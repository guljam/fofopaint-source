package main_module
{

    import flash.display.NativeWindow;
    import flash.display.Bitmap;
    import flash.geom.Point;
    import flash.display.Sprite;
    import flash.display.BitmapData;
    import flash.geom.Rectangle;
    import flash.events.KeyboardEvent;
    import flash.events.Event;
    import flash.display.NativeWindowInitOptions;
    import flash.display.NativeWindowSystemChrome;
    import flash.display.NativeWindowType;
    import flash.display.StageScaleMode;
    import flash.display.StageAlign;
    import flash.events.MouseEvent;
    import flash.events.NativeWindowBoundsEvent;

    public final class ImageViewWindow
    {
        public static var canvasWindowInfo:Array = [null, null, 400, 400]; // x, y, 너비, 높이
        private static var _isCanvasWindowON:Boolean = false; // 캔버스 새창 켜졌을 때
        public static var canvasWindow:NativeWindow; // 참조된 새 창
        public static var canvasWindowLayer1Bitmap:Bitmap; // 새창 안에 들어갈 레이어 1
        public static var canvasWindowLayer2Bitmap:Bitmap; // 새창 안에 들어갈 레이어 2
        public static var canvasWindowCanvasPanel:Sprite; // 캔버스 배경색
        public static var canvasWindowCanvasPanelBgSize:Point = new Point(0, 0); // 배경 크기
        public static var canvasWindowCanvasPanelBgColor:uint = 0; // 배경 색상
        public static var canvasWindowIgnoreResizeEventFlag:Boolean = false; // 창 크기 조정 이벤트 무시 플래그

        public static function get isCanvasWindowON():Boolean
        {
            return _isCanvasWindowON;
        }

        public static function updateCanvasWindowBGColor(color:uint, bmpd:BitmapData):void
        {
            if (canvasWindowCanvasPanelBgSize.x === bmpd.width
                    && canvasWindowCanvasPanelBgSize.y === bmpd.height
                    && canvasWindowCanvasPanelBgColor === color)
            {
                return;
            }

            canvasWindowCanvasPanel.graphics.clear();
            canvasWindowCanvasPanel.graphics.beginFill(color, 1.0);
            canvasWindowCanvasPanel.graphics.drawRect(0, 0, bmpd.width, bmpd.height);
            canvasWindowCanvasPanel.graphics.endFill();
            canvasWindowCanvasPanelBgSize.setTo(bmpd.width, bmpd.height);
            canvasWindowCanvasPanelBgColor = color;
        }

        public static function setCanvasWindowVisible(flag:Boolean):void
        {
            canvasWindow.visible = flag;
        }

        public static function updateCanvasWindowBitmapSize():void
        {
            const main:Main = Main._instance;
            const bounds:Rectangle = main.canvasNavigatorBox.setFitBitmapforBox(main.canvasLayer1BitmapData.width,
                    main.canvasLayer1BitmapData.height,
                    canvasWindow.stage.stageWidth,
                    canvasWindow.stage.stageHeight);
            updateCanvasWindowBGColor(main.CANVAS_BG_COLOR, main.canvasLayer1BitmapData);
            canvasWindowCanvasPanel.x = bounds.x;
            canvasWindowCanvasPanel.y = bounds.y;
            canvasWindowCanvasPanel.width = bounds.width;
            canvasWindowCanvasPanel.height = bounds.height;
        }

        public static function updateCanvasWindowData():void
        {
            FOFOTimer.addByName("canvasWindowUpdateDelayTimer", 0.2, false,
                    function():void
                    {
                        canvasWindowInfo[0] = canvasWindow.x;
                        canvasWindowInfo[1] = canvasWindow.y;
                        canvasWindowInfo[2] = canvasWindow.width;
                        canvasWindowInfo[3] = canvasWindow.height;

                        if (canvasWindowCanvasPanel.width !== canvasWindow.stage.stageWidth
                                || canvasWindowCanvasPanel.height !== canvasWindow.stage.stageHeight)
                        {
                            updateCanvasWindowBitmapSize();
                            return;
                        }
                    });
        }

        public static function onMoveCanvasWindow(e:Event):void
        {
            updateCanvasWindowData();
        }

        public static function onResizeCanvasWindow(e:Event):void
        {
            if (!canvasWindowIgnoreResizeEventFlag)
            {
                updateCanvasWindowData();
            }
            else
            {
                canvasWindowIgnoreResizeEventFlag = false;
            }
        }

        public static function updateCanvasWindowImage():void
        {
            const main:Main = Main._instance;

            canvasWindowLayer1Bitmap.bitmapData = main.canvasNavigatorBox.navLayer1Bitmap.bitmapData;
            canvasWindowLayer2Bitmap.bitmapData = main.canvasNavigatorBox.navLayer2Bitmap.bitmapData;
            canvasWindowLayer1Bitmap.smoothing = true;
            canvasWindowLayer2Bitmap.smoothing = true;
        }

        public static function copyMainWindowTitleToCanvasWindow():void
        {
            const main:Main = Main._instance;
            canvasWindow.title = main.stage.nativeWindow.title;
        }

        public static function fitCanvasWindowSizeToImage():void
        {
            if (canvasWindowCanvasPanel.width === canvasWindow.stage.stageWidth
                    && canvasWindowCanvasPanel.height === canvasWindow.stage.stageHeight)
            {
                return;
            }

            canvasWindowIgnoreResizeEventFlag = true;
            canvasWindow.bounds = new Rectangle(canvasWindow.bounds.x, canvasWindow.bounds.y
                    , canvasWindowCanvasPanel.width, canvasWindowCanvasPanel.height);
            // 한번 더해줘야 정확함
            canvasWindowIgnoreResizeEventFlag = true;
            canvasWindow.bounds = new Rectangle(canvasWindow.bounds.x, canvasWindow.bounds.y
                    , canvasWindow.bounds.width + (canvasWindowCanvasPanel.width - canvasWindow.stage.stageWidth)
                    , canvasWindow.bounds.height + (canvasWindowCanvasPanel.height - canvasWindow.stage.stageHeight));

            canvasWindowCanvasPanel.x = 0;
            canvasWindowCanvasPanel.y = 0;
        }

        public static function onMouseDownCanvasWindow(e:MouseEvent):void
        {
            canvasWindow.startMove();
        }

        public static function onRightMouseUpCanvasWindow(e:MouseEvent):void
        {
            if (canvasWindowCanvasPanel.width === canvasWindow.width
                    && canvasWindowCanvasPanel.height === canvasWindow.height)
            {
                return;
            }

            fitCanvasWindowSizeToImage();
        }

        public static function closeCanvasWindow():void
        {
            const main:Main = Main._instance;

            canvasWindow.visible = false;
            _isCanvasWindowON = false;
            if (!main.isReplayModeON && !main.isCaptureModeON)
            {
                MainUI.topBar.newWindowButton.visible = true;
                MainUI.topBar.newWindowCloseButton.visible = false;
            }
            main.stage.nativeWindow.activate();
        }

        public static function onKeyDownCanvasWindow(e:KeyboardEvent):void
        {
            const main:Main = Main._instance;
            if (e.keyCode === main.KEY.esc)
            {
                closeCanvasWindow();
            }
        }

        public static function onClosingCanvasWindow(e:Event):void
        {
            e.preventDefault();
            closeCanvasWindow();
        }

        public static function initializeCanvasWindow():void
        {
            const main:Main = Main._instance;

            var windowOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
            windowOptions.systemChrome = NativeWindowSystemChrome.STANDARD;
            windowOptions.type = NativeWindowType.NORMAL;
            windowOptions.owner = main.stage.nativeWindow;
            windowOptions.renderMode = "direct";

            canvasWindow = new NativeWindow(windowOptions);

            copyMainWindowTitleToCanvasWindow();
            canvasWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
            canvasWindow.stage.align = StageAlign.TOP_LEFT;
            canvasWindow.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownCanvasWindow);
            canvasWindow.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpCanvasWindow);
            canvasWindow.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownCanvasWindow);
            canvasWindow.addEventListener(Event.CLOSING, onClosingCanvasWindow);
            canvasWindow.addEventListener(Event.RESIZE, onResizeCanvasWindow);
            canvasWindow.addEventListener(NativeWindowBoundsEvent.MOVE, onMoveCanvasWindow);
            canvasWindow.addEventListener(Event.ACTIVATE, onActivateCanvasWindow);

            canvasWindowCanvasPanel = new Sprite();
            canvasWindowCanvasPanel.name = "canvasWindowCanvasPanel";
            canvasWindowLayer1Bitmap = new Bitmap();
            canvasWindowLayer2Bitmap = new Bitmap();
            updateCanvasWindowImage();

            canvasWindowCanvasPanel.addChild(canvasWindowLayer2Bitmap);
            canvasWindowCanvasPanel.addChild(canvasWindowLayer1Bitmap);
        }

        public static function onActivateCanvasWindow(e:Event):void
        {
            const main:Main = Main._instance;

            _isCanvasWindowON = true;

            if (!main.isReplayModeON && !main.isCaptureModeON)
            {
                MainUI.topBar.newWindowButton.visible = false;
                MainUI.topBar.newWindowCloseButton.visible = true;
            }
            if (canvasWindow.stage.getChildByName("canvasWindowCanvasPanel") === null)
            {
                canvasWindow.stage.addChild(canvasWindowCanvasPanel);
                canvasWindow.stage.color = Global.getUIStageColor();
            }

            updateCanvasWindowImage();
            updateCanvasWindowBitmapSize();
            updateCanvasWindowData();
        }

        public static function openImageViewWindow():void
        {
            if (canvasWindow === null)
            {
                initializeCanvasWindow();
                if (canvasWindowInfo[0] === null)
                {
                    const main:Main = Main._instance;
                    canvasWindowInfo[0] = main.stage.nativeWindow.x + MainUI.topBar.newWindowButton.x - canvasWindowInfo[2] / 2;
                    canvasWindowInfo[1] = main.stage.nativeWindow.y;
                }
                canvasWindow.bounds = new Rectangle(canvasWindowInfo[0], canvasWindowInfo[1], canvasWindowInfo[2], canvasWindowInfo[3]);
            }

            canvasWindow.activate();
        }

        public function ImageViewWindow():void
        {

        }
    }
}
