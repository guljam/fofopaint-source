package Modules.L2Engine.DrawEngine
{

    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import Modules.L4UI.DrawEngine.DrawViewport;
    import Modules.L1Data.Utils;
    import Modules.L1Data.FOFOTimer;

    // 드로우 모드 캔버스의 화면 배치: 앵커/패널 표시 트리, 이동, 줌, 회전/미러 화면 처리
    // 층: L2 엔진 - 드로우 모드 캔버스의 화면 배치 (이동, 줌, 회전·미러)
    public class CanvasView
    {
        // 캔버스 패널의 색이나 크기를 다시 그린 뒤 연동된 UI를 갱신하라는 보고
        public static var onCanvasPanelResizedFunc:Function;

        public static const canvasFlashEffect:Sprite = new Sprite();
        public static var canvasAnchorPoint:Sprite = new Sprite(); // 회전 스프라이트 부모
        public static var canvasPanel:Sprite = new Sprite(); // 회색 부분을 제외한 그리기 영역 추가
        public static var canvasZoomMultiplierList:Array = [0.125, 0.25, 0.5, 0.75, 1.0, 1.50, 2.0, 3.0, 4.0, 6.0, 8.0];
        public static var canvasZoomMultiplier:Number = 1.0;
        public static var canvasZoomIndex:int = 4;
        public static const viewport:DrawViewport = new DrawViewport();

        public static function applyCanvasFlashEffect(parent:DisplayObjectContainer, ox:Number, oy:Number, width:Number, height:Number, stopHandler:Function):void
        {
            if (!parent.getChildByName("canvasFlash"))
            {
                parent.addChild(canvasFlashEffect);
            }

            canvasFlashEffect.visible = true;
            canvasFlashEffect.graphics.beginFill(0xFFFFFF);
            canvasFlashEffect.graphics.drawRect(ox, oy, width, height);
            canvasFlashEffect.graphics.endFill();
            canvasFlashEffect.alpha = 1.0;
            const fadeStep:Number = Math.floor(0.05 * 256) / 256;
            FOFOTimer.addByName("flashingTimer", 0.0, true, function ():Boolean
                {
                    if (canvasFlashEffect.alpha < 0.1 || stopHandler())
                    {
                        canvasFlashEffect.alpha = 0.0;
                        canvasFlashEffect.visible = false;
                        canvasFlashEffect.graphics.clear();
                        if (parent.getChildByName("canvasFlash"))
                        {
                            parent.removeChild(canvasFlashEffect);
                        }
                        return false;
                    }
                    canvasFlashEffect.alpha -= fadeStep;
                    return true;
                });
        }

        public static function updateCanvasPanelMask(w:Number, h:Number):void
        {
            canvasPanel.scrollRect = new Rectangle(0, 0, w, h);
        }

        public static function getNearZoomIndex(nowZoom:Number):int
        {
            var index:int = Utils.binarySearchIndex(canvasZoomMultiplierList, nowZoom, function (item:*):Number
                {
                    return item;
                });
            if (index <= 0)
                return 0;
            else if (index >= canvasZoomMultiplierList.length - 1)
                return canvasZoomMultiplierList.length - 1;
            else if (canvasZoomMultiplierList[index + 1] - nowZoom < nowZoom - canvasZoomMultiplierList[index - 1])
            {
                return index + 1;
            }
            return index;
        }

        // 캔버스의 중심좌표를 구함 컨트롤 박스 옵션 박스 포함
        public static function getCanvasPanelMidPos():Point
        {
            const boundRect:Object = Utils.getBoundRect(DrawCanvas.canvasLayer1Bitmap);
            const left:Number = boundRect.left;
            const top:Number = boundRect.top;
            const right:Number = boundRect.right;
            const bottom:Number = boundRect.bottom;
            const visualWidth:Number = right - left; // 회전해있어도 상관없음
            const visualHeight:Number = bottom - top; // 양끝 모서리들의 직선거리를 구함
            const visualMidX:Number = Math.round((left + right) / 2); // 회전한 캔버스의 중심점을 구함
            const visualMidY:Number = Math.round((top + bottom) / 2); // floor안하면 1픽셀씩 내려감 0.5를 아래 setRegPoint 함수 에서 반올림 해줘서 그럼
            const p:Point = new Point(visualMidX, visualMidY);
            return p;
        }

        // 캔버스 패널의 배경색과 크기를 다시 그리고 연동된 UI 갱신을 알림
        public static function updateCanvasPanelColorAndSize():void
        {
            canvasPanel.graphics.clear();
            canvasPanel.graphics.beginFill(DrawCanvas.CANVAS_BG_COLOR);
            canvasPanel.graphics.drawRect(0, 0, DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT);
            canvasPanel.graphics.endFill();

            viewport.keepInStage();
            if (onCanvasPanelResizedFunc != null) onCanvasPanelResizedFunc();
        }
    }
}
