package Modules.L1Data
{
    import flash.events.StatusEvent;

    // 네이티브 repdata 조각 캐시 채우기 시작과 완료 알림
    // 네이티브는 호출 안에서 repdata 구간을 읽고 바로 돌아오며, 스레드에서 닫힌 조각만 인코드해 조각마다 캐시 파일로 쓰고 StatusEvent(code: "segcache", level: 작업 번호)를 보냄
    // 완료 결과 형식은 anesrc/fofonative/src/savejob.cpp ReplaySegmentCacheFillJob
    // 층: L1 데이터 - 네이티브 repdata 조각 캐시 채우기 시작과 완료 알림
    public final class NativeReplaySegmentCache
    {
        private static var isStatusListenerRegistered:Boolean = false;
        private static const onFillDoneByJobId:Object = {}; // 작업 번호 -> function(result:Object):void

        // 네이티브 ANE를 쓸 수 있는지 여부
        public static function get isAvailable():Boolean
        {
            return NativeCore.isAvailable;
        }

        // repdata의 [startByte, endByte)를 조각 규칙(앞까지 누적 프레임 startFrames에서 이어서)으로 나눠 닫힌 조각을 cacheFolderPath에 씀
        // 조각 파일 이름은 segmentFileNamePrefix + (firstSegmentNumber부터의 번호), reuseFofoPath에 같은 조각이 있으면 다시 인코드하지 않음 (없으면 빈 문자열)
        // 시작하지 못하면 false
        // onFillDone(result): result = {status:"ok"|"error", encodeMs, writeMs, reusedCount, segments:[{fileName, rawLength, rawCrc, compressedLength, compressedCrc, endFrames}], message}
        public static function startReplaySegmentCacheFill(repdataPath:String, startByte:Number, endByte:Number, startFrames:Number, cacheFolderPath:String,
                segmentFileNamePrefix:String, firstSegmentNumber:int, reuseFofoPath:String, onFillDone:Function):Boolean
        {
            if (!isAvailable)
            {
                return false;
            }

            const fillJobId:int = NativeCore.nextNativeJobId();
            const nativeResultCode:int = NativeCore.callNativeFunctionForResultCode("replaySegmentCacheFillStart", fillJobId, repdataPath, startByte, endByte, startFrames,
                    cacheFolderPath, segmentFileNamePrefix, firstSegmentNumber, reuseFofoPath);

            if (nativeResultCode !== NativeCore.OK)
            {
                trace("NativeReplaySegmentCache fill start failed: " + nativeResultCode);
                return false;
            }

            if (!isStatusListenerRegistered)
            {
                isStatusListenerRegistered = true;
                NativeCore.addNativeStatusListener(onFillStatusEvent);
            }

            onFillDoneByJobId[fillJobId] = onFillDone;
            return true;
        }

        // 네이티브의 "segcache" 완료 알림을 받아 결과 문자열을 객체로 바꿔 콜백을 부름
        private static function onFillStatusEvent(statusEvent:StatusEvent):void
        {
            if (statusEvent.code !== "segcache")
            {
                return;
            }

            const fillJobId:int = int(statusEvent.level);
            const onFillDone:Function = onFillDoneByJobId[fillJobId] as Function;

            if (onFillDone === null)
            {
                return;
            }

            delete onFillDoneByJobId[fillJobId];
            const lines:Array = String(NativeCore.callNativeFunction("takeJobResult", fillJobId)).split("\n");

            if (lines[0] !== "ok")
            {
                onFillDone({ status: "error", segments: [], message: lines.slice(1).join("\n") });
                return;
            }

            const segments:Array = [];
            const segmentCount:int = int(lines[4]);

            for (var i:int = 0;i < segmentCount;i++)
            {
                const fields:Array = String(lines[5 + i]).split(" ");
                segments.push({ fileName: fields[0], rawLength: Number(fields[1]), rawCrc: Number(fields[2]), compressedLength: Number(fields[3]),
                        compressedCrc: Number(fields[4]), endFrames: Number(fields[5]) });
            }

            onFillDone({ status: "ok", encodeMs: Number(lines[1]), writeMs: Number(lines[2]), reusedCount: int(lines[3]), segments: segments, message: "" });
        }
    }
}
