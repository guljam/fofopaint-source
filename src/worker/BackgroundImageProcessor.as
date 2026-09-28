package worker
{
    import Modules.ReplayDataCodec;
    import Modules.PixelRestore;
    import flash.display.BitmapData;
    import flash.display.PNGEncoderOptions;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Rectangle;
    import flash.net.registerClassAlias;
    import flash.system.MessageChannel;
    import flash.system.Worker;
    import flash.utils.ByteArray;

    public class BackgroundImageProcessor extends Sprite
    {

        private var bgWorker:Worker;

        protected var mainToBack:MessageChannel;

        protected var backToMain:MessageChannel;

        private var cacheGeneration:ByteArray; // main과 공유하는 현재 캐시 세대 번호

        public function BackgroundImageProcessor()
        {
            super();
            registerClassAlias("CacheImageMetaData", CacheImageMetaDataRecord);
            this.bgWorker = Worker.current;
            this.mainToBack = this.bgWorker.getSharedProperty("mainToBack");
            this.mainToBack.addEventListener(Event.CHANNEL_MESSAGE, this.onFromMain);
            this.backToMain = this.bgWorker.getSharedProperty("backToMain");
            this.cacheGeneration = this.bgWorker.getSharedProperty("cacheGeneration");
        }

        private function encodePNG(ba:ByteArray, w:Number, h:Number, bg:uint, transBGFlag:Boolean, isCaptureImage:Boolean):void
        {
            var bmpd:BitmapData = new BitmapData(w, h, true, transBGFlag ? 0 : bg);
            var bmpd2:BitmapData = new BitmapData(w, h, true, 0);
            ba.position = 0;
            bmpd2.lock();
            // setPixels를 그대로 쓰면 반투명 픽셀이 1씩 어두워져서 PNG도 어두워짐
            PixelRestore.setPixels(bmpd2, new Rectangle(0, 0, w, h), ba);
            bmpd2.unlock();
            bmpd.draw(bmpd2);
            ba.clear();
            bmpd.encode(new Rectangle(0, 0, w, h), new PNGEncoderOptions(), ba);
            if (isCaptureImage)
            {
                this.backToMain.send("encodePNGCaptureDone");
            }
            else
            {
                this.backToMain.send("encodePNGSaveDone");
            }
            this.backToMain.send(ba);
            ba.clear();
            ba = null;
        }

        // 캐시 이미지를 압축해서 main이 알려준 임시 파일에 씀
        // 성공, 취소, 실패 모두 응답해줘야 main의 작업 카운트와 대기열이 맞음
        private function compressUndoData(jobId:int, generation:int, path:String, metadata:Object, layer1:ByteArray, layer2:ByteArray):void
        {
            var result:String;

            try
            {
                result = writeCacheImage(generation, path, metadata, layer1, layer2);
            }
            catch (error:Error)
            {
                result = "error:" + error.message;
            }

            layer1.clear();
            layer2.clear();
            this.backToMain.send("compress_UndoDataDone");
            this.backToMain.send(jobId);
            this.backToMain.send(result);
        }

        private function writeCacheImage(generation:int, path:String, metadata:Object, layer1:ByteArray, layer2:ByteArray):String
        {
            if (isCacheGenerationChanged(generation))
                return "cancelled:0";

            const compressed1:ByteArray = copyAndCompress(layer1);

            if (isCacheGenerationChanged(generation))
            {
                compressed1.clear();
                return "cancelled:1";
            }

            const compressed2:ByteArray = copyAndCompress(layer2);

            if (isCacheGenerationChanged(generation))
            {
                compressed1.clear();
                compressed2.clear();
                return "cancelled:2";
            }

            const fs:FileStream = new FileStream();

            try
            {
                fs.open(new File(path), FileMode.WRITE);
                fs.writeObject([compressed1, compressed2, metadata]);
            }
            finally
            {
                fs.close();
                compressed1.clear();
                compressed2.clear();
            }

            return "done";
        }

        // shareable ByteArray는 compress를 못해서(Error #3735) worker 메모리로 복사한 뒤 압축
        // 원본은 복사 직후 바로 놓아서 두 레이어 원본과 복사본이 동시에 올라가지 않게 함
        private function copyAndCompress(source:ByteArray):ByteArray
        {
            const copy:ByteArray = new ByteArray();
            copy.writeBytes(source);
            source.clear();
            copy.compress();
            return copy;
        }

        private function isCacheGenerationChanged(generation:int):Boolean
        {
            // 값이 0일때만 0을 다시 쓰므로 main의 값은 바뀌지 않고 현재 값만 원자적으로 읽어옴
            return this.cacheGeneration.atomicCompareAndSwapIntAt(0, 0, 0) !== generation;
        }

        private function compressReplayData(ba1:ByteArray, ba2:ByteArray, ba3:ByteArray, ba4:ByteArray, ba5:ByteArray, ba6:ByteArray):void
        {
            ba1.compress();
            ba2.compress();
            ba3.compress();
            ba4.compress();
            ba5.compress();
            // 리플레이 명령은 전용 변환(LZMA 포함)으로 저장하고, 복원 결과가 원본과 다르면 기존 zlib으로 저장
            const encoded:ByteArray = ReplayDataCodec.encodeVerified(ba6);
            if (encoded != null)
            {
                ba6.clear();
                ba6.writeBytes(encoded);
                ba6.position = 0;
                encoded.clear();
            }
            else
            {
                ba6.compress();
            }
            this.backToMain.send("compress_ReplayDataDone");
            this.backToMain.send(ba1);
            this.backToMain.send(ba2);
            this.backToMain.send(ba3);
            this.backToMain.send(ba4);
            this.backToMain.send(ba5);
            this.backToMain.send(ba6);
            ba1.clear();
            ba2.clear();
            ba3.clear();
            ba4.clear();
            ba5.clear();
            ba6.clear();
            ba1 = null;
            ba2 = null;
            ba3 = null;
            ba4 = null;
            ba5 = null;
            ba6 = null;
        }

        private function onFromMain(event:Event):void
        {
            handleCommand(this.mainToBack.receive() as String);
        }

        protected function handleCommand(command:String):void
        {
            switch (command)
            {
                case "encodePNG":
                    this.encodePNG(this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true));
                    break;
                case "compress_ReplayData":
                    this.compressReplayData(this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true));
                    break;
                case "compress_UndoData":
                    this.compressUndoData(this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true));
            }
        }
    }
}
