package Modules.ReplayEngine
{
    import flash.display.BitmapData;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import Modules.BackgroundWorkerCoordinator;
    import Modules.CacheImageMetaData;
    import Modules.CanvasController;
    import Modules.FileManager;
    import Modules.ReferenceLayerController;
    import Modules.Utils;

    public class ReplayFileCache
    {
        public static const REPLAY_DISK_CACHE_FRAME_INTERVAL:Number = 10000;
        public static const REPLAY_MEMORY_CACHE_FRAME_INTERVAL:Number = 700;
      
        public static var rFirstImageLayer1BitmapData:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
        public static var rFirstImageLayer2BitmapData:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
        public static var rLastCacheImageIndex:int = -2; // 썸네일 인덱스 바뀌면 여기다 저장
        public static var rLastMemoryCachedImageIndex:int = -2; // 마지막에 그려준 캐쉬 이미지 번호를 저장
        public static var rTempCachedLastImageIndex:int = -2; // 더 잘게 쪼개준 이미지 인덱스 바뀌면 여기다 저장
        public static var rJumpImageFrameData:Array = [0]; // 스킵이미지 저장될때 r file frame sum을 저장해줌 처음에 rfirstimage라서 0번 추가해줌
        public static var rFrameTempCachedImages:Array = []; // 이전 탐색 프레임 빠르게 하기 위해서 jumpimage구간에서 더 잘게 이미지를 나누어주고 정보를여가다가 저장함

        public static function getReplayFileNameFromPath(path:String):String
        {
            return path.substr(0, path.lastIndexOf(".png")) + ".2020";
        }

        public static function initializeReplayDataFile(overWrite:Boolean = false):void // 기본 리플레이 파일 만들어줌
        {
            FileManager.initializeRepTempFile();

            if (FileManager.replayDataFilePath.exists === false || overWrite === true)
            {
                const fs:FileStream = new FileStream();
                fs.open(FileManager.replayDataFilePath, FileMode.WRITE);
                fs.close();
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

            // 실제 저장할 파일을 다시 써줌
            fs.open(FileManager.repFileTemp, FileMode.WRITE);
            fs.position = 0;
            fs.writeUTFBytes("FOFOPAINT"); // 파일 헤더
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

            fs.close();
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

            try
            {
                const newPath:String = getReplayFileNameFromPath(FileManager.lastSaveFilePath);
                FileManager.repFileTemp.moveTo(new File(newPath), true);
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
        }

        public static function loadReplayCacheImage(index:int):Object
        {
            const file:File = FileManager.replayCacheImageFolderPath.resolvePath(String(index));
            const fs:FileStream = new FileStream();
            fs.open(file, FileMode.READ);

            const data:Array = fs.readObject() as Array;
            fs.close();

            data[0].uncompress();
            data[1].uncompress();

            const metadata:CacheImageMetaData = data[2] as CacheImageMetaData;
            const rect:Rectangle = new Rectangle(0, 0, metadata.bmpdWidth, metadata.bmpdHeight);
            const layer1:BitmapData = new BitmapData(metadata.bmpdWidth,metadata.bmpdHeight,true,0);
            const layer2:BitmapData = new BitmapData( metadata.bmpdWidth,metadata.bmpdHeight,true,0);

            layer1.setPixels(rect, data[0]);
            layer2.setPixels(rect, data[1]);

            data[0].clear();
            data[1].clear();

            return {
                bmpd1:layer1,
                bmpd2:layer2,
                metadata:metadata
            };
        }

        public static function createFirstImageCache(bmpd1:BitmapData, bmpd2:BitmapData, bgColor:uint, mirrorFlag:Boolean = false):void
        {
            BackgroundWorkerCoordinator.cancelPendingCacheImages();

            if (FileManager.replayCacheImageFolderPath.exists)
            {
                FileManager.replayCacheImageFolderPath.deleteDirectory(true);
            }

            FileManager.replayCacheImageFolderPath.createDirectory();

            var ba1:ByteArray = new ByteArray();
            var ba2:ByteArray = new ByteArray();
            const w:Number = bmpd1.width;
            const h:Number = bmpd1.height;
            const newRectangle:Rectangle = new Rectangle(0, 0, w, h);

            //배열 버리고 새로 만들어주는데 메모메와 gc면에서 나은것같음
            rJumpImageFrameData = [];
            bmpd1.copyPixelsToByteArray(newRectangle, ba1);
            ba1.compress();
            rFirstImageLayer1BitmapData = CanvasController.updateBitmapData(rFirstImageLayer1BitmapData, bmpd1, null);

            if (bmpd2 === null)
            {
                bmpd2 = new BitmapData(w, h, true, 0);
            }

            bmpd2.copyPixelsToByteArray(newRectangle, ba2);
            ba2.compress();
            rFirstImageLayer2BitmapData = CanvasController.updateBitmapData(rFirstImageLayer2BitmapData, bmpd2, null);

            ReplaySaveMetaData.firstImageMirrorFlag = mirrorFlag;
            ReplaySaveMetaData.firstImageBG= bgColor;

            createCacheImage(ba1, ba2, new CacheImageMetaData(w, h, bgColor, 0, 0, 0, mirrorFlag, 0.0, 0.0));
            ba1.clear();
            ba2.clear();
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

        public static function createCacheImage(bmpd1:ByteArray, bmpd2:ByteArray, metadata:CacheImageMetaData):void
        {
            const fs:FileStream = new FileStream();
            rJumpImageFrameData.push(metadata.nowFrame);
            fs.open(FileManager.replayCacheImageFolderPath.resolvePath(String(rJumpImageFrameData.length - 1)), FileMode.WRITE);
            fs.writeObject([bmpd1, bmpd2, metadata]);
            fs.close();
        }

        // worker가 임시 파일로 써둔 캐시 이미지를 다음 번호로 확정해줌
        public static function commitCacheImage(tempFile:File, metadata:CacheImageMetaData):Boolean
        {
            // 이진 탐색이 깨지지 않게 마지막 캐시보다 뒤이고 리플레이 파일 안에 있는 프레임만 받음
            if (rJumpImageFrameData.length === 0
                    || metadata.nowFrame <= rJumpImageFrameData[rJumpImageFrameData.length - 1]
                    || metadata.nowFrame > ReplayState.getRFileDataTotalFrame())
            {
                return false;
            }

            try
            {
                tempFile.moveTo(FileManager.replayCacheImageFolderPath.resolvePath(String(rJumpImageFrameData.length)), true);
            }
            catch (error:Error)
            {
                trace("Cache image commit failed: " + error);
                return false;
            }

            rJumpImageFrameData.push(metadata.nowFrame);
            return true;
        }

        // frame 이후의 캐시 이미지를 지우고, worker에서 아직 만들고 있는 캐시 이미지도 무효로 만듬
        public static function truncateCacheImagesAfterFrame(frame:Number):void
        {
            BackgroundWorkerCoordinator.cancelPendingCacheImages();

            const list:Array = FileManager.replayCacheImageFolderPath.getDirectoryListing();
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
