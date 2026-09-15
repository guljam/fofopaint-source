package Modules.Tools
{
    import flash.geom.Point;
    import Modules.Utils;
    import Modules.CanvasController;

    public class DotTool
    {
        private static var cmd:Vector.<int> = new Vector.<int>();
        private static var pos:Vector.<Number> = new Vector.<Number>();

        public static function start(shape:Boolean, size:uint, color:uint, posX:Number, posY:Number, rotation:Number):void
        {
            CanvasController.canvasDrawLayerChild.graphics.clear();
            CanvasController.canvasDrawLayerChild.graphics.lineStyle(0, 0, 0);
            CanvasController.canvasDrawLayerChild.graphics.beginFill(color);
    
            if (shape === true)
            {
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
                cmd.length = 0;
                pos.length = 0;
            }
            else
            {
                CanvasController.canvasDrawLayerChild.graphics.drawCircle(posX, posY, size / 2);
            }
            CanvasController.canvasDrawLayerChild.graphics.endFill();
        }
    }
}
