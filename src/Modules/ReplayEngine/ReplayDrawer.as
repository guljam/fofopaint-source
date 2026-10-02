package Modules.ReplayEngine
{
    import Modules.DrawEngine.CanvasView;
    import Modules.DrawEngine.DrawCanvas;
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
    import Modules.FileManager;
    import flash.utils.getTimer;
    import Modules.UndoHistory;
    import Modules.UndoController;
    import Modules.Tools.PenTool;

    public class ReplayDrawer
    {
        // 리플레이
        public static var rFileStream:FileStream = new FileStream(); // 함수들을 왔다갔다 해야해서 전역으로 하나
        public static var rCanvasAnchorPoint:Sprite = new Sprite(); // 회전 스프라이트 부모
        public static var rCanvasPanel:Sprite = new Sprite();
        public static const viewport:ReplayViewport = new ReplayViewport(); // 리플레이 캔버스 화면 배치 (getter로 위 필드를 읽음)
        public static const cursorFollow:ReplayCursorFollow = new ReplayCursorFollow(); // 리플레이 커서 따라 캔버스 이동
        public static const fillAnim:ReplayFillAnim = new ReplayFillAnim(); // 채우기 펜 스캔라인 애니메이션
        public static var rCanvasDrawLayer:Sprite = new Sprite();
        public static var rCanvasDrawShape:Shape = new Shape();
        public static var rCanvasLayer1BitmapData:BitmapData = new BitmapData(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, true, 0);
        public static var rCanvasLayer2BitmapData:BitmapData = new BitmapData(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, true, 0);
        public static var rCanvasDrawLayerBitmapData:BitmapData = new BitmapData(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, true, 0);
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

        public static const REPLAY_CURSOR_SPIN_TURN_MS:Number = 900; // 실시간 재생에서 오래 쉬는 동안 리플레이 커서가 한바퀴 도는 시간 (시계 방향)
        public static const REPLAY_CURSOR_SPIN_RETURN_MS:Number = 200; // 쉬는 구간이 끝나고 원래 각도로 부드럽게 돌아가는 시간, 0이면 바로 돌아감
        private static const REPLAY_CURSOR_SPIN_TIMER:String = "replayCursorSpinTimer";
        private static var isReplayCursorSpinning:Boolean = false; // 쉬는 구간이라 커서가 도는 중인지 (되돌아가는 중은 false)
        private static var readCount:Number = 0;
        private static var rMemoryDataLen:uint;

        public static function resetRCanvasDrawLayerClipRect():void
        {
            rCanvasDrawLayerClipRect.setEmpty();
        }

        public static function extendRCanvasDrawLayerClipRect():void
        {
            const rairBrushOffset:Number = (ReplayState.rAirBrushSize2 > 0) ? PenTool.getClipRectOffsetAirBrush(ReplayState.rAirBrushSize2) : 1;
            rCanvasDrawLayerClipRect.x -= rairBrushOffset;
            rCanvasDrawLayerClipRect.y -= rairBrushOffset;
            rCanvasDrawLayerClipRect.width += (rairBrushOffset * 2);
            rCanvasDrawLayerClipRect.height += (rairBrushOffset * 2);
        }

        public static function updateRCanvasDrawLayerClipRect():void
        {
            rCanvasDrawLayerClipRect = rCanvasDrawLayerClipRect.union(rCanvasDrawShape.getBounds(rCanvasPanel));
        }

        public static function resetRCanvasDrawLayerClipRectLegacy():void
        {
            rCanvasDrawLayerClipRectLegacy.setEmpty();
        }

        public static function extendRCanvasDrawLayerClipRectLegacy():void
        {
            const rairBrushOffset:Number = (ReplayState.rAirBrushSize > 0) ? PenTool.getClipRectOffsetAirBrush(ReplayState.rAirBrushSize) : 1;
            rCanvasDrawLayerClipRectLegacy.x -= rairBrushOffset;
            rCanvasDrawLayerClipRectLegacy.y -= rairBrushOffset;
            rCanvasDrawLayerClipRectLegacy.width += (rairBrushOffset * 2);
            rCanvasDrawLayerClipRectLegacy.height += (rairBrushOffset * 2);
        }

        public static function updateRCanvasDrawLayerClipRectLegacy():void
        {
            rCanvasDrawLayerClipRectLegacy = rCanvasDrawLayerClipRectLegacy.union(rCanvasDrawShape.getBounds(rCanvasPanel));
        }

        // 데이터를 읽다 말았으면 끝까지 한세트 끝나게 프레임 이동시킴
        public static function finalizeRemainingReplayData():void
        {
            renderReplayFrame(ReplayState.rNowFrame + ReplayDrawCommands.getRemainingData(), ReplayDrawer.JUMP_FRAME_MANUAL);
        }

        public static function updateReplayCanvasFromUndoBaseInfo():void
        {
            const undoBaseImage:Array = UndoHistory.getUndoBaseImage();

            // 레이어를 먼저 교체하고 크기 정보를 맞춰줌
            rCanvasLayer1BitmapData = DrawCanvas.updateBitmapData(rCanvasLayer1BitmapData, undoBaseImage[0], rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = DrawCanvas.updateBitmapData(rCanvasLayer2BitmapData, undoBaseImage[1], rCanvasLayer2Bitmap);

            if (undoBaseImage[2] !== ReplayState.RCANVAS_WIDTH || undoBaseImage[3] !== ReplayState.RCANVAS_HEIGHT)
            {
                syncCanvasSizeReplayMode(undoBaseImage[2], undoBaseImage[3]);
            }

            if (undoBaseImage[4] !== ReplayState.RCANVAS_BG_COLOR)
            {
                updateCanvasBGColorReplayMode(undoBaseImage[4]);
            }

            ReplayState.rMirrorON = undoBaseImage[5];

            ReplayDrawCommands.setData(ReplayState.rMemoryData[0]);
            ReplayDrawCommands.drawAll();

            UndoHistory.updateUndoBaseImage(rCanvasLayer1BitmapData.clone(), rCanvasLayer2BitmapData.clone(), ReplayState.RCANVAS_WIDTH, ReplayState.RCANVAS_HEIGHT, ReplayState.RCANVAS_BG_COLOR, ReplayState.rMirrorON);

            ReplayDrawCommands.setFirstRCursorPosCurrent();
        }

        public static function updateReplayCanvasFromUndoRefData(undoRefData:Array, undoIndexSave:int):void
        {
            fillAnim.clear();
            ReplayState.rMemoryDataReadON = true;
            ReplayState.rMemoryDataIndex = undoIndexSave;
            ReplayState.rPrevFrame = ReplayState.rNowFrame;
            ReplayState.rNowFrame = ReplayState.getNowFrameUntilUndoIndex(undoIndexSave);

            ReplayState.rMirrorON = undoRefData[5];
            const rect:Rectangle = new Rectangle(0, 0, undoRefData[2], undoRefData[3]);

            // 레이어를 먼저 교체하고 크기 정보를 맞춰줌
            rCanvasLayer1BitmapData = DrawCanvas.updateBitmapData(rCanvasLayer1BitmapData, undoRefData[0], rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = DrawCanvas.updateBitmapData(rCanvasLayer2BitmapData, undoRefData[1], rCanvasLayer2Bitmap);

            if (undoRefData[2] !== ReplayState.RCANVAS_WIDTH || undoRefData[3] !== ReplayState.RCANVAS_HEIGHT)
            {
                syncCanvasSizeReplayMode(undoRefData[2], undoRefData[3]);
            }

            if (undoRefData[4] !== ReplayState.RCANVAS_BG_COLOR)
            {
                updateCanvasBGColorReplayMode(undoRefData[4]);
            }

            rCanvasDrawShape.graphics.clear();

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

            // 파일 캐시에서 새로 만든 bmpd라 clone 없이 그대로 넘겨줌
            rCanvasLayer1BitmapData = cacheImageData.bmpd1;
            rCanvasLayer2BitmapData = cacheImageData.bmpd2;
            rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
            rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;

            syncCanvasSizeReplayMode(rCanvasLayer1Bitmap.width, rCanvasLayer1Bitmap.height);
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

                if (loadCacheFlag === 2)
                {
                    // 메모리 캐시는 계속 보관해야 하므로 clone해서 씀
                    rCanvasLayer1BitmapData = DrawCanvas.updateBitmapData(rCanvasLayer1BitmapData, layer1bmpd, rCanvasLayer1Bitmap);
                    rCanvasLayer2BitmapData = DrawCanvas.updateBitmapData(rCanvasLayer2BitmapData, layer2bmpd, rCanvasLayer2Bitmap);
                }
                else
                {
                    // 파일 캐시에서 새로 만든 bmpd라 clone 없이 그대로 넘겨줌
                    rCanvasLayer1BitmapData = layer1bmpd;
                    rCanvasLayer2BitmapData = layer2bmpd;
                    rCanvasLayer1Bitmap.bitmapData = layer1bmpd;
                    rCanvasLayer2Bitmap.bitmapData = layer2bmpd;
                }

                layer1bmpd = null;
                layer2bmpd = null;
                syncCanvasSizeReplayMode(rCanvasLayer1Bitmap.width, rCanvasLayer1Bitmap.height);
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

        // 반환값: 리플레이를 정지해야 하면 true (슬라이드쇼 재생이 끝났을때)
        public static function renderReplayFrame(frame:Number, jumpflag:int):Boolean // jumpp
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
                    return false;
                }
            }

            ReplayController.invalidateRealtimeClock();
            stopReplayFOFOCursorSpin();
            fillAnim.clear();
            rFileStream.open(FileManager.replayDataFilePath, FileMode.READ);
            const remainingFrameCount:Number = drawCacheImageFirst(frame);
            const shouldStop:Boolean = ReplayDrawer.startDraw(remainingFrameCount, jumpflag);
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

            if (!ReplayState.isReplaySlideShowMode && !ReplayState.isReplayCanvasFitToWindow && !UndoController.isDeepUndoEnabled)
            {
                cursorFollow.check(true);
            }

            return shouldStop;
        }

        // 실시간 재생에서 오래 쉬는 구간에 들어갈때 커서를 그림 중심으로 제자리에서 돌림, 쉬는 구간마다 한번만 불림
        // 회전은 커서 안쪽 레이어에만 줘서 캔버스 회전 상쇄(setRcursorRotation)와 섞이지 않음
        public static function startReplayFOFOCursorSpin():void
        {
            if (isReplayCursorSpinning || !rReplayFOFOCursor.visible)
            {
                return;
            }

            isReplayCursorSpinning = true;
            // 되돌아가는 중에 다시 돌기 시작하면 지금 각도에서 이어서 돎
            const startAngle:Number = rReplayFOFOCursor.spinRotation;
            const startTime:int = getTimer();
            FOFOTimer.addByName(REPLAY_CURSOR_SPIN_TIMER, 0.0, true, function ():Boolean
                {
                    if (!rReplayFOFOCursor.visible)
                    {
                        isReplayCursorSpinning = false;
                        rReplayFOFOCursor.spinRotation = 0;
                        return false;
                    }

                    rReplayFOFOCursor.spinRotation = startAngle + (getTimer() - startTime) * 360 / REPLAY_CURSOR_SPIN_TURN_MS;
                    return true;
                });
        }

        // 쉬는 구간이 끝나서 다시 그릴때, 일시정지/탐색할때 원래 각도로 부드럽게 되돌림 (가까운 방향으로, 끝에서 느려지게)
        // 그리기 명령마다 불리지만 돌고 있지 않으면 플래그만 보고 끝남
        // 반환값: 돌던 중이었으면 true (부르는 쪽에서 그 프레임을 다 그린 뒤 커서 위치를 맞춰줌)
        public static function stopReplayFOFOCursorSpin():Boolean
        {
            if (!isReplayCursorSpinning)
            {
                return false;
            }

            isReplayCursorSpinning = false;
            // rotation은 -180~180으로 정리되어 있어서 그대로 0까지 줄이면 가까운 방향임
            const fromAngle:Number = rReplayFOFOCursor.spinRotation;

            if (REPLAY_CURSOR_SPIN_RETURN_MS <= 0 || fromAngle === 0 || !rReplayFOFOCursor.visible)
            {
                FOFOTimer.remove(REPLAY_CURSOR_SPIN_TIMER);
                rReplayFOFOCursor.spinRotation = 0;
                return true;
            }

            const startTime:int = getTimer();
            FOFOTimer.addByName(REPLAY_CURSOR_SPIN_TIMER, 0.0, true, function ():Boolean
                {
                    const t:Number = (getTimer() - startTime) / REPLAY_CURSOR_SPIN_RETURN_MS;

                    if (t >= 1 || !rReplayFOFOCursor.visible)
                    {
                        rReplayFOFOCursor.spinRotation = 0;
                        return false;
                    }

                    const ease:Number = 1 - (1 - t) * (1 - t); // ease-out
                    rReplayFOFOCursor.spinRotation = fromAngle * (1 - ease);
                    return true;
                });
            return true;
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
            const half:Number = DrawCanvas.CANVAS_WIDTH / 2;
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
            const blurSize:Number = PenTool.getBlurSize(ReplayState.rAirBrushSize, 1.0);
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
            const blurSize:Number = PenTool.getBlurSize(size, ReplayState.rCanvasZoomMultiplier);
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
                DrawCanvas.copyPixels(rCanvasLayer1BitmapData, tmpbmpd);
            }

            if (layer2)
            {
                tmpbmpd.fillRect(new Rectangle(0, 0, rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height), 0);
                tmpbmpd.draw(rCanvasLayer2BitmapData, movedMat);
                DrawCanvas.copyPixels(rCanvasLayer2BitmapData, tmpbmpd);
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
            DrawCanvas.copyPixels(rCanvasLayer1BitmapData, tmpbmpd);
            tmpbmpd.fillRect(rect, 0);
            tmpbmpd.draw(rCanvasLayer2BitmapData, flipMat);
            DrawCanvas.copyPixels(rCanvasLayer2BitmapData, tmpbmpd);
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
            rCanvasPanel.graphics.clear();
            rCanvasPanel.graphics.beginFill(color);
            rCanvasPanel.graphics.drawRect(0, 0, ReplayState.RCANVAS_WIDTH, ReplayState.RCANVAS_HEIGHT);
            rCanvasPanel.graphics.endFill();
        }

        public static function updateCanvasSizeReplayMode(w:Number, h:Number, moveX:Number = 0, moveY:Number = 0, movedFlag:Boolean = false):void
        {
            if (w === ReplayState.RCANVAS_WIDTH && h === ReplayState.RCANVAS_HEIGHT)
            {
                return;
            }

            rCanvasLayer1BitmapData = new BitmapData(w, h, true, 0);
            rCanvasLayer2BitmapData = new BitmapData(w, h, true, 0);

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
            syncCanvasSizeReplayMode(w, h);
        }

        // 레이어 픽셀은 건드리지 않고 패널, draw 버퍼, 크기 정보만 w h에 맞춰줌
        // 호출 전에 layer1 layer2가 이미 w h 크기의 이미지로 교체되어 있어야함
        // 기존 이미지를 새 크기로 옮겨야 하는 canvasSize 명령은 updateCanvasSizeReplayMode를 씀
        public static function syncCanvasSizeReplayMode(w:Number, h:Number):void
        {
            if (w === ReplayState.RCANVAS_WIDTH && h === ReplayState.RCANVAS_HEIGHT)
            {
                return;
            }

            if (rCanvasLayer1BitmapData.width !== w || rCanvasLayer1BitmapData.height !== h)
            {
                trace("[syncCanvasSizeReplayMode] layer size mismatch", rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height, w, h);
            }

            const bgColor:uint = ReplayState.RCANVAS_BG_COLOR;
            // 캔버스가 회전되어있으면 회전된 방향으로 움직여줘야함
            rCanvasPanel.graphics.clear();
            rCanvasPanel.graphics.beginFill(bgColor);
            rCanvasPanel.graphics.drawRect(0, 0, w, h);
            rCanvasPanel.graphics.endFill();
            rCanvasPanel.scrollRect = new Rectangle(0, 0, w, h); // 마스크 다시 씌워줌

            // draw 버퍼는 새 버퍼를 먼저 연결하고 이전 버퍼를 해제함
            const previousDrawLayerBitmapData:BitmapData = rCanvasDrawLayerBitmapData;
            rCanvasDrawLayerBitmapData = new BitmapData(w, h, true, 0);
            rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;

            if (previousDrawLayerBitmapData !== null)
                previousDrawLayerBitmapData.dispose();

            ReplayState.RCANVAS_WIDTH = w;
            ReplayState.RCANVAS_HEIGHT = h;
            cursorFollow.updateBounds();
            viewport.keepInStage();

            if (ReplayState.isReplayCanvasFitToWindow)
            {
                ReplayController.fitReplayCanvasToViewport();
            }
        }

        public static function clearCanvasReplayMode():void
        {
            const rect:Rectangle = new Rectangle(0, 0, ReplayState.RCANVAS_WIDTH, ReplayState.RCANVAS_HEIGHT);
            fillAnim.clear();
            rCanvasDrawShape.graphics.clear();
            rCanvasLayer1BitmapData.fillRect(rect, 0);
            rCanvasLayer2BitmapData.fillRect(rect, 0);
            rCanvasDrawLayerBitmapData.fillRect(rect, 0);
        }

        public static function setReplayCanvasBmpdFromDrawMode():void
        {
            rCanvasDrawShape.graphics.clear();
            rCanvasLayer1BitmapData = DrawCanvas.updateBitmapData(rCanvasLayer1BitmapData, DrawCanvas.canvasLayer1BitmapData, rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = DrawCanvas.updateBitmapData(rCanvasLayer2BitmapData, DrawCanvas.canvasLayer2BitmapData, rCanvasLayer2Bitmap);
            syncCanvasSizeReplayMode(DrawCanvas.canvasLayer1Bitmap.width, DrawCanvas.canvasLayer1Bitmap.height);
            updateCanvasBGColorReplayMode(DrawCanvas.CANVAS_BG_COLOR);
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

        // 리플레이 정지는 직접 하지 않고 정지가 필요한지만 반환함 (정지는 ReplayController가 처리)
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
                    return true;
                }
            }

            return false;
        }

        // 실시간 재생용: 지금 뭉치를 다 읽었으면 다음 뭉치를 그리지 않고 불러옴
        // 다음 명령이 wait인지 먼저 봐야 이번 프레임에 그릴지 정할수 있어서 필요함
        // 불러오는 순서와 상태 갱신은 drawFromFileData, drawFromMemoryData와 같음
        // 반환값: 더 읽을 데이터가 없으면 false (리플레이 끝)
        public static function prepareNextPlayData():Boolean
        {
            while (ReplayDrawCommands.isReadFinished())
            {
                if (!ReplayState.rMemoryDataReadON)
                {
                    if (readNextFileData() === false)
                    {
                        readyToReadMemoryData(JUMP_FRAME_PLAY);
                    }

                    continue;
                }

                ReplayState.rMemoryDataIndex++;

                if (checkFinish(JUMP_FRAME_PLAY))
                {
                    return false;
                }

                ReplayState.rPrevFrame = ReplayState.rNowFrame;
                ReplayDrawCommands.setData(ReplayState.rMemoryData[ReplayState.rMemoryDataIndex]);
            }

            return true;
        }

        // 반환값: 리플레이를 정지해야 하면 true
        public static function drawFromMemoryData(len:Number, jumpFlag:int):Boolean
        {
            for (var i:Number = 0;i < len;i++)
            {
                if (ReplayDrawCommands.isReadFinished())
                {
                    ReplayState.rMemoryDataIndex++;

                    if (checkFinish(jumpFlag))
                    {
                        return true;
                    }

                    ReplayState.rPrevFrame = ReplayState.rNowFrame;
                    ReplayDrawCommands.setData(ReplayState.rMemoryData[ReplayState.rMemoryDataIndex]);
                }

                ReplayDrawCommands.drawNext();
                ReplayState.rNowFrame++;
            }

            return false;
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
                        // 간격은 그리기 명령 수로 셈 (디스크 캐시 간격과 같은 기준이라 한 구간에 쌓이는 임시 캐시 수가 그대로임)
                        if (ReplayTimeline.getCommandCountAtFrame(ReplayState.rNowFrame) - ReplayTimeline.getCommandCountAtFrame(ReplayFileCache.getRFrameTempCacheLastFrame()) > ReplayFileCache.REPLAY_MEMORY_CACHE_FRAME_INTERVAL)
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

        // 반환값: 리플레이를 정지해야 하면 true
        public static function startDraw(commandCount:Number, jumpFlag:int):Boolean
        {
            var shouldStop:Boolean = false;

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
                    shouldStop = drawFromMemoryData(readCount, jumpFlag);
                }
            }

            return shouldStop;
        }
    }
}
