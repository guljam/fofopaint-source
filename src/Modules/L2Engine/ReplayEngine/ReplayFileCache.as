package Modules.L2Engine.ReplayEngine
{
    import Modules.DrawEngine.DrawCanvas;
    import flash.display.BitmapData;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import flash.utils.getTimer;
    import Modules.CacheImageMetaData;
    import Modules.ReplayDataCodec;
    import Modules.CacheImageFile;
    import Modules.PixelRestore;
    import Modules.CacheImageFormat;
    import Modules.ReferenceLayerController;
    import Modules.Utils;
    import Modules.L5App.FileManager;
    import Modules.L2Engine.BackgroundWorkerCoordinator;
    import Modules.ReplayEngine.ReplaySaveMetaData;
    import Modules.ReplayEngine.ReplayState;
    import Modules.L1Data.AppDataPaths;
    import Modules.L4UI.UIEngine.HintController;

    // 층: L2 엔진 - 리플레이 파일(repdata) 쓰기와 캐시 이미지 생성·복원
    public class ReplayFileCache
    {
        public static const REPLAY_DISK_CACHE_FRAME_INTERVAL:Number = 10000;
        public static const REPLAY_MEMORY_CACHE_FRAME_INTERVAL:Number = 700;
      
        public static var rFirstImageLayer1BitmapData:BitmapData = new BitmapData(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, true, 0);
        public static var rFirstImageLayer2BitmapData:BitmapData = new BitmapData(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, true, 0);
        public static var rLastCacheImageIndex:int = -2; // 썸네일 인덱스 바뀌면 여기다 저장
        public static var rLastMemoryCachedImageIndex:int = -2; // 마지막에 그려준 캐쉬 이미지 번호를 저장
        public static var rTempCachedLastImageIndex:int = -2; // 더 잘게 쪼개준 이미지 인덱스 바뀌면 여기다 저장
        public static var rJumpImageFrameData:Array = [0]; // 스킵이미지 저장될때 r file frame sum을 저장해줌 처음에 rfirstimage라서 0번 추가해줌
        public static var rTimingSheetFileObject:Array = null; // 저장 시작때 만들어둔 ["rTimingSheet", ...] 객체, writeReplayFile에서 파일 끝에 쓰고 비움
        public static var rFrameTempCachedImages:Array = []; // 이전 탐색 프레임 빠르게 하기 위해서 jumpimage구간에서 더 잘게 이미지를 나누어주고 정보를여가다가 저장함

        public static function getReplayFileNameFromPath(path:String):String
        {
            // 저장은 .fofo, 불러오기는 내용(헤더)으로 판단해서 이전 .2020 파일도 열림
            return path.substr(0, path.lastIndexOf(".png")) + ".fofo";
        }

        public static function initializeReplayDataFile(overWrite:Boolean = false):void // 기본 리플레이 파일 만들어줌
        {
            FileManager.initializeRepTempFile();

            if (AppDataPaths.replayDataFilePath.exists === false || overWrite === true)
            {
                const fs:FileStream = new FileStream();
                fs.open(AppDataPaths.replayDataFilePath, FileMode.WRITE);
                fs.close();
                ReplayDrawer.commandWindow.dispose(); // repdata가 바뀌었으니 미리 읽은 묶음은 버림
                TimingSheetFile.reset();
            }
        }

        public static function writeReplayFile(
                firstImageLayer1:ByteArray,
                firstImageLayer2:ByteArray,
                finalImageLayer1:ByteArray,
                finalImageLayer2:ByteArray,
                referenceImage:ByteArray,
                replayFileByteArray:ByteArray):void
        {
            const fs:FileStream = new FileStream();
            var isWritten:Boolean = true;

            try
            {
                // 실제 저장할 파일을 다시 써줌
                fs.open(FileManager.repFileTemp, FileMode.WRITE);
                fs.position = 0;
                // 파일 헤더, 리플레이 블록이 코덱 형식이면 이전 버전과 구분되게 V2FOFOPAINT
                fs.writeUTFBytes(ReplayDataCodec.isEncoded(replayFileByteArray) ? FileManager.REPLAY_FILE_HEADER_V2 : FileManager.REPLAY_FILE_HEADER_V1);
                fs.writeUnsignedInt(replayFileByteArray.length); // 뒤에 압축된 바이트를 얼마나 건너 뛰어야 하는지 저장
                fs.writeBytes(replayFileByteArray);

                // 임시 미러 플래그임
                if (ReplayState.lastMirrorReadyFlag) // 임시 미러가 되어있을때 진짜 캔버스로 반전되어있는데 리플레이 데이터에는 아직 써주지 않았으니까 넣어줌
                {
                    const tempMirrorData:Array = [["mirror"]];
                    fs.writeObject(tempMirrorData);
                }

                fs.writeObject(["rFirstImage", firstImageLayer1,
                                            firstImageLayer2,
                                            ReplaySaveMetaData.firstImageWidth,
                                            ReplaySaveMetaData.firstImageHeight,
                                            ReplaySaveMetaData.firstImageBG,
                                            ReplaySaveMetaData.firstImageMirrorFlag]);
                fs.writeObject(["rFinalImage", finalImageLayer1, finalImageLayer2, ReplaySaveMetaData.finalImageWidth,ReplaySaveMetaData.finalImageHeight,ReplaySaveMetaData.finalImageBG]);

                if (ReferenceLayerController.canvasRefLayerBitmapData)
                {
                    fs.writeObject(["refimage", referenceImage, // 1
                                ReplaySaveMetaData.refImageWidth,
                                ReplaySaveMetaData.refImageHeight,
                                ReplaySaveMetaData.refImageBitmapX,
                                ReplaySaveMetaData.refImageBitmapY,
                                ReplaySaveMetaData.refImageBitmapRotation,
                                ReplaySaveMetaData.refImageBitmapScaleX,
                                ReplaySaveMetaData.refImageBitmapScaleY,
                                ReplaySaveMetaData.refImageBitmapMirrorFlag,
                                ReplaySaveMetaData.refImageBitmapMoveSum,
                                ReplaySaveMetaData.refImageAlpha]);
                }

                // 타이밍 시트는 파일 맨 뒤에 둠. 읽을때 이 객체가 없으면 시트 없는 파일로 봄
                if (rTimingSheetFileObject !== null)
                {
                    fs.writeObject(rTimingSheetFileObject);
                }

                fs.close();
            }
            catch (writeErr:Error)
            {
                // 임시 파일 쓰기 실패(디스크 부족, 잠김 등), 아래에서 저장 잠금을 풀고 새 파일로 저장해줌
                isWritten = false;

                try
                {
                    fs.close();
                }
                catch (closeErr:Error)
                {
                }
            }

            rTimingSheetFileObject = null;
            firstImageLayer1.clear();
            firstImageLayer2.clear();
            finalImageLayer1.clear();
            finalImageLayer2.clear();
            referenceImage.clear();
            replayFileByteArray.clear();
            firstImageLayer1 = null;
            firstImageLayer2 = null;
            finalImageLayer1 = null;
            finalImageLayer2 = null;
            referenceImage = null;
            replayFileByteArray = null;

            var savedFile:File;

            try
            {
                if (isWritten === false)
                {
                    throw new Error("replay temp file write failed");
                }
                const newPath:String = getReplayFileNameFromPath(FileManager.lastSaveFilePath);
                savedFile = new File(newPath);
                FileManager.repFileTemp.moveTo(savedFile, true);
            }
            catch (err:Error)
            {
                // 파일 엑세스가 불가하므로 새로운 파일로 저장해줌

                if (BackgroundWorkerCoordinator.isSaveInProgress === 1)
                {
                    BackgroundWorkerCoordinator.isSaveInProgress = 0;
                }

                FileManager.openSaveFileBrowser(true, true);
                return;
            }

            if (BackgroundWorkerCoordinator.isSaveInProgress === 1)
            {
                BackgroundWorkerCoordinator.isSaveInProgress = 0;
            }

            HintController.showMouseHintTemp("Saved (" + (getTimer() - FileManager.saveStartTime) + " ms, " + formatFileSize(savedFile.size) + ")",10.0);
        }

        public static function formatFileSize(bytes:Number):String
        {
            if (bytes >= 1048576)
            {
                return (bytes / 1048576).toFixed(2) + " MB";
            }

            if (bytes >= 1024)
            {
                return (bytes / 1024).toFixed(1) + " KB";
            }

            return bytes + " B";
        }

        // {bmpd1, bmpd2, metadata}, 새 형식(네이티브 덤프)과 옛 형식 모두 읽음 (CacheImageFile)
        public static function loadReplayCacheImage(index:int):Object
        {
            return CacheImageFile.read(AppDataPaths.replayCacheImageFolderPath.resolvePath(String(index)));
        }

        // 캐시 이미지 만드는 도중에 앱을 닫아도 다음 실행때 이어서 만들수 있게 지금까지 확정된 캐시 번호 목록을 기록
        // repdata 크기, 수정 시간도 같이 넣어서 다른 리플레이 데이터의 캐시로 이어가지 않게 함
        // 캐시 이미지 파일을 다 쓴 다음에 부르므로 기록에 있는 번호는 전부 온전한 파일임
        public static function saveCacheProgress():void
        {
            const dataFile:File = AppDataPaths.replayDataFilePath;
            const tempFile:File = AppDataPaths.replayCacheProgressFilePath.parent.resolvePath(AppDataPaths.replayCacheProgressFilePath.name + ".tmp");
            const fs:FileStream = new FileStream();

            try
            {
                fs.open(tempFile, FileMode.WRITE);
                // 마지막은 캐시 파일 형식 버전, 다르면 이어 만들지 않고 처음부터 다시 만듦
                fs.writeObject([dataFile.size, dataFile.modificationDate.getTime(), rJumpImageFrameData.concat(), CacheImageFormat.VERSION]);
                fs.close();
                tempFile.moveTo(AppDataPaths.replayCacheProgressFilePath, true);
            }
            catch (error:Error)
            {
                // 기록을 못 남기면 다음 실행때 처음부터 다시 만들면 되니 캐시 생성은 계속함
                trace("Cache progress save failed: " + error);
                deleteCacheProgress();
            }
        }

        // 진행 기록과 로드박스 배경 이미지 기록을 같이 지움
        public static function deleteCacheProgress():void
        {
            try
            {
                if (AppDataPaths.replayCacheProgressFilePath.exists)
                {
                    AppDataPaths.replayCacheProgressFilePath.deleteFile();
                }

                if (AppDataPaths.replayCachePreviewFilePath.exists)
                {
                    AppDataPaths.replayCachePreviewFilePath.deleteFile();
                }
            }
            catch (error:Error)
            {
                trace("Cache progress delete failed: " + error);
            }
        }

        // 캐시 이미지 만드는 도중 앱을 닫을때 로드박스에 깔려있던 흐린 배경 이미지를 저장해서 다음 실행때 이어 만들때 다시 깔아줌
        // 배경 이미지가 없으면 기록을 지움
        public static function saveCachePreview(bmpd:BitmapData):void
        {
            try
            {
                if (bmpd === null)
                {
                    if (AppDataPaths.replayCachePreviewFilePath.exists)
                    {
                        AppDataPaths.replayCachePreviewFilePath.deleteFile();
                    }
                    return;
                }

                const ba:ByteArray = new ByteArray();
                bmpd.copyPixelsToByteArray(bmpd.rect, ba);
                ba.compress();

                const fs:FileStream = new FileStream();
                fs.open(AppDataPaths.replayCachePreviewFilePath, FileMode.WRITE);
                fs.writeObject([bmpd.width, bmpd.height, bmpd.transparent, ba]);
                fs.close();
                ba.clear();
            }
            catch (error:Error)
            {
                trace("Cache preview save failed: " + error);
            }
        }

        // 저장된 배경 이미지가 없거나 읽지 못하면 null
        public static function loadCachePreview():BitmapData
        {
            try
            {
                if (!AppDataPaths.replayCachePreviewFilePath.exists)
                {
                    return null;
                }

                const fs:FileStream = new FileStream();
                fs.open(AppDataPaths.replayCachePreviewFilePath, FileMode.READ);
                const data:Array = fs.readObject() as Array;
                fs.close();

                const ba:ByteArray = data[3] as ByteArray;
                ba.uncompress();
                const bmpd:BitmapData = new BitmapData(data[0], data[1], data[2], 0);
                PixelRestore.setPixels(bmpd, bmpd.rect, ba);
                ba.clear();
                return bmpd;
            }
            catch (error:Error)
            {
                trace("Cache preview load failed: " + error);
            }

            return null;
        }

        // 이어서 만들수 있으면 rJumpImageFrameData를 기록대로 되돌리고 이어서 시작할 캐시 번호를 돌려줌, 못하면 -1
        public static function restoreCacheProgress():int
        {
            const dataFile:File = AppDataPaths.replayDataFilePath;
            const fs:FileStream = new FileStream();

            try
            {
                if (!AppDataPaths.replayCacheProgressFilePath.exists || !dataFile.exists)
                {
                    return -1;
                }

                fs.open(AppDataPaths.replayCacheProgressFilePath, FileMode.READ);
                const progress:Array = fs.readObject() as Array;
                fs.close();

                if (progress === null || progress.length !== 4 || progress[3] !== CacheImageFormat.VERSION
                        || progress[0] !== dataFile.size
                        || progress[1] !== dataFile.modificationDate.getTime())
                {
                    return -1;
                }

                const frames:Array = progress[2] as Array;

                if (frames === null || frames.length === 0 || frames[0] !== 0)
                {
                    return -1;
                }

                // 번호마다 파일이 새 형식으로 온전한지(헤더만 읽음), 기록된 프레임과 맞는지 확인
                var lastByte:Number = 0;

                for (var i:int = 0;i < frames.length;i++)
                {
                    if (i > 0 && !(frames[i] > frames[i - 1]))
                    {
                        return -1;
                    }

                    const metadata:CacheImageMetaData = CacheImageFile.readNewFormatMetadata(AppDataPaths.replayCacheImageFolderPath.resolvePath(String(i)));

                    if (metadata === null
                            || metadata.nowFrame !== frames[i]
                            || metadata.lastByte < lastByte
                            || metadata.lastByte > dataFile.size
                            || metadata.bmpdWidth <= 0 || metadata.bmpdHeight <= 0)
                    {
                        return -1;
                    }

                    lastByte = metadata.lastByte;
                }

                rJumpImageFrameData = frames.concat();
                return frames.length - 1;
            }
            catch (error:Error)
            {
                // 읽다가 실패한 파일을 잡고 있으면 처음부터 다시 만들때 지워지지 않으니 닫아줌
                fs.close();
                trace("Cache progress restore failed: " + error);
            }

            return -1;
        }

        public static function createFirstImageCache(bmpd1:BitmapData, bmpd2:BitmapData, bgColor:uint, mirrorFlag:Boolean = false):void
        {
            BackgroundWorkerCoordinator.cancelPendingCacheImages();
            deleteCacheProgress();

            // 폴더를 지우고 바로 다시 만들면 다른 프로그램이 안의 파일을 잡고 있을때 삭제 대기 상태가 되어 생성이 실패할수 있어서 안의 파일만 지움
            // 캐시는 번호 목록 범위 안에서만 읽고 새 캐시는 덮어쓰기로 쓰니 못 지운 파일이 남아도 결과는 같음
            if (AppDataPaths.replayCacheImageFolderPath.exists)
            {
                const list:Array = AppDataPaths.replayCacheImageFolderPath.getDirectoryListing();

                for (var i:int = 0;i < list.length;i++)
                {
                    try
                    {
                        list[i].deleteFile();
                    }
                    catch (error:Error)
                    {
                        trace("Cache image cleanup failed: " + error);
                    }
                }
            }
            else
            {
                AppDataPaths.replayCacheImageFolderPath.createDirectory();
            }

            const w:Number = bmpd1.width;
            const h:Number = bmpd1.height;

            if (bmpd2 === null)
            {
                bmpd2 = new BitmapData(w, h, true, 0);
            }

            // 캐시 0번 (첫 이미지)은 바로 읽히므로 호출 안에서 다 씀, 네이티브면 내부 버퍼 원본 덤프
            //배열 버리고 새로 만들어주는데 메모메와 gc면에서 나은것같음
            rJumpImageFrameData = [0];
            CacheImageFile.writeSync(AppDataPaths.replayCacheImageFolderPath.resolvePath("0"), bmpd1, bmpd2, new CacheImageMetaData(w, h, bgColor, 0, 0, 0, mirrorFlag, 0.0, 0.0));
            rFirstImageLayer1BitmapData = DrawCanvas.updateBitmapData(rFirstImageLayer1BitmapData, bmpd1, null);
            rFirstImageLayer2BitmapData = DrawCanvas.updateBitmapData(rFirstImageLayer2BitmapData, bmpd2, null);

            ReplaySaveMetaData.firstImageMirrorFlag = mirrorFlag;
            ReplaySaveMetaData.firstImageBG= bgColor;
        }

        public static function refreshRFrameTempCachedImages():void
        {
            rFrameTempCachedImages = [];
        }

        public static function clearRFrameTempCache():void
        {
            if (rFrameTempCachedImages.length > 0)
            {
                for (var i:int = 0;i < rFrameTempCachedImages.length;i++)
                {
                    rFrameTempCachedImages[i][0].dispose();
                    rFrameTempCachedImages[i][1].dispose();
                }

                rFrameTempCachedImages = [];
                rLastCacheImageIndex = -2;
                rLastMemoryCachedImageIndex = -2;
                refreshRFrameTempCachedImages();
            }
        }

        public static function getRFrameTempCacheLastFrame():Number
        {
            if(rFrameTempCachedImages.length === 0) return 0.0;

            return rFrameTempCachedImages[rFrameTempCachedImages.length - 1][2].nowFrame;
        }

        public static function createRFrameTempCache(lastFrame:Number, lastReadBytes:Number):void
        {
            rFrameTempCachedImages.push(
                    [
                        ReplayDrawer.rCanvasLayer1BitmapData.clone(),
                        ReplayDrawer.rCanvasLayer2BitmapData.clone(),
                        new CacheImageMetaData(
                            ReplayDrawer.rCanvasLayer1BitmapData.width,
                            ReplayDrawer.rCanvasLayer1BitmapData.height,
                            ReplayState.RCANVAS_BG_COLOR,
                            lastReadBytes,
                            lastFrame,
                            ReplayState.rNowFrame,
                            ReplayState.rMirrorON)]);
        }

        // targetFrame이 rFrameCacheImages데이터에 몆 번 인덱스에 있나 구해줌
        public static function getCacheImageIndex(targetFrame:Number):int
        {
            return Utils.binarySearchIndex(rFrameTempCachedImages, targetFrame, function (item:*):Number
                {
                    return item[2].nowFrame;
                });
        }

        // targetFrame이 rJumpImageFrameData데이터에 몆 번 인덱스에 있나 구해줌
        public static function getCachedFrameImageIndex(targetFrame:Number):int
        {
            return Utils.binarySearchIndex(rJumpImageFrameData, targetFrame, function (item:*):Number
                {
                    return Number(item);
                });
        }

        // 다음 번호로 캐시 이미지를 호출 안에서 씀 (네이티브 병렬 작업을 못 쓸때의 불러오기 캐시)
        public static function createCacheImage(layer1:BitmapData, layer2:BitmapData, metadata:CacheImageMetaData):void
        {
            rJumpImageFrameData.push(metadata.nowFrame);
            CacheImageFile.writeSync(AppDataPaths.replayCacheImageFolderPath.resolvePath(String(rJumpImageFrameData.length - 1)), layer1, layer2, metadata);
        }

        // worker(또는 네이티브)가 임시 파일로 써둔 캐시 이미지를 다음 번호로 확정해줌 (undo 캐시)
        public static function commitCacheImage(tempFile:File, metadata:CacheImageMetaData):Boolean
        {
            // 이진 탐색이 깨지지 않게 마지막 캐시보다 뒤이고 리플레이 파일 안에 있는 프레임만 받음
            if (rJumpImageFrameData.length === 0
                    || metadata.nowFrame <= rJumpImageFrameData[rJumpImageFrameData.length - 1]
                    || metadata.nowFrame > ReplayState.getRFileDataTotalFrame())
            {
                return false;
            }

            if (!moveTempCacheImage(tempFile, rJumpImageFrameData.length))
            {
                return false;
            }

            rJumpImageFrameData.push(metadata.nowFrame);
            return true;
        }

        // 임시 파일을 index번 캐시 파일로 옮기고 정말 옮겨졌는지 확인 (rJumpImageFrameData는 부른 쪽이 갱신)
        // undo 캐시(commitCacheImage)와 불러오기 캐시(ReplayController.generateReplayCacheImage)가 같이 씀
        public static function moveTempCacheImage(tempFile:File, index:int):Boolean
        {
            const dest:File = AppDataPaths.replayCacheImageFolderPath.resolvePath(String(index));

            try
            {
                const size:Number = tempFile.size;
                tempFile.moveTo(dest, true);

                // 권한 문제등으로 moveTo가 예외 없이 끝나도 옮겨지지 않은 경우가 있어서 실제로 옮겨졌는지 확인한 뒤에만 번호를 확정
                // 같은 번호의 오래된 파일이 남아있을수 있으니 크기까지 비교
                if (size <= 0 || !dest.exists || dest.size !== size || tempFile.exists)
                {
                    AppDataPaths.writeCrashLog("Cache image commit not moved: " + dest.nativePath);
                    return false;
                }
            }
            catch (error:Error)
            {
                trace("Cache image commit failed: " + error);
                return false;
            }

            return true;
        }

        // 불러오기 캐시 임시 폴더를 만들고 안의 파일을 지움 (생성 시작, 앱 시작 때), 못 지운 파일은 남겨도 이름이 겹치지 않음
        public static function clearLoadCacheTempFolder():void
        {
            const folder:File = AppDataPaths.replayCacheImageLoadTempFolderPath;

            try
            {
                if (!folder.exists)
                {
                    folder.createDirectory();
                    return;
                }

                const list:Array = folder.getDirectoryListing();

                for (var i:int = 0;i < list.length;i++)
                {
                    deleteFileQuietly(list[i]);
                }
            }
            catch (error:Error)
            {
                trace("Load cache temp folder cleanup failed: " + error);
            }
        }

        public static function deleteFileQuietly(file:File):void
        {
            try
            {
                if (file !== null && file.exists)
                {
                    file.deleteFile();
                }
            }
            catch (error:Error)
            {
                trace("Cache temp file delete failed: " + error);
            }
        }

        // frame 이후의 캐시 이미지를 지우고, worker에서 아직 만들고 있는 캐시 이미지도 무효로 만듬
        public static function truncateCacheImagesAfterFrame(frame:Number):void
        {
            BackgroundWorkerCoordinator.cancelPendingCacheImages();

            const list:Array = AppDataPaths.replayCacheImageFolderPath.getDirectoryListing();
            const index:int = getCachedFrameImageIndex(frame);

            // index번 이후 파일 삭제
            for (var i:uint = 0, len:uint = list.length;i < len;i++)
            {
                if (parseInt(list[i].name) > index)
                {
                    list[i].deleteFile();
                }
            }

            // framedata도 인덱스 이후꺼 날려줌
            rJumpImageFrameData.splice(index + 1);
        }
    }
}
