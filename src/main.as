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
    import flash.text.TextField;
    import flash.text.TextFieldType;
    import flash.text.TextFormat;
    import flash.ui.Mouse;

    //import end
    public class main extends Sprite
    {
        private const APP_VERSION:Number = 26.10;
        private const APP_DATA_VERSION:Number = 2584;
        private var NEW_VERSION:String = APP_VERSION+"";
        private var UPDATE_FILE:File = File.applicationStorageDirectory.resolvePath("updateTmpFile.air");

        //단축키 keycode 리스트
        private const KEY:Object = {
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
                                    }
        //툴 번호 미리 지정
                    ,TOOL_NONE:int = 0
                    ,TOOL_PEN:int = (1 << 0) // 1
                    ,TOOL_ERASE:int = (1 << 1) // 2
                    ,TOOL_LINE:int = (1 << 2) // 4
                    ,TOOL_FILL_PEN:int = (1 << 3) // 8
                    // ,TOOL_SCAN_FILL:int = (1 << 4) // 16
                    ,TOOL_HAND:int = (1 << 5) // 32
                    ,TOOL_LASSO:int = (1 << 6) // 64
                    ,TOOL_SPUIT:int = (1 << 7) // 128
                    ,TOOL_ZOOM:int = (1 << 8) // 256
                    ,TOOL_ROTATE:int = (1 << 9) // 512
                    ,TOOL_MOVE:int = (1 << 10) // 1024

                    ,JUMP_FRAME_PLAY:int = (1 << 0)
                    ,JUMP_FRAME_ONCE:int = (1 << 1)
                    ,JUMP_FRAME_BEFORE:int = (1 << 2)
                    ,JUMP_FRAME_AFTER:int = (1 << 3)

                    ,CANVAS_MIN_SIZE:Number = 100
                    ,CANVAS_MAX_SIZE:Number = 2000

                    ,COLOR_DARK:uint = 0x323232//어두운색
                    ,COLOR_MID_DARK:uint = 0x535353//0x5B5B5B//중간 어두운색
                    ,COLOR_MID_BRIGHT:uint = 0xB8B8B8//중간 밝은색
                    ,COLOR_BRIGHT:uint = 0xF0F0F0//0xECEAE7//밝은색

                    ,BUTTON_OFF_ALPHA:Number = Math.round(0.25*256)/256

                    ,REPLAY_FASTEST_LIMIT_TIME:Number = 60
                    ,REPLAY_MAKE_JUMPIMAGE_INTERVAL:Number = 10000
                    ,REPLAY_JUMPIMAGE_CACHE_INTERVAL:Number = 700
                    ,REPLAY_MAX_SPEED:Number = 200

                    ,GRID_GAP:uint = 10
                    ,GRID_NORMAL_COLOR:uint = 0x808080

                    ,LASSO_SHARP_DATA:Array =
                    [
                        [[
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
                        ],3]
                    ]
                    ,KEY_REPEAT_DELAY:Number = 0.3
                    ,KEY_REPEAT_INTERVAL:Number = 0.06
                    ,COMMAND_CTRL:int = (1 << 0)
                    ,COMMAND_SHIFT:int = (1 << 1)
                    ,COMMAND_CTRL_SHIFT:int = (1 << 2)
                    ,LASSO_1PX_MOVE_UP:int= (1 << 0)
                    ,LASSO_1PX_MOVE_DOWN:int = (1 << 1)
                    ,LASSO_1PX_MOVE_LEFT:int = (1 << 2)
                    ,LASSO_1PX_MOVE_RIGHT:int = (1 << 3)
                    ,CUT_FRAME_NONE:int = 0
                    ,CUT_FRAME_SUPER_UNDO:int = (1 << 0)
                    ,CUT_FRAME_RE_RECORD:int = (1 << 1)
                    ,CUT_FRAME_DELETE_FRONT:int = (1 << 2)
                    ,WORKER_WAIT_INTERVAL:Number = 0.5
                    ,STRING_TITLE_FOFOPAINT:String = " - FOFO PAINT"
                    ,STRING_PREPARE_REPLAY_DATA:String = "Preparing replay data.. "
                    ,STRING_PLAYBACK_SPEED:String = "Playback speed x"
                    ,STRING_ONEMORE_CLICK_TO_OK:String = "One more click to OK"
                    ,STRING_WAIT_PROCESSING_DONE:String = "Close the app after processing done"
                    ,STRING_CAPTURE_OK:String = " _ Reset [right-click]"
                    ,STRING_MERGE_LASSO_IMAGE_TO_TRACE:String = "Merge selected area\ninto reference layer"
                    ,STRING_MERGE_CANVAS_IMAGE_TO_TRACE:String = "Merge canvas image\ninto reference layer"
                    ,STRING_RIGHT_CLICK_TO_RESET:String = "Reset [right-click]"
                    ,STRING_CUSTOM_COLOR_HINT:String = "OK [enter, space, esc, right-click]\nMove text cursor [a-d, j-l, arrow key, tab, shift+tab]\nAdjust value [w-s, i-k]"
                    ,STRING_TRACE_IMAGE_OPACITY:String = "Image opacity "
                    ,STRING_HOLD_NSEC:String = " <- hold 2 sec"
                    ,WORKER_STATE_STOPPED:int = 0
                    ,WORKER_STATE_INIT:int = (1 << 0)
                    ,WORKER_STATE_RUNNING:int = (1 << 1)
                    ,ZERO_POINT:Point = new Point(0,0)
                    ,KEY_BUFFER:Array = [] //정식 키 다운 눌러준 상태에서 다른 키가 눌러져 있으면 여기다가 저장
                    ;

        private var  RESIZE_BUTTON_COLOR:uint = 0xA5A5A5
                    ,STAGE_BG_COLOR:uint = 0xCCCCCC
                    ,CANVAS_BG_COLOR:uint = 0xFFFFFF
                    ,RCANVAS_BG_COLOR:uint = 0xFFFFFF
                    ,CANVAS_WIDTH:Number = 600
                    ,CANVAS_HEIGHT:Number = 390
                    ,RCANVAS_WIDTH:Number = 600
                    ,RCANVAS_HEIGHT:Number = 390
                    ,STAGE_TOP_OFFSET:Number = 0 //창 상하좌우 여백
                    ,STAGE_LEFT_OFFSET:Number = 0
                    ,STAGE_BOTTOM_OFFSET:Number = 0
                    ,STAGE_RIGHT_OFFSET:Number = 0
                    ,TOTAL_FRAME:Number = 0//rdata+file 프레임 전부 합친거
                    ,REPLAY_FASTEST_TOTAL_TIME:Number = 0 //최고 배속으로 돌렸는데도 총 재생시간이 60초 이상이면 올려줌
                    ,REPLAY_SLOWDRAW_ACTIVE_SPEED:Number = 60 //이 배속 이상일경우 doDrawSlowEvent를 걸어줌
        //프레임 타이머 변수
        private const miniTimer:fofoTimer = new fofoTimer(stage)
                    ,addTimer:Function = miniTimer.add
                    ,addTimerByName:Function = miniTimer.addByName
                    ,hasTimer:Function = miniTimer.hasTimer
                    ,removeTimer:Function = miniTimer.remove
                    ;
        //element
        private const canvas1Bitmap:Bitmap = new Bitmap(canvas1BitmapData,"auto",true)
                    ,canvas11Bitmap:Bitmap = new Bitmap(canvas11BitmapData,"auto",true)
                    ,canvas2Bitmap:Bitmap = new Bitmap(canvas2BitmapData,"auto",true)
                    ,resizeButtonR:canvasResizeButton = new canvasResizeButton()//캔버스 리사이즈 하는 버튼
                    ,resizeButtonD:canvasResizeButton = new canvasResizeButton()
                    ,resizeButtonL:canvasResizeButton = new canvasResizeButton()
                    ,resizeButtonU:canvasResizeButton = new canvasResizeButton()
                    ,regPoint:Sprite = new Sprite()//회전 스프라이트 부모
                    ,canvasPanel:Sprite = new Sprite()//회색 부분을 제외한 그리기 영역 추가
                    ,canvas2:Sprite = new Sprite() //캔버스 2번 임시로 그려주는 캔버스 버퍼?
                    ,canvas2Draw:Shape = new Shape() //실제로 선을 긋는 div
                    ,lassoBox1:Sprite = new Sprite()//선택한 이미지를 그려주고 확대 축소등 조작
                    ,lassoBox2:Sprite = new Sprite()//선택한 이미지를 그려주고 확대 축소등 조작
                    ,penSizeCursor:Shape = new Shape() //펜사이즈 미리 보기
                    ,captureAreaRect:Shape = new Shape()//스크린샷 박스 미리보기 그려줌
                    ,toolBox:toolButtons = new toolButtons()
                    ,toolBox2:toolButtons2 = new toolButtons2()
                    ,fillPenBox:fillPenButtons = new fillPenButtons()
                    ,rotateCursorBox:rotateCursor = new rotateCursor()//회전이 얼마나 됐는지 표시
                    ,lassoMenu:lassoButtons = new lassoButtons()//라소툴 버튼
                    ,lassoDraw:Shape = new Shape() //라소 영역 선 그려주는 쉐이프
                    ,topBar:topMenu = new topMenu()
                    ,spuitZoomCursor:spuitMag = new spuitMag()
                    ,toolTipBox:toolTipBoxSet = new toolTipBoxSet()//도움말 버튼
                    ,hintBox:toolTipBoxSet = new toolTipBoxSet()
                    ,hintHorverCursor:Shape = new Shape()//도움말 버튼 커서
                    ,hint:Object = cHint()
                    ,stageBG:Sprite = new Sprite() //드래그 불러오기가 stage공백에서는 안되서 수동으로 전체바탕으로 만들어줌
                    ,aboutPanel:aboutBox = new aboutBox()

                    ,loadMenuBox:loadBox = new loadBox()
                    ,controlBox:controlMenu = new controlMenu()
                    ,pickerBox:colorPickerBox = new colorPickerBox()
                    ,previewBox:previewPanel = new previewPanel()
                    ,appInfoBox:appInfoBar = new appInfoBar()
                    ,numPadBox:numPadButtons = new numPadButtons()
                    ,sideBar:sidePanel = new sidePanel()
                    ,fofo:fofoBottomBox = new fofoBottomBox()
                    ,sideBarScrollBar:Sprite = new Sprite()
                    ,sideBarScrollSet:Sprite = new Sprite()
                    ,canvasFlash:Sprite = new Sprite()
                    ,capStampFontListBox:capStampFontList = new capStampFontList()
                    ;

        private var  canvas1BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,canvas11BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,canvas2BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,canvas2ClipRect:Rectangle = new Rectangle() // 그려준 영역 만큼만 캔버스bitmap1에 그려주는 사각형
                    ,lassoBMPsub:Bitmap = new Bitmap()//아래레이어
                    ,lassoBMP:Bitmap = new Bitmap()
                    ,appResetFlag:Boolean = false
                    ,rMirrorON:Boolean = false //대칭 켜지면 올려줌
                    ,mirrorON:Boolean = false
                    ,mirrorCommandReady:Boolean = false //미러 커맨드를 넣어줄지 말지 결정
                    ,zoomList:Array = [0.125,0.25,0.5,0.75,1.0,1.50,2.0,3.0,4.0,6.0,8.0,12.0,16.0,24.0,32.0]
                    ,zoomed:Number = 1.0
                    ,zoomedIndex:int = 3
                    ,rzoomedIndex:int = 3
                    ,mouseClickON:Boolean = false //클릭하면 올려줌
                    ,rightMouseClickON:Boolean = false //클릭하면 올려줌
                    ,mouseDragON:Boolean = false//툴을 계속 클릭한채로 움직이면 topmenu의 힌트가 안켜지도록 함
                    ,clickBlockOnWindowActiveFlag:Boolean = false //알탭 하고나서 창활성화 되면 일정시간동안 작동하지 않게함
                    ,nowTool:int = 1 //현재 툴 번호
                    ,oldTool:int = TOOL_NONE //툴백업
                    ,nowKey:uint = 0//단축키 누른거 여기다가 저장
                    ,keyWaitMouseUp:Boolean = false //키 떼기 전에 마우스 먼저 떼주었을때 플래그 올려줌
                    ,penAlpha:Number = 1.0 //펜 변수
                    ,penColor:uint = 0x000000
                    ,penColorTransparentFlag:Boolean = false // 펜 컬러 투명 켜졌을때 올려줌
                    ,airBrushClipRectOffectInc:Array = [0,4,2,2,0,0,0,-2,-5,-5,-10,-16,-43]
                    ,penSizeList:Array = [0,1,2,3,4,5,7,10,13,18,30,45,80]
                    ,penAlphaList:Array = [0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0]
                    ,penCursorSize:Number = 3
                    ,penCursorShape:Boolean = false
                    ,penSize:uint = 3
                    ,penSizeIndex:uint = 3
                    ,penAlphaIndex:uint = 9
                    ,penShape:Boolean = false //false 이면 원 true 이면 사각형
                    ,penSmoothValue:Number = 0 //펜 손떨방 플래그
                    ,penSmoothSlideValue:int = 0 //펜 손떨방 플래그
                    ,penSmoothSlideTotal:Number = 20 //손떨방 총 단계
                    ,sharpLineON:Boolean = false //0.5픽셀어긋나게 안하고 완전히 정확하게 할때씀
                    ,fillPenON:Boolean = false //채우기 펜 플래그
                    ,fillPenStarted:Boolean = false //채우기 펜 시작됨
                    ,subLayerON:Boolean = false
                    ,checkedLayer:int = 0 //레이어가 체크되면 저장해줌
                    ,layerSwappedFlag:Boolean = false //1<->2 번호 바뀌는 힌트 써주려고 만듬
                    ,airBrushON:Boolean = false
                    ,airBrushSizeDrawMode:int = 0
                    ,airBrushSizeReplayMode:int = 0
                    ,airBrushSizeReplayMode2:int = 0
                    ,eraseOddOffset:Number = 0//지우개 변수
                    ,eraseSize:uint = 12
                    ,eraseSizeIndex:uint = 8
                    ,eraseShape:Boolean = false
                    ,eraseAlpha:Number = 1.0
                    ,eraseAlphaIndex:uint = 9
                    ,eraseAirBrushON:Boolean = false
                    ,penListShapeFlag:Boolean = false //펜 리스트에서 펜 모양 버튼 눌러줄때 툴이랑 상관없이 바꿔줌, 펜 미리보기 할때 필요
                    ,penLastUpdateInfo:Array = [null,null] //updatePenSizeCursor 중복 사용 방지를 위해서 마지막 크기 저장해놓고 같으면 건너뙴
        //컬러픽커 관련 변수
                    ,hsvColorArr:Vector.<Number> = new Vector.<Number> (3,true) //hue컬러 다른 함수들이랑 통신하기 위해서 전역으로 만들어줌
                    ,pickerMode:uint = 1 //1이면 펜컬러 2이면 배경색
                    ,pickerModeResetFlag:Boolean = false // 배경색 선택하고 나서 커서가 사이드바를 나가면 리셋해주는 이벤트를 올려주는 플래그
                    ,pickerOpaClicked:Boolean = false //피커박스에서 투명도 조절했을때 올려줌 mouse out 이벤트 하나만 작동되게 할라고
                    ,pickerHSVButtonMousePoslast:Point = new Point()
                    ,pickerBoxSwapPositionFlag:Boolean = false //위치 바뀌면 올려줌
                    ,pickerIgnoreHistoryColor:* = null //히스토리 색 등록 할때 여기에 등록된 색은 등록 안하게함

        //툴메뉴 관련 변수
        //어디 클릭했는지 위치 저장해줘서 다음에 켰을때 그 위치에서 툴메뉴가 켜지게끔 해줌
                    ,toolBox2ON:Boolean = false //툴박스가 오른쪽 클릭으로 켜졌을때 올려줌
        //undo 관련변수
                    ,undoIndex:int = 0 //undo redo할때 무슨 이미지인지 알려주는 undoImageData의 포인터 인덱스임
                    ,undoDelFlag:Boolean = false //undo하고 나서 addundo가 되었을때 뒷부분 데이터 전부 날려주는 플래그
                    ,readyAddUndoFlag:Boolean = false //선을 그어줄대 선전체가 캔버스 바깥쪽에 있을수도 있으니까 이걸 판단해줌
        //lasso 관련 변수
                    ,lassoToolON:Boolean = false //라소툴로 영역 선택하면 올려줌
                    ,lassoStartData:Array = [] //이 값이랑 비교해서 달라진게 있으면 ok할때 적용해줌
                    ,lassoMirrorON:Boolean = false //라소 mirror클릭했을때 마다 반전해줌
                    ,lassoMenuTempOFF:Boolean = false//툴 고정되어서 라소 선택하고 줌툴 클릭했을때 메뉴 잠시 없애주는 플래그
                    ,lassoPointSave:Array = []
                    ,lassoCopyON:Boolean = false //lasso 복사 누르면 올려줌
                    ,lassoBitmapdataSave:BitmapData //copy나 취소했을때 원래대로 돌려주는 이미지
                    ,lassoBitmapdataSubSave:BitmapData
                    ,lassoLayerCommand:Array = null//스왑 머지 순서 저장해줌
                    ,lassoSwapButtonClicked:Boolean // 스왑 버튼 클릭할때마다 true false로 변경해줌

        //window resize 관련 변수
                    ,lastWindowSize:Point = new Point() //창크기 조절 얼마나 됐을지 비교할때 마지막 크기 창크기 저장
        //save load 관련 변수
                    ,saveOneTime:Boolean = false //세이브 버튼 여러번 눌러서 데이터 계속 쓰여지는거 방지
                    ,saveFileName:String = getNewFileName() //세이브 파일 저장후에 이름을 이쪽에다가 보관해서 계속 그 이름으로 저장할수있게함
                    ,saveFilePath:String = saveFileName//파일 저장경로로 계속 저장 초기에는 filename이랑 똑같게 해줌
                    ,saveContinue:Boolean = false//한번 저장후에 다른이름으로 저장하기 전까지는 똑같은 이름으로 저장
                    ,rImgData:ByteArray = new ByteArray() //리플레이 데이터 저장해줄때 쓰는 바이트 배열 전역으로 돌려서 새로운 객체 하나만 생성하도록함
                    ,rImgData1:ByteArray = new ByteArray()
                    ,lastImgData:ByteArray = new ByteArray()
                    ,lastImgData1:ByteArray = new ByteArray()
                    ,traceImgData:ByteArray = new ByteArray()
                    ,replayDataBytes:ByteArray = new ByteArray()

        //키 오래누름 관련 변수
                    ,longKeyCountDown:Number = 0
                    ,loneKeyFrameCount:int = 0

        //컬러 히스토리 관련 변수
                    ,myPaletteSaveBeforeAddColor:Array = [-1,0]
                    ,myPaletteViewAllMode:Boolean = false //전체로 보면 올려줌
                    ,myPaletteLimitTotal:int = 100
                    ,myPaletteColorWidth:Number = 17//Math.floor(pickerBox.svBoxWidth/myPaletteLimit)//히스토리 개별 색깔 가로 크기
                    ,myPaletteColorHeight:Number = 17
                    ,myPaletteClickPos:Point = new Point() //컬러 히스토리 클릭하면 위치 넣어줌
                    ,myPaletteMovePos:Point = new Point() //컬러 히스토리 드래그할때 움직이는 포인트 넣어줌
                    ,myPaletteDragClickedColor:uint = 0 //드래그 준비 클릭한 컬러 저장해줌
                    ,myPaletteDragClickedIndex:int = -1 //드래그 준비 클릭한 컬러 인덱스 저장
                    ,myPaletteDragStarted:Boolean = false //컬러 히스토리 드래그 시작하면 올려줌
                    ,myPalettePresetType:int = 0 //타입저정 0 마이팔레트, 1 drawr, 2 tegaki
                    ,myPalettePreset:Array = []
                    ,myPaletteDrawrPreset:Array = [0xFFFFFF,0xC0C0C0,0xFF3B21,0xFFBD16,0xF5F30F,0xA5E975,0x71DBFD,0xFA80F9,null    ,null
                                                  ,0x000000,0x808080,0x8E0000,0xFFCC99,0x877D30,0x008F47,0x313BCD,0xC02E97,0x3F037E,null]
                    ,myPaletteTegakiPreset:Array = [0xA80515,0xA80515,0x800000,0x800000,0x4B3D38,0x4B3D38,0x313768,0x313768,0x394C44,0x394C44
                                                    ,0xF1D0D0,0xF1D0D0,0xF1E1D7,0xF1E1D7,0xEAE5D5,0xEAE5D5,0xD5E9F3,0xD5E9F3,0xD0EBDE,0xD0EBDE]
                    ,myPaletteSaveColorBeforeOtherType:Array = [0,0,0xA80515]

        //툴팁 관련 변수
                    ,toolTipHint:String = "" //topbar관련 힌트 여기 저장

        //리플레이 관련 변수
        private const appDataFile:File = File.applicationStorageDirectory.resolvePath("appdata"+(APP_DATA_VERSION.toString()))
                    ,scratchDataFile:File = File.applicationStorageDirectory.resolvePath("scratchdata")
                    ,undoDataFile:File = File.applicationStorageDirectory.resolvePath("undodata")
                    ,repFile:File = File.applicationStorageDirectory.resolvePath("repdata")
                    ,rJumpImageFolder:File = File.applicationStorageDirectory.resolvePath("imagecache")
        private var repFileTemp:File//파일을 저장하거나 불러올때 씀
                    ,rJumpImageFrameDataFile:File = File.applicationStorageDirectory.resolvePath("jumpframedata")
                    ,myPaletteListFile:File = File.applicationStorageDirectory.resolvePath("mypalettedata")
                    ,rFirstImageFile:File = rJumpImageFolder.resolvePath("0")
                    ,rFileStream:FileStream = new FileStream()//함수들을 왔다갔다 해야해서 전역으로 하나,
                    ,rregPoint:Sprite = new Sprite()//회전 스프라이트 부모
                    ,rcanvasPanel:Sprite = new Sprite()
                    ,rcanvas2:Sprite = new Sprite()
                    ,rcanvas2Draw:Shape = new Shape()
                    ,replayTimeBox:replayTimeBar = new replayTimeBar()
                    ,rcanvas1Bitmap:Bitmap = new Bitmap(rcanvas1BitmapData,"auto",true)
                    ,rcanvas11Bitmap:Bitmap = new Bitmap(rcanvas11BitmapData,"auto",true)
                    ,rcanvas2Bitmap:Bitmap = new Bitmap(rcanvas2BitmapData,"auto",true)
                    ,rCursor:tinyCursor = new tinyCursor(); //재생할때 틀어주는 작은 마우스

        private var rcanvas1BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,rcanvas11BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,rcanvas2BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,rcanvas2ClipRect:Rectangle = new Rectangle() //갱신된 부분만 그려주는 거
                    ,rcanvas2ClipRect2:Rectangle = new Rectangle() //갱신된 부분만 그려주는 거
                    ,replayStartON:Boolean = false //리플레이 시작버튼 여러번 누르는거 방지
                    ,playbackFinished:Boolean = true //리플레이가 자연히 끝났을때 올렽주는 플래그 가장 처음에 캔버스 싹쓸이 하기 위해서 넣어줌.
                    ,replayEndWithCanvasFitWindow:Boolean = false //리플레이가 follow cursor옵션으로 캔버스 작게 축소되서 끝났을때
                    ,replayModeON:Boolean = false //이건 모드 자체 껐다 켰다
                    ,replayModeGettingOFF:Boolean = false // 리플레이 모드를 꺼주는 중일때 올려줌 이미지 캐쉬 만드는거 방지 하려고
                    ,replayRepeatON:Boolean = true //리플레이 반복 켜기 끄기

                    ,rDataBuffer:Array = []
                    ,rData:Array = [] //rDataBuffer가 이쪽으로 이동되고 undo image data갯수에 똑같이맞추어줌
                    ,rDataFrame:Array = [] //rdata안에 몇프레임이 들어있는지 저장

        //아래 변수들은 전역으로 돌려야, 플레이 중간에 끊어도 계속 플레이 시킬 수 있음.
                    ,rLastBytePosition:Number = 0 //fs position 저장
                    ,rFileCutBytes:Number = 0 //super undo에서 파일 잘라줄때 필요함
                    ,rIndex:int = 0 //rData에서만씀 rData 스크로크 뭉치 인덱스
                    ,rIndexStart:int = 0 //리플레이에서 프레임 스캡을 앞부분으로 해줄때 rdata를 읽는 부분이면 현재 undoindex부분 부터 읽게 인덱스를 올려줌
                    ,rSubLayerSave:Boolean = false //리플레이 실행할때 이걸로 비교해서 캔버스 스왑해줌
                    ,rBGColorSave:uint = RCANVAS_BG_COLOR //load replay에서 씀
                    ,rDataReadFlag:Boolean = true //rData읽을때는 true, r file 읽을때는 false
                    ,rSpeed:Number = 1 //리플레이 속도 for루프로 2번씩혹은 3번씩 읽히게 만듬

                    ,rNowFrame:Number = 0 //dodraw에서 현재까지 플레이된 프레임수 누적, jump frame이 가동됐을때 프레임 누적갯수를 세서 썸네일 이미지 만들어줌
                    ,rPrevFrame:Number = 0 //jump one frame 에서 이전 프레임 탐색할때 이 프레임으로 탐색해줌 tickdraw에서 data 끝의 프레임을 저장함
                    ,rFirstImage:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,rFirstImage1:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,rFirstBGColor:uint = CANVAS_BG_COLOR
                    ,rzoomed:Number = 1.0 //리플레이 줌
                    ,rzoomedSave:Number = 1.0 //리플레이에서 수동줌하면 여기다가 저장해줌
                    ,rFitZoomedON:Boolean = false // 리플레이에서 오른쪽 클릭해서 창 크기에 맞췄을때 올려줌 startreplay될때 줌 1.0으로 리셋 못시키게함
                    ,rJumpImageIndexLast:int = -2 //썸네일 인덱스 바뀌면 여기다 저장
                    ,rJumpImageNowFrameLast:Number = -1
                    ,rCachedJumpImageIndexLast:int = -2 //마지막에 그려준 캐쉬 이미지 번호를 저장
                    ,rJumpCacheImageIndexSave:int = -2 // 더 잘게 쪼개준 이미지 인덱스 바뀌면 여기다 저장
                    ,rJumpImageFrameData:Array = [0] //스킵이미지 저장될때 r file frame sum을 저장해줌 처음에 rfirstimage라서 0번 추가해줌
                    ,rJumpImageLastBmpd1:BitmapData
                    ,rJumpImageLastBmpd11:BitmapData
                    ,makeJumpImageFlag:int = 0 //0이상이면 make jump image함수를 실행함. jumpframe함수에서 체크 0= 작업 끝남 1 = 작업 준비 2 = 작업중
                    ,rOnejumpFlagSave:Boolean = false //onejumpframe에서 prev인지 next인지 마지막 상태 저장해줌, 방향바꿀대 버튼 2번씩 눌러야 스킵되는거 방지하는거임
                    ,rOneJumpPrevSum:Number = 0 //뒤로 스킵키 오래누르고 있으면 프레임 합산은 여기다가 올려줌
                    ,rRestartTimerCount:uint = 0 //리스타트 타이머
                    ,rFrameTextDelayTime:int = 0 //프레임 바 딜레이
                    ,rCanvasBounds:Object = null
                    ,doDrawSlowEventON:Boolean = false //doDrawSlowEvent가 켜지면 올려줌
                    ,rFrameCacheImages:Array = [] //이전 탐색 프레임 빠르게 하기 위해서 jumpimage구간에서 더 잘게 이미지를 나누어주고 정보를여가다가 저장함
                    ,rSpeedLastStr:String = ""
                    ,rJumpFrameInitFlag:Boolean = false //리플레이모드 들어가서 바로 앞으로 재생할때 undodata첫부분부터 써주는 버그 때문에 이거 올려주고

        //about 관련 변수
                    ,aboutPanelON:Boolean = false //어바웃 창 떴을때 킴
                    ,needUpdate:int = 0 //새버전 나왔을때 올려주는 플래그
                    ,isCheckingUpdate:Boolean = false

        //스크린샷 관련 변수
                    ,captureModeON:Boolean = false //스크린샷 켜지면 올려줌
                    ,fileBrowserON:Boolean = false //캡쳐 저장키 빠르게 누를때 에러 떠서 중복안되게 플래그 세워줌
                    ,canvasBackupData:Object = {} //캡쳐 키면 캔버스 이전 상태 저장함
                    ,canvasBackupDataOnSave:Object = {} //save appdata에서 캔버스가 capture모드 상태로 저장해주기 때문에 백업한 데이터로 저장시켜줌
                    ,captureWindowMove:Point = new Point(0,0) //스크린샷이 켜져있는 상태에서 창을 조절했을때, 스크린샷이 끝나고 나서 regpoint를 그만큼 움직여줘야함
                    ,captureRotated:uint = 0 //캡쳐 회전한 변수 저장
                    ,captureFlipped:Boolean = false //캡쳐 대칭한 변수 저장
                    ,captureTransBGON:Boolean = false //배경 제외하고 저장하는 플래그
                    ,fullCaptureReady:Boolean = false
                    ,capTransparentBGBMPDSize:Number = 32
                    ,capTransparentBGBMPD:BitmapData
                    ,capInputFocusFlag:Boolean = false //포커스 되면 올려줌
                    ,capStampON:Boolean = false

        //윈도우 크기변수
                    ,lastWindowSizeInfo:Array = [0,0,680,768]
                    ,lastWindowState:int = 0

        //이미지 붙여넣기 변수
                    ,isClipBoardButtonAvailable:Boolean = false //윈도우 active에서 붙여넣기 가능한 이미지가 있으면 올려줌
                    ,clipImageOKCount:int = 0 //2번 이상 클릭되야 작동되게함

        //트레이스 레이어 변수
                    ,canvasTraceLayer:Sprite = new Sprite()//트레이스 레이어임
                    ,canvasTraceBitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0) //리사이즈등 수정된 데이터
                    ,canvasTraceBitmap:Bitmap = new Bitmap()
                    ,traceImageFile:File = File.applicationStorageDirectory.resolvePath("traceImg")
                    ,traceMenu:traceButtons = new traceButtons()
                    ,traceReizeMoveSum:Number = 0 //전역으로 돌려서 다시 클릭하거나 이미지를 불러와도 원래 스케일을 저장하도록함
                    ,tracePosInfo:Array = [0,0,0,1.0,1.0,false] // width, height, rotation,scale 미러 플래그
                    ,traceMenuON:Boolean = false //trace메뉴 켜졌을때 올려줌
                    ,traceRawBMPD:BitmapData = null
                    ,traceRawData:Array = null
                    ,traceImageCount:int = 0 //2번이상 클릭하면 되게
                    ,traceMemoryTrainingON:Boolean = false // 이거 켜지면 캔버스 그릴때 임시적으로 안보이게함
                    ,traceAlphaSave:Number = 0.5

        //그리드 레이어 변수
                    ,canvasGrid:Shape = new Shape()//트레이스 레이어임
                    ,gridValue:uint = 0
                    ,gridGapSave:Number = 0.0 //줌할때 다시 그려주는거 방지 갭이 다를때만 다시 그러줌
                    ,gridDrawOffsetX:Number = 0.0
                    ,gridDrawOffsetY:Number = 0.0
                    ,gridGraphicsCommand:Vector.<int> = new Vector.<int>
                    ,gridGraphicsData:Vector.<Number> = new Vector.<Number>

        //closure
                    ,realWorkingTimer:Object = cRealWorkingTimer()
                    ,dottedLine:Object = cDottedLine()//순서 먼저 와야함
                    ,penTool:Function = cPenTool()
                    ,dotTool:Function = cDrawDot()
                    ,lineTool:Function = cLineTool()
                    ,handTool:Function = cHandTool()
                    ,lassoToolFunction:Object = cLassoTool()
                    ,rotateTool:Function = cRotateTool()
                    ,zoomTool:Function = cZoomTool()
                    ,moveTool:Function = cMoveTool()
                    ,spuitTool:Function = cSpuitTool()
                    ,fillPenTool:Object = cFillPenTool()
                    // ,scanFillTool:Object = cScanFillTool()
                    ,drawDone:Function = cDrawDone()
                    ,tickDraw:Object = cTickDraw()
                    ,doDraw:Function = cDoDraw()
                    ,autoScroll:Object = cAutoScroll()
                    ,updatePenSizeCursor:Function = cUpdatePenSizeCursor()
                    ,undoData:Object = cAddUndoData()
                    ,penCursorPosition:Object = cUpdatePenCursorPosition()
                    ,checkSelectMainDrawTool:Function = cCheckSelectMainDrawTool()
                    ,drawCaptureArea:Object = cDrawCaptureArea()
                    ,drawCaptureStamp:Object = cDrawCaptureStamp()
                    ,replayHideCursor:Object = cCheckHideCursor()
                    ,resizeCanvas:Object = cResizeCanvas()
                    ,gridButton:Object = cGridFunc()

        //스크롤바 변수
                    ,scrollSetMovedY:Number = 0
                    ,scrollBarHeight:Number = 0
                    ,sideBarConstHeight:Number = 780

        //ui 색깔 변수
                    ,uiScaleIndex:int = 0
                    ,uiScaleSet:Array = [1.0,1.25,1.5,1.75,2.0,2.25]
                    ,uiColorIndex:int = 1
                    ,uiColorSet:Array = [       //주 컬러,        주컬러 반대색,    stage배경색,  캔버스 조절 막대 색,   리플레이 완료 막대 색, 리플레이 재시작 막대색
                                                [COLOR_DARK,      0xE5E5E5,      0x4B4B4B,    0x676767,            0x74AC74,           0xE8BE71],
                                                [COLOR_MID_DARK,  COLOR_BRIGHT,  0x888888,    RESIZE_BUTTON_COLOR, 0xA1CE9D,           0xF7DA83],
                                                [COLOR_MID_BRIGHT,0x505050,      0xC9C9C9,    0xB0B0B0,            0xB6DAAF,           0xF7EA8D],
                                                [COLOR_BRIGHT,    0x505050,      0xE1E1E1,    0xCBCBCB,            0xCEE5C5,           0xF7F2A0],
                                        ]
                    ,uiToolBoxColorSet:Array =
                    [                           //주 컬러,          윗부분 막대색, 전체 배경색, upstate왼쪽아이콘색,  overstate 버튼배경색  overstate 아이콘색
                                                [COLOR_DARK,        0x434343,   0xE5E5E5,  0xE5E5E5,           0x6E98B4,           0xE5E5E5],
                                                [COLOR_MID_DARK,    0xE3E3E1,   0xE3E3E1,  COLOR_MID_DARK,     0xB1DFEE,           COLOR_MID_DARK],
                                                [COLOR_MID_BRIGHT,  0xD6D5D4,   0x505050,  0x505050,           0xBADAE5,           0x505050],
                                                [COLOR_BRIGHT,      0xE7E7E7,   0x505050,  0x505050,           0xCEEBF2,           0x505050]
                    ]
                    ,toolTipBoxBGColor:Array = [0xFF7943,0xFF8A2C,0xFFAF45,0xFFCF46]
                    ,hintHorverCursorColor:Array = [0x73B5E4,0x7AC3F0,0x6C9CDB,0x609CFF]
        //워커 변수
        protected var worker:Worker
                    ,mainToBack:MessageChannel
                    ,backToMain:MessageChannel
                    ,isInSaveProgress:int = 0
                    ,isInSaveProgressOFFDelayTimer:int = 0
                    ,workerPNGSaveData:ByteArray = null
                    ,workerPNGCaptureFileData:Array = null
                    ,workerPNGCaptureData:Vector.<ByteArray>
                    ,workerUndoData:Array = null
                    ,workerUndoData2:Array = null
                    ,workerSWF:ByteArray = null
                    ,workerDataSendCount:int = 0
                    ,workerDataReceiveCount:int = 0
                    ,workerState:int = WORKER_STATE_STOPPED
                    ,workerWaitCount:int = 0 //워커 시작하고나서 약간 대기 시켜줘야함
                    ,workerFunctionsBeforeStart:Array = []

        //새창 관련 변수
                    ,canvasWindowInfo:Array = [null,null,400,400] //x y 너비 높이
                    ,canvasWindowON:Boolean = false //캔버스 새창 켜졌을때
                    ,canvasWindow:NativeWindow //참조된 새 창
                    ,canvasWindowBitmap:Bitmap //새창안에 들어갈 레이어 1 2번
                    ,canvasWindowBitmapSub:Bitmap
                    ,canvasWindowCanvasPanel:Sprite //캔버스 배경색
                    ,canvasWindowCanvasPanelBgSize:Point = new Point(0,0)
                    ,canvasWindowCanvasPanelBgColor:uint = 0
                    ,canvasWindowIgnoreResizeEventFlag:Boolean = false //창이랑 비트맵크기 맞춰줄때 이벤트 연속으로 발생하지 않게 걸어줌

        // 딥언도 관련 변수
                    ,deepUndoON:Boolean = false
                    ,deepUndoONSave:Boolean = false //리플레이 켜줄때 딥 플래그를 꺼줘서 여기다가 미리 저장해둠
                    ,deepUndoFrameSave:Number = -1 //리플레이 켜줄때 rNowFrame이 변하니까 그전에 백업해주고 꺼주고 다시 undo실행할때 이 프레임 기준으로 하려고

        //picker box RGB info관련 변수
                    ,rgbInfoFocusedON:Boolean = false // rgb info입력이 활성화 되었을때 올려줌
                    ,selectedRGBInfoIndex:int = -1 //처음 클릭했을때 R G B중 어느 영역을 클릭했는지
                    ,rgbInfoCursorPosSave:int = -1 //포커스 아웃 될때 마지막 커서 위치가 어딘지 저장
                    ,rgbInfoTextFocusedONFlag:Boolean = false // 텍스트 입력이 켜지면 올려줌
                    ,rgbInfoRightClickFocusIgnoreFlag:Boolean = false // RGB INFO 오를쪽 클릭은 힌트 안뜨고 기능못하게함
                    ,rgbInfoColorTypeHSV:Boolean = false // true가 되면 hsv false이면 rgb

        //기타
        private var windowClosingFlag:Boolean = false//윈도우 닫힐때 올려줌 save all data가 windows closing일때는 무조건 해주게 끔함
                    ,windowDeactivateTime:int = 0 //윈도우 비활성화된 시간 저장, 너무 자주 알탭해서 save all data가 자주 호출되는걸 막음
                    ,penCursorOFFFlag:Boolean = false //펜커서 이게 on되면 안보여줌
                    ,tempDragDropFile:File
                    ,tempCopiedImage:BitmapData
                    ,eraseMovedButton:SimpleButton = null //툴 선택해줬을때 지우개툴이 이동한 툴을 저장해줌 다시원래대로 복원해주려고
                    ,zoomToolHintON:Boolean = false //툴박스에서 마우스 클릭해서 줌툴써줄때 mouse out이벤트가 가장 늦게 되서 줌 배율 힌트가 처음에 보이지 않는거 해결
                    ,isRightSidebar:Boolean = false // 사이드바 위치 0이 왼쩾 1이 오른쪽
                    ,isSidebarVisible:Boolean = true
                    // ,sideBarPosSave:Number //사이드 바 단축키 사용하고나서 원래 위치로 옮겨줄때 씀
                    ,quickSidebarON:Boolean = false
                    ,topBarHintClickEventON:Boolean = false //톱바 힌트가 켜졌을때 클릭하면 지워주는 이벤트
                    ,updateAfterSaveFlag:Boolean = false //업데이트 버튼 눌렀을때 파일 저장 해주고 기다려주는 플래그
                    ,saveThenLoadFlag:Boolean = false //파일을 로드해주는데 파일 세이브 끝나고 로드 해주는 플래그
                    ,layerCheckKeyPressed:Boolean = false //w키 1키 계속 누르고 있을때 함수 호출 안하게 해주려고 플래그 올려줌
                    ,isDrawModeInputEventON:Boolean = false // 이벤트 세트가 켜지거나 꺼지는거 보관, 중복 이벤트 추가 피하려고
                    ,isReplayModeInputEventON:Boolean = false // 이벤트 세트가 켜지거나 꺼지는거 보관, 중복 이벤트 추가 피하려고
                    ,isCaptureModeInputEventON:Boolean = false // 이벤트 세트가 켜지거나 꺼지는거 보관, 중복 이벤트 추가 피하려고
                    ,dragDropFileSave:File //invoke 이벤트에서 파일을 너무 빨리 불러오지 못하게함
                    ,oldAppdataRtotalFrame:Number = -1 //24.00버전 이후로 쓸일 없지만 이전버전 호환성을 위해서 백업해주고 복원해줌
                    ,wheelZoomDelayTimer:int = 0 //휠로 줌조정 할때 감도를 약간 낮춰주기 위해서 타이머 사용
                    ;

        public function main():void
        {
            if(stage) init();
            else this.addEventListener(Event.ADDED_TO_STAGE,initEvent);
        }

        private function initEvent(e:Event):void
        {
            this.removeEventListener(Event.ADDED_TO_STAGE,initEvent);
            init();
        }

        private function init():void
        {
            deleteOldAppData();
            updateWindowTitle();
            setWindowTitleStar();
            setStageProperties();
            makeCanvasFamily();
            makeReplayCanvasFamily();
            makeMenuFamlity();
            makeResizeButtonFamily();
            updateCaptureTransParentBG();
            makeWorker();
            updateWindowSizeInfo();
            //입력 이벤트는 loadappdata보다느려야함
            addStageInputEvent();
            addInputEventStageChild();
            addInputEventDrawMode();
            loadAppData(); //이전 세팅 복원
            initReplayDataFile();
            initPickerBoxInfo(penColor);
            lastWindowSize = new Point(stage.nativeWindow.width,stage.nativeWindow.height);
            setCenvasCenterPos();
            setCenvasCenterPos(true);
            previewBox.updateImage(canvas1BitmapData,canvas11BitmapData,CANVAS_BG_COLOR);
            realWorkingTimer.start();
            checkVersion();
            setIMEDisabled();
            selectPenTool();
            pickerBox.selectPresetButton(0);
            hint.updateScale(getUIScale());
            hint.setCursorColor(hintHorverCursorColor[uiColorIndex]);
            toolTipBox.setBGColor(toolTipBoxBGColor[uiColorIndex]);
            hintBox.setBGColor(toolTipBoxBGColor[uiColorIndex]);
            setSideBarLeftPosition(); // 컨트롤 박스 크기가 set pentool 이후에 제대로 바뀜 원인 모름

            stage.addChild(fofo);
            stage.setChildIndex(fofo,stage.getChildIndex(sideBar)+(stage.getChildIndex(fofo) < stage.getChildIndex(sideBar)?0:1));

            NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvokeEvent);
        }

        //function
        private function getFilteredPos(mx:Number,my:Number):Point
        {
            mx = Math.round(mx*100)/100;
            my = Math.round(my*100)/100;

            if(sharpLineON)
            {
                my = Math.floor(my);
                mx = Math.floor(mx);
            }
            else if(penSmoothSlideValue === 0 && (regPoint.rotation % 90 === 0))
            {
                my = Math.round(my);
                mx = Math.round(mx);
            }

            return new Point(mx,my);
        }
            
        private function setPickColorScratchPad():void
        {
            pickColor(pickerBox.scratchPad.pickColor());
        }

        private function setCaptureFontListVisibleOff():void
        {
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,checkCaptureStampFontListVisibleOFFMouseDownEvent);    
            capStampFontListBox.visible = false;
        }
        private function checkCaptureStampFontListVisibleOFFMouseDownEvent(e:MouseEvent):void
        {
            if(!(capStampFontListBox.hitTestPoint(mouseX,mouseY) || topBar.capStampFont.hitTestPoint(mouseX,mouseY)))
            {
                setCaptureFontListVisibleOff();
            }
        }

        private function setCaptureStampFontBoxVisbleON():void
        {
            if(!capStampFontListBox.visible)
            {
                const gp:Point = topBar.capStampFont.localToGlobal(ZERO_POINT);

                capStampFontListBox.x = gp.x;
                capStampFontListBox.y = topBar.BARSIZE*topBar.scaleX;
                capStampFontListBox.updateSystemFontList();
                setTopChildIndex(capStampFontListBox);
                capStampFontListBox.setScale(getUIScale());
                capStampFontListBox.visible = true;

                stage.addEventListener(MouseEvent.MOUSE_DOWN,checkCaptureStampFontListVisibleOFFMouseDownEvent,false,-1);
            }
        }

        private function setTransparentBGDrawModeOFF():void
        {
            if(!canvasPanel.getChildByName("canvasFlash"))
            {
                return;
            }

            addTimerByName("viewTransBGTimer",0.0,true,function doTransBG():Boolean
            {
                if(canvasFlash.alpha < 0.0)
                {
                    canvasFlash.alpha = 0.0;
                    canvasFlash.visible = false;
                    canvasFlash.graphics.clear();
                    if(canvasPanel.getChildByName("canvasFlash"))
                    {
                        canvasPanel.removeChild(canvasFlash);
                    }
                    return false;
                }

                canvasFlash.alpha -= 0.15;
                return true;
            });
        }

        private function setTransparentBGDrawModeON():void
        {
            if(!canvasPanel.getChildByName("canvasFlash"))
            {
                canvasPanel.addChild(canvasFlash);
                canvasPanel.setChildIndex(canvasFlash,0);
                canvasFlash.visible = true;
                canvasFlash.graphics.beginBitmapFill(capTransparentBGBMPD);
                canvasFlash.graphics.drawRect(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);
                canvasFlash.graphics.endFill();
                canvasFlash.alpha = 0.0;
            }

            if(canvasFlash.alpha >= 1.0)
            {
                return;
            }

            addTimerByName("viewTransBGTimer",0.0,true,function doTransBG():Boolean
            {
                if(canvasFlash.alpha >= 1.0)
                {
                    canvasFlash.alpha = 1.0;
                    return false;
                }

                canvasFlash.alpha += 0.15;
                return true;
            });
        }

        private function setCaptureFlashEffect():void
        {
            if(drawCaptureArea.isFullImageCapture())
            {
                if(replayModeON)
                {
                    setcanvasFlash(rcanvasPanel,0,0,RCANVAS_WIDTH,RCANVAS_HEIGHT);
                }
                else
                {
                    setcanvasFlash(canvasPanel,0,0,CANVAS_WIDTH,CANVAS_HEIGHT);
                }
            }
            else
            {
                const nowCaptureArea:Rectangle = drawCaptureArea.getCaptureArea();
                setcanvasFlash((replayModeON)?rcanvasPanel:canvasPanel,nowCaptureArea.x,nowCaptureArea.y,nowCaptureArea.width,nowCaptureArea.height);
            }
        }

        private function setcanvasFlash(parent:DisplayObjectContainer,ox:Number,oy:Number,width:Number,height:Number):void
        {
            if(!parent.getChildByName("canvasFlash"))
            {
                parent.addChild(canvasFlash);
            }

            canvasFlash.visible = true;
            canvasFlash.graphics.beginFill(0xFFFFFF);
            canvasFlash.graphics.drawRect(ox,oy,width,height);
            canvasFlash.graphics.endFill();
            canvasFlash.alpha = 1.0;

            addTimerByName("flashingTimer",0.0,true,function doFlash():Boolean
            {
                if(canvasFlash.alpha < 0.0)
                {
                    canvasFlash.alpha = 0.0;
                    canvasFlash.visible = false;
                    canvasFlash.graphics.clear();
                    if(parent.getChildByName("canvasFlash"))
                    {
                        parent.removeChild(canvasFlash);
                    }
                    return false;
                }
                canvasFlash.alpha -= 0.13;
                return true;
            });
        }

        private function setPickerBoxTransBGBrightness(index:int):void
        {
            pickerBox.setBrightnessTransparentColorButtonBmpd(index);
            updateMyPaletteList();
            updateHistoryList();
            if(penColorTransparentFlag)
            {
                pickerBox.setRGBInfoBGTransparentColorON(myPalettePresetType);
            }
        }

        private function startScratchPadResetTimer(target:DisplayObject):void
        {
            addTimerByName("clearScratchPadTimer",0.4,false,function():void
            {
                setCountDownLongKey(target,"Clearing scratch pad.. ",null,pickerBox.scratchPad.clearPad,null);
            });
        }

        private function checkSelectMyPaletteOrReset():void
        {
            function mouseUpCheckSelectMyPaletteOrReset(e:MouseEvent):void
            {
                removeTimer("selectMyPaletteDelayTimer");
                stage.removeEventListener(MouseEvent.MOUSE_UP,mouseUpCheckSelectMyPaletteOrReset);

                if(e.target && e.target.name === "myPaletteButton")
                {
                    if(myPalettePresetType === 0)
                    {
                        if(myPaletteViewAllMode === false)
                        {
                            setMypPaletteListViewAll();
                        }
                        else
                        {
                            setMypPaletteListViewCompact();
                        }
                    }
                    else
                    {
                        changeMyPalettePreset(0);
                    }
                }
            }
            stage.addEventListener(MouseEvent.MOUSE_UP,mouseUpCheckSelectMyPaletteOrReset);

            addTimerByName("selectMyPaletteDelayTimer",0.4,false,function():void
            {
                setCountDownLongKey(pickerBox.myPaletteButton,"Clearing my palette.. ",null,clearMyPaletteList,null);
                stage.removeEventListener(MouseEvent.MOUSE_UP,mouseUpCheckSelectMyPaletteOrReset);
            });
        }

        private function checkSelctOrAddColorMyPalette():void
        {
            const firstClickColorIndex:uint = getMyPaletteIndexByMousePos();
            var colorAddedFlag:Boolean = false;

            function mouseUpCheckSelctOrAddColorMyPalette(e:MouseEvent):void
            {
                removeTimer("addColorMyPaletteDelayTimer");
                stage.removeEventListener(MouseEvent.MOUSE_UP,mouseUpCheckSelctOrAddColorMyPalette);
                if(colorAddedFlag === false)
                {
                    selectMyPaletteColor();
                }
            }
            stage.addEventListener(MouseEvent.MOUSE_UP,mouseUpCheckSelctOrAddColorMyPalette);

            addTimerByName("addColorMyPaletteDelayTimer",0.4,true,function():Boolean
            {
                if(firstClickColorIndex === getMyPaletteIndexByMousePos())
                {
                    colorAddedFlag = true;
                    addColorToMyPalette(pickerBox.getRGBInfoBGColor(),getMyPaletteIndexByMousePos());
                }
                else
                {
                    return false;
                }
                return true;
            });
        }

        private function isCursorInSideBar():Boolean
        {
            if(sideBar.visible === true)
            {
                const scale:Number = getUIScale();

                if(isRightSidebar
                && mouseX >= sideBar.x-sideBarScrollBar.width*scale && mouseX <= sideBar.x+sideBar.WIDTH*scale
                && mouseY >= sideBar.y && mouseY <= stage.stageHeight)
                {
                    return true;
                }
                else if(mouseX >= sideBar.x && mouseX <= sideBar.x+sideBar.WIDTH*scale+sideBarScrollBar.width*scale
                && mouseY >= sideBar.y && mouseY <= stage.stageHeight)
                {
                    return true;
                }
            }

            return false;
        }

        private function mouseWheelStage(e:MouseEvent):void
        {
            if(mouseClickON || rightMouseClickON || mouseDragON
            || captureModeON || !quickSidebarON && (!isNowKey(0) || getCommandKey() !== 0)) return;

            if(!hasTimer("wheelZoomTimer"))
            {
                addTimerByName("wheelZoomTimer",0.07,false,function():void
                {
                    if(isCursorInSideBar())
                    {
                        if(sideBarScrollBar.visible === true)
                        {
                            if(e.delta > 0)
                            {
                                setScrollBarMoveButton(40);
                            }
                            else
                            {
                                setScrollBarMoveButton(-40);
                            }
                        }
                    }
                    else if(isCursorInDrawArea())
                    {
                        if(e.delta > 0)
                        {
                            setZoomInButton(true,replayModeON);
                            if(!replayModeON)
                            {
                                setToolTipTempON(Math.floor(zoomed*100)+"%",1.5);
                            }
                        }
                        else
                        {
                            setZoomInButton(false,replayModeON);
                            if(!replayModeON)
                            {
                                setToolTipTempON(Math.floor(zoomed*100)+"%",1.5);
                            }
                        }
                    }
                })
            }
        }

        private function rgbInfoNumPadIncKey(inc:int):void
        {
            selectRGBInfoTextByRGBPos(rgbInfoCursorPosSave);
            if(rgbInfoColorTypeHSV)
            {
                adjustHSVInfoColor(inc,true);
            }
            else
            {
                adjustRGBInfoColor(inc,true);
            }
        }

        private function rgbInfoNumPadInputKey(num:String):void
        {
            var startIndex:int = pickerBox.rgbInfo.selectionBeginIndex;
            var endIndex:int = pickerBox.rgbInfo.selectionEndIndex;

            var cursorIndex:int;
            var currentValue:int;

            // 00 이렇게 되는거 방지
            if(rgbInfoColorTypeHSV)
            {
                if(num === "0" && int(getRGBColorTextFromRGBInfoText()[rgbInfoCursorPosSave]) === 0)
                {
                    return;
                }
            }
            else if(num === "0" && int(getRGBColorTextFromRGBInfoText()[rgbInfoCursorPosSave]) === 0)
            {
                return;
            }

            if(startIndex != endIndex)
            {
                pickerBox.rgbInfo.replaceText(startIndex,endIndex,num);
            }
            else
            {
                pickerBox.rgbInfo.replaceText(startIndex,startIndex,num);
            }

            checkRGBInfoTextFormat(true);
        }

        private function getSidebarConstHeight():Number
        {
            return (sideBarConstHeight + ((myPaletteViewAllMode && myPalettePresetType === 0) ? myPaletteColorHeight*7:0));
        }

        private function setCountDownLongKey(button:DisplayObject,hintStr:String,readyFunc:Function,okFunc:Function,cancelFunc:Function):void
        {
            if(!hasTimer("longKeyTimer"))
            {
                var keyBufferLenSave:uint = KEY_BUFFER.length;
                var mouseClickONSave:Boolean = mouseClickON;
                var rightMouseClickONSave:Boolean = rightMouseClickON;

                const deafultCount:Number = 3;
                const countNowTime:Number = Math.ceil((stage.frameRate*2)/deafultCount);

                longKeyCountDown = deafultCount;
                loneKeyFrameCount = 0;
                hint.off();

                if(readyFunc !== null)
                {
                    if(readyFunc() === true)
                    {
                        return;
                    }
                }

                function cancelLoneKey():void
                {
                    loneKeyFrameCount = 0;
                    longKeyCountDown = deafultCount;
                    toolTipBoxTimerOFF();
                }

                if(hintStr !== "")
                {
                    setToolTipString(hintStr+longKeyCountDown);
                    setToolTipON();
                }

                addTimerByName("longKeyTimer",0.0,true,function():Boolean
                {
                    if(mouseClickON !== mouseClickONSave
                    || rightMouseClickON !== rightMouseClickONSave
                    || keyBufferLenSave !== KEY_BUFFER.length
                    || (button && button.hitTestPoint(mouseX,mouseY) === false))
                    {
                        if(cancelFunc !== null)
                        {
                            cancelFunc();
                        }
                        cancelLoneKey();
                        return false;
                    }

                    loneKeyFrameCount++;

                    if(loneKeyFrameCount >= countNowTime)
                    {
                        loneKeyFrameCount = 0;
                        longKeyCountDown--;
                    }

                    setToolTipString(hintStr+longKeyCountDown);

                    if(longKeyCountDown <= 0)
                    {
                        cancelLoneKey();
                        okFunc();
                        return false;
                    }

                    return true;
                });
            }
        }

        private function setLoadBoxVisible(flag:Boolean):void
        {
            if(flag)
            {
                setDragDropSelectBoxCenterPos();
                stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownLoadBox);
            }
            else
            {
                stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownLoadBox);
            }

            setTopChildIndex(loadMenuBox);

            loadMenuBox.visible = flag;
        }

        private function getJumpImageFolder():File
        {
            return File.applicationStorageDirectory.resolvePath("imagecache");
        }

        private function initRepTempFile():void
        {
            repFileTemp = File.applicationStorageDirectory.resolvePath("tmp\\tmp_"+getRandomString(32))
        }

        private function checkButtonUpLoadBox(oldTargetName:String):void
        {
            loadMenuBox.addEventListener(MouseEvent.MOUSE_UP,mouseUpLoadBox);

            function mouseUpLoadBox(e:MouseEvent):void
            {
                loadMenuBox.removeEventListener(MouseEvent.MOUSE_UP,mouseUpLoadBox);

                if(!e.target || e.target.alpha < 1.0) return;

                if(oldTargetName === e.target.name)
                {
                    switch(e.target.name)
                    {
                        case "dragDropLoadButton":
                        {
                            if(saveThenLoadFlag === false && isInSaveProgress === 0 && !fileBrowserON && !loadMenuBox.isRefLayerLoadMode())
                            {
                                setLoadBoxVisible(false);
                                loadImageDragDrop(false);
                            }
                        }
                        break;

                        case "dragDropSaveAndLoadButton":
                        {
                            if(saveThenLoadFlag === false && isInSaveProgress === 0 && !fileBrowserON && !loadMenuBox.isRefLayerLoadMode())
                            {
                                saveThenLoadFlag = true;
                                loadMenuBox.setPleaseWait(true);
                                saveFile(false);
                            }
                        }
                        break;

                        case "dragDropLoadRefLayerButton":
                        {
                            if(saveThenLoadFlag === false && isInSaveProgress === 0 && !fileBrowserON)
                            {
                                loadImageDragDrop(true);
                                setLoadBoxVisible(false);
                            }
                        }
                        break;

                        case "dragDropCancelButton":
                        {
                            if(saveThenLoadFlag === false && isInSaveProgress === 0 && !fileBrowserON)
                            {
                                setLoadBoxVisible(false);
                            }
                        }
                        break;
                    }
                }
            }
        }

        private function mouseDownLoadBox(e:MouseEvent):void
        {
            if(!e.target)
            {
                return;
            }
            checkButtonUpLoadBox(e.target.name);
        }

        private function setLoadBoxOFFLoadFailed():void
        {
            saveThenLoadFlag = false;
            setToolTipTempON("Load failed");
            toolTipBox.x = Math.floor(loadMenuBox.x);
            toolTipBox.y = Math.floor(loadMenuBox.y);
            setLoadBoxVisible(false);
        }

        private function changeMyPalettePreset(type:int):void
        {
            if(myPalettePresetType === type)
            {
                return;
            }
            var myPalettePresetTypeSave:int = myPalettePresetType;
            myPalettePresetType = type;
            updateMyPaletteList();
            pickerBox.selectPresetButton(type);
            if(pickerMode !== 1)
            {
                changePickerModeToPenColor();
            }

            if(type === 1) // drawr
            {
                myPaletteSaveColorBeforeOtherType[myPalettePresetTypeSave] = pickerBox.getRGBInfoBGColor();
                pickColor(myPaletteSaveColorBeforeOtherType[1]);
            }
            else if(type === 2) //tegaki
            {
                myPaletteSaveColorBeforeOtherType[myPalettePresetTypeSave] = pickerBox.getRGBInfoBGColor();
                pickColor(myPaletteSaveColorBeforeOtherType[2]);
            }
            else
            {
                myPaletteSaveColorBeforeOtherType[myPalettePresetTypeSave] = pickerBox.getRGBInfoBGColor();
                pickColor(myPaletteSaveColorBeforeOtherType[0]);
            }

            checkFOFOPosition();
        }

        private function setFileBrowserONFlag(flag:Boolean):void
        {
            fileBrowserON = flag;
            resetKeyBuffer();
        }

        private function setRcursorRotation(newAngle:Number):void
        {
            rCursor.rotation = -newAngle;
        }

        private function formatBytes(bytes:Number):String {
            var sizes:Array = ["Bytes", "KB", "MB", "GB", "TB"];
            
            // 음수 또는 유효하지 않은 입력 처리
            if (isNaN(bytes) || bytes < 0) return "Invalid";
            if (bytes == 0) return "0 Byte";
            
            // 단위 계산 (최대 TB까지 제한)
            var i:int = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), sizes.length - 1);
            
            // 값 변환 및 소수점 첫째 자리 반올림
            var value:Number = bytes / Math.pow(1024, i);
            return Math.round(10 * value) / 10 + " " + sizes[i];
        }

        private function getDriveUsageString():String
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

        private function addInputEventCurrentModeLoadButton():void
        {
            if(replayModeON)
            {
                addInputEventReplayMode();
            }
            else
            {
                addInputEventDrawMode();
            }
        }

        private function removeInputEventCurrentModeLoadButton():void
        {
            setResizeButtonVisibleTimer(false);
            removeInputEventReplayMode();
            removeInputEventDrawMode();
        }

        private function getClipRectOffsetAirBrush(size:int):Number
        {
            const len:uint = penSizeList.length;
            for(var i:uint=1;i<len;i++)
            {
                if(penSizeList[i] === size)
                {
                    return size+airBrushClipRectOffectInc[i];
                }
            }
            return 0;
        }

        private function resetRCanvas2DrawCliprect2():void
        {
            rcanvas2ClipRect2.x = 0;
            rcanvas2ClipRect2.y = 0;
            rcanvas2ClipRect2.width = 0;
            rcanvas2ClipRect2.height = 0;
        }

        private function extandRCanvas2DrawCliprect2():void
        {
            var rairBrushOffset:Number = (airBrushSizeReplayMode2 > 0) ? getClipRectOffsetAirBrush(airBrushSizeReplayMode2) : 1;

            rcanvas2ClipRect2.x -= rairBrushOffset;
            rcanvas2ClipRect2.y -= rairBrushOffset;
            rcanvas2ClipRect2.width += (rairBrushOffset*2);
            rcanvas2ClipRect2.height += (rairBrushOffset*2);
        }

        private function updateRCanvas2DrawCliprect2():void
        {
            rcanvas2ClipRect2 = rcanvas2ClipRect2.union(rcanvas2Draw.getBounds(rcanvasPanel));
        }

        private function extandRCanvas2DrawCliprect():void
        {
            var rairBrushOffset:Number = (airBrushSizeReplayMode > 0) ? getClipRectOffsetAirBrush(airBrushSizeReplayMode) : 1;

            rcanvas2ClipRect.x -= rairBrushOffset;
            rcanvas2ClipRect.y -= rairBrushOffset;
            rcanvas2ClipRect.width += (rairBrushOffset*2);
            rcanvas2ClipRect.height += (rairBrushOffset*2);
        }

        private function resetRCanvas2DrawCliprect():void
        {
            rcanvas2ClipRect.x = 0;
            rcanvas2ClipRect.y = 0;
            rcanvas2ClipRect.width = 0;
            rcanvas2ClipRect.height = 0;
        }

        private function updateRCanvas2DrawCliprect():void
        {
            rcanvas2ClipRect = rcanvas2ClipRect.union(rcanvas2Draw.getBounds(rcanvasPanel));
        }

        private function resetCanvas2DrawCliprect():void
        {
            canvas2ClipRect.x = 0;
            canvas2ClipRect.y = 0;
            canvas2ClipRect.width = 0;
            canvas2ClipRect.height = 0;
        }

        private function extandCanvas2DrawCliprect():void
        {
            var airBrushOffset:Number = (airBrushSizeDrawMode > 0) ? getClipRectOffsetAirBrush(airBrushSizeDrawMode) : 1;

            canvas2ClipRect.x -= airBrushOffset;
            canvas2ClipRect.y -= airBrushOffset;
            canvas2ClipRect.width += (airBrushOffset*2);
            canvas2ClipRect.height += (airBrushOffset*2);
        }

        private function updateCanvas2DrawCliprect():void
        {
            canvas2ClipRect = canvas2ClipRect.union(canvas2Draw.getBounds(canvasPanel));
        }

        private function getDiplayObjectAlpha(alp:Number):Number
        {
            //객체의 alpha값이 8비트int로 변환된후 다시 Number로 변환되기 때문에 실제 소수점 비교를 할때도 같은 방식을 써주어야함
            return Math.round(alp*256)/256;
        }

        private function getLayerSwappedHint():String
        {
            return "Layers has been swapped "+((layerSwappedFlag) ? "1 <-> 2" : "2 <-> 1");
        }

        private function cImageMoveFunc(target:DisplayObject,targetAngle:Number,customScaleX:Number=1.0,customScaleY:Number=1.0):Function
        {
            var oldX:Number = target.x;
            var oldY:Number = target.y;
            var mx:Number = mouseX;
            var my:Number = mouseY;
            const zoom:Number = zoomed;
            const angle:Number = targetAngle;

            return function():Point
            {
                const dx:Number = mouseX-mx;
                const dy:Number = mouseY-my;
                const newPos:Point = rotatePoint(dx,dy,angle);

                newPos.setTo(oldX+newPos.x/zoom/customScaleX,oldY+newPos.y/zoom/customScaleY);

                return newPos;
            }
        }

        private function setRotateCursorOFF():void
        {
            rotateCursorBox.visible = false;
        }

        private function cGetCanvasRotationAngle(target:DisplayObject):Function
        {
            const snapThreshold:Number = 82;
            rotateCursorBox.x = mouseX;
            rotateCursorBox.y = mouseY+(65*getUIScale());
            rotateCursorBox["rotateArrow"].rotation = target.rotation;
            setTopChildIndex(rotateCursorBox);
            rotateCursorBox.visible = true;

            const toDeg:Number = 180.0/Math.PI;
            //움직인 각도합 로테이트 캔버스 마지막각도를 넣어줌 rad로 변환

            var sumAng:Number = target.rotation;
            //각도 차이 구하기 위해서 넣어줌, 초기 값은 마우스 클릭한 위치의 각도값
            var lastAng:Number = Math.atan2(mouseX-rotateCursorBox.x,mouseY-rotateCursorBox.y)*toDeg;
            var activateSnapFlag:Boolean = false;
            var ignoreSnapFlag:Boolean = true;
            var snappedAng:Number = 0;

            return function(snapFlag:Boolean):Number
            {
                const nowAng:Number = Math.atan2(mouseX-rotateCursorBox.x,mouseY-rotateCursorBox.y)*toDeg;
                const subAng:Number = lastAng-nowAng;

                lastAng = nowAng;
                sumAng += subAng;
                var deg:Number = sumAng;

                if(snapFlag)
                {
                    const snap90:Number = Math.abs(deg % 90.0);//90도 스냅 변수
                    const snap90N:Number = 90.0-snap90;
                    const snapAng:Number =  (snap90 > snap90N) ? snap90 : snap90N;

                    if(snapAng > snapThreshold && ignoreSnapFlag === false)
                    {
                        activateSnapFlag = true;
                        deg = Math.round(deg/90)*90;
                        if(snappedAng !== deg)
                        {
                            snappedAng = deg;
                        }
                    }
                    else if(activateSnapFlag === true)
                    {
                        sumAng = snappedAng;
                        deg = snappedAng;
                        activateSnapFlag = false;
                        ignoreSnapFlag = true;
                    }
                    else if(ignoreSnapFlag === true)
                    {
                        if(snapAng <= snapThreshold)
                        {
                            ignoreSnapFlag = false;
                        }
                    }
                }

                rotateCursorBox["rotateArrow"].rotation = deg;
                return Math.round(deg);
            }
        }

        private function getImageScaleHint(width:Number,height:Number,scale:Number,widthScaleFlag:Boolean):String
        {
            if(widthScaleFlag)
            {
                return Math.round(width*scale)+ " x "+ Math.round(height*scale) +" (x"+scale.toFixed(2)+")";
            }
            return Math.round(width)+ " x "+ Math.round(height) +" (x"+scale.toFixed(2)+")";
        }

        private function cImageResizeFunc(sc:Number):Function
        {
            var clickX:Number = mouseX;
            var clickY:Number = mouseY;
            var scale:Number = Math.abs(sc);
            var mxLastPos:Number;
            var myLastPos:Number;
            var moveFlag:int;

            return function (mx:Number,my:Number):Number
            {
                if(moveFlag != 0)
                {
                    if(moveFlag === 1)
                    {
                        const subX:Number = mx-mxLastPos;

                        if(subX !== 0) //차이가 0이 될때가 있어서 이건 스킵
                        {
                            scale *= Math.pow(2,subX*0.008);
                            traceReizeMoveSum += subX;
                        }
                    }
                    else if(moveFlag === 2)
                    {
                        const subY:Number = myLastPos-my;

                        if(subY !== 0)
                        {
                            scale *= Math.pow(2,subY*0.008);
                            traceReizeMoveSum += subY;
                        }
                    }
                }
                else if(moveFlag === 0)
                {
                    if(Math.abs(mx-clickX) > 5)
                    {
                        moveFlag = 1;
                    }
                    else if(Math.abs(my-clickY) > 5)
                    {
                        moveFlag = 2;
                    }
                }

                mxLastPos = mx;
                myLastPos = my;

                if(scale > 100) scale = 100;
                else if(scale < 0.1) scale = 0.1;

                return scale;
            }
        }

        private function setDeepUndoFrameSave(frame:Number):void
        {
            deepUndoFrameSave = frame;
        }

        private function getColorInfoStringOfHex(hexColor:uint,hsvFlag:Boolean):String
        {
            if(hsvFlag)
            {
                const hsv:Vector.<Number> = HEXtoHSV(hexColor);
                const h:Number = Math.round(hsv[0]*360);
                const s:Number = Math.round(hsv[1]*100);
                const v:Number = Math.round(hsv[2]*100);

                return "HSV "+h+","+s+","+v;
            }

            const rgb:Vector.<uint> = HEXtoRGB(hexColor);

            return "RGB "+rgb[0]+","+rgb[1]+","+rgb[2];
        }

        private function getCurrentColorHint():String
        {
            const strColor:String = getColorInfoStringOfHex(pickerBox.getCurrentColor(),rgbInfoColorTypeHSV);

            return "Current color : "+strColor;
        }

        private function isHintCantUse():Boolean
        {
            return mouseClickON || mouseDragON || toolBox2ON || fillPenStarted
            || lassoToolON || rgbInfoFocusedON || aboutPanelON || makeJumpImageFlag === 2
            || loadMenuBox.visible || numPadBox.visible;
        }

        private function setLayerSwapEffect(target:DisplayObject):void
        {
            target.alpha = BUTTON_OFF_ALPHA;

            addTimerByName("layerSwapFlickEffect",0.5,false,function():void
            {
                target.alpha = 1.0;
            })
        }

        private function pickerBoxHintONEvent(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target || pickerBox.alpha < 1.0) return;
            const targetName:String = target.name;
            var str:String = "";

            if(isHintCantUse() && !fillPenStarted)
            {
                return;
            }

            switch(targetName)
            {
                case "hueColor":
                {
                    str = "Hue";
                }
                break;

                case "svBox":
                {
                    str = "Situation and Value";
                }
                break;

                case "swapPositionButton":
                {
                    str = "Swap palette position [click]";
                }
                break;

                case "historyBox":
                {
                    str = "Move color to my palette [click+drag]";
                }
                break;

                case "myPaletteBox":
                {
                    if(myPalettePresetType !== 0) return;
                    str = "Add, remove, restore color [hold click]\nSwap color position [click+drag]";
                }
                break;

                case "rgbInfo":
                {
                    if(fillPenStarted)
                    {
                        return;
                    }
                    str = "Change value [click]\nChange color model [click "+((rgbInfoColorTypeHSV) ? "'HSV'":"'RGB'")+" text]";
                }
                break;

                case "paperColorButton":
                {
                    if(fillPenStarted)
                    {
                        return;
                    }
                    str = "Change background color";
                }
                break;

                case "penColorButton":
                {
                    if(fillPenStarted)
                    {
                        return;
                    }
                    str = "Change pen color";
                }
                break;

                case "currentColor": str = getCurrentColorHint(); break;
                case "transColorButton": str = "Transparent color\nON/OFF [c+space, m+space]"; break;
                case "myPaletteButton": str = "Expand palette ON/OFF [click x 2]\nClear palette [click]"+STRING_HOLD_NSEC; break;
                case "drawrPresetButton":
                case "tegakiPresetButton": str = "Clear scratch pad [click]"+STRING_HOLD_NSEC;break;
                case "scratchPad": str = "Scratch pad\nDraw [click+drag]\nSelect color [c, m, click]"; break;

                default:
                return;
            }

            if(str === "") return;

            hint.on(str,target);
        }

        private function scrollBarHintONEvent(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target || (isHintCantUse() && !fillPenStarted))
            {
                return;
            }

            var str:String = "Scroll sidebar [click+drag, mouse wheel on sidebar]\nReset [right-click]";

            hint.on(str,target);
        }

        private function sethintOFFDelay():void
        {
            addTimerByName("hintOFFTimer",3.0,false,function():void
            {
                hint.off();
            });
        }

        private function globalHintOFF(e:MouseEvent):void
        {
            if(controlBox.hitTestPoint(mouseX,mouseY))
            {
                return;
            }

            if(!rgbInfoFocusedON && !mouseDragON && !captureModeON)
            {
                if(hintBox.visible || hintHorverCursor.visible)
                {
                    hint.off();
                }
            }

            if(hintBox.visible)
            {
                if(hintBox.hitTestPoint(mouseX,mouseY))
                {
                    if(hintBox.y !== 0)
                    {
                        hintBox.y = 0;
                    }
                    else
                    {
                        hint.off();
                    }
                }
            }
        }

        private function setHintONTemp(str:String):void
        {
            hint.on(str,null,true);
            sethintOFFDelay();
        }

        private function cHint():Object
        {
            var gp:Point = new Point(0,0);
            var scale:Number = 1.0;
            var w:Number = 0;
            var h:Number = 0;
            var lastHint:String;
            var cursorColor:uint = 0;
            var targetSave:DisplayObject;
            var hintONTime:int = 0;
            var hintMoveWaitCountFirst:int = 0;
            var hintMoveWaitCountAfter:int = 0;
            var hintMoveDirection:Boolean = true;
            var hintMoveSpeed:Number = 2;
            var timeSum:int = 1000/stage.frameRate;

            function checkMoveingHint(e:Event):void
            {
                if(hintBox.width > stage.stageWidth)
                {
                    if(hintMoveWaitCountFirst >= 1000)
                    {
                        if(hintMoveDirection)
                        {
                            if(hintBox.x+hintBox.width > stage.stageWidth)
                            {
                                hintBox.x = hintBox.x-hintMoveSpeed*hintBox.scaleX;
                            }
                            else
                            {
                                hintMoveWaitCountAfter += timeSum;
                                if(hintMoveWaitCountAfter >= 1000)
                                {
                                    hintMoveWaitCountAfter = 0;
                                    hintMoveDirection = !hintMoveDirection;
                                }
                            }
                        }
                        else
                        {
                            if(hintBox.x < 0)
                            {
                                hintBox.x = hintBox.x+hintMoveSpeed*hintBox.scaleX
                            }
                            else
                            {
                                hintMoveWaitCountAfter += timeSum;
                                if(hintMoveWaitCountAfter >= 1000)
                                {
                                    hintMoveWaitCountAfter = 0;
                                    hintMoveDirection = !hintMoveDirection;
                                }
                            }
                        }
                    }
                    else
                    {
                        hintMoveWaitCountFirst += timeSum;
                    }
                }
                else
                {
                    hintMoveWaitCountFirst = 0;
                    hintMoveWaitCountAfter = 0;
                    hintMoveDirection = true;
                }
            }

            function isHintStarted():String
            {
                return lastHint;
            }

            function setCursorColor(color:uint):void
            {
                cursorColor = color;
            }

            function updateScale(newScale:Number):void
            {
                scale = newScale;
            }

            function cursorON(target:DisplayObject):void
            {
                gp = target.localToGlobal(ZERO_POINT);

                w = target.width*scale;
                h = target.height*scale;

                hintHorverCursor.graphics.clear();
                hintHorverCursor.graphics.lineStyle(2.0*scale,cursorColor);

                if(target is TextField)
                {
                    hintHorverCursor.x = gp.x-2*scale;
                    hintHorverCursor.y = gp.y-3*scale;
                }
                else if(target === controlBox.airBrushButtonWrapper || target === controlBox.sharpLineButtonWrapper)
                {
                    hintHorverCursor.x = gp.x-scale;
                    hintHorverCursor.y = gp.y-scale;
                }
                else
                {
                    hintHorverCursor.x = gp.x;
                    hintHorverCursor.y = gp.y;
                }

                hintHorverCursor.graphics.drawRect(0,0,w,(target is TextField) ? h-scale:h);

                setTopChildIndex(hintHorverCursor);
                hintHorverCursor.visible = true;
            }

            function hintOFFImmediately():void
            {
                hintHorverCursor.visible = false;
                lastHint = null;
                targetSave = null;
                removeTimer("hintOFFTimer");
                removeTimer("hintOFFDelayTimer");
                removeTimer("hintONDelayTimer");
                hintFullOFF();
            }

            function hintOFF():void
            {
                lastHint = null;
                targetSave = null;
                removeTimer("hintOFFTimer");
                hintHorverCursor.visible = false;
                addTimerByName("hintOFFDelayTimer",0.3,false,function():void
                {
                    hintFullOFF();
                });
            }

            function hintFullOFF():void
            {
                stage.removeEventListener(Event.ENTER_FRAME,checkMoveingHint);
                hintMoveWaitCountFirst = 0;
                hintMoveWaitCountAfter = 0;
                hintONTime = 0;
                hintBox.visible = false;
                hintBox.setText("");
                hintBox.x = -hintBox.width-3;
                hintBox.y = -hintBox.height-3;
            }

            function updateHintPos():void
            {
                hintBox.x = 0;
                hintBox.y = Math.round(stage.stageHeight-hintBox.getHeight()+1);
            }

            function hintON(str:String,target:DisplayObject,fastHint:Boolean=false):void
            {
                if(!hintHorverCursor.visible && !fastHint)
                {
                    return;
                }

                if(str === "" && target === null)
                {
                    str = lastHint;
                    target = targetSave;
                }

                hintBox.setText(str);
                targetSave = target;
                updateHintPos();

                // hintONEffect();
                setTopChildIndex(hintBox);
                hintBox.visible = true;
                stage.addEventListener(Event.ENTER_FRAME,checkMoveingHint);
            }

            function start(str:String,target:DisplayObject,fastHint:Boolean=false):void
            {
                str = str.replace(/\n/g, " _ ");
                if(hintBox.visible && lastHint === str)
                {
                    return;
                }

                removeTimer("hintOFFTimer");
                removeTimer("hintOFFDelayTimer");

                lastHint = str;
                targetSave = target;

                if(target)
                {
                    cursorON(target);
                }

                if(!target || fastHint || getTimer()-hintONTime < 1000 || hintBox.visible)
                {
                    hintON(str,target,fastHint);
                }
                else
                {
                    if(hintBox.visible)
                    {
                        hintFullOFF();
                    }

                    if(!hasTimer("hintONDelayTimer"))
                    {
                        addTimerByName("hintONDelayTimer",1.0,false,hintON,["",null]);
                    }
                }
            }

            return {
                on:start,
                off:hintOFF,
                updateHintPos:updateHintPos,
                cursorON:cursorON,
                updateScale:updateScale,
                setCursorColor:setCursorColor,
                isHintStarted:isHintStarted,
                hintOFFImmediately:hintOFFImmediately
            }
        }

        private function isRGBInfoValueChanged():Boolean
        {
            return pickerBox.getOldRGBInfoText() !== pickerBox.getFirstRGBInfoColorText();
        }

        private function checkRGBInfoHasEmptyValue():Boolean
        {
            const c:Array = getRGBColorTextFromRGBInfoText();
            var emptyFlag:int = -1;

            if(c[0] === "")
            {
                emptyFlag = 0;
                c[0] = "0";
            }

            if(c[1] === "")
            {
                emptyFlag = 1;
                c[1] = "0";
            }

            if(c[2] === "")
            {
                emptyFlag = 2;
                c[2] = "0";
            }

            if(emptyFlag === -1) return false;

            if(rgbInfoColorTypeHSV)
            {
                c[0] = Number(c[0])/360;
                c[1] = Number(c[1])/100;
                c[2] = Number(c[2])/100;
                const hsv:Vector.<Number> = new <Number>[c[0],c[1],c[2]];
                getHSVInfoString(hsv);
                setHSVCursorPosByColor(getHSVColorFromRGBInfoText());
            }
            else
            {
                c[0] = int(c[0]);
                c[1] = int(c[1]);
                c[2] = int(c[2]);
                getRGBInfoString(c[0],c[1],c[2]);
                setHSVCursorPosByColor(getHexColorFromRGBInfoText());
            }

            //이전 항목으로 이동
            --emptyFlag;
            if(emptyFlag < 0) emptyFlag = 0;
            selectRGBInfoTextByRGBPos(emptyFlag);

            return true;
        }

        //123,123,123에서 커서가 어느 지점이 있는지 반환함 0은 R, 1은 G, 2는 B
        private function getRGBInfoTextCursorPos():int
        {
            const textBeforeCursor:String = pickerBox.getRGBInfo().substring(0,pickerBox.rgbInfo.caretIndex);
            const rgb:Array =  textBeforeCursor.split(",");

            return rgb.length-1;
        }

        //index 값에 해당하는 RGB 텍스트 영역을 선택함
        private function selectRGBInfoTextByRGBPos(index:int):void
        {
            if(index < 0 || index > 2) return;

            if(index === 0)
            {
                pickerBox.rgbInfo.maxChars = 15;
                pickerBox.rgbInfo.setSelection(4,pickerBox.getRGBInfo().indexOf(","));
            }
            else if(index === 1)
            {
                pickerBox.rgbInfo.maxChars = 15;
                pickerBox.rgbInfo.setSelection(pickerBox.getRGBInfo().indexOf(",")+1,pickerBox.getRGBInfo().lastIndexOf(","));
            }
            else if(index === 2)
            {
                pickerBox.rgbInfo.maxChars = getRGBInfoTextLimit();
                pickerBox.rgbInfo.setSelection(pickerBox.getRGBInfo().lastIndexOf(",")+1,pickerBox.getRGBInfo().length);
            }

            selectedRGBInfoIndex = index;
        }

        //RGB 문자열 3개가 든 배열을 반환함
        private function getRGBColorTextFromRGBInfoText():Array
        {
            var rgbText:String = pickerBox.getRGBInfo().slice(4); // "RGB"와 공백 제거
            var rgb:Array = rgbText.split(","); // 쉼표로 숫자를 나눔

            return rgb;
        }

        private function getHSVColorFromRGBInfoText():Vector.<Number>
        {
            const c:Array = getRGBColorTextFromRGBInfoText();
            const h:Number = Number(c[0])/360;
            const s:Number = Number(c[1])/100;
            const v:Number = Number(c[2])/100;
            const hsv:Vector.<Number> = new <Number> [h,s,v];

            return hsv;
        }

        private function getHexColorFromRGBInfoText():uint
        {
            const c:Array = getRGBColorTextFromRGBInfoText();

            return RGBtoHEX(int(c[0]),int(c[1]),int(c[2]));
        }

        //R G B 해당 영역의 값이 3자리 인지 아닌지 확인
        private function isCurrentRGBInfoTextLenBiggerThan3():Boolean
        {
            const rgb:Array = getRGBColorTextFromRGBInfoText();
            const cursorPos:int = getRGBInfoTextCursorPos();

            if(rgb[cursorPos].length >= 3)
            {
                return true;
            }

            return false;
        }

        //RGB에서 R G 숫자 갯수에 따른 최대 글자 수를 구함
        private function getRGBInfoTextLimit():int
        {
            const rgb:Array = getRGBColorTextFromRGBInfoText();
            var sum:uint = 9;

            for(var i:uint=0;i<2;i++)
            {
                sum += rgb[i].length;
            }

            return sum;
        }

        private function checkRGBInfoColorValueLimit():void
        {
            const c:Array = getRGBColorTextFromRGBInfoText();

            if(rgbInfoColorTypeHSV)
            {
                if(int(c[0]) > 360) c[0] = "360";
                if(int(c[1]) > 100) c[1] = "100";
                if(int(c[2]) > 100) c[2] = "100";

                pickerBox.setRGBInfo("HSV "+c[0]+","+c[1]+","+c[2]);
            }
            else
            {
                if(int(c[0]) > 255) c[0]= "255";
                if(int(c[1]) > 255) c[1]= "255";
                if(int(c[2]) > 255) c[2]= "255";

                pickerBox.setRGBInfo("RGB "+c[0]+","+c[1]+","+c[2]);
            }
        }

        private function moveRGBInfoTextCursor(value:int):void
        {
            const cursorPos:int = pickerBox.rgbInfo.caretIndex;
            if(value === 1)
            {
                pickerBox.rgbInfo.setSelection(cursorPos+1,cursorPos+1);
            }
            else
            {
                pickerBox.rgbInfo.setSelection(cursorPos-1,cursorPos-1);
            }
        }

        private function adjustHSVInfoColor(value:int,fromNumPad:Boolean):void
        {
            const index:int = (fromNumPad) ? rgbInfoCursorPosSave:getRGBInfoTextCursorPos();
            const hsv:Array = getRGBColorTextFromRGBInfoText();
            var num:int = int(hsv[index]);

            num += value;

            if(num < 0) num = 0;

            if(index === 0)
            {
                if(num > 360) num = 360;
            }
            else
            {
                if(num > 100) num = 100;
            }

            hsv[index] = String(num);

            pickerBox.setRGBInfo("HSV "+hsv);
            pickerBox.updateOldRGBInfoText();

            setHSVCursorPosByColor(getHSVColorFromRGBInfoText());

            //커서가 숫자 맨 끝자리에 있고 자릿수가 적어지면 다음 채널로 넘어가기 때문에 해줘야함
            selectRGBInfoTextByRGBPos(index);
        }

        private function adjustRGBInfoColor(value:int,fromNumPad:Boolean):void
        {
            const index:int = (fromNumPad) ? rgbInfoCursorPosSave:getRGBInfoTextCursorPos();
            const rgb:Array = getRGBColorTextFromRGBInfoText();
            var num:int = int(rgb[index]);

            num += value;
            if(num < 0) num = 0;
            else if(num > 255) num = 255;

            rgb[index] = String(num);

            pickerBox.setRGBInfo("RGB "+rgb);
            pickerBox.updateOldRGBInfoText();

            setHSVCursorPosByColor(getHexColorFromRGBInfoText());

            //커서가 숫자 맨 끝자리에 있고 자릿수가 적어지면 다음 채널로 넘어가기 때문에 해줘야함
            selectRGBInfoTextByRGBPos(index);
        }

        private function rgbInfoTextMouseDownEvent(e:MouseEvent):void
        {
            if(pickerBox.rgbInfo.hitTestPoint(mouseX,mouseY))
            {
                var clickedPos:int = pickerBox.rgbInfo.getCharIndexAtPoint(pickerBox.rgbInfo.mouseX,10);
                if(clickedPos >= 0 && clickedPos <= 3)
                {
                    toggleRGBInfoTextColorType();
                }
            }
        }

        private function isNumberKeyCode(charCode:uint):Boolean
        {
            switch(String.fromCharCode(charCode))
            {
                case "0":
                case "1":
                case "2":
                case "3":
                case "4":
                case "5":
                case "6":
                case "7":
                case "8":
                case "9":
                return true;
            }

            return false;
        }

        private function rgbInfoTextKeyDownEvent(e:KeyboardEvent):void
        {
            const keyCode:int = e.keyCode;

            switch(keyCode)
            {
                case KEY.enter:
                case KEY.esc:
                case KEY.space:
                {
                    setStageFocusNull();
                }
                break;

                case KEY.tab:
                {
                    if(isPressingShift())
                    {
                        selectRGBInfoTextByRGBPos(getRGBInfoTextCursorPos()-1);
                    }
                    else
                    {
                        selectRGBInfoTextByRGBPos(getRGBInfoTextCursorPos()+1);
                    }
                }
                break;

                case KEY.up:
                case KEY.w:
                case KEY.i:
                {
                    if(rgbInfoColorTypeHSV)
                    {
                        adjustHSVInfoColor(1,false);
                    }
                    else
                    {
                        adjustRGBInfoColor(1,false);
                    }
                    e.preventDefault();
                }
                break;

                case KEY.down:
                case KEY.s:
                case KEY.k:
                {
                    if(rgbInfoColorTypeHSV)
                    {
                        adjustHSVInfoColor(-1,false);
                    }
                    else
                    {
                        adjustRGBInfoColor(-1,false);
                    }
                    e.preventDefault();
                }
                break;

                case KEY.d:
                case KEY.l:
                {
                    moveRGBInfoTextCursor(1);
                    e.preventDefault();
                }
                break;

                case KEY.a:
                case KEY.j:
                {
                    moveRGBInfoTextCursor(-1);
                    e.preventDefault();
                }
                break;

                case KEY.home:
                case KEY.end:
                case KEY.backspace:
                case KEY.right:
                case KEY.left:
                case KEY.down:
                case KEY.up:
                case KEY.shift:
                case KEY.alt:
                case KEY.ctrl:
                {
                    //pass
                }
                break;

                default:
                {
                    if(!isNumberKeyCode(e.charCode))
                    {
                        e.preventDefault();
                        setStageFocusNull();
                    }
                }
                break;
            }
        }

        private function setNumPadON():void
        {
            if(numPadBox.visible === false)
            {
                numPadBox.visible = true;
                setTopChildIndex(numPadBox);
                const gp:Point = pickerBox.svBox.localToGlobal(ZERO_POINT);
                numPadBox.x = gp.x;
                numPadBox.y = gp.y;
                resetNowKey();
                stage.addEventListener(MouseEvent.MOUSE_DOWN,numPadMouseDownEvent,false,-2);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,numPadRightMouseDownEvent,false,-2);
            }
        }

        private function setNumPadOFF():void
        {
            if(pickerBox.getRGBInfoBGColor() !== pickerBox.getCurrentColor())
            {
                setRGBInfoTextInputOK();
            }
            numPadBox.off();
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,numPadMouseDownEvent);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,numPadRightMouseDownEvent);
        }

        private function checkNumPadMouseUp(oldTargetName:String):void
        {
            function numPadMouseUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP,numPadMouseUpEvent);

                if(oldTargetName === e.target.name)
                {
                    switch(e.target.name)
                    {
                        case "numInc": rgbInfoNumPadIncKey(1); break;
                        case "numDec": rgbInfoNumPadIncKey(-1); break;
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
                            rgbInfoNumPadInputKey(e.target.name.charAt(3));
                        }
                        break;
                    }
                }
            };

            stage.addEventListener(MouseEvent.MOUSE_UP,numPadMouseUpEvent);
        }

        private function numPadRightMouseDownEvent(e:MouseEvent):void
        {
            if(!e.target) return;
            setStageFocusNull();
            rgbInfoRightClickFocusIgnoreFlag = true;
        }

        private function numPadMouseDownEvent(e:MouseEvent):void
        {
            if(!e.target) return;

            const targetName:String = e.target.name;
            if(!numPadBox.hitTestPoint(mouseX,mouseY) && !pickerBox.rgbInfo.hitTestPoint(mouseX,mouseY))
            {
                if(numPadBox.visible)
                {
                    setNumPadOFF();
                }
                return;
            }

            if(targetName === "numInc")
            {
                setHoldKeyRepeat(false,rgbInfoNumPadIncKey,1);
            }
            else if(targetName === "numDec")
            {
                setHoldKeyRepeat(false,rgbInfoNumPadIncKey,-1);
            }

            checkNumPadMouseUp(targetName);
        }

        //hsv rgb로 왔다갔다함
        private function toggleRGBInfoTextColorType():void
        {
            const oldCursorIndex:int = getRGBInfoTextCursorPos();

            if(rgbInfoColorTypeHSV)
            {
                rgbInfoColorTypeHSV = false;
                pickerBox.setRGBInfo(getRGBInfoString(pickerBox.getRGBInfoBGColor()));
            }
            else
            {
                rgbInfoColorTypeHSV = true;
                pickerBox.setRGBInfo(getHSVInfoString(HEXtoHSV(pickerBox.getRGBInfoBGColor())));
            }

            selectRGBInfoTextByRGBPos(oldCursorIndex);
        }

        private function setRGBInfoTextInputOK():void
        {
            const color:uint = pickerBox.getRGBInfoBGColor();

            if(isPenColorMode())
            {
                penColor = color;
                updateOpacityCursorPos(penAlphaIndex);
            }
            else if(isBackgroundColorMode())
            {
                setBackgroundColorDrawMode(color);
                if(canvasWindowON) updateCanvasWindowCanvasPanelBGColor(CANVAS_BG_COLOR,canvasWindowBitmap.bitmapData);
                addUndoBGColor(color);
            }
        }

        private function rgbInfoTextFocusOutEvent(e:FocusEvent):void
        {
            setIMEDisabled();
            checkKeyInvalidKey();

            rgbInfoCursorPosSave = selectedRGBInfoIndex;

            if(rgbInfoRightClickFocusIgnoreFlag)
            {
                rgbInfoRightClickFocusIgnoreFlag = false;
                pickerBox.rgbInfo.selectable = true;
                return;
            }

            // stagefo();
            hint.off();
            pickerBox.rgbInfo.background = false;
            pickerBox.rgbInfo.border  = false;
            pickerBox.rgbInfo.removeEventListener(Event.ENTER_FRAME,checkRGBInfoCursorPos);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, rgbInfoTextKeyDownEvent);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,rgbInfoTextMouseDownEvent);
            pickerBox.rgbInfo.removeEventListener(Event.CHANGE, onRGBInfoTextChangeEvent);
            rgbInfoRightClickFocusIgnoreFlag = false;

            if(pickerBox.getRGBInfoBGColor() !== pickerBox.getCurrentColor())
            {
                setRGBInfoTextInputOK();
            }

            addTimerByName("rgbInfoTextFocusOutEventDelayInput",0.0,false,function():void
            {
                rgbInfoFocusedON = false;
                addInputEventDrawMode();
            });
        }

        private function setStageFocusNull():void
        {
            stage.focus = null;

            if(numPadBox.visible)
            {
                setNumPadOFF();
            }
        }

        private function rgbInfoTextFocusInEvent(e:FocusEvent):void
        {
            if(rgbInfoRightClickFocusIgnoreFlag || lassoToolON)
            {
                //라소툴때문에 강제로 올려줌
                rgbInfoRightClickFocusIgnoreFlag = true;

                pickerBox.rgbInfo.selectable = false;
                pickerBox.updateOldRGBInfoText();
                addTimerByName("textInputFocusIgnoreDelay",0.0,false,function():void
                {
                    setStageFocusNull();
                });

                return;
            }
            //가장 자리를 클릭하면 Y값이 음수가 될때가 있어서 제대로된 값이 안나옴 그래서 녺이는 양수 고정으로 함
            const foundColorType:String = (rgbInfoColorTypeHSV) ? "HSV":"RGB";
            const isHSVRGBText:Boolean = (pickerBox.getRGBInfo().indexOf(foundColorType) !== -1)
            var currnetTextCursorPos:int = pickerBox.rgbInfo.getCharIndexAtPoint(pickerBox.rgbInfo.mouseX,10);
            if(rgbInfoFocusedON === false && isHSVRGBText && currnetTextCursorPos >= 0 && currnetTextCursorPos <= 3)
            {
                addTimerByName("textInputFocusIgnoreDelay",0.0,false,function():void
                {
                    setStageFocusNull();
                });
                toggleRGBInfoTextColorType();
                return;
            }
            else if(currnetTextCursorPos < 0) //텍스트 맨 끝에 클릭하면 -1이 되서 이때는 커서를 가장 뒤로 이동시킴
            {
                currnetTextCursorPos = pickerBox.rgbInfo.length;
            }

            setIMEDisabled();
            removeInputEventDrawMode();

            rgbInfoFocusedON = true;
            penColorTransparentFlag = false;
            selectedRGBInfoIndex = -1;

            if(isHSVRGBText)
            {
                pickerBox.updateOldRGBInfoText();
            }
            else //투명색으로 transparent 텍스트가 되있을때 말하는거임
            {
                setRGBInfoTextColorByColor(pickerBox.getRGBInfoBGColor());
                pickerBox.setRGBInfoBGTransparentColorOFF();
                pickerBox.setRGBInfo(pickerBox.getOldRGBInfoText());
            }

            pickerBox.updateFirstRGBInfoColorText();
            // pickerBox.rgbInfo.setSelection(0,0);
            if(quickSidebarON === false)
            {
                stage.addEventListener(KeyboardEvent.KEY_DOWN,rgbInfoTextKeyDownEvent);
            }
            pickerBox.rgbInfo.addEventListener(Event.CHANGE,onRGBInfoTextChangeEvent);
            setNowToolForDrawing(false);
            setNumPadON();

            addTimerByName("rgbInfoTextFocusInEventDelayCheck",0.0,false,function():void
            {
                stage.addEventListener(MouseEvent.MOUSE_DOWN,rgbInfoTextMouseDownEvent);
                pickerBox.rgbInfo.setSelection(currnetTextCursorPos,currnetTextCursorPos);
                pickerBox.rgbInfo.addEventListener(Event.ENTER_FRAME,checkRGBInfoCursorPos);
                hint.on(STRING_CUSTOM_COLOR_HINT,pickerBox.rgbInfo);
            });
        }

        private function checkRGBInfoTextFormat(fromNumPad:Boolean):void
        {
            var pattern:RegExp = /\b(RGB|HSV) \d{0,3},\d{0,3},\d{0,3}/;
            var isMatch:Boolean = pattern.test(pickerBox.getRGBInfo());
            //여기서 빈값을 채워주기 때문에 미리 함수 실행해줘야 함
            const hasEmptyChecked:Boolean = checkRGBInfoHasEmptyValue();

            if(isMatch)
            {
                checkRGBInfoColorValueLimit();
                pickerBox.updateOldRGBInfoText();

                if(rgbInfoColorTypeHSV)
                {
                    setHSVCursorPosByColor(getHSVColorFromRGBInfoText());
                }
                else
                {
                    setHSVCursorPosByColor(getHexColorFromRGBInfoText());
                }

                if(!fromNumPad && isCurrentRGBInfoTextLenBiggerThan3() && hasEmptyChecked === false)
                {
                    selectRGBInfoTextByRGBPos(getRGBInfoTextCursorPos()+1);
                }
            }
            else
            {
                pickerBox.resetToOldRGBInfoText();
            }
        }

        private function onRGBInfoTextChangeEvent(e:Event):void
        {
            checkRGBInfoTextFormat(false);
        }

        private function checkRGBInfoCursorPos(e:Event):void
        {
            if(pickerBox.rgbInfo.caretIndex < 4)
            {
                pickerBox.rgbInfo.setSelection(4,4);
            }

            if(pickerBox.rgbInfo.caretIndex < 0)
            {
                selectRGBInfoTextByRGBPos(2);
            }
            else if(selectedRGBInfoIndex !== getRGBInfoTextCursorPos())
            {
                selectRGBInfoTextByRGBPos(getRGBInfoTextCursorPos());
            }
        }

        private function getRGBInfoString(...args):String
        {
            if(args.length === 1)
            {
                if(args[0] is Vector.<uint>)
                {
                    return "RGB "+args[0][0]+","+args[0][1]+","+args[0][2];
                }
                else if(args[0] is uint || args[0] === 0)
                {
                    const c:Vector.<uint> = HEXtoRGB(args[0]);
                    return "RGB "+c[0]+","+c[1]+","+c[2];
                }
            }
            else if(args.length === 3)
            {
                return "RGB "+args[0]+","+args[1]+","+args[2];
            }

            return "";
        }

        private function getNewFileName():String
        {
            return getTimeStampTailHead()+" "+getRandomString(8)+".png"
        }

        private function updateStageOffset():void
        {
            const scale:Number = getUIScale();

            STAGE_TOP_OFFSET = (replayModeON) ? Math.round(topBar.BARSIZE*scale+replayTimeBox.BARSIZE*scale) : Math.round(topBar.BARSIZE*scale);
            STAGE_BOTTOM_OFFSET = 0;
            STAGE_RIGHT_OFFSET = 0;
            STAGE_LEFT_OFFSET = 0;

            if(captureModeON || replayModeON)
            {
                return;
            }

            if(sideBar.visible)
            {
                if(isRightSidebar)
                {
                    STAGE_RIGHT_OFFSET = Math.round(sideBar.getWidth());
                }
                else
                {
                    STAGE_LEFT_OFFSET = Math.round(sideBar.getWidth());
                }
            }
        }

        //드로우 모드와 리플레이 모드 캔버스 미러가 다를경우 undo 적용 이후에 mirror커맨드 넣어주도록 함
        private function checkMirrorCanvasReplayMirror():void
        {
            if(mirrorON !== rMirrorON)
            {
                mirrorCommandReady = true;
                mirrorDraw();
                checkGridMirror(mirrorON);
                setRCursorMirrorPos();
            }
            else if(mirrorCommandReady)
            {
                mirrorCommandReady = false;
            }
        }

        private function setlassoMenuTempOFF():void
        {
            lassoMenu.visible = true;
            lassoMenuTempOFF = false;
            resetNowKey();
        }

        private function setRCursorMirrorPos():void
        {
            const p:Point = tickDraw.getRCursorPos();
            const half:Number = CANVAS_WIDTH/2;
            const curcorX:Number = rCursor.x+(half-p.x)*2;

            rCursor.x = curcorX;
            tickDraw.setRCursorPos(curcorX,p.y);
        }

        private function setRCursorVisibleONFadeOFF():void
        {
            rCursor.alpha = 1.0;
            rCursor.visible = true;

            addTimerByName("rCursorOffAlphaAnimTimer",0.0,true,function():Boolean
            {
                if(rCursor.visible === false)
                {
                    return false;
                }

                rCursor.alpha -= 0.1;

                if(rCursor.alpha < 0.0)
                {
                    rCursor.visible = false;
                    rCursor.alpha = 1.0;

                    return false;
                }

                return true;
            });
        }

        private function setRCursorVisibleONUndo(undoIndex:int):void
        {
            if(undoIndex < 0)
            {
                if(tickDraw.hasRCursorFirstPos())
                {
                    const p:Point = tickDraw.getFirstRCursorPos();
                    tickDraw.setRCursorPos(p.x,p.y); //커서 위치도 업에이트 해줘야함 대칭해줄띠 getRcursor로 하기 때문에
                    tickDraw.updateRCursorPosToFirst();
                }
                else
                {
                    rCursor.visible = false;
                    toolTipBoxTimerOFF();
                }
            }
            else
            {
                tickDraw.updateRCursorPos();
            }
        }

        private function checkFOFOSideBarCollision():int
        {
            const sideBarWidth:Number = sideBar.getWidth();
            const scale:Number = getUIScale();
            const fofoHeight:Number = fofo.height-20*scale;
            const fofoTopRect:Rectangle = new Rectangle(sideBar.x,STAGE_TOP_OFFSET,sideBarWidth,fofoHeight);
            const fofoBottomRect:Rectangle = new Rectangle(sideBar.x,stage.stageHeight-STAGE_BOTTOM_OFFSET-fofoHeight,sideBarWidth,fofoHeight);
            const gp:Point = sideBarScrollSet.localToGlobal(ZERO_POINT);
            const sideBarRect:Rectangle = new Rectangle(gp.x-sideBarScrollSet.x*scale,gp.y,sideBar.getWidth(),getSidebarConstHeight()*scale);
            const collisionTop:Boolean = sideBarRect.intersects(fofoTopRect);
            const collisionBottom:Boolean = sideBarRect.intersects(fofoBottomRect);

            return (collisionTop && collisionBottom) ? 0 : (collisionBottom) ? 1 : (collisionTop) ? 2 : 3;
        }

        private function checkFOFOPosition():void
        {
            if(sideBar.visible === false)
            {
                fofo.visible = false;
                return;
            }

            const checkYPos:int = checkFOFOSideBarCollision();

            fofo.visible = sideBar.visible;

            if(checkYPos === 3)
            {
                return;
            }
            else if(checkYPos === 0)
            {
                fofo.visible = false;
            }
            else if(checkYPos === 1)
            {
                fofo.setTop(STAGE_TOP_OFFSET);

                if(isRightSidebar)
                {
                    fofo.setMirror(false);
                    fofo.x = sideBar.x+sideBar.getWidth()-fofo.width;
                }
                else
                {
                    fofo.setMirror(true);
                    fofo.x = sideBar.x;
                }

                if(fofo.visible === false)
                {
                    fofo.visible = true;
                }
            }
            else if(checkYPos === 2)
            {
                if(isRightSidebar)
                {
                    fofo.setMirror(false);
                    fofo.x = sideBar.x+sideBar.getWidth()-fofo.width;
                }
                else
                {
                    fofo.setMirror(true);
                    fofo.x = sideBar.x;
                }

                fofo.setBottom(stage.stageHeight-STAGE_BOTTOM_OFFSET);

                if(fofo.visible === false)
                {
                    fofo.visible = true;
                }
            }
        }

        private function updateCanvasWindowCanvasPanelBGColor(color:uint,bmpd:BitmapData):void
        {
            if(canvasWindowCanvasPanelBgSize.x === bmpd.width
            && canvasWindowCanvasPanelBgSize.y === bmpd.height
            && canvasWindowCanvasPanelBgColor === color)
            {
                return;
            }

            canvasWindowCanvasPanel.graphics.clear();
            canvasWindowCanvasPanel.graphics.beginFill(color,1.0);
            canvasWindowCanvasPanel.graphics.drawRect(0,0,bmpd.width,bmpd.height);
            canvasWindowCanvasPanel.graphics.endFill();
            canvasWindowCanvasPanelBgSize.setTo(bmpd.width,bmpd.height);
            canvasWindowCanvasPanelBgColor = color;
        }

        private function setCanvasWindowVisible(flag:Boolean):void
        {
            canvasWindow.visible = flag;
        }

        private function updateCanvasWindowBitmapSize():void
        {
            const bounds:Rectangle = previewBox.setFitBitmapforBox(canvas1BitmapData.width,canvas1BitmapData.height
                                                                  ,canvasWindow.stage.stageWidth,canvasWindow.stage.stageHeight);
            updateCanvasWindowCanvasPanelBGColor(CANVAS_BG_COLOR,canvas1BitmapData);
            canvasWindowCanvasPanel.x = bounds.x;
            canvasWindowCanvasPanel.y = bounds.y;
            canvasWindowCanvasPanel.width = bounds.width;
            canvasWindowCanvasPanel.height = bounds.height;
        }

        private function updateCanvasWindowData():void
        {
            addTimerByName("canvasWindowUpdateDelayTimer",0.2,false,
            function ():void
            {
                canvasWindowInfo[0] = canvasWindow.x;
                canvasWindowInfo[1] = canvasWindow.y;
                canvasWindowInfo[2] = canvasWindow.width;
                canvasWindowInfo[3] = canvasWindow.height;

                if(canvasWindowCanvasPanel.width !== canvasWindow.stage.stageWidth
                || canvasWindowCanvasPanel.height !== canvasWindow.stage.stageHeight)
                {
                    updateCanvasWindowBitmapSize();
                    return;
                }
            });
        }

        private function canvasWindowMovedEvent(e:Event):void
        {
            updateCanvasWindowData();
        }

        private function canvasWindowResizedEvent(e:Event):void
        {
            if(!canvasWindowIgnoreResizeEventFlag) updateCanvasWindowData();
            else canvasWindowIgnoreResizeEventFlag = false;
        }

        private function updateCanvasWindowImage():void
        {
            canvasWindowBitmap.bitmapData = previewBox.prevBitmap.bitmapData;
            canvasWindowBitmapSub.bitmapData = previewBox.prevBitmapSub.bitmapData;
            canvasWindowBitmap.smoothing = true;
            canvasWindowBitmapSub.smoothing = true;
        }

        private function setSyncWindowTitle():void
        {
            canvasWindow.title = stage.nativeWindow.title;
        }

        private function fitCanvasWindowSizeToCanvas():void
        {
            if(canvasWindowCanvasPanel.width === canvasWindow.stage.stageWidth
            && canvasWindowCanvasPanel.height === canvasWindow.stage.stageHeight)
            {
                return;
            }

            canvasWindowIgnoreResizeEventFlag = true;
            canvasWindow.bounds = new Rectangle(canvasWindow.bounds.x,canvasWindow.bounds.y
                                                ,canvasWindowCanvasPanel.width,canvasWindowCanvasPanel.height);
            //한번 더해줘야 정확함
            canvasWindowIgnoreResizeEventFlag = true;
            canvasWindow.bounds = new Rectangle(canvasWindow.bounds.x,canvasWindow.bounds.y
                                                ,canvasWindow.bounds.width+(canvasWindowCanvasPanel.width-canvasWindow.stage.stageWidth)
                                                ,canvasWindow.bounds.height+(canvasWindowCanvasPanel.height-canvasWindow.stage.stageHeight));

            canvasWindowCanvasPanel.x = 0;
            canvasWindowCanvasPanel.y = 0;
        }

        private function canvasWindowMoveStartEvent(e:MouseEvent):void
        {
            canvasWindow.startMove();
        }

        private function fitCanvasWindowSizeToCanvasRightMouseUp(e:MouseEvent):void
        {
            if(canvasWindowCanvasPanel.width === canvasWindow.width
            && canvasWindowCanvasPanel.height === canvasWindow.height)
            {
                return;
            }

            fitCanvasWindowSizeToCanvas();
        }

        private function closeCanvasWindowTemp():void
        {
            canvasWindow.visible = false;
            canvasWindowON = false;
            if(!replayModeON && !captureModeON)
            {
                topBar.newWindowButton.visible = true;
                topBar.newWindowCloseButton.visible = false;
            }
            stage.nativeWindow.activate();
        }

        private function canvasWindowCloseKeyDown(e:KeyboardEvent):void
        {
            if(e.keyCode === KEY.esc) closeCanvasWindowTemp();
        }

        private function canvasWindowClosedEvent(e:Event):void
        {
            if(windowClosingFlag == false)
            {
                e.preventDefault();
                closeCanvasWindowTemp();
            }
        }

        private function initCanvasWindow():void
        {
            var windowOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
            windowOptions.systemChrome = NativeWindowSystemChrome.STANDARD;
            windowOptions.type = NativeWindowType.NORMAL;
            windowOptions.owner = stage.nativeWindow;
            windowOptions.renderMode = "direct";

            canvasWindow = new NativeWindow(windowOptions);

            setSyncWindowTitle();
            canvasWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
            canvasWindow.stage.align = StageAlign.TOP_LEFT;
            canvasWindow.stage.addEventListener(MouseEvent.MOUSE_DOWN,canvasWindowMoveStartEvent);
            canvasWindow.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,fitCanvasWindowSizeToCanvasRightMouseUp);
            canvasWindow.stage.addEventListener(KeyboardEvent.KEY_DOWN,canvasWindowCloseKeyDown);
            canvasWindow.addEventListener(Event.CLOSING,canvasWindowClosedEvent);
            canvasWindow.addEventListener(Event.RESIZE,canvasWindowResizedEvent);
            canvasWindow.addEventListener(NativeWindowBoundsEvent.MOVE,canvasWindowMovedEvent);
            canvasWindow.addEventListener(Event.ACTIVATE,canvasWindowActivatedEvent);

            canvasWindowCanvasPanel = new Sprite();
            canvasWindowCanvasPanel.name = "canvasWindowCanvasPanel";
            canvasWindowBitmap = new Bitmap();
            canvasWindowBitmapSub = new Bitmap();
            updateCanvasWindowImage();

            canvasWindowCanvasPanel.addChild(canvasWindowBitmapSub);
            canvasWindowCanvasPanel.addChild(canvasWindowBitmap);
        }

        private function canvasWindowActivatedEvent(e:Event):void
        {
            canvasWindowON = true;
            if(!replayModeON && !captureModeON)
            {
                topBar.newWindowButton.visible = false;
                topBar.newWindowCloseButton.visible = true;
            }
            if(canvasWindow.stage.getChildByName("canvasWindowCanvasPanel") === null)
            {
                canvasWindow.stage.addChild(canvasWindowCanvasPanel);
                canvasWindow.stage.color = uiColorSet[uiColorIndex][2];
            }

            updateCanvasWindowImage();
            updateCanvasWindowBitmapSize();
            updateCanvasWindowData();
        }

        private function openImageViewWindow():void
        {
            if(canvasWindow === null)
            {
                initCanvasWindow();
                if(canvasWindowInfo[0] === null)
                {
                    canvasWindowInfo[0] = stage.nativeWindow.x+topBar.newWindowButton.x-canvasWindowInfo[2]/2;
                    canvasWindowInfo[1] = stage.nativeWindow.y;
                }
                canvasWindow.bounds = new Rectangle(canvasWindowInfo[0],canvasWindowInfo[1],canvasWindowInfo[2],canvasWindowInfo[3]);
            }

            canvasWindow.activate();
        }

        private function setLayerVisibleHint(layer:int):void
        {
            var layer1FlagStr:String = ((canvas1Bitmap.visible)?"ON":"OFF");
            var layer2FlagStr:String = ((canvas11Bitmap.visible)?"ON":"OFF");
            if(layer === 1) layer1FlagStr = "\'"+layer1FlagStr+"\'";
            else if(layer === 2) layer2FlagStr = "\'"+layer2FlagStr+"\'";

            const layer1Str:String = "Layer 1 "+layer1FlagStr;
            const layer2Str:String = "Layer 2 "+layer2FlagStr;

            setToolTipTempON(layer1Str+"\n"+layer2Str);
        }

        private function isSubLayerONReplayMode():Boolean
        {
            return rcanvasPanel.getChildIndex(rcanvas2) < rcanvasPanel.getChildIndex(rcanvas1Bitmap);
        }

        private function setClearButtonActive():void
        {
            if(!isInSaveProgress && topBar.clearButton.alpha < 1.0) topBar.clearButton.alpha = 1.0;
            if(controlBox.layerMergeButton.alpha < 1.0) controlBox.layerMergeButton.alpha = 1.0;
            setWindowTitleStar();
        }

        private function isAllLayerInvisible():Boolean
        {
            if(!canvas1Bitmap.visible && !canvas11Bitmap.visible)
            {
                setToolTipTempON("All layer locked");
                return true;
            }
            return false;
        }

        private function mergeLassoImageToTraceLayer():void
        {
            if(lassoCopyON)
            {
                drawLassoBoxImageToBitmapData(true);
                disposeLassoBMP();
                resetLassoBox();
            }
            else
            {
                if(deepUndoON) setApplyDeepUndo();
                const lassoInfo:Array = drawLassoBoxImageToBitmapData(true);
                const point1:Vector.<Number> = lassoPointSave[0].concat();
                const point2:Array = lassoPointSave[1].concat();
                
                var l1:Boolean = true;
                var l2:Boolean = true;

                if(checkedLayer === 1 || (canvas1Bitmap.visible && !canvas11Bitmap.visible))
                {
                    l1 = true;
                    l2 = false;
                }
                else if(checkedLayer === 2 || (!canvas1Bitmap.visible && canvas11Bitmap.visible))
                {
                    l1 = false;
                    l2 = true;
                }

                rDataBuffer.push(["lassodel2",point1,point2,lassoInfo,lassoCopyON,l1,l2]);
                undoData.addNew();

                disposeLassoBMP();
                resetLassoBox();
            }

            if(canvasTraceLayer.visible === false || traceAlphaSave === 0.0)
            {
                updateTraceOpaButtonPosByAlpha(0.5);
                traceAlphaSave = 0.5;
                canvasTraceLayer.visible = true;
                canvasTraceLayer.alpha = 0.5;
            }
            canvasTraceBitmap.smoothing = true;
        }

        private function mergeImageToTraceLayer(layer1:IBitmapDrawable,layer2:IBitmapDrawable):void
        {
            var tracebmpd:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
            const mat:Matrix = new Matrix();

            mat.scale(canvasTraceLayer.scaleX,canvasTraceLayer.scaleY);
            mat.rotate(canvasTraceLayer.rotation*Math.PI/180)
            mat.translate(CANVAS_WIDTH/2,CANVAS_HEIGHT/2);

            tracebmpd.draw(canvasTraceLayer,mat);

            if(layer2 !== null) tracebmpd.draw(layer2);
            if(layer1 !== null) tracebmpd.draw(layer1);

            if(canvasTraceBitmapData && tracebmpd !== canvasTraceBitmapData) canvasTraceBitmapData.dispose();
            canvasTraceBitmapData = tracebmpd.clone();
            canvasTraceBitmap.bitmapData = canvasTraceBitmapData;

            tracebmpd.dispose();
            tracebmpd = null;
        }

        private function setLayer1CheckToggle():void
        {
            if(controlBox.layer1CheckButton.visible === false)
            {
                checkedLayer = 1;
                controlBox.layer1CheckButton.visible = true;
                controlBox.layer1UncheckButton.visible = false;
                controlBox.layer2CheckButton.visible = false;
                controlBox.layer2UncheckButton.visible = true;
                toolBox.setToolButtonsForCheckedLayerON(BUTTON_OFF_ALPHA);
                toolBox2.setToolButtonsForCheckedLayerON(BUTTON_OFF_ALPHA);
            }
            else
            {
                checkedLayer = 0;
                controlBox.layer1CheckButton.visible = false;
                controlBox.layer1UncheckButton.visible = true;
                toolBox.setToolButtonsForCheckedLayerOFF();
                toolBox2.setToolButtonsForCheckedLayerOFF();
            }
        }

        private function setLayer2CheckToggle():void
        {
            if(controlBox.layer2CheckButton.visible === false)
            {
                checkedLayer = 2;
                controlBox.layer2CheckButton.visible = true;
                controlBox.layer2UncheckButton.visible = false;
                controlBox.layer1CheckButton.visible = false;
                controlBox.layer1UncheckButton.visible = true;
                toolBox.setToolButtonsForCheckedLayerON(BUTTON_OFF_ALPHA);
                toolBox2.setToolButtonsForCheckedLayerON(BUTTON_OFF_ALPHA);
            }
            else
            {
                checkedLayer = 0;
                controlBox.layer2CheckButton.visible = false;
                controlBox.layer2UncheckButton.visible = true;
                toolBox.setToolButtonsForCheckedLayerOFF();
                toolBox2.setToolButtonsForCheckedLayerOFF();
            }
        }

        private function setLayer1CheckToggleCaptureMode():void
        {
            topBar.capClipBoard.alpha = 1.0;

            if(replayModeON)
            {
                if(rcanvas1Bitmap.visible)
                {
                    rcanvas1Bitmap.visible = false;
                    if(!isSubLayerONReplayMode()) rcanvas2.visible = false;

                    topBar.capLayer1VisibleButton.alpha = BUTTON_OFF_ALPHA;
                    if(topBar.capLayer2VisibleButton.alpha < 1.0)
                    {
                        setLayer2CheckToggleCaptureMode();
                    }
                }
                else
                {
                    rcanvas1Bitmap.visible = true;
                    if(!isSubLayerONReplayMode()) rcanvas2.visible = true;

                    topBar.capLayer1VisibleButton.alpha = 1.0;
                }
            }
            else
            {
                if(canvas1Bitmap.visible)
                {
                    canvas1Bitmap.visible = false;
                    topBar.capLayer1VisibleButton.alpha = BUTTON_OFF_ALPHA;
                    if(topBar.capLayer2VisibleButton.alpha < 1.0)
                    {
                        setLayer2CheckToggleCaptureMode();
                    }
                }
                else
                {
                    canvas1Bitmap.visible = true;
                    topBar.capLayer1VisibleButton.alpha = 1.0;
                }
            }
        }

        private function setLayer2CheckToggleCaptureMode():void
        {
            topBar.capClipBoard.alpha = 1.0;

            if(replayModeON)
            {
                if(rcanvas11Bitmap.visible)
                {
                    rcanvas11Bitmap.visible = false;
                    if(isSubLayerONReplayMode()) rcanvas2.visible = false;

                    topBar.capLayer2VisibleButton.alpha = BUTTON_OFF_ALPHA;
                    if(topBar.capLayer1VisibleButton.alpha < 1.0)
                    {
                        setLayer1CheckToggleCaptureMode();
                    }
                }
                else
                {
                    rcanvas11Bitmap.visible = true;
                    if(isSubLayerONReplayMode()) rcanvas2.visible = true;

                    topBar.capLayer2VisibleButton.alpha = 1.0;
                }
            }
            else
            {
                if(canvas11Bitmap.visible)
                {
                    canvas11Bitmap.visible = false;
                    topBar.capLayer2VisibleButton.alpha = BUTTON_OFF_ALPHA;
                    if(topBar.capLayer1VisibleButton.alpha < 1.0)
                    {
                        setLayer1CheckToggleCaptureMode();
                    }
                }
                else
                {
                    canvas11Bitmap.visible = true;
                    topBar.capLayer2VisibleButton.alpha = 1.0;
                }
            }
        }

        private function addUndoBGColor(color:uint):void
        {
            if(hasLastRDataCommand("bgColor"))
            {
                rDataBuffer.push(["bgColor",color]);
                updateLastRDataCommand("bgColor");
                undoData.addContinue();
            }
            else
            {
                if(deepUndoON) setApplyDeepUndo();
                rDataBuffer.push(["bgColor",color]);
                undoData.addNew();
            }
        }

        private function updateLastRDataCommand(command:String):void
        {
            if(rData.length === 0) return;

            const arr:Array = rData[rData.length-1];
            if(arr.length === 1)
            {
                rData[rData.length-1] = rDataBuffer.concat();
                rDataBuffer = [];
            }
            else
            {
                for(var i:uint=0; i<arr.length; i++)
                {
                    if(command === arr[i][0])
                    {
                        //rdata버퍼가 배열이기 때문에 concat을 하면 배열안에 배열이 있어서 0번만 반환해줌
                        //buffer.concat -> [["data",11]] //이런식으로 반환이됨
                        arr[i] = rDataBuffer[0].concat();
                        rDataBuffer = [];
                        break;
                    }
                }
            }
            rDataFrame[rDataFrame.length-1] = rData[rData.length-1].length;
        }

        private function deleteLastRDataCommand(command:String):void
        {
            if(rData.length === 0) return;

            const index:int = undoIndex;

            if(rData[index].length === 1)
            {
                rData.splice(index);
                rDataFrame.splice(index);
            }
            else
            {
                const len:uint = rData[index].length;
                for(var i:uint=0;i<len;i++)
                {
                    if(command === rData[index][i][0])
                    {
                        rData[index].splice(i,1)
                        --i;
                    }
                }
                rData.splice(index+1);
                rDataFrame.splice(index+1);
            }

            undoDelFlag = false;
            undoData.updateLastRDataMirror();
            undoIndex = rData.length-1;
        }

        private function hasLastRDataCommand(command:String):Boolean
        {
            const index:int = undoIndex;

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

        private function setLayerMergeButton():void
        {
            if(hasLastRDataCommand("merge"))
            {
                deleteLastRDataCommand("merge");
            }
            else
            {
                if(deepUndoON)
                {
                    setApplyDeepUndo();
                }

                canvas11BitmapData.draw(canvas1BitmapData);
                canvas1BitmapData.fillRect(new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT),0);
                rDataBuffer.push(["merge"]);
                undoData.addNew();
            }
            controlBox.layerMergeButton.alpha = BUTTON_OFF_ALPHA;
        }

        private function setLayerSwapButton():void
        {
            if(controlBox.layerSwapButton.alpha < 1.0) return;

            if(deepUndoON) setApplyDeepUndo();

            layerSwappedFlag = !layerSwappedFlag;

            var tempbmpd1:BitmapData = canvas1BitmapData.clone();
            var tempbmpd11:BitmapData = canvas11BitmapData.clone();
            const rect:Rectangle = new Rectangle(0,0,canvas1BitmapData.width,canvas1BitmapData.height);

            canvas1BitmapData.fillRect(rect,0);
            canvas11BitmapData.fillRect(rect,0);

            canvas1BitmapData.draw(tempbmpd11);
            canvas11BitmapData.draw(tempbmpd1);

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
                undoData.addNew();
            }

            setLayerSwapEffect(controlBox.layerSwapButton);
        }

        private function getCaptrueImageBitmapdata(clipBoardCopyFlag:Boolean):BitmapData
        {
            const isReplayMode:Boolean = replayModeON;
            var rect:Rectangle = (!drawCaptureArea.isFullImageCapture()) ? drawCaptureArea.getCaptureArea() : null;
            var layer1:Boolean;
            var layer2:Boolean;

            if(isReplayMode)
            {
                layer1 = rcanvas1Bitmap.visible;
                layer2 = rcanvas11Bitmap.visible;
            }
            else
            {
                layer1 = canvas1Bitmap.visible;
                layer2 = canvas11Bitmap.visible;
            }

            const bmpd:BitmapData = getMergedBitmapdtata(isReplayMode,(captureModeON && captureTransBGON && !clipBoardCopyFlag) ? true : false,layer1,layer2,rect);
            const mat:Matrix = new Matrix();
            const deg:Number = 90*captureRotated;
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

            if(captureFlipped)
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
            if(capStampON && tmpbmpd.width >= 300) drawCaptureStamp.kungFinal(tmpbmpd);
            bmpd.dispose();

            return tmpbmpd;
        }

        private function copyCaptureImageToCilpBoard():void
        {
            Clipboard.generalClipboard.setData(ClipboardFormats.BITMAP_FORMAT,getCaptrueImageBitmapdata(true),false);
            // setHintONTemp("The image copied to clipboard successfully");
            topBar.capClipBoard.alpha = BUTTON_OFF_ALPHA;
        }

        private function getUIScaleString(index:int):String
        {
            if(index === 0)
            {
                return "100%";
            }
            else
            {
                return getUIScale()*100+"%";
            }
        }

        private function getUIScale():Number
        {
            return uiScaleSet[uiScaleIndex];
        }

        private function resetUIScale():void
        {
            setUIScaleButton(uiScaleSet.length);
        }

        private function setUIScaleButton(index:int):void
        {
            if(index > uiScaleSet.length-1) index = 0;
            uiScaleIndex = index;

            const stw:Number = stage.stageWidth;
            const sth:Number = stage.stageHeight;
            const scale:Number = uiScaleSet[index];

            sideBar.setScale(scale);
            if(isRightSidebar) updateSidebarDefaultRightPos();
            else sideBar.x = 0;

            topBar.setScale(scale);
            topBar.updateTopbarBG(stw);
            topBar.updateTimerPos(stage.stageWidth);
            replayTimeBox.setScale(scale);
            rotateCursorBox.setScale(scale);
            hintBox.setScale(scale);
            toolTipBox.setScale(scale);
            hint.updateScale(scale);
            lassoMenu.setScale(scale);
            traceMenu.setScale(scale);
            fillPenBox.setScale(scale);
            toolBox2.setScale(scale);
            aboutPanel.setScale(scale);
            spuitZoomCursor.setScale(scale);
            loadMenuBox.setScale(scale);
            numPadBox.setScale(scale);
            updateStageOffset();
            updateScrollBarHeight();
            rCursor.setScale(scale);
            fofo.setScale(scale);
            checkFOFOPosition();
            autoScroll.updateScale(scale);
            hint.updateHintPos();

            //이거 위에서 뭔가 해주고 난후에 여기서 해줘야함
            sideBar.y = Math.round(STAGE_TOP_OFFSET);
            sideBar.updateSideBGSize(getSideBarBGHeight());

            if(lassoToolON) checkBoxPosition(lassoMenu);
            if(traceMenuON) checkBoxPosition(traceMenu);

            updatePreviewBoxRectPos();
            hint.off();
        }

        private function setQuickSidebarOFFWaitMouseUp(e:MouseEvent):void
        {
            _quickSidebarOFF();
        }

        private function _quickSidebarOFF():void
        {
            stage.removeEventListener(MouseEvent.MOUSE_UP,setQuickSidebarOFFWaitMouseUp);
            stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpQuickSidebarOFF);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownQuickSidebarOFF);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownQuickSidebarOFF);

            if(isSidebarVisible === false) sideBar.visible = false;
            setDefaultXSidebarPos();
            quickSidebarON = false;
            checkFOFOPosition();
            pickerBox.rgbInfo.type = TextFieldType.INPUT;

            if(toolBox.getLastTool() === "toolSpuit")
            {
                spuitTool();
            }

            if(traceMenuON)
            {
                traceMenu.visible = true;
            }

            if(hintBox.visible || hintHorverCursor.visible)
            {
                hint.off();
            }

            setStageFocusNull();
        }

        private function setQuickSidebarOFF():void
        {
            if(mouseClickON && sideBar.hitTestPoint(mouseX,mouseY))
            {
                stage.addEventListener(MouseEvent.MOUSE_UP,setQuickSidebarOFFWaitMouseUp);
                return;
            }

            _quickSidebarOFF();
        }

        private function rightMouseDownQuickSidebarOFF(e:MouseEvent):void
        {
            if(!e.target || rgbInfoFocusedON || numPadBox.visible)
            {
                return;
            }

            switch(e.target.name)
            {
                case "zoomInButton":
                case "zoomOutButton":
                {
                    if(zoomed !== 1.0) resetZoomDrawMode();
                }
                break;

                case "toolRotate":
                {
                    if(regPoint.rotation !== 0.0) resetRotationDrawMode();
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

            if(pickerBox.rgbInfo.type === TextFieldType.INPUT)
            {
                setQuickSidebarOFF();
            }
        }

        private function mouseDownQuickSidebarOFF(e:MouseEvent):void
        {
            if(e.target && e.target.name === "sideBarScrollBar") return;

            if(mouseX < sideBar.x || mouseX > sideBar.x+sideBar.getWidth()
            || mouseY < sideBar.y)
            {
                setQuickSidebarOFF();
            }
        }

        private function keyUpQuickSidebarOFF(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;
            if(keyCode === KEY.s || keyCode === KEY.d
            || keyCode === KEY.j || keyCode === KEY.k
            || keyCode === KEY.n6)
            {
                setQuickSidebarOFF();
            }
        }

        private function setDefaultXSidebarPos():void
        {
            if(isRightSidebar) updateSidebarDefaultRightPos();
            else sideBar.x = 0;
        }

        private function setQuickSidebarON(shortcut:Boolean):void
        {
            quickSidebarON = true;

            if(shortcut)
            {
                pickerBox.rgbInfo.type = TextFieldType.DYNAMIC;
                setNowToolByOldTool();
                stage.addEventListener(KeyboardEvent.KEY_UP,keyUpQuickSidebarOFF);
            }
            else
            {
                pickerBox.rgbInfo.type = TextFieldType.INPUT;
                stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownQuickSidebarOFF,false,-2);
            }
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownQuickSidebarOFF,false,-2);

            const sideBarWidth:Number = sideBar.getWidth();
            sideBar.x = mouseX-(sideBarWidth)/2+((isRightSidebar)? -18:22);

            if(sideBar.x < 0) sideBar.x = 0;
            else if(sideBar.x+sideBarWidth > stage.stageWidth) updateSidebarDefaultRightPos();

            if(sideBar.visible === true && isSidebarVisible === false)
            {
                penCursorPosition.removeSideBarClickEvents();
            }

            if(traceMenuON) traceMenu.visible = false;

            if(toolTipBox.visible) toolTipBoxTimerOFF();
            // setSidebarReCacheBitmap();
            sideBar.visible = true;
            checkFOFOPosition();
        }

        private function deleteOldAppData():void
        {
            if(appDataFile.exists === false)
            {
                const localFolder:File = File.applicationStorageDirectory;
                const list:Array = localFolder.getDirectoryListing();
                const len:uint = list.length;

                var newerVersion:Number = 0.0;
                var newerFileName:String = ""

                for (var i:uint=0; i<len; i++)
                {
                    if(list[i].name.indexOf("appdata") !== -1 && list[i].name !== "appdata"+APP_DATA_VERSION.toString())
                    {
                        if(newerVersion < parseFloat(list[i].name.substr(7)))
                        {
                            newerVersion = parseFloat(list[i].name.substr(7));
                            newerFileName = list[i].name;
                        }
                    }
                }

                if(newerFileName !== "")
                {
                    const fs:FileStream = new FileStream();
                    fs.open(localFolder.resolvePath(newerFileName), FileMode.READ);
                    var d:Object = fs.readObject();
                    fs.close();

                    if(d["rFileTotalFrame"] && d["rFileTotalFrame"] > 0.0)
                    {
                        oldAppdataRtotalFrame = d["rFileTotalFrame"];
                    }
                }

                for (i=0; i<len; i++)
                {
                    if(list[i].name.indexOf("appdata") !== -1 && list[i].name !== "appdata"+APP_DATA_VERSION.toString())
                    {
                        list[i].deleteFile();
                    }
                }
            }
        }

        private function onFromWorker(e:Event):void
        {
            var msg:* = backToMain.receive();
            const command:String = msg as String;

            if(command === "encodePNGCaptureDone")
            {
                workerDataReceiveCount++;
                workerPNGCaptureData.push(backToMain.receive(true));
            }
            else if(command === "encodePNGSaveDone")
            {
                workerDataReceiveCount++;
                workerPNGSaveData = backToMain.receive(true);
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
                workerUndoData.push([backToMain.receive(true),backToMain.receive(true)]);
            }

            if(!hasTimer("workerStopTimer"))
            {
                addTimerByName("workerStopTimer",WORKER_WAIT_INTERVAL,true,stopWorker);
            }
        }

        private function setStartWorker(func:Function):void
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

        private function stopWorker(forceFlag:Boolean=false):Boolean
        {

            if((workerDataSendCount === workerDataReceiveCount
                && workerPNGCaptureFileData === null
                && workerPNGSaveData === null
                && workerUndoData2 === null)
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

                    if(isInSaveProgress === 2)
                    {
                        windowClosingFlag = true;
                        isInSaveProgress = 0;
                        stage.nativeWindow.close();
                    }

                    if(saveThenLoadFlag)
                    {
                        loadImageDragDrop(false);
                    }
                    else if(updateAfterSaveFlag)
                    {
                        startUpdate();
                    }

                    setSaveProgressOFF();
                    return false;
                }
                return true;
        }

        private function startWorker():void
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

        private function makeWorker():void
        {
            var workerLoader:URLLoader = new URLLoader();
            workerLoader.dataFormat = URLLoaderDataFormat.BINARY;
            workerLoader.addEventListener(Event.COMPLETE, loadComplete);
            workerLoader.load(new URLRequest("worker.swf"));

            function loadComplete(e:Event):void
            {
                workerSWF = e.target.data as ByteArray;
                workerLoader = null;
            }
        }

        private function updateCanvasPanelMask(w:Number,h:Number):void
        {
            canvasPanel.scrollRect = new Rectangle(0,0,w,h);
        }

        private function cDottedLine():Object
        {
            const dotOldPoint:Point = new Point(0,0);
            const oldPoint:Point = new Point(0,0);
            var dotsize:Number = 4;
            var lineSize:Number = 1;
            var dotLineColor:uint = 0;

            function updateScale(zoomed:Number):void
            {
                lineSize = 1/zoomed;
                dotsize = 4/zoomed;
            }

            function ready(g:Graphics,x:Number,y:Number):void
            {
                dotLineColor = 0;
                dotOldPoint.setTo(x,y);
                oldPoint.setTo(x,y);
                g.lineStyle(lineSize,0);
                g.moveTo(x,y);
            }

            function getLineColor():uint
            {
                return dotLineColor;
            }

            function resetLineColor():void
            {
                dotLineColor = 0;
            }

            function setDotOldPoint(x:Number,y:Number):void
            {
                dotOldPoint.setTo(x,y);
            }

            function toggleLineColor():uint
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

            function draw(g:Graphics,x:Number,y:Number):void
            {
                const endpos:Point = new Point(x,y);
                const dist:Number = Point.distance(dotOldPoint,endpos);

                if(dist > dotsize)
                {
                    dotOldPoint.setTo(x,y);

                    const div:Number = Math.floor(dist/dotsize);
                    if(div > 0)
                    {
                        const minUnit:Number = (dotsize/dist);
                        var pos:Point;
                        var divPoint:Point;

                        for(var i:Number=div;i>=1;i--)
                        {
                            pos = Point.interpolate(oldPoint,endpos,minUnit*i);
                            g.lineTo(pos.x,pos.y);
                            g.lineStyle(lineSize,toggleLineColor());
                            g.moveTo(pos.x,pos.y);
                        }
                    }
                    else
                    {
                        g.lineStyle(lineSize,toggleLineColor());
                        g.moveTo(x,y);
                    }
                }
                else
                {
                    g.lineTo(x,y);
                }

                oldPoint.setTo(x,y);
            }

            return {
                draw:draw,
                ready:ready,
                setDotOldPoint:setDotOldPoint,
                resetLineColor:resetLineColor,
                getLineColor:getLineColor,
                updateScale:updateScale
            }
        }

        private function setResizeButtonColor(color:uint):void
        {
            resizeButtonR.setColor(color);
            resizeButtonL.setColor(color);
            resizeButtonD.setColor(color);
            resizeButtonU.setColor(color);
        }

        private function cCheckHideCursor():Object
        {
            var isMouseHide:Boolean = false;
            var count:int = 0;
            const pos:Point = new Point(0,0);

            function isMouseMoved():Boolean
            {
                return pos.x !== mouseX || pos.y !== mouseY || mouseClickON || rightMouseClickON;
            }

            function updateMousePos():void
            {
                pos.setTo(mouseX,mouseY);
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
                    if(isMouseMoved()) reset();
                }
                else
                {
                    if(count > stage.frameRate*2)
                    {
                        Mouse.hide();
                        setTopBarHintOFF();
                        isMouseHide = true;
                        updateMousePos();
                    }
                    else
                    {
                        count++;
                    }

                    if(isMouseMoved()) count = 0;

                    updateMousePos();
                }
            }

            return{
                check:check,
                reset:reset
            }
        }

        private function setNowKey(key:int):void
        {
            nowKey = key;
        }

        private function resetNowKey():void
        {
            nowKey = 0;
        }

        private function isNowKey(key:uint):Boolean
        {
            return nowKey === key;
        }

        private function isNowToolPenOrLine():Boolean
        {
            return  nowTool === TOOL_PEN || nowTool === TOOL_LINE;
        }

        private function isNowTool(tool:int):Boolean
        {
            return nowTool === tool;
        }

        private function setNowTool(tool:int):void
        {
            nowTool = tool;
        }

        private function resetOldTool():void
        {
            oldTool = TOOL_NONE;
        }

        private function isOldTool(tool:int):Boolean
        {
            return oldTool === tool;
        }

        private function setOldTool(tool:int):void
        {
            oldTool = tool;
        }

        private function updateOldTool():void
        {
            if(oldTool === TOOL_NONE)
            {
                oldTool = nowTool;
            }
        }

        private function setHoldKeyRepeat(firstCall:Boolean,func:Function,...args):Boolean
        {
            if(hasTimer("keyHoldWaitTimer") || hasTimer("keyHoldRepeatTimer")) return false;

            addTimerByName("keyHoldWaitTimer",KEY_REPEAT_DELAY,false,
            function():void
            {
                func.apply(main,args);
                addTimerByName("keyHoldRepeatTimer",KEY_REPEAT_INTERVAL,true,func,args);
            });

            addCancelAutoKeyEvent();
            if(firstCall) func.apply(main,args);

            return true;
        }

        private function checkMoreOptionsKeyDown(keyCode:uint):Boolean
        {
            if(KEY_BUFFER[1] === KEY.n3 || KEY_BUFFER[1] === KEY.n8)
            {
                if(controlBox.sharpLineButtonWrapper.alpha === 1.0)
                {
                    setSharpLineButtonShortcut();
                }
                return true;
            }
            else if(KEY_BUFFER[1] === KEY.n4 || KEY_BUFFER[1] === KEY.n7)
            {
                if(isNowToolPenOrLine() || isNowTool(TOOL_FILL_PEN))
                {
                    setPenAirBrushButtonShortCut();
                    return true;
                }
                else if(isNowTool(TOOL_ERASE))
                {
                    setEraseAirBrushButtonShortCut();
                    return true;
                }
            }
            return false;
        }

        private function checkOpaSizeKeyDown(keyCode:uint):Boolean
        {
            switch(keyCode)
            {
                case KEY.f:
                case KEY.h:
                    setHoldKeyRepeat(true,shortCutPenSize,true);
                return true;

                case KEY.v:
                case KEY.n:
                    setHoldKeyRepeat(true,shortCutPenSize,false);
                return true;

                case KEY.g:
                    setHoldKeyRepeat(true,shortCutPenAlpha,true);
                return true;

                case KEY.b:
                    setHoldKeyRepeat(true,shortCutPenAlpha,false);
                return true;
            }

            return false;
        }

        private function isPressingControl():Boolean
        {
            return getCommandKey() === COMMAND_CTRL;
        }

        private function isPressingShift():Boolean
        {
            return getCommandKey() === COMMAND_SHIFT;
        }

        private function isPressingControlShift():Boolean
        {
            return getCommandKey() === COMMAND_CTRL_SHIFT;
        }

        private function getCommandKey():int
        {
            const first:uint = KEY_BUFFER[0];
            const second:uint = KEY_BUFFER[1];

            if((second === KEY.shift && (first === KEY.ctrl || first === KEY.rightCtrl))
            || (first === KEY.shift && (second === KEY.ctrl || second === KEY.rightCtrl))) return COMMAND_CTRL_SHIFT;
            if(first === KEY.shift) return COMMAND_SHIFT;
            if(first === KEY.ctrl || first === KEY.rightCtrl) return COMMAND_CTRL;

            return 0;
        }

        private function isToolActive():Boolean
        {
            if(checkedLayer === 0) return true;

            setToolTipTempON("Tool locked");

            return false;
        }

        private function isCurrentLayerActive():Boolean
        {
            if(!canvas1Bitmap.visible && !canvas11Bitmap.visible)
            {
                setToolTipTempON("All layer locked");
                return false;
            }

            if(subLayerON === false)
            {
                if(canvas1Bitmap.visible)
                {
                    return true;
                }
                else
                {
                    setToolTipTempON("Layer 1 locked");
                    return false;
                }
            }
            else if(subLayerON === true)
            {
                if(canvas11Bitmap.visible)
                {
                    return true;
                }
                else
                {
                    setToolTipTempON("Layer 2 locked");
                    return false;
                }
            }
            return false;
        }

        private function isCursorInDrawArea():Boolean
        {
            return !(topBar.hitTestPoint(mouseX,mouseY) || (sideBar.visible && sideBar.hitTestPoint(mouseX,mouseY)))
            // const mx:Number = mouseX;
            // const my:Number = mouseY;

            // if(mx <= STAGE_LEFT_OFFSET || mx >= stage.stageWidth -STAGE_RIGHT_OFFSET
            // || my <= STAGE_TOP_OFFSET  || my >= stage.stageHeight-STAGE_BOTTOM_OFFSET)
            // {
            //     return false;
            // }
            // return true;
        }

        private function setStageProperties():void
        {
            stage.vsyncEnabled = true;
            stage.scaleMode = StageScaleMode.NO_SCALE; //창크기 상관없이 스테이지 크기 고정
            stage.align = StageAlign.TOP_LEFT;
            stage.quality = StageQuality.BEST;
            stage.tabChildren = false;
            NativeApplication.nativeApplication.autoExit = true;
        }

        private function removeMouseKeyEventLassoTool():void
        {
            stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpLassoTool);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownLassoTool);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownLassoTool);
            stage.removeEventListener(MouseEvent.MOUSE_UP,mouseUpLassoTool);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownLassoTool);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,rightMouseUpLassoTool);
            addInputEventDrawMode();
        }

        private function addMouseKeyEventLassoTool():void
        {
            stage.addEventListener(KeyboardEvent.KEY_UP,keyUpLassoTool);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownLassoTool);
            stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownLassoTool);
            stage.addEventListener(MouseEvent.MOUSE_UP,mouseUpLassoTool,false,-1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownLassoTool);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,rightMouseUpLassoTool);
            stage.addEventListener(MouseEvent.MOUSE_OVER,lassoMenuHintONEvent);
            removeInputEventDrawMode();
        }

        private function mouseDownStage(e:MouseEvent):void
        {
            checkKeyInvalidKey();
            mouseClickON = true;

            if(stage.nativeWindow.active)
            {
                realWorkingTimer.resetAFKCount();
            }

            if(hint.isHintStarted() !== null)
            {
                hint.hintOFFImmediately()
            }
        }

        private function rightMouseDownStage(e:MouseEvent):void
        {
            checkKeyInvalidKey();
            rightMouseClickON = true;
            if(stage.nativeWindow.active)
            {
                realWorkingTimer.resetAFKCount();
            }
        }

        private function wheelDownStage(e:MouseEvent):void
        {
            if(captureModeON) return;

            if(hasTimer("toolTipTempONTimer"))
            {
                toolTipBoxTimerOFF();
            }

            if(lassoToolON)
            {
                lassoMenu.visible = false;
                lassoMenuTempOFF = true;
            }

            handTool(replayModeON,true);
        }

        private function mouseUpStage(e:MouseEvent):void
        {
            checkKeyInvalidKey();
            const mx:Number = mouseX;
            const my:Number = mouseY;

            mouseClickON = false;
            if(!mouseClickON && rightMouseClickON) mouseDragON = false;

            if(mx < 0 || mx > stage.stageWidth || my < 0 || my > stage.stageHeight)
            {
                if(sideBar.visible === false) penCursorPosition.setSideBarONWaitEvents();
            }

            if(stage.nativeWindow.active)
            {
                realWorkingTimer.resetAFKCount();
            }
        }

        private function rightMouseUpStage(e:MouseEvent):void
        {
            checkKeyInvalidKey();
            const mx:Number = mouseX;
            const my:Number = mouseY;

            rightMouseClickON = false;
            if(!mouseClickON && rightMouseClickON) mouseDragON = false;

            if(mx < 0 || mx > stage.stageWidth || my < 0 || my > stage.stageHeight)
            {
                if(sideBar.visible === false) penCursorPosition.setSideBarONWaitEvents();
            }

            if(stage.nativeWindow.active)
            {
                realWorkingTimer.resetAFKCount();
            }
        }

        private function mouseLeaveSideBarON():void
        {
            if(replayModeON || captureModeON || toolBox2.visible)
            {
                return;
            }

            if(!isSidebarVisible && !sideBar.visible)
            {
                const sideBarWidth:Number = sideBar.getWidth();

                if(((isRightSidebar && mouseX > stage.stageWidth-sideBarWidth)
                || (!isRightSidebar && mouseX < sideBarWidth))
                && mouseY > STAGE_TOP_OFFSET)
                {
                    penCursorPosition.checkSideBarON();
                }
            }
        }

        private function setWindowTitleStar():void
        {
            const titleEndStr:int = stage.nativeWindow.title.lastIndexOf(STRING_TITLE_FOFOPAINT);

            if(titleEndStr > 0 && stage.nativeWindow.title.charAt(titleEndStr-1) !== "*")
            {
                const starFileName:String = stage.nativeWindow.title.slice(0,titleEndStr)+"*";
                stage.nativeWindow.title = starFileName+STRING_TITLE_FOFOPAINT;

                if(canvasWindowON) setSyncWindowTitle();
            }
        }

        private function resetApp():void
        {
            appResetFlag = true;

            const files:File = File.applicationStorageDirectory;
            files.deleteDirectory(true);
        }

        // private function setSidebarReCacheBitmap():void
        // {
        //     // sideBar.cacheAsBitmap = false;
        //     // addTimerByName("sideBarReCacheAsBitmapTimer",0.0,false,function():void
        //     // {
        //     // });
        //         sideBar.cacheAsBitmap = true;
        // }

        private function setSidebarVisible(flag:Boolean,tempFlag:Boolean):void
        {
            if(tempFlag === false)
            {
                isSidebarVisible = flag;
            }

            if(flag)
            {
                sideBar.visible = true;

                //사이드바가 짤려 나오는 현상이 있어서 다시 캐쉬 풀었다가 다시 해줌
                // setSidebarReCacheBitmap();
            }
            else
            {
                sideBar.visible = false;

                if(hintBox.visible || hintHorverCursor.visible)
                {
                    hint.off();
                }
            }

            if(tempFlag === false)
            {
                topBar.checkSideBarONOFFButton(flag,isRightSidebar);
            }

            updateStageOffset();
            updatePreviewBoxRectPos();
            checkFOFOPosition();
        }

        private function selectTransparentColor():void
        {
            penColorTransparentFlag = true;
            pickerBox.updateOldRGBInfoText();
            pickerBox.setRGBInfoBGTransparentColorON(myPalettePresetType);
            pickerBox.setRGBInfo("Transparent");
        }

        private function setCurrentColor(mode:uint):void
        {
            const hexColor:uint = pickerBox.currentColorColor;

            penColorTransparentFlag = false;

            if(mode === 1)
            {
                penColor = hexColor;
                updateOpacityCursorPos(penAlphaIndex);
                setHSVCursorPosByColor((rgbInfoColorTypeHSV) ? HEXtoHSV(hexColor) : hexColor);
            }
            else if(mode === 2)
            {
                setBackgroundColorDrawMode(hexColor);
                if(canvasWindowON) updateCanvasWindowCanvasPanelBGColor(CANVAS_BG_COLOR,canvasWindowBitmap.bitmapData);
                setHSVCursorPosByColor((rgbInfoColorTypeHSV) ? HEXtoHSV(hexColor) : hexColor);
                addUndoBGColor(hexColor);
            }
        }

        private function getFinalImageFrom2020File(file:File,bgFlag:Boolean):BitmapData
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

        private function isNew2020File(file:File):Boolean
        {
            if(!file) return false;

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

        private function isOld2020File(file:File):Boolean
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

        private function isTrue2020File(file:File):Boolean
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

        private function isImageFileExt(path:String):Boolean
        {
            //가장 마지막 확장자만 따짐
            const gif:int = path.lastIndexOf(".gif");
            const jpg:int = path.lastIndexOf(".jpg");
            const png:int = path.lastIndexOf(".png");
            const find2020:int = path.lastIndexOf(".2020");
            const maxIndex:int = Math.max(gif,jpg,png,find2020);

            return maxIndex === find2020;
        }

        // private function cScanFillTool():Object
        // {
        //     const rect:Rectangle = new Rectangle();
        //     var bmpd:BitmapData;
        //     var baseColor:uint;
        //     var fillColor:uint;
        //     var alpha:Number;
        //     const ct:ColorTransform = new ColorTransform();

        //     function scanFillMouseUpEvent(e:MouseEvent):void
        //     {
        //         ct.alphaMultiplier = alpha;
        //         if(subLayerON)
        //         {
        //             canvas11BitmapData.draw(canvas2Draw,null,ct);
        //         }
        //         else
        //         {
        //             canvas1BitmapData.draw(canvas2Draw,null,ct);
        //         }
        //         canvas2Draw.graphics.clear();
        //         stage.removeEventListener(MouseEvent.MOUSE_MOVE,scanFillMouseMoveEvent);
        //         stage.removeEventListener(MouseEvent.MOUSE_UP,scanFillMouseUpEvent);
        //     }

        //     function drawScanLine():void
        //     {
        //         const startX:Number = Math.floor(canvas1Bitmap.mouseX);
        //         const startY:Number = Math.floor(canvas1Bitmap.mouseY);
        //         const fillColor:uint = 0xFF000000|penColor;
        //         var nowColor:uint;
        //         var leftX:Number = startX-1;
        //         var rightX:Number = startX+1;

        //         while(true)
        //         {
        //             nowColor = bmpd.getPixel32(leftX,startY);

        //             if(nowColor !== baseColor || leftX <= 0)
        //             {
        //                 break;
        //             }
        //             leftX--;
        //         }

        //         while(true)
        //         {
        //             nowColor = bmpd.getPixel32(rightX,startY);

        //             if(nowColor !== baseColor || rightX >= CANVAS_WIDTH)
        //             {
        //                 break;
        //             }
        //             rightX++;
        //         }

        //         canvas2Draw.graphics.lineStyle(1,fillColor,1.0,true,"normal",CapsStyle.NONE);
        //         canvas2Draw.graphics.moveTo(leftX-0.5,startY);
        //         canvas2Draw.graphics.lineTo(rightX+1.5,startY);
        //     }

        //     function scanFillMouseMoveEvent(e:MouseEvent):void
        //     {
        //         drawScanLine();
        //     }

        //     function updateMergedBmpd():void
        //     {
        //         // bmpd.lock();
        //         bmpd = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
        //         bmpd.fillRect(rect,0xFF000000|CANVAS_BG_COLOR);
        //         if(canvas11Bitmap.visible)
        //         {
        //             bmpd.draw(canvas11BitmapData);
        //         }

        //         if(canvas1Bitmap.visible)
        //         {
        //             bmpd.draw(canvas1BitmapData);
        //         }
        //     }

        //     function start():void
        //     {
        //         if(!canvas2Bitmap.bitmapData)
        //         {
        //             canvas2Bitmap.bitmapData = canvas2BitmapData;
        //         }
        //         rect.x = 0;
        //         rect.y = 0;
        //         rect.width = CANVAS_WIDTH;
        //         rect.height = CANVAS_HEIGHT;
        //         updateMergedBmpd();
        //         alpha = penAlpha;
        //         fillColor = 0xFF000000|penColor;
        //         baseColor = bmpd.getPixel32(Math.floor(canvas1Bitmap.mouseX),Math.floor(canvas1Bitmap.mouseY));

        //         if(!stage.getChildByName("testbmp"))
        //         {
        //             const bmp:Bitmap = new Bitmap(bmpd);
        //             bmp.name = "testbmp"
        //             bmp.scaleX = 0.3;
        //             bmp.scaleY = 0.3;
        //             stage.addChild(bmp);
        //             setTopChildIndex(bmp);
        //         }
        //         else
        //         {
        //             (stage.getChildByName("testbmp") as Bitmap).bitmapData = bmpd;
        //         }


        //         stage.addEventListener(MouseEvent.MOUSE_MOVE,scanFillMouseMoveEvent);
        //         stage.addEventListener(MouseEvent.MOUSE_UP,scanFillMouseUpEvent);
        //     }

        //     return {
        //         start:start
        //     };
        // }

        private function cFillPenTool():Object
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

            function updateFillPenPreview(e:Event):void
            {
                const newXcolor:uint = (penColorTransparentFlag) ? CANVAS_BG_COLOR : pickerBox.rgbInfoBGColor;
                const newXAlpha:Number = penAlpha
                const newXBlendMode:String = (penColorTransparentFlag) ? "erase" : null;

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

                if(!sideBar.visible || !sideBar.hitTestPoint(mouseX,mouseY) && !mouseClickON)
                {
                    fillPenPreviewModeFlag = false;
                    stage.removeEventListener(Event.ENTER_FRAME,updateFillPenPreview);
                    drawPreviewLine();
                }
            }

            function setFillPenColorPreviewMode():void
            {
                if(subLayerON)
                {
                    setCanvas2IndexToLayer2();
                }
                if(fillPenPreviewModeFlag === false)
                {
                    fillPenPreviewModeFlag = true;
                    stage.addEventListener(Event.ENTER_FRAME,updateFillPenPreview);
                }
            }

            function fillPenHint(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if(!target) return;

                const targetName:String = target.name;

                if(targetName === "fillPenOK") fillPenBox.hint("OK [q, o key up]");
                if(targetName === "fillPenCancel") fillPenBox.hint("Cancel\n[esc, backspace]");
                else if(targetName === "fillPenUndo") fillPenBox.hint("Undo [w, i]");
                else if(targetName === "fillPenSidebar") fillPenBox.hint("[6, s+d, j+k]");
            }

            function checkFillPenUndoReady():Boolean
            {
                if(canvasSizeRect.intersects(canvas2Draw.getBounds(canvasPanel)))
                {
                    return true;
                }
                return false;
            }

            function drawFillPenData():void
            {
                canvas2Draw.graphics.clear();

                if(data.length === 0) return;

                canvas2Draw.graphics.lineStyle(1,xColor);
                canvas2Draw.graphics.beginFill(xColor);
                canvas2Draw.graphics.drawPath(command,data);
                canvas2Draw.graphics.endFill();
                canvas2Draw.graphics.moveTo(data[data.length-2],data[data.length-1]);
                canvas2Draw.graphics.lineTo(data[0],data[1]);

                canvas2.alpha = xAlpha;
            }

            function drawPreviewLine():void
            {
                canvas2Draw.graphics.clear();

                const len:uint = data.length;
                if(len <= 3) return;

                dottedLine.ready(canvas2Draw.graphics,data[0],data[1]);

                for(var i:uint=2; i<len; i+=2)
                {
                    dottedLine.draw(canvas2Draw.graphics,data[i],data[i+1]);
                }
                dottedLine.draw(canvas2Draw.graphics,data[0],data[1]);

                if(subLayerON)
                {
                    setCanvas2IndexToLayer1();
                }

                canvas2.alpha = 1.0;
            }

            function cancelFillPen():void
            {
                removeEvents();
                canvas2.alpha = 1.0;
                mouseMoveCount = 0;
                fillPenStarted = false;
                command.length = 0;
                data.length = 0;
                commandUndoIndexArr.length = 0;
                canvas2Draw.graphics.clear();

                if(traceMenuON) traceMenu.visible = true;

                fillPenBox.visible = false;
                fillPenBox.x = -fillPenBox.width-3;
                fillPenBox.y = -fillPenBox.height-3;

                if(subLayerON)
                {
                    setCanvas2IndexToLayer2();
                }

                if(quickSidebarON)
                {
                    setQuickSidebarOFF();
                }

                toolBox.setFillPenModeOFF();
                controlBox.setFillPenModeOFF();
                pickerBox.checkPickerModeButton(1);
            }

            function endFillPenOK():void
            {
                if(checkFillPenUndoReady() === true && command.length > 2)
                {
                    readyAddUndoFlag = true;
                    command.push(2);
                    data.push(data[0]);
                    data.push(data[1]); //마지막으로 원점으로 선을 한번 이어줘야 깔끔하게 닫힘
                    canvas2.alpha = xAlpha;
                    rDataBuffer.push(["fill5",xColor,xAlpha,xBlendMode,command.concat(),data.concat(),airBrushON,airBrushSizeDrawMode]);

                    drawFillPenData();
                }

                resetCanvas2DrawCliprect();
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
                    canvas2Draw.graphics.clear();
                }
                else
                {
                    drawPreviewLine();
                }
            }

            function fillPenKeyDownEvent(e:KeyboardEvent):void
            {
                const keyCode:uint = e.keyCode;
                if(mouseClickON) return;

                if(keyCode === KEY.s || keyCode === KEY.k)
                {
                    if(KEY_BUFFER[1] === KEY.d || KEY_BUFFER[1] === KEY.j)
                    {
                        if(quickSidebarON === false)
                        {
                            setQuickSidebarON(true);
                            drawFillPenData();
                            setFillPenColorPreviewMode();
                        }
                    }
                }
                else if(keyCode === KEY.d || keyCode === KEY.j)
                {
                    if(KEY_BUFFER[1] === KEY.s || KEY_BUFFER[1] === KEY.k)
                    {
                        if(quickSidebarON === false)
                        {
                            setQuickSidebarON(true);
                            drawFillPenData();
                            setFillPenColorPreviewMode();
                        }
                    }
                }
                else if(keyCode === KEY.n6)
                {
                    if(quickSidebarON === false)
                    {
                        setQuickSidebarON(true);
                        drawFillPenData();
                        setFillPenColorPreviewMode();
                    }
                }
            }

            function fillPenKeyUpEvent(e:KeyboardEvent):void
            {
                const keyCode:uint = e.keyCode;

                if(mouseClickON)
                {
                    if(keyCode === KEY.q || keyCode === KEY.o || keyCode === KEY.enter)
                    {
                        afterKeyUpOK = true;
                    }
                    return;
                }

                if(keyCode === KEY.w || keyCode === KEY.i)
                {
                    undoData();
                }
                else if(keyCode === KEY.q || keyCode === KEY.o || keyCode === KEY.enter)
                {
                    endFillPenOK();
                }
                else if(keyCode === KEY.esc || keyCode === KEY.backspace)
                {
                    cancelFillPen();
                }
            }

            function fillPenRightMouseUpEvent(e:MouseEvent):void
            {
                if(!e.target as DisplayObject || e.target === sideBarScrollBar
                || sideBar.visible && sideBar.hitTestPoint(mouseX,mouseY))
                {
                    return;
                }

                const targetName:String = e.target.name;

                if(targetName === "fillPenOK")
                {
                    endFillPenOK();
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
                    setQuickSidebarON(false);
                    drawFillPenData();
                    setFillPenColorPreviewMode();
                }
                // else
                // {
                //     endFillPenOK();
                // }

                fillPenBox.visible = false;
            }

            function fillPenRightMouseDownEvent(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if(mouseClickON || quickSidebarON ||!target) return;

                if(target === sideBarScrollBar)
                {
                    resetSideBarPosition();
                    return;
                }
                else if(target.name === "zoomInButton" || target.name === "zoomOutButton")
                {
                    if(zoomed !== 1.0)
                    {
                        resetZoomDrawMode();
                    }
                    return;
                }
                else if(target.name === "toolRotate")
                {
                    if(regPoint.rotation !== 0.0)
                    {
                        resetRotationDrawMode();
                    }
                    return;
                }

                if(sideBar.visible && sideBar.hitTestPoint(mouseX,mouseY))
                {
                    return;
                }

                const scale:Number = fillPenBox.getScale();

                fillPenBox.visible = true;
                setTopChildIndex(fillPenBox);

                if(fillPenBoxUndoUsed)
                {
                    fillPenBox.x = Math.floor(mouseX-(fillPenBox.fillPenUndo.width/2)*scale);
                    fillPenBox.y = Math.floor(mouseY-(fillPenBox.fillPenUndo.y+fillPenBox.fillPenUndo.height/2)*scale);
                }
                else
                {
                    fillPenBox.x = Math.floor(mouseX-(fillPenBox.fillPenOK.x+fillPenBox.fillPenOK.width/2)*scale);
                    fillPenBox.y = Math.floor(mouseY-(fillPenBox.fillPenOK.y+fillPenBox.fillPenOK.height/2)*scale);
                }
            }

            function fillPenMouseUpEvent(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if(!target) return;

                const targetName:String = e.target.name;

                removeTimer("fillPenTimer");
                mouseDragON = false;
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,fillPenMouseMoveEvent);

                if(clickedButton === targetName)
                {
                    if(targetName === "toolFillPenOK")
                    {
                        endFillPenOK();
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
                            endFillPenOK();
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
                    const now:Point = new Point(mouseX,mouseY);
                    const dist:Number = Math.floor(Point.distance(now,lastMousePos));

                    mouseMoveCount += dist;
                    if(mouseMoveCount >= 10)
                    {
                        mouseMoveCount = 0;
                        commandUndoIndexArr.push(command.length-1);
                    }

                    lastMousePos.setTo(now.x,now.y);

                    if(afterKeyUpOK)
                    {
                        endFillPenOK();
                    }
                    else if(fillPenPreviewModeFlag === false)
                    {
                        drawPreviewLine();
                    }
                }

                afterKeyUpOK = false;
            }

            function fillPenMouseMoveEvent(e:MouseEvent):void
            {
                // if(readyAddUndoFlag === false) checkFillPenUndoReady();

                const filteredPos:Point = getFilteredPos(canvas2Draw.mouseX,canvas2Draw.mouseY);
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
                lastMousePos.setTo(mouseX,mouseY);

                if(!hasTimer("fillPenTimer"))
                {
                    addTimerByName("fillPenTimer",0.083,false,drawFillPenData);
                }
            }

            function fillPenMouseDownEvent(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if(!target) return;
                const targetName:String = target.name;

                clickedButton = targetName;

                if(fillPenBox.visible)
                {
                    return;
                }

                if(sideBar.visible && sideBar.hitTestPoint(mouseX,mouseY))
                {
                    if(targetName === "penColorButton"
                    || targetName === "paperColorButton"
                    || targetName === "rgbInfo")
                    {
                        return;
                    }

                    if(checkPickerBoxButtons(target))
                    {
                        setFillPenColorPreviewMode();
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
                            setHandToolPreviewBox(false);
                        }
                        return;

                        case "prevCursor":
                        {
                            setHandToolPreviewBox(true);
                        }
                        return;

                        case "zoomInButton":
                        case "zoomOutButton":
                        {
                            checkToolBoxMouseUp(targetName);
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
                            setFillPenColorPreviewMode();
                            setOpaButton(targetName);
                        }
                        break;

                        default:
                        break;
                    }
                }

                if(targetName === "sideBarScrollBar")
                {
                    setScrollBarMoveButton();
                }
                else if(isCursorInDrawArea() && quickSidebarON === false)
                {
                    mouseDragON = true;
                    stage.addEventListener(MouseEvent.MOUSE_MOVE,fillPenMouseMoveEvent);

                    const filteredPos:Point = getFilteredPos(canvas2Draw.mouseX,canvas2Draw.mouseY);
                    const mx:Number = filteredPos.x+pos05Offset;
                    const my:Number = filteredPos.y+pos05Offset;

                    if(subLayerON)
                    {
                        setCanvas2IndexToLayer2();
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
                fillPenBox.removeEventListener(MouseEvent.MOUSE_OVER,fillPenHint);
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,fillPenMouseDownEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,fillPenMouseUpEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,fillPenRightMouseDownEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,fillPenRightMouseUpEvent);
                stage.removeEventListener(KeyboardEvent.KEY_UP,fillPenKeyUpEvent);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN,fillPenKeyDownEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,fillPenMouseMoveEvent);
            }

            function addEvents():void
            {
                fillPenBox.addEventListener(MouseEvent.MOUSE_OVER,fillPenHint);
                stage.addEventListener(MouseEvent.MOUSE_DOWN,fillPenMouseDownEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,fillPenMouseUpEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,fillPenRightMouseDownEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,fillPenRightMouseUpEvent);
                stage.addEventListener(KeyboardEvent.KEY_UP,fillPenKeyUpEvent);
                stage.addEventListener(KeyboardEvent.KEY_DOWN,fillPenKeyDownEvent);
                stage.addEventListener(MouseEvent.MOUSE_MOVE,fillPenMouseMoveEvent);
            }

            function start():void
            {
                fillPenStarted = true;

                canvasSizeRect.width = CANVAS_WIDTH;
                canvasSizeRect.height = CANVAS_HEIGHT;

                command = new Vector.<int>();
                data = new Vector.<Number>();

                if(pickerMode !== 1)
                {
                    changePickerModeToPenColor();
                }
                mouseMoveCount = 0;
                afterKeyUpOK = false;
                pos05Offset = getSharpLineOffset(1.0);
                xColor = (penColorTransparentFlag) ? CANVAS_BG_COLOR : penColor;
                xAlpha = penAlpha;
                xBlendMode = (penColorTransparentFlag) ? "erase" : null;
                commandUndoIndexArr[0] = 0;
                clickedButton = null;
                fillPenBoxUndoUsed = false;

                if(airBrushON || eraseAirBrushON)
                {
                    canvas2Draw.filters = [];
                }

                if(!penColorTransparentFlag)
                {
                    if(!isCurrentColorSamePickedColor())
                    {
                        updatePickerCurrentColor(pickerBox.getRGBInfoBGColor());
                        addColorMyPaletteHistory(pickerBox.getRGBInfoBGColor());
                    }
                }

                if(traceMenuON) traceMenu.visible = false;
                dottedLine.updateScale(zoomed);

                const filteredPos:Point = getFilteredPos(canvas2Draw.mouseX,canvas2Draw.mouseY);
                var mx:Number = filteredPos.x+pos05Offset;
                var my:Number = filteredPos.y+pos05Offset;
                posSave.setTo(mx,my);

                command.push(1);
                data.push(mx);
                data.push(my);
                lastMousePos.setTo(mx,my);
                canvas2.alpha = xAlpha;
                toolBox.setFillPenModeON(BUTTON_OFF_ALPHA);
                controlBox.setFillPenModeON(BUTTON_OFF_ALPHA);
                pickerBox.fillPenModeON();

                addEvents();
            }

            return {
                start:start
            };
        }

        private function cPenTool():Function
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
            var pos05Offset:Number; //경계선 0.5를 조절해서 번지게 보이느냐 샤프하게 보이느냐
            var mouseMoveCount:int; //마우스 이벤트에서 움직일때 올려주는 카운터 한번에 너무 많이 움직여주면 cpu부하 먹어서 100카운트 마다 bmp에 그려줌
            var mouseMovedFlag:Boolean;
            var moveEventDistLimit:Number;//penmove에서 distlimit이하이면 jump해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌
            var dotflag:Boolean; //펜스무딩이 강하게 들어갔을때 아주 작은 위치만 그려주면 표현이 제대로 안되기 때문에 너무 작게 선이 그려졌을때 올려주는 플래그
            var sq1PXCursor:Boolean = false; //1픽셀 사각형 커서인경우 올려주고 커서 미리보기 회전적용되게 함

            function circleRectangleCollision(cx:Number, cy:Number, r:Number, rx:Number, ry:Number, w:Number, h:Number):Boolean
            {
                const px:Number = Math.max(rx, Math.min(cx,rx+w));
                const py:Number = Math.max(ry, Math.min(cy,ry+h));
                const distance:Number = (Math.sqrt(Math.pow(px-cx,2)+Math.pow(py-cy,2)));

                return distance <= r/2;
            }

            function checkPenToolUndoReady():void
            {
                if(canvas1Bitmap.hitTestPoint(mouseX,mouseY,true))
                {
                    readyAddUndoFlag = true;
                }
                else if(penCursorShape)
                {
                    if(canvasSizeRect.intersects(penSizeCursor.getBounds(canvasPanel)))
                    {
                        readyAddUndoFlag = true;
                    }
                }
                else if(circleRectangleCollision(canvasPanel.mouseX,canvasPanel.mouseY,penCursorSize,0,0,CANVAS_WIDTH,CANVAS_HEIGHT))
                {
                    readyAddUndoFlag = true;
                }
            }

            function lineStyleReady(shape:Boolean,size:uint,color:uint,alpha:Number):void
            {
                canvas2.alpha = alpha;

                if(shape === false)
                {
                    canvas2Draw.graphics.lineStyle(size,color);
                }
                else
                {
                    canvas2Draw.graphics.lineStyle(size,color,1,false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.BEVEL);
                }
            }

            function followCursorSmoothLine():void
            {
                var ox:Number = smoothPos.x;
                var oy:Number = smoothPos.y;

                ox += (smoothLast.x-ox)*penSmoothValue;
                oy += (smoothLast.y-oy)*penSmoothValue;

                penMove2(ox,oy);

                if(Math.abs(smoothLast.x-ox) < 0.02 && Math.abs(smoothLast.y-oy) < 0.02)
                {
                    return;
                }
                else
                {
                    smoothPos.setTo(ox,oy);
                    addTimerByName("followCursorSmoothLine",0.02,false,followCursorSmoothLine);
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


            function penMove2(mx:Number,my:Number):void
            {
                if(readyAddUndoFlag === false)
                {
                    checkPenToolUndoReady();
                }

                const filteredPos:Point = getFilteredPos(mx,my);

                mx = filteredPos.x+pos05Offset;
                my = filteredPos.y+pos05Offset;

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

                if(mouseMovedFlag === false) //움직이기 시작할때 linestyle이랑 moveto넣어줌
                {
                    mouseMovedFlag = true;

                    canvas2Draw.graphics.clear();
                    lineStyleReady(xShape,xSize,xColor,xAlpha);

                    if(xShape)
                    {
                        const filteredStartPos:Point = getFilteredPos(clickPos.x,clickPos.y);
                        filteredStartPos.x = filteredStartPos.x+pos05Offset;
                        filteredStartPos.y = filteredStartPos.y+pos05Offset;
                        updateExtendEndPoint(mx,my,filteredStartPos.x,filteredStartPos.y,xSize/8);
                        rDataBuffer.push(["lineStyle5",xShape,xSize,xColor,xAlpha,extendedPos.x,extendedPos.y,xBlendMode,false,subLayerON,airBrushSizeDrawMode]);
                        penPoints.push(extendedPos.x);
                        penPoints.push(extendedPos.y);
                        canvas2Draw.graphics.moveTo(extendedPos.x,extendedPos.y);
                    }
                    else
                    {
                        rDataBuffer.push(["lineStyle5",xShape,xSize,xColor,xAlpha,smoothPos.x+pos05Offset,smoothPos.y+pos05Offset,xBlendMode,false,subLayerON,airBrushSizeDrawMode]);
                        penPoints.push(smoothPos.x+pos05Offset);
                        penPoints.push(smoothPos.y+pos05Offset);
                        canvas2Draw.graphics.moveTo(smoothPos.x+pos05Offset,smoothPos.y+pos05Offset);
                    }
                }

                if(mouseMovedFlag)
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
                    canvas2Draw.graphics.lineTo(mx,my);

                    mouseMoveCount++;
                    if(mouseMoveCount >= 100)
                    {
                        mouseMoveCount = 0;

                        if(airBrushSizeDrawMode > 0)
                        {
                            const blurSize:Number = getBlurSize(airBrushSizeDrawMode,1.0);
                            canvas2Draw.filters = [new BlurFilter(blurSize,blurSize,3)];
                            canvas2BitmapData.draw(canvas2Draw,null,null,"layer");
                            canvas2Draw.filters = [];
                        }
                        else
                        {
                            canvas2BitmapData.draw(canvas2Draw,null,null,"layer");
                        }

                        canvas2Bitmap.bitmapData = canvas2BitmapData;
                        updateCanvas2DrawCliprect();
                        canvas2Draw.graphics.clear();

                        lineStyleReady(xShape,xSize,xColor,xAlpha);

                        const prevX:Number = penPoints[penPoints.length-4];
                        const prevY:Number = penPoints[penPoints.length-3];
                        penCommand.length = 0;
                        penPoints.length = 0;
                        rDataBuffer.push(["tempDone4"]);

                        if(xShape === true)
                        {
                            rDataBuffer.push(["lineStyle5",xShape,xSize,xColor,xAlpha,prevX,prevY,xBlendMode,false,subLayerON,airBrushSizeDrawMode]);
                            penCommand.push(1);
                            penPoints.push(prevX);
                            penPoints.push(prevY);
                            canvas2Draw.graphics.moveTo(prevX,prevY);
                        }
                        else
                        {
                            rDataBuffer.push(["lineStyle5",xShape,xSize,xColor,xAlpha,mx,my,xBlendMode,false,subLayerON,airBrushSizeDrawMode]);
                            penCommand.push(1);
                            penPoints.push(mx);
                            penPoints.push(my);
                            canvas2Draw.graphics.moveTo(mx,my);
                        }
                    }

                    if(xShape === true || sq1PXCursor === true)
                    {
                        const rad:Number = Math.atan2(mx-sqPenCursorLast.x,my-sqPenCursorLast.y);
                        const deg:Number = -rad*(180/Math.PI)+regPoint.rotation;

                        penSizeCursor.rotation = deg;
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

                //브러쉬 크기 제한보다 작게 움직였을때 무시함
                if(dist < moveEventDistLimit)
                {
                    moveEventDistLimit = moveEventDistLimit-dist;

                    if(moveEventDistLimit <= 0) moveEventDistLimit = xSize/5;
                    return true;
                }

                moveEventDistLimit = moveEventDistLimit-dist;
                if(moveEventDistLimit <= 0) moveEventDistLimit = xSize/5;

                moveEventLast.setTo(mx,my);
                return false;
            }

            function penToolMouseMoveEvent(e:MouseEvent):void
            {
                var filteredPos:Point = getFilteredPos(canvas2Draw.mouseX,canvas2Draw.mouseY);
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

                    penMove2(ox,oy);
                    smoothPos.setTo(ox,oy);
                    smoothLast.setTo(mx,my);

                    addTimerByName("followCursorSmoothLine",0.03,false,followCursorSmoothLine);
                }
                else
                {
                    penMove2(mx,my);
                    smoothPos.setTo(mx,my);
                }
            }

            function penToolMouseUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, penToolMouseUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, penToolMouseMoveEvent);

                if(penToolFlag && traceMemoryTrainingON && traceAlphaSave > 0.0)
                {
                    canvasTraceLayer.visible = true;
                }

                if(penSmoothSlideValue > 1)
                {
                    removeTimer("followCursorSmoothLine");
                }

                if(xShape === true)
                {
                    penSizeCursor.rotation = 0;

                    if(mouseMovedFlag === true)
                    {
                        const pointLen:uint = penPoints.length;
                        if(pointLen >= 4)
                        {
                            updateExtendEndPoint(penPoints[pointLen-4],penPoints[pointLen-3],penPoints[pointLen-2],penPoints[pointLen-1],xSize/8);
                            rDataBuffer.push(["lineTo",extendedPos.x,extendedPos.y]);
                            canvas2Draw.graphics.lineTo(extendedPos.x,extendedPos.y);
                        }
                    }
                }

                if(mouseMovedFlag === false || (penToolFlag && mouseMovedFlag === true && dotflag))
                {
                    rDataBuffer = [];
                    rDataBuffer.push(["dot4",xShape,xSize,xColor,xAlpha,clickPos.x,clickPos.y,xBlendMode,subLayerON,airBrushSizeDrawMode,regPoint.rotation]);
                    dotTool(xShape,xSize,xColor,clickPos.x,clickPos.y,regPoint.rotation);
                    resetCanvas2DrawCliprect();
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
                    xShape = penShape;
                    xAirBrushON = airBrushON;
                    dotflag = true;

                    if(penColorTransparentFlag)
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
                            updatePickerCurrentColor(pickerBox.getRGBInfoBGColor());
                            addColorMyPaletteHistory(pickerBox.getRGBInfoBGColor());
                        }
                    }
                }
                else
                {
                    xSize = eraseSize;
                    xColor = CANVAS_BG_COLOR;
                    xAlpha = eraseAlpha;
                    xShape = eraseShape;
                    xBlendMode = "erase";
                    xAirBrushON = eraseAirBrushON;
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

                if(penFlag && traceMemoryTrainingON)
                {
                    canvasTraceLayer.visible = false;
                }

                pos05Offset = getSharpLineOffset(xSize);
                mouseMoveCount = 0; //마우스 이벤트에서 움직일때 올려주는 카운터 한번에 너무 많이 움직여주면 cpu부하 먹어서 100카운트 마다 bmp에 그려줌
                mouseMovedFlag = false;
                canvasSizeRect.width = CANVAS_WIDTH;
                canvasSizeRect.height = CANVAS_HEIGHT;
                resetCanvas2DrawCliprect();
                const filteredPos:Point = getFilteredPos(canvas2Draw.mouseX,canvas2Draw.mouseY);

                clickPos.copyFrom(filteredPos); //점찍어 줄 때 판단하는 클릭한 자리 저장
                smoothPos.copyFrom(filteredPos);
                smoothLast.copyFrom(filteredPos); //penmove할때 마지막x y저장
                moveEventLast.copyFrom(filteredPos);

                if(xShape === true)
                {
                    sqPenCursorLast.copyFrom(smoothPos);
                    sqLinePosLast.copyFrom(smoothPos);
                }

                moveEventDistLimit = xSize/5;//penmove에서 distlimit이하이면 jump해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌

                if(readyAddUndoFlag === false)
                {
                    checkPenToolUndoReady();
                }
                canvas2Draw.filters = [];

                stage.addEventListener(MouseEvent.MOUSE_MOVE,penToolMouseMoveEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,penToolMouseUpEvent);
            };
        }

        private function stageMouseLeaveEvent(e:Event):void
        {
            mouseClickON = false;
            rightMouseClickON = false;
            mouseDragON = false;

            mouseLeaveSideBarON();
            penSizeCursor.visible = false;
        }

        private function updatePenCursorPositionEvent(e:MouseEvent):void
        {
            if(replayModeON || captureModeON) return;

            penCursorPosition.check();
        }

        private function cUpdatePenCursorPosition():Object
        {
            var cursorSize:Number = 3.0;
            var mouseDownEventON:Boolean;
            var sidebarTempOFF:Boolean;
            var visibleMouseUpEventON:Boolean;

            function updateCursorSize(size:Number):void
            {
                cursorSize = size*zoomed;
            }

            function updateZoom(z:Number):void
            {
                if(isNowToolPenOrLine()) cursorSize = penSize*zoomed;
                else if(isNowTool(TOOL_ERASE)) cursorSize = eraseSize*zoomed;
                else cursorSize = 0;
            }

            function setSideBarOFF():void
            {
                removeSideBarClickEvents();

                if(isSidebarVisible === false)
                {
                    setSidebarVisible(false,true);
                }
            }

            function isSidebarTempOFF():Boolean
            {
                return visibleMouseUpEventON;
            }

            function setSideBarONWaitEvents():void
            {
                visibleMouseUpEventON = true;
                stage.addEventListener(MouseEvent.MOUSE_DOWN,sidebarONMouseDownEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,sidebarONMouseUpEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,sidebarONMouseUpEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,sidebarONMouseDownEvent);
            }

            function setSideBarClickEvents():void
            {
                mouseDownEventON = true;
                stage.addEventListener(MouseEvent.MOUSE_DOWN,sidebarOFFMouseDownEvent,false,-1);
            }

            function removeSideBarClickEvents():void
            {
                removeTimer("sidebarONTimer");
                sidebarTempOFF = false;
                mouseDownEventON = false;
                visibleMouseUpEventON = false;
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,sidebarOFFMouseDownEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,sidebarONMouseUpEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,sidebarONMouseUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,sidebarONMouseDownEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,sidebarONMouseDownEvent);
            }

            function sidebarONMouseDownEvent(e:MouseEvent):void
            {
                if(sideBar.hitTestPoint(mouseX,mouseY) === false)
                {
                    removeSideBarClickEvents();
                }
            }

            //1초정도 켜지지 않게함
            function setSidebarONDelay():void
            {
                sidebarTempOFF = true;
                addTimerByName("sidebarONTimer",1.0,false,function():void
                {
                    visibleMouseUpEventON = false;
                    sidebarTempOFF = false;

                    removeSideBarClickEvents();
                });
            }

            function sidebarONMouseUpEvent(e:MouseEvent):void
            {
                if(!(rightMouseClickON && mouseClickON))
                {
                    setSidebarONDelay();
                }
            }

            function sidebarOFFRightMouseDownEvent(e:MouseEvent):void
            {
                clickBlockOnWindowActiveFlag = true;
                setClickBlockFlagOFFDelay();

                setSideBarOFF();
            }

            function sidebarOFFMouseDownEvent(e:MouseEvent):void
            {
                if(e.target && (e.target.name === "sideBarONButton" || e.target.name === "sideBarONButton2"
                || e.target.name === "fofo"))
                {

                }
                else if(sideBar.hitTestPoint(mouseX,mouseY) === false)
                {
                    setSideBarOFF();
                }
            }

            function checkSideBarON():void
            {
                if(resizeButtonR.visible)
                {
                    return;
                }

                if(!(mouseClickON || rightMouseClickON || mouseDragON))
                {
                    if(!sidebarTempOFF)
                    {
                        if(mouseDownEventON === false) setSideBarClickEvents();
                        if(sideBar.visible === false) setSidebarVisible(true,true);
                    }
                }
                else if(visibleMouseUpEventON === false && sideBar.visible === false) //클릭한 상태에서 들어올경우
                {
                    setSideBarONWaitEvents();
                }
            }

            function check():void
            {
                const mx:Number = mouseX;
                const my:Number = mouseY;

                //아마 이거 preview커서 박스 커서가 커져서 sidebar 바운더리가 커졌을때
                //제대로 확인못해서 썼던걸거임
                // || (!quickSidebarON && !isCursorInDrawArea())
                //(sideBar.visible && (sideBarScrollBar.hitTestPoint(mouseX,mouseY) || sideBar.hitTestPoint(mouseX,mouseY)))
                
                if(penCursorOFFFlag
                || (nowTool > TOOL_LINE && nowTool !== TOOL_FILL_PEN) //1 2 3 4 펜 지우개 라인툴 라인-지우개툴
                || !isCursorInDrawArea()
                || resizeCanvas.isCanvasResizing()
                || (traceMenu.visible && traceMenu.hitTestPoint(mouseX,mouseY))
                || loadMenuBox.visible)
                {
                    penSizeCursor.visible = false;
                }
                else
                {
                    //addundo플래그가 커서가 캔버스 안에 들어올때 해주기 때문에 위치를 계속 갱신해줘야함
                    penSizeCursor.x = mx;
                    penSizeCursor.y = my;

                    if(cursorSize <= 4 || isNowTool(TOOL_FILL_PEN))
                    {
                        penSizeCursor.visible = false;
                    }
                    else
                    {
                        penSizeCursor.visible = true;
                    }
                }

                if(isSidebarVisible === false && clickBlockOnWindowActiveFlag === false)
                {
                    if(sideBar.visible === false && toolBox2.visible === false)
                    {
                        if((!isRightSidebar && mx <= 15
                        || isRightSidebar && mx >= stage.stageWidth-15)
                        && my > STAGE_TOP_OFFSET)
                        {
                            checkSideBarON();
                        }
                    }
                }
            }

            return {
                check:check,
                setSideBarONWaitEvents:setSideBarONWaitEvents,
                checkSideBarON:checkSideBarON,
                setSideBarOFF:setSideBarOFF,
                isSidebarTempOFF:isSidebarTempOFF,
                setSidebarONDelay:setSidebarONDelay,
                updateZoom:updateZoom,
                updateCursorSize:updateCursorSize,
                removeSideBarClickEvents:removeSideBarClickEvents
            };
        }

        private function cRealWorkingTimer():Object
        {
            var appRunningTime:int = 0;
            var afkCount:int = 0; //마우스 멈춰있으면 올라가는 시간
            var lastTime:int = 0; //마지막 시간 저장해줌
            //시간 표시 관련 변수
            var tt:int;
            var hh:int;
            var mm:int;
            var ss:int;

            function resetAFKCount():void
            {
                afkCount = 0;
            }

            function reset():void
            {
                lastTime = getTimer();
                appRunningTime = 0;
                topBar.timer.text = "00:00:00";
                topBar.updateTimerPos(stage.stageWidth);
            }

            function setRunningTime(newTime:int):void
            {
                appRunningTime = newTime;
            }

            function getRunningTime():int
            {
                return appRunningTime;
            }

            function update():void
            {
                if(appRunningTime < 0)
                {
                    appRunningTime = 0;
                }

                tt = appRunningTime/1000;
                hh = Math.floor(tt/3600);
                mm = Math.floor((tt-hh*3600)/60);
                ss = Math.floor(tt%60);

                topBar.timer.text =      ((hh < 10) ? "0"+hh:""+hh)
                                    +":"+((mm < 10) ? "0"+mm:""+mm)
                                    +":"+((ss < 10) ? "0"+ss:""+ss);

                topBar.timerAFkDot.visible = false;
                topBar.updateTimerPos(stage.stageWidth);
            }

            function check():Boolean
            {
                const nowTime:int = getTimer();
                const subTime:int = nowTime-lastTime;

                if(subTime >= 1000)
                {
                    if(afkCount > 1000)
                    {
                        afkCount = 1001;

                        topBar.timerAFkDot.visible = !topBar.timerAFkDot.visible;
                        topBar.updateTimerPos(stage.stageWidth);
                    }
                    else
                    {
                        appRunningTime += subTime;
                        update();
                    }

                    afkCount += subTime;
                    lastTime = nowTime;
                }

                return true;
            }

            function setAFKMode():void
            {
                afkCount = 1001;
            }

            function resume():void
            {
                lastTime = getTimer();
            }

            function start():void
            {
                resume();
                addTimerByName("workingTimer",1.0,true,check);
            }

            return {
                start:start,
                resume:resume,
                setAFKMode:setAFKMode,
                reset:reset,
                update:update,
                resetAFKCount:resetAFKCount,
                getRunningTime:getRunningTime,
                setRunningTime:setRunningTime
            }
        }

		private function updateCaptureTransParentBG():void
        {
            const halfSize:Number = Math.floor(capTransparentBGBMPDSize/2);
            capTransparentBGBMPD = new BitmapData(capTransparentBGBMPDSize,capTransparentBGBMPDSize,false,0xFFFFFF);
            capTransparentBGBMPD.fillRect(new Rectangle(0,0,halfSize,halfSize),0xC8C8C8);
            capTransparentBGBMPD.fillRect(new Rectangle(halfSize,halfSize,halfSize,halfSize),0xCCCCCC);
        }

        //리턴값
		// <= 1.0	인간의 눈으로 인식 할 수 없음
		// 1 ~ 2	면밀한 관찰을 통해 인식 가능
		// 2 ~ 10	한눈에 알아볼 수 있음
		// 11-49	색상이 반대보다 비슷
		// 100	    색상이 정반대
		private function getColorDifferenceForHuman(rgbA:uint, rgbB:uint):Number
		{
			function rgb2lab(rgb:uint):Vector.<Number>
			{
				var _r:Number = ((rgb & 0xFF0000) >>> 16) / 255;
				var _g:Number = ((rgb & 0x00FF00) >>> 8) / 255;
				var _b:Number = ((rgb & 0x0000FF)) / 255;
				var _x:Number;
                var _y:Number;
                var _z:Number;

				_r = (_r > 0.04045) ? Math.pow((_r + 0.055) / 1.055, 2.4) : _r / 12.92;
				_g = (_g > 0.04045) ? Math.pow((_g + 0.055) / 1.055, 2.4) : _g / 12.92;
				_b = (_b > 0.04045) ? Math.pow((_b + 0.055) / 1.055, 2.4) : _b / 12.92;
				_x = (_r * 0.4124 + _g * 0.3576 + _b * 0.1805) / 0.95047;
				_y = (_r * 0.2126 + _g * 0.7152 + _b * 0.0722) / 1.00000;
				_z = (_r * 0.0193 + _g * 0.1192 + _b * 0.9505) / 1.08883;
				_x = (_x > 0.008856) ? Math.pow(_x, 1/3) : (7.787 * _x) + 16/116;
				_y = (_y > 0.008856) ? Math.pow(_y, 1/3) : (7.787 * _y) + 16/116;
				_z = (_z > 0.008856) ? Math.pow(_z, 1/3) : (7.787 * _z) + 16/116;

                const result:Vector.<Number> = new <Number> [(116 * _y) - 16, 500 * (_x - _y), 200 * (_y - _z)];

				return result;
			}

			const labA:Vector.<Number> = rgb2lab(rgbA);
			const labB:Vector.<Number> = rgb2lab(rgbB);
			const deltaL:Number = labA[0] - labB[0];
			const deltaA:Number = labA[1] - labB[1];
			const deltaB:Number = labA[2] - labB[2];
			const c1:Number = Math.sqrt(labA[1] * labA[1] + labA[2] * labA[2]);
			const c2:Number = Math.sqrt(labB[1] * labB[1] + labB[2] * labB[2]);
			const deltaC:Number = c1 - c2;
			var deltaH:Number = deltaA * deltaA + deltaB * deltaB - deltaC * deltaC;
			deltaH = deltaH < 0 ? 0 : Math.sqrt(deltaH);
			const sc:Number= 1.0 + 0.045 * c1;
			const sh:Number= 1.0 + 0.015 * c1;
			const deltaLKlsl:Number = deltaL / (1.0);
			const deltaCkcsc:Number = deltaC / (sc);
			const deltaHkhsh:Number = deltaH / (sh);
			const i:Number = deltaLKlsl * deltaLKlsl + deltaCkcsc * deltaCkcsc + deltaHkhsh * deltaHkhsh;

			return i < 0 ? 0 : Math.sqrt(i);
		}

        private function restoreZoomReplayMode():void
        {
            rzoomedIndex = getNearZoomIndex(rzoomedSave);
            setZoomCanvas(zoomList[rzoomedIndex],true);
            autoScroll.updateRCanvasBounds();
        }

        private function resetZoomReplayMode():void
        {
            const center:Point = getStageCenterPos(1);

            rzoomedSave = 1.0;
            rzoomedIndex = zoomList.indexOf(1.0);
            setRegPoint(center.x,center.y,true);
            setZoomCanvas(1.0,true);
            setFitZoomedOFF();
            autoScroll.updateRCanvasBounds();
        }

        private function resetZoomDrawMode():void
        {
            if(zoomed !== 1.0)
            {
                const center:Point = getStageCenterPos(0);
                const gcenter:Point = canvasPanel.globalToLocal(new Point(center.x,center.y));
                const gp:Point = canvasPanel.localToGlobal(ZERO_POINT);
                const panelLimitedPos:Point = getCanvasBoundLimitPoint(canvasPanel,gcenter.x,gcenter.y,CANVAS_WIDTH,CANVAS_HEIGHT,regPoint.scaleY,-regPoint.rotation);
                setRegPoint(panelLimitedPos.x+gp.x,panelLimitedPos.y+gp.y,false);

                zoomedIndex = zoomList.indexOf(1.0);
                setZoomCanvas(1.0,false);
                updatePenSizeCursor();
                updatePreviewBoxRectPos();
                drawGrid();
            }
        }

        private function setZoomInButton(zoomInFlag:Boolean,replayMode:Boolean):void
        {
            const xReg:Sprite = (replayMode) ? rregPoint : regPoint;
            const zoomMax:int = zoomList.length-1;
            var center:Point;
            var newZoomIndex:int = (replayMode) ? rzoomedIndex : zoomedIndex;

            if(zoomInFlag)
            {
                newZoomIndex++;
                if(newZoomIndex > zoomMax) newZoomIndex = zoomMax;
            }
            else
            {
                newZoomIndex--;
                if(newZoomIndex < 0) newZoomIndex = 0;
            }

            const newZoom:Number = zoomList[newZoomIndex];

            if(replayMode)
            {
                center = getStageCenterPos(1);
                rzoomedSave = newZoom;
                setFitZoomedOFF();
                rzoomedIndex = newZoomIndex;
                setRegPoint(center.x,center.y,true);
                setZoomCanvas(newZoom,replayMode);
                autoScroll.updateRCanvasBounds();
            }
            else
            {
                center = getStageCenterPos(0);
                const gcenter:Point = canvasPanel.globalToLocal(new Point(center.x,center.y));
                const gp:Point = canvasPanel.localToGlobal(ZERO_POINT);
                const panelLimitedPos:Point = getCanvasBoundLimitPoint(canvasPanel,gcenter.x,gcenter.y,CANVAS_WIDTH,CANVAS_HEIGHT,xReg.scaleY,-xReg.rotation);

                zoomedIndex = newZoomIndex;
                setRegPoint(panelLimitedPos.x+gp.x,panelLimitedPos.y+gp.y,false);
                setZoomCanvas(newZoom,replayMode);
                updatePenSizeCursor();
                updatePreviewBoxRectPos();

                if(gridValue > 0)
                {
                    drawGrid();
                }
            }
        }

        private function checkKeyUp(keyCode:uint):void
        {
            if(KEY_BUFFER.length === 0) resetNowKey();
            else if(!captureModeON && !replayModeON && isNowKey(keyCode)) keyDownLassoTool(null);
        }

        private function keyUpLassoTool(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;
            if(lassoMenuTempOFF && !mouseClickON)
            {
                lassoMenuTempOFF = false;
            }

            checkKeyUp(keyCode);
        }

        private function keyDownLassoTool(e:KeyboardEvent):void
        {
            if(mouseClickON || rightMouseClickON || mouseDragON)
            {
                return;
            }

            const keyCode:uint = KEY_BUFFER[0];
            var keyUsed:Boolean;

            if(keyCode === KEY.space)
            {
                keyUsed = checkCommandSubKey(2,true,function(input:int):void
                {
                    switch(input)
                    {
                        case KEY.w:
                        case KEY.i: setLasso1PxMoveButton(LASSO_1PX_MOVE_UP); break;

                        case KEY.a:
                        case KEY.j: setLasso1PxMoveButton(LASSO_1PX_MOVE_LEFT); break;

                        case KEY.s:
                        case KEY.k: setLasso1PxMoveButton(LASSO_1PX_MOVE_DOWN); break;

                        case KEY.d:
                        case KEY.l: setLasso1PxMoveButton(LASSO_1PX_MOVE_RIGHT); break;
                    }
                });

                if(keyUsed || isNowKey(keyCode)) return;

                lassoMenuTempOFF = true;
                setNowKey(keyCode);
                setNowTool(TOOL_HAND);
            }
            else if(isPressingShift())
            {
                keyUsed = checkCommandSubKey(2,true,function(input:int):void
                {
                    switch(input)
                    {
                        case KEY.s:
                        case KEY.k:
                            if(regPoint.rotation !== 0.0) resetRotationDrawMode();
                        return;

                        case KEY.w:
                        case KEY.i:
                            if(zoomed !== 1.0) resetZoomDrawMode();
                        return;
                    }
                });
                if(keyUsed) return;
            }
            else if(keyCode === KEY.tab || keyCode === KEY.backslash)
            {
                if(isNowKey(keyCode)) return;
                setNowKey(keyCode);

                setSidebarVisible(!isSidebarVisible,false);
                return;
            }

            if(isNowKey(keyCode)) return;
            setNowKey(keyCode);

            switch(keyCode)
            {
                case KEY.w:
                case KEY.i:
                {
                    lassoMenuTempOFF = true;
                    setNowKey(keyCode);
                    setNowTool(TOOL_ZOOM);
                }
                break;

                case KEY.s:
                case KEY.k:
                {
                    lassoMenuTempOFF = true;
                    setNowKey(keyCode);
                    setNowTool(TOOL_ROTATE);
                }
                break;

                case KEY.enter:
                    setLassoOKButton();
                break;

                case KEY.f3:
                    setSideBarPositionButton();
                break;

                case KEY.esc:
                case KEY.backspace:
                    setLassoCancelButton();
                break;
            }
        }

        private function setSideBarPositionButton():void
        {
            if(isRightSidebar === false)
            {
                isRightSidebar = true;
                setSideBarRightPosition(false);
            }
            else if(isRightSidebar === true)
            {
                isRightSidebar = false;
                setSideBarLeftPosition();
            }
        }

        private function updatePreviewBoxRectPos():void
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

            const gp:Point = canvas1Bitmap.globalToLocal(new Point(newLeftOffset,STAGE_TOP_OFFSET));
            const zoom:Number = zoomed;
            previewBox.updateCursor(gp.x*zoom,gp.y*zoom
                                    ,stage.stageWidth-newRightOffset-newLeftOffset
                                    ,stage.stageHeight-STAGE_TOP_OFFSET-STAGE_BOTTOM_OFFSET
                                    ,CANVAS_WIDTH*zoom,regPoint.rotation);
        }

        private function setHandToolPreviewBox(cursorClicked:Boolean):void
        {
            var sx:Number = previewBox.mouseX;
            var sy:Number = previewBox.mouseY;

            const prevCursorScale:Number = previewBox.prevCursorMultiply;
            const uiScale:Number = getUIScale();

            setOptimizeCanvasMoveON(true);
            hint.off();

            function setCenter(mx:Number,my:Number):void
            {
                const b:Object = getBoundRect(previewBox.prevCursor);
                const scale:Number = getUIScale();
                //prevToCanvasMultiply를 나눠 줘야 커서랑 같은 속도가 나옴
                const rectCenterX:Number = b.left+(b.right-b.left)/2;
                const rectCenterY:Number = b.top+(b.bottom-b.top)/2;
                var moveX:Number = (rectCenterX-mx)/prevCursorScale/uiScale;
                var moveY:Number = (rectCenterY-my)/prevCursorScale/uiScale;
                var p:Point = rotatePoint(moveX,moveY,-regPoint.rotation);

                regPoint.x += Math.round(p.x);
                regPoint.y += Math.round(p.y);

                updatePreviewBoxRectPos();
            }

            function setHandToolMouseUpEvent(e:MouseEvent):void
            {
                setOptimizeCanvasMoveON(false);
                checkCanvasPanelPos();
                updatePreviewBoxRectPos();
                mouseDragON = false;

                if(lassoToolON)
                {
                    if(lassoMenuTempOFF === true)
                    {
                        setlassoMenuTempOFF();
                    }
                }

                stage.removeEventListener(MouseEvent.MOUSE_MOVE,setHandToolMouseMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,setHandToolMouseUpEvent);
            }

            function setHandToolMouseMoveEvent(e:MouseEvent):void
            {
                const scale:Number = getUIScale();
                var mx:Number = previewBox.mouseX;
                var my:Number = previewBox.mouseY;
                //previewBox.prevCursorMultiply를 곱해줘야 커서랑 같은 속도가 나옴
                var moveX:Number = (sx-mx)/prevCursorScale;
                var moveY:Number = (sy-my)/prevCursorScale;
                var p:Point = rotatePoint(moveX,moveY,-regPoint.rotation);

                regPoint.x += Math.round(p.x);
                regPoint.y += Math.round(p.y);

                sx = mx;
                sy = my;

                updatePreviewBoxRectPos();
            }
            setRegPoint(0,0);

            if(lassoToolON)
            {
                lassoMenu.visible = false;
                lassoMenuTempOFF = true;
            }

            //클릭한 지점이 커서 바깥부분일때 강제로 캔버스 중심으로 옮겨줌
            if(!cursorClicked)
            {
                setCenter(mouseX,mouseY);
            }

            stage.addEventListener(MouseEvent.MOUSE_UP,setHandToolMouseUpEvent)
            stage.addEventListener(MouseEvent.MOUSE_MOVE,setHandToolMouseMoveEvent)
        }
        //원점 penSmoothX oy로부터 dx쪽으로 dist 만큼 떨어진 거리 점을 리턴함
        private function movePointAngleDist(ox:Number,oy:Number,dx:Number,dy:Number,dist:Number):Point
        {
            const rad:Number = Math.atan2(dx-ox,dy-oy);

            return new Point(ox+dist*Math.sin(rad)
                            ,oy+dist*Math.cos(rad));
        }

        private function setNowToolForDrawing(checkErase:Boolean):void
        {
            if(!(isNowToolPenOrLine() || isNowTool(TOOL_FILL_PEN)
            || (checkErase && isNowTool(TOOL_ERASE))))
            {
                resetOldTool();
                selectPenTool();
                updatePenSizeCursor();
            }
        }

        private function updateRGBInfoTextByColor(color:*):void
        {
            if(color is uint)
            {
                pickerBox.setRGBInfo(getRGBInfoString(color));
            }
            else if(color is Vector.<Number>)
            {
                pickerBox.setRGBInfo(getHSVInfoString(color));
            }
            else
            {
                return;
            }

            const textColor:uint = (color is Vector.<Number>) ? HSVtoHEX(color[0],color[1],color[2]) : color;
            setRGBInfoTextColorByColor(textColor);
        }

        private function setRGBInfoTextColorByColor(color:uint):void
        {
            pickerBox.setRGBInfoColor(getInvertColor(color,1.0
            ,(uiColorIndex >= 2) ? uiColorSet[uiColorIndex][0]:uiColorSet[uiColorIndex][1]
            ,(uiColorIndex >= 2) ? uiColorSet[uiColorIndex][1]:uiColorSet[uiColorIndex][0]));
        }

        private function initPickerBoxInfo(color:uint):void
        {
            return;
            updateRGBInfoTextByColor(color);
            pickerBox.updateRGBInfoBG(color,setRGBInfoBorderColor(color),myPalettePresetType);
            updatePickerCurrentColor(color);
        }

        private function setLassoTraceImageButton():void
        {
            setTopChildIndex(lassoMenu);
            traceImageCount++;

            function setLassoTraceImageButtonCountResetEvent(e:MouseEvent):void
            {
                traceImageCount = 0;
                lassoMenu.lassoTrace.removeEventListener(MouseEvent.MOUSE_OUT,setLassoTraceImageButtonCountResetEvent);
            }

            if(traceImageCount === 1)
            {
                lassoMenu.hint(STRING_ONEMORE_CLICK_TO_OK);
                lassoMenu.lassoTrace.addEventListener(MouseEvent.MOUSE_OUT,setLassoTraceImageButtonCountResetEvent);
            }
            else if(traceImageCount === 2)
            {
                traceImageCount = 0;
                lassoMenu.lassoTrace.removeEventListener(MouseEvent.MOUSE_OUT,setLassoTraceImageButtonCountResetEvent);
                traceMenu.hint(STRING_MERGE_LASSO_IMAGE_TO_TRACE);
                mergeLassoImageToTraceLayer();
                openTraceWindow();
            }
        }

        private function setTraceImageButton():void
        {
            if(traceMenu.traceImageButton.alpha !== 1.0) return;

            setTopChildIndex(traceMenu);
            traceImageCount++;

            function setTraceImageButtonCountResetEvent(e:MouseEvent):void
            {
                traceImageCount = 0;
                traceMenu.traceImageButton.removeEventListener(MouseEvent.MOUSE_OUT,setTraceImageButtonCountResetEvent);
            }

            if(traceImageCount === 1)
            {
                traceMenu.hint(STRING_ONEMORE_CLICK_TO_OK);
                traceMenu.traceImageButton.addEventListener(MouseEvent.MOUSE_OUT,setTraceImageButtonCountResetEvent);
            }
            else if(traceImageCount === 2)
            {
                traceImageCount = 0;
                traceMenu.traceImageButton.removeEventListener(MouseEvent.MOUSE_OUT,setTraceImageButtonCountResetEvent);
                traceMenu.hint(STRING_MERGE_CANVAS_IMAGE_TO_TRACE);
                pasteCanvasImageToTraceLayer();
            }
        }

        private function checkLassoMenuPos():void
        {
            checkBoxPosition(lassoMenu);
        }

        private function traceMenuHintONEvent(e:MouseEvent):void
        {
            if(!traceMenuON)
            {
                stage.removeEventListener(MouseEvent.MOUSE_OVER,traceMenuHintONEvent);
                return;
            }

            if(traceMenu.hitTestPoint(mouseX,mouseY) === false)
            {
                if(traceMenu.getHintStr() !== "Reference layer")
                {
                    traceMenu.hint("Reference layer");
                }

                return;
            }

            if(mouseDragON === true)
            {
                return;
            }

            const targetName:String = e.target.name;
            var str:String = "";

            switch(targetName)
            {
                case "traceCancelButton":str = "Close [esc, backspace, t]"; break;
                case "traceImageButton":str = STRING_MERGE_CANVAS_IMAGE_TO_TRACE; break;
                case "traceLoadButton":str = "Load image"; break;
                case "traceClipButton":str = "Load clipboard image"; break;
                case "traceButtonWrapper":str = "Adjust image opacity"; break;
                case "traceRotateButton":str = "Rotate image\n"+STRING_RIGHT_CLICK_TO_RESET; break;
                case "traceMoveButton":str = "Move image\n"+STRING_RIGHT_CLICK_TO_RESET; break;
                case "traceResizeButton":str = "Resize image\n"+STRING_RIGHT_CLICK_TO_RESET; break;
                case "traceMirrorButton":str = "Flip image"; break;
                case "traceVisibleONButton":
                case "traceVisibleOFFButton":str = "Memory training ON/OFF"; break;
                case "traceDeleteButton":str = "Erase reference image\n[click]"+STRING_HOLD_NSEC; break;
                default:
                    traceMenu.hint("Reference layer");
                return;
            }

            traceMenu.hint(str);
        }

        private function getLassoMenuHintSwapLayer():String
        {
            if(lassoSwapButtonClicked) return "Swap layers 2 <-> 1";

            return "Swap layers 1 <-> 2";
        }

        private function lassoMenuHintONEvent(e:MouseEvent):void
        {
            if(!lassoToolON)
            {
                stage.removeEventListener(MouseEvent.MOUSE_OVER,lassoMenuHintONEvent);
                return;
            }

            if(lassoMenu.hitTestPoint(mouseX,mouseY) === false)
            {
                if(lassoMenu.getHintStr() !== "Lasso tool")
                {
                    lassoMenu.hint("Lasso tool");
                }
                return;
            }

            if(mouseDragON === true)
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
                case "lassoTrace":str = STRING_MERGE_LASSO_IMAGE_TO_TRACE; break;
                case "lasso1pxLeft":
                case "lasso1pxRight":
                case "lasso1pxUp":
                case "lasso1pxDown": str = "Move image 1px\n[space+wasd / ijkl]"; break;
                case "lassoLayerMerge": str = "Merge image to layer 2"; break;
                case "lassoLayerSwap": str = getLassoMenuHintSwapLayer(); break;
                default: break;
            }

            lassoMenu.hint(str);
        }

        private function toolBoxHintOFFEvent(e:MouseEvent):void
        {
            if(rgbInfoFocusedON) return;
            if(zoomToolHintON) zoomToolHintON = false;
        }

        private function getToolBox2Hint(targetName:String):String
        {
            var str:String = "";

            switch(targetName)
            {
                case "toolSidebar": str = "[6, s+d, j+k]"; break;
                case "toolPen": str = "Pen [q, o key up] "; break;
                case "toolFillPen": str = "Fill pen [q, o]"; break;
                // case "toolScanFill": str = "Scan fill [q+w, o+i]"; break;
                case "toolErase": str = "Eraser [d, j]"; break;
                case "toolLasso": str = "Lasso [r, y]"; break;
                case "toolSpuit": str = "Eye dropper [c, m]"; break;
                case "toolUndo": str = "Undo [z, .]"; break;
                case "toolRedo": str = "Redo [x, ,]"; break;
                case "toolMirror": str = "Flip canvas [a, l]"; break;
                case "toolLine": str = "Line [shift]"; break;
                case "toolMove": str = "Move image [e, u]"; break;
                case "toolZoom": str = "Zoom [w, i]"; break;
                case "toolRotate": str = "Rotate [s, k]"; break;
                case "toolTrace": str = "Reference layer [t]"; break;
            }

            return str;
        }

        private function getToolBoxHint(targetName:String):String
        {
            var str:String = "";

            switch(targetName)
            {
                case "toolPen": str = "Pen [q, o key up]"; break;
                case "toolFillPen": str = "Fill pen [q, o]\nMenu [right-click after using the tool]"; break;
                case "toolFillPenOK": str = "OK"; break;
                case "toolFillPenCancel": str = "Cancel"; break;
                // case "toolScanFill": str = "Scan fill [q+w, o+i]\n Draw [Drag on canvas]"; break;
                case "toolErase": str = "Eraser [d, j]"; break;
                case "toolLasso": str = "Lasso [r, y]"; break;
                case "toolSpuit": str = "Eye dropper [c, m]\nPick transparent color ON/OFF [c+space, m+space]"; break;
                case "toolUndo":
                {
                    str = (fillPenStarted) ? "Undo":"Undo [z, .]\nRepeat [hold-click]"; break;
                }
                case "toolRedo": str = "Redo [x, ,]\nRepeat [hold-click]"; break;
                case "toolMirror": str = "Flip canvas [a, l]"; break;
                case "toolLine": str = "Line [shift]"; break;
                case "toolMove": str = "Move image [e, u]"; break;
                case "zoomInButton": str ="Zoom in canvas [w, i + drag canvas, mouse wheel on canvas]\nReset [right-click ,shift+w, shift+i]"; break;
                case "zoomOutButton": str ="Zoom out canvas [w, i + drag canvas, mouse wheel on canvas]\nReset [right-click ,shift+w, shift+i]"; break;
                case "toolRotate": str = "Rotate canvas [s, k]\nReset [right-click, shift+s , shift+k]"; break;
                case "toolTrace": str = "Reference layer [t]"; break;
            }

            return str;
        }

        private function toolBoxHint2ONEvent(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target || target.alpha < 1.0) return;

            const hintStr:String = getToolBox2Hint(target.name);
            toolBox2.hint((hintStr === "") ? "Tools" : hintStr);
        }

        private function toolBoxHintONEvent(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target) return;

            const targetName:String = target.name;

            if(lassoToolON)
            {
                if(targetName === "zoomInButton"
                || targetName === "zoomOutButton"
                || targetName === "toolRotate")
                {
                    if(mouseDragON)
                    {
                        return;
                    }
                }
                else
                {
                    return;
                }
            }
            else if(fillPenStarted &&
            (targetName === "toolFillPenOK"
            || targetName === "toolFillPenCancel" 
            || targetName === "toolUndo"
            || targetName === "zoomInButton"
            || targetName === "zoomOutButton"
            || targetName === "toolRotate"
            || targetName === "toolMirror"))
            {
                
            }
            else if(isHintCantUse())
            {
                return;
            }

            const hintStr:String = getToolBoxHint(targetName);

            if(hintStr === "")
            {
                // setToolTipOFF();
            }
            else
            {
                hint.on(hintStr,target);
            }
        }

        private function changeTopBarIcons(mode:String="draw"):void
        {
            if(lassoToolON === true || aboutPanelON === true)
            {
                return;
            }

            setTopBarHintOFF();
            setTopChildIndex(topBar);

            topBar.buttonSetVisible(mode,true,isRightSidebar,isSidebarVisible);
            topBar.updateButtonVisible(false);

            if(mode === "draw")
            {
                topBar.buttonSetVisible("replay",false);
                topBar.buttonSetVisible("capture",false);
                updatePenSizeCursor();
                if(needUpdate) topBar.updateButtonVisible(true);

                if(canvasWindowON) topBar.newWindowButton.visible = false;
                else topBar.newWindowCloseButton.visible = false;
            }
            else if(mode === "replay")
            {
                topBar.buttonSetVisible("draw",false,isRightSidebar);
                topBar.buttonSetVisible("capture",false);

                if(replayStartON)
                {
                    replayTimeBox["playButton"].visible = false;
                    replayTimeBox["pauseButton"].visible = true;
                }
                else
                {
                    replayTimeBox["playButton"].visible = true;
                    replayTimeBox["pauseButton"].visible = false;
                }
            }
            else if(mode === "capture")
            {
                topBar.buttonSetVisible("replay",false);
                topBar.buttonSetVisible("draw",false,isRightSidebar);

                if(canvas1Bitmap.visible)
                {
                    topBar.capLayer1VisibleButton.alpha = 1.0;
                }
                else
                {
                    topBar.capLayer1VisibleButton.alpha = BUTTON_OFF_ALPHA;
                }

                if(canvas11Bitmap.visible)
                {
                    topBar.capLayer2VisibleButton.alpha = 1.0;
                }
                else
                {
                    topBar.capLayer2VisibleButton.alpha = BUTTON_OFF_ALPHA;
                }

                checkCaptureStampButtonAlpha();
            }
        }

        private function getPenSizeFromTargetName(targetName:String):Number
        {
            const str:String = targetName.substr(11);
            const index:int = parseInt(str);
            return penSizeList[index];
        }

        private function getPenSizeHint(targetName:String):String
        {
            const hint:String = getPenSizeFromTargetName(targetName) + "px";

            return hint;
        }

        private function resetGrid():void
        {
            gridGapSave = 0;
            gridValue = 0;
            gridButton.setCursorPosByValue(0);
            clearGrid();
        }

        private function clearGrid():void
        {
            gridGapSave = 0;
            topBar.setGridMoveButtonAlpha(BUTTON_OFF_ALPHA);
            canvasGrid.visible = false;
            canvasGrid.graphics.clear();
        }

        private function drawGrid():void
        {
            if(gridValue === 0)
            {
                clearGrid();
                return;
            }

            var gridgap:Number = gridValue*GRID_GAP;
            if(gridgap*zoomed < gridgap)
            {
                gridgap = gridgap/zoomed;
            }

            if(gridgap !== gridGapSave)
            {
                gridGapSave = gridgap;

                const gridWidth:Number = CANVAS_WIDTH;
                const gridHeight:Number = CANVAS_HEIGHT;
                const offsetX:Number = gridDrawOffsetX;
                const offsetY:Number = gridDrawOffsetY;

                var i:uint = 1;
                var len:Number = Math.floor(gridHeight/gridgap+0.5);//가로선 횟수 w, h반대되는거 맞음

                if(offsetY < 0) len += 1;
                else if(offsetY > 0) i = 0;

                gridGraphicsCommand.length = 0;
                gridGraphicsData.length = 0;

                //가로선
                for(;i<=len;i++)
                {
                    gridGraphicsCommand.push(1);
                    gridGraphicsCommand.push(2);
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
                    gridGraphicsCommand.push(1);
                    gridGraphicsCommand.push(2);
                    gridGraphicsData.push(gridgap*i+offsetX)
                    gridGraphicsData.push(0);
                    gridGraphicsData.push(gridgap*i+offsetX);
                    gridGraphicsData.push(gridHeight);
                }
            }

            canvasGrid.graphics.clear();
            canvasGrid.graphics.lineStyle(1/zoomed,GRID_NORMAL_COLOR,0.5,false);
            canvasGrid.graphics.drawPath(gridGraphicsCommand,gridGraphicsData);

            checkGridMirror(mirrorON);
            canvasGrid.cacheAsBitmap = true;
            canvasGrid.visible = true;
        }

        private function cGridFunc():Object
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

            function drawDridByValue(mx:Number,initFlag:Boolean):void
            {
                if(mx < minDist) mx = minDist;
                else if(mx > maxDist) mx = maxDist;

                const value:Number = Math.floor((mx-minDist)/div);

                if(oldValue !== value || initFlag)
                {
                    setCursorPosByValue(value);

                    if(value === 0)
                    {
                        gridValue = 0;
                        oldValue = 0;
                        hint.off();
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

                        gridValue = value;
                        oldValue = value;
                        setHintONTemp("Grid " + (gridValue*GRID_GAP)+"px ("+gridValue+"/20)");

                        drawGrid();
                    }
                }

                setTopChildIndex(canvasGrid);
            }

            function mouseUpGridButton(e:MouseEvent):void
            {
                mouseDragON = false;
                stage.removeEventListener(MouseEvent.MOUSE_UP,mouseUpGridButton);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveGridButton);
            }

            function mouseMoveGridButton(e:MouseEvent):void
            {
                var mx:Number = topBar.gridSliderWrapper.mouseX;

                if(mx < minDist) mx = minDist;
                else if(mx > maxDist) mx = maxDist;

                drawDridByValue(mx,false);
            }

            function setGridMoveButton(moveX:Number,moveY:Number):void
            {
                setHoldKeyRepeat(true,function():void
                {
                    gridDrawOffsetX += moveX*(mirrorON ? -1:1);
                    gridDrawOffsetY += moveY;

                    if(Math.abs(gridDrawOffsetX) >= gridValue*GRID_GAP) gridDrawOffsetX = 0.0;
                    if(Math.abs(gridDrawOffsetY) >= gridValue*GRID_GAP) gridDrawOffsetY = 0.0;

                    gridGapSave = 0;
                    if(gridValue > 0) drawGrid();
                });
            }

            function mouseDownGridButton(e:MouseEvent):void
            {
                if(!e.target) return;
                const targetName:String = e.target.name;

                if(targetName === "gridButton" || topBar.gridButtonWrapper.hitTestPoint(mouseX,mouseY) === false)
                {
                    off();
                    return;
                }

                if(topBar.gridMoveButtonWrapper.hitTestPoint(mouseX,mouseY))
                {
                    if(e.target.alpha === 1.0)
                    {
                        var p:Point;

                        if(targetName === "gridMoveLeftButton")
                        {
                            p = rotatePoint(-1,0,regPoint.rotation);
                            setGridMoveButton(p.x,p.y);
                        }
                        else if(targetName === "gridMoveRightButton")
                        {
                            p = rotatePoint(1,0,regPoint.rotation);
                            setGridMoveButton(p.x,p.y);
                        }
                        else if(targetName === "gridMoveUpButton")
                        {
                            p = rotatePoint(0,-1,regPoint.rotation);
                            setGridMoveButton(p.x,p.y);
                        }
                        else if(targetName === "gridMoveDownButton")
                        {
                            p = rotatePoint(0,1,regPoint.rotation);
                            setGridMoveButton(p.x,p.y);
                        }
                    }
                }
                else if(topBar.gridSliderWrapper.hitTestPoint(mouseX,mouseY))
                {
                    mouseDragON = true;
                    oldValue = gridValue;
                    drawDridByValue(topBar.gridSliderWrapper.mouseX,true);
                    stage.addEventListener(MouseEvent.MOUSE_MOVE,mouseMoveGridButton);
                    stage.addEventListener(MouseEvent.MOUSE_UP,mouseUpGridButton);
                }

            }

            function keyUpGridButton(e:KeyboardEvent):void
            {
                if(e.keyCode === KEY.f2 || e.keyCode === KEY.f8)
                {
                    if(!(mouseClickON || mouseDragON))
                    {
                        if(isPressingShift())
                        {
                            if(gridValue !== 0)
                            {
                                hint.off();
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

            function rightMouseDownGridButton(e:MouseEvent):void
            {
                if(!e.target) return;

                const targetName:String = e.target.name;

                if(targetName === "gridMoveLeftButton"
                || targetName === "gridMoveRightButton")
                {
                    if(gridValue > 0)
                    {
                        gridDrawOffsetX = 0.0;
                        gridGapSave = 0.0
                        if(gridValue > 0) drawGrid();
                    }
                }
                else if(targetName === "gridMoveUpButton"
                     || targetName === "gridMoveDownButton")
                {
                    if(gridValue > 0)
                    {
                        gridDrawOffsetY = 0.0;
                        gridGapSave = 0.0;
                        if(gridValue > 0) drawGrid();
                    }
                }
                else if(targetName === "gridSliderWrapper")
                {
                    if(gridValue !== 0)
                    {
                        hint.off();
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
                hint.off();
                mouseDragON = false;
                cancelAutoKeyEvent(null);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownGridButton);
                stage.removeEventListener(MouseEvent.MOUSE_UP,mouseUpGridButton);
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownGridButton);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveGridButton);
                stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpGridButton);
                topBar.setReplaySpeedBarToGridSliderOFF(stage);
                resetKeyBuffer();
                addInputEventDrawMode();
            }

            // 그리그 키관련 수정해야함
            // 그리드 클릭으로 켜주고
            // 단축키로 꺼주면 아무것도 작동안함

            function start(shortcutKey:Boolean):void
            {
                if(topBar.gridButtonWrapper.visible === false)
                {
                    removeInputEventDrawMode();

                    if(gridValue > 0) topBar.setGridMoveButtonAlpha(1.0);
                    else topBar.setGridMoveButtonAlpha(BUTTON_OFF_ALPHA);

                    topBar.setReplaySpeedBarToGridSliderON(uiColorSet[uiColorIndex][0],shortcutKey);
                    setCursorPosByValue(gridValue);

                    if(shortcutKey)
                    {
                        const p:Point = topBar.globalToLocal(new Point(mouseX,mouseY));
                        topBar.gridButtonWrapper.x = p.x-topBar.gridSliderWrapper.x-topBar.gridSliderCursor.x;
                        topBar.gridButtonWrapper.y = p.y-topBar.gridSliderWrapper.y-topBar.gridSliderCursor.y;
                    }

                    stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownGridButton,false,-1);
                    stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownGridButton,false,-1);
                    stage.addEventListener(KeyboardEvent.KEY_UP,keyUpGridButton,false,-1);
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

        private function updateTraceOpaButtonPosByAlpha(alpha:Number):void
        {
            traceMenu["traceOpaButton"].x = (traceMenu["traceOpaBar"].x+1)+(traceMenu["traceOpaBar"].width*alpha);
        }

        private function closeTraceMenu():void
        {
            traceMenuON = false;
            traceMenu.visible = false;
            traceMenu.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,rightMouseUpTraceWindow);
        }

        private function rightMouseUpTraceWindow(e:MouseEvent):void
        {
            if(!traceMenuON) return;

            const target:DisplayObject = e.target as DisplayObject;
            if(!target ) return;

            const targetName:String = target.name;

            switch(targetName)
            {

                case "traceRotateButton":
                {
                    if(canvasTraceLayer.rotation !== 0)
                    {
                        saveOneTime = false;

                        canvasTraceLayer.rotation = 0;

                        tracePosInfo[2] = 0;
                    }
                }
                break;

                case "traceResizeButton":
                {
                    if(canvasTraceLayer.scaleY !== 1.0)
                    {
                        saveOneTime = false;

                        canvasTraceLayer.scaleX = (tracePosInfo[5])? -1.0 : 1.0;
                        canvasTraceLayer.scaleY = 1.0;

                        tracePosInfo[3] = canvasTraceLayer.scaleX;
                        tracePosInfo[4] = canvasTraceLayer.scaleY;
                    }
                }
                break;

                case "traceMoveButton":
                {
                    if(canvasTraceBitmap.x !== -canvasTraceBitmap.width/2
                    && canvasTraceBitmap.y !== -canvasTraceBitmap.height/2)
                    {
                        saveOneTime = false;

                        canvasTraceLayer.x = CANVAS_WIDTH/2;
                        canvasTraceLayer.y = CANVAS_HEIGHT/2;

                        canvasTraceBitmap.x = -canvasTraceBitmap.bitmapData.width/2;
                        canvasTraceBitmap.y = -canvasTraceBitmap.bitmapData.height/2;

                        tracePosInfo[0] = canvasTraceBitmap.x;
                        tracePosInfo[1] = canvasTraceBitmap.y;
                    }
                }
                break;

                default:
                break;
            }
        }

        private function openTraceWindow():void //load clip버튼에서 눌러줬을때 틀여줌
        {
            traceMenu.hint("Reference layer");
            traceMenu.x = Math.floor(mouseX-traceMenu.width/2);
            traceMenu.y = Math.floor(mouseY-8);
            traceMenu.visible = true;

            setTopChildIndex(traceMenu);
            checkBoxPosition(traceMenu);

            if(traceMenuON === false)
            {
                traceMenu.addEventListener(MouseEvent.RIGHT_MOUSE_UP,rightMouseUpTraceWindow);
                stage.addEventListener(MouseEvent.MOUSE_OVER,traceMenuHintONEvent);
            }

            traceMenuON = true;
            setTopChildIndex(traceMenu);
        }

        private function isTraceImageAlreadyDeleted():Boolean
        {
            return (canvasTraceBitmapData && canvasTraceBitmapData.width > 1 && canvasTraceBitmapData.height > 1)
                   || !canvasTraceBitmapData;
        }

        private function setTraceDeleteButton():void
        {
            setTopChildIndex(traceMenu);

            if(isTraceImageAlreadyDeleted())
            {
                clearTraceImage();
            }

            if(traceMemoryTrainingON === true)
            {
                setTraceVisibleButton();
            }
        }

        private function setTraceVisibleButton():void
        {
            if(traceMemoryTrainingON === false)
            {
                traceMemoryTrainingON = true;
                traceMenu.traceVisibleOFFButton.visible = false;
                traceMenu.traceVisibleONButton.visible = true;
            }
            else if(traceMemoryTrainingON === true)
            {
                traceMemoryTrainingON = false;
                traceMenu.traceVisibleOFFButton.visible = true;
                traceMenu.traceVisibleONButton.visible = false;
            }
        }

        private function setTraceMirrorButton():void
        {
            var tempBitData:BitmapData = new BitmapData(canvasTraceBitmapData.width,
                                                        canvasTraceBitmapData.height,true,0);
            var flipMat:Matrix = new Matrix(-1,0,0,1,canvasTraceBitmapData.width);

            tempBitData.draw(canvasTraceBitmapData,flipMat);

            if(canvasTraceBitmapData && tempBitData !== canvasTraceBitmapData) canvasTraceBitmapData.dispose();
            canvasTraceBitmapData = tempBitData.clone();
            canvasTraceBitmap.bitmapData = canvasTraceBitmapData;
            tempBitData.dispose();
            tempBitData = null;

            canvasTraceLayer.rotation = -canvasTraceLayer.rotation;//일단 각도 대칭해주고

            //canvas1을 기준으로 중심점 거리를 구해서 x값보정과 각도 보정을 함
            const canvasCenterX:Number = canvasTraceLayer.x+canvasTraceBitmap.x+canvasTraceBitmap.width/2;
            const subX:Number = Math.round((canvasTraceLayer.x-canvasCenterX)*2);
            const deg:Number = canvasTraceLayer.rotation-(regPoint.rotation)*2;

            canvasTraceBitmap.x = canvasTraceBitmap.x+subX;
            canvasTraceLayer.rotation = deg;//캔버스 전체가 회전해있을때 각도보정
            canvasTraceBitmap.smoothing = true;
            tracePosInfo[0] = canvasTraceBitmap.x;
            tracePosInfo[2] = canvasTraceLayer.rotation;

            saveOneTime = false;
        }

        private function setTraceRotateButton():void
        {
            var getAngle:Function = cGetCanvasRotationAngle(canvasTraceLayer);

            mouseDragON = true;
            traceMenu.visible = false;
            canvasTraceBitmap.smoothing = false;

            function traceRotateButtonUpEvent(e:MouseEvent):void
            {
                mouseDragON = false;
                saveOneTime = false;
                traceMenu.visible = true;
                getAngle = null;
                tracePosInfo[2] = canvasTraceLayer.rotation; //deg로 저장
                setRotateCursorOFF();
                canvasTraceBitmap.smoothing = true;
                stage.removeEventListener(MouseEvent.MOUSE_UP,traceRotateButtonUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,traceRotateButtonMoveEvent);
            }

            function traceRotateButtonMoveEvent(e:MouseEvent):void
            {
                canvasTraceLayer.rotation = getAngle(false);
            }

            stage.addEventListener(MouseEvent.MOUSE_UP,traceRotateButtonUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,traceRotateButtonMoveEvent);
        }

        private function setTraceResizeButton():void
        {
            const mirrorFlag:Boolean = tracePosInfo[5];
            var getScale:Function = cImageResizeFunc(canvasTraceLayer.scaleX);

            traceMenu.visible = false;
            canvasTraceBitmap.smoothing = false;

            mouseDragON = true;

            function traceResizeButtonUpEvent(e:MouseEvent):void
            {
                saveOneTime = false;
                mouseDragON = false;
                getScale = null;

                tracePosInfo[3] = canvasTraceLayer.scaleX;
                tracePosInfo[4] = canvasTraceLayer.scaleY;
                traceMenu.visible = true;
                canvasTraceBitmap.smoothing = true;
                setToolTipOFF();
                stage.removeEventListener(MouseEvent.MOUSE_UP,traceResizeButtonUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,traceResizeButtonMove);
            }

            function traceResizeButtonMove(e:MouseEvent):void
            {
                const scale:Number = getScale(mouseX,mouseY);
                canvasTraceLayer.scaleX = (mirrorFlag) ? -scale:scale;
                canvasTraceLayer.scaleY = scale;

                setToolTipString(getImageScaleHint(canvasTraceBitmapData.width,canvasTraceBitmapData.height,scale,true));
            }

            setToolTipString(getImageScaleHint(canvasTraceBitmapData.width,canvasTraceBitmapData.height,Math.abs(canvasTraceLayer.scaleX),true));
            setToolTipON();
            stage.addEventListener(MouseEvent.MOUSE_UP,traceResizeButtonUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,traceResizeButtonMove);
        }

        private function setTraceMoveButton():void
        {
            var getMovedPos:Function = cImageMoveFunc(canvasTraceBitmap,canvasTraceLayer.rotation+regPoint.rotation,tracePosInfo[3],tracePosInfo[4]);

            mouseDragON = true;
            traceMenu.visible = false;
            canvasTraceBitmap.smoothing = false;

            function traceMoveButtonUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP,traceMoveButtonUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,traceMoveButtonMoveEvent);
                saveOneTime = false;
                mouseDragON = false;
                getMovedPos = null;
                traceMenu.visible = true;
                tracePosInfo[0] = canvasTraceBitmap.x;
                tracePosInfo[1] = canvasTraceBitmap.y;
                canvasTraceBitmap.smoothing = true;
            }

            function traceMoveButtonMoveEvent(e:MouseEvent):void
            {
                const pos:Point = getMovedPos();

                canvasTraceBitmap.x = pos.x;
                canvasTraceBitmap.y = pos.y;
            }

            stage.addEventListener(MouseEvent.MOUSE_UP,traceMoveButtonUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,traceMoveButtonMoveEvent);
        }

        private function resetTraceOpa():void
        {
            traceAlphaSave = 0.5;
            canvasTraceLayer.alpha = 0.5;
            updateTraceOpaButtonPosByAlpha(0.5);
            traceMenu.hint(STRING_TRACE_IMAGE_OPACITY+Math.floor(0.5*100)+"%");
            canvasTraceLayer.visible = true;
        }

        private function setTraceOpaButton():void
        {
            const barWidth:Number = traceMenu["traceOpaBar"].width;
            const minDist:Number = traceMenu["traceOpaBar"].x+1;
            const maxDist:Number = minDist+barWidth-2;
            const step:Number = 10;

            mouseDragON = true;

            function traceOpaButtonUpEvent(e:MouseEvent):void
            {
                mouseDragON = false;
                stage.removeEventListener(MouseEvent.MOUSE_UP,traceOpaButtonUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,traceOpaButtonMoveEvent);
            }

            function traceOpaButtonMoveEvent(e:MouseEvent):void
            {
                setTraceOpaValue();
            }

            function setTraceOpaValue():void
            {
                var mx:Number = traceMenu.mouseX;

                if(mx < minDist) mx = minDist;
                else if(mx > maxDist) mx = maxDist;

                const value:Number = mx-minDist;
                const valueMax:Number = maxDist-minDist;
                const alpha:Number = getDiplayObjectAlpha(Math.floor(((value/valueMax))*100)/100);

                traceMenu["traceOpaButton"].x = mx;

                if(alpha < 0.0)
                {
                    canvasTraceLayer.visible = false;
                    canvasTraceLayer.alpha = 0.0;
                    traceAlphaSave = 0.0
                }
                else
                {
                    canvasTraceLayer.visible = true;
                    canvasTraceLayer.alpha = alpha;
                    traceAlphaSave = alpha;
                }

                traceMenu.hint(STRING_TRACE_IMAGE_OPACITY+Math.floor(alpha*100+0.5)+"%");
            }

            traceMenu.hint(STRING_TRACE_IMAGE_OPACITY+Math.floor(traceAlphaSave*100+0.5)+"%");
            setTraceOpaValue();

            stage.addEventListener(MouseEvent.MOUSE_UP,traceOpaButtonUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,traceOpaButtonMoveEvent);
        }

        private function saveTraceImage():void
        {
            if(!canvasTraceBitmap.bitmapData) return;

            const bmpd:BitmapData = canvasTraceBitmap.bitmapData;//실제 보여주는 데이터를 저장해줌
            const w:Number = canvasTraceBitmap.width;
            const h:Number = canvasTraceBitmap.height;
            const fs:FileStream = new FileStream();
            var ba:ByteArray = new ByteArray();
            const newRectangle:Rectangle = new Rectangle(0,0,w,h);

            bmpd.copyPixelsToByteArray(newRectangle,ba);
            // ba.compress();
            fs.open(traceImageFile,FileMode.WRITE);
            fs.writeObject([ba,w,h]);
            fs.close();
            ba.clear();
            ba = null;
        }

        private function clearTraceImage():void
        {
            canvasTraceBitmapData.dispose();
            canvasTraceBitmapData = new BitmapData(1,1,true,0);
            canvasTraceBitmap.bitmapData = canvasTraceBitmapData;
            resetTraceImageInfo();
            canvasTraceLayer.visible = false;
            traceAlphaSave = 0.0;
            canvasTraceLayer.alpha = 0.0;
            saveTraceImage();
        }

        private function resetTraceImageInfo():void
        {
            const ww:Number = -canvasTraceBitmap.width/2;
            const hh:Number = -canvasTraceBitmap.height/2;

            canvasTraceBitmap.x = ww;
            canvasTraceBitmap.y = hh; //중점 셋팅
            canvasTraceLayer.rotation = 0;
            canvasTraceLayer.scaleX = 1;
            canvasTraceLayer.scaleY = 1;
            traceReizeMoveSum = 0;
            tracePosInfo = [ww,hh,0,1,1,false];
        }

        private function setTraceImageInfo(x:Number,y:Number,rotation:Number,scaleX:Number,scaleY:Number,mirror:Boolean):void
        {
            canvasTraceLayer.x = CANVAS_WIDTH/2;
            canvasTraceLayer.y = CANVAS_HEIGHT/2;
            canvasTraceBitmap.x = x;
            canvasTraceBitmap.y = y;
            canvasTraceLayer.scaleX = scaleX;
            canvasTraceLayer.scaleY = scaleY;
            canvasTraceLayer.rotation = rotation;
            tracePosInfo = [x,y,rotation,scaleX,scaleY,mirror];
        }

        private function updateTraceInfoAfterPaste():void
        {
            if(canvasTraceLayer.visible === false || traceAlphaSave === 0.0)
            {
                updateTraceOpaButtonPosByAlpha(0.5);
                traceAlphaSave = 0.5;
                canvasTraceLayer.visible = true;
                canvasTraceLayer.alpha = 0.5;
            }

            canvasTraceBitmap.smoothing = true;
            saveOneTime = false;
        }

        private function paste2020FileImageToTraceLayer(file:File):void
        {
            if(isTrue2020File(file) === false)
            {
                saveThenLoadFlag = false;
                setLoadBoxVisible(false);
                setLoadBoxOFFLoadFailed();
                return;
            }

            const bmpd:BitmapData = getFinalImageFrom2020File(file,true);
            pasteTraceImage(bmpd,bmpd.width,bmpd.height);

            if(!replayModeON)
            {
                openTraceWindow();
            }
        }

        private function pasteCanvasImageToTraceLayer():void
        {
            if(deepUndoON) setApplyDeepUndo();

            var layer1Flag:Boolean = canvas1Bitmap.visible;
            var layer2Flag:Boolean = canvas11Bitmap.visible;

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

            mergeImageToTraceLayer((layer1Flag)  ? canvas1BitmapData :null
                                    ,(layer2Flag) ? canvas11BitmapData:null);
            const rect:Rectangle = new Rectangle(0,0,canvas1BitmapData.width,canvas1BitmapData.height);
            var command:String = "clear";

            if(layer1Flag)
            {
                canvas1BitmapData.fillRect(rect,0);
            }

            if(layer2Flag)
            {
                canvas11BitmapData.fillRect(rect,0);
            }

            if((layer1Flag && !layer2Flag) || !canvas11Bitmap.visible)
            {
                command = "clear1";
            }
            else if((layer2Flag && !layer1Flag) || !canvas1Bitmap.visible)
            {
                command = "clear2";
            }

            if(hasLastRDataCommand(command))
            {
                undoData.addContinue();
            }
            else
            {
                rDataBuffer = [[command]];
                undoData.addNew();
            }

            resetTraceImageInfo();
            updateTraceInfoAfterPaste();
        }

        private function pasteTraceImage(bmpd:IBitmapDrawable,w:Number,h:Number):void
        {
            const maxSize:Number = 1000;
            var maxLength:Number = (w > h) ? w : h;
            var scaleFix:Number = (maxLength > maxSize) ? maxSize/maxLength : 1.0;

            w = Math.floor(w*scaleFix);
            h = Math.floor(h*scaleFix); //maxSize 값을 넘으면 리사이즈 해줌
            var scaleMat:Matrix = new Matrix();
            scaleMat.scale(scaleFix,scaleFix);

            var tmpBMPD:BitmapData = new BitmapData(w,h,true,0);

            tmpBMPD.draw(bmpd,scaleMat,null,null,null,true);
            if(canvasTraceBitmapData && tmpBMPD !== canvasTraceBitmapData) canvasTraceBitmapData.dispose();
            canvasTraceBitmapData = tmpBMPD.clone();
            canvasTraceBitmap.bitmapData = canvasTraceBitmapData;

            tmpBMPD.dispose();
            tmpBMPD = null;

            resetTraceImageInfo();

            const gw:Number = CANVAS_WIDTH;
            const gh:Number = CANVAS_HEIGHT;
            const widthFlag:Boolean = (w >= h) ? true : false;
            var autoScale:Number = 0;

            if(w > gw && widthFlag === true) autoScale = gw/w;
            else if (h > gh && widthFlag === false) autoScale = gh/h;

            if(autoScale > 0)
            {
                canvasTraceLayer.scaleX = autoScale;
                canvasTraceLayer.scaleY = autoScale;
                tracePosInfo[3] = autoScale;
                tracePosInfo[4] = autoScale;
            }

            updateTraceInfoAfterPaste();
        }

        private function getBlurSize(size:Number,z:Number):Number
        {
            var blurSize:Number = size/2;

            if(blurSize <= 2) blurSize = 2;
            else if(blurSize > 30) blurSize = 30;

            return blurSize*z;
        }

        //drawdone에서 줌된 blur사이즈가 아니 1배율 블러를 적용해야 제대로 되기 때문에 이거해줌
        private function setBlurCanvasBySizeNoZoomReplayMode():void
        {
            const blurSize:Number = getBlurSize(airBrushSizeReplayMode,1.0);
            const blurf:BlurFilter = new BlurFilter(blurSize,blurSize,3);

            rcanvas2Draw.filters = [blurf];
        }

        private function resetCanvasBlurReplaymode():void
        {
            airBrushSizeReplayMode = 0;
            rcanvas2Draw.filters = [];
        }

        private function setBlurCanvasBySizeReplayMode(size:Number):void
        {
            const blurSize:Number = getBlurSize(size,rzoomed);
            const blurf:BlurFilter = new BlurFilter(blurSize,blurSize,3);
            airBrushSizeReplayMode = size;
            rcanvas2Draw.filters = [blurf];
        }

        private function setAirBrushCheckBox(flag:Boolean,penFlag:Boolean):void
        {
            controlBox["airBrushOFFButton"].visible = flag;
            controlBox["airBrushONButton"].visible = !flag;

            if(flag)
            {
                airBrushSizeDrawMode = (penFlag) ? penSize:eraseSize;

                controlBox.blurShapeSetON();
            }
            else if(airBrushSizeDrawMode !== 0)
            {
                airBrushSizeDrawMode = 0;
                canvas2Draw.filters = [];
                controlBox.blurShapeSetOFF();
            }
        }

        private function setEraseAirBrushButtonShortCut():void
        {
            eraseAirBrushON = !eraseAirBrushON;
            setAirBrushCheckBox(eraseAirBrushON,false);

            if(eraseAirBrushON) setToolTipTempON("Eraser Air brush ON");
            else setToolTipTempON("Eraser Air brush OFF");
        }

        private function setEraseAirBrushButton(flag:Boolean):void
        {
            eraseAirBrushON = flag;
            setAirBrushCheckBox(flag,false);
        }

        private function setPenAirBrushButtonShortCut():void
        {
            airBrushON = !airBrushON;
            setAirBrushCheckBox(airBrushON,true);

            if(airBrushON) setToolTipTempON("Pen Air brush ON");
            else setToolTipTempON("Pen Air brush OFF");
        }

        private function setPenAirBrushButton(flag:Boolean):void
        {
            airBrushON = flag;
            setAirBrushCheckBox(flag,true);
        }

        private function resetTransBG(replayMode:Boolean):void
        {
            var xPanel:Sprite;
            var w:Number = CANVAS_WIDTH;
            var h:Number = CANVAS_HEIGHT;
            var color:uint;

            if(replayMode)
            {
                xPanel = rcanvasPanel;
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

        private function setTransBG(replayMode:Boolean):void
        {
            var xPanel:Sprite;
            var w:Number = CANVAS_WIDTH;
            var h:Number = CANVAS_HEIGHT;

            if(replayMode)
            {
                xPanel = rcanvasPanel;
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

        private function setCanvas2IndexToLayer1():void
        {
            if(canvasPanel.getChildIndex(canvas2) < canvasPanel.getChildIndex(lassoBox1))
            {
                canvasPanel.setChildIndex(canvas2,canvasPanel.getChildIndex(lassoBox1));
            }
        }

        private function setCanvas2IndexToLayer2():void
        {
            if(canvasPanel.getChildIndex(canvas2) > canvasPanel.getChildIndex(canvas1Bitmap))
            {
                canvasPanel.setChildIndex(canvas2,canvasPanel.getChildIndex(canvas1Bitmap));
            }
        }

        private function selectSubLayer(flag:Boolean,onlyViewFlag:Boolean):void
        {
            if(onlyViewFlag)
            {
                if(flag)
                {
                    canvas1Bitmap.visible = false;
                    canvas11Bitmap.visible = true;
                }
                else
                {
                    canvas1Bitmap.visible = true;
                    canvas11Bitmap.visible = false;
                }
            }
            else
            {
                canvas1Bitmap.visible = true;
                canvas11Bitmap.visible = true;
            }

            subLayerON = flag;

            if(flag)
            {
                controlBox.layer1SelectButton.alpha = BUTTON_OFF_ALPHA;
                controlBox.layer2SelectButton.alpha = 1.0;
                setCanvas2IndexToLayer2();
            }
            else
            {
                controlBox.layer1SelectButton.alpha = 1.0;
                controlBox.layer2SelectButton.alpha = BUTTON_OFF_ALPHA;
                setCanvas2IndexToLayer1();
            }

            checkedLayer = 0;
            controlBox.layer1CheckButton.visible = false;
            controlBox.layer1UncheckButton.visible = true;
            controlBox.layer2CheckButton.visible = false;
            controlBox.layer2UncheckButton.visible = true;
            toolBox.setToolButtonsForCheckedLayerOFF();
            toolBox2.setToolButtonsForCheckedLayerOFF();

        }

        private function setSharpLineButtonShortcut():void
        {
            setSharpLineButton(!sharpLineON);

            if(sharpLineON) setToolTipTempON("Sharp line ON");
            else setToolTipTempON("Sharp line OFF");
        }

        private function getSharpLineOffset(size:Number):Number
        {
            return (sharpLineON) ? (size % 2.0 === 0) ? 0.0 : 0.5
                                 : (size % 2.0 === 0) ? 0.5 : 0.0;
        }

        private function setSharpLineButton(flag:Boolean):void
        {
            sharpLineON = flag;

            controlBox["sharpLineOFFButton"].visible = flag;
            controlBox["sharpLineONButton"].visible = !flag;

            updatePenSizeCursor();
        }

        private function updateStageBGSize():void
        {
            stageBG.graphics.clear();
            stageBG.graphics.beginFill(0,0.0);
            stageBG.graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
            stageBG.graphics.endFill();
        }

        private function updateStageBGColor(color:uint=0xCCCCCC):void
        {
            stage.color = color;

            STAGE_BG_COLOR = color;
        }

        private function updateWindowTitle():void
        {
            stage.nativeWindow.title = saveFileName + STRING_TITLE_FOFOPAINT;
            if(canvasWindowON) setSyncWindowTitle();
        }

        private function setUIColorButton():void
        {
            uiColorIndex++;

            if(uiColorIndex > uiColorSet.length-1)
                uiColorIndex = 0;

            setUIColor(uiColorIndex);

            const uiColorName:String = (uiColorIndex === 0) ? "Black"
                                      :(uiColorIndex === 1) ? "Dark Gray"
                                      :(uiColorIndex === 2) ? "Medium Gray"
                                      :(uiColorIndex === 3) ? "Light Gray" : "";

            setHintONTemp(uiColorName);
        }

        private function setUIColor(index:int):void
        {
            updateStageBGColor(uiColorSet[index][2]);
            controlBox.changeUIColor(uiColorSet[index][1]);
            pickerBox.changeUIColor(uiColorSet[index][1]);
            sideBar.changeUIColor(uiColorSet[index][0]);
            previewBox.chanegStageColor(uiColorSet[index][2]);
            toolBox.changeUIColor(uiToolBoxColorSet[index]);
            toolBox2.changeUIColor(uiToolBoxColorSet[index]);
            fillPenBox.changeBGColor(uiToolBoxColorSet[index]);
            traceMenu.changeUIColor(uiToolBoxColorSet[index],index === 0);
            lassoMenu.changeUIColor(uiToolBoxColorSet[index]);
            numPadBox.changeUIColor(uiToolBoxColorSet[index]);
            topBar.changeUIColor(uiColorSet[index][0],uiColorSet[index][1],uiColorSet[index][4]);
            rotateCursorBox.changeUIColor(uiColorSet[index][0],uiColorSet[index][1]);
            replayTimeBox.changeUIColor(uiColorSet[index][0],uiColorSet[index][1],uiToolBoxColorSet[index][4],index);
            checkClipBoardImage();
            appInfoBox.changeUIColor(uiColorSet[index][1]);
            setRGBInfoTextColorByColor(pickerBox.getRGBInfoBGColor());

            if(pickerMode !== 1)
            {
                changePickerModeToPenColor();
            }

            pickerBox.checkPickerModeButton(pickerMode);
            updateScrollBarColorHeight();
            setResizeButtonColor(uiColorSet[index][3]);

            toolTipBox.setBGColor(toolTipBoxBGColor[index]);
            hintBox.setBGColor(toolTipBoxBGColor[index]);
            hint.setCursorColor(hintHorverCursorColor[index]);
            fofo.changeColor(uiColorSet[index][1]);
            capStampFontListBox.changeUIColor(uiColorSet[index][0],uiColorSet[index][1],toolTipBoxBGColor[index]);

            if(canvasWindowON)
            {
                canvasWindow.stage.color = uiColorSet[index][2];
            }

            setPickerBoxTransBGBrightness(index);
        }

        private function addStageInputEvent():void
        {
            //전역스테이지 이벤트 cMouseMoveStage <- 스테이지 마우스 무브는 클로저로 하고있음
            stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownStage,false,1);
            stage.addEventListener(MouseEvent.MOUSE_UP,mouseUpStage,false,1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,rightMouseUpStage,false,1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownStage,false,1);
            stage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN,wheelDownStage,false,1);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownStage,false,1);
            stage.addEventListener(KeyboardEvent.KEY_UP,keyUpStage,false,1);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, updatePenCursorPositionEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,updatePenCursorPositionEvent,false,-1);
            stage.addEventListener(Event.MOUSE_LEAVE,stageMouseLeaveEvent,false);
        }

        private function addInputEventStageChild():void
        {
            //창을 가운데로 옮김
            stage.nativeWindow.x = Capabilities.screenResolutionX/2 - 680/2;
            stage.nativeWindow.y = Capabilities.screenResolutionY/2 - 768/2 - 50;
            stage.nativeWindow.addEventListener(Event.RESIZE,windowResizeEvent);
            stage.nativeWindow.addEventListener(Event.DEACTIVATE,windowDeactiveEvent);
            stage.nativeWindow.addEventListener(Event.ACTIVATE,windowActiveEvent);
            stage.nativeWindow.addEventListener(Event.CLOSING, windowClosingEvent);
            stage.addEventListener(MouseEvent.MOUSE_OUT,globalHintOFF);
            stage.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER,onDragEnterEvent);
            stage.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP,onDragDropEvent);
            stage.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelStage);

            //힌트 보여주는 이벤트
            appInfoBox.addEventListener(MouseEvent.MOUSE_OVER,toolBoxHintONEvent);
            toolBox.addEventListener(MouseEvent.MOUSE_OVER,toolBoxHintONEvent);
            toolBox.addEventListener(MouseEvent.MOUSE_OUT,toolBoxHintOFFEvent);
            toolBox2.addEventListener(MouseEvent.MOUSE_OVER,toolBoxHint2ONEvent);
            replayTimeBox.addEventListener(MouseEvent.MOUSE_OVER,topBarHintONEvent);
            topBar.addEventListener(MouseEvent.MOUSE_OVER,topBarHintONEvent);
            previewBox.addEventListener(MouseEvent.MOUSE_OVER,previewBoxHintONEvent);
            controlBox.addEventListener(MouseEvent.MOUSE_OVER,controlBoxHintONEvent);
            pickerBox.addEventListener(MouseEvent.MOUSE_OVER,pickerBoxHintONEvent);
            sideBarScrollBar.addEventListener(MouseEvent.MOUSE_OVER,scrollBarHintONEvent);
            loadMenuBox.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownLoadBox);
        }

        private function setControlBoxInfoOFF():void
        {
            var toolName:String = "Pen";
            const nt:uint = nowTool;

            if(isNowTool(TOOL_ERASE)) toolName = "Eraser";
            else if(isNowTool(TOOL_LINE)) toolName = "Line";
            else if(isNowTool(TOOL_FILL_PEN)) toolName = "Fill-pen";
            // else if(isNowTool(TOOL_SCAN_FILL)) toolName = "Scan-fill";

            controlBox.hintText(toolName);
        }

        private function getOpacityButtonHint(targetName:String):String
        {
            return "Opacity "+getOpacityHint(targetName)+" [g, b]";
        }

        private function getSizeButtonHint(targetName:String):String
        {
            return "Size "+getPenSizeHint(targetName)+ " [f, v, h, n]";
        }

        private function previewBoxHintONEvent(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target) return;
            const targetName:String = target.name;

            if(isHintCantUse() && !fillPenStarted)
            {
                return;
            }

            hint.on("Canvas navigator",e.currentTarget);
        }

        private function controlBoxHintONEvent(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target) return;
            const targetName:String = target.name;

            if(fillPenStarted)
            {
                switch(targetName)
                {
                    case "alphaButton":
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
                        hint.on(getSizeButtonHint(targetName),target);
                    }
                    return;

                    default:
                    return;
                }
                return;
            }
            else if(isHintCantUse())
            {
                return;
            }

            var str:String = "";

            switch(targetName)
            {
                case "shapeCircle": str = "circle";
                break;

                case "shapeRect": str = "Square";
                break;

                case "penSmoothSliderWapper":
                {
                    str = "Pen smoothing "+penSmoothSlideValue + "/" + penSmoothSlideTotal;
                }
                break;

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
                    hint.on(getSizeButtonHint(targetName),target);
                }
                return;

                case "alphaButton":
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
                    hint.on(getOpacityButtonHint(targetName),target);
                }
                return;

                case "sharpLineButtonWrapper":
                case "sharpLineOFFButton":
                case "sharpLineONButton":
                case "sharpLineText":
                    str = "Sharp line [3, 8]";
                break;

                case "airBrushButtonWrapper":
                case "airBrushOFFButton":
                case "airBrushONButton":
                case "airBrushText":
                    str = "Air brush [4, 7]";
                break;

                case "layer1SelectButton":
                    str = "Select layer 1 [1, 9]\nShow only layer 1 ON/OFF [click]";
                break;

                 case "layer2SelectButton":
                    str = "Select layer 2 [2, 0]\nShow only layer 2 ON/OFF [click]";
                break;

                case "layer1CheckButton":
                case "layer1UncheckButton":
                    str = "Check layer 1 [1+w, 9+i]\nfor move image tool, lasso tool, reference layer";
                break;

                case "layer2CheckButton":
                case "layer2UncheckButton":
                    str = "Check layer 2 [2+w, 0+i]\nfor move image tool, lasso tool, reference layer";
                break;

                case "layerSwapButton":
                    str = "Swap layers [shift+d, shift+j]";
                break;

                case "layerMergeButton":
                    str = "Merge image to layer 2 [shift+e, shift+o]";
                break;

                default:
                return;
            }

            if(str === "")
            {
                return;
            }

            hint.on(str,target);
        }

        private function HEXtoHSV(color:uint):Vector.<Number>
        {
            const r:uint = (color >> 16) & 0xFF;
            const g:uint = (color >> 8) & 0xFF;
            const b:uint = color & 0xFF;

            return RGBtoHSV(r,g,b);
        }

        private function setColorTransform(target:DisplayObject,color:uint):void
        {
            if(!target) return;

            const c:ColorTransform = target.transform.colorTransform;
            c.color = color; //-1이면 기본 컬러로 간다
            c.alphaMultiplier = 1.0;

            target.transform.colorTransform = c;
        }

        private function updateReplayBarPos(stw:Number):void
        {
            const scale:Number = getUIScale();
            const maxWidth:Number = stw-(replayTimeBox["replayTotalBar"].x+5)*scale;

            replayTimeBox["replayTotalBar"].width =  Math.floor(maxWidth/scale);
            replayTimeBox["replayBGBar"].width =  Math.floor(stw/scale)+1;
            replayTimeBox["frameInfo"].x = replayTimeBox["replayTotalBar"].x;
            replayTimeBox["frameInfo"].width =  Math.floor(maxWidth/scale);
            replayTimeBox["replayNowBar"].width = (replayTimeBox["replayTotalBar"].width)*(rNowFrame/TOTAL_FRAME);
        }

        private function setUpdateButton():void
        {
            setLoadBoxReady(true,false);
            updateAfterSaveFlag = true;
            saveFile(false);
        }

        private function startUpdate():void
        {
            setLoadBoxVisible(false);
            updateAfterSaveFlag = false;
            topBar.updateButtonVisible(false);
            if(needUpdate === 1)
            {
                addTimer(0.5,false,function():void
                {
                    installNewVersion();
                });
            }
            else if(needUpdate === 2)
            {
                navigateToURL(new URLRequest("https://github.com/guljam/2020FlashPaint"));
            }
            navigateToURL(new URLRequest("https://raw.githubusercontent.com/guljam/2020FlashPaint/master/releasenote.txt"));
        }

        private function installNewVersion():void
        {
            if(UPDATE_FILE.exists)
            {
                var updater:Updater = new Updater();
                updater.update(UPDATE_FILE, NEW_VERSION);
            }
        }

        private function shortCutPenAlpha(inc:Boolean):void
        {
            var alpha:Number = 0;
            var alphaStr:String = "";

            function setAlpha(alp:Number,size:uint):void
            {
                var index:Number = penAlphaList.indexOf(alp);
                const len:uint = penAlphaList.length-1;

                if(inc)
                {
                    index++;
                    if(index > len) index = len;
                }
                else
                {
                    index--;
                    if(index < 1) index = 1;
                }

                const alphaValue:Number = penAlphaList[index];
                alphaStr = size+"px, "+alphaValue*100+"%";

                setToolTipTempON(alphaStr);
                setPenAlpha(alphaValue);
            }

            setNowToolForDrawing(true);

            if(isNowToolPenOrLine() || isNowTool(TOOL_FILL_PEN))
            {
                setAlpha(penAlpha,penSize);
            }
            else if(isNowTool(TOOL_ERASE))
            {
                setAlpha(eraseAlpha,eraseSize);
            }
        }

        private function shortCutPenSize(flag:Boolean):void
        {
            const len:uint = penSizeList.length-1;

            function setSize(index:uint,alpha:Number):void
            {
                if(flag)
                {
                    index++;
                    if(index > len) index = len;
                }
                else
                {
                    index--;
                    if(index < 1) index = 1;
                }

                const sizeValue:Number = penSizeList[index];
                const sizeStr:String =  sizeValue+"px, "+(penAlpha*100)+"%";
                const sizeValueZoomed:Number = sizeValue*zoomed;

                setToolTipTempON(sizeStr);
                setPenSize(index);
                updatePenSizeCursor();

                if(penSizeCursor.visible === true)
                {
                    if(sizeValueZoomed <= 4)
                    {
                        penSizeCursor.visible = false;
                    }
                }
                else if(sizeValueZoomed > 4)
                {
                    penSizeCursor.visible = true;
                }
            }

            setNowToolForDrawing(true);

            if(isNowToolPenOrLine() || isNowTool(TOOL_FILL_PEN))
            {
                setSize(penSizeIndex,penAlpha);

                if(airBrushON && penSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = penSize;
                }
            }
            else if(isNowTool(TOOL_ERASE))
            {
                setSize(eraseSizeIndex,eraseAlpha);

                if(eraseAirBrushON && eraseSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = eraseSize;
                }
            }
        }

        //composing 키에대한 체크 잘모르겠음 한영 변환이 관련있는거 같음
        private function checkKeyInvalidKey():void
        {
            const len:uint = KEY_BUFFER.length;
            for(var i:int=0;i<len;i++)
            {
                if(KEY_BUFFER[i] === 229
                || KEY_BUFFER[i] === 241
                || KEY_BUFFER[i] === 242)
                {
                    resetKeyBuffer();
                    return;
                }
            }

            if(len >= 2)
            {
                if((KEY_BUFFER[0] === 18 && KEY_BUFFER[1] === 32)
                || (KEY_BUFFER[0] === 32 && KEY_BUFFER[1] === 18))
                {
                    resetKeyBuffer();
                }
            }
        }

        private function keyUpStage(e:KeyboardEvent):void
        {
            setIMEDisabled();
            checkKeyInvalidKey();

            if(stage.nativeWindow.active)
            {
                realWorkingTimer.resetAFKCount();
            }

            if(loadMenuBox.visible)
            {
                return;
            }

            const keyCode:uint = e.keyCode;
            const index:int = KEY_BUFFER.lastIndexOf(keyCode);

            if(index > -1)
            {
                KEY_BUFFER.splice(index,1);
            }
        }

        private function keyDownStage(e:KeyboardEvent):void
        {
            setIMEDisabled();
            checkKeyInvalidKey();

            if(stage.nativeWindow.active)
            {
                realWorkingTimer.resetAFKCount();
            }

            const keyCode:uint = e.keyCode;

            if(loadMenuBox.visible || keyCode === KEY.window)
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

        private function setOpaButton(targetName:String):void
        {
            const number:String = targetName.substr(11,targetName.length);
            const index:int = parseInt(number);

            setPenAlpha(penAlphaList[index]);
        }

        private function setPenSizeButton(targetName:String):void
        {
            const numberOnly:String = targetName.substr(11,targetName.length);
            const index:uint = parseInt(numberOnly);

            setPenSize(index);
            updatePenSizeCursor();

            if(isNowTool(TOOL_FILL_PEN))
            {
                if(airBrushON && penSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = penSize;
                }
            }
            else if(isNowToolPenOrLine())
            {
                if(airBrushON && penSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = penSize;
                }
            }
            else if(isNowTool(TOOL_ERASE))
            {
                if(eraseAirBrushON && eraseSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = eraseSize;
                }
            }
        }

        private function getOpacityHint(targetName:String):String
        {
            const lastNumber:String = targetName.substr(11);
            const alpIndex:int = parseInt(lastNumber);
            const alpha:Number = penAlphaList[alpIndex];
            const alpha100:String = alpha*100+"";
            const hint:String = alpha100 +"%";

            return hint;
        }

        private function setPenSmoothButton():void
        {
            const minDist:Number = controlBox.penSmoothSlider.x+1; //펜 리스트에 흰색 선 시작과 끝 x좌표임
            const maxDist:Number = minDist+controlBox.penSmoothSlider.width-1;
            const step:Number = penSmoothSlideTotal;
            const div:Number = (maxDist-minDist)/step;
            const maxValue:Number = 0.85;
            const minValue:Number = 0.02;
            const stepValue:Number = (maxValue-minValue)/step;
            const airBrushFlag:Boolean = isNowToolPenOrLine() && airBrushON;
            const eraseAirBrushFlag:Boolean = isNowTool(TOOL_ERASE) && eraseAirBrushON;
            var oldValue:int = penSmoothSlideValue;

            mouseDragON = true;

            function penSmoothButtonUpEvent(e:MouseEvent):void
            {
                mouseDragON = false;
                stage.removeEventListener(MouseEvent.MOUSE_UP,penSmoothButtonUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,penSmoothButtonMoveEvent);
            }

            function setpenSmoothSlideValue():void
            {
                var mx:Number = controlBox.penSmoothSliderWapper.mouseX+controlBox.penSmoothSlider.x;

                if(mx < minDist) mx = minDist;
                else if(mx > maxDist) mx = maxDist;

                //버튼을 기준으로 중간값으로
                const value:Number = Math.floor((mx-minDist)/div);

                if(oldValue !== value)
                {
                    const xpos:Number = value*div+minDist;

                    if(controlBox.penSmoothSliderCursor.x === xpos) return;

                    controlBox.penSmoothSliderCursor.x = xpos;

                    if(value === 0) penSmoothValue = 0;
                    else penSmoothValue = maxValue-(value*stepValue);

                    penSmoothSlideValue = value;
                    oldValue = value;
                    hint.on("Pen smoothing "+value + "/"+step,controlBox.penSmoothSliderWapper,true);
                }
            }

            function penSmoothButtonMoveEvent(e:MouseEvent):void
            {
                setpenSmoothSlideValue();
            }

            setpenSmoothSlideValue();

            stage.addEventListener(MouseEvent.MOUSE_UP,penSmoothButtonUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, penSmoothButtonMoveEvent);
        }

        private function getMergedBitmapdtata(replayMode:Boolean,captureTransparentBG:Boolean,layer1:Boolean,layer2:Boolean,clipRect:Rectangle):BitmapData
        {
            var xBitmapData1:BitmapData;
            var xBitmapData11:BitmapData;
            var xcanvas2:Sprite;
            var xBGCOLOR:uint;
            var alpha:Number;
            var mat:Matrix;
            var bmpd:BitmapData;

            if(replayMode)
            {
                xBitmapData1 = rcanvas1BitmapData;
                xBitmapData11 = rcanvas11BitmapData;
                xcanvas2 = rcanvas2;
                xBGCOLOR = RCANVAS_BG_COLOR;
                alpha = tickDraw.getLineStyleAlpha();
            }
            else
            {
                xBitmapData1 = canvas1BitmapData;
                xBitmapData11 = canvas11BitmapData;
                xcanvas2 = canvas2;
                xBGCOLOR = CANVAS_BG_COLOR;
                alpha = 1.0;
            }

            if(clipRect !== null)
            {
                bmpd = new BitmapData(clipRect.width,clipRect.height,true,(captureTransparentBG) ? 0 : 0xFF000000|xBGCOLOR);
                mat = new Matrix();
                mat.translate(-clipRect.x,-clipRect.y);
            }
            else
            {
                bmpd = new BitmapData(xBitmapData1.width,xBitmapData1.height,true,(captureTransparentBG) ? 0 : 0xFF000000|xBGCOLOR);
            }

            if(layer2) bmpd.draw(xBitmapData11,mat); //레이어 쌓기

            if(isSubLayerONReplayMode()) //레이어 2번을 그리고 있을때
            {
                if(layer2) bmpd.draw(xcanvas2,mat,new ColorTransform(1,1,1,alpha));
                if(layer1) bmpd.draw(xBitmapData1,mat);
            }
            else //레이어 1번 그리고 있을때
            {
                if(layer1)
                {
                    bmpd.draw(xBitmapData1,mat);
                    bmpd.draw(xcanvas2,mat,new ColorTransform(1,1,1,alpha));
                }
            }

            return bmpd;
        }

        private function initCaptrueFlip():void
        {
            const xReg:Sprite = (replayModeON) ? rregPoint : regPoint;
            if(captureRotated === 1)
            {
                xReg.rotation = 90;
            }
            else if(captureRotated === 3)
            {
                xReg.rotation = 270;
            }
        }

        private function setCaptrueFlipButton(flag:Boolean):void
        {
            captureFlipped = flag;
            fitCanvasToWindow(true);

            const xReg:Sprite = (replayModeON) ? rregPoint : regPoint;

            if(captureRotated === 1)
            {
                captureRotated = 3;
                xReg.rotation = 270;
            }
            else if(captureRotated === 3)
            {
                captureRotated = 1;
                xReg.rotation = 90;
            }

            topBar.capClipBoard.alpha = 1.0;

            drawCaptureArea.updateDrawArea();
        }

        private function checkCaptureStampButtonAlpha():void
        {
            if(capStampON)
            {
                topBar.capStamp.alpha = 1.0;
                topBar.captureInputWarpper.visible = true;
                topBar.capStampFont.visible = true;
            }
            else
            {
                topBar.capStamp.alpha = BUTTON_OFF_ALPHA;
                topBar.captureInputWarpper.visible = false;
                topBar.capStampFont.visible = false;
            }
        }

        private function setCaptrueStampButton():void
        {
            topBar.capClipBoard.alpha = 1.0;
            capStampON = !capStampON;
            checkCaptureStampButtonAlpha();
            drawCaptureStamp.update();
        }

        private function setCaptureOFF():void
        {
            setFileBrowserONFlag(false);

            if(replayModeON) setCaptureModeOFF(true,rregPoint,rcanvasPanel);
            else setCaptureModeOFF(false,regPoint,canvasPanel);
        }

        private function setCaptureTransButton(flag:Boolean):void
        {
            captureTransBGON = flag;

            if(captureTransBGON) setTransBG(replayModeON);
            else resetTransBG(replayModeON);

            topBar.capClipBoard.alpha = 1.0;
        }

        private function setCaptureRotateButton(rotateValue:uint):void
        {
            //90도 시계 방향으로 회전
            //1: 90도 2:180 3:270
            if(rotateValue >= 4) rotateValue = 0;
            captureRotated = rotateValue;
            fitCanvasToWindow(true);
            topBar.capClipBoard.alpha = 1.0;

            drawCaptureArea.updateDrawArea();
            setDefaultHintCaptureMode();
        }

        //rotate hand zoom에서 쓰임
        private function resizeButtonVisible(flag:Boolean):void
        {
            penCursorOFFFlag = flag;
            resizeButtonR.visible = flag;
            resizeButtonL.visible = flag;
            resizeButtonD.visible = flag;
            resizeButtonU.visible = flag;
        }

        private function setResizeButtonVisible(flag:Boolean):void
        {
            if(resizeButtonR.visible === flag)
            {
                return;
            }

            if(flag)
            {
                updateResizeButtonPos(CANVAS_WIDTH,CANVAS_HEIGHT);
            }

            resizeButtonVisible(flag);
        }

        private function setResizeButtonVisibleTimer(flag:Boolean):void
        {
            if(flag)
            {
                updateResizeButtonPos(CANVAS_WIDTH,CANVAS_HEIGHT);
                addTimerByName("resizeButtonVisibleDelayTimer",0.9,false,function():void
                {
                    resizeButtonVisible(true);
                    setTransparentBGDrawModeON();
                });
            }
            else
            {
                removeTimer("resizeButtonVisibleDelayTimer");
                resizeButtonVisible(false);
                setTransparentBGDrawModeOFF();
            }
        }

        private function addInputEventReplayMode():void
        {
            if(isReplayModeInputEventON === false)
            {
                isReplayModeInputEventON = true;
                // resetKeyBuffer();
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownReplayMode,false,-1);
                stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownReplayMode,false,-1);
                stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownReplayMode,false,-1);
                stage.addEventListener(KeyboardEvent.KEY_UP,keyUpReplayMode,false,-1);
            }
        }

        private function removeInputEventReplayMode():void
        {
            isReplayModeInputEventON = false;
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownReplayMode);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownReplayMode);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownReplayMode);
            stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpReplayMode);
        }

        private function removeInputEventDrawMode():void
        {
            isDrawModeInputEventON = false;
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownDrawMode);
            stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpDrawMode);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownDrawMode);
            stage.removeEventListener(MouseEvent.MOUSE_UP,mouseUpDrawMode,false);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownDrawMode);
            // stage.removeEventListener(MouseEvent.MOUSE_OVER,lassoMenuHintONEvent);
        }

        private function addInputEventDrawMode():void
        {
            if(isDrawModeInputEventON === false)
            {
                isDrawModeInputEventON = true;
                // resetKeyBuffer();
                stage.addEventListener(KeyboardEvent.KEY_UP,keyUpDrawMode,false,-1);
                stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownDrawMode,false,-1);
                stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownDrawMode,false,-1);
                stage.addEventListener(MouseEvent.MOUSE_UP,mouseUpDrawMode,false,-1);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownDrawMode,false,-1);
            }
        }

        private function removeInputEventCaptrueMode():void
        {
            isCaptureModeInputEventON = false;
            stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpCaptureMode);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownCaptureMode);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownCaptureMode);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownCaptureMode);
            stage.removeEventListener(MouseEvent.MOUSE_OVER,mouseOverCaptureMode);
        }

        private function addInputEventCaptrueMode():void
        {
            if(isCaptureModeInputEventON === false)
            {
                isCaptureModeInputEventON = true;
                // resetKeyBuffer();
                stage.addEventListener(KeyboardEvent.KEY_UP,keyUpCaptureMode,false,-1);
                stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownCaptureMode,false,-1);
                stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownCaptureMode,false,-1);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownCaptureMode,false,-1);
                stage.addEventListener(MouseEvent.MOUSE_OVER,mouseOverCaptureMode,false,-1);
            }
        }

        private function removeInputEventToolBox2():void
        {
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,rightMouseUpToolBox2);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownToolBox2);
            addInputEventDrawMode();
        }

        private function addInputEventToolBox2():void
        {
            removeInputEventDrawMode();
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,rightMouseUpToolBox2,false,-2);
            stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownToolBox2,false,-2);
        }

        private function isLassoLayerHasSwapped():Boolean
        {
            if(lassoLayerCommand === null || (lassoLayerCommand && lassoLayerCommand.length === 0))
            {
                return false;
            }

            return lassoLayerCommand[lassoLayerCommand.length-1] === 0;
        }

        private function addLassoLayerMergeCommand(command:int):void
        {
            if(lassoLayerCommand === null)
            {
                lassoLayerCommand = [];
            }
            //0번 스왑명령, 1번 머지 명령
            if(command === 0)
            {
                if(lassoLayerCommand.length > 0 && lassoLayerCommand[lassoLayerCommand.length-1] === 0)
                {
                    lassoLayerCommand.pop();
                }
                else
                {
                    lassoLayerCommand.push(0);
                }
            }
            else if(lassoLayerCommand[lassoLayerCommand.length-1] !== command)
            {
                lassoLayerCommand.push(command);
            }
        }

        private function swapLassoImage():void
        {
            var tmpbmpd:BitmapData = lassoBMP.bitmapData;
            lassoBMP.bitmapData = lassoBMPsub.bitmapData;
            lassoBMPsub.bitmapData = tmpbmpd;
            tmpbmpd = null;
        }

        private function mergeLassoImage():void
        {
            var rect:Rectangle = new Rectangle(0,0,lassoBMP.bitmapData.width,lassoBMP.bitmapData.height);

            lassoBMPsub.bitmapData.draw(lassoBMP);
            lassoBMP.bitmapData.fillRect(rect,0);
            rect = null;
        }

        private function setLassoLayerMergeButton():void
        {
            lassoMenu.lassoLayerMerge.alpha = BUTTON_OFF_ALPHA;
            mergeLassoImage();
            addLassoLayerMergeCommand(1);
        }

        private function setLassoLayerSwapButton():void
        {
            if(lassoMenu.lassoLayerSwap.alpha < 1.0) return;

            lassoSwapButtonClicked = !lassoSwapButtonClicked;
            swapLassoImage();
            addLassoLayerMergeCommand(0);
            lassoMenu.hint(getLassoMenuHintSwapLayer());
            setLayerSwapEffect(lassoMenu.lassoLayerSwap);
        }

        private function setLassoCopyButton():void
        {
            if(lassoCopyON) return;

            lassoCopyON = true;
            lassoMenu["lassoCopy"].alpha = BUTTON_OFF_ALPHA;
            lassoCancelBmpd();
        }

        private function setLassoRotateButton():void
        {
            var getAngle:Function = cGetCanvasRotationAngle(lassoBox1);

            mouseDragON = true;
            lassoBMP.smoothing = false;
            lassoBMPsub.smoothing = false;

            function lassoRotateButtonUpEvent(e:MouseEvent):void
            {
                lassoBMP.smoothing = true;
                lassoBMPsub.smoothing = true;
                mouseDragON = false;
                getAngle = null;
                lassoMenu.visible = true;
                setRotateCursorOFF();

                stage.removeEventListener(MouseEvent.MOUSE_UP, lassoRotateButtonUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,lassoRotateButtonMoveEvent);
            }

            function lassoRotateButtonMoveEvent(e:MouseEvent):void
            {
                const angle:Number = getAngle(false);

                lassoBox1.rotation = angle;
                lassoBox2.rotation = angle;
            }

            lassoMenu.visible = false;
            stage.addEventListener(MouseEvent.MOUSE_MOVE, lassoRotateButtonMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,lassoRotateButtonUpEvent);
        }

        private function setLassoResizeButton():void
        {
            const mirrorScale:Number = (lassoBox1.scaleX < 0) ? -1.0 : 1.0;
            var getScale:Function = cImageResizeFunc(lassoBox1.scaleX);

            mouseDragON = true;
            lassoBMP.smoothing = false;
            lassoBMPsub.smoothing = false;

            function lassoResizeButtonUpEvent(e:MouseEvent):void
            {
                lassoBMP.smoothing = true;
                lassoBMPsub.smoothing = true;
                mouseDragON = false
                getScale = null;

                checkLassoMenuPos();
                lassoMenu.visible = true;
                setToolTipOFF();

                stage.removeEventListener(MouseEvent.MOUSE_UP,lassoResizeButtonUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,lassoResizeButtonMoveEvent);
            }

            function lassoResizeButtonMoveEvent(e:MouseEvent):void
            {
                const scale:Number = getScale(mouseX,mouseY);
                lassoBox1.scaleX = scale*mirrorScale;
                lassoBox1.scaleY = scale;
                lassoBox2.scaleX = lassoBox1.scaleX;
                lassoBox2.scaleY = lassoBox1.scaleY;

                setToolTipString(getImageScaleHint(lassoBox1.width,lassoBox1.height,Math.abs(lassoBox1.scaleX),false));
            }

            setToolTipString(getImageScaleHint(lassoBox1.width,lassoBox1.height,Math.abs(lassoBox1.scaleX),false));
            setToolTipON();
            lassoMenu.visible = false;
            stage.addEventListener(MouseEvent.MOUSE_UP,lassoResizeButtonUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, lassoResizeButtonMoveEvent);
        }

        private function isLassoUsed():Boolean
        {
            if(lassoCopyON
            || lassoStartData[0] !== lassoBox1.x
            || lassoStartData[1] !== lassoBox1.y
            || lassoStartData[2] !== lassoBox1.scaleX
            || lassoStartData[3] !== lassoBox1.scaleY
            || lassoStartData[4] !== lassoBox1.rotation
            || (lassoLayerCommand && lassoLayerCommand.length > 0))
            {
                return true;
            }
            return false;
        }

        private function setLassoMoveButton():void
        {
            var getMovedPos:Function = cImageMoveFunc(lassoBox1,regPoint.rotation);
            mouseDragON = true;
            lassoBMP.smoothing = false;
            lassoBMPsub.smoothing = false;

            function lassoMoveButtonUpEvent(e:MouseEvent):void
            {
                mouseDragON = false;
                lassoBMP.smoothing = true;
                lassoBMPsub.smoothing = true;
                lassoMenu.visible = true;
                checkLassoMenuPos();
                stage.removeEventListener(MouseEvent.MOUSE_UP,lassoMoveButtonUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,lassoMoveButtonMoveEvent);
            }

            function lassoMoveButtonMoveEvent(e:MouseEvent):void
            {
                const pos:Point = getMovedPos();

                lassoBox1.x = Math.round(pos.x);
                lassoBox1.y = Math.round(pos.y);
                lassoBox2.x = lassoBox1.x;
                lassoBox2.y = lassoBox1.y;
            }

            lassoMenu.visible = false;
            stage.addEventListener(MouseEvent.MOUSE_UP,lassoMoveButtonUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, lassoMoveButtonMoveEvent);
        }

        private function setPenSize(index:uint):void
        {
            const size:uint = penSizeList[index];

            if(isNowToolPenOrLine() || isNowTool(TOOL_FILL_PEN))
            {
                penSize = size;
                penSizeIndex = index;
                penCursorPosition.updateCursorSize(penSize);
            }
            else if(isNowTool(TOOL_ERASE))
            {
                eraseSize = size;
                eraseSizeIndex = index;
                penCursorPosition.updateCursorSize(eraseSize);
            }
            controlBox.movePenSizeCursor(index);
        }

        private function setRGBInfoBorderColor(color:uint):uint
        {
            const defColor:Number = getColorDifferenceForHuman(color,uiColorSet[uiColorIndex][0]);
            return (defColor <= 15) ? uiColorSet[uiColorIndex][1] : 0;
        }

        private function isCurrentColorSamePickedColor():Boolean
        {
            return pickerBox.getRGBInfoBGColor() === pickerBox.getCurrentColor();
        }

        private function updatePickerCurrentColor(color:uint):void
        {
            pickerBox.updateCurrentColor(color,setRGBInfoBorderColor(color));
        }

        private function checkAutoSwitchIsPickerModeToPenEvent(e:Event):void
        {
            if(!mouseClickON && (!sideBar.visible || !pickerBox.hitTestPoint(mouseX,mouseY)))
            {
                stage.removeEventListener(Event.ENTER_FRAME,checkAutoSwitchIsPickerModeToPenEvent);
                pickerModeResetFlag = false;
                changePickerModeToPenColor();
            }
        }

        private function checkAutoSwitchIsPickerModeToPen():void
        {
            if(pickerModeResetFlag === false)
            {
                pickerModeResetFlag = true;
                stage.addEventListener(Event.ENTER_FRAME,checkAutoSwitchIsPickerModeToPenEvent);
            }
        }

        private function changePickerModeToPaperColor():void
        {
            const color:uint = CANVAS_BG_COLOR;

            pickerMode = 2;

            setHSVCursorPosByColor((rgbInfoColorTypeHSV) ? HEXtoHSV(color) : color);
            updatePickerCurrentColor(color);
            pickerBox.checkPickerModeButton(2);
            pickerBox.transColorButton.visible = false;
            penColorTransparentFlag = false;

            checkAutoSwitchIsPickerModeToPen();
        }

        private function changePickerModeToPenColor():void
        {
            const color:uint = penColor;

            pickerMode = 1;

            setHSVCursorPosByColor((rgbInfoColorTypeHSV) ? HEXtoHSV(color) : color);
            updatePickerCurrentColor(color);
            pickerBox.checkPickerModeButton(1);
            pickerBox.transColorButton.visible = true;
            penColorTransparentFlag = false;
        }

        private function setPenShapeButton(shapeFlag:Boolean):void
        {
            penListShapeFlag = shapeFlag;


            if(isNowToolPenOrLine())
            {
                if(penShape !== shapeFlag)
                {
                    penShape = shapeFlag;
                }
            }
            else if(isNowTool(TOOL_ERASE))
            {
                if(eraseShape !== shapeFlag)
                {
                    eraseShape = shapeFlag;
                }
            }

            controlBox.shapeFlag(shapeFlag);
            updatePenSizeCursor();
        }

        private function updatePenColor(color:uint):void
        {
            penColor = color;
            updateOpacityCursorPos(penAlphaIndex);
        }

        private function isBackgroundColorMode():Boolean
        {
            return pickerMode === 2 && fillPenStarted === false;
        }

        private function isPenColorMode():Boolean
        {
            return pickerMode === 1;
        }

        private function setHueColorButton():void
        {
            const offsetX:Number = pickerBox["offsetX"];
            const max:Number = pickerBox["svBoxWidth"];
            var pickedColor:uint = 0;

            setTopChildIndex(pickerBox["hueCursor"]);
            mouseDragON = true;
            penCursorOFFFlag = true;
            penColorTransparentFlag = false;

            function hueMoveStart(mx:Number):void
            {
                var hueCursorX:Number = mx;

                if(hueCursorX < 0) hueCursorX = 0;
                else if(hueCursorX > max) hueCursorX = max;

                pickerBox["hueCursor"].x = hueCursorX;

                const hueValue:Number = hueCursorX/max;
                const baseColor:Vector.<uint> = HSVtoRGB(hueValue,1.0,1.0);
                const baseHexColor:uint = RGBtoHEX(baseColor[0],baseColor[1],baseColor[2]);
                const color:uint = updatePickerBoxInfoColor(hueValue,hsvColorArr[1],hsvColorArr[2]);

                pickedColor = color;
                pickerBox.changeHueColor(baseHexColor);
                pickerBox.updateRGBInfoBG(color,setRGBInfoBorderColor(color),myPalettePresetType);
            }

            function hueColorButtonMoveEvent(e:MouseEvent):void
            {
                hueMoveStart(pickerBox["hueColor"].mouseX);
            }

            function hueColorButtonUpEvent(e:MouseEvent):void
            {
                hueMoveStart(pickerBox["hueColor"].mouseX);

                if(isPenColorMode())
                {
                    updatePenColor(pickedColor);
                }
                else if(isBackgroundColorMode())
                {
                    setBackgroundColorDrawMode(pickedColor);
                    if(canvasWindowON) updateCanvasWindowCanvasPanelBGColor(CANVAS_BG_COLOR,canvasWindowBitmap.bitmapData);
                    addUndoBGColor(pickedColor);
                }

                mouseDragON = false;
                penCursorOFFFlag = false;

                updateRGBInfoTextByColor((rgbInfoColorTypeHSV) ? HEXtoHSV(pickedColor) : pickedColor);
                pickerBox.setRGBInfoVisible(true);

                setNowToolForDrawing(false);
                //timer로 동작하는 경우 마지막 커서위치에 안가있을수도 있기 때문에 up에서도 해줌
                stage.removeEventListener(MouseEvent.MOUSE_UP,hueColorButtonUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,hueColorButtonMoveEvent);
            }

            pickerBox.setRGBInfoVisible(false);
            hueMoveStart(pickerBox["hueColor"].mouseX);
            stage.addEventListener(MouseEvent.MOUSE_UP,hueColorButtonUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, hueColorButtonMoveEvent);
        }

        private function updatePickerBoxInfoColor(h:Number,s:Number,v:Number):uint
        {
            const rgbColor:Vector.<uint> = HSVtoRGB(h,s,v);
            const r:uint = rgbColor[0];
            const g:uint = rgbColor[1];
            const b:uint = rgbColor[2];
            const rgbHexColor:uint = RGBtoHEX(r,g,b);
            const invColor:uint = getInvertColor(rgbHexColor,1.0
                                                ,(uiColorIndex >= 2) ? uiColorSet[uiColorIndex][0]:uiColorSet[uiColorIndex][1]
                                                ,(uiColorIndex >= 2) ? uiColorSet[uiColorIndex][1]:uiColorSet[uiColorIndex][0]);
            hsvColorArr[0] = h;
            hsvColorArr[1] = s;
            hsvColorArr[2] = v;

            return rgbHexColor;
        }

        private function setSVcolorButton():void
        {
            const colorBarWidth:Number = pickerBox["svBoxWidth"];
            const colorBarHeight:Number = pickerBox["svBoxHeight"];
            var pickedColor:uint = 0;

            setTopChildIndex(pickerBox["svCursor"]);
            mouseDragON = true;
            penCursorOFFFlag = true;
            penColorTransparentFlag = false;

            function setSVBoxMouseMoveEvent(mx:Number,my:Number):void
            {
                var svCursorX:Number = mx;
                var svCursorY:Number = my;

                if(svCursorX < 0) svCursorX = 0;
                else if(svCursorX > colorBarWidth) svCursorX = colorBarWidth;

                if(svCursorY < 0) svCursorY = 0;
                else if(svCursorY > colorBarHeight) svCursorY = colorBarHeight;

                pickerBox["svCursor"].x = svCursorX;
                pickerBox["svCursor"].y = svCursorY;

                const hueValue:Number = hsvColorArr[0];
                const sValue:Number = svCursorX/colorBarWidth;
                const vValue:Number = 1-(svCursorY/colorBarHeight);
                const color:uint = updatePickerBoxInfoColor(hueValue,sValue,vValue);

                pickedColor = color;
                pickerBox.updateRGBInfoBG(color,setRGBInfoBorderColor(color),myPalettePresetType);
                pickerBox.setRGBInfoVisible(false);
            }

            function svColorButtonMoveEvent(e:MouseEvent):void
            {
                setSVBoxMouseMoveEvent(pickerBox["svBox"].mouseX,pickerBox["svBox"].mouseY);
            }

            function svColorButtonUpEvent(e:MouseEvent):void
            {
                setSVBoxMouseMoveEvent(pickerBox["svBox"].mouseX,pickerBox["svBox"].mouseY);

                if(isPenColorMode())
                {
                    penColor = pickedColor;
                    updateOpacityCursorPos(penAlphaIndex);
                }
                else if(isBackgroundColorMode())
                {
                    setBackgroundColorDrawMode(pickedColor);
                    if(canvasWindowON) updateCanvasWindowCanvasPanelBGColor(CANVAS_BG_COLOR,canvasWindowBitmap.bitmapData);
                    addUndoBGColor(pickedColor);
                }

                mouseDragON = false;
                penCursorOFFFlag = false;

                updateRGBInfoTextByColor((rgbInfoColorTypeHSV) ? HEXtoHSV(pickedColor) : pickedColor);
                pickerBox.setRGBInfoVisible(true);
                setNowToolForDrawing(false);

                stage.removeEventListener(MouseEvent.MOUSE_UP,svColorButtonUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,svColorButtonMoveEvent);
            }

            pickerBox.setRGBInfoVisible(false);
            setSVBoxMouseMoveEvent(pickerBox["svBox"].mouseX,pickerBox["svBox"].mouseY);

            stage.addEventListener(MouseEvent.MOUSE_UP,svColorButtonUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, svColorButtonMoveEvent);
        }

        //단축키를  after tool mouse up에서 이전툴을 복구해줌
        private function setNowToolByOldTool():void
        {
            const oldToolSave:int = oldTool;

            if(oldToolSave === TOOL_NONE)
            {
                selectPenTool();
                updatePenSizeCursor();
                return;
            }

            switch (oldToolSave)
            {
                case TOOL_PEN:
                    selectPenTool();
                    updatePenSizeCursor();
                break;

                // case TOOL_SCAN_FILL:
                //     selectScanFillTool();
                // break;

                case TOOL_FILL_PEN:
                    selectFillPenTool();
                break;

                case TOOL_ERASE:
                    selectEraseTool();
                    updatePenSizeCursor();
                break;

                case TOOL_LINE:
                    selectLineTool();
                    updatePenSizeCursor();
                break;

                case TOOL_SPUIT:spuitTool(); break;
                case TOOL_LASSO:selectLassoTool(); break;
                case TOOL_MOVE:selectMoveTool(); break;
                case TOOL_ROTATE:selectRotateTool(); break;
                case TOOL_ZOOM:selectZoomTool(); break;
            }

            nowTool = oldToolSave;

            resetOldTool();
        }

        //VERSION변수를 문자열로 변환, 변환할때 뒤에 .0이 붙었는지 까지 체크
        private function convertVersionString(version:Number):String
        {
            var verStr:String = version.toString();

            if(verStr.indexOf(".") === -1) verStr = verStr + ".0";

            return verStr;
        }

        private function setIMEEnabled():void
        {
            IME.enabled = true;
        }

        private function setIMEDisabled():void
        {
            if(capInputFocusFlag)
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
        private function parseVersion(str:String):Number
        {
            return parseFloat(str);
        }

        private function isNewVersion(newVer:Array):Boolean
        {
            const oldVer:Array = (APP_VERSION.toFixed(2)).split(".");

            //앞 버전이 크면 참
            if(parseFloat(newVer[0]) > parseFloat(oldVer[0])
            ||
            (parseFloat(newVer[0]) === parseFloat(oldVer[0])
            && parseFloat(newVer[1]) > parseFloat(oldVer[1])))
            {
                return true;
            }

            return false;
        }

        private function checkVersion():void
        {
            if(isCheckingUpdate)
            {
                return;
            }

            isCheckingUpdate = true;

            var versionInfo:URLRequest = new URLRequest("https://raw.githubusercontent.com/guljam/2020FlashPaint/master/versionInfo.txt");
            var loader:URLLoader = new URLLoader();

            if(versionInfo.useCache)
            {
                versionInfo.useCache = false;
            }

            loader.addEventListener(Event.COMPLETE,getCurrentVersionComplete);
            loader.addEventListener(IOErrorEvent.IO_ERROR, getCurrentVersionFail);
            loader.load(versionInfo);

            function getCurrentVersionFail(e:IOErrorEvent):void
            {
                isCheckingUpdate = false;
                loader.removeEventListener(Event.COMPLETE,getCurrentVersionComplete);
                loader.removeEventListener(IOErrorEvent.IO_ERROR, getCurrentVersionFail);
                loader = null;
            }

            function getCurrentVersionComplete(e:Event):void
            {
                const versionStr:String = loader.data;
                if(!versionStr) return;

                const getVersionArr:Array = versionStr.split(".");

                if(getVersionArr.length >= 2)
                {
                    if(parseVersion(getVersionArr[0]) || parseVersion(getVersionArr[1]))
                    {
                        var tryCount:uint = 0;

                        const updateFile:URLRequest = new URLRequest("https://github.com/guljam/2020FlashPaint/releases/download/update2/fofoPaint.air");
                        if(isNewVersion(getVersionArr))
                        {
                            NEW_VERSION = versionStr;
                            var fileLoader:URLLoader = e.target as URLLoader;

                            fileLoader.dataFormat = URLLoaderDataFormat.BINARY;
                            fileLoader.addEventListener(Event.COMPLETE,downloadSuccessEvent);
                            fileLoader.addEventListener(IOErrorEvent.IO_ERROR,downloadFailedEvent);

                            function setDownloadText(updateFlag:int):void
                            {
                                fileLoader.removeEventListener(Event.COMPLETE,downloadSuccessEvent);
                                fileLoader.removeEventListener(IOErrorEvent.IO_ERROR,downloadFailedEvent);

                                needUpdate = updateFlag;
                                topBar.updateButtonVisible(true);
                                isCheckingUpdate = false;
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
                                else setDownloadText(2);
                            }

                            function downloadSuccessEvent(e:Event):void
                            {
                                var fs:FileStream = new FileStream();
                                fs.open(UPDATE_FILE,FileMode.WRITE);
                                fs.writeBytes(fileLoader.data);
                                fs.close();
                                setDownloadText(1);
                            }

                            if(Updater.isSupported)
                                fileLoader.load(updateFile); //다운로드를 시작함
                            else
                                setDownloadText(2);
                        }
                        else
                        {
                            isCheckingUpdate = false;
                            //최신 버전이면 이미 다운로드한 파일 있는지 체크하고 제거
                            if(UPDATE_FILE.exists)
                                UPDATE_FILE.deleteFile();
                        }
                    }
                }
                else
                {
                    isCheckingUpdate = false;
                }
                loader.removeEventListener(Event.COMPLETE,getCurrentVersionComplete);
                loader.removeEventListener(IOErrorEvent.IO_ERROR, getCurrentVersionFail);
                loader = null;
            }
        }

        private function closeAboutPanel():void
        {
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,aboutOFFMouseDownEvent);
            removeInputEventCaptrueMode();
            removeInputEventReplayMode();
            addInputEventDrawMode();
            aboutPanelON = false;
            aboutPanel.visible = false;
            addTimerByName("clickBlockTimer",0.15,false,function():void
            {
                clickBlockOnWindowActiveFlag = false;
            });
        }

        private function aboutOFFMouseDownEvent(e:MouseEvent):void
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
                    checkButtonUp(targetName);
                break;

                default:
                    closeAboutPanel();
                break;
            }
        }

        private function setAboutPanelCenterPos():void
        {
            aboutPanel.x = Math.floor(stage.stageWidth/2)+Math.floor(-aboutPanel.width/2);
            aboutPanel.y = Math.floor((stage.stageHeight-39)/2)+Math.floor(-aboutPanel.height/2);
        }

        private function openAboutPanel(welcome:Boolean):void
        {
            setTopChildIndex(aboutPanel);
            aboutPanelON = true;
            clickBlockOnWindowActiveFlag = true;
            hint.off();
            removeInputEventDrawMode();

            if(welcome === true)
            {
                aboutPanel.resetAppButton.visible = false;
                addTimerByName("openAboutPanelOFFTimer",1.0,false,function():void
                {
                    stage.addEventListener(MouseEvent.MOUSE_DOWN,aboutOFFMouseDownEvent);
                });
            }
            else
            {
                removeInputEventDrawMode();
                aboutPanel.resetAppButton.visible = true;
                checkVersion();
                stage.addEventListener(MouseEvent.MOUSE_DOWN,aboutOFFMouseDownEvent);
            }

            aboutPanel.randomLogo();
            aboutPanel.updateMemoryInfo(getDriveUsageString());
            setAboutPanelCenterPos();
            aboutPanel.visible = true;
        }

        private function clearDataResetVars():void
        {
            rBGColorSave = CANVAS_BG_COLOR;
            saveContinue = false;
            rMirrorON = false;
            mirrorON = false;
            mirrorCommandReady = false;
            rDataReadFlag = false;
            undoData.setRFileTotalFrame(0);
            TOTAL_FRAME = 0;
            makeJumpImageFlag = 0;
            layerSwappedFlag = false;

            resetTraceImageInfo();
            resetTraceOpa();
            initReplayDataFile(true);
            resetReplaySpeedBar();
            resetReplayTime();
            resetUndo();
            resetCaptureCanvasChangeValue();

            const fileName:String = getNewFileName();
            const name:String = saveFileName;
            const path:String = saveFilePath;
            const newName:String = name.substr(0,name.lastIndexOf(name))+fileName;
            const newPath:String = path.substr(0,path.lastIndexOf(name))+fileName;

            saveFileName = newName;
            saveFilePath = newPath;

            appInfoBox.setMirror(false);
            updateWindowTitle();
            cancelAutoKeyEvent(null);
        }

        private function setReRecordCopyCanvas():void
        {
            const lineStyleSave:Array = tickDraw.getrLineStyleSave();
            // if(!lineStyleSave) return;
            var newColorTransform:ColorTransform = new ColorTransform(1,1,1,lineStyleSave[0]);

            rcanvas2BitmapData.draw(rcanvas2Draw);
            rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;

            if(isSubLayerONReplayMode())
            {
                rcanvas11BitmapData.draw(rcanvas2Bitmap,null,newColorTransform,lineStyleSave[1]);
            }
            else
            {
                rcanvas1BitmapData.draw(rcanvas2Bitmap,null,newColorTransform,lineStyleSave[1]);
            }

            //캔버스 2번 지워줘야함
            rcanvas2Draw.graphics.clear();
            rcanvas2BitmapData.fillRect(new Rectangle(0,0,rcanvas2BitmapData.width,rcanvas2BitmapData.height),0);

            if(canvas1BitmapData && canvas1BitmapData !== rcanvas1BitmapData) canvas1BitmapData.dispose();
            canvas1BitmapData = rcanvas1BitmapData.clone();
            canvas1Bitmap.bitmapData = canvas1BitmapData;

            if(canvas11BitmapData && canvas11BitmapData !== rcanvas11BitmapData) canvas11BitmapData.dispose();
            canvas11BitmapData = rcanvas11BitmapData.clone();
            canvas11Bitmap.bitmapData = canvas11BitmapData;

            changeCanvasSize(canvas1Bitmap.width,canvas1Bitmap.height);
            setBackgroundColorDrawMode(RCANVAS_BG_COLOR);
            previewBox.updateImage(canvas1BitmapData,canvas11BitmapData,CANVAS_BG_COLOR);

            if(canvasWindowON)
            {
                updateCanvasWindowImage();
                updateCanvasWindowBitmapSize();
            }
        }

        private function clearData():void
        {
            clearCanvas();
            clearCanvasReplayMode();
            clearDataResetVars();
            setWindowTitleStar();
            tickDraw.resetFirstRCursorPos();
            clearRFrameCacheImages();
            //reset vars보다 뒤에 와야함
            //addundo에서 활성화 해주고 있기 때문에
            topBar.clearButton.alpha = BUTTON_OFF_ALPHA;
        }

        private function setClearData(keyFlag:Boolean):void
        {
            setCountDownLongKey((!keyFlag)?topBar.clearButton:null,"Creating new file.. ",null,clearData,null);
        }

        private function checkButtonUp(targetName:String):void
        {
            if(aboutPanelON)
            {
                function aboutButtonUpEvent(e:MouseEvent):void
                {
                    stage.removeEventListener(MouseEvent.MOUSE_UP,aboutButtonUpEvent);
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
                                closeAboutPanel();
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
                                closeAboutPanel();
                            break;
                        }
                    }
                }
                stage.addEventListener(MouseEvent.MOUSE_UP,aboutButtonUpEvent);
                return;
            }

            function buttonUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, buttonUpEvent);

                const upTargetName:String = e.target.name;

                if(targetName === upTargetName)
                {
                    switch(upTargetName)
                    {
                        case "drawModeButton":
                        {
                            setReplayModeOFF();
                        }
                        break;

                        case "replayModeButton":
                        {
                            setReplayModeON();
                            mouseClickON = false; //리플레이 버튼 누르고 나서 단축키가 안먹는 현상이 이거임
                        }
                        break;

                        case "capLayer1VisibleButton":
                        {
                            setLayer1CheckToggleCaptureMode();
                        }
                        break;

                        case "capLayer2VisibleButton":
                        {
                            setLayer2CheckToggleCaptureMode();
                        }
                        break;

                        case "dpiButton":
                            setUIScaleButton(++uiScaleIndex);
                        break;

                        case "updateButton":
                        {
                            setUpdateButton();
                        }
                        break;

                        case "sideBarPositionButton":
                        case "sideBarPositionButton2":
                            setSideBarPositionButton();
                        break;

                        case "sideBarOFFButton":
                        case "sideBarOFFButton2":
                            setSidebarVisible(false,false);
                        break;

                        case "sideBarONButton":
                        case "sideBarONButton2":
                            setSidebarVisible(true,false);
                        break;

                        case "traceLoadButton":
                            loadFile(true);
                        break;

                        case "saveButton":
                        case "repSaveButton":
                            saveFile(false);
                        break;

                        case "loadButton":
                        case "repLoadButton":
                            loadFile();
                        break;

                        case "clipButton":
                            setClipboardButton(false);
                        break;

                        case "repCaptureButton":
                        case "captureButton":
                            setCaptureModeON();
                        break;

                        case "capRotate":
                            setCaptureRotateButton(++captureRotated);
                        break;

                        case "capTrans":
                            setCaptureTransButton(!captureTransBGON);
                        break;

                        case "capClipBoard":
                            copyCaptureImageToCilpBoard();
                        break;

                        case "capFull":
                            saveCaptureImage();
                        break;

                        case "capOff":
                            setCaptureOFF();
                        break;

                        case "capFlip":
                            setCaptrueFlipButton(!captureFlipped);
                        break;

                        case "capStamp":
                            setCaptrueStampButton();
                        break;

                        case "capStampFont":
                            setCaptureStampFontBoxVisbleON();
                        break;

                        case "capFontListPrev":
                            capStampFontListBox.updateNextFontList(false);
                        break;

                        case "capFontListNext":
                            capStampFontListBox.updateNextFontList(true);
                        break;

                        case "topBarColorButton":
                            setUIColorButton();
                        break;

                        case "gridButton":
                            gridButton.start(false);
                        break;

                        case "aboutButton":
                            openAboutPanel(false);
                        break;

                        case "newWindowCloseButton":
                            closeCanvasWindowTemp()
                        break;

                        case "newWindowButton":
                            openImageViewWindow();
                        break;

                        case "replayZoomInButton":
                            setZoomInButton(true,true);
                        break;

                        case "replayZoomOutButton":
                            setZoomInButton(false,true);
                        break;

                        case "replayRepeatButton":
                        {
                            setReplayRepeatButton();
                        }
                        break;

                        case "traceCancelButton":
                        {
                            setTopChildIndex(traceMenu);
                            closeTraceMenu();
                        }
                        break;

                        case "traceImageButton":
                        {
                            setTraceImageButton();
                        }
                        break;

                        case "traceClipButton":
                        {
                            if(traceMenu.traceClipButton.alpha === 1.0)
                            {
                                setClipboardButton(true);
                            }
                        }
                        break;

                        case "traceMirrorButton":
                        {
                            setTopChildIndex(traceMenu);
                            setTraceMirrorButton();
                        }
                        break;

                        case "traceVisibleONButton":
                        case "traceVisibleOFFButton":
                        {
                            setTopChildIndex(traceMenu);
                            setTraceVisibleButton();
                        }
                        break;

                        case "playButton":
                            startReplay();
                        break;

                        case "pauseButton":
                            stopReplay();
                        break;

                        case "lassoTrace":
                            setLassoTraceImageButton();
                        break;

                        case "lassoOK":
                            setLassoOKButton();
                        break;

                        case "lassoCancel":
                        {
                            if(lassoToolON === true)
                            {
                                setLassoCancelButton();
                            }
                        }
                        break;

                        case "lassoLayerMerge":
                        {
                            if(lassoMenu.lassoLayerMerge.alpha === 1.0)
                            {
                                setLassoLayerMergeButton();
                            }
                        }
                        break;

                        case "lassoLayerSwap":
                        {
                            if(lassoMenu.lassoLayerSwap.alpha === 1.0)
                            {
                                setLassoLayerSwapButton();
                            }
                        }
                        break;

                        case "lasso1pxUp": setLasso1PxMoveButton(LASSO_1PX_MOVE_UP); break;
                        case "lasso1pxDown": setLasso1PxMoveButton(LASSO_1PX_MOVE_DOWN); break;
                        case "lasso1pxLeft": setLasso1PxMoveButton(LASSO_1PX_MOVE_LEFT); break;
                        case "lasso1pxRight": setLasso1PxMoveButton(LASSO_1PX_MOVE_RIGHT); break;
                        case "lassoCopy": setLassoCopyButton(); break;

                        case "lassoMirror":
                        {
                            lassoMirrorON = !lassoMirrorON;
                            lassoBox1.scaleX = -lassoBox1.scaleX;
                            lassoBox2.scaleX = lassoBox1.scaleX;

                            //캔버스가 회전한각도도 있어서 항상 세로축을 중심으로 대칭되게 regpoint각도를 보정값으로 넣어줌
                            lassoBox1.rotation = -lassoBox1.rotation-(regPoint.rotation*2);
                            lassoBox2.rotation = lassoBox1.rotation;
                        }
                        break;


                        case "replayFitToWindowButton":
                        {
                            if(rFitZoomedON) resetZoomReplayMode();
                            else setReplayFitToWindowButton();
                        }
                        break;

                        case "layerMergeButton":
                        {
                            setLayerMergeButton();
                            setHintONTemp("Layers has been merged to layer 2");
                        }
                        break;

                        case "layerSwapButton":
                        {
                            setLayerSwapButton();
                            setHintONTemp(getLayerSwappedHint());
                        }
                        break;

                        default:
                        break;
                    }
                }
            }
            stage.addEventListener(MouseEvent.MOUSE_UP,buttonUpEvent);
        }

        private function setCanvasSameReplayCanvas():void
        {
            zoomed = rzoomed;
            zoomedIndex = rzoomedIndex;
            regPoint.x = Math.floor(rregPoint.x); //뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
            regPoint.y = Math.floor(rregPoint.y);
            regPoint.scaleX = rregPoint.scaleX;
            regPoint.scaleY = rregPoint.scaleY;
            regPoint.rotation = rregPoint.rotation;
            canvasPanel.x = Math.floor(rcanvasPanel.x);
            canvasPanel.y = Math.floor(rcanvasPanel.y);
            setRcursorRotation(rregPoint.rotation);
        }

        private function setReplayDeleteBarVisibleOFF():void
        {
            replayTimeBox["replayDeleteBar"].visible = false;
            replayTimeBox["replayNowBar"].visible = true;
        }

        private function ensureReplayCanvasState():void
        {
            const rNowFrameBackup:Number = rNowFrame;
            jumpFrame(0,JUMP_FRAME_ONCE);
            jumpFrame(rNowFrameBackup,JUMP_FRAME_ONCE);
            mirrorON = rMirrorON;
            mirrorCommandReady = false;
            appInfoBox.setMirror(rMirrorON);
        }

        private function deleteReplayFrontData():void
        {
            //미러 되어있을 수도 있기 때문에 워래 프레임 으로 점프해준뒤에 실행해줌
            ensureReplayCanvasState();

            setReplayDeleteBarVisibleOFF();
            //첫 이미지 새로 만들어줌
            if(rJumpImageFolder.exists)
            {
                rJumpImageFolder.deleteDirectory(true);
            }

            rJumpImageFolder.createDirectory();

            makeFirstReplayImage(rcanvas1BitmapData,rcanvas11BitmapData,RCANVAS_BG_COLOR);

            const fs:FileStream = new FileStream();

            if(rDataReadFlag === true)
            {
                //repfile 초기화
                undoData.setUndoRefImageByReplayMode();
                fs.open(repFile,FileMode.WRITE); //파일 생성
                fs.close();

                saveOneTime = false;
                setClearButtonActive();
                undoData.setRFileTotalFrame(0);

                rData.splice(0,rIndex+1);
                rDataFrame.splice(0,rIndex+1);

                TOTAL_FRAME = getTotalFrame();
                // resetReplayTime();
                replayTimeBox["frameInfo"].text = TOTAL_FRAME+" / " + TOTAL_FRAME;
                replayTimeBox["replayNowBar"].width = (TOTAL_FRAME === 0) ? 0 : replayTimeBox["replayTotalBar"].width;
                topBar["reRecordingButton"].alpha = BUTTON_OFF_ALPHA;

                rCursor.visible = false;
            }
            else if(rDataReadFlag === false)
            {
                //make jumpimage에서 변경해주기 때문에
                if(repFileTemp.exists)//이미 있으면 지워주고
                {
                    repFileTemp.deleteFile();
                }
                var ba:ByteArray = new ByteArray();
                var d:Array;

                //짤라서 ba에 넣어주기
                fs.open(repFile,FileMode.READ);
                fs.position = rLastBytePosition;
                fs.readBytes(ba,0,fs.bytesAvailable);
                fs.close();

                //ba에 넣어준걸 다시 써주기
                fs.open(repFile,FileMode.WRITE);
                fs.position = 0;
                fs.writeBytes(ba,0,ba.length);
                fs.close();

                ba.clear();
                ba = null;

                rCursor.visible = false;
                replayTimeBox["replayNowBar"].width = 0;
                saveOneTime = false;
                setMakeJumpImage();
            }

            resetReplaySpeedBar();
            playbackFinished = true;

            if(undoIndex > rData.length-1)
            {
                undoIndex = rData.length-1;
            }

            undoToIndex(undoIndex);
            setDeepUndoOFF();
            checkReplaySpeedState();
            tickDraw.setFirstRCursorPosCurrent();
        }

        private function setReRecord():void
        {
            setReplayDeleteBarVisibleOFF();
            setReRecordCopyCanvas();
            clearDataResetVars();
            setCanvasSameReplayCanvas();

            if(replayModeON)
            {
                setDeepUndoFrameSave(rNowFrame);
                setReplayModeOFF();
            }

            setDeepUndoOFF();
            resetReplayTime();
        }

        //addundo data에서 캔버스 비트맵 데이터가 변경되기 전, rdatabuffer 비어있을때 넣어줘야함
        private function setApplyDeepUndo():void
        {
            const fs:FileStream = new FileStream();

            fs.open(repFile,FileMode.UPDATE);
            fs.position = rLastBytePosition;
            fs.truncate(); //데이터 위에 짤라주고
            fs.close();

            //썸네일 이미지도 날려줌
            const rNowFrameSave:Number = rNowFrame;
            const list:Array = rJumpImageFolder.getDirectoryListing();
            const index:Number = getJumpImageIndex(rNowFrameSave);
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
            undoData.setRFileTotalFrame(rNowFrameSave);
            TOTAL_FRAME = rNowFrameSave;

            resetReplayTime();
            resetUndo(true);
            rCursor.visible = true;//대칭된 커서 위치를 갱신해주려고 임시로 켜줌
            // checkMirrorCanvasReplayMirror();
            appInfoBox.setMirror(mirrorON);
            tickDraw.setFirstRCursorPosCurrent();
            rCursor.visible = false;

            previewBox.updateImage(canvas1BitmapData,canvas11BitmapData,CANVAS_BG_COLOR);

            if(canvasWindowON)
            {
                updateCanvasWindowImage();
                updateCanvasWindowBitmapSize();
            }
            // saveContinue = false;
            setDeepUndoOFF();
        }

        private function superUndo():void
        {
            ensureReplayCanvasState();
            setReplayDeleteBarVisibleOFF();

            if(rDataReadFlag === true)
            {
                //위에서 setJumpOneFrame을 해줘서 rindex가 증가되었기 때문에
                //실제 undo해줘야할 인덱스는 -1해줘야하는거임
                undoToIndex(rIndex);
                rData.splice(rIndex+1);
                rDataFrame.splice(rIndex+1);

                TOTAL_FRAME = getTotalFrame();
                resetReplayTime();
            }
            else if(rDataReadFlag === false)
            {
                tickDraw.setFirstRCursorPosCurrent();
                const fs:FileStream = new FileStream();

                fs.open(repFile,FileMode.UPDATE);
                fs.position = rLastBytePosition;
                fs.truncate(); //데이터 위에 짤라주고
                fs.close();

                //썸네일 이미지도 날려줌
                const rNowFrameSave:Number = rNowFrame;
                const list:Array = rJumpImageFolder.getDirectoryListing();
                const index:Number = getJumpImageIndex(rNowFrameSave);
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
                undoData.setRFileTotalFrame(rNowFrameSave);
                TOTAL_FRAME = rNowFrameSave;

                if(canvas1BitmapData && canvas1BitmapData !== rcanvas1BitmapData) canvas1BitmapData.dispose();
                canvas1BitmapData = rcanvas1BitmapData.clone();
                canvas1Bitmap.bitmapData = canvas1BitmapData;

                if(canvas11BitmapData && canvas11BitmapData !== rcanvas11BitmapData) canvas11BitmapData.dispose();
                canvas11BitmapData = rcanvas11BitmapData.clone();
                canvas11Bitmap.bitmapData = canvas11BitmapData;

                // mirrorON = rMirrorON;
                // mirrorCommandReady = false;
                // appInfoBox.setMirror(rMirrorON);
                changeCanvasSize(canvas1Bitmap.width,canvas1Bitmap.height,0,0,false);
                setBackgroundColorDrawMode(RCANVAS_BG_COLOR);
                resetReplayTime();
                setCanvasSameReplayCanvas();
                resetUndo();

                previewBox.updateImage(canvas1BitmapData,canvas11BitmapData,CANVAS_BG_COLOR);

                if(canvasWindowON)
                {
                    updateCanvasWindowImage();
                    updateCanvasWindowBitmapSize();
                }
            }

            replayTimeBox["replayNowBar"].width = replayTimeBox["replayTotalBar"].width;
            replayTimeBox["frameInfo"].text = TOTAL_FRAME+" / " + TOTAL_FRAME;

            resetReplaySpeedBar();
            setDeepUndoOFF();

            if(quickSidebarON)
            {
                _quickSidebarOFF();
            }

            saveContinue = false;
        }

        private function setDeleteBarDeleteFrontData():Boolean
        {
            replayTimeBox["replayDeleteBar"].x = replayTimeBox["replayTotalBar"].x;
            replayTimeBox["replayDeleteBar"].width = replayTimeBox["replayNowBar"].width;
            replayTimeBox["replayNowBar"].visible = false;
            replayTimeBox["replayDeleteBar"].visible = true;

            if(tickDraw.getIndex() < tickDraw.getDataLength())
            {
                drawRemainReplayData();
                checkCutFrameButtonsCanUse();
            }
            if(rNowFrame >= TOTAL_FRAME)
            {
                setReplayDeleteBarVisibleOFF();
                return true;
            }

            return false;
        }

        private function setDeleteBarSuperUndo():Boolean
        {
            const deleteBarWidth:Number = (replayTimeBox["replayTotalBar"].width*(rNowFrame/TOTAL_FRAME));

            replayTimeBox["replayDeleteBar"].x = replayTimeBox["replayTotalBar"].x+deleteBarWidth;
            replayTimeBox["replayDeleteBar"].width = (replayTimeBox["replayTotalBar"].width-deleteBarWidth);
            replayTimeBox["replayNowBar"].visible = false;
            replayTimeBox["replayDeleteBar"].visible = true;

            if(tickDraw.getIndex() < tickDraw.getDataLength())
            {
                drawRemainReplayData();
                checkCutFrameButtonsCanUse();
            }
            if(rNowFrame >= TOTAL_FRAME)
            {
                setReplayDeleteBarVisibleOFF();
                return true;
            }

            return false;
        }

        private function setDeleteBarReRecord():void
        {
            replayTimeBox["replayDeleteBar"].x = replayTimeBox["replayTotalBar"].x;
            replayTimeBox["replayDeleteBar"].width = replayTimeBox["replayTotalBar"].width;
            replayTimeBox["replayNowBar"].visible = false;
            replayTimeBox["replayDeleteBar"].visible = true;
        }

        private function setTopBarHintOFF():void
        {
            topBarHintClickEventON = false;

            if(captureModeON)
            {
                const str:String = drawCaptureArea.getRotatedRectSizeString();
                if(str === "")
                {
                    hint.off();
                }
                else
                {
                    setDefaultHintCaptureMode();
                }
            }
            else
            {
                hint.off();
            }
        }

        private function topBarHintONEvent(e:MouseEvent):void //topbarhint
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target) return;

            const targetName:String = e.target.name;

            if(lassoToolON)
            {
                if(targetName === "sideBarOFFButton"
                || targetName === "sideBarOFFButton2"
                || targetName === "sideBarONButton"
                || targetName === "sideBarONButton2"
                || targetName === "sideBarPositionButton"
                || targetName === "sideBarPositionButton2")
                {
                    if(mouseDragON)
                    {
                        return;
                    }
                }
                else
                {
                    return;
                }
            }
            else if(isHintCantUse())
            {
                return;
            }

            var str:String = "";

            switch(targetName)
            {
                case "frameInfo":
                case "replayTotalBar":
                case "replayNowBar":
                case "replayDeleteBar":
                {
                    setTopBarHintOFF();
                }
                return;
                case "timer":
                    str = "Actual working time\nReset [click]"+STRING_HOLD_NSEC;
                break;

                case "playButton":
                    str = "Play [enter, space]";
                break;

                case "pauseButton":
                    str = "Pause [enter, space]";
                break;

                case "replayPrev":
                    str = "Prev [left, z, .]\nJump 1 frame [right-click, shift+left, shift+z, shift+.]";
                break;

                case "replayNext":
                    str = "Next [right, x, ,]\nJump 1 frame [right-click, shift+right, shift+x, shift+,]";
                break;

                case "replaySpeedSliderWrapper":
                {
                    if(rSpeedLastStr === "") str = "Change playback speed [up, down / f, v / h, n]";
                    else str = rSpeedLastStr;
                }
                break;

                case "saveButton":
                case "repSaveButton":
                    str = "Save [ctrl+s]\nSave as.. [shift+ctrl+s, right-click]";
                break;

                case "loadButton":
                    str = "Load [ctrl+o]";
                break;

                case "repLoadButton":
                    str = "Load [ctrl+o]";
                break;

                case "clipButton":
                    str = "Load clipboard image [ctrl+v, ctrl+n]"+((topBar["clipButton"].alpha < 1.0)?"\nThere are no copied images":"");
                break;

                case "clearButton":
                    str = "New file [click, esc, backspace, delete]"+STRING_HOLD_NSEC;
                break;

                case "captureButton":
                case "repCaptureButton":
                    str = "Capture mode [ctrl+c, ctrl+m]";
                break;

                case "capOff":
                    str = "Exit capture mode (esc, backspace, f1, f7]";
                break;

                case "capFull":
                    str = (drawCaptureArea.isFullImageCapture()) ? "Save full image [ctrl+s, ctrl+k]" : "Save selected area [ctrl+s, ctrl+k]";
                break;

                case "capClipBoard":
                {
                    str = (e.target.alpha === 1.0) ? "Copy "+((drawCaptureArea.isFullImageCapture()) ?
                                                            "full image"
                                                            :"selected area image")
                                                            + " to clipboard [ctrl+c, ctrl+m]"
                                                            :"Already copied to clipboard";
                }
                break;

                case "capTrans":
                    str = "Background color ON/OFF [d, j]";
                break;

                case "capRotate":
                    str = "Rotate image [s, k]";
                break;

                case "capFlip":
                    str = "Flip image [a, l]";
                break;

                case "capLayer1VisibleButton":
                    str = "Layer 1 visible ON/OFF [1, 9]";
                break;

                case "capLayer2VisibleButton":
                    str = "Layer 2 visible ON/OFF [2, 0]";
                break;

                case "capStamp":
                    str = "Stamp ON/OFF [f, h]";
                break;

                case "capStampFont":
                    str = "Change stamp font";
                break;

                case "reRecordingButton":
                    str = "New file from this image [click, f2]"+STRING_HOLD_NSEC;
                break;

                case "cutPrevDataButton":
                    str = "Delete front data [click, f3]"+STRING_HOLD_NSEC;
                break;

                case "superUndoButton":
                    str = "Delete back data [click, f4]"+STRING_HOLD_NSEC;
                break;

                case "gridButton":
                    str = "Grid [f2, f8]\nReset [right-click, shift+f2, shift+f8]";
                break;

                case "gridSliderWrapper":
                {
                    if(gridValue === 0)
                    {
                        str = "Grid off";
                    }
                    else
                    {
                        str = "Grid " + (gridValue*GRID_GAP)+"px ("+gridValue+"/20), "+STRING_RIGHT_CLICK_TO_RESET;
                    }
                }
                break;

                case "gridMoveLeftButton":
                case "gridMoveRightButton":
                case "gridMoveUpButton":
                case "gridMoveDownButton":
                    str = "Move gird by 1 pixel \nRepeat [hold-click], Reset [right-click]";
                break;

                case "sideBarOFFButton":
                case "sideBarOFFButton2":
                    str = "Turn sidebar OFF [tab, \\ ]";
                break;

                case "sideBarONButton":
                case "sideBarONButton2":
                    str = "Turn sidebar ON [tab, \\ ]";
                break;

                case "sideBarPositionButton":
                    str = "Right sidebar [f3]";
                break;

                case "sideBarPositionButton2":
                    str = "Left sidebar [f3]";
                break;

                case "topBarColorButton":
                    str = "Change UI color [f4]";
                break;

                case "dpiButton":
                    str = "Current UI scale : "+getUIScaleString(uiScaleIndex)+"\nChange UI scale [f5]\nReset [shift+F5, right-click]";
                break;

                case "layer1CheckButton":
                case "layer1UncheckButton":
                    str = "Layer 1 visible ON/OFF [shift+1, shift+9]";
                break;

                case "layer2CheckButton":
                case "layer2UncheckButton":
                    str = "Layer 2 visible ON/OFF [shift+2, shift+0]";
                break;

                case "layerSwapButton":
                    str = "Swap layer [shift+q, shift+p]";
                break;

                case "layerMergeButton":
                    str = "Merge image to layer 2 [shift+e, shift+o]";
                break;

                case "aboutButton":
                    str = "About FOFO PAINT..";
                break;

                case "newWindowCloseButton":
                    str = "Close image view window [esc on window]";
                break;

                case "newWindowButton":
                    str = "Open image view window [f6]\nMove window [click+drag on window]\nFit to image size [right-click on window]";
                break;

                case "updateButton":
                    str = "Version " + NEW_VERSION + " released!\nInstall update [click]";
                break;

                case "drawModeButton": str = "Draw mode [f1, f7]"; break;
                case "replayModeButton": str = "Replay mode [f1, f7]"; break;
                case "replayZoomOutButton": str = "Zoom out [f5]\nReset [right-click, shift+f5, shift+f6]";break;
                case "replayZoomInButton": str = "Zoom in [f6]\nReset [right-click, shift+f5, shift+f6]"; break;
                case "replayFitToWindowButton": str = "Canvas center alignment ON/OFF [right-click on canvas]"; break;
                case "replayRotateButton": str = "Rotate \n"+STRING_RIGHT_CLICK_TO_RESET; break;
                case "replayRepeatButton": str = "Repeat ON/OFF"; break;

                default:
                return;
            }

            hint.on(str,target);
        }

        private function initReplayDataFile(overWrite:Boolean = false):void //기본 리플레이 파일 만들어줌
        {
            initRepTempFile();
            if(repFile.exists === false || overWrite === true)
            {
                const fs:FileStream = new FileStream();
                fs.open(repFile,FileMode.WRITE);
                fs.close();

                if(rJumpImageFolder.exists)
                {
                    rJumpImageFolder.deleteDirectory(true);
                }

                rJumpImageFolder.createDirectory();
                makeFirstReplayImage(canvas1BitmapData,canvas11BitmapData,CANVAS_BG_COLOR);
            }
        }

        private function drawFirstJumpImage():void
        {
            const fs:FileStream = new FileStream();
            const file:File = rJumpImageFolder.resolvePath("0");
            fs.open(file,FileMode.READ);
            const data:Array = fs.readObject() as Array;
            fs.close();
            data[0].uncompress();
            data[1].uncompress();
            var bmpd:BitmapData = new BitmapData(data[2],data[3],true,0);
            var bmpd1:BitmapData = new BitmapData(data[2],data[3],true,0);
            const newRectangle:Rectangle = new Rectangle(0,0,data[2],data[3]);

            bmpd.lock();
            bmpd.setPixels(newRectangle,data[0]);
            bmpd.unlock();

            bmpd1.lock();
            bmpd1.setPixels(newRectangle,data[1]);
            bmpd1.unlock();

            if(rcanvas1BitmapData && bmpd !== rcanvas1BitmapData) rcanvas1BitmapData.dispose();
            rcanvas1BitmapData = bmpd.clone();
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;

            if(rcanvas11BitmapData && bmpd1 !== rcanvas11BitmapData) rcanvas11BitmapData.dispose();
            rcanvas11BitmapData = bmpd1.clone();
            rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;
            bmpd.dispose();
            bmpd1.dispose();
            bmpd = null;
            bmpd1 = null;

            changeCanvasSizeReplayMode(rcanvas1Bitmap.width,rcanvas1Bitmap.height);
            setBackgroundColorReplayMode(data[4]);
        }

        private function makeFirstReplayImage(bmpd:BitmapData,bmpd1:BitmapData,bgColor:uint):void //리플레이 처음 이미지 만들어줌
        {
            const fs:FileStream = new FileStream();
            var ba:ByteArray = new ByteArray();
            var ba1:ByteArray = new ByteArray();
            const w:Number = bmpd.width;
            const h:Number = bmpd.height;
            const newRectangle:Rectangle = new Rectangle(0,0,w,h);

            rJumpImageFrameData = [0];

            bmpd.copyPixelsToByteArray(newRectangle,ba);
            ba.compress();

            if(rFirstImage && rFirstImage !== bmpd) rFirstImage.dispose();
            rFirstImage = bmpd.clone();

            if(bmpd1 === null) bmpd1 = new BitmapData(w,h,true,0);

            bmpd1.copyPixelsToByteArray(newRectangle,ba1);
            ba1.compress();

            if(rFirstImage1 && rFirstImage1 !== bmpd1) rFirstImage1.dispose();
            rFirstImage1 = bmpd1.clone();

            rFirstBGColor = bgColor;

            fs.open(rFirstImageFile,FileMode.WRITE);
            fs.writeObject([ba //레이어 1
                            ,ba1 //레이어 2
                            ,w //가로
                            ,h //세로
                            ,bgColor //배경색
                            ,0 //마지막 바이트
                            ,0 //마지막 프레임 합
                            ,false]); //미러 플래그
            fs.close();

            ba.clear();
            ba1.clear();

            ba = null;
            ba1 = null;
        }

        private function resetUndo(replayRefImageFlag:Boolean=false):void
        {
            undoIndex = -1;
            if(replayRefImageFlag === false) undoData.setUndoRefImageByDrawMode();
            else undoData.setUndoRefImageByReplayMode();
            undoData.resetRJumpImageCount();
            rData = [];
            rDataFrame = [];
            rDataBuffer = [];
            readyAddUndoFlag = false;
            undoDelFlag = false;
            rCursor.visible = false;
            deepUndoON = false;
        }

        //창크기에 맞추어서 캔버스를 축소해줌
        private function fitCanvasToWindow(captureMode:Boolean=false,manualFlag:Boolean=false):void
        {
            const replayMode:Boolean = replayModeON;
            const uiscale:Number = getUIScale();
            const offsetX:Number = 44+STAGE_LEFT_OFFSET+STAGE_RIGHT_OFFSET;
            const offsetY:Number = (captureMode) ? (topBar.BARSIZE)*uiscale+45*uiscale : (topBar.BARSIZE+replayTimeBox.BARSIZE)*uiscale+45*uiscale;
            const stw:int = stage.stageWidth-offsetX;
            const sth:int = stage.stageHeight-offsetY-STAGE_BOTTOM_OFFSET-hintBox.getDefaultHeight()*uiscale;
            var xBitmap1:Bitmap;
            var xBitmap11:Bitmap;
            var xReg:Sprite;
            var w:Number;
            var h:Number;
            var _captureRotated:uint;

            if(replayMode)
            {
                xBitmap1 = rcanvas1Bitmap;
                xBitmap11 = rcanvas11Bitmap;
                xReg = rregPoint;

                if(manualFlag)
                {
                    xReg.scaleX = 1.0;
                    xReg.scaleY = 1.0; //크기를 원래대로 해놓고 해야 길이 측정이 됨
                    const b:Rectangle = rcanvas1Bitmap.getBounds(stage);
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
                xBitmap1 = canvas1Bitmap;
                xBitmap11 = canvas11Bitmap;
                xReg = regPoint;
                w = CANVAS_WIDTH;
                h = CANVAS_HEIGHT;
            }

            if(captureMode)
            {
                _captureRotated = captureRotated;
                if(captureRotated === 1 || captureRotated === 3)
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
                xReg.rotation = 90*_captureRotated;
            }

            if(replayMode === true && z < 1.0 && !rFitZoomedON)
            {
                replayEndWithCanvasFitWindow = true;
            }

            setZoomCanvas(z,replayMode);
            setCenvasCenterPos(replayMode,captureMode);

            if(!manualFlag || playbackFinished)
            {
                xBitmap1.smoothing = true;
                xBitmap11.smoothing = true;
            }

            // if(captureMode)
            // {
            //     drawCaptureArea.updateDrawArea("fitCanvasToWindow");
            // }
        }

        private function replayCompleteEffect():void
        {
            replayTimeBox["playButton"].visible = true;
            replayTimeBox["pauseButton"].visible = false;

            setColorTransform(replayTimeBox["replayNowBar"],uiColorSet[uiColorIndex][5]);

            //재생이 끝나면 전체화면을 보여줌
            if(!mouseClickON)
            {
                fitCanvasToWindow();
                rzoomedIndex = zoomList.indexOf(1.0);
            }

            setcanvasFlash(rcanvasPanel,0,0,RCANVAS_WIDTH,RCANVAS_HEIGHT);
        }

        private function cancelRestartTimer():void
        {
            removeTimer("rRestartTimer");

            //재시작 카운터가 돌아갈때 1프레임 스킵을 하면
            //프레임 정보가 나오지 않고 END가 나와서 조건 걸어줌
            if(rRestartTimerCount < 10)
            {
                replayTimeBox["frameInfo"].text = TOTAL_FRAME+" / " +TOTAL_FRAME;
            }
            rRestartTimerCount = 10;
            setColorTransform(replayTimeBox["replayNowBar"],uiColorSet[uiColorIndex][4]);

            stage.removeEventListener(MouseEvent.MOUSE_DOWN,cancelRestartTimerEvent);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,cancelRestartTimerEvent);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,cancelRestartTimerEvent);
        }

        private function cancelRestartTimerEvent(e:Object):void
        {
            cancelRestartTimer();
        }

        private function setRestartTimer():void
        {
            if(replayRepeatON)
            {
                rRestartTimerCount = 10;

                stage.addEventListener(MouseEvent.MOUSE_DOWN,cancelRestartTimerEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,cancelRestartTimerEvent);
                stage.addEventListener(KeyboardEvent.KEY_DOWN,cancelRestartTimerEvent);

                addTimerByName("rRestartTimer",1.0,true,function():Boolean
                {
                    if(rRestartTimerCount === 0)
                    {
                        cancelRestartTimer();
                        startReplay();
                        return false;
                    }

                    const str:String = "Play again in " + rRestartTimerCount +" sec";
                    replayTimeBox["frameInfo"].text = str;
                    --rRestartTimerCount;
                    return true;
                });
            }
            else
            {
                rRestartTimerCount = 9;
                cancelRestartTimer();
            }
        }

        private function resetReplaySpeedBar():void
        {
            rSpeed = 1; //속도 리셋
            topBar.replaySpeedSliderCursor.x = topBar["replaySpeedSlider"].x+1.5;
        }

        //total frame file max frame등등은 수동으로 초기화
        //이건 리플레이 시간을 초기화 시켜주는것 뿐임 데이터는 건드리지 않음
        private function resetReplayTime():void
        {
            //어떤 이유가 있어서 rDataReadFlag는 여기 넣으면 안됨 수동으로 조절
            rIndex = 0;
            rIndexStart = 0;
            rLastBytePosition = 0;
            rNowFrame = 0;
            rPrevFrame = 0;
            rJumpImageIndexLast = -2;
            rJumpImageNowFrameLast = -1;
            rJumpCacheImageIndexSave = -2;
            playbackFinished = true;
            doDrawSlowEventON = false;
            rSpeedLastStr = "";
            tickDraw.reset();
        }

        private function applyLassoShapen(scale:Number):void
        {
            if(scale === 0.0) return;

            var index:uint = Math.abs(Math.floor(scale-1.0));
            if(index > 2) index = 2;

            var sharpen:ConvolutionFilter = new ConvolutionFilter(3,3,LASSO_SHARP_DATA[index][0],LASSO_SHARP_DATA[index][1]);

            lassoBMP.filters = [sharpen];
            lassoBMPsub.filters = [sharpen];
        }

        private function selectReplaySubLayer(flag:Boolean):void
        {
            rSubLayerSave = flag;

            if(flag)
            {
                if(rcanvasPanel.getChildIndex(rcanvas2) > rcanvasPanel.getChildIndex(rcanvas1Bitmap))
                {
                    rcanvasPanel.setChildIndex(rcanvas2,rcanvasPanel.getChildIndex(rcanvas1Bitmap));
                }
            }
            else if(rcanvasPanel.getChildIndex(rcanvas2) < rcanvasPanel.getChildIndex(rcanvas1Bitmap))
            {
                rcanvasPanel.setChildIndex(rcanvas2,rcanvasPanel.getChildIndex(rcanvas1Bitmap));
            }
        }

        private function moveImageReplayMode(x:Number,y:Number,layer1:Boolean,layer2:Boolean):void
        {
            var tempBitData:BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
            var movedMat:Matrix = new Matrix();
            if(!layer1 && !layer2)
            {
                layer1 = true;
                layer2 = true;
            }

            movedMat.translate(x,y);

            if(layer1)
            {
                tempBitData.draw(rcanvas1BitmapData,movedMat);
                if(rcanvas1BitmapData && tempBitData !== rcanvas1BitmapData) rcanvas1BitmapData.dispose();
                rcanvas1BitmapData = tempBitData.clone();
                rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
            }

            if(layer2)
            {
                tempBitData.fillRect(new Rectangle(0,0,RCANVAS_WIDTH,RCANVAS_HEIGHT),0);
                tempBitData.draw(rcanvas11BitmapData,movedMat);

                if(rcanvas11BitmapData && tempBitData !== rcanvas11BitmapData) rcanvas11BitmapData.dispose();
                rcanvas11BitmapData = tempBitData.clone();
                rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;
            }
            tempBitData.dispose();
            tempBitData = null;
        }

        private function replayLineStyleReady(shape:Boolean,size:uint,color:uint,alpha:Number):void
        {
            rcanvas2.alpha = alpha;
            if(shape)
            {
                rcanvas2Draw.graphics.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
            }
            else
            {
                rcanvas2Draw.graphics.lineStyle(size,color);
            }
        }

        private function replayLineStyleReady2(shape:Boolean,size:uint,color:uint,alpha:Number):void
        {
            rcanvas2.alpha = alpha;
            if(shape)
            {
                rcanvas2Draw.graphics.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.BEVEL);
            }
            else
            {
                rcanvas2Draw.graphics.lineStyle(size,color);
            }
        }

        private function replayLineStyleReady3(shape:Boolean,size:uint,color:uint,alpha:Number):void
        {
            rcanvas2.alpha = alpha;
            if(shape)
            {
                rcanvas2Draw.graphics.lineStyle(size,color,1,false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.BEVEL);
            }
            else
            {
                rcanvas2Draw.graphics.lineStyle(size,color);
            }
        }


        private function mirrorCanvasReplayMode():void
        {
            var mirrorBMPD:BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
            var flipMat:Matrix = new Matrix(-1,0,0,1,RCANVAS_WIDTH);

            mirrorBMPD.draw(rcanvas1BitmapData,flipMat);

            if(rcanvas1BitmapData && mirrorBMPD !== rcanvas1BitmapData) rcanvas1BitmapData.dispose();
            rcanvas1BitmapData = mirrorBMPD.clone();
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;

            mirrorBMPD.fillRect(new Rectangle(0,0,RCANVAS_WIDTH,RCANVAS_HEIGHT),0);
            mirrorBMPD.draw(rcanvas11BitmapData,flipMat);

            if(rcanvas11BitmapData && mirrorBMPD !== rcanvas11BitmapData) rcanvas11BitmapData.dispose();
            rcanvas11BitmapData = mirrorBMPD.clone();
            rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;

            mirrorBMPD.dispose();
            mirrorBMPD = null;

            rMirrorON = !rMirrorON;

            if(rFitZoomedON) fitCanvasToWindowManualReplayMode();
        }

        private function cTickDraw():Object
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
                rCursor.x = rCursorPosFirst.x;
                rCursor.y = rCursorPosFirst.y;
            }

            function updateRCursorPos():void
            {
                rCursor.x = rCursorPos.x;
                rCursor.y = rCursorPos.y;
            }

            function setRCursorPosMoveTool(x:Number,y:Number):void
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

            function reset():void
            {
                data = [];
                index = 0;
            }

            function ready(refData:Array,refIndex:uint=0):void
            {
                data = refData;
                index = refIndex;
            }

            function getRestDataCount():Number
            {
                if(!data) return 0;
                return data.length-index;
            }

            function isIndexSmallerData():Boolean
            {
                if(!data) return false;
                return index < data.length;
            }

            function isIndexBiggerData():Boolean
            {
                if(!data) return true;
                return index > data.length-1;
            }

            function getDataLength():uint
            {
                if(!data) return 0;
                return data.length;
            }

            function getData():Array
            {
                return data;
            }

            function getIndex():uint
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
                    next();
                }
            }

            function checkAirBrush(airBrushFlag:Boolean,size:uint):void
            {
                if(airBrushFlag === true)
                {
                    if(airBrushSizeReplayMode !== size) setBlurCanvasBySizeReplayMode(size);
                }
                else if(airBrushSizeReplayMode > 0)
                {
                    resetCanvasBlurReplaymode();
                }
            }

            function checkSubLayer(subLayerFlag:Boolean):void
            {
                if(subLayerFlag)
                {
                    // if((replayStartON && subLayerFlag) !== false && rSubLayerSave !== subLayerFlag)
                    if(rSubLayerSave !== subLayerFlag)
                    {
                        selectReplaySubLayer(subLayerFlag);
                    }
                }
                else if(rSubLayerSave)
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

                airBrushSizeReplayMode2 = airBrushSize;

                if(fillpen)
                {
                    rcanvas2Draw.graphics.clear();
                    replayLineStyleReady2(false,1,color,1.0);
                    rcanvas2Draw.graphics.beginFill(color);
                    rcanvas2Draw.graphics.moveTo(startX,startY);
                    rcanvas2.alpha = alpha;
                }
                else
                {
                    replayLineStyleReady3(shape,size,color,alpha);
                    rcanvas2Draw.graphics.moveTo(startX,startY);
                }

                if(index === 0)
                {
                    resetRCanvas2DrawCliprect2();
                }
                else
                {
                    updateRCanvas2DrawCliprect2();
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
                    rcanvas2Draw.graphics.clear();
                    replayLineStyleReady2(false,1,color,1.0);
                    rcanvas2Draw.graphics.beginFill(color);
                    rcanvas2Draw.graphics.moveTo(startX,startY);
                    rcanvas2.alpha = alpha;
                }
                else
                {
                    replayLineStyleReady3(shape,size,color,alpha);
                    rcanvas2Draw.graphics.moveTo(startX,startY);
                }

                if(index === 0)
                {
                    resetRCanvas2DrawCliprect();
                }
                else
                {
                    updateRCanvas2DrawCliprect();
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
                    rcanvas2Draw.graphics.moveTo(startX,startY);
                }
                else
                {
                    rcanvas2Draw.graphics.clear();
                    replayLineStyleReady2(false,1,color,1.0);
                    rcanvas2Draw.graphics.beginFill(color);
                    rcanvas2Draw.graphics.moveTo(startX,startY);
                    rcanvas2.alpha = alpha;
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
                    rcanvas2Draw.graphics.moveTo(startX,startY);
                }
                else
                {
                    rcanvas2Draw.graphics.clear();
                    replayLineStyleReady2(false,1,color,1.0);
                    rcanvas2Draw.graphics.beginFill(color);
                    rcanvas2Draw.graphics.moveTo(startX,startY);
                    rcanvas2.alpha = alpha;
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
                    rcanvas2Draw.graphics.moveTo(startX,startY);
                }
                else
                {
                    rcanvas2Draw.graphics.clear();
                    replayLineStyleReady(false,1,color,1.0);
                    rcanvas2Draw.graphics.beginFill(color);
                    rcanvas2Draw.graphics.moveTo(startX,startY);
                    rcanvas2.alpha = alpha;
                }
            }

            function lineTo(data:Array):void
            {
                const x:Number = data[1];
                const y:Number = data[2];

                rcanvas2Draw.graphics.lineTo(x,y);
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

                rcanvas2Bitmap.bitmapData = null;
                rcanvas2BitmapData.dispose();
                rcanvas2BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
                rcanvas2Draw.graphics.clear();

                updateLineStyleBackup(alpha,blendMode);
                rcanvas2.alpha = alpha;
                rcanvas2Draw.graphics.lineStyle(size,color,1,false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
                rcanvas2Draw.graphics.drawPath(command,xyData);
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

                airBrushSizeReplayMode2 = airBrushSize;
                updateLineStyleBackup(alpha,blendMode);

                rcanvas2.alpha = alpha;
                rcanvas2Draw.graphics.clear();
                rcanvas2Draw.graphics.lineStyle(1,color);
                rcanvas2Draw.graphics.beginFill(color);
                rcanvas2Draw.graphics.drawPath(command,xyData);
                setRCursorPos(xyData[xyData.length-2],xyData[xyData.length-1]);
                resetRCanvas2DrawCliprect2();
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
                rcanvas2.alpha = alpha;
                rcanvas2Draw.graphics.clear();
                rcanvas2Draw.graphics.lineStyle(1,color);
                rcanvas2Draw.graphics.beginFill(color);
                rcanvas2Draw.graphics.drawPath(command,xyData);
                setRCursorPos(xyData[xyData.length-2],xyData[xyData.length-1]);
                resetRCanvas2DrawCliprect();
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
                rcanvas2.alpha = alpha;
                rcanvas2Draw.graphics.clear();
                rcanvas2Draw.graphics.lineStyle(1,color);
                rcanvas2Draw.graphics.beginFill(color);
                rcanvas2Draw.graphics.drawPath(command,xyData);
                setRCursorPos(xyData[xyData.length-2],xyData[xyData.length-1]);
            }

            function fill2(data:Array):void
            {
                const color:Number = data[1];
                const alpha:Number = data[2];
                const blendMode:String = data[3];
                const arr:Vector.<Number> = data[4];
                const len:uint = arr.length;

                resetCanvasBlurReplaymode();
                updateLineStyleBackup(alpha,blendMode);
                rcanvas2.alpha = alpha;
                rcanvas2Draw.graphics.clear();
                rcanvas2Draw.graphics.lineStyle(1,color);
                rcanvas2Draw.graphics.beginFill(color);
                rcanvas2Draw.graphics.moveTo(arr[0],arr[1]);

                for(var i:uint = 2;i<len;i+=2)
                {
                    rcanvas2Draw.graphics.lineTo(arr[i],arr[i+1]);
                }

                rcanvas2Draw.graphics.endFill();
                setRCursorPos(arr[len-2],arr[len-1]);
            }

            function fill(data:Array):void
            {
                const color:Number = data[1];
                const alpha:Number = data[2];
                const blendMode:String = data[3];
                const command:Vector.<int> = data[4];
                const xyData:Vector.<Number> = data[5];

                resetCanvasBlurReplaymode();
                updateLineStyleBackup(alpha,blendMode);
                rcanvas2.alpha = alpha;
                rcanvas2Draw.graphics.clear();
                rcanvas2Draw.graphics.lineStyle(1,color);
                rcanvas2Draw.graphics.beginFill(color);
                rcanvas2Draw.graphics.drawPath(command,xyData);
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
                airBrushSizeReplayMode2 = airBrushSize;
                updateLineStyleBackup(alpha,blendMode);
                rcanvas2.alpha = alpha;
                rcanvas2Draw.graphics.lineStyle(0,0,0);
                rcanvas2Draw.graphics.beginFill(color);

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

                    rcanvas2Draw.graphics.drawPath(cmd,pos);

                    point = null;
                }
                else
                {
                    rcanvas2Draw.graphics.drawCircle(startX,startY,size/2);
                }

                rcanvas2Draw.graphics.endFill();
                resetRCanvas2DrawCliprect2();
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
                rcanvas2.alpha = alpha;
                rcanvas2Draw.graphics.lineStyle(0,0,0);
                rcanvas2Draw.graphics.beginFill(color);

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

                    rcanvas2Draw.graphics.drawPath(cmd,pos);
                }
                else
                {
                    rcanvas2Draw.graphics.drawCircle(startX,startY,size/2);
                }

                rcanvas2Draw.graphics.endFill();

                resetRCanvas2DrawCliprect();
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
                rcanvas2.alpha = alpha;
                rcanvas2Draw.graphics.lineStyle(0,0,0);
                rcanvas2Draw.graphics.beginFill(color);

                if(shape) rcanvas2Draw.graphics.drawRect(startX-size/2,startY-size/2,size,size);
                else rcanvas2Draw.graphics.drawCircle(startX,startY,size/2);
                rcanvas2Draw.graphics.endFill();

                resetRCanvas2DrawCliprect();
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
                rcanvas2.alpha = alpha;
                rcanvas2Draw.graphics.lineStyle(0,0,0);
                rcanvas2Draw.graphics.beginFill(color);

                if(shape) rcanvas2Draw.graphics.drawRect(startX-size/2,startY-size/2,size,size);
                else rcanvas2Draw.graphics.drawCircle(startX,startY,size/2);
                rcanvas2Draw.graphics.endFill();

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
                rcanvas2.alpha = alpha;

                checkSubLayer(subLayer);
                airBrushSizeReplayMode2 = airBrushSize;

                if(shape) rcanvas2Draw.graphics.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.ROUND);
                else rcanvas2Draw.graphics.lineStyle(size,color);

                rcanvas2Draw.graphics.moveTo(startX,startY);
                rcanvas2Draw.graphics.lineTo(endX,endY);

                resetRCanvas2DrawCliprect2();
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
                rcanvas2.alpha = alpha;

                checkSubLayer(subLayer);
                checkAirBrush(airBrush,size);

                if(shape) rcanvas2Draw.graphics.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.ROUND);
                else rcanvas2Draw.graphics.lineStyle(size,color);

                rcanvas2Draw.graphics.moveTo(startX,startY);
                rcanvas2Draw.graphics.lineTo(endX,endY);

                resetRCanvas2DrawCliprect();
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
                rcanvas2.alpha = alpha;

                checkSubLayer(subLayer);
                checkAirBrush(airBrush,size);

                if(shape) rcanvas2Draw.graphics.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.ROUND);
                else rcanvas2Draw.graphics.lineStyle(size,color);

                rcanvas2Draw.graphics.moveTo(startX,startY);
                rcanvas2Draw.graphics.lineTo(endX,endY);

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
                rcanvas2.alpha = alpha;

                checkSubLayer(subLayer);
                checkAirBrush(airBrush,size);

                if(shape) rcanvas2Draw.graphics.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
                else rcanvas2Draw.graphics.lineStyle(size,color);

                rcanvas2Draw.graphics.moveTo(startX,startY);
                rcanvas2Draw.graphics.lineTo(endX,endY);

                setRCursorPos(endX,endY);
            }

            function move1(data:Array):void
            {
                moveImageReplayMode(data[1],data[2],true,false);
                setRCursorPosMoveTool(data[1],data[2]);
            }

            function move2(data:Array):void
            {
                moveImageReplayMode(data[1],data[2],false,true);
                setRCursorPosMoveTool(data[1],data[2]);
            }

            function move(data:Array):void
            {
                moveImageReplayMode(data[1],data[2],true,true);
                setRCursorPosMoveTool(data[1],data[2]);
            }

            function resetLassoVars():void
            {
                lassoBMP.filters = [];
                lassoBMPsub.filters = [];

                if(lassoBMP.bitmapData) lassoBMP.bitmapData.dispose();
                if(lassoBMPsub.bitmapData) lassoBMPsub.bitmapData.dispose();

                lassoBox1.x = 0;
                lassoBox1.y = 0;
                lassoBox1.scaleX = 1.0;
                lassoBox1.scaleY = 1.0;
                lassoBox1.rotation = 0;
                lassoBox1.visible = false;

                lassoBox2.x = 0;
                lassoBox2.y = 0;
                lassoBox2.scaleX = 1.0;
                lassoBox2.scaleY = 1.0;
                lassoBox2.rotation = 0;
                lassoBox2.visible = false;
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

                    lassoBMP.smoothing = true;
                    lassoBMPsub.smoothing = true;

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
                        rcanvas1BitmapData.draw(lassoBMP,mat);
                        rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                    }

                    if(data[6])
                    {
                        rcanvas11BitmapData.draw(lassoBMPsub,mat);
                        rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;
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

                    lassoBMP.smoothing = true;
                    lassoBMPsub.smoothing = true;

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
                        rcanvas1BitmapData.draw(lassoBMP,mat);
                        rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                    }

                    if(data[6])
                    {
                        rcanvas11BitmapData.draw(lassoBMPsub,mat);
                        rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;
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

                rBGColorSave = color;
                setBackgroundColorReplayMode(color);
                setRCursorPosToCenter();
            }

            function canvasSize(data:Array):void
            {
                const width:Number = data[1];
                const height:Number = data[2];
                const moveX:Number = data[3];
                const moveY:Number = data[4];
                const movedFlag:Boolean = data[5];

                changeCanvasSizeReplayMode(width,height,moveX,moveY,movedFlag);
                setRCursorPos(width/2,height/2);
            }

            function tempDone4(data:Array):void
            {
                if(airBrushSizeReplayMode2 > 0)
                {
                    const blurSize:Number = getBlurSize(airBrushSizeReplayMode2,1.0);
                    rcanvas2Draw.filters = [new BlurFilter(blurSize,blurSize,3)];
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                    canvas2Draw.filters = [];
                }
                else
                {
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                }

                rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                updateRCanvas2DrawCliprect2();
                rcanvas2Draw.graphics.clear();
            }

            function tempDone3(data:Array):void
            {
                rcanvas2BitmapData.draw(rcanvas2Draw);
                rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                updateRCanvas2DrawCliprect2();
                rcanvas2Draw.graphics.clear();
            }

            function tempDone2(data:Array):void
            {
                if(airBrushSizeReplayMode > 0 && rzoomed !== 1.0)
                {
                    setBlurCanvasBySizeNoZoomReplayMode();
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                    rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                    updateRCanvas2DrawCliprect();
                    rcanvas2Draw.graphics.clear();
                    setBlurCanvasBySizeReplayMode(airBrushSizeReplayMode);
                }
                else
                {
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                    rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                    updateRCanvas2DrawCliprect();
                    rcanvas2Draw.graphics.clear();
                }
            }

            function tempDone(data:Array):void
            {
                if(airBrushSizeReplayMode > 0 && rzoomed !== 1.0)
                {
                    setBlurCanvasBySizeNoZoomReplayMode();
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                    rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                    rcanvas2Draw.graphics.clear();
                    setBlurCanvasBySizeReplayMode(airBrushSizeReplayMode);
                }
                else
                {
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                    rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                    rcanvas2Draw.graphics.clear();
                }
            }

            function drawDone5(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1,1,1,lineStyleData[0]);

                if(airBrushSizeReplayMode2 > 0)
                {
                    const blurSize:Number = getBlurSize(airBrushSizeReplayMode2,1.0);
                    rcanvas2Draw.filters = [new BlurFilter(blurSize,blurSize,3)];
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                    rcanvas2Draw.filters = [];
                }
                else
                {
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                }

                rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;

                updateRCanvas2DrawCliprect2();
                extandRCanvas2DrawCliprect2();

                if(subLayer)
                {
                    rcanvas11BitmapData.draw(rcanvas2Bitmap,null,canvasAlpha,lineStyleData[1],rcanvas2ClipRect2);
                    rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;
                }
                else
                {
                    rcanvas1BitmapData.draw(rcanvas2Bitmap,null,canvasAlpha,lineStyleData[1],rcanvas2ClipRect2);
                    rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                }

                rcanvas2BitmapData.fillRect(rcanvas2ClipRect2,0);
                rcanvas2Draw.graphics.clear();
            }

            function drawDone4(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1,1,1,lineStyleData[0]);

                rcanvas2BitmapData.draw(rcanvas2Draw);
                rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;

                updateRCanvas2DrawCliprect2();
                extandRCanvas2DrawCliprect2();

                if(airBrushSizeReplayMode2 > 0)
                {
                    const blurSize:Number = getBlurSize(airBrushSizeReplayMode2,1.0);
                    rcanvas2BitmapData.applyFilter(rcanvas2BitmapData,rcanvas2ClipRect2,new Point(rcanvas2ClipRect2.x,rcanvas2ClipRect2.y),new BlurFilter(blurSize,blurSize,3));
                    rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                }

                if(subLayer)
                {
                    rcanvas11BitmapData.draw(rcanvas2Bitmap,null,canvasAlpha,lineStyleData[1],rcanvas2ClipRect2);
                    rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;
                }
                else
                {
                    rcanvas1BitmapData.draw(rcanvas2Bitmap,null,canvasAlpha,lineStyleData[1],rcanvas2ClipRect2);
                    rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                }

                rcanvas2BitmapData.fillRect(rcanvas2ClipRect2,0);
                rcanvas2Draw.graphics.clear();
            }

            function drawDone3(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1,1,1,lineStyleData[0]);

                if(airBrushSizeReplayMode > 0 && rzoomed !== 1.0)
                {
                    setBlurCanvasBySizeNoZoomReplayMode();
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                    rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                    setBlurCanvasBySizeReplayMode(airBrushSizeReplayMode);
                }
                else
                {
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                    rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                }

                updateRCanvas2DrawCliprect();
                extandRCanvas2DrawCliprect();

                if(subLayer)
                {
                    rcanvas11BitmapData.draw(rcanvas2Bitmap,null,canvasAlpha,lineStyleData[1],rcanvas2ClipRect);
                    rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;
                }
                else
                {
                    rcanvas1BitmapData.draw(rcanvas2Bitmap,null,canvasAlpha,lineStyleData[1],rcanvas2ClipRect);
                    rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                }

                rcanvas2BitmapData.fillRect(rcanvas2ClipRect,0);
                rcanvas2Draw.graphics.clear();

                if(airBrushSizeReplayMode > 0)
                {
                    resetCanvasBlurReplaymode();
                }
            }

            function drawDone2(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1,1,1,lineStyleData[0]);

                if(airBrushSizeReplayMode > 0 && rzoomed !== 1.0)
                {
                    setBlurCanvasBySizeNoZoomReplayMode();
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                    rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                    setBlurCanvasBySizeReplayMode(airBrushSizeReplayMode);
                }
                else
                {
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                    rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                }

                if(subLayer)
                {
                    rcanvas11BitmapData.draw(rcanvas2Bitmap,null,canvasAlpha,lineStyleData[1]);
                    rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;
                }
                else
                {
                    rcanvas1BitmapData.draw(rcanvas2Bitmap,null,canvasAlpha,lineStyleData[1]);
                    rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                }

                rcanvas2BitmapData.fillRect(new Rectangle(0,0,rcanvas1BitmapData.width,rcanvas1BitmapData.height),0);
                rcanvas2Draw.graphics.clear();

                if(airBrushSizeReplayMode > 0)
                {
                    resetCanvasBlurReplaymode();
                }
            }

            function drawDone(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                // if(!lineStyleData) return;
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1,1,1,lineStyleData[0]);

                if(airBrushSizeReplayMode > 0 && rzoomed !== 1.0)
                {
                    setBlurCanvasBySizeNoZoomReplayMode();
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                    rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                    setBlurCanvasBySizeReplayMode(airBrushSizeReplayMode);
                }
                else
                {
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                    rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                }

                if(subLayer)
                {
                    var subLayerBmpd:BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
                    subLayerBmpd.draw(rcanvas2Bitmap,null,canvasAlpha);
                    subLayerBmpd.draw(rcanvas1Bitmap);

                    if(rcanvas1BitmapData && subLayerBmpd !== rcanvas1BitmapData) rcanvas1BitmapData.dispose();
                    rcanvas1BitmapData = subLayerBmpd.clone();
                    rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                    subLayerBmpd.dispose();
                    subLayerBmpd = null;
                }
                else
                {
                    rcanvas1BitmapData.draw(rcanvas2Bitmap,null,canvasAlpha,lineStyleData[1]);
                    rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                }

                rcanvas2Bitmap.bitmapData = null;
                rcanvas2BitmapData.fillRect(new Rectangle(0,0,rcanvas2BitmapData.width,rcanvas2BitmapData.height),0);

                rcanvas2Draw.graphics.clear();

                if(airBrushSizeReplayMode > 0)
                {
                    resetCanvasBlurReplaymode();
                }
            }

            function clear(layer1:Boolean,layer2:Boolean):void
            {
                if(!layer1 && !layer2)
                {
                    layer1 = true;
                    layer2 = true;
                }
                const rect:Rectangle = new Rectangle(0,0,rcanvas1BitmapData.width,rcanvas1BitmapData.height);

                if(layer1) rcanvas1BitmapData.fillRect(rect,0);
                if(layer2) rcanvas11BitmapData.fillRect(rect,0);
                setRCursorPosToCenter();
            }

            function swapLayer():void
            {
                var tempbmpd1:BitmapData = rcanvas1BitmapData.clone();
                var tempbmpd11:BitmapData = rcanvas11BitmapData.clone();
                const rect:Rectangle = new Rectangle(0,0,rcanvas1BitmapData.width,rcanvas1BitmapData.height);

                rcanvas1BitmapData.fillRect(rect,0);
                rcanvas11BitmapData.fillRect(rect,0);

                rcanvas1BitmapData.draw(tempbmpd11);
                rcanvas11BitmapData.draw(tempbmpd1);

                tempbmpd1.dispose();
                tempbmpd11.dispose();
                tempbmpd1 = null;
                tempbmpd11 = null;
                setRCursorPosToCenter();
            }

            function mergeLayer():void
            {
                rcanvas11BitmapData.draw(rcanvas1BitmapData);
                rcanvas1BitmapData.fillRect(new Rectangle(0,0,rcanvas1BitmapData.width,rcanvas1BitmapData.height),0);
                setRCursorPosToCenter();
            }

            function next():void
            {
                if(!data || data.length === 0)
                {
                    return;
                }

                switch(data[index][0])
                {
                    case "lineStyle": lineStyle(data[index]); break;
                    case "lineStyle2": lineStyle2(data[index]); break;
                    case "lineStyle3": lineStyle3(data[index]); break;
                    case "lineStyle4": lineStyle4(data[index]); break;
                    case "lineStyle5": lineStyle5(data[index]); break;
                    case "lineTo": lineTo(data[index]); break;
                    case "sqline": sqline(data[index]); break;
                    case "fill": fill(data[index]); break;
                    case "fill2": fill2(data[index]); break;
                    case "fill3": fill3(data[index]); break;
                    case "fill4": fill4(data[index]); break;
                    case "fill5": fill5(data[index]); break;
                    case "dot": dot(data[index]); break;
                    case "dot2": dot2(data[index]); break;
                    case "dot3": dot3(data[index]); break;
                    case "dot4": dot4(data[index]); break;
                    case "line": line(data[index]); break;
                    case "line1": line1(data[index]); break;
                    case "line2": line2(data[index]); break;
                    case "line3": line3(data[index]); break;
                    case "move": move(data[index]); break;
                    case "move1": move1(data[index]); break;
                    case "move2": move2(data[index]); break;
                    case "lasso": lasso(data[index],false); break;
                    case "lasso2": lasso2(data[index],false); break;
                    case "lassodel": lasso(data[index],true); break;
                    case "lassodel2": lasso2(data[index],true); break;
                    case "mirror": mirror(); break;
                    case "bgColor": bgColor(data[index]); break;
                    case "canvasSize": canvasSize(data[index]); break;
                    case "tempDone": tempDone(data[index]); break;
                    case "tempDone2": tempDone2(data[index]); break;
                    case "tempDone3": tempDone3(data[index]); break;
                    case "tempDone4": tempDone4(data[index]); break;
                    case "drawDone": drawDone(data[index]); break;
                    case "drawDone2": drawDone2(data[index]); break;
                    case "drawDone3": drawDone3(data[index]); break;
                    case "drawDone4": drawDone4(data[index]); break;
                    case "drawDone5": drawDone5(data[index]); break;
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
                next:next,
                drawAll:drawAll,
                ready:ready,
                reset:reset,
                setIndex:setIndex,
                getIndex:getIndex,
                getData:getData,
                isIndexSmallerData:isIndexSmallerData,
                isIndexBiggerData:isIndexBiggerData,
                getDataLength:getDataLength,
                getRestDataCount:getRestDataCount,
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

        //slow dodraw가 실행되면 일정 시간동안 얼마나 프레임을 스킵해줘야 그 시간이 되는지 계산
        private function getAutoJumpFrame(speed:Number):Number
        {
            const biasSpeed:Number = REPLAY_SLOWDRAW_ACTIVE_SPEED;
            const minTime:Number = TOTAL_FRAME/(biasSpeed*stage.frameRate);
            const subTime:Number = minTime-40;
            const subSpeed:Number = REPLAY_MAX_SPEED-biasSpeed;
            const unitTime:Number = subTime/subSpeed;
            const nowSpeed:Number = speed-biasSpeed;
            const newTime:Number = (subTime-unitTime*nowSpeed)+40;
            const newJumpFrame:Number = Math.floor(TOTAL_FRAME/newTime);

            return newJumpFrame;
        }

        private function setSlowDraw():void
        {
            replayStartON = true;
            doDrawSlowEventON = true;
            stage.removeEventListener(Event.ENTER_FRAME,doDrawEvent);
            rFileStream.close();
            stage.addEventListener(Event.ENTER_FRAME,doDrawSlowEvent);
        }

        private function doDrawSlowEvent(e:Event):void
        {
            if(rSpeed <= REPLAY_SLOWDRAW_ACTIVE_SPEED)
            {
                stage.removeEventListener(Event.ENTER_FRAME,doDrawSlowEvent);
                doDrawSlowEventON = false;
                replayStartON = false;
                startReplay();
                return;
            }

            const nowTime:int = getTimer();

            if(nowTime - rFrameTextDelayTime >= 500)
            {
                const nextFrame:Number = getAutoJumpFrame(rSpeed);
                const finalFrame:Number = rNowFrame+Math.floor(nextFrame/2);
                const totalF:Number = TOTAL_FRAME;
                const timeStr:String = getReplayRemainTime(nextFrame,totalF-rNowFrame,true);

                jumpFrame(finalFrame,JUMP_FRAME_ONCE);
                replayTimeBox["frameInfo"].text = rNowFrame+" / " + totalF + timeStr;
                rFrameTextDelayTime = nowTime;

                if(rNowFrame >= totalF)
                {
                    replayTimeBox["replayNowBar"].width = replayTimeBox["replayTotalBar"].width;
                    replayTimeBox["frameInfo"].text = TOTAL_FRAME+" / " +TOTAL_FRAME;
                    stopReplay();
                    replayCompleteEffect();
                    setRestartTimer();
                }
            }

            replayHideCursor.check();
        }

        private function doDrawEvent(e:Event):void
        {
            doDraw(rSpeed,JUMP_FRAME_PLAY);
            replayHideCursor.check();
        }

        private function clearRFrameCacheImages():void
        {
            rFrameCacheImages = [];
            rJumpImageIndexLast = -2;
            rCachedJumpImageIndexLast = -2;
        }

        private function getCacheImageLastFrame():Number
        {
            return rFrameCacheImages[rFrameCacheImages.length-1][6];
        }

        private function setCacheImageByIndex(index:uint,lastReadBytes:Number):void
        {
            rFrameCacheImages[index] = [rcanvas1BitmapData.clone()
                                        ,rcanvas11BitmapData.clone()
                                        ,rcanvas1BitmapData.width
                                        ,rcanvas1BitmapData.height
                                        ,RCANVAS_BG_COLOR
                                        ,lastReadBytes
                                        ,rNowFrame
                                        ,rMirrorON];
        }

        //jumpFlag  0: 기본 재생 1:탐색바를 마우스를 이용하여 스킵, 2:one frame 이전스트로크, 3:one frame 이후 스트로크
        private function cDoDraw():Function
        {
            //jumpFlag 1번은 마우스 커서로 무작위 스킵, 2,3번은 스트로크 단위혹은 프레임 단위로 앞뒤로 탐색
            var rDataLen:uint;
            var savedTime:int;
            var rFrameCursorDelayTime:int = 0; //커서 딜레이
            var _rFrameTextDelayTime:int = 0; //프레임 바 딜레이
            var getTimeStr:String;
            var timeStr:String;
            var readCount:Number = 0;
            var jumpImageGroupIndex:int;
            var nowJumpFlag:Boolean;

            function checkMakeCacheImage():void
            {
                if(rNowFrame > getCacheImageLastFrame() + REPLAY_JUMPIMAGE_CACHE_INTERVAL)
                {
                    setCacheImageByIndex(rFrameCacheImages.length,rFileCutBytes);
                }
            }

            function readyToReadRData(jumpFlag:int):void
            {
                rDataReadFlag = true;
                rIndex = rIndexStart;
                rIndexStart = 0;
                rDataLen = rData.length;

                if(jumpFlag === JUMP_FRAME_PLAY)
                {
                    rFileStream.close();
                    rLastBytePosition = 0;
                }

                if(rData.length > 0)
                {
                    rPrevFrame = rNowFrame;
                    tickDraw.ready(rData[rIndex]);
                }
                else
                {
                    tickDraw.reset();
                }
            }

            function setFileDataToTickDraw():Boolean
            {
                if(rFileStream.bytesAvailable > 0)
                {
                    const obj:Array = rFileStream.readObject() as Array;
                    if(!obj) return true;

                    tickDraw.ready(obj);
                    rFileCutBytes = rLastBytePosition;
                    rLastBytePosition = rFileStream.position;
                    rPrevFrame = rNowFrame;
                    return false;
                }
                return true;
            }

            function checkFinish(jumpFlag:int):Boolean
            {
                if(rIndex >= rDataLen || rDataLen === 0) //자연적 으로 끝났을때
                {
                    syncMirrorFinishReplayMode();

                    rCursor.visible = false;
                    playbackFinished = true;

                    if(jumpFlag === JUMP_FRAME_PLAY || doDrawSlowEventON === true)//1프레임 이상일때만 재시작 타이머 가동
                    {
                        //reset replay time해주지 말고 그냥 end플래그만 올려줌
                        //왜냐하면 리플레이 자연적으로 끝나고도 스킵프레임이나 oneframe jump을 해줄수가 있기 때문
                        replayTimeBox["replayNowBar"].width = replayTimeBox["replayTotalBar"].width;
                        replayTimeBox["frameInfo"].text = TOTAL_FRAME+" / " +TOTAL_FRAME;
                        stopReplay();//플레이 아이콘 내주지 말기
                        replayCompleteEffect();
                        setRestartTimer();
                        return true;
                    }
                }
                return false;
            }

            function updateCursorPosAndInfoText(jumpFlag:int):void
            {
                if(jumpFlag === JUMP_FRAME_PLAY || (doDrawSlowEventON && jumpFlag === JUMP_FRAME_ONCE))
                {
                    savedTime = getTimer();

                    if(savedTime-rFrameCursorDelayTime >= 66)
                    {
                        rFrameCursorDelayTime = savedTime;
                        tickDraw.updateRCursorPos();

                        if(!rFitZoomedON && !mouseClickON && !deepUndoON)
                        {
                            autoScroll.check(doDrawSlowEventON);
                        }

                        replayTimeBox["replayNowBar"].width = replayTimeBox["replayTotalBar"].width*(rNowFrame/TOTAL_FRAME);
                    }

                    if(savedTime-_rFrameTextDelayTime >= 1000) //갱신 느리게 해줌
                    {
                        _rFrameTextDelayTime = savedTime;
                        updateReplayRemainTimeText();
                    }
                }
                else if(doDrawSlowEventON === false)
                {
                    replayTimeBox["replayNowBar"].width = replayTimeBox["replayTotalBar"].width*(rNowFrame/TOTAL_FRAME);
                    updateReplayRemainTimeText();
                }
            }

            function drawRData(len:Number,jumpFlag:int):void
            {
                for(var i:Number=0;i<len;i++)
                {
                    if(tickDraw.isIndexBiggerData())
                    {
                        rIndex++;
                        if(checkFinish(jumpFlag)) return;
                        rPrevFrame = rNowFrame;
                        tickDraw.ready(rData[rIndex]);
                    }
                    tickDraw.next();
                    rNowFrame++;
                }
            }

            function drawFileData(len:Number,jumpFlag:int):void
            {
                for(var i:Number=0;i<len;i++)
                {
                    if(tickDraw.isIndexBiggerData())
                    {
                        // if(checkFinishDeepUndoLimit(jumpFlag)) return;
                        if(setFileDataToTickDraw())
                        {
                            //더이상 읽을 데이터가 없을때 rdata 읽기로 넘겨줌
                            readyToReadRData(jumpFlag);
                            return;
                        }
                        if(replayStartON === false && (jumpFlag === JUMP_FRAME_ONCE || jumpFlag === JUMP_FRAME_BEFORE))
                        {
                            checkMakeCacheImage();
                        }
                    }

                    tickDraw.next();
                    rNowFrame++;
                    readCount--;
                }
            }

            return function(jumpCount:Number,jumpFlag:int,replayModeON:Boolean=true):void
            {
                if(jumpCount > 0)
                {
                    //REPLAY_SLOWDRAW_ACTIVE_SPEED 이상으로 전체 재생 시간이 60초 이상일경우 작동
                    if(jumpFlag === JUMP_FRAME_PLAY && jumpCount > REPLAY_SLOWDRAW_ACTIVE_SPEED)
                    {
                        if(REPLAY_FASTEST_TOTAL_TIME > REPLAY_FASTEST_LIMIT_TIME)
                        {
                            setSlowDraw();
                            return;
                        }
                    }

                    readCount = jumpCount;
                    if(!rDataReadFlag) drawFileData(jumpCount,jumpFlag); //여기서 readcount 깍아주고
                    if(readCount > 0) drawRData(readCount,jumpFlag); //나머지 readcount를 여기서해줌
                }
                //playbackFinished 해주는 이유는 drawRdta에서 이미 checkfinish해줬는데
                //여기 밑까지 계속 함수를 읽어줘서 캔버스가 이동되어버리는 현상이 있어서 체크해줘야함
                if(!playbackFinished)
                {
                    updateCursorPosAndInfoText(jumpFlag);
                }
            }
        }

        private function getReplayRemainTime(speed:Number,totalFrame:Number,slowFrame:Boolean=false):String
        {
            const fps:Number = (slowFrame === true) ? 1:stage.frameRate;
            const totalSec:Number = totalFrame/(fps*speed);
            if(totalSec === 0) return "";

            const hour:int = totalSec/3600;
            const min:int = totalSec%3600/60;
            const sec:int = totalSec%60;
            var timeStr:String = "";

            if(hour > 0) timeStr += hour +":";

            if(min > 0) timeStr += (min >= 10) ? min+":" : "0"+min+":";
            else timeStr = "00:";

            if(sec > 0) timeStr += (sec >= 10) ? sec : "0"+sec;
            else timeStr += "00";

            if(hour === 0 && min === 0 && sec === 0)
            {
                const milisec:Number = totalSec-Math.floor(totalSec);
                const milisecStr:String = milisec.toFixed(1);

                return " ("+milisecStr+")";
            }

            return " ("+timeStr+")";
        }

        private function cAutoScroll():Object
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
            const topLimit:Number = padding+topBar.BARSIZE+replayTimeBox.BARSIZE;
            var rightLimit:Number;
            var bottomLimit:Number;

            function updateScale(newScale:Number):void
            {
                scale = newScale;
            }

            function updateRCanvasBounds():void
            {
                bounds = getBoundRect(rcanvas1Bitmap);
                left = bounds.left;
                right = bounds.right;
                top = bounds.top;
                bottom = bounds.bottom;
                stw = stage.stageWidth;
                sth = stage.stageHeight-(topBar.BARSIZE+replayTimeBox.BARSIZE)*scale;
                zoom = rzoomed;

                isCanvasWidthSmallerStage = right-left < stw;
                isCanvasHeightSmallerStage = bottom-top < sth;
                //캔버스 중점위치, 창 중점위치 사이 거리
                windowCenterPos.setTo(Math.floor(stw/2-(right+left)/2),Math.floor((topBar.BARSIZE+replayTimeBox.BARSIZE)*scale+sth/2-(bottom+top)/2));
                isNotCenterX = Math.abs(windowCenterPos.x) > 0; //캔버스 중점위치, 창 중점위치 사이 거리
                isNotCenterY = Math.abs(windowCenterPos.y) > 0;

                rightLimit = stw-padding;
                bottomLimit = sth+topBar.BARSIZE+replayTimeBox.BARSIZE-padding;
            }

            function check(viewCenterFlag:Boolean):void
            {
                cp = tickDraw.getRCursorPos();

                globalChecked = false;
                const div:Number = (viewCenterFlag) ? 1:3;

                if(isCanvasWidthSmallerStage)
                {
                    if(isNotCenterX)
                    {
                        rregPoint.x += windowCenterPos.x;
                        updateRCanvasBounds();
                    }
                }
                else
                {
                    globalChecked = true;
                    gp = rcanvas1Bitmap.localToGlobal(ZERO_POINT);
                    rg = rotatePoint(cp.x,cp.y,-rregPoint.rotation);
                    cursorPos.x = gp.x+(rg.x*zoom);

                    if(cursorPos.x < leftLimit)
                    {
                        rregPoint.x += Math.floor(Math.abs((cursorPos.x-stw/2)/div));
                        updateRCanvasBounds();
                    }
                    else if(cursorPos.x > rightLimit)
                    {
                        rregPoint.x -= Math.floor(Math.abs((cursorPos.x-stw/2)/div));
                        updateRCanvasBounds();
                    }
                }

                if(isCanvasHeightSmallerStage)
                {
                    if(isNotCenterY)
                    {
                        rregPoint.y += windowCenterPos.y;
                        updateRCanvasBounds();
                    }
                }
                else
                {
                    if(globalChecked === false)
                    {
                        globalChecked = true;
                        gp = rcanvas1Bitmap.localToGlobal(ZERO_POINT);
                        rg = rotatePoint(cp.x,cp.y,-rregPoint.rotation);
                    }
                    cursorPos.y = gp.y+(rg.y*zoom);

                    if(cursorPos.y < topLimit)
                    {
                        rregPoint.y += Math.floor(Math.abs((cursorPos.y-sth/2)/div));
                        updateRCanvasBounds();
                    }
                    else if(cursorPos.y > bottomLimit)
                    {
                        rregPoint.y -= Math.floor(Math.abs((cursorPos.y-sth/2)/div));
                        updateRCanvasBounds();
                    }
                }
            }

            return {
                check:check,
                updateRCanvasBounds:updateRCanvasBounds,
                updateScale:updateScale
            };
        }

        private function isSlowDrawTime(speed:Number):Boolean
        {
            return speed > REPLAY_SLOWDRAW_ACTIVE_SPEED
                                 && REPLAY_FASTEST_TOTAL_TIME > REPLAY_FASTEST_LIMIT_TIME;
        }

        private function updateReplayRemainTimeText():void
        {
            var xRSpeed:Number = (isSlowDrawTime(rSpeed))
                                 ? getAutoJumpFrame(rSpeed)/stage.frameRate : rSpeed;
                                //오토스킵은 1초마다 넘어가야할 프레임이니까 시간 구하려면 스테이지 프레임을 나누어줌

            const rFrameSave:Number = rNowFrame;
            const xNamojiTime:String = (deepUndoON)
                                       ? "" : getReplayRemainTime(xRSpeed,TOTAL_FRAME-rFrameSave);
            replayTimeBox["frameInfo"].text = rFrameSave+" / " + TOTAL_FRAME + xNamojiTime;
        }

        private function getReplayTotalTime(_speed:uint):String
        {
            var timeStr:String;
            if(isSlowDrawTime(_speed))
            {
                _speed = getAutoJumpFrame(_speed);
                timeStr = getReplayRemainTime(_speed,TOTAL_FRAME,true);
            }
            else
            {
                timeStr = getReplayRemainTime(_speed,TOTAL_FRAME);
            }

            return timeStr;
        }

        private function setReplayRepeatButton():void
        {
            replayRepeatON = !replayRepeatON;

            if(replayRepeatON)
            {
                topBar.replayRepeatButton.alpha = 1.0;
                if(rNowFrame >= TOTAL_FRAME)
                {
                    setColorTransform(replayTimeBox["replayNowBar"],uiColorSet[uiColorIndex][5]);
                    setRestartTimer();
                }
            }
            else
            {
                topBar.replayRepeatButton.alpha = BUTTON_OFF_ALPHA;
            }
        }

        private function setReplaySpeedButton():void
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
            const clacMax:Number = Math.floor(totalF/(stage.frameRate*3));//3초 x 30프레임
            var max:Number = (clacMax > maxSpeed) ? maxSpeed : clacMax;//최고 속도 3초 재생 이지만 REPLAY_MAX_SPEED배속은 넘기지 않음.
            var timeStr:String = getReplayTotalTime(rSpeed);
            var oldSpeed:uint;

            penCursorOFFFlag = true;
            mouseDragON = true;

            function setSpeed(mx:Number):void
            {
                var exp:Number = mx/maxDist;

                if(exp < 0) exp = 0;
                else if(exp > 1) exp = 1;

                var nowSpeed:uint = Math.floor(Math.pow(max,exp));

                if(oldSpeed !== nowSpeed)
                {
                    oldSpeed = nowSpeed;
                    if(nowSpeed > max) nowSpeed = max;

                    timeStr = getReplayTotalTime(nowSpeed);
                    rSpeed = nowSpeed;

                    const finalStr:String = STRING_PLAYBACK_SPEED+nowSpeed+timeStr;
                    setHintONTemp(finalStr);
                    rSpeedLastStr = finalStr;
                }
            }

            function moveButton(mx:Number):void
            {
                if(mx < minDist) mx = minDist;
                else if(mx > maxDist) mx = maxDist;

                topBar.replaySpeedSliderCursor.x = mx;
                setSpeed(mx);
            }

            function replaySpeedButtomUpEvent(e:MouseEvent):void
            {
                mouseDragON = false;
                if(playbackFinished === false) updateReplayRemainTimeText();
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,replaySpeedButtomMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,replaySpeedButtomUpEvent);
            }

            function replaySpeedButtomMoveEvent(e:MouseEvent):void
            {
                moveButton(topBar.replaySpeedSliderWrapper.mouseX);
            }

            moveButton(topBar.replaySpeedSliderWrapper.mouseX);
            setSpeed(topBar.replaySpeedSliderWrapper.mouseX);

            stage.addEventListener(MouseEvent.MOUSE_MOVE, replaySpeedButtomMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,replaySpeedButtomUpEvent);
        }

        private function getNowFrameUntilUndoIndex(index:int):Number
        {
            return undoData.getRFileTotalFrame()+undoData.getRDataTotalFrame(index);
        }

        private function getTotalFrame():Number
        {
            return getNowFrameUntilUndoIndex(rDataFrame.length-1);
        }

        private function getNearZoomIndex(nowZoom:Number):int
        {
            var low:int = 0;
            var high:int = zoomList.length-1;
            if(high <= 0) return high;
            var index:int = Math.floor((low+high)/2);

            while(low <= high)//2진 탐색
            {
                if(zoomList[index] === nowZoom) break;
                else if(zoomList[index] > nowZoom) high = index-1;
                else low = index+1;

                index = Math.floor((low + high)/2);
            }

            //가장 가까운값 검출
            if(index <= 0) return 0;
            else if(index >= zoomList.length-1) return zoomList.length-1;
            else if(zoomList[index+1]-nowZoom < nowZoom-zoomList[index-1])
            {
                //현재줌이 상위 줌이랑 더 가까우면 인덱스를 올려줌
                return index+1;
            }
            return index;
        }

        //targetFrame이 rFrameCacheImages데이터에 몆 번 인덱스에 있나 구해줌
        private function getCacheImageIndex(targetFrame:Number):Number
        {
            var low:Number = 0;
            var high:Number = rFrameCacheImages.length-1;
            if(high <= 0) return high;
            var index:Number = Math.floor((low+high)/2);

            while(low <= high)//2진 탐색
            {
                if(rFrameCacheImages[index][6] === targetFrame) break;
                else if(rFrameCacheImages[index][6] > targetFrame) high = index-1;
                else low = index+1;

                index = Math.floor((low + high)/2);
            }

            return index;
        }

        //targetFrame이 rJumpImageFrameData데이터에 몆 번 인덱스에 있나 구해줌
        private function getJumpImageIndex(targetFrame:Number):Number
        {
            var low:Number = 0;
            var high:Number = rJumpImageFrameData.length-1;
            if(high <= 0) return high;
            var index:Number = Math.floor((low + high)/2);

            while(low <= high)//2진 탐색
            {
                if(rJumpImageFrameData[index] === targetFrame) break;
                else if(rJumpImageFrameData[index] > targetFrame) high = index-1;
                else low = index+1;

                index = Math.floor((low + high)/2);
            }

            return index;
        }

        //프레임에 따라서 프레임 조작 버튼 활성화 해줌
        private function checkCutFrameButtonsCanUse():void
        {
            if(makeJumpImageFlag === 2 || isInSaveProgress || replayStartON)
            {
                topBar["superUndoButton"].alpha = BUTTON_OFF_ALPHA;
                topBar["cutPrevDataButton"].alpha = BUTTON_OFF_ALPHA;
                topBar["reRecordingButton"].alpha = BUTTON_OFF_ALPHA;
            }
            else
            {
                topBar["reRecordingButton"].alpha = 1.0;

                if(rNowFrame > 0 && rNowFrame < TOTAL_FRAME)
                {
                    topBar["superUndoButton"].alpha = 1.0;
                    topBar["cutPrevDataButton"].alpha = 1.0;
                }
                else
                {
                    topBar["superUndoButton"].alpha = BUTTON_OFF_ALPHA;
                    topBar["cutPrevDataButton"].alpha = BUTTON_OFF_ALPHA;
                }
            }
        }

        private function jumpOneFrame(toBackFlag:Boolean,trueOneFrame:Boolean):void
        {
            if(trueOneFrame)
            {
                if(toBackFlag)
                {
                    if(rNowFrame > 0) jumpFrame(rNowFrame-1,JUMP_FRAME_ONCE);
                }
                else if(rNowFrame < TOTAL_FRAME)
                {
                    jumpFrame(rNowFrame+1,JUMP_FRAME_ONCE);
                }
            }
            else
            {
                if(toBackFlag)
                {
                    if(rNowFrame > 0)
                    {
                        jumpFrame(rPrevFrame,JUMP_FRAME_BEFORE);
                    }
                }
                else if(rNowFrame <= TOTAL_FRAME)
                {
                    if(tickDraw.getRestDataCount() === 0)
                    {
                        //+1해줘서 다음 데이터 갱신해주고 나머지 끝까지 그려줌
                        jumpFrame(rNowFrame+1,JUMP_FRAME_AFTER);
                        jumpFrame(rNowFrame+tickDraw.getRestDataCount(),JUMP_FRAME_AFTER);
                    }
                    else
                    {
                        jumpFrame(rNowFrame+tickDraw.getRestDataCount(),JUMP_FRAME_AFTER);
                    }
                }
            }

            rOnejumpFlagSave = toBackFlag;
            checkCutFrameButtonsCanUse();

            if(rNowFrame === TOTAL_FRAME)
            {
                setColorTransform(replayTimeBox["replayNowBar"],uiColorSet[uiColorIndex][4]);
            }
            else
            {
                replayTimeBox.resetNowbarColor();
            }
        }

        private function addCancelAutoKeyEvent():void
        {
            stage.nativeWindow.addEventListener(Event.DEACTIVATE,cancelAutoKeyEvent);
            stage.addEventListener(MouseEvent.MOUSE_DOWN,cancelAutoKeyEvent);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,cancelAutoKeyEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,cancelAutoKeyEvent);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,cancelAutoKeyEvent);
            stage.addEventListener(KeyboardEvent.KEY_UP,cancelAutoKeyEvent);
        }

        private function cancelAutoKeyEvent(e:Object):void
        {
            removeTimer("keyHoldWaitTimer");
            removeTimer("keyHoldRepeatTimer");
            stage.nativeWindow.removeEventListener(Event.DEACTIVATE,cancelAutoKeyEvent);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,cancelAutoKeyEvent);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,cancelAutoKeyEvent);
            stage.removeEventListener(MouseEvent.MOUSE_UP,cancelAutoKeyEvent);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,cancelAutoKeyEvent);
            stage.removeEventListener(KeyboardEvent.KEY_UP,cancelAutoKeyEvent);
        }

        private function setJumpOneFrame(toBackFlag:Boolean,oneFrame:Boolean=false):void
        {
            playbackFinished = false;
            if(replayStartON) stopReplay();

            setHoldKeyRepeat(true,jumpOneFrame,toBackFlag,oneFrame);
        }

        private function jumpFrame(frame:Number,jumpflag:int):void //jumpp
        {
            if(frame < 0) frame = 0;
            else if(frame > TOTAL_FRAME) frame = TOTAL_FRAME;

            if(replayModeON)
            {
                if(frame >= TOTAL_FRAME && playbackFinished)
                {
                    return;
                }
            }

            const index:Number = getJumpImageIndex(frame);
            var cachedJumpImageIndex:Number = -1; //자잘 썸네일 인덱스를 넣어줌
            var updateRCavanvasImageFlag:int = 0;

            rFileStream.open(repFile,FileMode.READ);

            if(index !== rJumpImageIndexLast)
            {
                clearRFrameCacheImages();
                updateRCavanvasImageFlag = 1;
            }
            else if(rFrameCacheImages.length > 0)
            {
                if(frame >= rFrameCacheImages[0][6])
                {
                    cachedJumpImageIndex = getCacheImageIndex(frame);
                    if(rCachedJumpImageIndexLast !== cachedJumpImageIndex || frame < rNowFrame)
                    {
                        updateRCavanvasImageFlag = 2;
                    }
                }
            }

            var drawFrameCount:Number = 0.0;
            //미리 찍어둔 이미지로 캔버스를 설정
            if(updateRCavanvasImageFlag > 0 || frame < rNowFrame)
            {
                var jumpImageData:Array;
                var tempBmpd:BitmapData;
                var tempBmpd1:BitmapData;
                var newrect:Rectangle;

                if(updateRCavanvasImageFlag === 2)
                {
                    jumpImageData = rFrameCacheImages[cachedJumpImageIndex];
                    tempBmpd = jumpImageData[0];
                    tempBmpd1 = jumpImageData[1];
                    rCachedJumpImageIndexLast = cachedJumpImageIndex;
                }
                else
                {
                    const file:File = rJumpImageFolder.resolvePath(index+"");
                    const fs:FileStream = new FileStream();

                    fs.open(file,FileMode.READ);
                    jumpImageData = fs.readObject() as Array;
                    fs.close();
                    jumpImageData[0].uncompress();
                    jumpImageData[1].uncompress();

                    newrect = new Rectangle(0,0,jumpImageData[2],jumpImageData[3]);
                    tempBmpd = new BitmapData(jumpImageData[2],jumpImageData[3],true,0);
                    tempBmpd.lock();
                    tempBmpd.setPixels(newrect,jumpImageData[0]);
                    tempBmpd.unlock();

                    tempBmpd1 = new BitmapData(jumpImageData[2],jumpImageData[3],true,0);
                    tempBmpd1.lock();
                    tempBmpd1.setPixels(newrect,jumpImageData[1]);
                    tempBmpd1.unlock();

                    jumpImageData[0].clear();
                    jumpImageData[0] = null;
                    jumpImageData[1].clear();
                    jumpImageData[1] = null;
                    rJumpImageNowFrameLast = jumpImageData[6];
                }

                rJumpImageIndexLast = index;
                rLastBytePosition = jumpImageData[5]; //마지막 바이트
                rFileStream.position = jumpImageData[5];
                rNowFrame = jumpImageData[6]; //썸네일 이미지를 저장한 프레임
                //원하는 프레임에서 썸네일 이미지 프레임을 빼줌 나머지 프레임만 그려주면 되니깐
                drawFrameCount = frame-jumpImageData[6];
                rIndex = 0; //이거 먼저 초기화 시켜주어야함
                tickDraw.reset();
                clearCanvasReplayMode();
                rMirrorON = jumpImageData[7];

                if(rcanvas1BitmapData && tempBmpd !== rcanvas1BitmapData) rcanvas1BitmapData.dispose();
                rcanvas1BitmapData = tempBmpd.clone();
                rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;

                if(rcanvas11BitmapData && tempBmpd1 !== rcanvas11BitmapData) rcanvas11BitmapData.dispose();
                rcanvas11BitmapData = tempBmpd1.clone();
                rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;

                changeCanvasSizeReplayMode(rcanvas1Bitmap.width,rcanvas1Bitmap.height);
                setBackgroundColorReplayMode(jumpImageData[4]);

                if(updateRCavanvasImageFlag === 1 && replayStartON === false)
                {
                    setCacheImageByIndex(0,rLastBytePosition);
                }

                jumpImageData = null;
                rDataReadFlag = false;
                rIndexStart = 0;
                if(updateRCavanvasImageFlag !== 2)
                {
                    tempBmpd.dispose();
                    tempBmpd1.dispose();
                    tempBmpd = null;
                    tempBmpd1 = null;
                }
            }
            else
            {
                if(!rDataReadFlag) rFileStream.position = rLastBytePosition;
                drawFrameCount = frame - rNowFrame;
            }

            //그려줘야할 프레임이 0이면 rPrevFrame갱신이 안되니까 여기서 해줌
            if(drawFrameCount === 0.0)
            {
                rPrevFrame = frame-1;
            }

            doDraw(drawFrameCount,jumpflag,replayModeON);
            rFileStream.close();
            //dodraw밑이기 때문에 rFrameSum이 갱신되서 위에 nowFrame은 쓸수가 없음
            if(rNowFrame >= TOTAL_FRAME)
            {
                if(replayModeON)
                {
                    if(!playbackFinished)
                    {
                        playbackFinished = true;
                        syncMirrorFinishReplayMode();
                    }
                    rCursor.visible = false;
                }

                tickDraw.updateRCursorPos();
            }
            else
            {
                playbackFinished = false;
                tickDraw.updateRCursorPos();
                rCursor.visible = true;
            }

            if(!doDrawSlowEventON && !rFitZoomedON && !deepUndoON)
            {
                autoScroll.check(true);
            }
        }

        //데이터를 읽다 말았으면 끝까지 한세트 끝나게 프레임 이동시킴
        private function drawRemainReplayData():void
        {
            jumpFrame(rNowFrame+tickDraw.getRestDataCount(),JUMP_FRAME_ONCE);
            rOnejumpFlagSave = false;
        }

        private function setJumpFrameButton():void
        {
            const totalF:Number = TOTAL_FRAME;

            if(totalF === 0 || makeJumpImageFlag > 0)
            {
                return;
            }

            //리플레이 플레이 중인지 아닌지 플래그 미리 저장해둠
            var replayStartONSave:Boolean = false;
            if(replayStartON)
            {
                replayStartONSave = true;
                replayStartON = false;
                stage.removeEventListener(Event.ENTER_FRAME,doDrawEvent);
                stage.removeEventListener(Event.ENTER_FRAME,doDrawSlowEvent);
                rFileStream.close();
            }

            var clickedX:Number = replayTimeBox["replayTotalBar"].mouseX*replayTimeBox["replayTotalBar"].scaleX;
            var oldFrame:Number = Math.floor(totalF*clickedX/replayTimeBox["replayTotalBar"].width);
            var finalFrame:Number = 0;

            mouseDragON = true;
            replayTimeBox["replayNowBar"].width = clickedX;
            checkBarLimit();
            oldFrame = finalFrame;
            doDrawSlowEventON = false;
            playbackFinished = false;
            replayTimeBox.resetNowbarColor();
            replayHideCursor.check();

            function checkBarLimit():void
            {
                var mx:Number = replayTimeBox["replayTotalBar"].mouseX*replayTimeBox["replayTotalBar"].scaleX;

                if(mx < 0) mx = 0;
                else if(mx > replayTimeBox["replayTotalBar"].width) mx = replayTimeBox["replayTotalBar"].width;

                finalFrame = Math.floor(totalF*mx/replayTimeBox["replayTotalBar"].width);
                replayTimeBox["replayNowBar"].width = mx;
            }

            function replayTimeMouseUpEvent(e:MouseEvent):void
            {
                mouseDragON = false;
                removeTimer("jumpFrameUpdateTimer");
                jumpFrame(finalFrame,JUMP_FRAME_ONCE);
                oldFrame = finalFrame;
                checkBarLimit();

                //jumpframe함수 이후에 실행
                checkCutFrameButtonsCanUse();

                //재생중에 스킵하고 있었으면 다시 시작
                if(replayStartONSave && !playbackFinished)
                {
                    startReplay();
                }
                else if(playbackFinished)
                {
                    replayTimeBox["replayNowBar"].width = replayTimeBox["replayTotalBar"].width;
                    replayTimeBox["frameInfo"].text = TOTAL_FRAME+" / " +TOTAL_FRAME;
                    stopReplay();
                }

                if(rNowFrame === TOTAL_FRAME)
                {
                    setColorTransform(replayTimeBox["replayNowBar"],uiColorSet[uiColorIndex][4]);
                }

                stage.removeEventListener(MouseEvent.MOUSE_MOVE,replayTimeMouseMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,replayTimeMouseUpEvent);
            }

            function replayTimeMouseMoveEvent(e:MouseEvent):void
            {
                checkBarLimit();

                if(!hasTimer("jumpFrameUpdateTimer"))
                {
                    addTimerByName("jumpFrameUpdateTimer",0.25,false,function():void
                    {
                        oldFrame = finalFrame;
                        jumpFrame(finalFrame,JUMP_FRAME_ONCE);
                    });
                }
            }

            stage.addEventListener(MouseEvent.MOUSE_UP,replayTimeMouseUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, replayTimeMouseMoveEvent);
        }

        private function stopReplay():void
        {
            stage.removeEventListener(Event.ENTER_FRAME,doDrawEvent);
            stage.removeEventListener(Event.ENTER_FRAME,doDrawSlowEvent);

            replayTimeBox["playButton"].visible = true;
            replayTimeBox["pauseButton"].visible = false;

            rFileStream.close();

            replayStartON = false;
            doDrawSlowEventON = false;
            checkCutFrameButtonsCanUse();
            replayHideCursor.reset();
        }

        private function startReplay():void
        {
            if(replayStartON || TOTAL_FRAME === 0)
            {
                return; //혹시 몰라서 중복 클릭 제거 걸어줌
            }

            replayStartON = true;

            replayTimeBox.resetNowbarColor();
            replayTimeBox["playButton"].visible = false;
            replayTimeBox["pauseButton"].visible = true;
            checkCutFrameButtonsCanUse();

            rCursor.visible = true;

            if(playbackFinished === true) //리플레이 시간 등등 초기화 시키고 시작
            {
                rMirrorON = false;
                resetReplayTime();
                clearCanvasReplayMode();
                drawFirstJumpImage();
                rDataReadFlag = false;
                playbackFinished = false;//resetReplayTime함수 에서 이걸 true로 해주기 때문에 아래쪽에서 변경
                // resetRotationReplayMode();

                if(!rFitZoomedON)
                {
                    restoreZoomReplayMode();
                }

                autoScroll.updateRCanvasBounds();
                selectReplaySubLayer(false);
            }

            if(replayEndWithCanvasFitWindow === true)
            {
                replayEndWithCanvasFitWindow = false;
                rzoomedIndex = getNearZoomIndex(rzoomed);
                setZoomCanvas(rzoomed,true);
            }

            if(!rDataReadFlag)
            {
                rFileStream.open(repFile,FileMode.READ);
                rFileStream.position = rLastBytePosition;
            }

            if(rFitZoomedON) fitCanvasToWindowManualReplayMode();

            clearRFrameCacheImages();


            stage.addEventListener(Event.ENTER_FRAME,doDrawEvent);
        }

        private function setToolBoxPos(target:DisplayObject):void
        {
            const click:Point = new Point(mouseX,mouseY);
            setTopChildIndex(target);

            function toolBoxMoveMouseUpEvent(e:MouseEvent):void
            {
                checkBoxPosition(target);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,toolBoxMoveMouseMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP, toolBoxMoveMouseUpEvent);
            }

            function toolBoxMoveMouseMoveEvent(e:MouseEvent):void
            {
                target.x = Math.floor(target.x+mouseX-click.x);
                target.y = Math.floor(target.y+mouseY-click.y);

                click.x = mouseX;
                click.y = mouseY;
            }

            stage.addEventListener(MouseEvent.MOUSE_MOVE, toolBoxMoveMouseMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,toolBoxMoveMouseUpEvent);
        }

        private function checkToolBoxMouseUp(targetName:String):void
        {
            function checkToolBoxButtonUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP,checkToolBoxButtonUpEvent);

                const upTargetName:String = e.target.name;

                if(upTargetName !== targetName) return;

                switch(upTargetName)
                {
                    case "toolPen":
                    {
                        if(!isNowTool(TOOL_PEN))
                        {
                            selectPenTool();
                            updatePenSizeCursor();
                        }
                    }
                    break;

                    case "toolFillPen":
                    {
                        if(!isNowTool(TOOL_FILL_PEN))
                        {
                            selectFillPenTool();
                            updatePenSizeCursor();
                        }
                    }
                    break;

                    // case "toolScanFill":
                    // {
                    //     if(!isNowTool(TOOL_SCAN_FILL))
                    //     {
                    //         selectScanFillTool();
                    //         updatePenSizeCursor();
                    //     }
                    // }
                    // break;

                    case "toolErase":
                    {
                        if(!isNowTool(TOOL_ERASE))
                        {
                            selectEraseTool();
                            updatePenSizeCursor();
                        }
                    }
                    break;

                    case "toolLine":
                    {
                        if(!isNowTool(TOOL_LINE))
                        {
                            selectLineTool();
                            updatePenSizeCursor();
                        }
                    }
                    break;

                    case "toolLasso":
                    {
                        if(!isNowTool(TOOL_LASSO))
                        {
                            selectLassoTool();
                        }
                    }
                    break;

                    case "toolSpuit":
                    {
                        if(quickSidebarON)
                        {
                            resetOldTool();
                            toolBox.moveToolCursor("toolSpuit");
                        }
                        else if(!isNowTool(TOOL_SPUIT))
                        {
                            spuitTool();
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

                    case "zoomInButton":
                    {
                        setZoomInButton(true,false);
                    }
                    break;

                    case "zoomOutButton":
                    {
                        setZoomInButton(false,false);
                    }
                    break;

                    case "toolTrace":
                    {
                        if(quickSidebarON) _quickSidebarOFF();

                        if(traceMenuON === false)
                        {
                            openTraceWindow();
                            traceMenu.y = mouseY-60;
                        }
                    }
                    break;
                }
            }
            //undo키 반복이 있어서 우선순위 1로 약간 높여줌
            stage.addEventListener(MouseEvent.MOUSE_UP,checkToolBoxButtonUpEvent,false,1);
        }

        private function _setBackgroundColor(xCanvas:Sprite,w:Number,h:Number,color:uint):void
        {
            xCanvas.graphics.clear();
            xCanvas.graphics.beginFill(color);
            xCanvas.graphics.drawRect(0,0,w,h);
            xCanvas.graphics.endFill();
        }

        private function setBackgroundColorReplayMode(color:uint):void
        {
            RCANVAS_BG_COLOR = color;
            _setBackgroundColor(rcanvasPanel,RCANVAS_WIDTH,RCANVAS_HEIGHT,color);
        }

        private function setBackgroundColorDrawMode(color:uint):void
        {
            saveOneTime = false;
            CANVAS_BG_COLOR = color;
            previewBox.changeprevBitmapBGColor(color);
            _setBackgroundColor(canvasPanel,CANVAS_WIDTH,CANVAS_HEIGHT,color);
            if( pickerBox.scratchPad)
            {
                pickerBox.scratchPad.updateBGColor(color);
            }
        }

        private function toolTipBoxTimerOFF():void
        {
            removeTimer("toolTipTempONTimer");
            setToolTipOFF();
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,toolTipBoxTimerOFFEvent);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,toolTipBoxTimerOFFEvent);
        }

        private function toolTipBoxTimerOFFEvent(e:MouseEvent):void
        {
            toolTipBoxTimerOFF();
        }

        private function setToolTipTempON(str:String,time:Number=2.5):void
        {
            if(!hasTimer("toolTipTempONTimer"))
            {
                stage.addEventListener(MouseEvent.MOUSE_DOWN,toolTipBoxTimerOFFEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,toolTipBoxTimerOFFEvent);
            }

            addTimerByName("toolTipTempONTimer",time,false,function():void
            {
                toolTipBoxTimerOFF();
            });

            setToolTipString(str);
            setToolTipON();
        }

        private function setToolTipOFF():void
        {
            toolTipBox.visible = false;
        }

        private function setToolTipON():void
        {
            toolTipBox.visible = true;
        }

        // private function setToolTipString(str:String):void
        // {
        //     if(str !== "")
        //     {
        //         toolTipBox.setText(str);
        //     }

        //     const scale:Number = getUIScale();
        //     const stw:uint = stage.stageWidth+1;
        //     const sth:uint = stage.stageHeight+1;
        //     const rightLimit:Number = stw;
        //     const bottomLimit:Number = sth;
        //     const width:Number = toolTipBox.toolTipInfoText.width*scale;
        //     const height:Number = toolTipBox.toolTipInfoText.height*scale;
        //     var tooltipX:Number = Math.floor(mouseX-width/2)+5;
        //     var tooltipY:Number = Math.floor(mouseY-45*scale);
        //     const right:int = tooltipX+width;
        //     const bottom:int = tooltipY+height;

        //     if(tooltipX < 0) tooltipX = 0;
        //     else if(right > rightLimit) tooltipX = rightLimit-width;

        //     if(tooltipY < 0) tooltipY = 0;
        //     else if(bottom >= bottomLimit) tooltipY = bottomLimit-height;

        //     toolTipBox.x = Math.floor(tooltipX);
        //     toolTipBox.y = Math.floor(tooltipY);
        //     setTopChildIndex(toolTipBox);
        // }
        private function setToolTipString(str:String):void
        {
            if(str !== "")
            {
                toolTipBox.setText(str);
            }

            const scale:Number = getUIScale();
            const stw:uint = stage.stageWidth+1;
            const sth:uint = stage.stageHeight+1;
            const rightLimit:Number = stw;
            const bottomLimit:Number = sth;
            const width:Number = toolTipBox.toolTipInfoText.width*scale;
            const height:Number = toolTipBox.toolTipInfoText.height*scale;
            var tooltipX:Number = Math.floor(mouseX-width/2)+5;
            var tooltipY:Number = Math.floor(mouseY-45*scale);
            const right:int = tooltipX+width;
            const bottom:int = tooltipY+height;

            if(tooltipX < 0) tooltipX = 0;
            else if(right > rightLimit) tooltipX = rightLimit-width;

            if(tooltipY < 0) tooltipY = 0;
            else if(bottom >= bottomLimit) tooltipY = bottomLimit-height;

            toolTipBox.x = Math.floor(tooltipX);
            toolTipBox.y = Math.floor(tooltipY);
            setTopChildIndex(toolTipBox);
        }

        //drag load
        private function setDragDropSelectBoxCenterPos():void
        {
            loadMenuBox["dragDropFileBG"].x = 0;
            loadMenuBox["dragDropFileBG"].y = 0;
            loadMenuBox["dragDropFileBG"].width = 1;
            loadMenuBox["dragDropFileBG"].height = 1;
            // loadMenuBox.scaleX = 1.0;
            // loadMenuBox.scaleY = 1.0;

            const stw:Number = stage.stageWidth;
            const sth:Number = stage.stageHeight;
            const f1:Number = stw/loadMenuBox.width; //가장 짧은 길이를 기준으로 비율을 삼음
            const f2:Number = sth/loadMenuBox.height;
            const f:Number = (f1 <= f2) ? f1:f2;
            // loadMenuBox.scaleX = 1.0;
            // loadMenuBox.scaleY = 1.0;
            loadMenuBox.x = stw/2 - loadMenuBox.width/2;
            loadMenuBox.y = sth/2 - loadMenuBox.height/2;
            loadMenuBox["dragDropFileBG"].x = -loadMenuBox.x;
            loadMenuBox["dragDropFileBG"].y = -loadMenuBox.y;
            loadMenuBox["dragDropFileBG"].width = stw;
            loadMenuBox["dragDropFileBG"].height = sth;
        }

        private function keyDownLoadBox(e:KeyboardEvent):void
        {
            if(e.keyCode === KEY.esc || e.keyCode === KEY.backspace)
            {
                setLoadBoxVisible(false);
            }
        }

        private function setLoadBoxReady(pleaseWaitFlag:Boolean,traceLayer:Boolean):void
        {
            resetKeyBuffer();

            if(loadMenuBox.visible === false)
            {
                if(lassoToolON === true)
                {
                    setLassoCancelButton();
                    resetLassoBox();
                    resetOldTool();
                    selectPenTool();
                }

                loadMenuBox.changeUIColor(uiToolBoxColorSet[uiColorIndex]);
                loadMenuBox.setPleaseWait(pleaseWaitFlag);
                loadMenuBox.setRefLayerLoadMode(traceLayer);
                setLoadBoxVisible(true);
                setTopChildIndex(loadMenuBox);
            }

            closeToolBox2();
        }

        private function setClipboardButton(traceLayer:Boolean):void
        {
            if(isInSaveProgress) return;

            rFileStream.close();
            cancelRestartTimer();

            const data:* = getSystemClipboardData();

            if(data)
            {
                if(data is BitmapData)
                {
                    tempCopiedImage = data as BitmapData;
                    loadMenuBox.setRefLayerLoadMode(false);
                    loadMenuBox.setPreviewImage(tempCopiedImage);
                    setLoadBoxReady(false,traceLayer);
                }
                else if(data is Array)
                {
                    loadMenuBox.setRefLayerLoadMode(false);
                    setDragDropPreviewImageReady(data[0] as File,traceLayer);
                }
            }
        }

        private function getSystemClipboardData():*
        {
            return Clipboard.generalClipboard.getData(ClipboardFormats.BITMAP_FORMAT)
            || Clipboard.generalClipboard.getData(ClipboardFormats.FILE_LIST_FORMAT);
        }

        private function setClipboardButtonNotAvailable():void
        {
            topBar["clipButton"].alpha = BUTTON_OFF_ALPHA;
            traceMenu["traceClipButton"].alpha = BUTTON_OFF_ALPHA;
            isClipBoardButtonAvailable = false;
        }

        private function setClipboardButtonAvailable():void
        {
            topBar["clipButton"].alpha = 1.0;
            traceMenu["traceClipButton"].alpha = 1.0;
            isClipBoardButtonAvailable = true;
        }

        private function checkClipBoardImage():void
        {
            const data:* = getSystemClipboardData();

            if(data is BitmapData)
            {
                setClipboardButtonAvailable();
            }
            else if(data is Array)
            {
                const file:File = data[0] as File;

                var loader:Loader = new Loader();
                loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
                loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError);

                loader.load(new URLRequest(file.url));

                function onLoaderComplete(e:Event):void
                {
                    if(loadMenuBox.visible && isSameFile(file,dragDropFileSave)) return;
                    dragDropFileSave = file;

                    setClipboardButtonAvailable();
                }

                function onIOError(e:IOErrorEvent):void
                {
                    try
                    {
                        if(file.exists)
                        {
                            if(isTrue2020File(file))
                            {
                                if(loadMenuBox.visible && isSameFile(file,dragDropFileSave)) return;
                                dragDropFileSave = file;

                                setClipboardButtonAvailable();
                            }
                            else
                            {
                                setClipboardButtonNotAvailable();
                            }
                        }
                    }
                    catch(erro:Error)
                    {
                        setClipboardButtonNotAvailable();
                    }
                }
            }
            else
            {
                setClipboardButtonNotAvailable();
            }
        }

        private function isSameFile(file1:File,file2:File):Boolean
        {
            if(!dragDropFileSave) return false;

            return file1.nativePath === file2.nativePath
            && file1.size === file2.size
            && file1.modificationDate.getTime() === file2.modificationDate.getTime()
            && file1.creationDate.getTime() === file2.creationDate.getTime();
        }

        //운영체제에서 2020파일 연결을 FOFOPAINT로 해줬을때
        private function onInvokeEvent(event:InvokeEvent):void
        {
            if(fileBrowserON || captureModeON || isInSaveProgress !== 0)
            {
                return;
            }
            var arguments:Array = event.arguments;

            if(arguments && arguments.length > 0)
            {
                try
                {
                    var file:File = new File(arguments[0] as String);

                    if(file.exists)
                    {
                        if(loadMenuBox.visible && isSameFile(file,dragDropFileSave)) return;
                        dragDropFileSave = file;

                        if(replayStartON)
                        {
                            stopReplay();
                        }
                        
                        if(hasTimer("rRestartTimer"))
                        {
                            cancelRestartTimer();
                        }

                        setDragDropPreviewImageReady(file,false);
                    }
                }
                catch(err:Error)
                {

                }
            }
        }

        private function onDragDropEvent(e:NativeDragEvent):void
        {
            if(fileBrowserON || captureModeON === true ||isInSaveProgress !== 0)
            {
                return;
            }

            rFileStream.close();
            cancelRestartTimer();
            const data:Object = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT);
            const file:File = data[0] as File;

            if(loadMenuBox.visible && isSameFile(file,dragDropFileSave)) return;
            dragDropFileSave = file;

            setDragDropPreviewImageReady(data[0] as File,false);
        }

        private function setDragDropPreviewImageReady(file:File,traceLayer:Boolean):void
        {
            if(!file) return;

            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError);

            // URLRequest를 생성하여 이미지 파일을 로드
            loader.load(new URLRequest(file.url));

            // Loader 이벤트: 이미지 로드 완료 시 호출
            function onLoaderComplete(event:Event):void
            {
                loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
                loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);

                tempDragDropFile = file;
                const bmpd:BitmapData = new BitmapData(loader.content.width,loader.content.height,true,0);
                bmpd.draw(loader);
                loadMenuBox.setPreviewImage(bmpd);
                setLoadBoxReady(false,traceLayer);
                loader.unload();
                loader = null;
                // 여기서 디코딩 가능한 작업 수행
            }

            // IOErrorEvent: 이미지 로드 중 오류 발생 시 호출
            function onIOError(event:IOErrorEvent):void
            {
                loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
                loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);

                if(isTrue2020File(file))
                {
                    tempDragDropFile = file;
                    loadMenuBox.setPreviewImage(getFinalImageFrom2020File(file,true));
                    setLoadBoxReady(false,traceLayer);
                }

                dragDropFileSave = null;
                loader.unload();
                loader = null;
            }
        }

        private function onDragEnterEvent(e:NativeDragEvent):void
        {
            if(fileBrowserON || captureModeON === true ||isInSaveProgress !== 0)
            {
                return;
            }

            var c:Clipboard = e.clipboard;
            if(c.hasFormat("air:file list") === true)
            {
                if(replayStartON) stopReplay();
                var files:Array = c.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
                //두개이상 선택하고 드래그 할수있기 때문에 하나만 선택되었을때 되도록 해줌
                if(files && files.length == 1)
                {
                    NativeDragManager.acceptDragDrop(stage);
                }
            }
        }

        private function loadImageDragDrop(isTraceLayer:Boolean):void
        {
            if(tempCopiedImage) //클립보드에 이미지가 있으면
            {
                if(!isTraceLayer)
                {
                    const fileName:String = getNewFileName();
                    //두번째 변수에서 fileName를 같게 해줘야 저장할때 오류가 안남
                    loadImageFile(fileName,fileName,tempCopiedImage.width,tempCopiedImage.height,tempCopiedImage,null);
                }
                else
                {
                    pasteTraceImage(tempCopiedImage,tempCopiedImage.width,tempCopiedImage.height);
                    if(!replayModeON) openTraceWindow();
                }
                tempCopiedImage = null;
                return;
            }

            // var file:File = tempDragDropFile;
            //grab the files file
            var fs:FileStream = new FileStream();
            var loader:Loader = new Loader();
            var tmpFileName:String = "";

            //실제적으로 loader가 읽어서 캔버스에 그림
            function loaderIOErrorHandlerEvent(e:Event):void
            {
                setLoadBoxOFFLoadFailed();
                tempDragDropFile = null;
                loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, loaderIOErrorHandlerEvent);
                loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, startDrawImgEvent);
                loader = null;
            }

            function startDrawImgEvent(e:Event):void //drag load1
            {
                if(!isTraceLayer)
                {
                    if(tempCopiedImage)
                    {
                        loadImageFile("Paste Image",saveFilePath,tempCopiedImage.width,tempCopiedImage.height,tempCopiedImage,null);
                        tempCopiedImage = null;
                    }
                    else
                    {
                        loadImageFile(tmpFileName,tempDragDropFile.nativePath,loader.content.width,loader.content.height,loader,null);
                    }

                }
                else
                {
                    if(tempCopiedImage)
                    {
                        pasteTraceImage(tempCopiedImage,tempCopiedImage.width,tempCopiedImage.height);
                        tempCopiedImage = null;
                    }
                    else
                    {
                        pasteTraceImage(loader,loader.content.width,loader.content.height);
                    }

                    if(!replayModeON) openTraceWindow();
                }

                tempDragDropFile = null;
                loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, loaderIOErrorHandlerEvent);
                loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, startDrawImgEvent);
                loader.unload();
                loader = null;
            }

            //file steram에서 바이트를 읽어서 다시 loader한테 보내줌
            function completeHandler(e:Event):void
            {
                try
                {
                    if(isImageFileExt(tempDragDropFile.name) === true)
                    {
                        if(!isTraceLayer)
                        {
                            loadReplayFile(tempDragDropFile,tempDragDropFile.name,tempDragDropFile.nativePath);
                        }
                        else
                        {
                            paste2020FileImageToTraceLayer(tempDragDropFile);
                        }

                        fs.close();
                        fs.removeEventListener(Event.COMPLETE, completeHandler);
                        fs.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
                        fs = null;
                    }
                    else
                    {
                        var data2Byte:ByteArray = new ByteArray();
                        fs.readBytes(data2Byte,0,fs.bytesAvailable);
                        fs.close();
                        fs.removeEventListener(Event.COMPLETE, completeHandler);
                        fs.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
                        fs = null;

                        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loaderIOErrorHandlerEvent);
                        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, startDrawImgEvent);
                        loader.loadBytes(data2Byte);
                        data2Byte.clear();
                        data2Byte = null;
                    }
                }
                catch(err:Error)
                {
                    tempDragDropFile = null;
                    if(data2Byte)
                    {
                        data2Byte.clear();
                        data2Byte = null;
                    }
                    if(fs)
                    {
                        fs.close();
                        fs.removeEventListener(Event.COMPLETE, completeHandler);
                        fs.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
                        fs = null;
                    }
                    loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, loaderIOErrorHandlerEvent);
                    loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, startDrawImgEvent);
                    setLoadBoxOFFLoadFailed();
                }
            }

            function errorHandler(e:Event):void
            {
                setLoadBoxOFFLoadFailed();
                fs.close();
                fs.removeEventListener(Event.COMPLETE, completeHandler);
                fs.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
                fs = null;
                tempDragDropFile = null;
            }

            tmpFileName = tempDragDropFile.name;
            fs.addEventListener(Event.COMPLETE, completeHandler);
            fs.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
            fs.openAsync(tempDragDropFile,FileMode.READ);
        }

        private function getMyPaletteIndexByMousePosLimitBound():int
        {
            const isAllViewMode:Boolean = (myPalettePresetType === 0 && myPaletteViewAllMode);
            const paletteLines:int = (isAllViewMode) ? 8:2;
            var xLineIndex:int = Math.floor(pickerBox.myPaletteBox.mouseX/myPaletteColorWidth);
            var yLineIndex:int = Math.floor(pickerBox.myPaletteBox.mouseY/myPaletteColorHeight)

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

        private function getHistoryIndexByMousePos():int
        {
            const xLineIndex:int = Math.floor(pickerBox.historyBox.mouseX/myPaletteColorWidth);
            const yLineIndex:int = 10*(Math.floor(pickerBox.historyBox.mouseY/myPaletteColorHeight));

            if(xLineIndex+yLineIndex < 0 || xLineIndex+yLineIndex > myPaletteLimitTotal)
            {
                return -1;
            }

            return xLineIndex+yLineIndex;
        }

        private function getMyPaletteIndexByMousePos():int
        {
            var xLineIndex:int = Math.floor(pickerBox.myPaletteBox.mouseX/myPaletteColorWidth);
            var yLineIndex:int = 10*(Math.floor(pickerBox.myPaletteBox.mouseY/myPaletteColorHeight));
            if(xLineIndex > 9) xLineIndex = 9;
            if(yLineIndex > 80) yLineIndex = 80;

            if(xLineIndex+yLineIndex < 0 || xLineIndex+yLineIndex > myPaletteLimitTotal)
            {
                return -1;
            }

            return xLineIndex+yLineIndex;
        }

        private function getTegakiColorPresetIndex(index:int):int
        {
            if(index >= 10) index = index-10;
            return Math.floor(index/2)*2;
        }

        private function selectTegakiColorPreset(index:int):void
        {
            index = getTegakiColorPresetIndex(index);

            const mainColor:uint = myPaletteTegakiPreset[index];

            if(mainColor !== pickerBox.getRGBInfoBGColor())
            {
                penColor = myPaletteTegakiPreset[index];
                setHSVCursorPosByColor((rgbInfoColorTypeHSV) ? HEXtoHSV(penColor):penColor);
            }

            if(!fillPenStarted)
            {
                const bgColor:uint = myPaletteTegakiPreset[index+10];
                if(bgColor !== CANVAS_BG_COLOR)
                {
                    setBackgroundColorDrawMode(bgColor);

                    if(canvasWindowON)
                    {
                        updateCanvasWindowCanvasPanelBGColor(CANVAS_BG_COLOR,canvasWindowBitmap.bitmapData);
                    }
                    addUndoBGColor(bgColor);
                }
                setNowToolForDrawing(false);
            }
        }

        private function isSelctedHistoryColorEmpty(index:int):Boolean
        {
             return !(myPalettePreset[index+90] is uint);
        }

        private function isSelctedColorEmpty(index:int):Boolean
        {
            var list:Array = (myPalettePresetType === 1) ? myPaletteDrawrPreset
                            :(myPalettePresetType === 2) ? myPaletteTegakiPreset
                            :myPalettePreset;

            return !(list[index] is uint);
        }

        private function pickColor(pickedColor:uint):void
        {
            if(isPenColorMode())
            {
                penColor = pickedColor;
                setHSVCursorPosByColor((rgbInfoColorTypeHSV) ? HEXtoHSV(pickedColor) : pickedColor);
                setNowToolForDrawing(false);
            }
            else if(isBackgroundColorMode())
            {
                setBackgroundColorDrawMode(pickedColor);
                if(canvasWindowON) updateCanvasWindowCanvasPanelBGColor(CANVAS_BG_COLOR,canvasWindowBitmap.bitmapData);
                addUndoBGColor(pickedColor);
            }
        }

        private function selectHistoryColor():void
        {
            const index:int = getHistoryIndexByMousePos();

            if(index < 0 || myPaletteDragStarted)// || index !== myPaletteDragClickedIndex)
            {
                return;
            }

            if(!(myPalettePreset[index+90] is uint))
            {
                if(penColorTransparentFlag === false)
                {
                    selectTransparentColor();
                }
                return;
            }

            const pickedColor:uint = myPalettePreset[index+90];

            if(pickedColor === pickerBox.getRGBInfoBGColor() && !penColorTransparentFlag)
            {
                return;
            }

            pickColor(pickedColor);
        }

        private function selectMyPaletteColor():void
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
                    if(penColorTransparentFlag === false && pickerMode === 1)
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
                    if(penColorTransparentFlag === false && pickerMode === 1)
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

        //주어진 컬러 알파값을 기반으로 반전 컬러를 구함
        private function getInvertColor(color:uint,alpha:Number=1.0,bright:uint=0xC7C7C7,dark:uint=0x616161):uint
        {
            return (getColorDifferenceForHuman(color,bright) <= 30) ? dark : bright;
        }


        private function saveMypPaletteList():void
        {
            const fs:FileStream = new FileStream();

            fs.open(myPaletteListFile,FileMode.WRITE);
            fs.writeObject(myPalettePreset);
            fs.close();
        }

        private function initMyPaletteList():void
        {
            updateHistoryList();
            updateMyPaletteList();

            if(!myPaletteListFile.exists)
            {
                saveMypPaletteList();
            }
        }

        private function setMypPaletteListViewCompact():void
        {
            myPaletteViewAllMode = false;
            updateMyPaletteList();
            hint.off();
            checkFOFOPosition();
        }

        private function setMypPaletteListViewAll():void
        {
            myPaletteViewAllMode = true;
            updateMyPaletteList();
            hint.off();
            checkFOFOPosition();
        }

        private function addColorToMyPalette(color:uint,index:int):void
        {
            if(index < 0) return;

            if(isSelctedColorEmpty(index))
            {
                if(myPaletteSaveBeforeAddColor[0] === index)
                {
                    myPalettePreset[index] = myPaletteSaveBeforeAddColor[1];
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
                if(myPalettePreset[index] !== pickerBox.getRGBInfoBGColor())
                {
                    myPaletteSaveBeforeAddColor[0] = index;
                    myPaletteSaveBeforeAddColor[1] = myPalettePreset[index];
                    myPalettePreset[index] = (penColorTransparentFlag) ? null:color;
                    updateMyPaletteList();
                    addColorMyPaletteHistory(color);
                }
                else
                {
                    if(penColorTransparentFlag)
                    {
                        myPaletteSaveBeforeAddColor[0] = index;
                        myPaletteSaveBeforeAddColor[1] = myPalettePreset[index];
                    }

                    myPalettePreset[index] = null;
                    updateMyPaletteList();
                    addColorMyPaletteHistory(color);
                }
            }
        }

        private function clearMyPaletteList():void
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

        private function addColorMyPaletteHistory(color:uint):void
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
                // //투명색 부분 있으면 지워줌
                // for(i=90;i<100;i++)
                // {
                //     if(null === myPalettePreset[i])
                //     {
                //         myPalettePreset.splice(i,1);
                //         break;
                //     }
                // }


                myPalettePreset.insertAt(90,color);
                myPalettePreset.removeAt(100);
            }

            updateHistoryList();
        }

        private function updateHistoryList(ignoreIndex:int=-1):void
        {
            pickerBox.historyBox.graphics.clear();


            for(var i:uint=0;i<10;i++)
            {
                if(i+90 === ignoreIndex)
                {
                    drawColorStartPos(pickerBox.historyBox.graphics,myPaletteColorWidth*i,0,myPaletteColorWidth,myPaletteColorHeight);
                    continue;
                }
                if(!(myPalettePreset[i+90] is uint))
                {
                    pickerBox.historyBox.graphics.beginBitmapFill(pickerBox.myPaletteTransBGBmpd);
                }
                else
                {
                    pickerBox.historyBox.graphics.beginFill(myPalettePreset[i+90]);
                }

                pickerBox.historyBox.graphics.drawRect(myPaletteColorWidth*i,0,myPaletteColorWidth,myPaletteColorHeight);
            }

            pickerBox.historyBox.graphics.endFill();

            pickerBox.historyBox.graphics.lineStyle(1,0,0.2);
            for(i=1;i<10;i++)
            {
                pickerBox.historyBox.graphics.moveTo(myPaletteColorWidth*i,0);
                pickerBox.historyBox.graphics.lineTo(myPaletteColorWidth*i,myPaletteColorHeight);
            }
        }

        private function drawColorStartPos(g:Graphics,px:Number,py:Number,ww:Number,hh:Number):void
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

        private function updateMyPaletteList(ignoreIndex:int=-1):void
        {
            const type:int = myPalettePresetType;
            const arr:Array = (type === 0) ? myPalettePreset
                             :(type === 1) ? myPaletteDrawrPreset
                             :(type === 2) ? myPaletteTegakiPreset : null;

            if(arr === null) return;

            const ww:Number = myPaletteColorWidth;
            const hh:Number = myPaletteColorHeight;

            var len:int = (type === 0 && myPaletteViewAllMode) ? myPaletteLimitTotal-10:20;
            var nextX:Number = 0.0;
            var nextY:Number = 0.0;

            pickerBox.myPaletteBox.graphics.clear();
            pickerBox.myPaletteBox.graphics.lineStyle(0,0,0);

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
                    drawColorStartPos(pickerBox.myPaletteBox.graphics,px,py,ww,hh);
                    continue;
                }

                if(!(arr[i] is uint))
                {
                    pickerBox.myPaletteBox.graphics.beginBitmapFill(pickerBox.myPaletteTransBGBmpd);
                }
                else
                {
                    pickerBox.myPaletteBox.graphics.beginFill(arr[i]);
                }

                pickerBox.myPaletteBox.graphics.drawRect(px,py,ww,hh);
            }
            pickerBox.myPaletteBox.graphics.endFill();

            //구분선 그려주기
            if(type === 2) //tegaki
            {
                pickerBox.myPaletteBox.graphics.lineStyle(1,0,0.2);
                pickerBox.myPaletteBox.graphics.moveTo(0,hh);
                pickerBox.myPaletteBox.graphics.lineTo(ww*10,hh);

                for(i=2;i<10;i+=2)
                {
                    pickerBox.myPaletteBox.graphics.moveTo(ww*i,0);
                    pickerBox.myPaletteBox.graphics.lineTo(ww*i,hh*2);
                }
            }
            else if(type === 1) // drawr
            {
                pickerBox.myPaletteBox.graphics.lineStyle(1,0,0.2);
                pickerBox.myPaletteBox.graphics.moveTo(0,hh);
                pickerBox.myPaletteBox.graphics.lineTo(ww*10,hh);

                for(i=1;i<10;i++)
                {
                    pickerBox.myPaletteBox.graphics.moveTo(ww*i,0);
                    pickerBox.myPaletteBox.graphics.lineTo(ww*i,hh*2);
                }
            }
            else //my palette
            {
                if(myPaletteViewAllMode === false)
                {
                    //가로선
                    pickerBox.myPaletteBox.graphics.lineStyle(1,0,0.2);
                    pickerBox.myPaletteBox.graphics.moveTo(0,hh);
                    pickerBox.myPaletteBox.graphics.lineTo(ww*10,hh);

                    //세로
                    for(i=1;i<10;i++)
                    {
                        pickerBox.myPaletteBox.graphics.moveTo(myPaletteColorWidth*i,0);
                        pickerBox.myPaletteBox.graphics.lineTo(myPaletteColorWidth*i,hh*2);
                    }
                }
                else
                {
                    pickerBox.myPaletteBox.graphics.lineStyle(1,0,0.2);

                    //가로
                    for(i=1;i<9;i++)
                    {
                        pickerBox.myPaletteBox.graphics.moveTo(0,hh*i);
                        pickerBox.myPaletteBox.graphics.lineTo(myPaletteColorWidth*10,hh*i);
                    }
                    //세로
                    for(i=1;i<10;i++)
                    {
                        pickerBox.myPaletteBox.graphics.moveTo(myPaletteColorWidth*i,0);
                        pickerBox.myPaletteBox.graphics.lineTo(myPaletteColorWidth*i,hh*9);
                    }
                }
            }

            pickerBox.checkMainColorPickerBoxPosition(pickerBoxSwapPositionFlag);
        }

        private function makeResizeButtonFamily():void
        {
            resizeButtonU.name = "resizeButtonU";
            resizeButtonD.name = "resizeButtonD";
            resizeButtonR.name = "resizeButtonR";
            resizeButtonL.name = "resizeButtonL";

            regPoint.addChild(resizeButtonU);
            regPoint.addChild(resizeButtonD);
            regPoint.addChild(resizeButtonR);
            regPoint.addChild(resizeButtonL);
        }

        private function makeJumpImage():void //loadrep
        {
            const fs:FileStream = new FileStream();
            const fs2:FileStream = new FileStream();
            const totalSize:Number = repFile.size;
            const deepUndoFlag:Boolean = deepUndoON;
            var rect:Rectangle;
            var _frameSum:Number = 0;
            var _frameSumLast:Number = 0;
            var _rJumpImageCount:uint = 0;
            var _tickDraw:Object = tickDraw;
            var data:Array;
            var imgData:ByteArray = new ByteArray();
            var imgData1:ByteArray = new ByteArray();
            var hintPrintTimeSave:int = getTimer();

            regPoint.visible = false;
            rregPoint.visible = false;
            previewBox.visible = false;
            undoData.resetRJumpImageCount();
            clearCanvasReplayMode();//리플레이 캔버스 먼저 깨끗하게

            //첫 이미지 그려줌
            if(rcanvas1BitmapData && rFirstImage !== rcanvas1BitmapData) rcanvas1BitmapData.dispose();
            rcanvas1BitmapData = rFirstImage.clone();
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;

            if(rcanvas11BitmapData && rFirstImage1 !== rcanvas11BitmapData) rcanvas11BitmapData.dispose();
            rcanvas11BitmapData = rFirstImage1.clone();
            rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;
            changeCanvasSizeReplayMode(rcanvas1BitmapData.width,rcanvas1BitmapData.height); //크기도 바꿔주고

            fs.open(repFile,FileMode.READ);
            fs.position = 0;

            rMirrorON = false;

            function printPrograssHint(bytes:Number):void
            {
                const perc:Number =((totalSize-bytes)/totalSize)*100;
                const str:String = STRING_PREPARE_REPLAY_DATA+perc.toFixed(1)+"%";

                if(deepUndoFlag)
                {
                    setHintONTemp(str);
                }
                else
                {
                    replayTimeBox["frameInfo"].text = str;
                }
            }

            loadMenuBox.setPleaseWait(true);
            setLoadBoxVisible(true);

            function onFrameEnter(e:Event):void
            {
                while(true)
                {
                    const namojiBytes:Number = fs.bytesAvailable;

                    if(namojiBytes === 0)
                    {
                        stage.removeEventListener(Event.ENTER_FRAME,onFrameEnter);
                        fs.close();
                        _tickDraw.reset();
                        if(imgData)
                        {
                            imgData.clear();
                            imgData = null;
                        }

                        if(imgData1)
                        {
                            imgData1.clear();
                            imgData1 = null;
                        }

                        if(data)
                        {
                            data.length = 0;
                            data = null;
                        }

                        _tickDraw = null;
                        undoData.setRFileTotalFrame(_frameSum);
                        makeJumpImageFlag = 0;
                        resetReplayTime();
                        TOTAL_FRAME = getTotalFrame();
                        rNowFrame = TOTAL_FRAME;
                        deepUndoFrameSave = TOTAL_FRAME;
                        rPrevFrame = _frameSumLast;
                        playbackFinished = true;

                        if(mirrorCommandReady)
                        {
                            rMirrorON = !rMirrorON;
                            mirrorCommandReady = rMirrorON;
                        }

                        mirrorON = rMirrorON;
                        rMirrorON = rMirrorON;
                        undoData.setUndoRefImageMirrorFlag(rMirrorON);
                        appInfoBox.setMirror(rMirrorON);
                        previewBox.visible = true;

                        if(!replayModeON && deepUndoON)
                        {
                            rDataReadFlag = false;
                            setTopBarHintOFF();
                            addInputEventDrawMode();
                            // jumpFrame(undoData.getRFileTotalFrame()-1,JUMP_FRAME_ONCE);
                            jumpFrame(rPrevFrame,JUMP_FRAME_ONCE);
                            drawReplayImageToDrawModeCanvas();
                            rOnejumpFlagSave = true;
                            regPoint.visible = true;
                        }
                        else if(replayModeON)
                        {
                            checkReplaySpeedState();
                            checkCutFrameButtonsCanUse();
                            clearRFrameCacheImages();
                            rJumpImageIndexLast = -2;
                            rJumpImageNowFrameLast = -1;
                            rJumpCacheImageIndexSave = -2;

                            setDeepUndoOFF();
                            undoToIndex(rData.length-1);
                            setCenvasCenterPos(true,false);

                            removeInputEventDrawMode();
                            addInputEventReplayMode();
                            rregPoint.visible = true;
                        }

                        setLoadBoxVisible(false);
                        loadMenuBox.setPleaseWait(false);
                        resetKeyBuffer();
                        return;
                    }

                    data = fs.readObject() as Array;
                    _tickDraw.ready(data);
                    _frameSumLast = _frameSum;
                    _frameSum += data.length;
                    _rJumpImageCount += data.length;
                    _tickDraw.drawAll();

                    if(getTimer()-hintPrintTimeSave > 250)
                    {
                        hintPrintTimeSave = getTimer();
                        printPrograssHint(namojiBytes);
                        return;
                    }

                    if(_rJumpImageCount > REPLAY_MAKE_JUMPIMAGE_INTERVAL)
                    {
                        _rJumpImageCount = 0;
                        rJumpImageFrameData.push(_frameSum); // jumpimg:File변수보다 먼저 와야함
                        rect = new Rectangle(0,0,rcanvas1BitmapData.width,rcanvas1BitmapData.height);
                        imgData.clear();
                        imgData1.clear();
                        rcanvas1BitmapData.copyPixelsToByteArray(rect,imgData);
                        rcanvas11BitmapData.copyPixelsToByteArray(rect,imgData1);
                        imgData.compress();
                        imgData1.compress();

                        fs2.open(rJumpImageFolder.resolvePath((rJumpImageFrameData.length-1)+""),FileMode.WRITE);
                        //레이어1,레이어2,가로 세로, 배경색, 마지막 바이트 위치, 마지막 프레임 합
                        fs2.writeObject([imgData // 0
                                        ,imgData1
                                        ,rcanvas1BitmapData.width
                                        ,rcanvas1BitmapData.height
                                        ,rBGColorSave  //4
                                        ,fs.position
                                        ,_frameSum
                                        ,rMirrorON]); //7
                        fs2.close();

                        if(replayTimeBox["replayNowBar"].width > 0) replayTimeBox["replayNowBar"].width = 0;

                        if(getTimer()-hintPrintTimeSave > 250)
                        {
                            hintPrintTimeSave = getTimer();
                            printPrograssHint(namojiBytes);
                            return;
                        }

                        return;
                    }
                }
            }
            stage.addEventListener(Event.ENTER_FRAME,onFrameEnter);
        }

        private function setSaveProgressOFF():void
        {
            topBar.setButtonAlphaONSaving(isClipBoardButtonAvailable);
            if(replayModeON) checkCutFrameButtonsCanUse();
        }

        private function setSaveProgressON():void
        {
            if(isInSaveProgress === 0 ) isInSaveProgress = 1;
            if(topBar.saveButton.alpha === 1.0) topBar.setButtonAlphaOFFSaving(BUTTON_OFF_ALPHA);
        }

        private function callWorkerEncodePNG(bmpd:BitmapData,bg:uint,isCaptureImage:Boolean,isTransBG:Boolean):void
        {
            setStartWorker(function():void
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

        private function callWorkerCompressUndoJumpImage(data:ByteArray,data1:ByteArray):void
        {
            setStartWorker(function():void
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

        private function saveReplayFile():void
        {
            if(repFile.exists)
            {
                rImgData.position = 0;
                rImgData1.position = 0;
                lastImgData.position = 0;
                lastImgData1.position = 0;
                traceImgData.position = 0;
                replayDataBytes.position = 0;
                rImgData.length = 0;
                rImgData1.length = 0;
                lastImgData.length = 0;
                lastImgData1.length = 0;
                traceImgData.length = 0;
                replayDataBytes.length = 0;

                //첫번째 이미지 레이어 1 2 저장
                const fs:FileStream = new FileStream();
                const rImgDataW:Number = rFirstImage.width;
                const rImgDataH:Number = rFirstImage.height;
                var newRectangle:Rectangle = new Rectangle(0,0,rImgDataW,rImgDataH);

                rFirstImage.copyPixelsToByteArray(newRectangle,rImgData);
                rFirstImage1.copyPixelsToByteArray(newRectangle,rImgData1);

                //현재 캔버스 이미지 레이어 1 2 저장
                newRectangle = new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);
                canvas1BitmapData.copyPixelsToByteArray(newRectangle,lastImgData);
                canvas11BitmapData.copyPixelsToByteArray(newRectangle,lastImgData1);

                //참고 레이어 이미지 저장
                if(canvasTraceBitmapData)
                {
                    const traceImgWidth:Number = canvasTraceBitmapData.width;
                    const traceImgHeight:Number = canvasTraceBitmapData.height;
                    newRectangle = new Rectangle(0,0,traceImgWidth,traceImgHeight);
                    canvasTraceBitmapData.copyPixelsToByteArray(newRectangle,traceImgData);
                }

                //리플레이 파일을 임시파일로 복사
                repFile.copyTo(repFileTemp,true);

                //임시파일전체를 바이트배열로 읽어서 압축해줌
                fs.open(repFileTemp,FileMode.READ);
                fs.position = 0;

                //딥 언도일때는 읽은 바이트 까지만 읽어줌
                if(deepUndoON)
                {
                    fs.readBytes(replayDataBytes,0,rLastBytePosition);
                    fs.close();
                }
                else
                {
                    //그게 아니면 전체 리플레이 데이터 끝까지 읽고 undo데이터까지 넣어줌
                    fs.readBytes(replayDataBytes,0,fs.bytesAvailable);
                    fs.close();
                    replayDataBytes.position = replayDataBytes.length;

                    for(var i:int=0,len:int=undoIndex;i<=len;i++)//리플레이 데이터랑 첫이미지 마지막 이미지 추가적으로 붙여줌
                    {
                        if(rData[i] && rData[i].length === 0)
                        {
                            continue;
                        }
                        replayDataBytes.writeObject(rData[i]);
                    }
                }

                callWorkerCompressReplayData(rImgData,rImgData1,lastImgData,lastImgData1,traceImgData,replayDataBytes);
            }
        }

        private function callWorkerCompressReplayData(dataA:ByteArray,dataA1:ByteArray,dataB:ByteArray,dataB1:ByteArray,dataC:ByteArray,dataD:ByteArray):void
        {
            setStartWorker(function():void
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

        private function writeReplayFile(dataA:ByteArray
                                        ,dataA1:ByteArray
                                        ,dataB:ByteArray
                                        ,dataB1:ByteArray
                                        ,dataC:ByteArray
                                        ,dataD:ByteArray):void
        {

            const fs:FileStream = new FileStream();
            const rImgDataW:int = rFirstImage.width;
            const rImgDataH:int = rFirstImage.height;
            const traceImgWidth:Number = canvasTraceBitmapData.width;
            const traceImgHeight:Number = canvasTraceBitmapData.height;

            const newPath:String = saveFilePath.substr(0,saveFilePath.lastIndexOf(".png"))+".2020";
            var copyFile:File = new File(newPath);

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

            fs.writeObject(["rFirstImage",dataA,dataA1,rImgDataW,rImgDataH,rFirstBGColor]);
            fs.writeObject(["rFinalImage",dataB,dataB1,CANVAS_WIDTH,CANVAS_HEIGHT,CANVAS_BG_COLOR]);

            if(canvasTraceBitmapData)
            {
                fs.writeObject(["traceImage",dataC, // 1
                                            traceImgWidth,
                                            traceImgHeight,
                                            tracePosInfo[0],
                                            tracePosInfo[1],// 5
                                            tracePosInfo[2],
                                            tracePosInfo[3],
                                            tracePosInfo[4],
                                            tracePosInfo[5],
                                            traceReizeMoveSum,//10
                                            traceAlphaSave]);//11
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
                repFileTemp.moveTo(copyFile,true);
            }
            catch(err:Error)
            {
                //파일 엑세스가 불가하므로 새로운 파일로 저장해줌
                if(isInSaveProgress === 1) isInSaveProgress = 0;
                setSaveProgressOFF();
                saveFile(true,true);
                return;
            }

            if(isInSaveProgress === 1) isInSaveProgress = 0;

            setSaveProgressOFF();
        }

        private function loadReplayFile(oldFile:File,fileName:String,filePath:String):void //loadrep
        {
            if(isTrue2020File(oldFile) === false)
            {
                setLoadBoxOFFLoadFailed();
                return;
            }

            if(replayModeON)
            {
                setDeepUndoFrameSave(rNowFrame);
                setReplayModeOFF();
            }

            const fs:FileStream = new FileStream();
            var imgStartByte:uint = 0;
            var finalIMGBMPD:BitmapData = new BitmapData(1,1,true,0);
            var finalIMGBMPD1:BitmapData = new BitmapData(1,1,true,0);
            var imgW:uint = 0;
            var imgH:uint = 0;
            var bg:uint = 0;
            var errorFlag:Boolean = true;
            var traceBMPD:BitmapData = null;
            var traceImgInfo:Array = null;
            var newRectangle:Rectangle;

            initReplayDataFile(true); //일단 썸네일 이미지랑 리플레이 데이터 청소
            oldFile.copyTo(repFileTemp,true);//repdata.c3p를 복사 덮어씌우기

            if(traceRawData)
            {
                traceRawBMPD.dispose();
                traceRawBMPD = null;
                traceRawData = null;
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

                if(d[0] === "rFirstImage") //리플레이 첫 이미지 파일
                {
                    if(d[2] is ByteArray === false)
                    {
                        ba = d[1] as ByteArray;
                        newRectangle = new Rectangle(0,0,d[2],d[3]);
                        ba.uncompress();
                        rFirstImage = new BitmapData(d[2],d[3],true,0);
                        rFirstImage.lock();
                        rFirstImage.setPixels(newRectangle,ba);
                        rFirstImage.unlock();
                        ba.clear();
                        ba = null;
                        rBGColorSave = d[4];
                        makeFirstReplayImage(rFirstImage,null,d[4]); //0.cache 파일 갱신
                    }
                    else
                    {
                        ba = d[1] as ByteArray;
                        newRectangle = new Rectangle(0,0,d[3],d[4]);
                        ba.uncompress();
                        rFirstImage = new BitmapData(d[3],d[4],true,0);
                        rFirstImage.lock();
                        rFirstImage.setPixels(newRectangle,ba);
                        rFirstImage.unlock();
                        ba.clear();

                        ba = d[2] as ByteArray;
                        ba.uncompress();
                        rFirstImage1 = new BitmapData(d[3],d[4],true,0);
                        rFirstImage1.lock();
                        rFirstImage1.setPixels(newRectangle,ba);
                        rFirstImage1.unlock();
                        ba.clear();
                        ba = null;

                        rBGColorSave = d[5];
                        makeFirstReplayImage(rFirstImage,rFirstImage1,d[5]); //0.cache 파일 갱신
                    }
                }
                else if(d[0] === "rFinalImage")//최종 이미지
                {
                    //레이어1일때 구버전
                    if(d[2] is ByteArray === false)
                    {
                        ba = d[1] as ByteArray;
                        newRectangle = new Rectangle(0,0,d[2],d[3]);
                        ba.uncompress();
                        errorFlag = false;
                        finalIMGBMPD = new BitmapData(d[2],d[3],true,0);
                        finalIMGBMPD.lock();
                        finalIMGBMPD.setPixels(newRectangle,ba);
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
                        newRectangle = new Rectangle(0,0,d[3],d[4]);
                        ba.uncompress();
                        errorFlag = false;
                        finalIMGBMPD = new BitmapData(d[3],d[4],true,0);
                        finalIMGBMPD.lock();
                        finalIMGBMPD.setPixels(newRectangle,ba);
                        finalIMGBMPD.unlock();
                        ba.clear();

                        ba = d[2] as ByteArray;
                        ba.uncompress();
                        finalIMGBMPD1 = new BitmapData(d[3],d[4],true,0);
                        finalIMGBMPD1.lock();
                        finalIMGBMPD1.setPixels(newRectangle,ba);
                        finalIMGBMPD1.unlock();
                        ba.clear();
                        ba = null;

                        imgW = d[3];
                        imgH = d[4];
                        bg = d[5];
                    }
                }
                else if(d[0] === "traceImage")
                {
                    ba = d[1] as ByteArray;
                    newRectangle = new Rectangle(0,0,d[2],d[3]);
                    ba.uncompress();
                    traceRawBMPD = new BitmapData(d[2], d[3],true,0);
                    traceRawBMPD.lock();
                    traceRawBMPD.setPixels(newRectangle,ba);
                    traceRawBMPD.unlock();
                    ba.clear();
                    ba = null;
                    d[0] = null;
                    d[1] = null;
                    traceRawData = d.concat();
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
                fs.open(repFile,FileMode.WRITE);
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
                repFileTemp.moveTo(repFile,true);
            }

            if(repFileTemp.exists)
            {
                repFileTemp.deleteFile();
            }

            replayData.clear();
            replayData = null;

            makeJumpImageFlag = 1;
            loadFileAfter(fileName,filePath,imgW,imgH,finalIMGBMPD,finalIMGBMPD1,false,bg);
        }

        private function loadImageFile(fileName:String,filePath:String,width:Number,height:Number,imageData:IBitmapDrawable,imageData1:IBitmapDrawable):void
        {
            if(replayModeON)
            {
                setDeepUndoFrameSave(rNowFrame);
                setReplayModeOFF();
            }
            TOTAL_FRAME = 0;
            undoData.setRFileTotalFrame(0);
            makeJumpImageFlag = 0;
            traceRawBMPD = null;
            traceRawData = null;
            loadFileAfter(fileName,filePath,width,height,imageData,imageData1,true,0xFFFFFF);
            initReplayDataFile(true); //일단 썸네일 이미지랑 리플레이 데이터 청소
        }

        private function loadFileAfter(fileName:String,filePath:String, width:uint,height:uint,imageData:IBitmapDrawable,imageData1:IBitmapDrawable,imageOnlyFlag:Boolean,newBG:uint):void
        {
            if(!imageData)
            {
                setLoadBoxOFFLoadFailed();
                return;
            }

            var maxLength:Number = (width > height) ? width : height;
            var scaleFix:Number = (maxLength > CANVAS_MAX_SIZE) ? CANVAS_MAX_SIZE/maxLength : 1.0;
            const scaledwidth:Number = Math.floor(width*scaleFix);
            const scaledheight:Number= Math.floor(height*scaleFix); //CANVAS_MAX_SIZE 값을 넘으면 리사이즈 해줌
            var scaleMat:Matrix = new Matrix();
            scaleMat.scale(scaleFix,scaleFix);
            var tmpBMPD:BitmapData = new BitmapData(scaledwidth,scaledheight,true,0);

            if(captureModeON)
            {
                setCaptureOFF();
            }

            resetReplaySpeedBar();
            resetReplayTime();
            clearCanvasReplayMode();
            replayTimeBox["frameInfo"].text = "0 / " + getTotalFrame()+" frame";
            replayTimeBox["replayNowBar"].width = 0;

            setBackgroundColorDrawMode(newBG);
            setBackgroundColorReplayMode(newBG);
            if(canvasWindowON) updateCanvasWindowCanvasPanelBGColor(CANVAS_BG_COLOR,canvasWindowBitmap.bitmapData);

            if(isImageFileExt(fileName) === true)
            {
                fileName = fileName.substr(0,fileName.lastIndexOf(".2020"))+".png";
                filePath = filePath.substr(0,filePath.lastIndexOf(".2020"))+".png";
            }

            const saveFilePathSave:String = removeLastFileSeparator(saveFilePath);
            const lastSepIndex:int = saveFilePathSave.lastIndexOf(File.separator);
            const newPath:String = saveFilePathSave.substr(0,lastSepIndex)+File.separator+fileName;

            saveFileName = fileName;
            saveFilePath = newPath;
            saveContinue = false;//연속 세이브 플래그 취소
            rMirrorON = false;
            mirrorON = false;
            mirrorCommandReady = false;
            appInfoBox.setMirror(false);
            checkGridMirror(false);

            if(lassoToolON === true)
            {
                setLassoCancelButton();
                resetLassoBox();
            }

            if(fillPenStarted) fillPenTool.cancel();

            tmpBMPD.draw(imageData,scaleMat,null,null,null,true);

            if(canvas1BitmapData && tmpBMPD !== canvas1BitmapData) canvas1BitmapData.dispose();
            canvas1BitmapData = tmpBMPD.clone();
            canvas1Bitmap.bitmapData = canvas1BitmapData;

            if(imageOnlyFlag)
            {
                if(rFirstImage && tmpBMPD !== rFirstImage) rFirstImage.dispose();
                rFirstImage = tmpBMPD.clone(); //이미지만 불러와주면 첫 이미지를 갱신해줌
            }

            if(imageData1 !== null)
            {
                tmpBMPD.fillRect(new Rectangle(0,0,scaledwidth,scaledheight),0);
                tmpBMPD.draw(imageData1,scaleMat,null,null,null,true);

                if(canvas11BitmapData && tmpBMPD !== canvas11BitmapData) canvas11BitmapData.dispose();
                canvas11BitmapData = tmpBMPD.clone();
                canvas11Bitmap.bitmapData = canvas11BitmapData;

                if(imageOnlyFlag)
                {
                    rFirstImage1 = tmpBMPD.clone();
                }
            }
            else
            {
                canvas11BitmapData = new BitmapData(canvas1BitmapData.width,canvas1BitmapData.height,true,0);
                canvas11Bitmap.bitmapData = canvas11BitmapData;
            }

            changeCanvasSize(scaledwidth,scaledheight,0,0,false);
            setSameReplayModeImageByDrawMode();

            tmpBMPD.dispose();
            tmpBMPD = null;
            regPoint.rotation = 0;
            setRcursorRotation(0);
            zoomedIndex = 3;
            setZoomCanvas(1.0);
            updatePenSizeCursor();
            if(gridValue > 0) drawGrid();
            //bitmapdata가 갱신된이후에 업데이트 해줘야함
            resetUndo();
            tickDraw.resetFirstRCursorPos();

            if(traceRawData === null)
            {
                clearTraceImage();
            }
            else
            {
                canvasTraceBitmapData = traceRawBMPD.clone();
                canvasTraceBitmap.bitmapData = canvasTraceBitmapData;
                setTraceImageInfo(traceRawData[4],
                                  traceRawData[5],
                                  traceRawData[6],
                                  traceRawData[7],
                                  traceRawData[8],
                                  traceRawData[9]);
                traceReizeMoveSum = traceRawData[10];
                traceAlphaSave = traceRawData[11];
                canvasTraceLayer.visible = true;
                canvasTraceLayer.alpha = getDiplayObjectAlpha(traceRawData[11]);
                updateTraceOpaButtonPosByAlpha(traceRawData[11]);
                traceRawBMPD.dispose();
                traceRawBMPD = null;
                traceRawData = null;
                canvasTraceBitmap.smoothing = true;
            }

            setCenvasCenterPos();
            updateWindowTitle();
            selectSubLayer(false,false);
            selectReplaySubLayer(false);
            if(controlBox.layer1CheckButton.visible) setLayer1CheckToggle();
            if(controlBox.layer2CheckButton.visible) setLayer2CheckToggle();
            updateResizeButtonPos(CANVAS_WIDTH,CANVAS_HEIGHT);
            cancelAutoKeyEvent(null);

            canvas1Bitmap.visible = true;
            canvas11Bitmap.visible = true;
            topBar.captureButton.alpha = 1.0;
            topBar.clearButton.alpha = 1.0;
            traceMenu.traceImageButton.alpha = 1.0;

            setCurrentColor(1);
            setNowToolForDrawing(false);

            previewBox.updateImage(canvas1BitmapData,canvas11BitmapData,CANVAS_BG_COLOR);
            updatePreviewBoxRectPos();

            if(canvasWindowON)
            {
                updateCanvasWindowImage();
                canvasWindowIgnoreResizeEventFlag = true;
                updateCanvasWindowBitmapSize();
            }

            resetCaptureCanvasChangeValue();

            dragDropFileSave = null;
            saveThenLoadFlag = false;
            setLoadBoxVisible(false);
        }

        private function loadFile(traceLayer:Boolean=false):void
        {
            if(replayStartON) stopReplay();
            if(lassoToolON || fileBrowserON || fillPenStarted || isInSaveProgress)
            {
                return;
            }

            var windowTitle:String = "Open file";
            var imgExt:Array = [new FileFilter("All supported formats","*.2020;*.png;*.jpg;*.gif")];

            if(traceLayer === true)
            {
                windowTitle = "Open reference layer image";
            }

            //초기값으로 파일 경로가 저장된 파일 이름이랑 같으면 그냥 파일인스턴스로 만들어줌
            const file:File = (saveFilePath === saveFileName) ? new File() : new File(saveFilePath);

            function onCancelEvent(e:Event):void
            {
                setFileBrowserONFlag(false);
                file.removeEventListener(Event.SELECT,fileSelectHandler);
                file.removeEventListener(Event.COMPLETE,fileSelectCompleteHandler);
                file.removeEventListener(Event.CANCEL,onCancelEvent);
                addInputEventCurrentModeLoadButton();
            }

            function fileSelectHandler(e:Event):void
            {
                setFileBrowserONFlag(false);

                file.removeEventListener(Event.SELECT,fileSelectHandler);
                file.load();
            }

            function fileSelectCompleteHandler(e:Event):void
            {
                file.removeEventListener(Event.SELECT,fileSelectHandler);
                file.removeEventListener(Event.COMPLETE,fileSelectCompleteHandler);
                file.removeEventListener(Event.CANCEL,onCancelEvent);
                setFileBrowserONFlag(false);

                if(traceLayer)
                {
                    addInputEventCurrentModeLoadButton();
                    loadMenuBox.setRefLayerLoadMode(true);
                }
                else
                {
                    loadMenuBox.setRefLayerLoadMode(false);
                }

                setDragDropPreviewImageReady(file,traceLayer);
            }

            setFileBrowserONFlag(true);

            removeInputEventCurrentModeLoadButton();

            file.browseForOpen(windowTitle,imgExt);
            file.addEventListener(Event.SELECT,fileSelectHandler);
			file.addEventListener(Event.COMPLETE,fileSelectCompleteHandler);
            file.addEventListener(Event.CANCEL,onCancelEvent);
        }

        private function setCaptureUI(flag:Boolean):void
        {
            //함수 변수가 true가 직관적이라서 없애주는 변수는 반대로해줌
            const iFlag:Boolean = !flag;
            const replayMode:Boolean = replayModeON;

            drawCaptureArea.reset();
            setResizeButtonVisible(false);
            removeTimer("rCursorOffAlphaAnimTimer");

            if(replayMode)
            {
                setReplayDeleteBarVisibleOFF();
                setTopBarHintOFF();
                replayTimeBox.visible = iFlag;
            }
            else
            {
                canvasGrid.visible = iFlag;
            }

            if(flag)
            {
                if(replayMode) removeInputEventReplayMode();
                else removeInputEventDrawMode();

                if(isSidebarVisible) setSidebarVisible(false,true);
                penCursorOFFFlag = true;
                penSizeCursor.visible = false;
                canvasTraceLayer.visible = false;
                if(traceMenuON === true) traceMenu.visible = false;

                changeTopBarIcons("capture");

                setDefaultHintCaptureMode();
                rCursor.visible = false;
                if(toolTipBox.visible) toolTipBoxTimerOFF();
                addInputEventCaptrueMode();
            }
            else
            {
                removeInputEventCaptrueMode();
                canvasTraceLayer.visible = true;

                if(replayMode)
                {
                    changeTopBarIcons("replay");
                    addInputEventReplayMode();
                    replayTimeBox.visible = true;
                }
                else
                {
                    if(isSidebarVisible) setSidebarVisible(true,true);

                    if(traceMenuON === true)
                    {
                        traceMenu.visible = true;
                    }

                    penCursorOFFFlag = false;
                    changeTopBarIcons("draw");
                    addInputEventDrawMode();
                }
                changePickerModeToPenColor();
            }

            updateStageOffset();
        }

        private function setDefaultHintCaptureMode():void
        {
            if(capStampFontListBox.visible)
            {
                return;
            }

            if(!topBar.hitTestPoint(mouseX,mouseY) && !capStampFontListBox.hitTestPoint(mouseX,mouseY))
            {
                if(drawCaptureArea.isFullImageCapture())
                {
                    hint.on(drawCaptureArea.getRotatedRectSizeString()+"\nDraw capture area [click+drag]"+STRING_CAPTURE_OK,null,true);
                }
                else
                {
                    if(drawCaptureArea.isCursorInResizeButton())
                    {
                        hint.on(drawCaptureArea.getRotatedRectSizeString()+"\nResize [click+drag]"+STRING_CAPTURE_OK,null,true);
                    }
                    else if(drawCaptureArea.isCursorInCaptureDrea())
                    {
                        hint.on(drawCaptureArea.getRotatedRectSizeString()+"\nMove [click+drag]"+STRING_CAPTURE_OK,null,true);
                    }
                    else
                    {
                        hint.on(drawCaptureArea.getRotatedRectSizeString()+"\nDraw capture area [click+drag]"+STRING_CAPTURE_OK,null,true);
                    }
                }
            }

        }

        private function mouseOverCaptureMode(e:MouseEvent):void
        {
            addTimerByName("checkCaptureHintDelay",0.1,false,function():void
            {
                if(mouseDragON) return;

                if(!(topBar.hitTestPoint(mouseX,mouseY) || capStampFontListBox.hitTestPoint(mouseX,mouseY)))
                {
                    hintHorverCursor.visible = false;
                }
            });
        }

        private function rightMouseDownCaptureMode(e:MouseEvent):void
        {
            if(topBar.hitTestPoint(mouseX,mouseY) === false)
            {
                if(!drawCaptureArea.isFullImageCapture())
                {
                    drawCaptureArea.resetCaptureArea();
                }
            }
        }

        private function mouseDownCaptureMode(e:MouseEvent):void
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
                checkButtonUp(targetName);

                return;
            }

            if(targetName === "capClipBoard")
            {
                setCaptureFlashEffect();
                if(target.alpha < 1.0 && topBar.hitTestPoint(mouseX,mouseY))
                {
                    return;
                }
                checkButtonUp(targetName);
            }

            if(target.alpha < 1.0 && topBar.hitTestPoint(mouseX,mouseY))
            {
                return;
            }

            if(capStampFontListBox.visible)
            {
                if(targetName === "capFontListNext" || targetName === "capFontListPrev")
                {
                    checkButtonUp(targetName);
                }
                else if(targetName.indexOf(capStampFontListBox.getStampFontButtonName()) !== -1)
                {
                    drawCaptureStamp.changeFont(capStampFontListBox.getFontName(targetName),true);
                }
                else if(target.parent)
                {
                    if(target.parent.name && target.parent.name.indexOf(capStampFontListBox.getStampFontButtonName()) !== -1)
                    {
                        drawCaptureStamp.changeFont(capStampFontListBox.getFontName(target.parent.name),true);
                    }
                }

                return;
            }

            switch(targetName)
            {
                case "capRotate":
                case "capFlip":
                case "capFull":
                case "capOff":
                case "capTrans":
                {
                    checkButtonUp(targetName);
                }
                break;

                case "timer":
                {
                    setCountDownLongKey(topBar.timer,"Resetting the timer... ",null, realWorkingTimer.reset,null);
                }
                break;

                default:
                {
                    if(!clickBlockOnWindowActiveFlag)
                    {
                        drawCaptureArea.start();
                    }
                }
                break;
            }
        }

        private function keyUpCaptureMode(e:KeyboardEvent):void
        {
            checkKeyUp(e.keyCode);
        }

        private function keyDownCaptureMode(e:KeyboardEvent):void
        {
            const keyCode:uint = KEY_BUFFER[0];

            if(capStampFontListBox.visible)
            {
                if(keyCode === KEY.esc)
                {
                    setCaptureFontListVisibleOff();
                }
                return;
            }

            if(keyCode === KEY.esc)
            {
                if(stage.focus === topBar.captureInput)
                {
                    stage.focus = null;
                    return;
                }
            }

            if(stage.focus === topBar.captureInput || mouseClickON || rightMouseClickON || isNowKey(keyCode))
            {
                return;
            }

            if(isPressingControl())
            {
                if(KEY_BUFFER.length > 1)
                {
                    const subKey:uint = KEY_BUFFER[1];
                    if(subKey === KEY.s || subKey === KEY.k)
                    {
                        saveCaptureImage();
                    }
                    else if(subKey === KEY.c || subKey === KEY.m)
                    {
                        setCaptureFlashEffect();
                        if(topBar.capClipBoard.alpha === 1.0)
                        {
                            copyCaptureImageToCilpBoard();
                        }
                    }
                }
                return;
            }

            setNowKey(keyCode);

            switch(keyCode)
            {
                case KEY.esc:
                case KEY.backspace:
                case KEY.f1:
                case KEY.f7:
                    setCaptureOFF();
                break;

                case KEY.s:
                case KEY.k:
                    setCaptureRotateButton(++captureRotated);
                break;

                case KEY.a:
                case KEY.l:
                    setCaptrueFlipButton(!captureFlipped);
                break;

                case KEY.d:
                case KEY.j:
                    setCaptureTransButton(!captureTransBGON);
                break;

                case KEY.f:
                case KEY.h:
                    setCaptrueStampButton();
                break;

                case KEY.n1:
                case KEY.n9:
                    setLayer1CheckToggleCaptureMode();
                break;

                case KEY.n2:
                case KEY.n0:
                    setLayer2CheckToggleCaptureMode();
                break;

                default:
                break;
            }
        }

        private function captureMouseMoveHintEvent(e:MouseEvent):void
        {
            if(!captureModeON)
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,captureMouseMoveHintEvent);
                return;
            }

            if(mouseClickON || mouseDragON)
            {
                return;
            }

            setDefaultHintCaptureMode();
        }

        private function setCaptureModeON():void
        {
            if(makeJumpImageFlag === 2 || captureModeON) return;

            if(replayStartON)
            {
                stopReplay();
            }

            captureModeON = true;
            penCursorOFFFlag = true;

            if(numPadBox.visible)
            {
                setNumPadOFF();
            }

            if(!isSidebarVisible)
            {
                if(sideBar.visible)
                {
                    penCursorPosition.setSideBarOFF();
                }
            }

            stage.addEventListener(MouseEvent.MOUSE_MOVE, captureMouseMoveHintEvent);
            setCaptureUI(true);

            var xReg:Sprite;
            var xPanel:Sprite;
            var xZoomed:Number;
            var layer1:Boolean;
            var layer2:Boolean;

            if(replayModeON)
            {
                xReg = rregPoint;
                xPanel = rcanvasPanel;
                xZoomed = rzoomed;
                rCursor.visible = false;
                rcanvasPanel.addChild(captureAreaRect);
                layer1 = true;
                layer2 = true;
            }
            else
            {
                xReg = regPoint;
                xPanel = canvasPanel;
                xZoomed = zoomed;
                canvasPanel.addChild(captureAreaRect);
                if(canvas1Bitmap.visible) layer1 = true;
                if(canvas11Bitmap.visible) layer2 = true;
            }

            setTopChildIndex(captureAreaRect);
            captureAreaRect.visible = true;

            canvasBackupDataOnSave = {
                                    "z" : zoomed,
                                    "x" : Math.floor(regPoint.x), //뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
                                    "y" : Math.floor(regPoint.y),
                                    "r" : regPoint.rotation,
                                    "px" : Math.floor(canvasPanel.x),
                                    "py" : Math.floor(canvasPanel.y)
            }

            canvasBackupData = {
                                    "z" : xZoomed,
                                    "x" : Math.floor(xReg.x), //뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
                                    "y" : Math.floor(xReg.y),
                                    "r" : xReg.rotation,
                                    "px" : Math.floor(xPanel.x),
                                    "py" : Math.floor(xPanel.y),
                                    "layer1" : layer1,
                                    "layer2" : layer2
                                }

            // fitCanvasToWindow(true);
            //캔버스 회전에 fit canvas 함수가 들어있음
            setCaptureRotateButton(captureRotated);
            initCaptrueFlip();
            setCaptureTransButton(captureTransBGON);
            drawCaptureStamp.on();
            drawCaptureStamp.update();
        }

        private function resetCaptureCanvasChangeValue():void
        {
            captureRotated = 0;
            captureFlipped = false;
            captureTransBGON = false;
        }

        private function setCaptureModeOFF(replayMode:Boolean,xReg:Sprite,xPanel:Sprite):void
        {
            const data:Object = canvasBackupData;
            const xBitmap1:Bitmap = (replayMode) ? rcanvas1Bitmap : canvas1Bitmap;
            const xBitmap11:Bitmap = (replayMode) ? rcanvas11Bitmap : canvas11Bitmap;

            xBitmap1.smoothing = false;
            xBitmap11.smoothing = false;

            captureModeON = false;
            penCursorOFFFlag = false;
            captureAreaRect.visible = false;
            captureAreaRect.graphics.clear();
            drawCaptureStamp.off();
            capStampFontListBox.visible = false;

            //캔버스 이전 모양 위치로 복원
            xReg.rotation = data.r;
            xReg.x = data.x+captureWindowMove.x;
            xReg.y = data.y+captureWindowMove.y;
            xPanel.x = data.px;
            xPanel.y = data.py;

            if(replayMode)
            {
                rcanvas1Bitmap.visible = true;
                rcanvas11Bitmap.visible = true;
                rcanvas2.visible = true;
            }
            else
            {
                canvas1Bitmap.visible = data.layer1;
                canvas11Bitmap.visible = data.layer2;
            }

            if(!rFitZoomedON) setZoomCanvas(data.z,replayMode);
            setToolTipOFF();
            captureWindowMove.setTo(0,0);

            updatePenSizeCursor();

            //prev box 사각형 업데이트가 있기 때문에 xreg위치가 갱신된 다음에 해주어야함
            setCaptureUI(false);

            if(replayMode)
            {
                resetTransBG(true);
                rCursor.visible = true;
            }
            else if(!replayMode)
            {
                resetTransBG(false);
            }

            checkCanvasPanelPos(replayMode);
            canvasBackupData = {};
        }

        private function cDrawCaptureStamp():Object
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

            captureStampBitmap.name = "captureStampBitmap";
            captureStampBitmap.visible = false;

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
                capStampFontListBox.setSelectFont(newFont);
                capStampFontListBox.updateFontListSelect(newFont);
                topBar.captureInputFinal.setTextFormat(textformat);
                if(updateFlag) update();
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

            function _kung(textStr:String,textWidth:Number,align:String,posX:Number,offsetX:Number,testHeightFlag:Boolean):Number
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
                return _kung(getAppNameString(newLine),textWidth,"right",captrueStampBMPD.width-textWidth,2,testHeightFlag);
            }

            function kungMainStr(newLine:Boolean,textWidth:Number,testHeightFlag:Boolean):Number
            {
                return _kung(topBar.getCaptureInputString(),textWidth,"left",getTextWidthDate(newLine),0,testHeightFlag);
            }

            function kungDateStr(newLine:Boolean,testHeightFlag:Boolean):Number
            {
                return _kung(getCaptureStampDate(newLine),getTextWidthDate(newLine),"left",2,0,testHeightFlag);
            }

            function kungFinal(inputBMPD:BitmapData):void
            {
                update(); //미자막 시간 찍어줘야함
                const mat:Matrix = new Matrix();
                const ct:ColorTransform = new ColorTransform();

                mat.translate(0,inputBMPD.height-captrueStampBMPD.height);
                inputBMPD.draw(captureStampBitmap,mat,ct);
            }

            function getDominantColor(bitmapData:BitmapData):uint
            {
                var pixels:Vector.<uint> = bitmapData.getVector(bitmapData.rect);
                var totalPixels:int = pixels.length;

                var sumR:uint = 0;
                var sumG:uint = 0;
                var sumB:uint = 0;

                for each (var pixel:uint in pixels) {
                    sumR += (pixel >> 16) & 0xFF;
                    sumG += (pixel >> 8) & 0xFF;
                    sumB += pixel & 0xFF;
                }

                var avgR:int = sumR / totalPixels;
                var avgG:int = sumG / totalPixels;
                var avgB:int = sumB / totalPixels;

                return (avgR << 16) | (avgG << 8) | avgB;
            }

            function getSmallBmpd(clipRect:Rectangle):BitmapData
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
                const rawbmpd:BitmapData = getMergedBitmapdtata(replayModeON,false,true,true,(fullImageFlag) ? null:clipRect);
                tmpbmpd.draw(rawbmpd,mat);

                return tmpbmpd;
            }

            function focusOutCaptureInput(e:FocusEvent):void
            {
                addTimer(0.2,false,function():void
                {
                    setIMEDisabled();
                    capInputFocusFlag = false;
                });
            }

            function focusInCaptureInput(e:FocusEvent):void
            {
                capInputFocusFlag = true;
                addTimer(0.0,false,function():void
                {
                    topBar.captureInput.setSelection(0,topBar.captureInput.text.length);
                });
            }

            function inputCaptureInput(e:Event):void
            {
                topBar.capClipBoard.alpha = 1.0;

                if(!hasTimer("inputUpdateTimer"))
                {
                    addTimerByName("inputUpdateTimer",0.2,false,update);
                }
            }

            function visible(flag:Boolean):void
            {
                if(captureStampBitmap.visible !== flag)
                {
                    captureStampBitmap.visible = flag;
                }
            }

            function checkPosition(bmpdHeight:Number):void
            {
                const rect:Rectangle = drawCaptureArea.getCaptureArea();
                const rotateFlag:uint = captureRotated;
                var offsetX:Number;
                var offsetY:Number;

                if(drawCaptureArea.isFullImageCapture())
                {
                    offsetX = (replayModeON) ? RCANVAS_WIDTH:CANVAS_WIDTH;
                    offsetY = (replayModeON) ? RCANVAS_HEIGHT:CANVAS_HEIGHT;
                }
                else
                {
                    offsetX = rect.width;
                    offsetY = rect.height;
                }

                if(captureFlipped)
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

            function getCaptureAreaWidth(rect:Rectangle):Number
            {
                const notRotatedFlag:Boolean = captureRotated % 2 === 0;

                if(notRotatedFlag)
                {
                    if(drawCaptureArea.isFullImageCapture())
                    {
                        return (replayModeON) ? RCANVAS_WIDTH:CANVAS_WIDTH;
                    }
                    else
                    {
                        return rect.width;
                    }
                }
                else
                {
                    if(drawCaptureArea.isFullImageCapture())
                    {
                        return (replayModeON) ? RCANVAS_HEIGHT:CANVAS_HEIGHT;
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
                if(capStampON)
                {
                    const rect:Rectangle = drawCaptureArea.getCaptureArea();
                    const bmpdWidth:Number = getCaptureAreaWidth(rect);
                    if(bmpdWidth < 300)
                    {
                        if(captureStampBitmap.visible === true)
                        {
                            captureStampBitmap.visible = false;
                        }
                        return;
                    }
                    const smallBmpd:BitmapData = getSmallBmpd(rect);
                    if(!smallBmpd) return;
                    const imageDomiColor:uint = getDominantColor(smallBmpd);
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


                    if(captrueStampBMPD) captrueStampBMPD.dispose();
                    var bmpdHeight:Number = checkCaptrueStampBMPDHeight(twolineFlag,mainTextWidth);
                    captrueStampBMPD = new BitmapData(bmpdWidth,bmpdHeight,true,stampAlpha|imageDomiColor);
                    captureStampBitmap.bitmapData = captrueStampBMPD;

                    if(getColorBrightness(imageDomiColor) >= 150)
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

                    if(replayModeON)
                    {
                        if(rcanvasPanel.getChildByName("captureStampBitmap") === null)
                        {
                            rcanvasPanel.addChild(captureStampBitmap);
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
                    if(replayModeON)
                    {
                        if(rcanvasPanel.getChildByName("captureStampBitmap") !== null)
                        {
                            rcanvasPanel.removeChild(captureStampBitmap);
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
                if(replayModeON)
                {
                    rcanvasPanel.scrollRect = new Rectangle(0,0,RCANVAS_WIDTH,RCANVAS_HEIGHT);
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

                topBar.captureInput.removeEventListener(Event.CHANGE,inputCaptureInput);
                topBar.captureInput.removeEventListener(FocusEvent.FOCUS_IN,focusInCaptureInput);
                topBar.captureInput.removeEventListener(FocusEvent.FOCUS_OUT,focusOutCaptureInput);

                captureStampBitmap.visible = false;
                if(canvasPanel.getChildByName("captureStampBitmap") !== null)
                {
                    canvasPanel.removeChild(captureStampBitmap);
                }
            }

            function on():void
            {
                if(replayModeON)
                {
                    rcanvasPanel.scrollRect = null;
                }
                else
                {
                    canvasPanel.scrollRect = null;
                }

                textformat.font = null;

                topBar.captureInput.addEventListener(Event.CHANGE,inputCaptureInput);
                topBar.captureInput.addEventListener(FocusEvent.FOCUS_IN,focusInCaptureInput);
                topBar.captureInput.addEventListener(FocusEvent.FOCUS_OUT,focusOutCaptureInput);
            }

            return{
                on:on,
                off:off,
                update:update,
                visible:visible,
                kungFinal:kungFinal,
                changeFont:changeFont,
                getFontName:getFontName
            };

        }

        //마우스 클릭하면 캡쳐 영역그리는 함수
        private function cDrawCaptureArea():Object
        {
            var xPanel:Sprite;
            var mouseMoved:Boolean = false;
            var canvasWidth:Number = 0;
            var canvasHeight:Number = 0;
            var clickPos:Point = new Point(0,0);
            var limitWidthSave:Number = 0;
            var limitHeightSave:Number = 0;
            const rectFull:Rectangle = new Rectangle();
            const rectGhost:Rectangle = new Rectangle();
            const rect:Rectangle = new Rectangle();
            var resizeFlag:Boolean = false;
            const resizeButtonSize:Number = 20.0;
            const resizeButtonPos:Point = new Point(0,0);
            var minSize:Number = 10.0;
            const mouseMoveOffset:Number = 5.0;

            function checkIntersectRect():void
            {
                var intersection:Rectangle = rectFull.intersection(rect);

                if(intersection.width >= minSize && intersection.height >= minSize)
                {
                    rect.x = Math.round(intersection.x);
                    rect.y = Math.round(intersection.y);
                    rect.width = Math.round(intersection.width);
                    rect.height = Math.round(intersection.height);
                }
                else
                {
                    addTimer(0.0,false,function():void
                    {
                        resetCaptureArea();
                    });
                }
            }

            function checkIsRectEdgeNegative():void
            {
                if(rect.width < 0)
                {
                    rect.width = Math.abs(rect.width);
                    rect.x = rect.x-rect.width;
                }

                if(rect.height < 0)
                {
                    rect.height = Math.abs(rect.height);
                    rect.y = rect.y-rect.height;
                }
            }

            function captureMouseMoveEvent2(e:MouseEvent):void
            {
                if(!captureModeON)
                {
                    removeEvent();
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
                        if(!captureFlipped && captureRotated === 0 || captureFlipped && captureRotated === 3)
                        {
                            rectGhost.width += subX;
                            rectGhost.height += subY;
                            rect.width = rectGhost.width;
                            rect.height = rectGhost.height;

                            if(rect.width < minSize) rect.width = minSize;
                            else if(rect.x+rect.width > canvasWidth) rect.width = canvasWidth-rect.x;

                            if(rect.height < minSize) rect.height = minSize;
                            else if(rect.y+rect.height > canvasHeight) rect.height = canvasHeight-rect.y;
                        }
                        else if(!captureFlipped && captureRotated === 1 || captureFlipped && captureRotated === 2)
                        {
                            rectGhost.width += subX;
                            rectGhost.height -= subY;
                            rectGhost.y += subY;
                            rect.width = rectGhost.width;
                            rect.height = rectGhost.height;
                            rect.y = rectGhost.y;

                            if(rect.y < 0.0)
                            {
                                rect.y = 0.0;
                                rect.height = limitHeightSave;
                            }
                            if(rect.height < minSize)
                            {
                                rect.height = minSize;
                                rect.y = limitHeightSave-rect.height;
                            }

                            if(rect.width < minSize) rect.width = minSize;
                            else if(rect.x+rect.width > canvasWidth) rect.width = canvasWidth-rect.x;
                        }
                        else if(!captureFlipped && captureRotated === 2 || captureFlipped && captureRotated === 1)
                        {
                            rectGhost.width -= subX;
                            rectGhost.height -= subY;
                            rectGhost.x += subX;
                            rectGhost.y += subY;
                            rect.width = rectGhost.width;
                            rect.height = rectGhost.height;
                            rect.x = rectGhost.x;
                            rect.y = rectGhost.y;

                            if(rect.width < minSize)
                            {
                                rect.width = minSize;
                                rect.x = limitWidthSave-rect.width;
                            }

                            if(rect.height < minSize)
                            {
                                rect.height = minSize;
                                rect.y = limitHeightSave-rect.height;
                            }

                            if(rect.x < 0.0)
                            {
                                rect.x = 0.0;
                                rect.width = limitWidthSave;
                            }

                            if(rect.y < 0.0)
                            {
                                rect.y = 0.0;
                                rect.height = limitHeightSave;
                            }
                        }
                        else if(!captureFlipped && captureRotated === 3 || captureFlipped && captureRotated === 0)
                        {
                            rectGhost.width -= subX;
                            rectGhost.height += subY;
                            rectGhost.x += subX;

                            rect.width = rectGhost.width;
                            rect.height = rectGhost.height;
                            rect.x = rectGhost.x;

                            if(rect.x < 0.0)
                            {
                                rect.x = 0.0;
                                rect.width = limitWidthSave;
                            }

                            if(rect.width < minSize)
                            {
                                rect.width = minSize;
                                rect.x = limitWidthSave-rect.width;
                            }

                            if(rect.height < minSize) rect.height = minSize;
                            else if(rect.y+rect.height > canvasHeight) rect.height = canvasHeight-rect.y;
                        }

                        hint.on(getRotatedRectSizeString(),null);
                    }
                    else
                    {
                        rectGhost.x += subX;
                        rectGhost.y += subY;
                        rect.x = rectGhost.x;
                        rect.y = rectGhost.y;

                        if(rect.x < 0.0) rect.x = 0.0;
                        else if(rect.x+rect.width > canvasWidth) rect.x = canvasWidth-rect.width;

                        if(rect.y < 0.0) rect.y = 0.0;
                        else if(rect.y+rect.height > canvasHeight) rect.y = canvasHeight-rect.height;
                    }

                    rect.x = Math.round(rect.x);
                    rect.y = Math.round(rect.y);
                    rect.width = Math.round(rect.width);
                    rect.height = Math.round(rect.height);

                    clickPos.setTo(xPanel.mouseX,xPanel.mouseY);
                    drawArea(false);
                }
                else if(Math.abs(subX) >= mouseMoveOffset || Math.abs(subY) >= mouseMoveOffset)
                {
                    mouseMoved = true;
                    clickPos.setTo(mx,my);
                    drawCaptureStamp.visible(false);
                }
            }

            function captureMouseMoveEvent(e:MouseEvent):void
            {
                if(!captureModeON)
                {
                    removeEvent();
                    return;
                }

                var mx:Number = xPanel.mouseX;
                var my:Number = xPanel.mouseY;
                var subX:Number = Math.round(mx-clickPos.x);
                var subY:Number = Math.round(my-clickPos.y);

                if(mouseMoved)
                {
                    rectGhost.width = subX;
                    rectGhost.height = subY;

                    rect.x = rectGhost.x;
                    rect.y = rectGhost.y;
                    rect.width = rectGhost.width;
                    rect.height = rectGhost.height;
                    checkIsRectEdgeNegative();

                    hint.on(getRotatedRectSizeString(),null);
                    drawArea(false);

                }
                else if(Math.abs(subX) >= mouseMoveOffset || Math.abs(subY) >= mouseMoveOffset)
                {
                    rectGhost.x = clickPos.x;
                    rectGhost.y = clickPos.y;
                    rectGhost.width = subX;
                    rectGhost.height = subY;

                    rect.x = rectGhost.x;
                    rect.y = rectGhost.y;
                    rect.width = rectGhost.width;
                    rect.height = rectGhost.height;

                    clickPos.setTo(mx,my);
                    hint.on(getRotatedRectSizeString(),null);
                    mouseMoved = true;
                    drawCaptureStamp.visible(false);
                }
            }

            function captureMouseUp(e:MouseEvent):void
            {
                mouseDragON = false;
                removeEvent();

                if(mouseMoved === true)
                {
                    //rect길이가 음수인경우 cx cy를 양수로 다시 맞추어줌
                    checkIsRectEdgeNegative();
                    checkIntersectRect();
                    setDefaultHintCaptureMode();
                    topBar.capClipBoard.alpha = 1.0;

                    drawArea(true);
                    drawCaptureStamp.update();
                }
                // else if(!capInputFocusFlag)
                // {
                //     saveCaptureImage();
                // }
                mouseMoved = false;
            }

            function removeEvent():void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,captureMouseMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,captureMouseMoveEvent2);
                stage.removeEventListener(MouseEvent.MOUSE_UP,captureMouseUp);
            }

            function updateDrawArea(forceFlag:Boolean=false):void
            {
                if(rect.width > minSize && rect.height > minSize || forceFlag) drawArea(true);
                drawCaptureStamp.update();
            }

            function getCanvasScale():Number
            {
                return (replayModeON) ? Math.abs(rregPoint.scaleX) : Math.abs(regPoint.scaleX);
            }

            function drawResizeButton(scale:Number):void
            {
                if(isFullImageCapture())
                {
                    return;
                }

                captureAreaRect.graphics.lineStyle(1,0xFFFFFF,1.0,true);
                captureAreaRect.graphics.beginFill(0xFF6600);
                var posX:Number = rect.x;
                var posY:Number = rect.y;
                const offset:Number = 5/scale;

                if(!captureFlipped && captureRotated === 0|| captureFlipped && captureRotated === 3)
                {
                    posX += rect.width+offset;
                    posY += rect.height+offset;
                }
                else if(!captureFlipped && captureRotated === 1 || captureFlipped && captureRotated === 2)
                {
                    posX += rect.width+offset;
                    posY += -offset;
                }
                else if(!captureFlipped && captureRotated === 3 || captureFlipped && captureRotated === 0)
                {
                    posY += rect.height+offset;
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
                    p = rotatePoint(pos[i],pos[i+1],captureRotated*90.0);
                    pos[i] = posX+p.x*((captureFlipped)?-1.0:1.0);
                    pos[i+1] = posY+p.y;
                }
                captureAreaRect.graphics.drawPath(cmd,pos);
                captureAreaRect.graphics.endFill();
            }

            function drawArea(resizeButtonON:Boolean):void
            {
                const zoomed:Number = getCanvasScale();

                const lineSize:Number = Math.ceil(1/zoomed);
                captureAreaRect.graphics.clear();

                //배경색 약간 어둡게 해줌
                captureAreaRect.graphics.lineStyle(0,0,0);
                captureAreaRect.graphics.beginFill(0,0.3);
                captureAreaRect.graphics.drawRect(0,0,canvasWidth,rect.y); //위
                captureAreaRect.graphics.drawRect(0,rect.y,rect.x,rect.height);//왼쪽
                captureAreaRect.graphics.drawRect(rect.x+rect.width,rect.y,canvasWidth-(rect.x+rect.width),rect.height); //오른쪽
                captureAreaRect.graphics.drawRect(0,rect.y+rect.height,canvasWidth,canvasHeight-(rect.y+rect.height)); //아래
                captureAreaRect.graphics.endFill();
                captureAreaRect.graphics.lineStyle(lineSize,0xFFFFFF,1.0,true);
                captureAreaRect.graphics.drawRect(rect.x,rect.y,rect.width,rect.height);

                if(resizeButtonON)
                {
                    drawResizeButton(zoomed);
                }
            }

            function getRotatedRectSizeString():String
            {
                const w:Number = Math.abs(rect.width);
                const h:Number = Math.abs(rect.height);

                if(rect.x === 0.0 && rect.y === 0.0 && rect.width === 0.0 && rect.height === 0.0)
                {
                    if(replayModeON)
                    {
                        return (captureRotated === 0 || captureRotated === 2) ? RCANVAS_WIDTH+" x "+RCANVAS_HEIGHT : RCANVAS_HEIGHT+" x "+RCANVAS_WIDTH;
                    }
                    else
                    {
                        return (captureRotated === 0 || captureRotated === 2) ? CANVAS_WIDTH+" x "+CANVAS_HEIGHT : CANVAS_HEIGHT+" x "+CANVAS_WIDTH;
                    }
                }

                return (captureRotated === 0 || captureRotated === 2) ? w+" x "+h : h+" x "+w;
            }

            function resetCaptureArea():void
            {
                resizeButtonPos.setTo(0,0);
                resizeFlag = false;
                clickPos.setTo(0,0);
                rect.x = 0;
                rect.y = 0;
                rect.width = 0;
                rect.height = 0;
                rectGhost.x = 0;
                rectGhost.y = 0;
                rectGhost.width = 0;
                rectGhost.height = 0;
                rectFull.x = 0;
                rectFull.y = 0;
                rectFull.width = 0;
                rectFull.height = 0;
                limitWidthSave = 0;
                limitHeightSave = 0;
                captureAreaRect.graphics.clear();
                topBar.capClipBoard.alpha = 1.0;
                setDefaultHintCaptureMode();
                drawCaptureStamp.update();
            }

            function reset():void
            {
                resizeButtonPos.setTo(0,0);
                resizeFlag = false;
                clickPos.setTo(0,0);
                rect.x = 0;
                rect.y = 0;
                rect.width = 0;
                rect.height = 0;
                rectGhost.x = 0;
                rectGhost.y = 0;
                rectGhost.width = 0;
                rectGhost.height = 0;
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
                return rect.width === 0.0 || rect.height === 0.0;
            }

            function getCaptureArea():Rectangle
            {
                return rect;
            }

            function isCursorInCaptureDrea():Boolean
            {
                if(!xPanel) return false;

                return rect.contains(xPanel.mouseX,xPanel.mouseY);
            }

            function isCursorInResizeButton():Boolean
            {
                if(!xPanel) return false

                const p1:Point = new Point(xPanel.mouseX,xPanel.mouseY);

                if(Point.distance(p1,resizeButtonPos)*getCanvasScale() < resizeButtonSize)
                {
                    return true;
                }

                return false;
            }

            function setMoveOrResizeAreaReady(mx:Number,my:Number,flag:Boolean):void
            {
                mouseDragON = true;
                resizeFlag = flag;
                rectGhost.x = rect.x;
                rectGhost.y = rect.y;
                rectGhost.width = rect.width;
                rectGhost.height = rect.height;
                limitWidthSave = rect.x+rect.width;
                limitHeightSave = rect.y+rect.height;

                clickPos.setTo(mx,my);
                stage.addEventListener(MouseEvent.MOUSE_MOVE, captureMouseMoveEvent2);
                stage.addEventListener(MouseEvent.MOUSE_UP,captureMouseUp);
            }

            function start():void
            {
                if(topBar.hitTestPoint(mouseX,mouseY) === false)
                {
                    if(replayModeON) //리플레이 변수로 변경
                    {
                        canvasWidth = RCANVAS_WIDTH;
                        canvasHeight = RCANVAS_HEIGHT;
                        xPanel = rcanvasPanel;
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
                        setMoveOrResizeAreaReady(mx,my,true);
                    }
                    else if(isCursorInCaptureDrea())
                    {
                        setMoveOrResizeAreaReady(mx,my,false);
                    }
                    else
                    {
                        clickPos.setTo(mx,my);
                        mouseDragON = true;
                        stage.addEventListener(MouseEvent.MOUSE_MOVE, captureMouseMoveEvent);
                        stage.addEventListener(MouseEvent.MOUSE_UP,captureMouseUp);
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

        private function getRandomString(charLength:int = 6):String
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

        private function cutTimeStamp(str:String):String
        {
            const pattern:RegExp = /_\d\d\d\d\d\d\d\d\d/g;
            const findTimeStamp:String = pattern.exec(str);

            if(findTimeStamp === null) return str;

            const cutIndex:int = str.lastIndexOf(findTimeStamp);
            const cutStr:String = str.substr(0,cutIndex);

            return cutStr;
        }

        private function getTimeStampTailHead():String
        {
            const date:Date = new Date();
            const y:Number = date.getFullYear();
            const m:Number = date.getMonth()+1;
            const d:Number = date.getDate();
            const daystr:String = (d < 10) ? "0"+d : ""+d;
            const monthstr:String = (m < 10) ? "0"+m : ""+m;
            const timeStr:String = "["+y+"-"+monthstr+daystr+"]";

            return timeStr;
        }

        private function getTimeStampTail():String
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

        private function saveCapturePNGByOrder(saveName:String,savePath:String):void
        {
            workerPNGCaptureFileData.push([saveName,savePath]);
            if(!hasTimer("workerPNGCaptureTimer"))
            {
                addTimerByName("workerPNGCaptureTimer",WORKER_WAIT_INTERVAL,true,function():Boolean
                {
                    if(workerPNGCaptureData.length > 0)
                    {
                        while(workerPNGCaptureData.length > 0)
                        {
                            const fileName:String = workerPNGCaptureFileData[0][0];
                            const filePath:String = workerPNGCaptureFileData[0][1];

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
                            fs.writeBytes(workerPNGCaptureData[0]);
                            fs.close();
                            workerPNGCaptureData[0].clear();
                            workerPNGCaptureData[0] = null;
                            workerPNGCaptureData.shift();

                            workerPNGCaptureFileData[0] = null;
                            workerPNGCaptureFileData.shift();
                        }
                    }
                    else if(workerPNGCaptureData.length === 0 && workerPNGCaptureFileData.length === 0)
                    {
                        workerPNGCaptureFileData = null;
                        workerPNGCaptureData = null;
                        return false;
                    }
                    return true;
                });
            }
        }

        private function saveCaptureImage():void
        {
            if(fileBrowserON) return;

            setCaptureFlashEffect();

            const replayMode:Boolean = replayModeON;
            var name:String = saveFileName;
            var path:String = saveFilePath;
            const nextPath:String = checkExistingParentDirectory(path);

            if(path !== nextPath)
            {
                path = nextPath;
            }

            setFileBrowserONFlag(true);

            name = cutTimeStamp(name);
            name = name.substr(0,name.lastIndexOf(".png"))+"_"+getTimeStampTail()+".png";//뒤에 프레임 번호 붙여줌
            path = path.substr(0,path.lastIndexOf(saveFileName))+name;

            var file:File = (name !== path ) ? new File(path): File.desktopDirectory.resolvePath(name);

            const fs:FileStream = new FileStream();
            const saveWindowTitle:String = "Save image";

            file.addEventListener(IOErrorEvent.IO_ERROR, onCancelEvent);
            file.addEventListener(Event.CANCEL, onCancelEvent);
            file.addEventListener(Event.SELECT, onSelectEvent);
            file.browseForSave(saveWindowTitle);

            function onCancelEvent(e:Event):void
            {
                setFileBrowserONFlag(false);
                file.cancel();
                file.removeEventListener(IOErrorEvent.IO_ERROR, onCancelEvent);
                file.removeEventListener(Event.CANCEL, onCancelEvent);
                file.removeEventListener(Event.SELECT, onSelectEvent);
            }

            function onSelectEvent(e:Event):void
            {
                setFileBrowserONFlag(false);
                file.cancel();
                file.removeEventListener(IOErrorEvent.IO_ERROR,onCancelEvent);
                file.removeEventListener(Event.CANCEL,onCancelEvent);
                file.removeEventListener(Event.SELECT,onSelectEvent);

                if(workerPNGCaptureData === null) workerPNGCaptureData = new Vector.<ByteArray>();
                if(workerPNGCaptureFileData === null) workerPNGCaptureFileData = [];

                callWorkerEncodePNG(getCaptrueImageBitmapdata(false),0,true,captureTransBGON);
                saveCapturePNGByOrder(file.name,e.target.nativePath);
            }
        }

        private function checkSaveFailedFileName(saveFailed:Boolean):File
        {
            var _path:String = saveFilePath;
            var _name:String = saveFileName;

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

        private function checkNotPNGExtension(name:String,path:String):Array
        {
            const extArr:Array = [".2020",".jpg",".gif"];
            var fixedPath:String;
            var dotPNG:String;

            for(var i:uint=0; i<3; i++)
            {
                if(name.lastIndexOf(extArr[i]) !== -1)
                {
                    fixedPath = path.replace(name,"");
                    dotPNG = name.substr(0,name.lastIndexOf(extArr[i]))+".png";
                    return [fixedPath+dotPNG,dotPNG];
                }
            }

            if(name.lastIndexOf(".png") === -1)
            {
                fixedPath = path.replace(name,"");
                dotPNG = name+".png";
                return [fixedPath+dotPNG,dotPNG];
            }

            return [path,name];
        }
        
        //끝의 파일 구분자가 있으면 제거해줌
        private function removeLastFileSeparator(path:String):String
        {
            if (path.charAt(path.length - 1) === File.separator)
            {
                return path.substring(0, path.length - 1);
            }
            return path;
        }

        //해당 디렉토리가 없으면 그 상위 디렉토리로 위치를 바꾸어줌
        private function checkExistingParentDirectory(path:String):String
        {
            var cleanPath:String = removeLastFileSeparator(path);
            var testPath:String = cleanPath;
            var file:File = new File(testPath);
            var lastSep:int;

            if(!file.isDirectory)
            {
                lastSep = testPath.lastIndexOf(File.separator);
                testPath = testPath.substring(0, lastSep);
                cleanPath = testPath;
            }
            
            while (true)
            {
                file = new File(testPath);

                if (file.exists && file.isDirectory)
                {
                    return testPath + File.separator + saveFileName;
                }

                // 마지막 separator 위치 찾기
                lastSep = testPath.lastIndexOf(File.separator);
                if (lastSep === -1)
                    break;

                // 상위 경로로 이동
                testPath = testPath.substring(0, lastSep);
            }

            // 유효한 디렉토리를 찾지 못하면 데스크톱 반환
            return File.desktopDirectory.nativePath + File.separator + saveFileName;
        }

        private function saveFile(asFlag:Boolean,saveFailed:Boolean=false):void
        {
            //계속 저장하는거 방지 다른 이름으로 저장은 예외
            if(replayStartON) stopReplay();
            const continueFlag:Boolean = (saveContinue === true && asFlag === false);
            const nextPath:String = checkExistingParentDirectory(saveFilePath);
            const pngFile:File = new File(saveFilePath);
            const rawFilePath:String = saveFilePath.substr(0,saveFilePath.lastIndexOf(".png"))+".2020";
            const nowRawFile:File = new File(rawFilePath);
            const fofoFileExists:Boolean = pngFile.exists && nowRawFile.exists;

            if(nextPath === saveFilePath && saveOneTime && continueFlag && fofoFileExists)
            {
                if(updateAfterSaveFlag)
                {
                    startUpdate();
                }
                else
                {
                    if(saveThenLoadFlag)
                    {
                        loadImageDragDrop(false);
                    }
                    else
                    {
                        setHintONTemp("Already saved");
                    }
                }
                return;
            }

            if(lassoToolON || fillPenStarted || isInSaveProgress)
            {
                return;
            }

            const fs:FileStream = new FileStream();
            const mergedImage:BitmapData = getMergedBitmapdtata(false,false,true,true,null);

            setTopBarHintOFF();
            if(nextPath !== saveFilePath)
            {
                saveFilePath = nextPath;
            }

            if(continueFlag)
            {
                if(fofoFileExists === true)
                {
                    function saveContinueErrorEvent(e:Event):void
                    {
                        sethintOFFDelay();
                        fs.close();
                        fs.removeEventListener(IOErrorEvent.IO_ERROR,saveContinueErrorEvent);
                        saveOneTime = false;
                        if(saveThenLoadFlag)
                        {
                            loadImageDragDrop(false);
                        }
                        else
                        {
                            saveFile(true,true);
                        }
                    }

                    fs.addEventListener(IOErrorEvent.IO_ERROR,saveContinueErrorEvent);

                    setSaveProgressON();
                    workerPNGSaveData = null;
                    callWorkerEncodePNG(mergedImage.clone(),CANVAS_BG_COLOR,false,false);
                    saveReplayFile();
                    updateWindowTitle();
                    resetKeyBuffer();
                    saveOneTime = true;

                    addTimerByName("workerPNGSaveTimer",WORKER_WAIT_INTERVAL,true,function():Boolean
                    {
                        if(workerPNGSaveData !== null)
                        {
                            fs.openAsync(pngFile,FileMode.WRITE);
                            fs.writeBytes(workerPNGSaveData);
                            fs.close();
                            fs.removeEventListener(IOErrorEvent.IO_ERROR,saveContinueErrorEvent);

                            workerPNGSaveData.clear();
                            workerPNGSaveData = null;
                            return false;
                        }
                        return true;
                    });
                }
                else //파일을 못찾으면 새로 저장
                {
                    saveContinue = false;
                    saveFile(true);
                }
            }
            else
            {
                if(fileBrowserON) return;

                const file:File = checkSaveFailedFileName(saveFailed);
                const saveWindowTitle:String = (saveFailed) ? "Failed to save file! save with new name"
                                                :(asFlag === true) ? "Save file As.."
                                                :(saveThenLoadFlag) ? "Save file before load file"
                                                :(updateAfterSaveFlag) ? "Save file before update":"Save file";

                file.addEventListener(IOErrorEvent.IO_ERROR, onErrorEvent);
                file.addEventListener(Event.CANCEL, onErrorEvent);
                file.addEventListener(Event.SELECT, onSelectEvent);
                file.browseForSave(saveWindowTitle);

                setFileBrowserONFlag(true);

                function removeEvent():void
                {
                    file.removeEventListener(IOErrorEvent.IO_ERROR, onErrorEvent);
                    file.removeEventListener(Event.CANCEL, onErrorEvent);
                    file.removeEventListener(Event.SELECT, onSelectEvent);
                }

                function onErrorEvent(e:Event):void
                {
                    setFileBrowserONFlag(false);
                    file.cancel();
                    removeEvent();

                    if(saveThenLoadFlag)
                    {
                        loadImageDragDrop(false);
                    }
                    else if(updateAfterSaveFlag)
                    {
                        startUpdate();
                    }
                }

                function onSelectEvent(e:Event):void
                {
                    setFileBrowserONFlag(false);
                    setSaveProgressON();
                    removeEvent();

                    saveOneTime = true;
                    saveContinue = true;

                    const fName:String = file.name;
                    const fPath:String = e.target.nativePath;
                    //확장자가 2020이거나 png일경우 무시하고 원래 이름대로 저장  img.2020.png이렇게 중복되게 저장되는거 막음
                    var newFileData:Array = checkNotPNGExtension(fName,fPath);

                    saveFilePath = newFileData[0];
                    saveFileName = newFileData[1];
                    var f1:File = new File(newFileData[0]);

                    workerPNGSaveData = null;
                    callWorkerEncodePNG(mergedImage.clone(),CANVAS_BG_COLOR,false,false);
                    saveReplayFile();
                    updateWindowTitle();

                    addTimerByName("workerPNGSaveTimer",WORKER_WAIT_INTERVAL,true,function():Boolean
                    {
                        if(workerPNGSaveData !== null)
                        {
                            fs.openAsync(f1,FileMode.WRITE);
                            fs.writeBytes(workerPNGSaveData);
                            fs.close();

                            workerPNGSaveData.clear();
                            workerPNGSaveData = null;

                            return false;
                        }
                        return true;
                    });
                }
            }
        }

        private function saveReplayFrameData():void
        {
            const fs:FileStream = new FileStream();
            fs.open(rJumpImageFrameDataFile,FileMode.WRITE);
            fs.writeObject(rJumpImageFrameData);
            fs.close();
        }

        private function loadUndoData():void
        {
            if(undoDataFile.exists === false)
            {
                return;
            }

            rMirrorON = false;
            mirrorON = false;
            appInfoBox.setMirror(false);

            const fs:FileStream = new FileStream();
            fs.open(undoDataFile,FileMode.READ);

            const lastUndoIndex:int = fs.readInt();
            var arr:Array = fs.readObject() as Array; //undodata first
            const bmpdRect:Rectangle = new Rectangle(0,0,arr[2],arr[3]);
            var bmpd:BitmapData = new BitmapData(arr[2],arr[3],true,0);
            var bmpd1:BitmapData = new BitmapData(arr[2],arr[3],true,0);

            if(arr[6] is Number)
            {
                undoData.setRFileTotalFrame(arr[6]);
            }
            else if(oldAppdataRtotalFrame >= 0)
            {
                undoData.setRFileTotalFrame(oldAppdataRtotalFrame);
            }

            rData = (fs.readObject() as Array).concat();
            rDataFrame = (fs.readObject() as Array).concat();
            fs.close();

            undoIndex = lastUndoIndex;
            bmpd.lock();
            bmpd.setPixels(bmpdRect,arr[0]);
            bmpd.unlock();
            bmpd1.lock();
            bmpd1.setPixels(bmpdRect,arr[1]);
            bmpd1.unlock();
            undoData.setUndoRefImage(bmpd.clone(),bmpd1.clone(),arr[2],arr[3],arr[4],arr[5]);

            drawUndoData();
            rCursor.visible = false;
            toolTipBoxTimerOFF();
            bmpd.dispose();
            bmpd1.dispose();
            bmpd = null;
            bmpd1 = null;
            arr.length = 0;
            arr = null;

            //undo index가 arr의 가장 마지막 부분이 아니면 undo를 하던 중이니까 undoDelFlag 켜줌
            if(lastUndoIndex < rData.length-1) undoDelFlag = true;
            else undoDelFlag = false;
        }

        private function loadScratchPadImage():void
        {
            const fs:FileStream = new FileStream();
            const ba:ByteArray = new ByteArray();
            const bmpd:BitmapData = pickerBox.scratchPad.getBitmapData();

            fs.open(scratchDataFile,FileMode.READ);
            var arr:Array = fs.readObject() as Array;
            fs.close();

            bmpd.lock();
            bmpd.setPixels(new Rectangle(0,0,arr[1],arr[2]),arr[0]);
            bmpd.unlock();
        }

        private function saveScratchPadImage():void
        {
            const fs:FileStream = new FileStream();
            const ba:ByteArray = new ByteArray();
            const bmpd:BitmapData = pickerBox.scratchPad.getBitmapData();
            const newRectangle:Rectangle = new Rectangle(0,0,bmpd.width,bmpd.height);
            bmpd.copyPixelsToByteArray(pickerBox.scratchPad.getBitmapData().rect,ba);

            fs.open(scratchDataFile,FileMode.WRITE);
            fs.writeObject([ba,newRectangle.width,newRectangle.height]);
            fs.close();
        }

        private function saveUndoData():void
        {
            const fs:FileStream = new FileStream();
            const arr:Array = undoData.getUndoRefImage();
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
            var newArr:Array = [ba,ba1,arr[2],arr[3],arr[4],arr[5],undoData.getRFileTotalFrame()];

            fs.open(undoDataFile,FileMode.WRITE);
            fs.writeInt(undoIndex);
            fs.writeObject(newArr);
            fs.writeObject(rData);
            fs.writeObject(rDataFrame);
            fs.close();

            ba.clear();
            ba1.clear();
            ba = null;
            ba = null;
        }

        private function updateWindowSizeInfo():void
        {
            const windowSizeInfo:Rectangle = stage.nativeWindow.bounds;

            lastWindowSizeInfo[0] = windowSizeInfo.x;
            lastWindowSizeInfo[1] = windowSizeInfo.y;
            lastWindowSizeInfo[2] = windowSizeInfo.width;
            lastWindowSizeInfo[3] = windowSizeInfo.height;
        }

        private function saveAppData():void
        {
            updateWindowSizeInfo();

            const fs:FileStream = new FileStream();

            fs.open(appDataFile, FileMode.WRITE);
            fs.writeObject({"CANVAS_WIDTH":CANVAS_WIDTH,
                            "CANVAS_HEIGHT":CANVAS_HEIGHT,
                            "zoomed":(captureModeON) ? canvasBackupDataOnSave.z:zoomed,
                            "zoomedIndex":zoomedIndex,
                            "canvasPanel.x":(captureModeON) ? canvasBackupDataOnSave.px:canvasPanel.x,
                            "canvasPanel.y":(captureModeON) ? canvasBackupDataOnSave.py:canvasPanel.y,
                            "regPoint.x":(captureModeON) ? canvasBackupDataOnSave.x:regPoint.x,
                            "regPoint.y":(captureModeON) ? canvasBackupDataOnSave.y:regPoint.y,
                            "regPoint.rotation":(captureModeON) ? canvasBackupDataOnSave.r:regPoint.rotation,
                            "penSmoothValue":penSmoothValue,
                            "penSmoothSlideValue":penSmoothSlideValue,
                            "penSmoothButtonX":controlBox.penSmoothSliderCursor.x,
                            "penSize":penSize,
                            "penSizeIndex":penSizeIndex,
                            "penColor":penColor,
                            "penAlpha":penAlpha,
                            "penShape":penShape,
                            "eraseSize":eraseSize,
                            "eraseSizeIndex":eraseSizeIndex,
                            "eraseShape":eraseShape,
                            "eraseAlpha":eraseAlpha,
                            "stage.nativeWindow.x":lastWindowSizeInfo[0],
                            "stage.nativeWindow.y":lastWindowSizeInfo[1],
                            "stage.nativeWindow.width":lastWindowSizeInfo[2],
                            "stage.nativeWindow.height":lastWindowSizeInfo[3],
                            "saveFileName":saveFileName,
                            "toolBox.scaleX":toolBox.scaleX,
                            "lastWindowState":lastWindowState,
                            "uiColorIndex":uiColorIndex,
                            "APP_RUNNING_TIME":realWorkingTimer.getRunningTime(),
                            "traceAlphaSave":traceAlphaSave,
                            "traceOpaButtonX":traceMenu["traceOpaButton"].x,
                            "traceReizeMoveSum":traceReizeMoveSum,
                            "tracePosInfo[0]":tracePosInfo[0],
                            "tracePosInfo[1]":tracePosInfo[1],
                            "tracePosInfo[2]":tracePosInfo[2],
                            "tracePosInfo[3]":tracePosInfo[3],
                            "tracePosInfo[4]":tracePosInfo[4],
                            "tracePosInfo[5]":tracePosInfo[5],
                            "traceMenuPos[0]":traceMenu.x,
                            "traceMenuPos[1]":traceMenu.y,
                            "mirrorON":mirrorON,
                            "gridValue":gridValue,
                            "gridDrawOffsetX":gridDrawOffsetX,
                            "gridDrawOffsetY":gridDrawOffsetY,
                            "hueCursor.x":pickerBox["hueCursor"].x,
                            "svBaseColor":pickerBox["svBaseColor"],
                            "hsvColorArr[0]":hsvColorArr[0],
                            "rgbInfoColorTypeHSV":rgbInfoColorTypeHSV,
                            "makeJumpImageFlag":(makeJumpImageFlag === 2) ? 1:makeJumpImageFlag,
                            "rBGColorSave":rBGColorSave,
                            "isRightSidebar":isRightSidebar,
                            "saveFilePath":saveFilePath,
                            "isSidebarVisible":isSidebarVisible,
                            "uiScaleIndex":uiScaleIndex,
                            "canvasWindowON":canvasWindowON,
                            "canvasWindowInfo[0]":canvasWindowInfo[0],
                            "canvasWindowInfo[1]":canvasWindowInfo[1],
                            "canvasWindowInfo[2]":canvasWindowInfo[2],
                            "canvasWindowInfo[3]":canvasWindowInfo[3],
                            "getFirstRCursorPos.x":tickDraw.getFirstRCursorPos().x,
                            "getFirstRCursorPos.y":tickDraw.getFirstRCursorPos().y,
                            "saveContinue":saveContinue,
                            "myPalettePresetType":myPalettePresetType,
                            "myPaletteViewAllMode":myPaletteViewAllMode,
                            "pickerBoxSwapPositionFlag":pickerBoxSwapPositionFlag,
                            "topBar.captureInput.text":topBar.captureInput.text,
                            "capStampON":capStampON,
                            "captureStampFont":drawCaptureStamp.getFontName(),
                            "scrollSetMovedY":scrollSetMovedY
                            });
            fs.close();
        }

        private function loadAppData():void
        {
            const fs:FileStream = new FileStream();
            var arr:Array = [];
            var newRectangle:Rectangle;
            //앱 경로에 마지막 저장 파일이 있으면 끄기전의 상태로 세팅해줌

            if(rFirstImageFile.exists)
            {
                fs.open(rFirstImageFile, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();

                if(arr[1] is ByteArray === false)
                {
                    arr[0].uncompress();
                    newRectangle = new Rectangle(0,0,arr[1],arr[2]);
                    if(rFirstImage) rFirstImage.dispose();
                    rFirstImage = new BitmapData(arr[1],arr[2],true,0);
                    rFirstImage.lock();
                    rFirstImage.setPixels(newRectangle,arr[0]);
                    rFirstImage.unlock();
                    if(rFirstImage1) rFirstImage1.dispose();
                    rFirstImage1 = new BitmapData(arr[1],arr[2],true,0);
                    rFirstBGColor = arr[3];
                }
                else
                {
                    arr[0].uncompress();
                    newRectangle = new Rectangle(0,0,arr[2],arr[3]);
                    if(rFirstImage) rFirstImage.dispose();
                    rFirstImage = new BitmapData(arr[2],arr[3],true,0);
                    rFirstImage.lock();
                    rFirstImage.setPixels(newRectangle,arr[0]);
                    rFirstImage.unlock();

                    arr[1].uncompress();
                    if(rFirstImage1) rFirstImage1.dispose();
                    rFirstImage1 = new BitmapData(arr[2],arr[3],true,0);
                    rFirstImage1.lock();
                    rFirstImage1.setPixels(newRectangle,arr[1]);
                    rFirstImage1.unlock();
                    rFirstBGColor = arr[4];
                }
            }
            else
            {
                rFirstImage.dispose();
                rFirstImage1.dispose();
                rFirstImage = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
                rFirstImage1 = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
            }

            if(traceImageFile.exists) //저장한 trace 이미지 복원
            {
                fs.open(traceImageFile, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();
                // arr[0].uncompress();
                newRectangle = new Rectangle(0,0,arr[1],arr[2]);

                var bmpd:BitmapData = new BitmapData(arr[1], arr[2], true, 0);
                bmpd.lock();
                bmpd.setPixels(newRectangle,arr[0]);
                bmpd.unlock();

                if(canvasTraceBitmapData && bmpd !== canvasTraceBitmapData) canvasTraceBitmapData.dispose();
                canvasTraceBitmapData = bmpd.clone();
                canvasTraceBitmap.bitmapData = canvasTraceBitmapData;
                canvasTraceBitmap.smoothing = true;

                bmpd.dispose();
                bmpd = null;
            }

            if(rJumpImageFrameDataFile.exists)
            {
                fs.open(rJumpImageFrameDataFile,FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();
                rJumpImageFrameData = arr.concat();
            }

            if(myPaletteListFile.exists)
            {
                fs.open(myPaletteListFile,FileMode.READ);
                var list:Array = fs.readObject();
                myPalettePreset = list.concat();
                list.length = 0;
                list = null;
            }

            if(undoDataFile.exists)
            {
                loadUndoData();//undo data 복구 먼저 해줘야함
            }

            if(scratchDataFile.exists)
            {
                loadScratchPadImage();
            }

            if(appDataFile.exists)
            {
                fs.open(appDataFile, FileMode.READ);
                var d:Object = fs.readObject();
                fs.close();

                //loadUndoData함수에서 canvaspanel이 호출되는데 이전에 trace이미지 정보값을 넣어두어야함

                //그냥 해주면 창크기 적용이 안되서 타이머 걸어줌
                addTimerByName("loadAppDataDelayTimer",0.15,false,function():void
                {
                    stage.nativeWindow.width = d["stage.nativeWindow.width"];
                    stage.nativeWindow.height = d["stage.nativeWindow.height"];
                    stage.nativeWindow.x = d["stage.nativeWindow.x"];
                    stage.nativeWindow.y = d["stage.nativeWindow.y"];
                    lastWindowSize.x = d["stage.nativeWindow.width"];
                    lastWindowSize.y = d["stage.nativeWindow.height"];

                    //캔버스 위치까지 전부 다해준 다음에 이전 상태가 풀스크린이었으면 세팅해줌
                    if(d["lastWindowState"] === 1) stage.nativeWindow.maximize();
                    setUIScaleButton(d["uiScaleIndex"]);
                    setUIColor(d["uiColorIndex"]);
                    zoomedIndex = d["zoomedIndex"];
                    setZoomCanvas(d["zoomed"]);
                    canvasPanel.x = d["canvasPanel.x"];
                    canvasPanel.y = d["canvasPanel.y"];
                    regPoint.x = d["regPoint.x"];
                    regPoint.y = d["regPoint.y"];
                    regPoint.rotation = d["regPoint.rotation"];
                    setRcursorRotation(d["regPoint.rotation"]);
                    updateResizeButtonPos(CANVAS_WIDTH,CANVAS_HEIGHT);
                    rotateCursorBox["rotateArrow"].rotation = d["regPoint.rotation"];
                    uiColorIndex = d["uiColorIndex"];
                    penSmoothValue = d["penSmoothValue"];
                    penSmoothSlideValue = d["penSmoothSlideValue"];
                    controlBox.penSmoothSliderCursor.x = d["penSmoothButtonX"];
                    penSize = d["penSize"];
                    penColor = d["penColor"];
                    initPickerBoxInfo(d["penColor"]);
                    if(d["rgbInfoColorTypeHSV"]) toggleRGBInfoTextColorType();
                    setHSVCursorPosByColor((rgbInfoColorTypeHSV) ? HEXtoHSV(d["penColor"]) : d["penColor"]);
                    pickerBox.changeHueColor(d["svBaseColor"]);
                    hsvColorArr[0] = d["hsvColorArr[0]"];
                    pickerBox["hueCursor"].x = d["hueCursor.x"];
                    penAlpha = d["penAlpha"];
                    penAlphaIndex = penAlphaList.indexOf(d["eraseAlpha"]);
                    setPenAlpha(d["penAlpha"]);
                    penShape = d["penShape"];
                    penListShapeFlag =  d["penShape"];
                    controlBox.shapeFlag(d["penShape"]);
                    eraseSize = d["eraseSize"];
                    eraseShape = d["eraseShape"];
                    eraseAlpha = d["eraseAlpha"];
                    eraseAlphaIndex = penAlphaList.indexOf(d["eraseAlpha"]);
                    eraseSizeIndex = d["eraseSizeIndex"];
                    setPenSize(d["penSizeIndex"]);
                    saveFilePath = d["saveFilePath"];
                    saveFileName = d["saveFileName"];
                    if(saveFilePath === saveFileName)
                    {
                        saveFilePath = File.desktopDirectory.nativePath + File.separator + saveFileName;
                    }
                    realWorkingTimer.setRunningTime(d["APP_RUNNING_TIME"]);
                    realWorkingTimer.update();
                    traceAlphaSave = d["traceAlphaSave"]
                    canvasTraceLayer.alpha = d["traceAlphaSave"];
                    traceMenu["traceOpaButton"].x = d["traceOpaButtonX"];
                    traceMenu.x = d["traceMenuPos[0]"];
                    traceMenu.y = d["traceMenuPos[1]"];
                    traceReizeMoveSum = d["traceReizeMoveSum"];
                    isRightSidebar = d["isRightSidebar"];
                    isSidebarVisible = d["isSidebarVisible"];
                    if(d["isRightSidebar"]) setSideBarRightPosition(true);
                    if(!d["isSidebarVisible"]) setSidebarVisible(d["isSidebarVisible"],false);
                    makeJumpImageFlag = d["makeJumpImageFlag"];
                    rBGColorSave = d["rBGColorSave"];
                    tickDraw.setFirstRCursorPos(d["getFirstRCursorPos.x"],d["getFirstRCursorPos.y"]);

                    setTraceImageInfo(d["tracePosInfo[0]"],
                                      d["tracePosInfo[1]"],
                                      d["tracePosInfo[2]"],
                                      d["tracePosInfo[3]"],
                                      d["tracePosInfo[4]"],
                                      d["tracePosInfo[5]"]);

                    if(mirrorON !== d["mirrorON"]) mirrorCanvas(true);

                    gridValue = d["gridValue"];
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

                    saveContinue = d["saveContinue"];
                    rIndex = undoIndex;
                    rNowFrame = getNowFrameUntilUndoIndex(undoIndex);
                    rPrevFrame = getNowFrameUntilUndoIndex(undoIndex-1);

                    //혹시 몰라서 위치 체크 해줌
                    appInfoBox.setRotate(regPoint.rotation);
                    setCenvasCenterPos(true);
                    checkCanvasPanelPos();
                    checkCanvasPanelPos(true);
                    myPaletteSaveColorBeforeOtherType[0] = penColor;
                    if(d["myPalettePresetType"] > 0) changeMyPalettePreset(d["myPalettePresetType"]);

                    updateHistoryList();
                    myPaletteViewAllMode = d["myPaletteViewAllMode"];
                    if(myPalettePresetType === 0 && d["myPaletteViewAllMode"])
                    {
                        setMypPaletteListViewAll();
                    }
                    else
                    {
                        updateMyPaletteList();
                    }

                    pickerBoxSwapPositionFlag = d["pickerBoxSwapPositionFlag"];
                    if(d["pickerBoxSwapPositionFlag"])
                    {
                        pickerBox.swapColorBoxPosition(d["pickerBoxSwapPositionFlag"]);
                    }

                    sideBarScrollSet.y = d["scrollSetMovedY"];
                    topBar.captureInput.text = d["topBar.captureInput.text"];
                    capStampON = d["capStampON"];
                    if(d["captureStampFont"])
                    {
                        drawCaptureStamp.changeFont(d["captureStampFont"],false);
                    }

                    updatePreviewBoxRectPos();
                    updatePenSizeCursor();
                    updateWindowTitle();

                    selectSubLayer(false,false);
                });
            }
            else //복원파일이 없을때
            {
                if(saveFilePath === saveFileName)
                {
                    saveFilePath = File.desktopDirectory.nativePath + File.separator + saveFileName;
                }

                initMyPaletteList();

                lastWindowSize.x = 680;
                lastWindowSize.y = 768;
                stage.nativeWindow.width = lastWindowSize.x;
                stage.nativeWindow.height = lastWindowSize.y;

                changeCanvasSize(CANVAS_WIDTH,CANVAS_HEIGHT,0,0,false);
                updateResizeButtonPos(CANVAS_WIDTH,CANVAS_HEIGHT);
                setHSVCursorPosByColor(penColor);
                openAboutPanel(true);
                setUIColor(uiColorIndex);
                updatePreviewBoxRectPos();
                updateWindowSizeInfo();
                appInfoBox.init(CANVAS_WIDTH,CANVAS_HEIGHT,Math.floor(zoomed*100),regPoint.rotation,false);

                selectSubLayer(false,false);
            }
        }

        //size, size drag, zoom, rotate시 업데이트 해줌
        private function cUpdatePenSizeCursor():Function
        {
            var size:Number;
            var shape:Boolean;

            return function():void
            {
                const isPenTool:Boolean = isNowToolPenOrLine();
                if(!isPenTool && !isNowTool(TOOL_ERASE))
                {
                    return;
                }

                if(isPenTool)
                {
                    size = penSize;
                    shape = penShape;
                }
                else
                {
                    size = eraseSize;
                    shape = eraseShape;
                }

                const z:Number = zoomed;
                if(size*z === penLastUpdateInfo[0] && shape === penLastUpdateInfo[1])
                {
                    return;
                }

                penLastUpdateInfo[0] = size*z;
                penLastUpdateInfo[1] = shape;

                penSizeCursor.graphics.clear();

                if(shape === false)
                {
                    penSizeCursor.graphics.lineStyle(1,0xFFFFFF);
                    penSizeCursor.graphics.drawCircle(0,0,(size/2-1/z)*z);

                    penSizeCursor.graphics.lineStyle(1,0);
                    penSizeCursor.graphics.drawCircle(0,0,(size/2)*z);
                    penSizeCursor.rotation = 0;
                }
                else if(shape === true)
                {
                    penSizeCursor.graphics.lineStyle(1,0xFFFFFF);
                    penSizeCursor.graphics.drawRect((-size/2+1/z)*z,(-size/8+1/z)*z,(size-2/z)*z,(size/4-2/z)*z);

                    penSizeCursor.graphics.lineStyle(1,0);
                    penSizeCursor.graphics.drawRect(-size/2*z,-size/8*z,size*z,size*z/4);
                }

                penCursorShape = shape;
                penCursorSize = size;
            };
        }

        //canvas2번데이터를 canvas1에다가 최종적으로그려줌
        private function cDrawDone():Function
        {
            var canvas2Alpha:ColorTransform = new ColorTransform();

            return function():void
            {
                if(readyAddUndoFlag === false)
                {
                    rDataBuffer = [];
                    canvas2Draw.graphics.clear();
                    return;
                }

                if(deepUndoON)
                {
                    var rDataBufferBackup:Array = rDataBuffer.concat();
                    setApplyDeepUndo();
                    rDataBuffer = rDataBufferBackup.concat();
                    rDataBufferBackup.length = 0;
                }

                readyAddUndoFlag = false;

                if(airBrushSizeDrawMode > 0)
                {
                    const blurSize:Number = getBlurSize(airBrushSizeDrawMode,1.0);
                    canvas2Draw.filters = [new BlurFilter(blurSize,blurSize,3)];
                    canvas2BitmapData.draw(canvas2Draw);
                    canvas2Draw.filters = [];
                }
                else
                {
                    canvas2BitmapData.draw(canvas2Draw);
                }

                canvas2Bitmap.bitmapData = canvas2BitmapData;

                updateCanvas2DrawCliprect();
                extandCanvas2DrawCliprect(); // 그린 영역을 100% 다 포함하지 않아서 약간 늘려줌

                if(isNowToolPenOrLine() || isNowTool(TOOL_FILL_PEN))
                {
                    canvas2Alpha.alphaMultiplier = penAlpha;


                    if(subLayerON) canvas11BitmapData.draw(canvas2Bitmap,null,canvas2Alpha,(penColorTransparentFlag) ? "erase":null,canvas2ClipRect);
                    else            canvas1BitmapData.draw(canvas2Bitmap,null,canvas2Alpha,(penColorTransparentFlag) ? "erase":null,canvas2ClipRect);
                }
                else if(isNowTool(TOOL_ERASE))
                {
                    canvas2Alpha.alphaMultiplier = eraseAlpha;

                    if(subLayerON) canvas11BitmapData.draw(canvas2Bitmap,null,canvas2Alpha,"erase",canvas2ClipRect);
                    else           canvas1BitmapData.draw( canvas2Bitmap,null,canvas2Alpha,"erase",canvas2ClipRect);
                }

                rDataBuffer.push(["drawDone5",subLayerON]);

                if(subLayerON) canvas11Bitmap.bitmapData = canvas11BitmapData;
                else canvas1Bitmap.bitmapData = canvas1BitmapData;

                canvas2BitmapData.fillRect(canvas2ClipRect,0); //그려준 영역만
                canvas2Draw.graphics.clear();
                undoData.addNew();
            }
        }

        private function cLineTool():Function
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

            function checkLineLineIntersection(x1:Number, y1:Number, x2:Number, y2:Number, x3:Number, y3:Number, x4:Number, y4:Number):Boolean
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
            function checkLineToolUndoReady():Boolean
            {
                if(canvasPanel.hitTestPoint(mouseX,mouseY,true))
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
                return checkLineLineIntersection(x1,y1,x2,y2,0,0,canvasSizeWidth,0)
                    || checkLineLineIntersection(x1,y1,x2,y2,0,0,0,canvasSizeHeight)
                    || checkLineLineIntersection(x1,y1,x2,y2,0,canvasSizeHeight,canvasSizeWidth,canvasSizeHeight)
                    || checkLineLineIntersection(x1,y1,x2,y2,canvasSizeWidth,0,canvasSizeWidth,canvasSizeHeight)
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

            function setDegreeToolTipON():void
            {
                const ang:Number = Math.atan2(oldX-canvas2Draw.mouseX,oldY-canvas2Draw.mouseY);
                var deg:Number = ang*toDeg+90;
                if(deg > 180)
                {
                    deg = deg-90;
                }

                var degstr:String = Math.abs(deg % 90).toFixed(1)+"°";
                setToolTipString(degstr);
                setToolTipON();
            }

            function drawingLine():void //지우개인가 펜인가 구분해서 lineto 실시
            {
                canvas2Draw.graphics.clear();

                canvas2.alpha = xAlpha;
                if(xShape)
                {
                    canvas2Draw.graphics.lineStyle(xSize, xColor,1,false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.ROUND);
                }
                else
                {
                    canvas2Draw.graphics.lineStyle(xSize, xColor);
                }

                canvas2Draw.graphics.moveTo(startPoint.x,startPoint.y);
                canvas2Draw.graphics.lineTo(endPoint.x,endPoint.y);
            }

            function lineMoveEvent(e:MouseEvent):void
            {
                if(!mouseMovedFlag)
                {
                    mouseMovedFlag = true;
                }
                const mx:Number = canvas2Draw.mouseX;
                const my:Number = canvas2Draw.mouseY;

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

                drawingLine();
                setDegreeToolTipON();
            }

            function lineUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,lineMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP, lineUpEvent);

                penCursorOFFFlag = false;
                if(traceMemoryTrainingON)
                {
                    canvasTraceLayer.visible = true;
                }
                mouseDragON = false;
                setToolTipOFF();

                if(checkLineToolUndoReady() === true)
                {
                    const mx:Number = canvas2Draw.mouseX;
                    const my:Number = canvas2Draw.mouseY;

                    readyAddUndoFlag = true;

                    if(mouseMovedFlag === false && oldX === mx && oldY === my)
                    {
                        rDataBuffer = [];
                        rDataBuffer.push(["dot4",xShape,xSize,xColor,xAlpha,mx,my,xBlendMode,subLayerFlag,xAirBrushON,regPoint.rotation]);
                        dotTool(xShape,xSize,xColor,mx,my,regPoint.rotation);
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
                        drawingLine();
                    }
                }

                resetCanvas2DrawCliprect();
                drawDone();
            }

            return function (lineToolFlag:Boolean):void
            {
                penCursorOFFFlag = true;
                xSize = penSize;
                xAlpha = penAlpha;
                xShape = penShape;
                xAirBrushON = airBrushON;

                if(penColorTransparentFlag)
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
                        updatePickerCurrentColor(pickerBox.getRGBInfoBGColor());
                        addColorMyPaletteHistory(pickerBox.getRGBInfoBGColor());
                    }
                }

                canvasSizeWidth = CANVAS_WIDTH;
                canvasSizeHeight = CANVAS_HEIGHT;

                mouseMovedFlag = false;
                oldX = canvas2Draw.mouseX;
                oldY = canvas2Draw.mouseY;
                subLayerFlag = subLayerON

                if(traceMemoryTrainingON)
                {
                    canvasTraceLayer.visible = false;
                }

                //캔버스2번 지워주고, draw판넬 데이터도 지워줌
                canvas2BitmapData.dispose();
                canvas2Bitmap.bitmapData = null;
                canvas2BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);

                //선 관련 이벤트 함수 붙여줌
                stage.addEventListener(MouseEvent.MOUSE_MOVE, lineMoveEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,lineUpEvent);
            };
        }

        private function resetRotationReplayMode():void
        {
            const center:Point = getStageCenterPos(1);
            setRegPoint(center.x,center.y,true);
            rregPoint.rotation = 0;
            setRcursorRotation(0);
        }

        private function resetRotationDrawMode():void
        {
            const center:Point = getStageCenterPos(0);

            updatePenSizeCursor();
            setRegPoint(center.x,center.y,false);
            regPoint.rotation = 0;
            setRcursorRotation(0);
            appInfoBox.setRotate(0);
            updatePreviewBoxRectPos();
        }

        private function cRotateTool():Function
        {
            var getAngle:Function;
            var isReplayMode:Boolean;
            var xReg:Sprite;

            function rotateToolUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, rotateToolUpEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, rotateToolUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,rotateToolMoveEvent);

                mouseDragON = false;
                penCursorOFFFlag = false;
                getAngle = null;

                if(!isReplayMode)
                {
                    if(lassoToolON)
                    {
                        if(lassoMenuTempOFF === true)
                        {
                            setlassoMenuTempOFF();
                        }
                    }

                    updatePenSizeCursor();
                    setOptimizeCanvasMoveON(false);
                    updatePreviewBoxRectPos();
                }
                else
                {
                    if(rFitZoomedON) fitCanvasToWindowManualReplayMode();

                    resetNowKey();
                    autoScroll.updateRCanvasBounds();
                }

                setRotateCursorOFF();
                checkCanvasPanelPos(isReplayMode);
            }

            function rotateToolMoveEvent(e:MouseEvent):void
            {
                const ang:Number = getAngle(true);

                xReg.rotation = ang;
                setRcursorRotation(xReg.rotation);
                appInfoBox.setRotate(Math.abs(xReg.rotation));
            }

            return function (replayMode:Boolean=false):void
            {
                isReplayMode = replayMode;

                mouseDragON = true;

                if(replayMode)
                {
                    xReg = rregPoint;
                }
                else
                {
                    xReg = regPoint;
                }

                penCursorOFFFlag = true;

                if(!replayMode)
                {
                    setOptimizeCanvasMoveON(true);
                }

                const center:Point = getStageCenterPos(1);
                setRegPoint(center.x,center.y,replayMode);

                //캔버스 이동이 완료된후 함수를 초기화 시켜줌
                getAngle = cGetCanvasRotationAngle(xReg);

                hint.off();

                stage.addEventListener(MouseEvent.MOUSE_MOVE, rotateToolMoveEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,rotateToolUpEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,rotateToolUpEvent);
            };
        }

        private function cMoveTool():Function
        {
            var getMovedPos:Function;

            function moveToolOFFEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,moveToolMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP, moveToolOFFEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, moveToolOFFEvent);

                mouseDragON = false;
                penCursorOFFFlag = false;
                getMovedPos = null;
                var tempBitData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);

                const movex:Number = Math.floor(canvas1Bitmap.x);
                const movey:Number = Math.floor(canvas1Bitmap.y);
                const movex1:Number = Math.floor(canvas11Bitmap.x);
                const movey1:Number = Math.floor(canvas11Bitmap.y);
                var movedMat:Matrix = new Matrix();

                if(deepUndoON) setApplyDeepUndo();
                //최종적으로 움직인 거리를 실제로 비트맵 데이터 조작

                if(checkedLayer === 0)
                {
                    if(canvas1Bitmap.visible)
                    {
                        movedMat.translate(movex,movey);
                        tempBitData.draw(canvas1BitmapData,movedMat);

                        if(canvas1BitmapData && tempBitData !== canvas1BitmapData) canvas1BitmapData.dispose();
                        canvas1BitmapData = tempBitData.clone();
                        canvas1Bitmap.bitmapData = canvas1BitmapData;
                    }

                    if(canvas11Bitmap.visible)
                    {
                        movedMat = new Matrix();
                        movedMat.translate(movex1,movey1);
                        tempBitData.fillRect(new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT),0);
                        tempBitData.draw(canvas11BitmapData,movedMat);

                        if(canvas11BitmapData && tempBitData !== canvas11BitmapData) canvas11BitmapData.dispose();
                        canvas11BitmapData = tempBitData.clone();
                        canvas11Bitmap.bitmapData = canvas11BitmapData;
                    }
                }
                else if(checkedLayer === 1)
                {
                    movedMat.translate(movex,movey);
                    tempBitData.draw(canvas1BitmapData,movedMat);

                    if(canvas1BitmapData && tempBitData !== canvas1BitmapData) canvas1BitmapData.dispose();
                    canvas1BitmapData = tempBitData.clone();
                    canvas1Bitmap.bitmapData = canvas1BitmapData;
                }
                else if(checkedLayer === 2)
                {
                    movedMat = new Matrix();
                    movedMat.translate(movex1,movey1);
                    tempBitData.fillRect(new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT),0);
                    tempBitData.draw(canvas11BitmapData,movedMat);

                    if(canvas11BitmapData && tempBitData !== canvas11BitmapData) canvas11BitmapData.dispose();
                    canvas11BitmapData = tempBitData.clone();
                    canvas11Bitmap.bitmapData = canvas11BitmapData;
                }

                tempBitData.dispose();
                tempBitData = null;
                canvas1Bitmap.x = 0;
                canvas1Bitmap.y = 0;
                canvas11Bitmap.x = 0;
                canvas11Bitmap.y = 0;

                if(lassoToolON === false)
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
                        if(!canvas11Bitmap.visible)
                        {
                            command = "move1";
                            rDataBuffer.push([command,movex,movey]);
                        }
                        else if(!canvas1Bitmap.visible)
                        {
                            command = "move2";
                            rDataBuffer.push([command,movex1,movey1]);
                        }
                        else
                        {
                            rDataBuffer.push([command,movex,movey]);
                        }
                    }

                    if(hasLastRDataCommand(command)) undoData.addContinue();
                    else undoData.addNew();
                }
            }

            function moveToolMoveEvent(e:MouseEvent):void
            {
                const pos:Point = getMovedPos();

                if(checkedLayer === 0)
                {
                    if(canvas1Bitmap.visible)
                    {
                        canvas1Bitmap.x = pos.x;
                        canvas1Bitmap.y = pos.y;
                    }

                    if(canvas11Bitmap.visible)
                    {
                        canvas11Bitmap.x = pos.x;
                        canvas11Bitmap.y = pos.y;
                    }
                }
                else if(checkedLayer === 1)
                {
                    canvas1Bitmap.x = pos.x;
                    canvas1Bitmap.y = pos.y;
                }
                else if(checkedLayer === 2)
                {
                    canvas11Bitmap.x = pos.x;
                    canvas11Bitmap.y = pos.y;
                }
            }

            return function ():void
            {
                if(isAllLayerInvisible()) return;

                getMovedPos = cImageMoveFunc(canvas1Bitmap,regPoint.rotation);

                penCursorOFFFlag = true;

                stage.addEventListener(MouseEvent.MOUSE_MOVE, moveToolMoveEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,moveToolOFFEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,moveToolOFFEvent);
            };
        }

        private function getCanvasBoundLimitPoint(canvas:Sprite,px:Number,py:Number,width:Number,height:Number,zoom:Number,rotation:Number):Point
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

        private function cZoomTool():Function
        {
            const zoomMin:Number = zoomList[0];
            const zoomMax:Number = zoomList[zoomList.length-1];
            const mouseMoveStep:int = 37; //이 픽셀이상움직일때만 zoomcanvas를 실행
            const clickPos:Point = new Point(0,0);

            var xZoomed:Number;
            var zoomSum:Number;
            var moveXFlag:Boolean;//가로,세로 구분하는 플래그
            var zoomGoFlag:Boolean;//일정 범위를 넘기면 시작하는 플래그
            var oldX:Number;
            var oldY:Number;
            var moveFlag:uint = 0; //1이면 x축
            var oldZoom:Number;
            //클릭한 위치가 캔버스밖을 벗어날경우 줌 기준점을 캔버스 경계선에 닿도록 함
            var xCanvas:Sprite;
            var xRotation:Number
            var maxWidth:Number;//줌 배율을 곱해줘야 정확한 값이 나옴. width나 canvasPanel.mouseX는 scale된 값이 아님
            var maxHeight:Number;
            // var gp:Point;

            function zoomToolMouseUpEvent(clickZoomInFlag:Boolean):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, zoomToolMouseUpEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, zoomToolMouseUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,zoomToolMouseMoveEvent);

                zoomToolHintON = false;
                mouseDragON = false;
                penCursorOFFFlag = false;
                setToolTipOFF();

                updatePenSizeCursor();


                setOptimizeCanvasMoveON(false);

                if(lassoMenuTempOFF === true)
                {
                    setlassoMenuTempOFF();
                }

                updatePreviewBoxRectPos();

                if(gridValue > 0 && oldZoom !== zoomed)
                {
                    drawGrid();
                }
            }

            function setFixedToolTipPos():void
            {
                toolTipBox.x = clickPos.x-toolTipBox.width/2;
                toolTipBox.y = clickPos.y-35*getUIScale();
            }

            function zoomGoArray(index:uint):void
            {
                const newZoom:Number = zoomList[index];

                setZoomCanvas(newZoom,false);

                setToolTipString(Math.floor(newZoom*100)+"%");
                setFixedToolTipPos();
            }

            function zoomToolMouseMoveEvent2(dist:Number):void
            {
                if(dist > mouseMoveStep)
                {
                    zoomedIndex--;
                }
                else
                {
                    zoomedIndex++;
                }

                if(zoomedIndex < 0) zoomedIndex = 0;
                else if(zoomedIndex > zoomList.length-1) zoomedIndex = zoomList.length-1;

                zoomGoArray(zoomedIndex);
            }

            function zoomToolMouseMoveEvent(e:MouseEvent):void
            {
                var abs:Function = Math.abs;
                var mx:Number = mouseX;
                var my:Number = mouseY;

                if(moveFlag === 0)
                {
                    if(abs(mx-oldX) > 20)
                    {
                        moveFlag = 1;
                        oldX = mouseX;
                    }
                    else if(abs(my-oldY) > 20)
                    {
                        moveFlag = 2;
                        oldY = mouseY;
                    }
                }
                else if(moveFlag === 1)
                {
                    const subX:Number = oldX-mx;
                    if(abs(subX) > mouseMoveStep)
                    {
                        oldX = mouseX;
                        zoomToolMouseMoveEvent2(subX);
                    }
                }
                else if(moveFlag === 2)
                {
                    const subY:Number = my-oldY;

                    if(abs(subY) > mouseMoveStep)
                    {
                        oldY = mouseY;
                        zoomToolMouseMoveEvent2(subY);
                    }
                }
            }

            return function():void
            {
                //왼쪽 오른쪽 클릭 두번있기 때문에 중복 툴 사용은 피해줌
                if(zoomToolHintON === true) return;

                xZoomed = zoomed
                zoomSum = 0;
                moveXFlag = true;//가로,세로 구분하는 플래그
                zoomGoFlag = false;//일정 범위를 넘기면 시작하는 플래그
                oldX = mouseX;
                oldY = mouseY;
                moveFlag = 0; //1이면 x축
                penCursorOFFFlag = true;
                zoomToolHintON = true;
                setOptimizeCanvasMoveON(true);
                oldZoom = zoomed;
                mouseDragON = true;

                //클릭한 위치가 캔버스밖을 벗어날경우 줌 기준점을 캔버스 경계선에 닿도록 함
                xCanvas = canvasPanel;
                xRotation= -regPoint.rotation;
                maxWidth = CANVAS_WIDTH*xZoomed;//줌 배율을 곱해줘야 정확한 값이 나옴. width나 canvasPanel.mouseX는 scale된 값이 아님
                maxHeight = CANVAS_HEIGHT*xZoomed;

                var gp:Point;

                //regpoint를 panelLimitedPos계산한 값으로 이동
                if(lassoMenuTempOFF === true)
                {
                    gp = lassoBox1.localToGlobal(ZERO_POINT);
                    setRegPoint(gp.x,gp.y,false);
                }
                else
                {
                    gp = xCanvas.localToGlobal(ZERO_POINT);
                    const panelLimitedPos:Point = getCanvasBoundLimitPoint(xCanvas,xCanvas.mouseX,xCanvas.mouseY,CANVAS_WIDTH,CANVAS_HEIGHT,xZoomed,xRotation);

                    //캔버스 0,0점이 글로벌좌표 기준으로 어느 위치에 있는지 더해줘야함
                    setRegPoint(panelLimitedPos.x+gp.x,panelLimitedPos.y+gp.y,false);
                }

                clickPos.setTo(mouseX,mouseY);
                setToolTipString(Math.floor(oldZoom*100)+"%");
                setFixedToolTipPos();
                toolTipBox.visible =  true;

                stage.addEventListener(MouseEvent.MOUSE_MOVE, zoomToolMouseMoveEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,zoomToolMouseUpEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,zoomToolMouseUpEvent);
            };
        }

        //비트맵 데이터를 대칭으로 돌려줌
        private function mirrorDraw():void
        {
            var tempBitData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
            var flipMat:Matrix = new Matrix(-1,0,0,1,CANVAS_WIDTH);

            tempBitData.draw(canvas1BitmapData,flipMat);

            if(canvas1BitmapData && tempBitData !== canvas1BitmapData) canvas1BitmapData.dispose();
            canvas1BitmapData = tempBitData.clone();
            canvas1Bitmap.bitmapData = canvas1BitmapData;

            tempBitData.fillRect(new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT),0);
            tempBitData.draw(canvas11BitmapData,flipMat);

            if(canvas11BitmapData && tempBitData !== canvas11BitmapData) canvas11BitmapData.dispose();
            canvas11BitmapData = tempBitData.clone();
            canvas11Bitmap.bitmapData = canvas11BitmapData;

            tempBitData.dispose();
            tempBitData = null;

            previewBox.updateImage(canvas1BitmapData,canvas11BitmapData,CANVAS_BG_COLOR);

            if(canvasWindowON)
            {
                updateCanvasWindowImage();
            }
        }

        //캔버스의 중심좌표를 구함 컨트롤 박스 옵션 박스 포함
        private function getCanvasPanelMidPos():Point
        {
            const boundRect:Object = getBoundRect(canvas1Bitmap);
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

        private function syncMirrorFinishReplayMode():void
        {
            if(mirrorCommandReady) mirrorCanvasReplayMode();
        }

        private function checkGridMirror(mirrorON:Boolean):void
        {
            if(mirrorON)
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

        private function mirrorTraceLayerImage():void
        {
            canvasTraceLayer.scaleX = -canvasTraceLayer.scaleX;
            canvasTraceLayer.rotation = -canvasTraceLayer.rotation;
            tracePosInfo[2] = canvasTraceLayer.rotation;
            tracePosInfo[3] = canvasTraceLayer.scaleX;
            tracePosInfo[5] = !tracePosInfo[5];
        }

        private function mirrorCanvas(canvasOnly:Boolean=false):void
        {
            //canvaspanel로 하면 중점이 안맞아서 canvas1로함
            const p:Point = getCanvasPanelMidPos();

            mirrorON = !mirrorON;
            mirrorCommandReady = !mirrorCommandReady;
            mirrorDraw();
            appInfoBox.setMirror(mirrorON);

            //회전각 부호를 바꿔야 제대로 mirror가됨
            setRegPoint(p.x,p.y);//regpoint를 회전한 캔버스 중점으로 두고
            if(canvasOnly === false) //보통 미러할때, canvasonly가 true일때는 appdata에서 바꿔줄때 밖에 없음
            {
                regPoint.rotation = -regPoint.rotation;//반대각으로 세팅
                setRcursorRotation(regPoint.rotation)
                mirrorTraceLayerImage();
            }

            checkGridMirror(mirrorON);

            const halfCanvas:Number = (stage.stageWidth-sideBar.getWidth())/2;
            var stageHalf:Number = (sideBar.visible === false) ? stage.stageWidth/2
                                            : (isRightSidebar) ? halfCanvas
                                            :                    STAGE_LEFT_OFFSET+halfCanvas;

            //창 절반을 기준점으로 regpoint x축 이동.
            regPoint.x += Math.round((stageHalf-p.x)*2);
            updatePreviewBoxRectPos();
            saveOneTime = false; //미러도 화면이 바뀌기 때문에 세이브 플래그 꺼줌

            setRCursorMirrorPos();
        }

        private function changeCanvasSizeReplayMode(w:Number,h:Number,moveX:Number=0,moveY:Number=0,movedFlag:Boolean=false):void
        {
            if(w === RCANVAS_WIDTH && h === RCANVAS_HEIGHT)
            {
                return;
            }

            const bgColor:uint = RCANVAS_BG_COLOR;

            //캔버스가 회전되어있으면 회전된 방향으로 움직여줘야함
            rcanvasPanel.graphics.clear();
            rcanvasPanel.graphics.beginFill(bgColor);
            rcanvasPanel.graphics.drawRect(0,0,w,h);
            rcanvasPanel.graphics.endFill();

            rcanvasPanel.scrollRect = new Rectangle(0,0,w,h);//마스크 다시 씌워줌

            rcanvas1BitmapData = new BitmapData(w,h,true,0);
            rcanvas11BitmapData = new BitmapData(w,h,true,0);
            rcanvas2BitmapData = new BitmapData(w,h,true,0);
            RCANVAS_WIDTH = w;
            RCANVAS_HEIGHT = h;

            if(movedFlag)
            {
                //movex y는 캔버스 사이즈 조절에서 원점이 움직였을경우 그만큼 bitmapdata를 움직여줘야 원래 이미지대로 나옴
                var mat:Matrix = new Matrix();
                mat.translate(moveX,moveY);

                rcanvas1BitmapData.draw(rcanvas1Bitmap,mat);
                rcanvas11BitmapData.draw(rcanvas11Bitmap,mat);
            }
            else
            {
                rcanvas1BitmapData.draw(rcanvas1Bitmap);
                rcanvas11BitmapData.draw(rcanvas11Bitmap);
            }

            if(rcanvas1Bitmap.bitmapData) rcanvas1Bitmap.bitmapData.dispose();
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;

            if(rcanvas11Bitmap.bitmapData) rcanvas11Bitmap.bitmapData.dispose();
            rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;
            autoScroll.updateRCanvasBounds();
            checkCanvasPanelPos(true);

            if(rFitZoomedON) fitCanvasToWindowManualReplayMode();
        }

        private function updateCanvasTracePos(w:Number,h:Number,movedFlag:Boolean):void
        {
            const scX:Number = tracePosInfo[3];
            const scY:Number = tracePosInfo[4];
            const subW:Number = (CANVAS_WIDTH-w)/2;
            const subH:Number = (CANVAS_HEIGHT-h)/2;
            const rPos:Point = rotatePoint(subW,subH,canvasTraceLayer.rotation);

            canvasTraceLayer.x = w/2;
            canvasTraceLayer.y = h/2;

            if(movedFlag)
            {
                canvasTraceBitmap.x += -rPos.x/scX;
                canvasTraceBitmap.y += -rPos.y/scY;
            }
            else
            {
                canvasTraceBitmap.x += rPos.x/scX;
                canvasTraceBitmap.y += rPos.y/scY;
            }

            tracePosInfo[0] = canvasTraceBitmap.x;
            tracePosInfo[1] = canvasTraceBitmap.y;
        }

        private function changeCanvasSize(w:Number,h:Number,moveX:Number=0,moveY:Number=0,centerMovedFlag:Boolean=false):void
        {
            const maxSize:uint = CANVAS_MAX_SIZE;

            if(w > maxSize)  w = maxSize;
            else if(w < 1) w = 1;

            if(h > maxSize) h = maxSize;
            else if(h < 1) h = 1;

            _setBackgroundColor(canvasPanel,w,h,CANVAS_BG_COLOR);
            updateCanvasPanelMask(w,h);

            canvas1BitmapData = new BitmapData(w,h,true,0);
            canvas11BitmapData = new BitmapData(w,h,true,0);
            canvas2BitmapData = new BitmapData(w,h,true,0);

            if(centerMovedFlag)
            {
                //movex y는 캔버스 사이즈 조절에서 원점이 움직였을경우 그만큼 bitmapdata를 움직여줘야
                //원래 이미지대로 나옴
                var mat:Matrix = new Matrix();
                const rp:Point = rotatePoint(moveX,moveY,-regPoint.rotation);  //캔버스가 회전되어있으면 회전된 방향으로 움직여줘야함

                mat.translate(moveX,moveY);

                canvas1BitmapData.draw(canvas1Bitmap,mat);
                canvas11BitmapData.draw(canvas11Bitmap,mat);

                regPoint.x -= Math.round(rp.x*zoomed);
                regPoint.y -= Math.round(rp.y*zoomed);
            }
            else
            {
                canvas1BitmapData.draw(canvas1Bitmap);
                canvas11BitmapData.draw(canvas11Bitmap);
            }

            if(canvas1Bitmap.bitmapData) canvas1Bitmap.bitmapData.dispose();
            canvas1Bitmap.bitmapData = canvas1BitmapData;

            if(canvas11Bitmap.bitmapData) canvas11Bitmap.bitmapData.dispose();
            canvas11Bitmap.bitmapData = canvas11BitmapData;

            updateCanvasTracePos(w,h,centerMovedFlag); //canvas width가 갱신되게 전에 체크해야함

            CANVAS_WIDTH = w;
            CANVAS_HEIGHT = h;
            checkCanvasPanelPos();
            if(gridValue > 0) drawGrid();
            appInfoBox.setSize(w,h);
        }

        private function cResizeCanvas():Object
        {
            var resizeInitON:Boolean = false;
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

            function checkRatioSnapGuidePos():void
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

                    const color:uint = uiColorSet[uiColorIndex][1];
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

                        resizePreviewRatioRect.graphics.lineStyle(3/zoomed,color,1.0,true,"normal","none");

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
                if(resizeInitON)
                {
                    resizeInitON = false;
                    if(targetName !== null)
                    {
                        stage.removeEventListener(MouseEvent.MOUSE_UP,resizeButtonMouseUpEvent);
                        if(!rightMouseClickON)
                        {
                            rightMouseupEventON = false;
                            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,resizeButtonRightMouseUpEvent);
                        }

                        if(targetName === "resizeButtonL") stage.removeEventListener(MouseEvent.MOUSE_MOVE,resizeMouseMoveL);
                        else if(targetName === "resizeButtonR") stage.removeEventListener(MouseEvent.MOUSE_MOVE,resizeMouseMoveR);
                        else if(targetName === "resizeButtonU") stage.removeEventListener(MouseEvent.MOUSE_MOVE,resizeMouseMoveU);
                        else if(targetName === "resizeButtonD") stage.removeEventListener(MouseEvent.MOUSE_MOVE,resizeMouseMoveD);
                    }

                    canvasSizeChanging = false;
                    setToolTipOFF();
                    setResizeButtonVisible((isMouseCursorInStage() && rightMouseClickON) || isPressingControl());
                    regPoint.removeChild(resizePreviewRect);
                    regPoint.removeChild(resizePreviewRatioRect);
                    resizePreviewRect.graphics.clear();
                    resizePreviewRatioRect.graphics.clear();

                    if(subX !== 0 || subY !== 0)
                    {
                        const centerMovedFlag:Boolean = (targetName === "resizeButtonL" || targetName === "resizeButtonU") ? true:false;

                        if(deepUndoON)
                        {
                            setApplyDeepUndo();
                        }

                        changeCanvasSize(finalWidth,finalHeight,subX,subY,centerMovedFlag);
                        updateResizeButtonPos(finalWidth,finalHeight);
                        rDataBuffer.push(["canvasSize",finalWidth,finalHeight,subX,subY,centerMovedFlag]);

                        if(hasLastRDataCommand("canvasSize"))
                        {
                            undoData.addContinue();
                        }
                        else
                        {
                            undoData.addNew();

                            if(canvasWindowON)
                            {
                                updateCanvasWindowBitmapSize();
                            }
                        }
                    }

                    targetName = null;
                }
                else
                {
                    setResizeButtonVisible(false);
                    rightMouseupEventON = false;
                    stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,resizeButtonRightMouseUpEvent);
                }
            }

            function isMouseCursorInStage():Boolean
            {
                return mouseX >= 0 && mouseY >= 0 && mouseX <= stage.stageWidth && mouseY <= stage.stageHeight;
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

                if(size > 0) resizePreviewRect.graphics.beginFill(bgColor);
                else resizePreviewRect.graphics.beginFill(stageColor);

                resizePreviewRect.graphics.drawRect(x,y,w,h);

                checkRatioSnapGuidePos();
            }

            function checkHeightLimit(subY:Number):Number
            {
                var height:Number = (oldHeight+subY < min) ? min:
                                    (oldHeight+subY > max) ? max:
                                    Math.floor(oldHeight+subY);

                return height;
            }

            function changeHeight(flipFlag:Boolean):Number
            {
                subY = (flipFlag) ? resizeClickPos.y-canvasPanel.mouseY
                                  : canvasPanel.mouseY-resizeClickPos.y;

                var height:Number = (oldHeight+subY < min) ? min:
                                    (oldHeight+subY > max) ? max:
                                                             Math.floor(oldHeight+subY);
                if(height === max) subY = max-oldHeight;
                else if(height === min) subY = min-oldHeight;

                if(resizePreviewRatioRect.hitTestPoint(mouseX,mouseY,true))
                {
                    const snap:Array = checkRatioSnap(height);
                    if(snap)
                    {
                        subY = snap[0]-oldHeight;
                        finalHeight = snap[0];
                        setToolTipString(oldWidth+" x "+finalHeight+" ("+snap[1]+")");

                        return subY;
                    }
                }

                finalHeight = height;
                setToolTipString(oldWidth+" x "+finalHeight);

                return subY;
            }

            function checkWidthLimit(subX:Number):Number
            {
                var width:Number = (oldWidth+subX < min) ? min:
                                   (oldWidth+subX > max) ? max:
                                    Math.floor(oldWidth+subX);
                return width;
            }

            function changeWidth(flipFlag:Boolean):Number
            {
                subX = (flipFlag) ? resizeClickPos.x-canvasPanel.mouseX
                                  : canvasPanel.mouseX-resizeClickPos.x;

                var width:Number = (oldWidth+subX < min) ? min:
                                   (oldWidth+subX > max) ? max:
                                                    Math.floor(oldWidth+subX);

                if(width === max) subX =max-oldWidth;
                else if(width === min) subX = min-oldWidth;

                if(resizePreviewRatioRect.hitTestPoint(mouseX,mouseY,true))
                {
                    const snap:Array = checkRatioSnap(width);
                    if(snap)
                    {
                        subX = snap[0]-oldWidth;
                        finalWidth = snap[0];
                        setToolTipString(finalWidth+" x "+oldHeight+" ("+snap[1]+")");

                        return subX;
                    }
                }

                finalWidth = width;
                setToolTipString(finalWidth+" x "+oldHeight);

                return subX;
            }

            function resizeMouseMoveD(e:MouseEvent):void
            {
                var subY:Number = changeHeight(false);
                drawResizePreviewRect(subY,0,oldHeight,oldWidth,subY);
            }

            function resizeMouseMoveU(e:MouseEvent):void
            {
                var subY:Number = changeHeight(true);
                drawResizePreviewRect(subY,0,-subY,oldWidth,subY);
            }

            function resizeMouseMoveR(e:MouseEvent):void
            {
                var subX:Number = changeWidth(false);
                drawResizePreviewRect(subX,oldWidth,0,subX,oldHeight);
            }

            function resizeMouseMoveL(e:MouseEvent):void
            {
                var subX:Number = changeWidth(true);
                drawResizePreviewRect(subX,-subX,0,subX,oldHeight);
            }

            function getInitON():Boolean
            {
                return resizeInitON;
            }

            function initResizeVars():void
            {
                if(resizeInitON === false)
                {
                    resizeInitON = true;
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
                    guideLineWidth = 30/zoomed;
                    regPoint.addChild(resizePreviewRect);
                    regPoint.addChild(resizePreviewRatioRect);
                    setTopChildIndex(resizePreviewRect);
                    setTopChildIndex(resizePreviewRatioRect);
                }
            }

            function startResizeCanvas(_targetName:String):void
            {
                initResizeVars();
                targetName = _targetName;
                resizeClickPos.setTo(canvasPanel.mouseX,canvasPanel.mouseY);
                canvasSizeChanging = true;

                drawRatioSnapGuide(oldWidth,oldHeight,targetName);
                checkRatioSnapGuidePos();

                if(toolBox2ON) closeToolBox2();
                setResizeButtonVisible(false);

                stage.addEventListener(MouseEvent.MOUSE_UP,resizeButtonMouseUpEvent);
                if(rightMouseupEventON === false)
                {
                    rightMouseupEventON = true;
                    stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,resizeButtonRightMouseUpEvent);
                }

                if(targetName === "resizeButtonL") stage.addEventListener(MouseEvent.MOUSE_MOVE, resizeMouseMoveL);
                else if(targetName === "resizeButtonR") stage.addEventListener(MouseEvent.MOUSE_MOVE, resizeMouseMoveR);
                else if(targetName === "resizeButtonU") stage.addEventListener(MouseEvent.MOUSE_MOVE, resizeMouseMoveU);
                else if(targetName === "resizeButtonD") stage.addEventListener(MouseEvent.MOUSE_MOVE, resizeMouseMoveD);
            }

            return {
                start:startResizeCanvas,
                exit:exitResizeCanvas,
                isCanvasResizing:isCanvasResizing,
                getInitON:getInitON
            }
        }

        private function moveSelectedAreaToLassoBox(replayMode:Boolean,rectArr:Vector.<Number>,points:Array,copyFlag:Boolean,layer1:Boolean,layer2:Boolean):Boolean
        {
            //라소 경계 사각형 좌표와 크기
            const rectLeft:Number = rectArr[0];
            const rectTop:Number = rectArr[1];
            const rectWidth:Number = rectArr[2] - rectLeft;
            const rectHeight:Number = rectArr[3] - rectTop;
            const lassoPointsLen:uint = points.length;

            //가로세로 길이가 0 이하이면 실행하지 않음
            if(Math.floor(rectWidth) <= 0 || Math.floor(rectHeight) <= 0) return false;

            var xCanvas2Draw:Shape;
            var canvasBitmapData:BitmapData;
            var canvasBitmapDataSub:BitmapData;
            var canvasBitmap:Bitmap;
            var canvasBitmapSub:Bitmap;
            var canvas2FilterBackUp:Array = null //에어브러시 켜줄때 필터 백업함

            if(replayMode)
            {
                canvas2FilterBackUp = rcanvas2Draw.filters.concat();
                rcanvas2Draw.filters = [];
                xCanvas2Draw = rcanvas2Draw;

                if(layer1)
                {
                    canvasBitmapData = rcanvas1BitmapData;
                    canvasBitmap = rcanvas1Bitmap;
                }

                if(layer2)
                {
                    canvasBitmapDataSub = rcanvas11BitmapData;
                    canvasBitmapSub = rcanvas11Bitmap;
                }
            }
            else
            {
                canvas2FilterBackUp = canvas2Draw.filters.concat();
                canvas2Draw.filters = [];
                xCanvas2Draw = canvas2Draw;

                if(layer1)
                {
                    canvasBitmapData = canvas1BitmapData;
                    canvasBitmap = canvas1Bitmap;
                }

                if(layer2)
                {
                    canvasBitmapDataSub = canvas11BitmapData;
                    canvasBitmapSub = canvas11Bitmap;
                }
            }

            const newRectangle:Rectangle = new Rectangle(rectLeft,rectTop,rectWidth,rectHeight);

            var lassoBMPD:BitmapData = new BitmapData(rectWidth,rectHeight,true,0);
            var lassoBMPDsub:BitmapData = new BitmapData(rectWidth,rectHeight,true,0);
            var i:uint;

            //지우기 전에 사각형 모양으로 그려준 부분을 copypixel 함.
            if(layer1) lassoBMPD.copyPixels(canvasBitmapData,newRectangle,ZERO_POINT,null,null,true);
            if(layer2) lassoBMPDsub.copyPixels(canvasBitmapDataSub,newRectangle,ZERO_POINT,null,null,true);

            lassoBMP.smoothing = true;
            lassoBMPsub.smoothing = true;

            //bitmap1canvas에서 그려준 영역을 지워줌
            if(!copyFlag)
            {
                xCanvas2Draw.graphics.clear();
                xCanvas2Draw.graphics.beginFill(CANVAS_BG_COLOR);
                xCanvas2Draw.graphics.moveTo(points[0][0],points[0][1]);

                //rectLeft를 빼줘서 canvasdraw2의 0,0영역에 그려줌
                for(i=1;i<lassoPointsLen;i++)
                {
                    xCanvas2Draw.graphics.lineTo(points[i][0],points[i][1]);
                }

                xCanvas2Draw.graphics.endFill();

                if(layer1)
                {
                    canvasBitmapData.draw(xCanvas2Draw,null,null,"erase");
                    canvasBitmap.bitmapData = canvasBitmapData;
                }

                if(layer2)
                {
                    canvasBitmapDataSub.draw(xCanvas2Draw,null,null,"erase");
                    canvasBitmapSub.bitmapData = canvasBitmapDataSub;
                }
            }

            //-------------------------
            //clip하기 위해서 그려운 영역의 반전 부분을 0,0영역을 기준으로 그려줌
            //2번 반복하는게 좀 그런데 다른 방법 모르겠음
            //가로세로 절반 크기만큼 더해줘서 bmp의 중점으로 이동해주기 때문에 또 그만큼 빼줌
            xCanvas2Draw.graphics.clear();
            xCanvas2Draw.graphics.beginFill(0x00FF00);
            xCanvas2Draw.graphics.drawRect(0,0,rectWidth,rectHeight);
            xCanvas2Draw.graphics.moveTo(points[0][0]-rectLeft,points[0][1]-rectTop);

            //rectLeft를 빼줘서 canvasdraw2의 0,0영역에 그려줌
            for(i=1;i<lassoPointsLen;i++)
            {
                xCanvas2Draw.graphics.lineTo(points[i][0]-rectLeft,points[i][1]-rectTop);
            }

            //마지막으로 시작점을 이어줌
            xCanvas2Draw.graphics.endFill();
            if(layer1)
            {
                lassoBMP.bitmapData = lassoBMPD;
                lassoBMP.bitmapData.draw(xCanvas2Draw,null,null,"erase");
            }

            if(layer2)
            {
                lassoBMPsub.bitmapData = lassoBMPDsub;
                lassoBMPsub.bitmapData.draw(xCanvas2Draw,null,null,"erase");
            }
            xCanvas2Draw.graphics.clear(); //꼭 해줘야함

            //회전 확대를 bmp사각형의 중심으로 맞추어줌

            if(layer1)
            {
                lassoBMP.x = -rectWidth/2;
                lassoBMP.y = -rectHeight/2;
            }

            if(layer2)
            {
                lassoBMPsub.x = -rectWidth/2;
                lassoBMPsub.y = -rectHeight/2;
            }

            lassoBox1.x = rectLeft+rectWidth/2;
            lassoBox1.y = rectTop+rectHeight/2;
            lassoBox2.x = lassoBox1.x;
            lassoBox2.y = lassoBox1.y;
            lassoDraw.x = -lassoBox1.x;
            lassoDraw.y = -lassoBox1.y;

            if(replayMode)
            {
                rcanvas2Draw.filters = canvas2FilterBackUp.concat();
            }
            else
            {
                canvas2Draw.filters = canvas2FilterBackUp.concat();
            }

            return true;
        }

        private function cLassoTool():Object
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
                if(lassoPoints === null) return;

                lassoDraw.graphics.clear();

                const len:uint = lassoPoints.length;
                if(lassoPoints.length < 2) return;

                dottedLine.ready(lassoDraw.graphics,lassoPoints[0][0],lassoPoints[0][1]);

                for(var i:uint=0; i<len; i++)
                {
                    dottedLine.draw(lassoDraw.graphics,lassoPoints[i][0],lassoPoints[i][1]);
                }
                dottedLine.draw(lassoDraw.graphics,lassoPoints[0][0],lassoPoints[0][1]);
            }

            function setDeafultLassoMenuPos(lassoMenu:lassoButtons):void
            {
                const g:Point = lassoBox1.localToGlobal(ZERO_POINT);
                const lassoW:Number = (lassoMenu.width > stage.stageWidth)
                                      ? stage.stageWidth : lassoMenu.width;

                lassoMenu.x = Math.floor(g.x-lassoW/2);
                lassoMenu.y = Math.floor(g.y+(((lassoBox1.height)/2)*zoomed+20));
                // lassoMenu.y = floor(g.y+(((lassoBox1.height)/2)/zoomed+15));
            }

            function lassoDrawMouseUp():void
            {
                mouseDragON = false;
                removeTimer("LassoDrawDelayTimer");
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,lassoDrawMouseMove);
                stage.removeEventListener(MouseEvent.MOUSE_UP,lassoDrawMouseUp);

                if(Math.abs(lassoRect[0]-lassoRect[2]) < 5 || Math.abs(lassoRect[1]-lassoRect[3]) < 5)
                {
                    resetLassoBox();
                    return;
                }

                if(lassoRect[0] < 0) lassoRect[0] = 0;
                if(lassoRect[1] < 0) lassoRect[1] = 0;
                if(lassoRect[2] > CANVAS_WIDTH) lassoRect[2] = CANVAS_WIDTH;
                if(lassoRect[3] > CANVAS_HEIGHT) lassoRect[3] = CANVAS_HEIGHT;

                lassoPointSave.push(lassoRect);
                lassoPointSave.push(lassoPoints);

                var checklayer1:Boolean = canvas1Bitmap.visible;
                var checklayer2:Boolean = canvas11Bitmap.visible;

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

                if(moveSelectedAreaToLassoBox(false,lassoRect,lassoPoints,lassoCopyON,checklayer1,checklayer2) === false)
                {
                    resetLassoBox();
                }
                else
                {
                    drawPreviewLine();
                    //라소 메뉴 마우스 커서에보이기
                    lassoStartData = [lassoBox1.x,lassoBox1.y,lassoBox1.scaleX,lassoBox1.scaleY,lassoBox1.rotation];
                    lassoToolON = true;
                    setDeafultLassoMenuPos(lassoMenu);
                    checkLassoMenuPos();

                    if(checkedLayer || !checklayer1 || !checklayer2)
                    {
                        lassoMenu.lassoLayerSwap.alpha = BUTTON_OFF_ALPHA;
                        lassoMenu.lassoLayerMerge.alpha = BUTTON_OFF_ALPHA;
                    }
                    else
                    {
                        lassoMenu.lassoLayerSwap.alpha = 1.0;
                        lassoMenu.lassoLayerMerge.alpha = 1.0;
                    }

                    lassoBox2.visible = true;
                    lassoMenu.visible = true;
                    setTopChildIndex(lassoMenu);

                    if(traceMenuON === true) traceMenu.visible = false;

                    addMouseKeyEventLassoTool();
                }
            }

            function lassoDrawMouseMove(MouseEvent:Event):void
            {
                var mx:Number = canvas2Draw.mouseX;
                var my:Number = canvas2Draw.mouseY;

                lassoPoints.push([mx,my]);

                if(!hasTimer("LassoDrawDelayTimer"))
                {
                    addTimerByName("LassoDrawDelayTimer",0.083,false,function():void
                    {
                        drawPreviewLine();
                    });
                }

                //사각형 꼭지점 체크
                if(mx < lassoRect[0]) lassoRect[0] = mx;
                else if(mx > lassoRect[2]) lassoRect[2] = mx;

                if(my < lassoRect[1]) lassoRect[1] = my;
                else if(my > lassoRect[3]) lassoRect[3] = my;
            }

            function start ():void
            {
                if(lassoToolON === true || isAllLayerInvisible()) return;

                mouseDragON = true;

                lassoMenu.hint("Lasso tool");
                maxWidth = CANVAS_WIDTH;
                maxHeight = CANVAS_HEIGHT;

                clickPos.setTo(canvas2Draw.mouseX,canvas2Draw.mouseY);

                lassoDraw.x = 0;
                lassoDraw.y = 0;

                //left, top, right, bottom순임
                lassoRect = new <Number> [clickPos.x,clickPos.y,clickPos.x,clickPos.y];
                lassoPoints = [];
                lassoPointSave = [];

                canvas2.alpha = 1.0; //알파값이 조정되어 있을 수도 있기 때문에 해줌

                lassoDraw.graphics.clear();
                lassoPoints.push([clickPos.x,clickPos.y]);
                lassoBox1.visible = true;

                dottedLine.updateScale(zoomed);
                if(canvas1Bitmap.visible)
                {
                    if(lassoBitmapdataSave && canvas1BitmapData !== lassoBitmapdataSave) lassoBitmapdataSave.dispose();
                    lassoBitmapdataSave = canvas1BitmapData.clone();
                }
                if(canvas11Bitmap.visible)
                {
                    if(lassoBitmapdataSubSave && canvas11BitmapData !== lassoBitmapdataSubSave) lassoBitmapdataSubSave.dispose();
                    lassoBitmapdataSubSave = canvas11BitmapData.clone();
                }

                stage.addEventListener(MouseEvent.MOUSE_MOVE, lassoDrawMouseMove);
                stage.addEventListener(MouseEvent.MOUSE_UP,lassoDrawMouseUp);
            };

            return {
                start:start,
                resetPosData:resetPosData
            }
        }

        private function cSpuitTool():Function
        {
            //일단 흰색으로 배경 깔아줌
            const magSize:Number = spuitZoomCursor.magSize;
            const spuitMagRect:Rectangle = new Rectangle(0,0,magSize,magSize);
            const spuitMagMat:Matrix = new Matrix();
            var penColorBackup:uint;
            var canvasBGShape:Shape = new Shape();

            function isButtonSkipOldTool(targetName:String):Boolean
            {
                return !(targetName === "toolZoom"
                || targetName === "toolRotate"
                || targetName === "toolMirror"
                || targetName === "toolUndo"
                || targetName === "toolRedo"
                || targetName === "toolTrace");
            }

            function setSpuitMag():void
            {
                const mid:Number = magSize/(4*zoomed); //4는 기본 중앙값 magsize/2에서 zoomed나워주고 기본이 2배줌이니까 2로 나눠준값
                const tx:Number = -canvas1Bitmap.mouseX+mid;
                const ty:Number = -canvas1Bitmap.mouseY+mid;

                spuitMagMat.identity();
                spuitMagMat.translate(tx,ty);
                spuitMagMat.scale(2.0*zoomed,2.0*zoomed);

                spuitZoomCursor.spuitZoomBitmap.bitmapData.fillRect(spuitMagRect,STAGE_BG_COLOR);
                spuitZoomCursor.spuitZoomBitmap.bitmapData.draw(canvasBGShape,spuitMagMat,null,null,spuitMagRect);

                if(canvas11Bitmap.visible)
                {
                    spuitZoomCursor.spuitZoomBitmap.bitmapData.draw(canvas11Bitmap.bitmapData,spuitMagMat,null,null,spuitMagRect);
                }

                if(canvas1Bitmap.visible)
                {
                    spuitZoomCursor.spuitZoomBitmap.bitmapData.draw(canvas1Bitmap.bitmapData,spuitMagMat,null,null,spuitMagRect);
                }
            }

            function spuitPickColor():uint
            {
                if(canvas1Bitmap.hitTestPoint(mouseX,mouseY))
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
                    if(canvas1Bitmap.visible)
                    {
                        const c1:uint = canvas1BitmapData.getPixel32(canvas1Bitmap.mouseX,canvas1Bitmap.mouseY);
                        a1 = ((c1 & 0xFF000000) >>> 24)/255;
                        r1 = (c1 & 0x00FF0000) >>> 16;
                        g1 = (c1 & 0x0000FF00) >>> 8;
                        b1 = (c1 & 0x000000FF);
                    }

                    //밑 레이어
                    if(canvas11Bitmap.visible)
                    {
                        const c2:uint = canvas11BitmapData.getPixel32(canvas1Bitmap.mouseX,canvas1Bitmap.mouseY);
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

                    return RGBtoHEX(r,g,b);
                }
                else
                {
                    return penColorBackup;
                }
            }

            function spuitToolRightMouseDownEvent(e:MouseEvent):void
            {
                cancelSpuitTool(false);
            }

            function spuitToolKeyDownEvent(e:KeyboardEvent):void
            {
                if(isNotSpuitTool())
                {
                    cancelSpuitTool(false);
                    return;
                }

                if(e.keyCode === KEY.c || e.keyCode === KEY.m)
                {

                }
                else if(e.keyCode === KEY.space)
                {
                    if(penColorTransparentFlag)
                    {
                        setCurrentColor(1);

                        if(sideBar.visible === false)
                        {
                            setToolTipTempON("Current color selected");
                        }
                    }
                    else
                    {
                        setCurrentColor(1);
                        if(penColorTransparentFlag === false) selectTransparentColor();

                        if(sideBar.visible === false)
                        {
                            setToolTipTempON("Transparent color selected");
                        }
                    }
                    cancelSpuitTool(false);
                }
                else
                {
                    cancelSpuitTool(false);
                }
            }

            function spuitToolKeyUpEvent(e:KeyboardEvent):void
            {
                if(isNotSpuitTool())
                {
                    cancelSpuitTool(false);
                    return;
                }

                if(e.keyCode === KEY.c || e.keyCode === KEY.m)
                {
                    spuitToolOK();
                }
            }

            function spuitToolMouseDownEvent(e:MouseEvent):void
            {
                if(isNotSpuitTool())
                {
                    cancelSpuitTool(false);
                    return;
                }

                if(spuitZoomCursor.visible)
                {
                    spuitToolOK();
                }
                else
                {
                    cancelSpuitTool(false);
                }
            }

            function cancelSpuitTool(okFlag:Boolean):void
            {
                removeSpuitEvent();

                spuitZoomCursor.visible = false;
                canvasTraceLayer.visible = true;
                canvasBGShape.graphics.clear();
                if(okFlag)
                {
                    if(!(isOldTool(TOOL_FILL_PEN)
                    || isOldTool(TOOL_LINE)
                    || isOldTool(TOOL_PEN)))
                    {
                        setOldTool(TOOL_PEN);
                    }
                }
                setNowToolByOldTool();
            }

            function isNotSpuitTool():Boolean
            {
                return !isNowTool(TOOL_SPUIT) || replayModeON || captureModeON || fileBrowserON || clickBlockOnWindowActiveFlag;
            }

            function spuitToolOK():void
            {
                var okFlag:Boolean = false;

                if(spuitZoomCursor.visible === true)
                {
                    okFlag = true;
                    const pickedColor:uint = spuitPickColor();

                    penColor = pickedColor;
                    pickerIgnoreHistoryColor = pickedColor;
                    setHSVCursorPosByColor((rgbInfoColorTypeHSV) ? HEXtoHSV(pickedColor) : pickedColor);
                }

                cancelSpuitTool(okFlag);
            }

            function spuitToolMouseMoveEvent(e:MouseEvent):void
            {
                if(isNotSpuitTool())
                {
                    cancelSpuitTool(false);
                    return;
                }

                spuitZoomCursor.x = mouseX;
                spuitZoomCursor.y = mouseY;

                if(checkSpuitCursorVisibleON())
                {
                    setColorTransform(spuitZoomCursor["spuitNowColor"],spuitPickColor());
                    if(zoomed < 12.0)
                    {
                        setSpuitMag();
                    }
                    spuitZoomCursor.visible = true;
                }
                else
                {
                    spuitZoomCursor.visible = false;
                }
            }

            function removeSpuitMouseMoveEventDelay():void
            {
                
            }
            function removeSpuitEvent():void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,spuitToolMouseMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,spuitToolMouseDownEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,spuitToolRightMouseDownEvent);
                stage.removeEventListener(KeyboardEvent.KEY_UP,spuitToolKeyUpEvent);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN,spuitToolKeyDownEvent);
            }

            function addSpuitEvent():void
            {
                stage.addEventListener(MouseEvent.MOUSE_MOVE, spuitToolMouseMoveEvent);
                stage.addEventListener(MouseEvent.MOUSE_DOWN,spuitToolMouseDownEvent,false,-2);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,spuitToolRightMouseDownEvent,false,-2);
                stage.addEventListener(KeyboardEvent.KEY_UP,spuitToolKeyUpEvent,false,2);
                stage.addEventListener(KeyboardEvent.KEY_DOWN,spuitToolKeyDownEvent,false,2);
            }

            function checkSpuitCursorVisibleON():Boolean
            {
                return isCursorInDrawArea() && canvas1Bitmap.hitTestPoint(mouseX,mouseY,true)
                && !(traceMenu.visible && traceMenu.hitTestPoint(mouseX,mouseY));
            }

            return function ():void
            {
                toolBox.moveToolCursor("toolSpuit");

                if(checkedLayer !== 0)
                {
                    return;
                }

                if(isAllLayerInvisible())
                {
                    return;
                }

                updateOldTool();
                setOldTool(nowTool);
                setNowTool(TOOL_SPUIT);
                penColorBackup = penColor;
                setColorTransform(spuitZoomCursor["spuitOldColor"],penColor);
                setEraseButtonPosToOtherButtonPos("toolSpuit");
                spuitZoomCursor.rotateBitmap(regPoint.rotation);
                canvasTraceLayer.visible = false;
                canvasBGShape.graphics.clear();
                canvasBGShape.graphics.beginFill(CANVAS_BG_COLOR);
                canvasBGShape.graphics.drawRect(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);

                if(checkSpuitCursorVisibleON())
                {
                    spuitZoomCursor.x = mouseX;
                    spuitZoomCursor.y = mouseY;
                    setColorTransform(spuitZoomCursor["spuitNowColor"],spuitPickColor());
                    setTopChildIndex(spuitZoomCursor);

                    if(zoomed < 12.0)
                    {
                        spuitZoomCursor.spuitZoomBitmapBox.visible = true;
                        setSpuitMag();
                    }
                    else
                    {
                        spuitZoomCursor.spuitZoomBitmapBox.visible = false;
                    }
                    spuitZoomCursor.visible = true;
                }

                addSpuitEvent();
            };
        }

        private function cTransparentBG():Object
        {
            var timerActivated:Boolean = false //hand tool 오래 눌러줬을때 투명색 배경화면 보여주면 올려줌
            var isON:Boolean = false //투명 배경색 이벤트 한번만 켜주기
            var clickedPosX:Number = 0;
            var clickedPosY:Number = 0;

            function setTransparentBGTempOFFEvent(e:MouseEvent):void
            {
                const sx:Number = clickedPosX-mouseX;
                const sy:Number = clickedPosY-mouseY;
                const dist:Number = Math.sqrt(sx*sx+sy*sy);

                if(dist >= 10)
                {
                    if(timerActivated)
                    {
                        timerActivated = false;
                        canvasPanel.graphics.clear();
                        canvasPanel.graphics.beginFill(CANVAS_BG_COLOR);
                        canvasPanel.graphics.drawRect(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);
                        canvasPanel.graphics.endFill();
                    }

                    addTimerByName("viewTransBGDelayTimer",1.0,false,function():void
                    {
                        timerActivated = true;
                        canvasPanel.graphics.clear();
                        canvasPanel.graphics.beginBitmapFill(capTransparentBGBMPD);
                        canvasPanel.graphics.drawRect(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);
                        canvasPanel.graphics.endFill();
                        clickedPosX = mouseX;
                        clickedPosY = mouseY;
                    });
                }
            }

            function off():void
            {
                if(isON)
                {
                    isON = false;
                    stage.removeEventListener(MouseEvent.MOUSE_MOVE,setTransparentBGTempOFFEvent);
                }

                removeTimer("viewTransBGDelayTimer");
                if(timerActivated)
                {
                    timerActivated = false;
                    canvasPanel.graphics.clear();
                    canvasPanel.graphics.beginFill(CANVAS_BG_COLOR);
                    canvasPanel.graphics.drawRect(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);
                    canvasPanel.graphics.endFill();
                }
            }

            function on():void
            {
                if(isON === false)
                {
                    isON = true;
                    stage.addEventListener(MouseEvent.MOUSE_MOVE,setTransparentBGTempOFFEvent);
                }

                addTimerByName("viewTransBGDelayTimer",1.0,false,function():void
                {
                    timerActivated = true;
                    canvasPanel.graphics.clear();
                    canvasPanel.graphics.beginBitmapFill(capTransparentBGBMPD);
                    canvasPanel.graphics.drawRect(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);
                    canvasPanel.graphics.endFill();
                    clickedPosX = mouseX;
                    clickedPosY = mouseY;
                });
            }

            return{
                on:on,
                off:off,
                isON:isON
            };
        }

        private function setOptimizeCanvasMoveON(flag:Boolean):void
        {
            if(canvasTraceLayer.alpha > 0.0) canvasTraceLayer.visible = !flag;
            if(gridValue > 0)  canvasGrid.visible = !flag;
        }

        private function cHandTool():Function
        {
            const old:Point = new Point(0,0);

            var _replayMode:Boolean;
            var isDrawMode:Boolean;
            var xReg:Sprite;
            var xBitmap:Bitmap;

            function handToolUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,handToolMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,handToolUpEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,handToolUpEvent);
                stage.removeEventListener(MouseEvent.MIDDLE_MOUSE_UP,handToolUpEvent);

                mouseDragON = false;
                penCursorOFFFlag = false;

                checkCanvasPanelPos(_replayMode);

                if(isDrawMode)
                {
                    setOptimizeCanvasMoveON(false);

                    if(lassoToolON)
                    {
                        if(lassoMenuTempOFF === true)
                        {
                            setlassoMenuTempOFF();
                        }
                    } //tool box에서 클릭해서 핸드툴 들어갈때 필요함
                    else if(!isNowKey(KEY.space))
                    {
                        setNowToolByOldTool();
                    }

                    toolBox.setCursorVisible(true);
                    updatePreviewBoxRectPos();   
                }
                else
                {
                    if(old.x !== xReg.x || old.y !== xReg.y)
                    {
                        setFitZoomedOFF();
                    }
                    autoScroll.updateRCanvasBounds();
                }
            }

            function handToolMoveEvent(e:MouseEvent):void
            {
                xReg.x += (mouseX-old.x);
                xReg.y += (mouseY-old.y);

                old.setTo(mouseX,mouseY);
            }

            return function (replayMode:Boolean,fromWheelClick:Boolean):void
            {
                mouseDragON = true;
                _replayMode = replayMode;
                isDrawMode = !replayMode;
                xReg = (isDrawMode) ? regPoint : rregPoint;
                xBitmap = (isDrawMode) ? canvas1Bitmap : rcanvas1Bitmap;
                old.setTo(mouseX,mouseY);
                penCursorOFFFlag = true;

                if(isDrawMode)
                {
                    toolBox.setCursorVisible(false);
                    setOptimizeCanvasMoveON(true);
                }

                if(fromWheelClick)
                {
                    stage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP,handToolUpEvent);
                }

                stage.addEventListener(MouseEvent.MOUSE_MOVE, handToolMoveEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,handToolUpEvent);
                //윈도우 바깥에서 up을 하면 hand가 안꺼져서 오른쪽 마우스 뗄떼도 꺼주게함
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,handToolUpEvent);
            };
        }

        //zoom이나 rotate reg포인트 바뀔때마다
        //캔버스 판넬위치 따라 다니면서 크기 똑같이 해줌
        private function updateResizeButtonPos(width:Number,height:Number):void
        {
            function setpos(ent:canvasResizeButton,x:Number,y:Number,w:Number,h:Number):void
            {
                ent.x = x;
                ent.y = y;
                ent.width  = (w === 0) ? buttonSize : w;
                ent.height = (h === 0) ? buttonSize : h;
            }

            const z:Number = 1/zoomed;
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

        private function drawLassoBoxImageToBitmapData(toTraceLayer:Boolean):Array
        {
            const lassoBMPScaleX:Number = lassoBox1.scaleX;
            const lassoBMPScaleY:Number = lassoBox1.scaleY;
            var lassoBMPWidth:Number = lassoBMP.width*lassoBMPScaleX;
            var lassoBMPHeight:Number = lassoBMP.height*lassoBMPScaleY;

            if(checkedLayer === 2 || canvas1Bitmap.visible === false)
            {
                lassoBMPWidth = lassoBMPsub.width*lassoBMPScaleX;
                lassoBMPHeight = lassoBMPsub.height*lassoBMPScaleY;
            }

            const boxX:Number = lassoBox1.x;
            const boxY:Number = lassoBox1.y;
            const ang:Number = lassoBox1.rotation*Math.PI/180;
            var posMatrix:Matrix = new Matrix();

            posMatrix.scale(lassoBMPScaleX,lassoBMPScaleY);//스케일부터 조절해주고
            posMatrix.translate(-lassoBMPWidth/2,-lassoBMPHeight/2); //회전 중심점을 bmp중심으로 옮겨주고
            posMatrix.rotate(ang);//회전해줌
            posMatrix.translate(boxX,boxY);//라소박스 위치 그대로 붙여주면됨

            lassoBMP.smoothing = true;
            lassoBMPsub.smoothing = true;

            if(toTraceLayer === false)
            {
                if(canvas1Bitmap.visible) canvas1BitmapData.draw(lassoBMP,posMatrix);
                if(canvas11Bitmap.visible) canvas11BitmapData.draw(lassoBMPsub,posMatrix);
            }
            else
            {
                var layer1Bmpd:BitmapData;
                var layer2Bmpd:BitmapData;

                if(canvas1Bitmap.visible)
                {
                    layer1Bmpd = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
                    layer1Bmpd.draw(lassoBMP,posMatrix);
                }

                if(canvas11Bitmap.visible)
                {
                    layer2Bmpd = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
                    layer2Bmpd.draw(lassoBMPsub,posMatrix);
                }

                mergeImageToTraceLayer(layer1Bmpd,layer2Bmpd);

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

                resetTraceImageInfo();
            }

            if(lassoBitmapdataSave)
            {
                lassoBitmapdataSave.dispose();
                lassoBitmapdataSave = null;
            }

            if(lassoBitmapdataSubSave)
            {
                lassoBitmapdataSubSave.dispose();
                lassoBitmapdataSubSave = null;
            }

            return [lassoBMPScaleX,lassoBMPScaleY,
                    lassoBMPWidth,lassoBMPHeight,
                    ang,boxX,boxY];
        }

        private function setLassoOKButton():void
        {
            if(lassoToolON === true)
            {
                if(isLassoUsed()  === true) //사용후에 ok하면 처리해줌
                {
                    if(deepUndoON) setApplyDeepUndo();

                    const lassoInfo:Array = drawLassoBoxImageToBitmapData(false);
                    const point1:Vector.<Number> = lassoPointSave[0].concat();
                    const point2:Array = lassoPointSave[1].concat();
                    var command:Array = null;

                    if(lassoLayerCommand && lassoLayerCommand.length > 0)
                    {
                        command = lassoLayerCommand.concat();
                    }

                    var checklayer1:Boolean = canvas1Bitmap.visible;
                    var checklayer2:Boolean = canvas11Bitmap.visible;

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
                                                    ,lassoCopyON
                                                    ,checklayer1
                                                    ,checklayer2
                                                    ,command]);
                    undoData.addNew();
                }
                else
                {
                    lassoCancelBmpd();
                }

                disposeLassoBMP();
            }
            resetLassoBox();
        }

        private function disposeLassoBMP():void
        {
            if(lassoBMP.bitmapData) lassoBMP.bitmapData.dispose();
            if(lassoBMPsub.bitmapData) lassoBMPsub.bitmapData.dispose();
        }

        private function lassoCancelBmpd():void
        {
            if(lassoBitmapdataSave)
            {
                if(canvas1BitmapData && lassoBitmapdataSave !== canvas1BitmapData) canvas1BitmapData.dispose();
                canvas1BitmapData = lassoBitmapdataSave.clone();
                canvas1Bitmap.bitmapData = canvas1BitmapData;
            }

            if(lassoBitmapdataSubSave)
            {
                if(canvas11BitmapData && lassoBitmapdataSubSave !== canvas11BitmapData) canvas11BitmapData.dispose();
                canvas11BitmapData = lassoBitmapdataSubSave.clone();
                canvas11Bitmap.bitmapData = canvas11BitmapData;
            }

            previewBox.updateImage(canvas1BitmapData,canvas11BitmapData,CANVAS_BG_COLOR);

            if(canvasWindowON)
            {
                updateCanvasWindowImage();
            }
        }

        private function setLassoCancelButton():void
        {
            disposeLassoBMP();
            lassoCancelBmpd();
            resetLassoBox();
        }

        //펜툴로 선택,세팅 껍데기만 바꿔주는거임 penTool은 실제 툴을 진행하는거
        private function selectMoveTool():void
        {
            setNowTool(TOOL_MOVE);
            toolBox.moveToolCursor("toolMove");
            setControlBoxInfoOFF();
        }

        private function selectZoomTool():void
        {
            setNowTool(TOOL_ZOOM);
            toolBox.moveToolCursor("zoomInButton",appInfoBox);
            setControlBoxInfoOFF();
        }

        private function selectRotateTool():void
        {
            setNowTool(TOOL_ROTATE);
            toolBox.moveToolCursor("toolRotate",appInfoBox);
        }

        private function selectLassoTool():void
        {
            setNowTool(TOOL_LASSO);
            setEraseButtonPosToOtherButtonPos("toolLasso");
            toolBox.moveToolCursor("toolLasso");
            setControlBoxInfoOFF();
        }

        // private function selectScanFillTool():void
        // {
        //     setNowTool(TOOL_SCAN_FILL);

        //     penSizeCursor.visible = false;
        //     updateOpacityCursorPos(penAlphaIndex);
        //     setPenSize(penSizeIndex);

        //     setEraseButtonPosToOtherButtonPos("toolScanFill");
        //     toolBox.moveToolCursor("toolScanFill");
        //     setControlBoxInfoOFF();
        // }

        private function selectFillPenTool():void
        {
            setNowTool(TOOL_FILL_PEN);

            penSizeCursor.visible = false;

            updateOpacityCursorPos(penAlphaIndex);
            setAirBrushCheckBox(airBrushON,true);
            setPenSize(penSizeIndex);

            setEraseButtonPosToOtherButtonPos("toolFillPen");
            toolBox.moveToolCursor("toolFillPen");
            setControlBoxInfoOFF();
        }

        private function setEraseButtonPosToOtherButtonPos(toolName:String):void
        {
            const nowButton2:SimpleButton = toolBox2.getChildByName(toolName) as SimpleButton;
            if(!nowButton2) return;

            if(eraseMovedButton)
            {
                if(eraseMovedButton.x !== nowButton2.x
                || eraseMovedButton.y !== nowButton2.y) //위치가 다를 때에만 보여줌
                {
                    eraseMovedButton.visible = true;
                }
            }

            eraseMovedButton = nowButton2;

            nowButton2.visible = false;
            toolBox2["toolErase"].visible = true;
            toolBox2["toolErase"].x = nowButton2.x;
            toolBox2["toolErase"].y = nowButton2.y;
            setTopChildIndex(toolBox2["toolErase"]);
        }

        //펜 지우개 직선 지우개-직선 통합
        private function cCheckSelectMainDrawTool():Function
        {
            var sizeIndex:uint;
            var alphaIndex:uint;

            return function (size:uint,color:uint,alpha:Number,shape:Boolean,penFlag:Boolean,lineFlag:Boolean):void
            {
                if(penFlag)
                {
                    sizeIndex = penSizeIndex;
                    alphaIndex = penAlphaIndex;
                    setAirBrushCheckBox(airBrushON,true);
                }
                else
                {
                    sizeIndex = eraseSizeIndex;
                    alphaIndex = eraseAlphaIndex;
                    setAirBrushCheckBox(eraseAirBrushON,false);
                }
                setPenSize(sizeIndex);
                setPenAlpha(alpha);
                updateOpacityCursorPos(alphaIndex);

                if(lineFlag === false)
                {
                    if(penFlag)
                    {
                        setEraseButtonPosToOtherButtonPos("toolPen");
                        toolBox.moveToolCursor("toolPen");
                        setControlBoxInfoOFF();
                    }
                    else
                    {
                        if(eraseMovedButton) eraseMovedButton.visible = true;

                        eraseMovedButton = null;

                        toolBox2["toolErase"].visible = false;
                        toolBox.moveToolCursor("toolErase");
                        setControlBoxInfoOFF();
                    }
                }
                else //선툴을 선택했을때
                {
                    if(penFlag)
                    {
                        setEraseButtonPosToOtherButtonPos("toolLine");
                        toolBox.moveToolCursor("toolLine");
                        setControlBoxInfoOFF();
                    }
                    toolBox2["toolErase"].visible = true;
                    toolBox2["toolPen"].visible = true;
                }

                controlBox.shapeFlag(shape);
                penCursorPosition.check();
            }
        }

        private function selectLineTool():void
        {
            setNowTool(TOOL_LINE);
            checkSelectMainDrawTool(penSize,penColor,penAlpha,penShape,true,true);
        }

        private function selectPenTool():void
        {
            setNowTool(TOOL_PEN);
            checkSelectMainDrawTool(penSize,penColor,penAlpha,penShape,true,false);
        }

        private function selectEraseTool():void
        {
            setNowTool(TOOL_ERASE);
            checkSelectMainDrawTool(eraseSize,CANVAS_BG_COLOR,eraseAlpha,eraseShape,false,false);
        }

        //라소박스 변형이랑 플래그 초기화
        private function resetLassoBox():void
        {
            removeMouseKeyEventLassoTool();
            lassoToolON = false;
            lassoMirrorON = false;
            lassoCopyON = false;
            lassoMenuTempOFF = false;
            lassoLayerCommand = null;
            lassoSwapButtonClicked = false;
            lassoStartData = [];
            lassoPointSave = [];
            lassoBMP.filters = [];
            lassoBMPsub.filters = [];
            lassoMenu.visible = false;
            lassoDraw.x = 0;
            lassoDraw.y = 0;
            lassoBox1.visible = false;
            lassoBox1.x = 0;
            lassoBox1.y = 0;
            lassoBox1.scaleX = 1.0;
            lassoBox1.scaleY = 1.0;
            lassoBox1.rotation = 0;
            lassoBox2.visible = false;
            lassoBox2.x = 0;
            lassoBox2.y = 0;
            lassoBox2.scaleX = 1.0;
            lassoBox2.scaleY = 1.0;
            lassoBox2.rotation = 0;
            lassoMenu.lassoCopy.alpha = 1.0;
            lassoMenu.lassoLayerMerge.alpha = 1.0;
            lassoToolFunction.resetPosData();

            if(lassoBitmapdataSave)
            {
                lassoBitmapdataSave.dispose();
                lassoBitmapdataSave = null;
            }

            if(lassoBitmapdataSubSave)
            {
                lassoBitmapdataSubSave.dispose();
                lassoBitmapdataSubSave = null;
            }

            if(traceMenuON === true) traceMenu.visible = true;

            if(controlBox.layer1CheckButton.visible || controlBox.layer2CheckButton.visible)
            {
                toolBox.setToolButtonsForCheckedLayerON(BUTTON_OFF_ALPHA);
            }

            toolBox.setIconAlphaOnLassoToolON(1.0);

            controlBox.layerButtonWrapper.alpha = 1.0;
            controlBox.airBrushButtonWrapper.alpha = 1.0;
            controlBox.sharpLineButtonWrapper.alpha = 1.0;
            controlBox.opaSizeButtonWrapper.alpha = 1.0;
            pickerBox.alpha = 1.0;

            setNowToolByOldTool();
        }

        //stage를 기준으로 사각형 꼭지점들 구하기
        //회전이나 기준점 상관없이 보이는 그대로 리턴함
        private function getBoundRect(ent:DisplayObject):Object
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

        //panel은 그대로 있고 regpoint만 이동
        private function setRegPoint(tx:Number,ty:Number,replayMode:Boolean=false):void
        {
            tx = Math.round(tx);
            ty = Math.round(ty);

            var xReg:Sprite;
            var xCanvas:Sprite;
            var xZoomed:Number;

            if(replayMode)
            {
                xReg = rregPoint;
                xCanvas = rcanvasPanel;
                xZoomed = rzoomed;
            }
            else
            {
                xReg = regPoint;
                xCanvas = canvasPanel;
                xZoomed = zoomed;
            }

            if(xReg.x === tx && xReg.y === ty)
            {
                return;
            }

            //round하면 정확도가 약간 줄어드는데, 안하면 그릴때 픽셀 어긋남
            //캔버스 회전됐을때 점 위치를 구해줌
            //zoom된값을 나눠줘야 제대로된 이동거리가 나옴
            const rotateToolMoveEvent:Point = rotatePoint((xReg.x-tx)/xZoomed,
                                                 (xReg.y-ty)/xZoomed,
                                                 xReg.rotation);
            xReg.x = tx;
            xReg.y = ty;
            xCanvas.x += Math.round(rotateToolMoveEvent.x);//이동한 만큼 거꾸로 움직여줌
            xCanvas.y += Math.round(rotateToolMoveEvent.y);//rotate값 포함해서 움직여야함
        }

        //0,0을 기준으로 점tx,ty를 rad만큼 회전함,
        //3시 방향이 0도이고, 반시계 방향이 양수값임.
        private function rotatePoint(tx:Number,ty:Number,deg:Number):Point
        {
            const rad:Number = -(deg/180)*Math.PI;
            const cosO:Number = Math.cos(rad);
            const sinO:Number = Math.sin(rad);
            const rp:Point = new Point(tx*cosO-ty*sinO,tx*sinO+ty*cosO);

            return rp;
        }

        private function setTraceBitmapPosUndo(move:Point):void
        {
            canvasTraceBitmap.x += -move.x*(1/canvasTraceLayer.scaleX);
            canvasTraceBitmap.y += -move.y*(1/canvasTraceLayer.scaleY);

            tracePosInfo[0] = canvasTraceBitmap.x;
            tracePosInfo[1] = canvasTraceBitmap.y;
        }

        private function getCanvasMovedUndo(index:int,redoFlag:Boolean):Point
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

        private function drawUndoData(redoFlag:Boolean=false):void
        {
            const undoRefData:Array = undoData.getUndoRefImage();
            const undoIndexSave:int = undoIndex;

            rDataReadFlag = true;
            rIndex = undoIndexSave;
            rPrevFrame = rNowFrame;
            rNowFrame = getNowFrameUntilUndoIndex(undoIndexSave);

            rMirrorON = undoRefData[5];
            if(undoRefData[2] !== RCANVAS_WIDTH || undoRefData[3] !== RCANVAS_HEIGHT) changeCanvasSizeReplayMode(undoRefData[2],undoRefData[3],0,0,false);
            if(undoRefData[4] !== RCANVAS_BG_COLOR) setBackgroundColorReplayMode(undoRefData[4]);

            rcanvas2Draw.graphics.clear();

            if(rcanvas1BitmapData && undoRefData[0] !== rcanvas1BitmapData) rcanvas1BitmapData.dispose();
            rcanvas1BitmapData = undoRefData[0].clone();
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;

            if(rcanvas11BitmapData && undoRefData[1] !== rcanvas11BitmapData) rcanvas11BitmapData.dispose();
            rcanvas11BitmapData = undoRefData[1].clone();
            rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;

            if(rData.length > 0)
            {
                for(var i:int=0; i<=undoIndexSave; i++)
                {
                    if(!rData[i]) continue;

                    tickDraw.ready(rData[i]);
                    tickDraw.drawAll();
                }
            }

            setBackgroundColorDrawMode(RCANVAS_BG_COLOR);
            changeCanvasSize(RCANVAS_WIDTH,RCANVAS_HEIGHT,0,0,false);
            //앞 뒤 데이터가 캔버스 원점 이동 되었을때 반대방향으로 다시 움직여줌
            const movedRegPos:Point = getCanvasMovedUndo(undoIndexSave,redoFlag);
            if(movedRegPos)
            {
                regPoint.x += movedRegPos.x*zoomed;
                regPoint.y += movedRegPos.y*zoomed;
                setTraceBitmapPosUndo(movedRegPos);
            }

            if(canvas1BitmapData && rcanvas1BitmapData !== canvas1BitmapData) canvas1BitmapData.dispose();
            canvas1BitmapData = rcanvas1BitmapData.clone();
            canvas1Bitmap.bitmapData = canvas1BitmapData;

            if(canvas11BitmapData && rcanvas11BitmapData !== canvas11BitmapData) canvas11BitmapData.dispose();
            canvas11BitmapData = rcanvas11BitmapData.clone();
            canvas11Bitmap.bitmapData = canvas11BitmapData;

            setRCursorVisibleONUndo(undoIndex);
            checkMirrorCanvasReplayMirror();

            previewBox.updateImage(canvas1BitmapData,canvas11BitmapData,CANVAS_BG_COLOR);

            if(canvasWindowON)
            {
                updateCanvasWindowImage();
                updateCanvasWindowBitmapSize();
            }

            checkCanvasPanelPos(); //사이즈가 크가 줄었을때 캔버스가 창 밖으로 나가는거 체크
            updatePreviewBoxRectPos();
            setClearButtonActive();
        }

        private function redo():void
        {
            if(deepUndoON)
            {
                jumpOneFrame(false,false);
                drawReplayImageToDrawModeCanvas();
                setRCursorVisibleONFadeOFF();

                if(rNowFrame >= undoData.getRFileTotalFrame())
                {
                    setDeepUndoOFF();
                    undoIndex = -1;
                }
            }
            else
            {
                undoIndex++;
                if(undoIndex > rData.length-1)
                {
                    saveOneTime = false;
                    undoDelFlag = false;
                    undoIndex = rData.length-1;
                }
                else if(rData.length > 0)
                {
                    saveOneTime = false;
                    drawUndoData(true);
                    setRCursorVisibleONFadeOFF();
                }
            }
        }

        private function undo():void
        {
            if(deepUndoON)
            {
                if(rNowFrame > 0)
                {
                    jumpOneFrame(true,false);
                    drawReplayImageToDrawModeCanvas();
                    setRCursorVisibleONFadeOFF();
                }
            }
            else
            {
                undoIndex--;
                if(undoIndex < -1)
                {
                    saveOneTime = false;
                    undoIndex = -1;

                    if(makeJumpImageFlag === 1 || (makeJumpImageFlag === 0 && undoData.getRFileTotalFrame() > 0))
                    {
                        setDeepUndoON();
                        setRCursorVisibleONFadeOFF();
                    }
                }
                else if(rData.length > 0)
                {
                    saveOneTime = false;
                    undoDelFlag = true;
                    drawUndoData();
                    setRCursorVisibleONFadeOFF();
                }
            }
        }

        private function drawReplayImageToDrawModeCanvas():void
        {
            if(canvas1BitmapData && rcanvas1BitmapData !== canvas1BitmapData) canvas1BitmapData.dispose();
            canvas1BitmapData = rcanvas1BitmapData.clone();
            canvas1Bitmap.bitmapData = canvas1BitmapData;

            if(canvas11BitmapData && rcanvas11BitmapData !== canvas11BitmapData) canvas11BitmapData.dispose();
            canvas11BitmapData = rcanvas11BitmapData.clone();
            canvas11Bitmap.bitmapData = canvas11BitmapData;

            changeCanvasSize(rcanvas1BitmapData.width,rcanvas1BitmapData.height,0,0,false);

            setBackgroundColorDrawMode(RCANVAS_BG_COLOR);
            checkCanvasPanelPos(false);

            saveOneTime = false;

            checkMirrorCanvasReplayMirror();

            previewBox.updateImage(canvas1BitmapData,canvas11BitmapData,RCANVAS_BG_COLOR);

            if(canvasWindowON)
            {
                updateCanvasWindowImage();
                updateCanvasWindowBitmapSize();
            }
        }

        private function undoToIndex(index:int):void
        {
            undoIndex = index;
            saveOneTime = false;
            setClearButtonActive();
            drawUndoData();
        }

        private function cAddUndoData():Object
        {
            var rJumpImageCount:uint = 0;//데이터로 저장할때  rDataFrame 카운터 누적
            var rFileTotalFrame:Number = 0; //file에저장된 프레임수 누적해서 저장
            //undo 할때 이 데이터를 기준점으로 rData그려줌 메모리 적게 하려고
            var undoRefImage:Array = [rFirstImage.clone()
                                    ,rFirstImage1.clone()
                                    ,CANVAS_WIDTH
                                    ,CANVAS_HEIGHT
                                    ,CANVAS_BG_COLOR
                                    ,mirrorON];

            function resetRJumpImageCount():void
            {
                rJumpImageCount = 0;
            }

            function setUndoRefImageMirrorFlag(flag:Boolean):void
            {
                undoRefImage[5] = flag
            }

            function setUndoRefImageByReplayMode():void
            {
                undoData.setUndoRefImage(rcanvas1BitmapData.clone()
                                        ,rcanvas11BitmapData.clone()
                                        ,rcanvas1BitmapData.width
                                        ,rcanvas1BitmapData.height
                                        ,RCANVAS_BG_COLOR
                                        ,rMirrorON);
            }

            function setUndoRefImageByDrawMode():void
            {
                undoData.setUndoRefImage(canvas1BitmapData.clone()
                                        ,canvas11BitmapData.clone()
                                        ,canvas1BitmapData.width
                                        ,canvas1BitmapData.height
                                        ,CANVAS_BG_COLOR
                                        ,mirrorON);
            }

            function updateUndoRefImage():void
            {
                var rMirrorSave:Boolean = rMirrorON;

                if(undoRefImage[2] !== RCANVAS_WIDTH || undoRefImage[3] !== RCANVAS_HEIGHT) changeCanvasSizeReplayMode(undoRefImage[2],undoRefImage[3],0,0,false);
                if(undoRefImage[4] !== RCANVAS_BG_COLOR) setBackgroundColorReplayMode(undoRefImage[4]);

                if(rcanvas1BitmapData && undoRefImage[0] !== rcanvas1BitmapData) rcanvas1BitmapData.dispose();
                rcanvas1BitmapData = undoRefImage[0].clone();

                if(rcanvas11BitmapData && undoRefImage[1] !== rcanvas11BitmapData) rcanvas11BitmapData.dispose();
                rcanvas11BitmapData = undoRefImage[1].clone();

                rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;

                tickDraw.ready(rData[0]);
                tickDraw.drawAll();

                if(undoRefImage[0] && undoRefImage[0] !== rcanvas1BitmapData) undoRefImage[0].dispose();
                if(undoRefImage[1] && undoRefImage[1] !== rcanvas11BitmapData) undoRefImage[1].dispose();
                undoRefImage[0] = rcanvas1BitmapData.clone();
                undoRefImage[1] = rcanvas11BitmapData.clone();
                undoRefImage[2] = RCANVAS_WIDTH;
                undoRefImage[3] = RCANVAS_HEIGHT;
                undoRefImage[4] = RCANVAS_BG_COLOR;

                if(rMirrorON !== rMirrorSave)
                {
                    undoRefImage[5] = !undoRefImage[5];
                }

                tickDraw.setFirstRCursorPosCurrent();
            }

            function getUndoRefImage():Array
            {
                return undoRefImage;
            }

            function setUndoRefImage(bmpd1:BitmapData,bmpd2:BitmapData,width:Number,height:Number,bgColor:uint,mirrorFlag:Boolean):void
            {
                if(undoRefImage[0] && bmpd1 !== undoRefImage[0]) undoRefImage[0].dispose();
                if(undoRefImage[1] && bmpd2 !== undoRefImage[1]) undoRefImage[1].dispose();

                undoRefImage[0] = bmpd1;
                undoRefImage[1] = bmpd2;
                undoRefImage[2] = width;
                undoRefImage[3] = height;
                undoRefImage[4] = bgColor;
                undoRefImage[5] = mirrorFlag;
            }

            //undo index까지의 프레임 합을 구함
            function getRDataTotalFrame(index:int):Number
            {
                if(index < 0) return 0;

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

                if(undoDelFlag === true)
                {
                    undoDelFlag = false;
                    rData.splice(undoIndex+1);
                    rDataFrame.splice(undoIndex+1);
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

                previewBox.updateImage(canvas1BitmapData,canvas11BitmapData,CANVAS_BG_COLOR);

                if(canvasWindowON)
                {
                    updateCanvasWindowImage();
                    updateCanvasWindowBitmapSize();
                }
            }

            function addNew():void
            {
                if(undoDelFlag === true)
                {
                    undoDelFlag = false;
                    rData.splice(undoIndex+1);
                    rDataFrame.splice(undoIndex+1);
                }

                if(rData.length >= 10) //첫번째 이미지는 빼야하니깐 -1로 계산해야함
                {
                    var oldData:Array = rData[0];

                    if(oldData.length > 0)
                    {
                        const fs:FileStream = new FileStream();
                        const c:uint = rDataFrame[0];
                        const rf:File = repFile;

                        fs.open(rf,FileMode.APPEND);
                        fs.writeObject(oldData);
                        fs.close();
                        oldData = null;

                        rFileTotalFrame += c;
                        rJumpImageCount += c;
                        updateUndoRefImage();

                        if(makeJumpImageFlag === 0)
                        {
                            if(rJumpImageCount > REPLAY_MAKE_JUMPIMAGE_INTERVAL)
                            {
                                rJumpImageCount = 0;
                                const data:Array = undoRefImage;
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
                                if(workerUndoData === null) workerUndoData = [];
                                if(workerUndoData2 === null) workerUndoData2 = [];

                                workerUndoData2.push([w,h,bgColor,rf.size,rFileTotalFrame]);
                                callWorkerCompressUndoJumpImage(imgData,imgData1);

                                if(!hasTimer("workerUndoDataTimer"))
                                {
                                    addTimerByName("workerUndoDataTimer",WORKER_WAIT_INTERVAL,true,function():Boolean
                                    {
                                        if(workerUndoData.length > 0)
                                        {
                                            rJumpImageFrameData.push(workerUndoData2[0][4]);
                                            fs.open(rJumpImageFolder.resolvePath((rJumpImageFrameData.length-1)+""),FileMode.WRITE);
                                            fs.writeObject([workerUndoData[0][0]//레이어1
                                                            ,workerUndoData[0][1]//레이어2
                                                            ,workerUndoData2[0][0] //가로
                                                            ,workerUndoData2[0][1] //새로
                                                            ,workerUndoData2[0][2] //배경색
                                                            ,workerUndoData2[0][3] //마지막 바이트
                                                            ,workerUndoData2[0][4] //마지막 프레임 합
                                                            ,mirrorON]);//미러 플래그
                                            fs.close();
                                            workerUndoData[0][0].clear();
                                            workerUndoData[0][1].clear();
                                            workerUndoData[0][0] = null;
                                            workerUndoData[0][1] = null;

                                            workerUndoData[0] = null;
                                            workerUndoData2[0] = null;

                                            workerUndoData.shift();
                                            workerUndoData2.shift();
                                        }
                                        else if(workerUndoData2.length === 0 && workerUndoData.length === 0)
                                        {
                                            workerUndoData.length = 0;
                                            workerUndoData2.length = 0;
                                            workerUndoData = null;
                                            workerUndoData2 = null;

                                            return false;
                                        }
                                        return true;
                                    });
                                }
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
                    saveOneTime = false;
                    rDataReadFlag = true;
                }

                undoIndex = rData.length-1;
                previewBox.updateImage(canvas1BitmapData,canvas11BitmapData,CANVAS_BG_COLOR);

                if(canvasWindowON)
                {
                    updateCanvasWindowImage();
                }

                rPrevFrame = rNowFrame;
                rNowFrame = getTotalFrame();
                setClearButtonActive();
            };

            return {
                addNew:addNew,
                addContinue:addContinue,
                setRFileTotalFrame:setRFileTotalFrame,
                getRFileTotalFrame:getRFileTotalFrame,
                getRDataTotalFrame:getRDataTotalFrame,
                getUndoRefImage:getUndoRefImage,
                setUndoRefImage:setUndoRefImage,
                setUndoRefImageByReplayMode:setUndoRefImageByReplayMode,
                setUndoRefImageByDrawMode:setUndoRefImageByDrawMode,
                setUndoRefImageMirrorFlag:setUndoRefImageMirrorFlag,
                resetRJumpImageCount:resetRJumpImageCount,
                updateLastRDataMirror:updateLastRDataMirror
            }
        }

        // hsv커서가 color에 맞춰서 위치를 움직여줌
        private function setHSVCursorPosByColor(color:*):void
        {
            var hexColor:uint;

            if(color is uint)
            {
                hexColor = color;
            }
            else if(color is Vector.<Number>)
            {
                hexColor = HSVtoHEX(color[0],color[1],color[2]);
            }
            else
            {
                return;
            }

            penColorTransparentFlag = false;

            var hsvColor:Vector.<Number> = (color is uint) ? HEXtoHSV(hexColor) : color;

            hsvColorArr[1] = hsvColor[1];
            hsvColorArr[2] = hsvColor[2];

            if(hsvColor[1] > 0)
            {
                hsvColorArr[0] = hsvColor[0];
                pickerBox["hueCursor"].x = Math.round(hsvColor[0]*pickerBox["svBoxWidth"]);
            }

            pickerBox["svCursor"].x = Math.round(hsvColor[1]*pickerBox["svBoxWidth"]);
            pickerBox["svCursor"].y = Math.round(pickerBox["svBoxHeight"] - hsvColor[2]*pickerBox["svBoxHeight"]);

            //s v값을 제외한 순수 hue 컬러
            const baseColor:Vector.<uint> = HSVtoRGB(hsvColor[0],1.0,1.0);
            const baseHexColor:uint = RGBtoHEX(baseColor[0],baseColor[1],baseColor[2]);
            pickerBox.changeHueColor(baseHexColor);

            if(color is uint)
            {
                updateRGBInfoTextByColor(hexColor);
            }
            else
            {
                updateRGBInfoTextByColor(hsvColor);
            }
            pickerBox.updateRGBInfoBG(hexColor,setRGBInfoBorderColor(hexColor),myPalettePresetType);
        }

        //hex에서 rgb vector 배열로 반환
        private function HEXtoRGB(hex:uint):Vector.<uint>
        {
            const r:uint = (hex >> 16) & 0xFF;
            const g:uint = (hex >> 8) & 0xFF;
            const b:uint = hex & 0xFF;
            const rgb:Vector.<uint> = new <uint> [r,g,b];

            return rgb;
        }

        //rgb값을 16진수로 hex값으로 만들어줌
        private function RGBtoHEX(r:uint, g:uint, b:uint):uint
        {
            return (r << 16 | g << 8 | b);
        }

        private function HSVtoHEX(h:Number, s:Number, v:Number):uint
        {
            const rgb:Vector.<uint> = HSVtoRGB(h,s,v);

            return RGBtoHEX(rgb[0],rgb[1],rgb[2]);
        }

        //h는 0에서 360, s v는 0~1.0 사이값 넣어줘야함
        private function HSVtoRGB(h:Number, s:Number, v:Number):Vector.<uint>
        {
            v = Math.round(v * 255);

            const i:Number = Math.floor(h * 6);
            const f:Number = h * 6 - i;
            const p:Number = Math.round(v * (1 - s));
            const q:Number = Math.round(v * (1 - f * s));
            const t:Number = Math.round(v * (1 - (1 - f) * s));

            switch(i)
            {
                case 6:
                case 0: return new <uint> [v,t,p];
                case 1: return new <uint> [q,v,p];
                case 2: return new <uint> [p,v,t];
                case 3: return new <uint> [p,q,v];
                case 4: return new <uint> [t,p,v];
                case 5: return new <uint> [v,p,q];
            }

            return new <uint> [0,0,0];
        }

        //eyedropper에서 뽑은 rgb 컬러를 hvs로 변환해줄때 사용
        private function getHSVInfoString(hsvColor:Vector.<Number>):String
        {
            const h:Number = Math.round(hsvColor[0]*360);
            const s:Number = Math.round(hsvColor[1]*100);
            const v:Number = Math.round(hsvColor[2]*100);

            return "HSV "+h+","+s+","+v;
        }

        private function RGBtoHSV(r:Number, g:Number, b:Number):Vector.<Number>
        {
            r = r/255;
            g = g/255;
            b = b/255;

            const max:Number = Math.max(r, g, b);
            const min:Number = Math.min(r, g, b);
            var h:Number = 0;
            var s:Number = 0;
            var v:Number = max;
            const d:Number = max - min;

            s = (max == 0) ? 0 : d/max;

            if (max == min)
            {
                h = 0; //achromatic
            }
            else
            {
                if(max === r) h = (g - b) / d + (g < b ? 6 : 0);
                else if(max === g) h = (b - r) / d + 2;
                else if(max === b) h = (r - g) / d + 4;

                h = h/6;
            }

            const hsv:Vector.<Number> = new <Number> [h,s,v];
            if(s === 0) hsv[0] = hsvColorArr[0];

            return hsv;
        }

        //opabox의 커서 위치와 색깔을 바꿈
        private function updateOpacityCursorPos(index:int):void
        {
            if(index <= 0) return;

            const curButton:Sprite = controlBox.opaBox.getChildByName("alphaButton"+index) as Sprite;

            if(!curButton) return;

            controlBox.opaCursor.x = curButton.x;
            controlBox.opaCursor.y = curButton.y;
        }

        private function setPenAlpha(alpha:Number=0.0):void
        {
            var index:int = penAlphaList.indexOf(alpha);
            const eraseFlag:Boolean = isNowTool(TOOL_ERASE);

            updateOpacityCursorPos(index);

            if(eraseFlag === false)
            {
                penAlpha = alpha;
                penAlphaIndex = index;
            }
            else if(eraseFlag === true)
            {
                eraseAlpha = alpha;
                eraseAlphaIndex = index;
            }
        }

        private function cDrawDot():Function
        {
            const cmd:Vector.<int> = new Vector.<int>();
            const pos:Vector.<Number> = new Vector.<Number>();

            return function (shape:Boolean,size:uint,color:uint,posX:Number,posY:Number,rotation:Number):void
            {
                canvas2Draw.graphics.clear();
                canvas2Draw.graphics.lineStyle(0,0,0);
                canvas2Draw.graphics.beginFill(color);

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

                    canvas2Draw.graphics.drawPath(cmd,pos);
                }
                else
                {
                    canvas2Draw.graphics.drawCircle(posX,posY,size/2);
                }
                canvas2Draw.graphics.endFill();
            }
        }

        private function updateSidebarDefaultRightPos():void
        {
            sideBar.x = Math.round(stage.stageWidth-sideBar.getWidth());
        }

        private function setSideBarRightPosition(ignoreCanvasMove:Boolean):void
        {
            updateSidebarDefaultRightPos();

            sideBarScrollSet.x = 9;
            sideBarScrollSet.y = scrollSetMovedY;
            previewBox.x = -4;
            previewBox.y = 0;
            appInfoBox.setWidth(previewBox.BOX_WIDTH);
            appInfoBox.x = previewBox.x-2;
            appInfoBox.y = Math.floor(previewBox.y+previewBox.BOX_HEIGHT+6);
            controlBox.x = 39;
            controlBox.y = Math.floor(appInfoBox.y+appInfoBox.height+7);
            pickerBox.x = 39;
            pickerBox.y = Math.floor(controlBox.y+controlBox.height+10);
            toolBox.x = -2;
            toolBox.y = Math.floor(controlBox.y+1);

            resetScrollBarXPosition();

            sideBar.y = topBar.BARSIZE*topBar.scaleX;

            if(sideBar.visible)
            {
                if(ignoreCanvasMove === false) regPoint.x -= STAGE_RIGHT_OFFSET;
                topBar.sideBarOFFButton.visible = true;
                topBar.sideBarOFFButton2.visible = false;

            }
            else
            {
                topBar.sideBarONButton.visible = true;
                topBar.sideBarONButton2.visible = false;
            }

            topBar.sideBarPositionButton.visible = false;
            topBar.sideBarPositionButton2.visible = true;

            checkFOFOPosition();
            updateStageOffset();

            if(lassoToolON) checkBoxPosition(lassoMenu);
            if(traceMenuON) checkBoxPosition(traceMenu);
        }

        private function setSideBarLeftPosition():void
        {
            sideBar.x = 0;

            sideBarScrollSet.x = 5;
            sideBarScrollSet.y = scrollSetMovedY;
            previewBox.x = 0;
            previewBox.y = 0;
            appInfoBox.setWidth(previewBox.BOX_WIDTH);
            appInfoBox.x = previewBox.x-2;
            appInfoBox.y = Math.floor(previewBox.y+previewBox.BOX_HEIGHT+6);
            controlBox.x = 0;
            controlBox.y = Math.floor(appInfoBox.y+appInfoBox.height+7);
            pickerBox.x = 0;
            pickerBox.y = Math.floor(controlBox.y+controlBox.height+10);
            toolBox.x = 177;
            toolBox.y = Math.floor(controlBox.y+1);

            if(toolBox.getDeafultY() === 0) toolBox.setDeafultY(toolBox.y);

            resetScrollBarXPosition();

            sideBar.y = topBar.BARSIZE*topBar.scaleX;

            if(sideBar.visible)
            {
                regPoint.x += STAGE_LEFT_OFFSET;
                topBar.sideBarOFFButton.visible = false;
                topBar.sideBarOFFButton2.visible = true;
            }
            else
            {
                topBar.sideBarONButton.visible = false;
                topBar.sideBarONButton2.visible = true;
            }
            topBar.sideBarPositionButton.visible = true;
            topBar.sideBarPositionButton2.visible = false;

            updateStageOffset();
            checkFOFOPosition();

            if(lassoToolON) checkBoxPosition(lassoMenu);
            if(traceMenuON) checkBoxPosition(traceMenu);
        }

        private function updateScrollBarColorHeight():void
        {
            const scale:Number = getUIScale();
            const height:Number = Math.round((stage.stageHeight-STAGE_TOP_OFFSET-STAGE_BOTTOM_OFFSET)/scale);
            const color1:uint = uiColorSet[uiColorIndex][1];
            const color2:uint = uiColorSet[uiColorIndex][0];

            sideBarScrollBar.graphics.clear();
            sideBarScrollBar.graphics.lineStyle(1,color1,1.0,true);
            sideBarScrollBar.graphics.beginFill(color2);
            sideBarScrollBar.graphics.drawRect(0,0,16,height);
            sideBarScrollBar.graphics.endFill();

            scrollBarHeight = height;
        }

        private function makeMenuFamlity():void
        {
            aboutPanel.name = "aboutPanel";
            aboutPanel.setVersionInfo(APP_VERSION.toFixed(2));
            topBar.name = "topBar";
            sideBarScrollBar.name = "sideBarScrollBar";
            topBar.makeTopbarBG(COLOR_MID_DARK);
            changeTopBarIcons("draw");

            fillPenBox.x = -fillPenBox.width-3;
            fillPenBox.y = -fillPenBox.height-3;

            pickerBox.rgbInfo.addEventListener(FocusEvent.FOCUS_IN, rgbInfoTextFocusInEvent);
            pickerBox.rgbInfo.addEventListener(FocusEvent.FOCUS_OUT, rgbInfoTextFocusOutEvent);
            previewBox.scrollRect = new Rectangle(0,0,previewBox.width,previewBox.height);

            sideBarScrollSet.addChild(previewBox);
            sideBarScrollSet.addChild(appInfoBox);
            toolBox.initCanvasControlButtons(appInfoBox);
            sideBarScrollSet.addChild(toolBox);
            sideBarScrollSet.addChild(controlBox);
            sideBarScrollSet.addChild(pickerBox);
            // appInfoBox.cacheAsBitmap = true;
            // toolBox.cacheAsBitmap = true;
            // toolBox.cacheAsBitmap = true;
            // controlBox.cacheAsBitmap = true;
            // pickerBox.cacheAsBitmap = true;

            sideBar.addChild(sideBarScrollBar);
            sideBar.addChild(sideBarScrollSet);
            sideBar.updateSideBGSize(getSideBarBGHeight());
            sideBarScrollBar.alpha = 0.7;
            STAGE_TOP_OFFSET = topBar.BARSIZE;

            capStampFontListBox.y = 100;

            topBar.updateTimerPos(stage.stageWidth);
            
            stage.addChild(loadMenuBox);
            stage.addChild(traceMenu);
            stage.addChild(aboutPanel);
            stage.addChild(topBar);
            stage.addChild(sideBar);
            stage.addChild(fillPenBox);
            stage.addChild(toolBox2);
            stage.addChild(rotateCursorBox);
            stage.addChild(toolTipBox);
            stage.addChild(hintBox);
            stage.addChild(hintHorverCursor);
            stage.addChild(numPadBox);
            stage.addChild(capStampFontListBox);
            setTopChildIndex(topBar);
        }

        private function makeReplayCanvasFamily():void
        {
            rcanvasPanel.name = "rcanvasPanel";
            rregPoint.name = "rregPoint";
            rcanvas1Bitmap.name = "rcanvas1Bitmap";
            rcanvas11Bitmap.name = "rcanvas11Bitmap";
            rcanvas2.name = "rcanvas2";
            rcanvas2Draw.name = "rcanvas2Draw";
            replayTimeBox.name = "replayTimeBox";
            rCursor.name = "rCursor";
            rCursor.mouseEnabled = false;

            rcanvasPanel.graphics.beginFill(CANVAS_BG_COLOR);
            rcanvasPanel.graphics.drawRect(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);
            rcanvasPanel.graphics.endFill();

            rcanvas2.addChild(rcanvas2Bitmap);//
            rcanvas2.addChild(rcanvas2Draw);//canvas2에
            rcanvas2.blendMode = "layer";//캔버스1이랑 알파 불투명도가 겹치지 않게 layer모드로 해줌

            rcanvasPanel.addChild(rcanvas11Bitmap);//판넬에 canvas11추가
            rcanvasPanel.addChild(rcanvas1Bitmap);//판넬에 canvas1추가
            rcanvasPanel.addChild(rcanvas2);//판넬에 canvas2추가
            rcanvasPanel.scrollRect = new Rectangle(0,0,RCANVAS_HEIGHT,RCANVAS_HEIGHT);//마스크 해줘서 판 밖으로 선나타나지 않도록함

            rcanvasPanel.x = Math.floor(-rcanvasPanel.width/2);
            rcanvasPanel.y = Math.floor(-rcanvasPanel.height/2);

            rregPoint.addChild(rcanvasPanel);
            rregPoint.visible = false;
            stage.addChild(rregPoint);
            stage.addChild(replayTimeBox);
            replayTimeBox.x = 0;
            replayTimeBox.y = topBar.BARSIZE;
        }

        private function makeCanvasFamily():void
        {
            var g:Graphics;

            canvasPanel.name = "canvasPanel";
            regPoint.name = "regPoint";
            canvas1Bitmap.name = "canvas1Bitmap";
            canvas11Bitmap.name = "canvas11Bitmap";
            canvas2.name = "canvas2";
            canvas2Draw.name = "canvas2Draw";
            penSizeCursor.name = "penSizeCursor";
            stageBG.name = "stageBG";
            canvasTraceLayer.name = "canvasTraceLayer";
            canvasGrid.name = "canvasGrid";
            canvasFlash.name = "canvasFlash";

            updateStageBGSize();

            penSizeCursor.visible = false;

            lassoBox1.name = "lassoBox1";
            lassoBox1.addChild(lassoBMP);
            lassoBox1.addChild(lassoDraw);
            lassoBox1.visible = false;
            lassoBox2.name = "lassoBox2";
            lassoBox2.addChild(lassoBMPsub);
            lassoBox2.visible = false;

            captureAreaRect.visible = false;

            setBackgroundColorDrawMode(CANVAS_BG_COLOR);
            updateCanvasPanelMask(CANVAS_WIDTH,CANVAS_HEIGHT);

            updateStageBGColor(uiColorSet[uiColorIndex][2]);

            canvasTraceLayer.alpha = traceAlphaSave;
            canvasTraceLayer.addChild(canvasTraceBitmap);
            canvas2.addChild(canvas2Bitmap);
            canvas2.addChild(canvas2Draw);
            canvas2.blendMode = "layer";//캔버스1이랑 알파 불투명도가 겹치지 않게 layer모드로 해줌

            rCursor.visible = false;

            canvasPanel.addChild(canvasTraceLayer);
            canvasPanel.addChild(canvas11Bitmap);
            canvasPanel.addChild(lassoBox2);
            canvasPanel.addChild(canvas1Bitmap);
            canvasPanel.addChild(lassoBox1);
            canvasPanel.addChild(canvas2);
            canvasPanel.addChild(canvasGrid);
            canvasPanel.addChild(rCursor);
            //canvasrotate가 중점으로 올수있게 위치를 절반으로세팅
            canvasPanel.x = Math.floor(-canvasPanel.width/2);
            canvasPanel.y = Math.floor(-canvasPanel.height/2);

            regPoint.addChild(canvasPanel);

            stage.addChild(stageBG);
            stage.addChild(spuitZoomCursor);
            stage.addChild(lassoMenu);
            stage.addChild(regPoint);
            stage.addChild(penSizeCursor);
            stage.setChildIndex(regPoint,0);
            stage.setChildIndex(stageBG,0);
        }

        private function saveAllData():void
        {
            saveAppData();
            saveUndoData();
            saveReplayFrameData();
            saveTraceImage();
            saveMypPaletteList();
            saveScratchPadImage();
        }

        private function resetScrollBarXPosition():void
        {
            if(sideBarScrollBar.visible === false)
            {
                sideBarScrollBar.x = 0;
            }
            else if(isRightSidebar)
            {
                sideBarScrollBar.x = previewBox.x-sideBarScrollBar.width+4;
            }
            else
            {
                sideBarScrollBar.x = sideBar.WIDTH;
            }
        }


        private function updateScrollBarHeight():void
        {
            updateScrollBarColorHeight();
            resetScrollBarXPosition();
            checkScrollSetOutStage();
        }

        private function windowResizedBeforeClosingEvent(e:Event):void
        {
            lastWindowState = 1;
            stage.nativeWindow.close();
        }

        private function getSideBarBGHeight():Number
        {
            return (stage.stageHeight-topBar.BARSIZE*getUIScale())/getUIScale();
        }

        private function windowResizeEvent(e:Event):void
        {
            addTimerByName("windowResizeDelayTimer",0.2,false,function():void
            {
                const dx:Number = Math.round((stage.nativeWindow.width-lastWindowSize.x)/1.75);
                const dy:Number = Math.round((stage.nativeWindow.height-lastWindowSize.y)/1.75);

                if(captureModeON)
                {
                    captureWindowMove.setTo(dx,dy);
                    fitCanvasToWindow(true);
                    
                    if(!drawCaptureArea.isFullImageCapture())
                    {
                        drawCaptureArea.updateDrawArea(true);
                    }
                }
                else
                {
                    rregPoint.x = rregPoint.x+dx;
                    rregPoint.y = rregPoint.y+dy;
                    regPoint.x = regPoint.x+dx;
                    regPoint.y = regPoint.y+dy;
                    checkCanvasPanelPos(replayModeON);
                }

                if(lassoToolON)
                {
                    lassoMenu.x += dx;
                    lassoMenu.y += dy;
                    checkBoxPosition(lassoMenu);
                }

                if(traceMenuON)
                {
                    traceMenu.x += dx;
                    traceMenu.y += dy;
                    checkBoxPosition(traceMenu);
                }

                if(aboutPanelON)
                {
                    setAboutPanelCenterPos();
                }

                if(replayModeON)
                {
                    updateReplayBarPos(stage.stageWidth);
                    autoScroll.updateRCanvasBounds();

                    if(rFitZoomedON)
                    {
                        fitCanvasToWindowManualReplayMode();
                    }
                }

                updateStageBGColor(uiColorSet[uiColorIndex][2]);
                topBar.updateTopbarBG(stage.stageWidth);
                topBar.updateTimerPos(stage.stageWidth);
                sideBar.updateSideBGSize(getSideBarBGHeight());

                if(quickSidebarON)
                {
                    _quickSidebarOFF();
                }
                else
                {
                    setDefaultXSidebarPos();
                }
                
                updateScrollBarHeight();
                updatePreviewBoxRectPos();

                if(loadMenuBox.visible === true)
                {
                    setDragDropSelectBoxCenterPos();
                }

                updateStageBGSize();
                checkFOFOPosition();
                hint.updateHintPos();

                lastWindowSize.setTo(stage.nativeWindow.width,stage.nativeWindow.height);
            });
        }

        private function setZoomCanvas(newZoom:Number,replayMode:Boolean = false):void
        {
            if(!newZoom) newZoom = 1.0;
            if(newZoom < 0.0) newZoom = Math.abs(newZoom);

            var xReg:Sprite;

            if(!replayMode)
            {
                xReg = regPoint;
                zoomed = newZoom;

                if(!captureModeON)
                {
                    penCursorPosition.updateZoom(newZoom);
                }
            }
            else
            {
                rzoomed = newZoom;
                xReg = rregPoint;

                if(airBrushSizeReplayMode > 0)
                {
                    setBlurCanvasBySizeReplayMode(airBrushSizeReplayMode);
                }
            }

            xReg.scaleX = newZoom;
            xReg.scaleY = newZoom;

            if(captureModeON && captureFlipped)
            {
                xReg.scaleX = -xReg.scaleX;
            }

            if(!captureModeON)
            {
                appInfoBox.setZoom(newZoom);
            }

            updateRCursorScale(newZoom);
        }

        private function windowClosingEvent(e:Event):void
        {
            windowClosingFlag = true;

            if(captureModeON === true) setCaptureOFF();
            if(replayStartON === true) stopReplay();
            if(lassoToolON) setLassoCancelButton();

            if(stage.nativeWindow.displayState === "maximized") //최대화이면 복원해주고 닫아줌
            {
                stage.nativeWindow.addEventListener(Event.RESIZE,windowResizedBeforeClosingEvent);
                stage.nativeWindow.restore();
                e.preventDefault();
            }
            else
            {
                lastWindowState = 0;
            }
        }

        private function setTopChildIndex(ent:DisplayObject):void
        {
            const parent:DisplayObjectContainer = ent.parent as DisplayObjectContainer;

            if(parent === null) return;
            if(parent.getChildIndex(ent) === parent.numChildren-1) return;

            parent.setChildIndex(ent,parent.numChildren-1);
        }

        //check box position함수는 요소 전체가 창에서 넘어가만 않게 하는거고
        private function checkBoxPosition(ent:DisplayObject):void
        {
            if(ent.x+ent.width > stage.stageWidth-STAGE_RIGHT_OFFSET) ent.x = stage.stageWidth-ent.width-STAGE_RIGHT_OFFSET;
            else if(ent.x < STAGE_LEFT_OFFSET) ent.x = STAGE_LEFT_OFFSET;

            if(ent.y < STAGE_TOP_OFFSET) ent.y = STAGE_TOP_OFFSET;
            else if(ent.y+ent.height > stage.stageHeight-STAGE_BOTTOM_OFFSET) ent.y = (stage.stageHeight-STAGE_BOTTOM_OFFSET)-ent.height;
        }

        private function checkCanvasPanelPos(replayMode:Boolean = false):void
        {
            var xReg:Sprite;
            var xCanvas:Bitmap;

            if(replayMode)
            {
                xReg = rregPoint;
                xCanvas = rcanvas1Bitmap;
            }
            else
            {
                xReg = regPoint;
                xCanvas = canvas1Bitmap;
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
            if(left > rightLimit) xReg.x -= left-rightLimit;
            else if(right < leftLimit) xReg.x += leftLimit-right;

            if(bottom < topLimit) xReg.y += topLimit-bottom;
            else if(top > bottomLimit) xReg.y -= top-bottomLimit;
        }

        //캔버스 정 가운데로
        private function getStageCenterPos(flag:int):Point
        {
            const scale:Number = getUIScale();
            const center:Point = new Point(0,0);
            var topBarOffset:Number = topBar.BARSIZE*scale;

            if(flag === 0) //draw mode
            {
                center.setTo((!isSidebarVisible) ? Math.floor(stage.stageWidth/2)
                             :(isRightSidebar)   ? Math.floor((stage.stageWidth-STAGE_RIGHT_OFFSET)/2)
                                                 : Math.floor(STAGE_LEFT_OFFSET+(stage.stageWidth-STAGE_LEFT_OFFSET)/2)
                            ,Math.floor(topBarOffset+(stage.stageHeight-topBarOffset)/2));
            }
            else if(flag === 1) //replay mode
            {
                topBarOffset = topBarOffset+replayTimeBox.BARSIZE*scale;
                center.setTo(stage.stageWidth/2,Math.floor(topBarOffset+(stage.stageHeight-topBarOffset)/2));
            }
            else if(flag === 2) //capture mode
            {
                center.setTo(stage.stageWidth/2,Math.floor(topBarOffset+(stage.stageHeight-topBarOffset)/2));
            }
            else
            {
                center.setTo(stage.stageWidth/2,stage.stageHeight/2);
            }

            return center;
        }

        private function setCenvasCenterPos(replayMode:Boolean=false,captureMode:Boolean=false):void
        {
            var xReg:Sprite;
            var xCanvas:Sprite;
            var w:Number;
            var h:Number;
            var center:Point;

            if(replayMode)
            {
                xReg =  rregPoint;
                xCanvas = rcanvasPanel;
                w = RCANVAS_WIDTH;
                h = RCANVAS_HEIGHT;
            }
            else
            {
                xReg =  regPoint;
                xCanvas = canvasPanel;
                w = CANVAS_WIDTH;
                h = CANVAS_HEIGHT;
            }

            if(captureMode) center = getStageCenterPos(2);
            else if(replayMode) center = getStageCenterPos(1);
            else center = getStageCenterPos(0);

            xReg.x = Math.floor(center.x);
            xReg.y = Math.floor(center.y);
            xCanvas.x = Math.floor(-w/2);
            xCanvas.y = Math.floor(-h/2);
        }

        private function clearCanvasReplayMode():void
        {
            const rect:Rectangle = new Rectangle(0,0,RCANVAS_WIDTH,RCANVAS_HEIGHT);

            rcanvas2Draw.graphics.clear();
            rcanvas1BitmapData.fillRect(rect,0);
            rcanvas11BitmapData.fillRect(rect,0);
            rcanvas2BitmapData.fillRect(rect,0);
        }

        private function clearCanvas():void
        {
            const rect:Rectangle = new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);

            if(canvas1BitmapData) canvas1BitmapData.fillRect(rect,0);
            if(canvas11BitmapData) canvas11BitmapData.fillRect(rect,0);
            if(canvas2BitmapData) canvas2BitmapData.fillRect(rect,0);
        }

        //keyfunc
        private function setReplaySpeedByKey(upFlag:Boolean):void
        {
            const clacMax:Number = Math.floor(TOTAL_FRAME/(stage.frameRate*3));
            if(clacMax <= 0) return;

            const maxSpeed:Number = REPLAY_MAX_SPEED;
            var _rSpeed:Number = rSpeed;
            var max:Number = (clacMax > maxSpeed) ? maxSpeed : clacMax;

            if(upFlag)
            {
                _rSpeed += 1;
                if(_rSpeed > max) _rSpeed = max;
            }
            else
            {
                _rSpeed -= 1;
                if(_rSpeed < 1) _rSpeed = 1;
            }

            const timeStr:String = getReplayTotalTime(_rSpeed);
            const finalStr:String = STRING_PLAYBACK_SPEED+_rSpeed+timeStr;
            setHintONTemp(finalStr);

            rSpeed = _rSpeed;
            topBar.setSpeedButtonPosByValue(_rSpeed,max);
            if(playbackFinished === false) updateReplayRemainTimeText();
        }

        private function setReplaySpeedByKeyButton(upFlag:Boolean):void
        {
            setHoldKeyRepeat(true,setReplaySpeedByKey,upFlag);
        }

        private function keyUpReplayMode(e:KeyboardEvent):void
        {
            checkKeyUp(e.keyCode);
        }

        private function keyDownReplayMode(e:KeyboardEvent):void//keydown2
        {
            const keyCode:uint = KEY_BUFFER[0];

            if(mouseClickON || rightMouseClickON || isNowKey(keyCode) || loadMenuBox.visible) return;

            if(isPressingControlShift())
            {
                checkCommandSubKey(3,false,function(input:int):void
                {
                    if(input === KEY.s) saveFile(true);
                });
                return;
            }
            else if(isPressingShift())
            {
                checkCommandSubKey(2,false,function(input:int):void
                {
                    switch(input)
                    {
                        case KEY.left:
                        case KEY.z:
                        case KEY.dot:
                            setJumpOneFrame(true,true);
                        break;

                        case KEY.right:
                        case KEY.x:
                        case KEY.comma:
                            setJumpOneFrame(false,true);
                        break;

                        case KEY.f5:
                        case KEY.f6:
                            resetZoomReplayMode();
                        break;
                    }
                });
                return;
            }
            else if(isPressingControl())
            {
                checkCommandSubKey(2,false,function(input:int):void
                {
                    if(input === KEY.s) saveFile(false);
                    else if(input === KEY.o) loadFile();
                    else if(input === KEY.c || input === KEY.m) setCaptureModeON();
                });
                return;
            }

            setNowKey(keyCode);

            switch(keyCode)
            {
                case KEY.left:
                case KEY.z:
                case KEY.dot:
                    setJumpOneFrame(true,false);
                break;

                case KEY.right:
                case KEY.x:
                case KEY.comma:
                    setJumpOneFrame(false,false);
                break;

                case KEY.up:
                case KEY.f:
                case KEY.h:
                    setReplaySpeedByKeyButton(true);
                break;

                case KEY.down:
                case KEY.v:
                case KEY.n:
                    setReplaySpeedByKeyButton(false);
                break;

                case KEY.backspace:
                case KEY.esc:
                {
                    setReplayModeOFF();
                }
                break;

                case KEY.f1:
                case KEY.f7:
                {
                    setReplayModeOFF();
                }
                break;

                case KEY.f2:
                {
                    if(topBar.reRecordingButton.alpha === 1.0)
                    {
                        setCountDownLongKey(null,"Creating new file from this image..",setDeleteBarReRecord,setReRecord,setReplayDeleteBarVisibleOFF);
                    }
                }
                break;

                case KEY.f3:
                {
                    if(topBar.cutPrevDataButton.alpha === 1.0)
                    {
                        setCountDownLongKey(null,"Deleting front data..",setDeleteBarDeleteFrontData,deleteReplayFrontData,setReplayDeleteBarVisibleOFF);
                    }
                }
                break;

                case KEY.f4:
                {
                    if(topBar.superUndoButton.alpha === 1.0)
                    {
                        setCountDownLongKey(null,"Deleting back data.. ",setDeleteBarSuperUndo,superUndo,setReplayDeleteBarVisibleOFF);
                    }
                }
                break;

                case KEY.f5:
                    setZoomInButton(false,true);
                break;

                case KEY.f6:
                    setZoomInButton(true,true);
                break;

                case KEY.enter:
                case KEY.space:
                {
                    if(replayStartON === false) startReplay();
                    else stopReplay();
                }
                break;
            }
        }

        private function keyUpDrawMode(e:KeyboardEvent):void //keyup1
        {
            const keyCode:uint = e.keyCode;

            if(isNowKey(keyCode))
            {
                if(mouseClickON === true)
                {
                    keyWaitMouseUp = true;
                }
                else if(KEY_BUFFER.length > 0)
                {
                    keyDownDrawMode(null);
                }
                else
                {
                    layerCheckKeyPressed = false;
                    if(oldTool > TOOL_NONE) setNowToolByOldTool();

                    penCursorPosition.check();
                }
            }

            if(KEY_BUFFER.length === 0)
            {
                resetNowKey();
            }

            if(!isPressingControl())
            {
                if(resizeCanvas.getInitON()) resizeCanvas.exit(true);
                if(resizeButtonR.visible) setResizeButtonVisible(false);
            }
        }

        private function checkCommandSubKey(length:uint,saveFlag:Boolean,func:Function):Boolean
        {
            if(KEY_BUFFER.length === length)
            {
                const subKey:uint = KEY_BUFFER[length-1];
                if(saveFlag) setNowKey(subKey);
                func(subKey);
                return true;
            }
            return false;
        }

        private function keyDownDrawMode(e:KeyboardEvent):void
        {
            if(mouseClickON || rightMouseClickON || keyWaitMouseUp || fillPenStarted || loadMenuBox.visible || topBar.gridButtonWrapper.visible)
            {
                return;
            }

            const keyCode:uint = KEY_BUFFER[0];

            //자툴이 nowkey를 쓰기 때문에 nowkey 리턴 이전에서 체크해야함
            if(isPressingControlShift())
            {
                //shift 누르고 ctrl 순서로 누를때 이전툴로 복원
                if(isNowTool(TOOL_LINE)) setNowToolByOldTool();

                checkCommandSubKey(3,true,function(input:int):void
                {
                    if(input === KEY.s) saveFile(true);
                })
                return;
            }
            else if(isPressingControl())
            {
                if(checkCommandSubKey(2,true,function(input:int):void
                {
                    if(input === KEY.s) saveFile(false);
                    else if(input === KEY.o) loadFile();
                    else if(input === KEY.c || input === KEY.m)
                    {
                        setCaptureModeON();
                    }
                    else if(input === KEY.v || input === KEY.n)
                    {
                        if(isClipBoardButtonAvailable) setClipboardButton(false);
                    }
                }) === false)
                {
                    if(resizeCanvas.getInitON() === false)
                    {
                        setResizeButtonVisible(true);
                    }
                }

                return;
            }
            else if(isPressingShift())
            {
                if(checkOpaSizeKeyDown((KEY_BUFFER.length >= 2) ? KEY_BUFFER[1] : keyCode))
                {
                    return;
                }
                else if(checkMoreOptionsKeyDown(KEY_BUFFER[1]))
                {
                    return;
                }
                else
                {
                    const keyused:Boolean = checkCommandSubKey(2,true,function(input:int):void
                    {
                        switch(input)
                        {
                            case KEY.s:
                            case KEY.k:
                            {
                                if(regPoint.rotation !== 0.0) resetRotationDrawMode();
                            }
                            return;

                            case KEY.w:
                            case KEY.i:
                            {
                                if(zoomed !== 1.0) resetZoomDrawMode();
                            }
                            return;

                            case KEY.d:
                            case KEY.j:
                            {
                                setLayerSwapButton();
                                setHintONTemp(getLayerSwappedHint());
                            }
                            return;

                            case KEY.e:
                            case KEY.o:
                            {
                                if(controlBox.layerMergeButton.alpha === 1.0)
                                {
                                    setLayerMergeButton();
                                    setHintONTemp("Layers has been merged to layer 2");
                                }
                            }
                            return;

                            case KEY.f2:
                            case KEY.f8:
                            {
                                if(gridValue !== 0)
                                {
                                    resetGrid();
                                }
                            }
                            return;

                            case KEY.f5:
                            {
                                if(uiScaleIndex !== 0)
                                {
                                    resetUIScale();
                                }
                            }
                            return;
                        }
                    });

                    if(keyused)
                    {
                        return;
                    }
                }
            }

            if(KEY_BUFFER.length >= 2)
            {
                //지우개키 조합 따로 체크
                if(keyCode === KEY.d || keyCode === KEY.j)
                {
                    if(checkOpaSizeKeyDown(KEY_BUFFER[1]))
                    {
                        return;
                    }
                    else if(KEY_BUFFER[1] === KEY.s || KEY_BUFFER[1] === KEY.k)
                    {
                        if(quickSidebarON === false) setQuickSidebarON(true);
                        return;
                    }
                    else if(checkMoreOptionsKeyDown(KEY_BUFFER[1]))
                    {
                        return;
                    }

                }
                else if(keyCode === KEY.s || keyCode === KEY.k)
                {
                    if(KEY_BUFFER[1] === KEY.d || KEY_BUFFER[1] === KEY.j)
                    {
                        if(quickSidebarON === false) setQuickSidebarON(true);
                        return;
                    }
                }
                //필펜 조합 체크
                else if(keyCode === KEY.q || keyCode === KEY.o)
                {
                    // if(KEY_BUFFER[1] === KEY.w || KEY_BUFFER[1] === KEY.i)
                    // {
                    //     if(!isNowTool(TOOL_SCAN_FILL))
                    //     {
                    //         selectScanFillTool();
                    //         updatePenSizeCursor();
                    //     }
                    //     return;
                    // }
                    // else 
                    if(checkOpaSizeKeyDown(KEY_BUFFER[1]))
                    {
                        return;
                    }
                    else if(checkMoreOptionsKeyDown(KEY_BUFFER[1]))
                    {
                        return;
                    }
                }

                //레이어 따로 보기 조합 체크
                if(layerCheckKeyPressed === false)
                {
                    if(keyCode === KEY.w || keyCode === KEY.i)
                    {
                        if(KEY_BUFFER[1] === KEY.n1 || KEY_BUFFER[1] === KEY.n9)
                        {
                            layerCheckKeyPressed = true;

                            selectSubLayer(false,false);
                            setLayer1CheckToggle();

                            if(oldTool > TOOL_NONE) setNowToolByOldTool();
                            return;
                        }
                        else if(KEY_BUFFER[1] === KEY.n2 || KEY_BUFFER[1] === KEY.n0)
                        {
                            layerCheckKeyPressed = true;
                            selectSubLayer(true,false);
                            setLayer2CheckToggle();

                            if(oldTool > TOOL_NONE) setNowToolByOldTool();
                            return;
                        }
                    }
                    else if(keyCode === KEY.n1 || keyCode === KEY.n9)
                    {
                        if(KEY_BUFFER[1] === KEY.w || KEY_BUFFER[1] === KEY.i)
                        {
                            layerCheckKeyPressed = true;

                            selectSubLayer(false,false);
                            setLayer1CheckToggle();
                            return;
                        }
                    }
                    else if(keyCode === KEY.n2 || keyCode === KEY.n0)
                    {
                        if(KEY_BUFFER[1] === KEY.w || KEY_BUFFER[1] === KEY.i)
                        {
                            layerCheckKeyPressed = true;
                            selectSubLayer(true,false);
                            setLayer2CheckToggle();
                            return;
                        }
                    }
                }
            }

            if(isNowKey(keyCode)) return;
            setNowKey(keyCode);

            if(checkOpaSizeKeyDown(keyCode)) return;
            if(checkEtcKeyDown(keyCode)) return;
            checkToolKeyDown(keyCode);
        }

        private function checkEtcKeyDown(keyCode:int):Boolean
        {
            switch(keyCode)
            {
                case KEY.f1:
                case KEY.f7:
                {
                    setReplayModeON();
                }
                return true;

                case KEY.f2:
                case KEY.f8:
                {
                    gridButton.start(true);
                }
                return true;

                case KEY.f3:
                {
                    setSideBarPositionButton();
                }
                return true;

                case KEY.f4:
                {
                    setUIColorButton();
                    sethintOFFDelay();
                }
                return true;

                case KEY.f5:
                {
                    setUIScaleButton(++uiScaleIndex);
                    setHintONTemp("UI Scale "+getUIScaleString(uiScaleIndex));
                    sethintOFFDelay();
                }
                return true;

                case KEY.f6:
                {
                   if(canvasWindowON === false)
                   {
                        openImageViewWindow();
                   }
                   else if(canvasWindowON === true)
                   {
                        canvasWindow.visible = false;
                        canvasWindowON = false;
                        topBar.newWindowButton.alpha = 1.0;
                   }
                }
                return true;

                case KEY.n1:
                case KEY.n9:
                {
                    if(subLayerON)
                    {
                        selectSubLayer(false,false);
                    }
                    else
                    {
                        selectSubLayer(false,canvas11Bitmap.visible);
                    }

                    if(controlBox.layer2CheckButton.visible)
                    {
                        setLayer2CheckToggle();
                    }

                    setToolTipTempON("Layer 1 selected");
                }
                return true;

                case KEY.n2:
                case KEY.n0:
                {
                    if(!subLayerON)
                    {
                        selectSubLayer(true,false);
                    }
                    else
                    {
                        selectSubLayer(true,canvas1Bitmap.visible);
                    }
                    if(controlBox.layer1CheckButton.visible)
                    {
                        setLayer1CheckToggle();
                    }

                    setToolTipTempON("Layer 2 selected");
                }
                return true;

                case KEY.n3:
                case KEY.n8:
                {
                    if(controlBox.sharpLineButtonWrapper.alpha === 1.0)
                    {
                        setSharpLineButtonShortcut();
                    }
                }
                return true;

                case KEY.n4:
                case KEY.n7:
                {
                    if(isNowToolPenOrLine() || isNowTool(TOOL_FILL_PEN))
                    {
                        setPenAirBrushButtonShortCut();
                    }
                    else if(isNowTool(TOOL_ERASE))
                    {
                        setEraseAirBrushButtonShortCut();
                    }
                }
                case KEY.n6:
                {
                    setQuickSidebarON(true);
                }
                break;

                return true;

                case KEY.x:
                case KEY.comma:
                    setHoldKeyRepeat(true,redo);
                return true;

                case KEY.z:
                case KEY.dot:
                    setHoldKeyRepeat(true,undo);
                return true;

                case KEY.tab:
                case KEY.backslash:
                    setSidebarVisible(!isSidebarVisible,false);
                return true;
            }
            return false;
        }

        private function checkToolKeyDown(keyCode:int):void
        {
            if(traceMenuON)
            {
                if(keyCode === KEY.esc || keyCode === KEY.backspace)
                {
                    closeTraceMenu();
                    return;
                }
            }

            switch (keyCode)
            {
                case KEY.q:
                case KEY.o:
                {
                    setNowTool(TOOL_PEN); //q키가 올라가면 펜툴로 바꿔지게
                    updateOldTool();
                    selectFillPenTool();
                }
                break;

                case KEY.t:
                {
                    if(traceMenuON)
                    {
                        closeTraceMenu();
                    }
                    else
                    {
                        openTraceWindow();
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
                    if(pickerBox.scratchPad.hitTestPoint(stage.mouseX,stage.mouseY))
                    {
                        if(pickerBox.scratchPad.visible)
                        {
                            setPickColorScratchPad();
                        }
                    }
                    else if(!isNowTool(TOOL_SPUIT))
                    {
                        spuitTool();
                    }
                }
                break;

                case KEY.r:
                case KEY.y:
                {
                    if(!isNowTool(TOOL_LASSO))
                    {
                        updateOldTool();
                        selectLassoTool();
                    }
                }
                break;

                case KEY.space:
                {
                    if(!isNowTool(TOOL_HAND))
                    {
                        updateOldTool();
                        setNowTool(TOOL_HAND);
                    }
                }
                break;

                case KEY.d:
                case KEY.j:
                {
                    if(!isNowTool(TOOL_ERASE))
                    {
                        updateOldTool();
                        selectEraseTool();
                        updatePenSizeCursor();
                    }
                }
                break;

                case KEY.s:
                case KEY.k:
                {
                    if(!isNowTool(TOOL_ROTATE))
                    {
                        updateOldTool();
                        selectRotateTool();
                    }
                }
                break;

                case KEY.e:
                case KEY.u:
                {
                    if(!isNowTool(TOOL_MOVE))
                    {
                        updateOldTool();
                        selectMoveTool();
                    }
                }
                break;

                case KEY.w:
                case KEY.i:
                {
                    if(!isNowTool(TOOL_ZOOM))
                    {
                        updateOldTool();
                        selectZoomTool();
                    }
                }
                break;

                case KEY.shift:
                {
                    if(!isNowTool(TOOL_LINE))
                    {
                        updateOldTool();
                        selectLineTool();
                        updatePenSizeCursor();
                    }
                }
                break;

                case KEY.esc:
                case KEY.del:
                case KEY.backspace:
                {
                    if(topBar.clearButton.alpha === 1.0 && !isInSaveProgress)
                    {
                        setClearData(true);
                    }
                }
                break;
            }
            penCursorPosition.check();
        }

        private function setClickBlockFlagOFFDelay():void
        {
            addTimerByName("clickBlockTimer",0.15,false,function():void
            {
                clickBlockOnWindowActiveFlag = false;
            });
        }

        private function windowActiveEvent(e:Event):void
        {
            setIMEDisabled();
            realWorkingTimer.resume();
            checkClipBoardImage();

            if(aboutPanelON)
            {
                clickBlockOnWindowActiveFlag = true;
            }
            else
            {
                setClickBlockFlagOFFDelay();
            }
        }

        private function windowDeactiveEvent(e:Event):void
        {
            clickBlockOnWindowActiveFlag = true;
            resizeCanvas.exit(true);
            resetKeyBuffer();
            realWorkingTimer.setAFKMode();
            cancelAutoKeyEvent(null);
            removeTimer("longKeyTimer");

            if(toolBox2ON)
            {
                rightMouseClickON = false;
                closeToolBox2();
            }

            if(!isSidebarVisible) penCursorPosition.setSideBarOFF();

            if(topBarHintClickEventON)
            {
                topBarHintClickEventON = false;
                setTopBarHintOFF();
            }

            if(appResetFlag === false)
            {
                if(windowClosingFlag)
                {
                    const file:File = File.applicationStorageDirectory.resolvePath("tmp");
                    if(file.exists)
                    {
                        file.deleteDirectory(true);
                    }
                }

                if(windowClosingFlag
                ||
                ((getTimer()-windowDeactivateTime >= 10000
                && !isInSaveProgress && !fileBrowserON && !saveThenLoadFlag && !updateAfterSaveFlag && !loadMenuBox.visible)))
                {
                    windowDeactivateTime = getTimer();
                    saveAllData();
                }
            }

            if(quickSidebarON && !deepUndoON)
            {
                _quickSidebarOFF();
            }

            if(numPadBox.visible)
            {
                setNumPadOFF();
            }

            if(pickerBox.scratchPad.isScratchStarted)
            {
                pickerBox.scratchPad.removeCheckMouseDistEvent();
            }

            setNowToolByOldTool();
        }

        private function updateToolBoxMousePos(target:SimpleButton):void
        {
            //아이콘 중앙으로 맞추어줌
            if(!target) return;

            if(target.parent === toolBox2)
            {
                toolBox2.updateLastUsedToolPos(target.name);
            }
        }

        private function closeToolBox2():void
        {
            removeInputEventToolBox2();
            toolBox2ON = false;
            toolBox2.visible = false;
            setResizeButtonVisibleTimer(false);
        }

        //툴메뉴에서 클릭했을때
        private function setToolBox2ClickTool(target:SimpleButton,func:Function,...args):void
        {
            updateToolBoxMousePos(target);
            closeToolBox2();
            const len:int = args.length;
            if(len === 0) func();
            else if(len === 1) func(args[0]);
            else if(len === 2) func(args[0],args[1]);
        }

        private function mouseDownToolBox2(e:MouseEvent):void
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
                    setToolBox2ClickTool(target as SimpleButton,zoomTool);
                break;

                case "toolMove":
                    setToolBox2ClickTool(target as SimpleButton,moveTool);
                break;

                case "toolRotate":
                    setToolBox2ClickTool(target as SimpleButton,rotateTool);
                break;

                case "resizeButtonR":
                case "resizeButtonD":
                case "resizeButtonL":
                case "resizeButtonU":
                    setCanvasResizeButton(targetName);
                break;

                default:
                {
                    if(toolBox2.visible && toolBox2.hitTestPoint(mouseX,mouseY))
                    {
                        updateToolBoxMousePos(toolBox2.toolPen);
                        updateOldTool();
                        handTool(false,false);
                    }
                    closeToolBox2();
                }
                break;
            }
        }
        //툴메뉴 오른쪽 클릭 땠을때
        private function rightMouseUpToolBox2(e:MouseEvent):void
        {
            penCursorOFFFlag = false;

            if(lassoToolON === true)
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
                case "toolSidebar":
                {
                    setQuickSidebarON(false);
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

                // case "toolScanFill":
                // {
                //     selectScanFillTool();
                //     updatePenSizeCursor();
                // }
                // break;

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

                case "toolSpuit":
                {
                    if(!isNowTool(TOOL_SPUIT))
                    {
                        spuitTool();
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

                case "toolTrace":
                {
                    openTraceWindow();
                }
                break;
            }

            closeToolBox2();
        }

        private function setLasso1PxMoveButton(command:int):void
        {
            var posX:Number = 0;
            var posY:Number = 0;

            if(command === LASSO_1PX_MOVE_UP) posY = -1;
            else if(command === LASSO_1PX_MOVE_DOWN) posY = 1;
            else if(command === LASSO_1PX_MOVE_LEFT) posX = -1;
            else if(command === LASSO_1PX_MOVE_RIGHT) posX = 1;

            const rotatedPoint:Point = rotatePoint(posX,posY,regPoint.rotation);

            lassoBox1.x += rotatedPoint.x;
            lassoBox1.y += rotatedPoint.y;
            lassoBox2.x = lassoBox1.x;
            lassoBox2.y = lassoBox1.y;
        }

        // private function _setScrollBarMove(inputSubY:Number):void
        // {
        //     const scale:Number= getUIScale();
        //     const subY:Number = inputSubY/scale;
        //     const yLimit:Number = Math.ceil(sideBar.HEIGHT-sideBarScrollBar.height-STAGE_BOTTOM_OFFSET/scale);
        //     const diffHeight:Number = getSidebarConstHeight()*scale-(stage.stageHeight-STAGE_TOP_OFFSET-STAGE_BOTTOM_OFFSET);
        //     const canMoveHeight:Number = getSidebarConstHeight()*scale-(stage.stageHeight-STAGE_TOP_OFFSET-STAGE_BOTTOM_OFFSET);
        //     const factor:Number = (diffHeight/canMoveHeight);

        //     var my1:Number = sideBarScrollBar.y-subY;
        //     var my2:Number = sideBarScrollSet.y+subY*factor;

        //     if(my1 < 0)
        //     {
        //         my1 = 0;
        //         my2 = 0;
        //     }
        //     else if(my1 > yLimit)
        //     {
        //         my1 = yLimit;
        //         my2 = -diffHeight/scale;
        //     }

        //     sideBarScrollBar.y = Math.floor(my1);
        //     sideBarScrollSet.y = Math.floor(my2);
        // }

        // private function setScrollBarMoveButton(deltaY:Number=0.0):void
        // {
        //     const scale:Number = getUIScale();
        //     const sth:Number = stage.stageHeight;
        //     const canMoveHeight:Number = (sth-STAGE_TOP_OFFSET-STAGE_BOTTOM_OFFSET)-scrollBarHeight*scale;
        //     const diffHeight:Number = getSidebarConstHeight()*scale-(sth-STAGE_TOP_OFFSET-STAGE_BOTTOM_OFFSET);
        //     const factor:Number = (diffHeight/canMoveHeight);
        //     var scrollStarted:Boolean = false;
        //     var my1:Number = sideBarScrollBar.y;
        //     var my2:Number = sideBarScrollSet.y;
        //     var clickY:Number = mouseY;
        //     const yLimit:Number = Math.ceil(sideBar.HEIGHT-sideBarScrollBar.height-STAGE_BOTTOM_OFFSET/scale);

        //     if(deltaY === 0.0) mouseDragON = true;
        //     hint.off();

        //     function sideBarMouseUpEvent(e:MouseEvent):void
        //     {
        //         mouseDragON = false;
        //         scrollSetMovedY = sideBarScrollSet.y;
        //         scrollBarMovedY = sideBarScrollBar.y;

        //         stage.removeEventListener(MouseEvent.MOUSE_MOVE,sideBarMouseMoveEvent);
        //         stage.removeEventListener(MouseEvent.MOUSE_UP,sideBarMouseUpEvent);
        //     }

        //     function _moveScroll(subY:Number):void
        //     {
        //         my1 = my1-subY;
        //         my2 = my2+subY*factor;

        //         if(my1 < 0)
        //         {
        //             my1 = 0;
        //             my2 = 0;
        //         }
        //         else if(my1 > yLimit)
        //         {
        //             my1 = yLimit;
        //             my2 = -diffHeight/scale;
        //         }

        //         sideBarScrollBar.y = Math.floor(my1);
        //         sideBarScrollSet.y = Math.floor(my2);
        //     }

        //     function sideBarMouseMoveEvent(e:MouseEvent):void
        //     {
        //         const subY:Number = (clickY-mouseY)/scale;

        //         _moveScroll(subY);

        //         clickY = mouseY;
        //     }

        //     if(deltaY === 0.0)
        //     {
        //         stage.addEventListener(MouseEvent.MOUSE_MOVE, sideBarMouseMoveEvent);
        //         stage.addEventListener(MouseEvent.MOUSE_UP,sideBarMouseUpEvent);
        //     }
        //     else
        //     {
        //         _moveScroll(deltaY);
        //     }
        // }
        private function checkScrollSetOutStage():void
        {
            const scale:Number = getUIScale();
            const limitTop:Number = Math.floor(-sideBarConstHeight+20.0);
            const limitBottom:Number = Math.floor(stage.stageHeight-STAGE_TOP_OFFSET-STAGE_BOTTOM_OFFSET-20.0*scale);

            if(sideBarScrollSet.y < limitTop)
            {
                sideBarScrollSet.y = limitTop;//*scale;
            }
            else if(sideBarScrollSet.y*scale > limitBottom)
            {
                sideBarScrollSet.y = limitBottom/scale;
            }

            scrollSetMovedY = sideBarScrollSet.y;
        }

        private function resetSideBarPosition():void
        {
            sideBarScrollSet.y = 0;
            scrollSetMovedY = sideBarScrollSet.y;
            checkFOFOPosition();
        }

        private function setScrollBarMoveButton(deltaY:Number=0.0):void
        {
            const scale:Number = getUIScale();
            var clickY:Number = mouseY;
            
            deltaY = Math.floor(deltaY*scale);

            if(deltaY === 0.0) mouseDragON = true;
            hint.off();

            function sideBarMouseUpEvent(e:MouseEvent):void
            {
                checkScrollSetOutStage();
                mouseDragON = false;
                scrollSetMovedY = sideBarScrollSet.y;

                stage.removeEventListener(MouseEvent.MOUSE_MOVE,sideBarMouseMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,sideBarMouseUpEvent);
                checkFOFOPosition();
            }

            function _moveScroll(subY:Number):void
            {
                sideBarScrollSet.y += subY*1.5;
                scrollSetMovedY = sideBarScrollSet.y;
            }

            function sideBarMouseMoveEvent(e:MouseEvent):void
            {
                const subY:Number = (clickY-mouseY)/scale;
                _moveScroll(subY);
                clickY = mouseY;
            }

            if(deltaY === 0.0)
            {
                stage.addEventListener(MouseEvent.MOUSE_MOVE, sideBarMouseMoveEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,sideBarMouseUpEvent);
            }
            else
            {
                _moveScroll(deltaY);
                checkFOFOPosition();
            }
        }

        private function checkToolBoxButtons(target:DisplayObject):Boolean
        {
            if(!isNowKey(0) && !quickSidebarON || !target) return true;

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
                    setHoldKeyRepeat(false,undo);
                    checkToolBoxMouseUp(targetName);
                }
                return true;

                case "toolRedo":
                {
                    setHoldKeyRepeat(false,redo);
                    checkToolBoxMouseUp(targetName);
                }
                return true;

                case "zoomInButton":
                case "zoomOutButton":
                case "toolPen":
                case "toolFillPen":
                case "toolScanFill":
                case "toolErase":
                case "toolLasso":
                case "toolSpuit":
                case "toolUndo":
                case "toolRedo":
                case "toolMirror":
                case "toolLine":
                case "toolMove":
                case "toolRotate":
                case "toolTrace":
                case "toolBoxBG":
                case "toolMask":
                {
                    // setTopChildIndex(toolBox);
                    checkToolBoxMouseUp(targetName);
                }
                return true;
            }
            return false;
        }

        private function setCanvasResizeButton(targetName:String):void
        {
            penCursorOFFFlag = true;
            setToolTipON();
            penSizeCursor.visible = false;
            setToolTipString(CANVAS_WIDTH+" x "+CANVAS_HEIGHT);
            resizeCanvas.start(targetName);
        }

        private function checkReplaySpeedState():void
        {
            const totalFrame:Number = TOTAL_FRAME;
            const rf:Number = rNowFrame;
            const bw:Number = replayTimeBox["replayTotalBar"].width;

            if(totalFrame < stage.frameRate*3) topBar["replaySpeedSliderWrapper"].alpha = BUTTON_OFF_ALPHA;
            else topBar["replaySpeedSliderWrapper"].alpha = 1.0;
            //리플레이 속도를 최고 빠르게 했을때 시간 체크
            REPLAY_FASTEST_TOTAL_TIME = Math.floor(totalFrame/(REPLAY_MAX_SPEED*stage.frameRate));

            replayTimeBox["frameInfo"].text = rf+" / "+totalFrame;
            replayTimeBox["replayNowBar"].width = (totalFrame === 0) ? 0 : bw*(rf/totalFrame);
        }

        private function resetKeyBuffer():void
        {
            KEY_BUFFER.length = 0;
            resetNowKey();
        }

        private function updateRCursorScale(zoom:Number):void
        {
            const z:Number = getUIScale()/zoom;
            rCursor.scaleX = z;
            rCursor.scaleY = z;
        }

        private function setDeepUndoOFFForce():void
        {
            setDeepUndoOFF();
        }

        private function setDeepUndoOFF():void
        {
            deepUndoON = false;
            deepUndoONSave = false;
            rDataReadFlag = true;
            setRCursorVisibleONUndo(-1);
            clearRFrameCacheImages();
        }

        private function setDeepUndoON():void
        {
            deepUndoON = true;
            rDataReadFlag = false;

            if(makeJumpImageFlag === 1)
            {
                removeInputEventDrawMode();
                setTopChildIndex(replayTimeBox);
                updateReplayBarPos(stage.stageWidth);
                setHintONTemp(STRING_PREPARE_REPLAY_DATA);
                setMakeJumpImage();
            }
            else
            {
                TOTAL_FRAME = getTotalFrame();
                //이미지 캐시 해주고 rPrevFrame 갱신해주고
                jumpFrame(undoData.getRFileTotalFrame()-1,JUMP_FRAME_ONCE);
                //실제 rPrevFrame으로 점프
                jumpFrame(rPrevFrame,JUMP_FRAME_ONCE);
                drawReplayImageToDrawModeCanvas();
                rOnejumpFlagSave = true;
            }
        }

        private function setMakeJumpImage():void
        {
            makeJumpImageFlag = 2;

            if(!hasTimer("makeJumpImageWaitTimer"))
            {
                addTimerByName("makeJumpImageWaitTimer",0.1,false,function():void
                {
                    makeJumpImage();
                });
            }
        }

        private function syncDrawCanvasWithReplayMode():void
        {
            zoomed = rzoomed;//줌배율도 공유
            zoomedIndex = rzoomedIndex;
            regPoint.scaleX = rregPoint.scaleX;
            regPoint.scaleY = rregPoint.scaleY;
            regPoint.rotation = rregPoint.rotation;
            regPoint.x = rregPoint.x;
            regPoint.y = rregPoint.y;
            rcanvasPanel.x = rcanvasPanel.x;
            rcanvasPanel.y = rcanvasPanel.y;
            setRcursorRotation(regPoint.rotation);
        }

        private function syncReplayCanvasWithDrawMode():void
        {
            rzoomed = zoomed;//줌배율도 공유
            rzoomedIndex = zoomedIndex;
            rregPoint.scaleX = regPoint.scaleX;
            rregPoint.scaleY = regPoint.scaleY;
            rregPoint.rotation = regPoint.rotation;
            rregPoint.x = regPoint.x;
            rregPoint.y = regPoint.y;
            rcanvasPanel.x = canvasPanel.x;
            rcanvasPanel.y = canvasPanel.y;
            setRcursorRotation(rregPoint.rotation);
        }

        private function setSameReplayModeImageByDrawMode():void
        {
            rcanvas2Draw.graphics.clear();

            if(rcanvas1BitmapData && canvas1BitmapData !== rcanvas1BitmapData) rcanvas1BitmapData.dispose();
            rcanvas1BitmapData = canvas1BitmapData.clone();
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;

            if(rcanvas11BitmapData && canvas11BitmapData !== rcanvas11BitmapData) rcanvas11BitmapData.dispose();
            rcanvas11BitmapData = canvas11BitmapData.clone();
            rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;

            changeCanvasSizeReplayMode(canvas1Bitmap.width,canvas1Bitmap.height);
            setBackgroundColorReplayMode(CANVAS_BG_COLOR);
        }

        private function updateNowTimeBarByDrawMode():void
        {
            const totalFrame:Number = TOTAL_FRAME;

            replayTimeBox["frameInfo"].text = rNowFrame+" / " + totalFrame;
            replayTimeBox["replayNowBar"].width = (totalFrame === 0) ? 0 : replayTimeBox["replayTotalBar"].width*(rNowFrame/totalFrame);
            // setColorTransform(replayTimeBox["replayNowBar"],uiColorSet[uiColorIndex][4]);
        }

        private function setReplayModeOFF():void
        {
            if(makeJumpImageFlag === 2)
            {
                return;
            }

            removeInputEventReplayMode();
            replayModeON = false;
            penCursorOFFFlag = false;
            rregPoint.visible = false;
            rCursor.visible = false;
            replayTimeBox.visible = false;
            regPoint.visible = true;
            penSizeCursor.visible = true;
            if(traceMenuON === true) traceMenu.visible = true;
            if(isSidebarVisible === true) setSidebarVisible(true,true);
            canvasPanel.addChild(rCursor);
            setRcursorRotation(regPoint.rotation);
            if(toolTipBox.visible) toolTipBoxTimerOFF();
            replayTimeBox["pauseButton"].visible = false;
            setTopChildIndex(replayTimeBox);
            setReplayDeleteBarVisibleOFF();
            setTopBarHintOFF();
            setFitZoomedOFF();
            updateStageOffset();

            if(replayStartON === true) stopReplay();

            updatePreviewBoxRectPos();
            if(penColorTransparentFlag) selectTransparentColor();
            else changePickerModeToPenColor();
            updatePenSizeCursor();
            penCursorPosition.check();
            changeTopBarIcons("draw");
            appInfoBox.setZoom(zoomed);
            updateRCursorScale(zoomed);

            deepUndoON = deepUndoONSave;
            if(rNowFrame !== deepUndoFrameSave)
            {
                 //after로 해주는 이유는 캐쉬 안만들어줄라고
                jumpFrame(deepUndoFrameSave,JUMP_FRAME_AFTER);
            }
            clearRFrameCacheImages();
            rCursor.visible = false;
            addInputEventDrawMode();
        }

        private function setReplayModeON():void
        {
            if(makeJumpImageFlag === 2)
            {
                return;
            }

            removeInputEventDrawMode();
            replayModeON = true;
            penCursorOFFFlag = true;
            regPoint.visible = false;
            rregPoint.visible = true;
            replayTimeBox.visible = true;
            penSizeCursor.visible = false;
            replayTimeBox["pauseButton"].visible = false;
            replayTimeBox.y = Math.floor(topBar.BARSIZE*getUIScale()-4);
            setTopChildIndex(replayTimeBox);
            setReplayDeleteBarVisibleOFF();
            setTopBarHintOFF();
            if(numPadBox.visible) setNumPadOFF();
            if(toolTipBox.visible) toolTipBoxTimerOFF();
            rCursor.alpha = 1.0;
            rCursor.visible = false;
            rcanvasPanel.addChild(rCursor);
            setTopChildIndex(rCursor);
            setRcursorRotation(rregPoint.rotation);
            updateStageOffset();
            removeTimer("rCursorOffAlphaAnimTimer");

            deepUndoONSave = deepUndoON;
            if(deepUndoON) deepUndoON = false;
            deepUndoFrameSave = rNowFrame;

            TOTAL_FRAME = getTotalFrame();

            checkReplaySpeedState();

            //frame sum이 재계산된 maxframe을 넘어가면 리플레이 프레임이 넘어가기 때문에 끝난거임
            //그래서 캔버스 복사해주고 리플레이를 리셋해줌
            if(makeJumpImageFlag === 0)
            {
                if(CANVAS_WIDTH === RCANVAS_WIDTH && CANVAS_HEIGHT === RCANVAS_HEIGHT)
                {
                    syncReplayCanvasWithDrawMode();
                }
                else
                {
                    fitCanvasToWindow();
                    rzoomed = 1;
                    rregPoint.scaleX = 1;
                    rregPoint.scaleY = 1;
                    rzoomedIndex = zoomList.indexOf(rzoomed);
                }
            }

            updateReplayBarPos(stage.stageWidth);
            autoScroll.updateRCanvasBounds();
            updateRCursorScale(rzoomed);

            if(traceMenuON === true)
            {
                traceMenu.visible = false;
            }

            if(makeJumpImageFlag === 1)
            {
                removeInputEventReplayMode();
                replayTimeBox["frameInfo"].text = STRING_PREPARE_REPLAY_DATA;
                setSidebarVisible(false,true);
                changeTopBarIcons("replay");
                setMakeJumpImage();
            }
            else if(makeJumpImageFlag === 0)
            {
                rDataReadFlag = false;
                updateNowTimeBarByDrawMode();
                setSameReplayModeImageByDrawMode();

                //이거 안해주고 리플레이틀고 프레임 조작 안하고 재생하면 중간부터 되서 데이터가 꼬임
                playbackFinished = true;

                if(undoIndex >= 0)
                {
                    rIndexStart = undoIndex+1;
                    rDataReadFlag = true;
                }
                else
                {
                    rIndexStart = 0;
                    rDataReadFlag = false;
                }

                checkCutFrameButtonsCanUse();
                doDrawSlowEventON = false;
                checkCanvasPanelPos(true);
                setSidebarVisible(false,true);
                changeTopBarIcons("replay");
                addInputEventReplayMode();
            }
        }

        private function mouseDownReplayMode(e:MouseEvent):void //repdown1
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target || loadMenuBox.visible) return;

            const targetName:String = target.name;

            if(targetName)
            {
                if(targetName.indexOf("rcanvas") !== -1 || targetName === "stageBG")
                {
                    handTool(true,false);
                    return;
                }
                else if(targetName === "replayRepeatButton")
                {
                    if(!isNowKey(0))
                    {
                        return;
                    }

                    checkButtonUp(targetName);
                    return;
                }
            }

            if(target.alpha < 1.0)
            {
                return;
            }

            switch(targetName)
            {
                case "reRecordingButton":
                {
                    setCountDownLongKey(topBar.reRecordingButton,"Creating new file from this image.. ",setDeleteBarReRecord,setReRecord,setReplayDeleteBarVisibleOFF);
                }
                break;

                case "cutPrevDataButton":
                {
                    if(topBar.cutPrevDataButton.alpha === 1.0)
                    {
                        setCountDownLongKey(topBar.cutPrevDataButton,"Deleting front data.. ",setDeleteBarDeleteFrontData,deleteReplayFrontData,setReplayDeleteBarVisibleOFF);
                    }
                }
                break;

                case "superUndoButton":
                {
                    if(topBar.superUndoButton.alpha === 1.0)
                    {
                        setCountDownLongKey(topBar.superUndoButton,"Deleting back data.. ",setDeleteBarSuperUndo,superUndo,setReplayDeleteBarVisibleOFF);
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
                    setReplaySpeedButton();
                }
                break;

                case "replayTotalBar":
                {
                    setJumpFrameButton();
                }
                break;

                case "replayPrev":
                {
                    setJumpOneFrame(true,isPressingControlShift());
                }
                break;

                case "replayNext":
                {
                    setJumpOneFrame(false,isPressingControlShift());
                }
                break;

                case "timer":
                {
                    setCountDownLongKey(topBar.timer,"Resetting the timer... ",null, realWorkingTimer.reset,null);
                }
                break;

                case "drawModeButton":
                case "repLoadButton":
                case "saveButton":
                case "repSaveButton":
                case "captureButton":
                case "capOff":
                case "capFull":
                case "capClipBoard":
                case "capTrans":
                case "capFlip":
                case "capRotate":
                case "repCaptureButton":
                case "clipButton":
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
                    if(!isNowKey(0))
                    {
                        return;
                    }
                    checkButtonUp(targetName);
                }
                break;
            }
        }

        //키를 2개 이상 누르고 있을때 먼저 누른키를 떼면 다음키로 설정함
        private function mouseUpDrawMode(e:MouseEvent):void //mouseup1
        {
            if(keyWaitMouseUp)//단축키 떼고 마우스 땠을때 원래대로 돌림
            {
                keyWaitMouseUp = false;

                if(KEY_BUFFER.length > 0)
                {
                    keyDownDrawMode(null);
                }
                else
                {
                    resetNowKey();
                    if(oldTool > TOOL_NONE) setNowToolByOldTool();
                    penCursorPosition.check();
                }
            }
        }

        private function setFitZoomedOFF():void
        {
            rFitZoomedON = false;
        }

        private function setReplayFitToWindowButton():void
        {
            rFitZoomedON = true;
            fitCanvasToWindowManualReplayMode();
        }

        private function fitCanvasToWindowManualReplayMode():void
        {
            addTimerByName("rFitZoomedDelayTimer",0.15,false,function():void
            {
                fitCanvasToWindow(false,true);
                rzoomedIndex = getNearZoomIndex(rzoomed);
                rzoomed = zoomList[rzoomedIndex];
            });
        }

        private function rightMouseDownReplayMode(e:MouseEvent):void
        {
            if(mouseClickON || !isNowKey(0) || !e.target || loadMenuBox.visible) return;

            const targetName:String = e.target.name;

            if(targetName.indexOf("canvas") !== -1 || targetName === "stageBG")
            {
                if(rFitZoomedON) resetZoomReplayMode();
                else setReplayFitToWindowButton();
                return;
            }

            switch(targetName)
            {
                case "repSaveButton": saveFile(true); break;
                case "replayPrev": setJumpOneFrame(true,true); break;
                case "replayNext": setJumpOneFrame(false,true); break;
                case "replayRotateButton" : resetRotationReplayMode(); break;

                case "replayZoomInButton" :
                case "replayZoomOutButton" : resetZoomReplayMode(); break;
            }
        }

        private function openToolBox2():void
        {
            penCursorOFFFlag = true;
            penSizeCursor.visible = false;

            var pos:Point = toolBox2.getLastUsedToolPos();
            const scale:Number = getUIScale();

            if(pos.x === 0 && pos.y === y)
            {
                toolBox2.updateLastUsedToolPos("toolPen");
                pos = toolBox2.getLastUsedToolPos();
            }

            toolBox2.x = Math.floor(mouseX-pos.x*scale);
            toolBox2.y = Math.floor(mouseY-pos.y*scale);
            toolBox2.visible = true;
            toolBox2ON = true;
            setResizeButtonVisibleTimer(true);
            setTopChildIndex(toolBox2);
            addInputEventToolBox2();
        }

        private function rightMouseDownDrawMode(e:MouseEvent):void //rdown1
        {
            if(mouseClickON || isPressingControl() || quickSidebarON
            || fillPenStarted || isNowTool(TOOL_SPUIT) || (traceMenuON && traceMenu.hitTestPoint(mouseX,mouseY))
            || loadMenuBox.visible || topBar.gridButtonWrapper.visible || numPadBox.visible)
            {
                return;
            }

            if(isNowKey(KEY.n1) || isNowKey(KEY.n9))
            {
                selectSubLayer(false,canvas11Bitmap.visible);
                if(controlBox.layer2CheckButton.visible)
                {
                    setLayer2CheckToggle();
                }
                return;
            }
            else if(isNowKey(KEY.n2) || isNowKey(KEY.n0))
            {
                selectSubLayer(true,canvas1Bitmap.visible);
                if(controlBox.layer1CheckButton.visible)
                {
                    setLayer1CheckToggle();
                }
                return;
            }
            else if(!isNowKey(0))
            {
                return;
            }

            const targetName:String = e.target.name;
            switch(targetName)
            {
                case "saveButton":
                {
                    saveFile(true);
                }
                break;

                case "dpiButton":
                {
                    if(uiScaleIndex !== 0)
                    {
                        resetUIScale();
                    }
                }
                break;

                case "rgbInfo":
                {
                    rgbInfoRightClickFocusIgnoreFlag = true;
                }
                break;

                case "zoomInButton":
                case "zoomOutButton":
                {
                    if(zoomed !== 1.0) resetZoomDrawMode();
                }
                break;

                case "gridButton":
                {
                    if(gridValue !== 0)
                    {
                        hint.off();
                        resetGrid();
                    }
                }
                break;

                case "toolRotate":
                {
                    if(regPoint.rotation !== 0.0)
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
                    if(!isSidebarVisible && sideBar.visible)
                    {
                        penCursorPosition.setSideBarOFF();
                        penCursorPosition.setSidebarONDelay();
                    }
                    else if(isCursorInDrawArea())
                    {
                        if(toolBox2ON && !deepUndoON) closeToolBox2();
                        else openToolBox2();
                    }
                }
                break;
            }
        }

        private function checkControlBoxButtons(target:DisplayObject):Boolean
        {
            if(toolBox2ON)
            {
                return true;
            }

            const targetName:String = target.name;

            switch(targetName)
            {
                case "penSmoothSliderWapper":
                {
                    if(nowTool > 4) return true;
                    setPenSmoothButton();
                    setNowToolForDrawing(true);
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
                    setOpaButton(targetName);
                    setNowToolForDrawing(true);
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
                    setPenSizeButton(targetName);
                    setNowToolForDrawing(true);
                }
                return true;

                case "shapeRect":
                {
                    setPenShapeButton(true);
                    setNowToolForDrawing(true);
                }
                return true;

                case "shapeCircle":
                {
                    setPenShapeButton(false);
                    setNowToolForDrawing(true);
                }
                return true;


                case "layer1CheckButton":
                case "layer1UncheckButton":
                {
                    selectSubLayer(false,false);
                    setLayer1CheckToggle();
                }
                return true;

                case "layer2CheckButton":
                case "layer2UncheckButton":
                {
                    selectSubLayer(true,false);
                    setLayer2CheckToggle();
                }
                return true;

                case "layer1SelectButton":
                {
                    if(subLayerON)
                    {
                        selectSubLayer(false,false);
                    }
                    else
                    {
                        selectSubLayer(false,canvas11Bitmap.visible);
                    }

                    if(controlBox.layer2CheckButton.visible)
                    {
                        setLayer2CheckToggle();
                    }
                }
                return true;

                case "layer2SelectButton":
                {
                    if(!subLayerON)
                    {
                        selectSubLayer(true,false);
                    }
                    else
                    {
                        selectSubLayer(true,canvas1Bitmap.visible);
                    }

                    if(controlBox.layer1CheckButton.visible)
                    {
                        setLayer1CheckToggle();
                    }
                }
                return true;

                case "layerMergeButton":
                case "layerSwapButton":
                {
                    if(toolBox2ON || target.alpha < 1.0)
                    {
                        return true;
                    }
                    checkButtonUp(targetName);
                }
                return true;

                case "sharpLineButtonWrapper":
                case "sharpLineOFFButton":
                case "sharpLineONButton":
                case "sharpLineText":
                {
                    if(controlBox.sharpLineButtonWrapper.alpha === 1.0)
                    {
                        setNowToolForDrawing(true);
                        setSharpLineButton(!sharpLineON);
                    }
                }
                return true;

                case "airBrushButtonWrapper":
                case "airBrushOFFButton":
                case "airBrushONButton":
                case "airBrushText":
                {
                    if(controlBox.airBrushButtonWrapper.alpha === 1.0)
                    {
                        setNowToolForDrawing(true);
                        if(isNowToolPenOrLine() || isNowTool(TOOL_FILL_PEN))
                        {
                            setPenAirBrushButton(!airBrushON);
                        }
                        else if(isNowTool(TOOL_ERASE))
                        {
                            setEraseAirBrushButton(!eraseAirBrushON);
                        }
                    }
                }
                return true;
            }

            return false;
        }

        private function myPaletteDragMouseUpEvent(e:MouseEvent):void
        {
            mouseDragON = false;

            if(myPaletteDragStarted === true)
            {
                myPaletteDragStarted = false;

                const putIndex:int = getMyPaletteIndexByMousePosLimitBound();
                const colorSave:* = myPalettePreset[putIndex];

                myPalettePreset[putIndex] = myPaletteDragClickedColor;
                myPalettePreset[myPaletteDragClickedIndex] = (colorSave === null || colorSave === undefined) ? null:colorSave;

                updateMyPaletteList();
            }

            pickerBox.removeColorHistoryDragBox();
            stage.removeEventListener(MouseEvent.MOUSE_UP,myPaletteDragMouseUpEvent);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE,myPaletteDragMouseMoveEvent);
        }

        private function myPaletteDragMouseMoveEvent(e:MouseEvent):void
        {
            if(Point.distance(myPaletteClickPos,myPaletteMovePos) >= 4)
            {
                if(myPaletteDragStarted === false)
                {
                    removeTimer("addColorMyPaletteDelayTimer");
                    myPaletteDragStarted = true;
                    pickerBox.setColorDragBoxColor(myPaletteDragClickedColor,myPaletteColorWidth,myPaletteColorHeight);
                    updateMyPaletteList(myPaletteDragClickedIndex);
                }

                pickerBox.setColorHistoryDragBoxPos();

            }
            else
            {
                myPaletteMovePos.setTo(pickerBox.mouseX,pickerBox.mouseY);
            }
        }

        private function historyDragMouseUpEvent(e:MouseEvent):void
        {
            mouseDragON = false;

            if(myPaletteDragStarted === true)
            {
                myPaletteDragStarted = false;

                if(pickerBox.myPaletteBox.hitTestPoint(mouseX,mouseY))
                {
                    const putIndex:int = getMyPaletteIndexByMousePosLimitBound();
                    const colorSave:* = myPalettePreset[putIndex];

                    myPalettePreset[putIndex] = myPaletteDragClickedColor;
                    myPalettePreset[myPaletteDragClickedIndex] = (colorSave === null || colorSave === undefined) ? null:colorSave;

                    updateMyPaletteList(myPaletteDragClickedIndex);
                }
            }

            updateHistoryList();
            pickerBox.removeColorHistoryDragBox();
            stage.removeEventListener(MouseEvent.MOUSE_UP,historyDragMouseUpEvent);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE,historyColorDragMouseMoveEvent);
        }

        private function historyColorDragMouseMoveEvent(e:MouseEvent):void
        {
            if(Point.distance(myPaletteClickPos,myPaletteMovePos) >= 4)
            {
                if(myPaletteDragStarted === false)
                {
                    myPaletteDragStarted = true;
                    pickerBox.setColorDragBoxColor(myPaletteDragClickedColor,myPaletteColorWidth,myPaletteColorHeight);
                    updateMyPaletteList(myPaletteDragClickedIndex);
                    updateHistoryList(myPaletteDragClickedIndex);
                }

                pickerBox.setColorHistoryDragBoxPos();
            }
            else
            {
                myPaletteMovePos.setTo(pickerBox.mouseX,pickerBox.mouseY);
            }
        }

        private function checkButtonUpColorPickerBox(targetName:String):void
        {
            function buttonUpColorPickerBoxEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, buttonUpColorPickerBoxEvent);

                const upTargetName:String = e.target.name;

                if(targetName === upTargetName)
                {
                    switch(upTargetName)
                    {
                        case "currentColor":
                        {
                            setCurrentColor(pickerMode);
                            setNowToolForDrawing(false);
                        }
                        break;

                        case "penColorButton":
                        {
                            if(pickerMode !== 1)
                            {
                                changePickerModeToPenColor();
                            }
                        }
                        break;

                        case "paperColorButton":
                        {
                            if(pickerMode !== 2)
                            {
                                changePickerModeToPaperColor();
                            }
                        }
                        break;

                        case "historyBox":
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
                            if(pickerBox.transColorButton.alpha === 1.0)
                            {
                                selectTransparentColor();
                                setNowToolForDrawing(false);
                            }
                        }
                        break;

                        case "swapPositionButton":
                        {
                            pickerBoxSwapPositionFlag = !pickerBoxSwapPositionFlag;
                            pickerBox.swapColorBoxPosition(pickerBoxSwapPositionFlag);
                        }
                        break;

                        case "drawrPresetButton":
                        {
                            removeTimer("clearScratchPadTimer");
                            changeMyPalettePreset(1);
                        }
                        break;

                        case "tegakiPresetButton":
                        {
                            removeTimer("clearScratchPadTimer");
                            changeMyPalettePreset(2);
                        }
                        break;
                    }
                }
            }
            stage.addEventListener(MouseEvent.MOUSE_UP,buttonUpColorPickerBoxEvent);
        }

        private function checkPickerBoxButtons(target:DisplayObject):Boolean
        {
            if(toolBox2ON || (!isNowKey(0)
                             && !isNowToolPenOrLine()
                             && !isNowTool(TOOL_ERASE)
                             && !isNowTool(TOOL_FILL_PEN)))
            {
                return false;
            }

            const targetName:String = target.name;
            var index:int;

            if(targetName === "myPaletteBox")
            {
                if(myPalettePresetType === 0)
                {
                    index = getMyPaletteIndexByMousePos();
                    myPaletteDragClickedIndex = index;
                    if(index >= 0 && !isSelctedColorEmpty(index))
                    {
                        mouseDragON = true;
                        myPaletteDragClickedColor = myPalettePreset[index];
                        myPaletteClickPos.setTo(pickerBox.mouseX,pickerBox.mouseY);
                        myPaletteMovePos.setTo(pickerBox.mouseX,pickerBox.mouseY);
                        stage.addEventListener(MouseEvent.MOUSE_UP,myPaletteDragMouseUpEvent,false,-1);
                        stage.addEventListener(MouseEvent.MOUSE_MOVE,myPaletteDragMouseMoveEvent);
                    }
                }
            }
            else if(targetName === "historyBox")
            {
                if(myPalettePresetType === 0)
                {
                    index = getHistoryIndexByMousePos();
                    myPaletteDragClickedIndex = index+90;

                    if(index >= 0 && !isSelctedHistoryColorEmpty(index))
                    {
                        mouseDragON = true;
                        myPaletteDragClickedColor = myPalettePreset[index+90];
                        myPaletteClickPos.setTo(pickerBox.mouseX,pickerBox.mouseY);
                        myPaletteMovePos.setTo(pickerBox.mouseX,pickerBox.mouseY);
                        stage.addEventListener(MouseEvent.MOUSE_UP,historyDragMouseUpEvent,false,-1);
                        stage.addEventListener(MouseEvent.MOUSE_MOVE,historyColorDragMouseMoveEvent);
                    }
                }
            }

            switch(targetName)
            {
                case "scratchPad":
                {
                    pickerBox.scratchPad.drawReady(penSize,penColor,penAlpha,penShape,pickColor,getColorDifferenceForHuman);
                }
                return true;

                case "svBox":
                {
                    if(pickerBox.scratchPad && !pickerBox.scratchPad.visible)
                    {
                        setSVcolorButton();
                    }
                }
                return true;

                case "hueColor":
                {
                    if(pickerBox.scratchPad && !pickerBox.scratchPad.visible)
                    {
                        setHueColorButton();
                    }
                }
                return true;

                case "myPaletteBox":
                {
                    if(myPalettePresetType === 0)
                    {
                        checkSelctOrAddColorMyPalette();
                    }
                    else
                    {
                        checkButtonUpColorPickerBox(targetName);
                    }
                }
                return true;

                case "myPaletteButton":
                {
                    checkSelectMyPaletteOrReset();
                }
                return true;

                case "drawrPresetButton":
                case "tegakiPresetButton":
                {
                    startScratchPadResetTimer(target);
                    checkButtonUpColorPickerBox(targetName);
                }
                return true;

                case "penColorButton":
                case "paperColorButton":
                case "historyBox":
                case "transColorButton":
                case "currentColor":
                case "swapPositionButton":
                {
                    checkButtonUpColorPickerBox(targetName);
                }
                return true;

                default:

                return false;
            }

            return false;
        }

        private function rightMouseDownLassoTool(e:MouseEvent):void
        {
            if(!lassoToolON)
            {
                return;
            }

            const target:DisplayObject = e.target as DisplayObject;
            if(!target) return;

            const targetName:String = target.name;

            if(targetName === "toolZoom"
            || targetName === "zoomInButton"
            || targetName === "zoomOutButton")
            {
                if(zoomed !== 1.0) resetZoomDrawMode();
            }
            else if(targetName === "toolRotate")
            {
                if(regPoint.rotation !== 0.0) resetRotationDrawMode();
            }
        }

        private function rightMouseUpLassoTool(e:MouseEvent):void
        {
            if(!lassoToolON || mouseClickON)
            {
                return;
            }

            const target:DisplayObject = e.target as DisplayObject;
            if(!target) return;

            const targetName:String = target.name;

            if(targetName === "toolZoom"
            || targetName === "zoomInButton"
            || targetName === "zoomOutButton"
            || targetName === "toolRotate")
            {

            }
            else if(lassoMenu.hitTestPoint(mouseX,mouseY) === false || targetName === "lassoOK")
            {
                setLassoOKButton();
                return;
            }

            switch(targetName)
            {
                case "lassoRotate":
                {
                    if(lassoBox1.rotation !== 0)
                    {
                        lassoBox1.rotation = 0;
                        lassoBox2.rotation = 0;
                    }
                }
                break;

                case "lassoResize":
                {
                    if(lassoBox1.scaleY !== 1.0)
                    {
                        lassoBox1.scaleX = (lassoMirrorON) ? -1.0 : 1.0;
                        lassoBox1.scaleY = 1.0;
                        lassoBox2.scaleX = lassoBox1.scaleX;
                        lassoBox2.scaleY = lassoBox1.scaleY;
                    }
                }
                break;

                default:
                break;
            }
        }

        private function mouseUpLassoTool(e:MouseEvent):void
        {
            if(KEY_BUFFER.length === 1 && KEY_BUFFER[0] === KEY.space)
            {
                setNowKey(KEY.space);
                lassoMenuTempOFF = true;
                setNowTool(TOOL_HAND);
            }
        }

        private function mouseDownLassoTool(e:MouseEvent):void
        {
            if(rightMouseClickON)
            {
                return;
            }

            const target:DisplayObject = e.target as DisplayObject;
            if(!target)
            {
                return;
            }

            const targetName:String = target.name;

            if(isCursorInDrawArea() && lassoMenu.hitTestPoint(mouseX,mouseY) === false)
            {
                if(lassoMenuTempOFF)
                {
                    lassoMenu.visible = false;
                    if(isNowTool(TOOL_HAND)) handTool(false,false);
                    else if(isNowTool(TOOL_ZOOM)) zoomTool();
                    else if(isNowTool(TOOL_ROTATE)) rotateTool(false);
                }
                else
                {
                    setLassoMoveButton();
                }
            }
            else
            {
                switch(targetName)
                {
                    case "lassoMove": setLassoMoveButton(); break;
                    case "lassoResize": setLassoResizeButton(); break;
                    case "lassoRotate": setLassoRotateButton(); break;

                    case "prevStageBG":
                    case "prevBitmapBG":
                    case "prevBitmap":
                        setHandToolPreviewBox(false);
                    break;

                    case "prevCursor":
                        setHandToolPreviewBox(true);
                    break;

                    case "lassoMenuMoveButton":
                    {
                        setTopChildIndex(lassoMenu);
                        setToolBoxPos(lassoMenu);
                    }
                    break;

                    case "sideBarScrollBar":
                    {
                        setScrollBarMoveButton();
                    }
                    break;

                    case "zoomInButton":
                    {
                        setZoomInButton(true,false);
                    }
                    break;

                    case "zoomOutButton":
                    {
                        setZoomInButton(false,false);
                    }
                    break;

                    case "toolRotate":
                    {
                        lassoMenu.visible = false;
                        lassoMenuTempOFF = true;
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
                    case "lassoTrace":
                    case "sideBarPositionButton":
                    case "sideBarPositionButton2":
                    case "sideBarOFFButton":
                    case "sideBarOFFButton2":
                    case "sideBarONButton":
                    case "sideBarONButton2":
                    case "lassoLayerMerge":
                    case "lassoLayerSwap":
                    case "lassoMirror":
                        checkButtonUp(targetName);
                    break;

                    default:
                    break;
                }
            }

        }

        private function mouseDownDrawMode(e:MouseEvent):void
        {
            if(fillPenStarted || loadMenuBox.visible || topBar.gridButtonWrapper.visible || numPadBox.visible) return;

            const target:DisplayObject = e.target as DisplayObject;

            if(!target) return;

            const targetName:String = target.name;

            if(sideBar.visible)
            {
                if(sideBarScrollSet.hitTestPoint(mouseX,mouseY))
                {
                    if(targetName === "prevStageBG"
                    || targetName === "prevBitmapBG"
                    || targetName === "prevBitmap")
                    {
                        setHandToolPreviewBox(false);
                        return;
                    }
                    else if(targetName === "prevCursor")
                    {
                        setHandToolPreviewBox(true);
                        return;
                    }
                    else if(checkPickerBoxButtons(target) && isNowKey(0))
                    {
                        return;
                    }
                    else if(checkControlBoxButtons(target) && (isNowToolPenOrLine() || isNowTool(TOOL_ERASE)))
                    {
                        return;
                    }
                    else if(toolBox.alpha === 1.0 && target.alpha === 1.0 && checkToolBoxButtons(target))
                    {
                        return;
                    }
                }
                else if(isSidebarVisible === false)
                {
                    if(sideBar.visible && !sideBar.hitTestPoint(mouseX,mouseY) && isCursorInDrawArea())
                    {
                        penCursorPosition.setSideBarOFF();
                        return;
                    }
                }
            }

            if(quickSidebarON)
            {
                if(targetName === "sideBarScrollBar")
                {
                    setScrollBarMoveButton();
                }
                return;
            }

            switch (targetName)
            {
                case "saveButton": //아래 3개는 topbar메뉴에 가면 안됨 mouseuphandler랑 같이 연동되서 여기서 해주어야함
                case "repSaveButton":
                case "loadButton":
                case "replayModeButton":
                case "captureButton":
                case "repCaptureButton":
                case "clipButton":
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
                case "traceCancelButton":
                case "traceImageButton":
                case "traceLoadButton":
                case "traceMirrorButton":
                case "traceVisibleONButton":
                case "traceVisibleOFFButton":
                case "traceClipButton":
                case "appResetButton":
                case "dpiButton":
                case "newWindowButton":
                case "newWindowCloseButton":
                {
                    if(toolBox2ON || !isNowKey(0) || e.target.alpha < 1.0)
                    {
                        return;
                    }

                    checkButtonUp(targetName);
                }
                return;

                case "replaySpeedSliderWrapper":
                {
                    //grid 에서 불러줬을때 캔버스에 안무것도 못하게
                }
                return;

                case "traceDeleteButton":
                {
                    setCountDownLongKey(traceMenu.traceDeleteButton,"Erasing reference image... ",null,setTraceDeleteButton,null);
                }
                return;

                case "timer":
                {
                    setCountDownLongKey(topBar.timer,"Resetting the timer... ",null, realWorkingTimer.reset,null);
                }
                return

                case "clearButton":
                {
                    if(topBar.clearButton.alpha === 1.0 && !isInSaveProgress)
                    {
                        setClearData(false);
                    }
                }
                return;

                case "penSmoothSliderWapper":
                {
                    if(nowTool > 4) return;
                    setPenSmoothButton();
                }
                return;

                case "resizeButtonR":
                case "resizeButtonD":
                case "resizeButtonL":
                case "resizeButtonU":
                {
                    setCanvasResizeButton(targetName);
                }
                return;

                case "sideBarScrollBar":
                    setScrollBarMoveButton();
                return;

                case "traceRotateButton":
                {
                    setTopChildIndex(traceMenu);
                    setTraceRotateButton();
                }
                return;

                case "traceMoveButton":
                {
                    setTopChildIndex(traceMenu);
                    setTraceMoveButton();
                }
                return;

                case "traceResizeButton":
                {
                    setTopChildIndex(traceMenu);
                    setTraceResizeButton();
                }
                return;

                case "traceButtonWrapper":
                {
                    setTopChildIndex(traceMenu);
                    setTraceOpaButton();
                }
                return;

                case "traceMenuMoveButton":
                {
                    setToolBoxPos(traceMenu);
                }
                return;

                case "dragDropFileBG":
                return;
            }

            //캔버스 영역 밖에서는 해주지 않음
            if(isCursorInDrawArea() && !clickBlockOnWindowActiveFlag)
            {
                switch (nowTool)
                {
                    case TOOL_PEN: if(isCurrentLayerActive() && isToolActive()) penTool(true); break;
                    case TOOL_FILL_PEN: if(isCurrentLayerActive() && isToolActive()) fillPenTool.start(); break;
                    // case TOOL_SCAN_FILL: if(isCurrentLayerActive() && isToolActive()) scanFillTool.start(); break;
                    case TOOL_ERASE: if(isCurrentLayerActive() && isToolActive()) penTool(false); break;
                    case TOOL_LINE: if(isCurrentLayerActive() && isToolActive()) lineTool(true); break;
                    case TOOL_LASSO: if(isCurrentLayerActive()) lassoToolFunction.start(); break;
                    case TOOL_MOVE: if(isCurrentLayerActive()) moveTool(); break;
                    //캔버스 조작
                    case TOOL_ZOOM: zoomTool(); break;
                    case TOOL_HAND: handTool(false,false); break;
                    case TOOL_ROTATE: rotateTool(false); break;
                }
            }
        }

        // private var printdeepLevel:int = 0;
        // private function printArray(obj:Object,deepKey:String=""):void
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

        // private function testFuncTime():void
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
