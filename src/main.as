package
{
    import flash.desktop.Clipboard;
    import flash.desktop.ClipboardFormats;
    import flash.desktop.NativeApplication;
    import flash.desktop.NativeDragManager;
    import flash.desktop.Updater;
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
    import flash.display.NativeWindow;
    import flash.display.Loader;
    import flash.display.NativeWindowInitOptions;
    import flash.display.NativeWindowSystemChrome;
    import flash.display.NativeWindowType;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;
    import flash.events.NativeDragEvent;
    import flash.events.NativeWindowBoundsEvent;
    import flash.events.FocusEvent;
    import flash.events.InvokeEvent;
    import flash.events.TimerEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileStream;
    import flash.filesystem.FileMode;
    import flash.filters.BlurFilter;
    import flash.filters.ConvolutionFilter;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.ColorTransform;
    import flash.geom.Rectangle;
    import flash.net.URLRequest;
    import flash.net.FileFilter;
    import flash.net.URLLoader;
    import flash.net.navigateToURL;
    import flash.net.URLLoaderDataFormat;
    import flash.system.Capabilities;
    import flash.system.IME;
    import flash.system.Worker;
    import flash.system.WorkerDomain;
    import flash.system.MessageChannel;
    import flash.utils.ByteArray;
    import flash.utils.getTimer;
    import flash.utils.Timer;
    import flash.text.TextFormat;
    import flash.ui.Mouse;
    import libwebp.DecodeWebp;
    import flash.events.UncaughtErrorEvent;
    import flash.events.ErrorEvent;
    import flash.text.engine.BreakOpportunity;

    //import end
    public class Main extends Sprite
    {
        public const  APP_VERSION:Number = 27.01;
        public const  APP_STATE_VERSION:Number = 2701;

        public const  TOOL_NONE:int = 0,
                      TOOL_PEN:int = (1 << 0),
                      TOOL_ERASER:int = (1 << 1),
                      TOOL_LINE:int = (1 << 2),
                      TOOL_FILL_PEN:int = (1 << 3),
                      TOOL_SCAN_FILL:int = (1 << 4),
                      TOOL_HAND:int = (1 << 5),
                      TOOL_LASSO:int = (1 << 6),
                      TOOL_EYEDROPPER:int = (1 << 7),
                      TOOL_ZOOM:int = (1 << 8),
                      TOOL_ROTATE:int = (1 << 9),
                      TOOL_MOVE:int = (1 << 10);

        public const  JUMP_FRAME_PLAY:int = (1 << 0),
                      JUMP_FRAME_MANUAL:int = (1 << 1),
                      JUMP_FRAME_PREV:int = (1 << 2),
                      JUMP_FRAME_NEXT:int = (1 << 3);

        public const  REPLAY_FASTEST_TOTAL_TIME:Number = 10,
                      REPLAY_DISK_CACHE_FRAME_INTERVAL:Number = 10000,
                      REPLAY_MEMORY_CACHE_FRAME_INTERVAL:Number = 700,
                      REPLAY_SLIDESHOW_ACTIVE_SPEED:Number = 60,
                      REPLAY_SLIDESHOW_FRAME_RATE:Number = 2, //1/2초 = 0.5초마다 갱신
                      REPLAY_SLIDESHOW_UPDATE_TIME:Number = 1000/REPLAY_SLIDESHOW_FRAME_RATE;
        public var    REPLAY_MAX_SPEED:Number = 0.0;

        public const  GRID_GAP:uint = 10,
                      GRID_NORMAL_COLOR:uint = 0x808080;

        public const  LASSO_SHARP_DATA:Array =[[[
                                                    0,-1,0,
                                                    -1,12,-1
                                                    ,0,-1,0
                                                ],8],

                                                [[
                                                    0,-1,0,
                                                    -1,10,-1
                                                    ,0,-1,0
                                                ],6],

                                                [[
                                                    0,-1,0,
                                                    -1,7,-1
                                                    ,0,-1,0
                                                ],3]];
        public const  KEY_REPEAT_START_DELAY:Number = 0.3,
                      KEY_REPEAT_INTERVAL:Number = 0.06;

        public const  LASSO_1PX_MOVE_UP:int= (1 << 0),
                      LASSO_1PX_MOVE_DOWN:int = (1 << 1),
                      LASSO_1PX_MOVE_LEFT:int = (1 << 2),
                      LASSO_1PX_MOVE_RIGHT:int = (1 << 3);

        public const  WORKER_WAIT_INTERVAL:Number = 0.5,
                      WORKER_STATE_STOPPED:int = 0,
                      WORKER_STATE_INIT:int = (1 << 0),
                      WORKER_STATE_RUNNING:int = (1 << 1);

        public const  STRING_TITLE_FOFOPAINT:String = " - FOFO PAINT",
                      STRING_PLAYBACK_SPEED:String = "Playback speed x",
                      STRING_ONEMORE_CLICK_TO_OK:String = "One more click to OK",
                      STRING_WAIT_PROCESSING_DONE:String = "Close the app after processing done",
                      STRING_CAPTURE_OK:String = " _ Reset [right-click]",
                      STRING_MERGE_LASSO_IMAGE_TO_REFLAYER:String = "Merge selected area\ninto reference layer",
                      STRING_MERGE_CANVAS_IMAGE_TO_REFLAYER:String = "Merge canvas image\ninto reference layer",
                      STRING_RIGHT_CLICK_TO_RESET:String = "Reset [right-click]",
                      STRING_CUSTOM_COLOR_HINT:String = "OK [Any key except 0 ~ 9]",
                      STRING_REFLAYER_IMAGE_OPACITY:String = "Image opacity ",
                      STRING_PRESS_HOLD:String = "press and hold",
                      STRING_CLICK_HOLD:String = "click and hold";
                    
        public const  REPLAY_IMAGE_CAHCHE_COMPLETE:int = (1 << 0),
                      REPLAY_IMAGE_CAHCHE_READY:int = (1 << 1),
                      REPLAY_IMAGE_CAHCHE_PROCESSING:int = (1 << 2);

        public const  UPDATE_NONE:int = 0,
                      UPDATE_CHECKING:int = (1 << 0),
                      UPDATE_READY:int = (1 << 1),
                      UPDATE_NEEDS_MANUAL:int = (1 << 2),
                      UPDATE_VERSION_URL:String = "https://raw.githubusercontent.com/guljam/2020FlashPaint/master/versionInfo.txt",
                      UPDATE_FILE_URL:String = "https://github.com/guljam/2020FlashPaint/releases/download/update2/fofoPaint.air",
                      UPDATE_MAX_DOWNLOAD_RETRY:int = 5,
                      UPDATE_RETRY_DELAY:Number = 3.0;

        public const  CANVAS_MIN_SIZE:Number = 100,
                      CANVAS_MAX_SIZE:Number = 2000;

        public var  STAGE_BG_COLOR:uint = 0xCCCCCC;
        public var  CANVAS_WIDTH:Number = 600,
                    CANVAS_HEIGHT:Number = 390,
                    CANVAS_BG_COLOR:uint = 0xFFFFFF,
                    RCANVAS_WIDTH:Number = 600,
                    RCANVAS_HEIGHT:Number = 390,
                    RCANVAS_BG_COLOR:uint = 0xFFFFFF;

        public const BOTTOM_BAR_HEIGHT:Number = 25;
        public var  STAGE_TOP_OFFSET:Number = 0, //창 상하좌우 여백
                    STAGE_LEFT_OFFSET:Number = 0,
                    STAGE_BOTTOM_OFFSET:Number = BOTTOM_BAR_HEIGHT,
                    STAGE_RIGHT_OFFSET:Number = 0,
                    TOTAL_FRAME:Number = 0;//rdata+file 프레임 전부 합친거
                      
        //파일 저장 경로
        public const  appStateFilePath:File = File.applicationStorageDirectory.resolvePath("appstate"+(APP_STATE_VERSION.toString())),
                      scratchPadDataFilePath:File = File.applicationStorageDirectory.resolvePath("scratchdata"),
                      undoDataFilePath:File = File.applicationStorageDirectory.resolvePath("undodata"),
                      replayDataFilePath:File = File.applicationStorageDirectory.resolvePath("repdata"),
                      replayCacheImageFolderPath:File = File.applicationStorageDirectory.resolvePath("imagecache"),
                      replayCacheImageFrameDataFilePath:File = File.applicationStorageDirectory.resolvePath("jumpframedata"),
                      myPaletteDataFilePath:File = File.applicationStorageDirectory.resolvePath("mypalettedata"),
                      refLayerImageFilePath:File = File.applicationStorageDirectory.resolvePath("refimg"),
                      updateFilePath:File = File.applicationStorageDirectory.resolvePath("updateTmpFile.air");

        //키 누름 관련
        public var LAST_KEY:int = -1;//마지막 누른거 여기다가 저장 반복호출되는 keydown 함수에서 한번만 호출되게 하는변수
        public const KEY_BUFFER:Array = []; //정식 키 다운 눌러준 상태에서 다른 키가 눌러져 있으면 여기다가 저장
        public const COMMAND_CTRL:int = (1 << 0),
                      COMMAND_SHIFT:int = (1 << 1),
                      COMMAND_CTRL_SHIFT:int = (1 << 2);
        public const KEY:Object = {
                                        a:65,
                                        b:66,
                                        c:67,
                                        d:68,
                                        e:69,
                                        f:70,
                                        g:71,
                                        h:72,
                                        i:73,
                                        j:74,
                                        k:75,
                                        l:76,
                                        m:77,
                                        n:78,
                                        o:79,
                                        p:80,
                                        q:81,
                                        r:82,
                                        s:83,
                                        t:84,
                                        u:85,
                                        v:86,
                                        w:87,
                                        x:88,
                                        y:89,
                                        z:90,
                                        dot:190,
                                        comma:188,
                                        semicolon:186,
                                        shift:16,
                                        ctrl:17,
                                        alt:18,
                                        rightAlt:21, //as에서는 한글모드
                                        rightCtrl:25, //한글 모드에서 오른쪽 컨트롤
                                        space:32,
                                        backslash:220,
                                        backspace:8,
                                        enter:13,
                                        esc:27,
                                        del:46,
                                        tab:9,
                                        n0:48,
                                        n1:49,
                                        n2:50,
                                        n3:51,
                                        n4:52,
                                        n5:53,
                                        n6:54,
                                        n7:55,
                                        n8:56,
                                        n8:56,
                                        n9:57,
                                        minus:189,
                                        pgup:33,
                                        pgdn:34,
                                        home:36,
                                        end:35,
                                        left:37,
                                        up:38,
                                        right:39,
                                        down:40,
                                        f1:112,
                                        f2:113,
                                        f3:114,
                                        f4:115,
                                        f5:116,
                                        f6:117,
                                        f7:118,
                                        f8:119,
                                        f9:120,
                                        f10:121,
                                        f11:122,
                                        f12:123,
                                        window:91
                                    };

        //프레임 타이머 
        public const addTimer:Function = FOFOTimer.add,
                     addTimerByName:Function = FOFOTimer.addByName,
                     hasTimer:Function = FOFOTimer.hasTimer,
                     removeTimer:Function = FOFOTimer.remove;

        //메뉴 요소
        public const stageBG:Sprite = new Sprite(), //드래그 불러오기가 stage공백에서는 안되서 수동으로 전체바탕으로 만들어줌
                     resizeButtonR:Sprite = new Sprite(),//캔버스 리사이즈 하는 버튼
                     resizeButtonD:Sprite = new Sprite(),
                     resizeButtonL:Sprite = new Sprite(),
                     resizeButtonU:Sprite = new Sprite(),
                     toolBox:ToolMenuSet = new ToolMenuSet(),
                     toolBox2:ToolMenuSet2 = new ToolMenuSet2(),
                     fillPenBox:FillPenMenuSet = new FillPenMenuSet(),
                     canvasRotateCursor:RotateCursorSet = new RotateCursorSet(),//회전이 얼마나 됐는지 표시,
                     topBar:TopMenuSet = new TopMenuSet(),
                     eyedropperLens:EyedropperLensSet = new EyedropperLensSet(),
                     mouseHint:HintBoxSet = new HintBoxSet(stage,true),
                     bottomHint:HintBoxSet = new HintBoxSet(stage,false),
                     bottomBar:Sprite = new Sprite(),
                     hintHighlightBox:Shape = new Shape(), //요소에 마우스 클릭하면 사각형으로 하이라이트 표시해줌
                     aboutBox:AboutWindowSet = new AboutWindowSet(),
                     loadMenuBox:LoadBoxSet = new LoadBoxSet(),
                     toolOptionsBox:ToolOptionsSet = new ToolOptionsSet(),
                     colorPickerBox:ColorPickerSet = new ColorPickerSet(),
                     canvasNavigatorBox:CanvasNavigatorBoxSet = new CanvasNavigatorBoxSet(),
                     canvasInfoBox:CanvasInfoSet = new CanvasInfoSet(),
                     numPadBox:NumPadSet = new NumPadSet(),
                     sideBar:SidePanelSet = new SidePanelSet(),
                     fofo:FOFO = new FOFO(),
                     sideBarScrollBar:Sprite = new Sprite(),
                     sideBarScrollPanel:Sprite = new Sprite(),
                     canvasFlashEffect:Sprite = new Sprite();

        //초창기 개발 변수
        //펜툴 줌툴 미러 에어브러시
        public var  canvasAnchorPoint:Sprite = new Sprite(),//회전 스프라이트 부모
                    canvasPanel:Sprite = new Sprite(), //회색 부분을 제외한 그리기 영역 추가
                    canvasDrawLayer:Sprite = new Sprite(), //캔버스 2번 임시로 그려주는 캔버스 버퍼?
                    canvasDrawLayerChild:Shape = new Shape(), //실제로 선을 긋는 요소
                    canvasLayer1BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0),
                    canvasLayer2BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0),
                    canvasDrawLayerBitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0),
                    canvasLayer1Bitmap:Bitmap = new Bitmap(canvasLayer1BitmapData,"auto",true),
                    canvasLayer2Bitmap:Bitmap = new Bitmap(canvasLayer2BitmapData,"auto",true),
                    canvasDrawLayerBitmap:Bitmap = new Bitmap(canvasDrawLayerBitmapData,"auto",true),
                    penSizePreviewCursor:Shape = new Shape(), //펜사이즈 미리 보기
                    canvasDrawLayerClipRect:Rectangle = new Rectangle(), // 그려준 영역 만큼만 캔버스bitmap1에 그려주는 사각형
                    isCanvasMirrored:Boolean = false,
                    mirrorCommandReady:Boolean = false, //미러 커맨드를 넣어줄지 말지 결정
                    canvasZoomMultiplerList:Array = [0.125,0.25,0.5,0.75,1.0,1.50,2.0,3.0,4.0,6.0,8.0,12.0,16.0,24.0,32.0],
                    canvasZoomMultipler:Number = 1.0,
                    canvasZoomIndex:int = 3,
                    isMouseClicked:Boolean = false, //클릭하면 올려줌,
                    isRightMouseClicked:Boolean = false, //클릭하면 올려줌
                    isMouseDragging:Boolean = false, //툴을 계속 클릭한채로 움직이면 topmenu의 힌트가 안켜지도록 함
                    isMouseClickBlocked:Boolean = false, //알탭 하고나서 창활성화 되면 일정시간동안 작동하지 않게함
                    nowTool:int = 1, //현재 툴 번호
                    lastTool:int = TOOL_NONE, //툴백업
                    isKeyReleasedBeforeMouseUp:Boolean = false, //키 떼기 전에 마우스 먼저 떼주었을때 플래그 올려줌
                    penAlpha:Number = 1.0, //펜 변수,
                    penColor:uint = 0x000000,
                    isTransparentPenColor:Boolean = false, // 펜 컬러 투명 켜졌을때 올려줌
                    penSizeList:Array = [0,1,2,3,4,5,7,10,13,18,30,45,80],
                    penAlphaList:Array = [0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0],
                    penCursorSize:Number = 3,
                    penCursorShape:Boolean = false,
                    penSize:uint = 3,
                    penSizeIndex:uint = 3,
                    penAlphaIndex:uint = 9,
                    penIsSquare:Boolean = false, //false 이면 원 true 이면 사각형
                    penSmoothValue:Number = 0, //펜 손떨방 플래그
                    penSmoothSlideValue:int = 0, //펜 손떨방 플래그
                    penSmoothSlideTotal:Number = 20, //손떨방 총 단계
                    penListShapeIsSqare:Boolean = false, //펜 리스트에서 펜 모양 버튼 눌러줄때 툴이랑 상관없이 바꿔줌, 펜 미리보기 할때 필요
                    penLastSizeAndShape:Array = [null,null], //updatePenSizeCursor 중복 사용 방지를 위해서 마지막 크기 저장해놓고 같으면 건너뜀
                    eraserSize:uint = 12,
                    eraserSizeIndex:uint = 8,
                    eraserIsSquare:Boolean = false,
                    eraserAlpha:Number = 1.0,
                    eraserAlphaIndex:uint = 9,
                    isEraserAirBrushON:Boolean = false,
                    isFillPenON:Boolean = false, //채우기 펜 플래그
                    isFillPenStarted:Boolean = false, //채우기 펜 시작됨
                    isSharpLineON:Boolean = false, //0.5픽셀어긋나게 안하고 완전히 정확하게 할때씀
                    isLayer2Selected:Boolean = false,
                    checkedLayer:int = 0, //레이어가 체크되면 저장해줌
                    isLayerSwapped:Boolean = false, //1<->2 번호 바뀌는 힌트 써주려고 만듬
                    isPenAirBrushON:Boolean = false,
                    airBrushSizeDrawMode:int = 0,
                    airBrushClipRectOffsetData:Array = [0,4,2,2,0,0,0,-2,-5,-5,-10,-16,-43];

        //컬러픽커
        public var hsvColorData:Vector.<Number> = new Vector.<Number>(3, true), //h,s,v순서 hue컬러 다른 함수들이랑 통신하기 위해서 전역으로 만들어줌
                   isColorPickerModeBG:Boolean = false, //false이면 펜컬러 true이면 배경색
                   pickerModeResetFlag:Boolean = false, //배경색 선택하고 나서 커서가 사이드바를 나가면 리셋해주는 이벤트를 올려주는 플래그
                   pickerOpaClicked:Boolean = false, //피커박스에서 투명도 조절했을때 올려줌 mouse out 이벤트 하나만 작동되게 할라고
                   pickerHSVButtonMousePoslast:Point = new Point(), //HSV버튼 마우스 위치 저장용
                   isColorPickerBoxPositionSwapped:Boolean = false, //마이팔래트랑 컬러피커박스 위치 바뀌면 올려줌
                   pickerIgnoreHistoryColor:* = null; //히스토리 색 등록 할때 여기에 등록된 색은 등록 안하게함

        //오른쪽 클릭 툴박스
        public var isToolBox2Showing:Boolean = false; //툴박스가 오른쪽 클릭으로 켜졌을때 올려줌

        //undo
        public var  undoDataIndex:int = -1, //undo redo 상태 인덱스임
                    isDeleteUndoDataPending:Boolean = false, //undo하고 나서 addundo가 되었을때 뒷부분 데이터 전부 날려주는 플래그
                    canAddUndoData:Boolean = false; //선을 그어줄대 선전체가 캔버스 바깥쪽에 있을수도 있으니까 이걸 판단해줌

        //lasso
        public var lassoMenuBox:LassoMenuSet = new LassoMenuSet(), //라소툴 버튼
                   lassoDraw:Shape = new Shape(), //라소 영역 선 그려주는 쉐이프
                   lassoLayer1:Sprite = new Sprite(), //선택한 이미지를 그려주고 확대 축소등 조작
                   lassoLayer1Bitmap:Bitmap = new Bitmap(),
                   lassoLayer2:Sprite = new Sprite(), //lassoLayer2 레이어
                   lassoLayer2Bitmap:Bitmap = new Bitmap(), //lassoLayer2의 비트맵
                   isLassoToolStarted:Boolean = false, //라소툴로 영역 선택하면 올려줌
                   lassoFirstData:Array = [], //이 값이랑 비교해서 달라진게 있으면 ok할때 적용해줌
                   isLassoMirrorON:Boolean = false, //라소 mirror클릭했을때 마다 반전해줌
                   isLassoMenuHiddenTemp:Boolean = false, //툴 고정되어서 라소 선택하고 줌툴 클릭했을때 메뉴 잠시 없애주는 플래그
                   lassoTransformData:Array = [], //라소 변형 데이터
                   isLassoImageCopied:Boolean = false, //lasso 복사 누르면 올려줌
                   lassoLayer1LastBitmapdata:BitmapData, //copy나 취소했을때 원래대로 돌려주는 이미지
                   lassoLayer2LastBitmapdata:BitmapData, //copy나 취소했을때 원래대로 돌려주는 이미지
                   lassoLayerCommandData:Array = null, //스왑 머지 순서 저장해줌
                   isLassoLayerSwapButtonClicked:Boolean //스왑 버튼 클릭할때마다 true false로 변경해줌

        //save load 관련 변수
        public var isFileAlreadySaved:Boolean = false, //세이브 버튼 여러번 눌러서 데이터 계속 쓰여지는거 방지
                   isContinueSaveON:Boolean = false, //한번 저장후에 다른이름으로 저장하기 전까지는 똑같은 이름으로 저장
                   lastSaveFileName:String = getRandomFileName(), //세이브 파일 저장후에 이름을 이쪽에다가 보관해서 계속 그 이름으로 저장할수있게함
                   lastSaveFilePath:String = lastSaveFileName, //파일 저장경로로 계속 저장 초기에는 filename이랑 똑같게 해줌
                   lastSaveCaptureFilePath:String = lastSaveFileName,
                   rLayer1FirstImageData:ByteArray = new ByteArray(), //리플레이 데이터 저장해줄때 쓰는 바이트 배열 전역으로 돌려서 새로운 객체 하나만 생성하도록함
                   rLayer2FirstImageData:ByteArray = new ByteArray(), 
                   rLayer1CurrentImageData:ByteArray = new ByteArray(), 
                   rLayer2CurrentImageData:ByteArray = new ByteArray(), 
                   refLayerImageData:ByteArray = new ByteArray(), 
                   replayDataReadBytes:ByteArray = new ByteArray(); 

        //키 오래누름 관련 변수
        public var pressHoldCountDownTime:Number = 0.0,
                   pressHoldFrameCount:int = 0

        //컬러 히스토리 관련 변수
        public var isMyPaletteExpended:Boolean = false, //전체로 보면 올려줌
                   myPaletteColorBeforeAddColor:Array = [-1,0], //index, hexcolor
                   myPaletteColorLimit:int = 100,
                   myPaletteColorWidth:Number = 17, //Math.floor(pickerBox.svBoxWidth/myPaletteLimit)//히스토리 개별 색깔 가로 크기
                   myPaletteColorHeight:Number = 17,
                   myPaletteClickPos:Point = new Point(), //컬러 히스토리 클릭하면 위치 넣어줌
                   myPaletteMovePos:Point = new Point(), //컬러 히스토리 드래그할때 움직이는 포인트 넣어줌
                   myPaletteDragClickedColor:uint = 0, //드래그 준비 클릭한 컬러 저장해줌
                   myPaletteDragClickedIndex:int = -1, //드래그 준비 클릭한 컬러 인덱스 저장
                   myPaletteDragStarted:Boolean = false, //컬러 히스토리 드래그 시작하면 올려줌
                   myPalettePresetType:int = 0, //타입저정 0=mypalette, 1=drawr, 2=tegaki
                   myPalettePreset:Array = [],
                   myPaletteDrawrPreset:Array = [0xFFFFFF,0xC0C0C0,0xFF3B21,0xFFBD16,0xF5F30F,0xA5E975,0x71DBFD,0xFA80F9,null,null,
                                                 0x000000,0x808080,0x8E0000,0xFFCC99,0x877D30,0x008F47,0x313BCD,0xC02E97,0x3F037E,null],
                   myPaletteTegakiPreset:Array = [0xA80515,0xA80515,0x800000,0x800000,0x4B3D38,0x4B3D38,0x313768,0x313768,0x394C44,0x394C44,
                                                  0xF1D0D0,0xF1D0D0,0xF1E1D7,0xF1E1D7,0xEAE5D5,0xEAE5D5,0xD5E9F3,0xD5E9F3,0xD0EBDE,0xD0EBDE],
                   myPaletteSaveColorBeforeOtherType:Array = [0,0,0xA80515]; //다른 타입으로 바꾸기 전에 저장된 컬러

        //리플레이
        public var repFileTemp:File, //파일을 저장하거나 불러올때 씀
                   rFileStream:FileStream = new FileStream(), //함수들을 왔다갔다 해야해서 전역으로 하나
                   rCanvasAnchorPoint:Sprite = new Sprite(), //회전 스프라이트 부모
                   rCanvasPanel:Sprite = new Sprite(),
                   rCanvasDrawLayer:Sprite = new Sprite(),
                   rCanvasDrawShape:Shape = new Shape(),
                   rCanvasLayer1BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH, CANVAS_HEIGHT, true, 0),
                   rCanvasLayer2BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH, CANVAS_HEIGHT, true, 0),
                   rCanvasDrawLayerBitmapData:BitmapData = new BitmapData(CANVAS_WIDTH, CANVAS_HEIGHT, true, 0),
                   replayTimelineBox:ReplayTimelineSet = new ReplayTimelineSet(),
                   rCanvasLayer1Bitmap:Bitmap = new Bitmap(rCanvasLayer1BitmapData, "auto", true),
                   rCanvasLayer2Bitmap:Bitmap = new Bitmap(rCanvasLayer2BitmapData, "auto", true),
                   rCanvasDrawLayerBitmap:Bitmap = new Bitmap(rCanvasDrawLayerBitmapData, "auto", true),
                   rReplayFOFOCursor:FOFOCursor = new FOFOCursor(), //재생할때 틀어주는 작은 마우스
                   rCanvasDrawLayerClipRectLegacy:Rectangle = new Rectangle(), //갱신된 부분만 그려주는 거 오래된 버전 지원때문에 남겨둠
                   rCanvasDrawLayerClipRect:Rectangle = new Rectangle(), //갱신된 부분만 그려주는 거 이게 새거임
                   updatePrograssBarStartTime:int = 0, //리플레이 시작 시간저장 update prograss bar에서 프레임 오차 수정할때 참고하는 변수
                   isReplayStarted:Boolean = false, //리플레이 시작버튼 여러번 누르는거 방지
                   isReplayFinished:Boolean = true, //리플레이가 자연히 끝났을때 올려주는 플래그 가장 처음에 캔버스 싹쓸이 하기 위해서 넣어줌.
                   isReplayFinishedWithFiwWindow:Boolean = false, //리플레이가 follow cursor옵션으로 캔버스 작게 축소되서 끝났을때
                   isReplayModeON:Boolean = false, //이건 모드 자체 껐다 켰다
                   isReplayRepeatON:Boolean = true, //리플레이 반복 켜기 끄기
                   rDataBuffer:Array = [], //draw layer에서 그려준 데이터를 이쪽으로 다모아줌
                   rData:Array = [], //rDataBuffer가 이쪽으로 이동되고 undo image data갯수에 똑같이맞추어줌
                   rDataFrame:Array = [], //rdata안에 몇프레임이 들어있는지 저장
                   rDataReadFlag:Boolean = true, //rData읽을때는 true, r file 읽을때는 false
                   rFileLastBytePosition:Number = 0, //fs position 저장
                   rFileCutBytePosition:Number = 0, //super undo에서 파일 잘라줄때 필요함
                   rDataIndex:int = 0, //rData에서만씀 rData 스크로크 뭉치 인덱스
                   rDataStartIndex:int = 0, //리플레이에서 프레임 스캡을 앞부분으로 해줄때 rdata를 읽는 부분이면 현재 undoindex부분 부터 읽게 인덱스를 올려줌
                   rLastLayer2Selcted:Boolean = false, //리플레이 실행할때 이걸로 비교해서 캔버스 스왑해줌
                   rLastCanvasBGColor:uint = RCANVAS_BG_COLOR, //load replay에서 씀
                   rReplaySpeedMultipler:Number = 1, //리플레이 속도 for루프로 2번씩혹은 3번씩 읽히게 만듬
                   rAirBrushSize:int = 0, //레거시지원 변수
                   rAirBrushSize2:int = 0, //새로운거
                   rNowFrame:Number = 0, //dodraw에서 현재까지 플레이된 프레임수 누적, jump frame이 가동됐을때 프레임 누적갯수를 세서 썸네일 이미지 만들어줌
                   rPrevFrame:Number = 0, //jump one frame 에서 이전 프레임 탐색할때 이 프레임으로 탐색해줌 tickdraw에서 data 끝의 프레임을 저장함
                   rFirstImageLayer1BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0), 
                   rFirstImageLayer2BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0), 
                   rFirstImageBGColor:uint = CANVAS_BG_COLOR, 
                   rMirrorON:Boolean = false, //대칭 켜지면 올려줌
                   rCanvasZoomMultiplier:Number = 1.0, //리플레이 줌
                   rLastCanvasZoomMultiplier:Number = 1.0, //리플레이에서 수동줌하면 여기다가 저장해줌
                   rCanvasZoomIndex:int = 3, 
                   isReplayCanvasFitToWindow:Boolean = false, // 리플레이에서 오른쪽 클릭해서 창 크기에 맞췄을때 올려줌 startreplay될때 줌 1.0으로 리셋 못시키게함
                   rJumpImageIndexLast:int = -2, //썸네일 인덱스 바뀌면 여기다 저장
                   rJumpImageNowFrameLast:Number = -1, 
                   rCachedImageLastIndex:int = -2, //마지막에 그려준 캐쉬 이미지 번호를 저장
                   rTempCachedLastImageIndex:int = -2, // 더 잘게 쪼개준 이미지 인덱스 바뀌면 여기다 저장
                   rJumpImageFrameData:Array = [0], //스킵이미지 저장될때 r file frame sum을 저장해줌 처음에 rfirstimage라서 0번 추가해줌
                   rReplayImageCacheState:int = REPLAY_IMAGE_CAHCHE_COMPLETE, 
                   rReplayRestartTimerCount:uint = 0, //리스타트 타이머
                   rTimeLIneTextUpdateTime:int = 0, //프레임 바 딜레이
                   isReplaySlideShowMode:Boolean = false, //doDrawSlowEvent가 켜지면 올려줌
                   rFrameTempCachedImages:Array = [], //이전 탐색 프레임 빠르게 하기 위해서 jumpimage구간에서 더 잘게 이미지를 나누어주고 정보를여가다가 저장함
                   rSpeedLastHint:String = "";

        //about
        public var isAboutBoxOpened:Boolean = false, //어바웃 창 떴을때 킴
                    appUpdateStatus:int = UPDATE_NONE, //새버전 나왔을때 올려주는 플래그
                    newVersionStr:String = ""; //새버전 문자열 저장

        //캡쳐모드
        public var isCaptureModeON:Boolean = false, //스크린샷 켜지면 올려줌
                    isCaptureCanvasFlipped:Boolean = false, //캡쳐 대칭한 변수 저장
                    isCaptureTransparentBGShowing:Boolean = false, //배경 제외하고 저장하는 플래그
                    isCaptureStampTextFieldFocused:Boolean = false, //포커스 되면 올려줌
                    isCaptureStampEnabled:Boolean = false,
                    isCaptureModeInputEventsAdded:Boolean = false, // 이벤트 세트가 켜지거나 꺼지는거 보관, 중복 이벤트 추가 피하려고
                    captureStampFontListBox:CapStampFontListSet = new CapStampFontListSet(),
                    captureDragAreaOverlay:Shape = new Shape(), //스크린샷 박스 미리보기 그려줌
                    canvasStateBeforeCaptureMode:Object = {}, //캡쳐 키면 캔버스 이전 상태 저장함
                    drawModeCanvasStateForSaveAppState:Object = {}, //save app state에서 캔버스가 capture모드 상태로 저장해주기 때문에 백업한 데이터로 저장시켜줌
                    captureWindowMove:Point = new Point(0,0), //스크린샷이 켜져있는 상태에서 창을 조절했을때, 스크린샷이 끝나고 나서 regpoint를 그만큼 움직여줘야함
                    captureCanvasRotationStep:uint = 0, //캡쳐 회전한 변수 저장
                    capTransparentBGBMPDSize:Number = 32,
                    capTransparentBGBMPD:BitmapData;

        //윈도우 크기변
        public var lastAppWindowSize:Point = new Point(), //창크기 조절 얼마나 됐을지 비교할때 마지막 크기 창크기 저장
                   lastAppWindowSizeInfo:Array = [0,0,680,768],
                   lastAppWindowState:int = 0;

        //이미지 붙여넣기 
        public var  isClipBoardButtonActivated:Boolean = false //윈도우 active에서 붙여넣기 가능한 이미지가 있으면 올려줌

        //참고 레이어
        public const canvasRefLayer:Sprite = new Sprite()//트레이스 레이어임
        public var  isRefLayerMemoryTrainingON:Boolean = false, // 이거 켜지면 캔버스 그릴때 임시적으로 안보이게함
                    canvasRefLayerBitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0), 
                    canvasRefLayerBitmap:Bitmap = new Bitmap(), 
                    refLayerMenuBox:RefLayerMenuSet = new RefLayerMenuSet(), 
                    refLayerMenuDragXMoveSum:Number = 0, //전역으로 돌려서 다시 클릭하거나 이미지를 불러와도 원래 스케일을 저장하도록함
                    isRefLayerMenuON:Boolean = false, //참조레이어 메뉴 켜졌을때 올려줌
                    refLayerRawBitmapData:BitmapData = null, 
                    refLayerRawTransformData:Array = null, 
                    refLayerMenuConfirmCount:int = 0, //2번이상 클릭하면 되게
                    refLayerLastAlpha:Number = 0.5;

        //그리드 레이어
        public const canvasGrid:Shape = new Shape(), //트레이스 레이어임
                     gridGraphicsCommands:Vector.<int> = new Vector.<int>,
                     gridGraphicsData:Vector.<Number> = new Vector.<Number>;

        public var  gridGapValue:uint = 0,
                    lastGridGapValue:Number = 0.0, //줌할때 다시 그려주는거 방지 갭이 다를때만 다시 그러줌
                    gridDrawOffsetX:Number = 0.0,
                    gridDrawOffsetY:Number = 0.0;

        //툴 클로져 자주쓰는거는 클로져로 메모리에 미리 올려둬서 성능향상하려고 한건데 모르겠음
        public const  realWorkingTimer:Object = cRealWorkingTimer(),
                      dottedLine:Object = cDottedLine(),//순서 먼저 와야함
                      penTool:Function = cPenTool(),
                      dotTool:Function = cDrawDot(),
                      lineTool:Function = cLineTool(),
                      handTool:Function = cHandTool(),
                      lassoToolFunction:Object = cLassoTool(),
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
                      captureAreaManager:Object = cDrawCaptureArea(),
                      captureStampManager:Object = cDrawCaptureStamp(),
                      replayHideCursor:Object = cCheckHideCursor(),
                      resizeCanvas:Object = cResizeCanvas(),
                      gridButton:Object = cGridFunc();

        //스크롤바
        public var scrollSetMovedY:Number = 0,
                    scrollBarHeight:Number = 0,
                    sideBarConstHeight:Number = 780;

        //ui 색깔

        //워커
        public var  worker:Worker,
                    mainToBack:MessageChannel,
                    backToMain:MessageChannel,
                    isSaveInProgress:int = 0,
                    isSaveInProgressOFFDelayTimer:int = 0,
                    receivedSaveImageDataFromWorker:ByteArray = null,
                    captureImageDataQueue:Array = null,
                    receivedCaptureImageQueueFromWorker:Vector.<ByteArray>,
                    receivedUndoImageQueueFromWorker:Array = null,
                    undoDataQueue:Array = null,
                    workerSWF:ByteArray = null,
                    workerDataSendCount:int = 0,
                    workerDataReceiveCount:int = 0,
                    workerState:int = WORKER_STATE_STOPPED,
                    workerWaitCount:int = 0, //워커 시작하고나서 약간 대기 시켜줘야함,
                    workerFunctionsBeforeStart:Array = [];

        //새창 관련
       public var  canvasWindowInfo:Array = [null, null, 400, 400], // x, y, 너비, 높이
                   isCanvasWindowON:Boolean = false,                // 캔버스 새창 켜졌을 때
                   canvasWindow:NativeWindow,                       // 참조된 새 창
                   canvasWindowLayer1Bitmap:Bitmap,                 // 새창 안에 들어갈 레이어 1
                   canvasWindowLayer2Bitmap:Bitmap,                 // 새창 안에 들어갈 레이어 2
                   canvasWindowCanvasPanel:Sprite,                  // 캔버스 배경색
                   canvasWindowCanvasPanelBgSize:Point = new Point(0, 0), // 배경 크기
                   canvasWindowCanvasPanelBgColor:uint = 0,         // 배경 색상
                   canvasWindowIgnoreResizeEventFlag:Boolean = false; // 창 크기 조정 이벤트 무시 플래그

        // 딥언도 관련
        public var isDeepUndoEnabled:Boolean = false,
                    lastDeepUndoEnabledFlag:Boolean = false, //리플레이 켜줄때 딥 플래그를 꺼줘서 여기다가 미리 저장해둠
                    lastReplayFrameOnDeepUndoStart:Number = -1; //리플레이 켜줄때 rNowFrame이 변하니까 그전에 백업해주고 꺼주고 다시 undo실행할때 이 프레임 기준으로 하려고

        //picker box RGB info관련
        public var  lastRGBInfoColorPartIndex:int = -1, //처음 클릭했을때 R G B중 어느 영역을 클릭했는지
                    isHSVInfoTextMode:Boolean = false, // true가 되면 hsv false이면 rgb
                    numpadInputBuffer:String = "";    //숫자키 누르면 어기다가 저장해주고 필터링해줘서 rgbinfotext에 갱신해줌

        //사이드바 관련
        public var  isSidebarVisible:Boolean = true,               // 사이드바 표시 여부
                    isSidebarTempShowDeactivated:Boolean = false,  // 사이드바 임시로 보여주는 기능이 잠시 꺼졌을때 올려줌
                    isReactivateSidebarTempShowEventsAdded:Boolean = false,  // 사이드바 임시로 보여주는 기능을 끄는 이벤트들이 등록되면 올려줌
                    isSidebarHideEventAdded:Boolean = false,          // 사이드바가 임시로 보여졌을때 마우스 클릭하면 꺼주는 이벤트가 추가되면 올려줌
                    isRightSidebar:Boolean = false,                // 사이드바 위치 (false: 왼쪽, true: 오른쪽)
                    lassoAndRefLayerBoxLastPos:Array = [0,0,0,0,0,0,0,0]; // 사이즈바 켜줄때 임시로 사이드바 안쪽으로 밀려나게 하고 위치가 변경되지 않았으면 원래대로 복귀해줌
                                                                          //좌표순서 라소 이전, 이후, 트레이스 이전 이후

        //기타
        public var  isAppClosing:Boolean = false,                  // 앱종료할때 올려줌 창 최대화 되어있는 상태를 원래대로 하고 window resize이벤트에서 마지막에 종료 호출
                    lastWindowDeactivateTime:int = 0,              // 윈도우 비활성화된 시간 저장, 알탭 반복 시 save all data 과다 호출 방지
                    isPenSizeCursorInvisible:Boolean = false,      // 펜 커서가 보이지 않게 설정
                    lastEraserPosButton:SimpleButton = null,       // 지우개 툴이 이동한 버튼 저장, 복원용
                    isQuickSidebarActive:Boolean = false,          // 퀵 사이드바 활성화 여부
                    isUpdatePendingAfterSaving:Boolean = false,    // 업데이트 버튼 눌렀을 때 저장 후 대기 플래그
                    isLoadPendingAfterSaving:Boolean = false,      // 저장 후 로드 대기 플래그
                    isLayerCheckKeyPressed:Boolean = false,        // 키 입력 반복 시 함수 중복 호출 방지 플래그
                    isDrawModeInputEventsAdded:Boolean = false,    // 드로우 모드 이벤트 중복 추가 방지
                    isReplayModeInputEventsAdded:Boolean = false,  // 리플레이 모드 이벤트 중복 추가 방지
                    isFileBrowserOpened:Boolean = false,           // 캡처 저장 시 중복 실행 방지 플래그
                    lastLoadedFile:File,                           // invoke나 파일 드래그 드롭했을때 저장해줘서 같은 파일 로드하지 않게
                    loadMenuBoxBitmapData:BitmapData,              // 메뉴 박스 미리보기 이미지 데이터
                    loadMenuBoxFileType:String,                    // 메뉴 박스에 로드할 파일 종류
                    loadMenuBoxFile:File,                          // 메뉴 박스에 로드할 파일
                    lastBottomHintTarget:DisplayObject;            // bottomhint mosue move에서 자꾸 호출해주니까 미자막 오브 젝트 저장해서 호출 조금 덜하게 해줌

        public function Main():void
        {
            if(stage)
            {
                initializeStage();
            }
            else
            {
                this.addEventListener(Event.ADDED_TO_STAGE,onStageAdded);
            }
        }

        public function onStageAdded(e:Event):void
        {
            this.removeEventListener(Event.ADDED_TO_STAGE,onStageAdded);
            initializeStage();
        }

        public function initializeStage():void
        {
            updateWindowTitle();
            markWindowTitleAsDirty();
            initializeStageSettings();
            initializeCanvas();
            initializeReplayCanvas();
            initializeAppMenus();
            initializeResizeButtonFamily();
            initializeCaptureModeTransparentBG();
            initializeWorker();
            updateAppWindowSizeInfo();
            loadAppState();
            //입력 이벤트는 loadappdata보다느려야함
            addGlobalEvents();
            addGlobalEventsChild();
            addInputEventsDrawMode();
            initializeReplayDataFile();
            centerCanvas();
            centerCanvas(true);
            canvasNavigatorBox.updateImage(canvasLayer1BitmapData,canvasLayer2BitmapData,CANVAS_BG_COLOR);
            realWorkingTimer.start();
            checkForUpdates();
            tryDisableIME();
            colorPickerBox.setActiveColorPreset(0);
            mouseHint.updateBGColor();
            moveSideBar("left"); // 컨트롤 박스 크기가 set pentool 이후에 제대로 바뀜 원인 모름
            stage.addChild(fofo);
            stage.setChildIndex(fofo,stage.getChildIndex(sideBar)+(stage.getChildIndex(fofo) < stage.getChildIndex(sideBar)?0:1));
            HintStrings.init(this);
            bottomHint.visible = true;
            selectPenTool();
            checkCanUseClipBoardButton();
        }

        //function
        public function getCaptureModeHintCanvasPanel():String
        {
            return "draw"
        }

        public function updateLayer1BitmapData(newbmpd:BitmapData):void
        {
            canvasLayer1BitmapData = newbmpd.clone();
            canvasLayer1Bitmap.bitmapData = canvasLayer1BitmapData;
        }

        public function updateBitmapData(currentbmpd:BitmapData, newbmpd:BitmapData, targetBitmap:Bitmap):BitmapData
        {
            if (currentbmpd !== null && currentbmpd === newbmpd)
            {
                return currentbmpd;
            }

            const clone:BitmapData = newbmpd.clone();
            //currentbmpd distpos를 해주고 싶지만 뭔가 이미지 적용이 안되는 현상이 있어서 안해줌

            if(targetBitmap !== null)
            {
                targetBitmap.bitmapData = clone;
            }

            return clone;
        }

        public function calculateSliderValueFromMouseX(mousex:Number, minx:Number, maxx:Number, minvalue:Number, maxvalue:Number, cursor:DisplayObject):Number
        {
            if (mousex < minx)
            {
                mousex = minx;
            }
            else if (mousex > maxx)
            {
                mousex = maxx;
            }

            const per:Number = (mousex - minx) / (maxx - minx);
            const value:Number = minvalue + (maxvalue - minvalue) * per;

            if (cursor !== null)
            {
                cursor.x = mousex;
            }

            return value;
        }

        public function startDragInteraction(onDragStart:Function, onMouseMove:Function, onMouseUp:Function):void
        {
            // TODO: 슬라이더 메뉴관련은 이 함수로 대체해야함
            isMouseDragging = true;

            function onmouseUp(e:MouseEvent):void
            {
                isMouseDragging = false;
                stage.removeEventListener(MouseEvent.MOUSE_UP, onmouseUp);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseDown);
                
                onMouseUp();
            }

            function onMouseDown(e:MouseEvent):void
            {
                onMouseMove();
            }

            onDragStart();

            stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseDown);
            stage.addEventListener(MouseEvent.MOUSE_UP, onmouseUp);
        }

        public function isPopUpWindowOpened():Boolean
        {
            return topBar.gridButtonWrapper.visible || numPadBox.visible || loadMenuBox.visible || aboutBox.visible;
        }

        public function getFilteredPos(mx:Number, my:Number):Point
        {
            mx = Math.round(mx * 100) / 100;
            my = Math.round(my * 100) / 100;

            if (isSharpLineON)
            {
                my = Math.floor(my);
                mx = Math.floor(mx);
            }
            else if (penSmoothSlideValue === 0 && (canvasAnchorPoint.rotation % 90 === 0))
            {
                my = Math.round(my);
                mx = Math.round(mx);
            }

            return new Point(mx, my);
        }

        public function showPickColorScratchPad():void
        {
            pickColor(colorPickerBox.scratchPad.pickColor());
        }

        public function hideStampFontList():void
        {
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownShowStampFontList);
            captureStampFontListBox.visible = false;
        }

        public function onMouseDownShowStampFontList(e:MouseEvent):void
        {
            if (!(captureStampFontListBox.hitTestPoint(stage.mouseX, stage.mouseY) || topBar.capStampFont.hitTestPoint(stage.mouseX, stage.mouseY)))
            {
                hideStampFontList();
            }
        }

        public function showStampFontList():void
        {
            if (!captureStampFontListBox.visible)
            {
                const gp:Point = topBar.capStampFont.localToGlobal(new Point(0, 0));

                captureStampFontListBox.x = gp.x;
                captureStampFontListBox.y = topBar.BARSIZE * topBar.scaleX;
                captureStampFontListBox.updateSystemFontList();
                captureStampFontListBox.setScale(Global.getUIScale());
                setAsTopChild(captureStampFontListBox);
                captureStampFontListBox.visible = true;

                stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownShowStampFontList, false, -1);
            }
        }

        public function disableTransparentBGDrawMode():void
        {
            if (!canvasPanel.getChildByName("canvasFlash"))
            {
                return;
            }

            addTimerByName("viewTransBGTimer", 0.0, true, function():Boolean
                {
                    if (canvasFlashEffect.alpha < 0.0)
                    {
                        canvasFlashEffect.alpha = 0.0;
                        canvasFlashEffect.visible = false;
                        canvasFlashEffect.graphics.clear();
                        if (canvasPanel.getChildByName("canvasFlash"))
                        {
                            canvasPanel.removeChild(canvasFlashEffect);
                        }
                        return false;
                    }

                    canvasFlashEffect.alpha -= 0.15;
                    return true;
                });
        }

        public function enableTransparentBGDrawMode():void
        {
            if (!canvasPanel.getChildByName("canvasFlash"))
            {
                canvasPanel.addChild(canvasFlashEffect);
                canvasPanel.setChildIndex(canvasFlashEffect, 0);
                canvasFlashEffect.visible = true;
                canvasFlashEffect.graphics.beginBitmapFill(capTransparentBGBMPD);
                canvasFlashEffect.graphics.drawRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
                canvasFlashEffect.graphics.endFill();
                canvasFlashEffect.alpha = 0.0;
            }

            if (canvasFlashEffect.alpha >= 1.0)
            {
                return;
            }

            addTimerByName("viewTransBGTimer", 0.0, true, function ():Boolean
                {
                    if (canvasFlashEffect.alpha >= 1.0)
                    {
                        canvasFlashEffect.alpha = 1.0;
                        return false;
                    }

                    canvasFlashEffect.alpha += 0.15;
                    return true;
                });
        }

        public function executeCaptureFlashEffect():void
        {
            if (captureAreaManager.isFullImageCapture())
            {
                if (isReplayModeON)
                {
                    applyCanvasFlashEffect(rCanvasPanel, 0, 0, RCANVAS_WIDTH, RCANVAS_HEIGHT);
                }
                else
                {
                    applyCanvasFlashEffect(canvasPanel, 0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
                }
            }
            else
            {
                const nowCaptureArea:Rectangle = captureAreaManager.getCaptureArea();
                applyCanvasFlashEffect((isReplayModeON) ? rCanvasPanel : canvasPanel, nowCaptureArea.x, nowCaptureArea.y, nowCaptureArea.width, nowCaptureArea.height);
            }
        }

        public function applyCanvasFlashEffect(parent:DisplayObjectContainer, ox:Number, oy:Number, width:Number, height:Number):void
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

            addTimerByName("flashingTimer", 0.0, true, function ():Boolean
                {
                    if (canvasFlashEffect.alpha < 0.1)
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
                    canvasFlashEffect.alpha -= 0.13;
                    return true;
                });
        }

        public function updatePickerBoxTransBGBrightness():void
        {
            colorPickerBox.applyTransparentColorBrightness(Global.getUIColorIndex());
            updateMyPaletteList();
            updateHistoryList();
            if (isTransparentPenColor)
            {
                colorPickerBox.setRGBInfoBackgroundTransparent(myPalettePresetType);
            }
        }

        public function startScratchPadResetTimer(target:DisplayObject):void
        {
            addTimerByName("clearScratchPadTimer", 0.4, false, function():void
                {
                    startPressHoldKey(target, "Clearing scratch pad..", null, colorPickerBox.scratchPad.clearPad, null);
                });
        }

        public function selectOrResetMyPalette():void
        {
            function onMouseUpMyPalette(e:MouseEvent):void
            {
                removeTimer("selectMyPaletteDelayTimer");
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpMyPalette);

                if (e.target && e.target.name === "myPaletteButton")
                {
                    if (myPalettePresetType === 0)
                    {
                        if (isMyPaletteExpended === false)
                        {
                            switchMyPaletteToExpended();
                        }
                        else
                        {
                            switchMyPaletteToCompact();
                        }
                    }
                    else
                    {
                        activeColorPreset(0);
                    }
                }
            }
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpMyPalette);

            addTimerByName("selectMyPaletteDelayTimer", 0.4, false, function():void
                {
                    startPressHoldKey(colorPickerBox.myPaletteButton, "Clearing my palette..", null, clearMyPaletteList, null);
                    stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpMyPalette);
                });
        }

        public function startSelectOrAddColorMyPalette():void
        {
            const firstClickColorIndex:uint = getMyPaletteIndexByMousePos();
            var colorAddedFlag:Boolean = false;

            function onMyPaletteMouseUp(e:MouseEvent):void
            {
                removeTimer("addColorMyPaletteDelayTimer");
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMyPaletteMouseUp);
                if (colorAddedFlag === false)
                {
                    selectMyPaletteColor();
                }
            }
            stage.addEventListener(MouseEvent.MOUSE_UP, onMyPaletteMouseUp);

            addTimerByName("addColorMyPaletteDelayTimer", 0.6, true, function():Boolean
                {
                    if (firstClickColorIndex === getMyPaletteIndexByMousePos())
                    {
                        colorAddedFlag = true;
                        addColorToMyPalette(colorPickerBox.getRGBInfoBGColor(), getMyPaletteIndexByMousePos());
                    }
                    else
                    {
                        return false;
                    }
                    return true;
                });
        }

        public function isMouseCursorInSideBar():Boolean
        {
            if (sideBar.visible === true)
            {
                const scale:Number = Global.getUIScale();

                if (isRightSidebar
                        && stage.mouseX >= sideBar.x - sideBarScrollBar.width * scale
                        && stage.mouseX <= sideBar.x + sideBar.WIDTH * scale
                        && stage.mouseY >= sideBar.y
                        && stage.mouseY <= stage.stageHeight)
                {
                    return true;
                }
                else if (  stage.mouseX >= sideBar.x
                        && stage.mouseX <= sideBar.x + sideBar.WIDTH * scale + sideBarScrollBar.width * scale
                        && stage.mouseY >= sideBar.y
                        && stage.mouseY <= stage.stageHeight)
                {
                    return true;
                }
            }

            return false;
        }

        public function onMouseWheelStage(e:MouseEvent):void
        {
            if (isMouseClicked || isRightMouseClicked || isMouseDragging
                || isPopUpWindowOpened()
                || isCaptureModeON || !isQuickSidebarActive && isKeyPressed() || getCommandKey() !== 0)
                return;

            if (!hasTimer("wheelZoomTimer"))
            {
                addTimerByName("wheelZoomTimer", 0.07, false, function():void
                    {
                        if (isMouseCursorInSideBar())
                        {
                            if (sideBarScrollBar.visible === true)
                            {
                                if (e.delta > 0)
                                {
                                    startScrollSidebarByMouseWheel(40);
                                }
                                else
                                {
                                    startScrollSidebarByMouseWheel(-40);
                                }
                            }
                        }
                        else if (isCursorInDrawArea())
                        {
                            if (e.delta > 0)
                            {
                                zoomInCanvas(true, isReplayModeON);
                                if (!isReplayModeON)
                                {
                                    showMouseHintTemp(Math.floor(canvasZoomMultipler * 100) + "%");
                                }
                            }
                            else
                            {
                                zoomInCanvas(false, isReplayModeON);
                                if (!isReplayModeON)
                                {
                                    showMouseHintTemp(Math.floor(canvasZoomMultipler * 100) + "%");
                                }
                            }
                        }
                    });
            }
        }

        public function rgbInfoNumPadIncKey(inc:int):void
        {
            if (isHSVInfoTextMode)
            {
                adjustSingleValueHSV(inc);
                numPadBox.updateOkBaseColor(colorPickerBox.getRGBInfoBGColor());
            }
            else
            {
                adjustSingleValueRGB(inc);
                numPadBox.updateOkBaseColor(colorPickerBox.getRGBInfoBGColor());
            }
        }

        public function pressNumpadKey(num:String):void
        {
            var startIndex:int = colorPickerBox.rgbInfoText.selectionBeginIndex;
            var endIndex:int = colorPickerBox.rgbInfoText.selectionEndIndex;

            if(numpadInputBuffer.length >= 3)
            {
                stage.focus = null;
                return;
            }

            numpadInputBuffer += num;

            var value:int = parseInt(numpadInputBuffer);

            if(isHSVInfoTextMode)
            {
                if(lastRGBInfoColorPartIndex === 0)
                {
                    if(value > 360)
                    {
                        value = 360;
                    }
                    hsvColorData[lastRGBInfoColorPartIndex] = value/360;
                }
                else
                {
                    if(value > 100)
                    {
                        value = 100;
                    }
                    hsvColorData[lastRGBInfoColorPartIndex] = value/100;
                }
            }
            else 
            {
                if(value > 255)
                {
                    value = 255;
                }

                const arr:Array = getColorValueFromRGBInfoText();
                arr[lastRGBInfoColorPartIndex] = value;
                
                const hsv:Vector.<Number> = Global.HEXtoHSV(Global.RGBtoHEX(arr[0],arr[1],arr[2]),hsvColorData[0]);
                hsvColorData[0] = hsv[0];   
                hsvColorData[1] = hsv[1];
                hsvColorData[2] = hsv[2];
            }

            updateColorPickerCursorPosAndRGBInfo(hsvColorData);
            numPadBox.updateOkBaseColor(Global.HSVtoHEX(hsvColorData[0],hsvColorData[1],hsvColorData[2]));
            keepRGBInfoTextPartFocus();

            if (colorPickerBox.getRGBInfoBGColor() !== colorPickerBox.getCurrentColor())
            {
                applyAdjustedColor();
            }
        }

        public function getSidebarConstHeight():Number
        {
            return (sideBarConstHeight + ((isMyPaletteExpended && myPalettePresetType === 0) ? myPaletteColorHeight * 7 : 0));
        }

        public function startPressHoldKey(button:DisplayObject, hintStr:String, readyFunc:Function, okFunc:Function, cancelFunc:Function):void
        {
            if (!hasTimer("pressholdtimer"))
            {
                var keyBufferLenSave:uint = getPressedKeyCount();
                var mouseClickONSave:Boolean = isMouseClicked;
                var rightMouseClickONSave:Boolean = isRightMouseClicked;

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
                    hideMouseHint();
                }

                if (hintStr !== "")
                {
                    showMouseHint(hintStr +" "+ pressHoldCountDownTime);
                }

                addTimerByName("pressholdtimer", 0.0, true, function():Boolean
                    {
                        if (isMouseClicked !== mouseClickONSave
                                || isRightMouseClicked !== rightMouseClickONSave
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

                        showMouseHint(hintStr +" "+ pressHoldCountDownTime);

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

        public function closeLoadMenuBox():void
        {
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownLoadMenuBox);
            loadMenuBox.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLoadMenuBox);
            loadMenuBox.visible = false;
        }

        public function openLoadMenuBoxOnClosing():void
        {
            if(loadMenuBox.visible === false)
            {
                const bmpd:BitmapData = getMergedBitmapdtata(false,true,true,null);
                loadMenuBox.setPreviewImage(bmpd);
                loadMenuBox.showPleaseWait("Closing fofo paint...");
                loadMenuBox.updateClickBlockerSize(stage.stageWidth,stage.stageHeight);
                setAsTopChild(loadMenuBox);
                loadMenuBox.visible = true;
            }
        }

        public function openLoadMenuBox():void
        {
            if(loadMenuBox.visible === false)
            {
                stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownLoadMenuBox);
                loadMenuBox.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLoadMenuBox);
                loadMenuBox.visible = true;
            }
            loadMenuBox.updateClickBlockerSize(stage.stageWidth,stage.stageHeight);
            setAsTopChild(loadMenuBox);
        }

        public function getJumpImageFolder():File
        {
            return File.applicationStorageDirectory.resolvePath("imagecache");
        }

        public function initializeRepTempFile():void
        {
            repFileTemp = File.applicationStorageDirectory.resolvePath("tmp\\tmp_" + getRandomString(32));
        }

        public function executeLoadMenuBoxClick(oldTargetName:String):void
        {
            loadMenuBox.addEventListener(MouseEvent.MOUSE_UP, onMouseUpLoadMenuBox);

            function onMouseUpLoadMenuBox(e:MouseEvent):void
            {
                loadMenuBox.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpLoadMenuBox);

                if (!e.target || e.target.alpha < 1.0)
                {
                    return;
                }

                if (oldTargetName === e.target.name
                && isLoadPendingAfterSaving === false && isSaveInProgress === 0 && !isFileBrowserOpened)
                {
                    switch (e.target.name)
                    {
                        case "dragDropLoadButton":
                            {
                                if (!loadMenuBox.isRefLayerLoadMode())
                                {
                                    closeLoadMenuBox();
                                    loadFileTo("canvas");
                                }
                            }
                        break;

                        case "dragDropSaveAndLoadButton":
                            {
                                if (!loadMenuBox.isRefLayerLoadMode())
                                {
                                    isLoadPendingAfterSaving = true;
                                    loadMenuBox.showPleaseWait("Saving in progress...");
                                    openSaveFileBrowser(false);
                                }
                            }
                        break;

                        case "dragDropLoadRefLayerButton":
                            {
                                loadFileTo("reflayer");
                                closeLoadMenuBox();
                            }
                        break;

                        case "dragDropCancelButton":
                            {
                                closeLoadMenuBox();
                            }
                        break;
                    }
                }
            }
        }

        public function onMouseDownLoadMenuBox(e:MouseEvent):void
        {
            if (!e.target)
            {
                return;
            }
            executeLoadMenuBoxClick(e.target.name);
        }

        public function showLoadFaildMouseHint():void
        {
            isLoadPendingAfterSaving = false;
            showMouseHintTemp("Load failed");
            mouseHint.y = stage.mouseY;
            mouseHint.x = stage.mouseX;
        }

        public function activeColorPreset(type:int):void
        {
            if (myPalettePresetType === type)
            {
                return;
            }
            var myPalettePresetTypeSave:int = myPalettePresetType;
            myPalettePresetType = type;
            updateMyPaletteList();
            colorPickerBox.setActiveColorPreset(type);
            if (isColorPickerModeBG)
            {
                switchColorPickerModePen();
            }

            if (type === 1) // drawr
            {
                myPaletteSaveColorBeforeOtherType[myPalettePresetTypeSave] = colorPickerBox.getRGBInfoBGColor();
                pickColor(myPaletteSaveColorBeforeOtherType[1]);
            }
            else if (type === 2) // tegaki
            {
                myPaletteSaveColorBeforeOtherType[myPalettePresetTypeSave] = colorPickerBox.getRGBInfoBGColor();
                pickColor(myPaletteSaveColorBeforeOtherType[2]);
            }
            else
            {
                myPaletteSaveColorBeforeOtherType[myPalettePresetTypeSave] = colorPickerBox.getRGBInfoBGColor();
                pickColor(myPaletteSaveColorBeforeOtherType[0]);
            }

            checkFOFOPosition();
        }

        public function setFileBrowserIsOpen(flag:Boolean):void
        {
            isFileBrowserOpened = flag;
            clearKeyBuffer();
        }

        public function setRcursorRotation(newAngle:Number):void
        {
            rReplayFOFOCursor.rotation = -newAngle;
        }

        public function formatBytes(bytes:Number):String
        {
            var sizes:Array = ["Bytes", "KB", "MB", "GB", "TB"];

            // 음수 또는 유효하지 않은 입력 처리
            if (isNaN(bytes) || bytes < 0)
                return "Invalid";
            if (bytes == 0)
                return "0 Byte";

            // 단위 계산 (최대 TB까지 제한)
            var i:int = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), sizes.length - 1);

            // 값 변환 및 소수점 첫째 자리 반올림
            var value:Number = bytes / Math.pow(1024, i);
            return Math.round(10 * value) / 10 + " " + sizes[i];
        }

        public function getDriveUsageString():String
        {
            function getDirectorySize(dir:File):Number
            {
                var size:Number = 0;

                if (dir.isDirectory)
                {
                    var files:Array = dir.getDirectoryListing();

                    for each (var file:File in files)
                    {
                        if (file.isDirectory)
                        {
                            size += getDirectorySize(file);
                        }
                        else
                        {
                            size += file.size;
                        }
                    }
                }

                return size;
            }

            return formatBytes(getDirectorySize(File.applicationStorageDirectory));
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
            const len:uint = penSizeList.length;
            for (var i:uint = 1; i < len; i++)
            {
                if (penSizeList[i] === size)
                {
                    return size + airBrushClipRectOffsetData[i];
                }
            }
            return 0;
        }

        public function resetRCanvasDrawLayerCliprect2():void
        {
            rCanvasDrawLayerClipRect.x = 0;
            rCanvasDrawLayerClipRect.y = 0;
            rCanvasDrawLayerClipRect.width = 0;
            rCanvasDrawLayerClipRect.height = 0;
        }

        public function extandRCanvasDrawLayerCliprect2():void
        {
            var rairBrushOffset:Number = (rAirBrushSize2 > 0) ? getClipRectOffsetAirBrush(rAirBrushSize2) : 1;

            rCanvasDrawLayerClipRect.x -= rairBrushOffset;
            rCanvasDrawLayerClipRect.y -= rairBrushOffset;
            rCanvasDrawLayerClipRect.width += (rairBrushOffset * 2);
            rCanvasDrawLayerClipRect.height += (rairBrushOffset * 2);
        }

        public function updateRCanvasDrawLayerCliprect2():void
        {
            rCanvasDrawLayerClipRect = rCanvasDrawLayerClipRect.union(rCanvasDrawShape.getBounds(rCanvasPanel));
        }

        public function extandRCanvasDrawLayerCliprect():void
        {
            var rairBrushOffset:Number = (rAirBrushSize > 0) ? getClipRectOffsetAirBrush(rAirBrushSize) : 1;

            rCanvasDrawLayerClipRectLegacy.x -= rairBrushOffset;
            rCanvasDrawLayerClipRectLegacy.y -= rairBrushOffset;
            rCanvasDrawLayerClipRectLegacy.width += (rairBrushOffset * 2);
            rCanvasDrawLayerClipRectLegacy.height += (rairBrushOffset * 2);
        }

        public function resetRCanvasDrawLayerCliprect():void
        {
            rCanvasDrawLayerClipRectLegacy.x = 0;
            rCanvasDrawLayerClipRectLegacy.y = 0;
            rCanvasDrawLayerClipRectLegacy.width = 0;
            rCanvasDrawLayerClipRectLegacy.height = 0;
        }

        public function updateRCanvasDrawLayerCliprect():void
        {
            rCanvasDrawLayerClipRectLegacy = rCanvasDrawLayerClipRectLegacy.union(rCanvasDrawShape.getBounds(rCanvasPanel));
        }

        public function resetCanvasDrawLayerCliprect():void
        {
            canvasDrawLayerClipRect.x = 0;
            canvasDrawLayerClipRect.y = 0;
            canvasDrawLayerClipRect.width = 0;
            canvasDrawLayerClipRect.height = 0;
        }

        public function extandCanvasDrawLayerCliprect():void
        {
            var airBrushOffset:Number = (airBrushSizeDrawMode > 0) ? getClipRectOffsetAirBrush(airBrushSizeDrawMode) : 1;

            canvasDrawLayerClipRect.x -= airBrushOffset;
            canvasDrawLayerClipRect.y -= airBrushOffset;
            canvasDrawLayerClipRect.width += (airBrushOffset * 2);
            canvasDrawLayerClipRect.height += (airBrushOffset * 2);
        }

        public function updateCanvasDrawLayerCliprect():void
        {
            canvasDrawLayerClipRect = canvasDrawLayerClipRect.union(canvasDrawLayerChild.getBounds(canvasPanel));
        }

        public function normalizeAlphaValue(alp:Number):Number
        {
            // 객체의 alpha값이 8비트int로 변환된후 다시 Number로 변환되기 때문에 실제 소수점 비교를 할때도 같은 방식을 써주어야함
            return Math.round(alp * 256) / 256;
        }

        public function getCanvasLayerSwappedHintString():String
        {
            return "Layers has been swapped " + ((isLayerSwapped) ? "1 / 2" : "2 / 1");
        }

        public function createPosUpdateFunctionByMouseDrag(target:DisplayObject, targetAngle:Number, customScaleX:Number = 1.0, customScaleY:Number = 1.0):Function
        {
            var oldX:Number = target.x;
            var oldY:Number = target.y;
            var mx:Number = stage.mouseX;
            var my:Number = stage.mouseY;
            const zoom:Number = canvasZoomMultipler;
            const angle:Number = targetAngle;

            return function():Point
            {
                const dx:Number = stage.mouseX - mx;
                const dy:Number = stage.mouseY - my;
                const newPos:Point = rotatePoint(dx, dy, angle);

                newPos.setTo(oldX + newPos.x / zoom / customScaleX, oldY + newPos.y / zoom / customScaleY);

                return newPos;
            };

        }

        public function hideCanvasRotateCursor():void
        {
            canvasRotateCursor.visible = false;
        }

        public function createAngleUpdateFunctionByMouseDrag(target:DisplayObject):Function
        {
            const snapThreshold:Number = 82;
            canvasRotateCursor.x = stage.mouseX;
            canvasRotateCursor.y = stage.mouseY + (65 * Global.getUIScale());
            canvasRotateCursor.rotateArrow.rotation = target.rotation;
            setAsTopChild(canvasRotateCursor);
            canvasRotateCursor.visible = true;

            const toDeg:Number = 180.0 / Math.PI;
            // 움직인 각도합 로테이트 캔버스 마지막각도를 넣어줌 rad로 변환

            var sumAng:Number = target.rotation;
            // 각도 차이 구하기 위해서 넣어줌, 초기 값은 마우스 클릭한 위치의 각도값
            var lastAng:Number = Math.atan2(stage.mouseX - canvasRotateCursor.x, stage.mouseY - canvasRotateCursor.y) * toDeg;
            var activateSnapFlag:Boolean = false;
            var ignoreSnapFlag:Boolean = true;
            var snappedAng:Number = 0;

            return function():Number
            {
                const nowAng:Number = Math.atan2(stage.mouseX - canvasRotateCursor.x, stage.mouseY - canvasRotateCursor.y) * toDeg;
                const subAng:Number = lastAng - nowAng;

                lastAng = nowAng;
                sumAng += subAng;
                var deg:Number = sumAng;
                const snap90:Number = Math.abs(deg % 90.0); // 90도 스냅 변수
                const snap90N:Number = 90.0 - snap90;
                const snapAng:Number = (snap90 > snap90N) ? snap90 : snap90N;

                if (snapAng > snapThreshold && ignoreSnapFlag === false)
                {
                    activateSnapFlag = true;
                    deg = Math.round(deg / 90) * 90;
                    if (snappedAng !== deg)
                    {
                        snappedAng = deg;
                    }
                }
                else if (activateSnapFlag === true)
                {
                    sumAng = snappedAng;
                    deg = snappedAng;
                    activateSnapFlag = false;
                    ignoreSnapFlag = true;
                }
                else if (ignoreSnapFlag === true)
                {
                    if (snapAng <= snapThreshold)
                    {
                        ignoreSnapFlag = false;
                    }
                }

                canvasRotateCursor.rotateArrow.rotation = deg;
                return Math.round(deg);
            };

        }

        public function getImageScaleHint(width:Number, height:Number, scale:Number, scaleXFlag:Boolean):String
        {
            if (scaleXFlag)
            {
                return Math.round(width * scale) + " x " + Math.round(height * scale) + " (" + scale.toFixed(2) + ")";
            }
            return Math.round(width) + " x " + Math.round(height) + " (" + scale.toFixed(2) + ")";
        }

        public function createScaleUpdaterFromMouseDrag(sc:Number):Function
        {
            var clickX:Number = stage.mouseX;
            var clickY:Number = stage.mouseY;
            var scale:Number = Math.abs(sc);
            var mxLastPos:Number;
            var myLastPos:Number;
            var moveFlag:int;

            return function(mx:Number, my:Number):Number
            {
                if (moveFlag != 0)
                {
                    if (moveFlag === 1)
                    {
                        const subX:Number = mx - mxLastPos;

                        if (subX !== 0) // 차이가 0이 될때가 있어서 이건 스킵
                        {
                            scale *= Math.pow(2, subX * 0.008);
                            refLayerMenuDragXMoveSum += subX;
                        }
                    }
                    else if (moveFlag === 2)
                    {
                        const subY:Number = myLastPos - my;

                        if (subY !== 0)
                        {
                            scale *= Math.pow(2, subY * 0.008);
                            refLayerMenuDragXMoveSum += subY;
                        }
                    }
                }
                else if (moveFlag === 0)
                {
                    if (Math.abs(mx - clickX) > 5)
                    {
                        moveFlag = 1;
                    }
                    else if (Math.abs(my - clickY) > 5)
                    {
                        moveFlag = 2;
                    }
                }

                mxLastPos = mx;
                myLastPos = my;

                if (scale > 100)
                    scale = 100;
                else if (scale < 0.1)
                    scale = 0.1;

                return scale;
            };

        }
    
        public function getCurrentColorHint():String
        {
            const pickedColor:uint = colorPickerBox.getRGBInfoBGColor();
            const arr:Vector.<Number> = (isHSVInfoTextMode) ? Global.HEXtoHSV(pickedColor,hsvColorData[0]) : Global.HEXtoRGB(pickedColor);
            const mode:String = (isHSVInfoTextMode) ? "HSV" : "RGB";

            return "Current color : " + mode +" " + arr[0] + "," + arr[1] + "," + arr[2];
        }

        public function isHintUnavailable():Boolean
        {
            return isMouseClicked || isRightMouseClicked || isMouseDragging || isToolBox2Showing || isFillPenStarted
                || isLassoToolStarted || numPadBox.visible || isAboutBoxOpened || rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_PROCESSING;
        }

        public function playLayerSwapEffect(target:DisplayObject):void
        {
            target.alpha = Global.OFFALPHA;

            addTimerByName("layerSwapFlickEffect", 0.5, false, function():void
            {
                target.alpha = 1.0;
            });
        }

        // 123,123,123에서 커서가 어느 지점이 있는지 반환함 0=R, 1=G, 2=B
        public function getRGBInfoTextCursorPos(customIndex:* = null):int
        {
            if(customIndex === null)
            {
                customIndex = colorPickerBox.rgbInfoText.caretIndex;
            }

            const textBeforeCursor:String = colorPickerBox.getRGBInfoText().substring(0, customIndex);
            const rgb:Array = textBeforeCursor.split(",");
            return rgb.length - 1;
        }

        public function keepRGBInfoTextPartFocus():void
        {
            addTimerByName("keepRGBInfoTextPartFocusTimer",0.0,false,function():void
            {
                stage.focus = colorPickerBox.rgbInfoText;
                selectRGBInfoTextByIndex(lastRGBInfoColorPartIndex);
            })
        }

        // index 값에 해당하는 RGB 텍스트 영역을 선택함
        public function selectRGBInfoTextByIndex(index:int):void
        {
            if (index < 0 || index > 2)
            {
                return;
            }


            var start:int;
            var end:int;

            if (index === 0)
            {
                start = 4;
                end = colorPickerBox.getRGBInfoText().indexOf(",");
            }
            else if (index === 1)
            {
                start = colorPickerBox.getRGBInfoText().indexOf(",") + 1;
                end = colorPickerBox.getRGBInfoText().lastIndexOf(",");
            }
            else if (index === 2)
            {
                start = colorPickerBox.getRGBInfoText().lastIndexOf(",") + 1;
                end = colorPickerBox.getRGBInfoText().length;
            }

            colorPickerBox.rgbInfoText.setSelection(start,end);
            lastRGBInfoColorPartIndex = index;
        }

        public function getColorValueFromRGBInfoText():Array
        {
            var rgbText:String = colorPickerBox.getRGBInfoText().slice(4); // "RGB"와 공백 제거
            var rgb:Array = rgbText.split(","); // 쉼표로 숫자를 나눔

            return rgb;
        }

        public function adjustSingleValueHSV(inc:int):void
        {
            const index:int = lastRGBInfoColorPartIndex;
            const hsv:Array = getColorValueFromRGBInfoText();
            var num:int = int(hsv[lastRGBInfoColorPartIndex]);

            num += inc;

            if (num < 0)
            {
                num = 0;
            }

            if (index === 0)
            {
                if (num > 360)
                {
                    num = 360;
                }
            }
            else
            {
                if (num > 100)
                {
                    num = 100;
                }
            }

            hsv[index] = Number(num);
            hsv[0] = hsv[0]/360;
            hsv[1] = hsv[1]/100;
            hsv[2] = hsv[2]/100;

            const hsvvec:Vector.<Number> = new <Number>[hsv[0],hsv[1],hsv[2]];

            updateColorPickerCursorPosAndRGBInfo(hsvvec);
            keepRGBInfoTextPartFocus();
        }

        public function adjustSingleValueRGB(inc:int):void
        {
            const index:int = lastRGBInfoColorPartIndex;
            const rgb:Array = getColorValueFromRGBInfoText();
            var num:int = int(rgb[index]);

            num += inc;
            if (num < 0)
            {
                num = 0;
            }
            else if (num > 255)
            {
                num = 255;
            }

            rgb[index] = Number(num);
            updateColorPickerCursorPosAndRGBInfo(Global.RGBtoHEX(rgb[0], rgb[1], rgb[2]));
            keepRGBInfoTextPartFocus();
        }

        public function getRgbInfoTextClickedPosIndex():int
        {
            return colorPickerBox.rgbInfoText.getCharIndexAtPoint(colorPickerBox.rgbInfoText.mouseX, 10);
        }

        public function openNumPad():void
        {
            if (numPadBox.visible === false)
            {
                numPadBox.readyLCHAdjustment(Global.HSVtoHEX(hsvColorData[0], 1.0, 1.0), colorPickerBox.getRGBInfoBGColor());
                const gp:Point = colorPickerBox.rgbInfoBG.localToGlobal(new Point(0, 0));
                numPadBox.x = Math.floor(gp.x);
                numPadBox.y = Math.floor(gp.y + colorPickerBox.rgbInfoBG.height * Global.getUIScale()+1);
                setAsTopChild(numPadBox);
                resetLastKey();
                stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownNumPad, false, -2);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownNumPad, false, -2);
            }
        }

        public function closeNumpad():void
        {
            if (colorPickerBox.getRGBInfoBGColor() !== colorPickerBox.getCurrentColor())
            {
                applyAdjustedColor();
            }
            numPadBox.off();
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownNumPad);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownNumPad);

            addTimerByName("rgbInfoTextFocusOutEventDelayInput", 0.0, false, function():void
            {
                addInputEventsDrawMode();
            });
        }

        public function checkNumPadMouseUp(oldTargetName:String):void
        {
            function onMouseUpNumpad(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpNumpad);

                if (oldTargetName === e.target.name)
                {
                    switch (e.target.name)
                    {
                        case "num0":
                        case "num1":
                        case "num2":
                        case "num3":
                        case "num4":
                        case "num5":
                        case "num6":
                        case "num7":
                        case "num8":
                        case "num9":
                        {
                            pressNumpadKey(e.target.name.charAt(3));
                        }
                        break;

                        case "numClip":
                        {
                            const color:* = numPadBox.getClipboardColor();
                            if (color as uint)
                            {
                                numPadBox.updateOkBaseColor(color);
                                updateColorPickerCursorPosAndRGBInfo(color);
                            }
                        }
                        break;
                    }
                }
            };

            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpNumpad);
        }

        public function onRightMouseDownNumPad(e:MouseEvent):void
        {
            closeNumpad();
        }

        public function onMouseDownNumPad(e:MouseEvent):void
        {
            if (!e.target)
            {
                return;
            }

            const targetName:String = e.target.name;
            if (!numPadBox.hitTestPoint(stage.mouseX, stage.mouseY) && !colorPickerBox.rgbInfoText.hitTestPoint(stage.mouseX, stage.mouseY))
            {
                if (numPadBox.visible)
                {
                    closeNumpad();
                }
                return;
            }

            //TODO : rgb info text 동작 수정해야함
            // 항목을 선택하고 numpad로 수정하고 나서 다시 이전항목선택시 전체 선택이 안되고 일부 선택만됨
            //RGB HSV와 숫자 사이를 더블 클릭하면 가장 뒤에 숫자 항목이 선택됨

            if (targetName === "numInc")
            {
                startKeyRepeat(true, rgbInfoNumPadIncKey, 1);
            }
            else if (targetName === "numDec")
            {
                startKeyRepeat(true, rgbInfoNumPadIncKey, -1);
            }
            else if (targetName === "okLWrapper")
            {
                startAdjustOKLCH(0);
            }
            else if (targetName === "okCWrapper")
            {
                startAdjustOKLCH(1);
            }
            else if (targetName === "okHWrapper")
            {
                startAdjustOKLCH(2);
            }
            else
            {
                checkNumPadMouseUp(targetName);
            }
        }

        public function startAdjustOKLCH(index:int):void
        {
            numPadBox.startAdjustLCH(index, function(pickedColor:uint):void
            {
                updateColorPickerCursorPosAndRGBInfo(pickedColor);
                if (colorPickerBox.getRGBInfoBGColor() !== colorPickerBox.getCurrentColor())
                {
                    applyAdjustedColor();
                }
            });
        }

        //hsv rgb로 왔다갔다함
        public function toggleRGBInfoTextColorType():void
        {
            const cursorPosSave:int = getRGBInfoTextCursorPos();

            if (isHSVInfoTextMode)
            {
                isHSVInfoTextMode = false;
                colorPickerBox.updateRGBInfoText("RGB",Global.HEXtoRGB(colorPickerBox.getRGBInfoBGColor()));
            }
            else
            {
                isHSVInfoTextMode = true;
                colorPickerBox.updateRGBInfoText("HSV",Global.HEXtoHSV(colorPickerBox.getRGBInfoBGColor(),hsvColorData[0]));
            }
        }

        public function applyAdjustedColor():void
        {
            const color:uint = colorPickerBox.getRGBInfoBGColor();

            if (isPenColorMode())
            {
                penColor = color;
                updateOpacityCursorPos(penAlphaIndex);
            }
            else if (isBackgroundColorMode())
            {
                updateCanvasBGColorDrawMode(color);
                if (isCanvasWindowON)
                {
                    updateCanvasWindowBGColor(CANVAS_BG_COLOR, canvasWindowLayer1Bitmap.bitmapData);
                }
                addUndoBGColorData(color);
            }
        }

        public function onMouseDownRGBInfoText(e:MouseEvent):void
        {
            var clickedPos:int = getRgbInfoTextClickedPosIndex();

            numpadInputBuffer = "";
            isTransparentPenColor = false;

            if(colorPickerBox.getRGBInfoText() === "")
            {
                colorPickerBox.restoreRGBInfoText();
            }

            if (clickedPos >= 0 && clickedPos <= 3)
            {
                toggleRGBInfoTextColorType();
            }
            else
            {
                selectRGBInfoTextColorPart(clickedPos);
                if(!numPadBox.visible)
                {
                    colorPickerBox.restoreRGBInfoBackground();
                    ensureDrawingToolSelected(false);
                    openNumPad();
                    addTimer(0.1,false,function():void
                    {
                        showBottomHint(STRING_CUSTOM_COLOR_HINT);
                    });
                }
            }
        }

        public function selectRGBInfoTextColorPart(clickedIndex:int):void
        {
            stage.focus = colorPickerBox.rgbInfoText;
            var clickedRGBPart:int = getRGBInfoTextCursorPos(clickedIndex);

            if (clickedIndex < 0)
            {
                //음수이면 가장 오른쪽 부분 클릭
                clickedRGBPart = 2;
            }

            selectRGBInfoTextByIndex(clickedRGBPart);
        }

        public function updateLastFilePathByRandomFileName():void
        {
            const newFileName:String = getRandomFileName();
            lastSaveFileName = newFileName;
            lastSaveFilePath = getDirectoryOnly(lastSaveFilePath)+File.separator+newFileName;
        }

        public function getReplayFileNameFromPath(path:String):String
        {
            return path.substr(0,path.lastIndexOf(".png"))+".2020";
        }

        public function getRandomFileName():String
        {
            return getTimeStampTailHead() + "_" + getRandomString(8) + ".png";
        }

        public function updateStageOffset():void
        {
            const scale:Number = Global.getUIScale();

            STAGE_TOP_OFFSET = (isReplayModeON) ? Math.round(topBar.BARSIZE * scale + replayTimelineBox.BARSIZE * scale) : Math.round(topBar.BARSIZE * scale);
            STAGE_BOTTOM_OFFSET = 0;
            STAGE_RIGHT_OFFSET = 0;
            STAGE_LEFT_OFFSET = 0;

            if (isCaptureModeON || isReplayModeON)
            {
                return;
            }

            if (sideBar.visible)
            {
                if (isRightSidebar)
                {
                    STAGE_RIGHT_OFFSET = Math.round(sideBar.getWidth());
                }
                else
                {
                    STAGE_LEFT_OFFSET = Math.round(sideBar.getWidth());
                }
            }
        }

        // 드로우 모드와 리플레이 모드 캔버스 미러가 다를경우 undo 적용 이후에 mirror커맨드 넣어주도록 함
        public function checkMirrorCanvasReplayMirror():void
        {
            if (isCanvasMirrored !== rMirrorON)
            {
                mirrorCommandReady = true;
                mirrorDraw();
                updateGridMirror(isCanvasMirrored);
                mirrorRCursorPos();
            }
            else if (mirrorCommandReady)
            {
                mirrorCommandReady = false;
            }
        }

        public function hideLassoMenuBoxTemp():void
        {
            lassoMenuBox.visible = true;
            isLassoMenuHiddenTemp = false;
            resetLastKey();
        }

        public function mirrorRCursorPos():void
        {
            const p:Point = drawReplayByCommand.getRCursorPos();
            const half:Number = CANVAS_WIDTH / 2;
            const curcorX:Number = rReplayFOFOCursor.x + (half - p.x) * 2;

            rReplayFOFOCursor.x = curcorX;
            drawReplayByCommand.setRCursorPos(curcorX, p.y);
        }

        public function startRCursorFadeOut():void
        {
            rReplayFOFOCursor.alpha = 1.0;
            rReplayFOFOCursor.visible = true;

            addTimerByName("rCursorOffAlphaAnimTimer", 0.0, true, function():Boolean
                {
                    if (rReplayFOFOCursor.visible === false)
                    {
                        return false;
                    }

                    rReplayFOFOCursor.alpha -= 0.1;

                    if (rReplayFOFOCursor.alpha < 0.0)
                    {
                        rReplayFOFOCursor.visible = false;
                        rReplayFOFOCursor.alpha = 1.0;

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
                    hideMouseHint();
                }
            }
            else
            {
                drawReplayByCommand.updateRCursorPos();
            }
        }

        public function checkCollisionFOFOAndSideBarScrollSet():int
        {
            const sideBarWidth:Number = sideBar.getWidth();
            const scale:Number = Global.getUIScale();
            const fofoHeight:Number = fofo.height - 10 * scale;
            const fofoTopRect:Rectangle = new Rectangle(sideBar.x, STAGE_TOP_OFFSET, sideBarWidth, fofoHeight);
            const fofoBottomRect:Rectangle = new Rectangle(sideBar.x, stage.stageHeight - STAGE_BOTTOM_OFFSET - fofoHeight, sideBarWidth, fofoHeight);
            const gp:Point = sideBarScrollPanel.localToGlobal(new Point(0, 0));
            const sideBarRect:Rectangle = new Rectangle(gp.x - sideBarScrollPanel.x * scale, gp.y, sideBar.getWidth(), getSidebarConstHeight() * scale);
            const collisionTop:Boolean = sideBarRect.intersects(fofoTopRect);
            const collisionBottom:Boolean = sideBarRect.intersects(fofoBottomRect);

            return (collisionTop && collisionBottom) ? 0 : (collisionBottom) ? 1 : (collisionTop) ? 2 : 3;
        }

        public function alignFOFOToSidebar():void
        {
            if (isRightSidebar)
            {
                fofo.setMirror(false);
                fofo.x = sideBar.x + sideBar.getWidth() - fofo.width;
            }
            else
            {
                fofo.setMirror(true);
                fofo.x = sideBar.x;
            }
        }
        
        public function checkFOFOPosition():void
        {
            if (!sideBar.visible)
            {
                fofo.visible = false;
                return;
            }

            const checkYPos:int = checkCollisionFOFOAndSideBarScrollSet();
            fofo.visible = sideBar.visible;

            switch (checkYPos)
            {
                case 3:
                    // 충돌 없음 그대로 둠
                    return;

                case 0:
                    // 위/아래 모두 충돌 숨김
                    fofo.visible = false;
                    break;

                case 1:
                    // 아래쪽 충돌
                    fofo.setTop(STAGE_TOP_OFFSET);
                    alignFOFOToSidebar();
                    fofo.visible = true;
                    break;

                case 2:
                    // 위쪽 충돌
                    alignFOFOToSidebar();
                    fofo.setBottom(stage.stageHeight - STAGE_BOTTOM_OFFSET);
                    fofo.visible = true;
                    break;
            }
        }

        public function updateCanvasWindowBGColor(color:uint, bmpd:BitmapData):void
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

        public function setCanvasWindowVisible(flag:Boolean):void
        {
            canvasWindow.visible = flag;
        }

        public function updateCanvasWindowBitmapSize():void
        {
            const bounds:Rectangle = canvasNavigatorBox.setFitBitmapforBox(canvasLayer1BitmapData.width,
                                                                            canvasLayer1BitmapData.height,
                                                                            canvasWindow.stage.stageWidth,
                                                                            canvasWindow.stage.stageHeight);
            updateCanvasWindowBGColor(CANVAS_BG_COLOR, canvasLayer1BitmapData);
            canvasWindowCanvasPanel.x = bounds.x;
            canvasWindowCanvasPanel.y = bounds.y;
            canvasWindowCanvasPanel.width = bounds.width;
            canvasWindowCanvasPanel.height = bounds.height;
        }

        public function updateCanvasWindowData():void
        {
            addTimerByName("canvasWindowUpdateDelayTimer", 0.2, false,
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

        public function onMoveCanvasWindow(e:Event):void
        {
            updateCanvasWindowData();
        }

        public function onResizeCanvasWindow(e:Event):void
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

        public function updateCanvasWindowImage():void
        {
            canvasWindowLayer1Bitmap.bitmapData = canvasNavigatorBox.navLayer1Bitmap.bitmapData;
            canvasWindowLayer2Bitmap.bitmapData = canvasNavigatorBox.navLayer2Bitmap.bitmapData;
            canvasWindowLayer1Bitmap.smoothing = true;
            canvasWindowLayer2Bitmap.smoothing = true;
        }

        public function copyMainWindowTitleToCanvasWindow():void
        {
            canvasWindow.title = stage.nativeWindow.title;
        }

        public function fitCanvasWindowSizeToImage():void
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

        public function onMouseDownCanvasWindow(e:MouseEvent):void
        {
            canvasWindow.startMove();
        }

        public function onRightMouseUpCanvasWindow(e:MouseEvent):void
        {
            if (canvasWindowCanvasPanel.width === canvasWindow.width
                    && canvasWindowCanvasPanel.height === canvasWindow.height)
            {
                return;
            }

            fitCanvasWindowSizeToImage();
        }

        public function closeCanvasWindow():void
        {
            canvasWindow.visible = false;
            isCanvasWindowON = false;
            if (!isReplayModeON && !isCaptureModeON)
            {
                topBar.newWindowButton.visible = true;
                topBar.newWindowCloseButton.visible = false;
            }
            stage.nativeWindow.activate();
        }

        public function onKeyDownCanvasWindow(e:KeyboardEvent):void
        {
            if (e.keyCode === KEY.esc)
            {
                closeCanvasWindow();
            }
        }

        public function onClosingCanvasWindow(e:Event):void
        {
            e.preventDefault();
            closeCanvasWindow();
        }

        public function initializeCanvasWindow():void
        {
            var windowOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
            windowOptions.systemChrome = NativeWindowSystemChrome.STANDARD;
            windowOptions.type = NativeWindowType.NORMAL;
            windowOptions.owner = stage.nativeWindow;
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

        public function onActivateCanvasWindow(e:Event):void
        {
            isCanvasWindowON = true;
            if (!isReplayModeON && !isCaptureModeON)
            {
                topBar.newWindowButton.visible = false;
                topBar.newWindowCloseButton.visible = true;
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

        public function openImageViewWindow():void
        {
            if (canvasWindow === null)
            {
                initializeCanvasWindow();
                if (canvasWindowInfo[0] === null)
                {
                    canvasWindowInfo[0] = stage.nativeWindow.x + topBar.newWindowButton.x - canvasWindowInfo[2] / 2;
                    canvasWindowInfo[1] = stage.nativeWindow.y;
                }
                canvasWindow.bounds = new Rectangle(canvasWindowInfo[0], canvasWindowInfo[1], canvasWindowInfo[2], canvasWindowInfo[3]);
            }

            canvasWindow.activate();
        }

        public function isLayer2SelectedReplayMode():Boolean
        {
            return rCanvasPanel.getChildIndex(rCanvasDrawLayer) < rCanvasPanel.getChildIndex(rCanvasLayer1Bitmap);
        }

        public function enableNewFileButton():void
        {
            if (!isSaveInProgress && topBar.newFileButton.alpha < 1.0)
            {
                topBar.newFileButton.alpha = 1.0;
            }
            if (toolOptionsBox.layerMergeButton.alpha < 1.0)
            {
                toolOptionsBox.layerMergeButton.alpha = 1.0;
            }

            markWindowTitleAsDirty();
        }

        public function isAllLayerInvisible():Boolean
        {
            if (!canvasLayer1Bitmap.visible && !canvasLayer2Bitmap.visible)
            {
                showMouseHintTemp("All layer locked");
                return true;
            }
            return false;
        }

        public function mergeLassoImageToRefLayer():void
        {
            if (isLassoImageCopied)
            {
                applyLassoBoxImageToCanvas(true);
                disposeLassoBoxBitmapData();
                resetLassoBox();
            }
            else
            {
                if (isDeepUndoEnabled)
                {
                    applyDeepUndo();
                }
                const lassoInfo:Array = applyLassoBoxImageToCanvas(true);
                const point1:Vector.<Number> = lassoTransformData[0].concat();
                const point2:Array = lassoTransformData[1].concat();

                var l1:Boolean = true;
                var l2:Boolean = true;

                if (checkedLayer === 1 || (canvasLayer1Bitmap.visible && !canvasLayer2Bitmap.visible))
                {
                    l1 = true;
                    l2 = false;
                }
                else if (checkedLayer === 2 || (!canvasLayer1Bitmap.visible && canvasLayer2Bitmap.visible))
                {
                    l1 = false;
                    l2 = true;
                }

                rDataBuffer.push(["lassodel2", point1, point2, lassoInfo, isLassoImageCopied, l1, l2]);
                undoManager.addNew();

                disposeLassoBoxBitmapData();
                resetLassoBox();
            }

            if (canvasRefLayer.visible === false || refLayerLastAlpha === 0.0)
            {
                updateRefLayerOpacityCursorPosByValue(0.5);
                refLayerLastAlpha = 0.5;
                canvasRefLayer.visible = true;
                canvasRefLayer.alpha = 0.5;
            }
            canvasRefLayerBitmap.smoothing = true;
        }

        public function mergeImageToRefLayer(layer1:IBitmapDrawable, layer2:IBitmapDrawable):void
        {
            var tmpbmpd:BitmapData = new BitmapData(CANVAS_WIDTH, CANVAS_HEIGHT, true, 0);
            const mat:Matrix = new Matrix();

            mat.scale(canvasRefLayer.scaleX, canvasRefLayer.scaleY);
            mat.rotate(canvasRefLayer.rotation * Math.PI / 180);
            mat.translate(CANVAS_WIDTH / 2, CANVAS_HEIGHT / 2);

            tmpbmpd.draw(canvasRefLayer, mat);

            if (layer2 !== null)
            {
                tmpbmpd.draw(layer2);
            }
            if (layer1 !== null)
            {
                tmpbmpd.draw(layer1);
            }

            canvasRefLayerBitmapData = updateBitmapData(canvasRefLayerBitmapData, tmpbmpd, canvasRefLayerBitmap);

            tmpbmpd.dispose();
            tmpbmpd = null;
        }

         public function toggleLayer1Check():void
        {
            if (toolOptionsBox.layer1CheckedButton.visible === false)
            {
                checkedLayer = 1;
                toolOptionsBox.layer1CheckedButton.visible = true;
                toolOptionsBox.layer1UncheckedButton.visible = false;
                toolOptionsBox.layer2CheckedButton.visible = false;
                toolOptionsBox.layer2UncheckedButton.visible = true;
                toolBox.setToolButtonsForCheckedLayerON();
                toolBox2.setToolButtonsForCheckedLayerON();
            }
            else
            {
                checkedLayer = 0;
                toolOptionsBox.layer1CheckedButton.visible = false;
                toolOptionsBox.layer1UncheckedButton.visible = true;
                toolBox.setToolButtonsForCheckedLayerOFF();
                toolBox2.setToolButtonsForCheckedLayerOFF();
            }
        }

        public function toggleLayer2Check():void
        {
            if (toolOptionsBox.layer2CheckedButton.visible === false)
            {
                checkedLayer = 2;
                toolOptionsBox.layer2CheckedButton.visible = true;
                toolOptionsBox.layer2UncheckedButton.visible = false;
                toolOptionsBox.layer1CheckedButton.visible = false;
                toolOptionsBox.layer1UncheckedButton.visible = true;
                toolBox.setToolButtonsForCheckedLayerON();
                toolBox2.setToolButtonsForCheckedLayerON();
            }
            else
            {
                checkedLayer = 0;
                toolOptionsBox.layer2CheckedButton.visible = false;
                toolOptionsBox.layer2UncheckedButton.visible = true;
                toolBox.setToolButtonsForCheckedLayerOFF();
                toolBox2.setToolButtonsForCheckedLayerOFF();
            }
        }

        public function toggleLayerCaptureMode(layer:int):void
        {
            topBar.capClipBoard.alpha = 1.0;

            const replayMode:Boolean = isReplayModeON;

            var bitmap:Bitmap = replayMode
                ? (layer == 1 ? rCanvasLayer1Bitmap : rCanvasLayer2Bitmap)
                : (layer == 1 ? canvasLayer1Bitmap : canvasLayer2Bitmap);

            var button:DisplayObject = (layer == 1)
                ? topBar.capLayer1VisibleButton
                : topBar.capLayer2VisibleButton;

            var otherButton:DisplayObject = (layer == 1)
                ? topBar.capLayer2VisibleButton
                : topBar.capLayer1VisibleButton;

            if (bitmap.visible)
            {
                bitmap.visible = false;
                button.alpha = Global.OFFALPHA;

                if (replayMode)
                {
                    if ((layer == 1 && !isLayer2SelectedReplayMode())
                    ||  (layer == 2 && isLayer2SelectedReplayMode()))
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

            captureAreaManager.updateDrawArea();
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
                    applyDeepUndo();
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
                for (var i:uint = 0; i < arr.length; i++)
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
                return;

            const index:int = undoDataIndex;

            if (rData[index].length === 1)
            {
                rData.splice(index);
                rDataFrame.splice(index);
            }
            else
            {
                const len:uint = rData[index].length;
                for (var i:uint = 0; i < len; i++)
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
            undoDataIndex = rData.length  ;
        }

        public function hasLastRDataCommand(command:String):Boolean
        {
            const index:int = undoDataIndex;

            if(rData.length > 0 && index >= 0)
            {
                const len:uint = rData[index].length;

                for(var i:uint=0; i<len; i++)
                {
                    if(command === rData[index][i][0])
                    {
                        return true;
                    }
                }
            }

            return false;
        }

        public function mergeImageIntoLayer2():void
        {
            if(hasLastRDataCommand("merge"))
            {
                deleteLastRDataCommand("merge");
            }
            else
            {
                if(isDeepUndoEnabled)
                {
                    applyDeepUndo();
                }

                canvasLayer2BitmapData.draw(canvasLayer1BitmapData);
                canvasLayer1BitmapData.fillRect(new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT),0);
                rDataBuffer.push(["merge"]);
                undoManager.addNew();
            }
            toolOptionsBox.layerMergeButton.alpha = Global.OFFALPHA;
        }

        public function swapLayer():void
        {
            if(toolOptionsBox.layerSwapButton.alpha < 1.0)
            {
                return;
            }

            if(isDeepUndoEnabled) applyDeepUndo();

            isLayerSwapped = !isLayerSwapped;

            var tempbmpd1:BitmapData = canvasLayer1BitmapData.clone();
            var tempbmpd11:BitmapData = canvasLayer2BitmapData.clone();
            const rect:Rectangle = new Rectangle(0,0,canvasLayer1BitmapData.width,canvasLayer1BitmapData.height);

            canvasLayer1BitmapData.fillRect(rect,0);
            canvasLayer2BitmapData.fillRect(rect,0);

            canvasLayer1BitmapData.draw(tempbmpd11);
            canvasLayer2BitmapData.draw(tempbmpd1);

            tempbmpd1.dispose();
            tempbmpd11.dispose();
            tempbmpd1 = null;
            tempbmpd11 = null;

            if(hasLastRDataCommand("swap"))
            {
                deleteLastRDataCommand("swap");
            }
            else
            {
                rDataBuffer.push(["swap"]);
                undoManager.addNew();
            }

            playLayerSwapEffect(toolOptionsBox.layerSwapButton);
        }

        public function getCaptrueImageBitmapdata(clipBoardCopyFlag:Boolean):BitmapData
        {
            const isReplayMode:Boolean = isReplayModeON;
            var rect:Rectangle = (!captureAreaManager.isFullImageCapture()) ? captureAreaManager.getCaptureArea() : null;
            var layer1:Boolean;
            var layer2:Boolean;

            if(isReplayMode)
            {
                layer1 = rCanvasLayer1Bitmap.visible;
                layer2 = rCanvasLayer2Bitmap.visible;
            }
            else
            {
                layer1 = canvasLayer1Bitmap.visible;
                layer2 = canvasLayer2Bitmap.visible;
            }

            const bmpd:BitmapData = getMergedBitmapdtata((isCaptureModeON && isCaptureTransparentBGShowing && !clipBoardCopyFlag) ? true : false,layer1,layer2,rect);
            const mat:Matrix = new Matrix();
            const deg:Number = 90*captureCanvasRotationStep;
            var swapWH:Boolean = false;
            mat.rotate(deg*Math.PI/180);

            if(deg === 90)
            {
                mat.translate(bmpd.height,0);
                swapWH = true;
            }
            else if (deg === -90 || deg == 270)
            {
                mat.translate(0,bmpd.width);
                swapWH = true;
            }
            else if (deg === 180)
            {
                mat.translate(bmpd.width, bmpd.height);
            }

            if(isCaptureCanvasFlipped)
            {
                if(swapWH)
                {
                    mat.scale(1,-1);
                    mat.translate(0,bmpd.width);
                }
                else
                {
                    mat.scale(-1,1);
                    mat.translate(bmpd.width,0);
                }
            }
            const tmpbmpd:BitmapData = (swapWH) ? new BitmapData(bmpd.height,bmpd.width,true,0)
                                                 :new BitmapData(bmpd.width,bmpd.height,true,0);

            tmpbmpd.draw(bmpd,mat);
            if(isCaptureStampEnabled && tmpbmpd.width >= 300)
            {
                captureStampManager.kungFinal(tmpbmpd);
            }
            bmpd.dispose();

            return tmpbmpd;
        }

        public function copyCaptureImageToCilpBoard():void
        {
            Clipboard.generalClipboard.setData(ClipboardFormats.BITMAP_FORMAT,getCaptrueImageBitmapdata(true),false);
            // showMouseHintTemp("The image copied to clipboard successfully");
            topBar.capClipBoard.alpha = Global.OFFALPHA;
        }

        public function applyUIScale():void
        {
        //todo:클래스 내부에서 global scale참조하도록 매개변수 없애기
            const scale:Number = Global.getUIScale();
            const stw:Number = stage.stageWidth;
            const sth:Number = stage.stageHeight;

            sideBar.setScale(scale);
            setSidebarDefaultPos();
            topBar.setScale(scale);
            topBar.updateTopbarBG(stw);
            topBar.updateTimerPos(stage.stageWidth);
            replayTimelineBox.setScale(scale);
            canvasRotateCursor.setScale(scale);
            mouseHint.setScale(scale);
            bottomBar.scaleX = scale;
            bottomBar.scaleY = scale;
            lassoMenuBox.setScale(scale);
            refLayerMenuBox.setScale(scale);
            fillPenBox.setScale(scale);
            toolBox2.setScale(scale);
            aboutBox.setScale(scale);
            eyedropperLens.setScale(scale);
            numPadBox.setScale(scale);
            updateStageOffset();
            updateScrollBarHeight();
            rReplayFOFOCursor.setScale(scale);
            fofo.setScale(scale);
            checkFOFOPosition();
            rFollowMouse.updateScale(scale);

            //이거 위에서 뭔가 해주고 난후에 여기서 해줘야함
            sideBar.y = Math.round(STAGE_TOP_OFFSET);
            sideBar.updateSideBGSize(getSideBarBGHeight());

            if(isLassoToolStarted) keepBoxInsideViewPort(lassoMenuBox);
            if(isRefLayerMenuON) keepBoxInsideViewPort(refLayerMenuBox);

            updateCanvasNaigatorCursor();
            hideBottomHint();
        }

        public function onMouseUpQuickSidebar(e:MouseEvent):void
        {
            deactivateQuickSidebar();
        }

        public function deactivateQuickSidebar():void
        {
            stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUpQuickSidebar);
            stage.removeEventListener(KeyboardEvent.KEY_UP,onKeyUpQuickSidebar);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,onMouseDownQuickSidebar);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownQuickSidebar);

            if(isSidebarVisible === false)
            {
                sideBar.visible = false;
            }

            setSidebarDefaultPos();
            isQuickSidebarActive = false;
            checkFOFOPosition();
            sideBar.resetBG();

            if(toolBox.getLastTool() === "toolEyedropper")
            {
                eyeDropperTool();
            }

            if(isRefLayerMenuON)
            {
                refLayerMenuBox.visible = true;
            }

            hideBottomHint();
            closeNumpad();
        }

        public function startDeactivteQuickSidebar():void
        {
            if(isMouseClicked && sideBar.hitTestPoint(stage.mouseX,stage.mouseY))
            {
                stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpQuickSidebar);
                return;
            }

            deactivateQuickSidebar();
        }

        public function onRightMouseDownQuickSidebar(e:MouseEvent):void
        {
            if(!e.target || numPadBox.visible || isPopUpWindowOpened())
            {
                return;
            }

            switch(e.target.name)
            {
                case "toolZoomIn":
                case "toolZoomOut":
                {
                    if(canvasZoomMultipler !== 1.0)
                    {
                        resetZoomDrawMode();
                    }
                }
                break;

                case "toolRotate":
                {
                    if(canvasAnchorPoint.rotation !== 0.0)
                    {
                        resetRotationDrawMode();
                    }
                }
                break;

                case "sideBarScrollBar":
                {
                    resetSideBarPosition();
                }
                break;;

                case "myPaletteBox":
                {
                    //이거 있어야됨
                }
                break;

                default:
                break;
            }

            startDeactivteQuickSidebar();
        }

        public function onMouseDownQuickSidebar(e:MouseEvent):void
        {
            if(e.target && e.target.name === "sideBarScrollBar") return;

            if(stage.mouseX < sideBar.x || stage.mouseX > sideBar.x+sideBar.getWidth()
            || stage.mouseY < sideBar.y)
            {
                startDeactivteQuickSidebar();
            }
        }

        public function onKeyUpQuickSidebar(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;
            if(keyCode === KEY.s || keyCode === KEY.d
            || keyCode === KEY.j || keyCode === KEY.k
            || keyCode === KEY.n6)
            {
                startDeactivteQuickSidebar();
            }
        }

        public function setSidebarDefaultPos():void
        {
            if(isRightSidebar)
            {
                sideBar.x = Math.round(stage.stageWidth-sideBar.getWidth());
            }
            else
            {
                sideBar.x = 0;
            }
        }

        public function activeQuickSideBar(shortcut:Boolean):void
        {
            isQuickSidebarActive = true;

            if(shortcut)
            {
                selectLastUsedTool();
                stage.addEventListener(KeyboardEvent.KEY_UP,onKeyUpQuickSidebar);
            }
            else
            {
                stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDownQuickSidebar,false,-2);
            }
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownQuickSidebar,false,-2);

            const sideBarWidth:Number = sideBar.getWidth();
            const scrollBarWidthLeft:Number = (isRightSidebar) ? sideBarScrollBar.width:0;
            const scrollBarWidthRight:Number = (!isRightSidebar) ? sideBarScrollBar.width:0;
            sideBar.x = mouseX-(sideBarWidth)/2+((isRightSidebar)? -18:22);

            if(sideBar.x - scrollBarWidthLeft < 0)
            {
                sideBar.x = scrollBarWidthLeft;
            }
            else if(sideBar.x + sideBarWidth + scrollBarWidthRight > stage.stageWidth)
            {
                sideBar.x = stage.stageWidth-(sideBarWidth+scrollBarWidthRight);
            }

            if(sideBar.visible === true && isSidebarVisible === false)
            {
                removeSidebarTempShowActivateEvents();
            }

            if(isRefLayerMenuON)
            {
                refLayerMenuBox.visible = false;
            }

            if(mouseHint.isShowing())
            {
                hideMouseHint();
            }

            sideBar.setTransparentBG();

            hideHintHighlightBox();
            sideBar.visible = true;
            checkFOFOPosition();
        }

        public function onFromWorker(e:Event):void
        {
            var msg:* = backToMain.receive();
            const command:String = msg as String;

            if(command === "encodePNGCaptureDone")
            {
                workerDataReceiveCount++;
                receivedCaptureImageQueueFromWorker.push(backToMain.receive(true));
            }
            else if(command === "encodePNGSaveDone")
            {
                workerDataReceiveCount++;
                receivedSaveImageDataFromWorker = backToMain.receive(true);
            }
            else if(command === "compress_ReplayDataDone")
            {
                workerDataReceiveCount++;
                writeReplayFile(backToMain.receive(true)
                                ,backToMain.receive(true)
                                ,backToMain.receive(true)
                                ,backToMain.receive(true)
                                ,backToMain.receive(true)
                                ,backToMain.receive(true)
                                );
            }
            else if(command === "compress_UndoDataDone")
            {
                workerDataReceiveCount++;
                receivedUndoImageQueueFromWorker.push([backToMain.receive(true),backToMain.receive(true)]);
            }

            if(!hasTimer("workerStopTimer"))
            {
                addTimerByName("workerStopTimer",WORKER_WAIT_INTERVAL,true,stopWorkerIfIdle);
            }
        }

        public function sendDataToWorker(func:Function):void
        {
            if(workerState === WORKER_STATE_RUNNING)
            {
                func();
            }
            else
            {
                workerFunctionsBeforeStart.push(func);
                function waitWorkerReady(e:Event):void
                {
                    if(worker === null)
                    {
                        stage.removeEventListener(Event.ENTER_FRAME,waitWorkerReady);
                        workerWaitCount = 0;
                        workerState = WORKER_STATE_STOPPED;
                        return;
                    }

                    if(worker.state === "running")
                    {
                        workerWaitCount++;
                        if(workerWaitCount > 10)
                        {
                            workerWaitCount = 0;
                            workerState = WORKER_STATE_RUNNING;
                            stage.removeEventListener(Event.ENTER_FRAME,waitWorkerReady);
                            while(workerFunctionsBeforeStart.length)
                            {
                                workerFunctionsBeforeStart[0]();
                                workerFunctionsBeforeStart[0] = null;
                                workerFunctionsBeforeStart.shift();
                            }
                        }
                    }
                    else
                    {
                        workerWaitCount = 0;
                    }
                }
                stage.addEventListener(Event.ENTER_FRAME,waitWorkerReady);

                if(workerState === WORKER_STATE_STOPPED)
                {
                    startWorker();
                }
            }
        }

        public function stopWorkerIfIdle(forceFlag:Boolean=false):Boolean
        {
            if((workerDataSendCount === workerDataReceiveCount
                && captureImageDataQueue === null
                && receivedSaveImageDataFromWorker === null
                && undoDataQueue === null)
                || (forceFlag === true))
                {
                    workerState = WORKER_STATE_STOPPED;
                    workerDataSendCount = 0;
                    workerDataReceiveCount = 0;

                    if(worker)
                    {
                        worker.terminate();
                        worker = null;
                    }

                    if(isLoadPendingAfterSaving)
                    {
                        loadFileTo("canvas");
                    }
                    else if(isUpdatePendingAfterSaving)
                    {
                        startUpdate();
                    }

                    enableFileOperationButtonsTopbar();
                    return false;
                }
                return true;
        }

        public function startWorker():void
        {
            if(worker === null || worker.state === "new")
            {
                workerState = WORKER_STATE_INIT;
                worker = WorkerDomain.current.createWorker(workerSWF,true);
                mainToBack = Worker.current.createMessageChannel(worker);
                backToMain = worker.createMessageChannel(Worker.current);
                backToMain.addEventListener(Event.CHANNEL_MESSAGE,onFromWorker);
                worker.setSharedProperty("backToMain",backToMain);
                worker.setSharedProperty("mainToBack",mainToBack);
                worker.start();
            }
        }

        public function initializeWorker():void
        {
            var workerLoader:URLLoader = new URLLoader();
            workerLoader.dataFormat = URLLoaderDataFormat.BINARY;
            workerLoader.addEventListener(Event.COMPLETE, onCompleteWorker);
            workerLoader.load(new URLRequest("worker.swf"));

            function onCompleteWorker(e:Event):void
            {
                workerSWF = e.target.data as ByteArray;
                workerLoader = null;
            }
        }

        public function updateCanvasPanelMask(w:Number,h:Number):void
        {
            canvasPanel.scrollRect = new Rectangle(0,0,w,h);
        }

        public function cDottedLine():Object
        {
            const lastDotPos:Point = new Point(0,0);
            var lastLineLength:Number = 0;
            var dotLineLength:Number = 5;
            var subDotLength:Number;
            var startPos:Point = new Point(0,0);
            var lastInterpPos:Point = new Point(0,0);
            var lineSize:Number = 1;
            var dotLineColor:uint = 0;
            var graphics:Graphics;

            function setLineScale(zoomed:Number):void
            {
                lineSize = 1/zoomed;
                dotLineLength = 5/zoomed;
            }

            function toggleLineColor(from:int):uint
            {
                if(dotLineColor === 0)
                {
                    dotLineColor = 0xFFFFFF;
                }
                else
                {
                    dotLineColor = 0;
                }

                return dotLineColor;
            }

            function moveTo(g:Graphics,x:Number,y:Number):void
            {
                graphics = g;

                dotLineColor = 0;
                subDotLength = dotLineLength;
                startPos.setTo(x,y);
                lastDotPos.setTo(x,y);
                lastInterpPos.setTo(x,y);

                graphics.lineStyle(lineSize,dotLineColor,1.0,false,"normal","none");
                graphics.moveTo(x,y);
            }

            function lineTo(x:Number,y:Number,closeLine:Boolean=false):void
            {
                const nowPos:Point = new Point(x,y);
                var dist:Number = Point.distance(lastDotPos,nowPos);
                var interpPoint:Point = new Point(lastDotPos.x,lastDotPos.y);
                var ratio:Number;

                subDotLength -= dist;
                
                while(subDotLength < 0)
                {
                    ratio = (dist-subDotLength)/dist-1.0;
                    interpPoint = Point.interpolate(interpPoint,nowPos,ratio);
                    
                    toggleLineColor(1);
                    graphics.lineStyle(lineSize,dotLineColor,1.0,false,"normal","none");
                    graphics.moveTo(lastInterpPos.x,lastInterpPos.y);
                    graphics.lineTo(interpPoint.x,interpPoint.y);

                    lastInterpPos.setTo(interpPoint.x,interpPoint.y);
                    dist =  Point.distance(nowPos,interpPoint);
                    subDotLength += dotLineLength;
                }

                if(closeLine)
                {
                    graphics.lineTo(startPos.x,startPos.y);
                }

                lastDotPos.setTo(x,y);
            }

            return {
                lineTo:lineTo,
                moveTo:moveTo,
                setLineScale:setLineScale
            }
        }

        public function setResizeButtonColor():void
        {
            const color:uint = Global.getUIResizeBarColor();

            Global.setColorTransform(resizeButtonL,color);
            Global.setColorTransform(resizeButtonR,color);
            Global.setColorTransform(resizeButtonU,color);
            Global.setColorTransform(resizeButtonD,color);
        }

        public function cCheckHideCursor():Object
        {
            var isMouseHide:Boolean = false;
            var count:int = 0;
            const pos:Point = new Point(0,0);

            function isMouseMoved():Boolean
            {
                return pos.x !== stage.mouseX || pos.y !== stage.mouseY || isMouseClicked || isRightMouseClicked;
            }

            function updateMousePos():void
            {
                pos.setTo(stage.mouseX,stage.mouseY);
            }

            function reset():void
            {
                Mouse.show();
                isMouseHide = false;
                count = 0;
            }

            function check():void
            {
                if(isMouseHide)
                {
                    if(isMouseMoved())
                    {
                        reset();
                    }
                }
                else
                {
                    if(count > stage.frameRate)
                    {
                        if(!isHighlightBoxVisible())
                        {
                            Mouse.hide();
                            hideBottomHint();
                            isMouseHide = true;
                            updateMousePos();
                        }
                    }
                    else
                    {
                        count++;
                    }

                    if(isMouseMoved())
                    {
                        count = 0;
                    }

                    updateMousePos();
                }
            }

            return{
                check:check,
                reset:reset
            }
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
            return  nowTool === TOOL_PEN || nowTool === TOOL_LINE;
        }

        public function isSelectedTool(tool:int):Boolean
        {
            return nowTool === tool;
        }

        public function setToolIndex(tool:int):void
        {
            nowTool = tool;
        }

        public function resetOldTool():void
        {
            lastTool = TOOL_NONE;
        }

        public function isLastTool(tool:int):Boolean
        {
            return lastTool === tool;
        }

        public function selectLastTool(tool:int):void
        {
            lastTool = tool;
        }

        public function updateLastTool():void
        {
            if(lastTool === TOOL_NONE)
            {
                lastTool = nowTool;
            }
        }

        public function startKeyRepeat(firstCall:Boolean,func:Function,...args):Boolean
        {
            if(hasTimer("keyHoldWaitTimer") || hasTimer("keyHoldRepeatTimer"))
            {
                return false;
            }

            addTimerByName("keyHoldWaitTimer",KEY_REPEAT_START_DELAY,false,
            function():void
            {
                func.apply(Main,args);
                addTimerByName("keyHoldRepeatTimer",KEY_REPEAT_INTERVAL,true,func,args);
            });

            addKeyRepeatEvents();
            if(firstCall)
            {
                func.apply(Main,args);
            }

            return true;
        }

        public function checkPenOptionsKeyDown(keyCode:uint):Boolean
        {
            const secondKey:int = getSecondPressedKey();
            if(secondKey === KEY.n3 || secondKey === KEY.n8)
            {
                if(toolOptionsBox.sharpLineButtonWrapper.alpha === 1.0)
                {
                    toggleSharpLineByShortcut();
                }
                return true;
            }
            else if(secondKey === KEY.n4 || secondKey === KEY.n7)
            {
                if(isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILL_PEN))
                {
                    togglePenAirBrushButtonShortCut();
                    return true;
                }
                else if(isSelectedTool(TOOL_ERASER))
                {
                    toggleEraseAirBrushButtonShortCut();
                    return true;
                }
            }
            return false;
        }

        public function checkOpaSizeKeyDown(keyCode:uint):Boolean
        {
            switch(keyCode)
            {
                case KEY.f:
                case KEY.h:
                {
                    startKeyRepeat(true,adjustDrawToolSizeByShortcut,true);
                }
                return true;

                case KEY.v:
                case KEY.n:
                {
                    startKeyRepeat(true,adjustDrawToolSizeByShortcut,false);
                }
                return true;

                case KEY.g:
                {
                    startKeyRepeat(true,adjustDrawToolAlphaByShortcut,true);
                }
                return true;

                case KEY.b:
                {
                    startKeyRepeat(true,adjustDrawToolAlphaByShortcut,false);
                }
                return true;
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
            
            if((second === KEY.shift && (first === KEY.ctrl || first === KEY.rightCtrl))
            || (first === KEY.shift && (second === KEY.ctrl || second === KEY.rightCtrl)))
            {
                return COMMAND_CTRL_SHIFT;
            }
            if(first === KEY.shift)
            {
                return COMMAND_SHIFT;
            }
            if(first === KEY.ctrl || first === KEY.rightCtrl)
            {
                return COMMAND_CTRL;
            }

            return 0;
        }

        public function isToolEnabledByLayerUnChecked():Boolean
        {
            return checkedLayer === 0;
        }
 
        public function isCursorInDrawArea():Boolean
        {
            return !(topBar.hitTestPoint(stage.mouseX,stage.mouseY)
            || (sideBar.visible && sideBar.hitTestPoint(stage.mouseX,stage.mouseY)))
        }

        public function initializeStageSettings():void
        {
            stage.vsyncEnabled = true;
            stage.scaleMode = StageScaleMode.NO_SCALE; //창크기 상관없이 스테이지 크기 고정
            stage.align = StageAlign.TOP_LEFT;
            stage.quality = StageQuality.BEST;
            stage.tabChildren = false;
            NativeApplication.nativeApplication.autoExit = true;
        }

        public function removeInputEventsLassoTool():void
        {
            stage.removeEventListener(KeyboardEvent.KEY_UP,onKeyUpLassoTool);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,onKeyDownLassoTool);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,onMouseDownLassoTool);
            stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUpLassoTool);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownLassoTool);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,onRightMouseUpLassoTool);
            addInputEventsDrawMode();
        }

        public function addInputEventsLassoTool():void
        {
            stage.addEventListener(KeyboardEvent.KEY_UP,onKeyUpLassoTool);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDownLassoTool);
            stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDownLassoTool);
            stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpLassoTool,false,-1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownLassoTool);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,onRightMouseUpLassoTool);
            stage.addEventListener(MouseEvent.MOUSE_OVER,lassoMenuHintONEvent);
            removeInputEventsDrawMode();
        }

        public function onMouseDownStage(e:MouseEvent):void
        {
            checkInvalidKey();
            isMouseClicked = true;
            hideBottomHint();
        }

        public function onRightMouseDownStage(e:MouseEvent):void
        {
            checkInvalidKey();
            isRightMouseClicked = true;
        }

        public function onMiddleMouseDownStage(e:MouseEvent):void
        {
            if(isCaptureModeON) return;

            if(hasTimer("toolTipTempONTimer"))
            {
                hideMouseHint();
            }

            if(isLassoToolStarted)
            {
                lassoMenuBox.visible = false;
                isLassoMenuHiddenTemp = true;
            }

            handTool(isReplayModeON,true);
        }

        public function onMouseUpStage(e:MouseEvent):void
        {
            checkInvalidKey();
            const mx:Number = stage.mouseX;
            const my:Number = stage.mouseY;

            isMouseClicked = false;
            if(!isMouseClicked && isRightMouseClicked)
            {
                isMouseDragging = false;
            }
        }

        public function onRightMouseUpStage(e:MouseEvent):void
        {
            checkInvalidKey();
            const mx:Number = stage.mouseX;
            const my:Number = stage.mouseY;

            isRightMouseClicked = false;
            if(!isMouseClicked && isRightMouseClicked)
            {
                isMouseDragging = false;
            }
        }

        public function markWindowTitleAsDirty():void
        {
            const titleEndStr:int = stage.nativeWindow.title.lastIndexOf(STRING_TITLE_FOFOPAINT);

            if(titleEndStr > 0 && stage.nativeWindow.title.charAt(titleEndStr-1) !== "*")
            {
                const starFileName:String = stage.nativeWindow.title.slice(0,titleEndStr)+"*";
                stage.nativeWindow.title = starFileName+STRING_TITLE_FOFOPAINT;

                if(isCanvasWindowON)
                {
                    copyMainWindowTitleToCanvasWindow();
                }
            }
        }

        public function resetApp():void
        {
            stage.nativeWindow.removeEventListener(Event.CLOSING, onWindowClosingEvent);
            stage.nativeWindow.removeEventListener(Event.DEACTIVATE,onWindowDeactivate);
            const files:File = File.applicationStorageDirectory;
            files.deleteDirectory(true);
        }

		public function startHidingSidebarTemporary():void
        {
            removeSidebarTempShowActivateEvents();

            if (isSidebarVisible === false)
            {
                hideSidebarTemporary();
            }
        }

        public function addSidebarTempShowActivateEvents():void
        {
            isReactivateSidebarTempShowEventsAdded = true;

            stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownReactivateSidebarTempShow);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onMouseDownReactivateSidebarTempShow);
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpReactivateSidebarTempShow);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpReactivateSidebarTempShow);
        }

        public function setSideBarClickEvents():void
        {
            isSidebarHideEventAdded = true;
            stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownHideSidebar, false, -1);
        }

        public function removeSidebarTempShowActivateEvents():void
        {
            removeTimer("sidebarTempShowActivateTimer");
            isSidebarTempShowDeactivated = false;
            isSidebarHideEventAdded = false;
            isReactivateSidebarTempShowEventsAdded = false;

            stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownHideSidebar);

            stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpReactivateSidebarTempShow);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpReactivateSidebarTempShow);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownReactivateSidebarTempShow);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onMouseDownReactivateSidebarTempShow);
        }

        public function onMouseDownReactivateSidebarTempShow(e:MouseEvent):void
        {
            if (sideBar.hitTestPoint(stage.mouseX, stage.mouseY) === false)
            {
                removeSidebarTempShowActivateEvents();
            }
        }

        // 1초정도 켜지지 않게함
        public function startTimerActivateSidebarShowTemp():void
        {
            isSidebarTempShowDeactivated = true;
            addTimerByName("sidebarTempShowActivateTimer", 0.7, false, function():void
                {
                    isReactivateSidebarTempShowEventsAdded = false;
                    isSidebarTempShowDeactivated = false;

                    removeSidebarTempShowActivateEvents();
                });
        }

        public function onMouseUpReactivateSidebarTempShow(e:MouseEvent):void
        {
            if (!(isRightMouseClicked && isMouseClicked))
            {
                startTimerActivateSidebarShowTemp();
            }
        }

        public function sidebarOFFRightMouseDownEvent(e:MouseEvent):void
        {
            isMouseClickBlocked = true;
            unblockMouseClickAfterDelay();
            startHidingSidebarTemporary();
        }

        public function onMouseDownHideSidebar(e:MouseEvent):void
        {
            if (e.target && (e.target.name === "sideBarONButton" || e.target.name === "sideBarONButton2" || e.target.name === "fofo"))
            {

            }
            else if (sideBar.hitTestPoint(stage.mouseX, stage.mouseY) === false)
            {
                startHidingSidebarTemporary();
            }
        }

        public function startShowSideBarTemporary():void
        {
            if (!(isMouseClicked || isRightMouseClicked || isMouseDragging))
            {
                if (!isSidebarTempShowDeactivated)
                {
                    if (isSidebarHideEventAdded === false)
                    {
                        setSideBarClickEvents();
                    }

                    if (sideBar.visible === false)
                    {
                        // setSidebarVisible(true,true);
                        showSidebarTemporary();
                    }
                }
            }
            else if (isReactivateSidebarTempShowEventsAdded === false && sideBar.visible === false) // 클릭한 상태에서 들어올경우
            {
                addSidebarTempShowActivateEvents();
            }
        }

        public function canShowSidebarTemporarily():Boolean
        {
            return !sideBar.visible
            && !isReplayModeON
            && !isCaptureModeON
            && !isToolBox2Showing
            && !isMouseClickBlocked
            && !isLassoToolStarted
            && !resizeButtonR.visible;
        }

        public function onMouseLeaveSideBar(e:Event):void
        {
            if(canShowSidebarTemporarily())
            {
                const sideBarWidth:Number = sideBar.getWidth();

                if(((isRightSidebar && stage.mouseX > stage.stageWidth-sideBarWidth)
                || (!isRightSidebar && stage.mouseX < sideBarWidth))
                && mouseY > STAGE_TOP_OFFSET)
                {
                    startShowSideBarTemporary();
                }
            }
        }

	    public function onMouseMoveSideBar(e:MouseEvent):void
        {
            if (canShowSidebarTemporarily())
            {
                const mx:Number = stage.mouseX;
                const my:Number = stage.mouseY;

                if ((!isRightSidebar && mx <= 15 || isRightSidebar && mx >= stage.stageWidth - 15) && my > STAGE_TOP_OFFSET)
                {
                    startShowSideBarTemporary();
                }
            }
        }

        public function onMouseUpSideBar(e:MouseEvent):void
        {
            const mx:Number = stage.mouseX;
            const my:Number = stage.mouseY;

            if(mx < 0 || mx > stage.stageWidth || my < 0 || my > stage.stageHeight)
            {
                if(sideBar.visible === false)
                {
                    addSidebarTempShowActivateEvents();
                }
            }
        }
        
        public function updateSidebarLayout():void
        {
            updateStageOffset();
            updateCanvasNaigatorCursor();
            checkFOFOPosition();
        }

        public function restoreLassoAndRefLayerBoxLastPos():void
        {
            const arr:Array = lassoAndRefLayerBoxLastPos;

            if((arr[0] !== arr[2] || arr[1] !== arr[3])
            && lassoMenuBox.x === arr[2] && lassoMenuBox.y === arr[3])
            {
                lassoMenuBox.x = arr[0];
                lassoMenuBox.y = arr[1];
            }

            if((arr[4] !== arr[6] || arr[5] !== arr[7])
            && refLayerMenuBox.x === arr[6] && refLayerMenuBox.y === arr[7])
            {
                refLayerMenuBox.x = arr[4];  
                refLayerMenuBox.y = arr[5];
            }
        }

        public function recordLassoAndRefLayerBoxLastPos():void
        {
            const arr:Array = lassoAndRefLayerBoxLastPos;

            if (isLassoToolStarted)
            {
                arr[0] = lassoMenuBox.x;
                arr[1] = lassoMenuBox.y;
                keepBoxInsideViewPort(lassoMenuBox);
                arr[2] = lassoMenuBox.x;
                arr[3] = lassoMenuBox.y;
            }

            if (isRefLayerMenuON)
            {
                arr[4] = refLayerMenuBox.x;
                arr[5] = refLayerMenuBox.y;
                keepBoxInsideViewPort(refLayerMenuBox);
                arr[6] = refLayerMenuBox.x;
                arr[7] = refLayerMenuBox.y;
            }

        }

        public function showSidebarPermanent():void
        {
            isSidebarVisible = true;
            sideBar.visible = true;
            topBar.checkSideBarONOFFButton(true, isRightSidebar);
            updateSidebarLayout();
            hideBottomHint();
            recordLassoAndRefLayerBoxLastPos();
            sideBar.resetBG();

            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpSideBar);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpSideBar);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveSideBar);
            stage.removeEventListener(Event.MOUSE_LEAVE,onMouseLeaveSideBar);
        }

        public function hideSidebarPermanent():void
        {
            isSidebarVisible = false;
            sideBar.visible = false;
            topBar.checkSideBarONOFFButton(false, isRightSidebar);
            updateSidebarLayout();
            hideBottomHint();
            restoreLassoAndRefLayerBoxLastPos();

            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpSideBar);
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpSideBar);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveSideBar);
            stage.addEventListener(Event.MOUSE_LEAVE,onMouseLeaveSideBar);
        }

        public function showSidebarTemporary():void
        {
            sideBar.visible = true;
            updateSidebarLayout();
            recordLassoAndRefLayerBoxLastPos();
            sideBar.setTransparentBG();
        }

        public function hideSidebarTemporary():void
        {
            sideBar.visible = false;
            updateSidebarLayout();
            restoreLassoAndRefLayerBoxLastPos();
        }

        public function selectTransparentColor():void
        {
            isTransparentPenColor = true;
            colorPickerBox.setRGBInfoBackgroundTransparent(myPalettePresetType);
        }

        public function selectCurrentColor(bgmode:Boolean):void
        {
            const hexColor:uint = colorPickerBox.currentColor;

            isTransparentPenColor = false;

            if(bgmode)
            {
                updateCanvasBGColorDrawMode(hexColor);
                if(isCanvasWindowON)
                {
                    updateCanvasWindowBGColor(CANVAS_BG_COLOR,canvasWindowLayer1Bitmap.bitmapData);
                }
                updateColorPickerCursorPosAndRGBInfo(hexColor);
                addUndoBGColorData(hexColor);
            }
            else
            {
                penColor = hexColor;
                updateOpacityCursorPos(penAlphaIndex);
                updateColorPickerCursorPosAndRGBInfo(hexColor);
            }
        }

        public function getFinalBitmapDataFrom2020File(file:File,bgFlag:Boolean):BitmapData
        {
            const fs:FileStream = new FileStream();
            fs.open(file,FileMode.READ);
            var finalIMGBMPD:BitmapData;
            var finalIMGBMPD1:BitmapData;

            if(isNew2020File(file))
            {
                fs.readUTFBytes(9); //FOFOPAINT헤더 읽어줌
                const compBytes:uint = fs.readUnsignedInt(); // 압축된 데이터 길이 읽어줌
                fs.position += compBytes;
            }

            var ba:ByteArray;
            var newRectangle:Rectangle;
            var bg:uint;

            while(true)
            {
                if(fs.bytesAvailable === 0) break;
                const d:Array = fs.readObject() as Array;

                if(d[0] === "rFinalImage")
                {
                    //구버전 파일 레이어 없을때
                    if(d[2] is ByteArray === false)
                    {
                        ba = d[1] as ByteArray;
                        newRectangle = new Rectangle(0,0,d[2],d[3]);

                        ba.uncompress();
                        finalIMGBMPD = new BitmapData(d[2],d[3],true,0);
                        finalIMGBMPD.lock();
                        finalIMGBMPD.setPixels(newRectangle,ba);
                        finalIMGBMPD.unlock();
                        ba.clear();
                        ba = null;
                        bg = d[4];
                    }
                    else
                    {
                        ba = d[2] as ByteArray;
                        newRectangle = new Rectangle(0,0,d[3],d[4]);
                        ba.uncompress();
                        finalIMGBMPD = new BitmapData(d[3],d[4],true,0);
                        finalIMGBMPD.lock();
                        finalIMGBMPD.setPixels(newRectangle,ba);
                        finalIMGBMPD.unlock();
                        ba.clear();

                        ba = d[1] as ByteArray;
                        ba.uncompress();
                        finalIMGBMPD1 = new BitmapData(d[3],d[4],true,0);
                        finalIMGBMPD1.lock();
                        finalIMGBMPD1.setPixels(newRectangle,ba);
                        finalIMGBMPD1.unlock();
                        ba.clear();
                        ba = null;
                        bg = d[5];

                        finalIMGBMPD.draw(finalIMGBMPD1);
                        finalIMGBMPD1.dispose();
                    }
                }
            }
            fs.close();

            if(bgFlag)
            {
                const bgBmpd:BitmapData = new BitmapData(finalIMGBMPD.width,finalIMGBMPD.height,false,bg);
                bgBmpd.draw(finalIMGBMPD);

                return bgBmpd;
            }

            return finalIMGBMPD;
        }

        public function isNew2020File(file:File):Boolean
        {
            if(!file)
            {
                return false;
            }

            const fs:FileStream = new FileStream();
            fs.open(file,FileMode.READ);

            try
            {
                const header:String = fs.readUTFBytes(9);

                if(header === "FOFOPAINT")
                {
                    fs.close();
                    return true;
                }

                fs.close();
                fs.open(file,FileMode.READ);
            }
            catch(err:Error)
            {
                fs.close();
                return false;
            }

            return false;
        }

        public function isOld2020File(file:File):Boolean
        {
            const fs:FileStream = new FileStream();
            fs.open(file,FileMode.READ);

            try
            {
                //구버전 파일 읽기 헤더가 없고 바로 배열임
                const arr:Array = (fs.readObject() as Array);

                if(!arr) return false;
                if(!(arr[0][0] is String)) return false;

                fs.close();
                return true;
            }
            catch(err:Error)
            {
                fs.close();
                return false;
            }
            return false;
        }

        public function isTrue2020File(file:File):Boolean
        {
            if(!file || !(file is File)) return false;

            if(isNew2020File(file))
            {
                return true;
            }

            if(isOld2020File(file))
            {
                return true;
            }

            return false;
        }

        public function isImageFileExt(path:String):Boolean
        {
            //가장 마지막 확장자만 따짐
            const gif:int = path.lastIndexOf(".gif");
            const jpg:int = path.lastIndexOf(".jpg");
            const png:int = path.lastIndexOf(".png");
            const find2020:int = path.lastIndexOf(".2020");
            const maxIndex:int = Math.max(gif,jpg,png,find2020);

            return maxIndex === find2020;
        }

        public function cFillPenTool():Object
        {
            const lastMousePos:Point = new Point(0,0);
            var canvasSizeRect:Rectangle = new Rectangle();
            var command:Vector.<int>;
            var data:Vector.<Number>;
            var xColor:uint;
            var xAlpha:Number;
            var commandUndoIndexArr:Array = [];
            var mouseMoveCount:int;
            var afterKeyUpOK:Boolean;
            var pos05Offset:Number;
            // var _sharpLine:Boolean;
            var xBlendMode:String;
            var clickedButton:String;
            var fillPenBoxUndoUsed:Boolean = false;
            var canvasDrawZIndexSave:int = 0;
            const posSave:Point = new Point();
            var fillPenPreviewModeFlag:Boolean = false;
            var fillpenPreviewModeMouseTarget:DisplayObject;
            var turnOffFillPenPreviewCount:int = 0;

            function onEnterFrameFillPenPreview(e:Event):void
            {
                const newXcolor:uint = (isTransparentPenColor) ? CANVAS_BG_COLOR : colorPickerBox.rgbInfoBGColor;
                const newXAlpha:Number = penAlpha
                const newXBlendMode:String = (isTransparentPenColor) ? "erase" : null;

                if(newXcolor !== xColor)
                {
                    xColor = newXcolor;
                    xAlpha = newXAlpha;
                    xBlendMode = newXBlendMode;
                    drawFillPenData();
                }

                if(newXAlpha !== xAlpha)
                {
                    xAlpha = newXAlpha;
                    drawFillPenData();
                }

                if(newXBlendMode !== xBlendMode)
                {
                    xBlendMode = newXBlendMode;
                    drawFillPenData();
                }

                if(!sideBar.visible)
                {
                    fillPenPreviewModeFlag = false;
                    stage.removeEventListener(Event.ENTER_FRAME,onEnterFrameFillPenPreview);
                    drawPreviewLine();
                }
                else if(!sideBar.hitTestPoint(stage.mouseX,stage.mouseY) && !isMouseClicked)
                {
                    turnOffFillPenPreviewCount--;
                    if(turnOffFillPenPreviewCount <= 0)
                    {
                        turnOffFillPenPreviewCount = 0;
                        fillPenPreviewModeFlag = false;
                        stage.removeEventListener(Event.ENTER_FRAME,onEnterFrameFillPenPreview);
                        drawPreviewLine();
                    }
                }
            }

            function switchFillPenColorPreviewMode():void
            {
                if(isLayer2Selected)
                {
                    bringCanvasDrawLayerAboveLayer2();
                }

                if(fillPenPreviewModeFlag === false)
                {
                    fillPenPreviewModeFlag = true;
                    stage.addEventListener(Event.ENTER_FRAME,onEnterFrameFillPenPreview);
                }
            }

            function onMouseOverFillPenHint(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if(!target) return;

                const targetName:String = target.name;

                if(targetName === "fillPenOK") fillPenBox.hint("OK [q, o key up]");
                if(targetName === "fillPenCancel") fillPenBox.hint("Cancel\n[esc, backspace]");
                else if(targetName === "fillPenUndo") fillPenBox.hint("Undo [w, z, i, .]");
                else if(targetName === "fillPenSidebar") fillPenBox.hint("[6, s+d, j+k]");
            }

            function checkFillPenUndoReady():Boolean
            {
                if(canvasSizeRect.intersects(canvasDrawLayerChild.getBounds(canvasPanel)))
                {
                    return true;
                }
                return false;
            }

            function drawFillPenData():void
            {
                canvasDrawLayerChild.graphics.clear();

                if(data.length === 0) return;

                canvasDrawLayerChild.graphics.lineStyle(1,xColor);
                canvasDrawLayerChild.graphics.beginFill(xColor);
                canvasDrawLayerChild.graphics.drawPath(command,data);
                canvasDrawLayerChild.graphics.endFill();
                canvasDrawLayerChild.graphics.moveTo(data[data.length-2],data[data.length-1]);
                canvasDrawLayerChild.graphics.lineTo(data[0],data[1]);

                canvasDrawLayer.alpha = xAlpha;
            }

            function drawPreviewLine():void
            {
                canvasDrawLayerChild.graphics.clear();

                const len:uint = data.length;
                if(len <= 3)
                {
                    return;
                }

                dottedLine.moveTo(canvasDrawLayerChild.graphics,data[0],data[1]);

                for(var i:uint=2; i<len; i+=2)
                {
                    dottedLine.lineTo(data[i],data[i+1]);
                }
                dottedLine.lineTo(data[0],data[1],true);

                if(isLayer2Selected)
                {
                    bringCanvasDrawLayerAboveLayer1();
                }

                canvasDrawLayer.alpha = 1.0;
            }

            function cancelFillPen():void
            {
                removeEvents();
                canvasDrawLayer.alpha = 1.0;
                mouseMoveCount = 0;
                isFillPenStarted = false;
                command.length = 0;
                data.length = 0;
                commandUndoIndexArr.length = 0;
                canvasDrawLayerChild.graphics.clear();

                if(isRefLayerMenuON) refLayerMenuBox.visible = true;

                fillPenBox.visible = false;
                fillPenBox.x = -fillPenBox.width-3;
                fillPenBox.y = -fillPenBox.height-3;

                if(isLayer2Selected)
                {
                    bringCanvasDrawLayerAboveLayer2();
                }

                if(isQuickSidebarActive)
                {
                    startDeactivteQuickSidebar();
                }

                toolBox.setFillPenModeOFF();
                toolOptionsBox.restoreDisabledButtons();
                colorPickerBox.activePaperColorButton(false);
            }

            function applyFillPen():void
            {
                if(checkFillPenUndoReady() === true && command.length > 2)
                {
                    canAddUndoData = true;
                    command.push(2);
                    data.push(data[0]);
                    data.push(data[1]); //마지막으로 원점으로 선을 한번 이어줘야 깔끔하게 닫힘
                    canvasDrawLayer.alpha = xAlpha;
                    rDataBuffer.push(["fill5",xColor,xAlpha,xBlendMode,command.concat(),data.concat(),isPenAirBrushON,airBrushSizeDrawMode]);

                    drawFillPenData();
                }

                resetCanvasDrawLayerCliprect();
                drawDone();

                cancelFillPen();
            }

            function undoData():void
            {
                if(command.length === 0) return;

                command.splice(commandUndoIndexArr[commandUndoIndexArr.length-1],command.length);
                data.splice(commandUndoIndexArr[commandUndoIndexArr.length-1]*2,data.length);
                commandUndoIndexArr.pop();

                if(command.length <= 1)
                {
                    command.length = 0;
                    data.length = 0;
                    commandUndoIndexArr[0] = 0;
                    canvasDrawLayerChild.graphics.clear();
                }
                else
                {
                    drawPreviewLine();
                }
            }

            function onKeydownFillPen(e:KeyboardEvent):void
            {
                const keyCode:uint = e.keyCode;
                if(isMouseClicked)
                {
                    return;
                }

                if(isLastKey(keyCode))
                {
                    return;
                }

                const secondKey:int = getSecondPressedKey();

                if(keyCode === KEY.s || keyCode === KEY.k)
                {
                    if(secondKey === KEY.d || secondKey === KEY.j)
                    {
                        updateLastKey(keyCode);
                        if(isQuickSidebarActive === false)
                        {
                            activeQuickSideBar(true);
                            drawFillPenData();
                            switchFillPenColorPreviewMode();
                        }
                    }
                }
                else if(keyCode === KEY.d || keyCode === KEY.j)
                {
                    if(secondKey === KEY.s || secondKey === KEY.k)
                    {
                        updateLastKey(keyCode);
                        if(isQuickSidebarActive === false)
                        {
                            activeQuickSideBar(true);
                            drawFillPenData();
                            switchFillPenColorPreviewMode();
                        }
                    }
                }
                else if(keyCode === KEY.g || keyCode === KEY.b)
                {
                    updateLastKey(keyCode);
                    startKeyRepeat(true,function(increase:Boolean):void
                    {
                        turnOffFillPenPreviewCount = stage.frameRate;
                        adjustDrawToolAlphaByShortcut(increase);
                    },(keyCode === KEY.g)?true:false);
                    switchFillPenColorPreviewMode();
                }
                else if(keyCode === KEY.n6)
                {
                    updateLastKey(keyCode);
                    if(isQuickSidebarActive === false)
                    {
                        activeQuickSideBar(true);
                        drawFillPenData();
                        switchFillPenColorPreviewMode();
                    }
                }
            }

            function onKeyUpFillPen(e:KeyboardEvent):void
            {
                const keyCode:uint = e.keyCode;

                resetLastKey();

                if(isMouseClicked)
                {
                    if(keyCode === KEY.q || keyCode === KEY.o || keyCode === KEY.enter)
                    {
                        afterKeyUpOK = true;
                    }
                    return;
                }

                if(keyCode === KEY.w || keyCode === KEY.i || keyCode === KEY.z || keyCode === KEY.dot)
                {
                    undoData();
                }
                else if(keyCode === KEY.q || keyCode === KEY.o || keyCode === KEY.enter)
                {
                    applyFillPen();
                }
                else if(keyCode === KEY.esc || keyCode === KEY.backspace)
                {
                    cancelFillPen();
                }
            }

            function onRightMouseUpFillPen(e:MouseEvent):void
            {
                if(!e.target as DisplayObject || e.target === sideBarScrollBar
                || sideBar.visible && sideBar.hitTestPoint(stage.mouseX, stage.mouseY))
                {
                    return;
                }

                const targetName:String = e.target.name;

                if(targetName === "fillPenOK")
                {
                    applyFillPen();
                }
                else if(targetName === "fillPenCancel")
                {
                    cancelFillPen();
                }
                else if(targetName === "fillPenUndo")
                {
                    fillPenBoxUndoUsed = true;
                    undoData();
                }
                else if(targetName === "fillPenSidebar")
                {
                    activeQuickSideBar(false);
                    drawFillPenData();
                    switchFillPenColorPreviewMode();
                }
                // else
                // {
                //     endFillPenOK();
                // }

                fillPenBox.visible = false;
            }

            function onRightMouseDownFillPen(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if(isMouseClicked || isQuickSidebarActive ||!target || numPadBox.visible)
                {
                    return;
                }

                if(target === sideBarScrollBar)
                {
                    resetSideBarPosition();
                    return;
                }
                else if(target.name === "toolZoomIn" || target.name === "toolZoomOut")
                {
                    if(canvasZoomMultipler !== 1.0)
                    {
                        resetZoomDrawMode();
                    }
                    return;
                }
                else if(target.name === "toolRotate")
                {
                    if(canvasAnchorPoint.rotation !== 0.0)
                    {
                        resetRotationDrawMode();
                    }
                    return;
                }

                if(sideBar.visible && sideBar.hitTestPoint(stage.mouseX,stage.mouseY))
                {
                    return;
                }

                const scale:Number = fillPenBox.getScale();

                fillPenBox.visible = true;
                setAsTopChild(fillPenBox);

                if(fillPenBoxUndoUsed)
                {
                    fillPenBox.x = Math.floor(stage.mouseX-(fillPenBox.fillPenUndo.width/2)*scale);
                    fillPenBox.y = Math.floor(stage.mouseY-(fillPenBox.fillPenUndo.y+fillPenBox.fillPenUndo.height/2)*scale);
                }
                else
                {
                    fillPenBox.x = Math.floor(stage.mouseX-(fillPenBox.fillPenOK.x+fillPenBox.fillPenOK.width/2)*scale);
                    fillPenBox.y = Math.floor(stage.mouseY-(fillPenBox.fillPenOK.y+fillPenBox.fillPenOK.height/2)*scale);
                }
            }

            function onMouseUpFillPen(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if(!target) return;

                const targetName:String = e.target.name;

                removeTimer("fillPenTimer");
                isMouseDragging = false;
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveFillPen);

                if(clickedButton === targetName)
                {
                    if(targetName === "toolFillPenOK")
                    {
                        applyFillPen();
                        return;
                    }
                    else if(targetName === "toolFillPenCancel")
                    {
                        cancelFillPen();
                        return;
                    }
                    else if(targetName === "toolUndo")
                    {
                        fillPenBoxUndoUsed = true;
                        undoData();
                        return;
                    }
                }

                if(fillPenBox.visible)
                {
                    if(clickedButton === targetName)
                    {
                        if(targetName === "fillPenOK")
                        {
                            applyFillPen();
                        }
                        else if(targetName === "fillPenCancel")
                        {
                            cancelFillPen();
                        }
                        else if(targetName === "fillPenUndo")
                        {
                            fillPenBoxUndoUsed = true;
                            undoData();
                        }
                    }
                }
                else
                {
                    const mousePos:Point = new Point(stage.mouseX,stage.mouseY);
                    const dist:Number = Math.floor(Point.distance(mousePos,lastMousePos));

                    mouseMoveCount += dist;
                    if(mouseMoveCount >= 10)
                    {
                        mouseMoveCount = 0;
                        commandUndoIndexArr.push(command.length-1);
                    }

                    lastMousePos.setTo(mousePos.x,mousePos.y);

                    if(afterKeyUpOK)
                    {
                        applyFillPen();
                    }
                    else if(fillPenPreviewModeFlag === false)
                    {
                        drawPreviewLine();
                    }

                    if(turnOffFillPenPreviewCount > 0)
                    {
                        turnOffFillPenPreviewCount = 0;
                    }
                }

                afterKeyUpOK = false;
            }

            function onMouseMoveFillPen(e:MouseEvent):void
            {
                // if(readyAddUndoFlag === false) checkFillPenUndoReady();

                const filteredPos:Point = getFilteredPos(canvasDrawLayerChild.mouseX,canvasDrawLayerChild.mouseY);
                const mx:Number = filteredPos.x+pos05Offset;
                const my:Number = filteredPos.y+pos05Offset;

                if(posSave.x === mx && posSave.y === my)
                {
                    return;
                }

                posSave.setTo(mx,my);

                if(command.length === 0)
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
                if(mouseMoveCount >= 6)
                {
                    mouseMoveCount = 0;
                    commandUndoIndexArr.push(command.length-1);
                }
                lastMousePos.setTo(stage.mouseX,stage.mouseY);
                turnOffFillPenPreviewCount = 0;

                if(!hasTimer("fillPenTimer"))
                {
                    addTimerByName("fillPenTimer",0.083,false,drawFillPenData);
                }
            }

            function onMouseDownFillPen(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if(!target) return;
                const targetName:String = target.name;

                clickedButton = targetName;
                if(fillPenBox.visible)
                {
                    return;
                }

                if(sideBar.visible && sideBar.hitTestPoint(stage.mouseX,stage.mouseY))
                {
                    if(targetName === "penColorButton"
                    || targetName === "paperColorButton"
                    || targetName === "rgbInfoText")
                    {
                        return;
                    }

                    if(handleColorPickerBoxMouseDown(target) || numPadBox.visible)
                    {
                        switchFillPenColorPreviewMode();
                        return;
                    }

                    if(numPadBox.visible)
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
                            startCanvasMoveByCanvasNavigator(false);
                        }
                        return;

                        case "prevCursor":
                        {
                            startCanvasMoveByCanvasNavigator(true);
                        }
                        return;

                        case "toolZoomIn":
                        case "toolZoomOut":
                        {
                            executeToolBoxClick(targetName);
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
                            switchFillPenColorPreviewMode();
                            selectOpacityButton(targetName);
                        }
                        break;

                        default:
                        break;
                    }
                }

                if(targetName === "sideBarScrollBar")
                {
                    startScrollSidebarByDrag();
                }
                else if(isCursorInDrawArea() && isQuickSidebarActive === false)
                {
                    isMouseDragging = true;
                    stage.addEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveFillPen);

                    const filteredPos:Point = getFilteredPos(canvasDrawLayerChild.mouseX,canvasDrawLayerChild.mouseY);
                    const mx:Number = filteredPos.x+pos05Offset;
                    const my:Number = filteredPos.y+pos05Offset;

                    if(isLayer2Selected)
                    {
                        bringCanvasDrawLayerAboveLayer2();
                    }

                    if(posSave.x === mx && posSave.y === my)
                    {
                        removeTimer("fillPenTimer");
                        drawFillPenData();
                        return;
                    }
                    
                    posSave.setTo(mx,my);

                    if(command.length === 0)
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

                    removeTimer("fillPenTimer");
                    drawFillPenData();
                }
            }

            function removeEvents():void
            {
                stage.removeEventListener(MouseEvent.MOUSE_OVER,onMouseOverFillPenHint);
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,onMouseDownFillPen);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveFillPen);
                stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUpFillPen);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownFillPen);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,onRightMouseUpFillPen);
                stage.removeEventListener(KeyboardEvent.KEY_UP,onKeyUpFillPen);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN,onKeydownFillPen);
            }

            function addEvents():void
            {
                stage.addEventListener(MouseEvent.MOUSE_OVER,onMouseOverFillPenHint);
                stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDownFillPen);
                stage.addEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveFillPen);
                stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpFillPen);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownFillPen);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,onRightMouseUpFillPen);
                stage.addEventListener(KeyboardEvent.KEY_UP,onKeyUpFillPen);
                stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeydownFillPen);
            }

            function start():void
            {
                isFillPenStarted = true;

                canvasSizeRect.width = CANVAS_WIDTH;
                canvasSizeRect.height = CANVAS_HEIGHT;

                command = new Vector.<int>();
                data = new Vector.<Number>();

                if(isColorPickerModeBG)
                {
                    switchColorPickerModePen();
                }
                mouseMoveCount = 0;
                afterKeyUpOK = false;
                pos05Offset = getSharpLinePosOffset(1.0);
                xColor = (isTransparentPenColor) ? CANVAS_BG_COLOR : penColor;
                xAlpha = penAlpha;
                xBlendMode = (isTransparentPenColor) ? "erase" : null;
                commandUndoIndexArr[0] = 0;
                clickedButton = null;
                fillPenBoxUndoUsed = false;

                if(isPenAirBrushON || isEraserAirBrushON)
                {
                    canvasDrawLayerChild.filters = [];
                }

                if(!isTransparentPenColor)
                {
                    if(!isCurrentColorSamePickedColor())
                    {
                        updatePickerCurrentColor(colorPickerBox.getRGBInfoBGColor());
                        addColorMyPaletteHistory(colorPickerBox.getRGBInfoBGColor());
                    }
                }

                if(isRefLayerMenuON)
                {
                    refLayerMenuBox.visible = false;
                }
                dottedLine.setLineScale(canvasZoomMultipler);

                const filteredPos:Point = getFilteredPos(canvasDrawLayerChild.mouseX,canvasDrawLayerChild.mouseY);
                var mx:Number = filteredPos.x+pos05Offset;
                var my:Number = filteredPos.y+pos05Offset;
                posSave.setTo(mx,my);

                command.push(1);
                data.push(mx);
                data.push(my);
                lastMousePos.setTo(mx,my);
                canvasDrawLayer.alpha = xAlpha;
                toolBox.setFillPenModeON();
                toolOptionsBox.disableButtonFillPenStarted();
                colorPickerBox.fillPenModeON();

                addEvents();
            }

            return {
                start:start
            };
        }

        public function cPenTool():Function
        {
            const clickPos:Point = new Point(); //점찍어 줄 때 판단하는 클릭한 자리 저장
            const smoothPos:Point = new Point(); //펜 스무딩에서 커서 뒤에 따라가는 실제 선의 죄표를 저장
            const smoothLast:Point = new Point(); //펜 스무딩에서 현재 마우스 커서 위치를 저장
            const moveEventLast:Point = new Point(); //마우스 move이벤트에서 브러시 크기 필터 해주기 위해 현재 위치 저장
            const moveEventDistSave:Point = new Point(); //마우스 move이벤트에서 브러시 크기 필터 해주기 위해 마지막 위치 저장
            const moveEvent2Last:Point = new Point(); //penMove2함수에서 smooth pos를 저장해서 같은 위치면 안그려주기 위해서 마지막 위치를 저장
            const sqPenCursorLast:Point = new Point(); //사각형 커서 각도를 위한 위치저장
            const sqLinePosLast:Point = new Point(); //사각형라인일 때 일정 길이이상 일때만 그려주기 위한 위치
            const extendedPos:Point = new Point(); //사각형라인일 때 양끝점을 약간 확장해주기 위한 위치
            const penCommand:Vector.<int> = new Vector.<int>(); //그냥펜
            const penPoints:Vector.<Number> = new Vector.<Number>(); //그냥펜 좌표
            const canvasSizeRect:Rectangle = new Rectangle();

            var penToolFlag:Boolean;
            var xSize:uint;
            var xColor:uint;
            var xAlpha:Number;
            var xShape:Boolean;
            var xBlendMode:String;
            var xAirBrushON:Boolean;
            var offsetForSharpline:Number; //경계선 0.5를 조절해서 번지게 보이느냐 샤프하게 보이느냐
            var mouseMoveCount:int; //마우스 이벤트에서 움직일때 올려주는 카운터 한번에 너무 많이 움직여주면 cpu부하 먹어서 100카운트 마다 bmp에 그려줌
            var isMouseMoved:Boolean;
            var lastMouseMoveDist:Number;//penmove에서 distlimit이하이면 jump해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌
            var dotflag:Boolean; //펜스무딩이 강하게 들어갔을때 아주 작은 위치만 그려주면 표현이 제대로 안되기 때문에 너무 작게 선이 그려졌을때 올려주는 플래그
            var sq1PXCursor:Boolean = false; //1픽셀 사각형 커서인경우 올려주고 커서 미리보기 회전적용되게 함

            function isCircleRectColliding(cx:Number, cy:Number, r:Number, rx:Number, ry:Number, w:Number, h:Number):Boolean
            {
                const px:Number = Math.max(rx, Math.min(cx,rx+w));
                const py:Number = Math.max(ry, Math.min(cy,ry+h));
                const distance:Number = (Math.sqrt(Math.pow(px-cx,2)+Math.pow(py-cy,2)));

                return distance <= r/2;
            }

            function setCanUndoDataFlagON():void
            {
                if(canvasLayer1Bitmap.hitTestPoint(stage.mouseX,stage.mouseY,true))
                {
                    canAddUndoData = true;
                }
                else if(penCursorShape)
                {
                    if(canvasSizeRect.intersects(penSizePreviewCursor.getBounds(canvasPanel)))
                    {
                        canAddUndoData = true;
                    }
                }
                else if(isCircleRectColliding(canvasPanel.mouseX,canvasPanel.mouseY,penCursorSize,0,0,CANVAS_WIDTH,CANVAS_HEIGHT))
                {
                    canAddUndoData = true;
                }
            }

            function lineStyleReady(shape:Boolean,size:uint,color:uint,alpha:Number):void
            {
                canvasDrawLayer.alpha = alpha;

                if(shape === false)
                {
                    canvasDrawLayerChild.graphics.lineStyle(size,color);
                }
                else
                {
                    canvasDrawLayerChild.graphics.lineStyle(size,color,1,false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.BEVEL);
                }
            }

            function lineSmoothing():void
            {
                var ox:Number = smoothPos.x;
                var oy:Number = smoothPos.y;

                ox += (smoothLast.x-ox)*penSmoothValue;
                oy += (smoothLast.y-oy)*penSmoothValue;

                processPenToolMove(ox,oy);

                if(Math.abs(smoothLast.x-ox) < 0.02 && Math.abs(smoothLast.y-oy) < 0.02)
                {
                    return;
                }
                else
                {
                    smoothPos.setTo(ox,oy);
                    addTimerByName("lineSmoothingTimer",0.02,false,lineSmoothing);
                }
            }

            //끝 부분점을 distance만큼 길게 늘임
            function updateExtendEndPoint(x1:Number,y1:Number,x2:Number,y2:Number,distance:Number):void
            {
                // 선분 방향 벡터 계산
                const directionX:Number = x2 - x1;
                const directionY:Number = y2 - y1;

                // 선분 길이 계산
                const length:Number = Math.sqrt(directionX * directionX + directionY * directionY);

                // 선분 방향 벡터 정규화
                const normalizedDirectionX:Number = directionX / length;
                const normalizedDirectionY:Number = directionY / length;

                extendedPos.setTo(x2 + normalizedDirectionX * distance,y2 + normalizedDirectionY * distance);
            }


            function processPenToolMove(mx:Number,my:Number):void
            {
                if(canAddUndoData === false)
                {
                    setCanUndoDataFlagON();
                }

                const filteredPos:Point = getFilteredPos(mx,my);

                mx = filteredPos.x+offsetForSharpline;
                my = filteredPos.y+offsetForSharpline;

                if(xShape === true)
                {
                    const sx:Number = sqLinePosLast.x-mx;
                    const sy:Number = sqLinePosLast.y-my;
                    const dist:Number = Math.sqrt(sx*sx+sy*sy);

                    if(dist <= 2.5)
                    {
                        return;
                    }
                    else
                    {
                        sqLinePosLast.setTo(mx,my);
                    }
                }

                if(isMouseMoved === false) //움직이기 시작할때 linestyle이랑 moveto넣어줌
                {
                    isMouseMoved = true;

                    canvasDrawLayerChild.graphics.clear();
                    lineStyleReady(xShape,xSize,xColor,xAlpha);

                    if(xShape)
                    {
                        const filteredStartPos:Point = getFilteredPos(clickPos.x,clickPos.y);
                        filteredStartPos.x = filteredStartPos.x+offsetForSharpline;
                        filteredStartPos.y = filteredStartPos.y+offsetForSharpline;
                        updateExtendEndPoint(mx,my,filteredStartPos.x,filteredStartPos.y,xSize/8);
                        rDataBuffer.push(["lineStyle5",xShape,xSize,xColor,xAlpha,extendedPos.x,extendedPos.y,xBlendMode,false,isLayer2Selected,airBrushSizeDrawMode]);
                        penPoints.push(extendedPos.x);
                        penPoints.push(extendedPos.y);
                        canvasDrawLayerChild.graphics.moveTo(extendedPos.x,extendedPos.y);
                    }
                    else
                    {
                        rDataBuffer.push(["lineStyle5",xShape,xSize,xColor,xAlpha,smoothPos.x+offsetForSharpline,smoothPos.y+offsetForSharpline,xBlendMode,false,isLayer2Selected,airBrushSizeDrawMode]);
                        penPoints.push(smoothPos.x+offsetForSharpline);
                        penPoints.push(smoothPos.y+offsetForSharpline);
                        canvasDrawLayerChild.graphics.moveTo(smoothPos.x+offsetForSharpline,smoothPos.y+offsetForSharpline);
                    }
                }

                if(isMouseMoved)
                {
                    if(moveEvent2Last.x === mx && moveEvent2Last.y === my)
                    {
                        return;
                    }
                    rDataBuffer.push(["lineTo",mx,my]);
                    penCommand.push(2);
                    penPoints.push(mx);
                    penPoints.push(my);
                    moveEvent2Last.setTo(mx,my);
                    canvasDrawLayerChild.graphics.lineTo(mx,my);

                    mouseMoveCount++;
                    if(mouseMoveCount >= 100)
                    {
                        mouseMoveCount = 0;

                        if(airBrushSizeDrawMode > 0)
                        {
                            const blurSize:Number = getBlurSize(airBrushSizeDrawMode,1.0);
                            canvasDrawLayerChild.filters = [new BlurFilter(blurSize,blurSize,3)];
                            canvasDrawLayerBitmapData.draw(canvasDrawLayerChild,null,null,"layer");
                            canvasDrawLayerChild.filters = [];
                        }
                        else
                        {
                            canvasDrawLayerBitmapData.draw(canvasDrawLayerChild,null,null,"layer");
                        }

                        canvasDrawLayerBitmap.bitmapData = canvasDrawLayerBitmapData;
                        updateCanvasDrawLayerCliprect();
                        canvasDrawLayerChild.graphics.clear();

                        lineStyleReady(xShape,xSize,xColor,xAlpha);

                        const prevX:Number = penPoints[penPoints.length-4];
                        const prevY:Number = penPoints[penPoints.length-3];
                        penCommand.length = 0;
                        penPoints.length = 0;
                        rDataBuffer.push(["tempDone4"]);
                        //TODO: write object를 쓰지 않고 원시 데이터를 써서 리플레이를 빠르고 효율적이게 다시 쓸수있을것같음

                        if(xShape === true)
                        {
                            rDataBuffer.push(["lineStyle5",xShape,xSize,xColor,xAlpha,prevX,prevY,xBlendMode,false,isLayer2Selected,airBrushSizeDrawMode]);
                            penCommand.push(1);
                            penPoints.push(prevX);
                            penPoints.push(prevY);
                            canvasDrawLayerChild.graphics.moveTo(prevX,prevY);
                        }
                        else
                        {
                            rDataBuffer.push(["lineStyle5",xShape,xSize,xColor,xAlpha,mx,my,xBlendMode,false,isLayer2Selected,airBrushSizeDrawMode]);
                            penCommand.push(1);
                            penPoints.push(mx);
                            penPoints.push(my);
                            canvasDrawLayerChild.graphics.moveTo(mx,my);
                        }
                    }

                    if(xShape === true || sq1PXCursor === true)
                    {
                        const rad:Number = Math.atan2(mx-sqPenCursorLast.x,my-sqPenCursorLast.y);
                        const deg:Number = -rad*(180/Math.PI)+canvasAnchorPoint.rotation;

                        penSizePreviewCursor.rotation = deg;
                        sqPenCursorLast.x = mx;
                        sqPenCursorLast.y = my;
                    }

                    if(Point.distance(clickPos,moveEvent2Last) >= 0.2)
                    {
                        dotflag = false;
                    }
                }
            }

            function penToolMouseMoveLimit(mx:Number,my:Number):Boolean
            {
                moveEventDistSave.setTo(mx,my);
                const dist:Number = Point.distance(moveEventDistSave,moveEventLast);

                //브러쉬 크기 제한보다 작게 움직였을때 무시
                //브러시 크기에 따라서 짧은 선들의 집합으로 그림 사각펜에서 선을 안정화시킴
                if(dist < lastMouseMoveDist)
                {
                    lastMouseMoveDist = lastMouseMoveDist-dist;

                    if(lastMouseMoveDist <= 0)
                    {
                        lastMouseMoveDist = xSize/5;
                    }
                    return true;
                }

                lastMouseMoveDist = lastMouseMoveDist-dist;
                if(lastMouseMoveDist <= 0)
                {
                    lastMouseMoveDist = xSize/5;
                }

                moveEventLast.setTo(mx,my);
                return false;
            }

            function onMouseMovePenTool(e:MouseEvent):void
            {
                var filteredPos:Point = getFilteredPos(canvasDrawLayerChild.mouseX,canvasDrawLayerChild.mouseY);
                const mx:Number = filteredPos.x;
                const my:Number = filteredPos.y;

                if(penToolMouseMoveLimit(mx,my))
                {
                    return;
                } 

                if(penToolFlag && penSmoothSlideValue > 1)
                {
                    var ox:Number = smoothPos.x;
                    var oy:Number = smoothPos.y;

                    ox += (smoothLast.x-smoothPos.x)*penSmoothValue;
                    oy += (smoothLast.y-smoothPos.y)*penSmoothValue;

                    processPenToolMove(ox,oy);
                    smoothPos.setTo(ox,oy);
                    smoothLast.setTo(mx,my);

                    addTimerByName("lineSmoothingTimer",0.03,false,lineSmoothing);
                }
                else
                {
                    processPenToolMove(mx,my);
                    smoothPos.setTo(mx,my);
                }
            }

            function onMouseUpPenTool(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpPenTool);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMovePenTool);

                if(penToolFlag && isRefLayerMemoryTrainingON && refLayerLastAlpha > 0.0)
                {
                    setCanvasRefLayerVisibleWithFading();
                }

                if(penSmoothSlideValue > 1)
                {
                    removeTimer("lineSmoothingTimer");
                }

                if(xShape === true)
                {
                    penSizePreviewCursor.rotation = 0;

                    if(isMouseMoved === true)
                    {
                        const pointLen:uint = penPoints.length;
                        if(pointLen >= 4)
                        {
                            updateExtendEndPoint(penPoints[pointLen-4],penPoints[pointLen-3],penPoints[pointLen-2],penPoints[pointLen-1],xSize/8);
                            rDataBuffer.push(["lineTo",extendedPos.x,extendedPos.y]);
                            canvasDrawLayerChild.graphics.lineTo(extendedPos.x,extendedPos.y);
                        }
                    }
                }

                if(isMouseMoved === false || (penToolFlag && isMouseMoved === true && dotflag))
                {
                    rDataBuffer = [];
                    rDataBuffer.push(["dot4",xShape,xSize,xColor,xAlpha,clickPos.x,clickPos.y,xBlendMode,isLayer2Selected,airBrushSizeDrawMode,canvasAnchorPoint.rotation]);
                    dotTool(xShape,xSize,xColor,clickPos.x,clickPos.y,canvasAnchorPoint.rotation);
                    resetCanvasDrawLayerCliprect();
                }

                penCommand.length = 0;
                penPoints.length = 0;
                drawDone();
            }

            return function(penFlag:Boolean):void
            {
                penToolFlag = penFlag;

                if(penToolFlag)
                {
                    xSize = penSize;
                    xAlpha = penAlpha;
                    xShape = penIsSquare;
                    xAirBrushON = isPenAirBrushON;
                    dotflag = true;

                    if(isTransparentPenColor)
                    {
                        xColor = CANVAS_BG_COLOR;
                        xBlendMode = "erase";
                    }
                    else
                    {
                        xColor = penColor;
                        xBlendMode = null;

                        if(!isCurrentColorSamePickedColor())
                        {
                            updatePickerCurrentColor(colorPickerBox.getRGBInfoBGColor());
                            addColorMyPaletteHistory(colorPickerBox.getRGBInfoBGColor());
                        }
                    }
                }
                else
                {
                    xSize = eraserSize;
                    xColor = CANVAS_BG_COLOR;
                    xAlpha = eraserAlpha;
                    xShape = eraserIsSquare;
                    xBlendMode = "erase";
                    xAirBrushON = isEraserAirBrushON;
                }

                if(xSize === 1)
                {
                    sq1PXCursor = true;
                    xShape = false;
                }
                else
                {
                    sq1PXCursor = false;
                }

                if(penFlag && isRefLayerMemoryTrainingON)
                {
                    // setCanvasRefLayerVisibleWithFading(false);
                    canvasRefLayer.visible = false;
                }

                offsetForSharpline = getSharpLinePosOffset(xSize);
                mouseMoveCount = 0; //마우스 이벤트에서 움직일때 올려주는 카운터 한번에 너무 많이 움직여주면 cpu부하 먹어서 100카운트 마다 bmp에 그려줌
                isMouseMoved = false;
                canvasSizeRect.width = CANVAS_WIDTH;
                canvasSizeRect.height = CANVAS_HEIGHT;
                resetCanvasDrawLayerCliprect();
                const filteredPos:Point = getFilteredPos(canvasDrawLayerChild.mouseX,canvasDrawLayerChild.mouseY);

                clickPos.copyFrom(filteredPos); //점찍어 줄 때 판단하는 클릭한 자리 저장
                smoothPos.copyFrom(filteredPos);
                smoothLast.copyFrom(filteredPos); //penmove할때 마지막x y저장
                moveEventLast.copyFrom(filteredPos);

                if(xShape === true)
                {
                    sqPenCursorLast.copyFrom(smoothPos);
                    sqLinePosLast.copyFrom(smoothPos);
                }

                lastMouseMoveDist = xSize/5;//penmove에서 distlimit이하이면 jump해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌

                if(canAddUndoData === false)
                {
                    setCanUndoDataFlagON();
                }
                canvasDrawLayerChild.filters = [];

                stage.addEventListener(MouseEvent.MOUSE_MOVE,onMouseMovePenTool);
                stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpPenTool);
            };
        }

        public function onMouseLeaveStage(e:Event):void
        {
            isMouseClicked = false;
            isRightMouseClicked = false;
            isMouseDragging = false;
            penSizePreviewCursor.visible = false;
        }

        public function onMouseMoveUpdatePenPreviewCursor(e:MouseEvent):void
        {
            if(isReplayModeON || isCaptureModeON) return;

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
                cursorSize = size*canvasZoomMultipler;
            }

            function updateZoom(z:Number):void
            {
                if(isSelectedToolPenOrLine())
                {
                    cursorSize = penSize*canvasZoomMultipler;
                }
                else if(isSelectedTool(TOOL_ERASER))
                {
                    cursorSize = eraserSize*canvasZoomMultipler;
                }
                else
                {
                    cursorSize = 0;
                }
            }

            function checkCursorVisibility():void
            {
                if(cursorSize <= 4 || isSelectedTool(TOOL_FILL_PEN))
                {
                    if(penSizePreviewCursor.visible)
                    {
                        penSizePreviewCursor.visible = false;
                    }
                }
                else if(penSizePreviewCursor.visible === false)
                {
                    penSizePreviewCursor.visible = true;
                }
            }

            function check():void
            {
                const mx:Number = stage.mouseX;
                const my:Number = stage.mouseY;

                //아마 이거 preview커서 박스 커서가 커져서 sidebar 바운더리가 커졌을때
                //제대로 확인못해서 썼던걸거임
                // || (!quickSidebarON && !isCursorInDrawArea())
                //(sideBar.visible && (sideBarScrollBar.hitTestPoint(mouseX,mouseY) || sideBar.hitTestPoint(mouseX,mouseY)))
                
                if(isPenSizeCursorInvisible
                || (nowTool > TOOL_LINE && nowTool !== TOOL_FILL_PEN) //1 2 3 4 펜 지우개 라인툴 라인-지우개툴
                || !isCursorInDrawArea()
                || resizeCanvas.isCanvasResizing()
                || (refLayerMenuBox.visible && refLayerMenuBox.hitTestPoint(stage.mouseX, stage.mouseY))
                || loadMenuBox.visible)
                {
                    penSizePreviewCursor.visible = false;
                }
                else
                {
                    //addundo플래그가 커서가 캔버스 안에 들어올때 해주기 때문에 위치를 계속 갱신해줘야함
                    penSizePreviewCursor.x = mx;
                    penSizePreviewCursor.y = my;
                    checkCursorVisibility();
                }
            }

            return {
                check:check,
                updateZoom:updateZoom,
                updateCursorSize:updateCursorSize,
                checkCursorVisibility:checkCursorVisibility
            };
        }

        public function cRealWorkingTimer():Object
        {
            var workingTimer:Timer = new Timer(1000);
            var workingTime:int = 0;
            var lastTime:int = 0; //마지막 시간 저장해줌
            //시간 표시 관련 변수
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
                topBar.timer.text = "00:00:00";
                topBar.updateTimerPos(stage.stageWidth);
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
                if(workingTime < 0)
                {
                    workingTime = 0;
                }

                tt = workingTime/1000;
                hh = Math.floor(tt/3600);
                mm = Math.floor((tt-hh*3600)/60);
                ss = Math.floor(tt%60);

                topBar.timer.text =      ((hh < 10) ? "0"+hh:""+hh)
                                    +":"+((mm < 10) ? "0"+mm:""+mm)
                                    +":"+((ss < 10) ? "0"+ss:""+ss);

                topBar.timerAFkDot.visible = false;
                topBar.updateTimerPos(stage.stageWidth);
            }

            function onTimer():Boolean
            {
                const nowTime:int = getTimer();
                const subTime:int = nowTime-lastTime;

                if(!stage.nativeWindow.active
                || (!isMouseClicked && !isRightMouseClicked && !isKeyPressed()
                    && stage.mouseX === lastMousePosX && stage.mouseY === lastMousePosY))
                {
                    topBar.timerAFkDot.visible = !topBar.timerAFkDot.visible;
                    topBar.updateTimerPos(stage.stageWidth);
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
                if(workingTimer !== null)
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
                start:start,
                stop:stop,
                reset:reset,
                update:update,
                getRunningTime:getRunningTime,
                setRunningTime:setRunningTime
            }
        }

		public function initializeCaptureModeTransparentBG():void
        {
            const halfSize:Number = Math.floor(capTransparentBGBMPDSize/2);
            capTransparentBGBMPD = new BitmapData(capTransparentBGBMPDSize,capTransparentBGBMPDSize,false,0xFFFFFF);
            capTransparentBGBMPD.fillRect(new Rectangle(0,0,halfSize,halfSize),0xC8C8C8);
            capTransparentBGBMPD.fillRect(new Rectangle(halfSize,halfSize,halfSize,halfSize),0xCCCCCC);
        }

        
        public function restoreZoomReplayMode():void
        {
            rCanvasZoomIndex = getNearZoomIndex(rLastCanvasZoomMultiplier);
            updateCanvasScale(canvasZoomMultiplerList[rCanvasZoomIndex],true);
            rFollowMouse.updateBounds();
        }

        public function resetZoomReplayMode():void
        {
            const center:Point = getStageCenterPos("replay");

            rLastCanvasZoomMultiplier = 1.0;
            rCanvasZoomIndex = canvasZoomMultiplerList.indexOf(1.0);
            moveCanvasAnchorPoint(center.x,center.y,true);
            updateCanvasScale(1.0,true);
            setFitReplayCanvasToWindowOFF();
            rFollowMouse.updateBounds();
        }

        public function resetZoomDrawMode():void
        {
            if(canvasZoomMultipler !== 1.0)
            {
                const center:Point = getStageCenterPos("draw");
                const gcenter:Point = canvasPanel.globalToLocal(new Point(center.x,center.y));
                const gp:Point = canvasPanel.localToGlobal(new Point(0,0));
                const panelLimitedPos:Point = getCanvasBoundLimitPoint(canvasPanel,gcenter.x,gcenter.y,CANVAS_WIDTH,CANVAS_HEIGHT,canvasAnchorPoint.scaleY,-canvasAnchorPoint.rotation);
                moveCanvasAnchorPoint(panelLimitedPos.x+gp.x,panelLimitedPos.y+gp.y,false);

                canvasZoomIndex = canvasZoomMultiplerList.indexOf(1.0);
                updateCanvasScale(1.0,false);
                updatePenSizeCursor();
                updateCanvasNaigatorCursor();
                drawGrid();
            }
        }

        public function zoomInCanvas(zoomInFlag:Boolean,replayMode:Boolean):void
        {
            const xAnc:Sprite = (replayMode) ? rCanvasAnchorPoint : canvasAnchorPoint;
            const zoomMax:int = canvasZoomMultiplerList.length-1;
            var center:Point;
            var newZoomIndex:int = (replayMode) ? rCanvasZoomIndex : canvasZoomIndex;

            if(zoomInFlag)
            {
                newZoomIndex++;
                if(newZoomIndex > zoomMax)
                {
                    newZoomIndex = zoomMax;
                }
            }
            else
            {
                newZoomIndex--;
                if(newZoomIndex < 0)
                {
                    newZoomIndex = 0;
                }
            }

            const newZoom:Number = canvasZoomMultiplerList[newZoomIndex];

            if(replayMode)
            {
                center = getStageCenterPos("replay");
                rLastCanvasZoomMultiplier = newZoom;
                setFitReplayCanvasToWindowOFF();
                rCanvasZoomIndex = newZoomIndex;
                moveCanvasAnchorPoint(center.x,center.y,true);
                updateCanvasScale(newZoom,replayMode);
                rFollowMouse.updateBounds();
            }
            else
            {
                center = getStageCenterPos("draw");
                const gcenter:Point = canvasPanel.globalToLocal(new Point(center.x,center.y));
                const gp:Point = canvasPanel.localToGlobal(new Point(0,0));
                const panelLimitedPos:Point = getCanvasBoundLimitPoint(canvasPanel,gcenter.x,gcenter.y,CANVAS_WIDTH,CANVAS_HEIGHT,xAnc.scaleY,-xAnc.rotation);

                canvasZoomIndex = newZoomIndex;
                moveCanvasAnchorPoint(panelLimitedPos.x+gp.x,panelLimitedPos.y+gp.y,false);
                updateCanvasScale(newZoom,replayMode);
                updatePenSizeCursor();
                updateCanvasNaigatorCursor();

                if(gridGapValue > 0)
                {
                    drawGrid();
                }
            }
        }

        public function checkKeyUp(keyCode:uint):void
        {
            if(KEY_BUFFER.length === 0) resetLastKey();
            else if(!isCaptureModeON && !isReplayModeON && isLastKey(keyCode)) onKeyDownLassoTool(null);
        }

        public function onKeyUpLassoTool(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;
            if(isLassoMenuHiddenTemp && !isMouseClicked)
            {
                isLassoMenuHiddenTemp = false;
            }

            checkKeyUp(keyCode);
        }

        public function onKeyDownLassoTool(e:KeyboardEvent):void
        {
            if(isMouseClicked || isRightMouseClicked || isMouseDragging)
            {
                return;
            }

            const keyCode:uint = getFirstPressedKey();

            if(keyCode === KEY.space)
            {
                if(checkSubKey(2,true,function(input:int):void
                {
                    switch(input)
                    {
                        case KEY.w:
                        case KEY.i:
                        {
                            move1PxLassoTool(LASSO_1PX_MOVE_UP);
                        }
                        break;

                        case KEY.a:
                        case KEY.j:
                        {
                            move1PxLassoTool(LASSO_1PX_MOVE_LEFT);
                        }
                        break;

                        case KEY.s:
                        case KEY.k:
                        {
                            move1PxLassoTool(LASSO_1PX_MOVE_DOWN);
                        }
                        break;

                        case KEY.d:
                        case KEY.l:move1PxLassoTool(LASSO_1PX_MOVE_RIGHT); break;
                    }
                }))
                {
                    return;
                }

                if(isLastKey(keyCode))
                {
                    return;
                }
                updateLastKey(keyCode);

                isLassoMenuHiddenTemp = true;
                setToolIndex(TOOL_HAND);
            }
            else if(isPressingShift())
            {
                if(checkSubKey(2,true,function(input:int):void
                {
                    switch(input)
                    {
                        case KEY.s:
                        case KEY.k:
                            if(canvasAnchorPoint.rotation !== 0.0) resetRotationDrawMode();
                        return;

                        case KEY.w:
                        case KEY.i:
                            if(canvasZoomMultipler !== 1.0) resetZoomDrawMode();
                        return;
                    }
                }))
                {
                    return;
                }
            }

            if(isLastKey(keyCode))
            {
                return;
            }
            updateLastKey(keyCode);

            switch(keyCode)
            {
                case KEY.tab:
                case KEY.backslash:
                {
                    if(isSidebarVisible)
                    {
                        hideSidebarPermanent();
                    }
                    else
                    {
                        showSidebarPermanent();
                    }
                }
                break;

                case KEY.w:
                case KEY.i:
                {
                    isLassoMenuHiddenTemp = true;
                    updateLastKey(keyCode);
                    setToolIndex(TOOL_ZOOM);
                }
                break;

                case KEY.s:
                case KEY.k:
                {
                    isLassoMenuHiddenTemp = true;
                    updateLastKey(keyCode);
                    setToolIndex(TOOL_ROTATE);
                }
                break;

                case KEY.enter:
                {
                    applyLassoImageToCanvas();
                }
                break;

                case KEY.f3:
                {
                    toggleSideBarPosition();
                }
                break;

                case KEY.esc:
                case KEY.backspace:
                {
                    cancelLassoTool();
                }
                break;
            }
        }

        public function toggleSideBarPosition():void
        {
            if(isRightSidebar === false)
            {
                isRightSidebar = true;
                moveSideBar("right");
            }
            else if(isRightSidebar === true)
            {
                isRightSidebar = false;
                moveSideBar("left");
            }
        }

        public function updateCanvasNaigatorCursor():void
        {
            var newRightOffset:Number = 0;
            var newLeftOffset:Number = 0;

            if(isSidebarVisible === true)
            {
                newRightOffset = STAGE_RIGHT_OFFSET;
                newLeftOffset = STAGE_LEFT_OFFSET;

                if(isRightSidebar)
                {
                    newRightOffset = Math.round(sideBar.getWidth());
                }
                else
                {
                    newLeftOffset = Math.round(sideBar.getWidth());
                }
            }

            const gp:Point = canvasLayer1Bitmap.globalToLocal(new Point(newLeftOffset,STAGE_TOP_OFFSET));
            const zoom:Number = canvasZoomMultipler;
            canvasNavigatorBox.updateCursor(gp.x*zoom,gp.y*zoom
                                    ,stage.stageWidth-newRightOffset-newLeftOffset
                                    ,stage.stageHeight-STAGE_TOP_OFFSET-STAGE_BOTTOM_OFFSET
                                    ,CANVAS_WIDTH*zoom,canvasAnchorPoint.rotation);
        }

        public function startCanvasMoveByCanvasNavigator(navCursorClicked:Boolean):void
        {
            var sx:Number = canvasNavigatorBox.mouseX;
            var sy:Number = canvasNavigatorBox.mouseY;

            const prevCursorScale:Number = canvasNavigatorBox.navCursorMultiply;
            const uiScale:Number = Global.getUIScale();

            setRefLayerAndGridVisible(false);
            hideBottomHint();

            function centerCanvas(mx:Number,my:Number):void
            {
                const b:Object = getBoundRect(canvasNavigatorBox.navCursor);
                const scale:Number = Global.getUIScale();
                //prevToCanvasMultiply를 나눠 줘야 커서랑 같은 속도가 나옴
                const rectCenterX:Number = b.left+(b.right-b.left)/2;
                const rectCenterY:Number = b.top+(b.bottom-b.top)/2;
                var moveX:Number = (rectCenterX-mx)/prevCursorScale/uiScale;
                var moveY:Number = (rectCenterY-my)/prevCursorScale/uiScale;
                var p:Point = rotatePoint(moveX,moveY,-canvasAnchorPoint.rotation);

                canvasAnchorPoint.x += Math.round(p.x);
                canvasAnchorPoint.y += Math.round(p.y);

                updateCanvasNaigatorCursor();
            }

            function onMouseUpCanvasNavigator(e:MouseEvent):void
            {
                setRefLayerAndGridVisible(true);
                keepCnvasPanelInStage();
                updateCanvasNaigatorCursor();
                isMouseDragging = false;

                if(isLassoToolStarted)
                {
                    if(isLassoMenuHiddenTemp === true)
                    {
                        hideLassoMenuBoxTemp();
                    }
                }

                stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveCanvasNavigator);
                stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUpCanvasNavigator);
            }

            function onMouseMoveCanvasNavigator(e:MouseEvent):void
            {
                const scale:Number = Global.getUIScale();
                var mx:Number = canvasNavigatorBox.mouseX;
                var my:Number = canvasNavigatorBox.mouseY;
                //previewBox.prevCursorMultiply를 곱해줘야 커서랑 같은 속도가 나옴
                var moveX:Number = (sx-mx)/prevCursorScale;
                var moveY:Number = (sy-my)/prevCursorScale;
                var p:Point = rotatePoint(moveX,moveY,-canvasAnchorPoint.rotation);

                canvasAnchorPoint.x += Math.round(p.x);
                canvasAnchorPoint.y += Math.round(p.y);

                sx = mx;
                sy = my;

                updateCanvasNaigatorCursor();
            }
            moveCanvasAnchorPoint(0,0);

            if(isLassoToolStarted)
            {
                lassoMenuBox.visible = false;
                isLassoMenuHiddenTemp = true;
            }

            //클릭한 지점이 커서 바깥부분일때 강제로 캔버스 중심으로 옮겨줌
            if(!navCursorClicked)
            {
                centerCanvas(stage.mouseX,stage.mouseY);
            }

            stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpCanvasNavigator)
            stage.addEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveCanvasNavigator)
        }
        //원점 penSmoothX oy로부터 dx쪽으로 dist 만큼 떨어진 거리 점을 리턴함
        public function movePointAngleDist(ox:Number,oy:Number,dx:Number,dy:Number,dist:Number):Point
        {
            const rad:Number = Math.atan2(dx-ox,dy-oy);

            return new Point(ox+dist*Math.sin(rad)
                            ,oy+dist*Math.cos(rad));
        }

        public function ensureDrawingToolSelected(checkErase:Boolean):void
        {
            if(!(isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILL_PEN)
            || (checkErase && isSelectedTool(TOOL_ERASER))))
            {
                resetOldTool();
                selectPenTool();
                updatePenSizeCursor();
            }
        }

        public function handleOneMoreClickMergeIntoRefLayer(menuBox:DisplayObject,button:SimpleButton,hintstr:String,func:Function):void
        {
            setAsTopChild(menuBox);
            refLayerMenuConfirmCount++;

            function onMouseOutCancel(e:MouseEvent):void
            {
                button.removeEventListener(MouseEvent.MOUSE_OUT,onMouseOutCancel);
                refLayerMenuConfirmCount = 0;
            }

            if(refLayerMenuConfirmCount === 1)
            {
                menuBox["hint"](STRING_ONEMORE_CLICK_TO_OK);
                button.addEventListener(MouseEvent.MOUSE_OUT,onMouseOutCancel);
            }
            else if(refLayerMenuConfirmCount === 2)
            {
                button.removeEventListener(MouseEvent.MOUSE_OUT,onMouseOutCancel);
                refLayerMenuConfirmCount = 0;

                menuBox["hint"](hintstr);
                func();
            }
        }

        public function mergeLassoImageIntoToRefLayer():void
        {
            handleOneMoreClickMergeIntoRefLayer(
            lassoMenuBox,
            lassoMenuBox.lassoRefLayer,
            STRING_MERGE_LASSO_IMAGE_TO_REFLAYER,
            function():void
            {
                mergeLassoImageToRefLayer();
                openRefLayerMenu();
            });
        }

        public function mergeCanvasImageIntoRefLayer():void
        {
            if(refLayerMenuBox.refTransferCanvasImageButton.alpha !== 1.0)
            {
                return;
            }

            handleOneMoreClickMergeIntoRefLayer(
            refLayerMenuBox,
            refLayerMenuBox.refTransferCanvasImageButton,
            STRING_MERGE_CANVAS_IMAGE_TO_REFLAYER,
            mergeCanvasImageToRefLayer);
        }

        public function onMouseOverRefLayerMenuHint(e:MouseEvent):void
        {
            if(!isRefLayerMenuON)
            {
                stage.removeEventListener(MouseEvent.MOUSE_OVER,onMouseOverRefLayerMenuHint);
                return;
            }

            if(refLayerMenuBox.hitTestPoint(stage.mouseX,stage.mouseY) === false)
            {
                if(refLayerMenuBox.getHintStr() !== "Reference layer")
                {
                    refLayerMenuBox.hint("Reference layer");
                }

                return;
            }

            if(isMouseDragging === true)
            {
                return;
            }

            const targetName:String = e.target.name;
            var str:String = "";

            switch(targetName)
            {
                case "refMenuCloseButton":str = "Close [esc, backspace, t]"; break;
                case "refTransferCanvasImageButton":str = STRING_MERGE_CANVAS_IMAGE_TO_REFLAYER; break;
                case "refLoadImageButton":str = "Load image"; break;
                case "refClipBoardButton":str = "Load clipboard image"; break;
                case "refOpacitySliderWrapper":str = "Adjust image opacity"; break;
                case "refRotateImageButton":str = "Rotate image\n"+STRING_RIGHT_CLICK_TO_RESET; break;
                case "refMoveImageButton":str = "Move image\n"+STRING_RIGHT_CLICK_TO_RESET; break;
                case "refResizeImageButton":str = "Resize image\n"+STRING_RIGHT_CLICK_TO_RESET; break;
                case "refMirrorImageButton":str = "Flip image"; break;
                case "refMemoryTrainingOnButton":
                case "refMemoryTrainingOffButton":str = "Memory training ON/OFF"; break;
                case "refClearImageButton":str = "Erase reference image\n[click and hold]"; break;
                default:
                    refLayerMenuBox.hint("Reference layer");
                return;
            }

            refLayerMenuBox.hint(str);
        }

        public function getLassoMenuHintSwapLayer():String
        {
            if(isLassoLayerSwapButtonClicked) return "Swap layers 2 <-> 1";

            return "Swap layers 1 <-> 2";
        }

        public function lassoMenuHintONEvent(e:MouseEvent):void
        {
            if(!isLassoToolStarted)
            {
                stage.removeEventListener(MouseEvent.MOUSE_OVER,lassoMenuHintONEvent);
                return;
            }

            if(lassoMenuBox.hitTestPoint(stage.mouseX,stage.mouseY) === false)
            {
                if(lassoMenuBox.getHintStr() !== "Lasso tool")
                {
                    lassoMenuBox.hint("Lasso tool");
                }
                return;
            }

            if(isMouseDragging === true)
            {
                return;
            }

            const targetName:String = e.target.name;
            var str:String = "Lasso tool";

            switch(targetName)
            {
                case "lassoOK":str = "OK [enter, right-click]"; break;
                case "lassoCancel":str = "Cancel [esc, backspace]"; break;
                case "lassoCopy":str = "Copy image"; break;
                case "lassoRotate":str = "Rotate image\n"+STRING_RIGHT_CLICK_TO_RESET; break;
                case "lassoMirror":str = "Flip image"; break;
                case "lassoResize":str = "Resize image\n"+STRING_RIGHT_CLICK_TO_RESET; break;
                case "lassoRefLayer":str = STRING_MERGE_LASSO_IMAGE_TO_REFLAYER; break;
                case "lasso1pxLeft":
                case "lasso1pxRight":
                case "lasso1pxUp":
                case "lasso1pxDown": str = "Move image 1px\n[space+wasd / ijkl]"; break;
                case "lassoLayerMerge": str = "Merge image to layer 2"; break;
                case "lassoLayerSwap": str = getLassoMenuHintSwapLayer(); break;
                default: break;
            }

            lassoMenuBox.hint(str);
        }

        public function onMouseOverToolBox2Hint(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;

            if(!target || target.alpha < 1.0)
            {
                return;
            }

            const hintStr:String = HintStrings.getHintFromTargetName(target.name);

            toolBox2.hint((hintStr === null) ? "Tools" : hintStr);
        }

        public function updateTopBarModeIcons(mode:String):void
        {
            if(isLassoToolStarted === true || isAboutBoxOpened === true)
            {
                return;
            }

            setAsTopChild(topBar);

            topBar.hideUpdateButton();

            if(mode === "draw")
            {
                topBar.showModeIcons("draw",isRightSidebar,isSidebarVisible);
                topBar.hideModeIcons("replay");
                topBar.hideModeIcons("capture");
                updatePenSizeCursor();
                if(appUpdateStatus !== UPDATE_NONE)
                {
                    topBar.showUpdateButton();
                }

                if(isCanvasWindowON) topBar.newWindowButton.visible = false;
                else topBar.newWindowCloseButton.visible = false;
            }
            else if(mode === "replay")
            {
                topBar.showModeIcons("replay");
                topBar.hideModeIcons("draw");
                topBar.hideModeIcons("capture");

                if(isReplayStarted)
                {
                    replayTimelineBox.playButton.visible = false;
                    replayTimelineBox.pauseButton.visible = true;
                }
                else
                {
                    replayTimelineBox.playButton.visible = true;
                    replayTimelineBox.pauseButton.visible = false;
                }
            }
            else if(mode === "capture")
            {
                topBar.showModeIcons("capture");
                topBar.hideModeIcons("replay");
                topBar.hideModeIcons("draw");

                if(canvasLayer1Bitmap.visible)
                {
                    topBar.capLayer1VisibleButton.alpha = 1.0;
                }
                else
                {
                    topBar.capLayer1VisibleButton.alpha = Global.OFFALPHA;
                }

                if(canvasLayer2Bitmap.visible)
                {
                    topBar.capLayer2VisibleButton.alpha = 1.0;
                }
                else
                {
                    topBar.capLayer2VisibleButton.alpha = Global.OFFALPHA;
                }

                updateCaptureStampButtonAlpha();
            }
        }

        public function getGridGapHint():String
        {
            return gridGapValue+GRID_GAP +"px";
        }

        public function resetGrid():void
        {
            lastGridGapValue = 0;
            gridGapValue = 0;
            gridButton.setCursorPosByValue(0);
            clearGrid();
        }

        public function clearGrid():void
        {
            lastGridGapValue = 0;
            topBar.setGridMoveButtonAlpha(Global.OFFALPHA);
            canvasGrid.visible = false;
            canvasGrid.graphics.clear();
        }

        public function drawGrid():void
        {
            if(gridGapValue === 0)
            {
                clearGrid();
                return;
            }

            var gridgap:Number = gridGapValue*GRID_GAP;
            if(gridgap*canvasZoomMultipler < gridgap)
            {
                gridgap = gridgap/canvasZoomMultipler;
            }

            if(gridgap !== lastGridGapValue)
            {
                lastGridGapValue = gridgap;

                const gridWidth:Number = CANVAS_WIDTH;
                const gridHeight:Number = CANVAS_HEIGHT;
                const offsetX:Number = gridDrawOffsetX;
                const offsetY:Number = gridDrawOffsetY;

                var i:uint = 1;
                var len:Number = Math.floor(gridHeight/gridgap+0.5);//가로선 횟수 w, h반대되는거 맞음

                if(offsetY < 0) len += 1;
                else if(offsetY > 0) i = 0;

                gridGraphicsCommands.length = 0;
                gridGraphicsData.length = 0;

                //가로선
                for(;i<=len;i++)
                {
                    gridGraphicsCommands.push(1);
                    gridGraphicsCommands.push(2);
                    gridGraphicsData.push(0);
                    gridGraphicsData.push(gridgap*i+offsetY);
                    gridGraphicsData.push(gridWidth);
                    gridGraphicsData.push(gridgap*i+offsetY);
                }

                i = 1;
                len = Math.floor(gridWidth/gridgap+0.5); //세로선 횟수

                if(offsetX < 0) len += 1;
                else if(offsetX > 0) i = 0;

                //세로선
                for(;i<=len;i++)
                {
                    gridGraphicsCommands.push(1);
                    gridGraphicsCommands.push(2);
                    gridGraphicsData.push(gridgap*i+offsetX)
                    gridGraphicsData.push(0);
                    gridGraphicsData.push(gridgap*i+offsetX);
                    gridGraphicsData.push(gridHeight);
                }
            }

            canvasGrid.graphics.clear();
            canvasGrid.graphics.lineStyle(1/canvasZoomMultipler,GRID_NORMAL_COLOR,0.5,false);
            canvasGrid.graphics.drawPath(gridGraphicsCommands,gridGraphicsData);

            updateGridMirror(isCanvasMirrored);
            canvasGrid.cacheAsBitmap = true;
            canvasGrid.visible = true;
        }

        public function cGridFunc():Object
        {
            const minDist:Number = topBar.gridSlider.x+1.5;
            const maxDist:Number = minDist+topBar.gridSlider.width-2.5;
            const step:Number = 20;
            const div:Number = (maxDist-minDist)/step;
            var oldValue:Number;

            function setCursorPosByValue(value:Number):void
            {
                topBar.gridSliderCursor.x = value*div+minDist;
            }

            function drawGridByValue(mx:Number,initFlag:Boolean):void
            {
                if(mx < minDist) 
                {
                    mx = minDist;
                }
                else if(mx > maxDist) 
                {
                    mx = maxDist;
                }

                const value:Number = Math.floor((mx-minDist)/div);

                if(oldValue !== value || initFlag)
                {
                    setCursorPosByValue(value);

                    if(value === 0)
                    {
                        gridGapValue = 0;
                        oldValue = 0;
                        hideBottomHint();
                        clearGrid();
                        return;
                    }
                    else
                    {
                        if(topBar.isGridMoveButtonOFFAlpha()) topBar.setGridMoveButtonAlpha(1.0);

                        //변한 크기만큼 오프셋도 변화시켜줌
                        if(oldValue > 0 && value > 0)
                        {
                            gridDrawOffsetX = gridDrawOffsetX*(value/oldValue);
                            gridDrawOffsetY = gridDrawOffsetY*(value/oldValue);
                        }

                        gridGapValue = value;
                        oldValue = value;
                        showMouseHintTemp("Grid " + (gridGapValue*GRID_GAP)+"px ("+gridGapValue+"/20)");

                        drawGrid();
                    }
                }

                setAsTopChild(canvasGrid);
            }

            function onMouseUpGridButton(e:MouseEvent):void
            {
                isMouseDragging = false;
                stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUpGridButton);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveGridButton);
            }

            function onMouseMoveGridButton(e:MouseEvent):void
            {
                var mx:Number = topBar.gridSliderWrapper.mouseX;

                if(mx < minDist)
                {
                    mx = minDist;
                }
                else if(mx > maxDist) 
                {
                    mx = maxDist;
                }

                drawGridByValue(mx,false);
                showBottomHint(HintStrings.getHintFromTargetName("gridSliderWrapper"));
            }

            function repeatGridMoveByValue(moveX:Number,moveY:Number):void
            {
                startKeyRepeat(true,function():void
                {
                    gridDrawOffsetX += moveX*(isCanvasMirrored ? -1:1);
                    gridDrawOffsetY += moveY;

                    if(Math.abs(gridDrawOffsetX) >= gridGapValue*GRID_GAP) gridDrawOffsetX = 0.0;
                    if(Math.abs(gridDrawOffsetY) >= gridGapValue*GRID_GAP) gridDrawOffsetY = 0.0;

                    lastGridGapValue = 0;
                    if(gridGapValue > 0) drawGrid();
                });
            }

            function onMouseDownGridButton(e:MouseEvent):void
            {
                if(!e.target) return;
                const targetName:String = e.target.name;

                if(targetName === "gridButton" || topBar.gridButtonWrapper.hitTestPoint(stage.mouseX,stage.mouseY) === false)
                {
                    off();
                    return;
                }

                if(topBar.gridMoveButtonWrapper.hitTestPoint(stage.mouseX,stage.mouseY))
                {
                    if(e.target.alpha === 1.0)
                    {
                        var p:Point;

                        if(targetName === "gridMoveLeftButton")
                        {
                            p = rotatePoint(-1,0,canvasAnchorPoint.rotation);
                            repeatGridMoveByValue(p.x,p.y);
                        }
                        else if(targetName === "gridMoveRightButton")
                        {
                            p = rotatePoint(1,0,canvasAnchorPoint.rotation);
                            repeatGridMoveByValue(p.x,p.y);
                        }
                        else if(targetName === "gridMoveUpButton")
                        {
                            p = rotatePoint(0,-1,canvasAnchorPoint.rotation);
                            repeatGridMoveByValue(p.x,p.y);
                        }
                        else if(targetName === "gridMoveDownButton")
                        {
                            p = rotatePoint(0,1,canvasAnchorPoint.rotation);
                            repeatGridMoveByValue(p.x,p.y);
                        }
                    }
                }
                else if(topBar.gridSliderWrapper.hitTestPoint(stage.mouseX,stage.mouseY))
                {
                    isMouseDragging = true;
                    oldValue = gridGapValue;
                    drawGridByValue(topBar.gridSliderWrapper.mouseX,true);
                    stage.addEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveGridButton);
                    stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpGridButton);
                }
            }

            function onKeyUpGridButton(e:KeyboardEvent):void
            {
                if(e.keyCode === KEY.f2 || e.keyCode === KEY.f8)
                {
                    if(!(isMouseClicked || isMouseDragging))
                    {
                        if(isPressingShift())
                        {
                            if(gridGapValue !== 0)
                            {
                                hideBottomHint();
                                oldValue = 0;
                                resetGrid();
                            }
                        }
                        else
                        {
                            off();
                        }
                    }
                }
            }

            function onRightMouseDownGridButton(e:MouseEvent):void
            {
                if(!e.target) return;

                const targetName:String = e.target.name;

                if(targetName === "gridMoveLeftButton"
                || targetName === "gridMoveRightButton")
                {
                    if(gridGapValue > 0)
                    {
                        gridDrawOffsetX = 0.0;
                        lastGridGapValue = 0.0
                        if(gridGapValue > 0) drawGrid();
                    }
                }
                else if(targetName === "gridMoveUpButton"
                     || targetName === "gridMoveDownButton")
                {
                    if(gridGapValue > 0)
                    {
                        gridDrawOffsetY = 0.0;
                        lastGridGapValue = 0.0;
                        if(gridGapValue > 0) drawGrid();
                    }
                }
                else if(targetName === "gridSliderWrapper")
                {
                    if(gridGapValue !== 0)
                    {
                        hideBottomHint();
                        resetGrid();
                    }
                }
                else
                {
                    off();
                }
            }

            function off():void
            {
                hideBottomHint();
                isMouseDragging = false;
                removeKeyRepeatEvents(null);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownGridButton);
                stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUpGridButton);
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,onMouseDownGridButton);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveGridButton);
                stage.removeEventListener(KeyboardEvent.KEY_UP,onKeyUpGridButton);
                topBar.setReplaySpeedBarToGridSliderOFF(stage);
                clearKeyBuffer();
                addInputEventsDrawMode();
            }

            function start(shortcutKey:Boolean):void
            {
                if(topBar.gridButtonWrapper.visible === false)
                {
                    removeInputEventsDrawMode();

                    if(gridGapValue > 0)
                    {
                        topBar.setGridMoveButtonAlpha(1.0);
                    }
                    else
                    {
                        topBar.setGridMoveButtonAlpha(Global.OFFALPHA);
                    }

                    topBar.setReplaySpeedBarToGridSliderON(shortcutKey);
                    setCursorPosByValue(gridGapValue);

                    if(shortcutKey)
                    {
                        const p:Point = topBar.globalToLocal(new Point(stage.mouseX,stage.mouseY));
                        topBar.gridButtonWrapper.x = p.x-topBar.gridSliderWrapper.x-topBar.gridSliderCursor.x;
                        topBar.gridButtonWrapper.y = p.y-topBar.gridSliderWrapper.y-topBar.gridSliderCursor.y;
                    }

                    stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownGridButton,false,-1);
                    stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDownGridButton,false,-1);
                    stage.addEventListener(KeyboardEvent.KEY_UP,onKeyUpGridButton,false,-1);
                }
                else
                {
                    off();
                }
            }

            return {
                start:start,
                // off:off,
                setCursorPosByValue:setCursorPosByValue
            };
        }

        public function updateRefLayerOpacityCursorPosByValue(alpha:Number):void
        {
            refLayerMenuBox.refOpacityCursor.x = (refLayerMenuBox.refOpacityBar.x+1)+(refLayerMenuBox.refOpacityBar.width*alpha);
        }

        public function closeRefLayerMenu():void
        {
            isRefLayerMenuON = false;
            refLayerMenuBox.visible = false;
            refLayerMenuBox.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,onRightMouseUpRefLayerMenu);
        }

        public function onRightMouseUpRefLayerMenu(e:MouseEvent):void
        {
            if(!isRefLayerMenuON) return;

            const target:DisplayObject = e.target as DisplayObject;
            if(!target)
            {
                return;
            }

            switch(target.name)
            {
                case "refRotateImageButton":
                {
                    if(canvasRefLayer.rotation !== 0)
                    {
                        isFileAlreadySaved = false;

                        canvasRefLayer.rotation = 0;
                    }
                }
                break;

                case "refResizeImageButton":
                {
                    if(canvasRefLayer.scaleY !== 1.0)
                    {
                        isFileAlreadySaved = false;

                        canvasRefLayer.scaleX = (canvasRefLayer.scaleX < 0)? -1.0 : 1.0;
                        canvasRefLayer.scaleY = 1.0;
                    }
                }
                break;

                case "refMoveImageButton":
                {
                    if(canvasRefLayerBitmap.x !== -canvasRefLayerBitmap.width/2
                    && canvasRefLayerBitmap.y !== -canvasRefLayerBitmap.height/2)
                    {
                        isFileAlreadySaved = false;

                        canvasRefLayer.x = CANVAS_WIDTH/2;
                        canvasRefLayer.y = CANVAS_HEIGHT/2;

                        canvasRefLayerBitmap.x = -canvasRefLayerBitmap.bitmapData.width/2;
                        canvasRefLayerBitmap.y = -canvasRefLayerBitmap.bitmapData.height/2;
                    }
                }
                break;

                default:
                break;
            }
        }

        public function openRefLayerMenu():void //load clip버튼에서 눌러줬을때 틀여줌
        {
            refLayerMenuBox.hint("Reference layer");
            refLayerMenuBox.x = Math.floor(stage.mouseX-refLayerMenuBox.width/2);
            refLayerMenuBox.y = Math.floor(stage.mouseY-8);
            refLayerMenuBox.visible = true;

            setAsTopChild(refLayerMenuBox);
            keepBoxInsideViewPort(refLayerMenuBox);

            if(isRefLayerMenuON === false)
            {
                refLayerMenuBox.addEventListener(MouseEvent.RIGHT_MOUSE_UP,onRightMouseUpRefLayerMenu);
                stage.addEventListener(MouseEvent.MOUSE_OVER,onMouseOverRefLayerMenuHint);
            }

            isRefLayerMenuON = true;
            setAsTopChild(refLayerMenuBox);
        }

        public function isRefLayerImageAlreadyCleared():Boolean
        {
            return (canvasRefLayerBitmapData && canvasRefLayerBitmapData.width > 1 && canvasRefLayerBitmapData.height > 1)
                   || !canvasRefLayerBitmapData;
        }

        public function startReflayerClear():void
        {
            setAsTopChild(refLayerMenuBox);

            if(isRefLayerImageAlreadyCleared())
            {
                clearRefLayerImage();
            }

            if(isRefLayerMemoryTrainingON)
            {
                toggleRefLayerMemoryTraining();
            }
        }

        public function setCanvasRefLayerVisibleWithFading():void
        {

            var fadeStep:Number = Math.round(refLayerLastAlpha/15*256)/256;
            // if(fadeStep < 0.05)
            // {
            //     fadeStep = 0.05;
            // }

            canvasRefLayer.alpha = 0.0;
            canvasRefLayer.visible = true;

            addTimerByName("refLayerVisibleFadingTimer", 0.0, true, function (refLayer:Sprite,fadeStep:Number,maxAlpha:Number):Boolean
                {
                    canvasRefLayer.alpha += fadeStep;
                    if(canvasRefLayer.alpha >= maxAlpha)
                    {
                        canvasRefLayer.alpha = maxAlpha;
                        return false;
                    }
                    return true;
                },[canvasRefLayer,fadeStep,refLayerLastAlpha]);
        }

        public function toggleRefLayerMemoryTraining():void
        {
            if(isRefLayerMemoryTrainingON === false)
            {
                isRefLayerMemoryTrainingON = true;
                refLayerMenuBox.refMemoryTrainingOffButton.visible = false;
                refLayerMenuBox.refMemoryTrainingOnButton.visible = true;
            }
            else if(isRefLayerMemoryTrainingON === true)
            {
                isRefLayerMemoryTrainingON = false;
                refLayerMenuBox.refMemoryTrainingOffButton.visible = true;
                refLayerMenuBox.refMemoryTrainingOnButton.visible = false;
            }
        }

        public function startRefLayerImageMirror():void
        {
            var tmpbmpd:BitmapData = new BitmapData(canvasRefLayerBitmapData.width,
                                                        canvasRefLayerBitmapData.height,true,0);
            var flipMat:Matrix = new Matrix(-1,0,0,1,canvasRefLayerBitmapData.width);

            tmpbmpd.draw(canvasRefLayerBitmapData,flipMat);

            canvasRefLayerBitmapData = updateBitmapData(canvasRefLayerBitmapData,tmpbmpd,canvasRefLayerBitmap);

            tmpbmpd.dispose();
            tmpbmpd = null;

            canvasRefLayer.rotation = -canvasRefLayer.rotation;//일단 각도 대칭해주고

            //canvas1을 기준으로 중심점 거리를 구해서 x값보정과 각도 보정을 함
            const canvasCenterX:Number = canvasRefLayer.x+canvasRefLayerBitmap.x+canvasRefLayerBitmap.width/2;
            const subX:Number = Math.round((canvasRefLayer.x-canvasCenterX)*2);
            const deg:Number = canvasRefLayer.rotation-(canvasAnchorPoint.rotation)*2;

            canvasRefLayerBitmap.x = canvasRefLayerBitmap.x+subX;
            canvasRefLayer.rotation = deg;//캔버스 전체가 회전해있을때 각도보정
            canvasRefLayerBitmap.smoothing = true;
            isFileAlreadySaved = false;
        }

        public function startRefLayerRotation():void
        {
            const getangle:Function = createAngleUpdateFunctionByMouseDrag(canvasRefLayer);

            function onDragStart():void
            {
                refLayerMenuBox.visible = false;
                canvasRefLayerBitmap.smoothing = false;
            }

            function onMouseMove():void
            {   
                canvasRefLayer.rotation = getangle();
            }

            function onMouseUp():void
            {
                isFileAlreadySaved = false;
                refLayerMenuBox.visible = true;
                hideCanvasRotateCursor();
                canvasRefLayerBitmap.smoothing = true;
            }

            startDragInteraction(onDragStart,onMouseMove,onMouseUp);
        }

        public function startRefLayerImageScale():void
        {
            const getscale:Function = createScaleUpdaterFromMouseDrag(canvasRefLayer.scaleX);

            function onDragStart():void
            {
                showMouseHint(getImageScaleHint(canvasRefLayerBitmapData.width,canvasRefLayerBitmapData.height,Math.abs(canvasRefLayer.scaleX),true));
                refLayerMenuBox.visible = false;
                canvasRefLayerBitmap.smoothing = false;
            }

            function onMouseMove():void
            {
                const scale:Number = getscale(mouseX,mouseY);
                canvasRefLayer.scaleX = (canvasRefLayer.scaleX < 0) ? -scale:scale;
                canvasRefLayer.scaleY = scale;
                showMouseHint(getImageScaleHint(canvasRefLayerBitmapData.width,canvasRefLayerBitmapData.height,scale,true));
            }
            
            function onMouseUp():void
            {
                isFileAlreadySaved = false;
                refLayerMenuBox.visible = true;
                canvasRefLayerBitmap.smoothing = true;
                hideMouseHint();
            }

            startDragInteraction(onDragStart,onMouseMove,onMouseUp);
        }

        public function startRefLayerImageDrag():void
        {
            const getpos:Function = createPosUpdateFunctionByMouseDrag(canvasRefLayerBitmap,
                                                                canvasRefLayer.rotation+canvasAnchorPoint.rotation,
                                                                canvasRefLayer.scaleX,
                                                                canvasRefLayer.scaleY);
            function onDragStart():void
            {
                refLayerMenuBox.visible = false;
                canvasRefLayerBitmap.smoothing = false;
            }

            function onMouseMove():void
            {
                const pos:Point = getpos();

                canvasRefLayerBitmap.x = pos.x;
                canvasRefLayerBitmap.y = pos.y;
            }

            function onMouseUp():void
            {
                isFileAlreadySaved = false;
                refLayerMenuBox.visible = true;
                canvasRefLayerBitmap.smoothing = true;
            }

            startDragInteraction(onDragStart,onMouseMove,onMouseUp);
        }

        public function resetRefLayerMenuOpacity():void
        {
            refLayerLastAlpha = 0.5;
            canvasRefLayer.alpha = 0.5;
            updateRefLayerOpacityCursorPosByValue(0.5);
            refLayerMenuBox.hint(STRING_REFLAYER_IMAGE_OPACITY+Math.floor(0.5*100)+"%");
            canvasRefLayer.visible = true;
        }

        public function startRefLayerOpacityDrag():void
        {
            const barwidth:Number = refLayerMenuBox.refOpacityBar.width;
            const minx:Number = refLayerMenuBox.refOpacityBar.x+1;
            const maxx:Number = minx+barwidth-2;

            function onMouseMoveUpdateopacity():void
            {
                const value:Number = calculateSliderValueFromMouseX(refLayerMenuBox.mouseX,
                                                                    minx,
                                                                    maxx,
                                                                    0,
                                                                    1.0,
                                                                    refLayerMenuBox.refOpacityCursor);
                const alpha:Number = normalizeAlphaValue(value);

                if(alpha < 0.0)
                {
                    canvasRefLayer.visible = false;
                    canvasRefLayer.alpha = 0.0;
                    refLayerLastAlpha = 0.0
                }
                else
                {
                    canvasRefLayer.visible = true;
                    canvasRefLayer.alpha = alpha;
                    refLayerLastAlpha = alpha;
                }

                refLayerMenuBox.hint(STRING_REFLAYER_IMAGE_OPACITY+Math.floor(alpha*100+0.5)+"%");
            }

            function onDragStart():void
            {
                refLayerMenuBox.hint(STRING_REFLAYER_IMAGE_OPACITY+Math.floor(refLayerLastAlpha*100+0.5)+"%");
                onMouseMoveUpdateopacity();
            }

            startDragInteraction(onDragStart,onMouseMoveUpdateopacity,function():void{});
        }

        public function saveRefLayerImage():void
        {
            if(!canvasRefLayerBitmap.bitmapData) return;

            const bmpd:BitmapData = canvasRefLayerBitmap.bitmapData;//실제 보여주는 데이터를 저장해줌
            const w:Number = canvasRefLayerBitmap.width;
            const h:Number = canvasRefLayerBitmap.height;
            const fs:FileStream = new FileStream();
            var ba:ByteArray = new ByteArray();
            const newRectangle:Rectangle = new Rectangle(0,0,w,h);

            bmpd.copyPixelsToByteArray(newRectangle,ba);
            // ba.compress();
            fs.open(refLayerImageFilePath,FileMode.WRITE);
            fs.writeObject([ba,w,h]);
            fs.close();
            ba.clear();
            ba = null;
        }

        public function clearRefLayerImage():void
        {
            canvasRefLayerBitmapData.dispose();
            canvasRefLayerBitmapData = new BitmapData(1,1,true,0);
            canvasRefLayerBitmap.bitmapData = canvasRefLayerBitmapData;
            resetRefLayerImageTransform();
            canvasRefLayer.visible = false;
            canvasRefLayer.alpha = 0.0;
            refLayerLastAlpha = 0.0;
            saveRefLayerImage();
        }

        public function resetRefLayerImageTransform():void
        {
            const ww:Number = -canvasRefLayerBitmap.width/2;
            const hh:Number = -canvasRefLayerBitmap.height/2;

            canvasRefLayerBitmap.x = ww;
            canvasRefLayerBitmap.y = hh; //중점 셋팅
            canvasRefLayer.rotation = 0;
            canvasRefLayer.scaleX = 1;
            canvasRefLayer.scaleY = 1;
            refLayerMenuDragXMoveSum = 0;
        }

        public function updateRefLayerImageTransform(x:Number,y:Number,rotation:Number,scaleX:Number,scaleY:Number):void
        {
            canvasRefLayer.x = CANVAS_WIDTH/2;
            canvasRefLayer.y = CANVAS_HEIGHT/2;
            canvasRefLayerBitmap.x = x;
            canvasRefLayerBitmap.y = y;
            canvasRefLayer.scaleX = scaleX;
            canvasRefLayer.scaleY = scaleY;
            canvasRefLayer.rotation = rotation;
        }

        public function resetRefLayerOpacitySlider():void
        {
            if(canvasRefLayer.visible === false || refLayerLastAlpha === 0.0)
            {
                updateRefLayerOpacityCursorPosByValue(0.5);
                refLayerLastAlpha = 0.5;
                if(!isCaptureModeON) //캡쳐 모드에서 reflayer로드시 뒤에 배경 생겨나서
                {
                    canvasRefLayer.visible = true;
                }
                canvasRefLayer.alpha = 0.5;
            }

            canvasRefLayerBitmap.smoothing = true;
            isFileAlreadySaved = false;
        }

        public function mergeCanvasImageToRefLayer():void
        {
            if(isDeepUndoEnabled)
            {
                applyDeepUndo();
            }

            var layer1Flag:Boolean = canvasLayer1Bitmap.visible;
            var layer2Flag:Boolean = canvasLayer2Bitmap.visible;

            if(checkedLayer === 1)
            {
                layer1Flag = true;
                layer2Flag = false;
            }
            else if(checkedLayer === 2)
            {
                layer1Flag = false;
                layer2Flag = true;
            }

            mergeImageToRefLayer((layer1Flag) ? canvasLayer1BitmapData:null
                                ,(layer2Flag) ? canvasLayer2BitmapData:null);
            const rect:Rectangle = new Rectangle(0,0,canvasLayer1BitmapData.width,canvasLayer1BitmapData.height);
            var command:String = "clear";

            if(layer1Flag)
            {
                canvasLayer1BitmapData.fillRect(rect,0);
            }

            if(layer2Flag)
            {
                canvasLayer2BitmapData.fillRect(rect,0);
            }

            if((layer1Flag && !layer2Flag) || !canvasLayer2Bitmap.visible)
            {
                command = "clear1";
            }
            else if((layer2Flag && !layer1Flag) || !canvasLayer1Bitmap.visible)
            {
                command = "clear2";
            }

            if(hasLastRDataCommand(command))
            {
                undoManager.addContinue();
            }
            else
            {
                rDataBuffer = [[command]];
                undoManager.addNew();
            }

            resetRefLayerImageTransform();
            resetRefLayerOpacitySlider();
        }

        public function transferLoadedImageToRefLayer(bmpd:IBitmapDrawable,w:Number,h:Number):void
        {
            const maxSize:Number = 1000;
            var maxLength:Number = (w > h) ? w : h;
            var scaleFix:Number = (maxLength > maxSize) ? maxSize/maxLength : 1.0;

            w = Math.floor(w*scaleFix);
            h = Math.floor(h*scaleFix); //maxSize 값을 넘으면 리사이즈 해줌
            var scaleMat:Matrix = new Matrix();
            scaleMat.scale(scaleFix,scaleFix);

            var tmpbmpd:BitmapData = new BitmapData(w,h,true,0);

            tmpbmpd.draw(bmpd,scaleMat,null,null,null,true);

            canvasRefLayerBitmapData = updateBitmapData(canvasRefLayerBitmapData,tmpbmpd,canvasRefLayerBitmap);

            tmpbmpd.dispose();
            tmpbmpd = null;

            resetRefLayerImageTransform();

            const gw:Number = CANVAS_WIDTH;
            const gh:Number = CANVAS_HEIGHT;
            const widthFlag:Boolean = (w >= h) ? true : false;
            var autoScale:Number = 0;

            if(w > gw && widthFlag === true) autoScale = gw/w;
            else if (h > gh && widthFlag === false) autoScale = gh/h;

            if(autoScale > 0)
            {
                canvasRefLayer.scaleX = autoScale;
                canvasRefLayer.scaleY = autoScale;
            }

            resetRefLayerOpacitySlider();
        }

        public function getBlurSize(size:Number,z:Number):Number
        {
            var blurSize:Number = size/2;

            if(blurSize <= 2) blurSize = 2;
            else if(blurSize > 30) blurSize = 30;

            return blurSize*z;
        }

        //drawdone에서 줌된 blur사이즈가 아니 1배율 블러를 적용해야 제대로 되기 때문에 이거해줌
        public function blurReplayCanvasByDefaultValue():void
        {
            const blurSize:Number = getBlurSize(rAirBrushSize,1.0);
            const blurf:BlurFilter = new BlurFilter(blurSize,blurSize,3);

            rCanvasDrawShape.filters = [blurf];
        }

        public function resetBlurReplayCanvas():void
        {
            rAirBrushSize = 0;
            rCanvasDrawShape.filters = [];
        }

        public function blurReplayCanvasByValue(size:Number):void
        {
            const blurSize:Number = getBlurSize(size,rCanvasZoomMultiplier);
            const blurf:BlurFilter = new BlurFilter(blurSize,blurSize,3);
            rAirBrushSize = size;
            rCanvasDrawShape.filters = [blurf];
        }

        public function toggleAirBrushCheckBox(flag:Boolean,penFlag:Boolean):void
        {
            toolOptionsBox.airBrushOFFButton.visible = flag;
            toolOptionsBox.airBrushONButton.visible = !flag;

            if(flag)
            {
                airBrushSizeDrawMode = (penFlag) ? penSize:eraserSize;
                toolOptionsBox.blurShapeSetON();
            }
            else if(airBrushSizeDrawMode !== 0)
            {
                airBrushSizeDrawMode = 0;
                canvasDrawLayerChild.filters = [];
                toolOptionsBox.blurShapeSetOFF();
            }
        }

        public function toggleEraseAirBrushButtonShortCut():void
        {
            isEraserAirBrushON = !isEraserAirBrushON;
            toggleAirBrushCheckBox(isEraserAirBrushON,false);

            if(isEraserAirBrushON) showMouseHintTemp("Eraser Air brush ON");
            else showMouseHintTemp("Eraser Air brush OFF");
        }

        public function toggleEraseAirBrushButton(flag:Boolean):void
        {
            isEraserAirBrushON = flag;
            toggleAirBrushCheckBox(flag,false);
        }

        public function togglePenAirBrushButtonShortCut():void
        {
            isPenAirBrushON = !isPenAirBrushON;
            toggleAirBrushCheckBox(isPenAirBrushON,true);

            if(isPenAirBrushON) showMouseHintTemp("Pen Air brush ON");
            else showMouseHintTemp("Pen Air brush OFF");
        }

        public function togglePenAirBrushButton(flag:Boolean):void
        {
            isPenAirBrushON = flag;
            toggleAirBrushCheckBox(flag,true);
        }

        public function restoreCanvasBackgroundColor(replayMode:Boolean):void
        {
            var xPanel:Sprite;
            var w:Number = CANVAS_WIDTH;
            var h:Number = CANVAS_HEIGHT;
            var color:uint;

            if(replayMode)
            {
                xPanel = rCanvasPanel;
                w = RCANVAS_WIDTH;
                h = RCANVAS_HEIGHT;
                color = RCANVAS_BG_COLOR;
            }
            else
            {
                xPanel = canvasPanel;
                w = CANVAS_WIDTH;
                h = CANVAS_HEIGHT;
                color = CANVAS_BG_COLOR;
            }

            xPanel.graphics.clear();
            xPanel.graphics.beginFill(color);
            xPanel.graphics.drawRect(0,0,w,h);
            xPanel.graphics.endFill();
        }

        public function applyTransparentCanvasBackground(replayMode:Boolean):void
        {
            var xPanel:Sprite;
            var w:Number = CANVAS_WIDTH;
            var h:Number = CANVAS_HEIGHT;

            if(replayMode)
            {
                xPanel = rCanvasPanel;
                w = RCANVAS_WIDTH;
                h = RCANVAS_HEIGHT;
            }
            else
            {
                xPanel = canvasPanel;
                w = CANVAS_WIDTH;
                h = CANVAS_HEIGHT;
            }

            xPanel.graphics.clear();
            xPanel.graphics.lineStyle(0,0,0);
            xPanel.graphics.beginBitmapFill(capTransparentBGBMPD);
            xPanel.graphics.drawRect(0,0,w,h);
            xPanel.graphics.endFill();
        }

        public function bringCanvasDrawLayerAboveLayer1():void
        {
            if(canvasPanel.getChildIndex(canvasDrawLayer) < canvasPanel.getChildIndex(lassoLayer1))
            {
                canvasPanel.setChildIndex(canvasDrawLayer,canvasPanel.getChildIndex(lassoLayer1));
            }
        }

        public function bringCanvasDrawLayerAboveLayer2():void
        {
            if(canvasPanel.getChildIndex(canvasDrawLayer) > canvasPanel.getChildIndex(canvasLayer1Bitmap))
            {
                canvasPanel.setChildIndex(canvasDrawLayer,canvasPanel.getChildIndex(canvasLayer1Bitmap));
            }
        }

        public function selectLayer1(onlyViewFlag:Boolean):void
        {
            if (onlyViewFlag)
            {
                canvasLayer1Bitmap.visible = true;
                canvasLayer2Bitmap.visible = false;
            }
            else
            {
                canvasLayer1Bitmap.visible = true;
                canvasLayer2Bitmap.visible = true;
            }

            isLayer2Selected = false;

            toolOptionsBox.layer1SelectButton.alpha = 1.0;
            toolOptionsBox.layer2SelectButton.alpha = 0.6;

            bringCanvasDrawLayerAboveLayer1();
        }

        public function selectLayer2(onlyViewFlag:Boolean):void
        {
            if (onlyViewFlag)
            {
                canvasLayer1Bitmap.visible = false;
                canvasLayer2Bitmap.visible = true;
            }
            else
            {
                canvasLayer1Bitmap.visible = true;
                canvasLayer2Bitmap.visible = true;
            }

            isLayer2Selected = true;

            toolOptionsBox.layer1SelectButton.alpha = 0.6;
            toolOptionsBox.layer2SelectButton.alpha = 1.0;

            bringCanvasDrawLayerAboveLayer2();
        }


        public function toggleSharpLineByShortcut():void
        {
            toggleSharpLine(!isSharpLineON);

            if(isSharpLineON)
            {
                showMouseHintTemp("Sharp line ON");
            }
            else
            {
                showMouseHintTemp("Sharp line OFF");
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
            stageBG.graphics.clear();
            stageBG.graphics.beginFill(0,0.0);
            stageBG.graphics.drawRect(-2,-2,stage.stageWidth+4,stage.stageHeight+4);
            stageBG.graphics.endFill();
        }

        public function updateStageBGColor():void
        {   
            const color:uint = Global.getUIStageColor();
            stage.color = color;
            STAGE_BG_COLOR = color;
        }

        public function updateWindowTitle():void
        {
            stage.nativeWindow.title = lastSaveFileName + STRING_TITLE_FOFOPAINT;
            if(isCanvasWindowON)
            {
                copyMainWindowTitleToCanvasWindow();
            }
        }

        public function cycleUIColor():void
        {
            Global.setNextUIColor();
            applyUIColorSet();

            showMouseHintTemp(Global.setUIColorString());
        }

        public function applyUIColorSet():void
        {
            updateStageBGColor();
            updateBottomBarLayoutAndColor();
            canvasNavigatorBox.chanegStageColor(STAGE_BG_COLOR);
            
            if (isCanvasWindowON)
            {
                canvasWindow.stage.color = STAGE_BG_COLOR;
            }

            sideBar.updateUIColor();
            toolOptionsBox.updateUIColor();
            colorPickerBox.updateUIColor();
            canvasInfoBox.updateUIColor();
            canvasRotateCursor.changeUIColor();
            fofo.updateColor();
            
            toolBox.changeUIColor();
            toolBox2.changeUIColor();
            fillPenBox.updateUIColor();
            lassoMenuBox.updateUIColor();
            numPadBox.updateUIColor();
        
            refLayerMenuBox.updateUIColor();

            topBar.updateUIColor();
            replayTimelineBox.updateUIColor();
            captureStampFontListBox.updateUIColor();
            //todo: rgbinfotext 색깔을 바꿔주어야하는데?
            mouseHint.updateBGColor();
            bottomHint.updateHintTextColor(0);
            setResizeButtonColor();
            updateScrollBarColorAndHeight();
            
            if (isColorPickerModeBG)
            {
                switchColorPickerModePen();
            }

            colorPickerBox.activePaperColorButton(isColorPickerModeBG);
            checkCanUseClipBoardButton();
            updatePickerBoxTransBGBrightness();

            if(isBottomBarVisible())
            {
                hideBottomHint();
            }
        }

        public function addGlobalEvents():void
        {
            //전역스테이지 이벤트 cMouseMoveStage <- 스테이지 마우스 무브는 클로저로 하고있음
            stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDownStage,false,1);
            stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpStage,false,1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,onRightMouseUpStage,false,1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownStage,false,1);
            stage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN,onMiddleMouseDownStage,false,1);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDownStage,false,1);
            stage.addEventListener(KeyboardEvent.KEY_UP,onKeyUpStage,false,1);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveUpdatePenPreviewCursor);
            stage.addEventListener(MouseEvent.MOUSE_UP,onMouseMoveUpdatePenPreviewCursor,false,-1);
            stage.addEventListener(Event.MOUSE_LEAVE,onMouseLeaveStage,false);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveBottomHint);
            stage.nativeWindow.x = Capabilities.screenResolutionX/2 - 680/2;
            stage.nativeWindow.y = Capabilities.screenResolutionY/2 - 768/2 - 50;
            stage.nativeWindow.addEventListener(Event.RESIZE,onWindowResize);
            stage.nativeWindow.addEventListener(Event.DEACTIVATE,onWindowDeactivate);
            stage.nativeWindow.addEventListener(Event.ACTIVATE,onWindowActive);
            stage.nativeWindow.addEventListener(Event.CLOSING, onWindowClosingEvent);
            stage.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER,onDragEnterStage);
            stage.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP,onDragDropStage);
            stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheelStage);
            NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvokeEvent);

            loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onGlobalError);

            function onGlobalError(e:UncaughtErrorEvent):void
            {
                var msg:String = "eorr";

                if (e.error is Error) {
                    var err:Error = e.error as Error;
                    msg = err.message;
                    if (msg.hasOwnProperty("getStackTrace"))
                    {
                        var stack:String = err.getStackTrace();
                        if (stack != null)
                        {
                            msg += "\n[stack trace]\n" + stack;
                        }
                    }
                } else if (e.error is ErrorEvent) {
                    msg = (e.error as ErrorEvent).text;
                }

                showMouseHintTemp(msg);
            }
        }

        public function addGlobalEventsChild():void
        {
            toolBox2.addEventListener(MouseEvent.MOUSE_OVER,onMouseOverToolBox2Hint);
        }

        public function updateToolOptionsTextBySelectedTool():void
        {
            var toolName:String = "Pen";
            const nt:uint = nowTool;

            if(isSelectedTool(TOOL_ERASER)) toolName = "Eraser";
            else if(isSelectedTool(TOOL_LINE)) toolName = "Line";
            else if(isSelectedTool(TOOL_FILL_PEN)) toolName = "FillPen";

            toolOptionsBox.hintText(toolName);
        }

        public function getOpacityButtonHint(index:int):String
        {
            return "Opacity "+(penAlphaList[index]*100)+"% [g / b]";
        }

        public function getSizeButtonHint(index:int):String
        {
            return "Size "+penSizeList[index]+ "px [(f, v) / (h, n)]";
        }

        public function updateTimelineBoxPos(stw:Number):void
        {
            const scale:Number = Global.getUIScale();
            const maxWidth:Number = stw-(replayTimelineBox.trackBar.x+5)*scale;

            replayTimelineBox.trackBar.width =  Math.floor(maxWidth/scale);
            replayTimelineBox.replayBGBar.width =  Math.floor(stw/scale)+1;
            replayTimelineBox.prograssInfo.x = replayTimelineBox.trackBar.x;
            replayTimelineBox.prograssInfo.width =  Math.floor(maxWidth/scale);
            updateReplayPrograssBarWidthByNowFame();
        }

        public function prepareUpdate():void
        {
            prepareOpenLoadBox(true,false,null,null,null);
            isUpdatePendingAfterSaving = true;
            openSaveFileBrowser(false);
        }

        public function startUpdate():void
        {
            closeLoadMenuBox();
            isUpdatePendingAfterSaving = false;
            topBar.hideUpdateButton();

            if(appUpdateStatus === UPDATE_READY)
            {
                addTimer(0.5,false,function():void
                {
                    installNewVersion();
                });
            }
            else if(appUpdateStatus === UPDATE_NEEDS_MANUAL)
            {
                navigateToURL(new URLRequest("https://github.com/guljam/2020FlashPaint"));
            }
            navigateToURL(new URLRequest("https://raw.githubusercontent.com/guljam/2020FlashPaint/master/releasenote.txt"));
        }

        public function installNewVersion():void
        {
            if(updateFilePath.exists)
            {
                var updater:Updater = new Updater();
                updater.update(updateFilePath, newVersionStr);
            }
        }

        public function showDrawToolHintSizeOpacity():void
        {
            var tooltype:String = "";
            var size:Number;
            var alpha:Number;
            if(isSelectedTool(TOOL_PEN))
            {
                tooltype = "Pen ";
                size = penSizeList[penSizeIndex];
                alpha = penAlphaList[penAlphaIndex];
            }
            else if(isSelectedTool(TOOL_LINE))
            {
                tooltype = "Line ";
                size = penSizeList[penSizeIndex];
                alpha = penAlphaList[penAlphaIndex];
            }
            else if(isSelectedTool(TOOL_FILL_PEN))
            {
                tooltype = "Fill Pen ";
                size = 1;
                alpha = penAlphaList[penAlphaIndex];
            }
            else if(isSelectedTool(TOOL_ERASER))
            {
                tooltype = "Eraser ";
                size = penSizeList[eraserSizeIndex];
                alpha = penAlphaList[eraserAlphaIndex];
            }
            
            showMouseHintTemp(tooltype+size+"px, "+alpha*100+"%");
        }

        public function adjustDrawToolAlphaByShortcut(increase:Boolean):void
        {
            function setAlpha(alp:Number,size:uint):void
            {
                var index:Number = penAlphaList.indexOf(alp);
                const len:uint = penAlphaList.length-1;

                if(increase)
                {
                    index++;
                    if(index > len)
                    {
                        index = len;
                    }
                }
                else
                {
                    index--;
                    if(index < 1)
                    {
                        index = 1;
                    }
                }

                updateDrawToolAlpha(penAlphaList[index]);
                showDrawToolHintSizeOpacity();
            }

            ensureDrawingToolSelected(true);

            if(isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILL_PEN))
            {
                setAlpha(penAlpha,penSize);
            }
            else if(isSelectedTool(TOOL_ERASER))
            {
                setAlpha(eraserAlpha,eraserSize);
            }

        }

        public function adjustDrawToolSizeByShortcut(increase:Boolean):void
        {
            if(isSelectedTool(TOOL_FILL_PEN))
            {
                return;
            }
            const len:uint = penSizeList.length-1;

            function setSize(index:uint,alpha:Number):void
            {
                if(increase)
                {
                    index++;
                    if(index > len)
                    {
                        index = len;
                    }
                }
                else
                {
                    index--;
                    if(index < 1) 
                    {
                        index = 1;
                    }
                }

                setDrawToolSize(index);
                updatePenSizeCursor();
                showDrawToolHintSizeOpacity();
                penCursorManager.checkCursorVisibility();
            }

            ensureDrawingToolSelected(true);

            if(isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILL_PEN))
            {
                setSize(penSizeIndex,penAlpha);

                if(isPenAirBrushON && penSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = penSize;
                }
            }
            else if(isSelectedTool(TOOL_ERASER))
            {
                setSize(eraserSizeIndex,eraserAlpha);

                if(isEraserAirBrushON && eraserSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = eraserSize;
                }
            }
        }

        //composing 키에대한 체크 잘모르겠음 한영 변환이 관련있는거 같음
        public function checkInvalidKey():void
        {
            const len:uint = KEY_BUFFER.length;
            for(var i:int=0;i<len;i++)
            {
                if(KEY_BUFFER[i] === 229
                || KEY_BUFFER[i] === 241
                || KEY_BUFFER[i] === 242)
                {
                    clearKeyBuffer();
                    return;
                }
            }

            if(len >= 2)
            {
                if((KEY_BUFFER[0] === 18 && KEY_BUFFER[1] === 32)
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
            return KEY_BUFFER[KEY_BUFFER.length-1];
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

            if(index > -1)
            {
                KEY_BUFFER.splice(index,1);
            }
        }

        public function onKeyDownStage(e:KeyboardEvent):void
        {
            tryDisableIME();
            checkInvalidKey();

            const keyCode:uint = e.keyCode;

            if(keyCode === KEY.window)
            {
                return;
            }

            if(keyCode === KEY.tab || keyCode === KEY.alt)
            {
                e.preventDefault();
            }

            if(KEY_BUFFER.lastIndexOf(keyCode) === -1)
            {
                KEY_BUFFER.push(keyCode);
            }
        }

        public function selectOpacityButton(targetName:String):void
        {
            const number:String = targetName.substr(11,targetName.length);
            const index:int = parseInt(number);

            updateDrawToolAlpha(penAlphaList[index]);
        }

        public function selectPenSizeButton(targetName:String):void
        {
            const numberOnly:String = targetName.substr(11,targetName.length);
            const index:uint = parseInt(numberOnly);

            setDrawToolSize(index);
            updatePenSizeCursor();

            if(isSelectedTool(TOOL_FILL_PEN))
            {
                if(isPenAirBrushON && penSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = penSize;
                }
            }
            else if(isSelectedToolPenOrLine())
            {
                if(isPenAirBrushON && penSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = penSize;
                }
            }
            else if(isSelectedTool(TOOL_ERASER))
            {
                if(isEraserAirBrushON && eraserSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = eraserSize;
                }
            }
        }

        public function startPenSmootingAdjustment():void
        {
            const minDist:Number = toolOptionsBox.penSmoothSlider.x+1; //펜 리스트에 흰색 선 시작과 끝 x좌표임
            const maxDist:Number = minDist+toolOptionsBox.penSmoothSlider.width-1;
            const step:Number = penSmoothSlideTotal;
            const div:Number = (maxDist-minDist)/step;
            const maxValue:Number = 0.85;
            const minValue:Number = 0.02;
            const stepValue:Number = (maxValue-minValue)/step;
            const airBrushFlag:Boolean = isSelectedToolPenOrLine() && isPenAirBrushON;
            const eraseAirBrushFlag:Boolean = isSelectedTool(TOOL_ERASER) && isEraserAirBrushON;
            var oldValue:int = penSmoothSlideValue;

            isMouseDragging = true;

            function onMouseUpPenSmoothing(e:MouseEvent):void
            {
                isMouseDragging = false;
                stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUpPenSmoothing);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMovePenSmoothing);
            }

            function adjustPenSmoothingValue():void
            {
                var mx:Number = toolOptionsBox.penSmoothSliderWapper.mouseX+toolOptionsBox.penSmoothSlider.x;

                if(mx < minDist) 
                {
                    mx = minDist;
                }
                else if(mx > maxDist) 
                {
                    mx = maxDist;
                }

                //버튼을 기준으로 중간값으로
                const value:Number = Math.floor((mx-minDist)/div);

                if(oldValue !== value)
                {
                    const xpos:Number = value*div+minDist;

                    if(toolOptionsBox.penSmoothSliderCursor.x === xpos) return;

                    toolOptionsBox.penSmoothSliderCursor.x = xpos;

                    if(value === 0)
                    {
                        penSmoothValue = 0;
                    }
                    else
                    {
                        penSmoothValue = maxValue-(value*stepValue);
                    }

                    penSmoothSlideValue = value;
                    oldValue = value;
                    showBottomHint("Pen smoothing "+value + "/"+step);
                }
            }

            function onMouseMovePenSmoothing(e:MouseEvent):void
            {
                adjustPenSmoothingValue();
            }

            adjustPenSmoothingValue();

            stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpPenSmoothing);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMovePenSmoothing);
        }

        public function getMergedBitmapdtata(transparentBG:Boolean,layer1merge:Boolean,layer2merge:Boolean,clipRect:Rectangle):BitmapData
        {
            var xBitmapData1:BitmapData;
            var xBitmapData11:BitmapData;
            var xDrawLayer:Sprite;
            var xBGCOLOR:uint;
            var alpha:Number;
            var mat:Matrix;
            var bmpd:BitmapData;

            if(isReplayModeON)
            {
                xBitmapData1 = rCanvasLayer1BitmapData;
                xBitmapData11 = rCanvasLayer2BitmapData;
                xDrawLayer = rCanvasDrawLayer;
                xBGCOLOR = RCANVAS_BG_COLOR;
                alpha = drawReplayByCommand.getLineStyleAlpha();
            }
            else
            {
                xBitmapData1 = canvasLayer1BitmapData;
                xBitmapData11 = canvasLayer2BitmapData;
                xDrawLayer = canvasDrawLayer;
                xBGCOLOR = CANVAS_BG_COLOR;
                alpha = 1.0;
            }

            if(clipRect !== null)
            {
                bmpd = new BitmapData(clipRect.width,clipRect.height,true,(transparentBG) ? 0 : 0xFF000000|xBGCOLOR);
                mat = new Matrix();
                mat.translate(-clipRect.x,-clipRect.y);
            }
            else
            {
                bmpd = new BitmapData(xBitmapData1.width,xBitmapData1.height,true,(transparentBG) ? 0 : 0xFF000000|xBGCOLOR);
            }

            if(layer2merge)
            {
                bmpd.draw(xBitmapData11,mat); //레이어 쌓기
            }

            if(isLayer2SelectedReplayMode()) //레이어 2번을 그리고 있을때
            {
                if(layer2merge) bmpd.draw(xDrawLayer,mat,new ColorTransform(1,1,1,alpha));
                if(layer1merge) bmpd.draw(xBitmapData1,mat);
            }
            else //리플레이에서 레이어 1번그리고 있을때
            {
                if(layer1merge)
                {
                    bmpd.draw(xBitmapData1,mat);
                    bmpd.draw(xDrawLayer,mat,new ColorTransform(1,1,1,alpha));
                }
            }

            return bmpd;
        }

        public function updateCanvasFlipOnCaptureMode():void
        {
            const xAnc:Sprite = (isReplayModeON) ? rCanvasAnchorPoint : canvasAnchorPoint;
            if(captureCanvasRotationStep === 1)
            {
                xAnc.rotation = 90;
            }
            else if(captureCanvasRotationStep === 3)
            {
                xAnc.rotation = 270;
            }
        }

        public function flipCaptureImage(flag:Boolean,initFlag:Boolean):void
        {
            isCaptureCanvasFlipped = flag;
            fitCanvasToViewportMargin(true);

            const xAnc:Sprite = (isReplayModeON) ? rCanvasAnchorPoint : canvasAnchorPoint;

            if(captureCanvasRotationStep === 1)
            {
                captureCanvasRotationStep = 3;
                xAnc.rotation = 270;
            }
            else if(captureCanvasRotationStep === 3)
            {
                captureCanvasRotationStep = 1;
                xAnc.rotation = 90;
            }

            topBar.capClipBoard.alpha = 1.0;
            if(!initFlag)
            {
                captureAreaManager.updateDrawArea();
            }
        }

        public function updateCaptureStampButtonAlpha():void
        {
            if(isCaptureStampEnabled)
            {
                topBar.capStamp.alpha = 1.0;
                topBar.captureInputWarpper.visible = true;
                topBar.capStampFont.visible = true;
            }
            else
            {
                topBar.capStamp.alpha = Global.OFFALPHA;
                topBar.captureInputWarpper.visible = false;
                topBar.capStampFont.visible = false;
            }
        }

        public function toggleCaptureStampButton():void
        {
            topBar.capClipBoard.alpha = 1.0;
            isCaptureStampEnabled = !isCaptureStampEnabled;
            updateCaptureStampButtonAlpha();
            captureStampManager.update();
        }

        public function handleExitCaptureMode():void
        {
            setFileBrowserIsOpen(false);
            exitCaptureMode();
        }

        public function applyTransparentCanvasBGCaptureMode(flag:Boolean):void
        {
            isCaptureTransparentBGShowing = flag;

            if(isCaptureTransparentBGShowing)
            {
                applyTransparentCanvasBackground(isReplayModeON);
            }
            else
            {
                restoreCanvasBackgroundColor(isReplayModeON);
            }

            topBar.capClipBoard.alpha = 1.0;
        }

        public function rotateCaptureImage(rotateValue:uint,initFlag:Boolean):void
        {
            //90도 시계 방향으로 회전
            //1: 90도 2:180 3:270
            if(rotateValue >= 4) rotateValue = 0;
            captureCanvasRotationStep = rotateValue;
            fitCanvasToViewportMargin(true);
            topBar.capClipBoard.alpha = 1.0;

            if(!initFlag)
            {
                captureAreaManager.updateDrawArea();
            }
        }

        //rotate hand zoom에서 쓰임
        public function hideCanvasResizeButtons():void
        {
            isPenSizeCursorInvisible = false;
            resizeButtonR.visible = false;
            resizeButtonL.visible = false;
            resizeButtonD.visible = false;
            resizeButtonU.visible = false;
        }

        public function showCanvasResizeButtons():void
        {
            isPenSizeCursorInvisible = true;
            resizeButtonR.visible = true;
            resizeButtonL.visible = true;
            resizeButtonD.visible = true;
            resizeButtonU.visible = true;
        }

        public function updateCanvasResizeButtonVisible(flag:Boolean):void
        {
            if(resizeButtonR.visible === flag)
            {
                return;
            }

            if(flag)
            {
                updateResizeButtonPos(CANVAS_WIDTH,CANVAS_HEIGHT);
                showCanvasResizeButtons();
            }
            else
            {
                hideCanvasResizeButtons();
            }
        }

        public function showCanvasResizeButtonVisibleDelay(flag:Boolean):void
        {
            if(flag)
            {
                updateResizeButtonPos(CANVAS_WIDTH,CANVAS_HEIGHT);
                toolBox2.startResizeButtonWaitBarAnimation(0.9);
                addTimerByName("resizeButtonVisibleDelayTimer",0.9,false,function():void
                {
                    showCanvasResizeButtons();
                    enableTransparentBGDrawMode();
                });
            }
            else
            {
                removeTimer("resizeButtonVisibleDelayTimer");
                hideCanvasResizeButtons();
                disableTransparentBGDrawMode();
            }
        }

        public function addInputEventsReplayMode():void
        {
            if(isReplayModeInputEventsAdded === false)
            {
                isReplayModeInputEventsAdded = true;
                // resetKeyBuffer();
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownReplayMode,false,-1);
                stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDownReplayMode,false,-1);
                stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDownReplayMode,false,-1);
                stage.addEventListener(KeyboardEvent.KEY_UP,onKeyUpReplayMode,false,-1);
            }
        }

        public function removeInputEventsReplayMode():void
        {
            isReplayModeInputEventsAdded = false;
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownReplayMode);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,onMouseDownReplayMode);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,onKeyDownReplayMode);
            stage.removeEventListener(KeyboardEvent.KEY_UP,onKeyUpReplayMode);
        }

        public function removeInputEventsDrawMode():void
        {
            isDrawModeInputEventsAdded = false;
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,onKeyDownDrawMode);
            stage.removeEventListener(KeyboardEvent.KEY_UP,onKeyUpDrawMode);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,onMouseDownDrawMode);
            stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUpDrawMode,false);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownDrawMode);
            // stage.removeEventListener(MouseEvent.MOUSE_OVER,lassoMenuHintONEvent);
        }

        public function addInputEventsDrawMode():void
        {
            if(isDrawModeInputEventsAdded === false)
            {
                isDrawModeInputEventsAdded = true;
                // resetKeyBuffer();
                stage.addEventListener(KeyboardEvent.KEY_UP,onKeyUpDrawMode,false,-1);
                stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDownDrawMode,false,-1);
                stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDownDrawMode,false,-1);
                stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpDrawMode,false,-1);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownDrawMode,false,-1);
            }
        }

        public function removeInputEventCaptrueMode():void
        {
            isCaptureModeInputEventsAdded = false;
            stage.removeEventListener(KeyboardEvent.KEY_UP,onKeyUpCaptureMode);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,onKeyDownCaptureMode);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,onMouseDownCaptureMode);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownCaptureMode);
        }

        public function addInputEventsCaptrueMode():void
        {
            if(isCaptureModeInputEventsAdded === false)
            {
                isCaptureModeInputEventsAdded = true;
                // resetKeyBuffer();
                stage.addEventListener(KeyboardEvent.KEY_UP,onKeyUpCaptureMode,false,-1);
                stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDownCaptureMode,false,-1);
                stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDownCaptureMode,false,-1);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownCaptureMode,false,-1);
            }
        }

        public function removeInputEventsToolBox2():void
        {
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,onRightMouseUpToolBox2);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,onMouseDownToolBox2);
            addInputEventsDrawMode();
        }

        public function addInputEventsToolBox2():void
        {
            removeInputEventsDrawMode();
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,onRightMouseUpToolBox2,false,-2);
            stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDownToolBox2,false,-2);
        }

        public function addLassoLayerMergeCommand(command:int):void
        {
            if(lassoLayerCommandData === null)
            {
                lassoLayerCommandData = [];
            }
            //0번 스왑명령, 1번 머지 명령
            if(command === 0)
            {
                if(lassoLayerCommandData.length > 0 && lassoLayerCommandData[lassoLayerCommandData.length-1] === 0)
                {
                    lassoLayerCommandData.pop();
                }
                else
                {
                    lassoLayerCommandData.push(0);
                }
            }
            else if(lassoLayerCommandData[lassoLayerCommandData.length-1] !== command)
            {
                lassoLayerCommandData.push(command);
            }
        }

        public function swapLassoImage():void
        {
            var tmpbmpd:BitmapData = lassoLayer1Bitmap.bitmapData;
            lassoLayer1Bitmap.bitmapData = lassoLayer2Bitmap.bitmapData;
            lassoLayer2Bitmap.bitmapData = tmpbmpd;
            tmpbmpd = null;
        }

        public function mergeLassoImage():void
        {
            var rect:Rectangle = new Rectangle(0,0,lassoLayer1Bitmap.bitmapData.width,lassoLayer1Bitmap.bitmapData.height);

            lassoLayer2Bitmap.bitmapData.draw(lassoLayer1Bitmap);
            lassoLayer1Bitmap.bitmapData.fillRect(rect,0);
            rect = null;
        }

        public function mergeLayerByLassoTool():void
        {
            lassoMenuBox.lassoLayerMerge.alpha = Global.OFFALPHA;
            mergeLassoImage();
            addLassoLayerMergeCommand(1);
        }

        public function swapLayerByLassoTool():void
        {
            if(lassoMenuBox.lassoLayerSwap.alpha < 1.0)
            {
                return;
            }

            isLassoLayerSwapButtonClicked = !isLassoLayerSwapButtonClicked;
            swapLassoImage();
            addLassoLayerMergeCommand(0);
            lassoMenuBox.hint(getLassoMenuHintSwapLayer());
            playLayerSwapEffect(lassoMenuBox.lassoLayerSwap);
        }

        public function copyCanvasImageToLassoTool():void
        {
            if(isLassoImageCopied)
            {
                return;
            }

            isLassoImageCopied = true;
            lassoMenuBox.lassoCopy.alpha = Global.OFFALPHA;
            lassoCancelBmpd();
        }

        public function startLassoImageRotation():void
        {
            var getAngle:Function = createAngleUpdateFunctionByMouseDrag(lassoLayer1);

            function onMouseUp():void
            {
                getAngle = null;
                hideCanvasRotateCursor();

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

            startDragInteraction(onDragStart,onMouseMove,onMouseUp);
        }

        public function startLassoImageResize():void
        {
            const mirrorScale:Number = (lassoLayer1.scaleX < 0) ? -1.0 : 1.0;
            var getScale:Function = createScaleUpdaterFromMouseDrag(lassoLayer1.scaleX);

            function onDragStart():void
            {
                lassoMenuBox.visible = false;
                lassoLayer1Bitmap.smoothing = false;
                lassoLayer2Bitmap.smoothing = false;

                showMouseHint(getImageScaleHint(lassoLayer1.width,lassoLayer1.height,Math.abs(lassoLayer1.scaleX),false));
            }
            function onMouseUp():void
            {
                getScale = null;
                keepBoxInsideViewPort(lassoMenuBox);
                hideMouseHint();

                lassoLayer1Bitmap.smoothing = true;
                lassoLayer2Bitmap.smoothing = true;
                lassoMenuBox.visible = true;
            }

            function onMouseMove():void
            {
                const scale:Number = getScale(stage.mouseX,stage.mouseY);

                lassoLayer1.scaleX = scale*mirrorScale;
                lassoLayer1.scaleY = scale;
                lassoLayer2.scaleX = lassoLayer1.scaleX;
                lassoLayer2.scaleY = lassoLayer1.scaleY;

                showMouseHint(getImageScaleHint(lassoLayer1.width,lassoLayer1.height,Math.abs(lassoLayer1.scaleX),false));
            }

            startDragInteraction(onDragStart,onMouseMove,onMouseUp);
        }

        public function hasLassoImageChanges():Boolean
        {
            if(isLassoImageCopied
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

        public function startLassoImageMove():void
        {
            var getMovedPos:Function = createPosUpdateFunctionByMouseDrag(lassoLayer1,canvasAnchorPoint.rotation);

            function onMouseUp():void
            {
                getMovedPos = null;
                keepBoxInsideViewPort(lassoMenuBox);

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

            startDragInteraction(onDragStart,onMouseMove,onMouseUp);
        }

        public function setDrawToolSize(index:uint):void
        {
            const size:uint = penSizeList[index];

            if(isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILL_PEN))
            {
                penSize = size;
                penSizeIndex = index;
                penCursorManager.updateCursorSize(penSize);
            }
            else if(isSelectedTool(TOOL_ERASER))
            {
                eraserSize = size;
                eraserSizeIndex = index;
                penCursorManager.updateCursorSize(eraserSize);
            }
            toolOptionsBox.movePenSizeCursor(index);
        }



        public function isCurrentColorSamePickedColor():Boolean
        {
            return colorPickerBox.getRGBInfoBGColor() === colorPickerBox.getCurrentColor();
        }

        public function updatePickerCurrentColor(color:uint):void
        {
            colorPickerBox.updateCurrentColor(color);
        }

        public function onEnterFrameColorPickerBoxModeBGOFF(e:Event):void
        {
            if(!numPadBox.visible
            && !isMouseClicked
            && (!sideBar.visible || !colorPickerBox.hitTestPoint(stage.mouseX, stage.mouseY)))
            {
                stage.removeEventListener(Event.ENTER_FRAME,onEnterFrameColorPickerBoxModeBGOFF);
                pickerModeResetFlag = false;
                switchColorPickerModePen();
            }
        }

        public function switchColorPickerModeBG():void
        {
            const color:uint = CANVAS_BG_COLOR;

            isColorPickerModeBG = true;

            updateColorPickerCursorPosAndRGBInfo(color);
            updatePickerCurrentColor(color);
            colorPickerBox.activePaperColorButton(true);
            colorPickerBox.transColorButton.visible = false;
            isTransparentPenColor = false;

            if(pickerModeResetFlag === false)
            {
                pickerModeResetFlag = true;
                stage.addEventListener(Event.ENTER_FRAME,onEnterFrameColorPickerBoxModeBGOFF);
            }
        }

        public function switchColorPickerModePen():void
        {
            const color:uint = penColor;

            isColorPickerModeBG = false;
            updateColorPickerCursorPosAndRGBInfo(color);
            updatePickerCurrentColor(color);
            colorPickerBox.activePaperColorButton(false);
            colorPickerBox.transColorButton.visible = true;
            isTransparentPenColor = false;
        }

        public function selectPenShapeButton(shapeFlag:Boolean):void
        {
            penListShapeIsSqare = shapeFlag;

            if(isSelectedToolPenOrLine())
            {
                if(penIsSquare !== shapeFlag)
                {
                    penIsSquare = shapeFlag;
                }
            }
            else if(isSelectedTool(TOOL_ERASER))
            {
                if(eraserIsSquare !== shapeFlag)
                {
                    eraserIsSquare = shapeFlag;
                }
            }

            toolOptionsBox.updatePenShapeSet(shapeFlag);
            updatePenSizeCursor();
        }

        public function updatePenColor(color:uint):void
        {
            penColor = color;
            updateOpacityCursorPos(penAlphaIndex);
        }

        public function isBackgroundColorMode():Boolean
        {
            return isColorPickerModeBG === true && isFillPenStarted === false;
        }

        public function isPenColorMode():Boolean
        {
            return isColorPickerModeBG === false;
        }

        public function updateHSVColorData(h:Number,s:Number,v:Number):void
        {
            hsvColorData[0] = h;
            hsvColorData[1] = s;
            hsvColorData[2] = v;
        }

        public function startHueColorSelection():void
        {
            const offsetX:Number = colorPickerBox.offsetX;
            const max:Number = colorPickerBox.svBoxWidth;
            var pickedColor:uint = 0;

            function pickHueColor(mx:Number):void
            {
                var hueCursorX:Number = mx;

                if(hueCursorX < 0) hueCursorX = 0;
                else if(hueCursorX > max) hueCursorX = max;

                colorPickerBox.hueCursor.x = hueCursorX;

                const hueValue:Number = hueCursorX/max;
                const baseColor:Vector.<uint> = Global.HSVtoRGB(hueValue,1.0,1.0);
                const baseHexColor:uint = Global.RGBtoHEX(baseColor[0],baseColor[1],baseColor[2]);

                updateHSVColorData(hueValue,hsvColorData[1],hsvColorData[2]);
                pickedColor = Global.HSVtoHEX(hueValue,hsvColorData[1],hsvColorData[2]);
                colorPickerBox.updateHueColor(baseHexColor);
                colorPickerBox.updateRGBInfoBG(pickedColor,myPalettePresetType);
                if(isHSVInfoTextMode)
                {
                    colorPickerBox.updateRGBInfoText("HSV",hsvColorData);
                }
                else
                {
                    colorPickerBox.updateRGBInfoText("RGB",pickedColor);
                }
            }

            function onMouseMove():void
            {
                pickHueColor(colorPickerBox.hueColor.mouseX);
            }

            function onMouseUp():void
            {
                pickHueColor(colorPickerBox.hueColor.mouseX);

                if(isPenColorMode())
                {
                    updatePenColor(pickedColor);
                }
                else if(isBackgroundColorMode())
                {
                    updateCanvasBGColorDrawMode(pickedColor);
                    if(isCanvasWindowON) updateCanvasWindowBGColor(CANVAS_BG_COLOR,canvasWindowLayer1Bitmap.bitmapData);
                    addUndoBGColorData(pickedColor);
                }

                isPenSizeCursorInvisible = false;
                colorPickerBox.setRGBInfoVisible(true);
                ensureDrawingToolSelected(false);
            }

            function onDragStart():void
            {
                setAsTopChild(colorPickerBox.hueCursor);
                isPenSizeCursorInvisible = true;
                isTransparentPenColor = false;
                colorPickerBox.setRGBInfoVisible(false);
                pickHueColor(colorPickerBox.hueColor.mouseX);
            }

            startDragInteraction(onDragStart,onMouseMove,onMouseUp);
        }

        public function startSVColorSelection():void
        {
            const colorBarWidth:Number = colorPickerBox.svBoxWidth;
            const colorBarHeight:Number = colorPickerBox.svBoxHeight;
            var pickedColor:uint = 0;

            function pickSVColor(mx:Number,my:Number):void
            {
                var svCursorX:Number = mx;
                var svCursorY:Number = my;

                if(svCursorX < 0) svCursorX = 0;
                else if(svCursorX > colorBarWidth) svCursorX = colorBarWidth;

                if(svCursorY < 0) svCursorY = 0;
                else if(svCursorY > colorBarHeight) svCursorY = colorBarHeight;

                colorPickerBox.svCursor.x = svCursorX;
                colorPickerBox.svCursor.y = svCursorY;

                const hueValue:Number = hsvColorData[0];
                const sValue:Number = svCursorX/colorBarWidth;
                const vValue:Number = 1-(svCursorY/colorBarHeight);

                updateHSVColorData(hueValue,sValue,vValue);
                pickedColor = Global.HSVtoHEX(hueValue,sValue,vValue);
                colorPickerBox.updateRGBInfoBG(pickedColor,myPalettePresetType);
                colorPickerBox.setRGBInfoVisible(false);
                if(isHSVInfoTextMode)
                {
                    colorPickerBox.updateRGBInfoText("HSV",hsvColorData);
                }
                else
                {
                    colorPickerBox.updateRGBInfoText("RGB",pickedColor);
                }
            }

            function onMouseMove():void
            {
                pickSVColor(colorPickerBox.svBox.mouseX,colorPickerBox.svBox.mouseY);
            }

            function onMouseUp():void
            {
                pickSVColor(colorPickerBox.svBox.mouseX,colorPickerBox.svBox.mouseY);

                if(isPenColorMode())
                {
                    penColor = pickedColor;
                    updateOpacityCursorPos(penAlphaIndex);
                }
                else if(isBackgroundColorMode())
                {
                    updateCanvasBGColorDrawMode(pickedColor);
                    if(isCanvasWindowON) updateCanvasWindowBGColor(CANVAS_BG_COLOR,canvasWindowLayer1Bitmap.bitmapData);
                    addUndoBGColorData(pickedColor);
                }

                isPenSizeCursorInvisible = false;

                colorPickerBox.setRGBInfoVisible(true);
                ensureDrawingToolSelected(false);
            }

            function onDragStart():void
            {
                setAsTopChild(colorPickerBox.svCursor);
                isPenSizeCursorInvisible = true;
                isTransparentPenColor = false;
                colorPickerBox.setRGBInfoVisible(false);
                pickSVColor(colorPickerBox.svBox.mouseX,colorPickerBox.svBox.mouseY);
            }

            startDragInteraction(onDragStart,onMouseMove,onMouseUp);
        }

        //단축키를  after tool mouse up에서 이전툴을 복구해줌
        public function selectLastUsedTool():void
        {
            const lastToolSave:int = lastTool;

            if(lastToolSave === TOOL_NONE)
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

                case TOOL_FILL_PEN:
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

                case TOOL_EYEDROPPER:eyeDropperTool(); break;
                case TOOL_LASSO:selectLassoTool(); break;
                case TOOL_MOVE:selectMoveTool(); break;
                case TOOL_ROTATE:selectRotateTool(); break;
                case TOOL_ZOOM:selectZoomTool(); break;
            }

            nowTool = lastToolSave;

            resetOldTool();
        }

        //VERSION변수를 문자열로 변환, 변환할때 뒤에 .0이 붙었는지 까지 체크
        public function convertVersionString(version:Number):String
        {
            var verStr:String = version.toString();

            if(verStr && verStr.indexOf(".") === -1) verStr = verStr + ".0";

            return verStr;
        }

        public function enableIME():void
        {
            IME.enabled = true;
        }

        public function tryDisableIME():void
        {
            if(isCaptureStampTextFieldFocused)
            {
                IME.enabled = true;
                return;
            }

            if(Capabilities.hasIME && IME.enabled) //다른 언어로 하면 자판 안먹어서 그냥 ime자체를안씀
            {
                IME.compositionAbandoned();
                IME.enabled = false;
            }
        }

        //문자열을 소수 2번째 자리까지만 변환

        public function checkForUpdates():void
        {
            if(appUpdateStatus === UPDATE_CHECKING)
            {
                return;
            }

            appUpdateStatus = UPDATE_CHECKING;

            var versionInfo:URLRequest = new URLRequest(UPDATE_VERSION_URL);
            var loader:URLLoader = new URLLoader();

            versionInfo.useCache = false;

            loader.addEventListener(Event.COMPLETE,onCompleteCheckVersion);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onErrorCheckVersion);
            loader.load(versionInfo);

            function onErrorCheckVersion(e:IOErrorEvent):void
            {
                appUpdateStatus = UPDATE_NONE;
                loader.removeEventListener(Event.COMPLETE,onCompleteCheckVersion);
                loader.removeEventListener(IOErrorEvent.IO_ERROR, onErrorCheckVersion);
                loader = null;
            }

            function parseVersion(str:String):Number
            {
                return parseFloat(str);
            }

            function isNewVersion(newVersionArray:Array):Boolean
            {
                var current:Array = APP_VERSION.toFixed(2).split(".");
                
                var newMajor:Number = parseFloat(newVersionArray[0]);
                var newMinor:Number = parseFloat(newVersionArray[1]);
                var curMajor:Number = parseFloat(current[0]);
                var curMinor:Number = parseFloat(current[1]);
                
                return (newMajor > curMajor) || (newMajor === curMajor && newMinor > curMinor);
            }

            function onCompleteCheckVersion(e:Event):void
            {
                const versionStr:String = loader.data as String;
                if(!versionStr)
                {
                    return;
                }

                const versionArray:Array = versionStr.split(".");

                if(versionArray.length === 2)
                {
                    var tryCount:uint = 0;

                    const updateFile:URLRequest = new URLRequest(UPDATE_FILE_URL);
                    if(isNewVersion(versionArray))
                    {
                        newVersionStr = versionStr;
                        var fileLoader:URLLoader = e.target as URLLoader;

                        fileLoader.dataFormat = URLLoaderDataFormat.BINARY;
                        fileLoader.addEventListener(Event.COMPLETE,downloadSuccessEvent);
                        fileLoader.addEventListener(IOErrorEvent.IO_ERROR,downloadFailedEvent);

                        function onUpdateCheckFinished(updateState:int):void
                        {
                            fileLoader.removeEventListener(Event.COMPLETE,downloadSuccessEvent);
                            fileLoader.removeEventListener(IOErrorEvent.IO_ERROR,downloadFailedEvent);

                            appUpdateStatus = updateState;
                            topBar.showUpdateButton();
                        }

                        function downloadFailedEvent(e:Event):void
                        {
                            if(tryCount < 5)
                            {
                                addTimerByName("updateRryTimer",1.0,false,function():void
                                {
                                    tryCount++;
                                    fileLoader.load(updateFile);
                                });
                            }
                            else
                            {
                                onUpdateCheckFinished(UPDATE_NEEDS_MANUAL);
                            }
                        }

                        function downloadSuccessEvent(e:Event):void
                        {
                            var fs:FileStream = new FileStream();
                            fs.open(updateFilePath,FileMode.WRITE);
                            fs.writeBytes(fileLoader.data);
                            fs.close();
                            onUpdateCheckFinished(UPDATE_READY);
                        }

                        if(Updater.isSupported)
                        {
                            fileLoader.load(updateFile); //다운로드를 시작함
                        }
                        else
                        {
                            onUpdateCheckFinished(UPDATE_NEEDS_MANUAL);
                        }
                    }
                    else
                    {
                        appUpdateStatus = UPDATE_NONE;
                        //최신 버전이면 이미 다운로드한 파일 있는지 체크하고 제거
                        if(updateFilePath.exists)
                        {
                            updateFilePath.deleteFile();
                        }
                    }
                }
                else
                {
                    appUpdateStatus = UPDATE_NONE;
                }
                loader.removeEventListener(Event.COMPLETE,onCompleteCheckVersion);
                loader.removeEventListener(IOErrorEvent.IO_ERROR, onErrorCheckVersion);
                loader = null;
            }
        }

        public function closeAboutBox():void
        {
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,onAboutWindowMouseDown);
            removeInputEventCaptrueMode();
            removeInputEventsReplayMode();
            addInputEventsDrawMode();
            isAboutBoxOpened = false;
            aboutBox.visible = false;
            addTimerByName("clickBlockTimer",0.15,false,function():void
            {
                isMouseClickBlocked = false;
            });
        }

        public function onAboutWindowMouseDown(e:MouseEvent):void
        {
            const targetName:String = e.target.name;

            switch(targetName)
            {
                case "appResetButton":
                case "versionInfo":
                case "releaseNoteButton":
                case "resetAppButton":
                case "aboutButton":
                case "kor":
                case "jp":
                case "eng":
                case "aboutHomePageLink":
                // case "aboutMeLink":
                    handleMouseClick(targetName);
                break;

                default:
                    closeAboutBox();
                break;
            }
        }

        public function updateAboutPanelCenterPos():void
        {
            aboutBox.x = Math.floor(stage.stageWidth/2)+Math.floor(-aboutBox.width/2);
            aboutBox.y = Math.floor((stage.stageHeight-39)/2)+Math.floor(-aboutBox.height/2);
        }

        public function openAboutBox(welcome:Boolean):void
        {
            setAsTopChild(aboutBox);
            isAboutBoxOpened = true;
            isMouseClickBlocked = true;
            hideBottomHint();
            removeInputEventsDrawMode();

            if(welcome === true)
            {
                aboutBox.resetAppButton.visible = false;
                addTimerByName("openAboutPanelOFFTimer",1.0,false,function():void
                {
                    stage.addEventListener(MouseEvent.MOUSE_DOWN,onAboutWindowMouseDown);
                });
            }
            else
            {
                removeInputEventsDrawMode();
                aboutBox.resetAppButton.visible = true;
                checkForUpdates();
                stage.addEventListener(MouseEvent.MOUSE_DOWN,onAboutWindowMouseDown);
            }

            aboutBox.randomLogo();
            aboutBox.updateMemoryInfo(getDriveUsageString());
            updateAboutPanelCenterPos();
            aboutBox.visible = true;
        }

        public function clearDataAndResetVars():void
        {
            isContinueSaveON = false;
            rLastCanvasBGColor = CANVAS_BG_COLOR;
            rMirrorON = false;
            isCanvasMirrored = false;
            mirrorCommandReady = false;
            rDataReadFlag = false;
            undoManager.setRFileTotalFrame(0);
            updateTotalFrameAndReplayMaxSpeedFor10Sec(0);
            rReplayImageCacheState = REPLAY_IMAGE_CAHCHE_COMPLETE;
            isLayerSwapped = false;

            resetRefLayerImageTransform();
            resetRefLayerMenuOpacity();
            initializeReplayDataFile(true);
            resetReplaySpeedBar();
            resetReplayTime();
            resetUndoState();
            resetCaptureCanvasChangeValue();
            updateLastFilePathByRandomFileName();

            canvasInfoBox.setMirror(false);
            updateWindowTitle();
            removeKeyRepeatEvents(null);
        }

        public function copyReplayCanvasDataToDrawCanvas():void
        {
            const lineStyleSave:Array = drawReplayByCommand.getrLineStyleSave();
            // if(!lineStyleSave) return;
            var newColorTransform:ColorTransform = new ColorTransform(1,1,1,lineStyleSave[0]);

            rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
            rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;

            if(isLayer2SelectedReplayMode())
            {
                rCanvasLayer2BitmapData.draw(rCanvasDrawLayerBitmap,null,newColorTransform,lineStyleSave[1]);
            }
            else
            {
                rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap,null,newColorTransform,lineStyleSave[1]);
            }

            //캔버스 2번 지워줘야함
            rCanvasDrawShape.graphics.clear();
            rCanvasDrawLayerBitmapData.fillRect(new Rectangle(0,0,rCanvasDrawLayerBitmapData.width,rCanvasDrawLayerBitmapData.height),0);

            canvasLayer1BitmapData = updateBitmapData(canvasLayer1BitmapData,rCanvasLayer1BitmapData,canvasLayer1Bitmap);
            canvasLayer2BitmapData = updateBitmapData(canvasLayer2BitmapData,rCanvasLayer2BitmapData,canvasLayer2Bitmap);

            updateCavnvasSizeDrawMode(canvasLayer1Bitmap.width,canvasLayer1Bitmap.height);
            updateCanvasBGColorDrawMode(RCANVAS_BG_COLOR);
            canvasNavigatorBox.updateImage(canvasLayer1BitmapData,canvasLayer2BitmapData,CANVAS_BG_COLOR);

            if(isCanvasWindowON)
            {
                updateCanvasWindowImage();
                updateCanvasWindowBitmapSize();
            }
        }

        public function clearData():void
        {
            clearCanvas();
            clearCanvasReplayMode();
            clearDataAndResetVars();
            markWindowTitleAsDirty();
            drawReplayByCommand.resetFirstRCursorPos();
            clearRFrameTempCache();
            //reset vars보다 뒤에 와야함
            //addundo에서 활성화 해주고 있기 때문에
            topBar.newFileButton.alpha = Global.OFFALPHA;
        }

        public function createNewFile(fromShortcut:Boolean):void
        {
            startPressHoldKey((!fromShortcut)?topBar.newFileButton:null,"Creating a new file..",null,clearData,null);
        }

        public function handleMouseClick(targetName:String):void
        {
            if(isAboutBoxOpened)
            {
                function onMouseUpAboutBox(e:MouseEvent):void
                {
                    stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUpAboutBox);
                    const upTargetName:String = e.target.name;
                    if(targetName === upTargetName)
                    {
                        switch(targetName)
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

                            // case "aboutMeLink":
                            //     navigateToURL(new URLRequest("https://twitter.com/ninanoninini"));
                            // break;

                            default:
                                closeAboutBox();
                            break;
                        }
                    }
                }
                stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpAboutBox);
                return;
            }

            function onMouseUp(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);

                const upTargetName:String = e.target.name;

                if(targetName === upTargetName)
                {
                    switch(upTargetName)
                    {
                        case "drawModeButton":
                        {
                            exitReplayMode();
                        }
                        break;

                        case "replayModeButton":
                        {
                            enterReplayMode();
                            isMouseClicked = false; //리플레이 버튼 누르고 나서 단축키가 안먹는 현상이 이거임
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
                            applyUIScale();
                        }
                        break;

                        case "updateButton":
                        {
                            prepareUpdate();
                        }
                        break;

                        case "sideBarPositionButton":
                        case "sideBarPositionButton2":
                        {
                            toggleSideBarPosition();
                        }
                        break;

                        case "sideBarOFFButton":
                        case "sideBarOFFButton2":
                        {
                            hideSidebarPermanent();
                        }
                        break;

                        case "sideBarONButton":
                        case "sideBarONButton2":
                        {
                            showSidebarPermanent();
                        }
                        break;

                        case "refLoadImageButton":
                        {
                            openLoadFileBrowser(true);
                        }
                        break;

                        case "saveButton":
                        {
                            openSaveFileBrowser(false);
                        }
                        break;

                        case "loadButton":
                        {
                            openLoadFileBrowser();
                        }
                        break;

                        case "clipBoardButton":
                        {
                            tryLoadClipboardImage(false);
                        }
                        break;

                        case "repCaptureButton":
                        case "captureButton":
                        {
                            enterCaptureMode();
                        }
                        break;

                        case "capRotate":
                        {
                            rotateCaptureImage(++captureCanvasRotationStep,false);
                        }
                        break;

                        case "capTrans":
                        {
                            applyTransparentCanvasBGCaptureMode(!isCaptureTransparentBGShowing);
                        }
                        break;

                        case "capClipBoard":
                        {
                            copyCaptureImageToCilpBoard();
                        }
                        break;

                        case "capSave":
                        {
                            saveCaptureImage();
                        }
                        break;

                        case "capOff":
                        {
                            handleExitCaptureMode();
                        }
                        break;

                        case "capFlip":
                        {
                            flipCaptureImage(!isCaptureCanvasFlipped,false);
                        }
                        break;

                        case "capStamp":
                        {
                            toggleCaptureStampButton();
                        }
                        break;

                        case "capStampFont":
                        {
                            showStampFontList();
                        }
                        break;

                        case "capFontListPrev":
                        {
                            captureStampFontListBox.updateNextFontList(false);
                        }
                        break;

                        case "capFontListNext":
                        {
                            captureStampFontListBox.updateNextFontList(true);
                        }
                        break;

                        case "topBarColorButton":
                        {
                            cycleUIColor();
                        }
                        break;

                        case "gridButton":
                        {
                            gridButton.start(false);
                        }
                        break;

                        case "aboutButton":
                        {
                            openAboutBox(false);
                        }
                        break;

                        case "newWindowCloseButton":
                        {
                            closeCanvasWindow()
                        }
                        break;

                        case "newWindowButton":
                        {
                            openImageViewWindow();
                        }
                        break;

                        case "replayZoomInButton":
                        {
                            zoomInCanvas(true,true);
                        }
                        break;

                        case "replayZoomOutButton":
                        {
                            zoomInCanvas(false,true);
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
                            setAsTopChild(refLayerMenuBox);
                            closeRefLayerMenu();
                        }
                        break;

                        case "refTransferCanvasImageButton":
                        {
                            mergeCanvasImageIntoRefLayer();
                        }
                        break;

                        case "refClipBoardButton":
                        {
                            if(refLayerMenuBox.refClipBoardButton.alpha === 1.0)
                            {
                                tryLoadClipboardImage(true);
                            }
                        }
                        break;

                        case "refMirrorImageButton":
                        {
                            setAsTopChild(refLayerMenuBox);
                            startRefLayerImageMirror();
                        }
                        break;

                        case "refMemoryTrainingOnButton":
                        case "refMemoryTrainingOffButton":
                        {
                            setAsTopChild(refLayerMenuBox);
                            toggleRefLayerMemoryTraining();
                        }
                        break;

                        case "playButton":
                        {
                            startReplay();
                        }
                        break;

                        case "pauseButton":
                        {
                            stopReplay();
                        }
                        break;

                        case "lassoRefLayer":
                        {
                            mergeLassoImageIntoToRefLayer();
                        }
                        break;

                        case "lassoOK":
                        {
                            applyLassoImageToCanvas();
                        }
                        break;

                        case "lassoCancel":
                        {
                            if(isLassoToolStarted === true)
                            {
                                cancelLassoTool();
                            }
                        }
                        break;

                        case "lassoLayerMerge":
                        {
                            if(lassoMenuBox.lassoLayerMerge.alpha === 1.0)
                            {
                                mergeLayerByLassoTool();
                            }
                        }
                        break;

                        case "lassoLayerSwap":
                        {
                            if(lassoMenuBox.lassoLayerSwap.alpha === 1.0)
                            {
                                swapLayerByLassoTool();
                            }
                        }
                        break;

                        case "lasso1pxUp":
                        {
                            move1PxLassoTool(LASSO_1PX_MOVE_UP);
                        }
                        break;

                        case "lasso1pxDown":
                        {
                            move1PxLassoTool(LASSO_1PX_MOVE_DOWN);
                        }
                        break;

                        case "lasso1pxLeft":
                        {
                            move1PxLassoTool(LASSO_1PX_MOVE_LEFT);
                        }
                        break;

                        case "lasso1pxRight":
                        {
                            move1PxLassoTool(LASSO_1PX_MOVE_RIGHT);
                        }
                        break;

                        case "lassoCopy":
                        {
                            copyCanvasImageToLassoTool();
                        }
                        break;


                        case "lassoMirror":
                        {
                            isLassoMirrorON = !isLassoMirrorON;
                            lassoLayer1.scaleX = -lassoLayer1.scaleX;
                            lassoLayer2.scaleX = lassoLayer1.scaleX;

                            //캔버스가 회전한각도도 있어서 항상 세로축을 중심으로 대칭되게 regpoint각도를 보정값으로 넣어줌
                            lassoLayer1.rotation = -lassoLayer1.rotation-(canvasAnchorPoint.rotation*2);
                            lassoLayer2.rotation = lassoLayer1.rotation;
                        }
                        break;

                        case "layerMergeButton":
                        {
                            mergeImageIntoLayer2();
                            showMouseHintTemp("Layers has been merged to layer 2");
                        }
                        break;

                        case "layerSwapButton":
                        {
                            swapLayer();
                            showMouseHintTemp(getCanvasLayerSwappedHintString());
                        }
                        break;

                        default:
                        break;
                    }
                }
            }
            stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUp);
        }

        public function syncDrawCanvasWithReplayCanvas():void
        {
            canvasZoomMultipler = rCanvasZoomMultiplier;
            canvasZoomIndex = rCanvasZoomIndex;
            canvasAnchorPoint.x = Math.floor(rCanvasAnchorPoint.x); //뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
            canvasAnchorPoint.y = Math.floor(rCanvasAnchorPoint.y);
            canvasAnchorPoint.scaleX = rCanvasAnchorPoint.scaleX;
            canvasAnchorPoint.scaleY = rCanvasAnchorPoint.scaleY;
            canvasAnchorPoint.rotation = rCanvasAnchorPoint.rotation;
            canvasPanel.x = Math.floor(rCanvasPanel.x);
            canvasPanel.y = Math.floor(rCanvasPanel.y);
            setRcursorRotation(rCanvasAnchorPoint.rotation);
        }

        public function hideReplayDeleteRangeBar():void
        {
            replayTimelineBox.deleteRangeBar.visible = false;
            replayTimelineBox.prograssBar.visible = true;
        }

        public function ensureReplayCanvasState():void
        {
            const rNowFrameBackup:Number = rNowFrame;
            renderReplayFrame(0,JUMP_FRAME_MANUAL);
            renderReplayFrame(rNowFrameBackup,JUMP_FRAME_MANUAL);
            isCanvasMirrored = rMirrorON;
            mirrorCommandReady = false;
            canvasInfoBox.setMirror(rMirrorON);
        }

        public function deleteReplayDataBeforeCurrentFrame():void
        {
            //미러 되어있을 수도 있기 때문에 워래 프레임 으로 점프해준뒤에 실행해줌
            ensureReplayCanvasState();

            hideReplayDeleteRangeBar();
            createFirstImageCache(rCanvasLayer1BitmapData,rCanvasLayer2BitmapData,RCANVAS_BG_COLOR);

            const fs:FileStream = new FileStream();

            if(rDataReadFlag)
            {
                //repfile 초기화
                undoManager.updateUndoBaseImageFromReplayMode();
                fs.open(replayDataFilePath,FileMode.WRITE); //파일 생성
                fs.close();

                isFileAlreadySaved = false;
                enableNewFileButton();
                undoManager.setRFileTotalFrame(0);

                rData.splice(0,rDataIndex+1);
                rDataFrame.splice(0,rDataIndex+1);
                updateTotalFrameAndReplayMaxSpeedFor10Sec(getTotalFrame());
                updateReplayPrograssText(true,TOTAL_FRAME);

                if(TOTAL_FRAME === 0)
                {
                    resetReplayPrograssBarWidth();
                }
                else
                {
                    setReplayPrograssBarMaxWidth();
                }
                
                topBar.repNewFileButton.alpha = Global.OFFALPHA;

                rReplayFOFOCursor.visible = false;
            }
            else
            {
                //make jumpimage에서 변경해주기 때문에
                if(repFileTemp.exists)//이미 있으면 지워주고
                {
                    repFileTemp.deleteFile();
                }
                var ba:ByteArray = new ByteArray();
                var d:Array;

                //짤라서 ba에 넣어주기
                fs.open(replayDataFilePath,FileMode.READ);
                fs.position = rFileLastBytePosition;
                fs.readBytes(ba,0,fs.bytesAvailable);
                fs.close();

                //ba에 넣어준걸 다시 써주기
                fs.open(replayDataFilePath,FileMode.WRITE);
                fs.position = 0;
                fs.writeBytes(ba,0,ba.length);
                fs.close();

                ba.clear();
                ba = null;

                rReplayFOFOCursor.visible = false;
                resetReplayPrograssBarWidth();
                isFileAlreadySaved = false;
                startGeneratingReplayCacheImage();
            }

            resetReplaySpeedBar();
            isReplayFinished = true;

            if(undoDataIndex > rData.length-1)
            {
                undoDataIndex = rData.length-1;
            }

            undoToIndex(undoDataIndex);
            disableDeepUndo();
            updateReplayPrograssBarAndText();
            updateReplaySpeedSliderAlpha();
            drawReplayByCommand.setFirstRCursorPosCurrent();
        }

        public function deleteReplayDataAfterCurrentFrame():void
        {
            ensureReplayCanvasState();
            hideReplayDeleteRangeBar();

            if(rDataReadFlag === true)
            {
                //위에서 setJumpOneFrame을 해줘서 rindex가 증가되었기 때문에
                //실제 undo해줘야할 인덱스는 -1해줘야하는거임
                undoToIndex(rDataIndex);
                rData.splice(rDataIndex+1);
                rDataFrame.splice(rDataIndex+1);
                updateTotalFrameAndReplayMaxSpeedFor10Sec(getTotalFrame());
                resetReplayTime();
            }
            else if(rDataReadFlag === false)
            {
                drawReplayByCommand.setFirstRCursorPosCurrent();
                const fs:FileStream = new FileStream();

                fs.open(replayDataFilePath,FileMode.UPDATE);
                fs.position = rFileLastBytePosition;
                fs.truncate(); //데이터 위에 짤라주고
                fs.close();

                //썸네일 이미지도 날려줌
                const rNowFrameSave:Number = rNowFrame;
                const list:Array = replayCacheImageFolderPath.getDirectoryListing();
                const index:Number = getCachedFrameImageIndex(rNowFrameSave);
                //index번 이후 파일 삭제
                for(var i:uint = 0,len:uint=list.length; i < len; i++)
                {
                    if(parseInt(list[i].name) > index)
                    {
                        list[i].deleteFile();
                    }
                }
                //framedata도 인덱스 이후꺼 날려줌
                rJumpImageFrameData.splice(index+1);
                undoManager.setRFileTotalFrame(rNowFrameSave);
                updateTotalFrameAndReplayMaxSpeedFor10Sec(rNowFrameSave);

                canvasLayer1BitmapData = updateBitmapData(canvasLayer1BitmapData,rCanvasLayer1BitmapData,canvasLayer1Bitmap);
                canvasLayer1Bitmap.bitmapData = canvasLayer1BitmapData;
                canvasLayer2BitmapData = updateBitmapData(canvasLayer1BitmapData,rCanvasLayer2BitmapData,canvasLayer2Bitmap);
                canvasLayer2Bitmap.bitmapData = canvasLayer2BitmapData;

                // mirrorON = rMirrorON;
                // mirrorCommandReady = false;
                // appInfoBox.setMirror(rMirrorON);
                updateCavnvasSizeDrawMode(canvasLayer1Bitmap.width,canvasLayer1Bitmap.height,0,0,false);
                updateCanvasBGColorDrawMode(RCANVAS_BG_COLOR);
                resetReplayTime();
                syncDrawCanvasWithReplayCanvas();
                resetUndoState();
                canvasNavigatorBox.updateImage(canvasLayer1BitmapData,canvasLayer2BitmapData,CANVAS_BG_COLOR);

                if(isCanvasWindowON)
                {
                    updateCanvasWindowImage();
                    updateCanvasWindowBitmapSize();
                }
            }

            updateReplayPrograssBarAndText();
            updateReplaySpeedSliderAlpha();
            updateDeleteReplayDataButtonsState();

            resetReplaySpeedBar();
            disableDeepUndo();

            if(isQuickSidebarActive)
            {
                deactivateQuickSidebar();
            }

            isContinueSaveON = false;
        }

        public function createNewFileFromReplayCanvas():void
        {
            hideReplayDeleteRangeBar();
            copyReplayCanvasDataToDrawCanvas();
            clearDataAndResetVars();
            syncDrawCanvasWithReplayCanvas();
            exitReplayMode();
            disableDeepUndo();
            resetReplayTime();
        }

        //addundo data에서 캔버스 비트맵 데이터가 변경되기 전, rdatabuffer 비어있을때 넣어줘야함
        public function applyDeepUndo():void
        {
            const fs:FileStream = new FileStream();

            fs.open(replayDataFilePath,FileMode.UPDATE);
            fs.position = rFileLastBytePosition;
            fs.truncate(); //데이터 위에 짤라주고
            fs.close();

            //썸네일 이미지도 날려줌
            const rNowFrameSave:Number = rNowFrame;
            const list:Array = replayCacheImageFolderPath.getDirectoryListing();
            const index:Number = getCachedFrameImageIndex(rNowFrameSave);
            const len:uint = list.length;
            //index번 이후 파일 삭제
            for(var i:uint=0;i<len;i++)
            {
                if(parseInt(list[i].name) > index)
                {
                    list[i].deleteFile();
                }
            }
            //framedata도 인덱스 이후꺼 날려줌
            rJumpImageFrameData.splice(index+1);
            undoManager.setRFileTotalFrame(rNowFrameSave);
            updateTotalFrameAndReplayMaxSpeedFor10Sec(rNowFrameSave);

            resetReplayTime();
            resetUndoState(true);
            rReplayFOFOCursor.visible = true;//대칭된 커서 위치를 갱신해주려고 임시로 켜줌
            // checkMirrorCanvasReplayMirror();
            canvasInfoBox.setMirror(isCanvasMirrored);
            drawReplayByCommand.setFirstRCursorPosCurrent();
            rReplayFOFOCursor.visible = false;

            canvasNavigatorBox.updateImage(canvasLayer1BitmapData,canvasLayer2BitmapData,CANVAS_BG_COLOR);

            if(isCanvasWindowON)
            {
                updateCanvasWindowImage();
                updateCanvasWindowBitmapSize();
            }

            disableDeepUndo();
        }

     

        public function prepareDeleteReplayDataBeforeCurrentFrame():Boolean
        {
            replayTimelineBox.deleteRangeBar.x = replayTimelineBox.trackBar.x;
            replayTimelineBox.deleteRangeBar.width = replayTimelineBox.prograssBar.width;
            replayTimelineBox.prograssBar.visible = false;
            replayTimelineBox.deleteRangeBar.visible = true;

            if(drawReplayByCommand.getCurrentPosition() < drawReplayByCommand.getDataLength())
            {
                finalizeRemainingReplayData();
                updateDeleteReplayDataButtonsState();
            }
            if(rNowFrame >= TOTAL_FRAME)
            {
                hideReplayDeleteRangeBar();
                return true;
            }

            return false;
        }

        public function prepareDeleteReplayDataAfterCurrentFrame():Boolean
        {
            const deleteBarWidth:Number = (replayTimelineBox.trackBar.width*(rNowFrame/TOTAL_FRAME));

            replayTimelineBox.deleteRangeBar.x = replayTimelineBox.trackBar.x+deleteBarWidth;
            replayTimelineBox.deleteRangeBar.width = (replayTimelineBox.trackBar.width-deleteBarWidth);
            replayTimelineBox.prograssBar.visible = false;
            replayTimelineBox.deleteRangeBar.visible = true;

            if(drawReplayByCommand.getCurrentPosition() < drawReplayByCommand.getDataLength())
            {
                finalizeRemainingReplayData();
                updateDeleteReplayDataButtonsState();
            }

            if(rNowFrame >= TOTAL_FRAME)
            {
                hideReplayDeleteRangeBar();
                return true;
            }

            return false;
        }

        public function prepareCreateNewFileFromReplayCanvas():void
        {
            replayTimelineBox.deleteRangeBar.x = replayTimelineBox.trackBar.x;
            replayTimelineBox.deleteRangeBar.width = replayTimelineBox.trackBar.width;
            replayTimelineBox.prograssBar.visible = false;
            replayTimelineBox.deleteRangeBar.visible = true;
        }

        public function initializeReplayDataFile(overWrite:Boolean = false):void //기본 리플레이 파일 만들어줌
        {
            initializeRepTempFile();
            if(replayDataFilePath.exists === false || overWrite === true)
            {
                const fs:FileStream = new FileStream();
                fs.open(replayDataFilePath,FileMode.WRITE);
                fs.close();
                createFirstImageCache(canvasLayer1BitmapData,canvasLayer2BitmapData,CANVAS_BG_COLOR);
            }
        }

        public function drawFirstJumpImage():void
        {
            const fs:FileStream = new FileStream();
            const file:File = replayCacheImageFolderPath.resolvePath("0");
            fs.open(file,FileMode.READ);
            const data:Array = fs.readObject() as Array;
            fs.close();
            data[0].uncompress();
            data[1].uncompress();
            var layer1:BitmapData = new BitmapData(data[2],data[3],true,0);
            var layer2:BitmapData = new BitmapData(data[2],data[3],true,0);
            const newRectangle:Rectangle = new Rectangle(0,0,data[2],data[3]);

            layer1.lock();
            layer1.setPixels(newRectangle,data[0]);
            layer1.unlock();

            layer2.lock();
            layer2.setPixels(newRectangle,data[1]);
            layer2.unlock();

            rCanvasLayer1BitmapData = updateBitmapData(rCanvasLayer1BitmapData,layer1,rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = updateBitmapData(rCanvasLayer2BitmapData,layer2,rCanvasLayer2Bitmap);

            layer1.dispose();
            layer2.dispose();
            layer1 = null;
            layer2 = null;

            updateCanvasSizeReplayMode(rCanvasLayer1Bitmap.width,rCanvasLayer1Bitmap.height);
            updateCanvasBGColorReplayMode(data[4]);
        }

        public function createFirstImageCache(bmpd1:BitmapData,bmpd2:BitmapData,bgColor:uint):void
        {
            if(replayCacheImageFolderPath.exists)
            {
                replayCacheImageFolderPath.deleteDirectory(true);
            }
            replayCacheImageFolderPath.createDirectory();

            const fs:FileStream = new FileStream();
            var ba1:ByteArray = new ByteArray();
            var ba2:ByteArray = new ByteArray();
            const w:Number = bmpd1.width;
            const h:Number = bmpd1.height;
            const newRectangle:Rectangle = new Rectangle(0,0,w,h);

            rJumpImageFrameData.length = 0;
            bmpd1.copyPixelsToByteArray(newRectangle,ba1);
            ba1.compress();
            rFirstImageLayer1BitmapData = updateBitmapData(rFirstImageLayer1BitmapData,bmpd1,null);

            if(bmpd2 === null) bmpd2 = new BitmapData(w,h,true,0);
            bmpd2.copyPixelsToByteArray(newRectangle,ba2);
            ba2.compress();
            rFirstImageLayer2BitmapData = updateBitmapData(rFirstImageLayer2BitmapData,bmpd2,null);

            rFirstImageBGColor = bgColor;
            createCacheImage(ba1,ba2,w,h,bgColor,0,0,false);

            ba1.clear();
            ba2.clear();
        }

        public function resetUndoState(fromReplayMode:Boolean=false):void
        {
            undoDataIndex = -1;
            if(fromReplayMode)
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

        public function fitCanvasToViewportMargin(captureMode:Boolean=false,manualFlag:Boolean=false):void
        {
            const replayMode:Boolean = isReplayModeON;
            const uiscale:Number = Global.getUIScale();
            const offsetX:Number = 44+STAGE_LEFT_OFFSET+STAGE_RIGHT_OFFSET;
            const offsetY:Number = (captureMode) ? (topBar.BARSIZE)*uiscale+45*uiscale : (topBar.BARSIZE+replayTimelineBox.BARSIZE)*uiscale+45*uiscale;
            const stw:int = stage.stageWidth-offsetX;
            const sth:int = stage.stageHeight-offsetY-STAGE_BOTTOM_OFFSET-mouseHint.getDefaultHeight()*uiscale;
            var xBitmap1:Bitmap;
            var xBitmap11:Bitmap;
            var xAnc:Sprite;
            var w:Number;
            var h:Number;
            var _captureRotated:uint;

            if(replayMode)
            {
                xBitmap1 = rCanvasLayer1Bitmap;
                xBitmap11 = rCanvasLayer2Bitmap;
                xAnc = rCanvasAnchorPoint;

                if(manualFlag)
                {
                    xAnc.scaleX = 1.0;
                    xAnc.scaleY = 1.0; //크기를 원래대로 해놓고 해야 길이 측정이 됨
                    const b:Rectangle = rCanvasLayer1Bitmap.getBounds(stage);
                    w = b.right-b.left;
                    h = b.bottom-b.top;
                }
                else
                {
                    w = RCANVAS_WIDTH;
                    h = RCANVAS_HEIGHT;
                }
            }
            else
            {
                xBitmap1 = canvasLayer1Bitmap;
                xBitmap11 = canvasLayer2Bitmap;
                xAnc = canvasAnchorPoint;
                w = CANVAS_WIDTH;
                h = CANVAS_HEIGHT;
            }

            if(captureMode)
            {
                _captureRotated = captureCanvasRotationStep;
                if(captureCanvasRotationStep === 1 || captureCanvasRotationStep === 3)
                {
                    const widthSave:Number = w;
                    w = h;
                    h = widthSave;
                }
            }

            //줌이 1.0 보다 작고 가로 세로 줌비율이 가장 작은걸로 선택
            var z:Number = stw/w;
            const zh:Number = sth/h;

            if(zh < z) z = zh;
            if(z > 1.0) z = 1.0;

            if(captureMode)
            {
                xAnc.rotation = 90*_captureRotated;
            }

            if(replayMode === true && z < 1.0 && !isReplayCanvasFitToWindow)
            {
                isReplayFinishedWithFiwWindow = true;
            }

            updateCanvasScale(z,replayMode);
            centerCanvas(replayMode,captureMode);

            if(!manualFlag || isReplayFinished)
            {
                xBitmap1.smoothing = true;
                xBitmap11.smoothing = true;
            }

            // if(captureMode)
            // {
            //     drawCaptureArea.updateDrawArea("fitCanvasToWindow");
            // }
        }
        

        public function replayCompleteEffect():void
        {
            replayTimelineBox.playButton.visible = true;
            replayTimelineBox.pauseButton.visible = false;

            Global.setColorTransform(replayTimelineBox.prograssBar,Global.getUIReplayRestartBarColor());

            //재생이 끝나면 전체화면을 보여줌
            if(!isMouseClicked)
            {
                fitCanvasToViewportMargin();
                rCanvasZoomIndex = canvasZoomMultiplerList.indexOf(1.0);
            }

            applyCanvasFlashEffect(rCanvasPanel,0,0,RCANVAS_WIDTH,RCANVAS_HEIGHT);
        }

        public function cancelReplayRestartTimer():void
        {
            removeTimer("replayRestartTimer");

            //재시작 카운터가 돌아갈때 1프레임 스킵을 하면
            //프레임 정보가 나오지 않고 END가 나와서 조건 걸어줌
            if(rReplayRestartTimerCount < 10)
            {
                replayTimelineBox.prograssInfo.text = TOTAL_FRAME+" / " +TOTAL_FRAME;
            }
            rReplayRestartTimerCount = 10;
            Global.setColorTransform(replayTimelineBox.prograssBar,Global.getUIReplayEndBarColor());

            stage.removeEventListener(MouseEvent.MOUSE_DOWN,onMouseKeyDownRemoveRestartTimer);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onMouseKeyDownRemoveRestartTimer);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,onMouseKeyDownRemoveRestartTimer);
        }

        public function onMouseKeyDownRemoveRestartTimer(e:Object):void
        {
            cancelReplayRestartTimer();
        }

        public function startReplayRestartTimer():void
        {
            if(isReplayRepeatON)
            {
                rReplayRestartTimerCount = 10;

                stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseKeyDownRemoveRestartTimer);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onMouseKeyDownRemoveRestartTimer);
                stage.addEventListener(KeyboardEvent.KEY_DOWN,onMouseKeyDownRemoveRestartTimer);

                addTimerByName("replayRestartTimer",1.0,true,function():Boolean
                {
                    if(rReplayRestartTimerCount === 0)
                    {
                        cancelReplayRestartTimer();
                        startReplay();
                        return false;
                    }

                    const str:String = "Play again in " + rReplayRestartTimerCount +" sec";
                    replayTimelineBox.prograssInfo.text = str;
                    --rReplayRestartTimerCount;
                    return true;
                });
            }
            else
            {
                rReplayRestartTimerCount = 9;
                cancelReplayRestartTimer();
            }
        }

        public function resetReplaySpeedBar():void
        {
            rReplaySpeedMultipler = 1.0; //속도 리셋
            topBar.replaySpeedSliderCursor.x = topBar.replaySpeedSlider.x+1.5;
        }

        //total frame file max frame등등은 수동으로 초기화
        //이건 리플레이 시간을 초기화 시켜주는것 뿐임 데이터는 건드리지 않음
        public function resetReplayTime():void
        {
            //어떤 이유가 있어서 rDataReadFlag는 여기 넣으면 안됨 수동으로 조절
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
            rSpeedLastHint = "";
            drawReplayByCommand.clearData();
        }

        public function applyLassoShapen(scale:Number):void
        {
            if(scale === 0.0) return;

            var index:uint = Math.abs(Math.floor(scale-1.0));
            if(index > 2) index = 2;

            var sharpen:ConvolutionFilter = new ConvolutionFilter(3,3,LASSO_SHARP_DATA[index][0],LASSO_SHARP_DATA[index][1]);

            lassoLayer1Bitmap.filters = [sharpen];
            lassoLayer2Bitmap.filters = [sharpen];
        }

        public function selectReplaySubLayer(flag:Boolean):void
        {
            rLastLayer2Selcted = flag;

            if(flag)
            {
                if(rCanvasPanel.getChildIndex(rCanvasDrawLayer) > rCanvasPanel.getChildIndex(rCanvasLayer1Bitmap))
                {
                    rCanvasPanel.setChildIndex(rCanvasDrawLayer,rCanvasPanel.getChildIndex(rCanvasLayer1Bitmap));
                }
            }
            else if(rCanvasPanel.getChildIndex(rCanvasDrawLayer) < rCanvasPanel.getChildIndex(rCanvasLayer1Bitmap))
            {
                rCanvasPanel.setChildIndex(rCanvasDrawLayer,rCanvasPanel.getChildIndex(rCanvasLayer1Bitmap));
            }
        }

        public function moveImageReplayMode(x:Number,y:Number,layer1:Boolean,layer2:Boolean):void
        {
            var tmpbmpd:BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
            var movedMat:Matrix = new Matrix();
            if(!layer1 && !layer2)
            {
                layer1 = true;
                layer2 = true;
            }

            movedMat.translate(x,y);

            if(layer1)
            {
                tmpbmpd.draw(rCanvasLayer1BitmapData,movedMat);
                rCanvasLayer1BitmapData = updateBitmapData(rCanvasLayer1BitmapData,tmpbmpd,rCanvasLayer1Bitmap);
            }

            if(layer2)
            {
                tmpbmpd.fillRect(new Rectangle(0,0,RCANVAS_WIDTH,RCANVAS_HEIGHT),0);
                tmpbmpd.draw(rCanvasLayer2BitmapData,movedMat);

                rCanvasLayer2BitmapData = updateBitmapData(rCanvasLayer2BitmapData,tmpbmpd,rCanvasLayer2Bitmap);
            }
            tmpbmpd.dispose();
            tmpbmpd = null;
        }

        public function replayLineStyleReady(shape:Boolean,size:uint,color:uint,alpha:Number):void
        {
            rCanvasDrawLayer.alpha = alpha;
            if(shape)
            {
                rCanvasDrawShape.graphics.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
            }
            else
            {
                rCanvasDrawShape.graphics.lineStyle(size,color);
            }
        }

        public function replayLineStyleReady2(shape:Boolean,size:uint,color:uint,alpha:Number):void
        {
            rCanvasDrawLayer.alpha = alpha;
            if(shape)
            {
                rCanvasDrawShape.graphics.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.BEVEL);
            }
            else
            {
                rCanvasDrawShape.graphics.lineStyle(size,color);
            }
        }

        public function replayLineStyleReady3(shape:Boolean,size:uint,color:uint,alpha:Number):void
        {
            rCanvasDrawLayer.alpha = alpha;
            if(shape)
            {
                rCanvasDrawShape.graphics.lineStyle(size,color,1,false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.BEVEL);
            }
            else
            {
                rCanvasDrawShape.graphics.lineStyle(size,color);
            }
        }


        public function mirrorCanvasReplayMode():void
        {
            var tmpbmpd:BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
            var flipMat:Matrix = new Matrix(-1,0,0,1,RCANVAS_WIDTH);

            tmpbmpd.draw(rCanvasLayer1BitmapData,flipMat);

            rCanvasLayer1BitmapData = updateBitmapData(rCanvasLayer1BitmapData,tmpbmpd,rCanvasLayer1Bitmap);

            tmpbmpd.fillRect(new Rectangle(0,0,RCANVAS_WIDTH,RCANVAS_HEIGHT),0);
            tmpbmpd.draw(rCanvasLayer2BitmapData,flipMat);

            rCanvasLayer2BitmapData = updateBitmapData(rCanvasLayer2BitmapData,tmpbmpd,rCanvasLayer2Bitmap);

            tmpbmpd.dispose();
            tmpbmpd = null;

            rMirrorON = !rMirrorON;

            if(isReplayCanvasFitToWindow)
            {
                fitReplayCanvasToWindow();
            }
        }

        public function cDrawReplayDataCommands():Object
        {
            const rCursorPos:Point = new Point(0,0);
            //undo인덱스가 처음일때 tickdraw가 아무것도 안해주니까 위치 갱신이 안되서
            //undorefimage갱신 될때 마다 마지막 포인터 위치 저장해주는거
            const rCursorPosFirst:Point = new Point(-1,-1);

            var lineStyleBackup:Array = [1.0,null]//tempdone에서 쓰는 플래그임
            var index:uint = 0;
            var data:Array = [];//데이터 뭉치

            const cmd:Vector.<int> = new Vector.<int>();
            const pos:Vector.<Number> = new Vector.<Number>();

            function updateLineStyleBackup(alpha:Number,blendMode:String):void
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
                rCursorPosFirst.setTo(-1,-1);
            }

            function setFirstRCursorPos(x:Number,y:Number):void
            {
                rCursorPosFirst.setTo(x,y);
            }

            function setFirstRCursorPosCurrent():void
            {
                rCursorPosFirst.setTo(rCursorPos.x,rCursorPos.y);
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

            function setRCursorPosFromMoveTool(x:Number,y:Number):void
            {
                setRCursorPos(rCursorPos.x+x,rCursorPos.y+y)
            }

            function setRCursorPosToCenter():void
            {
                setRCursorPos(RCANVAS_WIDTH/2,RCANVAS_HEIGHT/2);
            }

            function setRCursorPos(x:Number,y:Number):void
            {
                if(x < 0) x = 0;
                else if(x > RCANVAS_WIDTH) x = RCANVAS_WIDTH;

                if(y < 0) y = 0;
                else if(y > RCANVAS_HEIGHT) y = RCANVAS_HEIGHT;

                rCursorPos.setTo(x,y);
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

            function setData(refData:Array,startIndex:uint=0):void
            {
                data = refData;
                index = startIndex;
            }

            function getRemainingData():uint
            {
                if(!data) return 0;
                return data.length-index;
            }

            function isReadFinished():Boolean
            {
                if(!data) return true;
                return index > data.length-1;
            }

            function getDataLength():uint
            {
                if(!data) return 0;
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
                if(lineStyleBackup.length !== 2) return [1.0,null];

                return lineStyleBackup;
            }

            function drawAll():void
            {
                var len:uint = data.length;
                for(var i:uint = 0; i < len; i++)
                {
                    drawNext();
                }
            }

            function checkAirBrush(airBrushFlag:Boolean,size:uint):void
            {
                if(airBrushFlag === true)
                {
                    if(rAirBrushSize !== size) blurReplayCanvasByValue(size);
                }
                else if(rAirBrushSize > 0)
                {
                    resetBlurReplayCanvas();
                }
            }

            function checkSubLayer(subLayerFlag:Boolean):void
            {
                if(subLayerFlag)
                {
                    // if((replayStartON && subLayerFlag) !== false && rSubLayerSave !== subLayerFlag)
                    if(rLastLayer2Selcted !== subLayerFlag)
                    {
                        selectReplaySubLayer(subLayerFlag);
                    }
                }
                else if(rLastLayer2Selcted)
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

                updateLineStyleBackup(alpha,blendMode);
                checkSubLayer(subLayer);

                rAirBrushSize2 = airBrushSize;

                if(fillpen)
                {
                    rCanvasDrawShape.graphics.clear();
                    replayLineStyleReady2(false,1,color,1.0);
                    rCanvasDrawShape.graphics.beginFill(color);
                    rCanvasDrawShape.graphics.moveTo(startX,startY);
                    rCanvasDrawLayer.alpha = alpha;
                }
                else
                {
                    replayLineStyleReady3(shape,size,color,alpha);
                    rCanvasDrawShape.graphics.moveTo(startX,startY);
                }

                if(index === 0)
                {
                    resetRCanvasDrawLayerCliprect2();
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

                updateLineStyleBackup(alpha,blendMode);
                checkSubLayer(subLayer);
                checkAirBrush(airBrush,size);

                if(fillpen)
                {
                    rCanvasDrawShape.graphics.clear();
                    replayLineStyleReady2(false,1,color,1.0);
                    rCanvasDrawShape.graphics.beginFill(color);
                    rCanvasDrawShape.graphics.moveTo(startX,startY);
                    rCanvasDrawLayer.alpha = alpha;
                }
                else
                {
                    replayLineStyleReady3(shape,size,color,alpha);
                    rCanvasDrawShape.graphics.moveTo(startX,startY);
                }

                if(index === 0)
                {
                    resetRCanvasDrawLayerCliprect();
                }
                else
                {
                    updateRCanvasDrawLayerCliprect();
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

                updateLineStyleBackup(alpha,blendMode);
                checkSubLayer(subLayer);
                checkAirBrush(airBrush,size);

                if(!fillpen)
                {
                    replayLineStyleReady3(shape,size,color,alpha);
                    rCanvasDrawShape.graphics.moveTo(startX,startY);
                }
                else
                {
                    rCanvasDrawShape.graphics.clear();
                    replayLineStyleReady2(false,1,color,1.0);
                    rCanvasDrawShape.graphics.beginFill(color);
                    rCanvasDrawShape.graphics.moveTo(startX,startY);
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

                updateLineStyleBackup(alpha,blendMode);
                checkSubLayer(subLayer);
                checkAirBrush(airBrush,size);

                if(!fillpen)
                {
                    replayLineStyleReady2(shape,size,color,alpha);
                    rCanvasDrawShape.graphics.moveTo(startX,startY);
                }
                else
                {
                    rCanvasDrawShape.graphics.clear();
                    replayLineStyleReady2(false,1,color,1.0);
                    rCanvasDrawShape.graphics.beginFill(color);
                    rCanvasDrawShape.graphics.moveTo(startX,startY);
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

                updateLineStyleBackup(alpha,blendMode);
                checkSubLayer(subLayer);
                checkAirBrush(airBrush,size);

                if(!fillpen)
                {
                    replayLineStyleReady(shape,size,color,alpha);
                    rCanvasDrawShape.graphics.moveTo(startX,startY);
                }
                else
                {
                    rCanvasDrawShape.graphics.clear();
                    replayLineStyleReady(false,1,color,1.0);
                    rCanvasDrawShape.graphics.beginFill(color);
                    rCanvasDrawShape.graphics.moveTo(startX,startY);
                    rCanvasDrawLayer.alpha = alpha;
                }
            }

            function lineTo(data:Array):void
            {
                const x:Number = data[1];
                const y:Number = data[2];

                rCanvasDrawShape.graphics.lineTo(x,y);
                setRCursorPos(x,y);
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
                rCanvasDrawLayerBitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
                rCanvasDrawShape.graphics.clear();

                updateLineStyleBackup(alpha,blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.lineStyle(size,color,1,false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
                rCanvasDrawShape.graphics.drawPath(command,xyData);
                setRCursorPos(xyData[xyData.length-2],xyData[xyData.length-1]);
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
                updateLineStyleBackup(alpha,blendMode);

                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.clear();
                rCanvasDrawShape.graphics.lineStyle(1,color);
                rCanvasDrawShape.graphics.beginFill(color);
                rCanvasDrawShape.graphics.drawPath(command,xyData);
                setRCursorPos(xyData[xyData.length-2],xyData[xyData.length-1]);
                resetRCanvasDrawLayerCliprect2();
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

                checkAirBrush(airBrushFlag,airBrushSize);
                updateLineStyleBackup(alpha,blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.clear();
                rCanvasDrawShape.graphics.lineStyle(1,color);
                rCanvasDrawShape.graphics.beginFill(color);
                rCanvasDrawShape.graphics.drawPath(command,xyData);
                setRCursorPos(xyData[xyData.length-2],xyData[xyData.length-1]);
                resetRCanvasDrawLayerCliprect();
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

                checkAirBrush(airBrushFlag,airBrushSize);
                updateLineStyleBackup(alpha,blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.clear();
                rCanvasDrawShape.graphics.lineStyle(1,color);
                rCanvasDrawShape.graphics.beginFill(color);
                rCanvasDrawShape.graphics.drawPath(command,xyData);
                setRCursorPos(xyData[xyData.length-2],xyData[xyData.length-1]);
            }

            function fill2(data:Array):void
            {
                const color:Number = data[1];
                const alpha:Number = data[2];
                const blendMode:String = data[3];
                const arr:Vector.<Number> = data[4];
                const len:uint = arr.length;

                resetBlurReplayCanvas();
                updateLineStyleBackup(alpha,blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.clear();
                rCanvasDrawShape.graphics.lineStyle(1,color);
                rCanvasDrawShape.graphics.beginFill(color);
                rCanvasDrawShape.graphics.moveTo(arr[0],arr[1]);

                for(var i:uint = 2;i<len;i+=2)
                {
                    rCanvasDrawShape.graphics.lineTo(arr[i],arr[i+1]);
                }

                rCanvasDrawShape.graphics.endFill();
                setRCursorPos(arr[len-2],arr[len-1]);
            }

            function fill(data:Array):void
            {
                const color:Number = data[1];
                const alpha:Number = data[2];
                const blendMode:String = data[3];
                const command:Vector.<int> = data[4];
                const xyData:Vector.<Number> = data[5];

                resetBlurReplayCanvas();
                updateLineStyleBackup(alpha,blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.clear();
                rCanvasDrawShape.graphics.lineStyle(1,color);
                rCanvasDrawShape.graphics.beginFill(color);
                rCanvasDrawShape.graphics.drawPath(command,xyData);
                setRCursorPos(xyData[xyData.length-2],xyData[xyData.length-1]);
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
                updateLineStyleBackup(alpha,blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.lineStyle(0,0,0);
                rCanvasDrawShape.graphics.beginFill(color);

                if(shape)
                {
                    cmd.length = 0;
                    pos.length = 0;
                    const halfSize:Number = size/2;
                    var point:Point = rotatePoint(-halfSize,-halfSize,rotation);

                    cmd.push(1);
                    pos.push(startX+point.x);
                    pos.push(startY+point.y);

                    point = rotatePoint(halfSize,-halfSize,rotation);
                    cmd.push(2);
                    pos.push(startX+point.x);
                    pos.push(startY+point.y);

                    point = rotatePoint(halfSize,halfSize,rotation);
                    cmd.push(2);
                    pos.push(startX+point.x);
                    pos.push(startY+point.y);

                    point = rotatePoint(-halfSize,halfSize,rotation);
                    cmd.push(2);
                    pos.push(startX+point.x);
                    pos.push(startY+point.y);

                    rCanvasDrawShape.graphics.drawPath(cmd,pos);

                    point = null;
                }
                else
                {
                    rCanvasDrawShape.graphics.drawCircle(startX,startY,size/2);
                }

                rCanvasDrawShape.graphics.endFill();
                resetRCanvasDrawLayerCliprect2();
                setRCursorPos(startX,startY);
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
                checkAirBrush(airBrush,size);
                updateLineStyleBackup(alpha,blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.lineStyle(0,0,0);
                rCanvasDrawShape.graphics.beginFill(color);

                if(shape)
                {
                    cmd.length = 0;
                    pos.length = 0;

                    const p0:Point = rotatePoint(-size/2,-size/2,rotation);
                    cmd.push(1);
                    pos.push(startX+p0.x);
                    pos.push(startY+p0.y);

                    const p1:Point = rotatePoint(+size/2,-size/2,rotation);
                    cmd.push(2);
                    pos.push(startX+p1.x);
                    pos.push(startY+p1.y);

                    const p2:Point = rotatePoint(+size/2,+size/2,rotation);
                    cmd.push(2);
                    pos.push(startX+p2.x);
                    pos.push(startY+p2.y);

                    const p3:Point = rotatePoint(-size/2,+size/2,rotation);
                    cmd.push(2);
                    pos.push(startX+p3.x);
                    pos.push(startY+p3.y);

                    rCanvasDrawShape.graphics.drawPath(cmd,pos);
                }
                else
                {
                    rCanvasDrawShape.graphics.drawCircle(startX,startY,size/2);
                }

                rCanvasDrawShape.graphics.endFill();

                resetRCanvasDrawLayerCliprect();
                setRCursorPos(startX,startY);
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
                checkAirBrush(airBrush,size);
                updateLineStyleBackup(alpha,blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.lineStyle(0,0,0);
                rCanvasDrawShape.graphics.beginFill(color);

                if(shape) rCanvasDrawShape.graphics.drawRect(startX-size/2,startY-size/2,size,size);
                else rCanvasDrawShape.graphics.drawCircle(startX,startY,size/2);
                rCanvasDrawShape.graphics.endFill();

                resetRCanvasDrawLayerCliprect();
                setRCursorPos(startX,startY);
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
                checkAirBrush(airBrush,size);
                updateLineStyleBackup(alpha,blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.lineStyle(0,0,0);
                rCanvasDrawShape.graphics.beginFill(color);

                if(shape) rCanvasDrawShape.graphics.drawRect(startX-size/2,startY-size/2,size,size);
                else rCanvasDrawShape.graphics.drawCircle(startX,startY,size/2);
                rCanvasDrawShape.graphics.endFill();

                setRCursorPos(startX,startY);
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

                updateLineStyleBackup(alpha,blendMode);
                rCanvasDrawLayer.alpha = alpha;

                checkSubLayer(subLayer);
                rAirBrushSize2 = airBrushSize;

                if(shape) rCanvasDrawShape.graphics.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.ROUND);
                else rCanvasDrawShape.graphics.lineStyle(size,color);

                rCanvasDrawShape.graphics.moveTo(startX,startY);
                rCanvasDrawShape.graphics.lineTo(endX,endY);

                resetRCanvasDrawLayerCliprect2();
                setRCursorPos(endX,endY);
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

                updateLineStyleBackup(alpha,blendMode);
                rCanvasDrawLayer.alpha = alpha;

                checkSubLayer(subLayer);
                checkAirBrush(airBrush,size);

                if(shape) rCanvasDrawShape.graphics.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.ROUND);
                else rCanvasDrawShape.graphics.lineStyle(size,color);

                rCanvasDrawShape.graphics.moveTo(startX,startY);
                rCanvasDrawShape.graphics.lineTo(endX,endY);

                resetRCanvasDrawLayerCliprect();
                setRCursorPos(endX,endY);
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

                updateLineStyleBackup(alpha,blendMode);
                rCanvasDrawLayer.alpha = alpha;

                checkSubLayer(subLayer);
                checkAirBrush(airBrush,size);

                if(shape) rCanvasDrawShape.graphics.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.ROUND);
                else rCanvasDrawShape.graphics.lineStyle(size,color);

                rCanvasDrawShape.graphics.moveTo(startX,startY);
                rCanvasDrawShape.graphics.lineTo(endX,endY);

                setRCursorPos(endX,endY);
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

                updateLineStyleBackup(alpha,blendMode);
                rCanvasDrawLayer.alpha = alpha;

                checkSubLayer(subLayer);
                checkAirBrush(airBrush,size);

                if(shape) rCanvasDrawShape.graphics.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
                else rCanvasDrawShape.graphics.lineStyle(size,color);

                rCanvasDrawShape.graphics.moveTo(startX,startY);
                rCanvasDrawShape.graphics.lineTo(endX,endY);

                setRCursorPos(endX,endY);
            }

            function move1(data:Array):void
            {
                moveImageReplayMode(data[1],data[2],true,false);
                setRCursorPosFromMoveTool(data[1],data[2]);
            }

            function move2(data:Array):void
            {
                moveImageReplayMode(data[1],data[2],false,true);
                setRCursorPosFromMoveTool(data[1],data[2]);
            }

            function move(data:Array):void
            {
                moveImageReplayMode(data[1],data[2],true,true);
                setRCursorPosFromMoveTool(data[1],data[2]);
            }

            function resetLassoVars():void
            {
                lassoLayer1Bitmap.filters = [];
                lassoLayer2Bitmap.filters = [];

                if(lassoLayer1Bitmap.bitmapData) lassoLayer1Bitmap.bitmapData.dispose();
                if(lassoLayer2Bitmap.bitmapData) lassoLayer2Bitmap.bitmapData.dispose();

                lassoLayer1.x = 0;
                lassoLayer1.y = 0;
                lassoLayer1.scaleX = 1.0;
                lassoLayer1.scaleY = 1.0;
                lassoLayer1.rotation = 0;
                lassoLayer1.visible = false;

                lassoLayer2.x = 0;
                lassoLayer2.y = 0;
                lassoLayer2.scaleX = 1.0;
                lassoLayer2.scaleY = 1.0;
                lassoLayer2.rotation = 0;
                lassoLayer2.visible = false;
            }

            //성능 문제로 샤픈 안해줌
            function lasso2(data:Array,clearOnly:Boolean):void
            {
                if(data[1].length === 0 || data[2].length === 0) return;

                var imageMovedToLasso:Boolean;
                if(data.length <= 5)
                {
                    if(data[3] === null || (data[3] is Array && data[3].length === 0))
                    {
                        //(["lasso",point1,point2,null,lassoInfo]); 초기 버전 데이터 구조 3번이 비어있음
                        //(["lasso",point1,point2,[],lassoInfo]);
                        imageMovedToLasso = moveSelectedAreaToLassoBox(true,data[1],data[2],false,true,true);
                    }
                    else if(data[3].length === 7)
                    {
                        //(["lasso",point1,point2,lassoInfo]); 2019년판 구버전
                        //(["lasso",point1,point2,lassoInfo,lassoCopyON])
                        imageMovedToLasso = moveSelectedAreaToLassoBox(true,data[1],data[2],data[4],true,true);
                    }
                }
                else
                {
                    //(["lasso",point1,point2,lassoInfo,lassoCopyON,canvas1Bitmap.visible,canvas11Bitmap.visible,lassoLayerSwappedFlag]); 신버전 데이터 길이가 6이상임
                    // ["lasso",point1,point2,lassoInfo,lassoCopyON,checklayer1,checklayer2,command] // 신버전 데이터
                    imageMovedToLasso = moveSelectedAreaToLassoBox(true,data[1],data[2],data[4],data[5],data[6]);
                }

                if(imageMovedToLasso && !clearOnly)
                {
                    var lassoInfo:Array = (data[3] is Array && data[3].length === 7) ? data[3]:data[4];
                    const bmpScaleX:Number = lassoInfo[0];
                    const bmpScaleY:Number = lassoInfo[1];
                    const bmpWidth:Number = lassoInfo[2];
                    const bmpHeight:Number = lassoInfo[3];
                    const bmpAngle:Number = lassoInfo[4];
                    const boxX:Number = lassoInfo[5];
                    const boxY:Number = lassoInfo[6];
                    const mat:Matrix = new Matrix();

                    mat.scale(bmpScaleX,bmpScaleY);
                    mat.translate(-bmpWidth/2,-bmpHeight/2);
                    mat.rotate(bmpAngle);
                    mat.translate(boxX,boxY);

                    setRCursorPos(boxX,boxY);

                    lassoLayer1Bitmap.smoothing = true;
                    lassoLayer2Bitmap.smoothing = true;

                    if(data[7] as Boolean)
                    {
                        if(data[7] === true)
                        {
                            swapLassoImage();
                        }
                    }
                    else if(data[7] as Array)
                    {
                        const len:uint = data[7].length;

                        for(var i:uint=0;i<len;i++)
                        {
                            if(data[7][i] === 0)
                            {
                                swapLassoImage();
                            }
                            else if(data[7][i] === 1)
                            {
                                mergeLassoImage();
                            }
                        }
                    }

                    if(data[5] || !data[5] && !data[6])
                    {
                        rCanvasLayer1BitmapData.draw(lassoLayer1Bitmap,mat);
                        rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                    }

                    if(data[6])
                    {
                        rCanvasLayer2BitmapData.draw(lassoLayer2Bitmap,mat);
                        rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                    }
                }

                resetLassoVars();
            }

            function lasso(data:Array,clearOnly:Boolean):void
            {
                if(data[1].length === 0 || data[2].length === 0) return;

                var imageMovedToLasso:Boolean;
                if(data.length <= 5)
                {
                    if(data[3] === null || (data[3] is Array && data[3].length === 0))
                    {
                        //(["lasso",point1,point2,null,lassoInfo]); 초기 버전 데이터 구조 3번이 비어있음
                        //(["lasso",point1,point2,[],lassoInfo]);
                        imageMovedToLasso = moveSelectedAreaToLassoBox(true,data[1],data[2],false,true,true);
                    }
                    else if(data[3].length === 7)
                    {
                        //(["lasso",point1,point2,lassoInfo]); 2019년판 구버전
                        //(["lasso",point1,point2,lassoInfo,lassoCopyON])
                        imageMovedToLasso = moveSelectedAreaToLassoBox(true,data[1],data[2],data[4],true,true);
                    }
                }
                else
                {
                    //(["lasso",point1,point2,lassoInfo,lassoCopyON,canvas1Bitmap.visible,canvas11Bitmap.visible,lassoLayerSwappedFlag]); 신버전 데이터 길이가 6이상임
                    // ["lasso",point1,point2,lassoInfo,lassoCopyON,checklayer1,checklayer2,command] // 신버전 데이터
                    imageMovedToLasso = moveSelectedAreaToLassoBox(true,data[1],data[2],data[4],data[5],data[6]);
                }

                if(imageMovedToLasso && !clearOnly)
                {
                    var lassoInfo:Array = (data[3] is Array && data[3].length === 7) ? data[3]:data[4];
                    const bmpScaleX:Number = lassoInfo[0];
                    const bmpScaleY:Number = lassoInfo[1];
                    const bmpWidth:Number = lassoInfo[2];
                    const bmpHeight:Number = lassoInfo[3];
                    const bmpAngle:Number = lassoInfo[4];
                    const boxX:Number = lassoInfo[5];
                    const boxY:Number = lassoInfo[6];
                    const mat:Matrix = new Matrix();

                    mat.scale(bmpScaleX,bmpScaleY);
                    mat.translate(-bmpWidth/2,-bmpHeight/2);
                    mat.rotate(bmpAngle);
                    mat.translate(boxX,boxY);

                    setRCursorPos(boxX,boxY);

                    lassoLayer1Bitmap.smoothing = true;
                    lassoLayer2Bitmap.smoothing = true;

                    if(data[7] as Boolean)
                    {
                        if(data[7] === true)
                        {
                            swapLassoImage();
                        }
                    }
                    else if(data[7] as Array)
                    {
                        const len:uint = data[7].length;

                        for(var i:uint=0;i<len;i++)
                        {
                            if(data[7][i] === 0)
                            {
                                swapLassoImage();
                            }
                            else if(data[7][i] === 1)
                            {
                                mergeLassoImage();
                            }
                        }
                    }

                    if(bmpScaleX !== 1 || bmpAngle !== 0)
                    {
                        applyLassoShapen(bmpScaleX);
                    }

                    if(data[5] || !data[5] && !data[6])
                    {
                        rCanvasLayer1BitmapData.draw(lassoLayer1Bitmap,mat);
                        rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                    }

                    if(data[6])
                    {
                        rCanvasLayer2BitmapData.draw(lassoLayer2Bitmap,mat);
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

                updateCanvasSizeReplayMode(width,height,moveX,moveY,movedFlag);
                setRCursorPos(width/2,height/2);
            }

            function tempDone4(data:Array):void
            {
                if(rAirBrushSize2 > 0)
                {
                    const blurSize:Number = getBlurSize(rAirBrushSize2,1.0);
                    rCanvasDrawShape.filters = [new BlurFilter(blurSize,blurSize,3)];
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    canvasDrawLayerChild.filters = [];
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
                if(rAirBrushSize > 0 && rCanvasZoomMultiplier !== 1.0)
                {
                    blurReplayCanvasByDefaultValue();
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                    updateRCanvasDrawLayerCliprect();
                    rCanvasDrawShape.graphics.clear();
                    blurReplayCanvasByValue(rAirBrushSize);
                }
                else
                {
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                    updateRCanvasDrawLayerCliprect();
                    rCanvasDrawShape.graphics.clear();
                }
            }

            function tempDone(data:Array):void
            {
                if(rAirBrushSize > 0 && rCanvasZoomMultiplier !== 1.0)
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
                const canvasAlpha:ColorTransform = new ColorTransform(1,1,1,lineStyleData[0]);

                if(rAirBrushSize2 > 0)
                {
                    const blurSize:Number = getBlurSize(rAirBrushSize2,1.0);
                    rCanvasDrawShape.filters = [new BlurFilter(blurSize,blurSize,3)];
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawShape.filters = [];
                }
                else
                {
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                }

                rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;

                updateRCanvasDrawLayerCliprect2();
                extandRCanvasDrawLayerCliprect2();

                if(subLayer)
                {
                    rCanvasLayer2BitmapData.draw(rCanvasDrawLayerBitmap,null,canvasAlpha,lineStyleData[1],rCanvasDrawLayerClipRect);
                    rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                }
                else
                {
                    rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap,null,canvasAlpha,lineStyleData[1],rCanvasDrawLayerClipRect);
                    rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                }

                rCanvasDrawLayerBitmapData.fillRect(rCanvasDrawLayerClipRect,0);
                rCanvasDrawShape.graphics.clear();
            }

            function drawDone4(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1,1,1,lineStyleData[0]);

                rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;

                updateRCanvasDrawLayerCliprect2();
                extandRCanvasDrawLayerCliprect2();

                if(rAirBrushSize2 > 0)
                {
                    const blurSize:Number = getBlurSize(rAirBrushSize2,1.0);
                    rCanvasDrawLayerBitmapData.applyFilter(rCanvasDrawLayerBitmapData,rCanvasDrawLayerClipRect,new Point(rCanvasDrawLayerClipRect.x,rCanvasDrawLayerClipRect.y),new BlurFilter(blurSize,blurSize,3));
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                }

                if(subLayer)
                {
                    rCanvasLayer2BitmapData.draw(rCanvasDrawLayerBitmap,null,canvasAlpha,lineStyleData[1],rCanvasDrawLayerClipRect);
                    rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                }
                else
                {
                    rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap,null,canvasAlpha,lineStyleData[1],rCanvasDrawLayerClipRect);
                    rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                }

                rCanvasDrawLayerBitmapData.fillRect(rCanvasDrawLayerClipRect,0);
                rCanvasDrawShape.graphics.clear();
            }

            function drawDone3(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1,1,1,lineStyleData[0]);

                if(rAirBrushSize > 0 && rCanvasZoomMultiplier !== 1.0)
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

                updateRCanvasDrawLayerCliprect();
                extandRCanvasDrawLayerCliprect();

                if(subLayer)
                {
                    rCanvasLayer2BitmapData.draw(rCanvasDrawLayerBitmap,null,canvasAlpha,lineStyleData[1],rCanvasDrawLayerClipRectLegacy);
                    rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                }
                else
                {
                    rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap,null,canvasAlpha,lineStyleData[1],rCanvasDrawLayerClipRectLegacy);
                    rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                }

                rCanvasDrawLayerBitmapData.fillRect(rCanvasDrawLayerClipRectLegacy,0);
                rCanvasDrawShape.graphics.clear();

                if(rAirBrushSize > 0)
                {
                    resetBlurReplayCanvas();
                }
            }

            function drawDone2(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1,1,1,lineStyleData[0]);

                if(rAirBrushSize > 0 && rCanvasZoomMultiplier !== 1.0)
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

                if(subLayer)
                {
                    rCanvasLayer2BitmapData.draw(rCanvasDrawLayerBitmap,null,canvasAlpha,lineStyleData[1]);
                    rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                }
                else
                {
                    rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap,null,canvasAlpha,lineStyleData[1]);
                    rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                }

                rCanvasDrawLayerBitmapData.fillRect(new Rectangle(0,0,rCanvasLayer1BitmapData.width,rCanvasLayer1BitmapData.height),0);
                rCanvasDrawShape.graphics.clear();

                if(rAirBrushSize > 0)
                {
                    resetBlurReplayCanvas();
                }
            }

            function drawDone(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                // if(!lineStyleData) return;
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1,1,1,lineStyleData[0]);

                if(rAirBrushSize > 0 && rCanvasZoomMultiplier !== 1.0)
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

                if(subLayer)
                {
                    var tmpbmpd:BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
                    tmpbmpd.draw(rCanvasDrawLayerBitmap,null,canvasAlpha);
                    tmpbmpd.draw(rCanvasLayer1Bitmap);

                    rCanvasLayer1BitmapData = updateBitmapData(rCanvasLayer1BitmapData,tmpbmpd,rCanvasLayer1Bitmap);

                    tmpbmpd.dispose();
                    tmpbmpd = null;
                }
                else
                {
                    rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap,null,canvasAlpha,lineStyleData[1]);
                    rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                }

                rCanvasDrawLayerBitmap.bitmapData = null;
                rCanvasDrawLayerBitmapData.fillRect(new Rectangle(0,0,rCanvasDrawLayerBitmapData.width,rCanvasDrawLayerBitmapData.height),0);

                rCanvasDrawShape.graphics.clear();

                if(rAirBrushSize > 0)
                {
                    resetBlurReplayCanvas();
                }
            }

            function clear(layer1:Boolean,layer2:Boolean):void
            {
                if(!layer1 && !layer2)
                {
                    layer1 = true;
                    layer2 = true;
                }
                const rect:Rectangle = new Rectangle(0,0,rCanvasLayer1BitmapData.width,rCanvasLayer1BitmapData.height);

                if(layer1) rCanvasLayer1BitmapData.fillRect(rect,0);
                if(layer2) rCanvasLayer2BitmapData.fillRect(rect,0);
                setRCursorPosToCenter();
            }

            function swapLayer():void
            {
                var tempbmpd1:BitmapData = rCanvasLayer1BitmapData.clone();
                var tempbmpd11:BitmapData = rCanvasLayer2BitmapData.clone();
                const rect:Rectangle = new Rectangle(0,0,rCanvasLayer1BitmapData.width,rCanvasLayer1BitmapData.height);

                rCanvasLayer1BitmapData.fillRect(rect,0);
                rCanvasLayer2BitmapData.fillRect(rect,0);

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
                rCanvasLayer1BitmapData.fillRect(new Rectangle(0,0,rCanvasLayer1BitmapData.width,rCanvasLayer1BitmapData.height),0);
                setRCursorPosToCenter();
            }

            function drawNext():void
            {
                if(!data || data.length === 0)
                {
                    return;
                }
                const d:Array = data[index];
                switch(d[0])
                {
                    case "lineStyle": lineStyle(d); break;
                    case "lineStyle2": lineStyle2(d); break;
                    case "lineStyle3": lineStyle3(d); break;
                    case "lineStyle4": lineStyle4(d); break;
                    case "lineStyle5": lineStyle5(d); break;
                    case "lineTo": lineTo(d); break;
                    case "sqline": sqline(d); break;
                    case "fill": fill(d); break;
                    case "fill2": fill2(d); break;
                    case "fill3": fill3(d); break;
                    case "fill4": fill4(d); break;
                    case "fill5": fill5(d); break;
                    case "dot": dot(d); break;
                    case "dot2": dot2(d); break;
                    case "dot3": dot3(d); break;
                    case "dot4": dot4(d); break;
                    case "line": line(d); break;
                    case "line1": line1(d); break;
                    case "line2": line2(d); break;
                    case "line3": line3(d); break;
                    case "move": move(d); break;
                    case "move1": move1(d); break;
                    case "move2": move2(d); break;
                    case "lasso": lasso(d,false); break;
                    case "lasso2": lasso2(d,false); break;
                    case "lassodel": lasso(d,true); break;
                    case "lassodel2": lasso2(d,true); break;
                    case "mirror": mirror(); break;
                    case "bgColor": bgColor(d); break;
                    case "canvasSize": canvasSize(d); break;
                    case "tempDone": tempDone(d); break;
                    case "tempDone2": tempDone2(d); break;
                    case "tempDone3": tempDone3(d); break;
                    case "tempDone4": tempDone4(d); break;
                    case "drawDone": drawDone(d); break;
                    case "drawDone2": drawDone2(d); break;
                    case "drawDone3": drawDone3(d); break;
                    case "drawDone4": drawDone4(d); break;
                    case "drawDone5": drawDone5(d); break;
                    case "clear": clear(true,true); break;
                    case "clear1": clear(true,false); break;
                    case "clear2": clear(false,true); break;
                    case "swap": swapLayer(); break;
                    case "merge": mergeLayer(); break;
                    default: break;
                }

                index++;
            }

            return {
                drawNext:drawNext,
                drawAll:drawAll,
                setData:setData,
                clearData:clearData,
                setIndex:setIndex,
                getCurrentPosition:getCurrentPosition,
                isReadFinished:isReadFinished,
                getDataLength:getDataLength,
                getRemainingData:getRemainingData,
                getrLineStyleSave:getrLineStyleSave,
                getLineStyleAlpha:getLineStyleAlpha,
                getRCursorPos:getRCursorPos,
                setRCursorPos:setRCursorPos,
                updateRCursorPos:updateRCursorPos,
                updateRCursorPosToFirst:updateRCursorPosToFirst,
                hasRCursorFirstPos:hasRCursorFirstPos,
                getFirstRCursorPos:getFirstRCursorPos,
                setFirstRCursorPos:setFirstRCursorPos,
                resetFirstRCursorPos:resetFirstRCursorPos,
                setFirstRCursorPosCurrent:setFirstRCursorPosCurrent,
                updateLineStyleBackup:updateLineStyleBackup
            }
        }

        public function updateTotalFrameAndReplayMaxSpeedFor10Sec(totalframe:Number):void
        {
            TOTAL_FRAME = totalframe;
            var maxSpeed:Number = Math.floor(totalframe/10/stage.frameRate);
            if(maxSpeed < 1.0)
            {
                maxSpeed = 1.0;
            }
            REPLAY_MAX_SPEED =  maxSpeed;
        }

        public function updateReplayPrograssBarWidthByNowFame():void
        {
            setReplayPrograssBarWidth(replayTimelineBox.trackBar.width*rNowFrame/TOTAL_FRAME);
        }

        public function increaseReplayPrograssBarWidth(inc:Number):void
        {
            setReplayPrograssBarWidth(replayTimelineBox.prograssBar.width+inc);
        }

        public function setReplayPrograssBarMaxWidth():void
        {
            setReplayPrograssBarWidth(replayTimelineBox.trackBar.width);
        }

        public function resetReplayPrograssBarWidth():void
        {
            setReplayPrograssBarWidth(0);
        }

        public function setReplayPrograssBarWidth(newWidth:Number):void
        {
            replayTimelineBox.prograssBar.width = newWidth;
        
            if(newWidth >= replayTimelineBox.trackBar.width)
            {
                if(!replayTimelineBox.isPrograssBarMaxWidthReached())
                {
                    replayTimelineBox.setPrograssBarMaxWidthFlag(true);
                }
            }
            else if(replayTimelineBox.isPrograssBarMaxWidthReached() || newWidth === 0)
            {
                replayTimelineBox.setPrograssBarMaxWidthFlag(false);
                Global.applyToolBoxButtonOverBGColor(replayTimelineBox.prograssBar);
            }
        }

        public function updateReplayPrograssText(finishFlag:Boolean=false,customFrame:Number=NaN):void
        {
            const remainingTime:String = (isDeepUndoEnabled || finishFlag) ? "" : getReplayRemainingTimeString(rReplaySpeedMultipler,TOTAL_FRAME-rNowFrame);

            if(isNaN(customFrame))
            {
                customFrame = rNowFrame;
            }
            
            replayTimelineBox.prograssInfo.text = customFrame+" / "+TOTAL_FRAME+remainingTime;
        }

        public function startUpdatePrograssBar():void
        {
            var lastCursorUpdateTime:int = getTimer();
            var lastTextUpdateTime:int = getTimer();
            const cursorUpdateTime:int = stage.frameRate*2.5;
            const textUpdateTime:int = 1000;
            const frameTime:Number = 1000 / stage.frameRate;
            var accWidth:Number = 0.0;

            function onEnterFrame(e:Event):void
            {   
                const nowTime:int = getTimer();
                const trackBarWidth:Number = replayTimelineBox.trackBar.width;

                if(isReplayFinished)
                {
                    stage.removeEventListener(Event.ENTER_FRAME,onEnterFrame);
                    return;
                }

                if(!isReplayStarted)
                {
                    updateReplayPrograssText();
                    stage.removeEventListener(Event.ENTER_FRAME,onEnterFrame);
                    return;
                }

                const stepWidth:Number = (trackBarWidth*rReplaySpeedMultipler) / TOTAL_FRAME;

                if(replayTimelineBox.prograssBar.width + stepWidth >= trackBarWidth)
                {
                }
                else
                {
                    const accWidthInt:int = int(accWidth);

                    accWidth += stepWidth;

                    if(accWidthInt >= 1)
                    {   
                        increaseReplayPrograssBarWidth(accWidthInt);
                        accWidth -= accWidthInt;
                    }
                }

                if(nowTime - lastCursorUpdateTime >= cursorUpdateTime)
                {
                    lastCursorUpdateTime = nowTime;
                    drawReplayByCommand.updateRCursorPos();

                    if(!isReplayCanvasFitToWindow && !isMouseClicked && !isDeepUndoEnabled)
                    {
                        rFollowMouse.check(isReplaySlideShowMode);
                    }
                }

                if(nowTime - lastTextUpdateTime >= textUpdateTime)
                {
                    lastTextUpdateTime = nowTime;
                    updateReplayPrograssText();
                }
                updatePrograssBarStartTime = getTimer();
            }
            stage.addEventListener(Event.ENTER_FRAME,onEnterFrame);
        }

        public function switchToReplaySlideShowMode():void
        {
            isReplayStarted = true;
            isReplaySlideShowMode = true;
            stage.removeEventListener(Event.ENTER_FRAME,onEnterFrameStartReplay);
            rFileStream.close();
            stage.addEventListener(Event.ENTER_FRAME,onEnterFrameStartReplaySlideShowMode);
        }

        public function onEnterFrameStartReplaySlideShowMode(e:Event):void
        {
            if(rReplaySpeedMultipler <= REPLAY_SLIDESHOW_ACTIVE_SPEED)
            {
                isReplaySlideShowMode = false;
                stage.removeEventListener(Event.ENTER_FRAME,onEnterFrameStartReplaySlideShowMode);
                rFileStream.close();

                if(!rDataReadFlag)
                {
                    rFileStream.open(replayDataFilePath,FileMode.READ);
                    rFileStream.position = rFileLastBytePosition;
                }
                stage.addEventListener(Event.ENTER_FRAME,onEnterFrameStartReplay);
            }
            else
            {
                const nowTime:int = getTimer();
                if(nowTime - rTimeLIneTextUpdateTime >= REPLAY_SLIDESHOW_UPDATE_TIME)
                {
                    rTimeLIneTextUpdateTime = nowTime;

                    const nextFrame:Number = rReplaySpeedMultipler*stage.frameRate;
                    renderReplayFrame(rNowFrame+Math.floor(nextFrame/REPLAY_SLIDESHOW_FRAME_RATE),JUMP_FRAME_MANUAL);

                    if(rNowFrame >= TOTAL_FRAME)
                    {
                        isReplayFinished = true;
                        setReplayPrograssBarMaxWidth();
                        updateReplayPrograssText(true,TOTAL_FRAME);
                        stopReplay();
                        replayCompleteEffect();
                        startReplayRestartTimer();
                    }
                }

                replayHideCursor.check();
            }
        }

        public function onEnterFrameStartReplay(e:Event):void
        {
            if(shouldUseReplaySlideShowMode(rReplaySpeedMultipler))
            {
                switchToReplaySlideShowMode();
            }
            else
            {
                drawCanvasFromReplayData(rReplaySpeedMultipler,JUMP_FRAME_PLAY);
            }

            replayHideCursor.check();
        }

        public function clearRFrameTempCache():void
        {
            if(rFrameTempCachedImages.length > 0)
            {
                for(var i:int = 0;i<rFrameTempCachedImages.length;i++)
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
            return rFrameTempCachedImages[rFrameTempCachedImages.length-1][6];
        }

        public function createRFrameTempCache(index:uint,lastReadBytes:Number):void
        {
            rFrameTempCachedImages[index] = [rCanvasLayer1BitmapData.clone()
                                        ,rCanvasLayer2BitmapData.clone()
                                        ,rCanvasLayer1BitmapData.width
                                        ,rCanvasLayer1BitmapData.height
                                        ,RCANVAS_BG_COLOR
                                        ,lastReadBytes
                                        ,rNowFrame
                                        ,rMirrorON];
        }

        //jumpFlag  0: 기본 재생 1:탐색바를 마우스를 이용하여 스킵, 2:one frame 이전스트로크, 3:one frame 이후 스트로크
        public function cDrawReplayData():Function
        {
            //jumpFlag 1번은 마우스 커서로 이동, 2,3번은 스트로크 단위혹은 프레임 단위로 앞뒤로 탐색
            var rDataLen:uint;
            var savedTime:int;
            var rFrameCursorDelayTime:int = 0; //커서 딜레이
            var _rFrameTextDelayTime:int = 0; //프레임 바 딜레이
            var getTimeStr:String;
            var timeStr:String;
            var readCount:Number = 0;
            var jumpImageGroupIndex:int;
            var nowJumpFlag:Boolean;
            const cursorUpdateTime:int = stage.frameRate*2;

            function makeMemoryCacheImage():void
            {
                createRFrameTempCache(rFrameTempCachedImages.length,rFileCutBytePosition);
            }

            function readyToReadMemoryData(jumpFlag:int):void
            {
                rDataReadFlag = true;
                rDataIndex = rDataStartIndex;
                rDataStartIndex = 0;
                rDataLen = rData.length;

                if(jumpFlag === JUMP_FRAME_PLAY)
                {
                    rFileStream.close();
                    rFileLastBytePosition = 0;
                }

                if(rData.length > 0)
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
                if(rFileStream.bytesAvailable > 0)
                {
                    const obj:Array = rFileStream.readObject() as Array;
                    if(!obj) return true;

                    drawReplayByCommand.setData(obj);
                    rFileCutBytePosition = rFileLastBytePosition;
                    rFileLastBytePosition = rFileStream.position;
                    rPrevFrame = rNowFrame;
                    return true;
                }
                return false
            }

            function checkFinish(jumpFlag:int):Boolean
            {
                if(rDataIndex >= rDataLen || rDataLen === 0) //자연적 으로 끝났을때
                {
                    // syncMirrorReplayModeWithDrawMode();

                    rReplayFOFOCursor.visible = false;
                    isReplayFinished = true;

                    if(jumpFlag === JUMP_FRAME_PLAY || isReplaySlideShowMode === true)//1프레임 이상일때만 재시작 타이머 가동
                    {
                        //reset replay time해주지 말고 그냥 end플래그만 올려줌
                        //왜냐하면 리플레이 자연적으로 끝나고도 스킵프레임이나 oneframe jump을 해줄수가 있기 때문
                        setReplayPrograssBarMaxWidth();
                        updateReplayPrograssText(true,TOTAL_FRAME);
                        stopReplay();//플레이 아이콘 내주지 말기
                        replayCompleteEffect();
                        startReplayRestartTimer();
                        return true;
                    }
                }
                return false;
            }

            function drawFromMemoryData(len:Number,jumpFlag:int):void
            {
                for(var i:Number=0;i<len;i++)
                {
                    if(drawReplayByCommand.isReadFinished())
                    {
                        rDataIndex++;
                        if(checkFinish(jumpFlag))
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

            function drawFromFileData(len:Number,jumpFlag:int):void
            {
                for(var i:Number=0;i<len;i++)
                {
                    if(drawReplayByCommand.isReadFinished())
                    {
                        // if(checkFinishDeepUndoLimit(jumpFlag)) return;
                        if(readNextFileData() === false)
                        {
                            //더이상 읽을 데이터가 없을때 메모리읽기로 넘겨줌
                            readyToReadMemoryData(jumpFlag);
                            return;
                        }

                        if(isReplayStarted === false && (jumpFlag === JUMP_FRAME_MANUAL || jumpFlag === JUMP_FRAME_PREV))
                        {
                            if(rNowFrame > getRFrameTempCacheLastFrame() + REPLAY_MEMORY_CACHE_FRAME_INTERVAL)
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

            return function(jumpCount:Number,jumpFlag:int):void
            {
                if(jumpCount > 0)
                {
                    readCount = jumpCount;
                    if(!rDataReadFlag)
                    {
                        //readcount 감소
                        drawFromFileData(jumpCount,jumpFlag);
                    }

                    if(readCount > 0)
                    {
                        //readcount를 읽어줌
                        drawFromMemoryData(readCount,jumpFlag);
                    }
                }
            }
        }

        public function getReplayRemainingTimeString(speed:Number,totalFrame:Number,isSlideShowMode:Boolean=false):String
        {
            const fps:Number = (isSlideShowMode === true) ? 1.0:stage.frameRate;
            const totalSec:Number = totalFrame/(fps*speed);
            if(totalSec === 0) return "";

            const hour:int = totalSec/3600;
            const min:int = totalSec%3600/60;
            const sec:int = totalSec%60;
            var timeStr:String = "";

            if(hour > 0)    
            {
                timeStr += hour +":";
            }

            if(min > 0) 
            {
                timeStr += (min >= 10) ? min+":" : "0"+min+":";
            }
            else 
            {
                timeStr = "00:";
            }

            if(sec > 0)
            {
                timeStr += (sec >= 10) ? sec : "0"+sec;
            }
            else
            {
                timeStr += "00";
            }

            if(hour === 0 && min === 0 && sec === 0)
            {
                const milisec:Number = totalSec-Math.floor(totalSec);
                const milisecStr:String = milisec.toFixed(1);

                return " ("+milisecStr+")";
            }

            return " ("+timeStr+")";
        }

        public function cReplayFollowMouse():Object
        {
            const padding:Number = 20;
            const cursorPos:Point = new Point(0,0);
            const windowCenterPos:Point = new Point(0,0); //캔버스 중점위치, 창 중점위치 사이 거리

            var stw:Number;
            var sth:Number; //프레임 탐색막대 길이 빼줌]
            var bounds:Object; //바운드 저장하는 객체
            var left:Number; //바운드 상하좌우
            var right:Number;
            var top:Number;
            var bottom:Number;
            var globalChecked:Boolean;
            var cp:Point; //커서 좌표
            var gp:Point; //캔버스 글로벌 좌표
            var rg:Point; //캔버스 회전된 글로벌 좌표
            var zoom:Number;
            var scale:Number;

            //rcanvas1 글로벌 좌표에 회전된 캔버스에서 커서 위치를 더해줌. 즉 윈도우 기준에서 커서 커서 위치를 구하는거임
            var isCanvasWidthSmallerStage:Boolean; //캔버스 가로 새로 길이가 스테이지 길이보다 클때 체크
            var isCanvasHeightSmallerStage:Boolean;
            var isNotCenterX:Boolean; //캔버스 중점위치, 창 중점위치 사이 거리
            var isNotCenterY:Boolean;

            const leftLimit:Number = padding;
            const topLimit:Number = padding+topBar.BARSIZE+replayTimelineBox.BARSIZE;
            var rightLimit:Number;
            var bottomLimit:Number;

            function updateScale(newScale:Number):void
            {
                scale = newScale;
            }

            function updateBounds():void
            {
                bounds = getBoundRect(rCanvasLayer1Bitmap);
                left = bounds.left;
                right = bounds.right;
                top = bounds.top;
                bottom = bounds.bottom;
                stw = stage.stageWidth;
                sth = stage.stageHeight-(topBar.BARSIZE+replayTimelineBox.BARSIZE)*scale;
                zoom = rCanvasZoomMultiplier;

                isCanvasWidthSmallerStage = right-left < stw;
                isCanvasHeightSmallerStage = bottom-top < sth;
                //캔버스 중점위치, 창 중점위치 사이 거리
                windowCenterPos.setTo(Math.floor(stw/2-(right+left)/2),Math.floor((topBar.BARSIZE+replayTimelineBox.BARSIZE)*scale+sth/2-(bottom+top)/2));
                isNotCenterX = Math.abs(windowCenterPos.x) > 0; //캔버스 중점위치, 창 중점위치 사이 거리
                isNotCenterY = Math.abs(windowCenterPos.y) > 0;

                rightLimit = stw-padding;
                bottomLimit = sth+topBar.BARSIZE+replayTimelineBox.BARSIZE-padding;
            }

            function check(viewCenterFlag:Boolean):void
            {
                cp = drawReplayByCommand.getRCursorPos();

                globalChecked = false;
                const div:Number = (viewCenterFlag) ? 1:3;

                if(isCanvasWidthSmallerStage)
                {
                    if(isNotCenterX)
                    {
                        rCanvasAnchorPoint.x += windowCenterPos.x;
                        updateBounds();
                    }
                }
                else
                {
                    globalChecked = true;
                    gp = rCanvasLayer1Bitmap.localToGlobal(new Point(0,0));
                    rg = rotatePoint(cp.x,cp.y,-rCanvasAnchorPoint.rotation);
                    cursorPos.x = gp.x+(rg.x*zoom);

                    if(cursorPos.x < leftLimit)
                    {
                        rCanvasAnchorPoint.x += Math.floor(Math.abs((cursorPos.x-stw/2)/div));
                        updateBounds();
                    }
                    else if(cursorPos.x > rightLimit)
                    {
                        rCanvasAnchorPoint.x -= Math.floor(Math.abs((cursorPos.x-stw/2)/div));
                        updateBounds();
                    }
                }

                if(isCanvasHeightSmallerStage)
                {
                    if(isNotCenterY)
                    {
                        rCanvasAnchorPoint.y += windowCenterPos.y;
                        updateBounds();
                    }
                }
                else
                {
                    if(globalChecked === false)
                    {
                        globalChecked = true;
                        gp = rCanvasLayer1Bitmap.localToGlobal(new Point(0,0));
                        rg = rotatePoint(cp.x,cp.y,-rCanvasAnchorPoint.rotation);
                    }
                    cursorPos.y = gp.y+(rg.y*zoom);

                    if(cursorPos.y < topLimit)
                    {
                        rCanvasAnchorPoint.y += Math.floor(Math.abs((cursorPos.y-sth/2)/div));
                        updateBounds();
                    }
                    else if(cursorPos.y > bottomLimit)
                    {
                        rCanvasAnchorPoint.y -= Math.floor(Math.abs((cursorPos.y-sth/2)/div));
                        updateBounds();
                    }
                }
            }

            return {
                check:check,
                updateBounds:updateBounds,
                updateScale:updateScale
            };
        }

        public function shouldUseReplaySlideShowMode(speed:Number):Boolean
        {
            return speed > REPLAY_SLIDESHOW_ACTIVE_SPEED;
        }

        public function toggleFitToCanvasReplayMode():void
        {
            if(isReplayCanvasFitToWindow)
            {
                resetZoomReplayMode();
                topBar.replayFitToWindowButton.alpha = Global.OFFALPHA;
            }
            else
            {
                setFitReplayCanvasToWindowON();
                topBar.replayFitToWindowButton.alpha = 1.0;
            }
        }

        public function toggleReplayRepeat():void
        {
            isReplayRepeatON = !isReplayRepeatON;

            if(isReplayRepeatON)
            {
                topBar.replayRepeatButton.alpha = 1.0;
            }
            else
            {
                topBar.replayRepeatButton.alpha = Global.OFFALPHA;
            }
        }

        public function getNowFrameUntilUndoIndex(index:int):Number
        {
            return undoManager.getRFileTotalFrame()+undoManager.getRDataTotalFrame(index);
        }

        public function getTotalFrame():Number
        {
            return getNowFrameUntilUndoIndex(rDataFrame.length-1);
        }

        public function binarySearchIndex(list:Array,target:Number,valueExtractor:Function):int
        {
            var low:int = 0;
            var high:int = list.length - 1;
            if (high <= 0)
            {
                return high;
            }

            var index:int = Math.floor((low + high) / 2);

            while (low <= high)
            {
                var value:Number = valueExtractor(list[index]);

                if (value === target)
                {
                    break;
                }
                else if (value > target) 
                {
                    high = index - 1;
                }
                else 
                {
                    low = index + 1;
                }

                index = Math.floor((low + high) / 2);
            }

            return index;
        }

        public function getNearZoomIndex(nowZoom:Number):int
        {
            var index:int = binarySearchIndex(canvasZoomMultiplerList, nowZoom, function(item:*):Number {
                return item;
            });

            if (index <= 0) return 0;
            else if (index >= canvasZoomMultiplerList.length - 1) return canvasZoomMultiplerList.length - 1;
            else if (canvasZoomMultiplerList[index + 1] - nowZoom < nowZoom - canvasZoomMultiplerList[index - 1]) {
                return index + 1;
            }
            return index;
        }

        //targetFrame이 rFrameCacheImages데이터에 몆 번 인덱스에 있나 구해줌
        public function getCacheImageIndex(targetFrame:Number):int
        {
            return binarySearchIndex(rFrameTempCachedImages, targetFrame, function(item:*):Number {
                return item[6];
            });
        }

        //targetFrame이 rJumpImageFrameData데이터에 몆 번 인덱스에 있나 구해줌
        public function getCachedFrameImageIndex(targetFrame:Number):int
        {
            return binarySearchIndex(rJumpImageFrameData, targetFrame, function(item:*):Number {
                return Number(item);
            });
        }

        public function updateDeleteReplayDataButtonsState():void
        {
            if(rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_PROCESSING || isSaveInProgress || isReplayStarted)
            {
                topBar.superUndoButton.alpha = Global.OFFALPHA;
                topBar.cutPrevDataButton.alpha = Global.OFFALPHA;
                topBar.repNewFileButton.alpha = Global.OFFALPHA;
            }
            else
            {
                topBar.repNewFileButton.alpha = 1.0;

                if(rNowFrame > 0 && rNowFrame < TOTAL_FRAME)
                {
                    topBar.superUndoButton.alpha = 1.0;
                    topBar.cutPrevDataButton.alpha = 1.0;
                }
                else
                {
                    topBar.superUndoButton.alpha = Global.OFFALPHA;
                    topBar.cutPrevDataButton.alpha = Global.OFFALPHA;
                }
            }
        }

        public function addKeyRepeatEvents():void
        {
            stage.nativeWindow.addEventListener(Event.DEACTIVATE,removeKeyRepeatEvents);
            stage.addEventListener(MouseEvent.MOUSE_DOWN,removeKeyRepeatEvents);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,removeKeyRepeatEvents);
            stage.addEventListener(MouseEvent.MOUSE_UP,removeKeyRepeatEvents);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,removeKeyRepeatEvents);
            stage.addEventListener(KeyboardEvent.KEY_UP,removeKeyRepeatEvents);
        }

        public function removeKeyRepeatEvents(e:Object):void
        {
            removeTimer("keyHoldWaitTimer");
            removeTimer("keyHoldRepeatTimer");
            stage.nativeWindow.removeEventListener(Event.DEACTIVATE,removeKeyRepeatEvents);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,removeKeyRepeatEvents);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,removeKeyRepeatEvents);
            stage.removeEventListener(MouseEvent.MOUSE_UP,removeKeyRepeatEvents);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,removeKeyRepeatEvents);
            stage.removeEventListener(KeyboardEvent.KEY_UP,removeKeyRepeatEvents);
        }

        public function readyForFrameJump():void
        {
            isReplayFinished = false;
            if(isReplayStarted)
            {
                stopReplay();
            }
        }

        public function moveToPreviousStep():void
        {
            readyForFrameJump();
            if(rNowFrame > 0)
            {
                renderReplayFrame(rPrevFrame,JUMP_FRAME_PREV);
                updateDeleteReplayDataButtonsState();
                updateReplayPrograssBarWidthByNowFame();
                updateReplayPrograssText();
            }
        }

        public function moveToNextStep():void
        {
            readyForFrameJump();
            if(rNowFrame <= TOTAL_FRAME)
            {
                if(drawReplayByCommand.getRemainingData() === 0)
                {
                    //+1해줘서 다음 데이터 갱신해주고 나머지 끝까지 그려줌
                    renderReplayFrame(rNowFrame+1,JUMP_FRAME_NEXT);
                    renderReplayFrame(rNowFrame+drawReplayByCommand.getRemainingData(),JUMP_FRAME_NEXT);
                    //jumpframe함수 이후에 실행

                }
                else
                {
                    renderReplayFrame(rNowFrame+drawReplayByCommand.getRemainingData(),JUMP_FRAME_NEXT);
                }
                updateDeleteReplayDataButtonsState();
                updateReplayPrograssBarWidthByNowFame();
                updateReplayPrograssText();
            }
        }

        public function moveToPreviousFrame():void
        {
            readyForFrameJump();
            if(rNowFrame > 0)
            {
                renderReplayFrame(rNowFrame-1,JUMP_FRAME_MANUAL);
                updateDeleteReplayDataButtonsState();
                updateReplayPrograssBarWidthByNowFame();
                updateReplayPrograssText();
            }
        }

        public function moveToNextFrame():void
        {
            readyForFrameJump();
            if(rNowFrame < TOTAL_FRAME)
            {
                renderReplayFrame(rNowFrame+1,JUMP_FRAME_MANUAL);
                updateDeleteReplayDataButtonsState();
                updateReplayPrograssBarWidthByNowFame();
                updateReplayPrograssText();
            }
        }

        public function drawCacheImageFirst(tragetFrame:Number):Number
        {
            const index:Number = getCachedFrameImageIndex(tragetFrame);
            var cachedImageIndex:Number = -1; //자잘 썸네일 인덱스를 넣어줌
            var loadCacheFlag:int = 0;
            var remainingFrameCount:Number = 0.0;
            
            //isReplayStarted 붙여주는 이유는
            //slide show모드로 재생하게 되면 클리어 케시를 계속 호출해주고
            //재생 완료시 rJumpImageIndexLast가 갱신되어있을때 다시 해주면 메모리 캐시가 없는데 캐시를 불러주는 버그가 생겨서
            //아무생각없이 넣어본건데 버그 안나서 그대로 두려고함
            if(index !== rJumpImageIndexLast && isReplayStarted === false)
            {
                clearRFrameTempCache();
                loadCacheFlag = 1;
            }
            else if(rFrameTempCachedImages.length > 0)
            {
                if(tragetFrame >= rFrameTempCachedImages[0][6])
                {
                    cachedImageIndex = getCacheImageIndex(tragetFrame);
                    if(rCachedImageLastIndex !== cachedImageIndex || tragetFrame < rNowFrame)
                    {
                        loadCacheFlag = 2;
                    }
                }
            }

            if(loadCacheFlag > 0 || tragetFrame < rNowFrame)
            {
                var cachedImageData:Array;
                var layer1bmpd:BitmapData;
                var layer2bmpd:BitmapData;
                var newrect:Rectangle;

                if(loadCacheFlag === 2)
                {
                    cachedImageData = rFrameTempCachedImages[cachedImageIndex];
                    layer1bmpd = cachedImageData[0];
                    layer2bmpd = cachedImageData[1];
                    rCachedImageLastIndex = cachedImageIndex;
                }
                else
                {
                    const file:File = replayCacheImageFolderPath.resolvePath(String(index));
                    const fs:FileStream = new FileStream();

                    fs.open(file,FileMode.READ);
                    cachedImageData = fs.readObject() as Array;
                    fs.close();
                    cachedImageData[0].uncompress();
                    cachedImageData[1].uncompress();

                    newrect = new Rectangle(0,0,cachedImageData[2],cachedImageData[3]);
                    layer1bmpd = new BitmapData(cachedImageData[2],cachedImageData[3],true,0);
                    layer1bmpd.lock();
                    layer1bmpd.setPixels(newrect,cachedImageData[0]);
                    layer1bmpd.unlock();

                    layer2bmpd = new BitmapData(cachedImageData[2],cachedImageData[3],true,0);
                    layer2bmpd.lock();
                    layer2bmpd.setPixels(newrect,cachedImageData[1]);
                    layer2bmpd.unlock();

                    cachedImageData[0].clear();
                    cachedImageData[0] = null;
                    cachedImageData[1].clear();
                    cachedImageData[1] = null;
                    rJumpImageNowFrameLast = cachedImageData[6];
                }

                rJumpImageIndexLast = index;
                rFileLastBytePosition = cachedImageData[5]; //마지막 바이트
                rFileStream.position = cachedImageData[5];
                rNowFrame = cachedImageData[6]; //썸네일 이미지를 저장한 프레임

                //원하는 프레임에서 썸네일 이미지 프레임을 빼줌 나머지 프레임만 그려주면 되니깐
                remainingFrameCount = tragetFrame-cachedImageData[6];
                rDataIndex = 0; //이거 먼저 초기화 시켜주어야함
                drawReplayByCommand.clearData();
                clearCanvasReplayMode();
                rMirrorON = cachedImageData[7];

                rCanvasLayer1BitmapData = updateBitmapData(rCanvasLayer1BitmapData,layer1bmpd,rCanvasLayer1Bitmap);
                rCanvasLayer2BitmapData = updateBitmapData(rCanvasLayer2BitmapData,layer2bmpd,rCanvasLayer2Bitmap);

                updateCanvasSizeReplayMode(rCanvasLayer1Bitmap.width,rCanvasLayer1Bitmap.height);
                updateCanvasBGColorReplayMode(cachedImageData[4]);

                if(loadCacheFlag === 1 && isReplayStarted === false)
                {
                    createRFrameTempCache(0,rFileLastBytePosition);
                }

                cachedImageData = null;
                rDataReadFlag = false;
                rDataStartIndex = 0;
                if(loadCacheFlag !== 2)
                {
                    layer1bmpd.dispose();
                    layer2bmpd.dispose();
                    layer1bmpd = null;
                    layer2bmpd = null;
                }
            }
            else
            {
                if(!rDataReadFlag)
                {
                    rFileStream.position = rFileLastBytePosition;
                }
                remainingFrameCount = tragetFrame - rNowFrame;
            }
      
            if(remainingFrameCount === 0.0)
            {
                rPrevFrame = tragetFrame-1;
            }

            return remainingFrameCount;
        }

        public function renderReplayFrame(frame:Number,jumpflag:int):void //jumpp
        {
        //TODO now prograss bar 는여기서 갱신조건 스탭으로만 하고
        //플레이중에는 따로 시간계산해서 매끄럽게 진행하는것으로 바꿈 마우스 조작 매끄럽게하는느낌으로 가려고함
            if(frame < 0) 
            {
                frame = 0;
            }
            else if(frame > TOTAL_FRAME) 
            {
                frame = TOTAL_FRAME;
            }

            if(isReplayModeON)
            {
                if(frame >= TOTAL_FRAME && isReplayFinished)
                {
                    return;
                }
            }

            rFileStream.open(replayDataFilePath,FileMode.READ);
            const remainingFrameCount:Number = drawCacheImageFirst(frame);
            drawCanvasFromReplayData(remainingFrameCount,jumpflag);
            rFileStream.close();

            //dodraw밑이기 때문에 rFrameSum이 갱신되서 위에 nowFrame은 쓸수가 없음
            if(rNowFrame >= TOTAL_FRAME)
            {
                if(isReplayModeON) //deepundo도 있어서
                {
                    if(!isReplayFinished)
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

            if(!isReplaySlideShowMode && !isReplayCanvasFitToWindow && !isDeepUndoEnabled)
            {
                rFollowMouse.check(true);
            }
        }

        //데이터를 읽다 말았으면 끝까지 한세트 끝나게 프레임 이동시킴
        public function finalizeRemainingReplayData():void
        {
            renderReplayFrame(rNowFrame+drawReplayByCommand.getRemainingData(),JUMP_FRAME_MANUAL);
        }

        public function onTimelineClick():void
        {
            if(TOTAL_FRAME === 0 || rReplayImageCacheState > REPLAY_IMAGE_CAHCHE_COMPLETE)
            {
                return;
            }

            //리플레이 플레이 중인지 아닌지 플래그 미리 저장해둠
            var wasReplayRunning:Boolean = false;
            var clickX:Number = replayTimelineBox.trackBar.mouseX*replayTimelineBox.trackBar.scaleX;
            var finalFrame:Number = Math.floor(TOTAL_FRAME*clickX/replayTimelineBox.trackBar.width);

            function clampFrame():void
            {
                var mx:Number = replayTimelineBox.trackBar.mouseX*replayTimelineBox.trackBar.scaleX;

                if(mx < 0)
                {
                    mx = 0;
                    resetReplayPrograssBarWidth();
                }
                else if(mx > replayTimelineBox.trackBar.width)
                {
                    mx = replayTimelineBox.trackBar.width;
                    setReplayPrograssBarMaxWidth();
                }
                else
                {
                    setReplayPrograssBarWidth(mx);
                }

                finalFrame = Math.floor(TOTAL_FRAME*mx/replayTimelineBox.trackBar.width);

                updateReplayPrograssText(false,finalFrame);
            }

            function onDragStart():void
            {
                if(isReplayStarted)
                {
                    wasReplayRunning = true;
                    isReplayStarted = false;
                    stage.removeEventListener(Event.ENTER_FRAME,onEnterFrameStartReplay);
                    stage.removeEventListener(Event.ENTER_FRAME,onEnterFrameStartReplaySlideShowMode);
                    rFileStream.close();
                }

                setReplayPrograssBarWidth(clickX);
                clampFrame();
                isReplaySlideShowMode = false;
                isReplayFinished = false;
                replayTimelineBox.resetPrograssBarColor();
                replayHideCursor.check();
            }

            function onMouseMove():void
            {
                clampFrame();

                if(!hasTimer("jumpFrameUpdateTimer"))
                {
                    addTimerByName("jumpFrameUpdateTimer",0.25,false,function():void
                    {
                        renderReplayFrame(finalFrame,JUMP_FRAME_MANUAL);
                    });
                }
            }

            function onMouseUp():void
            {
                removeTimer("jumpFrameUpdateTimer");
                renderReplayFrame(finalFrame,JUMP_FRAME_MANUAL);
                clampFrame();

                //jumpframe함수 이후에 실행
                updateDeleteReplayDataButtonsState();

                //재생중에 스킵하고 있었으면 다시 시작
                if(wasReplayRunning && !isReplayFinished)
                {
                    startReplay();
                }
                else if(isReplayFinished)
                {
                    setReplayPrograssBarMaxWidth();
                    updateReplayPrograssText(true,TOTAL_FRAME);
                    stopReplay();
                }
            }
            startDragInteraction(onDragStart,onMouseMove,onMouseUp);
        }

        public function stopReplay():void
        {
            stage.removeEventListener(Event.ENTER_FRAME,onEnterFrameStartReplay);
            stage.removeEventListener(Event.ENTER_FRAME,onEnterFrameStartReplaySlideShowMode);

            replayTimelineBox.playButton.visible = true;
            replayTimelineBox.pauseButton.visible = false;

            rFileStream.close();

            isReplayStarted = false;
            isReplaySlideShowMode = false;
            updateDeleteReplayDataButtonsState();
            replayHideCursor.reset();
        }

        public function startReplay():void
        {
            if(isReplayStarted || TOTAL_FRAME === 0)
            {
                return;
            }

            isReplayStarted = true;
            replayTimelineBox.resetPrograssBarColor();
            replayTimelineBox.playButton.visible = false;
            replayTimelineBox.pauseButton.visible = true;
            updateDeleteReplayDataButtonsState();

            rReplayFOFOCursor.visible = true;

            if(isReplayFinished === true) //리플레이 시간 등등 초기화 시키고 시작
            {
                resetReplayPrograssBarWidth();
                rMirrorON = false;
                resetReplayTime();
                clearCanvasReplayMode();
                drawFirstJumpImage();
                rDataReadFlag = false;
                isReplayFinished = false;//resetReplayTime함수 에서 이걸 true로 해주기 때문에 아래쪽에서 변경
                resetRotationReplayMode();

                if(!isReplayCanvasFitToWindow)
                {
                    restoreZoomReplayMode();
                }

                rFollowMouse.updateBounds();
                selectReplaySubLayer(false);
            }

            if(isReplayFinishedWithFiwWindow === true)
            {
                isReplayFinishedWithFiwWindow = false;
                rCanvasZoomIndex = getNearZoomIndex(rCanvasZoomMultiplier);
                updateCanvasScale(rCanvasZoomMultiplier,true);
            }

            if(!rDataReadFlag)
            {
                rFileStream.open(replayDataFilePath,FileMode.READ);
                rFileStream.position = rFileLastBytePosition;
            }

            if(isReplayCanvasFitToWindow)
            {
                fitReplayCanvasToWindow();
            }

            clearRFrameTempCache();
            startUpdatePrograssBar();
            stage.addEventListener(Event.ENTER_FRAME,onEnterFrameStartReplay);
        }

        public function startBoxDrag(target:DisplayObject):void
        {
            const clickPos:Point = new Point(stage.mouseX,stage.mouseY);

            function onDragStart():void
            {
                setAsTopChild(target);
            }

            function onMouseMove():void
            {
                target.x = Math.floor(target.x+stage.mouseX-clickPos.x);
                target.y = Math.floor(target.y+stage.mouseY-clickPos.y);

                clickPos.x = stage.mouseX;
                clickPos.y = stage.mouseY;
            }

            function onMouseUp():void
            {
                keepBoxInsideViewPort(target);
            }

            startDragInteraction(onDragStart,onMouseMove,onMouseUp);
        }

        public function executeToolBoxClick(targetName:String):void
        {
            function onMouseUpToolBox(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUpToolBox);

                const upTargetName:String = e.target.name;

                if(upTargetName !== targetName) return;

                switch(upTargetName)
                {
                    case "toolPen":
                    {
                        if(!isSelectedTool(TOOL_PEN))
                        {
                            selectPenTool();
                            updatePenSizeCursor();
                        }
                    }
                    break;

                    case "toolFillPen":
                    {
                        if(!isSelectedTool(TOOL_FILL_PEN))
                        {
                            selectFillPenTool();
                            updatePenSizeCursor();
                        }
                    }
                    break;

                    case "toolErase":
                    {
                        if(!isSelectedTool(TOOL_ERASER))
                        {
                            selectEraseTool();
                            updatePenSizeCursor();
                        }
                    }
                    break;

                    case "toolLine":
                    {
                        if(!isSelectedTool(TOOL_LINE))
                        {
                            selectLineTool();
                            updatePenSizeCursor();
                        }
                    }
                    break;

                    case "toolLasso":
                    {
                        if(!isSelectedTool(TOOL_LASSO))
                        {
                            selectLassoTool();
                        }
                    }
                    break;

                    case "toolEyedropper":
                    {
                        if(isQuickSidebarActive)
                        {
                            resetOldTool();
                            toolBox.moveToolCursor("toolEyedropper");
                        }
                        else if(!isSelectedTool(TOOL_EYEDROPPER))
                        {
                            eyeDropperTool();
                        }
                    }
                    break;

                    case "toolUndo":
                    {
                        if(!hasTimer("keyHoldRepeatTimer"))
                        {
                            undo();
                        }
                    }
                    break;

                    case "toolRedo":
                    {
                        if(!hasTimer("keyHoldRepeatTimer"))
                        {
                            redo();
                        }
                    }
                    break;

                    case "toolMirror":
                    {
                        mirrorCanvas();
                    }
                    break;

                    case "toolMove":
                    {
                        selectMoveTool();
                    }
                    break;

                    case "toolZoomIn":
                    {
                        zoomInCanvas(true,false);
                    }
                    break;

                    case "toolZoomOut":
                    {
                        zoomInCanvas(false,false);
                    }
                    break;

                    case "toolRefLayer":
                    {
                        if(isQuickSidebarActive) deactivateQuickSidebar();

                        if(isRefLayerMenuON === false)
                        {
                            openRefLayerMenu();
                            refLayerMenuBox.y = mouseY-60;
                        }
                    }
                    break;
                }
            }
            //undo키 반복이 있어서 우선순위 1로 약간 높여줌
            stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpToolBox,false,1);
        }

        public function updateCanvasBGColor(xCanvas:Sprite,w:Number,h:Number,color:uint):void
        {
            xCanvas.graphics.clear();
            xCanvas.graphics.beginFill(color);
            xCanvas.graphics.drawRect(0,0,w,h);
            xCanvas.graphics.endFill();
        }

        public function updateCanvasBGColorReplayMode(color:uint):void
        {
            RCANVAS_BG_COLOR = color;
            updateCanvasBGColor(rCanvasPanel,RCANVAS_WIDTH,RCANVAS_HEIGHT,color);
        }

        public function updateCanvasBGColorDrawMode(color:uint):void
        {
            isFileAlreadySaved = false;
            CANVAS_BG_COLOR = color;
            canvasNavigatorBox.changeprevBitmapBGColor(color);
            updateCanvasBGColor(canvasPanel,CANVAS_WIDTH,CANVAS_HEIGHT,color);
            if( colorPickerBox.scratchPad)
            {
                colorPickerBox.scratchPad.updateBGColor(color);
            }
        }

        public function updateBottomBarLayoutAndColor():void
        {
            bottomBar.x = 0; 
            bottomBar.y = stage.stageHeight - BOTTOM_BAR_HEIGHT*Global.getUIScale();
            bottomBar.graphics.clear();
            // bottomBar.graphics.lineStyle(0,0xFF0000,0.0);
            bottomBar.graphics.beginFill(Global.getHintBGColor(),0.75);
            bottomBar.graphics.drawRect(-3,0,stage.stageWidth+6,BOTTOM_BAR_HEIGHT+3);
            bottomBar.graphics.endFill();
        }

        public function isHintUnavailableWithFillPen(target:DisplayObject):Boolean
        {
            const targetName:String = target.name;

            if(isFillPenStarted)
            {
                if(target.alpha > 0.5
                &&
                (  toolBox.contains(target)
                || canvasInfoBox.contains(target)
                || colorPickerBox.contains(target))
                || (targetName && targetName.indexOf("alphaButton") !== -1))
                {
                }
                else
                {
                    return true;
                }
            }
            else if(isSelectedTool(TOOL_FILL_PEN))
            {
                if((targetName && targetName.indexOf("nSizeButton") !== -1) || target.alpha < 0.5)
                {
                    return true;
                }
            }
            else if(isHintUnavailable())
            {
                return true;
            }

            return false;
        }

        public function isCanvasNaviatorChild(target:DisplayObject):Boolean
        {
            const targetName:String = target.name;
            return (targetName === "navStageBG"
                || targetName === "navBitmapBG"
                || targetName === "navLayer1Bitmap"
                || targetName === "navLayer2Bitmap"
                || targetName === "navCursor")
        }

        public function showBottomHintForTargetCaptureMode(target:DisplayObject):void
        {
            if (isHintUnavailable())
            {
                return;
            }

            const hint:String = HintStrings.getHintFromTargetNameCaptureMode(target.name);
            
            if (hint)
            {
                removeTimer("bottomHintOffDelay");

                const targetName:String = target.name;
                const xCanvasPanel:Sprite = (isReplayModeON)?  rCanvasPanel : canvasPanel;
                if (captureAreaManager.isFullImageCapture() && xCanvasPanel.hitTestPoint(stage.mouseX, stage.mouseY,true))
                {
                    showHintHighlightBox((isReplayModeON)? rCanvasLayer1Bitmap : canvasLayer1Bitmap);
                    showBottomHint(hint);
                }
                else if (!(targetName === "rCanvasPanel"
                        || targetName === "rCanvasDrawLayer"
                        || targetName === "canvasPanel"
                        || targetName === "canvasDrawLayer"))
                {
                    showHintHighlightBox(target);
                    showBottomHint(hint);
                }
            }
            else
            {
                if (!hasTimer("bottomHintOffDelay"))
                {
                    addTimerByName("bottomHintOffDelay", 0.3, false, hideBottomHint);
                }
            }
        }

        public function showBottomHintForTarget(target:DisplayObject):void
        {
            const hint:String = HintStrings.getHintFromTargetName(target.name);

            if(hint)
            {
                removeTimer("bottomHintOffDelay");
                if(isCanvasNaviatorChild(target))
                {
                    showHintHighlightBox(canvasNavigatorBox.navStageBG);
                }
                else
                {
                    showHintHighlightBox(target);
                }

                if(!isBottomBarVisible())
                {
                    addTimerByName("bottomHintOnDelay",1.0,false,showBottomHint,[hint]);
                }
                else if(bottomHint.visible)
                {
                    showBottomHint(hint);
                }
            }
            else
            {
                if(!hasTimer("bottomHintOffDelay"))
                {
                    addTimerByName("bottomHintOffDelay",0.3,false,hideBottomHint);
                }
            }
        }

        public function onMouseMoveBottomHint(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target)
            {
                return;
            }

            if(target === lastBottomHintTarget || isToolBox2Showing)
            {   
                return;
            }

            //TODO : 여백이 좁으면 왔다갔다 스크롤링도 추가해야함

            removeTimer("bottomHintOnDelay")
            lastBottomHintTarget = target;

            if(isCaptureModeON)
            {
                showBottomHintForTargetCaptureMode(target);
            }
            else if(!isHintUnavailableWithFillPen(target))
            {
                showBottomHintForTarget(target);
            }
        }

        public function updateHightLightBoxZOrderByTarget(target:DisplayObject):void
        {
            const topIndex:int = stage.numChildren - 1;
            const tbIndex:int = stage.getChildIndex(topBar);
            const hIndex:int = stage.getChildIndex(hintHighlightBox);

            if (topBar.contains(target) || replayTimelineBox.contains(target))
            {
                var desiredIndex:int = Math.min(tbIndex + 1, topIndex);
                if (hIndex != desiredIndex)
                {
                    stage.setChildIndex(hintHighlightBox, desiredIndex);
                }
            }
            else
            {
                var desiredIndex2:int = Math.max(tbIndex - 1, 0);
                if (hIndex != desiredIndex2)
                {
                    stage.setChildIndex(hintHighlightBox, desiredIndex2);
                }
            }
        }

        public function showHintHighlightBox(target:DisplayObject,rect:Rectangle = null):void
        {
            hintHighlightBox.graphics.clear();
            hintHighlightBox.graphics.lineStyle(2*Global.getUIScale(), Global.getHintHightlightColor(), 1.0);

            rect = target.getBounds(stage);
            const panelrect:Rectangle = canvasLayer1Bitmap.getBounds(stage);

            var gp:Point = target.localToGlobal(new Point(0, 0));
            if (target === colorPickerBox.rgbInfoText)
            {
                gp.x -= 2;
                gp.y -= 3;
            }
            else if (target.parent === canvasNavigatorBox)
            {
                gp = canvasNavigatorBox.localToGlobal(new Point(0, 0));
                target = canvasNavigatorBox;
            }

            hintHighlightBox.x = rect.x;
            hintHighlightBox.y = rect.y;
            hintHighlightBox.graphics.drawRect(0, 0, rect.width, rect.height);
            updateHightLightBoxZOrderByTarget(target);
            hintHighlightBox.visible = true;
        }

        public function hideHintHighlightBox():void
        {
            hintHighlightBox.graphics.clear();
            hintHighlightBox.visible = false;
        }

        public function isBottomBarVisible():Boolean
        {
            return bottomBar.visible;
        }

        public function isHighlightBoxVisible():Boolean
        {
            return hintHighlightBox.visible;
        }

        public function hideBottomHint():void
        {
            removeTimer("bottomHintOnDelay");
            hideHintHighlightBox();
            bottomBar.visible = false;
        }

        public function showBottomHint(str:String):void
        {
            if(str === "")
            {
                return;
            }

            bottomHint.setHintText(str);
            bottomHint.show();
            updateBottomBarLayoutAndColor();
            bottomBar.visible = true;
            setAsTopChild(bottomBar);
        }

        public function hideMouseHint():void
        {
            mouseHint.hide();
        }

        public function showMouseHintTemp(str:String):void
        {
            // if(isHintUnavailable())
            // {
            //     return;
            // }
            showMouseHint(str,1.0);
        }

        public function showMouseHint(str:String,duration:Number=0.0):void
        {
            if(str !== "")
            {
                mouseHint.setHintText(str);
            }

            const stw:uint = stage.stageWidth+1;
            const sth:uint = stage.stageHeight+1;
            const hintWidth:Number = mouseHint.getScaledTextWidth();
            const hintHeight:Number = mouseHint.getScaledTextHeight();
            var hintX:Number = Math.floor(mouseX-hintWidth/2)+5;
            var hintY:Number = Math.floor(mouseY-45*Global.getUIScale());
            const hintRight:int = hintX+hintWidth;
            const hintBottom:int = hintY+hintHeight;

            if(hintX < 0)
            {
                hintX = 0;
            }
            else if(hintRight > stw)
            {
                hintX = stw-hintWidth;
            }

            if(hintY < 0)
            {
                hintY = 0;
            }
            else if(hintBottom >= sth)
            {
                hintY = sth-hintHeight;
            }

            mouseHint.x = Math.floor(hintX);
            mouseHint.y = Math.floor(hintY);
            mouseHint.setHintText(str);
            mouseHint.show(duration);
            setAsTopChild(mouseHint);
        }

        //drag load
        public function keyDownLoadMenuBox(e:KeyboardEvent):void
        {
            const firstKey:uint = getFirstPressedKey();
            if(firstKey === KEY.esc || firstKey === KEY.backspace)
            {
                closeLoadMenuBox();
            }
        }

        public function prepareOpenLoadBox(fromUpdate:Boolean,reflayermenu:Boolean,file:File,bmpd:BitmapData,filetype:String):void
        {            
            clearKeyBuffer();
            closeToolBox2();
            loadMenuBoxFileType = filetype;
            loadMenuBoxFile = file;
            loadMenuBoxBitmapData = bmpd;

            if(isLassoToolStarted === true)
            {
                cancelLassoTool();
                resetLassoBox();
                resetOldTool();
                selectPenTool();
            }

            if(bmpd)
            {
                loadMenuBox.setPreviewImage(bmpd);
                loadMenuBox.updateClickBlockerSize(stage.stageWidth,stage.stageHeight);
            }

            if(loadMenuBox.visible === false)
            {
                loadMenuBox.updateUIColor();

                if(fromUpdate)
                {
                    loadMenuBox.showPleaseWait("Waiting for the file to be saved");
                }
                else
                {
                    loadMenuBox.hidePleaseWait();
                    if(reflayermenu)
                    {
                        loadMenuBox.activateReflayerButtonOnly();
                    }
                    else
                    {
                        loadMenuBox.activateAllButtons();
                    }
                }

                openLoadMenuBox();
                setAsTopChild(loadMenuBox);
            }
        }
        
        public function tryLoadClipboardImage(toRefLayer:Boolean):void
        {
            if(isFileLoadBlocked())
            {
                return;
            }

            rFileStream.close();
            if(hasTimer("replayRestartTimer"))
            {
                cancelReplayRestartTimer();
            }

            const data:* = getSystemClipboardData();

            if(data)
            {
                if(data is BitmapData)
                {
                    prepareOpenLoadBox(false,toRefLayer,null,data as BitmapData,"clipboard");
                }
                else if (data is Array && data.length > 0)
                {
                    const file:File = data[0] as File;
                    if(canDisplayLoadMenuBox(file))
                    {
                        prepareLoadMenuBoxFromImageFile(file, toRefLayer);
                    }
                }
            }
        }

        public function getSystemClipboardData():*
        {
            return Clipboard.generalClipboard.getData(ClipboardFormats.BITMAP_FORMAT)
            || Clipboard.generalClipboard.getData(ClipboardFormats.FILE_LIST_FORMAT);
        }

        public function disableTopBarClipboardButton():void
        {
            topBar.clipBoardButton.alpha = Global.OFFALPHA;
            refLayerMenuBox.refClipBoardButton.alpha = Global.OFFALPHA;
            isClipBoardButtonActivated = false;
        }

        public function enableTopBarClipboardButton():void
        {
            topBar.clipBoardButton.alpha = 1.0;
            refLayerMenuBox.refClipBoardButton.alpha = 1.0;
            isClipBoardButtonActivated = true;
        }

        public function isWebpFile(file:File):Boolean
        {
            var stream:FileStream = new FileStream();
            stream.open(file, FileMode.READ);

            var header:ByteArray = new ByteArray();
            stream.readBytes(header, 0, Math.min(12, stream.bytesAvailable));
            stream.close();

            // Check "RIFF" at bytes 0–3
            if (header.length >= 12 &&
                    header[0] == 0x52 && header[1] == 0x49 &&
                    header[2] == 0x46 && header[3] == 0x46 &&
                    header[8] == 0x57 && header[9] == 0x45 &&
                    header[10] == 0x42 && header[11] == 0x50)
            {
                return true;
            }

            return false;
        }

        public function canDisplayLoadMenuBox(file:File):Boolean
        {
            return !loadMenuBox.visible || !isSameFile(file, lastLoadedFile);
        }

        public function prepareLoadMenuBoxFromImageFile(file:File,toRefLayer:Boolean):void
        {
            validateImageFile(file,
            function(type:String,file:File,bmpd:BitmapData):void
            {
                lastLoadedFile = file;
                if(type === "image")
                {
                    prepareOpenLoadBox(false,toRefLayer,file,bmpd,"image");
                }
                else if(type === "2020")
                {
                    prepareOpenLoadBox(false,toRefLayer,file,getFinalBitmapDataFrom2020File(file,true),"2020");
                }
                else if(type === "webp")
                {
                    var byteArray:ByteArray = new ByteArray();
                    var stream:FileStream = new FileStream();

                    stream.open(file, FileMode.READ);
                    stream.readBytes(byteArray, 0, stream.bytesAvailable);
                    stream.close();
                    prepareOpenLoadBox(false,toRefLayer,file,libwebp.DecodeWebp(byteArray),"webp");
                }
            },showLoadFaildMouseHint);
        }

        public function validateImageFile(file:File,callbackOk:Function,callbackCancel:Function=null):void
        {
            var loader:Loader = new Loader();

            function cleanEvents():void
            {
                loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onCompleteValidateFile);
                loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onErrorValidateFile);
                loader.unload();
                loader = null;
            }

            function onCompleteValidateFile(e:Event):void
            {
                if(callbackOk !== null)
                {
                    const bmpd:BitmapData = new BitmapData(loader.content.width,loader.content.height,true,0);
                    bmpd.draw(loader);
                    callbackOk("image",file,bmpd);
                }
                cleanEvents();
            }

            function onErrorValidateFile(e:IOErrorEvent):void
            {
                cleanEvents();

                try
                {
                    if (file.exists)
                    {
                        if(isTrue2020File(file))
                        {
                            if(callbackOk !== null)
                            {
                                callbackOk("2020",file,null);
                                return;
                            }
                        }
                        else if(isWebpFile(file))
                        {
                            if(callbackOk !== null)
                            {
                                callbackOk("webp",file,null);
                                return;
                            }
                        }
                    }
                }
                catch (error:Error)
                {
                    
                }

                if(callbackCancel !== null)
                {
                    callbackCancel();
                }
            }

            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onCompleteValidateFile);
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onErrorValidateFile);
            loader.load(new URLRequest(file.url));
        }

        public function checkCanUseClipBoardButton():void
        {
            const data:* = getSystemClipboardData();

            if (data is BitmapData)
            {
                enableTopBarClipboardButton();
                return;
            }

            if (data is Array && data.length > 0)
            {
                validateImageFile(data[0] as File,
                function(type:String,file:File,bmpd:BitmapData):void
                {
                    enableTopBarClipboardButton();
                },
                function():void
                {
                    disableTopBarClipboardButton();
                });
            }
            else
            {
                disableTopBarClipboardButton();
            }
        }

        public function getBitmapHash(bmp:BitmapData):uint
        {
            var bytes:ByteArray = bmp.getPixels(bmp.rect);
            bytes.position = 0;

            var hash:uint = 0;
            while (bytes.bytesAvailable >= 4)
            {
                hash ^= bytes.readUnsignedInt();
            }
            return hash;
        }

        public function isSameFile(file1:File,file2:File):Boolean
        {
            if(!lastLoadedFile)
            {
                return false;
            }

            return file1.nativePath === file2.nativePath
            && file1.size === file2.size
            && file1.modificationDate.getTime() === file2.modificationDate.getTime()
            && file1.creationDate.getTime() === file2.creationDate.getTime();
        }

        public function isFileLoadBlocked():Boolean
        {
            return isFileBrowserOpened || isSaveInProgress
            || rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_PROCESSING;
        }

        //운영체제에서 2020파일 연결을 FOFOPAINT로 해줬을때
        public function onInvokeEvent(e:InvokeEvent):void
        {
            if(isFileLoadBlocked())
            {
                e.preventDefault();
                return;
            }

            var arguments:Array = e.arguments;

            if(arguments && arguments.length > 0)
            {
                try
                {
                    var file:File = new File(arguments[0] as String);

                    if(file.exists)
                    {
                        if(!canDisplayLoadMenuBox(file))
                        {
                            return;
                        }
                        lastLoadedFile = file;

                        if(isReplayStarted)
                        {
                            stopReplay();
                        }
                        
                        if(hasTimer("replayRestartTimer"))
                        {
                            cancelReplayRestartTimer();
                        }

                        prepareLoadMenuBoxFromImageFile(file,false);
                    }
                }
                catch(err:Error)
                {

                }
            }
        }

        
        public function onDragDropStage(e:NativeDragEvent):void
        {
            if(isFileLoadBlocked())
            {
                return;
            }

            rFileStream.close();
            cancelReplayRestartTimer();

            const data:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
            if(data && data.length > 0)
            {
                const file:File = data[0] as File;

                if(canDisplayLoadMenuBox(file))
                {
                    prepareLoadMenuBoxFromImageFile(file,false);
                    return;
                }
            }
        }

        public function onDragEnterStage(e:NativeDragEvent):void
        {
            if(isFileLoadBlocked())
            {
                return;
            }

            var c:Clipboard = e.clipboard;
            if(c.hasFormat("air:file list") === true)
            {
                if(isReplayStarted) stopReplay();
                var files:Array = c.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
                //두개이상 선택하고 드래그 할수있기 때문에 하나만 선택되었을때 되도록 해줌
                if(files && files.length == 1)
                {
                    NativeDragManager.acceptDragDrop(stage);
                }
            }
        }

        public function loadFileTo(where:String):void
        {
            if(where === "reflayer")
            {
                if(loadMenuBoxBitmapData)
                {
                    transferLoadedImageToRefLayer(loadMenuBoxBitmapData,loadMenuBoxBitmapData.width,loadMenuBoxBitmapData.height);
                    if(!isReplayModeON && !isCaptureModeON)
                    {
                        openRefLayerMenu();
                    }
                    loadMenuBoxBitmapData.dispose();
                    loadMenuBoxBitmapData = null;
                }
            }
            else if(loadMenuBoxFile !== null)
            {
                if(loadMenuBoxFile.exists)
                {
                    if(loadMenuBoxFileType === "2020")
                    {
                        var fs:FileStream = new FileStream();
                        function onCompleteFileStream(e:Event):void
                        {
                            fs.removeEventListener(Event.COMPLETE, onCompleteFileStream);
                            fs.removeEventListener(IOErrorEvent.IO_ERROR, onErrorFileStream);
                            fs.close();
                            fs = null;

                            lastSaveFileName = loadMenuBoxFile.name;
                            lastSaveFilePath = loadMenuBoxFile.nativePath;
                            enterDrawModeOnLoadFile();
                            loadReplayFile(loadMenuBoxFile);
                            loadMenuBoxFile = null;
                        }

                        function onErrorFileStream(e:Event):void
                        {
                            showLoadFaildMouseHint();
                            fs.removeEventListener(Event.COMPLETE, onCompleteFileStream);
                            fs.removeEventListener(IOErrorEvent.IO_ERROR, onErrorFileStream);
                            fs.close();
                            fs = null;
                            loadMenuBoxFile = null;
                        }

                        fs.addEventListener(Event.COMPLETE, onCompleteFileStream);
                        fs.addEventListener(IOErrorEvent.IO_ERROR, onErrorFileStream);
                        fs.openAsync(loadMenuBoxFile,FileMode.READ);
                    }
                    else if(loadMenuBoxFileType === "webp" || loadMenuBoxFileType === "image")
                    {
                        lastSaveFileName = loadMenuBoxFile.name;
                        lastSaveFilePath = loadMenuBoxFile.nativePath;
                        loadImageFile(loadMenuBoxBitmapData.width,loadMenuBoxBitmapData.height,loadMenuBoxBitmapData,null);
                    }
                }
                else
                {
                    showLoadFaildMouseHint();
                }
            }
            else if(loadMenuBoxFileType === "clipboard")
            {
                enterDrawModeOnLoadFile();
                lastSaveFileName = getRandomFileName();
                loadImageFile(loadMenuBoxBitmapData.width,loadMenuBoxBitmapData.height,loadMenuBoxBitmapData,null);
            }
        }

        public function getMyPaletteIndexByMousePosLimitBound():int
        {
            const isAllViewMode:Boolean = (myPalettePresetType === 0 && isMyPaletteExpended);
            const paletteLines:int = (isAllViewMode) ? 8:2;
            var xLineIndex:int = Math.floor(colorPickerBox.myPaletteBox.mouseX/myPaletteColorWidth);
            var yLineIndex:int = Math.floor(colorPickerBox.myPaletteBox.mouseY/myPaletteColorHeight)

            if(xLineIndex < 0) xLineIndex = 0;
            else if(xLineIndex > 9) xLineIndex = 9;

            if(yLineIndex < 0) yLineIndex = 0;
            else if(yLineIndex >= paletteLines)
            {
                if(isAllViewMode)
                {
                    yLineIndex = paletteLines;
                }
                else
                {
                    yLineIndex = paletteLines-1;
                }
            }

            return xLineIndex+yLineIndex*10;
        }

        public function getHistoryIndexByMousePos():int
        {
            const xLineIndex:int = Math.floor(colorPickerBox.colorHistoryBox.mouseX/myPaletteColorWidth);
            const yLineIndex:int = 10*(Math.floor(colorPickerBox.colorHistoryBox.mouseY/myPaletteColorHeight));

            if(xLineIndex+yLineIndex < 0 || xLineIndex+yLineIndex > myPaletteColorLimit)
            {
                return -1;
            }

            return xLineIndex+yLineIndex;
        }

        public function getMyPaletteIndexByMousePos():int
        {
            var xLineIndex:int = Math.floor(colorPickerBox.myPaletteBox.mouseX/myPaletteColorWidth);
            var yLineIndex:int = 10*(Math.floor(colorPickerBox.myPaletteBox.mouseY/myPaletteColorHeight));
            if(xLineIndex > 9) xLineIndex = 9;
            if(yLineIndex > 80) yLineIndex = 80;

            if(xLineIndex+yLineIndex < 0 || xLineIndex+yLineIndex > myPaletteColorLimit)
            {
                return -1;
            }

            return xLineIndex+yLineIndex;
        }

        public function getTegakiColorPresetIndex(index:int):int
        {
            if(index >= 10)
            {
                index = index-10;
            }

            return Math.floor(index/2)*2;
        }

        public function selectTegakiColorPreset(index:int):void
        {
            index = getTegakiColorPresetIndex(index);

            const mainColor:uint = myPaletteTegakiPreset[index];

            if(mainColor !== colorPickerBox.getRGBInfoBGColor())
            {
                penColor = myPaletteTegakiPreset[index];
                updateColorPickerCursorPosAndRGBInfo(penColor);
            }

            if(!isFillPenStarted)
            {
                const bgColor:uint = myPaletteTegakiPreset[index+10];
                if(bgColor !== CANVAS_BG_COLOR)
                {
                    updateCanvasBGColorDrawMode(bgColor);

                    if(isCanvasWindowON)
                    {
                        updateCanvasWindowBGColor(CANVAS_BG_COLOR,canvasWindowLayer1Bitmap.bitmapData);
                    }
                    addUndoBGColorData(bgColor);
                }
                ensureDrawingToolSelected(false);
            }
        }

        public function isSelctedHistoryColorEmpty(index:int):Boolean
        {
            return !(myPalettePreset[index+90] is uint);
        }

        public function isSelctedColorEmpty(index:int):Boolean
        {
            var list:Array = (myPalettePresetType === 1) ? myPaletteDrawrPreset
                            :(myPalettePresetType === 2) ? myPaletteTegakiPreset
                            :myPalettePreset;

            return !(list[index] is uint);
        }

        public function pickColor(pickedColor:uint):void
        {
            if(isPenColorMode())
            {
                penColor = pickedColor;
                updateColorPickerCursorPosAndRGBInfo(pickedColor);
                ensureDrawingToolSelected(false);
            }
            else if(isBackgroundColorMode())
            {
                updateCanvasBGColorDrawMode(pickedColor);
                if(isCanvasWindowON) updateCanvasWindowBGColor(CANVAS_BG_COLOR,canvasWindowLayer1Bitmap.bitmapData);
                addUndoBGColorData(pickedColor);
            }
        }

        public function selectHistoryColor():void
        {
            const index:int = getHistoryIndexByMousePos();

            if(index < 0 || myPaletteDragStarted)// || index !== myPaletteDragClickedIndex)
            {
                return;
            }

            if(!(myPalettePreset[index+90] is uint))
            {
                if(isTransparentPenColor === false)
                {
                    selectTransparentColor();
                }
                return;
            }

            const pickedColor:uint = myPalettePreset[index+90];

            if(pickedColor === colorPickerBox.getRGBInfoBGColor() && !isTransparentPenColor)
            {
                return;
            }

            pickColor(pickedColor);
        }

        public function selectMyPaletteColor():void
        {
            const index:int = getMyPaletteIndexByMousePos();

            if(index < 0)
            {
                return;
            }

            if(index !== myPaletteDragClickedIndex)
            {
                if(myPalettePresetType === 0)
                {
                    return;
                }
            }

            var pickedColor:uint;

            if(myPalettePresetType === 0)
            {
                if(isSelctedColorEmpty(index))
                {
                    if(isTransparentPenColor === false && isColorPickerModeBG === false)
                    {
                        selectTransparentColor();
                    }
                    return;
                }

                pickedColor = myPalettePreset[index];

                // if(pickedColor === pickerBox.getRGBInfoBGColor() && !penColorTransparentFlag)
                // {
                //     return;
                // }
            }
            else if(myPalettePresetType === 1)
            {
                if(isSelctedColorEmpty(index))
                {
                    if(isTransparentPenColor === false && isColorPickerModeBG === false)
                    {
                        selectTransparentColor();
                    }
                    return;
                }

                pickedColor = myPaletteDrawrPreset[index];

            //     if(pickedColor === CANVAS_BG_COLOR && !penColorTransparentFlag)
            //     {
            //         return;
            //     }
            }
            else if(myPalettePresetType === 2)
            {
                selectTegakiColorPreset(index);
                return;
            }

            pickColor(pickedColor);
        }


        public function saveMypPaletteList():void
        {
            const fs:FileStream = new FileStream();

            fs.open(myPaletteDataFilePath,FileMode.WRITE);
            fs.writeObject(myPalettePreset);
            fs.close();
        }

        public function initializeMyPaletteList():void
        {
            updateHistoryList();
            updateMyPaletteList();

            if(!myPaletteDataFilePath.exists)
            {
                saveMypPaletteList();
            }
        }

        public function switchMyPaletteToCompact():void
        {
            isMyPaletteExpended = false;
            updateMyPaletteList();
            hideBottomHint();
            checkFOFOPosition();
        }

        public function switchMyPaletteToExpended():void
        {
            isMyPaletteExpended = true;
            updateMyPaletteList();
            hideBottomHint();
            checkFOFOPosition();
        }

        public function addColorToMyPalette(color:uint,index:int):void
        {
            if(index < 0) return;

            if(isSelctedColorEmpty(index))
            {
                if(myPaletteColorBeforeAddColor[0] === index)
                {
                    myPalettePreset[index] = myPaletteColorBeforeAddColor[1];
                    updateMyPaletteList();
                    addColorMyPaletteHistory(color);
                }
                else
                {
                    myPalettePreset[index] = color;
                    updateMyPaletteList();
                    addColorMyPaletteHistory(color);
                }
            }
            else
            {
                if(myPalettePreset[index] !== colorPickerBox.getRGBInfoBGColor())
                {
                    myPaletteColorBeforeAddColor[0] = index;
                    myPaletteColorBeforeAddColor[1] = myPalettePreset[index];
                    myPalettePreset[index] = (isTransparentPenColor) ? null:color;
                    updateMyPaletteList();
                    addColorMyPaletteHistory(color);
                }
                else
                {
                    if(isTransparentPenColor)
                    {
                        myPaletteColorBeforeAddColor[0] = index;
                        myPaletteColorBeforeAddColor[1] = myPalettePreset[index];
                    }

                    myPalettePreset[index] = null;
                    updateMyPaletteList();
                    addColorMyPaletteHistory(color);
                }
            }
        }

        public function clearMyPaletteList():void
        {
            for (var i:int = 0; i < 90; i++)
            {
                myPalettePreset[i] = null;
            }

            if(myPalettePresetType === 0)
            {
                updateHistoryList();
                updateMyPaletteList();
            }
        }

        public function addColorMyPaletteHistory(color:uint):void
        {
            //색깔 같으면 체크안함
            if(myPalettePreset[90] === color)
            {
                return;
            }

            if((pickerIgnoreHistoryColor as uint) === color)
            {
                pickerIgnoreHistoryColor = null;
                return;
            }

            //이미 있는 색깔이면 다시 최신으로 갱신
            for(var i:uint=90;i<100;i++)
            {
                if(color === myPalettePreset[i])
                {
                    const tmpColor:uint = myPalettePreset.splice(i,1);
                    if(myPalettePreset[90] === null || myPalettePreset[90] === undefined)
                    {
                        myPalettePreset[90] = tmpColor;
                    }
                    else
                    {
                        myPalettePreset.insertAt(90,tmpColor);
                    }
                    updateHistoryList();
                    return;
                }
            }

            //첫부분에 셕이 없으면 그대로 넣어줌
            if(myPalettePreset[90] === null || myPalettePreset[90] === undefined)
            {
                myPalettePreset[90] = color;
            }
            else
            {
                myPalettePreset.insertAt(90,color);
                myPalettePreset.removeAt(100);
            }

            updateHistoryList();
        }

        public function updateHistoryList(ignoreIndex:int=-1):void
        {
            colorPickerBox.colorHistoryBox.graphics.clear();

            for(var i:uint=0;i<10;i++)
            {
                if(90+i === ignoreIndex)
                {
                    drawColorStartPos(colorPickerBox.colorHistoryBox.graphics,myPaletteColorWidth*i,0,myPaletteColorWidth,myPaletteColorHeight);
                    continue;
                }
                if(!(myPalettePreset[90+i] is uint))
                {
                    colorPickerBox.colorHistoryBox.graphics.beginBitmapFill(colorPickerBox.myPaletteTransBGBmpd);
                }
                else
                {
                    colorPickerBox.colorHistoryBox.graphics.beginFill(myPalettePreset[i+90]);
                }

                colorPickerBox.colorHistoryBox.graphics.drawRect(myPaletteColorWidth*i,0,myPaletteColorWidth,myPaletteColorHeight);
            }

            colorPickerBox.colorHistoryBox.graphics.endFill();
            colorPickerBox.colorHistoryBox.graphics.lineStyle(1,0,0.2);

            for(i=1;i<10;i++)
            {
                colorPickerBox.colorHistoryBox.graphics.moveTo(myPaletteColorWidth*i,0);
                colorPickerBox.colorHistoryBox.graphics.lineTo(myPaletteColorWidth*i,myPaletteColorHeight);
            }
        }

        public function drawColorStartPos(g:Graphics,px:Number,py:Number,ww:Number,hh:Number):void
        {
            g.beginFill(0xFFFFFF);
            g.drawRect(px,py,myPaletteColorWidth,myPaletteColorHeight);
            g.endFill();
            g.lineStyle(3,0xFF6600);
            g.moveTo(px+5,py+5);
            g.lineTo(px+ww-5,py+hh-5);
            g.moveTo(px+ww-5,py+5);
            g.lineTo(px+5,py+hh-5);
            g.lineStyle(0,0,0);
        }

        public function updateMyPaletteList(ignoreIndex:int=-1):void
        {
            const type:int = myPalettePresetType;
            const arr:Array = (type === 0) ? myPalettePreset
                             :(type === 1) ? myPaletteDrawrPreset
                             :(type === 2) ? myPaletteTegakiPreset : null;

            if(arr === null) return;

            const ww:Number = myPaletteColorWidth;
            const hh:Number = myPaletteColorHeight;

            var len:int = (type === 0 && isMyPaletteExpended) ? myPaletteColorLimit-10:20;
            var nextX:Number = 0.0;
            var nextY:Number = 0.0;

            colorPickerBox.myPaletteBox.graphics.clear();
            colorPickerBox.myPaletteBox.graphics.lineStyle(0,0,0);

            var px:Number;
            var py:Number;

            //색깔 쭉 그려주기
            for(var i:uint=0;i<len;i++)
            {
                if(i > 0 && i % 10 === 0)
                {
                    nextX = 0;
                    nextY++;
                }

                px = ww*nextX;
                py = hh*(nextY);
                nextX += 1.0;

                if(i === ignoreIndex)
                {
                    drawColorStartPos(colorPickerBox.myPaletteBox.graphics,px,py,ww,hh);
                    continue;
                }

                if(!(arr[i] is uint))
                {
                    colorPickerBox.myPaletteBox.graphics.beginBitmapFill(colorPickerBox.myPaletteTransBGBmpd);
                }
                else
                {
                    colorPickerBox.myPaletteBox.graphics.beginFill(arr[i]);
                }

                colorPickerBox.myPaletteBox.graphics.drawRect(px,py,ww,hh);
            }
            colorPickerBox.myPaletteBox.graphics.endFill();

            //구분선 그려주기
            if(type === 2) //tegaki
            {
                colorPickerBox.myPaletteBox.graphics.lineStyle(1,0,0.2);
                colorPickerBox.myPaletteBox.graphics.moveTo(0,hh);
                colorPickerBox.myPaletteBox.graphics.lineTo(ww*10,hh);

                for(i=2;i<10;i+=2)
                {
                    colorPickerBox.myPaletteBox.graphics.moveTo(ww*i,0);
                    colorPickerBox.myPaletteBox.graphics.lineTo(ww*i,hh*2);
                }
            }
            else if(type === 1) // drawr
            {
                colorPickerBox.myPaletteBox.graphics.lineStyle(1,0,0.2);
                colorPickerBox.myPaletteBox.graphics.moveTo(0,hh);
                colorPickerBox.myPaletteBox.graphics.lineTo(ww*10,hh);

                for(i=1;i<10;i++)
                {
                    colorPickerBox.myPaletteBox.graphics.moveTo(ww*i,0);
                    colorPickerBox.myPaletteBox.graphics.lineTo(ww*i,hh*2);
                }
            }
            else //my palette
            {
                if(isMyPaletteExpended === false)
                {
                    //가로선
                    colorPickerBox.myPaletteBox.graphics.lineStyle(1,0,0.2);
                    colorPickerBox.myPaletteBox.graphics.moveTo(0,hh);
                    colorPickerBox.myPaletteBox.graphics.lineTo(ww*10,hh);

                    //세로
                    for(i=1;i<10;i++)
                    {
                        colorPickerBox.myPaletteBox.graphics.moveTo(myPaletteColorWidth*i,0);
                        colorPickerBox.myPaletteBox.graphics.lineTo(myPaletteColorWidth*i,hh*2);
                    }
                }
                else
                {
                    colorPickerBox.myPaletteBox.graphics.lineStyle(1,0,0.2);

                    //가로
                    for(i=1;i<9;i++)
                    {
                        colorPickerBox.myPaletteBox.graphics.moveTo(0,hh*i);
                        colorPickerBox.myPaletteBox.graphics.lineTo(myPaletteColorWidth*10,hh*i);
                    }
                    //세로
                    for(i=1;i<10;i++)
                    {
                        colorPickerBox.myPaletteBox.graphics.moveTo(myPaletteColorWidth*i,0);
                        colorPickerBox.myPaletteBox.graphics.lineTo(myPaletteColorWidth*i,hh*9);
                    }
                }
            }

            colorPickerBox.updateMainColorPickerBoxPosition(isColorPickerBoxPositionSwapped);
        }

        public function initializeResizeButtonFamily():void
        {
            function drawRect(target:Sprite):void
            {
                target.visible = false;
                target.graphics.clear();
                target.graphics.beginFill(0xFF0000);
                target.graphics.drawRect(0, 0, 10,10);
                target.graphics.endFill();
            }
            resizeButtonU.name = "resizeButtonU";
            resizeButtonD.name = "resizeButtonD";
            resizeButtonR.name = "resizeButtonR";
            resizeButtonL.name = "resizeButtonL";

            drawRect(resizeButtonU);
            drawRect(resizeButtonD);
            drawRect(resizeButtonL);
            drawRect(resizeButtonR);

            canvasAnchorPoint.addChild(resizeButtonU);
            canvasAnchorPoint.addChild(resizeButtonD);
            canvasAnchorPoint.addChild(resizeButtonR);
            canvasAnchorPoint.addChild(resizeButtonL);
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
            fs.open(replayCacheImageFolderPath.resolvePath(String(rJumpImageFrameData.length-1)),FileMode.WRITE);
            fs.writeObject([layer1ImageData // 0
                            ,layer2ImageData
                            ,imageWidth
                            ,imageHeight
                            ,bgColor  //4
                            ,lastBytePosition
                            ,frameSum
                            ,mirrorFlag]); //7
            fs.close();
        }

        public function generateReplayCacheImage():void //loadrep
        {
            const fs:FileStream = new FileStream();
            const fs2:FileStream = new FileStream();
            const totalSize:Number = replayDataFilePath.size;
            const deepUndoFlag:Boolean = isDeepUndoEnabled;
            var rect:Rectangle;
            var _frameSum:Number = 0;
            var _frameSumLast:Number = 0;
            var dataWriteCount:uint = 0;
            var hintPrintTimeSave:int = getTimer();

            canvasAnchorPoint.visible = false;
            rCanvasAnchorPoint.visible = false;
            canvasNavigatorBox.visible = false;
            undoManager.resetRJumpImageCount();
            clearCanvasReplayMode();//리플레이 캔버스 먼저 깨끗하게

            //첫 이미지 그려줌
            rCanvasLayer1BitmapData = updateBitmapData(rCanvasLayer1BitmapData,rFirstImageLayer1BitmapData,rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = updateBitmapData(rCanvasLayer2BitmapData,rFirstImageLayer2BitmapData,rCanvasLayer2Bitmap);

            //크기도 바꿔주고
            updateCanvasSizeReplayMode(rCanvasLayer1BitmapData.width,rCanvasLayer1BitmapData.height);

            fs.open(replayDataFilePath,FileMode.READ);
            fs.position = 0;

            rMirrorON = false;
			loadMenuBox.visible = false;

            function printPrograssHint(bytes:Number):void
            {
                const perc:Number = Math.round(((totalSize-bytes)/totalSize)*100);
                // const str:String = perc.toFixed(1)+"%";
        
                loadMenuBox.updatePlaseWaitPrograss(perc+"%");
            }

            loadMenuBox.showPleaseWait("Reading replay file");
            openLoadMenuBox();

            function onFrameEnter(e:Event):void
            {
                while(true)
                {
                    const namojiBytes:Number = fs.bytesAvailable;

                    if(namojiBytes === 0)
                    {
                        stage.removeEventListener(Event.ENTER_FRAME,onFrameEnter);
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

                        if(mirrorCommandReady)
                        {
                            rMirrorON = !rMirrorON;
                            mirrorCommandReady = rMirrorON;
                        }

                        isCanvasMirrored = rMirrorON;
                        rMirrorON = rMirrorON;
                        undoManager.updateUndoBaseImageMirrorFlag(rMirrorON);
                        canvasInfoBox.setMirror(rMirrorON);
                        canvasNavigatorBox.visible = true;

                        if(!isReplayModeON && isDeepUndoEnabled)
                        {
                            rDataReadFlag = false;
                            addInputEventsDrawMode();
                            // jumpFrame(undoData.getRFileTotalFrame()-1,JUMP_FRAME_ONCE);
                            renderReplayFrame(rPrevFrame,JUMP_FRAME_MANUAL);
                            applyReplayCanvasToDrawModeCanvas();
                            canvasAnchorPoint.visible = true;
                        }
                        else if(isReplayModeON)
                        {
                            updateReplayPrograssBarAndText();
                            updateReplaySpeedSliderAlpha();
                            updateDeleteReplayDataButtonsState();
                            clearRFrameTempCache();
                            rJumpImageIndexLast = -2;
                            rJumpImageNowFrameLast = -1;
                            rTempCachedLastImageIndex = -2;

                            disableDeepUndo();
                            undoToIndex(rData.length-1);
                            centerCanvas(true,false);

                            removeInputEventsDrawMode();
                            addInputEventsReplayMode();
                            rCanvasAnchorPoint.visible = true;
                        }

                        closeLoadMenuBox();
                        clearKeyBuffer();
                        return;
                    }

                    if(getTimer()-hintPrintTimeSave > 250)
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

                    if(dataWriteCount > REPLAY_DISK_CACHE_FRAME_INTERVAL)
                    {
                        var imgData1:ByteArray = new ByteArray();
                        var imgData2:ByteArray = new ByteArray();

                        dataWriteCount = 0;
                        rect = new Rectangle(0,0,rCanvasLayer1BitmapData.width,rCanvasLayer1BitmapData.height);
                        rCanvasLayer1BitmapData.copyPixelsToByteArray(rect,imgData1);
                        rCanvasLayer2BitmapData.copyPixelsToByteArray(rect,imgData2);
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

                        if(replayTimelineBox.prograssBar.width > 0)
                        {
                            resetReplayPrograssBarWidth();
                        }
                    }
                }
            }
            stage.addEventListener(Event.ENTER_FRAME,onFrameEnter);
        }

        public function enableFileOperationButtonsTopbar():void
        {
            topBar.enableFileOperationButtons(isClipBoardButtonActivated);
            if(isReplayModeON)
            {
                updateDeleteReplayDataButtonsState();
            }
        }

        public function disableFileOperationButtonsTopbar():void
        {
            if(isSaveInProgress === 0)
            {
                isSaveInProgress = 1;
            }

            if(topBar.saveButton.alpha === 1.0)
            {
                topBar.disableFileOperationButtons();
            }
        }

        public function startPngEncodingWorker(bmpd:BitmapData,bg:uint,isCaptureImage:Boolean,isTransBG:Boolean):void
        {
            sendDataToWorker(function():void
            {
                workerDataSendCount++;
                var ba:ByteArray = new ByteArray();
                bmpd.copyPixelsToByteArray(new Rectangle(0,0,bmpd.width,bmpd.height),ba);

                mainToBack.send("encodePNG");
                mainToBack.send(ba);
                mainToBack.send(bmpd.width);
                mainToBack.send(bmpd.height);
                mainToBack.send(bg);
                mainToBack.send(isTransBG);
                mainToBack.send(isCaptureImage);

                ba.clear()
                ba = null;
                bmpd.dispose();
                bmpd = null;
            });
        }

        public function startUndoImageCompressionWorker(data:ByteArray,data1:ByteArray):void
        {
            sendDataToWorker(function():void
            {
                workerDataSendCount++;
                mainToBack.send("compress_UndoData");
                mainToBack.send(data);
                mainToBack.send(data1);

                data.clear();
                data1.clear();
                data = null;
                data1 = null;
            });
        }

        public function saveReplayFile():void
        {
            if(replayDataFilePath.exists)
            {
                rLayer1FirstImageData.position = 0;
                rLayer2FirstImageData.position = 0;
                rLayer1CurrentImageData.position = 0;
                rLayer2CurrentImageData.position = 0;
                refLayerImageData.position = 0;
                replayDataReadBytes.position = 0;
                rLayer1FirstImageData.length = 0;
                rLayer2FirstImageData.length = 0;
                rLayer1CurrentImageData.length = 0;
                rLayer2CurrentImageData.length = 0;
                refLayerImageData.length = 0;
                replayDataReadBytes.length = 0;

                //첫번째 이미지 레이어 1 2 저장
                const fs:FileStream = new FileStream();
                const rImgDataW:Number = rFirstImageLayer1BitmapData.width;
                const rImgDataH:Number = rFirstImageLayer1BitmapData.height;
                var newRectangle:Rectangle = new Rectangle(0,0,rImgDataW,rImgDataH);

                rFirstImageLayer1BitmapData.copyPixelsToByteArray(newRectangle,rLayer1FirstImageData);
                rFirstImageLayer2BitmapData.copyPixelsToByteArray(newRectangle,rLayer2FirstImageData);

                //현재 캔버스 이미지 레이어 1 2 저장
                newRectangle = new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);
                canvasLayer1BitmapData.copyPixelsToByteArray(newRectangle,rLayer1CurrentImageData);
                canvasLayer2BitmapData.copyPixelsToByteArray(newRectangle,rLayer2CurrentImageData);

                //참고 레이어 이미지 저장
                if(canvasRefLayerBitmapData)
                {
                    const refImgWidth:Number = canvasRefLayerBitmapData.width;
                    const refImgHeight:Number = canvasRefLayerBitmapData.height;
                    newRectangle = new Rectangle(0,0,refImgWidth,refImgHeight);
                    canvasRefLayerBitmapData.copyPixelsToByteArray(newRectangle,refLayerImageData);
                }

                //리플레이 파일을 임시파일로 복사
                replayDataFilePath.copyTo(repFileTemp,true);

                //임시파일전체를 바이트배열로 읽어서 압축해줌
                fs.open(repFileTemp,FileMode.READ);
                fs.position = 0;

                //딥 언도일때는 읽은 바이트 까지만 읽어줌
                if(isDeepUndoEnabled)
                {
                    fs.readBytes(replayDataReadBytes,0,rFileLastBytePosition);
                    fs.close();
                }
                else
                {
                    //그게 아니면 전체 리플레이 데이터 끝까지 읽고 undo데이터까지 넣어줌
                    fs.readBytes(replayDataReadBytes,0,fs.bytesAvailable);
                    fs.close();
                    replayDataReadBytes.position = replayDataReadBytes.length;

                    for(var i:int=0,len:int=undoDataIndex;i<=len;i++)//리플레이 데이터랑 첫이미지 마지막 이미지 추가적으로 붙여줌
                    {
                        if(rData[i] && rData[i].length === 0)
                        {
                            continue;
                        }
                        replayDataReadBytes.writeObject(rData[i]);
                    }
                }

                startReplayDataCompressionWorker(rLayer1FirstImageData,rLayer2FirstImageData,rLayer1CurrentImageData,rLayer2CurrentImageData,refLayerImageData,replayDataReadBytes);
            }
        }

        public function startReplayDataCompressionWorker(dataA:ByteArray,dataA1:ByteArray,dataB:ByteArray,dataB1:ByteArray,dataC:ByteArray,dataD:ByteArray):void
        {
            sendDataToWorker(function():void
            {
                workerDataSendCount++;
                mainToBack.send("compress_ReplayData");
                mainToBack.send(dataA);
                mainToBack.send(dataA1);
                mainToBack.send(dataB);
                mainToBack.send(dataB1);
                mainToBack.send(dataC);
                mainToBack.send(dataD);
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
            });
        }

        public function writeReplayFile(dataA:ByteArray
                                        ,dataA1:ByteArray
                                        ,dataB:ByteArray
                                        ,dataB1:ByteArray
                                        ,dataC:ByteArray
                                        ,dataD:ByteArray):void
        {

            const fs:FileStream = new FileStream();
            const rImgDataW:int = rFirstImageLayer1BitmapData.width;
            const rImgDataH:int = rFirstImageLayer1BitmapData.height;
            const refImgWidth:Number = canvasRefLayerBitmapData.width;
            const refImgHeight:Number = canvasRefLayerBitmapData.height;

            //실제 저장할 파일을 다시 써줌
            fs.open(repFileTemp,FileMode.WRITE);

            fs.position = 0;
            fs.writeUTFBytes("FOFOPAINT"); //파일 헤더
            fs.writeUnsignedInt(dataD.length); //뒤에 압축된 바이트를 얼마나 건너 뛰어야 하는지 저장
            fs.writeBytes(dataD);

            if(mirrorCommandReady) //임시 미러가 되어있을때 진짜 캔버스로 반전되어있는데 리플레이 데이터에는 아직 써주지 않았으니까 넣어줌
            {
                const tempMirrorData:Array = [["mirror"]];
                fs.writeObject(tempMirrorData);
            }

            fs.writeObject(["rFirstImage",dataA,dataA1,rImgDataW,rImgDataH,rFirstImageBGColor]);
            fs.writeObject(["rFinalImage",dataB,dataB1,CANVAS_WIDTH,CANVAS_HEIGHT,CANVAS_BG_COLOR]);

            if(canvasRefLayerBitmapData)
            {
                fs.writeObject(["refimage",dataC, // 1
                                            refImgWidth,
                                            refImgHeight,
                                            canvasRefLayerBitmap.x,
                                            canvasRefLayerBitmap.y,
                                            canvasRefLayer.rotation,
                                            canvasRefLayer.scaleX,
                                            canvasRefLayer.scaleY,
                                            Boolean(canvasRefLayer.scaleX < 0),
                                            refLayerMenuDragXMoveSum,//10
                                            refLayerLastAlpha]);//11
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
                const newPath:String = lastSaveFilePath.substr(0,lastSaveFilePath.lastIndexOf(".png"))+".2020";
                repFileTemp.moveTo(new File(newPath),true);
            }
            catch(err:Error)
            {
                //파일 엑세스가 불가하므로 새로운 파일로 저장해줌
                if(isSaveInProgress === 1)
                {
                    isSaveInProgress = 0;
                }
                enableFileOperationButtonsTopbar();
                openSaveFileBrowser(true,true);
                return;
            }

            if(isSaveInProgress === 1)
            {
                isSaveInProgress = 0;
            }

            enableFileOperationButtonsTopbar();
        }

        public function loadReplayFile(oldFile:File):void //loadrep
        {
            if(isTrue2020File(oldFile) === false)
            {
                showLoadFaildMouseHint();
                return;
            }

            const fs:FileStream = new FileStream();
            var imgStartByte:uint = 0;
            var finalIMGBMPD:BitmapData = new BitmapData(1,1,true,0);
            var finalIMGBMPD1:BitmapData = new BitmapData(1,1,true,0);
            var imgW:uint = 0;
            var imgH:uint = 0;
            var bg:uint = 0;
            var errorFlag:Boolean = true;
            var rect:Rectangle;

            initializeReplayDataFile(true); //일단 썸네일 이미지랑 리플레이 데이터 청소
            oldFile.copyTo(repFileTemp,true);//repdata.c3p를 복사 덮어씌우기

            if(refLayerRawTransformData)
            {
                refLayerRawBitmapData.dispose();
                refLayerRawBitmapData = null;
                refLayerRawTransformData = null;
            }

            fs.open(repFileTemp,FileMode.READ);
            rJumpImageFrameData = [0];

            var d:Array;
            var ba:ByteArray;
            var replayData:ByteArray = new ByteArray();
            const isNew2020FileFlag:Boolean = isNew2020File(oldFile);

            if(isNew2020FileFlag)
            {
                const a:String = fs.readUTFBytes(9); //FOFOPAINT헤더 읽어줌
                const compBytes:uint = fs.readUnsignedInt(); // 압축된 데이터 길이 읽어줌
                if(compBytes > 0)
                {
                    //압축된 데이터 써주고 압축 풀어줌
                    fs.readBytes(replayData,0,compBytes);
                    replayData.uncompress();
                }
            }

            while(true)
            {
                if(fs.bytesAvailable === 0) break;
                d = fs.readObject()

                if(d[0] === "rFirstImage")
                {
                    if(d[2] is ByteArray === false)
                    {
                        ba = d[1] as ByteArray;
                        rect = new Rectangle(0,0,d[2],d[3]);
                        ba.uncompress();
                        rFirstImageLayer1BitmapData = new BitmapData(d[2],d[3],true,0);
                        rFirstImageLayer1BitmapData.lock();
                        rFirstImageLayer1BitmapData.setPixels(rect,ba);
                        rFirstImageLayer1BitmapData.unlock();
                        ba.clear();
                        ba = null;
                        rLastCanvasBGColor = d[4];
                        createFirstImageCache(rFirstImageLayer1BitmapData,null,d[4]);
                    }
                    else
                    {
                        ba = d[1] as ByteArray;
                        rect = new Rectangle(0,0,d[3],d[4]);
                        ba.uncompress();
                        rFirstImageLayer1BitmapData = new BitmapData(d[3],d[4],true,0);
                        rFirstImageLayer1BitmapData.lock();
                        rFirstImageLayer1BitmapData.setPixels(rect,ba);
                        rFirstImageLayer1BitmapData.unlock();
                        ba.clear();

                        ba = d[2] as ByteArray;
                        ba.uncompress();
                        rFirstImageLayer2BitmapData = new BitmapData(d[3],d[4],true,0);
                        rFirstImageLayer2BitmapData.lock();
                        rFirstImageLayer2BitmapData.setPixels(rect,ba);
                        rFirstImageLayer2BitmapData.unlock();
                        ba.clear();
                        ba = null;

                        rLastCanvasBGColor = d[5];
                        createFirstImageCache(rFirstImageLayer1BitmapData,rFirstImageLayer2BitmapData,d[5]); //0.cache 파일 갱신
                    }
                }
                else if(d[0] === "rFinalImage")//최종 이미지
                {
                    //레이어1일때 구버전
                    if(d[2] is ByteArray === false)
                    {
                        ba = d[1] as ByteArray;
                        rect = new Rectangle(0,0,d[2],d[3]);
                        ba.uncompress();
                        errorFlag = false;
                        finalIMGBMPD = new BitmapData(d[2],d[3],true,0);
                        finalIMGBMPD.lock();
                        finalIMGBMPD.setPixels(rect,ba);
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
                        rect = new Rectangle(0,0,d[3],d[4]);
                        ba.uncompress();
                        errorFlag = false;
                        finalIMGBMPD = new BitmapData(d[3],d[4],true,0);
                        finalIMGBMPD.lock();
                        finalIMGBMPD.setPixels(rect,ba);
                        finalIMGBMPD.unlock();
                        ba.clear();

                        ba = d[2] as ByteArray;
                        ba.uncompress();
                        finalIMGBMPD1 = new BitmapData(d[3],d[4],true,0);
                        finalIMGBMPD1.lock();
                        finalIMGBMPD1.setPixels(rect,ba);
                        finalIMGBMPD1.unlock();
                        ba.clear();
                        ba = null;

                        imgW = d[3];
                        imgH = d[4];
                        bg = d[5];
                    }
                }
                else if(d[0] === "refimage" || d[0] === "traceImage")
                {
                    ba = d[1] as ByteArray;
                    rect = new Rectangle(0,0,d[2],d[3]);
                    ba.uncompress();
                    refLayerRawBitmapData = new BitmapData(d[2], d[3],true,0);
                    refLayerRawBitmapData.lock();
                    refLayerRawBitmapData.setPixels(rect,ba);
                    refLayerRawBitmapData.unlock();
                    ba.clear();
                    ba = null;
                    d[0] = null;
                    d[1] = null;
                    refLayerRawTransformData = d.concat();
                }
                else if(isNew2020FileFlag) //신포멧인데 rData옛 버전에서rData압축안하고 넣어준거 읽어줌
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

            if(isNew2020FileFlag)
            {
                fs.open(replayDataFilePath,FileMode.WRITE);
                fs.position = 0;
                fs.writeBytes(replayData);
                fs.close();
            }
            else
            {
                //이미지직전까지 바이트를 기준으로 짤라줌, 즉 뒤에 붙은 첫 이미지 + 마지막 이미지를 지워줌
                fs.open(repFileTemp,FileMode.UPDATE);
                fs.position = imgStartByte;
                fs.truncate();
                fs.close();
                repFileTemp.moveTo(replayDataFilePath,true);
            }

            if(repFileTemp.exists)
            {
                repFileTemp.deleteFile();
            }

            replayData.clear();
            replayData = null;
            rReplayImageCacheState = REPLAY_IMAGE_CAHCHE_READY;
            finalizeLoadFile(imgW,imgH,finalIMGBMPD,finalIMGBMPD1,false,bg);
        }

        public function loadImageFile(width:Number,height:Number,layer1Image:IBitmapDrawable,layer2Image:IBitmapDrawable):void
        {
            updateTotalFrameAndReplayMaxSpeedFor10Sec(0);
            undoManager.setRFileTotalFrame(0);
            rReplayImageCacheState = REPLAY_IMAGE_CAHCHE_COMPLETE;
            refLayerRawBitmapData = null;
            refLayerRawTransformData = null;
            finalizeLoadFile(width,height,layer1Image,layer2Image,true,0xFFFFFF);
            initializeReplayDataFile(true); //일단 썸네일 이미지랑 리플레이 데이터 청소
        }

        public function finalizeLoadFile(width:uint,height:uint,imageData:IBitmapDrawable,imageData1:IBitmapDrawable,imageOnlyFlag:Boolean,newBG:uint):void
        {
            if(!imageData)
            {
                showLoadFaildMouseHint();
                return;
            }

            var maxLength:Number = (width > height) ? width : height;
            var scaleFix:Number = (maxLength > CANVAS_MAX_SIZE) ? CANVAS_MAX_SIZE/maxLength : 1.0;
            const scaledwidth:Number = Math.floor(width*scaleFix);
            const scaledheight:Number= Math.floor(height*scaleFix); //CANVAS_MAX_SIZE 값을 넘으면 리사이즈 해줌
            var scaleMat:Matrix = new Matrix();
            scaleMat.scale(scaleFix,scaleFix);
            var tmpbmpd:BitmapData = new BitmapData(scaledwidth,scaledheight,true,0);

            if(isCaptureModeON)
            {
                handleExitCaptureMode();
            }

            resetReplaySpeedBar();
            resetReplayTime();
            clearCanvasReplayMode();
            updateReplayPrograssText(true,0);
            resetReplayPrograssBarWidth();

            updateCanvasBGColorDrawMode(newBG);
            updateCanvasBGColorReplayMode(newBG);
            if(isCanvasWindowON)
            {
                updateCanvasWindowBGColor(CANVAS_BG_COLOR,canvasWindowLayer1Bitmap.bitmapData);
            }

            // updateLastFilePathByRandomFileName();
            isContinueSaveON = false;//연속 세이브 플래그 취소
            rMirrorON = false;
            isCanvasMirrored = false;
            mirrorCommandReady = false;
            canvasInfoBox.setMirror(false);
            updateGridMirror(false);

            if(isLassoToolStarted === true)
            {
                cancelLassoTool();
                resetLassoBox();
            }

            if(isFillPenStarted) 
            {
                fillPenTool.cancel();
            }

            tmpbmpd.draw(imageData,scaleMat,null,null,null,true);
            canvasLayer1BitmapData = updateBitmapData(canvasLayer1BitmapData,tmpbmpd,canvasLayer1Bitmap);

            if(imageOnlyFlag)
            {
                if(rFirstImageLayer1BitmapData && tmpbmpd !== rFirstImageLayer1BitmapData) rFirstImageLayer1BitmapData.dispose();
                rFirstImageLayer1BitmapData = tmpbmpd.clone(); //이미지만 불러와주면 첫 이미지를 갱신해줌
            }

            if(imageData1 !== null)
            {
                tmpbmpd.fillRect(new Rectangle(0,0,scaledwidth,scaledheight),0);
                tmpbmpd.draw(imageData1,scaleMat,null,null,null,true);
                canvasLayer2BitmapData = updateBitmapData(canvasLayer2BitmapData,tmpbmpd,canvasLayer2Bitmap);

                if(imageOnlyFlag)
                {
                    rFirstImageLayer2BitmapData = tmpbmpd.clone();
                }
            }
            else
            {
                canvasLayer2BitmapData = new BitmapData(canvasLayer1BitmapData.width,canvasLayer1BitmapData.height,true,0);
                canvasLayer2Bitmap.bitmapData = canvasLayer2BitmapData;
            }

            tmpbmpd.dispose();
            tmpbmpd = null;

            canvasAnchorPoint.rotation = 0;
            setRcursorRotation(0);
            canvasZoomIndex = 3;
            updateCanvasScale(1.0);
            updateCavnvasSizeDrawMode(scaledwidth,scaledheight,0,0,false);
            syncReplayCanvasImageWithDrawMode();
            syncReplayCanvasWithDrawMode();
            centerCanvas();

            updatePenSizeCursor();

            if(gridGapValue > 0)
            {
                drawGrid();
            }
            //bitmapdata가 갱신된이후에 업데이트 해줘야함
            resetUndoState();
            drawReplayByCommand.resetFirstRCursorPos();

            if(refLayerRawTransformData === null)
            {
                clearRefLayerImage();
            }
            else
            {
                canvasRefLayerBitmapData = refLayerRawBitmapData.clone();
                canvasRefLayerBitmap.bitmapData = canvasRefLayerBitmapData;

                updateRefLayerImageTransform(refLayerRawTransformData[4],
                                            refLayerRawTransformData[5],
                                            refLayerRawTransformData[6],
                                            refLayerRawTransformData[7],
                                            refLayerRawTransformData[8]);
                refLayerMenuDragXMoveSum = refLayerRawTransformData[10];
                refLayerLastAlpha = refLayerRawTransformData[11];
                canvasRefLayer.visible = true;
                canvasRefLayer.alpha = normalizeAlphaValue(refLayerRawTransformData[11]);
                updateRefLayerOpacityCursorPosByValue(refLayerRawTransformData[11]);
                refLayerRawBitmapData.dispose();
                refLayerRawBitmapData = null;
                refLayerRawTransformData = null;
                canvasRefLayerBitmap.smoothing = true;
            }

            updateWindowTitle();
            selectLayer1(false);
            selectReplaySubLayer(false);

            if(toolOptionsBox.layer1CheckedButton.visible)
            {
                toggleLayer1Check();
            }
            if(toolOptionsBox.layer2CheckedButton.visible)
            {
                toggleLayer2Check();
            }

            updateResizeButtonPos(CANVAS_WIDTH,CANVAS_HEIGHT);
            removeKeyRepeatEvents(null);

            canvasLayer1Bitmap.visible = true;
            canvasLayer2Bitmap.visible = true;
            topBar.captureButton.alpha = 1.0;
            topBar.newFileButton.alpha = 1.0;
            refLayerMenuBox.refTransferCanvasImageButton.alpha = 1.0;

            selectCurrentColor(false);
            ensureDrawingToolSelected(false);
            canvasNavigatorBox.updateImage(canvasLayer1BitmapData,canvasLayer2BitmapData,CANVAS_BG_COLOR);
            updateCanvasNaigatorCursor();

            if(isCanvasWindowON)
            {
                updateCanvasWindowImage();
                canvasWindowIgnoreResizeEventFlag = true;
                updateCanvasWindowBitmapSize();
            }

            resetCaptureCanvasChangeValue();

            lastLoadedFile = null;
            isLoadPendingAfterSaving = false;
            closeLoadMenuBox();
        }

        public function openLoadFileBrowser(toRefLayer:Boolean=false):void
        {
            if(isReplayStarted)
            {
                stopReplay();
            }
            if(isLassoToolStarted || isFileBrowserOpened || isFillPenStarted || isSaveInProgress)
            {
                return;
            }

            var windowTitle:String = "Open file";
            if(toRefLayer === true)
            {
                windowTitle = "Open reference layer image";
            }

            const loadPath:String = getDirectoryOnly(getExistingParentDirectory(lastSaveFilePath));
            const file:File = (lastSaveFilePath === lastSaveFileName) ? new File() : new File(loadPath);

            function cleanUpEvents():void
            {
                file.removeEventListener(Event.SELECT,onFileSelected);
                file.removeEventListener(Event.COMPLETE,onFileSelectComplete);
                file.removeEventListener(Event.CANCEL,onFileSelectCancel);
            }

            function onFileSelectCancel(e:Event):void
            {
                setFileBrowserIsOpen(false);
                cleanUpEvents();
                addInputEventsDrawModeOrReplayMode();
            }

            function onFileSelected(e:Event):void
            {
                setFileBrowserIsOpen(false);
                file.removeEventListener(Event.SELECT,onFileSelected);
                file.load();
            }

            function onFileSelectComplete(e:Event):void
            {
                cleanUpEvents();
                setFileBrowserIsOpen(false);
                addInputEventsDrawModeOrReplayMode();
                prepareLoadMenuBoxFromImageFile(file,toRefLayer);
            }

            setFileBrowserIsOpen(true);
            showCanvasResizeButtonVisibleDelay(false);
            removeInputEventsReplayMode();
            removeInputEventsDrawMode();

            file.browseForOpen(windowTitle,[new FileFilter("All supported formats","*.2020;*.png;*.jpg;*.jpeg;*.jfif;*.gif;*.webp")]);
            file.addEventListener(Event.SELECT,onFileSelected);
			file.addEventListener(Event.COMPLETE,onFileSelectComplete);
            file.addEventListener(Event.CANCEL,onFileSelectCancel);
        }

        public function activateCaptureUI():void
        {
            const replayMode:Boolean = isReplayModeON;

            captureAreaManager.reset();
            updateCanvasResizeButtonVisible(false);
            removeTimer("rCursorOffAlphaAnimTimer");

            if (replayMode)
            {
                hideReplayDeleteRangeBar();
                replayTimelineBox.visible = false;
                removeInputEventsReplayMode();
            }
            else
            {
                canvasGrid.visible = false;
                removeInputEventsDrawMode();
            }

            if (isSidebarVisible)
            {
                hideSidebarTemporary();
            }

            isPenSizeCursorInvisible = true;
            penSizePreviewCursor.visible = false;
            canvasRefLayer.visible = false;

            if (isRefLayerMenuON)
            {
                refLayerMenuBox.visible = false;
            }

            updateTopBarModeIcons("capture");
            rReplayFOFOCursor.visible = false;

            if (mouseHint.isShowing())
            {
                hideMouseHint();
            }

            addInputEventsCaptrueMode();
            updateStageOffset();
        }
        
        public function deactivateCaptureUI():void
        {
            const replayMode:Boolean = isReplayModeON;

            removeInputEventCaptrueMode();
            canvasRefLayer.visible = true;

            if (replayMode)
            {
                updateTopBarModeIcons("replay");
                addInputEventsReplayMode();
                replayTimelineBox.visible = true;
            }
            else
            {
                if (isSidebarVisible)
                {
                    showSidebarPermanent();
                }

                if (isRefLayerMenuON)
                {
                    refLayerMenuBox.visible = true;
                }

                isPenSizeCursorInvisible = false;
                updateTopBarModeIcons("draw");
                addInputEventsDrawMode();
            }

            switchColorPickerModePen();
            updateStageOffset();
        }

        public function onRightMouseDownCaptureMode(e:MouseEvent):void
        {
            if(topBar.hitTestPoint(stage.mouseX,stage.mouseY) === false)
            {
                if(!captureAreaManager.isFullImageCapture())
                {
                    captureAreaManager.resetCaptureArea();
                }
            }
        }

        public function onMouseDownCaptureMode(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;

            if(!target)
            {
                return;
            }

            const targetName:String = target.name;

            if(targetName === "capLayer1VisibleButton" || targetName === "capLayer2VisibleButton"
            || targetName === "capStamp" || targetName === "capStampFont")
            {
                handleMouseClick(targetName);

                return;
            }

            if(targetName === "capClipBoard")
            {
                executeCaptureFlashEffect();
                if(target.alpha < 1.0 && topBar.hitTestPoint(stage.mouseX,stage.mouseY))
                {
                    return;
                }
                handleMouseClick(targetName);
            }

            if(target.alpha < 1.0 && topBar.hitTestPoint(stage.mouseX,stage.mouseY))
            {
                return;
            }

            if(captureStampFontListBox.visible)
            {
                if(targetName === "capFontListNext" || targetName === "capFontListPrev")
                {
                    handleMouseClick(targetName);
                }
                else if(targetName && targetName.indexOf(captureStampFontListBox.getStampFontButtonName()) !== -1)
                {
                    captureStampManager.changeFont(captureStampFontListBox.getFontName(targetName),true);
                }
                else if(target.parent)
                {
                    if(target.parent.name && target.parent.name.indexOf(captureStampFontListBox.getStampFontButtonName()) !== -1)
                    {
                        captureStampManager.changeFont(captureStampFontListBox.getFontName(target.parent.name),true);
                    }
                }

                return;
            }

            switch(targetName)
            {
                case "capRotate":
                case "capFlip":
                case "capSave":
                case "capOff":
                case "capTrans":
                {
                    handleMouseClick(targetName);
                }
                break;

                case "timer":
                {
                    startPressHoldKey(topBar.timer,"Resetting the timer...",null, realWorkingTimer.reset,null);
                }
                break;

                default:
                {
                    if(!isMouseClickBlocked)
                    {
                        captureAreaManager.start();
                    }
                }
                break;
            }
        }

        public function onKeyUpCaptureMode(e:KeyboardEvent):void
        {
            updateLastKey(getLastKey());
            checkKeyUp(e.keyCode);
        }

        public function onKeyDownCaptureMode(e:KeyboardEvent):void
        {
            const firstKey:uint = getFirstPressedKey();

            if(captureStampFontListBox.visible)
            {
                if(firstKey === KEY.esc)
                {
                    hideStampFontList();
                }
                return;
            }

            if(firstKey === KEY.esc)
            {
                if(stage.focus === topBar.captureInput)
                {
                    stage.focus = null;
                    return;
                }
            }

            if(stage.focus === topBar.captureInput || isMouseClicked || isRightMouseClicked)
            {
                return;
            }

            if(isPressingControl())
            {
                const secondKey:uint = getSecondPressedKey();
                if(isLastKey(secondKey))
                {
                    return;
                }
                updateLastKey(secondKey);
                if(secondKey === KEY.s || secondKey === KEY.semicolon)
                {
                    saveCaptureImage();
                }
                else if(secondKey === KEY.c || secondKey === KEY.comma)
                {
                    executeCaptureFlashEffect();
                    if(topBar.capClipBoard.alpha === 1.0)
                    {
                        copyCaptureImageToCilpBoard();
                    }
                }
                else if(secondKey === KEY.v || secondKey === KEY.m)
                {
                    if(isClipBoardButtonActivated)
                    {
                        tryLoadClipboardImage(false);
                    }
                }
                return;
            }

            if(isLastKey(firstKey))
            {
                return;
            }
            updateLastKey(firstKey);

            switch(firstKey)
            {
                case KEY.esc:
                case KEY.backspace:
                case KEY.f1:
                case KEY.f7:
                    handleExitCaptureMode();
                break;

                default:
                break;
            }
        }

        public function enterCaptureMode():void
        {
            if(rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_PROCESSING || isCaptureModeON)
            {
                return;
            }

            if(isReplayStarted)
            {
                stopReplay();
            }

            isCaptureModeON = true;
            isPenSizeCursorInvisible = true;

            if(numPadBox.visible)
            {
                closeNumpad();
            }

            if(!isSidebarVisible && sideBar.visible)
            {
                startHidingSidebarTemporary();
            }

            activateCaptureUI();
            hideBottomHint();

            var xAnc:Sprite;
            var xPanel:Sprite;
            var xZoomed:Number;
            var layer1:Boolean;
            var layer2:Boolean;

            if(isReplayModeON)
            {
                xAnc = rCanvasAnchorPoint;
                xPanel = rCanvasPanel;
                xZoomed = rCanvasZoomMultiplier;
                rReplayFOFOCursor.visible = false;
                rCanvasPanel.addChild(captureDragAreaOverlay);
                layer1 = true;
                layer2 = true;
            }
            else
            {
                xAnc = canvasAnchorPoint;
                xPanel = canvasPanel;
                xZoomed = canvasZoomMultipler;
                canvasPanel.addChild(captureDragAreaOverlay);
                if(canvasLayer1Bitmap.visible) layer1 = true;
                if(canvasLayer2Bitmap.visible) layer2 = true;
            }

            setAsTopChild(captureDragAreaOverlay);

            drawModeCanvasStateForSaveAppState = {
                                    "z" : canvasZoomMultipler,
                                    "x" : Math.floor(canvasAnchorPoint.x), //뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
                                    "y" : Math.floor(canvasAnchorPoint.y),
                                    "r" : canvasAnchorPoint.rotation,
                                    "px" : Math.floor(canvasPanel.x),
                                    "py" : Math.floor(canvasPanel.y)
            };

            canvasStateBeforeCaptureMode = {
                                    "z" : xZoomed,
                                    "x" : Math.floor(xAnc.x), //뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
                                    "y" : Math.floor(xAnc.y),
                                    "r" : xAnc.rotation,
                                    "px" : Math.floor(xPanel.x),
                                    "py" : Math.floor(xPanel.y),
                                    "layer1" : layer1,
                                    "layer2" : layer2
            };

            lastBottomHintTarget = null;
            topBar.capClipBoard.alpha = 1.0;
            captureCanvasRotationStep = 0;
            isCaptureCanvasFlipped = false;
            fitCanvasToViewportMargin(true); 
            applyTransparentCanvasBGCaptureMode(false);
            captureStampManager.init();
            if(isCaptureStampEnabled)
            {
                captureStampManager.update();
            }
        }

        public function resetCaptureCanvasChangeValue():void
        {
            captureCanvasRotationStep = 0;
            isCaptureCanvasFlipped = false;
            isCaptureTransparentBGShowing = false;
        }

        public function exitCaptureMode():void
        {   
            const replayMode:Boolean = isReplayModeON;
            const data:Object = canvasStateBeforeCaptureMode;
            const xBitmap1:Bitmap = (replayMode) ? rCanvasLayer1Bitmap : canvasLayer1Bitmap;
            const xBitmap11:Bitmap = (replayMode) ? rCanvasLayer2Bitmap : canvasLayer2Bitmap;
            const xAnc:Sprite = (replayMode) ? rCanvasAnchorPoint : canvasAnchorPoint;
            const xPanel:Sprite = (replayMode) ? rCanvasPanel : canvasPanel;
            
            xBitmap1.smoothing = false;
            xBitmap11.smoothing = false;

            isCaptureModeON = false;
            isPenSizeCursorInvisible = false;
            captureDragAreaOverlay.graphics.clear();
            captureStampManager.off();
            captureStampFontListBox.visible = false;

            //캔버스 이전 모양 위치로 복원
            xAnc.rotation = data.r;
            xAnc.x = data.x+captureWindowMove.x;
            xAnc.y = data.y+captureWindowMove.y;
            xPanel.x = data.px;
            xPanel.y = data.py;

            if(replayMode)
            {
                rCanvasLayer1Bitmap.visible = true;
                rCanvasLayer2Bitmap.visible = true;
                rCanvasDrawLayer.visible = true;
            }
            else
            {
                canvasLayer1Bitmap.visible = data.layer1;
                canvasLayer2Bitmap.visible = data.layer2;
            }

            if(!isReplayCanvasFitToWindow) 
            {
                updateCanvasScale(data.z,replayMode);
            }

            lastBottomHintTarget = null;
            hideMouseHint();
            captureWindowMove.setTo(0,0);

            updatePenSizeCursor();

            //prev box 사각형 업데이트가 있기 때문에 xAnc위치가 갱신된 다음에 해주어야함
            deactivateCaptureUI();
            hideBottomHint();

            if(replayMode)
            {
                restoreCanvasBackgroundColor(true);
                rReplayFOFOCursor.visible = true;
            }
            else if(!replayMode)
            {
                restoreCanvasBackgroundColor(false);
            }

            keepCnvasPanelInStage(replayMode);
            canvasStateBeforeCaptureMode = {};
        }

        public function cDrawCaptureStamp():Object
        {
            var captrueStampBMPD:BitmapData = new BitmapData(1,1,false,0);
            var captureStampBitmap:Bitmap = new Bitmap(captrueStampBMPD);
            const stampAlpha:uint = 0xCB000000;
            const textformat:TextFormat = new TextFormat();
            const captureStampRect:Rectangle = new Rectangle();
            const bmpdMat:Matrix = new Matrix();
            const defaultFontSize:int = 13;
            var defaultBmpdHeight:int = defaultFontSize+2;
            var inputUpdateTimer:int = 0;
            var stampBGColor:* = null;
            const lastRectArea:Rectangle = new Rectangle();
            var lastBitmapVisibleFlag:int = 0;

            captureStampBitmap.name = "captureStampBitmap";
            captureStampBitmap.visible = false;

            function updateLastRectArea(rect:Rectangle):void
            {
                lastRectArea.x = rect.x;
                lastRectArea.y = rect.y;
                lastRectArea.width = rect.width;
                lastRectArea.height = rect.height;
            }

            function getFontName():String
            {
                return textformat.font;
            }

            function checkCaptrueStampBMPDHeight(twolineFlag:Boolean,mainTextWidth:Number):Number
            {
                var maxHeight:Number = kungDateStr(twolineFlag,true);
                const lines1:int = topBar.getCaptureInputFinalLines();
                if(lines1 === 2) return maxHeight;

                const height2:Number = kungMainStr(twolineFlag,mainTextWidth,true);
                const lines2:int = topBar.getCaptureInputFinalLines();
                if(lines2 === 2) return height2;
                else if(maxHeight < height2) maxHeight = height2;

                return maxHeight;
            }

            function changeFont(newFont:String,updateFlag:Boolean):void
            {
                textformat.font = newFont;
                captureStampFontListBox.setSelectFont(newFont);
                captureStampFontListBox.updateFontListSelect(newFont);
                topBar.captureInputFinal.setTextFormat(textformat);
                if(updateFlag)
                {
                    update();
                }
            }

            function getCaptureStampDate(newLine:Boolean):String
            {
                const date:Date = new Date();
                const y:Number = date.getFullYear();
                const m:Number = date.getMonth()+1;
                const d:Number = date.getDate();
                const hour:Number = date.getHours();
                const min:Number = date.getMinutes();
                const sec:Number = date.getSeconds();
                const monthstr:String = (m < 10) ? "0"+m : ""+m;
                const daystr:String = (d < 10) ? "0"+d : ""+d;
                const hourstr:String = (hour < 10) ? "0"+hour : ""+hour;
                const minstr:String = (min < 10) ? "0"+min : ""+min;
                const secstr:String = (sec < 10) ? "0"+sec : ""+sec;

                // return y+"-"+monthstr+"-"+daystr+" "+hourstr+":"+minstr+":"+secstr;
                return y+"-"+monthstr+"-"+daystr
                        + ((newLine)?"\n":" ")
                        + hourstr+":"+minstr+":"+secstr;
            }

            function getAppNameString(newLine:Boolean):String
            {
                return "FOFO PAINT"
                        +((newLine)?"\n":" ")
                        +APP_VERSION.toFixed(2);
            }

            function getTextWidthText(text:String,offset:Number):Number
            {
                const backupStr:String = topBar.captureInputFinal.text;
                const backupWidth:Number = topBar.getCaptureInputFinalWidth();
                topBar.setCaptureInputFinalWidth(CANVAS_MAX_SIZE);
                topBar.setCaptureInputFinalString(text);
                const width:Number = topBar.captureInputFinal.textWidth+offset;
                topBar.setCaptureInputFinalString(backupStr);
                topBar.setCaptureInputFinalWidth(backupWidth);

                return width;
            }

            function getTextWidthAppName(newLine:Boolean):Number
            {
                return getTextWidthText(getAppNameString(newLine),5);
            }

            function getTextWidthDate(newLine:Boolean):Number
            {
                return getTextWidthText(getCaptureStampDate(newLine),10);
            }

            function getTextWidthMain():Number
            {
                return getTextWidthText(topBar.getCaptureInputString(),2);
            }

            function kungStamp(textStr:String,textWidth:Number,align:String,posX:Number,offsetX:Number,testHeightFlag:Boolean):Number
            {
                textformat.align = align;
                topBar.captureInputFinal.defaultTextFormat = textformat;
                topBar.setCaptureInputFinalWidth(textWidth);
                topBar.setCaptureInputFinalString(textStr);

                if(testHeightFlag)
                {
                    return topBar.captureInputFinal.textHeight;
                }

                bmpdMat.identity();
                bmpdMat.translate(posX+offsetX,0);
                captrueStampBMPD.draw(topBar.captureInputFinal,bmpdMat);
                return 0;
            }

            function kungAppnameStr(newLine:Boolean,testHeightFlag:Boolean):Number
            {
                const textWidth:Number = getTextWidthAppName(newLine);
                return kungStamp(getAppNameString(newLine),textWidth,"right",captrueStampBMPD.width-textWidth,2,testHeightFlag);
            }

            function kungMainStr(newLine:Boolean,textWidth:Number,testHeightFlag:Boolean):Number
            {
                return kungStamp(topBar.getCaptureInputString(),textWidth,"left",getTextWidthDate(newLine),0,testHeightFlag);
            }

            function kungDateStr(newLine:Boolean,testHeightFlag:Boolean):Number
            {
                return kungStamp(getCaptureStampDate(newLine),getTextWidthDate(newLine),"left",2,0,testHeightFlag);
            }

            function kungFinal(inputBMPD:BitmapData):void
            {
                update(); //미자막 시간 찍어줘야함
                const mat:Matrix = new Matrix();
                const ct:ColorTransform = new ColorTransform();

                mat.translate(0,inputBMPD.height-captrueStampBMPD.height);
                inputBMPD.draw(captureStampBitmap,mat,ct);
            }

            function getImageDominantColor(bitmapData:BitmapData, k:int = 3, maxIter:int = 10):uint
            {
                var pixels:Vector.<uint> = bitmapData.getVector(bitmapData.rect);
                var totalPixels:int = pixels.length;

                // 초기 클러스터 중심을 무작위 픽셀에서 선택
                var centers:Array = [];
                for (var i:int = 0; i < k; i++)
                {
                    var randPixel:uint = pixels[int(Math.random() * totalPixels)];
                    centers.push([
                        (randPixel >> 16) & 0xFF,
                        (randPixel >> 8) & 0xFF,
                        randPixel & 0xFF
                    ]);
                }

                var assignments:Vector.<int> = new Vector.<int>(totalPixels, true);

                // 반복 학습
                for (var iter:int = 0; iter < maxIter; iter++)
                {
                    // 1. 각 픽셀을 가장 가까운 클러스터에 할당
                    for (var p:int = 0; p < totalPixels; p++)
                    {
                        var pixel:uint = pixels[p];
                        var r:int = (pixel >> 16) & 0xFF;
                        var g:int = (pixel >> 8) & 0xFF;
                        var b:int = pixel & 0xFF;

                        var bestCluster:int = 0;
                        var bestDist:Number = Number.MAX_VALUE;

                        for (var c:int = 0; c < k; c++)
                        {
                            var cr:int = centers[c][0];
                            var cg:int = centers[c][1];
                            var cb:int = centers[c][2];
                            var dist:Number = (r - cr) * (r - cr) + (g - cg) * (g - cg) + (b - cb) * (b - cb);

                            if (dist < bestDist)
                            {
                                bestDist = dist;
                                bestCluster = c;
                            }
                        }
                        assignments[p] = bestCluster;
                    }

                    // 2. 클러스터 중심 재계산
                    var sum:Array = [];
                    var count:Array = [];
                    for (c = 0; c < k; c++)
                    {
                        sum[c] = [0, 0, 0];
                        count[c] = 0;
                    }

                    for (p = 0; p < totalPixels; p++)
                    {
                        var cluster:int = assignments[p];
                        pixel = pixels[p];
                        sum[cluster][0] += (pixel >> 16) & 0xFF;
                        sum[cluster][1] += (pixel >> 8) & 0xFF;
                        sum[cluster][2] += pixel & 0xFF;
                        count[cluster]++;
                    }

                    for (c = 0; c < k; c++)
                    {
                        if (count[c] > 0)
                        {
                            centers[c][0] = sum[c][0] / count[c];
                            centers[c][1] = sum[c][1] / count[c];
                            centers[c][2] = sum[c][2] / count[c];
                        }
                    }
                }

                // 가장 큰 클러스터 찾기
                var maxCluster:int = 0;
                var maxCount:int = 0;
                for (c = 0; c < k; c++)
                {
                    if (count[c] > maxCount)
                    {
                        maxCount = count[c];
                        maxCluster = c;
                    }
                }

                var rFinal:int = centers[maxCluster][0];
                var gFinal:int = centers[maxCluster][1];
                var bFinal:int = centers[maxCluster][2];

                return (rFinal << 16) | (gFinal << 8) | bFinal;
            }

            // function getImageAverageColor(bitmapData:BitmapData):uint
            // {
            //     var pixels:Vector.<uint> = bitmapData.getVector(bitmapData.rect);
            //     var totalPixels:int = pixels.length;

            //     var sumR:uint = 0;
            //     var sumG:uint = 0;
            //     var sumB:uint = 0;

            //     for each (var pixel:uint in pixels) {
            //         sumR += (pixel >> 16) & 0xFF;
            //         sumG += (pixel >> 8) & 0xFF;
            //         sumB += pixel & 0xFF;
            //     }

            //     var avgR:int = sumR / totalPixels;
            //     var avgG:int = sumG / totalPixels;
            //     var avgB:int = sumB / totalPixels;

            //     return (avgR << 16) | (avgG << 8) | avgB;
            // }

            function getCaptureAreaBmpd(clipRect:Rectangle,layer1:Boolean,layer2:Boolean):BitmapData
            {
                var longEdge:Number;
                var areaWidth:Number;
                var areaHeight:Number;
                const fullImageFlag:Boolean = clipRect.width === 0 && clipRect.height === 0;

                if(fullImageFlag)
                {
                    longEdge = CANVAS_HEIGHT > CANVAS_WIDTH ? CANVAS_HEIGHT : CANVAS_WIDTH;
                    areaWidth = CANVAS_WIDTH;
                    areaHeight = CANVAS_HEIGHT;
                }
                else
                {
                    longEdge = clipRect.height > clipRect.width ? clipRect.height : clipRect.width;
                    areaWidth = clipRect.width;
                    areaHeight = clipRect.height;
                }

                if(areaWidth === 0 || areaHeight === 0)
                {
                    return null;
                }

                var scale:Number = 1.0;
                if(longEdge > 100)
                {
                    scale = 100/longEdge;
                }
                const width:Number = areaWidth*scale;
                const height:Number = areaHeight*scale;
                const mat:Matrix = new Matrix();
                mat.scale(scale,scale);
                const tmpbmpd:BitmapData = new BitmapData(width,height,true,0);
                const rawbmpd:BitmapData = getMergedBitmapdtata(false,layer1,layer2,(fullImageFlag) ? null:clipRect);
                tmpbmpd.draw(rawbmpd,mat);

                return tmpbmpd;
            }

            function onFocusOutCaptureInput(e:FocusEvent):void
            {
                addTimer(0.2,false,function():void
                {
                    tryDisableIME();
                    isCaptureStampTextFieldFocused = false;
                });
            }

            function onFocusInCaptureInput(e:FocusEvent):void
            {
                isCaptureStampTextFieldFocused = true;
                addTimer(0.0,false,function():void
                {
                    topBar.captureInput.setSelection(0,topBar.captureInput.text.length);
                });
            }

            function onChangeCaptureInput(e:Event):void
            {
                topBar.capClipBoard.alpha = 1.0;

                if(!hasTimer("inputUpdateTimer"))
                {
                    addTimerByName("inputUpdateTimer",0.2,false,update);
                }
            }

            function setVisible(flag:Boolean):void
            {
                if(captureStampBitmap.visible !== flag)
                {
                    captureStampBitmap.visible = flag;
                }
            }

            function checkPosition(bmpdHeight:Number):void
            {
                const rect:Rectangle = captureAreaManager.getCaptureArea();
                const rotateFlag:uint = captureCanvasRotationStep;
                var offsetX:Number;
                var offsetY:Number;

                if(captureAreaManager.isFullImageCapture())
                {
                    offsetX = (isReplayModeON) ? RCANVAS_WIDTH:CANVAS_WIDTH;
                    offsetY = (isReplayModeON) ? RCANVAS_HEIGHT:CANVAS_HEIGHT;
                }
                else
                {
                    offsetX = rect.width;
                    offsetY = rect.height;
                }

                if(isCaptureCanvasFlipped)
                {
                    captureStampBitmap.scaleX = -1.0;
                    if(rotateFlag === 0)
                    {
                        captureStampBitmap.rotation = 0;
                        captureStampBitmap.x = rect.x+offsetX;
                        captureStampBitmap.y = rect.y+offsetY-bmpdHeight;
                    }
                    else if(rotateFlag === 1)
                    {
                        captureStampBitmap.rotation = 90;
                        captureStampBitmap.x = rect.x+bmpdHeight;
                        captureStampBitmap.y = rect.y+offsetY;
                    }
                    else if(rotateFlag === 2)
                    {
                        captureStampBitmap.rotation = 180;
                        captureStampBitmap.x = rect.x;
                        captureStampBitmap.y = rect.y+bmpdHeight;
                    }
                    else if(rotateFlag === 3)
                    {
                        captureStampBitmap.rotation = -90;
                        captureStampBitmap.x = rect.x+offsetX-bmpdHeight;
                        captureStampBitmap.y = rect.y;
                    }
                }
                else
                {
                    captureStampBitmap.scaleX = 1.0;
                    if(rotateFlag === 0)
                    {
                        captureStampBitmap.rotation = 0;
                        captureStampBitmap.x = rect.x;
                        captureStampBitmap.y = rect.y+offsetY-bmpdHeight;
                    }
                    else if(rotateFlag === 1)
                    {
                        captureStampBitmap.rotation = -90;
                        captureStampBitmap.x = rect.x+offsetX-bmpdHeight;
                        captureStampBitmap.y = rect.y+offsetY;
                    }
                    else if(rotateFlag === 2)
                    {
                        captureStampBitmap.rotation = 180;
                        captureStampBitmap.x = rect.x+offsetX;
                        captureStampBitmap.y = rect.y+bmpdHeight;
                    }
                    else if(rotateFlag === 3)
                    {
                        captureStampBitmap.rotation = 90;
                        captureStampBitmap.x = rect.x+bmpdHeight;
                        captureStampBitmap.y = rect.y;
                    }
                }
            }

            // function checkPosition(bmpdHeight:Number):void
            // {
            //     const ROT_0:uint = 0;
            //     const ROT_90:uint = 1;
            //     const ROT_180:uint = 2;
            //     const ROT_270:uint = 3;
            //     const rect:Rectangle = captureAreaManager.getCaptureArea();
            //     const rotateFlag:uint = captureCanvasRotationStep;

            //     // 캡처 영역 크기 결정
            //     const offsetX:Number = captureAreaManager.isFullImageCapture()
            //         ? (isReplayModeON ? RCANVAS_WIDTH : CANVAS_WIDTH)
            //         : rect.width;
            //     const offsetY:Number = captureAreaManager.isFullImageCapture()
            //         ? (isReplayModeON ? RCANVAS_HEIGHT : CANVAS_HEIGHT)
            //         : rect.height;

            //     // 초기 설정
            //     var scaleX:Number = 1.0;
            //     var rotation:Number = 0.0;
            //     var posX:Number = rect.x;
            //     var posY:Number = rect.y;

            //     // 좌우 반전 처리
            //     if (isCaptureCanvasFlipped)
            //         scaleX = -1.0;

            //     // 회전 각도에 따라 위치 및 회전 계산
            //     switch (rotateFlag)
            //     {
            //         case ROT_0:
            //             rotation = 0;
            //             posX = rect.x + (isCaptureCanvasFlipped ? offsetX : 0);
            //             posY = rect.y + offsetY - bmpdHeight;
            //             break;

            //         case ROT_90:
            //             rotation = isCaptureCanvasFlipped ? 90 : -90;
            //             posX = rect.x + (isCaptureCanvasFlipped ? bmpdHeight : offsetX - bmpdHeight);
            //             posY = rect.y + offsetY;
            //             break;

            //         case ROT_180:
            //             rotation = 180;
            //             posX = rect.x + (isCaptureCanvasFlipped ? 0 : offsetX);
            //             posY = rect.y + bmpdHeight;
            //             break;

            //         case ROT_270:
            //             rotation = isCaptureCanvasFlipped ? -90 : 90;
            //             posX = rect.x + (isCaptureCanvasFlipped ? offsetX - bmpdHeight : bmpdHeight);
            //             posY = rect.y;
            //             break;
            //     }

            //     // 실제 적용
            //     captureStampBitmap.scaleX = scaleX;
            //     captureStampBitmap.rotation = rotation;
            //     captureStampBitmap.x = posX;
            //     captureStampBitmap.y = posY;
            // }

            function getCaptureAreaWidth(rect:Rectangle):Number
            {
                const notRotatedFlag:Boolean = captureCanvasRotationStep % 2 === 0;

                if(notRotatedFlag)
                {
                    if(captureAreaManager.isFullImageCapture())
                    {
                        return (isReplayModeON) ? RCANVAS_WIDTH:CANVAS_WIDTH;
                    }
                    else
                    {
                        return rect.width;
                    }
                }
                else
                {
                    if(captureAreaManager.isFullImageCapture())
                    {
                        return (isReplayModeON) ? RCANVAS_HEIGHT:CANVAS_HEIGHT;
                    }
                    else
                    {
                        return rect.height;
                    }
                }

                return 0;
            }

            function getColorBrightness(color:uint):Number
            {
                var red:int = (color >> 16) & 0xFF;
                var green:int = (color >> 8) & 0xFF;
                var blue:int = color & 0xFF;

                // 밝기 계산
                var brightness:Number = 0.299 * red + 0.587 * green + 0.114 * blue;

                return brightness;
            }

            function update():void
            {
                if(isCaptureStampEnabled)
                {
                    const rect:Rectangle = captureAreaManager.getCaptureArea();

                    const bmpdWidth:Number = getCaptureAreaWidth(rect);
                    if(bmpdWidth < 300)
                    {
                        if(captureStampBitmap.visible === true)
                        {
                            captureStampBitmap.visible = false;
                        }
                        return;
                    }
                    const layer1Visible:Boolean = (isReplayModeON) ? rCanvasLayer1Bitmap.visible : canvasLayer1Bitmap.visible;
                    const layer2Visible:Boolean = (isReplayModeON) ? rCanvasLayer2Bitmap.visible : canvasLayer2Bitmap.visible;
                    var bitmapVisibleFlag:int = 0;
                    if(layer1Visible)
                    {
                        bitmapVisibleFlag += 1;
                    }

                    if(layer2Visible)
                    {
                        bitmapVisibleFlag += 2;
                    }

                    const bmpd:BitmapData = getCaptureAreaBmpd(rect,layer1Visible,layer2Visible);
                    if(!bmpd)
                    {
                        return;
                    }

                    if(stampBGColor === null || !rect.equals(lastRectArea) || lastBitmapVisibleFlag !== bitmapVisibleFlag)
                    {
                        const tegakiBGColorIndex:int = myPaletteTegakiPreset.indexOf((isReplayModeON) ? RCANVAS_BG_COLOR:CANVAS_BG_COLOR);
                        if(tegakiBGColorIndex >= 0)
                        {
                            stampBGColor = myPaletteTegakiPreset[tegakiBGColorIndex-10];
                        }
                        else
                        {
                            stampBGColor = getImageDominantColor(bmpd);
                        }
                        updateLastRectArea(rect);
                    }

                    lastBitmapVisibleFlag = bitmapVisibleFlag;

                    var dateStrWidth:Number = getTextWidthDate(false);
                    var appStrWidth:Number = getTextWidthAppName(false);
                    var mainTextWidth:Number = bmpdWidth-(dateStrWidth+appStrWidth)-1;

                    textformat.size = defaultFontSize;
                    topBar.captureInput.maxChars = 0;
                    topBar.captureInputFinal.defaultTextFormat = textformat;
                    topBar.setCaptureInputFinalWidth(mainTextWidth);
                    topBar.setCaptureInputFinalString(topBar.getCaptureInputString());
                    
                    var twolineFlag:Boolean = false;

                    if(topBar.getCaptureInputFinalLines() >= 2)
                    {
                        twolineFlag = true;

                        var loopcount:int = 0;

                        do
                        {
                            textformat.size = defaultFontSize-loopcount;
                            topBar.captureInputFinal.defaultTextFormat = textformat;
                            dateStrWidth = getTextWidthDate(true);
                            appStrWidth = getTextWidthAppName(true);
                            mainTextWidth = bmpdWidth-(dateStrWidth+appStrWidth)-1;
                            topBar.setCaptureInputFinalWidth(mainTextWidth);
                            topBar.setCaptureInputFinalString(topBar.getCaptureInputString());
                            loopcount++;


                            if(defaultFontSize-loopcount <= 13)
                            {
                                //글씨크기를 한계까지 줄이고 칸이 꽉차면 더이상 입력 못하게함
                                if(topBar.captureInputFinal.numLines >= 3)
                                {
                                    topBar.captureInput.maxChars = 1;
                                    topBar.captureInput.text = topBar.captureInput.text.slice(0,-1);
                                }

                                break;
                            }
                        }
                        while(topBar.getCaptureInputFinalLines() >= 3);
                    }

                    if(captrueStampBMPD)
                    {
                        captrueStampBMPD.dispose();
                    }
                    var bmpdHeight:Number = checkCaptrueStampBMPDHeight(twolineFlag,mainTextWidth);
                    captrueStampBMPD = new BitmapData(bmpdWidth,bmpdHeight,true,stampAlpha|stampBGColor);
                    captureStampBitmap.bitmapData = captrueStampBMPD;

                    if(getColorBrightness(stampBGColor) >= 150)
                    {
                        topBar.captureInputFinal.textColor = 0x0;
                    }
                    else
                    {
                        topBar.captureInputFinal.textColor = 0xFFFFFF;
                    }

                    kungDateStr(twolineFlag,false);
                    kungMainStr(twolineFlag,mainTextWidth,false);
                    kungAppnameStr(twolineFlag,false);

                    if(captureStampBitmap.visible === false)
                    {
                        captureStampBitmap.visible = true;
                    }

                    if(isReplayModeON)
                    {
                        if(rCanvasPanel.getChildByName("captureStampBitmap") === null)
                        {
                            rCanvasPanel.addChild(captureStampBitmap);
                        }
                    }
                    else if(canvasPanel.getChildByName("captureStampBitmap") === null)
                    {
                        canvasPanel.addChild(captureStampBitmap);
                    }

                    checkPosition(bmpdHeight);
                }
                else if(captureStampBitmap.visible === true)
                {
                    if(isReplayModeON)
                    {
                        if(rCanvasPanel.getChildByName("captureStampBitmap") !== null)
                        {
                            rCanvasPanel.removeChild(captureStampBitmap);
                        }
                    }
                    else if(canvasPanel.getChildByName("captureStampBitmap") !== null)
                    {
                        canvasPanel.removeChild(captureStampBitmap);
                    }
                    captureStampBitmap.visible = false;
                }
            }

            function off():void
            {
                if(isReplayModeON)
                {
                    rCanvasPanel.scrollRect = new Rectangle(0,0,RCANVAS_WIDTH,RCANVAS_HEIGHT);
                }
                else
                {
                    canvasPanel.scrollRect = new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);
                }

                if(captrueStampBMPD)
                {
                    captrueStampBMPD.dispose();
                }

                captrueStampBMPD = null;

                topBar.captureInput.removeEventListener(Event.CHANGE,onChangeCaptureInput);
                topBar.captureInput.removeEventListener(FocusEvent.FOCUS_IN,onFocusInCaptureInput);
                topBar.captureInput.removeEventListener(FocusEvent.FOCUS_OUT,onFocusOutCaptureInput);

                captureStampBitmap.visible = false;
                if(canvasPanel.getChildByName("captureStampBitmap") !== null)
                {
                    canvasPanel.removeChild(captureStampBitmap);
                }
            }

            function init():void
            {
                if(isReplayModeON)
                {
                    rCanvasPanel.scrollRect = null;
                }
                else
                {
                    canvasPanel.scrollRect = null;
                }

                textformat.font = null;
                stampBGColor = null;

                topBar.captureInput.addEventListener(Event.CHANGE,onChangeCaptureInput);
                topBar.captureInput.addEventListener(FocusEvent.FOCUS_IN,onFocusInCaptureInput);
                topBar.captureInput.addEventListener(FocusEvent.FOCUS_OUT,onFocusOutCaptureInput);
            }

            return{
                init:init,
                off:off,
                update:update,
                setVisible:setVisible,
                kungFinal:kungFinal,
                changeFont:changeFont,
                getFontName:getFontName
            };

        }

        //마우스 클릭하면 캡쳐 영역그리는 함수
        public function cDrawCaptureArea():Object
        {
            var xPanel:Sprite;
            var mouseMoved:Boolean = false;
            var canvasWidth:Number = 0;
            var canvasHeight:Number = 0;
            var clickPos:Point = new Point(0,0);
            var limitWidthSave:Number = 0;
            var limitHeightSave:Number = 0;
            const rectFull:Rectangle = new Rectangle();
            const rectRaw:Rectangle = new Rectangle();
            const rectClamped:Rectangle = new Rectangle();
            var resizeFlag:Boolean = false;
            const resizeButtonSize:Number = 14.0;
            const resizeButtonPos:Point = new Point(0,0);
            var minSize:Number = 10.0;
            const mouseMoveOffset:Number = 5.0;

            function validateCaptureArea():void
            {
                var intersection:Rectangle = rectFull.intersection(rectClamped);

                if(intersection.width >= minSize && intersection.height >= minSize)
                {
                    rectClamped.x = Math.round(intersection.x);
                    rectClamped.y = Math.round(intersection.y);
                    rectClamped.width = Math.round(intersection.width);
                    rectClamped.height = Math.round(intersection.height);
                }
                else
                {
                    addTimer(0.0,false,function():void
                    {
                        resetCaptureArea();
                    });
                }
            }

            function normalizeRectClamped():void
            {
                if(rectClamped.width < 0)
                {
                    rectClamped.width = Math.abs(rectClamped.width);
                    rectClamped.x = rectClamped.x-rectClamped.width;
                }

                if(rectClamped.height < 0)
                {
                    rectClamped.height = Math.abs(rectClamped.height);
                    rectClamped.y = rectClamped.y-rectClamped.height;
                }
            }

            function onMouseMoveCaptureAreaDrawed(e:MouseEvent):void
            {
                if(!isCaptureModeON)
                {
                    removeCaptureAreaEvents();
                    return;
                }

                const mx:Number = xPanel.mouseX;
                const my:Number = xPanel.mouseY;
                var subX:Number = Math.round(mx-clickPos.x);
                var subY:Number = Math.round(my-clickPos.y);

                if(mouseMoved === true)
                {
                    if(resizeFlag)
                    {
                        if(!isCaptureCanvasFlipped && captureCanvasRotationStep === 0
                        || isCaptureCanvasFlipped && captureCanvasRotationStep === 3)
                        {
                            rectRaw.width += subX;
                            rectRaw.height += subY;
                            rectClamped.width = rectRaw.width;
                            rectClamped.height = rectRaw.height;

                            if(rectClamped.width < minSize) rectClamped.width = minSize;
                            else if(rectClamped.x+rectClamped.width > canvasWidth) rectClamped.width = canvasWidth-rectClamped.x;

                            if(rectClamped.height < minSize) rectClamped.height = minSize;
                            else if(rectClamped.y+rectClamped.height > canvasHeight) rectClamped.height = canvasHeight-rectClamped.y;
                        }
                        else if(!isCaptureCanvasFlipped && captureCanvasRotationStep === 1
                        || isCaptureCanvasFlipped && captureCanvasRotationStep === 2)
                        {
                            rectRaw.width += subX;
                            rectRaw.height -= subY;
                            rectRaw.y += subY;
                            rectClamped.width = rectRaw.width;
                            rectClamped.height = rectRaw.height;
                            rectClamped.y = rectRaw.y;

                            if(rectClamped.y < 0.0)
                            {
                                rectClamped.y = 0.0;
                                rectClamped.height = limitHeightSave;
                            }
                            if(rectClamped.height < minSize)
                            {
                                rectClamped.height = minSize;
                                rectClamped.y = limitHeightSave-rectClamped.height;
                            }

                            if(rectClamped.width < minSize) rectClamped.width = minSize;
                            else if(rectClamped.x+rectClamped.width > canvasWidth) rectClamped.width = canvasWidth-rectClamped.x;
                        }
                        else if(!isCaptureCanvasFlipped && captureCanvasRotationStep === 2
                        || isCaptureCanvasFlipped && captureCanvasRotationStep === 1)
                        {
                            rectRaw.width -= subX;
                            rectRaw.height -= subY;
                            rectRaw.x += subX;
                            rectRaw.y += subY;
                            rectClamped.width = rectRaw.width;
                            rectClamped.height = rectRaw.height;
                            rectClamped.x = rectRaw.x;
                            rectClamped.y = rectRaw.y;

                            if(rectClamped.width < minSize)
                            {
                                rectClamped.width = minSize;
                                rectClamped.x = limitWidthSave-rectClamped.width;
                            }

                            if(rectClamped.height < minSize)
                            {
                                rectClamped.height = minSize;
                                rectClamped.y = limitHeightSave-rectClamped.height;
                            }

                            if(rectClamped.x < 0.0)
                            {
                                rectClamped.x = 0.0;
                                rectClamped.width = limitWidthSave;
                            }

                            if(rectClamped.y < 0.0)
                            {
                                rectClamped.y = 0.0;
                                rectClamped.height = limitHeightSave;
                            }
                        }
                        else if(!isCaptureCanvasFlipped && captureCanvasRotationStep === 3
                        || isCaptureCanvasFlipped && captureCanvasRotationStep === 0)
                        {
                            rectRaw.width -= subX;
                            rectRaw.height += subY;
                            rectRaw.x += subX;

                            rectClamped.width = rectRaw.width;
                            rectClamped.height = rectRaw.height;
                            rectClamped.x = rectRaw.x;

                            if(rectClamped.x < 0.0)
                            {
                                rectClamped.x = 0.0;
                                rectClamped.width = limitWidthSave;
                            }

                            if(rectClamped.width < minSize)
                            {
                                rectClamped.width = minSize;
                                rectClamped.x = limitWidthSave-rectClamped.width;
                            }

                            if(rectClamped.height < minSize) 
                            {
                                rectClamped.height = minSize;
                            }
                            else if(rectClamped.y+rectClamped.height > canvasHeight) 
                            {
                                rectClamped.height = canvasHeight-rectClamped.y;
                            }
                        }

                        showBottomHint(getRotatedRectSizeString());
                    }
                    else
                    {
                        rectRaw.x += subX;
                        rectRaw.y += subY;
                        rectClamped.x = rectRaw.x;
                        rectClamped.y = rectRaw.y;

                        if(rectClamped.x < 0.0)
                        {
                            rectClamped.x = 0.0;
                        }
                        else if(rectClamped.x+rectClamped.width > canvasWidth)
                        {
                            rectClamped.x = canvasWidth-rectClamped.width;
                        }

                        if(rectClamped.y < 0.0)
                        {
                            rectClamped.y = 0.0;
                        }
                        else if(rectClamped.y+rectClamped.height > canvasHeight)
                        {
                            rectClamped.y = canvasHeight-rectClamped.height;
                        }
                    }

                    rectClamped.x = Math.round(rectClamped.x);
                    rectClamped.y = Math.round(rectClamped.y);
                    rectClamped.width = Math.round(rectClamped.width);
                    rectClamped.height = Math.round(rectClamped.height);

                    clickPos.setTo(xPanel.mouseX,xPanel.mouseY);
                    drawArea(false);
                }
                else if(Math.abs(subX) >= mouseMoveOffset || Math.abs(subY) >= mouseMoveOffset)
                {
                    mouseMoved = true;
                    clickPos.setTo(mx,my);
                    captureStampManager.setVisible(false);
                }
            }

            function onMouseMoveDrawCaptureArea(e:MouseEvent):void
            {
                if(!isCaptureModeON)
                {
                    removeCaptureAreaEvents();
                    return;
                }
                var mx:Number = xPanel.mouseX;
                var my:Number = xPanel.mouseY;
                var subX:Number = Math.round(mx-clickPos.x);
                var subY:Number = Math.round(my-clickPos.y);

                if(mouseMoved)
                {
                    rectRaw.width = subX;
                    rectRaw.height = subY;

                    rectClamped.x = rectRaw.x;
                    rectClamped.y = rectRaw.y;
                    rectClamped.width = rectRaw.width;
                    rectClamped.height = rectRaw.height;
                    normalizeRectClamped();
                    showBottomHint(getRotatedRectSizeString());
                    drawArea(false);
                }
                else if(Math.abs(subX) >= mouseMoveOffset || Math.abs(subY) >= mouseMoveOffset)
                {
                    rectRaw.x = clickPos.x;
                    rectRaw.y = clickPos.y;
                    rectRaw.width = subX;
                    rectRaw.height = subY;

                    rectClamped.x = rectRaw.x;
                    rectClamped.y = rectRaw.y;
                    rectClamped.width = rectRaw.width;
                    rectClamped.height = rectRaw.height;

                    clickPos.setTo(mx,my);
                    showBottomHint(getRotatedRectSizeString());
                    mouseMoved = true;
                    captureStampManager.setVisible(false);
                }
            }

            function onMouseUpCaptureArea(e:MouseEvent):void
            {
                isMouseDragging = false;
                removeCaptureAreaEvents();

                if(mouseMoved === true)
                {
                    //rect길이가 음수인경우 cx cy를 양수로 다시 맞추어줌
                    normalizeRectClamped();
                    validateCaptureArea();
                    topBar.capClipBoard.alpha = 1.0;
                    drawArea(true);
                    captureStampManager.update();
                }
                mouseMoved = false;
            }

            function removeCaptureAreaEvents():void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveDrawCaptureArea);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveCaptureAreaDrawed);
                stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUpCaptureArea);
            }

            function updateDrawArea(forceFlag:Boolean=false):void
            {
                if(rectClamped.width > minSize && rectClamped.height > minSize || forceFlag)
                {
                    drawArea(true);
                }
                captureStampManager.update();
            }

            function getCanvasScale():Number
            {
                return (isReplayModeON) ? Math.abs(rCanvasAnchorPoint.scaleX) : Math.abs(canvasAnchorPoint.scaleX);
            }

            function drawResizeButton(scale:Number):void
            {
                if(isFullImageCapture())
                {
                    return;
                }

                captureDragAreaOverlay.graphics.lineStyle(1,0xFFFFFF,1.0,true);
                captureDragAreaOverlay.graphics.beginFill(0xFF6600);
                var posX:Number = rectClamped.x;
                var posY:Number = rectClamped.y;
                // const offset:Number = 5/scale;
                const offset:Number = 0;

                if(!isCaptureCanvasFlipped && captureCanvasRotationStep === 0|| isCaptureCanvasFlipped && captureCanvasRotationStep === 3)
                {
                    posX += rectClamped.width+offset;
                    posY += rectClamped.height+offset;
                }
                else if(!isCaptureCanvasFlipped && captureCanvasRotationStep === 1 || isCaptureCanvasFlipped && captureCanvasRotationStep === 2)
                {
                    posX += rectClamped.width+offset;
                    posY += -offset;
                }
                else if(!isCaptureCanvasFlipped && captureCanvasRotationStep === 3 || isCaptureCanvasFlipped && captureCanvasRotationStep === 0)
                {
                    posY += rectClamped.height+offset;
                    posX += -offset;
                }
                else
                {
                    posX += -offset;
                    posY += -offset;
                }

                resizeButtonPos.setTo(posX,posY);

                const longEdge:Number = resizeButtonSize/scale;
                const shortEdge:Number = (resizeButtonSize/3)/scale;
                const cmd:Vector.<int> = new <int> [1,2,2,2,2,2,2];
                const pos:Vector.<Number> = new <Number> [0,0
                                                        ,0,-longEdge
                                                        ,shortEdge,-longEdge
                                                        ,shortEdge,shortEdge
                                                        ,-longEdge,shortEdge
                                                        ,-longEdge,0
                                                        ,0,0];
                const len:uint = pos.length;
                var p:Point;
                for(var i:uint=0;i<len;i+=2)
                {
                    p = rotatePoint(pos[i],pos[i+1],captureCanvasRotationStep*90.0);
                    pos[i] = posX+p.x*((isCaptureCanvasFlipped)?-1.0:1.0);
                    pos[i+1] = posY+p.y;
                }
                captureDragAreaOverlay.graphics.drawPath(cmd,pos);
                captureDragAreaOverlay.graphics.endFill();
            }

            function drawArea(resizeButtonON:Boolean):void
            {
                const zoomed:Number = getCanvasScale();

                const lineSize:Number = Math.ceil(1/zoomed);
                captureDragAreaOverlay.graphics.clear();
                //배경색 약간 어둡게 해줌
                captureDragAreaOverlay.graphics.lineStyle(0,0,0);
                captureDragAreaOverlay.graphics.beginFill(0,0.3);
                captureDragAreaOverlay.graphics.drawRect(0,0,canvasWidth,rectClamped.y) //위
                captureDragAreaOverlay.graphics.drawRect(0,rectClamped.y,rectClamped.x,rectClamped.height);//왼쪽
                captureDragAreaOverlay.graphics.drawRect(rectClamped.x+rectClamped.width,rectClamped.y,canvasWidth-(rectClamped.x+rectClamped.width),rectClamped.height); //오른쪽
                captureDragAreaOverlay.graphics.drawRect(0,rectClamped.y+rectClamped.height,canvasWidth,canvasHeight-(rectClamped.y+rectClamped.height)); //아래
                captureDragAreaOverlay.graphics.endFill();
                captureDragAreaOverlay.graphics.lineStyle(lineSize,0xFFFFFF,1.0,true);
                captureDragAreaOverlay.graphics.beginFill(0xFFFFFF,0.0)
                captureDragAreaOverlay.graphics.drawRect(rectClamped.x,rectClamped.y,rectClamped.width,rectClamped.height);

                if(resizeButtonON)
                {
                    drawResizeButton(zoomed);
                }
            }

            function getRotatedRectSizeString():String
            {
                const w:Number = Math.abs(rectClamped.width);
                const h:Number = Math.abs(rectClamped.height);

                if(rectClamped.x === 0.0 && rectClamped.y === 0.0 && rectClamped.width === 0.0 && rectClamped.height === 0.0)
                {
                    if(isReplayModeON)
                    {
                        return (captureCanvasRotationStep === 0 || captureCanvasRotationStep === 2) ? RCANVAS_WIDTH+" x "+RCANVAS_HEIGHT : RCANVAS_HEIGHT+" x "+RCANVAS_WIDTH;
                    }
                    else
                    {
                        return (captureCanvasRotationStep === 0 || captureCanvasRotationStep === 2) ? canvasWidth+" x "+canvasHeight : canvasHeight+" x "+canvasWidth;
                    }
                }

                if(w < minSize || h < minSize)
                {
                    return "";
                }

                return (captureCanvasRotationStep === 0 || captureCanvasRotationStep === 2) ? w+" x "+h : h+" x "+w;
            }

            function resetCaptureArea():void
            {
                resizeButtonPos.setTo(0,0);
                resizeFlag = false;
                clickPos.setTo(0,0);
                rectClamped.x = 0;
                rectClamped.y = 0;
                rectClamped.width = 0;
                rectClamped.height = 0;
                rectRaw.x = 0;
                rectRaw.y = 0;
                rectRaw.width = 0;
                rectRaw.height = 0;
                rectFull.x = 0;
                rectFull.y = 0;
                rectFull.width = 0;
                rectFull.height = 0;
                limitWidthSave = 0;
                limitHeightSave = 0;
                captureDragAreaOverlay.graphics.clear();
                topBar.capClipBoard.alpha = 1.0;
                captureStampManager.update();
            }

            function reset():void
            {
                resizeButtonPos.setTo(0,0);
                resizeFlag = false;
                clickPos.setTo(0,0);
                rectClamped.x = 0;
                rectClamped.y = 0;
                rectClamped.width = 0;
                rectClamped.height = 0;
                rectRaw.x = 0;
                rectRaw.y = 0;
                rectRaw.width = 0;
                rectRaw.height = 0;
                rectFull.x = 0;
                rectFull.y = 0;
                rectFull.width = 0;
                rectFull.height = 0;
                limitWidthSave = 0;
                limitHeightSave = 0;
                canvasWidth = 0;
                canvasHeight = 0;
                xPanel = null;
                mouseMoved = false;
                topBar.capClipBoard.alpha = 1.0;
            }

            function isFullImageCapture():Boolean
            {
                return rectClamped.width === 0.0 || rectClamped.height === 0.0;
            }

            function getCaptureArea():Rectangle
            {
                return rectClamped;
            }

            function isCursorInCaptureDrea():Boolean
            {
                if(!xPanel)
                {
                    return false;
                }

                return rectClamped.contains(xPanel.mouseX,xPanel.mouseY);
            }

            function isCursorInResizeButton():Boolean
            {
                if(!xPanel)
                {
                    return false;
                }

                const p1:Point = new Point(xPanel.mouseX,xPanel.mouseY);

                if(Point.distance(p1,resizeButtonPos)*getCanvasScale() < resizeButtonSize)
                {
                    return true;
                }

                return false;
            }

            function startUpdatingCaptureAreaPosSize(mx:Number,my:Number,flag:Boolean):void
            {
                isMouseDragging = true;
                resizeFlag = flag;
                rectRaw.x = rectClamped.x;
                rectRaw.y = rectClamped.y;
                rectRaw.width = rectClamped.width;
                rectRaw.height = rectClamped.height;
                limitWidthSave = rectClamped.x+rectClamped.width;
                limitHeightSave = rectClamped.y+rectClamped.height;

                clickPos.setTo(mx,my);
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveCaptureAreaDrawed);
                stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpCaptureArea);
            }

            function start():void
            {
                if(topBar.hitTestPoint(stage.mouseX,stage.mouseY) === false)
                {
                    if(isReplayModeON) //리플레이 변수로 변경
                    {
                        canvasWidth = RCANVAS_WIDTH;
                        canvasHeight = RCANVAS_HEIGHT;
                        xPanel = rCanvasPanel;
                    }
                    else
                    {
                        canvasWidth = CANVAS_WIDTH;
                        canvasHeight = CANVAS_HEIGHT;
                        xPanel = canvasPanel;
                    }

                    var mx:Number = xPanel.mouseX;
                    var my:Number = xPanel.mouseY;
                    rectFull.x = 0;
                    rectFull.y = 0;
                    rectFull.width = canvasWidth;
                    rectFull.height = canvasHeight;
                    resizeFlag = false;

                    if(isCursorInResizeButton())
                    {
                        startUpdatingCaptureAreaPosSize(mx,my,true);
                    }
                    else if(isCursorInCaptureDrea())
                    {
                        startUpdatingCaptureAreaPosSize(mx,my,false);
                    }
                    else
                    {
                        clickPos.setTo(mx,my);
                        isMouseDragging = true;
                        stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveDrawCaptureArea);
                        stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpCaptureArea);
                    }
                }
            };

            return {
                start:start,
                reset:reset,
                resetCaptureArea:resetCaptureArea,
                getCaptureArea:getCaptureArea,
                isFullImageCapture:isFullImageCapture,
                getRotatedRectSizeString:getRotatedRectSizeString,
                updateDrawArea:updateDrawArea,
                isCursorInCaptureDrea:isCursorInCaptureDrea,
                isCursorInResizeButton:isCursorInResizeButton
            };
        }

        public function getRandomString(charLength:int = 6):String
        {
            const chars:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            const charsLen:uint = chars.length;
            var randomString:String = "";
            var index:int;

            while(charLength > 0)
            {
                index = Math.floor(charsLen*Math.random());
                randomString += chars.charAt(index);
                charLength--;
            }

            return randomString;
        }

        public function getCaptureSaveHint():String
        {
            return (captureAreaManager.isFullImageCapture()) ? "image":"selected area";
        }

        public function cutTimeStamp(str:String):String
        {
            const pattern:RegExp = /_\d\d\d\d\d\d\d\d\d/g;
            const findTimeStamp:String = pattern.exec(str);

            if(findTimeStamp === null)
            {
                return str;
            }

            const cutIndex:int = str.lastIndexOf(findTimeStamp);
            const cutStr:String = str.substr(0,cutIndex);

            return cutStr;
        }

        public function getTimeStampTailHead():String
        {
            const date:Date = new Date();
            const y:Number = date.getFullYear();
            const m:Number = date.getMonth()+1;
            const d:Number = date.getDate();
            const daystr:String = (d < 10) ? "0"+d : ""+d;
            const monthstr:String = (m < 10) ? "0"+m : ""+m;
            const timeStr:String = "["+y+"-"+monthstr+"-"+daystr+"]";

            return timeStr;
        }

        public function getTimeStampTail():String
        {
            const date:Date = new Date();
            const hour:Number = date.getHours();
            const min:Number = date.getMinutes();
            const sec:Number = date.getSeconds();
            const hourstr:String = (hour < 10) ? "0"+hour : ""+hour;
            const minstr:String = (min < 10) ? "0"+min : ""+min;
            const secstr:String = (sec < 10) ? "0"+sec : ""+sec;
            var milisecStr:String = new String(getTimer());
            if(milisecStr.length > 3) milisecStr = milisecStr.substr(milisecStr.length-3);
            const timeStr:String = hourstr+minstr+secstr+milisecStr;

            return timeStr;
        }

        public function pollTimerWaitWorkerForSaveCaptureImage():void
        {
            if(!hasTimer("workerPNGCaptureTimer"))
            {
                addTimerByName("workerPNGCaptureTimer",WORKER_WAIT_INTERVAL,true,function():Boolean
                {
                    if(receivedCaptureImageQueueFromWorker.length > 0)
                    {
                        while(receivedCaptureImageQueueFromWorker.length > 0)
                        {
                            const fileName:String = captureImageDataQueue[0][0];
                            const filePath:String = captureImageDataQueue[0][1];

                            //마지막 경로 업데이트
                            // saveFilePath = filePath.substr(0,filePath.lastIndexOf(fileName))+saveFileName;

                            const fs:FileStream = new FileStream();
                            var file:File = new File(filePath);
                            if(fileName.lastIndexOf(".png") === -1)//png를 안붙여 줬을때
                            {
                                const fixedPath:String = filePath.replace(fileName,""); //이름짜르고 경로만 저장
                                const dotPNG:String = fileName+".png";
                                file = new File(fixedPath+dotPNG);
                            }

                            fs.open(file,FileMode.WRITE);
                            fs.writeBytes(receivedCaptureImageQueueFromWorker[0]);
                            fs.close();
                            receivedCaptureImageQueueFromWorker[0].clear();
                            receivedCaptureImageQueueFromWorker[0] = null;
                            receivedCaptureImageQueueFromWorker.shift();

                            captureImageDataQueue[0] = null;
                            captureImageDataQueue.shift();
                        }
                    }
                    else if(receivedCaptureImageQueueFromWorker.length === 0 && captureImageDataQueue.length === 0)
                    {
                        captureImageDataQueue = null;
                        receivedCaptureImageQueueFromWorker = null;
                        return false;
                    }
                    return true;
                });
            }
        }

        public function saveCaptureImage():void
        {
            if(isFileBrowserOpened)
            {
                return;
            }

            executeCaptureFlashEffect();

            const replayMode:Boolean = isReplayModeON;
            var name:String = lastSaveFileName;
            var path:String = getExistingParentDirectory(lastSaveCaptureFilePath);

            setFileBrowserIsOpen(true);

            name = cutTimeStamp(name);
            name = name.substr(0,name.lastIndexOf(".png"))+"_capture_"+getTimeStampTail()+".png";//뒤에 프레임 번호 붙여줌
            path = path.substr(0,path.lastIndexOf(lastSaveFileName))+name;

            var file:File = (name !== path) ? new File(path): File.desktopDirectory.resolvePath(name);

            const fs:FileStream = new FileStream();
            const saveWindowTitle:String = "Save capture image";

            file.addEventListener(IOErrorEvent.IO_ERROR, onCancelSaveCaptureImage);
            file.addEventListener(Event.CANCEL, onCancelSaveCaptureImage);
            file.addEventListener(Event.SELECT, onSelectSaveCaptureImage);
            file.browseForSave(saveWindowTitle);

            function onCancelSaveCaptureImage(e:Event):void
            {
                setFileBrowserIsOpen(false);
                file.cancel();
                file.removeEventListener(IOErrorEvent.IO_ERROR, onCancelSaveCaptureImage);
                file.removeEventListener(Event.CANCEL, onCancelSaveCaptureImage);
                file.removeEventListener(Event.SELECT, onSelectSaveCaptureImage);
            }

            function onSelectSaveCaptureImage(e:Event):void
            {
                setFileBrowserIsOpen(false);
                file.cancel();
                file.removeEventListener(IOErrorEvent.IO_ERROR,onCancelSaveCaptureImage);
                file.removeEventListener(Event.CANCEL,onCancelSaveCaptureImage);
                file.removeEventListener(Event.SELECT,onSelectSaveCaptureImage);

                if(receivedCaptureImageQueueFromWorker === null) receivedCaptureImageQueueFromWorker = new Vector.<ByteArray>();
                if(captureImageDataQueue === null) captureImageDataQueue = [];

                lastSaveCaptureFilePath = getDirectoryOnly(e.target.nativePath)+File.separator+lastSaveFileName;
                captureImageDataQueue.push([file.name,e.target.nativePath]);
                startPngEncodingWorker(getCaptrueImageBitmapdata(false),0,true,isCaptureTransparentBGShowing);
                pollTimerWaitWorkerForSaveCaptureImage();
            }
        }

        public function checkSaveFailedFileName(saveFailed:Boolean):File
        {
            var _path:String = lastSaveFilePath;
            var _name:String = lastSaveFileName;

            //파일 이름 빼고 경로만 추출
            const nameStatIndex:int = _path.lastIndexOf(_name);
            const pathonly:String = _path.substr(0,nameStatIndex);

            //파일 이름에 시간이 찍혀있으면 이름 그대로 반환하고 없으면 앞에 붙여줌
            var fileName:String = _name;
            var filePath:String = pathonly+fileName;

            if(saveFailed)
            {
                //파일 쓰기가 실패하면 뒤에 new 붙임
                filePath = _path.substr(0,_path.lastIndexOf(".png"))+"_copy.png";
                fileName = _name.substr(0,_name.lastIndexOf(".png"))+"_copy.png";
            }

            return (_name !== _path) ? new File(filePath) : File.desktopDirectory.resolvePath(fileName);
        }

        public function getFileNameFromPath(path:String):String
        {
            if (!path || path.length == 0)
            {
                return "";
            }

            var lastSlash:int = path.lastIndexOf(File.separator);

            if (lastSlash >= 0)
            {
                return path.substring(lastSlash + 1);
            }

            return path;
        }

        public function convertToPNGFilePath(path:String):String
        {
            const extArr:Array = [".2020",".jpg",".jpeg",".gif","jfif"];
            var pathOnly:String = getDirectoryOnly(path)+File.separator;
            var name:String = getFileNameFromPath(path);

            for(var i:uint=0; i<3; i++)
            {
                if(name.toLowerCase().lastIndexOf(extArr[i]) !== -1)
                {
                    return pathOnly+name.substr(0,name.lastIndexOf(extArr[i]))+".png";
                }
            }

            if(name.lastIndexOf(".png") === -1)
            {
                return pathOnly+name+".png";
            }

            return path;
        }
        
        //끝의 파일 구분자가 있으면 제거해줌
        public function removeLastFileSeparator(path:String):String
        {
            if (path.charAt(path.length - 1) === File.separator)
            {
                return path.substring(0, path.length - 1);
            }
            return path;
        }

        public function getDirectoryOnly(path:String):String
        {
            if (!path || path.length == 0)
            {
                return "";
            }

            // 마지막 구분자 위치 찾기
            var lastSlash:int = Math.max(path.lastIndexOf("\\"), path.lastIndexOf("/"));

            if (lastSlash >= 0)
            {
                // 마지막 구분자 앞부분만 반환
                return path.substring(0, lastSlash);
            }

            // 구분자가 없으면 경로가 아니라 파일명만 있는 경우 → 빈 문자열 반환
            return "";
        }

        //해당 디렉토리가 없으면 그 상위 디렉토리로 위치를 바꾸어줌
        public function getExistingParentDirectory(path:String):String
        {
            try
            {
                const oldFild:File = new File(path);

                if(oldFild.exists)
                {
                    return path;
                }

                var testPath:String = path;
                var file:File = new File(testPath);
                var lastSep:int;

                while (true)
                {
                    if (file.exists && file.isDirectory)
                    {
                        return testPath + File.separator + lastSaveFileName;
                    }

                    // 마지막 separator 위치 찾기
                    lastSep = testPath.lastIndexOf(File.separator);
                    if (lastSep === -1)
                    {
                        break;
                    }

                    // 상위 경로로 이동
                    testPath = testPath.substring(0, lastSep);
                    file = new File(testPath);
                }
            }
            catch(e:Error)
            {
                return File.desktopDirectory.nativePath + File.separator + lastSaveFileName;
            }

            return File.desktopDirectory.nativePath + File.separator + lastSaveFileName;
        }

        public function openSaveFileBrowser(asFlag:Boolean,saveFailed:Boolean=false):void
        {
            //계속 저장하는거 방지 다른 이름으로 저장은 예외
            if(isReplayStarted)
            {
                stopReplay();
            }

            const continueFlag:Boolean = (isContinueSaveON === true && asFlag === false);
            const nextPath:String = getExistingParentDirectory(lastSaveFilePath);
            const replayFilePath:String = getReplayFileNameFromPath(lastSaveFilePath);
            const rawFile:File = new File(replayFilePath);

            if(nextPath === lastSaveFilePath && isFileAlreadySaved && continueFlag && rawFile.exists)
            {
                if(isUpdatePendingAfterSaving)
                {
                    startUpdate();
                }
                else if(isLoadPendingAfterSaving)
                {
                    loadFileTo("canvas");
                }
                else
                {
                    showMouseHintTemp("Already saved");
                }

                return;
            }

            if(isLassoToolStarted || isFillPenStarted || isSaveInProgress)
            {
                return;
            }

            const fs:FileStream = new FileStream();
            const mergedImage:BitmapData = getMergedBitmapdtata(false,true,true,null);

            if(nextPath !== lastSaveFilePath)
            {
                lastSaveFilePath = nextPath;
            }

            function onErrorSaveFileContinue(e:Event):void
            {
                fs.close();
                fs.removeEventListener(IOErrorEvent.IO_ERROR,onErrorSaveFileContinue);
                isFileAlreadySaved = false;

                if(isLoadPendingAfterSaving)
                {
                    loadFileTo("canvas");
                }
                else
                {
                    openSaveFileBrowser(true,true);
                }
            }

            function pollTimerWaitWorkerForImageSave(lastPath:String,isContinueSave:Boolean):void
            {
                if(isContinueSave)
                {
                    fs.addEventListener(IOErrorEvent.IO_ERROR,onErrorSaveFileContinue);
                }

                addTimerByName("workerPNGSaveTimer",WORKER_WAIT_INTERVAL,true,function(_path:String):Boolean
                {
                    if(receivedSaveImageDataFromWorker !== null)
                    {
                        fs.openAsync(new File(_path),FileMode.WRITE);
                        fs.writeBytes(receivedSaveImageDataFromWorker);
                        fs.close();
                        if(isContinueSave)
                        {
                            fs.removeEventListener(IOErrorEvent.IO_ERROR,onErrorSaveFileContinue);
                        }

                        receivedSaveImageDataFromWorker.clear();
                        receivedSaveImageDataFromWorker = null;
                        return false;
                    }
                    return true;
                },[lastPath]);
            }

            if(continueFlag)
            {
                if(rawFile.exists)
                {
                    disableFileOperationButtonsTopbar();
                    receivedSaveImageDataFromWorker = null;
                    startPngEncodingWorker(mergedImage.clone(),CANVAS_BG_COLOR,false,false);
                    saveReplayFile();
                    updateWindowTitle();
                    clearKeyBuffer();
                    isFileAlreadySaved = true;
                    pollTimerWaitWorkerForImageSave(lastSaveFilePath,true);
                }
                else //파일을 못찾으면 새로 저장
                {
                    isContinueSaveON = false;
                    openSaveFileBrowser(true);
                }
            }
            else
            {
                if(isFileBrowserOpened)
                {
                    return;
                }

                const file:File = checkSaveFailedFileName(saveFailed);
                const saveWindowTitle:String = (saveFailed) ? "Failed to save file! save with new name"
                                                :(asFlag === true) ? "Save file As.."
                                                :(isLoadPendingAfterSaving) ? "Save file before load file"
                                                :(isUpdatePendingAfterSaving) ? "Save file before update":"Save file";

                file.addEventListener(IOErrorEvent.IO_ERROR, onErrorEvent);
                file.addEventListener(Event.CANCEL, onErrorEvent);
                file.addEventListener(Event.SELECT, onSelectEvent);
                file.browseForSave(saveWindowTitle);

                setFileBrowserIsOpen(true);

                function removeEvent():void
                {
                    file.removeEventListener(IOErrorEvent.IO_ERROR, onErrorEvent);
                    file.removeEventListener(Event.CANCEL, onErrorEvent);
                    file.removeEventListener(Event.SELECT, onSelectEvent);
                }

                function onErrorEvent(e:Event):void
                {
                    setFileBrowserIsOpen(false);
                    file.cancel();
                    removeEvent();

                    if(isLoadPendingAfterSaving)
                    {
                        loadFileTo("canvas");
                    }
                    else if(isUpdatePendingAfterSaving)
                    {
                        startUpdate();
                    }
                }

                function onSelectEvent(e:Event):void
                {
                    setFileBrowserIsOpen(false);
                    disableFileOperationButtonsTopbar();
                    removeEvent();

                    isFileAlreadySaved = true;
                    isContinueSaveON = true;

                    lastSaveFilePath = convertToPNGFilePath(e.target.nativePath);
                    lastSaveFileName = getFileNameFromPath(lastSaveFilePath);
                    receivedSaveImageDataFromWorker = null;
                    startPngEncodingWorker(mergedImage.clone(),CANVAS_BG_COLOR,false,false);
                    saveReplayFile();
                    updateWindowTitle();
                    pollTimerWaitWorkerForImageSave(lastSaveFilePath,false);
                }
            }
        }

        public function saveReplayFrameData():void
        {
            const fs:FileStream = new FileStream();
            fs.open(replayCacheImageFrameDataFilePath,FileMode.WRITE);
            fs.writeObject(rJumpImageFrameData);
            fs.close();
        }

        public function loadUndoData():void
        {
            if(undoDataFilePath.exists === false)
            {
                return;
            }

            rMirrorON = false;
            isCanvasMirrored = false;
            canvasInfoBox.setMirror(false);

            const fs:FileStream = new FileStream();
            fs.open(undoDataFilePath,FileMode.READ);

            const lastUndoIndex:int = fs.readInt();
            var arr:Array = fs.readObject() as Array; //undodata first
            const bmpdRect:Rectangle = new Rectangle(0,0,arr[2],arr[3]);
            var bmpd:BitmapData = new BitmapData(arr[2],arr[3],true,0);
            var bmpd1:BitmapData = new BitmapData(arr[2],arr[3],true,0);

            if(arr[6] is Number)
            {
                undoManager.setRFileTotalFrame(arr[6]);
            }

            rData = (fs.readObject() as Array).concat();
            rDataFrame = (fs.readObject() as Array).concat();
            fs.close();

            undoDataIndex = lastUndoIndex;
            bmpd.lock();
            bmpd.setPixels(bmpdRect,arr[0]);
            bmpd.unlock();
            bmpd1.lock();
            bmpd1.setPixels(bmpdRect,arr[1]);
            bmpd1.unlock();
            undoManager.updateUndoBaseImage(bmpd.clone(),bmpd1.clone(),arr[2],arr[3],arr[4],arr[5]);

            drawUndoData();
            rReplayFOFOCursor.visible = false;
            hideMouseHint();
            bmpd.dispose();
            bmpd1.dispose();
            bmpd = null;
            bmpd1 = null;
            arr.length = 0;
            arr = null;

            //undo index가 arr의 가장 마지막 부분이 아니면 undo를 하던 중이니까 isDeleteUndoDataPending 켜줌
            if(lastUndoIndex < rData.length-1)
            {
                isDeleteUndoDataPending = true;
            }
            else
            {
                isDeleteUndoDataPending = false;
            }
        }

        public function loadScratchPadImage():void
        {
            const fs:FileStream = new FileStream();
            const ba:ByteArray = new ByteArray();
            const bmpd:BitmapData = colorPickerBox.scratchPad.getBitmapData();

            fs.open(scratchPadDataFilePath,FileMode.READ);
            var arr:Array = fs.readObject() as Array;
            fs.close();

            bmpd.lock();
            bmpd.setPixels(new Rectangle(0,0,arr[1],arr[2]),arr[0]);
            bmpd.unlock();
        }

        public function saveScratchPadImage():void
        {
            const fs:FileStream = new FileStream();
            const ba:ByteArray = new ByteArray();
            const bmpd:BitmapData = colorPickerBox.scratchPad.getBitmapData();
            const newRectangle:Rectangle = new Rectangle(0,0,bmpd.width,bmpd.height);
            bmpd.copyPixelsToByteArray(colorPickerBox.scratchPad.getBitmapData().rect,ba);

            fs.open(scratchPadDataFilePath,FileMode.WRITE);
            fs.writeObject([ba,newRectangle.width,newRectangle.height]);
            fs.close();
        }

        public function saveUndoData():void
        {
            const fs:FileStream = new FileStream();
            const arr:Array = undoManager.getUndoBaseImage();
            const bmpd:BitmapData = arr[0];
            const bmpd1:BitmapData = arr[1];
            var ba:ByteArray = new ByteArray();
            var ba1:ByteArray = new ByteArray();
            var newRectangle:Rectangle = new Rectangle(0,0,arr[2],arr[3]);

            bmpd.copyPixelsToByteArray(newRectangle,ba);
            bmpd1.copyPixelsToByteArray(newRectangle,ba1);
            // ba.compress();
            // ba1.compress();
            //레이어 1,레이어2,가로,세로,배경색, repdata 합계 프레임
            var newArr:Array = [ba,ba1,arr[2],arr[3],arr[4],arr[5],undoManager.getRFileTotalFrame()];

            fs.open(undoDataFilePath,FileMode.WRITE);
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

        public function updateAppWindowSizeInfo():void
        {
            const windowSizeInfo:Rectangle = stage.nativeWindow.bounds;

            lastAppWindowSizeInfo[0] = windowSizeInfo.x;
            lastAppWindowSizeInfo[1] = windowSizeInfo.y;
            lastAppWindowSizeInfo[2] = windowSizeInfo.width;
            lastAppWindowSizeInfo[3] = windowSizeInfo.height;
        }

        public function saveAppSatate():void
        {
            updateAppWindowSizeInfo();

            const fs:FileStream = new FileStream();
            fs.open(appStateFilePath, FileMode.WRITE);
            fs.writeObject({"CANVAS_WIDTH":CANVAS_WIDTH,
                            "CANVAS_HEIGHT":CANVAS_HEIGHT,
                            "canvasZoomIndex":canvasZoomIndex,
                            "canvasZoomedMultipler":(isCaptureModeON) ? drawModeCanvasStateForSaveAppState.z:canvasZoomMultipler,
                            "canvasPanel.x":(isCaptureModeON) ? drawModeCanvasStateForSaveAppState.px:canvasPanel.x,
                            "canvasPanel.y":(isCaptureModeON) ? drawModeCanvasStateForSaveAppState.py:canvasPanel.y,
                            "canvasAnchorPoint.x":(isCaptureModeON) ? drawModeCanvasStateForSaveAppState.x:canvasAnchorPoint.x,
                            "canvasAnchorPoint.y":(isCaptureModeON) ? drawModeCanvasStateForSaveAppState.y:canvasAnchorPoint.y,
                            "canvasAnchorPoint.rotation":(isCaptureModeON) ? drawModeCanvasStateForSaveAppState.r:canvasAnchorPoint.rotation,
                            "penSmoothValue":penSmoothValue,
                            "penSmoothSlideValue":penSmoothSlideValue,
                            "penSmoothButtonX":toolOptionsBox.penSmoothSliderCursor.x,
                            "penSize":penSize,
                            "penSizeIndex":penSizeIndex,
                            "penColor":penColor,
                            "penAlpha":penAlpha,
                            "penIsSquare":penIsSquare,
                            "eraseSize":eraserSize,
                            "eraseSizeIndex":eraserSizeIndex,
                            "eraserIsSquare":eraserIsSquare,
                            "eraseAlpha":eraserAlpha,
                            "stage.nativeWindow.x":lastAppWindowSizeInfo[0],
                            "stage.nativeWindow.y":lastAppWindowSizeInfo[1],
                            "stage.nativeWindow.width":lastAppWindowSizeInfo[2],
                            "stage.nativeWindow.height":lastAppWindowSizeInfo[3],
                            "saveFileName":lastSaveFileName,
                            "toolBox.scaleX":toolBox.scaleX,
                            "lastWindowState":lastAppWindowState,
                            "uiColorIndex":Global.getUIColorIndex(),
                            "APP_RUNNING_TIME":realWorkingTimer.getRunningTime(),
                            "refLayerLastAlpha":refLayerLastAlpha,
                            "refOpacityCursor.x":refLayerMenuBox.refOpacityCursor.x,
                            "refLayerMenuDragXMoveSum":refLayerMenuDragXMoveSum,
                            "canvasRefLayerBitmap.x":canvasRefLayerBitmap.x,
                            "canvasRefLayerBitmap.y":canvasRefLayerBitmap.y,
                            "canvasRefLayer.rotation":canvasRefLayer.rotation,
                            "canvasRefLayer.scaleX":canvasRefLayer.scaleX,
                            "canvasRefLayer.scaleY":canvasRefLayer.scaleY,
                            "canvasRefLayer.mirror":Boolean(canvasRefLayer.scaleX),
                            "refLayerMenuBox[0]":refLayerMenuBox.x,
                            "refLayerMenuBox[1]":refLayerMenuBox.y,
                            "isCanvasMirrored":isCanvasMirrored,
                            "gridValue":gridGapValue,
                            "hsvColorData[0]":hsvColorData[0],
                            "gridDrawOffsetX":gridDrawOffsetX,
                            "gridDrawOffsetY":gridDrawOffsetY,
                            "hueCursor.x":colorPickerBox.hueCursor.x,
                            "svBaseColor":colorPickerBox.svBaseColor,
                            "isHSVInfoTextMode":isHSVInfoTextMode,
                            "rReplayImageCacheState":(rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_PROCESSING) ? REPLAY_IMAGE_CAHCHE_READY:rReplayImageCacheState,
                            "rLastCanvasBGColor":rLastCanvasBGColor,
                            "isRightSidebar":isRightSidebar,
                            "saveFilePath":lastSaveFilePath,
                            "isSidebarVisible":isSidebarVisible,
                            "uiScaleIndex":Global.getUIScaleIndex(),
                            "canvasWindowON":isCanvasWindowON,
                            "canvasWindowInfo[0]":canvasWindowInfo[0],
                            "canvasWindowInfo[1]":canvasWindowInfo[1],
                            "canvasWindowInfo[2]":canvasWindowInfo[2],
                            "canvasWindowInfo[3]":canvasWindowInfo[3],
                            "getFirstRCursorPos.x":drawReplayByCommand.getFirstRCursorPos().x,
                            "getFirstRCursorPos.y":drawReplayByCommand.getFirstRCursorPos().y,
                            "isContinueSaveON":isContinueSaveON,
                            "myPalettePresetType":myPalettePresetType,
                            "isMyPaletteExpended":isMyPaletteExpended,
                            "isColorPickerBoxPositionSwapped":isColorPickerBoxPositionSwapped,
                            "topBar.captureInput.text":topBar.captureInput.text,
                            "isCaptureStampON":isCaptureStampEnabled,
                            "captureStampFont":captureStampManager.getFontName(),
                            "scrollSetMovedY":scrollSetMovedY,
                            "isRefLayerMemoryTrainingON":isRefLayerMemoryTrainingON
                            });
            fs.close();
        }

        public function loadAppState():void
        {
            const fs:FileStream = new FileStream();
            var arr:Array = [];
            var newRectangle:Rectangle;

            const firstCachedImage:File = replayCacheImageFolderPath.resolvePath("0");
            //앱 경로에 마지막 저장 파일이 있으면 끄기전의 상태로 세팅해줌

            if(firstCachedImage.exists)
            {
                fs.open(firstCachedImage, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();

                if(arr[1] is ByteArray === false)
                {
                    arr[0].uncompress();
                    newRectangle = new Rectangle(0,0,arr[1],arr[2]);
                    if(rFirstImageLayer1BitmapData) rFirstImageLayer1BitmapData.dispose();
                    rFirstImageLayer1BitmapData = new BitmapData(arr[1],arr[2],true,0);
                    rFirstImageLayer1BitmapData.lock();
                    rFirstImageLayer1BitmapData.setPixels(newRectangle,arr[0]);
                    rFirstImageLayer1BitmapData.unlock();
                    if(rFirstImageLayer2BitmapData) rFirstImageLayer2BitmapData.dispose();
                    rFirstImageLayer2BitmapData = new BitmapData(arr[1],arr[2],true,0);
                    rFirstImageBGColor = arr[3];
                }
                else
                {
                    arr[0].uncompress();
                    newRectangle = new Rectangle(0,0,arr[2],arr[3]);
                    if(rFirstImageLayer1BitmapData) rFirstImageLayer1BitmapData.dispose();
                    rFirstImageLayer1BitmapData = new BitmapData(arr[2],arr[3],true,0);
                    rFirstImageLayer1BitmapData.lock();
                    rFirstImageLayer1BitmapData.setPixels(newRectangle,arr[0]);
                    rFirstImageLayer1BitmapData.unlock();

                    arr[1].uncompress();
                    if(rFirstImageLayer2BitmapData) rFirstImageLayer2BitmapData.dispose();
                    rFirstImageLayer2BitmapData = new BitmapData(arr[2],arr[3],true,0);
                    rFirstImageLayer2BitmapData.lock();
                    rFirstImageLayer2BitmapData.setPixels(newRectangle,arr[1]);
                    rFirstImageLayer2BitmapData.unlock();
                    rFirstImageBGColor = arr[4];
                }
            }
            else
            {
                rFirstImageLayer1BitmapData.dispose();
                rFirstImageLayer2BitmapData.dispose();
                rFirstImageLayer1BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
                rFirstImageLayer2BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
            }

            if(refLayerImageFilePath.exists)
            {
                fs.open(refLayerImageFilePath, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();
                // arr[0].uncompress();
                newRectangle = new Rectangle(0,0,arr[1],arr[2]);

                var tmpbmpd:BitmapData = new BitmapData(arr[1], arr[2], true, 0);
                tmpbmpd.lock();
                tmpbmpd.setPixels(newRectangle,arr[0]);
                tmpbmpd.unlock();

                canvasRefLayerBitmapData = updateBitmapData(canvasRefLayerBitmapData,tmpbmpd,canvasRefLayerBitmap);
                canvasRefLayerBitmap.smoothing = true;

                tmpbmpd.dispose();
                tmpbmpd = null;
            }

            if(replayCacheImageFrameDataFilePath.exists)
            {
                fs.open(replayCacheImageFrameDataFilePath,FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();
                rJumpImageFrameData = arr.concat();
            }

            if(myPaletteDataFilePath.exists)
            {
                fs.open(myPaletteDataFilePath,FileMode.READ);
                var list:Array = fs.readObject();
                myPalettePreset = list.concat();
                list.length = 0;
                list = null;
            }

            if(undoDataFilePath.exists)
            {
                loadUndoData();//undo data 복구 먼저 해줘야함
            }

            if(scratchPadDataFilePath.exists)
            {
                loadScratchPadImage();
            }

            if(appStateFilePath.exists)
            {
                fs.open(appStateFilePath, FileMode.READ);
                var d:Object = fs.readObject();
                fs.close();

                //loadUndoData함수에서 canvaspanel이 호출되는데 이전에 reflayer 이미지 정보값을 넣어두어야함
                //그냥 해주면 창크기 적용이 안되서 타이머 걸어줌
                addTimerByName("loadAppDataDelayTimer",0.2,false,function(d:Object):void
                {
                    stage.nativeWindow.width = d["stage.nativeWindow.width"];
                    stage.nativeWindow.height = d["stage.nativeWindow.height"];
                    stage.nativeWindow.x = d["stage.nativeWindow.x"];
                    stage.nativeWindow.y = d["stage.nativeWindow.y"];
                    lastAppWindowSize.x = d["stage.nativeWindow.width"];
                    lastAppWindowSize.y = d["stage.nativeWindow.height"];

                    //캔버스 위치까지 전부 다해준 다음에 이전 상태가 풀스크린이었으면 세팅해줌
                    if(d["lastWindowState"] === 1) stage.nativeWindow.maximize();
                    Global.setScaleIndex(d["uiScaleIndex"]);
                    applyUIScale();
                    Global.setUIColorIndex(d["uiColorIndex"]);
                    applyUIColorSet();
                    canvasZoomIndex = d["canvasZoomIndex"];
                    updateCanvasScale(d["canvasZoomedMultipler"]);
                    canvasPanel.x = d["canvasPanel.x"];
                    canvasPanel.y = d["canvasPanel.y"];
                    canvasAnchorPoint.x = d["canvasAnchorPoint.x"];
                    canvasAnchorPoint.y = d["canvasAnchorPoint.y"];
                    canvasAnchorPoint.rotation = d["canvasAnchorPoint.rotation"];
                    setRcursorRotation(d["canvasAnchorPoint.rotation"]);
                    updateResizeButtonPos(CANVAS_WIDTH,CANVAS_HEIGHT);
                    canvasRotateCursor.rotateArrow.rotation = d["canvasAnchorPoint.rotation"];
                    penSmoothValue = d["penSmoothValue"];
                    penSmoothSlideValue = d["penSmoothSlideValue"];
                    toolOptionsBox.penSmoothSliderCursor.x = d["penSmoothButtonX"];
                    penSize = d["penSize"];
                    penColor = d["penColor"];
                    hsvColorData[0] = d["hsvColorData[0]"]; //순서 중요 이게 먼저오고 밑에 rgb info갱신해주어야함
                    isHSVInfoTextMode = d["isHSVInfoTextMode"];
                    updatePickerCurrentColor(penColor);
                    updateColorPickerCursorPosAndRGBInfo(penColor);
                    colorPickerBox.updateHueColor(d["svBaseColor"]);
                    colorPickerBox.hueCursor.x = d["hueCursor.x"];
                    penAlpha = d["penAlpha"];
                    penAlphaIndex = penAlphaList.indexOf(d["eraseAlpha"]);
                    updateDrawToolAlpha(d["penAlpha"]);
                    penIsSquare = d["penIsSquare"];
                    penListShapeIsSqare =  d["penIsSquare"];
                    toolOptionsBox.updatePenShapeSet(d["penIsSquare"]);
                    eraserSize = d["eraseSize"];
                    eraserIsSquare = d["eraserIsSquare"];
                    eraserAlpha = d["eraseAlpha"];
                    eraserAlphaIndex = penAlphaList.indexOf(d["eraseAlpha"]);
                    eraserSizeIndex = d["eraseSizeIndex"];
                    setDrawToolSize(d["penSizeIndex"]);
                    lastSaveFilePath = d["saveFilePath"];
                    lastSaveFileName = d["saveFileName"];
                    if(lastSaveFilePath === lastSaveFileName)
                    {
                        lastSaveFilePath = File.desktopDirectory.nativePath + File.separator + lastSaveFileName;
                    }
                    realWorkingTimer.setRunningTime(d["APP_RUNNING_TIME"]);
                    realWorkingTimer.update();
                    refLayerLastAlpha = d["refLayerLastAlpha"]
                    canvasRefLayer.alpha = d["refLayerLastAlpha"];
                    refLayerMenuBox.refOpacityCursor.x = d["refOpacityCursor.x"];
                    refLayerMenuBox.x = d["refLayerMenuBox[0]"];
                    refLayerMenuBox.y = d["refLayerMenuBox[1]"];
                    refLayerMenuDragXMoveSum = d["refLayerMenuDragXMoveSum"];
                    if(d["isRefLayerMemoryTrainingON"])
                    {
                        isRefLayerMemoryTrainingON = false;
                        toggleRefLayerMemoryTraining();
                    }
                    isRightSidebar = d["isRightSidebar"];
                    isSidebarVisible = d["isSidebarVisible"];
                    if(d["isRightSidebar"]) moveSideBar("right",true);
                    if(!d["isSidebarVisible"]) hideSidebarPermanent();
                    rReplayImageCacheState = d["rReplayImageCacheState"];
                    rLastCanvasBGColor = d["rLastCanvasBGColor"];
                    drawReplayByCommand.setFirstRCursorPos(d["getFirstRCursorPos.x"],d["getFirstRCursorPos.y"]);

                    updateRefLayerImageTransform(d["canvasRefLayerBitmap.x"],
                                                d["canvasRefLayerBitmap.y"],
                                                d["canvasRefLayer.rotation"],
                                                d["canvasRefLayer.scaleX"],
                                                d["canvasRefLayer.scaleY"]);

                    if(isCanvasMirrored !== d["isCanvasMirrored"]) mirrorCanvas(true);

                    gridGapValue = d["gridValue"];
                    gridDrawOffsetX = d["gridDrawOffsetX"];
                    gridDrawOffsetY = d["gridDrawOffsetY"];
                    if(!gridDrawOffsetX) gridDrawOffsetX = 0.0;
                    if(!gridDrawOffsetY) gridDrawOffsetY = 0.0;

                    if(d["gridValue"] > 0) drawGrid();
                    if(d["canvasWindowON"])
                    {
                        canvasWindowInfo = [
                                                d["canvasWindowInfo[0]"],
                                                d["canvasWindowInfo[1]"],
                                                d["canvasWindowInfo[2]"],
                                                d["canvasWindowInfo[3]"]
                                            ];
                        openImageViewWindow();
                        stage.nativeWindow.activate();
                    }

                    isContinueSaveON = d["isContinueSaveON"];
                    rDataIndex = undoDataIndex;
                    rNowFrame = getNowFrameUntilUndoIndex(undoDataIndex);
                    rPrevFrame = getNowFrameUntilUndoIndex(undoDataIndex-1);

                    // 혹시 몰라서 위치 체크 해줌
                    canvasInfoBox.setRotate(canvasAnchorPoint.rotation);
                    centerCanvas(true);
                    keepCnvasPanelInStage();
                    keepCnvasPanelInStage(true);
                    myPaletteSaveColorBeforeOtherType[0] = penColor;
                    if(d["myPalettePresetType"] > 0) activeColorPreset(d["myPalettePresetType"]);

                    updateHistoryList();
                    isMyPaletteExpended = d["isMyPaletteExpended"];
                    if(myPalettePresetType === 0 && d["isMyPaletteExpended"])
                    {
                        switchMyPaletteToExpended();
                    }
                    else
                    {
                        updateMyPaletteList();
                    }

                    isColorPickerBoxPositionSwapped = d["isColorPickerBoxPositionSwapped"];
                    if(d["isColorPickerBoxPositionSwapped"])
                    {
                        colorPickerBox.swapColorBoxPositions(d["isColorPickerBoxPositionSwapped"]);
                    }

                    sideBarScrollPanel.y = d["scrollSetMovedY"];
                    topBar.captureInput.text = d["topBar.captureInput.text"];
                    isCaptureStampEnabled = d["isCaptureStampON"];
                    if(d["captureStampFont"])
                    {
                        captureStampManager.changeFont(d["captureStampFont"],false);
                    }

                    updateCanvasNaigatorCursor();
                    updatePenSizeCursor();
                    updateWindowTitle();

                    selectLayer1(false);
                },[d]);
            }
            else //복원파일이 없을때
            {
                if(lastSaveFilePath === lastSaveFileName)
                {
                    lastSaveFilePath = File.desktopDirectory.nativePath + File.separator + lastSaveFileName;
                }

                initializeMyPaletteList();
                lastAppWindowSize.x = 1000;
                lastAppWindowSize.y = 800;

                addTimer(0.3,true,function():Boolean
                {
                    if(stage.nativeWindow.width === 1000 && stage.nativeWindow.height === 800)
                    {
                        centerCanvas();
                        return false;
                    }
                    stage.nativeWindow.width = lastAppWindowSize.x;
                    stage.nativeWindow.height = lastAppWindowSize.y;
                    return true
                });

                updateCavnvasSizeDrawMode(CANVAS_WIDTH,CANVAS_HEIGHT,0,0,false);
                updateResizeButtonPos(CANVAS_WIDTH,CANVAS_HEIGHT);
                
                updatePickerCurrentColor(penColor);
                updateColorPickerCursorPosAndRGBInfo(penColor);
                openAboutBox(true);
                applyUIColorSet();
                updateCanvasNaigatorCursor();
                updateAppWindowSizeInfo();
                canvasInfoBox.init(CANVAS_WIDTH,CANVAS_HEIGHT,Math.floor(canvasZoomMultipler*100),canvasAnchorPoint.rotation,false);

                selectLayer1(false);
            }
        }

        //size, size drag, zoom, rotate시 업데이트 해줌
        public function cUpdatePenSizeCursor():Function
        {
            var size:Number;
            var shape:Boolean;

            return function():void
            {
                const isPenTool:Boolean = isSelectedToolPenOrLine();
                if(!isPenTool && !isSelectedTool(TOOL_ERASER))
                {
                    return;
                }

                if(isPenTool)
                {
                    size = penSize;
                    shape = penIsSquare;
                }
                else
                {
                    size = eraserSize;
                    shape = eraserIsSquare;
                }

                const z:Number = canvasZoomMultipler;
                if(size*z === penLastSizeAndShape[0] && shape === penLastSizeAndShape[1])
                {
                    return;
                }

                penLastSizeAndShape[0] = size*z;
                penLastSizeAndShape[1] = shape;

                penSizePreviewCursor.graphics.clear();

                if(shape === false)
                {
                    penSizePreviewCursor.graphics.lineStyle(1,0xFFFFFF);
                    penSizePreviewCursor.graphics.drawCircle(0,0,(size/2-1/z)*z);

                    penSizePreviewCursor.graphics.lineStyle(1,0);
                    penSizePreviewCursor.graphics.drawCircle(0,0,(size/2)*z);
                    penSizePreviewCursor.rotation = 0;
                }
                else if(shape === true)
                {
                    penSizePreviewCursor.graphics.lineStyle(1,0xFFFFFF);
                    penSizePreviewCursor.graphics.drawRect((-size/2+1/z)*z,(-size/8+1/z)*z,(size-2/z)*z,(size/4-2/z)*z);

                    penSizePreviewCursor.graphics.lineStyle(1,0);
                    penSizePreviewCursor.graphics.drawRect(-size/2*z,-size/8*z,size*z,size*z/4);
                }

                penCursorShape = shape;
                penCursorSize = size;
            };
        }

        public function cDrawDone():Function
        {
            var drawLayerAlpha:ColorTransform = new ColorTransform();

            return function():void
            {
                if(canAddUndoData === false)
                {
                    rDataBuffer = [];
                    canvasDrawLayerChild.graphics.clear();
                    return;
                }

                if(isDeepUndoEnabled)
                {
                    var rDataBufferSave:Array = rDataBuffer.concat();
                    applyDeepUndo();
                    rDataBuffer = rDataBufferSave;
                    rDataBufferSave = null;
                }

                canAddUndoData = false;

                if(airBrushSizeDrawMode > 0)
                {
                    const blurSize:Number = getBlurSize(airBrushSizeDrawMode,1.0);
                    canvasDrawLayerChild.filters = [new BlurFilter(blurSize,blurSize,3)];
                    canvasDrawLayerBitmapData.draw(canvasDrawLayerChild);
                    canvasDrawLayerChild.filters = [];
                }
                else
                {
                    canvasDrawLayerBitmapData.draw(canvasDrawLayerChild);
                }

                canvasDrawLayerBitmap.bitmapData = canvasDrawLayerBitmapData;

                updateCanvasDrawLayerCliprect();
                extandCanvasDrawLayerCliprect(); // 그린 영역을 100% 다 포함하지 않아서 약간 늘려줌

                if(isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILL_PEN))
                {
                    drawLayerAlpha.alphaMultiplier = penAlpha;


                    if(isLayer2Selected) canvasLayer2BitmapData.draw(canvasDrawLayerBitmap,null,drawLayerAlpha,(isTransparentPenColor) ? "erase":null,canvasDrawLayerClipRect);
                    else            canvasLayer1BitmapData.draw(canvasDrawLayerBitmap,null,drawLayerAlpha,(isTransparentPenColor) ? "erase":null,canvasDrawLayerClipRect);
                }
                else if(isSelectedTool(TOOL_ERASER))
                {
                    drawLayerAlpha.alphaMultiplier = eraserAlpha;

                    if(isLayer2Selected) canvasLayer2BitmapData.draw(canvasDrawLayerBitmap,null,drawLayerAlpha,"erase",canvasDrawLayerClipRect);
                    else           canvasLayer1BitmapData.draw( canvasDrawLayerBitmap,null,drawLayerAlpha,"erase",canvasDrawLayerClipRect);
                }

                rDataBuffer.push(["drawDone5",isLayer2Selected]);

                if(isLayer2Selected) canvasLayer2Bitmap.bitmapData = canvasLayer2BitmapData;
                else canvasLayer1Bitmap.bitmapData = canvasLayer1BitmapData;

                canvasDrawLayerBitmapData.fillRect(canvasDrawLayerClipRect,0); //그려준 영역만
                canvasDrawLayerChild.graphics.clear();
                undoManager.addNew();
            }
        }

        public function cLineTool():Function
        {
            const toDeg:Number = 180/Math.PI;
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

                if (denominator == 0) {
                    // 두 선분이 평행하거나 일치함
                    return false;
                }

                var t1:Number = numerator1 / denominator;
                var t2:Number = numerator2 / denominator;

                if (t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1) {
                    // 두 선분이 교차함
                    return true;
                } else {
                    // 두 선분이 교차하지 않음
                    return false;
                }
            }

            //중앙선+양옆선 3개의 선이 캔버스 4개의 선과 하나라도 닿으면 true를 반환함
            function isLineInsideCanvas():Boolean
            {
                if(canvasPanel.hitTestPoint(stage.mouseX,stage.mouseY,true))
                {
                    return true;
                }
                else
                {
                    const sideLine1:Array = getSideLine(startPoint.x,startPoint.y,endPoint.x,endPoint.y,xSize/2,xShape);
                    const sideLine2:Array = getSideLine(startPoint.x,startPoint.y,endPoint.x,endPoint.y,-xSize/2,xShape);

                    if(checkCollision(startPoint.x,startPoint.y,endPoint.x,endPoint.y)
                    || checkCollision(sideLine1[0],sideLine1[1],sideLine1[2],sideLine1[3])
                    || checkCollision(sideLine2[0],sideLine2[1],sideLine2[2],sideLine2[3]))
                    {
                        return true;
                    }
                }

                return false;
            }

            function checkCollision(x1:Number,y1:Number,x2:Number,y2:Number):Boolean
            {
                return isTwoLineIntersection(x1,y1,x2,y2,0,0,canvasSizeWidth,0)
                    || isTwoLineIntersection(x1,y1,x2,y2,0,0,0,canvasSizeHeight)
                    || isTwoLineIntersection(x1,y1,x2,y2,0,canvasSizeHeight,canvasSizeWidth,canvasSizeHeight)
                    || isTwoLineIntersection(x1,y1,x2,y2,canvasSizeWidth,0,canvasSizeWidth,canvasSizeHeight)
            }

            function getSideLine(x1:Number,y1:Number,x2:Number,y2:Number,distance:Number,squareCapFlag:Boolean):Array
            {
                //길이를 약간 늘려줌
                if(!squareCapFlag)
                {
                    const pointVec:Array = extendLineSegment(x1,y1,x2,y2,Math.abs(distance));
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

                return [newLineStartX,newLineStartY,newLineEndX,newLineEndY];
            }

            //선분 시작 끝점을 distance로 늘려서 좌표를 반환함
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
                const ang:Number = Math.atan2(oldX-canvasDrawLayerChild.mouseX,oldY-canvasDrawLayerChild.mouseY);
                var deg:Number = ang*toDeg+90;
                if(deg > 180)
                {
                    deg = deg-90;
                }

                var degstr:String = Math.abs(deg % 90).toFixed(1)+"°";
                showMouseHint(degstr);
            }

            function drawLine():void //지우개인가 펜인가 구분해서 lineto 실시
            {
                canvasDrawLayerChild.graphics.clear();

                canvasDrawLayer.alpha = xAlpha;
                if(xShape)
                {
                    canvasDrawLayerChild.graphics.lineStyle(xSize, xColor,1,false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.ROUND);
                }
                else
                {
                    canvasDrawLayerChild.graphics.lineStyle(xSize, xColor);
                }

                canvasDrawLayerChild.graphics.moveTo(startPoint.x,startPoint.y);
                canvasDrawLayerChild.graphics.lineTo(endPoint.x,endPoint.y);
            }

            function onMouseMoveLineTool(e:MouseEvent):void
            {
                if(!mouseMovedFlag)
                {
                    mouseMovedFlag = true;
                }
                const mx:Number = canvasDrawLayerChild.mouseX;
                const my:Number = canvasDrawLayerChild.mouseY;

                if(xShape === true)
                {
                    const extPoints:Array = extendLineSegment(oldX,oldY,mx,my,xSize/8);
                    startPoint.setTo(extPoints[0],extPoints[1]);
                    endPoint.setTo(extPoints[2],extPoints[3])
                }
                else
                {
                    startPoint.setTo(oldX,oldY);
                    endPoint.setTo(mx,my)
                }

                drawLine();
                showDgreeHint();
            }

            function onMouseUpLineTool(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveLineTool);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpLineTool);

                isPenSizeCursorInvisible = false;

                if(isRefLayerMemoryTrainingON && refLayerLastAlpha > 0.0)
                {
                    setCanvasRefLayerVisibleWithFading();
                }

                isMouseDragging = false;
                hideMouseHint();

                if(isLineInsideCanvas() === true)
                {
                    const mx:Number = canvasDrawLayerChild.mouseX;
                    const my:Number = canvasDrawLayerChild.mouseY;

                    canAddUndoData = true;

                    if(mouseMovedFlag === false && oldX === mx && oldY === my)
                    {
                        rDataBuffer = [];
                        rDataBuffer.push(["dot4",xShape,xSize,xColor,xAlpha,mx,my,xBlendMode,subLayerFlag,xAirBrushON,canvasAnchorPoint.rotation]);
                        dotTool(xShape,xSize,xColor,mx,my,canvasAnchorPoint.rotation);
                    }
                    else
                    {
                        if(xShape === true)
                        {
                            const extPoints:Array = extendLineSegment(oldX,oldY,mx,my,xSize/8);
                            startPoint.setTo(extPoints[0],extPoints[1]);
                            endPoint.setTo(extPoints[2],extPoints[3])
                        }
                        else
                        {
                            startPoint.setTo(oldX,oldY);
                            endPoint.setTo(mx,my)
                        }

                        rDataBuffer.push(["line3",xShape,xSize,xColor,xAlpha,startPoint.x,startPoint.y,endPoint.x,endPoint.y,xBlendMode,subLayerFlag,airBrushSizeDrawMode]);
                        drawLine();
                    }
                }

                resetCanvasDrawLayerCliprect();
                drawDone();
            }

            return function (lineToolFlag:Boolean):void
            {
                isPenSizeCursorInvisible = true;
                xSize = penSize;
                xAlpha = penAlpha;
                xShape = penIsSquare;
                xAirBrushON = isPenAirBrushON;

                if(isTransparentPenColor)
                {
                    xColor = CANVAS_BG_COLOR;
                    xBlendMode = "erase";
                }
                else
                {
                    xColor = penColor;
                    xBlendMode = null;

                    if(!isCurrentColorSamePickedColor())
                    {
                        updatePickerCurrentColor(colorPickerBox.getRGBInfoBGColor());
                        addColorMyPaletteHistory(colorPickerBox.getRGBInfoBGColor());
                    }
                }

                canvasSizeWidth = CANVAS_WIDTH;
                canvasSizeHeight = CANVAS_HEIGHT;

                mouseMovedFlag = false;
                oldX = canvasDrawLayerChild.mouseX;
                oldY = canvasDrawLayerChild.mouseY;
                subLayerFlag = isLayer2Selected

                if(isRefLayerMemoryTrainingON)
                {
                    // setCanvasRefLayerVisibleWithFading(false);
                    canvasRefLayer.visible = false;
                }

                //캔버스2번 지워주고, draw판넬 데이터도 지워줌
                canvasDrawLayerBitmapData.dispose();
                canvasDrawLayerBitmap.bitmapData = null;
                canvasDrawLayerBitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);

                //선 관련 이벤트 함수 붙여줌
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveLineTool);
                stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpLineTool);
            };
        }

        public function resetRotationReplayMode():void
        {
            const center:Point = getStageCenterPos("replay");
            moveCanvasAnchorPoint(center.x,center.y,true);
            rCanvasAnchorPoint.rotation = 0;
            setRcursorRotation(0);
        }

        public function resetRotationDrawMode():void
        {
            const center:Point = getStageCenterPos("draw");

            updatePenSizeCursor();
            moveCanvasAnchorPoint(center.x,center.y,false);
            canvasAnchorPoint.rotation = 0;
            setRcursorRotation(0);
            canvasInfoBox.setRotate(0);
            updateCanvasNaigatorCursor();
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
                canvasInfoBox.setRotate(Math.abs(xAnc.rotation));
            }

            function onMouseUp():void
            {
                isPenSizeCursorInvisible = false;

                if(!isReplayMode)
                {
                    if(isLassoToolStarted)
                    {
                        if(isLassoMenuHiddenTemp === true)
                        {
                            hideLassoMenuBoxTemp();
                        }
                    }

                    updatePenSizeCursor();
                    setRefLayerAndGridVisible(true);
                    updateCanvasNaigatorCursor();
                }
                else
                {
                    if(isReplayCanvasFitToWindow)
                    {
                        fitReplayCanvasToWindow();
                    }

                    resetLastKey();
                    rFollowMouse.updateBounds();
                }

                hideCanvasRotateCursor();
                keepCnvasPanelInStage(isReplayMode);
            }

            function onDragStart():void
            {
                isPenSizeCursorInvisible = true;

                if(!isReplayMode)
                {
                    setRefLayerAndGridVisible(false);
                }

                const center:Point = getStageCenterPos("replay");
                moveCanvasAnchorPoint(center.x,center.y,isReplayMode);
                //캔버스 이동이 완료된후 함수를 초기화 시켜줌
                hideBottomHint();
            }

            return function(fromReplayMode:Boolean):void
            {
                isReplayMode = fromReplayMode;
                xAnc = (isReplayMode) ? rCanvasAnchorPoint : canvasAnchorPoint
                getAngle = createAngleUpdateFunctionByMouseDrag(xAnc);
                startDragInteraction(onDragStart,onMouseMove,onMouseUp);
            }
        }

        public function cMoveTool():Function
        {
            var getMovedPos:Function;

            function onMouseUpMoveTool(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveMovetool);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpMoveTool);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpMoveTool);

                isMouseDragging = false;
                isPenSizeCursorInvisible = false;
                getMovedPos = null;
                var tmpbmpd:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);

                const movex:Number = Math.floor(canvasLayer1Bitmap.x);
                const movey:Number = Math.floor(canvasLayer1Bitmap.y);
                const movex1:Number = Math.floor(canvasLayer2Bitmap.x);
                const movey1:Number = Math.floor(canvasLayer2Bitmap.y);
                var movedMat:Matrix = new Matrix();

                if(isDeepUndoEnabled) applyDeepUndo();
                //최종적으로 움직인 거리를 실제로 비트맵 데이터 조작

                if(checkedLayer === 0)
                {
                    if(canvasLayer1Bitmap.visible)
                    {
                        movedMat.translate(movex,movey);
                        tmpbmpd.draw(canvasLayer1BitmapData,movedMat);
                        canvasLayer1BitmapData = updateBitmapData(canvasLayer1BitmapData,tmpbmpd,canvasLayer1Bitmap);
                    }

                    if(canvasLayer2Bitmap.visible)
                    {
                        movedMat = new Matrix();
                        movedMat.translate(movex1,movey1);
                        tmpbmpd.fillRect(new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT),0);
                        tmpbmpd.draw(canvasLayer2BitmapData,movedMat);
                        canvasLayer2BitmapData = updateBitmapData(canvasLayer2BitmapData,tmpbmpd,canvasLayer2Bitmap);
                    }
                }
                else if(checkedLayer === 1)
                {
                    movedMat.translate(movex,movey);
                    tmpbmpd.draw(canvasLayer1BitmapData,movedMat);
                    canvasLayer1BitmapData = updateBitmapData(canvasLayer1BitmapData,tmpbmpd,canvasLayer1Bitmap);
                }
                else if(checkedLayer === 2)
                {
                    movedMat = new Matrix();
                    movedMat.translate(movex1,movey1);
                    tmpbmpd.fillRect(new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT),0);
                    tmpbmpd.draw(canvasLayer2BitmapData,movedMat);
                    canvasLayer2BitmapData = updateBitmapData(canvasLayer2BitmapData,tmpbmpd,canvasLayer2Bitmap);
                }

                tmpbmpd.dispose();
                tmpbmpd = null;
                canvasLayer1Bitmap.x = 0;
                canvasLayer1Bitmap.y = 0;
                canvasLayer2Bitmap.x = 0;
                canvasLayer2Bitmap.y = 0;

                if(isLassoToolStarted === false)
                {
                    var command:String = "move";

                    if(checkedLayer === 1)
                    {
                        command = "move1";
                        rDataBuffer.push([command,movex,movey]);
                    }
                    else if(checkedLayer === 2)
                    {
                        command = "move2";
                        rDataBuffer.push([command,movex1,movey1]);
                    }
                    else
                    {
                        if(!canvasLayer2Bitmap.visible)
                        {
                            command = "move1";
                            rDataBuffer.push([command,movex,movey]);
                        }
                        else if(!canvasLayer1Bitmap.visible)
                        {
                            command = "move2";
                            rDataBuffer.push([command,movex1,movey1]);
                        }
                        else
                        {
                            rDataBuffer.push([command,movex,movey]);
                        }
                    }

                    if(hasLastRDataCommand(command)) undoManager.addContinue();
                    else undoManager.addNew();
                }
            }

            function onMouseMoveMovetool(e:MouseEvent):void
            {
                const pos:Point = getMovedPos();

                if(checkedLayer === 0)
                {
                    if(canvasLayer1Bitmap.visible)
                    {
                        canvasLayer1Bitmap.x = pos.x;
                        canvasLayer1Bitmap.y = pos.y;
                    }

                    if(canvasLayer2Bitmap.visible)
                    {
                        canvasLayer2Bitmap.x = pos.x;
                        canvasLayer2Bitmap.y = pos.y;
                    }
                }
                else if(checkedLayer === 1)
                {
                    canvasLayer1Bitmap.x = pos.x;
                    canvasLayer1Bitmap.y = pos.y;
                }
                else if(checkedLayer === 2)
                {
                    canvasLayer2Bitmap.x = pos.x;
                    canvasLayer2Bitmap.y = pos.y;
                }
            }

            return function ():void
            {
                if(isAllLayerInvisible()) return;

                getMovedPos = createPosUpdateFunctionByMouseDrag(canvasLayer1Bitmap,canvasAnchorPoint.rotation);

                isPenSizeCursorInvisible = true;

                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveMovetool);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,onMouseUpMoveTool);
                stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpMoveTool);
            };
        }

        public function getCanvasBoundLimitPoint(canvas:Sprite,px:Number,py:Number,width:Number,height:Number,zoom:Number,rotation:Number):Point
        {
            //매개변수 rotation은 음수값으로 넣어야 됨
            var zoomClickX:Number = px*zoom;
            var zoomClickY:Number = py*zoom;

            if(zoomClickX < 0)  zoomClickX = 0;
            else if(zoomClickX > width*zoom)  zoomClickX = width*zoom;

            if(zoomClickY < 0) zoomClickY = 0;
            else if(zoomClickY > height*zoom) zoomClickY = height*zoom;

            return rotatePoint(zoomClickX,zoomClickY,rotation);
        }

        public function cZoomTool():Function
        {   
            const zoomMaxIndex:uint = canvasZoomMultiplerList.length-1;
            const clickPos:Point = new Point(0,0);
            const lastMousePos:Point = new Point(0,0);
            const mouseMoveStep:int = 37; //이 픽셀이상움직일때만 zoomcanvas를 실행
            var lastZoom:Number = 0.0;
            var startZoomIndex:int = 0;
            var dragDirection:int = 0; //1이면 x축

            function fixMouseHintPos():void
            {
                mouseHint.x = clickPos.x-mouseHint.width/2;
                mouseHint.y = clickPos.y-35*Global.getUIScale();
            }

            function zoomToolMouseMoveEvent2(dist:Number):void
            {
                if(dist > mouseMoveStep)
                {
                    startZoomIndex--;
                }
                else
                {
                    startZoomIndex++;
                }

                if(startZoomIndex < 0) 
                {
                    startZoomIndex = 0;
                }
                else if(startZoomIndex > zoomMaxIndex)
                {
                    startZoomIndex = zoomMaxIndex;
                }

                const zoomValue:Number = canvasZoomMultiplerList[startZoomIndex];
                canvasZoomIndex = startZoomIndex;

                updateCanvasScale(zoomValue,false);
                showMouseHint(Math.floor(zoomValue*100)+"%");
                fixMouseHintPos();
            }

            function onMouseMove():void
            {
                var abs:Function = Math.abs;
                var mx:Number = stage.mouseX;
                var my:Number = stage.mouseY;

                if(dragDirection === 0)
                {
                    if(abs(mx-lastMousePos.x) > 20)
                    {
                        dragDirection = 1;
                        lastMousePos.x = stage.mouseX;
                    }
                    else if(abs(my-lastMousePos.y) > 20)
                    {
                        dragDirection = 2;
                        lastMousePos.y = stage.mouseY;
                    }
                }
                else if(dragDirection === 1)
                {
                    const subX:Number = lastMousePos.x-mx;
                    if(abs(subX) > mouseMoveStep)
                    {
                        lastMousePos.x = stage.mouseX;
                        zoomToolMouseMoveEvent2(subX);
                    }
                }
                else if(dragDirection === 2)
                {
                    const subY:Number = my-lastMousePos.y;

                    if(abs(subY) > mouseMoveStep)
                    {
                        lastMousePos.y = stage.mouseY;
                        zoomToolMouseMoveEvent2(subY);
                    }
                }
            }

            function onMouseUp():void
            {
                isMouseDragging = false;
                isPenSizeCursorInvisible = false;
                hideMouseHint();
                updatePenSizeCursor();
                setRefLayerAndGridVisible(true);

                if(isLassoMenuHiddenTemp === true)
                {
                    hideLassoMenuBoxTemp();
                }

                updateCanvasNaigatorCursor();

                if(gridGapValue > 0 && lastZoom !== canvasZoomMultipler)
                {
                    drawGrid();
                }
            }
            
            return function():void
            {
                function onDragStart():void
                {
                    lastZoom = canvasZoomMultipler;
                    dragDirection = 0;
                    //클릭한 위치가 캔버스밖을 벗어날경우 줌 기준점을 캔버스 경계선에 닿도록 함
                    var gp:Point;

                    if(isLassoMenuHiddenTemp === true)
                    {
                        gp = lassoLayer1.localToGlobal(new Point(0,0));
                        moveCanvasAnchorPoint(gp.x,gp.y,false);
                    }
                    else
                    {
                        gp = canvasPanel.localToGlobal(new Point(0,0));
                        const panelLimitedPos:Point = getCanvasBoundLimitPoint(canvasPanel,canvasPanel.mouseX,canvasPanel.mouseY,CANVAS_WIDTH,CANVAS_HEIGHT,canvasZoomMultipler,-canvasAnchorPoint.rotation);
                        
                        //캔버스 0,0점이 글로벌좌표 기준으로 어느 위치에 있는지 더해줘야함
                        moveCanvasAnchorPoint(panelLimitedPos.x+gp.x,panelLimitedPos.y+gp.y,false);
                    }

                    lastMousePos.setTo(stage.mouseX,stage.mouseY);
                    startZoomIndex = canvasZoomIndex;
                    isPenSizeCursorInvisible = true;
                    setRefLayerAndGridVisible(false);
                    clickPos.setTo(stage.mouseX,stage.mouseY);
                    showMouseHint(Math.floor(canvasZoomMultipler*100)+"%");
                    fixMouseHintPos();
                }
                
                startDragInteraction(onDragStart,onMouseMove,onMouseUp);
            }
        }

        //비트맵 데이터를 대칭으로 돌려줌
        public function mirrorDraw():void
        {
            var tmpbmpd:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
            var flipMat:Matrix = new Matrix(-1,0,0,1,CANVAS_WIDTH);

            tmpbmpd.draw(canvasLayer1BitmapData,flipMat);

            canvasLayer1BitmapData = updateBitmapData(canvasLayer1BitmapData,tmpbmpd,canvasLayer1Bitmap);
        
            tmpbmpd.fillRect(new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT),0);
            tmpbmpd.draw(canvasLayer2BitmapData,flipMat);

            canvasLayer2BitmapData = updateBitmapData(canvasLayer2BitmapData,tmpbmpd,canvasLayer2Bitmap);

            tmpbmpd.dispose();
            tmpbmpd = null;

            canvasNavigatorBox.updateImage(canvasLayer1BitmapData,canvasLayer2BitmapData,CANVAS_BG_COLOR);

            if(isCanvasWindowON)
            {
                updateCanvasWindowImage();
            }
        }

        //캔버스의 중심좌표를 구함 컨트롤 박스 옵션 박스 포함
        public function getCanvasPanelMidPos():Point
        {
            const boundRect:Object = getBoundRect(canvasLayer1Bitmap);
            const left:Number = boundRect.left;
            const top:Number = boundRect.top;
            const right:Number = boundRect.right;
            const bottom:Number = boundRect.bottom;
            const visualWidth:Number = right-left;//회전해있어도 상관없음
            const visualHeight:Number = bottom-top;//양끝 모서리들의 직선거리를 구함
            const visualMidX:Number = Math.round((left+right)/2);//회전한 캔버스의 중심점을 구함
            const visualMidY:Number = Math.round((top+bottom)/2); //floor안하면 1픽셀씩 내려감 0.5를 아래 setRegPoint 함수 에서 반올림 해줘서 그럼
            const p:Point = new Point(visualMidX,visualMidY);

            return p;
        }

        public function syncMirrorReplayModeWithDrawMode():void
        {
            if(mirrorCommandReady)
            {
                mirrorCanvasReplayMode();
            }
        }

        public function updateGridMirror(mirrorflag:Boolean):void
        {
            if(mirrorflag)
            {
                canvasGrid.scaleX = -1.0;
                canvasGrid.x = CANVAS_WIDTH;
            }
            else
            {
                canvasGrid.scaleX = 1;
                canvasGrid.x = 0;
            }
        }

        public function mirrorRefLayerImage():void
        {
            canvasRefLayer.scaleX = -canvasRefLayer.scaleX;
            canvasRefLayer.rotation = -canvasRefLayer.rotation;
        }

        public function mirrorCanvas(canvasOnly:Boolean=false):void
        {
            //canvaspanel로 하면 중점이 안맞아서 canvas1로함
            const p:Point = getCanvasPanelMidPos();

            isCanvasMirrored = !isCanvasMirrored;
            mirrorCommandReady = !mirrorCommandReady;
            mirrorDraw();
            canvasInfoBox.setMirror(isCanvasMirrored);

            //회전각 부호를 바꿔야 제대로 mirror가됨
            moveCanvasAnchorPoint(p.x,p.y);//regpoint를 회전한 캔버스 중점으로 두고
            if(canvasOnly === false) //보통 미러할때, canvasonly가 true일때는 appdata에서 바꿔줄때 밖에 없음
            {
                canvasAnchorPoint.rotation = -canvasAnchorPoint.rotation;//반대각으로 세팅
                setRcursorRotation(canvasAnchorPoint.rotation)
                mirrorRefLayerImage();
            }

            updateGridMirror(isCanvasMirrored);

            const halfCanvas:Number = (stage.stageWidth-sideBar.getWidth())/2;
            var stageHalf:Number = (sideBar.visible === false) ? stage.stageWidth/2
                                            : (isRightSidebar) ? halfCanvas
                                            :                    STAGE_LEFT_OFFSET+halfCanvas;

            //창 절반을 기준점으로 앵커포인트 x축 이동.
            canvasAnchorPoint.x += Math.round((stageHalf-p.x)*2);
            updateCanvasNaigatorCursor();
            isFileAlreadySaved = false; //미러도 화면이 바뀌기 때문에 세이브 플래그 꺼줌

            mirrorRCursorPos();
        }

        public function updateCanvasSizeReplayMode(w:Number,h:Number,moveX:Number=0,moveY:Number=0,movedFlag:Boolean=false):void
        {
            if(w === RCANVAS_WIDTH && h === RCANVAS_HEIGHT)
            {
                return;
            }

            const bgColor:uint = RCANVAS_BG_COLOR;

            //캔버스가 회전되어있으면 회전된 방향으로 움직여줘야함
            rCanvasPanel.graphics.clear();
            rCanvasPanel.graphics.beginFill(bgColor);
            rCanvasPanel.graphics.drawRect(0,0,w,h);
            rCanvasPanel.graphics.endFill();

            rCanvasPanel.scrollRect = new Rectangle(0,0,w,h);//마스크 다시 씌워줌

            rCanvasLayer1BitmapData = new BitmapData(w,h,true,0);
            rCanvasLayer2BitmapData = new BitmapData(w,h,true,0);
            rCanvasDrawLayerBitmapData = new BitmapData(w,h,true,0);
            RCANVAS_WIDTH = w;
            RCANVAS_HEIGHT = h;

            if(movedFlag)
            {
                //movex y는 캔버스 사이즈 조절에서 원점이 움직였을경우 그만큼 bitmapdata를 움직여줘야 원래 이미지대로 나옴
                var mat:Matrix = new Matrix();
                mat.translate(moveX,moveY);

                rCanvasLayer1BitmapData.draw(rCanvasLayer1Bitmap,mat);
                rCanvasLayer2BitmapData.draw(rCanvasLayer2Bitmap,mat);
            }
            else
            {
                rCanvasLayer1BitmapData.draw(rCanvasLayer1Bitmap);
                rCanvasLayer2BitmapData.draw(rCanvasLayer2Bitmap);
            }

            if(rCanvasLayer1Bitmap.bitmapData) rCanvasLayer1Bitmap.bitmapData.dispose();
            rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;

            if(rCanvasLayer2Bitmap.bitmapData) rCanvasLayer2Bitmap.bitmapData.dispose();
            rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
            
            rFollowMouse.updateBounds();
            keepCnvasPanelInStage(true);

            if(isReplayCanvasFitToWindow)
            {
                fitReplayCanvasToWindow();
            }
        }

        public function updateRefLayerImagePos(w:Number,h:Number,movedFlag:Boolean):void
        {
            const scX:Number = canvasRefLayer.scaleX;
            const scY:Number = canvasRefLayer.scaleX;
            const subW:Number = (CANVAS_WIDTH-w)/2;
            const subH:Number = (CANVAS_HEIGHT-h)/2;
            const rPos:Point = rotatePoint(subW,subH,canvasRefLayer.rotation);

            canvasRefLayer.x = w/2;
            canvasRefLayer.y = h/2;

            if(movedFlag)
            {
                canvasRefLayerBitmap.x += -rPos.x/scX;
                canvasRefLayerBitmap.y += -rPos.y/scY;
            }
            else
            {
                canvasRefLayerBitmap.x += rPos.x/scX;
                canvasRefLayerBitmap.y += rPos.y/scY;
            }
        }

        public function updateCavnvasSizeDrawMode(w:Number,h:Number,moveX:Number=0,moveY:Number=0,centerMovedFlag:Boolean=false):void
        {
            const maxSize:uint = CANVAS_MAX_SIZE;

            if(w > maxSize)  w = maxSize;
            else if(w < 1) w = 1;

            if(h > maxSize) h = maxSize;
            else if(h < 1) h = 1;

            updateCanvasBGColor(canvasPanel,w,h,CANVAS_BG_COLOR);
            updateCanvasPanelMask(w,h);

            canvasLayer1BitmapData = new BitmapData(w,h,true,0);
            canvasLayer2BitmapData = new BitmapData(w,h,true,0);
            canvasDrawLayerBitmapData = new BitmapData(w,h,true,0);

            if(centerMovedFlag)
            {
                //movex y는 캔버스 사이즈 조절에서 원점이 움직였을경우 그만큼 bitmapdata를 움직여줘야
                //원래 이미지대로 나옴
                var mat:Matrix = new Matrix();
                const rp:Point = rotatePoint(moveX,moveY,-canvasAnchorPoint.rotation);  //캔버스가 회전되어있으면 회전된 방향으로 움직여줘야함

                mat.translate(moveX,moveY);

                canvasLayer1BitmapData.draw(canvasLayer1Bitmap,mat);
                canvasLayer2BitmapData.draw(canvasLayer2Bitmap,mat);

                canvasAnchorPoint.x -= Math.round(rp.x*canvasZoomMultipler);
                canvasAnchorPoint.y -= Math.round(rp.y*canvasZoomMultipler);
            }
            else
            {
                canvasLayer1BitmapData.draw(canvasLayer1Bitmap);
                canvasLayer2BitmapData.draw(canvasLayer2Bitmap);
            }

            if(canvasLayer1Bitmap.bitmapData) canvasLayer1Bitmap.bitmapData.dispose();
            canvasLayer1Bitmap.bitmapData = canvasLayer1BitmapData;

            if(canvasLayer2Bitmap.bitmapData) canvasLayer2Bitmap.bitmapData.dispose();
            canvasLayer2Bitmap.bitmapData = canvasLayer2BitmapData;

            updateRefLayerImagePos(w,h,centerMovedFlag); //canvas width가 갱신되게 전에 체크해야함

            CANVAS_WIDTH = w;
            CANVAS_HEIGHT = h;
            keepCnvasPanelInStage();
            if(gridGapValue > 0) drawGrid();
            canvasInfoBox.setSize(w,h);
        }

        public function cResizeCanvas():Object
        {
            var started:Boolean = false;
            const resizePreviewRect:Shape = new Shape();
            const resizePreviewRatioRect:Shape = new Shape();
            const resizeClickPos:Point = new Point(0,0);
            var subX:Number = 0;
            var subY:Number = 0;
            const min:Number = CANVAS_MIN_SIZE;
            const max:Number = CANVAS_MAX_SIZE;
            const ratioSizeArr:Array = [];
            const ratioArr:Array = [
                                        "1:2",(1.0/2.0),
                                        "9:16",(9.0/16.0),
                                        "10:16",(10.0/16.0),
                                        "3:4",(3.0/4.0),
                                        "1:1",1.0,
                                        "4:3",(4.0/3.0),
                                        "16:10",(16.0/10.0),
                                        "16:9",(16.0/9.0),
                                        "2:1",2.0
                                    ];
            var guideLineWidth:Number = 0;
            var ratioGuidePosBackUp:Point = new Point(0,0);
            var widthFlag:Boolean = false; //가로인지 새로인지 결정
            var targetName:String;
            var oldWidth:Number;
            var oldHeight:Number;
            var bgColor:uint;
            var stageColor:uint;
            var finalWidth:uint;
            var finalHeight:uint;
            var canvasSizeChanging:Boolean;
            var rightMouseupEventON:Boolean = false;

            function updateRatioSnapGuidePos():void
            {
                if(widthFlag)
                {
                    if(canvasPanel.mouseY > oldHeight/2)
                    {
                        if(resizePreviewRatioRect.y === ratioGuidePosBackUp.y)
                        {
                            resizePreviewRatioRect.y = ratioGuidePosBackUp.y+oldHeight+guideLineWidth;
                        }
                    }
                    else if(resizePreviewRatioRect.y !== ratioGuidePosBackUp.y)
                    {
                        resizePreviewRatioRect.y = ratioGuidePosBackUp.y;
                    }
                }
                else
                {
                    if(canvasPanel.mouseX > oldWidth/2)
                    {
                        if(resizePreviewRatioRect.x === ratioGuidePosBackUp.x)
                        {
                            resizePreviewRatioRect.x = ratioGuidePosBackUp.x+oldWidth+guideLineWidth;
                        }
                    }
                    else if(resizePreviewRatioRect.x !== ratioGuidePosBackUp.x)
                    {
                        resizePreviewRatioRect.x = ratioGuidePosBackUp.x;
                    }
                }
            }

            function checkRatioSnap(width:Number):Array
            {
                var low:Number = 0;
                var high:Number = ratioSizeArr.length-1;
                var index:Number = Math.floor((low+high)/2);
                var snapWidth:Number;

                while(low <= high)//2진 탐색
                {
                    snapWidth = ratioSizeArr[index][0];

                    if(snapWidth === width) break;
                    else if(snapWidth > width) high = index-1;
                    else low = index+1;

                    index = Math.floor((low + high)/2);
                }
                ++index;

                if(index < 0) index = 0;
                else if(index > ratioSizeArr.length-1) index = ratioSizeArr.length-1;

                return ratioSizeArr[index];
            }

            function drawRatioSnapGuide(w:Number,h:Number,targetName:String):void
            {
                widthFlag = (targetName === "resizeButtonL" || targetName === "resizeButtonR") ? true : false;
                const flipFlag:Boolean = (targetName === "resizeButtonU" || targetName === "resizeButtonL") ? true : false;

                function _drawRatioLine(referenceSize:Number,offset:Number):void
                {
                    ratioSizeArr.length = 0;

                    //hittestpoint를 위해서 배경을 그려줌
                    resizePreviewRatioRect.graphics.beginFill(0xFFFF00,0.0);
                    if(widthFlag) resizePreviewRatioRect.graphics.drawRect(-max/2,-guideLineWidth,max*2,guideLineWidth);
                    else resizePreviewRatioRect.graphics.drawRect(-guideLineWidth,-max/2,guideLineWidth,max*2);
                    resizePreviewRatioRect.graphics.endFill();

                    const color:uint = Global.getUIFGColor()
                    var prevSize:Number; //스냅 격자 그려주는 위치
                    var realSize:Number; //스냅 걸릴때 실제 사이즈
                    const len:uint = ratioArr.length;

                    for(var i:uint=0;i<len;i+=2)
                    {
                        realSize = Math.round(referenceSize*ratioArr[i+1]);
                        prevSize = realSize;

                        if(realSize > max || realSize < min)
                        {
                            continue;
                        }

                        resizePreviewRatioRect.graphics.lineStyle(3/canvasZoomMultipler,color,1.0,true,"normal","none");

                        if(flipFlag)
                        {
                            prevSize = -prevSize+offset;
                        }

                        if(widthFlag)
                        {
                            resizePreviewRatioRect.graphics.moveTo(prevSize,0);
                            resizePreviewRatioRect.graphics.lineTo(prevSize,-guideLineWidth);
                        }
                        else
                        {
                            resizePreviewRatioRect.graphics.moveTo(0,prevSize);
                            resizePreviewRatioRect.graphics.lineTo(-guideLineWidth,prevSize);
                        }
                        ratioSizeArr.push([realSize,ratioArr[i]]);
                    }
                }

                if(widthFlag) //가로 조절
                {
                    _drawRatioLine(h,w);
                }
                else
                {
                    _drawRatioLine(w,h);
                }
            }

            function isCanvasResizing():Boolean
            {
                return canvasSizeChanging;
            }

            function exitResizeCanvas():void
            {
                if(started)
                {
                    started = false;
                    if(targetName !== null)
                    {
                        stage.removeEventListener(MouseEvent.MOUSE_UP,resizeButtonMouseUpEvent);
                        if(!isRightMouseClicked)
                        {
                            rightMouseupEventON = false;
                            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,resizeButtonRightMouseUpEvent);
                        }

                        if(targetName === "resizeButtonL") stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveReizeButtonL);
                        else if(targetName === "resizeButtonR") stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveReizeButtonR);
                        else if(targetName === "resizeButtonU") stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveReizeButtonU);
                        else if(targetName === "resizeButtonD") stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveReizeButtonD);
                    }

                    canvasSizeChanging = false;
                    hideMouseHint();
                    updateCanvasResizeButtonVisible((isMouseCursorInStage() && isRightMouseClicked) || isPressingControl());
                    canvasAnchorPoint.removeChild(resizePreviewRect);
                    canvasAnchorPoint.removeChild(resizePreviewRatioRect);
                    resizePreviewRect.graphics.clear();
                    resizePreviewRatioRect.graphics.clear();

                    if(subX !== 0 || subY !== 0)
                    {
                        const centerMovedFlag:Boolean = (targetName === "resizeButtonL" || targetName === "resizeButtonU") ? true:false;

                        if(isDeepUndoEnabled)
                        {
                            applyDeepUndo();
                        }

                        updateCavnvasSizeDrawMode(finalWidth,finalHeight,subX,subY,centerMovedFlag);
                        updateResizeButtonPos(finalWidth,finalHeight);
                        rDataBuffer.push(["canvasSize",finalWidth,finalHeight,subX,subY,centerMovedFlag]);

                        if(hasLastRDataCommand("canvasSize"))
                        {
                            undoManager.addContinue();
                        }
                        else
                        {
                            undoManager.addNew();

                            if(isCanvasWindowON)
                            {
                                updateCanvasWindowBitmapSize();
                            }
                        }
                    }

                    targetName = null;
                }
                else
                {
                    updateCanvasResizeButtonVisible(false);
                    rightMouseupEventON = false;
                    stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,resizeButtonRightMouseUpEvent);
                }
            }

            function isMouseCursorInStage():Boolean
            {
                return stage.mouseX >= 0 && stage.mouseY >= 0 && stage.mouseX <= stage.stageWidth && stage.mouseY <= stage.stageHeight;
            }

            function resizeButtonRightMouseUpEvent(e:MouseEvent):void
            {
                exitResizeCanvas();
            }

            function resizeButtonMouseUpEvent(e:MouseEvent):void
            {
                exitResizeCanvas();
            }

            function drawResizePreviewRect(size:Number,x:Number,y:Number,w:Number,h:Number):void
            {
                resizePreviewRect.graphics.clear();

                if(size > 0)
                {
                    resizePreviewRect.graphics.beginFill(bgColor);
                }
                else
                {
                    resizePreviewRect.graphics.beginFill(stageColor);
                }

                resizePreviewRect.graphics.drawRect(x,y,w,h);

                updateRatioSnapGuidePos();
            }

            function updateHeight(flipFlag:Boolean):Number
            {
                subY = (flipFlag) ? resizeClickPos.y-canvasPanel.mouseY
                                  : canvasPanel.mouseY-resizeClickPos.y;

                var height:Number = (oldHeight+subY < min) ? min:
                                    (oldHeight+subY > max) ? max:
                                                             Math.floor(oldHeight+subY);
                if(height === max) subY = max-oldHeight;
                else if(height === min) subY = min-oldHeight;

                if(resizePreviewRatioRect.hitTestPoint(stage.mouseX,stage.mouseY,true))
                {
                    const snap:Array = checkRatioSnap(height);
                    if(snap)
                    {
                        subY = snap[0]-oldHeight;
                        finalHeight = snap[0];
                        showMouseHint(oldWidth+" x "+finalHeight+" ("+snap[1]+")");

                        return subY;
                    }
                }

                finalHeight = height;
                showMouseHint(oldWidth+" x "+finalHeight);

                return subY;
            }

            function updateWidth(flipFlag:Boolean):Number
            {
                subX = (flipFlag) ? resizeClickPos.x-canvasPanel.mouseX
                                  : canvasPanel.mouseX-resizeClickPos.x;

                var width:Number = (oldWidth+subX < min) ? min:
                                   (oldWidth+subX > max) ? max:
                                                    Math.floor(oldWidth+subX);

                if(width === max) subX =max-oldWidth;
                else if(width === min) subX = min-oldWidth;

                if(resizePreviewRatioRect.hitTestPoint(stage.mouseX,stage.mouseY,true))
                {
                    const snap:Array = checkRatioSnap(width);
                    if(snap)
                    {
                        subX = snap[0]-oldWidth;
                        finalWidth = snap[0];
                        showMouseHint(finalWidth+" x "+oldHeight+" ("+snap[1]+")");

                        return subX;
                    }
                }

                finalWidth = width;
                showMouseHint(finalWidth+" x "+oldHeight);

                return subX;
            }

            function onMouseMoveReizeButtonD(e:MouseEvent):void
            {
                var subY:Number = updateHeight(false);
                drawResizePreviewRect(subY,0,oldHeight,oldWidth,subY);
            }

            function onMouseMoveReizeButtonU(e:MouseEvent):void
            {
                var subY:Number = updateHeight(true);
                drawResizePreviewRect(subY,0,-subY,oldWidth,subY);
            }

            function onMouseMoveReizeButtonR(e:MouseEvent):void
            {
                var subX:Number = updateWidth(false);
                drawResizePreviewRect(subX,oldWidth,0,subX,oldHeight);
            }

            function onMouseMoveReizeButtonL(e:MouseEvent):void
            {
                var subX:Number = updateWidth(true);
                drawResizePreviewRect(subX,-subX,0,subX,oldHeight);
            }

            function isResizing():Boolean
            {
                return started;
            }

            function initVars():void
            {
                oldWidth = CANVAS_WIDTH;
                oldHeight = CANVAS_HEIGHT;
                finalWidth = oldWidth;
                finalHeight = oldHeight;
                bgColor = CANVAS_BG_COLOR;
                stageColor = STAGE_BG_COLOR;
                subX = 0;
                subY = 0;
                canvasSizeChanging = false;
                resizePreviewRect.x = canvasPanel.x;
                resizePreviewRect.y = canvasPanel.y;
                resizePreviewRatioRect.x = resizePreviewRect.x;
                resizePreviewRatioRect.y = resizePreviewRect.y;
                ratioGuidePosBackUp.setTo(resizePreviewRatioRect.x,resizePreviewRatioRect.y);
                guideLineWidth = 30/canvasZoomMultipler;
                canvasAnchorPoint.addChild(resizePreviewRect);
                canvasAnchorPoint.addChild(resizePreviewRatioRect);
                setAsTopChild(resizePreviewRect);
                setAsTopChild(resizePreviewRatioRect);
            }

            function startResizeCanvas(_targetName:String):void
            {
                //TODO:Drag인터렉션으로 변환
                if(started === false)
                {
                    started = true;
                    initVars();
                }

                targetName = _targetName;
                resizeClickPos.setTo(canvasPanel.mouseX,canvasPanel.mouseY);
                canvasSizeChanging = true;

                drawRatioSnapGuide(oldWidth,oldHeight,targetName);
                updateRatioSnapGuidePos();

                if(isToolBox2Showing) closeToolBox2();
                updateCanvasResizeButtonVisible(false);

                stage.addEventListener(MouseEvent.MOUSE_UP,resizeButtonMouseUpEvent);
                if(rightMouseupEventON === false)
                {
                    rightMouseupEventON = true;
                    stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,resizeButtonRightMouseUpEvent);
                }

                var onMouseMove:Function;
                if(targetName === "resizeButtonL") onMouseMove = onMouseMoveReizeButtonL;
                else if(targetName === "resizeButtonR") onMouseMove = onMouseMoveReizeButtonR;
                else if(targetName === "resizeButtonU") onMouseMove = onMouseMoveReizeButtonU;
                else if(targetName === "resizeButtonD") onMouseMove = onMouseMoveReizeButtonD;

                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            }

            return {
                start:startResizeCanvas,
                exit:exitResizeCanvas,
                isCanvasResizing:isCanvasResizing,
                isResizing:isResizing
            }
        }

        public function moveSelectedAreaToLassoBox(replayMode:Boolean,rectArr:Vector.<Number>,points:Array,copyFlag:Boolean,layer1:Boolean,layer2:Boolean):Boolean
        {
            //라소 경계 사각형 좌표와 크기
            const rectLeft:Number = rectArr[0];
            const rectTop:Number = rectArr[1];
            const rectWidth:Number = rectArr[2] - rectLeft;
            const rectHeight:Number = rectArr[3] - rectTop;
            const lassoPointsLen:uint = points.length;

            //가로세로 길이가 0 이하이면 실행하지 않음
            if(Math.floor(rectWidth) <= 0 || Math.floor(rectHeight) <= 0) return false;

            var xCanvasDrawLayer:Shape;
            var canvasBitmapData:BitmapData;
            var canvasBitmapDataSub:BitmapData;
            var canvasBitmap:Bitmap;
            var canvasBitmapSub:Bitmap;
            var canvasDrawLayerFilterBackUp:Array = null //에어브러시 켜줄때 필터 백업함

            if(replayMode)
            {
                canvasDrawLayerFilterBackUp = rCanvasDrawShape.filters.concat();
                rCanvasDrawShape.filters = [];
                xCanvasDrawLayer = rCanvasDrawShape;

                if(layer1)
                {
                    canvasBitmapData = rCanvasLayer1BitmapData;
                    canvasBitmap = rCanvasLayer1Bitmap;
                }

                if(layer2)
                {
                    canvasBitmapDataSub = rCanvasLayer2BitmapData;
                    canvasBitmapSub = rCanvasLayer2Bitmap;
                }
            }
            else
            {
                canvasDrawLayerFilterBackUp = canvasDrawLayerChild.filters.concat();
                canvasDrawLayerChild.filters = [];
                xCanvasDrawLayer = canvasDrawLayerChild;

                if(layer1)
                {
                    canvasBitmapData = canvasLayer1BitmapData;
                    canvasBitmap = canvasLayer1Bitmap;
                }

                if(layer2)
                {
                    canvasBitmapDataSub = canvasLayer2BitmapData;
                    canvasBitmapSub = canvasLayer2Bitmap;
                }
            }

            const newRectangle:Rectangle = new Rectangle(rectLeft,rectTop,rectWidth,rectHeight);

            var lassoBMPD:BitmapData = new BitmapData(rectWidth,rectHeight,true,0);
            var lassoBMPDsub:BitmapData = new BitmapData(rectWidth,rectHeight,true,0);
            var i:uint;

            //지우기 전에 사각형 모양으로 그려준 부분을 copypixel 함.
            if(layer1) lassoBMPD.copyPixels(canvasBitmapData,newRectangle,new Point(0,0),null,null,true);
            if(layer2) lassoBMPDsub.copyPixels(canvasBitmapDataSub,newRectangle,new Point(0,0),null,null,true);

            lassoLayer1Bitmap.smoothing = true;
            lassoLayer2Bitmap.smoothing = true;

            //bitmap1canvas에서 그려준 영역을 지워줌
            if(!copyFlag)
            {
                xCanvasDrawLayer.graphics.clear();
                xCanvasDrawLayer.graphics.beginFill(CANVAS_BG_COLOR);
                xCanvasDrawLayer.graphics.moveTo(points[0][0],points[0][1]);

                //rectLeft를 빼줘서 canvasdraw2의 0,0영역에 그려줌
                for(i=1;i<lassoPointsLen;i++)
                {
                    xCanvasDrawLayer.graphics.lineTo(points[i][0],points[i][1]);
                }

                xCanvasDrawLayer.graphics.endFill();

                if(layer1)
                {
                    canvasBitmapData.draw(xCanvasDrawLayer,null,null,"erase");
                    canvasBitmap.bitmapData = canvasBitmapData;
                }

                if(layer2)
                {
                    canvasBitmapDataSub.draw(xCanvasDrawLayer,null,null,"erase");
                    canvasBitmapSub.bitmapData = canvasBitmapDataSub;
                }
            }

            //-------------------------
            //clip하기 위해서 그려운 영역의 반전 부분을 0,0영역을 기준으로 그려줌
            //2번 반복하는게 좀 그런데 다른 방법 모르겠음
            //가로세로 절반 크기만큼 더해줘서 bmp의 중점으로 이동해주기 때문에 또 그만큼 빼줌
            xCanvasDrawLayer.graphics.clear();
            xCanvasDrawLayer.graphics.beginFill(0x00FF00);
            xCanvasDrawLayer.graphics.drawRect(0,0,rectWidth,rectHeight);
            xCanvasDrawLayer.graphics.moveTo(points[0][0]-rectLeft,points[0][1]-rectTop);

            //rectLeft를 빼줘서 canvasdraw2의 0,0영역에 그려줌
            for(i=1;i<lassoPointsLen;i++)
            {
                xCanvasDrawLayer.graphics.lineTo(points[i][0]-rectLeft,points[i][1]-rectTop);
            }

            //마지막으로 시작점을 이어줌
            xCanvasDrawLayer.graphics.endFill();
            if(layer1)
            {
                lassoLayer1Bitmap.bitmapData = lassoBMPD;
                lassoLayer1Bitmap.bitmapData.draw(xCanvasDrawLayer,null,null,"erase");
            }

            if(layer2)
            {
                lassoLayer2Bitmap.bitmapData = lassoBMPDsub;
                lassoLayer2Bitmap.bitmapData.draw(xCanvasDrawLayer,null,null,"erase");
            }
            xCanvasDrawLayer.graphics.clear(); //꼭 해줘야함

            //회전 확대를 bmp사각형의 중심으로 맞추어줌

            if(layer1)
            {
                lassoLayer1Bitmap.x = -rectWidth/2;
                lassoLayer1Bitmap.y = -rectHeight/2;
            }

            if(layer2)
            {
                lassoLayer2Bitmap.x = -rectWidth/2;
                lassoLayer2Bitmap.y = -rectHeight/2;
            }

            lassoLayer1.x = rectLeft+rectWidth/2;
            lassoLayer1.y = rectTop+rectHeight/2;
            lassoLayer2.x = lassoLayer1.x;
            lassoLayer2.y = lassoLayer1.y;
            lassoDraw.x = -lassoLayer1.x;
            lassoDraw.y = -lassoLayer1.y;

            if(replayMode)
            {
                rCanvasDrawShape.filters = canvasDrawLayerFilterBackUp.concat();
            }
            else
            {
                canvasDrawLayerChild.filters = canvasDrawLayerFilterBackUp.concat();
            }

            return true;
        }

        public function cLassoTool():Object
        {
            var clickPos:Point = new Point(0,0);
            var maxWidth:Number;
            var maxHeight:Number;

            var lassoRect:Vector.<Number>;
            var lassoPoints:Array;

            function resetPosData():void
            {
                if(lassoRect) lassoRect.length = 0;
                if(lassoPoints) lassoPoints.length = 0;
                lassoRect = null;
                lassoPoints = null;
            }

            function drawPreviewLine():void
            {
                if(lassoPoints === null)
                {
                    return;
                }

                lassoDraw.graphics.clear();

                const len:uint = lassoPoints.length;
                if(lassoPoints.length < 2) 
                {
                    return;
                }

                dottedLine.moveTo(lassoDraw.graphics,lassoPoints[0][0],lassoPoints[0][1]);

                for(var i:uint=0; i<len; i++)
                {
                    dottedLine.lineTo(lassoPoints[i][0],lassoPoints[i][1]);
                }

                dottedLine.lineTo(lassoPoints[0][0],lassoPoints[0][1],true);
            }

            function setDeafultLassoMenuPos(lassoMenu:LassoMenuSet):void
            {
                const g:Point = lassoLayer1.localToGlobal(new Point(0,0));
                const lassoW:Number = (lassoMenu.width > stage.stageWidth)
                                      ? stage.stageWidth : lassoMenu.width;

                lassoMenu.x = Math.floor(g.x-lassoW/2);
                lassoMenu.y = Math.floor(g.y+(((lassoLayer1.height)/2)*canvasZoomMultipler+20));
                // lassoMenu.y = floor(g.y+(((lassoBox1.height)/2)/zoomed+15));
            }

            function onMouseUpLassoTool():void
            {
                isMouseDragging = false;
                removeTimer("LassoDrawDelayTimer");
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveLassoTool);
                stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUpLassoTool);

                if(Math.abs(lassoRect[0]-lassoRect[2]) < 5 || Math.abs(lassoRect[1]-lassoRect[3]) < 5)
                {
                    resetLassoBox();
                    return;
                }

                if(lassoRect[0] < 0) lassoRect[0] = 0;
                if(lassoRect[1] < 0) lassoRect[1] = 0;
                if(lassoRect[2] > CANVAS_WIDTH) lassoRect[2] = CANVAS_WIDTH;
                if(lassoRect[3] > CANVAS_HEIGHT) lassoRect[3] = CANVAS_HEIGHT;

                lassoTransformData.push(lassoRect);
                lassoTransformData.push(lassoPoints);

                var checklayer1:Boolean = canvasLayer1Bitmap.visible;
                var checklayer2:Boolean = canvasLayer2Bitmap.visible;

                if(checkedLayer === 1)
                {
                    checklayer1 = true;
                    checklayer2 = false;
                }
                else if(checkedLayer === 2)
                {
                    checklayer1 = false;
                    checklayer2 = true;
                }

                if(moveSelectedAreaToLassoBox(false,lassoRect,lassoPoints,isLassoImageCopied,checklayer1,checklayer2) === false)
                {
                    resetLassoBox();
                }
                else
                {
                    drawPreviewLine();
                    //라소 메뉴 마우스 커서에보이기
                    lassoFirstData = [lassoLayer1.x,lassoLayer1.y,lassoLayer1.scaleX,lassoLayer1.scaleY,lassoLayer1.rotation];
                    isLassoToolStarted = true;
                    setDeafultLassoMenuPos(lassoMenuBox);
                    keepBoxInsideViewPort(lassoMenuBox);

                    if(checkedLayer || !checklayer1 || !checklayer2)
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
                    setAsTopChild(lassoMenuBox);

                    if(isRefLayerMenuON === true)
                    {
                        refLayerMenuBox.visible = false;
                    }

                    addInputEventsLassoTool();
                }
            }

            function onMouseMoveLassoTool(MouseEvent:Event):void
            {
                var mx:Number = canvasDrawLayerChild.mouseX;
                var my:Number = canvasDrawLayerChild.mouseY;

                lassoPoints.push([mx,my]);

                if(!hasTimer("LassoDrawDelayTimer"))
                {
                    addTimerByName("LassoDrawDelayTimer",0.1,false,function():void
                    {
                        drawPreviewLine();
                    });
                }

                //사각형 꼭지점 체크
                if(mx < lassoRect[0])
                {
                    lassoRect[0] = mx;
                }
                else if(mx > lassoRect[2])
                {
                    lassoRect[2] = mx;
                }

                if(my < lassoRect[1])
                {
                    lassoRect[1] = my;
                }
                else if(my > lassoRect[3])
                {
                    lassoRect[3] = my;
                }
            }

            function start ():void
            {
                if(isLassoToolStarted === true || isAllLayerInvisible()) return;

                isMouseDragging = true;

                lassoMenuBox.hint("Lasso tool");
                maxWidth = CANVAS_WIDTH;
                maxHeight = CANVAS_HEIGHT;

                clickPos.setTo(canvasDrawLayerChild.mouseX,canvasDrawLayerChild.mouseY);

                lassoDraw.x = 0;
                lassoDraw.y = 0;

                //left, top, right, bottom순임
                lassoRect = new <Number> [clickPos.x,clickPos.y,clickPos.x,clickPos.y];
                lassoPoints = [];
                lassoTransformData = [];

                canvasDrawLayer.alpha = 1.0; //알파값이 조정되어 있을 수도 있기 때문에 해줌

                lassoDraw.graphics.clear();
                lassoPoints.push([clickPos.x,clickPos.y]);
                lassoLayer1.visible = true;

                dottedLine.setLineScale(canvasZoomMultipler);
                if(canvasLayer1Bitmap.visible)
                {
                    if(lassoLayer1LastBitmapdata != null) lassoLayer1LastBitmapdata.dispose();
                    lassoLayer1LastBitmapdata = canvasLayer1BitmapData.clone();
                }
                if(canvasLayer2Bitmap.visible)
                {
                    if(lassoLayer2LastBitmapdata != null) lassoLayer2LastBitmapdata.dispose();
                    lassoLayer2LastBitmapdata = canvasLayer2BitmapData.clone();
                }

                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveLassoTool);
                stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpLassoTool);
            };

            return {
                start:start,
                resetPosData:resetPosData
            }
        }

        public function cEyeDropperTool():Function
        {
            //일단 흰색으로 배경 깔아줌
            const magSize:Number = eyedropperLens.magSize;
            const lensRect:Rectangle = new Rectangle(0,0,magSize,magSize);
            const lensMat:Matrix = new Matrix();
            var penColorBackup:uint;
            var canvasBGShape:Shape = new Shape();

            function updateEyeDropperLensBitmap():void
            {
                const mid:Number = magSize/(4*canvasZoomMultipler); //4는 기본 중앙값 magsize/2에서 zoomed나워주고 기본이 2배줌이니까 2로 나눠준값
                const tx:Number = -canvasLayer1Bitmap.mouseX+mid;
                const ty:Number = -canvasLayer1Bitmap.mouseY+mid;

                lensMat.identity();
                lensMat.translate(tx,ty);
                lensMat.scale(2.0*canvasZoomMultipler,2.0*canvasZoomMultipler);

                eyedropperLens.bitmap.bitmapData.fillRect(lensRect,STAGE_BG_COLOR);
                eyedropperLens.bitmap.bitmapData.draw(canvasBGShape,lensMat,null,null,lensRect);

                if(canvasLayer2Bitmap.visible)
                {
                    eyedropperLens.bitmap.bitmapData.draw(canvasLayer2Bitmap.bitmapData,lensMat,null,null,lensRect);
                }

                if(canvasLayer1Bitmap.visible)
                {
                    eyedropperLens.bitmap.bitmapData.draw(canvasLayer1Bitmap.bitmapData,lensMat,null,null,lensRect);
                }
            }

            function pickColor():uint
            {
                if(canvasLayer1Bitmap.hitTestPoint(stage.mouseX,stage.mouseY))
                {
                    //배경색
                    const r3:uint = (CANVAS_BG_COLOR & 0xFF0000) >> 16;
                    const g3:uint = (CANVAS_BG_COLOR & 0x00FF00) >> 8;
                    const b3:uint = (CANVAS_BG_COLOR & 0x0000FF);

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

                    //위 레이어
                    if(canvasLayer1Bitmap.visible)
                    {
                        const c1:uint = canvasLayer1BitmapData.getPixel32(canvasLayer1Bitmap.mouseX,canvasLayer1Bitmap.mouseY);
                        a1 = ((c1 & 0xFF000000) >>> 24)/255;
                        r1 = (c1 & 0x00FF0000) >>> 16;
                        g1 = (c1 & 0x0000FF00) >>> 8;
                        b1 = (c1 & 0x000000FF);
                    }

                    //밑 레이어
                    if(canvasLayer2Bitmap.visible)
                    {
                        const c2:uint = canvasLayer2BitmapData.getPixel32(canvasLayer1Bitmap.mouseX,canvasLayer1Bitmap.mouseY);
                        a2 = ((c2 & 0xFF000000) >>> 24)/255;
                        r2 = (c2 & 0x00FF0000) >>> 16;
                        g2 = (c2 & 0x0000FF00) >>> 8;
                        b2 = (c2 & 0x000000FF);
                    }

                    // source over S 새로그린거 B는 원래 그려져 있던거
                    // aR : the union alpha (as + ab * (1 - as)) //알파 혼합
                    // r: ((S.r * S.a) + (B.r * B.a) * (1 - S.a)) / aR,
                    // g: ((S.g * S.a) + (B.g * B.a) * (1 - S.a)) / aR,
                    // b: ((S.b * S.a) + (B.b * B.a) * (1 - S.a)) / aR,

                    //아래 레이어 부터
                    aa = 1.0-a2;
                    rr = Math.round(r2*a2)+Math.round(r3*aa);
                    gg = Math.round(g2*a2)+Math.round(g3*aa);
                    bb = Math.round(b2*a2)+Math.round(b3*aa);

                    //그 위에 위 레이어
                    const aa1:Number = 1.0-a1;
                    const r:uint = Math.round(r1*a1)+Math.round(rr*aa1);
                    const g:uint = Math.round(g1*a1)+Math.round(gg*aa1);
                    const b:uint = Math.round(b1*a1)+Math.round(bb*aa1);

                    return Global.RGBtoHEX(r,g,b);
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
                if(isNotEyeDropperTool())
                {
                    exitEyeDropperTool(false);
                    return;
                }

                if(e.keyCode === KEY.c || e.keyCode === KEY.m)
                {

                }
                else if(e.keyCode === KEY.space)
                {
                    if(isTransparentPenColor)
                    {
                        selectCurrentColor(false);
                        if(sideBar.visible === false)
                        {
                            showMouseHintTemp("Current color selected");
                        }
                    }
                    else
                    {
                        selectCurrentColor(false);
                        if(isTransparentPenColor === false)
                        {
                            selectTransparentColor();
                        }

                        if(sideBar.visible === false)
                        {
                            showMouseHintTemp("Transparent color selected");
                        }
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
                if(isNotEyeDropperTool())
                {
                    exitEyeDropperTool(false);
                    return;
                }

                if(e.keyCode === KEY.c || e.keyCode === KEY.m)
                {
                    confirmEyeDropperSelection();
                }
            }

            function onMouseDownEyeDropper(e:MouseEvent):void
            {
                if(isNotEyeDropperTool())
                {
                    exitEyeDropperTool(false);
                    return;
                }

                if(eyedropperLens.visible)
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
                setCanvasRefLayerVisibleWithFading();
                canvasBGShape.graphics.clear();

                if(okFlag)
                {
                    if(!(isLastTool(TOOL_FILL_PEN)
                    || isLastTool(TOOL_LINE)
                    || isLastTool(TOOL_PEN)))
                    {
                        selectLastTool(TOOL_PEN);
                    }
                }
                selectLastUsedTool();
            }

            function isNotEyeDropperTool():Boolean
            {
                return !isSelectedTool(TOOL_EYEDROPPER) || isReplayModeON || isCaptureModeON || isFileBrowserOpened || isMouseClickBlocked;
            }

            function confirmEyeDropperSelection():void
            {
                var okFlag:Boolean = false;

                if(eyedropperLens.visible === true)
                {
                    okFlag = true;
                    const pickedColor:uint = pickColor();

                    penColor = pickedColor;
                    pickerIgnoreHistoryColor = pickedColor;
                    updateColorPickerCursorPosAndRGBInfo(pickedColor);
                }

                exitEyeDropperTool(okFlag);
            }

            function onMouseMoveEyeDropper(e:MouseEvent):void
            {
                if(isNotEyeDropperTool())
                {
                    exitEyeDropperTool(false);
                    return;
                }

                eyedropperLens.x = stage.mouseX;
                eyedropperLens.y = stage.mouseY;

                if(canShowEyedropperLens())
                {
                    Global.setColorTransform(eyedropperLens.nowColor,pickColor());
                    if(canvasZoomMultipler < 12.0)
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
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveEyeDropper);
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,onMouseDownEyeDropper);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownEyeDropper);
                stage.removeEventListener(KeyboardEvent.KEY_UP,onKeyUpEyeDropper);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN,onKeyDownEyeDropper);
            }

            function addEyedropperEvents():void
            {
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveEyeDropper);
                stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDownEyeDropper,false,-2);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onRightMouseDownEyeDropper,false,-2);
                stage.addEventListener(KeyboardEvent.KEY_UP,onKeyUpEyeDropper,false,2);
                stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDownEyeDropper,false,2);
            }

            function canShowEyedropperLens():Boolean
            {
                return isCursorInDrawArea() && canvasLayer1Bitmap.hitTestPoint(stage.mouseX,stage.mouseY,true)
                && !(refLayerMenuBox.visible && refLayerMenuBox.hitTestPoint(stage.mouseX,stage.mouseY));
            }

            return function ():void
            {
                toolBox.moveToolCursor("toolEyedropper");

                if(checkedLayer !== 0)
                {
                    return;
                }

                if(isAllLayerInvisible())
                {
                    return;
                }

                updateLastTool();
                selectLastTool(nowTool);
                setToolIndex(TOOL_EYEDROPPER);
                penColorBackup = penColor;
                Global.setColorTransform(eyedropperLens.oldColor,penColor);
                moveEraserButtonToOtherTool("toolEyedropper");
                eyedropperLens.rotateBitmap(canvasAnchorPoint.rotation);
                canvasRefLayer.visible = false;
                canvasBGShape.graphics.clear();
                canvasBGShape.graphics.beginFill(CANVAS_BG_COLOR);
                canvasBGShape.graphics.drawRect(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);

                if(canShowEyedropperLens())
                {
                    eyedropperLens.x = stage.mouseX;
                    eyedropperLens.y = stage.mouseY;
                    Global.setColorTransform(eyedropperLens.nowColor,pickColor());
                    setAsTopChild(eyedropperLens);

                    if(canvasZoomMultipler < 12.0)
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

        public function setRefLayerAndGridVisible(flag:Boolean):void
        {
            if(canvasRefLayer.alpha > 0.0)
            {
                if(flag)
                {
                    setCanvasRefLayerVisibleWithFading();
                }
                else
                {
                    canvasRefLayer.visible = false;
                }
            }
            if(gridGapValue > 0) 
            {
                canvasGrid.visible = flag;
            }
        }

        public function cHandTool():Function
        {
            const old:Point = new Point(0,0);

            var _replayMode:Boolean;
            var isDrawMode:Boolean;
            var xAnc:Sprite;
            var xBitmap:Bitmap;

            function onMouseUpHandTool(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMoveHandTool);
                stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUpHandTool);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,onMouseUpHandTool);
                stage.removeEventListener(MouseEvent.MIDDLE_MOUSE_UP,onMouseUpHandTool);

                isMouseDragging = false;
                isPenSizeCursorInvisible = false;

                keepCnvasPanelInStage(_replayMode);

                if(isDrawMode)
                {
                    setRefLayerAndGridVisible(true);

                    if(isLassoToolStarted)
                    {
                        if(isLassoMenuHiddenTemp === true)
                        {
                            hideLassoMenuBoxTemp();
                        }
                    } //tool box에서 클릭해서 핸드툴 들어갈때 필요함
                    else if(!isLastKey(KEY.space))
                    {
                        selectLastUsedTool();
                    }

                    toolBox.setCursorVisible(true);
                    updateCanvasNaigatorCursor();   
                }
                else
                {
                    if(old.x !== xAnc.x || old.y !== xAnc.y)
                    {
                        setFitReplayCanvasToWindowOFF();
                    }
                    rFollowMouse.updateBounds();
                }
            }

            function onMouseMoveHandTool(e:MouseEvent):void
            {
                xAnc.x += (stage.mouseX-old.x);
                xAnc.y += (mouseY-old.y);

                old.setTo(stage.mouseX,stage.mouseY);
            }

            return function (replayMode:Boolean,fromWheelClick:Boolean):void
            {
                isMouseDragging = true;
                _replayMode = replayMode;
                isDrawMode = !replayMode;
                xAnc = (isDrawMode) ? canvasAnchorPoint : rCanvasAnchorPoint;
                xBitmap = (isDrawMode) ? canvasLayer1Bitmap : rCanvasLayer1Bitmap;
                old.setTo(stage.mouseX, stage.mouseY);
                isPenSizeCursorInvisible = true;

                if(isDrawMode)
                {
                    toolBox.setCursorVisible(false);
                    setRefLayerAndGridVisible(false);
                }

                if(fromWheelClick)
                {
                    stage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP,onMouseUpHandTool);
                }

                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandTool);
                stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpHandTool);
                //윈도우 바깥에서 up을 하면 hand가 안꺼져서 오른쪽 마우스 뗄떼도 꺼주게함
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,onMouseUpHandTool);
            };
        }

        //zoom이나 rotate reg포인트 바뀔때마다
        //캔버스 판넬위치 따라 다니면서 크기 똑같이 해줌
        public function updateResizeButtonPos(width:Number,height:Number):void
        {
            function setpos(target:Sprite,x:Number,y:Number,w:Number,h:Number):void
            {
                target.x = x;
                target.y = y;
                target.width  = (w === 0) ? buttonSize : w;
                target.height = (h === 0) ? buttonSize : h;
            }

            const z:Number = 1/canvasZoomMultipler;
            const buttonSize:Number = 20*z;
            const buttonSize2:Number = 40*z;
            const cpPosX:Number = canvasPanel.x;
            const cpPosY:Number = canvasPanel.y;
            const top:Number = cpPosY-buttonSize;
            const bottom:Number = cpPosY+height;
            const left:Number = cpPosX-buttonSize;
            const right:Number = cpPosX+width;

            setpos(resizeButtonU,left,top,width+buttonSize2,0);
            setpos(resizeButtonD,left,bottom,width+buttonSize2,0);
            setpos(resizeButtonL,left,top,0,height+buttonSize);
            setpos(resizeButtonR,right,top,0,height+buttonSize);
        }

        public function applyLassoBoxImageToCanvas(isTransferRefLayer:Boolean):Array
        {
            const lassoBMPScaleX:Number = lassoLayer1.scaleX;
            const lassoBMPScaleY:Number = lassoLayer1.scaleY;
            var lassoBMPWidth:Number = lassoLayer1Bitmap.width*lassoBMPScaleX;
            var lassoBMPHeight:Number = lassoLayer1Bitmap.height*lassoBMPScaleY;

            if(checkedLayer === 2 || canvasLayer1Bitmap.visible === false)
            {
                lassoBMPWidth = lassoLayer2Bitmap.width*lassoBMPScaleX;
                lassoBMPHeight = lassoLayer2Bitmap.height*lassoBMPScaleY;
            }

            const boxX:Number = lassoLayer1.x;
            const boxY:Number = lassoLayer1.y;
            const ang:Number = lassoLayer1.rotation*Math.PI/180;
            var posMatrix:Matrix = new Matrix();

            posMatrix.scale(lassoBMPScaleX,lassoBMPScaleY);//스케일부터 조절해주고
            posMatrix.translate(-lassoBMPWidth/2,-lassoBMPHeight/2); //회전 중심점을 bmp중심으로 옮겨주고
            posMatrix.rotate(ang);//회전해줌
            posMatrix.translate(boxX,boxY);//라소박스 위치 그대로 붙여주면됨

            lassoLayer1Bitmap.smoothing = true;
            lassoLayer2Bitmap.smoothing = true;

            if(isTransferRefLayer === false)
            {
                if(canvasLayer1Bitmap.visible) canvasLayer1BitmapData.draw(lassoLayer1Bitmap,posMatrix);
                if(canvasLayer2Bitmap.visible) canvasLayer2BitmapData.draw(lassoLayer2Bitmap,posMatrix);
            }
            else
            {
                var layer1Bmpd:BitmapData;
                var layer2Bmpd:BitmapData;

                if(canvasLayer1Bitmap.visible)
                {
                    layer1Bmpd = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
                    layer1Bmpd.draw(lassoLayer1Bitmap,posMatrix);
                }

                if(canvasLayer2Bitmap.visible)
                {
                    layer2Bmpd = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
                    layer2Bmpd.draw(lassoLayer2Bitmap,posMatrix);
                }

                mergeImageToRefLayer(layer1Bmpd,layer2Bmpd);

                if(layer1Bmpd)
                {
                    layer1Bmpd.dispose();
                    layer1Bmpd = null;
                }

                if(layer2Bmpd)
                {
                    layer2Bmpd.dispose();
                    layer2Bmpd = null;
                }

                resetRefLayerImageTransform();
            }

            if(lassoLayer1LastBitmapdata)
            {
                lassoLayer1LastBitmapdata.dispose();
                lassoLayer1LastBitmapdata = null;
            }

            if(lassoLayer2LastBitmapdata)
            {
                lassoLayer2LastBitmapdata.dispose();
                lassoLayer2LastBitmapdata = null;
            }

            return [lassoBMPScaleX,lassoBMPScaleY,
                    lassoBMPWidth,lassoBMPHeight,
                    ang,boxX,boxY];
        }

        public function applyLassoImageToCanvas():void
        {
            if(isLassoToolStarted === true)
            {
                if(hasLassoImageChanges()  === true) //사용후에 ok하면 처리해줌
                {
                    if(isDeepUndoEnabled)
                    {
                        applyDeepUndo();
                    }

                    const lassoInfo:Array = applyLassoBoxImageToCanvas(false);
                    const point1:Vector.<Number> = lassoTransformData[0].concat();
                    const point2:Array = lassoTransformData[1].concat();
                    var command:Array = null;

                    if(lassoLayerCommandData && lassoLayerCommandData.length > 0)
                    {
                        command = lassoLayerCommandData.concat();
                    }

                    var checklayer1:Boolean = canvasLayer1Bitmap.visible;
                    var checklayer2:Boolean = canvasLayer2Bitmap.visible;

                    if(checkedLayer === 1)
                    {
                        checklayer1 = true;
                        checklayer2 = false;
                    }
                    else if(checkedLayer === 2)
                    {
                        checklayer1 = false;
                        checklayer2 = true;
                    }

                    rDataBuffer.push(["lasso2",point1,point2
                                                    ,lassoInfo
                                                    ,isLassoImageCopied
                                                    ,checklayer1
                                                    ,checklayer2
                                                    ,command]);
                    undoManager.addNew();
                }
                else
                {
                    lassoCancelBmpd();
                }

                disposeLassoBoxBitmapData();
            }
            resetLassoBox();
        }

        public function disposeLassoBoxBitmapData():void
        {
            if(lassoLayer1Bitmap.bitmapData)
            {
                lassoLayer1Bitmap.bitmapData.dispose();
            }
            if(lassoLayer2Bitmap.bitmapData)
            {
                lassoLayer2Bitmap.bitmapData.dispose();
            }
        }

        public function lassoCancelBmpd():void
        {
            if(lassoLayer1LastBitmapdata)
            {
                canvasLayer1BitmapData = updateBitmapData(canvasLayer1BitmapData,lassoLayer1LastBitmapdata,canvasLayer1Bitmap);
            }

            if(lassoLayer2LastBitmapdata)
            {
                canvasLayer2BitmapData = updateBitmapData(canvasLayer2BitmapData,lassoLayer2LastBitmapdata,canvasLayer2Bitmap);
            }

            canvasNavigatorBox.updateImage(canvasLayer1BitmapData,canvasLayer2BitmapData,CANVAS_BG_COLOR);

            if(isCanvasWindowON)
            {
                updateCanvasWindowImage();
            }
        }

        public function cancelLassoTool():void
        {
            disposeLassoBoxBitmapData();
            lassoCancelBmpd();
            resetLassoBox();
        }

        public function selectPenTool(lineFlag:Boolean=false):void
        {
            setToolIndex((lineFlag)?TOOL_LINE:TOOL_PEN);
            toggleAirBrushCheckBox(isPenAirBrushON,true);
            setDrawToolSize(penSizeIndex);
            updateDrawToolAlpha(penAlpha);
            updateOpacityCursorPos(penAlphaIndex);
            moveEraserButtonToOtherTool((lineFlag)?"toolLine":"toolPen");
            toolBox.moveToolCursor((lineFlag)?"toolLine":"toolPen");
            updateToolOptionsTextBySelectedTool();
            toolOptionsBox.updatePenShapeSet(penIsSquare);
            penCursorManager.check();

            if(toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }
        }

        public function selectLineTool():void
        {
            selectPenTool(true);
        }

        public function selectEraseTool():void
        {
            setToolIndex(TOOL_ERASER);
            toggleAirBrushCheckBox(isEraserAirBrushON,false);
            setDrawToolSize(eraserSizeIndex);
            updateDrawToolAlpha(eraserAlpha);
            updateOpacityCursorPos(eraserAlphaIndex);

            if(lastEraserPosButton)
            {
                lastEraserPosButton.visible = true;
            }

            lastEraserPosButton = null;
            toolBox2.toolErase.visible = false;
            toolBox.moveToolCursor("toolErase");
            updateToolOptionsTextBySelectedTool();
            toolOptionsBox.updatePenShapeSet(eraserIsSquare);
            penCursorManager.check();

            if(toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }
        }


        public function selectFillPenTool(fromShortCut:Boolean=false):void
        {
            setToolIndex(TOOL_FILL_PEN);
            toolBox.moveToolCursor("toolFillPen");
            penSizePreviewCursor.visible = false;
            updateOpacityCursorPos(penAlphaIndex);
            toggleAirBrushCheckBox(isPenAirBrushON, true);
            toolOptionsBox.movePenSizeCursor(1);
            toolOptionsBox.setButtonsAlphaFillPenSelected(Global.OFFALPHA);
            moveEraserButtonToOtherTool("toolFillPen");
            updateToolOptionsTextBySelectedTool();
        }

        public function selectMoveTool():void
        {
            updateToolOptionsTextBySelectedTool(); 
            setToolIndex(TOOL_MOVE);
            toolBox.moveToolCursor("toolMove");

            if(toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }
        }

        public function selectZoomTool():void
        {
            updateToolOptionsTextBySelectedTool();
            setToolIndex(TOOL_ZOOM);
            toolBox.moveToolCursor("toolZoomIn",canvasInfoBox);

            if(toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }
        }

        public function selectRotateTool():void
        {
            updateToolOptionsTextBySelectedTool();
            setToolIndex(TOOL_ROTATE);
            toolBox.moveToolCursor("toolRotate",canvasInfoBox);

            if(toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }
        }

        public function selectLassoTool():void
        {
            updateToolOptionsTextBySelectedTool();
            setToolIndex(TOOL_LASSO);
            toolBox.moveToolCursor("toolLasso");
            moveEraserButtonToOtherTool("toolLasso");

            if(toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }
        }

        public function moveEraserButtonToOtherTool(toolName:String):void
        {
            const nowButton2:SimpleButton = toolBox2.getChildByName(toolName) as SimpleButton;
            if(!nowButton2) return;

            if(lastEraserPosButton)
            {
                if(lastEraserPosButton.x !== nowButton2.x
                || lastEraserPosButton.y !== nowButton2.y) //위치가 다를 때에만 보여줌
                {
                    lastEraserPosButton.visible = true;
                }
            }

            lastEraserPosButton = nowButton2;

            nowButton2.visible = false;
            toolBox2.toolErase.visible = true;
            toolBox2.toolErase.x = nowButton2.x;
            toolBox2.toolErase.y = nowButton2.y;
            setAsTopChild(toolBox2.toolErase);
        }

        //라소박스 변형이랑 플래그 초기화
        public function resetLassoBox():void
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

            if(lassoLayer1LastBitmapdata)
            {
                lassoLayer1LastBitmapdata.dispose();
                lassoLayer1LastBitmapdata = null;
            }

            if(lassoLayer2LastBitmapdata)
            {
                lassoLayer2LastBitmapdata.dispose();
                lassoLayer2LastBitmapdata = null;
            }

            if(isRefLayerMenuON === true) refLayerMenuBox.visible = true;

            if(toolOptionsBox.layer1CheckedButton.visible || toolOptionsBox.layer2CheckedButton.visible)
            {
                toolBox.setToolButtonsForCheckedLayerON();
            }

            toolBox.setIconAlphaOnLassoToolON(1.0);

            toolOptionsBox.layerButtonWrapper.alpha = 1.0;
            toolOptionsBox.airBrushButtonWrapper.alpha = 1.0;
            toolOptionsBox.sharpLineButtonWrapper.alpha = 1.0;
            toolOptionsBox.opaSizeButtonWrapper.alpha = 1.0;
            colorPickerBox.alpha = 1.0;

            selectLastUsedTool();
        }

        //stage를 기준으로 사각형 꼭지점들 구하기
        //회전이나 기준점 상관없이 보이는 그대로 리턴함
        public function getBoundRect(ent:DisplayObject):Object
        {
            const b:Rectangle = ent.getBounds(stage);
            const tl:Point = b.topLeft;
            const br:Point = b.bottomRight;
            const tlx:Number = tl.x;
            const tly:Number = tl.y;
            const brx:Number = br.x;
            const bry:Number = br.y;

            const o:Object = {
                                left: tlx,
                                top: tly,
                                right: brx,
                                bottom: bry
                            };
            return o;
        }

        public function moveCanvasAnchorPoint(tx:Number,ty:Number,replayMode:Boolean=false):void
        {
            tx = Math.round(tx);
            ty = Math.round(ty);

            var xAnc:Sprite;
            var xCanvas:Sprite;
            var xZoomed:Number;

            if(replayMode)
            {
                xAnc = rCanvasAnchorPoint;
                xCanvas = rCanvasPanel;
                xZoomed = rCanvasZoomMultiplier;
            }
            else
            {
                xAnc = canvasAnchorPoint;
                xCanvas = canvasPanel;
                xZoomed = canvasZoomMultipler;
            }

            if(xAnc.x === tx && xAnc.y === ty)
            {
                return;
            }

            //round하면 정확도가 약간 줄어드는데, 안하면 그릴때 픽셀 어긋남
            //캔버스 회전됐을때 점 위치를 구해줌
            //zoom된값을 나눠줘야 제대로된 이동거리가 나옴
            const rotateToolMoveEvent:Point = rotatePoint((xAnc.x-tx)/xZoomed,
                                                 (xAnc.y-ty)/xZoomed,
                                                 xAnc.rotation);
            xAnc.x = tx;
            xAnc.y = ty;
            xCanvas.x += Math.round(rotateToolMoveEvent.x);//이동한 만큼 거꾸로 움직여줌
            xCanvas.y += Math.round(rotateToolMoveEvent.y);//rotate값 포함해서 움직여야함
        }

        //0,0을 기준으로 점tx,ty를 rad만큼 회전함,
        //3시 방향이 0도이고, 반시계 방향이 양수값임.
        public function rotatePoint(tx:Number,ty:Number,deg:Number):Point
        {
            const rad:Number = -(deg/180)*Math.PI;
            const cosO:Number = Math.cos(rad);
            const sinO:Number = Math.sin(rad);
            const rp:Point = new Point(tx*cosO-ty*sinO,tx*sinO+ty*cosO);

            return rp;
        }

        public function updateRefLayerBitmapPos(pos:Point):void
        {
            canvasRefLayerBitmap.x += -pos.x*(1/canvasRefLayer.scaleX);
            canvasRefLayerBitmap.y += -pos.y*(1/canvasRefLayer.scaleY);
        }

        public function getCanvasMovedUndo(index:int,redoFlag:Boolean):Point
        {
            const prevData:Array = (redoFlag) ? rData[index] : rData[index+1];
            if(!prevData) return null;

            var len:uint = prevData.length;
            var xSum:Number = 0;
            var ySum:Number = 0;

            for(var i:uint=0; i<len; i++)
            {
                if(prevData[i][0] === "canvasSize" && prevData[i][5] === true)
                {
                    xSum += prevData[i][3];
                    ySum += prevData[i][4];
                }
            }

            if(xSum === 0 && ySum === 0) return null;

            const movedXY:Point = (redoFlag) ? new Point(-xSum,-ySum)
                                             : new Point(xSum,ySum);
            return movedXY;
        }

        public function drawUndoData(redoFlag:Boolean=false):void
        {
            const undoRefData:Array = undoManager.getUndoBaseImage();
            const undoIndexSave:int = undoDataIndex;

            rDataReadFlag = true;
            rDataIndex = undoIndexSave;
            rPrevFrame = rNowFrame;
            rNowFrame = getNowFrameUntilUndoIndex(undoIndexSave);

            rMirrorON = undoRefData[5];
            if(undoRefData[2] !== RCANVAS_WIDTH || undoRefData[3] !== RCANVAS_HEIGHT)
            {
                updateCanvasSizeReplayMode(undoRefData[2],undoRefData[3],0,0,false);
            }
            if(undoRefData[4] !== RCANVAS_BG_COLOR)
            {
                updateCanvasBGColorReplayMode(undoRefData[4]);
            }

            rCanvasDrawShape.graphics.clear();
            
            rCanvasLayer1BitmapData = updateBitmapData(rCanvasLayer1BitmapData,undoRefData[0],rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = updateBitmapData(rCanvasLayer2BitmapData,undoRefData[1],rCanvasLayer2Bitmap);

            if(rData.length > 0)
            {
                for(var i:int=0; i<=undoIndexSave; i++)
                {
                    if(!rData[i]) continue;

                    drawReplayByCommand.setData(rData[i]);
                    drawReplayByCommand.drawAll();
                }
            }

            updateCanvasBGColorDrawMode(RCANVAS_BG_COLOR);
            updateCavnvasSizeDrawMode(RCANVAS_WIDTH,RCANVAS_HEIGHT,0,0,false);
            //앞 뒤 데이터가 캔버스 원점 이동 되었을때 반대방향으로 다시 움직여줌
            const movedRegPos:Point = getCanvasMovedUndo(undoIndexSave,redoFlag);
            if(movedRegPos)
            {
                canvasAnchorPoint.x += movedRegPos.x*canvasZoomMultipler;
                canvasAnchorPoint.y += movedRegPos.y*canvasZoomMultipler;
                updateRefLayerBitmapPos(movedRegPos);
            }

            canvasLayer1BitmapData = updateBitmapData(canvasLayer1BitmapData,rCanvasLayer1BitmapData,canvasLayer1Bitmap);
            canvasLayer2BitmapData = updateBitmapData(canvasLayer2BitmapData,rCanvasLayer2BitmapData,canvasLayer2Bitmap);

            showRCursorOnUndo(undoDataIndex);
            checkMirrorCanvasReplayMirror();

            canvasNavigatorBox.updateImage(canvasLayer1BitmapData,canvasLayer2BitmapData,CANVAS_BG_COLOR);

            if(isCanvasWindowON)
            {
                updateCanvasWindowImage();
                updateCanvasWindowBitmapSize();
            }

            keepCnvasPanelInStage(); //사이즈가 크가 줄었을때 캔버스가 창 밖으로 나가는거 체크
            updateCanvasNaigatorCursor();
            enableNewFileButton();
        }

        public function redo():void
        {
            if(isDeepUndoEnabled)
            {
                moveToNextStep();
                applyReplayCanvasToDrawModeCanvas();
                startRCursorFadeOut();

                if(rNowFrame >= undoManager.getRFileTotalFrame())
                {
                    disableDeepUndo();
                    undoDataIndex = -1;
                }
            }
            else
            {
                undoDataIndex++;
                if(undoDataIndex > rData.length-1)
                {
                    isFileAlreadySaved = false;
                    isDeleteUndoDataPending = false;
                    undoDataIndex = rData.length-1;
                }
                else if(rData.length > 0)
                {
                    isFileAlreadySaved = false;
                    drawUndoData(true);
                    startRCursorFadeOut();
                }
            }
        }

        public function undo():void
        {
            if(isDeepUndoEnabled)
            {
                if(rNowFrame > 0)
                {
                    moveToPreviousStep();
                    applyReplayCanvasToDrawModeCanvas();
                    startRCursorFadeOut();
                }
            }
            else
            {
                undoDataIndex--;
                if(undoDataIndex < -1)
                {
                    isFileAlreadySaved = false;
                    undoDataIndex = -1;

                    if(rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_READY || (rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_COMPLETE && undoManager.getRFileTotalFrame() > 0))
                    {
                        enableDeepUndo();
                        startRCursorFadeOut();
                    }
                }
                else if(rData.length > 0)
                {
                    isFileAlreadySaved = false;
                    isDeleteUndoDataPending = true;
                    drawUndoData();
                    startRCursorFadeOut();
                }
            }
        }

        public function applyReplayCanvasToDrawModeCanvas():void
        {
            canvasLayer1BitmapData = updateBitmapData(canvasLayer1BitmapData,rCanvasLayer1BitmapData,canvasLayer1Bitmap);
            canvasLayer2BitmapData = updateBitmapData(canvasLayer2BitmapData,rCanvasLayer2BitmapData,canvasLayer2Bitmap);
            updateCavnvasSizeDrawMode(rCanvasLayer1BitmapData.width,rCanvasLayer1BitmapData.height,0,0,false);
            updateCanvasBGColorDrawMode(RCANVAS_BG_COLOR);
            keepCnvasPanelInStage(false);
            isFileAlreadySaved = false;
            checkMirrorCanvasReplayMirror();
            canvasNavigatorBox.updateImage(canvasLayer1BitmapData,canvasLayer2BitmapData,RCANVAS_BG_COLOR);

            if(isCanvasWindowON)
            {
                updateCanvasWindowImage();
                updateCanvasWindowBitmapSize();
            }
        }

        public function undoToIndex(index:int):void
        {
            undoDataIndex = index;
            isFileAlreadySaved = false;
            enableNewFileButton();
            drawUndoData();
        }

        public function pollTimerWaitWorkerForCacheUndoData():void
        {
            if(!hasTimer("workerUndoDataTimer"))
            {
                addTimerByName("workerUndoDataTimer",WORKER_WAIT_INTERVAL,true,function():Boolean
                {
                    if(receivedUndoImageQueueFromWorker.length > 0)
                    {
                        createCacheImage(receivedUndoImageQueueFromWorker[0][0],
                                        receivedUndoImageQueueFromWorker[0][1],
                                        undoDataQueue[0][0],
                                        undoDataQueue[0][1],
                                        undoDataQueue[0][2],
                                        undoDataQueue[0][3],
                                        undoDataQueue[0][4],
                                        undoDataQueue[0][5]);

                        receivedUndoImageQueueFromWorker[0][0].clear();
                        receivedUndoImageQueueFromWorker[0][1].clear();
                        receivedUndoImageQueueFromWorker[0][0] = null;
                        receivedUndoImageQueueFromWorker[0][1] = null;
                        receivedUndoImageQueueFromWorker[0] = null;
                        undoDataQueue[0] = null;
                        receivedUndoImageQueueFromWorker.shift();
                        undoDataQueue.shift();
                    }
                    else if(undoDataQueue.length === 0 && receivedUndoImageQueueFromWorker.length === 0)
                    {
                        receivedUndoImageQueueFromWorker = null;
                        undoDataQueue = null;

                        return false;
                    }
                    return true;
                });
            }
        }
        
        public function cAddUndoData():Object
        {
            var dataWriteCount:uint = 0;//데이터로 저장할때  rDataFrame 카운터 누적
            var rFileTotalFrame:Number = 0; //file에저장된 프레임수 누적해서 저장
            //undo 할때 이 데이터를 기준점으로 rData그려줌 메모리 적게 하려고
            var undoBaseImage:Array = [rFirstImageLayer1BitmapData.clone()
                                    ,rFirstImageLayer2BitmapData.clone()
                                    ,CANVAS_WIDTH
                                    ,CANVAS_HEIGHT
                                    ,CANVAS_BG_COLOR
                                    ,isCanvasMirrored];

            function resetRJumpImageCount():void
            {
                dataWriteCount = 0;
            }

            function updateUndoBaseImageMirrorFlag(flag:Boolean):void
            {
                undoBaseImage[5] = flag
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
                undoManager.updateUndoBaseImage(canvasLayer1BitmapData.clone(),
                                             canvasLayer2BitmapData.clone(),
                                             canvasLayer1BitmapData.width,
                                             canvasLayer1BitmapData.height,
                                             CANVAS_BG_COLOR,
                                             isCanvasMirrored);
            }

            function updateReplayCanvasFromUndoBaseInfo():void
            {
                var rMirrorSave:Boolean = rMirrorON;

                if(undoBaseImage[2] !== RCANVAS_WIDTH || undoBaseImage[3] !== RCANVAS_HEIGHT)
                {
                    updateCanvasSizeReplayMode(undoBaseImage[2],undoBaseImage[3],0,0,false);
                }
                if(undoBaseImage[4] !== RCANVAS_BG_COLOR)
                {
                    updateCanvasBGColorReplayMode(undoBaseImage[4]);
                }

                rCanvasLayer1BitmapData = updateBitmapData(rCanvasLayer1BitmapData,undoBaseImage[0],rCanvasLayer1Bitmap);
                rCanvasLayer2BitmapData = updateBitmapData(rCanvasLayer2BitmapData,undoBaseImage[1],rCanvasLayer2Bitmap);

                drawReplayByCommand.setData(rData[0]);
                drawReplayByCommand.drawAll();

                if(undoBaseImage[0] && undoBaseImage[0] !== rCanvasLayer1BitmapData)
                {
                    undoBaseImage[0].dispose();
                }
                if(undoBaseImage[1] && undoBaseImage[1] !== rCanvasLayer2BitmapData)
                {
                    undoBaseImage[1].dispose();
                }

                undoBaseImage[0] = rCanvasLayer1BitmapData.clone();
                undoBaseImage[1] = rCanvasLayer2BitmapData.clone();
                undoBaseImage[2] = RCANVAS_WIDTH;
                undoBaseImage[3] = RCANVAS_HEIGHT;
                undoBaseImage[4] = RCANVAS_BG_COLOR;

                if(rMirrorON !== rMirrorSave)
                {
                    undoBaseImage[5] = !undoBaseImage[5];
                }

                drawReplayByCommand.setFirstRCursorPosCurrent();
            }

            function getUndoBaseImage():Array
            {
                return undoBaseImage;
            }

            function updateUndoBaseImage(bmpd1:BitmapData,bmpd2:BitmapData,width:Number,height:Number,bgColor:uint,mirrorFlag:Boolean):void
            {
                if(undoBaseImage[0] && bmpd1 !== undoBaseImage[0])
                {
                    undoBaseImage[0].dispose();
                }
                if(undoBaseImage[1] && bmpd2 !== undoBaseImage[1])
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

            //undo index까지의 프레임 합을 구함
            function getRDataTotalFrame(index:int):Number
            {
                if(index < 0)
                {
                    return 0;
                }

                var sum:Number = 0;

                for(var i:int=0;i<=index;i++)
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

            //미러가 되어있는지 확인해서 mirror커맨드를 무조건 앞으로 보냄
            //그게 아니면 미러 커맨드 지워줌
            function updateLastRDataMirror():void
            {
                var popArr:Array
                if(mirrorCommandReady)
                {
                    //마지막 데이터에 1개만의 미러 커맨드가 있으먼 미러를 무효로함 mirror mirror니까 원래대로임
                    if(rData.length > 0 && rData[rData.length-1].length === 1 && rData[rData.length-1][0][0] === "mirror")
                    {
                        mirrorCommandReady = false;
                        rData.pop();
                        rDataFrame.pop();
                    } //그게 아니면 가장 앞에 미러커맨드를 넣어줌
                    else if(rDataBuffer.length > 0 && rDataBuffer[0][0] !== "mirror")
                    {
                        mirrorCommandReady = false;
                        rDataBuffer.unshift(["mirror"]);
                    }
                }
                else
                {
                    //미러 커맨드가 꺼져있는데 독립인 미러커맨드가 있으면 지워주고 미러 커맨드 플래그를 올려줘서 다음번에
                    //미러 커맨드가 가장 앞에 오도록함
                    if(rData.length > 0 && rData[rData.length-1].length === 1 && rData[rData.length-1][0][0] === "mirror")
                    {
                        rData.pop();
                        rDataFrame.pop();
                        mirrorCommandReady = true;
                    } //그게 아니면 그냥 지워줌
                    else if(rDataBuffer.length > 0 && rDataBuffer[0][0] === "mirror")
                    {
                        rDataBuffer.shift();
                    }
                }
            }

            //끝 부분 중복처리 일때 넣어주는 거
            function addContinue():void
            {
                if(rData.length === 0) return;

                if(isDeleteUndoDataPending)
                {
                    isDeleteUndoDataPending = false;
                    rData.splice(undoDataIndex+1);
                    rDataFrame.splice(undoDataIndex+1);
                }

                updateLastRDataMirror();

                //버퍼에mirror가 있을수도 있기 때문에 요소를 하나씩 push해주어야함
                const len:uint = rDataBuffer.length;
                for(var i:uint=0; i<len; i++)
                {
                    rData[rData.length-1].push(rDataBuffer[i]);//배열안에 배열이 들어있음
                }

                rDataFrame[rDataFrame.length-1] = rData[rData.length-1].length;
                rDataBuffer = [];

                rPrevFrame = rNowFrame;
                rNowFrame = getTotalFrame();

                canvasNavigatorBox.updateImage(canvasLayer1BitmapData,canvasLayer2BitmapData,CANVAS_BG_COLOR);

                if(isCanvasWindowON)
                {
                    updateCanvasWindowImage();
                    updateCanvasWindowBitmapSize();
                }
            }

            function addNew():void
            {
                if(isDeleteUndoDataPending === true)
                {
                    isDeleteUndoDataPending = false;
                    rData.splice(undoDataIndex+1);
                    rDataFrame.splice(undoDataIndex+1);
                }
                if(rData.length >= 10) //첫번째 이미지는 빼야하니깐 -1로 계산해야함
                {
                    var oldData:Array = rData[0];

                    if(oldData.length > 0)
                    {
                        const fs:FileStream = new FileStream();
                        const c:uint = rDataFrame[0];
                        const rf:File = replayDataFilePath;

                        fs.open(rf,FileMode.APPEND);
                        fs.writeObject(oldData);
                        fs.close();
                        oldData = null;

                        rFileTotalFrame += c;
                        dataWriteCount += c;
                        updateReplayCanvasFromUndoBaseInfo();

                        if(rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_COMPLETE)
                        {
                            if(dataWriteCount > REPLAY_DISK_CACHE_FRAME_INTERVAL)
                            {
                                dataWriteCount = 0;
                                const data:Array = undoBaseImage;
                                const bmpd:BitmapData = data[0];
                                const bmpd1:BitmapData = data[1];
                                const w:int = data[2];
                                const h:int = data[3]
                                const bgColor:uint = data[4];
                                var imgData:ByteArray = new ByteArray();
                                var imgData1:ByteArray = new ByteArray();
                                const newRectangle:Rectangle = new Rectangle(0,0,w,h);

                                bmpd.copyPixelsToByteArray(newRectangle,imgData);
                                bmpd1.copyPixelsToByteArray(newRectangle,imgData1);

                                //위에서 쓰고나서 가능한 바이트랑 실제 바이트는 rf.size랑 다름, rf.size가 정확함
                                if(receivedUndoImageQueueFromWorker === null) receivedUndoImageQueueFromWorker = [];
                                if(undoDataQueue === null) undoDataQueue = [];
                                
                                undoDataQueue.push([w,h,bgColor,rf.size,rFileTotalFrame,isCanvasMirrored]);
                                startUndoImageCompressionWorker(imgData,imgData1);
                                pollTimerWaitWorkerForCacheUndoData();
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

                if(rDataBuffer.length > 0)
                {
                    rData.push(rDataBuffer);
                    rDataFrame.push(rDataBuffer.length);
                    rDataBuffer = [];
                    isFileAlreadySaved = false;
                    rDataReadFlag = true;
                }

                undoDataIndex = rData.length-1;
                canvasNavigatorBox.updateImage(canvasLayer1BitmapData,canvasLayer2BitmapData,CANVAS_BG_COLOR);

                if(isCanvasWindowON)
                {
                    updateCanvasWindowImage();
                }

                rPrevFrame = rNowFrame;
                rNowFrame = getTotalFrame();
                enableNewFileButton();
            };

            return {
                addNew:addNew,
                addContinue:addContinue,
                setRFileTotalFrame:setRFileTotalFrame,
                getRFileTotalFrame:getRFileTotalFrame,
                getRDataTotalFrame:getRDataTotalFrame,
                getUndoBaseImage:getUndoBaseImage,
                updateUndoBaseImage:updateUndoBaseImage,
                updateUndoBaseImageFromReplayMode:updateUndoBaseImageFromReplayMode,
                updateUndoBaseImageFromDrawMode:updateUndoBaseImageFromDrawMode,
                updateUndoBaseImageMirrorFlag:updateUndoBaseImageMirrorFlag,
                resetRJumpImageCount:resetRJumpImageCount,
                updateLastRDataMirror:updateLastRDataMirror
            }
        }

        // hsv커서가 color에 맞춰서 위치를 움직여줌
        public function updateColorPickerCursorPosAndRGBInfo(color:*):void
        {
            var hexColor:uint;
            var hsvColor:Vector.<Number>;

            if(color is uint)
            {
                hexColor = color as uint;
                hsvColor = Global.HEXtoHSV(hexColor,hsvColorData[0]);
            }
            else if(color is Vector.<Number>)
            {
                hexColor = Global.HSVtoHEX(color[0],color[1],color[2]);
                hsvColor = color as Vector.<Number>;
            }

            isTransparentPenColor = false;

            hsvColorData[1] = hsvColor[1];
            hsvColorData[2] = hsvColor[2];

            if(hsvColor[1] > 0 || color is Vector.<Number>) //채도값이 있을때만 갱신시킴
            {
                hsvColorData[0] = hsvColor[0];
                colorPickerBox.hueCursor.x = Math.round(hsvColor[0]*colorPickerBox.svBoxWidth);
            }

            colorPickerBox.svCursor.x = Math.round(hsvColor[1]*colorPickerBox.svBoxWidth);
            colorPickerBox.svCursor.y = Math.round(colorPickerBox.svBoxHeight - hsvColor[2]*colorPickerBox.svBoxHeight);

            //s v값을 제외한 순수 hue 컬러
            const baseColor:Vector.<uint> = Global.HSVtoRGB(hsvColor[0],1.0,1.0);
            const baseHexColor:uint = Global.RGBtoHEX(baseColor[0],baseColor[1],baseColor[2]);

            colorPickerBox.updateHueColor(baseHexColor);
            colorPickerBox.updateRGBInfoBG(hexColor,myPalettePresetType);

            if(isHSVInfoTextMode)
            {
                colorPickerBox.updateRGBInfoText("HSV",hsvColor);
            }
            else
            {
                colorPickerBox.updateRGBInfoText("RGB",hexColor);
            }
        }

        //opabox의 커서 위치와 색깔을 바꿈
        public function updateOpacityCursorPos(index:int):void
        {
            if(index <= 0) return;

            const curButton:Sprite = toolOptionsBox.opaBox.getChildByName("alphaButton"+index) as Sprite;

            if(!curButton) return;

            toolOptionsBox.opaCursor.x = curButton.x;
            toolOptionsBox.opaCursor.y = curButton.y;
        }

        public function updateDrawToolAlpha(alpha:Number=0.0):void
        {
        
            var index:int = penAlphaList.indexOf(alpha);
            const eraseFlag:Boolean = isSelectedTool(TOOL_ERASER);

            updateOpacityCursorPos(index);

            if(eraseFlag === false)
            {
                penAlpha = alpha;
                penAlphaIndex = index;
            }
            else if(eraseFlag === true)
            {
                eraserAlpha = alpha;
                eraserAlphaIndex = index;
            }
        }

        public function cDrawDot():Function
        {
            const cmd:Vector.<int> = new Vector.<int>();
            const pos:Vector.<Number> = new Vector.<Number>();

            return function (shape:Boolean,size:uint,color:uint,posX:Number,posY:Number,rotation:Number):void
            {
                canvasDrawLayerChild.graphics.clear();
                canvasDrawLayerChild.graphics.lineStyle(0,0,0);
                canvasDrawLayerChild.graphics.beginFill(color);

                if(shape === true)
                {
                    cmd.length = 0;
                    pos.length = 0;

                    const p0:Point = rotatePoint(-size/2,-size/2,rotation);
                    cmd.push(1);
                    pos.push(posX+p0.x);
                    pos.push(posY+p0.y);

                    const p1:Point = rotatePoint(+size/2,-size/2,rotation);
                    cmd.push(2);
                    pos.push(posX+p1.x);
                    pos.push(posY+p1.y);

                    const p2:Point = rotatePoint(+size/2,+size/2,rotation);
                    cmd.push(2);
                    pos.push(posX+p2.x);
                    pos.push(posY+p2.y);

                    const p3:Point = rotatePoint(-size/2,+size/2,rotation);
                    cmd.push(2);
                    pos.push(posX+p3.x);
                    pos.push(posY+p3.y);

                    canvasDrawLayerChild.graphics.drawPath(cmd,pos);
                }
                else
                {
                    canvasDrawLayerChild.graphics.drawCircle(posX,posY,size/2);
                }
                canvasDrawLayerChild.graphics.endFill();
            }
        }

        public function moveSideBar(direction:String, ignoreCheckStageOffset:Boolean = false):void
        {
            // direction: "left" or "right"
            const isRight:Boolean = (direction === "right");

            setSidebarDefaultPos();
            updateStageOffset();

            sideBarScrollPanel.x = isRight ? 9 : 5;
            sideBarScrollPanel.y = scrollSetMovedY;

            canvasNavigatorBox.x = isRight ? -4 : 0;
            canvasNavigatorBox.y = 0;

            canvasInfoBox.setWidth(canvasNavigatorBox.BOX_WIDTH);
            canvasInfoBox.x = canvasNavigatorBox.x - 2;
            canvasInfoBox.y = Math.floor(canvasNavigatorBox.y + canvasNavigatorBox.BOX_HEIGHT + 6);

            toolOptionsBox.x = isRight ? 39 : 0;
            toolOptionsBox.y = Math.floor(canvasInfoBox.y + canvasInfoBox.height + 7);

            colorPickerBox.x = toolOptionsBox.x;
            colorPickerBox.y = Math.floor(toolOptionsBox.y + toolOptionsBox.height + 10);

            toolBox.x = isRight ? -2 : 177;
            toolBox.y = Math.floor(toolOptionsBox.y + 1);

            if (!isRight && toolBox.getDeafultY() === 0)
            {
                toolBox.setDeafultY(toolBox.y);
            }

            resetScrollBarX();
            sideBar.y = topBar.BARSIZE * topBar.scaleX;

            if (!ignoreCheckStageOffset)
            {
                if(isRight)
                {
                    canvasAnchorPoint.x -= STAGE_RIGHT_OFFSET;
                }
                else
                {
                    canvasAnchorPoint.x += STAGE_LEFT_OFFSET;
                }
            }

            if (sideBar.visible)
            {
                topBar.sideBarOFFButton.visible = isRight;
                topBar.sideBarOFFButton2.visible = !isRight;
            }
            else
            {
                topBar.sideBarONButton.visible = isRight;
                topBar.sideBarONButton2.visible = !isRight;
            }

            topBar.sideBarPositionButton.visible = !isRight;
            topBar.sideBarPositionButton2.visible = isRight;

            checkFOFOPosition();

            if (isLassoToolStarted)
            {
                keepBoxInsideViewPort(lassoMenuBox);
            }

            if (isRefLayerMenuON)
            {
                keepBoxInsideViewPort(refLayerMenuBox);
            }

            hideBottomHint();
        }

        public function updateScrollBarColorAndHeight():void
        {
            const scale:Number = Global.getUIScale();
            const height:Number = Math.round((stage.stageHeight-STAGE_TOP_OFFSET-STAGE_BOTTOM_OFFSET)/scale);
            const color1:uint = Global.getUIFGColor();
            const color2:uint = Global.getUIBGColor();

            sideBarScrollBar.graphics.clear();
            sideBarScrollBar.graphics.lineStyle(2,color1,1.0,true);
            sideBarScrollBar.graphics.beginFill(color2);
            sideBarScrollBar.graphics.drawRect(0,1,21,height-2);
            sideBarScrollBar.graphics.endFill();

            scrollBarHeight = height;
        }

        public function initializeAppMenus():void
        {
            aboutBox.name = "aboutPanel";
            aboutBox.setVersionInfo(APP_VERSION.toFixed(2));
            topBar.name = "topBar";
            sideBarScrollBar.name = "sideBarScrollBar";
            topBar.makeTopbarBG(Global.UI_COLOR_MID_DARK);
            updateTopBarModeIcons("draw");

            fillPenBox.x = -fillPenBox.width-3;
            fillPenBox.y = -fillPenBox.height-3;

            colorPickerBox.rgbInfoText.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDownRGBInfoText);
            canvasNavigatorBox.scrollRect = new Rectangle(0,0,canvasNavigatorBox.width,canvasNavigatorBox.height);

            sideBarScrollPanel.addChild(canvasNavigatorBox);
            sideBarScrollPanel.addChild(canvasInfoBox);
            toolBox.initCanvasControlButtons(canvasInfoBox);
            sideBarScrollPanel.addChild(toolBox);
            sideBarScrollPanel.addChild(toolOptionsBox);
            sideBarScrollPanel.addChild(colorPickerBox);

            sideBar.addChild(sideBarScrollBar);
            sideBar.addChild(sideBarScrollPanel);
            sideBar.updateSideBGSize(getSideBarBGHeight());
            sideBarScrollBar.alpha = 0.75;
            STAGE_TOP_OFFSET = topBar.BARSIZE;

            captureStampFontListBox.y = 100;

            topBar.updateTimerPos(stage.stageWidth);
            topBar.replayFitToWindowButton.alpha = Global.OFFALPHA;
            
            bottomBar.name = "bottomBar";
            bottomBar.addChild(bottomHint);
            bottomHint.x = 2;
            bottomHint.y = 3;

            stage.addChild(loadMenuBox);
            stage.addChild(refLayerMenuBox);
            stage.addChild(aboutBox);
            stage.addChild(sideBar);
            stage.addChild(fillPenBox);
            stage.addChild(toolBox2);
            stage.addChild(canvasRotateCursor);
            stage.addChild(numPadBox);
            stage.addChild(captureStampFontListBox);
            stage.addChild(topBar);
            stage.addChild(hintHighlightBox);
            stage.addChild(bottomBar);
            stage.addChild(mouseHint);
        }

        public function initializeReplayCanvas():void
        {
            rCanvasPanel.name = "rCanvasPanel";
            rCanvasAnchorPoint.name = "rCanvasAnchorPoint";
            rCanvasLayer1Bitmap.name = "rCanvasLayer1Bitmap";
            rCanvasLayer2Bitmap.name = "rCanvasLayer2Bitmap";
            rCanvasDrawLayer.name = "rCanvasDrawLayer";
            rCanvasDrawShape.name = "rCanvasDrawShape";
            replayTimelineBox.name = "replayTimeBox";
            rReplayFOFOCursor.name = "rCursor";
            rReplayFOFOCursor.mouseEnabled = false;

            rCanvasPanel.graphics.beginFill(CANVAS_BG_COLOR);
            rCanvasPanel.graphics.drawRect(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);
            rCanvasPanel.graphics.endFill();

            rCanvasDrawLayer.addChild(rCanvasDrawLayerBitmap);
            rCanvasDrawLayer.addChild(rCanvasDrawShape);
            rCanvasDrawLayer.blendMode = "layer";//캔버스1이랑 알파 불투명도가 겹치지 않게 layer모드로 해줌

            rCanvasPanel.addChild(rCanvasLayer2Bitmap);
            rCanvasPanel.addChild(rCanvasLayer1Bitmap);
            rCanvasPanel.addChild(rCanvasDrawLayer);
            rCanvasPanel.scrollRect = new Rectangle(0,0,RCANVAS_WIDTH,RCANVAS_HEIGHT);//마스크 해줘서 판 밖으로 선나타나지 않도록함

            rCanvasPanel.x = Math.floor(-rCanvasPanel.width/2);
            rCanvasPanel.y = Math.floor(-rCanvasPanel.height/2);

            rCanvasAnchorPoint.addChild(rCanvasPanel);
            rCanvasAnchorPoint.visible = false;
            stage.addChild(rCanvasAnchorPoint);
            stage.addChild(replayTimelineBox);
            replayTimelineBox.x = 0;
        }

        public function initializeCanvas():void
        {
            var g:Graphics;

            canvasPanel.name = "canvasPanel";
            canvasAnchorPoint.name = "canvasAnchorPoint";
            canvasLayer1Bitmap.name = "canvasLayer1Bitmap";
            canvasLayer2Bitmap.name = "canvasLayer2Bitmap";
            canvasDrawLayer.name = "canvasDrawLayer";
            canvasDrawLayerChild.name = "canvasDrawShape";
            penSizePreviewCursor.name = "penSizeCursor";
            stageBG.name = "stageBG";
            canvasRefLayer.name = "canvasTraceLayer";
            canvasGrid.name = "canvasGrid";
            canvasFlashEffect.name = "canvasFlash";

            updateStageBGSize();

            penSizePreviewCursor.visible = false;

            lassoLayer1.name = "lassoBox1";
            lassoLayer1.addChild(lassoLayer1Bitmap);
            lassoLayer1.addChild(lassoDraw);
            lassoLayer1.visible = false;
            lassoLayer2.name = "lassoBox2";
            lassoLayer2.addChild(lassoLayer2Bitmap);
            lassoLayer2.visible = false;

            updateCanvasBGColorDrawMode(CANVAS_BG_COLOR);
            updateCanvasPanelMask(CANVAS_WIDTH,CANVAS_HEIGHT);

            updateStageBGColor();

            canvasRefLayer.alpha = refLayerLastAlpha;
            canvasRefLayer.addChild(canvasRefLayerBitmap);
            canvasDrawLayer.addChild(canvasDrawLayerBitmap);
            canvasDrawLayer.addChild(canvasDrawLayerChild);
            canvasDrawLayer.blendMode = "layer";//캔버스1이랑 알파 불투명도가 겹치지 않게 layer모드로 해줌

            rReplayFOFOCursor.visible = false;

            canvasPanel.addChild(canvasRefLayer);
            canvasPanel.addChild(canvasLayer2Bitmap);
            canvasPanel.addChild(lassoLayer2);
            canvasPanel.addChild(canvasLayer1Bitmap);
            canvasPanel.addChild(lassoLayer1);
            canvasPanel.addChild(canvasDrawLayer);
            canvasPanel.addChild(canvasGrid);
            canvasPanel.addChild(rReplayFOFOCursor);
            //canvasrotate가 중점으로 올수있게 위치를 절반으로세팅
            canvasPanel.x = Math.floor(-canvasPanel.width/2);
            canvasPanel.y = Math.floor(-canvasPanel.height/2);

            canvasAnchorPoint.addChild(canvasPanel);

            stage.addChild(stageBG);
            stage.addChild(eyedropperLens);
            stage.addChild(lassoMenuBox);
            stage.addChild(canvasAnchorPoint);
            stage.addChild(penSizePreviewCursor);
            stage.setChildIndex(canvasAnchorPoint,0);
            stage.setChildIndex(stageBG,0);
        }

        public function deleteTempDirectory():void
        {
            const file:File = File.applicationStorageDirectory.resolvePath("tmp");
            if(file.exists)
            {
                file.deleteDirectory(true);
            }
        }

        public function saveAllAppData():void
        {
            saveAppSatate();
            saveUndoData();
            saveReplayFrameData();
            saveRefLayerImage();
            saveMypPaletteList();
            saveScratchPadImage();
        }

        public function resetScrollBarX():void
        {
            if(sideBarScrollBar.visible === false)
            {
                sideBarScrollBar.x = 0;
            }
            else if(isRightSidebar)
            {
                sideBarScrollBar.x = canvasNavigatorBox.x-sideBarScrollBar.width+4;
            }
            else
            {
                sideBarScrollBar.x = sideBar.WIDTH;
            }
        }

        public function updateScrollBarHeight():void
        {
            updateScrollBarColorAndHeight();
            resetScrollBarX();
            checkScrollSetOutStage();
        }

        public function getSideBarBGHeight():Number
        {
            return (stage.stageHeight-topBar.BARSIZE*Global.getUIScale())/Global.getUIScale();
        }

        public function onWindowResize(e:Event):void
        {
            addTimerByName("windowResizeDelayTimer",0.2,false,function():void
            {
                const dx:Number = Math.round((stage.nativeWindow.width-lastAppWindowSize.x)/1.75);
                const dy:Number = Math.round((stage.nativeWindow.height-lastAppWindowSize.y)/1.75);

                if(isCaptureModeON)
                {
                    captureWindowMove.setTo(dx,dy);
                    fitCanvasToViewportMargin(true);
                    
                    if(!captureAreaManager.isFullImageCapture())
                    {
                        captureAreaManager.updateDrawArea(true);
                    }
                }
                else
                {
                    rCanvasAnchorPoint.x = rCanvasAnchorPoint.x+dx;
                    rCanvasAnchorPoint.y = rCanvasAnchorPoint.y+dy;
                    canvasAnchorPoint.x = canvasAnchorPoint.x+dx;
                    canvasAnchorPoint.y = canvasAnchorPoint.y+dy;
                    keepCnvasPanelInStage(isReplayModeON);
                }

                if(isLassoToolStarted)
                {
                    lassoMenuBox.x += dx;
                    lassoMenuBox.y += dy;
                    keepBoxInsideViewPort(lassoMenuBox);
                }

                if(isRefLayerMenuON)
                {
                    refLayerMenuBox.x += dx;
                    refLayerMenuBox.y += dy;
                    keepBoxInsideViewPort(refLayerMenuBox);
                }

                if(isAboutBoxOpened)
                {
                    updateAboutPanelCenterPos();
                }

                if(isReplayModeON)
                {
                    updateTimelineBoxPos(stage.stageWidth);
                    rFollowMouse.updateBounds();

                    if(isReplayCanvasFitToWindow)
                    {
                        fitReplayCanvasToWindow();
                    }
                }

                updateStageBGColor();
                topBar.updateTopbarBG(stage.stageWidth);
                topBar.updateTimerPos(stage.stageWidth);
                sideBar.updateSideBGSize(getSideBarBGHeight());

                if(isQuickSidebarActive)
                {
                    deactivateQuickSidebar();
                }
                else
                {
                    setSidebarDefaultPos();
                }
                
                updateScrollBarHeight();
                updateCanvasNaigatorCursor();

                if(loadMenuBox.visible === true)
                {
                    loadMenuBox.updateClickBlockerSize(stage.stageWidth,stage.stageHeight);
                }

                updateStageBGSize();
                checkFOFOPosition();
                updateBottomBarLayoutAndColor();
                lastAppWindowSize.setTo(stage.nativeWindow.width,stage.nativeWindow.height);

                if(isAppClosing)
                {
                    if(!hasTimer("pollTimerWaitWorkerStop"))
                    {
                        deleteTempDirectory();
                        saveAllAppData();
                        stage.nativeWindow.close();
                    }
                }
            });
        }

        public function updateCanvasScale(zoomValue:Number,isReplayMode:Boolean = false):void
        {
            if(!zoomValue) zoomValue = 1.0;
            if(zoomValue < 0.0) zoomValue = Math.abs(zoomValue);

            var xAnc:Sprite;

            if(!isReplayMode)
            {
                xAnc = canvasAnchorPoint;
                canvasZoomMultipler = zoomValue;

                if(!isCaptureModeON)
                {
                    penCursorManager.updateZoom(zoomValue);
                }
            }
            else
            {
                rCanvasZoomMultiplier = zoomValue;
                xAnc = rCanvasAnchorPoint;

                if(rAirBrushSize > 0)
                {
                    blurReplayCanvasByValue(rAirBrushSize);
                }
            }

            xAnc.scaleX = zoomValue;
            xAnc.scaleY = zoomValue;

            if(isCaptureModeON && isCaptureCanvasFlipped)
            {
                xAnc.scaleX = -xAnc.scaleX;
            }

            if(!isCaptureModeON)
            {
                canvasInfoBox.setZoom(zoomValue);
            }

            updateReplayCursorScale(zoomValue);
        }

        public function checkWindowMaximizedAndSaveAllData():void
        {
            if(stage.nativeWindow.displayState === "maximized")
            {
                lastAppWindowState = 1;
                stage.nativeWindow.restore();
            }
            else
            {
                lastAppWindowState = 0;
                deleteTempDirectory();
                saveAllAppData();
                stage.nativeWindow.close();
            }
        }

        public function onWindowClosingEvent(e:Event):void
        {
            isAppClosing = true;

            e.preventDefault();
            stage.nativeWindow.removeEventListener(Event.DEACTIVATE,onWindowDeactivate);
            removeInputEventCaptrueMode();
            removeInputEventsDrawMode();
            removeInputEventsReplayMode();
            realWorkingTimer.stop();
            
            if(canvasWindow !== null)
            {
                canvasWindow.visible = false;
            }

            if(isCaptureModeON === true)
            {
                handleExitCaptureMode();
            }

            if(isReplayStarted === true)
            {
                stopReplay();
            }

            if(isLassoToolStarted)
            {
                cancelLassoTool();
            }

            if(workerState === WORKER_STATE_RUNNING)
            {
                if(!hasTimer("pollTimerWaitWorkerStop"))
                {
                    stage.nativeWindow.title = "Waiting for remaining tasks...";
                    openLoadMenuBoxOnClosing();
                    addTimerByName("pollTimerWaitWorkerStop",WORKER_WAIT_INTERVAL,true,function():Boolean
                    {
                        if(workerState === WORKER_STATE_STOPPED)
                        {
                            removeTimer("pollTimerWaitWorkerStop");
                            checkWindowMaximizedAndSaveAllData();
                            return false;
                        }
                        return true;
                    }); 
                }
            }
            else 
            {
                checkWindowMaximizedAndSaveAllData();
            }
        }

        public function setAsTopChild(target:DisplayObject):void
        {
            const parent:DisplayObjectContainer = target.parent as DisplayObjectContainer;

            if(parent === null)
            {
                return;
            }

            if(parent.getChildIndex(target) === parent.numChildren-1)
            {
                return;
            }

            parent.setChildIndex(target,parent.numChildren-1);
        }

        //check box position함수는 요소 전체가 창에서 넘어가만 않게 하는거고
        public function keepBoxInsideViewPort(target:DisplayObject):void
        {
            const rect:Rectangle = target.getBounds(stage);

            if(rect.x < STAGE_LEFT_OFFSET) target.x = STAGE_LEFT_OFFSET;
            else if(rect.x+rect.width > stage.stageWidth-STAGE_RIGHT_OFFSET) target.x = stage.stageWidth-rect.width-STAGE_RIGHT_OFFSET;

            if(rect.y < STAGE_TOP_OFFSET) target.y = STAGE_TOP_OFFSET;
            else if(rect.y+rect.height > stage.stageHeight-STAGE_BOTTOM_OFFSET) target.y = stage.stageHeight-rect.height-STAGE_BOTTOM_OFFSET;
        }

        public function keepCnvasPanelInStage(replayMode:Boolean = false):void
        {
            var xAnc:Sprite;
            var xCanvas:Bitmap;

            if(replayMode)
            {
                xAnc = rCanvasAnchorPoint;
                xCanvas = rCanvasLayer1Bitmap;
            }
            else
            {
                xAnc = canvasAnchorPoint;
                xCanvas = canvasLayer1Bitmap;
            }

            const offset:int = 100; //최소 100픽셀 은 보여야함
            const bounds:Object = getBoundRect(xCanvas);
            const leftLimit:Number = STAGE_LEFT_OFFSET+offset;
            const rightLimit:Number = stage.stageWidth-(STAGE_RIGHT_OFFSET+offset);
            const topLimit:Number = STAGE_TOP_OFFSET+offset;
            const bottomLimit:Number = stage.stageHeight-(STAGE_BOTTOM_OFFSET+offset);

            //getbound는 보이는 그대로 사각형 끝점 좌표를 반환함
            const left:Number = bounds.left;
            const top:Number = bounds.top;
            const right:Number = bounds.right;
            const bottom:Number = bounds.bottom;

            //꼭지점이 경계offset을 넘어가면 넘어간 거리만큼 regpoint를 반대로 움직여줌
            if(left > rightLimit) xAnc.x -= left-rightLimit;
            else if(right < leftLimit) xAnc.x += leftLimit-right;

            if(bottom < topLimit) xAnc.y += topLimit-bottom;
            else if(top > bottomLimit) xAnc.y -= top-bottomLimit;
        }

        //캔버스 정 가운데로
        public function getStageCenterPos(mode:String):Point
        {
            const scale:Number = Global.getUIScale();
            const center:Point = new Point(0,0);
            var topBarOffset:Number = topBar.BARSIZE*scale;

            if(mode === "draw")
            {
                center.setTo((!isSidebarVisible) ? Math.floor(stage.stageWidth/2)
                             :(isRightSidebar)   ? Math.floor((stage.stageWidth-STAGE_RIGHT_OFFSET)/2)
                                                 : Math.floor(STAGE_LEFT_OFFSET+(stage.stageWidth-STAGE_LEFT_OFFSET)/2)
                            ,Math.floor(topBarOffset+(stage.stageHeight-topBarOffset)/2));
            }
            else if(mode === "replay")
            {
                topBarOffset = topBarOffset+replayTimelineBox.BARSIZE*scale;
                center.setTo(stage.stageWidth/2,Math.floor(topBarOffset+(stage.stageHeight-topBarOffset)/2));
            }
            else if(mode === "capture") 
            {
                center.setTo(stage.stageWidth/2,Math.floor(topBarOffset+(stage.stageHeight-topBarOffset)/2));
            }
            else
            {
                center.setTo(stage.stageWidth/2,stage.stageHeight/2);
            }

            return center;
        }

        public function centerCanvas(isReplayMode:Boolean = false, isCaptureMode:Boolean = false):void
        {
            var xAnc:Sprite;
            var xCanvas:Sprite;
            var w:Number;
            var h:Number;
            var center:Point = (isCaptureMode) ? getStageCenterPos("capture") :
                (isReplayMode) ? getStageCenterPos("replay") :
                getStageCenterPos("draw");

            if (isReplayMode)
            {
                xAnc = rCanvasAnchorPoint;
                xCanvas = rCanvasPanel;
                w = RCANVAS_WIDTH;
                h = RCANVAS_HEIGHT;
            }
            else
            {
                xAnc = canvasAnchorPoint;
                xCanvas = canvasPanel;
                w = CANVAS_WIDTH;
                h = CANVAS_HEIGHT;
            }

            xAnc.x = Math.floor(center.x);
            xAnc.y = Math.floor(center.y);
            xCanvas.x = Math.floor(-w / 2);
            xCanvas.y = Math.floor(-h / 2);

            if(!isReplayMode)
            {
                updateCanvasNaigatorCursor();
            }
        }

        public function clearCanvasReplayMode():void
        {
            const rect:Rectangle = new Rectangle(0,0,RCANVAS_WIDTH,RCANVAS_HEIGHT);

            rCanvasDrawShape.graphics.clear();
            rCanvasLayer1BitmapData.fillRect(rect,0);
            rCanvasLayer2BitmapData.fillRect(rect,0);
            rCanvasDrawLayerBitmapData.fillRect(rect,0);
        }

        public function clearCanvas():void
        {
            const rect:Rectangle = new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);

            if(canvasLayer1BitmapData) canvasLayer1BitmapData.fillRect(rect,0);
            if(canvasLayer2BitmapData) canvasLayer2BitmapData.fillRect(rect,0);
            if(canvasDrawLayerBitmapData) canvasDrawLayerBitmapData.fillRect(rect,0);
        }

        public function showReplaySpeedMouseHint():void
        {
            const timeStr:String = getReplayRemainingTimeString(rReplaySpeedMultipler,TOTAL_FRAME);
            const finalStr:String = STRING_PLAYBACK_SPEED+rReplaySpeedMultipler+timeStr;

            rSpeedLastHint = finalStr;
            showMouseHintTemp(finalStr);
        }
        
        //keyfunc
        public function adjustReplaySpeedByShortcut(increaseFlag:Boolean):void
        {
            const clacMax:Number = Math.floor(TOTAL_FRAME/(stage.frameRate*3));
            if(clacMax <= 0)
            {
                return;
            }

            const maxSpeed:Number = REPLAY_MAX_SPEED;
            var _rSpeed:Number = rReplaySpeedMultipler;

            if(increaseFlag)
            {
                _rSpeed += 1;
                if(_rSpeed > maxSpeed)
                {
                    _rSpeed = maxSpeed;
                }
            }
            else
            {
                _rSpeed -= 1;
                if(_rSpeed < 1)
                {
                    _rSpeed = 1;
                }
            }

            rReplaySpeedMultipler = _rSpeed;
            topBar.setSpeedButtonPosByValue(_rSpeed,maxSpeed);
            showReplaySpeedMouseHint();
        }

        public function startAdjustPlayBackSpeedByShortcut(increase:Boolean):void
        {
            startKeyRepeat(true,adjustReplaySpeedByShortcut,increase);
        }

        public function adjutReplaySpeedByMouse():void
        {
            const totalF:Number = TOTAL_FRAME;

            if(totalF <= stage.frameRate*3) // 3초 이내면 안함
            {
                return;
            }

            //setSpeedButtonPosByValue도 오프셋 수정해주어야함
            const minDist:Number = topBar.replaySpeedSlider.x+1.5;
            const maxDist:Number = minDist+topBar.replaySpeedSlider.width-2.5;
            const maxSpeed:Number = REPLAY_MAX_SPEED;
            var oldSpeed:Number;

            isPenSizeCursorInvisible = true;
            isMouseDragging = true;

            function setSpeed(mx:Number):void
            {
                var exp:Number = mx/maxDist;

                if(exp < 0)
                {
                    exp = 0;
                }
                else if(exp > 1)
                {
                    exp = 1;
                }

                var nowSpeed:Number = Math.floor(Math.pow(maxSpeed,exp));

                if(oldSpeed !== nowSpeed)
                {
                    oldSpeed = nowSpeed;
                    if(nowSpeed > maxSpeed)
                    {
                        nowSpeed = maxSpeed;
                    }
                    rReplaySpeedMultipler = nowSpeed;
                }
            }

            function moveButton(mx:Number):void
            {
                if(mx < minDist)
                {
                    mx = minDist;
                }
                else if(mx > maxDist)
                {
                    mx = maxDist;
                }

                topBar.replaySpeedSliderCursor.x = mx;
                setSpeed(mx);
                showReplaySpeedMouseHint();
                
                if(isReplayFinished === false)
                {
                    updateReplayPrograssText();
                }
            }

            function replaySpeedButtomUpEvent(e:MouseEvent):void
            {
                isMouseDragging = false;
                if(isReplayFinished === false)
                {
                    updateReplayPrograssText();
                }
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,replaySpeedButtomMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,replaySpeedButtomUpEvent);
            }

            function replaySpeedButtomMoveEvent(e:MouseEvent):void
            {
                moveButton(topBar.replaySpeedSliderWrapper.mouseX);
            }

            moveButton(topBar.replaySpeedSliderWrapper.mouseX);
            setSpeed(topBar.replaySpeedSliderWrapper.mouseX);
            showReplaySpeedMouseHint();

            stage.addEventListener(MouseEvent.MOUSE_MOVE, replaySpeedButtomMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,replaySpeedButtomUpEvent);
        }


        public function onKeyUpReplayMode(e:KeyboardEvent):void
        {
            checkKeyUp(e.keyCode);
        }

        public function onKeyDownReplayMode(e:KeyboardEvent):void//keydown2
        {
            const firstKey:uint = getFirstPressedKey();
            if(isMouseClicked || isRightMouseClicked || isLastKey(firstKey) || loadMenuBox.visible)
            {
                return;
            }

            if(isPressingShift())
            {
                checkSubKey(2,false,function(input:int):void
                {
                    switch(input)
                    {
                        case KEY.left:
                        case KEY.z:
                        case KEY.dot:
                        {
                            startKeyRepeat(true,moveToPreviousFrame);
                        }
                        break;

                        case KEY.right:
                        case KEY.x:
                        case KEY.comma:
                        {
                            startKeyRepeat(true,moveToNextFrame);
                        }
                        break;

                        case KEY.f5:
                        case KEY.f6:
                        {
                            resetZoomReplayMode();
                        }
                        break;
                    }
                });
                return;
            }
            else if(isPressingControl())
            {
                checkSubKey(2,true,function(input:int):void
                {
                    if(input === KEY.c || input === KEY.m)
                    {
                        enterCaptureMode();
                    }
                    else if(input === KEY.v || input === KEY.m)
                    {
                        if(isClipBoardButtonActivated)
                        {
                            tryLoadClipboardImage(false);
                        }
                    }
                });
                return;
            }

            updateLastKey(firstKey);

            switch(firstKey)
            {
                case KEY.left:
                case KEY.z:
                case KEY.dot:
                {
                    startKeyRepeat(true,moveToPreviousStep);
                }
                break;

                case KEY.right:
                case KEY.x:
                case KEY.comma:
                {
                    startKeyRepeat(true,moveToNextStep);
                }
                break;

                case KEY.up:
                case KEY.f:
                case KEY.h:
                {
                    startAdjustPlayBackSpeedByShortcut(true);
                }
                break;

                case KEY.down:
                case KEY.v:
                case KEY.n:
                {
                    startAdjustPlayBackSpeedByShortcut(false);
                }
                break;

                case KEY.backspace:
                case KEY.esc:
                {
                    exitReplayMode();
                }
                break;

                case KEY.f1:
                case KEY.f7:
                {
                    exitReplayMode();
                }
                break;

                case KEY.enter:
                case KEY.space:
                {
                    if(isReplayStarted === false) startReplay();
                    else stopReplay();
                }
                break;
            }
        }

        public function onKeyUpDrawMode(e:KeyboardEvent):void //keyup1
        {
            const keyCode:uint = e.keyCode;

            if(isLastKey(keyCode))
            {
                if(isMouseClicked === true)
                {
                    isKeyReleasedBeforeMouseUp = true;
                }
                else if(isKeyPressed())
                {
                    onKeyDownDrawMode(null);
                }
                else
                {
                    isLayerCheckKeyPressed = false;
                    if(lastTool > TOOL_NONE) selectLastUsedTool();

                    penCursorManager.check();
                }
            }

            if(!isKeyPressed())
            {
                resetLastKey();
            }

            if(!isPressingControl())
            {
                if(resizeCanvas.isResizing())
                {
                    resizeCanvas.exit(true);
                }
                if(resizeButtonR.visible)
                {
                    updateCanvasResizeButtonVisible(false);
                }
            }
        }

        public function checkSubKey(expectedLength:uint,updateFlag:Boolean,callback:Function):Boolean
        {
            if(getPressedKeyCount() !== expectedLength)
            {
                return false;
            }

            const subKey:uint = getLastKey();
            if(updateFlag)
            {
                updateLastKey(subKey);
            }

            if(callback !== null)
            {
                callback(subKey);
            }
            return true;
        }

        public function onKeyDownDrawMode(e:KeyboardEvent):void
        {
            if(isMouseClicked || isRightMouseClicked || isKeyReleasedBeforeMouseUp || isFillPenStarted
            || isPopUpWindowOpened())
            {
                return;
            }

            const firstKey:uint = getFirstPressedKey();
            const secondKey:int = getSecondPressedKey();

            //자툴이 nowkey를 쓰기 때문에 nowkey 리턴 이전에서 체크해야함
            if(isPressingControlShift())
            {
                //shift 누르고 ctrl 순서로 누를때 이전툴로 복원
                if(isSelectedTool(TOOL_LINE))
                {
                    selectLastUsedTool();
                }

                checkSubKey(3,true,function(input:int):void
                {
                    if(input === KEY.s)
                    {
                        openSaveFileBrowser(true);
                    }
                })
                return;
            }

            if(isPressingControl())
            {
                if(!checkSubKey(2,true,function(input:int):void
                {
                    if(input === KEY.s)
                    {
                        openSaveFileBrowser(false);
                    }
                    else if(input === KEY.o)
                    {
                        openLoadFileBrowser();
                    }
                    else if(input === KEY.c || input === KEY.comma)
                    {
                        enterCaptureMode();
                    }
                    else if(input === KEY.v || input === KEY.m)
                    {
                        if(isClipBoardButtonActivated)
                        {
                            tryLoadClipboardImage(false);
                        }
                    }
                }))
                {
                    if(resizeCanvas.isResizing() === false)
                    {
                        updateCanvasResizeButtonVisible(true);
                    }
                }

                return;
            }

            if(isPressingShift())
            {
                if(checkOpaSizeKeyDown(secondKey))
                {
                    return;
                }
                else if(checkPenOptionsKeyDown(secondKey))
                {
                    return;
                }
                else if(checkSubKey(2,true,function(input:int):void
                {
                    switch(input)
                    {
                        case KEY.s:
                        case KEY.k:
                        {
                            if(canvasAnchorPoint.rotation !== 0.0) resetRotationDrawMode();
                        }
                        return;

                        case KEY.w:
                        case KEY.i:
                        {
                            if(canvasZoomMultipler !== 1.0) resetZoomDrawMode();
                        }
                        return;

                        case KEY.d:
                        case KEY.j:
                        {
                            swapLayer();
                            showMouseHintTemp(getCanvasLayerSwappedHintString());
                        }
                        return;

                        case KEY.e:
                        case KEY.o:
                        {
                            if(toolOptionsBox.layerMergeButton.alpha === 1.0)
                            {
                                mergeImageIntoLayer2();
                                showMouseHintTemp("Layers has been merged to layer 2");
                            }
                        }
                        return;

                        case KEY.f2:
                        case KEY.f8:
                        {
                            if(gridGapValue !== 0)
                            {
                                resetGrid();
                            }
                        }
                        return;

                        case KEY.f5:
                        {
                            if(Global.getScaleIndex() !== 0)
                            {
                                Global.resetScaleIndex();
                                applyUIScale();
                            }
                        }
                        return;
                    }
                }))
                {
                    return;
                }
            }

            if(isTwoKeyPressed())
            {
                //지우개키 조합 따로 체크
                if(firstKey === KEY.d || firstKey === KEY.j)
                {
                    if(checkOpaSizeKeyDown(secondKey))
                    {
                        return;
                    }
                    else if(secondKey === KEY.s || secondKey === KEY.k)
                    {
                        if(isQuickSidebarActive === false)
                        {
                            activeQuickSideBar(true);
                        }
                        return;
                    }
                    else if(checkPenOptionsKeyDown(secondKey))
                    {
                        return;
                    }

                }
                else if(firstKey === KEY.s || firstKey === KEY.k)
                {
                    if(secondKey === KEY.d || secondKey === KEY.j)
                    {
                        if(isQuickSidebarActive === false) 
                        {
                            activeQuickSideBar(true);
                        }
                        return;
                    }
                }

                //필펜 조합 체크
                else if(firstKey === KEY.q || firstKey === KEY.o)
                {
                    if(checkOpaSizeKeyDown(secondKey))
                    {
                        return;
                    }
                    else if(checkPenOptionsKeyDown(secondKey))
                    {
                        return;
                    }
                }

                //레이어 따로 보기 조합 체크
                if(isLayerCheckKeyPressed === false)
                {
                    if(firstKey === KEY.w || firstKey === KEY.i)
                    {
                        if(secondKey === KEY.n1 || secondKey === KEY.n9)
                        {
                            isLayerCheckKeyPressed = true;
                            selectLayer1(false);
                            toggleLayer1Check();

                            if(lastTool > TOOL_NONE)
                            {
                                selectLastUsedTool();
                            }
                            return;
                        }
                        else if(secondKey === KEY.n2 || secondKey === KEY.n0)
                        {
                            isLayerCheckKeyPressed = true;
                            selectLayer2(false);
                            toggleLayer2Check();

                            if(lastTool > TOOL_NONE) 
                            {
                                selectLastUsedTool();
                            }
                            return;
                        }
                    }
                    else if(firstKey === KEY.n1 || firstKey === KEY.n9)
                    {
                        if(secondKey === KEY.w || secondKey === KEY.i)
                        {
                            isLayerCheckKeyPressed = true;

                            selectLayer1(false);
                            toggleLayer1Check();
                            return;
                        }
                    }
                    else if(firstKey === KEY.n2 || firstKey === KEY.n0)
                    {
                        if(secondKey === KEY.w || secondKey === KEY.i)
                        {
                            isLayerCheckKeyPressed = true;
                            selectLayer2(false);
                            toggleLayer2Check();
                            return;
                        }
                    }
                }
            }

            if(isLastKey(firstKey))
            {
                return;
            }
            updateLastKey(firstKey);

            if(checkOpaSizeKeyDown(firstKey))
            {
                return;
            }

            if(checkEtcKeyDown(firstKey))
            {
                return;
            }

            checkToolKeyDown(firstKey);
        }

        public function checkEtcKeyDown(keyCode:int):Boolean
        {
            switch(keyCode)
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
                    if(isLayer2Selected)
                    {
                        selectLayer1(false);
                    }
                    else
                    {
                        selectLayer1(canvasLayer2Bitmap.visible);
                    }

                    if(toolOptionsBox.layer2CheckedButton.visible)
                    {
                        toggleLayer2Check();
                    }

                    showMouseHintTemp("Layer 1 selected");
                }
                return true;

                case KEY.n2:
                case KEY.n0:
                {
                    if(!isLayer2Selected)
                    {
                        selectLayer2(false);
                    }
                    else
                    {
                        selectLayer2(canvasLayer1Bitmap.visible);
                    }
                    if(toolOptionsBox.layer1CheckedButton.visible)
                    {
                        toggleLayer1Check();
                    }

                    showMouseHintTemp("Layer 2 selected");
                }
                return true;

                case KEY.n3:
                case KEY.n8:
                {
                    if(toolOptionsBox.sharpLineButtonWrapper.alpha === 1.0)
                    {
                        toggleSharpLineByShortcut();
                    }
                }
                return true;

                case KEY.n4:
                case KEY.n7:
                {
                    if(isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILL_PEN))
                    {
                        togglePenAirBrushButtonShortCut();
                    }
                    else if(isSelectedTool(TOOL_ERASER))
                    {
                        toggleEraseAirBrushButtonShortCut();
                    }
                }
                return true;

                case KEY.n6:
                {
                    activeQuickSideBar(true);
                }
                break;

                return true;

                case KEY.x:
                case KEY.comma:
                {
                    startKeyRepeat(true,redo);
                }
                return true;

                case KEY.z:
                case KEY.dot:
                {
                    startKeyRepeat(true,undo);
                }
                return true;

                case KEY.tab:
                case KEY.backslash:
                {
                    if(isSidebarVisible)
                    {
                        hideSidebarPermanent();
                    }
                    else
                    {
                        showSidebarPermanent();
                    }
                }
                return true;
            }
            return false;
        }

        public function checkToolKeyDown(keyCode:int):void
        {
            if(isRefLayerMenuON)
            {
                if(keyCode === KEY.esc || keyCode === KEY.backspace)
                {
                    closeRefLayerMenu();
                    return;
                }
            }

            switch (keyCode)
            {
                case KEY.q:
                case KEY.o:
                {
                    setToolIndex(TOOL_PEN); //q키가 올라가면 펜툴로 바꿔지게
                    updateLastTool();
                    selectFillPenTool(true);
                }
                break;

                case KEY.t:
                {
                    if(isRefLayerMenuON)
                    {
                        closeRefLayerMenu();
                    }
                    else
                    {
                        openRefLayerMenu();
                    }
                }
                break;

                case KEY.a:
                case KEY.l:
                    mirrorCanvas();
                break;

                case KEY.c:
                case KEY.m:
                {
                    if(colorPickerBox.scratchPad.hitTestPoint(stage.mouseX,stage.mouseY))
                    {
                        if(colorPickerBox.scratchPad.visible)
                        {
                            showPickColorScratchPad();
                        }
                    }
                    else if(!isSelectedTool(TOOL_EYEDROPPER))
                    {
                        eyeDropperTool();
                    }
                }
                break;

                case KEY.r:
                case KEY.y:
                {
                    if(!isSelectedTool(TOOL_LASSO))
                    {
                        updateLastTool();
                        selectLassoTool();
                    }
                }
                break;

                case KEY.space:
                {
                    if(!isSelectedTool(TOOL_HAND))
                    {
                        updateLastTool();
                        setToolIndex(TOOL_HAND);
                    }
                }
                break;

                case KEY.d:
                case KEY.j:
                {
                    if(!isSelectedTool(TOOL_ERASER))
                    {
                        updateLastTool();
                        selectEraseTool();
                        updatePenSizeCursor();
                    }
                }
                break;

                case KEY.s:
                case KEY.k:
                {
                    if(!isSelectedTool(TOOL_ROTATE))
                    {
                        updateLastTool();
                        selectRotateTool();
                    }
                }
                break;

                case KEY.e:
                case KEY.u:
                {
                    if(!isSelectedTool(TOOL_MOVE))
                    {
                        updateLastTool();
                        selectMoveTool();
                    }
                }
                break;

                case KEY.w:
                case KEY.i:
                {
                    if(!isSelectedTool(TOOL_ZOOM))
                    {
                        updateLastTool();
                        selectZoomTool();
                    }
                }
                break;

                case KEY.shift:
                {
                    if(!isSelectedTool(TOOL_LINE))
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
                    if(topBar.newFileButton.alpha === 1.0 && !isSaveInProgress)
                    {
                        createNewFile(true);
                    }
                }
                break;
            }
            penCursorManager.check();
        }

        public function unblockMouseClickAfterDelay():void
        {
            addTimerByName("clickBlockTimer",0.15,false,function():void
            {
                isMouseClickBlocked = false;
            });
        }

        public function onWindowActive(e:Event):void
        {
            tryDisableIME();
            checkCanUseClipBoardButton();

            if(isAboutBoxOpened)
            {
                isMouseClickBlocked = true;
            }
            else
            {
                unblockMouseClickAfterDelay();
            }
        }

        public function onWindowDeactivate(e:Event):void
        {
            isMouseClickBlocked = true;
            resizeCanvas.exit(true);
            clearKeyBuffer();
            removeKeyRepeatEvents(null);
            removeTimer("pressholdtimer");

            if(isToolBox2Showing)
            {
                isRightMouseClicked = false;
                closeToolBox2();
            }

            if(!isSidebarVisible)
            {
                startHidingSidebarTemporary();
            }

            if(getTimer()-lastWindowDeactivateTime >= 3000
            && !isSaveInProgress
            && !isFileBrowserOpened
            && !isLoadPendingAfterSaving
            && !isUpdatePendingAfterSaving
            && !loadMenuBox.visible
            && rReplayImageCacheState !== REPLAY_IMAGE_CAHCHE_PROCESSING)
            {
                saveAllAppData();
                lastWindowDeactivateTime = getTimer();
            }

            if(isQuickSidebarActive && !isDeepUndoEnabled)
            {
                deactivateQuickSidebar();
            }

            if(numPadBox.visible)
            {
                closeNumpad();
            }

            if(numPadBox.isLCHSliderActive())
            {
                numPadBox.removeOKLCHMouseEvent();
            }

            if(colorPickerBox.scratchPad.isScratchStarted)
            {
                colorPickerBox.scratchPad.removeCheckMouseDistEvent();
            }

            selectLastUsedTool();
        }

        public function updateToolBoxMousePos(target:SimpleButton):void
        {
            //아이콘 중앙으로 맞추어줌
            if(!target)
            {
                return;
            }

            if(target.parent === toolBox2)
            {
                toolBox2.updateLastUsedToolPos(target.name);
            }
        }

        public function closeToolBox2(ignoreResizeButtonVisible:Boolean=false):void
        {
            if(!isToolBox2Showing)
            {
                return;
            }
            
            removeInputEventsToolBox2();
            isToolBox2Showing = false;
            toolBox2.visible = false;
            if(!ignoreResizeButtonVisible)
            {
                showCanvasResizeButtonVisibleDelay(false);
            }
        }

        public function onMouseDownToolBox2(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target)
            {
                return;
            }

            const targetName:String = target.name;

            switch(targetName)
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
                    startCanvasResizing(targetName);
                }
                break;

                default:
                {
                    if(toolBox2.visible && toolBox2.hitTestPoint(stage.mouseX, stage.mouseY))
                    {
                        updateToolBoxMousePos(toolBox2.toolPen);
                        updateLastTool();
                        handTool(false,false);
                    }
                    closeToolBox2();
                }
                break;
            }
        }
        //툴메뉴 오른쪽 클릭 땠을때
        public function onRightMouseUpToolBox2(e:MouseEvent):void
        {
            isPenSizeCursorInvisible = false;

            if(isLassoToolStarted === true)
            {
                closeToolBox2();
                return;
            }

            const target:SimpleButton = e.target as SimpleButton;

            if(!target || target.alpha < 1.0 || !isCursorInDrawArea())
            {
                closeToolBox2();
                return;
            }
            const targetName:String = e.target.name;

            if(targetName !== null && targetName.indexOf("tool") !== -1)
            {
                updateToolBoxMousePos(target);
            }
            
            switch(targetName)
            {
                case "toolQuickSidebar":
                {
                    activeQuickSideBar(false);
                }
                break;

                case "toolPen":
                {
                    selectPenTool();
                    updatePenSizeCursor();
                }
                break;

                case "toolFillPen":
                {
                    selectFillPenTool();
                    updatePenSizeCursor();
                }
                break;

                case "toolErase":
                {
                    selectEraseTool();
                    updatePenSizeCursor();
                }
                break;

                case "toolLine":
                {
                    selectLineTool();
                    updatePenSizeCursor();
                }
                break;

                case "toolLasso":
                {
                    selectLassoTool();
                }
                break;

                case "toolEyedropper":
                {
                    if(!isSelectedTool(TOOL_EYEDROPPER))
                    {
                        eyeDropperTool();
                    }
                }
                break;

                case "toolUndo":
                {
                    undo();
                }
                break;

                case "toolRedo":
                {
                    redo();
                }
                break;

                case "toolMirror":
                {
                    mirrorCanvas();
                }
                break;

                case "toolRefLayer":
                {
                    openRefLayerMenu();
                }
                break;
            }

            closeToolBox2();
        }

        public function move1PxLassoTool(command:int):void
        {
            var posX:Number = 0;
            var posY:Number = 0;

            if(command === LASSO_1PX_MOVE_UP) posY = -1;
            else if(command === LASSO_1PX_MOVE_DOWN) posY = 1;
            else if(command === LASSO_1PX_MOVE_LEFT) posX = -1;
            else if(command === LASSO_1PX_MOVE_RIGHT) posX = 1;

            const rotatedPoint:Point = rotatePoint(posX,posY,canvasAnchorPoint.rotation);

            lassoLayer1.x += rotatedPoint.x;
            lassoLayer1.y += rotatedPoint.y;
            lassoLayer2.x = lassoLayer1.x;
            lassoLayer2.y = lassoLayer1.y;
        }

        public function checkScrollSetOutStage():void
        {
            const scale:Number = Global.getUIScale();
            const limitTop:Number = Math.floor(-sideBarConstHeight+20.0);
            const limitBottom:Number = Math.floor(stage.stageHeight-STAGE_TOP_OFFSET-STAGE_BOTTOM_OFFSET-20.0*scale);

            if(sideBarScrollPanel.y < limitTop)
            {
                sideBarScrollPanel.y = limitTop;//*scale;
            }
            else if(sideBarScrollPanel.y*scale > limitBottom)
            {
                sideBarScrollPanel.y = limitBottom/scale;
            }

            scrollSetMovedY = sideBarScrollPanel.y;
        }

        public function resetSideBarPosition():void
        {
            sideBarScrollPanel.y = 0;
            scrollSetMovedY = sideBarScrollPanel.y;
            checkFOFOPosition();
        }

        public function startScrollSidebarByDrag():void
        {
            const scale:Number = Global.getUIScale();
            var clickY:Number = stage.mouseY;
            const alphaSave:Number = sideBarScrollBar.alpha;
            function onDragStart():void
            {
                sideBarScrollBar.alpha = 0.9;
            }

            function onMouseMove():void
            {
                const subY:Number = (clickY-mouseY)/scale;
                sideBarScrollPanel.y += subY*1.5;
                scrollSetMovedY = sideBarScrollPanel.y;
                clickY = mouseY;
            }

            function onMouseUp():void
            {
                sideBarScrollBar.alpha = alphaSave;
                checkScrollSetOutStage();
                scrollSetMovedY = sideBarScrollPanel.y;

                stage.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMove);
                stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUp);
                checkFOFOPosition();
            }

            startDragInteraction(onDragStart,onMouseMove,onMouseUp);
        }

        public function startScrollSidebarByMouseWheel(deltaY:Number):void
        {
            deltaY = Math.floor(deltaY*Global.getUIScale());
            sideBarScrollPanel.y += deltaY*1.5;
            scrollSetMovedY = sideBarScrollPanel.y;
            checkFOFOPosition();
            if(bottomBar.visible)
            {
                hideBottomHint();
            }
        }

        public function handleToolBoxMouseDown(target:DisplayObject):Boolean
        {
            if(isKeyPressed() && !isQuickSidebarActive || !target) return true;

            const targetName:String = target.name;

            switch(targetName)
            {
                case "toolRotate":
                {
                    rotateTool(false);
                }
                return true;

                case "toolUndo":
                {
                    startKeyRepeat(false,undo);
                    executeToolBoxClick(targetName);
                }
                return true;

                case "toolRedo":
                {
                    startKeyRepeat(false,redo);
                    executeToolBoxClick(targetName);
                }
                return true;

                case "toolZoomIn":
                case "toolZoomOut":
                case "toolPen":
                case "toolFillPen":
                case "toolErase":
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
                    executeToolBoxClick(targetName);
                }
                return true;
            }
            return false;
        }

        public function startCanvasResizing(targetName:String):void
        {
            isPenSizeCursorInvisible = true;
            penSizePreviewCursor.visible = false;
            showMouseHint(CANVAS_WIDTH+" x "+CANVAS_HEIGHT);
            resizeCanvas.start(targetName);
        }

        public function updateReplaySpeedSliderAlpha():void
        {
            if(REPLAY_MAX_SPEED === 1.0)
            {
                topBar.replaySpeedSliderWrapper.alpha = Global.OFFALPHA;
            }
            else
            {
                topBar.replaySpeedSliderWrapper.alpha = 1.0;
            }
        }

        public function updateReplayPrograssBarAndText():void
        {
            const totalFrame:Number = TOTAL_FRAME;
            const nowFrame:Number = rNowFrame;
            const trackBarWidth:Number = replayTimelineBox.trackBar.width;

            replayTimelineBox.prograssInfo.text = nowFrame+" / "+totalFrame;
            replayTimelineBox.prograssBar.width = (totalFrame === 0) ? 0 : trackBarWidth*(nowFrame/totalFrame);
        }

        public function clearKeyBuffer():void
        {
            KEY_BUFFER.length = 0;
            resetLastKey();
        }

        public function updateReplayCursorScale(zoom:Number):void
        {
            const z:Number = Global.getUIScale()/zoom;
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

            if(rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_READY)
            {
                removeInputEventsDrawMode();
                setAsTopChild(replayTimelineBox);
                updateTimelineBoxPos(stage.stageWidth);
                startGeneratingReplayCacheImage();
            }
            else
            {
                updateTotalFrameAndReplayMaxSpeedFor10Sec(getTotalFrame());
                //이미지 캐시 해주고 rPrevFrame 갱신해주고
                renderReplayFrame(undoManager.getRFileTotalFrame()-1,JUMP_FRAME_MANUAL);
                //실제 rPrevFrame으로 점프
                renderReplayFrame(rPrevFrame,JUMP_FRAME_MANUAL);
                applyReplayCanvasToDrawModeCanvas();
            }
        }

        public function startGeneratingReplayCacheImage():void
        {
            rReplayImageCacheState = REPLAY_IMAGE_CAHCHE_PROCESSING;

            if(!hasTimer("generatereplaycacheimagedelay"))
            {
                addTimerByName("generatereplaycacheimagedelay",0.1,false,function():void
                {
                    generateReplayCacheImage();
                });
            }
        }

        public function syncDrawCanvasWithReplayMode():void
        {
            canvasZoomMultipler = rCanvasZoomMultiplier;//줌배율도 공유
            canvasZoomIndex = rCanvasZoomIndex;
            canvasAnchorPoint.scaleX = rCanvasAnchorPoint.scaleX;
            canvasAnchorPoint.scaleY = rCanvasAnchorPoint.scaleY;
            canvasAnchorPoint.rotation = rCanvasAnchorPoint.rotation;
            canvasAnchorPoint.x = rCanvasAnchorPoint.x;
            canvasAnchorPoint.y = rCanvasAnchorPoint.y;
            rCanvasPanel.x = rCanvasPanel.x;
            rCanvasPanel.y = rCanvasPanel.y;
            setRcursorRotation(canvasAnchorPoint.rotation);
        }

        public function syncReplayCanvasWithDrawMode():void
        {
            rCanvasZoomMultiplier = canvasZoomMultipler;//줌배율도 공유
            rCanvasZoomIndex = canvasZoomIndex;
            rCanvasAnchorPoint.scaleX = canvasAnchorPoint.scaleX;
            rCanvasAnchorPoint.scaleY = canvasAnchorPoint.scaleY;
            rCanvasAnchorPoint.rotation = canvasAnchorPoint.rotation;
            rCanvasAnchorPoint.x = canvasAnchorPoint.x;
            rCanvasAnchorPoint.y = canvasAnchorPoint.y;
            rCanvasPanel.x = canvasPanel.x;
            rCanvasPanel.y = canvasPanel.y;
            setRcursorRotation(rCanvasAnchorPoint.rotation);
        }

        public function syncReplayCanvasImageWithDrawMode():void
        {
            rCanvasDrawShape.graphics.clear();
            rCanvasLayer1BitmapData = updateBitmapData(rCanvasLayer1BitmapData,canvasLayer1BitmapData,rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = updateBitmapData(rCanvasLayer2BitmapData,canvasLayer2BitmapData,rCanvasLayer2Bitmap);
            updateCanvasSizeReplayMode(canvasLayer1Bitmap.width,canvasLayer1Bitmap.height);
            updateCanvasBGColorReplayMode(CANVAS_BG_COLOR);
        }

        public function updateReplayTimeBarFromDrawMode():void
        {
            updateReplayPrograssText(true,rNowFrame);
            if(TOTAL_FRAME === 0)
            {
                resetReplayPrograssBarWidth();
            }
            else
            {
                updateReplayPrograssBarWidthByNowFame();
            }
        }

        public function enterDrawModeOnLoadFile():void
        {
             if(isCaptureModeON)
            {
                exitCaptureMode();
            }
            if(isReplayModeON)
            {
                exitReplayMode();
            }
        }

        public function exitReplayMode():void
        {
            if(rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_PROCESSING)
            {
                return;
            }

            removeInputEventsReplayMode();
            isReplayModeON = false;
            isPenSizeCursorInvisible = false;
            rCanvasAnchorPoint.visible = false;
            rReplayFOFOCursor.visible = false;
            replayTimelineBox.visible = false;
            canvasAnchorPoint.visible = true;
            penSizePreviewCursor.visible = true;
            if(isRefLayerMenuON === true) refLayerMenuBox.visible = true;
            if(isSidebarVisible === true) showSidebarPermanent();
            canvasPanel.addChild(rReplayFOFOCursor);
            setRcursorRotation(canvasAnchorPoint.rotation);
            if(mouseHint.isShowing()) hideMouseHint();
            replayTimelineBox.pauseButton.visible = false;
            setAsTopChild(replayTimelineBox);
            hideReplayDeleteRangeBar();
            setFitReplayCanvasToWindowOFF();
            updateStageOffset();
            if(isReplayStarted === true) stopReplay();
            updateCanvasNaigatorCursor();
            if(isTransparentPenColor) selectTransparentColor();
            else switchColorPickerModePen();
            updatePenSizeCursor();
            penCursorManager.check();
            updateTopBarModeIcons("draw");
            canvasInfoBox.setZoom(canvasZoomMultipler);
            updateReplayCursorScale(canvasZoomMultipler);

            isDeepUndoEnabled = lastDeepUndoEnabledFlag;
            if(rNowFrame !== lastReplayFrameOnDeepUndoStart)
            {
                //after로 해주는 이유는 캐쉬 안만들어줄라고
                renderReplayFrame(lastReplayFrameOnDeepUndoStart,JUMP_FRAME_NEXT);
            }
            clearRFrameTempCache();
            rReplayFOFOCursor.visible = false;
            addInputEventsDrawMode();
        }

        public function enterReplayMode():void
        {
            if(rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_PROCESSING)
            {
                return;
            }

            removeInputEventsDrawMode();
            isReplayModeON = true;
            isPenSizeCursorInvisible = true;
            canvasAnchorPoint.visible = false;
            rCanvasAnchorPoint.visible = true;
            replayTimelineBox.visible = true;
            penSizePreviewCursor.visible = false;
            replayTimelineBox.pauseButton.visible = false;
            replayTimelineBox.y = Math.floor(topBar.BARSIZE*Global.getUIScale()-4);
            setAsTopChild(replayTimelineBox);
            hideReplayDeleteRangeBar();

            if(numPadBox.visible)
            {
                closeNumpad();
            }

            if(mouseHint.isShowing())
            {
                hideMouseHint();
            }

            rReplayFOFOCursor.alpha = 1.0;
            rReplayFOFOCursor.visible = false;
            rCanvasPanel.addChild(rReplayFOFOCursor);
            setAsTopChild(rReplayFOFOCursor);
            setRcursorRotation(rCanvasAnchorPoint.rotation);
            updateStageOffset();
            removeTimer("rCursorOffAlphaAnimTimer");
            hideBottomHint();

            lastDeepUndoEnabledFlag = isDeepUndoEnabled;
            if(isDeepUndoEnabled) isDeepUndoEnabled = false;
            lastReplayFrameOnDeepUndoStart = rNowFrame;
            updateTotalFrameAndReplayMaxSpeedFor10Sec(getTotalFrame()); //최대 속도 계산
            updateReplayPrograssBarAndText();
            updateReplaySpeedSliderAlpha();

            //frame sum이 재계산된 maxframe을 넘어가면 리플레이 프레임이 넘어가기 때문에 끝난거임
            //그래서 캔버스 복사해주고 리플레이를 리셋해줌
            // if(rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_COMPLETE)
            // {
            //     if(CANVAS_WIDTH === RCANVAS_WIDTH && CANVAS_HEIGHT === RCANVAS_HEIGHT)
            //     {
            //         syncReplayCanvasWithDrawMode();
            //     }
            //     else
            //     {
            //         fitCanvasToViewportMargin();
            //         rCanvasZoomMultiplier = 1;
            //         rCanvasAnchorPoint.scaleX = 1;
            //         rCanvasAnchorPoint.scaleY = 1;
            //         rCanvasZoomIndex = canvasZoomMultiplerList.indexOf(rCanvasZoomMultiplier);
            //     }
            // }

            updateTimelineBoxPos(stage.stageWidth);
            rFollowMouse.updateBounds();
            updateReplayCursorScale(rCanvasZoomMultiplier);

            if(isRefLayerMenuON === true)
            {
                refLayerMenuBox.visible = false;
            }

            if(rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_READY)
            {
                removeInputEventsReplayMode();
                hideSidebarTemporary();
                updateTopBarModeIcons("replay");
                startGeneratingReplayCacheImage();
            }
            else if(rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_COMPLETE)
            {
                rDataReadFlag = false;
                updateReplayTimeBarFromDrawMode();
                fitCanvasToViewportMargin();
                // syncReplayCanvasImageWithDrawMode();

                //이거 안해주고 리플레이틀고 프레임 조작 안하고 재생하면 중간부터 되서 데이터가 꼬임
                isReplayFinished = true;

                if(undoDataIndex >= 0)
                {
                    rDataStartIndex = undoDataIndex+1;
                    rDataReadFlag = true;
                }
                else
                {
                    rDataStartIndex = 0;
                    rDataReadFlag = false;
                }

                updateDeleteReplayDataButtonsState();
                isReplaySlideShowMode = false;
                keepCnvasPanelInStage(true);
                hideSidebarTemporary();
                updateTopBarModeIcons("replay");
                addInputEventsReplayMode();
            }
        }

        public function onMouseDownReplayMode(e:MouseEvent):void //repdown1
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target || loadMenuBox.visible)
            {
                return;
            }

            const targetName:String = target.name;

            if(targetName)
            {
                if(targetName === "rCanvasPanel" || targetName === "rCanvasDrawLayer" || targetName === "stageBG")
                {
                    handTool(true,false);
                    return;
                }
                else if(targetName === "replayRepeatButton" || targetName === "replayFitToWindowButton")
                {
                    if(isKeyPressed())
                    {
                        return;
                    }

                    handleMouseClick(targetName);
                    return;
                }
            }

            if(target.alpha < 1.0)
            {
                return;
            }

            switch(targetName)
            {
                case "repNewFileButton":
                {
                    startPressHoldKey(topBar.repNewFileButton,"Creating a new file from this image..",prepareCreateNewFileFromReplayCanvas,createNewFileFromReplayCanvas,hideReplayDeleteRangeBar);
                }
                break;

                case "cutPrevDataButton":
                {
                    if(topBar.cutPrevDataButton.alpha === 1.0)
                    {
                        startPressHoldKey(topBar.cutPrevDataButton,"Deleting data..",prepareDeleteReplayDataBeforeCurrentFrame,deleteReplayDataBeforeCurrentFrame,hideReplayDeleteRangeBar);
                    }
                }
                break;

                case "superUndoButton":
                {
                    if(topBar.superUndoButton.alpha === 1.0)
                    {
                        startPressHoldKey(topBar.superUndoButton,"Deleting data..",prepareDeleteReplayDataAfterCurrentFrame,deleteReplayDataAfterCurrentFrame,hideReplayDeleteRangeBar);
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
                    onTimelineClick();
                }
                break;

                case "replayPrev":
                {
                    if(isPressingShift())
                    {
                        startKeyRepeat(true,moveToPreviousFrame);
                    }
                    else
                    {
                        startKeyRepeat(true,moveToPreviousStep);
                    }
                }
                break;

                case "replayNext":
                {
                    if(isPressingShift())
                    {
                        startKeyRepeat(true,moveToNextFrame);
                    }
                    else
                    {
                        startKeyRepeat(true,moveToNextStep);
                    }
                }
                break;

                case "timer":
                {
                    startPressHoldKey(topBar.timer,"Resetting the timer...",null, realWorkingTimer.reset,null);
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
                case "playButton":
                case "pauseButton":
                case "replayPrev":
                case "replayNext":
                {
                    if(isKeyPressed())
                    {
                        return;
                    }
                    handleMouseClick(targetName);
                }
                break;
            }
        }

        //키를 2개 이상 누르고 있을때 먼저 누른키를 떼면 다음키로 설정함
        public function onMouseUpDrawMode(e:MouseEvent):void //mouseup1
        {
            if(isKeyReleasedBeforeMouseUp)//단축키 떼고 마우스 땠을때 원래대로 돌림
            {
                isKeyReleasedBeforeMouseUp = false;

                if(KEY_BUFFER.length > 0)
                {
                    onKeyDownDrawMode(null);
                }
                else
                {
                    resetLastKey();
                    if(lastTool > TOOL_NONE) selectLastUsedTool();
                    penCursorManager.check();
                }
            }
        }

        public function setFitReplayCanvasToWindowOFF():void
        {
            isReplayCanvasFitToWindow = false;
        }

        public function setFitReplayCanvasToWindowON():void
        {
            isReplayCanvasFitToWindow = true;
            fitReplayCanvasToWindow();
        }

        public function fitReplayCanvasToWindow():void
        {
            addTimerByName("rFitZoomedDelayTimer",0.15,false,function():void
            {
                fitCanvasToViewportMargin(false,true);
                rCanvasZoomIndex = getNearZoomIndex(rCanvasZoomMultiplier);
                rCanvasZoomMultiplier = canvasZoomMultiplerList[rCanvasZoomIndex];
            });
        }

        public function onRightMouseDownReplayMode(e:MouseEvent):void
        {
            if(isMouseClicked || isKeyPressed() || !e.target || loadMenuBox.visible) return;

            const targetName:String = e.target.name;

            if(targetName && targetName.indexOf("canvas") !== -1 || targetName === "stageBG")
            {
                if(isReplayCanvasFitToWindow) resetZoomReplayMode();
                else setFitReplayCanvasToWindowON();
                return;
            }

            switch(targetName)
            {
                case "replayPrev": startKeyRepeat(true,moveToPreviousFrame); break;
                case "replayNext": startKeyRepeat(true,moveToNextFrame); break;
                case "replayRotateButton" : resetRotationReplayMode(); break;
                case "replayZoomInButton" :
                case "replayZoomOutButton" : resetZoomReplayMode(); break;
            }
        }

        public function openToolBox2():void
        {
            isPenSizeCursorInvisible = true;
            penSizePreviewCursor.visible = false;

            var pos:Point = toolBox2.getLastUsedToolPos();
            const scale:Number = Global.getUIScale();

            toolBox2.x = Math.floor(stage.mouseX-pos.x*scale);
            toolBox2.y = Math.floor(stage.mouseY-pos.y*scale);
            toolBox2.visible = true;
            toolBox2.alpha = 1.0;
            isToolBox2Showing = true;
            showCanvasResizeButtonVisibleDelay(true);
            setAsTopChild(toolBox2);
            addInputEventsToolBox2();

            addTimerByName("toolBox2HideCheckTimer",0.1,true,function():Boolean
            {
                if(!isToolBox2Showing)
                {
                    return false;
                }

                if(resizeButtonR.visible)
                {
                    if(!toolBox2.hitTestPoint(stage.mouseX,stage.mouseY))
                    {
                        toolBox2.alpha = 0.7;
                    }
                    else if(toolBox2.alpha < 1.0)
                    {
                        toolBox2.alpha = 1.0;
                    }
                }
                return true;
            })
        }

        public function onRightMouseDownDrawMode(e:MouseEvent):void //rdown1
        {
            if(isMouseClicked || isPressingControl() || isQuickSidebarActive
            || isFillPenStarted || isSelectedTool(TOOL_EYEDROPPER) || (isRefLayerMenuON && refLayerMenuBox.hitTestPoint(mouseX,mouseY))
            || loadMenuBox.visible || topBar.gridButtonWrapper.visible || numPadBox.visible)
            {
                return;
            }

            if(isKeyPressed())
            {
                return;
            }

            const targetName:String = e.target.name;
            switch(targetName)
            {
                case "saveButton":
                {
                    openSaveFileBrowser(true);
                }
                break;

                case "dpiButton":
                {
                    if(Global.getScaleIndex() !== 0)
                    {
                        Global.resetScaleIndex();
                        applyUIScale();
                    }
                }
                break;

                case "toolZoomIn":
                case "toolZoomOut":
                {
                    if(canvasZoomMultipler !== 1.0) resetZoomDrawMode();
                }
                break;

                case "gridButton":
                {
                    if(gridGapValue !== 0)
                    {
                        hideBottomHint();
                        resetGrid();
                    }
                }
                break;

                case "toolRotate":
                {
                    if(canvasAnchorPoint.rotation !== 0.0)
                    {
                        resetRotationDrawMode();
                    }
                }
                break;

                case "sideBarScrollBar":
                {
                    resetSideBarPosition();
                }
                break;

                default:
                {
                    if(isCursorInDrawArea())
                    {
                        if(isToolBox2Showing && !isDeepUndoEnabled)
                        {
                            closeToolBox2();
                        }
                        else
                        {
                            openToolBox2();
                        }
                    }
                }
                break;
            }
        }

        public function handleControlBoxMouseDown(target:DisplayObject):Boolean
        {
            if(isToolBox2Showing)
            {
                return true;
            }

            const targetName:String = target.name;

            switch(targetName)
            {
                case "penSmoothSliderWapper":
                {
                    if(nowTool > 4)
                    {
                        return true;
                    }
                    startPenSmootingAdjustment();
                    ensureDrawingToolSelected(true);
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
                    ensureDrawingToolSelected(true);
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
                    if(!isSelectedTool(TOOL_FILL_PEN))
                    {
                        selectPenSizeButton(targetName);
                        ensureDrawingToolSelected(true);
                    }
                }
                return true;

                case "shapeRect":
                {
                    if(!isSelectedTool(TOOL_FILL_PEN))
                    {
                        selectPenShapeButton(true);
                        ensureDrawingToolSelected(true);
                    }
                }
                return true;

                case "shapeCircle":
                {
                     if(!isSelectedTool(TOOL_FILL_PEN))
                    {
                        selectPenShapeButton(false);
                        ensureDrawingToolSelected(true);
                    }
                }
                return true;


                case "layer1CheckedButton":
                case "layer1UncheckedButton":
                {
                    selectLayer1(false);
                    toggleLayer1Check();
                }
                return true;

                case "layer2CheckedButton":
                case "layer2UncheckedButton":
                {
                    selectLayer2(false);
                    toggleLayer2Check();
                }
                return true;

                case "layer1SelectButton":
                {
                    if(isLayer2Selected)
                    {
                        selectLayer1(false);
                    }
                    else
                    {
                        selectLayer1(canvasLayer2Bitmap.visible);
                    }

                    if(toolOptionsBox.layer2CheckedButton.visible)
                    {
                        toggleLayer2Check();
                    }
                }
                return true;

                case "layer2SelectButton":
                {
                    if(!isLayer2Selected)
                    {
                        selectLayer2(false);
                    }
                    else
                    {
                        selectLayer2(canvasLayer1Bitmap.visible);
                    }

                    if(toolOptionsBox.layer1CheckedButton.visible)
                    {
                        toggleLayer1Check();
                    }
                }
                return true;

                case "layerMergeButton":
                case "layerSwapButton":
                {
                    if(isToolBox2Showing || target.alpha < 1.0)
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
                    if(toolOptionsBox.sharpLineButtonWrapper.alpha === 1.0)
                    {
                        ensureDrawingToolSelected(true);
                        toggleSharpLine(!isSharpLineON);
                    }
                }
                return true;

                case "airBrushButtonWrapper":
                case "airBrushOFFButton":
                case "airBrushONButton":
                case "airBrushText":
                {
                    if(toolOptionsBox.airBrushButtonWrapper.alpha === 1.0)
                    {
                        ensureDrawingToolSelected(true);
                        if(isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILL_PEN))
                        {
                            togglePenAirBrushButton(!isPenAirBrushON);
                        }
                        else if(isSelectedTool(TOOL_ERASER))
                        {
                            toggleEraseAirBrushButton(!isEraserAirBrushON);
                        }
                    }
                }
                return true;
            }

            return false;
        }

        public function startColorHistoryBoxDragging():void
        {
            const index:int =  getHistoryIndexByMousePos();

            function onDragStart():void
            {
                myPaletteDragClickedIndex = index+90;
                myPaletteDragClickedColor = myPalettePreset[index+90];
                myPaletteClickPos.setTo(colorPickerBox.mouseX,colorPickerBox.mouseY);
                myPaletteMovePos.setTo(colorPickerBox.mouseX,colorPickerBox.mouseY);
            }

            function onMouseMove():void
            {  
                if(Point.distance(myPaletteClickPos,myPaletteMovePos) >= 4)
                {
                    if(myPaletteDragStarted === false)
                    {
                        myPaletteDragStarted = true;
                        colorPickerBox.updateDragColor(myPaletteDragClickedColor,myPaletteColorWidth,myPaletteColorHeight);
                        updateMyPaletteList(myPaletteDragClickedIndex);
                        updateHistoryList(myPaletteDragClickedIndex);
                    }

                    colorPickerBox.updateDragColorPosToCursor();
                }
                else
                {
                    myPaletteMovePos.setTo(colorPickerBox.mouseX,colorPickerBox.mouseY);
                }
            }

            function onMouseUp():void
            {
                if(myPaletteDragStarted === true)
                {
                    myPaletteDragStarted = false;

                    if(colorPickerBox.myPaletteBox.hitTestPoint(mouseX,mouseY))
                    {
                        const putIndex:int = getMyPaletteIndexByMousePosLimitBound();
                        const colorSave:* = myPalettePreset[putIndex];

                        myPalettePreset[putIndex] = myPaletteDragClickedColor;
                        myPalettePreset[myPaletteDragClickedIndex] = (colorSave === null || colorSave === undefined) ? null:colorSave;
                        myPalettePreset.removeAt(myPaletteDragClickedIndex);

                        updateMyPaletteList(myPaletteDragClickedIndex);
                    }
                }

                updateHistoryList();
                colorPickerBox.removeDragColor();
            }



            if(index >= 0 && !isSelctedHistoryColorEmpty(index))
            {
                startDragInteraction(onDragStart,onMouseMove,onMouseUp);
            }
        }

        public function startMyPaletteBoxDragging():void
        {
            var index:int =  getMyPaletteIndexByMousePos();

            function onDragStart():void
            {
                if(index >= 0 && !isSelctedColorEmpty(index))
                {
                    myPaletteDragClickedIndex = index;
                    myPaletteDragClickedColor = myPalettePreset[index];
                    myPaletteClickPos.setTo(colorPickerBox.mouseX,colorPickerBox.mouseY);
                    myPaletteMovePos.setTo(colorPickerBox.mouseX,colorPickerBox.mouseY);
                }
            }

            function onMouseMouse():void
            {
                if(Point.distance(myPaletteClickPos,myPaletteMovePos) >= 4)
                {
                    if(myPaletteDragStarted === false)
                    {
                        removeTimer("addColorMyPaletteDelayTimer");
                        myPaletteDragStarted = true;
                        colorPickerBox.updateDragColor(myPaletteDragClickedColor,myPaletteColorWidth,myPaletteColorHeight);
                        updateMyPaletteList(myPaletteDragClickedIndex);
                    }

                    colorPickerBox.updateDragColorPosToCursor();
                }
                else
                {
                    myPaletteMovePos.setTo(colorPickerBox.mouseX,colorPickerBox.mouseY);
                }
            }

            function onMouseUp():void
            {
                if(myPaletteDragStarted === true)
                {
                    myPaletteDragStarted = false;
                    
                    const putIndex:int = getMyPaletteIndexByMousePosLimitBound();
                    const colorSave:* = myPalettePreset[putIndex];

                    myPalettePreset[putIndex] = myPaletteDragClickedColor;
                    myPalettePreset[myPaletteDragClickedIndex] = (colorSave === null || colorSave === undefined) ? null:colorSave;
                    updateMyPaletteList();
                }

                colorPickerBox.removeDragColor();
            }

            if(index >= 0 && !isSelctedColorEmpty(index))
            {
                startDragInteraction(onDragStart,onMouseMouse,onMouseUp);
            }
        }

        public function handleColorPickerBoxClick(targetName:String):void
        {
            function onMouseUpColorPickerBox(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpColorPickerBox);

                const upTargetName:String = e.target.name;

                if(targetName === upTargetName)
                {
                    switch(upTargetName)
                    {
                        case "currentColor":
                        {
                            selectCurrentColor(isColorPickerModeBG);
                            ensureDrawingToolSelected(false);
                        }
                        break;

                        case "penColorButton":
                        {
                            if(isColorPickerModeBG)
                            {
                                switchColorPickerModePen();
                            }
                        }
                        break;

                        case "paperColorButton":
                        {
                            if(!isColorPickerModeBG)
                            {
                                switchColorPickerModeBG();
                            }
                        }
                        break;

                        case "colorHistoryBox":
                        {
                            selectHistoryColor();
                        }
                        break;

                        case "myPaletteBox":
                        {
                            if(myPaletteDragStarted === false)
                            {
                                selectMyPaletteColor();
                            }
                        }
                        break;

                        case "transColorButton":
                        {
                            if(colorPickerBox.transColorButton.alpha === 1.0 && isTransparentPenColor === false)
                            {
                                selectTransparentColor();
                                ensureDrawingToolSelected(false);
                            }
                        }
                        break;

                        case "swapPositionButton":
                        {
                            isColorPickerBoxPositionSwapped = !isColorPickerBoxPositionSwapped;
                            colorPickerBox.swapColorBoxPositions(isColorPickerBoxPositionSwapped);
                        }
                        break;

                        case "drawrPresetButton":
                        {
                            removeTimer("clearScratchPadTimer");
                            activeColorPreset(1);
                        }
                        break;

                        case "tegakiPresetButton":
                        {
                            removeTimer("clearScratchPadTimer");
                            activeColorPreset(2);
                        }
                        break;
                    }
                }
            }
            stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUpColorPickerBox);
        }

        public function handleColorPickerBoxMouseDown(target:DisplayObject):Boolean
        {
            if(isToolBox2Showing || (isKeyPressed()
                                && !isSelectedToolPenOrLine()
                                && !isSelectedTool(TOOL_ERASER)
                                && !isSelectedTool(TOOL_FILL_PEN)))
            {
                return false;
            }

            const targetName:String = target.name;


            if(targetName === "myPaletteBox")
            {
                if(myPalettePresetType === 0)
                {
                    startMyPaletteBoxDragging();
                }
            }
            else if(targetName === "colorHistoryBox")
            {
                if(myPalettePresetType === 0)
                {
                    startColorHistoryBoxDragging();
                }
            }

            switch(targetName)
            {
                case "scratchPad":
                {
                    colorPickerBox.scratchPad.drawReady(penSize,penColor,penAlpha,penIsSquare,pickColor);
                }
                return true;

                case "svBox":
                {
                    if(colorPickerBox.scratchPad && !colorPickerBox.scratchPad.visible)
                    {
                        startSVColorSelection();
                    }
                }
                return true;

                case "hueColor":
                {
                    if(colorPickerBox.scratchPad && !colorPickerBox.scratchPad.visible)
                    {
                        startHueColorSelection();
                    }
                }
                return true;

                case "myPaletteBox":
                {
                    if(myPalettePresetType === 0)
                    {
                        startSelectOrAddColorMyPalette();
                    }
                    else
                    {
                        handleColorPickerBoxClick(targetName);
                    }
                }
                return true;

                case "myPaletteButton":
                {
                    selectOrResetMyPalette();
                }
                return true;

                case "drawrPresetButton":
                case "tegakiPresetButton":
                {
                    startScratchPadResetTimer(target);
                    handleColorPickerBoxClick(targetName);
                }
                return true;

                case "penColorButton":
                case "paperColorButton":
                case "colorHistoryBox":
                case "transColorButton":
                case "currentColor":
                case "swapPositionButton":
                {
                    handleColorPickerBoxClick(targetName);
                }
                return true;

                default:

                return false;
            }

            return false;
        }

        public function onRightMouseDownLassoTool(e:MouseEvent):void
        {
            if(!isLassoToolStarted)
            {
                return;
            }

            const target:DisplayObject = e.target as DisplayObject;
            if(!target) return;

            const targetName:String = target.name;

            if(targetName === "toolZoom"
            || targetName === "toolZoomIn"
            || targetName === "toolZoomOut")
            {
                if(canvasZoomMultipler !== 1.0) resetZoomDrawMode();
            }
            else if(targetName === "toolRotate")
            {
                if(canvasAnchorPoint.rotation !== 0.0) resetRotationDrawMode();
            }
        }

        public function onRightMouseUpLassoTool(e:MouseEvent):void
        {
            if(!isLassoToolStarted || isMouseClicked)
            {
                return;
            }

            const target:DisplayObject = e.target as DisplayObject;
            if(!target) return;

            const targetName:String = target.name;

            if(targetName === "toolZoom"
            || targetName === "toolZoomIn"
            || targetName === "toolZoomOut"
            || targetName === "toolRotate")
            {
                return;
            }

            if(lassoMenuBox.hitTestPoint(stage.mouseX,stage.mouseY) === false || targetName === "lassoOK")
            {
                applyLassoImageToCanvas();
                return;
            }

            if(targetName === "lassoRotate")
            {
                if(lassoLayer1.rotation !== 0)
                {
                    lassoLayer1.rotation = 0;
                    lassoLayer2.rotation = 0;
                }
            }
            else if(targetName === "lassoResize")
            {
                if(lassoLayer1.scaleY !== 1.0)
                {
                    lassoLayer1.scaleX = (isLassoMirrorON) ? -1.0 : 1.0;
                    lassoLayer1.scaleY = 1.0;
                    lassoLayer2.scaleX = lassoLayer1.scaleX;
                    lassoLayer2.scaleY = lassoLayer1.scaleY;
                }
            }
        }

        public function onMouseUpLassoTool(e:MouseEvent):void
        {
            if(getPressedKeyCount() === 1 && getFirstPressedKey() === KEY.space)
            {
                updateLastKey(KEY.space);
                isLassoMenuHiddenTemp = true;
                setToolIndex(TOOL_HAND);
            }
        }

        public function onMouseDownLassoTool(e:MouseEvent):void
        {
            if(isRightMouseClicked)
            {
                return;
            }

            const target:DisplayObject = e.target as DisplayObject;
            if(!target)
            {
                return;
            }

            const targetName:String = target.name;

            if(isCursorInDrawArea() && lassoMenuBox.hitTestPoint(stage.mouseX,stage.mouseY) === false)
            {
                if(isLassoMenuHiddenTemp)
                {
                    lassoMenuBox.visible = false;
                    if(isSelectedTool(TOOL_HAND)) handTool(false,false);
                    else if(isSelectedTool(TOOL_ZOOM)) zoomTool();
                    else if(isSelectedTool(TOOL_ROTATE)) rotateTool(false);
                }
                else
                {
                    startLassoImageMove();
                }
            }
            else
            {
                switch(targetName)
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
                        startCanvasMoveByCanvasNavigator(false);
                    }
                    break;

                    case "navCursor":
                    {
                        startCanvasMoveByCanvasNavigator(true);
                    }
                    break;

                    case "lassoMenuMoveButton":
                    {
                        setAsTopChild(lassoMenuBox);
                        startBoxDrag(lassoMenuBox);
                    }
                    break;

                    case "sideBarScrollBar":
                    {
                        startScrollSidebarByDrag();
                    }
                    break;

                    case "toolZoomIn":
                    {
                        zoomInCanvas(true,false);
                    }
                    break;

                    case "toolZoomOut":
                    {
                        zoomInCanvas(false,false);
                    }
                    break;

                    case "toolRotate":
                    {
                        lassoMenuBox.visible = false;
                        isLassoMenuHiddenTemp = true;
                        rotateTool(false);
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
                        handleMouseClick(targetName);
                    break;

                    default:
                    break;
                }
            }
        }
        public function handleSidebarMouseDown(target:DisplayObject):Boolean
        {
            const targetName:String = target.name;

            if(sideBarScrollPanel.hitTestPoint(stage.mouseX, stage.mouseY))
            {
                if(targetName === "navStageBG"
                || targetName === "navBitmapBG"
                || targetName === "navLayer1Bitmap"
                || targetName === "navLayer2Bitmap")
                {
                    startCanvasMoveByCanvasNavigator(false);
                    return true;
                }
                else if(targetName === "navCursor")
                {
                    startCanvasMoveByCanvasNavigator(true);
                    return true;
                }
                else if(handleColorPickerBoxMouseDown(target) && !isKeyPressed())
                {
                    return true;
                }
                else if(handleControlBoxMouseDown(target) && (isSelectedToolPenOrLine() || isSelectedTool(TOOL_ERASER)))
                {
                    return true;
                }
                else if(toolBox.alpha === 1.0 && target.alpha === 1.0 && handleToolBoxMouseDown(target))
                {
                    return true;
                }
            }
            else if(isSidebarVisible === false)
            {
                if(sideBar.visible && !sideBar.hitTestPoint(stage.mouseX,stage.mouseY) && isCursorInDrawArea())
                {
                    startHidingSidebarTemporary();
                    return true;
                }
            }
            return false;
        }

        public function onMouseDownDrawMode(e:MouseEvent):void
        {
            if(isFillPenStarted || loadMenuBox.visible
            || topBar.gridButtonWrapper.visible || numPadBox.visible)
            {
                return;
            }

            const target:DisplayObject = e.target as DisplayObject;
            if(!target)
            {
                return;
            }

            const targetName:String = target.name;

            if(sideBar.visible)
            {
                if(sideBarScrollPanel.hitTestPoint(stage.mouseX,stage.mouseY) && handleSidebarMouseDown(target))
                {
                    return;
                }
            }

            if(isQuickSidebarActive)
            {
                if(targetName === "sideBarScrollBar")
                {
                    startScrollSidebarByDrag();
                }
                return;
            }

            switch (targetName)
            {
                case "saveButton": //아래 3개는 topbar메뉴에 가면 안됨 mouseuphandler랑 같이 연동되서 여기서 해주어야함
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
                    if(isToolBox2Showing || isKeyPressed() || e.target.alpha < 1.0)
                    {
                        return;
                    }

                    handleMouseClick(targetName);
                }
                return;

                case "replaySpeedSliderWrapper":
                {
                    //grid 에서 불러줬을때 캔버스에 안무것도 못하게
                }
                return;

                case "refClearImageButton":
                {
                    startPressHoldKey(refLayerMenuBox.refClearImageButton,"Erasing reference image...",null,startReflayerClear,null);
                }
                return;

                case "timer":
                {
                    startPressHoldKey(topBar.timer,"Resetting the timer...",null, realWorkingTimer.reset,null);
                }
                return

                case "newFileButton":
                {
                    if(topBar.newFileButton.alpha === 1.0 && !isSaveInProgress)
                    {
                        createNewFile(false);
                    }
                }
                return;

                case "penSmoothSliderWapper":
                {
                    if(nowTool > 4)
                    {
                        return;
                    }
                    startPenSmootingAdjustment();
                }
                return;

                case "resizeButtonR":
                case "resizeButtonD":
                case "resizeButtonL":
                case "resizeButtonU":
                {
                    startCanvasResizing(targetName);
                }
                return;

                case "sideBarScrollBar":
                {
                    startScrollSidebarByDrag();
                }
                return;

                case "refRotateImageButton":
                {
                    setAsTopChild(refLayerMenuBox);
                    startRefLayerRotation();
                }
                return;

                case "refMoveImageButton":
                {
                    setAsTopChild(refLayerMenuBox);
                    startRefLayerImageDrag();
                }
                return;

                case "refResizeImageButton":
                {
                    setAsTopChild(refLayerMenuBox);
                    startRefLayerImageScale();
                }
                return;

                case "refOpacitySliderWrapper":
                {
                    setAsTopChild(refLayerMenuBox);
                    startRefLayerOpacityDrag();
                }
                return;

                case "refLayerMenuMoveButton":
                {
                    startBoxDrag(refLayerMenuBox);
                }
                return;

                case "dragDropFileBG":
                return;
            }

            //캔버스 영역 밖에서는 해주지 않음
            if(isCursorInDrawArea() && !isMouseClickBlocked)
            {
                switch (nowTool)
                {
                    case TOOL_PEN: if(isToolEnabledByLayerUnChecked()) penTool(true); break;
                    case TOOL_FILL_PEN: if(isToolEnabledByLayerUnChecked()) fillPenTool.start(); break;
                    case TOOL_ERASER: if(isToolEnabledByLayerUnChecked()) penTool(false); break;
                    case TOOL_LINE: if(isToolEnabledByLayerUnChecked()) lineTool(true); break;
                    case TOOL_LASSO: lassoToolFunction.start(); break;
                    case TOOL_MOVE: moveTool(); break;
                    //캔버스 조작
                    case TOOL_ZOOM: zoomTool(); break;
                    case TOOL_HAND: handTool(false,false); break;
                    case TOOL_ROTATE: rotateTool(false); break;
                }
            }
        }

        // public var printdeepLevel:int = 0;
        // public function printArray(obj:Object,deepKey:String=""):void
        // {
        //     var _print:Function = trace;
        //     var blank:String="";
        //     if(printdeepLevel === 0) _print('--- PRINT START --- ');
        //     else
        //     {
        //         const count:int = printdeepLevel;
        //         for(var b:int=0; b<count; b++)
        //         {
        //             blank += "   ";
        //         }
        //         _print(blank+'> index['+deepKey+']');
        //     }

        //     _print(blank+'{');
        //     for(var i:String in obj)
        //     {
        //         if(obj[i] !== null && typeof obj[i] === "object" && obj[i].length > 0)
        //         {
        //             ++printdeepLevel;
        //             printArray(obj[i],i);
        //         }
        //         else
        //         {
        //             _print(blank+'| '+i+' : ' + obj[i]);
        //         }
        //     }
        //     _print(blank+'}');
        //     --printdeepLevel;
        //     if(printdeepLevel < 0) printdeepLevel = 0;
        // }

        // public function testFuncTime():void
        // {
        //     const loop:int = 100000;
        //     function func1():void
        //     {

        //     }

        //     function func2():void
        //     {

        //     }

        //     function func3():void
        //     {

        //     }

        //     var _print:Function = trace;
        //     var i:int=0;
        //     var nt:int = getTimer();
        //     while(i < loop)
        //     {
        //         func1();

        //         i++;
        //     }

        //     _print("time 1",getTimer()-nt);

        //     i = 0;
        //     nt = getTimer();
        //     while(i < loop)
        //     {
        //         func2();
        //         i++;
        //     }

        //     _print("time 2",getTimer()-nt);

        //     i = 0;
        //     nt = getTimer();
        //     while(i < loop)
        //     {
        //         func3();
        //         i++;
        //     }

        //     _print("time 3",getTimer()-nt);
        // }
    }
 }
