package Modules
{
    import avm2.intrinsics.memory.li8;
    import avm2.intrinsics.memory.si8;
    import flash.display.BitmapData;
    import flash.display.BitmapDataChannel;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.system.ApplicationDomain;
    import flash.utils.ByteArray;
    import flash.utils.getDefinitionByName;

    // 투명 BitmapData는 내부에 premultiplied(색 x 알파) 값으로 저장돼서
    // copyPixelsToByteArray로 꺼낸 값을 setPixels로 다시 넣으면 반투명 픽셀이 1씩 어두워지고, 왕복할수록 누적됨
    // copyPixelsToByteArray 출력값과 내부값은 1:1이라 저장할때는 손실이 없고 불러올때만 바로잡으면 됨
    // 처음 쓸때 런타임 변환을 측정해서 표를 만들고
    // ANE(com.fofo.pixeldump)가 있으면 내부 버퍼에 원래 값을 직접 써넣고, 없으면(워커, 네이티브 빌드가 없는 운영체제) AS3로 입력값을 바꿔서 setPixels 함
    // 저장쪽에는 적용하면 안됨 (두번 적용되면 틀어짐)
    public final class PixelRestore
    {
        // ANE의 library.swf에 있는 클래스 (anesrc/pixeldump), 워커에는 ANE가 로드되지 않아서 직접 참조하지 않고 이름으로 찾음
        private static const NATIVE_CLASS_NAME:String = "com.fofo.pixeldump.PixelDump";
        private static const NATIVE_OK:int = 1;
        private static const TABLE_LENGTH:int = 65536; // 표 인덱스: 알파 << 8 | copyPixelsToByteArray 출력값
        private static const CHUNK_LENGTH:int = 1 << 20; // 한번에 작업 영역으로 복사해서 바꾸는 픽셀 바이트 수
        // AS3 경로용 domainMemory 버퍼, 앞 TABLE_LENGTH는 출력값 -> setPixels 입력값 표이고 뒤는 작업 영역
        // 측정이나 자체 검증에 실패하면 null로 두고 기존 setPixels 그대로 씀
        private static var workMemory:ByteArray = null;
        private static var nativeApi:Object = null; // 쓸 수 있으면 com.fofo.pixeldump.PixelDump 클래스, 아니면 null
        private static var isTableReady:Boolean = false;

        public static function get isNativeEnabled():Boolean
        {
            if (!isTableReady)
            {
                buildTable();
            }

            return nativeApi !== null;
        }

        // bmpd.setPixels(rect, pixels)와 같지만 저장할때의 내부 픽셀값을 그대로 복원해줌
        public static function setPixels(bmpd:BitmapData, rect:Rectangle, pixels:ByteArray):void
        {
            if (!isTableReady)
            {
                buildTable();
            }

            if (bmpd.transparent)
            {
                // ANE는 비트맵 전체를 한번에 채우는 경우만 처리
                if (nativeApi !== null && rect.x === 0 && rect.y === 0 && rect.width === bmpd.width && rect.height === bmpd.height
                        && nativeApi.restore(bmpd, pixels, pixels.position) === NATIVE_OK)
                {
                    pixels.position += rect.width * rect.height * 4; // setPixels처럼 읽은 만큼 넘겨줌
                    return;
                }

                if (workMemory !== null)
                {
                    remap(pixels, rect.width * rect.height * 4);
                }
            }

            bmpd.setPixels(rect, pixels);
        }

        // pixels의 현재 position부터 byteCount만큼 반투명 픽셀의 RGB를 표로 바꿔줌, position은 그대로 둠
        private static function remap(pixels:ByteArray, byteCount:int):void
        {
            const work:ByteArray = workMemory;
            const start:uint = pixels.position;
            const pixelEnd:uint = Math.min(pixels.length, start + byteCount);
            // libwebp(Crossbridge)도 domainMemory를 쓰므로 원래 값으로 돌려놔야함
            const previousMemory:ByteArray = ApplicationDomain.currentDomain.domainMemory;
            var offset:uint;
            var length:int;
            var end:int;
            var i:int;
            var alpha:int;
            var row:int;

            try
            {
                ApplicationDomain.currentDomain.domainMemory = work;

                // 픽셀을 표 뒤 작업 영역으로 조금씩 복사해서 li8/si8로 바꾼 뒤 되돌려 씀 (원본 크기를 늘리지 않으려고)
                for (offset = start;offset < pixelEnd;offset += CHUNK_LENGTH)
                {
                    length = Math.min(CHUNK_LENGTH, pixelEnd - offset);
                    work.position = TABLE_LENGTH;
                    work.writeBytes(pixels, offset, length);
                    end = TABLE_LENGTH + length;
                    // 디버그 빌드는 소스 줄마다 debugline 명령이 들어가서 반복문 본문을 한 줄로 두면 10배 가량 빨라짐
                    for (i = TABLE_LENGTH;i < end;i += 4) { alpha = li8(i); if (alpha !== 0 && alpha !== 255) { row = alpha << 8; si8(li8(row | li8(i + 1)), i + 1); si8(li8(row | li8(i + 2)), i + 2); si8(li8(row | li8(i + 3)), i + 3); } }
                    pixels.position = offset;
                    pixels.writeBytes(work, TABLE_LENGTH, length);
                }
            }
            finally
            {
                ApplicationDomain.currentDomain.domainMemory = previousMemory;
                pixels.position = start;
            }
        }

        private static function buildTable():void
        {
            isTableReady = true;

            try
            {
                const inputTable:ByteArray = new ByteArray(); // 출력값 -> setPixels 입력값 (AS3 경로)
                const internalTable:ByteArray = new ByteArray(); // 출력값 -> 내부 premultiplied 값 (ANE 경로)

                if (!measureTables(inputTable, internalTable))
                {
                    trace("PixelRestore: runtime conversion is not reversible, using plain setPixels");
                    return;
                }

                const work:ByteArray = new ByteArray();
                work.length = TABLE_LENGTH + CHUNK_LENGTH;
                work.writeBytes(inputTable, 0, TABLE_LENGTH);
                inputTable.clear();

                workMemory = work;

                if (!verifyRestore(restoreWithAS3))
                {
                    workMemory = null;
                    work.clear();
                    trace("PixelRestore: runtime conversion check failed, using plain setPixels");
                    return;
                }

                initializeNative(internalTable);
                internalTable.clear();
                trace("PixelRestore: " + ((nativeApi !== null) ? "native" : "actionscript"));
            }
            catch (error:Error)
            {
                workMemory = null;
                trace("PixelRestore: " + error);
            }
        }

        private static function initializeNative(internalTable:ByteArray):void
        {
            var api:Object;

            try
            {
                // 워커에는 ANE가 로드되지 않아서 클래스가 없음
                api = getDefinitionByName(NATIVE_CLASS_NAME);
            }
            catch (error:Error)
            {
                return;
            }

            try
            {
                // 네이티브 빌드가 없는 운영체제(default 플랫폼)면 false
                if (!api.open())
                {
                    return;
                }

                const tableResult:int = api.setTable(internalTable);

                if (tableResult !== NATIVE_OK)
                {
                    trace("PixelRestore native: setTable " + tableResult);
                }
                else
                {
                    nativeApi = api;

                    if (verifyRestore(restoreWithNative))
                    {
                        return;
                    }

                    trace("PixelRestore native: check failed");
                }
            }
            catch (error:Error)
            {
                trace("PixelRestore native: " + error);
            }

            nativeApi = null;

            try
            {
                api.close();
            }
            catch (error:Error)
            {
            }
        }

        // 모든 (알파, 입력값) 조합을 setPixels로 넣어보고 내부값과 출력값을 비교해서 두 표를 채움
        private static function measureTables(inputTable:ByteArray, internalTable:ByteArray):Boolean
        {
            const rect:Rectangle = new Rectangle(0, 0, 256, 256);
            const input:ByteArray = new ByteArray();
            var alpha:int;
            var value:int;

            for (alpha = 0;alpha < 256;alpha++)
            {
                for (value = 0;value < 256;value++)
                {
                    input.writeByte(alpha);
                    input.writeByte(value);
                    input.writeByte(value);
                    input.writeByte(value);
                }
            }

            input.position = 0;
            const grid:BitmapData = new BitmapData(256, 256, true, 0);
            grid.setPixels(rect, input);

            const premultiplied:BitmapData = getPremultipliedColor(grid);
            const output:ByteArray = new ByteArray();
            grid.copyPixelsToByteArray(rect, output);

            // 출력값 -> 내부값, 내부값 -> 그 값을 만드는 입력값
            const outputToInternal:Vector.<int> = new Vector.<int>(TABLE_LENGTH, true);
            const internalToInput:Vector.<int> = new Vector.<int>(TABLE_LENGTH, true);

            for (var i:int = 0;i < TABLE_LENGTH;i++)
            {
                outputToInternal[i] = -1;
                internalToInput[i] = -1;
            }

            for (alpha = 0;alpha < 256;alpha++)
            {
                for (value = 0;value < 256;value++)
                {
                    const internalValue:int = premultiplied.getPixel(value, alpha) & 0xFF;
                    const outputValue:int = output[((alpha << 8) | value) * 4 + 3];
                    const outputKey:int = (alpha << 8) | outputValue;

                    // 같은 출력값이 서로 다른 내부값에서 나오면 되돌릴 수 없음
                    if (outputToInternal[outputKey] !== -1 && outputToInternal[outputKey] !== internalValue)
                    {
                        return false;
                    }

                    outputToInternal[outputKey] = internalValue;
                    internalToInput[(alpha << 8) | internalValue] = value;
                }
            }

            inputTable.length = TABLE_LENGTH;
            internalTable.length = TABLE_LENGTH;

            for (i = 0;i < TABLE_LENGTH;i++)
            {
                const internalFromOutput:int = outputToInternal[i];
                const restoredInput:int = (internalFromOutput !== -1) ? internalToInput[(i & 0xFF00) | internalFromOutput] : -1;
                // 측정에 없던 값(실제 출력에는 나오지 않음)은 입력값은 그대로, 내부값은 계산값으로 둠
                inputTable[i] = (restoredInput !== -1) ? restoredInput : (i & 0xFF);
                internalTable[i] = (internalFromOutput !== -1) ? internalFromOutput : Math.round((i & 0xFF) * (i >> 8) / 255);
            }

            grid.dispose();
            premultiplied.dispose();
            input.clear();
            output.clear();
            return true;
        }

        private static function restoreWithAS3(bitmap:BitmapData, saved:ByteArray):Boolean
        {
            remap(saved, saved.length);
            bitmap.setPixels(bitmap.rect, saved);
            return true;
        }

        private static function restoreWithNative(bitmap:BitmapData, saved:ByteArray):Boolean
        {
            return nativeApi.restore(bitmap, saved, 0) === NATIVE_OK;
        }

        // 채널마다 다른 무작위 반투명 픽셀로 저장 -> 복원을 해보고 내부값이 그대로인지 확인
        private static function verifyRestore(restore:Function):Boolean
        {
            const source:BitmapData = new BitmapData(256, 256, true, 0);
            source.noise(20260928, 0, 255, BitmapDataChannel.ALPHA | BitmapDataChannel.RED | BitmapDataChannel.GREEN | BitmapDataChannel.BLUE, false);

            const saved:ByteArray = new ByteArray();
            source.copyPixelsToByteArray(source.rect, saved);
            saved.position = 0;

            const restored:BitmapData = new BitmapData(256, 256, true, 0);
            var isSame:Boolean = restore(restored, saved);

            if (isSame)
            {
                const sourceColor:BitmapData = getPremultipliedColor(source);
                const restoredColor:BitmapData = getPremultipliedColor(restored);
                const sourceAlpha:BitmapData = getAlpha(source);
                const restoredAlpha:BitmapData = getAlpha(restored);
                isSame = sourceColor.compare(restoredColor) === 0 && sourceAlpha.compare(restoredAlpha) === 0;
                sourceColor.dispose();
                restoredColor.dispose();
                sourceAlpha.dispose();
                restoredAlpha.dispose();
            }

            source.dispose();
            restored.dispose();
            saved.clear();
            return isSame;
        }

        // 불투명 검정 위에 그리면 RGB가 내부 premultiplied 값이 됨
        private static function getPremultipliedColor(bmpd:BitmapData):BitmapData
        {
            const color:BitmapData = new BitmapData(bmpd.width, bmpd.height, false, 0x000000);
            color.draw(bmpd);
            return color;
        }

        private static function getAlpha(bmpd:BitmapData):BitmapData
        {
            const alpha:BitmapData = new BitmapData(bmpd.width, bmpd.height, false, 0x000000);
            alpha.copyChannel(bmpd, bmpd.rect, new Point(), BitmapDataChannel.ALPHA, BitmapDataChannel.RED);
            return alpha;
        }
    }
}
