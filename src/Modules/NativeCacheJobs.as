package Modules
{
    import flash.display.BitmapData;
    import flash.events.StatusEvent;
    import flash.utils.ByteArray;

    // 네이티브 캐시 이미지 쓰기 작업 (undo 캐시, 불러오기 캐시) 시작과 완료 알림
    // 네이티브는 호출 안에서 두 레이어 내부 버퍼를 복사하고 바로 돌아오고, 끝나면 StatusEvent(code: "cache", level: 작업 번호)를 보냄
    // 층: L1 데이터 - 네이티브 캐시 이미지 쓰기 작업 시작과 완료 알림
    public final class NativeCacheJobs
    {
        public static const RESULT_BUSY:int = -9; // 메모리 상한에 닿음 (force가 아닐때), 다음에 다시 시도
        private static var isListening:Boolean = false;
        private static const handlers:Object = {}; // 작업 번호 -> function(result:Object):void
        private static var _pendingCount:int = 0;

        public static function get isAvailable():Boolean
        {
            return NativeCore.isAvailable;
        }

        public static function get pendingCount():int
        {
            return _pendingCount;
        }

        // path에 새 형식 캐시 파일을 씀 (임시 파일에 쓰고 교체), 시작하면 NativeCore.OK
        // generation이 네이티브 세대(cacheSetGeneration)와 달라지면 작업은 건너뛰고 "cancelled"로 끝남
        // force가 아니면 메모리 상한을 넘을때 RESULT_BUSY
        public static function start(path:String, layer1:BitmapData, layer2:BitmapData, metadata:CacheImageMetaData, generation:int, force:Boolean, onDone:Function):int
        {
            if (!isAvailable)
            {
                return 0;
            }

            const id:int = NativeCore.nextJobId();
            const metadataBytes:ByteArray = new ByteArray();
            metadataBytes.writeObject(metadata);
            const result:int = NativeCore.callResult("cacheWrite", id, path, layer1, layer2, metadataBytes, generation, force);
            metadataBytes.clear();

            if (result !== NativeCore.OK)
            {
                return result;
            }

            if (!isListening)
            {
                isListening = true;
                NativeCore.addStatusListener(onStatus);
            }

            handlers[id] = onDone;
            _pendingCount++;
            return result;
        }

        public static function setGeneration(generation:int):void
        {
            if (isAvailable)
            {
                NativeCore.call("cacheSetGeneration", generation);
            }
        }

        private static function onStatus(e:StatusEvent):void
        {
            if (e.code !== "cache")
            {
                return;
            }

            const id:int = int(e.level);
            const onDone:Function = handlers[id] as Function;

            if (onDone === null)
            {
                return;
            }

            delete handlers[id];
            _pendingCount--;
            // status, compressMs, writeMs, size, win32 error (anesrc/fofonative/src/cache.cpp resultText)
            const fields:Array = String(NativeCore.call("takeJobResult", id)).split("\n");
            onDone({ status: fields[0], compressMs: Number(fields[1]), writeMs: Number(fields[2]), size: Number(fields[3]), error: int(fields[4]) });
        }
    }
}
