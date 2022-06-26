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
    import flash.display.PNGEncoderOptions;
    import flash.filesystem.File;
    import flash.filesystem.FileStream;
    import flash.filesystem.FileMode;
    import flash.system.Capabilities;
    import flash.system.System;
    import flash.system.IME;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.ColorTransform;
    import flash.geom.Rectangle;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;
    import flash.events.NativeDragEvent;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import flash.utils.ByteArray;
    import flash.utils.getTimer;
    import flash.utils.setInterval;
    import flash.utils.clearInterval;
    import flash.net.URLRequest;
    import flash.net.FileFilter;
    import flash.net.URLLoader;
    import flash.net.navigateToURL;
    import flash.net.URLLoaderDataFormat;
    import flash.text.TextField;
    import flash.ui.Mouse;
    import flash.filters.BlurFilter;
    import flash.filters.ConvolutionFilter;//import end

    public class main extends Sprite
    {   
        private const APP_VERSION:Number = 14.87;
        private var NEW_VERSION:String = APP_VERSION+"";
        private var UPDATE_FILE:File = File.applicationStorageDirectory.resolvePath("updateTmpFile.air");

        //단축키 keycode 리스트
        private const STAGE_FRAME:int = stage.frameRate;
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
                                        // f9:120,
                                        // f10:121,
                                        // f11:122,
                                        // f12:123
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

                    ,CANVAS_MIN_SIZE:int = 100
                    ,CANVAS_MAX_SIZE:int = 2000

                    ,COLOR_DARK:uint = 0x323232//어두운색
                    ,COLOR_MID_DARK:uint = 0x535353//0x5B5B5B//중간 어두운색
                    ,COLOR_MID_BRIGHT:uint = 0xB8B8B8//중간 밝은색
                    ,COLOR_BRIGHT:uint = 0xF0F0F0//0xECEAE7//밝은색

                    ,GC_TIME_OUT:int = 30
                    ,BUTTON_OFF_ALPHA:Number = 0.15

                    ,REPLAY_FASTEST_LIMIT_TIME:Number = 60
                    ,IMG_CACHE_INTERVAL:uint = 10000
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
                    ,COMMAND_CTRL:int = (1 << 0)
                    ,COMMAND_SHIFT:int = (1 << 1)
                    ,COMMAND_CTRL_SHIFT:int = (1 << 2)
                    ,KEY_REPEAT_DELAY:Number = 300
                    ,KEY_REPEAT_INTERVAL:Number = 60
                    ,LASSO_1PX_MOVE_UP:int= (1 << 0)
                    ,LASSO_1PX_MOVE_DOWN:int = (1 << 1)
                    ,LASSO_1PX_MOVE_LEFT:int = (1 << 2)
                    ,LASSO_1PX_MOVE_RIGHT:int = (1 << 3)
                    ,CUT_FRAME_NONE:int = (1 << 0)
                    ,CUT_FRAME_SUPER_UNDO:int = (1 << 1)
                    ,CUT_FRAME_RE_RECORD:int = (1 << 2)
                    ,CUT_FRAME_DELETE_FRONT:int = (1 << 3)
                    ;

        private var  RESIZE_BUTTON_COLOR:uint = 0xA5A5A5
                    ,STAGE_BG_COLOR:uint = 0xCCCCCC
                    ,CANVAS_BG_COLOR:uint = 0xFFFFFF
                    ,RCANVAS_BG_COLOR:uint = 0xFFFFFF
                    ,CANVAS_WIDTH:Number = 600
                    ,CANVAS_HEIGHT:Number = 390
                    ,RCANVAS_WIDTH:Number = 600
                    ,RCANVAS_HEIGHT:Number = 390
                    ,APP_RUNNING_TIME:Number = 0 //앱 실행시간
                    ,STAGE_TOP_OFFSET:Number = 0 //창 상하좌우 여백
                    ,STAGE_LEFT_OFFSET:Number = 0
                    ,STAGE_BOTTOM_OFFSET:Number = 0
                    ,STAGE_RIGHT_OFFSET:Number = 0
                    ,CANVAS_TRACE_ALPHA:Number = 0.5
                    ,TOTAL_FRAME:Number = 0//rdata+file 프레임 전부 합친거
                    ,REPLAY_FASTEST_TOTAL_TIME:Number = 0 //최고 배속으로 돌렸는데도 총 재생시간이 60초 이상이면 올려줌
                    ,REPLAY_SLOWDRAW_ACTIVE_SPEED:Number = 50 //이 배속 이상일경우 doDrawSlowEvent를 걸어줌

        //element
        private const canvas1Bitmap:Bitmap = new Bitmap(canvas1BitmapData,"auto",true)
                    ,canvas2Bitmap:Bitmap = new Bitmap(canvas2BitmapData,"auto",true)
                    ,resizeButtonR:canvasResizeButton = new canvasResizeButton()//캔버스 리사이즈 하는 버튼
                    ,resizeButtonD:canvasResizeButton = new canvasResizeButton()
                    ,resizeButtonL:canvasResizeButton = new canvasResizeButton()
                    ,resizeButtonU:canvasResizeButton = new canvasResizeButton()
                    ,regPoint:Sprite = new Sprite()//회전 스프라이트 부모
                    ,canvasPanel:Sprite = new Sprite()//회색 부분을 제외한 그리기 영역 추가       
                    ,canvas1:Sprite = new Sprite() //캔버스 1번 레이어 1
                    ,canvas2:Sprite = new Sprite() //캔버스 2번 임시로 그려주는 캔버스 버퍼?
                    ,canvas2Draw:Shape = new Shape() //실제로 선을 긋는 div
                    ,canvasPanelMask:Shape = new Shape() //캔버스 마스크
                    ,lassoBox:Sprite = new Sprite()//선택한 이미지를 그려주고 확대 축소등 조작
                    ,penSizePrev:Shape = new Shape() //캔버스 마스크
                    ,penSizePrevCenter:Shape = new Shape() //캔버스 마스크
                    ,penSizeCursor:Shape = new Shape() //펜사이즈 미리 보기
                    ,reiszePreviewRect:Sprite = new Sprite()//캔버스 크기조절 미리보기 그려줌
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
                    ,sideBarScrollBar:Sprite = new Sprite()
                    ,sideBarScrollSet:Sprite = new Sprite()
                    ,transBGBMPD:BitmapData = new BitmapData(16,16,false,0xFFFFFF)

        private var  canvas1BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,canvas2BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,lassoBMP:Bitmap = new Bitmap()
                    ,appResetFlag:Boolean = false
                    ,rMirrorON:Boolean = false //대칭 켜지면 올려줌
                    ,mirrorON:Boolean = false //대칭 켜지면 올려줌
                    ,mirrorPushReady:Boolean = false//undo redo하고 있는데 미러가 달라서 mirror draw가 실행 되고 난후에 올려줌
                    ,zoomArr:Array = [0.25,0.5,0.75,1.0,2.0,3.0,4.0,6.0,8.0,12.0,16.0,24.0,32.0]
                    ,zoomed:Number = 1.0
                    ,zoomedIndex:int = 3
                    ,rzoomedIndex:int = 3
                    ,mouseClickON:Boolean = false //클릭하면 올려줌
                    ,rightMouseClickON:Boolean = false //클릭하면 올려줌
                    ,clickBlockFlag:Boolean = false //알탭 하고나서 창활성화 되면 일정시간동안 작동하지 않게함
                    ,clickBlockTimer:int = 0 //비활성에서 활성화 될때 약간의 텀을주는 타이머
                    ,mouseDragON:Boolean = false//툴을 계속 클릭한채로 움직이면 topmenu의 힌트가 안켜지도록 함
                    ,nowTool:int = 1 //현재 툴 번호
                    ,oldTool:int = TOOL_NONE //툴백업
                    ,keyBuffer:Array = [] //정식 키 다운 눌러준 상태에서 다른 키가 눌러져 있으면 여기다가 저장
                    ,nowKey:uint = 0 //단축키 누른거 여기다가 저장
                    ,nowKeyNotKeyUp:int = 0 //keyup에서 체크 안하는 단축키는 여기다가 저장
                    ,keyWaitMouseUp:Boolean = false //키 떼기 전에 마우스 먼저 떼주었을때 플래그 올려줌
                    ,penAlpha:Number = 1.0 //펜 변수
                    ,penColor:uint = 0x000000
                    ,sizeOffsetFlag:Boolean = false//0.5픽셀 이동이면 true임 pensizecursormove함수에서 써줌
                    ,sizeArr:Array = [0,1,2,3,4,5,7,10,13,18,30,45,80]
                    ,alphaArr:Array = [0.25,0.5,0.7,1.0]
                    ,penSize:uint = 3
                    ,penSizeIndex:uint = 3
                    ,penAlphaIndex:uint = 3
                    ,penShape:Boolean = false //false 이면 원 true 이면 사각형
                    ,penSmoothValue:Number = 0 //펜 손떨방 플래그
                    ,penSmoothSlideValue:int = 0 //펜 손떨방 플래그
                    ,penSmoothSlideTotal:Number = 20 //손떨방 총 단계
                    ,penSmoothButtonX:Number = 70 //손떨방 조절 버튼 초기 위치
                    ,pixelSnapON:Boolean = false //0.5픽셀어긋나게 안하고 완전히 정확하게 할때씀
                    ,fillPenON:Boolean = false //채우기 펜 플래그
                    ,subLayerON:Boolean = false
                    ,airBrushON:Boolean = false
                    ,airBrushSizeDrawMode:Number = 0
                    ,airBrushSizeReplayMode:Number = 0
                    ,fillPenStarted:Boolean = false //채우기 펜 시작됨
                    ,eraseOddOffset:Number = 0//지우개 변수
                    ,eraseSize:uint = 12
                    ,eraseSizeIndex:uint = 8
                    ,eraseShape:Boolean = false
                    ,eraseAlpha:Number = 1.0
                    ,eraseAlphaIndex:uint = 3
                    ,eraseAirBrushON:Boolean = false
                    ,penListShapeFlag:Boolean = false //펜 리스트에서 펜 모양 버튼 눌러줄때 툴이랑 상관없이 바꿔줌, 펜 미리보기 할때 필요
                    ,penLastUpdateInfo:Array = [null,null,null,null,null,null] //updatePenSizeCursor 중복 사용 방지를 위해서 마지막 크기 저장해놓고 같으면 건너뙴
                    ,addUndoMode:int = 0 //addundo했을때 캔버스 이동 리사이즈, 배경색 변경 등 중복되는거 체크하는것임.
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
                    ,toolBox2ResizeButtonTimer:int = 0 //툴박스 켜주고 나서 약간 딜레이를 주는 타이머
        //undo 관련변수
                    ,undoIndex:int = 0 //undo redo할때 무슨 이미지인지 알려주는 undoImageData의 포인터 인덱스임
                    ,undoDelFlag:Boolean = false //undo하고 나서 addundo가 되었을때 뒷부분 데이터 전부 날려주는 플래그
                    ,readyAddUndo:Boolean = false //선을 그어줄대 선전체가 캔버스 바깥쪽에 있을수도 있으니까 이걸 판단해줌
                    ,clearButtonClicked:Boolean = false//clear button 여러번 누르기 금지 플래그
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
        //window resize 관련 변수
                    ,lastWindowSize:Point = new Point() //창크기 조절 얼마나 됐을지 비교할때 마지막 크기 창크기 저장
        //save load 관련 변수
                    ,saveOneTime:Boolean = false //세이브 버튼 여러번 눌러서 데이터 계속 쓰여지는거 방지
                    ,saveFileName:String = getTimeStampTailHead()+" "+getRandomString()+".png"//세이브 파일 저장후에 이름을 이쪽에다가 보관해서 계속 그 이름으로 저장할수있게함
                    ,saveFilePath:String = saveFileName//파일 저장경로로 계속 저장 초기에는 filename이랑 똑같게 해줌
                    ,saveContinue:Boolean = false//한번 저장후에 다른이름으로 저장하기 전까지는 똑같은 이름으로 저장
                    ,clearDataButtonCount:uint = 0 //리플레이 취소 카운터

        //컬러 히스토리 관련 변수
                    ,colorHistoryList:Array = [0xFFFFFF,0x000000]
                    ,colorHistoryLimit:uint = 10
                    ,colorHistoryColorWidth:uint = 17//Math.floor(pickerBox.svBoxWidth/colorHistoryLimit)//히스토리 개별 색깔 가로 크기
                    ,colorHistoryRectH:uint = 19
                    ,colorHistoryUpdateReady:Boolean = false //히스토리 업데이트 이벤트 추가되면 올려주는거
                    ,colorHistoryUpdateBGReady:Boolean = false //히스토리 업데이트 이벤트 추가되면 올려주는거

        //툴팁 관련 변수
                    ,toolTipHint:String = "" //topbar관련 힌트 여기 저장
                    ,toolTipBoxTimer:uint = 0

        //리플레이 관련 변수
        private const appDataFile:File = File.applicationStorageDirectory.resolvePath("appdata1481")
                    ,undoDataFile:File = File.applicationStorageDirectory.resolvePath("undodata1481")
                    ,repFile:File = File.applicationStorageDirectory.resolvePath("repdata")
                    ,repFileTemp:File = File.applicationStorageDirectory.resolvePath("repdatatmp") //파일을 저장하거나 불러올때 씀
                    ,rJumpImageFolder:File = File.applicationStorageDirectory.resolvePath("imagecache")
                    ,rJumpImageFrameDataFile:File = File.applicationStorageDirectory.resolvePath("jumpframedata")
                    ,rFirstImageFile:File = rJumpImageFolder.resolvePath("0")
                    ,rFileStream:FileStream = new FileStream()//함수들을 왔다갔다 해야해서 전역으로 하나 ,
                    ,rregPoint:Sprite = new Sprite()//회전 스프라이트 부모
                    ,rcanvasPanel:Sprite = new Sprite()
                    ,rcanvas1:Sprite = new Sprite()
                    ,rcanvas2:Sprite = new Sprite()
                    ,rcanvas2Draw:Shape = new Shape()
                    ,rcanvasPanelMask:Shape = new Shape()
                    ,replayTimeBox:replayTimeBar = new replayTimeBar()
                    ,rcanvas1Bitmap:Bitmap = new Bitmap(rcanvas1BitmapData,"auto",true)
                    ,rcanvas2Bitmap:Bitmap = new Bitmap(rcanvas2BitmapData,"auto",true)
                    ,rCursor:SimpleButton = new tinyCursor(); //재생할때 틀어주는 작은 마우스

        private var rcanvas1BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,rcanvas2BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,replayStartON:Boolean = false //리플레이 시작버튼 여러번 누르는거 방지
                    ,replayAllEnd:Boolean = true //리플레이가 자연히 끝났을때 올렽주는 플래그 가장 처음에 캔버스 싹쓸이 하기 위해서 넣어줌.
                    ,replayEndWithcanvasFitWindow:Boolean = false //리플레이가 follow cursor옵션으로 캔버스 작게 축소되서 끝났을때
                    ,replayModeON:Boolean = false //이건 모드 자체 껐다 켰다

                    ,rDataBufferBackup:Array = []
                    ,rDataBuffer:Array = []
                    ,rData:Array = [] //rDataBuffer가 이쪽으로 이동되고 undo image data갯수에 똑같이맞추어줌
                    ,rDataFrame:Array = [] //rdata안에 몇프레임이 들어있는지 저장

        //아래 변수들은 전역으로 돌려야, 플레이 중간에 끊어도 계속 플레이 시킬 수 있음.
                    ,rLastBytes:Number = 0 //fs position 저장
                    ,rFileCutBytes:Number = 0 //super undo에서 파일 잘라줄때 필요함
                    ,rIndex:uint = 0 //rData에서만씀 rData 스크로크 뭉치 인덱스
                    ,rSubLayerSave:Boolean = false //리플레이 실행할때 이걸로 비교해서 캔버스 스왑해줌
                    ,rBGColorSave:uint = RCANVAS_BG_COLOR //load replay에서 씀
                    ,rDataReadFlag:Boolean = false //rData에서 frameArr한번만 등록해주는 플래그
                    ,rSpeed:Number = 1 //리플레이 속도 for루프로 2번씩혹은 3번씩 읽히게 만듬
                    
                    // ,rFileTotalFrame:Number = 0 //file에저장된 프레임수 누적해서 저장
                    ,rNowFrame:Number = 0 //dodraw에서 현재까지 플레이된 프레임수 누적, jump frame이 가동됐을때 프레임 누적갯수를 세서 썸네일 이미지 만들어줌
                    ,rPrevFrame:Number = 0 //jump one frame 에서 이전 프레임 탐색할때 이 프레임으로 탐색해줌 tickdraw에서 data 끝의 프레임을 저장함
                    ,rFirstImage:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,rFirstBGColor:uint = CANVAS_BG_COLOR
                    ,rzoomed:Number = 1.0 //리플레이 줌
                    ,rJumpImageIndexSave:int = -2 //썸네일 인덱스 바뀌면 여기다 저장
                    ,rJumpImageFrameData:Array = [0] //스킵이미지 저장될때 r file frame sum을 저장해줌 처음에 rfirstimage라서 0번 추가해줌
                    ,makeJumpImageFlag:int = 0 //0이상이면 make jump image함수를 실행함. jumpframe함수에서 체크
                    ,makeSKipImageWaitTimer:int = 0 //jump image 함수 중복 실행 방지
                    ,rOnejumpFlagSave:Boolean = false //onejumpframe에서 prev인지 next인지 마지막 상태 저장해줌, 방향바꿀대 버튼 2번씩 눌러야 스킵되는거 방지하는거임
                    ,keyHoldTimer:int = 0 //키 오래 누르고 있으면 한꺼번에 처리해주는 타이머
                    ,rOneJumpPrevSum:Number = 0 //뒤로 스킵키 오래누르고 있으면 프레임 합산은 여기다가 올려줌
                    ,replayONUndoUpdate:Boolean = true//undo가 된 상태에서 리플레이 켜줄때 file까지만 읽은 상태까지 프레임 스킵 해주는
                    ,rRestartTimer:uint = 0 //리스타트 타이머
                    ,rRestartTimerCount:uint = 0 //리스타트 타이머
                    ,rFrameTextDelayTime:int = 0 //프레임 바 딜레이

                    ,rCanvasBounds:Object = null
                    
                    ,doDrawSlowEventON:Boolean = false //doDrawSlowEvent가 켜지면 올려줌
                    ,rJumpMouseON:Boolean = false //스킵프레임 마우스로 할때 올려줌 dodraw에서 바조절 안되게 하려고 하는거임
                    ,rDataPreviewCacheImages:Array = [] //이전 탐색 프레임 빠르게 하기 위해서 jumpimage구간에서 더 잘게 이미지를 나누어주고 정보를여가다가 저장함
                    ,rSpeedLastStr:String = ""

        //about 관련 변수
                    ,aboutPanelON:Boolean = false //어바웃 창 떴을때 킴
                    ,needUpdate:int = 0 //새버전 나왔을때 올려주는 플래그
                    ,updateRryTimer:uint = 0
                    ,isCheckingUpdate:Boolean = false

        //cut Frame 관련 변수
                    ,cutFrameActiveButton:SimpleButton
                    ,cutFrameClickCounter:uint = 0 //1번 누르면 미리 보기, 2번 누르면 실행
                    ,cutFrameClickedButton:int = CUT_FRAME_NONE //무슨 버튼 눌렀는지 저장
                    ,rCutDataSaveFrame:Number = 0//슈퍼언도나 앞짜르기 할때 마우스 왔다갔다 하면서 반복해서 눌러줄때 jumponeframe이 계속작동되는거 방지해줌 

        //스크린샷 관련 변수
                    ,captureModeON:Boolean = false //스크린샷 켜지면 올려줌
                    ,browseWindowON:Boolean = false //캡쳐 저장키 빠르게 누를때 에러 떠서 중복안되게 플래그 세워줌
                    ,capturePanelData:Object = {}
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
                    ,canvasTraceBitmapDataRaw:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)//원본 참고레이어 데이터
                    ,canvasTraceBitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0) //리사이즈등 수정된 데이터
                    ,canvasTraceBitmap:Bitmap = new Bitmap()
                    ,traceImageFile:File = File.applicationStorageDirectory.resolvePath("traceImg")
                    ,traceMenuBox:traceButtons = new traceButtons()
                    ,traceReizeMoveSum:Number = 0 //전역으로 돌려서 다시 클릭하거나 이미지를 불러와도 원래 스케일을 저장하도록함
                    ,tracePosInfo:Array = [0,0,0,1.0,1.0,false] // width, height, rotation,scale 미러 플래그
                    ,traceMenuON:Boolean = false //trace메뉴 켜졌을때 올려줌
                    ,traceRawBMPD:BitmapData = null
                    ,traceRawArr:Array = null
                    ,traceImageCount:int = 0 //2번이상 클릭하면 되게
                    ,traceMemoryTraining:Boolean = false // 이거 켜지면 캔버스 그릴때 임시적으로 안보이게함
                    ,traceLastAlpha:Number = 0

        //그리드 레이어 변수 
                    ,canvasGrid:Sprite = new Sprite()//트레이스 레이어임
                    ,gridFlag:uint = 0

        //closure
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
                    ,tickDraw:Object = cTickDraw()
                    ,doDraw:Function = cDoDraw()
                    ,checkAutoScroll:Object = cAutoScroll()
                    ,updatePenSizeCursor:Function = cUpdatePenSizeCursor()
                    ,undoData:Object = cAddUndoData()
                    ,addUndoData:Function = undoData.add
                    ,penCursorPosition:Object = cUpdatePenCursorPosition()
                    ,updatePenCursorPosition:Function = penCursorPosition.check
                    ,checkMainDrawTool:Function = cCheckMainDrawTool()
                    ,drawCaptureArea:Object = cDrawCaptureArea()
                    ,stageMouseMoveEvent:Object = cStageMouseMoveEvent()
                    ,replayHideCursor:Object = cCheckHideCursor()
                    ,checkHideCursorCount:Function = replayHideCursor.check
                    ,resizeCanvas:Object = cSetCanvasSize()
                    ,setCanvasSize:Function = resizeCanvas.start

        //스크롤바 변수
                    ,scrollSetMovedY:Number = 0
                    ,scrollBarMovedY:Number = 0
                    ,scrollBarHeight:Number = 0
                    ,sideBarSetHeight:Number = 730
        //ui 색깔 변수
                    ,uiColorIndex:int = 1
                    ,uiColorSet:Array = [       //주 컬러,        주컬러 반대색, stage배경색, 캔버스 조절 막대 색, 리플레이 완료 막대 색
                                                [COLOR_DARK,      0xE5E5E5,      0x4B4B4B,    0x676767,            0x74AC74], 
                                                [COLOR_MID_DARK,  COLOR_BRIGHT,  0x888888,    RESIZE_BUTTON_COLOR, 0xA1CE9D],
                                                [COLOR_MID_BRIGHT,0x505050,      0xC9C9C9,    0xB0B0B0,            0xB6DAAF],
                                                [COLOR_BRIGHT,    0x505050,      0xE1E1E1,    0xCBCBCB,            0xCEE5C5],
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
        //기타
                    ,windowClosingFlag:Boolean = false//윈도우 닫힐때 올려줌 save all data가 windows closing일때는 무조건 해주게 끔함
                    ,windowDeactivateTime:int = 0 //윈도우 비활성화된 시간 저장, 너무 자주 알탭해서 save all data가 자주 호출되는걸 막음
                    ,penCursorOFFFlag:Boolean = false //펜커서 이게 on되면 안보여줌
                    ,tempDragDropFile:Object = []
                    ,tempCopiedImage:BitmapData
                    ,penSizePrevOFFTimer:int = 0
                    ,eraseMovedButton:SimpleButton = null //툴 선택해줬을때 지우개툴이 이동한 툴을 저장해줌 다시원래대로 복원해주려고
                    
                    ,zoomToolHintON:Boolean = false //툴박스에서 마우스 클릭해서 줌툴써줄때 mouse out이벤트가 가장 늦게 되서 줌 배율 힌트가 처음에 보이지 않는거 해결
                    ,controlBoxHintTimer:uint = 0 //컨트롤 박스 힌트 타이머 스무딩 힌트 일시적으로 보여줄때 사용
                    ,updateManualTimer:int = 0
                    ,isRightSidebar:Boolean = false // 사이드바 위치 0이 왼쩾 1이 오른쪽
                    ,isSidebarVisible:Boolean = true
                    ,windowResizeDelayTimer:int = 0
                    ,windowMoveDelayTimer:int = 0
                    ,topBarHintClickEventON:Boolean = false //톱바 힌트가 켜졌을때 클릭하면 지워주는 이벤트
                    ,afkONCount:int = 0
                    ,gcONCount:int = 0
                    ,workingTimer:int = 0
                    ,isDeepUndoON:Boolean = false
                    ,isDeepUndoONDelayTime:int = 0 //오른쪽 컨트롤키가 계속 눌리는 증상 있어서 타이머로 일정시간 동안 동작 안하게 락걸기
                    ,sideBarONMouseLeaveTimer:int = 0 //마우스 클릭후 바깥으로 나갔을때 사이드바 잠깐 안켜주는 플래그
                    ,isNewFOFOSaveForamat:Boolean = false
                    ;
        //vars
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
            updateWindowTitle();
            setWindowTitleStar();
            setStageProperties();
            makeCanvasFamily();
            makeReplayCanvasFamily();
            makeMenuFamlity();
            makeResizeButtonFamily();
            makeTransBG();
            updateWindowSizeInfo();
            updateColorHistoryList();
            loadAppData(); //이전 세팅 복원
            resetReplayDataFile();
            initPickerBoxInfo(penColor);
            addStageInputEvent();
            addInputEventStageChild();
            addInputEventDrawMode();
            lastWindowSize = new Point(stage.nativeWindow.width,stage.nativeWindow.height);
            setCenvasCenterPos();
            setCenvasCenterPos(true);
            previewBox.updateImage(canvas1BitmapData,CANVAS_BG_COLOR);
            startWorkingTimer();
            stageMouseMoveEvent.start();
            checkVersion();
            setIMEDisabled();
            selectPenTool();
        }
        
        //functions
        private function updateCanvasPanelMask(w:Number,h:Number):void
        {
            const maskg:Graphics = canvasPanelMask.graphics;
            maskg.clear();
            maskg.beginFill(0xFF00FF);
            maskg.drawRect(0,0,w,h);
            maskg.endFill();
        }

        private function isHitTestPoint(obj:DisplayObject,flag:Boolean=false):Boolean
        {
            return obj.hitTestPoint(mouseX,mouseY,flag) as Boolean;
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
                if(dotLineColor === 0) dotLineColor = 0xFFFFFF;
                else dotLineColor = 0;

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
                else g.lineTo(x,y);

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
                return pos.x !== mouseX || pos.y !== mouseY
                    || mouseClickON || rightMouseClickON;
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
                    else count++;

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

        private function isNowKey(key:int):Boolean
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
            if(oldTool === TOOL_NONE) oldTool = nowTool;
        }

        private function setHoldKeyRepeat(func:Function,...args):Boolean
        {
            if(keyHoldTimer !== 0) return false;
            
            function callFunc(args:Array):void
            {
                const len:int = args.length;
                if(len === 0) func();
                else if(len === 1) func(args[0]);
                else if(len === 2) func(args[0],args[1]);
            }

            keyHoldTimer = 0;
            if(keyHoldTimer === 0)
            {
                //오래누르고 있으면 enter frame으로 계속 발동 앞으로 가기만
                clearTimeout(keyHoldTimer);
                keyHoldTimer = setTimeout(function():void
                {
                    keyHoldTimer = setInterval(function():void
                    {
                        callFunc(args);
                    },KEY_REPEAT_INTERVAL);
                },KEY_REPEAT_DELAY);
                addCancelAutoKeyEvent();
            };

            callFunc(args);
            return true;
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
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,rightMouseUpLassoTool);
            addInputEventDrawMode();
        }

        private function addMouseKeyEventLassoTool():void
        {
            stage.addEventListener(KeyboardEvent.KEY_UP,keyUpLassoTool);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownLassoTool);
            stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownLassoTool);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,rightMouseUpLassoTool);
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

        private function exitDeepUndoMode():void
        {
            setDeepUndoUI(false);
        }

        private function cStageMouseMoveEvent():Object
        {
            const arr:Vector.<Function> = new Vector.<Function>();
            var lastTime:int = 0;
            var sumTime:int = 0;
            var nowTime:int = 0;
            var subTime:int = 0;

            //mosue move 이벤트 일정 시간 이내는 무시함
            function moveEventLimit():Boolean
            {
                nowTime = getTimer();
                subTime = nowTime-lastTime;
                sumTime += subTime;

                if(sumTime === 0) return true;
                else sumTime = 0;

                lastTime = nowTime;
                return false;
            }

            function add(func:Function):void
            {
                const _arr:Vector.<Function> = arr;
                if(_arr.lastIndexOf(func) === -1) _arr.push(func);
            }

            function remove(func:Function):void
            {
                const _arr:Vector.<Function> = arr;

                for(var i:int= _arr.length-1; i>=0; i--)
                {
                    if((_arr[i] as Function) === func) _arr.removeAt(i);
                }
            }

            function event(e:MouseEvent):void
            {
                if(moveEventLimit() === true) return;

                const _arr:Vector.<Function> = arr;

                for(var i:int = _arr.length-1; i>=0; i--)
                {
                    (_arr[i] as Function)(e);
                }
            }

            function start():void
            {
                //전역 마우스 move 이벤트
                stage.addEventListener(MouseEvent.MOUSE_MOVE,event);
            }

            return {
                start:start,
                remove:remove,
                add:add
            }
        }

        private function mouseLeaveSideBarON():void
        {
            if(replayModeON || captureModeON || sideBarONMouseLeaveTimer > 0)
            {
                return;
            }

            if(!isSidebarVisible && !sideBar.visible)
            {
                const mx:Number = mouseX;

                if((isRightSidebar && mx > stage.stageWidth-sideBar.w)
                || (!isRightSidebar && mx < sideBar.w))
                {
                    penCursorPosition.checkSideBarON();
                }
            }
        }

        private function setWindowTitleStar():void
        {
            if(stage.nativeWindow.title.lastIndexOf("*") === -1)
            {
                stage.nativeWindow.title = stage.nativeWindow.title+"*";
            }
        }

        private function resetApp():void
        {
            appResetFlag = true;
            
            const files:File = File.applicationStorageDirectory;
            files.deleteDirectory(true);
        }

        private function setSidebarVisible(flag:Boolean,tempFlag:Boolean):void
        {
            if(tempFlag === false) isSidebarVisible = flag;

            const tb:topMenu = topBar;

            if(flag)
            {
                if(tempFlag === false)
                {
                    tb.sideBarPositionButton.alpha = 1.0;
                    tb.sideBarPositionButton2.alpha = 1.0;
                }

                if(isRightSidebar)
                    STAGE_RIGHT_OFFSET = sideBar.w;
                else
                    STAGE_LEFT_OFFSET = sideBar.w;

                sideBar.visible = true;
            }
            else
            {
                // sideBar.visible = false;
                sideBar.setTempVisibleOFF(isRightSidebar);

                STAGE_RIGHT_OFFSET = 0;
                STAGE_LEFT_OFFSET = 0;

                tb.sideBarPositionButton.alpha = BUTTON_OFF_ALPHA;
                tb.sideBarPositionButton2.alpha = BUTTON_OFF_ALPHA;
            }

            if(tempFlag === false)
            {
                tb.checkSideBarONOFFButton(flag,isRightSidebar);
            }
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
                setHSVCursorPosByColor(hexColor);
                updateColorHistoryList();
                rDataBuffer.push(["bgColor",hexColor]);
                addUndoData(3);
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
            rDataBuffer.push(["bgColor",arr[1]]);
            addUndoData(3);

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
            isNewFOFOSaveForamat = false;
            fs.open(file,FileMode.READ);

            const header:String = fs.readUTFBytes(9);
            if(header === "FOFOPAINT")
            {
                isNewFOFOSaveForamat = true;
                fs.close();
                return true;
            }
            fs.close();
            fs.open(file,FileMode.READ);
            try
            {
                fs.readObject() as Array;
                fs.close();
                return true;
            }
            catch(err:Error)
            {
                fs.close();
                topBar.hintTimeError("Failed to load file");
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
            
            var clickedButton:String;
            var command:Vector.<int>;
            var data:Vector.<Number>;
            var xColor:uint;
            var xAlpha:Number;
            var xBlendMode:String;
            var commandUndoIndexArr:Array;
            var timer:int;
            var mouseMoved:Boolean;
            var mouseMoveCount:int;
            var afterKeyUpOK:Boolean;
            var _pixelSnap:Boolean;
            var rotateFlag:Boolean;
            var xOffset:Number;

            function _checkUndoReady():void
            {
                if(readyAddUndo === false)
                {
                    if(isHitTestPoint(canvas1Bitmap))
                    {
                        clearButtonClicked = false;
                        readyAddUndo = true;
                    }
                }
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
                if(len < 6) return;
                
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
                timer = 0;
                fillPenStarted = false;
                setFillpenUI(false);
                command.length = 0;
                data.length = 0;
                commandUndoIndexArr.length = 0;
                cd.graphics.clear();

                if(traceMenuON) traceMenuBox.visible = true;
            }

            function endFillPenOK():void
            {
                if(command.length > 2)
                {
                    command.push(2);
                    data.push(data[0]);
                    data.push(data[1]); //마지막으로 원점으로 선을 한번 이어줘야 깔끔하게 닫힘
                    canvas2.alpha = xAlpha;
                    rDataBuffer.push(["fill",xColor,xAlpha,xBlendMode,command.concat(),data.concat()]);
                    drawFillPenData();
                    drawDone();
                }

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

            function keyUpFillPen(e:KeyboardEvent):void
            {
                const keyCode:int = e.keyCode;
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

            function fillPenMouseMoveEvent(e:MouseEvent):void
            {
                if(readyAddUndo === false) _checkUndoReady();
                mouseMoved = true;

                var cdx:Number = cd.mouseX;
                var cdy:Number = cd.mouseY;

                if(_pixelSnap && rotateFlag === false)
                {
                    cdx = floor(cdx-xOffset)+xOffset;
                    cdy = floor(cdy-xOffset)+xOffset;
                }
                else
                {
                    cdx = floor(cdx*1000)/1000;
                    cdy = floor(cdy*1000)/1000;
                }

                if(command.length === 0)
                {
                    command.push(1);
                    data.push(cdx);
                    data.push(cdy);
                }
                else
                {
                    command.push(2);
                    data.push(cdx);
                    data.push(cdy);
                }
                mouseMoveCount++;
                if(mouseMoveCount > 50)
                {
                    mouseMoveCount = 0;
                    commandUndoIndexArr.push(command.length-1);
                }

                if(timer === 0)
                {
                    timer = setTimeout(function():void
                    {
                        timer = 0;
                        drawPreviewLine();
                    },KEY_REPEAT_INTERVAL);
                }
            }

            function mouseDownFillPen(e:MouseEvent):void
            {
                const targetName:String = e.target.name;
                const mx:Number = mouseX;
                const my:Number = mouseY;

                if(targetName === "fillPenOK"
                || targetName === "fillPenUndo"
                || targetName === "fillPenCancel")
                {
                    clickedButton = targetName;
                }
                else if(isCursorInDrawArea())
                {
                    stageMouseMoveEvent.add(fillPenMouseMoveEvent);
                    clickedButton = null;

                    var cdx:Number = cd.mouseX;
                    var cdy:Number = cd.mouseY;

                    if(_pixelSnap && rotateFlag === false)
                    {
                        cdx = floor(cdx-xOffset)+xOffset;
                        cdy = floor(cdy-xOffset)+xOffset;
                    }
                    else
                    {
                        cdx = floor(cdx*100)/100;
                        cdy = floor(cdy*100)/100;
                    }

                    if(command.length === 0)
                    {
                        command.push(1);
                        data.push(cdx);
                        data.push(cdy);
                    }
                    else
                    {
                        command.push(2);
                        data.push(cdx);
                        data.push(cdy);
                    }

                    clearTimeout(timer);
                    drawPreviewLine();
                    mouseDragON = true;

                    if(readyAddUndo === false) _checkUndoReady();
                }
            }

            function mouseupFillPen(e:MouseEvent):void
            {
                clearTimeout(timer);
                timer = 0;
                mouseMoveCount = 0;
                mouseDragON = false;
                mouseClickON = false;
                stageMouseMoveEvent.remove(fillPenMouseMoveEvent);

                const targetName:String = e.target.name;

                if(clickedButton === targetName)
                {
                    if(targetName === "fillPenOK")endFillPenOK();
                    else if(targetName === "fillPenCancel")cancelFillPen();
                    else if(targetName === "fillPenUndo")undoData();
                }
                else
                {
                    commandUndoIndexArr.push(command.length-1);

                    if(afterKeyUpOK) endFillPenOK();
                    else if(mouseMoved) drawPreviewLine();
                }

                afterKeyUpOK = false;
                mouseMoved = false;
            }

            
            function removeEvents():void
            {
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownFillPen);
                stage.removeEventListener(MouseEvent.MOUSE_UP,mouseupFillPen);
                stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpFillPen);
                stageMouseMoveEvent.remove(fillPenMouseMoveEvent);
            }

            function addEvents():void
            {
                stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownFillPen);
                stage.addEventListener(MouseEvent.MOUSE_UP,mouseupFillPen);
                stage.addEventListener(KeyboardEvent.KEY_UP,keyUpFillPen);
                stageMouseMoveEvent.add(fillPenMouseMoveEvent);
            }

            function start():void
            {
                fillPenStarted = true;

                command = new Vector.<int>();
                data = new Vector.<Number>();

                timer = 0;
                mouseMoved = false;
                mouseMoveCount = 0;
                afterKeyUpOK = false;
                clickedButton = null;
                _pixelSnap = pixelSnapON;
                rotateFlag = (regPoint.rotation % 90 === 0) ? false : true;
                xOffset = (sizeOffsetFlag) ? 0.5 : 0;

                xColor = penColor;
                xAlpha = penAlpha;
                xBlendMode = (xColor === CANVAS_BG_COLOR) ? "erase" : null;
                commandUndoIndexArr = [0];

                if(traceMenuON) traceMenuBox.visible = false;
                _dottedLine.updateScale(zoomed);

                command.push(1);
                data.push(cd.mouseX);
                data.push(cd.mouseY);

                setFillpenUI(true);
                if(readyAddUndo === false) _checkUndoReady();
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
            const click:Point = new Point(0,0); //점찍어 줄 때 판단하는 클릭한 자리 저장
            const smoothPos:Point = new Point(0,0);
            const smoothLast:Point = new Point(0,0);
            const pixelSnapLast:Point = new Point(0,0);
            const moveEventLast:Point = new Point(0,0);
            const moveEventLast2:Point = new Point(0,0);
            const sqPenCursorLast:Point = new Point(0,0);
            const penCommand:Vector.<int> = new Vector.<int>(); //그냥펜
            const penPoints:Vector.<Number> = new Vector.<Number>(); //그냥펜 좌표

            var _pixelSnap:Boolean;
            var penToolFlag:Boolean;
            var xSize:uint;
            var xColor:uint;
            var xAlpha:Number;
            var xShape:Boolean;
            var xBlendMode:String;
            var _airBrushON:Boolean;
            var rotateFlag:Boolean;
            var _traceMemoryTraining:Boolean;
            var xOffset:Number;
            var _penSmoothValue:Number;//펜 스무딩 플래그
            var _penSmoothSlideValue:int;
            var mouseMoveCount:uint; //마우스 이벤트에서 움직일때 올려주는 카운터 한번에 너무 많이 움직여주면 cpu부하 먹어서 100카운트 마다 bmp에 그려줌
            var mouseMovedFlag:Boolean;
            var penSmoothTimer:int; //펜 스무딩 할때 커서가 움직이지 않을때 나머지 그려지지않은 점들 이어주는 타이머임
            var distLimit:Number;//penmove에서 distlimit이하이면 jump해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌
            var shortDistFlag:Boolean; //확대 많이 하고 살짝 움직였을때 penmove에서 아예 처리를 안하는데 이걸 dot으로 처리하게 해줌
            var subLayerFlag:Boolean;
            
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
                    cdg.lineStyle(size, color);
                }
                else
                {
                    cdg.lineStyle(size, color, 1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
                }
            }


            function penMoveSmooth():void
            {
                var ox:Number = smoothPos.x;
                var oy:Number = smoothPos.y;
                const abs:Function = Math.abs;
                const smoothing:Number = _penSmoothValue;

                ox += (smoothLast.x-ox)*smoothing;
                oy += (smoothLast.y-oy)*smoothing;

                penMove2(ox,oy);

                if(floor(abs(smoothLast.x-ox)*100) > 0 || floor(abs(smoothLast.y-oy)*100) > 0)
                {
                    smoothPos.setTo(ox,oy);

                    clearTimeout(penSmoothTimer);
                    penSmoothTimer = setTimeout(penMoveSmooth, 10);
                }
            }

            function penMove2(x:Number,y:Number):void
            {
                if(readyAddUndo === false) checkUndoReady();

                if(!_pixelSnap && (_penSmoothSlideValue > 0 || rotateFlag))
                {
                    x = floor(x*100)/100;
                    y = floor(y*100)/100;
                }
                else
                {
                    x = floor(x-xOffset)+xOffset;
                    y = floor(y-xOffset)+xOffset;
                }

                if(!mouseMovedFlag) //움직이기 시작할때 linestyle이랑 moveto넣어줌
                {
                    mouseMovedFlag = true;

                    lineStyleReady(xShape,xSize,xColor,xAlpha);
                    rDataBuffer.push(["lineStyle",xShape,xSize,xColor,xAlpha,smoothPos.x,smoothPos.y,xBlendMode,false,subLayerFlag,_airBrushON]); //cx cy 처음 클릭한 지점으로 지정해줘야함
                    penCommand.push(1);
                    penPoints.push(smoothPos.x);
                    penPoints.push(smoothPos.y);

                    cdg.moveTo(smoothPos.x,smoothPos.y);
                }

                if(x === pixelSnapLast.x &&  y === pixelSnapLast.y)
                {
                    return;
                }
                else
                {
                    pixelSnapLast.x = x;
                    pixelSnapLast.y = y;
                } 

                cdg.lineTo(x,y);
                rDataBuffer.push(["lineTo",x,y]);
                penCommand.push(2);
                penPoints.push(x);
                penPoints.push(y);

                
                if(pixelSnapON === true && _penSmoothSlideValue === 0 && rotateFlag == false)
                {
                    checkPixelPerfect();
                }

                 //이 카운터 마다 다시 캔버스 2에 그려줌 길게 그을수록 cpu처리가 많아짐
                if(mouseMoveCount++ >= 100)
                {
                    if(_airBrushON && zoomed !== 1.0)
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
                    penCommand.length = 0;
                    penPoints.length = 0;
                    lineStyleReady(xShape,xSize,xColor,xAlpha);

                    rDataBuffer.push(["tempDone"]);
                    rDataBuffer.push(["lineStyle",xShape,xSize,xColor,xAlpha,x,y,xBlendMode,false,subLayerFlag,_airBrushON]);

                    penCommand.push(1);
                    penPoints.push(x);
                    penPoints.push(y);

                    cdg.moveTo(x,y);
                    mouseMoveCount = 0;
                }
                
                if(xShape === true)
                {
                    const rad:Number = Math.atan2(x-sqPenCursorLast.x,y-sqPenCursorLast.y);
                    const deg:Number = -rad*(180/Math.PI)+regPoint.rotation;
                    penSizeCursor.rotation = deg;
                    sqPenCursorLast.x = x;
                    sqPenCursorLast.y = y;
                }
            }

            function mouseMovePenTool(e:MouseEvent):void
            {
                const move:Point = new Point(cd.mouseX+xOffset,cd.mouseY+xOffset);
                const fx:Number = floor(move.x-xOffset)+xOffset;
                const fy:Number = floor(move.y-xOffset)+xOffset;

                // fx fy 반올림한 값이 브러시 크기 이하로 움직였을경우 플래그 올려줘서
                // mouse up에서 처리함
                if(fx === moveEventLast2.x && fy === moveEventLast2.y)
                {
                    shortDistFlag = true;
                    return;
                }

                moveEventLast2.setTo(fx,fy);

                const dist:Number = Point.distance(move,moveEventLast);

                //브러쉬 크기 제한보다 작게 움직였을때 무시함
                if(dist < distLimit)
                {
                    shortDistFlag = true;
                    distLimit = distLimit-dist;

                    if(distLimit <= 0) distLimit = xSize/5;
                    return;
                }

                distLimit = distLimit-dist;
                if(distLimit <= 0) distLimit = xSize/5;

                moveEventLast.setTo(move.x,move.y);

                if(penToolFlag && _penSmoothSlideValue > 1)
                {
                    var ox:Number = smoothPos.x;
                    var oy:Number = smoothPos.y;
                    
                    if(penSmoothTimer > 0)
                    {
                        ox += (smoothLast.x-smoothPos.x)*_penSmoothValue;
                        oy += (smoothLast.y-smoothPos.y)*_penSmoothValue;
                    }
                    else
                    {
                        //처음에 적당한 거리 움직여줌
                        const mm:Point = movePointAngleDist(smoothPos.x,smoothPos.y,move.x,move.y,1);
                        ox = mm.x;
                        oy = mm.y;
                    }

                    penMove2(ox,oy);
                    smoothPos.setTo(ox,oy);
                    smoothLast.setTo(move.x,move.y);

                    clearTimeout(penSmoothTimer);
                    penSmoothTimer = setTimeout(penMoveSmooth,20);
                }
                else penMove2(move.x,move.y);
            }

            function mouseUpPenTool(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpPenTool);
                stageMouseMoveEvent.remove(mouseMovePenTool);

                const xx:Number = cd.mouseX;
                const yy:Number = cd.mouseY;
                const mx:Number = xx+xOffset;
                const my:Number = yy+xOffset;

                if(penToolFlag && _traceMemoryTraining) canvasTraceLayer.visible = true;
                
                if(_penSmoothSlideValue > 1)
                {
                    clearTimeout(penSmoothTimer);
                    penSmoothTimer = 0;
                }

                if(xShape === true) penSizeCursor.rotation = regPoint.rotation;

                if(_penSmoothSlideValue > 1 && penToolFlag)
                {
                    const sx:Number = ((click.x+xOffset)-smoothPos.x);
                    const sy:Number = ((click.y+xOffset)-smoothPos.y);
                    const dist:Number = Math.sqrt(sx*sx+sy*sy);

                    if(dist < 0.2)
                    {
                        rDataBuffer.push(["dot",xShape,xSize,xColor,xAlpha,smoothPos.x,smoothPos.y,xBlendMode,subLayerFlag,_airBrushON]);
                        drawDot(xShape,xSize,xColor,smoothPos.x,smoothPos.y);
                    }
                }
                else if(mouseMovedFlag === false && ((click.x === xx && click.y === yy) || shortDistFlag))
                {
                    rDataBuffer.push(["dot",xShape,xSize,xColor,xAlpha,mx,my,xBlendMode,subLayerFlag,_airBrushON]);
                    drawDot(xShape,xSize,xColor,mx,my);
                }
                else if((penToolFlag && _penSmoothSlideValue <= 1) || !penToolFlag)
                {
                    if(!mouseMovedFlag)
                    {
                        lineStyleReady(xShape,xSize,xColor,xAlpha);
                        cdg.moveTo(smoothPos.x,smoothPos.y);
                        rDataBuffer.push(["lineStyle",xShape,xSize,xColor,xAlpha,smoothPos.x,smoothPos.y,xBlendMode,false,subLayerFlag,_airBrushON]); //cx cy 처음 클릭한 지점으로 지정해줘야함
                        rDataBuffer.push(["moveTo",mx,my]);
                    }
                    else
                    {
                        cdg.lineTo(mx,my);
                        rDataBuffer.push(["lineTo",mx,my]);
                    }
                }

                drawDone();

                penCommand.length = 0;
                penPoints.length = 0;
            }

            return function (penFlag:Boolean):void
            {
                penToolFlag = penFlag;
                
                if(penFlag)
                {
                    xSize = penSize;
                    xColor = penColor;
                    xAlpha = penAlpha;
                    xShape = penShape;
                    xBlendMode = (xColor === CANVAS_BG_COLOR) ? "erase" : null;
                    _airBrushON = airBrushON;
                }
                else
                {
                    xSize = eraseSize;
                    xColor = CANVAS_BG_COLOR;
                    xAlpha = eraseAlpha;
                    xShape = eraseShape;
                    xBlendMode = "erase";
                    _airBrushON = eraseAirBrushON;
                }

                subLayerFlag = (penFlag) ? subLayerON : false;

                //투명 바탕에 투명색이기 때문에 그냥 리턴해줘도됨
                if(subLayerFlag && xBlendMode === "erase") return;

                _pixelSnap = pixelSnapON;
                rotateFlag = (regPoint.rotation % 90 === 0) ? false : true;
                _traceMemoryTraining = traceMemoryTraining;
                xOffset = (sizeOffsetFlag) ? 0.5 : 0;
                if(penFlag && _traceMemoryTraining) canvasTraceLayer.visible = false;

                _penSmoothValue = penSmoothValue;//펜 스무딩 플래그
                _penSmoothSlideValue = penSmoothSlideValue;

                mouseMoveCount = 0; //마우스 이벤트에서 움직일때 올려주는 카운터 한번에 너무 많이 움직여주면 cpu부하 먹어서 100카운트 마다 bmp에 그려줌
                mouseMovedFlag = false;

                click.setTo(cd.mouseX,cd.mouseY); //점찍어 줄 때 판단하는 클릭한 자리 저장
                smoothPos.setTo(click.x+xOffset,click.y+xOffset);

                if(_penSmoothSlideValue === 0)
                    smoothPos.setTo(floor(smoothPos.x-xOffset)+xOffset,floor(smoothPos.y-xOffset)+xOffset)
                
                smoothLast.setTo(smoothPos.x,smoothPos.y); //penmove할때 마지막x y저장
                pixelSnapLast.setTo(smoothPos.x,smoothPos.y);
                moveEventLast.setTo(smoothPos.x,smoothPos.y);
                moveEventLast2.setTo(smoothPos.x,smoothPos.y);
                sqPenCursorLast.setTo(smoothPos.x,smoothPos.y);

                penSmoothTimer = 0; //펜 스무딩 할때 커서가 움직이지 않을때 나머지 그려지지않은 점들 이어주는 타이머임
                distLimit = xSize/10;//penmove에서 distlimit이하이면 jump해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌
                shortDistFlag = false; //확대 많이 하고 살짝 움직였을때 penmove에서 아예 처리를 안하는데 이걸 dot으로 처리하게 해줌

                if(readyAddUndo === false) checkUndoReady();

                stageMouseMoveEvent.add(mouseMovePenTool);
                stage.addEventListener(MouseEvent.MOUSE_UP,mouseUpPenTool);
            };
        }

        private function stageMouseLeaveEvent(e:Event):void
        {
            mouseClickON = false;
            rightMouseClickON = false;
            mouseDragON = false;
            
            setControlBoxInfoOFF();
            setTopBarHintOFF();
            
            if(resizeCanvas.isCanvasSizeChanging())
            {
                resizeCanvas.exitCanvasResize(true);
            }
            else if(toolBox2ON)
            {
                if(toolBox2.visible === false && isCursorInDrawArea() === false)
                {
                    closeToolBox2();
                }
            }

            mouseLeaveSideBarON();
        }

        private function updatePenCursorPositionEvent(e:MouseEvent):void
        {
            afkONCount = 0;
            if(replayModeON || captureModeON) return;
            updatePenCursorPosition();
        }

        private function cUpdatePenCursorPosition():Object
        {
            const _penSizeCursor:Shape = penSizeCursor;
            const sideBarVisibleOffset:Number = 15;
            const useCursorTool:int = TOOL_LINE;
            const _isPenTool:Boolean = isPenOrLineTool();
            const _isEraseTool:Boolean = isEraseTool();
            var zoomed:Number = 1.0;
            var cursorVisibleOFFSize:Number = 4;
            var cursorSize:Number = 3.0;

            var sidebarONTimer:int;
            var mouseDownEventON:Boolean;
            var sidebarTempOFF:Boolean;
            var visibleMouseUpEventON:Boolean;
            var nt:int;
            const pos:Point = new Point(0,0);
            // var mx:Number;
            // var my:Number;
            var posInStage:Boolean;

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
                if(isDeepUndoON === false)
                {
                    removeSideBarClickEvents();
                    if(isSidebarVisible === false)
                    {
                        setSidebarVisible(false,true);
                    }
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
                clearTimeout(sidebarONTimer);
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
                clearTimeout(sidebarONTimer);
                sidebarONTimer = setTimeout(function():void
                {
                    visibleMouseUpEventON = false;
                    sidebarTempOFF = false;
                    removeSideBarClickEvents();
                },1000);
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
                if(isHitTestPoint(sideBar) === false)
                    setSideBarOFF();
            }

            function checkSideBarON():void
            {
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
                nt = nowTool;
                pos.setTo(mouseX,mouseY);
                posInStage = pos.x >= STAGE_LEFT_OFFSET &&
                             pos.x <= stage.stageWidth-STAGE_RIGHT_OFFSET &&
                             pos.y >= STAGE_TOP_OFFSET &&
                             pos.y <= stage.stageHeight-STAGE_BOTTOM_OFFSET;

                if(nt > useCursorTool || penCursorOFFFlag || !posInStage)//1 2 3 4 펜 지우개 라인툴 라인-지우개툴
                {
                    _penSizeCursor.visible = false;
                }
                else
                {
                    //addundo플래그가 커서가 캔버스 안에 들어올때 해주기 때문에 위치를 계속 갱신해줘야함
                    _penSizeCursor.x = pos.x;
                    _penSizeCursor.y = pos.y;

                    if((cursorSize <= cursorVisibleOFFSize) || isNowTool(TOOL_FILL_PEN)) _penSizeCursor.visible = false;
                    else _penSizeCursor.visible = true;
                }

                if(isSidebarVisible === false && clickBlockFlag === false)
                {
                    if((!isRightSidebar && pos.x <= sideBarVisibleOffset || isRightSidebar && pos.x >= stage.stageWidth-sideBarVisibleOffset)
                    && pos.y > STAGE_TOP_OFFSET)
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
                updateCursorSize:updateCursorSize
            };
        }

        private function startWorkingTimer():void
        {
            clearInterval(workingTimer);

            workingTimer = setInterval(function():void //수동 gc실행
            {
                if(gcONCount === GC_TIME_OUT)
                {
                    gcONCount = 0;
                    System.pauseForGCIfCollectionImminent(0.75);
                    System.gc();
                }
                else gcONCount++;

                if(afkONCount === 2) afkONCount = 3;
                else if(afkONCount < 2)
                {
                    afkONCount++;
                    APP_RUNNING_TIME += 1000;
                    updateWorkingTime();
                }
            },1000);
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


        private function setZoomInButton(flag:Boolean,replayMode:Boolean):void
        {
            const xReg:Sprite = (replayMode) ? rregPoint : regPoint;
            const _zoomArr:Array = zoomArr;
            const zoomMax:int = _zoomArr.length-1;
            const floor:Function = Math.floor;
            const center:Point = getStageCenterPos(false,replayMode);
            var lastZoomIndex:int = (replayMode) ? rzoomedIndex : zoomedIndex;

            if(flag) //줌인 
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
                rzoomedIndex = lastZoomIndex;
                setRegPoint(center.x,center.y,true);
                updateReplayCanvasBounds();
                setZoomCanvas(newZoom,replayMode);
            }
            else
            {
                zoomedIndex = lastZoomIndex;
                setRegPoint(center.x,center.y,false);
                setZoomCanvas(newZoom,replayMode);
                setOptimizeCanvasMove(false);
                updatePenSizeCursor();
                updatePreviewBoxRectPos();
            }
        }

        private function keyUpLassoTool(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;
            if(lassoMenuTempOFF && !mouseClickON) lassoMenuTempOFF = false;

            if(isNowKey(keyCode))
            {
                if(keyBuffer.length > 0) setNowKey(keyBuffer[0]);
                else resetNowKey();
            }
        }

        private function keyDownLassoTool(e:KeyboardEvent):void
        {
            const keyCode:int = keyBuffer[0];

            if(isNowKey(keyCode)) return;            
            setNowKey(keyCode);

            switch(keyCode)
            {
                case KEY.space:
                {
                    setNowKey(keyCode);
                    setNowTool(TOOL_HAND);
                    lassoMenuTempOFF = true;
                }
                break;

                case KEY.w:
                case KEY.i:
                {
                    setNowKey(keyCode);
                    setNowTool(TOOL_ZOOM);
                    lassoMenuTempOFF = true;
                }
                break;

                case KEY.s:
                case KEY.k:
                {
                    setNowKey(keyCode);
                    setNowTool(TOOL_ROTATE);
                    lassoMenuTempOFF = true;
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
            if(isSidebarVisible === false)
            {
                return;
            }
            
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
            const z:Number = zoomed;

            previewBox.updateCursor(gp.x*z,gp.y*z
                                    ,stage.stageWidth-STAGE_LEFT_OFFSET-STAGE_RIGHT_OFFSET
                                    ,stage.stageHeight-STAGE_TOP_OFFSET-STAGE_BOTTOM_OFFSET
                                    ,CANVAS_WIDTH*z,regPoint.rotation);
        }

        private function setHandToolPreviewBox(cursorClicked:Boolean):void
        {
            const floor:Function = Math.floor;
            const cursor:Sprite = previewBox.prevCursor;
            var sx:Number = previewBox.mouseX;
            var sy:Number = previewBox.mouseY;
            const _consoleBitmap:Bitmap = previewBox.prevBitmap;
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

            function consolBoxHandToolUpEvent(e:MouseEvent):void
            {
                setOptimizeCanvasMove(false);
                checkCanvasPanelPos();
                updatePreviewBoxRectPos();
                mouseClickON = false;
                mouseDragON = false
                stageMouseMoveEvent.remove(consolBoxHandToolMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,consolBoxHandToolUpEvent);
            }

            function consolBoxHandToolMoveEvent(e:MouseEvent):void
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

            stageMouseMoveEvent.add(consolBoxHandToolMoveEvent)
            stage.addEventListener(MouseEvent.MOUSE_UP,consolBoxHandToolUpEvent)
        }
                //원점 penSmoothX oy로부터 dx쪽으로 dist 만큼 떨어진 거리 점을 리턴함

        private function movePointAngleDist(ox:Number,oy:Number,dx:Number,dy:Number,dist:Number):Point
        {
            const rad:Number = Math.atan2(dx-ox,dy-oy);

            return new Point(ox + dist*Math.sin(rad)
                            ,oy + dist*Math.cos(rad));
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

        private function setTraceImageButton():void
        {
            const btn:SimpleButton = traceMenuBox.traceImageButton;
            setTopChildIndex(traceMenuBox);
            traceImageCount++;

            function setTraceImageButtonCountResetEvent(e:MouseEvent):void
            {
                traceImageCount = 0;
                btn.removeEventListener(MouseEvent.MOUSE_OUT,setTraceImageButtonCountResetEvent);
            }

            if(traceImageCount === 1)
            {
                traceMenuBox.traceInfo.text = "One more click to OK";
                btn.addEventListener(MouseEvent.MOUSE_OUT,setTraceImageButtonCountResetEvent);
            }
            else if(traceImageCount === 2)
            {
                traceImageCount = 0;
                btn.removeEventListener(MouseEvent.MOUSE_OUT,setTraceImageButtonCountResetEvent);
                traceMenuBox.traceInfo.text = "Transfer to ref. layer";
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
                rDataBuffer.push(["bgColor",hexColor]);
                addUndoData(3);
            }
        }


        private function checkLassoMenuPos():void
        {
            const _lassoMenu:lassoButtons = lassoMenu;
            const _lassoBox:Sprite = lassoBox;
            const g:Point = _lassoBox.localToGlobal(new Point(0,0));
            const floor:Function = Math.floor;
            const stw:Number = stage.stageWidth;
            const sth:Number = stage.stageHeight;
            var lassoW:Number = _lassoMenu.width;
            var lassoH:Number = _lassoMenu.height;

            if(lassoW > stw) lassoW = stw;

            _lassoMenu.x = floor(g.x-lassoW/2);
            _lassoMenu.y = floor(g.y+(lassoBox.height*zoomed)/2+15);

            checkBoxPosition(_lassoMenu);
        }

        private function traceMenuHintONEvent(e:MouseEvent):void
        {
            if(mouseDragON === true) return;
            const targetName:String = e.target.name;
            var str:String = "";
            switch(targetName)
            {
                case "traceCancelButton":str = "Close"; break;
                case "traceImageButton":str = "Transfer to ref. layer"; break;
                case "traceLoadButton":str = "Paste image from file"; break;
                case "traceClipButton":str = "Paste image from clipboard"; break;
                case "traceButtonWrapper":str = "Adjust opacity"; break;
                case "traceRotateButton":str = "Rotate image"; break;
                case "traceMoveButton":str = "Move image"; break;
                case "traceResizeButton":str = "Resize image"; break;
                case "traceCancelButton":str = "Close"; break;
                case "traceMirrorButton":str = "Flip image"; break;
                case "traceVisibleONButton":
                case "traceVisibleOFFButton":str = "Memory training ON/OFF"; break;
                case "traceDeleteButton":str = "Erase reference image"; break;
                default:
                    traceMenuBox.traceInfo.text = "Reference layer";
                return;
            }

            traceMenuBox.traceInfo.text = str;
        }
        private function lassoMenuHintONEvent(e:MouseEvent):void
        {
            if(mouseDragON === true) return;
            const targetName:String = e.target.name;
            var str:String = "";

            switch(targetName)
            {
                case "lassoOK":str = "OK (enter, richt-click)"; break;
                case "lassoCancel":str = "Cancel (esc, backspace)"; break;
                case "lassoCopy":str = "Copy image"; break;
                case "lassoMove":str = "Move image"; break;
                case "lassoRotate":str = "Rotate image"; break;
                case "lassoCZoom":str = "Zoom canvas"; break;
                case "lassoCRotate":str = "Rotate Canvas"; break;
                case "lassoCHand":str = "Move canvas"; break;
                case "lassoMirror":str = "Flip image"; break;
                case "lassoResize":str = "Resize image"; break;
                case "lasso1pxLeft":
                case "lasso1pxRight":
                case "lasso1pxUp":
                case "lasso1pxDown":
                    str = "Move image 1px (arrow key)"
                break;

                default: lassoMenu.lassoInfo.text = "Lasso tool";
                return;
            }

            lassoMenu.lassoInfo.text = str;
        }

        private function toolBoxHintOFFEvent(e:MouseEvent):void
        {
            if(toolBox.toolInfo.visible)// && mouseX >= sideBar.w-5)
                toolBox.hintOFF();

            if(zoomToolHintON) zoomToolHintON = false;
            else toolTipBox.visible = false;
        }

        private function checkToolBoxHint(targetName:String):String
        {
            var str:String = "";

            switch(targetName)
            {
                case "fillPenOK": str = "OK (q, o, enter, right-click)"; break;
                case "fillPenCancel": str = "cancel (esc, backspace)"; break;
                case "fillPenUndo": str = "undo (w, z / i, .)"; break;
                case "toolBoxCloseButton": str = "Close"; break;
                case "toolPen": str = "Pen (q, o key up) "; break;
                case "toolFillPen": str = "Fill pen (q, o)"; break;
                case "toolErase": str = "Eraser (d, j)"; break;
                case "toolLasso": str = "Lasso (r, y)"; break;
                case "toolSpuit": str = "Eye dropper (c, m)"; break;
                case "deepUndoOK": str = "OK (enter, ctrl+z, ctrl+.)"; break;
                case "deepUndoCancel": str = "Cancel (esc, backspace)"; break;
                case "toolUndo": str = "Undo (z, .)"; break;
                case "toolRedo": str = "Redo (x, ,)"; break;
                case "toolMirror": str = "Flip canvas(a, l)"; break;
                case "toolLine": str = "Line (shift)"; break;
                case "toolMove": str = "Move image (e, u)"; break;
                case "toolZoom": if(!toolBox.isZoomIconON()) str = "Zoom (w, i)"; break;
                case "toolRotate": str = "Rotate (s, k)"; break;
                case "toolTrace": str = "Reference layer (t)"; break;
                case "toolMask": str = "Mask (sift+x, shift+,)"; break;
                case "maskOK": str = "OK (enter, shift+x, shift+,)"; break;
                case "maskCancel": str = "Cancel (esc, backspace)"; break;
                case "maskApply": str = "Apply to mask (right-click, a, l)"; break;
                case "maskUndo": str = "Undo (z, .)"; break;
                case "maskErase": str = "Eraser (d, j)"; break;
                case "maskDelete": str = "Delete all mask (del, shift+d, shift+j)"; break;
            }
            return str;
        }

        private function toolBoxHint2ONEvent(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target || target.alpha < 1.0) return;

            const hintStr:String = checkToolBoxHint(target.name);
            toolBox2.toolInfo.text = (hintStr === "") ? "Tools" : hintStr;

        }

        private function toolBoxHintONEvent(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target || mouseClickON || mouseDragON || target.alpha < 1.0) return;

            const hintStr:String = checkToolBoxHint(target.name);

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

            const _tb:topMenu = topBar;
            _tb.hintOFF();
            setTopChildIndex(_tb);

            const buttonSetVisible:Function = _tb.buttonSetVisible;

            buttonSetVisible(mode,true,isRightSidebar,isSidebarVisible);  
            _tb.updateButtonVisible(false);

            if(mode === "draw")
            {
                buttonSetVisible("replay",false);
                buttonSetVisible("capture",false);
                _tb.changeHintYPos(_tb.BARSIZE);
                updatePenSizeCursor();
                if(needUpdate)
                {
                    _tb.updateButtonVisible(true);
                }
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
                _tb.changeHintYPos(_tb.BARSIZE+_replayTimeBox.BARSIZE);
            }
            else if(mode === "capture")
            {
                buttonSetVisible("replay",false);
                buttonSetVisible("draw",false,isRightSidebar);
                _tb.changeHintYPos(_tb.BARSIZE);
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
        }

        private function setGridButton():void
        {
            gridFlag++;
        
            setTopChildIndex(canvasGrid);
            canvasGrid.visible = true;

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
        }

        private function updateTraceOpaButtonPosByAlpha(alpha:Number):void
        {
            const _traceMenuBox:traceButtons = traceMenuBox;
            const button:SimpleButton = _traceMenuBox["traceOpaButton"];
            const bar:SimpleButton = _traceMenuBox["traceOpaBar"];
            const barWidth:Number = bar.width*alpha;
            const buttonMin:Number = bar.x;
            traceMenuBox["traceOpaButton"].x = buttonMin+barWidth;
        }

        private function closeTraceMenu():void
        {
            traceMenuON = false;
            traceMenuBox.visible = false;
        }

        private function openTraceWindow():void //load clip버튼에서 눌러줬을때 틀여줌
        {
            if(traceMenuON === true)
            {
                setTopChildIndex(traceMenuBox);
                return;
            }

            const _traceMenuBox:traceButtons = traceMenuBox;
            _traceMenuBox.x = mouseX-_traceMenuBox.width/2;
            _traceMenuBox.y = mouseY-3;
            _traceMenuBox.visible = true;

            traceMenuON = true;

            setTopChildIndex(_traceMenuBox);
            checkBoxPosition(_traceMenuBox);
        }

        private function setTraceDeleteButton():void
        {
            const btn:SimpleButton = traceMenuBox.traceDeleteButton;

            setTopChildIndex(traceMenuBox);
            traceImageCount++;

            function traceDeleteButtonCountResetEvent(e:MouseEvent):void
            {
                traceImageCount = 0;
                btn.removeEventListener(MouseEvent.MOUSE_OUT,traceDeleteButtonCountResetEvent);
            }

            if(traceImageCount === 1)
            {
                traceMenuBox.traceInfo.text = "One more click to OK";
                btn.addEventListener(MouseEvent.MOUSE_OUT,traceDeleteButtonCountResetEvent);
            }
            else if(traceImageCount === 2)
            {
                traceImageCount = 0;
                traceMenuBox.traceInfo.text = "Erase reference image";
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
                traceMenuBox.traceVisibleOFFButton.visible = false;
                traceMenuBox.traceVisibleONButton.visible = true;
            }
            else if(traceMemoryTraining === true)
            {
                traceMemoryTraining = false;
                traceMenuBox.traceVisibleOFFButton.visible = true;
                traceMenuBox.traceVisibleONButton.visible = false;
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
            // const traceMenuClickPos:Array = [traceMenuBox.mouseX,traceMenuBox.mouseY];

            // const PI2:Number = PI*2;
            const toDeg:Number = 180/PI;
            var regAng:Number = -regPoint.rotation%90;
            var oldAng:Number = _canvasTrace.rotation;
            var sumAng:Number = oldAng*PI/180;

            traceMenuBox.visible = false;
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
                traceMenuBox.visible = true;
                _rotateCursorBox.rotation = 0;
                saveOneTime = false;
                mouseDragON = false;
                tracePosInfo[2] = canvasTraceLayer.rotation; //deg로 저장
                _rotateCursorBox.visible = false;
                canvasTraceBitmap.smoothing = true;
                stage.removeEventListener(MouseEvent.MOUSE_UP,traceRotateButtonUpEvent);
                stageMouseMoveEvent.remove(traceRotateButtonMoveEvent);
            }

            function traceRotateButtonMoveEvent(e:MouseEvent):void
            {
                const nowAng:Number = atan2(mouseX-_rotateCursorBox.x,mouseY-_rotateCursorBox.y);
                const subAng:Number = lastAng-nowAng;

                if(subAng === 0) return;

                lastAng = nowAng;
                sumAng += subAng;
                var deg:Number = floor(sumAng*toDeg);
                const snap90:Number = abs(deg%90);//90도 스냅 변수
                const snap90N:Number = 90-snap90;
                const snapAng:Number = (snap90 > snap90N) ? snap90 : snap90N;

                //90도에 가까우면 90도 스냅이 걸리게함
                if(snapAng > 85)
                {
                    deg = floor(deg/90+0.5)*90;
                }

                _canvasTrace.rotation = deg;
                _rotateCursorBox["rotateArrow"].rotation = deg;
            }

            stage.addEventListener(MouseEvent.MOUSE_UP,traceRotateButtonUpEvent);
            stageMouseMoveEvent.add(traceRotateButtonMoveEvent);
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
            const smoothLast:Point = new Point(0,0);
            var moveFlag:int = 0;

            traceMenuBox.visible = false;
            canvasTraceBitmap.smoothing = false;
            setToolTipString(w+ " x "+ h +" ["+_canvasTrace.scaleX.toFixed(2)+"]");
            toolTipBox.visible = true;

            function traceResizeButtonUpEvent(e:MouseEvent):void
            {
                saveOneTime = false;
                mouseDragON = false;
                tracePosInfo[3] = _canvasTrace.scaleX;
                tracePosInfo[4] = _canvasTrace.scaleY;
                traceMenuBox.visible = true;
                canvasTraceBitmap.smoothing = true;
                toolTipBox.visible = false;
                stage.removeEventListener(MouseEvent.MOUSE_UP,traceResizeButtonUpEvent);
                stageMouseMoveEvent.remove(traceResizeButtonMove);
            }

            function traceResizeButtonMove(e:MouseEvent):void
            {
                const mx:Number = mouseX;
                const my:Number = mouseY;

                if(moveFlag != 0)
                {
                    if(moveFlag === 1)
                    {
                        const subX:Number = mx-smoothLast.x;
                        
                        if(subX !== 0) //차이가 0이 될때가 있어서 이건 스킵
                        {
                            var dx:Number = subX*0.02;
                            if(mirrorFlag) _canvasTrace.scaleX -= dx;
                            else  _canvasTrace.scaleX += dx;

                            _canvasTrace.scaleY += dx;
                            traceReizeMoveSum += subX;
                        }
                    }
                    else if(moveFlag === 2)
                    {
                        const subY:Number = smoothLast.y-my;
                        if(subY !== 0)
                        {
                            const dy:Number = subY*0.02;
                            if(mirrorFlag) _canvasTrace.scaleX -= dy;
                            else  _canvasTrace.scaleX += dy;

                            _canvasTrace.scaleY += dy;
                            traceReizeMoveSum += subY;
                        }
                        
                    }
                    smoothLast.setTo(mx,my);
                }
                else if(moveFlag === 0)
                {
                    if(abs(mx-z) > moveOffset)
                    {
                        moveFlag = 1;
                    }
                    else if(abs(my-cy) > moveOffset)
                    {
                        moveFlag = 2;
                    }
                    smoothLast.setTo(mx,my);
                }

                const sc:Number = abs(_canvasTrace.scaleX);
                const ww:Number = floor(w*sc+0.5);
                const hh:Number = floor(h*sc+0.5);
                
                setToolTipString(ww+ " x "+ hh +" ["+sc.toFixed(2)+"]");
                toolTipBox.visible = true;
            }

            stage.addEventListener(MouseEvent.MOUSE_UP,traceResizeButtonUpEvent);
            stageMouseMoveEvent.add(traceResizeButtonMove);
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

            traceMenuBox.visible = false;
            canvasTraceBitmap.smoothing = false;

            function traceMoveButtonUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP,traceMoveButtonUpEvent);
                stageMouseMoveEvent.remove(traceMoveButtonMoveEvent);
                saveOneTime = false;
                mouseDragON = false;
                traceMenuBox.visible = true;
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
            stageMouseMoveEvent.add(traceMoveButtonMoveEvent);
        }

        private function setTraceClipButton():void
        {
            const btn:SimpleButton = traceMenuBox.traceClipButton;

            if(btn.alpha !== 1.0) return;

            setTopChildIndex(traceMenuBox);
            traceImageCount++;

            function traceClipButtonCountResetEvent(e:MouseEvent):void
            {
                traceImageCount = 0;
                btn.removeEventListener(MouseEvent.MOUSE_OUT,traceClipButtonCountResetEvent);
            }

            if(traceImageCount === 1)
            {
                traceMenuBox.traceInfo.text = "One more click to OK";
                btn.addEventListener(MouseEvent.MOUSE_OUT,traceClipButtonCountResetEvent);
            }
            else if(traceImageCount === 2)
            {
                traceImageCount = 0;
                traceMenuBox.traceInfo.text = "Paste image from clipboard";
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
            traceMenuBox.traceInfo.text = "Opacity "+Math.floor(deafultAlpha*100)+"%"
            canvasTraceLayer.visible = true;
        }

        private function setTraceOpaButton():void
        {
            const _traceMenuBox:traceButtons = traceMenuBox;
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
                stageMouseMoveEvent.remove(traceOpaButtonMoveEvent);
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
                _traceMenuBox.traceInfo.text = "Opacity "+floor(alpha*100+0.5)+"%"
            }
            _traceMenuBox.traceInfo.text = "Opacity "+floor(CANVAS_TRACE_ALPHA*100+0.5)+"%"

            setTraceOpaValue();

            stage.addEventListener(MouseEvent.MOUSE_UP,traceOpaButtonUpEvent);
            stageMouseMoveEvent.add(traceOpaButtonMoveEvent);
        }

        private function saveTraceImage():void
        {
            if(!canvasTraceBitmap.bitmapData) return;
            
            const bmpd:BitmapData = canvasTraceBitmap.bitmapData;//실제 보여주는 데이터를 저장해줌
            const w:int = canvasTraceBitmap.width;
            const h:int = canvasTraceBitmap.height;
            const fs:FileStream = new FileStream();
            const ba:ByteArray = new ByteArray;
            const newRectangle:Rectangle = new Rectangle(0,0,w,h);
           
            bmpd.copyPixelsToByteArray(newRectangle,ba);
            ba.compress();
            fs.open(traceImageFile,FileMode.WRITE);
            fs.writeObject([ba,w,h]);
            fs.close();
            ba.clear();
        }

        private function clearTraceImage():void
        {
            canvasTraceBitmapData.dispose();
            canvasTraceBitmapData = new BitmapData(1,1,true,0);
            canvasTraceBitmap.bitmapData = null;
            if(traceImageFile.exists) traceImageFile.deleteFile();

            resetTraceImageInfo();
        }
        
        private function resetTraceImageInfo():void
        {
            const _canvasTrace:Sprite = canvasTraceLayer;
            const _canvasTraceBitmap:Bitmap = canvasTraceBitmap;
            const ww:Number = -_canvasTraceBitmap.width/2;
            const hh:Number = -_canvasTraceBitmap.height/2;
            const xx:Number = (mirrorON) ? -1 : 1;

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
                canvasTraceBitmapData.dispose();
                canvasTraceBitmapData = tmpBMPD.clone();
                canvasTraceBitmap.bitmapData = canvasTraceBitmapData;

                tmpBMPD.dispose();
                tmpBMPD = null;
            }
            else //캔버스 자체 이미지를 붙여넣을때
            {
                rDataBuffer = [["clear"]];
                canvasTraceBitmapData.dispose();
                canvasTraceBitmapData = canvas1BitmapData.clone();
                canvasTraceBitmap.bitmapData = canvasTraceBitmapData;
                canvas1BitmapData = new BitmapData(w,h,true,0); //캔버스를 지워줌
                canvas1Bitmap.bitmapData = canvas1BitmapData;
                addUndoData(4);
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

            updateTraceOpaButtonPosByAlpha(0.5);

            CANVAS_TRACE_ALPHA = 0.5;
            canvasTraceLayer.visible = true;
            canvasTraceLayer.alpha = 0.5;
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

                if((penFlag && size === airBrushSizeDrawMode)
                || (size === airBrushSizeDrawMode))
                {
                    _controlBox.blurShapeSetON();
                }
                else
                {
                    setBlurCanvasBySizeDrawMode(size);
                    _controlBox.blurShapeSetON();
                }
            }
            else if(airBrushSizeDrawMode !== 0)
            {
                airBrushSizeDrawMode = 0;
                canvas2Draw.filters = [];
                _controlBox.blurShapeSetOFF();
            }
        }

        private function setAirBrush(flag:Boolean):void
        {
            const penFlag:Boolean = isPenOrLineTool();

            if(penFlag) airBrushON = flag;
            else eraseAirBrushON = flag;

            setAirBrushCheckBox(flag,penFlag);
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

        private function setSubLayer(flag:Boolean):void
        {
            subLayerON = flag;
            const _controlBox:controlMenu = controlBox;
            _controlBox["subLayerOFFButton"].visible = flag;
            _controlBox["subLayerONButton"].visible = !flag;

            if(subLayerON) canvasPanel.setChildIndex(canvas1,2);
            else canvasPanel.setChildIndex(canvas2,2);
        }   

        private function setPixelSnap(flag:Boolean):void
        {
            pixelSnapON = flag;
            const _controlBox:controlMenu = controlBox;
            _controlBox["pixelSnapOFFButton"].visible = flag;
            _controlBox["pixelSnapONButton"].visible = !flag;

            const isErase:Boolean = isEraseTool();
            const z:Number = zoomed;
            const size:uint = (isErase) ? eraseSize:penSize;
            const zSize:Number = size*z;

            if(pixelSnapON)
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

        private function setFillPen(flag:Boolean):void
        {
            if(flag === true)
            {
                penSizeCursor.visible = false;

                const _controlBox:controlMenu = controlBox;
                controlBox.pixelSnapButtonWrapper.alpha = 1.0;
                controlBox.subLayerButtonWrapper.alpha = 1.0;
                controlBox.airBrushButtonWrapper.alpha = BUTTON_OFF_ALPHA;

                const airBrushFlagBackup:Boolean = airBrushON;
                setAirBrush(false);
                airBrushON = airBrushFlagBackup;

                canvasPanel.setChildIndex(canvas2,2);

                updateOpaBoxColor(penColor);
                updateOpacityCursor(penAlphaIndex);
            }
        }

        private function updateStageBG(color:uint=0xCCCCCC):void
        {
            const g:Graphics = stageBG.graphics;

            g.clear();
            g.beginFill(color);//paneldraw마스크 아무색이나 상관없음
            g.drawRect(0,0,stage.stageWidth,stage.stageHeight);
            g.endFill();
            STAGE_BG_COLOR = color;
        }

        private function updateWindowTitle():void
        {
            stage.nativeWindow.title = saveFileName;
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
            controlBox.changeUIColor(base,op);
            toolTipBox.changeUIColor(base,op);
            pickerBox.changeUIColor(op);
            updatePickerCurrentColor(penColor);
            sideBar.changeUIColor(base,op);
            previewBox.chanegStageColor(bg);
            toolBox.changeUIColor(_arr2);
            toolBox2.changeUIColor(_arr2);
            traceMenuBox.changeUIColor(_arr2,index === 0);
            lassoMenu.changeUIColor(_arr2);
            topBar.changeUIColor(base,op,uiColorSet[index][4]);
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
            updateScrollBar(scrollBarHeight);
            setResizeButtonColor(nowColorSet[3]);
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
            stageMouseMoveEvent.add(updatePenCursorPositionEvent);
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
            toolBox2.addEventListener(MouseEvent.MOUSE_OUT,toolBoxHintOFFEvent);
            // toolBox2.addEventListener(MouseEvent.MOUSE_OUT,toolBox2HintOFF);
            lassoMenu.addEventListener(MouseEvent.MOUSE_OVER,lassoMenuHintONEvent);
            traceMenuBox.addEventListener(MouseEvent.MOUSE_OVER,traceMenuHintONEvent);

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
            
            controlBox.hintText(toolName+" Options");
        }

        private function controlBoxHintOFFEvent(e:MouseEvent):void
        {
            clearTimeout(controlBoxHintTimer);
            controlBoxHintTimer = setTimeout(function():void
            {
                if(isHitTestPoint(controlBox) === false)
                {
                    setControlBoxInfoOFF();
                }
            },100);
        }

        private function controlBoxHintONEvent(e:MouseEvent):void
        {
            if(mouseDragON || mouseClickON || toolBox2ON || lassoToolON) return;

            const target:DisplayObject = e.target as DisplayObject;
            const targetName:String = target.name;
            var str:String = "";

            switch(targetName)
            {      
                case "shapeCircle": str = "Circle"; break;
                case "shapeRect": str = "Square"; break;

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
                    str = penSizeHint(targetName)+" (f, v / h, n)";
                }
                break;

                case "alphaButton0":
                case "alphaButton1":
                case "alphaButton2":
                case "alphaButton3":
                    str = getAlphaHint(targetName)+" (g, b)";
                break;

                case "pixelSnapButtonWrapper":
                case "pixelSnapOFFButton":
                case "pixelSnapONButton":
                case "pixelSnapText":
                    str = "Sharp line (3, 9)";
                break;

                case "airBrushWrapper":
                case "airBrushOFFButton":
                case "airBrushONButton":
                case "airBrushText":
                    str = "Air brush (4, 0)";
                break;

                case "subLayerButtonWrapper":
                case "subLayerOFFButton":
                case "subLayerONButton":
                case "subLayerText":
                    str = "Sub layer (5, -)";
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
            rFileStream.close();
            restartTimerCancel();

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
            const _replayTimeBox:replayTimeBar = replayTimeBox;
            const replayTotalBar:Sprite = _replayTimeBox["replayTotalBar"];
            const maxWidth:Number = stw-_replayTimeBox["replayTotalBar"].x-5;
            const totalFrame:Number = TOTAL_FRAME;

            _replayTimeBox["replayBGBar"].width = stw;
            replayTotalBar.width = maxWidth;
            _replayTimeBox["frameInfo"].x = replayTotalBar.x;
            _replayTimeBox["frameInfo"].width = maxWidth;
            _replayTimeBox["replayNowBar"].width = (replayTotalBar.width)*(rNowFrame/totalFrame);
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

                setToolTipStringTime(alphaStr);
                setPenAlpha(alphaValue);
            }

            if(isEraseTool()) setAlpha(eraseAlpha,eraseSize);
            else if(isPenOrLineTool()) setAlpha(penAlpha,penSize);
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

                setToolTipStringTime(sizeStr);
                setPenSize(index);
                updatePenSizeCursor();
            }

            if(isPenOrLineTool())
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
            if(fileDragSelectBox.visible) return;

            const keyCode:int = e.keyCode;
            const index:int = keyBuffer.lastIndexOf(keyCode);

            if(index > -1) keyBuffer.splice(index,1);
        }

        private function stageKeyDownEvent(e:KeyboardEvent):void
        {
            const keyCode:int = e.keyCode;

            if(fileDragSelectBox.visible || keyCode === KEY.window) return;

            const index:int = keyBuffer.lastIndexOf(keyCode);

            if(keyCode === KEY.tab || keyCode === KEY.alt) e.preventDefault();
            if(index === -1) keyBuffer.push(keyCode);
        }

        private function setAlphaButton(targetName:String):void
        {
            const numberStr:String = targetName.substr(11,targetName.length);
            const alpIndex:int = parseInt(numberStr);
            const alpha:Number = alphaArr[alpIndex];
            const alphaStr:String =  alpha*100+"%";

            setPenAlpha(alpha);
        }

        private function setPenSizeButton(targetName:String):void
        {
            const numberOnly:String = targetName.substr(11,targetName.length);
            const index:uint = parseInt(numberOnly);

            function penSizePrevOFFEvent(e:MouseEvent):void
            {
                if(isHitTestPoint(controlBox.penSizeTransButtonBox) === false)
                {
                    clearTimeout(penSizePrevOFFTimer);
                    penSizePrev.visible = false;
                    stage.removeEventListener(MouseEvent.MOUSE_DOWN,penSizePrevOFFEvent);
                }
            }

            setPenSize(index);
            updatePenSizeCursor();
            penSizePrev.visible = true;

            if(isPenOrLineTool())
            {
                if(airBrushON && penSize !== airBrushSizeDrawMode) setBlurCanvasBySizeDrawMode(penSize);
            }
            else if(isEraseTool())
            {
                if(eraseAirBrushON && eraseSize !== airBrushSizeDrawMode)setBlurCanvasBySizeDrawMode(eraseSize);
            }

            clearTimeout(penSizePrevOFFTimer);
            penSizePrevOFFTimer = setTimeout(function():void
            {
                penSizePrev.visible = false;
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,penSizePrevOFFEvent);
            },2000);
            
            stage.addEventListener(MouseEvent.MOUSE_DOWN,penSizePrevOFFEvent);
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
            const leftOffset:Number = sliderSet["penSmoothBar"].x+2; //펜 리스트에 흰색 선 시작과 끝 x좌표임
            const rightOffset:Number = leftOffset+sliderSet["penSmoothBar"].width-2;
            const step:Number = penSmoothSlideTotal;
            const div:Number = (rightOffset-leftOffset)/step;
            const maxValue:Number = 0.85;
            const minValue:Number = 0.02;
            const stepValue:Number = (maxValue-minValue)/step;
            const airBrushFlag:Boolean = isPenOrLineTool() && airBrushON;
            const eraseAirBrushFlag:Boolean = isEraseTool() && eraseAirBrushON;
            var oldValue:int = penSmoothSlideValue;
  
            function penSmoothButtonUpEvent(e:MouseEvent):void
            {
                mouseDragON = false;
                stage.removeEventListener(MouseEvent.MOUSE_UP,penSmoothButtonUpEvent);
                stageMouseMoveEvent.remove(penSmoothButtonMoveEvent);
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
            stageMouseMoveEvent.add(penSmoothButtonMoveEvent);
        }

        private function mergeCanvas(replayMode:Boolean,transBG:Boolean):BitmapData
        {
            var xbitmap1:BitmapData;
            var xbitmap2:BitmapData;
            var xCanvas2Draw:Shape;
            var xBGCOLOR:uint;
            var alpha:Number;

            if(replayMode)
            {
                xbitmap1 = rcanvas1BitmapData;
                xbitmap2 = rcanvas2BitmapData;
                xCanvas2Draw = rcanvas2Draw;
                xBGCOLOR = RCANVAS_BG_COLOR;
                alpha = tickDraw.getLineStyleAlpha();
            }
            else
            {
                xbitmap1 = canvas1BitmapData;
                xbitmap2 = canvas2BitmapData;
                xCanvas2Draw = canvas2Draw;
                xBGCOLOR = CANVAS_BG_COLOR;
                alpha = 1.0;
            }

            const w:Number = xbitmap1.width;
            const h:Number = xbitmap1.height;
            const bmpd:BitmapData = new BitmapData(w,h,true,(transBG) ? 0 : 0xFF000000|xBGCOLOR);
            const bmpd2:BitmapData = new BitmapData(w,h,true,0);
            const newColorTransForm:ColorTransform = new ColorTransform(1,1,1,alpha);

            bmpd2.draw(xbitmap2);
            bmpd2.draw(xCanvas2Draw);//캔버스 2번부터 눌러주고
            bmpd.draw(xbitmap1); //1번 그려주고
            bmpd.draw(bmpd2,null,newColorTransForm); //그위에 2번 그려줌

            return bmpd;
        }

        private function setCaptrueFlipButton():void
        {
            captureFlipped = !captureFlipped;
            canvasFitWindow(true);
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
            if(replayModeON) saveCaptureImage(0,0,rcanvas1BitmapData.width,rcanvas1BitmapData.height);
            else saveCaptureImage(0,0,canvas1BitmapData.width,canvas1BitmapData.height);
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
            canvasFitWindow(true);
        }

        //rotate hand zoom에서 쓰임
        private function _setResizeButtonVisible(flag:Boolean):void
        {
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
                clearTimeout(toolBox2ResizeButtonTimer);
                updateResizeButtonPos();
            }
            _setResizeButtonVisible(flag);
        }

        private function setResizeButtonVisibleTimer(flag:Boolean):void
        {
            clearTimeout(toolBox2ResizeButtonTimer);
            if(flag)
            {
                updateResizeButtonPos();
                toolBox2ResizeButtonTimer = setTimeout(function():void
                {
                    _setResizeButtonVisible(true);
                },700);
            }
            else _setResizeButtonVisible(false);
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
            if(isDeepUndoON) return;
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

        private function removeDeepUndoEvent():void
        {
            stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpDeepUndo);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownDeepUndo);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownDeepUndo);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownDeepUndo);
        }

        private function addInputEventDeepUndo():void
        {
            resetKeyBuffer();
            stage.addEventListener(KeyboardEvent.KEY_UP,keyUpDeepUndo,false,-1);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownDeepUndo,false,-1);
            stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownDeepUndo,false,-1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownDeepUndo,false,-1);
        }

        private function removeInputEventDrawMode():void
        {
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownDrawMode);
            stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpDrawMode);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownDrawMode);
            stage.removeEventListener(MouseEvent.MOUSE_UP,mouseUpDrawMode,false);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownDrawMode);
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
        }

        private function addInputEventCaptrueMode():void
        {
            stage.addEventListener(KeyboardEvent.KEY_UP,keyUpCaptureMode,false,-1);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownCaptureMode,false,-1);
            stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownCaptureMode,false,-1);
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

            if(lassoToolON || fillPenStarted || target.alpha < 1.0) return;

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
                    setReplayUI(true);

                    mouseClickON = false; //리플레이 버튼 누르고 나서 단축키가 안먹는 현상이 이거임
                }
                break;

                case "drawModeButton": setReplayUI(false); break;
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
                stageMouseMoveEvent.remove(lassoRotateButtonMoveEvent);
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
            angleCursor.rotation = _lassoBox.rotation;
            _rotateCursorBox.visible = true;
            setTopChildIndex(_rotateCursorBox);
            lastAng = Math.atan2(mouseX-_rotateCursorBox.x,mouseY-_rotateCursorBox.y);
            _lassoMenu.visible = false;
            stageMouseMoveEvent.add(lassoRotateButtonMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,lassoRotateButtonUpEvent);
        }

        private function setLassoResizeButton():void
        {
            lassoResizeON = true;
            const _lassoBox:Sprite = lassoBox;
            const _lassoMenu:lassoButtons = lassoMenu;
            const floor:Function = Math.floor;
            const abs:Function = Math.abs;
            const moveOffset:Number = 7;
            const _lassoBMP:Bitmap = lassoBMP;
            var lassoFirstX:Number = mouseX;
            var lassoFirstY:Number = mouseY;
            var lassoMovedX:Number = lassoFirstX;
            var lassoMovedY:Number = lassoFirstY;
            var lassoFirstScale:Number = _lassoBox.scaleY;
            var sc:Number = lassoFirstScale;
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
                stageMouseMoveEvent.remove(lassoResizeButtonMoveEvent);
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
                            sc += (subX)*0.02;
                            lassoResizeMoveSum += subX;
                        }
                    }
                    else if(moveFlag === 2)
                    {
                        const subY:Number = lassoMovedY-my;
                        if(subY !== 0)
                        {
                            sc += (subY)*0.02;
                            lassoResizeMoveSum += subY;
                        }
                    }
                    //10픽셀 이하움직임에서는 원래 크기 스냅걸리게함
                    if(abs(lassoResizeMoveSum) <= moveOffset) sc = 1.0;
                }
                else if(moveFlag === 0)
                {
                    if(abs(mx-lassoFirstX) > moveOffset) moveFlag = 1;
                    else if(abs(my-lassoFirstY) > moveOffset) moveFlag = 2;
                }

                _lassoBox.scaleX = (mirrorFlag === true) ? -sc : sc;
                _lassoBox.scaleY = sc;
                lassoMovedX = mx;
                lassoMovedY = my;

                setToolTipString(floor(_lassoBox.width+0.5) +" x " +floor(_lassoBox.height+0.5) +" ["+sc.toFixed(2)+"]");
            }

            setToolTipString(floor(_lassoBox.width+0.5)+" x "+floor(_lassoBox.height+0.5) +" ["+sc.toFixed(2)+"]");
            toolTipBox.visible = true;
            _lassoMenu.visible = false;
            stage.addEventListener(MouseEvent.MOUSE_UP,lassoResizeButtonUpEvent);
            stageMouseMoveEvent.add(lassoResizeButtonMoveEvent);
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
                stageMouseMoveEvent.remove(lassoMoveButtonMoveEvent);
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
            stageMouseMoveEvent.add(lassoMoveButtonMoveEvent);
        }

        private function setPenSize(index:uint):void
        {
            const size:uint = sizeArr[index];

            if(isPenOrLineTool()) 
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
            else selectPenTool();

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
                const color:uint = setPickerHSV(hueValue,HUECOLOR[1],HUECOLOR[2],mode);

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
                    updateColorHistoryList();
                    rDataBuffer.push(["bgColor",pickedColor]);
                    addUndoData(3);
                }

                mouseDragON = false;
                penCursorOFFFlag = false;

                forceSetMainDrawTool();
                //timer로 동작하는 경우 마지막 커서위치에 안가있을수도 있기 때문에 up에서도 해줌
                stage.removeEventListener(MouseEvent.MOUSE_UP,hueColorButtonUpEvent);
                stageMouseMoveEvent.remove(hueColorButtonMoveEvent);
            }
            hueMoveStart(hueColorBox.mouseX);
            stage.addEventListener(MouseEvent.MOUSE_UP,hueColorButtonUpEvent);
            stageMouseMoveEvent.add(hueColorButtonMoveEvent);
        }
        
        private function setPickerHSV(h:Number,s:Number,v:Number,mode:uint):uint
        {
            const rgbColor:Vector.<uint> = HSVtoRGB(h,s,v); //
            const r:uint = rgbColor[0];
            const g:uint = rgbColor[1];
            const b:uint = rgbColor[2];
            const rgbHexColor:uint = RGBtoHex(r,g,b);
            const invColor:uint = getInvertColor(rgbHexColor,1.0
            ,(uiColorIndex >= 2) ? uiColorSet[uiColorIndex][0]:uiColorSet[uiColorIndex][1]
            ,(uiColorIndex >= 2) ? uiColorSet[uiColorIndex][1]:uiColorSet[uiColorIndex][0]);
            const _setColorTransform:Function = setColorTransform;
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
                const color:uint = setPickerHSV(hue0,sValue,vValue,mode);

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
                    updateColorHistoryList();
                    rDataBuffer.push(["bgColor",pickedColor]);
                    addUndoData(3);
                }

                mouseDragON = false;
                penCursorOFFFlag = false;

                forceSetMainDrawTool();

                stage.removeEventListener(MouseEvent.MOUSE_UP,svColorButtonUpEvent);
                stageMouseMoveEvent.remove(svColorButtonMoveEvent);
            }

            setSVBoxMouseMoveEvent(svColorBox.mouseX,svColorBox.mouseY);

            stage.addEventListener(MouseEvent.MOUSE_UP,svColorButtonUpEvent);
            stageMouseMoveEvent.add(svColorButtonMoveEvent);
        }

        //단축키를  after tool mouse up에서 이전툴을 복구해줌
        private function setOldTool():void
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

        private function resetTimer():void
        {
            APP_RUNNING_TIME = 0;
            updateWorkingTime();
        }

        private function updateWorkingTime():void
        {
            const floor:Function = Math.floor;
            const nowTime:Number = APP_RUNNING_TIME/1000;
            const hh:Number = floor(nowTime/3600);
            const mm:Number = floor((nowTime-hh*3600)/60);
            const ss:Number = floor(nowTime%60);
            const h:String = (hh < 10)?"0"+hh:""+hh;
            const m:String = (mm < 10)? "0"+mm:""+mm;
            const s:String = (ss < 10)?"0"+ss:""+ss;
            const time:String = h+":"+m+":"+s;

            topBar.timer.text = time;
			topBar.timer.width = topBar.timer.textWidth+10;
            topBar.updateTimerPos(stage.stageWidth);
        }

        //VERSION변수를 문자열로 변환, 변환할때 뒤에 .0이 붙었는지 까지 체크
        private function convertVersionString(version:Number):String
        {
            var verStr:String = version.toString();

            if(verStr.indexOf(".") === -1) verStr = verStr + ".0";

            return verStr;
        }

        //문자열을 소수 2번째 자리까지만 변환
        private function parseVersion(str:String):Array
        {
            const dotIndex:int = str.indexOf(".");

            if(dotIndex === -1) return[parseInt(str),0];

            const head:String = str.slice(0,dotIndex);
            var tail:String = str.slice(dotIndex+1,str.length);
            var tailLen:uint = tail.length;
            const ver1:Number = parseInt(head);
            const ver2:Number = parseInt(tail)/Math.pow(10,tailLen-1);

            return [ver1,ver2];
        }

        private function setIMEDisabled():void
        {
            if(Capabilities.hasIME && IME.enabled) //다른 언어로 하면 자판 안먹어서 그냥 ime자체를안씀
            {
                IME.enabled = false;
            }
        }

        private function checkVersion():void
        {
            if(isCheckingUpdate)
            {
                return;
            }

            isCheckingUpdate = true;
            clearTimeout(updateRryTimer);

            var url:URLRequest = new URLRequest("https://raw.githubusercontent.com/guljam/2020FlashPaint/master/versionInfo.txt");
            var loader:URLLoader = new URLLoader();

            if(url.useCache)
            {
                url.useCache = false;
            }

            loader.addEventListener(Event.COMPLETE, urlLoadCompleteEvent);
            loader.addEventListener(IOErrorEvent.IO_ERROR, urlLoadFailEvent);
            loader.load(url);

            function urlLoadFailEvent(e:IOErrorEvent):void
            {
                isCheckingUpdate = false;
                loader.removeEventListener(Event.COMPLETE, urlLoadCompleteEvent);
                loader.removeEventListener(IOErrorEvent.IO_ERROR, urlLoadFailEvent);
                loader = null;
            }

            function urlLoadCompleteEvent(e:Event):void
            {
                const versionStr:String = loader.data;
                const findVersionStr:int = versionStr.lastIndexOf(".");

                if(findVersionStr !== -1)
                {
                    var newVersion:Array = parseVersion(versionStr);
                    if(newVersion)
                    {
                        const floor:Function = Math.floor;
                        const oldVersion:Array = parseVersion(String(APP_VERSION));
                        const isNewVersion:Boolean = (newVersion[0] > oldVersion[0]) || (newVersion[1] > oldVersion[1]);
                        var tryCount:uint = 0;

                        url = new URLRequest("https://github.com/guljam/2020FlashPaint/releases/download/update2/fofoPaint.air");

                        if(isNewVersion)
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
                                    updateRryTimer = setTimeout(function():void
                                    {
                                        tryCount++;
                                        fileLoader.load(url);
                                    },1000)
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
                                fileLoader.load(url); //다운로드를 시작함
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
                loader.removeEventListener(Event.COMPLETE, urlLoadCompleteEvent);
                loader.removeEventListener(IOErrorEvent.IO_ERROR, urlLoadFailEvent);
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
            clickBlockTimer = setTimeout(function():void
            {
                clickBlockFlag = false;
            },150);
        }

        private function aboutOFFMouseDownEvent(e:MouseEvent):void
        {
            const targetName:String = e.target.name;

            switch(targetName)
            {
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
            if(welcome === false)
            {
                checkVersion();
                stage.addEventListener(MouseEvent.MOUSE_DOWN,aboutOFFMouseDownEvent);
            }
            else if(welcome === true)
            {
                aboutPanel.appResetButton.visible = false;
                setTimeout(function():void
                {
                    stage.addEventListener(MouseEvent.MOUSE_DOWN,aboutOFFMouseDownEvent);
                },1000);
            }

            aboutPanel.randomLogo();
            setAboutPanelCenterPos();
        }

        private function clearDataResetVars():void
        {
            tickDraw.resetgetRCursorPos();
            rBGColorSave = CANVAS_BG_COLOR;
            saveContinue = false;
            rMirrorON = false;
            mirrorON = false;
            mirrorPushReady = false;
            rDataReadFlag = false;
            rSpeed = 1;
            undoData.setRFileTotalFrame(0);
            TOTAL_FRAME = 0;
            makeJumpImageFlag = 0;
            topBar.replaySpeedMoveButton.x = topBar["replaySpeedBar"].x;

            resetTraceImageInfo();
            resetTraceOpa();
            updateFirstImage(canvas1BitmapData,CANVAS_BG_COLOR);
            resetReplayDataFile(true);
            resetReplayTime();
            resetUndo();
            addUndoData();

            const fileName:String = getTimeStampTailHead()+" "+getRandomString()+".png";
            const name:String = saveFileName;
            const path:String = saveFilePath;
            const newName:String = name.substr(0,name.lastIndexOf(name))+fileName;
            const newPath:String = path.substr(0,path.lastIndexOf(name))+fileName;

            saveFileName = newName;
            saveFilePath = newPath;
            
            appInfoBox.setMirror(false);
            updateWindowTitle();
            setWindowTitleStar();
            cancelAutoKeyEvent({});
        }

        private function setReRecordCopyCanvas():void
        {
            const dd:Array = tickDraw.getrLineStyleSave();
            // if(!dd) return;
            const newColorTransform:ColorTransform = new ColorTransform(1,1,1,dd[0]);

            rcanvas2BitmapData.draw(rcanvas2Draw);
            rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
            rcanvas1BitmapData.draw(rcanvas2Bitmap,null,newColorTransform,dd[1]);

            //캔버스 2번 지워줘야함
            rcanvas2Draw.graphics.clear();
            rcanvas2BitmapData.dispose();
            rcanvas2BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);

            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
            canvas1BitmapData = rcanvas1BitmapData.clone();
            canvas1Bitmap.bitmapData = canvas1BitmapData;

            changeCanvasSize(canvas1Bitmap.width,canvas1Bitmap.height);
            setBackgroundColorDrawMode(RCANVAS_BG_COLOR);

            clearButtonClicked = false;
            clearDataResetVars();
        }

        private function clearData():void
        {
            clearButtonClicked = true;
            clearCanvas();
            clearCanvasReplayMode();
            clearDataResetVars();
        }

        private function setClearData(keyFlag:Boolean=false):void
        {
            if(clearButtonClicked === false)
            {
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
                    topBar.hintOFF();
                    clearData();
                }
                else if(clearDataButtonCount <= 1)
                {
                    if(keyFlag)
                    {
                        topBar.hintTime("One more press to OK",topBar.clearButton);
                    }
                    else
                    {
                        topBar.hint("One more click to OK",topBar.clearButton);
                    }
                }
            }
            else
            {
                clearDataButtonCount = 0;
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
                        case "updateButton":
                        {
                            if(needUpdate === 1)
                            {
                                setTimeout(function():void
                                {
                                    installNewVersion();
                                },500);
                            }
                            else if(needUpdate === 2)
                            {
                                navigateToURL(new URLRequest("https://github.com/guljam/2020FlashPaint"));
                            }
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
                        break
                        case "repCaptureButton":
                        case "captureButton":
                             setCaptureReady();
                        break;
                        case "capRotate":
                            setCaptureRotateButton();
                        break;
                        case "capTrans":
                            setCaptureTransButton();
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
                            resetTimer();
                        }
                        break;

                        case "traceCancelButton":
                        {
                            setTopChildIndex(traceMenuBox);
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
                            setTopChildIndex(traceMenuBox);
                            checkButtonUp(targetName);
                        }
                        break;

                        case "traceClipButton":
                        {
                            setTopChildIndex(traceMenuBox);
                            setTraceClipButton();
                        }
                        break;

                        case "traceMirrorButton":
                        {
                            setTopChildIndex(traceMenuBox);
                            setTraceMirrorButton();
                        }
                        break;

                        case "traceDeleteButton":
                        {
                            setTopChildIndex(traceMenuBox);
                            setTraceDeleteButton();
                        }
                        break;

                        case "traceVisibleONButton":
                        case "traceVisibleOFFButton":
                        {
                            setTopChildIndex(traceMenuBox);
                            setTraceVisibleButton();
                        }
                        break;

                        case "playButton":
                            startReplay();
                        break;

                        case "pauseButton":
                            stopReplay();
                        break;

                        case "lassoOK":
                        {
                            setLassoOKButton();
                        }
                        break;

                        case "lassoCancel":
                        {
                            if(lassoToolON === true)
                            {
                                setLassoCancelButton();
                            }
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
            cutFrameClickCounter = 0;
            cutFrameClickedButton = CUT_FRAME_NONE;
            topBar.hintOFF();
            replayTimeBox["replayDeleteBar"].visible = false;
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

            updateFirstImage(rcanvas1BitmapData,RCANVAS_BG_COLOR);

            if(repFileTemp.exists)//이미 있으면 지워주고
            {
                repFileTemp.deleteFile();
            }
            const sourceFS:FileStream = new FileStream();

            if(rDataReadFlag === true)
            {
                //repfile 초기화
                undoData.setUndoRefImageByReplayMode();
                sourceFS.open(repFile,FileMode.WRITE);
                sourceFS.close();
                forceUndoAndDeleteFrontData(rIndex+1);
                TOTAL_FRAME = getTotalFrame();
                resetReplayTime();
                replayNowBar.width = 0;
                
                rcanvas1BitmapData = canvas1BitmapData.clone();
                rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
            }
            else if(rDataReadFlag === false)
            {
                //make jumpimage에서 변경해주기 때문에
                if(repFileTemp.exists)//이미 있으면 지워주고
                {
                    repFileTemp.deleteFile();
                }
                const targetFS:FileStream = new FileStream();
                var d:Array;

                sourceFS.open(repFile,FileMode.READ);
                sourceFS.position = rLastBytes;
                targetFS.open(repFileTemp,FileMode.APPEND);
                while(1)
                {
                    if(sourceFS.bytesAvailable === 0) break;
                    d = sourceFS.readObject() as Array;

                    targetFS.writeObject(d);
                }
                sourceFS.close();
                targetFS.close();

                repFileTemp.copyTo(repFile,true);
                repFileTemp.deleteFile();

                _makeJumpImage();
                rCursor.visible = false;
                replayNowBar.width = 0;
                saveOneTime = false;
            }
            checkReplaySpeedState();
        }

        private function setReRecord():void
        {
            setReRecordCopyCanvas();
            setCanvasSameReplayCanvas();
            setReplayUI(false);
        }

        private function superUndo():void
        {
            if(rDataReadFlag === true)
            {
                //위에서 setJumpOneFrame을 해줘서 rindex가 증가되었기 때문에
                //실제 undo해줘야할 인덱스는 -1해줘야하는거임
                forceUndoToIndex(rIndex);
                resetReplayTime();
            }
            else if(rDataReadFlag === false)
            {
                const replayTotalBar:Sprite = replayTimeBox["replayTotalBar"] as Sprite;
                const replayNowBar:Sprite = replayTimeBox["replayNowBar"] as Sprite;
                const fs:FileStream = new FileStream();
                const bw:Number = replayTotalBar.width;

                fs.open(repFile,FileMode.UPDATE);
                fs.position = rLastBytes;
                fs.truncate(); //데이터 위에 짤라주고
                fs.close();

                //썸네일 이미지도 날려줌
                const _rframeSum:Number = rNowFrame;
                const list:Array = rJumpImageFolder.getDirectoryListing();
                const index:Number = getJumpImageIndex(_rframeSum);
                //index번 이후 파일 삭제
                for (var i:uint = 0,len:uint=list.length; i < len; i++)
                {
                    const fileNumber:Number = parseInt(list[i].name);
                    if(fileNumber > index) list[i].deleteFile();
                }
                //framedata도 인덱스 이후꺼 날려줌
                rJumpImageFrameData.splice(index+1);
                undoData.setRFileTotalFrame(_rframeSum);
                TOTAL_FRAME = _rframeSum;

                canvas1BitmapData = rcanvas1BitmapData.clone();
                canvas1Bitmap.bitmapData = canvas1BitmapData;
                changeCanvasSize(canvas1Bitmap.width,canvas1Bitmap.height,0,0,false);
                resetReplayTime();
                setBackgroundColorDrawMode(RCANVAS_BG_COLOR);
                replayNowBar.width = bw;
                setCanvasSameReplayCanvas();
                resetUndo();
                addUndoData();
            }
            isDeepUndoONDelayTime = getTimer();
            if(isDeepUndoON) setDeepUndoUI(false)
            else if(replayModeON) setReplayUI(false);
            saveContinue = false;
        }

        private function getCutFrameOKString():String
        {
            return "One more click to OK (Red data will be deleted)";
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
            return (flag === CUT_FRAME_SUPER_UNDO) ?  "Super-undo : "
                  :(flag === CUT_FRAME_RE_RECORD) ? "Re-recording : "
                  :(flag === CUT_FRAME_DELETE_FRONT) ? "Delete front data : "
                  : "";
        }

        private function setCutFrameActiveButton(flag:int):void
        {
            if(flag === CUT_FRAME_SUPER_UNDO) cutFrameActiveButton = topBar["superUndoButton"];
            else if(flag === CUT_FRAME_RE_RECORD) cutFrameActiveButton = topBar["reRecordingButton"];
            else if(flag === CUT_FRAME_DELETE_FRONT) cutFrameActiveButton = topBar["cutPrevDataButton"];
        }

        private function setCutFrameButton(flag:int,shortcutKey:Boolean):void
        {
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
                        checkCutFrameButtons();
                    }
                }

                setCutFrameRedBar(flag);

                if(shortcutKey === false)
                {
                    topBar.hint(getCutFrameOKString(),cutFrameActiveButton);
                }
                else if(shortcutKey === true)
                {
                    topBar.hint(getCutFrameHint(flag)+getCutFrameOKString(),cutFrameActiveButton);
                    stage.addEventListener(MouseEvent.MOUSE_DOWN,resetCutFrameClickCounterMouseDownEvent);
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
                if(hint === "")
                    topBar.hintOFF();
                else
                    topBar.hint(hint+" (Click canvas to save)",topBar.capOff);
            }
            else topBar.hintOFF();
        }
        
        private function topBarHintOFFEvent(e:MouseEvent):void
        {
            if(replayModeON)
            {
                const _replayTimeBox:replayTimeBar = replayTimeBox;
                if(mouseY >= _replayTimeBox.y+_replayTimeBox.BARSIZE-3)
                {
                    setTopBarHintOFF();
                }
            }
            else if(mouseY >= topBar.BARSIZE)
            {
                setTopBarHintOFF();
            }
        }

        private function topBarHintONEvent(e:MouseEvent):void //topbarhint
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target || mouseDragON || mouseClickON || toolBox2ON || lassoToolON) return;

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
                        str = "Prev (left, z, .), 1 frame(right-click, shift + [click, left, z, .])";
                    break;

                    case "replayNext":
                        str = "Next (right, x, ,), 1 frame(right-click, shift + [click, right, x, ,])";
                    break;

                    case "replaySpeedBarWrapper":
                    {
                        if(rSpeedLastStr === "") str = "Change playback speed(up, down / f, v / h, n)";
                        else str = rSpeedLastStr;
                    }
                    break;

                    case "saveButton":
                    case "repSaveButton":
                        str = "Save (ctrl+s), Save as.. (right-click, shift+ctrl+s)";
                    break;

                    case "loadButton":
                        str = "Load (ctrl+o), Load to Reference layer (right-click, ctrl+shift+o)";
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

                    case "capTrans":
                        str = "Background color ON/OFF (d, j)";
                    break;

                    case "capRotate":
                        str = "Rotate image (s, k)";
                    break;

                    case "capFlip":
                        str = "Flip image (a, l)";
                    break;

                    case "reRecordingButton":
                    {
                        if(cutFrameClickCounter === 1
                        && cutFrameClickedButton === CUT_FRAME_RE_RECORD)
                            str = getCutFrameOKString();
                        else
                            str = "Re-recording from this image (f1, f6)";
                    }

                    break;
                    case "superUndoButton":
                    {
                        if(cutFrameClickCounter === 1
                        && cutFrameClickedButton === CUT_FRAME_SUPER_UNDO)
                            str = getCutFrameOKString();
                        else
                            str = "Super-undo (f2, f7)";
                    }
                    break;

                    case "cutPrevDataButton":
                    {
                        if(cutFrameClickCounter === 1
                        && cutFrameClickedButton === CUT_FRAME_DELETE_FRONT)
                            str = getCutFrameOKString();
                        else
                            str = "Delete front data (f3, f8)";   
                    }
                    break;

                    case "gridButton":
                        str = "Grid (f1, f6)";
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
                        str = "Right sidebar (f2, f7)";
                    break;

                    case "sideBarPositionButton2":
                        str = "Left sidebar (f2, f7)";
                    break;

                    case "topBarColorButton":
                        str = "Change UI color (f3, f8)";
                    break;

                    case "aboutButton":
                        str = "About";
                    break;

                    case "updateButton":
                        str = "Version " + NEW_VERSION + " released!";
                       
                    break;

                    case "drawModeButton":str = "Draw mode (1, 7)"; break;
                    case "replayModeButton":str = "Replay mode (2, 8)"; break;
                    case "toolBoxONButton":str = "Tool-box ON/OFF"; break;
                    case "replayZoomInButton":str = "Zoom in"; break;
                    case "replayZoomOutButton":str = "Zoom out"; break;
                    case "replayRotateButton":str = "Rotate"; break;

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

        private function resetReplayDataFile(overWrite:Boolean = false):void //기본 리플레이 파일 만들어줌
        {
            const hey:Boolean = repFile.exists;

            if(hey === false || overWrite === true)
            {
                const fs:FileStream = new FileStream();
                fs.open(repFile,FileMode.WRITE);
                fs.close();

                if(rJumpImageFolder.exists)
                    rJumpImageFolder.deleteDirectory(true);

                rJumpImageFolder.createDirectory();
                updateFirstImage(canvas1BitmapData,CANVAS_BG_COLOR);
            }
        }

        private function resetJumpImage():void
        {
            const fs:FileStream = new FileStream();
            const file:File = rJumpImageFolder.resolvePath("0");
            fs.open(file,FileMode.READ);
            const data:Array = fs.readObject() as Array;
            fs.close();
            data[0].uncompress();
            var bmpd:BitmapData = new BitmapData(data[1],data[2],true,0);
            const newRectangle:Rectangle = new Rectangle(0,0,data[1],data[2]);
            
            bmpd.lock();
            bmpd.setPixels(newRectangle,data[0]);
            bmpd.unlock();

            rcanvas1BitmapData.dispose();
            rcanvas1BitmapData = bmpd.clone();
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
            bmpd.dispose();
            bmpd = null;

            changeCanvasSizeReplayMode(rcanvas1Bitmap.width,rcanvas1Bitmap.height);
            setBackgroundColorReplayMode(data[3]);
        }

        private function updateFirstImage(bmpd:BitmapData=null,bgColor:uint=0):void //리플레이 처음 이미지 만들어줌
        {
            const fs:FileStream = new FileStream();
            const ba:ByteArray = new ByteArray;
            const w:int = bmpd.width;
            const h:int = bmpd.height;
            const newRectangle:Rectangle = new Rectangle(0,0,w,h);

            rJumpImageFrameData = [0];

            bmpd.copyPixelsToByteArray(newRectangle,ba);
            ba.compress();
            rFirstImage = bmpd.clone();
            rFirstBGColor = bgColor;

            fs.open(rFirstImageFile,FileMode.WRITE);
            fs.writeObject([ba,w,h,bgColor,0,0]); //첫번째 이미지가 bytearray임
            fs.close();
            ba.clear();
        }

        private function resetUndo():void
        {
            undoIndex = -1;
            addUndoMode = 0;
            undoData.setUndoRefImageByDrawMode();
            rData = [];
            rDataFrame = [];
            rDataBuffer = [];
            readyAddUndo = false;
            replayONUndoUpdate = false;
            undoDelFlag = false;
        }

        //창크기에 맞추어서 캔버스를 축소해줌
        private function canvasFitWindow(captureMode:Boolean=false):void
        {
            const replayMode:Boolean = replayModeON;
            const offsetX:Number = 40;
            const offsetY:Number = (captureMode) ? topBar.BARSIZE+40 : topBar.BARSIZE+replayTimeBox.BARSIZE+40;
            const stw:int = stage.stageWidth-offsetX;
            const sth:int = stage.stageHeight-offsetY;
            var xBitmap:Bitmap;
            var xReg:Sprite;
            var w:Number;
            var h:Number;
            var _captureRotated:uint;

            if(replayMode)
            {
                xBitmap = rcanvas1Bitmap;
                xReg = rregPoint;
                w = RCANVAS_WIDTH;
                h = RCANVAS_HEIGHT;
            }
            else
            {
                xBitmap = canvas1Bitmap;
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
            else xReg.rotation = 0;

            if(replayMode === true && z < 1.0)
                replayEndWithcanvasFitWindow = true;
            
            setZoomCanvas(z,replayMode);
            setCenvasCenterPos(replayMode,captureMode);
            xBitmap.smoothing = true;

            if(captureMode)
            {
                drawCaptureArea.updateCaptureAreaLineSize();
                if(topBar.topMenuInfo.visible)
                {
                    topBar.hint(topBar.topMenuInfo.text,topBar.capOff);
                }
            }
        }

        private function replayCompleteEffect():void
        {
            const _replayTimeBox:replayTimeBar = replayTimeBox;
            _replayTimeBox["playButton"].visible = true;
            _replayTimeBox["pauseButton"].visible = false;

            setColorTransform(_replayTimeBox["replayNowBar"],uiColorSet[uiColorIndex][4]);
            
            //재생이 끝나면 전체화면을 보여줌
            if(!mouseClickON)
            {
                canvasFitWindow();
                rzoomedIndex = zoomArr.indexOf(1.0);
            }
        }

        private function restartTimerCancel():void
        {
            const info:TextField = replayTimeBox["frameInfo"];
            clearInterval(rRestartTimer);

            //재시작 카운터가 돌아갈때 1프레임 스킵을 하면
            //프레임 정보가 나오지 않고 END가 나와서 조건 걸어줌
            if(rRestartTimerCount < 10)
            {
                info.text = "Playback finished";
            }
            rRestartTimerCount = 10;
            replayTimeBox.resetNowbarColor();
        }

        private function setRestartTimer():void
        {
            rRestartTimerCount = 10;
            
            function restartTimerCancelEvent(e:Object):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,restartTimerCancelEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,restartTimerCancelEvent);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN,restartTimerCancelEvent);
                restartTimerCancel();
            }

            stage.addEventListener(MouseEvent.MOUSE_DOWN,restartTimerCancelEvent);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,restartTimerCancelEvent);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,restartTimerCancelEvent);
            clearInterval(rRestartTimer);

            rRestartTimer = setInterval(function():void
            {
                if(rRestartTimerCount === 0)
                {
                    restartTimerCancel();
                    startReplay();
                    return;
                }
                const str:String = "Playback restarts in " + rRestartTimerCount +" sec";
                replayTimeBox["frameInfo"].text = str;
                --rRestartTimerCount;
            },1000);
        }

        //total frame file max frame등등은 수동으로 초기화
        //이건 리플레이 시간을 초기화 시켜주는것 뿐임 데이터는 건드리지 않음
        private function resetReplayTime():void
        {
            //어떤 이유가 있어서 rDataReadFlag는 여기 넣으면 안됨 수동으로 조절
            rIndex = 0;
            rLastBytes = 0;
            rNowFrame = 0;
            rPrevFrame = 0;
            rJumpImageIndexSave = -2;
            replayAllEnd = true;
            replayONUndoUpdate = false;
            // replayModeONFirstJump = true;
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
        }

        private function setReplaySubLayer(flag:Boolean):void
        {
            if(flag !== rSubLayerSave)
            {
                rSubLayerSave = flag;
                if(flag) rcanvasPanel.setChildIndex(rcanvas1,1);
                else rcanvasPanel.setChildIndex(rcanvas2,1);
            }
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
            rcanvas2BitmapData = new BitmapData(w,h,true,0);

            RCANVAS_WIDTH = w;
            RCANVAS_HEIGHT = h;

            if(movedFlag)
            {
                //movex y는 캔버스 사이즈 조절에서 원점이 움직였을경우 그만큼 bitmapdata를 움직여줘야 원래 이미지대로 나옴
                var mat:Matrix = new Matrix();
                mat.translate(moveX,moveY);
                rcanvas1BitmapData.draw(rcanvas1Bitmap,mat);
            }
            else rcanvas1BitmapData.draw(rcanvas1Bitmap);
            

            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;

            updateReplayCanvasBounds();
            checkCanvasPanelPos(true);
        }

        private function replayMoveImage(x:Number,y:Number):void
        {
            var tempBitData:BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
            var movedMat:Matrix = new Matrix();

            movedMat.translate(x,y);

            //최종적으로 움직인 거리를 실제로 비트맵 데이터 조작
            tempBitData.draw(rcanvas1BitmapData,movedMat);
            rcanvas1BitmapData = tempBitData.clone();
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
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

        private function replayMirrorCanvas():void
        {
            var mirrorBMPD:BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
            var flipMat:Matrix = new Matrix(-1,0,0,1,RCANVAS_WIDTH);

            mirrorBMPD.draw(rcanvas1BitmapData,flipMat);
            rcanvas1BitmapData = mirrorBMPD.clone();
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
            mirrorBMPD.dispose();
            mirrorBMPD = null;

            rMirrorON = !rMirrorON;
        }

        private function cTickDraw():Object
        {
            const cd2:Graphics = rcanvas2Draw.graphics;
            const rTinyCursorPos:Point = new Point(0,0);

            var lineStyleBackup:Array; //tempdone에서 쓰는 플래그임
            var index:uint;
            var data:Array; //데이터 뭉치
            var d:Array; // 데이터 뭉치안에 데이터 뭉치
            
            function updateLineStyleBackup(arr:Array):void
            {
                lineStyleBackup = arr;
            }

            function updateRCursorPos():void
            {
                rCursor.x = rTinyCursorPos.x;
                rCursor.y = rTinyCursorPos.y;
            }

            function resetgetRCursorPos():void
            {
                rTinyCursorPos.setTo(0,0);
            }

            function setRCursorPos(x:Number,y:Number):void
            {
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
                if(lineStyleBackup.length !== 2) return [1.0,]
                
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

                if((replayStartON && subLayer) !== null) setReplaySubLayer(subLayer);

                if(airBrush === true)
                {
                    if(airBrushSizeReplayMode !== size) setBlurCanvasBySizeReplayMode(size);
                }
                else if(airBrushSizeReplayMode > 0) resetCanvasBlurReplaymode();

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
                cd2.drawPath(command, xyData);
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
                setRCursorPos(xyData[0],xyData[1]);
            }

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
                setRCursorPos(arr[0],arr[1]);
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

                if((replayStartON && subLayer) !== null)
                {
                    setReplaySubLayer(subLayer);
                }

                if(airBrush === true)
                {
                    if(airBrushSizeReplayMode !== size) setBlurCanvasBySizeReplayMode(size);
                }
                else if(airBrushSizeReplayMode > 0) resetCanvasBlurReplaymode();

                updateLineStyleBackup([alpha,blendMode]);
                rcanvas2.alpha = alpha;
                cd2.lineStyle(0,0,0);
                cd2.beginFill(color);

                if(shape) cd2.drawRect(startX-size/2,startY-size/2,size,size);
                else cd2.drawCircle(startX,startY,size/2);
                
                setRCursorPos(startX,startY);
                cd2.endFill();
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

                rcanvasPanel.setChildIndex(rcanvas2,1);
                updateLineStyleBackup([alpha,blendMode]);
                rcanvas2.alpha = alpha;

                if((replayStartON && subLayer) !== null) setReplaySubLayer(subLayer);

                if(airBrush)
                {
                    if(airBrushSizeReplayMode !== size) setBlurCanvasBySizeReplayMode(size);
                }
                else if(airBrushSizeReplayMode > 0) resetCanvasBlurReplaymode();

                if(shape) cd2.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
                else cd2.lineStyle(size,color);

                cd2.moveTo(startX,startY);
                cd2.lineTo(endX,endY);
                setRCursorPos(endX,endY);
            }

            function move(data:Array):void
            {
                const moveX:Number = data[1];
                const moveY:Number = data[2];

                replayMoveImage(moveX,moveY);
            }
            
            function lasso(data:Array):void
            {
                const lsbox:Sprite = lassoBox;
                const point1:Vector.<Number> = data[1];
                const point2:Array = data[2];

                if(point1.length === 0 || point2.length === 0) return;

                const lassoInfo:Array = data[3];
                const copyFlag:Boolean = data[4];
                const bmpScaleX:Number = lassoInfo[0];
                const bmpScaleY:Number = lassoInfo[1];
                const bmpWidth:Number = lassoInfo[2];
                const bmpHeight:Number = lassoInfo[3];
                const bmpAngle:Number = lassoInfo[4];
                const boxX:Number = lassoInfo[5];
                const boxY:Number = lassoInfo[6];

                function resetLassoBox2():void
                {
                    lassoBMP.filters = [];

                    if(lassoBMP.bitmapData)
                    {
                        lassoBMP.bitmapData.dispose();
                        lassoBMP.bitmapData = null;
                    }

                    lsbox.x = 0;
                    lsbox.y = 0;
                    lsbox.scaleX = 1.0;
                    lsbox.scaleY = 1.0;
                    lsbox.rotation = 0;
                    lsbox.visible = false;
                }

                const lassoDone:Boolean = doLassoDraw(true,point1,point2,copyFlag);
                if(!lassoDone)
                {
                    resetLassoBox2();
                    return;
                }

                var posMatrix:Matrix = new Matrix();
                posMatrix.scale(bmpScaleX,bmpScaleY);
                posMatrix.translate(-bmpWidth/2,-bmpHeight/2);
                posMatrix.rotate(bmpAngle);
                posMatrix.translate(boxX,boxY);

                lassoBMP.smoothing = true;

                if(bmpScaleX !== 1 || bmpAngle !== 0)
                    applyLassoShapen(bmpScaleX);

                rcanvas1BitmapData.draw(lassoBMP,posMatrix);
                rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                resetLassoBox2();
            }

            function mirror():void
            {
                replayMirrorCanvas();
            }

            function bgColor(data:Array):void
            {
                const color:uint = data[1];

                rBGColorSave = color;
                setBackgroundColorReplayMode(color);
            }

            function canvasSize(data:Array):void
            {
                const width:Number = data[1];
                const height:Number = data[2];
                const moveX:Number = data[3];
                const moveY:Number = data[4];
                const movedFlag:Boolean = data[5];

                changeCanvasSizeReplayMode(width,height,moveX,moveY,movedFlag);
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
                    const subLayerBmpd:BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
                    subLayerBmpd.draw(rcanvas2Bitmap,null,canvasAlpha);
                    subLayerBmpd.draw(rcanvas1Bitmap);
                    rcanvas1BitmapData = subLayerBmpd.clone();
                    rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                    subLayerBmpd.dispose();
                }
                else
                {
                    rcanvas1BitmapData.draw(rcanvas2Bitmap,null,canvasAlpha,lineStyleData[1]);
                    rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                }

                rcanvas2Bitmap.bitmapData = null;
                rcanvas2BitmapData.dispose();
                rcanvas2BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);

                cd2.clear();
            }

            function clear(data:Array):void
            {
                rcanvas1BitmapData.dispose();
                rcanvas1BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
                rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
            }

            function next():void
            {
                if(!data || data.length === 0) return;

                d = data[index];
                index++;
                switch(d[0] as String)
                {
                    case "lineStyle": lineStyle(d); break;
                    case "lineTo": lineTo(d); break;
                    case "sqline": sqline(d); break;
                    case "fill": fill(d); break;
                    case "fill2": fill2(d); break;
                    case "dot": dot(d); break;
                    case "line": line(d); break;
                    case "move": move(d); break;
                    case "lasso": lasso(d); break;
                    case "mirror": mirror(); break;
                    case "bgColor": bgColor(d); break;
                    case "canvasSize": canvasSize(d); break;
                    case "tempDone": tempDone(d); break;
                    case "drawDone": drawDone(d); break;
                    case "clear": clear(d); break;
                }
            }

            return {
                next:next,
                drawAll:drawAll,
                ready:ready,
                reset:reset,
                setIndex:setIndex,
                getIndex:getIndex,
                isIndexSmallerData:isIndexSmallerData,
                isIndexBiggerData:isIndexBiggerData,
                getDataLength:getDataLength,
                getRestDataCount:getRestDataCount,
                getrLineStyleSave:getrLineStyleSave,
                getLineStyleAlpha:getLineStyleAlpha,
                getRCursorPos:getRCursorPos,
                setRCursorPos:setRCursorPos,
                resetgetRCursorPos:resetgetRCursorPos,
                updateRCursorPos:updateRCursorPos,
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

            const nt:int = getTimer();
            
            if(nt - rFrameTextDelayTime >= 500)
            {   
                const nextFrame:Number = getAutoJumpFrame(rSpeed);
                const finalFrame:Number = rNowFrame+Math.floor(nextFrame/2);
                const totalF:Number = TOTAL_FRAME;
                const _rFrameSum:Number = rNowFrame;
                const getTimeStr:String = getReplayRemainTime(nextFrame,totalF-_rFrameSum,true);
                const timeStr:String = getTimeStr;

                _jumpFrame(finalFrame,JUMP_FRAME_ONCE); 
                replayTimeBox["frameInfo"].text = _rFrameSum+" / " + totalF + timeStr;
                rFrameTextDelayTime = nt;
            }
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
            const _CACHE_DIV_10:Number= Math.floor(IMG_CACHE_INTERVAL/10);
            const _tickDraw:Object = tickDraw;
            const _JUMP_FRAME_PLAY:int = JUMP_FRAME_PLAY;
            const _JUMP_FRAME_ONCE:int = JUMP_FRAME_ONCE;
            const _JUMP_FRAME_BEFORE:int = JUMP_FRAME_BEFORE;
            const _JUMP_FRAME_AFTER:int = JUMP_FRAME_AFTER;
            
            var rDataLen:uint;
            var prevJumpImageSaveCount:Number;
            var prevJumpImageSaveIndex:uint;
            var savedTime:int;
            var rFrameCursorDelayTime:int = 0; //커서 딜레이
            var _rFrameTextDelayTime:int = 0; //프레임 바 딜레이
            var getTimeStr:String;
            var timeStr:String;
            var readCount:Number = 0;
            var jumpImageGroupIndex:int;
            var _undoIndex:int = 0;

            function checkMakeCacheImage(jumpFlag:int):void
            {
                if(jumpFlag === _JUMP_FRAME_ONCE || jumpFlag === _JUMP_FRAME_BEFORE)
                {
                    if(prevJumpImageSaveCount >= _CACHE_DIV_10)
                    {
                        prevJumpImageSaveCount = 0;
                        if(!rDataPreviewCacheImages[prevJumpImageSaveIndex])
                        {
                            rDataPreviewCacheImages[prevJumpImageSaveIndex] = [rcanvas1BitmapData.clone(),rcanvas1BitmapData.width,rcanvas1BitmapData.height,RCANVAS_BG_COLOR,rFileCutBytes,rNowFrame];
                        }
                        prevJumpImageSaveIndex++;
                    }
                }
            }

            function readyToReadRData(jumpFlag:int):void
            {
                _undoIndex = undoIndex;
                if(_undoIndex < 0)
                {
                    rDataReadFlag = false;
                    _tickDraw.reset();
                    return;
                }

                rDataReadFlag = true;
                rIndex = 0;
                rDataLen = rData.length;

                if(undoData.getRFileTotalFrame() !== rNowFrame)//다시한번 체크하고 갱신해줌
                {
                    undoData.setRFileTotalFrame(rNowFrame);
                    TOTAL_FRAME = getTotalFrame();
                }

                if(jumpFlag === _JUMP_FRAME_PLAY)
                {
                    _rfs.close();
                    rLastBytes = 0;
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
                    rFileCutBytes = rLastBytes;
                    rLastBytes = _rfs.position;
                    rPrevFrame = rNowFrame;
                    return false;
                }
                return true;
            }

            function checkFinish(jumpFlag:int):Boolean
            {
                if(rIndex > undoIndex || rDataLen === 0) //자연적 으로 끝났을때
                {
                    if(mirrorPushReady) replayMirrorCanvas();

                    tcursor.visible = false;
                    replayAllEnd = true;

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
                if(jumpFlag === _JUMP_FRAME_PLAY)
                {
                    savedTime = getTimer();

                    if(savedTime-rFrameCursorDelayTime >= 100)
                    {
                        rFrameCursorDelayTime = savedTime;
                        
                        tickDraw.updateRCursorPos();

                        if(!mouseClickON && isDeepUndoON === false)
                        {
                            checkAutoScroll.check();
                        }
                    }

                    if(savedTime-_rFrameTextDelayTime >= 1000) //갱신 느리게 해줌
                    {
                        _rFrameTextDelayTime = savedTime;
                        updateReplayRemainTime();
                    }
                }
                else if(doDrawSlowEventON === false)
                {
                    updateReplayRemainTime();
                }

                if(!rJumpMouseON)
                {
                    replayTimeBox["replayNowBar"].width = replayTimeBox["replayTotalBar"].width*rNowFrame/TOTAL_FRAME;
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
                for(var i:Number=0;i<len;i++)
                {
                    if(_tickDraw.isIndexBiggerData())
                    {
                        if(setFileDataToTickDraw() === true)
                        {
                            //더이상 읽을 데이터가 없을때 rdata 읽기로 넘겨줌
                            readyToReadRData(jumpFlag);
                            return;
                        }
                        checkMakeCacheImage(jumpFlag);
                    }
                    tickDraw.next();
                    prevJumpImageSaveCount++;
                    rNowFrame++;
                    readCount--;
                }
            }

            return function(jumpCount:Number,jumpFlag:int):void
            {
                if(jumpCount > 0)
                {
                    //REPLAY_SLOWDRAW_ACTIVE_SPEED 이상으로 전체 재생 시간이 60초 이하일경우 작동
                    if(jumpFlag === _JUMP_FRAME_PLAY && jumpCount > _REPLAY_SLOWDRAW_ACTIVE_SPEED)
                    {
                        if(REPLAY_FASTEST_TOTAL_TIME > REPLAY_FASTEST_LIMIT_TIME)
                        {
                            setSlowDraw();
                            return;
                        }
                    }

                    prevJumpImageSaveCount = 0;
                    prevJumpImageSaveIndex = 0;
                    readCount = jumpCount;

                    if(!rDataReadFlag) drawFileData(jumpCount,jumpFlag);
                    drawRData(readCount,jumpFlag);
                }
                updateCursorPosAndInfoText(jumpFlag);
            };
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

        //autoscroll check에서 계속 갱신해주면 부하 걸릴거같아서 줌하거나 캔버스 사이즈 조절되거나
        //할때 특정 조건에서만 업데이트 시키는거임
        private function updateReplayCanvasBounds():void
        {
            checkAutoScroll.updateRCanvasBounds();
        }

        private function cAutoScroll():Object
        {
            const abs:Function = Math.abs;
            const floor:Function = Math.floor;
            const offsetY:Number = topBar.BARSIZE+replayTimeBox.BARSIZE;
            const _rregPoint:Sprite = rregPoint;
            const zerop:Point = new Point(0,0);
            const padding:Number = 15;
            const leftLimit:Number = padding;
            const topLimit:Number = padding+offsetY;
            const cursorPos:Point = new Point(0,0);
            const windowCenterPos:Point = new Point(0,0); //캔버스 중점위치, 창 중점위치 사이 거리

            var stw:Number;
            var sth:Number; //프레임 탐색막대 길이 빼줌
            var b:Object; //바운드 저장하는 객체
            var left:Number; //바운드 상하좌우
            var right:Number;
            var top:Number;
            var bottom:Number;
            var globalChecked:Boolean;
            var g:Point; //캔버스 글로벌 좌표
            var rg:Point; //캔버스 회전된 글로벌 좌표
            var z:Number;
            //rcanvas1 글로벌 좌표에 회전된 캔버스에서 커서 위치를 더해줌. 즉 윈도우 기준에서 커서 커서 위치를 구하는거임
            var isCanvasWidthSmallerStage:Boolean; //캔버스 가로 새로 길이가 스테이지 길이보다 클때 체크
            var isCanvasHeightSmallerStage:Boolean;
            var isNotCenterX:Boolean; //캔버스 중점위치, 창 중점위치 사이 거리
            var isNotCenterY:Boolean;
            var rightLimit:Number;
            var bottomLimit:Number;

            function updateRCanvasBounds():void
            {
                b = getBoundRect(rcanvas1);
                left = b.left;
                right = b.right;
                top = b.top;
                bottom = b.bottom;
                stw = stage.stageWidth;
                sth = stage.stageHeight-offsetY;
                z = rzoomed;

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
                const p:Point = tickDraw.getRCursorPos();

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
                    g = rcanvas1.localToGlobal(zerop);
                    rg = rotatePoint(p.x,p.y,-_rregPoint.rotation);
                    cursorPos.x = g.x+(rg.x*z);

                    if(cursorPos.x < leftLimit)
                    {
                        _rregPoint.x += floor(abs((cursorPos.x-stw/2)/4));
                        updateReplayCanvasBounds(); 
                    }
                    else if(cursorPos.x > rightLimit)
                    {
                        _rregPoint.x -= floor(abs((cursorPos.x-stw/2)/4));
                        updateReplayCanvasBounds();
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
                        g = rcanvas1.localToGlobal(zerop);
                        rg = rotatePoint(p.x,p.y,-_rregPoint.rotation);
                    }
                    cursorPos.y = g.y+(rg.y*z);

                    if(cursorPos.y < topLimit)
                    {
                        _rregPoint.y += floor(abs((cursorPos.y-sth/2)/4));
                        updateReplayCanvasBounds();
                    }
                    else if(cursorPos.y > bottomLimit)
                    {
                        _rregPoint.y -= floor(abs((cursorPos.y-sth/2)/4));
                        updateReplayCanvasBounds();
                    }
                }
            }

            return {
                check:check,
                updateRCanvasBounds:updateRCanvasBounds
            };
        }

        private function isSlowDrawTime(speed:Number):Boolean
        {
            return speed > REPLAY_SLOWDRAW_ACTIVE_SPEED
                                 && REPLAY_FASTEST_TOTAL_TIME > REPLAY_FASTEST_LIMIT_TIME;
        }

        private function updateReplayRemainTime():void
        {
            var _rSpeed:Number = (isSlowDrawTime(rSpeed))
                                 ? getAutoJumpFrame(rSpeed)/STAGE_FRAME : rSpeed;
                                //오토스킵은 1초마다 넘어가야할 프레임이니까 시간 구하려면 스테이지 프레임을 나누어줌

            const totalF:Number = TOTAL_FRAME;
            const _rFrameSum:Number = rNowFrame;
            const namojiTime:String = (isDeepUndoON)
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

            if(totalF <= STAGE_FRAME*3)
            {
                return;
            }

            const topBar:topMenu = topBar;
            const abs:Function = Math.abs;
            const floor:Function = Math.floor;
            const set:Sprite = topBar.replaySpeedSet;
            const minDist:Number = topBar["replaySpeedBar"].x+2;
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
                const finalStr:String = "Playback speed x"+rSpeed+" "+ timeStr;
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
                if(replayAllEnd === false) updateReplayRemainTime();
                stageMouseMoveEvent.remove(replaySpeedButtomMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,replaySpeedButtomUpEvent);
            }

            function replaySpeedButtomMoveEvent(e:MouseEvent):void
            {
                moveButton(set.mouseX);
            }
            moveButton(set.mouseX);
            setSpeed(set.mouseX);

            stageMouseMoveEvent.add(replaySpeedButtomMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,replaySpeedButtomUpEvent);
        }

        private function getTotalFrame():Number
        {
            var totalF:Number = undoData.getRFileTotalFrame();
            const _rDataFrame:Array = rDataFrame;
            var rDataSum:Number = 0;
            var aa:uint;

            for(var i:int=0,len:int=undoIndex;i<=len;i++)
            {
                aa = _rDataFrame[i];
                rDataSum += aa;
            }
            const sum:Number = totalF+rDataSum;
            return sum;
        }

        //targetFrame이 rDataPreviewCacheImages데이터에 몆 번 인덱스에 있나 구해줌
        private function getCacheImageIndex(targetFrame:Number):Number
        {
            const arr:Array = rDataPreviewCacheImages;
            var low:Number = 0;
            var high:Number = arr.length-1;
            if(high === 0)  return 0;
            var index:Number = Math.floor((low + high)/2);

            while(low <= high)//2진 탐색
            {
                const indexFrame:Number = arr[index][5];

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
            if(high === 0) return 0;
            var index:Number = Math.floor((low + high)/2);

            while(low <= high)//2진 탐색
            {
                const indexFrame:Number = arr[index];

                if(indexFrame === targetFrame) break;
                else if(indexFrame > targetFrame) high = index-1;
                else low = index+1;

                index = Math.floor((low + high)/2);
            }
            return index;
        }
        
        //프레임에 따라서 프레임 조작 버튼 활성화 해줌
        private function checkCutFrameButtons():void
        {
            const tb:Sprite = topBar;
            const rSum:Number = rNowFrame;

            if(rSum > 0 && rSum < TOTAL_FRAME)
            {
                tb["superUndoButton"].alpha = 1.0;
                tb["cutPrevDataButton"].alpha = 1.0;
            }
            else
            {
                tb["superUndoButton"].alpha = BUTTON_OFF_ALPHA;
                tb["cutPrevDataButton"].alpha = BUTTON_OFF_ALPHA;
            }

            if(rSum === TOTAL_FRAME) tb["reRecordingButton"].alpha = BUTTON_OFF_ALPHA;
            else tb["reRecordingButton"].alpha = 1.0;
        }

        private function _jumpOneFrame(toback:Boolean,trueOneFrame:Boolean):void
        {
            if(trueOneFrame)
            {
                if(toback && rNowFrame > 0) _jumpFrame(rNowFrame-1,JUMP_FRAME_ONCE);
                else if(!toback && rNowFrame < TOTAL_FRAME) _jumpFrame(rNowFrame+1,JUMP_FRAME_ONCE);
            }
            else
            {
                if(toback && rNowFrame > 0)
                {
                    //rPrevFrame이 rNowFrame이 같게되면 jumpframe에서 0프레임을 이동하므로
                    //-1을 해줘서 tickdarw에서 이전 데이터를 가지게 해줘야함
                    if(rPrevFrame === rNowFrame) _jumpFrame(rNowFrame-1,JUMP_FRAME_BEFORE);
                    _jumpFrame(rPrevFrame,JUMP_FRAME_BEFORE);
                }
                else if(!toback && rNowFrame <= TOTAL_FRAME)
                {
                    if(tickDraw.getRestDataCount() === 0)
                    {
                        //+1해줘서 다음 데이터 갱신해주고 나머지 끝까지 그려줌
                        _jumpFrame(rNowFrame+1,JUMP_FRAME_AFTER);
                        _jumpFrame(rNowFrame+tickDraw.getRestDataCount(),JUMP_FRAME_AFTER);
                    }
                    else
                    {
                        _jumpFrame(rNowFrame+tickDraw.getRestDataCount(),JUMP_FRAME_AFTER);
                    }
                }
            }

            rOnejumpFlagSave = toback;
            checkCutFrameButtons();
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
            clearTimeout(keyHoldTimer);
            clearInterval(keyHoldTimer);
            keyHoldTimer = 0;
            stage.nativeWindow.removeEventListener(Event.DEACTIVATE,cancelAutoKeyEvent);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,cancelAutoKeyEvent);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,cancelAutoKeyEvent);
            stage.removeEventListener(MouseEvent.MOUSE_UP,cancelAutoKeyEvent);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,cancelAutoKeyEvent);
            stage.removeEventListener(KeyboardEvent.KEY_UP,cancelAutoKeyEvent);
        }

        private function setJumpOneFrame(prev:Boolean,oneFrame:Boolean=false):void
        {
            if(setHoldKeyRepeat(_jumpOneFrame,prev,oneFrame) === true)
            {
                if(cutFrameClickCounter > 0) resetCutFrameClickCounter();
                if(replayStartON) stopReplay();
            }
        }

        private function checkExitDeepUndo(flag:int):Boolean
        {
            if(isDeepUndoON && flag === JUMP_FRAME_AFTER && rNowFrame === TOTAL_FRAME)
            {
                exitDeepUndoMode();
                return true;
            }
            return false;
        }

        private function _jumpFrame(frame:Number,jumpflag:int):void //jumpp 
        {
            if(frame < 0) frame = 0;
            else if(frame > TOTAL_FRAME) frame = TOTAL_FRAME;
            if(checkExitDeepUndo(jumpflag)) return;

            const nowFrame:Number = rNowFrame;
            const prevjumpFlag:Boolean = frame < nowFrame;
            const index:Number = getJumpImageIndex(frame);
            var prevJumpImageIndex:Number = 0; //자잘 썸네일 인덱스를 넣어줌
            var jumpImageData:Array = [];
            var tempBmpd:BitmapData = new BitmapData(1,1,true,0);

            rFileStream.open(repFile,FileMode.READ);

            if(index !== rJumpImageIndexSave) rDataPreviewCacheImages = [];
            else if(rDataPreviewCacheImages.length > 0) prevJumpImageIndex = getCacheImageIndex(frame);

            if(index !== rJumpImageIndexSave || prevjumpFlag)
            {
                if(prevJumpImageIndex > 0)//prevjumpFlag && false)
                {
                    jumpImageData = rDataPreviewCacheImages[prevJumpImageIndex];
                    tempBmpd = jumpImageData[0];
                }
                else
                {
                    const file:File = rJumpImageFolder.resolvePath(index+"");
                    const fs:FileStream = new FileStream();
                    fs.open(file,FileMode.READ);
                    jumpImageData = fs.readObject() as Array;
                    fs.close();
                    jumpImageData[0].uncompress();
                    tempBmpd = new BitmapData(jumpImageData[1],jumpImageData[2],true,0);
                    tempBmpd.lock();
                    tempBmpd.setPixels(new Rectangle(0,0,jumpImageData[1],jumpImageData[2]),jumpImageData[0]);
                    tempBmpd.unlock();
                }

                rJumpImageIndexSave = index;
                rLastBytes = jumpImageData[4]; //마지막 바이트
                rFileStream.position = jumpImageData[4];
                rNowFrame = jumpImageData[5]; //썸네일 이미지를 저장한 프레임
                //원하는 프레임에서 썸네일 이미지 프레임을 빼줌 나머지 프레임만 그려주면 되니깐
                frame = frame-jumpImageData[5]; 
                rDataReadFlag = false;
                rIndex = 0; //이거 먼저 초기화 시켜주어야함
                tickDraw.reset();
                clearCanvasReplayMode();
                rMirrorON = false;

                rcanvas1BitmapData.dispose();
                rcanvas1BitmapData = tempBmpd.clone();
                rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                changeCanvasSizeReplayMode(rcanvas1Bitmap.width,rcanvas1Bitmap.height);
                setBackgroundColorReplayMode(jumpImageData[3]);
            }
            else //점프 프레임이 기존 프레임 이후일때는 계속 그림
            {
                if(!rDataReadFlag) rFileStream.position = rLastBytes;
                frame = frame - nowFrame;
            }

            doDraw(frame,jumpflag);
            rFileStream.close();
            
            //dodraw밑이기 때문에 rFrameSum이 갱신되서 위에 nowFrame은 쓸수가 없음
            if(rNowFrame >= TOTAL_FRAME)
            {
                replayAllEnd = true;
                rCursor.visible = false;
                //보통 스킵일때 마지막 임시 mirror가 켜져있을때 여기서 해줌
                //스킵이 너무 딱맞게 되서 마지막을 안하나?
                if(mirrorPushReady !== rMirrorON)
                {
                    replayMirrorCanvas();
                }
            }
            else
            {
                replayAllEnd = false;
                tickDraw.updateRCursorPos();
                rCursor.visible = true;
            }
            if(checkExitDeepUndo(jumpflag)) return;
            if(!isDeepUndoON) checkAutoScroll.check();
        }

        //데이터를 읽다 말았으면 끝까지 한세트 끝나게 프레임 이동시킴
        private function drawRemainReplayData():void
        {
            _jumpFrame(rNowFrame+tickDraw.getRestDataCount(),JUMP_FRAME_ONCE);
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
            const totalBar:Sprite = replayTimeBox["replayTotalBar"] as Sprite;
            const totalBarScale:Number = totalBar.scaleX;
            const nowBar:Sprite = replayTimeBox["replayNowBar"] as Sprite;
            const maxWidth:Number = totalBar.width;//replayPrograssBaseBarWidth*scaleX;
            var clickedX:Number = totalBar.mouseX*totalBarScale;
            var jumpUpdateTimer:uint = 0;
            var oldFrame:Number = floor(totalF*clickedX/maxWidth);
            var finalFrame:Number = 0;

            rJumpMouseON = true;
            nowBar.width = clickedX;
            checkBarLimit();
            oldFrame = finalFrame;;

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
                rJumpMouseON = false;
                clearTimeout(jumpUpdateTimer);
                _jumpFrame(finalFrame,JUMP_FRAME_ONCE);
                if(isDeepUndoON)
                {
                    if(tickDraw.isIndexSmallerData()) 
                    {
                        drawRemainReplayData();
                    }
                }

                jumpUpdateTimer = 0;
                oldFrame = finalFrame;
                checkBarLimit();

                if(!isDeepUndoON)
                {
                    //jumpframe함수 이후에 실행
                    if(!replayStartONSave) checkCutFrameButtons();

                    //재생중에 스킵하고 있었으면 다시 시작
                    
                    if(replayStartONSave && !replayAllEnd)
                    {
                        startReplay();
                    }
                    else if(replayAllEnd) stopReplay();
                }

                stageMouseMoveEvent.remove(replayTimeMouseMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,replayTimeMouseUpEvent);
            }

            function replayTimeMouseMoveEvent(e:MouseEvent):void
            {
                checkBarLimit();
                
                if(jumpUpdateTimer === 0)
                {
                    clearTimeout(jumpUpdateTimer);
                    jumpUpdateTimer = setTimeout(function():void
                    {
                        jumpUpdateTimer = 0;
                        oldFrame = finalFrame;
                        _jumpFrame(finalFrame,JUMP_FRAME_ONCE);
                    },200);
                }
            }

            stage.addEventListener(MouseEvent.MOUSE_UP,replayTimeMouseUpEvent);
            stageMouseMoveEvent.add(replayTimeMouseMoveEvent);
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
            checkCutFrameButtons();
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

            replayTimeBox["playButton"].visible = false;
            replayTimeBox["pauseButton"].visible = true;
            tb["reRecordingButton"].alpha = 1.0;
            tb["superUndoButton"].alpha = 1.0;
            tb["cutPrevDataButton"].alpha = 1.0;

            rCursor.visible = true;

            if(replayAllEnd === true) //리플레이 시간 등등 초기화 시키고 시작
            {
                resetReplayTime();
                clearCanvasReplayMode();
                resetJumpImage();
                rDataReadFlag = false;
                replayAllEnd = false;//resetReplayTime함수 에서 이걸 true로 해주기 때문에 아래쪽에서 변경
            }

            if(replayEndWithcanvasFitWindow === true)
            {
                replayEndWithcanvasFitWindow = false;
                setZoomCanvas(rzoomed,true);
            }

            if(!rDataReadFlag)
            {
                rFileStream.open(repFile,FileMode.READ);
                rFileStream.position = rLastBytes;
            }
            
            if(cutFrameClickCounter > 0) resetCutFrameClickCounter();

            stage.addEventListener(Event.ENTER_FRAME,doDrawEvent);
        }

        private function moveToolBoxByType(type:int=0):void
        {
            var xBox:Sprite = null;

            if(type === 1) xBox = lassoMenu;
            else if(type === 2) xBox = traceMenuBox;

            const click:Point = new Point(mouseX,mouseY);
            setTopChildIndex(xBox);

            function toolBoxMoveMouseUpEvent(e:MouseEvent):void
            {
                checkBoxPosition(xBox);
                stageMouseMoveEvent.remove(toolBoxMoveMouseMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP, toolBoxMoveMouseUpEvent);
            }

            function toolBoxMoveMouseMoveEvent(e:MouseEvent):void
            {
                xBox.x += mouseX-click.x;
                xBox.y += mouseY-click.y;

                click.x = mouseX;
                click.y = mouseY;
            }

            stageMouseMoveEvent.add(toolBoxMoveMouseMoveEvent);
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
                    if(!isNowTool(TOOL_SPUIT))
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
                    if(traceMenuON === false)
                    {
                        openTraceWindow();
                        traceMenuBox.y = mouseY-60;
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
            if(RCANVAS_BG_COLOR === color) return;
            RCANVAS_BG_COLOR = color;
            _setBackgroundColor(rcanvasPanel,RCANVAS_WIDTH,RCANVAS_HEIGHT,color);
        }

        private function setBackgroundColorDrawMode(color:uint):void
        {
            if(CANVAS_BG_COLOR === color) return;
            clearButtonClicked = false;
            saveOneTime = false;
            CANVAS_BG_COLOR = color;
            previewBox.changeprevBitmapBGColor(color);

            _setBackgroundColor(canvasPanel,CANVAS_WIDTH,CANVAS_HEIGHT,color);
        }

        private function changeToolTipString(str:String):void
        {
            const _toolTipBox:toolTipBoxSet = toolTipBox;
            const textfe:TextField = _toolTipBox["toolTipInfoText"];
            textfe.text = str;
            textfe.width = textfe.textWidth+20;
            _toolTipBox["toolTipBoxBG"].width = textfe.textWidth+6;
        }

        private function setToolTipStringTime(str:String,time:Number=2000):void
        {
            function toolTipBoxTimerOFFEvent(e:MouseEvent):void
            {
                clearTimeout(toolTipBoxTimer);
                toolTipBoxTimer = 0;
                toolTipBox.visible = false;
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,toolTipBoxTimerOFFEvent);
            }

            if(toolTipBoxTimer === 0)
            {
                stage.addEventListener(MouseEvent.MOUSE_DOWN,toolTipBoxTimerOFFEvent);
            }

            setToolTipString(str);
            toolTipBox.visible = true;

            clearTimeout(toolTipBoxTimer);
            toolTipBoxTimer = setTimeout(function():void
            {
                stageMouseMoveEvent.remove(toolTipBoxTimerOFFEvent);
                if(toolTipBox["toolTipInfoText"].text === str)
                {
                    toolTipBoxTimer = 0;
                    toolTipBox.visible = false;
                }
            },time);
        }

        private function moveToolTipString():void
        {
            const tb:toolTipBoxSet = toolTipBox;
        }

        private function setToolTipString(str:String,x:Number=0,y:Number=0):void
        {
            const floor:Function = Math.floor;
            const _toolTipBox:toolTipBoxSet = toolTipBox;
            const toolTipText:TextField = _toolTipBox["toolTipInfoText"];
            if(str !== "")
            {
                toolTipText.text = str;
                toolTipText.width = toolTipText.textWidth+20;
            }

            const mx:Number = (x > 0) ? x : mouseX;
            const my:Number = (y > 0) ? y : mouseY;
            const tbHeight:Number = _toolTipBox.height+3;
            const cw:int = toolTipText.textWidth+6;
            const right:int = mx+cw/2;
            const offsetX:int = -cw/2;
            const offsetY:int = -34;
            const bottom:int = my-offsetY+tbHeight;
            const stw:uint = stage.stageWidth;
            const sth:uint = stage.stageHeight+3;
            const ylim:Number = sth-tbHeight;

            if(mx+offsetX < 0) _toolTipBox.x = 0;
            else if(right > stw) _toolTipBox.x = floor(stw-cw);
            else _toolTipBox.x = floor(mx-cw/2);

            if(my-offsetY < 0) _toolTipBox.y = 0;
            else if(bottom >= sth) _toolTipBox.y = floor(ylim);
            else _toolTipBox.y = floor(my-offsetY);

            if(my >= _toolTipBox.y-1) //맨 아래에서 커서가 힌트를 넘어갈때 다시 위로 올려줌
            {
                var ycheck:Number = my+offsetY-25;
                _toolTipBox.y = (ycheck < ylim) ? floor(ycheck) : floor(ylim);
            }

            if(str !== "")
            {
                _toolTipBox["toolTipBoxBG"].width = floor(cw+2);
            }

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
            restartTimerCancel();
            if(isDeepUndoON) exitDeepUndoMode();

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

        private function loadImageDragDrop(obj:Object,isReference:Boolean):void
        {
            if(tempCopiedImage) //클립보드에 이미지가 있으면
            {
                if(!isReference)
                {
                    const fileName:String = "Clipboard_image_"+clipImageNameCount+".png";
                    //두번째 변수에서 fileName를 같게 해줘야 저장할때 오류가 안남
                    loadImageFile(fileName,fileName,tempCopiedImage.width,tempCopiedImage.height,tempCopiedImage);
                }
                else if(isReference)
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
                fs.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
                

                //실제적으로 loader가 읽어서 캔버스에 그림
                function loaderIOErrorHandlerEvent(e:Event):void
                {
                    topBar.hintTimeError("Failed to load file");
                    tempDragDropFile = null;
                    loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, loaderIOErrorHandlerEvent);
                    loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, startDrawImgEvent);
                    loader = null;
                }

                function startDrawImgEvent(e:Event):void //drag load1
                {
                    var loaderInfo:LoaderInfo = LoaderInfo(e.target);

                    if(!isReference)
                    {
                        if(tempCopiedImage)
                        {
                            loadImageFile("Paste Image",saveFilePath,tempCopiedImage.width,tempCopiedImage.height,tempCopiedImage);
                            tempCopiedImage = null;
                        }
                        else
                        {
                            loadImageFile(tmpFileName,file.nativePath,loaderInfo.width,loaderInfo.height,loaderInfo.loader);
                        }

                    }
                    else if(isReference)
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
                        if(!isReference)
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
                rDataBuffer.push(["bgColor",pickedColor]);
                addUndoData(3);
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

            setToolTipStringTime("Added RGB "+c[0]+","+c[1]+","+c[2]);
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
                    arr.splice(0,1);
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
            resizeButtonR.name = "resizeButtonR";
            resizeButtonD.name = "resizeButtonD";
            resizeButtonL.name = "resizeButtonL";
            resizeButtonU.name = "resizeButtonU";

            regPoint.addChild(resizeButtonU);
            regPoint.addChild(resizeButtonD);
            regPoint.addChild(resizeButtonL);
            regPoint.addChild(resizeButtonR);
        }

        private function _makeJumpImage():void //loadrep
        {
            const fs:FileStream = new FileStream();
            const cd2:Graphics = rcanvas2Draw.graphics;
            const rf:File = repFile;
            const totalSize:Number = rf.size;
            const _IMG_CACHE_INTERVAL:uint = IMG_CACHE_INTERVAL;
            const replayInfoText:TextField = replayTimeBox["frameInfo"];
            var _frameSum:Number = 0;
            var _frameSumLast:Number = 0;
            var _rJumpImageCount:uint = 0;

            makeJumpImageFlag = 2;
            clearCanvasReplayMode();//일단 리플레이 캔버스 먼저 깨끗하게
            rcanvas1BitmapData = rFirstImage.clone(); 
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
            changeCanvasSizeReplayMode(rcanvas1BitmapData.width,rcanvas1BitmapData.height); //크기도 바꿔주고
            fs.open(rf,FileMode.READ);
            fs.position = 0;

            rregPoint.visible = false;

            const _tickDraw:Object = tickDraw;
            
            function onFrameEnter(e:Event):void
            {
                while(1)
                {
                    const namojiBytes:Number = fs.bytesAvailable;

                    if(namojiBytes === 0)
                    {
                        _tickDraw.reset();
                        stage.removeEventListener(Event.ENTER_FRAME,onFrameEnter);
                        fs.close();
                        undoData.setRFileTotalFrame(_frameSum);
                        makeJumpImageFlag = 0;
                        rregPoint.visible = true;
                        resetReplayTime();
                        TOTAL_FRAME = getTotalFrame();
                        rDataReadFlag = false;
                        setCenvasCenterPos(true,false);
                        checkCutFrameButtons();
                        rNowFrame = TOTAL_FRAME;
                        rPrevFrame = _frameSumLast;
                        checkReplaySpeedState();
                        if(isDeepUndoON)
                        {
                            setDeepUndoUI(true);
                        }
                        else
                        {
                            // _jumpFrame(TOTAL_FRAME+1,JUMP_FRAME_ONCE);
                            // rDataPreviewCacheImages = [];
                            // rJumpImageIndexSave = -2;
                            removeInputEventDrawMode();
                            addInputEventReplayMode();
                        }
                        return;
                    }

                    const d:Array = fs.readObject() as Array;
                    const dlen:Number = d.length;

                    _tickDraw.ready(d);
                    _frameSumLast = _frameSum;
                    _frameSum += dlen;
                    _rJumpImageCount += dlen;
                    _tickDraw.drawAll();

                    if(_rJumpImageCount > _IMG_CACHE_INTERVAL)
                    {
                        rJumpImageFrameData.push(_frameSum); // jumpimg:File변수보다 먼저 와야함

                        const perc:Number = Math.floor(((totalSize-namojiBytes)/totalSize)*100);
                        const fs3:FileStream = new FileStream();
                        const jumpimg:File = rJumpImageFolder.resolvePath((rJumpImageFrameData.length-1)+"");
                        const lastBytePos:Number = fs.position;
                        const imgData:ByteArray = new ByteArray();
                        const w:Number = rcanvas1BitmapData.width;
                        const h:Number = rcanvas1BitmapData.height;
                        const newRectangle:Rectangle = new Rectangle(0,0,w,h);

                        rcanvas1BitmapData.copyPixelsToByteArray(newRectangle,imgData);
                        imgData.compress();
                        fs3.open(jumpimg,FileMode.WRITE);
                        fs3.writeObject([imgData,w,h,rBGColorSave,lastBytePos,_frameSum])//이미지 데이터,가로 세로, 배경색, 마지막 바이트 위치, 마지막 프레임 합
                        fs3.close();
                        imgData.clear();
                        _rJumpImageCount = 0;
                        replayInfoText.text = "Loading... "+perc+"%";
                        return;
                    }
                }
            }
            stage.addEventListener(Event.ENTER_FRAME,onFrameEnter);
        }

        private function saveReplayFile():void
        {
            if(repFile.exists)
            {
                const pathStr:String = saveFilePath;
                const newPath:String = pathStr.substr(0,pathStr.lastIndexOf(".png"))+".2020";
                const fs:FileStream = new FileStream();
                const copyFile:File = new File(newPath);
                const rImgData:ByteArray = new ByteArray();
                const rImgDataW:int = rFirstImage.width;
                const rImgDataH:int = rFirstImage.height;
                const lastImgData:ByteArray = new ByteArray();
                const traceImgData:ByteArray = new ByteArray();
                const _rData:Array = rData;
                const _traceBmpd:BitmapData = canvasTraceBitmapData;
                var newRectangle:Rectangle = new Rectangle(0,0,rImgDataW,rImgDataH);

                rFirstImage.copyPixelsToByteArray(newRectangle,rImgData);
                rImgData.compress();

                newRectangle = new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);
                canvas1BitmapData.copyPixelsToByteArray(newRectangle,lastImgData);
                lastImgData.compress();

                if(_traceBmpd)
                {
                    const traceImgInfo:Array = tracePosInfo;
                    const traceImgWidth:Number = _traceBmpd.width;
                    const traceImgHeight:Number = _traceBmpd.height;
                    newRectangle = new Rectangle(0,0,traceImgWidth,traceImgHeight);
                    _traceBmpd.copyPixelsToByteArray(newRectangle,traceImgData);
                    traceImgData.compress();
                }

                repFile.copyTo(repFileTemp,true);//일단 임시파일로 복사

                //임시파일전체를 바이트배열로 읽어서 압축해줌
                const tmpBytes:ByteArray = new ByteArray();
                fs.open(repFileTemp,FileMode.READ);
                fs.position = 0;
                fs.readBytes(tmpBytes,0,fs.bytesAvailable);
                tmpBytes.compress();
                fs.close();

                //실제 저장할 파일을 다시 써줌
                fs.open(repFileTemp,FileMode.WRITE);
                fs.position = 0;
                fs.writeUTFBytes("FOFOPAINT"); //파일 헤더
                fs.writeUnsignedInt(tmpBytes.length); //뒤에 압축된 바이트를 얼마나 건너 뛰어야 하는지 저장
                fs.writeBytes(tmpBytes);
                tmpBytes.clear();

                var _readUndoArray:Array;
                for(var i:int=0,len:int=undoIndex;i<=len;i++)//리플레이 데이터랑 첫이미지 마지막 이미지 추가적으로 붙여줌
                {
                    _readUndoArray = _rData[i] as Array;
                    if(_readUndoArray.length === 0) continue;
                    fs.writeObject(_readUndoArray);
                }

                if(mirrorPushReady) //임시 미러가 되어있을때 진짜 캔버스로 반전되어있는데 리플레이 데이터에는 아직 써주지 않았으니까 넣어줌
                {
                    const tempMirrorData:Array = [["mirror"]];
                    fs.writeObject(tempMirrorData);
                }

                fs.writeObject(["rFirstImage",rImgData,rImgDataW,rImgDataH,rFirstBGColor]);
                fs.writeObject(["rFinalImage",lastImgData,CANVAS_WIDTH,CANVAS_HEIGHT,CANVAS_BG_COLOR]);
                if(_traceBmpd)
                {
                    fs.writeObject(["traceImage",traceImgData, // 1
                                                traceImgWidth,
                                                traceImgHeight,
                                                traceImgInfo[0],
                                                traceImgInfo[1],// 5
                                                traceImgInfo[2],
                                                traceImgInfo[3],
                                                traceImgInfo[4],
                                                traceImgInfo[5],
                                                traceReizeMoveSum,//10
                                                CANVAS_TRACE_ALPHA]);// 11
                }
                fs.close();
                rImgData.clear();
                lastImgData.clear();
                repFileTemp.moveTo(copyFile,true);
                topBar.hintTimeOK("File saved successfully");
            }
        }

        private function loadReplayFile(oldFile:File,fileName:String,filePath:String):void //loadrep
        {
            if(isTrue2020File(oldFile) === false) return;
            if(replayModeON)  setReplayUI(false);

            removeInputEventDrawMode();

            const fs:FileStream = new FileStream();
            var imgStartByte:uint = 0;
            var finalIMGBMPD:BitmapData = new BitmapData(1,1,true,0);
            var imgW:uint = 0;
            var imgH:uint = 0;
            var bg:uint = 0;
            var errorFlag:Boolean = true;
            var traceBMPD:BitmapData = null;
            var traceImgInfo:Array = null;
            var newRectangle:Rectangle;

            resetReplayDataFile(true); //일단 썸네일 이미지랑 리플레이 데이터 청소
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
            const _isNewFOFOSaveForamat:Boolean = isNewFOFOSaveForamat;

            if(_isNewFOFOSaveForamat)
            {
                isNewFOFOSaveForamat = false;
                const replayData:ByteArray = new ByteArray();
                fs.readUTFBytes(9); //FOFOPAINT헤더 읽어줌
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
                d = fs.readObject() as Array;

                if(d[0] === "rFirstImage") //리플레이 첫 이미지 파일
                {
                    ba = d[1] as ByteArray;
                    newRectangle = new Rectangle(0,0,d[2],d[3]);
                    ba.uncompress();
                    rFirstImage = new BitmapData(d[2],d[3],true,0);
                    rFirstImage.lock();
                    rFirstImage.setPixels(newRectangle,ba);
                    rFirstImage.unlock();
                    ba.clear();
                    const bgc:uint = d[4];

                    //r first img 업데이트 해줌
                    updateFirstImage(rFirstImage,bgc); //0.cache 파일 갱신
                    rBGColorSave = bgc;
                }
                else if(d[0] === "rFinalImage")//최종 이미지
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

                    imgW = d[2];
                    imgH = d[3];
                    bg = d[4];
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
                    d[0] = null;
                    d[1] = null;
                    traceRawArr = d.concat();
                }
                else if(_isNewFOFOSaveForamat)
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

            if(_isNewFOFOSaveForamat)
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

            makeJumpImageFlag = 1;
            loadFileAfter(fileName,filePath,imgW,imgH,finalIMGBMPD,false,bg);
            addInputEventDrawMode();
        }

        private function loadRawFileToReferenceLayer(file:File):void
        {
            if(isTrue2020File(file) === false)
            {
                topBar.hintTimeError("Failed to load file");
                return;
            }

            const fs:FileStream = new FileStream();
            var errorFlag:Boolean = true;
            fs.open(file,FileMode.READ);
            var finalIMGBMPD:BitmapData = new BitmapData(1,1,true,0);
            
            const _isNewFOFOSaveForamat:Boolean = isNewFOFOSaveForamat;
            if(_isNewFOFOSaveForamat)
            {
                isNewFOFOSaveForamat = false;
                fs.readUTFBytes(9); //FOFOPAINT헤더 읽어줌
                const compBytes:uint = fs.readUnsignedInt(); // 압축된 데이터 길이 읽어줌
                fs.position += compBytes;
            }

            while(1)
            {
                if(fs.bytesAvailable === 0) break;
                const d:Array = fs.readObject() as Array;

                if(d[0] === "rFinalImage")//최종 이미지
                {
                    const ba2:ByteArray = d[1] as ByteArray;
                    const newRectangle:Rectangle = new Rectangle(0,0,d[2],d[3]);

                    ba2.uncompress();
                    finalIMGBMPD = new BitmapData(d[2],d[3],true,0);
                    finalIMGBMPD.lock();
                    finalIMGBMPD.setPixels(newRectangle,ba2);
                    finalIMGBMPD.unlock();
                    ba2.clear();
                    errorFlag = false;
                }
            }
            fs.close();

            pasteTraceImage(finalIMGBMPD,finalIMGBMPD.width,finalIMGBMPD.height);

            if(!replayModeON)
            {
                openTraceWindow();
            }
        }

        private function loadImageFile(fileName:String,filePath:String, width:Number,height:Number,imageData:IBitmapDrawable):void
        {
            if(replayModeON) setReplayUI(false);
            TOTAL_FRAME = 0;
            undoData.setRFileTotalFrame(0);
            makeJumpImageFlag = 0;
            traceRawBMPD = null;
            traceRawArr = null;
            loadFileAfter(fileName,filePath,width,height,imageData,true);
            resetReplayDataFile(true); //일단 썸네일 이미지랑 리플레이 데이터 청소
        }

        private function loadFileAfter(fileName:String,filePath:String, width:uint,height:uint,imageData:IBitmapDrawable,cloneFlag:Boolean,newBG:uint=0xFFFFFF):void
        {
            if(!imageData)
            {
                topBar.hintTimeError("Failed to load file");
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

            rSpeed = 1; //속도 리셋
            topBar.replaySpeedMoveButton.x = topBar["replaySpeedBar"].x;
            resetReplayTime();
            clearCanvasReplayMode();
            replayTimeBox["frameInfo"].text = "0 / " + getTotalFrame()+" frame";
            replayTimeBox["replayNowBar"].width = 0;

            setBackgroundColorDrawMode(newBG);
            setBackgroundColorReplayMode(newBG);

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
            appInfoBox.setMirror(false);
            mirrorPushReady = false;
            clearButtonClicked = false;

            if(lassoToolON === true)
            {
                setLassoCancelButton();
                resetLassoBox();
            }

            if(fillPenStarted) fillPenTool.cancel();

            tickDraw.resetgetRCursorPos();
            tmpBMPD.draw(imageData,scaleMat,null,null,null,true);
            canvas1BitmapData = tmpBMPD.clone();
            canvas1Bitmap.bitmapData = canvas1BitmapData;
            changeCanvasSize(scaledwidth,scaledheight,0,0,false);
            if(cloneFlag) rFirstImage = tmpBMPD.clone();

            tmpBMPD.dispose();
            tmpBMPD = null;
            regPoint.rotation = 0;
            zoomedIndex = 3;
            setZoomCanvas(1.0);
            //bitmapdata가 갱신된이후에 업데이트 해줘야함
            resetUndo();

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
                canvasTraceLayer.alpha = tArr[11];
                updateTraceOpaButtonPosByAlpha(tArr[11]);
                traceRawBMPD.dispose();
                traceRawBMPD = null;
                traceRawArr = null;
                canvasTraceBitmap.smoothing = true;
            }
            setCenvasCenterPos();
            addUndoData();
            updateWindowTitle();
            setWindowTitleStar();
            setSubLayer(false);
            setReplaySubLayer(false);
            updateResizeButtonPos();
            cancelAutoKeyEvent({});
            System.gc();
        }

        private function loadFile(subLayer:Boolean=false):void
        {
            if(replayStartON) stopReplay();
            if(lassoToolON || browseWindowON || fillPenStarted) return;
            const allowedExt:String = "*.2020;*.png;*.jpg;*.gif";
            var newFileFilter:FileFilter = new FileFilter("Image or 2020 file",allowedExt);
            var windowTitle:String = "Open file";
            var imgExt:Array = [newFileFilter];

            if(subLayer === true)
            {
                newFileFilter = new FileFilter("Image file",allowedExt);
                windowTitle = "Open reference layer image";
                imgExt = [newFileFilter];
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
                if(subLayer === true) pasteTraceImage(loaderInfo.loader,loaderInfo.width,loaderInfo.height);
                else loadImageFile(file.name,file.nativePath,loaderInfo.width,loaderInfo.height,loaderInfo.loader);

                loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR,loadErrorEvent);
                loader.contentLoaderInfo.removeEventListener(Event.COMPLETE,loadFileCompleteEvent);
                loader.unload();
                loader = null;
            }

            function loadErrorEvent(e:Event):void
            {
                topBar.hintTimeError("Failed to load file");
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
                    if(subLayer === true) loadRawFileToReferenceLayer(file);
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

            canvasGrid.visible = iFlag;
            setResizeButtonVisible(false);

            if(replayMode)
            {
                resetCutFrameClickCounter();
                topBar.hintOFF();
                replayTimeBox.visible = iFlag;
            }

            if(flag === true)
            {
                sideBar.visible = false;
                topBar.resetHintColor();
                penSizeCursor.visible = false;
                canvasTraceLayer.visible = false;
                if(traceMenuON === true) traceMenuBox.visible = false;

                changeTopBarIcons("capture");

                addInputEventCaptrueMode();
                if(replayModeON) removeInputEventReplayMode();
                else removeInputEventDrawMode();
            }
            else 
            {
                canvasTraceLayer.visible = true;
                removeInputEventCaptrueMode();

                if(replayMode)
                {
                    changeTopBarIcons("replay");
                    addInputEventReplayMode();
                }
                else
                {
                    if(isSidebarVisible === true)
                        sideBar.visible = true;

                    if(traceMenuON === true)
                        traceMenuBox.visible = true;

                    changeTopBarIcons("draw");
                    addInputEventDrawMode();
                }

                changePickerModeToNormal();
            }
        }

        private function mouseDownCaptureMode(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!isNowKey(0) || !target) return;

            const targetName:String = target.name;

            switch(targetName)
            {
                case "capRotate":
                case "capFlip":
                case "capFull":
                case "capOff":
                case "capTrans":
                    checkButtonUp(targetName);
                break;

                case "timer":
                {
                    resetTimer();
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
            if(e.keyCode === nowKey)
            {
                if(keyBuffer.length > 0)setNowKey(keyBuffer[0]);
                else resetNowKey();
            }
        }

        private function keyDownCaptureMode(e:KeyboardEvent):void
        {
            const keyCode:uint = keyBuffer[0];
            if(mouseClickON || rightMouseClickON || isNowKey(keyCode)) return;

           setNowKey(keyCode);

            switch(keyCode)
            {
                case KEY.c:
                case KEY.m:
                    setFullCaptrueButton();
                break;

                case KEY.s:
                case KEY.k:
                    setCaptureRotateButton();
                break;

                case KEY.a:
                case KEY.l:
                    setCaptrueFlipButton();
                break;

                case KEY.d:
                case KEY.j:
                    setCaptureTransButton();
                break;

                case KEY.esc:
                case KEY.backspace:
                    setCaptureOFFButton(true);
                break;
            }
        }

        private function captureMouseMoveHintEvent(e:MouseEvent):void
        {
            if(!captureModeON)
                stageMouseMoveEvent.remove(captureMouseMoveHintEvent);
        }

        private function setCaptureReady():void
        {
            if(captureModeON) return;
            if(replayStartON)stopReplay();

            captureModeON = true;
            penCursorOFFFlag = true;
            stageMouseMoveEvent.add(captureMouseMoveHintEvent);

            setCaptureUI(true);
            captureRotated = 0;
            captureFlipped = false;
            // captureTransBGON = false;

            const floor:Function = Math.floor;
            var xReg:Sprite;
            var xPanel:Sprite;
            var xZoomed:Number;

            if(replayModeON)
            {
                xReg = rregPoint;
                xPanel = rcanvasPanel;
                xZoomed = rzoomed;
                rCursor.visible = false;
                rcanvasPanel.addChild(captureAreaRect);
            }
            else
            {
                xReg = regPoint;
                xPanel = canvasPanel;
                xZoomed = zoomed;
                canvasPanel.addChild(captureAreaRect);
            }

            setTopChildIndex(captureAreaRect);
            captureAreaRect.visible = true;

            capturePanelData = {
                                    "z" : xZoomed,
                                    "x" : floor(xReg.x), //뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
                                    "y" : floor(xReg.y),
                                    "r" : xReg.rotation,
                                    "px" : floor(xPanel.x),
                                    "py" : floor(xPanel.y)
                                }

            canvasFitWindow(true);
            captureTransBGON = true;
            setCaptureTransButton();
            resetTransBG(false);
        }

        private function setCaptureModeOFF(replayMode:Boolean,xReg:Sprite,xPanel:Sprite):void
        {
            const data:Object = capturePanelData;
            const xBitmap:Bitmap = (replayMode) ? rcanvas1Bitmap : canvas1Bitmap;

            xBitmap.smoothing = false;

            captureModeON = false;
            penCursorOFFFlag = false;
            captureAreaRect.visible = false;
            captureAreaRect.graphics.clear();
            setCaptureUI(false);

            //캔버스 이전 모양 위치로 복원
            xReg.rotation = data.r;
            xReg.x = data.x+captureWindowMove.x;
            xReg.y = data.y+captureWindowMove.y;
            xPanel.x = data.px;
            xPanel.y = data.py;

            setZoomCanvas(data.z,replayMode);
            toolTipBox.visible = false;
            captureWindowMove = new Point(0,0);

            updatePenSizeCursor();

            if(replayMode)
            {
                resetTransBG(true);
                rCursor.visible = true;
            }
            else if(!replayMode)
            {
                resetTransBG(false);
            }

            drawCaptureArea.reset();
            checkCanvasPanelPos(replayMode);
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

            function updateCaptureAreaLineSize():void
            {
                if(rectW > 10 && rectH > 10) drawArea(cx,cy,rectW,rectH);
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
                    stageMouseMoveEvent.remove(captureMouseMove);
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
                if(!rectW || !rectH || (rectW < 10 && rectW < 10)) return "";
                else return (captureRotated === 0 || captureRotated === 2) ? abs(rectW)+" x "+abs(rectH)
                                                                          : abs(rectH)+" x "+abs(rectW);
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
            }

            function captureMouseUp(e:MouseEvent):void
            {
                stageMouseMoveEvent.remove(captureMouseMove);
                stage.removeEventListener(MouseEvent.MOUSE_UP,captureMouseUp);
                
                if(mouseMoved === true)
                {
                    //rect길이가 음수인경우 cx cy를 양수로 다시 맞추어줌
                    if(rectW < 0)
                    {
                        rectW = -rectW;
                        cx = cx-rectW;
                    }

                    if(rectH < 0)
                    {
                        rectH = -rectH;
                        cy = cy-rectH;
                    }

                    rectX = cx;
                    rectY = cy;
                    topBar.hint(getRotatedRectSizeString()+" (Click canvas to save)",topBar.capOff);
                }
                else if(abs(rectW) > 10 && abs(rectH) > 10) saveCaptureImage(rectX,rectY,rectW,rectH);

                mouseMoved = false;
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

                stageMouseMoveEvent.add(captureMouseMove);
                stage.addEventListener(MouseEvent.MOUSE_UP,captureMouseUp);
            };

            return {
                start:start,
                reset:reset,
                getRotatedRectSizeString:getRotatedRectSizeString,
                updateCaptureAreaLineSize:updateCaptureAreaLineSize
            };
        }

        private function getRandomString():String
        {
            var count:int = 6+Math.random()*10;
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

        private function saveCaptureImage(cx:Number,cy:Number,rectW:Number,rectH:Number):void
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
                var newRectangle:Rectangle = new Rectangle(cx,cy,rectW,rectH);
                const finalData:ByteArray = new ByteArray();
                const bmpd:BitmapData = mergeCanvas(replayMode,captureTransBGON);
                var cropData:ByteArray = bmpd.getPixels(newRectangle);
                cropData.position = 0; //이거 꼭 해줘야함 안그러면 setpixel에서 에러뜸
                const cropbmpd:BitmapData = new BitmapData(rectW,rectH,true,0);
                const pngOption:PNGEncoderOptions = new PNGEncoderOptions();

                cropbmpd.lock();

                newRectangle = new Rectangle(0,0,cropbmpd.width,cropbmpd.height);
                cropbmpd.setPixels(newRectangle,cropData);

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
                
                if(!swapWH)
                {
                    newRectangle = new Rectangle(0,0,cropbmpd.width,cropbmpd.height);
                    tmpbmpd.encode(newRectangle, pngOption, finalData);
                }
                else
                {
                    newRectangle = new Rectangle(0,0,cropbmpd.height,cropbmpd.width);
                    tmpbmpd.encode(newRectangle, pngOption, finalData);
                }

                cropbmpd.unlock();

                var fName:String = file1.name;
                var fPath:String = e.target.nativePath;

                //마지막 경로 업데이트
                saveFilePath = fPath.substr(0,fPath.lastIndexOf(fName))+saveFileName;

                if(fName.lastIndexOf(".png") === -1)//png를 안붙여 줬을때
                {
                    const fixedPath:String = fPath.replace(fName,""); //이름짜르고 경로만 저장
                    const reFile:File = new File(fixedPath);
                    const dotPNG:String = fName+".png";
                    file1 = reFile.resolvePath(dotPNG);
                }

                fs.open(file1,FileMode.WRITE);
                fs.writeBytes(finalData);
                fs.close();
                finalData.clear();
                file1.cancel();
                file1.removeEventListener(IOErrorEvent.IO_ERROR, onCancelEvent);
                file1.removeEventListener(Event.CANCEL, onCancelEvent);
                file1.removeEventListener(Event.SELECT, onSelectEvent);

                // buttonEffect(topBar["capFull"]);
            }
        }

        private function checkSaveFileName(saveFailed:Boolean):File
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

        private function saveFile(asFlag:Boolean,saveFailed:Boolean=false):void
        {
            //계속 저장하는거 방지 다른 이름으로 저장은 예외
            if(replayStartON)
            {
                stopReplay();
            }

            const continueFlag:Boolean = saveContinue === true && asFlag === false;

            if((saveOneTime === true && continueFlag) || lassoToolON || fillPenStarted)
            {
                return;
            }
            
            const fs:FileStream = new FileStream();
            if(continueFlag)
            {
                const normalFile:File = new File(saveFilePath);

                if(normalFile.exists === true)
                {
                    function saveContinueErrorEvent(e:Event):void
                    {
                        fs.close();
                        fs.removeEventListener(IOErrorEvent.IO_ERROR, saveContinueErrorEvent);
                        saveOneTime = false;
                        saveFile(true,true);
                    }

                    const bmpd:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,false,CANVAS_BG_COLOR);
                    var byteArray:ByteArray = new ByteArray();
                    const newRectangle:Rectangle = new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);
                    const pngOption:PNGEncoderOptions = new PNGEncoderOptions();

                    bmpd.draw(canvas1BitmapData);
                    bmpd.encode(newRectangle,pngOption,byteArray);

                    fs.addEventListener(IOErrorEvent.IO_ERROR, saveContinueErrorEvent);
                    fs.openAsync(normalFile,FileMode.WRITE);
                    fs.writeBytes(byteArray);
                    fs.close();

                    byteArray.clear();
                    saveReplayFile();
                    updateWindowTitle();
                    saveOneTime = true;
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

                const file:File = checkSaveFileName(saveFailed);
                const saveWindowTitle:String = (asFlag === true) ? "Save file As..":"Save file";

                file.addEventListener(IOErrorEvent.IO_ERROR, onErrorEvent);
                file.addEventListener(Event.CANCEL, onCancelEvent);
                file.addEventListener(Event.SELECT, onSelectEvent);
                file.browseForSave(saveWindowTitle);

                browseWindowON = true;
                
                function removeEvent():void
                {
                    file.removeEventListener(IOErrorEvent.IO_ERROR, onErrorEvent);
                    file.removeEventListener(Event.CANCEL, onCancelEvent);
                    file.removeEventListener(Event.SELECT, onSelectEvent);
                }

                function onErrorEvent(e:Event):void
                {
                    browseWindowON = false;
                    file.cancel();
                    removeEvent();
                }

                function onCancelEvent(e:Event):void
                {
                    browseWindowON = false;
                    file.cancel();
                    removeEvent();
                }

                function onSelectEvent(e:Event):void
                {
                    browseWindowON = false;
                    removeEvent();

                    saveOneTime = true;
                    saveContinue = true;

                    const saveFileName_old:String = saveFileName;
                    const fName:String = file.name;
                    const fPath:String = e.target.nativePath;
                    const bmpd:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,false,CANVAS_BG_COLOR);
                    const byteArray:ByteArray = new ByteArray();
                    const newRectangle:Rectangle = new Rectangle(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);
                    const pngOption:PNGEncoderOptions = new PNGEncoderOptions();

                    bmpd.draw(canvas1BitmapData);
                    bmpd.encode(newRectangle,pngOption,byteArray);

                    var f1:File = new File(fPath);

                    saveFileName = fName;
                    saveFilePath = fPath;

                    //확장자가 2020이거나 png일경우 무시하고 원래 이름대로 저장  img.2020.png이렇게 중복되게 저장되는거 막음
                    if(fName.lastIndexOf(".2020") !== -1)
                    {
                        const fixedPath2:String = fPath.replace(fName,""); //이름짜르고 경로만 저장
                        const newName:String = fName.substr(0,fName.lastIndexOf(".2020"));
                        const reFile2:File = new File(fixedPath2);
                        const dotPNG2:String = newName+".png";

                        f1 = reFile2.resolvePath(dotPNG2);

                        saveFilePath = f1.nativePath;
                        saveFileName = dotPNG2;
                    }
                    else if(fName.lastIndexOf(".png") === -1)//png를 안붙여 줬을때
                    {
                        const fixedPath:String = fPath.replace(fName,""); //이름짜르고 경로만 저장
                        const reFile:File = new File(fixedPath);
                        const dotPNG:String = fName+".png";

                        f1 = reFile.resolvePath(dotPNG);

                        saveFilePath = f1.nativePath;
                        saveFileName = dotPNG;
                    }
                    fs.openAsync(f1,FileMode.WRITE);
                    fs.writeBytes(byteArray);
                    fs.close();

                    byteArray.clear();
                    updateWindowTitle();
                    saveReplayFile();
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
            const newRectangle:Rectangle = new Rectangle(0,0,arr[1],arr[2]);
            const bmpd:BitmapData = new BitmapData(arr[1],arr[2],true,0);
            const arr1:Array = fs.readObject() as Array;
            const arr2:Array = fs.readObject() as Array;
            
            rData = arr1.concat();
            rDataFrame = arr2.concat();
            fs.close();

            undoIndex = lastUndoIndex;
            bmpd.lock();
            bmpd.setPixels(newRectangle,arr[0]);
            bmpd.unlock();
            undoData.setUndoRefImage([bmpd.clone(),arr[1],arr[2],arr[3]]);
            drawUndoData();
            addUndoMode = 0;
            bmpd.dispose();

            //undo index가 arr의 가장 마지막 부분이 아니면 undo를 하던 중이니까 undoDelFlag 켜줌
            if(lastUndoIndex < rData.length-1) undoDelFlag = true;
            else undoDelFlag = false;
        }

        private function saveUndoData():void
        {
            const fs:FileStream = new FileStream();
            const arr:Array = undoData.getUndoRefImage();
            const bmpd:BitmapData = arr[0];
            const ba:ByteArray = new ByteArray();
            var newRectangle:Rectangle = new Rectangle(0,0,arr[1],arr[2]);

            bmpd.copyPixelsToByteArray(newRectangle,ba);
            ba.compress();
            var newArr:Array = [ba,arr[1],arr[2],arr[3],arr[4]];

            fs.open(undoDataFile,FileMode.WRITE);
            fs.writeInt(undoIndex);
            fs.writeObject(newArr);
            fs.writeObject(rData);
            fs.writeObject(rDataFrame);
            fs.close();
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
                            "zoomed":zoomed,
                            "zoomedIndex":zoomedIndex,
                            "canvasPanel.x":canvasPanel.x,
                            "canvasPanel.y":canvasPanel.y,
                            "regPoint.x":regPoint.x,
                            "regPoint.y": regPoint.y,
                            "regPoint.rotation":regPoint.rotation,
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
                            "APP_RUNNING_TIME":APP_RUNNING_TIME,
                            "CANVAS_TRACE_ALPHA":CANVAS_TRACE_ALPHA,
                            "traceOpaButtonX":traceMenuBox["traceOpaButton"].x,
                            "traceReizeMoveSum":traceReizeMoveSum,
                            "tracePosInfo[0]":tracePosInfo[0],
                            "tracePosInfo[1]":tracePosInfo[1],
                            "tracePosInfo[2]":tracePosInfo[2],
                            "tracePosInfo[3]":tracePosInfo[3],
                            "tracePosInfo[4]":tracePosInfo[4],
                            "tracePosInfo[5]":tracePosInfo[5],
                            "traceMenuPos[0]":traceMenuBox.x,
                            "traceMenuPos[1]":traceMenuBox.y,
                            "mirrorON":mirrorON,
                            "gridFlag":gridFlag,
                            "hueCursor.x":pickerBox["hueCursor"].x,
                            "svBaseColor":pickerBox["svBaseColor"],
                            "HUECOLOR[0]":HUECOLOR[0],
                            "makeJumpImageFlag":makeJumpImageFlag,
                            "rBGColorSave":rBGColorSave,
                            "isRightSidebar":isRightSidebar,
                            "saveFilePath":saveFilePath,
                            "isSidebarVisible":isSidebarVisible
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
                arr[0].uncompress();
                newRectangle = new Rectangle(0,0,arr[1],arr[2]);
                rFirstImage = new BitmapData(arr[1],arr[2],true,0);
                rFirstImage.lock();
                rFirstImage.setPixels(newRectangle,arr[0]);
                rFirstImage.unlock();
                rFirstBGColor = arr[3];
            }
            else
            {
                rFirstImage = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
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

                setTimeout(function():void //그냥 해주면 창크기 적용이 안되서 타이머 걸어줌
                {
                    _nativeWindow.width = d["stage.nativeWindow.width"];
                    _nativeWindow.height = d["stage.nativeWindow.height"];
                    _nativeWindow.x = d["stage.nativeWindow.x"];
                    _nativeWindow.y = d["stage.nativeWindow.y"];
                    lastWindowSize.x = d["stage.nativeWindow.width"];
                    lastWindowSize.y = d["stage.nativeWindow.height"];

                    //캔버스 위치까지 전부 다해준 다음에 이전 상태가 풀스크린이었으면 세팅해줌
                    if(d["lastWindowState"] === 1)
                    {
                        stage.nativeWindow.maximize();
                    }

                    zoomedIndex = d["zoomedIndex"];
                    setZoomCanvas(d["zoomed"]);
                    canvasPanel.x = d["canvasPanel.x"];
                    canvasPanel.y = d["canvasPanel.y"];
                    regPoint.x = d["regPoint.x"];
                    regPoint.y = d["regPoint.y"];
                    regPoint.rotation = d["regPoint.rotation"];
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
                    colorHistoryList = d["colorHistoryList"];
                    APP_RUNNING_TIME = d["APP_RUNNING_TIME"];
                    updateWorkingTime();
                    CANVAS_TRACE_ALPHA = d["CANVAS_TRACE_ALPHA"]
                    canvasTraceLayer.alpha = d["CANVAS_TRACE_ALPHA"];
                    traceMenuBox["traceOpaButton"].x = d["traceOpaButtonX"];
                    traceMenuBox.x = d["traceMenuPos[0]"];
                    traceMenuBox.y = d["traceMenuPos[1]"];
                    traceReizeMoveSum = d["traceReizeMoveSum"];
                    isRightSidebar = d["isRightSidebar"];
                    isSidebarVisible = d["isSidebarVisible"];
                    if(d["isRightSidebar"]) setSideBarRightPosition(true);
                    if(!d["isSidebarVisible"])
                    {
                        sideBar.cacheAsBitmap = false;
                        setSidebarVisible(d["isSidebarVisible"],false);
                        setTimeout(function():void //비트맵 캐싱을 하면 처음에 그래픽이 깨져서 일단 일캐해줌
                        {
                            sideBar.cacheAsBitmap = true;
                        },1000);
                    }
                    makeJumpImageFlag = d["makeJumpImageFlag"];
                    rBGColorSave = d["rBGColorSave"];
                    saveFilePath = d["saveFilePath"];

                    setTraceImageInfo(d["tracePosInfo[0]"],
                                      d["tracePosInfo[1]"],
                                      d["tracePosInfo[2]"],
                                      d["tracePosInfo[3]"],
                                      d["tracePosInfo[4]"],
                                      d["tracePosInfo[5]"]);

                    if(mirrorON !== d["mirrorON"])
                    {
                        mirrorCanvas(true);
                    }
                    
                    gridFlag = d["gridFlag"];
                    drawGrid();

                    //혹시 몰라서 위치 체크 해줌
                    appInfoBox.setRotate(regPoint.rotation);
                    setCenvasCenterPos(true);
                    checkCanvasPanelPos();
                    checkCanvasPanelPos(true);
                    updateColorHistoryList();
                    updatePreviewBoxRectPos();
                    updatePenSizeCursor();
                    updateWindowTitle();
                    setWindowTitleStar();
                },150);
            }
            else //복원파일이 없을때
            {
                lastWindowSize.x = 680;
                lastWindowSize.y = 768;
                _nativeWindow.width = lastWindowSize.x;
                _nativeWindow.height = lastWindowSize.y;

                changeCanvasSize(CANVAS_WIDTH,CANVAS_HEIGHT,0,0,false);
                setHSVCursorPosByColor(penColor);
                addUndoData();
                openAboutPanel(true);

                setUIColor(uiColorIndex);
                updatePreviewBoxRectPos();
                updateWindowSizeInfo();
                appInfoBox.init(CANVAS_WIDTH,CANVAS_WIDTH,zoomed,regPoint.rotation,false);
            }
        }

        //빈 stage공백에 광클하면 쓸데없는 addundo가 되서
        //캔버스를 클릭했거나, 펜사이즈가 캔버스에 걸치면 addundo가 되게 예약해줌
        private function checkUndoReady():void
        {
            if(penSizeCursor.hitTestObject(canvas1Bitmap))
            {
                if(!readyAddUndo) setWindowTitleStar();

                clearButtonClicked = false; //undo추가 예약되어있으면 그때 꺼줌
                readyAddUndo = true;
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

                if(pixelSnapON)
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

                // _penSizeCursor.x = mouseX;
                // _penSizeCursor.y = mouseY;
            };
        }

        //canvas2번데이터를 canvas1에다가 최종적으로그려줌
        private function drawDone():void
        {
            //커서 시작이 캔버스가 아니고 끝도 캔버스가 아니면 아무것도 안함
            if(readyAddUndo === false)
            {
                rDataBuffer = [];
                canvas2Draw.graphics.clear();
                return;
            }

            var canvas2Alpha:ColorTransform;

            readyAddUndo = false;
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
                canvas2Alpha = new ColorTransform(1,1,1,penAlpha);

                if(subLayerON)
                {
                    const subLayer:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
                    subLayer.draw(canvas2Bitmap,null,canvas2Alpha);
                    subLayer.draw(canvas1Bitmap);
                    canvas1BitmapData = subLayer.clone();
                    canvas1Bitmap.bitmapData = canvas1BitmapData;
                    rDataBuffer.push(["drawDone",true]);

                    subLayer.dispose();
                }
                else
                {
                    if(penColor === CANVAS_BG_COLOR)//배경색이랑 같으면 earse모드로 바꿔줌
                    {
                        canvas1BitmapData.draw(canvas2Bitmap,null,canvas2Alpha,"erase");
                        rDataBuffer.push(["drawDone"]);
                    }
                    else
                    {
                        canvas1BitmapData.draw(canvas2Bitmap,null,canvas2Alpha);
                        rDataBuffer.push(["drawDone"]);
                    }
                }
            }
            else if(isEraseTool())
            {
                canvas2Alpha = new ColorTransform(1,1,1,eraseAlpha);
                canvas1BitmapData.draw(canvas2Bitmap,null,canvas2Alpha,"erase");
                rDataBuffer.push(["drawDone"]);
            }

            canvas1Bitmap.bitmapData = canvas1BitmapData;
            canvas2Bitmap.bitmapData = null;
            canvas2BitmapData.dispose();
            canvas2BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
            canvas2Draw.graphics.clear();

            addUndoData();
        }

        private function cLineTool():Function
        {
            const floor:Function = Math.floor;
            const abs:Function = Math.abs;
            const atan2:Function = Math.atan2;
            const toDeg:Number = 180/Math.PI;
            const cd:Shape = canvas2Draw;
            const old:Point = new Point(0,0);

            var _traceMemoryTraining:Boolean;
            var xSize:uint;
            var xColor:uint;
            var xAlpha:Number;
            var xShape:Boolean;
            var xBlendMode:String;
            var _airBrushON:Boolean;
            var xOffset:Number;
            var mouseMovedFlag:Boolean;
            var subLayerFlag:Boolean;

            function drawingLine():void //지우개인가 펜인가 구분해서 lineto 실시
            {
                const cd:Shape  = canvas2Draw;
                const cdg:Graphics = cd.graphics;
                const mx:Number = cd.mouseX+xOffset;
                const my:Number = cd.mouseY+xOffset;
                cdg.clear();

                canvas2.alpha = xAlpha;
                if(xShape)
                {
                    cdg.lineStyle(xSize, xColor, 1, false, LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
                }
                else
                {
                    cdg.lineStyle(xSize, xColor);
                }

                cdg.moveTo(old.x+xOffset,old.y+xOffset);
                cdg.lineTo(mx,my);

                const ang:Number = atan2(old.x-cd.mouseX,old.y-cd.mouseY);
                var deg:Number = ang*toDeg+90;
                if(deg > 180)
                {
                    deg = deg-90;
                }

                var degstr:String = abs(deg % 90).toFixed(1)+"°";
                setToolTipString(degstr);
                toolTipBox.visible = true;

                const rad:Number = Math.atan2(old.x+xOffset-mx,old.y+xOffset-my);
                const cursorDeg:Number = -rad*(180/Math.PI)+regPoint.rotation;
                penSizeCursor.rotation = cursorDeg;
            }

            function lineMoveEvent(e:MouseEvent):void
            {
                if(!mouseMovedFlag)
                {
                    mouseMovedFlag = true;
                }

                drawingLine();

                if(readyAddUndo === false) checkUndoReady();
            }

            function lineUpEvent(e:MouseEvent):void
            {
                stageMouseMoveEvent.remove(lineMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP, lineUpEvent);

                if(_traceMemoryTraining)
                {
                    canvasTraceLayer.visible = true;
                }

                mouseDragON = false;

                const x:Number = cd.mouseX;
                const y:Number = cd.mouseY;
                const cx:Number = old.x;
                const cy:Number = old.y;
                const cxOff:Number = cx+xOffset;
                const cyOff:Number = cy+xOffset;
                const xx:Number = x+xOffset;
                const yy:Number = y+xOffset;

                if(mouseMovedFlag === false && cx === x && cy === y)
                {
                    rDataBuffer.push(["dot",xShape,xSize,xColor,xAlpha,xx,yy,xBlendMode,subLayerFlag,_airBrushON]);
                    drawDot(xShape,xSize,xColor,xx,yy);
                }
                else
                {
                    rDataBuffer.push(["line",xShape,xSize,xColor,xAlpha,cxOff,cyOff,xx,yy,xBlendMode,subLayerFlag,_airBrushON]);
                    drawingLine();                    
                }
                toolTipBox.visible = false;

                if(xShape === true)
                {
                    penSizeCursor.rotation = regPoint.rotation;
                }

                if(readyAddUndo === false) checkUndoReady();

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
                _airBrushON = airBrushON;

                xOffset = (sizeOffsetFlag) ? 0.5 : 0;

                mouseMovedFlag = false;
                old.setTo(cd.mouseX,cd.mouseY);
                subLayerFlag = subLayerON

                if(_traceMemoryTraining)
                {
                    canvasTraceLayer.visible = false;
                }
                
                //캔버스2번 지워주고, draw판넬 데이터도 지워줌
                canvas2BitmapData.dispose();
                canvas2Bitmap.bitmapData = null;
                canvas2BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
                if(readyAddUndo === false) checkUndoReady();

                //선 관련 이벤트 함수 붙여줌
                stageMouseMoveEvent.add(lineMoveEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,lineUpEvent);
            };
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
            var rotateCenterX:Number;
            var rotateCenterY:Number;

            function rotateToolUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, rotateToolUpEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, rotateToolUpEvent);
                stageMouseMoveEvent.remove(rotateToolMoveEvent);

                mouseDragON = false;
                penCursorOFFFlag = false;

                if(!_replayMode)
                {                    
                    if(lassoMenuTempOFF === true)
                    {
                        nowTool = TOOL_LASSO;
                        checkLassoMenuPos();
                        lassoMenuTempOFF = false;
                        lassoMenu.visible = true;
                        resetNowKey();
                    }

                    updatePenSizeCursor();
                    setOptimizeCanvasMove(false);
                    updatePreviewBoxRectPos();
                }
                else
                {
                    resetNowKey();
                    updateReplayCanvasBounds();
                }

                _rotateCursorBox.visible = false;
                checkCanvasPanelPos(_replayMode);
            }

            function rotateToolMoveEvent(e:MouseEvent):void
            {
                const abs:Function = Math.abs;
                const nowAng:Number = Math.atan2(mouseX-_rotateCursorBox.x,mouseY-_rotateCursorBox.y);
                const subAng:Number = lastAng-nowAng;

                if(subAng === 0) return;

                lastAng = nowAng;

                sumAng += subAng;
                var deg:Number = sumAng*toDeg;
                const snap90:Number = abs(deg%90);//90도 스냅 변수
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
                appInfoBox.setRotate(xReg.rotation);
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

                // var PI2:Number = PI*2;
                //각도 차이 구하기 위해서 넣어줌, 초기 값은 마우스 클릭한 위치의 각도값 
                lastAng = 0;
                //움직인 각도합 로테이트 캔버스 마지막각도를 넣어줌 rad로 변환
                sumAng = xReg.rotation*PI/180;
                center = getStageCenterPos(false,replayMode);
                rotateCenterX = center.x;
                rotateCenterY = center.y;

                penCursorOFFFlag = true;

                if(!replayMode)
                {
                    setOptimizeCanvasMove(true);
                }
                
                setRegPoint(rotateCenterX,rotateCenterY,replayMode);

                setTopChildIndex(_rotateCursorBox);
                _rotateCursorBox.visible = true;
                _rotateCursorBox.x = mouseX;
                _rotateCursorBox.y = mouseY+65;
                angleCursor.rotation = xReg.rotation;

                //regpoint와 각도 가이드가 전부이동한 후에 lastAng을 갱신해줌
                lastAng = Math.atan2(mouseX-_rotateCursorBox.x,mouseY-_rotateCursorBox.y);

                stageMouseMoveEvent.add(rotateToolMoveEvent);
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
                stageMouseMoveEvent.remove(moveToolMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP, moveToolOFFEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, moveToolOFFEvent);

                mouseDragON = false;
                penCursorOFFFlag = false;

                const floor:Function = Math.floor;
                const movex:Number = floor(canvas1.x);
                const movey:Number = floor(canvas1.y);

                var tempBitData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
                var movedMat:Matrix = new Matrix();

                movedMat.translate(movex,movey);

                //최종적으로 움직인 거리를 실제로 비트맵 데이터 조작
                tempBitData.draw(canvas1BitmapData,movedMat);
                canvas1BitmapData = tempBitData.clone();
                canvas1Bitmap.bitmapData = canvas1BitmapData;
                tempBitData.dispose();
                tempBitData = null;

                //좌표를 원점으로 돌림
                canvas1.x = 0;
                canvas1.y = 0;

                if(lassoToolON === false)
                {
                    clearButtonClicked = false;
                    rDataBuffer.push(["move",movex,movey]);
                    addUndoData(1);
                }
            }

            function moveToolMoveEvent(e:MouseEvent):void
            {
                const dx:Number = mouseX-old.x;
                const dy:Number = mouseY-old.y;
                const rPos:Point = rotatePoint(dx,dy,regPoint.rotation);

                canvas1.x = rPos.x/z; //캔버스만 옮겨줘서 미리보기해줌
                canvas1.y = rPos.y/z;
            }

            return function ():void
            {
                old.setTo(mouseX,mouseY);
                z = zoomed;
                penCursorOFFFlag = true;

                stageMouseMoveEvent.add(moveToolMoveEvent);
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
                stageMouseMoveEvent.remove(zoomToolMouseMoveEvent);

                zoomToolHintON = false;
                mouseDragON = false;
                penCursorOFFFlag = false;
                toolTipBox.visible = false;

                updatePenSizeCursor();
                setOptimizeCanvasMove(false);

                if(lassoMenuTempOFF === true)
                {
                    nowTool = TOOL_LASSO;
                    checkLassoMenuPos();
                    lassoMenuTempOFF = false;
                    lassoMenu.visible = true;
                    resetNowKey();
                }

                updatePreviewBoxRectPos();
            }

            function zoomGoArray(index:uint):void
            {
                const newZoom:Number = _zoomArr[index];
                const textZoom:uint = Math.floor(newZoom*100);

                setZoomCanvas(newZoom,false);
                setToolTipString(textZoom+"%",clickPos.x,clickPos.y);
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
                setToolTipString(zoomed*100+"%",clickPos.x,clickPos.y);
                toolTipBox.visible = true;

                stageMouseMoveEvent.add(zoomToolMouseMoveEvent);
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
            canvas1BitmapData = tempBitData.clone();
            canvas1Bitmap.bitmapData = canvas1BitmapData;
            tempBitData.dispose();
            tempBitData = null;

            previewBox.updateImage(canvas1BitmapData,CANVAS_BG_COLOR);
        }


        //캔버스의 중심좌표를 구함 컨트롤 박스 옵션 박스 포함
        private function getCanvasPanelMidPos():Point
        {
            const round:Function = Math.round;
            const boundRect:Object = getBoundRect(canvas1);
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

        private function mirrorCanvas(canvasOnly:Boolean=false):void
        {
            //canvaspanel로 하면 중점이 안맞아서 canvas1로함
            const p:Point = getCanvasPanelMidPos();
            const _traceInfo:Array = tracePosInfo;

            mirrorON = !mirrorON;
            mirrorPushReady = !mirrorPushReady;
            mirrorDraw();
            appInfoBox.setMirror(mirrorON);

            //회전각 부호를 바꿔야 제대로 mirror가됨
            setRegPoint(p.x,p.y);//regpoint를 회전한 캔버스 중점으로 두고
            if(canvasOnly === false) //보통 미러할때, canvasonly가 true일때는 appdata에서 바꿔줄때 밖에 없음
            {
                regPoint.rotation = -regPoint.rotation;//반대각으로 세팅
                canvasTraceLayer.scaleX = -canvasTraceLayer.scaleX;
                canvasTraceLayer.rotation = -canvasTraceLayer.rotation;
                _traceInfo[2] = canvasTraceLayer.rotation;
                _traceInfo[3] = canvasTraceLayer.scaleX;
                _traceInfo[5] = !_traceInfo[5];
            }

            if(mirrorON)
            {
                canvasGrid.scaleX = -canvasGrid.scaleX;
                canvasGrid.x += CANVAS_WIDTH;
            }
            else
            {
                canvasGrid.scaleX = 1;
                canvasGrid.x = 0;
            }

            const halfCanvas:Number = (stage.stageWidth-sideBar.w)/2;
            var stageHalf:Number = (sideBar.visible === false) ? stage.stageWidth/2
                                 : (isRightSidebar) ? halfCanvas
                                 : STAGE_LEFT_OFFSET+halfCanvas;

            //창 절반을 기준점으로 regpoint x축 이동.
            regPoint.x += Math.round((stageHalf-p.x)*2);
            updatePreviewBoxRectPos();
            replayONUndoUpdate = true;
            saveOneTime = false; //미러도 화면이 바뀌기 때문에 세이브 플래그 꺼줌
        }

        private function changeCanvasSizeReplayMode(w:Number,h:Number,moveX:Number=0,moveY:Number=0,movedFlag:Boolean=false):void
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
            rcanvas2BitmapData = new BitmapData(w,h,true,0);
            RCANVAS_WIDTH = w;
            RCANVAS_HEIGHT = h;

            if(movedFlag)
            {
                //movex y는 캔버스 사이즈 조절에서 원점이 움직였을경우 그만큼 bitmapdata를 움직여줘야 원래 이미지대로 나옴
                var mat:Matrix = new Matrix();
                mat.translate(moveX,moveY);
                rcanvas1BitmapData.draw(rcanvas1Bitmap,mat);
            }
            else rcanvas1BitmapData.draw(rcanvas1Bitmap);

            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
            updateReplayCanvasBounds();
            checkCanvasPanelPos(true);
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

        private function changeCanvasSize(w:Number,h:Number,moveX:Number=0,moveY:Number=0,movedFlag:Boolean=false):void
        {
            const cg:Graphics = canvasPanel.graphics;
            const maxSize:uint = CANVAS_MAX_SIZE;

            if(w > maxSize)  w = maxSize;
            else if(w < 1) w = 1;

            if(h > maxSize) h = maxSize;
            else if(h < 1) h = 1;

            _setBackgroundColor(canvasPanel,w,h,CANVAS_BG_COLOR);
            updateCanvasPanelMask(w,h);
            canvas1BitmapData = new BitmapData(w,h,true,0);
            canvas2BitmapData = new BitmapData(w,h,true,0);

            if(movedFlag)
            {
                //movex y는 캔버스 사이즈 조절에서 원점이 움직였을경우 그만큼 bitmapdata를 움직여줘야
                //원래 이미지대로 나옴
                var mat:Matrix = new Matrix();
                const rp:Point = rotatePoint(moveX,moveY,-regPoint.rotation);  //캔버스가 회전되어있으면 회전된 방향으로 움직여줘야함
                mat.translate(moveX,moveY);
                canvas1BitmapData.draw(canvas1Bitmap,mat);
                regPoint.x -= Math.round(rp.x*zoomed);
                regPoint.y -= Math.round(rp.y*zoomed);
            }
            else canvas1BitmapData.draw(canvas1Bitmap);
            canvas1Bitmap.bitmapData = canvas1BitmapData;
            updateCanvasTracePos(w,h,movedFlag); //canvas width가 갱신되게 전에 체크해야함

            CANVAS_WIDTH = w;
            CANVAS_HEIGHT = h;
            checkCanvasPanelPos();
            drawGrid();

            const _appInfoBox:appInfoBar = appInfoBox;
            _appInfoBox.setSize(w,h);
        }

        private function cSetCanvasSize():Object
        {
            const resizeg:Graphics = reiszePreviewRect.graphics;
            const resizeClickPos:Point = new Point(0,0);
            const moved:Point = new Point(0,0);

            var targetName:String;
            var w:Number;
            var h:Number;
            var minL:int;
            var maxL:int;
            var bgColor:uint;
            var stageColor:uint;
            var finalWidth:uint;
            var finalHeight:uint;
            var startByShortCut:Boolean;
            var canvasSizeChanging:Boolean;
            
            function isCanvasSizeChanging():Boolean
            {
                return canvasSizeChanging;
            }
            
            function exitCanvasResize(forceExit:Boolean):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP,resizeButtonMouseUpEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,resizeButtonMouseUpEvent);
                stageMouseMoveEvent.remove(resizeButtonMouseMoveEvent);

                canvasSizeChanging = false;
                toolTipBox.visible = false;
                penCursorOFFFlag = false;
                setResizeButtonVisible((forceExit || (startByShortCut && !isPressingControl())) ? false:true);
                reiszePreviewRect.graphics.clear();
                reiszePreviewRect.visible = false;
                regPoint.removeChild(reiszePreviewRect);

                if(moved.x === 0 && moved.y === 0) return;

                const centerMoved:Boolean = (targetName === "resizeButtonL" || targetName === "resizeButtonU") ? true:false;
                
                changeCanvasSize(finalWidth,finalHeight,moved.x,moved.y,centerMoved);
                updateResizeButtonPos();
                clearButtonClicked = false;
                rDataBuffer.push(["canvasSize",CANVAS_WIDTH,CANVAS_HEIGHT,moved.x,moved.y,centerMoved]);
                addUndoData(2);
            }

            function resizeButtonMouseUpEvent(e:MouseEvent):void
            {
                exitCanvasResize(false);
            }

            function resizeButtonMouseMoveEvent(e:MouseEvent):void
            {
                const sub:Point = new Point((targetName === "resizeButtonR")  ? canvasPanel.mouseX-resizeClickPos.x:
                               (targetName === "resizeButtonL") ? resizeClickPos.x-canvasPanel.mouseX: 0
                               ,(targetName === "resizeButtonD")  ? canvasPanel.mouseY-resizeClickPos.y:
                               (targetName === "resizeButtonU") ? resizeClickPos.y-canvasPanel.mouseY: 0);
                
                finalWidth = (w+sub.x < minL) ? minL:
                           (w+sub.x > maxL) ? maxL:w+sub.x;
                finalHeight = (h+sub.y < minL) ? minL:
                           (h+sub.y > maxL) ? maxL:h+sub.y;

                sub.setTo((finalWidth === maxL) ? maxL-w:
                        (finalWidth === minL) ? minL-w : sub.x
                        ,(finalHeight === maxL) ? maxL-h:
                        (finalHeight === minL) ? minL-h : sub.y)

                moved.setTo(sub.x,sub.y);

                //미리보기 사각형 그려주기
                resizeg.clear();

                if(targetName === "resizeButtonR")
                {
                    if(sub.x > 0) resizeg.beginFill(bgColor);
                    else resizeg.beginFill(stageColor);
                    resizeg.drawRect(w,0,sub.x,h);
                    //미리보기 사각형이 화면을 넘어가면 자동 스크롤
                }
                else if(targetName === "resizeButtonL")
                {
                    if(sub.x > 0) resizeg.beginFill(bgColor);
                    else resizeg.beginFill(stageColor);
                    resizeg.drawRect(-sub.x,0,sub.x,h);
                }
                else if(targetName === "resizeButtonD")
                {
                    if(sub.y > 0) resizeg.beginFill(bgColor);
                    else resizeg.beginFill(stageColor);
                    resizeg.drawRect(0,h,w,sub.y);
                }
                else if(targetName === "resizeButtonU")
                {
                    if(sub.y > 0) resizeg.beginFill(bgColor);
                    else resizeg.beginFill(stageColor);
                    resizeg.drawRect(0,-sub.y,w,sub.y);
                }

                setToolTipString(finalWidth+" x "+finalHeight);
            }

            function start(_targetName:String,shortcut:Boolean):void
            {
                startByShortCut = shortcut;
                targetName = _targetName;
                w = CANVAS_WIDTH;
                h = CANVAS_HEIGHT;
                minL = CANVAS_MIN_SIZE;
                maxL = CANVAS_MAX_SIZE;
                bgColor = CANVAS_BG_COLOR;
                stageColor = STAGE_BG_COLOR;
                resizeClickPos.setTo(canvasPanel.mouseX,canvasPanel.mouseY);
                finalWidth = 0;
                finalHeight = 0;
                moved.setTo(0,0);

                canvasSizeChanging = true;
                //canvaspanel로 마우스 좌표 해주는 이유는
                //회전 되었을때도 panel좌표가 0도기준으로 유지 되기 때문
                reiszePreviewRect.x = canvasPanel.x;
                reiszePreviewRect.y = canvasPanel.y;
                regPoint.addChild(reiszePreviewRect);
                setTopChildIndex(reiszePreviewRect);
                reiszePreviewRect.visible = true;
                if(toolBox2ON) toolBox2.visible = false;
                setResizeButtonVisible(false);

                stage.addEventListener(MouseEvent.MOUSE_UP,resizeButtonMouseUpEvent);
                stageMouseMoveEvent.add(resizeButtonMouseMoveEvent);
            }
            
            return {
                start:start,
                exitCanvasResize:exitCanvasResize,
                isCanvasSizeChanging:isCanvasSizeChanging
            }
        }

        private function doLassoDraw(replayMode:Boolean,rectArr:Vector.<Number>,points:Array,copyFlag:Boolean=false):Boolean
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

            var canvas2FilterBackUp:Array;
            var drawEnt:Shape;
            var canvasBitmapData:BitmapData;
            var canvasBitmap:Bitmap;

            if(replayMode)
            {
                canvas2FilterBackUp = rcanvas2Draw.filters.concat();
                rcanvas2Draw.filters = [];
                drawEnt = rcanvas2Draw;
                canvasBitmapData = rcanvas1BitmapData;
                canvasBitmap = rcanvas1Bitmap;
            }
            else
            {
                canvas2FilterBackUp = canvas2Draw.filters.concat();
                canvas2Draw.filters = [];
                drawEnt = canvas2Draw;
                canvasBitmapData = canvas1BitmapData;
                canvasBitmap = canvas1Bitmap;
            }

            const cd:Shape = drawEnt;
            const cdg:Graphics = cd.graphics;
            const halfWidth:Number = rectWidth/2;
            const halfHeight:Number = rectHeight/2;
            const lassoP0:Array = points[0];
            const zerop:Point = new Point(0,0);
            const newRectangle:Rectangle = new Rectangle(rectLeft,rectTop,rectWidth,rectHeight);

            var lassoBMPD:BitmapData = new BitmapData(rectWidth,rectHeight,true,0);
            var i:uint;
            var x:Number;
            var y:Number;
            var nowPoint:Array;
            var xx:Number;
            var yy:Number;

            //지우기 전에 사각형 모양으로 그려준 부분을 copypixel 함.
            lassoBMPD.copyPixels(canvasBitmapData,newRectangle,zerop,null,null,true);

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
                canvasBitmapData.draw(cd,null,null,"erase");
                canvasBitmap.bitmapData = canvasBitmapData;
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
            lassoBMP.bitmapData = lassoBMPD;
            lassoBMP.bitmapData.draw(cd,null,null,"erase");
            cdg.clear(); //꼭 해줘야함

            //회전 확대를 bmp사각형의 중심으로 맞추어줌
            lassoBMP.x = -halfWidth;
            lassoBMP.y = -halfHeight;
            lassoBox.x = rectLeft+halfWidth;
            lassoBox.y = rectTop+halfHeight;
            lassoDraw.x = -lassoBox.x;
            lassoDraw.y = -lassoBox.y;
            lassoBMP.smoothing = true;

            if(replayMode) rcanvas2Draw.filters = canvas2FilterBackUp.concat();
            else canvas2Draw.filters = canvas2FilterBackUp.concat();

            return true;
        }

        private function cLassoTool():Function
        {
            const cd:Shape = canvas2Draw;
            const lassoDottedLineLimit:int = 3;
            const lassog:Graphics = lassoDraw.graphics;
            const _dottedLine:Object = dottedLine;
            const clickPos:Point = new Point(0,0);

            var canvas2FilterBackUp:Array;
            var lassoRect:Vector.<Number>;
            var lassoPoints:Array;
            var timer:int = 0;

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

            function lassoDrawMouseUp():void
            {
                stageMouseMoveEvent.remove(lassoDrawMouseMove);
                stage.removeEventListener(MouseEvent.MOUSE_UP,lassoDrawMouseUp);

                if(lassoRect[0] < 0) lassoRect[0] = 0;
                if(lassoRect[1] < 0) lassoRect[1] = 0;
                if(lassoRect[2] > CANVAS_WIDTH) lassoRect[2] = CANVAS_WIDTH;
                if(lassoRect[3] > CANVAS_HEIGHT) lassoRect[3] = CANVAS_HEIGHT;

                lassoPointSave.push(lassoRect);
                lassoPointSave.push(lassoPoints);

                const lassoDone:Boolean = doLassoDraw(false,lassoRect,lassoPoints);
                if(!lassoDone)
                {
                    resetLassoBox();
                    return;
                }

                drawPreviewLine();

                //라소 메뉴 마우스 커서에보이기
                const _lassoMenu:lassoButtons = lassoMenu;
                const floor:Function = Math.floor;

                lassoStartData = [lassoBox.x,lassoBox.y,lassoBox.scaleX,lassoBox.scaleY,lassoBox.rotation];
                lassoToolON = true;
                checkLassoMenuPos();
                _lassoMenu.visible = true;
                setTopChildIndex(_lassoMenu);

                if(traceMenuON === true) traceMenuBox.visible = false;
                toolBox.alpha = BUTTON_OFF_ALPHA;
                addMouseKeyEventLassoTool();
            }

            function lassoDrawMouseMove(MouseEvent:Event):void
            {
                const x:Number = cd.mouseX;
                const y:Number = cd.mouseY;
                
                lassoPoints.push([x,y]);
                if(timer === 0)
                {
                    timer = setTimeout(function():void
                    {
                        timer = 0;
                        drawPreviewLine();
                    },KEY_REPEAT_INTERVAL);
                }

                //사각형 꼭지점 체크
                if(x < lassoRect[0]) lassoRect[0] = x;
                else if(x > lassoRect[2]) lassoRect[2] = x;

                if(y < lassoRect[1]) lassoRect[1] = y;
                else if(y > lassoRect[3]) lassoRect[3] = y;
            }

            return function():void
            {
                if(lassoToolON === true) return;

                timer = 0;
                canvas2FilterBackUp = canvas2Draw.filters.concat();
                canvas2Draw.filters = [];

                clickPos.x = cd.mouseX;
                clickPos.y = cd.mouseY;
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
                lassoBitmapdataSave = canvas1BitmapData.clone();
                stageMouseMoveEvent.add(lassoDrawMouseMove);
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

            var canvas1bmp:Bitmap;
            var canvas1bmpd:BitmapData;
            var spuitbmpd:BitmapData;
            var penColorBackup:uint;
            var _colorHistoryList:Array;
            var colorHistoryLen:int;
            var colorHistoryFindIndex:int;

            function pickColor():uint
            {
                return (isHitTestPoint(canvas1Bitmap)) ?
                  spuitbmpd.getPixel(canvas1Bitmap.mouseX,canvas1Bitmap.mouseY)
                : penColorBackup;
            }

            //픽커 도중에 오른쪽 클릭하면 캔슬해줌
            function colorPickerCancelKeyUpEvent(e:KeyboardEvent):void
            {
                if(e.keyCode === KEY.c || e.keyCode === KEY.m)
                {
                    colorPickerOFF(true);
                }
            }

            function colorPickerCancelKeyDownEvent(e:KeyboardEvent):void
            {
                if(e.keyCode === KEY.c || e.keyCode === KEY.m)
                {
                    return;
                }

                colorPickerOFF(false);
            }

            function colorPickerCancelMouseEvent(e:MouseEvent):void
            {
                colorPickerOFF(false);
            }

            function colorPickerOKMouseEvent(e:MouseEvent):void
            {
                const targetName:String = e.target.name;
                
                if(spuitCursor.visible)
                    colorPickerOFF(true);
                else
                    colorPickerOFF(false);
            }

            function colorPickerOFF(okFlag:Boolean):void
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
                spuitbmpd.dispose();
                spuitCursor.visible = false;
                setOldTool();
                //move에서 spuitBitmapData를 쓰고 있기 때문에 이벤트를 먼저 해제해주고 데이터 비워줌
            }

            function colorPickerMoveEvent(e:MouseEvent):void
            {
                const targetName:String = e.target.name;

                spuitCursor.x = mouseX;
                spuitCursor.y = mouseY;

                if(targetName && targetName.indexOf("canvas") !== -1 || targetName === "canvasGrid")
                {
                    spuitCursor.visible = true;
                    _setColorTransform(spuitCursor["spuitNowColor"],pickColor()); 
                }
                else
                {
                    spuitCursor.visible = false;
                }
            }

            function removeSpuitEvent():void
            {
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,colorPickerOKMouseEvent);
                stageMouseMoveEvent.remove(colorPickerMoveEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, colorPickerCancelMouseEvent);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, colorPickerCancelKeyDownEvent);
                stage.removeEventListener(KeyboardEvent.KEY_UP, colorPickerCancelKeyUpEvent);
            }

            function addSpuitEvent():void
            {
                stage.addEventListener(MouseEvent.MOUSE_DOWN,colorPickerOKMouseEvent,false,-2);
                stageMouseMoveEvent.add(colorPickerMoveEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,colorPickerCancelMouseEvent);
                stage.addEventListener(KeyboardEvent.KEY_DOWN,colorPickerCancelKeyDownEvent,false,2);
                stage.addEventListener(KeyboardEvent.KEY_UP,colorPickerCancelKeyUpEvent,false,2);
            }

            return function ():void
            {
                canvas1bmp = canvas1Bitmap;
                canvas1bmpd = canvas1BitmapData;
                _colorHistoryList = colorHistoryList;
                colorHistoryLen = colorHistoryList.length;
                colorHistoryFindIndex = -1;
                toolBox.moveToolCursor("toolSpuit");

                oldTool = nowTool;
                spuitbmpd = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,false,CANVAS_BG_COLOR);
                spuitbmpd.draw(canvas1BitmapData);
                penColorBackup = penColor;
                setNowTool(TOOL_SPUIT);
                _setColorTransform(spuitCursor["spuitOldColor"],penColor);
                moveEraseButton("toolSpuit");
                
                if(isHitTestPoint(canvas1Bitmap) === true
                && mouseX > STAGE_LEFT_OFFSET && mouseX < stage.stageWidth-STAGE_RIGHT_OFFSET //캔버스 영역안에서만
                && mouseY > STAGE_TOP_OFFSET && mouseY < stage.stageHeight-STAGE_BOTTOM_OFFSET)
                {
                    spuitCursor.x = mouseX;
                    spuitCursor.y = mouseY;
                    _setColorTransform(spuitCursor["spuitNowColor"],pickColor());
                    setTopChildIndex(spuitCursor);
                    spuitCursor.visible = true;
                }

                addSpuitEvent();
            };
        }

        private function setOptimizeCanvasMove(flag:Boolean):void
        {
            if(canvasTraceLayer.alpha > 0.0) canvasTraceLayer.visible = !flag;
        }

        private function cHandTool():Function
        {
            const old:Point = new Point(0,0);;

            var _replayMode:Boolean;
            var isDrawMode:Boolean;
            var xReg:Sprite;
            var xBitmap:Bitmap;

            function handToolUpEvent(e:MouseEvent):void
            {   
                stageMouseMoveEvent.remove(handToolMoveEvent);
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
                            lassoMenu.visible = true;
                            lassoMenuTempOFF = false;
                            resetNowKey();
                        }
                        checkLassoMenuPos();
                    } //tool box에서 클릭해서 핸드툴 들어갈때 필요함
                    else if(!isNowKey(KEY.space)) setOldTool();
                    
                    if(!isDeepUndoON) toolBox.setCursorVisible(true);
                    updatePreviewBoxRectPos();
                }
                else
                {
                    updateReplayCanvasBounds();
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

                stageMouseMoveEvent.add(handToolMoveEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,handToolUpEvent);
                //윈도우 바깥에서 up을 하면 hand가 안꺼져서 오른쪽 마우스 뗄떼도 꺼주게함
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,handToolUpEvent);
            };
        }

        //zoom이나 rotate reg포인트 바뀔때마다
        //캔버스 판넬위치 따라 다니면서 크기 똑같이 해줌
        private function updateResizeButtonPos():void
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
            const w:Number = CANVAS_WIDTH;
            const h:Number = CANVAS_HEIGHT;
            const top:Number = cpPosY-buttonSize;
            const bottom:Number = cpPosY+h;
            const left:Number = cpPosX-buttonSize;
            const right:Number = cpPosX+w;

            setpos(resizeButtonU,left, top,    w+buttonSize2, 0);
            setpos(resizeButtonD,left, bottom, w+buttonSize2, 0);
            setpos(resizeButtonL,left, top,    0,             h+buttonSize);
            setpos(resizeButtonR,right,top,    0,             h+buttonSize);
        }

        //라소 취소하면 undo이전 이미지로 되돌림
        private function setLassoOKButton():void
        {
            if(lassoToolON === true)
            {
                if(isLassoUsed()  === true) //사용후에 ok하면 처리해줌
                {
                    clearButtonClicked = false;
                    const lassoBMPScaleX:Number = lassoBox.scaleX;
                    const lassoBMPScaleY:Number = lassoBox.scaleY;
                    const lassoBMPWidth:Number = lassoBMP.width*lassoBMPScaleX;
                    const lassoBMPHeight:Number = lassoBMP.height*lassoBMPScaleY;
                    const boxX:Number = lassoBox.x;
                    const boxY:Number = lassoBox.y;
                    const ang:Number = lassoBox.rotation*Math.PI/180;
                    var posMatrix:Matrix = new Matrix();

                    posMatrix.scale(lassoBMPScaleX,lassoBMPScaleY);//스케일부터 조절해주고
                    posMatrix.translate(-lassoBMPWidth/2,-lassoBMPHeight/2); //회전 중심점을 bmp중심으로 옮겨주고
                    posMatrix.rotate(ang);//회전해줌
                    posMatrix.translate(boxX,boxY);//라소박스 위치 그대로 붙여주면됨

                    //캔버스 1에 그려줌
                    lassoBMP.smoothing = true;

                    if(lassoBMPScaleX !== 1 || lassoBox.rotation !== 0)
                    {
                        applyLassoShapen(lassoBMPScaleX);
                    }

                    canvas1BitmapData.draw(lassoBMP,posMatrix);
                    canvas1Bitmap.bitmapData = canvas1BitmapData;
                    if(lassoBitmapdataSave) lassoBitmapdataSave.dispose();

                    const point1:Vector.<Number> = lassoPointSave[0].concat();
                    const point2:Array = lassoPointSave[1].concat();
                    const lassoInfos:Array = [lassoBMPScaleX,lassoBMPScaleY,
                                                lassoBMPWidth,lassoBMPHeight,
                                                ang,boxX,boxY];

                    rDataBuffer.push(["lasso",point1,point2,lassoInfos,lassoCopyON]);
                    addUndoData();
                }
                else lassoCancelBmpd();

                disposeLassoBMP();
            }
            resetLassoBox();
        }

        private function disposeLassoBMP():void
        {
            if(lassoBMP.bitmapData !== null)
            {
                lassoBMP.bitmapData.dispose();
                lassoBMP.bitmapData = null;
            }
        }

        private function lassoCancelBmpd():void
        {
            canvas1BitmapData = lassoBitmapdataSave.clone();
            canvas1Bitmap.bitmapData = canvas1BitmapData;
            previewBox.updateImage(canvas1BitmapData,CANVAS_BG_COLOR);
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
        }

        private function selectZoomTool():void
        {
            setNowTool(TOOL_ZOOM);
            toolBox.moveToolCursor("toolZoom");
        }

        private function selectRotateTool():void
        {
            setNowTool(TOOL_ROTATE);
            toolBox.moveToolCursor("toolRotate");
        }

        private function selectLassoTool():void
        {
            updateOldTool();
            setNowTool(TOOL_LASSO);
            moveEraseButton("toolLasso");
            toolBox.moveToolCursor("toolLasso");
        }

        private function selectFillPenTool():void
        {
            setNowTool(TOOL_FILL_PEN);
            setFillPen(true);
            moveEraseButton("toolFillPen");
            toolBox.moveToolCursor("toolFillPen");
            controlBox.controlInfo.text = "Fill-pen Options";
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
                    _controlBox.pixelSnapButtonWrapper.alpha = 1.0;
                    _controlBox.subLayerButtonWrapper.alpha = 1.0;
                                
                    if(subLayerON) canvasPanel.setChildIndex(canvas1,2);
                    else canvasPanel.setChildIndex(canvas2,2);

                    setAirBrushCheckBox(airBrushON,true);
                }
                else
                {
                    sizeIndex = eraseSizeIndex;
                    alphaIndex = eraseAlphaIndex;
                    _controlBox.pixelSnapButtonWrapper.alpha = BUTTON_OFF_ALPHA;
                    _controlBox.subLayerButtonWrapper.alpha = BUTTON_OFF_ALPHA;
                    
                    canvasPanel.setChildIndex(canvas2,2);

                    setAirBrushCheckBox(eraseAirBrushON,false);
                }
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
                        _controlBox.controlInfo.text = "Pen Options";
                    }
                    else
                    {
                        if(eraseMovedButton) eraseMovedButton.visible = true;

                        eraseMovedButton = null;

                        eraseButton2.visible = false;
                        toolBox.moveToolCursor("toolErase");
                        _controlBox.controlInfo.text = "Eraser Options";
                    }
                }
                else //선툴을 선택했을때
                {
                    if(penFlag)
                    {
                        moveEraseButton("toolLine");
                        toolBox.moveToolCursor("toolLine");
                        _controlBox.controlInfo.text = "Line Options";
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
            lassoMenu.visible = false;
            lassoDraw.x = 0;
            lassoDraw.y = 0;
            lassoBox.x = 0;
            lassoBox.y = 0;
            lassoBox.scaleX = 1.0;
            lassoBox.scaleY = 1.0;
            lassoBox.rotation = 0;
            lassoBox.visible = false;
            lassoResizeMoveSum = 0;
            lassoMenu["lassoCopy"].alpha = 1.0;
            lassoBitmapdataSave.dispose();

            controlBox.visible = true;
            pickerBox.visible = true;

            if(traceMenuON === true)
            {
                traceMenuBox.visible = true;
            }

            toolBox.alpha = 1.0;

            setOldTool();
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
            if(xReg.x === tx && xReg.y === ty) return;

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
            const w:uint = d[1];
            const h:uint = d[2];
            const bg:uint = d[3];
            const index:int = undoIndex;
            const _tickDraw:Object = tickDraw;
            const _zoomed:Number = zoomed;

            rMirrorON = false; //미러가 안된 상태의 undoimage를 깔아주기 때문에 처음에는 false로 설정해야함
            if(w !== RCANVAS_WIDTH || h !== RCANVAS_HEIGHT) changeCanvasSizeReplayMode(w,h,0,0,false);
            if(bg !== RCANVAS_BG_COLOR) setBackgroundColorReplayMode(bg);

            rcanvas1BitmapData = image.clone();
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;

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

            canvas1BitmapData = rcanvas1BitmapData.clone();
            canvas1Bitmap.bitmapData = canvas1BitmapData;

            if(mirrorON !== rMirrorON)
            {
                mirrorPushReady = true;
                mirrorDraw();
            }
            else
            {
                mirrorPushReady = false;
            }

            previewBox.updateImage(canvas1BitmapData,CANVAS_BG_COLOR);
            checkCanvasPanelPos(); //사이즈가 크가 줄었을때 캔버스가 창 밖으로 나가는거 체크
            updatePreviewBoxRectPos();
        }

        private function redo():void
        {
            const len:int = rData.length-1;
            undoIndex++;
            if(undoIndex > len)
            {
                undoDelFlag = false;
                replayONUndoUpdate = false;
                undoIndex = len;
            }
            else
            {
                saveOneTime = false;
                drawUndoData(true);
            }
        }

        private function undo():void
        {
            undoIndex--;
            if(undoIndex < -1)
            {
                undoIndex = -1;
                if(!isDeepUndoON)
                {
                    if(getTimer() - isDeepUndoONDelayTime > 200
                    && (makeJumpImageFlag === 1 || (makeJumpImageFlag === 0 && undoData.getRFileTotalFrame() > 0)))
                    {
                        setDeepUndoUI(true);
                    }
                }
            }
            else
            {
                clearButtonClicked = false;
                undoDelFlag = true;
                replayONUndoUpdate = true;
                addUndoMode = 0;
                drawUndoData();
            }
        }

        private function setRedoButton(useAutoKey:Boolean):void
        {
            if(useAutoKey) setHoldKeyRepeat(redo);
            else redo();
        }

        private function setUndoButton(useAutoKey:Boolean):void
        {
            if(useAutoKey) setHoldKeyRepeat(undo);
            else undo();
        }

        private function forceUndoAndDeleteFrontData(index:int):void
        {
            const endIndex:uint = index;

            rData.splice(0,endIndex);
            rDataFrame.splice(0,endIndex);
            undoIndex = rData.length-1;
            saveOneTime = false;
            clearButtonClicked = false;
            replayONUndoUpdate = true;
            addUndoMode = 0;
        }

        private function forceUndoToIndex(index:int):void
        {
            undoIndex = index;
            saveOneTime = false;
            clearButtonClicked = false;
            replayONUndoUpdate = true;
            addUndoMode = 0;
            drawUndoData();

            //데이터 뒷부분 지워줌
            const startIndex:uint = index+1;
            rData.splice(startIndex);
            rDataFrame.splice(startIndex);
        }

        private function cAddUndoData():Object
        {
            const UNDO_LIMIT:int = 20;
            var rJumpImageCount:uint = 0;//데이터로 저장할때  rDataFrame 카운터 누적
            var rFileTotalFrame:Number = 0; //file에저장된 프레임수 누적해서 저장
            //undo 할때 이 데이터를 기준점으로 rData그려줌 메모리 적게 하려고
            var undoRefImage:Array = [rFirstImage.clone(),CANVAS_WIDTH,CANVAS_HEIGHT,CANVAS_BG_COLOR];

            function setUndoRefImageByReplayMode():void
            {
                undoData.setUndoRefImage([rcanvas1BitmapData.clone()
                                            ,rcanvas1BitmapData.width
                                            ,rcanvas1BitmapData.height
                                            ,RCANVAS_BG_COLOR]);
            }

            function setUndoRefImageByDrawMode():void
            {
                undoData.setUndoRefImage([canvas1BitmapData.clone()
                                            ,canvas1BitmapData.width
                                            ,canvas1BitmapData.height
                                            ,CANVAS_BG_COLOR]);
            }

            function updateUndoDataFirst():void
            {
                const d:Array = undoRefImage;
                const image:BitmapData = d[0];
                const w:uint = d[1];
                const h:uint = d[2];
                const bg:uint = d[3];
                const len:int = undoIndex;

                if(w !== RCANVAS_WIDTH || h !== RCANVAS_HEIGHT) changeCanvasSizeReplayMode(w,h,0,0,false);
                if(bg !== RCANVAS_BG_COLOR) setBackgroundColorReplayMode(bg);

                rcanvas1BitmapData = image.clone();
                rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;

                tickDraw.ready(rData[0]);
                tickDraw.drawAll();

                undoRefImage = [rcanvas1BitmapData.clone(),RCANVAS_WIDTH,RCANVAS_HEIGHT,RCANVAS_BG_COLOR];
            }

            function getUndoRefImage():Array
            {
                return undoRefImage;
            }

            function setUndoRefImage(arr:Array):void
            {
                undoRefImage = arr.concat();
            }

            function getRFileTotalFrame():Number
            {
                return rFileTotalFrame;
            }

            function setRFileTotalFrame(frame:Number):void
            {
                rFileTotalFrame = frame;
            }

            function updateLastRDataMirror(addMode:int):void
            {
                if(mirrorPushReady)
                {
                    mirrorPushReady = false;
                    if(rDataBuffer.length > 0 && rDataBuffer[0][0] !== "mirror")
                    {
                        addMode = 0;
                        addUndoMode = 0;
                        rDataBuffer.unshift(["mirror"]);
                    }
                }
                else
                {
                    if(rDataBuffer.length > 0 && rDataBuffer[0][0] === "mirror")
                    {
                        addMode = 0;
                        addUndoMode = 0;
                        rDataBuffer.shift();
                    }
                }
            }

            function updateLastRData(addMode:int):void
            {
                var arr:Array;

                if(addMode === 3) //배경색은 mirror랑 상관없어서 직접 대입
                {
                    arr = rDataBuffer.concat();
                    rData[rData.length-1] = arr;
                }
                else
                {
                    const bufferLen1:uint = rDataBuffer.length;
                    //for해주는 이유 버퍼갯수가 1개일때는 직접 대입하면 되는데
                    //mirror플래그가 있을수도 있기 때문에 요소를 하나씩 push해주어야함 ["mirror"]푸쉬 ["canvassize",123,23]푸쉬 이런식
                    for(var i:uint = 0; i < bufferLen1;i++)
                    {
                        arr = rDataBuffer[i];
                        rData[rData.length-1].push(arr);//배열안에 배열이 들어있음
                    }
                }

                rDataFrame[rDataFrame.length-1] = rData[rData.length-1].length;
                rDataBuffer = [];
            }

            function add(addMode:int=0):void
            {
                replayONUndoUpdate = true;

                if(undoDelFlag === true)
                {
                    const startIndex:uint = undoIndex+1;
                    undoDelFlag = false;
                    rData.splice(startIndex);
                    rDataFrame.splice(startIndex);
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
                        updateUndoDataFirst();

                        if(makeJumpImageFlag === 0)
                        {
                            if(rJumpImageCount > IMG_CACHE_INTERVAL)
                            {
                                const data:Array = undoRefImage;
                                const bmpd:BitmapData = data[0];
                                const w:int = data[1];
                                const h:int = data[2]
                                const bgColor:uint = data[3];
                                const _rFileTotalFrame:Number = rFileTotalFrame;
                                //위에서 쓰고나서 가능한 바이트랑 실제 바이트는 rf.size랑 다름, rf.size가 정확함
                                rJumpImageFrameData.push(_rFileTotalFrame);

                                const jumpimg:File = rJumpImageFolder.resolvePath((rJumpImageFrameData.length-1)+"");
                                const imgData:ByteArray = new ByteArray();
                                const newRectangle:Rectangle = new Rectangle(0,0,w,h);

                                bmpd.copyPixelsToByteArray(newRectangle,imgData);
                                imgData.compress();
                                fs.open(jumpimg,FileMode.WRITE);
                                fs.writeObject([imgData,w,h,bgColor,rf.size,_rFileTotalFrame]);//이미지 데이터,가로 세로, 배경색, 마지막 바이트 위치, 마지막 프레임 합
                                fs.close();
                                imgData.clear();
                                rJumpImageCount = 0;
                            }
                        }
                    }

                    rData.shift();
                    rDataFrame.shift();
                }

                updateLastRDataMirror(addMode);

                //연속해서 캔버스 사이즈와 move tool이용할경우 가장 마지막 데이터만 바꿔줌
                if(addMode > 0 && addUndoMode === addMode)
                {
                    updateLastRData(addMode);
                }
                else if(rDataBuffer.length > 0)
                { 
                    rData.push(rDataBuffer);
                    rDataFrame.push(rDataBuffer.length);
                    rDataBuffer = [];

                    saveOneTime = false;
                }

                undoIndex = rData.length-1;
                addUndoMode = addMode;
                previewBox.updateImage(canvas1BitmapData,CANVAS_BG_COLOR);
            };

            return {
                add:add,
                setRFileTotalFrame:setRFileTotalFrame,
                getRFileTotalFrame:getRFileTotalFrame,
                getUndoRefImage:getUndoRefImage,
                setUndoRefImage:setUndoRefImage,
                setUndoRefImageByReplayMode:setUndoRefImageByReplayMode,
                setUndoRefImageByDrawMode:setUndoRefImageByDrawMode
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
            const rgb:uint = (r << 16 | g << 8 | b);

            return rgb;
        }

        //h는 0에서 360, s v는 0~1.0 사이값 넣어줘야함
        private function HSVtoRGB(h:Number, s:Number, v:Number):Vector.<uint>
        {
            const nt:int = getTimer();
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

            if(penColor === penLastUpdateInfo[2] && index === penLastUpdateInfo[3])
                return;
            penLastUpdateInfo[2] = penColor;
            penLastUpdateInfo[3] = index;

            const alphaCursor:SimpleButton = _opabox["alphaCursor"];

            alphaCursor.x = curButton.x;
            alphaCursor.y = curButton.y+3;
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

        private function setSideBarRightPosition(ignoreCanvasMove:Boolean):void
        {
            const _sideBar:sidePanel = sideBar;
            const floor:Function = Math.floor;

            _sideBar.x = stage.stageWidth-_sideBar.w;

            sideBarScrollSet.x = 5;
            sideBarScrollSet.y = scrollSetMovedY;
            previewBox.x = 0;
            previewBox.y = 0;
            appInfoBox.x = -2;
            appInfoBox.y = previewBox.y+previewBox.BOX_HEIGHT+3;
            controlBox.x = 39;
            controlBox.y = appInfoBox.y+appInfoBox.height;
            pickerBox.x = 39;
            pickerBox.y = controlBox.y+controlBox.height+5;
            toolBox.x = 0;
            toolBox.y = controlBox.y+2;

            sideBarScrollBar.x = previewBox.x-sideBarScrollBar.width;
            sideBarScrollBar.y = scrollBarMovedY;

            _sideBar.y = topBar.BARSIZE;

            STAGE_RIGHT_OFFSET = _sideBar.w;
            STAGE_LEFT_OFFSET = 0;

            if(ignoreCanvasMove === false)
                regPoint.x -= STAGE_RIGHT_OFFSET;

            topBar.sideBarPositionButton.visible = false;
            topBar.sideBarPositionButton2.visible = true;
            topBar.sideBarOFFButton.visible = true;
            topBar.sideBarOFFButton2.visible = false;
        }

        private function setSideBarLeftPosition():void
        {
            const _sideBar:sidePanel = sideBar;
            const floor:Function = Math.floor;

            _sideBar.x = 0;

            sideBarScrollSet.x = 5;
            sideBarScrollSet.y = scrollSetMovedY;
            previewBox.x = 0;
            previewBox.y = 0;
            appInfoBox.x = -2;
            appInfoBox.y = previewBox.y+previewBox.BOX_HEIGHT+3;
            controlBox.x = 0;
            controlBox.y = appInfoBox.y+appInfoBox.height;
            pickerBox.x = 0;
            pickerBox.y = controlBox.y+controlBox.height+5;
            toolBox.x = controlBox.x+controlBox.width;
            toolBox.y = controlBox.y+2;

            if(toolBox.getDeafultY() === 0)
                toolBox.setDeafultY(toolBox.y);

            sideBarScrollBar.x = _sideBar.w;
            sideBarScrollBar.y = scrollBarMovedY;

            _sideBar.y = topBar.BARSIZE;

            STAGE_LEFT_OFFSET = _sideBar.w;
            STAGE_RIGHT_OFFSET = 0;

            regPoint.x += STAGE_LEFT_OFFSET;

            topBar.sideBarPositionButton.visible = true;
            topBar.sideBarPositionButton2.visible = false;
            topBar.sideBarOFFButton.visible = false;
            topBar.sideBarOFFButton2.visible = true;
        }

        private function updateScrollBar(height:Number):void
        {
            var g:Graphics = sideBarScrollBar.graphics;
            const color1:uint = uiColorSet[uiColorIndex][1];
            const color2:uint = uiColorSet[uiColorIndex][0];

            g.clear();
            g.lineStyle(1,color1,1.0,true);
            // g.lineStyle(1,0,0);
            g.beginFill(color2);
            g.drawRect(0,0,9,height);
            g.endFill();

            scrollBarHeight = height;
        }

        private function makeMenuFamlity():void
        {
            const floor:Function = Math.floor;
            const stw:int = stage.stageWidth;
            const stH:int = stage.stageHeight;
            const stw2:Number = floor(stw/2);
            const stH2:Number = floor(stH/2);

            aboutPanel.name = "aboutPanel";
            aboutPanel.setVersionInfo(APP_VERSION.toFixed(2));

            penSizePrev.alpha = 0.6;
            penSizePrev.x = stw2;
            penSizePrev.y = stH2;

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
            sideBarScrollBar.alpha = 0.5;

            STAGE_TOP_OFFSET = topBar.BARSIZE;

            updateWorkingTime();
            topBar.updateTimerPos(stage.stageWidth);

            stage.addChild(fileDragSelectBox);
            stage.addChild(traceMenuBox);
            stage.addChild(penSizePrev);
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

            rregPoint.name = "rregPoint";
            _rcanvasPanel.name = "rcanvasPanel";
            rcanvas1.name = "rcanvas1";
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

            rcanvas1.addChild(rcanvas1Bitmap);//canvas1에 투명 bmp도화지 추가
            rcanvas2.addChild(rcanvas2Bitmap);//
            rcanvas2.addChild(rcanvas2Draw);//canvas2에
            rcanvas2.blendMode = "layer";//캔버스1이랑 알파 불투명도가 겹치지 않게 layer모드로 해줌

            _rcanvasPanel.addChild(rcanvas1);//판넬에 canvas1추가
            _rcanvasPanel.addChild(rcanvas2);//판넬에 canvas2추가
            _rcanvasPanel.addChild(rcanvasPanelMask);//판넬에  마스크 추가
            _rcanvasPanel.addChild(rCursor);
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
            const _canvasPanel:Sprite = canvasPanel;

            regPoint.name = "regPoint";
            _canvasPanel.name = "canvasPanel";
            canvas1.name = "canvas1";
            canvas2.name = "canvas2";
            canvas2Draw.name = "canvas2Draw";
            penSizeCursor.name = "penSizeCursor";
            stageBG.name = "stageBG";
            canvasTraceLayer.name = "canvasTraceLayer";
            canvasGrid.name = "canvasGrid";

            penSizeCursor.visible = false;

            lassoBox.name = "lassoBox";
            lassoBox.addChild(lassoBMP);
            lassoBox.addChild(lassoDraw);

            lassoBox.visible = false;

            reiszePreviewRect.visible = false;
            captureAreaRect.visible = false;
            captureAreaRect.blendMode = "difference";

            setBackgroundColorDrawMode(CANVAS_BG_COLOR);
            updateCanvasPanelMask(CANVAS_WIDTH,CANVAS_HEIGHT);

            updateStageBG(uiColorSet[uiColorIndex][2]);

            canvasTraceLayer.alpha = CANVAS_TRACE_ALPHA;
            canvasTraceLayer.addChild(canvasTraceBitmap);
            canvas1.addChild(canvas1Bitmap);
            canvas2.addChild(canvas2Bitmap);
            canvas2.addChild(canvas2Draw);
            canvas2.blendMode = "layer";//캔버스1이랑 알파 불투명도가 겹치지 않게 layer모드로 해줌

            _canvasPanel.addChild(canvasTraceLayer);
            _canvasPanel.addChild(canvas1)
            _canvasPanel.addChild(canvas2);
            _canvasPanel.addChild(lassoBox);
            _canvasPanel.addChild(canvasGrid);
            _canvasPanel.addChild(canvasPanelMask);
            _canvasPanel.mask = canvasPanelMask;

            //canvasrotate가 중점으로 올수있게 위치를 절반으로세팅
            _canvasPanel.x = Math.floor(-_canvasPanel.width/2);
            _canvasPanel.y = Math.floor(-_canvasPanel.height/2);

            regPoint.addChild(_canvasPanel);

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
            const topOffset:Number = STAGE_TOP_OFFSET;
            const sideBarSetHeight:Number = sideBarSetHeight;
            sth = floor(sth-topOffset); //상단 메뉴 길이 빼줌 sth랑 sideBarSetHeight 같이 빼야함

            //창이 늘어났을때 여유공간 있으면 아랫쪽으로 옮겨줌
            const nowScrollSetBottom:Number = sideBarSetHeight+sideBarScrollSet.y;
            if(nowScrollSetBottom < sth)
            {
                var newYPos:Number = floor(sideBarScrollSet.y+(sth-nowScrollSetBottom));
                if(newYPos > 0) newYPos = 0;

                sideBarScrollSet.y = newYPos;
                scrollSetMovedY = newYPos;
            }
            
            if(sideBarSetHeight < sth || isDeepUndoON || fillPenStarted)
            {
                sideBarScrollBar.visible = false;
                return;
            }

            var scrollBarSize:Number = floor(sth*(sth/sideBarSetHeight));
            if(scrollBarSize < 50) scrollBarSize = 50;

            scrollBarHeight = scrollBarSize;
            updateScrollBar(scrollBarSize);

            //스크롤바 위치 갱신
            const scrollSetY:Number = Math.abs(sideBarScrollSet.y);
            const factor:Number = (sth-scrollBarSize)/(sideBarSetHeight-sth);
            sideBarScrollBar.y = floor(scrollSetY*factor);

            sideBarScrollBar.visible = true;
        }

        private function windowResizedBeforeClosingEvent(e:Event):void
        {
            lastWindowState = 1
            // saveAllData();
            stage.nativeWindow.close();
        }

        private function windowResizeEvent(e:Event):void
        {
            clearTimeout(windowResizeDelayTimer)
            windowResizeDelayTimer = setTimeout(function():void 
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
                    captureWindowMove = new Point(dx,dy);
                    canvasFitWindow(true);
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
                    const _lassoMenu:lassoButtons = lassoMenu;
                    _lassoMenu.x += dx;
                    _lassoMenu.y += dy;
                    checkBoxPosition(_lassoMenu);
                }

                penSizePrev.x = stage.stageWidth/2;
                penSizePrev.y = stage.stageHeight/2;

                if(aboutPanelON) setAboutPanelCenterPos();
                
                if(replayModeON)
                {
                    updateReplayBarPos(stw);
                    updateReplayCanvasBounds();
                }

                updateStageBG(uiColorSet[uiColorIndex][2]);
                topBar.updateTopbarBG(stw);
                topBar.updateTimerPos(stage.stageWidth);

                sideBar.updateSideBGSize(sth-STAGE_TOP_OFFSET);
                updateScrollBarHeight(sth);
                if(isRightSidebar) sideBar.x = stage.stageWidth-sideBar.w;
                if(isDeepUndoON) toolBox.checkDeepUndoIconBottom();
                else if(fillPenStarted) toolBox.checkFillPenIconBottom();

                updatePreviewBoxRectPos();

                if(fileDragSelectBox.visible === true)
                    setDragDropSelectBoxCenterPos();
    
                _lastWindowSize.x = windowW;
                _lastWindowSize.y = windowH;
            },200);
        }

        private function setZoomCanvas(z:Number,replayMode:Boolean = false):void
        {
            const fz:Number = Math.floor(z*100+0.5)/100;
            var xReg:Sprite;
            
            if(!replayMode)
            {
                xReg = regPoint;
                zoomed = fz;
                if(!captureModeON) penCursorPosition.updateZoom(fz);
                if(airBrushSizeDrawMode > 0) setBlurCanvasBySizeDrawMode(airBrushSizeDrawMode);
            }
            else
            {
                updateRCursorScale(fz)
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
            if(makeJumpImageFlag === 2)
            {
                e.preventDefault();
                return;
            }
            windowClosingFlag = true;

            if(replayStartON === true) stopReplay();
            if(captureModeON === true) captureOFF();
            if(isNowTool(TOOL_LASSO)) setLassoCancelButton();

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
            parent.setChildIndex(ent, parent.numChildren-1);
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
            var xCanvas:Sprite;

            if(replayMode)
            {
                xReg = rregPoint;
                xCanvas = rcanvas1;
            }
            else
            {
                xReg = regPoint;
                xCanvas = canvas1;
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
        private function getStageCenterPos(captureMode:Boolean,replayMode:Boolean):Point
        {
            const floor:Function = Math.floor;
            const topBarOffset:Number = topBar.BARSIZE;
            const center:Point = new Point(0,0);

            if(captureMode)
            {
                center.setTo(stage.stageWidth/2,floor(topBarOffset+(stage.stageHeight-topBarOffset)/2));
            }
            else if(replayMode)
            {
                const repTopOffset:Number = topBarOffset+replayTimeBox.BARSIZE;
                center.setTo(stage.stageWidth/2,floor(repTopOffset+(stage.stageHeight-repTopOffset)/2));
            }
            else
            {
                center.setTo((isRightSidebar) ? floor((stage.stageWidth-STAGE_RIGHT_OFFSET)/2)
                                              : floor(STAGE_LEFT_OFFSET+(stage.stageWidth-STAGE_LEFT_OFFSET)/2)
                            ,floor(topBarOffset+(stage.stageHeight-topBarOffset)/2));
            }

            return center;
        }
        
        private function setCenvasCenterPos(replayMode:Boolean=false,captureMode:Boolean=false):void
        {
            var xReg:Sprite;
            var xCanvas:Sprite;
            var w:Number;
            var h:Number;

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

            const floor:Function = Math.floor;
            const center:Point = getStageCenterPos(captureMode,replayMode);

            xReg.x = floor(center.x);
            xReg.y = floor(center.y);
            xCanvas.x = floor(-w/2);
            xCanvas.y = floor(-h/2);
        }

        private function clearCanvasReplayMode():void
        {
            const w:uint = RCANVAS_WIDTH;
            const h:uint = RCANVAS_HEIGHT;

            rcanvas2Draw.graphics.clear();

            rcanvas1BitmapData.dispose();
            rcanvas1BitmapData = null;
            rcanvas1BitmapData = new BitmapData(w,h,true,0);
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;

            rcanvas2BitmapData.dispose();
            rcanvas2BitmapData = null;
            rcanvas2BitmapData = new BitmapData(w,h,true,0);
            rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
        }

        private function clearCanvas():void
        {
            const w:uint = CANVAS_WIDTH;
            const h:uint = CANVAS_HEIGHT;

            canvas1BitmapData.dispose();
            canvas1BitmapData = new BitmapData(w,h,true,0);
            canvas1Bitmap.bitmapData = canvas1BitmapData;

            canvas2BitmapData.dispose();
            canvas2BitmapData = new BitmapData(w,h,true,0);
            canvas2Bitmap.bitmapData = canvas2BitmapData;
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
            const finalStr:String = "Playback speed x "+_rSpeed+timeStr;
            topBar.hintTime(finalStr,topBar.replaySpeedSet);

            rSpeed = _rSpeed;
            topBar.setSpeedButtonPosByValue(_rSpeed,max);
            if(replayAllEnd === false) updateReplayRemainTime();
        }

        private function setReplaySpeedByKeyButton(upFlag:Boolean):void
        {
            setHoldKeyRepeat(setReplaySpeedByKey,upFlag);
        }

        private function keyUpReplayMode(e:KeyboardEvent):void
        {
            if(isNowKey(e.keyCode))
            {
                if(keyBuffer.length > 0) setNowKey(keyBuffer[0]);
                else resetNowKey();
            }
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
                    else if(input === KEY.c || input === KEY.m) setCaptureReady();
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
                    else setReplayUI(false);
                }
                break;

                case KEY.f1:
                case KEY.f6:
                    setCutFrameButton(CUT_FRAME_RE_RECORD,true);
                break;

                case KEY.f2:
                case KEY.f7:
                    setCutFrameButton(CUT_FRAME_SUPER_UNDO,true);
                break;

                case KEY.f3:
                case KEY.f8:
                    setCutFrameButton(CUT_FRAME_DELETE_FRONT,true);
                break;

                case KEY.n1:
                case KEY.n7:
                    setReplayUI(false);
                break;

                case KEY.enter:
                case KEY.space:
                {
                    if(replayStartON === false)
                        startReplay();
                    else
                        stopReplay();
                }
                break;
            }
        }

        private function keyUpDrawMode(e:KeyboardEvent):void //keyup1
        {
            const keyCode:int = e.keyCode;

            if(keyCode === nowKeyNotKeyUp)
            {
                nowKeyNotKeyUp = 0;
                if(keyBuffer.length === 0) resetNowKey();
            }

            if(isNowKey(keyCode))
            {
                if(mouseClickON === true) keyWaitMouseUp = true;
                else checkNextKeyDown();
            }
            if(!isPressingControl() && resizeButtonR.visible)
            {
                setResizeButtonVisible(false);
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
                if(isNowTool(TOOL_LINE)) setOldTool();

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
                    else if(input === KEY.c || input === KEY.m) setCaptureReady();
                    else if(input === KEY.v || input === KEY.n)
                    {
                        if(clipImageON) setClipButton();
                    }
                }) === false) setResizeButtonVisible(true);

                return;
            }

            //지우개키 조합 따로 체크
            if(isNowKey(KEY.d) || isNowKey(KEY.j))
            {
                if(checkOpaSizeKeyDown((keyBuffer.length >= 2) ? keyBuffer[1] : keyCode)) return;
            }

            if(isNowKey(keyCode)) return;

            setNowKey(keyCode);
            if(checkOpaSizeKeyDown(keyCode)) return;
            
            //etc키 먼저 체크하고 false반환하면 툴키 체크
            if(checkEtcKeyDown(keyCode)) return;
            checkToolKeyDown(keyCode);
        }

        private function checkEtcKeyDown(keyCode:int):Boolean
        {
            switch(keyCode)
            {
                case KEY.f1:
                case KEY.f6:
                {
                    nowKeyNotKeyUp = keyCode;
                    setGridButton();
                    topBar.hintTimeOff();
                }
                return true;

                case KEY.f2:
                case KEY.f7:
                {
                    nowKeyNotKeyUp = keyCode;
                    setSideBarPositionButton();
                }
                return true;

                case KEY.f3:
                case KEY.f8:
                {
                    nowKeyNotKeyUp = keyCode;
                    setUIColorButton();
                    topBar.hintTimeOff();
                }
                return true;
                
                case KEY.n2:
                case KEY.n8:
                {
                    nowKeyNotKeyUp = keyCode;
                    setReplayUI(true);
                }
                return true;

                case KEY.n3:
                case KEY.n9:
                {
                    nowKeyNotKeyUp = keyCode;
                    if(controlBox.pixelSnapButtonWrapper.alpha === 1.0)
                        setPixelSnap(!pixelSnapON);
                }
                return true;

                case KEY.n4:
                case KEY.n0:
                {
                    nowKeyNotKeyUp = keyCode;
                    airBrushON = !airBrushON;
                    setAirBrushCheckBox(airBrushON,true);
                }
                return true;

                case KEY.n5:
                case KEY.minus:
                {
                    nowKeyNotKeyUp = keyCode;
                    if(controlBox.subLayerButtonWrapper.alpha === 1.0)
                        setSubLayer(!subLayerON);
                }
                return true;

                case KEY.x:
                case KEY.comma:
                    nowKeyNotKeyUp = keyCode;
                    setRedoButton(true);
                return true;

                case KEY.z:
                case KEY.dot:
                    nowKeyNotKeyUp = keyCode;
                    setUndoButton(true);
                return true;

                case KEY.tab:
                case KEY.backslash:
                    nowKeyNotKeyUp = keyCode;
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
                    if(!traceMenuON) openTraceWindow();
                    else if(traceMenuON) closeTraceMenu();
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
                    setClearData(true);
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
                traceMenuBox["traceClipButton"].alpha = 1.0;
                clipImageON = true;
            }
            else
            {
                const offAlpha:Number = BUTTON_OFF_ALPHA;
                topBar["clipButton"].alpha = offAlpha;
                traceMenuBox["traceClipButton"].alpha = offAlpha;
                clipImageON = false;
            }
        }

        private function setClickBlockFlagOFFDelay():void
        {
            clearTimeout(clickBlockTimer);
            clickBlockTimer = setTimeout(function():void
            {
                clickBlockFlag = false;
            },150);
        }

        private function windowActiveEvent(e:Event):void
        {
            //알탭해주고 창 활성화 해줄때 한번은 안하게끔함
            startWorkingTimer();
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
            clearInterval(workingTimer);
            resetKeyBuffer();

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
                if(replayStartON === false)
                {
                    const nt:int = getTimer();
                    const subTime:int = nt-windowDeactivateTime;

                    if(subTime > 3000 || windowClosingFlag)
                    {
                        windowDeactivateTime = nt;
                        saveAllData();
                        System.gc();
                    }
                }
            }
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
            toolTipBox.visible = false;
            setResizeButtonVisibleTimer(false);
        }

        //툴메뉴에서 클릭했을때
        private function setToolBox2ClickTool(target:SimpleButton,func:Function):void
        {
            updateToolBoxMousePos(target);
            func();
            closeToolBox2();
        }

        private function mouseDownToolBox2(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if(!target || isDeepUndoON)
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

            if(!target || target.alpha < 1.0)
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
                case "deepUndoOK":
                {
                    superUndo();
                }
                break;

                case "deepUndoCancel":
                {
                    exitDeepUndoMode();
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
                    if(isDeepUndoON)
                    {
                        _jumpOneFrame(true,false);
                    }
                    else setUndoButton(false);
                }
                break;
                case "toolRedo":
                {
                    if(isDeepUndoON)
                    {
                        _jumpOneFrame(false,false);
                    }
                    else setRedoButton(false);
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
            const sth:Number = stage.stageHeight;
            const canMoveHeight:Number = (sth-STAGE_TOP_OFFSET)-scrollBarHeight;
            const diffHeight:Number = sideBarSetHeight-(sth-STAGE_TOP_OFFSET);
            const factor:Number = diffHeight/canMoveHeight;
            var scrollStarted:Boolean = false;
            var my1:Number = sideBarScrollBar.y;
            var my2:Number = sideBarScrollSet.y;

            mouseDragON = true;

            function sideBarMouseUpEvent(e:MouseEvent):void
            {
                mouseDragON = false;
                scrollSetMovedY = sideBarScrollSet.y;
                scrollBarMovedY = sideBarScrollBar.y;

                stageMouseMoveEvent.remove(sideBarMouseMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,sideBarMouseUpEvent);
            }

            function sideBarMouseMoveEvent(e:MouseEvent):void
            {
                const subY:Number = clickY-mouseY;

                my1 = my1-subY;
                my2 = my2+subY*factor;

                if(my1 < 0)
                {
                    my1 = 0;
                    my2 = 0;
                }
                else if(my1 > sideBar.h-sideBarScrollBar.height)
                {
                    my1 = sideBar.h-sideBarScrollBar.height;
                    my2 = -diffHeight;
                }

                sideBarScrollBar.y = floor(my1);
                sideBarScrollSet.y = floor(my2);

                clickY = mouseY;
            }

            clickY = clickY;
            stageMouseMoveEvent.add(sideBarMouseMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,sideBarMouseUpEvent);
        }

        private function checkToolBoxButtons(targetName:String):Boolean
        {
            if(!isNowKey(0)) return true;

            if(lassoToolON === false)
            {
                stage.addEventListener(MouseEvent.MOUSE_UP,checkToolBoxButtonUpEvent);
            }

            switch(targetName)
            {
                case "toolRotate":
                {
                    rotateTool(false);
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
                    return true;
                }

                return false;
            }
            return false;
        }

        private function setCanvasResizeButton(targetName:String,shortcut:Boolean):void
        {   
            penCursorOFFFlag = true;
            toolTipBox.visible = true;
            penSizeCursor.visible = false;
            setToolTipString(CANVAS_WIDTH+" x "+CANVAS_HEIGHT);
            setCanvasSize(targetName,shortcut);
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
            nowKeyNotKeyUp = 0;
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

        private function setDeepUndoUI(flag:Boolean):void
        {
            isDeepUndoON = flag;
            const iFlag:Boolean = !flag;
            cancelAutoKeyEvent({});

            topBar.hintOFF();
            penCursorOFFFlag = flag;
            rregPoint.visible = flag;
            regPoint.visible = iFlag;
            penSizeCursor.visible = iFlag;
            rCursor.visible = flag;
            replayTimeBox.visible = flag;
            setTopChildIndex(replayTimeBox);
            setTopChildIndex(rCursor);

            if(flag)
            {
                replayTimeBox.setTimeBarOnly(true);
                updateReplayBarPos(stage.stageWidth);
            
                if(makeJumpImageFlag === 1)
                {
                    replayTimeBox["frameInfo"].text = "Loading...";
                    setMakeJumpImage();
                }
                else
                {
                    if(!sideBar.visible) sideBar.setTempVisibleON(toolBox.BOX_WIDTH+10,isRightSidebar);
                    TOTAL_FRAME = getTotalFrame();
                    toolBox.checkDeepUndoIconBottom();
                    toolBox.deepUndoIconON();
                    toolBox.bgBoxVisible(true);
                    toolBox2.deepUndoIconON();
                    sideBarScrollBar.visible = false;
                    updateRCursorScale(zoomed);
                    removeInputEventDrawMode();
                    addInputEventDeepUndo();
                    syncReplayCanvasWithDrawMode();
                    updateRCursorScale(rzoomed);
                    topBar.resetHintColor();
                    if(traceMenuON === true) traceMenuBox.visible = false;
                    _jumpFrame(undoData.getRFileTotalFrame()-1,JUMP_FRAME_ONCE);
                    _jumpFrame(rPrevFrame,JUMP_FRAME_ONCE);
                    rOnejumpFlagSave = true;
                }
            }
            else
            {
                if(isSidebarVisible === false) sideBar.setTempVisibleOFF(isRightSidebar);
                replayTimeBox.setTimeBarOnly(false,topBar.BARSIZE);
                toolBox.checkBottomOFF();
                toolBox.deepUndoIconOFF();
                toolBox.bgBoxVisible(false);
                toolBox2.deepUndoIconOFF();
                updateScrollBarHeight(stage.stageHeight);
                syncDrawCanvasWithReplayMode();
                addInputEventDrawMode();
                removeDeepUndoEvent();
                if(traceMenuON === true) traceMenuBox.visible = true;
                if(isSidebarVisible === true) sideBar.visible = true;
                rDataPreviewCacheImages = [];
                changePickerModeToNormal();
                updatePenSizeCursor();
                updatePenCursorPosition();
                // changeTopBarIcons("draw");
            }
        }

        private function setMakeJumpImage():void
        {
            if(makeSKipImageWaitTimer === 0)
            {
                makeSKipImageWaitTimer = setTimeout(function():void
                {
                    makeSKipImageWaitTimer = 0;
                    _makeJumpImage();
                },60);
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

        private function setReplayUI(flag:Boolean):void
        {
            const iFlag:Boolean = !flag;

            replayModeON = flag;
            penCursorOFFFlag = flag;
            rregPoint.visible = flag;
            regPoint.visible = iFlag;
            penSizeCursor.visible = iFlag;
            replayTimeBox.visible = flag;
            rCursor.visible = flag;
            replayTimeBox["pauseButton"].visible = false;
            setTopChildIndex(replayTimeBox);
            resetCutFrameClickCounter();
            topBar.hintOFF();

            if(iFlag) //리플레이 꺼줄때
            {
                removeInputEventReplayMode();
                addInputEventDrawMode();
                clearDataButtonCount = 0;
                
                if(isSidebarVisible === true) sideBar.visible = true;
                if(replayStartON === true) stopReplay();

                resetOldTool();
                selectPenTool();
                rDataPreviewCacheImages = [];
                updatePreviewBoxRectPos();
                changePickerModeToNormal();
                updatePenSizeCursor();
                updatePenCursorPosition();

                if(traceMenuON === true) traceMenuBox.visible = true;

                changeTopBarIcons("draw");
                appInfoBox.setZoom(zoomed);
            }
            else if(flag) //리플레이 켜줄때
            {
                removeInputEventDrawMode();
                rCursor.visible = false;
                setTopChildIndex(rCursor);
            
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
                        canvasFitWindow();
                        rzoomed = 1;
                        rregPoint.scaleX = 1;
                        rregPoint.scaleY = 1;
                        rzoomedIndex = zoomArr.indexOf(rzoomed);
                    }
                }

                checkCutFrameButtons();
                updateReplayBarPos(stage.stageWidth);
                updateReplayCanvasBounds();
                updateRCursorScale(rzoomed);
                topBar.resetHintColor();

                if(traceMenuON === true) traceMenuBox.visible = false;

                if(makeJumpImageFlag === 1)
                {
                    replayTimeBox["frameInfo"].text = "Loading...";
                    sideBar.visible = false;
                    changeTopBarIcons("replay");
                    setMakeJumpImage();
                }
                else if(makeJumpImageFlag === 0)
                {
                    if(replayONUndoUpdate)
                    {
                        const totalFrame:Number = TOTAL_FRAME;
                        rDataReadFlag = false;
                        replayTimeBox["frameInfo"].text = totalFrame+" / " + totalFrame;
                        replayTimeBox["replayNowBar"].width = (totalFrame === 0) ? 0 : replayTimeBox["replayTotalBar"].width;
                        topBar["reRecordingButton"].alpha = BUTTON_OFF_ALPHA;
                        clearCanvasReplayMode();
                        resetReplayTime();
                        rNowFrame = totalFrame;
                        rPrevFrame = totalFrame-1;

                        rcanvas1BitmapData.dispose();
                        rcanvas1BitmapData = canvas1BitmapData.clone();
                        rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                        changeCanvasSizeReplayMode(canvas1Bitmap.width,canvas1Bitmap.height);
                        setBackgroundColorReplayMode(CANVAS_BG_COLOR);
                    }

                    checkCanvasPanelPos(flag);
                    sideBar.visible = false;
                    changeTopBarIcons("replay");
                    removeInputEventDrawMode();
                    addInputEventReplayMode();
                }
            }
        }

        private function rightMouseDownDeepUndo(e:MouseEvent):void
        {
            if(mouseClickON || !isNowKey(0)) return;
            if(isCursorInDrawArea()) openToolBox2();
        }

        private function mouseDownDeepUndo(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            const targetName:String = target.name;

            if(isCursorInDrawArea() && sideBar.hitTestPoint(mouseX,mouseY) === false)
            {
                handTool(true);
            }
            else
            {
                switch(targetName)
                {
                    case "replayNowBar":
                    case "replayTotalBar":
                    case "frameInfo":
                        setJumpFrameButton();
                    break;

                    case "toolUndo":setJumpOneFrame(true,false); break;
                    case "toolRedo":setJumpOneFrame(false,false); break;
                    case "deepUndoOK":superUndo(); break;
                    case "deepUndoCancel":exitDeepUndoMode(); break;
                }
            }
        }

        private function keyUpDeepUndo(e:KeyboardEvent):void
        {
            if(isNowKey(e.keyCode))
            {
                if(keyBuffer.length > 0) setNowKey(keyBuffer[0]);
                else resetNowKey();
            }
        }

        private function keyDownDeepUndo(e:KeyboardEvent):void
        {
            const keyCode:uint = keyBuffer[0];
            if(mouseClickON || rightMouseClickON || isNowKey(keyCode)) return;

            var subKey:int;
            if(isPressingControl())
            {
                checkCommandSubKey(2,false,function(input:int):void
                {
                    if(input === KEY.z || input === KEY.dot) superUndo();
                    else if(input === KEY.c || input === KEY.m)
                    {
                        exitDeepUndoMode();
                        setCaptureReady();
                    }
                })
                return;
            }

            setNowKey(keyCode);

            switch(keyCode)
            {
                case KEY.enter:
                    superUndo();
                break;

                case KEY.z:
                case KEY.dot:
                    setJumpOneFrame(true,false);
                break;

                case KEY.x:
                case KEY.comma:
                    setJumpOneFrame(false,false);
                break;

                case KEY.esc:
                case KEY.backspace:
                case KEY.n1:
                case KEY.n7:
                    exitDeepUndoMode();
                break;
                case KEY.n2:
                case KEY.n8:
                    exitDeepUndoMode();
                    setReplayUI(true);
                break;
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

            if(target.alpha < 1.0) return;

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
                case "dragDropFileButton":
                case "dragDropRefButton":
                case "dragDropCancelButton":
                case "playButton":
                case "pauseButton":
                case "replayPrev":
                case "replayNext":
                case "timer":
                {
                    if(!isNowKey(0)) return;
                    checkButtonUp(targetName);
                }
                break;
            }
        }

        //키를 2개 이상 누르고 있을때 먼저 누른키를 떼면 다음키로 설정함
        private function checkNextKeyDown():void
        {
            if(keyBuffer.length > 0)
            {
                const nextKey:int = keyBuffer[0];
                setNowKey(nextKey);
                checkToolKeyDown(nextKey);
            }
            else
            {
                resetNowKey();
                if(oldTool > TOOL_NONE) setOldTool();
                updatePenCursorPosition();
            }
        }

        private function mouseUpDrawMode(e:MouseEvent):void //mouseup1
        {
            if(keyWaitMouseUp)//단축키 떼고 마우스 땠을때 원래대로 돌림
            {
                keyWaitMouseUp = false;
                checkNextKeyDown();
            }
        }

        private function rightMouseDownReplayMode(e:MouseEvent):void
        {
            if(mouseClickON || !isNowKey(0)) return;

            const targetName:String = e.target.name;

            if(targetName === "repSaveButton") saveFile(true);
            else if(targetName === "replayPrev") setJumpOneFrame(true,true);
            else if(targetName === "replayNext") setJumpOneFrame(false,true);
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
            if(mouseClickON || !isNowKey(0) || isPressingControl()) return;

            const targetName:String = e.target.name;

            if(targetName === "saveButton") saveFile(true);
            else if(targetName === "loadButton") loadFile(true);
            else
            {
                if(fillPenStarted)
                {
                    fillPenTool.ok();
                }
                else if(!isSidebarVisible && sideBar.visible)
                {
                    penCursorPosition.setSideBarOFF();
                    penCursorPosition.setSidebarONDelay();
                }
                else if(isCursorInDrawArea())
                {
                    if(toolBox2ON && !isDeepUndoON) closeToolBox2();
                    else openToolBox2();
                }
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

                case "subLayerButtonWrapper":
                case "subLayerOFFButton":
                case "subLayerONButton":
                case "subLayerText":
                {
                    setSubLayer(!subLayerON);
                }
                return true;

                case "pixelSnapButtonWrapper":
                case "pixelSnapOFFButton":
                case "pixelSnapONButton":
                case "pixelSnapText":
                {
                    setPixelSnap(!pixelSnapON);
                }
                return true;

                case "airBrushButtonWrapper":
                case "airBrushOFFButton":
                case "airBrushONButton":
                case "airBrushText":
                {
                    if(isPenOrLineTool())
                    {
                        setAirBrush(!airBrushON);
                    }
                    else if(isEraseTool())
                    {
                        setAirBrush(!eraseAirBrushON);
                    }
                }
                return true;
            }

            return false;
        }

        private function checkPickerBoxButtons(target:DisplayObject):void
        {
            const nt:int = nowTool;

            if(toolBox2ON || (!isNowKey(0) && nt !== TOOL_FILL_PEN
                                           && nt !== TOOL_LINE
                                           && nt !== TOOL_PEN))
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
            if(lassoToolON) setLassoOKButton();
        }

        private function mouseDownLassoTool(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            const targetName:String = target.name;

            if(isCursorInDrawArea() && isHitTestPoint(lassoMenu) === false)
            {
                if(lassoMenuTempOFF)
                {
                    lassoMenu.visible = false;
                    if(isNowTool(TOOL_HAND)) handTool();
                    else if(isNowTool(TOOL_ZOOM)) zoomTool();
                    else if(isNowTool(TOOL_ROTATE)) rotateTool();
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
                        rotateTool();
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
                    case "lassoCancel": checkButtonUp(targetName); break;
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
                if(checkPickerBoxButtons(target) && isNowKey(0)) 
                {
                    return;
                }
                else if(checkControlBoxButtons(target) && (isPenOrLineTool() || isEraseTool())) 
                {
                    return;
                }
                else if(target.alpha === 1.0 && checkToolBoxButtons(targetName)) 
                {
                    return;
                }
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
                {
                    if(toolBox2ON || !isNowKey(0) || e.target.alpha < 1.0)
                        return;
                        
                    checkButtonUp(targetName);
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
                {
                    setSideBarScrollMove(mouseY);
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
                    setHandToolPreviewBox(true);
                return;

                case "traceRotateButton":
                {
                    setTopChildIndex(traceMenuBox);
                    setTraceRotateButton();
                }
                return;

                case "traceMoveButton":
                {
                    setTopChildIndex(traceMenuBox);
                    setTraceMoveButton();
                }
                return;

                case "traceResizeButton":
                {
                    setTopChildIndex(traceMenuBox);
                    setTraceResizeButton();
                }
                return;

                case "traceButtonWrapper":
                {
                    setTopChildIndex(traceMenuBox);
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
            if(isCursorInDrawArea() && clickBlockFlag === false)
            {
                switch (nowTool)
                {
                    case TOOL_FILL_PEN:fillPenTool.start();break;
                    case TOOL_PEN:penTool(true);break;
                    case TOOL_ERASE:penTool(false);break;
                    case TOOL_LINE:lineTool(true);break;
                    case TOOL_HAND:handTool();break;
                    case TOOL_LASSO:lassoTool();break;
                    case TOOL_ROTATE:rotateTool();break;
                    case TOOL_ZOOM:zoomTool();break;
                    case TOOL_MOVE:moveTool();break;
                }
            }
        }
    }
 }
