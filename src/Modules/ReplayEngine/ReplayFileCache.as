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
        public static var rFirstImageMirrorFlag:Boolean = false; // 첫이미지 캔버스 미러 상태 저장
        public static var rFirstImageBGColor:uint = CanvasController.CANVAS_BG_COLOR;
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

        public static function writeReplayFile(dataA:ByteArray
                , dataA1:ByteArray
                , dataB:ByteArray
                , dataB1:ByteArray
                , dataC:ByteArray
                , dataD:ByteArray):void
        {
            const fs:FileStream = new FileStream();
            const rImgDataW:int = rFirstImageLayer1BitmapData.width;
            const rImgDataH:int = rFirstImageLayer1BitmapData.height;
            const refImgWidth:Number = ReferenceLayerController.canvasRefLayerBitmapData.width;
            const refImgHeight:Number = ReferenceLayerController.canvasRefLayerBitmapData.height;
            // 실제 저장할 파일을 다시 써줌
            fs.open(FileManager.repFileTemp, FileMode.WRITE);
            fs.position = 0;
            fs.writeUTFBytes("FOFOPAINT"); // 파일 헤더
            fs.writeUnsignedInt(dataD.length); // 뒤에 압축된 바이트를 얼마나 건너 뛰어야 하는지 저장
            fs.writeBytes(dataD);

            // 임시 미러 플래그임
            if (ReplayState.lastMirrorReadyFlag) // 임시 미러가 되어있을때 진짜 캔버스로 반전되어있는데 리플레이 데이터에는 아직 써주지 않았으니까 넣어줌
            {
                const tempMirrorData:Array = [["mirror"]];
                fs.writeObject(tempMirrorData);
            }

            fs.writeObject(["rFirstImage", dataA, dataA1, rImgDataW, rImgDataH, rFirstImageBGColor, rFirstImageMirrorFlag]);
            fs.writeObject(["rFinalImage", dataB, dataB1, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, CanvasController.CANVAS_BG_COLOR]);

            if (ReferenceLayerController.canvasRefLayerBitmapData)
            {
                fs.writeObject(["refimage", dataC, // 1
                            refImgWidth,
                            refImgHeight,
                            ReferenceLayerController.canvasRefLayerBitmap.x,
                            ReferenceLayerController.canvasRefLayerBitmap.y,
                            ReferenceLayerController.canvasRefLayer.rotation,
                            ReferenceLayerController.canvasRefLayer.scaleX,
                            ReferenceLayerController.canvasRefLayer.scaleY,
                            Boolean(ReferenceLayerController.canvasRefLayer.scaleX < 0),
                            ReferenceLayerController.refLayerMenuDragXMoveSum, // 10
                            ReferenceLayerController.refLayerLastAlpha]); // 11
            }

            fs.close();
            dataA.clear();
            dataA1.clear();
            dataB.clear();
            dataB1.clear();
            dataC.clear();
            dataD.clear();
            dataA = null;
            dataA1 = null;
            dataB = null;
            dataB1 = null;
            dataC = null;
            dataD = null;

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

                FileManager.enableFileOperationButtonsTopbar();
                FileManager.openSaveFileBrowser(true, true);
                return;
            }

            if (BackgroundWorkerCoordinator.isSaveInProgress === 1)
            {
                BackgroundWorkerCoordinator.isSaveInProgress = 0;
            }

            FileManager.enableFileOperationButtonsTopbar();
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

            rFirstImageMirrorFlag = mirrorFlag;
            rJumpImageFrameData.length = 0;
            bmpd1.copyPixelsToByteArray(newRectangle, ba1);
            ba1.compress();
            rFirstImageLayer1BitmapData = CanvasController.updateBitmapData(rFirstImageLayer1BitmapData, bmpd1, null);

            if (bmpd2 === null)
                bmpd2 = new BitmapData(w, h, true, 0);
            bmpd2.copyPixelsToByteArray(newRectangle, ba2);
            ba2.compress();
            rFirstImageLayer2BitmapData = CanvasController.updateBitmapData(rFirstImageLayer2BitmapData, bmpd2, null);
            rFirstImageBGColor = bgColor;
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

                rFrameTempCachedImages.length = 0;
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
    }
}
