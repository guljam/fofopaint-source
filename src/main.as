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
    import flash.display.LoaderInfo;
    import flash.display.NativeWindowInitOptions;
    import flash.display.NativeWindowSystemChrome;
    import flash.display.NativeWindowType;
    import flash.filesystem.File;
    import flash.filesystem.FileStream;
    import flash.filesystem.FileMode;
    import flash.system.Capabilities;
    import flash.system.IME;
    import flash.system.Worker;
    import flash.system.WorkerDomain;
    import flash.system.MessageChannel;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.ColorTransform;
    import flash.geom.Rectangle;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;
    import flash.events.NativeDragEvent;
    import flash.events.NativeWindowBoundsEvent;
    import flash.utils.ByteArray;
    import flash.utils.getTimer;
    import flash.utils.setTimeout;
    import flash.net.URLRequest;
    import flash.net.FileFilter;
    import flash.net.URLLoader;
    import flash.net.navigateToURL;
    import flash.net.URLLoaderDataFormat;
    import flash.text.TextField;
    import flash.ui.Mouse;
    import flash.filters.BlurFilter;
    import flash.system.System;
    import flash.filters.ConvolutionFilter;//import end

    public class main extends Sprite
    {
        private const APP_VERSION:Number = 20.15;
        private const APP_DATA_VERSION:Number = 18.71;
        private var NEW_VERSION:String = APP_VERSION+"";
        private var UPDATE_FILE:File = File.applicationStorageDirectory.resolvePath("updateTmpFile.air");
        private const STAGE_FRAME:int = stage.frameRate;

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
                    ,TOOL_PEN:int = (1 << 0)
                    ,TOOL_ERASE:int = (1 << 1)
                    ,TOOL_LINE:int = (1 << 2)
                    ,TOOL_FILL_PEN:int = (1 << 3)
                    ,TOOL_HAND:int = (1 << 4)
                    ,TOOL_LASSO:int = (1 << 5)
                    ,TOOL_SPUIT:int = (1 << 6)
                    ,TOOL_ZOOM:int = (1 << 7)
                    ,TOOL_ROTATE:int = (1 << 8)
                    ,TOOL_MOVE:int = (1 << 9)

                    ,JUMP_FRAME_PLAY:int = (1 << 0)
                    ,JUMP_FRAME_ONCE:int = (1 << 1)
                    ,JUMP_FRAME_BEFORE:int = (1 << 2)
                    ,JUMP_FRAME_AFTER:int = (1 << 3)

                    ,CENTERPOS_DRAW:int = 0
                    ,CENTERPOS_CAPTURE:int = (1 << 0)
                    ,CENTERPOS_REPLAY:int = (1 << 1)
                    ,CENTERPOS_DEEPUNDO:int = (1 << 2)

                    ,CANVAS_MIN_SIZE:Number = 100
                    ,CANVAS_MAX_SIZE:Number = 2000

                    ,COLOR_DARK:uint = 0x323232//어두운색
                    ,COLOR_MID_DARK:uint = 0x535353//0x5B5B5B//중간 어두운색
                    ,COLOR_MID_BRIGHT:uint = 0xB8B8B8//중간 밝은색
                    ,COLOR_BRIGHT:uint = 0xF0F0F0//0xECEAE7//밝은색

                    ,BUTTON_OFF_ALPHA:Number = 0.15

                    ,REPLAY_FASTEST_LIMIT_TIME:Number = 60
                    ,REPLAY_MAKE_JUMPIMAGE_COUNT:uint = 10000
                    ,REPLAY_MAX_SPEED:Number = 200

                    ,GRID_GAP:uint = 30
                    ,GRID_NORMAL_COLOR:uint = 0xBABABA
                    ,GRID_5UNIT_COLOR:uint = 0x515151

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
                    ,KEY_REPEAT_DELAY:Number = 0.25
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
                    ,STRING_PREPARE_REPLAY_DATA:String = "Preparing replay data.."
                    ,STRING_PLAYBACK_SPEED:String = "Playback speed x"
                    ,STRING_ONEMORE_CLICK_TO_OK:String = "One more click to OK"
                    ,STRING_ONEMORE_PRESS_TO_OK:String = "One more press key to OK"
                    ,STRING_WAIT_PROCESSING_DONE:String = "Close the app after processing done"
                    ,STRING_CAPTURE_OK:String = " (Click canvas to save image, Right-click to reset capture area)"
                    ,STRING_MERGE_LASSO_IMAGE_TO_TRACE:String = "Merge selected area\ninto reference layer"
                    ,STRING_MERGE_CANVAS_IMAGE_TO_TRACE:String = "Merge canvas image\ninto reference layer"
                    ,STRING_RIGHT_CLICK_TO_RESET:String = "Right-click to reset"
                    ,WORKER_STATE_STOPPED:int = 0
                    ,WORKER_STATE_INIT:int = (1 << 0)
                    ,WORKER_STATE_RUNNING:int = (1 << 1)
                    ,WINDOW_BORDER_SIZE:Number = 5;
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
                    ,CANVAS_TRACE_ALPHA:Number = 0.5
                    ,TOTAL_FRAME:Number = 0//rdata+file 프레임 전부 합친거
                    ,REPLAY_FASTEST_TOTAL_TIME:Number = 0 //최고 배속으로 돌렸는데도 총 재생시간이 60초 이상이면 올려줌
                    ,REPLAY_SLOWDRAW_ACTIVE_SPEED:Number = 50 //이 배속 이상일경우 doDrawSlowEvent를 걸어줌
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
                    ,canvasPanelMask:Shape = new Shape() //캔버스 마스크
                    ,lassoBox:Sprite = new Sprite()//선택한 이미지를 그려주고 확대 축소등 조작
                    ,penSizeCursor:Shape = new Shape() //펜사이즈 미리 보기
                    ,captureAreaRect:Shape = new Shape()//스크린샷 박스 미리보기 그려줌
                    ,toolBox:toolButtons = new toolButtons()
                    ,toolBox2:toolButtons2 = new toolButtons2()
                    ,rotateCursorBox:rotateCursor = new rotateCursor()//회전이 얼마나 됐는지 표시
                    ,lassoMenu:lassoButtons = new lassoButtons()//라소툴 버튼
                    ,lassoDraw:Shape = new Shape() //라소 영역 선 그려주는 쉐이프
                    ,topBar:topMenu = new topMenu()
                    ,spuitZoomCursor:spuitMag = new spuitMag()
                    ,toolTipBox:toolTipBoxSet = new toolTipBoxSet()//도움말 버튼
                    ,stageBG:Sprite = new Sprite() //드래그 불러오기가 stage공백에서는 안되서 수동으로 전체바탕으로 만들어줌
                    ,aboutPanel:aboutBox = new aboutBox()

                    ,fileDragSelectBox:loadBox = new loadBox()
                    ,controlBox:controlMenu = new controlMenu()
                    ,pickerBox:colorPickerBox = new colorPickerBox()
                    ,previewBox:previewPanel = new previewPanel()
                    ,appInfoBox:appInfoBar = new appInfoBar()
                    ,sideBar:sidePanel = new sidePanel()
                    ,fofo:fofoBottomBox = new fofoBottomBox()
                    ,sideBarScrollBar:Sprite = new Sprite()
                    ,sideBarScrollSet:Sprite = new Sprite()
                    ,transBGBMPD:BitmapData = new BitmapData(16,16,false,0xFFFFFF)
                    ,windowBorderD:Shape = new Shape()
                    ,windowBorderR:Shape = new Shape()
                    ,windowBorderL:Shape = new Shape()
                    ;

        private var  canvas1BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,canvas11BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,canvas2BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,lassoBMPsub:Bitmap = new Bitmap()//아래레이어
                    ,lassoBMP:Bitmap = new Bitmap()
                    ,appResetFlag:Boolean = false
                    ,rMirrorON:Boolean = false //대칭 켜지면 올려줌
                    ,mirrorON:Boolean = false
                    ,mirrorCommandReady:Boolean = false //미러 커맨드를 넣어줄지 말지 결정
                    ,zoomArr:Array = [0.125,0.25,0.5,0.75,1.0,2.0,3.0,4.0,6.0,8.0,12.0,16.0,24.0,32.0]
                    ,zoomed:Number = 1.0
                    ,zoomedIndex:int = 3
                    ,rzoomedIndex:int = 3
                    ,mouseClickON:Boolean = false //클릭하면 올려줌
                    ,rightMouseClickON:Boolean = false //클릭하면 올려줌
                    ,clickBlockFlag:Boolean = false //알탭 하고나서 창활성화 되면 일정시간동안 작동하지 않게함
                    ,mouseDragON:Boolean = false//툴을 계속 클릭한채로 움직이면 topmenu의 힌트가 안켜지도록 함
                    ,nowTool:int = 1 //현재 툴 번호
                    ,oldTool:int = TOOL_NONE //툴백업
                    ,keyBuffer:Array = [] //정식 키 다운 눌러준 상태에서 다른 키가 눌러져 있으면 여기다가 저장
                    ,nowKey:uint = 0//단축키 누른거 여기다가 저장
                    ,keyWaitMouseUp:Boolean = false //키 떼기 전에 마우스 먼저 떼주었을때 플래그 올려줌
                    ,penAlpha:Number = 1.0 //펜 변수
                    ,penColor:uint = 0x000000
                    ,sizeOffsetFlag:Boolean = false//0.5픽셀 이동이면 true임 pensizecursormove함수에서 써줌
                    ,sizeArr:Array = [0,1,2,3,4,5,7,10,13,18,30,45,80]
                    ,alphaArr:Array = [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0]
                    ,penCursorSize:Number = 3
                    ,penCursorShape:Boolean = false // true이면 사각형
                    ,penSize:uint = 3
                    ,penSizeIndex:uint = 3
                    ,penAlphaIndex:uint = 9
                    ,penShape:Boolean = false //false 이면 원 true 이면 사각형
                    ,penSmoothValue:Number = 0 //펜 손떨방 플래그
                    ,penSmoothSlideValue:int = 0 //펜 손떨방 플래그
                    ,penSmoothSlideTotal:Number = 20 //손떨방 총 단계
                    ,penSmoothButtonX:Number = 70 //손떨방 조절 버튼 초기 위치
                    ,sharpLineON:Boolean = false //0.5픽셀어긋나게 안하고 완전히 정확하게 할때씀
                    ,fillPenON:Boolean = false //채우기 펜 플래그
                    ,subLayerON:Boolean = false
                    ,subLayerPreviewON:Boolean = false
                    ,checkedLayer:int = 0 //레이어가 체크되면 저장해줌
                    ,airBrushON:Boolean = false
                    ,airBrushSizeDrawMode:Number = 0
                    ,airBrushSizeReplayMode:Number = 0
                    ,fillPenStarted:Boolean = false //채우기 펜 시작됨
                    ,eraseOddOffset:Number = 0//지우개 변수
                    ,eraseSize:uint = 12
                    ,eraseSizeIndex:uint = 8
                    ,eraseShape:Boolean = false
                    ,eraseAlpha:Number = 1.0
                    ,eraseAlphaIndex:uint = 9
                    ,eraseAirBrushON:Boolean = false
                    ,penListShapeFlag:Boolean = false //펜 리스트에서 펜 모양 버튼 눌러줄때 툴이랑 상관없이 바꿔줌, 펜 미리보기 할때 필요
                    ,penLastUpdateInfo:Array = [null,null,null,null,null,null] //updatePenSizeCursor 중복 사용 방지를 위해서 마지막 크기 저장해놓고 같으면 건너뙴
        //컬러픽커 관련 변수
                    ,HUECOLOR:Vector.<Number> = new Vector.<Number> (3,true) //hue컬러 다른 함수들이랑 통신하기 위해서 전역으로 만들어줌
                    ,pickerBoxColorBackup:uint = 0 //컬러 픽커 켜질때 원래 색깔 저장하는 곳
                    ,changedColor:int = -1 // 컬러 히스토리에서 고른 색깔을 여기다가 넣어줌
                    ,pickerMode:uint = 1 //1이면 펜컬러 2이면 배경색
                    ,pickerOpaClicked:Boolean = false //피커박스에서 투명도 조절했을때 올려줌 mouse out 이벤트 하나만 작동되게 할라고
                    ,pickerColorSelected:Boolean = false //피커박스에서 컬러를 한번이라도 조절했으면 올려줌
        //툴메뉴 관련 변수
        //어디 클릭했는지 위치 저장해줘서 다음에 켰을때 그 위치에서 툴메뉴가 켜지게끔 해줌
                    ,toolBoxLastClickPos:Point = new Point()//툴박스 마지막 위치 저장
                    ,toolBoxClickedTarget:String = "" //toolbox 항상 on해줬을때 아이콘을 클릭하고 땠을때 같은 아이콘인지 확인해주는 거임
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
                    ,lassoResizeON:Boolean = false //라소 무브 클릭하면 켜줌 힌트 메세지 안없어지게
                    ,lassoResizeMoveSum:Number = 0//라소 무브 클릭 움직이는 합저장 줌 1배 스냅걸리게 할때 쓰임
                    ,lassoPointSave:Array = []
                    ,lassoCopyON:Boolean = false //lasso 복사 누르면 올려줌
                    ,lassoBitmapdataSave:BitmapData //copy나 취소했을때 원래대로 돌려주는 이미지
                    ,lassoBitmapdataSubSave:BitmapData

        //window resize 관련 변수
                    ,lastWindowSize:Point = new Point() //창크기 조절 얼마나 됐을지 비교할때 마지막 크기 창크기 저장
        //save load 관련 변수
                    ,saveOneTime:Boolean = false //세이브 버튼 여러번 눌러서 데이터 계속 쓰여지는거 방지
                    ,saveFileName:String = getTimeStampTailHead()+" "+getRandomString()+".png"//세이브 파일 저장후에 이름을 이쪽에다가 보관해서 계속 그 이름으로 저장할수있게함
                    ,saveFilePath:String = saveFileName//파일 저장경로로 계속 저장 초기에는 filename이랑 똑같게 해줌
                    ,saveContinue:Boolean = false//한번 저장후에 다른이름으로 저장하기 전까지는 똑같은 이름으로 저장
                    ,clearDataButtonCount:uint = 0 //리플레이 취소 카운터
                    ,rImgData:ByteArray = new ByteArray()
                    ,rImgData1:ByteArray = new ByteArray()
                    ,lastImgData:ByteArray = new ByteArray()
                    ,lastImgData1:ByteArray = new ByteArray()
                    ,traceImgData:ByteArray = new ByteArray()
                    ,replayDataBytes:ByteArray = new ByteArray()

        //컬러 히스토리 관련 변수
                    ,colorHistoryList:Array = [0xFFFFFF,0x000000]
                    ,colorHistoryLimit:uint = 10
                    ,colorHistoryColorWidth:uint = 17//Math.floor(pickerBox.svBoxWidth/colorHistoryLimit)//히스토리 개별 색깔 가로 크기
                    ,colorHistoryRectH:uint = 19
                    ,colorHistoryUpdateReady:Boolean = false //히스토리 업데이트 이벤트 추가되면 올려주는거
                    ,colorHistoryUpdateBGReady:Boolean = false //히스토리 업데이트 이벤트 추가되면 올려주는거

        //툴팁 관련 변수
                    ,toolTipHint:String = "" //topbar관련 힌트 여기 저장

        //리플레이 관련 변수
        private const appDataFile:File = File.applicationStorageDirectory.resolvePath("appdata"+(APP_DATA_VERSION.toString()))
                    ,undoDataFile:File = File.applicationStorageDirectory.resolvePath("undodata")
                    ,repFile:File = File.applicationStorageDirectory.resolvePath("repdata")
                    ,repFileTemp:File = File.applicationStorageDirectory.resolvePath("repdatatmp") //파일을 저장하거나 불러올때 씀
                    ,rJumpImageFolder:File = File.applicationStorageDirectory.resolvePath("imagecache")
                    ,rJumpImageFrameDataFile:File = File.applicationStorageDirectory.resolvePath("jumpframedata")
                    ,rFirstImageFile:File = rJumpImageFolder.resolvePath("0")
                    ,rFileStream:FileStream = new FileStream()//함수들을 왔다갔다 해야해서 전역으로 하나 ,
                    ,rregPoint:Sprite = new Sprite()//회전 스프라이트 부모
                    ,rcanvasPanel:Sprite = new Sprite()
                    ,rcanvas2:Sprite = new Sprite()
                    ,rcanvas2Draw:Shape = new Shape()
                    ,rcanvasPanelMask:Shape = new Shape()
                    ,replayTimeBox:replayTimeBar = new replayTimeBar()
                    ,rcanvas1Bitmap:Bitmap = new Bitmap(rcanvas1BitmapData,"auto",true)
                    ,rcanvas11Bitmap:Bitmap = new Bitmap(rcanvas11BitmapData,"auto",true)
                    ,rcanvas2Bitmap:Bitmap = new Bitmap(rcanvas2BitmapData,"auto",true)
                    ,rCursor:SimpleButton = new tinyCursor(); //재생할때 틀어주는 작은 마우스

        private var rcanvas1BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,rcanvas11BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,rcanvas2BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,replayStartON:Boolean = false //리플레이 시작버튼 여러번 누르는거 방지
                    ,playbackFinished:Boolean = true //리플레이가 자연히 끝났을때 올렽주는 플래그 가장 처음에 캔버스 싹쓸이 하기 위해서 넣어줌.
                    ,replayEndWithCanvasFitWindow:Boolean = false //리플레이가 follow cursor옵션으로 캔버스 작게 축소되서 끝났을때
                    ,replayModeON:Boolean = false //이건 모드 자체 껐다 켰다

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
                    ,rFitZoomedON:Boolean = false // 리플레이에서 오른쪽 클릭해서 창 크기에 맞췄을때 올려줌 startreplay될때 줌 1.0으로 리셋 못시키게함
                    ,rJumpImageIndexLast:int = -2 //썸네일 인덱스 바뀌면 여기다 저장
                    ,rJumpImageNowFrameLast:Number = -1
                    ,rCachedJumpImageIndexLast:int = -2 //마지막에 그려준 캐쉬 이미지 번호를 저장
                    ,rCachedJumpImageIndexPush:int = 1 //dodraw에서 캐시이미지 그려줄때 이 번호로 순차적으로 저장하게 함
                    ,rCachedJumpImageIndexFrame:Number //dodraw에서 캐시이미지 가장 높은 프레임을 저장해줌
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

        //cut Frame 관련 변수
                    ,cutFrameActiveButton:SimpleButton
                    ,cutFrameClickCounter:uint = 0 //1번 누르면 미리 보기, 2번 누르면 실행
                    ,cutFrameWithShortcut:Boolean = false // cutframe할때 단축키를 썼는지 저장
                    ,cutFrameClickedButton:int = CUT_FRAME_NONE //무슨 버튼 눌렀는지 저장
                    ,rCutDataSaveFrame:Number = 0//슈퍼언도나 앞짜르기 할때 마우스 왔다갔다 하면서 반복해서 눌러줄때 jumponeframe이 계속작동되는거 방지해줌

        //스크린샷 관련 변수
                    ,captureModeON:Boolean = false //스크린샷 켜지면 올려줌
                    ,browseWindowON:Boolean = false //캡쳐 저장키 빠르게 누를때 에러 떠서 중복안되게 플래그 세워줌
                    ,canvasBackupData:Object = {} //캡쳐 키면 캔버스 이전 상태 저장함
                    ,canvasBackupDataOnSave:Object = {} //save appdata에서 캔버스가 capture모드 상태로 저장해주기 때문에 백업한 데이터로 저장시켜줌
                    ,captureZoomed:Number = 1 // 사각형 그려줄때 선 두깨를 이 배율에 맞추어서 해줌
                    ,captureWindowMove:Point = new Point(0,0) //스크린샷이 켜져있는 상태에서 창을 조절했을때, 스크린샷이 끝나고 나서 regpoint를 그만큼 움직여줘야함
                    ,captureRotated:uint = 0 //캡쳐 회전한 변수 저장
                    ,captureFlipped:Boolean = false //캡쳐 대칭한 변수 저장
                    ,captureTransBGON:Boolean = false //배경 제외하고 저장하는 플래그
                    ,fullCaptureReady:Boolean = false

        //윈도우 크기변수
                    ,lastWindowSizeInfo:Array = [0,0,680,768]
                    ,lastWindowState:int = 0

        //이미지 붙여넣기 변수
                    ,clipImageON:Boolean = false //윈도우 active에서 붙여넣기 가능한 이미지가 있으면 올려줌
                    ,clipImageOKCount:int = 0 //2번 이상 클릭되야 작동되게함
                    ,clipImageNameCount:int = 0 //붙여넣기 횟수만큼 파일이름뒤에 번호 붙여줌

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
                    ,traceRawArr:Array = null
                    ,traceImageCount:int = 0 //2번이상 클릭하면 되게
                    ,traceMemoryTraining:Boolean = false // 이거 켜지면 캔버스 그릴때 임시적으로 안보이게함
                    ,traceLastAlpha:Number = 0

        //그리드 레이어 변수
                    ,canvasGrid:Shape = new Shape()//트레이스 레이어임
                    ,gridFlag:uint = 0
        //closure
                    ,realWorkingTimer:Object = cRealWorkingTimer()
                    ,dottedLine:Object = cDottedLine()//순서 먼저 와야함
                    ,penTool:Function = cPenTool()
                    ,lineTool:Function = cLineTool()
                    ,handTool:Function = cHandTool()
                    ,lassoTool:Function = cLassoTool()
                    ,rotateTool:Function = cRotateTool()
                    ,zoomTool:Function = cZoomTool()
                    ,moveTool:Function = cMoveTool()
                    ,spuitTool:Function = cSpuitTool()
                    ,fillPenTool:Object = cFillPenTool()
                    ,drawDone:Function = cDrawDone()
                    ,tickDraw:Object = cTickDraw()
                    ,doDraw:Function = cDoDraw()
                    ,autoScroll:Object = cAutoScroll()
                    ,updatePenSizeCursor:Function = cUpdatePenSizeCursor()
                    ,undoData:Object = cAddUndoData()
                    ,addUndoData:Function = undoData.add
                    ,addUndoDataContinue:Function = undoData.addContinue
                    ,penCursorPosition:Object = cUpdatePenCursorPosition()
                    ,updatePenCursorPosition:Function = penCursorPosition.check
                    ,checkMainDrawTool:Function = cCheckMainDrawTool()
                    ,drawCaptureArea:Object = cDrawCaptureArea()
                    ,stageMouseMoveEvent:Object = cStageMouseMoveEvent()
                    ,replayHideCursor:Object = cCheckHideCursor()
                    ,checkHideCursorCount:Function = replayHideCursor.check
                    ,resizeCanvas:Object = cResizeCanvas()
                    ,setResizeCanvas:Function = resizeCanvas.start
                    ,startGC:Function = cStartGC()
                    // ,writeReplayFile:Object = cWriteReplayFile()

        //스크롤바 변수
                    ,scrollSetMovedY:Number = 0
                    ,scrollBarMovedY:Number = 0
                    ,scrollBarHeight:Number = 0
                    ,sideBarSetHeight:Number = 747

        //ui 색깔 변수
                    ,uiScaleIndex:int = 0
                    ,uiScaleSet:Array = [1.0,1.25,1.5,1.75,2.0]
                    ,uiColorIndex:int = 1
                    ,uiColorSet:Array = [       //주 컬러,        주컬러 반대색,    stage배경색,  캔버스 조절 막대 색,   리플레이 완료 막대 색, 리플레이 재시작 막대색
                                                [COLOR_DARK,      0xE5E5E5,      0x4B4B4B,    0x676767,            0x74AC74,           0xE8BE71],
                                                [COLOR_MID_DARK,  COLOR_BRIGHT,  0x888888,    RESIZE_BUTTON_COLOR, 0xA1CE9D,           0xF7DA83],
                                                [COLOR_MID_BRIGHT,0x505050,      0xC9C9C9,    0xB0B0B0,            0xB6DAAF,           0xF7EA8D],
                                                [COLOR_BRIGHT,    0x505050,      0xE1E1E1,    0xCBCBCB,            0xCEE5C5,           0xF7F2A0],
                                        ]
                    ,uiToolBoxColorSet:Array =
                    [ //컬러 셋 이름,       윗부분 막대색, 전체 배경색, upstate왼쪽아이콘색,  overstate 버튼배경색  overstate 아이콘색
                        [COLOR_DARK,        0x434343,   0xE5E5E5,  0xE5E5E5,           0x6E98B4,           0xE5E5E5],
                        [COLOR_MID_DARK,    0xE3E3E1,   0xE3E3E1,  COLOR_MID_DARK,     0xB1DFEE,           COLOR_MID_DARK],
                        [COLOR_MID_BRIGHT,  0xD6D5D4,   0x505050,  0x505050,           0xBADAE5,           0x505050],
                        [COLOR_BRIGHT,      0xE7E7E7,   0x505050,  0x505050,           0xCEEBF2,           0x505050]
                    ]
                    ,tegaKiPresetColor:Vector.<Array> = new <Array>[
                                                                        [0x800000,0xF0E0D6],
                                                                        [0x4B3D38,0xEAE5D5],
                                                                        [0x384B43,0xCFEADD],
                                                                        [0x313768,0xD5E9F3],
                                                                        [0xA80515,0xF1D0D0]
                                                                    ]
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
                    ,workerReplaySendBA:ByteArray = new ByteArray()
                    ,workerReplaySendBATemp:ByteArray = new ByteArray()

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
        //기타
        private var windowClosingFlag:Boolean = false//윈도우 닫힐때 올려줌 save all data가 windows closing일때는 무조건 해주게 끔함
                    ,windowDeactivateTime:int = 0 //윈도우 비활성화된 시간 저장, 너무 자주 알탭해서 save all data가 자주 호출되는걸 막음
                    ,penCursorOFFFlag:Boolean = false //펜커서 이게 on되면 안보여줌
                    ,tempDragDropFile:Object = []
                    ,tempCopiedImage:BitmapData
                    ,eraseMovedButton:SimpleButton = null //툴 선택해줬을때 지우개툴이 이동한 툴을 저장해줌 다시원래대로 복원해주려고

                    ,zoomToolHintON:Boolean = false //툴박스에서 마우스 클릭해서 줌툴써줄때 mouse out이벤트가 가장 늦게 되서 줌 배율 힌트가 처음에 보이지 않는거 해결
                    ,isRightSidebar:Boolean = false // 사이드바 위치 0이 왼쩾 1이 오른쪽
                    ,isSidebarVisible:Boolean = true
                    ,sideBarPosSave:Number //사이드 바 단축키 사용하고나서 원래 위치로 옮겨줄때 씀
                    ,quickSidebarON:Boolean = false
                    ,topBarHintClickEventON:Boolean = false //톱바 힌트가 켜졌을때 클릭하면 지워주는 이벤트
                    ,isNewFOFOSaveFormat:Boolean = false
                    ,updateAfterSave:Boolean = false //업데이트 버튼 눌렀을때 파일 저장 해주고 기다려주는 플래그
                    ,layerVisibleKeyFuncCalled:Boolean = false //w키 1키 계속 누르고 있을때 함수 호출 안하게 해주려고 플래그 올려줌
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
            makeTransBG();
            makeWindowBorder();
            makeWorker();
            updateWindowSizeInfo();
            updateColorHistoryList();
            loadAppData(); //이전 세팅 복원
            initReplayDataFile();
            initPickerBoxInfo(penColor);
            addStageInputEvent();
            addInputEventStageChild();
            addInputEventDrawMode();
            lastWindowSize = new Point(stage.nativeWindow.width,stage.nativeWindow.height);
            setCenvasCenterPos();
            setCenvasCenterPos(true);
            previewBox.updateImage(canvas1BitmapData,canvas11BitmapData,CANVAS_BG_COLOR);
            realWorkingTimer.start();
            stageMouseMoveEvent.start();
            checkVersion();
            setIMEDisabled();
            selectPenTool();

            stage.addChild(fofo);
            stage.setChildIndex(fofo,stage.getChildIndex(sideBar)+1);
        }

        //function
        private function updateStageOffset():void
        {
            const scale:Number = getUIScale();
            const borderSize:Number = Math.round(WINDOW_BORDER_SIZE*scale);

            STAGE_TOP_OFFSET = Math.round(topBar.BARSIZE*scale);
            STAGE_BOTTOM_OFFSET = borderSize;
            STAGE_RIGHT_OFFSET = borderSize;
            STAGE_LEFT_OFFSET = borderSize;

            if(captureModeON || replayModeON)
            {
                return;
            }

            if(isSidebarVisible)
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

        private function makeWindowBorder():void
        {
            windowBorderD.cacheAsBitmap = true;
            windowBorderR.cacheAsBitmap = true;
            windowBorderL.cacheAsBitmap = true;
            stage.addChild(windowBorderD);
            stage.addChild(windowBorderR);
            stage.addChild(windowBorderL);
            stage.setChildIndex(windowBorderL,stage.getChildIndex(rregPoint)+1);
            stage.setChildIndex(windowBorderR,stage.getChildIndex(rregPoint)+1);
            stage.setChildIndex(windowBorderD,stage.getChildIndex(rregPoint)+1);
        }

        private function setWindowBorderColor(base:uint):void
        {
            const ct:ColorTransform = new ColorTransform();
            ct.color = base;
            windowBorderD.transform.colorTransform = ct;
            windowBorderR.transform.colorTransform = ct;
            windowBorderL.transform.colorTransform = ct;
        }

        private function updateWindowBorder(stw:int,sth:int):void
        {
            const scale:Number = getUIScale();
            const size:Number = WINDOW_BORDER_SIZE*scale;

            windowBorderD.graphics.clear();
            windowBorderD.graphics.beginFill(0xFF0000);
            windowBorderD.graphics.drawRect(0,0,stw,size);
            windowBorderD.graphics.endFill();

            windowBorderL.graphics.clear();
            windowBorderL.graphics.beginFill(0xFFFF00);
            windowBorderL.graphics.drawRect(0,0,size,sth);
            windowBorderL.graphics.endFill();

            windowBorderR.graphics.clear();
            windowBorderR.graphics.beginFill(0xFFFF00);
            windowBorderR.graphics.drawRect(0,0,size,sth);
            windowBorderR.graphics.endFill();

            windowBorderD.x = 0;
            windowBorderD.y = sth-size;
            windowBorderL.x = stw-size;
        }

        private function clearArrayElement(arr:Array):void
        {
            const len:uint = arr.length;
            for (var i:uint = 0; i < len; i++)
            {
                arr[i] = null;
            }
            arr.length = 0;
            arr = null;
        }

        private function cloneBitmapData(targetBmpd:BitmapData,sourceBmpd:BitmapData):void
        {
            if(targetBmpd && targetBmpd !== sourceBmpd) targetBmpd.dispose();
            targetBmpd = sourceBmpd.clone();

            targetBmpd = null;
            sourceBmpd = null;
        }

        private function checkMirrorCanvasReplayMirror():void
        {
            if(mirrorON !== rMirrorON)
            {
                mirrorCommandReady = true;
                mirrorDraw();
                checkGridMirror(mirrorON);
                if(rCursor.visible) setRCursorMirrorPos();
            }
            else
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

        private function setRCursorVisibleOFFUndoMouseDownEvent(e:MouseEvent):void
        {
            setRCursorVisibleOFFUndo(true);
        }

        private function setRCursorVisibleOFFUndo(pureClickFlag:Boolean=false):void
        {
            if((pureClickFlag && isCursorInDrawArea()) || !pureClickFlag)
            {
                rCursor.visible = false;
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,setRCursorVisibleOFFUndoMouseDownEvent);
                removeTimer("setRCursorVisibleOFFUndoTimer");
            }
        }

        private function setRCursorVisibleONUndo(undoIndex:int):void
        {
            if(rCursor.visible === false)
            {
                rCursor.visible = true;
                stage.addEventListener(MouseEvent.MOUSE_DOWN,setRCursorVisibleOFFUndoMouseDownEvent);
            }

            if(undoIndex < 0)
            {
                const _tickDraw:Object = tickDraw;
                if(_tickDraw.hasRCursorFirstPos())
                {
                    const p:Point = _tickDraw.getFirstRCursorPos();
                    _tickDraw.setRCursorPos(p.x,p.y); //커서 위치도 업에이트 해줘야함 대칭해줄띠 getRcursor로 하기 때문에
                    _tickDraw.updateRCursorPosToFirst();
                }
                else
                {
                    setRCursorVisibleOFFUndo();
                    toolTipBoxTimerOFF();
                }
            }
            else
            {
                tickDraw.updateRCursorPos();
            }
        }

        private function setSingleLayerPreviewOFF():void
        {
            subLayerPreviewON = false;
            previewBox.prevBitmap.visible = true;
            previewBox.prevBitmapSub.visible = true;

            stage.removeEventListener(KeyboardEvent.KEY_UP,setSingleLayerPreviewOFFKeyUpEvent);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE,layerSinglePreviewOFFMouseOutEvent);
        }

        private function setSingleLayerPreviewOFFKeyUpEvent(e:KeyboardEvent):void
        {
            if(e.keyCode === KEY.n1 || e.keyCode === KEY.n2
            || e.keyCode === KEY.n9 || e.keyCode === KEY.n0)
            {
                setSingleLayerPreviewOFF();
            }
        }

        private function layerSinglePreviewOFFMouseOutEvent(e:MouseEvent):void
        {
            if(controlBox.layerButtonWrapper.hitTestPoint(mouseX,mouseY) === false
            || controlBox.layerSwapButton.hitTestPoint(mouseX,mouseY) === true
            || controlBox.layerMergeButton.hitTestPoint(mouseX,mouseY) === true)
            {
                setSingleLayerPreviewOFF();
            }
        }

        private function setSingleLayerPreview(layer:int,shortcut:Boolean):void
        {
            if(subLayerPreviewON === false)
            {
                subLayerPreviewON = true;
                stage.addEventListener(KeyboardEvent.KEY_UP,setSingleLayerPreviewOFFKeyUpEvent,false,5);
                if(!shortcut)
                {
                    stage.addEventListener(MouseEvent.MOUSE_MOVE,layerSinglePreviewOFFMouseOutEvent,false,5);
                }
            }

            if(layer === 1)
            {
                previewBox.prevBitmap.visible = true;
                previewBox.prevBitmapSub.visible = false;
            }
            else if(layer === 2)
            {
                previewBox.prevBitmap.visible = false;
                previewBox.prevBitmapSub.visible = true;
            }
        }

        private function checkfofoPos():void
        {
            if(isRightSidebar)
            {
                fofo.flipImage(false);
                fofo.x = sideBar.x+sideBar.getWidth()-fofo.width;
            }
            else
            {
                fofo.flipImage(true);
                fofo.x = sideBar.x;
            }

            fofo.setY(stage.stageHeight);

            if(sideBar.visible)
            {
                if(sideBarScrollSet.hitTestObject(fofo)) fofo.visible = false;
                else fofo.visible = true;
            }
            else
            {
                fofo.visible = false;
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
            const bounds:Rectangle = previewBox.setFitBitmapforBox(canvasWindowBitmap.bitmapData.width,canvasWindowBitmap.bitmapData.height
                                                                  ,canvasWindow.stage.stageWidth,canvasWindow.stage.stageHeight);
            updateCanvasWindowCanvasPanelBGColor(CANVAS_BG_COLOR,canvasWindowBitmap.bitmapData);
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
                if(canvasWindow.width < 300 && canvasWindow.height < 300)
                {
                    canvasWindow.bounds = new Rectangle(canvasWindow.x,canvasWindow.y,300,300);
                }
                else
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
            return rcanvasPanel.getChildIndex(rcanvas2) === 1;
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

                rDataBuffer.push(["lassodel",point1,point2,lassoInfo,lassoCopyON,canvas1Bitmap.visible,canvas11Bitmap.visible]);
                addUndoData();

                disposeLassoBMP();
                resetLassoBox();
            }

            if(canvasTraceLayer.visible === false || CANVAS_TRACE_ALPHA === 0.0)
            {
                updateTraceOpaButtonPosByAlpha(0.5);
                CANVAS_TRACE_ALPHA = 0.5;
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

        private function checkCaptureButtonActiveCaptureMode():void
        {
            topBar.capClipBoard.alpha = 1.0;
            if(replayModeON)
            {
                if(!rcanvas1Bitmap.visible && !rcanvas11Bitmap.visible)
                {
                    topBar.capFull.alpha = BUTTON_OFF_ALPHA;
                    topBar.capClipBoard.alpha = BUTTON_OFF_ALPHA;
                    topBar.capRotate.alpha = BUTTON_OFF_ALPHA;
                    topBar.capFlip.alpha = BUTTON_OFF_ALPHA;
                }
                else if(topBar.capFull.alpha < 1.0)
                {
                    topBar.capFull.alpha = 1.0;
                    topBar.capClipBoard.alpha = 1.0;
                    topBar.capRotate.alpha = 1.0;
                    topBar.capFlip.alpha = 1.0;
                }
            }
            else
            {
                if(!canvas1Bitmap.visible && !canvas11Bitmap.visible)
                {
                    topBar.capFull.alpha = BUTTON_OFF_ALPHA;
                    topBar.capClipBoard.alpha = BUTTON_OFF_ALPHA;
                    topBar.capRotate.alpha = BUTTON_OFF_ALPHA;
                    topBar.capFlip.alpha = BUTTON_OFF_ALPHA;
                }
                else if(topBar.capFull.alpha < 1.0)
                {
                    topBar.capFull.alpha = 1.0;
                    topBar.capClipBoard.alpha = 1.0;
                    topBar.capRotate.alpha = 1.0;
                    topBar.capFlip.alpha = 1.0;
                }
            }
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
            if(replayModeON)
            {
                if(rcanvas1Bitmap.visible)
                {
                    rcanvas1Bitmap.visible = false;
                    if(!isSubLayerONReplayMode()) rcanvas2.visible = false;

                    topBar.capLayer1VisibleButton.alpha = BUTTON_OFF_ALPHA;
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
                }
                else
                {
                    canvas1Bitmap.visible = true;
                    topBar.capLayer1VisibleButton.alpha = 1.0;
                }
            }

            checkCaptureButtonActiveCaptureMode();
        }

        private function setLayer2CheckToggleCaptureMode():void
        {
            if(replayModeON)
            {
                if(rcanvas11Bitmap.visible)
                {
                    rcanvas11Bitmap.visible = false;
                    if(isSubLayerONReplayMode()) rcanvas2.visible = false;

                    topBar.capLayer2VisibleButton.alpha = BUTTON_OFF_ALPHA;
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
                }
                else
                {
                    canvas11Bitmap.visible = true;
                    topBar.capLayer2VisibleButton.alpha = 1.0;
                }
            }
            checkCaptureButtonActiveCaptureMode();
        }

        private function addUndoBGColor(color:uint):void
        {
            if(hasLastRDataCommand("bgColor"))
            {
                rDataBuffer.push(["bgColor",color]);
                updateLastRDataCommand("bgColor");
                addUndoDataContinue();
            }
            else
            {
                if(deepUndoON) setApplyDeepUndo();
                rDataBuffer.push(["bgColor",color]);
                addUndoData();
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
            const arr:Array = rData[index];

            if(arr.length === 1)
            {
                rData.splice(index);
                rDataFrame.splice(index);
            }
            else
            {
                for(var i:uint=0; i<arr.length; i++)
                {
                    if(command === arr[i][0])
                    {
                        arr.splice(i,1)
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
                addUndoData();
            }
            controlBox.layerMergeButton.alpha = BUTTON_OFF_ALPHA;
        }

        private function setLayerSwapButton():void
        {
            if(deepUndoON) setApplyDeepUndo();
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
                addUndoData();
            }
        }

        private function getProcessedCaptureImage(clipBoardCopyFlag:Boolean):BitmapData
        {
            const isReplayMode:Boolean = replayModeON;
            var info:Array;
            var layer1:Boolean;
            var layer2:Boolean;

            if(drawCaptureArea.isFullImageCapture())
            {
                if(isReplayMode) info = [0,0,rcanvas1BitmapData.width,rcanvas1BitmapData.height];
                else info = [0,0,canvas1BitmapData.width,canvas1BitmapData.height];
            }
            else
            {
                info = drawCaptureArea.getCaptureArea();
            }

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

            const bmpd:BitmapData = mergeCanvas(isReplayMode,(captureModeON && captureTransBGON && !clipBoardCopyFlag) ? true : false,layer1,layer2);
            var newRectangle:Rectangle = new Rectangle(info[0],info[1],info[2],info[3]);
            var cropData:ByteArray = bmpd.getPixels(newRectangle);
            cropData.position = 0; //이거 꼭 해줘야함 안그러면 setpixel에서 에러뜸
            const cropbmpd:BitmapData = new BitmapData(info[2],info[3],true,0);

            newRectangle = new Rectangle(0,0,cropbmpd.width,cropbmpd.height);
            cropbmpd.lock();
            cropbmpd.setPixels(newRectangle,cropData);
            cropbmpd.unlock();
            cropData.clear();
            cropData = null;

            const mat:Matrix = new Matrix;
            const deg:Number = 90*captureRotated;
            var tmpbmpd:BitmapData = new BitmapData(cropbmpd.width,cropbmpd.height,true,0);
            var swapWH:Boolean = false;
            mat.rotate(deg*Math.PI/180);

            if(deg === 90)
            {
                mat.translate(cropbmpd.height,0);
                swapWH = true;
            }
            else if (deg === -90 || deg == 270)
            {
                mat.translate(0,cropbmpd.width);
                swapWH = true;
            }
            else if (deg === 180)
            {
                mat.translate(cropbmpd.width, cropbmpd.height);
            }

            if(captureFlipped)
            {
                if(swapWH)
                {
                    mat.scale(1,-1);
                    mat.translate(0,cropbmpd.width);
                }
                else
                {
                    mat.scale(-1,1);
                    mat.translate(cropbmpd.width,0);
                }
            }

            if(swapWH) tmpbmpd = new BitmapData(cropbmpd.height,cropbmpd.width,true,0);

            tmpbmpd.draw(cropbmpd,mat);
            cropbmpd.dispose();

            return tmpbmpd;
        }

        private function copyCaptureImageToCilpBoard():void
        {
            Clipboard.generalClipboard.setData(ClipboardFormats.BITMAP_FORMAT,getProcessedCaptureImage(true),false);
            topBar.hint("The image copied to clipboard successfully",topBar.capClipBoard as DisplayObject);
            topBar.capClipBoard.alpha = BUTTON_OFF_ALPHA;
        }

        private function getUIScaleString(index:int):String
        {
            if(index === 0)
                return "100%";
            else
                return getUIScale()*100+"%";
        }

        private function getUIScale():Number
        {
            return uiScaleSet[uiScaleIndex];
        }

        private function setUIScaleButton(index:int):void
        {
            if(index > uiScaleSet.length-1) index = 0;
            uiScaleIndex = index;

            const stw:Number = stage.stageWidth;
            const sth:Number = stage.stageHeight;
            const scale:Number = uiScaleSet[index];

            sideBar.scaleX = scale;
            sideBar.scaleY = scale;

            if(isRightSidebar) updateSidebarDefaultRightPos();
            else sideBar.x = 0;

            topBar.scaleX = scale;
            topBar.scaleY = scale;
            topBar.updateTopbarBG(stw);
            topBar.updateTimerPos(stw);
            topBar.updateHintBGWidth(stw);

            replayTimeBox.scaleX = scale;
            replayTimeBox.scaleY = scale;

            lassoMenu.scaleX = scale*lassoMenu.fixedScale;
            lassoMenu.scaleY = scale*lassoMenu.fixedScale;

            traceMenu.scaleX = scale*traceMenu.fixedScale;
            traceMenu.scaleY = scale*traceMenu.fixedScale;

            toolBox2.scaleX = scale*toolBox2.fixedScale;
            toolBox2.scaleY = scale*toolBox2.fixedScale;

            toolTipBox.scaleX = scale;
            toolTipBox.scaleY = scale;
            toolTipBox.updateBGPosition((uiScaleIndex === 0) ? false:true)

            aboutPanel.scaleX = scale;
            aboutPanel.scaleY = scale;

            updateStageOffset();
            updateScrollBarHeight(sth);
            sideBar.y = Math.round(STAGE_TOP_OFFSET);
            sideBar.updateSideBGSize((sth-STAGE_TOP_OFFSET)/getUIScale());
            fofo.scaleX = scale*fofo.fixedScale;
            fofo.scaleY = scale*fofo.fixedScale;
            checkfofoPos();
            updateWindowBorder(stw,sth);
            autoScroll.updateScale(scale);

            if(lassoToolON) checkBoxPosition(lassoMenu);
            if(traceMenuON) checkBoxPosition(traceMenu);

            updatePreviewBoxRectPos();
        }

        private function cStartGC():Function
        {
            var gcCount:int;

            function startGCCycle():void
            {
                gcCount = 0;
                stage.addEventListener(Event.ENTER_FRAME,doGC);
            }

            function doGC(evt:Event):void
            {
                System.gc();
                if(++gcCount > 1)
                {
                    stage.removeEventListener(Event.ENTER_FRAME,doGC);
                    setTimeout(lastGC,40);
                }
            }

            function lastGC():void
            {
                System.gc();
            }

            return startGCCycle;
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

            sideBar.x = sideBarPosSave;
            quickSidebarON = false;
            checkfofoPos();

            if(toolBox.getLastTool() === "toolSpuit") spuitTool();
            if(traceMenuON) traceMenu.visible = true;
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
            if(!e.target) return;

            switch(e.target.name)
            {
                case "toolZoom":
                case "zoomInButton":
                case "zoomOutButton":
                {
                    if(zoomed !== 1.0) resetZoomDrawMode();
                }
                return;

                case "toolRotate":
                {
                    if(regPoint.rotation !== 0.0) resetRotationDrawMode();
                }
                return;

                case "colorHistoryBox":
                case "colorHistoryBoxBG":
                return;
            }

            setQuickSidebarOFF();
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
            || keyCode === KEY.j || keyCode === KEY.k)
            {
                setQuickSidebarOFF();
            }
        }

        private function setQuickSidebarON(shortcut:Boolean):void
        {
            quickSidebarON = true;

            if(shortcut)
            {
                restoreFirstUsedTool();
                stage.addEventListener(KeyboardEvent.KEY_UP,keyUpQuickSidebarOFF);
            }
            else
            {
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownQuickSidebarOFF,false,-2);
                stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownQuickSidebarOFF,false,-2);
            }

            const sideBarWidth:Number = sideBar.getWidth();

            sideBarPosSave = sideBar.x;
            sideBar.x = mouseX-(sideBarWidth)/2+((isRightSidebar)? -18:22);

            if(sideBar.x < 0) sideBar.x = 0;
            else if(sideBar.x+sideBarWidth > stage.stageWidth) updateSidebarDefaultRightPos();

            if(sideBar.visible === true && isSidebarVisible === false)
            {
                penCursorPosition.removeSideBarClickEvents();
            }

            sideBar.visible = true;

            if(traceMenuON) traceMenu.visible = false;

            checkfofoPos();
            if(toolTipBox.visible) toolTipBoxTimerOFF();
            setSidebarReCacheBitmap();
        }

        private function deleteOldAppData():void
        {
            const list:Array = File.applicationStorageDirectory.getDirectoryListing();
            const len:int = list.length;
            var filename:String;

            for (var i:int=0; i<len; i++)
            {
                filename = list[i].name;
                if(filename.indexOf("appdata") !== -1 && filename !== "appdata"+APP_DATA_VERSION.toString())
                {
                    const files:File = File.applicationStorageDirectory;
                    files.deleteDirectory(true);
                    return;
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

                    startGC();

                    if(updateAfterSave)
                    {
                        startUpdate();
                    }
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

            workerReplaySendBA.shareable = true;
            workerReplaySendBATemp.shareable = true;

            function loadComplete(e:Event):void
            {
                workerSWF = e.target.data as ByteArray;
                workerLoader = null;
            }
        }

        private function updateCanvasPanelMask(w:Number,h:Number):void
        {
            const maskg:Graphics = canvasPanelMask.graphics;
            maskg.clear();
            maskg.beginFill(0xFF00FF);
            maskg.drawRect(0,0,w,h);
            maskg.endFill();
        }

        private function isHitTestPoint(obj:DisplayObject,checkShape:Boolean=false):Boolean
        {
            return obj.hitTestPoint(mouseX,mouseY,checkShape) as Boolean;
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
                    dotLineColor = 0xFFFFFF;
                else
                    dotLineColor = 0;

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

                        for(var i:Number=div; i>=1; i--)
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
            const hideTime:int = STAGE_FRAME;
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
                    if(count > hideTime)
                    {
                        Mouse.hide();
                        topBar.hintOFF();
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

        private function updateOldTool():void
        {
            if(oldTool === TOOL_NONE)
                oldTool = nowTool;
        }

        private function setHoldKeyRepeat(func:Function,...args):Boolean
        {
            if(hasTimer("keyHoldWaitTimer") || hasTimer("keyHoldRepeatTimer")) return false;

            addTimerByName("keyHoldWaitTimer",KEY_REPEAT_DELAY,false,
            function():void
            {
                func.apply(main,args);
                addTimerByName("keyHoldRepeatTimer",KEY_REPEAT_INTERVAL,true,func,args);
            });

            addCancelAutoKeyEvent();
            func.apply(main,args);

            return true;
        }

        private function checkMoreOptionsKeyDown(keyCode:int):Boolean
        {
            if(keyBuffer[1] === KEY.n3 || keyBuffer[1] === KEY.n8)
            {
                setSharpLineButtonShortcut();
                return true;
            }
            else if(keyBuffer[1] === KEY.n4 || keyBuffer[1] === KEY.n7)
            {
                if(isPenOrLineTool() || isNowTool(TOOL_FILL_PEN))
                {
                    setPenAirBrushButtonShortCut();
                    return true;
                }
                else if(isEraseTool())
                {
                    setEraseAirBrushButtonShortCut();
                    return true;
                }
            }
            return false;
        }

        private function checkOpaSizeKeyDown(keyCode:int):Boolean
        {
            switch(keyCode)
            {
                case KEY.f:
                case KEY.h:
                    setHoldKeyRepeat(shortCutPenSize,true);
                return true;

                case KEY.v:
                case KEY.n:
                    setHoldKeyRepeat(shortCutPenSize,false);
                return true;

                case KEY.g:
                    setHoldKeyRepeat(shortCutPenAlpha,true);
                return true;

                case KEY.b:
                    setHoldKeyRepeat(shortCutPenAlpha,false);
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
            const arr:Array = keyBuffer;
            const first:int = arr[0];
            const second:int = arr[1];

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
            const mx:Number = mouseX;
            const my:Number = mouseY;

            if(mx <= STAGE_LEFT_OFFSET || mx >= stage.stageWidth -STAGE_RIGHT_OFFSET
            || my <= STAGE_TOP_OFFSET  || my >= stage.stageHeight-STAGE_BOTTOM_OFFSET)
            {
                return false;
            }
            return true;
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
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,rightMouseUpLassoTool);
            addInputEventDrawMode();
        }

        private function addMouseKeyEventLassoTool():void
        {
            stage.addEventListener(KeyboardEvent.KEY_UP,keyUpLassoTool);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownLassoTool);
            stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownLassoTool);
            stage.addEventListener(MouseEvent.MOUSE_UP,mouseUpLassoTool,false,-1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,rightMouseUpLassoTool);
            stage.addEventListener(MouseEvent.MOUSE_OVER,lassoMenuHintONEvent);
            removeInputEventDrawMode();
        }

        private function stageMouseDownEvent(e:MouseEvent):void
        {
            mouseClickON = true;
        }

        private function stageRightMouseDownEvent(e:MouseEvent):void
        {
            rightMouseClickON = true;
        }

        private function stageMouseUpEvent(e:MouseEvent):void
        {
            const mx:Number = mouseX;
            const my:Number = mouseY;

            mouseClickON = false;
            if(!mouseClickON && rightMouseClickON) mouseDragON = false;

            if(mx < 0 || mx > stage.stageWidth || my < 0 || my > stage.stageHeight)
            {
                if(sideBar.visible === false) penCursorPosition.setSideBarONWaitEvents();
            }
        }

        private function stageRightMouseUpEvent(e:MouseEvent):void
        {
            const mx:Number = mouseX;
            const my:Number = mouseY;

            rightMouseClickON = false;
            if(!mouseClickON && rightMouseClickON) mouseDragON = false;

            if(mx < 0 || mx > stage.stageWidth || my < 0 || my > stage.stageHeight)
            {
                if(sideBar.visible === false) penCursorPosition.setSideBarONWaitEvents();
            }
        }

        private function cStageMouseMoveEvent():Object
        {
            const funcNameList:Vector.<String> = new Vector.<String>();
            const funcList:Vector.<Function> = new Vector.<Function>();
            var lastTime:int = 0;
            var nowTime:int = 0;

            //mosue move 이벤트 일정 시간 이내는 무시함
            function moveEventLimit():Boolean
            {
                nowTime = getTimer();

                if(nowTime === lastTime)
                {
                    return true;
                }

                lastTime = nowTime;

                return false;
            }

            function add(name:String,func:Function):void
            {
                if(funcNameList.lastIndexOf(name) === -1)
                {
                    funcNameList.push(name);
                    funcList.push(func);
                }
            }

            function remove(name:String):void
            {
                const len:uint = funcNameList.length;
                for(var i:int=0;i<len;i++)
                {
                    if(funcNameList[i] === name)
                    {
                        funcNameList.removeAt(i);
                        funcList.removeAt(i);
                        break;
                    }
                }
            }

            function event(e:MouseEvent):void
            {
                if(moveEventLimit() === true) return;

                const len:uint = funcList.length;

                for(var i:int=0;i<len;i++)
                {
                    funcList[i](e);
                }
            }

            function start():void
            {
                //전역 마우스 move 이벤트
                stage.addEventListener(MouseEvent.MOUSE_MOVE,event);
            }

            return {
                event:event,
                start:start,
                remove:remove,
                add:add
            }
        }

        private function mouseLeaveSideBarON():void
        {
            if(replayModeON || captureModeON)
            {
                return;
            }

            if(!isSidebarVisible && !sideBar.visible)
            {
                const mx:Number = mouseX;
                const sideBarWidth:Number = sideBar.getWidth();

                if((isRightSidebar && mx > stage.stageWidth-sideBarWidth)
                || (!isRightSidebar && mx < sideBarWidth))
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

        private function setSidebarReCacheBitmap():void
        {
            sideBar.cacheAsBitmap = false;
            addTimerByName("sideBarReCacheAsBitmapTimer",0.2,false,function():void
            {
                sideBar.cacheAsBitmap = true;
            });
        }

        private function setSidebarVisible(flag:Boolean,tempFlag:Boolean):void
        {
            if(tempFlag === false) isSidebarVisible = flag;

            if(flag)
            {
                sideBar.visible = true;
                checkfofoPos();

                //사이드바가 짤려 나오는 현상이 있어서 다시 캐쉬 풀었다가 다시 해줌
                setSidebarReCacheBitmap();
            }
            else
            {
                sideBar.setTempVisibleOFF(isRightSidebar);
                fofo.visible = false;
            }

            if(tempFlag === false)
            {
                topBar.checkSideBarONOFFButton(flag,isRightSidebar);
            }

            updateStageOffset();
            updatePreviewBoxRectPos();
        }

        private function setCurrentColor(mode:uint):void
        {
            const _pickerBox:colorPickerBox = pickerBox;
            const hexColor:uint = _pickerBox.currentColorColor;
            const c:Vector.<uint> = HEXtoRGB(hexColor);
            const colorHint:String = "RGB "+c[0]+","+c[1]+","+c[2];

            pickerColorSelected = true;

            if(mode === 1)
            {
                penColor = hexColor;//색깔이 다를때만
                updateOpaBoxColor(hexColor);
                updateOpacityCursor(penAlphaIndex);
                setHSVCursorPosByColor(hexColor);
            }
            else if(mode === 2)
            {
                setBackgroundColorDrawMode(hexColor);
                if(canvasWindowON) updateCanvasWindowCanvasPanelBGColor(CANVAS_BG_COLOR,canvasWindowBitmap.bitmapData);
                setHSVCursorPosByColor(hexColor);
                updateColorHistoryList();
                addUndoBGColor(hexColor);
            }

            _pickerBox.setRGBInfo(colorHint);
        }

        private function setTegakiPresetColor(targetName:String):void
        {
            const lastNumber:String = targetName.substr(6,1);
            const index:int = parseInt(lastNumber);
            const arr:Array = tegaKiPresetColor[index];

            penColor = arr[0];
            setBackgroundColorDrawMode(arr[1]);
            if(canvasWindowON) updateCanvasWindowCanvasPanelBGColor(CANVAS_BG_COLOR,canvasWindowBitmap.bitmapData);
            addUndoBGColor(arr[1]);

            if(!colorHistoryUpdateReady)
            {
                colorHistoryUpdateReady = true;
                stage.addEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryEvent);
            }

            if(pickerMode === 1)
            {
                setHSVCursorPosByColor(arr[0]);
            }
            else if(pickerMode === 2)
            {
                setHSVCursorPosByColor(arr[1]);
            }
        }

        private function isTrue2020File(file:File):Boolean
        {
            const fs:FileStream = new FileStream();
            isNewFOFOSaveFormat = false;
            fs.open(file,FileMode.READ);

            const header:String = fs.readUTFBytes(9);
            if(header === "FOFOPAINT")
            {
                isNewFOFOSaveFormat = true;
                fs.close();
                return true;
            }

            fs.close();
            fs.open(file,FileMode.READ);
            try
            {
                //구버전 파일 읽기 헤더가 없고 바로 배열임
                fs.readObject() as Array;
                fs.close();
                return true;
            }
            catch(err:Error)
            {
                fs.close();
                topBar.hintLoadError();
                return false;
            }

            return false;
        }

        private function is2020Ext(path:String):Boolean
        {
            const gif:int = path.lastIndexOf(".gif");
            const jpg:int = path.lastIndexOf(".jpg");
            const png:int = path.lastIndexOf(".png");
            const find2020:int = path.lastIndexOf(".2020");
            const maxIndex:int = Math.max(gif,jpg,png,find2020);

            return maxIndex === find2020;
        }

        private function cFillPenTool():Object
        {
            const _dottedLine:Object = dottedLine;
            const floor:Function = Math.floor;
            const cd:Shape = canvas2Draw;
            const cdg:Graphics = cd.graphics;
            const lastMousePos:Point = new Point(0,0);

            var canvasSizeRect:Rectangle = new Rectangle();

            var clickedButton:String;
            var command:Vector.<int>;
            var data:Vector.<Number>;
            var xColor:uint;
            var xAlpha:Number;
            var commandUndoIndexArr:Array;
            var mouseMoved:Boolean;
            var mouseMoveCount:int;
            var afterKeyUpOK:Boolean;
            var _sharpLine:Boolean;
            var rotateFlag:Boolean;
            var xOffset:Number;

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
                const g:Graphics = cd.graphics;
                const dataLen:int = data.length;

                g.clear();
                if(dataLen === 0) return;
                g.lineStyle(1,xColor);
                g.beginFill(xColor);
                g.drawPath(command,data);
                g.endFill();
                g.moveTo(data[dataLen-2],data[dataLen-1]);
                g.lineTo(data[0],data[1]);
            }

            function drawPreviewLine():void
            {
                const _data:Vector.<Number> = data;
                const g:Graphics = cdg;
                const len:int = _data.length;
                var x:Number = _data[0];
                var y:Number = _data[1];

                g.clear();
                if(len <= 3) return;

                _dottedLine.ready(g,x,y);

                for(var i:int=2; i<len; i+=2)
                {
                    x = _data[i];
                    y = _data[i+1];
                    _dottedLine.draw(g,x,y);
                }
                _dottedLine.draw(g,data[0],data[1]);
            }

            function cancelFillPen():void
            {
                removeEvents();
                canvas2.alpha = 1.0;
                mouseMoveCount = 0;
                fillPenStarted = false;
                setFillpenUI(false);
                command.length = 0;
                data.length = 0;
                commandUndoIndexArr = [];
                cd.graphics.clear();

                if(traceMenuON) traceMenu.visible = true;
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
                    rDataBuffer.push(["fill3",xColor,xAlpha,null,command.concat(),data.concat(),airBrushON,airBrushSizeDrawMode]);
                    if(airBrushON)
                    {
                        setBlurCanvasBySizeDrawMode(airBrushSizeDrawMode);
                    }
                    drawFillPenData();
                }

                drawDone();

                cancelFillPen();
            }

            function undoData():void
            {
                if(command.length === 0) return;
                const commandIndex:int = commandUndoIndexArr[commandUndoIndexArr.length-1];

                command.splice(commandIndex,command.length);
                data.splice(commandIndex*2,data.length);
                commandUndoIndexArr.pop();

                if(command.length <= 1)
                {
                    command.length = 0;
                    data.length = 0;
                    commandUndoIndexArr = [0];
                    cd.graphics.clear();
                }
                else drawPreviewLine();
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

                if(keyCode === KEY.w || keyCode === KEY.i
                || keyCode === KEY.z || keyCode === KEY.dot)
                {
                    undoData();
                }
                else if(keyCode === KEY.q || keyCode === KEY.o
                || keyCode === KEY.enter)
                {
                    endFillPenOK();
                }
                else if(keyCode === KEY.esc || keyCode === KEY.backspace)
                {
                    cancelFillPen();
                }
            }

            function fillPenMouseUpEvent(e:MouseEvent):void
            {
                removeTimer("fillPenTimer");
                mouseDragON = false;
                mouseClickON = false;
                stageMouseMoveEvent.remove("fillPenMouseMoveEvent");

                const targetName:String = e.target.name;

                if(clickedButton === targetName)
                {
                    if(targetName === "fillPenOK") endFillPenOK();
                    else if(targetName === "fillPenCancel") cancelFillPen();
                    else if(targetName === "fillPenUndo") undoData();
                }
                else
                {
                    const now:Point = new Point(mouseX,mouseY);
                    const dist:Number = floor(Point.distance(now,lastMousePos));

                    mouseMoveCount += dist;
                    if(mouseMoveCount >= 30)
                    {
                        mouseMoveCount = 0;
                        commandUndoIndexArr.push(command.length-1);
                    }

                    lastMousePos.setTo(now.x,now.y);

                    if(afterKeyUpOK) endFillPenOK();
                    else if(mouseMoved) drawPreviewLine();
                }

                afterKeyUpOK = false;
                mouseMoved = false;
            }

            function fillPenMouseMoveEvent(e:MouseEvent):void
            {
                // if(readyAddUndoFlag === false) checkFillPenUndoReady();
                mouseMoved = true;

                var mx:Number = cd.mouseX;
                var my:Number = cd.mouseY;

                if(_sharpLine && rotateFlag === false)
                {
                    mx = floor(mx-xOffset)+xOffset;
                    my = floor(my-xOffset)+xOffset;
                }
                else
                {
                    mx = floor(mx*1000)/1000;
                    my = floor(my*1000)/1000;
                }

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
                if(mouseMoveCount >= 30)
                {
                    mouseMoveCount = 0;
                    commandUndoIndexArr.push(command.length-1);
                }
                lastMousePos.setTo(mouseX,mouseY);

                if(!hasTimer("fillPenTimer"))
                {
                    addTimerByName("fillPenTimer",0.083,false,drawPreviewLine);
                }
            }

            function fillPenMouseDownEvent(e:MouseEvent):void
            {
                const targetName:String = e.target.name;

                if(targetName === "fillPenOK"
                || targetName === "fillPenUndo"
                || targetName === "fillPenCancel")
                {
                    clickedButton = targetName;
                }
                else if(isCursorInDrawArea())
                {
                    stageMouseMoveEvent.add("fillPenMouseMoveEvent",fillPenMouseMoveEvent);
                    clickedButton = null;

                    var mx:Number = cd.mouseX;
                    var my:Number = cd.mouseY;

                    if(_sharpLine && rotateFlag === false)
                    {
                        mx = floor(mx-xOffset)+xOffset;
                        my = floor(my-xOffset)+xOffset;
                    }
                    else
                    {
                        mx = floor(mx*100)/100;
                        my = floor(my*100)/100;
                    }

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
                    drawPreviewLine();
                    mouseDragON = true;

                    // if(readyAddUndoFlag === false) checkFillPenUndoReady();
                }
            }

            function removeEvents():void
            {
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,fillPenMouseDownEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,fillPenMouseUpEvent);
                stage.removeEventListener(KeyboardEvent.KEY_UP,fillPenKeyUpEvent);
                stageMouseMoveEvent.remove("fillPenMouseMoveEvent");
            }

            function addEvents():void
            {
                stage.addEventListener(MouseEvent.MOUSE_DOWN,fillPenMouseDownEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,fillPenMouseUpEvent);
                stage.addEventListener(KeyboardEvent.KEY_UP,fillPenKeyUpEvent);
                stageMouseMoveEvent.add("fillPenMouseMoveEvent",fillPenMouseMoveEvent);
            }

            function start():void
            {
                fillPenStarted = true;

                canvasSizeRect.width = CANVAS_WIDTH;
                canvasSizeRect.height = CANVAS_HEIGHT;

                command = new Vector.<int>();
                data = new Vector.<Number>();

                mouseMoved = false;
                mouseMoveCount = 0;
                afterKeyUpOK = false;
                clickedButton = null;
                _sharpLine = sharpLineON;
                rotateFlag = (regPoint.rotation % 90 === 0) ? false : true;
                xOffset = (sizeOffsetFlag) ? 0.5 : 0;

                xColor = penColor;
                xAlpha = penAlpha;
                commandUndoIndexArr = [0];

                if(airBrushON || eraseAirBrushON)
                {
                    clearArrayElement(canvas2Draw.filters);
                    canvas2Draw.filters.length = 0;
                    canvas2Draw.filters = null;
                }

                if(traceMenuON) traceMenu.visible = false;
                _dottedLine.updateScale(zoomed);

                var mx:Number = cd.mouseX;
                var my:Number = cd.mouseY;

                command.push(1);
                data.push(mx);
                data.push(my);
                lastMousePos.setTo(mx,my);

                setFillpenUI(true);
                canvas2.alpha = 1.0;
                addEvents();
            }

            return {
                start:start,
                ok:endFillPenOK,
                cancel:cancelFillPen
            };
        }

        private function cPenTool():Function
        {
            const cd:Shape = canvas2Draw;
            const floor:Function = Math.floor;
            const cdg:Graphics = cd.graphics;
            const clickPos:Point = new Point(); //점찍어 줄 때 판단하는 클릭한 자리 저장
            const smoothPos:Point = new Point(); //펜 스무딩에서 커서 뒤에 따라가는 실제 선의 죄표를 저장
            const smoothLast:Point = new Point(); //펜 스무딩에서 현재 마우스 커서 위치를 저장
            const moveEventLast:Point = new Point();
            const moveEventDistSave:Point = new Point();
            const sqPenCursorLast:Point = new Point();
            const sqLinePosLast:Point = new Point();
            const extendedPos:Point = new Point();
            const penCommand:Vector.<int> = new Vector.<int>(); //그냥펜
            const penPoints:Vector.<Number> = new Vector.<Number>(); //그냥펜 좌표
            const canvasSizeRect:Rectangle = new Rectangle();

            var initFlag:Boolean = false;
            var penToolFlag:Boolean;
            var xSize:uint;
            var xColor:uint;
            var xAlpha:Number;
            var xShape:Boolean;
            var xBlendMode:String;
            var xAirBrushON:Boolean;
            var rotateFlag:Boolean;
            var xOffset:Number;
            var _penSmoothValue:Number;//펜 스무딩 플래그
            var _penSmoothSlideValue:int;
            var mouseMoveCount:uint; //마우스 이벤트에서 움직일때 올려주는 카운터 한번에 너무 많이 움직여주면 cpu부하 먹어서 100카운트 마다 bmp에 그려줌
            var mouseMovedFlag:Boolean;
            var tempDoneFlag:Boolean;
            var moveEventDistLimit:Number;//penmove에서 distlimit이하이면 jump해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌
            var subLayerFlag:Boolean;
            var penSmoothTimer:int;

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

            function checkPixelPerfect():void
            {
                const command:Vector.<int> = penCommand;

                if(command.length > 2)
				{
                    const data:Vector.<Number> = penPoints;
					var len:uint = command.length;

					var i_:int = (len-3)*2;//뒤에 있는값
					var x_:Number = data[i_];
					var y_:Number = data[i_+1];

					const midIndex:int = (len-2);
					var i:int = midIndex*2; //중간값
					var x:Number = data[i];
					var y:Number = data[i+1];

					var _i:int = (len-1)*2; //앞에있는값
					var _x:Number = data[_i];
					var _y:Number = data[_i+1];

                    //L모양이 나오면 중간값을 없애줌
					if((x_ == x || y_ == y)
					&& (_x == x || _y == y)
					&& _x != x_
					&& _y != y_)
					{
						command.splice(midIndex,1);
						data.splice(i,2);

                        //이게 정확할런지 모르겠다
                        rDataBuffer.splice(rDataBuffer.length-2,1);

						cdg.clear();
                        lineStyleReady(xShape,xSize,xColor,xAlpha);
                        cdg.moveTo(data[0],data[1]);

                        len = command.length;
                        for(var j:int=1; j<len; j++)
                        {
                            cdg.lineTo(data[j*2],data[j*2+1]);
                        }
					}
				}
            }

            function lineStyleReady(shape:Boolean,size:uint,color:uint,alpha:Number):void
            {
                canvas2.alpha = alpha;

                if(shape === false)
                {
                    cdg.lineStyle(size,color);
                }
                else
                {
                    cdg.lineStyle(size,color,1,false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.BEVEL);
                }
            }

            function followCursorSmoothLine():void
            {
                var ox:Number = smoothPos.x;
                var oy:Number = smoothPos.y;

                ox += (smoothLast.x-ox)*_penSmoothValue;
                oy += (smoothLast.y-oy)*_penSmoothValue;

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

            function penMove2(mx:Number,my:Number):void
            {
                if(readyAddUndoFlag === false)
                {
                    checkPenToolUndoReady();
                }

                if(!sharpLineON && (_penSmoothSlideValue > 0 || rotateFlag))
                {
                    mx = floor(mx*100)/100;
                    my = floor(my*100)/100;
                }
                else
                {
                    mx = floor(mx-xOffset)+xOffset;
                    my = floor(my-xOffset)+xOffset;
                }

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
                    lineStyleReady(xShape,xSize,xColor,xAlpha);

                    if(xShape)
                    {
                        updateExtendEndPoint(mx,my,clickPos.x,clickPos.y,xSize/4);
                        rDataBuffer.push(["lineStyle3",xShape,xSize,xColor,xAlpha,extendedPos.x,extendedPos.y,xBlendMode,false,subLayerFlag,xAirBrushON]);
                        penPoints.push(extendedPos.x);
                        penPoints.push(extendedPos.y);
                        cdg.moveTo(extendedPos.x,extendedPos.y);
                    }
                    else
                    {
                        rDataBuffer.push(["lineStyle3",xShape,xSize,xColor,xAlpha,smoothPos.x,smoothPos.y,xBlendMode,false,subLayerFlag,xAirBrushON]);
                        penPoints.push(smoothPos.x);
                        penPoints.push(smoothPos.y);
                        cdg.moveTo(smoothPos.x,smoothPos.y);
                    }
                }

                ++mouseMoveCount;

                rDataBuffer.push(["lineTo",mx,my]);
                penCommand.push(2);
                penPoints.push(mx);
                penPoints.push(my);
                cdg.lineTo(mx,my);

                if(sharpLineON === true && _penSmoothSlideValue === 0 && rotateFlag == false)
                {
                    checkPixelPerfect();
                }

                if(mouseMoveCount >= 100)
                {
                    mouseMoveCount = 0;
                    tempDoneFlag = true;

                    if(xAirBrushON && zoomed !== 1.0)
                    {
                        setBlurCanvasBySizeNoZoomDrawMode();
                        canvas2BitmapData.draw(cd,null,null,"layer");
                        canvas2Bitmap.bitmapData = canvas2BitmapData;
                        cdg.clear();
                        setBlurCanvasBySizeDrawMode(airBrushSizeDrawMode);
                    }
                    else
                    {
                        canvas2BitmapData.draw(cd,null,null,"layer");
                        canvas2Bitmap.bitmapData = canvas2BitmapData;
                        cdg.clear();
                    }

                    lineStyleReady(xShape,xSize,xColor,xAlpha);
                    const prevX:Number = penPoints[penPoints.length-4];
                    const prevY:Number = penPoints[penPoints.length-3];

                    penCommand.length = 0;
                    penPoints.length = 0;
                    rDataBuffer.push(["tempDone"]);

                    if(xShape === true)
                    {
                        rDataBuffer.push(["lineStyle3",xShape,xSize,xColor,xAlpha,prevX,prevY,xBlendMode,false,subLayerFlag,xAirBrushON]);
                        penCommand.push(1);
                        penPoints.push(prevX);
                        penPoints.push(prevY);
                        cdg.moveTo(prevX,prevY);
                    }
                    else
                    {
                        rDataBuffer.push(["lineStyle3",xShape,xSize,xColor,xAlpha,mx,my,xBlendMode,false,subLayerFlag,xAirBrushON]);
                        penCommand.push(1);
                        penPoints.push(mx);
                        penPoints.push(my);
                        cdg.moveTo(mx,my);
                    }
                }

                if(xShape === true)
                {
                    const rad:Number = Math.atan2(mx-sqPenCursorLast.x,my-sqPenCursorLast.y);
                    const deg:Number = -rad*(180/Math.PI)+regPoint.rotation;

                    penSizeCursor.rotation = deg;
                    sqPenCursorLast.x = mx;
                    sqPenCursorLast.y = my;
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
                const mx:Number = cd.mouseX+xOffset;
                const my:Number = cd.mouseY+xOffset;

                if(penToolMouseMoveLimit(mx,my)) return;

                if(penToolFlag && _penSmoothSlideValue > 1)
                {
                    var ox:Number = smoothPos.x;
                    var oy:Number = smoothPos.y;

                    ox += (smoothLast.x-smoothPos.x)*_penSmoothValue;
                    oy += (smoothLast.y-smoothPos.y)*_penSmoothValue;

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

            //끝 부분점을 distance만큼 길게 늘임
            function updateExtendEndPoint(x1:Number,y1:Number,x2:Number,y2:Number,distance:Number):void
            {
                // 선분 방향 벡터 계산
                var directionX:Number = x2 - x1;
                var directionY:Number = y2 - y1;

                // 선분 길이 계산
                var length:Number = Math.sqrt(directionX * directionX + directionY * directionY);

                // 선분 방향 벡터 정규화
                var normalizedDirectionX:Number = directionX / length;
                var normalizedDirectionY:Number = directionY / length;

                extendedPos.setTo(x2 + normalizedDirectionX * distance,y2 + normalizedDirectionY * distance)
            }

            function penToolMouseUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, penToolMouseUpEvent);
                stageMouseMoveEvent.remove("penToolMouseMoveEvent");

                const xx:Number = cd.mouseX;
                const yy:Number = cd.mouseY;
                const mx:Number = xx+xOffset;
                const my:Number = yy+xOffset;

                if(penToolFlag && traceMemoryTraining && CANVAS_TRACE_ALPHA > 0.0)
                {
                    canvasTraceLayer.visible = true;
                }

                if(_penSmoothSlideValue > 1)
                {
                    removeTimer("followCursorSmoothLine");
                }

                if(xShape === true)
                {
                    penSizeCursor.rotation = regPoint.rotation;

                    if(mouseMovedFlag === true)
                    {
                        const pointLen:uint = penPoints.length;
                        if(pointLen >= 4)
                        {
                            updateExtendEndPoint(penPoints[pointLen-4],penPoints[pointLen-3],penPoints[pointLen-2],penPoints[pointLen-1],xSize/4);
                            rDataBuffer.push(["lineTo",extendedPos.x,extendedPos.y]);
                            cdg.lineTo(extendedPos.x,extendedPos.y);
                        }
                    }
                }

                if(mouseMovedFlag === false || (penToolFlag && mouseMovedFlag === true && Point.distance(smoothPos,clickPos) < 0.2))
                {
                    rDataBuffer.length = 0;
                    rDataBuffer.push(["dot",xShape,xSize,xColor,xAlpha,clickPos.x,clickPos.y,xBlendMode,subLayerFlag,xAirBrushON]);
                    drawDot(xShape,xSize,xColor,clickPos.x,clickPos.y);
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
                    xColor = penColor;
                    xAlpha = penAlpha;
                    xShape = penShape;
                    xBlendMode = null;
                    xAirBrushON = airBrushON;
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
                    xShape = false;
                }

                if(penFlag && traceMemoryTraining)
                {
                    canvasTraceLayer.visible = false;
                }

                subLayerFlag = (penFlag) ? subLayerON : false;
                rotateFlag = (regPoint.rotation % 90 === 0) ? false : true;
                xOffset = (sizeOffsetFlag) ? 0.5 : 0;
                _penSmoothValue = penSmoothValue;//펜 스무딩 플래그
                _penSmoothSlideValue = penSmoothSlideValue;
                mouseMoveCount = 0; //마우스 이벤트에서 움직일때 올려주는 카운터 한번에 너무 많이 움직여주면 cpu부하 먹어서 100카운트 마다 bmp에 그려줌
                mouseMovedFlag = false;
                tempDoneFlag = false;
                canvasSizeRect.width = CANVAS_WIDTH;
                canvasSizeRect.height = CANVAS_HEIGHT;

                clickPos.setTo(cd.mouseX,cd.mouseY); //점찍어 줄 때 판단하는 클릭한 자리 저장

                if(_penSmoothSlideValue === 0)
                {
                    smoothPos.setTo(floor(cd.mouseX-xOffset)+xOffset,floor(cd.mouseY-xOffset)+xOffset);
                }
                else
                {
                    smoothPos.setTo(cd.mouseX+xOffset,cd.mouseY+xOffset);
                }

                smoothLast.copyFrom(smoothPos); //penmove할때 마지막x y저장
                moveEventLast.copyFrom(smoothPos);
                sqPenCursorLast.copyFrom(smoothPos);
                sqLinePosLast.copyFrom(smoothPos);

                moveEventDistLimit = xSize/5;//penmove에서 distlimit이하이면 jump해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌

                if(readyAddUndoFlag === false)
                {
                    checkPenToolUndoReady();
                }

                stageMouseMoveEvent.add("penToolMouseMoveEvent",penToolMouseMoveEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,penToolMouseUpEvent);
            };
        }

        private function stageMouseLeaveEvent(e:Event):void
        {
            mouseClickON = false;
            rightMouseClickON = false;
            mouseDragON = false;

            setControlBoxInfoOFF();
            setTopBarHintOFF();

            if(resizeCanvas.isCanvasResizing())
            {
                resizeCanvas.exit(true);
            }
            if(toolBox2ON)
            {
                closeToolBox2();
            }

            mouseLeaveSideBarON();
        }

        private function updatePenCursorPositionEvent(e:MouseEvent):void
        {
            realWorkingTimer.resetAFKCount();

            if(replayModeON || captureModeON) return;

            updatePenCursorPosition();
        }

        private function cUpdatePenCursorPosition():Object
        {
            const _penSizeCursor:Shape = penSizeCursor;
            const useCursorTool:int = TOOL_LINE;
            const _isPenTool:Boolean = isPenOrLineTool();
            const _isEraseTool:Boolean = isEraseTool();
            var zoomed:Number = 1.0;
            var cursorSize:Number = 3.0;
            var mouseDownEventON:Boolean;
            var sidebarTempOFF:Boolean;
            var visibleMouseUpEventON:Boolean;
            var mx:Number = 0;
            var my:Number = 0;

            function updateCursorSize(size:Number):void
            {
                cursorSize = size*zoomed;
            }

            function updateZoom(z:Number):void
            {
                zoomed = z;

                if(_isPenTool) cursorSize = penSize*z;
                else if(_isEraseTool) cursorSize = eraseSize*z;
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
                stage.addEventListener(MouseEvent.MOUSE_UP,sidebarONMouseUpEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,sidebarONMouseUpEvent);
                stage.addEventListener(MouseEvent.MOUSE_DOWN,sidebarONMouseDownEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,sidebarONMouseDownEvent);
            }

            function setSideBarClickEvents():void
            {
                mouseDownEventON = true;
                stage.addEventListener(MouseEvent.MOUSE_DOWN,sidebarOFFMouseDownEvent,false,1);
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
                if(isHitTestPoint(sideBar) === false)
                {
                    removeSideBarClickEvents();
                }
            }

            //클릭한 상태로 sidebar on틀어줬을때 1초정도 켜지지 않게함
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
                setSidebarONDelay();
            }

            function sidebarOFFRightMouseDownEvent(e:MouseEvent):void
            {
                clickBlockFlag = true;
                setClickBlockFlagOFFDelay();

                setSideBarOFF();
            }

            function sidebarOFFMouseDownEvent(e:MouseEvent):void
            {
                if(e.target && (e.target.name === "sideBarONButton" || e.target.name === "sideBarONButton2"))
                {

                }
                else if(isHitTestPoint(sideBar) === false)
                {
                    setSideBarOFF();
                }
            }

            function checkSideBarON():void
            {
                if(resizeButtonR.visible) return;

                if(!mouseClickON && !rightMouseClickON)
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
                mx = mouseX;
                my = mouseY;

                if(penCursorOFFFlag
                || (nowTool > useCursorTool && nowTool !== TOOL_FILL_PEN) //1 2 3 4 펜 지우개 라인툴 라인-지우개툴
                || !(mx >= STAGE_LEFT_OFFSET &&
                    mx <= stage.stageWidth-STAGE_RIGHT_OFFSET &&
                    my >= STAGE_TOP_OFFSET &&
                    my <= stage.stageHeight-STAGE_BOTTOM_OFFSET)
                || quickSidebarON
                || resizeCanvas.isCanvasResizing()
                || (traceMenu.visible && traceMenu.hitTestPoint(mouseX,mouseY))
                || (sideBarScrollBar.visible && sideBarScrollBar.hitTestPoint(mouseX,mouseY)))
                {
                    _penSizeCursor.visible = false;
                }
                else
                {
                    //addundo플래그가 커서가 캔버스 안에 들어올때 해주기 때문에 위치를 계속 갱신해줘야함
                    _penSizeCursor.x = mx;
                    _penSizeCursor.y = my;

                    if(cursorSize <= 4 || isNowTool(TOOL_FILL_PEN))
                    {
                        _penSizeCursor.visible = false;
                    }
                    else
                    {
                        _penSizeCursor.visible = true;
                    }
                }

                if(isSidebarVisible === false && clickBlockFlag === false)
                {
                    if((!isRightSidebar && mx <= 15 || isRightSidebar && mx >= stage.stageWidth-15)
                    && my > STAGE_TOP_OFFSET)
                    {
                        checkSideBarON();
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
            const _topBar:topMenu = topBar;
            const floor:Function = Math.floor;
            var started:Boolean = false;
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
                _topBar.timer.text = "00:00:00";
                _topBar.timer.width = _topBar.timer.textWidth+10;
                _topBar.updateTimerPos(stage.stageWidth);
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
                tt = appRunningTime/1000;
                hh = floor(tt/3600);
                mm = floor((tt-hh*3600)/60);
                ss = floor(tt%60);

                _topBar.timer.text = ((hh < 10) ? "0"+hh:""+hh) + ":"
                                    +((mm < 10) ? "0"+mm:""+mm) + ":"
                                    +((ss < 10) ? "0"+ss:""+ss);
                _topBar.timer.width = _topBar.timer.textWidth+10;
                _topBar.updateTimerPos(stage.stageWidth);
            }

            function check(e:Event):void
            {
                const nowTime:int = getTimer();
                const subTime:int = nowTime-lastTime;

                if(subTime >= 1000)
                {
                    if(afkCount >= 5000)
                    {
                        afkCount = 5000;
                    }
                    else
                    {
                        appRunningTime += subTime;
                        update();
                    }

                    afkCount += subTime;
                    lastTime = nowTime;
                }
            }

            function stop():void
            {
                started = false;
                afkCount = 0;
                stage.removeEventListener(Event.ENTER_FRAME,check);
            }

            function start():void
            {
                if(started) return;
                lastTime = getTimer();
                started = true;
                stage.addEventListener(Event.ENTER_FRAME,check);
            }

            return {
                start:start,
                stop:stop,
                reset:reset,
                update:update,
                resetAFKCount:resetAFKCount,
                getRunningTime:getRunningTime,
                setRunningTime:setRunningTime
            }
        }

		private function makeTransBG():void
        {
            const checkShape:Shape = new Shape();
            var g:Graphics = checkShape.graphics;

            g.beginFill(0xCCCCCC);
            g.drawRect(0,0,8,8);
            g.drawRect(8,8,8,8);
            g.endFill();

            transBGBMPD.draw(checkShape);
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
                const pow:Function = Math.pow;
				var r:Number = ((rgb & 0xFF0000) >>> 16) / 255;
				var g:Number = ((rgb & 0x00FF00) >>> 8) / 255;
				var b:Number = ((rgb & 0x0000FF)) / 255;
				var x:Number, y:Number, z:Number;

				r = (r > 0.04045) ? pow((r + 0.055) / 1.055, 2.4) : r / 12.92;
				g = (g > 0.04045) ? pow((g + 0.055) / 1.055, 2.4) : g / 12.92;
				b = (b > 0.04045) ? pow((b + 0.055) / 1.055, 2.4) : b / 12.92;
				x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047;
				y = (r * 0.2126 + g * 0.7152 + b * 0.0722) / 1.00000;
				z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883;
				x = (x > 0.008856) ? pow(x, 1/3) : (7.787 * x) + 16/116;
				y = (y > 0.008856) ? pow(y, 1/3) : (7.787 * y) + 16/116;
				z = (z > 0.008856) ? pow(z, 1/3) : (7.787 * z) + 16/116;

                const result:Vector.<Number> = new <Number> [(116 * y) - 16, 500 * (x - y), 200 * (y - z)];

				return result;
			}

            const sqrt:Function = Math.sqrt;
			const labA:Vector.<Number> = rgb2lab(rgbA);
			const labB:Vector.<Number> = rgb2lab(rgbB);
			const deltaL:Number = labA[0] - labB[0];
			const deltaA:Number = labA[1] - labB[1];
			const deltaB:Number = labA[2] - labB[2];
			const c1:Number = sqrt(labA[1] * labA[1] + labA[2] * labA[2]);
			const c2:Number = sqrt(labB[1] * labB[1] + labB[2] * labB[2]);
			const deltaC:Number = c1 - c2;
			var deltaH:Number = deltaA * deltaA + deltaB * deltaB - deltaC * deltaC;
			deltaH = deltaH < 0 ? 0 : sqrt(deltaH);
			const sc:Number= 1.0 + 0.045 * c1;
			const sh:Number= 1.0 + 0.015 * c1;
			const deltaLKlsl:Number = deltaL / (1.0);
			const deltaCkcsc:Number = deltaC / (sc);
			const deltaHkhsh:Number = deltaH / (sh);
			const i:Number = deltaLKlsl * deltaLKlsl + deltaCkcsc * deltaCkcsc + deltaHkhsh * deltaHkhsh;

			return i < 0 ? 0 : sqrt(i);
		}

        private function resetZoomReplayMode():void
        {
            const center:Point = getStageCenterPos(CENTERPOS_DRAW);

            rzoomedIndex = zoomArr.indexOf(1.0);
            setRegPoint(center.x,center.y,true);
            autoScroll.updateRCanvasBounds();
            setZoomCanvas(1.0,true);
            setFitZoomedOFF();
        }

        private function resetZoomDrawMode(center:Point=null):void
        {
            if(!center) center = getStageCenterPos(CENTERPOS_DRAW);

            zoomedIndex = zoomArr.indexOf(1.0);
            setRegPoint(center.x,center.y,false);
            setZoomCanvas(1.0,false);
            updatePenSizeCursor();
            updatePreviewBoxRectPos();
        }

        private function setZoomInButton(zoomInFlag:Boolean,replayMode:Boolean):void
        {
            const xReg:Sprite = (replayMode) ? rregPoint : regPoint;
            const _zoomArr:Array = zoomArr;
            const zoomMax:int = _zoomArr.length-1;
            const floor:Function = Math.floor;
            const center:Point = getStageCenterPos(CENTERPOS_REPLAY);
            var lastZoomIndex:int = (replayMode) ? rzoomedIndex : zoomedIndex;

            if(zoomInFlag)
            {
                lastZoomIndex++;
                if(lastZoomIndex > zoomMax)
                    lastZoomIndex = zoomMax;
            }
            else
            {
                lastZoomIndex--;
                if(lastZoomIndex < 0)
                    lastZoomIndex = 0;
            }

            const newZoom:Number = _zoomArr[lastZoomIndex];

            if(replayMode)
            {
                setFitZoomedOFF();
                rzoomedIndex = lastZoomIndex;
                setRegPoint(center.x,center.y,true);
                autoScroll.updateRCanvasBounds();
                setZoomCanvas(newZoom,replayMode);
            }
            else
            {
                zoomedIndex = lastZoomIndex;
                setOptimizeCanvasMove(false);
                setRegPoint(center.x,center.y,false);
                setZoomCanvas(newZoom,replayMode);
                updatePenSizeCursor();
                updatePreviewBoxRectPos();
            }
        }

        private function checkKeyUp(keyCode:uint):void
        {
            if(keyBuffer.length === 0) resetNowKey();
            else if(isNowKey(keyCode)) keyDownLassoTool(null);
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
            const keyCode:int = keyBuffer[0];
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
                            if(zoomed !== 1.0) resetZoomDrawMode(lassoBox.localToGlobal(new Point(0,0)));
                        return;
                    }
                });
                if(keyUsed) return;
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

                case KEY.esc:
                case KEY.backspace:
                    setLassoCancelButton();
                break;
            }
        }

        private function setSideBarPositionButton():void
        {
            const _sideBar:sidePanel = sideBar;

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
            const gp:Point = canvas1Bitmap.globalToLocal(new Point(STAGE_LEFT_OFFSET,STAGE_TOP_OFFSET));
            const zoom:Number = zoomed;

            previewBox.updateCursor(gp.x*zoom,gp.y*zoom
                                    ,stage.stageWidth-STAGE_LEFT_OFFSET-STAGE_RIGHT_OFFSET
                                    ,stage.stageHeight-STAGE_TOP_OFFSET-STAGE_BOTTOM_OFFSET
                                    ,CANVAS_WIDTH*zoom,regPoint.rotation);
        }

        private function setHandToolPreviewBox(cursorClicked:Boolean):void
        {
            const floor:Function = Math.floor;
            const cursor:Sprite = previewBox.prevCursor;
            var sx:Number = previewBox.mouseX;
            var sy:Number = previewBox.mouseY;
            const _regPoint:Sprite = regPoint;
            const prevToCanvasMultiply:Number = previewBox.prevCursorMultiply

            setOptimizeCanvasMove(true);

            function setCenter(x:Number,y:Number):void
            {
                const b:Object = getBoundRect(cursor);
                //prevToCanvasMultiply를 나눠 줘야 커서랑 같은 속도가 나옴
                const rectCenterX:Number = b.left+(b.right-b.left)/2;
                const rectCenterY:Number = b.top+(b.bottom-b.top)/2;
                var moveX:Number = floor((rectCenterX-x)/prevToCanvasMultiply);
                var moveY:Number = floor((rectCenterY-y)/prevToCanvasMultiply);
                var p:Point = rotatePoint(moveX,moveY,-regPoint.rotation);

                _regPoint.x += p.x;
                _regPoint.y += p.y;

                updatePreviewBoxRectPos();
            }

            function setHandToolMouveUpEvent(e:MouseEvent):void
            {
                setOptimizeCanvasMove(false);
                checkCanvasPanelPos();
                updatePreviewBoxRectPos();
                mouseClickON = false;
                mouseDragON = false
                stageMouseMoveEvent.remove("setHandToolMouseMoveEvent");
                stage.removeEventListener(MouseEvent.MOUSE_UP,setHandToolMouveUpEvent);
            }

            function setHandToolMouseMoveEvent(e:MouseEvent):void
            {
                var mx:Number = previewBox.mouseX;
                var my:Number = previewBox.mouseY;
                //prevToCanvasMultiply를 곱해줘야 커서랑 같은 속도가 나옴
                var moveX:Number = floor((sx-mx)/prevToCanvasMultiply);
                var moveY:Number = floor((sy-my)/prevToCanvasMultiply);
                var p:Point = rotatePoint(moveX,moveY,-regPoint.rotation);

                _regPoint.x += p.x;
                _regPoint.y += p.y;

                sx = mx;
                sy = my;

                updatePreviewBoxRectPos();
            }
            setRegPoint(0,0);

            //클릭한 지점이 커서 바깥부분일때 강제로 캔버스 중심으로 옮겨줌
            if(!cursorClicked)
            {
                setCenter(mouseX,mouseY);
            }

            stageMouseMoveEvent.add("setHandToolMouseMoveEvent",setHandToolMouseMoveEvent)
            stage.addEventListener(MouseEvent.MOUSE_UP,setHandToolMouveUpEvent)
        }
        //원점 penSmoothX oy로부터 dx쪽으로 dist 만큼 떨어진 거리 점을 리턴함
        private function movePointAngleDist(ox:Number,oy:Number,dx:Number,dy:Number,dist:Number):Point
        {
            const rad:Number = Math.atan2(dx-ox,dy-oy);

            return new Point(ox+dist*Math.sin(rad)
                            ,oy+dist*Math.cos(rad));
        }

        private function forceSetMainDrawTool():void
        {
            if(!(isPenOrLineTool() || isNowTool(TOOL_FILL_PEN)))
            {
                resetOldTool();
                selectPenTool();
                updatePenSizeCursor();
            }
        }

        private function initPickerBoxInfo(color:uint):void
        {
            const _pickerBox:colorPickerBox = pickerBox;
            const rgbColor:Vector.<uint> = HEXtoRGB(color);
            const r:uint = rgbColor[0];
            const g:uint = rgbColor[1];
            const b:uint = rgbColor[2];
            const colorHint:String =  "RGB "+r+","+g+","+b;

            _pickerBox.setRGBInfo(colorHint);
            _pickerBox.setRGBInfoColor(getInvertColor(color,1.0
            ,(uiColorIndex >= 2) ? uiColorSet[uiColorIndex][0]:uiColorSet[uiColorIndex][1]
            ,(uiColorIndex >= 2) ? uiColorSet[uiColorIndex][1]:uiColorSet[uiColorIndex][0]));
            _pickerBox.updateRGBInfoBG(color,setColorBorder(color));
            updatePickerCurrentColor(color);
        }

        private function setLassoTraceImageButton():void
        {
            const btn:SimpleButton = lassoMenu.lassoTrace;

            setTopChildIndex(lassoMenu);
            traceImageCount++;

            function setLassoTraceImageButtonCountResetEvent(e:MouseEvent):void
            {
                traceImageCount = 0;
                btn.removeEventListener(MouseEvent.MOUSE_OUT,setLassoTraceImageButtonCountResetEvent);
            }

            if(traceImageCount === 1)
            {
                lassoMenu.hint(STRING_ONEMORE_CLICK_TO_OK);
                btn.addEventListener(MouseEvent.MOUSE_OUT,setLassoTraceImageButtonCountResetEvent);
            }
            else if(traceImageCount === 2)
            {
                traceImageCount = 0;
                btn.removeEventListener(MouseEvent.MOUSE_OUT,setLassoTraceImageButtonCountResetEvent);
                traceMenu.hint(STRING_MERGE_LASSO_IMAGE_TO_TRACE);
                mergeLassoImageToTraceLayer();
                openTraceWindow();
            }
        }

        private function setTraceImageButton():void
        {
            const btn:SimpleButton = traceMenu.traceImageButton;
            if(btn.alpha !== 1.0) return;

            setTopChildIndex(traceMenu);
            traceImageCount++;

            function setTraceImageButtonCountResetEvent(e:MouseEvent):void
            {
                traceImageCount = 0;
                btn.removeEventListener(MouseEvent.MOUSE_OUT,setTraceImageButtonCountResetEvent);
            }

            if(traceImageCount === 1)
            {
                traceMenu.hint(STRING_ONEMORE_CLICK_TO_OK);
                btn.addEventListener(MouseEvent.MOUSE_OUT,setTraceImageButtonCountResetEvent);
            }
            else if(traceImageCount === 2)
            {
                traceImageCount = 0;
                btn.removeEventListener(MouseEvent.MOUSE_OUT,setTraceImageButtonCountResetEvent);
                traceMenu.hint(STRING_MERGE_CANVAS_IMAGE_TO_TRACE);
                pasteTraceImage();
            }
        }

        private function setPresetColor(target:Sprite,bgFlag:Boolean):void
        {
            if(!target) return;

            const hexColor:uint = target.transform.colorTransform.color;
            const _setColorTransform:Function = setColorTransform;
            const c:Vector.<uint> = HEXtoRGB(hexColor);
            const colorHint:String = "RGB "+c[0]+","+c[1]+","+c[2];

            setHSVCursorPosByColor(hexColor);

            if(bgFlag === false)
            {
                penColor = hexColor;
                updateOpaBoxColor(hexColor);
                updateOpacityCursor(penAlphaIndex);
                forceSetMainDrawTool();
            }
            else if(bgFlag === true)
            {
                updateColorHistoryList();
                setBackgroundColorDrawMode(hexColor);
                if(canvasWindowON) updateCanvasWindowCanvasPanelBGColor(CANVAS_BG_COLOR,canvasWindowBitmap.bitmapData);
                addUndoBGColor(hexColor);
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
                case "traceCancelButton":str = "Close"; break;
                case "traceImageButton":str = STRING_MERGE_CANVAS_IMAGE_TO_TRACE; break;
                case "traceLoadButton":str = "Paste image from file"; break;
                case "traceClipButton":str = "Paste image from clipboard"; break;
                case "traceButtonWrapper":str = "Adjust opacity"; break;
                case "traceRotateButton":str = "Rotate image\n("+STRING_RIGHT_CLICK_TO_RESET+")"; break;
                case "traceMoveButton":str = "Move image\n("+STRING_RIGHT_CLICK_TO_RESET+")"; break;
                case "traceResizeButton":str = "Resize image\n("+STRING_RIGHT_CLICK_TO_RESET+")"; break;
                case "traceCancelButton":str = "Close"; break;
                case "traceMirrorButton":str = "Flip image"; break;
                case "traceVisibleONButton":
                case "traceVisibleOFFButton":str = "Memory training ON/OFF"; break;
                case "traceDeleteButton":str = "Erase reference image"; break;
                default:
                    traceMenu.hint("Reference layer");
                return;
            }

            traceMenu.hint(str);
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
            var str:String = "";

            switch(targetName)
            {
                case "lassoOK":str = "OK (enter, right-click)"; break;
                case "lassoCancel":str = "Cancel (esc, backspace)"; break;
                case "lassoCopy":str = "Copy image"; break;
                case "lassoCZoom":str = "Zoom canvas\nReset (Right-click, shift+w/i)"; break;
                case "lassoCRotate":str = "Rotate Canvas\nReset (Right-click, shift+s/k)"; break;
                case "lassoCHand":str = "Move canvas"; break;
                case "lassoRotate":str = "Rotate image\n("+STRING_RIGHT_CLICK_TO_RESET+")"; break;
                case "lassoMirror":str = "Flip image"; break;
                case "lassoResize":str = "Resize image\n("+STRING_RIGHT_CLICK_TO_RESET+")"; break;
                case "lassoTrace":str = STRING_MERGE_LASSO_IMAGE_TO_TRACE; break;
                case "lasso1pxLeft":
                case "lasso1pxRight":
                case "lasso1pxUp":
                case "lasso1pxDown":
                    str = "Move image 1px\n(space+wasd / ijkl)"
                break;

                default: lassoMenu.hint("Lasso tool");
                return;
            }

            lassoMenu.hint(str);
        }

        private function toolBoxHintOFFEvent(e:MouseEvent):void
        {
            if(toolBox.toolInfo.visible) toolBox.hintOFF();
            if(zoomToolHintON) zoomToolHintON = false;
        }

        private function getToolBox2Hint(targetName:String):String
        {
            var str:String = "";

            switch(targetName)
            {
                case "toolSidebar": str = "(s+d, j+k)"; break;
                case "toolPen": str = "Pen (q, o key up) "; break;
                case "toolFillPen": str = "Fill pen (q, o)"; break;
                case "toolErase": str = "Eraser (d, j)"; break;
                case "toolLasso": str = "Lasso (r, y)"; break;
                case "toolSpuit": str = "Eye dropper (c, m)"; break;
                case "toolUndo": str = "Undo (z, .)"; break;
                case "toolRedo": str = "Redo (x, ,)"; break;
                case "toolMirror": str = "Flip canvas (a, l)"; break;
                case "toolLine": str = "Line (shift)"; break;
                case "toolMove": str = "Move image (e, u)"; break;
                case "toolZoom": if(!toolBox.isZoomIconON()) str = "Zoom (w, i)"; break;
                case "toolRotate": str = "Rotate (s, k)"; break;
                case "toolTrace": str = "Reference layer (t)"; break;
            }

            return str;
        }

        private function getToolBoxHint(targetName:String):String
        {
            var str:String = "";

            switch(targetName)
            {
                case "toolSidebar": str = "Quick sidebar\n(s+d, j+k)"; break;
                case "fillPenOK": str = "OK\n(q, o, enter, right-click)"; break;
                case "fillPenCancel": str = "cancel\n(esc, backspace)"; break;
                case "fillPenUndo": str = "undo\n(w, z / i, .)"; break;
                case "toolPen": str = "Pen\n(q, o key up) "; break;
                case "toolFillPen": str = "Fill pen\n(q, o)"; break;
                case "toolErase": str = "Eraser\n(d, j)"; break;
                case "toolLasso": str = "Lasso\n(r, y)"; break;
                case "toolSpuit": str = "Eye dropper\n(c, m)"; break;
                case "toolUndo": str = "Undo\n(z, .)"; break;
                case "toolRedo": str = "Redo\n(x, ,)"; break;
                case "toolMirror": str = "Flip canvas\n(a, l)"; break;
                case "toolLine": str = "Line\n(shift)"; break;
                case "toolMove": str = "Move image\n(e, u)"; break;
                case "toolZoom": if(!toolBox.isZoomIconON()) str = "Zoom (w, i)\nReset (right-click, shift+w/i)"; break;
                case "zoomInButton": str ="Zoom in\nReset (right-click)"; break;
                case "zoomOutButton": str ="Zoom out\nReset (right-click)"; break;
                case "toolRotate": str = "Rotate (s, k)\nReset (right-click, shift+s/k)"; break;
                case "toolTrace": str = "Reference layer\n(t)"; break;
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
            if(!target || mouseClickON || mouseDragON || toolBox.alpha < 1.0 || target.alpha < 1.0) return;

            const hintStr:String = getToolBoxHint(target.name);

            if(hintStr === "")
            {
                toolTipBox.visible = false;
            }
            else
            {
                toolBox.hint(hintStr,(e.target as SimpleButton),isRightSidebar);
            }
        }

        private function changeTopBarIcons(mode:String="draw"):void
        {
            if(lassoToolON === true || aboutPanelON === true)
            {
                return;
            }

            const tb:topMenu = topBar;
            tb.hintOFF();
            setTopChildIndex(tb);

            const buttonSetVisible:Function = tb.buttonSetVisible;

            buttonSetVisible(mode,true,isRightSidebar,isSidebarVisible);
            tb.updateButtonVisible(false);

            if(mode === "draw")
            {
                buttonSetVisible("replay",false);
                buttonSetVisible("capture",false);
                tb.changeHintYPos(tb.BARSIZE);
                updatePenSizeCursor();
                if(needUpdate) tb.updateButtonVisible(true);

                if(canvasWindowON) topBar.newWindowButton.visible = false;
                else topBar.newWindowCloseButton.visible = false;
            }
            else if(mode === "replay")
            {
                const _replayTimeBox:replayTimeBar = replayTimeBox;
                buttonSetVisible("draw",false,isRightSidebar);
                buttonSetVisible("capture",false);

                if(replayStartON)
                {
                    _replayTimeBox["playButton"].visible = false;
                    _replayTimeBox["pauseButton"].visible = true;
                }
                else
                {
                    _replayTimeBox["playButton"].visible = true;
                    _replayTimeBox["pauseButton"].visible = false;
                }
                tb.changeHintYPos(tb.BARSIZE+_replayTimeBox.BARSIZE-4);
            }
            else if(mode === "capture")
            {
                buttonSetVisible("replay",false);
                buttonSetVisible("draw",false,isRightSidebar);
                tb.changeHintYPos(tb.BARSIZE);

                if(canvas1Bitmap.visible)
                {
                    tb.capLayer1VisibleButton.alpha = 1.0;
                }
                else
                {
                    tb.capLayer1VisibleButton.alpha = BUTTON_OFF_ALPHA;
                }

                if(canvas11Bitmap.visible)
                {
                    tb.capLayer2VisibleButton.alpha = 1.0;
                }
                else
                {
                    tb.capLayer2VisibleButton.alpha = BUTTON_OFF_ALPHA;
                }
            }
        }

        private function penSizeHint(targetName:String):String
        {
            const str:String = targetName.substr(11,2);
            const index:int = parseInt(str);
            const size:int = sizeArr[index];
            const strlen:int = 3-(size+"").length;
            var blank:String ="";
            if(strlen === 1) blank = " ";
            else if(strlen === 2) blank = "  ";
            const hint:String = size + "px"+blank;

            return hint;
        }

        private function drawGrid():void
        {
            const g:Graphics = canvasGrid.graphics;
            const flag:uint = gridFlag;
            if(flag === 0)
            {
                canvasGrid.visible = false;
                g.clear();
                return;
            }

            const w:Number = CANVAS_WIDTH;
            const h:Number = CANVAS_HEIGHT;
            const floor:Function = Math.floor;
            const gridgap:Number = flag*GRID_GAP;
            const len:Number = floor(h/gridgap+0.5);//가로선 횟수 w, h반대되는거 맞음
            const len2:Number = floor(w/gridgap+0.5); //세로선 횟수
            const normalColor:uint = GRID_NORMAL_COLOR;
            const unitColor:uint = GRID_5UNIT_COLOR;
            var cmd:Vector.<int> = new Vector.<int>();
            var data:Vector.<Number> = new Vector.<Number>();
            var gridi:Number;

            g.clear();
            g.lineStyle(1,normalColor,0.5,true);
            for(var i:uint=1;i<=len;i++)
            {
                gridi = gridgap*i;
                cmd.push(1);
                cmd.push(2);
                data.push(0)
                data.push(gridi);
                data.push(w);
                data.push(gridi);
            }

            for(i=1;i<=len2;i++)
            {
                gridi = gridgap*i;
                cmd.push(1);
                cmd.push(2);
                data.push(gridi)
                data.push(0);
                data.push(gridi);
                data.push(h);
            }

            g.drawPath(cmd,data);

            cmd = new Vector.<int>();
            data = new Vector.<Number>();
            g.lineStyle(1,unitColor,0.5,true); //5단위 강조선

            for(i=1;i<len;i+=5)
            {
                gridi = gridgap*i;
                cmd.push(1);
                cmd.push(2);
                data.push(w)
                data.push(gridi);
                data.push(w);
                data.push(gridi);
            }

            for(i=1;i<len2;i+=5)
            {
                gridi = gridgap*i;
                cmd.push(1);
                cmd.push(2);
                data.push(gridi)
                data.push(0);
                data.push(gridi);
                data.push(h);
            }
            g.drawPath(cmd,data);

            cmd.length = 0;
            data.length = 0;
            checkGridMirror(mirrorON);
            canvasGrid.visible = true;
            canvasGrid.cacheAsBitmap = true;
        }

        private function setGridButton():void
        {
            gridFlag++;

            if(gridFlag > 5)
            {
                gridFlag = 0;
                topBar.hint("Grid OFF",topBar.gridButton);
            }
            else
            {
                topBar.hint("Grid " + (gridFlag*GRID_GAP)+"px ("+gridFlag+"/5)",topBar.gridButton);
            }

            drawGrid();
            setTopChildIndex(canvasGrid);
        }

        private function updateTraceOpaButtonPosByAlpha(alpha:Number):void
        {
            const _traceMenuBox:traceButtons = traceMenu;
            const button:SimpleButton = _traceMenuBox["traceOpaButton"];
            const bar:SimpleButton = _traceMenuBox["traceOpaBar"];
            const barWidth:Number = bar.width*alpha;
            const buttonMin:Number = bar.x;
            traceMenu["traceOpaButton"].x = buttonMin+barWidth;
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
            const _traceMenuBox:traceButtons = traceMenu;
            _traceMenuBox.hint("Reference layer");
            _traceMenuBox.x = mouseX-_traceMenuBox.width/2;
            _traceMenuBox.y = mouseY-8;
            _traceMenuBox.visible = true;

            setTopChildIndex(_traceMenuBox);
            checkBoxPosition(_traceMenuBox);

            if(traceMenuON === false)
            {
                _traceMenuBox.addEventListener(MouseEvent.RIGHT_MOUSE_UP,rightMouseUpTraceWindow);
                stage.addEventListener(MouseEvent.MOUSE_OVER,traceMenuHintONEvent);
            }

            traceMenuON = true;
            setTopChildIndex(traceMenu);
        }

        private function setTraceDeleteButton():void
        {
            const btn:SimpleButton = traceMenu.traceDeleteButton;

            setTopChildIndex(traceMenu);
            traceImageCount++;

            function traceDeleteButtonCountResetEvent(e:MouseEvent):void
            {
                traceImageCount = 0;
                btn.removeEventListener(MouseEvent.MOUSE_OUT,traceDeleteButtonCountResetEvent);
            }

            if(traceImageCount === 1)
            {
                traceMenu.hint(STRING_ONEMORE_CLICK_TO_OK);
                btn.addEventListener(MouseEvent.MOUSE_OUT,traceDeleteButtonCountResetEvent);
            }
            else if(traceImageCount === 2)
            {
                traceImageCount = 0;
                traceMenu.hint("Erase reference image");
                btn.removeEventListener(MouseEvent.MOUSE_OUT,traceDeleteButtonCountResetEvent);

                clearTraceImage();
                if(traceMemoryTraining === true)
                {
                    setTraceVisibleButton();
                }
            }
        }

        private function setTraceVisibleButton():void
        {
            if(traceMemoryTraining === false)
            {
                traceMemoryTraining = true;
                traceMenu.traceVisibleOFFButton.visible = false;
                traceMenu.traceVisibleONButton.visible = true;
            }
            else if(traceMemoryTraining === true)
            {
                traceMemoryTraining = false;
                traceMenu.traceVisibleOFFButton.visible = true;
                traceMenu.traceVisibleONButton.visible = false;
            }
        }

        private function setTraceMirrorButton():void
        {
            const _canvasTrace:Sprite = canvasTraceLayer;
            const _canvasTraceBitmap:Bitmap = canvasTraceBitmap;
            const _canvasTraceBitmapData:BitmapData = canvasTraceBitmapData;
            var tempBitData:BitmapData = new BitmapData(_canvasTraceBitmapData.width,
                                                        _canvasTraceBitmapData.height,true,0);
            var flipMat:Matrix = new Matrix(-1,0,0,1,_canvasTraceBitmapData.width);

            tempBitData.draw(_canvasTraceBitmapData,flipMat);

            if(canvasTraceBitmapData && tempBitData !== canvasTraceBitmapData) canvasTraceBitmapData.dispose();
            canvasTraceBitmapData = tempBitData.clone();
            canvasTraceBitmap.bitmapData = canvasTraceBitmapData;
            tempBitData.dispose();
            tempBitData = null;

            _canvasTrace.rotation = -_canvasTrace.rotation;//일단 각도 대칭해주고

            //canvas1을 기준으로 중심점 거리를 구해서 x값보정과 각도 보정을 함
            const canvasCenterX:Number = _canvasTrace.x+_canvasTraceBitmap.x+_canvasTraceBitmap.width/2;
            const subX:Number = Math.round((_canvasTrace.x-canvasCenterX)*2);
            const deg:Number = _canvasTrace.rotation-(regPoint.rotation)*2;

            _canvasTraceBitmap.x = _canvasTraceBitmap.x+subX;
            _canvasTrace.rotation = deg;//캔버스 전체가 회전해있을때 각도보정
            canvasTraceBitmap.smoothing = true;
            tracePosInfo[0] = _canvasTraceBitmap.x;
            tracePosInfo[2] = _canvasTrace.rotation;

            saveOneTime = false;
        }

        private function setTraceRotateButton():void
        {
            const _canvasTrace:Sprite = canvasTraceLayer;
            const _rotateCursorBox:rotateCursor = rotateCursorBox;
            const atan2:Function = Math.atan2;
            const floor:Function = Math.floor;
            const abs:Function = Math.abs;
            const PI:Number = Math.PI;
            // const traceMenuClickPos:Array = [traceMenu.mouseX,traceMenu.mouseY];

            // const PI2:Number = PI*2;
            const toDeg:Number = 180/PI;
            var regAng:Number = -regPoint.rotation%90;
            var oldAng:Number = _canvasTrace.rotation;
            var sumAng:Number = oldAng*PI/180;

            traceMenu.visible = false;
            canvasTraceBitmap.smoothing = false;

            setTopChildIndex(_rotateCursorBox);
            // _rotateCursorBox.rotation = regAng;
            _rotateCursorBox.visible = true;
            _rotateCursorBox.x = mouseX;
            _rotateCursorBox.y = mouseY+50;
            _rotateCursorBox["rotateArrow"].rotation = oldAng;

            var lastAng:Number = atan2(mouseX-_rotateCursorBox.x,mouseY-_rotateCursorBox.y);

            function traceRotateButtonUpEvent(e:MouseEvent):void
            {
                traceMenu.visible = true;
                _rotateCursorBox.rotation = 0;
                saveOneTime = false;
                mouseDragON = false;
                tracePosInfo[2] = canvasTraceLayer.rotation; //deg로 저장
                _rotateCursorBox.visible = false;
                canvasTraceBitmap.smoothing = true;
                stage.removeEventListener(MouseEvent.MOUSE_UP,traceRotateButtonUpEvent);
                stageMouseMoveEvent.remove("traceRotateButtonMoveEvent");
            }

            function traceRotateButtonMoveEvent(e:MouseEvent):void
            {
                const nowAng:Number = atan2(mouseX-_rotateCursorBox.x,mouseY-_rotateCursorBox.y);
                const subAng:Number = lastAng-nowAng;

                if(subAng === 0) return;

                lastAng = nowAng;
                sumAng += subAng;
                var deg:Number = floor(sumAng*toDeg);

                _canvasTrace.rotation = deg;
                _rotateCursorBox["rotateArrow"].rotation = deg;
            }

            stage.addEventListener(MouseEvent.MOUSE_UP,traceRotateButtonUpEvent);
            stageMouseMoveEvent.add("traceRotateButtonMoveEvent",traceRotateButtonMoveEvent);
        }

        private function setTraceResizeButton():void
        {
            const _canvasTrace:Sprite = canvasTraceLayer;
            const moveOffset:Number = 5;
            const cx:Number = mouseX;
            const cy:Number = mouseY;
            const abs:Function = Math.abs;
            const floor:Function = Math.floor;
            const bmpd:BitmapData = canvasTraceBitmapData;
            const w:Number = bmpd.width;
            const h:Number = bmpd.height;
            const mirrorFlag:Boolean = tracePosInfo[5];
            const mouseMoveLast:Point = new Point(0,0);
            var moveFlag:int = 0;

            traceMenu.visible = false;
            canvasTraceBitmap.smoothing = false;
            setToolTipON(w+ " x "+ h +" ["+_canvasTrace.scaleX.toFixed(2)+"]");
            toolTipBox.visible = true;

            function traceResizeButtonUpEvent(e:MouseEvent):void
            {
                saveOneTime = false;
                mouseDragON = false;
                tracePosInfo[3] = _canvasTrace.scaleX;
                tracePosInfo[4] = _canvasTrace.scaleY;
                traceMenu.visible = true;
                canvasTraceBitmap.smoothing = true;
                toolTipBox.visible = false;
                stage.removeEventListener(MouseEvent.MOUSE_UP,traceResizeButtonUpEvent);
                stageMouseMoveEvent.remove("traceResizeButtonMove");
            }

            function traceResizeButtonMove(e:MouseEvent):void
            {
                const mx:Number = mouseX;
                const my:Number = mouseY;

                if(moveFlag != 0)
                {
                    if(moveFlag === 1)
                    {
                        const subX:Number = mx-mouseMoveLast.x;

                        if(subX !== 0) //차이가 0이 될때가 있어서 이건 스킵
                        {
                            var dx:Number = subX*0.005;

                            if(mirrorFlag) _canvasTrace.scaleX -= dx;
                            else  _canvasTrace.scaleX += dx;

                            _canvasTrace.scaleY += dx;
                            traceReizeMoveSum += subX;
                        }
                    }
                    else if(moveFlag === 2)
                    {
                        const subY:Number = mouseMoveLast.y-my;
                        if(subY !== 0)
                        {
                            const dy:Number = subY*0.005;

                            if(mirrorFlag) _canvasTrace.scaleX -= dy;
                            else  _canvasTrace.scaleX += dy;

                            _canvasTrace.scaleY += dy;
                            traceReizeMoveSum += subY;
                        }
                    }
                    mouseMoveLast.setTo(mx,my);
                }
                else if(moveFlag === 0)
                {
                    if(abs(mx-cx) > moveOffset)
                    {
                        moveFlag = 1;
                    }
                    else if(abs(my-cy) > moveOffset)
                    {
                        moveFlag = 2;
                    }
                    mouseMoveLast.setTo(mx,my);
                }

                const sc:Number = abs(_canvasTrace.scaleX);
                const ww:Number = floor(w*sc+0.5);
                const hh:Number = floor(h*sc+0.5);

                setToolTipON(ww+ " x "+ hh +" ["+sc.toFixed(2)+"]");
                toolTipBox.visible = true;
            }

            stage.addEventListener(MouseEvent.MOUSE_UP,traceResizeButtonUpEvent);
            stageMouseMoveEvent.add("traceResizeButtonMove",traceResizeButtonMove);
        }

        private function setTraceMoveButton():void
        {
            const _canvasTraceBitmap:Bitmap = canvasTraceBitmap;
            const cx:Number = mouseX;
            const cy:Number = mouseY;
            const oldX:Number = _canvasTraceBitmap.x;
            const oldY:Number = _canvasTraceBitmap.y;
            const rotation:Number = regPoint.rotation+canvasTraceLayer.rotation;
            const scX:Number = tracePosInfo[3];
            const scY:Number = tracePosInfo[4];

            traceMenu.visible = false;
            canvasTraceBitmap.smoothing = false;

            function traceMoveButtonUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP,traceMoveButtonUpEvent);
                stageMouseMoveEvent.remove("traceMoveButtonMoveEvent");
                saveOneTime = false;
                mouseDragON = false;
                traceMenu.visible = true;
                tracePosInfo[0] = _canvasTraceBitmap.x;
                tracePosInfo[1] = _canvasTraceBitmap.y;
                canvasTraceBitmap.smoothing = true;
            }

            function traceMoveButtonMoveEvent(e:MouseEvent):void
            {
                const dx:Number = mouseX-cx;
                const dy:Number = mouseY-cy;
                const r:Point = rotatePoint(dx,dy,rotation);

                _canvasTraceBitmap.x = oldX+r.x/zoomed/scX; //캔버스만 옮겨줘서 미리보기해줌
                _canvasTraceBitmap.y = oldY+r.y/zoomed/scY;
            }

            stage.addEventListener(MouseEvent.MOUSE_UP,traceMoveButtonUpEvent);
            stageMouseMoveEvent.add("traceMoveButtonMoveEvent",traceMoveButtonMoveEvent);
        }

        private function setTraceClipButton():void
        {
            const btn:SimpleButton = traceMenu.traceClipButton;

            if(btn.alpha !== 1.0) return;

            setTopChildIndex(traceMenu);
            traceImageCount++;

            function traceClipButtonCountResetEvent(e:MouseEvent):void
            {
                traceImageCount = 0;
                btn.removeEventListener(MouseEvent.MOUSE_OUT,traceClipButtonCountResetEvent);
            }

            if(traceImageCount === 1)
            {
                traceMenu.hint(STRING_ONEMORE_CLICK_TO_OK);
                btn.addEventListener(MouseEvent.MOUSE_OUT,traceClipButtonCountResetEvent);
            }
            else if(traceImageCount === 2)
            {
                traceImageCount = 0;
                traceMenu.hint("Paste image from clipboard");
                btn.removeEventListener(MouseEvent.MOUSE_OUT,traceClipButtonCountResetEvent);

                const bmpd:Object = Clipboard.generalClipboard.getData(ClipboardFormats.BITMAP_FORMAT);

                if(bmpd as BitmapData)
                {
                    pasteTraceImage(bmpd as IBitmapDrawable, bmpd.width,bmpd.height);
                }
            }
        }

        private function resetTraceOpa():void
        {
            const deafultAlpha:Number = 0.5;

            CANVAS_TRACE_ALPHA = deafultAlpha;
            canvasTraceLayer.alpha = deafultAlpha;
            updateTraceOpaButtonPosByAlpha(deafultAlpha);
            traceMenu.hint("Opacity "+Math.floor(deafultAlpha*100)+"%");
            canvasTraceLayer.visible = true;
        }

        private function setTraceOpaButton():void
        {
            const _traceMenuBox:traceButtons = traceMenu;
            const button:SimpleButton = _traceMenuBox["traceOpaButton"];
            const bar:SimpleButton = _traceMenuBox["traceOpaBar"];
            const barWidth:Number = bar.width;
            const buttonMin:Number = bar.x+1;
            const buttonMax:Number = buttonMin+barWidth-2;
            const floor:Function = Math.floor;
            const step:Number = 10;

            function traceOpaButtonUpEvent(e:MouseEvent):void
            {
                mouseDragON = false;
                stage.removeEventListener(MouseEvent.MOUSE_UP,traceOpaButtonUpEvent);
                stageMouseMoveEvent.remove("traceOpaButtonMoveEvent");
            }

            function traceOpaButtonMoveEvent(e:MouseEvent):void
            {
                setTraceOpaValue();
            }

            function setTraceOpaValue():void
            {
                var mx:Number = _traceMenuBox.mouseX;

                if(mx < buttonMin) mx = buttonMin;
                else if(mx > buttonMax) mx = buttonMax;

                const value:Number = mx-buttonMin;
                const valueMax:Number = buttonMax-buttonMin;
                const alpha:Number = floor(((value/valueMax))*100)/100;

                button.x = mx;

                CANVAS_TRACE_ALPHA = alpha;
                if(alpha < 0.0)
                {
                    canvasTraceLayer.visible = false;
                    canvasTraceLayer.alpha = 0;
                }
                else
                {
                    if(canvasTraceLayer.visible === false)
                    {
                        canvasTraceLayer.visible = true;
                    }
                    canvasTraceLayer.alpha = alpha;
                }
                _traceMenuBox.hint("Opacity "+floor(alpha*100+0.5)+"%");
            }
            _traceMenuBox.hint("Opacity "+floor(CANVAS_TRACE_ALPHA*100+0.5)+"%");

            setTraceOpaValue();

            stage.addEventListener(MouseEvent.MOUSE_UP,traceOpaButtonUpEvent);
            stageMouseMoveEvent.add("traceOpaButtonMoveEvent",traceOpaButtonMoveEvent);
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
            ba.compress();
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
            saveTraceImage();
        }

        private function resetTraceImageInfo():void
        {
            const _canvasTrace:Sprite = canvasTraceLayer;
            const _canvasTraceBitmap:Bitmap = canvasTraceBitmap;
            const ww:Number = -_canvasTraceBitmap.width/2;
            const hh:Number = -_canvasTraceBitmap.height/2;

            _canvasTraceBitmap.x = ww;
            _canvasTraceBitmap.y = hh; //중점 셋팅
            _canvasTrace.rotation = 0;
            _canvasTrace.scaleX = 1;
            _canvasTrace.scaleY = 1;
            traceReizeMoveSum = 0;
            tracePosInfo = [ww,hh,0,1,1,false];
        }

        private function setTraceImageInfo(x:Number,y:Number,rotation:Number,scaleX:Number,scaleY:Number,mirror:Boolean):void
        {
            const _canvasTrace:Sprite = canvasTraceLayer;
            const _canvasTraceBitmap:Bitmap = canvasTraceBitmap;

            _canvasTrace.x = CANVAS_WIDTH/2;
            _canvasTrace.y = CANVAS_HEIGHT/2;
            _canvasTraceBitmap.x = x;
            _canvasTraceBitmap.y = y;
            _canvasTrace.scaleX = scaleX;
            _canvasTrace.scaleY = scaleY;
            _canvasTrace.rotation = rotation;
            tracePosInfo = [x,y,rotation,scaleX,scaleY,mirror];
        }

        private function pasteTraceImage(bmpd:IBitmapDrawable=null,w:Number=1,h:Number=1):void
        {
            if(!bmpd)
            {
                w = CANVAS_WIDTH;
                h = CANVAS_HEIGHT
            }

            if(bmpd) //로드한 이미지를 붙여넣을때
            {
                const maxSize:Number = 1000;
                const floor:Function = Math.floor;
                var maxLength:Number = (w > h) ? w : h;
                var scaleFix:Number = (maxLength > maxSize) ? maxSize/maxLength : 1.0;

                w = floor(w*scaleFix);
                h = floor(h*scaleFix); //maxSize 값을 넘으면 리사이즈 해줌
                var scaleMat:Matrix = new Matrix();
                scaleMat.scale(scaleFix,scaleFix);

                var tmpBMPD:BitmapData = new BitmapData(w,h,true,0);

                tmpBMPD.draw(bmpd,scaleMat,null,null,null,true);
                if(canvasTraceBitmapData && tmpBMPD !== canvasTraceBitmapData) canvasTraceBitmapData.dispose();
                canvasTraceBitmapData = tmpBMPD.clone();
                canvasTraceBitmap.bitmapData = canvasTraceBitmapData;

                tmpBMPD.dispose();
                tmpBMPD = null;
            }
            else //캔버스 자체 이미지를 붙여넣을때
            {
                if(deepUndoON) setApplyDeepUndo();
                var command:String = "clear";
                mergeImageToTraceLayer((canvas1Bitmap.visible)  ? canvas1BitmapData :null
                                      ,(canvas11Bitmap.visible) ? canvas11BitmapData:null);

                if(canvas1Bitmap.visible)
                {
                    canvas1BitmapData.fillRect(new Rectangle(0,0,w,h),0);
                }
                if(canvas11Bitmap.visible)
                {
                    canvas11BitmapData.fillRect(new Rectangle(0,0,w,h),0);
                }

                if(!canvas11Bitmap.visible)
                {
                    command = "clear1";
                }
                else if(!canvas1Bitmap.visible)
                {
                    command = "clear2";
                }

                if(hasLastRDataCommand(command))
                {
                    addUndoDataContinue();
                }
                else
                {
                    rDataBuffer = [[command]];
                    addUndoData();
                }
            }
            resetTraceImageInfo();

            if(bmpd) // 이미지 붙여넣을때 이미지가 캔버스사이즈보다 크면 자동 리사이즈함
            {
                const gw:Number = CANVAS_WIDTH;
                const gh:Number = CANVAS_HEIGHT;
                const widthFlag:Boolean = (w >= h) ? true : false;
                var autoScale:Number = 0;

                if(w > gw && widthFlag === true) autoScale = gw/w;
                else if (h > gh && widthFlag === false) autoScale = gh/h;

                if(autoScale > 0)
                {
                    const _canvasTrace:Sprite = canvasTraceLayer;
                    _canvasTrace.scaleX = autoScale;
                    _canvasTrace.scaleY = autoScale;
                    tracePosInfo[3] = autoScale;
                    tracePosInfo[4] = autoScale;
                }
            }

            if(canvasTraceLayer.visible === false || CANVAS_TRACE_ALPHA === 0.0)
            {
                updateTraceOpaButtonPosByAlpha(0.5);
                CANVAS_TRACE_ALPHA = 0.5;
                canvasTraceLayer.visible = true;
                canvasTraceLayer.alpha = 0.5;
            }
            canvasTraceBitmap.smoothing = true;
            saveOneTime = false;
        }

        private function getBlurSize(size:Number,z:Number):Number
        {
            var blurSize:Number = size/2;

            if(blurSize <= 2) blurSize = 2;
            else if(blurSize > 30) blurSize = 30;

            return blurSize*z;
        }

        private function setBlurCanvasBySizeNoZoomDrawMode():void
        {
            const blurSize:Number = getBlurSize(airBrushSizeDrawMode,1.0);
            const blurf:BlurFilter = new BlurFilter(blurSize,blurSize,3);

            canvas2Draw.filters = [blurf];
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

        private function setBlurCanvasBySizeDrawMode(size:Number):void
        {
            const blurSize:Number = getBlurSize(size,zoomed);
            const blurf:BlurFilter = new BlurFilter(blurSize,blurSize,3);
            airBrushSizeDrawMode = size;
            canvas2Draw.filters = [blurf];
        }

        private function setAirBrushCheckBox(flag:Boolean,penFlag:Boolean):void
        {
            const _controlBox:controlMenu = controlBox;
            _controlBox["airBrushOFFButton"].visible = flag;
            _controlBox["airBrushONButton"].visible = !flag;

            if(flag)
            {
                var size:uint = (penFlag) ? penSize:eraseSize;

                if(size !== airBrushSizeDrawMode)
                {
                    setBlurCanvasBySizeDrawMode(size);
                }

                _controlBox.blurShapeSetON();
            }
            else if(airBrushSizeDrawMode !== 0)
            {
                airBrushSizeDrawMode = 0;
                canvas2Draw.filters = [];
                _controlBox.blurShapeSetOFF();
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

            const cg:Graphics = xPanel.graphics;
            cg.clear();
            cg.beginFill(color);
            cg.drawRect(0,0,w,h);
            cg.endFill();
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

            var g:Graphics = xPanel.graphics;
            g.clear();
            g.lineStyle(0,0,0);
            g.beginBitmapFill(transBGBMPD);
            g.drawRect(0,0,w,h);
            g.endFill();
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
                canvasPanel.setChildIndex(canvas2,2);
            }
            else
            {
                controlBox.layer1SelectButton.alpha = 1.0;
                controlBox.layer2SelectButton.alpha = BUTTON_OFF_ALPHA;
                canvasPanel.setChildIndex(canvas1Bitmap,2);
            }
        }

        private function setSharpLineButtonShortcut():void
        {
            if(controlBox.sharpLineButtonWrapper.alpha === 1.0)
            {
                setSharpLineButton(!sharpLineON);

                if(sharpLineON) setToolTipTempON("Sharp line ON");
                else setToolTipTempON("Sharp line OFF");
            }
        }

        private function setSharpLineButton(flag:Boolean):void
        {
            if(!(isPenOrLineTool() || isEraseTool() || nowTool === TOOL_FILL_PEN)) return;

            sharpLineON = flag;

            controlBox["sharpLineOFFButton"].visible = flag;
            controlBox["sharpLineONButton"].visible = !flag;

            const isErase:Boolean = isEraseTool();
            const z:Number = zoomed;
            const size:uint = (isErase) ? eraseSize:penSize;
            const zSize:Number = size*z;

            if(sharpLineON)
            {
                if(size % 2 === 1.0) sizeOffsetFlag = true; //홀수 사이즈 일때 켜줌
                else sizeOffsetFlag = false;
            }
            else
            {
                if(z !== 1.0 || size === 1.0 || zSize % 2 !== 0) sizeOffsetFlag = false;
                else sizeOffsetFlag = true;
            }
        }

        private function updateStageBG(color:uint=0xCCCCCC):void
        {
            stageBG.graphics.clear();
            stageBG.graphics.beginFill(color);//paneldraw마스크 아무색이나 상관없음
            stageBG.graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
            stageBG.graphics.endFill();
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
            const uiColorName:String = (uiColorIndex === 0 ) ? "Black"
                :(uiColorIndex === 1) ?"Dark Gray"
                :(uiColorIndex === 2) ?"Medium Gray"
                :(uiColorIndex === 3) ?"Light Gray" : "";

            topBar.hint(uiColorName,topBar.topBarColorButton);
        }

        private function setUIColor(index:int):void
        {
            const _arr:Array = uiColorSet;
            const _arr2:Array = uiToolBoxColorSet[index];
            const nowColorSet:Array = _arr[index];
            const base:uint = nowColorSet[0];
            const op:uint = nowColorSet[1];
            const bg:uint = nowColorSet[2];
            const border:uint = nowColorSet[3];

            updateStageBG(bg);
            controlBox.changeUIColor(op);
            toolTipBox.changeUIColor(base,op);
            pickerBox.changeUIColor(op);
            updatePickerCurrentColor(penColor);
            sideBar.changeUIColor(base);
            previewBox.chanegStageColor(bg);
            toolBox.changeUIColor(_arr2);
            toolBox2.changeUIColor(_arr2);
            traceMenu.changeUIColor(_arr2,index === 0);
            lassoMenu.changeUIColor(_arr2);
            topBar.changeUIColor(base,op,_arr[index][4]);
            rotateCursorBox.changeUIColor(base,op);
            fileDragSelectBox.changeUIColor(_arr2);
            replayTimeBox.changeUIColor(base,op,_arr2[4],index);
            checkClipBoardImage();
            appInfoBox.canvasInfo.textColor = op;
            pickerBox.setRGBInfoColor(getInvertColor(pickerBox.rgbInfoBGColor,1.0
                                                    ,(uiColorIndex >= 2) ? base:op
                                                    ,(uiColorIndex >= 2) ? op:base));

            if(pickerMode !== 1) changePickerModeToNormal();
            pickerBox.setPickerMode(pickerMode);
            updateScrollBarColorHeight(scrollBarHeight);
            setResizeButtonColor(nowColorSet[3]);
            fofo.changeColor(op);
            setWindowBorderColor(base);

            if(canvasWindowON)
            {
                canvasWindow.stage.color = _arr[index][2];
            }
        }

        private function addStageInputEvent():void
        {
            colorHistoryUpdateReady = true;
            //전역스테이지 이벤트 cStageMouseMoveEvent <- 스테이지 마우스 무브는 클로저로 하고있음
            stage.addEventListener(MouseEvent.MOUSE_DOWN,stageMouseDownEvent,false,1);
            stage.addEventListener(MouseEvent.MOUSE_UP,stageMouseUpEvent,false,1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,stageRightMouseUpEvent,false,1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,stageRightMouseDownEvent,false,1);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,stageKeyDownEvent,false,1);
            stage.addEventListener(KeyboardEvent.KEY_UP,stageKeyUpEvent,false,1);
            stage.addEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryEvent);
            stageMouseMoveEvent.add("updatePenCursorPositionEvent",updatePenCursorPositionEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,updatePenCursorPositionEvent,false,-1);
            stage.addEventListener(Event.MOUSE_LEAVE,stageMouseLeaveEvent,false);
        }

        private function addInputEventStageChild():void
        {
            //창을 가운데로 옮김
            const _nativeWindow:NativeWindow = stage.nativeWindow;
            _nativeWindow.x = Capabilities.screenResolutionX/2 - 680/2;
            _nativeWindow.y = Capabilities.screenResolutionY/2 - 768/2 - 50;
            _nativeWindow.addEventListener(Event.RESIZE,windowResizeEvent);
            _nativeWindow.addEventListener(Event.DEACTIVATE,windowDeactiveEvent);
            _nativeWindow.addEventListener(Event.ACTIVATE,windowActiveEvent);
            _nativeWindow.addEventListener(Event.CLOSING, windowClosingEvent);

            stage.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER,onDragEnterEvent);
            stage.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP,onDragDropEvent);
            pickerBox.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,colorHistoryAddEvent);

            //힌트 보여주는 이벤트
            toolBox.addEventListener(MouseEvent.MOUSE_OVER,toolBoxHintONEvent);
            toolBox.addEventListener(MouseEvent.MOUSE_OUT,toolBoxHintOFFEvent);
            toolBox2.addEventListener(MouseEvent.MOUSE_OVER,toolBoxHint2ONEvent);

            replayTimeBox.addEventListener(MouseEvent.MOUSE_OVER,topBarHintONEvent);
            replayTimeBox.addEventListener(MouseEvent.MOUSE_OUT,topBarHintOFFEvent);
            topBar.addEventListener(MouseEvent.MOUSE_OVER,topBarHintONEvent);
            topBar.addEventListener(MouseEvent.MOUSE_OUT,topBarHintOFFEvent);

            controlBox.addEventListener(MouseEvent.MOUSE_OVER,controlBoxHintONEvent);
            controlBox.addEventListener(MouseEvent.MOUSE_OUT,controlBoxHintOFFEvent);

            topBar.addEventListener(MouseEvent.CLICK,topBarClickEvent);
        }

        private function setControlBoxInfoOFF():void
        {
            const nt:uint = nowTool;
            var toolName:String = "Pen";

            if(nt === TOOL_ERASE) toolName = "Eraser";
            else if(nt === TOOL_LINE) toolName = "Line";
            else if(nt === TOOL_FILL_PEN) toolName = "Fill-pen";

            controlBox.hintText(toolName+" options");
        }

        private function controlBoxHintOFFEvent(e:MouseEvent):void
        {
            if(!hasTimer("controlBoxHintTimer"))
            {
                addTimerByName("controlBoxHintTimer",0.2,true,function():Boolean
                {
                    if(isHitTestPoint(controlBox) === false)
                    {
                        setControlBoxInfoOFF();
                        return false;
                    }
                    return true;
                });
            }
        }

        private function controlBoxHintONEvent(e:MouseEvent):void
        {
            if(mouseDragON || mouseClickON || toolBox2ON || lassoToolON) return;

            const target:DisplayObject = e.target as DisplayObject;
            const targetName:String = target.name;
            var str:String = "";

            switch(targetName)
            {
                case "shapeCircle": str = "Circle";
                break;

                case "shapeRect": str = "Square";
                break;

                case "penSmoothSlider":
                case "penSmoothButton":
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
                    str = "Size : "+penSizeHint(targetName)+" (f, v / h, n)";
                }
                break;

                case "alphaButton0":
                case "alphaButton1":
                case "alphaButton2":
                case "alphaButton3":
                case "alphaButton4":
                case "alphaButton5":
                case "alphaButton6":
                case "alphaButton7":
                case "alphaButton8":
                case "alphaButton9":
                    str = "Opacity : "+getAlphaHint(targetName)+" (g, b)";
                break;

                case "sharpLineButtonWrapper":
                case "sharpLineOFFButton":
                case "sharpLineONButton":
                case "sharpLineText":
                    str = "Sharp line (3, 8)";
                break;

                case "airBrushButtonWrapper":
                case "airBrushOFFButton":
                case "airBrushONButton":
                case "airBrushText":
                    str = "Air brush (4, 7)";
                break;

                case "layer1SelectButton":
                    str = "Select layer 1 (1, 9)\nView only (right click)";
                    setSingleLayerPreview(1,false);
                break;

                 case "layer2SelectButton":
                    str = "Select layer 2 (2, 0)\nView only (right click)";
                    setSingleLayerPreview(2,false);
                break;

                case "layer1CheckButton":
                case "layer1UncheckButton":
                    str = "Check layer 1\n(1+w, 9+i)";
                    setSingleLayerPreview(1,false);
                break;

                case "layer2CheckButton":
                case "layer2UncheckButton":
                    str = "Check layer 2\n(2+w, 0+i)";
                    setSingleLayerPreview(2,false);
                break;

                case "layerSwapButton":
                    str = "Swap layer 1 <-> 2\n(shift+d, shift+j)";
                break;

                case "layerMergeButton":
                    str = "Merge image to layer 2\n(shift+e, shift+o)";
                break;
            }

            if(str === "")
            {
                return;
            }
            controlBox.hintText(str);
        }

        private function setClipButton():void
        {
            if(isInSaveProgress) return;
            rFileStream.close();
            cancelRestartTimer();

            tempCopiedImage = Clipboard.generalClipboard.getData(ClipboardFormats.BITMAP_FORMAT) as BitmapData;

            if(tempCopiedImage)
            {
                setDragDropSelectBoxReady("Clipboard_image_"+clipImageNameCount+".png");
                clipImageNameCount++;
            }
        }

        private function isPenOrLineTool():Boolean
        {
            const nt:int = nowTool;
            const bool:Boolean = (nt === TOOL_PEN || nt === TOOL_LINE);

            return bool;
        }

        private function isEraseTool():Boolean
        {
            return nowTool === TOOL_ERASE;
        }

        private function colorHistoryAddEvent(e:MouseEvent):void
        {
            const targetName:String = e.target.name;
            if(targetName === "colorHistoryBox" || targetName === "colorHistoryBoxBG")
            {
                addColorToHistoryManual();
            }
        }

        private function HEXtoHSV(color:uint):Vector.<Number>
        {
            const r:uint = (color >> 16) & 0xFF;
            const g:uint = (color >> 8) & 0xFF;
            const b:uint = color & 0xFF;

            return RGBtoHSV(r,g,b);
        }

        private function setColorTransform(ent:DisplayObject,color:uint,defaultFlag:Boolean=false):void
        {
            if(!ent) return;

            const c:ColorTransform = new ColorTransform();

            if(!defaultFlag)
            {
                c.color = color; //-1이면 기본 컬러로 간다
                c.alphaMultiplier = 1.0;
            }

            ent.transform.colorTransform = c;
        }

        private function updateReplayBarPos(stw:Number):void
        {
            const floor:Function = Math.floor;
            const scale:Number = getUIScale();
            const _replayTimeBox:replayTimeBar = replayTimeBox;
            const replayTotalBar:Sprite = _replayTimeBox["replayTotalBar"];
            const maxWidth:Number = stw-(_replayTimeBox["replayTotalBar"].x+5)*scale;
            const totalFrame:Number = TOTAL_FRAME;

            replayTotalBar.width = floor(maxWidth/scale);
            _replayTimeBox["replayBGBar"].width = floor(stw/scale)+1;
            _replayTimeBox["frameInfo"].x = replayTotalBar.x;
            _replayTimeBox["frameInfo"].width = floor(maxWidth/scale);
            _replayTimeBox["replayNowBar"].width = (replayTotalBar.width)*(rNowFrame/totalFrame);
        }

        private function setUpdateButton():void
        {
            updateAfterSave = true;
            saveFile(false);
        }

        private function startUpdate():void
        {
            updateAfterSave = false;
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

        private function shortCutPenAlpha(flag:Boolean):void
        {
            var alpha:Number = 0;
            var alphaStr:String = "";

            function setAlpha(alp:Number,size:uint):void
            {
                var index:Number = alphaArr.indexOf(alp);
                const len:uint = alphaArr.length-1;
                if(flag)
                {
                    index++;
                    if(index > len) index = len;
                }
                else
                {
                    index--;
                    if(index < 0) index = 0;
                }

                const alphaValue:Number = alphaArr[index];
                alphaStr = size+"px, "+alphaValue*100+"%";

                setToolTipTempON(alphaStr);
                setPenAlpha(alphaValue);
            }

            if(isPenOrLineTool() || isNowTool(TOOL_FILL_PEN))
            {
                setAlpha(penAlpha,penSize);
            }
            else if(isEraseTool())
            {
                setAlpha(eraseAlpha,eraseSize);
            }
        }

        private function shortCutPenSize(flag:Boolean):void
        {
            const len:uint = sizeArr.length-1;

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

                const sizeValue:Number = sizeArr[index];
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

            if(isPenOrLineTool() || isNowTool(TOOL_FILL_PEN))
            {
                setSize(penSizeIndex,penAlpha);
                if(airBrushON && penSize !== airBrushSizeDrawMode) setBlurCanvasBySizeDrawMode(penSize);
            }
            else if(isEraseTool())
            {
                setSize(eraseSizeIndex,eraseAlpha);
                if(eraseAirBrushON && eraseSize !== airBrushSizeDrawMode) setBlurCanvasBySizeDrawMode(eraseSize);
            }
        }

        private function stageKeyUpEvent(e:KeyboardEvent):void
        {
            if(fileDragSelectBox.visible)
            {
                return;
            }

            const keyCode:uint = e.keyCode;
            const index:int = keyBuffer.lastIndexOf(keyCode);

            if(index > -1)
            {
                keyBuffer.splice(index,1);
            }
        }

        private function stageKeyDownEvent(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;

            if(fileDragSelectBox.visible || keyCode === KEY.window)
            {
                return;
            }

            if(keyCode === KEY.tab || keyCode === KEY.alt)
            {
                e.preventDefault();
            }

            if(keyBuffer.lastIndexOf(keyCode) === -1)
            {
                keyBuffer.push(keyCode);
            }
        }

        private function setAlphaButton(targetName:String):void
        {
            const number:String = targetName.substr(11,targetName.length);
            const index:int = parseInt(number);

            setPenAlpha(alphaArr[index]);
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
                    setBlurCanvasBySizeDrawMode(penSize);
                }
            }
            else if(isPenOrLineTool())
            {
                if(airBrushON && penSize !== airBrushSizeDrawMode)
                {
                    setBlurCanvasBySizeDrawMode(penSize);
                }
            }
            else if(isEraseTool())
            {
                if(eraseAirBrushON && eraseSize !== airBrushSizeDrawMode)
                {
                    setBlurCanvasBySizeDrawMode(eraseSize);
                }
            }
        }

        //opacolor의 색깔을 바꿈
        private function updateOpaBoxColor(color:uint):void
        {
            if(color === penLastUpdateInfo[4])
            {
                return;
            }
            penLastUpdateInfo[4] = color;

            if(!colorHistoryUpdateReady)
            {
                colorHistoryUpdateReady = true;
                stage.addEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryEvent);
            }
        }

        private function getAlphaHint(targetName:String):String
        {
            const lastNumber:String = targetName.substr(11,1);
            const alpIndex:int = parseInt(lastNumber);
            const alpha:Number = alphaArr[alpIndex];
            const alpha100:String = alpha*100+"";
            const strlen:int = 3-(alpha100.length);
            var blank:String ="";
            if(strlen === 1) blank = " ";
            else if(strlen === 2) blank = "  ";
            const hint:String = alpha100 +"%"+blank;

            return hint;
        }

        private function setPenSmoothButton():void
        {
            const _controlBox:controlMenu = controlBox;
            const sliderSet:Sprite = _controlBox.penSmoothSliderSet;
            const button:SimpleButton = sliderSet["penSmoothButton"];
            const leftOffset:Number = sliderSet["penSmoothBar"].x+3; //펜 리스트에 흰색 선 시작과 끝 x좌표임
            const rightOffset:Number = leftOffset+sliderSet["penSmoothBar"].width-2;
            const step:Number = penSmoothSlideTotal;
            const div:Number = (rightOffset-leftOffset)/step;
            const maxValue:Number = 0.85;
            const minValue:Number = 0.02;
            const stepValue:Number = (maxValue-minValue)/step;
            const airBrushFlag:Boolean = isPenOrLineTool() && airBrushON;
            const eraseAirBrushFlag:Boolean = isEraseTool() && eraseAirBrushON;
            var oldValue:int = penSmoothSlideValue;

            mouseDragON = true;

            function penSmoothButtonUpEvent(e:MouseEvent):void
            {
                mouseDragON = false;
                stage.removeEventListener(MouseEvent.MOUSE_UP,penSmoothButtonUpEvent);
                stageMouseMoveEvent.remove("penSmoothButtonMoveEvent");
            }

            function setpenSmoothSlideValue():void
            {
                var mx:Number = sliderSet.mouseX;

                if(mx < leftOffset) mx = leftOffset;
                else if(mx > rightOffset) mx = rightOffset;

                //버튼을 기준으로 중간값으로
                const value:Number = Math.floor((mx-leftOffset)/div);
                const xpos:Number = value*div+leftOffset;

                if(button.x === xpos) return;

                button.x = xpos;
                penSmoothButtonX = xpos;

                if(value === 0) penSmoothValue = 0;
                else penSmoothValue = maxValue-(value*stepValue);

                penSmoothSlideValue = value;

                if(oldValue !== value)
                {
                    oldValue = value;
                    controlBox.hintText("Pen smoothing "+value + "/"+step);
                }
            }

            function penSmoothButtonMoveEvent(e:MouseEvent):void
            {
                setpenSmoothSlideValue();
            }

            setpenSmoothSlideValue();

            stage.addEventListener(MouseEvent.MOUSE_UP,penSmoothButtonUpEvent);
            stageMouseMoveEvent.add("penSmoothButtonMoveEvent",penSmoothButtonMoveEvent);
        }

        private function mergeCanvas(replayMode:Boolean,captureTransparentBG:Boolean,layer1:Boolean,layer2:Boolean):BitmapData
        {
            var xbitmap1:BitmapData;
            var xbitmap11:BitmapData;
            var xcanvas2:Sprite;
            var xBGCOLOR:uint;
            var alpha:Number;

            if(replayMode)
            {
                xbitmap1 = rcanvas1BitmapData;
                xbitmap11 = rcanvas11BitmapData;
                xcanvas2 = rcanvas2;
                xBGCOLOR = RCANVAS_BG_COLOR;
                alpha = tickDraw.getLineStyleAlpha();
            }
            else
            {
                xbitmap1 = canvas1BitmapData;
                xbitmap11 = canvas11BitmapData;
                xcanvas2 = canvas2;
                xBGCOLOR = CANVAS_BG_COLOR;
                alpha = 1.0;
            }

            const bmpd:BitmapData = new BitmapData(xbitmap1.width,xbitmap1.height,true
                                                  ,(captureTransparentBG) ? 0 : 0xFF000000|xBGCOLOR);

            if(layer2) bmpd.draw(xbitmap11); //레이어 쌓기

            if(isSubLayerONReplayMode()) //레이어 2번을 그리고 있을때
            {
                if(layer2) bmpd.draw(xcanvas2,null,new ColorTransform(1,1,1,alpha));
                if(layer1) bmpd.draw(xbitmap1);
            }
            else //레이어 1번 그리고 있을때
            {
                if(layer1)
                {
                    bmpd.draw(xbitmap1);
                    bmpd.draw(xcanvas2,null,new ColorTransform(1,1,1,alpha));
                }
            }

            return bmpd;
        }

        private function setCaptrueFlipButton():void
        {
            captureFlipped = !captureFlipped;
            fitCanvasToWindow(true);
            const xReg:Sprite = (replayModeON) ? rregPoint : regPoint;
            const _captureRotated:uint = captureRotated;

            if(_captureRotated === 1)
            {
                captureRotated = 3;
                xReg.rotation = 270;
            }
            else if(_captureRotated === 3)
            {
                captureRotated = 1
                xReg.rotation = 90;
            }

            topBar.capClipBoard.alpha = 1.0;
        }

        private function captureOFF():void
        {
            browseWindowON = false;

            if(replayModeON) setCaptureModeOFF(true,rregPoint,rcanvasPanel);
            else setCaptureModeOFF(false,regPoint,canvasPanel);
        }

        private function setCaptureOFFButton(shortcut:Boolean):void
        {
            captureOFF();
        }

        private function setFullCaptrueButton():void
        {
            saveCaptureImage();
        }

        private function setCaptureTransButton():void
        {
            captureTransBGON = !captureTransBGON;

            if(captureTransBGON) setTransBG(replayModeON);
            else resetTransBG(replayModeON);
        }

        private function setCaptureRotateButton():void
        {
            captureRotated++;
            if(captureRotated >= 4) captureRotated = 0;
            fitCanvasToWindow(true);
            topBar.capClipBoard.alpha = 1.0;
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
            if(resizeButtonR.visible === flag) return;

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
                addTimerByName("resizeButtonVisibleDelayTimer",0.7,false,function():void
                {
                    resizeButtonVisible(true);
                });
            }
            else
            {
                removeTimer("resizeButtonVisibleDelayTimer");
                resizeButtonVisible(false);
            }
        }

        private function updateColorHistoryBGEvent(e:MouseEvent):void
        {
            const targetName:String =  e.target.name;

            if(targetName
            && (targetName.indexOf("canvas") !== -1 || targetName === "stageBG" || targetName === "canvasGrid"))
            {
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryBGEvent);
                colorHistoryUpdateBGReady = false;
                addColorToHistory(CANVAS_BG_COLOR);
                changePickerModeToNormal();
            }
        }

        private function updateColorHistoryEvent(e:MouseEvent):void
        {
            if(quickSidebarON) return;

            const targetName:String =  e.target.name;

            if((isPenOrLineTool() || isNowTool(TOOL_FILL_PEN))
            && targetName
            && (targetName.indexOf("canvas") !== -1 || targetName === "stageBG" || targetName === "canvasGrid"))
            {
                colorHistoryUpdateReady = false;
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryEvent);

                const _penColor:uint = penColor;

                if(changedColor !== _penColor)
                {
                    changedColor = _penColor;
                    addColorToHistory(_penColor);
                    updateColorHistoryList();
                    updatePickerCurrentColor(_penColor);
                }
            }
        }

        private function addInputEventReplayMode():void
        {
            resetKeyBuffer();
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownReplayMode,false,-1);
            stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownReplayMode,false,-1);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownReplayMode,false,-1);
            stage.addEventListener(KeyboardEvent.KEY_UP,keyUpReplayMode,false,-1);
        }

        private function removeInputEventReplayMode():void
        {
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownReplayMode);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownReplayMode);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownReplayMode);
            stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpReplayMode);
        }

        private function removeInputEventDrawMode():void
        {
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownDrawMode);
            stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpDrawMode);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownDrawMode);
            stage.removeEventListener(MouseEvent.MOUSE_UP,mouseUpDrawMode,false);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownDrawMode);
            // stage.removeEventListener(MouseEvent.MOUSE_OVER,lassoMenuHintONEvent);
        }

        private function addInputEventDrawMode():void
        {
            resetKeyBuffer();
            stage.addEventListener(KeyboardEvent.KEY_UP,keyUpDrawMode,false,-1);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownDrawMode,false,-1);
            stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownDrawMode,false,-1);
            stage.addEventListener(MouseEvent.MOUSE_UP,mouseUpDrawMode,false,-1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownDrawMode,false,-1);
        }

        private function removeInputEventCaptrueMode():void
        {
            stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpCaptureMode);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownCaptureMode);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownCaptureMode);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownCaptureMode);
            stage.removeEventListener(MouseEvent.MOUSE_OVER,mouseOverCaptureMode);
        }

        private function addInputEventCaptrueMode():void
        {
            resetKeyBuffer();
            stage.addEventListener(KeyboardEvent.KEY_UP,keyUpCaptureMode,false,-1);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownCaptureMode,false,-1);
            stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownCaptureMode,false,-1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownCaptureMode,false,-1);
            stage.addEventListener(MouseEvent.MOUSE_OVER,mouseOverCaptureMode,false,-1);
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

        private function topBarClickEvent(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target) return;
            const targetName:String = target.name;

            if(lassoToolON || fillPenStarted || target.alpha < 1.0
            || makeJumpImageFlag === 2) return;

            switch (targetName)
            {
                case "clearButton":
                {
                    if(toolBox2ON || !isNowKey(0)) return;

                    setClearData();
                }
                break;

                case "replayModeButton":
                {
                    if(toolBox2ON || !isNowKey(0)) return;

                    setReplayUION();

                    mouseClickON = false; //리플레이 버튼 누르고 나서 단축키가 안먹는 현상이 이거임
                }
                break;

                case "drawModeButton": setReplayUIOFF(); break;
                case "superUndoButton": setCutFrameButton(CUT_FRAME_SUPER_UNDO,false); break;
                case "reRecordingButton": setCutFrameButton(CUT_FRAME_RE_RECORD,false); break;
                case "cutPrevDataButton": setCutFrameButton(CUT_FRAME_DELETE_FRONT,false); break;
            }
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
            lassoResizeON = true;
            const _lassoBox:Sprite = lassoBox;
            const _lassoMenu:lassoButtons = lassoMenu;
            const _canvasPanel:Sprite = canvasPanel;
            const floor:Function = Math.floor;
            const atan2:Function = Math.atan2;
            const abs:Function = Math.abs;
            const PI:Number = Math.PI;
            const _rotateCursorBox:rotateCursor = rotateCursorBox;
            const angleCursor:SimpleButton = _rotateCursorBox["rotateArrow"]

            var sumAng:Number = lassoBox.rotation*PI/180;//rad로 바꿔줌
            var lastAng:Number = 0;
            const toDeg:Number = 180/PI;

            lassoBMP.smoothing = false;

            function lassoRotateButtonUpEvent(e:MouseEvent):void
            {
                lassoResizeON = false;
                lassoBMP.smoothing = true;
                _lassoMenu.visible = true;
                _rotateCursorBox.visible = false;

                stage.removeEventListener(MouseEvent.MOUSE_UP, lassoRotateButtonUpEvent);
                stageMouseMoveEvent.remove("lassoRotateButtonMoveEvent");
            }

            function lassoRotateButtonMoveEvent(e:MouseEvent):void
            {
                const nowAng:Number = Math.atan2(mouseX-_rotateCursorBox.x,mouseY-_rotateCursorBox.y);
                const subAng:Number = lastAng-nowAng;

                if(subAng === 0) return;

                lastAng = nowAng;
                sumAng += subAng;

                const deg:Number = floor(sumAng*toDeg+0.5);

                _lassoBox.rotation = deg;
                angleCursor.rotation = deg;
            }

            _rotateCursorBox.x = mouseX;
            _rotateCursorBox.y = mouseY+50;
            _rotateCursorBox.visible = true;
            setTopChildIndex(_rotateCursorBox);
            lastAng = Math.atan2(mouseX-_rotateCursorBox.x,mouseY-_rotateCursorBox.y);
            angleCursor.rotation = _lassoBox.rotation;
            _lassoMenu.visible = false;
            stageMouseMoveEvent.add("lassoRotateButtonMoveEvent",lassoRotateButtonMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,lassoRotateButtonUpEvent);
        }

        private function setLassoResizeButton():void
        {
            lassoResizeON = true;
            const _lassoBox:Sprite = lassoBox;
            const _lassoMenu:lassoButtons = lassoMenu;
            const floor:Function = Math.floor;
            const abs:Function = Math.abs;
            const _lassoBMP:Bitmap = lassoBMP;
            var lassoFirstX:Number = mouseX;
            var lassoFirstY:Number = mouseY;
            var lassoMovedX:Number = lassoFirstX;
            var lassoMovedY:Number = lassoFirstY;
            var lassoFirstScale:Number = _lassoBox.scaleY;
            var lassoImageScale:Number = lassoFirstScale;
            var moveFlag:uint = 0;

            _lassoBMP.smoothing = false;

            function lassoResizeButtonUpEvent(e:MouseEvent):void
            {
                lassoResizeON = false;

                checkLassoMenuPos();
                _lassoBMP.smoothing = true;
                _lassoMenu.visible = true;
                toolTipBox.visible = false;

                stage.removeEventListener(MouseEvent.MOUSE_UP,lassoResizeButtonUpEvent);
                stageMouseMoveEvent.remove("lassoResizeButtonMoveEvent");
            }

            function lassoResizeButtonMoveEvent(e:MouseEvent):void
            {
                const mx:Number = mouseX;
                const my:Number = mouseY;
                const mirrorFlag:Boolean = lassoMirrorON;//미러플래그 켜져 있으면 x축 부호 반대로 해줘야함

                if(moveFlag != 0)
                {
                    if(moveFlag === 1)
                    {
                        const subX:Number = mx-lassoMovedX;
                        if(subX !== 0) //차이가 0이 될때가 있어서 이건 스킵
                        {
                            lassoImageScale += (subX)*0.005;
                            lassoResizeMoveSum += subX;
                        }
                    }
                    else if(moveFlag === 2)
                    {
                        const subY:Number = lassoMovedY-my;
                        if(subY !== 0)
                        {
                            lassoImageScale += (subY)*0.005;
                            lassoResizeMoveSum += subY;
                        }
                    }
                }
                else if(moveFlag === 0)
                {
                    if(abs(mx-lassoFirstX) > 3) moveFlag = 1;
                    else if(abs(my-lassoFirstY) > 3) moveFlag = 2;
                }

                _lassoBox.scaleX = (mirrorFlag) ? -lassoImageScale : lassoImageScale;
                _lassoBox.scaleY = lassoImageScale;
                lassoMovedX = mx;
                lassoMovedY = my;

                setToolTipON(floor(_lassoBox.width+0.5) +" x " +floor(_lassoBox.height+0.5) +" ["+lassoImageScale.toFixed(2)+"]");
            }

            setToolTipON(floor(_lassoBox.width+0.5)+" x "+floor(_lassoBox.height+0.5) +" ["+lassoImageScale.toFixed(2)+"]");
            toolTipBox.visible = true;
            _lassoMenu.visible = false;
            stage.addEventListener(MouseEvent.MOUSE_UP,lassoResizeButtonUpEvent);
            stageMouseMoveEvent.add("lassoResizeButtonMoveEvent",lassoResizeButtonMoveEvent);
        }

        private function isLassoUsed():Boolean
        {
            const arr:Array = lassoStartData;
            const _lassobox:Sprite = lassoBox;

            if(lassoCopyON
            || arr[0] !== _lassobox.x
            || arr[1] !== _lassobox.y
            || arr[2] !== _lassobox.scaleX
            || arr[3] !== _lassobox.scaleY
            || arr[4] !== _lassobox.rotation)
            {
                return true;
            }
            return false;
        }

        private function setLassoMoveButton():void
        {
            var old:Point = new Point(mouseX,mouseY);
            const _lassoMenu:lassoButtons = lassoMenu;
            var sx:Number = lassoBox.x;
            var sy:Number = lassoBox.y;

            lassoBMP.smoothing = false;

            function lassoMoveButtonUpEvent(e:MouseEvent):void
            {
                lassoBMP.smoothing = true;
                _lassoMenu.visible = true;
                checkLassoMenuPos();
                stage.removeEventListener(MouseEvent.MOUSE_UP,lassoMoveButtonUpEvent);
                stageMouseMoveEvent.remove("lassoMoveButtonMoveEvent");
            }

            function lassoMoveButtonMoveEvent(e:MouseEvent):void
            {
                const round:Function = Math.round;
                const moveX:Number = mouseX-old.x;
                const moveY:Number = mouseY-old.y;
                const rotatedMove:Point = rotatePoint(moveX,moveY,regPoint.rotation);
                const z:Number = zoomed;

                sx += rotatedMove.x/z;
                sy += rotatedMove.y/z;

                lassoBox.x = round(sx);
                lassoBox.y = round(sy);

                old.setTo(mouseX,mouseY);
            }
            _lassoMenu.visible = false;
            stage.addEventListener(MouseEvent.MOUSE_UP,lassoMoveButtonUpEvent);
            stageMouseMoveEvent.add("lassoMoveButtonMoveEvent",lassoMoveButtonMoveEvent);
        }

        private function setPenSize(index:uint):void
        {
            const size:uint = sizeArr[index];

            if(isPenOrLineTool() || isNowTool(TOOL_FILL_PEN))
            {
                penSize = size;
                penSizeIndex = index;
                penCursorPosition.updateCursorSize(penSize);
            }
            else if(isEraseTool())
            {
                eraseSize = size;
                eraseSizeIndex = index;
                penCursorPosition.updateCursorSize(eraseSize);
            }
            else
            {
                selectPenTool();
            }

            controlBox.movePenSizeCursor(index);
        }

        private function setColorBorder(color:uint):uint
        {
            const defColor:Number = getColorDifferenceForHuman(color,uiColorSet[uiColorIndex][0]);
            return (defColor <= 15) ? uiColorSet[uiColorIndex][1] : 0;
        }

        private function updatePickerCurrentColor(color:uint):void
        {
            pickerBox.updateCurrentColor(color,setColorBorder(color));
        }

        private function changePickerModeToBG():void
        {
            const color:uint = CANVAS_BG_COLOR;
            pickerMode = 2;
            setHSVCursorPosByColor(color);
            updatePickerCurrentColor(color);
            pickerBox.setPickerMode(2);
            stage.addEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryBGEvent);
        }

        private function changePickerModeToNormal():void
        {
            const color:uint = penColor;
            pickerMode = 1;
            addColorToHistory(CANVAS_BG_COLOR);
            addColorToHistory(penColor);
            setHSVCursorPosByColor(color);
            updatePickerCurrentColor(color);
            pickerBox.setPickerMode(1);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryBGEvent);
            // if(colorHistoryUpdateReady === false)
            // {
            //     colorHistoryUpdateReady = true;
            //     stage.addEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryEvent);
            // }
        }

        private function setPenShapeButton(shapeFlag:Boolean):void
        {
            penListShapeFlag = shapeFlag;

            if(shapeFlag === true)
            {
                penSizeCursor.rotation = regPoint.rotation;
            }

            if(isPenOrLineTool())
            {
                if(penShape !== shapeFlag)
                {
                    penShape = shapeFlag;
                }
            }
            else if(isEraseTool())
            {
                if(eraseShape !== shapeFlag)
                {
                    eraseShape = shapeFlag;
                }
            }

            controlBox.shapeFlag(shapeFlag);
            updatePenSizeCursor();
        }

        private function setHueColorButton():void
        {
            const _pickerBox:colorPickerBox = pickerBox;
            const _hueBarWidth:Number = _pickerBox["svBoxWidth"];
            const offsetX:Number = _pickerBox["offsetX"];
            const hueColorBox:Sprite = _pickerBox["hueColor"];
            const hueCursor:SimpleButton = _pickerBox["hueCursor"];
            const mode:uint = pickerMode;
            const max:Number = _hueBarWidth;
            var pickedColor:uint = 0;

            setTopChildIndex(hueCursor);
            mouseDragON = true;
            penCursorOFFFlag = true;

            function hueMoveStart(mx:Number):void
            {
                var hueCursorX:Number = mx;

                if(hueCursorX < 0) hueCursorX = 0;
                else if(hueCursorX > max) hueCursorX = max;

                hueCursor.x = hueCursorX;

                const hueValue:Number = Math.floor((hueCursorX*360)/_hueBarWidth);
                const baseColor:Vector.<uint> = HSVtoRGB(hueValue,1.0,1.0);
                const baseHexColor:uint = RGBtoHex(baseColor[0],baseColor[1],baseColor[2]);
                const color:uint = updatePickerBoxInfoColor(hueValue,HUECOLOR[1],HUECOLOR[2]);

                pickedColor = color;
                pickerColorSelected = true;
                _pickerBox.changeHueColor(baseHexColor);
                _pickerBox.updateRGBInfoBG(color,setColorBorder(color));
            }

            function hueColorButtonMoveEvent(e:MouseEvent):void
            {
                hueMoveStart(hueColorBox.mouseX);
            }

            function hueColorButtonUpEvent(e:MouseEvent):void
            {
                hueMoveStart(hueColorBox.mouseX);

                if(mode === 1)
                {
                    penColor = pickedColor;
                    updateOpaBoxColor(pickedColor);
                    updateOpacityCursor(penAlphaIndex);
                }
                else if(mode === 2)
                {
                    setBackgroundColorDrawMode(pickedColor);
                    if(canvasWindowON) updateCanvasWindowCanvasPanelBGColor(CANVAS_BG_COLOR,canvasWindowBitmap.bitmapData);
                    updateColorHistoryList();
                    addUndoBGColor(pickedColor);
                }

                mouseDragON = false;
                penCursorOFFFlag = false;

                forceSetMainDrawTool();
                //timer로 동작하는 경우 마지막 커서위치에 안가있을수도 있기 때문에 up에서도 해줌
                stage.removeEventListener(MouseEvent.MOUSE_UP,hueColorButtonUpEvent);
                stageMouseMoveEvent.remove("hueColorButtonMoveEvent");
            }
            hueMoveStart(hueColorBox.mouseX);
            stage.addEventListener(MouseEvent.MOUSE_UP,hueColorButtonUpEvent);
            stageMouseMoveEvent.add("hueColorButtonMoveEvent",hueColorButtonMoveEvent);
        }

        private function updatePickerBoxInfoColor(h:Number,s:Number,v:Number):uint
        {
            const rgbColor:Vector.<uint> = HSVtoRGB(h,s,v);
            const r:uint = rgbColor[0];
            const g:uint = rgbColor[1];
            const b:uint = rgbColor[2];
            const rgbHexColor:uint = RGBtoHex(r,g,b);
            const invColor:uint = getInvertColor(rgbHexColor,1.0
                                                ,(uiColorIndex >= 2) ? uiColorSet[uiColorIndex][0]:uiColorSet[uiColorIndex][1]
                                                ,(uiColorIndex >= 2) ? uiColorSet[uiColorIndex][1]:uiColorSet[uiColorIndex][0]);
            const colorHint:String =  "RGB "+r+","+g+","+b;

            HUECOLOR[0] = h;
            HUECOLOR[1] = s;
            HUECOLOR[2] = v;

            pickerBox.setRGBInfo(colorHint);
            pickerBox.setRGBInfoColor(invColor);

            return rgbHexColor;
        }

        private function setSVcolorButton():void
        {
            const _pickerBox:colorPickerBox = pickerBox;
            const svColorBox:Sprite = _pickerBox["svBox"];
            const svCursor:SimpleButton = _pickerBox["svCursor"];
            const _colorBarWidth:Number = _pickerBox["svBoxWidth"];
            const _colorBarHeight:Number = _pickerBox["svBoxHeight"];
            const mode:uint = pickerMode;
            var pickedColor:uint = 0;

            setTopChildIndex(svCursor);
            mouseDragON = true;
            penCursorOFFFlag = true;

            function setSVBoxMouseMoveEvent(mx:Number,my:Number):void
            {
                var svCursorX:Number = mx;
                var svCursorY:Number = my;

                if(svCursorX < 0) svCursorX = 0;
                else if(svCursorX > _colorBarWidth) svCursorX = _colorBarWidth;

                if(svCursorY < 0) svCursorY = 0;
                else if(svCursorY > _colorBarHeight) svCursorY = _colorBarHeight;

                svCursor.x = svCursorX;
                svCursor.y = svCursorY;

                const hue0:Number = HUECOLOR[0];
                const sValue:Number = svCursorX/_colorBarWidth;
                const vValue:Number = 1-(svCursorY/_colorBarHeight);
                const color:uint = updatePickerBoxInfoColor(hue0,sValue,vValue);

                pickedColor = color;
                _pickerBox.updateRGBInfoBG(color,setColorBorder(color));
            }

            function svColorButtonMoveEvent(e:MouseEvent):void
            {
                pickerColorSelected = true;
                setSVBoxMouseMoveEvent(svColorBox.mouseX,svColorBox.mouseY);
            }

            function svColorButtonUpEvent(e:MouseEvent):void
            {
                setSVBoxMouseMoveEvent(svColorBox.mouseX,svColorBox.mouseY);

                if(mode === 1)
                {
                    penColor = pickedColor;
                    updateOpaBoxColor(pickedColor);
                    updateOpacityCursor(penAlphaIndex);
                }
                else if(mode === 2)
                {
                    setBackgroundColorDrawMode(pickedColor);
                    if(canvasWindowON) updateCanvasWindowCanvasPanelBGColor(CANVAS_BG_COLOR,canvasWindowBitmap.bitmapData);
                    updateColorHistoryList();
                    addUndoBGColor(pickedColor);
                }

                mouseDragON = false;
                penCursorOFFFlag = false;

                forceSetMainDrawTool();

                stage.removeEventListener(MouseEvent.MOUSE_UP,svColorButtonUpEvent);
                stageMouseMoveEvent.remove("svColorButtonMoveEvent");
            }

            setSVBoxMouseMoveEvent(svColorBox.mouseX,svColorBox.mouseY);

            stage.addEventListener(MouseEvent.MOUSE_UP,svColorButtonUpEvent);
            stageMouseMoveEvent.add("svColorButtonMoveEvent",svColorButtonMoveEvent);
        }

        //단축키를  after tool mouse up에서 이전툴을 복구해줌
        private function restoreFirstUsedTool():void
        {
            const _oldTool:int = oldTool;

            if(_oldTool === TOOL_NONE)
            {
                selectPenTool();
                updatePenSizeCursor();
                return;
            }

            switch (_oldTool)
            {
                case TOOL_FILL_PEN:
                    selectFillPenTool();
                break;

                case TOOL_PEN:
                    selectPenTool();
                    updatePenSizeCursor();
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

            nowTool = _oldTool;

            resetOldTool();
        }

        //VERSION변수를 문자열로 변환, 변환할때 뒤에 .0이 붙었는지 까지 체크
        private function convertVersionString(version:Number):String
        {
            var verStr:String = version.toString();

            if(verStr.indexOf(".") === -1) verStr = verStr + ".0";

            return verStr;
        }

        private function setIMEDisabled():void
        {
            if(Capabilities.hasIME && IME.enabled) //다른 언어로 하면 자판 안먹어서 그냥 ime자체를안씀
            {
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
                        const floor:Function = Math.floor;
                        const oldVersion:Number = APP_VERSION;
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
                clickBlockFlag = false;
            });
        }

        private function aboutOFFMouseDownEvent(e:MouseEvent):void
        {
            const targetName:String = e.target.name;

            switch(targetName)
            {
                case "versionInfo":
                case "releaseNote":
                    navigateToURL(new URLRequest("https://raw.githubusercontent.com/guljam/2020FlashPaint/master/releasenote.txt"));
                break;

                case "appResetButton":
                    checkButtonUp(targetName);
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

                case "aboutTwitterLink":
                    navigateToURL(new URLRequest("https://twitter.com/ninanoninini"));
                break;

                default:
                    closeAboutPanel();
                break;
            }
        }

        private function setAboutPanelCenterPos():void
        {
            const panel:Sprite = aboutPanel;
            const w:Number = panel.width;
            const h:Number = panel.height;
            const floor:Function = Math.floor;

            panel.x = floor(stage.stageWidth/2)+floor(-w/2);
            panel.y = floor((stage.stageHeight-39)/2)+ floor(-h/2);
            panel.visible = true;
        }

        private function openAboutPanel(welcome:Boolean):void
        {
            const _aboutPanel:aboutBox = aboutPanel;

            setTopChildIndex(_aboutPanel);
            aboutPanelON = true;
            clickBlockFlag = true;

            removeInputEventDrawMode();

            aboutPanel.appResetButton.visible = true;
            if(welcome === true)
            {
                aboutPanel.appResetButton.visible = false;
                addTimerByName("openAboutPanelOFFTimer",1.0,false,function():void
                {
                    stage.addEventListener(MouseEvent.MOUSE_DOWN,aboutOFFMouseDownEvent);
                });
            }
            else
            {
                checkVersion();
                stage.addEventListener(MouseEvent.MOUSE_DOWN,aboutOFFMouseDownEvent);
            }

            aboutPanel.randomLogo();
            setAboutPanelCenterPos();
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

            resetTraceImageInfo();
            resetTraceOpa();
            makeFirstReplayImage(canvas1BitmapData,canvas11BitmapData,CANVAS_BG_COLOR);
            initReplayDataFile(true);
            resetReplaySpeedBar();
            resetReplayTime();
            resetUndo();

            const fileName:String = getTimeStampTailHead()+" "+getRandomString()+".png";
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
            const dd:Array = tickDraw.getrLineStyleSave();
            // if(!dd) return;
            const newColorTransform:ColorTransform = new ColorTransform(1,1,1,dd[0]);

            rcanvas2BitmapData.draw(rcanvas2Draw);

            if(isSubLayerONReplayMode()) rcanvas11BitmapData.draw(rcanvas2BitmapData,null,newColorTransform,dd[1]);
            else rcanvas1BitmapData.draw(rcanvas2BitmapData,null,newColorTransform,dd[1]);

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
            //reset vars보다 뒤에 와야함
            //addundo에서 활성화 해주고 있기 때문에
            topBar.clearButton.alpha = BUTTON_OFF_ALPHA;
        }

        private function setClearData(keyFlag:Boolean=false):void
        {
            if(isInSaveProgress) return;

            if(clearDataButtonCount === 0)
            {
                if(keyFlag)
                {
                    function clearDataButtonCountResetEvent(e:MouseEvent):void
                    {
                        //클리어 버튼이 아닐때만
                        if(e.target.name !== "clearButton")
                        {
                            setTopBarHintOFF();
                        }
                        stage.removeEventListener(MouseEvent.MOUSE_DOWN,clearDataButtonCountResetEvent);
                    }

                    stage.addEventListener(MouseEvent.MOUSE_DOWN,clearDataButtonCountResetEvent);
                }

                function clearDataButtonCountResetEventOver(e:MouseEvent):void
                {
                    clearDataButtonCount = 0;
                    stage.removeEventListener(MouseEvent.MOUSE_OVER,clearDataButtonCountResetEventOver);
                }
                stage.addEventListener(MouseEvent.MOUSE_OVER,clearDataButtonCountResetEventOver);
            }

            clearDataButtonCount++;

            if(clearDataButtonCount >= 2)
            {
                clearDataButtonCount = 0;
                topBar.hintOFF();
                clearData();
            }
            else if(clearDataButtonCount === 1)
            {
                if(keyFlag) topBar.hintTime(STRING_ONEMORE_PRESS_TO_OK,topBar.clearButton);
                else topBar.hint(STRING_ONEMORE_CLICK_TO_OK,topBar.clearButton);
            }
        }

        private function checkButtonUp(targetName:String):void
        {
            if(aboutPanelON)
            {
                if(targetName === "appResetButton")
                {
                    resetApp();
                    stage.nativeWindow.close();
                }
                return;
            }

            function buttonUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, buttonUpEvent);

                const upTargetName:String = e.target.name;
                var url:URLRequest;

                if(targetName === upTargetName)
                {
                    switch(upTargetName)
                    {
                        case "capLayer1VisibleButton":
                            setLayer1CheckToggleCaptureMode();
                        break;

                        case "capLayer2VisibleButton":
                            setLayer2CheckToggleCaptureMode();
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
                            setClipButton();
                        break;

                        case "repCaptureButton":
                        case "captureButton":
                             setCaptureModeON();
                        break;

                        case "capRotate":
                            setCaptureRotateButton();
                        break;

                        case "capTrans":
                            setCaptureTransButton();
                        break;

                        case "capClipBoard":
                            copyCaptureImageToCilpBoard();
                        break;

                        case "capFull":
                            setFullCaptrueButton();
                        break;

                        case "capOff":
                            setCaptureOFFButton(false);
                        break;

                        case "capFlip":
                            setCaptrueFlipButton();
                        break;

                        case "topBarColorButton":
                            setUIColorButton();
                        break;

                        case "gridButton":
                            setGridButton();
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

                        case "dragDropFileButton":
                        {
                            loadImageDragDrop(tempDragDropFile,false);
                            fileDragSelectBox.visible = false;
                        }
                        break;

                        case "dragDropRefButton":
                        {
                            loadImageDragDrop(tempDragDropFile,true);
                            fileDragSelectBox.visible = false;
                        }
                        break;

                        case "dragDropCancelButton":
                        {
                            fileDragSelectBox.visible = false;
                        }
                        break;

                        case "timer":
                        {
                            realWorkingTimer.reset();
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

                        case "traceLoadButton":
                        {
                            setTopChildIndex(traceMenu);
                            checkButtonUp(targetName);
                        }
                        break;

                        case "traceClipButton":
                        {
                            setTopChildIndex(traceMenu);
                            setTraceClipButton();
                        }
                        break;

                        case "traceMirrorButton":
                        {
                            setTopChildIndex(traceMenu);
                            setTraceMirrorButton();
                        }
                        break;

                        case "traceDeleteButton":
                        {
                            setTopChildIndex(traceMenu);
                            setTraceDeleteButton();
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

                        case "replayFitToWindowButton":
                        {
                            if(rFitZoomedON) resetZoomReplayMode();
                            else setReplayFitToWindowButton();
                        }
                        break;

                        case "layerMergeButton":
                        {
                            setLayerMergeButton();
                            topBar.hintTime("Layers has been merged to layer 2",topBar.replayModeButton);
                        }
                        break;

                        case "layerSwapButton":
                        {
                            setLayerSwapButton();
                            topBar.hintTime("Layers has been swapped",topBar.replayModeButton);
                        }
                        break;
                    }
                }
            }
            stage.addEventListener(MouseEvent.MOUSE_UP,buttonUpEvent);
        }

        private function setCanvasSameReplayCanvas():void
        {
            const floor:Function = Math.floor;

            zoomed = rzoomed;
            zoomedIndex = rzoomedIndex;
            regPoint.x = floor(rregPoint.x); //뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
            regPoint.y = floor(rregPoint.y);
            regPoint.scaleX = rregPoint.scaleX;
            regPoint.scaleY = rregPoint.scaleY;
            regPoint.rotation = rregPoint.rotation;
            canvasPanel.x = floor(rcanvasPanel.x);
            canvasPanel.y = floor(rcanvasPanel.y);
        }

        private function resetCutFrameClickCounter():void
        {
            if(cutFrameActiveButton !== null)
            {
                cutFrameActiveButton.removeEventListener(MouseEvent.MOUSE_OUT,resetCutFrameClickCounterEvent);
                cutFrameActiveButton = null;
            }

            stage.removeEventListener(MouseEvent.MOUSE_DOWN,resetCutFrameClickCounterMouseDownEvent);
            cutFrameWithShortcut = false;
            cutFrameClickCounter = 0;
            cutFrameClickedButton = CUT_FRAME_NONE;
            topBar.hintOFF();
            replayTimeBox["replayDeleteBar"].visible = false;
            replayTimeBox["replayNowBar"].visible = true;
        }

        private function resetCutFrameClickCounterMouseDownEvent(e:MouseEvent):void
        {
            if(e.target && cutFrameActiveButton === e.target)
            {

            }
            else
            {
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,resetCutFrameClickCounterMouseDownEvent);
                resetCutFrameClickCounter();
            }
        }

        private function resetCutFrameClickCounterEvent(e:MouseEvent):void
        {
            resetCutFrameClickCounter();
        }

        private function deleteReplayFrontData():void
        {
            const replayTotalBar:Sprite = replayTimeBox["replayTotalBar"] as Sprite;
            const replayNowBar:Sprite = replayTimeBox["replayNowBar"] as Sprite;
            //첫 이미지 새로 만들어줌
            if(rJumpImageFolder.exists) rJumpImageFolder.deleteDirectory(true);
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
                replayNowBar.width = (TOTAL_FRAME === 0) ? 0 : replayTimeBox["replayTotalBar"].width;
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
                replayNowBar.width = 0;
                saveOneTime = false;
                setMakeJumpImage();
            }

            resetReplaySpeedBar();

            playbackFinished = true;
            if(undoIndex > rData.length-1) undoIndex = rData.length-1;
            undoToIndex(undoIndex);
            setDeepUndoOFF();
            checkReplaySpeedState();
        }

        private function setReRecord():void
        {
            setReRecordCopyCanvas();
            clearDataResetVars();
            setCanvasSameReplayCanvas();
            if(replayModeON) setReplayUIOFF();
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
            const _rframeSum:Number = rNowFrame;
            const list:Array = rJumpImageFolder.getDirectoryListing();
            const index:Number = getJumpImageIndex(_rframeSum);
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
            undoData.setRFileTotalFrame(_rframeSum);
            TOTAL_FRAME = _rframeSum;

            if(canvas1BitmapData && canvas1BitmapData !== rcanvas1BitmapData) canvas1BitmapData.dispose();
            canvas1BitmapData = rcanvas1BitmapData.clone();
            canvas1Bitmap.bitmapData = canvas1BitmapData;

            if(canvas11BitmapData && canvas11BitmapData !== rcanvas11BitmapData) canvas11BitmapData.dispose();
            canvas11BitmapData = rcanvas11BitmapData.clone();
            canvas11Bitmap.bitmapData = canvas11BitmapData;

            resetReplayTime();
            resetUndo(true);
            rCursor.visible = true;//대칭된 커서 위치를 갱신해주려고 임시로 켜줌
            checkMirrorCanvasReplayMirror();
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
            setRCursorVisibleOFFUndo();
        }

        private function superUndo():void
        {
            const replayTotalBar:Sprite = replayTimeBox["replayTotalBar"] as Sprite;
            const replayNowBar:Sprite = replayTimeBox["replayNowBar"] as Sprite;
            const bw:Number = replayTotalBar.width;

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
                const _rframeSum:Number = rNowFrame;
                const list:Array = rJumpImageFolder.getDirectoryListing();
                const index:Number = getJumpImageIndex(_rframeSum);
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
                undoData.setRFileTotalFrame(_rframeSum);
                TOTAL_FRAME = _rframeSum;

                if(canvas1BitmapData && canvas1BitmapData !== rcanvas1BitmapData) canvas1BitmapData.dispose();
                canvas1BitmapData = rcanvas1BitmapData.clone();
                canvas1Bitmap.bitmapData = canvas1BitmapData;

                if(canvas11BitmapData && canvas11BitmapData !== rcanvas11BitmapData) canvas11BitmapData.dispose();
                canvas11BitmapData = rcanvas11BitmapData.clone();
                canvas11Bitmap.bitmapData = canvas11BitmapData;

                changeCanvasSize(canvas1Bitmap.width,canvas1Bitmap.height,0,0,false);
                setBackgroundColorDrawMode(RCANVAS_BG_COLOR);
                resetReplayTime();
                setCanvasSameReplayCanvas();
                resetUndo();
                mirrorCommandReady = false;
                appInfoBox.setMirror(rMirrorON);

                previewBox.updateImage(canvas1BitmapData,canvas11BitmapData,CANVAS_BG_COLOR);

                if(canvasWindowON)
                {
                    updateCanvasWindowImage();
                    updateCanvasWindowBitmapSize();
                }
            }

            replayNowBar.width = bw;
            replayTimeBox["frameInfo"].text = TOTAL_FRAME+" / " + TOTAL_FRAME;

            rSpeed = 1; //속도 리셋
            topBar.replaySpeedMoveButton.x = topBar["replaySpeedBar"].x+3;

            setDeepUndoOFF();
            if(quickSidebarON) _quickSidebarOFF();

            saveContinue = false;
        }

        private function getCutFrameOKString():String
        {
            return ((cutFrameWithShortcut) ? STRING_ONEMORE_PRESS_TO_OK
                                                 : STRING_ONEMORE_CLICK_TO_OK);
                                                //  +" (Data in the red area will be deleted)";
        }

        private function setCutFrameRedBar(flag:int):void
        {
            const replayTimeBox:replayTimeBar = replayTimeBox;
            const replayNowBar:Sprite = replayTimeBox["replayNowBar"] as Sprite;
            const deleteBar:Sprite = replayTimeBox["replayDeleteBar"] as Sprite;
            const replayTotalBar:Sprite = replayTimeBox["replayTotalBar"] as Sprite;

            if(flag === CUT_FRAME_SUPER_UNDO)
            {
                const width:Number = (replayTotalBar.width*(rNowFrame/TOTAL_FRAME));
                deleteBar.x = replayTotalBar.x+width;
                deleteBar.width = (replayTotalBar.width-width);
            }
            else if(flag === CUT_FRAME_RE_RECORD)
            {
                deleteBar.x = replayTotalBar.x;
                deleteBar.width = replayTotalBar.width;
            }
            else if(flag === CUT_FRAME_DELETE_FRONT)
            {
                deleteBar.x = replayTotalBar.x;
                deleteBar.width = replayNowBar.width;
            }

            replayNowBar.visible = false;
            deleteBar.visible = true;
        }

        private function doCutFrame(flag:int):void
        {
            if(flag === CUT_FRAME_SUPER_UNDO) superUndo();
            else if(flag === CUT_FRAME_RE_RECORD) setReRecord();
            else if(flag === CUT_FRAME_DELETE_FRONT) deleteReplayFrontData();
        }

        private function getCutFrameHint(flag:int):String
        {
            return (flag === CUT_FRAME_SUPER_UNDO) ?  "Delete back data : "
                  :(flag === CUT_FRAME_RE_RECORD) ? "New file from this image : "
                  :(flag === CUT_FRAME_DELETE_FRONT) ? "Delete front data : "
                  : "";
        }

        private function setCutFrameActiveButton(flag:int):void
        {
            if(flag === CUT_FRAME_SUPER_UNDO) cutFrameActiveButton = topBar["superUndoButton"];
            else if(flag === CUT_FRAME_RE_RECORD) cutFrameActiveButton = topBar["reRecordingButton"];
            else if(flag === CUT_FRAME_DELETE_FRONT) cutFrameActiveButton = topBar["cutPrevDataButton"];
        }

        private function setCutFrameButton(flag:int,shortcutKeyFlag:Boolean):void
        {
            if(isInSaveProgress) return;
            setCutFrameActiveButton(flag);

            if(cutFrameActiveButton.alpha < 1.0)
            {
                resetCutFrameClickCounter();
                return;
            }

            if(replayStartON) stopReplay();

            if(cutFrameClickedButton === CUT_FRAME_NONE)
            {
                cutFrameClickedButton = flag;
                cutFrameClickCounter++;
            }
            else if(cutFrameClickedButton !== flag)
            {
                resetCutFrameClickCounter();
                cutFrameClickedButton = flag;
                cutFrameClickCounter = 1;
                setCutFrameActiveButton(flag);
            }
            else cutFrameClickCounter++;

            if(cutFrameClickCounter === 1)
            {
                toolTipBox.visible = false;
                cutFrameActiveButton.addEventListener(MouseEvent.MOUSE_OUT,resetCutFrameClickCounterEvent);

                if(flag !== CUT_FRAME_RE_RECORD)
                {
                    //데이터 전부 읽고 짤라줘야함
                    if(tickDraw.getIndex() < tickDraw.getDataLength())
                    {
                        drawRemainReplayData();
                        checkCutFrameButtonsActive();
                    }
                    if(rNowFrame >= TOTAL_FRAME)
                    {
                        resetCutFrameClickCounter();
                        return;
                    }
                }

                setCutFrameRedBar(flag);

                if(shortcutKeyFlag)
                {
                    cutFrameWithShortcut = true;
                    topBar.hint(getCutFrameHint(flag)+getCutFrameOKString(),cutFrameActiveButton);
                    stage.addEventListener(MouseEvent.MOUSE_DOWN,resetCutFrameClickCounterMouseDownEvent);
                }
                else
                {
                    cutFrameWithShortcut = false;
                    topBar.hint(getCutFrameOKString(),cutFrameActiveButton);
                }
            }
            else if(cutFrameClickCounter >= 2)
            {
                saveContinue = false;
                resetCutFrameClickCounter();
                doCutFrame(flag);
            }
        }

        private function setTopBarHintOFF():void
        {
            clearDataButtonCount = 0;
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,topBarHintOFFEvent);
            topBarHintClickEventON = false;

            if(captureModeON)
            {
                const hint:String = drawCaptureArea.getRotatedRectSizeString();
                if(hint === "") topBar.hintOFF();
                else
                {
                    topBar.hint(hint+STRING_CAPTURE_OK,topBar.capOff);
                }
            }
            else
            {
                topBar.hintOFF();
            }
        }

        private function topBarHintOFFEvent(e:MouseEvent):void
        {
            if(replayModeON)
            {
                const _replayTimeBox:replayTimeBar = replayTimeBox;
                if(mouseY >= (_replayTimeBox.y+_replayTimeBox.BARSIZE-3)*getUIScale())
                {
                    setTopBarHintOFF();
                }
            }
            else if(mouseY >= topBar.BARSIZE*getUIScale())
            {
                setTopBarHintOFF();
            }
        }

        private function topBarHintONEvent(e:MouseEvent):void //topbarhint
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target || mouseDragON || mouseClickON
            || toolBox2ON || lassoToolON) return;

            const targetName:String = e.target.name;
            if(topBarHintClickEventON === false)
            {
                topBarHintClickEventON = true;
                stage.addEventListener(MouseEvent.MOUSE_DOWN,topBarHintOFFEvent);
            }

            if(targetName !== null)
            {
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
                        str = "Actual working time (click to reset timer)";
                    break;

                    case "playButton":
                        str = "Play (enter, space)";
                    break;

                    case "pauseButton":
                        str = "Pause (enter, space)";
                    break;

                    case "replayPrev":
                        str = "Prev (left, z, .) 1 frame (right-click, shift+left/z/.)";
                    break;

                    case "replayNext":
                        str = "Next (right, x, ,) 1 frame (right-click, shift+right/x/,)";
                    break;

                    case "replaySpeedBarWrapper":
                    {
                        if(rSpeedLastStr === "") str = "Change playback speed (up, down / f, v / h, n)";
                        else str = rSpeedLastStr;
                    }
                    break;

                    case "saveButton":
                    case "repSaveButton":
                        str = "Save (ctrl+s) Save as.. (right-click, shift+ctrl+s)";
                    break;

                    case "loadButton":
                        str = "Load (ctrl+o) Load to Reference layer (right-click, ctrl+shift+o)";
                    break;
                    case "repLoadButton":
                        str = "Load (ctrl+o)";
                    break;

                    case "clipButton":
                        str = "Load clipboard image (ctrl+v, ctrl+n)";
                    break;

                    case "clearButton":
                        str = "New file (esc, backspace, delete)";
                    break;

                    case "captureButton":
                    case "repCaptureButton":
                        str = "Capture mode (ctrl+c, ctrl+m)";
                    break;

                    case "capOff":
                        str = "Exit capture mode (esc, backspace)";
                    break;

                    case "capFull":
                        str = "Save full image (c, m)";
                    break;

                    case "capClipBoard":
                            str = (e.target.alpha === 1.0) ? "Copy "+((drawCaptureArea.isFullImageCapture()) ?
                                                                    "full image"
                                                                    :"selected area image")
                                                            + " to clipboard (v, n)"
                                                            :"Already copied to clipboard";
                    break;

                    case "capTrans":
                        str = "Background color ON/OFF (d, j)";
                    break;

                    case "capRotate":
                        str = "Rotate image (s, k)";
                    break;

                    case "capFlip":
                        str = "Flip image (a, l)";
                    break;

                    case "capLayer1VisibleButton":
                        str = "Layer 1 visible ON/OFF (1, 9)";
                    break;

                    case "capLayer2VisibleButton":
                        str = "Layer 2 visible ON/OFF (2, 0)";
                    break;

                    case "reRecordingButton":
                    {
                        if(cutFrameClickCounter === 1
                        && cutFrameClickedButton === CUT_FRAME_RE_RECORD)
                            str = getCutFrameOKString();
                        else
                            str = "New file from this image (f2)";
                    }

                    break;

                    case "cutPrevDataButton":
                    {
                        if(cutFrameClickCounter === 1
                        && cutFrameClickedButton === CUT_FRAME_DELETE_FRONT)
                            str = getCutFrameOKString();
                        else
                            str = "Delete front data (f3)";
                    }
                    break;

                    case "superUndoButton":
                    {
                        if(cutFrameClickCounter === 1
                        && cutFrameClickedButton === CUT_FRAME_SUPER_UNDO)
                            str = getCutFrameOKString();
                        else
                            str = "Delete back data (f4)";
                    }
                    break;

                    case "gridButton":
                        str = "Grid (f2, f8)";
                    break;

                    case "sideBarOFFButton":
                    case "sideBarOFFButton2":
                        str = "Turn sidebar OFF (tab, \\ )";
                    break;

                    case "sideBarONButton":
                    case "sideBarONButton2":
                        str = "Turn sidebar ON (tab, \\ )";
                    break;

                    case "sideBarPositionButton":
                        str = "Right sidebar (f3)";
                    break;

                    case "sideBarPositionButton2":
                        str = "Left sidebar (f3)";
                    break;

                    case "topBarColorButton":
                        str = "Change UI color (f4)";
                    break;

                    case "dpiButton":
                        str = "Change UI scale (f5), current "+getUIScaleString(uiScaleIndex);
                    break;

                    case "layer1CheckButton":
                    case "layer1UncheckButton":
                        str = "Layer 1 visible ON/OFF (shift+1, shift+9)";
                    break;

                    case "layer2CheckButton":
                    case "layer2UncheckButton":
                        str = "Layer 2 visible ON/OFF (shift+2, shift+0)";
                    break;

                    case "layerSwapButton":
                        str = "Swap layer (shift+q, shift+p)";
                    break;

                    case "layerMergeButton":
                        str = "Merge image to layer 2 (shift+e, shift+o)";
                    break;

                    case "aboutButton":
                        str = "About";
                    break;

                    case "newWindowCloseButton":
                        str = "Close image view window (esc on new window)";
                    break;

                    case "newWindowButton":
                        str = "Open image view window (f6)";
                    break;

                    case "updateButton":
                        str = "Version " + NEW_VERSION + " released!";
                    break;

                    case "drawModeButton": str = "Draw mode (f1, f7)"; break;
                    case "replayModeButton": str = "Replay mode (f1, f7)"; break;
                    case "replayZoomInButton": str = "Zoom in (f5), Reset (right-click)"; break;
                    case "replayZoomOutButton": str = "Zoom out (f6), Reset (right-click)"; break;
                    case "replayFitToWindowButton": str = "Canvas center alignment ON/OFF (right-click on canvas)"; break;
                    case "replayRotateButton": str = "Rotate ("+STRING_RIGHT_CLICK_TO_RESET+")"; break;

                    default:
                    return;
                }

                if(targetName === "replaySpeedBarWrapper")
                    topBar.hint(str,topBar.replaySpeedSet);
                else
                    topBar.hint(str,e.target as DisplayObject);

                setTopChildIndex(topBar);
            }
        }

        private function initReplayDataFile(overWrite:Boolean = false):void //기본 리플레이 파일 만들어줌
        {
            if(repFile.exists === false || overWrite === true)
            {
                const fs:FileStream = new FileStream();
                fs.open(repFile,FileMode.WRITE);
                fs.close();

                if(rJumpImageFolder.exists)
                    rJumpImageFolder.deleteDirectory(true);

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
            rData.length = 0;
            rDataFrame.length = 0;
            rDataBuffer.length = 0;
            readyAddUndoFlag = false;
            undoDelFlag = false;
            setRCursorVisibleOFFUndo();
            deepUndoON = false;
        }

        //창크기에 맞추어서 캔버스를 축소해줌
        private function fitCanvasToWindow(captureMode:Boolean=false,manualFlag:Boolean=false):void
        {
            const replayMode:Boolean = replayModeON;
            const offsetX:Number = 44+STAGE_LEFT_OFFSET+STAGE_RIGHT_OFFSET;
            const offsetY:Number = (captureMode) ? (topBar.BARSIZE)*getUIScale()+45 : (topBar.BARSIZE+replayTimeBox.BARSIZE)*getUIScale()+45;
            const stw:int = stage.stageWidth-offsetX;
            const sth:int = stage.stageHeight-offsetY-STAGE_BOTTOM_OFFSET;
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
                    const _w:Number = w;
                    w = h;
                    h = _w;
                }
            }

            //줌이 1.0 보다 작고 가로 세로 줌비율이 가장 작은걸로 선택
            var z:Number = stw/w;
            const zh:Number = sth/h;

            if(zh < z) z = zh;
            if(z > 1.0) z = 1.0;

            if(captureMode)
            {
                captureZoomed = 1/z;
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

            if(captureMode)
            {
                drawCaptureArea.updateCaptureAreaLineSize();
            }
        }

        private function replayCompleteEffect():void
        {
            const _replayTimeBox:replayTimeBar = replayTimeBox;
            _replayTimeBox["playButton"].visible = true;
            _replayTimeBox["pauseButton"].visible = false;

            setColorTransform(_replayTimeBox["replayNowBar"],uiColorSet[uiColorIndex][5]);

            //재생이 끝나면 전체화면을 보여줌
            if(!mouseClickON)
            {
                fitCanvasToWindow();
                rzoomedIndex = zoomArr.indexOf(1.0);
            }
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

        private function resetReplaySpeedBar():void
        {
            rSpeed = 1; //속도 리셋
            topBar.replaySpeedMoveButton.x = topBar["replaySpeedBar"].x+3;
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

            const sharpData:Array = LASSO_SHARP_DATA;
            var index:uint = Math.abs(Math.floor(scale-1.0));
            if(index > 2) index = 2;

            var sharpen:ConvolutionFilter = new ConvolutionFilter(3,3,sharpData[index][0],sharpData[index][1]);

            lassoBMP.filters = [sharpen];
            lassoBMPsub.filters = [sharpen];
        }

        private function selectReplaySubLayer(flag:Boolean):void
        {
            rSubLayerSave = flag;

            if(flag) rcanvasPanel.setChildIndex(rcanvas2,1);
            else rcanvasPanel.setChildIndex(rcanvas1Bitmap,1);
        }

        private function setReplayPanelSize(w:Number,h:Number,moveX:Number=0,moveY:Number=0,movedFlag:Boolean=false):void
        {
            const cpg:Graphics = rcanvasPanel.graphics;
            const maskg:Graphics = rcanvasPanelMask.graphics;
            const bgColor:uint = RCANVAS_BG_COLOR;
            //캔버스가 회전되어있으면 회전된 방향으로 움직여줘야함

            cpg.clear();
            cpg.beginFill(bgColor);
            cpg.drawRect(0,0,w,h);
            cpg.endFill();

            maskg.clear();
            maskg.beginFill(bgColor);//paneldraw마스크 아무색이나 상관없음 어차피 마스크로 쓸거라
            maskg.drawRect(0,0,w,h);
            maskg.endFill();
            rcanvasPanel.mask = rcanvasPanelMask;//마스크 다시 씌워줌

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

            if(rcanvas1Bitmap.bitmapData && rcanvas1Bitmap.bitmapData !== rcanvas1BitmapData) rcanvas1Bitmap.bitmapData.dispose();
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;

            if(rcanvas11Bitmap.bitmapData && rcanvas11Bitmap.bitmapData !== rcanvas11BitmapData) rcanvas11Bitmap.bitmapData.dispose();
            rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;

            autoScroll.updateRCanvasBounds();
            checkCanvasPanelPos(true);
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
                rcanvas2Draw.graphics.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.BEVEL);
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
            const cd2:Graphics = rcanvas2Draw.graphics;
            const rTinyCursorPos:Point = new Point(0,0);
            //undo인덱스가 처음일때 tickdraw가 아무것도 안해주니까 위치 갱신이 안되서
            //undorefimage갱신 될때 마다 마지막 포인터 위치 저장해주는거
            const rTinyCursorPosFirst:Point = new Point(-1,-1);

            var lineStyleBackup:Array; //tempdone에서 쓰는 플래그임
            var index:uint;
            var data:Array; //데이터 뭉치

            function updateLineStyleBackup(arr:Array):void
            {
                lineStyleBackup = arr;
            }

            function getFirstRCursorPos():Point
            {
                return rTinyCursorPosFirst;
            }

            function resetFirstRCursorPos():void
            {
                rTinyCursorPosFirst.setTo(-1,-1);
            }

            function setFirstRCursorPos(x:Number,y:Number):void
            {
                rTinyCursorPosFirst.setTo(x,y);
            }

            function setFirstRCursorPosCurrent():void
            {
                rTinyCursorPosFirst.setTo(rTinyCursorPos.x,rTinyCursorPos.y);
            }

            function hasRCursorFirstPos():Boolean
            {
                return rTinyCursorPosFirst.x > 0 && rTinyCursorPosFirst.y > 0;
            }

            function updateRCursorPosToFirst():void
            {
                rCursor.x = rTinyCursorPosFirst.x;
                rCursor.y = rTinyCursorPosFirst.y;
            }

            function updateRCursorPos():void
            {
                rCursor.x = rTinyCursorPos.x;
                rCursor.y = rTinyCursorPos.y;
            }

            function setRCursorPosMoveTool(x:Number,y:Number):void
            {
                setRCursorPos(rTinyCursorPos.x+x,rTinyCursorPos.y+y)
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

                rTinyCursorPos.setTo(x,y);
            }

            function getRCursorPos():Point
            {
                return rTinyCursorPos;
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
                if(lineStyleBackup.length !== 2) return [1.0,];

                return lineStyleBackup;
            }

            function drawAll():void
            {
                var len:int = data.length;
                for(var i:int = 0; i < len; i++)
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
                    if((replayStartON && subLayerFlag) !== null && rSubLayerSave !== subLayerFlag)
                    {
                        selectReplaySubLayer(subLayerFlag);
                    }
                }
                else if(rSubLayerSave)
                {
                    selectReplaySubLayer(false);
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

                updateLineStyleBackup([alpha,blendMode]);
                checkSubLayer(subLayer);
                checkAirBrush(airBrush,size);

                if(!fillpen)
                {
                    replayLineStyleReady3(shape,size,color,alpha);
                    cd2.moveTo(startX,startY);
                }
                else
                {
                    cd2.clear();
                    replayLineStyleReady2(false,1,color,1.0);
                    cd2.beginFill(color);
                    cd2.moveTo(startX,startY);
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

                updateLineStyleBackup([alpha,blendMode]);
                checkSubLayer(subLayer);
                checkAirBrush(airBrush,size);

                if(!fillpen)
                {
                    replayLineStyleReady2(shape,size,color,alpha);
                    cd2.moveTo(startX,startY);
                }
                else
                {
                    cd2.clear();
                    replayLineStyleReady2(false,1,color,1.0);
                    cd2.beginFill(color);
                    cd2.moveTo(startX,startY);
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

                updateLineStyleBackup([alpha,blendMode]);
                checkSubLayer(subLayer);
                checkAirBrush(airBrush,size);

                if(!fillpen)
                {
                    replayLineStyleReady(shape,size,color,alpha);
                    cd2.moveTo(startX,startY);
                }
                else
                {
                    cd2.clear();
                    replayLineStyleReady(false,1,color,1.0);
                    cd2.beginFill(color);
                    cd2.moveTo(startX,startY);
                    rcanvas2.alpha = alpha;
                }
            }

            function lineTo(data:Array):void
            {
                const x:Number = data[1];
                const y:Number = data[2];

                cd2.lineTo(x,y);
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
                cd2.clear();

                updateLineStyleBackup([alpha,blendMode]);
                rcanvas2.alpha = alpha;
                cd2.lineStyle(size,color,1,false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
                cd2.drawPath(command,xyData);
                setRCursorPos(xyData[xyData.length-2],xyData[xyData.length-1]);
            }

            function fill(data:Array):void
            {
                const color:Number = data[1];
                const alpha:Number = data[2];
                const blendMode:String = data[3];
                const command:Vector.<int> = data[4];
                const xyData:Vector.<Number> = data[5];

                resetCanvasBlurReplaymode();
                updateLineStyleBackup([alpha,blendMode]);
                rcanvas2.alpha = alpha;
                cd2.clear();
                cd2.lineStyle(1,color);
                cd2.beginFill(color);
                cd2.drawPath(command,xyData);
                setRCursorPos(xyData[xyData.length-2],xyData[xyData.length-1]);
            }

            //이건아마 중간에 쓰다 말거임 그래도 오래된 리플레이 파일을 위해서 남겨둠
            function fill2(data:Array):void
            {
                const color:Number = data[1];
                const alpha:Number = data[2];
                const blendMode:String = data[3];
                const arr:Vector.<Number> = data[4];
                const len:uint = arr.length;

                resetCanvasBlurReplaymode();
                updateLineStyleBackup([alpha,blendMode]);
                rcanvas2.alpha = alpha;
                cd2.clear();
                cd2.lineStyle(1,color);
                cd2.beginFill(color);
                cd2.moveTo(arr[0],arr[1]);

                for(var i:uint = 2;i<len;i+=2)
                {
                    cd2.lineTo(arr[i],arr[i+1]);
                }

                cd2.endFill();
                setRCursorPos(arr[len-2],arr[len-1]);
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
                updateLineStyleBackup([alpha,blendMode]);
                rcanvas2.alpha = alpha;
                cd2.clear();
                cd2.lineStyle(1,color);
                cd2.beginFill(color);
                cd2.drawPath(command,xyData);
                setRCursorPos(xyData[xyData.length-2],xyData[xyData.length-1]);
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
                updateLineStyleBackup([alpha,blendMode]);
                rcanvas2.alpha = alpha;
                cd2.lineStyle(0,0,0);
                cd2.beginFill(color);

                if(shape) cd2.drawRect(startX-size/2,startY-size/2,size,size);
                else cd2.drawCircle(startX,startY,size/2);
                cd2.endFill();

                setRCursorPos(startX,startY);
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

                updateLineStyleBackup([alpha,blendMode]);
                rcanvas2.alpha = alpha;

                checkSubLayer(subLayer);
                checkAirBrush(airBrush,size);

                if(shape) cd2.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.ROUND);
                else cd2.lineStyle(size,color);

                cd2.moveTo(startX,startY);
                cd2.lineTo(endX,endY);

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

                updateLineStyleBackup([alpha,blendMode]);
                rcanvas2.alpha = alpha;

                checkSubLayer(subLayer);
                checkAirBrush(airBrush,size);

                if(shape) cd2.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
                else cd2.lineStyle(size,color);

                cd2.moveTo(startX,startY);
                cd2.lineTo(endX,endY);

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

                const lsbox:Sprite = lassoBox;
                lsbox.x = 0;
                lsbox.y = 0;
                lsbox.scaleX = 1.0;
                lsbox.scaleY = 1.0;
                lsbox.rotation = 0;
                lsbox.visible = false;
            }

            function lasso(data:Array,clearOnly:Boolean):void
            {
                if(data[1].length === 0 || data[2].length === 0) return;

                const oldData:Boolean = typeof(data[4]) === "object";
                //(["lasso",point1,point2,null,lassoInfo]); 원시 버전 데이터 이게 왜 4번에 있는지 모르겠음
                //(["lasso",point1,point2,lassoInfo]); 구버전 데이터
                //(["lasso",point1,point2,lassoInfo,lassoCopyON,canvas1Bitmap.visible,canvas11Bitmap.visible]); 신버전 데이터
                const imageMovedToLasso:Boolean = (oldData)
                                                  ? moveSelectedAreaToLassoBox(true,data[1],data[2],false,false,false)
                                                  : moveSelectedAreaToLassoBox(true,data[1],data[2],data[4],data[5],data[6]);

                if(imageMovedToLasso && !clearOnly)
                {
                    const lassoInfo:Array = (oldData) ? data[4]:data[3];
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

            function tempDone(data:Array):void
            {
                if(airBrushSizeReplayMode > 0 && rzoomed !== 1.0)
                {
                    setBlurCanvasBySizeNoZoomReplayMode();
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                    rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                    cd2.clear();
                    setBlurCanvasBySizeReplayMode(airBrushSizeReplayMode);
                }
                else
                {
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                    rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                    cd2.clear();
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
                cd2.clear();
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

                cd2.clear();
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
                if(!data || data.length === 0) return;

                switch(data[index][0])
                {
                    case "lineStyle": lineStyle(data[index]); break;
                    case "lineStyle2": lineStyle2(data[index]); break;
                    case "lineStyle3": lineStyle3(data[index]); break;
                    case "lineTo": lineTo(data[index]); break;
                    case "sqline": sqline(data[index]); break;
                    case "fill": fill(data[index]); break;
                    case "fill2": fill2(data[index]); break;
                    case "fill3": fill3(data[index]); break;
                    case "dot": dot(data[index]); break;
                    case "line": line(data[index]); break;
                    case "line1": line1(data[index]); break;
                    case "move": move(data[index]); break;
                    case "move1": move1(data[index]); break;
                    case "move2": move2(data[index]); break;
                    case "lasso": lasso(data[index],false); break;
                    case "lassodel": lasso(data[index],true); break;
                    case "mirror": mirror(); break;
                    case "bgColor": bgColor(data[index]); break;
                    case "canvasSize": canvasSize(data[index]); break;
                    case "tempDone": tempDone(data[index]); break;
                    case "drawDone": drawDone(data[index]); break;
                    case "drawDone2": drawDone2(data[index]); break;
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
            const minTime:Number = TOTAL_FRAME/(biasSpeed*STAGE_FRAME);
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
            const _rSpeed:uint = rSpeed;

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
                const _rFrameSum:Number = rNowFrame;
                const getTimeStr:String = getReplayRemainTime(nextFrame,totalF-_rFrameSum,true);
                const timeStr:String = getTimeStr;

                jumpFrame(finalFrame,JUMP_FRAME_ONCE);
                replayTimeBox["frameInfo"].text = _rFrameSum+" / " + totalF + timeStr;
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

            checkHideCursorCount();
        }

        private function doDrawEvent(e:Event):void
        {
            doDraw(rSpeed,JUMP_FRAME_PLAY);
            checkHideCursorCount();
        }
        //jumpFlag  0: 기본 재생 1:탐색바를 마우스를 이용하여 스킵, 2:one frame 이전스트로크, 3:one frame 이후 스트로크
        private function cDoDraw():Function
        {
            //jumpFlag 1번은 마우스 커서로 무작위 스킵, 2,3번은 스트로크 단위혹은 프레임 단위로 앞뒤로 탐색
            const _REPLAY_SLOWDRAW_ACTIVE_SPEED:Number = REPLAY_SLOWDRAW_ACTIVE_SPEED;
            const tcursor:SimpleButton = rCursor;
            const _rfs:FileStream = rFileStream;
            const _CACHE_DIV_10:Number= Math.floor(REPLAY_MAKE_JUMPIMAGE_COUNT/10);
            const _tickDraw:Object = tickDraw;
            const _JUMP_FRAME_PLAY:int = JUMP_FRAME_PLAY;
            const _JUMP_FRAME_ONCE:int = JUMP_FRAME_ONCE;
            const _JUMP_FRAME_BEFORE:int = JUMP_FRAME_BEFORE;
            const _JUMP_FRAME_AFTER:int = JUMP_FRAME_AFTER;

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
                if((rNowFrame - rJumpImageNowFrameLast)/_CACHE_DIV_10 > rCachedJumpImageIndexPush
                &&  rNowFrame > rCachedJumpImageIndexFrame)
                {
                    rFrameCacheImages[rCachedJumpImageIndexPush] = [rcanvas1BitmapData.clone()
                                                ,rcanvas11BitmapData.clone()
                                                ,rcanvas1BitmapData.width
                                                ,rcanvas1BitmapData.height
                                                ,RCANVAS_BG_COLOR
                                                ,rFileCutBytes
                                                ,rNowFrame
                                                ,rMirrorON];

                    rCachedJumpImageIndexPush++;
                    rCachedJumpImageIndexFrame = rNowFrame;
                }
            }

            function readyToReadRData(jumpFlag:int):void
            {
                rDataReadFlag = true;
                rIndex = rIndexStart;
                rIndexStart = 0;
                rDataLen = rData.length;
                if(jumpFlag === _JUMP_FRAME_PLAY)
                {
                    _rfs.close();
                    rLastBytePosition = 0;
                }

                if(rData.length > 0)
                {
                    rPrevFrame = rNowFrame;
                    _tickDraw.ready(rData[rIndex]);
                }
                else
                {
                    _tickDraw.reset();
                }
            }

            function setFileDataToTickDraw():Boolean
            {
                if(_rfs.bytesAvailable > 0)
                {
                    const obj:Array = _rfs.readObject() as Array;
                    _tickDraw.ready(obj);
                    rFileCutBytes = rLastBytePosition;
                    rLastBytePosition = _rfs.position;
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

                    tcursor.visible = false;
                    playbackFinished = true;

                    if(jumpFlag === _JUMP_FRAME_PLAY || doDrawSlowEventON === true)//1프레임 이상일때만 재시작 타이머 가동
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
                if(jumpFlag === _JUMP_FRAME_PLAY || (doDrawSlowEventON && jumpFlag === _JUMP_FRAME_ONCE))
                {
                    savedTime = getTimer();

                    if(savedTime-rFrameCursorDelayTime >= 100)
                    {
                        rFrameCursorDelayTime = savedTime;
                        tickDraw.updateRCursorPos();

                        if(!rFitZoomedON && !mouseClickON && deepUndoON === false)
                        {
                            autoScroll.check();
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
                    if(_tickDraw.isIndexBiggerData())
                    {
                        rIndex++;
                        if(checkFinish(jumpFlag)) return;
                        rPrevFrame = rNowFrame;
                        _tickDraw.ready(rData[rIndex]);
                    }
                    tickDraw.next();
                    rNowFrame++;
                }
            }

            function drawFileData(len:Number,jumpFlag:int):void
            {
                const flag:Boolean = jumpFlag === _JUMP_FRAME_ONCE || jumpFlag === _JUMP_FRAME_BEFORE;
                for(var i:Number=0;i<len;i++)
                {
                    if(_tickDraw.isIndexBiggerData())
                    {
                        // if(checkFinishDeepUndoLimit(jumpFlag)) return;
                        if(setFileDataToTickDraw())
                        {
                            //더이상 읽을 데이터가 없을때 rdata 읽기로 넘겨줌
                            readyToReadRData(jumpFlag);
                            return;
                        }
                        if(flag)
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
                    if(jumpFlag === _JUMP_FRAME_PLAY && jumpCount > REPLAY_SLOWDRAW_ACTIVE_SPEED)
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
            const fps:Number = (slowFrame === true) ? 1 : STAGE_FRAME;
            const floor:Function = Math.floor;
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
                const milisec:Number = totalSec-floor(totalSec);
                const milisecStr:String = milisec.toFixed(1);

                return " ("+milisecStr+")";
            }

            return " ("+timeStr+")";
        }

        private function cAutoScroll():Object
        {
            const abs:Function = Math.abs;
            const floor:Function = Math.floor;
            var offsetY:Number = topBar.BARSIZE+replayTimeBox.BARSIZE;
            const _rregPoint:Sprite = rregPoint;
            const zerop:Point = new Point(0,0);
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

            //rcanvas1 글로벌 좌표에 회전된 캔버스에서 커서 위치를 더해줌. 즉 윈도우 기준에서 커서 커서 위치를 구하는거임
            var isCanvasWidthSmallerStage:Boolean; //캔버스 가로 새로 길이가 스테이지 길이보다 클때 체크
            var isCanvasHeightSmallerStage:Boolean;
            var isNotCenterX:Boolean; //캔버스 중점위치, 창 중점위치 사이 거리
            var isNotCenterY:Boolean;

            const leftLimit:Number = padding;
            const topLimit:Number = padding+offsetY;
            var rightLimit:Number;
            var bottomLimit:Number;

            function updateScale(scale:Number):void
            {
                offsetY = topBar.BARSIZE+replayTimeBox.BARSIZE*scale;
                updateRCanvasBounds();
            }

            function updateRCanvasBounds():void
            {
                bounds = getBoundRect(rcanvas1Bitmap);
                left = bounds.left;
                right = bounds.right;
                top = bounds.top;
                bottom = bounds.bottom;
                stw = stage.stageWidth;
                sth = stage.stageHeight-offsetY;
                zoom = rzoomed;

                isCanvasWidthSmallerStage = right-left > stw;
                isCanvasHeightSmallerStage = bottom-top > sth;
                //캔버스 중점위치, 창 중점위치 사이 거리
                windowCenterPos.setTo(floor(stw/2-(right+left)/2),floor((sth/2-(bottom+top)/2)+offsetY));
                isNotCenterX = abs(windowCenterPos.x) > 0; //캔버스 중점위치, 창 중점위치 사이 거리
                isNotCenterY = abs(windowCenterPos.y) > 0;

                rightLimit = stw-padding;
                bottomLimit = sth+offsetY-padding;
            }

            function check():void
            {
                cp = tickDraw.getRCursorPos();

                globalChecked = false;

                if(!isCanvasWidthSmallerStage)
                {
                    if(isNotCenterX)
                    {
                        _rregPoint.x += windowCenterPos.x;
                        updateRCanvasBounds();
                    }
                }
                else
                {
                    globalChecked = true;
                    gp = rcanvas1Bitmap.localToGlobal(zerop);
                    rg = rotatePoint(cp.x,cp.y,-_rregPoint.rotation);
                    cursorPos.x = gp.x+(rg.x*zoom);

                    if(cursorPos.x < leftLimit)
                    {
                        _rregPoint.x += floor(abs((cursorPos.x-stw/2)/3));
                        updateRCanvasBounds();
                    }
                    else if(cursorPos.x > rightLimit)
                    {
                        _rregPoint.x -= floor(abs((cursorPos.x-stw/2)/3));
                        updateRCanvasBounds();
                    }
                }

                if(!isCanvasHeightSmallerStage)
                {
                    if(isNotCenterY)
                    {
                        _rregPoint.y += windowCenterPos.y;
                        updateRCanvasBounds();
                    }
                }
                else
                {
                    if(globalChecked === false)
                    {
                        globalChecked = true;
                        gp = rcanvas1Bitmap.localToGlobal(zerop);
                        rg = rotatePoint(cp.x,cp.y,-_rregPoint.rotation);
                    }
                    cursorPos.y = gp.y+(rg.y*zoom);

                    if(cursorPos.y < topLimit)
                    {
                        _rregPoint.y += floor(abs((cursorPos.y-sth/2)/3));
                        updateRCanvasBounds();
                    }
                    else if(cursorPos.y > bottomLimit)
                    {
                        _rregPoint.y -= floor(abs((cursorPos.y-sth/2)/3));
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
            var _rSpeed:Number = (isSlowDrawTime(rSpeed))
                                 ? getAutoJumpFrame(rSpeed)/STAGE_FRAME : rSpeed;
                                //오토스킵은 1초마다 넘어가야할 프레임이니까 시간 구하려면 스테이지 프레임을 나누어줌

            const totalF:Number = TOTAL_FRAME;
            const _rFrameSum:Number = rNowFrame;
            const namojiTime:String = (deepUndoON)
                                       ? "" : getReplayRemainTime(_rSpeed,totalF-_rFrameSum);
            replayTimeBox["frameInfo"].text = _rFrameSum+" / " + totalF + namojiTime;
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

        private function setReplaySpeedButton():void
        {
            const totalF:Number = TOTAL_FRAME;

            if(totalF <= STAGE_FRAME*3) // 3초 이내면 안함
            {
                return;
            }

            const topBar:topMenu = topBar;
            const abs:Function = Math.abs;
            const floor:Function = Math.floor;
            const set:Sprite = topBar.replaySpeedSet;
            const minDist:Number = topBar["replaySpeedBar"].x+3;
            const maxDist:Number = minDist+topBar["replaySpeedBar"].width-2;
            const button:SimpleButton = topBar.replaySpeedMoveButton;
            const maxSpeed:Number = REPLAY_MAX_SPEED;
            const clacMax:Number = floor(totalF/(STAGE_FRAME*3));//3초 x 30프레임
            var max:Number = (clacMax > maxSpeed) ? maxSpeed : clacMax;//최고 속도 3초 재생 이지만 REPLAY_MAX_SPEED배속은 넘기지 않음.
            var timeStr:String = getReplayTotalTime(rSpeed);

            penCursorOFFFlag = true;

            function setSpeed(mx:Number):void
            {
                var exp:Number = mx/maxDist;
                if(exp < 0) exp = 0;
                else if(exp > 1) exp = 1;
                var nowSpeed:uint = floor(Math.pow(max,exp));

                if(nowSpeed > max) nowSpeed = max;

                timeStr = getReplayTotalTime(nowSpeed);
                const finalStr:String = STRING_PLAYBACK_SPEED+rSpeed+timeStr;
                topBar.hint(finalStr,topBar.replaySpeedSet);
                rSpeedLastStr = finalStr;
                rSpeed = nowSpeed;
            }

            function moveButton(mx:Number):void
            {
                if(mx < minDist) mx = minDist;
                else if(mx > maxDist) mx = maxDist;

                button.x = mx;
                setSpeed(mx);
            }

            function replaySpeedButtomUpEvent(e:MouseEvent):void
            {
                mouseDragON = false;
                // topBar.hintOFF()
                if(playbackFinished === false) updateReplayRemainTimeText();
                stageMouseMoveEvent.remove("replaySpeedButtomMoveEvent");
                stage.removeEventListener(MouseEvent.MOUSE_UP,replaySpeedButtomUpEvent);
            }

            function replaySpeedButtomMoveEvent(e:MouseEvent):void
            {
                moveButton(set.mouseX);
            }
            moveButton(set.mouseX);
            setSpeed(set.mouseX);

            stageMouseMoveEvent.add("replaySpeedButtomMoveEvent",replaySpeedButtomMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,replaySpeedButtomUpEvent);
        }

        private function getTotalFrameUntilUndoIndex(index:int):Number
        {
            return undoData.getRFileTotalFrame()+undoData.getRDataTotalFrame(index);
        }

        private function getTotalFrame():Number
        {
            return getTotalFrameUntilUndoIndex(rDataFrame.length-1);
        }

        private function getNearZoomIndex(nowZoom:Number):uint
        {
            const arr:Array = zoomArr;
            const len:uint = arr.length-1;
            var low:Number = 0;
            var high:Number = len;
            if(high <= 0) return high;
            var index:Number = Math.floor((low+high)/2);
            var zoom:Number;

            while(low <= high)//2진 탐색
            {
                zoom = arr[index];
                if(zoom === nowZoom) break;
                else if(zoom > nowZoom) high = index-1;
                else low = index+1;

                index = Math.floor((low + high)/2);
            }

            //가장 가까운값 검출
            if(index <= 0) return 0;
            else if(index >= len) return len;
            else if(arr[index+1]-nowZoom < nowZoom-arr[index-1])
            {
                //현재줌이 상위 줌이랑 더 가까우면 인덱스를 올려줌
                return index+1;
            }
            return index;
        }

        //targetFrame이 rFrameCacheImages데이터에 몆 번 인덱스에 있나 구해줌
        private function getCacheImageIndex(targetFrame:Number):Number
        {
            var arr:Array = rFrameCacheImages;
            var low:Number = 0;
            var high:Number = arr.length-1;
            if(high <= 0) return high;
            var index:Number = Math.floor((low+high)/2);
            var indexFrame:Number;

            while(low <= high)//2진 탐색
            {
                indexFrame = arr[index][6];

                if(indexFrame === targetFrame) break;
                else if(indexFrame > targetFrame) high = index-1;
                else low = index+1;

                index = Math.floor((low + high)/2);
            }

            return index;
        }

        //targetFrame이 rJumpImageFrameData데이터에 몆 번 인덱스에 있나 구해줌
        private function getJumpImageIndex(targetFrame:Number):Number
        {
            const arr:Array = rJumpImageFrameData;
            var low:Number = 0;
            var high:Number = arr.length-1;
            if(high <= 0) return high;
            var index:Number = Math.floor((low + high)/2);
            var indexFrame:Number;

            while(low <= high)//2진 탐색
            {
                indexFrame = arr[index];

                if(indexFrame === targetFrame) break;
                else if(indexFrame > targetFrame) high = index-1;
                else low = index+1;

                index = Math.floor((low + high)/2);
            }
            return index;
        }

        //프레임에 따라서 프레임 조작 버튼 활성화 해줌
        private function checkCutFrameButtonsActive():void
        {
            if(makeJumpImageFlag === 2 || isInSaveProgress)
            {
                topBar["superUndoButton"].alpha = BUTTON_OFF_ALPHA;
                topBar["cutPrevDataButton"].alpha = BUTTON_OFF_ALPHA;
                topBar["reRecordingButton"].alpha = BUTTON_OFF_ALPHA;
            }
            else
            {
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

                if(TOTAL_FRAME === 0)
                {
                    topBar["reRecordingButton"].alpha = BUTTON_OFF_ALPHA;
                }
                else
                {
                    topBar["reRecordingButton"].alpha = 1.0;
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
                        //rPrevFrame이 rNowFrame이 같거나 크게 되면 jumpframe에서 0프레임을 이동하므로
                        //-1을 해줘서 tickdarw에서 rPrevFrame를 고쳐주고 해줘야함
                        if(rPrevFrame >= rNowFrame)
                        {
                            jumpFrame(rNowFrame-1,JUMP_FRAME_BEFORE);
                        }
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
            checkCutFrameButtonsActive();

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
            if(setHoldKeyRepeat(jumpOneFrame,toBackFlag,oneFrame) === true)
            {
                playbackFinished = false;
                if(cutFrameClickCounter > 0) resetCutFrameClickCounter();
                if(replayStartON) stopReplay();
            }
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

            //미리 찍어둔 이미지로 캔버스를 설정
            if(updateRCavanvasImageFlag > 0 || frame < rNowFrame)
            {
                var jumpImageData:Array;
                var tempBmpd:BitmapData;
                var tempBmpd1:BitmapData;

                if(updateRCavanvasImageFlag === 2)
                {
                    jumpImageData = rFrameCacheImages[cachedJumpImageIndex];
                    tempBmpd = jumpImageData[0].clone();
                    tempBmpd1 = jumpImageData[1].clone();
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

                    const newrect:Rectangle = new Rectangle(0,0,jumpImageData[2],jumpImageData[3]);
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
                frame = frame-jumpImageData[6];
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

                if(updateRCavanvasImageFlag === 1)
                {
                    rFrameCacheImages[0] = [rcanvas1BitmapData.clone()
                                            ,rcanvas11BitmapData.clone()
                                            ,rcanvas1BitmapData.width
                                            ,rcanvas1BitmapData.height
                                            ,RCANVAS_BG_COLOR
                                            ,rLastBytePosition
                                            ,rNowFrame
                                            ,rMirrorON];
                }

                jumpImageData = null;
                rDataReadFlag = false;
                rIndexStart = 0;
                tempBmpd.dispose();
                tempBmpd1.dispose();
                tempBmpd = null;
                tempBmpd1 = null;
            }
            else
            {
                if(!rDataReadFlag) rFileStream.position = rLastBytePosition;
                frame = frame - rNowFrame;
            }

            doDraw(frame,jumpflag,replayModeON);
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

            if(!rFitZoomedON || !deepUndoON)
            {
                autoScroll.check();
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
            if(totalF === 0 || makeJumpImageFlag > 0) return;

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

            const floor:Function = Math.floor;
            const totalBar:Sprite = replayTimeBox["replayTotalBar"];
            const totalBarScale:Number = totalBar.scaleX;
            const nowBar:Sprite = replayTimeBox["replayNowBar"];
            const maxWidth:Number = totalBar.width;//replayPrograssBaseBarWidth*scaleX;
            var clickedX:Number = totalBar.mouseX*totalBarScale;
            var oldFrame:Number = floor(totalF*clickedX/maxWidth);
            var finalFrame:Number = 0;

            nowBar.width = clickedX;
            checkBarLimit();
            oldFrame = finalFrame;
            playbackFinished = false;
            replayTimeBox.resetNowbarColor();

            function checkBarLimit():void
            {
                var mx:Number = totalBar.mouseX*totalBarScale;

                if(mx < 0) mx = 0;
                else if(mx > maxWidth) mx = maxWidth;

                finalFrame = floor(totalF*mx/maxWidth);
                nowBar.width = mx;
            }

            function replayTimeMouseUpEvent(e:MouseEvent):void
            {
                removeTimer("jumpFrameUpdateTimer");
                jumpFrame(finalFrame,JUMP_FRAME_ONCE);
                oldFrame = finalFrame;
                checkBarLimit();

                //jumpframe함수 이후에 실행
                if(!replayStartONSave) checkCutFrameButtonsActive();

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

                stageMouseMoveEvent.remove("replayTimeMouseMoveEvent");
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
            stageMouseMoveEvent.add("replayTimeMouseMoveEvent",replayTimeMouseMoveEvent);
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
            checkCutFrameButtonsActive();
            replayHideCursor.reset();
        }

        private function startReplay():void
        {
            if(replayStartON || TOTAL_FRAME === 0)
            {
                return; //혹시 몰라서 중복 클릭 제거 걸어줌
            }

            const tb:Sprite = topBar;

            replayStartON = true;
            replayTimeBox.resetNowbarColor();
            replayTimeBox["playButton"].visible = false;
            replayTimeBox["pauseButton"].visible = true;
            tb["reRecordingButton"].alpha = 1.0;
            tb["superUndoButton"].alpha = 1.0;
            tb["cutPrevDataButton"].alpha = 1.0;

            rCursor.visible = true;

            if(playbackFinished === true) //리플레이 시간 등등 초기화 시키고 시작
            {
                rMirrorON = false;
                resetReplayTime();
                clearCanvasReplayMode();
                drawFirstJumpImage();
                rDataReadFlag = false;
                playbackFinished = false;//resetReplayTime함수 에서 이걸 true로 해주기 때문에 아래쪽에서 변경
                resetRotationReplayMode();
                if(!rFitZoomedON) setZoomCanvas(1.0,true);
                autoScroll.updateRCanvasBounds();
                selectReplaySubLayer(false);
            }

            if(replayEndWithCanvasFitWindow === true)
            {
                replayEndWithCanvasFitWindow = false;
                setZoomCanvas(rzoomed,true);
            }

            if(!rDataReadFlag)
            {
                rFileStream.open(repFile,FileMode.READ);
                rFileStream.position = rLastBytePosition;
            }

            if(cutFrameClickCounter > 0) resetCutFrameClickCounter();
            if(rFitZoomedON) fitCanvasToWindowManualReplayMode();

            stage.addEventListener(Event.ENTER_FRAME,doDrawEvent);
        }

        private function moveToolBoxByType(type:int=0):void
        {
            var xBox:Sprite = null;

            if(type === 1) xBox = lassoMenu;
            else if(type === 2) xBox = traceMenu;

            const click:Point = new Point(mouseX,mouseY);
            setTopChildIndex(xBox);

            function toolBoxMoveMouseUpEvent(e:MouseEvent):void
            {
                checkBoxPosition(xBox);
                stageMouseMoveEvent.remove("toolBoxMoveMouseMoveEvent");
                stage.removeEventListener(MouseEvent.MOUSE_UP, toolBoxMoveMouseUpEvent);
            }

            function toolBoxMoveMouseMoveEvent(e:MouseEvent):void
            {
                xBox.x += mouseX-click.x;
                xBox.y += mouseY-click.y;

                click.x = mouseX;
                click.y = mouseY;
            }

            stageMouseMoveEvent.add("toolBoxMoveMouseMoveEvent",toolBoxMoveMouseMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,toolBoxMoveMouseUpEvent);
        }

        private function checkToolBoxButtonUpEvent(e:MouseEvent):void
        {
            stage.removeEventListener(MouseEvent.MOUSE_UP,checkToolBoxButtonUpEvent);

            const targetName:String = e.target.name;

            if(toolBoxClickedTarget !== targetName)
            {
                toolBoxClickedTarget = "";
                return;
            }

            toolBoxClickedTarget = "";

            switch(targetName)
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
                        updateOldTool();
                        spuitTool();
                    }
                }
                break;

                case "toolUndo": setUndoButton(false); break;
                case "toolRedo": setRedoButton(false); break;
                case "toolMirror": mirrorCanvas(); break;
                case "toolMove": selectMoveTool(); break;
                case "zoomInButton": setZoomInButton(true,false); break;
                case "zoomOutButton": setZoomInButton(false,false); break;
                case "toolZoom": toolBox.zoomIconON(); break;

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

        private function _setBackgroundColor(xCanvas:Sprite,w:Number,h:Number,color:uint):void
        {
            const cg:Graphics = xCanvas.graphics;
            cg.clear();
            cg.beginFill(color);
            cg.drawRect(0,0,w,h);
            cg.endFill();
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
        }

        private function changeToolTipString(str:String):void
        {
            const _toolTipBox:toolTipBoxSet = toolTipBox;
            const info:TextField = _toolTipBox["toolTipInfoText"];
            info.text = str;
            info.width = info.textWidth+20;
            _toolTipBox["toolTipBoxBG"].width = info.textWidth+6;
        }

        private function toolTipBoxTimerOFF():void
        {
            removeTimer("toolTipTempONTimer");
            toolTipBox.visible = false;
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,toolTipBoxTimerOFFEvent);
        }

        private function toolTipBoxTimerOFFEvent(e:MouseEvent):void
        {
            toolTipBoxTimerOFF();
        }

        private function setToolTipTempON(str:String,customX:Number=NaN,customY:Number=NaN,time:Number=2.5):void
        {
            if(!hasTimer("toolTipTempONTimer"))
            {
                stage.addEventListener(MouseEvent.MOUSE_DOWN,toolTipBoxTimerOFFEvent);
            }

            addTimerByName("toolTipTempONTimer",time,false,function():void
            {
                toolTipBoxTimerOFF();
            });

            setToolTipON(str,customX,customY);
            toolTipBox.visible = true;
        }

        private function moveToolTipString():void
        {
            const tb:toolTipBoxSet = toolTipBox;
        }

        private function setToolTipON(str:String,mx:Number=NaN,my:Number=NaN):void
        {
            const _toolTipBox:toolTipBoxSet = toolTipBox;
            const floor:Function = Math.floor;
            const toolTipText:TextField = _toolTipBox["toolTipInfoText"];

            if(str !== "")
            {
                toolTipText.text = str;
                _toolTipBox["toolTipBoxBG"].width = floor(toolTipText.textWidth+8);
                _toolTipBox["toolTipBoxBG"].height = floor(toolTipText.textHeight+((str.lastIndexOf("\n") === -1)?2:5));
            }

            if(!mx)
            {
                my = mouseY;
                mx = mouseX;
            }

            const width:int =_toolTipBox["toolTipBoxBG"].width*_toolTipBox.scaleX;
            const height:Number =  _toolTipBox["toolTipBoxBG"].height*_toolTipBox.scaleX;
            const stw:uint = stage.stageWidth+1;
            const sth:uint = stage.stageHeight+1;
            const rightLimit:Number = stw;
            const bottomLimit:Number = sth;
            var tooltipX:Number = floor(mx-width/2)+5;
            var tooltipY:Number = floor(my-45);
            const right:int = tooltipX+width;
            const bottom:int = tooltipY+height;

            if(tooltipX < STAGE_LEFT_OFFSET) tooltipX = STAGE_LEFT_OFFSET;
            else if(right > rightLimit-STAGE_RIGHT_OFFSET) tooltipX = rightLimit-STAGE_RIGHT_OFFSET-width;

            if(tooltipY < STAGE_TOP_OFFSET) tooltipY = STAGE_TOP_OFFSET;
            else if(bottom >= bottomLimit-STAGE_BOTTOM_OFFSET) tooltipY = bottomLimit-STAGE_BOTTOM_OFFSET-height;

            _toolTipBox.x = floor(tooltipX);
            _toolTipBox.y = floor(tooltipY);
            setTopChildIndex(_toolTipBox);
        }

        //drag load
        private function setDragDropSelectBoxCenterPos():void
        {
            const box:loadBox = fileDragSelectBox;
            const bg:Sprite = box["dragDropFileBG"];
            bg.x = 0;
            bg.y = 0;
            bg.width = 1;
            bg.height = 1;
            box.scaleX = 1.0;
            box.scaleY = 1.0;

            const stw:Number = stage.stageWidth;
            const sth:Number = stage.stageHeight;
            const f1:Number = stw/box.width; //가장 짧은 길이를 기준으로 비율을 삼음
            const f2:Number = sth/box.height;
            const f:Number = (f1 <= f2) ? f1:f2;
            box.scaleX = 1.0;
            box.scaleY = 1.0;
            box.x = stw/2 - box.width/2;
            box.y = sth/2 - box.height/2;
            bg.x = -box.x;
            bg.y = -box.y;
            bg.width = stw;
            bg.height = sth;
        }

        private function setDragDropSelectBoxReady(filename:String=""):void
        {
            resetKeyBuffer();
            if(fileDragSelectBox.visible === false)
            {
                if(lassoToolON === true)
                {
                    setLassoCancelButton();
                    resetLassoBox();
                    resetOldTool();
                    selectPenTool();
                }

                setDragDropSelectBoxCenterPos();
                fileDragSelectBox.visible = true;
                setTopChildIndex(fileDragSelectBox);
            }

            if(toolBox2ON) closeToolBox2();
        }

        private function onDragDropEvent(e:NativeDragEvent):void
        {
            rFileStream.close();
            cancelRestartTimer();

            tempDragDropFile = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT);

            var file:File = File(tempDragDropFile[0]);
            const fileName:String = file.name;
            const ext:String = fileName.substr(fileName.lastIndexOf(".")+1,fileName.length);
            if(ext === "2020" || ext === "png" || ext === "jpg" || ext === "gif")
            {
                setDragDropSelectBoxReady(file.name);
            }
        }

        private function onDragEnterEvent(e:NativeDragEvent):void
        {
            if(captureModeON === true) return;
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

        private function loadImageDragDrop(obj:Object,isTraceLayer:Boolean):void
        {
            if(tempCopiedImage) //클립보드에 이미지가 있으면
            {
                if(!isTraceLayer)
                {
                    const fileName:String = "Clipboard_image_"+clipImageNameCount+".png";
                    //두번째 변수에서 fileName를 같게 해줘야 저장할때 오류가 안남
                    loadImageFile(fileName,fileName,tempCopiedImage.width,tempCopiedImage.height,tempCopiedImage,null);
                }
                else if(isTraceLayer)
                {
                    pasteTraceImage(tempCopiedImage,tempCopiedImage.width,tempCopiedImage.height);
                    if(!replayModeON) openTraceWindow();
                }
                tempCopiedImage = null;
            }
            else if(obj.length > 0) //파일 드래그로 직접 해줄때
            {
                //grab the files file
                var file:File = File(obj[0]);
                var fs:FileStream = new FileStream();
                var loader:Loader = new Loader();
                var tmpFileName:String = "";

                fs.addEventListener(Event.COMPLETE, completeHandler);
                fs.addEventListener(IOErrorEvent.IO_ERROR, errorHandler)

                //실제적으로 loader가 읽어서 캔버스에 그림
                function loaderIOErrorHandlerEvent(e:Event):void
                {
                    topBar.hintLoadError();
                    tempDragDropFile = null;
                    loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, loaderIOErrorHandlerEvent);
                    loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, startDrawImgEvent);
                    loader = null;
                }

                function startDrawImgEvent(e:Event):void //drag load1
                {
                    var loaderInfo:LoaderInfo = LoaderInfo(e.target);

                    if(!isTraceLayer)
                    {
                        if(tempCopiedImage)
                        {
                            loadImageFile("Paste Image",saveFilePath,tempCopiedImage.width,tempCopiedImage.height,tempCopiedImage,null);
                            tempCopiedImage = null;
                        }
                        else
                        {
                            loadImageFile(tmpFileName,file.nativePath,loaderInfo.width,loaderInfo.height,loaderInfo.loader,null);
                        }

                    }
                    else if(isTraceLayer)
                    {
                        if(tempCopiedImage)
                        {
                            pasteTraceImage(tempCopiedImage,tempCopiedImage.width,tempCopiedImage.height);
                            tempCopiedImage = null;
                        }
                        else
                        {
                            pasteTraceImage(loaderInfo.loader,loaderInfo.width,loaderInfo.height);
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
                    if(is2020Ext(file.name) === true)
                    {
                        if(!isTraceLayer)
                        {
                            loadReplayFile(file,file.name,file.nativePath);
                        }
                        else
                        {
                            loadRawFileToReferenceLayer(file);
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

                function errorHandler(e:Event):void
                {
                    fs.close();
                    fs.removeEventListener(Event.COMPLETE, completeHandler);
                    fs.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
                    fs = null;
                    tempDragDropFile = null;
                }

                tmpFileName = file.name;
                fs.openAsync(file, FileMode.READ);
            }
        }

        private function selectHistoryColor():void
        {
            const _pickerMode:uint = pickerMode;
            const historyBox:Sprite = pickerBox.colorHistoryBox;
            const floor:Function = Math.floor;
            const arr:Array = colorHistoryList;
            const mx:Number = historyBox.mouseX;
            const my:Number = historyBox.mouseY;
            const inX:int = floor(mx/colorHistoryColorWidth);
            const inY:int = floor(my/colorHistoryRectH);//히스토리 컬러 높이 나누고 몫을 구함
            const index:int = inX+(inY*10); //10개씩 한줄이니까 10을 더해줌 이거 10개 정해주는건 updateColorHistoryList의 for문에서 %연산으로 해줌

            if(index > arr.length-1) return;

            const pickedColor:uint = arr[index];
            var c:Vector.<uint> = HEXtoRGB(pickedColor);
            var findIndex:uint = arr.lastIndexOf(pickedColor);
            const colorHint:String = "RGB "+c[0]+","+c[1]+","+c[2];

            updateOpaBoxColor(pickedColor);

            if(_pickerMode === 2)
            {
                updateColorHistoryList();
                setBackgroundColorDrawMode(pickedColor);
                if(canvasWindowON) updateCanvasWindowCanvasPanelBGColor(CANVAS_BG_COLOR,canvasWindowBitmap.bitmapData);
                addUndoBGColor(pickedColor);
            }
            else if(_pickerMode === 1)
            {
                // changedColor = pickedColor;
                penColor = pickedColor;
                setHSVCursorPosByColor(pickedColor);
                forceSetMainDrawTool();
            }

            const invColor:uint = getInvertColor(pickedColor,1.0);

            pickerColorSelected = true;

            if(!colorHistoryUpdateReady && findIndex !== -1)
            {
                colorHistoryUpdateReady = true;
                stage.addEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryEvent);
            }
        }

        private function addColorToHistoryManual():void
        {
            const color:uint = (pickerMode === 2) ? CANVAS_BG_COLOR:penColor;
            changedColor = color;
            const arr:Array = colorHistoryList;
            const c:Vector.<uint> = HEXtoRGB(color);

            addColorToHistory(color);

            setToolTipTempON("Added RGB "+c[0]+","+c[1]+","+c[2]);
            toolTipBox.visible = true;
        }

        //최근에 쓴 컬러를 항상 마지막에 오게함
        private function setColorHistoryLastColorByIndex(index:int):void
        {
            const arr:Array = colorHistoryList;
            const arrlength:int = arr.length;
            const lastIndex:int = arr.length-1;

            if(arrlength > 0 && index !== lastIndex)
            {
                arr.push(arr[index]);
                arr.splice(index,1);
            }
        }

        //최근에 쓴 컬러를 항상 마지막에 오게함
        private function setColorHistoryLastColor(color:uint):void
        {
            const index:int = colorHistoryList.lastIndexOf(color);
            setColorHistoryLastColorByIndex(index);
        }

        private function addColorToHistory(color:uint):void
        {
            const arr:Array = colorHistoryList;
            const findIndex:int = arr.lastIndexOf(color);
            //리스트 안에 컬러가 있으면 넣어주지 않음
            if(findIndex === -1)
            {
                arr.push(color);

                if(arr.length > colorHistoryLimit)
                {
                    arr.splice(0,1);
                }
            }
            else setColorHistoryLastColorByIndex(findIndex);

            updateColorHistoryList();
        }

        private function getColorBright(color:uint,alpha:Number=1.0):Number
        {
            const round:Function = Math.round;
            const c:Vector.<uint> = HEXtoRGB(color);
            const intAlpha:Number = (1 - alpha) * 255;//흰배경색을 기준으로 계산
            const r:uint = round(intAlpha + alpha*c[0]);
            const g:uint = round(intAlpha + alpha*c[1]);
            const b:uint = round(intAlpha + alpha*c[2]);
            const bright:Number = ((r*299)+(g*587)+(b*114))/1000;

            return bright;
        }

        //주어진 컬러 알파값을 기반으로 반전 컬러를 구함
        private function getInvertColor(color:uint,alpha:Number=1.0,bright:uint=0xC7C7C7,dark:uint=0x616161):uint
        {
            const bgContrast:Number = getColorBright(color,alpha);

            color = (bgContrast >= 137) ? dark : bright;
            return color; //밝은색일때 반전색 / 어두울때 반전색
        }

        private function updateColorHistoryList():void
        {
            const arr:Array = colorHistoryList;
            const cg:Graphics = pickerBox.colorHistoryBox.graphics;
            const w:Number = colorHistoryColorWidth;
            const h:Number = colorHistoryRectH;
            const len:int = arr.length;

            cg.clear();
            for(var i:int=0;i<len;i++)
            {
                cg.beginFill(arr[i]);
                cg.drawRect(i*w,0,w,h);
            }
            cg.endFill();
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

        private function clearRFrameCacheImages():void
        {
            var _rFrameCacheImages:Array = rFrameCacheImages;
            const len:uint = _rFrameCacheImages.length;
            var i:int = 0;
            while(i<len)
            {
                if(_rFrameCacheImages[i][0])
                {
                    _rFrameCacheImages[i][0].dispose();
                    _rFrameCacheImages[i][1].dispose();
                    _rFrameCacheImages[i][2] = null;
                    _rFrameCacheImages[i][3] = null;
                    _rFrameCacheImages[i][4] = null;
                    _rFrameCacheImages[i][5] = null;
                    _rFrameCacheImages[i][6] = null;
                    _rFrameCacheImages[i][7] = null;
                }
                i++;
            }
            rFrameCacheImages.length = 0;
            _rFrameCacheImages = null;
            rJumpImageIndexLast = -2;
            rCachedJumpImageIndexLast = -2;
            rCachedJumpImageIndexPush = 1;
            rCachedJumpImageIndexFrame = 0;
        }

        private function makeJumpImage():void //loadrep
        {
            const fs:FileStream = new FileStream();
            const fs2:FileStream = new FileStream();
            const cd2:Graphics = rcanvas2Draw.graphics;
            const totalSize:Number = repFile.size;
            const _REPLAY_MAKE_JUMPIMAGE_COUNT:uint = REPLAY_MAKE_JUMPIMAGE_COUNT;
            const replayInfoText:TextField = replayTimeBox["frameInfo"];
            const topBarHint:Function = topBar.hint;
            const topBarSaveButton:SimpleButton = topBar.saveButton;
            const deepUndoFlag:Boolean = deepUndoON;
            const loadingStr:String = "Reading replay data.. ";
            var rect:Rectangle;
            var _frameSum:Number = 0;
            var _frameSumLast:Number = 0;
            var _rJumpImageCount:uint = 0;
            var _tickDraw:Object = tickDraw;
            var data:Array;
            var imgData:ByteArray = new ByteArray();
            var imgData1:ByteArray = new ByteArray();

            regPoint.visible = false;
            rregPoint.visible = false;
            undoData.resetRJumpImageCount();
            clearCanvasReplayMode();//일단 리플레이 캔버스 먼저 깨끗하게
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

            function onFrameEnter(e:Event):void
            {
                while(1)
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

                        if(!replayModeON && deepUndoON)
                        {
                            rDataReadFlag = false;
                            topBar.hintOFF();
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
                            checkCutFrameButtonsActive();
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
                        return;
                    }

                    data = fs.readObject() as Array;
                    _tickDraw.ready(data);
                    _frameSumLast = _frameSum;
                    _frameSum += data.length;
                    _rJumpImageCount += data.length;
                    _tickDraw.drawAll();

                    if(_rJumpImageCount > _REPLAY_MAKE_JUMPIMAGE_COUNT)
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

                        if(deepUndoFlag) topBarHint(loadingStr+Math.floor(((totalSize-namojiBytes)/totalSize)*100)+"%",topBarSaveButton);
                        else replayInfoText.text = loadingStr+Math.floor(((totalSize-namojiBytes)/totalSize)*100)+"%";

                        return;
                    }
                }
            }
            stage.addEventListener(Event.ENTER_FRAME,onFrameEnter);
        }

        private function setSaveProgressOFF():void
        {
            topBar.setButtonAlphaONSaving(clipImageON);
            if(replayModeON) checkCutFrameButtonsActive();
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
                    const traceImgInfo:Array = tracePosInfo;
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
                    const _rData:Array = rData;
                    var _readUndoArray:Array;
                    for(var i:int=0,len:int=undoIndex;i<=len;i++)//리플레이 데이터랑 첫이미지 마지막 이미지 추가적으로 붙여줌
                    {
                        _readUndoArray = _rData[i] as Array;
                        if(_readUndoArray.length === 0) continue;
                        replayDataBytes.writeObject(_readUndoArray);
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
            const _traceBmpd:BitmapData = canvasTraceBitmapData;
            const traceImgWidth:Number = _traceBmpd.width;
            const traceImgHeight:Number = _traceBmpd.height;
            const _tracePosInfo:Array = tracePosInfo;

            const pathStr:String = saveFilePath;
            const newPath:String = pathStr.substr(0,pathStr.lastIndexOf(".png"))+".2020";
            const copyFile:File = new File(newPath);

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

            if(_traceBmpd)
            {
                fs.writeObject(["traceImage",dataC, // 1
                                            traceImgWidth,
                                            traceImgHeight,
                                            _tracePosInfo[0],
                                            _tracePosInfo[1],// 5
                                            _tracePosInfo[2],
                                            _tracePosInfo[3],
                                            _tracePosInfo[4],
                                            _tracePosInfo[5],
                                            traceReizeMoveSum,//10
                                            CANVAS_TRACE_ALPHA]);//11
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
                topBar.hintSaveError();
                if(repFileTemp.exists) repFileTemp.deleteFile();
                setSaveProgressOFF();
                saveFile(true,true);
            }

            if(isInSaveProgress === 1) isInSaveProgress = 0;

            setSaveProgressOFF();
        }

        private function loadReplayFile(oldFile:File,fileName:String,filePath:String):void //loadrep
        {
            if(isTrue2020File(oldFile) === false)return;
            if(replayModeON)  setReplayUIOFF();

            removeInputEventDrawMode();

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

            if(traceRawArr)
            {
                traceRawBMPD.dispose();
                traceRawBMPD = null;
                traceRawArr = null;
            }

            fs.open(repFileTemp,FileMode.READ);
            rJumpImageFrameData = [0];

            var d:Array;
            var ba:ByteArray;
            var replayData:ByteArray = new ByteArray();
            const _isNewFOFOSaveFormat:Boolean = isNewFOFOSaveFormat;

            if(_isNewFOFOSaveFormat)
            {
                isNewFOFOSaveFormat = false;
                const a:String = fs.readUTFBytes(9); //FOFOPAINT헤더 읽어줌
                const compBytes:uint = fs.readUnsignedInt(); // 압축된 데이터 길이 읽어줌
                if(compBytes > 0)
                {
                    //압축된 데이터 써주고 압축 풀어줌
                    fs.readBytes(replayData,0,compBytes);
                    replayData.uncompress();
                }
            }

            while(1)
            {
                if(fs.bytesAvailable === 0) break;
                d = fs.readObject()

                if(d[0] === "rFirstImage") //리플레이 첫 이미지 파일
                {
                    if(d[2] as ByteArray === null)
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
                    if(d[2] as ByteArray === null)
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
                    traceRawArr = d.concat();
                }
                else if(_isNewFOFOSaveFormat) //신포멧인데 rData옛 버전에서rData압축안하고 넣어준거 읽어줌
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

            if(_isNewFOFOSaveFormat)
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
            addInputEventDrawMode();
        }

        private function loadRawFileToReferenceLayer(file:File):void
        {
            if(isTrue2020File(file) === false)
            {
                topBar.hintLoadError();
                return;
            }

            const fs:FileStream = new FileStream();
            fs.open(file,FileMode.READ);
            var finalIMGBMPD:BitmapData;
            var finalIMGBMPD1:BitmapData;

            const _isNewFOFOSaveFormat:Boolean = isNewFOFOSaveFormat;
            if(_isNewFOFOSaveFormat)
            {
                isNewFOFOSaveFormat = false;
                fs.readUTFBytes(9); //FOFOPAINT헤더 읽어줌
                const compBytes:uint = fs.readUnsignedInt(); // 압축된 데이터 길이 읽어줌
                fs.position += compBytes;
            }

            var ba:ByteArray;
            var newRectangle:Rectangle;

            while(1)
            {
                if(fs.bytesAvailable === 0) break;
                const d:Array = fs.readObject() as Array;

                if(d[0] === "rFinalImage")
                {
                    if(d[2] as ByteArray === null)
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

                        finalIMGBMPD.draw(finalIMGBMPD1);
                        finalIMGBMPD1.dispose();
                    }
                }
            }
            fs.close();

            pasteTraceImage(finalIMGBMPD,finalIMGBMPD.width,finalIMGBMPD.height);

            if(!replayModeON)
            {
                openTraceWindow();
            }
        }

        private function loadImageFile(fileName:String,filePath:String,width:Number,height:Number,imageData:IBitmapDrawable,imageData1:IBitmapDrawable):void
        {
            if(replayModeON) setReplayUIOFF();
            TOTAL_FRAME = 0;
            undoData.setRFileTotalFrame(0);
            makeJumpImageFlag = 0;
            traceRawBMPD = null;
            traceRawArr = null;
            loadFileAfter(fileName,filePath,width,height,imageData,imageData1,true,0xFFFFFF);
            initReplayDataFile(true); //일단 썸네일 이미지랑 리플레이 데이터 청소
        }

        private function loadFileAfter(fileName:String,filePath:String, width:uint,height:uint,imageData:IBitmapDrawable,imageData1:IBitmapDrawable,imageOnlyFlag:Boolean,newBG:uint):void
        {
            if(!imageData)
            {
                topBar.hintLoadError();
                return;
            }

            const floor:Function = Math.floor;
            var maxLength:Number = (width > height) ? width : height;
            var scaleFix:Number = (maxLength > CANVAS_MAX_SIZE) ? CANVAS_MAX_SIZE/maxLength : 1.0;
            const scaledwidth:Number = floor(width*scaleFix);
            const scaledheight:Number= floor(height*scaleFix); //CANVAS_MAX_SIZE 값을 넘으면 리사이즈 해줌
            var scaleMat:Matrix = new Matrix();
            scaleMat.scale(scaleFix,scaleFix);
            var tmpBMPD:BitmapData = new BitmapData(scaledwidth,scaledheight,true,0);

            if(captureModeON)
            {
                captureOFF();
            }

            resetReplaySpeedBar();
            resetReplayTime();
            clearCanvasReplayMode();
            replayTimeBox["frameInfo"].text = "0 / " + getTotalFrame()+" frame";
            replayTimeBox["replayNowBar"].width = 0;

            setBackgroundColorDrawMode(newBG);
            setBackgroundColorReplayMode(newBG);
            if(canvasWindowON) updateCanvasWindowCanvasPanelBGColor(CANVAS_BG_COLOR,canvasWindowBitmap.bitmapData);

            if(is2020Ext(fileName) === true)
            {
                fileName = fileName.substr(0,fileName.lastIndexOf(".2020"))+".png";
                filePath = filePath.substr(0,filePath.lastIndexOf(".2020"))+".png";
            }

            saveFileName = fileName;
            saveFilePath = filePath;
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

            tmpBMPD.dispose();
            tmpBMPD = null;
            regPoint.rotation = 0;
            zoomedIndex = 3;
            setZoomCanvas(1.0);
            updatePenSizeCursor();
            //bitmapdata가 갱신된이후에 업데이트 해줘야함
            resetUndo();
            tickDraw.resetFirstRCursorPos();

            if(traceRawArr === null)
            {
                clearTraceImage();
            }
            else
            {
                const tArr:Array = traceRawArr;
                canvasTraceBitmapData = traceRawBMPD.clone();
                canvasTraceBitmap.bitmapData = canvasTraceBitmapData;
                setTraceImageInfo(tArr[4],
                                  tArr[5],
                                  tArr[6],
                                  tArr[7],
                                  tArr[8],
                                  tArr[9]);
                traceReizeMoveSum = tArr[10];
                CANVAS_TRACE_ALPHA = tArr[11];
                canvasTraceLayer.visible = true;
                canvasTraceLayer.alpha = tArr[11];
                updateTraceOpaButtonPosByAlpha(tArr[11]);
                traceRawBMPD.dispose();
                traceRawBMPD = null;
                traceRawArr = null;
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

            previewBox.updateImage(canvas1BitmapData,canvas11BitmapData,CANVAS_BG_COLOR);

            if(canvasWindowON)
            {
                updateCanvasWindowImage();
                canvasWindowIgnoreResizeEventFlag = true;
                updateCanvasWindowBitmapSize();
            }
        }

        private function loadFile(traceLayer:Boolean=false):void
        {
            if(replayStartON) stopReplay();
            if(lassoToolON || browseWindowON || fillPenStarted || isInSaveProgress)
            {
                return;
            }

            var windowTitle:String = "Open file";
            var imgExt:Array = [new FileFilter("All supported formats","*.2020;*.png;*.jpg;*.gif")];

            if(traceLayer === true)
            {
                windowTitle = "Open reference layer image";
            }

            var loader:Loader = new Loader();
            //초기값으로 파일 경로가 저장된 파일 이름이랑 같으면 그냥 파일인스턴스로 만들어줌
            const file:File = (saveFilePath === saveFileName) ? new File() : new File(saveFilePath);
            var tempFileName:String = "";

            //browser에서 fr.data에서 넘겨준 바이트데이터를 실제적으로 처리함
            function loadFileCompleteEvent(e:Event):void //load1
            {
                browseWindowON = false;
                var loaderInfo:LoaderInfo = LoaderInfo(e.target);

                //2020이 아닌 보통 이미지 처리
                if(traceLayer === true) pasteTraceImage(loaderInfo.loader,loaderInfo.width,loaderInfo.height);
                else loadImageFile(file.name,file.nativePath,loaderInfo.width,loaderInfo.height,loaderInfo.loader,null);

                loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR,loadErrorEvent);
                loader.contentLoaderInfo.removeEventListener(Event.COMPLETE,loadFileCompleteEvent);
                loader.unload();
                loader = null;
            }

            function loadErrorEvent(e:Event):void
            {
                topBar.hintLoadError();
                browseWindowON = false;
                //에러나면 아무것도 안해줌
                loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR,loadErrorEvent);
                loader.contentLoaderInfo.removeEventListener(Event.COMPLETE,loadFileCompleteEvent);
                loader.unload();
                loader = null;
            }

            function onCancelEvent(e:Event):void
            {
                browseWindowON = false;
                file.removeEventListener(Event.SELECT,fileSelectHandler);
                file.removeEventListener(Event.COMPLETE,fileSelectCompleteHandler);
                file.removeEventListener(Event.CANCEL,onCancelEvent);
            }

            function fileSelectHandler(e:Event):void
            {
                browseWindowON = false;
                tempFileName = file.name;

                file.removeEventListener(Event.SELECT,fileSelectHandler);
                file.load();
            }

            function fileSelectCompleteHandler(e:Event):void
            {
                browseWindowON = false;
                //2020파일 처리
                if(is2020Ext(file.name) === true)
                {
                    if(traceLayer === true) loadRawFileToReferenceLayer(file);
                    else loadReplayFile(file,file.name,file.nativePath);
                }
                else //일반 이미지 처리
                {
                    loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,loadErrorEvent);
                    loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loadFileCompleteEvent);
                    loader.loadBytes(file.data);
                }

                file.removeEventListener(Event.SELECT,fileSelectHandler);
                file.removeEventListener(Event.COMPLETE,fileSelectCompleteHandler);
                file.removeEventListener(Event.CANCEL,onCancelEvent);
            }

            browseWindowON = true;

            file.browseForOpen(windowTitle,imgExt);
            file.addEventListener(Event.SELECT,fileSelectHandler);
			file.addEventListener(Event.COMPLETE,fileSelectCompleteHandler);
            file.addEventListener(Event.CANCEL,onCancelEvent);
        }

        private function setCaptureUI(flag:Boolean):void
        {
            //함수 변수가 true가 직관적이라서 없애주는 변수는 반대로해줌
            const iFlag:Boolean = !flag;
            const tb:Sprite = topBar;
            const replayMode:Boolean = replayModeON;

            drawCaptureArea.reset();
            setResizeButtonVisible(false);

            if(replayMode)
            {
                resetCutFrameClickCounter();
                topBar.hintOFF();
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
                topBar.resetHintColor();
                penCursorOFFFlag = true;
                penSizeCursor.visible = false;
                canvasTraceLayer.visible = false;
                if(traceMenuON === true) traceMenu.visible = false;

                changeTopBarIcons("capture");

                setDefaultHintCaptureMode();
                setRCursorVisibleOFFUndo();
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
                changePickerModeToNormal();
            }

            updateStageOffset();
        }

        private function setDefaultHintCaptureMode():void
        {
            topBar.hint("Drag canvas to draw capture area (Click canvas to save full image)",topBar.capOff);
        }

        private function mouseOverCaptureMode(e:MouseEvent):void
        {
            if(topBar.hitTestPoint(mouseX,mouseY) === false && drawCaptureArea.isFullImageCapture())
            {
                setDefaultHintCaptureMode();
            }
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
            if(!target) return;

            const targetName:String = target.name;

            if(targetName === "capLayer1VisibleButton" || targetName === "capLayer2VisibleButton")
            {
                checkButtonUp(targetName);

                return;
            }

            if(target.alpha < 1.0 && topBar.hitTestPoint(mouseX,mouseY))
            {
                return;
            }

            switch(targetName)
            {
                case "capRotate":
                case "capFlip":
                case "capFull":
                case "capOff":
                case "capTrans":
                case "capClipBoard":
                    checkButtonUp(targetName);
                break;

                case "timer":
                {
                    realWorkingTimer.reset();
                }
                return;

                default:
                {
                    if(clickBlockFlag) return;
                    drawCaptureArea.start(replayModeON);
                }
                return;
            }
        }

        private function keyUpCaptureMode(e:KeyboardEvent):void
        {
            checkKeyUp(e.keyCode);
        }

        private function keyDownCaptureMode(e:KeyboardEvent):void
        {
            const keyCode:uint = keyBuffer[0];

            if(mouseClickON || rightMouseClickON || isNowKey(keyCode)) return;

            if(isPressingControl())
            {
                if(keyBuffer.length > 1)
                {
                    const subKey:int = keyBuffer[1];
                    if(subKey === KEY.c || subKey === KEY.m)
                    {
                        setFullCaptrueButton();
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
                    setCaptureOFFButton(true);
                break;

                case KEY.v:
                case KEY.n:
                    if(topBar.capClipBoard.alpha === 1.0)
                    {
                        copyCaptureImageToCilpBoard();
                    }
                break;

                case KEY.c:
                case KEY.m:
                    if(topBar.capFull.alpha === 1.0)
                    {
                        setFullCaptrueButton();
                    }
                break;

                case KEY.s:
                case KEY.k:
                    if(topBar.capRotate.alpha === 1.0)
                    {
                        setCaptureRotateButton();
                    }
                break;

                case KEY.a:
                case KEY.l:
                    if(topBar.capFlip.alpha === 1.0)
                    {
                        setCaptrueFlipButton();
                    }
                break;

                case KEY.d:
                case KEY.j:
                    setCaptureTransButton();
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
            if(!captureModeON) stageMouseMoveEvent.remove("captureMouseMoveHintEvent");
        }

        private function setCaptureModeON():void
        {
            if(makeJumpImageFlag === 2) return;
            // if(captureModeON || isInSaveProgress) return;
            // if(replayStartON)stopReplay();
            if(captureModeON) return;

            if(replayStartON)
            {
                stopReplay();
            }

            captureModeON = true;
            penCursorOFFFlag = true;
            stageMouseMoveEvent.add("captureMouseMoveHintEvent",captureMouseMoveHintEvent);

            setCaptureUI(true);
            captureRotated = 0;
            captureFlipped = false;
            // captureTransBGON = false;

            const floor:Function = Math.floor;
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
                                    "x" : floor(regPoint.x), //뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
                                    "y" : floor(regPoint.y),
                                    "r" : regPoint.rotation,
                                    "px" : floor(canvasPanel.x),
                                    "py" : floor(canvasPanel.y)
            }

            canvasBackupData = {
                                    "z" : xZoomed,
                                    "x" : floor(xReg.x), //뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
                                    "y" : floor(xReg.y),
                                    "r" : xReg.rotation,
                                    "px" : floor(xPanel.x),
                                    "py" : floor(xPanel.y),
                                    "layer1" : layer1,
                                    "layer2" : layer2
                                }

            fitCanvasToWindow(true);
            captureTransBGON = true;
            setCaptureTransButton();
            resetTransBG(false);
        }

        private function setCaptureModeOFF(replayMode:Boolean,xReg:Sprite,xPanel:Sprite):void
        {
            const data:Object = canvasBackupData;
            const xBitmap1:Bitmap = (replayMode) ? rcanvas1Bitmap : canvas1Bitmap;
            const xBitmap11:Bitmap = (replayMode) ? rcanvas1Bitmap : canvas1Bitmap;

            xBitmap1.smoothing = false;
            xBitmap11.smoothing = false;

            captureModeON = false;
            penCursorOFFFlag = false;
            captureAreaRect.visible = false;
            captureAreaRect.graphics.clear();

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
            toolTipBox.visible = false;
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

        //마우스 클릭하면 캡쳐 영역그리는 함수
        private function cDrawCaptureArea():Object
        {
            const floor:Function = Math.floor;
            const abs:Function = Math.abs;
            const replayMode:Boolean = replayModeON;
            const scZoomed:Number = captureZoomed;

            var mouseMoved:Boolean;
            var xCaptureRect:Shape;
            var xReg:Sprite;
            var xPanel:Sprite;
            var canvasWidth:Number;
            var canvasHeight:Number;
            var cx:Number;
            var cy:Number;
            var rectX:Number;
            var rectY:Number;
            var rectW:Number;
            var rectH:Number;
            var drawedcx:Number; //한번 영역을 그려줬으면 원점을 여기다가 저장
            var drawedcy:Number; //다음번에 클릭해서 저장하면 이 원점으로 그려줌
            var finalRect:Array = [0,0,0,0];

            function updateCaptureAreaLineSize():void
            {
                if(rectW > 10 && rectH > 10) drawArea(drawedcx,drawedcy,rectW,rectH);
            }

            function drawArea(x:Number,y:Number,w:Number,h:Number):void
            {
                const g:Graphics = captureAreaRect.graphics;
                const zoomed:Number = (replayModeON) ? Math.abs(rregPoint.scaleX) : Math.abs(regPoint.scaleX);
                var lineSize:Number = Math.ceil(2/zoomed);

                g.clear();
                g.lineStyle(lineSize,0x0099FF,1.0,true);
                g.drawRect(x,y,w,h);
            }

            function captureMouseMove(e:MouseEvent):void
            {
                if(!captureModeON)
                {
                    stageMouseMoveEvent.remove("captureMouseMove");
                    stage.removeEventListener(MouseEvent.MOUSE_UP,captureMouseUp);
                }

                var ww:Number = xPanel.mouseX-cx;
                var hh:Number = xPanel.mouseY-cy;

                if(ww < -cx) ww = -cx;
                else if(ww > canvasWidth-cx) ww = canvasWidth-cx;

                if(hh < -cy) hh = -cy;
                else if(hh > canvasHeight-cy) hh = canvasHeight-cy;

                ww = floor(ww+0.5);
                hh = floor(hh+0.5);

                if(abs(ww) > 10 && abs(hh) > 10)
                {
                    rectW = ww;
                    rectH = hh;
                    drawArea(cx,cy,ww,hh);
                    topBar.hint(getRotatedRectSizeString(),topBar.capOff);
                    mouseMoved = true;
                }
            }

            function getRotatedRectSizeString():String
            {
                const w:Number = abs(rectW);
                const h:Number = abs(rectH);

                if(!rectW || !rectH || (w < 10 && h < 10))
                {
                    return "";
                }
                else
                {
                    return (captureRotated === 0 || captureRotated === 2) ? w+" x "+h
                                                                          : h+" x "+w;
                }
            }

            function resetCaptureArea():void
            {
                rectX = 0;
                rectY = 0;
                rectW = 0;
                rectH = 0;
                captureAreaRect.graphics.clear();
                topBar.capClipBoard.alpha = 1.0;
                setDefaultHintCaptureMode();
            }

            function reset():void
            {
                cx = 0;
                cy = 0;
                rectX = 0;
                rectY = 0;
                rectW = 0;
                rectH = 0;
                canvasWidth = 0;
                canvasHeight = 0;
                xCaptureRect = null;
                xReg = null;
                xPanel = null;
                mouseMoved = false;
                topBar.capClipBoard.alpha = 1.0;
            }

            function captureMouseUp(e:MouseEvent):void
            {
                stageMouseMoveEvent.remove("captureMouseMove");
                stage.removeEventListener(MouseEvent.MOUSE_UP,captureMouseUp);

                if(mouseMoved === true)
                {
                    //rect길이가 음수인경우 cx cy를 양수로 다시 맞추어줌
                    if(rectW < 0)
                    {
                        rectW = (-rectW);
                        cx = cx-rectW;
                    }

                    if(rectH < 0)
                    {
                        rectH = (-rectH);
                        cy = cy-rectH;
                    }

                    rectX = cx;
                    rectY = cy;
                    drawedcx = cx;
                    drawedcy = cy;

                    finalRect[0] = rectX;
                    finalRect[1] = rectY;
                    finalRect[2] = rectW;
                    finalRect[3] = rectH;

                    topBar.hint(getRotatedRectSizeString()+STRING_CAPTURE_OK,topBar.capOff);
                    topBar.capClipBoard.alpha = 1.0;
                }
                else
                {
                    saveCaptureImage();
                }
                mouseMoved = false;
            }

            function isFullImageCapture():Boolean
            {
                return rectW === 0 || rectH === 0;
            }

            function getCaptureArea():Array
            {
                return finalRect;
            }

            function start(replayMode:Boolean):void
            {
                if(replayMode) //리플레이 변수로 변경
                {
                    canvasWidth = RCANVAS_WIDTH;
                    canvasHeight = RCANVAS_HEIGHT;
                    xReg = rregPoint;
                    xPanel = rcanvasPanel;
                }
                else
                {
                    canvasWidth = CANVAS_WIDTH;
                    canvasHeight = CANVAS_HEIGHT;
                    xReg = regPoint;
                    xPanel = canvasPanel;
                }

                cx = xPanel.mouseX;
                cy = xPanel.mouseY;

                if(cx < 0) cx = 0;
                else if(cx > canvasWidth) cx = canvasWidth;

                if(cy < 0 ) cy = 0;
                else if(cy > canvasHeight) cy = canvasHeight;

                cx = floor(cx);
                cy = floor(cy);
                if(topBar.hitTestPoint(mouseX,mouseY) === false)
                {
                    stageMouseMoveEvent.add("captureMouseMove",captureMouseMove);
                    stage.addEventListener(MouseEvent.MOUSE_UP,captureMouseUp);
                }
            };

            return {
                start:start,
                reset:reset,
                resetCaptureArea:resetCaptureArea,
                getCaptureArea:getCaptureArea,
                isFullImageCapture:isFullImageCapture,
                getRotatedRectSizeString:getRotatedRectSizeString,
                updateCaptureAreaLineSize:updateCaptureAreaLineSize
            };
        }

        private function getRandomString():String
        {
            var count:int = 6;
            const chars:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            const charsLen:uint = chars.length;
            var randomString:String = "";
            var index:int;

            while(count > 0)
            {
                index = Math.floor(charsLen*Math.random());
                randomString += chars.charAt(index);
                count--;
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
                            saveFilePath = filePath.substr(0,filePath.lastIndexOf(fileName))+saveFileName;

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
            if(browseWindowON) return;

            const replayMode:Boolean = replayModeON;
            var name:String = saveFileName;
            var path:String = saveFilePath;
            const firstSaveFlag:Boolean = (name !== path);

            browseWindowON = true;

            name = cutTimeStamp(name);
            name = name.substr(0,name.lastIndexOf(".png"))+"_"+getTimeStampTail()+".png";//뒤에 프레임 번호 붙여줌
            path = path.substr(0,path.lastIndexOf(saveFileName))+name;

            var file1:File = (firstSaveFlag) ? new File(path): File.desktopDirectory.resolvePath(name);

            const fs:FileStream = new FileStream();
            const saveWindowTitle:String = "Save image";

            file1.addEventListener(IOErrorEvent.IO_ERROR, onCancelEvent);
            file1.addEventListener(Event.CANCEL, onCancelEvent);
            file1.addEventListener(Event.SELECT, onSelectEvent);
            file1.browseForSave(saveWindowTitle);

            resetKeyBuffer();

            function onCancelEvent(e:Event):void
            {
                browseWindowON = false;
                file1.cancel();
                file1.removeEventListener(IOErrorEvent.IO_ERROR, onCancelEvent);
                file1.removeEventListener(Event.CANCEL, onCancelEvent);
                file1.removeEventListener(Event.SELECT, onSelectEvent);
            }

            function onSelectEvent(e:Event):void
            {
                browseWindowON = false;
                file1.cancel();
                file1.removeEventListener(IOErrorEvent.IO_ERROR,onCancelEvent);
                file1.removeEventListener(Event.CANCEL,onCancelEvent);
                file1.removeEventListener(Event.SELECT,onSelectEvent);

                if(workerPNGCaptureData === null) workerPNGCaptureData = new Vector.<ByteArray>()
                if(workerPNGCaptureFileData === null) workerPNGCaptureFileData = [];

                callWorkerEncodePNG(getProcessedCaptureImage(false),0,true,captureTransBGON);
                saveCapturePNGByOrder(file1.name,e.target.nativePath);
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
                filePath = _path.substr(0,_path.lastIndexOf(".png"))+"_new.png";
                fileName = _name.substr(0,_name.lastIndexOf(".png"))+"_new.png";
            }

            return (_name !== _path) ? new File(filePath) : File.desktopDirectory.resolvePath(fileName);
        }

        private function checkNotPNGExtension(name:String,path:String):Array
        {
            const extArr:Array = [".2020",".jpg",".gif"];
            var fixedPath:String;
            var dotPNG:String;

            for(var i:int=0; i<3; i++)
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

        private function saveFile(asFlag:Boolean,saveFailed:Boolean=false):void
        {
            //계속 저장하는거 방지 다른 이름으로 저장은 예외
            if(replayStartON) stopReplay();
            const continueFlag:Boolean = saveContinue === true && asFlag === false;

            if(saveOneTime && continueFlag)
            {
                if(updateAfterSave)
                {
                    startUpdate();
                }
                else
                {
                    topBar.hintTime("Already saved",topBar.replayModeButton);
                }
                return;
            }

            if(lassoToolON || fillPenStarted || isInSaveProgress)
            {
                return;
            }

            const fs:FileStream = new FileStream();
            const mergedImage:BitmapData = mergeCanvas(false,false,true,true);

            topBar.hintOFF();

            if(continueFlag)
            {
                const normalFile:File = new File(saveFilePath);

                if(normalFile.exists === true)
                {
                    function saveContinueErrorEvent(e:Event):void
                    {
                        topBar.hintTimeOFFWithColor();
                        fs.close();
                        fs.removeEventListener(IOErrorEvent.IO_ERROR,saveContinueErrorEvent);
                        saveOneTime = false;
                        saveFile(true,true);
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
                            fs.openAsync(normalFile,FileMode.WRITE);
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
                if(browseWindowON) return;

                const file:File = checkSaveFailedFileName(saveFailed);
                const saveWindowTitle:String = (asFlag === true) ? "Save file As.."
                                                :(updateAfterSave) ? "Save file before update":"Save file";

                file.addEventListener(IOErrorEvent.IO_ERROR, onErrorEvent);
                file.addEventListener(Event.CANCEL, onErrorEvent);
                file.addEventListener(Event.SELECT, onSelectEvent);
                file.browseForSave(saveWindowTitle);

                resetKeyBuffer(); //ctrl + 조합키로 브라우저 창열었을때 ctrl키가 계속 눌려있어서 키가 안먹음 그래서 리셋해줌
                browseWindowON = true;

                function removeEvent():void
                {
                    file.removeEventListener(IOErrorEvent.IO_ERROR, onErrorEvent);
                    file.removeEventListener(Event.CANCEL, onErrorEvent);
                    file.removeEventListener(Event.SELECT, onSelectEvent);
                }

                function onErrorEvent(e:Event):void
                {
                    browseWindowON = false;
                    file.cancel();
                    removeEvent();
                    if(updateAfterSave)
                    {
                        startUpdate();
                    }
                }

                function onSelectEvent(e:Event):void
                {
                    browseWindowON = false;

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
            const arr:Array = fs.readObject() as Array; //undodata first
            arr[0].uncompress();
            arr[1].uncompress();
            const newRectangle:Rectangle = new Rectangle(0,0,arr[2],arr[3]);
            var bmpd:BitmapData = new BitmapData(arr[2],arr[3],true,0);
            var bmpd1:BitmapData = new BitmapData(arr[2],arr[3],true,0);
            var arr1:Array = fs.readObject() as Array;
            var arr2:Array = fs.readObject() as Array;

            rData = arr1.concat();
            rDataFrame = arr2.concat();
            arr1 = [];
            arr2 = [];
            fs.close();

            undoIndex = lastUndoIndex;
            bmpd.lock();
            bmpd.setPixels(newRectangle,arr[0]);
            bmpd.unlock();
            bmpd1.lock();
            bmpd1.setPixels(newRectangle,arr[1]);
            bmpd1.unlock();
            undoData.setUndoRefImage(bmpd.clone(),bmpd1.clone(),arr[2],arr[3],arr[4],arr[5]);

            drawUndoData();
            setRCursorVisibleOFFUndo();
            toolTipBoxTimerOFF();
            bmpd.dispose();
            bmpd1.dispose();
            bmpd = null;
            bmpd1 = null;

            //undo index가 arr의 가장 마지막 부분이 아니면 undo를 하던 중이니까 undoDelFlag 켜줌
            if(lastUndoIndex < rData.length-1) undoDelFlag = true;
            else undoDelFlag = false;
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
            ba.compress();
            ba1.compress();
            //레이어 1,레이어2,가로,세로,배경색
            var newArr:Array = [ba,ba1,arr[2],arr[3],arr[4],arr[5]];

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
                            "penSmoothButtonX":controlBox.penSmoothSliderSet["penSmoothButton"].x,
                            "penSize":penSize,
                            "penSizeIndex":penSizeIndex,
                            "penColor":penColor,
                            "changedColor":changedColor,
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
                            "colorHistoryList":colorHistoryList,
                            "CANVAS_BG_COLOR":CANVAS_BG_COLOR,
                            "toolBoxLastClickPos.x":toolBoxLastClickPos.x,
                            "toolBoxLastClickPos.y":toolBoxLastClickPos.y,
                            "rFileTotalFrame":undoData.getRFileTotalFrame(),
                            "toolBox.scaleX":toolBox.scaleX,
                            "lastWindowState":lastWindowState,
                            "uiColorIndex":uiColorIndex,
                            "APP_RUNNING_TIME":realWorkingTimer.getRunningTime(),
                            "CANVAS_TRACE_ALPHA":CANVAS_TRACE_ALPHA,
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
                            "gridFlag":gridFlag,
                            "hueCursor.x":pickerBox["hueCursor"].x,
                            "svBaseColor":pickerBox["svBaseColor"],
                            "HUECOLOR[0]":HUECOLOR[0],
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
                            "getFirstRCursorPos.y":tickDraw.getFirstRCursorPos().y
                            });
            fs.close();
        }

        private function loadAppData():void
        {
            const _nativeWindow:NativeWindow = stage.nativeWindow;
            const fs:FileStream = new FileStream();
            var arr:Array = [];
            var newRectangle:Rectangle;
            //앱 경로에 마지막 저장 파일이 있으면 끄기전의 상태로 세팅해줌

            if(rFirstImageFile.exists)
            {
                fs.open(rFirstImageFile, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();

                if(arr[1] as ByteArray === null)
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
                arr[0].uncompress();
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

            if(appDataFile.exists)
            {
                fs.open(appDataFile, FileMode.READ);
                const d:Object = fs.readObject();
                fs.close();

                //loadUndoData함수에서 canvaspanel이 호출되는데 이전에 trace이미지 정보값을 넣어두어야함
                if(undoDataFile.exists) loadUndoData();//undo data 복구 먼저 해줌

                //그냥 해주면 창크기 적용이 안되서 타이머 걸어줌
                addTimerByName("loadAppDataDelayTimer",0.15,false,function():void
                {
                    _nativeWindow.width = d["stage.nativeWindow.width"];
                    _nativeWindow.height = d["stage.nativeWindow.height"];
                    _nativeWindow.x = d["stage.nativeWindow.x"];
                    _nativeWindow.y = d["stage.nativeWindow.y"];
                    lastWindowSize.x = d["stage.nativeWindow.width"];
                    lastWindowSize.y = d["stage.nativeWindow.height"];

                    //캔버스 위치까지 전부 다해준 다음에 이전 상태가 풀스크린이었으면 세팅해줌
                    if(d["lastWindowState"] === 1) stage.nativeWindow.maximize();
                    zoomedIndex = d["zoomedIndex"];
                    setZoomCanvas(d["zoomed"]);
                    canvasPanel.x = d["canvasPanel.x"];
                    canvasPanel.y = d["canvasPanel.y"];
                    regPoint.x = d["regPoint.x"];
                    regPoint.y = d["regPoint.y"];
                    regPoint.rotation = d["regPoint.rotation"];
                    updateResizeButtonPos(CANVAS_WIDTH,CANVAS_HEIGHT);
                    rotateCursorBox["rotateArrow"].rotation = d["regPoint.rotation"];
                    uiColorIndex = d["uiColorIndex"];
                    setUIColor(d["uiColorIndex"]);
                    penSmoothValue = d["penSmoothValue"];
                    penSmoothSlideValue = d["penSmoothSlideValue"];
                    controlBox.penSmoothSliderSet["penSmoothButton"].x = d["penSmoothButtonX"];
                    penSize = d["penSize"];
                    penColor = d["penColor"];
                    updateOpaBoxColor(d["penColor"]);
                    initPickerBoxInfo(d["penColor"]);
                    setHSVCursorPosByColor(d["penColor"]);
                    pickerBox.changeHueColor(d["svBaseColor"]);
                    HUECOLOR[0] = d["HUECOLOR[0]"];
                    pickerBox["hueCursor"].x = d["hueCursor.x"];
                    changedColor = d["changedColor"]
                    penAlpha = d["penAlpha"];
                    penAlphaIndex = alphaArr.indexOf(d["eraseAlpha"]);
                    setPenAlpha(d["penAlpha"]);
                    penShape = d["penShape"];
                    penListShapeFlag =  d["penShape"];
                    controlBox.shapeFlag(d["penShape"]);
                    eraseSize = d["eraseSize"];
                    eraseShape = d["eraseShape"];
                    eraseAlpha = d["eraseAlpha"];
                    eraseAlphaIndex = alphaArr.indexOf(d["eraseAlpha"]);
                    eraseSizeIndex = d["eraseSizeIndex"];
                    setPenSize(d["penSizeIndex"]);
                    toolBoxLastClickPos.x = d["toolBoxLastClickPos.x"];
                    toolBoxLastClickPos.y = d["toolBoxLastClickPos.y"];
                    undoData.setRFileTotalFrame(d["rFileTotalFrame"]);
                    saveFileName = d["saveFileName"];
                    saveFilePath = d["saveFileName"];
                    colorHistoryList = d["colorHistoryList"].concat();
                    d["colorHistoryList"] = [];
                    realWorkingTimer.setRunningTime(d["APP_RUNNING_TIME"]);
                    realWorkingTimer.update();
                    CANVAS_TRACE_ALPHA = d["CANVAS_TRACE_ALPHA"]
                    canvasTraceLayer.alpha = d["CANVAS_TRACE_ALPHA"];
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
                    saveFilePath = d["saveFilePath"];
                    tickDraw.setFirstRCursorPos(d["getFirstRCursorPos.x"],d["getFirstRCursorPos.y"]);

                    setTraceImageInfo(d["tracePosInfo[0]"],
                                      d["tracePosInfo[1]"],
                                      d["tracePosInfo[2]"],
                                      d["tracePosInfo[3]"],
                                      d["tracePosInfo[4]"],
                                      d["tracePosInfo[5]"]);

                    if(mirrorON !== d["mirrorON"]) mirrorCanvas(true);

                    gridFlag = d["gridFlag"];
                    drawGrid();
                    setUIScaleButton(d["uiScaleIndex"]);
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

                    rIndex = undoIndex;
                    rNowFrame = getTotalFrameUntilUndoIndex(undoIndex);
                    rPrevFrame = getTotalFrameUntilUndoIndex(undoIndex-1);

                    //혹시 몰라서 위치 체크 해줌
                    appInfoBox.setRotate(regPoint.rotation);
                    setCenvasCenterPos(true);
                    checkCanvasPanelPos();
                    checkCanvasPanelPos(true);
                    updateColorHistoryList();
                    updatePreviewBoxRectPos();
                    updatePenSizeCursor();
                    updateWindowTitle();

                    selectSubLayer(false,false);
                });
            }
            else //복원파일이 없을때
            {
                lastWindowSize.x = 680;
                lastWindowSize.y = 768;
                _nativeWindow.width = lastWindowSize.x;
                _nativeWindow.height = lastWindowSize.y;

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
            const lastInfo:Array = penLastUpdateInfo;
            const _penSizeCursor:Shape = penSizeCursor;
            const pg:Graphics = _penSizeCursor.graphics;

            var eraseFlag:Boolean;
            var z:Number;
            var size:uint;
            var shape:Boolean;
            var zSize:Number = size*z;
            var halfSize:Number = size/2;
            var z1:Number = 1/z;
            var z1z1:Number = z1*2;
            var sqStart:Number = (-halfSize+z1)*z;
            var sqWidth:Number = (size-z1z1)*z;
            var sqStart1:Number = -halfSize*z;
            var sqWidth1:Number= size*z;

            return function ():void
            {
                eraseFlag = isEraseTool();
                z = zoomed;

                if(eraseFlag)
                {
                    size = eraseSize;
                    shape = eraseShape;
                }
                else
                {
                    size = penSize;
                    shape = penShape;
                }

                zSize = size*z;
                _penSizeCursor.rotation = regPoint.rotation;

                if(zSize === lastInfo[0] && shape === lastInfo[1])
                {
                    return;
                }

                lastInfo[0] = zSize;
                lastInfo[1] = shape;

                halfSize = size/2;
                z1 = 1/z;
                z1z1 = z1*2;

                if(sharpLineON)
                {
                    if(size % 2 === 1.0) sizeOffsetFlag = true; //홀수 사이즈 일때 켜줌
                    else sizeOffsetFlag = false;
                }
                else
                {
                    if(size === 1.0 || size % 2 !== 0) sizeOffsetFlag = false;
                    else sizeOffsetFlag = true;
                }

                pg.clear();

                if(shape === false)
                {
                    pg.lineStyle(1,0xFFFFFF);
                    pg.drawCircle(0,0,(halfSize-z1)*z);

                    pg.lineStyle(1,0);
                    pg.drawCircle(0,0,halfSize*z);
                    _penSizeCursor.rotation = 0;
                }
                else if(shape === true)
                {
                    sqStart = (-halfSize+z1)*z;
                    sqWidth = (size-z1z1)*z;
                    sqStart1 = -halfSize*z;
                    sqWidth1= size*z;

                    pg.lineStyle(1,0xFFFFFF);
                    pg.drawRect(sqStart,sqStart,sqWidth,sqWidth);

                    pg.lineStyle(1,0);
                    pg.drawRect(sqStart1,sqStart1,sqWidth1,sqWidth1);
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

                if(airBrushSizeDrawMode > 0 && zoomed !== 1.0)
                {
                    setBlurCanvasBySizeNoZoomDrawMode();
                    canvas2BitmapData.draw(canvas2Draw);
                    canvas2Bitmap.bitmapData = canvas2BitmapData;
                    setBlurCanvasBySizeDrawMode(airBrushSizeDrawMode);
                }
                else
                {
                    canvas2BitmapData.draw(canvas2Draw);
                    canvas2Bitmap.bitmapData = canvas2BitmapData;
                }

                if(isPenOrLineTool() || isNowTool(TOOL_FILL_PEN))
                {
                    canvas2Alpha.alphaMultiplier = penAlpha;
                    // canvas2Alpha = new ColorTransform(1,1,1,penAlpha);
                    if(subLayerON) canvas11BitmapData.draw(canvas2Bitmap,null,canvas2Alpha);
                    else canvas1BitmapData.draw(canvas2Bitmap,null,canvas2Alpha);
                }
                else if(isEraseTool())
                {
                    canvas2Alpha.alphaMultiplier = eraseAlpha;
                    // canvas2Alpha = new ColorTransform(1,1,1,eraseAlpha);
                    if(subLayerON) canvas11BitmapData.draw(canvas2Bitmap,null,canvas2Alpha,"erase");
                    else canvas1BitmapData.draw(canvas2Bitmap,null,canvas2Alpha,"erase");
                }

                rDataBuffer.push(["drawDone2",subLayerON]);

                if(subLayerON) canvas11Bitmap.bitmapData = canvas11BitmapData;
                else canvas1Bitmap.bitmapData = canvas1BitmapData;

                canvas2BitmapData.fillRect(new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT),0);
                canvas2Draw.graphics.clear();

                addUndoData();
            }
        }

        private function cLineTool():Function
        {
            const floor:Function = Math.floor;
            const abs:Function = Math.abs;
            const atan2:Function = Math.atan2;
            const toDeg:Number = 180/Math.PI;
            const cd:Shape = canvas2Draw;
            // const oldPoint:Point = new Point(0,0);
            var oldX:Number;
            var oldY:Number;
            var startPoint:Point = new Point();
            var endPoint:Point = new Point();

            var canvasSizeWidth:Number;
            var canvasSizeHeight:Number;
            var _traceMemoryTraining:Boolean;
            var xSize:uint;
            var xColor:uint;
            var xAlpha:Number;
            var xShape:Boolean;
            var xBlendMode:String;
            var xAirBrushON:Boolean;
            var xOffset:Number;
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

            function syncPenCursorLineAngle(mx:Number,my:Number):void
            {
                const rad:Number = Math.atan2(oldX+xOffset-mx,oldY+xOffset-my);
                const cursorDeg:Number = -rad*(180/Math.PI)+regPoint.rotation;
                penSizeCursor.rotation = cursorDeg;
            }

            function setDegreeToolTipON():void
            {
                const ang:Number = atan2(oldX-cd.mouseX,oldY-cd.mouseY);
                var deg:Number = ang*toDeg+90;
                if(deg > 180)
                {
                    deg = deg-90;
                }

                var degstr:String = abs(deg % 90).toFixed(1)+"°";
                setToolTipON(degstr);
                toolTipBox.visible = true;
            }

            function drawingLine():void //지우개인가 펜인가 구분해서 lineto 실시
            {
                const cdg:Graphics = cd.graphics;
                cdg.clear();

                canvas2.alpha = xAlpha;
                if(xShape)
                {
                    cdg.lineStyle(xSize, xColor, 1, false, LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.ROUND);
                }
                else
                {
                    cdg.lineStyle(xSize, xColor);
                }

                cdg.moveTo(startPoint.x,startPoint.y);
                cdg.lineTo(endPoint.x,endPoint.y);
            }

            function lineMoveEvent(e:MouseEvent):void
            {
                if(!mouseMovedFlag)
                {
                    mouseMovedFlag = true;
                }
                const mx:Number = cd.mouseX+xOffset;
                const my:Number = cd.mouseY+xOffset;

                if(xShape === true)
                {
                    const extPoints:Array = extendLineSegment(oldX+xOffset,oldY+xOffset,mx,my,xSize/2);
                    startPoint.setTo(extPoints[0],extPoints[1]);
                    endPoint.setTo(extPoints[2],extPoints[3])
                }
                else
                {
                    startPoint.setTo(oldX+xOffset,oldY+xOffset);
                    endPoint.setTo(mx,my)
                }

                drawingLine();
                setDegreeToolTipON();
                if(xShape === true)
                {
                    syncPenCursorLineAngle(mx,my);
                }
            }

            function lineUpEvent(e:MouseEvent):void
            {
                stageMouseMoveEvent.remove("lineMoveEvent");
                stage.removeEventListener(MouseEvent.MOUSE_UP, lineUpEvent);

                if(_traceMemoryTraining)
                {
                    canvasTraceLayer.visible = true;
                }

                mouseDragON = false;
                toolTipBox.visible = false;

                if(checkLineToolUndoReady() === true)
                {
                    const mx:Number = cd.mouseX;
                    const my:Number = cd.mouseY;
                    const cx:Number = oldX;
                    const cy:Number = oldY;

                    readyAddUndoFlag = true;

                    if(mouseMovedFlag === false && cx === mx && my === y)
                    {
                        const xx:Number = mx+xOffset;
                        const yy:Number = my+xOffset;
                        rDataBuffer.push(["dot",xShape,xSize,xColor,xAlpha,xx,yy,xBlendMode,subLayerFlag,xAirBrushON]);
                        drawDot(xShape,xSize,xColor,xx,yy);
                    }
                    else
                    {
                        if(xShape === true)
                        {
                            const extPoints:Array = extendLineSegment(cx+xOffset,cy+xOffset,mx,my,xSize/2);
                            startPoint.setTo(extPoints[0],extPoints[1]);
                            endPoint.setTo(extPoints[2],extPoints[3])
                        }
                        else
                        {
                            startPoint.setTo(cx+xOffset,cy+xOffset);
                            endPoint.setTo(mx,my)
                        }

                        rDataBuffer.push(["line1",xShape,xSize,xColor,xAlpha,startPoint.x,startPoint.y,endPoint.x,endPoint.y,xBlendMode,subLayerFlag,xAirBrushON]);
                        drawingLine();
                    }
                }

                if(xShape === true)
                {
                    penSizeCursor.rotation = regPoint.rotation;
                }

                drawDone();
            }

            return function (lineToolFlag:Boolean):void
            {
                _traceMemoryTraining = traceMemoryTraining;

                xSize = penSize;
                xColor = penColor;
                xAlpha = penAlpha;
                xShape = penShape;
                xBlendMode = null;
                xAirBrushON = airBrushON;
                canvasSizeWidth = CANVAS_WIDTH;
                canvasSizeHeight = CANVAS_HEIGHT;

                xOffset = (sizeOffsetFlag) ? 0.5 : 0;

                mouseMovedFlag = false;
                oldX = cd.mouseX;
                oldY = cd.mouseY;
                subLayerFlag = subLayerON

                if(_traceMemoryTraining)
                {
                    canvasTraceLayer.visible = false;
                }

                //캔버스2번 지워주고, draw판넬 데이터도 지워줌
                canvas2BitmapData.dispose();
                canvas2Bitmap.bitmapData = null;
                canvas2BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);

                //선 관련 이벤트 함수 붙여줌
                stageMouseMoveEvent.add("lineMoveEvent",lineMoveEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,lineUpEvent);
            };
        }

        private function resetRotationReplayMode():void
        {
            const center:Point = getStageCenterPos(CENTERPOS_REPLAY);
            setRegPoint(center.x,center.y,true);
            rregPoint.rotation = 0;
        }

        private function resetRotationDrawMode():void
        {
            const center:Point = getStageCenterPos(CENTERPOS_DRAW);

            updatePenSizeCursor();
            setRegPoint(center.x,center.y,false);
            regPoint.rotation = 0;
            appInfoBox.setRotate(0);
            updatePreviewBoxRectPos();
        }

        private function cRotateTool():Function
        {
            const _rotateCursorBox:rotateCursor = rotateCursorBox;
            const floor:Function = Math.floor;
            const angleCursor:SimpleButton = _rotateCursorBox["rotateArrow"];
            const PI:Number = Math.PI;
            const toDeg:Number = 180/PI; //rad를 deg로 변환하는 수식

            var _replayMode:Boolean;
            var xReg:Sprite;
            var xBitmap:Bitmap;
            //각도 차이 구하기 위해서 넣어줌, 초기 값은 마우스 클릭한 위치의 각도값
            var lastAng:Number;
            //움직인 각도합 로테이트 캔버스 마지막각도를 넣어줌 rad로 변환
            var sumAng:Number;
            var center:Point;

            function rotateToolUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, rotateToolUpEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, rotateToolUpEvent);
                stageMouseMoveEvent.remove("rotateToolMoveEvent");

                mouseDragON = false;
                penCursorOFFFlag = false;

                if(!_replayMode)
                {
                    if(lassoToolON)
                    {
                        if(lassoMenuTempOFF === true)
                        {
                            setlassoMenuTempOFF();
                        }
                    }

                    updatePenSizeCursor();
                    setOptimizeCanvasMove(false);
                    updatePreviewBoxRectPos();
                }
                else
                {
                    if(rFitZoomedON) fitCanvasToWindowManualReplayMode();

                    resetNowKey();
                    autoScroll.updateRCanvasBounds();
                }

                _rotateCursorBox.visible = false;
                checkCanvasPanelPos(_replayMode);
            }

            function rotateToolMoveEvent(e:MouseEvent):void
            {
                const nowAng:Number = Math.atan2(mouseX-_rotateCursorBox.x,mouseY-_rotateCursorBox.y);
                const subAng:Number = lastAng-nowAng;

                if(subAng === 0) return;

                lastAng = nowAng;
                sumAng += subAng;

                var deg:Number = sumAng*toDeg;
                const snap90:Number = Math.abs(deg%90);//90도 스냅 변수
                const snap90N:Number = 90-snap90;
                const snapAng:Number = (snap90 > snap90N) ? snap90 : snap90N;

                //90도에 가까우면 90도 스냅이 걸리게함
                if(snapAng > 85)
                {
                    deg = floor(deg/90+0.5)*90;
                }

                deg = Math.floor(deg);

                angleCursor.rotation = deg;
                xReg.rotation = deg;
                appInfoBox.setRotate(Math.abs(xReg.rotation));
            }

            return function (replayMode:Boolean=false):void
            {
                _replayMode = replayMode;

                if(replayMode)
                {
                    xReg = rregPoint;
                    xBitmap = rcanvas1Bitmap;
                }
                else
                {
                    xReg = regPoint;
                    xBitmap = canvas1Bitmap;
                }

                //각도 차이 구하기 위해서 넣어줌, 초기 값은 마우스 클릭한 위치의 각도값
                lastAng = 0;
                //움직인 각도합 로테이트 캔버스 마지막각도를 넣어줌 rad로 변환
                sumAng = xReg.rotation*PI/180;
                center = getStageCenterPos(CENTERPOS_REPLAY);
                penCursorOFFFlag = true;

                if(!replayMode)
                {
                    setOptimizeCanvasMove(true);
                }

                setRegPoint(center.x,center.y,replayMode);

                setTopChildIndex(_rotateCursorBox);
                _rotateCursorBox.visible = true;
                _rotateCursorBox.x = mouseX;
                _rotateCursorBox.y = mouseY+65;
                angleCursor.rotation = xReg.rotation;

                //regpoint와 각도 가이드가 전부이동한 후에 lastAng을 갱신해줌
                lastAng = Math.atan2(mouseX-_rotateCursorBox.x,mouseY-_rotateCursorBox.y);

                stageMouseMoveEvent.add("rotateToolMoveEvent",rotateToolMoveEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,rotateToolUpEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,rotateToolUpEvent);
            };
        }

        private function cMoveTool():Function
        {
            const old:Point = new Point(0,0);
            var z:Number = zoomed;

            function moveToolOFFEvent(e:MouseEvent):void
            {
                stageMouseMoveEvent.remove("moveToolMoveEvent");
                stage.removeEventListener(MouseEvent.MOUSE_UP, moveToolOFFEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, moveToolOFFEvent);

                mouseDragON = false;
                penCursorOFFFlag = false;
                var tempBitData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);

                const floor:Function = Math.floor;
                const movex:Number = floor(canvas1Bitmap.x);
                const movey:Number = floor(canvas1Bitmap.y);
                const movex1:Number = floor(canvas11Bitmap.x);
                const movey1:Number = floor(canvas11Bitmap.y);
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

                    if(hasLastRDataCommand(command)) addUndoDataContinue();
                    else addUndoData();
                }
            }

            function moveToolMoveEvent(e:MouseEvent):void
            {
                const dx:Number = mouseX-old.x;
                const dy:Number = mouseY-old.y;
                const rPos:Point = rotatePoint(dx,dy,regPoint.rotation);
                const mx:Number = rPos.x/z;
                const my:Number = rPos.y/z;

                if(checkedLayer === 0)
                {
                    if(canvas1Bitmap.visible)
                    {
                        canvas1Bitmap.x = mx;
                        canvas1Bitmap.y = my;
                    }

                    if(canvas11Bitmap.visible)
                    {
                        canvas11Bitmap.x = mx;
                        canvas11Bitmap.y = my;
                    }
                }
                else if(checkedLayer === 1)
                {
                    canvas1Bitmap.x = mx;
                    canvas1Bitmap.y = my;
                }
                else if(checkedLayer === 2)
                {
                    canvas11Bitmap.x = mx;
                    canvas11Bitmap.y = my;
                }
            }

            return function ():void
            {
                if(isAllLayerInvisible()) return;

                old.setTo(mouseX,mouseY);
                z = zoomed;
                penCursorOFFFlag = true;

                stageMouseMoveEvent.add("moveToolMoveEvent",moveToolMoveEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,moveToolOFFEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,moveToolOFFEvent);
            };
        }

        private function getNearestZoomValue(z:Number):Number
        {
            z = (z > 1.0) ? Math.round(z) : Math.round(z*10)/10;//반올림 해줌

            const arr:Array = zoomArr;
            const len:uint = arr.length-1;
            var low:Number = 0;
            var high:Number = arr.length-1;
            var index:Number = 0;
            for(var i:int=0; i<len; i++)
            {
                if(z <= arr[i])
                {
                    if(i === 0) index = i;
                    if(i > 0 && arr[i]-z < z-arr[i-1]) index = i;
                    else index = i-1;

                    break;
                }
            }

            zoomedIndex = index;

            const final:Number = arr[index];
            return final;
        }

        private function cZoomTool():Function
        {
            const _zoomArr:Array = zoomArr;
            const _zoomArrLen:uint = _zoomArr.length;
            const zoomMin:Number = _zoomArr[0];
            const zoomMax:Number = _zoomArr[_zoomArrLen-1];
            const mouseMoveStep:int = 37; //이 픽셀이상움직일때만 zoomcanvas를 실행
            const zoomUnit:Number = 1.0;// 0.25;//한 스탭당 얼마나 줌할것인지
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
            var zerop:Point;
            var gp:Point;
            var zoomClickX:Number;
            var zoomClickY:Number;
            //캔버스가 회전해있을경우 음수를 해줘야 정확한 값이 나옴
            var panelLimitedPos:Point;
            //캔버스 0,0점이 글로벌좌표 기준으로 어느 위치에 있는지 더해줘야함
            var panelLimitedX:Number;
            var panelLimitedY:Number;

            function zoomToolMouseUpEvent(clickZoomInFlag:Boolean):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, zoomToolMouseUpEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, zoomToolMouseUpEvent);
                stageMouseMoveEvent.remove("zoomToolMouseMoveEvent");

                zoomToolHintON = false;
                mouseDragON = false;
                penCursorOFFFlag = false;
                toolTipBox.visible = false;

                updatePenSizeCursor();
                setOptimizeCanvasMove(false);

                if(lassoMenuTempOFF === true)
                {
                    setlassoMenuTempOFF();
                }

                updatePreviewBoxRectPos();
                updateRCursorScale(zoomed);
            }

            function zoomGoArray(index:uint):void
            {
                const newZoom:Number = _zoomArr[index];
                const textZoom:uint = Math.floor(newZoom*100);

                setZoomCanvas(newZoom,false);
                setToolTipON(textZoom+"%",clickPos.x,clickPos.y);
            }

            function zoomToolMouseMoveEvent2(dist:Number):void
            {
                if(dist > mouseMoveStep)zoomedIndex--;
                else zoomedIndex++;

                if(zoomedIndex < 0) zoomedIndex = 0;
                else if(zoomedIndex > _zoomArrLen-1) zoomedIndex = _zoomArrLen-1;

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
                    }
                    else if(abs(my-oldY) > 20)
                    {
                        moveFlag = 2;
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
                oldZoom;
                penCursorOFFFlag = true;
                zoomToolHintON = true;
                setOptimizeCanvasMove(true);
                oldZoom = zoomed;

                //클릭한 위치가 캔버스밖을 벗어날경우 줌 기준점을 캔버스 경계선에 닿도록 함
                xCanvas = canvasPanel;
                xRotation= -regPoint.rotation;
                maxWidth = CANVAS_WIDTH*xZoomed;//줌 배율을 곱해줘야 정확한 값이 나옴. width나 canvasPanel.mouseX는 scale된 값이 아님
                maxHeight = CANVAS_HEIGHT*xZoomed;
                zerop = new Point(0,0);
                gp = xCanvas.localToGlobal(zerop);
                zoomClickX = xCanvas.mouseX*xZoomed;
                zoomClickY = xCanvas.mouseY*xZoomed;

                if(zoomClickX < 0)  zoomClickX = 0;
                else if(zoomClickX > maxWidth)  zoomClickX = maxWidth;

                if(zoomClickY < 0) zoomClickY = 0;
                else if(zoomClickY > maxHeight) zoomClickY = maxHeight;

                //캔버스가 회전해있을경우 음수를 해줘야 정확한 값이 나옴
                panelLimitedPos = rotatePoint(zoomClickX,zoomClickY, xRotation);
                //캔버스 0,0점이 글로벌좌표 기준으로 어느 위치에 있는지 더해줘야함
                panelLimitedX = panelLimitedPos.x+gp.x;
                panelLimitedY = panelLimitedPos.y+gp.y;

                //regpoint를 panelLimitedPos계산한 값으로 이동
                if(lassoMenuTempOFF === true)
                {
                    gp = lassoBox.localToGlobal(zerop);
                    setRegPoint(gp.x,gp.y,false);
                }
                else
                {
                    setRegPoint(panelLimitedX,panelLimitedY,false);
                }

                clickPos.setTo(mouseX,mouseY);
                setToolTipON(zoomed*100+"%",clickPos.x,clickPos.y);
                toolTipBox.visible = true;

                stageMouseMoveEvent.add("zoomToolMouseMoveEvent",zoomToolMouseMoveEvent);
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
            const round:Function = Math.round;
            const boundRect:Object = getBoundRect(canvas1Bitmap);
            const left:Number = boundRect.left;
            const top:Number = boundRect.top;
            const right:Number = boundRect.right;
            const bottom:Number = boundRect.bottom;
            const visualWidth:Number = right-left;//회전해있어도 상관없음
            const visualHeight:Number = bottom-top;//양끝 모서리들의 직선거리를 구함
            const visualMidX:Number = round((left+right)/2);//회전한 캔버스의 중심점을 구함
            const visualMidY:Number = round((top+bottom)/2); //floor안하면 1픽셀씩 내려감 0.5를 아래 setRegPoint 함수 에서 반올림 해줘서 그럼
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
            const _canvasTraceLayer:Sprite = canvasTraceLayer;
            const _traceInfo:Array = tracePosInfo;

            canvasTraceLayer.scaleX = -canvasTraceLayer.scaleX;
            canvasTraceLayer.rotation = -canvasTraceLayer.rotation;
            _traceInfo[2] = canvasTraceLayer.rotation;
            _traceInfo[3] = canvasTraceLayer.scaleX;
            _traceInfo[5] = !_traceInfo[5];
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

            if(rCursor.visible) setRCursorMirrorPos();
        }

        private function changeCanvasSizeReplayMode(w:Number,h:Number,moveX:Number=0,moveY:Number=0,movedFlag:Boolean=false):void
        {
            if(w === RCANVAS_WIDTH && h === RCANVAS_HEIGHT)
            {
                return;
            }

            const cpg:Graphics = rcanvasPanel.graphics;
            const maskg:Graphics = rcanvasPanelMask.graphics;
            const bgColor:uint = RCANVAS_BG_COLOR;

            //캔버스가 회전되어있으면 회전된 방향으로 움직여줘야함
            cpg.clear();
            cpg.beginFill(bgColor);
            cpg.drawRect(0,0,w,h);
            cpg.endFill();
            maskg.clear();
            maskg.beginFill(bgColor);//paneldraw마스크 아무색이나 상관없음 어차피 마스크로 쓸거라
            maskg.drawRect(0,0,w,h);
            maskg.endFill();
            rcanvasPanel.mask = rcanvasPanelMask;//마스크 다시 씌워줌
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
            const _canvasTrace:Sprite = canvasTraceLayer;
            const _canvasTraceBitmap:Bitmap = canvasTraceBitmap;
            const scX:Number = tracePosInfo[3];
            const scY:Number = tracePosInfo[4];
            const subW:Number = (CANVAS_WIDTH-w)/2;
            const subH:Number = (CANVAS_HEIGHT-h)/2;
            const rPos:Point = rotatePoint(subW,subH,canvasTraceLayer.rotation);

            _canvasTrace.x = w/2;
            _canvasTrace.y = h/2;

            if(movedFlag)
            {
                _canvasTraceBitmap.x += -rPos.x/scX;
                _canvasTraceBitmap.y += -rPos.y/scY;
            }
            else
            {
                _canvasTraceBitmap.x += rPos.x/scX;
                _canvasTraceBitmap.y += rPos.y/scY;
            }

            tracePosInfo[0] = _canvasTraceBitmap.x;
            tracePosInfo[1] = _canvasTraceBitmap.y;
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
            drawGrid();
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
                                        "1:2",0.5,
                                        "9:16",0.5625,
                                        "10:16",0.625,
                                        "3:4",0.75,

                                        "1:1",1.0,

                                        "4:3",1.333,
                                        "16:10",1.6,
                                        "16:9",1.777,
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
            var startByShortCut:Boolean;
            var canvasSizeChanging:Boolean;

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
                const arr:Array = ratioSizeArr;
                const len:uint = arr.length-1;
                const floor:Function = Math.floor;
                var low:Number = 0;
                var high:Number = arr.length-1;
                var index:Number = floor((low+high)/2);
                var snapWidth:Number;

                while(low <= high)//2진 탐색
                {
                    snapWidth = arr[index][0];

                    if(snapWidth === width) break;
                    else if(snapWidth > width) high = index-1;
                    else low = index+1;

                    index = floor((low + high)/2);
                }

                ++index;

                if(index < 0) index = 0;
                else if(index > len) index = len;

                return ratioSizeArr[index];
            }

            function drawRatioSnapGuide(w:Number,h:Number,targetName:String):void
            {
                widthFlag = (targetName === "resizeButtonL" || targetName === "resizeButtonR") ? true : false;
                const flipFlag:Boolean = (targetName === "resizeButtonU" || targetName === "resizeButtonL") ? true : false;
                const g:Graphics = resizePreviewRatioRect.graphics;
                const lineSize:Number = 3/zoomed;
                const lineWidth:Number = guideLineWidth;

                function _drawRatioLine(referenceSize:Number,offset:Number):void
                {
                    const round:Function = Math.round;
                    const len:uint = ratioArr.length;
                    const color:uint = uiColorSet[uiColorIndex][1];
                    var i:uint;
                    var prevSize:Number; //스냅 격자 그려주는 위치
                    var realSize:Number; //스냅 걸릴때 실제 사이즈

                    ratioSizeArr.length = 0;

                    //hittestpoint를 위해서 배경을 그려줌
                    g.beginFill(0xFFFF00,0.0);
                    if(widthFlag) g.drawRect(-max/2,-lineWidth,max*2,lineWidth);
                    else g.drawRect(-lineWidth,-max/2,lineWidth,max*2);
                    g.endFill();

                    for(i=0;i<len;i+=2)
                    {
                        realSize = round(referenceSize*ratioArr[i+1]);
                        prevSize = realSize;
                        if(realSize > max || realSize < min) continue;

                        g.lineStyle(lineSize,color,1.0,true,"normal","none");

                        if(flipFlag) prevSize = -prevSize+offset;

                        if(widthFlag)
                        {
                            g.moveTo(prevSize,0);
                            g.lineTo(prevSize,-lineWidth);
                        }
                        else
                        {
                            g.moveTo(0,prevSize);
                            g.lineTo(-lineWidth,prevSize);
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

            function exitResizeCanvas(forceExit:Boolean):void
            {
                if(resizeInitON)
                {
                    resizeInitON = false;
                    if(targetName !== null)
                    {
                        stage.removeEventListener(MouseEvent.MOUSE_UP,resizeButtonMouseUpEvent);
                        stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,resizeButtonRightMouseUpEvent);

                        if(targetName === "resizeButtonL") stageMouseMoveEvent.remove("resizeMouseMoveL");
                        else if(targetName === "resizeButtonR") stageMouseMoveEvent.remove("resizeMouseMoveR");
                        else if(targetName === "resizeButtonU") stageMouseMoveEvent.remove("resizeMouseMoveU");
                        else if(targetName === "resizeButtonD") stageMouseMoveEvent.remove("resizeMouseMoveD");
                    }

                    canvasSizeChanging = false;
                    toolTipBox.visible = false;
                    setResizeButtonVisible((forceExit || (startByShortCut && !isPressingControl())) ? false:true);
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
                            addUndoDataContinue();
                        }
                        else
                        {
                            addUndoData();
                            if(canvasWindowON)
                            {
                                updateCanvasWindowBitmapSize();
                            }
                        }
                    }

                    targetName = null;
                }
            }

            function resizeButtonRightMouseUpEvent(e:MouseEvent):void
            {
                exitResizeCanvas(true);
            }

            function resizeButtonMouseUpEvent(e:MouseEvent):void
            {
                exitResizeCanvas(false);
            }

            function drawResizePreviewRect(size:Number,x:Number,y:Number,w:Number,h:Number):void
            {
                const resizeg:Graphics = resizePreviewRect.graphics;

                resizeg.clear();

                if(size > 0) resizeg.beginFill(bgColor);
                else resizeg.beginFill(stageColor);

                resizeg.drawRect(x,y,w,h);

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
                        setToolTipON(oldWidth+" x "+finalHeight+" ("+snap[1]+")");

                        return subY;
                    }
                }

                finalHeight = height;
                setToolTipON(oldWidth+" x "+finalHeight);

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
                        setToolTipON(finalWidth+" x "+oldHeight+" ("+snap[1]+")");

                        return subX;
                    }
                }

                finalWidth = width;
                setToolTipON(finalWidth+" x "+oldHeight);

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

            function startResizeCanvas(_targetName:String,shortcut:Boolean):void
            {
                initResizeVars();
                startByShortCut = shortcut;
                targetName = _targetName;
                resizeClickPos.setTo(canvasPanel.mouseX,canvasPanel.mouseY);
                canvasSizeChanging = true;

                drawRatioSnapGuide(oldWidth,oldHeight,targetName);
                checkRatioSnapGuidePos();

                if(toolBox2ON) toolBox2.visible = false;
                setResizeButtonVisible(false);

                stage.addEventListener(MouseEvent.MOUSE_UP,resizeButtonMouseUpEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,resizeButtonRightMouseUpEvent);

                if(targetName === "resizeButtonL") stageMouseMoveEvent.add("resizeMouseMoveL",resizeMouseMoveL);
                else if(targetName === "resizeButtonR") stageMouseMoveEvent.add("resizeMouseMoveR",resizeMouseMoveR);
                else if(targetName === "resizeButtonU") stageMouseMoveEvent.add("resizeMouseMoveU",resizeMouseMoveU);
                else if(targetName === "resizeButtonD") stageMouseMoveEvent.add("resizeMouseMoveD",resizeMouseMoveD);
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
            const floor:Function = Math.floor;
            const rectLeft:Number = rectArr[0];
            const rectTop:Number = rectArr[1];
            const rectWidth:Number = rectArr[2] - rectLeft;
            const rectHeight:Number = rectArr[3] - rectTop;
            const lassoPointsLen:uint = points.length;

            //가로세로 길이가 0 이하이면 실행하지 않음
            if(floor(rectWidth) <= 0 || floor(rectHeight) <= 0) return false;

            var drawEnt:Shape;
            var canvasBitmapData:BitmapData;
            var canvasBitmapDataSub:BitmapData;
            var canvasBitmap:Bitmap;
            var canvasBitmapSub:Bitmap;
            var canvas2FilterBackUp:Array = null //에어브러시 켜줄때 필터 백업함

            if(replayMode)
            {
                canvas2FilterBackUp = rcanvas2Draw.filters.concat();
                rcanvas2Draw.filters = [];
                drawEnt = rcanvas2Draw

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
                drawEnt = canvas2Draw;

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

            const cd:Shape = drawEnt;
            const cdg:Graphics = cd.graphics;
            const halfWidth:Number = rectWidth/2;
            const halfHeight:Number = rectHeight/2;
            const lassoP0:Array = points[0];
            const zerop:Point = new Point(0,0);
            const newRectangle:Rectangle = new Rectangle(rectLeft,rectTop,rectWidth,rectHeight);

            var lassoBMPD:BitmapData = new BitmapData(rectWidth,rectHeight,true,0);
            var lassoBMPDsub:BitmapData = new BitmapData(rectWidth,rectHeight,true,0);
            var i:uint;
            var x:Number;
            var y:Number;
            var nowPoint:Array;
            var xx:Number;
            var yy:Number;

            //지우기 전에 사각형 모양으로 그려준 부분을 copypixel 함.
            if(layer1) lassoBMPD.copyPixels(canvasBitmapData,newRectangle,zerop,null,null,true);
            if(layer2) lassoBMPDsub.copyPixels(canvasBitmapDataSub,newRectangle,zerop,null,null,true);

            //bitmap1canvas에서 그려준 영역을 지워줌
            if(!copyFlag)
            {
                x = lassoP0[0];
                y = lassoP0[1];
                cdg.clear();
                cdg.beginFill(CANVAS_BG_COLOR);
                cdg.moveTo(x,y);

                //rectLeft를 빼줘서 canvasdraw2의 0,0영역에 그려줌
                for(i=1;i<lassoPointsLen;i++)
                {
                    nowPoint = points[i] as Array;
                    x = nowPoint[0];
                    y = nowPoint[1];
                    cdg.lineTo(x,y);
                }
                cdg.endFill();
                if(layer1)
                {
                    canvasBitmapData.draw(cd,null,null,"erase");
                    canvasBitmap.bitmapData = canvasBitmapData;
                    if(deepUndoON)
                    {
                        if(rcanvas1BitmapData && canvasBitmapData !== rcanvas1BitmapData) rcanvas1BitmapData.dispose();
                        rcanvas1BitmapData = canvasBitmapData.clone();
                    }
                }

                if(layer2)
                {
                    canvasBitmapDataSub.draw(cd,null,null,"erase");
                    canvasBitmapSub.bitmapData = canvasBitmapDataSub;
                    if(deepUndoON)
                    {
                        if(rcanvas11BitmapData && canvasBitmapDataSub !== rcanvas11BitmapData) rcanvas11BitmapData.dispose();
                        rcanvas11BitmapData = canvasBitmapDataSub.clone();
                    }
                }
            }

            //-------------------------
            //clip하기 위해서 그려운 영역의 반전 부분을 0,0영역을 기준으로 그려줌
            //2번 반복하는게 좀 그런데 다른 방법 모르겠음
            //가로세로 절반 크기만큼 더해줘서 bmp의 중점으로 이동해주기 때문에 또 그만큼 빼줌
            cdg.clear();
            cdg.beginFill(0x00FF00);
            cdg.drawRect(0,0,rectWidth,rectHeight);
            cdg.moveTo(lassoP0[0]-rectLeft,lassoP0[1]-rectTop);

            //rectLeft를 빼줘서 canvasdraw2의 0,0영역에 그려줌
            for(i=1;i<lassoPointsLen;i++)
            {
                nowPoint = points[i];
                xx = (nowPoint[0]-rectLeft);
                yy = (nowPoint[1]-rectTop);
                cdg.lineTo(xx,yy);
            }

            //마지막으로 시작점을 이어줌
            cdg.endFill();
            if(layer1)
            {
                lassoBMP.bitmapData = lassoBMPD;
                lassoBMP.bitmapData.draw(cd,null,null,"erase");
            }

            if(layer2)
            {
                lassoBMPsub.bitmapData = lassoBMPDsub;
                lassoBMPsub.bitmapData.draw(cd,null,null,"erase");
            }
            cdg.clear(); //꼭 해줘야함

            //회전 확대를 bmp사각형의 중심으로 맞추어줌

            if(layer1)
            {
                lassoBMP.x = -halfWidth;
                lassoBMP.y = -halfHeight;
                lassoBMP.smoothing = true;
            }

            if(layer2)
            {
                lassoBMPsub.x = -halfWidth;
                lassoBMPsub.y = -halfHeight;
                lassoBMPsub.smoothing = true;
            }

            lassoBox.x = rectLeft+halfWidth;
            lassoBox.y = rectTop+halfHeight;
            lassoDraw.x = -lassoBox.x;
            lassoDraw.y = -lassoBox.y;

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

        private function cLassoTool():Function
        {
            const cd:Shape = canvas2Draw;
            const lassoDottedLineLimit:int = 3;
            const lassog:Graphics = lassoDraw.graphics;
            const _dottedLine:Object = dottedLine;
            var clickPos:Point = new Point(0,0);
            var maxWidth:Number;
            var maxHeight:Number;

            var lassoRect:Vector.<Number>;
            var lassoPoints:Array;

            function drawPreviewLine():void
            {
                const _lassoPoints:Array = lassoPoints;
                const g:Graphics = lassog;
                const len:int = _lassoPoints.length;
                var x:Number = _lassoPoints[0][0];
                var y:Number = _lassoPoints[0][1];

                g.clear();
                if(_lassoPoints.length < 2) return;

                _dottedLine.ready(g,x,y);

                for(var i:int=0; i<len; i++)
                {
                    x = _lassoPoints[i][0];
                    y = _lassoPoints[i][1];
                    _dottedLine.draw(g,x,y);
                }
                _dottedLine.draw(g,_lassoPoints[0][0],_lassoPoints[0][1]);
            }

            function setDeafultLassoMenuPos(lassoMenu:lassoButtons):void
            {
                const floor:Function = Math.floor;
                const g:Point = lassoBox.localToGlobal(new Point(0,0));
                const lassoW:Number = (lassoMenu.width > stage.stageWidth)
                                      ? stage.stageWidth : lassoMenu.width;

                lassoMenu.x = floor(g.x-lassoW/2);
                lassoMenu.y = floor(g.y+(((lassoBox.height)/2)*zoomed+20));
                // lassoMenu.y = floor(g.y+(((lassoBox.height)/2)/zoomed+15));
            }

            function lassoDrawMouseUp():void
            {
                stageMouseMoveEvent.remove("lassoDrawMouseMove");
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
                    return;
                }

                if(checklayer2)
                {
                    canvasPanel.setChildIndex(lassoBox,canvasPanel.getChildIndex(canvas1Bitmap)-1);
                }
                drawPreviewLine();

                //라소 메뉴 마우스 커서에보이기
                lassoStartData = [lassoBox.x,lassoBox.y,lassoBox.scaleX,lassoBox.scaleY,lassoBox.rotation];
                lassoToolON = true;
                setDeafultLassoMenuPos(lassoMenu);
                checkLassoMenuPos();
                lassoMenu.visible = true;
                setTopChildIndex(lassoMenu);

                if(traceMenuON === true) traceMenu.visible = false;

                toolBox.setToolButtonsForCheckedLayerOFF();
                toolBox.alpha = BUTTON_OFF_ALPHA;
                addMouseKeyEventLassoTool();
            }

            function lassoDrawMouseMove(MouseEvent:Event):void
            {
                var mx:Number = cd.mouseX;
                var my:Number = cd.mouseY;

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

            return function():void
            {
                if(lassoToolON === true || isAllLayerInvisible()) return;

                lassoMenu.hint("Lasso tool");
                maxWidth = CANVAS_WIDTH;
                maxHeight = CANVAS_HEIGHT;

                clickPos.setTo(cd.mouseX,cd.mouseY);

                lassoDraw.x = 0;
                lassoDraw.y = 0;

                //left, top, right, bottom순임
                lassoRect = new <Number> [clickPos.x,clickPos.y,clickPos.x,clickPos.y];
                lassoPoints = [];
                lassoPointSave = [];

                canvas2.alpha = 1.0; //알파값이 조정되어 있을 수도 있기 때문에 해줌
                setTopChildIndex(lassoBox);

                lassog.clear();
                lassoBox.visible = true;

                lassoPoints.push([clickPos.x,clickPos.y]);

                _dottedLine.updateScale(zoomed);
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
                stageMouseMoveEvent.add("lassoDrawMouseMove",lassoDrawMouseMove);
                stage.addEventListener(MouseEvent.MOUSE_UP,lassoDrawMouseUp);
            };
        }

        private function RGBAtoRGB(bgColor:uint,a:Number,color:uint):uint
        {
            var c:Vector.<uint> = HEXtoRGB(color);

            const _bg:Vector.<uint> = HEXtoRGB(bgColor);
            const r:uint = c[0];
            const g:uint = c[1];
            const b:uint = c[2];
            const _r:uint = _bg[0];
            const _g:uint = _bg[1];
            const _b:uint = _bg[2];
            const alp:Number = (1-a);
            const c16:uint = (alp*_r + a*r) << 16;
            const c8:uint = (alp*_g + a*g) << 8
            const c0:uint = (alp*_b + a*b);
            const rgb:uint = c16|c8|c0;

            return rgb;
        }

        private function cSpuitTool():Function
        {
            //일단 흰색으로 배경 깔아줌
            const spuitCursor:spuitMag = spuitZoomCursor;
            const humaneye:Function = getColorDifferenceForHuman;
            const floor:Function = Math.floor;
            const _setColorTransform:Function = setColorTransform;
            const pickerBox:colorPickerBox = pickerBox;
            const colorHistoryItemWidth:Number = colorHistoryColorWidth;
            const colorMatchMidX:Number = colorHistoryItemWidth/2;
            const _spuitZoomBitmap:Bitmap = spuitZoomCursor.spuitZoomBitmap;
            const magSize:Number = spuitCursor.magSize;
            const _canvasPanel:Sprite = canvasPanel;
            const lastPickedColor:uint = 0;
            const canvasBGShape:Shape = new Shape();
            const _canvas1Bitmap:Bitmap = canvas1Bitmap;
            const _canvas11Bitmap:Bitmap = canvas11Bitmap;

            var spuitDefaultZoom:Number = 2.0; // zoomed에 따라서 가변됨 초기값 1 x 2.0
            var canvasBGColor:uint = CANVAS_BG_COLOR;
            var canvas1bmpd:BitmapData;
            var canvas11bmpd:BitmapData;
            var penColorBackup:uint;

            function isButtonSkipOldTool(targetName:String):Boolean
            {
                return !(targetName === "toolZoom"
                || targetName === "toolRotate"
                || targetName === "toolMirror"
                || targetName === "toolUndo"
                || targetName === "toolRedo"
                || targetName === "toolTrace")
            }

            function setSpuitMag():void
            {
                const mid:Number = magSize/(4*zoomed); //기본 중앙값 magsize/2에서 zoomed나워주고 기본이 2배줌이니까 2로 나눠준값
                const bmpd:BitmapData = new BitmapData(magSize,magSize,true,0xFF000000|uiColorSet[uiColorIndex][2]);
                const tx:Number = -_canvas1Bitmap.mouseX+mid;
                const ty:Number = -_canvas1Bitmap.mouseY+mid;
                const mat:Matrix = new Matrix();

                mat.translate(tx,ty);
                mat.scale(spuitDefaultZoom,spuitDefaultZoom);

                bmpd.draw(canvasPanel,mat);

                _spuitZoomBitmap.bitmapData = bmpd;
            }

            function pickColor():uint
            {
                if(isHitTestPoint(canvas1Bitmap))
                {
                    //뽑기색
                    const round:Function = Math.round;

                    //배경색
                    const r3:uint = (canvasBGColor & 0xFF0000) >> 16;
                    const g3:uint = (canvasBGColor & 0x00FF00) >> 8;
                    const b3:uint = (canvasBGColor & 0x0000FF);

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
                    if(_canvas1Bitmap.visible)
                    {
                        const c1:uint = canvas1bmpd.getPixel32(_canvas1Bitmap.mouseX,_canvas1Bitmap.mouseY);
                        a1 = ((c1 & 0xFF000000) >>> 24)/255;
                        r1 = (c1 & 0x00FF0000) >>> 16;
                        g1 = (c1 & 0x0000FF00) >>> 8;
                        b1 = (c1 & 0x000000FF);
                    }

                    //밑 레이어
                    if(_canvas11Bitmap.visible)
                    {
                        const c2:uint = canvas11bmpd.getPixel32(_canvas1Bitmap.mouseX,_canvas1Bitmap.mouseY);
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
                    rr = round(r2*a2)+round(r3*aa);
                    gg = round(g2*a2)+round(g3*aa);
                    bb = round(b2*a2)+round(b3*aa);

                    //그 위에 위 레이어
                    const aa1:Number = 1.0-a1;
                    const r:uint = round(r1*a1)+round(rr*aa1);
                    const g:uint = round(g1*a1)+round(gg*aa1);
                    const b:uint = round(b1*a1)+round(bb*aa1);

                    return RGBtoHex(r,g,b);
                }
                else
                {
                    return penColorBackup;
                }
            }

            //픽커 도중에 오른쪽 클릭하면 캔슬해줌
            function colorPickerCancelKeyUpEvent(e:KeyboardEvent):void
            {
                if(e.keyCode === KEY.c || e.keyCode === KEY.m)
                {
                    colorPickerOFF(true,false);
                }
            }

            // function colorPickerCancelKeyDownEvent(e:KeyboardEvent):void
            // {
            //     if(e.keyCode === KEY.c || e.keyCode === KEY.m)
            //     {
            //         return;
            //     }

            //     colorPickerOFF(false,false);
            // }

            function colorPickerCancelMouseEvent(e:MouseEvent):void
            {
                const skipOldToolFlag:Boolean = (e.target && e.target.name) ? isButtonSkipOldTool(e.target.name) : false;
                colorPickerOFF(false,skipOldToolFlag);
            }

            function colorPickerOKMouseEvent(e:MouseEvent):void
            {
                if(spuitCursor.visible) colorPickerOFF(true,false);
                else
                {
                    const skipOldToolFlag:Boolean = (e.target && e.target.name) ? isButtonSkipOldTool(e.target.name) : false;
                    colorPickerOFF(false,skipOldToolFlag);
                }
            }

            function colorPickerOFF(okFlag:Boolean,skipOldTool:Boolean):void
            {
                removeSpuitEvent();

                if(okFlag && spuitCursor.visible === true)
                {
                    const pickedColor:uint = pickColor();
                    const findColor:uint = colorHistoryList.lastIndexOf(pickedColor)

                    changedColor = pickedColor; //이 변수는 컬러 히스토리를 선택했을때 선택할 색을 저장하는 변수인데 여기다가도 변경해줘서
                    penColor = pickedColor;
                    updatePickerCurrentColor(pickedColor);
                    setHSVCursorPosByColor(pickedColor);

                    if(findColor !== -1)
                    {
                        setColorHistoryLastColorByIndex(findColor);
                        updateColorHistoryList();
                    }

                    if(oldTool === TOOL_LINE) oldTool = TOOL_LINE;
                    else if(oldTool === TOOL_FILL_PEN) oldTool = TOOL_FILL_PEN;
                    else oldTool = TOOL_PEN;
                }

                canvas1bmpd = null;
                canvas11bmpd = null;

                spuitCursor.visible = false;

                if(!skipOldTool) restoreFirstUsedTool();
                if(_spuitZoomBitmap.bitmapData) _spuitZoomBitmap.bitmapData.dispose();
            }

            function colorPickerMoveEvent(e:MouseEvent):void
            {
                const targetName:String = e.target.name;

                spuitCursor.x = mouseX;
                spuitCursor.y = mouseY;

                if(isCursorInDrawArea())
                {
                    _setColorTransform(spuitCursor["spuitNowColor"],pickColor());
                    if(zoomed < 12.0) setSpuitMag();
                    spuitCursor.visible = true;
                }
                else
                {
                    spuitCursor.visible = false;
                }
            }

            function removeSpuitEvent():void
            {
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,colorPickerOKMouseEvent);
                stageMouseMoveEvent.remove("colorPickerMoveEvent");
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,colorPickerCancelMouseEvent);
                // stage.removeEventListener(KeyboardEvent.KEY_DOWN,colorPickerCancelKeyDownEvent);
                stage.removeEventListener(KeyboardEvent.KEY_UP,colorPickerCancelKeyUpEvent);
            }

            function addSpuitEvent():void
            {
                stage.addEventListener(MouseEvent.MOUSE_DOWN,colorPickerOKMouseEvent,false,-2);
                stageMouseMoveEvent.add("colorPickerMoveEvent",colorPickerMoveEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,colorPickerCancelMouseEvent);
                // stage.addEventListener(KeyboardEvent.KEY_DOWN,colorPickerCancelKeyDownEvent,false,2);
                stage.addEventListener(KeyboardEvent.KEY_UP,colorPickerCancelKeyUpEvent,false,2);
            }

            return function ():void
            {
                toolBox.moveToolCursor("toolSpuit");
                if(checkedLayer !== 0) return;

                controlBox.sharpLineButtonWrapper.alpha = BUTTON_OFF_ALPHA;
                controlBox.airBrushButtonWrapper.alpha = BUTTON_OFF_ALPHA;

                if(isAllLayerInvisible()) return;

                canvasBGColor = CANVAS_BG_COLOR;
                canvas1bmpd = canvas1BitmapData;
                canvas11bmpd = canvas11BitmapData;
                spuitDefaultZoom = zoomed*2.0;
                if(!isNowTool(TOOL_SPUIT) && oldTool === TOOL_NONE) oldTool = nowTool;
                setNowTool(TOOL_SPUIT);
                penColorBackup = penColor;
                _setColorTransform(spuitCursor["spuitOldColor"],penColor);
                moveEraseButton("toolSpuit");
                spuitCursor.rotateBitmap(regPoint.rotation);

                if(isCursorInDrawArea())
                {
                    spuitCursor.x = mouseX;
                    spuitCursor.y = mouseY;
                    _setColorTransform(spuitCursor["spuitNowColor"],pickColor());
                    setTopChildIndex(spuitCursor);

                    if(zoomed < 12.0)
                    {
                        spuitCursor.spuitZoomBitmapBox.visible = true;
                        setSpuitMag();
                    }
                    else
                    {
                        spuitCursor.spuitZoomBitmapBox.visible = false;
                    }
                    spuitCursor.visible = true;
                }

                addSpuitEvent();
            };
        }

        private function setOptimizeCanvasMove(flag:Boolean):void
        {
            if(canvasTraceLayer.alpha > 0.0) canvasTraceLayer.visible = !flag;
            if(gridFlag > 0) canvasGrid.visible = !flag;
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
                stageMouseMoveEvent.remove("handToolMoveEvent");
                stage.removeEventListener(MouseEvent.MOUSE_UP, handToolUpEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, handToolUpEvent);

                mouseDragON = false;
                penCursorOFFFlag = false;

                checkCanvasPanelPos(_replayMode);

                if(isDrawMode)
                {
                    setOptimizeCanvasMove(false);

                    if(lassoToolON)
                    {
                        if(lassoMenuTempOFF === true)
                        {
                            setlassoMenuTempOFF();
                        }
                    } //tool box에서 클릭해서 핸드툴 들어갈때 필요함
                    else if(!isNowKey(KEY.space)) restoreFirstUsedTool();

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

            return function (replayMode:Boolean=false):void
            {
                _replayMode = replayMode;
                isDrawMode = !replayMode;
                xReg = (isDrawMode) ? regPoint : rregPoint;
                xBitmap = (isDrawMode) ? canvas1Bitmap : rcanvas1Bitmap;
                old.setTo(mouseX,mouseY);
                penCursorOFFFlag = true;

                if(isDrawMode)
                {
                    toolBox.setCursorVisible(false);
                    setOptimizeCanvasMove(true);
                }

                stageMouseMoveEvent.add("handToolMoveEvent",handToolMoveEvent);
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
            const lassoBMPScaleX:Number = lassoBox.scaleX;
            const lassoBMPScaleY:Number = lassoBox.scaleY;
            var lassoBMPWidth:Number = lassoBMP.width*lassoBMPScaleX;
            var lassoBMPHeight:Number = lassoBMP.height*lassoBMPScaleY;

            if(checkedLayer === 2 || canvas1Bitmap.visible === false)
            {
                lassoBMPWidth = lassoBMPsub.width*lassoBMPScaleX;
                lassoBMPHeight = lassoBMPsub.height*lassoBMPScaleY;
            }

            const boxX:Number = lassoBox.x;
            const boxY:Number = lassoBox.y;
            const ang:Number = lassoBox.rotation*Math.PI/180;
            var posMatrix:Matrix = new Matrix();

            posMatrix.scale(lassoBMPScaleX,lassoBMPScaleY);//스케일부터 조절해주고
            posMatrix.translate(-lassoBMPWidth/2,-lassoBMPHeight/2); //회전 중심점을 bmp중심으로 옮겨주고
            posMatrix.rotate(ang);//회전해줌
            posMatrix.translate(boxX,boxY);//라소박스 위치 그대로 붙여주면됨

            //캔버스 1에 그려줌
            lassoBMPsub.smoothing = true;
            lassoBMP.smoothing = true;

            if(lassoBMPScaleX !== 1 || lassoBox.rotation !== 0)
            {
                applyLassoShapen(lassoBMPScaleX);
            }

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

                    rDataBuffer.push(["lasso",point1,point2,lassoInfo,lassoCopyON,checklayer1,checklayer2]);
                    addUndoData();
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
            if(lassoBMP.bitmapData !== null) lassoBMP.bitmapData.dispose();
            if(lassoBMPsub.bitmapData !== null) lassoBMPsub.bitmapData.dispose();
        }

        private function lassoCancelBmpd():void
        {
            if(lassoBitmapdataSave)
            {
                if(canvas1BitmapData && lassoBitmapdataSave !== canvas1BitmapData) canvas1BitmapData.dispose();
                canvas1BitmapData = lassoBitmapdataSave.clone();
                canvas1Bitmap.bitmapData = canvas1BitmapData;
                if(deepUndoON)
                {
                    if(rcanvas1BitmapData && lassoBitmapdataSave !== rcanvas1BitmapData) rcanvas1BitmapData.dispose();
                    rcanvas1BitmapData = lassoBitmapdataSave.clone();
                }
            }

            if(lassoBitmapdataSubSave)
            {
                if(canvas11BitmapData && lassoBitmapdataSubSave !== canvas11BitmapData) canvas11BitmapData.dispose();
                canvas11BitmapData = lassoBitmapdataSubSave.clone();
                canvas11Bitmap.bitmapData = canvas11BitmapData;
                if(deepUndoON)
                {
                    if(rcanvas11BitmapData && lassoBitmapdataSave !== rcanvas11BitmapData) rcanvas11BitmapData.dispose();
                    rcanvas11BitmapData = lassoBitmapdataSave.clone();
                }
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

            controlBox.sharpLineButtonWrapper.alpha = BUTTON_OFF_ALPHA;
            controlBox.airBrushButtonWrapper.alpha = BUTTON_OFF_ALPHA;
        }

        private function selectZoomTool():void
        {
            setNowTool(TOOL_ZOOM);
            toolBox.moveToolCursor("toolZoom");

            controlBox.sharpLineButtonWrapper.alpha = BUTTON_OFF_ALPHA;
            controlBox.airBrushButtonWrapper.alpha = BUTTON_OFF_ALPHA;
        }

        private function selectRotateTool():void
        {
            setNowTool(TOOL_ROTATE);
            toolBox.moveToolCursor("toolRotate");
        }

        private function selectLassoTool():void
        {
            setNowTool(TOOL_LASSO);
            moveEraseButton("toolLasso");
            toolBox.moveToolCursor("toolLasso");

            controlBox.sharpLineButtonWrapper.alpha = BUTTON_OFF_ALPHA;
            controlBox.airBrushButtonWrapper.alpha = BUTTON_OFF_ALPHA;
        }

        private function selectFillPenTool():void
        {
            setNowTool(TOOL_FILL_PEN);

            penSizeCursor.visible = false;

            controlBox.sharpLineButtonWrapper.alpha = 1.0;
            controlBox.airBrushButtonWrapper.alpha = 1.0;

            canvasPanel.setChildIndex(canvas1Bitmap,2);
            updateOpaBoxColor(penColor);
            updateOpacityCursor(penAlphaIndex);
            setAirBrushCheckBox(airBrushON,true);
            setPenSize(penSizeIndex);

            moveEraseButton("toolFillPen");
            toolBox.moveToolCursor("toolFillPen");
            setControlBoxInfoOFF();
        }

        private function moveEraseButton(toolName:String):void
        {
            const _toolBox2:toolButtons2 = toolBox2;
            const eraseButton2:SimpleButton = _toolBox2["toolErase"];
            const nowButton2:SimpleButton = _toolBox2[toolName] as SimpleButton;

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
            eraseButton2.visible = true;
            eraseButton2.x = nowButton2.x;
            eraseButton2.y = nowButton2.y;
            setTopChildIndex(eraseButton2);
        }

        //펜 지우개 직선 지우개-직선 통합
        private function cCheckMainDrawTool():Function
        {
            const _controlBox:controlMenu = controlBox;
            const _toolBox:toolButtons = toolBox;
            const _toolBox2:toolButtons2 = toolBox2;
            const eraseButton2:SimpleButton = _toolBox2["toolErase"];
            const penButton2:SimpleButton = _toolBox2["toolPen"];

            var sizeIndex:uint;
            var alphaIndex:uint;

            return function (size:uint,color:uint,alpha:Number,shape:Boolean,penFlag:Boolean,lineFlag:Boolean):void
            {
                if(penFlag)
                {
                    sizeIndex = penSizeIndex;
                    alphaIndex = penAlphaIndex;

                    if(subLayerON)
                        canvasPanel.setChildIndex(canvas2,2);
                    else
                        canvasPanel.setChildIndex(canvas1Bitmap,2);

                    setAirBrushCheckBox(airBrushON,true);
                }
                else
                {
                    sizeIndex = eraseSizeIndex;
                    alphaIndex = eraseAlphaIndex;

                    if(subLayerON)
                        canvasPanel.setChildIndex(canvas2,2);
                    else
                        canvasPanel.setChildIndex(canvas1Bitmap,2);

                    setAirBrushCheckBox(eraseAirBrushON,false);
                }

                _controlBox.sharpLineButtonWrapper.alpha = 1.0;
                _controlBox.airBrushButtonWrapper.alpha = 1.0;

                setPenSize(sizeIndex);
                setPenAlpha(alpha);

                updateOpaBoxColor(color);
                updateOpacityCursor(alphaIndex);

                if(lineFlag === false)
                {
                    if(penFlag)
                    {
                        moveEraseButton("toolPen");
                        toolBox.moveToolCursor("toolPen");
                        setControlBoxInfoOFF();
                    }
                    else
                    {
                        if(eraseMovedButton) eraseMovedButton.visible = true;

                        eraseMovedButton = null;

                        eraseButton2.visible = false;
                        toolBox.moveToolCursor("toolErase");
                        setControlBoxInfoOFF();
                    }
                }
                else //선툴을 선택했을때
                {
                    if(penFlag)
                    {
                        moveEraseButton("toolLine");
                        toolBox.moveToolCursor("toolLine");
                        setControlBoxInfoOFF();
                    }
                    eraseButton2.visible = true;
                    penButton2.visible = true;
                }

                _controlBox.shapeFlag(shape);
                updatePenCursorPosition();
            }
        }

        private function selectLineTool():void
        {
            setNowTool(TOOL_LINE);
            checkMainDrawTool(penSize,penColor,penAlpha,penShape,true,true);
        }

        private function selectPenTool():void
        {
            setNowTool(TOOL_PEN);
            checkMainDrawTool(penSize,penColor,penAlpha,penShape,true,false);
        }

        private function selectEraseTool():void
        {
            setNowTool(TOOL_ERASE);
            checkMainDrawTool(eraseSize,CANVAS_BG_COLOR,eraseAlpha,eraseShape,false,false);
        }

        //라소박스 변형이랑 플래그 초기화
        private function resetLassoBox():void
        {
            removeMouseKeyEventLassoTool();
            lassoToolON = false;
            lassoMirrorON = false;
            lassoCopyON = false;
            lassoMenuTempOFF = false;
            lassoStartData = [];
            lassoPointSave = [];
            lassoBMP.filters = [];
            lassoBMPsub.filters = [];
            lassoMenu.visible = false;
            lassoDraw.x = 0;
            lassoDraw.y = 0;
            lassoBox.visible = false;
            lassoBox.x = 0;
            lassoBox.y = 0;
            lassoBox.scaleX = 1.0;
            lassoBox.scaleY = 1.0;
            lassoBox.rotation = 0;
            canvasPanel.setChildIndex(lassoBox,canvasPanel.getChildIndex(canvas2)+1);
            lassoResizeMoveSum = 0;
            lassoMenu["lassoCopy"].alpha = 1.0;

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

            toolBox.alpha = 1.0;
            restoreFirstUsedTool();

            if(controlBox.layer1CheckButton.visible || controlBox.layer2CheckButton.visible)
            {
                toolBox.setToolButtonsForCheckedLayerON(BUTTON_OFF_ALPHA);
            }
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
            const round:Function = Math.round;
            tx = round(tx);
            ty = round(ty);

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
            const z:Number = zoomed;
            const rotateToolMoveEvent:Point = rotatePoint((xReg.x-tx)/xZoomed,
                                                 (xReg.y-ty)/xZoomed,
                                                 xReg.rotation);
            xReg.x = tx;
            xReg.y = ty;
            xCanvas.x += round(rotateToolMoveEvent.x);//이동한 만큼 거꾸로 움직여줌
            xCanvas.y += round(rotateToolMoveEvent.y);//rotate값 포함해서 움직여야함
        }

        //0,0을 기준으로 점tx,ty를 rad만큼 회전함,
        //3시 방향이 0도이고, 반시계 방향이 양수값임.
        private function rotatePoint(tx:Number,ty:Number,deg:Number):Point
        {
            const rad:Number = -(deg/180)*Math.PI;
            const cosO:Number = Math.cos(rad);
            const sinO:Number = Math.sin(rad);
            const x:Number = tx;
            const y:Number = ty;
            const rp:Point = new Point(x*cosO-y*sinO,x*sinO+y*cosO);

            return rp;
        }

        private function setTraceBitmapPosUndo(move:Point):void
        {
            const _canvasTraceBitmap:Bitmap = canvasTraceBitmap;
            const _canvasTrace:Sprite = canvasTraceLayer;

            _canvasTraceBitmap.x += -move.x*(1/_canvasTrace.scaleX);
            _canvasTraceBitmap.y += -move.y*(1/_canvasTrace.scaleY);

            tracePosInfo[0] = _canvasTraceBitmap.x;
            tracePosInfo[1] = _canvasTraceBitmap.y;
        }

        private function getCanvasMovedUndo(index:int,redoFlag:Boolean):Point
        {
            const prevData:Array = (redoFlag) ? rData[index] : rData[index+1];
            if(!prevData) return null;

            var len:int = prevData.length;
            var arr:Array;
            var x:Number = 0;
            var y:Number = 0;

            for(var i:int=0; i<len; i++)
            {
                arr = prevData[i] as Array;
                if(arr[0] === "canvasSize" && arr[5] === true)
                {
                    x += arr[3];
                    y += arr[4];
                }
            }
            if(x === 0 && y === 0) return null;

            const movedXY:Point = (redoFlag) ? new Point(-x,-y)
                                             : new Point(x,y);
            return movedXY;
        }

        private function drawUndoData(redoFlag:Boolean=false):void
        {
            const d:Array = undoData.getUndoRefImage();
            const image:BitmapData = d[0];
            const image1:BitmapData = d[1];
            const w:uint = d[2];
            const h:uint = d[3];
            const bg:uint = d[4];
            const index:int = undoIndex;
            const _tickDraw:Object = tickDraw;
            const _zoomed:Number = zoomed;

            rDataReadFlag = true;
            rIndex = index;
            rPrevFrame = rNowFrame;
            rNowFrame = getTotalFrameUntilUndoIndex(index);

            rMirrorON = d[5];
            if(w !== RCANVAS_WIDTH || h !== RCANVAS_HEIGHT) changeCanvasSizeReplayMode(w,h,0,0,false);
            if(bg !== RCANVAS_BG_COLOR) setBackgroundColorReplayMode(bg);

            rcanvas2Draw.graphics.clear();

            if(rcanvas1BitmapData && image !== rcanvas1BitmapData) rcanvas1BitmapData.dispose();
            rcanvas1BitmapData = image.clone();
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;

            if(rcanvas11BitmapData && image1 !== rcanvas11BitmapData) rcanvas11BitmapData.dispose();
            rcanvas11BitmapData = image1.clone();
            rcanvas11Bitmap.bitmapData = rcanvas11BitmapData;

            if(rData.length > 0)
            {
                for(var i:int=0; i<=index; i++)
                {
                    if(!rData[i]) continue;

                    _tickDraw.ready(rData[i]);
                    _tickDraw.drawAll();
                }
            }

            setBackgroundColorDrawMode(RCANVAS_BG_COLOR);
            changeCanvasSize(RCANVAS_WIDTH,RCANVAS_HEIGHT,0,0,false);
            //앞 뒤 데이터가 캔버스 원점 이동 되었을때 반대방향으로 다시 움직여줌
            const movedRegPos:Point = getCanvasMovedUndo(index,redoFlag);
            if(movedRegPos)
            {
                regPoint.x += movedRegPos.x*_zoomed;
                regPoint.y += movedRegPos.y*_zoomed;
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

        private function redo(keyFlag:Boolean):void
        {
            if(deepUndoON)
            {
                jumpOneFrame(false,false);
                drawReplayImageToDrawModeCanvas();

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
                }
            }
            addTimerByName("setRCursorVisibleOFFUndoTimer",2.0,false,setRCursorVisibleOFFUndo,[false]);
        }

        private function undo(keyFlag:Boolean):void
        {
            if(deepUndoON)
            {
                if(rNowFrame > 0)
                {
                    if(keyFlag) setJumpOneFrame(true,false);
                    else jumpOneFrame(true,false);

                    drawReplayImageToDrawModeCanvas();
                }

                if(rNowFrame <= 0)
                {
                    setRCursorVisibleOFFUndo();
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
                    }
                }
                else if(rData.length > 0)
                {
                    saveOneTime = false;
                    undoDelFlag = true;
                    drawUndoData();
                }
            }
            addTimerByName("setRCursorVisibleOFFUndoTimer",2.0,false,setRCursorVisibleOFFUndo,[false]);
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

        private function setRedoButton(useAutoKey:Boolean,shortcutFlag:Boolean=false):void
        {
            if(useAutoKey) setHoldKeyRepeat(redo,shortcutFlag);
            else redo(shortcutFlag);
        }

        private function setUndoButton(useAutoKey:Boolean,shortcutFlag:Boolean=false):void
        {
            if(useAutoKey) setHoldKeyRepeat(undo,shortcutFlag);
            else undo(shortcutFlag);
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
            const UNDO_LIMIT:int = 10;
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
                const d:Array = undoRefImage;
                const image:BitmapData = d[0];
                const image1:BitmapData = d[1];
                const w:uint = d[2];
                const h:uint = d[3];
                const bg:uint = d[4];
                const len:int = undoIndex;
                var rMirrorSave:Boolean = rMirrorON;

                if(w !== RCANVAS_WIDTH || h !== RCANVAS_HEIGHT) changeCanvasSizeReplayMode(w,h,0,0,false);
                if(bg !== RCANVAS_BG_COLOR) setBackgroundColorReplayMode(bg);

                if(rcanvas1BitmapData && image !== rcanvas1BitmapData) rcanvas1BitmapData.dispose();
                rcanvas1BitmapData = image.clone();

                if(rcanvas11BitmapData && image1 !== rcanvas11BitmapData) rcanvas11BitmapData.dispose();
                rcanvas11BitmapData = image1.clone();

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

                const _rDataFrame:Array = rDataFrame;
                var sum:Number = 0;

                for(var i:int=0;i<=index;i++)
                {
                    sum += _rDataFrame[i];
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
                const len:uint = rDataBuffer.length;
                //버퍼에mirror가 있을수도 있기 때문에 요소를 하나씩 push해주어야함
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

            function add():void
            {
                if(undoDelFlag === true)
                {
                    undoDelFlag = false;
                    rData.splice(undoIndex+1);
                    rDataFrame.splice(undoIndex+1);
                }

                if(rData.length >= UNDO_LIMIT) //첫번째 이미지는 빼야하니깐 -1로 계산해야함
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
                            if(rJumpImageCount > REPLAY_MAKE_JUMPIMAGE_COUNT)
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
                                            const undo2FirstData:Array = workerUndoData2[0];
                                            rJumpImageFrameData.push(undo2FirstData[4]);
                                            fs.open(rJumpImageFolder.resolvePath((rJumpImageFrameData.length-1)+""),FileMode.WRITE);
                                            fs.writeObject([workerUndoData[0][0]//레이어1
                                                            ,workerUndoData[0][1]//레이어2
                                                            ,undo2FirstData[0] //가로
                                                            ,undo2FirstData[1] //새로
                                                            ,undo2FirstData[2] //배경색
                                                            ,undo2FirstData[3] //마지막 바이트
                                                            ,undo2FirstData[4] //마지막 프레임 합
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
                add:add,
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
        private function setHSVCursorPosByColor(color:uint,initFlag:Boolean=false):void
        {
            if(color === penLastUpdateInfo[5] && !pickerColorSelected) return;

            penLastUpdateInfo[5] = color;

            const floor:Function = Math.floor;
            const round:Function = Math.round;
            const _pickerBox:colorPickerBox = pickerBox;
            const _colorBarWidth:Number = _pickerBox["svBoxWidth"];
            const _colorBarHeight:Number = _pickerBox["svBoxHeight"];
            const svCursor:SimpleButton = _pickerBox["svCursor"];
            const hueCursor:SimpleButton = _pickerBox["hueCursor"];
            const hsvColor:Vector.<Number> = HEXtoHSV(color);
            const hpos:Number= round(hsvColor[0]*_colorBarWidth);
            const spos:Number= round(hsvColor[1]*_colorBarWidth);
            const vpos:Number= round(_colorBarHeight - hsvColor[2]*_colorBarHeight);
            //s v값을 제외한 순수 hue 컬러
            const baseColor:Vector.<uint> = HSVtoRGB(hsvColor[0]*360,1.0,1.0);
            const baseHexColor:uint = RGBtoHex(baseColor[0],baseColor[1],baseColor[2]);
            const alpha:Number = (pickerMode === 1) ? penAlpha : 1.0;

            HUECOLOR[1] = hsvColor[1]; //round 해주면 안됨
            HUECOLOR[2] = hsvColor[2];

            svCursor.x = floor(spos+0.5);
            svCursor.y = floor(vpos+0.5);

            //채도가 0보다 클때에만  hue값을 업데이트해줌, 회색계열 선택할 때마다 hue가 0. 빨간색으로 돌아가는거 방지
            if(spos > 0 || initFlag === true)
            {
                HUECOLOR[0] = Math.round(hsvColor[0]*360);
                hueCursor.x = hpos;
                _pickerBox.changeHueColor(baseHexColor);
            }

            const c:Vector.<uint> = HEXtoRGB(color);
            const colorHint:String =  "RGB "+c[0]+","+c[1]+","+c[2];
            _pickerBox.setRGBInfo(colorHint);
            _pickerBox.setRGBInfoColor(getInvertColor(color,1.0
            ,(uiColorIndex >= 2) ? uiColorSet[uiColorIndex][0]:uiColorSet[uiColorIndex][1]
            ,(uiColorIndex >= 2) ? uiColorSet[uiColorIndex][1]:uiColorSet[uiColorIndex][0]));
            const defColor:Number = getColorDifferenceForHuman(color,uiColorSet[uiColorIndex][0]);

            _pickerBox.updateRGBInfoBG(color,setColorBorder(color));
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
        private function RGBtoHex(r:uint, g:uint, b:uint):uint
        {
            return (r << 16 | g << 8 | b);
        }

        //h는 0에서 360, s v는 0~1.0 사이값 넣어줘야함
        private function HSVtoRGB(h:Number, s:Number, v:Number):Vector.<uint>
        {
            const round:Function = Math.round;
            h = h/360;
            v = round(v * 255);

            const i:Number = Math.floor(h * 6);
            const f:Number = h * 6 - i;
            const p:Number = round(v * (1 - s));
            const q:Number = round(v * (1 - f * s));
            const t:Number = round(v * (1 - (1 - f) * s));

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
            return new Vector.<uint> ([0,0,0]);
        }

        //eyedropper에서 뽑은 rgb 컬러를 hvs로 변환해줄때 사용
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

            const hsv:Vector.<Number> = new <Number> [h, s, v];
            return hsv;
        }

        //opabox의 커서 위치와 색깔을 바꿈
        private function updateOpacityCursor(index:int):void
        {
            if(index < 0) return;

            const _opabox:Sprite = controlBox.opaBox;
            const curButton:SimpleButton = _opabox["alphaButton"+index];

            if(!curButton)return;
            if(penColor === penLastUpdateInfo[2] && index === penLastUpdateInfo[3]) return;

            penLastUpdateInfo[2] = penColor;
            penLastUpdateInfo[3] = index;

            const alphaCursor:SimpleButton = _opabox["alphaCursor"];

            alphaCursor.x = curButton.x;
            alphaCursor.y = curButton.y;
        }

        private function setPenAlpha(alpha:Number=0):void
        {
            //toolType 이 true이면 지우개임
            //펜이나 보통 라인툴이 아니면 리턴
            var index:int = alphaArr.indexOf(alpha);
            const eraseFlag:Boolean = isEraseTool();

            updateOpacityCursor(index);

            if(eraseFlag === false)
            {
                penAlpha = alpha;
                penAlphaIndex = index;
                updatePickerCurrentColor(penColor);
            }
            else if(eraseFlag === true)
            {
                eraseAlpha = alpha;
                eraseAlphaIndex = index;
            }
        }

        private function drawDot(shape:Boolean,size:uint,color:uint,x:Number,y:Number):void
        {
            const cd:Shape = canvas2Draw;
            const cdg:Graphics = cd.graphics;

            cdg.clear();
            cdg.lineStyle(0,0,0);
            cdg.beginFill(color);

            if(shape === false)
            {
                cdg.drawCircle(x,y,size/2);
            }
            else if(shape === true)
            {
                cdg.drawRect(x-size/2,y-size/2,size,size);
            }

            cdg.endFill();
        }

        private function updateSidebarDefaultRightPos():void
        {
            sideBar.x = Math.round(stage.stageWidth-sideBar.getWidth());
        }

        private function setSideBarRightPosition(ignoreCanvasMove:Boolean):void
        {
            const floor:Function = Math.floor;

            updateSidebarDefaultRightPos();

            sideBarScrollSet.x = 9;
            sideBarScrollSet.y = scrollSetMovedY;
            previewBox.x = -4;
            previewBox.y = 0;
            appInfoBox.setWidth(previewBox.BOX_WIDTH);
            appInfoBox.x = previewBox.x-2;
            appInfoBox.y = floor(previewBox.y+previewBox.BOX_HEIGHT+3);
            controlBox.x = 39;
            controlBox.y = floor(appInfoBox.y+appInfoBox.height);
            pickerBox.x = 39;
            pickerBox.y = floor(controlBox.y+controlBox.height+6);
            toolBox.x = -2;
            toolBox.y = floor(controlBox.y+2);

            sideBarScrollBar.x = previewBox.x-sideBarScrollBar.width+4;
            sideBarScrollBar.y = scrollBarMovedY;

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

            checkfofoPos();
            updateStageOffset();

            if(lassoToolON) checkBoxPosition(lassoMenu);
            if(traceMenuON) checkBoxPosition(traceMenu);
        }

        private function setSideBarLeftPosition():void
        {
            const floor:Function = Math.floor;
            sideBar.x = 0;

            sideBarScrollSet.x = 5;
            sideBarScrollSet.y = scrollSetMovedY;
            previewBox.x = 0;
            previewBox.y = 0;
            appInfoBox.setWidth(previewBox.BOX_WIDTH);
            appInfoBox.x = previewBox.x-2;
            appInfoBox.y = floor(previewBox.y+previewBox.BOX_HEIGHT+3);
            controlBox.x = 0;
            controlBox.y = floor(appInfoBox.y+appInfoBox.height);
            pickerBox.x = 0;
            pickerBox.y = floor(controlBox.y+controlBox.height+6);
            toolBox.x = 177;
            toolBox.y = floor(controlBox.y+2);

            if(toolBox.getDeafultY() === 0) toolBox.setDeafultY(toolBox.y);

            sideBarScrollBar.x = sideBar.w;
            sideBarScrollBar.y = scrollBarMovedY;

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

            checkfofoPos();
            updateStageOffset();

            if(lassoToolON) checkBoxPosition(lassoMenu);
            if(traceMenuON) checkBoxPosition(traceMenu);
        }

        private function updateScrollBarColorHeight(height:Number):void
        {
            var g:Graphics = sideBarScrollBar.graphics;
            const color1:uint = uiColorSet[uiColorIndex][1];
            const color2:uint = uiColorSet[uiColorIndex][0];

            g.clear();
            g.lineStyle(1,color1,1.0,true);
            // g.lineStyle(1,0,0);
            g.beginFill(color2);
            g.drawRect(0,0,16,height);
            g.endFill();

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

            sideBarScrollSet.addChild(previewBox);
            sideBarScrollSet.addChild(appInfoBox);
            sideBarScrollSet.addChild(toolBox);
            sideBarScrollSet.addChild(controlBox);
            sideBarScrollSet.addChild(pickerBox);
            sideBar.addChild(sideBarScrollBar);
            sideBar.addChild(sideBarScrollSet);
            sideBar.updateSideBGSize(stage.stageHeight);
            setSideBarLeftPosition();
            sideBarScrollBar.alpha = 0.7;

            STAGE_TOP_OFFSET = topBar.BARSIZE;

            topBar.updateTimerPos(stage.stageWidth);
            stage.addChild(fileDragSelectBox);
            stage.addChild(traceMenu);
            stage.addChild(aboutPanel);
            stage.addChild(topBar);
            stage.addChild(sideBar);
            stage.addChild(toolBox2);
            stage.addChild(rotateCursorBox);
            stage.addChild(toolTipBox);
            setTopChildIndex(topBar);
        }

        private function makeReplayCanvasFamily():void
        {
            var g:Graphics;
            const _rcanvasPanel:Sprite = rcanvasPanel;

            _rcanvasPanel.name = "rcanvasPanel";
            rregPoint.name = "rregPoint";
            rcanvas1Bitmap.name = "rcanvas1Bitmap";
            rcanvas11Bitmap.name = "rcanvas11Bitmap";
            rcanvas2.name = "rcanvas2";
            rcanvas2Draw.name = "rcanvas2Draw";
            replayTimeBox.name = "replayTimeBox";
            rCursor.name = "rCursor";
            rCursor.useHandCursor = false;

            g = _rcanvasPanel.graphics;
            _rcanvasPanel.graphics.beginFill(CANVAS_BG_COLOR);
            _rcanvasPanel.graphics.drawRect(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);
            _rcanvasPanel.graphics.endFill();

            //캔버스 박스에서 lineto가 아무데나 그려지면 안되서 mask로 가려줌
            g = rcanvasPanelMask.graphics;
            rcanvasPanelMask.graphics.beginFill(CANVAS_BG_COLOR);//paneldraw마스크 아무색이나 상관없음 어차피 마스크로 쓸거라
            rcanvasPanelMask.graphics.drawRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
            rcanvasPanelMask.graphics.endFill();

            rcanvas2.addChild(rcanvas2Bitmap);//
            rcanvas2.addChild(rcanvas2Draw);//canvas2에
            rcanvas2.blendMode = "layer";//캔버스1이랑 알파 불투명도가 겹치지 않게 layer모드로 해줌

            _rcanvasPanel.addChild(rcanvas11Bitmap);//판넬에 canvas1추가
            _rcanvasPanel.addChild(rcanvas1Bitmap);//판넬에 canvas1추가
            _rcanvasPanel.addChild(rcanvas2);//판넬에 canvas2추가
            _rcanvasPanel.addChild(rcanvasPanelMask);//판넬에  마스크 추가
            _rcanvasPanel.mask = rcanvasPanelMask;//마스크 해줘서 판 밖으로 선나타나지 않도록함

            _rcanvasPanel.x = Math.floor(-_rcanvasPanel.width/2);
            _rcanvasPanel.y = Math.floor(-_rcanvasPanel.height/2);

            rregPoint.addChild(_rcanvasPanel);
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

            penSizeCursor.visible = false;

            lassoBox.name = "lassoBox";
            lassoBox.addChild(lassoBMPsub);
            lassoBox.addChild(lassoBMP);
            lassoBox.addChild(lassoDraw);
            lassoBox.visible = false;

            captureAreaRect.visible = false;
            captureAreaRect.blendMode = "difference";

            setBackgroundColorDrawMode(CANVAS_BG_COLOR);
            updateCanvasPanelMask(CANVAS_WIDTH,CANVAS_HEIGHT);

            updateStageBG(uiColorSet[uiColorIndex][2]);

            canvasTraceLayer.alpha = CANVAS_TRACE_ALPHA;
            canvasTraceLayer.addChild(canvasTraceBitmap);
            canvas2.addChild(canvas2Bitmap);
            canvas2.addChild(canvas2Draw);
            canvas2.blendMode = "layer";//캔버스1이랑 알파 불투명도가 겹치지 않게 layer모드로 해줌

            canvasPanel.addChild(canvasTraceLayer);
            canvasPanel.addChild(canvas11Bitmap);
            canvasPanel.addChild(canvas1Bitmap);
            canvasPanel.addChild(canvas2);
            canvasPanel.addChild(lassoBox);
            canvasPanel.addChild(canvasGrid);
            rCursor.visible = false;
            canvasPanel.addChild(rCursor);
            canvasPanel.addChild(canvasPanelMask);
            canvasPanel.mask = canvasPanelMask;

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
        }

        private function updateScrollBarHeight(sth:Number):void
        {
            const floor:Function = Math.floor;
            const scale:Number = getUIScale();
            const topOffset:Number = STAGE_TOP_OFFSET;
            const sideBarSetHeight:Number = sideBarSetHeight*scale;
            sth = floor(sth-topOffset); //상단 메뉴 길이 빼줌 sth랑 sideBarSetHeight 같이 빼야함

            //창이 늘어났을때 여유공간 있으면 아랫쪽으로 옮겨줌
            const nowScrollSetBottom:Number = sideBarSetHeight+sideBarScrollSet.y*scale;
            if(nowScrollSetBottom < sth)
            {
                var newYPos:Number = floor(sideBarScrollSet.y*scale+(sth-nowScrollSetBottom))/scale;
                if(newYPos > 0) newYPos = 0;

                sideBarScrollSet.y = newYPos;
                scrollSetMovedY = newYPos;
            }

            if(sideBarSetHeight < sth || fillPenStarted)
            {
                sideBarScrollBar.visible = false;
                return;
            }

            var scScrollBarHeight:Number = floor(sth*(sth/sideBarSetHeight))/scale;
            if(scScrollBarHeight < 50) scScrollBarHeight = 50;

            updateScrollBarColorHeight(scScrollBarHeight);

            //스크롤바 위치 갱신
            const scrollSetY:Number = Math.abs(sideBarScrollSet.y*scale);
            const factor:Number = (sth-STAGE_BOTTOM_OFFSET-scScrollBarHeight*scale)/(sideBarSetHeight-sth);

            sideBarScrollBar.y = floor(scrollSetY*factor)/scale;
            sideBarScrollBar.visible = true;
        }

        private function windowResizedBeforeClosingEvent(e:Event):void
        {
            lastWindowState = 1;
            stage.nativeWindow.close();
        }

        private function windowResizeEvent(e:Event):void
        {
            addTimerByName("windowResizeDelayTimer",0.2,false,function():void
            {
                const _lastWindowSize:Point = lastWindowSize;
                const _lastWindowSize0:Number = _lastWindowSize.x;
                const _lastWindowSize1:Number = _lastWindowSize.y;
                const windowW:Number = stage.nativeWindow.width;
                const windowH:Number = stage.nativeWindow.height;
                const stw:Number = stage.stageWidth;
                const sth:Number = stage.stageHeight;
                const round:Function = Math.round;
                const dx:Number = round((windowW-_lastWindowSize0)/1.75);
                const dy:Number = round((windowH-_lastWindowSize1)/1.75);

                if(captureModeON)
                {
                    captureWindowMove.setTo(dx,dy);
                    fitCanvasToWindow(true);
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

                if(aboutPanelON) setAboutPanelCenterPos();

                if(replayModeON)
                {
                    updateReplayBarPos(stw);
                    autoScroll.updateRCanvasBounds();

                    if(rFitZoomedON) fitCanvasToWindowManualReplayMode();
                }

                updateStageBG(uiColorSet[uiColorIndex][2]);
                topBar.updateTopbarBG(stw);
                topBar.updateTimerPos(stw);
                topBar.updateHintBGWidth(stw);

                sideBar.updateSideBGSize((sth-STAGE_TOP_OFFSET)/getUIScale());
                updateScrollBarHeight(sth);

                if(isRightSidebar)
                {
                    if(sideBar.tempVisibleON) sideBar.setTempVisibleON(toolBox.BOX_WIDTH+10,isRightSidebar);
                    else updateSidebarDefaultRightPos();
                }

                if(fillPenStarted)
                {
                    toolBox.checkFillPenIconBottom();
                }

                updatePreviewBoxRectPos();

                if(fileDragSelectBox.visible === true)
                {
                    setDragDropSelectBoxCenterPos();
                }

                checkfofoPos();
                updateWindowBorder(stw,sth);

                _lastWindowSize.x = windowW;
                _lastWindowSize.y = windowH;
            });
        }

        private function setZoomCanvas(z:Number,replayMode:Boolean = false):void
        {
            const fz:Number = Math.floor(z*100+0.5)/100;
            var xReg:Sprite;

            updateRCursorScale(fz);

            if(!replayMode)
            {
                xReg = regPoint;
                zoomed = fz;
                if(!captureModeON) penCursorPosition.updateZoom(fz);
                if(airBrushSizeDrawMode > 0) setBlurCanvasBySizeDrawMode(airBrushSizeDrawMode);
            }
            else
            {
                rzoomed = fz;
                xReg = rregPoint;
                if(airBrushSizeReplayMode > 0) setBlurCanvasBySizeReplayMode(airBrushSizeReplayMode);
            }

            if(z < 0.1) z = 0.1;
            xReg.scaleX = z;
            xReg.scaleY = z;

            if(captureModeON && captureFlipped)
            {
                xReg.scaleX = -xReg.scaleX;
            }

            if(!captureModeON)
            {
                appInfoBox.setZoom(z);
            }
        }

        private function windowClosingEvent(e:Event):void
        {
            windowClosingFlag = true;

            if(replayStartON === true) stopReplay();
            if(captureModeON === true) captureOFF();
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
            var offsetTop:Number = STAGE_TOP_OFFSET;
            var offsetLeft:Number = STAGE_LEFT_OFFSET;
            var offsetBottom:Number = STAGE_BOTTOM_OFFSET;
            var offsetRight:Number = STAGE_RIGHT_OFFSET;

            const left:Number = ent.x;
            const top:Number = ent.y;
            const right:Number = left+ent.width;
            const bottom:Number = top+ent.height; //info text 사이즈 더해줌
            const xLimit:Number = stage.stageWidth;
            const yLimit:Number = stage.stageHeight;

            if(right > xLimit-offsetRight) ent.x = xLimit-ent.width-offsetRight;
            else if(left < offsetLeft) ent.x = offsetLeft;

            if(top < offsetTop) ent.y = offsetTop;
            else if(bottom > yLimit-offsetBottom) ent.y = (yLimit-offsetBottom)-ent.height;
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
            const floor:Function = Math.floor;
            const scale:Number = getUIScale();
            const center:Point = new Point(0,0);
            var topBarOffset:Number = topBar.BARSIZE*scale;

            if(flag === CENTERPOS_DRAW)
            {
                center.setTo((!isSidebarVisible) ? floor(stage.stageWidth/2)
                             :(isRightSidebar)   ? floor((stage.stageWidth-STAGE_RIGHT_OFFSET)/2)
                                                 : floor(STAGE_LEFT_OFFSET+(stage.stageWidth-STAGE_LEFT_OFFSET)/2)
                            ,floor(topBarOffset+(stage.stageHeight-topBarOffset)/2));
            }
            else if(flag === CENTERPOS_CAPTURE)
            {
                topBarOffset = topBarOffset+14*scale;
                center.setTo(stage.stageWidth/2,floor(topBarOffset+(stage.stageHeight-topBarOffset)/2));
            }
            else if(flag === CENTERPOS_REPLAY)
            {
                topBarOffset = topBarOffset+replayTimeBox.BARSIZE*scale-13;
                center.setTo(stage.stageWidth/2,floor(topBarOffset+(stage.stageHeight-topBarOffset)/2));
            }
            else if(flag === CENTERPOS_DEEPUNDO)
            {
                center.setTo((isSidebarVisible) ? (isRightSidebar) ? floor((stage.stageWidth-STAGE_RIGHT_OFFSET)/2)
                                                                   : floor(STAGE_LEFT_OFFSET+(stage.stageWidth-STAGE_LEFT_OFFSET)/2)
                            :(isRightSidebar)   ? floor((stage.stageWidth-(toolBox.BOX_WIDTH+10)*scale)/2)
                                                : floor((toolBox.BOX_WIDTH+10)*scale+(stage.stageWidth-(toolBox.BOX_WIDTH+10)*scale)/2)
                            ,floor(topBarOffset+(stage.stageHeight-topBarOffset)/2));
            }
            else
            {
                center.setTo(stage.stageWidth/2,stage.stageHeight/2);
            }

            return center;
        }

        private function setCenvasCenterPos(replayMode:Boolean=false,captureMode:Boolean=false):void
        {
            const floor:Function = Math.floor;
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

            if(replayMode) center = getStageCenterPos(CENTERPOS_REPLAY);
            else if(captureMode) center = getStageCenterPos(CENTERPOS_CAPTURE);
            else center = getStageCenterPos(CENTERPOS_DRAW);

            xReg.x = floor(center.x);
            xReg.y = floor(center.y);
            xCanvas.x = floor(-w/2);
            xCanvas.y = floor(-h/2);
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

            startGC();
        }

        //keyfunc
        private function setReplaySpeedByKey(upFlag:Boolean):void
        {
            const clacMax:Number = Math.floor(TOTAL_FRAME/(STAGE_FRAME*3));
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
            topBar.hintTime(finalStr,topBar.replaySpeedSet);

            rSpeed = _rSpeed;
            topBar.setSpeedButtonPosByValue(_rSpeed,max);
            if(playbackFinished === false) updateReplayRemainTimeText();
        }

        private function setReplaySpeedByKeyButton(upFlag:Boolean):void
        {
            setHoldKeyRepeat(setReplaySpeedByKey,upFlag);
        }

        private function keyUpReplayMode(e:KeyboardEvent):void
        {
            checkKeyUp(e.keyCode);
        }

        private function keyDownReplayMode(e:KeyboardEvent):void//keydown2
        {
            const keyCode:uint = keyBuffer[0];

            if(mouseClickON || rightMouseClickON || isNowKey(keyCode)) return;

            var subKey:int;

            if(isPressingControlShift())
            {
                checkCommandSubKey(3,false,function(input:int):void
                {
                    if(input === KEY.s) saveFile(true);
                    else if(input === KEY.o) loadFile(true);
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
                    if(cutFrameClickedButton !== CUT_FRAME_NONE) resetCutFrameClickCounter();
                    else setReplayUIOFF();
                }
                break;

                case KEY.f2:
                    setCutFrameButton(CUT_FRAME_RE_RECORD,true);
                break;

                case KEY.f3:
                    setCutFrameButton(CUT_FRAME_DELETE_FRONT,true);
                break;

                case KEY.f4:
                    setCutFrameButton(CUT_FRAME_SUPER_UNDO,true);
                break;

                case KEY.f5:
                    setZoomInButton(true,true);
                break;

                case KEY.f6:
                    setZoomInButton(false,true);
                break;

                case KEY.f1:
                case KEY.f7:
                    setReplayUIOFF();
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
                else if(keyBuffer.length > 0)
                {
                    keyDownDrawMode(null);
                }
                else
                {
                    if(layerVisibleKeyFuncCalled) layerVisibleKeyFuncCalled = false;

                    if(oldTool > TOOL_NONE) restoreFirstUsedTool();

                    updatePenCursorPosition();
                }
            }

            if(keyBuffer.length === 0)
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
            if(keyBuffer.length === length)
            {
                const subKey:int = keyBuffer[length-1];
                if(saveFlag) setNowKey(subKey);
                func(subKey);
                return true;
            }
            return false;
        }

        private function keyDownDrawMode(e:KeyboardEvent):void
        {
            if(mouseClickON || rightMouseClickON || keyWaitMouseUp || fillPenStarted)
            {
                return;
            }

            const keyCode:uint = keyBuffer[0];

            //자툴이 nowkey를 쓰기 때문에 nowkey 리턴 이전에서 체크해야함
            if(isPressingControlShift())
            {
                //shift 누르고 ctrl 순서로 누를때 이전툴로 복원
                if(isNowTool(TOOL_LINE)) restoreFirstUsedTool();

                checkCommandSubKey(3,true,function(input:int):void
                {
                    if(input === KEY.s) saveFile(true);
                    else if(input === KEY.o) loadFile(true);
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
                        if(clipImageON) setClipButton();
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
                if(checkOpaSizeKeyDown((keyBuffer.length >= 2) ? keyBuffer[1] : keyCode))
                {
                    return;
                }
                else if(checkMoreOptionsKeyDown(keyBuffer[1]))
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
                                if(regPoint.rotation !== 0.0) resetRotationDrawMode();
                            return;

                            case KEY.w:
                            case KEY.i:
                                if(zoomed !== 1.0) resetZoomDrawMode();
                            return;

                            case KEY.d:
                            case KEY.j:
                            {
                                setLayerSwapButton();
                                setToolTipTempON("Layers has been swapped");
                            }
                            return;

                            case KEY.e:
                            case KEY.o:
                                if(controlBox.layerMergeButton.alpha === 1.0)
                                {
                                    setLayerMergeButton();
                                    setToolTipTempON("Layers has been merged to layer 2");
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

            if(keyBuffer.length >= 2)
            {
                //지우개키 조합 따로 체크
                if(keyCode === KEY.d || keyCode === KEY.j)
                {
                    if(checkOpaSizeKeyDown(keyBuffer[1]))
                    {
                        return;
                    }
                    else if(keyBuffer[1] === KEY.s || keyBuffer[1] === KEY.k)
                    {
                        if(quickSidebarON === false) setQuickSidebarON(true);
                        return;
                    }
                    else if(checkMoreOptionsKeyDown(keyBuffer[1]))
                    {
                        return;
                    }

                }
                else if(keyCode === KEY.s || keyCode === KEY.k)
                {
                    if(keyBuffer[1] === KEY.d || keyBuffer[1] === KEY.j)
                    {
                        if(quickSidebarON === false) setQuickSidebarON(true);
                        return;
                    }
                }
                //필펜 조합 체크
                else if(keyCode === KEY.q || keyCode === KEY.o)
                {
                    if(checkOpaSizeKeyDown(keyBuffer[1]))
                    {
                        return;
                    }
                    else if(checkMoreOptionsKeyDown(keyBuffer[1]))
                    {
                        return;
                    }
                }

                //레이어 따로 보기 조합 체크
                if(layerVisibleKeyFuncCalled === false)
                {
                    if(keyCode === KEY.w || keyCode === KEY.i)
                    {
                        if(keyBuffer[1] === KEY.n1 || keyBuffer[1] === KEY.n9)
                        {
                            layerVisibleKeyFuncCalled = true;
                            selectSubLayer(false,false);
                            setLayer1CheckToggle();

                            if(oldTool > TOOL_NONE) restoreFirstUsedTool();
                            return;
                        }
                        else if(keyBuffer[1] === KEY.n2 || keyBuffer[1] === KEY.n0)
                        {
                            layerVisibleKeyFuncCalled = true;
                            selectSubLayer(true,false);
                            setLayer2CheckToggle();

                            if(oldTool > TOOL_NONE) restoreFirstUsedTool();
                            return;
                        }
                    }
                    else if(keyCode === KEY.n1 || keyCode === KEY.n9)
                    {
                        if(keyBuffer[1] === KEY.w || keyBuffer[1] === KEY.i)
                        {
                            layerVisibleKeyFuncCalled = true;

                            selectSubLayer(false,false);
                            setLayer1CheckToggle();
                            return;
                        }
                    }
                    else if(keyCode === KEY.n2 || keyCode === KEY.n0)
                    {
                        if(keyBuffer[1] === KEY.w || keyBuffer[1] === KEY.i)
                        {
                            layerVisibleKeyFuncCalled = true;
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
                    setReplayUION();
                }
                return true;

                case KEY.f2:
                case KEY.f8:
                {
                    setGridButton();
                    topBar.hintTimeOFF();
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
                    topBar.hintTimeOFF();
                }
                return true;

                case KEY.f5:
                {
                    setUIScaleButton(++uiScaleIndex);
                    topBar.hint("UI Scale "+getUIScaleString(uiScaleIndex),topBar.dpiButton);
                    topBar.hintTimeOFF();
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
                    selectSubLayer(false,false);
                    if(controlBox.layer2CheckButton.visible)
                    {
                        setLayer2CheckToggle();
                    }

                    setSingleLayerPreview(1,true);
                    setToolTipTempON("Layer 1 selected");
                }
                return true;

                case KEY.n2:
                case KEY.n0:
                {
                    selectSubLayer(true,false);
                    if(controlBox.layer1CheckButton.visible)
                    {
                        setLayer1CheckToggle();
                    }
                    setSingleLayerPreview(2,true);
                    setToolTipTempON("Layer 2 selected");
                }
                return true;

                case KEY.n3:
                case KEY.n8:
                {
                    setSharpLineButtonShortcut();
                }
                return true;

                case KEY.n4:
                case KEY.n7:
                {
                    if(isPenOrLineTool() || isNowTool(TOOL_FILL_PEN))
                    {
                        setPenAirBrushButtonShortCut();
                    }
                    else if(isEraseTool())
                    {
                        setEraseAirBrushButtonShortCut();
                    }
                }
                return true;

                case KEY.x:
                case KEY.comma:
                    setRedoButton(true,false);
                return true;

                case KEY.z:
                case KEY.dot:
                    setUndoButton(true,false);
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
                    if(!isNowTool(TOOL_SPUIT))
                    {
                        updateOldTool();
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
                    if(traceMenuON)
                    {
                        closeTraceMenu();
                    }
                    else if(topBar.clearButton.alpha === 1.0)
                    {
                        setClearData(true);
                    }
                }
                break;
            }
            updatePenCursorPosition();
        }

        private function checkClipBoardImage():void
        {
            const bmpd:Object = Clipboard.generalClipboard.getData(ClipboardFormats.BITMAP_FORMAT);

            if(bmpd as BitmapData)
            {
                topBar["clipButton"].alpha = 1.0;
                traceMenu["traceClipButton"].alpha = 1.0;
                clipImageON = true;
            }
            else
            {
                const offAlpha:Number = BUTTON_OFF_ALPHA;
                topBar["clipButton"].alpha = offAlpha;
                traceMenu["traceClipButton"].alpha = offAlpha;
                clipImageON = false;
            }
        }

        private function setClickBlockFlagOFFDelay():void
        {
            addTimerByName("clickBlockTimer",0.15,false,function():void
            {
                clickBlockFlag = false;
            });
        }

        private function windowActiveEvent(e:Event):void
        {
            //알탭해주고 창 활성화 해줄때 한번은 안하게끔함
            realWorkingTimer.start();
            checkClipBoardImage();

            if(aboutPanelON)
            {
                clickBlockFlag = true;
            }
            else
            {
                setClickBlockFlagOFFDelay();
            }
        }

        private function windowDeactiveEvent(e:Event):void
        {
            clickBlockFlag = true;
            resizeCanvas.exit(true);
            realWorkingTimer.stop();
            resetKeyBuffer();
            cancelAutoKeyEvent(null);

            if(toolBox2ON)
            {
                rightMouseClickON = false;
                closeToolBox2();
            }

            if(!isSidebarVisible) penCursorPosition.setSideBarOFF();

            if(topBarHintClickEventON)
            {
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,topBarHintOFFEvent);
                topBarHintClickEventON = false;
                topBar.hintOFF();
            }

            if(appResetFlag === false)
            {
                const nowTime:int = getTimer();
                const subTime:int = nowTime-windowDeactivateTime;

                if(subTime >= 1000 || windowClosingFlag)
                {
                    windowDeactivateTime = nowTime;
                    saveAllData();
                }
            }

            if(quickSidebarON && !deepUndoON) _quickSidebarOFF();
            if(subLayerPreviewON) setSingleLayerPreviewOFF();

            restoreFirstUsedTool();
        }

        private function updateToolBoxMousePos(target:SimpleButton):void
        {
            //아이콘 중앙으로 맞추어줌
            if(!target) return;
            if(target.parent as Sprite === toolBox2)
            {
                toolBoxLastClickPos.x = -(target.x+target.width/2)*toolBox2.scaleX;//*scale;
                toolBoxLastClickPos.y = -(target.y+target.height/2)*toolBox2.scaleX;//*scale;
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
                    setCanvasResizeButton(targetName,false);
                break;

                default:
                {
                    if(toolBox2.visible && isHitTestPoint(toolBox2))
                    {
                        updateToolBoxMousePos(toolBox2.toolPen);
                        updateOldTool();
                        handTool();
                        closeToolBox2();
                    }
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
                        oldTool = nowTool;
                    }
                    spuitTool();
                }
                break;
                case "toolUndo":
                {
                    setUndoButton(false);
                }
                break;
                case "toolRedo":
                {
                    setRedoButton(false);
                }
                break;
                case "toolMirror":
                    mirrorCanvas();
                break;

                case "toolTrace":
                    openTraceWindow();
                break;
            }

            closeToolBox2();
        }

        private function setLasso1PxMoveButton(command:int):void
        {
            const m:Number = 1/zoomed;
            const rotate:Number = regPoint.rotation;
            var x:Number = 0;
            var y:Number = 0;

            if(command === LASSO_1PX_MOVE_UP) y = -1;
            else if(command === LASSO_1PX_MOVE_DOWN) y = 1;
            else if(command === LASSO_1PX_MOVE_LEFT) x = -1;
            else if(command === LASSO_1PX_MOVE_RIGHT) x = 1;

            const r:Point = rotatePoint(x,y,rotate);

            lassoBox.x += r.x;
            lassoBox.y += r.y;
        }

        private function setSideBarScrollMove(clickY:Number):void
        {
            const floor:Function = Math.floor;
            const scale:Number = getUIScale();
            const sth:Number = stage.stageHeight;
            const canMoveHeight:Number = (sth-STAGE_TOP_OFFSET)-scrollBarHeight*scale;
            const diffHeight:Number = sideBarSetHeight*scale-(sth-STAGE_TOP_OFFSET);
            const factor:Number = (diffHeight/canMoveHeight);
            var scrollStarted:Boolean = false;
            var my1:Number = sideBarScrollBar.y;
            var my2:Number = sideBarScrollSet.y;
            const yLimit:Number = Math.ceil(sideBar.h-sideBarScrollBar.height-STAGE_BOTTOM_OFFSET/scale);

            mouseDragON = true;

            function sideBarMouseUpEvent(e:MouseEvent):void
            {
                mouseDragON = false;
                scrollSetMovedY = sideBarScrollSet.y;
                scrollBarMovedY = sideBarScrollBar.y;

                stageMouseMoveEvent.remove("sideBarMouseMoveEvent");
                stage.removeEventListener(MouseEvent.MOUSE_UP,sideBarMouseUpEvent);
            }

            function sideBarMouseMoveEvent(e:MouseEvent):void
            {
                const subY:Number = (clickY-mouseY)/scale;

                my1 = my1-subY;
                my2 = my2+subY*factor;

                if(my1 < 0)
                {
                    my1 = 0;
                    my2 = 0;
                }
                else if(my1 > yLimit)
                {
                    my1 = yLimit;
                    my2 = -diffHeight/scale;
                }

                sideBarScrollBar.y = floor(my1);
                sideBarScrollSet.y = floor(my2);

                clickY = mouseY;
            }

            clickY = clickY;
            stageMouseMoveEvent.add("sideBarMouseMoveEvent",sideBarMouseMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,sideBarMouseUpEvent);
        }

        private function checkToolBoxButtons(target:DisplayObject):Boolean
        {
            if(!isNowKey(0) && !quickSidebarON || !target) return true;

            if(lassoToolON === false)
            {
                stage.addEventListener(MouseEvent.MOUSE_UP,checkToolBoxButtonUpEvent);
            }

            const targetName:String = target.name;

            switch(targetName)
            {
                case "toolRotate":
                {
                    rotateTool(false);
                }
                break;

                case "toolUndo":
                {
                    setUndoButton(true);
                }
                break;

                case "toolRedo":
                {
                    setRedoButton(true);
                }
                break;

                case "zoomInButton":
                case "zoomOutButton":
                {
                    toolBoxClickedTarget = targetName;
                    setTopChildIndex(toolBox);
                }
                return true;

                case "toolPen":
                case "toolFillPen":
                case "toolErase":
                case "toolLasso":
                case "toolSpuit":
                case "toolUndo":
                case "toolRedo":
                case "toolMirror":
                case "toolLine":
                case "toolMove":
                case "toolZoom":
                case "toolRotate":
                case "toolTrace":
                case "toolBoxBG":
                case "toolMask":
                {
                    setTopChildIndex(toolBox);
                    toolBoxClickedTarget = targetName;
                }
                return true;
            }
            return false;
        }

        private function setCanvasResizeButton(targetName:String,shortcut:Boolean):void
        {
            penCursorOFFFlag = true;
            toolTipBox.visible = true;
            penSizeCursor.visible = false;
            setToolTipON(CANVAS_WIDTH+" x "+CANVAS_HEIGHT);
            setResizeCanvas(targetName,shortcut);
        }

        private function checkReplaySpeedState():void
        {
            const floor:Function = Math.floor;
            const totalFrame:Number = TOTAL_FRAME;
            const rf:Number = rNowFrame;
            const bw:Number = replayTimeBox["replayTotalBar"].width;

            if(totalFrame < STAGE_FRAME*3) topBar["replaySpeedSet"].alpha = BUTTON_OFF_ALPHA;
            else topBar["replaySpeedSet"].alpha = 1.0;
            //리플레이 속도를 최고 빠르게 했을때 시간 체크
            REPLAY_FASTEST_TOTAL_TIME = floor(totalFrame/(REPLAY_MAX_SPEED*STAGE_FRAME));

            replayTimeBox["frameInfo"].text = rf+" / "+totalFrame;
            replayTimeBox["replayNowBar"].width = (totalFrame === 0) ? 0 : bw*(rf/totalFrame);
        }

        private function resetKeyBuffer():void
        {
            keyBuffer = [];
            resetNowKey();
        }

        private function updateRCursorScale(zoom:Number):void
        {
            const z:Number = 1/zoom;
            rCursor.scaleX = z;
            rCursor.scaleY = z;
        }

        private function setFillpenUI(flag:Boolean):void
        {
            if(flag)
            {
                if(!sideBar.visible) sideBar.setTempVisibleON(toolBox.BOX_WIDTH+10,isRightSidebar);
                toolBox.fillPenIconON();
                toolBox.bgBoxVisible(true);
                sideBarScrollBar.visible = false;
                toolBox.checkFillPenIconBottom();
            }
            else
            {
                if(isSidebarVisible === false) sideBar.setTempVisibleOFF(isRightSidebar);

                toolBox.fillPenIconOFF();
                toolBox.checkBottomOFF();
                toolBox.bgBoxVisible(false);
                updateScrollBarHeight(stage.stageHeight);
            }
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
                topBar.hint(STRING_PREPARE_REPLAY_DATA,topBar.saveButton);
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
            const _rregPoint:Sprite = rregPoint;
            const _regPoint:Sprite = regPoint;
            const _rcanvasPanel:Sprite = rcanvasPanel;
            const _canvasPanel:Sprite = canvasPanel;

            zoomed = rzoomed;//줌배율도 공유
            zoomedIndex = rzoomedIndex;
            _regPoint.scaleX = _rregPoint.scaleX;
            _regPoint.scaleY = _rregPoint.scaleY;
            _regPoint.rotation = _rregPoint.rotation;
            _regPoint.x = _rregPoint.x;
            _regPoint.y = _rregPoint.y;
            _rcanvasPanel.x = _rcanvasPanel.x;
            _rcanvasPanel.y = _rcanvasPanel.y;
        }

        private function syncReplayCanvasWithDrawMode():void
        {
            const _rregPoint:Sprite = rregPoint;
            const _regPoint:Sprite = regPoint;
            const _rcanvasPanel:Sprite = rcanvasPanel;
            const _canvasPanel:Sprite = canvasPanel;

            rzoomed = zoomed;//줌배율도 공유
            rzoomedIndex = zoomedIndex;
            _rregPoint.scaleX = _regPoint.scaleX;
            _rregPoint.scaleY = _regPoint.scaleY;
            _rregPoint.rotation = _regPoint.rotation;
            _rregPoint.x = _regPoint.x;
            _rregPoint.y = _regPoint.y;
            _rcanvasPanel.x = _canvasPanel.x;
            _rcanvasPanel.y = _canvasPanel.y;
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
            setColorTransform(replayTimeBox["replayNowBar"],uiColorSet[uiColorIndex][4]);
        }

        private function setReplayUIOFF():void
        {
            if(makeJumpImageFlag === 2) return;
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
            if(toolTipBox.visible) toolTipBoxTimerOFF();
            replayTimeBox["pauseButton"].visible = false;
            setTopChildIndex(replayTimeBox);
            resetCutFrameClickCounter();
            topBar.hintOFF();
            setFitZoomedOFF();
            clearDataButtonCount = 0;
            clearRFrameCacheImages();
            updateStageOffset();

            if(replayStartON === true) stopReplay();

            resetOldTool();
            selectPenTool();
            updatePreviewBoxRectPos();
            changePickerModeToNormal();
            updatePenSizeCursor();
            updatePenCursorPosition();
            changeTopBarIcons("draw");
            appInfoBox.setZoom(zoomed);
            updateRCursorScale(zoomed);

            deepUndoON = deepUndoONSave;

            if(rNowFrame !== deepUndoFrameSave)
            {
                jumpFrame(deepUndoFrameSave,JUMP_FRAME_ONCE);
            }

            rCursor.visible = false;
            addInputEventDrawMode();
        }

        private function setReplayUION():void
        {
            if(makeJumpImageFlag === 2) return;
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
            resetCutFrameClickCounter();
            topBar.hintOFF();
            if(toolTipBox.visible) toolTipBoxTimerOFF();
            rcanvasPanel.addChild(rCursor);
            setRCursorVisibleOFFUndo();
            setTopChildIndex(rCursor);
            updateStageOffset();
            removeTimer("setRCursorVisibleOFFUndoTimer");

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
                    rzoomedIndex = zoomArr.indexOf(rzoomed);
                }
            }

            updateReplayBarPos(stage.stageWidth);
            autoScroll.updateRCanvasBounds();
            updateRCursorScale(rzoomed);
            topBar.resetHintColor();

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

                checkCutFrameButtonsActive();
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
            const targetName:String = target.name;

            if(targetName && (targetName.indexOf("rcanvas") !== -1 || targetName === "stageBG"))
            {
                handTool(true);
                return;
            }

            if(target.alpha < 1.0)
            {
                return;
            }

            switch(targetName)
            {
                case "replayRotateButton":
                {
                    rotateTool(true);
                }
                break;

                case "replaySpeedBarWrapper":
                {
                    setReplaySpeedButton();
                }
                break;

                case "replayNowBar":
                case "replayTotalBar":
                case "frameInfo":
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

                case "loadButton":
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
                case "dragDropFileButton":
                case "dragDropRefButton":
                case "dragDropCancelButton":
                case "playButton":
                case "pauseButton":
                case "replayPrev":
                case "replayNext":
                case "timer":
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

                if(keyBuffer.length > 0)
                {
                    keyDownDrawMode(null);
                }
                else
                {
                    resetNowKey();
                    if(oldTool > TOOL_NONE) restoreFirstUsedTool();
                    updatePenCursorPosition();
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
                rzoomed = zoomArr[rzoomedIndex];
            });
        }

        private function rightMouseDownReplayMode(e:MouseEvent):void
        {
            if(mouseClickON || !isNowKey(0) || !e.target) return;

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

            const mx:Number = mouseX;
            const my:Number = mouseY;
            const _toolBox2:toolButtons2 = toolBox2;
            const floor:Function = Math.floor;

            if(toolBoxLastClickPos.x === 0 && toolBoxLastClickPos.y === 0)
            {
                toolBoxLastClickPos.x = -_toolBox2.width/2;
                toolBoxLastClickPos.y = -_toolBox2.height/2;
            }

            _toolBox2.x = floor(mx+toolBoxLastClickPos.x);//원점에서 마지막으로 클릭한 위치로 옮겨줌
            _toolBox2.y = floor(my+toolBoxLastClickPos.y);
            _toolBox2.visible = true;
            toolBox2ON = true;
            setResizeButtonVisibleTimer(true);
            setTopChildIndex(_toolBox2);
            addInputEventToolBox2();
        }

        private function rightMouseDownDrawMode(e:MouseEvent):void //rdown1
        {
            if(mouseClickON || isPressingControl() || quickSidebarON
            || (traceMenuON && traceMenu.hitTestPoint(mouseX,mouseY)))
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
                case "saveButton": saveFile(true); break;
                case "loadButton": loadFile(true); break;

                case "toolZoom":
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

                case "layer1SelectButton":
                    selectSubLayer(false,canvas11Bitmap.visible);
                    if(controlBox.layer2CheckButton.visible)
                    {
                        setLayer2CheckToggle();
                    }
                break;

                case "layer2SelectButton":
                    selectSubLayer(true,canvas1Bitmap.visible);
                    if(controlBox.layer1CheckButton.visible)
                    {
                        setLayer1CheckToggle();
                    }
                break;

                default:
                {
                    if(fillPenStarted)
                    {
                        fillPenTool.ok();
                    }
                    else if(!isSidebarVisible && sideBar.visible)
                    {
                        if(!(targetName === "colorHistoryBox" || targetName === "colorHistoryBoxBG"))
                        {
                            penCursorPosition.setSideBarOFF();
                            penCursorPosition.setSidebarONDelay();
                        }
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

            setTopChildIndex(controlBox);

            switch(targetName)
            {
                case "penSmoothSlider":
                case "penSmoothButton":
                {
                    if(nowTool > 4) return true;
                    setPenSmoothButton();
                }
                return true;

                case "alphaButton0":
                case "alphaButton1":
                case "alphaButton2":
                case "alphaButton3":
                case "alphaButton4":
                case "alphaButton5":
                case "alphaButton6":
                case "alphaButton7":
                case "alphaButton8":
                case "alphaButton9":
                {
                    setAlphaButton(targetName);
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
                }
                return true;

                case "shapeRect":
                {
                    setPenShapeButton(true);
                }
                return true;

                case "shapeCircle":
                {
                    setPenShapeButton(false);
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
                    selectSubLayer(false,false);
                    if(controlBox.layer2CheckButton.visible)
                    {
                        setLayer2CheckToggle();
                    }
                }
                return true;

                case "layer2SelectButton":
                {
                    selectSubLayer(true,false);
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
                    setSharpLineButton(!sharpLineON);
                }
                return true;

                case "airBrushButtonWrapper":
                case "airBrushOFFButton":
                case "airBrushONButton":
                case "airBrushText":
                {
                    if(controlBox.airBrushButtonWrapper.alpha === 1.0)
                    {
                        if(isPenOrLineTool() || isNowTool(TOOL_FILL_PEN))
                        {
                            setPenAirBrushButton(!airBrushON);
                        }
                        else if(isEraseTool())
                        {
                            setEraseAirBrushButton(!eraseAirBrushON);
                        }
                    }
                }
                return true;
            }

            return false;
        }

        private function checkPickerBoxButtons(target:DisplayObject):void
        {
            const nt:int = nowTool;

            if(toolBox2ON || (!isNowKey(0)
                             && nt !== TOOL_FILL_PEN
                             && nt !== TOOL_LINE
                             && nt !== TOOL_PEN
                             && nt !== TOOL_ERASE))
            {
                return;
            }

            const targetName:String = target.name;

            colorHistoryUpdateReady = false;

            if(targetName && targetName.indexOf("drawr") !== -1)
            {
                setPresetColor(target as Sprite,(pickerMode == 2) ? true : false);
                return;
            }

            switch(targetName)
            {
                case "penColorButton":
                {
                    if(pickerMode !== 1)
                    {
                        changePickerModeToNormal();
                    }
                }
                return;

                case "paperColorButton":
                {
                    if(pickerMode !== 2)
                    {
                        changePickerModeToBG();
                    }
                }
                return;

                case "svBox":
                case "svCursor":
                {
                    setSVcolorButton();
                }
                return;
                case "hueColor":
                case "hueCursor":
                {
                    setHueColorButton();
                }
                return;

                case "colorHistoryBox":
                case "colorHistoryBoxBG":
                {
                    selectHistoryColor();
                }
                return;

                case "currentColor":
                {
                    setCurrentColor(pickerMode);
                }
                return;

                case "tegaki0":
                case "tegaki1":
                case "tegaki2":
                case "tegaki3":
                case "tegaki4":
                {
                    setTegakiPresetColor(targetName);
                }
                return;
            }
        }

        private function rightMouseUpLassoTool(e:MouseEvent):void
        {
            if(!lassoToolON || mouseClickON)
            {
                return;
            }

            const target:DisplayObject = e.target as DisplayObject;
            const targetName:String = target.name;

            if(lassoMenu.hitTestPoint(mouseX,mouseY) === false || targetName === "lassoOK")
            {
                setLassoOKButton();
                return;
            }

            switch(targetName)
            {
                case "lassoCZoom":
                {
                    if(zoomed !== 1.0) resetZoomDrawMode(lassoBox.localToGlobal(new Point(0,0)));
                }
                break;

                case "lassoCRotate":
                {
                    if(regPoint.rotation !== 0) resetRotationDrawMode();
                }
                break;

                case "lassoRotate":
                {
                    if(lassoBox.rotation !== 0) lassoBox.rotation = 0;
                }
                break;

                case "lassoResize":
                {
                    if(lassoBox.scaleY !== 1.0)
                    {
                        lassoBox.scaleX = (lassoMirrorON) ? -1.0 : 1.0;
                        lassoBox.scaleY = 1.0;
                    }
                }
                break;

                default:
                break;
            }
        }

        private function mouseUpLassoTool(e:MouseEvent):void
        {
            if(keyBuffer.length === 1 && keyBuffer[0] === KEY.space)
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
            const targetName:String = target.name;

            if(isCursorInDrawArea() && isHitTestPoint(lassoMenu) === false)
            {
                if(lassoMenuTempOFF)
                {
                    lassoMenu.visible = false;
                    if(isNowTool(TOOL_HAND)) handTool();
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

                    case "lassoInfo":
                    case "lassoMenuMoveButton":
                    {
                        setTopChildIndex(lassoMenu);
                        moveToolBoxByType(1);
                    }
                    break;

                    case "lassoCRotate":
                    {
                        lassoMenu.visible = false;
                        lassoMenuTempOFF = true;
                        rotateTool(false);
                    }
                    break;

                    case "lassoCZoom":
                    {
                        lassoMenu.visible = false;
                        lassoMenuTempOFF = true;
                        zoomTool();
                    }
                    break;

                    case "lassoCHand":
                    {
                        lassoMenu.visible = false;
                        lassoMenuTempOFF = true;
                        handTool(false);
                    }
                    break;

                    case "lassoMirror":
                    {
                        lassoMirrorON = !lassoMirrorON;
                        lassoBox.scaleX = -lassoBox.scaleX;

                        //캔버스가 회전한각도도 있어서 항상 세로축을 중심으로 대칭되게 regpoint각도를 보정값으로 넣어줌
                        lassoBox.rotation = -lassoBox.rotation-(regPoint.rotation*2);
                    }
                    break;

                    case "lasso1pxUp": setLasso1PxMoveButton(LASSO_1PX_MOVE_UP); break;
                    case "lasso1pxDown": setLasso1PxMoveButton(LASSO_1PX_MOVE_DOWN); break;
                    case "lasso1pxLeft": setLasso1PxMoveButton(LASSO_1PX_MOVE_LEFT); break;
                    case "lasso1pxRight": setLasso1PxMoveButton(LASSO_1PX_MOVE_RIGHT); break;
                    case "lassoCopy": setLassoCopyButton(); break;

                    case "lassoOK":
                    case "lassoCancel":
                    case "lassoTrace":
                        checkButtonUp(targetName);
                    break;
                }
            }

        }

        private function mouseDownDrawMode(e:MouseEvent):void
        {
            if(fillPenStarted) return;

            const target:DisplayObject = e.target as DisplayObject;

            if(!target) return;

            const targetName:String = target.name;

            if(sideBar.visible && isHitTestPoint(sideBarScrollSet,true))
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
                else if(checkControlBoxButtons(target) && (isPenOrLineTool() || isEraseTool()))
                {
                    return;
                }
                else if(toolBox.alpha === 1.0 && target.alpha === 1.0 && checkToolBoxButtons(target))
                {
                    return;
                }
            }

            if(quickSidebarON)
            {
                if(targetName === "sideBarScrollBar")
                {
                    setSideBarScrollMove(mouseY);
                }
                return;
            }

            switch (targetName)
            {
                case "saveButton": //아래 3개는 topbar메뉴에 가면 안됨 mouseuphandler랑 같이 연동되서 여기서 해주어야함
                case "repSaveButton":
                case "loadButton":
                case "repLoadButton":
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
                case "dragDropFileButton":
                case "dragDropRefButton":
                case "dragDropCancelButton":
                case "timer":
                case "traceCancelButton":
                case "traceImageButton":
                case "traceLoadButton":
                case "traceClipButton":
                case "traceMirrorButton":
                case "traceDeleteButton":
                case "traceVisibleONButton":
                case "traceVisibleOFFButton":
                case "appResetButton":
                case "dpiButton":
                case "newWindowButton":
                case "newWindowCloseButton":
                {
                    if(toolBox2ON || !isNowKey(0) || e.target.alpha < 1.0)
                        return;

                    checkButtonUp(targetName);
                }
                return;

                case "penSmoothSlider":
                case "penSmoothButton":
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
                    setCanvasResizeButton(targetName,true);
                }
                return;

                case "sideBarScrollBar":
                    setSideBarScrollMove(mouseY);
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

                case "traceInfo":
                case "traceMenuMoveButton":
                {
                    moveToolBoxByType(2);
                }
                return;

                case "dragDropFileBG":
                return;

                return;
            }

            //캔버스 영역 밖에서는 해주지 않음
            if(isCursorInDrawArea() && !clickBlockFlag)
            {
                switch (nowTool)
                {
                    case TOOL_FILL_PEN: if(isCurrentLayerActive() && isToolActive()) fillPenTool.start(); break;
                    case TOOL_PEN: if(isCurrentLayerActive() && isToolActive()) penTool(true); break;
                    case TOOL_ERASE: if(isCurrentLayerActive() && isToolActive()) penTool(false); break;
                    case TOOL_LINE: if(isCurrentLayerActive() && isToolActive()) lineTool(true); break;
                    case TOOL_LASSO: if(isCurrentLayerActive()) lassoTool(); break;
                    case TOOL_MOVE: if(isCurrentLayerActive()) moveTool(); break;
                    //캔버스 조작
                    case TOOL_ZOOM: zoomTool(); break;
                    case TOOL_HAND: handTool(); break;
                    case TOOL_ROTATE: rotateTool(false); break;
                }
            }
        }

        // private var printdeepLevel:int = 0;
        // private function printArray(obj:Object,deepKey:String=""):void
        // {
        //     var blank:String="";
        //     if(printdeepLevel === 0) trace('--- PRINT START --- ');
        //     else
        //     {
        //         const count:int = printdeepLevel;
        //         for(var b:int=0; b<count; b++)
        //         {
        //             blank += "   ";
        //         }
        //         trace(blank+'> index['+deepKey+']');
        //     }

        //     trace(blank+'{');
        //     for(var i:String in obj)
        //     {
        //         if(obj[i] !== null && typeof obj[i] === "object" && obj[i].length > 0)
        //         {
        //             ++printdeepLevel;
        //             printArray(obj[i],i);
        //         }
        //         else
        //         {
        //             trace(blank+'| '+i+' : ' + obj[i]);
        //         }
        //     }
        //     trace(blank+'}');
        //     --printdeepLevel;
        //     if(printdeepLevel < 0) printdeepLevel = 0;
        // }
    }
 }
