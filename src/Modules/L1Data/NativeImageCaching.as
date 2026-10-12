package Modules.L1Data
{
    import flash.display.BitmapData;
    import flash.events.StatusEvent;
    import flash.utils.ByteArray;
    import Modules.L2Engine.CacheImageMetaData;

    // 네이티브 캐시 이미지 쓰기 (undo 캐시, 불러오기 캐시) 시작과 완료 알림
    // 네이티브는 호출 안에서 두 레이어 내부 버퍼를 복사하고 바로 돌아오고, 끝나면 StatusEvent(code: "cache", level: 작업 번호)를 보냄
    // 층: L1 데이터 - 네이티브 캐시 이미지 쓰기 시작과 완료 알림
    public final class NativeImageCaching
    {
        public static const RESULT_BUSY:int = -9; // 메모리 상한에 닿음 (forceIgnoreMemoryLimit가 아닐때), 다음에 다시 시도
        private static var isStatusListenerRegistered:Boolean = false;
        private static const onCacheWriteDoneByJobId:Object = {}; // 작업 번호 -> function(result:Object):void
        private static var _pendingCacheWriteCount:int = 0;

        // 네이티브 ANE를 쓸 수 있는지 여부
        public static function get isAvailable():Boolean
        {
            return NativeCore.isAvailable;
        }

        // 시작했지만 아직 완료 알림이 오지 않은 캐시 파일 쓰기 개수
        public static function get pendingCacheWriteCount():int
        {
            return _pendingCacheWriteCount;
        }

        // cacheFilePath에 새 형식 캐시 파일을 씀 (임시 파일에 쓰고 교체), 시작하면 NativeCore.OK
        // cacheGeneration이 네이티브 세대(setCacheGeneration)와 달라지면 쓰기는 건너뛰고 "cancelled"로 끝남
        // forceIgnoreMemoryLimit가 아니면 메모리 상한을 넘을때 RESULT_BUSY
        public static function startCacheFileWrite(cacheFilePath:String, layer1BitmapData:BitmapData, layer2BitmapData:BitmapData, cacheImageMetaData:CacheImageMetaData, cacheGeneration:int, forceIgnoreMemoryLimit:Boolean, onCacheWriteDone:Function):int
        {
            if (!isAvailable)
            {
                return 0;
            }

            const cacheWriteJobId:int = NativeCore.nextNativeJobId();
            const cacheImageMetaDataBytes:ByteArray = new ByteArray();
            cacheImageMetaDataBytes.writeObject(cacheImageMetaData);
            const nativeResultCode:int = NativeCore.callNativeFunctionForResultCode("cacheWrite", cacheWriteJobId, cacheFilePath, layer1BitmapData, layer2BitmapData, cacheImageMetaDataBytes, cacheGeneration, forceIgnoreMemoryLimit);
            cacheImageMetaDataBytes.clear();

            if (nativeResultCode !== NativeCore.OK)
            {
                return nativeResultCode;
            }

            if (!isStatusListenerRegistered)
            {
                isStatusListenerRegistered = true;
                NativeCore.addNativeStatusListener(onCacheWriteStatusEvent);
            }

            onCacheWriteDoneByJobId[cacheWriteJobId] = onCacheWriteDone;
            _pendingCacheWriteCount++;
            return nativeResultCode;
        }

        // 네이티브에 현재 캐시 세대를 알림. 이보다 오래된 세대로 시작한 쓰기는 건너뜀
        public static function setCacheGeneration(cacheGeneration:int):void
        {
            if (isAvailable)
            {
                NativeCore.callNativeFunction("cacheSetGeneration", cacheGeneration);
            }
        }

        // 네이티브의 "cache" 완료 알림을 받아 그 작업의 결과를 읽고 startCacheFileWrite에 넘긴 콜백을 부름
        private static function onCacheWriteStatusEvent(statusEvent:StatusEvent):void
        {
            if (statusEvent.code !== "cache")
            {
                return;
            }

            const cacheWriteJobId:int = int(statusEvent.level);
            const onCacheWriteDone:Function = onCacheWriteDoneByJobId[cacheWriteJobId] as Function;

            if (onCacheWriteDone === null)
            {
                return;
            }

            delete onCacheWriteDoneByJobId[cacheWriteJobId];
            _pendingCacheWriteCount--;
            // status, compressMs, writeMs, size, win32 error (anesrc/fofonative/src/cache.cpp resultText)
            const cacheWriteResultFields:Array = String(NativeCore.callNativeFunction("takeJobResult", cacheWriteJobId)).split("\n");
            onCacheWriteDone({ status: cacheWriteResultFields[0], compressMs: Number(cacheWriteResultFields[1]), writeMs: Number(cacheWriteResultFields[2]), size: Number(cacheWriteResultFields[3]), error: int(cacheWriteResultFields[4]) });
        }
    }
}
