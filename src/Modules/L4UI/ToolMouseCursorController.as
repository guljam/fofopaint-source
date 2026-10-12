package Modules.L4UI
{
    import Modules.L1Data.AppSettingsIniFile;
    import Modules.L1Data.MouseState;
    import Modules.L1Data.ToolState;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L4UI.CaptureEngine.CaptureController;
    import Modules.L4UI.DrawEngine.CanvasResizer;
    import Modules.L4UI.Tools.ToolPanel;
    import Modules.L4UI.UIEngine.UIController;
    import flash.display.BitmapData;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.ui.Mouse;
    import flash.ui.MouseCursor;
    import flash.ui.MouseCursorData;
    import flash.utils.ByteArray;
    import flash.utils.Endian;

    // 층: L4 UI - 툴마다 다른 OS 마우스 커서 (resource/mousecursor/*.bmp 24bit, 마젠타가 투명)
    // 그림은 오른손용 한 벌만 두고, 왼손잡이 설정이면 등록할 때 좌우로 뒤집음
    public class ToolMouseCursorController
    {
        [Embed(source="../../../resource/mousecursor/pen.bmp", mimeType="application/octet-stream")]
        private static const PenBmpBytes:Class;
        [Embed(source="../../../resource/mousecursor/eraser.bmp", mimeType="application/octet-stream")]
        private static const EraserBmpBytes:Class;
        [Embed(source="../../../resource/mousecursor/fillpen.bmp", mimeType="application/octet-stream")]
        private static const FillPenBmpBytes:Class;
        [Embed(source="../../../resource/mousecursor/eyedropper.bmp", mimeType="application/octet-stream")]
        private static const EyedropperBmpBytes:Class;
        [Embed(source="../../../resource/mousecursor/lasso.bmp", mimeType="application/octet-stream")]
        private static const LassoBmpBytes:Class;
        [Embed(source="../../../resource/mousecursor/move.bmp", mimeType="application/octet-stream")]
        private static const MoveBmpBytes:Class;
        [Embed(source="../../../resource/mousecursor/hand_open.bmp", mimeType="application/octet-stream")]
        private static const HandOpenBmpBytes:Class;
        [Embed(source="../../../resource/mousecursor/hand_grab.bmp", mimeType="application/octet-stream")]
        private static const HandGrabBmpBytes:Class;
        [Embed(source="../../../resource/mousecursor/zoom.bmp", mimeType="application/octet-stream")]
        private static const ZoomBmpBytes:Class;
        [Embed(source="../../../resource/mousecursor/rotate.bmp", mimeType="application/octet-stream")]
        private static const RotateBmpBytes:Class;

        private static const CURSOR_SIZE:int = 32;
        private static const TRANSPARENT_KEY_COLOR:uint = 0xFF00FF;

        private static const CURSOR_NAME_PEN:String = "fofoCursorPen";
        private static const CURSOR_NAME_ERASER:String = "fofoCursorEraser";
        private static const CURSOR_NAME_FILLPEN:String = "fofoCursorFillPen";
        private static const CURSOR_NAME_EYEDROPPER:String = "fofoCursorEyedropper";
        private static const CURSOR_NAME_LASSO:String = "fofoCursorLasso";
        private static const CURSOR_NAME_MOVE:String = "fofoCursorMove";
        private static const CURSOR_NAME_HAND_OPEN:String = "fofoCursorHandOpen";
        private static const CURSOR_NAME_HAND_GRAB:String = "fofoCursorHandGrab";
        private static const CURSOR_NAME_ZOOM:String = "fofoCursorZoom";
        private static const CURSOR_NAME_ROTATE:String = "fofoCursorRotate";

        private static var isCursorRegistered:Boolean = false;
        private static var registeredCursorNameList:Vector.<String> = new Vector.<String>();
        private static var lastAppliedCursorName:String = null;

        // 왼손잡이 설정을 읽은 뒤에 부름. 설정이 바뀌면 다시 부르면 됨 (이미 등록된 커서는 지우고 다시 등록)
        public static function registerToolMouseCursors():void
        {
            if (!Mouse.supportsNativeCursor)
            {
                return;
            }
            if (isCursorRegistered)
            {
                Mouse.cursor = MouseCursor.AUTO;
                for each (var oldName:String in registeredCursorNameList)
                {
                    Mouse.unregisterCursor(oldName);
                }
                registeredCursorNameList.length = 0;
            }
            lastAppliedCursorName = null;
            const isLeftHanded:Boolean = AppSettingsIniFile.isLeftHandedMouseCursor;
            // 핫스팟은 오른손용 그림 기준 (make_cursors.py의 CURSORS와 같은 값)
            registerToolMouseCursor(CURSOR_NAME_PEN, new PenBmpBytes() as ByteArray, 3, 29, isLeftHanded);
            registerToolMouseCursor(CURSOR_NAME_ERASER, new EraserBmpBytes() as ByteArray, 8, 28, isLeftHanded);
            registerToolMouseCursor(CURSOR_NAME_FILLPEN, new FillPenBmpBytes() as ByteArray, 3, 29, isLeftHanded);
            registerToolMouseCursor(CURSOR_NAME_EYEDROPPER, new EyedropperBmpBytes() as ByteArray, 3, 29, isLeftHanded);
            registerToolMouseCursor(CURSOR_NAME_LASSO, new LassoBmpBytes() as ByteArray, 4, 29, isLeftHanded);
            registerToolMouseCursor(CURSOR_NAME_MOVE, new MoveBmpBytes() as ByteArray, 16, 16, isLeftHanded);
            registerToolMouseCursor(CURSOR_NAME_HAND_OPEN, new HandOpenBmpBytes() as ByteArray, 16, 16, isLeftHanded);
            registerToolMouseCursor(CURSOR_NAME_HAND_GRAB, new HandGrabBmpBytes() as ByteArray, 16, 18, isLeftHanded);
            registerToolMouseCursor(CURSOR_NAME_ZOOM, new ZoomBmpBytes() as ByteArray, 12, 12, isLeftHanded);
            registerToolMouseCursor(CURSOR_NAME_ROTATE, new RotateBmpBytes() as ByteArray, 16, 16, isLeftHanded);
            isCursorRegistered = true;
        }

        // 마우스를 움직이거나 툴이 바뀔 때 부름. 이름이 바뀔 때만 Mouse.cursor에 대입함
        public static function updateToolMouseCursorByToolAndPointerArea():void
        {
            if (!isCursorRegistered)
            {
                return;
            }
            const cursorName:String = isToolMouseCursorAllowedHere() ? getCursorNameFromSelectedTool() : MouseCursor.AUTO;
            if (cursorName === lastAppliedCursorName)
            {
                return;
            }
            lastAppliedCursorName = cursorName;
            Mouse.cursor = cursorName;
        }

        // 리플레이/캡처 모드, UI 위, 메뉴가 열린 동안은 기본 커서
        private static function isToolMouseCursorAllowedHere():Boolean
        {
            return !(ReplayState.isReplayModeON || CaptureController.isCaptureModeON
                    || ToolPanel.isToolBox2Showing || UIController.loadMenuBox.visible
                    || CanvasResizer.isCanvasResizing() || !UIController.isCursorInDrawArea());
        }

        private static function getCursorNameFromSelectedTool():String
        {
            switch (ToolState.nowTool)
            {
                case ToolState.TOOL_PEN:
                case ToolState.TOOL_LINE:
                    return CURSOR_NAME_PEN;
                case ToolState.TOOL_ERASER:
                    return CURSOR_NAME_ERASER;
                case ToolState.TOOL_FILLPEN:
                    return CURSOR_NAME_FILLPEN;
                case ToolState.TOOL_EYEDROPPER:
                    return CURSOR_NAME_EYEDROPPER;
                case ToolState.TOOL_LASSO:
                    return CURSOR_NAME_LASSO;
                case ToolState.TOOL_MOVE:
                    return CURSOR_NAME_MOVE;
                case ToolState.TOOL_HAND:
                    return MouseState.isLeftDown ? CURSOR_NAME_HAND_GRAB : CURSOR_NAME_HAND_OPEN;
                case ToolState.TOOL_ZOOM:
                    return CURSOR_NAME_ZOOM;
                case ToolState.TOOL_ROTATE:
                    return CURSOR_NAME_ROTATE;
            }
            return MouseCursor.AUTO;
        }

        private static function registerToolMouseCursor(cursorName:String, bmpBytes:ByteArray, hotSpotX:int, hotSpotY:int, isLeftHanded:Boolean):void
        {
            var cursorBitmapData:BitmapData = createCursorBitmapDataFromBmpBytes(bmpBytes);
            if (isLeftHanded)
            {
                const flippedBitmapData:BitmapData = new BitmapData(CURSOR_SIZE, CURSOR_SIZE, true, 0);
                flippedBitmapData.draw(cursorBitmapData, new Matrix(-1, 0, 0, 1, CURSOR_SIZE, 0));
                cursorBitmapData.dispose();
                cursorBitmapData = flippedBitmapData;
                hotSpotX = CURSOR_SIZE - 1 - hotSpotX;
            }
            const cursorData:MouseCursorData = new MouseCursorData();
            cursorData.data = new <BitmapData>[cursorBitmapData];
            cursorData.hotSpot = new Point(hotSpotX, hotSpotY);
            Mouse.registerCursor(cursorName, cursorData);
            registeredCursorNameList.push(cursorName);
        }

        // 24bit 비압축 BMP(아래 줄부터 저장, 줄마다 4바이트 정렬)를 읽고 마젠타를 투명으로 바꿈
        private static function createCursorBitmapDataFromBmpBytes(bmpBytes:ByteArray):BitmapData
        {
            bmpBytes.endian = Endian.LITTLE_ENDIAN;
            bmpBytes.position = 10;
            const pixelDataOffset:uint = bmpBytes.readUnsignedInt();
            bmpBytes.position = 18;
            const bmpWidth:int = bmpBytes.readInt();
            const bmpHeight:int = bmpBytes.readInt();
            const rowStride:int = (bmpWidth * 3 + 3) & ~3;
            const cursorBitmapData:BitmapData = new BitmapData(bmpWidth, bmpHeight, true, 0);
            for (var rowIndex:int = 0; rowIndex < bmpHeight; rowIndex++)
            {
                const canvasY:int = bmpHeight - 1 - rowIndex;
                bmpBytes.position = pixelDataOffset + rowIndex * rowStride;
                for (var canvasX:int = 0; canvasX < bmpWidth; canvasX++)
                {
                    const blue:uint = bmpBytes.readUnsignedByte();
                    const green:uint = bmpBytes.readUnsignedByte();
                    const red:uint = bmpBytes.readUnsignedByte();
                    const rgb:uint = (red << 16) | (green << 8) | blue;
                    cursorBitmapData.setPixel32(canvasX, canvasY, rgb === TRANSPARENT_KEY_COLOR ? 0 : (0xFF000000 | rgb));
                }
            }
            return cursorBitmapData;
        }
    }
}
