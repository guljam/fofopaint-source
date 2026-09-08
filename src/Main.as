package
{
    import flash.desktop.Clipboard;
    import flash.desktop.ClipboardFormats;
    import flash.desktop.NativeApplication;
    import flash.desktop.NativeDragManager;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.SimpleButton;
    import flash.display.Graphics;
    import flash.display.LineScaleMode;
    import flash.display.CapsStyle;
    import flash.display.JointStyle;
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.IBitmapDrawable;
    import flash.display.StageScaleMode;
    import flash.display.StageAlign;
    import flash.display.StageQuality;
    import flash.display.Loader;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;
    import flash.events.NativeDragEvent;
    import flash.events.InvokeEvent;
    import flash.events.TimerEvent;
    import flash.events.UncaughtErrorEvent;
    import flash.events.ErrorEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileStream;
    import flash.filesystem.FileMode;
    import flash.filters.BlurFilter;
    import flash.filters.GlowFilter;
    import flash.filters.ConvolutionFilter;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.ColorTransform;
    import flash.geom.Rectangle;
    import flash.net.URLRequest;
    import flash.net.FileFilter;
    import flash.net.navigateToURL;
    import flash.system.Capabilities;
    import flash.system.IME;
    import flash.utils.ByteArray;
    import flash.utils.getTimer;
    import flash.utils.Timer;
    import flash.ui.Mouse;
    import Modules.Tools.LassoTool;
    import Modules.Tools.PenTool;
    import Modules.Utils;
    import Modules.CanvasGridOverlay;
    import Modules.DragInteraction;
    import Modules.ClipboardManager;
    import Modules.ImageViewWindow;
    import Modules.MainUI;
    import Modules.AppUpdater;
    import Modules.BackgroundWorkerCoordinator;
    import Modules.ReferenceLayerController;
    import Modules.MainUIController;
    import Modules.SidebarController;
    import Modules.PaletteController;
    import Symbols.ToolMenuSet;
    import Symbols.ToolMenuSet2;
    import Symbols.FillPenMenuSet;
    import Symbols.EyedropperLensSet;
    import Symbols.AboutWindowSet;
    import Symbols.CanvasInfoSet;
    import Symbols.CanvasNavigatorBoxSet;
    import Symbols.LassoMenuSet;
    import Symbols.LoadBoxSet;
    import Symbols.NumPadSet;
    import Symbols.ToolOptionsSet;
    import Modules.ColorPickerController;
    import Modules.CaptureController;
    import Modules.FileManager;
    import Symbols.HintBoxSet;
    import Modules.CanvasController;
    import flash.net.registerClassAlias;
    import Modules.AppStateManager;
    import flash.utils.describeType;
    // import
    public class Main extends Sprite
    {
        private const savepos:Array = [0, 0, 0, 0];

        public static var _instance:Main;
        public const APP_VERSION:String = "28.01";
        public const APP_STATE_VERSION:String = "2801";
        public const TOOL_NONE:int = 0,
            TOOL_PEN:int = (1 << 0),
            TOOL_ERASER:int = (1 << 1),
            TOOL_LINE:int = (1 << 2),
            TOOL_FILLPEN:int = (1 << 3),
            TOOL_HAND:int = (1 << 4),
            TOOL_LASSO:int = (1 << 5),
            TOOL_EYEDROPPER:int = (1 << 6),
            TOOL_ZOOM:int = (1 << 7),
            TOOL_ROTATE:int = (1 << 8),
            TOOL_MOVE:int = (1 << 9),
            TOOL_UNDO:int = (1 << 10),
            TOOL_REDO:int = (1 << 11),
            TOOL_MIRROR:int = (1 << 12);
        public const JUMP_FRAME_PLAY:int = (1 << 0),
            JUMP_FRAME_MANUAL:int = (1 << 1),
            JUMP_FRAME_PREV:int = (1 << 2),
            JUMP_FRAME_NEXT:int = (1 << 3);
        public const REPLAY_FASTEST_TOTAL_TIME:Number = 10,
            REPLAY_DISK_CACHE_FRAME_INTERVAL:Number = 10000,
            REPLAY_MEMORY_CACHE_FRAME_INTERVAL:Number = 700,
            REPLAY_SLIDESHOW_ACTIVE_SPEED:Number = 60,
            REPLAY_SLIDESHOW_FRAME_RATE:Number = 2, // 1/2초 = 0.5초마다 갱신
            REPLAY_SLIDESHOW_UPDATE_TIME:Number = 1000 / REPLAY_SLIDESHOW_FRAME_RATE;
        public var REPLAY_MAX_SPEED:Number = 0.0;

        public const KEY_REPEAT_START_DELAY:Number = 0.3,
            KEY_REPEAT_INTERVAL:Number = 0.06;

        public const STRING_TITLE_FOFOPAINT:String = " - FOFO PAINT";
        public const REPLAY_IMAGE_CAHCHE_COMPLETE:int = (1 << 0),
            REPLAY_IMAGE_CAHCHE_READY:int = (1 << 1),
            REPLAY_IMAGE_CAHCHE_PROCESSING:int = (1 << 2);

       
        public var    RCANVAS_WIDTH:Number = 600,
            RCANVAS_HEIGHT:Number = 390,
            RCANVAS_BG_COLOR:uint = 0xFFFFFF;
        public var TOTAL_FRAME:Number = 0; // rdata+file 프레임 전부 합친거
        // 파일 저장 경로

        // 키 누름 관련
        public var LAST_KEY:int = -1; // 마지막 누른거 여기다가 저장 반복호출되는 keydown 함수에서 한번만 호출되게 하는변수
        public const KEY_BUFFER:Array = []; // 정식 키 다운 눌러준 상태에서 다른 키가 눌러져 있으면 여기다가 저장
        public const COMMAND_CTRL:int = (1 << 0),
            COMMAND_SHIFT:int = (1 << 1),
            COMMAND_CTRL_SHIFT:int = (1 << 2);
        public const KEY:Object = {
                a: 65,
                b: 66,
                c: 67,
                d: 68,
                e: 69,
                f: 70,
                g: 71,
                h: 72,
                i: 73,
                j: 74,
                k: 75,
                l: 76,
                m: 77,
                n: 78,
                o: 79,
                p: 80,
                q: 81,
                r: 82,
                s: 83,
                t: 84,
                u: 85,
                v: 86,
                w: 87,
                x: 88,
                y: 89,
                z: 90,
                dot: 190,
                comma: 188,
                semicolon: 186,
                shift: 16,
                ctrl: 17,
                alt: 18,
                rightAlt: 21, // as에서는 한글모드
                rightCtrl: 25, // 한글 모드에서 오른쪽 컨트롤
                space: 32,
                backslash: 220,
                backspace: 8,
                enter: 13,
                esc: 27,
                del: 46,
                tab: 9,
                n0: 48,
                n1: 49,
                n2: 50,
                n3: 51,
                n4: 52,
                n5: 53,
                n6: 54,
                n7: 55,
                n8: 56,
                n8: 56,
                n9: 57,
                minus: 189,
                pgup: 33,
                pgdn: 34,
                home: 36,
                end: 35,
                left: 37,
                up: 38,
                right: 39,
                down: 40,
                f1: 112,
                f2: 113,
                f3: 114,
                f4: 115,
                f5: 116,
                f6: 117,
                f7: 118,
                f8: 119,
                f9: 120,
                f10: 121,
                f11: 122,
                f12: 123,
                window: 91
            };
        // 메뉴 요소
        public const toolBox:ToolMenuSet = new ToolMenuSet(),
            toolBox2:ToolMenuSet2 = new ToolMenuSet2(),
            fillPenBox:FillPenMenuSet = new FillPenMenuSet(),
            eyedropperLens:EyedropperLensSet = new EyedropperLensSet(),
            
            toolOptionsBox:ToolOptionsSet = new ToolOptionsSet(),
            numPadBox:NumPadSet = new NumPadSet();
        // about
        public const aboutBox:AboutWindowSet = new AboutWindowSet();
        public var isAboutBoxOpened:Boolean = false; // 어바웃 창 떴을때 킴
        // 초창기 개발 변수
        // 펜툴 줌툴 미러 에어브러시
        
            
            public var aaa:int = 0,
            mirrorCommandReady:Boolean = false, // 미러 커맨드를 넣어줄지 말지 결정
            // canvasZoomMultiplerList:Array = [0.125,0.25,0.5,0.75,1.0,1.50,2.0,3.0,4.0,6.0,8.0,12.0,16.0,24.0,32.0],
            nowTool:int = 1, // 현재 툴 번호
            lastTool:int = TOOL_NONE, // 툴백업
            isFillPenON:Boolean = false, // 채우기 펜 플래그
            isFillPenStarted:Boolean = false, // 채우기 펜 시작됨
            isSharpLineON:Boolean = false, // 0.5픽셀어긋나게 안하고 완전히 정확하게 할때씀
            isPenAirBrushON:Boolean = false,
            airBrushSizeDrawMode:int = 0,
            airBrushClipRectOffsetData:Array = [0, 4, 2, 2, 0, 0, 0, -2, -5, -5, -10, -16, -43];
        // 컨트롤 박스 투명도  todo : 임시임
        // 오른쪽 클릭 툴박스
        public var isToolBox2Showing:Boolean = false, // 툴박스가 오른쪽 클릭으로 켜졌을때 올려줌
            selectedToolViewBitmap:Bitmap = new Bitmap();
        // undo
        public var undoDataIndex:int = -1, // undo redo 상태 인덱스임
            isDeleteUndoDataPending:Boolean = false, // undo하고 나서 addundo가 되었을때 뒷부분 데이터 전부 날려주는 플래그
            canAddUndoData:Boolean = false; // 선을 그어줄대 선전체가 캔버스 바깥쪽에 있을수도 있으니까 이걸 판단해줌
        // lasso

        // 키 오래누름 관련 변수
        public var pressHoldCountDownTime:Number = 0.0,
            pressHoldFrameCount:int = 0;
        // 리플레이
        public var repFileTemp:File, // 파일을 저장하거나 불러올때 씀
            rFileStream:FileStream = new FileStream(), // 함수들을 왔다갔다 해야해서 전역으로 하나
            rCanvasAnchorPoint:Sprite = new Sprite(), // 회전 스프라이트 부모
            rCanvasPanel:Sprite = new Sprite(),
            rCanvasDrawLayer:Sprite = new Sprite(),
            rCanvasDrawShape:Shape = new Shape(),
            rCanvasCompleteAnchorPoint:Sprite = new Sprite(),
            rCanvasLayer1BitmapData:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0),
            rCanvasLayer2BitmapData:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0),
            rCanvasDrawLayerBitmapData:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0),
            rCanvasLayer1Bitmap:Bitmap = new Bitmap(rCanvasLayer1BitmapData, "auto", true),
            rCanvasLayer2Bitmap:Bitmap = new Bitmap(),
            rCanvasCompleteBitmap:Bitmap = new Bitmap(new BitmapData(1, 1, false, 0), "auto", true),
            rCanvasDrawLayerBitmap:Bitmap = new Bitmap(rCanvasDrawLayerBitmapData, "auto", true),
            rReplayFOFOCursor:FOFOCursor = new FOFOCursor(), // 재생할때 틀어주는 작은 마우스
            rCanvasDrawLayerClipRectLegacy:Rectangle = new Rectangle(), // 갱신된 부분만 그려주는 거 오래된 버전 지원때문에 남겨둠
            rCanvasDrawLayerClipRect:Rectangle = new Rectangle(), // 갱신된 부분만 그려주는 거 이게 새거임
            updatePrograssBarStartTime:int = 0, // 리플레이 시작 시간저장 update prograss bar에서 프레임 오차 수정할때 참고하는 변수
            isReplayStarted:Boolean = false, // 리플레이 시작버튼 여러번 누르는거 방지
            isReplayFinished:Boolean = true, // 리플레이가 자연히 끝났을때 올려주는 플래그 가장 처음에 캔버스 싹쓸이 하기 위해서 넣어줌.
            isReplayFinishedWithFiwWindow:Boolean = false, // 리플레이가 follow cursor옵션으로 캔버스 작게 축소되서 끝났을때
            isReplayModeON:Boolean = false, // 이건 모드 자체 껐다 켰다
            isReplayRepeatON:Boolean = true, // 리플레이 반복 켜기 끄기
            rDataBuffer:Array = [], // draw layer에서 그려준 데이터를 이쪽으로 다모아줌
            rData:Array = [], // rDataBuffer가 이쪽으로 이동되고 undo image data갯수에 똑같이맞추어줌
            rDataFrame:Array = [], // rdata안에 몇프레임이 들어있는지 저장
            rDataReadFlag:Boolean = true, // rData읽을때는 true, r file 읽을때는 false
            rFileLastBytePosition:Number = 0, // fs position 저장
            rFileCutBytePosition:Number = 0, // super undo에서 파일 잘라줄때 필요함
            rDataIndex:int = 0, // rData에서만씀 rData 스크로크 뭉치 인덱스
            rDataStartIndex:int = 0, // 리플레이에서 프레임 스캡을 앞부분으로 해줄때 rdata를 읽는 부분이면 현재 undoindex부분 부터 읽게 인덱스를 올려줌
            rLastLayer2Selcted:Boolean = false, // 리플레이 실행할때 이걸로 비교해서 캔버스 스왑해줌
            rLastCanvasBGColor:uint = RCANVAS_BG_COLOR, // load replay에서 씀
            rReplaySpeedMultipler:Number = 1, // 리플레이 속도 for루프로 2번씩혹은 3번씩 읽히게 만듬
            rAirBrushSize:int = 0, // 레거시지원 변수
            rAirBrushSize2:int = 0, // 새로운거
            rNowFrame:Number = 0, // dodraw에서 현재까지 플레이된 프레임수 누적, jump frame이 가동됐을때 프레임 누적갯수를 세서 썸네일 이미지 만들어줌
            rPrevFrame:Number = 0, // jump one frame 에서 이전 프레임 탐색할때 이 프레임으로 탐색해줌 tickdraw에서 data 끝의 프레임을 저장함
            rFirstImageLayer1BitmapData:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0),
            rFirstImageLayer2BitmapData:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0),
            rFirstImageBGColor:uint = CanvasController.CANVAS_BG_COLOR,
            rMirrorON:Boolean = false, // 대칭 켜지면 올려줌
            rCanvasZoomMultiplier:Number = 1.0, // 리플레이 줌
            rLastCanvasZoomMultiplier:Number = 1.0, // 리플레이에서 수동줌하면 여기다가 저장해줌
            rCanvasZoomIndex:int = 4,
            isReplayCanvasFitToWindow:Boolean = false, // 리플레이에서 오른쪽 클릭해서 창 크기에 맞췄을때 올려줌 startreplay될때 줌 1.0으로 리셋 못시키게함
            rJumpImageIndexLast:int = -2, // 썸네일 인덱스 바뀌면 여기다 저장
            rJumpImageNowFrameLast:Number = -1,
            rCachedImageLastIndex:int = -2, // 마지막에 그려준 캐쉬 이미지 번호를 저장
            rTempCachedLastImageIndex:int = -2, // 더 잘게 쪼개준 이미지 인덱스 바뀌면 여기다 저장
            rJumpImageFrameData:Array = [0], // 스킵이미지 저장될때 r file frame sum을 저장해줌 처음에 rfirstimage라서 0번 추가해줌
            rReplayImageCacheState:int = REPLAY_IMAGE_CAHCHE_COMPLETE,
            rReplayRestartTimerCount:uint = 0, // 리스타트 타이머
            rSeekbarTextUpdateTime:int = 0, // 프레임 바 딜레이
            isReplaySlideShowMode:Boolean = false, // doDrawSlowEvent가 켜지면 올려줌
            rFrameTempCachedImages:Array = [], // 이전 탐색 프레임 빠르게 하기 위해서 jumpimage구간에서 더 잘게 이미지를 나누어주고 정보를여가다가 저장함
            lastReplayTimeBoxYPos:Number = 0; // 리플레이 재생해줄때 WorkspaceView.topbar 사라지게 할때 원래 위치 저장해서 끝나면 이 위치로 복원해줌
        // 캡쳐모드


        // 윈도우 크기변수
        // 툴 클로져 자주쓰는거는 클로져로 메모리에 미리 올려둬서 성능향상하려고 한건데 모르겠음
        public const realWorkingTimer:Object = cRealWorkingTimer(),
            dottedLine:Object = cDottedLine(), // 순서 먼저 와야함
            dotTool:Function = cDrawDot(),
            lineTool:Function = cLineTool(),
            handTool:Function = cHandTool(),
            rotateTool:Function = cCanvasRotateTool(),
            zoomTool:Function = cZoomTool(),
            moveTool:Function = cMoveTool(),
            eyeDropperTool:Function = cEyeDropperTool(),
            fillPenTool:Object = cFillPenTool(),
            drawDone:Function = cDrawDone(),
            drawReplayByCommand:Object = cDrawReplayDataCommands(),
            drawCanvasFromReplayData:Function = cDrawReplayData(),
            rFollowMouse:Object = cReplayFollowMouse(),
            updatePenSizeCursor:Function = cUpdatePenSizeCursor(),
            undoManager:Object = cAddUndoData(),
            penCursorManager:Object = cPenCursorUpdater(),
            replayHideCursor:Object = cReplayHideCursor(),
            resizeCanvas:Object = CanvasController.cResizeCanvas();
        // 딥언도
        public var isDeepUndoEnabled:Boolean = false,
            lastDeepUndoEnabledFlag:Boolean = false, // 리플레이 켜줄때 딥 플래그를 꺼줘서 여기다가 미리 저장해둠
            lastReplayFrameOnDeepUndoStart:Number = -1; // 리플레이 켜줄때 rNowFrame이 변하니까 그전에 백업해주고 꺼주고 다시 undo실행할때 이 프레임 기준으로 하려고
        // 기타
        public var isAppClosing:Boolean = false, // 앱종료할때 올려줌 창 최대화 되어있는 상태를 원래대로 하고 window resize이벤트에서 마지막에 종료 호출
            lastWindowDeactivateTime:int = 0, // 윈도우 비활성화된 시간 저장, 알탭 반복 시 save all data 과다 호출 방지
            lastEraserPosButton:SimpleButton = null, // 지우개 툴이 이동한 버튼 저장; 복원용
            isLayerCheckKeyPressed:Boolean = false,
            isDrawModeInputEventsAdded:Boolean = false,
            isReplayModeInputEventsAdded:Boolean = false;
            
        public function Main():void
        {
            _instance = this;
            if (this.stage)
            {
                initializeStage();
            }
            else
            {
                this.addEventListener(Event.ADDED_TO_STAGE, onStageAdded);
            }
        }
        public function onStageAdded(e:Event):void
        {
            this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdded);
            initializeStage();
        }
        public function initializeModule():void
        {
            //나중에 file load 클래스 초기화로 옮겨야함
            registerClassAlias("AppState", AppStateManager);
            //main ui가 호출되기전에 이것부터 stage 연결시켜주어야함 그냥 상단에 고정
            HintBoxSet.setMainStage(this.stage);

            AppUpdater.setMainInstance(this);
            BackgroundWorkerCoordinator.setMainInstance(this);
            CanvasGridOverlay.setMainInstance(this);
            CaptureController.setMainInstance(this);
            CanvasController.setMainInstance(this);
            ClipboardManager.setMainInstance(this);
            ColorPickerController.setMainInstance(this);
            DragInteraction.setMainInstance(this);
            FileManager.setMainInstance(this);
            ImageViewWindow.setMainInstance(this);
            MainUI.setMainInstance(this);
            MainUIController.setMainInstance(this);
            PaletteController.setMainInstance(this);
            ReferenceLayerController.setMainInstance(this);
            SidebarController.setMainInstance(this);
            Utils.setMainInstance(this);
            
            PenTool.setMainInstance(this);
            LassoTool.setMainInstance(this);
        }

        public function initializeStage():void
        {
            initializeModule();
            MainUIController.updateWindowTitle();
            MainUIController.markWindowTitleAsDirty();
            initializeStageSettings();
            CanvasController.initializeCanvas();
            initializeReplayCanvas();
            MainUI.initializeAppMenus();
            MainUIController.initializeResizeButtonFamily();
            CaptureController.initializeCaptureModeTransparentBG();
            BackgroundWorkerCoordinator.initializeWorker();
            loadAppState();
            // 입력 이벤트는 loadappdstate보다느려야함
            addGlobalEvents();
            addGlobalEventsChild();
            addInputEventsDrawMode();
            initializeReplayDataFile();
            CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
            realWorkingTimer.start();
            AppUpdater.checkUpdate();
            tryDisableIME();
            ColorPickerController.colorPickerBox.setActiveColorPreset(0);
            MainUI.mouseHint.updateBGColor();
            SidebarController.moveSideBar("left"); // 컨트롤 박스 크기가 set pentool 이후에 제대로 바뀜 원인 모름
            stage.addChild(SidebarController.fofo);
            stage.setChildIndex(SidebarController.fofo, stage.getChildIndex(SidebarController.sideBar) + (stage.getChildIndex(SidebarController.fofo) < stage.getChildIndex(SidebarController.sideBar) ? 0 : 1));
            HintStrings.setMainInstance(this);
            MainUI.bottomHint.visible = true;
            selectPenTool();
            ClipboardManager.checkCanUseClipBoardButton();
        }
        // function
        public function updateSelectedToolViewBoxPos():void
        {
            const viewportRect:Rectangle = MainUIController.getViewportRect();
            selectedToolViewBitmap.x = viewportRect.x + viewportRect.width / 2 - selectedToolViewBitmap.width / 2;
            selectedToolViewBitmap.y = viewportRect.y + 20 * Global.getUIScale();
        }
        public function getToolButtonFromToolIndex(toolIndex:*):SimpleButton
        {
            switch (toolIndex)
            {
                case TOOL_PEN:
                    return toolBox.toolPen;
                case TOOL_FILLPEN:
                    return toolBox.toolFillPen;
                case TOOL_ERASER:
                    return toolBox.toolEraser;
                case TOOL_EYEDROPPER:
                    return toolBox.toolEyedropper;
                case TOOL_LASSO:
                    return toolBox.toolLasso;
                case TOOL_MOVE:
                    return toolBox.toolMove;
                case TOOL_LINE:
                    return toolBox.toolLine;
                case TOOL_ZOOM:
                    return toolBox.toolZoomIn;
                case TOOL_ROTATE:
                    return toolBox.toolRotate;
                case TOOL_HAND:
                    return toolBox.toolHand;
                case TOOL_UNDO:
                    return toolBox.toolUndo;
                case TOOL_REDO:
                    return toolBox.toolRedo;
                case TOOL_MIRROR:
                    return toolBox.toolMirror;
            }
            return null;
        }
        public function showNowToolIconToCursorTemp(toolIndex:int):void
        {
            if (SidebarController.isQuickSidebarActive)
            {
                return;
            }
            const toolButton:SimpleButton = getToolButtonFromToolIndex(toolIndex);
            if (toolButton === null)
            {
                return;
            }
            selectedToolViewBitmap.bitmapData = toolBox.getToolSelectViewBmpd(toolIndex, toolButton);
            updateSelectedToolViewBoxPos();
            startAlphaFadeOut(selectedToolViewBitmap, 1.0, 1.0);
        }
        public function isGeneratingCacheImages():Boolean
        {
            return rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_PROCESSING;
        }





        public function startScratchPadResetTimer(target:DisplayObject):void
        {
            FOFOTimer.addByName("clearScratchPadTimer", 0.4, false, function ():void
                {
                    startPressHoldKey(target, "Clearing scratch pad..", null, ColorPickerController.colorPickerBox.scratchPad.clearPad, null);
                });
        }

        public function startPressHoldKey(button:DisplayObject, hintStr:String, readyFunc:Function, okFunc:Function, cancelFunc:Function):void
        {
            if (!FOFOTimer.hasTimer("pressholdtimer"))
            {
                var keyBufferLenSave:uint = getPressedKeyCount();
                var mouseClickONSave:Boolean = CanvasController.isMouseClicked;
                var rightMouseClickONSave:Boolean = CanvasController.isRightMouseClicked;
                const countDownTime:Number = 3;
                const countDownTimeNow:Number = Math.ceil((stage.frameRate * 2.5) / countDownTime);
                pressHoldCountDownTime = countDownTime;
                pressHoldFrameCount = 0;
                if (readyFunc !== null)
                {
                    if (readyFunc() === true)
                    {
                        return;
                    }
                }
                function cancelHoldingKey():void
                {
                    pressHoldFrameCount = 0;
                    pressHoldCountDownTime = countDownTime;
                    MainUI.hideMouseHint();
                }
                if (hintStr !== "")
                {
                    MainUI.showMouseHint(hintStr + " " + pressHoldCountDownTime);
                }
                FOFOTimer.addByName("pressholdtimer", 0.0, true, function ():Boolean
                    {
                        if (CanvasController.isMouseClicked !== mouseClickONSave
                                || CanvasController.isRightMouseClicked !== rightMouseClickONSave
                                || keyBufferLenSave !== getPressedKeyCount()
                                || (button && button.hitTestPoint(stage.mouseX, stage.mouseY) === false))
                        {
                            if (cancelFunc !== null)
                            {
                                cancelFunc();
                            }
                            cancelHoldingKey();
                            return false;
                        }
                        pressHoldFrameCount++;
                        if (pressHoldFrameCount >= countDownTimeNow)
                        {
                            pressHoldFrameCount = 0;
                            pressHoldCountDownTime--;
                        }
                        MainUI.showMouseHint(hintStr + " " + pressHoldCountDownTime);
                        if (pressHoldCountDownTime <= 0)
                        {
                            cancelHoldingKey();
                            okFunc();
                            return false;
                        }
                        return true;
                    });
            }
        }









        public function setRcursorRotation(newAngle:Number):void
        {
            rReplayFOFOCursor.rotation = -newAngle;
        }


        public function addInputEventsDrawModeOrReplayMode():void
        {
            if (isReplayModeON)
            {
                addInputEventsReplayMode();
            }
            else
            {
                addInputEventsDrawMode();
            }
        }
        public function getClipRectOffsetAirBrush(size:int):Number
        {
            const len:uint = PenTool.penSizeList.length;
            for (var i:uint = 1;i < len;i++)
            {
                if (PenTool.penSizeList[i] === size)
                {
                    return size + airBrushClipRectOffsetData[i];
                }
            }
            return 0;
        }


        public function updateRCanvasDrawLayerCliprect2():void
        {
            rCanvasDrawLayerClipRect = rCanvasDrawLayerClipRect.union(rCanvasDrawShape.getBounds(rCanvasPanel));
        }




        public function getCanvasLayerSwappedHintString():String
        {
            return "Layers has been swapped " + ((CanvasController.isLayerSwapped) ? "1 / 2" : "2 / 1");
        }


        public function getReplayFileNameFromPath(path:String):String
        {
            return path.substr(0, path.lastIndexOf(".png")) + ".2020";
        }

        // 드로우 모드와 리플레이 모드 캔버스 미러가 다를경우 undo 적용 이후에 mirror커맨드 넣어주도록 함
        public function checkMirrorCanvasReplayMirror():void
        {
            if (CanvasController.isCanvasMirrored !== rMirrorON)
            {
                mirrorCommandReady = true;
                mirrorDraw();
                CanvasGridOverlay.updateGridMirror(CanvasController.isCanvasMirrored);
                mirrorRCursorPos();
            }
            else if (mirrorCommandReady)
            {
                mirrorCommandReady = false;
            }
        }

        public function mirrorRCursorPos():void
        {
            const p:Point = drawReplayByCommand.getRCursorPos();
            const half:Number = CanvasController.CANVAS_WIDTH / 2;
            const curcorX:Number = rReplayFOFOCursor.x + (half - p.x) * 2;
            rReplayFOFOCursor.x = curcorX;
            drawReplayByCommand.setRCursorPos(curcorX, p.y);
        }
        public function startAlphaFadeOut(target:DisplayObject, startAlpha:Number = 1.0, waitDuration:Number = 0.0):void
        {
            target.alpha = startAlpha;
            target.visible = true;
            const startTime:int = getTimer() + waitDuration * 1000;
            FOFOTimer.addByName("alphaFadeOutTimer_" + target.name, 0.0, true, function ():Boolean
                {
                    if (getTimer() < startTime)
                    {
                        return true;
                    }
                    if (target.visible === false)
                    {
                        return false;
                    }
                    target.alpha -= 0.1;
                    if (target.alpha < 0.0)
                    {
                        target.visible = false;
                        target.alpha = 1.0;
                        return false;
                    }
                    return true;
                });
        }
        public function showRCursorOnUndo(undoIndex:int):void
        {
            if (undoIndex < 0)
            {
                if (drawReplayByCommand.hasRCursorFirstPos())
                {
                    const p:Point = drawReplayByCommand.getFirstRCursorPos();
                    drawReplayByCommand.setRCursorPos(p.x, p.y); // 커서 위치도 업에이트 해줘야함 대칭해줄띠 getRcursor로 하기 때문에
                    drawReplayByCommand.updateRCursorPosToFirst();
                }
                else
                {
                    rReplayFOFOCursor.visible = false;
                    MainUI.hideMouseHint();
                }
            }
            else
            {
                drawReplayByCommand.updateRCursorPos();
            }
        }
        public function isLayer2SelectedReplayMode():Boolean
        {
            return rCanvasPanel.getChildIndex(rCanvasDrawLayer) < rCanvasPanel.getChildIndex(rCanvasLayer1Bitmap);
        }




        public function toggleLayerCaptureMode(layer:int):void
        {
            MainUI.topBar.capClipBoard.alpha = 1.0;
            const replayMode:Boolean = isReplayModeON;
            var bitmap:Bitmap = replayMode
                ? (layer == 1 ? rCanvasLayer1Bitmap : rCanvasLayer2Bitmap)
                : (layer == 1 ? CanvasController.canvasLayer1Bitmap : CanvasController.canvasLayer2Bitmap);
            var button:DisplayObject = (layer == 1)
                ? MainUI.topBar.capLayer1VisibleButton
                : MainUI.topBar.capLayer2VisibleButton;
            var otherButton:DisplayObject = (layer == 1)
                ? MainUI.topBar.capLayer2VisibleButton
                : MainUI.topBar.capLayer1VisibleButton;
            if (bitmap.visible)
            {
                bitmap.visible = false;
                button.alpha = Global.OFFALPHA;
                if (replayMode)
                {
                    if ((layer == 1 && !isLayer2SelectedReplayMode())
                            || (layer == 2 && isLayer2SelectedReplayMode()))
                    {
                        rCanvasDrawLayer.visible = false;
                    }
                }
                if (otherButton.alpha < 1.0)
                {
                    toggleLayerCaptureMode((layer == 1) ? 2 : 1);
                }
            }
            else
            {
                bitmap.visible = true;
                button.alpha = 1.0;
                if (replayMode)
                {
                    if ((layer == 1 && !isLayer2SelectedReplayMode())
                            || (layer == 2 && isLayer2SelectedReplayMode()))
                    {
                        rCanvasDrawLayer.visible = true;
                    }
                }
            }
            CaptureController.captureAreaManager.updateDrawArea();
        }
        public function addUndoBGColorData(color:uint):void
        {
            if (hasLastRDataCommand("bgColor"))
            {
                rDataBuffer.push(["bgColor", color]);
                updateLastRDataCommand("bgColor");
                undoManager.addContinue();
            }
            else
            {
                if (isDeepUndoEnabled)
                {
                    applyDeepUndo();
                }
                rDataBuffer.push(["bgColor", color]);
                undoManager.addNew();
            }
        }
        public function updateLastRDataCommand(command:String):void
        {
            if (rData.length === 0)
                return;
            const arr:Array = rData[rData.length - 1];
            if (arr.length === 1)
            {
                rData[rData.length - 1] = rDataBuffer.concat();
                rDataBuffer = [];
            }
            else
            {
                for (var i:uint = 0;i < arr.length;i++)
                {
                    if (command === arr[i][0])
                    {
                        // rdata버퍼가 배열이기 때문에 concat을 하면 배열안에 배열이 있어서 0번만 반환해줌
                        // buffer.concat -> [["data",11]] //이런식으로 반환이됨
                        arr[i] = rDataBuffer[0].concat();
                        rDataBuffer = [];
                        break;
                    }
                }
            }
            rDataFrame[rDataFrame.length - 1] = rData[rData.length - 1].length;
        }
        public function deleteLastRDataCommand(command:String):void
        {
            if (rData.length === 0)
            {
                return;
            }
            const index:int = undoDataIndex;
            if (rData[index].length === 1)
            {
                rData.splice(index);
                rDataFrame.splice(index);
            }
            else
            {
                const len:uint = rData[index].length;
                for (var i:uint = 0;i < len;i++)
                {
                    if (command === rData[index][i][0])
                    {
                        rData[index].splice(i, 1);
                        --i;
                    }
                }
                rData.splice(index + 1);
                rDataFrame.splice(index + 1);
            }
            isDeleteUndoDataPending = false;
            undoManager.updateLastRDataMirror();
            undoDataIndex = rData.length - 1;
        }
        public function hasLastRDataCommand(command:String):Boolean
        {
            const index:int = undoDataIndex;
            if (rData.length > 0 && index >= 0)
            {
                const len:uint = rData[index].length;
                for (var i:uint = 0;i < len;i++)
                {
                    if (command === rData[index][i][0])
                    {
                        return true;
                    }
                }
            }
            return false;
        }



        public function cDottedLine():Object
        {
            const lastDotPos:Point = new Point(0, 0);
            var lastLineLength:Number = 0;
            var dotLineLength:Number = 5;
            var subDotLength:Number;
            var startPos:Point = new Point(0, 0);
            var lastInterpPos:Point = new Point(0, 0);
            var lineSize:Number = 1;
            var dotLineColor:uint = 0;
            var graphics:Graphics;
            function setLineScale(zoomed:Number):void
            {
                lineSize = 1 / zoomed;
                dotLineLength = 5 / zoomed;
            }
            function toggleLineColor(from:int):uint
            {
                if (dotLineColor === 0)
                {
                    dotLineColor = 0xFFFFFF;
                }
                else
                {
                    dotLineColor = 0;
                }
                return dotLineColor;
            }
            function moveTo(g:Graphics, x:Number, y:Number):void
            {
                graphics = g;
                dotLineColor = 0;
                subDotLength = dotLineLength;
                startPos.setTo(x, y);
                lastDotPos.setTo(x, y);
                lastInterpPos.setTo(x, y);
                graphics.lineStyle(lineSize, dotLineColor, 1.0, false, "normal", "none");
                graphics.moveTo(x, y);
            }
            function lineTo(x:Number, y:Number, closeLine:Boolean = false):void
            {
                const nowPos:Point = new Point(x, y);
                var dist:Number = Point.distance(lastDotPos, nowPos);
                var interpPoint:Point = new Point(lastDotPos.x, lastDotPos.y);
                var ratio:Number;
                subDotLength -= dist;
                while (subDotLength < 0)
                {
                    ratio = (dist - subDotLength) / dist - 1.0;
                    interpPoint = Point.interpolate(interpPoint, nowPos, ratio);
                    toggleLineColor(1);
                    graphics.lineStyle(lineSize, dotLineColor, 1.0, false, "normal", "none");
                    graphics.moveTo(lastInterpPos.x, lastInterpPos.y);
                    graphics.lineTo(interpPoint.x, interpPoint.y);
                    lastInterpPos.setTo(interpPoint.x, interpPoint.y);
                    dist = Point.distance(nowPos, interpPoint);
                    subDotLength += dotLineLength;
                }
                if (closeLine)
                {
                    graphics.lineTo(startPos.x, startPos.y);
                }
                lastDotPos.setTo(x, y);
            }
            return {
                    lineTo: lineTo,
                    moveTo: moveTo,
                    setLineScale: setLineScale
                };
        }
        public function cReplayHideCursor():Object
        {
            var isMouseHided:Boolean = false;
            var count:int = 0;
            const pos:Point = new Point(0, 0);
            const frameRate:Number = stage.frameRate;
            function isMouseMoved():Boolean
            {
                return pos.x !== stage.mouseX || pos.y !== stage.mouseY || CanvasController.isMouseClicked || CanvasController.isRightMouseClicked;
            }
            function updateMousePos():void
            {
                pos.setTo(stage.mouseX, stage.mouseY);
            }
            function show():void
            {
                Mouse.show();
                isMouseHided = false;
                count = 0;
            }
            function check():void
            {
                if (isMouseHided)
                {
                    if (isMouseMoved())
                    {
                        count = 0;
                        show();
                    }
                }
                else
                {
                    if (count > frameRate)
                    {
                        count = frameRate;
                        if (!MainUI.isHighlightBoxVisible())
                        {
                            Mouse.hide();
                            MainUI.hideBottomHint();
                            isMouseHided = true;
                            updateMousePos();
                        }
                    }
                    else
                    {
                        count++;
                    }
                    if (isMouseMoved())
                    {
                        count = 0;
                    }
                    updateMousePos();
                }
            }
            return {
                    check: check,
                    show: show
                };
        }
        public function updateLastKey(key:int):void
        {
            LAST_KEY = getLastKey();
        }
        public function resetLastKey():void
        {
            LAST_KEY = -1;
        }
        public function isLastKey(key:uint):Boolean
        {
            return LAST_KEY === key;
        }
        public function isSelectedToolPenOrLine():Boolean
        {
            return nowTool === TOOL_PEN || nowTool === TOOL_LINE;
        }
        public function isSelectedTool(tool:int):Boolean
        {
            return nowTool === tool;
        }
        public function setSelectedTool(tool:int):void
        {
            nowTool = tool;
        }
        public function resetLastTool():void
        {
            lastTool = TOOL_NONE;
        }
        public function isLastTool(tool:int):Boolean
        {
            return lastTool === tool;
        }
        public function setLastTool(tool:int):void
        {
            lastTool = tool;
        }
        public function updateLastTool():void
        {
            if (lastTool === TOOL_NONE)
            {
                lastTool = nowTool;
            }
        }
        public function startKeyRepeatStopTimerOnMouseLeave(target:DisplayObject):void
        {
            FOFOTimer.addByName("checkKeyRepeatStop", 0.0, true, function ():Boolean
                {
                    if (!target.hitTestPoint(stage.mouseX, stage.mouseY))
                    {
                        removeKeyRepeatEvents(null);
                        return false;
                    }
                    return true;
                });
        }
        public function startKeyRepeat(firstCall:Boolean, func:Function, ...args):Boolean
        {
            if (FOFOTimer.hasTimer("keyHoldWaitTimer") || FOFOTimer.hasTimer("keyHoldRepeatTimer"))
            {
                return false;
            }
            FOFOTimer.addByName("keyHoldWaitTimer", KEY_REPEAT_START_DELAY, false,
                    function ():void
                    {
                        func.apply(Main, args);
                        FOFOTimer.addByName("keyHoldRepeatTimer", KEY_REPEAT_INTERVAL, true, func, args);
                    });
            addKeyRepeatEvents();
            if (firstCall)
            {
                func.apply(Main, args);
            }
            return true;
        }
        public function checkPenOptionsKeyDown(keyCode:uint):Boolean
        {
            const secondKey:int = getSecondPressedKey();
            if (secondKey === KEY.n3 || secondKey === KEY.n8)
            {
                if (toolOptionsBox.sharpLineButtonWrapper.alpha === 1.0)
                {
                    toggleSharpLineByShortcut();
                }
                return true;
            }
            else if (secondKey === KEY.n4 || secondKey === KEY.n7)
            {
                if (isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILLPEN))
                {
                    togglePenAirBrushButtonShortCut();
                    return true;
                }
                else if (isSelectedTool(TOOL_ERASER))
                {
                    toggleEraseAirBrushButtonShortCut();
                    return true;
                }
            }
            return false;
        }
        public function isPressingControl():Boolean
        {
            return getCommandKey() === COMMAND_CTRL;
        }
        public function isPressingShift():Boolean
        {
            return getCommandKey() === COMMAND_SHIFT;
        }
        public function isPressingControlShift():Boolean
        {
            return getCommandKey() === COMMAND_CTRL_SHIFT;
        }
        public function getCommandKey():int
        {
            const first:uint = getFirstPressedKey();
            const second:uint = getSecondPressedKey();
            if ((second === KEY.shift && (first === KEY.ctrl || first === KEY.rightCtrl))
                    || (first === KEY.shift && (second === KEY.ctrl || second === KEY.rightCtrl)))
            {
                return COMMAND_CTRL_SHIFT;
            }
            if (first === KEY.shift)
            {
                return COMMAND_SHIFT;
            }
            if (first === KEY.ctrl || first === KEY.rightCtrl)
            {
                return COMMAND_CTRL;
            }
            return 0;
        }

        public function isCursorInDrawArea():Boolean
        {
            return !(MainUI.topBar.hitTestPoint(stage.mouseX, stage.mouseY)
                    || (SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(stage.mouseX, stage.mouseY))
                    || (MainUI.seekBarBox.visible && MainUI.seekBarBox.hitTestPoint(stage.mouseX, stage.mouseY)));
        }
        public function initializeStageSettings():void
        {
            stage.vsyncEnabled = true;
            stage.scaleMode = StageScaleMode.NO_SCALE; // 창크기 상관없이 스테이지 크기 고정
            stage.align = StageAlign.TOP_LEFT;
            stage.quality = StageQuality.BEST;
            stage.tabChildren = false;
            NativeApplication.nativeApplication.autoExit = true;
        }


        public function onMouseDownStage(e:MouseEvent):void
        {
            checkInvalidKey();
            CanvasController.isMouseClicked = true;
            MainUI.hideBottomHint();
        }

        public function onMouseUpStage(e:MouseEvent):void
        {
            checkInvalidKey();
            const mx:Number = stage.mouseX;
            const my:Number = stage.mouseY;
            CanvasController.isMouseClicked = false;
            if (!CanvasController.isMouseClicked && CanvasController.isRightMouseClicked)
            {
                CanvasController.isMouseDragging = false;
            }
        }

        public function onRightMouseUpStage(e:MouseEvent):void
        {
            checkInvalidKey();
            const mx:Number = stage.mouseX;
            const my:Number = stage.mouseY;
            CanvasController.isRightMouseClicked = false;
            if (!CanvasController.isMouseClicked && CanvasController.isRightMouseClicked)
            {
                CanvasController.isMouseDragging = false;
            }
        }

        public function onRightMouseDownStage(e:MouseEvent):void
        {
            checkInvalidKey();
            CanvasController.isRightMouseClicked = true;
        }
        public function onMiddleMouseDownStage(e:MouseEvent):void
        {
            if (CaptureController.isCaptureModeON)
                return;
            if (FOFOTimer.hasTimer("toolTipTempONTimer"))
            {
                MainUI.hideMouseHint();
            }
            if (LassoTool.isLassoToolStarted)
            {
                LassoTool.lassoMenuBox.visible = false;
                LassoTool.isLassoMenuHiddenTemp = true;
            }
            handTool(isReplayModeON, true);
            showNowToolIconToCursorTemp(TOOL_HAND);
        }

        public function onMouseLeaveStage(e:Event):void
        {
            CanvasController.isMouseClicked = false;
            CanvasController.isRightMouseClicked = false;
            CanvasController.isMouseDragging = false;
            CanvasController.penSizePreviewCursor.visible = false;
        }

                public function onMouseWheelStage(e:MouseEvent):void
        {
            if (CanvasController.isMouseClicked || CanvasController.isRightMouseClicked || CanvasController.isMouseDragging
                    || MainUIController.isPopUpWindowOpened()
                    || CaptureController.isCaptureModeON || !SidebarController.isQuickSidebarActive && isKeyPressed() || getCommandKey() !== 0)
                    {
                return;

                    }

            if (!FOFOTimer.hasTimer("wheelZoomTimer"))
            {
                FOFOTimer.addByName("wheelZoomTimer", 0.07, false, function ():void
                    {
                        if (SidebarController.isMouseCursorInSideBar())
                        {
                            if (SidebarController.sideBarScrollBar.visible === true)
                            {
                                if (e.delta > 0)
                                {
                                    SidebarController.startScrollSidebarByMouseWheel(40);
                                }
                                else
                                {
                                    SidebarController.startScrollSidebarByMouseWheel(-40);
                                }
                            }
                        }
                        else if (!isReplayModeON && isCursorInDrawArea())
                        {
                            if (e.delta > 0)
                            {
                                CanvasController.zoomInCanvas(true, false);
                                MainUI.showMouseHintTemp(Math.floor(CanvasController.canvasZoomMultipler * 100) + "%");
                            }
                            else
                            {
                                CanvasController.zoomInCanvas(false, false);
                                MainUI.showMouseHintTemp(Math.floor(CanvasController.canvasZoomMultipler * 100) + "%");
                            }
                        }
                    });
            }
        }


        public function resetApp():void
        {
            stage.nativeWindow.removeEventListener(Event.CLOSING, FileManager.onWindowClosingEvent);
            stage.nativeWindow.removeEventListener(Event.DEACTIVATE, FileManager.onWindowDeactivate);
            const files:File = File.applicationStorageDirectory;
            files.deleteDirectory(true);
        }



        public function cFillPenTool():Object
        {
            const lastMousePos:Point = new Point(0, 0);
            var canvasSizeRect:Rectangle = new Rectangle();
            var command:Vector.<int>;
            var data:Vector.<Number>;
            var xColor:uint;
            var xAlpha:Number;
            var commandUndoIndexArr:Array = [];
            var mouseMoveCount:int;
            var afterKeyUpOK:Boolean;
            var pos05Offset:Number;
            var xBlendMode:String;
            var clickedButton:String;
            var canvasDrawZIndexSave:int = 0;
            const lastPosOnMouseMove:Point = new Point();
            var lastFillPenBoxUsedButton:SimpleButton;
            var turnOffFillPenPreviewCount:int = 0;
            var isStartedFromShortCut:Boolean = false;
            function updateLastFillPenBoxButtonUsed(target:SimpleButton):void
            {
                lastFillPenBoxUsedButton = target;
            }
            function startFillColorUpdateTimer():void
            {
                showFillColor();
                FOFOTimer.addByName("fillColorUpdateTimer", 0.1, true, function ():Boolean
                    {
                        const newXcolor:uint = (PenTool.isTransparentPenColor) ? CanvasController.CANVAS_BG_COLOR : ColorPickerController.colorPickerBox.rgbInfoBGColor;
                        const newXAlpha:Number = PenTool.penAlpha;
                        const newXBlendMode:String = (PenTool.isTransparentPenColor) ? "erase" : null;
                        if (newXcolor !== xColor)
                        {
                            xColor = newXcolor;
                            xAlpha = newXAlpha;
                            xBlendMode = newXBlendMode;
                            showFillColor();
                        }
                        if (newXAlpha !== xAlpha)
                        {
                            xAlpha = newXAlpha;
                            showFillColor();
                        }
                        if (newXBlendMode !== xBlendMode)
                        {
                            xBlendMode = newXBlendMode;
                            showFillColor();
                        }
                        if (!SidebarController.sideBar.visible)
                        {
                            showDottedLine();
                            return false;
                        }
                        else if (!CanvasController.isMouseClicked && !SidebarController.sideBar.hitTestPoint(stage.mouseX, stage.mouseY))
                        {
                            turnOffFillPenPreviewCount--;
                            if (turnOffFillPenPreviewCount <= 0)
                            {
                                turnOffFillPenPreviewCount = 0;
                                showDottedLine();
                                return false;
                            }
                        }
                        return true;
                    });
            }
            function onMouseOverFillPenHint(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if (!target)
                    return;
                const targetName:String = target.name;
                if (!FOFOTimer.hasTimer("fillColorUpdateTimer") && SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(stage.mouseX, stage.mouseY))
                {
                    startFillColorUpdateTimer();
                }
                if (targetName === "fillPenOK")
                    fillPenBox.hint("OK [q, o key up]");
                if (targetName === "fillPenCancel")
                    fillPenBox.hint("Cancel\n[esc, backspace]");
                else if (targetName === "fillPenUndo")
                    fillPenBox.hint("Undo [w, z, i, .]");
                else if (targetName === "fillPenSidebar")
                    fillPenBox.hint("[6, s+d, j+k]");
            }
            function checkFillPenUndoReady():Boolean
            {
                if (canvasSizeRect.intersects(CanvasController.canvasDrawLayerChild.getBounds(CanvasController.canvasPanel)))
                {
                    return true;
                }
                return false;
            }
            function showFillColor():void
            {
                CanvasController.canvasDrawLayerChild.graphics.clear();
                if (data.length === 0)
                {
                    return;
                }
                CanvasController.canvasDrawLayerChild.graphics.lineStyle(1, xColor);
                CanvasController.canvasDrawLayerChild.graphics.beginFill(xColor);
                CanvasController.canvasDrawLayerChild.graphics.drawPath(command, data);
                CanvasController.canvasDrawLayerChild.graphics.endFill();
                CanvasController.canvasDrawLayerChild.graphics.moveTo(data[data.length - 2], data[data.length - 1]);
                CanvasController.canvasDrawLayerChild.graphics.lineTo(data[0], data[1]);
                CanvasController.canvasDrawLayer.alpha = xAlpha;
            }
            function showDottedLine():void
            {
                CanvasController.canvasDrawLayerChild.graphics.clear();
                const len:uint = data.length;
                if (len <= 3)
                {
                    return;
                }
                dottedLine.moveTo(CanvasController.canvasDrawLayerChild.graphics, data[0], data[1]);
                for (var i:uint = 2;i < len;i += 2)
                {
                    dottedLine.lineTo(data[i], data[i + 1]);
                }
                dottedLine.lineTo(data[0], data[1], true);
                if (CanvasController.isLayer2Selected)
                {
                    CanvasController.bringCanvasDrawLayerAboveLayer1();
                }
                CanvasController.canvasDrawLayer.alpha = 1.0;
            }
            function exitFillPen():void
            {
                removeEvents();
                CanvasController.canvasDrawLayer.alpha = 1.0;
                mouseMoveCount = 0;
                isFillPenStarted = false;
                command.length = 0;
                data.length = 0;
                commandUndoIndexArr.length = 0;
                CanvasController.canvasDrawLayerChild.graphics.clear();
                if (ReferenceLayerController.isRefLayerMenuON)
                {
                    ReferenceLayerController.refLayerMenuBox.visible = true;
                }
                fillPenBox.visible = false;
                fillPenBox.x = -fillPenBox.width - 3;
                fillPenBox.y = -fillPenBox.height - 3;
                if (CanvasController.isLayer2Selected)
                {
                    CanvasController.bringCanvasDrawLayerAboveLayer2();
                }
                if (SidebarController.isQuickSidebarActive)
                {
                    SidebarController.startDeactivteQuickSidebar();
                }
                toolBox.setFillPenModeOFF();
                toolOptionsBox.setButtonsAlphaFillPenSelected(Global.OFFALPHA);
                toolOptionsBox.restoreDisabledButtons();
                ColorPickerController.colorPickerBox.activePaperColorButton(false);
                if (isStartedFromShortCut)
                {
                    setLastTool(TOOL_PEN);
                    selectPenTool();
                }
            }
            function applyFillPen():void
            {
                if (checkFillPenUndoReady() === true && command.length > 2)
                {
                    canAddUndoData = true;
                    command.push(2);
                    data.push(data[0]);
                    data.push(data[1]); // 마지막으로 원점으로 선을 한번 이어줘야 깔끔하게 닫힘
                    CanvasController.canvasDrawLayer.alpha = xAlpha;
                    rDataBuffer.push(["fill5", xColor, xAlpha, xBlendMode, command.concat(), data.concat(), isPenAirBrushON, airBrushSizeDrawMode]);
                    showFillColor();
                }
                CanvasController.resetCanvasDrawLayerCliprect();
                drawDone();
                exitFillPen();
            }
            function undoData():void
            {
                if (command.length === 0)
                    return;
                command.splice(commandUndoIndexArr[commandUndoIndexArr.length - 1], command.length);
                data.splice(commandUndoIndexArr[commandUndoIndexArr.length - 1] * 2, data.length);
                commandUndoIndexArr.pop();
                if (command.length <= 1)
                {
                    command.length = 0;
                    data.length = 0;
                    commandUndoIndexArr[0] = 0;
                    CanvasController.canvasDrawLayerChild.graphics.clear();
                }
                else
                {
                    showDottedLine();
                }
            }
            function onKeydownFillPen(e:KeyboardEvent):void
            {
                const pressedKey:uint = e.keyCode;
                if (CanvasController.isMouseClicked)
                {
                    return;
                }
                if (isLastKey(pressedKey))
                {
                    return;
                }
                const secondKey:int = getSecondPressedKey();
                if (SidebarController.isPressingQuickSidebarShortcut(pressedKey, secondKey)
                        || pressedKey === KEY.n6)
                {
                    updateLastKey(pressedKey);
                    if (SidebarController.isQuickSidebarActive === false)
                    {
                        SidebarController.activeQuickSideBar(true);
                        if (!FOFOTimer.hasTimer("fillColorUpdateTimer"))
                        {
                            startFillColorUpdateTimer();
                        }
                    }
                }
                else if (pressedKey === KEY.g || pressedKey === KEY.b)
                {
                    updateLastKey(pressedKey);
                    startKeyRepeat(true, function (increase:Boolean):void
                        {
                            turnOffFillPenPreviewCount = stage.frameRate;
                            adjustDrawToolAlphaByShortcut(increase);
                        }, (pressedKey === KEY.g) ? true : false);
                    if (!FOFOTimer.hasTimer("fillColorUpdateTimer"))
                    {
                        startFillColorUpdateTimer();
                    }
                }
            }
            function onKeyUpFillPen(e:KeyboardEvent):void
            {
                const keyCode:uint = e.keyCode;
                resetLastKey();
                if (CanvasController.isMouseClicked)
                {
                    if (keyCode === KEY.q || keyCode === KEY.o || keyCode === KEY.enter)
                    {
                        afterKeyUpOK = true;
                    }
                    return;
                }
                if (keyCode === KEY.w || keyCode === KEY.i || keyCode === KEY.z || keyCode === KEY.dot)
                {
                    undoData();
                }
                else if (keyCode === KEY.q || keyCode === KEY.o || keyCode === KEY.enter)
                {
                    applyFillPen();
                }
                else if (keyCode === KEY.esc || keyCode === KEY.backspace)
                {
                    exitFillPen();
                }
            }
            function onRightMouseUpFillPen(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if (!target as DisplayObject || target === SidebarController.sideBarScrollBar
                        || SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(stage.mouseX, stage.mouseY))
                {
                    return;
                }
                const targetName:String = target.name;
                if (targetName === "fillPenOK")
                {
                    applyFillPen();
                }
                else if (targetName === "fillPenCancel")
                {
                    exitFillPen();
                }
                else if (targetName === "fillPenUndo")
                {
                    updateLastFillPenBoxButtonUsed(target as SimpleButton);
                    undoData();
                }
                else if (targetName === "fillPenSidebar")
                {
                    updateLastFillPenBoxButtonUsed(target as SimpleButton);
                    SidebarController.activeQuickSideBar(false);
                    if (!FOFOTimer.hasTimer("fillColorUpdateTimer"))
                    {
                        startFillColorUpdateTimer();
                    }
                }
                fillPenBox.visible = false;
            }
            function onRightMouseDownFillPen(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if (CanvasController.isMouseClicked || SidebarController.isQuickSidebarActive || !target || numPadBox.visible)
                {
                    return;
                }
                if (target === SidebarController.sideBarScrollBar)
                {
                    SidebarController.resetSideBarPosition();
                    return;
                }
                else if (target.name === "toolZoomIn" || target.name === "toolZoomOut")
                {
                    if (CanvasController.canvasZoomMultipler !== 1.0)
                    {
                        CanvasController.resetZoomDrawMode();
                    }
                    return;
                }
                else if (target.name === "toolRotate")
                {
                    if (CanvasController.canvasAnchorPoint.rotation !== 0.0)
                    {
                        resetRotationDrawMode();
                    }
                    return;
                }
                if (SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(stage.mouseX, stage.mouseY))
                {
                    return;
                }
                const scale:Number = fillPenBox.getScale();
                fillPenBox.x = Math.floor(stage.mouseX - (lastFillPenBoxUsedButton.x + lastFillPenBoxUsedButton.width / 2) * scale);
                fillPenBox.y = Math.floor(stage.mouseY - (lastFillPenBoxUsedButton.y + lastFillPenBoxUsedButton.height / 2) * scale);
                fillPenBox.visible = true;
                Utils.setAsTopChild(fillPenBox);
            }
            function onMouseUpFillPen(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if (!target)
                    return;
                const targetName:String = e.target.name;
                FOFOTimer.remove("previewFilledColorUpdateTimer");
                CanvasController.isMouseDragging = false;
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);
                if (clickedButton === targetName)
                {
                    if (targetName === "toolFillPenOK")
                    {
                        applyFillPen();
                        return;
                    }
                    else if (targetName === "toolFillPenCancel")
                    {
                        exitFillPen();
                        return;
                    }
                    else if (targetName === "toolUndo")
                    {
                        undoData();
                        return;
                    }
                }
                if (fillPenBox.visible)
                {
                    if (clickedButton === targetName)
                    {
                        if (targetName === "fillPenOK")
                        {
                            applyFillPen();
                        }
                        else if (targetName === "fillPenCancel")
                        {
                            exitFillPen();
                        }
                        else if (targetName === "fillPenUndo")
                        {
                            updateLastFillPenBoxButtonUsed(target as SimpleButton);
                            undoData();
                        }
                    }
                }
                else
                {
                    const mousePos:Point = new Point(stage.mouseX, stage.mouseY);
                    const dist:Number = Math.floor(Point.distance(mousePos, lastMousePos));
                    mouseMoveCount += dist;
                    if (mouseMoveCount >= 10)
                    {
                        mouseMoveCount = 0;
                        commandUndoIndexArr.push(command.length - 1);
                    }
                    lastMousePos.setTo(mousePos.x, mousePos.y);
                    if (afterKeyUpOK)
                    {
                        applyFillPen();
                    }
                    else if (isCursorInDrawArea())
                    {
                        showDottedLine();
                    }
                    if (turnOffFillPenPreviewCount > 0)
                    {
                        turnOffFillPenPreviewCount = 0;
                    }
                }
                afterKeyUpOK = false;
            }
            function onMouseMoveFillPen(e:MouseEvent):void
            {
                const filteredPos:Point = CanvasController.getRefinedPoint(CanvasController.canvasDrawLayerChild.mouseX, CanvasController.canvasDrawLayerChild.mouseY);
                const mx:Number = filteredPos.x + pos05Offset;
                const my:Number = filteredPos.y + pos05Offset;
                if (lastPosOnMouseMove.x === mx && lastPosOnMouseMove.y === my)
                {
                    return;
                }
                lastPosOnMouseMove.setTo(mx, my);
                if (command.length === 0)
                {
                    command.push(1);
                    data.push(mx);
                    data.push(my);
                }
                else
                {
                    command.push(2);
                    data.push(mx);
                    data.push(my);
                }
                mouseMoveCount++;
                if (mouseMoveCount >= 6)
                {
                    mouseMoveCount = 0;
                    commandUndoIndexArr.push(command.length - 1);
                }
                lastMousePos.setTo(stage.mouseX, stage.mouseY);
                turnOffFillPenPreviewCount = 0;
                if (!FOFOTimer.hasTimer("previewFilledColorUpdateTimer"))
                {
                    FOFOTimer.addByName("previewFilledColorUpdateTimer", 0.1, false, showFillColor);
                }
            }
            function onMouseDownFillPen(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if (!target)
                    return;
                const targetName:String = target.name;
                clickedButton = targetName;
                if (fillPenBox.visible)
                {
                    return;
                }
                if (SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(stage.mouseX, stage.mouseY))
                {
                    if (targetName === "penColorButton"
                            || targetName === "paperColorButton"
                            || targetName === "rgbInfoText")
                    {
                        return;
                    }
                    if (ColorPickerController.handleColorPickerBoxMouseDown(target) || numPadBox.visible)
                    {
                        return;
                    }
                    if (numPadBox.visible)
                    {
                        return;
                    }
                    switch (targetName)
                    {
                        case "toolRotate":
                            {
                                rotateTool(false);
                            }
                            return;
                        case "prevStageBG":
                        case "prevBitmapBG":
                        case "prevBitmap":
                            {
                                CanvasController.startCanvasMoveByCanvasNavigator(false);
                            }
                            return;
                        case "prevCursor":
                            {
                                CanvasController.startCanvasMoveByCanvasNavigator(true);
                            }
                            return;
                        case "toolZoomIn":
                        case "toolZoomOut":
                            {
                                handleToolBoxClick(targetName);
                            }
                            return;
                        case "alphaButton1":
                        case "alphaButton2":
                        case "alphaButton3":
                        case "alphaButton4":
                        case "alphaButton5":
                        case "alphaButton6":
                        case "alphaButton7":
                        case "alphaButton8":
                        case "alphaButton9":
                        case "alphaButton10":
                            {
                                selectOpacityButton(targetName);
                            }
                            break;
                        default:
                            break;
                    }
                }
                if (targetName === "sideBarScrollBar")
                {
                    SidebarController.startScrollSidebarByDrag();
                }
                else if (isCursorInDrawArea() && SidebarController.isQuickSidebarActive === false)
                {
                    CanvasController.isMouseDragging = true;
                    stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);
                    const filteredPos:Point = CanvasController.getRefinedPoint(CanvasController.canvasDrawLayerChild.mouseX, CanvasController.canvasDrawLayerChild.mouseY);
                    const mx:Number = filteredPos.x + pos05Offset;
                    const my:Number = filteredPos.y + pos05Offset;
                    if (CanvasController.isLayer2Selected)
                    {
                        CanvasController.bringCanvasDrawLayerAboveLayer2();
                    }
                    if (lastPosOnMouseMove.x === mx && lastPosOnMouseMove.y === my)
                    {
                        FOFOTimer.remove("previewFilledColorUpdateTimer");
                        showFillColor();
                        return;
                    }
                    lastPosOnMouseMove.setTo(mx, my);
                    if (command.length === 0)
                    {
                        command.push(1);
                        data.push(mx);
                        data.push(my);
                    }
                    else
                    {
                        command.push(2);
                        data.push(mx);
                        data.push(my);
                    }
                    FOFOTimer.remove("previewFilledColorUpdateTimer");
                    showFillColor();
                }
            }
            function removeEvents():void
            {
                stage.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOverFillPenHint);
                stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownFillPen);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpFillPen);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownFillPen);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpFillPen);
                stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpFillPen);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeydownFillPen);
            }
            function addEvents():void
            {
                stage.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverFillPenHint);
                stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownFillPen);
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);
                stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpFillPen);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownFillPen);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpFillPen);
                stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpFillPen);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeydownFillPen);
            }
            function start():void
            {
                isFillPenStarted = true;
                if (getFirstPressedKey() === KEY.q || getFirstPressedKey() === KEY.o)
                {
                    isStartedFromShortCut = true;
                }
                else
                {
                    isStartedFromShortCut = false;
                }
                canvasSizeRect.width = CanvasController.CANVAS_WIDTH;
                canvasSizeRect.height = CanvasController.CANVAS_HEIGHT;
                command = new Vector.<int>();
                data = new Vector.<Number>();
                if (ColorPickerController.isColorPickerModeBG)
                {
                    ColorPickerController.switchColorPickerModePen();
                }
                mouseMoveCount = 0;
                afterKeyUpOK = false;
                pos05Offset = getSharpLinePosOffset(1.0);
                xColor = (PenTool.isTransparentPenColor) ? CanvasController.CANVAS_BG_COLOR : PenTool.penColor;
                xAlpha = PenTool.penAlpha;
                xBlendMode = (PenTool.isTransparentPenColor) ? "erase" : null;
                commandUndoIndexArr[0] = 0;
                clickedButton = null;
                updateLastFillPenBoxButtonUsed(fillPenBox.fillPenOK as SimpleButton);
                if (isPenAirBrushON || PenTool.isEraserAirBrushON)
                {
                    CanvasController.canvasDrawLayerChild.filters = [];
                }
                if (!PenTool.isTransparentPenColor)
                {
                    if (!ColorPickerController.isCurrentColorSamePickedColor())
                    {
                        ColorPickerController.updatePickerCurrentColor(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
                        PaletteController.addColorMyPaletteHistory(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
                    }
                }
                if (ReferenceLayerController.isRefLayerMenuON)
                {
                    ReferenceLayerController.refLayerMenuBox.visible = false;
                }
                dottedLine.setLineScale(CanvasController.canvasZoomMultipler);
                const filteredPos:Point = CanvasController.getRefinedPoint(CanvasController.canvasDrawLayerChild.mouseX, CanvasController.canvasDrawLayerChild.mouseY);
                var mx:Number = filteredPos.x + pos05Offset;
                var my:Number = filteredPos.y + pos05Offset;
                lastPosOnMouseMove.setTo(mx, my);
                command.push(1);
                data.push(mx);
                data.push(my);
                lastMousePos.setTo(mx, my);
                CanvasController.canvasDrawLayer.alpha = xAlpha;
                toolBox.setFillPenModeON();
                toolOptionsBox.disableButtonFillPenStarted();
                ColorPickerController.colorPickerBox.fillPenModeON();
                addEvents();
            }
            return {
                    start: start
                };
        }


        public function onMouseMoveUpdatePenPreviewCursor(e:MouseEvent):void
        {
            if (isReplayModeON || CaptureController.isCaptureModeON)
                return;
            penCursorManager.check();
        }
        public function cPenCursorUpdater():Object
        {
            var cursorSize:Number = 3.0;
            function getCursorSize():Number
            {
                return cursorSize;
            }
            function updateCursorSize(size:Number):void
            {
                cursorSize = size * CanvasController.canvasZoomMultipler;
            }
            function updateZoom(z:Number):void
            {
                if (isSelectedToolPenOrLine())
                {
                    cursorSize = PenTool.penSize * CanvasController.canvasZoomMultipler;
                }
                else if (isSelectedTool(TOOL_ERASER))
                {
                    cursorSize = PenTool.eraserSize * CanvasController.canvasZoomMultipler;
                }
                else
                {
                    cursorSize = 0;
                }
            }
            function checkCursorVisibility():void
            {
                if (cursorSize <= 4 || isSelectedTool(TOOL_FILLPEN))
                {
                    if (CanvasController.penSizePreviewCursor.visible)
                    {
                        CanvasController.penSizePreviewCursor.visible = false;
                    }
                }
                else if (CanvasController.penSizePreviewCursor.visible === false)
                {
                    CanvasController.penSizePreviewCursor.visible = true;
                }
            }
            function check():void
            {
                const mx:Number = stage.mouseX;
                const my:Number = stage.mouseY;
                // 아마 이거 preview커서 박스 커서가 커져서 sidebar 바운더리가 커졌을때
                // 제대로 확인못해서 썼던걸거임
                // || (!quickSidebarON && !isCursorInDrawArea())
                // (sideBar.visible && (sideBarScrollBar.hitTestPoint(mouseX,mouseY) || sideBar.hitTestPoint(mouseX,mouseY)))
                if (CanvasController.isPenSizeCursorInvisible
                        || (nowTool > TOOL_LINE && nowTool !== TOOL_FILLPEN) // 1 2 3 4 펜 지우개 라인툴 라인-지우개툴
                        || !isCursorInDrawArea()
                        || resizeCanvas.isCanvasResizing()
                        || (ReferenceLayerController.refLayerMenuBox.visible && ReferenceLayerController.refLayerMenuBox.hitTestPoint(stage.mouseX, stage.mouseY))
                        || FileManager.loadMenuBox.visible)
                {
                    CanvasController.penSizePreviewCursor.visible = false;
                }
                else
                {
                    // addundo플래그가 커서가 캔버스 안에 들어올때 해주기 때문에 위치를 계속 갱신해줘야함
                    CanvasController.penSizePreviewCursor.x = mx;
                    CanvasController.penSizePreviewCursor.y = my;
                    checkCursorVisibility();
                }
            }
            return {
                    check: check,
                    updateZoom: updateZoom,
                    updateCursorSize: updateCursorSize,
                    checkCursorVisibility: checkCursorVisibility
                };
        }
        public function cRealWorkingTimer():Object
        {
            var workingTimer:Timer = new Timer(1000);
            var workingTime:int = 0;
            var lastTime:int = 0; // 마지막 시간 저장해줌
            // 시간 표시 관련 변수
            var tt:int;
            var hh:int;
            var mm:int;
            var ss:int;
            var lastMousePosX:Number = 0;
            var lastMousePosY:Number = 0;
            function reset():void
            {
                lastTime = getTimer();
                workingTime = 0;
                MainUI.topBar.timer.text = "00:00:00";
                MainUI.topBar.updateTimerPos(stage.stageWidth);
            }
            function setRunningTime(newTime:int):void
            {
                workingTime = newTime;
            }
            function getRunningTime():int
            {
                return workingTime;
            }
            function update():void
            {
                if (workingTime < 0)
                {
                    workingTime = 0;
                }
                tt = workingTime / 1000;
                hh = Math.floor(tt / 3600);
                mm = Math.floor((tt - hh * 3600) / 60);
                ss = Math.floor(tt % 60);
                MainUI.topBar.timer.text = ((hh < 10) ? "0" + hh : "" + hh)
                    + ":" + ((mm < 10) ? "0" + mm : "" + mm)
                    + ":" + ((ss < 10) ? "0" + ss : "" + ss);
                MainUI.topBar.timerAFkDot.visible = false;
                MainUI.topBar.updateTimerPos(stage.stageWidth);
            }
            function onTimer():Boolean
            {
                const nowTime:int = getTimer();
                const subTime:int = nowTime - lastTime;
                if (!stage.nativeWindow.active
                        || (!CanvasController.isMouseClicked && !CanvasController.isRightMouseClicked && !isKeyPressed()
                            && stage.mouseX === lastMousePosX && stage.mouseY === lastMousePosY))
                {
                    MainUI.topBar.timerAFkDot.visible = !MainUI.topBar.timerAFkDot.visible;
                    MainUI.topBar.updateTimerPos(stage.stageWidth);
                }
                else
                {
                    workingTime += subTime;
                    update();
                }
                lastMousePosX = stage.mouseX;
                lastMousePosY = stage.mouseY;
                lastTime = nowTime;
                return true;
            }
            function stop():void
            {
                if (workingTimer !== null)
                {
                    workingTimer.stop();
                    workingTimer.removeEventListener(TimerEvent.TIMER, onTimer);
                    workingTimer = null;
                }
            }
            function start():void
            {
                workingTimer.addEventListener(TimerEvent.TIMER, onTimer);
                workingTimer.start();
            }
            return {
                    start: start,
                    stop: stop,
                    reset: reset,
                    update: update,
                    getRunningTime: getRunningTime,
                    setRunningTime: setRunningTime
                };
        }
        public function restoreZoomReplayMode():void
        {
            rCanvasZoomIndex = CanvasController.getNearZoomIndex(rLastCanvasZoomMultiplier);
            CanvasController.updateCanvasScale(CanvasController.canvasZoomMultiplerList[rCanvasZoomIndex], true);
            rFollowMouse.updateBounds();
        }
        public function resetZoomReplayMode():void
        {
            const center:Point = MainUIController.getStageCenterPos("replay");
            rLastCanvasZoomMultiplier = 1.0;
            rCanvasZoomIndex = CanvasController.canvasZoomMultiplerList.indexOf(1.0);
            CanvasController.moveCanvasAnchorPoint(center.x, center.y, true);
            CanvasController.updateCanvasScale(1.0, true);
            setFitReplayCanvasToViewportOFF();
            rFollowMouse.updateBounds();
        }


        public function checkGeneralKeyUp(keyCode:uint):void
        {
            if (KEY_BUFFER.length === 0)
            {
                resetLastKey();
            }
            else if (!CaptureController.isCaptureModeON && !isReplayModeON && isLastKey(keyCode))
            {
                LassoTool.onKeyDownLassoTool(null);
            }
        }



        public function selectPenToolIfNotDrawingTool(checkErase:Boolean):void
        {
            if (!(isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILLPEN)
                        || (checkErase && isSelectedTool(TOOL_ERASER))))
            {
                resetLastTool();
                selectPenTool();
                updatePenSizeCursor();
            }
        }


        public function onMouseOverToolBox2Hint(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if (!target || target.alpha < 1.0)
            {
                return;
            }
            const hintStr:String = HintStrings.getHintFromTargetName(target.name);
            toolBox2.hint((hintStr === null) ? "Tools" : hintStr);
        }

        // drawdone에서 줌된 blur사이즈가 아니 1배율 블러를 적용해야 제대로 되기 때문에 이거해줌
        public function blurReplayCanvasByDefaultValue():void
        {
            const blurSize:Number = CanvasController.getBlurSize(rAirBrushSize, 1.0);
            const blurf:BlurFilter = new BlurFilter(blurSize, blurSize, 3);
            rCanvasDrawShape.filters = [blurf];
        }
        public function resetBlurReplayCanvas():void
        {
            rAirBrushSize = 0;
            rCanvasDrawShape.filters = [];
        }
        public function blurReplayCanvasByValue(size:Number):void
        {
            const blurSize:Number = CanvasController.getBlurSize(size, rCanvasZoomMultiplier);
            const blurf:BlurFilter = new BlurFilter(blurSize, blurSize, 3);
            rAirBrushSize = size;
            rCanvasDrawShape.filters = [blurf];
        }
        public function toggleAirBrushCheckBox(flag:Boolean, penFlag:Boolean):void
        {
            toolOptionsBox.airBrushOFFButton.visible = flag;
            toolOptionsBox.airBrushONButton.visible = !flag;
            if (flag)
            {
                airBrushSizeDrawMode = (penFlag) ? PenTool.penSize : PenTool.eraserSize;
                toolOptionsBox.blurShapeSetON();
            }
            else if (airBrushSizeDrawMode !== 0)
            {
                airBrushSizeDrawMode = 0;
                CanvasController.canvasDrawLayerChild.filters = [];
                toolOptionsBox.blurShapeSetOFF();
            }
        }
        public function toggleEraseAirBrushButtonShortCut():void
        {
            PenTool.isEraserAirBrushON = !PenTool.isEraserAirBrushON;
            toggleAirBrushCheckBox(PenTool.isEraserAirBrushON, false);
            if (PenTool.isEraserAirBrushON)
                MainUI.showMouseHintTemp("Eraser Air brush ON");
            else
                MainUI.showMouseHintTemp("Eraser Air brush OFF");
        }
        public function toggleEraseAirBrushButton(flag:Boolean):void
        {
            PenTool.isEraserAirBrushON = flag;
            toggleAirBrushCheckBox(flag, false);
        }
        public function togglePenAirBrushButtonShortCut():void
        {
            isPenAirBrushON = !isPenAirBrushON;
            toggleAirBrushCheckBox(isPenAirBrushON, true);
            if (isPenAirBrushON)
                MainUI.showMouseHintTemp("Pen Air brush ON");
            else
                MainUI.showMouseHintTemp("Pen Air brush OFF");
        }
        public function togglePenAirBrushButton(flag:Boolean):void
        {
            isPenAirBrushON = flag;
            toggleAirBrushCheckBox(flag, true);
        }
        public function restoreCanvasBackgroundColor(replayMode:Boolean):void
        {
            var xPanel:Sprite;
            var w:Number = CanvasController.CANVAS_WIDTH;
            var h:Number = CanvasController.CANVAS_HEIGHT;
            var color:uint;
            if (replayMode)
            {
                xPanel = rCanvasPanel;
                w = RCANVAS_WIDTH;
                h = RCANVAS_HEIGHT;
                color = RCANVAS_BG_COLOR;
            }
            else
            {
                xPanel = CanvasController.canvasPanel;
                w = CanvasController.CANVAS_WIDTH;
                h = CanvasController.CANVAS_HEIGHT;
                color = CanvasController.CANVAS_BG_COLOR;
            }
            xPanel.graphics.clear();
            xPanel.graphics.beginFill(color);
            xPanel.graphics.drawRect(0, 0, w, h);
            xPanel.graphics.endFill();
        }


        public function toggleSharpLineByShortcut():void
        {
            toggleSharpLine(!isSharpLineON);
            if (isSharpLineON)
            {
                MainUI.showMouseHintTemp("Sharp line ON");
            }
            else
            {
                MainUI.showMouseHintTemp("Sharp line OFF");
            }
        }
        public function getSharpLinePosOffset(size:Number):Number
        {
            return (isSharpLineON) ? (size % 2.0 === 0) ? 0.0 : 0.5
                : (size % 2.0 === 0) ? 0.5 : 0.0;
        }
        public function toggleSharpLine(flag:Boolean):void
        {
            isSharpLineON = flag;
            toolOptionsBox.sharpLineOFFButton.visible = flag;
            toolOptionsBox.sharpLineONButton.visible = !flag;
            updatePenSizeCursor();
        }
        public function updateStageBGSize():void
        {
            MainUI.stageBG.graphics.clear();
            MainUI.stageBG.graphics.beginFill(0, 0.0);
            MainUI.stageBG.graphics.drawRect(-2, -2, stage.stageWidth + 4, stage.stageHeight + 4);
            MainUI.stageBG.graphics.endFill();
            if (MainUI.stageBG.getChildByName("rCanvasCompleteAnchorPoint"))
            {
                setReplayCompleteCanvasCenter();
            }
        }
        public function addGlobalEvents():void
        {
            // 전역스테이지 이벤트 cMouseMoveStage <- 스테이지 마우스 무브는 클로저로 하고있음
            stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownStage, false, 1);
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpStage, false, 1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpStage, false, 1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownStage, false, 1);
            stage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, onMiddleMouseDownStage, false, 1);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownStage, false, 1);
            stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpStage, false, 1);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveUpdatePenPreviewCursor);
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseMoveUpdatePenPreviewCursor, false, -1);
            stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeaveStage, false);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, MainUI.onMouseMoveBottomHint);
            stage.nativeWindow.x = Capabilities.screenResolutionX / 2 - 680 / 2;
            stage.nativeWindow.y = Capabilities.screenResolutionY / 2 - 768 / 2 - 50;
            stage.nativeWindow.addEventListener(Event.RESIZE, MainUIController.onWindowResize);
            stage.nativeWindow.addEventListener(Event.DEACTIVATE, FileManager.onWindowDeactivate);
            stage.nativeWindow.addEventListener(Event.ACTIVATE, MainUIController.onWindowActive);
            stage.nativeWindow.addEventListener(Event.CLOSING, FileManager.onWindowClosingEvent);
            stage.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragEnterStage);
            stage.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, FileManager.onDragDropStage);
            stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheelStage);
            NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, FileManager.onInvokeEvent);
            loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onGlobalError);
            function onGlobalError(e:UncaughtErrorEvent):void
            {
                var msg:String = "An unknown error occurred.";
                var errorObject:Object = e.error;
                if (errorObject is Error)
                {
                    msg = (errorObject as Error).message;
                }
                else if (errorObject is ErrorEvent)
                {
                    msg = (errorObject as ErrorEvent).text;
                }
                else if (errorObject != null) // Error, ErrorEvent가 아닌 객체 처리
                {
                    msg = String(errorObject);
                }
                MainUI.showMouseHintTemp(msg, 10.0);
                // 이 핸들러가 에러를 처리했음을 시스템에 알리고 기본 동작을 막습니다. (권장)
                e.preventDefault();
            }
        }
        public function addGlobalEventsChild():void
        {
            toolBox2.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverToolBox2Hint);
        }
        public function updateToolOptionsTextBySelectedTool():void
        {
            var toolName:String = "Pen";
            const nt:uint = nowTool;
            if (isSelectedTool(TOOL_ERASER))
                toolName = "Eraser";
            else if (isSelectedTool(TOOL_LINE))
                toolName = "Line";
            else if (isSelectedTool(TOOL_FILLPEN))
                toolName = "FillPen";
            toolOptionsBox.hintText(toolName);
        }
        public function showDrawToolHintSizeOpacity():void
        {
            var tooltype:String = "";
            var size:Number;
            var alpha:Number;
            if (isSelectedTool(TOOL_PEN))
            {
                tooltype = "Pen ";
                size = PenTool.penSizeList[PenTool.penSizeIndex];
                alpha = PenTool.penAlphaList[PenTool.penAlphaIndex];
            }
            else if (isSelectedTool(TOOL_LINE))
            {
                tooltype = "Line ";
                size = PenTool.penSizeList[PenTool.penSizeIndex];
                alpha = PenTool.penAlphaList[PenTool.penAlphaIndex];
            }
            else if (isSelectedTool(TOOL_FILLPEN))
            {
                tooltype = "Fill Pen ";
                size = 1;
                alpha = PenTool.penAlphaList[PenTool.penAlphaIndex];
            }
            else if (isSelectedTool(TOOL_ERASER))
            {
                tooltype = "Eraser ";
                size = PenTool.penSizeList[PenTool.eraserSizeIndex];
                alpha = PenTool.penAlphaList[PenTool.eraserAlphaIndex];
            }
            MainUI.showMouseHintTemp(tooltype + size + "px, " + alpha * 100 + "%");
        }
        public function adjustDrawToolAlphaByShortcut(increase:Boolean):void
        {
            function setAlpha(alp:Number, size:uint):void
            {
                var index:Number = PenTool.penAlphaList.indexOf(alp);
                const len:uint = PenTool.penAlphaList.length - 1;
                if (increase)
                {
                    index++;
                    if (index > len)
                    {
                        index = len;
                    }
                }
                else
                {
                    index--;
                    if (index < 1)
                    {
                        index = 1;
                    }
                }
                updateDrawToolAlpha(PenTool.penAlphaList[index]);
                showDrawToolHintSizeOpacity();
            }
            selectPenToolIfNotDrawingTool(true);
            if (isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILLPEN))
            {
                setAlpha(PenTool.penAlpha, PenTool.penSize);
            }
            else if (isSelectedTool(TOOL_ERASER))
            {
                setAlpha(PenTool.eraserAlpha, PenTool.eraserSize);
            }
        }
        public function adjustDrawToolSizeByShortcut(increase:Boolean):void
        {
            if (isSelectedTool(TOOL_FILLPEN))
            {
                return;
            }
            const len:uint = PenTool.penSizeList.length - 1;
            function setSize(index:uint, alpha:Number):void
            {
                if (increase)
                {
                    index++;
                    if (index > len)
                    {
                        index = len;
                    }
                }
                else
                {
                    index--;
                    if (index < 1)
                    {
                        index = 1;
                    }
                }
                setDrawToolSize(index);
                updatePenSizeCursor();
                showDrawToolHintSizeOpacity();
                penCursorManager.checkCursorVisibility();
            }
            selectPenToolIfNotDrawingTool(true);
            if (isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILLPEN))
            {
                setSize(PenTool.penSizeIndex, PenTool.penAlpha);
                if (isPenAirBrushON && PenTool.penSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = PenTool.penSize;
                }
            }
            else if (isSelectedTool(TOOL_ERASER))
            {
                setSize(PenTool.eraserSizeIndex, PenTool.eraserAlpha);
                if (PenTool.isEraserAirBrushON && PenTool.eraserSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = PenTool.eraserSize;
                }
            }
        }
        // composing 키에대한 체크 잘모르겠음 한영 변환이 관련있는거 같음
        public function checkInvalidKey():void
        {
            const len:uint = KEY_BUFFER.length;
            for (var i:int = 0;i < len;i++)
            {
                if (KEY_BUFFER[i] === 229
                        || KEY_BUFFER[i] === 241
                        || KEY_BUFFER[i] === 242)
                {
                    clearKeyBuffer();
                    return;
                }
            }
            if (len >= 2)
            {
                if ((KEY_BUFFER[0] === 18 && KEY_BUFFER[1] === 32)
                        || (KEY_BUFFER[0] === 32 && KEY_BUFFER[1] === 18))
                {
                    clearKeyBuffer();
                }
            }
        }
        public function getPressedKeyCount():int
        {
            return KEY_BUFFER.length;
        }
        public function isKeyPressed():Boolean
        {
            return KEY_BUFFER.length > 0;
        }
        public function getLastKey():int
        {
            return KEY_BUFFER[KEY_BUFFER.length - 1];
        }
        public function isTwoKeyPressed():Boolean
        {
            return KEY_BUFFER.length === 2;
        }
        public function isPressdKey(key:int):int
        {
            return KEY_BUFFER.lastIndexOf(key);
        }
        public function getFirstPressedKey():int
        {
            return KEY_BUFFER[0];
        }
        public function getSecondPressedKey():int
        {
            return KEY_BUFFER[1];
        }
        public function onKeyUpStage(e:KeyboardEvent):void
        {
            tryDisableIME();
            checkInvalidKey();
            const index:int = isPressdKey(e.keyCode);
            if (index > -1)
            {
                KEY_BUFFER.splice(index, 1);
            }
        }
        public function onKeyDownStage(e:KeyboardEvent):void
        {
            tryDisableIME();
            checkInvalidKey();
            const keyCode:uint = e.keyCode;
            if (keyCode === KEY.window)
            {
                return;
            }
            if (keyCode === KEY.tab || keyCode === KEY.alt)
            {
                e.preventDefault();
            }
            if (KEY_BUFFER.lastIndexOf(keyCode) === -1)
            {
                KEY_BUFFER.push(keyCode);
            }
        }
        public function selectPenSizeButton(targetName:String):void
        {
            const numberOnly:String = targetName.substr(11, targetName.length);
            const index:uint = parseInt(numberOnly);
            setDrawToolSize(index);
            updatePenSizeCursor();
            if (isSelectedTool(TOOL_FILLPEN))
            {
                if (isPenAirBrushON && PenTool.penSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = PenTool.penSize;
                }
            }
            else if (isSelectedToolPenOrLine())
            {
                if (isPenAirBrushON && PenTool.penSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = PenTool.penSize;
                }
            }
            else if (isSelectedTool(TOOL_ERASER))
            {
                if (PenTool.isEraserAirBrushON && PenTool.eraserSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = PenTool.eraserSize;
                }
            }
        }
        public function startPenSmootingAdjustment():void
        {
            const minDist:Number = toolOptionsBox.penSmoothSlider.x + 1; // 펜 리스트에 흰색 선 시작과 끝 x좌표임
            const maxDist:Number = minDist + toolOptionsBox.penSmoothSlider.width - 1;
            const step:Number = PenTool.penSmoothSlideTotal;
            const div:Number = (maxDist - minDist) / step;
            const maxValue:Number = 0.85;
            const minValue:Number = 0.02;
            const stepValue:Number = (maxValue - minValue) / step;
            const airBrushFlag:Boolean = isSelectedToolPenOrLine() && isPenAirBrushON;
            const eraseAirBrushFlag:Boolean = isSelectedTool(TOOL_ERASER) && PenTool.isEraserAirBrushON;
            var oldValue:int = PenTool.penSmoothSlideValue;
            CanvasController.isMouseDragging = true;
            function onMouseUpPenSmoothing(e:MouseEvent):void
            {
                CanvasController.isMouseDragging = false;
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpPenSmoothing);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMovePenSmoothing);
            }
            function adjustPenSmoothingValue():void
            {
                var mx:Number = toolOptionsBox.penSmoothSliderWapper.mouseX + toolOptionsBox.penSmoothSlider.x;
                if (mx < minDist)
                {
                    mx = minDist;
                }
                else if (mx > maxDist)
                {
                    mx = maxDist;
                }
                // 버튼을 기준으로 중간값으로
                const value:Number = Math.floor((mx - minDist) / div);
                if (oldValue !== value)
                {
                    const xpos:Number = value * div + minDist;
                    if (toolOptionsBox.penSmoothSliderCursor.x === xpos)
                        return;
                    toolOptionsBox.penSmoothSliderCursor.x = xpos;
                    if (value === 0)
                    {
                        PenTool.penSmoothValue = 0;
                    }
                    else
                    {
                        PenTool.penSmoothValue = maxValue - (value * stepValue);
                    }
                    PenTool.penSmoothSlideValue = value;
                    oldValue = value;
                    MainUI.showBottomHint(HintStrings.getHintFromTargetName("penSmoothSliderWapper"));
                }
            }
            function onMouseMovePenSmoothing(e:MouseEvent):void
            {
                adjustPenSmoothingValue();
            }
            adjustPenSmoothingValue();
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpPenSmoothing);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMovePenSmoothing);
        }

        // rotate hand zoom에서 쓰임
        public function addInputEventsReplayMode():void
        {
            if (isReplayModeInputEventsAdded === false)
            {
                isReplayModeInputEventsAdded = true;
                // resetKeyBuffer();
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownReplayMode, false, -1);
                stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownReplayMode, false, -1);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownReplayMode, false, -1);
                stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpReplayMode, false, -1);
            }
        }
        public function removeInputEventsReplayMode():void
        {
            isReplayModeInputEventsAdded = false;
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownReplayMode);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownReplayMode);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownReplayMode);
            stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpReplayMode);
        }
        public function removeInputEventsDrawMode():void
        {
            isDrawModeInputEventsAdded = false;
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownDrawMode);
            stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpDrawMode);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownDrawMode);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpDrawMode, false);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownDrawMode);
            ColorPickerController.colorPickerBox.rgbInfoText.removeEventListener(MouseEvent.MOUSE_DOWN, ColorPickerController.onMouseDownRGBInfoText);
            // stage.removeEventListener(MouseEvent.MOUSE_OVER,lassoMenuHintONEvent);
        }
        public function addInputEventsDrawMode():void
        {
            if (isDrawModeInputEventsAdded === false)
            {
                isDrawModeInputEventsAdded = true;
                // resetKeyBuffer();
                stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpDrawMode, false, -1);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownDrawMode, false, -1);
                stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownDrawMode, false, -1);
                stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpDrawMode, false, -1);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownDrawMode, false, -1);
                ColorPickerController.colorPickerBox.rgbInfoText.addEventListener(MouseEvent.MOUSE_DOWN, ColorPickerController.onMouseDownRGBInfoText);
            }
        }

        public function removeInputEventsToolBox2():void
        {
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpToolBox2);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownToolBox2);
            toolBox2.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOverToolBox2);
            stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpToolBox2);
            addInputEventsDrawMode();
        }
        public function addInputEventsToolBox2(fromShortcut:Boolean):void
        {
            removeInputEventsDrawMode();
            if (fromShortcut)
            {
                toolBox2.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverToolBox2, false, -2);
                stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpToolBox2, false, -2);
            }
            else
            {
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpToolBox2, false, -2);
            }
            stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownToolBox2, false, -2);
        }









        public function updateDrawToolAlpha(alpha:Number = 0.0):void
        {
            const index:int = PenTool.penAlphaList.indexOf(alpha);
            const eraseFlag:Boolean = isSelectedTool(TOOL_ERASER);
            updateOpacityCursorPos(index);
            if (eraseFlag === false)
            {
                PenTool.penAlpha = alpha;
                PenTool.penAlphaIndex = index;
            }
            else if (eraseFlag === true)
            {
                PenTool.eraserAlpha = alpha;
                PenTool.eraserAlphaIndex = index;
            }
        }
        public function setDrawToolSize(index:uint):void
        {
            const size:uint = PenTool.penSizeList[index];
            if (isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILLPEN))
            {
                PenTool.penSize = size;
                PenTool.penSizeIndex = index;
                penCursorManager.updateCursorSize(PenTool.penSize);
            }
            else if (isSelectedTool(TOOL_ERASER))
            {
                PenTool.eraserSize = size;
                PenTool.eraserSizeIndex = index;
                penCursorManager.updateCursorSize(PenTool.eraserSize);
            }
            toolOptionsBox.movePenSizeCursor(index);
        }
        public function selectPenShapeButton(shapeFlag:Boolean):void
        {
            PenTool.penListShapeIsSqare = shapeFlag;
            if (isSelectedToolPenOrLine())
            {
                if (PenTool.penIsSquare !== shapeFlag)
                {
                    PenTool.penIsSquare = shapeFlag;
                }
            }
            else if (isSelectedTool(TOOL_ERASER))
            {
                if (PenTool.eraserIsSquare !== shapeFlag)
                {
                    PenTool.eraserIsSquare = shapeFlag;
                }
            }
            toolOptionsBox.updatePenShapeSet(shapeFlag);
            updatePenSizeCursor();
        }
        // 단축키를  after tool mouse up에서 이전툴을 복구해줌
        public function selectLastUsedTool():void
        {
            const lastToolSave:int = lastTool;
            if (lastToolSave === TOOL_NONE)
            {
                selectPenTool();
                updatePenSizeCursor();
                return;
            }
            switch (lastToolSave)
            {
                case TOOL_PEN:
                    selectPenTool();
                    updatePenSizeCursor();
                    break;
                case TOOL_FILLPEN:
                    selectFillPenTool();
                    break;
                case TOOL_ERASER:
                    selectEraseTool();
                    updatePenSizeCursor();
                    break;
                case TOOL_LINE:
                    selectLineTool();
                    updatePenSizeCursor();
                    break;
                case TOOL_EYEDROPPER:
                    eyeDropperTool();
                    break;
                case TOOL_LASSO:
                    selectLassoTool();
                    break;
                case TOOL_MOVE:
                    selectMoveTool();
                    break;
                case TOOL_ROTATE:
                    selectRotateTool();
                    break;
                case TOOL_ZOOM:
                    selectZoomTool();
                    break;
            }
            nowTool = lastToolSave;
            resetLastTool();
        }
        // VERSION변수를 문자열로 변환, 변환할때 뒤에 .0이 붙었는지 까지 체크
        public function convertVersionString(version:Number):String
        {
            var verStr:String = version.toString();
            if (verStr && verStr.indexOf(".") === -1)
                verStr = verStr + ".0";
            return verStr;
        }
        public function enableIME():void
        {
            IME.enabled = true;
        }
        public function tryDisableIME():void
        {
            if (CaptureController.isCaptureStampTextFieldFocused)
            {
                IME.enabled = true;
                return;
            }
            if (Capabilities.hasIME && IME.enabled) // 다른 언어로 하면 자판 안먹어서 그냥 ime자체를안씀
            {
                IME.compositionAbandoned();
                IME.enabled = false;
            }
        }
        // 문자열을 소수 2번째 자리까지만 변환
        public function closeAboutBox():void
        {
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, MainUIController.onAboutWindowMouseDown);
            CaptureController.removeInputEventCaptrueMode();
            removeInputEventsReplayMode();
            addInputEventsDrawMode();
            isAboutBoxOpened = false;
            aboutBox.visible = false;
            FOFOTimer.addByName("clickBlockTimer", 0.15, false, function ():void
                {
                    CanvasController.isMouseClickBlocked = false;
                });
        }
        public function updateAboutPanelCenterPos():void
        {
            aboutBox.x = Math.floor(stage.stageWidth / 2) + Math.floor(-aboutBox.width / 2);
            aboutBox.y = Math.floor((stage.stageHeight - 39) / 2) + Math.floor(-aboutBox.height / 2);
        }
        public function openAboutBox(welcome:Boolean):void
        {
            Utils.setAsTopChild(aboutBox);
            isAboutBoxOpened = true;
            CanvasController.isMouseClickBlocked = true;
            MainUI.hideBottomHint();
            removeInputEventsDrawMode();
            if (welcome === true)
            {
                aboutBox.resetAppButton.visible = false;
                FOFOTimer.addByName("openAboutPanelOFFTimer", 1.0, false, function ():void
                    {
                        stage.addEventListener(MouseEvent.MOUSE_DOWN, MainUIController.onAboutWindowMouseDown);
                    });
            }
            else
            {
                removeInputEventsDrawMode();
                aboutBox.resetAppButton.visible = true;
                AppUpdater.checkUpdate();
                stage.addEventListener(MouseEvent.MOUSE_DOWN, MainUIController.onAboutWindowMouseDown);
            }
            aboutBox.randomLogo();
            aboutBox.updateMemoryInfo(FileManager.getDriveUsageString());
            updateAboutPanelCenterPos();
            aboutBox.visible = true;
        }
        public function clearDataAndResetVars():void
        {
            FileManager.isContinueSaveON = false;
            rLastCanvasBGColor = CanvasController.CANVAS_BG_COLOR;
            rMirrorON = false;
            CanvasController.isCanvasMirrored = false;
            mirrorCommandReady = false;
            rDataReadFlag = false;
            undoManager.setRFileTotalFrame(0);
            updateTotalFrameAndReplayMaxSpeedFor10Sec(0);
            rReplayImageCacheState = REPLAY_IMAGE_CAHCHE_COMPLETE;
            CanvasController.isLayerSwapped = false;
            ReferenceLayerController.resetRefLayerImageTransform();
            ReferenceLayerController.resetRefLayerMenuOpacity();
            initializeReplayDataFile(true);
            resetReplaySpeedBar();
            resetReplayTime();
            resetUndoState();
            CaptureController.resetCaptureCanvasChangeValue();
            FileManager.updateLastFilePathByRandomFileName();
            CanvasController.canvasInfoBox.setMirror(false);
            MainUIController.updateWindowTitle();
            removeKeyRepeatEvents(null);
        }
        public function copyReplayCanvasDataToDrawCanvas():void
        {
            const lineStyleSave:Array = drawReplayByCommand.getrLineStyleSave();
            // if(!lineStyleSave) return;
            var newColorTransform:ColorTransform = new ColorTransform(1, 1, 1, lineStyleSave[0]);
            rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
            rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
            if (isLayer2SelectedReplayMode())
            {
                rCanvasLayer2BitmapData.draw(rCanvasDrawLayerBitmap, null, newColorTransform, lineStyleSave[1]);
            }
            else
            {
                rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap, null, newColorTransform, lineStyleSave[1]);
            }
            // 캔버스 2번 지워줘야함
            rCanvasDrawShape.graphics.clear();
            rCanvasDrawLayerBitmapData.fillRect(new Rectangle(0, 0, rCanvasDrawLayerBitmapData.width, rCanvasDrawLayerBitmapData.height), 0);
            CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, rCanvasLayer1BitmapData, CanvasController.canvasLayer1Bitmap);
            CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, rCanvasLayer2BitmapData, CanvasController.canvasLayer2Bitmap);
            CanvasController.updateCavnvasSizeDrawMode(CanvasController.canvasLayer1Bitmap.width, CanvasController.canvasLayer1Bitmap.height);
            ColorPickerController.updateCanvasBGColorDrawMode(RCANVAS_BG_COLOR);
            CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
        }
        public function clearDrawingData():void
        {
            CanvasController.clearCanvas();
            resetZoomReplayMode();
            resetRotationReplayMode();
            CanvasController.centerCanvas("replay");
            clearCanvasReplayMode();
            CanvasController.resetZoomDrawMode();
            resetRotationDrawMode();
            CanvasController.centerCanvas("draw");
            clearDataAndResetVars();
            MainUIController.markWindowTitleAsDirty();
            drawReplayByCommand.resetFirstRCursorPos();
            clearRFrameTempCache();
            // reset vars보다 뒤에 와야함
            // addundo에서 활성화 해주고 있기 때문에
            MainUI.topBar.newFileButton.alpha = Global.OFFALPHA;
        }

        //todo: 분야별로 분리해야
        public function handleMouseClick(targetName:String):void
        {
            if (isAboutBoxOpened)
            {
                function onMouseUpAboutBox(e:MouseEvent):void
                {
                    stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpAboutBox);
                    const upTargetName:String = e.target.name;
                    if (targetName === upTargetName)
                    {
                        switch (targetName)
                        {
                            case "resetAppButton":
                                {
                                    resetApp();
                                    stage.nativeWindow.close();
                                }
                                break;
                            case "versionInfo":
                            case "releaseNoteButton":
                                navigateToURL(new URLRequest("https://raw.githubusercontent.com/guljam/2020FlashPaint/master/releasenote.txt"));
                                break;
                            case "aboutButton":
                                closeAboutBox();
                                break;
                            case "kor":
                                navigateToURL(new URLRequest("https://github.com/guljam/2020FlashPaint/wiki/FOFO-Paint-%EC%84%A4%EB%AA%85%EC%84%9C"));
                                break;
                            case "jp":
                                navigateToURL(new URLRequest("https://github.com/guljam/2020FlashPaint/wiki/FOFO-Paint-%E3%83%9E%E3%83%8B%E3%83%A5%E3%82%A2%E3%83%AB"));
                                break;
                            case "eng":
                                navigateToURL(new URLRequest("https://github.com/guljam/2020FlashPaint/wiki/FOFO-Paint-manual"));
                                break;
                            case "aboutHomePageLink":
                                navigateToURL(new URLRequest("https://guljam.github.io/2020FlashPaint/"));
                                break;
                            case "aboutManualFolder":
                                FileManager.openLocalManualFolder();
                                break;
                                // case "aboutMeLink":
                                // navigateToURL(new URLRequest("https://twitter.com/ninanoninini"));
                                // break;
                            default:
                                closeAboutBox();
                                break;
                        }
                    }
                }
                stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpAboutBox);
                return;
            }
            function onMouseUp(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
                const upTargetName:String = e.target.name;
                if (targetName === upTargetName)
                {
                    switch (upTargetName)
                    {
                        case "drawModeButton":
                            {
                                exitReplayMode();
                            }
                            break;
                        case "replayModeButton":
                            {
                                enterReplayMode();
                                CanvasController.isMouseClicked = false; // 리플레이 버튼 누르고 나서 단축키가 안먹는 현상이 이거임
                            }
                            break;
                        case "capLayer1VisibleButton":
                            {
                                toggleLayerCaptureMode(1);
                            }
                            break;
                        case "capLayer2VisibleButton":
                            {
                                toggleLayerCaptureMode(2);
                            }
                            break;
                        case "dpiButton":
                            {
                                Global.setNextScaleIndex();
                                MainUIController.applyUIScale();
                                MainUI.showMouseHintTemp(Global.getUIScaleString());
                            }
                            break;
                        case "updateButton":
                            {
                                AppUpdater.prepareUpdate();
                            }
                            break;
                        case "sideBarPositionButton":
                        case "sideBarPositionButton2":
                            {
                                SidebarController.toggleSideBarPosition();
                            }
                            break;
                        case "sideBarOFFButton":
                        case "sideBarOFFButton2":
                            {
                                SidebarController.hideSidebarPermanent();
                            }
                            break;
                        case "sideBarONButton":
                        case "sideBarONButton2":
                            {
                                SidebarController.showSidebarPermanent();
                            }
                            break;
                        case "refLoadImageButton":
                            {
                                FileManager.openLoadFileBrowser(true);
                            }
                            break;
                        case "saveButton":
                            {
                                FileManager.openSaveFileBrowser(false);
                            }
                            break;
                        case "loadButton":
                            {
                                FileManager.openLoadFileBrowser();
                            }
                            break;
                        case "clipBoardButton":
                            {
                                ClipboardManager.tryLoadClipboardImage(false);
                            }
                            break;
                        case "repCaptureButton":
                        case "captureButton":
                            {
                                CaptureController.enterCaptureMode();
                            }
                            break;
                        case "capRotate":
                            {
                                CaptureController.rotateCaptureImage(++CaptureController.captureCanvasRotationStep, false);
                            }
                            break;
                        case "capTrans":
                            {
                                CaptureController.applyTransparentCanvasBGCaptureMode(!CaptureController.isCaptureTransparentBGShowing);
                            }
                            break;
                        case "capClipBoard":
                            {
                                CaptureController.copyCaptureImageToCilpBoard();
                            }
                            break;
                        case "capSave":
                            {
                                FileManager.saveCaptureImage();
                            }
                            break;
                        case "capOff":
                            {
                                CaptureController.handleExitCaptureMode();
                            }
                            break;
                        case "capFlip":
                            {
                                CaptureController.flipCaptureImage(!CaptureController.isCaptureCanvasFlipped, false);
                            }
                            break;
                        case "capStamp":
                            {
                                CaptureController.toggleCaptureStampButton();
                            }
                            break;
                        case "capStampFont":
                            {
                                CaptureController.showStampFontList();
                            }
                            break;
                        case "capFontListPrev":
                            {
                                CaptureController.captureStampFontListBox.updateNextFontList(false);
                            }
                            break;
                        case "capFontListNext":
                            {
                                CaptureController.captureStampFontListBox.updateNextFontList(true);
                            }
                            break;
                        case "topBarColorButton":
                            {
                                MainUIController.cycleUIColor();
                            }
                            break;
                        case "gridButton":
                            {
                                CanvasGridOverlay.gridButton.start(false);
                            }
                            break;
                        case "aboutButton":
                            {
                                openAboutBox(false);
                            }
                            break;
                        case "newWindowCloseButton":
                            {
                                ImageViewWindow.closeCanvasWindow();
                            }
                            break;
                        case "newWindowButton":
                            {
                                ImageViewWindow.openImageViewWindow();
                            }
                            break;
                        case "replayZoomInButton":
                            {
                                CanvasController.zoomInCanvas(true, true);
                            }
                            break;
                        case "replayZoomOutButton":
                            {
                                CanvasController.zoomInCanvas(false, true);
                            }
                            break;
                        case "replayFitToWindowButton":
                            {
                                toggleFitToCanvasReplayMode();
                            }
                            break;
                        case "replayRepeatButton":
                            {
                                toggleReplayRepeat();
                            }
                            break;
                        case "refMenuCloseButton":
                            {
                                Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                                ReferenceLayerController.closeRefLayerMenu();
                            }
                            break;
                        case "refTransferCanvasImageButton":
                            {
                                ReferenceLayerController.mergeCanvasImageIntoRefLayer();
                            }
                            break;
                        case "refClipBoardButton":
                            {
                                if (ReferenceLayerController.refLayerMenuBox.refClipBoardButton.alpha === 1.0)
                                {
                                    ClipboardManager.tryLoadClipboardImage(true);
                                }
                            }
                            break;
                        case "refMirrorImageButton":
                            {
                                Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                                if (ReferenceLayerController.isRefLayerEmpty())
                                {
                                    ReferenceLayerController.showRefLayerIsEmptyHint();
                                }
                                else
                                {
                                    ReferenceLayerController.startRefLayerImageMirror();
                                }
                            }
                            break;
                        case "refMemoryTrainingOnButton":
                        case "refMemoryTrainingOffButton":
                            {
                                Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                                if (ReferenceLayerController.isRefLayerEmpty())
                                {
                                    ReferenceLayerController.showRefLayerIsEmptyHint();
                                }
                                else
                                {
                                    ReferenceLayerController.toggleRefLayerMemoryTraining();
                                }
                            }
                            break;
                        case "playButton":
                            {
                                if (isReplayRestartTimerON())
                                {
                                    cancelReplayRestartTimer();
                                }
                                else
                                {
                                    handleReplayStartButton();
                                }
                            }
                            break;
                        case "pauseButton":
                            {
                                FOFOTimer.remove("prograssBarUpdateTimer");
                                if (isReplayRestartTimerON())
                                {
                                    cancelReplayRestartTimer();
                                }
                                else
                                {
                                    handleReplayStopButton();
                                }
                            }
                            break;
                        case "lassoRefLayer":
                            {
                                LassoTool.mergeLassoImageIntoToRefLayer();
                            }
                            break;
                        case "lassoOK":
                            {
                                LassoTool.applyLassoImageToCanvas();
                            }
                            break;
                        case "lassoCancel":
                            {
                                if (LassoTool.isLassoToolStarted === true)
                                {
                                    LassoTool.cancelLassoTool();
                                }
                            }
                            break;
                        case "lassoLayerMerge":
                            {
                                if (LassoTool.lassoMenuBox.lassoLayerMerge.alpha === 1.0)
                                {
                                    LassoTool.mergeLayerByLassoTool();
                                }
                            }
                            break;
                        case "lassoLayerSwap":
                            {
                                if (LassoTool.lassoMenuBox.lassoLayerSwap.alpha === 1.0)
                                {
                                    LassoTool.swapLayerByLassoTool();
                                }
                            }
                            break;
                        case "lasso1pxUp":
                            {
                                LassoTool.move1PxLassoTool(LassoTool.LASSO_1PX_MOVE_UP);
                            }
                            break;
                        case "lasso1pxDown":
                            {
                                LassoTool.move1PxLassoTool(LassoTool.LASSO_1PX_MOVE_DOWN);
                            }
                            break;
                        case "lasso1pxLeft":
                            {
                                LassoTool.move1PxLassoTool(LassoTool.LASSO_1PX_MOVE_LEFT);
                            }
                            break;
                        case "lasso1pxRight":
                            {
                                LassoTool.move1PxLassoTool(LassoTool.LASSO_1PX_MOVE_RIGHT);
                            }
                            break;
                        case "lassoCopy":
                            {
                                LassoTool.copyCanvasImageToLassoTool();
                            }
                            break;
                        case "lassoMirror":
                            {
                                LassoTool.isLassoMirrorON = !LassoTool.isLassoMirrorON;
                                LassoTool.lassoLayer1.scaleX = -LassoTool.lassoLayer1.scaleX;
                                LassoTool.lassoLayer2.scaleX = LassoTool.lassoLayer1.scaleX;
                                // 캔버스가 회전한각도도 있어서 항상 세로축을 중심으로 대칭되게 regpoint각도를 보정값으로 넣어줌
                                LassoTool.lassoLayer1.rotation = -LassoTool.lassoLayer1.rotation - (CanvasController.canvasAnchorPoint.rotation * 2);
                                LassoTool.lassoLayer2.rotation = LassoTool.lassoLayer1.rotation;
                            }
                            break;
                        case "layerMergeButton":
                            {
                                CanvasController.mergeImageIntoLayer2();
                                MainUI.showMouseHintTemp("Layers has been merged to layer 2");
                            }
                            break;
                        case "layerSwapButton":
                            {
                                CanvasController.swapLayer();
                                MainUI.showMouseHintTemp(getCanvasLayerSwappedHintString());
                            }
                            break;
                        default:
                            break;
                    }
                }
            }
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        }
        public function syncDrawCanvasWithReplayCanvas():void
        {
            CanvasController.canvasZoomMultipler = rCanvasZoomMultiplier;
            CanvasController.canvasZoomIndex = rCanvasZoomIndex;
            CanvasController.canvasAnchorPoint.x = Math.floor(rCanvasAnchorPoint.x); // 뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
            CanvasController.canvasAnchorPoint.y = Math.floor(rCanvasAnchorPoint.y);
            CanvasController.canvasAnchorPoint.scaleX = rCanvasAnchorPoint.scaleX;
            CanvasController.canvasAnchorPoint.scaleY = rCanvasAnchorPoint.scaleY;
            CanvasController.canvasAnchorPoint.rotation = rCanvasAnchorPoint.rotation;
            CanvasController.canvasPanel.x = Math.floor(rCanvasPanel.x);
            CanvasController.canvasPanel.y = Math.floor(rCanvasPanel.y);
            setRcursorRotation(rCanvasAnchorPoint.rotation);
        }
        public function ensureReplayCanvasState():void
        {
            const rNowFrameBackup:Number = rNowFrame;
            renderReplayFrame(0, JUMP_FRAME_MANUAL);
            renderReplayFrame(rNowFrameBackup, JUMP_FRAME_MANUAL);
            CanvasController.isCanvasMirrored = rMirrorON;
            mirrorCommandReady = false;
            CanvasController.canvasInfoBox.setMirror(rMirrorON);
        }
        public function deleteReplayDataBeforeCurrentFrame():void
        {
            // 미러 되어있을 수도 있기 때문에 워래 프레임 으로 점프해준뒤에 실행해줌
            ensureReplayCanvasState();
            MainUI.seekBarBox.setDeleteRangeBarVisible(false);
            createFirstImageCache(rCanvasLayer1BitmapData, rCanvasLayer2BitmapData, RCANVAS_BG_COLOR);
            const fs:FileStream = new FileStream();
            if (rDataReadFlag)
            {
                // repfile 초기화
                undoManager.updateUndoBaseImageFromReplayMode();
                fs.open(FileManager.replayDataFilePath, FileMode.WRITE); // 파일 생성
                fs.close();
                FileManager.isFileAlreadySaved = false;
                FileManager.enableNewFileButton();
                undoManager.setRFileTotalFrame(0);
                rData.splice(0, rDataIndex + 1);
                rDataFrame.splice(0, rDataIndex + 1);
                updateTotalFrameAndReplayMaxSpeedFor10Sec(getTotalFrame());
                updateReplayPrograssText(true, TOTAL_FRAME);
                if (TOTAL_FRAME === 0)
                {
                    MainUI.seekBarBox.resetReplayPrograssBarWidth();
                }
                else
                {
                    MainUI.seekBarBox.setReplayPrograssBarMaxWidth();
                }
                MainUI.topBar.repNewFileButton.alpha = Global.OFFALPHA;
                rReplayFOFOCursor.visible = false;
            }
            else
            {
                // make jumpimage에서 변경해주기 때문에
                if (repFileTemp.exists) // 이미 있으면 지워주고
                {
                    repFileTemp.deleteFile();
                }
                var ba:ByteArray = new ByteArray();
                var d:Array;
                // 짤라서 ba에 넣어주기
                fs.open(FileManager.replayDataFilePath, FileMode.READ);
                fs.position = rFileLastBytePosition;
                fs.readBytes(ba, 0, fs.bytesAvailable);
                fs.close();
                // ba에 넣어준걸 다시 써주기
                fs.open(FileManager.replayDataFilePath, FileMode.WRITE);
                fs.position = 0;
                fs.writeBytes(ba, 0, ba.length);
                fs.close();
                ba.clear();
                ba = null;
                rReplayFOFOCursor.visible = false;
                MainUI.seekBarBox.resetReplayPrograssBarWidth();
                FileManager.isFileAlreadySaved = false;
                startGeneratingReplayCacheImage();
            }
            resetReplaySpeedBar();
            isReplayFinished = true;
            if (undoDataIndex > rData.length - 1)
            {
                undoDataIndex = rData.length - 1;
            }
            undoToIndex(undoDataIndex);
            disableDeepUndo();
            updateReplayPrograssBarAndText();
            updateReplaySpeedSliderAlpha();
            drawReplayByCommand.setFirstRCursorPosCurrent();
            ReferenceLayerController.resetRefLayerImageTransform();
        }
        public function deleteReplayDataAfterCurrentFrame():void
        {
            ensureReplayCanvasState();
            MainUI.seekBarBox.setDeleteRangeBarVisible(false);
            if (rDataReadFlag === true)
            {
                // 위에서 setJumpOneFrame을 해줘서 rindex가 증가되었기 때문에
                // 실제 undo해줘야할 인덱스는 -1해줘야하는거임
                undoToIndex(rDataIndex);
                rData.splice(rDataIndex + 1);
                rDataFrame.splice(rDataIndex + 1);
                updateTotalFrameAndReplayMaxSpeedFor10Sec(getTotalFrame());
                resetReplayTime();
            }
            else if (rDataReadFlag === false)
            {
                drawReplayByCommand.setFirstRCursorPosCurrent();
                const fs:FileStream = new FileStream();
                fs.open(FileManager.replayDataFilePath, FileMode.UPDATE);
                fs.position = rFileLastBytePosition;
                fs.truncate(); // 데이터 위에 짤라주고
                fs.close();
                // 썸네일 이미지도 날려줌
                const rNowFrameSave:Number = rNowFrame;
                const list:Array = FileManager.replayCacheImageFolderPath.getDirectoryListing();
                const index:Number = getCachedFrameImageIndex(rNowFrameSave);
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
                undoManager.setRFileTotalFrame(rNowFrameSave);
                updateTotalFrameAndReplayMaxSpeedFor10Sec(rNowFrameSave);
                CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, rCanvasLayer1BitmapData, CanvasController.canvasLayer1Bitmap);
                CanvasController.canvasLayer1Bitmap.bitmapData = CanvasController.canvasLayer1BitmapData;
                CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, rCanvasLayer2BitmapData, CanvasController.canvasLayer2Bitmap);
                CanvasController.canvasLayer2Bitmap.bitmapData = CanvasController.canvasLayer2BitmapData;
                // mirrorON = rMirrorON;
                // mirrorCommandReady = false;
                // appInfoBox.setMirror(rMirrorON);
                CanvasController.updateCavnvasSizeDrawMode(CanvasController.canvasLayer1Bitmap.width, CanvasController.canvasLayer1Bitmap.height, 0, 0, false);
                ColorPickerController.updateCanvasBGColorDrawMode(RCANVAS_BG_COLOR);
                resetReplayTime();
                syncDrawCanvasWithReplayCanvas();
                resetUndoState();
                CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
                if (ImageViewWindow.isCanvasWindowON)
                {
                    ImageViewWindow.updateCanvasWindowImage();
                    ImageViewWindow.updateCanvasWindowBitmapSize();
                }
            }
            updateReplayPrograssBarAndText();
            updateReplaySpeedSliderAlpha();
            updateDeleteReplayDataButtonsState();
            resetReplaySpeedBar();
            disableDeepUndo();
            ReferenceLayerController.resetRefLayerImageTransform();
            if (SidebarController.isQuickSidebarActive)
            {
                SidebarController.deactivateQuickSidebar();
            }
            FileManager.isContinueSaveON = false;
        }
        public function createNewFileFromReplayCanvas():void
        {
            MainUI.seekBarBox.setDeleteRangeBarVisible(false);
            copyReplayCanvasDataToDrawCanvas();
            clearDataAndResetVars();
            syncDrawCanvasWithReplayCanvas();
            exitReplayMode();
            disableDeepUndo();
            resetReplayTime();
            ReferenceLayerController.resetRefLayerImageTransform();
        }
        // addundo data에서 캔버스 비트맵 데이터가 변경되기 전, rdatabuffer 비어있을때 넣어줘야함
        public function applyDeepUndo():void
        {
            const fs:FileStream = new FileStream();
            fs.open(FileManager.replayDataFilePath, FileMode.UPDATE);
            fs.position = rFileLastBytePosition;
            fs.truncate(); // 데이터 위에 짤라주고
            fs.close();
            // 썸네일 이미지도 날려줌
            const rNowFrameSave:Number = rNowFrame;
            const list:Array = FileManager.replayCacheImageFolderPath.getDirectoryListing();
            const index:Number = getCachedFrameImageIndex(rNowFrameSave);
            const len:uint = list.length;
            // index번 이후 파일 삭제
            for (var i:uint = 0;i < len;i++)
            {
                if (parseInt(list[i].name) > index)
                {
                    list[i].deleteFile();
                }
            }
            // framedata도 인덱스 이후꺼 날려줌
            rJumpImageFrameData.splice(index + 1);
            undoManager.setRFileTotalFrame(rNowFrameSave);
            updateTotalFrameAndReplayMaxSpeedFor10Sec(rNowFrameSave);
            resetReplayTime();
            resetUndoState(true);
            rReplayFOFOCursor.visible = true; // 대칭된 커서 위치를 갱신해주려고 임시로 켜줌
            // checkMirrorCanvasReplayMirror();
            CanvasController.canvasInfoBox.setMirror(CanvasController.isCanvasMirrored);
            drawReplayByCommand.setFirstRCursorPosCurrent();
            rReplayFOFOCursor.visible = false;
            CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
            disableDeepUndo();
        }
        public function prepareDeleteReplayData(mode:String):Boolean
        {
            if (mode !== "total")
            {
                if (drawReplayByCommand.getCurrentPosition() < drawReplayByCommand.getDataLength())
                {
                    finalizeRemainingReplayData();
                    updateReplayPrograssText();
                    MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(rNowFrame / TOTAL_FRAME);
                    updateDeleteReplayDataButtonsState();
                }
                if (rNowFrame >= TOTAL_FRAME)
                {
                    MainUI.seekBarBox.setDeleteRangeBarVisible(false);
                    return true;
                }
            }
            MainUI.seekBarBox.updateDeleteDangeBarPosWidth(mode);
            return false;
        }
        public function initializeReplayDataFile(overWrite:Boolean = false):void // 기본 리플레이 파일 만들어줌
        {
            FileManager.initializeRepTempFile();
            if (FileManager.replayDataFilePath.exists === false || overWrite === true)
            {
                const fs:FileStream = new FileStream();
                fs.open(FileManager.replayDataFilePath, FileMode.WRITE);
                fs.close();
                createFirstImageCache(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
            }
        }
        public function drawFirstJumpImage():void
        {
            const fs:FileStream = new FileStream();
            const file:File = FileManager.replayCacheImageFolderPath.resolvePath("0");
            fs.open(file, FileMode.READ);
            const data:Array = fs.readObject() as Array;
            fs.close();
            data[0].uncompress();
            data[1].uncompress();
            var layer1:BitmapData = new BitmapData(data[2], data[3], true, 0);
            var layer2:BitmapData = new BitmapData(data[2], data[3], true, 0);
            const newRectangle:Rectangle = new Rectangle(0, 0, data[2], data[3]);
            layer1.lock();
            layer1.setPixels(newRectangle, data[0]);
            layer1.unlock();
            layer2.lock();
            layer2.setPixels(newRectangle, data[1]);
            layer2.unlock();
            rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, layer1, rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, layer2, rCanvasLayer2Bitmap);
            layer1.dispose();
            layer2.dispose();
            layer1 = null;
            layer2 = null;
            updateCanvasSizeReplayMode(rCanvasLayer1Bitmap.width, rCanvasLayer1Bitmap.height);
            updateCanvasBGColorReplayMode(data[4]);
        }
        public function createFirstImageCache(bmpd1:BitmapData, bmpd2:BitmapData, bgColor:uint):void
        {
            if (FileManager.replayCacheImageFolderPath.exists)
            {
                FileManager.replayCacheImageFolderPath.deleteDirectory(true);
            }
            FileManager.replayCacheImageFolderPath.createDirectory();
            const fs:FileStream = new FileStream();
            var ba1:ByteArray = new ByteArray();
            var ba2:ByteArray = new ByteArray();
            const w:Number = bmpd1.width;
            const h:Number = bmpd1.height;
            const newRectangle:Rectangle = new Rectangle(0, 0, w, h);
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
            createCacheImage(ba1, ba2, w, h, bgColor, 0, 0, false);
            ba1.clear();
            ba2.clear();
        }
        public function resetUndoState(fromReplayMode:Boolean = false):void
        {
            undoDataIndex = -1;
            if (fromReplayMode)
            {
                undoManager.updateUndoBaseImageFromReplayMode();
            }
            else
            {
                undoManager.updateUndoBaseImageFromDrawMode();
            }
            undoManager.resetRJumpImageCount();
            rData = [];
            rDataFrame = [];
            rDataBuffer = [];
            canAddUndoData = false;
            isDeleteUndoDataPending = false;
            rReplayFOFOCursor.visible = false;
            isDeepUndoEnabled = false;
        }
        public function fitCanvasToViewportMargin(fitting:Boolean = false):void
        {
            if (!isReplayModeON && !CaptureController.isCaptureModeON)
            {
                return;
            }
            const uiscale:Number = Global.getUIScale();
            const offsetX:Number = 44 + MainUIController.STAGE_LEFT_OFFSET + MainUIController.STAGE_RIGHT_OFFSET;
            const offsetY:Number = (CaptureController.isCaptureModeON) ? (MainUI.topBar.BARSIZE) * uiscale + 42 * uiscale : (MainUI.topBar.BARSIZE) * uiscale + 42 * uiscale;
            const stw:int = stage.stageWidth - offsetX;
            const sth:int = stage.stageHeight - offsetY - MainUIController.STAGE_BOTTOM_OFFSET;
            var xBitmap1:Bitmap;
            var xBitmap11:Bitmap;
            var xAnc:Sprite;
            var canvasWidth:Number;
            var canvasHeight:Number;
            if (isReplayModeON)
            {
                xBitmap1 = rCanvasLayer1Bitmap;
                xBitmap11 = rCanvasLayer2Bitmap;
                xAnc = rCanvasAnchorPoint;
                if (fitting)
                {
                    xAnc.scaleX = 1.0;
                    xAnc.scaleY = 1.0; // 크기를 원래대로 해놓고 해야 길이 측정이 됨
                    const b:Rectangle = rCanvasLayer1Bitmap.getBounds(stage);
                    canvasWidth = b.right - b.left;
                    canvasHeight = b.bottom - b.top;
                }
                else
                {
                    canvasWidth = RCANVAS_WIDTH;
                    canvasHeight = RCANVAS_HEIGHT;
                }
            }
            else
            {
                xBitmap1 = CanvasController.canvasLayer1Bitmap;
                xBitmap11 = CanvasController.canvasLayer2Bitmap;
                xAnc = CanvasController.canvasAnchorPoint;
                canvasWidth = CanvasController.CANVAS_WIDTH;
                canvasHeight = CanvasController.CANVAS_HEIGHT;
            }
            if (CaptureController.isCaptureModeON)
            {
                if (CaptureController.captureCanvasRotationStep === 1 || CaptureController.captureCanvasRotationStep === 3)
                {
                    const widthSave:Number = canvasWidth;
                    canvasWidth = canvasHeight;
                    canvasHeight = widthSave;
                }
            }
            const scaleW:Number = stw / canvasWidth;
            const scaleH:Number = sth / canvasHeight;
            var scale:Number = Math.min(scaleW, scaleH);
            if (!fitting && scale > 1.0)
            {
                scale = 1.0;
            }
            if (CaptureController.isCaptureModeON)
            {
                xAnc.rotation = 90 * CaptureController.captureCanvasRotationStep;
            }
            if (isReplayModeON && !isReplayCanvasFitToWindow)
            {
                isReplayFinishedWithFiwWindow = true;
            }
            if (CaptureController.isCaptureModeON)
            {
                CanvasController.updateCanvasScale(scale, isReplayModeON);
                CanvasController.centerCanvas("capture");
            }
            else if (isReplayModeON)
            {
                CanvasController.updateCanvasScale(scale, isReplayModeON);
                CanvasController.centerCanvas("replay");
            }
            if (!fitting || isReplayFinished)
            {
                xBitmap1.smoothing = true;
                xBitmap11.smoothing = true;
            }
        }
        public function setReplayCompleteCanvasCenter():void
        {
            rCanvasCompleteAnchorPoint.width = stage.stageWidth + 200;
            rCanvasCompleteAnchorPoint.height = stage.stageHeight + 200;
            rCanvasCompleteAnchorPoint.x = stage.stageWidth / 2;
            rCanvasCompleteAnchorPoint.y = stage.stageHeight / 2;
            rCanvasCompleteBitmap.x = -rCanvasCompleteBitmap.width / 2;
            rCanvasCompleteBitmap.y = -rCanvasCompleteBitmap.height / 2;
        }
        public function hideCompleteImageToBGReplayMode():void
        {
            if (MainUI.stageBG.getChildByName("rCanvasCompleteAnchorPoint"))
            {
                MainUI.stageBG.removeChild(rCanvasCompleteAnchorPoint);
            }
            if (rCanvasCompleteBitmap.bitmapData)
            {
                rCanvasCompleteBitmap.bitmapData.dispose();
            }
            rCanvasCompleteBitmap.filters = [];
            rCanvasPanel.filters = [];
        }
        public function showCompleteImageToBGReplayMode():void
        {
            const mergedbmpd:BitmapData = CanvasController.getMergedBitmapdtata(false, true, true, null);
            const tmpbmpd:BitmapData = new BitmapData(mergedbmpd.width / 2, mergedbmpd.height / 2, false, 0);
            const mat:Matrix = new Matrix();
            mat.scale(0.5, 0.5);
            var alpha:ColorTransform = new ColorTransform(1, 1, 1, 0.8);
            tmpbmpd.draw(mergedbmpd, mat, alpha);
            rCanvasCompleteBitmap.bitmapData = tmpbmpd;
            rCanvasCompleteBitmap.filters = [new BlurFilter(15, 15, 3)];
            setReplayCompleteCanvasCenter();
            var glow:GlowFilter = new GlowFilter();
            glow.color = 0xFFFFFF; // 빨간색 테두리
            glow.alpha = 0.5;
            glow.blurX = 20;
            glow.blurY = 20;
            glow.strength = 2;
            glow.quality = 3;
            rCanvasPanel.filters = [glow];
            MainUI.stageBG.addChild(rCanvasCompleteAnchorPoint);
        }
        public function replayCompleteEffect():void
        {
            fitCanvasToViewportMargin(isReplayCanvasFitToWindow);
            CanvasController.applyCanvasFlashEffect(rCanvasPanel, 0, 0, RCANVAS_WIDTH, RCANVAS_HEIGHT, function ():Boolean
                {
                    return MainUI.topBar.visible;
                });
        }
        public function cancelReplayRestartTimer():void
        {
            MainUI.seekBarBox.setPlayButtonVisible(true);
            hideCompleteImageToBGReplayMode();
            MainUI.showTopbarOnReplayEnd();
            FOFOTimer.remove("replayRestartTimer");
            updateReplayPrograssText(true, TOTAL_FRAME);
            Global.setColorTransform(MainUI.seekBarBox.prograssBar, Global.getUIReplayEndBarColor());
            CanvasController.updateCanvasScale(rLastCanvasZoomMultiplier, true);
        }
        public function isReplayRestartTimerON():Boolean
        {
            return FOFOTimer.hasTimer("replayRestartTimer");
        }
        public function startReplayRestartTimer():void
        {
            Global.setColorTransform(MainUI.seekBarBox.prograssBar, Global.getUIReplayRestartBarColor());
            if (isReplayRepeatON)
            {
                rReplayRestartTimerCount = 20;
                FOFOTimer.addByName("replayRestartTimer", 1.0, true, function ():Boolean
                    {
                        if (rReplayRestartTimerCount === 0)
                        {
                            cancelReplayRestartTimer();
                            handleReplayStartButton();
                            return false;
                        }
                        MainUI.seekBarBox.prograssInfo.text = HintStrings.getReplayRestartHintString(rReplayRestartTimerCount);
                        --rReplayRestartTimerCount;
                        return true;
                    });
            }
            else
            {
                rReplayRestartTimerCount = 0;
                updateReplayPrograssText(true, TOTAL_FRAME);
            }
        }
        public function resetReplaySpeedBar():void
        {
            rReplaySpeedMultipler = 1.0; // 속도 리셋
            MainUI.topBar.replaySpeedSliderCursor.x = MainUI.topBar.replaySpeedSlider.x + 1.5;
        }
        // total frame file max frame등등은 수동으로 초기화
        // 이건 리플레이 시간을 초기화 시켜주는것 뿐임 데이터는 건드리지 않음
        public function resetReplayTime():void
        {
            // 어떤 이유가 있어서 rDataReadFlag는 여기 넣으면 안됨 수동으로 조절
            rDataIndex = 0;
            rDataStartIndex = 0;
            rFileLastBytePosition = 0;
            rNowFrame = 0;
            rPrevFrame = 0;
            rJumpImageIndexLast = -2;
            rJumpImageNowFrameLast = -1;
            rTempCachedLastImageIndex = -2;
            isReplayFinished = true;
            isReplaySlideShowMode = false;
            drawReplayByCommand.clearData();
        }

        public function selectReplaySubLayer(flag:Boolean):void
        {
            rLastLayer2Selcted = flag;
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
        public function moveImageReplayMode(x:Number, y:Number, layer1:Boolean, layer2:Boolean):void
        {
            var tmpbmpd:BitmapData = new BitmapData(RCANVAS_WIDTH, RCANVAS_HEIGHT, true, 0);
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
                rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, tmpbmpd, rCanvasLayer1Bitmap);
            }
            if (layer2)
            {
                tmpbmpd.fillRect(new Rectangle(0, 0, RCANVAS_WIDTH, RCANVAS_HEIGHT), 0);
                tmpbmpd.draw(rCanvasLayer2BitmapData, movedMat);
                rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, tmpbmpd, rCanvasLayer2Bitmap);
            }
            tmpbmpd.dispose();
            tmpbmpd = null;
        }
        public function replayLineStyleReady(shape:Boolean, size:uint, color:uint, alpha:Number):void
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
        public function replayLineStyleReady2(shape:Boolean, size:uint, color:uint, alpha:Number):void
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
        public function replayLineStyleReady3(shape:Boolean, size:uint, color:uint, alpha:Number):void
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
        public function mirrorCanvasReplayMode():void
        {
            var tmpbmpd:BitmapData = new BitmapData(RCANVAS_WIDTH, RCANVAS_HEIGHT, true, 0);
            var flipMat:Matrix = new Matrix(-1, 0, 0, 1, RCANVAS_WIDTH);
            tmpbmpd.draw(rCanvasLayer1BitmapData, flipMat);
            rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, tmpbmpd, rCanvasLayer1Bitmap);
            tmpbmpd.fillRect(new Rectangle(0, 0, RCANVAS_WIDTH, RCANVAS_HEIGHT), 0);
            tmpbmpd.draw(rCanvasLayer2BitmapData, flipMat);
            rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, tmpbmpd, rCanvasLayer2Bitmap);
            tmpbmpd.dispose();
            tmpbmpd = null;
            rMirrorON = !rMirrorON;
            if (isReplayCanvasFitToWindow)
            {
                fitReplayCanvasToViewport();
            }
        }
        public function cDrawReplayDataCommands():Object
        {
            const rCursorPos:Point = new Point(0, 0);
            // undo인덱스가 처음일때 tickdraw가 아무것도 안해주니까 위치 갱신이 안되서
            // undorefimage갱신 될때 마다 마지막 포인터 위치 저장해주는거
            const rCursorPosFirst:Point = new Point(-1, -1);
            var lineStyleBackup:Array = [1.0, null];
            // tempdone에서 쓰는 플래그임
            var index:uint = 0;
            var data:Array = []; // 데이터 뭉치
            const cmd:Vector.<int> = new Vector.<int>();
            const pos:Vector.<Number> = new Vector.<Number>();
            function updateLineStyleBackup(alpha:Number, blendMode:String):void
            {
                lineStyleBackup[0] = alpha;
                lineStyleBackup[1] = blendMode;
            }
            function getFirstRCursorPos():Point
            {
                return rCursorPosFirst;
            }
            function resetFirstRCursorPos():void
            {
                rCursorPosFirst.setTo(-1, -1);
            }
            function setFirstRCursorPos(x:Number, y:Number):void
            {
                rCursorPosFirst.setTo(x, y);
            }
            function setFirstRCursorPosCurrent():void
            {
                rCursorPosFirst.setTo(rCursorPos.x, rCursorPos.y);
            }
            function hasRCursorFirstPos():Boolean
            {
                return rCursorPosFirst.x > 0 && rCursorPosFirst.y > 0;
            }
            function updateRCursorPosToFirst():void
            {
                rReplayFOFOCursor.x = rCursorPosFirst.x;
                rReplayFOFOCursor.y = rCursorPosFirst.y;
            }
            function updateRCursorPos():void
            {
                rReplayFOFOCursor.x = rCursorPos.x;
                rReplayFOFOCursor.y = rCursorPos.y;
            }
            function setRCursorPosFromMoveTool(x:Number, y:Number):void
            {
                setRCursorPos(rCursorPos.x + x, rCursorPos.y + y);
            }
            function setRCursorPosToCenter():void
            {
                setRCursorPos(RCANVAS_WIDTH / 2, RCANVAS_HEIGHT / 2);
            }
            function setRCursorPos(x:Number, y:Number):void
            {
                if (x < 0)
                    x = 0;
                else if (x > RCANVAS_WIDTH)
                    x = RCANVAS_WIDTH;
                if (y < 0)
                    y = 0;
                else if (y > RCANVAS_HEIGHT)
                    y = RCANVAS_HEIGHT;
                rCursorPos.setTo(x, y);
            }
            function getRCursorPos():Point
            {
                return rCursorPos;
            }
            function clearData():void
            {
                data = [];
                index = 0;
            }
            function setData(refData:Array, startIndex:uint = 0):void
            {
                data = refData;
                index = startIndex;
            }
            function getRemainingData():uint
            {
                if (!data)
                    return 0;
                return data.length - index;
            }
            function isReadFinished():Boolean
            {
                if (!data)
                    return true;
                return index > data.length - 1;
            }
            function getDataLength():uint
            {
                if (!data)
                    return 0;
                return data.length;
            }
            function getCurrentPosition():uint
            {
                return index;
            }
            function setIndex(newIndex:uint):void
            {
                index = newIndex;
            }
            function getLineStyleAlpha():Number
            {
                return lineStyleBackup[0];
            }
            function getrLineStyleSave():Array
            {
                if (lineStyleBackup.length !== 2)
                    return [1.0, null];
                return lineStyleBackup;
            }
            function drawAll():void
            {
                var len:uint = data.length;
                for (var i:uint = 0;i < len;i++)
                {
                    drawNext();
                }
            }
            function checkAirBrush(airBrushFlag:Boolean, size:uint):void
            {
                if (airBrushFlag === true)
                {
                    if (rAirBrushSize !== size)
                        blurReplayCanvasByValue(size);
                }
                else if (rAirBrushSize > 0)
                {
                    resetBlurReplayCanvas();
                }
            }
            function checkSubLayer(subLayerFlag:Boolean):void
            {
                if (subLayerFlag)
                {
                    // if((replayStartON && subLayerFlag) !== false && rSubLayerSave !== subLayerFlag)
                    if (rLastLayer2Selcted !== subLayerFlag)
                    {
                        selectReplaySubLayer(subLayerFlag);
                    }
                }
                else if (rLastLayer2Selcted)
                {
                    selectReplaySubLayer(false);
                }
            }
            function lineStyle5(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const fillpen:Boolean = data[8];
                const subLayer:Boolean = data[9];
                const airBrushSize:Number = data[10];
                updateLineStyleBackup(alpha, blendMode);
                checkSubLayer(subLayer);
                rAirBrushSize2 = airBrushSize;
                if (fillpen)
                {
                    rCanvasDrawShape.graphics.clear();
                    replayLineStyleReady2(false, 1, color, 1.0);
                    rCanvasDrawShape.graphics.beginFill(color);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                    rCanvasDrawLayer.alpha = alpha;
                }
                else
                {
                    replayLineStyleReady3(shape, size, color, alpha);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                }
                if (index === 0)
                {
                    CanvasController.resetRCanvasDrawLayerCliprect2();
                }
                else
                {
                    updateRCanvasDrawLayerCliprect2();
                }
            }
            function lineStyle4(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const fillpen:Boolean = data[8];
                const subLayer:Boolean = data[9];
                const airBrush:Boolean = data[10];
                updateLineStyleBackup(alpha, blendMode);
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                if (fillpen)
                {
                    rCanvasDrawShape.graphics.clear();
                    replayLineStyleReady2(false, 1, color, 1.0);
                    rCanvasDrawShape.graphics.beginFill(color);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                    rCanvasDrawLayer.alpha = alpha;
                }
                else
                {
                    replayLineStyleReady3(shape, size, color, alpha);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                }
                if (index === 0)
                {
                    CanvasController.resetRCanvasDrawLayerCliprect();
                }
                else
                {
                    CanvasController.updateRCanvasDrawLayerCliprect();
                }
            }
            function lineStyle3(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const fillpen:Boolean = data[8];
                const subLayer:Boolean = data[9];
                const airBrush:Boolean = data[10];
                updateLineStyleBackup(alpha, blendMode);
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                if (!fillpen)
                {
                    replayLineStyleReady3(shape, size, color, alpha);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                }
                else
                {
                    rCanvasDrawShape.graphics.clear();
                    replayLineStyleReady2(false, 1, color, 1.0);
                    rCanvasDrawShape.graphics.beginFill(color);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                    rCanvasDrawLayer.alpha = alpha;
                }
            }
            function lineStyle2(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const fillpen:Boolean = data[8];
                const subLayer:Boolean = data[9];
                const airBrush:Boolean = data[10];
                updateLineStyleBackup(alpha, blendMode);
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                if (!fillpen)
                {
                    replayLineStyleReady2(shape, size, color, alpha);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                }
                else
                {
                    rCanvasDrawShape.graphics.clear();
                    replayLineStyleReady2(false, 1, color, 1.0);
                    rCanvasDrawShape.graphics.beginFill(color);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                    rCanvasDrawLayer.alpha = alpha;
                }
            }
            function lineStyle(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const fillpen:Boolean = data[8];
                const subLayer:Boolean = data[9];
                const airBrush:Boolean = data[10];
                updateLineStyleBackup(alpha, blendMode);
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                if (!fillpen)
                {
                    replayLineStyleReady(shape, size, color, alpha);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                }
                else
                {
                    rCanvasDrawShape.graphics.clear();
                    replayLineStyleReady(false, 1, color, 1.0);
                    rCanvasDrawShape.graphics.beginFill(color);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                    rCanvasDrawLayer.alpha = alpha;
                }
            }
            function lineTo(data:Array):void
            {
                const x:Number = data[1];
                const y:Number = data[2];
                rCanvasDrawShape.graphics.lineTo(x, y);
                setRCursorPos(x, y);
            }
            function sqline(data:Array):void
            {
                const size:Number = data[1];
                const color:Number = data[2];
                const alpha:Number = data[3];
                const blendMode:String = data[4];
                const command:Vector.<int> = data[5];
                const xyData:Vector.<Number> = data[6];
                rCanvasDrawLayerBitmap.bitmapData = null;
                rCanvasDrawLayerBitmapData.dispose();
                rCanvasDrawLayerBitmapData = new BitmapData(RCANVAS_WIDTH, RCANVAS_HEIGHT, true, 0);
                rCanvasDrawShape.graphics.clear();
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.SQUARE, JointStyle.ROUND);
                rCanvasDrawShape.graphics.drawPath(command, xyData);
                setRCursorPos(xyData[xyData.length - 2], xyData[xyData.length - 1]);
            }
            function fill5(data:Array):void
            {
                const color:Number = data[1];
                const alpha:Number = data[2];
                const blendMode:String = data[3];
                const command:Vector.<int> = data[4];
                const xyData:Vector.<Number> = data[5];
                const airBrushFlag:Boolean = data[6];
                const airBrushSize:uint = data[7];
                rAirBrushSize2 = airBrushSize;
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.clear();
                rCanvasDrawShape.graphics.lineStyle(1, color);
                rCanvasDrawShape.graphics.beginFill(color);
                rCanvasDrawShape.graphics.drawPath(command, xyData);
                setRCursorPos(xyData[xyData.length - 2], xyData[xyData.length - 1]);
                CanvasController.resetRCanvasDrawLayerCliprect2();
            }
            function fill4(data:Array):void
            {
                const color:Number = data[1];
                const alpha:Number = data[2];
                const blendMode:String = data[3];
                const command:Vector.<int> = data[4];
                const xyData:Vector.<Number> = data[5];
                const airBrushFlag:Boolean = data[6];
                const airBrushSize:uint = data[7];
                checkAirBrush(airBrushFlag, airBrushSize);
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.clear();
                rCanvasDrawShape.graphics.lineStyle(1, color);
                rCanvasDrawShape.graphics.beginFill(color);
                rCanvasDrawShape.graphics.drawPath(command, xyData);
                setRCursorPos(xyData[xyData.length - 2], xyData[xyData.length - 1]);
                CanvasController.resetRCanvasDrawLayerCliprect();
            }
            function fill3(data:Array):void
            {
                const color:Number = data[1];
                const alpha:Number = data[2];
                const blendMode:String = data[3];
                const command:Vector.<int> = data[4];
                const xyData:Vector.<Number> = data[5];
                const airBrushFlag:Boolean = data[6];
                const airBrushSize:uint = data[7];
                checkAirBrush(airBrushFlag, airBrushSize);
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.clear();
                rCanvasDrawShape.graphics.lineStyle(1, color);
                rCanvasDrawShape.graphics.beginFill(color);
                rCanvasDrawShape.graphics.drawPath(command, xyData);
                setRCursorPos(xyData[xyData.length - 2], xyData[xyData.length - 1]);
            }
            function fill2(data:Array):void
            {
                const color:Number = data[1];
                const alpha:Number = data[2];
                const blendMode:String = data[3];
                const arr:Vector.<Number> = data[4];
                const len:uint = arr.length;
                resetBlurReplayCanvas();
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.clear();
                rCanvasDrawShape.graphics.lineStyle(1, color);
                rCanvasDrawShape.graphics.beginFill(color);
                rCanvasDrawShape.graphics.moveTo(arr[0], arr[1]);
                for (var i:uint = 2;i < len;i += 2)
                {
                    rCanvasDrawShape.graphics.lineTo(arr[i], arr[i + 1]);
                }
                rCanvasDrawShape.graphics.endFill();
                setRCursorPos(arr[len - 2], arr[len - 1]);
            }
            function fill(data:Array):void
            {
                const color:Number = data[1];
                const alpha:Number = data[2];
                const blendMode:String = data[3];
                const command:Vector.<int> = data[4];
                const xyData:Vector.<Number> = data[5];
                resetBlurReplayCanvas();
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.clear();
                rCanvasDrawShape.graphics.lineStyle(1, color);
                rCanvasDrawShape.graphics.beginFill(color);
                rCanvasDrawShape.graphics.drawPath(command, xyData);
                setRCursorPos(xyData[xyData.length - 2], xyData[xyData.length - 1]);
            }
            function dot4(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const subLayer:Boolean = data[8];
                const airBrushSize:Number = data[9];
                const rotation:Number = data[10];
                checkSubLayer(subLayer);
                rAirBrushSize2 = airBrushSize;
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.lineStyle(0, 0, 0);
                rCanvasDrawShape.graphics.beginFill(color);
                if (shape)
                {
                    cmd.length = 0;
                    pos.length = 0;
                    const halfSize:Number = size / 2;
                    var point:Point = Utils.rotatePoint(-halfSize, -halfSize, rotation);
                    cmd.push(1);
                    pos.push(startX + point.x);
                    pos.push(startY + point.y);
                    point = Utils.rotatePoint(halfSize, -halfSize, rotation);
                    cmd.push(2);
                    pos.push(startX + point.x);
                    pos.push(startY + point.y);
                    point = Utils.rotatePoint(halfSize, halfSize, rotation);
                    cmd.push(2);
                    pos.push(startX + point.x);
                    pos.push(startY + point.y);
                    point = Utils.rotatePoint(-halfSize, halfSize, rotation);
                    cmd.push(2);
                    pos.push(startX + point.x);
                    pos.push(startY + point.y);
                    rCanvasDrawShape.graphics.drawPath(cmd, pos);
                    point = null;
                }
                else
                {
                    rCanvasDrawShape.graphics.drawCircle(startX, startY, size / 2);
                }
                rCanvasDrawShape.graphics.endFill();
                CanvasController.resetRCanvasDrawLayerCliprect2();
                setRCursorPos(startX, startY);
            }
            function dot3(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const subLayer:Boolean = data[8];
                const airBrush:Boolean = data[9];
                const rotation:Number = data[10];
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.lineStyle(0, 0, 0);
                rCanvasDrawShape.graphics.beginFill(color);
                if (shape)
                {
                    cmd.length = 0;
                    pos.length = 0;
                    const p0:Point = Utils.rotatePoint(-size / 2, -size / 2, rotation);
                    cmd.push(1);
                    pos.push(startX + p0.x);
                    pos.push(startY + p0.y);
                    const p1:Point = Utils.rotatePoint(+size / 2, -size / 2, rotation);
                    cmd.push(2);
                    pos.push(startX + p1.x);
                    pos.push(startY + p1.y);
                    const p2:Point = Utils.rotatePoint(+size / 2, +size / 2, rotation);
                    cmd.push(2);
                    pos.push(startX + p2.x);
                    pos.push(startY + p2.y);
                    const p3:Point = Utils.rotatePoint(-size / 2, +size / 2, rotation);
                    cmd.push(2);
                    pos.push(startX + p3.x);
                    pos.push(startY + p3.y);
                    rCanvasDrawShape.graphics.drawPath(cmd, pos);
                }
                else
                {
                    rCanvasDrawShape.graphics.drawCircle(startX, startY, size / 2);
                }
                rCanvasDrawShape.graphics.endFill();
                CanvasController.resetRCanvasDrawLayerCliprect();
                setRCursorPos(startX, startY);
            }
            function dot2(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const subLayer:Boolean = data[8];
                const airBrush:Boolean = data[9];
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.lineStyle(0, 0, 0);
                rCanvasDrawShape.graphics.beginFill(color);
                if (shape)
                    rCanvasDrawShape.graphics.drawRect(startX - size / 2, startY - size / 2, size, size);
                else
                    rCanvasDrawShape.graphics.drawCircle(startX, startY, size / 2);
                rCanvasDrawShape.graphics.endFill();
                CanvasController.resetRCanvasDrawLayerCliprect();
                setRCursorPos(startX, startY);
            }
            function dot(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const subLayer:Boolean = data[8];
                const airBrush:Boolean = data[9];
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.lineStyle(0, 0, 0);
                rCanvasDrawShape.graphics.beginFill(color);
                if (shape)
                    rCanvasDrawShape.graphics.drawRect(startX - size / 2, startY - size / 2, size, size);
                else
                    rCanvasDrawShape.graphics.drawCircle(startX, startY, size / 2);
                rCanvasDrawShape.graphics.endFill();
                setRCursorPos(startX, startY);
            }
            function line3(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const endX:Number = data[7];
                const endY:Number = data[8];
                const blendMode:String = data[9];
                const subLayer:Boolean = data[10];
                const airBrushSize:Number = data[11];
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                checkSubLayer(subLayer);
                rAirBrushSize2 = airBrushSize;
                if (shape)
                    rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND);
                else
                    rCanvasDrawShape.graphics.lineStyle(size, color);
                rCanvasDrawShape.graphics.moveTo(startX, startY);
                rCanvasDrawShape.graphics.lineTo(endX, endY);
                CanvasController.resetRCanvasDrawLayerCliprect2();
                setRCursorPos(endX, endY);
            }
            function line2(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const endX:Number = data[7];
                const endY:Number = data[8];
                const blendMode:String = data[9];
                const subLayer:Boolean = data[10];
                const airBrush:Boolean = data[11];
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                if (shape)
                    rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND);
                else
                    rCanvasDrawShape.graphics.lineStyle(size, color);
                rCanvasDrawShape.graphics.moveTo(startX, startY);
                rCanvasDrawShape.graphics.lineTo(endX, endY);
                CanvasController.resetRCanvasDrawLayerCliprect();
                setRCursorPos(endX, endY);
            }
            function line1(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const endX:Number = data[7];
                const endY:Number = data[8];
                const blendMode:String = data[9];
                const subLayer:Boolean = data[10];
                const airBrush:Boolean = data[11];
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                if (shape)
                    rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND);
                else
                    rCanvasDrawShape.graphics.lineStyle(size, color);
                rCanvasDrawShape.graphics.moveTo(startX, startY);
                rCanvasDrawShape.graphics.lineTo(endX, endY);
                setRCursorPos(endX, endY);
            }
            function line(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const endX:Number = data[7];
                const endY:Number = data[8];
                const blendMode:String = data[9];
                const subLayer:Boolean = data[10];
                const airBrush:Boolean = data[11];
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                if (shape)
                    rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.SQUARE, JointStyle.ROUND);
                else
                    rCanvasDrawShape.graphics.lineStyle(size, color);
                rCanvasDrawShape.graphics.moveTo(startX, startY);
                rCanvasDrawShape.graphics.lineTo(endX, endY);
                setRCursorPos(endX, endY);
            }
            function move1(data:Array):void
            {
                moveImageReplayMode(data[1], data[2], true, false);
                setRCursorPosFromMoveTool(data[1], data[2]);
            }
            function move2(data:Array):void
            {
                moveImageReplayMode(data[1], data[2], false, true);
                setRCursorPosFromMoveTool(data[1], data[2]);
            }
            function move(data:Array):void
            {
                moveImageReplayMode(data[1], data[2], true, true);
                setRCursorPosFromMoveTool(data[1], data[2]);
            }
            function resetLassoVars():void
            {
                LassoTool.lassoLayer1Bitmap.filters = [];
                LassoTool.lassoLayer2Bitmap.filters = [];
                if (LassoTool.lassoLayer1Bitmap.bitmapData)
                    LassoTool.lassoLayer1Bitmap.bitmapData.dispose();
                if (LassoTool.lassoLayer2Bitmap.bitmapData)
                    LassoTool.lassoLayer2Bitmap.bitmapData.dispose();
                LassoTool.lassoLayer1.x = 0;
                LassoTool.lassoLayer1.y = 0;
                LassoTool.lassoLayer1.scaleX = 1.0;
                LassoTool.lassoLayer1.scaleY = 1.0;
                LassoTool.lassoLayer1.rotation = 0;
                LassoTool.lassoLayer1.visible = false;
                LassoTool.lassoLayer2.x = 0;
                LassoTool.lassoLayer2.y = 0;
                LassoTool.lassoLayer2.scaleX = 1.0;
                LassoTool.lassoLayer2.scaleY = 1.0;
                LassoTool.lassoLayer2.rotation = 0;
                LassoTool.lassoLayer2.visible = false;
            }
            // 성능 문제로 샤픈 안해줌
            function lasso2(data:Array, clearOnly:Boolean):void
            {
                if (data[1].length === 0 || data[2].length === 0)
                    return;
                var imageMovedToLasso:Boolean;
                if (data.length <= 5)
                {
                    if (data[3] === null || (data[3] is Array && data[3].length === 0))
                    {
                        // (["lasso",point1,point2,null,lassoInfo]); 초기 버전 데이터 구조 3번이 비어있음
                        // (["lasso",point1,point2,[],lassoInfo]);
                        imageMovedToLasso = LassoTool.moveSelectedAreaToLassoBox(true, data[1], data[2], false, true, true);
                    }
                    else if (data[3].length === 7)
                    {
                        // (["lasso",point1,point2,lassoInfo]); 2019년판 구버전
                        // (["lasso",point1,point2,lassoInfo,lassoCopyON])
                        imageMovedToLasso = LassoTool.moveSelectedAreaToLassoBox(true, data[1], data[2], data[4], true, true);
                    }
                }
                else
                {
                    // (["lasso",point1,point2,lassoInfo,lassoCopyON,canvas1Bitmap.visible,canvas11Bitmap.visible,lassoLayerSwappedFlag]); 신버전 데이터 길이가 6이상임
                    // ["lasso",point1,point2,lassoInfo,lassoCopyON,checklayer1,checklayer2,command] // 신버전 데이터
                    imageMovedToLasso = LassoTool.moveSelectedAreaToLassoBox(true, data[1], data[2], data[4], data[5], data[6]);
                }
                if (imageMovedToLasso && !clearOnly)
                {
                    var lassoInfo:Array = (data[3] is Array && data[3].length === 7) ? data[3] : data[4];
                    const bmpScaleX:Number = lassoInfo[0];
                    const bmpScaleY:Number = lassoInfo[1];
                    const bmpWidth:Number = lassoInfo[2];
                    const bmpHeight:Number = lassoInfo[3];
                    const bmpAngle:Number = lassoInfo[4];
                    const boxX:Number = lassoInfo[5];
                    const boxY:Number = lassoInfo[6];
                    const mat:Matrix = new Matrix();
                    mat.scale(bmpScaleX, bmpScaleY);
                    mat.translate(-bmpWidth / 2, -bmpHeight / 2);
                    mat.rotate(bmpAngle);
                    mat.translate(boxX, boxY);
                    setRCursorPos(boxX, boxY);
                    LassoTool.lassoLayer1Bitmap.smoothing = true;
                    LassoTool.lassoLayer2Bitmap.smoothing = true;
                    if (data[7] as Boolean)
                    {
                        if (data[7] === true)
                        {
                            LassoTool.swapLassoImage();
                        }
                    }
                    else if (data[7] as Array)
                    {
                        const len:uint = data[7].length;
                        for (var i:uint = 0;i < len;i++)
                        {
                            if (data[7][i] === 0)
                            {
                                LassoTool.swapLassoImage();
                            }
                            else if (data[7][i] === 1)
                            {
                                LassoTool.mergeLassoImage();
                            }
                        }
                    }
                    if (data[5] || !data[5] && !data[6])
                    {
                        rCanvasLayer1BitmapData.draw(LassoTool.lassoLayer1Bitmap, mat);
                        rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                    }
                    if (data[6])
                    {
                        rCanvasLayer2BitmapData.draw(LassoTool.lassoLayer2Bitmap, mat);
                        rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                    }
                }
                resetLassoVars();
            }
            function lasso(data:Array, clearOnly:Boolean):void
            {
                if (data[1].length === 0 || data[2].length === 0)
                    return;
                var imageMovedToLasso:Boolean;
                if (data.length <= 5)
                {
                    if (data[3] === null || (data[3] is Array && data[3].length === 0))
                    {
                        // (["lasso",point1,point2,null,lassoInfo]); 초기 버전 데이터 구조 3번이 비어있음
                        // (["lasso",point1,point2,[],lassoInfo]);
                        imageMovedToLasso = LassoTool.moveSelectedAreaToLassoBox(true, data[1], data[2], false, true, true);
                    }
                    else if (data[3].length === 7)
                    {
                        // (["lasso",point1,point2,lassoInfo]); 2019년판 구버전
                        // (["lasso",point1,point2,lassoInfo,lassoCopyON])
                        imageMovedToLasso = LassoTool.moveSelectedAreaToLassoBox(true, data[1], data[2], data[4], true, true);
                    }
                }
                else
                {
                    // (["lasso",point1,point2,lassoInfo,lassoCopyON,canvas1Bitmap.visible,canvas11Bitmap.visible,lassoLayerSwappedFlag]); 신버전 데이터 길이가 6이상임
                    // ["lasso",point1,point2,lassoInfo,lassoCopyON,checklayer1,checklayer2,command] // 신버전 데이터
                    imageMovedToLasso = LassoTool.moveSelectedAreaToLassoBox(true, data[1], data[2], data[4], data[5], data[6]);
                }
                if (imageMovedToLasso && !clearOnly)
                {
                    var lassoInfo:Array = (data[3] is Array && data[3].length === 7) ? data[3] : data[4];
                    const bmpScaleX:Number = lassoInfo[0];
                    const bmpScaleY:Number = lassoInfo[1];
                    const bmpWidth:Number = lassoInfo[2];
                    const bmpHeight:Number = lassoInfo[3];
                    const bmpAngle:Number = lassoInfo[4];
                    const boxX:Number = lassoInfo[5];
                    const boxY:Number = lassoInfo[6];
                    const mat:Matrix = new Matrix();
                    mat.scale(bmpScaleX, bmpScaleY);
                    mat.translate(-bmpWidth / 2, -bmpHeight / 2);
                    mat.rotate(bmpAngle);
                    mat.translate(boxX, boxY);
                    setRCursorPos(boxX, boxY);
                    LassoTool.lassoLayer1Bitmap.smoothing = true;
                    LassoTool.lassoLayer2Bitmap.smoothing = true;
                    if (data[7] as Boolean)
                    {
                        if (data[7] === true)
                        {
                            LassoTool.swapLassoImage();
                        }
                    }
                    else if (data[7] as Array)
                    {
                        const len:uint = data[7].length;
                        for (var i:uint = 0;i < len;i++)
                        {
                            if (data[7][i] === 0)
                            {
                                LassoTool.swapLassoImage();
                            }
                            else if (data[7][i] === 1)
                            {
                                LassoTool.mergeLassoImage();
                            }
                        }
                    }
                    if (bmpScaleX !== 1 || bmpAngle !== 0)
                    {
                        LassoTool.applyLassoShapen(bmpScaleX);
                    }
                    if (data[5] || !data[5] && !data[6])
                    {
                        rCanvasLayer1BitmapData.draw(LassoTool.lassoLayer1Bitmap, mat);
                        rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                    }
                    if (data[6])
                    {
                        rCanvasLayer2BitmapData.draw(LassoTool.lassoLayer2Bitmap, mat);
                        rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                    }
                }
                resetLassoVars();
            }
            function mirror():void
            {
                mirrorCanvasReplayMode();
                setRCursorPosToCenter();
            }
            function bgColor(data:Array):void
            {
                const color:uint = data[1];
                rLastCanvasBGColor = color;
                updateCanvasBGColorReplayMode(color);
                setRCursorPosToCenter();
            }
            function canvasSize(data:Array):void
            {
                const width:Number = data[1];
                const height:Number = data[2];
                const moveX:Number = data[3];
                const moveY:Number = data[4];
                const movedFlag:Boolean = data[5];
                updateCanvasSizeReplayMode(width, height, moveX, moveY, movedFlag);
                setRCursorPos(width / 2, height / 2);
            }
            function tempDone4(data:Array):void
            {
                if (rAirBrushSize2 > 0)
                {
                    const blurSize:Number = CanvasController.getBlurSize(rAirBrushSize2, 1.0);
                    rCanvasDrawShape.filters = [new BlurFilter(blurSize, blurSize, 3)];
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    CanvasController.canvasDrawLayerChild.filters = [];
                }
                else
                {
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                }
                rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                updateRCanvasDrawLayerCliprect2();
                rCanvasDrawShape.graphics.clear();
            }
            function tempDone3(data:Array):void
            {
                rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                updateRCanvasDrawLayerCliprect2();
                rCanvasDrawShape.graphics.clear();
            }
            function tempDone2(data:Array):void
            {
                if (rAirBrushSize > 0 && rCanvasZoomMultiplier !== 1.0)
                {
                    blurReplayCanvasByDefaultValue();
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                    CanvasController.updateRCanvasDrawLayerCliprect();
                    rCanvasDrawShape.graphics.clear();
                    blurReplayCanvasByValue(rAirBrushSize);
                }
                else
                {
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                    CanvasController.updateRCanvasDrawLayerCliprect();
                    rCanvasDrawShape.graphics.clear();
                }
            }
            function tempDone(data:Array):void
            {
                if (rAirBrushSize > 0 && rCanvasZoomMultiplier !== 1.0)
                {
                    blurReplayCanvasByDefaultValue();
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                    rCanvasDrawShape.graphics.clear();
                    blurReplayCanvasByValue(rAirBrushSize);
                }
                else
                {
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                    rCanvasDrawShape.graphics.clear();
                }
            }
            function drawDone5(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1, 1, 1, lineStyleData[0]);
                if (rAirBrushSize2 > 0)
                {
                    const blurSize:Number = CanvasController.getBlurSize(rAirBrushSize2, 1.0);
                    rCanvasDrawShape.filters = [new BlurFilter(blurSize, blurSize, 3)];
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawShape.filters = [];
                }
                else
                {
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                }
                rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                updateRCanvasDrawLayerCliprect2();
                CanvasController.extandRCanvasDrawLayerCliprect2();
                if (subLayer)
                {
                    rCanvasLayer2BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], rCanvasDrawLayerClipRect);
                    rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                }
                else
                {
                    rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], rCanvasDrawLayerClipRect);
                    rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                }
                rCanvasDrawLayerBitmapData.fillRect(rCanvasDrawLayerClipRect, 0);
                rCanvasDrawShape.graphics.clear();
            }
            function drawDone4(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1, 1, 1, lineStyleData[0]);
                rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                updateRCanvasDrawLayerCliprect2();
                CanvasController.extandRCanvasDrawLayerCliprect2();
                if (rAirBrushSize2 > 0)
                {
                    const blurSize:Number = CanvasController.getBlurSize(rAirBrushSize2, 1.0);
                    rCanvasDrawLayerBitmapData.applyFilter(rCanvasDrawLayerBitmapData, rCanvasDrawLayerClipRect, new Point(rCanvasDrawLayerClipRect.x, rCanvasDrawLayerClipRect.y), new BlurFilter(blurSize, blurSize, 3));
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                }
                if (subLayer)
                {
                    rCanvasLayer2BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], rCanvasDrawLayerClipRect);
                    rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                }
                else
                {
                    rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], rCanvasDrawLayerClipRect);
                    rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                }
                rCanvasDrawLayerBitmapData.fillRect(rCanvasDrawLayerClipRect, 0);
                rCanvasDrawShape.graphics.clear();
            }
            function drawDone3(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1, 1, 1, lineStyleData[0]);
                if (rAirBrushSize > 0 && rCanvasZoomMultiplier !== 1.0)
                {
                    blurReplayCanvasByDefaultValue();
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                    blurReplayCanvasByValue(rAirBrushSize);
                }
                else
                {
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                }
                CanvasController.updateRCanvasDrawLayerCliprect();
                CanvasController.extandRCanvasDrawLayerCliprect();
                if (subLayer)
                {
                    rCanvasLayer2BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], rCanvasDrawLayerClipRectLegacy);
                    rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                }
                else
                {
                    rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], rCanvasDrawLayerClipRectLegacy);
                    rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                }
                rCanvasDrawLayerBitmapData.fillRect(rCanvasDrawLayerClipRectLegacy, 0);
                rCanvasDrawShape.graphics.clear();
                if (rAirBrushSize > 0)
                {
                    resetBlurReplayCanvas();
                }
            }
            function drawDone2(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1, 1, 1, lineStyleData[0]);
                if (rAirBrushSize > 0 && rCanvasZoomMultiplier !== 1.0)
                {
                    blurReplayCanvasByDefaultValue();
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                    blurReplayCanvasByValue(rAirBrushSize);
                }
                else
                {
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                }
                if (subLayer)
                {
                    rCanvasLayer2BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1]);
                    rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                }
                else
                {
                    rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1]);
                    rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                }
                rCanvasDrawLayerBitmapData.fillRect(new Rectangle(0, 0, rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height), 0);
                rCanvasDrawShape.graphics.clear();
                if (rAirBrushSize > 0)
                {
                    resetBlurReplayCanvas();
                }
            }
            function drawDone(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                // if(!lineStyleData) return;
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1, 1, 1, lineStyleData[0]);
                if (rAirBrushSize > 0 && rCanvasZoomMultiplier !== 1.0)
                {
                    blurReplayCanvasByDefaultValue();
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                    blurReplayCanvasByValue(rAirBrushSize);
                }
                else
                {
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                }
                if (subLayer)
                {
                    var tmpbmpd:BitmapData = new BitmapData(RCANVAS_WIDTH, RCANVAS_HEIGHT, true, 0);
                    tmpbmpd.draw(rCanvasDrawLayerBitmap, null, canvasAlpha);
                    tmpbmpd.draw(rCanvasLayer1Bitmap);
                    rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, tmpbmpd, rCanvasLayer1Bitmap);
                    tmpbmpd.dispose();
                    tmpbmpd = null;
                }
                else
                {
                    rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1]);
                    rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                }
                rCanvasDrawLayerBitmap.bitmapData = null;
                rCanvasDrawLayerBitmapData.fillRect(new Rectangle(0, 0, rCanvasDrawLayerBitmapData.width, rCanvasDrawLayerBitmapData.height), 0);
                rCanvasDrawShape.graphics.clear();
                if (rAirBrushSize > 0)
                {
                    resetBlurReplayCanvas();
                }
            }
            function clear(layer1:Boolean, layer2:Boolean):void
            {
                if (!layer1 && !layer2)
                {
                    layer1 = true;
                    layer2 = true;
                }
                const rect:Rectangle = new Rectangle(0, 0, rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height);
                if (layer1)
                    rCanvasLayer1BitmapData.fillRect(rect, 0);
                if (layer2)
                    rCanvasLayer2BitmapData.fillRect(rect, 0);
                setRCursorPosToCenter();
            }
            function swapLayer():void
            {
                var tempbmpd1:BitmapData = rCanvasLayer1BitmapData.clone();
                var tempbmpd11:BitmapData = rCanvasLayer2BitmapData.clone();
                const rect:Rectangle = new Rectangle(0, 0, rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height);
                rCanvasLayer1BitmapData.fillRect(rect, 0);
                rCanvasLayer2BitmapData.fillRect(rect, 0);
                rCanvasLayer1BitmapData.draw(tempbmpd11);
                rCanvasLayer2BitmapData.draw(tempbmpd1);
                tempbmpd1.dispose();
                tempbmpd11.dispose();
                tempbmpd1 = null;
                tempbmpd11 = null;
                setRCursorPosToCenter();
            }
            function mergeLayer():void
            {
                rCanvasLayer2BitmapData.draw(rCanvasLayer1BitmapData);
                rCanvasLayer1BitmapData.fillRect(new Rectangle(0, 0, rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height), 0);
                setRCursorPosToCenter();
            }
            function drawNext():void
            {
                if (!data || data.length === 0)
                {
                    return;
                }
                const d:Array = data[index];
                switch (d[0])
                {
                    case "lineStyle":
                        lineStyle(d);
                        break;
                    case "lineStyle2":
                        lineStyle2(d);
                        break;
                    case "lineStyle3":
                        lineStyle3(d);
                        break;
                    case "lineStyle4":
                        lineStyle4(d);
                        break;
                    case "lineStyle5":
                        lineStyle5(d);
                        break;
                    case "lineTo":
                        lineTo(d);
                        break;
                    case "sqline":
                        sqline(d);
                        break;
                    case "fill":
                        fill(d);
                        break;
                    case "fill2":
                        fill2(d);
                        break;
                    case "fill3":
                        fill3(d);
                        break;
                    case "fill4":
                        fill4(d);
                        break;
                    case "fill5":
                        fill5(d);
                        break;
                    case "dot":
                        dot(d);
                        break;
                    case "dot2":
                        dot2(d);
                        break;
                    case "dot3":
                        dot3(d);
                        break;
                    case "dot4":
                        dot4(d);
                        break;
                    case "line":
                        line(d);
                        break;
                    case "line1":
                        line1(d);
                        break;
                    case "line2":
                        line2(d);
                        break;
                    case "line3":
                        line3(d);
                        break;
                    case "move":
                        move(d);
                        break;
                    case "move1":
                        move1(d);
                        break;
                    case "move2":
                        move2(d);
                        break;
                    case "lasso":
                        lasso(d, false);
                        break;
                    case "lasso2":
                        lasso2(d, false);
                        break;
                    case "lassodel":
                        lasso(d, true);
                        break;
                    case "lassodel2":
                        lasso2(d, true);
                        break;
                    case "mirror":
                        mirror();
                        break;
                    case "bgColor":
                        bgColor(d);
                        break;
                    case "canvasSize":
                        canvasSize(d);
                        break;
                    case "tempDone":
                        tempDone(d);
                        break;
                    case "tempDone2":
                        tempDone2(d);
                        break;
                    case "tempDone3":
                        tempDone3(d);
                        break;
                    case "tempDone4":
                        tempDone4(d);
                        break;
                    case "drawDone":
                        drawDone(d);
                        break;
                    case "drawDone2":
                        drawDone2(d);
                        break;
                    case "drawDone3":
                        drawDone3(d);
                        break;
                    case "drawDone4":
                        drawDone4(d);
                        break;
                    case "drawDone5":
                        drawDone5(d);
                        break;
                    case "clear":
                        clear(true, true);
                        break;
                    case "clear1":
                        clear(true, false);
                        break;
                    case "clear2":
                        clear(false, true);
                        break;
                    case "swap":
                        swapLayer();
                        break;
                    case "merge":
                        mergeLayer();
                        break;
                    default:
                        break;
                }
                index++;
            }
            return {
                    drawNext: drawNext,
                    drawAll: drawAll,
                    setData: setData,
                    clearData: clearData,
                    setIndex: setIndex,
                    getCurrentPosition: getCurrentPosition,
                    isReadFinished: isReadFinished,
                    getDataLength: getDataLength,
                    getRemainingData: getRemainingData,
                    getrLineStyleSave: getrLineStyleSave,
                    getLineStyleAlpha: getLineStyleAlpha,
                    getRCursorPos: getRCursorPos,
                    setRCursorPos: setRCursorPos,
                    updateRCursorPos: updateRCursorPos,
                    updateRCursorPosToFirst: updateRCursorPosToFirst,
                    hasRCursorFirstPos: hasRCursorFirstPos,
                    getFirstRCursorPos: getFirstRCursorPos,
                    setFirstRCursorPos: setFirstRCursorPos,
                    resetFirstRCursorPos: resetFirstRCursorPos,
                    setFirstRCursorPosCurrent: setFirstRCursorPosCurrent,
                    updateLineStyleBackup: updateLineStyleBackup
                };
        }
        public function updateTotalFrameAndReplayMaxSpeedFor10Sec(totalframe:Number):void
        {
            TOTAL_FRAME = totalframe;
            var maxSpeed:Number = Math.floor(totalframe / 10 / stage.frameRate);
            if (maxSpeed < 1.0)
            {
                maxSpeed = 1.0;
            }
            REPLAY_MAX_SPEED = maxSpeed;
            if (rReplaySpeedMultipler > maxSpeed)
            {
                rReplaySpeedMultipler = maxSpeed;
            }
        }
        public function updateReplayPrograssText(finishFlag:Boolean = false, customFrame:Number = NaN):void
        {
            const remainingTime:String = (isDeepUndoEnabled || finishFlag) ? "" : getReplayRemainingTimeString(rReplaySpeedMultipler, TOTAL_FRAME - rNowFrame);
            if (isNaN(customFrame))
            {
                customFrame = rNowFrame;
            }
            MainUI.seekBarBox.prograssInfo.text = customFrame + " / " + TOTAL_FRAME + remainingTime;
        }
        public function startCheckingHideMouseCursor():void
        {
            if (FOFOTimer.hasTimer("replayHideCursorCheckTimer"))
            {
                return;
            }
            FOFOTimer.addByName("replayHideCursorCheckTimer", 0.0, true, function ():Boolean
                {
                    if (!isReplayModeON || MainUI.topBar.visible)
                    {
                        replayHideCursor.show();
                        return false;
                    }
                    replayHideCursor.check();
                    return true;
                });
        }
        public function startUpdatingPrograssBarTimer():void
        {
            if (FOFOTimer.hasTimer("prograssBarUpdateTimer"))
            {
                return;
            }
            var lastCursorUpdateTime:int = getTimer();
            var lastTextUpdateTime:int = getTimer();
            const cursorUpdateTime:int = stage.frameRate * 2;
            const textUpdateTime:int = 1000;
            updateReplayPrograssText();
            MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(rNowFrame / TOTAL_FRAME);
            FOFOTimer.addByName("prograssBarUpdateTimer", 0.0, true, function ():Boolean
                {
                    if (!isReplayModeON)
                    {
                        return false;
                    }
                    if (rNowFrame >= TOTAL_FRAME)
                    {
                        MainUI.seekBarBox.setReplayPrograssBarMaxWidth();
                        updateReplayPrograssText(true, TOTAL_FRAME);
                        replayCompleteEffect();
                        startReplayRestartTimer();
                        showCompleteImageToBGReplayMode();
                        MainUI.hideBottomHint();
                        return false;
                    }
                    const nowTime:int = getTimer();
                    if (nowTime - lastCursorUpdateTime >= cursorUpdateTime)
                    {
                        lastCursorUpdateTime = nowTime;
                        drawReplayByCommand.updateRCursorPos();
                        if (!isReplayCanvasFitToWindow && !CanvasController.isMouseClicked && !isDeepUndoEnabled)
                        {
                            rFollowMouse.check(isReplaySlideShowMode);
                        }
                    }
                    if (nowTime - lastTextUpdateTime >= textUpdateTime)
                    {
                        lastTextUpdateTime = nowTime;
                        updateReplayPrograssText();
                        MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(rNowFrame / TOTAL_FRAME);
                    }
                    updatePrograssBarStartTime = getTimer();
                    return true;
                });
        }
        public function drawCanvasFromReplayDataSlideShowMode():void
        {
            const nowTime:int = getTimer();
            if (nowTime - rSeekbarTextUpdateTime >= REPLAY_SLIDESHOW_UPDATE_TIME)
            {
                rSeekbarTextUpdateTime = nowTime;
                const nextFrame:Number = rReplaySpeedMultipler * stage.frameRate;
                renderReplayFrame(rNowFrame + Math.floor(nextFrame / REPLAY_SLIDESHOW_FRAME_RATE), JUMP_FRAME_MANUAL);
                if (rNowFrame >= TOTAL_FRAME)
                {
                    isReplayFinished = true;
                    stopReplay();
                }
            }
        }
        public function startReplayDrawTimer():void
        {
            FOFOTimer.addByName("replayDrawTimer", 0.0, true, function ():Boolean
                {
                    if (isReplaySlideShowMode)
                    {
                        if (!shouldUseReplaySlideShowMode())
                        {
                            isReplaySlideShowMode = false;
                            rFileStream.close();
                            if (!rDataReadFlag)
                            {
                                rFileStream.open(FileManager.replayDataFilePath, FileMode.READ);
                                rFileStream.position = rFileLastBytePosition;
                            }
                        }
                        else
                        {
                            drawCanvasFromReplayDataSlideShowMode();
                        }
                        return true;
                    }
                    if (shouldUseReplaySlideShowMode())
                    {
                        isReplaySlideShowMode = true;
                        rFileStream.close();
                    }
                    else
                    {
                        drawCanvasFromReplayData(rReplaySpeedMultipler, JUMP_FRAME_PLAY);
                    }
                    return true;
                });
        }
        public function clearRFrameTempCache():void
        {
            if (rFrameTempCachedImages.length > 0)
            {
                for (var i:int = 0;i < rFrameTempCachedImages.length;i++)
                {
                    rFrameTempCachedImages[i][0].dispose();
                    rFrameTempCachedImages[i][1].dispose();
                }
                rFrameTempCachedImages.length = 0;
                rJumpImageIndexLast = -2;
                rCachedImageLastIndex = -2;
            }
        }
        public function getRFrameTempCacheLastFrame():Number
        {
            return rFrameTempCachedImages[rFrameTempCachedImages.length - 1][6];
        }
        public function createRFrameTempCache(index:uint, lastReadBytes:Number):void
        {
            rFrameTempCachedImages[index] = [rCanvasLayer1BitmapData.clone()
                    , rCanvasLayer2BitmapData.clone()
                    , rCanvasLayer1BitmapData.width
                    , rCanvasLayer1BitmapData.height
                    , RCANVAS_BG_COLOR
                    , lastReadBytes
                    , rNowFrame
                    , rMirrorON];
        }
        // jumpFlag  0: 기본 재생 1:탐색바를 마우스를 이용하여 스킵, 2:one frame 이전스트로크, 3:one frame 이후 스트로크
        public function cDrawReplayData():Function
        {
            // jumpFlag 1번은 마우스 커서로 이동, 2,3번은 스트로크 단위혹은 프레임 단위로 앞뒤로 탐색
            var rDataLen:uint;
            var savedTime:int;
            var rFrameCursorDelayTime:int = 0; // 커서 딜레이
            var _rFrameTextDelayTime:int = 0; // 프레임 바 딜레이
            var getTimeStr:String;
            var timeStr:String;
            var readCount:Number = 0;
            var jumpImageGroupIndex:int;
            var nowJumpFlag:Boolean;
            const cursorUpdateTime:int = stage.frameRate * 2;
            function makeMemoryCacheImage():void
            {
                createRFrameTempCache(rFrameTempCachedImages.length, rFileCutBytePosition);
            }
            function readyToReadMemoryData(jumpFlag:int):void
            {
                rDataReadFlag = true;
                rDataIndex = rDataStartIndex;
                rDataStartIndex = 0;
                rDataLen = rData.length;
                if (jumpFlag === JUMP_FRAME_PLAY)
                {
                    rFileStream.close();
                    rFileLastBytePosition = 0;
                }
                if (rData.length > 0)
                {
                    rPrevFrame = rNowFrame;
                    drawReplayByCommand.setData(rData[rDataIndex]);
                }
                else
                {
                    drawReplayByCommand.clearData();
                }
            }
            function readNextFileData():Boolean
            {
                if (rFileStream.bytesAvailable > 0)
                {
                    const obj:Array = rFileStream.readObject() as Array;
                    if (!obj)
                        return true;
                    drawReplayByCommand.setData(obj);
                    rFileCutBytePosition = rFileLastBytePosition;
                    rFileLastBytePosition = rFileStream.position;
                    rPrevFrame = rNowFrame;
                    return true;
                }
                return false;
            }
            function checkFinish(jumpFlag:int):Boolean
            {
                if (rDataIndex >= rDataLen || rDataLen === 0) // 자연적으로 끝났을때
                {
                    rReplayFOFOCursor.visible = false;
                    isReplayFinished = true;
                    if (jumpFlag === JUMP_FRAME_PLAY || isReplaySlideShowMode === true) // 1프레임 이상일때만 재시작 타이머 가동
                    {
                        // reset replay time해주지 말고 그냥 end플래그만 올려줌
                        // 왜냐하면 리플레이 자연적으로 끝나고도 스킵프레임이나 oneframe jump을 해줄수가 있기 때문
                        stopReplay();
                        return true;
                    }
                }
                return false;
            }
            function drawFromMemoryData(len:Number, jumpFlag:int):void
            {
                for (var i:Number = 0;i < len;i++)
                {
                    if (drawReplayByCommand.isReadFinished())
                    {
                        rDataIndex++;
                        if (checkFinish(jumpFlag))
                        {
                            return;
                        }
                        rPrevFrame = rNowFrame;
                        drawReplayByCommand.setData(rData[rDataIndex]);
                    }
                    drawReplayByCommand.drawNext();
                    rNowFrame++;
                }
            }
            function drawFromFileData(len:Number, jumpFlag:int):void
            {
                for (var i:Number = 0;i < len;i++)
                {
                    if (drawReplayByCommand.isReadFinished())
                    {
                        if (readNextFileData() === false)
                        {
                            // 더이상 읽을 데이터가 없을때 메모리읽기로 넘겨줌
                            readyToReadMemoryData(jumpFlag);
                            return;
                        }
                        if (isReplayStarted === false && (jumpFlag === JUMP_FRAME_MANUAL || jumpFlag === JUMP_FRAME_PREV))
                        {
                            if (rNowFrame > getRFrameTempCacheLastFrame() + REPLAY_MEMORY_CACHE_FRAME_INTERVAL)
                            {
                                makeMemoryCacheImage();
                            }
                        }
                    }
                    drawReplayByCommand.drawNext();
                    rNowFrame++;
                    readCount--;
                }
            }
            return function (jumpCount:Number, jumpFlag:int):void
            {
                if (jumpCount > 0)
                {
                    readCount = jumpCount;
                    if (!rDataReadFlag)
                    {
                        // readcount 감소
                        drawFromFileData(jumpCount, jumpFlag);
                    }
                    if (readCount > 0)
                    {
                        // readcount를 읽어줌
                        drawFromMemoryData(readCount, jumpFlag);
                    }
                }
            };
        }
        public function getReplayRemainingTimeString(speed:Number, totalFrame:Number, isSlideShowMode:Boolean = false):String
        {
            const fps:Number = (isSlideShowMode === true) ? 1.0 : stage.frameRate;
            const totalSec:Number = totalFrame / (fps * speed);
            if (totalSec === 0)
                return "";
            const hour:int = totalSec / 3600;
            const min:int = totalSec % 3600 / 60;
            const sec:int = totalSec % 60;
            var timeStr:String = "";
            if (hour > 0)
            {
                timeStr += hour + ":";
            }
            if (min > 0)
            {
                timeStr += (min >= 10) ? min + ":" : "0" + min + ":";
            }
            else
            {
                timeStr = "00:";
            }
            if (sec > 0)
            {
                timeStr += (sec >= 10) ? sec : "0" + sec;
            }
            else
            {
                timeStr += "00";
            }
            if (hour === 0 && min === 0 && sec === 0)
            {
                const milisec:Number = totalSec - Math.floor(totalSec);
                const milisecStr:String = milisec.toFixed(1);
                return " (" + milisecStr + ")";
            }
            return " (" + timeStr + ")";
        }
        public function cReplayFollowMouse():Object
        {
            const padding:Number = 20;
            const cursorPos:Point = new Point(0, 0);
            const windowCenterPos:Point = new Point(0, 0); // 캔버스 중점위치, 창 중점위치 사이 거리
            var stw:Number;
            var sth:Number; // 프레임 탐색막대 길이 빼줌]
            var bounds:Object; // 바운드 저장하는 객체
            var left:Number; // 바운드 상하좌우
            var right:Number;
            var top:Number;
            var bottom:Number;
            var globalChecked:Boolean;
            var cp:Point; // 커서 좌표
            var gp:Point; // 캔버스 글로벌 좌표
            var rg:Point; // 캔버스 회전된 글로벌 좌표
            var zoom:Number = 1.0;
            var scale:Number = 1.0;
            // rcanvas1 글로벌 좌표에 회전된 캔버스에서 커서 위치를 더해줌. 즉 윈도우 기준에서 커서 커서 위치를 구하는거임
            var isCanvasWidthSmallerStage:Boolean; // 캔버스 가로 새로 길이가 스테이지 길이보다 클때 체크
            var isCanvasHeightSmallerStage:Boolean;
            var isNotCenterX:Boolean; // 캔버스 중점위치, 창 중점위치 사이 거리
            var isNotCenterY:Boolean;
            const leftLimit:Number = padding;
            const topLimit:Number = padding + MainUI.topBar.BARSIZE;
            var rightLimit:Number;
            var bottomLimit:Number;
            function updateScale(newScale:Number):void
            {
                scale = newScale;
            }
            function updateBounds():void
            {
                bounds = Utils.getBoundRect(rCanvasLayer1Bitmap);
                left = bounds.left;
                right = bounds.right;
                top = bounds.top;
                bottom = bounds.bottom;
                stw = stage.stageWidth;
                sth = stage.stageHeight - (MainUI.topBar.BARSIZE) * scale;
                zoom = rCanvasZoomMultiplier;
                isCanvasWidthSmallerStage = right - left < stw;
                isCanvasHeightSmallerStage = bottom - top < sth;
                // 캔버스 중점위치, 창 중점위치 사이 거리
                windowCenterPos.setTo(Math.floor(stw / 2 - (right + left) / 2), Math.floor((MainUI.topBar.BARSIZE) * scale + sth / 2 - (bottom + top) / 2));
                isNotCenterX = Math.abs(windowCenterPos.x) > 0; // 캔버스 중점위치, 창 중점위치 사이 거리
                isNotCenterY = Math.abs(windowCenterPos.y) > 0;
                rightLimit = stw - padding;
                bottomLimit = sth + MainUI.topBar.BARSIZE - padding;
            }
            function check(viewCenterFlag:Boolean):void
            {
                cp = drawReplayByCommand.getRCursorPos();
                globalChecked = false;
                const div:Number = (viewCenterFlag) ? 1 : 3;
                if (isCanvasWidthSmallerStage)
                {
                    if (isNotCenterX)
                    {
                        rCanvasAnchorPoint.x += windowCenterPos.x;
                        updateBounds();
                    }
                }
                else
                {
                    globalChecked = true;
                    gp = rCanvasLayer1Bitmap.localToGlobal(new Point(0, 0));
                    rg = Utils.rotatePoint(cp.x, cp.y, -rCanvasAnchorPoint.rotation);
                    cursorPos.x = gp.x + (rg.x * zoom);
                    if (cursorPos.x < leftLimit)
                    {
                        rCanvasAnchorPoint.x += Math.floor(Math.abs((cursorPos.x - stw / 2) / div));
                        updateBounds();
                    }
                    else if (cursorPos.x > rightLimit)
                    {
                        rCanvasAnchorPoint.x -= Math.floor(Math.abs((cursorPos.x - stw / 2) / div));
                        updateBounds();
                    }
                }
                if (isCanvasHeightSmallerStage)
                {
                    if (isNotCenterY)
                    {
                        rCanvasAnchorPoint.y += windowCenterPos.y;
                        updateBounds();
                    }
                }
                else
                {
                    if (globalChecked === false)
                    {
                        globalChecked = true;
                        gp = rCanvasLayer1Bitmap.localToGlobal(new Point(0, 0));
                        rg = Utils.rotatePoint(cp.x, cp.y, -rCanvasAnchorPoint.rotation);
                    }
                    cursorPos.y = gp.y + (rg.y * zoom);
                    if (cursorPos.y < topLimit)
                    {
                        rCanvasAnchorPoint.y += Math.floor(Math.abs((cursorPos.y - sth / 2) / div));
                        updateBounds();
                    }
                    else if (cursorPos.y > bottomLimit)
                    {
                        rCanvasAnchorPoint.y -= Math.floor(Math.abs((cursorPos.y - sth / 2) / div));
                        updateBounds();
                    }
                }
            }
            return {
                    check: check,
                    updateBounds: updateBounds,
                    updateScale: updateScale
                };
        }
        public function shouldUseReplaySlideShowMode():Boolean
        {
            return rReplaySpeedMultipler > REPLAY_SLIDESHOW_ACTIVE_SPEED;
        }
        public function toggleFitToCanvasReplayMode():void
        {
            if (isReplayCanvasFitToWindow)
            {
                resetZoomReplayMode();
                MainUI.topBar.replayFitToWindowButton.alpha = Global.OFFALPHA;
            }
            else
            {
                setFitReplayCanvasToViewportON();
                MainUI.topBar.replayFitToWindowButton.alpha = 1.0;
            }
        }
        public function toggleReplayRepeat():void
        {
            isReplayRepeatON = !isReplayRepeatON;
            if (isReplayRepeatON)
            {
                MainUI.topBar.replayRepeatButton.alpha = 1.0;
            }
            else
            {
                MainUI.topBar.replayRepeatButton.alpha = Global.OFFALPHA;
            }
        }
        public function getNowFrameUntilUndoIndex(index:int):Number
        {
            return undoManager.getRFileTotalFrame() + undoManager.getRDataTotalFrame(index);
        }
        public function getTotalFrame():Number
        {
            return getNowFrameUntilUndoIndex(rDataFrame.length - 1);
        }

        // targetFrame이 rFrameCacheImages데이터에 몆 번 인덱스에 있나 구해줌
        public function getCacheImageIndex(targetFrame:Number):int
        {
            return Utils.binarySearchIndex(rFrameTempCachedImages, targetFrame, function (item:*):Number
                {
                    return item[6];
                });
        }
        // targetFrame이 rJumpImageFrameData데이터에 몆 번 인덱스에 있나 구해줌
        public function getCachedFrameImageIndex(targetFrame:Number):int
        {
            return Utils.binarySearchIndex(rJumpImageFrameData, targetFrame, function (item:*):Number
                {
                    return Number(item);
                });
        }
        public function updateDeleteReplayDataButtonsState():void
        {
            if (isGeneratingCacheImages() || BackgroundWorkerCoordinator.isSaveInProgress || isReplayStarted)
            {
                MainUI.topBar.superUndoButton.alpha = Global.OFFALPHA;
                MainUI.topBar.cutPrevDataButton.alpha = Global.OFFALPHA;
                MainUI.topBar.repNewFileButton.alpha = Global.OFFALPHA;
            }
            else
            {
                MainUI.topBar.repNewFileButton.alpha = 1.0;
                if (rNowFrame > 0 && rNowFrame < TOTAL_FRAME)
                {
                    MainUI.topBar.superUndoButton.alpha = 1.0;
                    MainUI.topBar.cutPrevDataButton.alpha = 1.0;
                }
                else
                {
                    MainUI.topBar.superUndoButton.alpha = Global.OFFALPHA;
                    MainUI.topBar.cutPrevDataButton.alpha = Global.OFFALPHA;
                }
            }
        }
        public function addKeyRepeatEvents():void
        {
            stage.nativeWindow.addEventListener(Event.DEACTIVATE, removeKeyRepeatEvents);
            stage.addEventListener(MouseEvent.MOUSE_DOWN, removeKeyRepeatEvents);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, removeKeyRepeatEvents);
            stage.addEventListener(MouseEvent.MOUSE_UP, removeKeyRepeatEvents);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, removeKeyRepeatEvents);
            stage.addEventListener(KeyboardEvent.KEY_UP, removeKeyRepeatEvents);
        }
        public function removeKeyRepeatEvents(e:Object):void
        {
            FOFOTimer.remove("checkKeyRepeatStop");
            FOFOTimer.remove("keyHoldWaitTimer");
            FOFOTimer.remove("keyHoldRepeatTimer");
            stage.nativeWindow.removeEventListener(Event.DEACTIVATE, removeKeyRepeatEvents);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, removeKeyRepeatEvents);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, removeKeyRepeatEvents);
            stage.removeEventListener(MouseEvent.MOUSE_UP, removeKeyRepeatEvents);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, removeKeyRepeatEvents);
            stage.removeEventListener(KeyboardEvent.KEY_UP, removeKeyRepeatEvents);
        }
        public function readyForFrameJump():void
        {
            isReplayFinished = false;
            if (isReplayStarted)
            {
                stopReplay();
            }
        }
        public function moveToPreviousStep():void
        {
            readyForFrameJump();
            if (rNowFrame > 0)
            {
                renderReplayFrame(rPrevFrame, JUMP_FRAME_PREV);
                updateDeleteReplayDataButtonsState();
                MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(rNowFrame / TOTAL_FRAME);
                updateReplayPrograssText();
            }
        }
        public function moveToNextStep():void
        {
            readyForFrameJump();
            if (rNowFrame <= TOTAL_FRAME)
            {
                if (drawReplayByCommand.getRemainingData() === 0)
                {
                    // +1해줘서 다음 데이터 갱신해주고 나머지 끝까지 그려줌
                    renderReplayFrame(rNowFrame + 1, JUMP_FRAME_NEXT);
                    renderReplayFrame(rNowFrame + drawReplayByCommand.getRemainingData(), JUMP_FRAME_NEXT);
                    // jumpframe함수 이후에 실행
                }
                else
                {
                    renderReplayFrame(rNowFrame + drawReplayByCommand.getRemainingData(), JUMP_FRAME_NEXT);
                }
                updateDeleteReplayDataButtonsState();
                MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(rNowFrame / TOTAL_FRAME);
                updateReplayPrograssText();
            }
        }
        public function moveToPreviousFrame():void
        {
            readyForFrameJump();
            if (rNowFrame > 0)
            {
                renderReplayFrame(rNowFrame - 1, JUMP_FRAME_MANUAL);
                updateDeleteReplayDataButtonsState();
                MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(rNowFrame / TOTAL_FRAME);
                updateReplayPrograssText();
            }
        }
        public function moveToNextFrame():void
        {
            readyForFrameJump();
            if (rNowFrame < TOTAL_FRAME)
            {
                renderReplayFrame(rNowFrame + 1, JUMP_FRAME_MANUAL);
                updateDeleteReplayDataButtonsState();
                MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(rNowFrame / TOTAL_FRAME);
                updateReplayPrograssText();
            }
        }
        public function drawCacheImageFirst(tragetFrame:Number):Number
        {
            const index:Number = getCachedFrameImageIndex(tragetFrame);
            var cachedImageIndex:Number = -1; // 자잘 썸네일 인덱스를 넣어줌
            var loadCacheFlag:int = 0;
            var remainingFrameCount:Number = 0.0;
            // isReplayStarted 붙여주는 이유는
            // slide show모드로 재생하게 되면 클리어 케시를 계속 호출해주고
            // 재생 완료시 rJumpImageIndexLast가 갱신되어있을때 다시 해주면 메모리 캐시가 없는데 캐시를 불러주는 버그가 생겨서
            // 아무생각없이 넣어본건데 버그 안나서 그대로 두려고함
            if (index !== rJumpImageIndexLast && isReplayStarted === false)
            {
                clearRFrameTempCache();
                loadCacheFlag = 1;
            }
            else if (rFrameTempCachedImages.length > 0)
            {
                if (tragetFrame >= rFrameTempCachedImages[0][6])
                {
                    cachedImageIndex = getCacheImageIndex(tragetFrame);
                    if (rCachedImageLastIndex !== cachedImageIndex || tragetFrame < rNowFrame)
                    {
                        loadCacheFlag = 2;
                    }
                }
            }
            if (loadCacheFlag > 0 || tragetFrame < rNowFrame)
            {
                var cachedImageData:Array;
                var layer1bmpd:BitmapData;
                var layer2bmpd:BitmapData;
                var newrect:Rectangle;
                if (loadCacheFlag === 2)
                {
                    cachedImageData = rFrameTempCachedImages[cachedImageIndex];
                    layer1bmpd = cachedImageData[0];
                    layer2bmpd = cachedImageData[1];
                    rCachedImageLastIndex = cachedImageIndex;
                }
                else
                {
                    const file:File = FileManager.replayCacheImageFolderPath.resolvePath(String(index));
                    const fs:FileStream = new FileStream();
                    fs.open(file, FileMode.READ);
                    cachedImageData = fs.readObject() as Array;
                    fs.close();
                    cachedImageData[0].uncompress();
                    cachedImageData[1].uncompress();
                    newrect = new Rectangle(0, 0, cachedImageData[2], cachedImageData[3]);
                    layer1bmpd = new BitmapData(cachedImageData[2], cachedImageData[3], true, 0);
                    layer1bmpd.lock();
                    layer1bmpd.setPixels(newrect, cachedImageData[0]);
                    layer1bmpd.unlock();
                    layer2bmpd = new BitmapData(cachedImageData[2], cachedImageData[3], true, 0);
                    layer2bmpd.lock();
                    layer2bmpd.setPixels(newrect, cachedImageData[1]);
                    layer2bmpd.unlock();
                    cachedImageData[0].clear();
                    cachedImageData[0] = null;
                    cachedImageData[1].clear();
                    cachedImageData[1] = null;
                    rJumpImageNowFrameLast = cachedImageData[6];
                }
                rJumpImageIndexLast = index;
                rFileLastBytePosition = cachedImageData[5]; // 마지막 바이트
                rFileStream.position = cachedImageData[5];
                rNowFrame = cachedImageData[6]; // 썸네일 이미지를 저장한 프레임
                // 원하는 프레임에서 썸네일 이미지 프레임을 빼줌 나머지 프레임만 그려주면 되니깐
                remainingFrameCount = tragetFrame - cachedImageData[6];
                rDataIndex = 0; // 이거 먼저 초기화 시켜주어야함
                drawReplayByCommand.clearData();
                clearCanvasReplayMode();
                rMirrorON = cachedImageData[7];
                rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, layer1bmpd, rCanvasLayer1Bitmap);
                rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, layer2bmpd, rCanvasLayer2Bitmap);
                updateCanvasSizeReplayMode(rCanvasLayer1Bitmap.width, rCanvasLayer1Bitmap.height);
                updateCanvasBGColorReplayMode(cachedImageData[4]);
                if (loadCacheFlag === 1 && isReplayStarted === false)
                {
                    createRFrameTempCache(0, rFileLastBytePosition);
                }
                cachedImageData = null;
                rDataReadFlag = false;
                rDataStartIndex = 0;
                if (loadCacheFlag !== 2)
                {
                    layer1bmpd.dispose();
                    layer2bmpd.dispose();
                    layer1bmpd = null;
                    layer2bmpd = null;
                }
            }
            else
            {
                if (!rDataReadFlag)
                {
                    rFileStream.position = rFileLastBytePosition;
                }
                remainingFrameCount = tragetFrame - rNowFrame;
            }
            if (remainingFrameCount === 0.0)
            {
                rPrevFrame = tragetFrame - 1;
            }
            return remainingFrameCount;
        }
        public function renderReplayFrame(frame:Number, jumpflag:int):void // jumpp
        {
            if (frame < 0)
            {
                frame = 0;
            }
            else if (frame > TOTAL_FRAME)
            {
                frame = TOTAL_FRAME;
            }
            if (isReplayModeON)
            {
                if (frame >= TOTAL_FRAME && isReplayFinished)
                {
                    return;
                }
            }
            rFileStream.open(FileManager.replayDataFilePath, FileMode.READ);
            const remainingFrameCount:Number = drawCacheImageFirst(frame);
            drawCanvasFromReplayData(remainingFrameCount, jumpflag);
            rFileStream.close();
            // dodraw밑이기 때문에 rFrameSum이 갱신되서 위에 nowFrame은 쓸수가 없음
            if (rNowFrame >= TOTAL_FRAME)
            {
                if (isReplayModeON) // deepundo도 있어서
                {
                    if (!isReplayFinished)
                    {
                        isReplayFinished = true;
                        // syncMirrorReplayModeWithDrawMode();
                    }
                    rReplayFOFOCursor.visible = false;
                }
            }
            else
            {
                isReplayFinished = false;
                rReplayFOFOCursor.visible = true;
            }
            drawReplayByCommand.updateRCursorPos();
            if (!isReplaySlideShowMode && !isReplayCanvasFitToWindow && !isDeepUndoEnabled)
            {
                rFollowMouse.check(true);
            }
        }
        // 데이터를 읽다 말았으면 끝까지 한세트 끝나게 프레임 이동시킴
        public function finalizeRemainingReplayData():void
        {
            renderReplayFrame(rNowFrame + drawReplayByCommand.getRemainingData(), JUMP_FRAME_MANUAL);
        }
        public function onSeekbarClick():void
        {
            if (TOTAL_FRAME === 0 || rReplayImageCacheState > REPLAY_IMAGE_CAHCHE_COMPLETE)
            {
                return;
            }
            // 리플레이 플레이 중인지 아닌지 플래그 미리 저장해둠
            var wasReplayRunning:Boolean = false;
            var clickX:Number = MainUI.seekBarBox.trackBar.mouseX * MainUI.seekBarBox.trackBar.scaleX;
            var finalFrame:Number = Math.floor(TOTAL_FRAME * clickX / MainUI.seekBarBox.trackBar.width);
            function clampFrame():void
            {
                var mx:Number = MainUI.seekBarBox.trackBar.mouseX * MainUI.seekBarBox.trackBar.scaleX;
                if (mx < 0)
                {
                    mx = 0;
                    MainUI.seekBarBox.resetReplayPrograssBarWidth();
                }
                else if (mx > MainUI.seekBarBox.trackBar.width)
                {
                    mx = MainUI.seekBarBox.trackBar.width;
                    MainUI.seekBarBox.setReplayPrograssBarMaxWidth();
                }
                else
                {
                    MainUI.seekBarBox.setReplayPrograssBarWidth(mx);
                }
                finalFrame = Math.floor(TOTAL_FRAME * mx / MainUI.seekBarBox.trackBar.width);
                updateReplayPrograssText(false, finalFrame);
            }
            function onDragStart():void
            {
                if (isReplayStarted)
                {
                    wasReplayRunning = true;
                    isReplayStarted = false;
                    FOFOTimer.remove("replayDrawTimer");
                    rFileStream.close();
                }
                FOFOTimer.remove("prograssBarUpdateTimer");
                MainUI.seekBarBox.setReplayPrograssBarWidth(clickX);
                clampFrame();
                isReplaySlideShowMode = false;
                isReplayFinished = false;
                MainUI.seekBarBox.resetPrograssBarColor();
            }
            function onMouseMove():void
            {
                clampFrame();
                if (!FOFOTimer.hasTimer("jumpFrameUpdateTimer"))
                {
                    FOFOTimer.addByName("jumpFrameUpdateTimer", 0.25, false, function ():void
                        {
                            renderReplayFrame(finalFrame, JUMP_FRAME_MANUAL);
                        });
                }
            }
            function onMouseUp():void
            {
                FOFOTimer.remove("jumpFrameUpdateTimer");
                renderReplayFrame(finalFrame, JUMP_FRAME_MANUAL);
                clampFrame();
                // jumpframe함수 이후에 실행
                updateDeleteReplayDataButtonsState();
                // 재생중에 스킵하고 있었으면 다시 시작
                if (wasReplayRunning && !isReplayFinished)
                {
                    startReplay();
                }
                else if (isReplayFinished)
                {
                    MainUI.seekBarBox.setReplayPrograssBarMaxWidth();
                    updateReplayPrograssText(true, TOTAL_FRAME);
                    stopReplay();
                }
            }
            DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        }
        public function hideTopbarOnReplayStart():void
        {
            if (MainUI.topBar.visible === true)
            {
                MainUI.seekBarBox.y = 0;
                MainUI.seekBarBox.hideReplayControlButton();
                MainUI.topBar.visible = false;
                MainUI.hideBottomHint();
                MainUI.hideMouseHint();
            }
        }
        public function handleReplayStopButton():void
        {
            MainUI.showTopbarOnReplayEnd();
            stopReplay();
        }
        public function stopReplay():void
        {
            FOFOTimer.remove("replayDrawTimer");
            if (!isReplayFinished)
            {
                MainUI.seekBarBox.setPlayButtonVisible(true);
            }
            rFileStream.close();
            isReplayStarted = false;
            isReplaySlideShowMode = false;
            updateDeleteReplayDataButtonsState();
        }
        public function handleReplayStartButton():void
        {
            hideTopbarOnReplayStart();
            startReplay();
        }
        public function startReplay():void
        {
            if (isReplayStarted || TOTAL_FRAME === 0)
            {
                return;
            }
            isReplayStarted = true;
            MainUI.seekBarBox.resetPrograssBarColor();
            MainUI.seekBarBox.playButton.visible = false;
            MainUI.seekBarBox.pauseButton.visible = true;
            rReplayFOFOCursor.visible = true;
            updateDeleteReplayDataButtonsState();
            if (isReplayFinished === true) // 리플레이 시간 등등 초기화 시키고 시작
            {
                MainUI.seekBarBox.resetReplayPrograssBarWidth();
                rMirrorON = false;
                resetReplayTime();
                clearCanvasReplayMode();
                drawFirstJumpImage();
                rDataReadFlag = false;
                isReplayFinished = false; // resetReplayTime함수 에서 이걸 true로 해주기 때문에 아래쪽에서 변경
                rFollowMouse.updateBounds();
                selectReplaySubLayer(false);
            }
            if (!rDataReadFlag)
            {
                rFileStream.open(FileManager.replayDataFilePath, FileMode.READ);
                rFileStream.position = rFileLastBytePosition;
            }
            if (isReplayCanvasFitToWindow)
            {
                fitReplayCanvasToViewport();
            }
            clearRFrameTempCache();
            startReplayDrawTimer();
            startUpdatingPrograssBarTimer();
            startCheckingHideMouseCursor();
        }
        public function handleToolBoxClick(targetName:String):void
        {
            function onMouseUpToolBox(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpToolBox);
                if (isGeneratingCacheImages())
                {
                    return;
                }
                const upTargetName:String = e.target.name;
                if (upTargetName !== targetName)
                    return;
                switch (upTargetName)
                {
                    case "toolPen":
                        {
                            if (!isSelectedTool(TOOL_PEN))
                            {
                                selectPenTool();
                                updatePenSizeCursor();
                            }
                        }
                        break;
                    case "toolFillPen":
                        {
                            if (!isSelectedTool(TOOL_FILLPEN))
                            {
                                selectFillPenTool();
                                updatePenSizeCursor();
                            }
                        }
                        break;
                    case "toolEraser":
                        {
                            if (!isSelectedTool(TOOL_ERASER))
                            {
                                selectEraseTool();
                                updatePenSizeCursor();
                            }
                        }
                        break;
                    case "toolLine":
                        {
                            if (!isSelectedTool(TOOL_LINE))
                            {
                                selectLineTool();
                                updatePenSizeCursor();
                            }
                        }
                        break;
                    case "toolLasso":
                        {
                            if (!isSelectedTool(TOOL_LASSO))
                            {
                                selectLassoTool();
                            }
                        }
                        break;
                    case "toolEyedropper":
                        {
                            if (SidebarController.isQuickSidebarActive)
                            {
                                resetLastTool();
                                toolBox.moveToolCursor("toolEyedropper");
                            }
                            else if (!isSelectedTool(TOOL_EYEDROPPER))
                            {
                                eyeDropperTool();
                            }
                        }
                        break;
                    case "toolUndo":
                        {
                            if (!FOFOTimer.hasTimer("keyHoldRepeatTimer"))
                            {
                                undo();
                            }
                        }
                        break;
                    case "toolRedo":
                        {
                            if (!FOFOTimer.hasTimer("keyHoldRepeatTimer"))
                            {
                                redo();
                            }
                        }
                        break;
                    case "toolMirror":
                        {
                            CanvasController.mirrorCanvas();
                        }
                        break;
                    case "toolMove":
                        {
                            selectMoveTool();
                        }
                        break;
                    case "toolZoomIn":
                        {
                            CanvasController.zoomInCanvas(true, false);
                        }
                        break;
                    case "toolZoomOut":
                        {
                            CanvasController.zoomInCanvas(false, false);
                        }
                        break;
                    case "toolRefLayer":
                        {
                            if (SidebarController.isQuickSidebarActive)
                                SidebarController.deactivateQuickSidebar();
                            if (ReferenceLayerController.isRefLayerMenuON === false)
                            {
                                ReferenceLayerController.openRefLayerMenu();
                                ReferenceLayerController.refLayerMenuBox.y = mouseY - 60;
                            }
                        }
                        break;
                }
            }
            // undo키 반복이 있어서 우선순위 1로 약간 높여줌
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpToolBox, false, 1);
        }
        public function updateCanvasBGColor(xCanvas:Sprite, w:Number, h:Number, color:uint):void
        {
            xCanvas.graphics.clear();
            xCanvas.graphics.beginFill(color);
            xCanvas.graphics.drawRect(0, 0, w, h);
            xCanvas.graphics.endFill();
        }
        public function updateCanvasBGColorReplayMode(color:uint):void
        {
            RCANVAS_BG_COLOR = color;
            updateCanvasBGColor(rCanvasPanel, RCANVAS_WIDTH, RCANVAS_HEIGHT, color);
        }

        public function isHintAvailableWithFillPen(target:DisplayObject):Boolean
        {
            const targetName:String = target.name;
            if (isFillPenStarted)
            {
                if (target.alpha > 0.5
                        &&
                        (toolBox.contains(target)
                            || CanvasController.canvasInfoBox.contains(target)
                            || ColorPickerController.colorPickerBox.contains(target))
                        || target === SidebarController.sideBarScrollBar
                        || (targetName && targetName.indexOf("alphaButton") !== -1))
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
            else if (isSelectedTool(TOOL_FILLPEN))
            {
                if ((targetName && targetName.indexOf("nSizeButton") !== -1) || target.alpha < 0.5)
                {
                    return false;
                }
            }
            else if (MainUI.isHintUnavailable())
            {
                return false;
            }
            return true;
        }







        public function onDragEnterStage(e:NativeDragEvent):void
        {
            if (FileManager.isFileLoadBlocked())
            {
                return;
            }
            var c:Clipboard = e.clipboard;
            if (c.hasFormat("air:file list") === true)
            {
                if (isReplayStarted)
                    stopReplay();
                var files:Array = c.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
                // 두개이상 선택하고 드래그 할수있기 때문에 하나만 선택되었을때 되도록 해줌
                if (files && files.length == 1)
                {
                    NativeDragManager.acceptDragDrop(stage);
                }
            }
        }

        public function createCacheImage
            (
                layer1ImageData:ByteArray,
                layer2ImageData:ByteArray,
                imageWidth:int,
                imageHeight:int,
                bgColor:uint,
                lastBytePosition:Number,
                frameSum:Number,
                mirrorFlag:Boolean
            ):void
        {
            const fs:FileStream = new FileStream();
            rJumpImageFrameData.push(frameSum);
            fs.open(FileManager.replayCacheImageFolderPath.resolvePath(String(rJumpImageFrameData.length - 1)), FileMode.WRITE);
            fs.writeObject([layer1ImageData // 0
                        , layer2ImageData
                        , imageWidth
                        , imageHeight
                        , bgColor // 4
                        , lastBytePosition
                        , frameSum
                        , mirrorFlag]); // 7
            fs.close();
        }
        public function generateReplayCacheImage():void // loadrep
        {
            const fs:FileStream = new FileStream();
            const fs2:FileStream = new FileStream();
            const totalSize:Number = FileManager.replayDataFilePath.size;
            const deepUndoFlag:Boolean = isDeepUndoEnabled;
            var rect:Rectangle;
            var _frameSum:Number = 0;
            var _frameSumLast:Number = 0;
            var dataWriteCount:uint = 0;
            var hintPrintTimeSave:int = getTimer();
            CanvasController.canvasAnchorPoint.visible = false;
            rCanvasAnchorPoint.visible = false;
            CanvasController.canvasNavigatorBox.visible = false;
            undoManager.resetRJumpImageCount();
            clearCanvasReplayMode(); // 리플레이 캔버스 먼저 깨끗하게
            // 첫 이미지 그려줌
            rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, rFirstImageLayer1BitmapData, rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, rFirstImageLayer2BitmapData, rCanvasLayer2Bitmap);
            // 크기도 바꿔주고
            updateCanvasSizeReplayMode(rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height);
            fs.open(FileManager.replayDataFilePath, FileMode.READ);
            fs.position = 0;
            rMirrorON = false;
            FileManager.loadMenuBox.visible = false;
            function printPrograssHint(bytes:Number):void
            {
                const perc:Number = Math.round(((totalSize - bytes) / totalSize) * 100);
                // const str:String = perc.toFixed(1)+"%";
                FileManager.loadMenuBox.updatePlaseWaitPrograss(perc + "%");
            }
            FileManager.loadMenuBox.showPleaseWait("Reading replay file");
            FileManager.openLoadMenuBox();
            function onFrameEnter(e:Event):void
            {
                while (true)
                {
                    const namojiBytes:Number = fs.bytesAvailable;
                    if (namojiBytes === 0)
                    {
                        stage.removeEventListener(Event.ENTER_FRAME, onFrameEnter);
                        fs.close();
                        drawReplayByCommand.clearData();
                        undoManager.setRFileTotalFrame(_frameSum);
                        rReplayImageCacheState = REPLAY_IMAGE_CAHCHE_COMPLETE;
                        resetReplayTime();
                        updateTotalFrameAndReplayMaxSpeedFor10Sec(getTotalFrame());
                        rNowFrame = TOTAL_FRAME;
                        lastReplayFrameOnDeepUndoStart = TOTAL_FRAME;
                        rPrevFrame = _frameSumLast;
                        isReplayFinished = true;
                        if (mirrorCommandReady)
                        {
                            rMirrorON = !rMirrorON;
                            mirrorCommandReady = rMirrorON;
                        }
                        CanvasController.isCanvasMirrored = rMirrorON;
                        rMirrorON = rMirrorON;
                        undoManager.updateUndoBaseImageMirrorFlag(rMirrorON);
                        CanvasController.canvasInfoBox.setMirror(rMirrorON);
                        CanvasController.canvasNavigatorBox.visible = true;
                        if (!isReplayModeON && isDeepUndoEnabled)
                        {
                            rDataReadFlag = false;
                            addInputEventsDrawMode();
                            // jumpFrame(undoData.getRFileTotalFrame()-1,JUMP_FRAME_ONCE);
                            renderReplayFrame(rPrevFrame, JUMP_FRAME_MANUAL);
                            applyReplayCanvasToDrawModeCanvas();
                            CanvasController.canvasAnchorPoint.visible = true;
                        }
                        else if (isReplayModeON)
                        {
                            updateReplayPrograssBarAndText();
                            updateReplaySpeedSliderAlpha();
                            updateDeleteReplayDataButtonsState();
                            clearRFrameTempCache();
                            rJumpImageIndexLast = -2;
                            rJumpImageNowFrameLast = -1;
                            rTempCachedLastImageIndex = -2;
                            disableDeepUndo();
                            undoToIndex(rData.length - 1);
                            CanvasController.centerCanvas("replay");
                            removeInputEventsDrawMode();
                            addInputEventsReplayMode();
                            rCanvasAnchorPoint.visible = true;
                        }
                        FileManager.closeLoadMenuBox();
                        clearKeyBuffer();
                        return;
                    }
                    if (getTimer() - hintPrintTimeSave > 250)
                    {
                        hintPrintTimeSave = getTimer();
                        printPrograssHint(namojiBytes);
                        return;
                    }
                    const data:Array = fs.readObject() as Array;
                    drawReplayByCommand.setData(data);
                    _frameSumLast = _frameSum;
                    _frameSum += data.length; // _rJumpImageCount 변수보다 먼저 와야함
                    dataWriteCount += data.length;
                    drawReplayByCommand.drawAll();
                    if (dataWriteCount > REPLAY_DISK_CACHE_FRAME_INTERVAL)
                    {
                        var imgData1:ByteArray = new ByteArray();
                        var imgData2:ByteArray = new ByteArray();
                        dataWriteCount = 0;
                        rect = new Rectangle(0, 0, rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height);
                        rCanvasLayer1BitmapData.copyPixelsToByteArray(rect, imgData1);
                        rCanvasLayer2BitmapData.copyPixelsToByteArray(rect, imgData2);
                        imgData1.compress();
                        imgData2.compress();
                        createCacheImage(imgData1,
                                imgData2,
                                rCanvasLayer1BitmapData.width,
                                rCanvasLayer1BitmapData.height,
                                rLastCanvasBGColor,
                                fs.position,
                                _frameSum,
                                rMirrorON);
                        imgData1.clear();
                        imgData2.clear();
                        if (MainUI.seekBarBox.prograssBar.width > 0)
                        {
                            MainUI.seekBarBox.resetReplayPrograssBarWidth();
                        }
                    }
                }
            }
            stage.addEventListener(Event.ENTER_FRAME, onFrameEnter);
        }

        public function writeReplayFile(dataA:ByteArray
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
            fs.open(repFileTemp, FileMode.WRITE);
            fs.position = 0;
            fs.writeUTFBytes("FOFOPAINT"); // 파일 헤더
            fs.writeUnsignedInt(dataD.length); // 뒤에 압축된 바이트를 얼마나 건너 뛰어야 하는지 저장
            fs.writeBytes(dataD);
            if (mirrorCommandReady) // 임시 미러가 되어있을때 진짜 캔버스로 반전되어있는데 리플레이 데이터에는 아직 써주지 않았으니까 넣어줌
            {
                const tempMirrorData:Array = [["mirror"]];
                fs.writeObject(tempMirrorData);
            }
            fs.writeObject(["rFirstImage", dataA, dataA1, rImgDataW, rImgDataH, rFirstImageBGColor]);
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
                const newPath:String = FileManager.lastSaveFilePath.substr(0, FileManager.lastSaveFilePath.lastIndexOf(".png")) + ".2020";
                repFileTemp.moveTo(new File(newPath), true);
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

        public function loadReplayFile(oldFile:File):void // loadrep
        {
            if (FileManager.isTrue2020File(oldFile) === false)
            {
                FileManager.showLoadFaildMouseHint();
                return;
            }
            const fs:FileStream = new FileStream();
            var imgStartByte:uint = 0;
            var finalIMGBMPD:BitmapData = new BitmapData(1, 1, true, 0);
            var finalIMGBMPD1:BitmapData = new BitmapData(1, 1, true, 0);
            var imgW:uint = 0;
            var imgH:uint = 0;
            var bg:uint = 0;
            var errorFlag:Boolean = true;
            var rect:Rectangle;
            initializeReplayDataFile(true); // 일단 썸네일 이미지랑 리플레이 데이터 청소
            oldFile.copyTo(repFileTemp, true); // repdata.c3p를 복사 덮어씌우기
            if (ReferenceLayerController.refLayerRawTransformData)
            {
                ReferenceLayerController.refLayerRawBitmapData.dispose();
                ReferenceLayerController.refLayerRawBitmapData = null;
                ReferenceLayerController.refLayerRawTransformData = null;
            }
            fs.open(repFileTemp, FileMode.READ);
            rJumpImageFrameData = [0];
            var d:Array;
            var ba:ByteArray;
            var replayData:ByteArray = new ByteArray();
            const isNew2020FileFlag:Boolean = FileManager.isNew2020File(oldFile);
            if (isNew2020FileFlag)
            {
                const a:String = fs.readUTFBytes(9); // FOFOPAINT헤더 읽어줌
                const compBytes:uint = fs.readUnsignedInt(); // 압축된 데이터 길이 읽어줌
                if (compBytes > 0)
                {
                    // 압축된 데이터 써주고 압축 풀어줌
                    fs.readBytes(replayData, 0, compBytes);
                    replayData.uncompress();
                }
            }
            while (true)
            {
                if (fs.bytesAvailable === 0)
                    break;
                d = fs.readObject();
                if (d[0] === "rFirstImage")
                {
                    if (d[2] is ByteArray === false)
                    {
                        ba = d[1] as ByteArray;
                        rect = new Rectangle(0, 0, d[2], d[3]);
                        ba.uncompress();
                        rFirstImageLayer1BitmapData = new BitmapData(d[2], d[3], true, 0);
                        rFirstImageLayer1BitmapData.lock();
                        rFirstImageLayer1BitmapData.setPixels(rect, ba);
                        rFirstImageLayer1BitmapData.unlock();
                        ba.clear();
                        ba = null;
                        rLastCanvasBGColor = d[4];
                        createFirstImageCache(rFirstImageLayer1BitmapData, null, d[4]);
                    }
                    else
                    {
                        ba = d[1] as ByteArray;
                        rect = new Rectangle(0, 0, d[3], d[4]);
                        ba.uncompress();
                        rFirstImageLayer1BitmapData = new BitmapData(d[3], d[4], true, 0);
                        rFirstImageLayer1BitmapData.lock();
                        rFirstImageLayer1BitmapData.setPixels(rect, ba);
                        rFirstImageLayer1BitmapData.unlock();
                        ba.clear();
                        ba = d[2] as ByteArray;
                        ba.uncompress();
                        rFirstImageLayer2BitmapData = new BitmapData(d[3], d[4], true, 0);
                        rFirstImageLayer2BitmapData.lock();
                        rFirstImageLayer2BitmapData.setPixels(rect, ba);
                        rFirstImageLayer2BitmapData.unlock();
                        ba.clear();
                        ba = null;
                        rLastCanvasBGColor = d[5];
                        createFirstImageCache(rFirstImageLayer1BitmapData, rFirstImageLayer2BitmapData, d[5]); // 0.cache 파일 갱신
                    }
                }
                else if (d[0] === "rFinalImage") // 최종 이미지
                {
                    // 레이어1일때 구버전
                    if (d[2] is ByteArray === false)
                    {
                        ba = d[1] as ByteArray;
                        rect = new Rectangle(0, 0, d[2], d[3]);
                        ba.uncompress();
                        errorFlag = false;
                        finalIMGBMPD = new BitmapData(d[2], d[3], true, 0);
                        finalIMGBMPD.lock();
                        finalIMGBMPD.setPixels(rect, ba);
                        finalIMGBMPD.unlock();
                        ba.clear();
                        ba = null;
                        imgW = d[2];
                        imgH = d[3];
                        bg = d[4];
                    }
                    else
                    {
                        ba = d[1] as ByteArray;
                        rect = new Rectangle(0, 0, d[3], d[4]);
                        ba.uncompress();
                        errorFlag = false;
                        finalIMGBMPD = new BitmapData(d[3], d[4], true, 0);
                        finalIMGBMPD.lock();
                        finalIMGBMPD.setPixels(rect, ba);
                        finalIMGBMPD.unlock();
                        ba.clear();
                        ba = d[2] as ByteArray;
                        ba.uncompress();
                        finalIMGBMPD1 = new BitmapData(d[3], d[4], true, 0);
                        finalIMGBMPD1.lock();
                        finalIMGBMPD1.setPixels(rect, ba);
                        finalIMGBMPD1.unlock();
                        ba.clear();
                        ba = null;
                        imgW = d[3];
                        imgH = d[4];
                        bg = d[5];
                    }
                }
                else if (d[0] === "refimage" || d[0] === "traceImage")
                {
                    ba = d[1] as ByteArray;
                    rect = new Rectangle(0, 0, d[2], d[3]);
                    ba.uncompress();
                    ReferenceLayerController.refLayerRawBitmapData = new BitmapData(d[2], d[3], true, 0);
                    ReferenceLayerController.refLayerRawBitmapData.lock();
                    ReferenceLayerController.refLayerRawBitmapData.setPixels(rect, ba);
                    ReferenceLayerController.refLayerRawBitmapData.unlock();
                    ba.clear();
                    ba = null;
                    d[0] = null;
                    d[1] = null;
                    ReferenceLayerController.refLayerRawTransformData = d.concat();
                }
                else if (isNew2020FileFlag) // 신포멧인데 rData옛 버전에서rData압축안하고 넣어준거 읽어줌
                {
                    replayData.position = replayData.length;
                    replayData.writeObject(d);
                }
                else
                {
                    imgStartByte = fs.position;
                }
            }
            fs.close();
            if (isNew2020FileFlag)
            {
                fs.open(FileManager.replayDataFilePath, FileMode.WRITE);
                fs.position = 0;
                fs.writeBytes(replayData);
                fs.close();
            }
            else
            {
                // 이미지직전까지 바이트를 기준으로 짤라줌, 즉 뒤에 붙은 첫 이미지 + 마지막 이미지를 지워줌
                fs.open(repFileTemp, FileMode.UPDATE);
                fs.position = imgStartByte;
                fs.truncate();
                fs.close();
                repFileTemp.moveTo(FileManager.replayDataFilePath, true);
            }
            if (repFileTemp.exists)
            {
                repFileTemp.deleteFile();
            }
            replayData.clear();
            replayData = null;
            rReplayImageCacheState = REPLAY_IMAGE_CAHCHE_READY;
            finalizeLoadFile(imgW, imgH, finalIMGBMPD, finalIMGBMPD1, false, bg);
        }
        public function loadImageFile(width:Number, height:Number, layer1Image:IBitmapDrawable, layer2Image:IBitmapDrawable):void
        {
            updateTotalFrameAndReplayMaxSpeedFor10Sec(0);
            undoManager.setRFileTotalFrame(0);
            rReplayImageCacheState = REPLAY_IMAGE_CAHCHE_COMPLETE;
            ReferenceLayerController.refLayerRawBitmapData = null;
            ReferenceLayerController.refLayerRawTransformData = null;
            finalizeLoadFile(width, height, layer1Image, layer2Image, true, 0xFFFFFF);
            initializeReplayDataFile(true); // 일단 썸네일 이미지랑 리플레이 데이터 청소
        }
        public function finalizeLoadFile(width:uint, height:uint, imageData:IBitmapDrawable, imageData1:IBitmapDrawable, imageOnlyFlag:Boolean, newBG:uint):void
        {
            if (!imageData)
            {
                FileManager.showLoadFaildMouseHint();
                return;
            }
            var maxLength:Number = (width > height) ? width : height;
            var scaleFix:Number = (maxLength > CanvasController.CANVAS_MAX_SIZE) ? CanvasController.CANVAS_MAX_SIZE / maxLength : 1.0;
            const scaledwidth:Number = Math.floor(width * scaleFix);
            const scaledheight:Number = Math.floor(height * scaleFix); // CANVAS_MAX_SIZE 값을 넘으면 리사이즈 해줌
            var scaleMat:Matrix = new Matrix();
            scaleMat.scale(scaleFix, scaleFix);
            var tmpbmpd:BitmapData = new BitmapData(scaledwidth, scaledheight, true, 0);
            if (CaptureController.isCaptureModeON)
            {
                CaptureController.handleExitCaptureMode();
            }
            resetReplaySpeedBar();
            resetReplayTime();
            clearCanvasReplayMode();
            updateReplayPrograssText(true, 0);
            MainUI.seekBarBox.resetReplayPrograssBarWidth();
            ColorPickerController.updateCanvasBGColorDrawMode(newBG);
            updateCanvasBGColorReplayMode(newBG);
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowBGColor(CanvasController.CANVAS_BG_COLOR, ImageViewWindow.canvasWindowLayer1Bitmap.bitmapData);
            }
            // FileManager.updateLastFilePathByRandomFileName();
            FileManager.isContinueSaveON = false; // 연속 세이브 플래그 취소
            rMirrorON = false;
            CanvasController.isCanvasMirrored = false;
            mirrorCommandReady = false;
            CanvasController.canvasInfoBox.setMirror(false);
            CanvasGridOverlay.updateGridMirror(false);
            if (LassoTool.isLassoToolStarted === true)
            {
                LassoTool.cancelLassoTool();
                LassoTool.resetLassoBox();
            }
            if (isFillPenStarted)
            {
                fillPenTool.cancel();
            }
            tmpbmpd.draw(imageData, scaleMat, null, null, null, true);
            CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, tmpbmpd, CanvasController.canvasLayer1Bitmap);
            if (imageOnlyFlag)
            {
                if (rFirstImageLayer1BitmapData && tmpbmpd !== rFirstImageLayer1BitmapData)
                    rFirstImageLayer1BitmapData.dispose();
                rFirstImageLayer1BitmapData = tmpbmpd.clone(); // 이미지만 불러와주면 첫 이미지를 갱신해줌
            }
            if (imageData1 !== null)
            {
                tmpbmpd.fillRect(new Rectangle(0, 0, scaledwidth, scaledheight), 0);
                tmpbmpd.draw(imageData1, scaleMat, null, null, null, true);
                CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, tmpbmpd, CanvasController.canvasLayer2Bitmap);
                if (imageOnlyFlag)
                {
                    rFirstImageLayer2BitmapData = tmpbmpd.clone();
                }
            }
            else
            {
                CanvasController.canvasLayer2BitmapData = new BitmapData(CanvasController.canvasLayer1BitmapData.width, CanvasController.canvasLayer1BitmapData.height, true, 0);
                CanvasController.canvasLayer2Bitmap.bitmapData = CanvasController.canvasLayer2BitmapData;
            }
            tmpbmpd.dispose();
            tmpbmpd = null;
            CanvasController.canvasAnchorPoint.rotation = 0;
            setRcursorRotation(0);
            CanvasController.canvasZoomIndex = 3;
            CanvasController.updateCanvasScale(1.0);
            CanvasController.updateCavnvasSizeDrawMode(scaledwidth, scaledheight, 0, 0, false);
            syncReplayCanvasImageWithDrawMode();
            syncReplayCanvasWithDrawMode();
            CanvasController.centerCanvas("draw");
            updatePenSizeCursor();
            if (CanvasGridOverlay.gridGapMultiplier > 0)
            {
                CanvasGridOverlay.drawGrid();
            }
            // bitmapdata가 갱신된이후에 업데이트 해줘야함
            resetUndoState();
            drawReplayByCommand.resetFirstRCursorPos();
            if (ReferenceLayerController.refLayerRawTransformData === null)
            {
                ReferenceLayerController.clearRefLayerImage();
            }
            else
            {
                ReferenceLayerController.canvasRefLayerBitmapData = ReferenceLayerController.refLayerRawBitmapData.clone();
                ReferenceLayerController.canvasRefLayerBitmap.bitmapData = ReferenceLayerController.canvasRefLayerBitmapData;
                ReferenceLayerController.updateRefLayerImageTransform(ReferenceLayerController.refLayerRawTransformData[4],
                        ReferenceLayerController.refLayerRawTransformData[5],
                        ReferenceLayerController.refLayerRawTransformData[6],
                        ReferenceLayerController.refLayerRawTransformData[7],
                        ReferenceLayerController.refLayerRawTransformData[8]);
                ReferenceLayerController.refLayerMenuDragXMoveSum = ReferenceLayerController.refLayerRawTransformData[10];
                ReferenceLayerController.refLayerLastAlpha = ReferenceLayerController.refLayerRawTransformData[11];
                ReferenceLayerController.canvasRefLayer.visible = true;
                ReferenceLayerController.canvasRefLayer.alpha = Utils.normalizeAlphaValue(ReferenceLayerController.refLayerRawTransformData[11]);
                ReferenceLayerController.updateRefLayerOpacityCursorPosByValue(ReferenceLayerController.refLayerRawTransformData[11]);
                ReferenceLayerController.refLayerRawBitmapData.dispose();
                ReferenceLayerController.refLayerRawBitmapData = null;
                ReferenceLayerController.refLayerRawTransformData = null;
                ReferenceLayerController.canvasRefLayerBitmap.smoothing = true;
            }
            MainUIController.updateWindowTitle();
            CanvasController.selectLayer1(false);
            selectReplaySubLayer(false);
            if (toolOptionsBox.layer1CheckedButton.visible)
            {
                CanvasController.toggleLayer1Check();
            }
            if (toolOptionsBox.layer2CheckedButton.visible)
            {
                CanvasController.toggleLayer2Check();
            }
            MainUIController.updateResizeButtonPos(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
            removeKeyRepeatEvents(null);
            CanvasController.canvasLayer1Bitmap.visible = true;
            CanvasController.canvasLayer2Bitmap.visible = true;
            MainUI.topBar.captureButton.alpha = 1.0;
            MainUI.topBar.newFileButton.alpha = 1.0;
            ReferenceLayerController.refLayerMenuBox.refTransferCanvasImageButton.alpha = 1.0;
            ColorPickerController.selectCurrentColor(false);
            selectPenToolIfNotDrawingTool(false);
            CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
            MainUIController.updateCanvasNaigatorCursor();
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.canvasWindowIgnoreResizeEventFlag = true;
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
            CaptureController.resetCaptureCanvasChangeValue();
            FileManager.lastLoadedFile = null;
            FileManager.isLoadPendingAfterSaving = false;
            FileManager.closeLoadMenuBox();
        }









        public function saveReplayFrameData():void
        {
            const fs:FileStream = new FileStream();
            fs.open(FileManager.replayCacheImageFrameDataFilePath, FileMode.WRITE);
            fs.writeObject(rJumpImageFrameData);
            fs.close();
        }
        public function loadUndoData():void
        {
            if (FileManager.undoDataFilePath.exists === false)
            {
                return;
            }
            rMirrorON = false;
            CanvasController.isCanvasMirrored = false;
            CanvasController.canvasInfoBox.setMirror(false);
            const fs:FileStream = new FileStream();
            fs.open(FileManager.undoDataFilePath, FileMode.READ);
            const lastUndoIndex:int = fs.readInt();
            var arr:Array = fs.readObject() as Array; // undodata first
            const bmpdRect:Rectangle = new Rectangle(0, 0, arr[2], arr[3]);
            var bmpd:BitmapData = new BitmapData(arr[2], arr[3], true, 0);
            var bmpd1:BitmapData = new BitmapData(arr[2], arr[3], true, 0);
            if (arr[6] is Number)
            {
                undoManager.setRFileTotalFrame(arr[6]);
            }
            rData = (fs.readObject() as Array).concat();
            rDataFrame = (fs.readObject() as Array).concat();
            fs.close();
            undoDataIndex = lastUndoIndex;
            bmpd.lock();
            bmpd.setPixels(bmpdRect, arr[0]);
            bmpd.unlock();
            bmpd1.lock();
            bmpd1.setPixels(bmpdRect, arr[1]);
            bmpd1.unlock();
            undoManager.updateUndoBaseImage(bmpd.clone(), bmpd1.clone(), arr[2], arr[3], arr[4], arr[5]);
            drawUndoData();
            rReplayFOFOCursor.visible = false;
            MainUI.hideMouseHint();
            bmpd.dispose();
            bmpd1.dispose();
            bmpd = null;
            bmpd1 = null;
            arr.length = 0;
            arr = null;
            // undo index가 arr의 가장 마지막 부분이 아니면 undo를 하던 중이니까 isDeleteUndoDataPending 켜줌
            if (lastUndoIndex < rData.length - 1)
            {
                isDeleteUndoDataPending = true;
            }
            else
            {
                isDeleteUndoDataPending = false;
            }
        }


        public function saveUndoData():void
        {
            const fs:FileStream = new FileStream();
            const arr:Array = undoManager.getUndoBaseImage();
            const bmpd:BitmapData = arr[0];
            const bmpd1:BitmapData = arr[1];
            var ba:ByteArray = new ByteArray();
            var ba1:ByteArray = new ByteArray();
            var newRectangle:Rectangle = new Rectangle(0, 0, arr[2], arr[3]);
            bmpd.copyPixelsToByteArray(newRectangle, ba);
            bmpd1.copyPixelsToByteArray(newRectangle, ba1);
            // ba.compress();
            // ba1.compress();
            // 레이어 1,레이어2,가로,세로,배경색, repdata 합계 프레임
            var newArr:Array = [ba, ba1, arr[2], arr[3], arr[4], arr[5], undoManager.getRFileTotalFrame()];
            fs.open(FileManager.undoDataFilePath, FileMode.WRITE);
            fs.writeInt(undoDataIndex);
            fs.writeObject(newArr);
            fs.writeObject(rData);
            fs.writeObject(rDataFrame);
            fs.close();
            ba.clear();
            ba1.clear();
            ba = null;
            ba = null;
        }


        // size, size drag, zoom, rotate시 업데이트 해줌
        public function cUpdatePenSizeCursor():Function
        {
            var size:Number;
            var shape:Boolean;
            return function ():void
            {
                const isPenTool:Boolean = isSelectedToolPenOrLine();
                if (!isPenTool && !isSelectedTool(TOOL_ERASER))
                {
                    return;
                }
                if (isPenTool)
                {
                    size = PenTool.penSize;
                    shape = PenTool.penIsSquare;
                }
                else
                {
                    size = PenTool.eraserSize;
                    shape = PenTool.eraserIsSquare;
                }
                const z:Number = CanvasController.canvasZoomMultipler;
                if (size * z === PenTool.penLastSizeAndShape[0] && shape === PenTool.penLastSizeAndShape[1])
                {
                    return;
                }
                PenTool.penLastSizeAndShape[0] = size * z;
                PenTool.penLastSizeAndShape[1] = shape;
                CanvasController.penSizePreviewCursor.graphics.clear();
                if (shape === false)
                {
                    CanvasController.penSizePreviewCursor.graphics.lineStyle(1, 0xFFFFFF);
                    CanvasController.penSizePreviewCursor.graphics.drawCircle(0, 0, (size / 2 - 1 / z) * z);
                    CanvasController.penSizePreviewCursor.graphics.lineStyle(1, 0);
                    CanvasController.penSizePreviewCursor.graphics.drawCircle(0, 0, (size / 2) * z);
                    CanvasController.penSizePreviewCursor.rotation = 0;
                }
                else if (shape === true)
                {
                    CanvasController.penSizePreviewCursor.graphics.lineStyle(1, 0xFFFFFF);
                    CanvasController.penSizePreviewCursor.graphics.drawRect((-size / 2 + 1 / z) * z, (-size / 8 + 1 / z) * z, (size - 2 / z) * z, (size / 4 - 2 / z) * z);
                    CanvasController.penSizePreviewCursor.graphics.lineStyle(1, 0);
                    CanvasController.penSizePreviewCursor.graphics.drawRect(-size / 2 * z, -size / 8 * z, size * z, size * z / 4);
                }
                PenTool.penCursorShape = shape;
                PenTool.penCursorSize = size;
            };
        }
        public function cDrawDone():Function
        {
            var drawLayerAlpha:ColorTransform = new ColorTransform();
            return function ():void
            {
                if (canAddUndoData === false)
                {
                    rDataBuffer = [];
                    CanvasController.canvasDrawLayerChild.graphics.clear();
                    return;
                }
                if (isDeepUndoEnabled)
                {
                    var rDataBufferSave:Array = rDataBuffer.concat();
                    applyDeepUndo();
                    rDataBuffer = rDataBufferSave;
                    rDataBufferSave = null;
                }
                canAddUndoData = false;
                if (airBrushSizeDrawMode > 0)
                {
                    const blurSize:Number = CanvasController.getBlurSize(airBrushSizeDrawMode, 1.0);
                    CanvasController.canvasDrawLayerChild.filters = [new BlurFilter(blurSize, blurSize, 3)];
                    CanvasController.canvasDrawLayerBitmapData.draw(CanvasController.canvasDrawLayerChild);
                    CanvasController.canvasDrawLayerChild.filters = [];
                }
                else
                {
                    CanvasController.canvasDrawLayerBitmapData.draw(CanvasController.canvasDrawLayerChild);
                }
                CanvasController.canvasDrawLayerBitmap.bitmapData = CanvasController.canvasDrawLayerBitmapData;
                CanvasController.updateCanvasDrawLayerCliprect();
                CanvasController.extandCanvasDrawLayerCliprect(); // 그린 영역을 100% 다 포함하지 않아서 약간 늘려줌
                if (isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILLPEN))
                {
                    drawLayerAlpha.alphaMultiplier = PenTool.penAlpha;
                    if (CanvasController.isLayer2Selected)
                        CanvasController.canvasLayer2BitmapData.draw(CanvasController.canvasDrawLayerBitmap, null, drawLayerAlpha, (PenTool.isTransparentPenColor) ? "erase" : null, CanvasController.canvasDrawLayerClipRect);
                    else
                        CanvasController.canvasLayer1BitmapData.draw(CanvasController.canvasDrawLayerBitmap, null, drawLayerAlpha, (PenTool.isTransparentPenColor) ? "erase" : null, CanvasController.canvasDrawLayerClipRect);
                }
                else if (isSelectedTool(TOOL_ERASER))
                {
                    drawLayerAlpha.alphaMultiplier = PenTool.eraserAlpha;
                    if (CanvasController.isLayer2Selected)
                        CanvasController.canvasLayer2BitmapData.draw(CanvasController.canvasDrawLayerBitmap, null, drawLayerAlpha, "erase", CanvasController.canvasDrawLayerClipRect);
                    else
                        CanvasController.canvasLayer1BitmapData.draw(CanvasController.canvasDrawLayerBitmap, null, drawLayerAlpha, "erase", CanvasController.canvasDrawLayerClipRect);
                }
                rDataBuffer.push(["drawDone5", CanvasController.isLayer2Selected]);
                if (CanvasController.isLayer2Selected)
                    CanvasController.canvasLayer2Bitmap.bitmapData = CanvasController.canvasLayer2BitmapData;
                else
                    CanvasController.canvasLayer1Bitmap.bitmapData = CanvasController.canvasLayer1BitmapData;
                CanvasController.canvasDrawLayerBitmapData.fillRect(CanvasController.canvasDrawLayerClipRect, 0); // 그려준 영역만
                CanvasController.canvasDrawLayerChild.graphics.clear();
                undoManager.addNew();
            };
        }
        public function cLineTool():Function
        {
            const toDeg:Number = 180 / Math.PI;
            // const oldPoint:Point = new Point(0,0);
            var oldX:Number;
            var oldY:Number;
            var startPoint:Point = new Point();
            var endPoint:Point = new Point();
            var canvasSizeWidth:Number;
            var canvasSizeHeight:Number;
            var xSize:uint;
            var xColor:uint;
            var xAlpha:Number;
            var xShape:Boolean;
            var xBlendMode:String;
            var xAirBrushON:Boolean;
            var mouseMovedFlag:Boolean;
            var subLayerFlag:Boolean;
            function isTwoLineIntersection(x1:Number, y1:Number, x2:Number, y2:Number, x3:Number, y3:Number, x4:Number, y4:Number):Boolean
            {
                var denominator:Number = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);
                var numerator1:Number = (x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3);
                var numerator2:Number = (x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3);
                if (denominator == 0)
                {
                    // 두 선분이 평행하거나 일치함
                    return false;
                }
                var t1:Number = numerator1 / denominator;
                var t2:Number = numerator2 / denominator;
                if (t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1)
                {
                    // 두 선분이 교차함
                    return true;
                }
                else
                {
                    // 두 선분이 교차하지 않음
                    return false;
                }
            }
            // 중앙선+양옆선 3개의 선이 캔버스 4개의 선과 하나라도 닿으면 true를 반환함
            function isLineInsideCanvas():Boolean
            {
                if (CanvasController.canvasPanel.hitTestPoint(stage.mouseX, stage.mouseY, true))
                {
                    return true;
                }
                else
                {
                    const sideLine1:Array = getSideLine(startPoint.x, startPoint.y, endPoint.x, endPoint.y, xSize / 2, xShape);
                    const sideLine2:Array = getSideLine(startPoint.x, startPoint.y, endPoint.x, endPoint.y, -xSize / 2, xShape);
                    if (checkCollision(startPoint.x, startPoint.y, endPoint.x, endPoint.y)
                            || checkCollision(sideLine1[0], sideLine1[1], sideLine1[2], sideLine1[3])
                            || checkCollision(sideLine2[0], sideLine2[1], sideLine2[2], sideLine2[3]))
                    {
                        return true;
                    }
                }
                return false;
            }
            function checkCollision(x1:Number, y1:Number, x2:Number, y2:Number):Boolean
            {
                return isTwoLineIntersection(x1, y1, x2, y2, 0, 0, canvasSizeWidth, 0)
                    || isTwoLineIntersection(x1, y1, x2, y2, 0, 0, 0, canvasSizeHeight)
                    || isTwoLineIntersection(x1, y1, x2, y2, 0, canvasSizeHeight, canvasSizeWidth, canvasSizeHeight)
                    || isTwoLineIntersection(x1, y1, x2, y2, canvasSizeWidth, 0, canvasSizeWidth, canvasSizeHeight);
            }
            function getSideLine(x1:Number, y1:Number, x2:Number, y2:Number, distance:Number, squareCapFlag:Boolean):Array
            {
                // 길이를 약간 늘려줌
                if (!squareCapFlag)
                {
                    const pointVec:Array = extendLineSegment(x1, y1, x2, y2, Math.abs(distance));
                    x1 = pointVec[0];
                    y1 = pointVec[1];
                    x2 = pointVec[2];
                    y2 = pointVec[3];
                }
                // 선분의 방향 벡터
                var directionX:Number = x2 - x1;
                var directionY:Number = y2 - y1;
                // 선분의 방향 벡터를 정규화
                var magnitude:Number = Math.sqrt(directionX * directionX + directionY * directionY);
                var normalizedDirectionX:Number = directionX / magnitude;
                var normalizedDirectionY:Number = directionY / magnitude;
                var newDirectionX:Number = -normalizedDirectionY;
                var newDirectionY:Number = normalizedDirectionX;
                // 새로운 선분의 시작점과 끝점을 계산
                var newLineStartX:Number = x1 + distance * newDirectionX;
                var newLineStartY:Number = y1 + distance * newDirectionY;
                var newLineEndX:Number = x2 + distance * newDirectionX;
                var newLineEndY:Number = y2 + distance * newDirectionY;
                return [newLineStartX, newLineStartY, newLineEndX, newLineEndY];
            }
            // 선분 시작 끝점을 distance로 늘려서 좌표를 반환함
            function extendLineSegment(x1:Number, y1:Number, x2:Number, y2:Number, distance:Number):Array
            {
                // 선분의 방향 벡터 계산
                var directionX:Number = x2 - x1;
                var directionY:Number = y2 - y1;
                // 방향 벡터의 길이 계산
                var length:Number = Math.sqrt(directionX * directionX + directionY * directionY);
                // 방향 벡터를 정규화
                directionX /= length;
                directionY /= length;
                // 양 끝점 좌표 이동
                var extendedX1:Number = x1 - directionX * distance;
                var extendedY1:Number = y1 - directionY * distance;
                var extendedX2:Number = x2 + directionX * distance;
                var extendedY2:Number = y2 + directionY * distance;
                return [extendedX1, extendedY1, extendedX2, extendedY2];
            }
            function showDgreeHint():void
            {
                const ang:Number = Math.atan2(oldX - CanvasController.canvasDrawLayerChild.mouseX, oldY - CanvasController.canvasDrawLayerChild.mouseY);
                var deg:Number = ang * toDeg + 90;
                if (deg > 180)
                {
                    deg = deg - 90;
                }
                var degstr:String = Math.abs(deg % 90).toFixed(1) + "°";
                MainUI.showMouseHint(degstr);
            }
            function drawLine():void // 지우개인가 펜인가 구분해서 lineto 실시
            {
                CanvasController.canvasDrawLayerChild.graphics.clear();
                CanvasController.canvasDrawLayer.alpha = xAlpha;
                if (xShape)
                {
                    CanvasController.canvasDrawLayerChild.graphics.lineStyle(xSize, xColor, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND);
                }
                else
                {
                    CanvasController.canvasDrawLayerChild.graphics.lineStyle(xSize, xColor);
                }
                CanvasController.canvasDrawLayerChild.graphics.moveTo(startPoint.x, startPoint.y);
                CanvasController.canvasDrawLayerChild.graphics.lineTo(endPoint.x, endPoint.y);
            }
            function onMouseMoveLineTool(e:MouseEvent):void
            {
                if (!mouseMovedFlag)
                {
                    mouseMovedFlag = true;
                }
                const mx:Number = CanvasController.canvasDrawLayerChild.mouseX;
                const my:Number = CanvasController.canvasDrawLayerChild.mouseY;
                if (xShape === true)
                {
                    const extPoints:Array = extendLineSegment(oldX, oldY, mx, my, xSize / 8);
                    startPoint.setTo(extPoints[0], extPoints[1]);
                    endPoint.setTo(extPoints[2], extPoints[3]);
                }
                else
                {
                    startPoint.setTo(oldX, oldY);
                    endPoint.setTo(mx, my);
                }
                drawLine();
                showDgreeHint();
            }
            function onMouseUpLineTool(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveLineTool);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpLineTool);
                CanvasController.isPenSizeCursorInvisible = false;
                if (!ReferenceLayerController.isRefLayerEmpty() && ReferenceLayerController.isRefLayerMemoryTrainingON && ReferenceLayerController.refLayerLastAlpha > 0.0)
                {
                    ReferenceLayerController.setCanvasRefLayerVisibleDelay();
                }
                CanvasController.isMouseDragging = false;
                MainUI.hideMouseHint();
                if (isLineInsideCanvas() === true)
                {
                    const mx:Number = CanvasController.canvasDrawLayerChild.mouseX;
                    const my:Number = CanvasController.canvasDrawLayerChild.mouseY;
                    canAddUndoData = true;
                    if (mouseMovedFlag === false && oldX === mx && oldY === my)
                    {
                        rDataBuffer = [];
                        rDataBuffer.push(["dot4", xShape, xSize, xColor, xAlpha, mx, my, xBlendMode, subLayerFlag, xAirBrushON, CanvasController.canvasAnchorPoint.rotation]);
                        dotTool(xShape, xSize, xColor, mx, my, CanvasController.canvasAnchorPoint.rotation);
                    }
                    else
                    {
                        if (xShape === true)
                        {
                            const extPoints:Array = extendLineSegment(oldX, oldY, mx, my, xSize / 8);
                            startPoint.setTo(extPoints[0], extPoints[1]);
                            endPoint.setTo(extPoints[2], extPoints[3]);
                        }
                        else
                        {
                            startPoint.setTo(oldX, oldY);
                            endPoint.setTo(mx, my);
                        }
                        rDataBuffer.push(["line3", xShape, xSize, xColor, xAlpha, startPoint.x, startPoint.y, endPoint.x, endPoint.y, xBlendMode, subLayerFlag, airBrushSizeDrawMode]);
                        drawLine();
                    }
                }
                CanvasController.resetCanvasDrawLayerCliprect();
                drawDone();
            }
            return function (lineToolFlag:Boolean):void
            {
                CanvasController.isPenSizeCursorInvisible = true;
                xSize = PenTool.penSize;
                xAlpha = PenTool.penAlpha;
                xShape = PenTool.penIsSquare;
                xAirBrushON = isPenAirBrushON;
                if (PenTool.isTransparentPenColor)
                {
                    xColor = CanvasController.CANVAS_BG_COLOR;
                    xBlendMode = "erase";
                }
                else
                {
                    xColor = PenTool.penColor;
                    xBlendMode = null;
                    if (!ColorPickerController.isCurrentColorSamePickedColor())
                    {
                        ColorPickerController.updatePickerCurrentColor(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
                        PaletteController.addColorMyPaletteHistory(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
                    }
                }
                canvasSizeWidth = CanvasController.CANVAS_WIDTH;
                canvasSizeHeight = CanvasController.CANVAS_HEIGHT;
                mouseMovedFlag = false;
                oldX = CanvasController.canvasDrawLayerChild.mouseX;
                oldY = CanvasController.canvasDrawLayerChild.mouseY;
                subLayerFlag = CanvasController.isLayer2Selected;
                if (!ReferenceLayerController.isRefLayerEmpty() && ReferenceLayerController.isRefLayerMemoryTrainingON)
                {
                    ReferenceLayerController.setCanvasRefLayerInvisible();
                }
                // 캔버스2번 지워주고, draw판넬 데이터도 지워줌
                CanvasController.canvasDrawLayerBitmapData.dispose();
                CanvasController.canvasDrawLayerBitmap.bitmapData = null;
                CanvasController.canvasDrawLayerBitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
                // 선 관련 이벤트 함수 붙여줌
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveLineTool);
                stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpLineTool);
            };
        }
        public function resetRotationReplayMode():void
        {
            const center:Point = MainUIController.getStageCenterPos("replay");
            CanvasController.moveCanvasAnchorPoint(center.x, center.y, true);
            rCanvasAnchorPoint.rotation = 0;
            setRcursorRotation(0);
        }
        public function resetRotationDrawMode():void
        {
            const center:Point = MainUIController.getStageCenterPos("draw");
            updatePenSizeCursor();
            CanvasController.moveCanvasAnchorPoint(center.x, center.y, false);
            CanvasController.canvasAnchorPoint.rotation = 0;
            setRcursorRotation(0);
            CanvasController.canvasInfoBox.setRotate(0);
            MainUIController.updateCanvasNaigatorCursor();
        }
        public function cCanvasRotateTool():Function
        {
            var isReplayMode:Boolean;
            var xAnc:Sprite;
            var getAngle:Function;
            function onMouseMove():void
            {
                const ang:Number = getAngle(true);
                xAnc.rotation = ang;
                setRcursorRotation(xAnc.rotation);
                CanvasController.canvasInfoBox.setRotate(Math.abs(xAnc.rotation));
            }

            function onMouseUp():void
            {
                CanvasController.isPenSizeCursorInvisible = false;
                if (!isReplayMode)
                {
                    if (LassoTool.isLassoToolStarted)
                    {
                        if (LassoTool.isLassoMenuHiddenTemp === true)
                        {
                            LassoTool.hideLassoMenuBoxTemp();
                        }
                    }
                    updatePenSizeCursor();
                    ReferenceLayerController.setRefLayerAndGridVisible(true);
                    MainUIController.updateCanvasNaigatorCursor();
                }
                else
                {
                    if (isReplayCanvasFitToWindow)
                    {
                        fitReplayCanvasToViewport();
                    }
                    resetLastKey();
                    rFollowMouse.updateBounds();
                }
                MainUI.hideCanvasRotateCursor();
                CanvasController.keepCanvasPanelInStage(isReplayMode);
            }
            function onDragStart():void
            {
                CanvasController.isPenSizeCursorInvisible = true;
                if (!isReplayMode)
                {
                    ReferenceLayerController.setRefLayerAndGridVisible(false);
                }
                const center:Point = MainUIController.getStageCenterPos("replay");
                CanvasController.moveCanvasAnchorPoint(center.x, center.y, isReplayMode);
                // 캔버스 이동이 완료된후 함수를 초기화 시켜줌
                MainUI.hideBottomHint();
            }
            return function (fromReplayMode:Boolean):void
            {
                isReplayMode = fromReplayMode;
                xAnc = (isReplayMode) ? rCanvasAnchorPoint : CanvasController.canvasAnchorPoint;
                getAngle = MainUI.showCanvasRotateCursorMouseDrag(xAnc);
                DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
            };
        }
        public function cMoveTool():Function
        {
            var getMovedPos:Function;
            function onMouseUpMoveTool(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveMovetool);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpMoveTool);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpMoveTool);
                CanvasController.isMouseDragging = false;
                CanvasController.isPenSizeCursorInvisible = false;
                getMovedPos = null;
                var tmpbmpd:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
                const movex:Number = Math.floor(CanvasController.canvasLayer1Bitmap.x);
                const movey:Number = Math.floor(CanvasController.canvasLayer1Bitmap.y);
                const movex1:Number = Math.floor(CanvasController.canvasLayer2Bitmap.x);
                const movey1:Number = Math.floor(CanvasController.canvasLayer2Bitmap.y);
                var movedMat:Matrix = new Matrix();
                if (isDeepUndoEnabled)
                    applyDeepUndo();
                // 최종적으로 움직인 거리를 실제로 비트맵 데이터 조작
                if (CanvasController.checkedLayer === 0)
                {
                    if (CanvasController.canvasLayer1Bitmap.visible)
                    {
                        movedMat.translate(movex, movey);
                        tmpbmpd.draw(CanvasController.canvasLayer1BitmapData, movedMat);
                        CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, tmpbmpd, CanvasController.canvasLayer1Bitmap);
                    }
                    if (CanvasController.canvasLayer2Bitmap.visible)
                    {
                        movedMat = new Matrix();
                        movedMat.translate(movex1, movey1);
                        tmpbmpd.fillRect(new Rectangle(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT), 0);
                        tmpbmpd.draw(CanvasController.canvasLayer2BitmapData, movedMat);
                        CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, tmpbmpd, CanvasController.canvasLayer2Bitmap);
                    }
                }
                else if (CanvasController.checkedLayer === 1)
                {
                    movedMat.translate(movex, movey);
                    tmpbmpd.draw(CanvasController.canvasLayer1BitmapData, movedMat);
                    CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, tmpbmpd, CanvasController.canvasLayer1Bitmap);
                }
                else if (CanvasController.checkedLayer === 2)
                {
                    movedMat = new Matrix();
                    movedMat.translate(movex1, movey1);
                    tmpbmpd.fillRect(new Rectangle(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT), 0);
                    tmpbmpd.draw(CanvasController.canvasLayer2BitmapData, movedMat);
                    CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, tmpbmpd, CanvasController.canvasLayer2Bitmap);
                }
                tmpbmpd.dispose();
                tmpbmpd = null;
                CanvasController.canvasLayer1Bitmap.x = 0;
                CanvasController.canvasLayer1Bitmap.y = 0;
                CanvasController.canvasLayer2Bitmap.x = 0;
                CanvasController.canvasLayer2Bitmap.y = 0;
                if (LassoTool.isLassoToolStarted === false)
                {
                    var command:String = "move";
                    if (CanvasController.checkedLayer === 1)
                    {
                        command = "move1";
                        rDataBuffer.push([command, movex, movey]);
                    }
                    else if (CanvasController.checkedLayer === 2)
                    {
                        command = "move2";
                        rDataBuffer.push([command, movex1, movey1]);
                    }
                    else
                    {
                        if (!CanvasController.canvasLayer2Bitmap.visible)
                        {
                            command = "move1";
                            rDataBuffer.push([command, movex, movey]);
                        }
                        else if (!CanvasController.canvasLayer1Bitmap.visible)
                        {
                            command = "move2";
                            rDataBuffer.push([command, movex1, movey1]);
                        }
                        else
                        {
                            rDataBuffer.push([command, movex, movey]);
                        }
                    }
                    if (hasLastRDataCommand(command))
                        undoManager.addContinue();
                    else
                        undoManager.addNew();
                }
            }
            function onMouseMoveMovetool(e:MouseEvent):void
            {
                const pos:Point = getMovedPos();
                if (CanvasController.checkedLayer === 0)
                {
                    if (CanvasController.canvasLayer1Bitmap.visible)
                    {
                        CanvasController.canvasLayer1Bitmap.x = pos.x;
                        CanvasController.canvasLayer1Bitmap.y = pos.y;
                    }
                    if (CanvasController.canvasLayer2Bitmap.visible)
                    {
                        CanvasController.canvasLayer2Bitmap.x = pos.x;
                        CanvasController.canvasLayer2Bitmap.y = pos.y;
                    }
                }
                else if (CanvasController.checkedLayer === 1)
                {
                    CanvasController.canvasLayer1Bitmap.x = pos.x;
                    CanvasController.canvasLayer1Bitmap.y = pos.y;
                }
                else if (CanvasController.checkedLayer === 2)
                {
                    CanvasController.canvasLayer2Bitmap.x = pos.x;
                    CanvasController.canvasLayer2Bitmap.y = pos.y;
                }
            }
            return function ():void
            {
                if (CanvasController.isAllLayerInvisible())
                    return;
                getMovedPos = Utils.updateImagePosMouseDrag(CanvasController.canvasLayer1Bitmap, CanvasController.canvasAnchorPoint.rotation);
                CanvasController.isPenSizeCursorInvisible = true;
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveMovetool);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpMoveTool);
                stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpMoveTool);
            };
        }
        public function getCanvasBoundLimitPoint(canvas:Sprite, px:Number, py:Number, width:Number, height:Number, zoom:Number, rotation:Number):Point
        {
            // 매개변수 rotation은 음수값으로 넣어야 됨
            var zoomClickX:Number = px * zoom;
            var zoomClickY:Number = py * zoom;
            if (zoomClickX < 0)
                zoomClickX = 0;
            else if (zoomClickX > width * zoom)
                zoomClickX = width * zoom;
            if (zoomClickY < 0)
                zoomClickY = 0;
            else if (zoomClickY > height * zoom)
                zoomClickY = height * zoom;
            return Utils.rotatePoint(zoomClickX, zoomClickY, rotation);
        }
        public function cZoomTool():Function
        {
            const zoomMaxIndex:uint = CanvasController.canvasZoomMultiplerList.length - 1;
            const clickPos:Point = new Point(0, 0);
            const lastMousePos:Point = new Point(0, 0);
            const mouseMoveStep:int = 26; // 이 픽셀이상움직일때만 zoomcanvas를 실행
            var lastZoom:Number = 0.0;
            var startZoomIndex:int = 0;
            var dragDirection:int = 0; // 1이면 x축
            function fixMouseHintPos():void
            {
                MainUI.mouseHint.x = clickPos.x - MainUI.mouseHint.width / 2;
                MainUI.mouseHint.y = clickPos.y - 35 * Global.getUIScale();
            }
            function zoomToolMouseMoveEvent2(dist:Number):void
            {
                if (dist > mouseMoveStep)
                {
                    startZoomIndex--;
                }
                else
                {
                    startZoomIndex++;
                }
                if (startZoomIndex < 0)
                {
                    startZoomIndex = 0;
                }
                else if (startZoomIndex > zoomMaxIndex)
                {
                    startZoomIndex = zoomMaxIndex;
                }
                const zoomValue:Number = CanvasController.canvasZoomMultiplerList[startZoomIndex];
                CanvasController.canvasZoomIndex = startZoomIndex;
                CanvasController.updateCanvasScale(zoomValue, false);
                MainUI.showMouseHint(Math.floor(zoomValue * 100) + "%");
                fixMouseHintPos();
            }
            function onMouseMove():void
            {
                var abs:Function = Math.abs;
                var mx:Number = stage.mouseX;
                var my:Number = stage.mouseY;
                if (dragDirection === 0)
                {
                    if (abs(mx - lastMousePos.x) > 20)
                    {
                        dragDirection = 1;
                        lastMousePos.x = stage.mouseX;
                    }
                    else if (abs(my - lastMousePos.y) > 20)
                    {
                        dragDirection = 2;
                        lastMousePos.y = stage.mouseY;
                    }
                }
                else if (dragDirection === 1)
                {
                    const subX:Number = lastMousePos.x - mx;
                    if (abs(subX) > mouseMoveStep)
                    {
                        lastMousePos.x = stage.mouseX;
                        zoomToolMouseMoveEvent2(subX);
                    }
                }
                else if (dragDirection === 2)
                {
                    const subY:Number = my - lastMousePos.y;
                    if (abs(subY) > mouseMoveStep)
                    {
                        lastMousePos.y = stage.mouseY;
                        zoomToolMouseMoveEvent2(subY);
                    }
                }
            }
            function onMouseUp():void
            {
                CanvasController.isMouseDragging = false;
                CanvasController.isPenSizeCursorInvisible = false;
                MainUI.hideMouseHint();
                updatePenSizeCursor();
                ReferenceLayerController.setRefLayerAndGridVisible(true);
                if (LassoTool.isLassoMenuHiddenTemp === true)
                {
                    LassoTool.hideLassoMenuBoxTemp();
                }
                MainUIController.updateCanvasNaigatorCursor();
                if (CanvasGridOverlay.gridGapMultiplier > 0 && lastZoom !== CanvasController.canvasZoomMultipler)
                {
                    CanvasGridOverlay.drawGrid();
                }
            }
            return function ():void
            {
                function onDragStart():void
                {
                    lastZoom = CanvasController.canvasZoomMultipler;
                    dragDirection = 0;
                    // 클릭한 위치가 캔버스밖을 벗어날경우 줌 기준점을 캔버스 경계선에 닿도록 함
                    var gp:Point;
                    if (LassoTool.isLassoMenuHiddenTemp === true)
                    {
                        gp = LassoTool.lassoLayer1.localToGlobal(new Point(0, 0));
                        CanvasController.moveCanvasAnchorPoint(gp.x, gp.y, false);
                    }
                    else
                    {
                        gp = CanvasController.canvasPanel.localToGlobal(new Point(0, 0));
                        const panelLimitedPos:Point = getCanvasBoundLimitPoint(CanvasController.canvasPanel, CanvasController.canvasPanel.mouseX, CanvasController.canvasPanel.mouseY, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, CanvasController.canvasZoomMultipler, -CanvasController.canvasAnchorPoint.rotation);
                        // 캔버스 0,0점이 글로벌좌표 기준으로 어느 위치에 있는지 더해줘야함
                        CanvasController.moveCanvasAnchorPoint(panelLimitedPos.x + gp.x, panelLimitedPos.y + gp.y, false);
                    }
                    lastMousePos.setTo(stage.mouseX, stage.mouseY);
                    startZoomIndex = CanvasController.canvasZoomIndex;
                    CanvasController.isPenSizeCursorInvisible = true;
                    ReferenceLayerController.setRefLayerAndGridVisible(false);
                    clickPos.setTo(stage.mouseX, stage.mouseY);
                    MainUI.showMouseHint(Math.floor(CanvasController.canvasZoomMultipler * 100) + "%");
                    fixMouseHintPos();
                }
                DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
            };
        }
        // 비트맵 데이터를 대칭으로 돌려줌
        public function mirrorDraw():void
        {
            var tmpbmpd:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
            var flipMat:Matrix = new Matrix(-1, 0, 0, 1, CanvasController.CANVAS_WIDTH);
            tmpbmpd.draw(CanvasController.canvasLayer1BitmapData, flipMat);
            CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, tmpbmpd, CanvasController.canvasLayer1Bitmap);
            tmpbmpd.fillRect(new Rectangle(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT), 0);
            tmpbmpd.draw(CanvasController.canvasLayer2BitmapData, flipMat);
            CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, tmpbmpd, CanvasController.canvasLayer2Bitmap);
            tmpbmpd.dispose();
            tmpbmpd = null;
            CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
            }
        }

        public function syncMirrorReplayModeWithDrawMode():void
        {
            if (mirrorCommandReady)
            {
                mirrorCanvasReplayMode();
            }
        }

        public function updateCanvasSizeReplayMode(w:Number, h:Number, moveX:Number = 0, moveY:Number = 0, movedFlag:Boolean = false):void
        {
            if (w === RCANVAS_WIDTH && h === RCANVAS_HEIGHT)
            {
                return;
            }
            const bgColor:uint = RCANVAS_BG_COLOR;
            // 캔버스가 회전되어있으면 회전된 방향으로 움직여줘야함
            rCanvasPanel.graphics.clear();
            rCanvasPanel.graphics.beginFill(bgColor);
            rCanvasPanel.graphics.drawRect(0, 0, w, h);
            rCanvasPanel.graphics.endFill();
            rCanvasPanel.scrollRect = new Rectangle(0, 0, w, h); // 마스크 다시 씌워줌
            rCanvasLayer1BitmapData = new BitmapData(w, h, true, 0);
            rCanvasLayer2BitmapData = new BitmapData(w, h, true, 0);
            rCanvasDrawLayerBitmapData = new BitmapData(w, h, true, 0);
            RCANVAS_WIDTH = w;
            RCANVAS_HEIGHT = h;
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
            rFollowMouse.updateBounds();
            CanvasController.keepCanvasPanelInStage(true);
            if (isReplayCanvasFitToWindow)
            {
                fitReplayCanvasToViewport();
            }
        }





        public function cEyeDropperTool():Function
        {
            // 일단 흰색으로 배경 깔아줌
            const magSize:Number = eyedropperLens.magSize;
            const lensRect:Rectangle = new Rectangle(0, 0, magSize, magSize);
            const lensMat:Matrix = new Matrix();
            var penColorBackup:uint;
            var canvasBGShape:Shape = new Shape();
            function updateEyeDropperLensBitmap():void
            {
                const mid:Number = magSize / (4 * CanvasController.canvasZoomMultipler); // 4는 기본 중앙값 magsize/2에서 zoomed나워주고 기본이 2배줌이니까 2로 나눠준값
                const tx:Number = -CanvasController.canvasLayer1Bitmap.mouseX + mid;
                const ty:Number = -CanvasController.canvasLayer1Bitmap.mouseY + mid;
                lensMat.identity();
                lensMat.translate(tx, ty);
                lensMat.scale(2.0 * CanvasController.canvasZoomMultipler, 2.0 * CanvasController.canvasZoomMultipler);
                eyedropperLens.bitmap.bitmapData.fillRect(lensRect, MainUIController.STAGE_BG_COLOR);
                eyedropperLens.bitmap.bitmapData.draw(canvasBGShape, lensMat, null, null, lensRect);
                if (CanvasController.canvasLayer2Bitmap.visible)
                {
                    eyedropperLens.bitmap.bitmapData.draw(CanvasController.canvasLayer2Bitmap.bitmapData, lensMat, null, null, lensRect);
                }
                if (CanvasController.canvasLayer1Bitmap.visible)
                {
                    eyedropperLens.bitmap.bitmapData.draw(CanvasController.canvasLayer1Bitmap.bitmapData, lensMat, null, null, lensRect);
                }
            }
            function pickColor():uint
            {
                if (CanvasController.canvasLayer1Bitmap.hitTestPoint(stage.mouseX, stage.mouseY))
                {
                    // 배경색
                    const r3:uint = (CanvasController.CANVAS_BG_COLOR & 0xFF0000) >> 16;
                    const g3:uint = (CanvasController.CANVAS_BG_COLOR & 0x00FF00) >> 8;
                    const b3:uint = (CanvasController.CANVAS_BG_COLOR & 0x0000FF);
                    var aa:Number = 0;
                    var rr:uint = 0;
                    var gg:uint = 0;
                    var bb:uint = 0;
                    var a1:Number = 0;
                    var r1:uint = 0;
                    var g1:uint = 0;
                    var b1:uint = 0;
                    var a2:Number = 0;
                    var r2:uint = 0;
                    var g2:uint = 0;
                    var b2:uint = 0;
                    // 위 레이어
                    if (CanvasController.canvasLayer1Bitmap.visible)
                    {
                        const c1:uint = CanvasController.canvasLayer1BitmapData.getPixel32(CanvasController.canvasLayer1Bitmap.mouseX, CanvasController.canvasLayer1Bitmap.mouseY);
                        a1 = ((c1 & 0xFF000000) >>> 24) / 255;
                        r1 = (c1 & 0x00FF0000) >>> 16;
                        g1 = (c1 & 0x0000FF00) >>> 8;
                        b1 = (c1 & 0x000000FF);
                    }
                    // 밑 레이어
                    if (CanvasController.canvasLayer2Bitmap.visible)
                    {
                        const c2:uint = CanvasController.canvasLayer2BitmapData.getPixel32(CanvasController.canvasLayer1Bitmap.mouseX, CanvasController.canvasLayer1Bitmap.mouseY);
                        a2 = ((c2 & 0xFF000000) >>> 24) / 255;
                        r2 = (c2 & 0x00FF0000) >>> 16;
                        g2 = (c2 & 0x0000FF00) >>> 8;
                        b2 = (c2 & 0x000000FF);
                    }
                    // source over S 새로그린거 B는 원래 그려져 있던거
                    // aR : the union alpha (as + ab * (1 - as)) //알파 혼합
                    // r: ((S.r * S.a) + (B.r * B.a) * (1 - S.a)) / aR,
                    // g: ((S.g * S.a) + (B.g * B.a) * (1 - S.a)) / aR,
                    // b: ((S.b * S.a) + (B.b * B.a) * (1 - S.a)) / aR,
                    // 아래 레이어 부터
                    aa = 1.0 - a2;
                    rr = Math.round(r2 * a2) + Math.round(r3 * aa);
                    gg = Math.round(g2 * a2) + Math.round(g3 * aa);
                    bb = Math.round(b2 * a2) + Math.round(b3 * aa);
                    // 그 위에 위 레이어
                    const aa1:Number = 1.0 - a1;
                    const r:uint = Math.round(r1 * a1) + Math.round(rr * aa1);
                    const g:uint = Math.round(g1 * a1) + Math.round(gg * aa1);
                    const b:uint = Math.round(b1 * a1) + Math.round(bb * aa1);
                    return Global.RGBtoHEX(r, g, b);
                }
                else
                {
                    return penColorBackup;
                }
            }
            function onRightMouseDownEyeDropper(e:MouseEvent):void
            {
                exitEyeDropperTool(false);
            }
            function onKeyDownEyeDropper(e:KeyboardEvent):void
            {
                if (isNotEyeDropperTool())
                {
                    exitEyeDropperTool(false);
                    return;
                }
                if (e.keyCode === KEY.c || e.keyCode === KEY.m) {}
                else if (e.keyCode === KEY.space)
                {
                    if (PenTool.isTransparentPenColor)
                    {
                        ColorPickerController.selectCurrentColor(false);
                        MainUI.showMouseHintTemp("Current color selected");
                    }
                    else
                    {
                        ColorPickerController.selectCurrentColor(false);
                        if (PenTool.isTransparentPenColor === false)
                        {
                            ColorPickerController.selectTransparentColor();
                        }
                        MainUI.showMouseHintTemp("Transparent color selected");
                    }
                    exitEyeDropperTool(false);
                }
                else
                {
                    exitEyeDropperTool(false);
                }
            }
            function onKeyUpEyeDropper(e:KeyboardEvent):void
            {
                if (isNotEyeDropperTool())
                {
                    exitEyeDropperTool(false);
                    return;
                }
                if (e.keyCode === KEY.c || e.keyCode === KEY.m)
                {
                    confirmEyeDropperSelection();
                }
            }
            function onMouseDownEyeDropper(e:MouseEvent):void
            {
                if (isNotEyeDropperTool())
                {
                    exitEyeDropperTool(false);
                    return;
                }
                if (eyedropperLens.visible)
                {
                    confirmEyeDropperSelection();
                }
                else
                {
                    exitEyeDropperTool(false);
                }
            }
            function exitEyeDropperTool(okFlag:Boolean):void
            {
                removeEyedropperEvents();
                eyedropperLens.visible = false;
                // canvasRefLayer.visible = true;
                canvasBGShape.graphics.clear();
                ReferenceLayerController.setRefLayerAndGridVisible(true);
                if (okFlag)
                {
                    if (!(isLastTool(TOOL_FILLPEN)
                                || isLastTool(TOOL_LINE)
                                || isLastTool(TOOL_PEN)))
                    {
                        setLastTool(TOOL_PEN);
                    }
                }
                selectLastUsedTool();
            }
            function isNotEyeDropperTool():Boolean
            {
                return !isSelectedTool(TOOL_EYEDROPPER) || isReplayModeON || CaptureController.isCaptureModeON || FileManager.isFileBrowserOpened || CanvasController.isMouseClickBlocked;
            }
            function confirmEyeDropperSelection():void
            {
                var okFlag:Boolean = false;
                if (eyedropperLens.visible === true)
                {
                    okFlag = true;
                    const pickedColor:uint = pickColor();
                    PenTool.penColor = pickedColor;
                    ColorPickerController.pickerIgnoreHistoryColor = pickedColor;
                    ColorPickerController.updateColorPickerCursorPosAndRGBInfo(pickedColor);
                }
                exitEyeDropperTool(okFlag);
            }
            function onMouseMoveEyeDropper(e:MouseEvent):void
            {
                if (isNotEyeDropperTool())
                {
                    exitEyeDropperTool(false);
                    return;
                }
                eyedropperLens.x = stage.mouseX;
                eyedropperLens.y = stage.mouseY;
                if (canShowEyedropperLens())
                {
                    Global.setColorTransform(eyedropperLens.nowColor, pickColor());
                    if (CanvasController.canvasZoomMultipler < 12.0)
                    {
                        updateEyeDropperLensBitmap();
                    }
                    eyedropperLens.visible = true;
                }
                else
                {
                    eyedropperLens.visible = false;
                }
            }
            function removeEyedropperEvents():void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveEyeDropper);
                stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownEyeDropper);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownEyeDropper);
                stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpEyeDropper);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownEyeDropper);
            }
            function addEyedropperEvents():void
            {
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveEyeDropper);
                stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownEyeDropper, false, -2);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownEyeDropper, false, -2);
                stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpEyeDropper, false, 2);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownEyeDropper, false, 2);
            }
            function canShowEyedropperLens():Boolean
            {
                return isCursorInDrawArea() && CanvasController.canvasLayer1Bitmap.hitTestPoint(stage.mouseX, stage.mouseY, true)
                    && !(ReferenceLayerController.refLayerMenuBox.visible && ReferenceLayerController.refLayerMenuBox.hitTestPoint(stage.mouseX, stage.mouseY));
            }
            return function ():void
            {
                toolBox.moveToolCursor("toolEyedropper");
                if (CanvasController.checkedLayer !== 0)
                {
                    return;
                }
                if (CanvasController.isAllLayerInvisible())
                {
                    return;
                }
                updateLastTool();
                setLastTool(nowTool);
                setSelectedTool(TOOL_EYEDROPPER);
                penColorBackup = PenTool.penColor;
                Global.setColorTransform(eyedropperLens.oldColor, PenTool.penColor);
                moveEraserButtonToOtherTool("toolEyedropper");
                eyedropperLens.rotateBitmap(CanvasController.canvasAnchorPoint.rotation);
                ReferenceLayerController.setCanvasRefLayerInvisible();
                canvasBGShape.graphics.clear();
                canvasBGShape.graphics.beginFill(CanvasController.CANVAS_BG_COLOR);
                canvasBGShape.graphics.drawRect(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
                if (canShowEyedropperLens())
                {
                    eyedropperLens.x = stage.mouseX;
                    eyedropperLens.y = stage.mouseY;
                    Global.setColorTransform(eyedropperLens.nowColor, pickColor());
                    Utils.setAsTopChild(eyedropperLens);
                    if (CanvasController.canvasZoomMultipler < 12.0)
                    {
                        eyedropperLens.circleBox.visible = true;
                        updateEyeDropperLensBitmap();
                    }
                    else
                    {
                        eyedropperLens.circleBox.visible = false;
                    }
                    eyedropperLens.visible = true;
                }
                addEyedropperEvents();
            };
        }
        public function cHandTool():Function
        {
            const old:Point = new Point(0, 0);
            var isReplayMode:Boolean;
            var isDrawMode:Boolean;
            var xAnc:Sprite;
            var xBitmap:Bitmap;
            function onMouseUpHandTool(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandTool);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpHandTool);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpHandTool);
                stage.removeEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMouseUpHandTool);
                CanvasController.isMouseDragging = false;
                CanvasController.isPenSizeCursorInvisible = false;
                CanvasController.keepCanvasPanelInStage(isReplayMode);
                if (isDrawMode)
                {
                    ReferenceLayerController.setRefLayerAndGridVisible(true);
                    if (LassoTool.isLassoToolStarted)
                    {
                        if (LassoTool.isLassoMenuHiddenTemp === true)
                        {
                            LassoTool.hideLassoMenuBoxTemp();
                        }
                    } // tool box에서 클릭해서 핸드툴 들어갈때 필요함
                    else if (!isLastKey(KEY.space))
                    {
                        selectLastUsedTool();
                    }
                    toolBox.setCursorVisible(true);
                    MainUIController.updateCanvasNaigatorCursor();
                }
                else
                {
                    rFollowMouse.updateBounds();
                }
            }
            function onMouseMoveHandTool(e:MouseEvent):void
            {
                if (isReplayMode && isReplayRestartTimerON())
                {
                    onMouseUpHandTool(null);
                    return;
                }
                xAnc.x += (stage.mouseX - old.x);
                xAnc.y += (mouseY - old.y);
                old.setTo(stage.mouseX, stage.mouseY);
            }
            return function (fromReplayMode:Boolean, fromWheelClick:Boolean):void
            {
                CanvasController.isMouseDragging = true;
                isReplayMode = fromReplayMode;
                isDrawMode = !fromReplayMode;
                xAnc = (isDrawMode) ? CanvasController.canvasAnchorPoint : rCanvasAnchorPoint;
                xBitmap = (isDrawMode) ? CanvasController.canvasLayer1Bitmap : rCanvasLayer1Bitmap;
                old.setTo(stage.mouseX, stage.mouseY);
                CanvasController.isPenSizeCursorInvisible = true;
                if (isDrawMode)
                {
                    toolBox.setCursorVisible(false);
                    ReferenceLayerController.setRefLayerAndGridVisible(false);
                }
                if (fromWheelClick)
                {
                    stage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMouseUpHandTool);
                }
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandTool);
                stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpHandTool);
                // 윈도우 바깥에서 up을 하면 hand가 안꺼져서 오른쪽 마우스 뗄떼도 꺼주게함
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpHandTool);
            };
        }





        public function selectPenTool(lineFlag:Boolean = false):void
        {
            setSelectedTool((lineFlag) ? TOOL_LINE : TOOL_PEN);
            toggleAirBrushCheckBox(isPenAirBrushON, true);
            setDrawToolSize(PenTool.penSizeIndex);
            updateDrawToolAlpha(PenTool.penAlpha);
            updateOpacityCursorPos(PenTool.penAlphaIndex);
            moveEraserButtonToOtherTool((lineFlag) ? "toolLine" : "toolPen");
            toolBox.moveToolCursor((lineFlag) ? "toolLine" : "toolPen");
            updateToolOptionsTextBySelectedTool();
            toolOptionsBox.updatePenShapeSet(PenTool.penIsSquare);
            penCursorManager.check();
            if (toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }
            toolOptionsBox.enablePenSmoothingSlider();
        }
        public function selectLineTool():void
        {
            selectPenTool(true);
            toolOptionsBox.disablePenSmoothingSlider();
        }
        public function selectEraseTool():void
        {
            setSelectedTool(TOOL_ERASER);
            toggleAirBrushCheckBox(PenTool.isEraserAirBrushON, false);
            setDrawToolSize(PenTool.eraserSizeIndex);
            updateDrawToolAlpha(PenTool.eraserAlpha);
            updateOpacityCursorPos(PenTool.eraserAlphaIndex);
            if (lastEraserPosButton)
            {
                lastEraserPosButton.visible = true;
            }
            lastEraserPosButton = null;
            toolBox2.toolEraser.visible = false;
            toolBox.moveToolCursor("toolEraser");
            updateToolOptionsTextBySelectedTool();
            toolOptionsBox.updatePenShapeSet(PenTool.eraserIsSquare);
            penCursorManager.check();
            if (toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }
            toolOptionsBox.disablePenSmoothingSlider();
        }
        public function selectFillPenTool():void
        {
            setSelectedTool(TOOL_FILLPEN);
            toolBox.moveToolCursor("toolFillPen");
            CanvasController.penSizePreviewCursor.visible = false;
            updateOpacityCursorPos(PenTool.penAlphaIndex);
            toggleAirBrushCheckBox(isPenAirBrushON, true);
            toolOptionsBox.movePenSizeCursor(1);
            toolOptionsBox.setButtonsAlphaFillPenSelected(Global.OFFALPHA);
            moveEraserButtonToOtherTool("toolFillPen");
            updateToolOptionsTextBySelectedTool();
        }
        public function selectMoveTool():void
        {
            updateToolOptionsTextBySelectedTool();
            setSelectedTool(TOOL_MOVE);
            toolBox.moveToolCursor("toolMove");
            if (toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }
            toolOptionsBox.enablePenSmoothingSlider();
        }
        public function selectZoomTool():void
        {
            updateToolOptionsTextBySelectedTool();
            setSelectedTool(TOOL_ZOOM);
            toolBox.moveToolCursor("toolZoomIn", CanvasController.canvasInfoBox);
            if (toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }
            toolOptionsBox.enablePenSmoothingSlider();
        }
        public function selectRotateTool():void
        {
            updateToolOptionsTextBySelectedTool();
            setSelectedTool(TOOL_ROTATE);
            toolBox.moveToolCursor("toolRotate", CanvasController.canvasInfoBox);
            if (toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }
            toolOptionsBox.enablePenSmoothingSlider();
        }
        public function selectLassoTool():void
        {
            updateToolOptionsTextBySelectedTool();
            setSelectedTool(TOOL_LASSO);
            toolBox.moveToolCursor("toolLasso");
            moveEraserButtonToOtherTool("toolLasso");
            if (toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }
            toolOptionsBox.enablePenSmoothingSlider();
        }
        public function moveEraserButtonToOtherTool(toolName:String):void
        {
            const nowButton2:SimpleButton = toolBox2.getChildByName(toolName) as SimpleButton;
            if (!nowButton2)
                return;
            if (lastEraserPosButton)
            {
                if (lastEraserPosButton.x !== nowButton2.x
                        || lastEraserPosButton.y !== nowButton2.y) // 위치가 다를 때에만 보여줌
                {
                    lastEraserPosButton.visible = true;
                }
            }
            lastEraserPosButton = nowButton2;
            nowButton2.visible = false;
            toolBox2.toolEraser.visible = true;
            toolBox2.toolEraser.x = nowButton2.x;
            toolBox2.toolEraser.y = nowButton2.y;
            Utils.setAsTopChild(toolBox2.toolEraser);
        }



        public function getCanvasMovedUndo(index:int, redoFlag:Boolean):Point
        {
            const prevData:Array = (redoFlag) ? rData[index] : rData[index + 1];
            if (!prevData)
                return null;
            var len:uint = prevData.length;
            var xSum:Number = 0;
            var ySum:Number = 0;
            for (var i:uint = 0;i < len;i++)
            {
                if (prevData[i][0] === "canvasSize" && prevData[i][5] === true)
                {
                    xSum += prevData[i][3];
                    ySum += prevData[i][4];
                }
            }
            if (xSum === 0 && ySum === 0)
                return null;
            const movedXY:Point = (redoFlag) ? new Point(-xSum, -ySum)
                : new Point(xSum, ySum);
            return movedXY;
        }
        public function drawUndoData(redoFlag:Boolean = false):void
        {
            const undoRefData:Array = undoManager.getUndoBaseImage();
            const undoIndexSave:int = undoDataIndex;
            rDataReadFlag = true;
            rDataIndex = undoIndexSave;
            rPrevFrame = rNowFrame;
            rNowFrame = getNowFrameUntilUndoIndex(undoIndexSave);
            rMirrorON = undoRefData[5];
            if (undoRefData[2] !== RCANVAS_WIDTH || undoRefData[3] !== RCANVAS_HEIGHT)
            {
                updateCanvasSizeReplayMode(undoRefData[2], undoRefData[3], 0, 0, false);
            }
            if (undoRefData[4] !== RCANVAS_BG_COLOR)
            {
                updateCanvasBGColorReplayMode(undoRefData[4]);
            }
            rCanvasDrawShape.graphics.clear();
            rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, undoRefData[0], rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, undoRefData[1], rCanvasLayer2Bitmap);
            if (rData.length > 0)
            {
                for (var i:int = 0;i <= undoIndexSave;i++)
                {
                    if (!rData[i])
                        continue;
                    drawReplayByCommand.setData(rData[i]);
                    drawReplayByCommand.drawAll();
                }
            }
            ColorPickerController.updateCanvasBGColorDrawMode(RCANVAS_BG_COLOR);
            CanvasController.updateCavnvasSizeDrawMode(RCANVAS_WIDTH, RCANVAS_HEIGHT, 0, 0, false);
            // 앞 뒤 데이터가 캔버스 원점 이동 되었을때 반대방향으로 다시 움직여줌
            const movedRegPos:Point = getCanvasMovedUndo(undoIndexSave, redoFlag);
            if (movedRegPos)
            {
                CanvasController.canvasAnchorPoint.x += movedRegPos.x * CanvasController.canvasZoomMultipler;
                CanvasController.canvasAnchorPoint.y += movedRegPos.y * CanvasController.canvasZoomMultipler;
                ReferenceLayerController.updateRefLayerBitmapPos(movedRegPos);
            }
            CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, rCanvasLayer1BitmapData, CanvasController.canvasLayer1Bitmap);
            CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, rCanvasLayer2BitmapData, CanvasController.canvasLayer2Bitmap);
            showRCursorOnUndo(undoDataIndex);
            checkMirrorCanvasReplayMirror();
            CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
            CanvasController.keepCanvasPanelInStage(); // 사이즈가 크가 줄었을때 캔버스가 창 밖으로 나가는거 체크
            MainUIController.updateCanvasNaigatorCursor();
            FileManager.enableNewFileButton();
        }
        public function redo():void
        {
            if (isDeepUndoEnabled)
            {
                moveToNextStep();
                applyReplayCanvasToDrawModeCanvas();
                startAlphaFadeOut(rReplayFOFOCursor, 1.0, 0.3);
                if (rNowFrame >= undoManager.getRFileTotalFrame())
                {
                    disableDeepUndo();
                    undoDataIndex = -1;
                }
            }
            else
            {
                undoDataIndex++;
                if (undoDataIndex > rData.length - 1)
                {
                    FileManager.isFileAlreadySaved = false;
                    isDeleteUndoDataPending = false;
                    undoDataIndex = rData.length - 1;
                }
                else if (rData.length > 0)
                {
                    FileManager.isFileAlreadySaved = false;
                    drawUndoData(true);
                    startAlphaFadeOut(rReplayFOFOCursor, 1.0, 0.3);
                }
            }
        }
        public function undo():void
        {
            if (isGeneratingCacheImages())
            {
                removeKeyRepeatEvents(null);
                return;
            }
            if (isDeepUndoEnabled)
            {
                if (rNowFrame > 0)
                {
                    moveToPreviousStep();
                    applyReplayCanvasToDrawModeCanvas();
                    startAlphaFadeOut(rReplayFOFOCursor, 1.0, 0.3);
                }
            }
            else
            {
                undoDataIndex--;
                if (undoDataIndex < -1)
                {
                    FileManager.isFileAlreadySaved = false;
                    undoDataIndex = -1;
                    if (rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_READY || (rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_COMPLETE && undoManager.getRFileTotalFrame() > 0))
                    {
                        enableDeepUndo();
                        startAlphaFadeOut(rReplayFOFOCursor, 1.0, 0.3);
                    }
                }
                else if (rData.length > 0)
                {
                    FileManager.isFileAlreadySaved = false;
                    isDeleteUndoDataPending = true;
                    drawUndoData();
                    startAlphaFadeOut(rReplayFOFOCursor, 1.0, 0.3);
                }
            }
        }
        public function applyReplayCanvasToDrawModeCanvas():void
        {
            CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, rCanvasLayer1BitmapData, CanvasController.canvasLayer1Bitmap);
            CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, rCanvasLayer2BitmapData, CanvasController.canvasLayer2Bitmap);
            CanvasController.updateCavnvasSizeDrawMode(rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height, 0, 0, false);
            ColorPickerController.updateCanvasBGColorDrawMode(RCANVAS_BG_COLOR);
            CanvasController.keepCanvasPanelInStage(false);
            FileManager.isFileAlreadySaved = false;
            checkMirrorCanvasReplayMirror();
            CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, RCANVAS_BG_COLOR);
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
        }
        public function undoToIndex(index:int):void
        {
            undoDataIndex = index;
            FileManager.isFileAlreadySaved = false;
            FileManager.enableNewFileButton();
            drawUndoData();
        }
        public function cAddUndoData():Object
        {
            var dataWriteCount:uint = 0; // 데이터로 저장할때  rDataFrame 카운터 누적
            var rFileTotalFrame:Number = 0; // file에저장된 프레임수 누적해서 저장
            // undo 할때 이 데이터를 기준점으로 rData그려줌 메모리 적게 하려고
            var undoBaseImage:Array = [rFirstImageLayer1BitmapData.clone()
                    , rFirstImageLayer2BitmapData.clone()
                    , CanvasController.CANVAS_WIDTH
                    , CanvasController.CANVAS_HEIGHT
                    , CanvasController.CANVAS_BG_COLOR
                    , CanvasController.isCanvasMirrored];
            function resetRJumpImageCount():void
            {
                dataWriteCount = 0;
            }
            function updateUndoBaseImageMirrorFlag(flag:Boolean):void
            {
                undoBaseImage[5] = flag;
            }
            function updateUndoBaseImageFromReplayMode():void
            {
                undoManager.updateUndoBaseImage(rCanvasLayer1BitmapData.clone(),
                        rCanvasLayer2BitmapData.clone(),
                        rCanvasLayer1BitmapData.width,
                        rCanvasLayer1BitmapData.height,
                        RCANVAS_BG_COLOR,
                        rMirrorON);
            }
            function updateUndoBaseImageFromDrawMode():void
            {
                undoManager.updateUndoBaseImage(CanvasController.canvasLayer1BitmapData.clone(),
                        CanvasController.canvasLayer2BitmapData.clone(),
                        CanvasController.canvasLayer1BitmapData.width,
                        CanvasController.canvasLayer1BitmapData.height,
                        CanvasController.CANVAS_BG_COLOR,
                        CanvasController.isCanvasMirrored);
            }
            function updateReplayCanvasFromUndoBaseInfo():void
            {
                var rMirrorSave:Boolean = rMirrorON;
                if (undoBaseImage[2] !== RCANVAS_WIDTH || undoBaseImage[3] !== RCANVAS_HEIGHT)
                {
                    updateCanvasSizeReplayMode(undoBaseImage[2], undoBaseImage[3], 0, 0, false);
                }
                if (undoBaseImage[4] !== RCANVAS_BG_COLOR)
                {
                    updateCanvasBGColorReplayMode(undoBaseImage[4]);
                }
                rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, undoBaseImage[0], rCanvasLayer1Bitmap);
                rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, undoBaseImage[1], rCanvasLayer2Bitmap);
                drawReplayByCommand.setData(rData[0]);
                drawReplayByCommand.drawAll();
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
                undoBaseImage[2] = RCANVAS_WIDTH;
                undoBaseImage[3] = RCANVAS_HEIGHT;
                undoBaseImage[4] = RCANVAS_BG_COLOR;
                if (rMirrorON !== rMirrorSave)
                {
                    undoBaseImage[5] = !undoBaseImage[5];
                }
                drawReplayByCommand.setFirstRCursorPosCurrent();
            }
            function getUndoBaseImage():Array
            {
                return undoBaseImage;
            }
            function updateUndoBaseImage(bmpd1:BitmapData, bmpd2:BitmapData, width:Number, height:Number, bgColor:uint, mirrorFlag:Boolean):void
            {
                if (undoBaseImage[0] && bmpd1 !== undoBaseImage[0])
                {
                    undoBaseImage[0].dispose();
                }
                if (undoBaseImage[1] && bmpd2 !== undoBaseImage[1])
                {
                    undoBaseImage[1].dispose();
                }
                undoBaseImage[0] = bmpd1;
                undoBaseImage[1] = bmpd2;
                undoBaseImage[2] = width;
                undoBaseImage[3] = height;
                undoBaseImage[4] = bgColor;
                undoBaseImage[5] = mirrorFlag;
            }
            // undo index까지의 프레임 합을 구함
            function getRDataTotalFrame(index:int):Number
            {
                if (index < 0)
                {
                    return 0;
                }
                var sum:Number = 0;
                for (var i:int = 0;i <= index;i++)
                {
                    sum += rDataFrame[i];
                }
                return sum;
            }
            function getRFileTotalFrame():Number
            {
                return rFileTotalFrame;
            }
            function setRFileTotalFrame(frame:Number):void
            {
                rFileTotalFrame = frame;
            }
            // 미러가 되어있는지 확인해서 mirror커맨드를 무조건 앞으로 보냄
            // 그게 아니면 미러 커맨드 지워줌
            function updateLastRDataMirror():void
            {
                var popArr:Array;
                if (mirrorCommandReady)
                {
                    // 마지막 데이터에 1개만의 미러 커맨드가 있으먼 미러를 무효로함 mirror mirror니까 원래대로임
                    if (rData.length > 0 && rData[rData.length - 1].length === 1 && rData[rData.length - 1][0][0] === "mirror")
                    {
                        mirrorCommandReady = false;
                        rData.pop();
                        rDataFrame.pop();
                    } // 그게 아니면 가장 앞에 미러커맨드를 넣어줌
                    else if (rDataBuffer.length > 0 && rDataBuffer[0][0] !== "mirror")
                    {
                        mirrorCommandReady = false;
                        rDataBuffer.unshift(["mirror"]);
                    }
                }
                else
                {
                    // 미러 커맨드가 꺼져있는데 독립인 미러커맨드가 있으면 지워주고 미러 커맨드 플래그를 올려줘서 다음번에
                    // 미러 커맨드가 가장 앞에 오도록함
                    if (rData.length > 0 && rData[rData.length - 1].length === 1 && rData[rData.length - 1][0][0] === "mirror")
                    {
                        rData.pop();
                        rDataFrame.pop();
                        mirrorCommandReady = true;
                    } // 그게 아니면 그냥 지워줌
                    else if (rDataBuffer.length > 0 && rDataBuffer[0][0] === "mirror")
                    {
                        rDataBuffer.shift();
                    }
                }
            }
            // 끝 부분 중복처리 일때 넣어주는 거
            function addContinue():void
            {
                if (rData.length === 0)
                    return;
                if (isDeleteUndoDataPending)
                {
                    isDeleteUndoDataPending = false;
                    rData.splice(undoDataIndex + 1);
                    rDataFrame.splice(undoDataIndex + 1);
                }
                updateLastRDataMirror();
                // 버퍼에mirror가 있을수도 있기 때문에 요소를 하나씩 push해주어야함
                const len:uint = rDataBuffer.length;
                for (var i:uint = 0;i < len;i++)
                {
                    rData[rData.length - 1].push(rDataBuffer[i]); // 배열안에 배열이 들어있음
                }
                rDataFrame[rDataFrame.length - 1] = rData[rData.length - 1].length;
                rDataBuffer = [];
                rPrevFrame = rNowFrame;
                rNowFrame = getTotalFrame();
                CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
                if (ImageViewWindow.isCanvasWindowON)
                {
                    ImageViewWindow.updateCanvasWindowImage();
                    ImageViewWindow.updateCanvasWindowBitmapSize();
                }
            }
            function addNew():void
            {
                if (isDeleteUndoDataPending === true)
                {
                    isDeleteUndoDataPending = false;
                    rData.splice(undoDataIndex + 1);
                    rDataFrame.splice(undoDataIndex + 1);
                }
                if (rData.length >= 10) // 첫번째 이미지는 빼야하니깐 -1로 계산해야함
                {
                    var oldData:Array = rData[0];
                    if (oldData.length > 0)
                    {
                        const fs:FileStream = new FileStream();
                        const c:uint = rDataFrame[0];
                        const rf:File = FileManager.replayDataFilePath;
                        fs.open(rf, FileMode.APPEND);
                        fs.writeObject(oldData);
                        fs.close();
                        oldData = null;
                        rFileTotalFrame += c;
                        dataWriteCount += c;
                        updateReplayCanvasFromUndoBaseInfo();
                        if (rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_COMPLETE)
                        {
                            if (dataWriteCount > REPLAY_DISK_CACHE_FRAME_INTERVAL)
                            {
                                dataWriteCount = 0;
                                const data:Array = undoBaseImage;
                                const bmpd:BitmapData = data[0];
                                const bmpd1:BitmapData = data[1];
                                const w:int = data[2];
                                const h:int = data[3];
                                const bgColor:uint = data[4];
                                var imgData:ByteArray = new ByteArray();
                                var imgData1:ByteArray = new ByteArray();
                                const newRectangle:Rectangle = new Rectangle(0, 0, w, h);
                                bmpd.copyPixelsToByteArray(newRectangle, imgData);
                                bmpd1.copyPixelsToByteArray(newRectangle, imgData1);
                                // 위에서 쓰고나서 가능한 바이트랑 실제 바이트는 rf.size랑 다름, rf.size가 정확함
                                if (BackgroundWorkerCoordinator.receivedUndoImageQueueFromWorker === null)
                                    BackgroundWorkerCoordinator.receivedUndoImageQueueFromWorker = [];
                                if (BackgroundWorkerCoordinator.undoDataQueue === null)
                                    BackgroundWorkerCoordinator.undoDataQueue = [];
                                BackgroundWorkerCoordinator.undoDataQueue.push([w, h, bgColor, rf.size, rFileTotalFrame, CanvasController.isCanvasMirrored]);
                                BackgroundWorkerCoordinator.startUndoImageCompressionWorker(imgData, imgData1);
                                BackgroundWorkerCoordinator.pollTimerWaitWorkerForCacheUndoData();
                            }
                        }
                    }
                    rData[0].length = 0;
                    rData[0] = null;
                    rDataFrame[0] = null;
                    rData.shift();
                    rDataFrame.shift();
                }
                updateLastRDataMirror();
                if (rDataBuffer.length > 0)
                {
                    rData.push(rDataBuffer);
                    rDataFrame.push(rDataBuffer.length);
                    rDataBuffer = [];
                    FileManager.isFileAlreadySaved = false;
                    rDataReadFlag = true;
                }
                undoDataIndex = rData.length - 1;
                CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
                if (ImageViewWindow.isCanvasWindowON)
                {
                    ImageViewWindow.updateCanvasWindowImage();
                }
                rPrevFrame = rNowFrame;
                rNowFrame = getTotalFrame();
                FileManager.enableNewFileButton();
            };
            return {
                    addNew: addNew,
                    addContinue: addContinue,
                    setRFileTotalFrame: setRFileTotalFrame,
                    getRFileTotalFrame: getRFileTotalFrame,
                    getRDataTotalFrame: getRDataTotalFrame,
                    getUndoBaseImage: getUndoBaseImage,
                    updateUndoBaseImage: updateUndoBaseImage,
                    updateUndoBaseImageFromReplayMode: updateUndoBaseImageFromReplayMode,
                    updateUndoBaseImageFromDrawMode: updateUndoBaseImageFromDrawMode,
                    updateUndoBaseImageMirrorFlag: updateUndoBaseImageMirrorFlag,
                    resetRJumpImageCount: resetRJumpImageCount,
                    updateLastRDataMirror: updateLastRDataMirror
                };
        }
        public function handlePenOpacitySizeKeyDown(keyCode:uint):Boolean
        {
            switch (keyCode)
            {
                case KEY.f:
                case KEY.h:
                    startKeyRepeat(true, adjustDrawToolSizeByShortcut, true);
                    return true;
                case KEY.v:
                case KEY.n:
                    startKeyRepeat(true, adjustDrawToolSizeByShortcut, false);
                    return true;
                case KEY.g:
                CanvasController.canvasPanel.x= savepos[0];
                CanvasController.canvasPanel.y= savepos[1];
                CanvasController.canvasAnchorPoint.x= savepos[2];
                CanvasController.canvasAnchorPoint.y= savepos[3];

                    startKeyRepeat(true, adjustDrawToolAlphaByShortcut, true);
                    return true;
                case KEY.b:
                    startKeyRepeat(true, adjustDrawToolAlphaByShortcut, false);
                    return true;
            }
            return false;
        }
        
        public function selectOpacityButton(targetName:String):void
        {
            const number:String = targetName.substr(11, targetName.length);
            const index:int = parseInt(number);
            updateDrawToolAlpha(PenTool.penAlphaList[index]);
        }
        // opabox의 커서 위치와 색깔을 바꿈
        public function updateOpacityCursorPos(index:int):void
        {
            if (index <= 0)
                return;
            const curButton:Sprite = toolOptionsBox.opaBox.getChildByName("alphaButton" + index) as Sprite;
            if (!curButton)
                return;
            toolOptionsBox.opaCursor.x = curButton.x;
            toolOptionsBox.opaCursor.y = curButton.y;
        }
        public function cDrawDot():Function
        {
            const cmd:Vector.<int> = new Vector.<int>();
            const pos:Vector.<Number> = new Vector.<Number>();
            return function (shape:Boolean, size:uint, color:uint, posX:Number, posY:Number, rotation:Number):void
            {
                CanvasController.canvasDrawLayerChild.graphics.clear();
                CanvasController.canvasDrawLayerChild.graphics.lineStyle(0, 0, 0);
                CanvasController.canvasDrawLayerChild.graphics.beginFill(color);
                if (shape === true)
                {
                    cmd.length = 0;
                    pos.length = 0;
                    const p0:Point = Utils.rotatePoint(-size / 2, -size / 2, rotation);
                    cmd.push(1);
                    pos.push(posX + p0.x);
                    pos.push(posY + p0.y);
                    const p1:Point = Utils.rotatePoint(+size / 2, -size / 2, rotation);
                    cmd.push(2);
                    pos.push(posX + p1.x);
                    pos.push(posY + p1.y);
                    const p2:Point = Utils.rotatePoint(+size / 2, +size / 2, rotation);
                    cmd.push(2);
                    pos.push(posX + p2.x);
                    pos.push(posY + p2.y);
                    const p3:Point = Utils.rotatePoint(-size / 2, +size / 2, rotation);
                    cmd.push(2);
                    pos.push(posX + p3.x);
                    pos.push(posY + p3.y);
                    CanvasController.canvasDrawLayerChild.graphics.drawPath(cmd, pos);
                }
                else
                {
                    CanvasController.canvasDrawLayerChild.graphics.drawCircle(posX, posY, size / 2);
                }
                CanvasController.canvasDrawLayerChild.graphics.endFill();
            };
        }
        public function initializeReplayCanvas():void
        {
            rCanvasPanel.name = "rCanvasPanel";
            rCanvasAnchorPoint.name = "rCanvasAnchorPoint";
            rCanvasLayer1Bitmap.name = "rCanvasLayer1Bitmap";
            rCanvasLayer2Bitmap.name = "rCanvasLayer2Bitmap";
            rCanvasCompleteBitmap.name = "rCanvasCompleteBitmap";
            rCanvasCompleteAnchorPoint.name = "rCanvasCompleteAnchorPoint";
            rCanvasDrawLayer.name = "rCanvasDrawLayer";
            rCanvasDrawShape.name = "rCanvasDrawShape";
            MainUI.seekBarBox.name = "seekBarBox";
            rReplayFOFOCursor.name = "rCursor";
            rReplayFOFOCursor.mouseEnabled = false;
            rCanvasCompleteAnchorPoint.addChild(rCanvasCompleteBitmap);
            rCanvasPanel.graphics.beginFill(CanvasController.CANVAS_BG_COLOR);
            rCanvasPanel.graphics.drawRect(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
            rCanvasPanel.graphics.endFill();
            rCanvasDrawLayer.addChild(rCanvasDrawLayerBitmap);
            rCanvasDrawLayer.addChild(rCanvasDrawShape);
            rCanvasDrawLayer.blendMode = "layer"; // 캔버스1이랑 알파 불투명도가 겹치지 않게 layer모드로 해줌
            rCanvasPanel.addChild(rCanvasLayer2Bitmap);
            rCanvasPanel.addChild(rCanvasLayer1Bitmap);
            rCanvasPanel.addChild(rCanvasDrawLayer);
            rCanvasPanel.scrollRect = new Rectangle(0, 0, RCANVAS_WIDTH, RCANVAS_HEIGHT); // 마스크 해줘서 판 밖으로 선나타나지 않도록함
            rCanvasPanel.x = Math.floor(-rCanvasPanel.width / 2);
            rCanvasPanel.y = Math.floor(-rCanvasPanel.height / 2);
            rCanvasAnchorPoint.addChild(rCanvasPanel);
            rCanvasAnchorPoint.visible = false;
            stage.addChild(rCanvasAnchorPoint);
            stage.addChild(MainUI.seekBarBox);
            MainUI.seekBarBox.x = 0;
        }

        public function loadAppState():void
        {
            const fs:FileStream = new FileStream();
            var arr:Array = [];
            var newRectangle:Rectangle;
            const firstCachedImage:File = FileManager.replayCacheImageFolderPath.resolvePath("0");
            // 앱 경로에 마지막 저장 파일이 있으면 끄기전의 상태로 세팅해줌
            if (firstCachedImage.exists)
            {
                fs.open(firstCachedImage, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();
                if (arr[1] is ByteArray === false)
                {
                    arr[0].uncompress();
                    newRectangle = new Rectangle(0, 0, arr[1], arr[2]);
                    if (rFirstImageLayer1BitmapData)
                        rFirstImageLayer1BitmapData.dispose();
                    rFirstImageLayer1BitmapData = new BitmapData(arr[1], arr[2], true, 0);
                    rFirstImageLayer1BitmapData.lock();
                    rFirstImageLayer1BitmapData.setPixels(newRectangle, arr[0]);
                    rFirstImageLayer1BitmapData.unlock();
                    if (rFirstImageLayer2BitmapData)
                        rFirstImageLayer2BitmapData.dispose();
                    rFirstImageLayer2BitmapData = new BitmapData(arr[1], arr[2], true, 0);
                    rFirstImageBGColor = arr[3];
                }
                else
                {
                    arr[0].uncompress();
                    newRectangle = new Rectangle(0, 0, arr[2], arr[3]);
                    if (rFirstImageLayer1BitmapData)
                        rFirstImageLayer1BitmapData.dispose();
                    rFirstImageLayer1BitmapData = new BitmapData(arr[2], arr[3], true, 0);
                    rFirstImageLayer1BitmapData.lock();
                    rFirstImageLayer1BitmapData.setPixels(newRectangle, arr[0]);
                    rFirstImageLayer1BitmapData.unlock();
                    arr[1].uncompress();
                    if (rFirstImageLayer2BitmapData)
                        rFirstImageLayer2BitmapData.dispose();
                    rFirstImageLayer2BitmapData = new BitmapData(arr[2], arr[3], true, 0);
                    rFirstImageLayer2BitmapData.lock();
                    rFirstImageLayer2BitmapData.setPixels(newRectangle, arr[1]);
                    rFirstImageLayer2BitmapData.unlock();
                    rFirstImageBGColor = arr[4];
                }
            }
            else
            {
                rFirstImageLayer1BitmapData.dispose();
                rFirstImageLayer2BitmapData.dispose();
                rFirstImageLayer1BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
                rFirstImageLayer2BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
            }
            if (ReferenceLayerController.refLayerImageFilePath.exists)
            {
                fs.open(ReferenceLayerController.refLayerImageFilePath, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();
                // arr[0].uncompress();
                newRectangle = new Rectangle(0, 0, arr[1], arr[2]);
                var tmpbmpd:BitmapData = new BitmapData(arr[1], arr[2], true, 0);
                tmpbmpd.lock();
                tmpbmpd.setPixels(newRectangle, arr[0]);
                tmpbmpd.unlock();
                ReferenceLayerController.canvasRefLayerBitmapData = CanvasController.updateBitmapData(ReferenceLayerController.canvasRefLayerBitmapData, tmpbmpd, ReferenceLayerController.canvasRefLayerBitmap);
                ReferenceLayerController.canvasRefLayerBitmap.smoothing = true;
                tmpbmpd.dispose();
                tmpbmpd = null;
            }
            if (FileManager.replayCacheImageFrameDataFilePath.exists)
            {
                fs.open(FileManager.replayCacheImageFrameDataFilePath, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();
                rJumpImageFrameData = arr.concat();
            }
            if (FileManager.myPaletteDataFilePath.exists)
            {
                fs.open(FileManager.myPaletteDataFilePath, FileMode.READ);
                var list:Array = fs.readObject();
                PaletteController.myPalettePreset = list.concat();
                list.length = 0;
                list = null;
            }
            if (FileManager.undoDataFilePath.exists)
            {
                loadUndoData(); // undo data 복구 먼저 해줘야함
            }
            if (FileManager.scratchPadDataFilePath.exists)
            {
                FileManager.loadScratchPadImage();
            }
            if (FileManager.appStateFilePath.exists)
            {
                fs.open(FileManager.appStateFilePath, FileMode.READ);
                const appStateObject:AppStateManager = fs.readObject() as AppStateManager;
                fs.close();
                // loadUndoData함수에서 canvaspanel이 호출되는데 이전에 reflayer 이미지 정보값을 넣어두어야함
                // 그냥 해주면 창크기 적용이 안되서 타이머 걸어줌
                FOFOTimer.addByName("loadAppDataDelayTimer", 0.2, false, function ():void
                {
                    stage.nativeWindow.width = appStateObject.stageNativeWindowWidth;
                    stage.nativeWindow.height = appStateObject.stageNativeWindowHeight;
                    stage.nativeWindow.x = appStateObject.stageNativeWindowX;
                    stage.nativeWindow.y = appStateObject.stageNativeWindowY;
                    MainUIController.lastAppWindowSize.width = appStateObject.stageNativeWindowWidth;
                    MainUIController.lastAppWindowSize.height = appStateObject.stageNativeWindowHeight;

                    // 캔버스 위치까지 전부 다해준 다음에 이전 상태가 풀스크린이었으면 세팅해줌
                    if (appStateObject.lastWindowState === 1)
                        stage.nativeWindow.maximize();

                    Global.setScaleIndex(appStateObject.uiScaleIndex);
                    MainUIController.applyUIScale();
                    Global.setUIColorIndex(appStateObject.uiColorIndex);
                    MainUIController.applyUIColorSet();

                    CanvasController.canvasZoomIndex = appStateObject.canvasZoomIndex;
                    CanvasController.updateCanvasScale(appStateObject.canvasZoomedMultiplier);
                    CanvasController.canvasPanel.x = appStateObject.canvasPanelX;
                    CanvasController.canvasPanel.y = appStateObject.canvasPanelY;
                    CanvasController.canvasAnchorPoint.x = appStateObject.canvasAnchorPointX;
                    CanvasController.canvasAnchorPoint.y = appStateObject.canvasAnchorPointY;
                    savepos[0] =appStateObject.canvasPanelX;
                    savepos[1] =appStateObject.canvasPanelY;
                    savepos[2] =appStateObject.canvasAnchorPointX;
                    savepos[3] =appStateObject.canvasAnchorPointY;
                    CanvasController.canvasAnchorPoint.rotation = appStateObject.canvasAnchorPointRotation;
                    setRcursorRotation(appStateObject.canvasAnchorPointRotation);
                    MainUIController.updateResizeButtonPos(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
                    CanvasController.canvasRotateCursor.rotateArrow.rotation = appStateObject.canvasAnchorPointRotation;

                    PenTool.penSmoothValue = appStateObject.penSmoothValue;
                    PenTool.penSmoothSlideValue = appStateObject.penSmoothSlideValue;
                    toolOptionsBox.penSmoothSliderCursor.x = appStateObject.penSmoothButtonX;
                    PenTool.penSize = appStateObject.penSize;
                    PenTool.penColor = appStateObject.penColor;

                    ColorPickerController.hsvColorData[0] = appStateObject.hsvColorData0; // 순서 중요 이게 먼저오고 밑에 rgb info갱신해주어야함
                    ColorPickerController.isHSVInfoTextMode = appStateObject.isHSVInfoTextMode;
                    ColorPickerController.updatePickerCurrentColor(PenTool.penColor);
                    ColorPickerController.updateColorPickerCursorPosAndRGBInfo(PenTool.penColor);
                    ColorPickerController.colorPickerBox.updateHueColor(appStateObject.svBaseColor);
                    ColorPickerController.colorPickerBox.hueCursor.x = appStateObject.hueCursorX;

                    PenTool.penAlpha = appStateObject.penAlpha;
                    PenTool.penAlphaIndex = PenTool.penAlphaList.indexOf(appStateObject.penAlpha);
                    updateDrawToolAlpha(appStateObject.penAlpha);
                    PenTool.penIsSquare = appStateObject.penIsSquare;
                    PenTool.penListShapeIsSqare = appStateObject.penIsSquare;
                    toolOptionsBox.updatePenShapeSet(appStateObject.penIsSquare);

                    PenTool.eraserSize = appStateObject.eraseSize;
                    PenTool.eraserIsSquare = appStateObject.eraserIsSquare;
                    PenTool.eraserAlpha = appStateObject.eraseAlpha;
                    PenTool.eraserAlphaIndex = PenTool.penAlphaList.indexOf(appStateObject.eraseAlpha);
                    PenTool.eraserSizeIndex = appStateObject.eraseSizeIndex;
                    setDrawToolSize(appStateObject.penSizeIndex);

                    FileManager.lastSaveFilePath = appStateObject.saveFilePath;
                    FileManager.lastSaveFileName = appStateObject.saveFileName;
                    if (FileManager.lastSaveFilePath === FileManager.lastSaveFileName)
                    {
                        FileManager.lastSaveFilePath = File.desktopDirectory.nativePath + File.separator + FileManager.lastSaveFileName;
                    }

                    realWorkingTimer.setRunningTime(appStateObject.appRunningTime);
                    realWorkingTimer.update();

                    ReferenceLayerController.refLayerLastAlpha = appStateObject.refLayerLastAlpha;
                    ReferenceLayerController.canvasRefLayer.alpha = appStateObject.refLayerLastAlpha;
                    ReferenceLayerController.refLayerMenuBox.refOpacityCursor.x = appStateObject.refOpacityCursorX;
                    ReferenceLayerController.refLayerMenuBox.x = appStateObject.refLayerMenuBox0;
                    ReferenceLayerController.refLayerMenuBox.y = appStateObject.refLayerMenuBox1;
                    ReferenceLayerController.refLayerMenuDragXMoveSum = appStateObject.refLayerMenuDragXMoveSum;

                    if (appStateObject.isRefLayerMemoryTrainingON)
                    {
                        ReferenceLayerController.isRefLayerMemoryTrainingON = false;
                        ReferenceLayerController.toggleRefLayerMemoryTraining();
                    }

                    SidebarController.isRightSidebar = appStateObject.isRightSidebar;
                    SidebarController.isSidebarVisible = appStateObject.isSidebarVisible;
                    if (appStateObject.isRightSidebar)
                        SidebarController.moveSideBar("right", true);
                    if (!appStateObject.isSidebarVisible)
                        SidebarController.hideSidebarPermanent();

                    rReplayImageCacheState = appStateObject.rReplayImageCacheState;
                    rLastCanvasBGColor = appStateObject.rLastCanvasBGColor;
                    drawReplayByCommand.setFirstRCursorPos(appStateObject.getFirstRCursorPosX, appStateObject.getFirstRCursorPosY);

                    ReferenceLayerController.updateRefLayerImageTransform(
                        appStateObject.canvasRefLayerBitmapX,
                        appStateObject.canvasRefLayerBitmapY,
                        appStateObject.canvasRefLayerRotation,
                        appStateObject.canvasRefLayerScaleX,
                        appStateObject.canvasRefLayerScaleY
                    );

                    if (CanvasController.isCanvasMirrored !== appStateObject.isCanvasMirrored)
                        CanvasController.mirrorCanvas(true);

                    CanvasGridOverlay.gridGapMultiplier = appStateObject.gridValue;
                    CanvasGridOverlay.gridDrawOffsetX = appStateObject.gridDrawOffsetX;
                    CanvasGridOverlay.gridDrawOffsetY = appStateObject.gridDrawOffsetY;
                    if (!CanvasGridOverlay.gridDrawOffsetX)
                        CanvasGridOverlay.gridDrawOffsetX = 0.0;
                    if (!CanvasGridOverlay.gridDrawOffsetY)
                        CanvasGridOverlay.gridDrawOffsetY = 0.0;
                    if (appStateObject.gridValue > 0)
                        CanvasGridOverlay.drawGrid();

                    if (appStateObject.canvasWindowON)
                    {
                        ImageViewWindow.canvasWindowInfo = [
                            appStateObject.newWindowInfo0,
                            appStateObject.newWindowInfo1,
                            appStateObject.newWindowInfo2,
                            appStateObject.newWindowInfo3
                        ];
                        ImageViewWindow.openImageViewWindow();
                        stage.nativeWindow.activate();
                    }

                    FileManager.isContinueSaveON = appStateObject.isContinueSaveON;
                    rDataIndex = undoDataIndex;
                    rNowFrame = getNowFrameUntilUndoIndex(undoDataIndex);
                    rPrevFrame = getNowFrameUntilUndoIndex(undoDataIndex - 1);

                    // 혹시 몰라서 위치 체크 해줌
                    CanvasController.canvasInfoBox.setRotate(CanvasController.canvasAnchorPoint.rotation);
                    CanvasController.centerCanvas("replay");
                    CanvasController.keepCanvasPanelInStage();
                    CanvasController.keepCanvasPanelInStage(true);

                    PaletteController.myPaletteSaveColorBeforeOtherType[0] = PenTool.penColor;
                    if (appStateObject.myPalettePresetType > 0)
                        ColorPickerController.activeColorPreset(appStateObject.myPalettePresetType);

                    PaletteController.updateHistoryList();
                    PaletteController.isMyPaletteExpended = appStateObject.isMyPaletteExpended;
                    if (PaletteController.myPalettePresetType === 0 && appStateObject.isMyPaletteExpended)
                    {
                        PaletteController.switchMyPaletteToExpended();
                    }
                    else
                    {
                        PaletteController.updateMyPaletteList();
                    }

                    ColorPickerController.isColorPickerBoxPositionSwapped = appStateObject.isColorPickerBoxPositionSwapped;
                    if (appStateObject.isColorPickerBoxPositionSwapped)
                    {
                        ColorPickerController.colorPickerBox.swapColorBoxPositions(appStateObject.isColorPickerBoxPositionSwapped);
                    }

                    SidebarController.sideBarScrollPanel.y = appStateObject.scrollSetMovedY;
                    MainUI.topBar.captureInput.text = appStateObject.captureStampText;
                    CaptureController.isCaptureStampEnabled = appStateObject.isCaptureStampON;
                    if (appStateObject.captureStampFont)
                    {
                        CaptureController.captureStampManager.changeFont(appStateObject.captureStampFont, false);
                    }

                    MainUIController.updateCanvasNaigatorCursor();
                    updatePenSizeCursor();
                    MainUIController.updateWindowTitle();
                    CanvasController.selectLayer1(false);
                });
            }
            else // 복원파일이 없을때
            {
                if (FileManager.lastSaveFilePath === FileManager.lastSaveFileName)
                {
                    FileManager.lastSaveFilePath = File.desktopDirectory.nativePath + File.separator + FileManager.lastSaveFileName;
                }
                PaletteController.initializeMyPaletteList();
                MainUIController.lastAppWindowSize.width = 1000;
                MainUIController.lastAppWindowSize.height = 800;
                FOFOTimer.add(0.3, true, function ():Boolean
                    {
                        if (stage.nativeWindow.width === 1000 && stage.nativeWindow.height === 800)
                        {
                            CanvasController.centerCanvas("draw");
                            return false;
                        }
                        stage.nativeWindow.width = MainUIController.lastAppWindowSize.width;
                        stage.nativeWindow.height = MainUIController.lastAppWindowSize.height;
                        return true;
                    });
                CanvasController.updateCavnvasSizeDrawMode(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, 0, 0, false);
                MainUIController.updateResizeButtonPos(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
                ColorPickerController.updatePickerCurrentColor(PenTool.penColor);
                ColorPickerController.updateColorPickerCursorPosAndRGBInfo(PenTool.penColor);
                openAboutBox(true);
                MainUIController.applyUIColorSet();
                MainUIController.updateCanvasNaigatorCursor();
                CanvasController.canvasInfoBox.init(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, Math.floor(CanvasController.canvasZoomMultipler * 100), CanvasController.canvasAnchorPoint.rotation, false);
                CanvasController.selectLayer1(false);
                PaletteController.initMyPaletteHistory();
            }
        }





        public function clearCanvasReplayMode():void
        {
            const rect:Rectangle = new Rectangle(0, 0, RCANVAS_WIDTH, RCANVAS_HEIGHT);
            rCanvasDrawShape.graphics.clear();
            rCanvasLayer1BitmapData.fillRect(rect, 0);
            rCanvasLayer2BitmapData.fillRect(rect, 0);
            rCanvasDrawLayerBitmapData.fillRect(rect, 0);
        }

        public function showReplaySpeedMouseHint():void
        {
            const timeStr:String = getReplayRemainingTimeString(rReplaySpeedMultipler, TOTAL_FRAME);
            const finalStr:String = HintStrings.getReplaySpeedHintString(rReplaySpeedMultipler, timeStr);
            MainUI.showMouseHintTemp(finalStr);
        }
        // keyfunc
        public function adjustReplaySpeedByShortcut(increaseFlag:Boolean):void
        {
            const clacMax:Number = Math.floor(TOTAL_FRAME / (stage.frameRate * 3));
            if (clacMax <= 0)
            {
                return;
            }
            const maxSpeed:Number = REPLAY_MAX_SPEED;
            var _rSpeed:Number = rReplaySpeedMultipler;
            if (increaseFlag)
            {
                _rSpeed += 1;
                if (_rSpeed > maxSpeed)
                {
                    _rSpeed = maxSpeed;
                }
            }
            else
            {
                _rSpeed -= 1;
                if (_rSpeed < 1)
                {
                    _rSpeed = 1;
                }
            }
            rReplaySpeedMultipler = _rSpeed;
            MainUI.topBar.setSpeedButtonPosByValue(_rSpeed, maxSpeed);
            showReplaySpeedMouseHint();
        }
        public function startAdjustPlayBackSpeedByShortcut(increase:Boolean):void
        {
            startKeyRepeat(true, adjustReplaySpeedByShortcut, increase);
        }
        public function adjutReplaySpeedByMouse():void
        {
            const totalF:Number = TOTAL_FRAME;
            if (totalF <= stage.frameRate * 3) // 3초 이내면 안함
            {
                return;
            }
            // setSpeedButtonPosByValue도 오프셋 수정해주어야함
            const minDist:Number = MainUI.topBar.replaySpeedSlider.x + 1.5;
            const maxDist:Number = minDist + MainUI.topBar.replaySpeedSlider.width - 2.5;
            const maxSpeed:Number = REPLAY_MAX_SPEED;
            var oldSpeed:Number;
            CanvasController.isPenSizeCursorInvisible = true;
            CanvasController.isMouseDragging = true;
            function setSpeed(mx:Number):void
            {
                var exp:Number = mx / maxDist;
                if (exp < 0)
                {
                    exp = 0;
                }
                else if (exp > 1)
                {
                    exp = 1;
                }
                var nowSpeed:Number = Math.floor(Math.pow(maxSpeed, exp));
                if (oldSpeed !== nowSpeed)
                {
                    oldSpeed = nowSpeed;
                    if (nowSpeed > maxSpeed)
                    {
                        nowSpeed = maxSpeed;
                    }
                    rReplaySpeedMultipler = nowSpeed;
                }
            }
            function moveButton(mx:Number):void
            {
                if (mx < minDist)
                {
                    mx = minDist;
                }
                else if (mx > maxDist)
                {
                    mx = maxDist;
                }
                MainUI.topBar.replaySpeedSliderCursor.x = mx;
                setSpeed(mx);
                showReplaySpeedMouseHint();
                if (isReplayFinished === false)
                {
                    updateReplayPrograssText();
                }
            }
            function replaySpeedButtomUpEvent(e:MouseEvent):void
            {
                CanvasController.isMouseDragging = false;
                if (isReplayFinished === false)
                {
                    updateReplayPrograssText();
                }
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, replaySpeedButtomMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP, replaySpeedButtomUpEvent);
            }
            function replaySpeedButtomMoveEvent(e:MouseEvent):void
            {
                moveButton(MainUI.topBar.replaySpeedSliderWrapper.mouseX);
            }
            moveButton(MainUI.topBar.replaySpeedSliderWrapper.mouseX);
            setSpeed(MainUI.topBar.replaySpeedSliderWrapper.mouseX);
            showReplaySpeedMouseHint();
            stage.addEventListener(MouseEvent.MOUSE_MOVE, replaySpeedButtomMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP, replaySpeedButtomUpEvent);
        }
        public function onKeyUpReplayMode(e:KeyboardEvent):void
        {
            checkGeneralKeyUp(e.keyCode);
        }
        public function onKeyDownReplayMode(e:KeyboardEvent):void // keydown2
        {
            const firstKey:uint = getFirstPressedKey();
            if (CanvasController.isMouseClicked || CanvasController.isRightMouseClicked || isLastKey(firstKey) || FileManager.loadMenuBox.visible)
            {
                return;
            }
            if (isReplayStarted)
            {
                switch (firstKey)
                {
                    case KEY.backspace:
                    case KEY.esc:
                    case KEY.enter:
                    case KEY.space:
                        {
                            updateLastKey(firstKey);
                            FOFOTimer.remove("prograssBarUpdateTimer");
                            handleReplayStopButton();
                            ;
                        }
                        break;
                }
                return;
            }
            if (isReplayRestartTimerON())
            {
                switch (firstKey)
                {
                    case KEY.backspace:
                    case KEY.esc:
                    case KEY.enter:
                    case KEY.space:
                        {
                            updateLastKey(firstKey);
                            cancelReplayRestartTimer();
                        }
                        break;
                }
                return;
            }
            if (isPressingShift())
            {
                checkSubKey(2, false, function (input:int):void
                    {
                        switch (input)
                        {
                            case KEY.left:
                            case KEY.z:
                            case KEY.dot:
                                {
                                    if (!isReplayStarted)
                                    {
                                        startKeyRepeat(true, moveToPreviousFrame);
                                    }
                                }
                                break;
                            case KEY.right:
                            case KEY.x:
                            case KEY.comma:
                                {
                                    if (!isReplayStarted)
                                    {
                                        startKeyRepeat(true, moveToNextFrame);
                                    }
                                }
                                break;
                        }
                    });
                return;
            }
            else if (isPressingControl())
            {
                checkSubKey(2, true, function (input:int):void
                    {
                        if (input === KEY.c || input === KEY.m)
                        {
                            CaptureController.enterCaptureMode();
                        }
                        else if (input === KEY.v || input === KEY.m)
                        {
                            if (ClipboardManager.isClipBoardButtonActivated)
                            {
                                ClipboardManager.tryLoadClipboardImage(false);
                            }
                        }
                    });
                return;
            }
            updateLastKey(firstKey);
            switch (firstKey)
            {
                case KEY.left:
                case KEY.z:
                case KEY.dot:
                    {
                        if (!isReplayStarted)
                        {
                            startKeyRepeat(true, moveToPreviousStep);
                        }
                    }
                    break;
                case KEY.right:
                case KEY.x:
                case KEY.comma:
                    {
                        if (!isReplayStarted)
                        {
                            startKeyRepeat(true, moveToNextStep);
                        }
                    }
                    break;
                case KEY.up:
                case KEY.f:
                case KEY.h:
                    {
                        if (!isReplayStarted)
                        {
                            startAdjustPlayBackSpeedByShortcut(true);
                        }
                    }
                    break;
                case KEY.down:
                case KEY.v:
                case KEY.n:
                    {
                        if (!isReplayStarted)
                        {
                            startAdjustPlayBackSpeedByShortcut(false);
                        }
                    }
                    break;
                case KEY.backspace:
                case KEY.esc:
                case KEY.f1:
                case KEY.f7:
                    {
                        exitReplayMode();
                    }
                    break;
                case KEY.enter:
                case KEY.space:
                    {
                        if (isReplayRestartTimerON())
                        {
                            cancelReplayRestartTimer();
                        }
                        else
                        {
                            handleReplayStartButton();
                        }
                    }
                    break;
            }
        }
        public function onKeyUpDrawMode(e:KeyboardEvent):void // keyup1
        {
            const keyCode:uint = e.keyCode;
            if (isLastKey(keyCode))
            {
                if (CanvasController.isMouseClicked === true)
                {
                    CanvasController.isKeyReleasedBeforeMouseUp = true;
                }
                else if (isKeyPressed())
                {
                    onKeyDownDrawMode(null);
                }
                else
                {
                    isLayerCheckKeyPressed = false;
                    if (lastTool > TOOL_NONE)
                    {
                        selectLastUsedTool();
                        showNowToolIconToCursorTemp(nowTool);
                    }
                    penCursorManager.check();
                }
            }
            if (!isKeyPressed())
            {
                resetLastKey();
            }
            if (!isPressingControl())
            {
                if (resizeCanvas.isResizing())
                {
                    resizeCanvas.exit(true);
                }
                if (MainUIController.resizeButtonR.visible)
                {
                    MainUIController.updateCanvasResizeButtonVisible(false);
                }
            }
        }
        public function checkSubKey(expectedLength:uint, updateFlag:Boolean, callback:Function):Boolean
        {
            if (getPressedKeyCount() !== expectedLength)
            {
                return false;
            }
            const subKey:uint = getLastKey();
            if (updateFlag)
            {
                updateLastKey(subKey);
            }
            if (callback !== null)
            {
                callback(subKey);
            }
            return true;
        }
        public function onKeyDownDrawMode(e:KeyboardEvent):void
        {
            if (CanvasController.isMouseClicked || CanvasController.isRightMouseClicked || CanvasController.isKeyReleasedBeforeMouseUp || isFillPenStarted
                    || MainUIController.isPopUpWindowOpened())
            {
                return;
            }
            const firstKey:uint = getFirstPressedKey();
            const secondKey:int = getSecondPressedKey();
            // 자툴이 nowkey를 쓰기 때문에 nowkey 리턴 이전에서 체크해야함
            if (isPressingControlShift())
            {
                // shift 누르고 ctrl 순서로 누를때 이전툴로 복원
                if (isSelectedTool(TOOL_LINE))
                {
                    selectLastUsedTool();
                }
                checkSubKey(3, true, function (input:int):void
                    {
                        if (input === KEY.s)
                        {
                            FileManager.openSaveFileBrowser(true);
                        }
                    });
                return;
            }
            if (isPressingControl())
            {
                if (!checkSubKey(2, true, function (input:int):void
                        {
                            if (input === KEY.s)
                                {
                                    FileManager.openSaveFileBrowser(false);
                        }
                        else if (input === KEY.o)
                            {
                                FileManager.openLoadFileBrowser();
                    }
                    else if (input === KEY.c || input === KEY.comma)
                        {
                            CaptureController.enterCaptureMode();
                }
                else if (input === KEY.v || input === KEY.m)
                    {
                        if (ClipboardManager.isClipBoardButtonActivated)
                            {
                                ClipboardManager.tryLoadClipboardImage(false);
                    }
                }
            }))
            {
                if (resizeCanvas.isResizing() === false)
                {
                    MainUIController.updateCanvasResizeButtonVisible(true);
                }
                }
                return;
            }
            if (isPressingShift())
            {
                if (handlePenOpacitySizeKeyDown(secondKey))
                {
                    return;
                }
                else if (checkPenOptionsKeyDown(secondKey))
                {
                    return;
                }
                else if (checkSubKey(2, true, function (input:int):void
                        {
                            switch (input)
                                {
                                    case KEY.s:
                                    case KEY.k:
                                    {
                                        if (CanvasController.canvasAnchorPoint.rotation !== 0.0)
                                            {
                                                resetRotationDrawMode();
                                    }
                                }
                                return;
                        case KEY.w:
                        case KEY.i:
                        {
                            if (CanvasController.canvasZoomMultipler !== 1.0)
                                {
                                    CanvasController.resetZoomDrawMode();
                        }
                    }
                    return;
        }
        }))
        {
            return;
        }
        }
        if (isTwoKeyPressed())
        {
            // 지우개키 조합 따로 체크
            if (firstKey === KEY.d || firstKey === KEY.j)
            {
                if (handlePenOpacitySizeKeyDown(secondKey))
                {
                    return;
                }
                else if (secondKey === KEY.s || secondKey === KEY.k)
                {
                    if (SidebarController.isQuickSidebarActive === false)
                    {
                        SidebarController.activeQuickSideBar(true);
                    }
                    return;
                }
                else if (checkPenOptionsKeyDown(secondKey))
                {
                    return;
                }
            }
            else if (SidebarController.isPressingQuickSidebarShortcut(firstKey, secondKey))
            {
                if (SidebarController.isQuickSidebarActive === false)
                {
                    SidebarController.activeQuickSideBar(true);
                }
                return;
            }
            // 필펜 조합 체크
            else if (firstKey === KEY.q || firstKey === KEY.o)
            {
                if (handlePenOpacitySizeKeyDown(secondKey))
                {
                    return;
                }
                else if (checkPenOptionsKeyDown(secondKey))
                {
                    return;
                }
            }
        }
        if (isLastKey(firstKey))
        {
            return;
        }
        updateLastKey(firstKey);
        if (handlePenOpacitySizeKeyDown(firstKey))
        {
            return;
        }
        if (handleExtraKeyDown(firstKey))
        {
            return;
        }
        handleToolKeyDown(firstKey);
        }
        public function handleExtraKeyDown(keyCode:int):Boolean
        {
            switch (keyCode)
            {
                case KEY.f1:
                case KEY.f7:
                    {
                        enterReplayMode();
                    }
                    return true;
                case KEY.n1:
                case KEY.n9:
                    {
                        if (CanvasController.isLayer2Selected)
                        {
                            MainUI.showMouseHintTemp("Layer 1 selected");
                            CanvasController.selectLayer1(false);
                        }
                        else
                        {
                            CanvasController.selectLayer1(CanvasController.canvasLayer2Bitmap.visible);
                            MainUI.showMouseHintLayerVisible();
                        }
                        if (toolOptionsBox.layer2CheckedButton.visible)
                        {
                            CanvasController.toggleLayer2Check();
                        }
                    }
                    return true;
                case KEY.n2:
                case KEY.n0:
                    {
                        if (!CanvasController.isLayer2Selected)
                        {
                            MainUI.showMouseHintTemp("Layer 2 selected");
                            CanvasController.selectLayer2(false);
                        }
                        else
                        {
                            CanvasController.selectLayer2(CanvasController.canvasLayer1Bitmap.visible);
                            MainUI.showMouseHintLayerVisible();
                        }
                        if (toolOptionsBox.layer1CheckedButton.visible)
                        {
                            CanvasController.toggleLayer1Check();
                        }
                    }
                    return true;
                case KEY.n3:
                case KEY.n8:
                    {
                        if (toolOptionsBox.sharpLineButtonWrapper.alpha === 1.0)
                        {
                            toggleSharpLineByShortcut();
                        }
                    }
                    return true;
                case KEY.n4:
                case KEY.n7:
                    {
                        if (isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILLPEN))
                        {
                            togglePenAirBrushButtonShortCut();
                        }
                        else if (isSelectedTool(TOOL_ERASER))
                        {
                            toggleEraseAirBrushButtonShortCut();
                        }
                    }
                    return true;
                case KEY.n6:
                    {
                        SidebarController.activeQuickSideBar(true);
                    }
                    break;
                    return true;
                case KEY.x:
                case KEY.comma:
                    {
                        startKeyRepeat(true, redo);
                        showNowToolIconToCursorTemp(TOOL_REDO);
                    }
                    return true;
                case KEY.z:
                case KEY.dot:
                    {
                        startKeyRepeat(true, undo);
                        showNowToolIconToCursorTemp(TOOL_UNDO);
                    }
                    return true;
                case KEY.tab:
                case KEY.backslash:
                    {
                        if (SidebarController.isSidebarVisible)
                        {
                            SidebarController.hideSidebarPermanent();
                        }
                        else
                        {
                            SidebarController.showSidebarPermanent();
                        }
                    }
                    return true;
            }
            return false;
        }
        public function handleToolKeyDown(keyCode:int):void
        {
            if (ReferenceLayerController.isRefLayerMenuON)
            {
                if (keyCode === KEY.esc || keyCode === KEY.backspace)
                {
                    ReferenceLayerController.closeRefLayerMenu();
                    return;
                }
            }
            switch (keyCode)
            {
                case KEY.q:
                case KEY.o:
                    {
                        setLastTool(TOOL_PEN);
                        selectFillPenTool();
                        showNowToolIconToCursorTemp(TOOL_FILLPEN);
                    }
                    break;
                case KEY.t:
                    {
                        if (ReferenceLayerController.isRefLayerMenuON)
                        {
                            ReferenceLayerController.closeRefLayerMenu();
                        }
                        else
                        {
                            ReferenceLayerController.openRefLayerMenu();
                        }
                    }
                    break;
                case KEY.a:
                case KEY.l:
                    {
                        CanvasController.mirrorCanvas();
                        showNowToolIconToCursorTemp(TOOL_MIRROR);
                    }
                    break;
                case KEY.c:
                case KEY.m:
                    {
                        if (ColorPickerController.colorPickerBox.scratchPad.hitTestPoint(stage.mouseX, stage.mouseY))
                        {
                            if (ColorPickerController.colorPickerBox.scratchPad.visible)
                            {
                                ColorPickerController.showPickColorScratchPad();
                            }
                        }
                        else if (!isSelectedTool(TOOL_EYEDROPPER))
                        {
                            eyeDropperTool();
                            showNowToolIconToCursorTemp(TOOL_EYEDROPPER);
                        }
                    }
                    break;
                case KEY.r:
                case KEY.y:
                    {
                        if (!isSelectedTool(TOOL_LASSO))
                        {
                            updateLastTool();
                            selectLassoTool();
                            showNowToolIconToCursorTemp(TOOL_LASSO);
                        }
                    }
                    break;
                case KEY.space:
                    {
                        if (!isSelectedTool(TOOL_HAND))
                        {
                            updateLastTool();
                            setSelectedTool(TOOL_HAND);
                            showNowToolIconToCursorTemp(TOOL_HAND);
                        }
                    }
                    break;
                case KEY.d:
                case KEY.j:
                    {
                        if (!isSelectedTool(TOOL_ERASER))
                        {
                            updateLastTool();
                            selectEraseTool();
                            updatePenSizeCursor();
                            showNowToolIconToCursorTemp(TOOL_ERASER);
                        }
                    }
                    break;
                case KEY.s:
                case KEY.k:
                    {
                        if (!isSelectedTool(TOOL_ROTATE))
                        {
                            updateLastTool();
                            selectRotateTool();
                            showNowToolIconToCursorTemp(TOOL_ROTATE);
                        }
                    }
                    break;
                case KEY.e:
                case KEY.u:
                    {
                        if (!isSelectedTool(TOOL_MOVE))
                        {
                            updateLastTool();
                            selectMoveTool();
                            showNowToolIconToCursorTemp(TOOL_MOVE);
                        }
                    }
                    break;
                case KEY.w:
                case KEY.i:
                    {
                        if (!isSelectedTool(TOOL_ZOOM))
                        {
                            updateLastTool();
                            selectZoomTool();
                            showNowToolIconToCursorTemp(TOOL_ZOOM);
                        }
                    }
                    break;
                case KEY.shift:
                    {
                        if (!isSelectedTool(TOOL_LINE))
                        {
                            updateLastTool();
                            selectLineTool();
                            updatePenSizeCursor();
                        }
                    }
                    break;
                case KEY.esc:
                case KEY.del:
                case KEY.backspace:
                    {
                        if (MainUI.topBar.newFileButton.alpha === 1.0 && !BackgroundWorkerCoordinator.isSaveInProgress)
                        {
                            FileManager.createNewFile(true);
                        }
                    }
                    break;
            }
            penCursorManager.check();
        }
        public function unblockMouseClickAfterDelay():void
        {
            FOFOTimer.addByName("clickBlockTimer", 0.15, false, function ():void
                {
                    CanvasController.isMouseClickBlocked = false;
                });
        }

        public function updateToolBoxMousePos(target:SimpleButton):void
        {
            // 아이콘 중앙으로 맞추어줌
            if (!target)
            {
                return;
            }
            if (target.parent === toolBox2)
            {
                toolBox2.updateLastUsedToolPos(target.name);
            }
        }
        public function closeToolBox2(ignoreResizeButtonVisible:Boolean = false):void
        {
            if (!isToolBox2Showing)
            {
                return;
            }
            removeInputEventsToolBox2();
            isToolBox2Showing = false;
            toolBox2.visible = false;
            if (!ignoreResizeButtonVisible)
            {
                MainUIController.showCanvasResizeButtonVisibleDelay(false);
            }
        }
        public function onMouseDownToolBox2(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
            {
                return;
            }
            const targetName:String = target.name;
            switch (targetName)
            {
                case "toolZoom":
                    {
                        updateToolBoxMousePos(target as SimpleButton);
                        closeToolBox2();
                        zoomTool();
                    }
                    break;
                case "toolMove":
                    {
                        updateToolBoxMousePos(target as SimpleButton);
                        closeToolBox2();
                        moveTool();
                    }
                    break;
                case "toolRotate2":
                    {
                        updateToolBoxMousePos(target as SimpleButton);
                        closeToolBox2();
                        rotateTool(false);
                    }
                    break;
                case "resizeButtonR":
                case "resizeButtonD":
                case "resizeButtonL":
                case "resizeButtonU":
                    {
                        CanvasController.startCanvasResizing(targetName);
                    }
                    break;
                default:
                    {
                        if (toolBox2.visible && toolBox2.hitTestPoint(stage.mouseX, stage.mouseY))
                        {
                            updateToolBoxMousePos(toolBox2.toolPen);
                            updateLastTool();
                            handTool(false, false);
                        }
                        closeToolBox2();
                    }
                    break;
            }
        }
        public function handleToolBox2Closing(target:DisplayObject):void
        {
            const targetName:String = target.name;
            if (targetName !== null && targetName.indexOf("tool") !== -1)
            {
                updateToolBoxMousePos(target as SimpleButton);
            }
            switch (targetName)
            {
                case "toolQuickSidebar":
                    {
                        SidebarController.activeQuickSideBar(false);
                    }
                    break;
                case "toolPen":
                    {
                        selectPenTool();
                        updatePenSizeCursor();
                        showNowToolIconToCursorTemp(TOOL_PEN);
                    }
                    break;
                case "toolFillPen":
                    {
                        selectFillPenTool();
                        updatePenSizeCursor();
                        showNowToolIconToCursorTemp(TOOL_FILLPEN);
                    }
                    break;
                case "toolEraser":
                    {
                        selectEraseTool();
                        updatePenSizeCursor();
                        showNowToolIconToCursorTemp(TOOL_ERASER);
                    }
                    break;
                case "toolLine":
                    {
                        selectLineTool();
                        updatePenSizeCursor();
                        showNowToolIconToCursorTemp(TOOL_LINE);
                    }
                    break;
                case "toolLasso":
                    {
                        selectLassoTool();
                        showNowToolIconToCursorTemp(TOOL_LASSO);
                    }
                    break;
                case "toolEyedropper":
                    {
                        if (!isSelectedTool(TOOL_EYEDROPPER))
                        {
                            eyeDropperTool();
                            showNowToolIconToCursorTemp(TOOL_EYEDROPPER);
                        }
                    }
                    break;
                case "toolUndo":
                    {
                        undo();
                        showNowToolIconToCursorTemp(TOOL_UNDO);
                    }
                    break;
                case "toolRedo":
                    {
                        redo();
                        showNowToolIconToCursorTemp(TOOL_REDO);
                    }
                    break;
                case "toolMirror":
                    {
                        CanvasController.mirrorCanvas();
                        showNowToolIconToCursorTemp(TOOL_MIRROR);
                    }
                    break;
                case "toolRefLayer":
                    {
                        ReferenceLayerController.openRefLayerMenu();
                    }
                    break;
            }
            closeToolBox2();
        }
        public function onMouseOverToolBox2(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
            {
                return;
            }
            const targetName:String = target.name;
            if (targetName && targetName.indexOf("tool") !== -1)
            {
                toolBox2.setMouseOverTarget(target);
            }
        }
        public function onKeyUpToolBox2(e:KeyboardEvent):void
        {
            resetLastKey();
            handleToolBox2Closing(toolBox2.getMouseOverTarget());
        }
        public function onRightMouseUpToolBox2(e:MouseEvent):void
        {
            CanvasController.isPenSizeCursorInvisible = false;
            if (LassoTool.isLassoToolStarted === true)
            {
                closeToolBox2();
                return;
            }
            const target:SimpleButton = e.target as SimpleButton;
            if (!target || target.alpha < 1.0 || !isCursorInDrawArea())
            {
                closeToolBox2();
                return;
            }
            handleToolBox2Closing(target);
        }

        public function handleToolBoxMouseDown(target:DisplayObject):Boolean
        {
            if (isKeyPressed() && !SidebarController.isQuickSidebarActive || !target)
                return true;
            const targetName:String = target.name;
            switch (targetName)
            {
                case "toolRotate":
                    {
                        rotateTool(false);
                    }
                    return true;
                case "toolUndo":
                    {
                        startKeyRepeat(false, undo);
                        startKeyRepeatStopTimerOnMouseLeave(target);
                        handleToolBoxClick(targetName);
                    }
                    return true;
                case "toolRedo":
                    {
                        startKeyRepeat(false, redo);
                        startKeyRepeatStopTimerOnMouseLeave(target);
                        handleToolBoxClick(targetName);
                    }
                    return true;
                case "toolZoomIn":
                case "toolZoomOut":
                case "toolPen":
                case "toolFillPen":
                case "toolEraser":
                case "toolLasso":
                case "toolEyedropper":
                case "toolUndo":
                case "toolRedo":
                case "toolMirror":
                case "toolLine":
                case "toolMove":
                case "toolRotate":
                case "toolRefLayer":
                case "toolBoxBG":
                case "toolMask":
                    {
                        // setTopChildIndex(toolBox);
                        handleToolBoxClick(targetName);
                    }
                    return true;
            }
            return false;
        }

        public function updateReplaySpeedSliderAlpha():void
        {
            if (REPLAY_MAX_SPEED === 1.0)
            {
                MainUI.topBar.replaySpeedSliderWrapper.alpha = Global.OFFALPHA;
            }
            else
            {
                MainUI.topBar.replaySpeedSliderWrapper.alpha = 1.0;
            }
        }
        public function updateReplayPrograssBarAndText():void
        {
            const totalFrame:Number = TOTAL_FRAME;
            const nowFrame:Number = rNowFrame;
            const trackBarWidth:Number = MainUI.seekBarBox.trackBar.width;
            MainUI.seekBarBox.prograssInfo.text = nowFrame + " / " + totalFrame;
            MainUI.seekBarBox.prograssBar.width = (totalFrame === 0) ? 0 : trackBarWidth * (nowFrame / totalFrame);
        }
        public function clearKeyBuffer():void
        {
            KEY_BUFFER.length = 0;
            resetLastKey();
        }
        public function updateReplayCursorScale(zoom:Number):void
        {
            const z:Number = 1.0 / zoom;
            rReplayFOFOCursor.scaleX = z;
            rReplayFOFOCursor.scaleY = z;
        }
        public function disableDeepUndo():void
        {
            isDeepUndoEnabled = false;
            lastDeepUndoEnabledFlag = false;
            rDataReadFlag = true;
            showRCursorOnUndo(-1);
            clearRFrameTempCache();
        }
        public function enableDeepUndo():void
        {
            isDeepUndoEnabled = true;
            rDataReadFlag = false;
            if (rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_READY)
            {
                removeInputEventsDrawMode();
                Utils.setAsTopChild(MainUI.seekBarBox);
                MainUI.seekBarBox.updatePos(stage.stageWidth);
                startGeneratingReplayCacheImage();
            }
            else
            {
                updateTotalFrameAndReplayMaxSpeedFor10Sec(getTotalFrame());
                // 이미지 캐시 해주고 rPrevFrame 갱신해주고
                renderReplayFrame(undoManager.getRFileTotalFrame() - 1, JUMP_FRAME_MANUAL);
                // 실제 rPrevFrame으로 점프
                renderReplayFrame(rPrevFrame, JUMP_FRAME_MANUAL);
                applyReplayCanvasToDrawModeCanvas();
            }
        }
        public function startGeneratingReplayCacheImage():void
        {
            rReplayImageCacheState = REPLAY_IMAGE_CAHCHE_PROCESSING;
            if (!FOFOTimer.hasTimer("generatereplaycacheimagedelay"))
            {
                FOFOTimer.addByName("generatereplaycacheimagedelay", 0.1, false, function ():void
                    {
                        generateReplayCacheImage();
                    });
            }
        }
        public function syncDrawCanvasWithReplayMode():void
        {
            CanvasController.canvasZoomMultipler = rCanvasZoomMultiplier; // 줌배율도 공유
            CanvasController.canvasZoomIndex = rCanvasZoomIndex;
            CanvasController.canvasAnchorPoint.scaleX = rCanvasAnchorPoint.scaleX;
            CanvasController.canvasAnchorPoint.scaleY = rCanvasAnchorPoint.scaleY;
            CanvasController.canvasAnchorPoint.rotation = rCanvasAnchorPoint.rotation;
            CanvasController.canvasAnchorPoint.x = rCanvasAnchorPoint.x;
            CanvasController.canvasAnchorPoint.y = rCanvasAnchorPoint.y;
            rCanvasPanel.x = rCanvasPanel.x;
            rCanvasPanel.y = rCanvasPanel.y;
            setRcursorRotation(CanvasController.canvasAnchorPoint.rotation);
        }
        public function syncReplayCanvasWithDrawMode():void
        {
            rCanvasZoomMultiplier = CanvasController.canvasZoomMultipler; // 줌배율도 공유
            rCanvasZoomIndex = CanvasController.canvasZoomIndex;
            rCanvasAnchorPoint.scaleX = CanvasController.canvasAnchorPoint.scaleX;
            rCanvasAnchorPoint.scaleY = CanvasController.canvasAnchorPoint.scaleY;
            rCanvasAnchorPoint.rotation = CanvasController.canvasAnchorPoint.rotation;
            rCanvasAnchorPoint.x = CanvasController.canvasAnchorPoint.x;
            rCanvasAnchorPoint.y = CanvasController.canvasAnchorPoint.y;
            rCanvasPanel.x = CanvasController.canvasPanel.x;
            rCanvasPanel.y = CanvasController.canvasPanel.y;
            setRcursorRotation(rCanvasAnchorPoint.rotation);
        }
        public function syncReplayCanvasImageWithDrawMode():void
        {
            rCanvasDrawShape.graphics.clear();
            rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, CanvasController.canvasLayer1BitmapData, rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, CanvasController.canvasLayer2BitmapData, rCanvasLayer2Bitmap);
            updateCanvasSizeReplayMode(CanvasController.canvasLayer1Bitmap.width, CanvasController.canvasLayer1Bitmap.height);
            updateCanvasBGColorReplayMode(CanvasController.CANVAS_BG_COLOR);
        }
        public function updateReplayTimeBarFromDrawMode():void
        {
            updateReplayPrograssText(true, rNowFrame);
            if (TOTAL_FRAME === 0)
            {
                MainUI.seekBarBox.resetReplayPrograssBarWidth();
            }
            else
            {
                MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(rNowFrame / TOTAL_FRAME);
            }
        }

        public function exitReplayMode():void
        {
            if (isGeneratingCacheImages())
            {
                return;
            }
            if (isReplayStarted === true)
            {
                stopReplay();
            }
            removeInputEventsReplayMode();
            cancelReplayRestartTimer();
            isReplayModeON = false;
            CanvasController.isPenSizeCursorInvisible = false;
            rCanvasAnchorPoint.visible = false;
            rReplayFOFOCursor.visible = false;
            MainUI.seekBarBox.visible = false;
            CanvasController.canvasAnchorPoint.visible = true;
            CanvasController.penSizePreviewCursor.visible = true;
            if (ReferenceLayerController.isRefLayerMenuON === true)
            {
                ReferenceLayerController.refLayerMenuBox.visible = true;
            }
            if (SidebarController.isSidebarVisible === true)
            {
                SidebarController.showSidebarPermanent();
            }
            CanvasController.canvasPanel.addChild(rReplayFOFOCursor);
            setRcursorRotation(CanvasController.canvasAnchorPoint.rotation);
            if (MainUI.mouseHint.isShowing())
            {
                MainUI.hideMouseHint();
            }
            MainUI.seekBarBox.pauseButton.visible = false;
            Utils.setAsTopChild(MainUI.seekBarBox);
            MainUI.seekBarBox.setDeleteRangeBarVisible(false);
            MainUIController.updateStageOffset();
            MainUIController.updateCanvasNaigatorCursor();
            if (PenTool.isTransparentPenColor)
            {
                ColorPickerController.selectTransparentColor();
            }
            else
            {
                ColorPickerController.switchColorPickerModePen();
            }
            updatePenSizeCursor();
            penCursorManager.check();
            MainUI.updateTopbarIconsDrawMode();
            CanvasController.canvasInfoBox.setZoom(CanvasController.canvasZoomMultipler);
            updateReplayCursorScale(CanvasController.canvasZoomMultipler);
            isDeepUndoEnabled = lastDeepUndoEnabledFlag;
            if (rNowFrame !== lastReplayFrameOnDeepUndoStart)
            {
                // after로 해주는 이유는 캐쉬 안만들어줄라고
                renderReplayFrame(lastReplayFrameOnDeepUndoStart, JUMP_FRAME_NEXT);
            }
            clearRFrameTempCache();
            rReplayFOFOCursor.visible = false;
            addInputEventsDrawMode();
        }
        public function enterReplayMode():void
        {
            if (isGeneratingCacheImages())
            {
                return;
            }
            removeInputEventsDrawMode();
            isReplayModeON = true;
            CanvasController.isPenSizeCursorInvisible = true;
            CanvasController.canvasAnchorPoint.visible = false;
            rCanvasAnchorPoint.visible = true;
            MainUI.seekBarBox.visible = true;
            CanvasController.penSizePreviewCursor.visible = false;
            MainUI.seekBarBox.pauseButton.visible = false;
            MainUI.seekBarBox.y = Math.floor(MainUI.topBar.BARSIZE * Global.getUIScale() - 4);
            lastReplayTimeBoxYPos = MainUI.seekBarBox.y;
            Utils.setAsTopChild(MainUI.seekBarBox);
            MainUI.seekBarBox.setDeleteRangeBarVisible(false);
            if (numPadBox.visible)
            {
                ColorPickerController.closeNumpad();
            }
            if (MainUI.mouseHint.isShowing())
            {
                MainUI.hideMouseHint();
            }
            rReplayFOFOCursor.alpha = 1.0;
            rReplayFOFOCursor.visible = false;
            rCanvasPanel.addChild(rReplayFOFOCursor);
            Utils.setAsTopChild(rReplayFOFOCursor);
            setRcursorRotation(rCanvasAnchorPoint.rotation);
            MainUIController.updateStageOffset();
            FOFOTimer.remove("rCursorOffAlphaAnimTimer");
            MainUI.hideBottomHint();
            lastDeepUndoEnabledFlag = isDeepUndoEnabled;
            isDeepUndoEnabled = false;
            lastReplayFrameOnDeepUndoStart = rNowFrame;
            updateTotalFrameAndReplayMaxSpeedFor10Sec(getTotalFrame()); // 최대 속도 계산
            updateReplayPrograssBarAndText();
            updateReplaySpeedSliderAlpha();
            MainUI.seekBarBox.updatePos(stage.stageWidth);
            rFollowMouse.updateBounds();
            updateReplayCursorScale(rCanvasZoomMultiplier);
            if (ReferenceLayerController.isRefLayerMenuON === true)
            {
                ReferenceLayerController.refLayerMenuBox.visible = false;
            }
            if (rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_READY)
            {
                removeKeyRepeatEvents(null);
                removeInputEventsReplayMode();
                SidebarController.hideSidebarTemporary();
                MainUI.updateTopbarIconsReplayMode();
                startGeneratingReplayCacheImage();
            }
            else if (rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_COMPLETE)
            {
                rDataReadFlag = false;
                updateReplayTimeBarFromDrawMode();
                CanvasController.centerCanvas("replay");
                // fitCanvasToViewportMargin();
                // 이거 안해주고 리플레이틀고 프레임 조작 안하고 재생하면 중간부터 되서 데이터가 꼬임
                isReplayFinished = true;
                if (undoDataIndex >= 0)
                {
                    rDataStartIndex = undoDataIndex + 1;
                    rDataReadFlag = true;
                }
                else
                {
                    rDataStartIndex = 0;
                    rDataReadFlag = false;
                }
                updateDeleteReplayDataButtonsState();
                isReplaySlideShowMode = false;
                CanvasController.keepCanvasPanelInStage(true);
                SidebarController.hideSidebarTemporary();
                MainUI.updateTopbarIconsReplayMode();
                addInputEventsReplayMode();
            }
        }
        public function onMouseDownReplayMode(e:MouseEvent):void // repdown1
        {
            const target:DisplayObject = e.target as DisplayObject;
            if (!target || FileManager.loadMenuBox.visible)
            {
                return;
            }
            const targetName:String = target.name;
            if (isReplayRestartTimerON())
            {
                if (MainUI.seekBarBox.trackBar.hitTestPoint(stage.mouseX, stage.mouseY))
                {
                    cancelReplayRestartTimer();
                    return;
                }
            }
            if (targetName && !isReplayRestartTimerON())
            {
                if (targetName === "rCanvasPanel" || targetName === "rCanvasDrawLayer" || targetName === "WorkspaceView.stageBG")
                {
                    handTool(true, false);
                    return;
                }
                else if (targetName === "replayRepeatButton" || targetName === "replayFitToWindowButton")
                {
                    if (isKeyPressed())
                    {
                        return;
                    }
                    handleMouseClick(targetName);
                    return;
                }
            }
            if (target.alpha < 1.0)
            {
                return;
            }
            switch (targetName)
            {
                case "repNewFileButton":
                    {
                        startPressHoldKey(MainUI.topBar.repNewFileButton, HintStrings.getNewFileHintString(),
                                function ():Boolean
                                {
                                    return prepareDeleteReplayData("total");
                                },
                                createNewFileFromReplayCanvas,
                                function ():void
                                {
                                    MainUI.seekBarBox.setDeleteRangeBarVisible(false);
                                });
                    }
                    break;
                case "cutPrevDataButton":
                    {
                        if (MainUI.topBar.cutPrevDataButton.alpha === 1.0)
                        {
                            startPressHoldKey(MainUI.topBar.cutPrevDataButton, HintStrings.getDeleteReplayDataHintString(), function ():Boolean
                                {
                                    return prepareDeleteReplayData("before");
                                },
                                    deleteReplayDataBeforeCurrentFrame,
                                    function ():void
                                    {
                                        MainUI.seekBarBox.setDeleteRangeBarVisible(false);
                                    });
                        }
                    }
                    break;
                case "superUndoButton":
                    {
                        if (MainUI.topBar.superUndoButton.alpha === 1.0)
                        {
                            startPressHoldKey(MainUI.topBar.superUndoButton, HintStrings.getDeleteReplayDataHintString(), function ():Boolean
                                {
                                    return prepareDeleteReplayData("after");
                                },
                                    deleteReplayDataAfterCurrentFrame, function ():void
                                    {
                                        MainUI.seekBarBox.setDeleteRangeBarVisible(false);
                                    });
                        }
                    }
                    break;
                case "replayRotateButton":
                    {
                        rotateTool(true);
                    }
                    break;
                case "replaySpeedSliderWrapper":
                    {
                        adjutReplaySpeedByMouse();
                    }
                    break;
                case "trackBar":
                    {
                        onSeekbarClick();
                    }
                    break;
                case "replayPrev":
                    {
                        FOFOTimer.remove("prograssBarUpdateTimer");
                        if (isPressingShift())
                        {
                            startKeyRepeat(true, moveToPreviousFrame);
                            startKeyRepeatStopTimerOnMouseLeave(target);
                        }
                        else
                        {
                            startKeyRepeat(true, moveToPreviousStep);
                            startKeyRepeatStopTimerOnMouseLeave(target);
                        }
                    }
                    break;
                case "replayNext":
                    {
                        FOFOTimer.remove("prograssBarUpdateTimer");
                        if (isPressingShift())
                        {
                            startKeyRepeat(true, moveToNextFrame);
                            startKeyRepeatStopTimerOnMouseLeave(target);
                        }
                        else
                        {
                            startKeyRepeat(true, moveToNextStep);
                            startKeyRepeatStopTimerOnMouseLeave(target);
                        }
                    }
                    break;
                case "timer":
                    {
                        startPressHoldKey(MainUI.topBar.timer, HintStrings.getResetTimerHintString(), null, realWorkingTimer.reset, null);
                    }
                    break;
                case "drawModeButton":
                case "saveButton":
                case "captureButton":
                case "capOff":
                case "capSave":
                case "capClipBoard":
                case "capTrans":
                case "capFlip":
                case "capRotate":
                case "repCaptureButton":
                case "clipBoardButton":
                case "topBarColorButton":
                case "playButton":
                case "pauseButton":
                case "replayZoomInButton":
                case "replayZoomOutButton":
                case "replayFitToWindowButton":
                case "replayPrev":
                case "replayNext":
                    {
                        if (isKeyPressed())
                        {
                            return;
                        }
                        handleMouseClick(targetName);
                    }
                    break;
            }
        }
        // 키를 2개 이상 누르고 있을때 먼저 누른키를 떼면 다음키로 설정함
        public function onMouseUpDrawMode(e:MouseEvent):void // mouseup1
        {
            if (CanvasController.isKeyReleasedBeforeMouseUp) // 단축키 떼고 마우스 땠을때 원래대로 돌림
            {
                CanvasController.isKeyReleasedBeforeMouseUp = false;
                if (KEY_BUFFER.length > 0)
                {
                    onKeyDownDrawMode(null);
                }
                else
                {
                    resetLastKey();
                    if (lastTool > TOOL_NONE)
                    {
                        selectLastUsedTool();
                    }
                    penCursorManager.check();
                }
            }
        }
        public function setFitReplayCanvasToViewportOFF():void
        {
            isReplayCanvasFitToWindow = false;
        }
        public function setFitReplayCanvasToViewportON():void
        {
            isReplayCanvasFitToWindow = true;
            fitReplayCanvasToViewport();
        }
        public function fitReplayCanvasToViewport():void
        {
            FOFOTimer.addByName("rFitZoomedDelayTimer", 0.15, false, function ():void
                {
                    fitCanvasToViewportMargin(true);
                    rCanvasZoomIndex = CanvasController.getNearZoomIndex(rCanvasZoomMultiplier);
                    rCanvasZoomMultiplier = CanvasController.canvasZoomMultiplerList[rCanvasZoomIndex];
                });
        }
        public function onRightMouseDownReplayMode(e:MouseEvent):void
        {
            if (CanvasController.isMouseClicked || isKeyPressed() || !e.target || FileManager.loadMenuBox.visible)
                return;
            const targetName:String = e.target.name;
            switch (targetName)
            {
                case "replayPrev":
                    {
                        startKeyRepeat(true, moveToPreviousFrame);
                        startKeyRepeatStopTimerOnMouseLeave(e.target as DisplayObject);
                    }
                    break;
                case "replayNext":
                    {
                        startKeyRepeat(true, moveToNextFrame);
                        startKeyRepeatStopTimerOnMouseLeave(e.target as DisplayObject);
                    }
                    break;
                case "replayRotateButton":
                    {
                        resetRotationReplayMode();
                    }
                    break;
                case "replayZoomInButton":
                case "replayZoomOutButton":
                {
                    resetZoomReplayMode();
                    break;
                }
                case "rCanvasDrawLayer":
                case "WorkspaceView.stageBG":
                    {
                        if (isReplayRestartTimerON())
                        {
                            cancelReplayRestartTimer();
                        }
                        else if (!isReplayStarted)
                        {
                            handleReplayStartButton();
                        }
                        else
                        {
                            handleReplayStopButton();
                        }
                    }
                    break;
            }
        }
        public function openToolBox2(fromShortcut:Boolean):void
        {
            CanvasController.isPenSizeCursorInvisible = true;
            CanvasController.penSizePreviewCursor.visible = false;
            var pos:Point = toolBox2.getLastUsedToolPos();
            const scale:Number = Global.getUIScale();
            toolBox2.x = Math.floor(stage.mouseX - pos.x * scale);
            toolBox2.y = Math.floor(stage.mouseY - pos.y * scale);
            toolBox2.alpha = 1.0;
            toolBox2.visible = true;
            isToolBox2Showing = true;
            MainUIController.showCanvasResizeButtonVisibleDelay(true);
            Utils.setAsTopChild(toolBox2);
            addInputEventsToolBox2(fromShortcut);
            FOFOTimer.addByName("toolBox2HideCheckTimer", 0.1, true, function ():Boolean
                {
                    if (!isToolBox2Showing)
                    {
                        return false;
                    }
                    if (MainUIController.resizeButtonR.visible)
                    {
                        if (!toolBox2.hitTestPoint(stage.mouseX, stage.mouseY))
                        {
                            toolBox2.alpha = 0.6;
                        }
                        else if (toolBox2.alpha < 1.0)
                        {
                            toolBox2.alpha = 1.0;
                        }
                    }
                    return true;
                });
        }
        public function onRightMouseDownDrawMode(e:MouseEvent):void // rdown1
        {
            if (CanvasController.isMouseClicked || isKeyPressed() || isPressingControl() || SidebarController.isQuickSidebarActive
                    || isFillPenStarted || isSelectedTool(TOOL_EYEDROPPER) || (ReferenceLayerController.isRefLayerMenuON && ReferenceLayerController.refLayerMenuBox.hitTestPoint(mouseX, mouseY))
                    || FileManager.loadMenuBox.visible || MainUI.topBar.gridButtonWrapper.visible || numPadBox.visible)
            {
                return;
            }
            const targetName:String = e.target.name;
            switch (targetName)
            {
                case "saveButton":
                    {
                        FileManager.openSaveFileBrowser(true);
                    }
                    break;
                case "dpiButton":
                    {
                        if (Global.getScaleIndex() !== 0)
                        {
                            Global.resetScaleIndex();
                            MainUIController.applyUIScale();
                            MainUI.showMouseHintTemp(Global.getUIScaleString());
                        }
                    }
                    break;
                case "toolZoomIn":
                case "toolZoomOut":
                    {
                        if (CanvasController.canvasZoomMultipler !== 1.0)
                            CanvasController.resetZoomDrawMode();
                    }
                    break;
                case "gridButton":
                    {
                        if (CanvasGridOverlay.gridGapMultiplier !== 0)
                        {
                            MainUI.hideBottomHint();
                            CanvasGridOverlay.resetGrid();
                        }
                    }
                    break;
                case "toolRotate":
                    {
                        if (CanvasController.canvasAnchorPoint.rotation !== 0.0)
                        {
                            resetRotationDrawMode();
                        }
                    }
                    break;
                case "sideBarScrollBar":
                    {
                        SidebarController.resetSideBarPosition();
                    }
                    break;
                default:
                    {
                        if (isCursorInDrawArea())
                        {
                            if (isToolBox2Showing && !isDeepUndoEnabled)
                            {
                                closeToolBox2();
                            }
                            else
                            {
                                openToolBox2(false);
                            }
                        }
                    }
                    break;
            }
        }
        public function handlePenOptionsBoxMouseDown(target:DisplayObject):Boolean
        {
            if (isToolBox2Showing)
            {
                return true;
            }
            const targetName:String = target.name;
            if (target.alpha === Global.OFFALPHA)
            {
                return true;
            }
            switch (targetName)
            {
                case "penSmoothSliderWapper":
                    {
                        if (nowTool !== TOOL_PEN)
                        {
                            return true;
                        }
                        selectPenToolIfNotDrawingTool(true);
                        startPenSmootingAdjustment();
                    }
                    return true;
                case "alphaButton1":
                case "alphaButton2":
                case "alphaButton3":
                case "alphaButton4":
                case "alphaButton5":
                case "alphaButton6":
                case "alphaButton7":
                case "alphaButton8":
                case "alphaButton9":
                case "alphaButton10":
                    {
                        selectOpacityButton(targetName);
                        selectPenToolIfNotDrawingTool(true);
                    }
                    return true;
                case "nSizeButton1":
                case "nSizeButton2":
                case "nSizeButton3":
                case "nSizeButton4":
                case "nSizeButton5":
                case "nSizeButton6":
                case "nSizeButton7":
                case "nSizeButton8":
                case "nSizeButton9":
                case "nSizeButton10":
                case "nSizeButton11":
                case "nSizeButton12":
                    {
                        if (!isSelectedTool(TOOL_FILLPEN))
                        {
                            selectPenToolIfNotDrawingTool(true);
                            selectPenSizeButton(targetName);
                        }
                    }
                    return true;
                case "shapeRect":
                    {
                        if (!isSelectedTool(TOOL_FILLPEN))
                        {
                            selectPenToolIfNotDrawingTool(true);
                            selectPenShapeButton(true);
                        }
                    }
                    return true;
                case "shapeCircle":
                    {
                        if (!isSelectedTool(TOOL_FILLPEN))
                        {
                            selectPenToolIfNotDrawingTool(true);
                            selectPenShapeButton(false);
                        }
                    }
                    return true;
                case "layer1CheckedButton":
                case "layer1UncheckedButton":
                    {
                        CanvasController.selectLayer1(false);
                        CanvasController.toggleLayer1Check();
                    }
                    return true;
                case "layer2CheckedButton":
                case "layer2UncheckedButton":
                    {
                        CanvasController.selectLayer2(false);
                        CanvasController.toggleLayer2Check();
                    }
                    return true;
                case "layer1SelectButton":
                    {
                        if (CanvasController.isLayer2Selected)
                        {
                            CanvasController.selectLayer1(false);
                        }
                        else
                        {
                            CanvasController.selectLayer1(CanvasController.canvasLayer2Bitmap.visible);
                            MainUI.showMouseHintLayerVisible();
                        }
                        if (toolOptionsBox.layer2CheckedButton.visible)
                        {
                            CanvasController.toggleLayer2Check();
                        }
                    }
                    return true;
                case "layer2SelectButton":
                    {
                        if (!CanvasController.isLayer2Selected)
                        {
                            CanvasController.selectLayer2(false);
                        }
                        else
                        {
                            CanvasController.selectLayer2(CanvasController.canvasLayer1Bitmap.visible);
                            MainUI.showMouseHintLayerVisible();
                        }
                        if (toolOptionsBox.layer1CheckedButton.visible)
                        {
                            CanvasController.toggleLayer1Check();
                        }
                    }
                    return true;
                case "layerMergeButton":
                case "layerSwapButton":
                    {
                        if (isToolBox2Showing || target.alpha < 1.0)
                        {
                            return true;
                        }
                        handleMouseClick(targetName);
                    }
                    return true;
                case "sharpLineButtonWrapper":
                case "sharpLineOFFButton":
                case "sharpLineONButton":
                case "sharpLineText":
                    {
                        if (toolOptionsBox.sharpLineButtonWrapper.alpha === 1.0)
                        {
                            selectPenToolIfNotDrawingTool(true);
                            toggleSharpLine(!isSharpLineON);
                        }
                    }
                    return true;
                case "airBrushButtonWrapper":
                case "airBrushOFFButton":
                case "airBrushONButton":
                case "airBrushText":
                    {
                        if (toolOptionsBox.airBrushButtonWrapper.alpha === 1.0)
                        {
                            selectPenToolIfNotDrawingTool(true);
                            if (isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILLPEN))
                            {
                                togglePenAirBrushButton(!isPenAirBrushON);
                            }
                            else if (isSelectedTool(TOOL_ERASER))
                            {
                                toggleEraseAirBrushButton(!PenTool.isEraserAirBrushON);
                            }
                        }
                    }
                    return true;
            }
            return false;
        }




        public function onMouseDownDrawMode(e:MouseEvent):void
        {
            if (isFillPenStarted || FileManager.loadMenuBox.visible
                    || MainUI.topBar.gridButtonWrapper.visible || numPadBox.visible)
            {
                return;
            }
            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
            {
                return;
            }
            const targetName:String = target.name;
            if (SidebarController.sideBar.visible)
            {
                if (SidebarController.sideBarScrollPanel.hitTestPoint(stage.mouseX, stage.mouseY) && SidebarController.handleSidebarMouseDown(target))
                {
                    return;
                }
            }
            if (SidebarController.isQuickSidebarActive)
            {
                if (targetName === "sideBarScrollBar")
                {
                    SidebarController.startScrollSidebarByDrag();
                }
                return;
            }
            switch (targetName)
            {
                case "saveButton": // 아래 3개는 WorkspaceView.topbar메뉴에 가면 안됨 mouseuphandler랑 같이 연동되서 여기서 해주어야함
                case "loadButton":
                case "replayModeButton":
                case "captureButton":
                case "repCaptureButton":
                case "clipBoardButton":
                case "topBarColorButton":
                case "gridButton":
                case "penOptionButton":
                case "aboutButton":
                case "updateButton":
                case "sideBarPositionButton":
                case "sideBarPositionButton2":
                case "sideBarOFFButton":
                case "sideBarOFFButton2":
                case "sideBarONButton":
                case "sideBarONButton2":
                case "refMenuCloseButton":
                case "refTransferCanvasImageButton":
                case "refLoadImageButton":
                case "refMirrorImageButton":
                case "refMemoryTrainingOnButton":
                case "refMemoryTrainingOffButton":
                case "refClipBoardButton":
                case "appResetButton":
                case "dpiButton":
                case "newWindowButton":
                case "newWindowCloseButton":
                    {
                        if (isToolBox2Showing || isKeyPressed() || e.target.alpha < 1.0)
                        {
                            return;
                        }
                        handleMouseClick(targetName);
                    }
                    return;
                case "replaySpeedSliderWrapper":
                    {
                        // grid 에서 불러줬을때 캔버스에 안무것도 못하게
                    }
                    return;
                case "refClearImageButton":
                    {
                        if (ReferenceLayerController.isRefLayerEmpty())
                        {
                            ReferenceLayerController.showRefLayerIsEmptyHint();
                        }
                        else
                        {
                            startPressHoldKey(ReferenceLayerController.refLayerMenuBox.refClearImageButton, "Erasing reference image...", null, ReferenceLayerController.startReflayerClear, null);
                        }
                    }
                    return;
                case "timer":
                    {
                        startPressHoldKey(MainUI.topBar.timer, HintStrings.getResetTimerHintString(), null, realWorkingTimer.reset, null);
                    }
                    return;
                case "newFileButton":
                    {
                        if (MainUI.topBar.newFileButton.alpha === 1.0 && !BackgroundWorkerCoordinator.isSaveInProgress)
                        {
                            FileManager.createNewFile(false);
                        }
                    }
                    return;
                case "resizeButtonR":
                case "resizeButtonD":
                case "resizeButtonL":
                case "resizeButtonU":
                    {
                        CanvasController.startCanvasResizing(targetName);
                    }
                    return;
                case "sideBarScrollBar":
                    {
                        SidebarController.startScrollSidebarByDrag();
                    }
                    return;
                case "refRotateImageButton":
                    {
                        Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                        if (ReferenceLayerController.isRefLayerEmpty())
                        {
                            ReferenceLayerController.showRefLayerIsEmptyHint();
                        }
                        else
                        {
                            ReferenceLayerController.startRefLayerRotation();
                        }
                    }
                    return;
                case "refMoveImageButton":
                    {
                        Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                        if (ReferenceLayerController.isRefLayerEmpty())
                        {
                            ReferenceLayerController.showRefLayerIsEmptyHint();
                        }
                        else
                        {
                            ReferenceLayerController.startRefLayerImageDrag();
                        }
                    }
                    return;
                case "refResizeImageButton":
                    {
                        Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                        if (ReferenceLayerController.isRefLayerEmpty())
                        {
                            ReferenceLayerController.showRefLayerIsEmptyHint();
                        }
                        else
                        {
                            ReferenceLayerController.startRefLayerImageScale();
                        }
                    }
                    return;
                case "refOpacitySliderWrapper":
                    {
                        Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                        if (ReferenceLayerController.isRefLayerEmpty())
                        {
                            ReferenceLayerController.showRefLayerIsEmptyHint();
                        }
                        else
                        {
                            ReferenceLayerController.startRefLayerOpacityDrag();
                        }
                    }
                    return;
                case "refLayerMenuMoveButton":
                    {
                        DragInteraction.startBoxDrag(ReferenceLayerController.refLayerMenuBox);
                    }
                    return;
                case "dragDropFileBG":
                    return;
            }
            // 캔버스 영역 밖에서는 해주지 않음
            if (isCursorInDrawArea() && !CanvasController.isMouseClickBlocked)
            {
                switch (nowTool)
                {
                    case TOOL_PEN:
                        if (CanvasController.isToolEnabledByLayerUnChecked())
                            PenTool.start();
                        break;
                    case TOOL_FILLPEN:
                        if (CanvasController.isToolEnabledByLayerUnChecked())
                            fillPenTool.start();
                        break;
                    case TOOL_ERASER:
                        if (CanvasController.isToolEnabledByLayerUnChecked())
                            PenTool.startWithEraserMode();
                        break;
                    case TOOL_LINE:
                        if (CanvasController.isToolEnabledByLayerUnChecked())
                            lineTool(true);
                        break;
                    case TOOL_LASSO:
                        LassoTool.lassoToolFunction.start();
                        break;
                    case TOOL_MOVE:
                        moveTool();
                        break;
                        // 캔버스 조작
                    case TOOL_ZOOM:
                        zoomTool();
                        break;
                    case TOOL_HAND:
                        handTool(false, false);
                        break;
                    case TOOL_ROTATE:
                        rotateTool(false);
                        break;
                }
            }
        }
    }
}
