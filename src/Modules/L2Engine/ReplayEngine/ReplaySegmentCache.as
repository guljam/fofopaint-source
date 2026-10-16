package Modules.L2Engine.ReplayEngine
{
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.ByteArray;
    import flash.utils.getTimer;
    import Modules.L1Data.AppDataPaths;
    import Modules.L1Data.NativeReplaySegmentCache;
    import Modules.L1Data.ReplayDataCodec;
    import Modules.L2Engine.BackgroundWorkerCoordinator;

    // repdata 조각 캐시: repdata를 조각(누적 프레임이 1만의 배수를 넘는 뭉치 뒤에서 자름, .fofo 세그먼트 형식과 같은 경계)마다 미리 FRC2로 인코드해 둠
    // 저장할때 캐시에 있는 앞부분은 repdata를 읽거나 다시 인코드하지 않고 압축 바이트를 그대로 쓰고, 그 뒤만 읽어서 인코드함 (NativeSave, worker 저장 모두)
    // 조각 목록(기록 파일 "segments")은 repdata 처음부터 이어진 조각만 담고, repdata를 자르거나 바꾸는 곳에서 repdata보다 먼저 고쳐 씀
    //   덧붙이기: 닫힌 조각이 생기면 채우기 시작 (UndoHistory), 자르기: 자른 위치 뒤 조각을 버림 (딥 언두, 뒤 삭제)
    //   새로 쓰기: 전부 버림 (불러오기, 새 파일, 앞 삭제) -> 불러오기와 앞 삭제는 다시 채움
    // 채우기는 네이티브(NativeReplaySegmentCache)나 worker에서 하고, 시작한 뒤에 repdata가 잘리거나 바뀌면(세대가 바뀌면) 결과를 버림
    // 층: L2 엔진 - repdata 조각 캐시 목록과 채우기
    public final class ReplaySegmentCache
    {
        private static const SEGMENT_LEDGER_FILE_NAME:String = "segments";
        private static const SEGMENT_LEDGER_VERSION:int = 1;

        // repdata 처음부터 이어진 캐시 조각들 {fileName, rawLength, rawCrc, compressedLength, compressedCrc, endByte, endFrames}
        private static var cachedSegments:Array = [];
        // repdata를 자르거나 새로 쓸때마다 올림, 이전 세대로 시작한 채우기 결과는 버림
        private static var segmentCacheGeneration:int = 0;
        private static var fillJobSeq:int = 0;
        private static var runningFillJob:Object = null; // {jobId, generation, startByte, endByte, startFrames, startTime, isNative}
        private static var isFillRequestedWhileRunning:Boolean = false;
        private static var reuseFofoPathForNextFill:String = "";
        // 채우기가 실패하면(지원하지 않는 명령 형식 등) 같은 구간을 계속 다시 시도하지 않게 자르거나 새로 쓸때까지 멈춤
        private static var isFillStoppedByFailure:Boolean = false;

        // 마지막으로 끝난 채우기 결과 {status, isNative, startByte, endByte, segmentCount, reusedCount, encodeMs, writeMs, wallMs, isDiscarded} (로그와 테스트용)
        public static var lastFillResult:Object = null;

        // 캐시에 있는 조각 수
        public static function get cachedSegmentCount():int
        {
            return cachedSegments.length;
        }

        // 채우기 작업이 진행 중인지 (테스트에서 기다릴때)
        public static function get isFillRunning():Boolean
        {
            return runningFillJob !== null || isFillRequestedWhileRunning;
        }

        // 캐시 조각이 끝나는 repdata 바이트 위치 (캐시가 비어있으면 0)
        public static function getCachedSegmentEndByte():Number
        {
            return (cachedSegments.length > 0) ? cachedSegments[cachedSegments.length - 1].endByte : 0;
        }

        // 캐시 조각 끝까지의 누적 프레임 (캐시가 비어있으면 0)
        public static function getCachedSegmentEndFrames():Number
        {
            return (cachedSegments.length > 0) ? cachedSegments[cachedSegments.length - 1].endFrames : 0;
        }

        // 저장할 repdata 길이(saveByteLength) 안에 들어가는 앞부분 캐시 조각들 (복사본)
        public static function getCachedSegmentsForSave(saveByteLength:Number):Array
        {
            const segments:Array = [];

            for (var i:int = 0;i < cachedSegments.length && cachedSegments[i].endByte <= saveByteLength;i++)
            {
                segments.push(cachedSegments[i]);
            }

            return segments;
        }

        // 캐시 조각 파일 경로
        public static function getSegmentFilePath(segment:Object):String
        {
            return AppDataPaths.replaySegmentCacheFolderPath.resolvePath(segment.fileName).nativePath;
        }

        // 앱 시작때: 기록을 읽어 지금 repdata와 맞는 앞부분 조각만 남기고, 기록에 없는 파일은 지운 뒤 남은 부분을 채움
        // 다른 버전의 앱이 repdata를 바꿨을 수 있어서 마지막 조각은 repdata를 읽어 원본 crc를 확인함
        public static function restoreSegmentCacheFromDisk():void
        {
            cachedSegments = readSegmentLedger();
            const repdata:File = AppDataPaths.replayDataFilePath;
            const repdataSize:Number = repdata.exists ? repdata.size : 0;
            var validCount:int = 0;
            var endByte:Number = 0;

            for (var i:int = 0;i < cachedSegments.length;i++)
            {
                const segment:Object = cachedSegments[i];
                const file:File = AppDataPaths.replaySegmentCacheFolderPath.resolvePath(segment.fileName);

                if (segment.endByte !== endByte + segment.rawLength || segment.endByte > repdataSize || !file.exists || file.size !== segment.compressedLength)
                {
                    break;
                }

                endByte = segment.endByte;
                validCount++;
            }

            if (validCount > 0 && !isSegmentRawCrcSameAsRepdata(cachedSegments[validCount - 1]))
            {
                validCount = 0;
            }

            if (validCount !== cachedSegments.length)
            {
                trace("Replay segment cache restore: " + validCount + "/" + cachedSegments.length + " segments valid");
                cachedSegments.length = validCount;
                writeSegmentLedger();
            }

            deleteUnlistedSegmentFiles();

            // worker는 시작 직후엔 아직 준비가 안 되어 있을 수 있어서 네이티브일때만 바로 채움 (worker면 다음 덧붙이기때 채움)
            if (NativeReplaySegmentCache.isAvailable)
            {
                requestSegmentCacheFill();
            }
        }

        // repdata를 새로 쓰기 전에 부름: 캐시를 모두 버림
        public static function clearSegmentCache():void
        {
            segmentCacheGeneration++;
            isFillStoppedByFailure = false;
            isFillRequestedWhileRunning = false;
            reuseFofoPathForNextFill = "";
            cachedSegments = [];
            writeSegmentLedger();
            deleteUnlistedSegmentFiles();
        }

        // repdata를 byteLength로 자르기 전에 부름: 끝이 byteLength를 넘는 조각을 버림
        public static function truncateSegmentCacheToByteLength(byteLength:Number):void
        {
            segmentCacheGeneration++;
            isFillStoppedByFailure = false;
            var keepCount:int = 0;

            while (keepCount < cachedSegments.length && cachedSegments[keepCount].endByte <= byteLength)
            {
                keepCount++;
            }

            if (keepCount < cachedSegments.length)
            {
                const removedSegments:Array = cachedSegments.splice(keepCount);
                writeSegmentLedger();
                deleteSegmentFiles(removedSegments);
            }
        }

        // 저장에서 index번 조각부터 파일이 깨졌거나 없다고 알려줬을때 그 뒤를 버림 (다음 채우기에서 다시 만듦)
        public static function dropCachedSegmentsFromIndex(index:int):void
        {
            if (index >= cachedSegments.length)
            {
                return;
            }

            segmentCacheGeneration++;
            const removedSegments:Array = cachedSegments.splice(index);
            writeSegmentLedger();
            deleteSegmentFiles(removedSegments);
            AppDataPaths.writeCrashLog("Replay segment cache dropped from " + index + " (" + removedSegments.length + " segments)");
        }

        // 리플레이 파일에 뭉치를 덧붙인 뒤 부름: 캐시 끝 뒤에 닫힌 조각이 생겼으면(누적 프레임이 1만의 배수를 넘었으면) 채우기 시작
        public static function requestSegmentCacheFillIfSegmentClosed(replayFileTotalFrames:Number):void
        {
            if (Math.floor(replayFileTotalFrames / ReplayDataCodec.SEGMENT_FRAMES) > Math.floor(getCachedSegmentEndFrames() / ReplayDataCodec.SEGMENT_FRAMES))
            {
                requestSegmentCacheFill();
            }
        }

        // 캐시 끝부터 repdata 끝까지의 닫힌 조각을 채움, 이미 채우는 중이면 끝난 뒤 다시 채움
        // reuseFofoPath: 같은 조각의 압축 결과를 가져올 .fofo (불러온 파일, 네이티브만), 없으면 빈 문자열
        public static function requestSegmentCacheFill(reuseFofoPath:String = ""):void
        {
            if (isFillStoppedByFailure)
            {
                return;
            }

            if (runningFillJob !== null)
            {
                isFillRequestedWhileRunning = true;

                if (reuseFofoPath !== "")
                {
                    reuseFofoPathForNextFill = reuseFofoPath;
                }
                return;
            }

            startSegmentCacheFill(reuseFofoPath);
        }

        // worker의 채우기 결과 (BackgroundWorkerCoordinator), segments가 null이면 실패
        public static function finishWorkerSegmentCacheFill(jobId:int, segments:Array, encodeMs:Number, writeMs:Number):void
        {
            if (runningFillJob === null || runningFillJob.jobId !== jobId)
            {
                deleteSegmentFiles(segments);
                return;
            }

            finishSegmentCacheFill(runningFillJob, segments, { status: (segments !== null) ? "ok" : "error", encodeMs: encodeMs, writeMs: writeMs, reusedCount: 0 });
        }

        // 캐시 끝부터 repdata 끝까지를 읽어 채우기 작업을 시작 (네이티브, 못하면 worker)
        private static function startSegmentCacheFill(reuseFofoPath:String):void
        {
            const repdata:File = AppDataPaths.replayDataFilePath;
            const startByte:Number = getCachedSegmentEndByte();
            const endByte:Number = repdata.exists ? repdata.size : 0;

            if (endByte <= startByte)
            {
                return;
            }

            try
            {
                AppDataPaths.replaySegmentCacheFolderPath.createDirectory();
            }
            catch (error:Error)
            {
                AppDataPaths.writeCrashLog(error);
                return;
            }

            const jobId:int = ++fillJobSeq;
            const job:Object = { jobId: jobId, generation: segmentCacheGeneration, startByte: startByte, endByte: endByte, startFrames: getCachedSegmentEndFrames(),
                    startTime: getTimer(), isNative: true };
            // 세대와 작업 번호를 이름에 넣어서 버려진 작업이 늦게 쓴 파일이 목록의 파일을 덮어쓰지 않게 함
            const segmentFileNamePrefix:String = "g" + job.generation + "j" + jobId + "_";
            const folderPath:String = AppDataPaths.replaySegmentCacheFolderPath.nativePath;
            runningFillJob = job;

            if (NativeReplaySegmentCache.startReplaySegmentCacheFill(repdata.nativePath, startByte, endByte, job.startFrames, folderPath, segmentFileNamePrefix,
                    cachedSegments.length, reuseFofoPath, function (result:Object):void
                    {
                        finishSegmentCacheFill(job, (result.status === "ok") ? result.segments : null, result);
                    }))
            {
                return;
            }

            // worker: 구간은 여기서 읽어 넘김 (repdata는 AIR가 공유 없이 열어 자르므로 worker가 직접 열지 않음)
            job.isNative = false;
            const replayBytes:ByteArray = new ByteArray();
            const fs:FileStream = new FileStream();

            try
            {
                fs.open(repdata, FileMode.READ);
                fs.position = startByte;
                fs.readBytes(replayBytes, 0, endByte - startByte);
                fs.close();
            }
            catch (error:Error)
            {
                fs.close();
                runningFillJob = null;
                AppDataPaths.writeCrashLog(error);
                return;
            }

            BackgroundWorkerCoordinator.startReplaySegmentEncodingWorker(jobId, replayBytes, job.startFrames, folderPath, segmentFileNamePrefix, cachedSegments.length);
        }

        // 채우기 결과 반영: 시작한 뒤 repdata가 그대로면 조각을 목록에 붙이고 기록, 아니면 쓴 파일을 지움. 기다리던 요청이 있으면 다시 채움
        private static function finishSegmentCacheFill(job:Object, segments:Array, result:Object):void
        {
            runningFillJob = null;
            const isDiscarded:Boolean = job.generation !== segmentCacheGeneration;
            lastFillResult = { status: result.status, isNative: job.isNative, startByte: job.startByte, endByte: job.endByte, segmentCount: (segments !== null) ? segments.length : 0,
                    reusedCount: result.reusedCount, encodeMs: result.encodeMs, writeMs: result.writeMs, wallMs: getTimer() - job.startTime, isDiscarded: isDiscarded };

            if (segments === null)
            {
                if (!isDiscarded)
                {
                    isFillStoppedByFailure = true;
                    AppDataPaths.writeCrashLog("Replay segment cache fill failed: " + result.message);
                }
            }
            else if (isDiscarded)
            {
                deleteSegmentFiles(segments);
            }
            else if (segments.length > 0)
            {
                var endByte:Number = job.startByte;

                for (var i:int = 0;i < segments.length;i++)
                {
                    const segment:Object = segments[i];
                    endByte += segment.rawLength;
                    cachedSegments.push({ fileName: segment.fileName, rawLength: segment.rawLength, rawCrc: segment.rawCrc, compressedLength: segment.compressedLength,
                            compressedCrc: segment.compressedCrc, endByte: endByte, endFrames: segment.endFrames });
                }

                writeSegmentLedger();
            }

            if (isFillRequestedWhileRunning)
            {
                isFillRequestedWhileRunning = false;
                const reuseFofoPath:String = reuseFofoPathForNextFill;
                reuseFofoPathForNextFill = "";
                requestSegmentCacheFill(reuseFofoPath);
            }
        }

        // 조각의 원본 crc가 지금 repdata의 그 구간과 같은지
        private static function isSegmentRawCrcSameAsRepdata(segment:Object):Boolean
        {
            const raw:ByteArray = new ByteArray();
            const fs:FileStream = new FileStream();

            try
            {
                fs.open(AppDataPaths.replayDataFilePath, FileMode.READ);
                fs.position = segment.endByte - segment.rawLength;
                fs.readBytes(raw, 0, segment.rawLength);
                fs.close();
            }
            catch (error:Error)
            {
                fs.close();
                return false;
            }

            const isSame:Boolean = raw.length === segment.rawLength && ReplayDataCodec.crc32OfBytes(raw, 0, raw.length) === segment.rawCrc;
            raw.clear();
            return isSame;
        }

        // 기록 파일을 읽어 조각 목록으로, 없거나 형식이 다르면 빈 목록
        private static function readSegmentLedger():Array
        {
            const segments:Array = [];
            const ledgerFile:File = AppDataPaths.replaySegmentCacheFolderPath.resolvePath(SEGMENT_LEDGER_FILE_NAME);
            const fs:FileStream = new FileStream();

            try
            {
                if (!ledgerFile.exists)
                {
                    return segments;
                }

                fs.open(ledgerFile, FileMode.READ);
                const ledger:Array = fs.readObject() as Array;
                fs.close();

                if (ledger === null || ledger[0] !== SEGMENT_LEDGER_VERSION || !(ledger[1] is Array))
                {
                    return segments;
                }

                for each (var entry:Array in ledger[1])
                {
                    segments.push({ fileName: String(entry[0]), rawLength: Number(entry[1]), rawCrc: Number(entry[2]), compressedLength: Number(entry[3]),
                            compressedCrc: Number(entry[4]), endByte: Number(entry[5]), endFrames: Number(entry[6]) });
                }
            }
            catch (error:Error)
            {
                fs.close();
                trace("Replay segment ledger read failed: " + error);
                segments.length = 0;
            }

            return segments;
        }

        // 조각 목록을 기록 파일에 씀 (임시 파일에 쓰고 교체), 못 쓰면 기록을 지워서 다음 실행때 캐시를 쓰지 않게 함
        private static function writeSegmentLedger():void
        {
            const folder:File = AppDataPaths.replaySegmentCacheFolderPath;
            const ledgerFile:File = folder.resolvePath(SEGMENT_LEDGER_FILE_NAME);
            const tempFile:File = folder.resolvePath(SEGMENT_LEDGER_FILE_NAME + ".tmp");
            const fs:FileStream = new FileStream();

            try
            {
                folder.createDirectory();
                const entries:Array = [];

                for each (var segment:Object in cachedSegments)
                {
                    entries.push([segment.fileName, segment.rawLength, segment.rawCrc, segment.compressedLength, segment.compressedCrc, segment.endByte, segment.endFrames]);
                }

                fs.open(tempFile, FileMode.WRITE);
                fs.writeObject([SEGMENT_LEDGER_VERSION, entries]);
                fs.close();
                tempFile.moveTo(ledgerFile, true);
            }
            catch (error:Error)
            {
                fs.close();
                AppDataPaths.writeCrashLog(error);

                try
                {
                    if (ledgerFile.exists)
                    {
                        ledgerFile.deleteFile();
                    }
                }
                catch (deleteError:Error)
                {
                }
            }
        }

        // 목록에 없는 조각 파일을 지움 (버려진 채우기가 남긴 파일, 이전 실행에서 남은 임시 파일)
        private static function deleteUnlistedSegmentFiles():void
        {
            const folder:File = AppDataPaths.replaySegmentCacheFolderPath;

            if (!folder.exists)
            {
                return;
            }

            const listedFileNames:Object = {};
            listedFileNames[SEGMENT_LEDGER_FILE_NAME] = true;

            for each (var segment:Object in cachedSegments)
            {
                listedFileNames[segment.fileName] = true;
            }

            for each (var file:File in folder.getDirectoryListing())
            {
                if (listedFileNames[file.name] !== true)
                {
                    deleteFileQuietly(file);
                }
            }
        }

        // 조각들의 파일을 지움 (segments가 null이면 아무것도 안 함)
        private static function deleteSegmentFiles(segments:Array):void
        {
            if (segments === null)
            {
                return;
            }

            for each (var segment:Object in segments)
            {
                deleteFileQuietly(AppDataPaths.replaySegmentCacheFolderPath.resolvePath(segment.fileName));
            }
        }

        private static function deleteFileQuietly(file:File):void
        {
            try
            {
                if (file.exists)
                {
                    file.deleteFile();
                }
            }
            catch (error:Error)
            {
                trace("Replay segment file delete failed: " + error);
            }
        }
    }
}
