package Modules.ReplayEngine
{
    import Modules.DrawEngine.DrawCanvas;
    import Modules.ReferenceLayerController;

    public class ReplaySaveMetaData
    {
        public static var firstImageWidth:Number = 0.0;
        public static var firstImageHeight:Number = 0.0;
        public static var firstImageBG:uint = 0;
        public static var firstImageMirrorFlag:Boolean = false;
        public static var finalImageWidth:Number = 0.0;
        public static var finalImageHeight:Number = 0.0;
        public static var finalImageBG:uint = 0;
        public static var refImageWidth:Number = 0.0;
        public static var refImageHeight:Number = 0.0;
        public static var refImageBitmapX:Number = 0.0;
        public static var refImageBitmapY:Number = 0.0;
        public static var refImageBitmapRotation:Number = 0.0;
        public static var refImageBitmapScaleX:Number = 0.0;
        public static var refImageBitmapScaleY:Number = 0.0;
        public static var refImageBitmapMirrorFlag:Boolean = false;
        public static var refImageBitmapMoveSum:Number = 0.0;
        public static var refImageAlpha:Number = 0.0;

        public static function update():void
        {
            firstImageWidth = ReplayFileCache.rFirstImageLayer1BitmapData.width;
            firstImageHeight = ReplayFileCache.rFirstImageLayer1BitmapData.height;
            finalImageWidth = DrawCanvas.canvasLayer1BitmapData.width;
            finalImageHeight = DrawCanvas.canvasLayer1BitmapData.height;
            finalImageBG = DrawCanvas.CANVAS_BG_COLOR;
            refImageWidth = ReferenceLayerController.canvasRefLayerBitmapData.width;
            refImageHeight = ReferenceLayerController.canvasRefLayerBitmapData.height;
            refImageBitmapX = ReferenceLayerController.canvasRefLayerBitmap.x;
            refImageBitmapY = ReferenceLayerController.canvasRefLayerBitmap.y;
            refImageBitmapRotation = ReferenceLayerController.canvasRefLayer.rotation;
            refImageBitmapScaleX = ReferenceLayerController.canvasRefLayer.scaleX;
            refImageBitmapScaleY = ReferenceLayerController.canvasRefLayer.scaleY;
            refImageBitmapMirrorFlag = Boolean(ReferenceLayerController.canvasRefLayer.scaleX < 0);
            refImageBitmapMoveSum = ReferenceLayerController.refLayerMenuDragXMoveSum;
            refImageAlpha = ReferenceLayerController.refLayerLastAlpha;
        }
    }
}
