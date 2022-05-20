package
{
    import flash.desktop.*;
    import flash.display.*;
    import flash.filesystem.*;
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
    import flash.filters.ConvolutionFilter; // import end ConvolutionFilter가 끝임
    
    public class Main extends Sprite
    {   
        private const APP_VERSION:Number = 11.55;
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
                                        lalt:18, //as에서는 한글모드 관계 없이 왼쪽 오른쪽 전부 18번임
                                        ctrl:17,
                                        shift:16,
                                        space:32,
                                        enter:13,
                                        esc:27,
                                        del:46,
                                        tab:9,
                                        n1:49,
                                        n2:50,
                                        n6:54,
                                        n7:55,
                                        n8:56,
                                        left:37,
                                        up:38,
                                        right:39,
                                        down:40,
                                        f1:112,
                                        f2:113,
                                        f3:114,
                                        f4:115,
                                        f5:116,
                                        f6:117
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
                    ,TOOL_LINE_ERASE:int = 4
                    ,TOOL_HAND:int = 5
                    ,TOOL_LASSO:int = 6
                    ,TOOL_SPUIT:int = 7
                    ,TOOL_ZOOM:int = 8
                    ,TOOL_ROTATE:int = 9
                    ,TOOL_MOVE:int = 10
                    ,STAGE_FRAME:int = stage.frameRate

                    ,CANVAS_MIN_SIZE:int = 100
                    ,CANVAS_MAX_SIZE:int = 2000
                    ,BUTTON_OFF_ALPHA:Number = 0.15
                    ,COLOR_DARK:uint = 0x323232//어두운색
                    // ,COLOR_MID_DARK:uint = 0x666666//중간 어두운색
                    ,COLOR_MID_DARK:uint = 0x5B5B5B//중간 어두운색
                    ,COLOR_MID_BRIGHT:uint = 0xB8B8B8//중간 밝은색
                    ,COLOR_BRIGHT:uint = 0xF0F0F0//0xECEAE7//밝은색
                    ,AFK_TIME_OUT:int = 20
                    ,GC_TIME_OUT:int = 60*5 //5분마다

        private var  RESIZE_BUTTON_COLOR:uint = 0xA5A5A5
                    ,STAGE_BG_COLOR:uint = 0xCCCCCC
                    ,CANVAS_BG_COLOR:uint = 0xFFFFFF
                    ,RCANVAS_BG_COLOR:uint = 0xFFFFFF
                    ,CANVAS_WIDTH:Number = 600
                    ,CANVAS_HEIGHT:Number = 390
                    ,RCANVAS_WIDTH:Number = 600
                    ,RCANVAS_HEIGHT:Number = 390
                    ,APP_RUNNING_TIME:Number = 0 //앱 실행시간
                    ,TOP_OFFSET:Number = 0 //창 상하좌우 여백
                    ,LEFT_OFFSET:Number = 0
                    ,BOTTOM_OFFSET:Number = 0
                    ,RIGHT_OFFSET:Number = 0

        //element
        //완전 투명 배경색은 ARGB순임
        private const canvas1Bitmap:Bitmap = new Bitmap(canvas1BitmapData,"auto",true)
                    ,canvas2Bitmap:Bitmap = new Bitmap(canvas2BitmapData,"auto",true) //move할때 임시로 넣어주는 캔버스

        private const resizeButtonR:Sprite = new Sprite()//캔버스 리사이즈 하는 버튼
                    ,resizeButtonD:Sprite = new Sprite()
                    ,resizeButtonL:Sprite = new Sprite()
                    ,resizeButtonU:Sprite = new Sprite()
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
                    // ,penSizeCursor2:Shape = new Shape() //펜사이즈 미리 보기
                    // ,penSizeCursor3:Shape = new Shape() //펜사이즈 미리 보기
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
                    // ,canvasTransBMP:canvasTransPanel = new canvasTransPanel()
                    ,fileDragSelectBox:loadBox = new loadBox()
                    ,controlBox:controlMenu = new controlMenu()
                    ,pickerBox:colorPickerBox = new colorPickerBox()
                    ,appInfoBox:appInfoBar = new appInfoBar()
                    ,previewBox:previewPanel = new previewPanel()
                    ,sideBar:sidePanel = new sidePanel()
                    ,consoleBox:consolePanel = new consolePanel()
                    ,transBGBMPD:BitmapData = new BitmapData(16,16,false,0xFFFFFF);
                     //draw var
        private var canvas1BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,canvas2BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,lassoBMP:Bitmap = new Bitmap()
                    ,shiftKeyON:Boolean = false
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
                    ,mouseClickPos:Vector.<Number> = new Vector.<Number> (2,true) //함수간에 통신 전역으로 쓰고 싶을때, 클릭한 자리 저장
                    ,afterToolOff:Boolean = false //키 떼기 전에 마우스 먼저 떼주었을때 플래그 올려줌
                    ,penAlpha:Number = 1.0 //펜 변수
                    ,penColor:uint = 0x000000
                    ,penColorBackup:uint = 0x000000
                    ,sizeOffsetFlag:Boolean = false//0.5픽셀 이동이면 true임 pensizecursormove함수에서 써줌
                    ,sizeArr:Array = [0,1,2,3,4,5,7,10,15,25,35,50,150]
                    ,alphaArr:Array = [0.25,0.5,0.75,1.0]
                    ,penSize:uint = 3
                    ,penSizeIndex:uint = 3
                    ,penAlphaIndex:uint = 3
                    ,penShape:Boolean = false //false 이면 원 true 이면 사각형
                    ,penSmoothValue:Number = 0 //펜 손떨방 플래그
                    ,penSmoothSlideValue:Number = 0 //펜 손떨방 플래그
                    ,penSmoothSlideTotal:Number = 20 //손떨방 총 단계
                    ,penSmoothButtonX:Number = 70 //손떨방 조절 버튼 초기 위치
                    ,pixelSnap:Boolean = false //0.5픽셀어긋나게 안하고 완전히 정확하게 할때씀
                    ,fillPenON:Boolean = false //채우기 펜 플래그
                    ,subLayerON:Boolean = false
                    // ,penFillCursorON:Boolean = false //update cursor size에서 중복 막는 if를 넘어가기 위해서 채우기펜 커서를 인지 아닌지 체크해주는 플래그

                    // ,penSmoothTimer:uint = 0 //펜 손떨방 타이머 저장소
                    ,eraseOddOffset:Number = 0//지우개 변수
                    ,eraseSize:uint = 12
                    ,eraseSizeIndex:uint = 8
                    ,eraseShape:Boolean = false
                    ,eraseAlpha:Number = 1.0
                    ,eraseAlphaIndex:uint = 3
                    ,penListShapeFlag:Boolean = false //펜 리스트에서 펜 모양 버튼 눌러줄때 툴이랑 상관없이 바꿔줌, 펜 미리보기 할때 필요
                    ,lastUpdateInfo:Array = [null,null,null,null,null,null] //updatePenSizeCursor 중복 사용 방지를 위해서 마지막 크기 저장해놓고 같으면 건너뙴
                    // ,penAlphaPrevTimer:uint = 0
                    ,resizeButtonActive:Boolean = false ///캔버스 리사이즈 버튼 클릭했을때 올려줌
                    ,addUndoMode:uint = 0 //addundo했을때 캔버스 이동 리사이즈, 배경색 변경 등 중복되는거 체크하는것임.

        //컬러픽커 관련 변수
                    // ,colorBarWidth:Number = pickerBox.rectSize//hue s v 컬러픽커 초기값
                    // ,colorBarHeight:Number = pickerBox.rectSize2//colorpickerbox 클라스 참고
                    // ,hueBarWidth:Number = colorBarWidth //huecolor가 초기값이 정확이 361이 아니라서 그냥 따로 변수로 조절해줌
                    ,HUECOLOR:Vector.<Number> = new Vector.<Number> (3,true) //hue컬러 다른 함수들이랑 통신하기 위해서 전역으로 만들어줌
                    ,pickerBoxColorBackup:uint = 0 //컬러 픽커 켜질때 원래 색깔 저장하는 곳
                    ,changedColor:int = -1 // 컬러 히스토리에서 고른 색깔을 여기다가 넣어줌
                    ,pickerMode:uint = 1
                    // ,pickerBoxON:Boolean = false
                    ,pickerOpaClicked:Boolean = false //피커박스에서 투명도 조절했을때 올려줌 mouse out 이벤트 하나만 작동되게 할라고
                    ,pickerColorSelected:Boolean = false //피커박스에서 컬러를 한번이라도 조절했으면 올려줌
                    // ,pickerLastHint:String = "" //피커박스 마지막 힌트 저장해줌

        //툴메뉴 관련 변수
        //어디 클릭했는지 위치 저장해줘서 다음에 켰을때 그 위치에서 툴메뉴가 켜지게끔 해줌
                    ,toolBoxLastClickPos:Vector.<Number> = new Vector.<Number> (2,true)//툴박스 마지막 위치 저장
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
                    ,lastWindowSize:Vector.<Number> = new Vector.<Number> (2,true) //창크기 조절 얼마나 됐을지 비교할때 마지막 크기 창크기 저장
                    ,reizeButtonClickEnt:Sprite

        //save load 관련 변수
                    ,saveOneTime:Boolean = false //세이브 버튼 여러번 눌러서 데이터 계속 쓰여지는거 방지
                    ,saveFileName:String = "untitled.png"//세이브 파일 저장후에 이름을 이쪽에다가 보관해서 계속 그 이름으로 저장할수있게함
                    ,saveFilePath:String = saveFileName//파일 저장경로로 계속 저장 초기에는 filename이랑 똑같게 해줌
                    ,saveContinue:Boolean = false//한번 저장후에 다른이름으로 저장하기 전까지는 똑같은 이름으로 저장
                    ,clearDataButtonCount:uint = 0 //리플레이 취소 카운터

        //컬러 히스토리 관련 변수
                    ,colorHistoryList:Array = [0xFFFFFF,0x000000]
                    ,colorHistoryLimit:uint = 20
                    ,colorHistoryColorWidth:uint = 17//Math.floor(pickerBox.svBoxWidth/colorHistoryLimit)//히스토리 개별 색깔 가로 크기
                    ,colorHistoryRectH:uint = 19
                    ,colorHistoryIndex:uint = 1 //선택된 컬러 list의 인덱스
                    ,colorHistoryUpdateReady:Boolean = false //히스토리 업데이트 이벤트 추가되면 올려주는거
                    ,colorHistoryUpdateBGReady:Boolean = false //히스토리 업데이트 이벤트 추가되면 올려주는거

        //툴팁 관련 변수
                    // ,toolTipText:Object = toolTipBox["toolTipInfoText"]
                    // ,toolTipTextBG:Object = toolTipBox["toolTipBoxBG"]
                    ,toolTipHint:String = "" //topbar관련 힌트 여기 저장
                    ,toolTipBoxTimer:uint = 0

        //리플레이 관련 변수
        private const appDataFile:File = File.applicationStorageDirectory.resolvePath("appdata1068.301")
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
                    ,IMG_CACHE_INTERVAL:uint = 15000
                    ,REPLAY_MAX_SPEED:Number = 300
                    ,REPLAY_SPEED_DIST:Number = 180
                    ,rCursor:SimpleButton = new tinyCursor(); //재생할때 틀어주는 작은 마우스

        private var rcanvas1BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,rcanvas2BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,replayStartON:Boolean = false //리플레이 시작버튼 여러번 누르는거 방지
                    ,replayAllEnd:Boolean = true //리플레이가 자연히 끝났을때 올렽주는 플래그 가장 처음에 캔버스 싹쓸이 하기 위해서 넣어줌.
                    ,replayEndWithcanvasFitWindow:Boolean = false //리플레이가 follow cursor옵션으로 캔버스 작게 축소되서 끝났을때
                    ,replayModeON:Boolean = false //이건 모드 자체 껐다 켰다
                    // ,replayModeONFirstSkip:Boolean = false//리플레이 키고 나서 바로 프레임스킵 하거나 리플레이 재생이 다끝났을때 올려줌, 스킵할때 리플레이 캔버스 모두 지워주는 플래그

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
                    ,rFirstImage:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0)
                    ,rFirstBGColor:uint = CANVAS_BG_COLOR
                    ,rzoomed:Number = 1.0 //리플레이 줌
                    // ,rRotateToolON:Boolean = false //리플레이에서 줌툴
                    ,rSkipLastIndex:Number = -2 //썸네일 인덱스 바뀌면 여기다 저장
                    ,rSkipImageFrameData:Array = [0] //스킵이미지 저장될때 r file frame sum을 저장해줌 처음에 rfirstimage라서 0번 추가해줌
                    ,rSkipImageCount:uint = 0//데이터로 저장할때  rDataFrame 카운터 누적
                    ,rSkipImageInit:int = 0 //0이상이면 make skip image함수를 실행함. skipframe함수에서 체크
                    ,rOneSkipFlag:Boolean = false //oneskipframe에서 prev인지 next인지 마지막 상태 저장해줌, 방향바꿀대 버튼 2번씩 눌러야 스킵되는거 방지하는거임
                    ,rOneSkipTimer:int = 0 //키 오래 누르고 있으면 한꺼번에 처리해주는 타이머
                    ,rOneSkipPrevSum:Number = 0 //뒤로 스킵키 오래누르고 있으면 프레임 합산은 여기다가 올려줌
                    ,replayONUndoUpdate:Boolean = false//undo가 된 상태에서 리플레이 켜줄때 file까지만 읽은 상태까지 프레임 스킵 해주는
                    ,rRestartTimer:uint = 0 //리스타트 타이머
                    ,rRestartTimerCount:uint = 0 //리스타트 타이머
                    ,rFrameTextDelayTime:int = 0 //frame 정보 보여주는거 갱신마다 해주지 말고 일정시간마다 갱신해주는 시간 저장하는 변수
                    ,rFrameCursorDelayTime:int = 0 //커서 느리게 해줌
                    ,rCanvasBounds:Object = null
                    ,REPLAY_FASTEST_TOTAL_TIME:Number = 0 //최고 배속으로 돌렸는데도 총 재생시간이 30초 이상이면 올려줌
                    ,REPLAY_SLOWDRAW_ACTIVE_SPEED:Number = 80 //이 배속 이상일경우 doDrawSlowEvent를 걸어줌
                    ,doDrawSlowEventON:Boolean = false //doDrawSlowEvent가 켜지면 올려줌
                    ,rSkipMouseON:Boolean = false //스킵프레임 마우스로 할때 올려줌 dodraw에서 바조절 안되게 하려고 하는거임
                    ,rDataPreviewCacheImages:Array = [] //이전 탐색 프레임 빠르게 하기 위해서 skipimage구간에서 더 잘게 이미지를 나누어주고 정보를여가다가 저장함
                    ,rSpeedLastStr:String = ""
                    // ,rReplay30Fps:Boolean = false

        //about 관련 변수
                    ,aboutPanelON:Boolean = false //어바웃 창 떴을때 킴
                    ,needUpdate:int = 0 //새버전 나왔을때 올려주는 플래그

        //cut Frame 관련 변수
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
                    // ,captureTransBGButton:SimpleButton
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
                    ,traceVisibleFlag:Boolean = false // 이거 켜지면 캔버스 그릴때 임시적으로 안보이게함
                    ,traceLastAlpha:Number = 0
        //그리드 레이어 변수 
                    ,canvasGrid:Sprite = new Sprite()//트레이스 레이어임
                    ,gridFlag:uint = 0
                    ,GRID_GAP:uint = 30
                    ,GRID_NORMAL_COLOR:uint = 0xBABABA
                    ,GRID_5UNIT_COLOR:uint = 0x515151

        //기타
                    ,windowClosingFlag:Boolean = false//윈도우 닫힐때 올려줌 save all data가 windows closing일때는 무조건 해주게 끔함
                    ,windowDeactivateTime:int = 0 //윈도우 비활성화된 시간 저장, 너무 자주 알탭해서 save all data가 자주 호출되는걸 막음
                    ,clearDataFileNameCount:uint = 0
                    ,penCursorOFFFlag:Boolean = false //펜커서 이게 on되면 안보여줌
                    ,altCursorON:Boolean = false //키보드로 커서 변경해줄때 마지막 커서 색깔이 뭐였는지 저장
                    ,keybufferArr:Array = [] //정식 키 다운 눌러준 상태에서 다른 키가 눌러져 있으면 여기다가 저장
                                             
                    ,uiColorIndex:int = 1
                    ,uiColorSet:Array = [//주 컬러, 주컬러 반대색, stage배경색, 캔버스 조절 막대 색, //툴박스 
                                                [COLOR_DARK,0xE5E5E5,0x4B4B4B,0x676767], 
                                                [COLOR_MID_DARK,COLOR_BRIGHT,0x888888,RESIZE_BUTTON_COLOR],
                                                [COLOR_MID_BRIGHT,0x505050,0xC9C9C9,0xB0B0B0],
                                                [COLOR_BRIGHT,0x505050,0xE1E1E1,0xCBCBCB],
                                            ]
                    ,uiToolBoxColorSet:Array =
                    [ //컬러 셋 이름,윗부분 막대색, 전체 배경색, upstate왼쪽아이콘색, update오른쪽 아이콘색, overstate 버튼배경색 overstate 아이콘색
                        [COLOR_DARK,0x434343,0xE5E5E5,0xE5E5E5,0x6E98B4,0xE5E5E5],
                        [COLOR_MID_DARK,0xE3E3E1,0xE3E3E1,COLOR_MID_DARK,0xB1DFEE,COLOR_MID_DARK],
                        [COLOR_MID_BRIGHT,0xD6D5D4,0x505050,0x505050,0xBADAE5,0x505050],
                        [COLOR_BRIGHT,0xE7E7E7,0x666666,0x666666,0xCEEBF2,0x666666]
                    ]

                    ,tempDragDropFile:Object = []
                    ,tempCopiedImage:BitmapData
                    ,selectedNewPenSizeButtonIndex:int = 3
                    ,penSizePrevOFFTimer:int = 0
                    ,topBarON:int = 0  //topmenu가 보였을때
                    ,eraseMovedButton:SimpleButton = null //툴 선택해줬을때 지우개툴이 이동한 툴을 저장해줌 다시원래대로 복원해주려고
                    ,toolBox2ToolClicked:Boolean = false //툴박스에서 줌 이동 회전툴 클릭해주었을때 올려줌
                    ,zoomToolHintON:Boolean = false //툴박스에서 마우스 클릭해서 줌툴써줄때 mouse out이벤트가 가장 늦게 되서 줌 배율 힌트가 처음에 보이지 않는거 해결
                    ,controlBoxHintTimer:uint = 0 //컨트롤 박스 힌트 타이머 스무딩 힌트 일시적으로 보여줄때 사용
                    ,updateManualTimer:int = 0
                    ,clickBlockFlag:Boolean = false //알탭 하고나서 창활성화 되면 일정시간동안 작동하지 않게함
                    ,clickBlockTimer:int = 0 //비활성에서 활성화 될때 약간의 텀을주는 타이머
                    ,penSizeOpaKeyUpEventON:Boolean = false //펜 투명도 사이즈 단축키로 조절시 올려줌
                    ,isRightSidebar:Boolean = false // 사이드바 위치 0이 왼쩾 1이 오른쪽
                    ,mouseMoveEventLastTime:int = 0
                    ,mouseMoveEventTimeLimit:int = 3
                    ,mouseMoveEventTimeLimitCount:int = mouseMoveEventTimeLimit
                    ,windowResizeDelayTimer:int = 0
                    ,topBarHintClickEventON:Boolean = false //톱바 힌트가 켜졌을때 클릭하면 지워주는 이벤트
                    ,afkONCount:int = 0
                    ,gcONCount:int = 0
                    ,workingTimer:int = 0
                    ,penCursorCheckTimer:int = 0
                    ;
                     
        public function Main():void //main1
        {
            this.addEventListener(Event.ADDED_TO_STAGE, init);
        }

        // private function printColorInfo(x:Number,y:Number):void //init1
        // {
        //     const c:uint = canvas1BitmapData.getPixel32(x,y);
        //     const a:uint = (c & 0xFF000000) >>> 24;
        //     const r:uint = (c & 0x00FF0000) >>> 16;
        //     const g:uint = (c & 0x0000FF00) >>> 8;
        //     const b:uint = (c & 0x000000FF);

        //     consoleBox.print("color = "+r+" "+g+" "+b+" alpha = "+a);
        // }

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
            updatePenSizeCursor();
            resetReplayDataFile();
            selectPenTool();
            checkVersion(false);
            initPickerBoxInfo(penColor);

            //캔버스 중점으로 옮겨주고, 리사이즈 이벤트 추가
            lastWindowSize[0] = stage.nativeWindow.width;
            lastWindowSize[1] = stage.nativeWindow.height;
            setCenvasCenterPos();
            setCenvasCenterPos(true);
            previewBox.updateImage(canvas1BitmapData,CANVAS_BG_COLOR);
            consoleBox.print("FOFO PAINT "+APP_VERSION.toFixed(2));

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
        private function stageHintOFFEvent(e:Event):void
        {
            setControlBoxInfoOFF();
            setTopBarHintOFF();
        }

        private function updatePenCursorPositionEvent(e:MouseEvent):void
        {
            if(clickBlockFlag || replayModeON || captureModeON) return;
            afkONCount = 0;

            updatePenCursorPosition();
        }

        private function updatePenCursorPosition():void
        {
            const _penSizeCursor:Shape = penSizeCursor;
            // const _penSizeCursor2:Shape = penSizeCursor2;

            if(nowTool > 4 || penCursorOFFFlag)//1 2 3 4 펜 지우개 라인툴 라인-지우개툴
            {
                clearTimeout(penCursorCheckTimer);
                penCursorCheckTimer = 0;
                _penSizeCursor.visible = false;
                // _penSizeCursor2.visible = false;
            }
            else
            {
                const offset:Number = (sizeOffsetFlag) ? 0.5:0;
                const _canvasPanel:Sprite = canvasPanel;
                const floor:Function = Math.floor;
                const mx:Number = _canvasPanel.mouseX;
                const my:Number = _canvasPanel.mouseY;
                var x:Number = mx+offset;
                var y:Number = my+offset;

                if(pixelSnap)
                {
                    x = floor(mx)+offset;
                    y = floor(my)+offset;
                }

                _penSizeCursor.x = x;//check undo에서 추적하기 때문에 커서를 무조건 보이지 않아도 따라가야함
                _penSizeCursor.y = y;
                // _penSizeCursor2.x = x;
                // _penSizeCursor2.y = y;

                if(_penSizeCursor.width < (8/zoomed) || fillPenON)
                {
                    clearTimeout(penCursorCheckTimer);
                    penCursorCheckTimer = 0;
                    _penSizeCursor.visible = false;
                    // _penSizeCursor2.visible = false;
                }
                else
                {
                    _penSizeCursor.visible = true;
                    // _penSizeCursor2.visible = false;
                }
                // else if(!mouseClickON) //중앙색 검출해서 외곽선 바꿔주기
                // {
                //     if(penCursorCheckTimer === 0)
                //     {
                //         penCursorCheckTimer = setTimeout(function():void
                //         {
                //             penCursorCheckTimer = 0;

                //             var color:uint = canvas1BitmapData.getPixel32(canvas1Bitmap.mouseX,canvas1Bitmap.mouseY);
                //             const rgb:uint = color & 0x00FFFFFF;
                //             const alpha:Number = ((color >> 24) & 0xFF)/255;
                //             const c:uint = RGBAtoRGB(CANVAS_BG_COLOR,alpha,rgb);
                //             const r:uint = (c >> 16) & 0xFF;
                //             const g:uint = (c >> 8) & 0xFF;
                //             const b:uint = c & 0xFF;
                //             const cont:int = getColorBright(RGBtoHex(r,g,b),1.0);

                //             if(cont >= 128)//검은색 커서로 표시
                //             {
                //                 if(!_penSizeCursor.visible)
                //                 {
                //                     _penSizeCursor.visible = true;
                //                     _penSizeCursor2.visible = false;
                //                     altCursorON = false;
                //                 }
                //             }
                //             else
                //             {
                //                 if(!_penSizeCursor2.visible)
                //                 {
                //                     _penSizeCursor.visible = false;
                //                     _penSizeCursor2.visible = true;
                //                     altCursorON = true;
                //                 }
                //             }
                //         },200);
                //     }
                // }
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
                    System.pauseForGCIfCollectionImminent();
                    System.gc();
                }
                else
                {
                    gcONCount++;
                }
     
                if(afkONCount === AFK_TIME_OUT)
                {
                    afkONCount++;
                    stopWorkingTimer();
                }
                else if(afkONCount < AFK_TIME_OUT)
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
		// <= 1.0	인간의 눈으로 인식 할 수 없습니다.
		// 1 ~ 2	면밀한 관찰을 통해 인식 할 수 있습니다.
		// 2 ~ 10	한눈에 알아볼 수 있습니다.
		// 11-49	색상이 반대보다 비슷합니다.
		// 100	    색상이 정반대입니다.
		private function getColorDifferenceForHuman(rgbA:uint, rgbB:uint):Number
		{
			function rgb2lab(rgb:uint):Vector.<Number>
			{
				var r:Number = ((rgb & 0xFF0000) >>> 16) / 255;
				var g:Number = ((rgb & 0x00FF00) >>> 8) / 255;
				var b:Number = ((rgb & 0x0000FF)) / 255;
				var x:Number, y:Number, z:Number;

				r = (r > 0.04045) ? Math.pow((r + 0.055) / 1.055, 2.4) : r / 12.92;
				g = (g > 0.04045) ? Math.pow((g + 0.055) / 1.055, 2.4) : g / 12.92;
				b = (b > 0.04045) ? Math.pow((b + 0.055) / 1.055, 2.4) : b / 12.92;
				x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047;
				y = (r * 0.2126 + g * 0.7152 + b * 0.0722) / 1.00000;
				z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883;
				x = (x > 0.008856) ? Math.pow(x, 1/3) : (7.787 * x) + 16/116;
				y = (y > 0.008856) ? Math.pow(y, 1/3) : (7.787 * y) + 16/116;
				z = (z > 0.008856) ? Math.pow(z, 1/3) : (7.787 * z) + 16/116;

                const result:Vector.<Number> = new <Number> [(116 * y) - 16, 500 * (x - y), 200 * (y - z)];
				
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
                consoleBox.print("Canvas zoom "+Math.floor(newZoom*100)+"%");
            }
        }

        //mosue move 이벤트 일정 시간 이내는 무시함
        private function limitMouseMoveEventTime(nowTime:int):Boolean
        {
            const subTime:int = nowTime-mouseMoveEventLastTime;

            if(subTime < mouseMoveEventTimeLimit)
            {
                mouseMoveEventTimeLimitCount = mouseMoveEventTimeLimitCount-subTime;

                if(mouseMoveEventTimeLimitCount <= 0)
                {
                    mouseMoveEventTimeLimitCount = mouseMoveEventTimeLimit;
                }

                return true;
            }

            mouseMoveEventLastTime = nowTime;

            mouseMoveEventTimeLimitCount = mouseMoveEventTimeLimitCount-subTime;

            if(mouseMoveEventTimeLimitCount <= 0) 
            {
                mouseMoveEventTimeLimitCount = mouseMoveEventTimeLimit;
            }

            return false;
        }

        private function checkKeWhileShiftKey(keyCode:uint,ctrlKey:Boolean):Boolean
        {
            if(ctrlKey)
            {
                if(keyCode === KEY.s)
                {
                    saveFile(true);
                }
                else if(keyCode === KEY.o)
                {
                    loadFile(true);
                }
                else if(keyCode === KEY.v && clipImageON)
                {
                    if(!clipImageShortCutON)
                    {
                        clipImageShortCutON = true;
                        setTraceClipButton();
                        openTraceMenu();
                    }
                }
                return true;
            }
            return false;
        }

        private function checkKeWhileControlKey(keyCode:uint,shiftKey:Boolean):void
        {
            if(keyCode === KEY.s) //ctrl+s
            {
                //컨트롤-쉬프트 조합은
                //checkLineToolEraseKeyDown함수에서 해줌
                saveFile(false);
            }
            else if(keyCode === KEY.o) //ctrl+o
            {
                loadFile();
            }
            else if(keyCode === KEY.v)
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
                case KEY.space:
                {
                    nowKey = keyCode;
                    nowTool = TOOL_HAND;
                    return true;
                }
                break;

                case KEY.w:
                case KEY.i:
                {
                    nowKey = keyCode;
                    nowTool = TOOL_ZOOM;
                    toolBox.hint("Select \nzoom point",toolBox.toolZoom,isRightSidebar);
                    return true;
                }
                break;

                case KEY.s:
                case KEY.k:
                {
                    nowKey = keyCode;
                    nowTool = TOOL_ROTATE;
                    return true;
                }
                break;

                case KEY.enter:
                    setLassoOKButton();
                break;

                case KEY.esc:
                    setLassoCancelButton();
                break;
            }
            return false;
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

        private function updatePreviewCursorPos():void
        {
            const gp:Point = canvas1Bitmap.globalToLocal(new Point(LEFT_OFFSET,TOP_OFFSET));
            const z:Number = zoomed;

            previewBox.updateCursor(gp.x*z
                                    ,gp.y*z
                                    ,stage.stageWidth-LEFT_OFFSET-RIGHT_OFFSET
                                    ,stage.stageHeight-TOP_OFFSET-BOTTOM_OFFSET
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
            const _zoomed:Number = zoomed;
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
                consoleBox.print("Canvas move")
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
                selectPenTool(true);
            }
            else if(nowTool !== TOOL_PEN)
            {
                if(fillPenON)
                {
                    selectFillPen();
                }
                else
                {
                    nowToolBackup = TOOL_PEN;
                    selectPenTool();
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
            _pickerBox.setRGBInfoColor(getInvertColor(color,1.0,0xFFFFFF,0));
            _pickerBox.updateRGBInfoBG(color);
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
                traceMenuBox.traceInfo.text = "Transfer to reference layer";
                pasteTraceImage();
            }
        }

        private function setPresetColor(target:DisplayObject,bgFlag:Boolean):void
        {
            if(!target) return;

            const hexColor:uint = target.transform.colorTransform.color;
            const _setColorTransform:Function = setColorTransform;
            const c:Vector.<uint> = HEXtoRGB(hexColor);
            const colorHint:String = "RGB "+c[0]+","+c[1]+","+c[2];

            if(bgFlag === false)
            {
                penColor = hexColor;//색깔이 다를때만
                updateOpaBoxColor(hexColor);
                updateOpacityCursor(penAlphaIndex);
                setHSVCursorPosByColor(hexColor);

                // pickerLastHint = colorHint;
                forceSetMainDrawTool();
            }
            else if(bgFlag === true)
            {
                colorHistoryList[0] = hexColor;
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
            // const z:Number = zoomed;
            // const sc:Number = Math.abs(_lassoBox.scaleX);
            const floor:Function = Math.floor;
            const stw:Number = stage.stageWidth;
            const sth:Number = stage.stageHeight;
            var lassoW:Number = _lassoMenu.width;
            var lassoH:Number = _lassoMenu.height;

            if(lassoW > stw) lassoW = stw;
            if(lassoH > sth) lassoH = sth;

            _lassoMenu.x = floor(g.x-lassoW/2);
            // _lassoMenu.y = floor(g.y+lassoH/sc)*z);
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
                    str = "Transfer to reference layer";
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
                    traceMenuBox.traceInfo.text = "REFERENCE LAYER";
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
                    str = "Move image by 1px (left)"
                break;

                case "lasso1pxRight":
                    str = "Move image by 1px (right)"
                break;

                case "lasso1pxUp":
                    str = "Move image by 1px (up)"
                break;

                case "lasso1pxDown":
                    str = "Move image 1px (down)"
                break;

                default:
                    lassoMenu.lassoInfo.text = "LASSO";
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
            if(toolBox.toolInfo.visible)// && mouseX >= sideBar.WIDTH-5)
            {
                toolBox.hintOFF();
            }

            if(zoomToolHintON) zoomToolHintON = false;
            else toolTipBox.visible = false;

            stage.removeEventListener(MouseEvent.MOUSE_MOVE,toolBoxHintMoveEvent);
        }

        private function toolBoxHintONEvent(e:MouseEvent):void
        {
            if(mouseClickON ||  mouseDragON) return;
            const targetName:String = e.target.name;
            const _tb2:toolButtons2 = toolBox2;
            const toolBox2Flag:Boolean = _tb2.visible;
            var str:String = "";
            var twoLineHint:Boolean = false;
            var eraseLineFlag:Boolean = false;//직선툴을 가르키면 직선 지우개 툴을 임시적으로 켜줌
            
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
                    str = "Erase (d, j)";
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
                    eraseLineFlag = true;
                }
                break;

                case "toolEraseLine":
                {
                    if(toolBox2Flag)
                    {
                        str = "Erase line\n(shift+d, shift+j)";
                        twoLineHint = true;
                    }
                    else
                    {
                        str = "Erase line (shift+d, shift+j)";
                    }
                    eraseLineFlag = true;
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

            const eraseLineIcon:SimpleButton = _tb2["toolEraseLine"];
            const fillPenIcon:SimpleButton = _tb2["toolFillPen"];
            //직선 툴을 선택했을때
            if(eraseLineFlag === true)
            {
                //플래그를 올려줬는데 지우개 직선툴이 아니면
                if(nowTool !== TOOL_LINE_ERASE)
                {
                    //지우개 직선툴 아이콘을 보여줌
                    fillPenIcon.visible = false;
                    eraseLineIcon.visible = true;
                    
                    const eraseIcon:SimpleButton = _tb2["toolErase"];
                    //지우개 아이콘이 지우개 직선툴 위치에 있으면 지우개 아이콘도 꺼줌
                    if(eraseIcon.x === fillPenIcon.x
                    && eraseIcon.y === fillPenIcon.y)
                    {
                        eraseIcon.visible = false;
                    }
                } 
            }
            //직선툴 선택이 아니고, 지우개 직선툴이 아이콘이 켜져 있고,
            else if(eraseLineIcon.visible === true)
            {
                // 현재 툴이 직선툴이 아니면 꺼줌
                if(nowTool !== TOOL_LINE)
                {
                    fillPenIcon.visible = true;
                    eraseLineIcon.visible = false;
                }
                // 필펜이랑 위치가 겹치면 필펜 아이콘을 꺼줌
                else if(eraseLineIcon.x === fillPenIcon.x
                && eraseLineIcon.y === fillPenIcon.y)
                {
                    fillPenIcon.visible = false;
                }
            }

            // toolBox.toolInfo.text = str;

            if(toolBox2Flag === true)
            {
                toolBox2.toolInfo.text = str;
                if(twoLineHint)
                {
                    toolBox2.toolInfo.height = toolBox2.toolInfo.textHeight+10;
                    toolBox2.toolBoxMoveButton.height = toolBox2.toolInfo.height;
                }
                else
                {
                    toolBox2.toolInfo.height = 22.7;
                    toolBox2.toolBoxMoveButton.height = 25;
                }
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

            buttonSetVisible(mode,true);

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
                const _replayTimeBox:replayTimeBar = replayTimeBox
                buttonSetVisible("draw",false);
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
                buttonSetVisible("draw",false);
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
                // g.moveTo(0,gridi);//가로선
                // g.lineTo(w,gridi);
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
                // g.moveTo(gridi,0);//세로선
                // g.lineTo(gridi,h);
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

                // g.moveTo(0,gridi);//가로선
                // g.lineTo(w,gridi);
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
                // g.moveTo(gridi,0);//세로선
                // g.lineTo(gridi,h);
            }
            g.drawPath(cmd,data);
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
            // const offsetX:Number = button.width/2;
            const barWidth:Number = bar.width*alpha;
            const buttonMin:Number = bar.x//+offsetX;
            traceMenuBox["traceOpaButton"].x = buttonMin+barWidth//-offsetX;
        }

        private function closeTraceMenu():void
        {
            traceMenuON = false;
            traceMenuBox.visible = false;
        }


        private function openTraceMenu():void //load clip버튼에서 눌러줬을때 틀여줌
        {
            if(traceMenuON === true)
            {
                setTopChildIndex(traceMenuBox);
                return;
            }

            const _traceMenuBox:traceButtons = traceMenuBox;
    
            // _traceMenuBox.x = stage.stageWidth/2-_traceMenuBox.width/2;
            // _traceMenuBox.y = stage.stageHeight-250;
            _traceMenuBox.x = mouseX-_traceMenuBox.width/2//stage.stageWidth/2-_traceMenuBox.width/2;
            _traceMenuBox.y = mouseY-3//stage.stageHeight-250;
            
            _traceMenuBox.visible = true;
            traceMenuON = true;
            setTopChildIndex(_traceMenuBox);
            checkBoxPosition(_traceMenuBox);
            // if(toolBoxAlwaysON) toolBox.visible = false;
        }

        private function selectTraceTool():void
        {
            openTraceMenu();
            //checkPenEraseIconSameLocation();
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
                if(traceVisibleFlag === true)
                {
                    setTraceVisibleButton();
                }
            }
        }

        private function setTraceVisibleButton():void
        {
            if(traceVisibleFlag === false)
            {
                traceVisibleFlag = true;
                traceMenuBox.traceVisibleOFFButton.visible = false;
                traceMenuBox.traceVisibleONButton.visible = true;
            }
            else if(traceVisibleFlag === true)
            {
                traceVisibleFlag = false;
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
                // traceMenuBoxFollowCursor(traceMenuClickPos);
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
            // const traceMenuClickPos:Array = [traceMenuBox.mouseX,traceMenuBox.mouseY];
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
                // traceMenuBoxFollowCursor(traceMenuClickPos);
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
   
                    // //10픽셀 이하움직임에서는 원래 크기 스냅걸리게함
                    // if(abs(traceReizeMoveSum) <= 10 && _canvasTrace.scaleY === 1.0)
                    // {
                    //     _canvasTrace.scaleX = (mirrorFlag) ? -1.0 : 1.0;
                    //     _canvasTrace.scaleY = 1.0;
                    // }
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
            // const mirrorFlag:Boolean = mirrorON;

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
                // traceMenuBoxFollowCursor(traceMenuClickPos);
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
            // const offsetX:Number = button.width/2; //버튼 두깨 빼줌
            const barWidth:Number = bar.width;
            const buttonMin:Number = bar.x//-offsetX;
            const buttonMax:Number = buttonMin+barWidth//-offsetX;
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
                var mx:Number = _traceMenuBox.mouseX//+offsetX;

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
                // const mirrorFlag:Boolean = mirrorON;
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
            // const info:Array = tracePosInfo;
        
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
                // tmpBMPD.draw(canvasTraceBitmapData);
                // tmpBMPD.draw(canvas1BitmapData);
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
            
            if(CANVAS_TRACE_ALPHA < 0.15)
            {
                updateTraceOpaButtonPosByAlpha(0.5);

                CANVAS_TRACE_ALPHA = 0.5;
                canvasTrace.visible = true;
                canvasTrace.alpha = 0.5;
            }

            _canvasTraceBitmap.smoothing = true;
            saveOneTime = false;
            consoleBox.print("Update reference layer");
        }

        private function setPixelSnapButton(flag:Boolean):void
        {
            function pixelSnapButtonUpEvent(e:MouseEvent):void
            {
                setPixelSnap(flag);
                stage.removeEventListener(MouseEvent.MOUSE_UP,pixelSnapButtonUpEvent);
            }

            stage.addEventListener(MouseEvent.MOUSE_UP,pixelSnapButtonUpEvent);
        }

        private function setSubLayerButton(flag:Boolean):void
        {
            function subLayerButtonUpEvent(e:MouseEvent):void
            {
                setSubLayer(flag);
                stage.removeEventListener(MouseEvent.MOUSE_UP,subLayerButtonUpEvent);
            }

            stage.addEventListener(MouseEvent.MOUSE_UP,subLayerButtonUpEvent);
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
            pixelSnap = flag;
            updatePenSizeCursor();
            const _controlBox:controlMenu = controlBox;
            _controlBox["pixelSnapOFFButton"].visible = flag;
            _controlBox["pixelSnapONButton"].visible = !flag;

            const isErase:Boolean = isEraseTool();
            const z:Number = zoomed;
            const size:uint = (isErase) ? eraseSize:penSize;
            const zSize:Number = size*z;

            if(pixelSnap)
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
                // penSizeCursor2.visible = false;
            }
            fillPenON = flag;
            // penFillCursorON = flag; //업데이트 함수에서 사이즈 같아 리턴해주는거 방지해주기 위해서
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
            stage.nativeWindow.title = saveFileName + " - FOFO Paint";
        }

        private function changeResizeButtonColor(color:uint):void
        {
            const c:ColorTransform = new ColorTransform();
            c.color = color;
            resizeButtonR.transform.colorTransform = c;
            resizeButtonD.transform.colorTransform = c;
            resizeButtonL.transform.colorTransform = c;
            resizeButtonU.transform.colorTransform = c;
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

        private function setUIColor(index:uint):void
        {
            const _arr:Array = uiColorSet;
            const _arr2:Array = uiToolBoxColorSet[index];
            const base:uint = _arr[index][0];
            const op:uint = _arr[index][1];
            const bg:uint = _arr[index][2];
            const border:uint = _arr[index][3];
            const subBase:uint = _arr2[1];

            updateStageBG(bg);
            controlBox.changeUIColor(base,op);
            changeResizeButtonColor(border);
            toolTipBox.changeUIColor(base,op);
            pickerBox.changeUIColor(base,op,index);
            updatePickerCurrentColor(penColor);
            sideBar.changeUIColor(base,op);
            previewBox.chanegStageColor(bg);
            toolBox.changeUIColor(_arr2);
            toolBox2.changeUIColor(_arr2);
            traceMenuBox.changeUIColor(_arr2,index === 0);
            lassoMenu.changeUIColor(_arr2);
            topBar.changeUIColor(base,op);
            topBar.changeUIColor(base,op);
            rotateCursorBox.changeUIColor(base,op);
            fileDragSelectBox.changeUIColor(_arr2);
            replayTimeBox.changeUIColor(base,op,_arr2[4],index);
            consoleBox.changeUIColor(base,op);
            checkClipBoardImage();
            appInfoBox.canvasInfo.textColor = op;
        }

        private function windowStageElementSetting():void
        {
            updateWindowTitle();
            stage.vsyncEnabled = false;
            stage.scaleMode = StageScaleMode.NO_SCALE; //창크기 상관없이 스테이지 크기 고정
            stage.align = StageAlign.TOP_LEFT;
            stage.quality = StageQuality.BEST;
            stage.tabChildren = false;

            NativeApplication.nativeApplication.autoExit = true;

            //창을 가운데로 옮김
            const _nativeWindow:NativeWindow = stage.nativeWindow;
            _nativeWindow.x = Capabilities.screenResolutionX/2 - 680/2;
            _nativeWindow.y = Capabilities.screenResolutionY/2 - 768/2 - 50;
            _nativeWindow.addEventListener(Event.RESIZE,windowResizedEvent);
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

            // pickerBox.addEventListener(MouseEvent.MOUSE_OVER,pickerBoxHintONEvent);

            topBar.addEventListener(MouseEvent.CLICK,topBarClickEvent);
        }

        // private function pickerBoxHintONEvent(e:MouseEvent):void
        // {
        //     if(mouseClickON || mouseDragON)
        //     {
        //         return;
        //     }

        //     const targetName:String = e.target.name;

        //     if(targetName === "currentColor")
        //     {
        //         pickerLastHint = pickerBox.getRGBInfo();
        //         pickerBox.setRGBInfo("Reset color");
        //     }
        //     else if(pickerLastHint !== "")
        //     {
        //         pickerBox.setRGBInfo(pickerLastHint);
        //         pickerLastHint = "";
        //     }
        //     // else if(targetName === "pickerBoxPanel")
        //     // {
        //     //     if(pickerLastHint !== "")
        //     //     {
        //     //         pickerBox.setRGBInfo(pickerLastHint);
        //     //     }
        //     // }
        // }

        private function setControlBoxInfoOFF():void
        {
            const nt:uint = nowTool;
            var toolName:String = "Pen";

            if(nt === TOOL_ERASE) toolName = "Erase";
            else if(nt === TOOL_LINE) toolName = "Line";
            else if(nt === TOOL_LINE_ERASE) toolName = "Erase-line";
            else if(fillPenON) toolName = "Fill-pen";
            
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
            if(mouseDragON || mouseClickON || toolBox2ON) return;

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
                    str = "Pen smoothing "+penSmoothSlideValue + "/"+penSmoothSlideTotal;
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

                case "pixelSnapButtonWapper":
                case "pixelSnapOFFButton":
                case "pixelSnapONButton":
                case "pixelSnapText":
                {   
                    str = "Sharp line ON/OFF";
                }
                break;

                case "subLayerButtonWapper":
                case "subLayerOFFButton":
                case "subLayerONButton":
                case "subLayerText":
                {   
                    str = "Sub layer ON/OFF";
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
            const nt:int = nowTool;
            const bool:Boolean = (nt === TOOL_ERASE || nt === TOOL_LINE_ERASE);

            return bool;
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
            const replayTotalBar:SimpleButton = _replayTimeBox["replayTotalBar"];
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

            function alphaGO(alp:Number):void
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
                alphaStr =  alphaValue*100+"%";

                setToolTipStringTime(alphaStr);
                setPenAlpha(alphaValue);
            }

            if(isEraseTool())
            {
                alphaGO(eraseAlpha);

            }
            else if(isPenTool())
            {
                alphaGO(penAlpha);
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

            function sizeGO(index:uint):void
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
                const sizeStr:String =  sizeValue+"px";

                setToolTipStringTime(sizeStr);
                setPenSize(index);

                // if(altCursorON)
                // {
                //     penSizeCursor2.visible = true;
                // }
                // else
                // {
                // }
                penSizeCursor.visible = true;
            }


            if(isPenTool())
            {
                sizeGO(penSizeIndex);
            }
            else if(isEraseTool())
            {
                sizeGO(eraseSizeIndex);
            }
            function printConsolSizeEvent(e:KeyboardEvent):void
            {
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
            const keycode:int = e.keyCode;

            afkONCount = 0;

            if(keycode === KEY.shift && shiftKeyON)
            {
                shiftKeyON = false;
            }

            const index:int = keybufferArr.lastIndexOf(keycode);

            if(index > -1) // 이거 해줘야 하는지 잘 모르겠음 남겨둠 if(keycode === nowKey)
            {
                keybufferArr.splice(index,1);
            }
        }

        private function keyDownBufferEvent(e:KeyboardEvent):void
        {
            const keycode:int = e.keyCode;
            if(keycode === KEY.shift && !shiftKeyON)
            {
                shiftKeyON = true;
            }

            if(lassoToolON || captureModeON || e.ctrlKey || e.altKey || e.shiftKey) return;
        
            if(keybufferArr.lastIndexOf(keycode) === -1 && nowKey !== keycode)
            {
                keybufferArr.push(keycode);
            }

            if(!mouseClickON && !mouseDragON)
            {
                switch(keycode)
                {
                    case KEY.f:
                    case KEY.h:
                        shortCutPenSize(true);
                    break;

                    case KEY.v:
                    case KEY.n:
                        shortCutPenSize(false);
                    break;

                    case KEY.g:
                        shortCutPenAlpha(true);
                    break;
                    case KEY.b:
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
            checkPenSize();
            penSizePrev.visible = true;
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
            if(color === lastUpdateInfo[4]) return;
            lastUpdateInfo[4] = color;
            
            const _opaBox:Sprite = controlBox.opaBox;
            const alphaArr:Array = alphaArr;
            var cc:ColorTransform = new ColorTransform();
            var btn:SimpleButton;
            var alp:Number;
            cc.color = color;

            if(!colorHistoryUpdateReady)
            {
                colorHistoryUpdateReady = true;
                stage.addEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryEvent);
            }

            for(var i:int=3;i>=0;i--)
            {
                btn = _opaBox["alphaButton"+i];
                alp = alphaArr[i];
                cc.alphaMultiplier = alp;
                btn.transform.colorTransform = cc;
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
            const leftOffset:Number = sliderSet["penSmoothBar"].x; //펜 리스트에 흰색 선 시작과 끝 x좌표임
            const rightOffset:Number = leftOffset+sliderSet["penSmoothBar"].width;
            const step:Number = penSmoothSlideTotal;
            const div:Number = (rightOffset-leftOffset)/step;
            const maxValue:Number = 0.85;
            const minValue:Number = 0.02;
            const stepValue:Number = (maxValue-minValue)/step;
            var oldValue:Number = penSmoothSlideValue;

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
                topBar["capTransCheck"].visible = true;
                changeToolTipString("Restore background");
            }
            else
            {
                resetTransBG(replayModeON);
                topBar["capTransCheck"].visible = false;
                changeToolTipString("Remove background");
            }
        }

        private function setCaptureRotateButton():void
        {
            captureRotated++;
            if(captureRotated >= 4) captureRotated = 0;

            canvasFitWindow(true);
        }

        private function setCaptureCursorON(replayMode:Boolean,zoomed:Number):void
        {
            const xCapture:Shape = (replayMode) ? rcapturePreviewCursor : capturePreviewCursor;
            const g:Graphics = xCapture.graphics;
            const cursorSize:Number = 100*zoomed;
            xcapturePreviewCursor = xCapture;

            g.clear();
            g.lineStyle(5*zoomed,0xFFFFFF,0.4,true,"normal","none");
            g.moveTo(-cursorSize,0);
            g.lineTo(cursorSize,0);
            g.moveTo(0,-cursorSize);
            g.lineTo(0,cursorSize);

            g.lineStyle(3*zoomed,0,1.0,true,"normal","none");
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

            if(isPenTool()
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
            if(lassoToolON || (e.target.alpha && e.target.alpha < 1.0)) return;

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

            // const PI2:Number = PI*2;
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
                toolTipBox.visible = false;
                
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

                // if(sumAng > PI2) sumAng -= PI2; //360도가 넘으면 360을 빼줌
                // else if(sumAng < -PI2) sumAng += PI2;

                const deg:Number = floor(sumAng*toDeg+0.5);

                _lassoBox.rotation = deg;
                angleCursor.rotation = deg;

                setToolTipString(abs(_lassoBox.rotation)+"°");
            }
            _rotateCursorBox.x = mouseX;
            _rotateCursorBox.y = mouseY+50;
            angleCursor.rotation = _lassoBox.rotation;
            _rotateCursorBox.visible = true;
            setTopChildIndex(_rotateCursorBox);
            lastAng = Math.atan2(mouseX-_rotateCursorBox.x,mouseY-_rotateCursorBox.y);
            setToolTipString(floor(abs(_lassoBox.rotation))+"°");
            toolTipBox.visible = true;

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

            if(fillPenON)
            {
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

            updatePenSizeCursor();
            controlBox.movePenSizeCursor(index);
        }

        private function updatePickerCurrentColor(color:uint):void
        {
            const defColor:Number = getColorDifferenceForHuman(color,uiColorSet[uiColorIndex][0]);
            pickerBox.updateCurrentColor(color,defColor <= 15,uiColorSet[uiColorIndex][1]);
        }

        private function changePickerModeToBG():void
        {
            const color:uint = CANVAS_BG_COLOR;
            pickerMode = 2;
            pickerBox.changeBGTextToPicker(true);
            setHSVCursorPosByColor(color);
            updatePickerCurrentColor(color);

            if(colorHistoryUpdateBGReady === false)
            {
                colorHistoryUpdateBGReady = true;
                stage.addEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryBGEvent);
            }
        }

        private function changePickerModeToNormal():void
        {
            const color:uint = penColor;
            pickerMode = 1;
            pickerBox.changeBGTextToPicker(false);
            setHSVCursorPosByColor(color);
            updatePickerCurrentColor(color);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryBGEvent);
        }

        private function setShapeButton(shapeFlag:Boolean):void
        {
            penListShapeFlag = shapeFlag;

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
                _pickerBox.updateRGBInfoBG(color);
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
                    colorHistoryList[0] = pickedColor;
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
            const invColor:uint = getInvertColor(rgbHexColor,1.0,0xFFFFFF,0);
            const _setColorTransform:Function = setColorTransform;
            const colorHint:String =  "RGB "+r+","+g+","+b;

            HUECOLOR[0] = h;
            HUECOLOR[1] = s;
            HUECOLOR[2] = v;

            pickerBox.setRGBInfo(colorHint);
            pickerBox.setRGBInfoColor(invColor);

            // pickerLastHint = colorHint;

            return rgbHexColor;
        }

        private function setSVcolorButton():void
        {
            const _pickerBox:colorPickerBox = pickerBox;
            const svColorBox:Sprite = _pickerBox["mainPickerBox"];
            const svCursor:SimpleButton = _pickerBox["svCursor"];
            const _colorBarWidth:Number = _pickerBox["svBoxWidth"];
            const _colorBarHeight:Number = _pickerBox["svBoxHeight"];
            const mode:uint = pickerMode;
            var pickedColor:uint = 0;

            setTopChildIndex(svCursor);
            mouseDragON = true;
            penCursorOFFFlag = true;

            function svMoveStart(mx:Number,my:Number):void
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
                _pickerBox.updateRGBInfoBG(color);
            }

            function svColorButtonMoveEvent(e:MouseEvent):void
            {
                pickerColorSelected = true;
                svMoveStart(svColorBox.mouseX,svColorBox.mouseY);
            }

            function svColorButtonUpEvent(e:MouseEvent):void
            {
                svMoveStart(svColorBox.mouseX,svColorBox.mouseY);

                if(mode === 1)
                {
                    penColor = pickedColor;
                    updateOpaBoxColor(pickedColor);
                    updateOpacityCursor(penAlphaIndex);
                }
                else if(mode === 2)
                {
                    colorHistoryList[0] = pickedColor;
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

            svMoveStart(svColorBox.mouseX,svColorBox.mouseY);

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

            nowTool = prevTool;
            nowToolBackup = -1;

            switch (prevTool)
            {
                case TOOL_PEN:
                    if(fillPenON)
                    {
                        selectFillPen();
                    }
                    else
                    {
                        selectPenTool();
                    }
                break;

                case TOOL_ERASE:
                    selectEraseTool();
                break;

                case TOOL_LINE:
                    selectPenTool(true);
                break;

                case TOOL_LINE_ERASE:
                    selectEraseTool(true);
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
        }

        private function setTimerResetButton():void
        {
            const nt:int = getTimer();
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
        private function stringToNumber(str:String):Number
        {
            const dotIndex:int = str.indexOf(".");

            if(dotIndex === -1) return NaN;

            const head:String = str.slice(0,dotIndex);
            var tail:String = str.slice(dotIndex+1,str.length);
            var tailLen:uint = tail.length;

            if(tailLen > 2)
            {
                tail = tail.slice(0,2);
                tailLen = tail.length;
            }

            const headNum:Number = parseInt(head);
            const tailNum:Number = parseInt(tail)/Math.pow(10,tailLen);
            const num:Number = headNum+tailNum;

            return num;
        }

        // private function checkUsedMemory():void
        // {
        //     const memory:Number= Math.floor(((System.privateMemory+System.freeMemory)/1048576)*10+0.5)/10;
        //     // const diskCache:Number = getDiskCacheSize();

        //     appInfoBox.memoryCacheInfo(memory);
        // }

        private function checkVersion(checkOnly:Boolean):void
        {
            var url:URLRequest = new URLRequest("https://guljam.github.io/2020FlashPaint/versionInfo.txt");
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
                    var newVersion:Number = stringToNumber(versionStr);
                    //getVersion이 NaN일수도 있음
                    if(newVersion)
                    {
                        const floor:Function = Math.floor;
                        const oldnewVersion:Number = APP_VERSION;
                        const oldv:Number = oldnewVersion*100;
                        const newv:Number = newVersion*100;
                        var updateRryTimer:uint = 0;
                        var tryCount:uint = 0;

                        url = new URLRequest("https://github.com/guljam/2020FlashPaint/releases/download/update2/fofoPaint.air");

                        if(newv > oldv)
                        {
                            NEW_VERSION = versionStr;
                            var fileLoader:URLLoader = e.target as URLLoader;
                            
                            fileLoader.dataFormat = URLLoaderDataFormat.BINARY;
                            fileLoader.addEventListener(Event.COMPLETE,downloadSuccessEvent);
                            fileLoader.addEventListener(IOErrorEvent.IO_ERROR,downloadFailedEvent);

                            function setDownloadText(flag:int):void
                            {
                                fileLoader.removeEventListener(Event.COMPLETE,downloadSuccessEvent);
                                fileLoader.removeEventListener(IOErrorEvent.IO_ERROR,downloadFailedEvent);

                                const versionStr2:String = "Version " + versionStr + " released";
                                const downloadButton:TextField = aboutPanel["downloadButton"];

                                //html text적용
                                downloadButton.visible = true;
                                downloadButton.text = versionStr2;
                                needUpdate = flag;
                                if(checkOnly === false) openAboutPanel(2);
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
                                //여기까지 다운로드 appdata에 파일 저장거임
                                setDownloadText(1);
                            }

                            if(Updater.isSupported)
                            {
                                //다운로드를 시작함
                                fileLoader.load(url);
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
                loader.removeEventListener(Event.COMPLETE, urlLoadCompleteEvent);
                loader.removeEventListener(IOErrorEvent.IO_ERROR, urlLoadFailEvent);
                loader = null;
            }
        }

        private function closeAboutPanel():void
        {
            if(!replayModeON && !captureModeON) addMainEvent();

            stage.removeEventListener(MouseEvent.MOUSE_DOWN,aboutOFFEvent);
            aboutPanelON = false;
            aboutPanel.visible = false;
            clickBlockTimer = setTimeout(function():void
            {
                clickBlockFlag = false;
            },150);
        }

        private function aboutOFFEvent(e:MouseEvent):void
        {
            const targetName:String = e.target.name;
            var url:URLRequest;

            switch(targetName)
            {
                case "aboutButton":
                {
                    closeAboutPanel();
                }
                break;
                case "logo1":
                case "logo2":
                case "logo3":
                case "logo4":
                case "logo5":
                case "downloadButton":
                {
                    if(needUpdate === 1)
                    {
                        url = new URLRequest("https://guljam.github.io/2020FlashPaint/releasenote.txt");
                        navigateToURL(url);

                        closeAboutPanel();
                        setTimeout(function():void
                        {
                            installNewVersion();
                        },500);
                    }
                    else if(needUpdate === 2)
                    {
                        url = new URLRequest("https://guljam.github.io/2020FlashPaint/");
                        navigateToURL(url);
                        closeAboutPanel();
                    }
                    else
                    {
                        closeAboutPanel();
                    }
                }
                break;

                case "kor":
                    url = new URLRequest("https://guljam.github.io/2020FlashPaint/kr.html");
                    navigateToURL(url);
                break;

                case "jp":
                    url = new URLRequest("https://guljam.github.io/2020FlashPaint/jp.html"); 
                    navigateToURL(url);
                break;

                case "eng":
                    url = new URLRequest("https://guljam.github.io/2020FlashPaint/en.html")
                    navigateToURL(url);
                break;
                case "aboutTwitterLink":
                    url = new URLRequest("https://twitter.com/ninanoninini")
                    navigateToURL(url);
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

        private function openAboutPanel(flag:uint=0):void //welcome:Boolean=false):void
        {
            const _aboutPanel:aboutBox = aboutPanel;
            setTopChildIndex(_aboutPanel);
            aboutPanelON = true;
            clickBlockFlag = true;

            consoleBox.print("FOFO PAINT "+APP_VERSION.toFixed(2));

            if(!replayModeON) removeMainEvent();
            // closeTopbar();

            if(flag === 0)
            {
                stage.addEventListener(MouseEvent.MOUSE_DOWN,aboutOFFEvent);
            }
            else if(flag === 1) //처음 시작작
            {
                setTimeout(function():void
                {
                    stage.addEventListener(MouseEvent.MOUSE_DOWN,aboutOFFEvent);
                },1000);
            }
            else if(flag === 2) // 업데이트 할때
            {
                setTimeout(function():void
                {
                    stage.addEventListener(MouseEvent.MOUSE_DOWN,aboutOFFEvent);
                },1000);
            }

            aboutPanel.randomLogo();
            setAboutPanelCenterPos();
            if(needUpdate === 0) checkVersion(true);
            // checkUsedMemory();
        }

        private function clearCountDownString():String
        {
            const countquest:String = "Delete all data " + "("+-(clearDataButtonCount-3)+")";
            return countquest;
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
                // rcanvas1Bitmap.smoothing = true;

                canvas1Bitmap.bitmapData = rcanvas1BitmapData.clone();
                //canvas1Bitmap.smoothing = true;

                setPanelSize(canvas1Bitmap.width,canvas1Bitmap.height);
                setBackgroundColor(RCANVAS_BG_COLOR);

                clearButtonClicked = false;
            }
            else
            {
                clearCanvas();
                clearCanvasReplayMode();
                // setBackgroundColor(0xFFFFFF);
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
            clearTraceImage();
            resetReplayDataFile(true);
            resetReplayTime();
            addUndoData();
            setTimerResetButton();
            // consoleBox.deleteAll();
            // checkUsedMemory();
            const untitleCountName:String = "untitled"+clearDataFileNameCount+".png";
            const name:String = saveFileName;
            const path:String = saveFilePath;
            const newName:String = name.substr(0,name.lastIndexOf(name))+untitleCountName;
            const newPath:String = path.substr(0,path.lastIndexOf(name))+untitleCountName;

            saveFileName = newName;
            saveFilePath = newPath;

            clearDataFileNameCount++;

            updateWindowTitle();
            consoleBox.print("Clear all data");
        }

        private function setClearData(keyFlag:Boolean=false):void
        {
            if(clearButtonClicked === false)
            {
                if(keyFlag && clearDataButtonCount === 0)
                {
                    const clearButton:SimpleButton = topBar["clearButton"];
                    setToolTipString("Delete all data");
                    function clearDataButtonCountResetEvent(e:MouseEvent):void
                    {
                        const targetName:String = e.target.name;
                        //클리어 버튼이 아닐때만
                        if(targetName !== "clearButton")
                        {
                            clearDataButtonCount = 0;
                        }
                        stage.removeEventListener(MouseEvent.MOUSE_DOWN,clearDataButtonCountResetEvent);
                    }

                    stage.addEventListener(MouseEvent.MOUSE_DOWN,clearDataButtonCountResetEvent);
                }

                clearDataButtonCount++;

                if(clearDataButtonCount >= 3)
                {
                    topBar.hintOFF();
                    clearData();
                }
                else if(clearDataButtonCount < 3)
                {
                    if(keyFlag)
                    {
                        topBar.hintTime(clearCountDownString(),topBar.clearButton);
                    }
                    else
                    {
                        topBar.hint(clearCountDownString(),topBar.clearButton);
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
            if(aboutPanelON) return;

            function buttonUpEvent(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, buttonUpEvent);

                const upTargetName:String = e.target.name;

                if(targetName === upTargetName)
                {
                    switch(upTargetName)
                    {
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
                        case "sideBarPositionButton":
                            setSideBarPositionButton();
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
                        case "capTransCheck":
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
                            setGridButton();
                        break;

                        case "timerResetButton":
                        {
                            setTimerResetButton();
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

        private function cutFrameData(flag:int,shortcutKey:Boolean):void
        {
            if(replayStartON) stopReplay();

            const _replayTimeBox:replayTimeBar = replayTimeBox;
            const replayNowBar:SimpleButton = _replayTimeBox["replayNowBar"] as SimpleButton;
            var activeButton:SimpleButton;

            if(flag === 0)
            {
                activeButton = topBar["superUndoButton"];
            }
            else if(flag === 1)
            {
                activeButton = topBar["reRecordingButton"];
            }
            else if(flag === 2)
            {
                activeButton = topBar["cutPrevDataButton"];
            }
            if(activeButton.alpha < 1.0) return;
            // const prevCutButton:SimpleButton = topBar["cutPrevDataButton"];
            // const rrButton:SimpleButton = topBar["reRecordingButton"];
            // const sUndoButton:SimpleButton = topBar["superUndoButton"];
            const deleteBar:SimpleButton = _replayTimeBox["replayDeleteBar"];
            const _replayTotalBar:SimpleButton = _replayTimeBox["replayTotalBar"];

            function resetClickCounterMouseDownEvent(e:MouseEvent):void
            {
                if(e.target && activeButton === e.target)
                {

                }
                else
                {
                    resetClickCounter();
                    topBar.hintOFF();
                }
            }

            function resetClickCounterEvent(e:MouseEvent):void
            {
                cutFrameClickedButton = -1;
                resetClickCounter();
            }

            function resetClickCounter():void
            {
                // toolTipBox.visible = true;
                activeButton.removeEventListener(MouseEvent.MOUSE_OUT,resetClickCounterEvent);
                stage.removeEventListener(MouseEvent.MOUSE_DOWN,resetClickCounterMouseDownEvent);
                cutFrameClickCounter = 0;
                deleteBar.visible = false;
            }

            cutFrameClickCounter++;

            if(cutFrameClickedButton !== flag)
            {
                resetClickCounter();
                cutFrameClickCounter = 1;
            }
            cutFrameClickedButton = flag;

            if(cutFrameClickCounter === 1)
            {
                toolTipBox.visible = false;
                const totalBarWidth:Number = _replayTotalBar.width;

                activeButton.addEventListener(MouseEvent.MOUSE_OUT,resetClickCounterEvent);
                if(shortcutKey)
                {
                    stage.addEventListener(MouseEvent.MOUSE_DOWN,resetClickCounterMouseDownEvent);
                }

                if(flag !== 1)
                {
                    //중간 데이터다 넘기고 짤라줘야함
                    if(rFrame < rFrameArr.length) 
                    {
                        setSkipFrame(rFrameSum+rFrameArr.length-rFrame,3);
                        rOneSkipFlag = false;
                        checkCutFrameButtons();
                    }

                    //oneframe처리후에 프레임이 아이콘이 비활성화 되면 해주지 않음
                    if(activeButton.alpha < 1.0)
                    {
                        resetClickCounter();
                        return;
                    }
                }

                if(flag === 0)
                {
                    const width:Number = (totalBarWidth*(rFrameSum/TOTAL_FRAME));
                    deleteBar.x = _replayTotalBar.x+width;
                    deleteBar.width = (totalBarWidth-width);
                }
                else if(flag === 1)
                {
                    deleteBar.x = _replayTotalBar.x;
                    deleteBar.width = totalBarWidth;
                }
                else if(flag === 2)
                {
                    deleteBar.x = _replayTotalBar.x;
                    deleteBar.width = replayNowBar.width;
                }

                if(shortcutKey === false)
                {
                    topBar.hint("One more click to OK (Red area will be deleted)",activeButton);
                }
                else if(shortcutKey === true)
                {
                    const funcName:String = (flag === 0) ?  "Super-undo : "
                                            :(flag === 1) ? "Re-recording : "
                                            :(flag === 2) ? "Delete front data : "
                                            : "";
                    topBar.hint(funcName + "One more press key to OK (Red area will be deleted)",activeButton);
                }


                deleteBar.visible = true;
            }
            else if(cutFrameClickCounter === 2)
            {
                saveContinue = false;
                resetClickCounter();
                selectPenTool();
                cutFrameClickedButton = -1;

                if(flag === 0) //super undo
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
                        const fs:FileStream = new FileStream();
                        const bw:Number = _replayTotalBar.width;
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
                else if(flag === 1) //re-recording
                {
                    clearData(true);
                    replayNowBar.width = 0;
                    setCanvasSameReplayCanvas();
                    setReplayUI(false);
                }
                else if(flag === 2) //cut prev data 앞부분 잘라주기 
                {
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
                    return;
                }
                // closeTopbar();
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
            if(mouseDragON || mouseClickON || toolBox2ON) return;

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
                    case "playButton":
                        str = "Play (enter, space)";
                    break;

                    case "pauseButton":
                        str = "Pause (enter, space)";
                    break;

                    case "replayPrev":
                        str = "Prev(left), 1 frame(right-click, shift+click)";
                    break;

                    case "replayNext":
                        str = "Next(right), 1 frame(right-click, shift+click)";
                    break;
                    case "replaySpeedBarWrapper":
                    {
                        if(rSpeedLastStr === "") str = "Change playback speed";
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
                        if(clearButtonClicked === false)
                        {
                            var str1:String = clearCountDownString();
                            if(str1 !== "")//단축키랑 마우스 동시에 눌러줄때는 리셋해줌
                            {
                                clearDataButtonCount = 0;
                                str1 = clearCountDownString();
                            }
                            str = "Delete all data (click × 3, esc × 3)";
                        }
                        else
                        {
                            str = "All data deleted";
                        }
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
                    case "capTransCheck":
                        if(!captureTransBGON) str = "Remove background (d, j)";
                        else if(captureTransBGON) str = "Restore background (d, j)";
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
                            str = "Super-undo (click × 2, f5 × 2)";
                        }
                    break;

                    case "reRecordingButton":
                        if(cutFrameClickCounter === 1 && cutFrameClickedButton === 1)
                        {
                            str = "One more click to OK (Red area will be deleted)";
                        }
                        else
                        {
                            str = "Re-recording from this image (click × 2, f4 × 2)";
                        }
                    break;

                    case "cutPrevDataButton":
                        if(cutFrameClickCounter === 1 && cutFrameClickedButton === 2)
                        {
                            str = "One more click to OK (Red area will be deleted)";
                        }
                        else
                        {
                            str = "Delete front data (click × 2, f6 × 2)";   
                        }
                    break;


                    case "gridButton":
                        str = "Grid (f1)";
                    break;

                    case "sideBarPositionButton":
                        str = "Change Sidebar position (f2)"
                    break;
                    case "topBarColorButton":
                        str = "Change UI color (f3)"
                    break;
                    case "aboutButton":
                        str = "About";
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
                        str = "Canvas zoom-in";
                    break;
                     case "replayZoomOutButton":
                        str = "Canvas zoom-out";
                    break;

                    case "replayRotateButton":
                        str = "Canvas rotate";
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
            // rcanvas1Bitmap.smoothing = true;
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

            if(zh < z) z = zh;
            if(z > 1.0) z = 1.0;

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

            var barColor:uint = 0xA1CE9D; //2번 디폴트 어두운 회색

            if(uiColorIndex === 0) barColor = 0x74AC74;
            else if(uiColorIndex === 2) barColor = 0xB6DAAF;
            else if(uiColorIndex === 3)  barColor = 0xCEE5C5;

            setColorTransform(_replayTimeBox["replayNowBar"],barColor);
            
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
                    // rRestartTimerCount = 10;
                    // clearInterval(rRestartTimer);
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
            else
            {
                rcanvas1BitmapData.draw(rcanvas1Bitmap);
            }
            rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
            // rcanvas1Bitmap.smoothing = true;

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
            // rcanvas1Bitmap.smoothing = true;
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
            // rcanvas1Bitmap.smoothing = true;
        }

        private function doTickDraw(cd2:Graphics,lastFlag:Boolean=false):void
        {
            const fr:Array = rFrameArr;

            if(fr.length === 0 || fr === null) return;

            const d:Array = fr[rFrame];
            const drawInfo:String = d[0];
            var shape:Boolean;
            var size:Number;
            var size2:Number; //dot에서 사각형 크기
            var color:uint;
            var alpha:Number;
            var x:Number;
            var y:Number;
            var x2:Number; //직선에서 끝점임, x y는 시작점
            var y2:Number;
            var blendMode:String;
            var fillPenFlag:Boolean;
            var subLayerFlag:Boolean;

            switch(drawInfo)//rep draw info
            {
                case "lineStyle":
                {
                    shape = d[1] as Boolean;
                    size = d[2] as Number;
                    color = d[3] as uint;
                    alpha = d[4] as Number;
                    x = d[5] as Number;
                    y = d[6] as Number;
                    blendMode = d[7] as String;
                    fillPenFlag = d[8] as Boolean; //이전 버전 데이터
                    rLineStyleSave = [alpha,blendMode];

                    if(replayStartON && d[9] !== undefined)
                    {
                        setReplaySubLayer(d[9]);
                    }

                    if(!fillPenFlag)
                    {
                        replayLineStyleReady(shape,size,color,alpha);
                        cd2.moveTo(x,y);
                    }
                    else
                    {
                        cd2.clear();
                        replayLineStyleReady(false,1,color,1.0);
                        cd2.beginFill(color);
                        cd2.moveTo(x,y);
                        rcanvas2.alpha = alpha;
                    }
                }
                break;

                case "lineTo":
                {
                    x = d[1] as Number;
                    y = d[2] as Number;

                    cd2.lineTo(x,y);

                    if(lastFlag) rTinyCursorPos = [x,y];
                }
                break;

                case "sqline":
                {
                    rcanvas2Bitmap.bitmapData = null;
                    rcanvas2BitmapData.dispose();
                    rcanvas2BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
                    cd2.clear();

                    size = d[1] as Number;
                    color = d[2] as uint;
                    alpha = d[3] as Number;
                    blendMode = d[4] as String;

                    rLineStyleSave = [alpha,blendMode];
                    rcanvas2.alpha = alpha;
                    cd2.lineStyle(size,color,1,false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
                    cd2.drawPath(d[5] as Vector.<int>, d[6] as Vector.<Number>);
                }
                break;

                case "fill":
                {
                    color = d[1] as uint;
                    alpha = d[2] as Number;
                    blendMode = d[4] as String;

                    rLineStyleSave = [alpha,blendMode];
                    rcanvas2.alpha = alpha;
                    cd2.clear();
                    cd2.lineStyle(1,color);
                    cd2.beginFill(color);
                    cd2.drawPath(d[4] as Vector.<int>,d[5] as Vector.<Number>);

                    if(lastFlag) rTinyCursorPos = [d[5][0] as Number,d[5][1] as Number];

                    rSubLayerSave = d[6] as Boolean;
                }
                break;

                case "dot":
                {
                    shape = d[1] as Boolean;
                    size = d[2] as Number;
                    size2 = size/2 as Number;
                    color = d[3] as uint;
                    alpha = d[4] as Number;
                    x = d[5] as Number;
                    y = d[6] as Number;
                    blendMode = d[7] as String;

                    if(replayStartON && d[8] !== undefined)
                    {
                        setReplaySubLayer(d[8]);
                    }

                    rLineStyleSave = [alpha,blendMode];
                    rcanvas2.alpha = alpha;
                    cd2.lineStyle(0,0,0);
                    cd2.beginFill(color);

                    if(!shape) cd2.drawCircle(x,y,size2);
                    else if(shape) cd2.drawRect(x-size2,y-size2,size,size);

                    if(lastFlag) rTinyCursorPos = [x,y];

                    cd2.endFill();
                }
                break;

                case "line":
                {
                    rcanvasPanel.setChildIndex(rcanvas2,1);
                    shape = d[1] as Boolean;
                    size = d[2] as Number;
                    color = d[3] as uint;
                    alpha = d[4] as Number;
                    x = d[5] as Number;
                    y = d[6] as Number;
                    x2 = d[7] as Number;
                    y2 = d[8] as Number;
                    blendMode = d[9] as String;

                    rLineStyleSave = [alpha,blendMode];
                    rcanvas2.alpha = alpha;
                    if(replayStartON && d[10] !== undefined)
                    {
                        setReplaySubLayer(d[10]);
                    }

                    if(!shape) cd2.lineStyle(size,color);
                    else cd2.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);

                    cd2.moveTo(x,y);
                    cd2.lineTo(x2,y2);

                    if(lastFlag) rTinyCursorPos = [d[7],d[8]];
                }
                break;

                case "move":
                {
                    x = d[1] as Number;
                    y = d[2] as Number;
                    replayMoveImage(x,y);
                }
                break;

                case "lasso":
                {
                    const lsbox:Sprite = lassoBox;
                    const point1:Vector.<Number> = d[1] as Vector.<Number>;
                    const point2:Array = d[2] as Array;
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
                    posMatrix.translate(Math.floor(-lassoInfo2/2),Math.floor(-lassoInfo3/2));
                    posMatrix.rotate(lassoInfo4);
                    posMatrix.translate(lassoInfo5,lassoInfo6);

                    lassoBMP.smoothing = true;

                    if(lassoInfo0 !== 1 || lassoInfo4 !== 0)
                    {
                        applyLassoShapen(lassoInfo0);
                    }

                    rcanvas1BitmapData.draw(lassoBMP,posMatrix);
                    rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;

                    // rcanvas1Bitmap.smoothing = true;
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
                    color = d[1] as uint;
                    rBGColorSave = color;
                    setBackgroundColor(color,true);
                }
                break;

                case "canvasSize":
                {
                    x = d[1] as Number;
                    y = d[2] as Number;
                    x2 = d[3] as Number;
                    y2 = d[4] as Number;
                    shape = d[5] as Boolean;
                    setReplayPanelSize(x,y,x2,y2,shape);
                }
                break;

                case "tempDone":
                {
                    rcanvas2BitmapData.draw(rcanvas2Draw);
                    rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
                    // rcanvas2Bitmap.smoothing = true;
                    cd2.clear();
                }
                break;

                case "drawDone":
                {
                    const tmpD2:Array = rLineStyleSave;
                    alpha = tmpD2[0] as Number;
                    blendMode = tmpD2[1] as String;
                    const canvasAlpha:ColorTransform = new ColorTransform(1,1,1,alpha);

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
                        rcanvas1BitmapData.draw(rcanvas2Bitmap,null,canvasAlpha,blendMode);
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
        }

        // private function doTickDrawClearCanvas():void
        // {
        //     rcanvas1BitmapData.dispose();
        //     rcanvas1BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
        //     rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
        // }

        // private function doTickDrawTempDrawDone(cd2:Graphics):void
        // {
        //     rcanvas2BitmapData.draw(rcanvas2Draw);
        //     rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;
        //     // rcanvas2Bitmap.smoothing = true;
        //     cd2.clear();
        // }

        // private function doTickDrawDrawDone(cd2:Graphics,d:Array):void
        // {
        //     const tmpD2:Array = rLineStyleSave;
        //     const alpha:Number = tmpD2[0] as Number;
        //     const blendMode:String = tmpD2[1] as String;
        //     const canvasAlpha:ColorTransform = new ColorTransform(1,1,1,alpha);

        //     rcanvas2BitmapData.draw(rcanvas2Draw);
        //     rcanvas2Bitmap.bitmapData = rcanvas2BitmapData;

        //     if(d[1] !== undefined && d[1])
        //     {
        //         const subLayer:BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
        //         subLayer.draw(rcanvas2Bitmap,null,canvasAlpha);
        //         subLayer.draw(rcanvas1Bitmap);
        //         rcanvas1BitmapData = subLayer.clone();
        //         rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
        //         subLayer.dispose();
        //     }
        //     else
        //     {
        //         rcanvas1BitmapData.draw(rcanvas2Bitmap,null,canvasAlpha,blendMode);
        //         rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
        //     }

        //     rcanvas2Bitmap.bitmapData = null;
        //     rcanvas2BitmapData.dispose();
        //     rcanvas2BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
        //     cd2.clear();
        // }

        // private function doTickDrawResizeCanvas(d:Array):void
        // {
        //     const width:Number = d[1] as Number;
        //     const height:Number = d[2] as Number;
        //     const moveX:Number = d[3] as Number;
        //     const moveY:Number = d[4] as Number;
        //     const movedFlag:Boolean = d[5] as Boolean;

        //     setPanelSizeReplayMode(width,height,moveX,moveY,movedFlag);
        // }

        // private function doTickDrawMirrorCanvas():void
        // {
        //     var mirrorBMPD:BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
        //     var flipMat:Matrix = new Matrix(-1,0,0,1,RCANVAS_WIDTH);

        //     mirrorBMPD.draw(rcanvas1BitmapData,flipMat);
        //     rcanvas1BitmapData = mirrorBMPD.clone();
        //     rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
        //     mirrorBMPD.dispose();
        //     mirrorBMPD = null;
        //     // rcanvas1Bitmap.smoothing = true;
        // }


        // private function doTickDrawBGColor(color:uint):void
        // {
        //     rBGColorSave = color;
        //     setBackgroundColor(color,true);
        // }

        // private function doTickDrawLassoTool(d:Array):void
        // {
        //     const lsbox:Sprite = lassoBox;
        //     const point1:Vector.<Number> = d[1];
        //     const point2:Array = d[2];
        //     const lassoInfo:Array = d[3];
        //     const copyFlag:Boolean = d[4];
        //     const lassoInfo0:Number = lassoInfo[0];
        //     const lassoInfo1:Number = lassoInfo[1];
        //     const lassoInfo2:Number = lassoInfo[2];
        //     const lassoInfo3:Number = lassoInfo[3];
        //     const lassoInfo4:Number = lassoInfo[4];
        //     const lassoInfo5:Number = lassoInfo[5];
        //     const lassoInfo6:Number = lassoInfo[6];
        //     const lassoDone:Boolean = doLassoDraw(true,point1,point2,copyFlag);

        //     function resetLassoBoxReplayMode():void
        //     {
        //         lassoBMP.filters = [];
        //         if(lassoBMP.bitmapData)
        //         {
        //             lassoBMP.bitmapData.dispose();
        //             lassoBMP.bitmapData = null;
        //         }

        //         lsbox.x = 0;
        //         lsbox.y = 0;
        //         lsbox.scaleX = 1.0;
        //         lsbox.scaleY = 1.0;
        //         lsbox.rotation = 0;
        //         lsbox.visible = false;
        //     }

        //     if(!lassoDone)
        //     {
        //         resetLassoBoxReplayMode();
        //         return;
        //     }

        //     var posMatrix:Matrix = new Matrix();

        //     posMatrix.scale(lassoInfo0,lassoInfo1);
        //     posMatrix.translate(Math.floor(-lassoInfo2/2),Math.floor(-lassoInfo3/2));
        //     posMatrix.rotate(lassoInfo4);
        //     posMatrix.translate(lassoInfo5,lassoInfo6);

        //     lassoBMP.smoothing = true;

        //     if(lassoInfo0 !== 1 || lassoInfo4 !== 0)
        //     {
        //         applyLassoShapen(lassoInfo0);
        //     }

        //     rcanvas1BitmapData.draw(lassoBMP,posMatrix);
        //     rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;

        //     // rcanvas1Bitmap.smoothing = true;

        //     resetLassoBoxReplayMode();
        // }

        // private function doTickDrawMoveImage(cd2:Graphics,d:Array):void
        // {
        //     var tempBitData:BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
        //     var movedMat:Matrix = new Matrix();

        //     movedMat.translate(d[1],d[2]);

        //     //최종적으로 움직인 거리를 실제로 비트맵 데이터 조작
        //     tempBitData.draw(rcanvas1BitmapData,movedMat);
        //     rcanvas1BitmapData = tempBitData.clone();
        //     rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
        //     // rcanvas1Bitmap.smoothing = true;
        //     tempBitData.dispose();
        //     tempBitData = null;
        // }
        // private function doTickDrawLineTool(cd2:Graphics,d:Array,updateCursorPos:Boolean):void
        // {
        //     const shape:Boolean = d[1] as Boolean;
        //     const size:Number = d[2] as Number;
        //     const color:uint = d[3] as uint;
        //     const alpha:Number = d[4] as Number;
        //     const x1:Number = d[5] as Number;
        //     const y1:Number = d[6] as Number;
        //     const x2:Number = d[7] as Number;
        //     const y2:Number = d[8] as Number;
        //     const blendMode:String = d[9] as String;
        //     const sublayerFlag:Boolean = d[10] as Boolean;

        //     rLineStyleSave = [alpha,blendMode];
        //     rcanvas2.alpha = alpha;

        //     if(replayStartON && d[10] !== undefined)
        //     {
        //         setReplaySubLayer(sublayerFlag);
        //     }

        //     cd2.lineStyle();
        //     if(shape) cd2.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
        //     else cd2.lineStyle(size,color);

        //     cd2.moveTo(x1,y1);
        //     cd2.lineTo(x2,y2);

        //     if(updateCursorPos) rTinyCursorPos = [x2,y2];
        // }

        // private function doTickDrawDot(cd2:Graphics,d:Array,updateCursorPos:Boolean):void
        // {
        //     //1 : shape
        //     //2 : size
        //     //3 : color
        //     //4 : alpha
        //     //5 : x
        //     //6 : y
        //     //7 : blend mode
        //     //8 : sublayer flag

        //     const size2:Number = d[2]/2;

        //     if(replayStartON && d[8] !== undefined)
        //     {
        //         setReplaySubLayer(d[8]);
        //     }

        //     rLineStyleSave = [d[4],d[7]];
        //     rcanvas2.alpha = d[4];
        //     cd2.lineStyle(0,0,0);
        //     cd2.beginFill(d[3]);

        //     if(d[1])
        //     {
        //         cd2.drawRect(x-size2,y-size2,d[2],d[2]);
        //     }
        //     else
        //     {
        //         cd2.drawCircle(x,y,size2);
        //     }

        //     if(updateCursorPos) rTinyCursorPos = [d[5],d[6]];

        //     cd2.endFill();
        // }

        // private function doTickDrawFillPen(cd2:Graphics,d:Array,updateCursorPos:Boolean):void
        // {
        //     //1 : color
        //     //2 : alpha
        //     //3 : blendMode
        //     //4 : commands
        //     //5 : path data
        //     //6 : sublayer Flag
        //     rLineStyleSave = [d[2],d[3]];
        //     rcanvas2.alpha = d[2];
        //     cd2.clear();
        //     cd2.lineStyle(1,d[1]);
        //     cd2.beginFill(d[1]);
        //     cd2.drawPath(d[4],d[5]);
        //     if(updateCursorPos) rTinyCursorPos = [d[5][0],d[5][1]];
        //     rSubLayerSave = d[6];
        // }

        // private function doTickDrawSqareLine(cd2:Graphics,d:Array):void
        // {
        //     //1 : size
        //     //2 : color
        //     //3 : alpha
        //     //4 : blend mode
        //     //5 : commands
        //     //6 : path data
        //     rcanvas2Bitmap.bitmapData = null;
        //     rcanvas2BitmapData.dispose();
        //     rcanvas2BitmapData = new BitmapData(RCANVAS_WIDTH,RCANVAS_HEIGHT,true,0);
        //     cd2.clear();

        //     rLineStyleSave = [d[3],d[4]];
        //     rcanvas2.alpha = d[3];
        //     cd2.lineStyle(d[1],d[2], 1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
        //     cd2.drawPath(d[5],d[6]);
        // }

        // private function doTickDrawLineTo(cd2:Graphics,d:Array,updateCursorPos:Boolean):void
        // {
        //     //1 :x
        //     //2 :y
        //     const x:Number = d[1] as Number;
        //     const y:Number = d[2] as Number;
        //     cd2.lineTo(x,y);
        //     if(updateCursorPos) rTinyCursorPos = [d[1],d[2]];
        // }

        // private function doTickDrawLineStyle(cd2:Graphics,d:Array):void
        // {
        //     const shape:Boolean = d[1] as Boolean;
        //     const size:Number = d[2] as Number;
        //     const color:uint = d[3] as uint;
        //     const alpha:Number = d[4] as Number;
        //     const x:Number =  d[5] as Number;
        //     const y:Number =  d[6] as Number;
        //     const blendMode:String = d[7] as String;
        //     const fillPenFlag:Boolean = d[8] as Boolean;
        //     const sublayerFlag:Boolean = d[9] as Boolean;

        //     rLineStyleSave = [alpha,blendMode];

        //     if(replayStartON && d[9] !== undefined)
        //     {
        //         setReplaySubLayer(sublayerFlag);
        //     }

        //     if(!fillPenFlag)
        //     {
        //         cd2.clear();
        //         rcanvas2.alpha = alpha;

        //         if(!shape)
        //         {
        //             rcanvas2Draw.graphics.lineStyle(size,color);
        //         }
        //         else
        //         {
        //             rcanvas2Draw.graphics.lineStyle(size,color,1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
        //         }

        //         cd2.moveTo(x,y);
        //     }
        //     else
        //     {
        //         cd2.clear();
        //         rcanvas2.alpha = 1.0;
        //         if(!shape)
        //         {
        //             rcanvas2Draw.graphics.lineStyle(1,color);
        //         }
        //         else
        //         {
        //             rcanvas2Draw.graphics.lineStyle(1,color,1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
        //         }
        //         cd2.beginFill(color);
        //         cd2.moveTo(x,y);
        //     }
        // }

        // private function doTickDraw(cd2:Graphics,updateCursorPos:Boolean=false):void
        // {
        //     const fr:Array = rFrameArr;

        //     if(fr.length === 0 || fr === null) return;

        //     const data:Array = fr[rFrame];
        //     const drawInfo:String = data[0];
        //     var shape:Boolean;
        //     var size:Number;
        //     var size2:Number; //dot에서 사각형 크기
        //     var color:uint;
        //     var alpha:Number;
        //     var x:Number;
        //     var y:Number;
        //     var x2:Number; //직선에서 끝점임, x y는 시작점
        //     var y2:Number;
        //     var blendMode:String;
        //     var fillPenFlag:Boolean;
        //     var subLayerFlag:Boolean;

        //     switch(drawInfo)//rep draw info
        //     {
        //         case "lineStyle":
        //         {
        //             doTickDrawLineStyle(cd2,data);
        //         }
        //         break;
        //         case "lineTo":
        //         {
        //             doTickDrawLineTo(cd2,data,updateCursorPos);
        //         }
        //         break;

        //         case "sqline":
        //         {
        //             doTickDrawSqareLine(cd2,data);
        //         }
        //         break;

        //         case "fill":
        //         {
        //             doTickDrawFillPen(cd2,data,updateCursorPos);
        //         }
        //         break;

        //         case "dot":
        //         {
        //             doTickDrawDot(cd2,data,updateCursorPos)
        //         }
        //         break;

        //         case "line":
        //         {
        //             doTickDrawLineTool(cd2,data,updateCursorPos);
        //         }
        //         break;

        //         case "move":
        //         {
        //             doTickDrawMoveImage(cd2,data);
        //         }
        //         break;

        //         case "lasso":
        //         {
        //             doTickDrawLassoTool(data)
        //         }
        //         break;
                
        //         case "mirror":
        //         {
        //             doTickDrawMirrorCanvas();
        //             break;
        //         }
        //         case "bgColor":
        //         {
        //             doTickDrawBGColor(data[1]);
        //         }
        //         break;

        //         case "canvasSize":
        //         {
        //             doTickDrawResizeCanvas(data);
        //         }
        //         break;

        //         case "tempDone":
        //         {
        //             doTickDrawTempDrawDone(cd2);
        //         }
        //         break;
                
        //         case "drawDone":
        //         {
        //             doTickDrawDrawDone(cd2,data);
        //         }
        //         break;

        //         case "clear":
        //         {
        //             doTickDrawClearCanvas();
        //         }
        //         break;
        //     }
        //     rFrame++;
        // }

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

        private function doDrawSlowEventStart():void
        {
            replayStartON = true;
            doDrawSlowEventON = true;
            //stage.frameRate = 24;
            stage.removeEventListener(Event.ENTER_FRAME,doDrawEvent);
            rFileStream.close();
            stage.addEventListener(Event.ENTER_FRAME,doDrawSlowEvent);
        }

        private function doDrawSlowEvent(e:Event):void
        {
            // rReplay30Fps = !rReplay30Fps;
            // if(rReplay30Fps === true)
            // {

            // }
            // else
            // {
            // }
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
            // rReplay30Fps = !rReplay30Fps;
            // if(rReplay30Fps === true)
            // {

            // }
            // else
            // {
            // }
            doDraw(rSpeed,0);
        }

        //skipFlag  0: 기본 재생 1:탐색바를 마우스를 이용하여 스킵, 2:one frame 이전스트로크, 3:one frame 이후 스트로크
        private function doDraw(skipCount:Number,skipFlag:uint):void
        {
            //skipflag 1번은 마우스 커서로 무작위 스킵, 2,3번은 스트로크 단위혹은 프레임 단위로 앞뒤로 탐색
            if(replayStartON === false && !skipFlag) return;

            if(skipCount > REPLAY_SLOWDRAW_ACTIVE_SPEED)
            {
                if(REPLAY_FASTEST_TOTAL_TIME > 60 && skipFlag === 0)
                {
                    doDrawSlowEventStart();
                    return;
                }
            }

            const cd2:Graphics = rcanvas2Draw.graphics;
            const rDataLen:uint = rData.length;
            const tcursor:SimpleButton = rCursor;
            const _rfs:FileStream = rFileStream;
            const CACHE_DIV_10:Number= Math.floor(IMG_CACHE_INTERVAL/10);
            const drawLimit:Number = skipCount-1;
            var rFrameLimit:Number = rFrameArr.length-1; //rframe 인덱스 0번 기준
            var obj:Array;
            var prevSkipImageSaveCount:Number = 0;
            var prevSkipImageSaveIndex:uint = 0;

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
                            
                            //수동 탐색할때 속도를 위해서 썸네일 이미지를 더 잘게 쪼개줌
                            if(skipFlag === 1 || skipFlag === 2)
                            {
                                if(prevSkipImageSaveCount >= CACHE_DIV_10)
                                {
                                    prevSkipImageSaveCount = 0;
                                    if(!rDataPreviewCacheImages[prevSkipImageSaveIndex])
                                    {
                                        const repBmpd:BitmapData = rcanvas1BitmapData;
                                        rDataPreviewCacheImages[prevSkipImageSaveIndex] = [repBmpd.clone(),repBmpd.width,repBmpd.height,RCANVAS_BG_COLOR,rFileCutBytes,rFrameSum];
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

                            if(rData.length > 0)
                            {
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

                        rFrameArr = rData[rIndex];
                        rFrameLimit = rFrameArr.length-1;

                        i--;
                        continue;
                    }
                }
        
                doTickDraw(cd2,(skipFlag >= 2) ? true : (i === drawLimit));
                
                rFrameSum++; //resultFrameSum 으로 대체함
            }

            const nt:int = getTimer();
            var totalF:Number;

            

            if(skipFlag === 0)
            {
                if(nt-rFrameCursorDelayTime >= 70)
                {
                    tcursor.x = rTinyCursorPos[0];
                    tcursor.y = rTinyCursorPos[1];
                    rFrameCursorDelayTime = nt;
                    
                    if(!mouseClickON)
                    {
                        checkAutoScroll(rTinyCursorPos[0],rTinyCursorPos[1],rzoomed);
                    }
                }

                if(nt-rFrameTextDelayTime >= 1000) //갱신 느리게 해줌
                {
                    totalF = TOTAL_FRAME;
                    const getTimeStr:String = getReplayTime(skipCount,totalF-rFrameSum);
                    const timeStr:String = " ("+getTimeStr+")";
                    replayTimeBox["frameInfo"].text = rFrameSum+" / " + totalF + timeStr;
                    rFrameTextDelayTime = nt;
                }
            }
            else if(doDrawSlowEventON === false)
            {
                totalF = TOTAL_FRAME;
                replayTimeBox["frameInfo"].text = rFrameSum+" / " +totalF;
            }
            if(!rSkipMouseON)
            {
                totalF = TOTAL_FRAME;
                replayTimeBox["replayNowBar"].width = replayTimeBox["replayTotalBar"].width*rFrameSum/totalF;
            }
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
            rCanvasBounds = getBoundRect(rcanvas1);
        }

        // private function checkAutoScroll(x:Number,y:Number,rzoomed:Number):void
        // {
        //     const abs:Function = Math.abs;
        //     const floor:Function = Math.floor;
        //     const stW:Number = stage.stageWidth;
        //     const stH:Number = stage.stageHeight; //프레임 탐색막대 길이 빼줌
        //     const b:Object = rCanvasBounds;
        //     const left:Number = b.left;
        //     const right:Number = b.right;
        //     const top:Number = b.top;
        //     const bottom:Number = b.bottom;
        //     const centerMoveX:Number = floor(stW/2-(right+left)/2); //캔버스 중점위치, 창 중점위치 사이 거리
        //     const centerMoveY:Number = floor(stH/2-(bottom+top)/2);

        //     if(right-left < stW && abs(centerMoveX) <= 15
        //     && bottom-top < stH && abs(centerMoveY) <= 15) //캔버스가 창안 정가운데 위치해 있으면 그냥 리턴
        //     {
        //         return;
        //     }

        //     const _rregPoint:Sprite = rregPoint;
        //     const zerop:Point = new Point(0,0);
        //     const g:Point = rcanvas1.localToGlobal(zerop);
        //     const rg:Point = rotatePoint(x,y,-_rregPoint.rotation); //회전된 값을 넣어주어야함
        //     const z:Number = rzoomed;
        //     const cursorX:Number = g.x+(rg.x*z);//rcanvas1 글로벌 좌표에
        //     const cursorY:Number = g.y+(rg.y*z);//회전된 캔버스에서 커서 위치를 더해줌. 즉 윈도우 기준에서 커서 커서 위치를 구하는거임
        //     const innerLimitX:Number = stW/10;
        //     const innerLimitY:Number = stH/10;

        //     //캔버스 크기가 창크기보다 작고 중점간거리가 -+15 이상이면 중앙으로 옮겨줌
        //     if(right-left < stW && abs(centerMoveX) > 15)
        //     {
        //         _rregPoint.x += centerMoveX;
        //         updateReplayCanvasBounds();
        //     }//캔버스 절반과 커서의 거리에 1/5을 곱한 거리를 움직여줌
        //     else if(left < 0 && cursorX < innerLimitX)
        //     {
        //         _rregPoint.x += floor(abs((cursorX-stW/2)/5));
        //         updateReplayCanvasBounds(); 
        //     }
        //     else if(right > stW && cursorX > stW-innerLimitX)
        //     {
        //         _rregPoint.x -= floor(abs((cursorX-stW/2)/5));
        //         updateReplayCanvasBounds();
        //     }

        //     if(bottom-top < stH && abs(centerMoveY) > 15)
        //     {
        //         _rregPoint.y += centerMoveY;
        //         updateReplayCanvasBounds();
        //     }
        //     else if(top < offsetY && cursorY < innerLimitY)
        //     {
        //         _rregPoint.y += floor(abs((cursorY-stH/2)/5));
        //         updateReplayCanvasBounds();
        //     }
        //     else if(bottom > stH && cursorY > stH-innerLimitY)
        //     {
        //         _rregPoint.y -= floor(abs((cursorY-stH/2)/5));
        //         updateReplayCanvasBounds();
        //     }
        // }

        private function checkAutoScroll(x:Number,y:Number,rzoomed:Number):void
        {
            const abs:Function = Math.abs;
            const floor:Function = Math.floor;
            const offsetY:Number = topBar.BARSIZE+replayTimeBox.BARSIZE;
            const stW:Number = stage.stageWidth;
            const stH:Number = stage.stageHeight-offsetY; //프레임 탐색막대 길이 빼줌
            const b:Object = rCanvasBounds;
            const left:Number = b.left;
            const right:Number = b.right;
            const top:Number = b.top;
            const bottom:Number = b.bottom;
            const padding:Number = 50;

            if((cursorX > padding && cursorX < stW-padding
            && cursorY > padding+offsetY && cursorY < stH-padding)
            || stW-padding*2 < padding || stH-padding*2 < padding)
            {
                return;
            }

            const _rregPoint:Sprite = rregPoint;
            const zerop:Point = new Point(0,0);
            const g:Point = rcanvas1.localToGlobal(zerop);
            const rg:Point = rotatePoint(x,y,-_rregPoint.rotation); //회전된 값을 넣어주어야함
            const z:Number = rzoomed;
            const cursorX:Number = g.x+(rg.x*z);//rcanvas1 글로벌 좌표에
            const cursorY:Number = g.y+(rg.y*z);//회전된 캔버스에서 커서 위치를 더해줌. 즉 윈도우 기준에서 커서 커서 위치를 구하는거임

            if(cursorX < padding)
            {
                _rregPoint.x += floor(abs((cursorX-stW/2)/3));
                updateReplayCanvasBounds(); 
            }
            else if(cursorX > stW-padding)
            {
                _rregPoint.x -= floor(abs((cursorX-stW/2)/3));
                updateReplayCanvasBounds();
            }

            if(cursorY < padding+offsetY)
            {
                _rregPoint.y += floor(abs((cursorY-stH/2)/3));
                updateReplayCanvasBounds();
            }
            else if(cursorY > stH-padding)
            {
                _rregPoint.y -= floor(abs((cursorY-stH/2)/3));
                updateReplayCanvasBounds();
            }
        }

        private function getReplayRemainTime():void
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
            if(totalF <= STAGE_FRAME*3) return;

            const topBar:topMenu = topBar;
            const abs:Function = Math.abs;
            const floor:Function = Math.floor;
            const set:Sprite = topBar.replaySpeedSet;
            const minDist:Number = topBar["replaySpeedBar"].x;
            const maxDist:Number = minDist+topBar["replaySpeedBar"].width;
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

                const finalStr:String = "Playback speed ×"+rSpeed+" ("+timeStr+")";
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
                // getReplayRemainTime();
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,replaySpeedButtomMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,replaySpeedButtomUpEvent);
            }
            function replaySpeedButtomMoveEvent(e:MouseEvent):void
            {
                moveButton(set.mouseX);
            }
            moveButton(set.mouseX);
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

        private function getCacheImageIndex(targetFrame:Number):Number
        {
            const arr:Array = rDataPreviewCacheImages;
            var low:Number = 0;
            var high:Number = arr.length-1;
            if(high === 0)
            {
                return 0;
            }
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

        //targetFrame이 rSkipImageFrameData데이터에 몆번 인덱스에 있나 구해줌
        private function getSkipImageIndex(targetFrame:Number):Number
        {
            const arr:Array = rSkipImageFrameData;
            var low:Number = 0;
            var high:Number = arr.length-1;
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

        private function setSkipOneFrame(prev:Boolean,useKey:Boolean=false,trueOneFrame:Boolean=false):void
        {
            var cancelFlag:Boolean = false;

            if(replayStartON) stopReplay();
  
            topBar["reRecordingButton"].visible = true;

            function skipOneFrame():void
            {
                const _rFrameSum:Number = rFrameSum;

                if(trueOneFrame)
                {
                    if(prev && _rFrameSum > 0) setSkipFrame(_rFrameSum-1);
                    else if(!prev && _rFrameSum < TOTAL_FRAME) setSkipFrame(_rFrameSum+1);
                }
                else
                {
                    var goFrame:Number = rFrameSum+rFrameArr.length-rFrame+1;
                    if(prev && _rFrameSum > 0)
                    {
                        if(rFrame <= 0) //데이터 머리 경계면에서 이전 탐색 미리해줌 버튼2번씩 눌러야하는거 방지
                        {
                            setSkipFrame(_rFrameSum-1,2);
                        }
                        goFrame = rFrameSum-(rFrame+1);

                        setSkipFrame(goFrame,2);

                        if(rOneSkipFlag !== prev)
                        {
                            goFrame = rFrameSum-(rFrame+1)
                            setSkipFrame(goFrame,2);
                        }
                    }
                    else if(!prev && _rFrameSum < TOTAL_FRAME)
                    {
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

            function autoOneFrameSkipEvent(e:Event):void
            {
                skipOneFrame();
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

            skipOneFrame();
        }

        private function setSkipFrame(jumpframe:Number,flag:uint=1):void //skipp 
        {
            //flag = 1 //딱 한프레임만 스킵할때
            //flag = 2 //이전 탐색 할때 올려줌
            //flag = 3 //앞 탐색 할때 올려줌
            const fSum:Number = rFrameSum;
            
            if(jumpframe < 0) jumpframe = 0;
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

            // if(replayModeONFirstSkip) //키고나서 바로 스킵해주었을때 캔버스 다 지워주고
            // {
            //     replayModeONFirstSkip = false;
            //     clearCanvasReplayMode();
            // }

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

            // if(mouseClickON === false)
            // {
            //     getReplayRemainTime();
            // }

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
            checkAutoScroll(tcursor.x,tcursor.y,rzoomed);
        }

        private function setSkipFrameButton():void
        {
            const totalF:Number = TOTAL_FRAME;
            if(totalF === 0 || rSkipImageInit > 0) return;

            //리플레이 플레이 중인지 아닌지 플래그 미리 저장해둠
            var replayStartONSave:Boolean = false;

            if(replayStartON)
            {
                //stage.frameRate = 24;
                replayStartONSave = true;
                replayStartON = false;
                stage.removeEventListener(Event.ENTER_FRAME,doDrawEvent);
                stage.removeEventListener(Event.ENTER_FRAME,doDrawSlowEvent);
                rFileStream.close();
            }

            const floor:Function = Math.floor;
            const totalBar:SimpleButton = replayTimeBox["replayTotalBar"];
            const totalBarScale:Number = totalBar.scaleX;
            const nowBar:SimpleButton = replayTimeBox["replayNowBar"];
            const maxWidth:Number = totalBar.width;//replayPrograssBaseBarWidth*scaleX;
            var clickedX:Number = totalBar.mouseX*totalBarScale;
            var skipUpdateTimer:uint = 0;
            // var mousemoved:Boolean = false;
            var oldFrame:Number = floor(totalF*clickedX/maxWidth);
            var finalFrame:Number = 0;

            rSkipMouseON = true;
            nowBar.width = clickedX;
            getReplayRemainTime();

            function replayTimeMouseUpEvent(e:MouseEvent):void
            {
                rSkipMouseON =false;
                clearTimeout(skipUpdateTimer);
                var mx2:Number = totalBar.mouseX*totalBarScale;
                if(mx2 < 0) mx2 = 0;
                else if(mx2 > maxWidth) mx2 = maxWidth;

                nowBar.width = mx2;
                setSkipFrame(floor(totalF*mx2/maxWidth));

                //skipframe함수 이후에 실행
                if(!replayStartONSave)
                {
                    checkCutFrameButtons();
                }
                //재생중에 스킵하고 있었으면 다시 시작
                if(replayStartONSave && !replayAllEnd) startReplay();
                else if(replayAllEnd) stopReplay();

                stage.removeEventListener(MouseEvent.MOUSE_MOVE,replayTimeMouseMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP,replayTimeMouseUpEvent);
            }

            function replayTimeMouseMoveEvent(e:MouseEvent):void
            {
                if(limitMouseMoveEventTime(getTimer()) === true) return;

                var mx2:Number = totalBar.mouseX*totalBarScale;
                if(mx2 < 0) mx2 = 0;
                else if(mx2 > maxWidth) mx2 = maxWidth;

                finalFrame = floor(totalF*mx2/maxWidth);

                nowBar.width = mx2;
                replayTimeBox["frameInfo"].text = finalFrame+" / " +totalF;

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
            if(replayStartON || TOTAL_FRAME === 0) return; //혹시 몰라서 중복 클릭 제거 걸어줌
            const tb:Sprite = topBar;

            //stage.frameRate = 30;

            replayStartON = true;
            // replayModeONFirstSkip = false;

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

            stage.addEventListener(Event.ENTER_FRAME,doDrawEvent);
        }

        //똑같은 이름에 배경색이 다를경우 raw파일 배경색 이름을 업데이트 해줌
        private function moveToolBoxByType(type:int=0):void
        {
            var xBox:Sprite = null;

            if(type === 1) xBox = lassoMenu;
            else if(type === 2) xBox = traceMenuBox;

            mouseClickPos[0] = mouseX;
            mouseClickPos[1] = mouseY;

            setTopChildIndex(xBox);

            function toolBoxMoveMouseUpEvent(e:MouseEvent):void
            {
                checkBoxPosition(xBox);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, toolBoxMoveMouseMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP, toolBoxMoveMouseUpEvent);
            }

            function toolBoxMoveMouseMoveEvent(e:MouseEvent):void
            {
                xBox.x += mouseX-mouseClickPos[0];
                xBox.y += mouseY-mouseClickPos[1];

                mouseClickPos[0] = mouseX;
                mouseClickPos[1] = mouseY;
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

            // if(targetName !== null && targetName.indexOf("tool") !== -1)
            // {
            //     // const target:DisplayObject = e.target as DisplayObject;
            //     // updateToolBoxMousePos(target);
            // }

            switch(targetName)
            {
                case "toolPen":
                {
                    if(fillPenON === true)
                    {
                        fillPenON = false;
                        // penFillCursorON = true;
                    }
                    selectPenTool();
                }
                break;
                case "toolFillPen":
                {
                    if(fillPenON === false) 
                    {
                        selectFillPen();
                    }
                }
                break;
                case "toolErase":
                {
                    if(nowTool !== TOOL_ERASE) 
                    {
                        selectEraseTool();
                    }
                }
                break;
                case "toolLine":
                {
                    if(nowTool !== TOOL_LINE) 
                    {
                        selectPenTool(true);
                    }
                }
                break;
                case"toolEraseLine":
                {
                    if(nowTool !== TOOL_LINE_ERASE) 
                    {
                        selectEraseTool(true);
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
                    consoleBox.print("Flip canvas "+((mirrorON) ? "ON":"OFF"))
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
                    // selectZoomTool();
                }
                break;

                case "toolTrace":
                {
                    if(traceMenuON === false) openTraceMenu();
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
                // toolTipTextBG.height = toolTipText.textHeight+1;
            }

            setTopChildIndex(_toolTipBox);
        }

        //drag load
        private function setDragDropSelectBoxCenterPos():void
        {
            const box:loadBox = fileDragSelectBox;
            const bg:Shape = box["dragDropFileBG"];
            bg.x = 0;
            bg.y = 0;
            bg.width = 1;
            bg.height = 1;
            box.scaleX = 1;
            box.scaleY = 1;
            
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
            const textBox:TextField = box["fileNameInfo"];
            if(filename !== "")
            {
                textBox.text = filename;
            }
            if(box.visible === false)
            {
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
                    if(!replayModeON) openTraceMenu();
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
                    consoleBox.print("Failed to load file");
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

                        if(!replayModeON) openTraceMenu();
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
                    if(file.nativePath.lastIndexOf(".2020") !== -1)
                    {
                        if(!isReference)
                        {
                            loadReplayFile(file,file.name,file.nativePath);
                        }
                        else
                        {
                            loadRawFileToReferenceLayer(file);
                            if(!replayModeON) openTraceMenu();
                        }
                        
                        fs.close();
                        fs.removeEventListener(Event.COMPLETE, completeHandler);
                        fs.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
                        fs = null;
                    }
                    // else if(file.nativePath.lastIndexOf(".gif") !== -1)
                    // {
                    //     loadGIFImage(file);
                    //     fs.close();
                    //     fs.removeEventListener(Event.COMPLETE, completeHandler);
                    //     fs.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
                    //     fs = null;
                    // }
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

            if(index > arr.length-1)
            {
                return;
            }
            const pickedColor:uint = arr[index];
            var c:Vector.<uint> = HEXtoRGB(pickedColor);
            var findIndex:uint = arr.lastIndexOf(pickedColor);
            const colorHint:String = "RGB "+c[0]+","+c[1]+","+c[2];
            // pickerLastHint = colorHint;

            updateOpaBoxColor(pickedColor);
            
            if(_pickerMode === 2)
            {
                colorHistoryList[0] = pickedColor;
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
                    selectPenTool(true);
                }
                else
                {
                    if(fillPenON)
                    {
                        selectFillPen();
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
            else //이미 컬러가 있으면 그냥 업뎃
            {
                checkColorHistoryLastColor(color,true);
            }
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
                if(findIndex === 0) //백그라운드 컬러이면 예외적으로 처리
                {
                    arr.push(color);
                    arr.splice(1,1);
                }
                else
                {
                    colorHistoryList.push(arr.splice(findIndex,1)[0]);
                }
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
                    arr.splice(1,1);
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
                if(x%10===0)
                {
                    x = 0;
                    y += colorHistoryRectH;
                }
            }
            cg.endFill();
        }

        private function makeResizeButtonFamily():void
        {
            const _regPoint:Sprite = regPoint;
            const color:uint = RESIZE_BUTTON_COLOR;

            function drawRect(ent:Object):void
            {
                const g:Graphics = ent.graphics;
                g.clear();
                g.lineStyle(0,0,0);
                g.beginFill(color);
                g.drawRect(0,0,20,20);
                g.endFill();
            }

            drawRect(resizeButtonR);
            drawRect(resizeButtonD);
            drawRect(resizeButtonL);
            drawRect(resizeButtonU);

            resizeButtonR.name = "resizeButtonR";
            resizeButtonD.name = "resizeButtonD";
            resizeButtonL.name = "resizeButtonL";
            resizeButtonU.name = "resizeButtonU";

            regPoint.addChild(resizeButtonU);
            regPoint.addChild(resizeButtonD);
            regPoint.addChild(resizeButtonL);
            regPoint.addChild(resizeButtonR);
        }

        private function eraseLineReadyKeyDownEvent(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;
            if(keyCode === KEY.shift)//이벤트 계속 추가 되는거 한번만 되게 막아줌
            {
                if(nowTool !== TOOL_LINE_ERASE)
                {
                    stage.removeEventListener(KeyboardEvent.KEY_DOWN, eraseLineReadyKeyDownEvent);
                    stage.addEventListener(KeyboardEvent.KEY_UP, eraseLineReadyKeyUpEvent);
                    selectEraseTool(true);
                }
            }
        }

        private function eraseLineReadyKeyUpEvent(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;
            if(keyCode === KEY.shift)//이벤트 계속 추가 되는거 한번만 되게 막아줌
            {
                if(nowTool !== TOOL_ERASE)
                {
                    if(nowKey === KEY.d || nowKey === KEY.j)
                    {
                        stage.addEventListener(KeyboardEvent.KEY_DOWN, eraseLineReadyKeyDownEvent);
                        stage.removeEventListener(KeyboardEvent.KEY_UP, eraseLineReadyKeyUpEvent);
                        selectEraseTool();
                    }
                }
            }
        }

        private function setDeactiveResizeButton():void
        {
            if(reizeButtonClickEnt !== null)
            {
                setColorTransform(reizeButtonClickEnt as DisplayObject,uiColorSet[uiColorIndex][3]);
                reizeButtonClickEnt = null;
                toolTipBox.visible = false;
            }
            penCursorOFFFlag = false;
        }

        private function setActiveResizeButton(target:Sprite):void
        {
            setColorTransform(target,0xD3EFFF);
            reizeButtonClickEnt = target;
            setTopChildIndex(target);

            resizeButtonActive = true;
            penCursorOFFFlag = true;
            toolTipBox.visible = true;

            setToolTipString(CANVAS_WIDTH+" x "+CANVAS_HEIGHT);
        }

        private function canvasSizeButtonMouseUPEvent(e:MouseEvent):void
        {
            toolTipBox.visible = false;
            resizeButtonActive = false;

            setDeactiveResizeButton();
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, canvasSizeButtonMouseUPEvent);
            stage.removeEventListener(MouseEvent.MOUSE_UP, canvasSizeButtonMouseUPEvent);
        }

        private function makeSkipImage():void //loadrep
        {
            const fs:FileStream = new FileStream();
            const cd2:Graphics = rcanvas2Draw.graphics;
            const rf:File = repFile;
            const totalSize:Number = rf.size;
            const _IMG_CACHE_INTERVAL:uint = IMG_CACHE_INTERVAL;
            // const _appInfoBox:appInfoBar = appInfoBox;
            const replayInfoText:TextField = replayTimeBox["frameInfo"];
            var _frameSum:Number = 0;
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
                    _frameSum += dlen;
                    _rSkipImageCount += dlen;
                    
                    for(var i:uint=0;i<dlen;i++)
                    {
                        _doTickDraw(cd2,false);
                    }

                    rFrame = 0;

                    if(_rSkipImageCount > _IMG_CACHE_INTERVAL)
                    {
                        rSkipImageFrameData.push(_frameSum); //순서 중요 skipimg:File변수보다 먼저 와야함

                        // const percRaw:Number = (totalSize-namojiBytes)/totalSize;
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
                const _rData:Array = rData;//.concat();
                // const _rDataFrame:Array = rDataFrame;//concat();
                const _traceBmpd:BitmapData = canvasTraceBitmapData;
                var newRectangle:Rectangle = new Rectangle(0,0,rImgDataW,rImgDataH);
                // var _rFileMaxFrame:Number = rFileTotalFrame;

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
                    // const c:Number = _rDataFrame[i] as Number;
                    fs.writeObject(_readUndoArray);
                    // _rFileMaxFrame += c;
                }

                if(mirrorPushON) //임시 미러가 되어있을때 진짜 캔버스로 반전되어있는데 리플레이 데이터에는 아직 써주지 않았으니까 넣어줌
                {
                    const tempMirrorData:Array = [["mirror"]];
                    fs.writeObject(tempMirrorData);
                    // _rFileMaxFrame++;
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

                consoleBox.print(" > 2020 file " + repFileSizeStr);
                consoleBox.print(" > png file " + imageFileSizeStr);
                consoleBox.print("File saved successfully");

                // buttonEffect(topBar["saveButton"]);
            }
        }
    
        private function loadReplayFile(oldFile:File,fileName:String,filePath:String):void //loadrep
        {
            //mouse down 이벤트 지워주고 make skip image while break해줄때 다시 추가해줌
            // stage.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownEvent);
            removeMainEvent();

            if(replayModeON) setReplayUI(false);

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

            function tempErrorMsg():void
            {
                fs.close();
                if(repFileTemp.exists) repFileTemp.deleteFile();

                consoleBox.print("Failed to load file");
            }

            try//2020확장자여도 전혀 연관없는 파일일수도 있어서 try씌워줌
            {
                while(1)
                {
                    if(fs.bytesAvailable === 0) break;
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
                        // TOTAL_FRAME = d[5];
                        // rFileTotalFrame = d[5];
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
            }
            catch(err:Error) //실패하면 무시
            {
                fs.close();
                tempErrorMsg();
                return;
            }

            if(errorFlag)
            {
                fs.close();
                tempErrorMsg();
                return;
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
            const fs:FileStream = new FileStream();
            var errorFlag:Boolean = true;
            fs.open(file,FileMode.READ);

            function tempErrorMsg():void
            {
                fs.close();
                consoleBox.print("Failed to load file");
            }
            var finalIMGBMPD:BitmapData = new BitmapData(1,1,true,0);

            try//2020확장자여도 전혀 연관없는 파일일수도 있어서 try씌워줌
            {
                while(1)
                {
                    if(fs.bytesAvailable === 0)
                    {
                        break;
                    }
                    const d:Array = fs.readObject() as Array;
                    if(d[0] === "rFinalImage")//최종 이미지
                    {
                        errorFlag = false;
                        const ba2:ByteArray = d[1] as ByteArray;
                        const newRectangle:Rectangle = new Rectangle(0,0,d[2],d[3]);
                        ba2.uncompress();
                        errorFlag = false;
                        finalIMGBMPD = new BitmapData(d[2],d[3],true,0);
                        finalIMGBMPD.lock();
                        finalIMGBMPD.setPixels(newRectangle,ba2);
                        finalIMGBMPD.unlock();
                        ba2.clear();
                    }
                }
            }
            catch(err:Error) //실패하면 무시
            {
                tempErrorMsg();
                return;
            }

            if(errorFlag)
            {
                tempErrorMsg();
                return;
            }

            pasteTraceImage(finalIMGBMPD,finalIMGBMPD.width,finalIMGBMPD.height);
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
            consoleBox.print("Image loaded successfully");
            // buttonEffect(topBar["loadButton"]);
        }

        private function loadFileAfter(fileName:String,filePath:String, width:uint,height:uint,imageData:IBitmapDrawable,cloneFlag:Boolean,newBG:uint=0xFFFFFF):void
        {
            if(!imageData)
            {
                consoleBox.print("Failed to load file");
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
            // var bgColor:uint = newBG;

            if(captureModeON) captureOFF();
            rSpeed = 1; //속도 리셋
            topBar.replaySpeedMoveButton.x = topBar["replaySpeedBar"].x;
            resetReplayTime();
            clearCanvasReplayMode();
            replayTimeBox["frameInfo"].text = "0 / " + getTotalFrame()+" frame";
            replayTimeBox["replayNowBar"].width = 0;

            setBackgroundColor(newBG);
            setBackgroundColor(newBG,true);

            const findExt:int = fileName.lastIndexOf(".2020");

            if(findExt !== -1)
            {
                fileName = fileName.substr(0,findExt)+".png";
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
            setTimerResetButton();
            setSubLayer(false);
            setReplaySubLayer(false);
            // checkUsedMemory();
        }

        private function loadFile(subLayer:Boolean=false):void
        {
            if(replayStartON) stopReplay();
            // rFileStream.close();

            if(lassoToolON || browseWindowON) return;

            var newFileFilter:FileFilter = new FileFilter("Image or 2020 file", "*.2020;*.png;*.jpg;*.gif");
            var windowTitle:String = "Open file";
            var imgExt:Array = [newFileFilter];

            if(subLayer === true)
            {
                newFileFilter = new FileFilter("Image file", "*.png;*.jpg;*.gif");
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

                if(subLayer === true)
                {
                    pasteTraceImage(loaderInfo.loader,loaderInfo.width,loaderInfo.height);
                }
                else
                {
                    loadImageFile(file.name,file.nativePath,loaderInfo.width,loaderInfo.height,loaderInfo.loader);
                }

                loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, loadErrorEvent);
                loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loadFileCompleteEvent);
                loader.unload();
                loader = null;
            }

            function loadErrorEvent(e:Event):void
            {
                browseWindowON = false;
                //에러나면 아무것도 안해줌
                loader = null;
                consoleBox.print("Failed to load file");
            }

            function onCancelEvent(e:Event):void
            {
                browseWindowON = false;
                file.removeEventListener(Event.SELECT, fileSelectHandler);
                file.removeEventListener(Event.COMPLETE, fileSelectCompleteHandler);
                file.removeEventListener(Event.CANCEL, onCancelEvent);
            }

            function fileSelectHandler(e:Event):void
            {
                browseWindowON = false;
                tempFileName = file.name;

                file.removeEventListener(Event.SELECT, fileSelectHandler);
                file.load();
            }

            function fileSelectCompleteHandler(e:Event):void
            {
                browseWindowON = false;
                if(file.nativePath.lastIndexOf(".2020") !== -1)
                {
                    loadReplayFile(file,file.name,file.nativePath);
                }
                // else if(file.nativePath.lastIndexOf(".gif") !== -1)
                // {
                //     loadGIFImage(file);
                // }
                else
                {
                    loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadErrorEvent);
                    loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadFileCompleteEvent);
                    loader.loadBytes(file.data);
                }

                file.removeEventListener(Event.SELECT, fileSelectHandler);
                file.removeEventListener(Event.COMPLETE, fileSelectCompleteHandler);
                file.removeEventListener(Event.CANCEL, onCancelEvent);
            }

            browseWindowON = true;

            file.browseForOpen(windowTitle,imgExt);
            file.addEventListener(Event.SELECT, fileSelectHandler);
			file.addEventListener(Event.COMPLETE, fileSelectCompleteHandler);
            file.addEventListener(Event.CANCEL, onCancelEvent);
        }

        private function setCaptureUI(flag:Boolean):void
        {
            //함수 변수가 true가 직관적이라서 없애주는 변수는 반대로해줌
            const iFlag:Boolean = !flag;
            const tb:Sprite = topBar;
            const transChecker:SimpleButton = tb["capTransCheck"];
            const replayMode:Boolean = replayModeON;
            const bottomTopbar:Boolean = topBarON === 2;

            canvasGrid.visible = iFlag;

            if(replayMode)
            {
                replayTimeBox.visible = iFlag;
            }
            else
            {
                sideBar.visible = iFlag;
                resizeButtonR.visible = iFlag;
                resizeButtonL.visible = iFlag;
                resizeButtonD.visible = iFlag;
                resizeButtonU.visible = iFlag;
            }

            if(flag === true)
            {
                penSizeCursor.visible = false;
                // penSizeCursor2.visible = false;

                if(traceMenuON === true) traceMenuBox.visible = false;
                if(captureTransBGON) transChecker.visible = true;
                else transChecker.visible = false;
                changeTopBarIcons("capture");
            }
            else 
            {
                if(transChecker.visible === true) transChecker.visible = false;
                appInfoBox.updateCanvasInfo();

                if(replayMode)
                {
                    changeTopBarIcons("replay");
                }
                else
                {
                    if(traceMenuON === true) traceMenuBox.visible = true;
                    changeTopBarIcons("draw");
                }
            }
        }

        //캡쳐영역 그리기 시작전에 설정 세팅해줌
        private function captureKeyUpEvent(e:KeyboardEvent):void
        {
            if(e.keyCode === KEY.s)
            {
                fullCaptureReady = true;
            }
        }

        private function captureKeydownEvent(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;

            if(keyCode == KEY.s || keyCode == KEY.k)
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
            else if(keyCode === KEY.a || keyCode == KEY.l)
            {
                setCaptrueFlipButton();
            }
            else if(keyCode === KEY.d || keyCode === KEY.j)
            {
                setCaptureTransButton();
            }
            else if(e.keyCode === KEY.esc)
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
            if(captureModeON) return;
            if(replayStartON) stopReplay();

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
            const b:Object = capturePanelData;
            const xBitmap:Bitmap = (replayMode) ? rcanvas1Bitmap : canvas1Bitmap;

            xBitmap.smoothing = false;

            captureModeON = false;
            penCursorOFFFlag = false;
            xCaptureRect.graphics.clear();
            xCaptureRect.visible = false;
            xcapturePreviewCursor.visible = false;

            setCaptureUI(false);

            //캔버스 이전 모양 위치로 복원
            xReg.rotation = b.r;
            xReg.x = b.x + captureWindowMove[0];
            xReg.y = b.y + captureWindowMove[1];
            xPanel.x = b.px;
            xPanel.y = b.py;

            setZoomCanvas(b.z,replayMode);
            toolTipBox.visible = false;
            captureWindowMove = [0,0];

            if(replayMode)
            {
                resetTransBG(true);
                changeTopBarIcons("replay");
                rCursor.visible = true;
            }
            else if(!replayMode)
            {
                resetTransBG(false);
                updateResizeButtonPos();
                addKeyEvent();
            }

            checkCanvasPanelPos(replayMode);
        }
        //마우스 클릭하면 캡쳐 영역그리는 함수
        private function drawCaptureArea():void
        {
            const floor:Function = Math.floor;
            const abs:Function = Math.abs;
            const replayMode:Boolean = replayModeON;
            const scZoomed:Number = captureZoomed;

            var xCaptureRect:Shape = capturePreviewRect;
            var xReg:Sprite = regPoint
            var xPanel:Sprite = canvasPanel;
            var canvasWidth:Number = CANVAS_WIDTH;
            var canvasHeight:Number = CANVAS_HEIGHT;
            const _captureRotated:uint = captureRotated;

            if(replayMode) //리플레이 변수로 변경
            {
                canvasWidth = RCANVAS_WIDTH;
                canvasHeight = RCANVAS_HEIGHT;
                xCaptureRect = rcapturePreviewRect;
                xReg = rregPoint;
                xPanel = rcanvasPanel;
            }

            var rectData:Array = [0,0,0,0];
            var cx:Number = xPanel.mouseX;
            var cy:Number = xPanel.mouseY;
            var rectW:Number = 0;
            var rectH:Number = 0;

            if(cx < 0) cx = 0;
            else if(cx > canvasWidth) cx = canvasWidth;

            if(cy < 0 ) cy = 0;
            else if(cy > canvasHeight) cy = canvasHeight;

            cx = floor(cx);
            cy = floor(cy);

            xCaptureRect.graphics.clear();
            xCaptureRect.visible = true;
            xcapturePreviewCursor.visible = false;
            toolTipBox.visible = false;

            function captureMouseMove(e:MouseEvent):void
            {
                if(!captureModeON)
                {
                    stage.removeEventListener(MouseEvent.MOUSE_MOVE,captureMouseMove);
                    stage.removeEventListener(MouseEvent.MOUSE_UP,captureMouseUp);
                }

                const g:Graphics = xCaptureRect.graphics;
                var ww:Number = xPanel.mouseX-cx;
                var hh:Number = xPanel.mouseY-cy;

                if(ww < -cx) ww = -cx;
                else if(ww > canvasWidth-cx) ww = canvasWidth-cx;

                if(hh < -cy) hh = -cy;
                else if(hh > canvasHeight-cy) hh = canvasHeight-cy;

                ww = floor(ww);
                hh = floor(hh);

                rectW = ww;
                rectH = hh;

                g.clear();
                g.lineStyle(5*scZoomed,0xFFFFFF,0.5,true);
                g.drawRect(cx,cy,ww,hh);
                g.lineStyle(3*scZoomed,0,1.0,true);
                g.drawRect(cx,cy,ww,hh);

                const whinfo:String = (_captureRotated === 0 || _captureRotated === 2) ? abs(ww)+" x "+abs(hh) : abs(hh)+" x "+abs(ww);

                setToolTipString(whinfo);
                toolTipBox.visible = true;
            }

            function captureMouseUp(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,captureMouseMove);
                stage.removeEventListener(MouseEvent.MOUSE_UP,captureMouseUp);

                xcapturePreviewCursor.visible = true;

                if(abs(rectW) > 10 && abs(rectH) > 10)
                {
                    var icx:Number = cx;
                    var icy:Number = cy;
                    var irectW:Number = rectW;
                    var irectH:Number = rectH;

                    //rect길이가 음수인경우 cx cy를 양수로 다시 맞추어줌
                    if(irectW < 0)
                    {
                        irectW = -irectW;
                        icx = icx-irectW;
                    }

                    if(irectH < 0)
                    {
                        irectH = -irectH;
                        icy = icy-irectH;
                    }
                    saveCaptureImage(icx,icy,irectW,irectH);
                }
            }
            stage.addEventListener(MouseEvent.MOUSE_MOVE,captureMouseMove);
            stage.addEventListener(MouseEvent.MOUSE_UP,captureMouseUp);
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
            const date:Date = new Date();
            const firstSaveFlag:Boolean = (name !== path);
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

            browseWindowON = true;

            // name = name.substr(0,name.lastIndexOf(".png"))+"_"+getRandomString(6)+".png";//뒤에 프레임 번호 붙여줌
            name = name.substr(0,name.lastIndexOf(".png"))+"_"+timeStr+".png";//뒤에 프레임 번호 붙여줌
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

                if(deg == 90)
                {
                    mat.translate(cropbmpd.height,0);
                    swapWH = true;
                }
                else if (deg == -90 || deg == 270)
                {
                    mat.translate(0,cropbmpd.width);
                    swapWH = true;
                }
                else if (deg == 180)
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

                consoleBox.print("Image saved successfully");
                // buttonEffect(topBar["capFull"]);
            }
        }

        private function saveFile(asFlag:Boolean,saveFailed:Boolean=false):void
        {
            //계속 저장하는거 방지 다른 이름으로 저장은 예외
            if(replayStartON) stopReplay();
            const continueFlag:Boolean = saveContinue === true && asFlag === false;

            if((saveOneTime === true && continueFlag)
            || lassoToolON)
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
                    _path = _path.substr(0,_path.lastIndexOf(".png"))+"_new"+".png";
                    _name = _name.substr(0,_name.lastIndexOf(".png"))+"_new"+".png";
                }
                var file:File = (_name !== _path) ? new File(_path) : File.desktopDirectory.resolvePath(_name);

                var saveWindowTitle:String = (asFlag === true) ? "Save file As..":"Save file";
                if(saveFailed) saveWindowTitle = "Save failed: try saving with a new name ..";

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
                    consoleBox.print("Failed to save file");
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
                checkUndoRedoIcon();
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
            if(lastUndoIndex < arr.length-1) undoDelFlag = true;
            else undoDelFlag = false;

            const arr1:Array = fs.readObject() as Array;
            const arr2:Array = fs.readObject() as Array;
            fs.close();

            undoData = arr.concat();
            rData = arr1.concat();
            rDataFrame = arr2.concat();
            checkUndoRedoIcon();
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
                            "toolBoxLastClickPos[0]":toolBoxLastClickPos[0],
                            "toolBoxLastClickPos[1]":toolBoxLastClickPos[1],
                            "rFileTotalFrame":rFileTotalFrame,
                            "toolBox.scaleX":toolBox.scaleX,
                            "lastWindowState":lastWindowState,
                            "uiColorIndex":uiColorIndex,
                            "APP_RUNNING_TIME":APP_RUNNING_TIME,
                            "pixelSnap":pixelSnap,
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
                            "isRightSidebar":isRightSidebar
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
                    lastWindowSize[0] = d["stage.nativeWindow.width"];
                    lastWindowSize[1] = d["stage.nativeWindow.height"];

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
                    regPoint.rotation = rotateCursorBox["rotateArrow"].rotation = d["regPoint.rotation"];
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
                    updatePenSizeCursor();
                    eraseSize = d["eraseSize"];
                    eraseShape = d["eraseShape"];
                    eraseAlpha = d["eraseAlpha"];
                    eraseAlphaIndex = alphaArr.indexOf(d["eraseAlpha"]);
                    eraseSizeIndex = d["eraseSizeIndex"];
                    setPenSize(d["penSizeIndex"]);
                    toolBoxLastClickPos[0] = d["toolBoxLastClickPos[0]"];
                    toolBoxLastClickPos[1] = d["toolBoxLastClickPos[1]"];
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
                    if(isRightSidebar) setSideBarRightPosition(true);


                    rSkipImageInit = d["rSkipImageInit"];
                    rBGColorSave = d["rBGColorSave"];

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
                    consoleBox.updateConsoleHeight(_nativeWindow.width);

                    // updatePenSizeCursor();
                    setPixelSnap(d["pixelSnap"]);
                    
                    updateWindowTitle();
                    appInfoBox.insertCanvasInfo([null,null,null,regPoint.rotation,null]);
                },150);
            }
            else //복원파일이 없을때
            {
                lastWindowSize[0] = 680;
                lastWindowSize[1] = 768;
                _nativeWindow.width = lastWindowSize[0];
                _nativeWindow.height = lastWindowSize[1];

                setPenSize(penSizeIndex);
                setPanelSize(CANVAS_WIDTH,CANVAS_HEIGHT,0,0,false);
                setHSVCursorPosByColor(penColor);
                addUndoData();
                openAboutPanel(1);

                setUIColor(uiColorIndex);
                updatePreviewCursorPos();
                updateWindowSizeInfo();
                consoleBox.updateConsoleHeight(_nativeWindow.width);
                appInfoBox.insertCanvasInfo([CANVAS_WIDTH,CANVAS_HEIGHT,zoomed*100,regPoint.rotation]);
            }
        }

        //빈 stage공백에 광클하면 쓸데없는 addundo가 되서
        //캔버스를 클릭했거나, 펜사이즈가 캔버스에 걸치면 addundo가 되게 예약해줌
        private function checkUndoReady():void
        {
            if(penSizeCursor.hitTestObject(canvasPanelMask))
            {
                clearButtonClicked = false; //undo추가 예약되어있으면 그때 꺼줌
                readyAddUndo = true;
            }
        }

        //size, size drag, zoom, rotate시 업데이트 해줌
        private function updatePenSizeCursor():void//transFlag:Boolean=false):void
        {
            const lastInfo:Array = lastUpdateInfo;
            const eraseFlag:Boolean = isEraseTool();
            const z:Number = zoomed;
            const size:uint = (!eraseFlag) ? penSize :eraseSize;
            const shape:Boolean = (!eraseFlag) ? penShape :eraseShape;
            const zSize:Number = size*z;

            if(zSize === lastInfo[0] && shape === lastInfo[1])
            {
                return;
            }

            lastInfo[0] = zSize;
            lastInfo[1] = shape;

            const _penSizeCursor:Shape = penSizeCursor;
            // const _penSizeCursor2:Shape = penSizeCursor2;
            const pg:Graphics = _penSizeCursor.graphics;
            // const pg2:Graphics = _penSizeCursor2.graphics;
            const halfSize:Number = size/2;
            const z1:Number = 1/z;
            const z1z1:Number = z1*2;
            const z3:Number = (3/z < 0.51) ? 0.51 : 3/z;
            var realSize:Number = (z1 < 1 && z1 > 0.5) ? 0.5 : z1;

            if(pixelSnap)
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
            pg.lineStyle(z3,0xFFFFFF);

            //커서 테두리
            // if(z <= 4)
            // {
            //     if(shape === false)
            //     {
            //         pg.drawCircle(0,0,halfSize);
            //     }
            //     else if(shape === true)
            //     {
            //         pg.drawRect(-halfSize,-halfSize,size,size);
            //     }
            // }

            //진짜 커서
            if(shape === false)
            {
                pg.lineStyle(realSize,0);
                pg.drawCircle(0,0,halfSize);
                pg.lineStyle(realSize,0xFFFFFF);
                pg.drawCircle(0,0,halfSize-z1);
            }
            else if(shape === true) 
            {
                pg.lineStyle(realSize,0);
                pg.drawRect(-halfSize,-halfSize,size,size);
                pg.lineStyle(realSize,0xFFFFFF);
                pg.drawRect(-halfSize+z1,-halfSize+z1,size-z1z1,size-z1z1);
            }


            // pg2.clear();
            // pg2.lineStyle(z3,0,0.2);

            // //커서 테두리
            // if(z <= 4)
            // {
            //     if(shape === false) pg2.drawCircle(0,0,halfSize);
            //     else if(shape === true) pg2.drawRect(-halfSize,-halfSize,size,size);
            // }

            // pg2.lineStyle(realSize,0xFFFFFF);
            // if(shape === false) pg2.drawCircle(0,0,halfSize);
            // else if(shape === true) pg2.drawRect(-halfSize,-halfSize,size,size);

            _penSizeCursor.rotation = 0;
            // _penSizeCursor2.rotation = 0;

            if(_penSizeCursor.width < 8/zoomed)
            {
                _penSizeCursor.visible = false;
                // _penSizeCursor2.visible = false;
                return;
            }
            // else if(altCursorON)
            // {
            //     // _penSizeCursor2.visible = true;
            //     _penSizeCursor.visible = false;
            // }
            // else
            // {
            //     // _penSizeCursor2.visible = false;
            //     _penSizeCursor.visible = true;
            // }


            const _canvasPanel:Sprite = canvasPanel;
            const offset:Number = (sizeOffsetFlag) ? 0.5 : 0;
            const x:Number = _canvasPanel.mouseX+offset;
            const y:Number = _canvasPanel.mouseY+offset;

            _penSizeCursor.x = x;
            _penSizeCursor.y = y;
            // _penSizeCursor2.x = x;
            // _penSizeCursor2.y = y;
        }

        //선툴에서 d키 누르면 erase랑 pen 왔다갔다
        private function eraseLineKeyDownEvent(e:KeyboardEvent):void
        {
            const keycode:uint = e.keyCode;

            if(keycode === KEY.d || keycode === KEY.j)
            {
                if(nowTool !== TOOL_LINE_ERASE)
                {
                    stage.removeEventListener(KeyboardEvent.KEY_DOWN, eraseLineKeyDownEvent);
                    stage.addEventListener(KeyboardEvent.KEY_UP, eraseLineKeyUPEvent);
                    selectEraseTool(true);//함수안에서 툴변경해줌
                }
            }
            
            if(e.controlKey && !mouseClickON)
            {
                if(keycode === KEY.s)
                {
                    setPrevTool();
                    saveFile(true);

                    // stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent,false,-1);
                    // stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDownEvent,false,-1);
                }
                else if(keycode === KEY.o)
                {
                    setPrevTool();
                    loadFile(true);

                    // stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent,false,-1);
                    // stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDownEvent,false,-1);
                }
            }
        }

        private function eraseLineKeyUPEvent(e:KeyboardEvent):void
        {
            const keycode:uint = e.keyCode;

            if(keycode === KEY.d || keycode === KEY.j)
            {
                if(nowTool !== TOOL_LINE && !mouseClickON)
                {
                    stage.removeEventListener(KeyboardEvent.KEY_UP, eraseLineKeyUPEvent);
                    stage.addEventListener(KeyboardEvent.KEY_DOWN, eraseLineKeyDownEvent);
                    selectPenTool(true);
                }
            }
            else if(keycode === KEY.shift)
            {
                // nowKey = 0;
                stage.removeEventListener(KeyboardEvent.KEY_UP, eraseLineKeyUPEvent);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, eraseLineKeyDownEvent);
            }
        }

        //canvas2번데이터를 canvas1에다가 최종적으로그려줌
        private function drawDone(tool:int):void
        {
            //커서 시작이 캔버스가 아니고 끝도 캔버스가 아니면 아무것도 안함
            if(readyAddUndo === false)
            {
                rDataBuffer = [];
                canvas2Draw.graphics.clear();
                return;
            }

            if(tool === 0) consoleBox.print("Pen");
            else if(tool === 1) consoleBox.print("Erase");
            else if(tool === 2) consoleBox.print("Fill-pen");
            else if(tool === 3) consoleBox.print("Line");
            else if(tool === 4) consoleBox.print("Erase-Line");

            var canvas2Alpha:ColorTransform;
            readyAddUndo = false;
            canvas2BitmapData.draw(canvas2Draw);
            canvas2Bitmap.bitmapData = canvas2BitmapData;

            if(isPenTool())
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

        private function setLineTool():void
        {
            const lineFlag:Boolean = TOOL_LINE === nowTool;
            const toDeg:Number = 180/Math.PI;
            const floor:Function = Math.floor;
            const abs:Function = Math.abs;
            const atan2:Function = Math.atan2;
            const _traceVisibleFlag:Boolean = traceVisibleFlag;

            var xSize:uint = penSize;
            var xColor:uint = penColor;
            var xAlpha:Number = penAlpha;
            var xShape:Boolean = penShape;
            var xBlendMode:String = null;

            mouseDragON = true;

            if(!lineFlag)
            {
                xSize = eraseSize;
                xColor = CANVAS_BG_COLOR;
                xAlpha = eraseAlpha;
                xShape = eraseShape;
                xBlendMode = "erase";
            }

            var xOffset:Number = (sizeOffsetFlag) ? 0.5 : 0;

            const cd:Shape = canvas2Draw;
            var mouseMovedFlag:Boolean = mouseMovedFlag;
            var oldX:Number = cd.mouseX;
            var oldY:Number = cd.mouseY;
            const subLayerFlag:Boolean = (lineFlag) ? subLayerON : false;

            if(lineFlag && _traceVisibleFlag)
            {
                canvasTrace.visible = false;
            }

            function drawingLine():void //지우개인가 펜인가 구분해서 lineto 실시
            {
                const cd:Shape  = canvas2Draw;
                const cdg:Graphics = cd.graphics;
                const mx:Number = cd.mouseX+xOffset;
                const my:Number = cd.mouseY+xOffset;
                cdg.clear();

                canvas2.alpha = xAlpha;
                if(xShape) cdg.lineStyle(xSize, xColor, 1, false, LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
                else cdg.lineStyle(xSize, xColor);

                cdg.moveTo(oldX+xOffset,oldY+xOffset);
                cdg.lineTo(mx,my);

                const ang:Number = atan2(oldX-cd.mouseX,oldY-cd.mouseY);
                var deg:Number = ang*toDeg+90;
                if(deg > 180) deg = deg-90;
                var degstr:String = abs(deg%90).toFixed(1)+"°";
                setToolTipString(degstr);
                toolTipBox.visible = true;
            }

            function lineMoveEvent(e:MouseEvent):void
            {
                if(limitMouseMoveEventTime(getTimer()) === true) return;
                if(!mouseMovedFlag)
                {
                    mouseMovedFlag = true;
                }

                drawingLine();
                if(readyAddUndo === false) checkUndoReady();
            }

            function lineUpEvent(e:MouseEvent):void
            {
                if(lineFlag && _traceVisibleFlag)
                {
                    canvasTrace.visible = true;
                }

                mouseDragON = false;
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, lineMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP, lineUpEvent);

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
                    rDataBuffer.push(["dot",xShape,xSize,xColor,xAlpha,xx,yy,xBlendMode,subLayerFlag]);
                    drawDot(xShape,xSize,xColor,xx,yy);
                }
                else
                {
                    rDataBuffer.push(["line",xShape,xSize,xColor,xAlpha,cxOff,cyOff,xx,yy,xBlendMode,subLayerFlag]);
                    drawingLine();                    
                }
                toolTipBox.visible = false;

                if(readyAddUndo === false) checkUndoReady();
                drawDone((lineFlag) ? 3 : 4);
            }

            //캔버스2번 지워주고, draw판넬 데이터도 지워줌
            canvas2BitmapData.dispose();
            canvas2Bitmap.bitmapData = null;
            canvas2BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);

            checkUndoReady();

            //선 관련 이벤트 함수 붙여줌
            stage.addEventListener(MouseEvent.MOUSE_MOVE,lineMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,lineUpEvent);
        }

        private function setRotateTool(replayMode:Boolean = false):void
        {
            const xReg:Sprite = (!replayMode) ? regPoint:rregPoint;
            const floor:Function = Math.floor;
            const xBitmap:Bitmap = (!replayMode) ? canvas1Bitmap : rcanvas1Bitmap;
            const _rotateCursorBox:rotateCursor = rotateCursorBox;
            const angleCursor:SimpleButton = _rotateCursorBox["rotateArrow"];

            var PI:Number = Math.PI;
            // var PI2:Number = PI*2;
            //각도 차이 구하기 위해서 넣어줌, 초기 값은 마우스 클릭한 위치의 각도값 
            var lastAng:Number = 0;
            //움직인 각도합 로테이트 캔버스 마지막각도를 넣어줌 rad로 변환
            var sumAng:Number = xReg.rotation*PI/180;
            const toDeg:Number = 180/PI; //rad를 deg로 변환하는 수식
            const center:Point = getStageCenterPos(false,replayMode);
            var rotateCenterX:Number = center.x;
            const rotateCenterY:Number = center.y;

            mouseDragON = true;
            penCursorOFFFlag = true;
            // xBitmap.smoothing = false;

            if(!replayMode)
            {
                // if(toolBoxAlwaysON) toolBox.visible = false;
                setOptimizeCanvasMove(true);
            }

            function rotateToolUpEvent(e:MouseEvent):void
            {
                mouseDragON = false;
                penCursorOFFFlag = false;
                // xBitmap.smoothing = true;

                if(!replayMode)
                {                    
                    if(lassoMenuTempOFF === true)
                    {
                        nowTool = TOOL_LASSO;
                        checkLassoMenuPos();
                        lassoMenuTempOFF = false;
                        lassoMenu.visible = true;
                    }

                    updatePenSizeCursor();
                    updatePreviewCursorPos();
                    setOptimizeCanvasMove(false);
                    updatePreviewCursorPos();
                    consoleBox.print("Canvas rotate "+xReg.rotation+"°");
                }
                else
                {
                    rNowKey = 0;
                    updateReplayCanvasBounds();
                }

                _rotateCursorBox.visible = false;
                checkCanvasPanelPos(replayMode);

                stage.removeEventListener(MouseEvent.MOUSE_UP, rotateToolUpEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, rotateToolUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, rotateToolMoveEvent);
            }

            function rotateToolMoveEvent(e:MouseEvent):void
            {
                if(limitMouseMoveEventTime(getTimer()) === true) return;
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
        }

        private function setMoveTool():void
        {
            const lassoFirstX:Number = lassoBox.x;
            const lassoFirstY:Number = lassoBox.y;
            var oldX:Number = mouseX;
            var oldY:Number = mouseY;
            const z:Number = zoomed;

            //canvas1Bitmap.smoothing = false;
            mouseDragON = true;
            penCursorOFFFlag = true;

            // if(toolBoxAlwaysON) toolBox.visible = false;

            function moveToolOFFEvent(e:MouseEvent):void
            {
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
                //canvas1Bitmap.smoothing = true;
                tempBitData.dispose();
                tempBitData = null;

                //좌표를 원점으로 돌림
                canvas1.x = 0;
                canvas1.y = 0;

                if(lassoToolON === false)
                {
                    consoleBox.print("Image move");
                    clearButtonClicked = false;
                    rDataBuffer.push(["move",movex,movey]);
                    addUndoData(1);
                }

                stage.removeEventListener(MouseEvent.MOUSE_MOVE, moveToolMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP, moveToolOFFEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, moveToolOFFEvent);
            }

            function moveToolMoveEvent(e:MouseEvent):void
            {
                if(limitMouseMoveEventTime(getTimer()) === true) return;
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

            stage.addEventListener(MouseEvent.MOUSE_MOVE, moveToolMoveEvent);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, moveToolOFFEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP, moveToolOFFEvent);
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

        private function setZoomTool(replayMode:Boolean = false):void
        {
            const xZoomed:Number = (!replayMode) ? zoomed : rzoomed;
            const _zoomArr:Array = zoomArr;
            const _zoomArrLen:uint = _zoomArr.length;
            const zoomMin:Number = _zoomArr[0];
            const zoomMax:Number = _zoomArr[_zoomArrLen-1];
            var mouseMoveStep:uint = 37; //이 픽셀이상움직일때만 zoomcanvas를 실행
            var zoomUnit:Number = 1.0;// 0.25;//한 스탭당 얼마나 줌할것인지
            var zoomSum:Number = 0;
            var moveXFlag:Boolean = true;//가로,세로 구분하는 플래그
            var zoomGoFlag:Boolean = false;//일정 범위를 넘기면 시작하는 플래그
            var oldX:Number = mouseX;
            var oldY:Number = mouseY;
            var moveFlag:uint = 0; //1이면 x축
            var oldZoom:Number;
            const strZoom:String = Math.floor(xZoomed*100)+"%";

            mouseDragON = true;
            penCursorOFFFlag = true;
            zoomToolHintON = true;

            if(!replayMode)
            {
                // if(toolBoxAlwaysON) toolBox.visible = false;
                if(replayEndWithcanvasFitWindow === true) replayEndWithcanvasFitWindow = false;
                setOptimizeCanvasMove(true);
                oldZoom = zoomed;
            }
            else
            {
                oldZoom = getNearestZoomValue(rzoomed);
            }

            function zoomToolUpEvent(e:MouseEvent):void
            {
                zoomToolHintON = false;
                mouseDragON = false;
                penCursorOFFFlag = false;

                stage.removeEventListener(MouseEvent.MOUSE_UP, zoomToolUpEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, zoomToolUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, zoomToolMoveEvent);

                toolTipBox.visible = false;

                if(!replayMode)
                {
                    updatePenSizeCursor();
                    setOptimizeCanvasMove(false);

                    if(lassoMenuTempOFF === true)
                    {
                        nowTool = TOOL_LASSO;
                        checkLassoMenuPos();
                        lassoMenuTempOFF = false;
                        lassoMenu.visible = true;
                    }
                    updatePreviewCursorPos();
                    consoleBox.print("Canvas zoom "+Math.floor(zoomed*100)+"%");
                }
                else
                {
                    rNowKey = 0;
                    updateReplayCanvasBounds();
                }
            }

            function zoomGoArray(index:uint):void
            {
                const newZoom:Number = _zoomArr[index];
                const textZoom:uint = Math.ceil(newZoom*100);

                changeToolTipString(textZoom+"%");
                toolTipBox.visible = true;
                setZoomCanvas(newZoom,replayMode);
            }

            function zoomToolMoveEvent2(dist:Number):void
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

            function zoomToolMoveEvent(e:MouseEvent):void
            {
                if(limitMouseMoveEventTime(getTimer()) === true) return;
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
                    if(Math.abs(subX) > mouseMoveStep)
                    {
                        oldX = mouseX;
                        zoomToolMoveEvent2(subX);
                    }
                }
                else if(moveFlag === 2)
                {
                    const subY:Number = my-oldY;
                    if(Math.abs(subY) > mouseMoveStep)
                    {
                        oldY = mouseY;
                        zoomToolMoveEvent2(subY);
                    }
                }
            }

            //클릭한 위치가 캔버스밖을 벗어날경우 줌 기준점을 캔버스 경계선에 닿도록 함
            var xCanvas:Sprite = canvasPanel;
            var xRotation:Number= -regPoint.rotation;
            var maxWidth:Number = CANVAS_WIDTH*xZoomed;//줌 배율을 곱해줘야 정확한 값이 나옴. width나 canvasPanel.mouseX는 scale된 값이 아님
            var maxHeight:Number = CANVAS_HEIGHT*xZoomed;

            if(replayMode)
            {
                xCanvas = rcanvasPanel;
                xRotation = -rregPoint.rotation;
                maxWidth = RCANVAS_WIDTH*xZoomed; //RCANVASWIDTH변수는 재생위치에 따라서 갱신이 안되어 있어서
                maxHeight = RCANVAS_HEIGHT*xZoomed; //실제 캔버스 사이즈값을 줌
            }
            const zerop:Point = new Point(0,0);
            var gp:Point = xCanvas.localToGlobal(zerop);
            var zoomClickX:Number = xCanvas.mouseX*xZoomed;
            var zoomClickY:Number = xCanvas.mouseY*xZoomed;

            if(zoomClickX < 0) zoomClickX = 0;
            else if(zoomClickX > maxWidth) zoomClickX = maxWidth;
            if(zoomClickY < 0) zoomClickY = 0;
            else if(zoomClickY > maxHeight) zoomClickY = maxHeight;

            //캔버스가 회전해있을경우 음수를 해줘야 정확한 값이 나옴
            const panelLimitedPos:Point = rotatePoint(zoomClickX,zoomClickY, xRotation);
            //캔버스 0,0점이 글로벌좌표 기준으로 어느 위치에 있는지 더해줘야함
            const panelLimitedX:Number = panelLimitedPos.x+gp.x;
            const panelLimitedY:Number = panelLimitedPos.y+gp.y;

            //sregpoint를 panelLimitedPos계산한 값으로 이동
            if(lassoMenuTempOFF === true)
            {
                gp = lassoBox.localToGlobal(zerop);
                setRegPoint(gp.x,gp.y,false);
            }
            else
            {
                setRegPoint(panelLimitedX,panelLimitedY,replayMode);
            }

            setToolTipString(strZoom);
            toolTipBox.visible = true;

            stage.addEventListener(MouseEvent.MOUSE_MOVE,zoomToolMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,zoomToolUpEvent);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,zoomToolUpEvent);
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
            updatePreviewCursorPos();
            //canvas1Bitmap.smoothing = true;
        }


        //캔버스의 중심좌표를 구함 컨트롤 박스 옵션 박스 포함
        private function getCanvasPanelMidPos():Point
        {
            const floor:Function = Math.floor;
            const boundRect:Object = getBoundRect(canvas1);
            const left:Number = boundRect.left;
            const top:Number = boundRect.top;
            const right:Number = boundRect.right;
            const bottom:Number = boundRect.bottom;
            const visualWidth:Number = right-left;//회전해있어도 상관없음
            const visualHeight:Number = bottom-top;//양끝 모서리들의 직선거리를 구함
            const visualMidX:Number = floor((left+right)/2);//회전한 캔버스의 중심점을 구함
            const visualMidY:Number = floor((top+bottom)/2); //floor안하면 1픽셀씩 내려감 0.5를 아래 setRegPoint 함수 에서 반올림 해줘서 그럼
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

            const halfCanvas:Number = (stage.stageWidth-sideBar.WIDTH)/2;
            var stageHalf:Number = (isRightSidebar) ? halfCanvas
                                                    : LEFT_OFFSET+halfCanvas;
            //창 절반을 기준점으로 regpoint x축 이동.
            regPoint.x += Math.round((stageHalf-p.x)*2);
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

            if(w > maxSize) w = maxSize;
            else if(w < 1) w = 1;

            if(h > maxSize) h = maxSize;
            else if(h < 1) h = 1;

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
            // controlBox.updateNavigatorImage(canvas1BitmapData,bgColor);
            // controlBox.updateNavigatorImagePosition(w,h,bgColor);

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

            var resizeClickPos:Vector.<Number> = new Vector.<Number> (2,true);
            var finalWidth:uint = 0;
            var finalHeight:uint = 0;
            var movedX:int = 0;
            var movedY:int = 0;

            function resizeButtonMouseUpEvent(e:MouseEvent):void
            {
                // var me:MouseEvent;
                
                resizeButtonActive = false; //엑티브 플래그 해제
                setDeactiveResizeButton();

                reiszePreviewRect.graphics.clear();
                reiszePreviewRect.visible = false;
                regPoint.removeChild(reiszePreviewRect);

                stage.removeEventListener(MouseEvent.MOUSE_UP,resizeButtonMouseUpEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP,resizeButtonMouseUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,resizeButtonMouseMoveEvent);

                // me = new MouseEvent(MouseEvent.RIGHT_MOUSE_UP);
                // stage.dispatchEvent(me);
                // me = new MouseEvent(MouseEvent.MOUSE_UP);
                // stage.dispatchEvent(me);

                setResizeButtonVisible(true);

                if(movedX === 0 && movedY === 0)
                {
                    //변경되지 않았으면 그냥 리턴
                    return;
                }

                const centerMoved:Boolean = (targetName === "resizeButtonL" || targetName === "resizeButtonU") ? true:false;
                setPanelSize(finalWidth,finalHeight,movedX,movedY,true,centerMoved);

                consoleBox.print("Canvas size "+finalWidth+" × "+finalHeight)
            }

            function resizeButtonMouseMoveEvent(e:MouseEvent):void
            {
                const oPointX:Number = canvasPanel.x;
                const oPointY:Number = canvasPanel.y;
                const mx:Number = mouseX;
                const my:Number = mouseY;
                const resizeg:Graphics = reiszePreviewRect.graphics;
                var edgePoint:Number;

                var subX:int = (targetName === "resizeButtonR")  ? canvasPanel.mouseX-resizeClickPos[0]:
                               (targetName === "resizeButtonL") ? resizeClickPos[0]-canvasPanel.mouseX: 0;
                var subY:int = (targetName === "resizeButtonD")  ? canvasPanel.mouseY-resizeClickPos[1]:
                               (targetName === "resizeButtonU") ? resizeClickPos[1]-canvasPanel.mouseY: 0;

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
            resizeClickPos[0] = canvasPanel.mouseX;
            resizeClickPos[1] = canvasPanel.mouseY;

            setResizeButtonVisible(false);
            reiszePreviewRect.x = canvasPanel.x;
            reiszePreviewRect.y = canvasPanel.y;
            regPoint.addChild(reiszePreviewRect);
            setTopChildIndex(reiszePreviewRect);
            reiszePreviewRect.visible = true;

            stage.addEventListener(MouseEvent.MOUSE_UP,resizeButtonMouseUpEvent);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,resizeButtonMouseUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,resizeButtonMouseMoveEvent);
        }

        //지우개랑 펜이랑 합쳐져있음
        private function setPenTool(penToolFlag:Boolean):void
        {
            var xSize:uint;
            var xColor:uint;
            var xAlpha:Number;
            var xShape:Boolean;
            var xBlendMode:String;
            var fillPenON:Boolean = fillPenON;

            if(penToolFlag)
            {
                xSize = penSize;
                xColor = penColor;
                xAlpha = penAlpha;
                xShape = penShape;
                xBlendMode = (xColor === CANVAS_BG_COLOR) ? "erase" : null;
            }
            else
            {
                fillPenON = false;
                xSize = eraseSize;
                xColor = CANVAS_BG_COLOR;
                xAlpha = eraseAlpha;
                xShape = eraseShape;
                xBlendMode = "erase";
            }

            const cd:Shape = canvas2Draw;
            // const mouseMoveCountLimit:uint = 800; //zoom에 따라서 100카운터 선 길이가 차이나서 비례해서 해줌
            const floor:Function = Math.floor;
            const cdg:Graphics = cd.graphics;
            const _pixelSnap:Boolean = pixelSnap;
            const rotateFlag:Boolean = (regPoint.rotation % 90 === 0) ? false : true;
            const _traceVisibleFlag:Boolean = traceVisibleFlag;
            var xOffset:Number = (sizeOffsetFlag) ? 0.5 : 0;
            
            if(fillPenON)
            {
                xOffset = (_pixelSnap) ? 0.5 : 0;
                xSize = 1;
                var fillPenCommand:Vector.<int> = new Vector.<int>(); //필펜 커맨드
                var fillPenPoints:Vector.<Number> = new Vector.<Number>(); //필펜 좌표
                var fillPenFirstBorderColor:uint;
            }

            const _penSmoothValue:Number = penSmoothValue;//펜 스무딩 플래그
            const _penSmoothSlideValue:Number = penSmoothSlideValue;

            var mouseMoveCount:uint = 0; //마우스 이벤트에서 움직일때 올려주는 카운터 한번에 너무 많이 움직여주면 cpu부하 먹어서 100카운트 마다 bmp에 그려줌
            var mouseMovedFlag:Boolean = false;
            var clickX:Number = cd.mouseX; //점찍어 줄 때 판단하는 클릭한 자리 저장
            var clickY:Number = cd.mouseY; //점찍어 줄 때 판단하는 클릭한 자리 저장
            var cx:Number = clickX+xOffset;// 첫 클릭한 지점
            var cy:Number = clickY+xOffset;

            if(_penSmoothSlideValue === 0)
            {
                cx = floor(cx-xOffset)+xOffset;
                cy = floor(cy-xOffset)+xOffset;
            }

            var smoothLastX:Number = cx; //penmove할때 마지막x y저장
            var smoothLastY:Number = cy; //penmove가 없을때 penmoveSMoothin함수는 이점을 목표로 이동함
            var pixelSnapLastX:Number = cx;
            var pixelSnapLastY:Number = cy;
            var moveEventLastX:Number = cx;//픽셀거리 검출 변수
            var moveEventLastY:Number = cy;
            var moveEventLastX2:Number = cx;//픽셀거리 검출 변수
            var moveEventLastY2:Number = cy;
            var penSmoothTimer:int = 0; //펜 스무딩 할때 커서가 움직이지 않을때 나머지 그려지지않은 점들 이어주는 타이머임
            var distLimit:Number = xSize/10;//penmove에서 distlimit이하이면 skip해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌
            var shortDistFlag:Boolean = false; //확대 많이 하고 살짝 움직였을때 penmove에서 아예 처리를 안하는데 이걸 dot으로 처리하게 해줌
            const subLayerFlag:Boolean = (penToolFlag) ? subLayerON : false;
            
            if(penToolFlag && _traceVisibleFlag)
            {
                canvasTrace.visible = false;
            }

            function lineStyleReady(shape:Boolean,size:uint,color:uint,alpha:Number):void
            {
                const cd:Shape  = canvas2Draw;
                const cdg:Graphics = cd.graphics;
                // const odd:Number = (size === 1 || size % 2 !== 0) ? 0 : 0.5;
                canvas2.alpha = alpha;

                if(shape === false)
                {
                    cdg.lineStyle(size, color);
                }
                else
                {
                    //vertical로 했더니 캔버스가 45도쯤 되면 선두깨가 안나와서 normal로 설정
                    cdg.lineStyle(size, color, 1, false,LineScaleMode.NORMAL,CapsStyle.SQUARE,JointStyle.ROUND);
                }

                // cdg.moveTo(cd.mouseX+odd, cd.mouseY+odd);
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
                if(readyAddUndo === false) checkUndoReady();

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

                    if(fillPenON)
                    {
                        const bgContrast:Number = getColorBright(xColor,1.0);
                        const borderColor:uint = (bgContrast >= 137) ? 0 : 0xFFFFFF;
                        const circleGraphic:Graphics = capturePreviewCursor.graphics;
                        const _zoomed:Number = zoomed;

                        fillPenFirstBorderColor = borderColor;

                        capturePreviewCursor.visible = true;
                        circleGraphic.clear();
                        circleGraphic.lineStyle(1/_zoomed,0,1.0);
                        circleGraphic.drawCircle(cx,cy,10/_zoomed);
                        circleGraphic.lineStyle(1/_zoomed,0xFFFFFF,1.0);
                        circleGraphic.drawCircle(cx,cy,9/_zoomed);
                        // capturePreviewCursor.graphics.beginFill(xColor);
                        // capturePreviewCursor.graphics.endFill();

                        lineStyleReady(false,1,xColor,1.0);
                        fillPenCommand.push(1);
                        fillPenPoints.push(cx);
                        fillPenPoints.push(cy);

                        cdg.lineStyle(1,xColor);
                        cdg.beginFill(xColor);
                        cdg.drawPath(fillPenCommand,fillPenPoints);
                        cdg.endFill();
                    }
                    else
                    {
                        lineStyleReady(xShape,xSize,xColor,xAlpha);
                        rDataBuffer.push(["lineStyle",xShape,xSize,xColor,xAlpha,cx,cy,xBlendMode,false,subLayerFlag]); //cx cy 처음 클릭한 지점으로 지정해줘야함
                    }

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

                if(fillPenON === false)
                {
                    rDataBuffer.push(["lineTo",x,y]);
                }
                else
                {
                    fillPenCommand.push(2);
                    fillPenPoints.push(x);
                    fillPenPoints.push(y);
                }

                if(++mouseMoveCount >= 100) //이 카운터 마다 다시 캔버스 2에 그려줌 길게 그을수록 cpu처리가 많아짐
                {
                    //draw를 canvas2에다가 그려주고
                    canvas2BitmapData.draw(cd,null,null,"layer");
                    canvas2Bitmap.bitmapData = canvas2BitmapData;
                    // canvas2Bitmap.smoothing = true;
                    //draw는 처음부터 다시시작
                    cdg.clear();

                    if(fillPenON)
                    {
                        // cdg.lineStyle(1,fillPenFirstBorderColor,1.0,true);
                        // cdg.beginFill(xColor);
                        // cdg.drawCircle(fillPenPoints[0],fillPenPoints[1],3);
                        // cdg.endFill();
                        lineStyleReady(false,1,xColor,1.0);
                    }
                    else
                    {
                        lineStyleReady(xShape,xSize,xColor,xAlpha);
                        rDataBuffer.push(["tempDone"]);
                        rDataBuffer.push(["lineStyle",xShape,xSize,xColor,xAlpha,x,y,xBlendMode,false,subLayerFlag]);
                    }
                    cdg.moveTo(x,y);
                    mouseMoveCount = 0;
                }
            }

            function penToolMoveEvent(e:MouseEvent):void
            {
                //일정 시간 이내는 무시함
                if(limitMouseMoveEventTime(getTimer()) === true)
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
                    if(distLimit <= 0)  distLimit = xSize/5;
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
                    {   //처음에 적당한 거리 움직여줌
                        const mm:Point = movePointAngleDist(mx,my,cx,cy,1);
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
                else
                {
                    penMove2(mx,my);
                }
            }

            function penToolUpEvent(e:MouseEvent):void
            {
                const x:Number = cd.mouseX;
                const y:Number = cd.mouseY;
                const mx:Number = x+xOffset;
                const my:Number = y+xOffset;

                if(penToolFlag && _traceVisibleFlag)
                {
                    canvasTrace.visible = true;
                }
                if(_penSmoothSlideValue > 1)
                {
                    clearTimeout(penSmoothTimer);
                    penSmoothTimer = 0;
                }

                if(fillPenON)
                {
                    capturePreviewCursor.graphics.clear();
                    capturePreviewCursor.visible = false;

                    if(mouseMovedFlag)
                    {
                        // if(penToolFlag && _penSmoothSlideValue === 0)
                        // {
                        //     cdg.lineTo(mx,my);
                        //     fillPenCommand.push(2);
                        //     fillPenPoints.push(mx);
                        //     fillPenPoints.push(my);
                        // }

                        canvas2Bitmap.bitmapData = null;
                        canvas2BitmapData.dispose();
                        cdg.clear();
                        canvas2BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);//캔버스 2 초기화 하고

                        canvas2.alpha = xAlpha; //다시 그려줌
                        cdg.lineStyle(1,xColor);
                        cdg.beginFill(xColor);
                        cdg.drawPath(fillPenCommand,fillPenPoints);
                        cdg.endFill();
                        rDataBuffer.push(["fill",xColor,xAlpha,xBlendMode,fillPenCommand.concat(),fillPenPoints.concat()]);
                    }

                    fillPenCommand = null;
                    fillPenPoints = null;
                }
                else if(_penSmoothSlideValue > 1 && penToolFlag)
                {
                    const sx:Number = ((clickX+xOffset)-cx);
                    const sy:Number = ((clickY+xOffset)-cy);
                    const dist:Number = Math.sqrt(sx*sx+sy*sy);

                    if(dist < 0.2)
                    {
                        rDataBuffer.push(["dot",xShape,xSize,xColor,xAlpha,cx,cy,xBlendMode,subLayerFlag]);
                        drawDot(xShape,xSize,xColor,cx,cy);
                    }
                }
                else if(mouseMovedFlag === false && ((clickX === x && clickY === y) || shortDistFlag))
                {
                    rDataBuffer.push(["dot",xShape,xSize,xColor,xAlpha,mx,my,xBlendMode,subLayerFlag]);
                    drawDot(xShape,xSize,xColor,mx,my);
                }
                else if((penToolFlag && _penSmoothSlideValue <= 1) || !penToolFlag)
                {
                    if(!mouseMovedFlag)
                    {
                        lineStyleReady(xShape,xSize,xColor,xAlpha);
                        cdg.moveTo(cx,cy);
                        rDataBuffer.push(["lineStyle",xShape,xSize,xColor,xAlpha,cx,cy,xBlendMode,false,subLayerFlag]); //cx cy 처음 클릭한 지점으로 지정해줘야함
                        rDataBuffer.push(["moveTo",mx,my]);
                    }
                    cdg.lineTo(mx,my);
                    rDataBuffer.push(["lineTo",mx,my]);
                }

                drawDone((fillPenON) ? 2 :(penToolFlag) ? 0 : 1);

                stage.removeEventListener(MouseEvent.MOUSE_UP, penToolUpEvent);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, penToolMoveEvent);
            }

            checkUndoReady();
            stage.addEventListener(MouseEvent.MOUSE_MOVE,penToolMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,penToolUpEvent);
        }

        private function doLassoDraw(replayMode:Boolean,rectArr:Vector.<Number>,points:Array,copyFlag:Boolean=false):Boolean
        {
            var drawEnt:Shape = canvas2Draw;
            var canvasBitmapData:BitmapData = canvas1BitmapData;
            var canvasBitmap:Bitmap = canvas1Bitmap;

            if(replayMode)
            {
                drawEnt = rcanvas2Draw;
                canvasBitmapData = rcanvas1BitmapData;
                canvasBitmap = rcanvas1Bitmap;
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

            //지우기 전에 사각형 모양으로 그려준 부분을 copypixel 함.
            lassoBMPD.copyPixels(canvasBitmapData,newRectangle,zerop,null,null,true);
            //----bitmap1canvas에서 그려준 영역을 지워줌
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
                // canvasBitmap.smoothing = true;
            }

            //-------------------------
            //clip하기 위해서 그려운 영역의 반전 부분을 0,0영역을 기준으로 그려줌
            //2번 반복하는게 좀 그런데 다른 방법 모르겠음
            lassog.clear();
            lassog.lineStyle(1,0xFF00FF);
            lassog.beginFill(0xFF00FF,0.1);
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
                lassog.lineTo(xx,yy);
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

            return true;
        }


        private function setLassoTool():void
        {
            //이미 켜져 있으면 리턴
            if(lassoToolON === true) return;

            const cd:Shape = canvas2Draw;
            const lassog:Graphics = lassoDrawG.graphics;
            const lassoClickX:Number = cd.mouseX;
            const lassoClickY:Number = cd.mouseY;
            //left, top, right, bottom순임
            const lassoRect:Vector.<Number> = new <Number> [lassoClickX,lassoClickY,lassoClickX,lassoClickY];
            const lassoPoints:Array = [];
            lassoPointSave = [];

            // if(toolBoxAlwaysON) toolBox.visible = false;

            function lassoDrawMouseUp():void
            {
                //이벤트 부터 꺼주자
                stage.removeEventListener(MouseEvent.MOUSE_MOVE,lassoDrawMouseMove);
                stage.removeEventListener(MouseEvent.MOUSE_UP,lassoDrawMouseUp);

                //x y가 캔버스 범위를 넘지 않게함
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
                stage.addEventListener(KeyboardEvent.KEY_DOWN,lassoToolKeyDownEvent);
            }

            function lassoDrawMouseMove(MouseEvent:Event):void
            {
                if(limitMouseMoveEventTime(getTimer()) === true) return;

                const x:Number = cd.mouseX;
                const y:Number = cd.mouseY;

                lassog.lineTo(x,y);

                //사각형 꼭지점 체크
                if(x < lassoRect[0]) lassoRect[0] = x;
                else if(x > lassoRect[2]) lassoRect[2] = x;

                if(y < lassoRect[1]) lassoRect[1] = y;
                else if(y > lassoRect[3]) lassoRect[3] = y;

                lassoPoints.push([x,y]);
            }

            canvas2.alpha = 1.0; //알파값이 조정되어 있을 수도 있기 때문에 해줌
            setTopChildIndex(lassoBox);

            lassoBox.visible = true;
            lassog.clear();
            lassog.lineStyle(1,0x00FFFF);
            lassog.beginFill(0x00FFFF,0.1);
            lassog.moveTo(lassoClickX,lassoClickY);
            lassoPoints.push([lassoClickX,lassoClickY]);

            stage.addEventListener(MouseEvent.MOUSE_MOVE,lassoDrawMouseMove);
            stage.addEventListener(MouseEvent.MOUSE_UP,lassoDrawMouseUp);
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

        private function setSpuitTool():void
        {
            //일단 흰색으로 배경 깔아줌
            const spuitCursor:Sprite = spuitZoomCursor;
            const oldTool:int = nowTool;
            const _setColorTransform:Function = setColorTransform;
            const spuitbmpd:BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,false,CANVAS_BG_COLOR);
            
            spuitbmpd.draw(canvas1BitmapData);
            penColorBackup = penColor;
            nowTool = TOOL_SPUIT;
            _setColorTransform(spuitCursor["spuitOldColor"],penColor);
            moveEraseButton("toolSpuit");

            function pickColor():uint
            {
                return (canvas1Bitmap.hitTestPoint(mouseX,mouseY)) ? spuitbmpd.getPixel(canvas1Bitmap.mouseX,canvas1Bitmap.mouseY)
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
                    consoleBox.print("Pick color "+colorHint);

                    if(colorhistoryArrlength > 1 && findIndex !== -1)
                    {
                        changedColor = int.MAX_VALUE;
                        if(!colorHistoryUpdateReady)
                        {
                            colorHistoryUpdateReady = true;
                            stage.addEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryEvent);
                        }
                    }

                    if(oldTool === TOOL_LINE) nowToolBackup = TOOL_LINE;
                    else nowToolBackup = TOOL_PEN;
                }

                spuitbmpd.dispose();

                spuitCursor.visible = false;

                if(fillPenON)
                {
                    updateOpaBoxColor(pickedColor);
                }

                setPrevTool();
                //move에서 spuitBitmapData를 쓰고 있기 때문에 이벤트를 먼저 해제해주고 데이터 비워줌
            }

            function colorPickerMoveEvent(e:MouseEvent):void
            {
                if(limitMouseMoveEventTime(getTimer()) === true) return;
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

            if(canvas1Bitmap.hitTestPoint(mouseX,mouseY) === true
            && mouseX > LEFT_OFFSET && mouseX < stage.stageWidth-RIGHT_OFFSET //캔버스 영역안에서만
            && mouseY > TOP_OFFSET && mouseY < stage.stageHeight-BOTTOM_OFFSET)
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
        }

        private function setOptimizeCanvasMove(flag:Boolean):void
        {
            setResizeButtonVisible(!flag);
            if(canvasTrace.alpha > 0.0)
            {
                canvasTrace.visible = !flag;
            }
        }

        private function setHandTool(replayMode:Boolean = false,toolBoxHandFlag:Boolean=false):void
        {
            const isDrawMode:Boolean =!replayMode;
            const xReg:Sprite = (isDrawMode) ? regPoint : rregPoint;
            const xBitmap:Bitmap = (isDrawMode) ? canvas1Bitmap : rcanvas1Bitmap;
            var oldX:Number = mouseX;
            var oldY:Number = mouseY;

            mouseDragON = true;
            penCursorOFFFlag = true;

            // xBitmap.smoothing = false;
            if(isDrawMode)
            {
               setOptimizeCanvasMove(true);
                // if(toolBoxAlwaysON) toolBox.visible = false;
            }

            function handToolUpEvent(e:MouseEvent):void
            {
                mouseDragON = false;
                penCursorOFFFlag = false;

                // xBitmap.smoothing = true;

                checkCanvasPanelPos(replayMode);

                if(isDrawMode)
                {
                    consoleBox.print("Canvas move");
                    setOptimizeCanvasMove(false);
                    if(nowKey !== KEY.space && toolBoxHandFlag === false)
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
                
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, handToolMoveEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP, handToolUpEvent);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, handToolUpEvent);
            }

            function handToolMoveEvent(e:MouseEvent):void
            {
                if(limitMouseMoveEventTime(getTimer()) === true) return;
                if(isDrawMode) updateResizeButtonPos();

                xReg.x += (mouseX-oldX);
                xReg.y += (mouseY-oldY);

                oldX = mouseX;
                oldY = mouseY;
            }

            stage.addEventListener(MouseEvent.MOUSE_MOVE, handToolMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP, handToolUpEvent);
            //윈도우 바깥에서 up을 하면 hand가 안꺼져서 오른쪽 마우스 뗄떼도 꺼주게함
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, handToolUpEvent);
        }

        //zoom이나 rotate reg포인트 바뀔때마다
        //캔버스 판넬위치 따라 다니면서 크기 똑같이 해줌
        private function updateResizeButtonPos():void
        {
            function setpos(ent:Sprite,x:Number,y:Number,w:Number,h:Number):void
            {
                ent.x = x;
                ent.y = y;
                ent.width = w;
                ent.height = h;
            }

            const rx:Number = regPoint.x;
            const ry:Number = regPoint.y;
            const cpPosX:Number = canvasPanel.x;
            const cpPosY:Number = canvasPanel.y;
            const w:Number = CANVAS_WIDTH;
            const h:Number = CANVAS_HEIGHT;
            const posX:Number = cpPosX+w;
            const posY:Number = cpPosY+h;
            const defSize:Number = 20/zoomed;
            const tmpClac:Number = cpPosY-defSize;
            const tmpCalc2:Number = h+defSize*2;

            const stWidth:uint = stage.stageWidth;
            const stHeight:uint = stage.stageHeight;

            setpos(resizeButtonU,cpPosX-defSize,tmpClac,w+defSize*2,defSize);
            setpos(resizeButtonD,cpPosX-defSize,posY,w+defSize*2,defSize);
            setpos(resizeButtonL,cpPosX-defSize,tmpClac,defSize,tmpCalc2);
            setpos(resizeButtonR,posX,tmpClac,defSize,tmpCalc2);
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
                    const floor:Function = Math.floor;

                    posMatrix.scale(lassoBMPScaleX,lassoBMPScaleY);//스케일부터 조절해주고
                    posMatrix.translate(floor(-lassoBMPWidth/2),floor(-lassoBMPHeight/2)); //회전 중심점을 bmp중심으로 옮겨주고
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
                    //canvas1Bitmap.smoothing = true;

                    // const point1:Vector.<Number> = lassoPointSave[0].concat();
                    // const point2:Array = lassoPointSave[1].concat();
                    const lassoInfos:Array = [lassoBMPScaleX,lassoBMPScaleY,
                                                lassoBMPWidth,lassoBMPHeight,
                                                ang,boxX,boxY];

                    rDataBuffer.push(["lasso",lassoPointSave[0],lassoPointSave[1],lassoInfos,lassoCopyON]);
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
            previewBox.updateImage(canvas1BitmapData,CANVAS_BG_COLOR);
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
            //checkPenEraseIconSameLocation();
            toolBox.moveToolCursor("toolMove");
        }

        private function selectZoomTool():void
        {
            nowToolBackup = nowTool;
            nowTool = TOOL_ZOOM;
            toolBox.moveToolCursor("toolZoom");
            //checkPenEraseIconSameLocation();
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
            //checkPenEraseIconSameLocation();
            toolBox.moveToolCursor("toolLasso");
        }

        private function selectFillPen():void
        {
            if(nowTool !== TOOL_PEN) nowTool = TOOL_PEN;
            // penFillCursorON = true;
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
        private function checkMainDrawTool(size:uint,color:uint,alpha:Number,shape:Boolean,penFlag:Boolean,lineFlag:Boolean):void
        {
            const _controlBox:controlMenu = controlBox;
            const _toolBox:toolButtons = toolBox;
            const _toolBox2:toolButtons2 = toolBox2;
            const eraseButton2:SimpleButton = _toolBox2["toolErase"];
            const penButton2:SimpleButton = _toolBox2["toolPen"];
            var index:uint;
            var aIndex:uint;
            var xAir:Boolean;

            if(penFlag)
            {
                index = penSizeIndex;
                aIndex = penAlphaIndex;
                _controlBox.pixelSnapButtonWapper.alpha = 1.0;
                _controlBox.subLayerButtonWapper.alpha = 1.0;
                            
                if(subLayerON) canvasPanel.setChildIndex(canvas1,2);
                else canvasPanel.setChildIndex(canvas2,2);
            }
            else
            {
                index = eraseSizeIndex;
                aIndex = eraseAlphaIndex;
                _controlBox.pixelSnapButtonWapper.alpha = BUTTON_OFF_ALPHA;
                _controlBox.subLayerButtonWapper.alpha = BUTTON_OFF_ALPHA;        
                canvasPanel.setChildIndex(canvas2,2);
            }

            fillPenON = false;

            setPenSize(index);
            setPenAlpha(alpha);
            
            updateOpaBoxColor(color);
            updateOpacityCursor(aIndex);

            if(lineFlag === false)
            {
                // eraseButton.visible = penFlag;
                // penButton.visible = !penFlag;
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

                    // eraseButton.visible = false;
                    eraseButton2.visible = false;
                    toolBox.moveToolCursor("toolErase");
                    _controlBox.controlInfo.text = "Erase Options";
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
                else
                {
                    toolBox2["toolFillPen"].visible = false;
                    moveEraseButton("toolEraseLine");
                    toolBox.moveToolCursor("toolEraseLine");
                    _controlBox.controlInfo.text = "Erase-line Options";
                }
                // eraseButton.visible = true;
                // penButton.visible = true;
                eraseButton2.visible = true;
                penButton2.visible = true;
            }

            _controlBox.shapeFlag(shape);
            updatePenSizeCursor();
        }

        private function selectPenTool(lineFlag:Boolean=false):void
        {
            if(!lineFlag)
            {
                nowTool = TOOL_PEN;
            }
            else
            {
                nowTool = TOOL_LINE;
            }
            checkMainDrawTool(penSize,penColor,penAlpha,penShape,true,lineFlag);
        }

        private function selectEraseTool(lineFlag:Boolean=false):void
        {
            const oldTool:int = nowTool;

            if(!lineFlag)
            {
                nowTool = TOOL_ERASE;
            }
            else
            {
                nowTool = TOOL_LINE_ERASE;
            }

            checkMainDrawTool(eraseSize,CANVAS_BG_COLOR,eraseAlpha,eraseShape,false,lineFlag);
        }

        //라소박스 변형이랑 플래그 초기화
        private function resetLassoBox():void
        {
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,lassoToolKeyDownEvent);

            lassoToolON = false;
            lassoMirrorON = false;
            lassoCopyON = false;
            lassoMenuTempOFF = false;
            lassoStartData = []
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

            if(traceMenuON === true) traceMenuBox.visible = true;

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

            //canvas1Bitmap.smoothing = true;

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
        }

        private function checkUndoRedoIcon():void
        {
            if(undoIndex <= 0)
            {
                toolBox.toolUndo.alpha = BUTTON_OFF_ALPHA;
                toolBox2.toolUndo.alpha = BUTTON_OFF_ALPHA;
            }
            else
            {
                toolBox.toolUndo.alpha = 1.0;
                toolBox2.toolUndo.alpha = 1.0;
            }

            if(undoIndex >= undoData.length-1)
            {
                toolBox.toolRedo.alpha = BUTTON_OFF_ALPHA;
                toolBox2.toolRedo.alpha = BUTTON_OFF_ALPHA;
            }
            else
            {
                toolBox.toolRedo.alpha = 1.0;
                toolBox2.toolRedo.alpha = 1.0;
            }
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

            checkUndoRedoIcon();
            const str:String = "Redo " + undoIndex + " / " + (undoData.length-1);
            consoleBox.print(str);
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

            checkUndoRedoIcon();
            const str:String = "Undo " + undoIndex + " / " + (undoData.length-1);
            consoleBox.print(str);
        }

        private function forceUndoAndDeleteFrontData(index:int):void
        {
            const endIndex:uint = index;
            undoData.splice(0,endIndex);  
            rData.splice(0,endIndex);
            rDataFrame.splice(0,endIndex);

            //firstimage 처음 넣어줘야함
            undoData.unshift([rFirstImage.clone(),false,rFirstImage.width,rFirstImage.height,rFirstBGColor]);
            rData.unshift([]);
            rDataFrame.unshift(0);

            undoIndex = undoIndex-(index-1);
            saveOneTime = false;
            clearButtonClicked = false;
            replayONUndoUpdate = true;
            addUndoMode = 0;
            // drawUndoData(false);
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

        private function addUndoData(addMode:uint=0):void
        {
            const _canvas1Bitmap:Bitmap = canvas1Bitmap;
            if(undoDelFlag === true)
            {
                replayONUndoUpdate = true;
                const startIndex:uint = undoIndex+1;
                undoDelFlag = false;
                undoData.splice(startIndex);
                rData.splice(startIndex);
                rDataFrame.splice(startIndex);
            }

            if(undoData.length >= 11) //첫번째 이미지는 빼야하니깐 -1로 계산해야함
            {
                const pushReady:Array = rData[0];

                if(pushReady.length > 0)
                {
                    const fs:FileStream = new FileStream();
                    const c:uint = rDataFrame[0];
                    const rf:File = repFile;

                    fs.open(rf,FileMode.APPEND);
                    fs.writeObject(pushReady);
                    fs.close();

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
                // else if(addMode === 4) //trace중복 사용은 아무것도 안함
            }
            else
            {
                undoData.push([canvas1BitmapData.clone(),mirrorON,_canvas1Bitmap.width,_canvas1Bitmap.height,CANVAS_BG_COLOR]);
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
            checkUndoRedoIcon();
            previewBox.updateImage(canvas1BitmapData,CANVAS_BG_COLOR);
            // _canvas1Bitmap.smoothing = true;
        }

        // hsv커서가 color에 맞춰서 위치를 움직여줌
        private function setHSVCursorPosByColor(color:uint,initFlag:Boolean=false):void
        {
            if(color === lastUpdateInfo[5] && !pickerColorSelected)
            {
                return;
            }
            lastUpdateInfo[5] = color;

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
            _pickerBox.setRGBInfoColor(getInvertColor(color,1.0,0xFFFFFF,0));
            _pickerBox.updateRGBInfoBG(color);
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
            if(index < 0) return;
            const _opabox:Sprite = controlBox.opaBox;
            // const curButton:SimpleButton = _opabox.getChildByName("alphaButton"+index) as SimpleButton;
            const curButton:SimpleButton = _opabox["alphaButton"+index];
            if(!curButton) return;

            const hexRGB:uint = RGBAtoRGB(0xFFFFFF
                                        ,alphaArr[index]
                                        ,curButton.transform.colorTransform.color);
            const cont:uint = getColorBright(hexRGB);
            var color:uint;

            if(cont >= 137) color = 0x383838;
            else color = 0xE9E9E9;

            if(color === lastUpdateInfo[2] && index === lastUpdateInfo[3]) return;
            lastUpdateInfo[2] = color;
            lastUpdateInfo[3] = index;

            const ypos:Number = curButton.x-6;
            const alphaCursor:SimpleButton = _opabox["alphaCursor"];

            alphaCursor.x = ypos;
            setColorTransform(alphaCursor,color);
        }

        private function setPenAlpha(alpha:Number=0):void
        {
            //toolType 이 true이면 지우개임
            //펜이나 보통 라인툴이 아니면 리턴
            var index:int = alphaArr.indexOf(alpha);
            const floor:Function = Math.floor;
            const eraseFlag:Boolean = isEraseTool();
            const str:String = String(alpha*100)+"%";

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

            if(shape === false) cdg.drawCircle(x,y,size/2);
            else if(shape === true) cdg.drawRect(x-size/2,y-size/2,size,size);

            cdg.endFill();
        }

        private function checkPenSize(shapeFlag:Boolean=false, shape:Boolean=false, xSize:Number=0):void//noTimer:Boolean = false):void
        {
            const eraseFlag:Boolean = isEraseTool();
            const pp:Shape = penSizePrev;

            if(shapeFlag === false)
            {
                shape = (!eraseFlag) ? penShape : eraseShape;
            }

            if(xSize === 0)
            {
                xSize = (!eraseFlag) ? penSize : eraseSize;
            }
 
            const toolSize:Number = xSize*zoomed;
            const pg:Graphics = pp.graphics;

            penSizePrev.alpha = 1.0;

            pg.clear();
            pg.lineStyle(0,0,0);
            pg.beginFill(0x8DB1D9);
            if(shape === false) pg.drawCircle(0,0,toolSize/2);
            else pg.drawRect(-toolSize/2,-toolSize/2,toolSize,toolSize);
            pg.endFill();

            pg.lineStyle(1,0xBAD2EE);
            if(shape === false) pg.drawCircle(0,0,toolSize/2);
            else pg.drawRect(-toolSize/2,-toolSize/2,toolSize,toolSize);
        }

        private function updateSideBarRightPosition():void
        {
            sideBar.x = stage.stageWidth-sideBar.WIDTH;
        }

        private function setSideBarRightPosition(ignoreCanvasMove:Boolean):void
        {
            const _sideBar:sidePanel = sideBar;
            const floor:Function = Math.floor;
            const sidebarOffsetX:Number = 5+toolBox.BOX_WIDTH+5;

            _sideBar.x = stage.stageWidth-_sideBar.WIDTH;

            previewBox.x = 5;
            previewBox.y = 0;

            appInfoBox.x = 40;
            appInfoBox.y = previewBox.y+previewBox.BOX_HEIGHT+5;

            controlBox.x = sidebarOffsetX;
            controlBox.y = floor(appInfoBox.y+appInfoBox.height+1);

            toolBox.x = 5;
            toolBox.y = appInfoBox.y+1;
            toolBox.zoomIconRightPos();

            pickerBox.x = sidebarOffsetX;
            pickerBox.y = floor(controlBox.y+controlBox.height+5);

            consoleBox.x = sidebarOffsetX-6;
            consoleBox.y = floor(pickerBox.y+pickerBox.height);

            _sideBar.y = topBar.BARSIZE;

            RIGHT_OFFSET = _sideBar.WIDTH;
            LEFT_OFFSET = 0;

            _sideBar.updatesideBGSize(stage.stageHeight);
            _sideBar.fofoImageRight();
            
            if(ignoreCanvasMove === false)
            {
                regPoint.x -= RIGHT_OFFSET;
            }
        }

        private function setSideBarLeftPosition():void
        {
            const _sideBar:sidePanel = sideBar;
            const floor:Function = Math.floor;
            const sidebarOffsetX:Number = 5;

            _sideBar.x = 0;

            previewBox.x = sidebarOffsetX;
            previewBox.y = 0;

            appInfoBox.x = 1;
            appInfoBox.y = previewBox.y+previewBox.BOX_HEIGHT+5;

            controlBox.x = sidebarOffsetX;
            controlBox.y = floor(appInfoBox.y+appInfoBox.height);

            toolBox.x = floor(controlBox.x+controlBox.width+1);
            toolBox.y = appInfoBox.y+1;
            toolBox.zoomIconLeftPos();

            pickerBox.x = sidebarOffsetX;
            pickerBox.y = floor(controlBox.y+controlBox.height+5);

            consoleBox.x = -1;
            consoleBox.y = floor(pickerBox.y+pickerBox.height);

            _sideBar.y = topBar.BARSIZE;
            _sideBar.fofoImageLeft();

            LEFT_OFFSET = _sideBar.WIDTH;
            RIGHT_OFFSET = 0;

            regPoint.x += LEFT_OFFSET;
        }

        private function makeMenuFamlity():void
        {
            const floor:Function = Math.floor;
            const stw:int = stage.stageWidth;
            const stH:int = stage.stageHeight;
            const stw2:Number = floor(stw/2);
            const stH2:Number = floor(stH/2);

            aboutPanel.name ="aboutPanel";
            penSizePrev.alpha = 0.6;
            penSizePrev.x = stw2;
            penSizePrev.y = stH2;

            topBar.name = "topBar";
            // _topBar.alignButtons();
            topBar.makeTopbarBG(COLOR_MID_DARK);
            changeTopBarIcons("draw");

            sideBar.addChild(previewBox);
            sideBar.addChild(appInfoBox);
            sideBar.addChild(toolBox);
            sideBar.addChild(controlBox);
            sideBar.addChild(pickerBox);
            sideBar.addChild(consoleBox);
            sideBar.updatesideBGSize(stage.stageHeight);
            setSideBarLeftPosition();

            TOP_OFFSET = topBar.BARSIZE;

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
            rcapturePreviewCursor.visible = false;
            // rcapturePreviewCursor.blendMode = "invert";

            rcapturePreviewRect.visible = false;
            // rcapturePreviewRect.blendMode = "invert";

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

            // rregPoint.graphics.beginFill(0xFF0000); //디버그용 reg포인트가 어디 위치하는지 보여줌
            // rregPoint.graphics.drawRect(0,0,20,20);
            // rregPoint.graphics.endFill();
            // rcanvasPanel.alpha = 0.5;

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
            // penSizeCursor2.name = "penSizeCursor2";
            stageBG.name = "stageBG";
            canvasTrace.name = "canvasTrace";
            canvasGrid.name = "canvasGrid";

            penSizeCursor.visible = false;
            // penSizeCursor2.visible = false;

            lassoDrawG.blendMode = "difference";

            lassoBox.name = "lassoBox";
            lassoBox.addChild(lassoBMP);
            lassoBox.addChild(lassoDrawG);
            // lassoBox.graphics.beginFill(0xFF0000);
            // lassoBox.graphics.drawCircle(0,0,3);
            
            lassoBox.visible = false;

            reiszePreviewRect.visible = false;
            // reiszePreviewRect.blendMode = "invert";

            capturePreviewCursor.visible = false;
            capturePreviewRect.visible = false;

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

            // penSizeCursor.cacheAsBitmap = true;
            // penSizeCursor2.cacheAsBitmap = true;
            _canvasPanel.addChild(canvasTrace);// 판넬레 trace layer 추가
            _canvasPanel.addChild(canvas1);//판넬에 canvas1추가
            _canvasPanel.addChild(canvas2);//판넬에 canvas2추가
            _canvasPanel.addChild(lassoBox);
            _canvasPanel.addChild(canvasGrid);
            _canvasPanel.addChild(capturePreviewRect);
            _canvasPanel.addChild(capturePreviewCursor);
            _canvasPanel.addChild(penSizeCursor);
            // _canvasPanel.addChild(penSizeCursor2);
            _canvasPanel.addChild(canvasPanelMask);//판넬에  마스크 추가
            _canvasPanel.mask = canvasPanelMask;//마스크 해줘서 판 밖으로 선나타나지 않도록함

            //canvasrotate가 중점으로 올수있게 위치를 절반으로세팅
            _canvasPanel.x = Math.floor(-_canvasPanel.width/2);
            _canvasPanel.y = Math.floor(-_canvasPanel.height/2);

            regPoint.addChild(_canvasPanel);

            stage.addChild(stageBG);
            stage.addChild(spuitZoomCursor);
            stage.addChild(lassoMenu);
            stage.addChild(regPoint);//stage에 캔버스 판넬 추가
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

        private function windowResizedBeforeClosingEvent(e:Event):void
        {
            lastWindowState = 1
            // saveAllData();
            stage.nativeWindow.close();
        }

        private function windowResizedEvent(e:Event):void
        {
            clearTimeout(windowResizeDelayTimer)
            windowResizeDelayTimer = setTimeout(function ():void 
            {
                const _lastWindowSize:Vector.<Number> = lastWindowSize;
                const _lastWindowSize0:Number = _lastWindowSize[0];
                const _lastWindowSize1:Number = _lastWindowSize[1];
                const windowW:Number = stage.nativeWindow.width;
                const windowH:Number = stage.nativeWindow.height
                const stw:Number = stage.stageWidth;
                const sth:Number = stage.stageHeight;
                const round:Function = Math.round;
                // const panelPosX:int = regPoint.x + canvasPanel.x;
                // const panelPosY:int = regPoint.y + canvasPanel.y;
                const dx:Number = round((windowW-_lastWindowSize0)/1.75);
                const dy:Number = round((windowH-_lastWindowSize1)/1.75);
                // const dx1:Number = round((windowW-_lastWindowSize0));//창길이의 1배만큼 움직여줌
                // const dy1:Number = round((windowH-_lastWindowSize1));

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
                if(captureModeON) canvasFitWindow(true);
                checkCanvasPanelPos();
                if(replayModeON)
                {
                    updateReplayBarPos(stw,sth);
                    updateReplayCanvasBounds();
                }
                else
                {
                    updateResizeButtonPos();//리사이즈 버튼 위치도 업데이트
                }
                if(aboutPanelON) setAboutPanelCenterPos();
                updateStageBG(uiColorSet[uiColorIndex][2]);
                topBar.updateTopbarBG(stw);
                topBar.updateTimerPos(stage.stageWidth);
                sideBar.updatesideBGSize(sth);
                if(isRightSidebar) updateSideBarRightPosition();
                consoleBox.updateConsoleHeight(sth);
                updatePreviewCursorPos();
            
                if(fileDragSelectBox.visible === true) setDragDropSelectBoxCenterPos();
    
                _lastWindowSize[0] = windowW;
                _lastWindowSize[1] = windowH;
            },100);
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

            if(shiftKeyON === true)
            {
                appResetFlag = true;
                if(appDataFile.exists) appDataFile.deleteFile(); //파일이 있으면 지워줌
                if(repFile.exists) repFile.deleteFile();
                if(rSkipImageFolder.exists) rSkipImageFolder.deleteDirectory(true);
                if(rSkipImageFrameDataFile.exists) rSkipImageFrameDataFile.deleteFile();
                if(undoDataFile.exists) undoDataFile.deleteFile();
                if(traceImageFile.exists) traceImageFile.deleteFile();
            }
            else if(stage.nativeWindow.displayState === "maximized") //최대화이면 복원해주고 닫아줌
            {
                stage.nativeWindow.addEventListener(Event.RESIZE,windowResizedBeforeClosingEvent);
                stage.nativeWindow.restore();
                e.preventDefault();
            }
            else
            {
                lastWindowState = 0
                // saveAllData();
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
            var offsetTop:Number = TOP_OFFSET;
            var offsetLeft:Number = LEFT_OFFSET;
            var offsetBottom:Number = BOTTOM_OFFSET;
            var offsetRight:Number = RIGHT_OFFSET;

            const left:Number = ent.x;
            const top:Number = ent.y;
            const right:Number = left+ent.width;
            const bottom:Number = top+ent.height; //info text 사이즈 더해줌
            const xLimit:Number = stage.stageWidth;
            const yLimit:Number = stage.stageHeight;
            const vec:Vector.<Number> = new Vector.<Number> (2,true);

            if(right > xLimit-offsetRight) ent.x = xLimit-ent.width-offsetRight;
            else if(left < offsetLeft) ent.x = offsetLeft;

            if(top < offsetTop) ent.y = offsetTop;
            else if(bottom > yLimit-offsetBottom) ent.y = (yLimit-offsetBottom)-ent.height;

            vec[0] = ent.x;
            vec[1] = ent.y;
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
            const leftLimit:Number = LEFT_OFFSET+offset;
            const rightLimit:Number = stage.stageWidth-(RIGHT_OFFSET+offset);
            const topLimit:Number = TOP_OFFSET+offset;
            const bottomLimit:Number = stage.stageHeight-(BOTTOM_OFFSET+offset);

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
            var centerX:Number = (isRightSidebar) ? floor((stage.stageWidth-RIGHT_OFFSET)/2) : floor(LEFT_OFFSET+(stage.stageWidth-LEFT_OFFSET)/2);
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

            xReg.x = center.x;
            xReg.y = center.y;
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
            const finalStr:String = "Playback speed ×"+oldSpeed+" ("+timeStr+")";
            topBar.hintTime(finalStr,topBar.replaySpeedSet);

            rSpeed = oldSpeed;
            topBar.setSpeedButtonPosByValue(oldSpeed,max);
        }

        private function keyDownReplayModeEvent(e:KeyboardEvent):void//keydown2
        {
            const keyCode:uint = e.keyCode;

            switch(keyCode)
            {
                case KEY.left:
                {
                    setSkipOneFrame(true,true,e.shiftKey);
                }
                break;
                case KEY.right:
                {
                    setSkipOneFrame(false,true,e.shiftKey);
                }
                break;

                case KEY.up:
                {
                    setReplaySpeedByKey(true);
                }
                break;
                case KEY.down:
                {
                    setReplaySpeedByKey(false);
                }
                break;
            }

            if(rNowKey === keyCode)
            {
                return;
            }

            if(keyCode === KEY.shift && !shiftKeyON)
            {
                shiftKeyON = true;
            }

            if(keyCode === KEY.tab || captureModeON || aboutPanelON)
            {
                e.preventDefault();
                return;
            }
            else if(captureModeShortCutOFF)
            {
                captureModeShortCutOFF = false;
                return;
            }

            if(e.shiftKey === true) //자툴이 있기 때문에 아래 return 해주지 않음
            {
                if(keyCode === KEY.s)
                {
                    if(e.controlKey === true)
                    {
                        saveFile(true);
                    }
                    return;
                }
            }
            else if(e.controlKey === true)
            {
                if(keyCode === KEY.s) //ctrl+s
                {
                    saveFile(false);
                }
                else if(keyCode === KEY.o) //ctrl+o
                {
                    loadFile();
                }
                return;
            }
            else if(e.altKey === true)
            {
                if(keyCode === KEY.s)
                {
                    setCaptureReady();
                }
                return;
            }

            rNowKey = keyCode;

            switch(keyCode)
            {
                case KEY.f4:
                {
                    cutFrameData(1,true);
                }
                break;

                case KEY.f5:
                {
                    cutFrameData(0,true);
                }
                break;

                case KEY.f6:
                {
                    cutFrameData(2,true);
                }
                
                case KEY.s:
                case KEY.k:
                {
                    selectRotateTool();
                }
                break;

                case KEY.w:
                case KEY.i:
                {
                    selectZoomTool();
                }
                break;
                case KEY.n1:
                case KEY.n7:
                {
                    setReplayUI(false);
                }
                break;
                case KEY.enter:
                case KEY.space:
                {
                    if(repSpaceKeyON === false)
                    {
                        repSpaceKeyON = true;
                        if(replayStartON === false) startReplay();
                        else stopReplay();
                    }
                }
                break;
            }
        }

        private function keyUpReplayModeEvent(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;

            rNowKey = 0;
            if(keyCode === KEY.shift && shiftKeyON)
            {
                shiftKeyON = false;
            }
            else if(keyCode === KEY.enter || keyCode === KEY.space)
            {
                repSpaceKeyON = false;
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
            else if(clipImageShortCutON && keyCode === KEY.v)
            {
                clipImageShortCutON = false;
            }

            if(_nowKey === keyCode)//key down에서 눌러준 키가 아니면 리턴
            {
                if(_nowKey === KEY.d || _nowKey === KEY.j)
                {
                    stage.removeEventListener(KeyboardEvent.KEY_DOWN, eraseLineReadyKeyDownEvent);
                    stage.removeEventListener(KeyboardEvent.KEY_UP, eraseLineReadyKeyUpEvent);
                }
                else if(_nowKey === KEY.q || _nowKey === KEY.o) // fill pen up
                {
                    if(fillPenON === true)
                    {
                        fillPenON = false;
                        // penFillCursorON = true; 
                        selectPenTool();
                    }
                }

                if(mouseClickON === true)
                {
                    afterToolOff = true;
                }
                else
                {
                    const nt:int = nowTool;
                    //else if 해주면 안됨
                    if(nt === TOOL_LINE)
                    {
                        penCursorOFFFlag = false;
                        stage.removeEventListener(KeyboardEvent.KEY_UP, eraseLineKeyUPEvent);
                        stage.removeEventListener(KeyboardEvent.KEY_DOWN, eraseLineKeyDownEvent);
                    }
                    else if(nt === TOOL_ERASE)
                    {
                        penCursorOFFFlag = false;
                    }

                    //tool lasso 왜해주냐면 단축키를 누른 상태에서 그리고 lasso draw가 작동된후 단축키를 떼면 prev가 작동되서 그럼
                    if(!lassoToolON && nowToolBackup > 0)
                    {
                        setPrevTool();
                    }

                    if(keybufferArr.length > 0)
                    {
                        const nextKey:int = keybufferArr[0];
                        checkToolKeyDown(nextKey);
                        keybufferArr.shift();
                    }
                    else
                    {
                        nowKey = 0;
                    }
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

            if(captureModeON || keyCode === KEY.tab  || fileDragSelectBox.visible === true) // pickerBoxON || penListBoxON ||
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
                if(checkKeWhileShiftKey(keyCode,e.controlKey))
                return;
                
                // {

                // }
                //이 공간에서 리턴 해주면 안됨
            }
            else if(e.controlKey === true || keyCode === 25) //오른쪽 컨트롤키
            {
                checkKeWhileControlKey(keyCode,e.shiftKey);
                return;
            }
            else if(e.altKey === true || keyCode === 18 || keyCode === 21)
            {
                if(keyCode === KEY.s)
                {
                    setCaptureReady();
                }
                return;
            }
            else if(keyCode === KEY.f1) setGridButton();
            else if(keyCode === KEY.f2) setSideBarPositionButton();
            else if(keyCode === KEY.f3) setUIColorButton();

            //컨트롤 알트 스크롤락 makeSkipImage키등은 charcode가 없어서 그냥 리턴함
            //keyup에서 감지 못해서 에러남
            if(afterToolOff || (e.charCode === 0 && keyCode !== KEY.shift)) //줌 대기중일때 키 안먹게
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

            checkToolKeyDown(keyCode);

            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, rightMouseDownEvent);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent);
        }

        private function checkToolKeyDown(keyCode:int):void
        {
            nowKey = keyCode;
            
            switch (keyCode)
            {
                case KEY.q:
                case KEY.o:
                {
                    if(fillPenON === false)
                    {
                        selectFillPen();
                    }
                }
                break;
                case KEY.t:
                {
                    if(!traceMenuON) openTraceMenu();
                    else if(traceMenuON) closeTraceMenu();
                }
                break;
                case KEY.n2:
                case KEY.n8:
                {
                    setReplayUI(true);
                }
                break;
                case KEY.a:
                case KEY.l:
                {
                    mirrorCanvas();
                    consoleBox.print("Flip canvas "+((mirrorON) ? "ON":"OFF"));
                }
                break;

                case KEY.c:
                case KEY.m:
                {
                    if(nowTool !== TOOL_SPUIT)
                    {
                        nowToolBackup = nowTool;
                        setSpuitTool();
                    }
                }
                break;
                case KEY.r:
                case KEY.y:
                {
                    if(nowTool !== TOOL_LASSO)
                    {
                        selectLassoTool();
                    }
                }
                break;
                case KEY.space:
                {
                    if(nowTool !== TOOL_HAND)
                    {
                        nowToolBackup = nowTool;
                        nowTool = TOOL_HAND;
                    }
                }
                break;
                case KEY.d:
                case KEY.j:
                {
                    if(nowTool !== TOOL_ERASE)
                    {
                        nowToolBackup = nowTool;
                        selectEraseTool();
                        stage.addEventListener(KeyboardEvent.KEY_DOWN, eraseLineReadyKeyDownEvent);
                    }
                }
                break;
                case KEY.x:
                case KEY.comma:
                {
                    setRedoButton();
                }
                break;
                case KEY.z:
                case KEY.dot:
                {
                    setUndoButton();
                }
                break;
                case KEY.s:
                case KEY.k:
                {
                    if(nowTool !== TOOL_ROTATE)
                    {
                        selectRotateTool();
                    }

                }
                break;
                case KEY.e:
                case KEY.u:
                {
                    if(nowTool !== TOOL_MOVE)
                    {
                        selectMoveTool();
                    }
                }
                break;
                case KEY.w:
                case KEY.i:
                {
                    if(nowTool !== TOOL_ZOOM)
                    {
                        selectZoomTool();
                    }
                }
                break;
                case KEY.shift:
                {
                    if(!(nowTool === TOOL_LINE || nowTool === TOOL_LINE_ERASE))
                    {
                        nowToolBackup = nowTool;
                    }
                    selectPenTool(true);
                    stage.addEventListener(KeyboardEvent.KEY_DOWN, eraseLineKeyDownEvent);
                }
                break;
                case KEY.esc:
                case KEY.del:
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
            keybufferArr = [];
            nowKey = 0;
            afterToolOff = false;
            shiftKeyON = false;

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
            // if(lassoMenuTempOFF === true)
            // {
            //     lassoMenu.visible = true;
            //     lassoMenuTempOFF = false;
            // }

            //지우개나 라인툴에서 q키누르는거 대기하는 이벤트 제거
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,eraseLineReadyKeyDownEvent);
            stage.removeEventListener(KeyboardEvent.KEY_UP,eraseLineReadyKeyUpEvent);

            //라인툴에서 지우개 키 누르는 이벤트 제거
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,eraseLineKeyDownEvent);
            stage.removeEventListener(KeyboardEvent.KEY_UP,eraseLineKeyUPEvent);

            if(appResetFlag === false)
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

        private function updateToolBoxMousePos(target:SimpleButton):void
        {
            //아이콘 중앙으로 맞추어줌
            if(!target) return;
            if(target.parent as Sprite === toolBox2)
            {
                toolBoxLastClickPos[0] = -(target.x+target.width/2)*toolBox2.scaleX;//*scale;
                toolBoxLastClickPos[1] = -(target.y+target.height/2)*toolBox2.scaleX;//*scale;
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
                }
                break;
                case "toolFillPen":
                {
                    selectFillPen();
                }
                break;
                case "toolErase":
                {
                    selectEraseTool();
                }
                break;
                case "toolLine":
                {
                    selectPenTool(true);
                }
                break;
                case "toolEraseLine":
                {
                    selectEraseTool(true);
                }
                break;
                case "toolLasso":
                {
                    selectLassoTool();
                }
                break;
                case "toolSpuit":
                {
                    if(nowTool !== TOOL_SPUIT) nowToolBackup = nowTool;
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
                    consoleBox.print("Flip canvas "+((mirrorON) ? "ON":"OFF"))
                break;
                case "toolTrace":
                    selectTraceTool();
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

            if(keycode === KEY.up)
            {
                setLasso1PxMoveButton("up");
                checkLassoMenuPos();
            }
            else if(keycode === KEY.down)
            {
               setLasso1PxMoveButton("down");
                checkLassoMenuPos();
            }
            else if(keycode === KEY.left)
            {
                setLasso1PxMoveButton("left");
                checkLassoMenuPos();
            }
            else if(keycode === KEY.right)
            {
                setLasso1PxMoveButton("right");
                checkLassoMenuPos();
            }
        }

        private function checkToolBoxButtons(targetName:String):Boolean
        {
            const _toolBox:toolButtons = toolBox;

            if(lassoToolON === false)
            {
                stage.addEventListener(MouseEvent.MOUSE_UP,checkToolBoxButtonUpEvent);
            }
            
            setTopChildIndex(toolBox);
            
            switch(targetName)
            {
                case "toolBoxMoveButton":
                {
                    // if(nowTool === TOOL_ZOOM) nowTool = nowToolBackup;
                    // setTopChildIndex(_toolBox);
                    // moveToolBoxByType(0);
                }
                return true;

                case "toolRotate":
                {
                    setRotateTool(false);
                    // selectRotateTool();
                }
                break;


                case "zoomInButton":
                case "zoomOutButton":
                {
                    toolBoxAlwaysClickTool = targetName;
                    setTopChildIndex(_toolBox);
                    mouseClickPos[0] = mouseX;
                    mouseClickPos[1] = mouseY;
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
                case "toolEraseLine":
                case "toolMove":
                case "toolZoom":
                case "toolRotate":
                case "toolTrace":
                case "toolBoxBG":
                {
                    // if(nowTool === TOOL_ZOOM) nowTool = nowToolBackup;
                    setTopChildIndex(_toolBox);
                    toolBoxAlwaysClickTool = targetName;
                    mouseClickPos[0] = mouseX;
                    mouseClickPos[1] = mouseY;
                    return true;
                }

                return false;
            }
            return false;
        }

        private function checkResizeButton(target:Sprite,shortcutKey:Boolean):Boolean
        {   
            if(reizeButtonClickEnt === target)
            {
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, canvasSizeButtonMouseUPEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP, canvasSizeButtonMouseUPEvent);
                setCanvasSize(reizeButtonClickEnt.name);
                return true; //밑에 tool이 실행되기 때문에 조건 만족할때만 return해야함
            }
            else if(shortcutKey === true)
            {
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, canvasSizeButtonMouseUPEvent);
                stage.removeEventListener(MouseEvent.MOUSE_UP, canvasSizeButtonMouseUPEvent);
                setActiveResizeButton(target);
                setCanvasSize(target.name);

                return true;
            }
            else
            {
                setDeactiveResizeButton();
            }
            return false;
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

        private function setReplayUI(flag:Boolean):void
        {
            const iFlag:Boolean = !flag;
            const floor:Function = Math.floor;
            const _regPoint:Sprite = regPoint;
            const _rregPoint:Sprite = rregPoint;
            const _canvasPanel:Sprite = canvasPanel;
            const _rcanvasPanel:Sprite = rcanvasPanel;
            const _appInfoBox:appInfoBar = appInfoBox;
            const bottomTopbar:Boolean = topBarON === 2;

            keybufferArr = [];
            nowKey = 0;
            rNowKey = 0;

            replayModeON = flag;
            penCursorOFFFlag = flag;
            // replayModeONFirstSkip = flag;
            repSpaceKeyON = iFlag;
            rregPoint.visible = flag;
            regPoint.visible = iFlag;
            resizeButtonR.visible = iFlag;
            resizeButtonL.visible = iFlag;
            resizeButtonD.visible = iFlag;
            resizeButtonU.visible = iFlag;
            replayTimeBox.visible = flag; //탐색바 켜줌
            rCursor.visible = flag;
            replayTimeBox["pauseButton"].visible = false;
            sideBar.visible = iFlag;
            setTopChildIndex(replayTimeBox);

            if(iFlag) //리플레이 꺼줄때
            {
                clearDataButtonCount = 0;
                if(replayStartON === true) stopReplay();
                
                rSkipLastIndex = -2;//스킵 이미지 인덱스 원래대로 되돌려줌

                // if(CANVAS_WIDTH === RCANVAS_WIDTH && CANVAS_HEIGHT === RCANVAS_HEIGHT)
                // {
                //     zoomed = rzoomed;
                //     _regPoint.x = floor(_rregPoint.x); //뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
                //     _regPoint.y = floor(_rregPoint.y);
                //     _regPoint.scaleX = _rregPoint.scaleX;
                //     _regPoint.scaleY = _rregPoint.scaleY;
                //     _regPoint.rotation = _rregPoint.rotation;
                //     _canvasPanel.x = floor(_rcanvasPanel.x);
                //     _canvasPanel.y = floor(_rcanvasPanel.y);

                //     updateResizeButtonPos();
                // }

                //follow cursor옵션에서 캔버스 다 그려주고, fitwindow가 됐을때 줌 단위가 0.25단위가 아닐경우 근처 값으로 보정
                // const fixedZoom:Number = getNearestZoomValue(rzoomed);
                // // zoomed = fixedZoom;
                // setZoomCanvas(fixedZoom);
                setResizeButtonVisible(true);
                removeReplayMainEvent();
                updatePreviewCursorPos();

                if(traceMenuON === true) traceMenuBox.visible = true;
                changeTopBarIcons("draw");

                _appInfoBox.insertCanvasInfo([CANVAS_WIDTH,CANVAS_HEIGHT,zoomed*100,_regPoint.rotation]);
                addMainEvent();
            }
            else if(flag) //리플레이 켜줄때
            {
                setTopChildIndex(rCursor);
                removeMainEvent();

                TOTAL_FRAME = getTotalFrame();
                checkReplaySpeedState();

                //frame sum이 재계산된 maxframe을 넘어가면 리플레이 프레임이 넘어가기 때문에 끝난거임
                //그래서 캔버스 복사해주고 리플레이를 리셋해줌
                const maxf:Number = TOTAL_FRAME;
                
                if(replayONUndoUpdate || maxf === 0)// && rf > maxf)
                {
                    replayONUndoUpdate = false;
                    rCursor.visible = false;
                    rDataReadFlag = false;
                    replayTimeBox["frameInfo"].text = maxf+" / " + maxf;
                    replayTimeBox["replayNowBar"].width = (maxf === 0) ? 0 : replayTimeBox["replayTotalBar"].width;
                    clearCanvasReplayMode();
                    resetReplayTime();

                    rcanvas1BitmapData.dispose();
                    rcanvas1BitmapData = canvas1BitmapData.clone();
                    rcanvas1Bitmap.bitmapData = rcanvas1BitmapData;
                    // rcanvas1Bitmap.smoothing = true;
                    setPanelSizeReplayMode(canvas1Bitmap.width,canvas1Bitmap.height);
                    setBackgroundColor(CANVAS_BG_COLOR,true);
                }

                if(rFrameSum === 0)
                {
                    rCursor.visible = false;
                }

                // if(rSkipImageInit === 0)
                // {
                //     canvasFitWindow();
                //     rzoomed = 1;
                //     _rregPoint.scaleX = 1;
                //     _rregPoint.scaleY = 1;
                //     rzoomedIndex = zoomArr.indexOf(rzoomed);

                //     // if(CANVAS_WIDTH === RCANVAS_WIDTH && CANVAS_HEIGHT === RCANVAS_HEIGHT)
                //     // {
                //     //     rzoomed = zoomed;//줌배율도 공유
                //     //     _rregPoint.scaleX = _regPoint.scaleX;
                //     //     _rregPoint.scaleY = _regPoint.scaleY;
                //     //     _rregPoint.rotation = _regPoint.rotation;
                //     //     _rregPoint.x = _regPoint.x;
                //     //     _rregPoint.y = _regPoint.y;
                //     //     _rcanvasPanel.x = _canvasPanel.x;
                //     //     _rcanvasPanel.y = _canvasPanel.y;
                //     // }
                //     // else
                //     // {
                //     //     canvasFitWindow();
                //     // }
                // }

                checkCutFrameButtons();
                updateReplayBarPos(stage.stageWidth,stage.stageHeight);
                updateReplayCanvasBounds();

                if(traceMenuON === true) traceMenuBox.visible = false;

                changeTopBarIcons("replay");

                if(rSkipImageInit === 1)
                {
                    makeSkipImage();
                }
                else if(rSkipImageInit === 0)
                {
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
            if(mouseClickON)
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
                if(!(targetName === "capRotate" || targetName === "capFlip" || targetName === "capFull" || targetName === "capOff" || targetName === "capTrans" || targetName === "capTransCheck"))
                {
                    drawCaptureArea();
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

                case "dragDropFileButton":
                {
                    loadImageDragDrop(tempDragDropFile,false);
                    fileDragSelectBox.visible = false;
                }
                return;

                case "dragDropRefButton":
                {
                    loadImageDragDrop(tempDragDropFile,true);
                    fileDragSelectBox.visible = false;
                }
                return;

                case "dragDropCancelButton":
                {
                    fileDragSelectBox.visible = false;
                }
                return;
                
                case "replaySpeedBarWrapper":
                {
                    setReplaySpeedButton();
                }
                return;
                case "replayPrev":
                {
                    setSkipOneFrame(true,false,e.shiftKey);
                    break;
                }

                case "replayNext":
                {
                    setSkipOneFrame(false,false,e.shiftKey);
                }
                break;

                case "rToolInfo":
                case "rToolBG":
                {
                    moveToolBoxByType(3);
                }
                break;

                case "replayNowBar":
                case "replayTotalBar":
                case "frameInfo":
                {
                    setSkipFrameButton();
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
                case "capTransCheck":
                case "capFlip":
                case "capRotate":
                case "repCaptureButton":
                case "clipButton":
                case "topBarColorButton":
                case "timerResetButton":
                case "playButton":
                case "pauseButton":
                case "replayZoomInButton":
                case "replayZoomOutButton":
                {
                    if(nowKey !== 0) return;

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
                nowKey = 0;
                setPrevTool();
                if(keybufferArr.length > 0)
                {
                    const nextKey:int = keybufferArr[0];
                    checkToolKeyDown(nextKey);
                    keybufferArr.shift()
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
            if(captureModeON || rNowKey !== 0) return;
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

            const mx:Number = mouseX;
            const my:Number = mouseY;
            const _toolBox2:toolButtons2 = toolBox2;

            // if(toolBoxAlwaysON === true)
            // {
            //     toolBox.visible = false;
            // }

            if(toolBoxLastClickPos[0] === 0 && toolBoxLastClickPos[1] === 0)
            {
                toolBoxLastClickPos[0] = -_toolBox2.width/2;
                toolBoxLastClickPos[1] = -_toolBox2.height/2;
            }
            _toolBox2.x = mx+toolBoxLastClickPos[0];//원점에서 마지막으로 클릭한 위치로 옮겨줌
            _toolBox2.y = my+toolBoxLastClickPos[1];
            checkBoxPosition(_toolBox2);
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

            if(targetName === "resizeButtonR"
            || targetName === "resizeButtonD"
            || targetName === "resizeButtonL"
            || targetName === "resizeButtonU")
            {
                if(!lassoToolON)
                {
                    setActiveResizeButton(e.target as Sprite);
                    stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, canvasSizeButtonMouseUPEvent);
                    stage.addEventListener(MouseEvent.MOUSE_UP, canvasSizeButtonMouseUPEvent);
                }
            }
            else if(targetName === "prevStageBG"
            ||targetName === "prevBitmapBG"
            ||targetName === "prevBitmap"
            ||targetName === "prevCursor")
            {
                previewBox.prevBitmapBG.visible =  !previewBox.prevBitmapBG.visible
                previewBox.prevBitmap.visible = !previewBox.prevBitmap.visible
                previewBox.prevCursor.visible =  !previewBox.prevCursor.visible
            }
            else if(targetName === "saveButton")
            {
                saveFile(true);
            }
            else if(targetName === "loadButton")
            {
                loadFile(true);
            }
            else if(targetName && (targetName.indexOf("canvas") !== -1 || targetName === "stageBG" || targetName === "canvasGrid"))
            {
                openToolBox2();
            }
        }

        private function checkControlBoxButtons(target:DisplayObject):void
        {
            if(toolBox2ON)
            {
                return;
            }

            const targetName:String = target.name;

            setTopChildIndex(controlBox);

            switch(targetName)
            {
                case "shapeRect":
                {
                    setShapeButton(true);
                }
                return;
                case "shapeCircle":
                {
                    setShapeButton(false);
                }
                return;

                case "penSmoothSlider":
                case "penSmoothButton":
                {
                    if(nowTool > 4) return;
                    setPenSmoothButton();

                }
                return;

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
                return;

                case "alphaButton0":
                case "alphaButton1":
                case "alphaButton2":
                case "alphaButton3":
                {
                    setAlphaButton(targetName);
                }
                return;

                case "subLayerButtonWapper":
                case "subLayerOFFButton":
                case "subLayerONButton":
                case "subLayerText":
                {
                    if(subLayerON === true)
                    {
                        setSubLayerButton(false);
                    }
                    else if(subLayerON === false)
                    {
                        setSubLayerButton(true);
                    }
                }
                return;
                case "pixelSnapButtonWapper":
                case "pixelSnapOFFButton":
                case "pixelSnapONButton":
                case "pixelSnapText":
                {
                    if(pixelSnap === true)
                    {
                        setPixelSnapButton(false);
                    }
                    else if(pixelSnap === false)
                    {
                        setPixelSnapButton(true);
                    }
                }
                return;

            }
        }

        private function checkPickerBoxButtons(target:DisplayObject):void
        {
            if(toolBox2ON || nowKey !== 0) return;
            const targetName:String = target.name;
            const _pickerBox:colorPickerBox = pickerBox;
            const mode:uint = pickerMode;

            colorHistoryUpdateReady = false;
            // stage.removeEventListener(MouseEvent.MOUSE_DOWN,updateColorHistoryEvent);

            setTopChildIndex(pickerBox);
            if(targetName && targetName.indexOf("preset") !== -1)
            {
                setPresetColor(target,(pickerMode == 2) ? true : false);
                return;
            }

            switch(targetName)
            {
                case "bgText":
                case "bgButtonBorder":
                {
                    if(pickerMode === 1)
                    {
                        changePickerModeToBG();
                    }
                    else if(pickerMode === 2)
                    {
                        changePickerModeToNormal();
                    }
                }
                break;

                case "mainPickerBox":
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
                    const hexColor:uint = pickerBox.currentColorColor;
                    const _setColorTransform:Function = setColorTransform;
                    const c:Vector.<uint> = HEXtoRGB(hexColor);
                    const colorHint:String = "RGB "+c[0]+","+c[1]+","+c[2];

                    pickerColorSelected = true;

                    setHSVCursorPosByColor(hexColor);

                    if(mode === 1)
                    {
                        penColor = hexColor;//색깔이 다를때만
                        updateOpaBoxColor(hexColor);
                        updateOpacityCursor(penAlphaIndex);
                    }
                    else if(mode === 2)
                    {
                        setBackgroundColor(hexColor);
                        colorHistoryList[0] = hexColor;
                        updateColorHistoryList();
                        rDataBuffer.push(["bgColor",hexColor]);
                        addUndoData(3);
                    }

                    _pickerBox.setRGBInfo(colorHint);
                    // pickerLastHint = colorHint;
                }
                return;
            }
        }

        private function checkLassoToolButtons(targetName:String):void //mdown1
        {
            switch(targetName)
            {
                case "lassoMirror":
                {
                    lassoMirrorON = !lassoMirrorON;
                    lassoBox.scaleX = -lassoBox.scaleX;

                    //캔버스가 회전한각도도 있어서 항상 세로축을 중심으로 대칭되게 regpoint각도를 보정값으로 넣어줌
                    lassoBox.rotation = -lassoBox.rotation-(regPoint.rotation*2);
                }
                return;

                case "lasso1pxLeft":
                {
                    setLasso1PxMoveButton("left");
                }
                return;
                case "lasso1pxRight":
                {
                    setLasso1PxMoveButton("right");
                }
                return;
                case "lasso1pxUp":
                {
                    setLasso1PxMoveButton("up");
                }
                return;
                case "lasso1pxDown":
                {
                    setLasso1PxMoveButton("down");
                }
                return;
                case "lassoMove":
                {
                    setLassoMoveButton();
                }
                return;

                case "lassoResize":
                {
                    setLassoResizeButton();
                }
                return;

                case "lassoRotate":
                {
                    setLassoRotateButton();
                }
                return;

                case "lassoCopy":
                {
                    setLassoCopyButton();
                }
                return;

                case "lassoOK":
                {
                    consoleBox.print("Lasso OK");
                    setLassoOKButton();
                }
                return;

                case "lassoCancel":
                {
                    if(lassoToolON === true)
                    {
                        consoleBox.print("Lasso canceled");
                        setLassoCancelButton();
                    }
                }
                return;

                case "lassoInfo":
                case "lassoMenuMoveButton":
                {
                    setTopChildIndex(lassoMenu);
                    moveToolBoxByType(1);
                }
                return;

                case "lassoCRotate":
                {
                    lassoMenu.visible = false;
                    lassoMenuTempOFF = true;
                    setRotateTool();
                }
                return;

                case "lassoCZoom":
                {
                    lassoMenu.visible = false;
                    lassoMenuTempOFF = true;
                    setZoomTool();
                }
                return;

                case "lassoCHand":
                {
                    lassoMenu.visible = false;
                    lassoMenuTempOFF = true;
                    setHandTool(false);
                }
                return;
            }
        }

        private function mouseDownEvent(e:MouseEvent):void //mdown1
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

            // if(e.shiftKey)
            // {
            //     floodFill(canvas1Bitmap.mouseX,canvas1Bitmap.mouseY,penColor,penAlpha);
            //     return;
            // }

            if(lassoToolON && !lassoMenuTempOFF)
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
                    case "capTransCheck":
                    break;

                    default:
                        drawCaptureArea();
                    return;
                }
            }
            else if(reizeButtonClickEnt !== null && reizeButtonClickEnt !== target)
            {
                setDeactiveResizeButton();
                return;
            }
            else if(sideBar.hitTestPoint(mouseX,mouseY,true) && nowKey === 0)
            {
                if(checkPickerBoxButtons(target)) return;
                else if(checkControlBoxButtons(target)) return;
                else if(checkToolBoxButtons(targetName)) return;
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
                case "capTransCheck":
                case "capRotate":
                case "captureButton":
                case "repCaptureButton":
                case "clipButton":
                case "topBarColorButton":
                case "gridButton":
                case "timerResetButton":
                case "penOptionButton":
                case "aboutButton":
                case "sideBarPositionButton":
                {
                    if(toolBox2ON || lassoToolON || nowKey !== 0 || e.target.alpha < 1.0)
                    {
                        return;
                    }

                    checkButtonUp(targetName);
                }
                return;
                case "consoleText":
                {
                    setHandTool(false,true);
                }
                return;
                case "prevStageBG":
                case "prevBitmapBG":
                case "prevBitmap":
                    setHandToolPreviewBox(false);
                return;
                case "prevCursor":
                    setHandToolPreviewBox(true);
                return;

                return;
                case "dragDropFileBG":
                return;

                case "dragDropFileButton":
                {
                    loadImageDragDrop(tempDragDropFile,false);
                    fileDragSelectBox.visible = false;
                }
                return;

                case "dragDropRefButton":
                {
                    loadImageDragDrop(tempDragDropFile,true);
                    fileDragSelectBox.visible = false;
                }
                return;

                case "dragDropCancelButton":
                {
                    fileDragSelectBox.visible = false;
                }
                return;

                case "traceCancelButton":
                {
                    setTopChildIndex(traceMenuBox);
                    closeTraceMenu();
                }
                return;

                case "traceImageButton":
                {
                    setTraceImageButton();
                }
                return;

                case "traceLoadButton":
                {
                    setTopChildIndex(traceMenuBox);
                    checkButtonUp(targetName);
                }
                return;

                case "traceClipButton":
                {
                    setTopChildIndex(traceMenuBox);
                    setTraceClipButton();
                }
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

                case "traceMirrorButton":
                {
                    setTopChildIndex(traceMenuBox);
                    setTraceMirrorButton();
                }
                return;

                case "traceDeleteButton":
                {
                    setTopChildIndex(traceMenuBox);
                    setTraceDeleteButton();
                }
                return;

                case "traceVisibleONButton":
                case "traceVisibleOFFButton":
                {
                    setTopChildIndex(traceMenuBox);
                    setTraceVisibleButton();
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
                        if(checkResizeButton(target as Sprite,e.controlKey) === true) return;
                    }
                }
                break;

                case "traceInfo":
                case "traceMenuMoveButton":
                {
                    moveToolBoxByType(2);
                }
                return;
            }

            //캔버스 영역 밖에서는 해주지 않음
            if(mouseX <= LEFT_OFFSET || mouseX >= stage.stageWidth-RIGHT_OFFSET
            || mouseY <= TOP_OFFSET || mouseY >= stage.stageHeight-BOTTOM_OFFSET
            || clickBlockFlag === true)
            {
                return;
            }

            switch (nowTool)
            {
                case TOOL_PEN:
                    setPenTool(true);
                break;

                case TOOL_ERASE:
                    setPenTool(false);
                break;

                case TOOL_LINE:
                case TOOL_LINE_ERASE:
                    setLineTool();
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