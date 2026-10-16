package Modules.L1Data
{
    import flash.display.BitmapData;
    import flash.events.StatusEvent;
    import flash.utils.ByteArray;

    // 네이티브 저장 작업(.png + .fofo, 캡처 PNG) 시작과 완료 알림
    // 네이티브는 시작 호출 안에서 비트맵과 바이트를 복사하고 바로 돌아오며, 끝나면 StatusEvent(code: "save"/"png", level: 작업 번호)를 보냄
    // 완료 결과는 takeJobResult로 꺼냄 (줄마다 한 필드, anesrc/fofonative/src/savejob.cpp makeResult)
    // 층: L1 데이터 - 네이티브 저장 작업 시작과 완료 알림
    public final class NativeSave
    {
        public static const STATUS_OK:String = "ok";
        public static const STATUS_RENAMED:String = "renamed"; // 원래 이름으로 교체하지 못해서 이름_new 쌍으로 저장함
        public static const STATUS_FAILED:String = "failed"; // 폴더 없음, 권한 없음, 디스크 부족 등 쓰기 실패
        public static const STATUS_INTERNAL:String = "internal"; // 네이티브 내부 오류, 기존 worker 경로로 다시 저장해야 함
        private static const PNG_COMPRESSION_LEVEL:int = 6; // 캡처 PNG 저장에 쓰는 압축 단계

        private static var isStatusListenerRegistered:Boolean = false;
        private static const onSaveDoneByJobId:Object = {}; // 작업 번호 -> function(result:Object):void
        private static var pendingSaveCount:int = 0;

        // 마지막으로 끝난 저장 작업의 결과 (onSaveStatusEvent의 result, 로그와 테스트에서 재사용 집계를 볼때 씀)
        public static var lastSaveJobResult:Object = null;

        // 테스트에서 기존 worker 저장 경로를 시험할때 true
        public static var isDisabled:Boolean = false;

        // 저장표/PNG표 검증까지 통과해서 네이티브로 저장할 수 있는지
        public static function get isAvailable():Boolean
        {
            return !isDisabled && NativeCore.isAvailable && PixelRestore.isNativeSaveEnabled && PixelRestore.isNativePngEnabled;
        }

        // 아직 완료 알림을 받지 못한 네이티브 저장 작업이 있는지
        public static function get hasPendingNativeSave():Boolean
        {
            return pendingSaveCount > 0;
        }

        // .png와 .fofo 저장 시작, 시작하지 못하면 false (호출한 쪽이 기존 worker 경로로 저장)
        // compositeBitmapData: PNG로 쓸 합성 이미지, referenceBitmapData/referenceImageMetaArray: 참고 레이어가 없으면 null
        // repdataReadByteLength: repdata 파일 앞에서 읽을 바이트 수, memoryGroupsBytes: 그 뒤에 붙일 메모리 뭉치(writeObject)
        // reuseFofoPath: 압축 결과를 다시 쓸 이전 .fofo (원본이 같은 리플레이 조각, 첫 이미지, 참고 이미지는 다시 압축하지 않음), 없으면 빈 문자열
        // timing*: 타이밍 시트 객체 재료. 시트/점 시각 파일은 지금 길이까지 네이티브가 읽고, 앞 timingFileFrameCount 프레임만 쓴 뒤 메모리 부분 기록을 이어 붙임
        //   (TimingSheetFile.makeSheetFileObject와 같은 객체, timingLegacyFrameCount는 객체 끝의 옛 프레임 수)
        // cacheSegmentPaths/cacheSegmentNumbers: repdata 조각 캐시(ReplaySegmentCache) 앞부분 조각 파일 경로와 조각마다 [원본 길이, 원본 crc, 압축 길이, 압축 crc, 누적 프레임]
        //   네이티브는 맞는 앞부분 조각을 그대로 쓰고 repdata는 그 뒤부터만 읽음, 결과 message의 cachedSegments가 offeredCacheSegments보다 적으면 그 뒤 조각 파일이 깨진 것
        public static function startReplayFileAndPngSave(pngPath:String, fofoPath:String, compositeBitmapData:BitmapData,
                firstLayer1BitmapData:BitmapData, firstLayer2BitmapData:BitmapData, currentLayer1BitmapData:BitmapData, currentLayer2BitmapData:BitmapData, referenceBitmapData:BitmapData,
                repdataPath:String, repdataReadByteLength:Number, memoryGroupsBytes:ByteArray, mirrorBytes:ByteArray,
                timingSheetFilePath:String, timingSheetFileByteLength:Number, timingPointsFilePath:String, timingPointsFileByteLength:Number,
                timingFileFrameCount:Number, timingMemoryRecordBytes:ByteArray, timingMemoryPointRecordBytes:ByteArray, timingLegacyFrameCount:Number,
                firstImageMetaArray:Array, finalImageMetaArray:Array, referenceImageMetaArray:Array, nativeSaveOptions:int, reuseFofoPath:String,
                cacheSegmentPaths:Array, cacheSegmentNumbers:Array, onSaveDone:Function):Boolean
        {
            if (!isAvailable)
            {
                return false;
            }

            const saveJobId:int = NativeCore.nextNativeJobId();
            const nativeResultCode:int = NativeCore.callNativeFunctionForResultCode("saveStart", saveJobId, pngPath, fofoPath, compositeBitmapData, firstLayer1BitmapData, firstLayer2BitmapData, currentLayer1BitmapData, currentLayer2BitmapData, referenceBitmapData,
                    repdataPath, repdataReadByteLength, memoryGroupsBytes, mirrorBytes, firstImageMetaArray, finalImageMetaArray, referenceImageMetaArray, nativeSaveOptions, reuseFofoPath,
                    timingSheetFilePath, timingSheetFileByteLength, timingPointsFilePath, timingPointsFileByteLength, timingFileFrameCount, timingMemoryRecordBytes, timingMemoryPointRecordBytes, timingLegacyFrameCount,
                    cacheSegmentPaths, cacheSegmentNumbers);

            if (nativeResultCode !== NativeCore.OK)
            {
                trace("NativeSave saveStart failed: " + nativeResultCode);
                return false;
            }

            registerSaveDoneHandler(saveJobId, onSaveDone);
            return true;
        }

        // 캡처 이미지 PNG 저장 시작, 시작하지 못하면 false
        public static function startCapturePngSave(pngFilePath:String, captureBitmapData:BitmapData, onSaveDone:Function):Boolean
        {
            if (!isAvailable)
            {
                return false;
            }

            const saveJobId:int = NativeCore.nextNativeJobId();
            const nativeResultCode:int = NativeCore.callNativeFunctionForResultCode("pngStart", saveJobId, pngFilePath, captureBitmapData, PNG_COMPRESSION_LEVEL);

            if (nativeResultCode !== NativeCore.OK)
            {
                trace("NativeSave pngStart failed: " + nativeResultCode);
                return false;
            }

            registerSaveDoneHandler(saveJobId, onSaveDone);
            return true;
        }

        // 저장 작업 번호에 완료 콜백을 등록하고, 처음이면 네이티브 알림 수신을 시작
        private static function registerSaveDoneHandler(saveJobId:int, onSaveDone:Function):void
        {
            if (!isStatusListenerRegistered)
            {
                isStatusListenerRegistered = true;
                NativeCore.addNativeStatusListener(onSaveStatusEvent);
            }

            onSaveDoneByJobId[saveJobId] = onSaveDone;
            pendingSaveCount++;
        }

        // 네이티브의 "save"/"png" 완료 알림을 받아 그 작업의 결과를 읽고 등록된 콜백을 부름
        private static function onSaveStatusEvent(statusEvent:StatusEvent):void
        {
            if (statusEvent.code !== "save" && statusEvent.code !== "png")
            {
                return;
            }

            const saveJobId:int = int(statusEvent.level);
            const onSaveDone:Function = onSaveDoneByJobId[saveJobId] as Function;

            if (onSaveDone === null)
            {
                return;
            }

            delete onSaveDoneByJobId[saveJobId];
            pendingSaveCount--;
            const saveResultFields:Array = String(NativeCore.callNativeFunction("takeJobResult", saveJobId)).split("\n");
            const result:Object = {
                    status: saveResultFields[0],
                    pngPath: saveResultFields[1],
                    fofoPath: saveResultFields[2],
                    fofoSize: Number(saveResultFields[3]),
                    stage: saveResultFields[4],
                    error: int(saveResultFields[5]),
                    codec: saveResultFields[6],
                    encodeMs: Number(saveResultFields[7]),
                    writeMs: Number(saveResultFields[8]),
                    message: saveResultFields.slice(9).join("\n")
                };
            lastSaveJobResult = result;
            onSaveDone(result);
        }
    }
}
