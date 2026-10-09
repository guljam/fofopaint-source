package Modules
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

        private static var isListening:Boolean = false;
        private static const handlers:Object = {}; // 작업 번호 -> function(result:Object):void
        private static var pendingCount:int = 0;

        // 테스트에서 기존 worker 저장 경로를 시험할때 true
        public static var isDisabled:Boolean = false;

        // 저장표/PNG표 검증까지 통과해서 네이티브로 저장할 수 있는지
        public static function get isAvailable():Boolean
        {
            return !isDisabled && NativeCore.isAvailable && PixelRestore.isNativeSaveEnabled && PixelRestore.isNativePngEnabled;
        }

        // 아직 완료 알림을 받지 못한 네이티브 저장 작업이 있는지
        public static function get isBusy():Boolean
        {
            return pendingCount > 0;
        }

        // .png와 .fofo 저장 시작, 시작하지 못하면 false (호출한 쪽이 기존 worker 경로로 저장)
        // composite: PNG로 쓸 합성 이미지, reference/referenceMeta: 참고 레이어가 없으면 null
        // repdataLength: repdata 파일 앞에서 읽을 바이트 수, memoryGroups: 그 뒤에 붙일 메모리 뭉치(writeObject)
        public static function startSave(pngPath:String, fofoPath:String, composite:BitmapData,
                first1:BitmapData, first2:BitmapData, current1:BitmapData, current2:BitmapData, reference:BitmapData,
                repdataPath:String, repdataLength:Number, memoryGroups:ByteArray, mirrorBytes:ByteArray, timingBytes:ByteArray,
                firstMeta:Array, finalMeta:Array, referenceMeta:Array, options:int, onDone:Function):Boolean
        {
            if (!isAvailable)
            {
                return false;
            }

            const id:int = NativeCore.nextJobId();
            const result:int = NativeCore.callResult("saveStart", id, pngPath, fofoPath, composite, first1, first2, current1, current2, reference,
                    repdataPath, repdataLength, memoryGroups, mirrorBytes, timingBytes, firstMeta, finalMeta, referenceMeta, options);

            if (result !== NativeCore.OK)
            {
                trace("NativeSave saveStart failed: " + result);
                return false;
            }

            register(id, onDone);
            return true;
        }

        // 캡처 이미지 PNG 저장 시작, 시작하지 못하면 false
        public static function startPng(path:String, image:BitmapData, onDone:Function):Boolean
        {
            if (!isAvailable)
            {
                return false;
            }

            const id:int = NativeCore.nextJobId();
            const result:int = NativeCore.callResult("pngStart", id, path, image, 6);

            if (result !== NativeCore.OK)
            {
                trace("NativeSave pngStart failed: " + result);
                return false;
            }

            register(id, onDone);
            return true;
        }

        private static function register(id:int, onDone:Function):void
        {
            if (!isListening)
            {
                isListening = true;
                NativeCore.addStatusListener(onStatus);
            }

            handlers[id] = onDone;
            pendingCount++;
        }

        private static function onStatus(e:StatusEvent):void
        {
            if (e.code !== "save" && e.code !== "png")
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
            pendingCount--;
            const fields:Array = String(NativeCore.call("takeJobResult", id)).split("\n");
            const result:Object = {
                    status: fields[0],
                    pngPath: fields[1],
                    fofoPath: fields[2],
                    fofoSize: Number(fields[3]),
                    stage: fields[4],
                    error: int(fields[5]),
                    codec: fields[6],
                    encodeMs: Number(fields[7]),
                    writeMs: Number(fields[8]),
                    message: fields.slice(9).join("\n")
                };
            onDone(result);
        }
    }
}
