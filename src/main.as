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
    import flash.filters.BlurFilter; 
    import flash.filters.ConvolutionFilter;// ConvolutionFilter가 끝임

    public class main extends Sprite
    {   
        private const APP_VERSION:Number = 14.07;
        private var NEW_VERSION:String = APP_VERSION+"";
        private var UPDATE_FILE:File = File.applicationStorageDirectory.resolvePath("updateTmpFile.air");

        //단축키 keycode 리스트
        private const STAGE_FRAME:int = stage.frameRate;
        private const gKey:Object = {
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
                                        lalt:18, //as에서는 한글모드 관계 없이 왼쪽 오른쪽 전부 18번임
                                        ctrl:17,
                                        shift:16,
                                        space:32,
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
                                        backslash:220
                                        // f7:118,
                                        // f8:119,
                                        // f9:120,
                                        // f10:121,
                                        // f11:122,
                                        // f12:123
                                    }
        //툴 번호 미리 지정
                    ,TOOL_PEN:int = 1
                    ,TOOL_ERASE:int = 2
                    ,TOOL_LINE:int = 3
                    ,TOOL_HAND:int = 5
                    ,TOOL_LASSO:int = 6
                    ,TOOL_SPUIT:int = 7
                    ,TOOL_ZOOM:int = 8
                    ,TOOL_ROTATE:int = 9
                    ,TOOL_MOVE:int = 10
                    ,TOOL_FILL_PEN:int = 11

                    ,CANVAS_MIN_SIZE:int = 100
                    ,CANVAS_MAX_SIZE:int = 2000
                    ,BUTTON_OFF_ALPHA:Number = 0.15
                    ,COLOR_DARK:uint = 0x323232//어두운색
                    // ,COLOR_MID_DARK:uint = 0x666666//중간 어두운색
                    ,COLOR_MID_DARK:uint = 0x535353//0x5B5B5B//중간 어두운색
                    ,COLOR_MID_BRIGHT:uint = 0xB8B8B8//중간 밝은색
                    ,COLOR_BRIGHT:uint = 0xF0F0F0//0xECEAE7//밝은색
                    ,GC_TIME_OUT:int = 30

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

        //element
        private const canvas1Bitmap:Bitmap = new Bitmap(canvas1BitmapData,"auto",true)
                    ,canvas2Bitmap:Bitmap = new Bitmap(canvas2BitmapData,"auto",true)

        private const resizeButtonR:canvasResizeButton = new canvasResizeButton()//캔버스 리사이즈 하는 버튼
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
                    ,capturePreviewRect:Shape = new Shape()//스크린샷 박스 미리보기 그려줌
                    ,capturePreviewCursor:Shape = new Shape()//스크린샷 박스 미리보기 그려줌
                    ,toolBox:toolButtons = new toolButtons()
                    ,toolBox2:toolButtons2 = new toolButtons2()
                    ,rotateCursorBox:rotateCursor = new rotateCursor()//회전이 얼마나 됐는지 표시
                    ,lassoMenu:lassoButtons = new lassoButtons()//라소툴 버튼
                    ,lassoDrawG:Shape = new Shape() //라소 영역 선 그려주는 쉐이프
                    ,topBar:topMenu = new topMenu()
                    ,spuitZoomCursor:spuitMag = new spuitMag()
                    ,toolTipBox:toolTipBoxSet = new toolTipBoxSet()//도움말 버튼
                    ,stageBG:Sprite = new Sprite() //드래그 불러오기가 stage공백에서는 안되서 수동으로 전체바탕으로 만들어줌
                    ,aboutPanel:aboutBox = new aboutBox()
                    ,fillPenBox:fillPenButtons = new fillPenButtons()

                    // ,canvasTransBMP:canvasTransPanel = new canvasTransPanel()
                    ,fileDragSelectBox:loadBox = new loadBox()
                    ,controlBox:controlMenu = new controlMenu()
                    ,pickerBox:colorPickerBox = new colorPickerBox()
                    ,previewBox:previewPanel = new previewPanel()
                    ,appInfoBox:appInfoBar = new appInfoBar()
                    ,sideBar:sidePanel = new sidePanel()
                    ,sideBarScrollBar:Sprite = new Sprite()
                    ,sideBarScrollSet:Sprite = new Sprite()
                    // ,consoleBox:consolePanel = new consolePanel()
                    ,transBGBMPD:BitmapData = new BitmapData(16,16,false,0xFFFFFF)
                     //draw var
        private var canvas1BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,canvas2BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,lassoBMP:Bitmap = new Bitmap()
                    ,shiftKeyON:Boolean = false
                    ,controlKeyON:Boolean = false
                    ,appResetFlag:Boolean = false
                    ,repSpaceKeyON:Boolean = false//리플레이 스페이스 키 재생에서 계속누르는거 방지
                    ,mirrorON:Boolean = false //대칭 켜지면 올려줌
                    ,mirrorPushON:Boolean = false//undo redo하고 있는데 미러가 달라서 mirror draw가 실행 되고 난후에 올려줌
                    ,zoomArr:Array = [0.25,0.5,0.75,1.0,2.0,3.0,4.0,6.0,8.0,12.0,16.0,24.0,32.0]
                    ,zoomed:Number = 1.0
                    ,zoomedIndex:int = 3
                    ,rzoomedIndex:int = 3
                    ,mouseClickON:Boolean = false //클릭하면 올려줌
                    ,mouseDragON:Boolean = false//툴을 계속 클릭한채로 움직이면 topmenu의 힌트가 안켜지도록 함
                    ,nowTool:int = 1 //현재 툴 번호
                    ,nowToolBackup:int = 1 //툴백업
                    ,nowKey:uint = 0 //단축키 누른거 여기다가 저장
                    ,rNowKey:uint = 0 //리플레이 단축키 누른거 저장
                    ,afterToolOff:Boolean = false //키 떼기 전에 마우스 먼저 떼주었을때 플래그 올려줌
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
                    ,fillPenStarted:Boolean = false //채우기 펜 시작됨

                    // ,penSmoothTimer:uint = 0 //펜 손떨방 타이머 저장소
                    ,eraseOddOffset:Number = 0//지우개 변수
                    ,eraseSize:uint = 12
                    ,eraseSizeIndex:uint = 8
                    ,eraseShape:Boolean = false
                    ,eraseAlpha:Number = 1.0
                    ,eraseAlphaIndex:uint = 3
                    ,eraseAirBrushON:Boolean = false
                    ,penListShapeFlag:Boolean = false //펜 리스트에서 펜 모양 버튼 눌러줄때 툴이랑 상관없이 바꿔줌, 펜 미리보기 할때 필요
                    ,penLastUpdateInfo:Array = [null,null,null,null,null,null] //updatePenSizeCursor 중복 사용 방지를 위해서 마지막 크기 저장해놓고 같으면 건너뙴
                    ,addUndoMode:uint = 0 //addundo했을때 캔버스 이동 리사이즈, 배경색 변경 등 중복되는거 체크하는것임.

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
                    ,toolBoxAlwaysClickTool:String = "" //toolbox 항상 on해줬을때 아이콘을 클릭하고 땠을때 같은 아이콘인지 확인해주는 거임
                    ,toolBox2ON:Boolean = false //툴박스가 오른쪽 클릭으로 켜졌을때 올려줌

        //undo 관련변수
                    ,undoData:Array = [] //undo 이미지 데이터 보관소
                    ,undoIndex:int = 0 //undo redo할때 무슨 이미지인지 알려주는 undoImageData의 포인터 인덱스임
                    ,undoDelFlag:Boolean = false //undo하고 나서 addundo가 되었을때 뒷부분 데이터 전부 날려주는 플래그
                    ,readyAddUndo:Boolean = false //선을 그어줄대 선전체가 캔버스 바깥쪽에 있을수도 있으니까 이걸 판단해줌
                    ,clearButtonClicked:Boolean = false//clear button 여러번 누르기 금지 플래그

        //lasso 관련 변수
                    ,lassoToolON:Boolean = false //라소툴로 영역 선택하면 올려줌
                    ,lassoStartData:Array = [] //이 값이랑 비교해서 달라진게 있으면 ok할때 적용해줌
                    ,lassoMirrorON:Boolean = false //라소 mirror클릭했을때 마다 반전해줌
                    ,lassoMenuClickPos:Array = [0,0] //라소메뉴 클릭한 자리 저장
                    ,lassoMenuTempOFF:Boolean = false//툴 고정되어서 라소 선택하고 줌툴 클릭했을때 메뉴 잠시 없애주는 플래그
                    ,lassoResizeON:Boolean = false //라소 무브 클릭하면 켜줌 힌트 메세지 안없어지게
                    ,lassoResizeMoveSum:Number = 0//라소 무브 클릭 움직이는 합저장 줌 1배 스냅걸리게 할때 쓰임
                    ,lassoPointSave:Array = []
                    ,lassoCopyON:Boolean = false //lasso 복사 누르면 올려줌
                    ,lassoSharpData:Array =
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
        //window resize 관련 변수
                    ,lastWindowSize:Point = new Point() //창크기 조절 얼마나 됐을지 비교할때 마지막 크기 창크기 저장
        //save load 관련 변수
                    ,saveOneTime:Boolean = false //세이브 버튼 여러번 눌러서 데이터 계속 쓰여지는거 방지
                    ,saveFileName:String = "untitled.png"//세이브 파일 저장후에 이름을 이쪽에다가 보관해서 계속 그 이름으로 저장할수있게함
                    ,saveFilePath:String = saveFileName//파일 저장경로로 계속 저장 초기에는 filename이랑 똑같게 해줌
                    ,saveContinue:Boolean = false//한번 저장후에 다른이름으로 저장하기 전까지는 똑같은 이름으로 저장
                    ,clearDataButtonCount:uint = 0 //리플레이 취소 카운터

        //컬러 히스토리 관련 변수
                    ,colorHistoryList:Array = [0xFFFFFF,0x000000]
                    ,colorHistoryLimit:uint = 10
                    ,colorHistoryColorWidth:uint = 17//Math.floor(pickerBox.svBoxWidth/colorHistoryLimit)//히스토리 개별 색깔 가로 크기
                    ,colorHistoryRectH:uint = 19
                    ,colorHistoryIndex:uint = 1 //선택된 컬러 list의 인덱스
                    ,colorHistoryUpdateReady:Boolean = false //히스토리 업데이트 이벤트 추가되면 올려주는거
                    ,colorHistoryUpdateBGReady:Boolean = false //히스토리 업데이트 이벤트 추가되면 올려주는거

        //툴팁 관련 변수
                    ,toolTipHint:String = "" //topbar관련 힌트 여기 저장
                    ,toolTipBoxTimer:uint = 0

        //리플레이 관련 변수
        private const appDataFile:File = File.applicationStorageDirectory.resolvePath("appdata1407.301")
                    ,undoDataFile:File = File.applicationStorageDirectory.resolvePath("undodata.301")
                    ,repFile:File = File.applicationStorageDirectory.resolvePath("repdata.301")
                    ,repFileTemp:File = File.applicationStorageDirectory.resolvePath("temp_repdata.301") //파일을 저장하거나 불러올때 씀
                    ,rSkipImageFolder:File = File.applicationStorageDirectory.resolvePath("skipImages")
                    ,rSkipImageFrameDataFile:File = File.applicationStorageDirectory.resolvePath("skipframedata.301")
                    ,rFirstImageFile:File = rSkipImageFolder.resolvePath("0.img")
                    ,rFileStream:FileStream = new FileStream()//함수들을 왔다갔다 해야해서 전역으로 하나 ,
                    ,rregPoint:Sprite = new Sprite()//회전 스프라이트 부모
                    ,rcanvasPanel:Sprite = new Sprite()
                    ,rcanvas1:Sprite = new Sprite()
                    ,rcanvas2:Sprite = new Sprite()
                    ,rcanvas2Draw:Shape = new Shape()
                    ,rcapturePreviewRect:Shape = new Shape()//스크린샷 박스 미리보기 그려줌
                    ,rcapturePreviewCursor:Shape = new Shape()//스크린샷 커서 그려줌
                    ,rcanvasPanelMask:Shape = new Shape()
                    ,replayTimeBox:replayTimeBar = new replayTimeBar()
                    ,rcanvas1Bitmap:Bitmap = new Bitmap(rcanvas1BitmapData,"auto",true)
                    ,rcanvas2Bitmap:Bitmap = new Bitmap(rcanvas2BitmapData,"auto",true)
                    ,IMG_CACHE_INTERVAL:uint = 13000
                    ,REPLAY_MAX_SPEED:Number = 200
                    ,REPLAY_SPEED_DIST:Number = 180
                    ,rCursor:SimpleButton = new tinyCursor(); //재생할때 틀어주는 작은 마우스

        private var rcanvas1BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,rcanvas2BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,replayStartON:Boolean = false //리플레이 시작버튼 여러번 누르는거 방지
                    ,replayAllEnd:Boolean = true //리플레이가 자연히 끝났을때 올렽주는 플래그 가장 처음에 캔버스 싹쓸이 하기 위해서 넣어줌.
                    ,replayEndWithcanvasFitWindow:Boolean = false //리플레이가 follow cursor옵션으로 캔버스 작게 축소되서 끝났을때
                    ,replayModeON:Boolean = false //이건 모드 자체 껐다 켰다

                    ,rDataBuffer:Array = []
                    ,rData:Array = [] //rDataBuffer가 이쪽으로 이동되고 undo image data갯수에 똑같이맞추어줌
                    ,rDataFrame:Array = [] //rdata안에 몇프레임이 들어있는지 저장

        //아래 변수들은 전역으로 돌려야, 플레이 중간에 끊어도 계속 플레이 시킬 수 있음.
                    ,rLastBytes:Number = 0 //fs position 저장
                    ,rFileCutBytes:Number = 0 //super undo에서 파일 잘라줄때 필요함
                    ,rFrame:uint = 0 //실제 자잘 스트로크 프레임 인덱스
                    ,rIndex:uint = 0 //rData에서만씀 rData 스크로크 뭉치 인덱스
                    ,rFrameArr:Array = [] //이안의 데이터를 재생시킴
                    ,rLineStyleSave:Array = [] //tempdone에서 쓰는 플래그임
                    ,rSubLayerSave:Boolean = false //리플레이 실행할때 이걸로 비교해서 캔버스 스왑해줌
                    ,rTinyCursorPos:Array = [] //작은 커서 위치 갱신해주는데 쓰임
                    ,rBGColorSave:uint = RCANVAS_BG_COLOR //load replay에서 씀
                    ,rDataReadFlag:Boolean = false //rData에서 frameArr한번만 등록해주는 플래그
                    ,rSpeed:Number = 1 //리플레이 속도 for루프로 2번씩혹은 3번씩 읽히게 만듬
                    ,TOTAL_FRAME:Number = 0//rdata+file 프레임 전부 합친거
                    ,rFileTotalFrame:Number = 0 //file에저장된 프레임수 누적해서 저장
                    ,rFrameSum:Number = 0 //dodraw에서 현재까지 플레이된 프레임수 누적, skip frame이 가동됐을때 프레임 누적갯수를 세서 썸네일 이미지 만들어줌
                    ,rFrameSumLast:Number = 0 //skip one frame 에서 이전 프레임 탐색할때 이 프레임으로 탐색해줌
                    ,rFirstImage:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,rFirstBGColor:uint = CANVAS_BG_COLOR
                    ,rzoomed:Number = 1.0 //리플레이 줌
                    ,rSkipLastIndex:Number = -2 //썸네일 인덱스 바뀌면 여기다 저장
                    ,rSkipImageFrameData:Array = [0] //스킵이미지 저장될때 r file frame sum을 저장해줌 처음에 rfirstimage라서 0번 추가해줌
                    ,rSkipImageCount:uint = 0//데이터로 저장할때  rDataFrame 카운터 누적
                    ,rSkipImageInit:int = 0 //0이상이면 make skip image함수를 실행함. skipframe함수에서 체크
                    ,rOneSkipFlag:Boolean = false //oneskipframe에서 prev인지 next인지 마지막 상태 저장해줌, 방향바꿀대 버튼 2번씩 눌러야 스킵되는거 방지하는거임
                    ,rOneSkipTimer:int = 0 //키 오래 누르고 있으면 한꺼번에 처리해주는 타이머
                    ,rOneSkipPrevSum:Number = 0 //뒤로 스킵키 오래누르고 있으면 프레임 합산은 여기다가 올려줌
                    ,replayONUndoUpdate:Boolean = true//undo가 된 상태에서 리플레이 켜줄때 file까지만 읽은 상태까지 프레임 스킵 해주는
                    ,rRestartTimer:uint = 0 //리스타트 타이머
                    ,rRestartTimerCount:uint = 0 //리스타트 타이머
                    ,rFrameTextDelayTime:int = 0 //프레임 바 딜레이

                    ,rCanvasBounds:Object = null
                    ,REPLAY_FASTEST_TOTAL_TIME:Number = 0 //최고 배속으로 돌렸는데도 총 재생시간이 30초 이상이면 올려줌
                    ,REPLAY_SLOWDRAW_ACTIVE_SPEED:Number = 50 //이 배속 이상일경우 doDrawSlowEvent를 걸어줌
                    ,doDrawSlowEventON:Boolean = false //doDrawSlowEvent가 켜지면 올려줌
                    ,rSkipMouseON:Boolean = false //스킵프레임 마우스로 할때 올려줌 dodraw에서 바조절 안되게 하려고 하는거임
                    ,rDataPreviewCacheImages:Array = [] //이전 탐색 프레임 빠르게 하기 위해서 skipimage구간에서 더 잘게 이미지를 나누어주고 정보를여가다가 저장함
                    ,rSpeedLastStr:String = ""

        //about 관련 변수
                    ,aboutPanelON:Boolean = false //어바웃 창 떴을때 킴
                    ,needUpdate:int = 0 //새버전 나왔을때 올려주는 플래그
                    ,updateRryTimer:uint = 0
                    ,isCheckingUpdate:Boolean = false

        //cut Frame 관련 변수
                    ,cutFrameActiveButton:SimpleButton
                    ,cutFrameClickCounter:uint = 0 //1번 누르면 미리 보기, 2번 누르면 실행
                    ,cutFrameClickedButton:int = -1 //무슨 버튼 눌렀는지 저장
                    ,rCutDataSaveFrame:Number = 0//슈퍼언도나 앞짜르기 할때 마우스 왔다갔다 하면서 반복해서 눌러줄때 skiponeframe이 계속작동되는거 방지해줌 

        //스크린샷 관련 변수
                    ,captureModeON:Boolean = false //스크린샷 켜지면 올려줌
                    ,captureModeShortCutOFF:Boolean = false //단축키로 종료할때 연속해서 눌려서 한번 걸어줌
                    ,browseWindowON:Boolean = false //캡쳐 저장키 빠르게 누를때 에러 떠서 중복안되게 플래그 세워줌
                    ,capturePanelData:Object = {}
                    ,captureZoomed:Number = 1 // 사각형 그려줄때 선 두깨를 이 배율에 맞추어서 해줌
                    ,captureWindowMove:Array = [0,0] //스크린샷이 켜져있는 상태에서 창을 조절했을때, 스크린샷이 끝나고 나서 regpoint를 그만큼 움직여줘야함
                    ,xcapturePreviewCursor:Shape
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
                    ,clipImageShortCutON:Boolean = false //key 이벤트 한번만 작동되게 플래그 걸어줌

        //트레이스 레이어 변수
                    ,canvasTrace:Sprite = new Sprite()//트레이스 레이어임
                    ,canvasTraceBitmapDataRaw:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)//원본 참고레이어 데이터
                    ,canvasTraceBitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0) //리사이즈등 수정된 데이터
                    ,canvasTraceBitmap:Bitmap = new Bitmap()
                    ,CANVAS_TRACE_ALPHA:Number = 0.5
                    ,traceImageFile:File = File.applicationStorageDirectory.resolvePath("traceImg.301")
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
                    ,GRID_GAP:uint = 30
                    ,GRID_NORMAL_COLOR:uint = 0xBABABA
                    ,GRID_5UNIT_COLOR:uint = 0x515151

        //클로저 변수
                    ,setPenTool:Function = closurePenTool()
                    ,setLineTool:Function = closureLineTool()
                    ,setHandTool:Function = closureHandTool()
                    ,setLassoTool:Function = closureLassoTool()
                    ,setRotateTool:Function = closureRotateTool()
                    ,setZoomTool:Function = closureZoomTool()
                    ,setMoveTool:Function = closureMoveTool()
                    ,setSpuitTool:Function = closureSpuitTool()
                    ,setFillPenTool:Object = closureFillPenTool()
                    ,checkAutoScroll:Object = closureAutoScroll()
                    ,doDraw:Function = closureDoDraw()
                    ,doTickDraw:Function = closureTickDraw()
                    ,checkUndoReady:Function = closureCheckUndoReady()
                    ,updatePenSizeCursor:Function = closureUpdatePenSizeCursor()
                    ,addUndoData:Function = closureAddUndoData()
                    ,checkToolKeyDown:Function = closureCheckToolKeyDown()
                    ,updatePenCursorPosition:Function = closureUpdatePenCursorPosition()
                    ,checkMainDrawTool:Function = closureCheckMainDrawTool()
                    ,drawCaptureArea:Object = closureDrawCaptureArea()
        //스크롤바 변수
                    ,scrollSetMovedY:Number = 0
                    ,scrollBarMovedY:Number = 0
                    ,scrollBarHeight:Number = 0
                    ,sideBarSetHeight:Number = 730
        //기타
                    ,windowClosingFlag:Boolean = false//윈도우 닫힐때 올려줌 save all data가 windows closing일때는 무조건 해주게 끔함
                    ,windowDeactivateTime:int = 0 //윈도우 비활성화된 시간 저장, 너무 자주 알탭해서 save all data가 자주 호출되는걸 막음
                    ,penCursorOFFFlag:Boolean = false //펜커서 이게 on되면 안보여줌
                    ,altCursorON:Boolean = false //키보드로 커서 변경해줄때 마지막 커서 색깔이 뭐였는지 저장
                    ,keyBufferArr:Array = [] //정식 키 다운 눌러준 상태에서 다른 키가 눌러져 있으면 여기다가 저장
                                             
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

                    ,tempDragDropFile:Object = []
                    ,tempCopiedImage:BitmapData
                    ,selectedNewPenSizeButtonIndex:int = 3
                    ,penSizePrevOFFTimer:int = 0
                    ,eraseMovedButton:SimpleButton = null //툴 선택해줬을때 지우개툴이 이동한 툴을 저장해줌 다시원래대로 복원해주려고
                    ,toolBox2ToolClicked:Boolean = false //툴박스에서 줌 이동 회전툴 클릭해주었을때 올려줌
                    ,zoomToolHintON:Boolean = false //툴박스에서 마우스 클릭해서 줌툴써줄때 mouse out이벤트가 가장 늦게 되서 줌 배율 힌트가 처음에 보이지 않는거 해결
                    ,controlBoxHintTimer:uint = 0 //컨트롤 박스 힌트 타이머 스무딩 힌트 일시적으로 보여줄때 사용
                    ,updateManualTimer:int = 0
                    ,clickBlockFlag:Boolean = false //알탭 하고나서 창활성화 되면 일정시간동안 작동하지 않게함
                    ,clickBlockTimer:int = 0 //비활성에서 활성화 될때 약간의 텀을주는 타이머
                    ,penSizeOpaKeyUpEventON:Boolean = false //펜 투명도 사이즈 단축키로 조절시 올려줌
                    ,isRightSidebar:Boolean = false // 사이드바 위치 0이 왼쩾 1이 오른쪽
                    ,isSidebarVisible:Boolean = true
                    ,limitMouseMoveEventTime:Function = closureLimitMouseMoveEventTime()
                    ,windowResizeDelayTimer:int = 0
                    ,windowMoveDelayTimer:int = 0
                    ,topBarHintClickEventON:Boolean = false //톱바 힌트가 켜졌을때 클릭하면 지워주는 이벤트
                    ,afkONCount:int = 0
                    ,gcONCount:int = 0
                    ,workingTimer:int = 0
                    ;
        //vars

        public function main():void
        {
            this.addEventListener(Event.ADDED_TO_STAGE, init);
        }

        private function init(e:Event):void //init1
        {
            windowStageElementSetting();
            makeCanvasFamily();
            makeReplayCanvasFamily();
            makeMenuFamlity();
            makeResizeButtonFamily();
            makeTransBG();
            updateWindowSizeInfo();
            updateResizeButtonPos();
            updateColorHistoryList();
            loadAppData(); //이전 세팅 복원
            resetReplayDataFile();
            checkVersion();
            initPickerBoxInfo(penColor);
            
            //캔버스 중점으로 옮겨주고, 리사이즈 이벤트 추가
            lastWindowSize.x = stage.nativeWindow.width;
            lastWindowSize.y = stage.nativeWindow.height;
            setCenvasCenterPos();
            setCenvasCenterPos(true);
            previewBox.updateImage(canvas1BitmapData,CANVAS_BG_COLOR);

            zoomedIndex = zoomArr.indexOf(zoomed); //줌 인덱스 업데이트

            colorHistoryUpdateReady = true;
            stage.addEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryEvent);
            stage.addEventListener(KeyboardEvent.KEY_UP, keyUpEvent);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownBufferEvent,false,3);
            stage.addEventListener(KeyboardEvent.KEY_UP,keyUpBufferEvent,false,3);
            
            //펜커서 업데이트 이벤트
            stage.addEventListener(MouseEvent.MOUSE_MOVE,updatePenCursorPositionEvent,false,-3);
            stage.addEventListener(MouseEvent.MOUSE_UP,updatePenCursorPositionEvent,false,-3);
            //
            stage.addEventListener(Event.MOUSE_LEAVE,stageHintOFFEvent,false);

            if(Capabilities.hasIME && IME.enabled) //다른 언어로 하면 자판 안먹어서 그냥 ime자체를안씀
            {
                IME.enabled = false;
            }

            startWorkingTimer();
        }
        
        //functions
        private function sideBarVisibleMouseLeaveEvent(e:Event):void
        {
            if(replayModeON || captureModeON) return;

            if(!isSidebarVisible && !sideBar.visible)
            {
                const mx:Number = mouseX;

                if((isRightSidebar && mx > stage.stageWidth-sideBar.w)
                || (!isRightSidebar && mx < sideBar.w))
                {
                    setSidebarVisible(true,true);
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
            if(appDataFile.exists) appDataFile.deleteFile(); //파일이 있으면 지워줌
            if(repFile.exists) repFile.deleteFile();
            if(rSkipImageFolder.exists) rSkipImageFolder.deleteDirectory(true);
            if(rSkipImageFrameDataFile.exists) rSkipImageFrameDataFile.deleteFile();
            if(undoDataFile.exists) undoDataFile.deleteFile();
            if(traceImageFile.exists) traceImageFile.deleteFile();
        }

        private function setSidebarVisible(flag:Boolean,tempFlag:Boolean):void
        {
            if(tempFlag === false)
                isSidebarVisible = flag;

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
                sideBar.visible = false;

                STAGE_RIGHT_OFFSET = 0;
                STAGE_LEFT_OFFSET = 0;

                tb.sideBarPositionButton.alpha = BUTTON_OFF_ALPHA;
                tb.sideBarPositionButton2.alpha = BUTTON_OFF_ALPHA;
            }
            if(tempFlag === false)
            {
                tb.checkSideBarONOFFButton(flag,isRightSidebar);
            }
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
                setBackgroundColor(hexColor);
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
            setBackgroundColor(arr[1]);
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
            const ba:ByteArray = new ByteArray;

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
                topBar.hintTimeError("Load failed");
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

        private function closureFillPenTool():Object
        {
            const floor:Function = Math.floor;
            const cd:Shape = canvas2Draw;
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

            function start():void
            {
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
                canvas2.alpha = xAlpha;
                xBlendMode = (xColor === CANVAS_BG_COLOR) ? "erase" : null;
                commandUndoIndexArr = [0];

                if(traceMenuON)
                    traceMenuBox.visible = false;

                command.push(1);
                data.push(cd.mouseX);
                data.push(cd.mouseY);

                setTopChildIndex(fillPenBox);
                fillPenBox.visible = true;
                fillPenStarted = true;
                toolBox.toolSelectCursor.visible = false;
                toolBox.alpha = BUTTON_OFF_ALPHA;

                _checkUndoReady();

                stage.addEventListener(MouseEvent.MOUSE_DOWN,fillPenMouseDownEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,fillPenMouseUpEvent);
                stage.addEventListener(MouseEvent.MOUSE_MOVE,fillPenMouseMoveEvent);
                stage.addEventListener(KeyboardEvent.KEY_UP,fillPenKeyUpEvent);
            }

            function _checkUndoReady():void
            {
                if(canvas1Bitmap.hitTestPoint(mouseX,mouseY) === true)
                {
                    clearButtonClicked = false;
                    readyAddUndo = true;
                }
            }

            function drawFillPenData(finish:Boolean=false):void
            {
                const g:Graphics = cd.graphics;
                const dataLen:int = data.length;

                g.clear();
                g.lineStyle(1,xColor);
                if(finish)
                {
                    g.beginFill(xColor);
                }
                g.drawPath(command,data);
                g.endFill();

                if(finish === false) //마지막 닫히는 선 그려주기 drawpath에서는 마지막선을 닫아주지 않음
                {
                    g.moveTo(data[dataLen-2],data[dataLen-1]);
                    g.lineTo(data[0],data[1]);
                }
            }

            function cancelFillPen():void
            {
                stage.removeEventListener(KeyboardEvent.KEY_UP,fillPenKeyUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,fillPenMouseMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,fillPenMouseDownEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,fillPenMouseUpEvent);
                
                canvas2.alpha = 1.0;
                mouseMoveCount = 0;
                timer = 0;
                fillPenStarted = false;
                fillPenBox.visible = false;
                toolBox.toolSelectCursor.visible = true;
                command.length = 0;
                data.length = 0;
                commandUndoIndexArr.length = 0;
                cd.graphics.clear();

                if(traceMenuON)
                {
                    traceMenuBox.visible = true;
                }

                toolBox.alpha = 1.0;
            }

            function endFillPenOK():void
            {
                if(data.length > 2)
                {
                    command.push(2);
                    data.push(data[0]);
                    data.push(data[1]); //마지막으로 원점으로 선을 한번 이어줘야 깔끔하게 닫힘

                    rDataBuffer.push(["fill",xColor,xAlpha,xBlendMode,command.concat(),data.concat()]);
                    drawFillPenData(true);
                    drawDone();
                }

                cancelFillPen();
            }

            function undoData():void
            {
                if(command.length === 0)
                {
                    return;
                }
                const commandIndex:int = commandUndoIndexArr[commandUndoIndexArr.length-1];

                command.splice(commandIndex,command.length);
                data.splice(commandIndex*2,data.length);
                commandUndoIndexArr.pop();

                if(command.length === 1)
                {
                    command.length = 0;
                    data.length = 0;
                    commandUndoIndexArr = [0];
                    cd.graphics.clear();
                }
                else
                {
                    drawFillPenData();
                }
            }

            function fillPenKeyUpEvent(e:KeyboardEvent):void
            {
                const keyCode:int = e.keyCode;
                if(mouseClickON)
                {
                    if(keyCode === gKey.q || keyCode === gKey.o || keyCode === gKey.enter)
                    {
                        afterKeyUpOK = true;
                    }
                    return;
                }

                if(keyCode === gKey.w || keyCode === gKey.i
                || keyCode === gKey.z || keyCode === gKey.dot)
                {
                    undoData();
                }
                else if(keyCode === gKey.q || keyCode === gKey.o
                || keyCode === gKey.enter)
                {
                    endFillPenOK();
                }
                else if(keyCode === gKey.esc)
                {
                    cancelFillPen();
                }
            }

            function fillPenMouseMoveEvent(e:MouseEvent):void
            {
                if(limitMouseMoveEventTime() === true)
                {
                    return;
                }

                if(readyAddUndo === false)
                {
                    _checkUndoReady();
                }
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

                if(mouseMoveCount++ > 100)
                {
                    mouseMoveCount = 0;
                    commandUndoIndexArr.push(command.length-1);
                }

                if(timer === 0)
                {
                    timer = setTimeout(function():void
                    {
                        timer = 0;
                        drawFillPenData();
                    },100);
                }
            }

            function fillPenMouseDownEvent(e:MouseEvent):void
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
                else if(!(mx <= STAGE_LEFT_OFFSET || mx >= stage.stageWidth -STAGE_RIGHT_OFFSET
                       || my <= STAGE_TOP_OFFSET  || my >= stage.stageHeight-STAGE_BOTTOM_OFFSET
                       || clickBlockFlag === true))
                {
                    stage.addEventListener(MouseEvent.MOUSE_MOVE,fillPenMouseMoveEvent);
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

                    clearTimeout(timer);
                    drawFillPenData();
                    mouseDragON = true;
                    mouseClickON = true;

                    if(readyAddUndo === false)
                    {
                        _checkUndoReady();
                    }
                }
            }

            function fillPenMouseUpEvent(e:MouseEvent):void
            {
                clearTimeout(timer);
                timer = 0;
                mouseMoveCount = 0;
                mouseDragON = false;
                mouseClickON = false;
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,fillPenMouseMoveEvent);

                const targetName:String = e.target.name;

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
                        undoData();
                    }
                }
                else
                {
                    commandUndoIndexArr.push(command.length-1);

                    if(afterKeyUpOK)
                    {
                        endFillPenOK();
                    }
                    else if(mouseMoved)
                    {
                        drawFillPenData();
                    }
                }

                afterKeyUpOK = false;
                mouseMoved = false;
            }

            return {
                start:start,
                ok:endFillPenOK,
                cancel:cancelFillPen
            };
        }

        private function closurePenTool():Function
        {
            const cd:Shape = canvas2Draw;
            const floor:Function = Math.floor; 
            const cdg:Graphics = cd.graphics;

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
            var clickX:Number; //점찍어 줄 때 판단하는 클릭한 자리 저장
            var clickY:Number; //점찍어 줄 때 판단하는 클릭한 자리 저장
            var cx:Number;// 첫 클릭한 지점
            var cy:Number;
            var smoothLastX:Number; //penmove할때 마지막x y저장
            var smoothLastY:Number; //penmove가 없을때 penmoveSMoothin함수는 이점을 목표로 이동함
            var pixelSnapLastX:Number;
            var pixelSnapLastY:Number;
            var moveEventLastX:Number;//픽셀거리 검출 변수
            var moveEventLastY:Number;
            var moveEventLastX2:Number;//픽셀거리 검출 변수
            var moveEventLastY2:Number;
            var penSmoothTimer:int; //펜 스무딩 할때 커서가 움직이지 않을때 나머지 그려지지않은 점들 이어주는 타이머임
            var distLimit:Number;//penmove에서 distlimit이하이면 skip해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌
            var shortDistFlag:Boolean; //확대 많이 하고 살짝 움직였을때 penmove에서 아예 처리를 안하는데 이걸 dot으로 처리하게 해줌
            var subLayerFlag:Boolean;
            var sqPenCursorLastX:Number;
            var sqPenCursorLastY:Number;

            const penCommand:Vector.<int> = new Vector.<int>(); //그냥펜
            const penPoints:Vector.<Number> = new Vector.<Number>(); //그냥펜 좌표
            
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
                var ox:Number = cx;
                var oy:Number = cy;
                const abs:Function = Math.abs;
                const smoothing:Number = _penSmoothValue;

                ox += (smoothLastX-ox)*smoothing;
                oy += (smoothLastY-oy)*smoothing;

                penMove2(ox,oy);

                if(floor(abs(smoothLastX-ox)*100) > 0 || floor(abs(smoothLastY-oy)*100) > 0)
                {
                    cx = ox;
                    cy = oy;

                    clearTimeout(penSmoothTimer);
                    penSmoothTimer = setTimeout(penMoveSmooth, 10);
                }
            }

            function penMove2(x:Number,y:Number):void
            {
                if(readyAddUndo === false) 
                {
                    checkUndoReady();
                }

                if(!_pixelSnap && (_penSmoothSlideValue > 0 || rotateFlag))
                {
                    x = floor(x*1000)/1000;
                    y = floor(y*1000)/1000;
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
                    rDataBuffer.push(["lineStyle",xShape,xSize,xColor,xAlpha,cx,cy,xBlendMode,false,subLayerFlag,_airBrushON]); //cx cy 처음 클릭한 지점으로 지정해줘야함
                    penCommand.push(1);
                    penPoints.push(cx);
                    penPoints.push(cy);

                    cdg.moveTo(cx,cy);
                }

                if(x === pixelSnapLastX &&  y === pixelSnapLastY)
                {
                    return;
                }
                else
                {
                    pixelSnapLastX = x;
                    pixelSnapLastY = y;
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
                    canvas2BitmapData.draw(cd,null,null,"layer");
                    canvas2Bitmap.bitmapData = canvas2BitmapData;
                    cdg.clear();

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
                    const rad:Number = Math.atan2(x-sqPenCursorLastX,y-sqPenCursorLastY);
                    const deg:Number = -rad*(180/Math.PI)+regPoint.rotation;
                    penSizeCursor.rotation = deg;
                    sqPenCursorLastX = x;
                    sqPenCursorLastY = y;
                }
            }

            function penToolMoveEvent(e:MouseEvent):void
            {
                //일정 시간 이내는 무시함
                if(limitMouseMoveEventTime() === true)
                {
                    shortDistFlag = true;
                    return;
                }

                const mx:Number = cd.mouseX+xOffset;
                const my:Number = cd.mouseY+xOffset;
                const fx:Number = floor(mx-xOffset)+xOffset;
                const fy:Number = floor(my-xOffset)+xOffset;

                // fx fy 반올림한 값이 브러시 크기 이하로 움직였을경우 플래그 올려줘서
                // mouse up에서 처리함
                if(fx === moveEventLastX2 && fy === moveEventLastY2)
                {
                    shortDistFlag = true;
                    return;
                }

                moveEventLastX2 = fx;
                moveEventLastY2 = fy;

                const sx:Number = (mx-moveEventLastX);
                const sy:Number = (my-moveEventLastY);
                const dist:Number = Math.sqrt(sx*sx+sy*sy);

                //브러쉬 크기 제한보다 작게 움직였을때 무시함
                if(dist < distLimit)
                {
                    shortDistFlag = true;
                    distLimit = distLimit-dist;

                    if(distLimit <= 0)
                    {
                        distLimit = xSize/5;
                    }
                    return;
                }

                distLimit = distLimit-dist;
                if(distLimit <= 0)
                {
                    distLimit = xSize/5;
                }

                moveEventLastX = mx;
                moveEventLastY = my;

                if(penToolFlag && _penSmoothSlideValue > 1)
                {
                    var ox:Number = cx;
                    var oy:Number = cy;
                    
                    if(penSmoothTimer > 0)
                    {
                        ox += (smoothLastX-cx)*_penSmoothValue;
                        oy += (smoothLastY-cy)*_penSmoothValue;
                    }
                    else
                    {
                        //처음에 적당한 거리 움직여줌
                        const mm:Point = movePointAngleDist(cx,cy,mx,my,1);
                        ox = mm.x;
                        oy = mm.y;
                    }

                    penMove2(ox,oy);

                    cx = ox;
                    cy = oy;
                    smoothLastX = mx;
                    smoothLastY = my;

                    clearTimeout(penSmoothTimer);
                    penSmoothTimer = setTimeout(penMoveSmooth,20);
                }
                else penMove2(mx,my);
            }

            function penToolUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, penToolUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, penToolMoveEvent);

                const x:Number = cd.mouseX;
                const y:Number = cd.mouseY;
                const mx:Number = x+xOffset;
                const my:Number = y+xOffset;

                if(penToolFlag && traceMemoryTraining)
                {
                    canvasTrace.visible = true;
                }
                
                if(_penSmoothSlideValue > 1)
                {
                    clearTimeout(penSmoothTimer);
                    penSmoothTimer = 0;
                }

                if(xShape === true)
                {
                    penSizeCursor.rotation = regPoint.rotation;
                }

                if(_penSmoothSlideValue > 1 && penToolFlag)
                {
                    const sx:Number = ((clickX+xOffset)-cx);
                    const sy:Number = ((clickY+xOffset)-cy);
                    const dist:Number = Math.sqrt(sx*sx+sy*sy);

                    if(dist < 0.2)
                    {
                        rDataBuffer.push(["dot",xShape,xSize,xColor,xAlpha,cx,cy,xBlendMode,subLayerFlag,_airBrushON]);
                        drawDot(xShape,xSize,xColor,cx,cy);
                    }
                }
                else if(mouseMovedFlag === false && ((clickX === x && clickY === y) || shortDistFlag))
                {
                    rDataBuffer.push(["dot",xShape,xSize,xColor,xAlpha,mx,my,xBlendMode,subLayerFlag,_airBrushON]);
                    drawDot(xShape,xSize,xColor,mx,my);
                }
                else if((penToolFlag && _penSmoothSlideValue <= 1) || !penToolFlag)
                {
                    if(!mouseMovedFlag)
                    {
                        lineStyleReady(xShape,xSize,xColor,xAlpha);
                        cdg.moveTo(cx,cy);
                        rDataBuffer.push(["lineStyle",xShape,xSize,xColor,xAlpha,cx,cy,xBlendMode,false,subLayerFlag,_airBrushON]); //cx cy 처음 클릭한 지점으로 지정해줘야함
                        rDataBuffer.push(["moveTo",mx,my]);
                    }
                    cdg.lineTo(mx,my);
                    rDataBuffer.push(["lineTo",mx,my]);
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
                if(subLayerFlag && xBlendMode === "erase")
                {
                    return;
                }

                _pixelSnap = pixelSnapON;
                rotateFlag = (regPoint.rotation % 90 === 0) ? false : true;
                _traceMemoryTraining = traceMemoryTraining
                xOffset = (sizeOffsetFlag) ? 0.5 : 0;

                if(penFlag && _traceMemoryTraining)
                {
                    canvasTrace.visible = false;
                }

                _penSmoothValue = penSmoothValue;//펜 스무딩 플래그
                _penSmoothSlideValue = penSmoothSlideValue;

                mouseMoveCount = 0; //마우스 이벤트에서 움직일때 올려주는 카운터 한번에 너무 많이 움직여주면 cpu부하 먹어서 100카운트 마다 bmp에 그려줌
                mouseMovedFlag = false;

                clickX = cd.mouseX; //점찍어 줄 때 판단하는 클릭한 자리 저장
                clickY = cd.mouseY; //점찍어 줄 때 판단하는 클릭한 자리 저장
                cx = clickX+xOffset;// 첫 클릭한 지점
                cy = clickY+xOffset;

                if(_penSmoothSlideValue === 0)
                {
                    cx = floor(cx-xOffset)+xOffset;
                    cy = floor(cy-xOffset)+xOffset;
                }

                smoothLastX = cx; //penmove할때 마지막x y저장
                smoothLastY = cy; //penmove가 없을때 penmoveSMoothin함수는 이점을 목표로 이동함
                pixelSnapLastX = cx;
                pixelSnapLastY = cy;
                moveEventLastX = cx;//픽셀거리 검출 변수
                moveEventLastY = cy;
                moveEventLastX2 = cx;//픽셀거리 검출 변수
                moveEventLastY2 = cy;
                sqPenCursorLastX = cx;
                sqPenCursorLastY = cy;

                penSmoothTimer = 0; //펜 스무딩 할때 커서가 움직이지 않을때 나머지 그려지지않은 점들 이어주는 타이머임
                distLimit = xSize/10;//penmove에서 distlimit이하이면 skip해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌
                shortDistFlag = false; //확대 많이 하고 살짝 움직였을때 penmove에서 아예 처리를 안하는데 이걸 dot으로 처리하게 해줌

                checkUndoReady();

                stage.addEventListener(MouseEvent.MOUSE_MOVE,penToolMoveEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,penToolUpEvent);
            };
        }


        private function stageHintOFFEvent(e:Event):void
        {
            setControlBoxInfoOFF();
            setTopBarHintOFF();
        }

        private function updatePenCursorPositionEvent(e:MouseEvent):void
        {
            if(clickBlockFlag || replayModeON || captureModeON)
            {
                return;
            }
            afkONCount = 0;

            updatePenCursorPosition();
        }

        private function closureUpdatePenCursorPosition():Function
        {
            const _penSizeCursor:Shape = penSizeCursor;
            var sidebarOFFTimer:int;
            var sidebarONTimer:int;
            var sidebarTempOFF:Boolean;
            var mouseUpEventON:Boolean;
            var visibleMouseUpEventON:Boolean;
            var nt:int;
            var mx:Number;
            var my:Number;
            var posInStage:Boolean;

            function sideBarTimeOut():void
            {
                clearTimeout(sidebarOFFTimer);
                sidebarOFFTimer = setTimeout(function():void
                {
                    stage.removeEventListener(MouseEvent.MOUSE_DOWN,sidebarOffMouseDownEvent);
                    stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,sidebarOffMouseDownEvent);
                    stage.removeEventListener(MouseEvent.MOUSE_UP,sidebarOffMouseUpEvent);
                    sidebarOFFTimer = 0;
                    if(isSidebarVisible === false)
                    {
                        setSidebarVisible(false,true);
                    }
                },500);
            }

            function sidebarONMouseUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP,sidebarOffMouseUpEvent);
                visibleMouseUpEventON = false;
                sidebarTempOFF = true;
                clearTimeout(sidebarONTimer);
                sidebarONTimer = setTimeout(function():void
                {
                    sidebarTempOFF = false;
                },1000);
            }

            function sidebarOffMouseUpEvent(e:MouseEvent):void
            {
                if(sideBar.hitTestPoint(mouseX,mouseY) === false)
                {
                    mouseUpEventON = false;
                    sideBarTimeOut();
                }
            }

            function sidebarOffMouseDownEvent(e:MouseEvent):void
            {
                if(sideBar.hitTestPoint(mouseX,mouseY) === false)
                {
                    stage.removeEventListener(MouseEvent.MOUSE_DOWN,sidebarOffMouseDownEvent);
                    stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,sidebarOffMouseDownEvent);
                    stage.removeEventListener(MouseEvent.MOUSE_UP,sidebarOffMouseUpEvent);
                    clearTimeout(sidebarOFFTimer);
                    sidebarOFFTimer = 0;
                    if(isSidebarVisible === false)
                    {
                        setSidebarVisible(false,true);
                    }
                }
            }

            return function():void
            {
                nt = nowTool;
                mx = mouseX;
                my = mouseY;
                posInStage = mx >= STAGE_LEFT_OFFSET 
                          && mx <= stage.stageWidth-STAGE_RIGHT_OFFSET
                          && my >= STAGE_TOP_OFFSET
                          && my <= stage.stageHeight-STAGE_BOTTOM_OFFSET;

                if((nt > 4 && nt !== TOOL_FILL_PEN )|| penCursorOFFFlag || !posInStage)//1 2 3 4 펜 지우개 라인툴 라인-지우개툴
                {
                    _penSizeCursor.visible = false;
                }
                else
                {
                    _penSizeCursor.x = mx;
                    _penSizeCursor.y = my;

                    if(_penSizeCursor.width < (8/zoomed) || nowTool === TOOL_FILL_PEN)
                    {
                        _penSizeCursor.visible = false;
                    }
                    else
                    {
                        _penSizeCursor.visible = true;
                    }
                }

                if(isSidebarVisible === false)
                {
                    if(sideBar.visible)
                    {
                        const offset:Number = (sideBarScrollBar.visible) ? 10 : 0;
                        //마우스 사이드바 바깥으로 나감
                        if(sideBar.hitTestPoint(mx,my) === false)
                        {
                            if(mouseClickON || mouseDragON)
                            {
                                if(mouseUpEventON === false)
                                {
                                    mouseUpEventON = true;
                                    stage.addEventListener(MouseEvent.MOUSE_UP,sidebarOffMouseUpEvent);
                                }
                            }
                            else 
                            {
                                if(sidebarOFFTimer === 0)
                                {
                                    sideBarTimeOut();
                                    stage.addEventListener(MouseEvent.MOUSE_DOWN,sidebarOffMouseDownEvent);
                                    stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,sidebarOffMouseDownEvent);
                                }
                            }
                        }
                        else if(sidebarOFFTimer !== 0)
                        {
                            clearTimeout(sidebarOFFTimer);
                            sidebarOFFTimer = 0;
                            stage.removeEventListener(MouseEvent.MOUSE_DOWN,sidebarOffMouseDownEvent);
                            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,sidebarOffMouseDownEvent);
                            stage.removeEventListener(MouseEvent.MOUSE_UP,sidebarOffMouseUpEvent);
                        }
                    } //마우스 사이드바 활성 영역으로 들어옴
                    else if((!isRightSidebar && mx <= 30 || isRightSidebar && mx >= stage.stageWidth-30)
                    && my > STAGE_TOP_OFFSET)
                    {
                        if(!mouseClickON && !mouseDragON)
                        {
                            if(!sidebarTempOFF)
                            {
                                setSidebarVisible(true,true);
                            }
                        }
                        else if(visibleMouseUpEventON === false) //클릭한 상태에서 들어올경우
                        {
                            visibleMouseUpEventON = true;
                            stage.addEventListener(MouseEvent.MOUSE_UP,sidebarONMouseUpEvent);
                        }
                    }
                }
            }
        }

        private function startWorkingTimer():void
        {
            clearInterval(workingTimer);

            workingTimer = setInterval(function():void //수동 gc실행
            {
                if(gcONCount === GC_TIME_OUT)
                {
                    gcONCount = 0;
                    // System.pauseForGCIfCollectionImminent(0.5);
                    System.gc();
                }
                else
                {
                    gcONCount++;
                }
     
                if(afkONCount >= 1)
                {
                    afkONCount++;
                    stopWorkingTimer();
                }
                else if(afkONCount < 1)
                {
                    afkONCount++;
                    APP_RUNNING_TIME += 1000;
                    updateWorkingTime();
                }
            },1000);
        }

        private function stopWorkingTimer():void
        {
            function workingTimerResumeEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,workingTimerResumeEvent);
                afkONCount = 0;
            }
            stage.addEventListener(MouseEvent.MOUSE_MOVE,workingTimerResumeEvent);
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
                {
                    lastZoomIndex = zoomMax;
                }
            }
            else
            {
                lastZoomIndex--;
                if(lastZoomIndex < 0)
                {
                    lastZoomIndex = 0;
                }
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
                updatePreviewCursorPos();
            }
        }

        //mosue move 이벤트 일정 시간 이내는 무시함
        private function closureLimitMouseMoveEventTime():Function
        {
            const rand:Function = Math.random;
            var limit:int = rand()*7+1;
            var lastTime:int = 0;
            var count:int = 0;
            var nowTime:int = 0;
            var subTime:int = 0;

            return function ():Boolean
            {
                nowTime = getTimer();
                subTime = nowTime-lastTime;

                if(subTime < limit)
                {
                    limit = rand()*7+1;
                    count = count-subTime;

                    if(count <= 0)
                    {
                        count = limit;
                    }
                    return true;
                }
                else
                {
                    lastTime = nowTime;
                    count = count-subTime;

                    if(count <= 0)
                    {
                        count = rand()*7+1;
                    }

                    return false;

                }
                return false;
            }
        }

        private function checkKeWhileShiftKey(keyCode:uint):Boolean
        {
            if(controlKeyON)
            {
                if(keyCode === gKey.s)
                {
                    saveFile(true);
                }
                else if(keyCode === gKey.o)
                {
                    loadFile(true);
                }
                else if(keyCode === gKey.v && clipImageON)
                {
                    if(!clipImageShortCutON)
                    {
                        clipImageShortCutON = true;
                        setTraceClipButton();
                        openTraceWindow();
                    }
                }
                return true;
            }
            return false;
        }

        private function checkKeWhileControlKey(keyCode:uint):void
        {
            if(keyCode === gKey.s) //ctrl+s
            {
                saveFile(false);
            }
            else if(keyCode === gKey.o) //ctrl+o
            {
                loadFile();
            }
            else if(keyCode === gKey.v)
            {
                if(clipImageON)
                {
                    if(!clipImageShortCutON)
                    {
                        clipImageShortCutON = true;
                        setClipButton();
                    }
                }
            }
        }

        private function checkKeyWhileLassoToolON(keyCode:uint):Boolean
        {
            switch(keyCode)
            {
                case gKey.space:
                {
                    nowKey = keyCode;
                    nowTool = TOOL_HAND;
                    return true;
                }
                break;

                case gKey.w:
                case gKey.i:
                {
                    nowKey = keyCode;
                    nowTool = TOOL_ZOOM;
                    return true;
                }
                break;

                case gKey.s:
                case gKey.k:
                {
                    nowKey = keyCode;
                    nowTool = TOOL_ROTATE;
                    return true;
                }
                break;

                case gKey.enter:
                    setLassoOKButton();
                break;

                case gKey.esc:
                    setLassoCancelButton();
                break;
            }
            return false;
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

        private function updatePreviewCursorPos():void
        {
            const gp:Point = canvas1Bitmap.globalToLocal(new Point(STAGE_LEFT_OFFSET,STAGE_TOP_OFFSET));
            const z:Number = zoomed;

            previewBox.updateCursor(gp.x*z
                                    ,gp.y*z
                                    ,stage.stageWidth-STAGE_LEFT_OFFSET-STAGE_RIGHT_OFFSET
                                    ,stage.stageHeight-STAGE_TOP_OFFSET-STAGE_BOTTOM_OFFSET
                                    ,CANVAS_WIDTH*z
                                    ,regPoint.rotation);
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

            mouseClickON = true;
            mouseDragON = true;

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

                updatePreviewCursorPos();
            }

            function consolBoxHandToolUpEvent(e:MouseEvent):void
            {
                setOptimizeCanvasMove(false);
                checkCanvasPanelPos();
                updatePreviewCursorPos();
                mouseClickON = false;
                mouseDragON = false
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,consolBoxHandToolMoveEvent);
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

                updatePreviewCursorPos();
            }
            setRegPoint(0,0);

            //클릭한 지점이 커서 바깥부분일때 강제로 캔버스 중심으로 옮겨줌
            if(!cursorClicked)
            {
                setCenter(mouseX,mouseY);
            }

            stage.addEventListener(MouseEvent.MOUSE_MOVE,consolBoxHandToolMoveEvent)
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
            if(nowTool === TOOL_LINE)
            {
                nowToolBackup = TOOL_LINE;
                selectLineTool();
                updatePenSizeCursor();
            }
            else if(nowTool !== TOOL_PEN)
            {
                if(nowTool === TOOL_FILL_PEN)
                {
                    selectFillPenTool();
                }
                else
                {
                    nowToolBackup = TOOL_PEN;
                    selectPenTool();
                    updatePenSizeCursor();
                }
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

        private function getReplayFileSize():String
        {
            var endStr:String = " MB";
            var size:Number = Math.round((repFile.size/1048576)*100)/100;
            if(size < 1.0)
            {
                size = Math.round(repFile.size/1048);
                endStr = " KB";
            }

            if(repFile.exists)
            {
                return "("+size+endStr+")";
            }
            else
            {
                return "(0 MB)";
            }
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
                setBackgroundColor(hexColor);
                rDataBuffer.push(["bgColor",hexColor]);
                addUndoData(3);
            }
        }


        private function checkLassoMenuPos():void
        {
            const _lassoMenu:lassoButtons = lassoMenu;
            const _lassoBox:Sprite = lassoBox;
            const zerop:Point = new Point(0,0);
            const g:Point = _lassoBox.localToGlobal(zerop);
            const floor:Function = Math.floor;
            const stw:Number = stage.stageWidth;
            const sth:Number = stage.stageHeight;
            var lassoW:Number = _lassoMenu.width;
            var lassoH:Number = _lassoMenu.height;

            if(lassoW > stw) lassoW = stw;
            if(lassoH > sth) lassoH = sth;

            _lassoMenu.x = floor(g.x-lassoW/2);
            _lassoMenu.y = floor(g.y+lassoH);

            checkBoxPosition(_lassoMenu);
        }

        private function traceMenuHintONEvent(e:MouseEvent):void
        {
            if(mouseDragON === true) return;
            const targetName:String = e.target.name;
            var str:String = "";
            switch(targetName)
            {
                case "traceCancelButton":
                    str = "Close";
                break;

                case "traceImageButton":
                    str = "Transfer to ref. layer";
                break;
                case "traceLoadButton":
                    str = "Paste image from file";
                break;

                case "traceClipButton":
                    str = "Paste image from clipboard";
                break;

                case "traceButtonWrapper":
                    str = "Adjust opacity";
                break;

                case "traceRotateButton":
                    str = "Rotate image";
                break;

                case "traceMoveButton":
                    str = "Move image";
                break;

                case "traceResizeButton":
                    str = "Resize image";
                break;

                case "traceCancelButton":
                    str = "Close";
                break;
                case "traceMirrorButton":
                    str = "Flip image";
                break;

                case "traceVisibleONButton":
                case "traceVisibleOFFButton":
                    str = "Memory training ON/OFF";
                break;

                case "traceDeleteButton":
                    str = "Erase reference image";
                break;


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
                case "lassoOK":
                    str = "OK";
                break;

                case "lassoCancel":
                    str = "Cancel";
                break;

                case "lassoCopy":
                    str = "Copy image";
                break;

                case "lassoMove":
                    str = "Move image";
                break;

                case "lassoRotate":
                    str = "Rotate image";
                break;

                case "lassoCZoom":
                    str = "Zoom canvas";
                break;

                case "lassoCRotate":
                    str = "Rotate Canvas"
                break;
                case "lassoCHand":
                    str = "Move canvas";
                break;

                case "lassoMirror":
                    str = "Flip image";
                break;

                case "lassoResize":
                    str = "Resize image";
                break;

                case "lasso1pxLeft":
                case "lasso1pxRight":
                case "lasso1pxUp":
                case "lasso1pxDown":
                    str = "Move image 1px"
                break;

                default:
                    lassoMenu.lassoInfo.text = "Lasso tool";
                return;
            }

            lassoMenu.lassoInfo.text = str;
        }

        private function toolBoxHintMoveEvent(e:MouseEvent):void
        {
            setToolTipString("");
        }

        private function toolBoxHintOFFEvent(e:MouseEvent):void
        {
            if(toolBox.toolInfo.visible)// && mouseX >= sideBar.w-5)
            {
                toolBox.hintOFF();
            }

            if(zoomToolHintON) zoomToolHintON = false;
            else toolTipBox.visible = false;

            stage.removeEventListener(MouseEvent.MOUSE_MOVE,toolBoxHintMoveEvent);
        }

        private function toolBoxHintONEvent(e:MouseEvent):void
        {
            if(mouseClickON || mouseDragON || lassoToolON || fillPenStarted) return;

            const targetName:String = e.target.name;
            const _tb2:toolButtons2 = toolBox2;
            const toolBox2Flag:Boolean = _tb2.visible;
            var str:String = "";
            // var twoLineHint:Boolean = false;
            
            switch(targetName)
            {
                case "toolBoxCloseButton":
                    str = "Close";
                break;

                case "toolPen":
                    str = "Pen (q, o key up) ";
                break;

                case "toolFillPen":
                    str = "Fill pen (q, o)";
                break;

                case "toolErase":
                    str = "Eraser (d, j)";
                break;

                case "toolLasso":
                    str = "Lasso (r, y)";
                break;

                case "toolSpuit":
                    str = "Eye dropper (c, m)";
                break;

                case "toolUndo":
                    str = "Undo (z, .)";
                break;

                case "toolRedo":
                    str = "Redo (x, ,)";
                break;

                case "toolMirror":
                    str = "Flip canvas(a, l)";
                break;

                case "toolLine":
                {
                    str = "Line (shift)";
                }
                break;

                case "toolMove":
                    str = "Move image (e, u)";
                break;

                case "toolZoom":
                    if(!toolBox.isZoomIconON()) str = "Zoom (w, i)";
                break;

                case "toolRotate":
                    str = "Rotate (s, k)";
                break;

                case "toolTrace":
                    str = "Reference layer (t)";
                break;

                default:
                    if(toolBox2Flag === true)
                    {
                        toolBox2.toolInfo.text = "Tools";
                    }
                    else
                    {
                        toolTipBox.visible = false;
                        stage.removeEventListener(MouseEvent.MOUSE_MOVE,toolBoxHintMoveEvent);
                    }
                return;
            }

            if(toolBox2Flag === true)
            {
                toolBox2.toolInfo.text = str;
                toolBox2.toolInfo.height = 22.7;
                toolBox2.toolBoxMoveButton.height = 25;
            }
            else
            {
                toolBox.hint(str,e.target as SimpleButton,isRightSidebar);
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

            if(mode === "draw")
            {
                buttonSetVisible("replay",false);
                buttonSetVisible("capture",false);
                _tb.changeHintYPos(_tb.BARSIZE);
                nowToolBackup = TOOL_PEN;
                nowTool = TOOL_PEN;
                selectPenTool();
                
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
            const _canvasTrace:Sprite = canvasTrace;
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
            const _canvasTrace:Sprite = canvasTrace;
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
            mouseDragON = true;

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
                tracePosInfo[2] = canvasTrace.rotation; //deg로 저장
                _rotateCursorBox.visible = false;
                canvasTraceBitmap.smoothing = true;
                stage.removeEventListener(MouseEvent.MOUSE_UP,traceRotateButtonUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,traceRotateButtonMoveEvent);
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
                setToolTipString(abs(_canvasTrace.rotation)+"°");
            }

            setToolTipString(abs(_canvasTrace.rotation)+"°");

            stage.addEventListener(MouseEvent.MOUSE_UP,traceRotateButtonUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,traceRotateButtonMoveEvent);
        }

        private function setTraceResizeButton():void
        {
            const _canvasTrace:Sprite = canvasTrace;
            const moveOffset:Number = 5;
            const cx:Number = mouseX;
            const cy:Number = mouseY;
            const abs:Function = Math.abs;
            const floor:Function = Math.floor;
            const bmpd:BitmapData = canvasTraceBitmapData;
            const w:Number = bmpd.width;
            const h:Number = bmpd.height;
            const mirrorFlag:Boolean = tracePosInfo[5];
            var smoothLastX:Number = cx;
            var smoothLastY:Number = cy;
            var moveFlag:int = 0;

            mouseDragON = true;
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
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,traceResizeButtonMove);
            }

            function traceResizeButtonMove(e:MouseEvent):void
            {
                const mx:Number = mouseX;
                const my:Number = mouseY;

                if(moveFlag != 0)
                {
                    if(moveFlag === 1)
                    {
                        const subX:Number = mx-smoothLastX;
                        
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
                        const subY:Number = smoothLastY-my;
                        if(subY !== 0)
                        {
                            const dy:Number = subY*0.02;
                            if(mirrorFlag) _canvasTrace.scaleX -= dy;
                            else  _canvasTrace.scaleX += dy;

                            _canvasTrace.scaleY += dy;
                            traceReizeMoveSum += subY;
                        }
                        
                    }
                    smoothLastX = mx;
                    smoothLastY = my;
                }
                else if(moveFlag === 0)
                {
                    if(abs(mx-cx) > moveOffset)
                    {
                        moveFlag = 1;
                        smoothLastX = mx;   
                    }
                    else if(abs(my-cy) > moveOffset)
                    {
                        moveFlag = 2;
                        smoothLastY = my;
                    }
                }

                const sc:Number = abs(_canvasTrace.scaleX);
                const ww:Number = floor(w*sc+0.5);
                const hh:Number = floor(h*sc+0.5);
                
                setToolTipString(ww+ " x "+ hh +" ["+sc.toFixed(2)+"]");
                toolTipBox.visible = true;
            }

            stage.addEventListener(MouseEvent.MOUSE_UP,traceResizeButtonUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,traceResizeButtonMove);
        }

        private function setTraceMoveButton():void
        {
            const _canvasTraceBitmap:Bitmap = canvasTraceBitmap;
            const cx:Number = mouseX;
            const cy:Number = mouseY;
            const oldX:Number = _canvasTraceBitmap.x;
            const oldY:Number = _canvasTraceBitmap.y;
            const rotation:Number = regPoint.rotation+canvasTrace.rotation;
            const scX:Number = tracePosInfo[3];
            const scY:Number = tracePosInfo[4];

            mouseDragON = true;
            traceMenuBox.visible = false;
            canvasTraceBitmap.smoothing = false;

            function traceMoveButtonUpEvent(e:MouseEvent):void
            {
                saveOneTime = false;
                mouseDragON = false;
                traceMenuBox.visible = true;
                tracePosInfo[0] = _canvasTraceBitmap.x;
                tracePosInfo[1] = _canvasTraceBitmap.y;
                canvasTraceBitmap.smoothing = true;
                stage.removeEventListener(MouseEvent.MOUSE_UP,traceMoveButtonUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,traceMoveButtonMoveEvent);
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
            stage.addEventListener(MouseEvent.MOUSE_MOVE,traceMoveButtonMoveEvent);
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
                    canvasTrace.visible = false;
                    canvasTrace.alpha = 0;
                }
                else
                {
                    if(canvasTrace.visible === false)
                    {
                        canvasTrace.visible = true;
                    }
                    canvasTrace.alpha = alpha;
                }
                _traceMenuBox.traceInfo.text = "Opacity "+floor(alpha*100+0.5)+"%"
            }
            _traceMenuBox.traceInfo.text = "Opacity "+floor(CANVAS_TRACE_ALPHA*100+0.5)+"%"

            setTraceOpaValue();

            stage.addEventListener(MouseEvent.MOUSE_UP,traceOpaButtonUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,traceOpaButtonMoveEvent);
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

            setTraceImageInfo(false);
        }
        
        private function setTraceImageInfo(customPos:Boolean,x:Number=0,y:Number=0,rotation:Number=0,scaleX:Number=1,scaleY:Number=1,mirror:Boolean=false):void
        {
            const _canvasTrace:Sprite = canvasTrace;
            const _canvasTraceBitmap:Bitmap = canvasTraceBitmap;

            _canvasTrace.x = CANVAS_WIDTH/2;
            _canvasTrace.y = CANVAS_HEIGHT/2;
            if(customPos === true)
            {
                _canvasTraceBitmap.x = x;
                _canvasTraceBitmap.y = y;
                _canvasTrace.scaleX = scaleX;
                _canvasTrace.scaleY = scaleY;
                _canvasTrace.rotation = rotation;
                tracePosInfo = [x,y,rotation,scaleX,scaleY,mirror];
            }
            else //커스텀이 아니고 리셋 할때
            {
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
        }

        private function pasteTraceImage(bmpd:IBitmapDrawable=null,w:Number=1,h:Number=1):void
        {
            if(!bmpd)
            {
                w = CANVAS_WIDTH;
                h = CANVAS_HEIGHT
            }

            const _canvasTraceBitmap:Bitmap = canvasTraceBitmap;
        
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
                canvasTraceBitmapData = tmpBMPD.clone();
                _canvasTraceBitmap.bitmapData = canvasTraceBitmapData;

                tmpBMPD.dispose();
                tmpBMPD = null;
            }
            else //캔버스 자체 이미지를 붙여넣을때
            {
                rDataBuffer = [["clear"]];
                canvasTraceBitmapData = canvas1BitmapData.clone();
                _canvasTraceBitmap.bitmapData = canvasTraceBitmapData;
                canvas1BitmapData = new BitmapData(w,h,true,0); //캔버스를 지워줌
                canvas1Bitmap.bitmapData = canvas1BitmapData;
                addUndoData(4);
            }
            setTraceImageInfo(false);

            if(bmpd) // 이미지 붙여넣을때 이미지가 캔버스사이즈보다 크면 자동 리사이즈함
            {
                const gw:Number = CANVAS_WIDTH;
                const gh:Number = CANVAS_HEIGHT;
                const widthFlag:Boolean = (w >= h) ? true : false;
                var autoScale:Number = 0;

                if(w > gw && widthFlag === true)
                {
                    autoScale = gw/w;
                }
                else if (h > gh && widthFlag === false)
                {
                    autoScale = gh/h;
                }

                if(autoScale > 0)
                {
                    const _canvasTrace:Sprite = canvasTrace;
                    _canvasTrace.scaleX = autoScale;
                    _canvasTrace.scaleY = autoScale;
                    tracePosInfo[3] = autoScale;
                    tracePosInfo[4] = autoScale;
                    _canvasTraceBitmap.smoothing = true;
                }
            }

            updateTraceOpaButtonPosByAlpha(0.5);

            CANVAS_TRACE_ALPHA = 0.5;
            canvasTrace.visible = true;
            canvasTrace.alpha = 0.5;

            _canvasTraceBitmap.smoothing = true;
            saveOneTime = false;
        }

        private function setBlurCanvas2DrawBySize(size:Number,replayMode:Boolean):void
        {
            var blurSize:Number = size/2;
            
            if(blurSize <= 2)
            {
                blurSize = 2;
            }
            if(blurSize > 30)
            {
                blurSize = 30;
            }

            const blurf:BlurFilter = new BlurFilter(blurSize,blurSize,3);

            if(replayMode)
            {
                rcanvas2Draw.filters = [blurf];
            }
            else
            {
                canvas2Draw.filters = [blurf];
            }
        }

        private function setAirBrushCheckBox(flag:Boolean,penFlag:Boolean):void
        {
            const _controlBox:controlMenu = controlBox;
            _controlBox["airBrushOFFButton"].visible = flag;
            _controlBox["airBrushONButton"].visible = !flag;

            if(flag)
            {
                var size:uint;
                if(penFlag)
                {
                    size = penSize;
                }
                else
                {
                    size = eraseSize;
                }

                setBlurCanvas2DrawBySize(size,false);
                _controlBox.blurShapeSetON();
            }
            else
            {
                canvas2Draw.filters = [];
                _controlBox.blurShapeSetOFF();
            }
        }

        private function setAirBrush(flag:Boolean):void
        {
            const penFlag:Boolean = isPenTool();

            if(penFlag)
            {
                airBrushON = flag;
            }
            else
            {
                eraseAirBrushON = flag;
            }

            setAirBrushCheckBox(flag,penFlag);
        }

        public function resetTransBG(replayMode:Boolean):void
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
        
        public function setTransBG(replayMode:Boolean):void
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

        public function setSubLayer(flag:Boolean):void
        {
            subLayerON = flag;
            const _controlBox:controlMenu = controlBox;
            _controlBox["subLayerOFFButton"].visible = flag;
            _controlBox["subLayerONButton"].visible = !flag;

            if(subLayerON)
            {
                canvasPanel.setChildIndex(canvas1,2);
            }
            else
            {
                canvasPanel.setChildIndex(canvas2,2);
            }
        }   

        public function setPixelSnap(flag:Boolean):void
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
            {
                uiColorIndex = 0;
            }
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
            const base:uint = _arr[index][0];
            const op:uint = _arr[index][1];
            const bg:uint = _arr[index][2];
            const border:uint = _arr[index][3];

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
            fillPenBox.changeBGColor(_arr2);
            checkClipBoardImage();
            appInfoBox.canvasInfo.textColor = op;
            pickerBox.setRGBInfoColor(getInvertColor(pickerBox.rgbInfoBGColor,1.0
                                                    ,(uiColorIndex >= 2) ? base:op
                                                    ,(uiColorIndex >= 2) ? op:base));
            if(pickerMode !== 1)
            {
                changePickerModeToNormal();
            }
            pickerBox.setPickerMode(pickerMode);
            updateScrollBar(scrollBarHeight);
        }

        private function windowStageElementSetting():void
        {
            updateWindowTitle();
            setWindowTitleStar();
            stage.vsyncEnabled = true;
            stage.scaleMode = StageScaleMode.NO_SCALE; //창크기 상관없이 스테이지 크기 고정
            stage.align = StageAlign.TOP_LEFT;
            stage.quality = StageQuality.BEST;
            stage.tabChildren = false;

            NativeApplication.nativeApplication.autoExit = true;

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
            toolBox2.addEventListener(MouseEvent.MOUSE_OVER,toolBoxHintONEvent);
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

            fillPenBox.addEventListener(MouseEvent.MOUSE_OVER,fillPenBoxHintONEvent);
            fillPenBox.addEventListener(MouseEvent.MOUSE_OUT,fillPenBoxHintOFFEvent);

            stage.addEventListener(Event.MOUSE_LEAVE,sideBarVisibleMouseLeaveEvent);
            topBar.addEventListener(MouseEvent.CLICK,topBarClickEvent);
        }

        private function fillPenBoxHintOFFEvent(e:MouseEvent):void
        {
            toolTipBox.visible = false;
        }

        private function fillPenBoxHintONEvent(e:MouseEvent):void
        {
            if(mouseDragON || mouseClickON) return;

            const target:DisplayObject = e.target as DisplayObject;
            const targetName:String = target.name;
            var str:String = "";

            switch(targetName)
            {      
                case "fillPenOK":
                {
                    str = "OK (q, o, enter, right-click)";
                }
                break;

                case "fillPenCancel":
                {
                    str = "cancel (esc)";
                }
                break;

                case "fillPenUndo":
                {
                    str = "undo (w, z / i, .)";
                }
                break;

                default:
                    toolTipBox.visible = false;
                return;
            }

            setToolTipString(str);
            toolTipBox.visible = true;
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
                if(controlBox.hitTestPoint(mouseX,mouseY) === false)
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
                case "shapeCircle":
                {
                    str = "Circle";
                }
                break;
                case "shapeRect":
                {
                    str = "Square";
                }
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
                    str = penSizeHint(targetName)+" (f, v / h, n)";
                }
                break;

                case "alphaButton0":
                case "alphaButton1":
                case "alphaButton2":
                case "alphaButton3":
                {   
                    str = getAlphaHint(targetName)+" (g, b)";
                }
                break;

                case "pixelSnapButtonWrapper":
                case "pixelSnapOFFButton":
                case "pixelSnapONButton":
                case "pixelSnapText":
                {   
                    str = "Sharp line (3, 9)";
                }
                break;

                case "airBrushWrapper":
                case "airBrushOFFButton":
                case "airBrushONButton":
                case "airBrushText":
                {   
                    str = "Air brush (4, 0)";
                }
                break;

                case "subLayerButtonWrapper":
                case "subLayerOFFButton":
                case "subLayerONButton":
                case "subLayerText":
                {   
                    str = "Sub layer (5, -)";
                }
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

        private function isPenTool():Boolean
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

        private function updateReplayBarPos(stw:Number,sth:Number):void
        {
            const _replayTimeBox:replayTimeBar = replayTimeBox;
            const replayTotalBar:Sprite = _replayTimeBox["replayTotalBar"];
            const maxWidth:Number = stw-_replayTimeBox["replayTotalBar"].x-5;
            const totalFrame:Number = TOTAL_FRAME;

            _replayTimeBox["replayBGBar"].width = stw+20;
            replayTotalBar.width = maxWidth;
            _replayTimeBox["frameInfo"].x = replayTotalBar.x;
            _replayTimeBox["frameInfo"].width = maxWidth;
            _replayTimeBox["replayNowBar"].width = (replayTotalBar.width)*(rFrameSum/totalFrame);
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

            function alphaGO(alp:Number,size:uint):void
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

            if(isEraseTool())
            {
                alphaGO(eraseAlpha,eraseSize);

            }
            else if(isPenTool())
            {
                alphaGO(penAlpha,penSize);
            }

            function printConsolAlphaEvent(e:KeyboardEvent):void
            {
                penSizeOpaKeyUpEventON = false;
                stage.removeEventListener(KeyboardEvent.KEY_UP,printConsolAlphaEvent);
            }
            if(penSizeOpaKeyUpEventON === false)
            {
                penSizeOpaKeyUpEventON = true;
                stage.addEventListener(KeyboardEvent.KEY_UP,printConsolAlphaEvent);
            }
        }

        private function shortCutPenSize(flag:Boolean):void
        {
            var index:int = 0;
            const len:uint = sizeArr.length-1;

            function sizeGO(index:uint,alpha:Number):void
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

            if(isPenTool())
            {
                sizeGO(penSizeIndex,penAlpha);
            }
            else if(isEraseTool())
            {
                sizeGO(eraseSizeIndex,eraseAlpha);
            }

            function printConsolSizeEvent(e:KeyboardEvent):void
            {   
                if(isPenTool() && airBrushON)
                {
                    setBlurCanvas2DrawBySize(penSize,false);
                }

                if(isEraseTool() && eraseAirBrushON)
                {
                    setBlurCanvas2DrawBySize(eraseSize,false);
                }
                penSizeOpaKeyUpEventON = false;
                stage.removeEventListener(KeyboardEvent.KEY_UP,printConsolSizeEvent);
            }

            if(penSizeOpaKeyUpEventON === false)
            {
                penSizeOpaKeyUpEventON = true
                stage.addEventListener(KeyboardEvent.KEY_UP,printConsolSizeEvent);
            }
        }

        private function keyUpBufferEvent(e:KeyboardEvent):void
        {
            const keyCode:int = e.keyCode;

            afkONCount = 0;

            switch(keyCode)
            {
                case gKey.shift:
                    shiftKeyON = false;
                break;

                case gKey.ctrl:
                case 25:
                case 17:
                    controlKeyON = false;
                break;

                case gKey.tab:
                case gKey.backslash:
                    setSidebarVisible(!isSidebarVisible,false);
                break;
            }

            const index:int = keyBufferArr.lastIndexOf(keyCode);

            if(index > -1) // 이거 해줘야 하는지 잘 모르겠음 남겨둠 if(keycode === nowKey)
            {
                keyBufferArr.splice(index,1);
            }
        }

        private function keyDownBufferEvent(e:KeyboardEvent):void
        {
            const keyCode:int = e.keyCode;

            if(keyCode === gKey.shift && !shiftKeyON)
            {
                shiftKeyON = true;
            }

            if((keyCode === gKey.ctrl || keyCode === 25 || keyCode === 17) && !controlKeyON)
            {
                controlKeyON = true;
            }

            if(shiftKeyON && controlKeyON)
            {
                if(keyCode === gKey.s)
                {
                    saveFile(true);
                }
                else if(keyCode === gKey.o)
                {
                    loadFile();
                }
            }

            if(lassoToolON || captureModeON || e.ctrlKey || e.altKey || keyCode === 91) return;
        
            if(keyBufferArr.lastIndexOf(keyCode) === -1 && nowKey !== keyCode)
            {
                keyBufferArr.push(keyCode);
            }

            if(!mouseClickON && !mouseDragON)
            {
                switch(keyCode)
                {
                    case gKey.f:
                    case gKey.h:
                        shortCutPenSize(true);
                    break;

                    case gKey.v:
                    case gKey.n:
                        shortCutPenSize(false);
                    break;

                    case gKey.g:
                        shortCutPenAlpha(true);
                    break;
                    case gKey.b:
                        shortCutPenAlpha(false);
                    break;
                }
            }
        }

        private function setAlphaButton(targetName:String):void
        {
            const numberStr:String = targetName.substr(11,targetName.length);
            const alpIndex:int = parseInt(numberStr);
            const alpha:Number = alphaArr[alpIndex];
            const alphaStr:String =  alpha*100+"%";
            setPenAlpha(alpha);
        }

        private function setSizeButton2(targetName:String):void
        {
            const numberOnly:String = targetName.substr(11,targetName.length);
            const index:uint = parseInt(numberOnly);

            function penSizePrevOFFEvent(e:MouseEvent):void
            {
                if(controlBox.penSizeTransButtonBox.hitTestPoint(mouseX,mouseY) === false)
                {
                    clearTimeout(penSizePrevOFFTimer);
                    penSizePrev.visible = false;
                    stage.removeEventListener(MouseEvent.MOUSE_DOWN,penSizePrevOFFEvent);
                }
            }

            setPenSize(index);
            updatePenSizeCursor();
            penSizePrev.visible = true;

            if(isPenTool() && airBrushON)
            {
                setBlurCanvas2DrawBySize(penSize,false);
            }

            if(isEraseTool() && eraseAirBrushON)
            {
                setBlurCanvas2DrawBySize(eraseSize,false);
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
            const airBrushFlag:Boolean = isPenTool() && airBrushON;
            const eraseAirBrushFlag:Boolean = isEraseTool() && eraseAirBrushON;
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
                var mx:Number = sliderSet.mouseX;

                if(mx < leftOffset) mx = leftOffset;
                else if(mx > rightOffset) mx = rightOffset;

                //버튼을 기준으로 중간값으로
                const value:Number = Math.floor((mx-leftOffset)/div);
                const xpos:Number = value*div+leftOffset;

                if(button.x === xpos) return;

                button.x = xpos;
                penSmoothButtonX = xpos;

                if(value === 0)
                {
                    penSmoothValue = 0;
                }
                else
                {
                    penSmoothValue = maxValue-(value*stepValue);
                }

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
            stage.addEventListener(MouseEvent.MOUSE_MOVE,penSmoothButtonMoveEvent);
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
                alpha = rLineStyleSave[0];
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

            capturePreviewCursor.x = 0;
            capturePreviewCursor.y = 0;
            rcapturePreviewCursor.x = 0;
            rcapturePreviewCursor.y = 0;
            
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,captureKeydownEvent);
            stage.removeEventListener(KeyboardEvent.KEY_UP,captureKeyUpEvent);
            if(replayModeON)
            {
                setCaptureModeOFF(true,rregPoint,rcanvasPanel,rcapturePreviewRect);
            }
            else
            {
                setCaptureModeOFF(false,regPoint,canvasPanel,capturePreviewRect);
            }

        }

        private function setCaptureOFFButton(shortcut:Boolean):void
        {
            if(shortcut)
            {
                captureModeShortCutOFF = true;
            }
            captureOFF();
        }

        private function setFullCaptrueButton():void
        {
            if(replayModeON)
            {
                saveCaptureImage(0,0,rcanvas1BitmapData.width,rcanvas1BitmapData.height);
            }
            else
            {
                saveCaptureImage(0,0,canvas1BitmapData.width,canvas1BitmapData.height);
            }
        }

        private function setCaptureTransButton():void
        {
            captureTransBGON = !captureTransBGON;

            if(captureTransBGON)
            {
                setTransBG(replayModeON);
            }
            else
            {
                resetTransBG(replayModeON);
            }
        }

        private function setCaptureRotateButton():void
        {
            captureRotated++;
            if(captureRotated >= 4)
            {
                captureRotated = 0;
            }

            if(toolTipBox.visible === true)
            {
                changeToolTipString(drawCaptureArea.getRotatedRectSizeString()+" (Click canvas to save again)")

            }

            canvasFitWindow(true);
        }

        private function setCaptureCursorON(replayMode:Boolean,zoomed:Number):void
        {
            const xCapture:Shape = (replayMode) ? rcapturePreviewCursor : capturePreviewCursor;
            const g:Graphics = xCapture.graphics;
            const cursorSize:Number = 100*zoomed;

            xcapturePreviewCursor = xCapture;

            g.clear();
            g.lineStyle(Math.ceil(2*zoomed),0x0099FF,1.0,true,"normal","none");
            g.moveTo(-cursorSize,0);
            g.lineTo(cursorSize,0);
            g.moveTo(0,-cursorSize);
            g.lineTo(0,cursorSize);

            xCapture.cacheAsBitmap = true;
            xCapture.visible = true;
        }

        //rotate hand zoom에서 쓰임
        private function setResizeButtonVisible(flag:Boolean):void
        {
            if(flag)
            {
                updateResizeButtonPos();
            }
            resizeButtonR.visible = flag;
            resizeButtonL.visible = flag;
            resizeButtonD.visible = flag;
            resizeButtonU.visible = flag;
        }

        private function updateColorHistoryBGEvent(e:MouseEvent):void
        {
            const targetName:String =  e.target.name;
            if(targetName
            && (targetName.indexOf("canvas") !== -1 || targetName === "stageBG" || targetName === "canvasGrid"))
            {
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryBGEvent);
                colorHistoryUpdateBGReady = false;
                changePickerModeToNormal();
            }
        }

        private function updateColorHistoryEvent(e:MouseEvent):void
        {
            const targetName:String =  e.target.name;

            if((isPenTool() || nowTool === TOOL_FILL_PEN)
            && targetName
            && (targetName.indexOf("canvas") !== -1 || targetName === "stageBG" || targetName === "canvasGrid"))
            {
                colorHistoryUpdateReady = false;
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryEvent);

                var chUpdateFlag:Boolean = false; //컬러 히스토리 업데이트 할지 결정해주는 플래그
                const xColor:uint = penColor;

                if(changedColor !== xColor)
                {
                    chUpdateFlag = true;
                    changedColor = xColor;
                    addColorToHistory(xColor);
                }

                if(pickerMode)
                {
                    updatePickerCurrentColor(xColor);
                }
                checkColorHistoryLastColor(xColor,chUpdateFlag);
            }
        }

        private function removeReplayMainEvent():void
        {
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDownReplayModeEvent);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownReplayModeEvent);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownReplayModeEvent);
            stage.removeEventListener(KeyboardEvent.KEY_UP, keyUpReplayModeEvent);
        }

        private function addReplayMainEvent():void
        {
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDownReplayModeEvent);
            stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownReplayModeEvent);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownReplayModeEvent);
            stage.addEventListener(KeyboardEvent.KEY_UP,keyUpReplayModeEvent);
        }

        private function addMainEvent():void
        {
            addKeyEvent();
            stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownEvent,false,-1);
            //mouse up은 할필요가 없음 mouse down에서 추가해주기 때문에
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownEvent,false,-1);
        }

        private function addKeyEvent():void
        {
            stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownBufferEvent,false,3);
            stage.addEventListener(KeyboardEvent.KEY_UP,keyUpBufferEvent,false,3);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownEvent,false,-1);
            stage.addEventListener(KeyboardEvent.KEY_UP,keyUpEvent,false,-1);
        }

        private function removeKeyEvent():void
        {
            nowKey = 0;
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownEvent);
            stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpEvent);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownBufferEvent);
            stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpBufferEvent);
        }

        private function removeMainEvent():void
        {
            //about 링크 클릭해줄때 강제적으로 mouse up이벤트가 작동
            mouseClickON = false;
            mouseDragON = false;

            stage.removeEventListener(MouseEvent.MOUSE_UP,mouseUpEvent);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownEvent);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,rightMouseDownEvent);
            removeKeyEvent();
        }

        private function topBarClickEvent(e:MouseEvent):void
        {
            if(lassoToolON || fillPenStarted || (e.target.alpha && e.target.alpha < 1.0)) return;

            switch (e.target.name)
            {
                case "clearButton":
                {
                    if(toolBox2ON || nowKey !== 0) return;
                    setClearData();
                }
                return;

                case "replayModeButton": //켬1
                {
                    if(toolBox2ON || nowKey !== 0) return;
                    setReplayUI(true);

                    mouseClickON = false; //리플레이 버튼 누르고 나서 단축키가 안먹는 현상이 이거임
                }
                return;

                case "drawModeButton": //끔1
                {
                    setReplayUI(false);
                }
                break;

                case "superUndoButton":
                {
                    cutFrameData(0,false);
                }
                break;

                case "reRecordingButton":
                {
                    cutFrameData(1,false);
                }
                break;
                case "cutPrevDataButton":
                {
                    cutFrameData(2,false);
                }
                break;

            }
        }

        private function setLassoCopyButton():void
        {
            if(lassoCopyON) return;
            
            lassoCopyON = true;
            lassoMenu["lassoCopy"].alpha = BUTTON_OFF_ALPHA;
            setLassoCancelButton(true);
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
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, lassoRotateButtonMoveEvent);
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

            lassoMenuClickPos[0] = _lassoMenu.mouseX;
            lassoMenuClickPos[1] = _lassoMenu.mouseY;

            _lassoMenu.visible = false;
            stage.addEventListener(MouseEvent.MOUSE_MOVE, lassoRotateButtonMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP, lassoRotateButtonUpEvent);
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
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,lassoResizeButtonMoveEvent);
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

            lassoMenuClickPos[0] = _lassoMenu.mouseX;
            lassoMenuClickPos[1] = _lassoMenu.mouseY;

            _lassoMenu.visible = false;
            stage.addEventListener(MouseEvent.MOUSE_UP,lassoResizeButtonUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,lassoResizeButtonMoveEvent);
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
            var oldX:Number = mouseX;
            var oldY:Number = mouseY;
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
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,lassoMoveButtonMoveEvent);
            }

            function lassoMoveButtonMoveEvent(e:MouseEvent):void
            {
                const round:Function = Math.round;
                const moveX:Number = mouseX-oldX;
                const moveY:Number = mouseY-oldY;
                const rotatedMove:Point = rotatePoint(moveX,moveY,regPoint.rotation);
                const z:Number = zoomed;

                sx += rotatedMove.x/z;
                sy += rotatedMove.y/z;

                lassoBox.x = round(sx);
                lassoBox.y = round(sy);

                oldX = mouseX;
                oldY = mouseY;
            }

            lassoMenuClickPos[0] = _lassoMenu.mouseX;
            lassoMenuClickPos[1] = _lassoMenu.mouseY;

            _lassoMenu.visible = false;
            stage.addEventListener(MouseEvent.MOUSE_UP,lassoMoveButtonUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,lassoMoveButtonMoveEvent);
        }

        private function setPenSize(index:uint):void
        {
            const size:uint = sizeArr[index];
            const isErase:Boolean = isEraseTool();
            var blurf:BlurFilter;

            if(nowTool === TOOL_FILL_PEN)
            {
                nowToolBackup = 1;
                selectPenTool();
            }

            if(isPenTool()) 
            {
                penSize = size;
                penSizeIndex = index;
            }
            else if(isErase) 
            {
                eraseSize = size;
                eraseSizeIndex = index;
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
            setHSVCursorPosByColor(color);
            updatePickerCurrentColor(color);
            pickerBox.setPickerMode(1);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryBGEvent);
        }

        private function setShapeButton(shapeFlag:Boolean):void
        {
            penListShapeFlag = shapeFlag;

            if(shapeFlag === true)
            {
                penSizeCursor.rotation = regPoint.rotation;
            }

            if(isPenTool())
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
                const barw:Number = _hueBarWidth;

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
                    setBackgroundColor(pickedColor);
                    updateColorHistoryList();
                    rDataBuffer.push(["bgColor",pickedColor]);
                    addUndoData(3);
                }

                mouseDragON = false;
                penCursorOFFFlag = false;

                forceSetMainDrawTool();
                //timer로 동작하는 경우 마지막 커서위치에 안가있을수도 있기 때문에 up에서도 해줌
                stage.removeEventListener(MouseEvent.MOUSE_UP,hueColorButtonUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,hueColorButtonMoveEvent);
            }
            hueMoveStart(hueColorBox.mouseX);
            stage.addEventListener(MouseEvent.MOUSE_UP,hueColorButtonUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,hueColorButtonMoveEvent);
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
                    setBackgroundColor(pickedColor);
                    updateColorHistoryList();
                    rDataBuffer.push(["bgColor",pickedColor]);
                    addUndoData(3);
                }

                mouseDragON = false;
                penCursorOFFFlag = false;

                forceSetMainDrawTool();

                stage.removeEventListener(MouseEvent.MOUSE_UP,svColorButtonUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,svColorButtonMoveEvent);
            }

            setSVBoxMouseMoveEvent(svColorBox.mouseX,svColorBox.mouseY);

            stage.addEventListener(MouseEvent.MOUSE_UP,svColorButtonUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,svColorButtonMoveEvent);
        }

        //단축키를  after tool mouse up에서 이전툴을 복구해줌
        private function setPrevTool():void
        {
            const prevTool:int = nowToolBackup;

            if(prevTool === nowTool)
            {
                nowToolBackup = -1;
                return;
            }
            else if(nowToolBackup === -1)
            {
                selectPenTool();
                return;
            }

            switch (prevTool)
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

                case TOOL_SPUIT:
                    setSpuitTool();
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

            nowTool = prevTool;
            nowToolBackup = -1;
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

            if(dotIndex === -1) return null;

            const head:String = str.slice(0,dotIndex);
            var tail:String = str.slice(dotIndex+1,str.length);
            var tailLen:uint = tail.length;

            if(tailLen > 2)
            {
                tail = tail.slice(0,2);
                tailLen = tail.length;
            }

            const ver1:Number = parseInt(head);
            const ver2:Number = parseInt(tail)/Math.pow(10,tailLen);

            return [ver1,ver2];
        }

        private function checkVersion():void
        {
            if(isCheckingUpdate)
            {
                return;
            }

            isCheckingUpdate = true;
            clearTimeout(updateRryTimer);

            var url:URLRequest = new URLRequest("https://raw.githubusercontent.com/guljam/fofopaint-source/main/fofoversion");
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
                    //getVersion이 NaN일수도 있음
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
                                topBar.aboutButton.visible = false;
                                topBar.updateButton.visible = true;
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
                                else
                                {
                                    setDownloadText(2);
                                }
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
                            {
                                fileLoader.load(url); //다운로드를 시작함
                            }
                            else
                            {
                                setDownloadText(2);
                            }
                        }
                        else
                        {
                            //최신 버전이면 이미 다운로드한 파일 있는지 체크하고 제거
                            if(UPDATE_FILE.exists)
                            {
                                UPDATE_FILE.deleteFile();
                            }
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
            if(!replayModeON && !captureModeON) addMainEvent();

            stage.removeEventListener(MouseEvent.MOUSE_DOWN,aboutOFFMouseDownEvent);
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
                {
                    checkButtonUp(targetName);
                }
                break;
                
                case "aboutButton":
                {
                    closeAboutPanel();
                }
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

        private function openAboutPanel(flag:uint=0):void
        {
            const _aboutPanel:aboutBox = aboutPanel;

            setTopChildIndex(_aboutPanel);
            aboutPanelON = true;
            clickBlockFlag = true;

            if(!replayModeON)
            {
                removeMainEvent();
            }

            aboutPanel.appResetButton.visible = true;
            if(flag === 0)
            {
                checkVersion();
                stage.addEventListener(MouseEvent.MOUSE_DOWN,aboutOFFMouseDownEvent);
            }
            else if(flag === 1) //처음 시작 할때
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

        private function clearData(reRecordFlag:Boolean = false):void
        {
            if(reRecordFlag)
            {
                const dd:Array = rLineStyleSave;
                const newColorTransform:ColorTransform = new ColorTransform(1,1,1,dd[0]);
                rcanvas2BitmapData.draw(rcanvas2Draw);
                rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                rcanvas1BitmapData.draw(rcanvas2Bitmap,null,newColorTransform,dd[1]);

                //캔버스 2번 지워줘야함
                rcanvas2Draw.graphics.clear();
                rcanvas2BitmapData.dispose();

                rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                canvas1Bitmap.bitmapData = rcanvas1BitmapData.clone();

                setPanelSize(canvas1Bitmap.width,canvas1Bitmap.height);
                setBackgroundColor(RCANVAS_BG_COLOR);

                clearButtonClicked = false;
            }
            else
            {
                clearCanvas();
                clearCanvasReplayMode();
                clearButtonClicked = true;
            }
            rTinyCursorPos = [];
            rBGColorSave = CANVAS_BG_COLOR;
            updateFirstImage(canvas1BitmapData,CANVAS_BG_COLOR);
            saveContinue = false;
            mirrorON = false;
            mirrorPushON = false;
            rDataReadFlag = false;
            rSpeed = 1;
            rFileTotalFrame = 0;
            TOTAL_FRAME = 0;
            rSkipImageInit = 0;
            topBar.replaySpeedMoveButton.x = topBar["replaySpeedBar"].x;

            resetUndo();
            resetReplayDataFile(true);
            resetReplayTime();
            addUndoData();

            const randomStrCount:int = 6+Math.random()*10;
            const fileName:String = getRandomString(randomStrCount)+".png";
            const name:String = saveFileName;
            const path:String = saveFilePath;
            const newName:String = name.substr(0,name.lastIndexOf(name))+fileName;
            const newPath:String = path.substr(0,path.lastIndexOf(name))+fileName;

            saveFileName = newName;
            saveFilePath = newPath;

            updateWindowTitle();
            setWindowTitleStar();
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
                        {
                            setUIColorButton();
                        }
                        break;

                        case "gridButton":
                        {
                            setGridButton();
                        }
                        break;

                        case "aboutButton":
                        {
                            openAboutPanel();
                        }
                        case "replayZoomInButton":
                        {
                            setZoomInButton(true,true);
                        }
                        break;

                        case "replayZoomOutButton":
                        {
                            setZoomInButton(false,true);
                        }
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
                        {
                            startReplay();
                        }
                        break;

                        case "pauseButton":
                        {
                            stopReplay();
                        }
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
            stage.addEventListener(MouseEvent.MOUSE_UP, buttonUpEvent);
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
            updateResizeButtonPos();
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
            cutFrameClickedButton = -1;
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
            if(rSkipImageFolder.exists) rSkipImageFolder.deleteDirectory(true);
            rSkipImageFolder.createDirectory();

            updateFirstImage(rcanvas1BitmapData,RCANVAS_BG_COLOR);

            if(repFileTemp.exists)//이미 있으면 지워주고
            {
                repFileTemp.deleteFile();
            }
            const sourceFS:FileStream = new FileStream();

            if(rDataReadFlag === true)
            {
                //repfile 초기화
                sourceFS.open(repFile,FileMode.WRITE);
                sourceFS.close();

                forceUndoAndDeleteFrontData(rIndex+1);
                TOTAL_FRAME = getTotalFrame();
                resetReplayTime();
                replayTimeBox["frameInfo"].text = "Replay data is ready "+getReplayFileSize();
                replayNowBar.width = 0;
            }
            else if(rDataReadFlag === false)
            {
                //make skipimage에서 변경해주기 때문에
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
                    if(sourceFS.bytesAvailable === 0)
                    {
                        break;
                    }
                    d = sourceFS.readObject() as Array;

                    targetFS.writeObject(d);
                }
                sourceFS.close();
                targetFS.close();

                repFileTemp.copyTo(repFile,true);
                repFileTemp.deleteFile();

                makeSkipImage();
                rCursor.visible = false;
                replayNowBar.width = 0;
                saveOneTime = false;
            }
            checkReplaySpeedState();
        }

        private function superUndo():void
        {
            if(rDataReadFlag === true)
            {
                //위에서 setSkipOneFrame을 해줘서 rindex가 증가되었기 때문에
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
                const _rframeSum:Number = rFrameSum;
                const list:Array = rSkipImageFolder.getDirectoryListing();
                const index:Number = getSkipImageIndex(_rframeSum);
                //index번 이후 파일 삭제
                for (var i:uint = 0,len:uint=list.length; i < len; i++)
                {
                    const fileNumber:Number = parseInt(list[i].name);
                    if(fileNumber > index) list[i].deleteFile();
                }
                //framedata도 인덱스 이후꺼 날려줌
                rSkipImageFrameData.splice(index+1);
                rFileTotalFrame = _rframeSum;
                TOTAL_FRAME = _rframeSum;

                canvas1BitmapData = rcanvas1BitmapData.clone();
                canvas1Bitmap.bitmapData = canvas1BitmapData;
                setPanelSize(canvas1Bitmap.width,canvas1Bitmap.height,0,0,false);
                resetReplayTime();
                resetUndo();
                setBackgroundColor(RCANVAS_BG_COLOR);
                addUndoData();
                setCanvasSameReplayCanvas();

                replayNowBar.width = bw;
            }
            setReplayUI(false);
        }

        private function cutFrameData(flag:int,shortcutKey:Boolean):void
        {
            if(flag === 0) cutFrameActiveButton = topBar["superUndoButton"];
            else if(flag === 1) cutFrameActiveButton = topBar["reRecordingButton"];
            else if(flag === 2) cutFrameActiveButton = topBar["cutPrevDataButton"];

            if(cutFrameActiveButton.alpha < 1.0)
            {
                resetCutFrameClickCounter();
                return;
            }

            if(replayStartON) stopReplay();

            if(cutFrameClickedButton < 0)
            {
                cutFrameClickedButton = flag;
                cutFrameClickCounter++;
            }
            else if(cutFrameClickedButton !== flag)
            {
                resetCutFrameClickCounter();
                cutFrameClickCounter = 1;
                cutFrameClickedButton = flag;

                if(flag === 0) cutFrameActiveButton = topBar["superUndoButton"];
                else if(flag === 1) cutFrameActiveButton = topBar["reRecordingButton"];
                else if(flag === 2) cutFrameActiveButton = topBar["cutPrevDataButton"];
            }
            else
            {
                cutFrameClickCounter++;
            }

            if(cutFrameClickCounter === 1)
            {
                const replayTimeBox:replayTimeBar = replayTimeBox;
                const replayNowBar:Sprite = replayTimeBox["replayNowBar"] as Sprite;
                const deleteBar:Sprite = replayTimeBox["replayDeleteBar"] as Sprite;
                const replayTotalBar:Sprite = replayTimeBox["replayTotalBar"] as Sprite;

                toolTipBox.visible = false;
                cutFrameActiveButton.addEventListener(MouseEvent.MOUSE_OUT,resetCutFrameClickCounterEvent);
                
                if(flag !== 1)
                {
                    //데이터 전부 읽고 짤라줘야함
                    if(rFrame < rFrameArr.length) 
                    {
                        setSkipFrame(rFrameSum+rFrameArr.length-rFrame,3);
                        rOneSkipFlag = false;
                        checkCutFrameButtons();
                    }
                }

                if(flag === 0)
                {
                    const width:Number = (replayTotalBar.width*(rFrameSum/TOTAL_FRAME));
                    deleteBar.x = replayTotalBar.x+width;
                    deleteBar.width = (replayTotalBar.width-width);
                }
                else if(flag === 1)
                {
                    deleteBar.x = replayTotalBar.x;
                    deleteBar.width = replayTotalBar.width;
                }
                else if(flag === 2)
                {
                    deleteBar.x = replayTotalBar.x;
                    deleteBar.width = replayNowBar.width;
                }

                if(shortcutKey === false)
                {
                    topBar.hint("One more click to OK (Red area will be deleted)",cutFrameActiveButton);
                }
                else if(shortcutKey === true)
                {
                    const funcName:String = (flag === 0) ?  "Super-undo : "
                                            :(flag === 1) ? "Re-recording : "
                                            :(flag === 2) ? "Delete front data : "
                                            : "";
                    topBar.hint(funcName + "One more press key to OK (Red area will be deleted)",cutFrameActiveButton);
                    stage.addEventListener(MouseEvent.MOUSE_DOWN,resetCutFrameClickCounterMouseDownEvent);
                }

                deleteBar.visible = true;
            }
            else if(cutFrameClickCounter >= 2)
            {
                saveContinue = false;
                resetCutFrameClickCounter();
                selectPenTool();

                if(flag === 0) //super undo
                {
                    superUndo();
                }
                else if(flag === 1) //re-recording
                {
                    clearData(true);
                    setCanvasSameReplayCanvas();
                    setReplayUI(false);
                }
                else if(flag === 2) //cut prev data 앞부분 잘라주기 
                {
                    deleteReplayFrontData();
                }
            }
        }

        private function setTopBarHintOFF():void
        {
            clearDataButtonCount = 0;
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,topBarHintOFFEvent);
            topBarHintClickEventON = false;
            topBar.hintOFF();
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
            if(mouseDragON || mouseClickON || toolBox2ON || lassoToolON) return;

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
                        str = "Prev (left, z, .), 1 frame(right-click, shift+click)";
                    break;

                    case "replayNext":
                        str = "Next (right, x, ,), 1 frame(right-click, shift+click)";
                    break;
                    case "replaySpeedBarWrapper":
                    {
                        if(rSpeedLastStr === "") str = "Change playback speed(up, down / f, v / h, n)";
                        else str = rSpeedLastStr;
                    }
                    
                    break;

                    case "saveButton":
                    case "repSaveButton":
                        str = "Save (ctrl+s), As..(right-click, shift+ctrl+s)";
                    break;

                    case "loadButton":
                        str = "Load (ctrl+o), Load to Reference layer (right-click, ctrl+shift+o)";
                    break;
                    case "repLoadButton":
                        str = "Load (ctrl+o)";
                    break;

                    case "clipButton":
                        str = "Load clipboard image (ctrl+v)";
                    break;

                    case "clearButton":
                    {
                        str = "New file (esc, delete)";
                    }
                    break;

                    case "captureButton":
                    case "repCaptureButton":
                        str = "Capture mode (alt+s)";
                    break;

                    case "capOff":
                        str = "Exit capture mode (esc)";
                    break;

                    case "capFull":
                        str = "Save full image (alt+s)";
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

                    case "superUndoButton":
                        if(cutFrameClickCounter === 1 && cutFrameClickedButton === 0)
                        {
                            str = "One more click to OK (Red area will be deleted)";
                        }
                        else
                        {
                            str = "Super-undo (f5, ctrl+z, ctrl+.)";
                        }
                    break;

                    case "reRecordingButton":
                        if(cutFrameClickCounter === 1 && cutFrameClickedButton === 1)
                        {
                            str = "One more click to OK (Red area will be deleted)";
                        }
                        else
                        {
                            str = "Re-recording from this image (f4, ctrl+c, ctrl+,)";
                        }
                    break;

                    case "cutPrevDataButton":
                        if(cutFrameClickCounter === 1 && cutFrameClickedButton === 2)
                        {
                            str = "One more click to OK (Red area will be deleted)";
                        }
                        else
                        {
                            str = "Delete front data (c6, ctrl+x, ctrl+m)";   
                        }
                    break;


                    case "gridButton":
                        str = "Grid (f1)";
                    break;

                    case "sideBarOFFButton":
                    case "sideBarOFFButton2":
                        str = "Sidebar OFF (tab, \\ )";
                    break;

                    case "sideBarONButton":
                    case "sideBarONButton2":
                        str = "Sidebar ON (tab, \\ )";
                    break;

                    case "sideBarPositionButton":
                        str = "Right sidebar (f2)";
                    break;

                    case "sideBarPositionButton2":
                        str = "Left sidebar (f2)";
                    break;

                    case "topBarColorButton":
                        str = "Change UI color (f3)";
                    break;

                    case "aboutButton":
                        str = "About";
                    break;

                    case "updateButton":
                        str = "Version " + NEW_VERSION + " released!";
                       
                    break;

                    case "drawModeButton":
                        str = "Draw mode (1, 7)";
                    break;

                    case "replayModeButton":
                        str = "Replay mode (2, 8)";
                    break;
                    
                    case "toolBoxONButton":
                       str = "Tool-box ON/OFF";
                    break;

                    case "replayZoomInButton":
                        str = "Zoom in";
                    break;
                     case "replayZoomOutButton":
                        str = "Zoom out";
                    break;

                    case "replayRotateButton":
                        str = "Rotate";
                    break;

                    default:
                        
                    return;
                }
                
                if(targetName === "replaySpeedBarWrapper")
                {
                    topBar.hint(str,topBar.replaySpeedSet);
                }
                else
                {
                    topBar.hint(str,e.target as DisplayObject);
                }
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

                if(rSkipImageFolder.exists)
                {
                    rSkipImageFolder.deleteDirectory(true);
                }
                rSkipImageFolder.createDirectory();
                updateFirstImage(canvas1BitmapData,CANVAS_BG_COLOR);
            }
        }

        private function resetSkipImage():void
        {
            const fs:FileStream = new FileStream();
            const file:File = rSkipImageFolder.resolvePath("0.img");
            fs.open(file,FileMode.READ);
            const data:Array = fs.readObject() as Array;
            fs.close();

            const bmpd:BitmapData = new BitmapData(data[1],data[2],true,0);
            const newRectangle:Rectangle = new Rectangle(0,0,data[1],data[2]);
            bmpd.lock();
            bmpd.setPixels(newRectangle,data[0]);
            bmpd.unlock();
            rcanvas1BitmapData.dispose();
            rcanvas1BitmapData = bmpd.clone();

            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
            setPanelSizeReplayMode(rcanvas1Bitmap.width,rcanvas1Bitmap.height);
            setBackgroundColor(data[3],true);
        }

        private function updateFirstImage(bmpd:BitmapData=null,bgColor:uint=0):void //리플레이 처음 이미지 만들어줌
        {
            const fs:FileStream = new FileStream();
            const ba:ByteArray = new ByteArray;
            const w:int = bmpd.width;
            const h:int = bmpd.height;
            const newRectangle:Rectangle = new Rectangle(0,0,w,h);

            rSkipImageFrameData = [0];

            bmpd.copyPixelsToByteArray(newRectangle,ba);
            rFirstImage = bmpd.clone();
            rFirstBGColor = bgColor;

            fs.open(rFirstImageFile,FileMode.WRITE);
            fs.writeObject([ba,w,h,bgColor,0,0]); //첫번째 이미지가 bytearray임
            fs.close();
            ba.clear();
        }

        private function resetUndo():void
        {
            undoIndex = 0;
            addUndoMode = 0;
            undoData = [];//undo 데이터 다 지워줌
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
            var xBitmap:Bitmap = rcanvas1Bitmap;
            var xReg:Sprite = rregPoint;
            var stw:int = stage.stageWidth-offsetX;
            var sth:int = stage.stageHeight-offsetY;
            var w:Number = RCANVAS_WIDTH;
            var h:Number = RCANVAS_HEIGHT;
            const _captureRotated:uint = captureRotated;

            if(!replayMode)
            {
                xBitmap = canvas1Bitmap;
                xReg = regPoint;
                w = CANVAS_WIDTH;
                h = CANVAS_HEIGHT;
            }
            else if(captureMode)
            {
                if(_captureRotated === 1 || _captureRotated === 3)
                {
                    const _w:Number = w;
                    w = h;
                    h = _w;
                }
            }

            //줌이 1.0 보다 작고 가로 세로 줌비율이 가장 작은걸로 선택
            var z:Number = stw/w;
            const zh:Number = sth/h;

            if(zh < z)
            {
                z = zh;
            }

            if(z > 1.0)
            {
                z = 1.0;
            }

            if(captureMode)
            {
                captureZoomed = 1/z;
                xReg.rotation = 90*_captureRotated;
            }
            else 
            {
                xReg.rotation = 0;
            }

            if(replayMode === true && z < 1.0)
            {
                replayEndWithcanvasFitWindow = true;
            }
            
            setZoomCanvas(z,replayMode);
            setCenvasCenterPos(replayMode,captureMode);
            xBitmap.smoothing = true;

            if(captureMode)
            {
                setCaptureCursorON(replayMode,1/z);
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
            rFrame = 0;
            rLastBytes = 0;
            rFrameSum = 0;
            rFrameSumLast = 0;
            rSkipLastIndex = -2;
            replayAllEnd = true;
            replayONUndoUpdate = false;
            // replayModeONFirstSkip = true;
            doDrawSlowEventON = false;
            rFrameArr = [];
            rSpeedLastStr = "";
        }

        private function applyLassoShapen(scale:Number):void
        {
            if(scale === 0.0) return;

            const a:Array = lassoSharpData;
            var index:uint = Math.abs(Math.floor(scale-1.0));
            if(index > 2) index = 2;

            var sharpen:ConvolutionFilter = new ConvolutionFilter(3,3,a[index][0],a[index][1]);

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
            if(!shape)
            {
                rcanvas2Draw.graphics.lineStyle(size,color);
            }
            else
            {
                rcanvas2Draw.graphics.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
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
        }

        private function closureTickDraw():Function
        {
            const cd2:Graphics = rcanvas2Draw.graphics;

            var fr:Array;
            var d:Array;

            return function (lastFlag:Boolean):void
            {
                fr = rFrameArr;
                d = fr[rFrame];

                if(fr.length === 0 || fr === null) return;

                switch(d[0] as String)
                {
                    case "lineStyle":
                    {
                        rLineStyleSave = [d[4] as Number,d[7] as String];

                        if(replayStartON && d[9] !== undefined)
                        {
                            setReplaySubLayer(d[9]);
                        }

                        if(d[10] === true)
                        {
                            setBlurCanvas2DrawBySize(d[2] as Number,true);
                        }
                        else if(rcanvas2Draw.filters.length > 0)
                        {
                            rcanvas2Draw.filters = [];
                        }

                        if(!d[8] as Boolean)
                        {
                            replayLineStyleReady(d[1] as Boolean,d[2] as Number,d[3] as uint,d[4] as Number);
                            cd2.moveTo(d[5] as Number,d[6] as Number);
                        }
                        else
                        {
                            cd2.clear();
                            replayLineStyleReady(false,1,d[3] as uint,1.0);
                            cd2.beginFill(d[3] as uint);
                            cd2.moveTo(d[5] as Number,d[6] as Number);
                            rcanvas2.alpha = d[4] as Number;
                        }
                    }
                    break;

                    case "lineTo":
                    {
                        cd2.lineTo(d[1] as Number,d[2] as Number);

                        if(lastFlag)
                        {
                            rTinyCursorPos = [d[1] as Number,d[2] as Number];
                        }
                    }
                    break;

                    case "sqline":
                    {
                        rcanvas2Bitmap.bitmapData = null;
                        rcanvas2BitmapData.dispose();
                        rcanvas2BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
                        cd2.clear();

                        rLineStyleSave = [d[3] as Number,d[4] as String];
                        rcanvas2.alpha = d[3] as Number;
                        cd2.lineStyle(d[1] as Number,d[2] as uint,1,false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
                        cd2.drawPath(d[5] as Vector.<int>, d[6] as Vector.<Number>);
                    }
                    break;

                    case "fill":
                    {
                        rcanvas2Draw.filters = [];
                        rLineStyleSave = [d[2] as Number,d[3] as String];

                        rcanvas2.alpha = d[2] as Number;
                        cd2.clear();
                        cd2.lineStyle(1,d[1] as uint);
                        cd2.beginFill(d[1] as uint);
                        cd2.drawPath(d[4] as Vector.<int>,d[5] as Vector.<Number>);

                        if(lastFlag)
                        {
                            rTinyCursorPos = [d[5][0] as Number,d[5][1] as Number];
                        }
                    }
                    break;

                    case "fill2":
                    {
                        rcanvas2Draw.filters = [];

                        rLineStyleSave = [d[2] as Number,d[3] as String];
                        rcanvas2.alpha = d[2] as Number;

                        cd2.clear();
                        cd2.lineStyle(1,d[1] as uint);
                        cd2.beginFill(d[1] as uint);

                        const arr:Vector.<Number> = d[4] as Vector.<Number>;
                        const len:uint = arr.length;

                        cd2.moveTo(arr[0],arr[1]);

                        for(var i:uint = 2;i<len;i+=2)
                        {
                            cd2.lineTo(arr[i],arr[i+1]);
                        }

                        cd2.endFill();

                        if(lastFlag)
                        {
                            rTinyCursorPos = [arr[0] as Number,arr[1] as Number];
                        }
                    }
                    break;

                    case "dot":
                    {
                        if(replayStartON && d[8] !== undefined)
                        {
                            setReplaySubLayer(d[8]);
                        }

                        if(d[9] === true)
                        {
                            setBlurCanvas2DrawBySize(d[2] as Number,true);
                        }
                        else if(rcanvas2Draw.filters.length > 0)
                        {
                            rcanvas2Draw.filters = [];
                        }

                        rLineStyleSave = [d[4] as Number,d[7] as String];
                        rcanvas2.alpha = d[4] as Number;
                        cd2.lineStyle(0,0,0);
                        cd2.beginFill(d[3] as uint);

                        if(!d[1] as Boolean)
                        {
                            cd2.drawCircle(d[5] as Number,d[6] as Number,(d[2] as Number)/2);
                        }
                        else if(d[1] as Boolean)
                        {
                            cd2.drawRect((d[5] as Number)-(d[2] as Number)/2
                                                        ,(d[6] as Number)-(d[2] as Number)/2
                                                        , d[2] as Number
                                                        , d[2] as Number);
                        }

                        if(lastFlag)
                        {
                            rTinyCursorPos = [d[5] as Number,d[6] as Number];
                        }

                        cd2.endFill();
                    }
                    break;

                    case "line":
                    {
                        rcanvasPanel.setChildIndex(rcanvas2,1);

                        rLineStyleSave = [d[4] as Number,d[9] as String];
                        rcanvas2.alpha = d[4] as Number;

                        if(replayStartON && d[10] !== undefined)
                        {
                            setReplaySubLayer(d[10]);
                        }

                        if(d[11] === true)
                        {
                            setBlurCanvas2DrawBySize(d[2] as Number,true);
                        }
                        else if(rcanvas2Draw.filters.length > 0)
                        {
                            rcanvas2Draw.filters = [];
                        }

                        if(!d[1] as Boolean)
                        {
                            cd2.lineStyle(d[2] as Number,d[3] as uint);
                        }
                        else
                        {
                            cd2.lineStyle(d[2] as Number,d[3] as uint,1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
                        }

                        cd2.moveTo(d[5] as Number,d[6] as Number);
                        cd2.lineTo(d[7] as Number,d[8] as Number);

                        if(lastFlag)
                        {
                            rTinyCursorPos = [d[7],d[8]];
                        }
                    }
                    break;

                    case "move":
                    {
                        replayMoveImage(d[1] as Number,d[2] as Number);
                    }
                    break;

                    case "lasso":
                    {
                        const lsbox:Sprite = lassoBox;
                        const point1:Vector.<Number> = d[1] as Vector.<Number>;
                        const point2:Array = d[2] as Array;

                        if(point1.length === 0 || point2.length === 0) break;

                        const lassoInfo:Array = d[3] as Array;
                        const copyFlag:Boolean = d[4] as Boolean;
                        const lassoInfo0:Number = lassoInfo[0] as Number;
                        const lassoInfo1:Number = lassoInfo[1] as Number;
                        const lassoInfo2:Number = lassoInfo[2] as Number;
                        const lassoInfo3:Number = lassoInfo[3] as Number;
                        const lassoInfo4:Number = lassoInfo[4] as Number;
                        const lassoInfo5:Number = lassoInfo[5] as Number;
                        const lassoInfo6:Number = lassoInfo[6] as Number;

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
                            break;
                        }

                        var posMatrix:Matrix = new Matrix();
                        posMatrix.scale(lassoInfo0,lassoInfo1);
                        posMatrix.translate(-lassoInfo2/2,-lassoInfo3/2);
                        posMatrix.rotate(lassoInfo4);
                        posMatrix.translate(lassoInfo5,lassoInfo6);

                        lassoBMP.smoothing = true;

                        if(lassoInfo0 !== 1 || lassoInfo4 !== 0)
                        {
                            applyLassoShapen(lassoInfo0);
                        }

                        rcanvas1BitmapData.draw(lassoBMP,posMatrix);
                        rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;

                        resetLassoBox2();

                    }
                    break;

                    case "mirror":
                    {
                        replayMirrorCanvas();
                        break;
                    }
                    case "bgColor":
                    {
                        rBGColorSave = d[1] as uint;
                        setBackgroundColor(d[1] as uint,true);
                    }
                    break;

                    case "canvasSize":
                    {
                        setPanelSizeReplayMode(d[1] as Number,d[2] as Number,d[3] as Number,d[4] as Number,d[5] as Boolean);
                    }
                    break;

                    case "tempDone":
                    {
                        rcanvas2BitmapData.draw(rcanvas2Draw);
                        rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                        cd2.clear();
                    }
                    break;

                    case "drawDone":
                    {
                        const tmpD2:Array = rLineStyleSave;
                        const canvasAlpha:ColorTransform = new ColorTransform(1,1,1,tmpD2[0] as Number);

                        rcanvas2BitmapData.draw(rcanvas2Draw);
                        rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;

                        if(d[1] !== undefined && d[1] === true)
                        {
                            const subLayer:BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
                            subLayer.draw(rcanvas2Bitmap,null,canvasAlpha);
                            subLayer.draw(rcanvas1Bitmap);
                            rcanvas1BitmapData = subLayer.clone();
                            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                            subLayer.dispose();
                        }
                        else
                        {
                            rcanvas1BitmapData.draw(rcanvas2Bitmap,null,canvasAlpha,tmpD2[1] as String);
                            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                        }

                        rcanvas2Bitmap.bitmapData = null;
                        rcanvas2BitmapData.dispose();
                        rcanvas2BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);

                        cd2.clear();
                    }
                    break;

                    case "clear":
                    {
                        rcanvas1BitmapData.dispose();
                        rcanvas1BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
                        rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                    }
                    break;
                }
                rFrame++;
            };
        }

        private function getAutoSkipFrame(oldspeed:Number):Number
        {
            const biasSpeed:Number = REPLAY_SLOWDRAW_ACTIVE_SPEED;
            const minTime:Number = TOTAL_FRAME/(biasSpeed*STAGE_FRAME);
            const subTime:Number = minTime-40;
            const subSpeed:Number = REPLAY_MAX_SPEED-biasSpeed;
            const unitTime:Number = subTime/subSpeed;
            const nowSpeed:Number = oldspeed-biasSpeed;
            const newTime:Number = (subTime-unitTime*nowSpeed)+40;
            const newSkipFrame:Number = Math.floor(TOTAL_FRAME/newTime);

            return newSkipFrame;
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
                const nextFrame:Number = getAutoSkipFrame(rSpeed);
                const finalFrame:Number = rFrameSum+Math.floor(nextFrame/2);
                const totalF:Number = TOTAL_FRAME;
                const _rFrameSum:Number = rFrameSum;
                const getTimeStr:String = getReplayTime(nextFrame,totalF-_rFrameSum,true);
                const timeStr:String = (getTimeStr === "0 sec") ? "" : " ("+getTimeStr+")";

                setSkipFrame(finalFrame,1); 
                replayTimeBox["frameInfo"].text = _rFrameSum+" / " + totalF + timeStr;
                rFrameTextDelayTime = nt;
            }
        }

        private function doDrawEvent(e:Event):void
        {
            doDraw(rSpeed,0);
        }

        //skipFlag  0: 기본 재생 1:탐색바를 마우스를 이용하여 스킵, 2:one frame 이전스트로크, 3:one frame 이후 스트로크
        private function closureDoDraw():Function
        {
            //skipflag 1번은 마우스 커서로 무작위 스킵, 2,3번은 스트로크 단위혹은 프레임 단위로 앞뒤로 탐색
            const _REPLAY_SLOWDRAW_ACTIVE_SPEED:Number = REPLAY_SLOWDRAW_ACTIVE_SPEED;
            const cd2:Graphics = rcanvas2Draw.graphics;
            const tcursor:SimpleButton = rCursor;
            const _rfs:FileStream = rFileStream;
            const CACHE_DIV_10:Number= Math.floor(IMG_CACHE_INTERVAL/20);
            
            var rDataLen:uint;
            var drawLimit:Number;
            var rFrameLimit:Number; //rframe 인덱스 0번 기준
            var obj:Array;
            var prevSkipImageSaveCount:Number;
            var prevSkipImageSaveIndex:uint;
            var nt:int;
            var rFrameCursorDelayTime:int = 0; //커서 딜레이
            var _rFrameTextDelayTime:int = 0; //프레임 바 딜레이
            var getTimeStr:String;
            var timeStr:String;

            return function (skipCount:Number,skipFlag:int):void
            {
                if(replayStartON === false && !skipFlag) return;

                rDataLen = rData.length;
                drawLimit = skipCount-1;
                rFrameLimit = rFrameArr.length-1; //rframe 인덱스 0번 기준
                prevSkipImageSaveCount = 0;
                prevSkipImageSaveIndex = 0;

                //REPLAY_SLOWDRAW_ACTIVE_SPEED 이상으로 전체 재생 시간이 60초 이하일경우 작동
                if(skipCount > _REPLAY_SLOWDRAW_ACTIVE_SPEED)
                {
                    if(REPLAY_FASTEST_TOTAL_TIME > 60 && skipFlag === 0)
                    {
                        setSlowDraw();
                        return;
                    }
                }

                if(drawLimit < 0)
                {
                    rFrameSumLast = rFrameSum - 1;
                }

                for(var i:Number=0;i<=drawLimit;i++)
                {
                    if(!rDataReadFlag)
                    {
                        prevSkipImageSaveCount++;
                        if(rFrame > rFrameLimit)
                        {
                            if(_rfs.bytesAvailable > 0)
                            {
                                obj = _rfs.readObject() as Array;
                                rFrameArr = obj;
                                rFrameLimit = obj.length-1;
                                rFrame = 0;
                                rFileCutBytes = rLastBytes;
                                rLastBytes = _rfs.position;
                                rFrameSumLast = rFrameSum;
                                
                                //수동 탐색할때 속도를 위해서 썸네일 이미지를 더 잘게 쪼개줌
                                if(skipFlag === 1 || skipFlag === 2)
                                {
                                    if(prevSkipImageSaveCount >= CACHE_DIV_10)
                                    {
                                        prevSkipImageSaveCount = 0;
                                        if(!rDataPreviewCacheImages[prevSkipImageSaveIndex])
                                        {
                                            rDataPreviewCacheImages[prevSkipImageSaveIndex] = [rcanvas1BitmapData.clone(),rcanvas1BitmapData.width,rcanvas1BitmapData.height,RCANVAS_BG_COLOR,rFileCutBytes,rFrameSum];
                                        }
                                        prevSkipImageSaveIndex++;
                                    }
                                }

                                i--;
                                continue;
                            }
                            else
                            {
                                rDataReadFlag = true;
                                rFrame = 0;
                                rIndex = 0;

                                if(rFileTotalFrame !== rFrameSum)//다시한번 체크하고 갱신해줌
                                {
                                    rFileTotalFrame = rFrameSum;
                                    TOTAL_FRAME = getTotalFrame();
                                }

                                if(skipFlag === 0)
                                {
                                    _rfs.close();
                                    rLastBytes = 0;
                                }

                                if(rData.length > 1)
                                {
                                    rFrameSumLast = rFrameSum;
                                    rFrameArr = rData[rIndex];
                                    rFrameLimit = rFrameArr.length-1;
                                }
                                else
                                {
                                    rFrameArr = [];
                                }

                                i--;
                                continue;
                            }
                        }
                    }
                    else
                    {
                        if(rFrame > rFrameLimit)
                        {
                            rFrame = 0;
                            rIndex++;

                            if(rIndex > undoIndex || rDataLen === 0) //자연적 으로 끝났을때
                            {
                                if(mirrorPushON) replayMirrorCanvas();

                                tcursor.visible = false;
                                replayAllEnd = true;

                                if(skipFlag === 0 || doDrawSlowEventON === true)//1프레임 이상일때만 재시작 타이머 가동
                                {
                                    //reset replay time해주지 말고 그냥 end플래그만 올려줌
                                    //왜냐하면 리플레이 자연적으로 끝나고도 스킵프레임이나 oneframe skip을 해줄수가 있기 때문
                                    replayTimeBox["replayNowBar"].width = replayTimeBox["replayTotalBar"].width;
                                    replayTimeBox["frameInfo"].text = TOTAL_FRAME+" / " +TOTAL_FRAME;
                                    stopReplay();//플레이 아이콘 내주지 말기
                                    replayCompleteEffect();
                                    setRestartTimer();

                                    return;
                                }

                                break;
                            }

                            rFrameSumLast = rFrameSum;
                            rFrameArr = rData[rIndex];
                            rFrameLimit = rFrameArr.length-1;

                            i--;
                            continue;
                        }
                    }
            
                    doTickDraw((skipFlag >= 2) ? true : (i === drawLimit));
                    
                    rFrameSum++; //resultFrameSum 으로 대체함
                }

                if(skipFlag === 0)
                {
                    nt = getTimer();

                    if(nt-rFrameCursorDelayTime >= 100)
                    {
                        rFrameCursorDelayTime = nt;
                        tcursor.x = rTinyCursorPos[0];
                        tcursor.y = rTinyCursorPos[1];
                        
                        if(!mouseClickON)
                        {
                            checkAutoScroll.check(rTinyCursorPos[0],rTinyCursorPos[1]);
                        }
                    }

                    if(nt-_rFrameTextDelayTime >= 1000) //갱신 느리게 해줌
                    {
                        _rFrameTextDelayTime = nt;
                        updateReplayRemainTime();
                    }
                }
                else if(doDrawSlowEventON === false)
                {
                    updateReplayRemainTime();
                }

                if(!rSkipMouseON)
                {
                    replayTimeBox["replayNowBar"].width = replayTimeBox["replayTotalBar"].width*rFrameSum/TOTAL_FRAME;
                }
            };
        }

        private function getReplayTime(speed:Number,totalF:Number,slowFRAME:Boolean=false):String
        {
            const fps:Number = (slowFRAME === true) ? 1 : STAGE_FRAME;
            const floor:Function = Math.floor;
            const sec:Number = (totalF/(fps*speed))+1;
            const min:Number = sec/60;
            const hour:Number = min/60;
            var timeStr:String = (floor(hour) > 0) ? floor(hour*10)/10+" hrs"
                                :(floor(min)  > 0) ? floor(min*10)/10+" min"
                                                   : floor(sec+0.5)+" sec";

            return timeStr;
        }

        //autoscroll check에서 계속 갱신해주면 부하 걸릴거같아서 줌하거나 캔버스 사이즈 조절되거나
        //할때 특정 조건에서만 업데이트 시키는거임
        private function updateReplayCanvasBounds():void
        {
            checkAutoScroll.updateRCanvasBounds();
        }

        private function closureAutoScroll():Object
        {
            const abs:Function = Math.abs;
            const floor:Function = Math.floor;
            const offsetY:Number = topBar.BARSIZE+replayTimeBox.BARSIZE;
            const padding:Number = 15;
            const _rregPoint:Sprite = rregPoint;
            const zerop:Point = new Point(0,0);

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
            var cursorX:Number;//rcanvas1 글로벌 좌표에
            var cursorY:Number;//회전된 캔버스에서 커서 위치를 더해줌. 즉 윈도우 기준에서 커서 커서 위치를 구하는거임
            var checkOverWidth:Boolean; //캔버스 가로 새로 길이가 스테이지 길이보다 클때 체크
            var checkOverHeight:Boolean;
            var windowCenterX:Number; //캔버스 중점위치, 창 중점위치 사이 거리
            var windowCenterY:Number;
            var checkCenterX:Boolean; //캔버스 중점위치, 창 중점위치 사이 거리
            var checkCenterY:Boolean;

            const leftLimit:Number = padding;
            const topLimit:Number = padding+offsetY;
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

                checkOverWidth = right-left > stw;
                checkOverHeight = bottom-top > sth;
                windowCenterX = floor(stw/2-(right+left)/2); //캔버스 중점위치, 창 중점위치 사이 거리
                windowCenterY = floor((sth/2-(bottom+top)/2)+offsetY);
                checkCenterX = abs(windowCenterX) > 0; //캔버스 중점위치, 창 중점위치 사이 거리
                checkCenterY = abs(windowCenterY) > 0;

                rightLimit = stw-padding;
                bottomLimit = sth+offsetY-padding;
            }

            function check(x:Number,y:Number):void
            {
                globalChecked = false;

                if(!checkOverWidth)
                {
                    if(checkCenterX)
                    {
                        _rregPoint.x += windowCenterX;
                        updateRCanvasBounds();
                    }
                }
                else
                {
                    globalChecked = true;
                    g = rcanvas1.localToGlobal(zerop);
                    rg = rotatePoint(x,y,-_rregPoint.rotation);
                    cursorX = g.x+(rg.x*z);

                    if(cursorX < leftLimit)
                    {
                        _rregPoint.x += floor(abs((cursorX-stw/2)/5));
                        updateReplayCanvasBounds(); 
                    }
                    else if(cursorX > rightLimit)
                    {
                        _rregPoint.x -= floor(abs((cursorX-stw/2)/5));
                        updateReplayCanvasBounds();
                    }
                }

                if(!checkOverHeight)
                {
                    if(checkCenterY)
                    {
                        _rregPoint.y += windowCenterY;
                        updateRCanvasBounds();
                    }
                }
                else
                {
                    if(globalChecked === false)
                    {
                        globalChecked = true;
                        g = rcanvas1.localToGlobal(zerop);
                        rg = rotatePoint(x,y,-_rregPoint.rotation);
                    }
                    cursorY = g.y+(rg.y*z);

                    if(cursorY < topLimit)
                    {
                        _rregPoint.y += floor(abs((cursorY-sth/2)/5));
                        updateReplayCanvasBounds();
                    }
                    else if(cursorY > bottomLimit)
                    {
                        _rregPoint.y -= floor(abs((cursorY-sth/2)/5));
                        updateReplayCanvasBounds();
                    }
                }
            }

            return {
                check:check,
                updateRCanvasBounds:updateRCanvasBounds
            };
        }

        private function updateReplayRemainTime():void
        {
            const totalF:Number = TOTAL_FRAME;
            const _rFrameSum:Number = rFrameSum;
            const namojiTime:String = getReplayTime(rSpeed,totalF-_rFrameSum);
            const namojiTimeStr:String = (namojiTime === "0 sec") ? "" : " ("+namojiTime+")";

            replayTimeBox["frameInfo"].text = _rFrameSum+" / " + totalF + namojiTimeStr;
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
            mouseDragON = true;

            function getReplayTotalTime(_speed:uint):String
            {
                if(REPLAY_FASTEST_TOTAL_TIME > 60)
                {
                    _speed = getAutoSkipFrame(_speed);
                    timeStr = getReplayTime(_speed,totalF,true);
                }
                else
                {
                    timeStr = getReplayTime(_speed,totalF);
                }

                return timeStr;
            }

            function setSpeed(mx:Number):void
            {
                var exp:Number = mx/maxDist;
                if(exp < 0) exp = 0;
                else if(exp > 1) exp = 1;
                var nowSpeed:uint = floor(Math.pow(max,exp));

                if(nowSpeed > max) nowSpeed = max;

                const finalStr:String = "Playback speed x "+rSpeed+" ("+timeStr+")";
                timeStr = getReplayTotalTime(nowSpeed);
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
                updateReplayRemainTime();
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,replaySpeedButtomMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,replaySpeedButtomUpEvent);
            }

            function replaySpeedButtomMoveEvent(e:MouseEvent):void
            {
                moveButton(set.mouseX);
            }
            moveButton(set.mouseX);
            setSpeed(set.mouseX);

            stage.addEventListener(MouseEvent.MOUSE_MOVE,replaySpeedButtomMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,replaySpeedButtomUpEvent);
        }

        private function getTotalFrame():Number
        {
            var totalF:Number = rFileTotalFrame;
            const _rDataFrame:Array = rDataFrame;
            var rDataSum:Number = 0;
            var aa:uint;

            for(var i:uint=0,len:uint=undoIndex;i<=len;i++)
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

        //targetFrame이 rSkipImageFrameData데이터에 몆 번 인덱스에 있나 구해줌
        private function getSkipImageIndex(targetFrame:Number):Number
        {
            const arr:Array = rSkipImageFrameData;
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
            const rSum:Number = rFrameSum;

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

            if(rSum === TOTAL_FRAME)
            {
                tb["reRecordingButton"].alpha = BUTTON_OFF_ALPHA;
            }
            else
            {
                tb["reRecordingButton"].alpha = 1.0;
            }
        }

        private function skipOneFrame(prev:Boolean,trueOneFrame:Boolean):void
        {
            const _rFrameSum:Number = rFrameSum;

            if(trueOneFrame)
            {
                if(prev && _rFrameSum > 0)
                {
                    setSkipFrame(_rFrameSum-1);
                }
                else if(!prev && _rFrameSum < TOTAL_FRAME)
                {
                    setSkipFrame(_rFrameSum+1);
                }
            }
            else
            {
                if(prev && _rFrameSum > 0)
                {
                    setSkipFrame(rFrameSumLast,2);
                }
                else if(!prev && _rFrameSum < TOTAL_FRAME)
                {
                    var goFrame:Number = rFrameSum+rFrameArr.length-rFrame+1;
                    //dodraw에서 3번 플래그는 break해줘서 infinity로 해도 되는데
                    //skipimage index찾는 과정에서 문제가 있어서 정확해 해줘야함
                    if(_rFrameSum === 0)
                    {
                        rOneSkipFlag = prev;
                        setSkipFrame(1,3);
                    }
                    goFrame = rFrameSum+rFrameArr.length-rFrame+1;
                    setSkipFrame(goFrame,3);

                    if(rOneSkipFlag !== prev)
                    {
                        goFrame = rFrameSum+rFrameArr.length-rFrame+1;
                        setSkipFrame(goFrame,3);
                    }
                }
            }

            rOneSkipFlag = prev;
            checkCutFrameButtons();
        }

        private function setSkipOneFrame(prev:Boolean,useKey:Boolean=false,trueOneFrame:Boolean=false):void
        {
            if(cutFrameClickCounter > 0)
            {
                resetCutFrameClickCounter();
            }

            var cancelFlag:Boolean = false;

            if(replayStartON) stopReplay();
  
            topBar["reRecordingButton"].visible = true;
            
            function autoOneFrameSkipEvent(e:Event):void
            {
                skipOneFrame(prev,trueOneFrame);
            }

            function autoOneFrameSkipCancelEvent(e:Object):void
            {
                clearTimeout(rOneSkipTimer);
                stage.removeEventListener(Event.ENTER_FRAME,autoOneFrameSkipEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,autoOneFrameSkipCancelEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,autoOneFrameSkipCancelEvent);
                stage.nativeWindow.removeEventListener(Event.DEACTIVATE,autoOneFrameSkipCancelEvent);
            }

            if(!useKey) //마우스로 버튼 클릭했을때
            {
                //오래누르고 있으면 enter frame으로 계속 발동 앞으로 가기만
                clearTimeout(rOneSkipTimer);
                rOneSkipTimer = setTimeout(function():void
                {
                    stage.addEventListener(Event.ENTER_FRAME,autoOneFrameSkipEvent);
                },300);
                stage.nativeWindow.addEventListener(Event.DEACTIVATE,autoOneFrameSkipCancelEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,autoOneFrameSkipCancelEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,autoOneFrameSkipCancelEvent);
            }

            skipOneFrame(prev,trueOneFrame);
        }

        private function setSkipFrame(jumpframe:Number,flag:uint=1):void //skipp 
        {
            //flag = 1 //딱 한프레임만 스킵할때
            //flag = 2 //이전 탐색 할때 올려줌
            //flag = 3 //앞 탐색 할때 올려줌
            const fSum:Number = rFrameSum;
            
            if(jumpframe < 0)
            {
                jumpframe = 0;
            }
            if(jumpframe === fSum)
            {
                return;
            }

            const prevSkipFlag:Boolean = jumpframe < fSum;
            const tcursor:SimpleButton = rCursor;
            const index:Number = getSkipImageIndex(jumpframe);
            var prevSkipImageIndex:Number = 0; //자잘 썸네일 인덱스를 넣어줌
            var skipImageData:Array = [];
            var tempBmpd:BitmapData = new BitmapData(1,1,true,0);

            rFileStream.open(repFile,FileMode.READ);

            if(index !== rSkipLastIndex)
            {
                rDataPreviewCacheImages = [];
            }
            else if(rDataPreviewCacheImages.length > 0) //프리뷰 썸네일 데이터 있을경우
            {
                prevSkipImageIndex = getCacheImageIndex(jumpframe);
            }

            if(index !== rSkipLastIndex || prevSkipFlag)
            {
                if(prevSkipImageIndex > 0)//prevSkipFlag && false)
                {
                    skipImageData = rDataPreviewCacheImages[prevSkipImageIndex];
                }
                else
                {
                    const file:File = rSkipImageFolder.resolvePath(index+".img");
                    const fs:FileStream = new FileStream();
                    fs.open(file,FileMode.READ);
                    skipImageData = fs.readObject() as Array;
                    fs.close();
                }

                rSkipLastIndex = index;
                rLastBytes = skipImageData[4]; //마지막 바이트
                rFileStream.position = skipImageData[4];
                rFrameSum = skipImageData[5]; //썸네일 이미지를 저장한 프레임
                //원하는 프레임에서 썸네일 이미지 프레임을 빼줌 나머지 프레임만 그려주면 되니깐
                jumpframe = jumpframe-skipImageData[5]; 
                rDataReadFlag = false;
                rIndex = 0; //이거 먼저 초기화 시켜주어야함
                rFrame = 0;
                rFrameArr = [];
                clearCanvasReplayMode();

                if(prevSkipImageIndex > 0)
                {
                    tempBmpd = skipImageData[0];
                }
                else
                {
                    tempBmpd = new BitmapData(skipImageData[1],skipImageData[2],true,0);
                    const newRectangle:Rectangle = new Rectangle(0,0,skipImageData[1],skipImageData[2]);
                    tempBmpd.lock();
                    tempBmpd.setPixels(newRectangle,skipImageData[0]);
                    tempBmpd.unlock();
                }

                rcanvas1BitmapData.dispose();
                rcanvas1BitmapData = tempBmpd.clone();
                rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                setPanelSizeReplayMode(rcanvas1Bitmap.width,rcanvas1Bitmap.height);
                setBackgroundColor(skipImageData[3],true);
            }
            else //점프 프레임이 기존 프레임 이후일때는 계속 그림
            {
                if(!rDataReadFlag) rFileStream.position = rLastBytes;
                jumpframe = jumpframe - fSum;
            }

            doDraw(jumpframe,flag);
            rFileStream.close();

            //dodraw밑이기 때문에 rFrameSum이 갱신되서 위에 fsum은 쓸수가 없음
            if(rFrameSum >= TOTAL_FRAME)
            {
                replayAllEnd = true;
                tcursor.visible = false;
                //보통 스킵일때 마지막 임시 mirror가 켜져있을때 여기서 해줌
                //스킵이 너무 딱맞게 되서 마지막을 안하나?
                if(mirrorPushON && flag === 1)
                {
                    replayMirrorCanvas();
                }
            }
            else
            {
                replayAllEnd = false;
                tcursor.visible = true;
                tcursor.x = rTinyCursorPos[0];
                tcursor.y = rTinyCursorPos[1];
            }
            checkAutoScroll.check(tcursor.x,tcursor.y);
        }

        private function setSkipFrameButton():void
        {
            const totalF:Number = TOTAL_FRAME;
            if(totalF === 0 || rSkipImageInit > 0) return;

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
            var skipUpdateTimer:uint = 0;
            var oldFrame:Number = floor(totalF*clickedX/maxWidth);
            var finalFrame:Number = 0;

            rSkipMouseON = true;
            nowBar.width = clickedX;

            checkBarLimit();
            oldFrame = finalFrame;
            setSkipFrame(finalFrame);

            function checkBarLimit():void
            {
                var mx:Number = totalBar.mouseX*totalBarScale;

                if(mx < 0)
                {
                    mx = 0;
                }
                else if(mx > maxWidth)
                {
                    mx = maxWidth;
                }

                finalFrame = floor(totalF*mx/maxWidth);
                nowBar.width = mx;
            }

            function replayTimeMouseUpEvent(e:MouseEvent):void
            {
                rSkipMouseON = false;
                clearTimeout(skipUpdateTimer);
                skipUpdateTimer = 0;
                oldFrame = finalFrame;
                setSkipFrame(finalFrame);

                checkBarLimit();

                //skipframe함수 이후에 실행
                if(!replayStartONSave)
                {
                    checkCutFrameButtons();
                }
                //재생중에 스킵하고 있었으면 다시 시작
                if(replayStartONSave && !replayAllEnd)
                {
                    startReplay();
                }
                else if(replayAllEnd)
                {
                    stopReplay();
                }

                stage.removeEventListener(MouseEvent.MOUSE_MOVE,replayTimeMouseMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,replayTimeMouseUpEvent);
            }

            function replayTimeMouseMoveEvent(e:MouseEvent):void
            {
                if(limitMouseMoveEventTime() === true)
                {
                    return;
                }

                checkBarLimit();
                
                if(skipUpdateTimer === 0)
                {
                    clearTimeout(skipUpdateTimer);
                    skipUpdateTimer = setTimeout(function():void
                    {
                        skipUpdateTimer = 0;
                        oldFrame = finalFrame;
                        setSkipFrame(finalFrame);
                    },200);
                }
            }

            stage.addEventListener(MouseEvent.MOUSE_UP,replayTimeMouseUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,replayTimeMouseMoveEvent);
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
                resetSkipImage();
                rDataReadFlag = false;
                replayAllEnd = false;//resetReplayTime함수 에서 이걸 true로 해주기 때문에 아래쪽에서 변경
            }

            if(replayEndWithcanvasFitWindow === true)
            {
                replayEndWithcanvasFitWindow = false;
                setZoomCanvas(1.0,true);
            }

            if(!rDataReadFlag)
            {
                rFileStream.open(repFile,FileMode.READ);
                rFileStream.position = rLastBytes;
            }
            
            if(cutFrameClickCounter > 0)
                resetCutFrameClickCounter();

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
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, toolBoxMoveMouseMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP, toolBoxMoveMouseUpEvent);
            }

            function toolBoxMoveMouseMoveEvent(e:MouseEvent):void
            {
                xBox.x += mouseX-click.x;
                xBox.y += mouseY-click.y;

                click.x = mouseX;
                click.y = mouseY;
            }

            stage.addEventListener(MouseEvent.MOUSE_MOVE, toolBoxMoveMouseMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP, toolBoxMoveMouseUpEvent);
        }


		private function zoomIconOFFEvent(e:MouseEvent):void
		{
			const targetName:String = e.target.name;
			if(targetName && targetName === "zoomInButton" || targetName === "zoomOutButton"
            || targetName === "toolZoom")
			{

			}
			else
			{
			    stage.removeEventListener(MouseEvent.MOUSE_DOWN,zoomIconOFFEvent);
				toolBox.zoomIconOFF();
			}
		}

        private function checkToolBoxButtonUpEvent(e:MouseEvent):void
        {
            stage.removeEventListener(MouseEvent.MOUSE_UP,checkToolBoxButtonUpEvent);
            
            const targetName:String = e.target.name;

            if(toolBoxAlwaysClickTool !== targetName)
            {
                toolBoxAlwaysClickTool = "";
                return;
            }

            toolBoxAlwaysClickTool = "";

            switch(targetName)
            {
                case "toolPen":
                {
                    if(nowTool !== TOOL_PEN)
                    {
                        selectPenTool();
                        updatePenSizeCursor();
                    }
                }
                break;
                case "toolFillPen":
                {
                    if(nowTool !== TOOL_FILL_PEN) 
                    {
                        selectFillPenTool();
                        updatePenSizeCursor();
                    }
                }
                break;
                case "toolErase":
                {
                    if(nowTool !== TOOL_ERASE) 
                    {
                        selectEraseTool();
                        updatePenSizeCursor();
                    }
                }
                break;
                case "toolLine":
                {
                    if(nowTool !== TOOL_LINE) 
                    {
                        selectLineTool();
                        updatePenSizeCursor();
                    }
                }
                break;
                case "toolLasso":
                {
                    if(nowTool !== TOOL_LASSO) 
                    {
                        selectLassoTool();
                    }
                }
                break;
                case "toolSpuit":
                {
                    if(nowTool !== TOOL_SPUIT) 
                    {
                        nowToolBackup = nowTool;
                    }

                    setSpuitTool();
                }
                break;
                case "toolUndo":
                {
                    setUndoButton();
                }
                break;
                case "toolRedo":
                {
                    setRedoButton();
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
                case "toolZoom":
                {
                    toolBox.zoomIconON();
                    stage.addEventListener(MouseEvent.MOUSE_DOWN,zoomIconOFFEvent);
                }
                break;

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

        //드래그 타이머 걸어서 실제적으로 색깔 선택
        private function setBackgroundColor(color:uint,replayMode:Boolean=false):void
        {
            var xbg:uint = (!replayMode) ? CANVAS_BG_COLOR: RCANVAS_BG_COLOR;

            if(xbg === color)
            {
                return;
            }

            var xCanvas:Sprite = canvasPanel;
            var xw:uint = CANVAS_WIDTH;
            var xh:uint = CANVAS_HEIGHT;

            if(replayMode)
            {
                xCanvas = rcanvasPanel;
                xw = RCANVAS_WIDTH;
                xh = RCANVAS_HEIGHT;
                RCANVAS_BG_COLOR = color;
            }
            else
            {
                clearButtonClicked = false;
                saveOneTime = false;
                CANVAS_BG_COLOR = color;
                previewBox.changeprevBitmapBGColor(color);
            }
            
            const cg:Graphics = xCanvas.graphics;
            cg.clear();
            cg.beginFill(color);
            cg.drawRect(0,0,xw,xh);
            cg.endFill();
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
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,toolTipBoxTimerOFFEvent);
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

        private function setToolTipString(str:String):void
        {
            const _toolTipBox:toolTipBoxSet = toolTipBox;
            const toolTipText:TextField = _toolTipBox["toolTipInfoText"];
            if(str !== "")
            {
                toolTipText.text = str;
                toolTipText.width = toolTipText.textWidth+20;
            }

            const mx:Number = mouseX;
            const my:Number = mouseY;
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
            else if(right > stw) _toolTipBox.x = stw-cw;
            else _toolTipBox.x = mx-cw/2;

            if(my-offsetY < 0) _toolTipBox.y = 0;
            else if(bottom >= sth) _toolTipBox.y = ylim;
            else _toolTipBox.y = my-offsetY;

            if(my >= _toolTipBox.y-1) //맨 아래에서 커서가 힌트를 넘어갈때 다시 위로 올려줌
            {
                var ycheck:Number = my+offsetY-25;
                _toolTipBox.y = (ycheck < ylim) ? ycheck : ylim;
            }

            if(str !== "")
            {
                _toolTipBox["toolTipBoxBG"].width = cw;
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
            const box:loadBox = fileDragSelectBox;

            if(box.visible === false)
            {
                if(lassoToolON === true)
                {
                    setLassoCancelButton();
                    resetLassoBox();
                    selectPenTool();
                }

                setDragDropSelectBoxCenterPos();
                box.visible = true;  
                setTopChildIndex(box);
            }

            if(toolBox2ON)
            {
                closeToolBox2();
            }
        }

        private function onDragDropEvent(e:NativeDragEvent):void
        {
            rFileStream.close();
            restartTimerCancel();

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

        private function pickHistoryColor():void
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
                setBackgroundColor(pickedColor);
                rDataBuffer.push(["bgColor",pickedColor]);
                addUndoData(3);
            }
            else if(_pickerMode === 1)
            {
                changedColor = pickedColor;
                penColor = pickedColor;
                colorHistoryIndex = index;

                setHSVCursorPosByColor(pickedColor);

                if(nowTool === TOOL_LINE)
                {
                    nowToolBackup = TOOL_LINE;
                    selectLineTool();
                }
                else
                {
                    if(nowTool === TOOL_FILL_PEN)
                    {
                        selectFillPenTool();
                    }
                    else
                    {
                        nowToolBackup = TOOL_PEN;
                        selectPenTool();
                    }
                }
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

            const findIndex:int = addColorToHistory(color);
            const arr:Array = colorHistoryList;
            const c:Vector.<uint> = HEXtoRGB(color);

            if(findIndex < 1)
            {
                setToolTipStringTime("Added RGB "+c[0]+","+c[1]+","+c[2]);
                toolTipBox.visible = true;
                updateColorHistoryList();
            }
            else checkColorHistoryLastColor(color,true);  //이미 컬러가 있으면 그냥 업뎃
        }

        //최근에 쓴 컬러를 항상 마지막에 오게함
        private function checkColorHistoryLastColor(color:uint,updateFlag:Boolean):void
        {
            const arr:Array = colorHistoryList;
            const arrlength:uint = arr.length;
            const findIndex:int = arr.lastIndexOf(color);

            if(arrlength > 1 && color !== arr[arrlength-1])
            {
                updateFlag = true;
                colorHistoryList.push(arr.splice(findIndex,1)[0]);
            }

            if(updateFlag === true)
            {
                updateColorHistoryList();
            }
        }

        private function addColorToHistory(color:uint):int
        {
            const arr:Array = colorHistoryList;
            //리스트 안에 컬러가 있으면 넣어주지 않음
            const findIndex:int = arr.lastIndexOf(color);

            if(findIndex < 1)
            {
                arr.push(color);
                if(arr.length > colorHistoryLimit)
                {
                    arr.splice(0,1);
                }
            }
            return findIndex;
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
            var x:Number = 0;
            var y:Number = 0;

            cg.clear();

            for(var i:int=0;i<len;i++)
            {
                if(changedColor === arr[i] && i !== 0)
                {
                    colorHistoryIndex = i;
                }
                cg.beginFill(arr[i]);
                cg.drawRect(x*w,y,w,h);
                x++;
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

        private function eraseKeyDownEvent(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;

            if(keyCode === gKey.n4 || keyCode === gKey.n0)
            {
                eraseAirBrushON = !eraseAirBrushON;
                setAirBrushCheckBox(eraseAirBrushON,false);
            }
        }

        private function makeSkipImage():void //loadrep
        {
            const fs:FileStream = new FileStream();
            const cd2:Graphics = rcanvas2Draw.graphics;
            const rf:File = repFile;
            const totalSize:Number = rf.size;
            const _IMG_CACHE_INTERVAL:uint = IMG_CACHE_INTERVAL;
            const replayInfoText:TextField = replayTimeBox["frameInfo"];
            var _frameSum:Number = 0;
            var _frameSumLast:Number = 0;
            var _rSkipImageCount:uint = 0;
            rSkipImageInit = 2;
            clearCanvasReplayMode();//일단 리플레이 캔버스 먼저 깨끗하게
            rcanvas1BitmapData = rFirstImage.clone(); 
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
            setPanelSizeReplayMode(rcanvas1BitmapData.width,rcanvas1BitmapData.height); //크기도 바꿔주고

            replayInfoText.text = "Reading replay data..";
            rFrame = 0;//꼭 해줘야함 이전 파일 리플레이에서 rframe이 0이 아닌상태가 있기 때문에 아래 while시작 초기화 없이 시작하면 에러남
            fs.open(rf,FileMode.READ);
            fs.position = 0;

            rregPoint.visible = false;

            const _doTickDraw:Function = doTickDraw;

            function onFrameEnter(e:Event):void
            {
                while(1)
                {
                    const namojiBytes:Number = fs.bytesAvailable;

                    if(namojiBytes === 0)
                    {
                        rFrame = 0;
                        stage.removeEventListener(Event.ENTER_FRAME,onFrameEnter);
                        fs.close();
                        rFileTotalFrame = _frameSum;
                        rSkipImageInit = 0;
                        rregPoint.visible = true;
                        replayInfoText.text = "Replay data is ready "+getReplayFileSize();
                        resetReplayTime();
                        TOTAL_FRAME = getTotalFrame();
                        rDataReadFlag = false;
                        setCenvasCenterPos(true,false);
                        checkCutFrameButtons();
                        rFrameSum = TOTAL_FRAME;
                        rFrameSumLast = _frameSumLast;
                        checkReplaySpeedState();

                        stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDownReplayModeEvent);
                        stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownReplayModeEvent);
                        stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownReplayModeEvent);
                        stage.addEventListener(KeyboardEvent.KEY_UP,keyUpReplayModeEvent);

                        return;
                    }
                    const d:Array = fs.readObject() as Array;
                    const dlen:Number = d.length;

                    rFrameArr = d;
                    _frameSumLast = _frameSum;
                    _frameSum += dlen;
                    _rSkipImageCount += dlen;
                    
                    for(var i:uint=0;i<dlen;i++)
                    {
                        _doTickDraw(false);
                    }

                    rFrame = 0;

                    if(_rSkipImageCount > _IMG_CACHE_INTERVAL)
                    {
                        rSkipImageFrameData.push(_frameSum); //순서 중요 skipimg:File변수보다 먼저 와야함

                        const perc:Number = Math.floor(((totalSize-namojiBytes)/totalSize)*100);
                        const fs3:FileStream = new FileStream();
                        const skipimg:File = rSkipImageFolder.resolvePath((rSkipImageFrameData.length-1)+".img");
                        const lastBytePos:Number = fs.position;
                        const imgData:ByteArray = new ByteArray();
                        const w:Number = rcanvas1BitmapData.width;
                        const h:Number = rcanvas1BitmapData.height;
                        const newRectangle:Rectangle = new Rectangle(0,0,w,h);

                        rcanvas1BitmapData.copyPixelsToByteArray(newRectangle,imgData);
                        fs3.open(skipimg,FileMode.WRITE);
                        fs3.writeObject([imgData,w,h,rBGColorSave,lastBytePos,_frameSum])//이미지 데이터,가로 세로, 배경색, 마지막 바이트 위치, 마지막 프레임 합
                        fs3.close();
                        imgData.clear();
                        _rSkipImageCount = 0;
                        replayInfoText.text = "Reading replay data.. "+perc+"%";
                        return;
                    }
                }
            }
            stage.addEventListener(Event.ENTER_FRAME,onFrameEnter);
        }

        private function saveReplayFile(imageSize:Number):void
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

                repFile.copyTo(repFileTemp,true);//일단 임시파일에다가 써줌
                fs.open(repFileTemp,FileMode.APPEND);

                var _readUndoArray:Array;
                for(var i:int=0,len:int=undoIndex;i<=len;i++)//리플레이 데이터랑 첫이미지 마지막 이미지 추가적으로 붙여줌
                {
                    _readUndoArray = _rData[i] as Array;
                    if(_readUndoArray.length === 0) continue;
                    fs.writeObject(_readUndoArray);
                }

                if(mirrorPushON) //임시 미러가 되어있을때 진짜 캔버스로 반전되어있는데 리플레이 데이터에는 아직 써주지 않았으니까 넣어줌
                {
                    const tempMirrorData:Array = [["mirror"]];
                    fs.writeObject(tempMirrorData);
                }

                fs.writeObject(["rFirstImage",rImgData,rImgDataW,rImgDataH,rFirstBGColor]);
                fs.writeObject(["rFinalImage",lastImgData,CANVAS_WIDTH,CANVAS_HEIGHT,CANVAS_BG_COLOR]);
                if(_traceBmpd)
                {
                    fs.writeObject(["traceImage",traceImgData,
                                                traceImgWidth, // 2
                                                traceImgHeight,// 3
                                                traceImgInfo[0],// 4
                                                traceImgInfo[1],// 5
                                                traceImgInfo[2],// 6
                                                traceImgInfo[3],// 7
                                                traceImgInfo[4],// 8
                                                traceImgInfo[5],// 9
                                                traceReizeMoveSum,//10
                                                CANVAS_TRACE_ALPHA] );// 11
                }
                fs.close();
                rImgData.clear();
                lastImgData.clear();

                const round:Function = Math.round;

                const rawrepSize:Number = repFileTemp.size;
                const repFileSize:Number = round(repFileTemp.size/1024);
                repFileTemp.moveTo(copyFile,true);//원래 목표했던 경로에 덮어쓰기 이동 덮어쓰기

                const imageFileSize:Number = round(imageSize/1024);
                const repFileSizeStr:String = (repFileSize > 1024) ? (repFileSize/1024).toFixed(1)+" MB": repFileSize.toFixed(1)+" KB";
                const imageFileSizeStr:String = (imageFileSize > 1024) ?  (imageFileSize/1024).toFixed(1)+" MB":imageFileSize.toFixed(1)+" KB";

                topBar.hintTimeOK("Saved *.2020 ("+repFileSizeStr+") *.png("+imageFileSizeStr+")");

            }
        }

        private function loadReplayFile(oldFile:File,fileName:String,filePath:String):void //loadrep
        {
            if(isTrue2020File(oldFile) === false) return;

            removeMainEvent();

            if(replayModeON)  setReplayUI(false);

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
            rSkipImageFrameData = [0];

            while(1)
            {
                if(fs.bytesAvailable === 0)
                {
                    break;
                }
                const d:Array = fs.readObject() as Array;

                if(d[0] === "rFirstImage") //리플레이 첫 이미지 파일
                {
                    const ba:ByteArray = d[1] as ByteArray;
                    newRectangle = new Rectangle(0,0,d[2],d[3]);
                    ba.uncompress();
                    rFirstImage = new BitmapData(d[2], d[3], true, 0);
                    rFirstImage.lock();
                    rFirstImage.setPixels(newRectangle,ba);
                    rFirstImage.unlock();
                    ba.clear();
                    const bgc:uint = d[4];

                    //r first img 업데이트 해줌
                    updateFirstImage(rFirstImage,bgc); //0.img 파일 갱신
                    rBGColorSave = bgc;
                }
                else if(d[0] === "rFinalImage")//최종 이미지
                {
                    const ba2:ByteArray = d[1] as ByteArray;
                    newRectangle = new Rectangle(0,0,d[2],d[3]);
                    ba2.uncompress();
                    errorFlag = false;
                    finalIMGBMPD = new BitmapData(d[2],d[3],true,0);
                    finalIMGBMPD.lock();
                    finalIMGBMPD.setPixels(newRectangle,ba2);
                    finalIMGBMPD.unlock();
                    ba2.clear();

                    imgW = d[2];
                    imgH = d[3];
                    bg = d[4];
                }
                else if(d[0] === "traceImage")
                {
                    const ba3:ByteArray = d[1] as ByteArray;
                    newRectangle = new Rectangle(0,0,d[2],d[3]);
                    ba3.uncompress();
                    traceRawBMPD = new BitmapData(d[2], d[3], true, 0);
                    traceRawBMPD.lock();
                    traceRawBMPD.setPixels(newRectangle,ba3);
                    traceRawBMPD.unlock();
                    d[0] = null;
                    d[1] = null;
                    traceRawArr = d.concat();
                }
                else
                {
                    imgStartByte = fs.position;
                }
            }

            fs.close();

            //이미지직전까지 바이트를 기준으로 짤라줌, 즉 뒤에 붙은 첫 이미지 + 마지막 이미지를 지워줌
            fs.open(repFileTemp,FileMode.UPDATE);
            fs.position = imgStartByte;
            fs.truncate();
            fs.close();

            repFileTemp.moveTo(repFile,true);
            rSkipImageInit = 1;
            loadFileAfter(fileName,filePath,imgW,imgH,finalIMGBMPD,false,bg);
            addMainEvent();
        }

        private function loadRawFileToReferenceLayer(file:File):void
        {
            if(isTrue2020File(file) === false)
            {
                topBar.hintTimeError("Load failed");
                return;
            }

            const fs:FileStream = new FileStream();
            var errorFlag:Boolean = true;
            fs.open(file,FileMode.READ);

            var finalIMGBMPD:BitmapData = new BitmapData(1,1,true,0);

            while(1)
            {
                if(fs.bytesAvailable === 0)
                {
                    break;
                }
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
            rFileTotalFrame = 0;
            rSkipImageInit = 0;
            traceRawBMPD = null;
            traceRawArr = null;
            loadFileAfter(fileName,filePath,width,height,imageData,true);
            resetReplayDataFile(true); //일단 썸네일 이미지랑 리플레이 데이터 청소
        }

        private function loadFileAfter(fileName:String,filePath:String, width:uint,height:uint,imageData:IBitmapDrawable,cloneFlag:Boolean,newBG:uint=0xFFFFFF):void
        {
            if(!imageData)
            {
                topBar.hintTimeError("Load failed");
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

            setBackgroundColor(newBG);
            setBackgroundColor(newBG,true);

            if(is2020Ext(fileName) === true)
            {
                fileName = fileName.substr(0,fileName.lastIndexOf(".2020"))+".png";
                filePath = filePath.substr(0,filePath.lastIndexOf(".2020"))+".png";
            }

            saveFileName = fileName;
            saveFilePath = filePath;
            saveContinue = false;//연속 세이브 플래그 취소
            mirrorON = false;
            mirrorPushON = false;
            clearButtonClicked = false;
            resetUndo();

            if(lassoToolON === true)
            {
                setLassoCancelButton();
                resetLassoBox();
            }

            if(fillPenStarted)
            {
                setFillPenTool.cancel();
            }

            rTinyCursorPos = [];
            tmpBMPD.draw(imageData,scaleMat,null,null,null,true);
            canvas1BitmapData = tmpBMPD.clone();
            canvas1Bitmap.bitmapData = canvas1BitmapData;
            setPanelSize(scaledwidth,scaledheight,0,0,false);
            if(cloneFlag) rFirstImage = tmpBMPD.clone();

            tmpBMPD.dispose();
            tmpBMPD = null;
            regPoint.rotation = 0;
            zoomedIndex = 3;
            setZoomCanvas(1.0);
            if(traceRawArr === null)
            {
                clearTraceImage();
            }
            else
            {
                const tArr:Array = traceRawArr;
                canvasTraceBitmapData = traceRawBMPD.clone();
                canvasTraceBitmap.bitmapData = canvasTraceBitmapData;
                setTraceImageInfo(  true,
                                    tArr[4],
                                    tArr[5],
                                    tArr[6],
                                    tArr[7],
                                    tArr[8],
                                    tArr[9]
                                );
                traceReizeMoveSum = tArr[10];
                CANVAS_TRACE_ALPHA = tArr[11];
                canvasTrace.alpha = tArr[11];
                updateTraceOpaButtonPosByAlpha(tArr[11]);
                traceRawBMPD.dispose();
                traceRawBMPD = null;
                traceRawArr = null;
                canvasTraceBitmap.smoothing = true;
            }
            setCenvasCenterPos();
            updateResizeButtonPos();
            addUndoData();
            updateWindowTitle();
            setWindowTitleStar();
            setSubLayer(false);
            setReplaySubLayer(false);
        }

        private function loadFile(subLayer:Boolean=false):void
        {
            if(replayStartON)
            {
                stopReplay();
            }

            if(lassoToolON || browseWindowON || fillPenStarted) return;

            var newFileFilter:FileFilter = new FileFilter("Image or 2020 file", "*.2020;*.png;*.jpg;*.gif");
            var windowTitle:String = "Open file";
            var imgExt:Array = [newFileFilter];

            if(subLayer === true)
            {
                newFileFilter = new FileFilter("Image file", "*.2020;*.png;*.jpg;*.gif");
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
                if(subLayer === true)
                {
                    pasteTraceImage(loaderInfo.loader,loaderInfo.width,loaderInfo.height);
                }
                else
                {
                    loadImageFile(file.name,file.nativePath,loaderInfo.width,loaderInfo.height,loaderInfo.loader);
                }

                loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR,loadErrorEvent);
                loader.contentLoaderInfo.removeEventListener(Event.COMPLETE,loadFileCompleteEvent);
                loader.unload();
                loader = null;
            }

            function loadErrorEvent(e:Event):void
            {
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
                    if(subLayer === true)
                    {
                        loadRawFileToReferenceLayer(file);
                    }
                    else
                    {
                        loadReplayFile(file,file.name,file.nativePath);
                    }
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

            resetKeyBuffer();
            canvasGrid.visible = iFlag;

            if(replayMode)
            {
                resetCutFrameClickCounter();
                topBar.hintOFF();
                replayTimeBox.visible = iFlag;
            }
            else
            {
                resizeButtonR.visible = iFlag;
                resizeButtonL.visible = iFlag;
                resizeButtonD.visible = iFlag;
                resizeButtonU.visible = iFlag;
            }

            if(flag === true)
            {
                sideBar.visible = false;
                topBar.resetHintColor();
                penSizeCursor.visible = false;
                canvasTrace.visible = false;

                if(traceMenuON === true)
                {
                    traceMenuBox.visible = false;
                }
                changeTopBarIcons("capture");
            }
            else 
            {
                canvasTrace.visible = true;
                appInfoBox.updateCanvasInfo();

                if(replayMode)
                {
                    changeTopBarIcons("replay");
                }
                else
                {
                    if(isSidebarVisible === true)
                        sideBar.visible = true;

                    if(traceMenuON === true)
                        traceMenuBox.visible = true;

                    changeTopBarIcons("draw");
                }

                changePickerModeToNormal();
            }
        }

        //캡쳐영역 그리기 시작전에 설정 세팅해줌
        private function captureKeyUpEvent(e:KeyboardEvent):void
        {
            if(e.keyCode === gKey.s)
            {
                fullCaptureReady = true;
            }
        }

        private function captureKeydownEvent(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;

            if(keyCode == gKey.s || keyCode == gKey.k)
            {
                if(e.altKey && fullCaptureReady)
                {
                    setFullCaptrueButton();
                }
                else
                {
                    setCaptureRotateButton();
                }
            }
            else if(keyCode === gKey.a || keyCode == gKey.l)
            {
                setCaptrueFlipButton();
            }
            else if(keyCode === gKey.d || keyCode === gKey.j)
            {
                setCaptureTransButton();
            }
            else if(e.keyCode === gKey.esc)
            {
                setCaptureOFFButton(true);
            }
        }

        private function captureMouseMoveHintEvent(e:MouseEvent):void
        {
            if(!captureModeON)
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,captureMouseMoveHintEvent);
                return;
            }
            const cursor:Shape = xcapturePreviewCursor;
            const xPanel:Sprite = (replayModeON) ? rcanvasPanel:canvasPanel;

            cursor.x = xPanel.mouseX;
            cursor.y = xPanel.mouseY;
        }

        private function setCaptureReady():void
        {
            if(captureModeON)
            {
                return;
            }

            if(replayStartON)
            {
                stopReplay();
            }

            captureModeON = true;
            penCursorOFFFlag = true;
            stage.addEventListener(MouseEvent.MOUSE_MOVE,captureMouseMoveHintEvent);
            stage.addEventListener(KeyboardEvent.KEY_DOWN,captureKeydownEvent);
            stage.addEventListener(KeyboardEvent.KEY_UP,captureKeyUpEvent);

            removeKeyEvent();

            setCaptureUI(true);
            captureRotated = 0;
            captureFlipped = false;
            // captureTransBGON = false;

            const floor:Function = Math.floor;
            var xCaptureRect:Shape = capturePreviewRect;
            var xReg:Sprite = regPoint
            var xPanel:Sprite = canvasPanel;
            var xZoomed:Number = zoomed;

            if(replayModeON)
            {
                xCaptureRect = rcapturePreviewRect;
                xReg = rregPoint;
                xPanel = rcanvasPanel;
                xZoomed = rzoomed;
                rCursor.visible = false;
            }

            setTopChildIndex(xCaptureRect);
            xCaptureRect.visible = true;

            capturePanelData = {
                                    "z" : xZoomed,
                                    "x" : floor(xReg.x), //뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
                                    "y" : floor(xReg.y),
                                    "r" : xReg.rotation,
                                    "px" : floor(xPanel.x),
                                    "py" : floor(xPanel.y)
                                }

            canvasFitWindow(true);

            const cursor:Shape = xcapturePreviewCursor;
            cursor.x = xPanel.mouseX;
            cursor.y = xPanel.mouseY;

            captureTransBGON = true;
            setCaptureTransButton();
            resetTransBG(false);
        }


        private function setCaptureModeOFF(replayMode:Boolean,xReg:Sprite,xPanel:Sprite,xCaptureRect:Shape):void
        {
            const data:Object = capturePanelData;
            const xBitmap:Bitmap = (replayMode) ? rcanvas1Bitmap : canvas1Bitmap;

            xBitmap.smoothing = false;

            captureModeON = false;
            penCursorOFFFlag = false;
            xCaptureRect.graphics.clear();
            xCaptureRect.visible = false;
            xcapturePreviewCursor.visible = false;

            setCaptureUI(false);

            //캔버스 이전 모양 위치로 복원
            xReg.rotation = data.r;
            xReg.x = data.x + captureWindowMove[0];
            xReg.y = data.y + captureWindowMove[1];
            xPanel.x = data.px;
            xPanel.y = data.py;

            setZoomCanvas(data.z,replayMode);
            toolTipBox.visible = false;
            captureWindowMove = [0,0];

            updatePenSizeCursor();

            if(replayMode)
            {
                resetTransBG(true);
                rCursor.visible = true;
            }
            else if(!replayMode)
            {
                resetTransBG(false);
                updateResizeButtonPos();
                addKeyEvent();
            }

            drawCaptureArea.reset();
            checkCanvasPanelPos(replayMode);
        }

        //마우스 클릭하면 캡쳐 영역그리는 함수
        private function closureDrawCaptureArea():Object
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

            function captureMouseMove(e:MouseEvent):void
            {
                if(limitMouseMoveEventTime() === true)
                {
                    return;
                }

                if(!captureModeON)
                {
                    stage.removeEventListener(MouseEvent.MOUSE_MOVE,captureMouseMove);
                    stage.removeEventListener(MouseEvent.MOUSE_UP,captureMouseUp);
                }

                const g:Graphics = xCaptureRect.graphics;
                var ww:Number = xPanel.mouseX-cx;
                var hh:Number = xPanel.mouseY-cy;

                if(ww < -cx) 
                {
                    ww = -cx;
                }
                else if(ww > canvasWidth-cx) 
                {
                    ww = canvasWidth-cx;
                }

                if(hh < -cy) 
                {
                    hh = -cy;
                }
                else if(hh > canvasHeight-cy) 
                {
                    hh = canvasHeight-cy;
                }

                ww = floor(ww+0.5);
                hh = floor(hh+0.5);

                if(abs(ww) > 10 && abs(hh) > 10)
                {
                    const zoomed:Number = (replayModeON) ? rregPoint.scaleX : regPoint.scaleX;
                    const lineSize:Number = Math.ceil(2/zoomed);
                    
                    rectW = ww;
                    rectH = hh;

                    g.clear();
                    g.lineStyle(lineSize,0x0099FF,1.0,true);
                    g.drawRect(cx,cy,ww,hh);

                    setToolTipString(getRotatedRectSizeString());
                    toolTipBox.visible = true;
                    mouseMoved = true;
                }
            }

            function getRotatedRectSizeString():String
            {
                return (captureRotated === 0 || captureRotated === 2) ? abs(rectW)+" x "+abs(rectH)
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
            }

            function captureMouseUp(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,captureMouseMove);
                stage.removeEventListener(MouseEvent.MOUSE_UP,captureMouseUp);

                xcapturePreviewCursor.visible = true;

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
                    changeToolTipString(getRotatedRectSizeString()+" (Click canvas to save again)")
                    
                    saveCaptureImage(cx,cy,rectW,rectH);
                }
                else if(abs(rectW) > 10 && abs(rectH) > 10)
                {
                    saveCaptureImage(rectX,rectY,rectW,rectH);
                }

                mouseMoved = false;
            }

            function start (replayMode:Boolean):void
            {
                if(replayMode) //리플레이 변수로 변경
                {
                    canvasWidth = RCANVAS_WIDTH;
                    canvasHeight = RCANVAS_HEIGHT;
                    xCaptureRect = rcapturePreviewRect;
                    xReg = rregPoint;
                    xPanel = rcanvasPanel;
                }
                else
                {
                    canvasWidth = CANVAS_WIDTH;
                    canvasHeight = CANVAS_HEIGHT;
                    xCaptureRect = capturePreviewRect;
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

                stage.addEventListener(MouseEvent.MOUSE_MOVE,captureMouseMove);
                stage.addEventListener(MouseEvent.MOUSE_UP,captureMouseUp);
            };

            return {
                start:start,
                reset:reset,
                getRotatedRectSizeString:getRotatedRectSizeString
            };
        }

        private function getRandomString(count:int):String
        {
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
            const set:Array = str.split(/_\d{8}_\d{6}/g);
            const len:int = set.length;

            if(len === 0)
            {
                return str;
            }
            else if(len === 1)
            {
                return set[0];
            }

            var newStr:String = set[0];

            for(var i:int=1;i<len;i++)
            {
                if(set[i].length > 0)
                {
                    newStr += set[i];
                }
            }

            return newStr;
        }

        private function getTimeStamp():String
        {
            const date:Date = new Date();
            const y:Number = date.getFullYear();
            const m:Number = date.getMonth()+1;
            const d:Number = date.getDate();
            const hour:Number = date.getHours();
            const min:Number = date.getMinutes();
            const sec:Number = date.getSeconds();
            const daystr:String = (d < 10) ? "0"+d : ""+d;
            const monthstr:String = (m < 10) ? "0"+m : ""+m;
            const hourstr:String = (hour < 10) ? "0"+hour : ""+hour;
            const minstr:String = (min < 10) ? "0"+min : ""+min;
            const secstr:String = (sec < 10) ? "0"+sec : ""+sec;
            const timeStr:String = ""+y+monthstr+daystr+"_"+hourstr+minstr+secstr;

            return timeStr;
        }

        private function saveCaptureImage(cx:Number,cy:Number,rectW:Number,rectH:Number):void
        {
            if(browseWindowON)
            {
                return;
            }

            const replayMode:Boolean = replayModeON;
            var name:String = saveFileName;
            var path:String = saveFilePath;
            const firstSaveFlag:Boolean = (name !== path);
            
            browseWindowON = true;

            name = cutTimeStamp(name);
            name = name.substr(0,name.lastIndexOf(".png"))+"_"+getTimeStamp()+".png";//뒤에 프레임 번호 붙여줌
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
            var imageSize:Number;

            // checkUsedMemory();
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
                    imageSize = byteArray.length;

                    fs.addEventListener(IOErrorEvent.IO_ERROR, saveContinueErrorEvent);
                    fs.openAsync(normalFile,FileMode.WRITE);
                    fs.writeBytes(byteArray);
                    fs.close();

                    byteArray.clear();
                    saveReplayFile(imageSize);
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
                if(browseWindowON)
                {
                    return;
                }

                var _path:String = saveFilePath;
                var _name:String = saveFileName;
                const firstSaveFlag:Boolean = (_name !== _path);

                if(saveFailed)
                {
                    _path = _path.substr(0,_path.lastIndexOf(".png"))+"_new.png";
                    _name = _name.substr(0,_name.lastIndexOf(".png"))+"_new.png";
                }

                var file:File = (_name !== _path) ? new File(_path) : File.desktopDirectory.resolvePath(_name);
                var saveWindowTitle:String = (asFlag === true) ? "Save file As..":"Save file";

                if(saveFailed)
                {
                    saveWindowTitle = "Save failed: try saving with a new name ..";
                }

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
                    imageSize = byteArray.length;

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
                    fs.open(f1,FileMode.WRITE);
                    fs.writeBytes(byteArray);
                    fs.close();

                    byteArray.clear();
                    updateWindowTitle();
                    saveReplayFile(imageSize);
                }
            }
        }

        private function saveReplayFrameData():void
        {
            const fs:FileStream = new FileStream();
            fs.open(rSkipImageFrameDataFile,FileMode.WRITE);
            fs.writeObject(rSkipImageFrameData);
            fs.close();
        }

        private function loadUndoData():void
        {
            if(undoDataFile.exists === false)
            {
                return;
            }

            const fs:FileStream = new FileStream();
            fs.open(undoDataFile,FileMode.READ);
            const lastUndoIndex:uint = fs.readUnsignedInt();
            undoIndex = lastUndoIndex;
            var arr:Array = fs.readObject() as Array;
            const len:uint = arr.length;
            var newRectangle:Rectangle;
			
            for(var i:uint=0;i<len;i++)
            {
                const a:Array = arr[i] as Array;
                const bmpd:BitmapData = new BitmapData(a[2],a[3],true,0);

                newRectangle = new Rectangle(0,0,a[2],a[3]);
                // a[0].uncompress();
                bmpd.lock();
                bmpd.setPixels(newRectangle,a[0]);
                bmpd.unlock();
                a[0] = bmpd.clone();

                if(i === lastUndoIndex)
                {
                    canvas1BitmapData = a[0].clone();
                    canvas1Bitmap.bitmapData = canvas1BitmapData;
                    //canvas1Bitmap.smoothing = true;
                    mirrorON = a[1]; //mirrorPushON할 필요 없음

                    const w:uint = a[2];
                    const h:uint = a[3];
                    const bg:uint = a[4];

                    setBackgroundColor(bg);
                    setBackgroundColor(bg,true);
                    setPanelSize(w,h,0,0,false);
                    setPanelSizeReplayMode(w,h);

                    addUndoMode = 0;
                }
                bmpd.dispose();
            }
            //undo index가 arr의 가장 마지막 부분이 아니면 undo를 하던 중이니까 undoDelFlag 켜줌
            if(lastUndoIndex < arr.length-1)
            {
                undoDelFlag = true;
            }
            else 
            {
                undoDelFlag = false;
            }

            const arr1:Array = fs.readObject() as Array;
            const arr2:Array = fs.readObject() as Array;

            fs.close();

            undoData = arr.concat();
            rData = arr1.concat();
            rDataFrame = arr2.concat();
        }

        private function saveUndoData():void
        {
            const fs:FileStream = new FileStream();
            const arr:Array = undoData;
            var newArr:Array = [];
            var newRectangle:Rectangle;

            for(var i:uint=0,len:uint=arr.length;i<len;i++)
            {
                const ba:ByteArray = new ByteArray();
                const u:Array = arr[i] as Array;

                newRectangle = new Rectangle(0,0,u[2],u[3]);
                u[0].copyPixelsToByteArray(newRectangle,ba);
                // ba.compress();
                newArr.push([ba,u[1],u[2],u[3],u[4]]);
            }

            fs.open(undoDataFile,FileMode.WRITE);
            fs.writeUnsignedInt(undoIndex);
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
                            "rFileTotalFrame":rFileTotalFrame,
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
                            "rSkipImageInit":rSkipImageInit,
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

            if(rFirstImageFile.exists === true)
            {
                fs.open(rFirstImageFile, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();
                newRectangle = new Rectangle(0,0,arr[1],arr[2]);
                rFirstImage = new BitmapData(arr[1], arr[2], true, 0);
                rFirstImage.lock();
                rFirstImage.setPixels(newRectangle,arr[0]);
                rFirstImage.unlock();
                rFirstBGColor = arr[3];
            }
            else
            {
                rFirstImage = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
            }

            if(traceImageFile.exists === true) //저장한 trace 이미지 복원
            {
                fs.open(traceImageFile, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();
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

            if(rSkipImageFrameDataFile.exists === true)
            {
                fs.open(rSkipImageFrameDataFile,FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();
                rSkipImageFrameData = arr.concat();
            }

            if(appDataFile.exists === true)
            {
                fs.open(appDataFile, FileMode.READ);
                const d:Object = fs.readObject();
                fs.close();

                //loadUndoData함수에서 canvaspanel이 호출되는데 이전에 trace이미지 정보값을 넣어두어야함
                loadUndoData();//undo data 복구 먼저 해줌
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
                    rFileTotalFrame = d["rFileTotalFrame"];
                    saveFileName = saveFilePath = d["saveFileName"];
                    colorHistoryList = d["colorHistoryList"] as Array;
                    APP_RUNNING_TIME = d["APP_RUNNING_TIME"];
                    updateWorkingTime();
                    CANVAS_TRACE_ALPHA = d["CANVAS_TRACE_ALPHA"]
                    canvasTrace.alpha = d["CANVAS_TRACE_ALPHA"];
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
                    rSkipImageInit = d["rSkipImageInit"];
                    rBGColorSave = d["rBGColorSave"];
                    saveFilePath = d["saveFilePath"];

                    setTraceImageInfo(true, d["tracePosInfo[0]"],
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
                    setCenvasCenterPos(true);
                    checkCanvasPanelPos();
                    checkCanvasPanelPos(true);
                    updateResizeButtonPos();
                    updateColorHistoryList();
                    updatePreviewCursorPos();
                    appInfoBox.insertCanvasInfo([null,null,null,regPoint.rotation,null]);
                    updatePenSizeCursor();
                },150);
            }
            else //복원파일이 없을때
            {
                lastWindowSize.x = 680;
                lastWindowSize.y = 768;
                _nativeWindow.width = lastWindowSize.x;
                _nativeWindow.height = lastWindowSize.y;

                setPenSize(penSizeIndex);
                setPanelSize(CANVAS_WIDTH,CANVAS_HEIGHT,0,0,false);
                setHSVCursorPosByColor(penColor);
                addUndoData();
                openAboutPanel(1);

                setUIColor(uiColorIndex);
                updatePreviewCursorPos();
                updateWindowSizeInfo();
                appInfoBox.insertCanvasInfo([CANVAS_WIDTH,CANVAS_HEIGHT,zoomed*100,regPoint.rotation]);
                updatePenSizeCursor();
            }

            updateWindowTitle();
            setWindowTitleStar();
        }

        //빈 stage공백에 광클하면 쓸데없는 addundo가 되서
        //캔버스를 클릭했거나, 펜사이즈가 캔버스에 걸치면 addundo가 되게 예약해줌
        private function closureCheckUndoReady():Function
        {
            return function ():void
            {
                if(penSizeCursor.hitTestObject(canvas1Bitmap))
                {
                    if(readyAddUndo === false)
                    {
                        setWindowTitleStar();
                    }
                    clearButtonClicked = false; //undo추가 예약되어있으면 그때 꺼줌
                    readyAddUndo = true;
                }
            };
        }

        //size, size drag, zoom, rotate시 업데이트 해줌
        private function closureUpdatePenSizeCursor():Function
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

                if(zSize < 8)
                {
                    _penSizeCursor.visible = false;
                    return;
                }

                _penSizeCursor.x = mouseX;
                _penSizeCursor.y = mouseY;
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
            canvas2BitmapData.draw(canvas2Draw);
            canvas2Bitmap.bitmapData = canvas2BitmapData;

            if(isPenTool() || nowTool === TOOL_FILL_PEN)
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

        private function closureLineTool():Function
        {
            const floor:Function = Math.floor;
            const abs:Function = Math.abs;
            const atan2:Function = Math.atan2;
            const toDeg:Number = 180/Math.PI;
            const cd:Shape = canvas2Draw;

            var _traceMemoryTraining:Boolean;
            var xSize:uint;
            var xColor:uint;
            var xAlpha:Number;
            var xShape:Boolean;
            var xBlendMode:String;
            var _airBrushON:Boolean;
            var xOffset:Number;
            var mouseMovedFlag:Boolean;
            var oldX:Number;
            var oldY:Number;
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

                cdg.moveTo(oldX+xOffset,oldY+xOffset);
                cdg.lineTo(mx,my);

                const ang:Number = atan2(oldX-cd.mouseX,oldY-cd.mouseY);
                var deg:Number = ang*toDeg+90;
                if(deg > 180)
                {
                    deg = deg-90;
                }

                var degstr:String = abs(deg % 90).toFixed(1)+"°";
                setToolTipString(degstr);
                toolTipBox.visible = true;

                const rad:Number = Math.atan2(oldX+xOffset-mx,oldY+xOffset-my);
                const cursorDeg:Number = -rad*(180/Math.PI)+regPoint.rotation;
                penSizeCursor.rotation = cursorDeg;
            }

            function lineMoveEvent(e:MouseEvent):void
            {
                if(limitMouseMoveEventTime() === true)
                {
                    return;
                }

                if(!mouseMovedFlag)
                {
                    mouseDragON = true;
                    mouseMovedFlag = true;
                }

                drawingLine();

                if(readyAddUndo === false) checkUndoReady();
            }

            function lineUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, lineMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP, lineUpEvent);

                if(_traceMemoryTraining)
                {
                    canvasTrace.visible = true;
                }

                mouseDragON = false;

                const x:Number = cd.mouseX;
                const y:Number = cd.mouseY;
                const cx:Number = oldX;
                const cy:Number = oldY;
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

                if(readyAddUndo === false)
                {
                    checkUndoReady();
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
                _airBrushON = airBrushON;

                xOffset = (sizeOffsetFlag) ? 0.5 : 0;

                mouseMovedFlag = false;
                oldX = cd.mouseX;
                oldY = cd.mouseY;
                subLayerFlag = subLayerON

                if(_traceMemoryTraining)
                {
                    canvasTrace.visible = false;
                }
                
                //캔버스2번 지워주고, draw판넬 데이터도 지워줌
                canvas2BitmapData.dispose();
                canvas2Bitmap.bitmapData = null;
                canvas2BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);

                checkUndoReady();

                //선 관련 이벤트 함수 붙여줌
                stage.addEventListener(MouseEvent.MOUSE_MOVE,lineMoveEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,lineUpEvent);
            };
        }

        private function closureRotateTool():Function
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
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, rotateToolMoveEvent);

                mouseDragON = false;
                penCursorOFFFlag = false;
                // xBitmap.smoothing = true;

                if(!_replayMode)
                {                    
                    if(lassoMenuTempOFF === true)
                    {
                        nowTool = TOOL_LASSO;
                        checkLassoMenuPos();
                        lassoMenuTempOFF = false;
                        lassoMenu.visible = true;
                    }

                    updatePenSizeCursor();
                    setOptimizeCanvasMove(false);
                    updatePreviewCursorPos();
                }
                else
                {
                    rNowKey = 0;
                    updateReplayCanvasBounds();
                }

                _rotateCursorBox.visible = false;
                checkCanvasPanelPos(_replayMode);
            }

            function rotateToolMoveEvent(e:MouseEvent):void
            {
                if(limitMouseMoveEventTime() === true) return;
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
                appInfoBox.insertCanvasInfo([null,null,null,xReg.rotation]);
            }

            return function (replayMode:Boolean=false):void
            {
                _replayMode = replayMode;
                xReg = (!replayMode) ? regPoint:rregPoint;
                xBitmap = (!replayMode) ? canvas1Bitmap : rcanvas1Bitmap;

                // var PI2:Number = PI*2;
                //각도 차이 구하기 위해서 넣어줌, 초기 값은 마우스 클릭한 위치의 각도값 
                lastAng = 0;
                //움직인 각도합 로테이트 캔버스 마지막각도를 넣어줌 rad로 변환
                sumAng = xReg.rotation*PI/180;
                center = getStageCenterPos(false,replayMode);
                rotateCenterX = center.x;
                rotateCenterY = center.y;

                mouseDragON = true;
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

                stage.addEventListener(MouseEvent.MOUSE_MOVE, rotateToolMoveEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP, rotateToolUpEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, rotateToolUpEvent);
            };
        }

        private function closureMoveTool():Function
        {
            var lassoFirstX:Number = lassoBox.x;
            var lassoFirstY:Number = lassoBox.y;
            var oldX:Number = mouseX;
            var oldY:Number = mouseY;
            var z:Number = zoomed;

            function moveToolOFFEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, moveToolMoveEvent);
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
                if(limitMouseMoveEventTime() === true) return;
                const dx:Number = mouseX-oldX;
                const dy:Number = mouseY-oldY;
                const rPos:Point = rotatePoint(dx,dy,regPoint.rotation);

                if(lassoToolON === true)
                {
                    lassoBox.x = lassoFirstX + rPos.x/z; //캔버스만 옮겨줘서 미리보기해줌
                    lassoBox.y = lassoFirstY + rPos.y/z;
                }
                canvas1.x = rPos.x/z; //캔버스만 옮겨줘서 미리보기해줌
                canvas1.y = rPos.y/z;
            }

            return function ():void
            {
                lassoFirstX = lassoBox.x;
                lassoFirstY = lassoBox.y;
                oldX = mouseX;
                oldY = mouseY;
                z = zoomed;

                mouseDragON = true;
                penCursorOFFFlag = true;

                stage.addEventListener(MouseEvent.MOUSE_MOVE, moveToolMoveEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, moveToolOFFEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP, moveToolOFFEvent);
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

        private function closureZoomTool():Function
        {
            const _zoomArr:Array = zoomArr;
            const _zoomArrLen:uint = _zoomArr.length;
            const zoomMin:Number = _zoomArr[0];
            const zoomMax:Number = _zoomArr[_zoomArrLen-1];
            const mouseMoveStep:int = 37; //이 픽셀이상움직일때만 zoomcanvas를 실행
            const zoomUnit:Number = 1.0;// 0.25;//한 스탭당 얼마나 줌할것인지

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
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, zoomToolMouseMoveEvent);

                zoomToolHintON = false;
                mouseDragON = false;
                penCursorOFFFlag = false;
                // toolTipBox.visible = false;

                updatePenSizeCursor();
                updateResizeButtonPos();
                setOptimizeCanvasMove(false);

                if(lassoMenuTempOFF === true)
                {
                    nowTool = TOOL_LASSO;
                    checkLassoMenuPos();
                    lassoMenuTempOFF = false;
                    lassoMenu.visible = true;
                }

                updatePreviewCursorPos();
            }

            function zoomGoArray(index:uint):void
            {
                const newZoom:Number = _zoomArr[index];
                const textZoom:uint = Math.ceil(newZoom*100);

                setZoomCanvas(newZoom,false);
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

                if(zoomedIndex < 0)
                {
                    zoomedIndex = 0
                }
                else if(zoomedIndex > _zoomArrLen-1)
                {
                    zoomedIndex = _zoomArrLen-1;
                }

                zoomGoArray(zoomedIndex);
            }

            function zoomToolMouseMoveEvent(e:MouseEvent):void
            {
                if(limitMouseMoveEventTime() === true) return;
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

            return function ():void
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
                mouseDragON = true;
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

                if(zoomClickX < 0) 
                {
                    zoomClickX = 0;
                }
                else if(zoomClickX > maxWidth) 
                {
                    zoomClickX = maxWidth;
                }

                if(zoomClickY < 0) 
                {
                    zoomClickY = 0;
                }
                else if(zoomClickY > maxHeight) 
                {
                    zoomClickY = maxHeight;
                }

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

                stage.addEventListener(MouseEvent.MOUSE_MOVE,zoomToolMouseMoveEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, zoomToolMouseUpEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP, zoomToolMouseUpEvent);
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
            mirrorPushON = !mirrorPushON;
            mirrorDraw();

            //회전각 부호를 바꿔야 제대로 mirror가됨
            setRegPoint(p.x,p.y);//regpoint를 회전한 캔버스 중점으로 두고
            if(canvasOnly === false) //보통 미러할때, canvasonly가 true일때는 appdata에서 바꿔줄때 밖에 없음
            {
                regPoint.rotation = -regPoint.rotation;//반대각으로 세팅
                canvasTrace.scaleX = -canvasTrace.scaleX;
                canvasTrace.rotation = -canvasTrace.rotation;
                _traceInfo[2] = canvasTrace.rotation;
                _traceInfo[3] = canvasTrace.scaleX;
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
            updatePreviewCursorPos();
            saveOneTime = false; //미러도 화면이 바뀌기 때문에 세이브 플래그 꺼줌
        }

        private function setPanelSizeReplayMode(w:Number,h:Number,moveX:Number=0,moveY:Number=0,movedFlag:Boolean=false):void
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
            else
            {
                rcanvas1BitmapData.draw(rcanvas1Bitmap);
            }
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
            // rcanvas1Bitmap.smoothing = true;

            updateReplayCanvasBounds();
            checkCanvasPanelPos(true);
        }

        private function setPanelSize(w:Number,h:Number,moveX:Number=0,moveY:Number=0,undoFlag:Boolean=true,movedFlag:Boolean=false):void
        {
            const cg:Graphics = canvasPanel.graphics;
            const maskg:Graphics = canvasPanelMask.graphics;
            const maxSize:uint = CANVAS_MAX_SIZE;
            const bgColor:uint = CANVAS_BG_COLOR;
            const _canvasTrace:Sprite = canvasTrace;
            const _canvasTraceBitmap:Bitmap = canvasTraceBitmap;

            if(w > maxSize) 
            {
                w = maxSize;
            }
            else if(w < 1)
            {
                w = 1;
            }

            if(h > maxSize) 
            {
                h = maxSize;
            }
            else if(h < 1) 
            {
                h = 1;
            }

            cg.clear();
            cg.beginFill(bgColor);
            cg.drawRect(0,0,w,h);
            cg.endFill();

            maskg.clear();
            maskg.beginFill(bgColor);//paneldraw마스크 아무색이나 상관없음 어차피 마스크로 쓸거라
            maskg.drawRect(0, 0, w, h);
            maskg.endFill();
            canvasPanel.mask = canvasPanelMask;//마스크 다시 씌워줌

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
            else
            {
                canvas1BitmapData.draw(canvas1Bitmap);
            }
            canvas1Bitmap.bitmapData = canvas1BitmapData;
            //canvas1Bitmap.smoothing = true;

            const subW:Number = (CANVAS_WIDTH-w)/2;
            const subH:Number = (CANVAS_HEIGHT-h)/2;
            const rPos:Point = rotatePoint(subW,subH,canvasTrace.rotation);
            const sc:Number = tracePosInfo[3];

            _canvasTrace.x = w/2;
            _canvasTrace.y = h/2;

            if(movedFlag)
            {
                _canvasTraceBitmap.x += -rPos.x/sc;
                _canvasTraceBitmap.y += -rPos.y/sc;
            }
            else
            {
                _canvasTraceBitmap.x += rPos.x/sc;
                _canvasTraceBitmap.y += rPos.y/sc;
            }

            tracePosInfo[0] = _canvasTraceBitmap.x;
            tracePosInfo[1] = _canvasTraceBitmap.y;

            CANVAS_WIDTH = w;//undo보다 먼저 해줘야함
            CANVAS_HEIGHT = h;

            //이거 캔버스 움직일때 갱신해줘야함
            //undo 함수 에서 사이즈 변경할때는 addundo하지 않음
            if(undoFlag === true)
            {
                clearButtonClicked = false;
                rDataBuffer.push(["canvasSize",w,h,moveX,moveY,movedFlag]);
                addUndoData(2);
            }
            checkCanvasPanelPos();
            updateResizeButtonPos();
            drawGrid();

            const _appInfoBox:appInfoBar = appInfoBox;
            _appInfoBox.insertCanvasInfo([w,h,null,null]);
        }

        private function setCanvasSize(targetName:String):void
        {
            const w:Number = CANVAS_WIDTH;
            const h:Number = CANVAS_HEIGHT;
            const minL:int = CANVAS_MIN_SIZE;
            const maxL:int = CANVAS_MAX_SIZE;
            const bgColor:uint = CANVAS_BG_COLOR;
            const stageColor:uint = STAGE_BG_COLOR;

            const resizeClickPosX:Number = canvasPanel.mouseX;
            const resizeClickPosY:Number = canvasPanel.mouseY;
            var finalWidth:uint = 0;
            var finalHeight:uint = 0;
            var movedX:int = 0;
            var movedY:int = 0;

            function resizeButtonMouseUpEvent(e:MouseEvent):void
            {
                toolTipBox.visible = false;
                penCursorOFFFlag = false;

                reiszePreviewRect.graphics.clear();
                reiszePreviewRect.visible = false;
                regPoint.removeChild(reiszePreviewRect);

                stage.removeEventListener(MouseEvent.MOUSE_UP,resizeButtonMouseUpEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,resizeButtonMouseUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,resizeButtonMouseMoveEvent);

                setResizeButtonVisible(true);

                if(movedX === 0 && movedY === 0)
                {
                    //변경되지 않았으면 그냥 리턴
                    return;
                }

                const centerMoved:Boolean = (targetName === "resizeButtonL" || targetName === "resizeButtonU") ? true:false;
                setPanelSize(finalWidth,finalHeight,movedX,movedY,true,centerMoved);

            }

            function resizeButtonMouseMoveEvent(e:MouseEvent):void
            {
                const oPointX:Number = canvasPanel.x;
                const oPointY:Number = canvasPanel.y;
                const mx:Number = mouseX;
                const my:Number = mouseY;
                const resizeg:Graphics = reiszePreviewRect.graphics;
                var edgePoint:Number;

                var subX:int = (targetName === "resizeButtonR")  ? canvasPanel.mouseX-resizeClickPosX:
                               (targetName === "resizeButtonL") ? resizeClickPosX-canvasPanel.mouseX: 0;
                var subY:int = (targetName === "resizeButtonD")  ? canvasPanel.mouseY-resizeClickPosY:
                               (targetName === "resizeButtonU") ? resizeClickPosY-canvasPanel.mouseY: 0;

                finalWidth = (w+subX < minL) ? minL:
                           (w+subX > maxL) ? maxL:w+subX;
                finalHeight = (h+subY < minL) ? minL:
                           (h+subY > maxL) ? maxL:h+subY;

                subX = (finalWidth === maxL) ? maxL-w:
                        (finalWidth === minL) ? minL-w : subX;
                subY = (finalHeight === maxL) ? maxL-h:
                        (finalHeight === minL) ? minL-h : subY;

                movedX = subX;
                movedY = subY;

                //미리보기 사각형 그려주기
                resizeg.clear();
                if(targetName === "resizeButtonR")
                {
                    if(subX > 0) resizeg.beginFill(bgColor);
                    else resizeg.beginFill(stageColor);
                    resizeg.drawRect(w,0,subX,h);
                    //미리보기 사각형이 화면을 넘어가면 자동 스크롤
                }
                else if(targetName === "resizeButtonL")
                {
                    if(subX > 0) resizeg.beginFill(bgColor);
                    else resizeg.beginFill(stageColor);
                    resizeg.drawRect(-subX,0,subX,h);
                }
                else if(targetName === "resizeButtonD")
                {
                    if(subY > 0) resizeg.beginFill(bgColor);
                    else resizeg.beginFill(stageColor);
                    resizeg.drawRect(0,h,w,subY);
                }
                else if(targetName === "resizeButtonU")
                {
                    if(subY > 0) resizeg.beginFill(bgColor);
                    else resizeg.beginFill(stageColor);
                    resizeg.drawRect(0,-subY,w,subY);
                }

                setToolTipString(finalWidth+" x "+finalHeight);
            }

            //canvaspanel로 마우스 좌표 해주는 이유는
            //회전 되었을때도 panel좌표가 0도기준으로 유지 되기 때문
            setResizeButtonVisible(false);
            reiszePreviewRect.x = canvasPanel.x;
            reiszePreviewRect.y = canvasPanel.y;
            regPoint.addChild(reiszePreviewRect);
            setTopChildIndex(reiszePreviewRect);
            reiszePreviewRect.visible = true;

            stage.addEventListener(MouseEvent.MOUSE_UP,resizeButtonMouseUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,resizeButtonMouseMoveEvent);
        }

        //지우개랑 펜이랑 합쳐져있음

        private function doLassoDraw(replayMode:Boolean,rectArr:Vector.<Number>,points:Array,copyFlag:Boolean=false):Boolean
        {
            var canvas2FilterBackUp:Array = canvas2Draw.filters.concat();

            var drawEnt:Shape = canvas2Draw;
            var canvasBitmapData:BitmapData = canvas1BitmapData;
            var canvasBitmap:Bitmap = canvas1Bitmap;

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
                canvas2Draw.filters = [];
            }

            const cd:Shape = drawEnt;
            const cdg:Graphics = cd.graphics;
            //라소 경계 사각형 좌표와 크기
            const lassog:Graphics = lassoDrawG.graphics;
            const rectLeft:Number = rectArr[0];
            const rectTop:Number = rectArr[1];
            const rectWidth:Number = rectArr[2] - rectLeft;
            const rectHeight:Number = rectArr[3] - rectTop;
            const lassoPointsLen:uint = points.length;
            const floor:Function = Math.floor;

            //가로세로 길이가 0 이하이면 실행하지 않음
            if(floor(rectWidth) <= 0 || floor(rectHeight) <= 0) return false;

            const halfWidth:Number = rectWidth/2;
            const halfHeight:Number = rectHeight/2;
            const lassoP0:Array = points[0];
            const zerop:Point = new Point(0,0);
            const newRectangle:Rectangle = new Rectangle(rectLeft,rectTop,rectWidth,rectHeight);

            var lassoBMPD:BitmapData = new BitmapData(rectWidth,rectHeight,true,0);
            var i:uint;
            var x:Number;
            var y:Number;
            var lp:Array;
            var xx:Number;
            var yy:Number;

            var lassoDottedLineLimit:int = 3;
            var lassoDottedLineCount:int = 0;
            var lassoDottedLineLastX:Number = 0;
            var lassoDottedLineLastY:Number = 0;
            var lassoDottedLineColor:uint = 0;

            //지우기 전에 사각형 모양으로 그려준 부분을 copypixel 함.
            lassoBMPD.copyPixels(canvasBitmapData,newRectangle,zerop,null,null,true);

            //bitmap1canvas에서 그려준 영역을 지워줌
            if(!copyFlag)
            {
                x = lassoP0[0];
                y = lassoP0[1];
                cdg.clear();
                // cdg.lineStyle(0,0,0);
                cdg.beginFill(CANVAS_BG_COLOR);
                cdg.moveTo(x,y);

                //rectLeft를 빼줘서 canvasdraw2의 0,0영역에 그려줌
                for(i=1;i<lassoPointsLen;i++)
                {
                    lp = points[i];
                    x = lp[0];
                    y = lp[1];
                    cdg.lineTo(x,y);
                }
                cdg.endFill();
                canvasBitmapData.draw(cd,null,null,"erase");
                canvasBitmap.bitmapData = canvasBitmapData;
            }

            //-------------------------
            //clip하기 위해서 그려운 영역의 반전 부분을 0,0영역을 기준으로 그려줌
            //2번 반복하는게 좀 그런데 다른 방법 모르겠음
            lassog.clear();
            lassog.lineStyle(1,lassoDottedLineColor);
            //가로세로 절반 크기만큼 더해줘서 bmp의 중점으로 이동해주기 때문에 또 그만큼 빼줌
            lassog.moveTo(lassoP0[0]-rectLeft-halfWidth,lassoP0[1]-rectTop-halfHeight);

            cdg.clear();
            cdg.beginFill(0x00FF00);
            cdg.drawRect(0,0,rectWidth,rectHeight);
            cdg.moveTo(lassoP0[0]-rectLeft,lassoP0[1]-rectTop);

            //rectLeft를 빼줘서 canvasdraw2의 0,0영역에 그려줌
            for(i=1;i<lassoPointsLen;i++)
            {
                lp = points[i];
                xx = lp[0]-rectLeft;
                yy = lp[1]-rectTop;
                cdg.lineTo(xx,yy);


                xx = xx-halfWidth;
                yy = yy-halfHeight;

                lassoDottedLineCount++;
                if(lassoDottedLineCount > lassoDottedLineLimit)
                {
                    lassoDottedLineCount = 0;
                    if(lassoDottedLineColor === 0)
                    {
                        lassoDottedLineColor = 0xFFFFFF;
                    }
                    else
                    {
                        lassoDottedLineColor = 0;
                    }
                    lassog.lineStyle(1,lassoDottedLineColor);
                    lassog.moveTo(lassoDottedLineLastX,lassoDottedLineLastY);
                }

                lassog.lineTo(xx,yy);
                lassoDottedLineLastX = xx;
                lassoDottedLineLastY = yy;
            }

            //마지막으로 시작점을 이어줌 close path없나?
            lassog.lineTo(lassoP0[0]-rectLeft-halfWidth,lassoP0[1]-rectTop-halfHeight);
            cdg.endFill();

            //비트맵 데이터 넣어주고
            lassoBMP.bitmapData = lassoBMPD;
            //위에서 그려준 테두리 부분만 erase해줌
            lassoBMP.bitmapData.draw(cd,null,null,"erase");
            cdg.clear(); //꼭 해줘야함

            //회전 확대를 bmp사각형의 중심으로 맞추어줌
            lassoBMP.x = -halfWidth;
            lassoBMP.y = -halfHeight;
            lassoBox.x = rectLeft+halfWidth;
            lassoBox.y = rectTop+halfHeight;
            lassoBMP.smoothing = true;

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


        private function closureLassoTool():Function
        {
            const cd:Shape = canvas2Draw;
            const lassoDottedLineLimit:int = 3;
            const lassog:Graphics = lassoDrawG.graphics;

            var lassoDottedLineCount:int;
            var lassoDottedLineColor:uint;
            var lassoDottedLineLastX:Number;
            var lassoDottedLineLastY:Number;
            var canvas2FilterBackUp:Array;
            var lassoClickX:Number;
            var lassoClickY:Number;
            var lassoRect:Vector.<Number>;
            var lassoPoints:Array;
            
            function lassoDrawMouseUp():void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,lassoDrawMouseMove);
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

                //라소 메뉴 마우스 커서에보이기
                const _lassoMenu:lassoButtons = lassoMenu;
                const floor:Function = Math.floor;

                lassoStartData = [lassoBox.x,lassoBox.y,lassoBox.scaleX,lassoBox.scaleY,lassoBox.rotation];
                lassoToolON = true;
                checkLassoMenuPos();
                _lassoMenu.visible = true;
                setTopChildIndex(_lassoMenu);

                if(traceMenuON === true)
                {
                    traceMenuBox.visible = false;
                }

                toolBox.alpha = BUTTON_OFF_ALPHA;

                stage.addEventListener(KeyboardEvent.KEY_DOWN,lassoToolKeyDownEvent);
            }

            function lassoDrawMouseMove(MouseEvent:Event):void
            {
                if(limitMouseMoveEventTime() === true) return;

                const x:Number = cd.mouseX;
                const y:Number = cd.mouseY;

                lassoDottedLineCount++;

                if(lassoDottedLineCount >= lassoDottedLineLimit)
                {
                    lassoDottedLineCount = 0;

                    if(lassoDottedLineColor === 0)
                    {
                        lassoDottedLineColor = 0xFFFFFF;
                    }
                    else
                    {
                        lassoDottedLineColor = 0;
                    }

                    lassog.lineStyle(1,lassoDottedLineColor);
                    lassog.moveTo(lassoDottedLineLastX,lassoDottedLineLastY);
                }

                lassog.lineTo(x,y);
 
                lassoDottedLineLastX = x;
                lassoDottedLineLastY = y;
                //사각형 꼭지점 체크
                if(x < lassoRect[0]) lassoRect[0] = x;
                else if(x > lassoRect[2]) lassoRect[2] = x;

                if(y < lassoRect[1]) lassoRect[1] = y;
                else if(y > lassoRect[3]) lassoRect[3] = y;

                lassoPoints.push([x,y]);
            }

            return function ():void
            {
                if(lassoToolON === true) return;

                canvas2FilterBackUp = canvas2Draw.filters.concat();
                canvas2Draw.filters = [];

                lassoClickX = cd.mouseX;
                lassoClickY = cd.mouseY;
                //left, top, right, bottom순임
                lassoRect = new <Number> [lassoClickX,lassoClickY,lassoClickX,lassoClickY];
                lassoPoints = [];
                lassoPointSave = [];
                lassoDottedLineCount = 0;
                lassoDottedLineColor = 0;

                canvas2.alpha = 1.0; //알파값이 조정되어 있을 수도 있기 때문에 해줌
                setTopChildIndex(lassoBox);

                lassoBox.visible = true;
                lassog.clear();
                lassog.lineStyle(1,lassoDottedLineColor);
                lassog.moveTo(lassoClickX,lassoClickY);
                lassoPoints.push([lassoClickX,lassoClickY]);

                stage.addEventListener(MouseEvent.MOUSE_MOVE,lassoDrawMouseMove);
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

        private function closureSpuitTool():Function
        {
            //일단 흰색으로 배경 깔아줌
            const spuitCursor:Sprite = spuitZoomCursor;
            const _setColorTransform:Function = setColorTransform;
            const canvas1bmpd:BitmapData = canvas1BitmapData;
            var oldTool:int;
            var spuitbmpd:BitmapData;
            var penColorBackup:uint;
            const zerop:Point = new Point(0,0);
            const pickerBox:colorPickerBox = pickerBox;

            function pickColor():uint
            {
                return (canvas1Bitmap.hitTestPoint(mouseX,mouseY)) ? spuitbmpd.getPixel(canvas1Bitmap.mouseX,canvas1Bitmap.mouseY)
                                                                     : penColorBackup;
            }

            //픽커 도중에 오른쪽 클릭하면 캔슬해줌
            function colorPickerCancelKeyUpEvent(e:KeyboardEvent):void
            {
                if(e.keyCode === gKey.c || e.keyCode === gKey.m)
                {
                    colorPickerOFF(true);
                }
            }

            function colorPickerCancelKeyDownEvent(e:KeyboardEvent):void
            {
                if(e.keyCode === gKey.c || e.keyCode === gKey.m)
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
                colorPickerOFF(true);
            }

            function colorPickerOFF(okFlag:Boolean):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,colorPickerOKMouseEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,colorPickerMoveEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, colorPickerCancelMouseEvent);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, colorPickerCancelKeyDownEvent);
                stage.removeEventListener(KeyboardEvent.KEY_UP, colorPickerCancelKeyUpEvent);

                if(okFlag && spuitCursor.visible === true)
                {
                    const pickedColor:uint = pickColor();
                    const colorhistoryArr:Array = colorHistoryList;
                    const colorhistoryArrlength:uint = colorhistoryArr.length;
                    const findIndex:int = colorhistoryArr.lastIndexOf(pickedColor);
                    const c:Vector.<uint> = HEXtoRGB(pickedColor);
                    const colorHint:String =  "RGB "+c[0]+","+c[1]+","+c[2];

                    // pickerONButton.transform.colorTransform = newColor;
                    changedColor = pickedColor; //이 변수는 컬러 히스토리를 선택했을때 선택할 색을 저장하는 변수인데 여기다가도 변경해줘서
                    penColor = pickedColor;
                    updatePickerCurrentColor(pickedColor);
                    setHSVCursorPosByColor(pickedColor);

                    if(colorhistoryArrlength > 1 && findIndex !== -1)
                    {
                        changedColor = int.MAX_VALUE;
                        
                        if(!colorHistoryUpdateReady)
                        {
                            colorHistoryUpdateReady = true;
                            stage.addEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryEvent);
                        }
                    }

                    if(oldTool === TOOL_LINE)
                    {
                        nowToolBackup = TOOL_LINE;
                    }
                    else if(oldTool === TOOL_FILL_PEN)
                    {
                        nowToolBackup = TOOL_FILL_PEN;
                    }
                    else
                    {
                        nowToolBackup = TOOL_PEN;
                    }
                }

                spuitbmpd.dispose();
                spuitCursor.visible = false;
                setPrevTool();
                //move에서 spuitBitmapData를 쓰고 있기 때문에 이벤트를 먼저 해제해주고 데이터 비워줌
            }

            function colorPickerMoveEvent(e:MouseEvent):void
            {
                if(limitMouseMoveEventTime() === true)
                {
                    return;
                }
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

            return function ():void
            {
                toolBox.moveToolCursor("toolSpuit");

                oldTool = nowTool;
                spuitbmpd = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,false,CANVAS_BG_COLOR);
                
                spuitbmpd.draw(canvas1BitmapData);
                penColorBackup = penColor;
                nowTool = TOOL_SPUIT;
                _setColorTransform(spuitCursor["spuitOldColor"],penColor);
                moveEraseButton("toolSpuit");
                
                if(canvas1Bitmap.hitTestPoint(mouseX,mouseY) === true
                && mouseX > STAGE_LEFT_OFFSET && mouseX < stage.stageWidth-STAGE_RIGHT_OFFSET //캔버스 영역안에서만
                && mouseY > STAGE_TOP_OFFSET && mouseY < stage.stageHeight-STAGE_BOTTOM_OFFSET)
                {
                    spuitCursor.x = mouseX;
                    spuitCursor.y = mouseY;
                    _setColorTransform(spuitCursor["spuitNowColor"],pickColor());
                    setTopChildIndex(spuitCursor);
                    spuitCursor.visible = true;
                }

                stage.addEventListener(MouseEvent.MOUSE_DOWN,colorPickerOKMouseEvent,false,-2);
                stage.addEventListener(MouseEvent.MOUSE_MOVE,colorPickerMoveEvent);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, colorPickerCancelMouseEvent);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, colorPickerCancelKeyDownEvent,false,2);
                stage.addEventListener(KeyboardEvent.KEY_UP, colorPickerCancelKeyUpEvent,false,2);
            };
        }

        private function setOptimizeCanvasMove(flag:Boolean):void
        {
            setResizeButtonVisible(!flag);
            if(canvasTrace.alpha > 0.0)
            {
                canvasTrace.visible = !flag;
            }
        }

        private function closureHandTool():Function
        {
            var _replayMode:Boolean;
            var isDrawMode:Boolean;
            var xReg:Sprite;
            var xBitmap:Bitmap;
            var oldX:Number;
            var oldY:Number;
            var toolBoxHandFlag:Boolean;

            function handToolUpEvent(e:MouseEvent):void
            {   
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, handToolMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP, handToolUpEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, handToolUpEvent);

                mouseDragON = false;
                penCursorOFFFlag = false;

                checkCanvasPanelPos(_replayMode);

                if(isDrawMode)
                {
                    setOptimizeCanvasMove(false);

                    if(nowKey !== gKey.space && toolBoxHandFlag === false)
                    {
                        setPrevTool();
                    }

                    if(lassoToolON)
                    {
                        if(lassoMenuTempOFF === true)
                        {
                            lassoMenu.visible = true;
                            lassoMenuTempOFF = false;
                        }
                        checkLassoMenuPos();
                    }
                    updatePreviewCursorPos();
                }
                else
                {
                    updateReplayCanvasBounds();
                }
            }

            function handToolMoveEvent(e:MouseEvent):void
            {
                if(limitMouseMoveEventTime() === true) return;

                xReg.x += (mouseX-oldX);
                xReg.y += (mouseY-oldY);

                oldX = mouseX;
                oldY = mouseY;
            }

            return function (replayMode:Boolean=false,toolBoxHandFlag:Boolean=false):void
            {
                _replayMode = replayMode;
                isDrawMode = !replayMode;
                xReg = (isDrawMode) ? regPoint : rregPoint;
                xBitmap = (isDrawMode) ? canvas1Bitmap : rcanvas1Bitmap;
                oldX = mouseX;
                oldY = mouseY;

                mouseDragON = true;
                penCursorOFFFlag = true;

                if(isDrawMode) setOptimizeCanvasMove(true);

                stage.addEventListener(MouseEvent.MOUSE_MOVE, handToolMoveEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP, handToolUpEvent);
                //윈도우 바깥에서 up을 하면 hand가 안꺼져서 오른쪽 마우스 뗄떼도 꺼주게함
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, handToolUpEvent);
            };
        }

        //zoom이나 rotate reg포인트 바뀔때마다
        //캔버스 판넬위치 따라 다니면서 크기 똑같이 해줌
        private function updateResizeButtonPos():void
        {
            function setpos(ent:canvasResizeButton,x:Number,y:Number):void
            {
                const z:Number = 1/zoomed;
                ent.scaleX = z;
                ent.scaleY = z;
                ent.x = x;
                ent.y = y;
            }

            const cpPosX:Number = canvasPanel.x;
            const cpPosY:Number = canvasPanel.y;
            const w:Number = CANVAS_WIDTH;
            const h:Number = CANVAS_HEIGHT;
            const xHalf:Number = cpPosX+w/2;
            const xLeft:Number = cpPosX;
            const xRight:Number = cpPosX+w;
            const yHalf:Number = cpPosY+h/2;
            const yTop:Number = cpPosY;
            const yBottom:Number = cpPosY+h;

            setpos(resizeButtonU,xHalf,yTop);
            setpos(resizeButtonD,xHalf,yBottom);
            setpos(resizeButtonL,xLeft,yHalf);
            setpos(resizeButtonR,xRight,yHalf);
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

                    const point1:Vector.<Number> = lassoPointSave[0].concat();
                    const point2:Array = lassoPointSave[1].concat();
                    const lassoInfos:Array = [lassoBMPScaleX,lassoBMPScaleY,
                                                lassoBMPWidth,lassoBMPHeight,
                                                ang,boxX,boxY];

                    rDataBuffer.push(["lasso",point1,point2,lassoInfos,lassoCopyON]);
                    addUndoData();
                }
                else //그렇지 않으면 cancel이랑 똑같이
                {
                    lassoCanceleBmpd();
                }

                lassoBMP.bitmapData.dispose();
                lassoBMP.bitmapData = null;
            }
            resetLassoBox();
        }

        private function lassoCanceleBmpd():void
        {
            const u:Array = undoData[undoIndex];

            canvas1BitmapData = u[0].clone();
            canvas1Bitmap.bitmapData = canvas1BitmapData;
            if(mirrorON !== u[1])
            {
                mirrorDraw();
            }
            else
            {
                previewBox.updateImage(canvas1BitmapData,CANVAS_BG_COLOR);
            }
        }

        private function setLassoCancelButton(copyFlag:Boolean=false):void
        {
            if(!copyFlag)
            {
                if(lassoBMP.bitmapData !== null)
                {
                    lassoBMP.bitmapData.dispose();
                    lassoBMP.bitmapData = null;
                }

                resetLassoBox();
            }

            if(undoData.length > 0)
            {
                lassoCanceleBmpd();
            }
        }

        //펜툴로 선택,세팅 껍데기만 바꿔주는거임 setPenTool은 실제 툴을 진행하는거
        private function selectMoveTool():void
        {
            nowToolBackup = nowTool;
            nowTool = TOOL_MOVE;
            toolBox.moveToolCursor("toolMove");
        }

        private function selectZoomTool():void
        {
            nowToolBackup = nowTool;
            nowTool = TOOL_ZOOM;
            toolBox.moveToolCursor("toolZoom");
        }

        private function selectRotateTool():void
        {
            nowToolBackup = nowTool;
            nowTool = TOOL_ROTATE;
            toolBox.moveToolCursor("toolRotate");
        }

        private function selectLassoTool():void
        {
            nowToolBackup = nowTool;
            nowTool = TOOL_LASSO;
            moveEraseButton("toolLasso");
            toolBox.moveToolCursor("toolLasso");
        }

        private function selectFillPenTool():void
        {
            nowToolBackup = TOOL_PEN;
            nowTool = TOOL_FILL_PEN;
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
        private function closureCheckMainDrawTool():Function
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
                                
                    if(subLayerON)
                    {
                        canvasPanel.setChildIndex(canvas1,2);
                    }
                    else
                    {
                        canvasPanel.setChildIndex(canvas2,2);
                    }

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
                        if(eraseMovedButton) 
                        {
                            eraseMovedButton.visible = true;
                        }

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
            }
        }

        private function selectLineTool():void
        {
            nowTool = TOOL_LINE;
            checkMainDrawTool(penSize,penColor,penAlpha,penShape,true,true);
        }

        private function selectPenTool():void
        {
            nowTool = TOOL_PEN;
            checkMainDrawTool(penSize,penColor,penAlpha,penShape,true,false);
        }

        private function selectEraseTool():void
        {
            nowTool = TOOL_ERASE;
            checkMainDrawTool(eraseSize,CANVAS_BG_COLOR,eraseAlpha,eraseShape,false,false);
        }

        //라소박스 변형이랑 플래그 초기화
        private function resetLassoBox():void
        {
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,lassoToolKeyDownEvent);

            lassoToolON = false;
            lassoMirrorON = false;
            lassoCopyON = false;
            lassoMenuTempOFF = false;
            lassoStartData = [];
            lassoPointSave = [];
            lassoBMP.filters = [];
            lassoMenu.visible = false;
            lassoBox.x = 0;
            lassoBox.y = 0;
            lassoBox.scaleX = 1.0;
            lassoBox.scaleY = 1.0;
            lassoBox.rotation = 0;
            lassoBox.visible = false;
            lassoResizeMoveSum = 0;
            lassoMenu["lassoCopy"].alpha = 1.0;

            controlBox.visible = true;
            pickerBox.visible = true;

            if(traceMenuON === true)
            {
                traceMenuBox.visible = true;
            }

            toolBox.alpha = 1.0;

            setPrevTool();
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
            var xReg:Sprite = regPoint;
            var xCanvas:Sprite = canvasPanel;
            var xZoomed:Number = zoomed;

            if(replayMode)
            {
                xReg = rregPoint;
                xCanvas = rcanvasPanel;
                xZoomed = rzoomed;
            }

            //round하면 정확도가 약간 줄어드는데, 안하면 그릴때 픽셀 어긋남
            const floor:Function = Math.floor;
            //캔버스 회전됐을때 점 위치를 구해줌
            //zoom된값을 나눠줘야 제대로된 이동거리가 나옴
            const z:Number = zoomed;
            const rotateToolMoveEvent:Point = rotatePoint((xReg.x-tx)/xZoomed,
                                                 (xReg.y-ty)/xZoomed,
                                                 xReg.rotation);
            xReg.x = floor(tx+0.5);//이동시키고
            xReg.y = floor(ty+0.5);
            xCanvas.x += floor(rotateToolMoveEvent.x+0.5);//이동한 만큼 거꾸로 움직여줌
            xCanvas.y += floor(rotateToolMoveEvent.y+0.5);//rotate값 포함해서 움직여야함

            if(!replayMode)
            {
                updateResizeButtonPos();
            }
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

        private function drawUndoData(redoFlag:Boolean):void
        {
            const d:Array = undoData;
            const index:uint = undoIndex;

            const u:Array = d[index];
            const data:BitmapData = u[0];
            const mirrorFlag:Boolean = u[1];
            const w:uint = u[2];
            const h:uint = u[3];
            const bg:uint = u[4];
            var mirrorChanged:Boolean = false; //미러플래그 변화를 감지함

            //undo한 데이터와 캔버스 사이즈가 다르면 비트맵데이터 크기바꿈
            if(w !== CANVAS_WIDTH || h !== CANVAS_HEIGHT) setPanelSize(w,h,0,0,false);
            if(bg !== CANVAS_BG_COLOR) setBackgroundColor(bg);

            canvas1BitmapData = data.clone();//clone으로 해주어야함
            canvas1Bitmap.bitmapData = canvas1BitmapData;
            previewBox.updateImage(canvas1BitmapData,CANVAS_BG_COLOR);

            if(mirrorON !== mirrorFlag)
            {
                mirrorPushON = true;
                mirrorDraw();
            }
            else
            {
                mirrorPushON = false;
            }

            checkCanvasPanelPos(); //사이즈가 크가 줄었을때 캔버스가 창 밖으로 나가는거 체크
            updatePreviewCursorPos();
        }
        private function setRedoButton():void
        {
            ++undoIndex;
            const len:uint = undoData.length-1;
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

            const str:String = "Redo " + undoIndex + " / " + (undoData.length-1);
        }

        private function setUndoButton():void
        {
            --undoIndex;

            if(undoIndex < 0)
            {
                undoIndex = 0;
            }
            else
            {
                saveOneTime = false;
                clearButtonClicked = false;
                undoDelFlag = true;
                replayONUndoUpdate = true;
                addUndoMode = 0;
                drawUndoData(false);
            }

            const str:String = "Undo " + undoIndex + " / " + (undoData.length-1);
        }

        private function forceUndoAndDeleteFrontData(index:int):void
        {
            const endIndex:uint = index;
            undoData.splice(0,endIndex);  
            rData.splice(0,endIndex);
            rDataFrame.splice(0,endIndex);

            undoData.unshift([rFirstImage.clone(),false,rFirstImage.width,rFirstImage.height,rFirstBGColor]);
            rData.unshift([]);
            rDataFrame.unshift(0);

            undoIndex = undoIndex-(index-1);
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
            drawUndoData(false);

            //데이터 뒷부분 지워줌
            const startIndex:uint = index+1;
            undoData.splice(startIndex);
            rData.splice(startIndex);
            rDataFrame.splice(startIndex);
        }

        private function closureAddUndoData():Function
        {
            return function(addMode:uint=0):void
            {
                replayONUndoUpdate = true;

                if(undoDelFlag === true)
                {
                    const startIndex:uint = undoIndex+1;
                    undoDelFlag = false;
                    undoData.splice(startIndex);
                    rData.splice(startIndex);
                    rDataFrame.splice(startIndex);
                }

                if(undoData.length >= 6) //첫번째 이미지는 빼야하니깐 -1로 계산해야함
                {
                    var pushReady:Array = rData[0];

                    if(pushReady.length > 0)
                    {
                        const fs:FileStream = new FileStream();
                        const c:uint = rDataFrame[0];
                        const rf:File = repFile;

                        fs.open(rf,FileMode.APPEND);
                        fs.writeObject(pushReady);
                        fs.close();

                        pushReady = null;

                        rFileTotalFrame += c;
                        rSkipImageCount += c;

                        if(rSkipImageInit === 0)
                        {
                            if(rSkipImageCount > IMG_CACHE_INTERVAL)
                            {
                                //위에서 쓰고나서 가능한 바이트랑 실제 바이트 = rf.size랑 다름, rf.size가 정확함
                                const rFileMaxFrameSave:Number = rFileTotalFrame;

                                rSkipImageFrameData.push(rFileMaxFrameSave);

                                const skipimg:File = rSkipImageFolder.resolvePath((rSkipImageFrameData.length-1)+".img");
                                const imgData:ByteArray = new ByteArray();
                                const u:Array = undoData[0];
                                const w:uint= u[2];
                                const h:uint= u[3];
                                const bgColor:uint = u[4];
                                const newRectangle:Rectangle = new Rectangle(0,0,w,h);

                                u[0].copyPixelsToByteArray(newRectangle,imgData);
                                fs.open(skipimg,FileMode.WRITE);
                                fs.writeObject([imgData,w,h,bgColor,rf.size,rFileMaxFrameSave]);//이미지 데이터,가로 세로, 배경색, 마지막 바이트 위치, 마지막 프레임 합
                                fs.close();
                                imgData.clear();
                                rSkipImageCount = 0;
                            }
                        }
                    }

                    undoData.shift();
                    rData.shift();
                    rDataFrame.shift();
                }

                if(mirrorPushON)
                {
                    mirrorPushON = false;
                    if(rDataBuffer.length > 0 && rDataBuffer[0][0] !== "mirror")
                    {
                        addMode = 0;
                        addUndoMode = 0;
                        rDataBuffer.unshift(["mirror"]);
                    }
                }
                else if(!mirrorPushON)
                {
                    if(rDataBuffer.length > 0 && rDataBuffer[0][0] === "mirror")
                    {
                        addMode = 0;
                        addUndoMode = 0;
                        rDataBuffer.shift();
                    }
                }

                //연속해서 캔버스 사이즈와 move tool이용할경우 가장 마지막 데이터만 바꿔줌
                if(addMode > 0 && addUndoMode === addMode)
                {
                    const lastUndoData:Array = undoData[undoData.length-1];
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

                    if(addMode === 1) //move툴 중복 사용
                    {
                        lastUndoData[0] = canvas1BitmapData.clone();
                    }
                    else if(addMode === 2)//add1 //캔버스 사이즈 변경
                    {
                        //사이즈 변경된 bitmapdata까지 갱신해줘야함
                        lastUndoData[0] = canvas1BitmapData.clone();
                        lastUndoData[2] = CANVAS_WIDTH;
                        lastUndoData[3] = CANVAS_HEIGHT;
                    }
                    else if(addMode === 3) //배경색 중복 사용
                    {
                        lastUndoData[4] = CANVAS_BG_COLOR;
                    }
                }
                else
                {
                    undoData.push([canvas1BitmapData.clone(),mirrorON,canvas1Bitmap.width,canvas1Bitmap.height,CANVAS_BG_COLOR]);
                    rData.push(rDataBuffer);
                    rDataFrame.push(rDataBuffer.length);
                    rDataBuffer = [];

                    if(saveOneTime === true)
                    {
                        saveOneTime = false;
                    }
                }

                undoIndex = undoData.length-1;
                addUndoMode = addMode;
                previewBox.updateImage(canvas1BitmapData,CANVAS_BG_COLOR);
            };
        }

        // hsv커서가 color에 맞춰서 위치를 움직여줌
        private function setHSVCursorPosByColor(color:uint,initFlag:Boolean=false):void
        {
            if(color === penLastUpdateInfo[5] && !pickerColorSelected)
            {
                return;
            }
            penLastUpdateInfo[5] = color;

            const floor:Function = Math.floor;
            const _pickerBox:colorPickerBox = pickerBox;
            const _colorBarWidth:Number = _pickerBox["svBoxWidth"];
            const _colorBarHeight:Number = _pickerBox["svBoxHeight"];
            const svCursor:SimpleButton = _pickerBox["svCursor"];
            const hueCursor:SimpleButton = _pickerBox["hueCursor"];
            const round:Function = Math.round;
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
        private function HSVtoRGB (h:Number, s:Number, v:Number):Vector.<uint>
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
                case 0: return new <uint> [v, t, p];
                case 1: return new <uint> [q, v, p];
                case 2: return new <uint> [p, v, t];
                case 3: return new <uint> [p, q, v];
                case 4: return new <uint> [t, p, v];
                case 5: return new <uint> [v, p, q];
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
            if(index < 0)
            {
                return;
            }

            const _opabox:Sprite = controlBox.opaBox;
            const curButton:SimpleButton = _opabox["alphaButton"+index];

            if(!curButton)
            {
                return;
            }

            if(penColor === penLastUpdateInfo[2] && index === penLastUpdateInfo[3])
            {
                return;
            }
            penLastUpdateInfo[2] = penColor;
            penLastUpdateInfo[3] = index;

            const alphaCursor:SimpleButton = _opabox["alphaCursor"];

            alphaCursor.x = curButton.x;//+curButton.width/2-alphaCursor.width/2;
            alphaCursor.y = curButton.y+3;//+curButton.height/2;//-alphaCursor.height/2;
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
            toolBox.zoomIconRightPos();

            sideBarScrollBar.x = previewBox.x-sideBarScrollBar.width;
            sideBarScrollBar.y = scrollBarMovedY;

            _sideBar.y = topBar.BARSIZE;

            STAGE_RIGHT_OFFSET = _sideBar.w;
            STAGE_LEFT_OFFSET = 0;

            const fillPenIconPos:Point = toolBox.toolFillPen.localToGlobal(new Point(0,0));
            fillPenBox.x = fillPenIconPos.x-34;
            fillPenBox.y = fillPenIconPos.y-1;

            if(ignoreCanvasMove === false)
            {
                regPoint.x -= STAGE_RIGHT_OFFSET;
            }

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
            toolBox.zoomIconLeftPos();

            sideBarScrollBar.x = _sideBar.w;
            sideBarScrollBar.y = scrollBarMovedY;

            _sideBar.y = topBar.BARSIZE;

            STAGE_LEFT_OFFSET = _sideBar.w;
            STAGE_RIGHT_OFFSET = 0;

            const fillPenIconPos:Point = toolBox.toolFillPen.localToGlobal(new Point(0,0));
            fillPenBox.x = fillPenIconPos.x;
            fillPenBox.y = fillPenIconPos.y;

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
            // g.lineStyle(1,color1,1.0,true);
            g.lineStyle(0,0,0);
            g.beginFill(color2);
            g.drawRect(0,0,10,height);
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
            sideBarScrollBar.alpha = 0.7;

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
            stage.addChild(fillPenBox);
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
            rcapturePreviewCursor.visible = false;
            rcapturePreviewCursor.blendMode = "difference";

            rcapturePreviewRect.visible = false;
            rcapturePreviewRect.blendMode = "difference";

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
            _rcanvasPanel.addChild(rcapturePreviewRect);
            _rcanvasPanel.addChild(rcapturePreviewCursor);
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
            canvasTrace.name = "canvasTrace";
            canvasGrid.name = "canvasGrid";

            penSizeCursor.visible = false;

            lassoBox.name = "lassoBox";
            lassoBox.addChild(lassoBMP);
            lassoBox.addChild(lassoDrawG);

            lassoBox.visible = false;

            reiszePreviewRect.visible = false;

            capturePreviewCursor.visible = false;
            capturePreviewCursor.blendMode = "difference";

            capturePreviewRect.visible = false;
            capturePreviewRect.blendMode = "difference";

            g = _canvasPanel.graphics;
            g.clear();
            g.beginFill(CANVAS_BG_COLOR);
            g.drawRect(0,0,CANVAS_WIDTH,CANVAS_HEIGHT);
            g.endFill();

            //캔버스 박스에서 lineto가 아무데나 그려지면 안되서 mask로 가려줌
            g = canvasPanelMask.graphics
            g.clear();
            g.beginFill(0);//paneldraw마스크 아무색이나 상관없음
            g.drawRect(0,0,CANVAS_WIDTH, CANVAS_HEIGHT);
            g.endFill();

            updateStageBG(uiColorSet[uiColorIndex][2]);

            canvasTrace.alpha = CANVAS_TRACE_ALPHA;
            canvasTrace.addChild(canvasTraceBitmap);
            canvas1.addChild(canvas1Bitmap);//canvas1에 투명 bmp도화지 추가
            canvas2.addChild(canvas2Bitmap);//
            canvas2.addChild(canvas2Draw);//canvas2에
            canvas2.blendMode = "layer";//캔버스1이랑 알파 불투명도가 겹치지 않게 layer모드로 해줌

            _canvasPanel.addChild(canvasTrace);// 판넬레 trace layer 추가
            _canvasPanel.addChild(canvas1);//판넬에 canvas1추가
            _canvasPanel.addChild(canvas2);//판넬에 canvas2추가
            _canvasPanel.addChild(lassoBox);
            _canvasPanel.addChild(canvasGrid);
            _canvasPanel.addChild(capturePreviewRect);
            _canvasPanel.addChild(capturePreviewCursor);
            _canvasPanel.addChild(canvasPanelMask);//판넬에  마스크 추가
            _canvasPanel.mask = canvasPanelMask;//마스크 해줘서 판 밖으로 선나타나지 않도록함

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

            //add event
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDownEvent,false,-1);
            stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownEvent,false,-1);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent,false,-1);
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
            
            if(sideBarSetHeight < sth)
            {
                sideBarScrollBar.visible = false;
                return;
            }

            var scrollBarSize:Number = floor(sth-(sideBarSetHeight-sth));
            if(scrollBarSize < 50)
            {
                scrollBarSize = 50;
            }

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

                //창움직임에 따라서 약간씩 움직여줌
                rregPoint.x = rregPoint.x+dx;
                rregPoint.y = rregPoint.y+dy;
                regPoint.x = regPoint.x+dx;
                regPoint.y = regPoint.y+dy;

                if(captureModeON)
                {
                    captureWindowMove[0] += dx;
                    captureWindowMove[1] += dy;
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

                if(captureModeON)
                {
                    canvasFitWindow(true);
                }

                checkCanvasPanelPos();

                if(aboutPanelON) setAboutPanelCenterPos();
                
                if(replayModeON)
                {
                    updateReplayBarPos(stw,sth);
                    updateReplayCanvasBounds();
                }
                else updateResizeButtonPos();//리사이즈 버튼 위치도 업데이트

                updateStageBG(uiColorSet[uiColorIndex][2]);
                topBar.updateTopbarBG(stw);
                topBar.updateTimerPos(stage.stageWidth);

                sideBar.updateSideBGSize(sth-STAGE_TOP_OFFSET);
                updateScrollBarHeight(sth);
                if(isRightSidebar) sideBar.x = stage.stageWidth-sideBar.w;
                updatePreviewCursorPos();

                if(fileDragSelectBox.visible === true)
                {
                    setDragDropSelectBoxCenterPos();
                }
    
                _lastWindowSize.x = windowW;
                _lastWindowSize.y = windowH;
            },200);
        }

        private function setZoomCanvas(z:Number,replayMode:Boolean = false):void
        {
            const fz:Number = Math.floor(z*100+0.5)/100;
            var xReg:Sprite = regPoint;

            if(!replayMode)
            {
                zoomed = fz;
            }
            else
            {
                const rz:Number = fz;
                const rzo:Number = 1/rz;
                const tCursor:SimpleButton = rCursor;

                rzoomed = rz;
                tCursor.scaleX = rzo;
                tCursor.scaleY = rzo;

                xReg = rregPoint;
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
                appInfoBox.insertCanvasInfo([null,null,Math.floor(z*100),null]);
            }
        }

        private function windowClosingEvent(e:Event):void
        {
            if(rSkipImageInit === 2)
            {
                e.preventDefault();
                return;
            }
            windowClosingFlag = true;

            if(replayStartON === true) stopReplay();
            if(captureModeON === true) captureOFF();
            if(nowTool === TOOL_LASSO) setLassoCancelButton();

            if(shiftKeyON)
            {
                resetApp();
            }
            else if(stage.nativeWindow.displayState === "maximized") //최대화이면 복원해주고 닫아줌
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
            var xReg:Sprite = regPoint
            var xCanvas:Sprite = canvas1;
            if(replayMode)
            {
                xReg = rregPoint;
                xCanvas = rcanvas1;
            }
            const offset:int = 100; //최소 100픽셀 은 보여야함
            const BRECT:Object = getBoundRect(xCanvas);
            const leftLimit:Number = STAGE_LEFT_OFFSET+offset;
            const rightLimit:Number = stage.stageWidth-(STAGE_RIGHT_OFFSET+offset);
            const topLimit:Number = STAGE_TOP_OFFSET+offset;
            const bottomLimit:Number = stage.stageHeight-(STAGE_BOTTOM_OFFSET+offset);

            //getbound는 보이는 그대로 사각형 끝점 좌표를 반환함
            const left:Number = BRECT.left;
            const top:Number = BRECT.top;
            const right:Number = BRECT.right;
            const bottom:Number = BRECT.bottom;

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
            var centerX:Number = (isRightSidebar) ? floor((stage.stageWidth-STAGE_RIGHT_OFFSET)/2) : floor(STAGE_LEFT_OFFSET+(stage.stageWidth-STAGE_LEFT_OFFSET)/2);
            var centerY:Number = floor(topBarOffset+(stage.stageHeight-topBarOffset)/2);

            if(captureMode)
            {
                centerX = stage.stageWidth/2;
                centerY = floor(topBarOffset+(stage.stageHeight-topBarOffset)/2);
            }
            else if(replayMode)
            {
                const repTopOffset:Number = topBarOffset+replayTimeBox.BARSIZE;
                centerX = stage.stageWidth/2;
                centerY = floor(repTopOffset+(stage.stageHeight-repTopOffset)/2);
            }
            return new Point(centerX,centerY);
        }
        private function setCenvasCenterPos(replayMode:Boolean = false,captureMode:Boolean=false):void
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

            mirrorON = false;
            mirrorPushON = false;

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
            var oldSpeed:Number = rSpeed;
            var max:Number = (clacMax > maxSpeed) ? maxSpeed : clacMax;

            if(upFlag)
            {
                oldSpeed += 1;
                if(oldSpeed > max) oldSpeed = max;
            }
            else
            {
                oldSpeed -= 1;
                if(oldSpeed < 1) oldSpeed = 1;
            }

            const timeStr:String = getReplayTime(oldSpeed,TOTAL_FRAME);
            const finalStr:String = "Playback speed x "+oldSpeed+" ("+timeStr+")";
            topBar.hintTime(finalStr,topBar.replaySpeedSet);

            rSpeed = oldSpeed;
            topBar.setSpeedButtonPosByValue(oldSpeed,max);
        }

        private function keyDownReplayModeEvent(e:KeyboardEvent):void//keydown2
        {
            const keyCode:uint = e.keyCode;

            if(e.shiftKey === true) //자툴이 있기 때문에 아래 return 해주지 않음
            {
                if(keyCode === gKey.s)
                {
                    if(e.controlKey === true)
                    {
                        saveFile(true);
                    }
                    return;
                }
            }
            else if(e.altKey === true)
            {
                if(keyCode === gKey.s)
                {
                    setCaptureReady();
                }
                return;
            }
            else if(e.controlKey === true || keyCode ===  gKey.ctrl || keyCode === 25 || keyCode === 17 || controlKeyON)
            {
                controlKeyON = true;

                if(keyCode === gKey.s)
                {
                    saveFile(false);
                }
                else if(keyCode === gKey.o)
                {
                    loadFile();
                }
                else if(keyCode === gKey.z || keyCode === gKey.dot)
                {
                    cutFrameData(0,true);
                }
                else if(keyCode === gKey.c  || keyCode === gKey.m)
                {
                    cutFrameData(1,true);
                }
                else if(keyCode === gKey.x  || keyCode === gKey.comma)
                {
                    cutFrameData(2,true);
                }
                return;
            }

            switch(keyCode)
            {
                case gKey.left:
                case gKey.z:
                case gKey.dot:
                {
                    setSkipOneFrame(true,true,e.shiftKey);
                }
                break;

                case gKey.right:
                case gKey.x:
                case gKey.comma:
                {
                    setSkipOneFrame(false,true,e.shiftKey);
                }
                break;

                case gKey.up:
                case gKey.f:
                case gKey.h:
                {
                    setReplaySpeedByKey(true);
                }
                break;
                case gKey.down:
                case gKey.v:
                case gKey.n:
                {
                    setReplaySpeedByKey(false);
                }
                break;
            }

            if(rNowKey === keyCode)
            {
                return;
            }

            if(keyCode === gKey.shift && !shiftKeyON)
            {
                shiftKeyON = true;
            }

            if(keyCode === gKey.tab || captureModeON || aboutPanelON)
            {
                e.preventDefault();
                return;
            }
            else if(captureModeShortCutOFF)
            {
                captureModeShortCutOFF = false;
                return;
            }

            rNowKey = keyCode;

            switch(keyCode)
            {
                case gKey.esc:
                {
                    if(cutFrameClickedButton > 0)
                    {
                        resetCutFrameClickCounter();
                    }
                    else setReplayUI(false);
                }
                break;

                case gKey.f4:
                {
                    cutFrameData(1,true);
                }
                break;

                case gKey.f5:
                {
                    cutFrameData(0,true);
                }
                break;

                case gKey.f6:
                {
                    cutFrameData(2,true);
                }
                break;

                case gKey.n1:
                case gKey.n7:
                {
                    setReplayUI(false);
                }
                break;

                case gKey.enter:
                case gKey.space:
                {
                    if(repSpaceKeyON === false)
                    {
                        repSpaceKeyON = true;

                        if(replayStartON === false)
                        {
                            startReplay();
                        }
                        else
                        {
                            stopReplay();
                        }
                    }
                }
                break;
            }
        }

        private function keyUpReplayModeEvent(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;

            rNowKey = 0;
            if(keyCode === gKey.shift && shiftKeyON)
            {
                shiftKeyON = false;
            }
            else if(keyCode === gKey.enter || keyCode === gKey.space)
            {
                repSpaceKeyON = false;
            }
            else if(e.controlKey === true || keyCode ===  gKey.ctrl || keyCode === 25 || keyCode === 17)
            {
                controlKeyON = false;
            }
        }

        private function keyUpEvent(e:KeyboardEvent):void //keyup1
        {
            const keyCode:uint = e.keyCode;
            const _nowKey:uint = nowKey;

            if(lassoMenuTempOFF) //라소툴 임시로 꺼줄때 다시 라소툴로 복귀
            {
                if(keyCode === _nowKey)
                {
                    // nowKey = 0;
                    nowTool = TOOL_LASSO;
                    lassoMenuTempOFF = false;
                    lassoMenu.visible = true;
                    stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDownEvent);
                    stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent,false,-1);
                }
            }
            else if(clipImageShortCutON && keyCode === gKey.v)
            {
                clipImageShortCutON = false;
            }

            if(_nowKey === keyCode)//key down에서 눌러준 키가 아니면 리턴
            {
                if(_nowKey === gKey.d || _nowKey === gKey.j)
                {
                    stage.removeEventListener(KeyboardEvent.KEY_DOWN,eraseKeyDownEvent);
                }

                if(mouseClickON === true)
                {
                    afterToolOff = true;
                }
                else
                {
                    const nt:int = nowTool;

                    if(nt === TOOL_ERASE || nt === TOOL_LINE)
                    {
                        penCursorOFFFlag = false;
                    }

                    //tool lasso 왜해주냐면 단축키를 누른 상태에서 그리고 lasso draw가 작동된후 단축키를 떼면 prev가 작동되서 그럼
                    //일단 이전툴로 하고나서 아래 툴키를 해야함 안하면 nowtool backup이 꼬임
                    if(!lassoToolON && nowToolBackup > 0)
                    {
                        setPrevTool();
                    }
                    
                    if(keyBufferArr.length > 0)
                    {
                        const nextKey:int = keyBufferArr.shift();
                        checkToolKeyDown(nextKey);
                    }
                    else nowKey = 0;
                }

                if(!replayModeON) //키를 누른채로 replaymode로 변경하는 경우도 있어서 조건 걸어줌
                {
                    stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent,false,-1);
                    stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDownEvent,false,-1);
                }
            }

            updatePenCursorPosition();
        }

        private function keyDownEvent(e:KeyboardEvent):void//keydown1
        {
            const keyCode:uint = e.keyCode;
            if(nowKey !== 0)
            {
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDownEvent);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent);
                return;
            }

            if(captureModeON || keyCode === gKey.tab || fileDragSelectBox.visible === true || fillPenStarted) // pickerBoxON || penListBoxON ||
            {
                e.preventDefault();
                return;
            }
            else if(captureModeShortCutOFF)
            {
                captureModeShortCutOFF = false;
                return;
            }

            //저장 불러오기 단축키 먼저 체크
            if(e.shiftKey === true) //자툴이 있기 때문에 아래 return 해주지 않음
            {
                if(checkKeWhileShiftKey(keyCode) === true) return;
                //이 공간에서 리턴 해주면 안됨
            }

            if(e.controlKey === true || keyCode === 25 || keyCode === 17 || controlKeyON) //오른쪽 컨트롤키
            {
                checkKeWhileControlKey(keyCode);
                return;
            }

            if(e.altKey === true || keyCode === 18 || keyCode === 21)
            {
                if(keyCode === gKey.s)
                {
                    setCaptureReady();
                }
                return;
            }

            if(keyCode === gKey.f1)
            {
                setGridButton();
                topBar.hintTimeOff();
            }
            else if(keyCode === gKey.f2)
            {
                setSideBarPositionButton();
            }
            else if(keyCode === gKey.f3)
            {
                setUIColorButton();
                topBar.hintTimeOff();
            }
            else if(keyCode === gKey.n3 || keyCode === gKey.n9)
            {
                if(controlBox.pixelSnapButtonWrapper.alpha === 1.0)
                {
                    setPixelSnap(!pixelSnapON);
                }
                return;
            }
            else if(keyCode === gKey.n4 || keyCode === gKey.n0)
            {
                airBrushON = !airBrushON;
                setAirBrushCheckBox(airBrushON,true);
                return;
            }
            else if(keyCode === gKey.n5 || keyCode === gKey.minus)
            {
                if(controlBox.subLayerButtonWrapper.alpha === 1.0)
                {
                    setSubLayer(!subLayerON)
                }
                return;
            }
            //컨트롤 알트 스크롤락 makeSkipImage키등은 charcode가 없어서 그냥 리턴함
            //keyup에서 감지 못해서 에러남
            if(afterToolOff || (e.charCode === 0 && keyCode !== gKey.shift)) //줌 대기중일때 키 안먹게
            {//단축키는 놓았는데 mouse up이 되지 않아서 툴이 안꺼지면 리턴해줌
                return;
            }
            else if(lassoToolON === true)
            {
                if(lassoMenuTempOFF === true) return;
                // const keyco:uint = keyCode;
                if(checkKeyWhileLassoToolON(keyCode) === true)
                {
                    lassoMenuTempOFF = true;
                    lassoMenu.visible = false;
                    stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDownEvent);
                    stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownEvent);
                }
                return;
            }
            else if(fillPenStarted)
            {
                return;
            }

            checkToolKeyDown(keyCode);

            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDownEvent);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent);
        }

        private function closureCheckToolKeyDown():Function
        {
            return function(keyCode:int):void
            {
                nowKey = keyCode;
                
                switch (keyCode)
                {
                    case gKey.q:
                    case gKey.o:
                    {
                        nowToolBackup = nowTool;
                        selectFillPenTool();
                    }
                    break;

                    case gKey.t:
                    {
                        if(!traceMenuON) 
                        {
                            openTraceWindow();
                        }
                        else if(traceMenuON) 
                        {
                            closeTraceMenu();
                        }
                    }
                    break;

                    case gKey.n2:
                    case gKey.n8:
                    {
                        setReplayUI(true);
                    }
                    break;

                    case gKey.a:
                    case gKey.l:
                    {
                        mirrorCanvas();
                    }
                    break;


                    case gKey.c:
                    case gKey.m:
                    {
                        if(nowTool !== TOOL_SPUIT)
                        {
                            nowToolBackup = nowTool;
                            setSpuitTool();
                        }
                    }
                    break;

                    case gKey.r:
                    case gKey.y:
                    {
                        if(nowTool !== TOOL_LASSO)
                        {
                            selectLassoTool();
                        }
                    }
                    break;

                    case gKey.space:
                    {
                        if(nowTool !== TOOL_HAND)
                        {
                            nowToolBackup = nowTool;
                            nowTool = TOOL_HAND;
                        }
                    }
                    break;

                    case gKey.d:
                    case gKey.j:
                    {
                        if(nowTool !== TOOL_ERASE)
                        {
                            nowToolBackup = nowTool;
                            selectEraseTool();
                            updatePenSizeCursor();
                            stage.addEventListener(KeyboardEvent.KEY_DOWN, eraseKeyDownEvent);
                        }
                    }
                    break;

                    case gKey.x:
                    case gKey.comma:
                    {
                        setRedoButton();
                    }
                    break;

                    case gKey.z:
                    case gKey.dot:
                    {
                        setUndoButton();
                    }
                    break;

                    case gKey.s:
                    case gKey.k:
                    {
                        if(nowTool !== TOOL_ROTATE)
                        {
                            selectRotateTool();
                        }

                    }
                    break;

                    case gKey.e:
                    case gKey.u:
                    {
                        if(nowTool !== TOOL_MOVE)
                        {
                            selectMoveTool();
                        }
                    }
                    break;

                    case gKey.w:
                    case gKey.i:
                    {
                        if(nowTool !== TOOL_ZOOM)
                        {
                            selectZoomTool();
                        }
                    }
                    break;

                    case gKey.shift:
                    {
                        if(nowTool !== TOOL_LINE)
                        {
                            nowToolBackup = nowTool;
                            selectLineTool();
                            updatePenSizeCursor();
                        }
                    }
                    break;

                    case gKey.esc:
                    case gKey.del:
                    {
                        if(lassoToolON === false && nowTool !== TOOL_SPUIT)
                        {
                            setClearData(true);
                        }
                    }
                    break;
                }

                updatePenCursorPosition();
            }
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

        private function windowActiveEvent(e:Event):void
        {
            //알탭해주고 창 활성화 해줄때 한번은 안하게끔함
            startWorkingTimer();
            checkClipBoardImage();
            clearTimeout(clickBlockTimer);
            clickBlockTimer = setTimeout(function():void
            {
                clickBlockFlag = false;
            },150);
        }

        private function windowDeactiveEvent(e:Event):void
        {
            clickBlockFlag = true;
            clearInterval(workingTimer);

            if(nowKey != 0)
            {
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDownEvent,false,-1);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent,false,-1);
            }
            keyBufferArr = [];
            nowKey = 0;
            afterToolOff = false;
            shiftKeyON = false;
            controlKeyON = false;

            if(topBarHintClickEventON)
            {
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,topBarHintOFFEvent);
                topBarHintClickEventON = false;
                topBar.hintOFF();
            }

            if(toolBox2ON)
            {
                closeToolBox2();
            }

            //지우개나 라인툴에서 q키누르는거 대기하는 이벤트 제거
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,eraseKeyDownEvent);

            //라인툴에서 지우개 키 누르는 이벤트 제거
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
            toolBox2ON = false;
            toolBox2.visible = false;
            toolTipBox.visible = false;
            // if(toolBoxAlwaysON) toolBox.visible = true;
            
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,toolBox2MouseUpEvent);
            toolBox2.removeEventListener(MouseEvent.MOUSE_DOWN,toolBox2MouseDownEvent);
            stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownEvent);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent,false,-1);
        }

        //툴메뉴에서 클릭했을때
        private function toolBox2MouseDownEvent(e:MouseEvent):void
        {
            const target:SimpleButton = e.target as SimpleButton;
            if(!target) return;
            const targetName:String = target.name;

            if(targetName === "toolZoom")
            {
                toolBox2ToolClicked = true;
                updateToolBoxMousePos(target);
                closeToolBox2();
                setZoomTool();
            }
            else if(targetName === "toolMove")
            {
                toolBox2ToolClicked = true;
                updateToolBoxMousePos(target);
                closeToolBox2();
                setMoveTool();
            }
            else if(targetName === "toolRotate")
            {
                toolBox2ToolClicked = true;
                updateToolBoxMousePos(target);
                closeToolBox2();
                setRotateTool();
            }
            else if(targetName === "toolInfo" || targetName === "toolBoxMoveButton")
            {

            }
            else
            {
                updateToolBoxMousePos(toolBox2.toolPen);
                closeToolBox2();

                if(nowTool !== TOOL_HAND)
                {
                    nowToolBackup = nowTool;
                }
                nowTool = TOOL_HAND;
            }
        }

        //툴메뉴 오른쪽 클릭 땠을때
        private function toolBox2MouseUpEvent(e:MouseEvent):void
        {
            penCursorOFFFlag = false;
            if(lassoToolON === true)
            {
                closeToolBox2();
                return;
            }

            const targetName:String = e.target.name;

            if(targetName !== null && targetName.indexOf("tool") !== -1)
            {
                const target:SimpleButton = e.target as SimpleButton;
                updateToolBoxMousePos(target);
            }

            switch(targetName)
            {
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
                    if(nowTool !== TOOL_SPUIT)
                    {
                        nowToolBackup = nowTool;
                    }
                    setSpuitTool();
                }
                break;
                case "toolUndo":
                    setUndoButton();
                break;
                case "toolRedo":
                    setRedoButton();
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

        private function setLasso1PxMoveButton(command:String):void
        {
            const m:Number = 1/zoomed;
            const rotate:Number = regPoint.rotation;
            var x:Number = 0;
            var y:Number = 0;

            if(command === "up") y = -1;
            else if(command === "down") y = 1;
            else if(command === "left") x = -1;
            else if(command === "right") x = 1;

            const r:Point = rotatePoint(x,y,rotate);

            lassoBox.x += r.x;
            lassoBox.y += r.y;
        }

        private function lassoToolKeyDownEvent(e:KeyboardEvent):void
        {
            if(lassoMenuTempOFF === true) return;
            const keycode:uint = e.keyCode;

            if(keycode === gKey.up)
            {
                setLasso1PxMoveButton("up");
                checkLassoMenuPos();
            }
            else if(keycode === gKey.down)
            {
               setLasso1PxMoveButton("down");
                checkLassoMenuPos();
            }
            else if(keycode === gKey.left)
            {
                setLasso1PxMoveButton("left");
                checkLassoMenuPos();
            }
            else if(keycode === gKey.right)
            {
                setLasso1PxMoveButton("right");
                checkLassoMenuPos();
            }
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

                stage.removeEventListener(MouseEvent.MOUSE_MOVE,sideBarMouseMoveEvent);
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
            stage.addEventListener(MouseEvent.MOUSE_MOVE,sideBarMouseMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,sideBarMouseUpEvent);
        }

        private function checkToolBoxButtons(targetName:String):Boolean
        {
            if(nowKey !== 0) return true;

            const _toolBox:toolButtons = toolBox;

            if(lassoToolON === false)
            {
                stage.addEventListener(MouseEvent.MOUSE_UP,checkToolBoxButtonUpEvent);
            }

            switch(targetName)
            {
                case "toolRotate":
                {
                    setRotateTool(false);
                }
                break;


                case "zoomInButton":
                case "zoomOutButton":
                {
                    toolBoxAlwaysClickTool = targetName;
                    setTopChildIndex(_toolBox);
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
                {
                    setTopChildIndex(_toolBox);
                    toolBoxAlwaysClickTool = targetName;
                    return true;
                }

                return false;
            }
            return false;
        }

        private function setCanvasResizeButton(target:canvasResizeButton):Boolean
        {   
            penCursorOFFFlag = true;
            toolTipBox.visible = true;
            penSizeCursor.visible = false;
            setToolTipString(CANVAS_WIDTH+" x "+CANVAS_HEIGHT);

            setCanvasSize(target.name);
            return true; //밑에 tool이 실행되기 때문에 조건 만족할때만 return해야함
        }

        private function checkReplaySpeedState():void
        {
            const floor:Function = Math.floor;
            const maxf:Number = TOTAL_FRAME;
            const rf:Number = rFrameSum;
            const bw:Number = replayTimeBox["replayTotalBar"].width;

            replayTimeBox["frameInfo"].text = rf+" / "+maxf;
            replayTimeBox["replayNowBar"].width = (maxf === 0) ? 0 : bw*(rf/maxf);

            if(maxf < STAGE_FRAME*3) topBar["replaySpeedSet"].alpha = BUTTON_OFF_ALPHA;
            else topBar["replaySpeedSet"].alpha = 1.0;
            //리플레이 속도를 최고 빠르게 했을때 시간 체크
            REPLAY_FASTEST_TOTAL_TIME = floor(maxf/(REPLAY_MAX_SPEED*STAGE_FRAME));
        }

        private function resetKeyBuffer():void
        {
            keyBufferArr = [];
            nowKey = 0;
            rNowKey = 0;
            shiftKeyON = false;
            repSpaceKeyON = false;
            controlKeyON = false;
        }

        private function setReplayUI(flag:Boolean):void
        {
            const iFlag:Boolean = !flag;

            replayModeON = flag;
            penCursorOFFFlag = flag;
            rregPoint.visible = flag;
            regPoint.visible = iFlag;
            resizeButtonR.visible = iFlag;
            resizeButtonL.visible = iFlag;
            resizeButtonD.visible = iFlag;
            resizeButtonU.visible = iFlag;
            replayTimeBox.visible = flag; //탐색바 켜줌
            rCursor.visible = flag;
            replayTimeBox["pauseButton"].visible = false;
            setTopChildIndex(replayTimeBox);
            resetCutFrameClickCounter();
            topBar.hintOFF();
            resetKeyBuffer();

            if(iFlag) //리플레이 꺼줄때
            {
                clearDataButtonCount = 0;

                if(isSidebarVisible === true) sideBar.visible = true;
                if(replayStartON === true) stopReplay();

                rSkipLastIndex = -2;//스킵 이미지 인덱스 원래대로 되돌려줌
                setResizeButtonVisible(true);
                removeReplayMainEvent();
                updatePreviewCursorPos();
                changePickerModeToNormal();
                rDataPreviewCacheImages = [];

                if(traceMenuON === true)
                {
                    traceMenuBox.visible = true;
                }

                changeTopBarIcons("draw");
                addMainEvent();

                appInfoBox.insertCanvasInfo([null,null,Math.floor(zoomed*100),null]);
            }
            else if(flag) //리플레이 켜줄때
            {
                sideBar.visible = false;
                rCursor.visible = false;
                setTopChildIndex(rCursor);
                removeMainEvent();

                TOTAL_FRAME = getTotalFrame();
                checkReplaySpeedState();

                //frame sum이 재계산된 maxframe을 넘어가면 리플레이 프레임이 넘어가기 때문에 끝난거임
                //그래서 캔버스 복사해주고 리플레이를 리셋해줌
                if(rSkipImageInit === 0)
                {
                    const _rregPoint:Sprite = rregPoint;
                    
                    if(CANVAS_WIDTH === RCANVAS_WIDTH && CANVAS_HEIGHT === RCANVAS_HEIGHT)
                    {
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
                    else
                    {
                        canvasFitWindow();
                        rzoomed = 1;
                        _rregPoint.scaleX = 1;
                        _rregPoint.scaleY = 1;
                        rzoomedIndex = zoomArr.indexOf(rzoomed);
                    }
                }

                checkCutFrameButtons();
                updateReplayBarPos(stage.stageWidth,stage.stageHeight);
                updateReplayCanvasBounds();
                topBar.resetHintColor();

                if(traceMenuON === true)
                {
                    traceMenuBox.visible = false;
                }

                changeTopBarIcons("replay");

                if(rSkipImageInit === 1)
                {
                    setTimeout(function():void
                    {
                        makeSkipImage();
                    },100);
                }
                else if(rSkipImageInit === 0)
                {
                    const totalFrame:Number = TOTAL_FRAME;
                
                    if(replayONUndoUpdate)
                    {
                        rDataReadFlag = false;
                        replayTimeBox["frameInfo"].text = totalFrame+" / " + totalFrame;
                        replayTimeBox["replayNowBar"].width = (totalFrame === 0) ? 0 : replayTimeBox["replayTotalBar"].width;
                        clearCanvasReplayMode();
                        resetReplayTime();
                        rFrameSum = totalFrame;
                        rFrameSumLast = totalFrame-1;

                        rcanvas1BitmapData.dispose();
                        rcanvas1BitmapData = canvas1BitmapData.clone();
                        rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                        setPanelSizeReplayMode(canvas1Bitmap.width,canvas1Bitmap.height);
                        setBackgroundColor(CANVAS_BG_COLOR,true);
                    }

                    checkCanvasPanelPos(flag);
                    addReplayMainEvent();
                }
            }
        }

        private function mouseUpReplayModeEvent(e:MouseEvent):void
        {
            mouseClickON = false;
            stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpReplayModeEvent);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownReplayModeEvent);
        }

        private function mouseDownReplayModeEvent(e:MouseEvent):void //repdown1
        {
            if(mouseClickON || clickBlockFlag)
            {
                return;
            }

            mouseClickON = true;

            stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpReplayModeEvent);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownReplayModeEvent);

            const target:DisplayObject = e.target as DisplayObject;
            const targetName:String = target.name;

            //캡쳐 모드가 먼저 여야함
            if(captureModeON)
            {
                if(!(targetName === "capRotate" || targetName === "capFlip" || targetName === "capFull" || targetName === "capOff" || targetName === "capTrans"))
                {
                    drawCaptureArea.start(true);
                    return;
                }
            }

            if(targetName && (targetName.indexOf("rcanvas") !== -1 || targetName === "stageBG"))
            {
                setHandTool(true);
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
                    setRotateTool(true);
                }
                break;

                case "replaySpeedBarWrapper":
                {
                    setReplaySpeedButton();
                }
                return;

                case "replayNowBar":
                case "replayTotalBar":
                case "frameInfo":
                {
                    setSkipFrameButton();
                }
                break;

                case "replayPrev":
                {
                    setSkipOneFrame(true,false,e.shiftKey);
                }
                break;

                case "replayNext":
                {
                    setSkipOneFrame(false,false,e.shiftKey);
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
                    if(nowKey !== 0)
                    {
                        return;
                    }

                    checkButtonUp(targetName);
                }
                return;
            }
        }

        private function mouseUpEvent(e:MouseEvent):void //mouseup1
        {
            mouseClickON = false;

            if(afterToolOff)//단축키 떼고 마우스 땠을때 원래대로 돌림
            {
                afterToolOff = false;
                setPrevTool();

                if(keyBufferArr.length > 0)
                {
                    const nextKey:int = keyBufferArr.shift();
                    checkToolKeyDown(nextKey);
                }
                else
                {
                    nowKey = 0;
                }
            }

            //키가 눌려있지 않을때만 해줌 이벤트 추가
            if(nowKey === 0 && !replayModeON)
            {
                stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent,false,-1);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDownEvent,false,-1);
            }
            stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpEvent);
        }

        private function rightMouseDownReplayModeEvent(e:MouseEvent):void
        {
            if(captureModeON || rNowKey !== 0)
            {
                return;
            }
            const targetName:String = e.target.name;

            if(targetName === "repSaveButton")
            {
                saveFile(true);
            }
            else if(targetName === "replayPrev")
            {
                setSkipOneFrame(true,false,true);
            }
            else if(targetName === "replayNext")
            {
                setSkipOneFrame(false,false,true);
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
            setTopChildIndex(_toolBox2);

            stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownEvent);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,toolBox2MouseUpEvent);
            _toolBox2.addEventListener(MouseEvent.MOUSE_DOWN,toolBox2MouseDownEvent);
        }

        private function rightMouseDownEvent(e:MouseEvent):void //rdown1
        {
            if(captureModeON || lassoToolON)
            {
                return;
            }

            const targetName:String = e.target.name;

            if(targetName === "saveButton")
            {
                saveFile(true);
            }
            else if(targetName === "loadButton")
            {
                loadFile(true);
            }
            else
            {
                if(fillPenStarted === true)
                {
                    setFillPenTool.ok();
                }
                else if(targetName && (targetName.indexOf("canvas") !== -1 || targetName === "stageBG" || targetName === "canvasGrid"))
                {
                    openToolBox2();
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
                    setSizeButton2(targetName);
                }
                return true;

                case "shapeRect":
                {
                    setShapeButton(true);
                }
                return true;
                
                case "shapeCircle":
                {
                    setShapeButton(false);
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
                    if(isPenTool())
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

            if(toolBox2ON || (nowKey !== 0 && nt !== TOOL_FILL_PEN
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
                    pickHistoryColor();
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

        private function checkLassoToolButtons(targetName:String):void
        {
            switch(targetName)
            {
                case "lassoMove":
                {
                    setLassoMoveButton();
                }
                break;

                case "lassoResize":
                {
                    setLassoResizeButton();
                }
                break;

                case "lassoRotate":
                {
                    setLassoRotateButton();
                }
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
                    setRotateTool();
                }
                break;

                case "lassoCZoom":
                {
                    lassoMenu.visible = false;
                    lassoMenuTempOFF = true;
                    setZoomTool();
                }
                break;

                case "lassoCHand":
                {
                    lassoMenu.visible = false;
                    lassoMenuTempOFF = true;
                    setHandTool(false);
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

                case "lasso1pxLeft":
                {
                    setLasso1PxMoveButton("left");
                }
                break;
                case "lasso1pxRight":
                {
                    setLasso1PxMoveButton("right");
                }
                break;
                case "lasso1pxUp":
                {
                    setLasso1PxMoveButton("up");
                }
                break;
                case "lasso1pxDown":
                {
                    setLasso1PxMoveButton("down");
                }
                break;

                case "lassoCopy":
                {
                    setLassoCopyButton();
                }
                break;

                case "lassoOK":
                case "lassoCancel":
                {
                    checkButtonUp(targetName);
                }
                break;
            }
        }

        private function mouseDownEvent(e:MouseEvent):void
        {
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDownEvent);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,mouseUpEvent,false,-1);

            const target:DisplayObject = e.target as DisplayObject;
            const targetName:String = target.name;

            mouseClickON = true;

            if(toolBox2ToolClicked)
            {
                toolBox2ToolClicked = false;
                return;
            }

            if(fillPenStarted === true) 
            {
                return;
            }
            else if(lassoToolON && !lassoMenuTempOFF)
            {
                checkLassoToolButtons(targetName);
                return;
            }
            else if(captureModeON)
            {
                switch(targetName)
                {
                    case "capRotate":
                    case "capFlip":
                    case "capFull":
                    case "capOff":
                    case "capTrans":
                    break;

                    case "timer":
                    {
                        resetTimer();
                    }
                    return;

                    default:
                        if(clickBlockFlag === false)
                        {
                            drawCaptureArea.start(false);
                        }
                    return;
                }
            }
            else if(sideBar.visible && sideBarScrollSet.hitTestPoint(mouseX,mouseY,true))
            {
                if(checkPickerBoxButtons(target) && nowKey === 0) 
                {
                    return;
                }
                else if(checkControlBoxButtons(target) && (isPenTool() || isEraseTool())) 
                {
                    return;
                }
                else if(checkToolBoxButtons(targetName)) 
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
                case "capOff":
                case "capFull":
                case "capFlip":
                case "capTrans":
                case "capRotate":
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
                    if(toolBox2ON || lassoToolON || fillPenStarted || nowKey !== 0 || e.target.alpha < 1.0)
                    {
                        return;
                    }

                    checkButtonUp(targetName);
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

                case "resizeButtonR":
                case "resizeButtonD":
                case "resizeButtonL":
                case "resizeButtonU":
                {
                    //오른쪽 클릭에서 ent채워주면 그냥 리턴해야함
                    //안해주면 캔버스 조절할때 펜이 캔버스에 그어짐
                    if(!lassoToolON)
                    {
                        if(setCanvasResizeButton(target as canvasResizeButton) === true)
                        {
                            return;
                        }
                    }
                }
                break;

                case "traceInfo":
                case "traceMenuMoveButton":
                {
                    moveToolBoxByType(2);
                }

                case "dragDropFileBG":
                return;

                return;
            }

            //캔버스 영역 밖에서는 해주지 않음
            const mx:Number = mouseX;
            const my:Number = mouseY;

            if(mx <= STAGE_LEFT_OFFSET || mx >= stage.stageWidth -STAGE_RIGHT_OFFSET
            || my <= STAGE_TOP_OFFSET  || my >= stage.stageHeight-STAGE_BOTTOM_OFFSET
            || clickBlockFlag === true)
            {
                return;
            }

            switch (nowTool)
            {
                case TOOL_FILL_PEN:
                    setFillPenTool.start();
                break;

                case TOOL_PEN:
                    setPenTool(true);
                break;

                case TOOL_ERASE:
                    setPenTool(false);
                break;

                case TOOL_LINE:
                    setLineTool(true);
                break;

                case TOOL_HAND:
                    setHandTool();
                break;

                case TOOL_LASSO:
                    setLassoTool();
                break;

                case TOOL_ROTATE:
                    setRotateTool();
                break;

                case TOOL_ZOOM:
                    setZoomTool();
                break;

                case TOOL_MOVE:
                    setMoveTool();
                break;
            }
        }
    }
 }
