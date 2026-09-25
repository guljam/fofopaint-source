package Modules
{
    import flash.geom.Point;
    import Modules.Tools.LassoTool;
    import flash.display.LineScaleMode;
    import flash.display.CapsStyle;
    import flash.display.BitmapData;
    import flash.geom.ColorTransform;
    import flash.geom.Rectangle;
    import flash.display.JointStyle;
    import flash.geom.Matrix;
    import flash.filters.BlurFilter;

    public class ReplayDrawCommands
    {
        public static const rCursorPos:Point = new Point(0, 0);
        // undo인덱스가 처음일때 tickdraw가 아무것도 안해주니까 위치 갱신이 안되서
        // undorefimage갱신 될때 마다 마지막 포인터 위치 저장해주는거
        public static const rCursorPosFirst:Point = new Point(-1, -1);
        public static var lineStyleBackup:Array = [1.0, null];
        // tempdone에서 쓰는 플래그임
        public static var index:uint = 0;
        public static var data:Array = []; // 데이터 뭉치
        public static const cmd:Vector.<int> = new Vector.<int>();
        public static const pos:Vector.<Number> = new Vector.<Number>();

        public static function updateLineStyleBackup(alpha:Number, blendMode:String):void
        {
            lineStyleBackup[0] = alpha;
            lineStyleBackup[1] = blendMode;
        }

        public static function getFirstRCursorPos():Point
        {
            return rCursorPosFirst;
        }

        public static function resetFirstRCursorPos():void
        {
            rCursorPosFirst.setTo(-1, -1);
        }

        public static function setFirstRCursorPos(x:Number, y:Number):void
        {
            rCursorPosFirst.setTo(x, y);
        }

        public static function setFirstRCursorPosCurrent():void
        {
            rCursorPosFirst.setTo(rCursorPos.x, rCursorPos.y);
        }

        public static function hasRCursorFirstPos():Boolean
        {
            return rCursorPosFirst.x > 0 && rCursorPosFirst.y > 0;
        }

        public static function updateRCursorPosToFirst():void
        {
            ReplayController.rReplayFOFOCursor.x = rCursorPosFirst.x;
            ReplayController.rReplayFOFOCursor.y = rCursorPosFirst.y;
        }

        public static function updateRCursorPos():void
        {
            ReplayController.rReplayFOFOCursor.x = rCursorPos.x;
            ReplayController.rReplayFOFOCursor.y = rCursorPos.y;
        }

        public static function setRCursorPosFromMoveTool(x:Number, y:Number):void
        {
            setRCursorPos(rCursorPos.x + x, rCursorPos.y + y);
        }

        public static function setRCursorPosToCenter():void
        {
            setRCursorPos(ReplayController.RCANVAS_WIDTH / 2, ReplayController.RCANVAS_HEIGHT / 2);
        }

        public static function setRCursorPos(x:Number, y:Number):void
        {
            if (x < 0)
                x = 0;

            else if (x > ReplayController.RCANVAS_WIDTH)
                x = ReplayController.RCANVAS_WIDTH;

            if (y < 0)
                y = 0;

            else if (y > ReplayController.RCANVAS_HEIGHT)
                y = ReplayController.RCANVAS_HEIGHT;
            rCursorPos.setTo(x, y);
        }

        public static function getRCursorPos():Point
        {
            return rCursorPos;
        }

        public static function clearData():void
        {
            data = [];
            index = 0;
        }

        public static function setData(refData:Array, startIndex:uint = 0):void
        {
            data = refData;
            index = startIndex;
        }

        public static function getRemainingData():uint
        {
            if (!data)
                return 0;

            return data.length - index;
        }

        public static function isReadFinished():Boolean
        {
            if (!data)
                return true;
            return index > data.length - 1;
        }

        public static function getDataLength():uint
        {
            if (!data)
                return 0;
            return data.length;
        }

        public static function getCurrentPosition():uint
        {
            return index;
        }

        public static function setIndex(newIndex:uint):void
        {
            index = newIndex;
        }

        public static function getLineStyleAlpha():Number
        {
            return lineStyleBackup[0];
        }

        public static function getrLineStyleSave():Array
        {
            if (lineStyleBackup.length !== 2)
                return [1.0, null];
            return lineStyleBackup;
        }

        public static function drawAll():void
        {
            var len:uint = data.length;

            for (var i:uint = 0;i < len;i++)
            {
                drawNext();
            }
        }

        public static function checkAirBrush(airBrushFlag:Boolean, size:uint):void
        {
            if (airBrushFlag === true)
            {
                if (ReplayController.rAirBrushSize !== size)
                    ReplayController.blurReplayCanvasByValue(size);
            }
            else if (ReplayController.rAirBrushSize > 0)
            {
                ReplayController.resetBlurReplayCanvas();
            }
        }

        public static function checkSubLayer(subLayerFlag:Boolean):void
        {
            if (subLayerFlag)
            {
                // if((replayStartON && subLayerFlag) !== false && rSubLayerSave !== subLayerFlag)

                if (ReplayController.rLastLayer2Selcted !== subLayerFlag)
                {
                    ReplayController.selectReplaySubLayer(subLayerFlag);
                }
            }
            else if (ReplayController.rLastLayer2Selcted)
            {
                ReplayController.selectReplaySubLayer(false);
            }
        }

        public static function lineStyle5(data:Array):void
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
            ReplayController.rAirBrushSize2 = airBrushSize;

            if (fillpen)
            {
                ReplayController.rCanvasDrawShape.graphics.clear();
                ReplayController.replayLineStyleReady2(false, 1, color, 1.0);
                ReplayController.rCanvasDrawShape.graphics.beginFill(color);
                ReplayController.rCanvasDrawShape.graphics.moveTo(startX, startY);
                ReplayController.rCanvasDrawLayer.alpha = alpha;
            }
            else
            {
                ReplayController.replayLineStyleReady3(shape, size, color, alpha);
                ReplayController.rCanvasDrawShape.graphics.moveTo(startX, startY);
            }

            if (index === 0)
            {
                CanvasController.resetRCanvasDrawLayerCliprect2();
            }
            else
            {
                ReplayController.updateRCanvasDrawLayerCliprect2();
            }
        }

        public static function lineStyle4(data:Array):void
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
                ReplayController.rCanvasDrawShape.graphics.clear();
                ReplayController.replayLineStyleReady2(false, 1, color, 1.0);
                ReplayController.rCanvasDrawShape.graphics.beginFill(color);
                ReplayController.rCanvasDrawShape.graphics.moveTo(startX, startY);
                ReplayController.rCanvasDrawLayer.alpha = alpha;
            }
            else
            {
                ReplayController.replayLineStyleReady3(shape, size, color, alpha);
                ReplayController.rCanvasDrawShape.graphics.moveTo(startX, startY);
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

        public static function lineStyle3(data:Array):void
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
                ReplayController.replayLineStyleReady3(shape, size, color, alpha);
                ReplayController.rCanvasDrawShape.graphics.moveTo(startX, startY);
            }
            else
            {
                ReplayController.rCanvasDrawShape.graphics.clear();
                ReplayController.replayLineStyleReady2(false, 1, color, 1.0);
                ReplayController.rCanvasDrawShape.graphics.beginFill(color);
                ReplayController.rCanvasDrawShape.graphics.moveTo(startX, startY);
                ReplayController.rCanvasDrawLayer.alpha = alpha;
            }
        }

        public static function lineStyle2(data:Array):void
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
                ReplayController.replayLineStyleReady2(shape, size, color, alpha);
                ReplayController.rCanvasDrawShape.graphics.moveTo(startX, startY);
            }
            else
            {
                ReplayController.rCanvasDrawShape.graphics.clear();
                ReplayController.replayLineStyleReady2(false, 1, color, 1.0);
                ReplayController.rCanvasDrawShape.graphics.beginFill(color);
                ReplayController.rCanvasDrawShape.graphics.moveTo(startX, startY);
                ReplayController.rCanvasDrawLayer.alpha = alpha;
            }
        }

        public static function lineStyle(data:Array):void
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
                ReplayController.replayLineStyleReady(shape, size, color, alpha);
                ReplayController.rCanvasDrawShape.graphics.moveTo(startX, startY);
            }
            else
            {
                ReplayController.rCanvasDrawShape.graphics.clear();
                ReplayController.replayLineStyleReady(false, 1, color, 1.0);
                ReplayController.rCanvasDrawShape.graphics.beginFill(color);
                ReplayController.rCanvasDrawShape.graphics.moveTo(startX, startY);
                ReplayController.rCanvasDrawLayer.alpha = alpha;
            }
        }

        public static function lineTo(data:Array):void
        {
            const x:Number = data[1];
            const y:Number = data[2];
            ReplayController.rCanvasDrawShape.graphics.lineTo(x, y);
            setRCursorPos(x, y);
        }

        public static function sqline(data:Array):void
        {
            const size:Number = data[1];
            const color:Number = data[2];
            const alpha:Number = data[3];
            const blendMode:String = data[4];
            const command:Vector.<int> = data[5];
            const xyData:Vector.<Number> = data[6];

            // 왜 재할당을 하는지 모르겠는데 일단 남겨둠 구버전 명령어라서 더이상 안씀
            // 예전에 직선툴에서 움직일때 뭔가 잔상이 남거나 해서 지워주었을수도 있음
            ReplayController.rCanvasDrawLayerBitmap.bitmapData = null;
            ReplayController.rCanvasDrawLayerBitmapData.dispose();
            ReplayController.rCanvasDrawLayerBitmapData = new BitmapData(ReplayController.RCANVAS_WIDTH, ReplayController.RCANVAS_HEIGHT, true, 0);
            ReplayController.rCanvasDrawShape.graphics.clear();
            updateLineStyleBackup(alpha, blendMode);
            ReplayController.rCanvasDrawLayer.alpha = alpha;
            ReplayController.rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.SQUARE, JointStyle.ROUND);
            ReplayController.rCanvasDrawShape.graphics.drawPath(command, xyData);
            setRCursorPos(xyData[xyData.length - 2], xyData[xyData.length - 1]);
        }

        public static function fill5(data:Array):void
        {
            const color:Number = data[1];
            const alpha:Number = data[2];
            const blendMode:String = data[3];
            const command:Vector.<int> = data[4];
            const xyData:Vector.<Number> = data[5];
            const airBrushFlag:Boolean = data[6];
            const airBrushSize:uint = data[7];
            ReplayController.rAirBrushSize2 = airBrushSize;
            updateLineStyleBackup(alpha, blendMode);
            ReplayController.rCanvasDrawLayer.alpha = alpha;
            ReplayController.rCanvasDrawShape.graphics.clear();
            ReplayController.rCanvasDrawShape.graphics.lineStyle(1, color);
            ReplayController.rCanvasDrawShape.graphics.beginFill(color);
            ReplayController.rCanvasDrawShape.graphics.drawPath(command, xyData);
            setRCursorPos(xyData[xyData.length - 2], xyData[xyData.length - 1]);
            CanvasController.resetRCanvasDrawLayerCliprect2();
        }

        public static function fill4(data:Array):void
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
            ReplayController.rCanvasDrawLayer.alpha = alpha;
            ReplayController.rCanvasDrawShape.graphics.clear();
            ReplayController.rCanvasDrawShape.graphics.lineStyle(1, color);
            ReplayController.rCanvasDrawShape.graphics.beginFill(color);
            ReplayController.rCanvasDrawShape.graphics.drawPath(command, xyData);
            setRCursorPos(xyData[xyData.length - 2], xyData[xyData.length - 1]);
            CanvasController.resetRCanvasDrawLayerCliprect();
        }

        public static function fill3(data:Array):void
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
            ReplayController.rCanvasDrawLayer.alpha = alpha;
            ReplayController.rCanvasDrawShape.graphics.clear();
            ReplayController.rCanvasDrawShape.graphics.lineStyle(1, color);
            ReplayController.rCanvasDrawShape.graphics.beginFill(color);
            ReplayController.rCanvasDrawShape.graphics.drawPath(command, xyData);
            setRCursorPos(xyData[xyData.length - 2], xyData[xyData.length - 1]);
        }

        public static function fill2(data:Array):void
        {
            const color:Number = data[1];
            const alpha:Number = data[2];
            const blendMode:String = data[3];
            const arr:Vector.<Number> = data[4];
            const len:uint = arr.length;
            ReplayController.resetBlurReplayCanvas();
            updateLineStyleBackup(alpha, blendMode);
            ReplayController.rCanvasDrawLayer.alpha = alpha;
            ReplayController.rCanvasDrawShape.graphics.clear();
            ReplayController.rCanvasDrawShape.graphics.lineStyle(1, color);
            ReplayController.rCanvasDrawShape.graphics.beginFill(color);
            ReplayController.rCanvasDrawShape.graphics.moveTo(arr[0], arr[1]);

            for (var i:uint = 2;i < len;i += 2)
            {
                ReplayController.rCanvasDrawShape.graphics.lineTo(arr[i], arr[i + 1]);
            }

            ReplayController.rCanvasDrawShape.graphics.endFill();
            setRCursorPos(arr[len - 2], arr[len - 1]);
        }

        public static function fill(data:Array):void
        {
            const color:Number = data[1];
            const alpha:Number = data[2];
            const blendMode:String = data[3];
            const command:Vector.<int> = data[4];
            const xyData:Vector.<Number> = data[5];
            ReplayController.resetBlurReplayCanvas();
            updateLineStyleBackup(alpha, blendMode);
            ReplayController.rCanvasDrawLayer.alpha = alpha;
            ReplayController.rCanvasDrawShape.graphics.clear();
            ReplayController.rCanvasDrawShape.graphics.lineStyle(1, color);
            ReplayController.rCanvasDrawShape.graphics.beginFill(color);
            ReplayController.rCanvasDrawShape.graphics.drawPath(command, xyData);
            setRCursorPos(xyData[xyData.length - 2], xyData[xyData.length - 1]);
        }

        public static function dot4(data:Array):void
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
            ReplayController.rAirBrushSize2 = airBrushSize;
            updateLineStyleBackup(alpha, blendMode);
            ReplayController.rCanvasDrawLayer.alpha = alpha;
            ReplayController.rCanvasDrawShape.graphics.lineStyle(0, 0, 0);
            ReplayController.rCanvasDrawShape.graphics.beginFill(color);

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
                ReplayController.rCanvasDrawShape.graphics.drawPath(cmd, pos);
                point = null;
            }
            else
            {
                ReplayController.rCanvasDrawShape.graphics.drawCircle(startX, startY, size / 2);
            }

            ReplayController.rCanvasDrawShape.graphics.endFill();
            CanvasController.resetRCanvasDrawLayerCliprect2();
            setRCursorPos(startX, startY);
        }

        public static function dot3(data:Array):void
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
            ReplayController.rCanvasDrawLayer.alpha = alpha;
            ReplayController.rCanvasDrawShape.graphics.lineStyle(0, 0, 0);
            ReplayController.rCanvasDrawShape.graphics.beginFill(color);

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
                ReplayController.rCanvasDrawShape.graphics.drawPath(cmd, pos);
            }
            else
            {
                ReplayController.rCanvasDrawShape.graphics.drawCircle(startX, startY, size / 2);
            }

            ReplayController.rCanvasDrawShape.graphics.endFill();
            CanvasController.resetRCanvasDrawLayerCliprect();
            setRCursorPos(startX, startY);
        }

        public static function dot2(data:Array):void
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
            ReplayController.rCanvasDrawLayer.alpha = alpha;
            ReplayController.rCanvasDrawShape.graphics.lineStyle(0, 0, 0);
            ReplayController.rCanvasDrawShape.graphics.beginFill(color);

            if (shape)
                ReplayController.rCanvasDrawShape.graphics.drawRect(startX - size / 2, startY - size / 2, size, size);

            else
                ReplayController.rCanvasDrawShape.graphics.drawCircle(startX, startY, size / 2);
            ReplayController.rCanvasDrawShape.graphics.endFill();
            CanvasController.resetRCanvasDrawLayerCliprect();
            setRCursorPos(startX, startY);
        }

        public static function dot(data:Array):void
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
            ReplayController.rCanvasDrawLayer.alpha = alpha;
            ReplayController.rCanvasDrawShape.graphics.lineStyle(0, 0, 0);
            ReplayController.rCanvasDrawShape.graphics.beginFill(color);

            if (shape)
                ReplayController.rCanvasDrawShape.graphics.drawRect(startX - size / 2, startY - size / 2, size, size);

            else
                ReplayController.rCanvasDrawShape.graphics.drawCircle(startX, startY, size / 2);
            ReplayController.rCanvasDrawShape.graphics.endFill();
            setRCursorPos(startX, startY);
        }

        public static function line4(data:Array):void
        {
            const shape:Boolean = data[1];
            const size:uint = data[2];
            const color:uint = data[3];
            const alpha:Number = data[4];
            const command:Vector.<int> = data[5];
            const xydata:Vector.<Number> = data[6];
            const blendMode:String = data[7];
            const subLayer:Boolean = data[8];
            const airBrushSize:Number = data[9];

            updateLineStyleBackup(alpha, blendMode);
            ReplayController.rCanvasDrawLayer.alpha = alpha;
            checkSubLayer(subLayer);
            ReplayController.rAirBrushSize2 = airBrushSize;

            if (shape)
                ReplayController.rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND);
            else
                ReplayController.rCanvasDrawShape.graphics.lineStyle(size, color);

            ReplayController.rCanvasDrawShape.graphics.drawPath(command, xydata);
            CanvasController.resetRCanvasDrawLayerCliprect2();
            setRCursorPos(xydata[xydata.length - 2], xydata[xydata.length - 1]);
        }

        public static function line3(data:Array):void
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
            ReplayController.rCanvasDrawLayer.alpha = alpha;
            checkSubLayer(subLayer);
            ReplayController.rAirBrushSize2 = airBrushSize;

            if (shape)
                ReplayController.rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND);
            else
                ReplayController.rCanvasDrawShape.graphics.lineStyle(size, color);
            ReplayController.rCanvasDrawShape.graphics.moveTo(startX, startY);
            ReplayController.rCanvasDrawShape.graphics.lineTo(endX, endY);
            CanvasController.resetRCanvasDrawLayerCliprect2();
            setRCursorPos(endX, endY);
        }

        public static function line2(data:Array):void
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
            ReplayController.rCanvasDrawLayer.alpha = alpha;
            checkSubLayer(subLayer);
            checkAirBrush(airBrush, size);

            if (shape)
                ReplayController.rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND);

            else
                ReplayController.rCanvasDrawShape.graphics.lineStyle(size, color);
            ReplayController.rCanvasDrawShape.graphics.moveTo(startX, startY);
            ReplayController.rCanvasDrawShape.graphics.lineTo(endX, endY);
            CanvasController.resetRCanvasDrawLayerCliprect();
            setRCursorPos(endX, endY);
        }

        public static function line1(data:Array):void
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
            ReplayController.rCanvasDrawLayer.alpha = alpha;
            checkSubLayer(subLayer);
            checkAirBrush(airBrush, size);

            if (shape)
                ReplayController.rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND);

            else
                ReplayController.rCanvasDrawShape.graphics.lineStyle(size, color);
            ReplayController.rCanvasDrawShape.graphics.moveTo(startX, startY);
            ReplayController.rCanvasDrawShape.graphics.lineTo(endX, endY);
            setRCursorPos(endX, endY);
        }

        public static function line(data:Array):void
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
            ReplayController.rCanvasDrawLayer.alpha = alpha;
            checkSubLayer(subLayer);
            checkAirBrush(airBrush, size);

            if (shape)
                ReplayController.rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.SQUARE, JointStyle.ROUND);

            else
                ReplayController.rCanvasDrawShape.graphics.lineStyle(size, color);
            ReplayController.rCanvasDrawShape.graphics.moveTo(startX, startY);
            ReplayController.rCanvasDrawShape.graphics.lineTo(endX, endY);
            setRCursorPos(endX, endY);
        }

        public static function move1(data:Array):void
        {
            ReplayController.moveImageReplayMode(data[1], data[2], true, false);
            setRCursorPosFromMoveTool(data[1], data[2]);
        }

        public static function move2(data:Array):void
        {
            ReplayController.moveImageReplayMode(data[1], data[2], false, true);
            setRCursorPosFromMoveTool(data[1], data[2]);
        }

        public static function move(data:Array):void
        {
            ReplayController.moveImageReplayMode(data[1], data[2], true, true);
            setRCursorPosFromMoveTool(data[1], data[2]);
        }

        public static function resetLassoVars():void
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

        public static function lasso2(data:Array, clearOnly:Boolean):void
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
                    ReplayController.rCanvasLayer1BitmapData.draw(LassoTool.lassoLayer1Bitmap, mat);
                    ReplayController.rCanvasLayer1Bitmap.bitmapData = ReplayController.rCanvasLayer1BitmapData;
                }

                if (data[6])
                {
                    ReplayController.rCanvasLayer2BitmapData.draw(LassoTool.lassoLayer2Bitmap, mat);
                    ReplayController.rCanvasLayer2Bitmap.bitmapData = ReplayController.rCanvasLayer2BitmapData;
                }
            }

            resetLassoVars();
        }

        public static function lasso(data:Array, clearOnly:Boolean):void
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
                    ReplayController.rCanvasLayer1BitmapData.draw(LassoTool.lassoLayer1Bitmap, mat);
                    ReplayController.rCanvasLayer1Bitmap.bitmapData = ReplayController.rCanvasLayer1BitmapData;
                }

                if (data[6])
                {
                    ReplayController.rCanvasLayer2BitmapData.draw(LassoTool.lassoLayer2Bitmap, mat);
                    ReplayController.rCanvasLayer2Bitmap.bitmapData = ReplayController.rCanvasLayer2BitmapData;
                }
            }

            resetLassoVars();
        }

        public static function mirror():void
        {
            ReplayController.mirrorCanvasReplayMode();
            setRCursorPosToCenter();
        }

        public static function bgColor(data:Array):void
        {
            const color:uint = data[1];
            ReplayController.rLastCanvasBGColor = color;
            ReplayController.updateCanvasBGColorReplayMode(color);
            setRCursorPosToCenter();
        }

        public static function canvasSize(data:Array):void
        {
            const width:Number = data[1];
            const height:Number = data[2];
            const moveX:Number = data[3];
            const moveY:Number = data[4];
            const movedFlag:Boolean = data[5];
            ReplayController.updateCanvasSizeReplayMode(width, height, moveX, moveY, movedFlag);
            setRCursorPos(width / 2, height / 2);
        }

        public static function tempDone4(data:Array):void
        {
            if (ReplayController.rAirBrushSize2 > 0)
            {
                const blurSize:Number = CanvasController.getBlurSize(ReplayController.rAirBrushSize2, 1.0);
                ReplayController.rCanvasDrawShape.filters = [new BlurFilter(blurSize, blurSize, 3)];
                ReplayController.rCanvasDrawLayerBitmapData.draw(ReplayController.rCanvasDrawShape);
                CanvasController.canvasDrawLayerChild.filters = [];
            }
            else
            {
                ReplayController.rCanvasDrawLayerBitmapData.draw(ReplayController.rCanvasDrawShape);
            }

            ReplayController.rCanvasDrawLayerBitmap.bitmapData = ReplayController.rCanvasDrawLayerBitmapData;
            ReplayController.updateRCanvasDrawLayerCliprect2();
            ReplayController.rCanvasDrawShape.graphics.clear();
        }

        public static function tempDone3(data:Array):void
        {
            ReplayController.rCanvasDrawLayerBitmapData.draw(ReplayController.rCanvasDrawShape);
            ReplayController.rCanvasDrawLayerBitmap.bitmapData = ReplayController.rCanvasDrawLayerBitmapData;
            ReplayController.updateRCanvasDrawLayerCliprect2();
            ReplayController.rCanvasDrawShape.graphics.clear();
        }

        public static function tempDone2(data:Array):void
        {
            if (ReplayController.rAirBrushSize > 0 && ReplayController.rCanvasZoomMultiplier !== 1.0)
            {
                ReplayController.blurReplayCanvasByDefaultValue();
                ReplayController.rCanvasDrawLayerBitmapData.draw(ReplayController.rCanvasDrawShape);
                ReplayController.rCanvasDrawLayerBitmap.bitmapData = ReplayController.rCanvasDrawLayerBitmapData;
                CanvasController.updateRCanvasDrawLayerCliprect();
                ReplayController.rCanvasDrawShape.graphics.clear();
                ReplayController.blurReplayCanvasByValue(ReplayController.rAirBrushSize);
            }
            else
            {
                ReplayController.rCanvasDrawLayerBitmapData.draw(ReplayController.rCanvasDrawShape);
                ReplayController.rCanvasDrawLayerBitmap.bitmapData = ReplayController.rCanvasDrawLayerBitmapData;
                CanvasController.updateRCanvasDrawLayerCliprect();
                ReplayController.rCanvasDrawShape.graphics.clear();
            }
        }

        public static function tempDone(data:Array):void
        {
            if (ReplayController.rAirBrushSize > 0 && ReplayController.rCanvasZoomMultiplier !== 1.0)
            {
                ReplayController.blurReplayCanvasByDefaultValue();
                ReplayController.rCanvasDrawLayerBitmapData.draw(ReplayController.rCanvasDrawShape);
                ReplayController.rCanvasDrawLayerBitmap.bitmapData = ReplayController.rCanvasDrawLayerBitmapData;
                ReplayController.rCanvasDrawShape.graphics.clear();
                ReplayController.blurReplayCanvasByValue(ReplayController.rAirBrushSize);
            }
            else
            {
                ReplayController.rCanvasDrawLayerBitmapData.draw(ReplayController.rCanvasDrawShape);
                ReplayController.rCanvasDrawLayerBitmap.bitmapData = ReplayController.rCanvasDrawLayerBitmapData;
                ReplayController.rCanvasDrawShape.graphics.clear();
            }
        }

        public static function drawDone5(data:Array):void
        {
            const lineStyleData:Array = getrLineStyleSave();
            const subLayer:Boolean = data[1];
            const canvasAlpha:ColorTransform = new ColorTransform(1, 1, 1, lineStyleData[0]);

            if (ReplayController.rAirBrushSize2 > 0)
            {
                const blurSize:Number = CanvasController.getBlurSize(ReplayController.rAirBrushSize2, 1.0);
                ReplayController.rCanvasDrawShape.filters = [new BlurFilter(blurSize, blurSize, 3)];
                ReplayController.rCanvasDrawLayerBitmapData.draw(ReplayController.rCanvasDrawShape);
                ReplayController.rCanvasDrawShape.filters = [];
            }
            else
            {
                ReplayController.rCanvasDrawLayerBitmapData.draw(ReplayController.rCanvasDrawShape);
            }

            ReplayController.rCanvasDrawLayerBitmap.bitmapData = ReplayController.rCanvasDrawLayerBitmapData;
            ReplayController.updateRCanvasDrawLayerCliprect2();
            CanvasController.extandRCanvasDrawLayerCliprect2();

            if (subLayer)
            {
                ReplayController.rCanvasLayer2BitmapData.draw(ReplayController.rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], ReplayController.rCanvasDrawLayerClipRect);
                ReplayController.rCanvasLayer2Bitmap.bitmapData = ReplayController.rCanvasLayer2BitmapData;
            }
            else
            {
                ReplayController.rCanvasLayer1BitmapData.draw(ReplayController.rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], ReplayController.rCanvasDrawLayerClipRect);
                ReplayController.rCanvasLayer1Bitmap.bitmapData = ReplayController.rCanvasLayer1BitmapData;
            }

            ReplayController.rCanvasDrawLayerBitmapData.fillRect(ReplayController.rCanvasDrawLayerClipRect, 0);
            ReplayController.rCanvasDrawShape.graphics.clear();
        }

        public static function drawDone4(data:Array):void
        {
            const lineStyleData:Array = getrLineStyleSave();
            const subLayer:Boolean = data[1];
            const canvasAlpha:ColorTransform = new ColorTransform(1, 1, 1, lineStyleData[0]);
            ReplayController.rCanvasDrawLayerBitmapData.draw(ReplayController.rCanvasDrawShape);
            ReplayController.rCanvasDrawLayerBitmap.bitmapData = ReplayController.rCanvasDrawLayerBitmapData;
            ReplayController.updateRCanvasDrawLayerCliprect2();
            CanvasController.extandRCanvasDrawLayerCliprect2();

            if (ReplayController.rAirBrushSize2 > 0)
            {
                const blurSize:Number = CanvasController.getBlurSize(ReplayController.rAirBrushSize2, 1.0);
                ReplayController.rCanvasDrawLayerBitmapData.applyFilter(ReplayController.rCanvasDrawLayerBitmapData, ReplayController.rCanvasDrawLayerClipRect, new Point(ReplayController.rCanvasDrawLayerClipRect.x, ReplayController.rCanvasDrawLayerClipRect.y), new BlurFilter(blurSize, blurSize, 3));
                ReplayController.rCanvasDrawLayerBitmap.bitmapData = ReplayController.rCanvasDrawLayerBitmapData;
            }

            if (subLayer)
            {
                ReplayController.rCanvasLayer2BitmapData.draw(ReplayController.rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], ReplayController.rCanvasDrawLayerClipRect);
                ReplayController.rCanvasLayer2Bitmap.bitmapData = ReplayController.rCanvasLayer2BitmapData;
            }
            else
            {
                ReplayController.rCanvasLayer1BitmapData.draw(ReplayController.rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], ReplayController.rCanvasDrawLayerClipRect);
                ReplayController.rCanvasLayer1Bitmap.bitmapData = ReplayController.rCanvasLayer1BitmapData;
            }

            ReplayController.rCanvasDrawLayerBitmapData.fillRect(ReplayController.rCanvasDrawLayerClipRect, 0);
            ReplayController.rCanvasDrawShape.graphics.clear();
        }

        public static function drawDone3(data:Array):void
        {
            const lineStyleData:Array = getrLineStyleSave();
            const subLayer:Boolean = data[1];
            const canvasAlpha:ColorTransform = new ColorTransform(1, 1, 1, lineStyleData[0]);

            if (ReplayController.rAirBrushSize > 0 && ReplayController.rCanvasZoomMultiplier !== 1.0)
            {
                ReplayController.blurReplayCanvasByDefaultValue();
                ReplayController.rCanvasDrawLayerBitmapData.draw(ReplayController.rCanvasDrawShape);
                ReplayController.rCanvasDrawLayerBitmap.bitmapData = ReplayController.rCanvasDrawLayerBitmapData;
                ReplayController.blurReplayCanvasByValue(ReplayController.rAirBrushSize);
            }
            else
            {
                ReplayController.rCanvasDrawLayerBitmapData.draw(ReplayController.rCanvasDrawShape);
                ReplayController.rCanvasDrawLayerBitmap.bitmapData = ReplayController.rCanvasDrawLayerBitmapData;
            }

            CanvasController.updateRCanvasDrawLayerCliprect();
            CanvasController.extandRCanvasDrawLayerCliprect();

            if (subLayer)
            {
                ReplayController.rCanvasLayer2BitmapData.draw(ReplayController.rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], ReplayController.rCanvasDrawLayerClipRectLegacy);
                ReplayController.rCanvasLayer2Bitmap.bitmapData = ReplayController.rCanvasLayer2BitmapData;
            }
            else
            {
                ReplayController.rCanvasLayer1BitmapData.draw(ReplayController.rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], ReplayController.rCanvasDrawLayerClipRectLegacy);
                ReplayController.rCanvasLayer1Bitmap.bitmapData = ReplayController.rCanvasLayer1BitmapData;
            }

            ReplayController.rCanvasDrawLayerBitmapData.fillRect(ReplayController.rCanvasDrawLayerClipRectLegacy, 0);
            ReplayController.rCanvasDrawShape.graphics.clear();

            if (ReplayController.rAirBrushSize > 0)
            {
                ReplayController.resetBlurReplayCanvas();
            }
        }

        public static function drawDone2(data:Array):void
        {
            const lineStyleData:Array = getrLineStyleSave();
            const subLayer:Boolean = data[1];
            const canvasAlpha:ColorTransform = new ColorTransform(1, 1, 1, lineStyleData[0]);

            if (ReplayController.rAirBrushSize > 0 && ReplayController.rCanvasZoomMultiplier !== 1.0)
            {
                ReplayController.blurReplayCanvasByDefaultValue();
                ReplayController.rCanvasDrawLayerBitmapData.draw(ReplayController.rCanvasDrawShape);
                ReplayController.rCanvasDrawLayerBitmap.bitmapData = ReplayController.rCanvasDrawLayerBitmapData;
                ReplayController.blurReplayCanvasByValue(ReplayController.rAirBrushSize);
            }
            else
            {
                ReplayController.rCanvasDrawLayerBitmapData.draw(ReplayController.rCanvasDrawShape);
                ReplayController.rCanvasDrawLayerBitmap.bitmapData = ReplayController.rCanvasDrawLayerBitmapData;
            }

            if (subLayer)
            {
                ReplayController.rCanvasLayer2BitmapData.draw(ReplayController.rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1]);
                ReplayController.rCanvasLayer2Bitmap.bitmapData = ReplayController.rCanvasLayer2BitmapData;
            }
            else
            {
                ReplayController.rCanvasLayer1BitmapData.draw(ReplayController.rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1]);
                ReplayController.rCanvasLayer1Bitmap.bitmapData = ReplayController.rCanvasLayer1BitmapData;
            }

            ReplayController.rCanvasDrawLayerBitmapData.fillRect(new Rectangle(0, 0, ReplayController.rCanvasLayer1BitmapData.width, ReplayController.rCanvasLayer1BitmapData.height), 0);
            ReplayController.rCanvasDrawShape.graphics.clear();

            if (ReplayController.rAirBrushSize > 0)
            {
                ReplayController.resetBlurReplayCanvas();
            }
        }

        public static function drawDone(data:Array):void
        {
            const lineStyleData:Array = getrLineStyleSave();
            // if(!lineStyleData) return;
            const subLayer:Boolean = data[1];
            const canvasAlpha:ColorTransform = new ColorTransform(1, 1, 1, lineStyleData[0]);

            if (ReplayController.rAirBrushSize > 0 && ReplayController.rCanvasZoomMultiplier !== 1.0)
            {
                ReplayController.blurReplayCanvasByDefaultValue();
                ReplayController.rCanvasDrawLayerBitmapData.draw(ReplayController.rCanvasDrawShape);
                ReplayController.rCanvasDrawLayerBitmap.bitmapData = ReplayController.rCanvasDrawLayerBitmapData;
                ReplayController.blurReplayCanvasByValue(ReplayController.rAirBrushSize);
            }
            else
            {
                ReplayController.rCanvasDrawLayerBitmapData.draw(ReplayController.rCanvasDrawShape);
                ReplayController.rCanvasDrawLayerBitmap.bitmapData = ReplayController.rCanvasDrawLayerBitmapData;
            }

            if (subLayer)
            {
                var tmpbmpd:BitmapData = new BitmapData(ReplayController.RCANVAS_WIDTH, ReplayController.RCANVAS_HEIGHT, true, 0);
                tmpbmpd.draw(ReplayController.rCanvasDrawLayerBitmap, null, canvasAlpha);
                tmpbmpd.draw(ReplayController.rCanvasLayer1Bitmap);
                ReplayController.rCanvasLayer1BitmapData = CanvasController.updateBitmapData(ReplayController.rCanvasLayer1BitmapData, tmpbmpd, ReplayController.rCanvasLayer1Bitmap);
                tmpbmpd.dispose();
                tmpbmpd = null;
            }
            else
            {
                ReplayController.rCanvasLayer1BitmapData.draw(ReplayController.rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1]);
                ReplayController.rCanvasLayer1Bitmap.bitmapData = ReplayController.rCanvasLayer1BitmapData;
            }

            ReplayController.rCanvasDrawLayerBitmap.bitmapData = null;
            ReplayController.rCanvasDrawLayerBitmapData.fillRect(new Rectangle(0, 0, ReplayController.rCanvasDrawLayerBitmapData.width, ReplayController.rCanvasDrawLayerBitmapData.height), 0);
            ReplayController.rCanvasDrawShape.graphics.clear();

            if (ReplayController.rAirBrushSize > 0)
            {
                ReplayController.resetBlurReplayCanvas();
            }
        }

        public static function clear(layer1:Boolean, layer2:Boolean):void
        {
            if (!layer1 && !layer2)
            {
                layer1 = true;
                layer2 = true;
            }

            const rect:Rectangle = new Rectangle(0, 0, ReplayController.rCanvasLayer1BitmapData.width, ReplayController.rCanvasLayer1BitmapData.height);

            if (layer1)
                ReplayController.rCanvasLayer1BitmapData.fillRect(rect, 0);

            if (layer2)
                ReplayController.rCanvasLayer2BitmapData.fillRect(rect, 0);
            setRCursorPosToCenter();
        }

        public static function swapLayer():void
        {
            var tempbmpd1:BitmapData = ReplayController.rCanvasLayer1BitmapData.clone();
            var tempbmpd11:BitmapData = ReplayController.rCanvasLayer2BitmapData.clone();
            const rect:Rectangle = new Rectangle(0, 0, ReplayController.rCanvasLayer1BitmapData.width, ReplayController.rCanvasLayer1BitmapData.height);
            ReplayController.rCanvasLayer1BitmapData.fillRect(rect, 0);
            ReplayController.rCanvasLayer2BitmapData.fillRect(rect, 0);
            ReplayController.rCanvasLayer1BitmapData.draw(tempbmpd11);
            ReplayController.rCanvasLayer2BitmapData.draw(tempbmpd1);
            tempbmpd1.dispose();
            tempbmpd11.dispose();
            tempbmpd1 = null;
            tempbmpd11 = null;
            setRCursorPosToCenter();
        }

        public static function mergeLayer():void
        {
            ReplayController.rCanvasLayer2BitmapData.draw(ReplayController.rCanvasLayer1BitmapData);
            ReplayController.rCanvasLayer1BitmapData.fillRect(new Rectangle(0, 0, ReplayController.rCanvasLayer1BitmapData.width, ReplayController.rCanvasLayer1BitmapData.height), 0);
            setRCursorPosToCenter();
        }

        public static function drawNext():void
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
                case "line4":
                    line4(d);
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
    }
}
