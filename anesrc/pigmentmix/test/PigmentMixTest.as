package
{
    import flash.desktop.NativeApplication;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.BitmapDataChannel;
    import flash.display.CapsStyle;
    import flash.display.Loader;
    import flash.display.PNGEncoderOptions;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.ColorTransform;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.system.System;
    import flash.utils.ByteArray;
    import flash.utils.getDefinitionByName;
    import flash.utils.getTimer;

    // pigmentmix ANE 속도 테스트
    // 바닥: testimage.jpg를 캔버스 크기로 늘려서 깔아줌 (불투명)
    // 획: 한 색 + 픽셀마다 무작위 커버리지(경계선 반투명 흉내, 최악 조건) + 무작위 펜 알파 0~100%
    // 일반 그리기(BitmapData.draw + ColorTransform 알파)와 ANE 안료 합성 시간을 같은 입력으로 비교함
    public class PigmentMixTest extends Sprite
    {
        private static const SIZES:Array = [3000, 2000, 1000];
        private static const RUNS:int = 3;
        private static const SAMPLE_COUNT:int = 2000;

        private var PigmentMix:Class;
        private var outDir:File;
        private var report:Array = [];
        private var photo:BitmapData;

        public function PigmentMixTest()
        {
            outDir = new File(TEST::OUT);
            outDir.createDirectory();

            try
            {
                PigmentMix = getDefinitionByName("com.fofo.pigmentmix.PigmentMix") as Class;
            }
            catch (e:Error)
            {
                finish("PigmentMix 클래스를 찾을 수 없음: " + e.message);
                return;
            }

            if (!PigmentMix.open())
            {
                finish("ANE 컨텍스트를 만들 수 없음");
                return;
            }

            const bytes:ByteArray = new ByteArray();
            const fs:FileStream = new FileStream();
            fs.open(new File(TEST::IMAGE), FileMode.READ);
            fs.readBytes(bytes);
            fs.close();

            const loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void
            {
                photo = Bitmap(loader.content).bitmapData;
                run();
            });
            loader.loadBytes(bytes);
        }

        private function log(line:String):void
        {
            trace(line);
            report.push(line);
        }

        private function run():void
        {
            log("image " + photo.width + "x" + photo.height + ", hardware threads " + PigmentMix.hardwareThreads() + ", test threads " + TEST::THREADS);
            log("size\trun\talpha\tcolor\tnormal(ms)\tpigment(ms)\tnative(ms)\tsampleMaxDiff");

            var seed:int = 12345;

            for each (var size:int in SIZES)
            {
                const base:BitmapData = makeBase(size);
                const rect:Rectangle = base.rect;

                for (var r:int = 0; r < RUNS; r++)
                {
                    seed = nextRandom(seed);
                    var alpha:Number = (seed % 1001) / 1000; // 0~100%
                    seed = nextRandom(seed);
                    var color:uint = seed & 0xFFFFFF;
                    seed = nextRandom(seed);
                    var draw:BitmapData = makeStroke(size, color, seed);
                    var drawBitmap:Bitmap = new Bitmap(draw);

                    // 일반 그리기 (DrawingFinish와 같은 호출)
                    var normal:BitmapData = base.clone();
                    System.gc();
                    var t0:int = getTimer();
                    normal.draw(drawBitmap, null, new ColorTransform(1, 1, 1, alpha), null, rect);
                    normal.getPixel32(size - 1, size - 1); // 지연 처리가 있으면 여기서 끝나게 함
                    var normalMs:int = getTimer() - t0;

                    // 안료 합성
                    var pigment:BitmapData = base.clone();
                    System.gc();
                    t0 = getTimer();
                    var nativeUs:Number = PigmentMix.composite(pigment, draw, 0, 0, size, size, color, alpha, TEST::THREADS);
                    var pigmentMs:int = getTimer() - t0;

                    var diff:int = verify(base, draw, pigment, color, alpha, seed);

                    log(size + "\t" + (r + 1) + "\t" + (alpha * 100).toFixed(1) + "%\t#" + hex(color) + "\t" + normalMs + "\t" + pigmentMs + "\t" + (nativeUs / 1000).toFixed(1) + "\t" + diff);

                    if (size === 1000 && r === 0)
                    {
                        savePNG(normal, "noise_normal.png");
                        savePNG(pigment, "noise_pigment.png");
                    }

                    normal.dispose();
                    pigment.dispose();
                    draw.dispose();
                }

                base.dispose();
            }

            demo();
            finish(null);
        }

        // 바닥 이미지 (사진을 캔버스 크기로 늘려서 그림)
        private function makeBase(size:int):BitmapData
        {
            const base:BitmapData = new BitmapData(size, size, true, 0);
            const m:Matrix = new Matrix();
            m.scale(size / photo.width, size / photo.height);
            base.draw(photo, m, null, null, null, true);
            return base;
        }

        // 한 색 획 + 픽셀마다 무작위 커버리지
        private function makeStroke(size:int, color:uint, seed:int):BitmapData
        {
            const draw:BitmapData = new BitmapData(size, size, true, 0xFF000000 | color);
            const noise:BitmapData = new BitmapData(size, size, true, 0);
            noise.noise(seed, 0, 255, BitmapDataChannel.ALPHA, false);
            draw.copyChannel(noise, noise.rect, new Point(), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
            noise.dispose();
            return draw;
        }

        // 무작위 픽셀을 mixbox 원본(mixbox_lerp)과 비교해서 가장 큰 채널 차이를 돌려줌
        // 바닥이 불투명이라 t = 커버리지 * 알파
        private function verify(base:BitmapData, draw:BitmapData, result:BitmapData, color:uint, alpha:Number, seed:int):int
        {
            var maxDiff:int = 0;

            for (var i:int = 0; i < SAMPLE_COUNT; i++)
            {
                seed = nextRandom(seed);
                const x:int = seed % base.width;
                seed = nextRandom(seed);
                const y:int = seed % base.height;
                const coverage:uint = draw.getPixel32(x, y) >>> 24;
                const got:uint = result.getPixel(x, y);
                var expected:uint;

                if (coverage === 0 || alpha === 0)
                    expected = base.getPixel(x, y);
                else
                    expected = PigmentMix.lerpRef(base.getPixel(x, y), color, coverage / 255 * alpha);

                maxDiff = Math.max(maxDiff, Math.abs(int(got >> 16 & 0xFF) - int(expected >> 16 & 0xFF)), Math.abs(int(got >> 8 & 0xFF) - int(expected >> 8 & 0xFF)), Math.abs(int(got & 0xFF) - int(expected & 0xFF)));
            }

            return maxDiff;
        }

        // 눈으로 확인하는 용도: 노랑, 파랑, 빨강 획을 겹쳐 그린 결과 (왼쪽 일반, 오른쪽 안료)
        private function demo():void
        {
            const w:int = 600;
            const h:int = 600;
            const strokes:Array = [
                [0xFEEC00, 0.8, 60, 120, 540, 200], // Cadmium Yellow
                [0x002185, 0.6, 60, 480, 540, 120], // Cobalt Blue
                [0xFF2702, 0.5, 300, 40, 300, 560], // Cadmium Red
                [0xFEEC00, 0.8, 80, 300, 520, 300] // Cadmium Yellow
            ];
            const normal:BitmapData = new BitmapData(w, h, true, 0xFFFFFFFF);
            const pigment:BitmapData = normal.clone();
            const shape:Shape = new Shape();
            const draw:BitmapData = new BitmapData(w, h, true, 0);

            for each (var s:Array in strokes)
            {
                shape.graphics.clear();
                shape.graphics.lineStyle(90, s[0], 1, false, "normal", CapsStyle.ROUND);
                shape.graphics.moveTo(s[2], s[3]);
                shape.graphics.lineTo(s[4], s[5]);
                draw.fillRect(draw.rect, 0);
                draw.draw(shape, null, null, null, null, true);
                normal.draw(new Bitmap(draw), null, new ColorTransform(1, 1, 1, s[1]));
                PigmentMix.composite(pigment, draw, 0, 0, w, h, s[0], s[1], 0);
            }

            const both:BitmapData = new BitmapData(w * 2, h, true, 0);
            both.copyPixels(normal, normal.rect, new Point());
            both.copyPixels(pigment, pigment.rect, new Point(w, 0));
            savePNG(both, "demo_normal_vs_pigment.png");
        }

        private function savePNG(bmpd:BitmapData, name:String):void
        {
            const fs:FileStream = new FileStream();
            fs.open(outDir.resolvePath(name), FileMode.WRITE);
            fs.writeBytes(bmpd.encode(bmpd.rect, new PNGEncoderOptions(true)));
            fs.close();
        }

        private static function nextRandom(seed:int):int
        {
            return int((seed * 1103515245 + 12345) & 0x7FFFFFFF);
        }

        private static function hex(color:uint):String
        {
            const s:String = color.toString(16).toUpperCase();
            return "000000".substr(0, 6 - s.length) + s;
        }

        private function finish(error:String):void
        {
            if (error)
                log("ERROR " + error);

            const fs:FileStream = new FileStream();
            fs.open(outDir.resolvePath("report.txt"), FileMode.WRITE);
            fs.writeUTFBytes(report.join("\n") + "\n");
            fs.close();
            NativeApplication.nativeApplication.exit();
        }
    }
}
