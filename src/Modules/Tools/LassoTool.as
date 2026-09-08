package Modules.Tools
{
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import Symbols.LassoMenuSet;
    import flash.geom.Point;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import flash.filters.ConvolutionFilter;
    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.geom.Matrix;
    import Modules.ReferenceLayerController;
    import Modules.MainUIController;
    import Modules.SidebarController;
    import Modules.MainUI;
    import Modules.DragInteraction;
    import Modules.Utils;
    import Modules.ColorPickerController;
    import Modules.ImageViewWindow;

    public class LassoTool
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static const LASSO_SHARP_DATA:Array = [[[
                        0, -1, 0,
                        -1, 12, -1
                        , 0, -1, 0
                    ], 8],
                [[
                        0, -1, 0,
                        -1, 10, -1
                        , 0, -1, 0
                    ], 6],
                [[
                        0, -1, 0,
                        -1, 7, -1
                        , 0, -1, 0
                    ], 3]];

        public static const LASSO_1PX_MOVE_UP:int = (1 << 0);
        public static const LASSO_1PX_MOVE_DOWN:int = (1 << 1);
        public static const LASSO_1PX_MOVE_LEFT:int = (1 << 2);
        public static const LASSO_1PX_MOVE_RIGHT:int = (1 << 3);

        public static var lassoMenuBox:LassoMenuSet = new LassoMenuSet(); // 라소툴 버튼
        public static var lassoDraw:Shape = new Shape(); // 라소 영역 선 그려주는 쉐이프
        public static var lassoLayer1:Sprite = new Sprite(); // 선택한 이미지를 그려주고 확대/축소 등 조작
        public static var lassoLayer1Bitmap:Bitmap = new Bitmap();

        public static var lassoLayer2:Sprite = new Sprite(); // lassoLayer2 레이어
        public static var lassoLayer2Bitmap:Bitmap = new Bitmap(); // lassoLayer2의 비트맵

        public static var isLassoToolStarted:Boolean = false; // 라소툴로 영역 선택하면 올려줌
        public static var lassoFirstData:Array = []; // 이 값과 비교해서 달라진 게 있으면 OK할 때 적용
        public static var isLassoMirrorON:Boolean = false; // 라소 mirror 클릭할 때마다 반전
        public static var isLassoMenuHiddenTemp:Boolean = false; // 툴 고정 상태에서 줌툴 클릭 시 메뉴를 잠시 숨기는 플래그

        public static var lassoTransformData:Array = []; // 라소 변형 데이터
        public static var isLassoImageCopied:Boolean = false; // lasso 복사 누르면 올려줌

        public static var lassoLayer1LastBitmapdata:BitmapData; // copy나 취소했을 때 원래대로 돌려주는 이미지
        public static var lassoLayer2LastBitmapdata:BitmapData; // copy나 취소했을 때 원래대로 돌려주는 이미지
        public static var lassoLayerCommandData:Array = null; // 스왑/머지 순서 저장

        public static var isLassoLayerSwapButtonClicked:Boolean; // 스왑 버튼 클릭할 때마다 true/false 변경

        public static var lassoToolFunction:Object = cLassoTool();
        public static var lassoAndRefLayerBoxLastPos:Array = [0, 0, 0, 0, 0, 0, 0, 0]; // 사이즈바 켜줄때 임시로 사이드바 안쪽으로 밀려나게 하고 위치가 변경되지 않았으면 원래대로 복귀해줌

        public static function hideLassoMenuBoxTemp():void
        {
            lassoMenuBox.visible = true;
            isLassoMenuHiddenTemp = false;
            main.resetLastKey();
        }

        public static function mergeLassoImageToRefLayer():void
        {
            if (isLassoImageCopied)
            {
                applyLassoBoxImageToCanvas(true);
                disposeLassoBoxBitmapData();
                resetLassoBox();
            }
            else
            {
                if (main.isDeepUndoEnabled)
                {
                    main.applyDeepUndo();
                }
                const lassoInfo:Array = applyLassoBoxImageToCanvas(true);
                const point1:Vector.<Number> = lassoTransformData[0].concat();
                const point2:Array = lassoTransformData[1].concat();
                var l1:Boolean = true;
                var l2:Boolean = true;
                if (main.checkedLayer === 1 || (main.canvasLayer1Bitmap.visible && !main.canvasLayer2Bitmap.visible))
                {
                    l1 = true;
                    l2 = false;
                }
                else if (main.checkedLayer === 2 || (!main.canvasLayer1Bitmap.visible && main.canvasLayer2Bitmap.visible))
                {
                    l1 = false;
                    l2 = true;
                }
                main.rDataBuffer.push(["lassodel2", point1, point2, lassoInfo, isLassoImageCopied, l1, l2]);
                main.undoManager.addNew();
                disposeLassoBoxBitmapData();
                resetLassoBox();
            }
            if (ReferenceLayerController.canvasRefLayer.visible === false || ReferenceLayerController.refLayerLastAlpha === 0.0)
            {
                ReferenceLayerController.updateRefLayerOpacityCursorPosByValue(0.5);
                ReferenceLayerController.refLayerLastAlpha = 0.5;
                ReferenceLayerController.canvasRefLayer.visible = true;
                ReferenceLayerController.canvasRefLayer.alpha = 0.5;
            }
            ReferenceLayerController.canvasRefLayerBitmap.smoothing = true;
        }

        public static function removeInputEventsLassoTool():void
        {
            main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpLassoTool);
            main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownLassoTool);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLassoTool);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpLassoTool);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownLassoTool);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpLassoTool);
            main.addInputEventsDrawMode();
        }

        public static function addInputEventsLassoTool():void
        {
            main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpLassoTool);
            main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownLassoTool);
            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLassoTool);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpLassoTool, false, -1);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownLassoTool);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpLassoTool);
            main.stage.addEventListener(MouseEvent.MOUSE_OVER, lassoMenuHintONEvent);
            main.removeInputEventsDrawMode();
        }

        // 1초정도 켜지지 않게함
        public static function restoreLassoAndRefLayerBoxLastPos():void
        {
            const arr:Array = lassoAndRefLayerBoxLastPos;
            if ((arr[0] !== arr[2] || arr[1] !== arr[3])
                    && lassoMenuBox.x === arr[2] && lassoMenuBox.y === arr[3])
            {
                lassoMenuBox.x = arr[0];
                lassoMenuBox.y = arr[1];
            }
            if ((arr[4] !== arr[6] || arr[5] !== arr[7])
                    && ReferenceLayerController.refLayerMenuBox.x === arr[6] && ReferenceLayerController.refLayerMenuBox.y === arr[7])
            {
                ReferenceLayerController.refLayerMenuBox.x = arr[4];
                ReferenceLayerController.refLayerMenuBox.y = arr[5];
            }
        }

        public static function recordLassoAndRefLayerBoxLastPos():void
        {
            const arr:Array = lassoAndRefLayerBoxLastPos;
            if (isLassoToolStarted)
            {
                arr[0] = lassoMenuBox.x;
                arr[1] = lassoMenuBox.y;
                MainUIController.keepBoxInsideViewPort(lassoMenuBox);
                arr[2] = lassoMenuBox.x;
                arr[3] = lassoMenuBox.y;
            }
            if (ReferenceLayerController.isRefLayerMenuON)
            {
                arr[4] = ReferenceLayerController.refLayerMenuBox.x;
                arr[5] = ReferenceLayerController.refLayerMenuBox.y;
                MainUIController.keepBoxInsideViewPort(ReferenceLayerController.refLayerMenuBox);
                arr[6] = ReferenceLayerController.refLayerMenuBox.x;
                arr[7] = ReferenceLayerController.refLayerMenuBox.y;
            }
        }

        public static function onKeyUpLassoTool(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;
            if (isLassoMenuHiddenTemp && !main.isMouseClicked)
            {
                isLassoMenuHiddenTemp = false;
            }
            main.checkGeneralKeyUp(keyCode);
        }

        public static function onKeyDownLassoTool(e:KeyboardEvent):void
        {
            if (main.isMouseClicked || main.isRightMouseClicked || main.isMouseDragging)
            {
                return;
            }

            const keyCode:uint = main.getFirstPressedKey();

            if (keyCode === main.KEY.space)
            {
                if (main.checkSubKey(2, true, function (input:int):void
                        {
                            switch (input)
                                {
                                    case main.KEY.w:
                                    case main.KEY.i:
                                    move1PxLassoTool(LASSO_1PX_MOVE_UP);
                            break;

                        case main.KEY.a:
                            case main.KEY.j:
                            move1PxLassoTool(LASSO_1PX_MOVE_LEFT);
                        break;

                        case main.KEY.s:
                            case main.KEY.k:
                            move1PxLassoTool(LASSO_1PX_MOVE_DOWN);
                        break;

                        case main.KEY.d:
                            case main.KEY.l:
                            move1PxLassoTool(LASSO_1PX_MOVE_RIGHT);
                        break;
                    }
                }))
            {
                return;
            }

            if (main.isLastKey(keyCode))
            {
                return;
            }

            main.updateLastKey(keyCode);
            isLassoMenuHiddenTemp = true;
            main.setSelectedTool(main.TOOL_HAND);
            main.showNowToolIconToCursorTemp(main.TOOL_HAND);
        }
        else if (main.isPressingShift())
        {
            if (main.checkSubKey(2, true, function (input:int):void
                    {
                        switch (input)
                            {
                                case main.KEY.s:
                                case main.KEY.k:
                                if (main.canvasAnchorPoint.rotation !== 0.0)
                                    {
                                        main.resetRotationDrawMode();
                            }
                            return;

                    case main.KEY.w:
                    case main.KEY.i:
                    if (main.canvasZoomMultipler !== 1.0)
                        {
                            main.resetZoomDrawMode();
                }
                return;
    }
}))
{
    return;
}
}

if (main.isLastKey(keyCode))
{
    return;
}

main.updateLastKey(keyCode);

switch (keyCode)
{
    case main.KEY.tab:
    case main.KEY.backslash:
        if (SidebarController.isSidebarVisible)
        {
            SidebarController.hideSidebarPermanent();
        }
        else
        {
            SidebarController.showSidebarPermanent();
        }
        break;

    case main.KEY.w:
    case main.KEY.i:
        isLassoMenuHiddenTemp = true;
        main.updateLastKey(keyCode);
        main.setSelectedTool(main.TOOL_ZOOM);
        main.showNowToolIconToCursorTemp(main.TOOL_ZOOM);
        break;

    case main.KEY.s:
    case main.KEY.k:
        isLassoMenuHiddenTemp = true;
        main.updateLastKey(keyCode);
        main.setSelectedTool(main.TOOL_ROTATE);
        main.showNowToolIconToCursorTemp(main.TOOL_ROTATE);
        break;

    case main.KEY.enter:
        applyLassoImageToCanvas();
        break;

    case main.KEY.esc:
    case main.KEY.backspace:
        cancelLassoTool();
        break;
}
}

public static function mergeLassoImageIntoToRefLayer():void
{
    ReferenceLayerController.handleOneMoreClickMergeIntoRefLayer(
            lassoMenuBox,
            lassoMenuBox.lassoRefLayer,
            HintStrings.STRING_MERGE_INTO_REFLAYER,
            function ():void
            {
                mergeLassoImageToRefLayer();
                ReferenceLayerController.openRefLayerMenu();
            });
}

public static function lassoMenuHintONEvent(e:MouseEvent):void
{
    if (!isLassoToolStarted)
    {
        main.stage.removeEventListener(MouseEvent.MOUSE_OVER, lassoMenuHintONEvent);
        return;
    }
    if (lassoMenuBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
    {
        if (lassoMenuBox.getHintStr() !== "Lasso tool")
        {
            lassoMenuBox.hint("Lasso tool");
        }
        return;
    }
    if (main.isMouseDragging === true)
    {
        return;
    }
    lassoMenuBox.hint(HintStrings.getHintFromTargetNameLassoTool(e.target.name));
}

public static function addLassoLayerMergeCommand(command:int):void
{
    if (lassoLayerCommandData === null)
    {
        lassoLayerCommandData = [];
    }
    // 0번 스왑명령, 1번 머지 명령
    if (command === 0)
    {
        if (lassoLayerCommandData.length > 0 && lassoLayerCommandData[lassoLayerCommandData.length - 1] === 0)
        {
            lassoLayerCommandData.pop();
        }
        else
        {
            lassoLayerCommandData.push(0);
        }
    }
    else if (lassoLayerCommandData[lassoLayerCommandData.length - 1] !== command)
    {
        lassoLayerCommandData.push(command);
    }
}

public static function swapLassoImage():void
{
    var tmpbmpd:BitmapData = lassoLayer1Bitmap.bitmapData;
    lassoLayer1Bitmap.bitmapData = lassoLayer2Bitmap.bitmapData;
    lassoLayer2Bitmap.bitmapData = tmpbmpd;
    tmpbmpd = null;
}

public static function mergeLassoImage():void
{
    var rect:Rectangle = new Rectangle(0, 0, lassoLayer1Bitmap.bitmapData.width, lassoLayer1Bitmap.bitmapData.height);
    lassoLayer2Bitmap.bitmapData.draw(lassoLayer1Bitmap);
    lassoLayer1Bitmap.bitmapData.fillRect(rect, 0);
    rect = null;
}

public static function mergeLayerByLassoTool():void
{
    lassoMenuBox.lassoLayerMerge.alpha = Global.OFFALPHA;
    mergeLassoImage();
    addLassoLayerMergeCommand(1);
}
public static function swapLayerByLassoTool():void
{
    if (lassoMenuBox.lassoLayerSwap.alpha < 1.0)
    {
        return;
    }
    isLassoLayerSwapButtonClicked = !isLassoLayerSwapButtonClicked;
    swapLassoImage();
    addLassoLayerMergeCommand(0);
    lassoMenuBox.hint(HintStrings.getLassoMenuHintSwapLayer());
    main.playLayerSwapEffect(lassoMenuBox.lassoLayerSwap);
}

public static function copyCanvasImageToLassoTool():void
{
    if (isLassoImageCopied)
    {
        return;
    }
    isLassoImageCopied = true;
    lassoMenuBox.lassoCopy.alpha = Global.OFFALPHA;
    lassoCancelBmpd();
}

public static function startLassoImageRotation():void
{
    var getAngle:Function = MainUI.showCanvasRotateCursorMouseDrag(lassoLayer1);
    function onMouseUp():void
    {
        getAngle = null;
        MainUI.hideCanvasRotateCursor();
        lassoLayer1Bitmap.smoothing = true;
        lassoLayer2Bitmap.smoothing = true;
        lassoMenuBox.visible = true;
    }
    function onDragStart():void
    {
        lassoMenuBox.visible = false;
        lassoLayer1Bitmap.smoothing = false;
        lassoLayer2Bitmap.smoothing = false;
    }
    function onMouseMove():void
    {
        const angle:Number = getAngle(false);
        lassoLayer1.rotation = angle;
        lassoLayer2.rotation = angle;
    }
    DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
}

public static function startLassoImageResize():void
{
    const mirrorScale:Number = (lassoLayer1.scaleX < 0) ? -1.0 : 1.0;
    var getScale:Function = Utils.updateImageScaleMouseDrag(lassoLayer1.scaleX);
    function onDragStart():void
    {
        lassoMenuBox.visible = false;
        lassoLayer1Bitmap.smoothing = false;
        lassoLayer2Bitmap.smoothing = false;
        MainUI.showMouseHint(MainUI.getImageScaleHint(lassoLayer1.width, lassoLayer1.height, Math.abs(lassoLayer1.scaleX), false));
    }
    function onMouseUp():void
    {
        getScale = null;
        MainUIController.keepBoxInsideViewPort(lassoMenuBox);
        MainUI.hideMouseHint();
        lassoLayer1Bitmap.smoothing = true;
        lassoLayer2Bitmap.smoothing = true;
        lassoMenuBox.visible = true;
    }
    function onMouseMove():void
    {
        const scale:Number = getScale(main.stage.mouseX, main.stage.mouseY);
        lassoLayer1.scaleX = scale * mirrorScale;
        lassoLayer1.scaleY = scale;
        lassoLayer2.scaleX = lassoLayer1.scaleX;
        lassoLayer2.scaleY = lassoLayer1.scaleY;
        MainUI.showMouseHint(MainUI.getImageScaleHint(lassoLayer1.width, lassoLayer1.height, Math.abs(lassoLayer1.scaleX), false));
    }
    DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
}

public static function hasLassoImageChanges():Boolean
{
    if (isLassoImageCopied
            || lassoFirstData[0] !== lassoLayer1.x
            || lassoFirstData[1] !== lassoLayer1.y
            || lassoFirstData[2] !== lassoLayer1.scaleX
            || lassoFirstData[3] !== lassoLayer1.scaleY
            || lassoFirstData[4] !== lassoLayer1.rotation
            || (lassoLayerCommandData && lassoLayerCommandData.length > 0))
    {
        return true;
    }
    return false;
}

public static function startLassoImageMove():void
{
    var getMovedPos:Function = Utils.updateImagePosMouseDrag(lassoLayer1, main.canvasAnchorPoint.rotation);
    function onMouseUp():void
    {
        getMovedPos = null;
        MainUIController.keepBoxInsideViewPort(lassoMenuBox);
        lassoLayer1Bitmap.smoothing = true;
        lassoLayer2Bitmap.smoothing = true;
        lassoMenuBox.visible = true;
    }
    function onMouseMove():void
    {
        const pos:Point = getMovedPos();
        lassoLayer1.x = Math.round(pos.x);
        lassoLayer1.y = Math.round(pos.y);
        lassoLayer2.x = lassoLayer1.x;
        lassoLayer2.y = lassoLayer1.y;
    }
    function onDragStart():void
    {
        lassoMenuBox.visible = false;
        lassoLayer1Bitmap.smoothing = false;
        lassoLayer2Bitmap.smoothing = false;
    }
    DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
}

public static function applyLassoShapen(scale:Number):void
{
    if (scale === 0.0)
        return;
    var index:uint = Math.abs(Math.floor(scale - 1.0));
    if (index > 2)
        index = 2;
    var sharpen:ConvolutionFilter = new ConvolutionFilter(3, 3, LASSO_SHARP_DATA[index][0], LASSO_SHARP_DATA[index][1]);
    lassoLayer1Bitmap.filters = [sharpen];
    lassoLayer2Bitmap.filters = [sharpen];
}

public static function isHintAvailableWithLassoToolStarted(target:DisplayObject):Boolean
{
    if (target === main.toolBox.toolZoomIn
            || target === main.toolBox.toolZoomOut
            || target === main.toolBox.toolRotate
            || target === SidebarController.sideBarScrollBar)
    {
        return true;
    }
    return false;
}

public static function moveSelectedAreaToLassoBox(replayMode:Boolean, rectArr:Vector.<Number>, points:Array, copyFlag:Boolean, layer1:Boolean, layer2:Boolean):Boolean
{
    // 라소 경계 사각형 좌표와 크기
    const rectLeft:Number = rectArr[0];
    const rectTop:Number = rectArr[1];
    const rectWidth:Number = rectArr[2] - rectLeft;
    const rectHeight:Number = rectArr[3] - rectTop;
    const lassoPointsLen:uint = points.length;
    // 가로세로 길이가 0 이하이면 실행하지 않음
    if (Math.floor(rectWidth) <= 0 || Math.floor(rectHeight) <= 0)
        return false;
    var xCanvasDrawLayer:Shape;
    var canvasBitmapData:BitmapData;
    var canvasBitmapDataSub:BitmapData;
    var canvasBitmap:Bitmap;
    var canvasBitmapSub:Bitmap;
    var canvasDrawLayerFilterBackUp:Array = null;
    // 에어브러시 켜줄때 필터 백업함
    if (replayMode)
    {
        canvasDrawLayerFilterBackUp = main.rCanvasDrawShape.filters.concat();
        main.rCanvasDrawShape.filters = [];
        xCanvasDrawLayer = main.rCanvasDrawShape;
        if (layer1)
        {
            canvasBitmapData = main.rCanvasLayer1BitmapData;
            canvasBitmap = main.rCanvasLayer1Bitmap;
        }
        if (layer2)
        {
            canvasBitmapDataSub = main.rCanvasLayer2BitmapData;
            canvasBitmapSub = main.rCanvasLayer2Bitmap;
        }
    }
    else
    {
        canvasDrawLayerFilterBackUp = main.canvasDrawLayerChild.filters.concat();
        main.canvasDrawLayerChild.filters = [];
        xCanvasDrawLayer = main.canvasDrawLayerChild;
        if (layer1)
        {
            canvasBitmapData = main.canvasLayer1BitmapData;
            canvasBitmap = main.canvasLayer1Bitmap;
        }
        if (layer2)
        {
            canvasBitmapDataSub = main.canvasLayer2BitmapData;
            canvasBitmapSub = main.canvasLayer2Bitmap;
        }
    }
    const newRectangle:Rectangle = new Rectangle(rectLeft, rectTop, rectWidth, rectHeight);
    var lassoBMPD:BitmapData = new BitmapData(rectWidth, rectHeight, true, 0);
    var lassoBMPDsub:BitmapData = new BitmapData(rectWidth, rectHeight, true, 0);
    var i:uint;
    // 지우기 전에 사각형 모양으로 그려준 부분을 copypixel 함.
    if (layer1)
        lassoBMPD.copyPixels(canvasBitmapData, newRectangle, new Point(0, 0), null, null, true);
    if (layer2)
        lassoBMPDsub.copyPixels(canvasBitmapDataSub, newRectangle, new Point(0, 0), null, null, true);
    lassoLayer1Bitmap.smoothing = true;
    lassoLayer2Bitmap.smoothing = true;
    // bitmap1canvas에서 그려준 영역을 지워줌
    if (!copyFlag)
    {
        xCanvasDrawLayer.graphics.clear();
        xCanvasDrawLayer.graphics.beginFill(main.CANVAS_BG_COLOR);
        xCanvasDrawLayer.graphics.moveTo(points[0][0], points[0][1]);
        // rectLeft를 빼줘서 canvasdraw2의 0,0영역에 그려줌
        for (i = 1;i < lassoPointsLen;i++)
        {
            xCanvasDrawLayer.graphics.lineTo(points[i][0], points[i][1]);
        }
        xCanvasDrawLayer.graphics.endFill();
        if (layer1)
        {
            canvasBitmapData.draw(xCanvasDrawLayer, null, null, "erase");
            canvasBitmap.bitmapData = canvasBitmapData;
        }
        if (layer2)
        {
            canvasBitmapDataSub.draw(xCanvasDrawLayer, null, null, "erase");
            canvasBitmapSub.bitmapData = canvasBitmapDataSub;
        }
    }
    // -------------------------
    // clip하기 위해서 그려운 영역의 반전 부분을 0,0영역을 기준으로 그려줌
    // 2번 반복하는게 좀 그런데 다른 방법 모르겠음
    // 가로세로 절반 크기만큼 더해줘서 bmp의 중점으로 이동해주기 때문에 또 그만큼 빼줌
    xCanvasDrawLayer.graphics.clear();
    xCanvasDrawLayer.graphics.beginFill(0x00FF00);
    xCanvasDrawLayer.graphics.drawRect(0, 0, rectWidth, rectHeight);
    xCanvasDrawLayer.graphics.moveTo(points[0][0] - rectLeft, points[0][1] - rectTop);
    // rectLeft를 빼줘서 canvasdraw2의 0,0영역에 그려줌
    for (i = 1;i < lassoPointsLen;i++)
    {
        xCanvasDrawLayer.graphics.lineTo(points[i][0] - rectLeft, points[i][1] - rectTop);
    }
    // 마지막으로 시작점을 이어줌
    xCanvasDrawLayer.graphics.endFill();
    if (layer1)
    {
        lassoLayer1Bitmap.bitmapData = lassoBMPD;
        lassoLayer1Bitmap.bitmapData.draw(xCanvasDrawLayer, null, null, "erase");
    }
    if (layer2)
    {
        lassoLayer2Bitmap.bitmapData = lassoBMPDsub;
        lassoLayer2Bitmap.bitmapData.draw(xCanvasDrawLayer, null, null, "erase");
    }
    xCanvasDrawLayer.graphics.clear(); // 꼭 해줘야함
    // 회전 확대를 bmp사각형의 중심으로 맞추어줌
    if (layer1)
    {
        lassoLayer1Bitmap.x = -rectWidth / 2;
        lassoLayer1Bitmap.y = -rectHeight / 2;
    }
    if (layer2)
    {
        lassoLayer2Bitmap.x = -rectWidth / 2;
        lassoLayer2Bitmap.y = -rectHeight / 2;
    }
    lassoLayer1.x = rectLeft + rectWidth / 2;
    lassoLayer1.y = rectTop + rectHeight / 2;
    lassoLayer2.x = lassoLayer1.x;
    lassoLayer2.y = lassoLayer1.y;
    lassoDraw.x = -lassoLayer1.x;
    lassoDraw.y = -lassoLayer1.y;
    if (replayMode)
    {
        main.rCanvasDrawShape.filters = canvasDrawLayerFilterBackUp.concat();
    }
    else
    {
        main.canvasDrawLayerChild.filters = canvasDrawLayerFilterBackUp.concat();
    }
    return true;
}

public static function setAlphaButtonsOnLassoTool(alpha:Number):void
{
    ColorPickerController.colorPickerBox.alpha = alpha;
    main.toolBox.alpha = alpha;
    main.toolOptionsBox.alpha = alpha;
    main.toolBox.toolMirror.alpha = alpha;
}

public static function cLassoTool():Object
{
    var clickPos:Point = new Point(0, 0);
    var maxWidth:Number;
    var maxHeight:Number;
    var lassoRect:Vector.<Number>;
    var lassoPoints:Array;
    function resetPosData():void
    {
        if (lassoRect)
            lassoRect.length = 0;
        if (lassoPoints)
            lassoPoints.length = 0;
        lassoRect = null;
        lassoPoints = null;
    }
    function drawPreviewLine():void
    {
        if (lassoPoints === null)
        {
            return;
        }
        lassoDraw.graphics.clear();
        const len:uint = lassoPoints.length;
        if (lassoPoints.length < 2)
        {
            return;
        }
        main.dottedLine.moveTo(lassoDraw.graphics, lassoPoints[0][0], lassoPoints[0][1]);
        for (var i:uint = 0;i < len;i++)
        {
            main.dottedLine.lineTo(lassoPoints[i][0], lassoPoints[i][1]);
        }
        main.dottedLine.lineTo(lassoPoints[0][0], lassoPoints[0][1], true);
    }
    function setDeafultLassoMenuPos(lassoMenu:LassoMenuSet):void
    {
        const g:Point = lassoLayer1.localToGlobal(new Point(0, 0));
        const lassoW:Number = (lassoMenu.width > main.stage.stageWidth)
            ? main.stage.stageWidth : lassoMenu.width;
        lassoMenu.x = Math.floor(g.x - lassoW / 2);
        lassoMenu.y = Math.floor(g.y + (((lassoLayer1.height) / 2) * main.canvasZoomMultipler + 20));
        // lassoMenu.y = floor(g.y+(((lassoBox1.height)/2)/zoomed+15));
    }
    function onMouseUpLassoTool():void
    {
        main.isMouseDragging = false;
        FOFOTimer.remove("LassoDrawDelayTimer");
        main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveLassoTool);
        main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpLassoTool);
        if (Math.abs(lassoRect[0] - lassoRect[2]) < 5 || Math.abs(lassoRect[1] - lassoRect[3]) < 5)
        {
            resetLassoBox();
            return;
        }
        if (lassoRect[0] < 0)
            lassoRect[0] = 0;
        if (lassoRect[1] < 0)
            lassoRect[1] = 0;
        if (lassoRect[2] > main.CANVAS_WIDTH)
            lassoRect[2] = main.CANVAS_WIDTH;
        if (lassoRect[3] > main.CANVAS_HEIGHT)
            lassoRect[3] = main.CANVAS_HEIGHT;
        lassoTransformData.push(lassoRect);
        lassoTransformData.push(lassoPoints);
        var checklayer1:Boolean = main.canvasLayer1Bitmap.visible;
        var checklayer2:Boolean = main.canvasLayer2Bitmap.visible;
        if (main.checkedLayer === 1)
        {
            checklayer1 = true;
            checklayer2 = false;
        }
        else if (main.checkedLayer === 2)
        {
            checklayer1 = false;
            checklayer2 = true;
        }
        if (moveSelectedAreaToLassoBox(false, lassoRect, lassoPoints, isLassoImageCopied, checklayer1, checklayer2) === false)
        {
            resetLassoBox();
        }
        else
        {
            drawPreviewLine();
            // 라소 메뉴 마우스 커서에보이기
            lassoFirstData = [lassoLayer1.x, lassoLayer1.y, lassoLayer1.scaleX, lassoLayer1.scaleY, lassoLayer1.rotation];
            isLassoToolStarted = true;
            setDeafultLassoMenuPos(lassoMenuBox);
            MainUIController.keepBoxInsideViewPort(lassoMenuBox);
            if (main.checkedLayer || !checklayer1 || !checklayer2)
            {
                lassoMenuBox.lassoLayerSwap.alpha = Global.OFFALPHA;
                lassoMenuBox.lassoLayerMerge.alpha = Global.OFFALPHA;
            }
            else
            {
                lassoMenuBox.lassoLayerSwap.alpha = 1.0;
                lassoMenuBox.lassoLayerMerge.alpha = 1.0;
            }
            lassoLayer2.visible = true;
            lassoMenuBox.visible = true;
            Utils.setAsTopChild(lassoMenuBox);
            if (ReferenceLayerController.isRefLayerMenuON === true)
            {
                ReferenceLayerController.refLayerMenuBox.visible = false;
            }
            setAlphaButtonsOnLassoTool(Global.OFFALPHA);
            addInputEventsLassoTool();
        }
    }
    function onMouseMoveLassoTool(MouseEvent:Event):void
    {
        var mx:Number = main.canvasDrawLayerChild.mouseX;
        var my:Number = main.canvasDrawLayerChild.mouseY;
        lassoPoints.push([mx, my]);
        if (!FOFOTimer.hasTimer("LassoDrawDelayTimer"))
        {
            FOFOTimer.addByName("LassoDrawDelayTimer", 0.1, false, function ():void
                {
                    drawPreviewLine();
                });
        }
        // 사각형 꼭지점 체크
        if (mx < lassoRect[0])
        {
            lassoRect[0] = mx;
        }
        else if (mx > lassoRect[2])
        {
            lassoRect[2] = mx;
        }
        if (my < lassoRect[1])
        {
            lassoRect[1] = my;
        }
        else if (my > lassoRect[3])
        {
            lassoRect[3] = my;
        }
    }
    function start():void
    {
        if (isLassoToolStarted === true || main.isAllLayerInvisible())
            return;
        main.isMouseDragging = true;
        lassoMenuBox.hint("Lasso tool");
        maxWidth = main.CANVAS_WIDTH;
        maxHeight = main.CANVAS_HEIGHT;
        clickPos.setTo(main.canvasDrawLayerChild.mouseX, main.canvasDrawLayerChild.mouseY);
        lassoDraw.x = 0;
        lassoDraw.y = 0;
        // left, top, right, bottom순임
        lassoRect = new <Number>[clickPos.x, clickPos.y, clickPos.x, clickPos.y];
        lassoPoints = [];
        lassoTransformData = [];
        main.canvasDrawLayer.alpha = 1.0; // 알파값이 조정되어 있을 수도 있기 때문에 해줌
        lassoDraw.graphics.clear();
        lassoPoints.push([clickPos.x, clickPos.y]);
        lassoLayer1.visible = true;
        main.dottedLine.setLineScale(main.canvasZoomMultipler);
        if (main.canvasLayer1Bitmap.visible)
        {
            if (lassoLayer1LastBitmapdata != null)
                lassoLayer1LastBitmapdata.dispose();
            lassoLayer1LastBitmapdata = main.canvasLayer1BitmapData.clone();
        }
        if (main.canvasLayer2Bitmap.visible)
        {
            if (lassoLayer2LastBitmapdata != null)
                lassoLayer2LastBitmapdata.dispose();
            lassoLayer2LastBitmapdata = main.canvasLayer2BitmapData.clone();
        }
        main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveLassoTool);
        main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpLassoTool);
    };
    return {
            start: start,
            resetPosData: resetPosData
        };
}

// zoom이나 rotate reg포인트 바뀔때마다
// 캔버스 판넬위치 따라 다니면서 크기 똑같이 해줌
public static function applyLassoBoxImageToCanvas(isTransferRefLayer:Boolean):Array
{
    const lassoBMPScaleX:Number = lassoLayer1.scaleX;
    const lassoBMPScaleY:Number = lassoLayer1.scaleY;
    var lassoBMPWidth:Number = lassoLayer1Bitmap.width * lassoBMPScaleX;
    var lassoBMPHeight:Number = lassoLayer1Bitmap.height * lassoBMPScaleY;
    if (main.checkedLayer === 2 || main.canvasLayer1Bitmap.visible === false)
    {
        lassoBMPWidth = lassoLayer2Bitmap.width * lassoBMPScaleX;
        lassoBMPHeight = lassoLayer2Bitmap.height * lassoBMPScaleY;
    }
    const boxX:Number = lassoLayer1.x;
    const boxY:Number = lassoLayer1.y;
    const ang:Number = lassoLayer1.rotation * Math.PI / 180;
    var posMatrix:Matrix = new Matrix();
    posMatrix.scale(lassoBMPScaleX, lassoBMPScaleY); // 스케일부터 조절해주고
    posMatrix.translate(-lassoBMPWidth / 2, -lassoBMPHeight / 2); // 회전 중심점을 bmp중심으로 옮겨주고
    posMatrix.rotate(ang); // 회전해줌
    posMatrix.translate(boxX, boxY); // 라소박스 위치 그대로 붙여주면됨
    lassoLayer1Bitmap.smoothing = true;
    lassoLayer2Bitmap.smoothing = true;
    if (isTransferRefLayer === false)
    {
        if (main.canvasLayer1Bitmap.visible)
            main.canvasLayer1BitmapData.draw(lassoLayer1Bitmap, posMatrix);
        if (main.canvasLayer2Bitmap.visible)
            main.canvasLayer2BitmapData.draw(lassoLayer2Bitmap, posMatrix);
    }
    else
    {
        var layer1Bmpd:BitmapData;
        var layer2Bmpd:BitmapData;
        if (main.canvasLayer1Bitmap.visible)
        {
            layer1Bmpd = new BitmapData(main.CANVAS_WIDTH, main.CANVAS_HEIGHT, true, 0);
            layer1Bmpd.draw(lassoLayer1Bitmap, posMatrix);
        }
        if (main.canvasLayer2Bitmap.visible)
        {
            layer2Bmpd = new BitmapData(main.CANVAS_WIDTH, main.CANVAS_HEIGHT, true, 0);
            layer2Bmpd.draw(lassoLayer2Bitmap, posMatrix);
        }
        ReferenceLayerController.mergeImageToRefLayer(layer1Bmpd, layer2Bmpd);
        if (layer1Bmpd)
        {
            layer1Bmpd.dispose();
            layer1Bmpd = null;
        }
        if (layer2Bmpd)
        {
            layer2Bmpd.dispose();
            layer2Bmpd = null;
        }
        ReferenceLayerController.resetRefLayerImageTransform();
    }
    if (lassoLayer1LastBitmapdata)
    {
        lassoLayer1LastBitmapdata.dispose();
        lassoLayer1LastBitmapdata = null;
    }
    if (lassoLayer2LastBitmapdata)
    {
        lassoLayer2LastBitmapdata.dispose();
        lassoLayer2LastBitmapdata = null;
    }
    return [lassoBMPScaleX, lassoBMPScaleY,
            lassoBMPWidth, lassoBMPHeight,
            ang, boxX, boxY];
}

public static function applyLassoImageToCanvas():void
{
    if (isLassoToolStarted === true)
    {
        if (hasLassoImageChanges() === true) // 사용후에 ok하면 처리해줌
        {
            if (main.isDeepUndoEnabled)
            {
                main.applyDeepUndo();
            }
            const lassoInfo:Array = applyLassoBoxImageToCanvas(false);
            const point1:Vector.<Number> = lassoTransformData[0].concat();
            const point2:Array = lassoTransformData[1].concat();
            var command:Array = null;
            if (lassoLayerCommandData && lassoLayerCommandData.length > 0)
            {
                command = lassoLayerCommandData.concat();
            }
            var checklayer1:Boolean = main.canvasLayer1Bitmap.visible;
            var checklayer2:Boolean = main.canvasLayer2Bitmap.visible;
            if (main.checkedLayer === 1)
            {
                checklayer1 = true;
                checklayer2 = false;
            }
            else if (main.checkedLayer === 2)
            {
                checklayer1 = false;
                checklayer2 = true;
            }
            main.rDataBuffer.push(["lasso2", point1, point2
                        , lassoInfo
                        , isLassoImageCopied
                        , checklayer1
                        , checklayer2
                        , command]);
            main.undoManager.addNew();
        }
        else
        {
            lassoCancelBmpd();
        }
        disposeLassoBoxBitmapData();
    }
    resetLassoBox();
}

public static function disposeLassoBoxBitmapData():void
{
    if (lassoLayer1Bitmap.bitmapData)
    {
        lassoLayer1Bitmap.bitmapData.dispose();
    }
    if (lassoLayer2Bitmap.bitmapData)
    {
        lassoLayer2Bitmap.bitmapData.dispose();
    }
}

// todo cancel lasso bmpd 로 바꾸기
public static function lassoCancelBmpd():void
{
    if (lassoLayer1LastBitmapdata)
    {
        main.canvasLayer1BitmapData = main.updateBitmapData(main.canvasLayer1BitmapData, lassoLayer1LastBitmapdata, main.canvasLayer1Bitmap);
    }
    if (lassoLayer2LastBitmapdata)
    {
        main.canvasLayer2BitmapData = main.updateBitmapData(main.canvasLayer2BitmapData, lassoLayer2LastBitmapdata, main.canvasLayer2Bitmap);
    }
    main.canvasNavigatorBox.updateImage(main.canvasLayer1BitmapData, main.canvasLayer2BitmapData, main.CANVAS_BG_COLOR);
    if (ImageViewWindow.isCanvasWindowON)
    {
        ImageViewWindow.updateCanvasWindowImage();
    }
}

public static function cancelLassoTool():void
{
    disposeLassoBoxBitmapData();
    lassoCancelBmpd();
    resetLassoBox();
}

// 라소박스 변형이랑 플래그 초기화
public static function resetLassoBox():void
{
    removeInputEventsLassoTool();
    isLassoToolStarted = false;
    isLassoMirrorON = false;
    isLassoImageCopied = false;
    isLassoMenuHiddenTemp = false;
    lassoLayerCommandData = null;
    isLassoLayerSwapButtonClicked = false;
    lassoFirstData = [];
    lassoTransformData = [];
    lassoLayer1Bitmap.filters = [];
    lassoLayer2Bitmap.filters = [];
    lassoMenuBox.visible = false;
    lassoDraw.x = 0;
    lassoDraw.y = 0;
    lassoLayer1.visible = false;
    lassoLayer1.x = 0;
    lassoLayer1.y = 0;
    lassoLayer1.scaleX = 1.0;
    lassoLayer1.scaleY = 1.0;
    lassoLayer1.rotation = 0;
    lassoLayer2.visible = false;
    lassoLayer2.x = 0;
    lassoLayer2.y = 0;
    lassoLayer2.scaleX = 1.0;
    lassoLayer2.scaleY = 1.0;
    lassoLayer2.rotation = 0;
    lassoMenuBox.lassoCopy.alpha = 1.0;
    lassoMenuBox.lassoLayerMerge.alpha = 1.0;
    lassoToolFunction.resetPosData();
    if (lassoLayer1LastBitmapdata)
    {
        lassoLayer1LastBitmapdata.dispose();
        lassoLayer1LastBitmapdata = null;
    }
    if (lassoLayer2LastBitmapdata)
    {
        lassoLayer2LastBitmapdata.dispose();
        lassoLayer2LastBitmapdata = null;
    }
    if (ReferenceLayerController.isRefLayerMenuON === true)
        ReferenceLayerController.refLayerMenuBox.visible = true;
    if (main.toolOptionsBox.layer1CheckedButton.visible || main.toolOptionsBox.layer2CheckedButton.visible)
    {
        main.toolBox.setToolButtonsForCheckedLayerON();
    }
    main.toolBox.setIconAlphaOnLassoToolON(1.0);
    main.toolOptionsBox.layerButtonWrapper.alpha = 1.0;
    main.toolOptionsBox.airBrushButtonWrapper.alpha = 1.0;
    main.toolOptionsBox.sharpLineButtonWrapper.alpha = 1.0;
    main.toolOptionsBox.opaSizeButtonWrapper.alpha = 1.0;
    ColorPickerController.colorPickerBox.alpha = 1.0;
    main.selectLastUsedTool();
    setAlphaButtonsOnLassoTool(1.0);
}

public static function move1PxLassoTool(command:int):void
{
    var posX:Number = 0;
    var posY:Number = 0;
    if (command === LASSO_1PX_MOVE_UP)
        posY = -1;
    else if (command === LASSO_1PX_MOVE_DOWN)
        posY = 1;
    else if (command === LASSO_1PX_MOVE_LEFT)
        posX = -1;
    else if (command === LASSO_1PX_MOVE_RIGHT)
        posX = 1;
    const rotatedPoint:Point = Utils.rotatePoint(posX, posY, main.canvasAnchorPoint.rotation);
    lassoLayer1.x += rotatedPoint.x;
    lassoLayer1.y += rotatedPoint.y;
    lassoLayer2.x = lassoLayer1.x;
    lassoLayer2.y = lassoLayer1.y;
}

public static function onRightMouseDownLassoTool(e:MouseEvent):void
{
    if (!isLassoToolStarted)
    {
        return;
    }
    const target:DisplayObject = e.target as DisplayObject;
    if (!target)
        return;
    const targetName:String = target.name;
    if (targetName === "toolZoom"
            || targetName === "toolZoomIn"
            || targetName === "toolZoomOut")
    {
        if (main.canvasZoomMultipler !== 1.0)
            main.resetZoomDrawMode();
    }
    else if (targetName === "toolRotate")
    {
        if (main.canvasAnchorPoint.rotation !== 0.0)
            main.resetRotationDrawMode();
    }
}

public static function onRightMouseUpLassoTool(e:MouseEvent):void
{
    if (!isLassoToolStarted || main.isMouseClicked)
    {
        return;
    }
    const target:DisplayObject = e.target as DisplayObject;
    if (!target)
        return;
    const targetName:String = target.name;
    if (targetName === "toolZoom"
            || targetName === "toolZoomIn"
            || targetName === "toolZoomOut"
            || targetName === "toolRotate")
    {
        return;
    }
    if (lassoMenuBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false || targetName === "lassoOK")
    {
        applyLassoImageToCanvas();
        return;
    }
    if (targetName === "lassoRotate")
    {
        if (lassoLayer1.rotation !== 0)
        {
            lassoLayer1.rotation = 0;
            lassoLayer2.rotation = 0;
        }
    }
    else if (targetName === "lassoResize")
    {
        if (lassoLayer1.scaleY !== 1.0)
        {
            lassoLayer1.scaleX = (isLassoMirrorON) ? -1.0 : 1.0;
            lassoLayer1.scaleY = 1.0;
            lassoLayer2.scaleX = lassoLayer1.scaleX;
            lassoLayer2.scaleY = lassoLayer1.scaleY;
        }
    }
}

public static function onMouseUpLassoTool(e:MouseEvent):void
{
    if (main.getPressedKeyCount() === 1 && main.getFirstPressedKey() === main.KEY.space)
    {
        main.updateLastKey(main.KEY.space);
        isLassoMenuHiddenTemp = true;
        main.setSelectedTool(main.TOOL_HAND);
        main.showNowToolIconToCursorTemp(main.TOOL_HAND);
    }
}

public static function onMouseDownLassoTool(e:MouseEvent):void
{
    if (main.isRightMouseClicked)
    {
        return;
    }
    const target:DisplayObject = e.target as DisplayObject;
    if (!target)
    {
        return;
    }
    const targetName:String = target.name;
    if (main.isCursorInDrawArea() && lassoMenuBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
    {
        if (isLassoMenuHiddenTemp)
        {
            lassoMenuBox.visible = false;
            if (main.isSelectedTool(main.TOOL_HAND))
                main.handTool(false, false);
            else if (main.isSelectedTool(main.TOOL_ZOOM))
                main.zoomTool();
            else if (main.isSelectedTool(main.TOOL_ROTATE))
                main.rotateTool(false);
        }
        else
        {
            startLassoImageMove();
        }
    }
    else
    {
        switch (targetName)
        {
            case "lassoMove":
                {
                    startLassoImageMove();
                }
                break;
            case "lassoResize":
                {
                    startLassoImageResize();
                }
                break;
            case "lassoRotate":
                {
                    startLassoImageRotation();
                }
                break;
            case "navStageBG":
            case "navBitmapBG":
            case "navLayer1Bitmap":
            case "navLayer2Bitmap":
                {
                    main.startCanvasMoveByCanvasNavigator(false);
                }
                break;
            case "navCursor":
                {
                    main.startCanvasMoveByCanvasNavigator(true);
                }
                break;
            case "lassoMenuMoveButton":
                {
                    Utils.setAsTopChild(lassoMenuBox);
                    DragInteraction.startBoxDrag(lassoMenuBox);
                }
                break;
            case "sideBarScrollBar":
                {
                    SidebarController.startScrollSidebarByDrag();
                }
                break;
            case "toolZoomIn":
                {
                    main.zoomInCanvas(true, false);
                }
                break;
            case "toolZoomOut":
                {
                    main.zoomInCanvas(false, false);
                }
                break;
            case "toolRotate":
                {
                    lassoMenuBox.visible = false;
                    isLassoMenuHiddenTemp = true;
                    main.rotateTool(false);
                }
                break;
            case "lasso1pxUp":
            case "lasso1pxDown":
            case "lasso1pxLeft":
            case "lasso1pxRight":
            case "lassoCopy":
            case "lassoOK":
            case "lassoCancel":
            case "lassoRefLayer":
            case "sideBarPositionButton":
            case "sideBarPositionButton2":
            case "sideBarOFFButton":
            case "sideBarOFFButton2":
            case "sideBarONButton":
            case "sideBarONButton2":
            case "lassoLayerMerge":
            case "lassoLayerSwap":
            case "lassoMirror":
                main.handleMouseClick(targetName);
                break;
            default:
                break;
        }
    }
}
}
}
