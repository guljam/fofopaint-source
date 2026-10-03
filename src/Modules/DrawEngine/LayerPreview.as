package Modules.DrawEngine
{
    import Modules.MouseState;
    import Modules.ReferenceLayerController;
    import Modules.SidebarController;
    import Modules.ReplayEngine.ReplayState;
    import Modules.UIEngine.UIController;
    import Modules.UIEngine.UITheme;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.LineScaleMode;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.getTimer;
    import Symbols.ToolOptionsSet;

    // 컨트롤 박스의 레이어 버튼에 hover 하면 캔버스를 비스듬히 눕혀 층(배경/참조/레이어2/레이어1)을 보여줌
    // 3D/GPU 없이 2D Matrix(세로 압축 + 층별 띄우기)만 사용. 레이어 BitmapData는 참조만 하므로 복사 없음
    // 실제 레이어 상태(visible, alpha)는 건드리지 않고 매 프레임 읽어서 보여주기만 함
    public class LayerPreview
    {
        private static const ROTATE_DEGREES:Number = 40.0; // 평면 회전각
        private static const ISO_SQUASH:Number = 0.5; // 회전 후 세로 압축 비율 (작을수록 납작)
        private static const FIT_MARGIN:Number = 0.88; // 뷰포트 대비 층 묶음이 차지하는 최대 비율
        private static const MAX_FIT_SCALE:Number = 1.5; // 작은 캔버스를 이 배율보다 크게 키우지는 않음
        private static const LAYER_GAP_RATIO:Number = 0.2; // 층 사이 화면상 간격 (캔버스 높이 대비)
        private static const HIDDEN_LAYER_ALPHA:Number = 0.12; // 꺼진 레이어도 위치를 알 수 있게 흐리게
        private static const CENTER_BAND_MIN:Number = 0.35; // 미리보기 중심의 세로 허용 범위 (뷰포트 높이 대비)
        private static const CENTER_BAND_MAX:Number = 0.65;
        private static const SIDEBAR_GAP:Number = 24.0; // 사이드바와 미리보기 사이 간격 (UI 배율 적용 전)
        private static const ORBIT_PERIOD_MS:int = 2000; // hover 한 층이 원을 한 바퀴 돌아 원점으로 돌아오는 시간
        private static const ORBIT_RADIUS_RATIO:Number = 0.01; // 원 반지름 (층 크기 대비)
        private static const EASE:Number = 0.4;
        private static const HIGHLIGHT_COLOR:uint = 0x2F8CFF;

        private static const DEPTH_BG:int = 0;
        private static const DEPTH_REF:int = 1;
        private static const DEPTH_LAYER2:int = 2;
        private static const DEPTH_LAYER1:int = 3;
        private static const DEPTH_COUNT:int = 4;

        private static const container:Sprite = new Sprite();
        private static const planes:Vector.<Sprite> = new Vector.<Sprite>(DEPTH_COUNT, true);
        private static const borders:Vector.<Shape> = new Vector.<Shape>(DEPTH_COUNT, true);
        private static const bgShape:Shape = new Shape();
        private static const layer1View:Bitmap = new Bitmap(null, "auto", true);
        private static const layer2View:Bitmap = new Bitmap(null, "auto", true);
        private static const refView:Bitmap = new Bitmap(null, "auto", true);
        private static const refHolder:Sprite = new Sprite();
        private static var isBuilt:Boolean = false;

        private static var isShown:Boolean = false;
        private static var isClosing:Boolean = false;
        private static var t:Number = 0.0; // 0: 평면, 1: 완전히 기울어진 상태
        private static var highlightDepth:int = -1;
        private static var orbitDepth:int = -1;
        private static var orbitStartTime:int = 0;
        private static var drawnWidth:int = 0;
        private static var drawnHeight:int = 0;
        private static var drawnHighlight:int = -2;
        private static var optionsBoxRef:ToolOptionsSet = null; // 컨트롤 박스(ToolOptionsSet): 켜고 끄는 영역이자 세로 위치 기준
        // 켤 때 한번 정하는 가로 배치: 사이드바가 뷰포트 중심의 어느 쪽인지로 결정
        private static var isPreviewOnRight:Boolean = true; // 사이드바의 오른쪽에 둘지
        private static var isCenteredInViewport:Boolean = false; // 고정 사이드바면 true: 뷰포트 중앙, 퀵 사이드바면 false: 사이드바 옆
        private static var areaLeft:Number = 0.0; // 미리보기가 들어갈 가로 범위 (stage 좌표)
        private static var areaRight:Number = 0.0;

        public static function init(optionsBox:ToolOptionsSet):void
        {
            optionsBoxRef = optionsBox;
            attach(optionsBox.layer1SelectButton, DEPTH_LAYER1);
            attach(optionsBox.layer1CheckedButton, DEPTH_LAYER1);
            attach(optionsBox.layer1UncheckedButton, DEPTH_LAYER1);
            attach(optionsBox.layer2SelectButton, DEPTH_LAYER2);
            attach(optionsBox.layer2CheckedButton, DEPTH_LAYER2);
            attach(optionsBox.layer2UncheckedButton, DEPTH_LAYER2);
            // ROLL_OVER/OUT은 버튼 사이 빈틈이나 자식 경계에서 켜졌다 꺼지기를 반복하므로 쓰지 않고,
            // 마우스가 컨트롤 박스의 경계 사각형 안에 있는지로 켜고 끔
            optionsBox.layerButtonWrapper.addEventListener(MouseEvent.MOUSE_OVER, onlayerButtonWrapperMouseOver);
            CanvasView.main.stage.addEventListener(MouseEvent.MOUSE_OUT, onlayerButtonWrapperMouseOut);
        }

        private static function onlayerButtonWrapperMouseOver(e:MouseEvent):void
        {
            show(); // 닫히는 중이면 닫힘을 취소함 (show가 isClosing을 풀어줌)
        }

        private static function onlayerButtonWrapperMouseOut(e:Event):void
        {
            if(!optionsBoxRef.layerButtonWrapper.hitTestPoint(CanvasView.main.stage.mouseX,CanvasView.main.stage.mouseY))
            {
                hide();
            }
        }

        private static function getLayerButtonWrapperBounds():Rectangle
        {
            const r:Rectangle = optionsBoxRef.layerButtonWrapper.getBounds(optionsBoxRef.stage);
            const view:Rectangle = UIController.getViewportRect(); // 스크롤로 상단바 뒤로 올라간 부분은 제외
            return r.intersection(new Rectangle(0, view.y, optionsBoxRef.layerButtonWrapper.stage.stageWidth, view.height));
        }


        // 사이드바 위치(x축으로만 움직임)를 확인해 미리보기의 가로 범위를 정함
        private static function layoutBesideSidebar():void
        {
            const stageW:Number = optionsBoxRef.stage.stageWidth;
            const sideBar:* = SidebarController.sideBar;
            const barW:Number = SidebarController.SCROLL_BAR_WIDTH;
            const leftEdge:Number = sideBar.x - (SidebarController.isRightSidebar ? barW : 0);
            const rightEdge:Number = sideBar.x + sideBar.getWidth() + (SidebarController.isRightSidebar ? 0 : barW);
            const gap:Number = SIDEBAR_GAP * UITheme.getUIScale();
            isCenteredInViewport = !SidebarController.isQuickSidebarActive;
            if (isCenteredInViewport)
            {
                // 고정 사이드바: 사이드바를 뺀 뷰포트 영역의 가로 중앙에 표시
                const view:Rectangle = UIController.getViewportRect();
                areaLeft = view.x + gap;
                areaRight = view.x + view.width - gap;
                return;
            }
            isPreviewOnRight =(leftEdge + rightEdge) / 2 < stageW / 2; // 사이드바가 중심의 왼쪽이면 그 오른쪽에 둠
            areaLeft = isPreviewOnRight ? rightEdge + gap : gap;
            areaRight = isPreviewOnRight ? stageW - gap : leftEdge - gap;
        }

        // 레이어 버튼 hover는 테두리만 바꿈. 미리보기 위치는 움직이지 않음
        private static function attach(button:DisplayObject, depth:int):void
        {
            button.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void
                {
                    highlightDepth = depth;
                });
            button.addEventListener(MouseEvent.MOUSE_OUT, onButtonOut);
        }

        private static function onButtonOut(e:MouseEvent):void
        {
            highlightDepth = -1;
        }

        public static function show():void
        {
            if (ReplayState.isReplayModeON || MouseState.isDragging)
            {
                return;
            }
            isClosing = false;
            if (isShown)
            {
                return;
            }
            layoutBesideSidebar();
            build();
            isShown = true;
            // 캔버스의 이동/줌/회전을 받지 않도록 anchor가 아닌 stage에 둠 (UI보다는 아래)
            const stage:DisplayObjectContainer = CanvasView.canvasAnchorPoint.parent;
            stage.addChildAt(container, stage.getChildIndex(CanvasView.canvasAnchorPoint) + 1);
            CanvasView.canvasPanel.visible = false;
            container.addEventListener(Event.ENTER_FRAME, onFrame);
            CanvasView.main.stage.addEventListener(Event.DEACTIVATE, onDeactivate);
            update();
        }

        public static function hide():void
        {
            if (isShown)
            {
                isClosing = true;
            }
        }

        private static function onDeactivate(e:Event):void
        {
            close();
        }

        private static function close():void
        {
            if (!isShown)
            {
                return;
            }
            isShown = false;
            isClosing = false;
            t = 0.0;
            highlightDepth = -1;
            container.removeEventListener(Event.ENTER_FRAME, onFrame);
            CanvasView.main.stage.removeEventListener(Event.DEACTIVATE, onDeactivate);
            if (container.parent)
            {
                container.parent.removeChild(container);
            }
            layer1View.bitmapData = null; // 참조 해제
            layer2View.bitmapData = null;
            refView.bitmapData = null;
            CanvasView.canvasPanel.visible = true;
        }

        private static function build():void
        {
            if (isBuilt)
            {
                return;
            }
            isBuilt = true;
            const bgPlane:Sprite = new Sprite();
            bgPlane.addChild(bgShape);
            const refPlane:Sprite = new Sprite();
            refHolder.addChild(refView);
            refPlane.addChild(refHolder);
            const l2Plane:Sprite = new Sprite();
            l2Plane.addChild(layer2View);
            const l1Plane:Sprite = new Sprite();
            l1Plane.addChild(layer1View);
            planes[DEPTH_BG] = bgPlane;
            planes[DEPTH_REF] = refPlane;
            planes[DEPTH_LAYER2] = l2Plane;
            planes[DEPTH_LAYER1] = l1Plane;
            for (var i:int = 0; i < DEPTH_COUNT; i++)
            {
                borders[i] = new Shape();
                planes[i].addChild(borders[i]);
                planes[i].mouseEnabled = false;
                planes[i].mouseChildren = false;
                container.addChild(planes[i]);
            }
            container.mouseEnabled = false;
            container.mouseChildren = false;
        }

        private static function onFrame(e:Event):void
        {
            if (MouseState.isDragging)
            {
                close();
                return;
            }
            // 닫히는 도중 마우스가 다시 들어왔는데 MOUSE_OVER를 놓친 경우를 대비해, 실제 위치로 닫힘을 취소함
            if (isClosing && optionsBoxRef.layerButtonWrapper.hitTestPoint(CanvasView.main.stage.mouseX, CanvasView.main.stage.mouseY))
            {
                isClosing = false;
            }
            const target:Number = isClosing ? 0.0 : 1.0;
            t += (target - t) * EASE;
            if (Math.abs(target - t) < 0.01)
            {
                t = target;
                if (isClosing)
                {
                    close();
                    return;
                }
            }
            update();
        }

        // 현재 레이어 상태를 읽어 각 층의 내용과 Matrix를 갱신
        private static function update():void
        {
            const bmp1:BitmapData = DrawCanvas.canvasLayer1Bitmap.bitmapData;
            const bmp2:BitmapData = DrawCanvas.canvasLayer2Bitmap.bitmapData;
            const w:int = bmp1.width;
            const h:int = bmp1.height;

            layer1View.bitmapData = bmp1;
            layer2View.bitmapData = bmp2;
            planes[DEPTH_LAYER1].alpha = DrawCanvas.canvasLayer1Bitmap.visible ? 1.0 : HIDDEN_LAYER_ALPHA;
            planes[DEPTH_LAYER2].alpha = DrawCanvas.canvasLayer2Bitmap.visible ? 1.0 : HIDDEN_LAYER_ALPHA;

            updateRefPlane(w, h);

            if (highlightDepth !== orbitDepth)
            {
                orbitDepth = highlightDepth;
                orbitStartTime = getTimer(); // 다른 층으로 옮기면 원점에서 다시 시작
            }
            if (w !== drawnWidth || h !== drawnHeight || highlightDepth !== drawnHighlight)
            {
                drawnWidth = w;
                drawnHeight = h;
                drawnHighlight = highlightDepth;
                redrawShapes(w, h);
            }

            // 아이소메트릭: 평면을 회전한 뒤 세로를 눌러서 마름모 모양으로 눕힘 (회전 -> 세로 압축 -> 층별 위로 띄움)
            // 캔버스의 현재 위치/줌/회전에서 시작해 사이드바 옆의 고정 모양으로 이어지게 보간 (t=0이 원래 화면)
            const area:Rectangle = getPreviewArea();
            const gapCanvas:Number = h * LAYER_GAP_RATIO;
            const boundSize:Number = (w + h) / Math.SQRT2; // 45도 회전한 평면의 가로/세로 폭
            const stackWidth:Number = boundSize;
            const stackHeight:Number = boundSize * ISO_SQUASH + gapCanvas * (DEPTH_COUNT - 1);
            const fit:Number = Math.min(MAX_FIT_SCALE, area.width * FIT_MARGIN / stackWidth, area.height * FIT_MARGIN / stackHeight);
            const startScale:Number = CanvasView.canvasAnchorPoint.scaleY;
            const startRotation:Number = CanvasView.canvasAnchorPoint.rotation;

            const startPos:Point = CanvasView.canvasPanel.localToGlobal(new Point(w / 2, h / 2));
            // 사이드바 쪽 가장자리에 붙임 (사이드바가 왼쪽이면 영역의 왼쪽 끝, 오른쪽이면 영역의 오른쪽 끝)
            const halfStackWidth:Number = stackWidth * fit / 2;
            const endX:Number = isCenteredInViewport ? area.x + area.width / 2
                : isPreviewOnRight ? area.x + halfStackWidth : area.x + area.width - halfStackWidth;
            container.x = startPos.x + (endX - startPos.x) * t;
            container.y = startPos.y + (area.y + area.height / 2 - startPos.y) * t;

            const rotation:Number = (startRotation + (ROTATE_DEGREES - startRotation) * t) * Math.PI / 180;
            const squash:Number = 1.0 - (1.0 - ISO_SQUASH) * t;
            const s:Number = startScale + (fit - startScale) * t;
            const gap:Number = gapCanvas * s * t;
            for (var d:int = 0; d < DEPTH_COUNT; d++)
            {
                const m:Matrix = new Matrix();
                m.translate(-w / 2, -h / 2);
                m.rotate(rotation);
                m.scale(s, s * squash);
                m.translate(0, ((DEPTH_COUNT - 1) / 2 - d) * gap); // 위층일수록 위로, 전체는 가운데 기준
                if (d === highlightDepth)
                {
                    // hover 한 층만 원을 그리며 움직이고 ORBIT_PERIOD_MS 마다 원점으로 돌아옴 (원점을 지나는 원)
                    const theta:Number = ((getTimer() - orbitStartTime) % ORBIT_PERIOD_MS) / ORBIT_PERIOD_MS * Math.PI * 2;
                    const radius:Number = boundSize * s * ORBIT_RADIUS_RATIO * t;
                    m.translate(radius * Math.sin(theta), radius * (Math.cos(theta) - 1));
                }
                planes[d].transform.matrix = m;
            }
        }

        // 미리보기가 들어갈 화면 영역
        // - 가로: 켤 때 정한 사이드바 옆 범위 (layoutBesideSidebar)
        // - 세로: 컨트롤 박스의 세로 중심을 따라가되 중앙 띠 안으로 제한, 위아래 중 좁은 쪽에 맞춰 높이를 정함
        private static function getPreviewArea():Rectangle
        {
            const view:Rectangle = UIController.getViewportRect();
            if (isCenteredInViewport)
            {
                // 고정 사이드바: 세로도 뷰포트 전체의 중앙 기준
                return new Rectangle(areaLeft, view.y, Math.max(1.0, areaRight - areaLeft), view.height);
            }
            const box:Rectangle = getLayerButtonWrapperBounds();
            const boxCenterY:Number = box.isEmpty() ? view.y + view.height / 2 : box.y + box.height / 2;
            const minY:Number = view.y + view.height * CENTER_BAND_MIN;
            const maxY:Number = view.y + view.height * CENTER_BAND_MAX;
            const centerY:Number = Math.max(minY, Math.min(maxY, boxCenterY));
            const halfHeight:Number = Math.min(centerY - view.y, view.y + view.height - centerY);
            return new Rectangle(areaLeft, centerY - halfHeight, Math.max(1.0, areaRight - areaLeft), halfHeight * 2);
        }

        private static function updateRefPlane(w:int, h:int):void
        {
            const refBmpd:BitmapData = ReferenceLayerController.canvasRefLayerBitmap.bitmapData;
            const hasRef:Boolean = refBmpd !== null && refBmpd.width > 1 && refBmpd.height > 1
                && ReferenceLayerController.canvasRefLayer.visible && !ReferenceLayerController.isRefLayerMemoryTrainingON;
            planes[DEPTH_REF].visible = hasRef;
            if (!hasRef)
            {
                return;
            }
            refView.bitmapData = refBmpd;
            refView.x = ReferenceLayerController.canvasRefLayerBitmap.x;
            refView.y = ReferenceLayerController.canvasRefLayerBitmap.y;
            refHolder.transform.matrix = ReferenceLayerController.canvasRefLayer.transform.matrix;
            planes[DEPTH_REF].alpha = ReferenceLayerController.canvasRefLayer.alpha;
            planes[DEPTH_REF].scrollRect = new Rectangle(0, 0, w, h); // 캔버스 밖으로 나간 참조 이미지는 잘라냄
        }

        private static function redrawShapes(w:int, h:int):void
        {
            bgShape.graphics.clear();
            bgShape.graphics.beginFill(DrawCanvas.CANVAS_BG_COLOR);
            bgShape.graphics.drawRect(0, 0, w, h);
            bgShape.graphics.endFill();
            for (var i:int = 0; i < DEPTH_COUNT; i++)
            {
                const isHighlight:Boolean = (i === highlightDepth);
                const g:* = borders[i].graphics;
                g.clear();
                g.lineStyle(isHighlight ? 3 : 1, isHighlight ? HIGHLIGHT_COLOR : 0x000000, isHighlight ? 1.0 : 0.25, false, LineScaleMode.NONE);
                g.drawRect(0, 0, w, h);
            }
        }
    }
}
