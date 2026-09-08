package Modules
{
    import flash.geom.Rectangle;

    public class AppStateManager
    {
        public function AppStageManager():void {}
        public var canvasZoomIndex:int;
        public var canvasZoomedMultiplier:Number;
        public var canvasPanelX:Number;
        public var canvasPanelY:Number;
        public var canvasAnchorPointX:Number;
        public var canvasAnchorPointY:Number;
        public var canvasAnchorPointRotation:Number;
        public var penSmoothValue:Number;
        public var penSmoothSlideValue:int;
        public var penSmoothButtonX:Number;
        public var penSize:uint;
        public var penSizeIndex:int;
        public var penColor:uint;
        public var penAlpha:Number;
        public var penIsSquare:Boolean;
        public var eraseSize:uint;
        public var eraseSizeIndex:uint;
        public var eraserIsSquare:Boolean;
        public var eraseAlpha:Number;
        public var stageNativeWindowX:Number;
        public var stageNativeWindowY:Number;
        public var stageNativeWindowWidth:Number;
        public var stageNativeWindowHeight:Number;
        public var saveFileName:String;
        public var lastWindowState:int;
        public var uiColorIndex:int;
        public var appRunningTime:int;
        public var refLayerLastAlpha:Number;
        public var refOpacityCursorX:Number;
        public var refLayerMenuDragXMoveSum:Number;
        public var canvasRefLayerBitmapX:Number;
        public var canvasRefLayerBitmapY:Number;
        public var canvasRefLayerRotation:Number;
        public var canvasRefLayerScaleX:Number;
        public var canvasRefLayerScaleY:Number;
        public var refLayerMenuBox0:Number;
        public var refLayerMenuBox1:Number;
        public var isCanvasMirrored:Boolean;
        public var gridValue:uint;
        public var hsvColorData0:Number;
        public var gridDrawOffsetX:Number;
        public var gridDrawOffsetY:Number;
        public var hueCursorX:Number;
        public var svBaseColor:uint;
        public var isHSVInfoTextMode:Boolean;
        public var rReplayImageCacheState:int;
        public var rLastCanvasBGColor:uint;
        public var isRightSidebar:Boolean;
        public var saveFilePath:String;
        public var isSidebarVisible:Boolean;
        public var uiScaleIndex:int;
        public var canvasWindowON:Boolean;
        public var newWindowInfo0:Number;
        public var newWindowInfo1:Number;
        public var newWindowInfo2:Number;
        public var newWindowInfo3:Number;
        public var getFirstRCursorPosX:Number;
        public var getFirstRCursorPosY:Number;
        public var isContinueSaveON:Boolean;
        public var myPalettePresetType:int;
        public var isMyPaletteExpended:Boolean;
        public var isColorPickerBoxPositionSwapped:Boolean;
        public var captureStampText:String;
        public var isCaptureStampON:Boolean;
        public var captureStampFont:String;
        public var scrollSetMovedY:Number;
        public var isRefLayerMemoryTrainingON:Boolean;
    }
}
