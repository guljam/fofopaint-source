package Modules.ReplayEngine
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.CapsStyle;
    import flash.display.JointStyle;
    import flash.display.LineScaleMode;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.filters.BlurFilter;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import Symbols.FOFOCursorSet;
    import Modules.CacheImageMetaData;
    import Modules.CanvasController;
    import Modules.FileManager;
    import Modules.UndoController;
    import Modules.UndoManager;

    public class ReplayDrawer
    {
        // 리플레이
        public static var rFileStream:FileStream = new FileStream(); // 함수들을 왔다갔다 해야해서 전역으로 하나
        public static var rCanvasAnchorPoint:Sprite = new Sprite(); // 회전 스프라이트 부모
        public static var rCanvasPanel:Sprite = new Sprite();
        public static var rCanvasDrawLayer:Sprite = new Sprite();
        public static var rCanvasDrawShape:Shape = new Shape();
        public static var rCanvasLayer1BitmapData:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
        public static var rCanvasLayer2BitmapData:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
        public static var rCanvasDrawLayerBitmapData:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
        public static var rCanvasLayer1Bitmap:Bitmap = new Bitmap(rCanvasLayer1BitmapData, "auto", true);
        public static var rCanvasLayer2Bitmap:Bitmap = new Bitmap(rCanvasLayer2BitmapData, "auto", true);
        public static var rCanvasDrawLayerBitmap:Bitmap = new Bitmap(rCanvasDrawLayerBitmapData, "auto", true);
        public static var rReplayFOFOCursor:FOFOCursorSet = new FOFOCursorSet(); // 재생할때 틀어주는 작은 마우스 커서
        public static var rCanvasDrawLayerClipRectLegacy:Rectangle = new Rectangle(); // 갱신된 부분만 그려주는 거 오래된 버전 지원때문에 남겨둠
        public static var rCanvasDrawLayerClipRect:Rectangle = new Rectangle(); // 갱신된 부분만 그려주는 거 이게 새거임
        public static const JUMP_FRAME_PLAY:int = (1 << 0); // 그냥 재생할때
        public static const JUMP_FRAME_MANUAL:int = (1 << 1); // 탐색바에서 마우스 특정 프레임 클릭
        public static const JUMP_FRAME_PREV:int = (1 << 2); // 이전 프레임으로 이동 (프레임 감소)
        public static const JUMP_FRAME_NEXT:int = (1 << 3); // 이후 프레임으로 이동 (프레임 증가)

        private static var readCount:Number = 0;
        private static var rMemoryDataLen:uint;

        // 데이터를 읽다 말았으면 끝까지 한세트 끝나게 프레임 이동시킴
        public static function finalizeRemainingReplayData():void
        {
            renderReplayFrame(ReplayState.rNowFrame + ReplayDrawCommands.getRemainingData(), ReplayDrawer.JUMP_FRAME_MANUAL);
        }

        public static function updateReplayCanvasFromUndoBaseInfo():void
        {
            const undoBaseImage:Array = UndoController.getUndoBaseImage();

            if (undoBaseImage[2] !== ReplayState.RCANVAS_WIDTH || undoBaseImage[3] !== ReplayState.RCANVAS_HEIGHT)
            {
                updateCanvasSizeReplayMode(undoBaseImage[2], undoBaseImage[3], 0, 0, false);
            }

            if (undoBaseImage[4] !== ReplayState.RCANVAS_BG_COLOR)
            {
                updateCanvasBGColorReplayMode(undoBaseImage[4]);
            }

            rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, undoBaseImage[0], rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, undoBaseImage[1], rCanvasLayer2Bitmap);
            ReplayState.rMirrorON = undoBaseImage[5];

            ReplayDrawCommands.setData(ReplayState.rMemoryData[0]);
            ReplayDrawCommands.drawAll();

            if (undoBaseImage[0] && undoBaseImage[0] !== rCanvasLayer1BitmapData)
            {
                undoBaseImage[0].dispose();
            }

            if (undoBaseImage[1] && undoBaseImage[1] !== rCanvasLayer2BitmapData)
            {
                undoBaseImage[1].dispose();
            }

            undoBaseImage[0] = rCanvasLayer1BitmapData.clone();
            undoBaseImage[1] = rCanvasLayer2BitmapData.clone();
            undoBaseImage[2] = ReplayState.RCANVAS_WIDTH;
            undoBaseImage[3] = ReplayState.RCANVAS_HEIGHT;
            undoBaseImage[4] = ReplayState.RCANVAS_BG_COLOR;
            undoBaseImage[5] = ReplayState.rMirrorON;

            ReplayDrawCommands.setFirstRCursorPosCurrent();
        }

        public static function updateReplayCanvasFromUndoRefData(undoRefData:Array, undoIndexSave:int):void
        {
            ReplayState.rMemoryDataReadON = true;
            ReplayState.rMemoryDataIndex = undoIndexSave;
            ReplayState.rPrevFrame = ReplayState.rNowFrame;
            ReplayState.rNowFrame = ReplayState.getNowFrameUntilUndoIndex(undoIndexSave);

            ReplayState.rMirrorON = undoRefData[5];
            const rect:Rectangle = new Rectangle(0, 0, undoRefData[2], undoRefData[3]);

            if (undoRefData[2] !== ReplayState.RCANVAS_WIDTH || undoRefData[3] !== ReplayState.RCANVAS_HEIGHT)
            {
                updateCanvasSizeReplayMode(undoRefData[2], undoRefData[3], 0, 0, false);
            }

            if (undoRefData[4] !== ReplayState.RCANVAS_BG_COLOR)
            {
                updateCanvasBGColorReplayMode(undoRefData[4]);
            }

            rCanvasDrawShape.graphics.clear();

            rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, undoRefData[0], rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, undoRefData[1], rCanvasLayer2Bitmap);

            if (ReplayState.rMemoryData.length > 0)
            {
                for (var i:int = 0;i <= undoIndexSave;i++)
                {
                    if (!ReplayState.rMemoryData[i])
                        continue;
                    ReplayDrawCommands.setData(ReplayState.rMemoryData[i]);
                    ReplayDrawCommands.drawAll();
                }
            }
        }

        public static function drawFirstJumpImage():void
        {
            const cacheImageData:Object = ReplayFileCache.loadReplayCacheImage(0);

            rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, cacheImageData.bmpd1, rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, cacheImageData.bmpd2, rCanvasLayer2Bitmap);
            cacheImageData.bmpd1.dispose();
            cacheImageData.bmpd2.dispose();

            updateCanvasSizeReplayMode(rCanvasLayer1Bitmap.width, rCanvasLayer1Bitmap.height);
            updateCanvasBGColorReplayMode(cacheImageData.metadata.bgColor);
            ReplayState.rMirrorON = cacheImageData.metadata.mirrorFlag;
        }

        public static function drawCacheImageFirst(tragetFrame:Number):Number
        {
            const index:int = ReplayFileCache.getCachedFrameImageIndex(tragetFrame);
            var rMemoryCachedImageIndex:Number = -1; // 자잘 썸네일 인덱스를 넣어줌
            var loadCacheFlag:int = 0;
            var remainingFrameCount:Number = 0.0;

            // isReplayStarted 붙여주는 이유는
            // slide show모드로 재생하게 되면 클리어 케시를 계속 호출해주고
            // 재생 완료시 rJumpImageIndexLast가 갱신되어있을때 다시 해주면 메모리 캐시가 없는데 캐시를 불러주는 버그가 생겨서
            // 아무생각없이 넣어본건데 버그 안나서 그대로 두려고함
            if (index !== ReplayFileCache.rLastCacheImageIndex && ReplayState.isReplayStarted === false)
            {
                ReplayFileCache.clearRFrameTempCache();
                loadCacheFlag = 1;
            }
            else if (ReplayFileCache.rFrameTempCachedImages.length > 0)
            {
                if (tragetFrame >= ReplayFileCache.rFrameTempCachedImages[0][2].nowFrame)
                {
                    rMemoryCachedImageIndex = ReplayFileCache.getCacheImageIndex(tragetFrame);

                    if (ReplayFileCache.rLastMemoryCachedImageIndex !== rMemoryCachedImageIndex || tragetFrame < ReplayState.rNowFrame)
                    {
                        loadCacheFlag = 2;
                    }
                }
            }

            if (loadCacheFlag > 0 || tragetFrame < ReplayState.rNowFrame)
            {
                var cachedImageData:Array;
                var metaData:CacheImageMetaData;
                var layer1bmpd:BitmapData;
                var layer2bmpd:BitmapData;
                var newrect:Rectangle;

                if (loadCacheFlag === 2)
                {
                    cachedImageData = ReplayFileCache.rFrameTempCachedImages[rMemoryCachedImageIndex];
                    layer1bmpd = cachedImageData[0];
                    layer2bmpd = cachedImageData[1];
                    metaData = cachedImageData[2];
                    ReplayFileCache.rLastMemoryCachedImageIndex = rMemoryCachedImageIndex;
                }
                else
                {
                    const cacheImageData:Object = ReplayFileCache.loadReplayCacheImage(index);
                    layer1bmpd = cacheImageData.bmpd1;
                    layer2bmpd = cacheImageData.bmpd2;
                    metaData = cacheImageData.metadata as CacheImageMetaData;
                }

                ReplayFileCache.rLastCacheImageIndex = index;
                ReplayState.rMemoryDataIndex = 0; // 이거 먼저 초기화 시켜주어야함
                ReplayState.rNowFrame = metaData.nowFrame; // 썸네일 이미지를 저장한 프레임
                ReplayState.rFileLastBytePosition = metaData.lastByte; // 마지막 바이트
                rFileStream.position = metaData.lastByte;
                // 원하는 프레임에서 썸네일 이미지 프레임을 빼줌 나머지 프레임만 그려주면 되니깐
                remainingFrameCount = tragetFrame - metaData.nowFrame;
                ReplayDrawCommands.clearData();
                clearCanvasReplayMode();
                ReplayState.rMirrorON = metaData.mirrorFlag;
                rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, layer1bmpd, rCanvasLayer1Bitmap);
                rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, layer2bmpd, rCanvasLayer2Bitmap);
                updateCanvasSizeReplayMode(rCanvasLayer1Bitmap.width, rCanvasLayer1Bitmap.height);
                updateCanvasBGColorReplayMode(metaData.bgColor);
                ReplayDrawCommands.setRCursorPos(metaData.rCursorPosX, metaData.rCursorPosY);

                if (loadCacheFlag === 1 && ReplayState.isReplayStarted === false)
                {
                    ReplayFileCache.refreshRFrameTempCachedImages();
                    ReplayFileCache.createRFrameTempCache(metaData.lastFrame, ReplayState.rFileLastBytePosition);
                }

                cachedImageData = null;
                ReplayState.rMemoryDataReadON = false;
                ReplayState.rMemoryDataStartIndex = 0;

                if (loadCacheFlag !== 2)
                {
                    layer1bmpd.dispose();
                    layer2bmpd.dispose();
                    layer1bmpd = null;
                    layer2bmpd = null;
                }

                if (remainingFrameCount === 0.0)
                {
                    ReplayState.rPrevFrame = metaData.lastFrame;
                }
            }
            else
            {
                if (!ReplayState.rMemoryDataReadON)
                {
                    rFileStream.position = ReplayState.rFileLastBytePosition;
                }

                remainingFrameCount = tragetFrame - ReplayState.rNowFrame;
            }

            return remainingFrameCount;
        }

        public static function renderReplayFrame(frame:Number, jumpflag:int):void // jumpp
        {
            if (frame < 0)
            {
                frame = 0;
            }
            else if (frame > ReplayState.TOTAL_FRAME)
            {
                frame = ReplayState.TOTAL_FRAME;
            }

            if (ReplayState.isReplayModeON)
            {
                if (frame >= ReplayState.TOTAL_FRAME && ReplayState.isReplayFinished)
                {
                    return;
                }
            }

            rFileStream.open(FileManager.replayDataFilePath, FileMode.READ);
            const remainingFrameCount:Number = drawCacheImageFirst(frame);
            ReplayDrawer.startDraw(remainingFrameCount, jumpflag);
            rFileStream.close();
            // dodraw밑이기 때문에 rFrameSum이 갱신되서 위에 nowFrame은 쓸수가 없음

            if (ReplayState.rNowFrame >= ReplayState.TOTAL_FRAME)
            {
                if (ReplayState.isReplayModeON) // deepundo도 있어서
                {
                    if (!ReplayState.isReplayFinished)
                    {
                        ReplayState.isReplayFinished = true;
                        // syncMirrorReplayModeWithDrawMode();
                    }

                    rReplayFOFOCursor.visible = false;
                }
            }
            else
            {
                ReplayState.isReplayFinished = false;
                rReplayFOFOCursor.visible = true;
            }

            ReplayDrawCommands.updateRCursorPos();

            if (!ReplayState.isReplaySlideShowMode && !ReplayState.isReplayCanvasFitToWindow && !UndoManager.isDeepUndoEnabled)
            {
                ReplayController.rFollowMouse.check(true);
            }
        }

        public static function updateReplayCursorScale(zoom:Number):void
        {
            const z:Number = 1.0 / zoom;
            rReplayFOFOCursor.scaleX = z;
            rReplayFOFOCursor.scaleY = z;
        }

        public static function setRcursorRotation(newAngle:Number):void
        {
            rReplayFOFOCursor.rotation = -newAngle;
        }

        public static function mirrorRCursorPos():void
        {
            const p:Point = ReplayDrawCommands.getRCursorPos();
            const half:Number = CanvasController.CANVAS_WIDTH / 2;
            const curcorX:Number = rReplayFOFOCursor.x + (half - p.x) * 2;
            rReplayFOFOCursor.x = curcorX;
            ReplayDrawCommands.setRCursorPos(curcorX, p.y);
        }

        public static function isLayer2SelectedReplayMode():Boolean
        {
            return rCanvasPanel.getChildIndex(rCanvasDrawLayer) < rCanvasPanel.getChildIndex(rCanvasLayer1Bitmap);
        }

        // drawdone에서 줌된 blur사이즈가 아니 1배율 블러를 적용해야 제대로 되기 때문에 이거해줌
        public static function blurReplayCanvasByDefaultValue():void
        {
            const blurSize:Number = CanvasController.getBlurSize(ReplayState.rAirBrushSize, 1.0);
            const blurf:BlurFilter = new BlurFilter(blurSize, blurSize, 3);
            rCanvasDrawShape.filters = [blurf];
        }

        public static function resetBlurReplayCanvas():void
        {
            ReplayState.rAirBrushSize = 0;
            rCanvasDrawShape.filters = [];
        }

        public static function blurReplayCanvasByValue(size:Number):void
        {
            const blurSize:Number = CanvasController.getBlurSize(size, ReplayState.rCanvasZoomMultiplier);
            const blurf:BlurFilter = new BlurFilter(blurSize, blurSize, 3);
            ReplayState.rAirBrushSize = size;
            rCanvasDrawShape.filters = [blurf];
        }

        public static function selectReplaySubLayer(flag:Boolean):void
        {
            ReplayState.rLastLayer2Selcted = flag;

            if (flag)
            {
                if (rCanvasPanel.getChildIndex(rCanvasDrawLayer) > rCanvasPanel.getChildIndex(rCanvasLayer1Bitmap))
                {
                    rCanvasPanel.setChildIndex(rCanvasDrawLayer, rCanvasPanel.getChildIndex(rCanvasLayer1Bitmap));
                }
            }
            else if (rCanvasPanel.getChildIndex(rCanvasDrawLayer) < rCanvasPanel.getChildIndex(rCanvasLayer1Bitmap))
            {
                rCanvasPanel.setChildIndex(rCanvasDrawLayer, rCanvasPanel.getChildIndex(rCanvasLayer1Bitmap));
            }
        }

        public static function moveImageReplayMode(x:Number, y:Number, layer1:Boolean, layer2:Boolean):void
        {
            var tmpbmpd:BitmapData = new BitmapData(rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height, true, 0);
            var movedMat:Matrix = new Matrix();

            if (!layer1 && !layer2)
            {
                layer1 = true;
                layer2 = true;
            }

            movedMat.translate(x, y);

            if (layer1)
            {
                tmpbmpd.draw(rCanvasLayer1BitmapData, movedMat);
                CanvasController.copyPixels(rCanvasLayer1BitmapData, tmpbmpd);
            }

            if (layer2)
            {
                tmpbmpd.fillRect(new Rectangle(0, 0, rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height), 0);
                tmpbmpd.draw(rCanvasLayer2BitmapData, movedMat);
                CanvasController.copyPixels(rCanvasLayer2BitmapData, tmpbmpd);
            }

            tmpbmpd.dispose();
            tmpbmpd = null;
        }

        public static function replayLineStyleReady(shape:Boolean, size:uint, color:uint, alpha:Number):void
        {
            rCanvasDrawLayer.alpha = alpha;

            if (shape)
            {
                rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.SQUARE, JointStyle.ROUND);
            }
            else
            {
                rCanvasDrawShape.graphics.lineStyle(size, color);
            }
        }

        public static function replayLineStyleReady2(shape:Boolean, size:uint, color:uint, alpha:Number):void
        {
            rCanvasDrawLayer.alpha = alpha;

            if (shape)
            {
                rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.SQUARE, JointStyle.BEVEL);
            }
            else
            {
                rCanvasDrawShape.graphics.lineStyle(size, color);
            }
        }

        public static function replayLineStyleReady3(shape:Boolean, size:uint, color:uint, alpha:Number):void
        {
            rCanvasDrawLayer.alpha = alpha;

            if (shape)
            {
                rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.BEVEL);
            }
            else
            {
                rCanvasDrawShape.graphics.lineStyle(size, color);
            }
        }

        public static function mirrorCanvasReplayMode():void
        {
            var tmpbmpd:BitmapData = new BitmapData(rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height, true, 0);
            var flipMat:Matrix = new Matrix(-1, 0, 0, 1, rCanvasLayer1BitmapData.width);
            const rect:Rectangle = new Rectangle(0, 0, rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height);
            tmpbmpd.draw(rCanvasLayer1BitmapData, flipMat);
            CanvasController.copyPixels(rCanvasLayer1BitmapData, tmpbmpd);
            tmpbmpd.fillRect(rect, 0);
            tmpbmpd.draw(rCanvasLayer2BitmapData, flipMat);
            CanvasController.copyPixels(rCanvasLayer2BitmapData, tmpbmpd);
            tmpbmpd.dispose();
            tmpbmpd = null;
            ReplayState.rMirrorON = !ReplayState.rMirrorON;

            if (ReplayState.isReplayCanvasFitToWindow)
            {
                ReplayController.fitReplayCanvasToViewport();
            }
        }

        public static function updateCanvasBGColorReplayMode(color:uint):void
        {
            ReplayState.RCANVAS_BG_COLOR = color;
            CanvasController.updateCanvasBGPanelReplayMode(color);
        }

        public static function updateCanvasSizeReplayMode(w:Number, h:Number, moveX:Number = 0, moveY:Number = 0, movedFlag:Boolean = false):void
        {
            if (w === ReplayState.RCANVAS_WIDTH && h === ReplayState.RCANVAS_HEIGHT)
            {
                return;
            }

            const bgColor:uint = ReplayState.RCANVAS_BG_COLOR;
            // 캔버스가 회전되어있으면 회전된 방향으로 움직여줘야함
            rCanvasPanel.graphics.clear();
            rCanvasPanel.graphics.beginFill(bgColor);
            rCanvasPanel.graphics.drawRect(0, 0, w, h);
            rCanvasPanel.graphics.endFill();
            rCanvasPanel.scrollRect = new Rectangle(0, 0, w, h); // 마스크 다시 씌워줌
            rCanvasLayer1BitmapData = new BitmapData(w, h, true, 0);
            rCanvasLayer2BitmapData = new BitmapData(w, h, true, 0);
            rCanvasDrawLayerBitmapData = new BitmapData(w, h, true, 0);
            ReplayState.RCANVAS_WIDTH = w;
            ReplayState.RCANVAS_HEIGHT = h;

            if (movedFlag)
            {
                // movex y는 캔버스 사이즈 조절에서 원점이 움직였을경우 그만큼 bitmapdata를 움직여줘야 원래 이미지대로 나옴
                var mat:Matrix = new Matrix();
                mat.translate(moveX, moveY);
                rCanvasLayer1BitmapData.draw(rCanvasLayer1Bitmap, mat);
                rCanvasLayer2BitmapData.draw(rCanvasLayer2Bitmap, mat);
            }
            else
            {
                rCanvasLayer1BitmapData.draw(rCanvasLayer1Bitmap);
                rCanvasLayer2BitmapData.draw(rCanvasLayer2Bitmap);
            }

            if (rCanvasLayer1Bitmap.bitmapData)
                rCanvasLayer1Bitmap.bitmapData.dispose();

            rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;

            if (rCanvasLayer2Bitmap.bitmapData)
                rCanvasLayer2Bitmap.bitmapData.dispose();

            rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
            ReplayController.rFollowMouse.updateBounds();
            CanvasController.keepCanvasPanelInStage(true);

            if (ReplayState.isReplayCanvasFitToWindow)
            {
                ReplayController.fitReplayCanvasToViewport();
            }
        }

        public static function clearCanvasReplayMode():void
        {
            const rect:Rectangle = new Rectangle(0, 0, ReplayState.RCANVAS_WIDTH, ReplayState.RCANVAS_HEIGHT);
            rCanvasDrawShape.graphics.clear();
            rCanvasLayer1BitmapData.fillRect(rect, 0);
            rCanvasLayer2BitmapData.fillRect(rect, 0);
            rCanvasDrawLayerBitmapData.fillRect(rect, 0);
        }

        public static function setReplayCanvasBmpdFromDrawMode():void
        {
            rCanvasDrawShape.graphics.clear();
            rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, CanvasController.canvasLayer1BitmapData, rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, CanvasController.canvasLayer2BitmapData, rCanvasLayer2Bitmap);
            updateCanvasSizeReplayMode(CanvasController.canvasLayer1Bitmap.width, CanvasController.canvasLayer1Bitmap.height);
            updateCanvasBGColorReplayMode(CanvasController.CANVAS_BG_COLOR);
        }

        public static function updateRCanvasDrawLayerCliprect2():void
        {
            rCanvasDrawLayerClipRect = rCanvasDrawLayerClipRect.union(rCanvasDrawShape.getBounds(rCanvasPanel));
        }

        public static function makeMemoryCacheImage(completedStepStartFrame:Number):void
        {
            ReplayFileCache.createRFrameTempCache(completedStepStartFrame, ReplayState.rFileCutBytePosition);
        }

        public static function readyToReadMemoryData(jumpFlag:int):void
        {
            ReplayState.rMemoryDataReadON = true;
            ReplayState.rMemoryDataIndex = ReplayState.rMemoryDataStartIndex;
            ReplayState.rMemoryDataStartIndex = 0;
            rMemoryDataLen = ReplayState.rMemoryData.length;

            if (jumpFlag === JUMP_FRAME_PLAY)
            {
                 ReplayDrawer.rFileStream.close();
            }

            if ( ReplayState.rMemoryData.length > 0)
            {
                ReplayState.rPrevFrame = ReplayState.rNowFrame;
                ReplayDrawCommands.setData(ReplayState.rMemoryData[ReplayState.rMemoryDataIndex]);
            }
            else
            {
                ReplayDrawCommands.clearData();
            }
        }

        public static function readNextFileData():Boolean
        {
            if (ReplayDrawer.rFileStream.bytesAvailable > 0)
            {
                const obj:Array = ReplayDrawer.rFileStream.readObject() as Array;

                if (!obj)
                    return true;
                ReplayDrawCommands.setData(obj);
                ReplayState.rFileCutBytePosition = ReplayState.rFileLastBytePosition;
                ReplayState.rFileLastBytePosition = ReplayDrawer.rFileStream.position;
                ReplayState.rPrevFrame = ReplayState.rNowFrame;
                return true;
            }

            return false;
        }

        public static function checkFinish(jumpFlag:int):Boolean
        {
            if (ReplayState.rMemoryDataIndex >= rMemoryDataLen || rMemoryDataLen === 0) // 자연적으로 끝났을때
            {
                ReplayDrawer.rReplayFOFOCursor.visible = false;
                ReplayState.isReplayFinished = true;

                if (jumpFlag === JUMP_FRAME_PLAY || ReplayState.isReplaySlideShowMode === true) // 1프레임 이상일때만 재시작 타이머 가동
                {
                    // reset replay time해주지 말고 그냥 end플래그만 올려줌
                    // 왜냐하면 리플레이 자연적으로 끝나고도 스킵프레임이나 oneframe jump을 해줄수가 있기 때문
                    ReplayController.stopReplay();
                    return true;
                }
            }

            return false;
        }

        public static function drawFromMemoryData(len:Number, jumpFlag:int):void
        {
            for (var i:Number = 0;i < len;i++)
            {
                if (ReplayDrawCommands.isReadFinished())
                {
                    ReplayState.rMemoryDataIndex++;

                    if (checkFinish(jumpFlag))
                    {
                        return;
                    }

                    ReplayState.rPrevFrame = ReplayState.rNowFrame;
                    ReplayDrawCommands.setData(ReplayState.rMemoryData[ReplayState.rMemoryDataIndex]);
                }

                ReplayDrawCommands.drawNext();
                ReplayState.rNowFrame++;
            }
        }

        public static function drawFromFileData(len:Number, jumpFlag:int):void
        {
            for (var i:Number = 0;i < len;i++)
            {
                if (ReplayDrawCommands.isReadFinished())
                {
                    const completedStepStartFrame:Number = ReplayState.rPrevFrame;
                    if (readNextFileData() === false)
                    {
                        // 더이상 읽을 데이터가 없을때 메모리읽기로 넘겨줌
                        readyToReadMemoryData(jumpFlag);
                        return;
                    }

                    if (ReplayState.isReplayStarted === false && (jumpFlag === JUMP_FRAME_MANUAL || jumpFlag === JUMP_FRAME_PREV))
                    {
                        if (ReplayState.rNowFrame > ReplayFileCache.getRFrameTempCacheLastFrame() + ReplayFileCache.REPLAY_MEMORY_CACHE_FRAME_INTERVAL)
                        {
                            makeMemoryCacheImage(completedStepStartFrame);
                        }
                    }
                }

                ReplayDrawCommands.drawNext();
                ReplayState.rNowFrame++;
                readCount--;
            }
        }

        public static function startDraw(commandCount:Number, jumpFlag:int):void
        {
            if (commandCount > 0)
            {
                readCount = commandCount;

                if (!ReplayState.rMemoryDataReadON)
                {
                    // readcount 감소
                    drawFromFileData(commandCount, jumpFlag);
                }

                if (readCount > 0)
                {
                    // readcount를 읽어줌
                    drawFromMemoryData(readCount, jumpFlag);
                }
            }
        }
    }
}
