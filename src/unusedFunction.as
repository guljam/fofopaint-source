package
{
    import flash.display.Sprite;

    public function unusedFunction():void
    {
    }
}
/*
package
{
    import flash.display.Sprite;

    public function unusedFunction():void
    {
         private function floodFill(x:Number, y:Number,color:uint,alpha:Number):void
        {
            const floor:Function = Math.floor;
            const alpha32:uint = floor(alpha*255) << 24;
            const alphaColor:uint =  alpha32 | color;
            const limit:Number = 200;
            var limitX1:Number = x-limit;
            var limitX2:Number = x+limit;
            var limitY1:Number = y-limit;
            var limitY2:Number = y+limit;
            var minX:Number;
            var maxX:Number;

            if(limitX1 <= 0) limitX1 = 0;
            if(limitX2 >= CANVAS_WIDTH) limitX2 = CANVAS_WIDTH;
            if(limitY1 <= 0) limitY1 = 0;
            if(limitY2 >= CANVAS_HEIGHT) limitY2 = CANVAS_HEIGHT;

            x = floor(x);
            y = floor(y);

            const firstColor:uint = canvas1BitmapData.getPixel32(x,y);
            // const bmpd:BitmapData = new BitmapData(canvas1BitmapData.width,canvas1BitmapData.height,true,0);

            // function rgba(r:uint, g:uint, b:uint):Array {
            //     const floor:Function = Math.floor;
            //     const minColor:uint = Math.min(r, g, b);
            //     var a:Number = (255-minColor)/255;
            //     return [floor((r - minColor) / a),
            //             floor((g - minColor) / a),
            //             floor((b - minColor) / a),
            //             a];
            // }

            function test(x:Number,y:Number):Boolean
            {
                const getColor:uint = canvas1BitmapData.getPixel32(x,y);
                if(firstColor !== getColor)
                {
                    const getAlpha:Number = ((getColor & 0xFF000000)>>>24)/255;
                    var a2:uint = (getColor & 0xFF000000) >> 24;
                    // var r2:uint = (getColor & 0x00FF0000) >> 16;
                    // var g2:uint = (getColor & 0x0000FF00) >> 8;
                    // var b2:uint = (getColor & 0x000000FF);
                    // const r1:uint = (color & 0xFF0000) >> 16;
                    // const g1:uint = (color & 0x00FF00) >> 8;
                    // const b1:uint = (color & 0x0000FF);
                    
                    // //desination over R = S*(1 - Da) + D;
                    // var r:uint = (r1*(1-getAlpha)+r2)<<16;
                    // var g:uint = (g1*(1-getAlpha)+g2)<<8;
                    // var b:uint = (b1*(1-getAlpha)+b2);
                    // var a:Number = alpha*(1-getAlpha)+getAlpha;
                    // var a32:uint = (a*255) << 24;

                    // if(a === 1.0)
                    // {
                    //     const n:Array = rgba(r,g,b);

                    //     r = n[0];
                    //     g = n[1];
                    //     b = n[2];
                    //     a = (n[3]*255) << 24;
                    //     bmpd.setPixel32(x,y,a32|r|g|b);
                    // }
                    // else
                    // {
                    //     bmpd.setPixel32(x,y,a32|r|g|b);
                    // }

                    // bmpd.setPixel32(x,y,a32|r|g|b);
                   canvas1BitmapData.setPixel32(x,y,alphaColor);
                }
                return firstColor === getColor;
            }

            function paint(x:Number,y:Number):void
            {
                canvas1BitmapData.setPixel32(x,y,alphaColor);
            }

            // xMin, xMax, y, down[true] / up[false], extendLeft, extendRight
            var ranges:Array = [[x, x, y, null, true, true]];
            paint(x, y);

            function addNextLine(newY:Number, isNext:Boolean, downwards:Boolean):void
            {
                var rMinX:Number = minX;
                var inRange:Boolean = false;

                for(var x:Number=minX; x<=maxX; x++)
                {
                    // jump testing, if testing previous line within previous range
                    var empty:Boolean = (isNext || (x<r[0] || x>r[1])) && test(x, newY);
                    if(!inRange && empty)
                    {
                        rMinX = x;
                        inRange = true;
                    }
                    else if(inRange && !empty)
                    {
                        ranges.push([rMinX, x-1, newY, downwards, rMinX==minX, false]);
                        inRange = false;
                    }
                    if(inRange)
                    {
                        paint(x, newY);
                    }
                    // jump
                    if(!isNext && x==r[0])
                    {
                        x = r[1];
                    }
                }

                if(inRange)
                {
                    ranges.push([rMinX, x-1, newY, downwards, rMinX==minX, true]);
                }
            }

            while(ranges.length)
            {
                var r:Array = ranges.pop();
                var down:Boolean = r[3] === true;
                var up:Boolean =   r[3] === false;
                minX = r[0];
                // extendLeft
                var _y:Number = r[2];
                if(r[4])
                {
                    while(minX > limitX1 && test(minX-1, _y))
                    {
                        minX--;
                        paint(minX, _y);
                    }
                }
                maxX = r[1];
                // extendRight
                if(r[5])
                {
                    while(maxX<limitX2 && test(maxX+1, _y))
                    {
                        maxX++;
                        paint(maxX, _y);
                    }
                }
                r[0]--;
                r[1]++;

                trace('_y',_y);

                if(_y < limitY2) addNextLine(_y+1, !up, true);
                if(_y > limitY1) addNextLine(_y-1, !down, false);
            }
            // bmpd.draw(canvas1BitmapData);
            // canvas1BitmapData = bmpd.clone();
            canvas1Bitmap.bitmapData = canvas1BitmapData;
            // bmpd.dispose();
        }

private function getRandomString(count:uint):String
{
    const chars:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    const charsLen:uint = chars.length;
    var randomString:String = "";
    for(var i:uint=0;i<count;i++)
    {
        const index:uint = Math.floor(charsLen*Math.random());
        const ss:String = chars.charAt(index);
        randomString += ss;
    }

    return randomString;
}

function floodFillScanline(x, y, width, height, diagonal, test, paint) {
    // xMin, xMax, y, down[true] / up[false], extendLeft, extendRight
    var ranges = [[x, x, y, null, true, true]];
    paint(x, y);

    while(ranges.length) {
        var r = ranges.pop();
        var down = r[3] === true;
        var up =   r[3] === false;

        // extendLeft
        var minX = r[0];
        var y = r[2];
        if(r[4]) {
            while(minX>0 && test(minX-1, y)) {
                minX--;
                paint(minX, y);
            }
        }
        var maxX = r[1];
        // extendRight
        if(r[5]) {
            while(maxX<width-1 && test(maxX+1, y)) {
                maxX++;
                paint(maxX, y);
            }
        }

        if(diagonal) {
            // extend range looked at for next lines
            if(minX>0) minX--;
            if(maxX<width-1) maxX++;
        }
        else {
            // extend range ignored from previous line
            r[0]--;
            r[1]++;
        }

        function addNextLine(newY, isNext, downwards) {
            var rMinX = minX;
            var inRange = false;
            for(var x=minX; x<=maxX; x++) {
                // jump testing, if testing previous line within previous range
                var empty = (isNext || (x<r[0] || x>r[1])) && test(x, newY);
                if(!inRange && empty) {
                    rMinX = x;
                    inRange = true;
                }
                else if(inRange && !empty) {
                    ranges.push([rMinX, x-1, newY, downwards, rMinX==minX, false]);
                    inRange = false;
                }
                if(inRange) {
                    paint(x, newY);
                }
                // jump
                if(!isNext && x==r[0]) {
                    x = r[1];
                }
            }
            if(inRange) {
                ranges.push([rMinX, x-1, newY, downwards, rMinX==minX, true]);
            }
        }

        if(y<height)
            addNextLine(y+1, !up, true);
        if(y>0)
            addNextLine(y-1, !down, false);
    }
}


private var printdeepLevel:int = 0;
private function printa(obj:Object,deepKey:String=""):void
{
    var blank:String="";
    if(printdeepLevel === 0) trace('--- PRINT START --- ');
    else
    {
        const count:int = printdeepLevel;
        for(var b:int = 0; b < count;b++)
        {
            blank += "   ";
        }
        trace(blank+'--> ['+deepKey+']');
    }

    for(var i:String in obj)
    {
        if(obj[i] !== null && typeof obj[i] === "object" && obj[i].length > 0)
        {
            ++printdeepLevel;
            printa(obj[i],i);
        }
        else
        {
            trace(blank+'|'+i + ' : ' + obj[i]);
        }
    }
    --printdeepLevel;
}

import flash.ui.MouseCursorData;
        import flash.ui.Mouse;    
        private function mouseHelperON():void
        {
            
            function mouseHelperMove(e:MouseEvent):void
            {
                const stw:Number = stage.stageHeight;
                const sth:Number = stage.stageHeight;
                var mx:Number = mouseX;
                var my:Number = mouseY;
                const right:Number = mx+mouseGuide.width-100;
                const bottom:Number = my+mouseGuide.height-70;

                if(right > stw)
                {
                    mx -= mouseGuide.width+30;
                }
                if(bottom > sth)
                {
                    my -= mouseGuide.height+30;
                }

                mouseGuide.x = mx;
                mouseGuide.y = my;
            }
            stage.addChild(mouseGuide);
            stage.addEventListener(MouseEvent.MOUSE_MOVE,mouseHelperMove);
            stage.addEventListener(MouseEvent.MOUSE_UP,mouseGuide.mouseUpHandler);
			stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseGuide.mouseDownHandler);
			stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,mouseGuide.mouseRightDownHandler);
			stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,mouseGuide.mouseRightUpHandler);
        }

        public function changeCursor():void 
        {
            initCustomCursor();
            const _customCursorData:Array = customCursorData[0];
            const mouseCursorData:MouseCursorData = new MouseCursorData();
            const cursorName:String = _customCursorData[0];
            const cursorBmpd:Vector.<BitmapData> = _customCursorData[1];
            const cursorSpotData:Array = _customCursorData[2];
            const cursorSpot:Point = new Point(cursorSpotData[0],cursorSpotData[1]);

            trace('cursorSpot',cursorSpot,"cursorName",cursorName,"cursorBmpd",cursorBmpd.length);

            mouseCursorData.data = cursorBmpd;
            mouseCursorData.frameRate = 1;
            mouseCursorData.hotSpot = cursorSpot;
            
            Mouse.registerCursor(cursorName,mouseCursorData);
            Mouse.cursor = cursorName;
            trace('call change cursor',_customCursorData);
        }

        private function initCustomCursor():void
        {
            trace('call make natvie cursor');
            var cursorBmpd:BitmapData = new BitmapData(32,32,true,0);
            const blackColor:uint = 0xFF000000;
            const whiteColor:uint = 0xFFFFFFFF;
            const maincolorXY:Array = [[1,8],[1,9],[2,8],[2,9],[3,8],[3,9] //up
                                      ,[8,1],[8,2],[8,3],[9,1],[9,2],[9,3]//left
                                      ,[8,14],[8,15],[8,16],[9,14],[9,15],[9,16]//right
                                      ,[14,8],[14,9],[15,8],[15,9],[16,8],[16,9]//bottom
                                      ,[9,9]]; //center
            const len:uint = maincolorXY.length-1;
            var i:int=len;
            while(i>=0)
            {
                trace('cord = ',maincolorXY[i][0],maincolorXY[i][1]);
                cursorBmpd.setPixel32(maincolorXY[i][0],maincolorXY[i][1],blackColor);
                i--;
            }

            customCursorData[0][1].push(cursorBmpd);

            cursorBmpd = new BitmapData(32,32,true,0);
            i=len;
            while(i>=0)
            {
                cursorBmpd.setPixel32(maincolorXY[i][0],maincolorXY[i][1],whiteColor);
                i--;
            }
            customCursorData[1][1].push(cursorBmpd);

            cursorBmpd = new BitmapData(1,1,true,0);
            cursorBmpd.setPixel32(0,0,blackColor);
            customCursorData[2][1].push(cursorBmpd);

            cursorBmpd = new BitmapData(1,1,true,0);
            cursorBmpd.setPixel32(0,0,whiteColor);
            customCursorData[3][1].push(cursorBmpd);
        }
        private function floodFillScanline(x:int, y:int,newColor:uint,alpha:Number):void
        {
            const bmpd:BitmapData = canvas1BitmapData;
            const baseColor:uint = bmpd.getPixel32(x,y);
            const newColor32:uint = (((alpha*255)<<24)|newColor);

            trace('콜함');
            if(baseColor === newColor32)
            {
                return;
            }

            const time1:int = getTimer();
            const width:int = CANVAS_WIDTH;
            const height:int = CANVAS_HEIGHT;
            const tmpBmpd:BitmapData = new BitmapData(width,height,true,0);
            const edges:Array = [];
            
            // xMin, xMax, y, down[true] / up[false], extendLeft, extendRight
            var ranges:Array = [[x, x, y, null, true, true]];

            function findEdge(arr:Array):void
            {
                var len:int = edges.length;
                for(var i:int = 0; i < len; i+=2)
                {
                    canvas1BitmapData.setPixel32(arr[i][0],arr[i][1],0xFF0000FF);   
                }
                canvas1Bitmap.bitmapData = canvas1BitmapData;
            }

            function test(x:int,y:int):Boolean
            {
                const getColor:uint = bmpd.getPixel32(x,y);

                if(getColor === baseColor)
                {
                    return true;
                }
                const alpint:uint = ((getColor >>> 24)*0.25) << 24;
                const colorint:uint = (getColor & 0x00FFFFFF);
                const convColor:uint = alpint|colorint;
                trace('alpint',alpint,"colorint",colorint,"convColor",convColor);
                bmpd.setPixel32(x,y,convColor);
                
                // trace('halfAlpha|newColor',halfAlpha|newColor);
                tmpBmpd.setPixel32(x,y,newColor32);
                // // const alpha:uint = (getColor >>> 24)
                // const getColor2:uint = tmpBmpd.getPixel32(x,y);

                // if(getColor !== newColor32 && getColor2 === 0)
                // {
                //     tmpBmpd.setPixel32(x,y,newColor32);
                //     edges.push([x,y]);
                // }
                return false;
            }

            function paint(x:int,y:int):void
            {
                bmpd.setPixel32(x,y,newColor32);
            }

            bmpd.lock();
            tmpBmpd.lock();
            paint(x, y);

            const rSize:int = 150; //실제 사이즈는 x2해야함
            var xMinLimit:int = (x-rSize < 0) ? 0:x-rSize;
            var xMaxLimit:int = (x+rSize > width-1) ? width-1:x+rSize;
            var yMinLimit:int = (y-rSize < 0) ? 0:y-rSize;
            var yMaxLimit:int = (y+rSize > height-1) ? height-1:y+rSize;

            // trace('xMinLimit',xMinLimit,"xMaxLimit",xMaxLimit,"yMinLimit",yMinLimit,"yMaxLimit",yMaxLimit);

            while(ranges.length)
            {
                var r:Array = ranges.pop();
                var down:Boolean = r[3] === true;
                var up:Boolean =   r[3] === false;

                // extendLeft
                var minX:int = r[0];
                y = r[2];
                if(r[4])
                {
                    // while(minX>0 && test(minX-1, y))
                    while(minX > xMinLimit && test(minX-1, y))
                    {
                        minX--;
                        paint(minX, y);
                    }
                }
                var maxX:int = r[1];
                // extendRight
                if(r[5])
                {
                    // while(maxX<width-1 && test(maxX+1, y))
                    while(maxX<xMaxLimit && test(maxX+1, y))
                    {
                        maxX++;
                        paint(maxX, y);
                    }
                }

                // extend range ignored from previous line
                r[0]--;
                r[1]++;
            
                function addNextLine(newY:int, isNext:Boolean, downwards:Boolean):void
                {
                    var rMinX:int = minX;
                    var inRange:Boolean = false;
                    for(var x:int=minX; x<=maxX; x++)
                    {
                        // jump testing, if testing previous line within previous range
                        var empty:Boolean = (isNext || (x<r[0] || x>r[1])) && test(x, newY);

                        if(!inRange && empty) {
                            rMinX = x;
                            inRange = true;
                        }
                        else if(inRange && !empty) {
                            ranges.push([rMinX, x-1, newY, downwards, rMinX==minX, false]);
                            inRange = false;
                        }
                        if(inRange) {
                            paint(x, newY);
                        }
                        // jump
                        if(!isNext && x==r[0]) {
                            x = r[1];
                        }
                    }
                    if(inRange)
                    {
                        ranges.push([rMinX, x-1, newY, downwards, rMinX==minX, true]);
                    }
                }

                // if(y<height-1)
                if(y<yMaxLimit)
                    addNextLine(y+1, !up, true);
                // if(y>0)
                if(y>yMinLimit)
                    addNextLine(y-1, !down, false);
            }
            
            tmpBmpd.draw(bmpd,null,null,"multiply");
            canvas1BitmapData = tmpBmpd.clone();
            canvas1Bitmap.bitmapData = canvas1BitmapData;
            tmpBmpd.dispose();
            addUndo();
            trace('걸린 시간 : ',getTimer()-time1,"ms");
        }



private function setPenTool(penToolFlag:Boolean):void
{
    var xSize:uint;
    var xColor:uint;
    var xAlpha:Number;
    var xShape:Boolean;
    var xBlendMode:String;
    var fillPenON:Boolean = fillPenON;
    var _airBrushON:Boolean;

    if(penToolFlag)
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
        fillPenON = false;
        xSize = eraseSize;
        xColor = CANVAS_BG_COLOR;
        xAlpha = eraseAlpha;
        xShape = eraseShape;
        xBlendMode = "erase";
        _airBrushON = eraseAirBrushON;
    }

    const cd:Shape = canvas2Draw;
    // const mouseMoveCountLimit:uint = 800; //zoom에 따라서 100카운터 선 길이가 차이나서 비례해서 해줌
    const floor:Function = Math.floor; 
    const cdg:Graphics = cd.graphics;
    const _pixelSnap:Boolean = pixelSnapON;
    const rotateFlag:Boolean = (regPoint.rotation % 90 === 0) ? false : true;
    const _traceVisibleFlag:Boolean = traceVisibleFlag;
    var xOffset:Number = (sizeOffsetFlag) ? 0.5 : 0;

    if(fillPenON)
    {
        _airBrushON = false;
        xOffset = (_pixelSnap) ? 0.5 : 0;
        xSize = 1;
        var fillPenCommand:Vector.<int> = new Vector.<int>(); //필펜 커맨드
        var fillPenPoints:Vector.<Number> = new Vector.<Number>(); //필펜 좌표
        var fillPenFirstBorderColor:uint;
    }

    const _penSmoothValue:Number = penSmoothValue;//펜 스무딩 플래그
    const _penSmoothSlideValue:int = penSmoothSlideValue;

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
    var distLimit:Number = xSize/10;//penmove에서 distlimit이하이면 jump해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌
    var shortDistFlag:Boolean = false; //확대 많이 하고 살짝 움직였을때 penmove에서 아예 처리를 안하는데 이걸 dot으로 처리하게 해줌
    const subLayerFlag:Boolean = (penToolFlag) ? subLayerON : false;

    var sqPenCursorLastX:Number = cx;
    var sqPenCursorLastY:Number = cy;
    
    if(penToolFlag && _traceVisibleFlag)
    {
        canvasTrace.visible = false;
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
                rDataBuffer.push(["lineStyle",xShape,xSize,xColor,xAlpha,cx,cy,xBlendMode,false,subLayerFlag,_airBrushON]); //cx cy 처음 클릭한 지점으로 지정해줘야함
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
                rDataBuffer.push(["lineStyle",xShape,xSize,xColor,xAlpha,x,y,xBlendMode,false,subLayerFlag,_airBrushON]);
            }
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

        if(xShape === true)
        {
            penSizeCursor.rotation = regPoint.rotation;
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

        drawDone((fillPenON) ? 2 :(penToolFlag) ? 0 : 1);

        stage.removeEventListener(MouseEvent.MOUSE_UP, penToolUpEvent);
        stage.removeEventListener(MouseEvent.MOUSE_MOVE, penToolMoveEvent);
    }

    checkUndoReady();
    stage.addEventListener(MouseEvent.MOUSE_MOVE,penToolMoveEvent);
    stage.addEventListener(MouseEvent.MOUSE_UP,penToolUpEvent);
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
            var _airBrushON:Boolean = airBrushON;

            mouseDragON = true;

            if(!lineFlag)
            {
                xSize = eraseSize;
                xColor = CANVAS_BG_COLOR;
                xAlpha = eraseAlpha;
                xShape = eraseShape;
                xBlendMode = "erase";
                _airBrushON = eraseAirBrushON;
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
                if(deg > 180)
                {
                    deg = deg-90;
                }

                var degstr:String = abs(deg%90).toFixed(1)+"°";
                setToolTipON(degstr);
                toolTipBox.visible = true;

                const rad:Number = Math.atan2(oldX+xOffset-mx,oldY+xOffset-my);
                const cursorDeg:Number = -rad*(180/Math.PI)+regPoint.rotation;
                penSizeCursor.rotation = cursorDeg;
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


private function setLassoTool():void
        {
            //이미 켜져 있으면 리턴
            if(lassoToolON === true) return;
            const canvas2FilterBackUp:Array = canvas2Draw.filters.concat();
            canvas2Draw.filters = [];

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


         private function CRotateTool(replayMode:Boolean = false):void
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

            setToolTipON(strZoom);
            toolTipBox.visible = true;

            stage.addEventListener(MouseEvent.MOUSE_MOVE,zoomToolMoveEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP,zoomToolUpEvent);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP,zoomToolUpEvent);
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
                    setClearButtonActive();
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

                    if(d[10] === true)
                    {
                        setBlurCanvasBySize(size,true);
                    }
                    else if(rcanvas2Draw.filters.length > 0)
                    {
                        rcanvas2Draw.filters = [];
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

                    trace(rFrameSum,' [ x y =',x,y)

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
                    blendMode = d[3] as String;

                    rcanvas2Draw.filters = [];

                    rLineStyleSave = [alpha,blendMode];
                    rcanvas2.alpha = alpha;
                    cd2.clear();
                    cd2.lineStyle(1,color);
                    cd2.beginFill(color);
                    cd2.drawPath(d[4] as Vector.<int>,d[5] as Vector.<Number>);

                    if(lastFlag) rTinyCursorPos = [d[5][0] as Number,d[5][1] as Number];
                }
               break;

                case "fill2":
                {
                    color = d[1] as uint;
                    alpha = d[2] as Number;
                    blendMode = d[3] as String;

                    rcanvas2Draw.filters = [];

                    rLineStyleSave = [alpha,blendMode];
                    rcanvas2.alpha = alpha;
                    cd2.clear();
                    cd2.lineStyle(1,color);
                    cd2.beginFill(color);

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

                    if(d[9] === true)
                    {
                        setBlurCanvasBySize(size,true);
                    }
                    else if(rcanvas2Draw.filters.length > 0)
                    {
                        rcanvas2Draw.filters = [];
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

                    if(d[11] === true)
                    {
                        setBlurCanvasBySize(size,true);
                    }
                    else if(rcanvas2Draw.filters.length > 0)
                    {
                        rcanvas2Draw.filters = [];
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
            const padding:Number = 5;

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

            if(right-left > stW)
            {
                if(cursorX < padding)
                {
                    _rregPoint.x += floor(abs((cursorX-stW/2)/5));
                    updateReplayCanvasBounds(); 
                }
                else if(cursorX > stW-padding)
                {
                    _rregPoint.x -= floor(abs((cursorX-stW/2)/5));
                    updateReplayCanvasBounds();
                }
            }

            trace('bottom-top < stH',bottom-top, 'stH',stH);

            if(bottom-top > stH)
            {
                if(cursorY < padding+offsetY)
                {
                    _rregPoint.y += floor(abs((cursorY-stH/2)/5));
                    updateReplayCanvasBounds();
                }
                else if(cursorY > stH-padding)
                {
                    _rregPoint.y -= floor(abs((cursorY-stH/2)/5));
                    updateReplayCanvasBounds();
                }
            }
        }

         //jumpFlag  0: 기본 재생 1:탐색바를 마우스를 이용하여 스킵, 2:one frame 이전스트로크, 3:one frame 이후 스트로크
        private function doDraw(jumpCount:Number,jumpFlag:uint):void
        {
            //jumpflag 1번은 마우스 커서로 무작위 스킵, 2,3번은 스트로크 단위혹은 프레임 단위로 앞뒤로 탐색
            if(replayStartON === false && !jumpFlag) return;

            if(jumpCount > REPLAY_SLOWDRAW_ACTIVE_SPEED)
            {
                if(REPLAY_FASTEST_TOTAL_TIME > 60 && jumpFlag === 0)
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
            const drawLimit:Number = jumpCount-1;
            var rFrameLimit:Number = rFrameArr.length-1; //rframe 인덱스 0번 기준
            var obj:Array;
            var prevJumpImageSaveCount:Number = 0;
            var prevJumpImageSaveIndex:uint = 0;

            if(drawLimit < 0)
            {
                rFrameSumLast = rFrameSum - 1;
            }

            for(var i:Number=0;i<=drawLimit;i++)
            {
                if(!rDataReadFlag)
                {
                    prevJumpImageSaveCount++;
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
                            if(jumpFlag === 1 || jumpFlag === 2)
                            {
                                if(prevJumpImageSaveCount >= CACHE_DIV_10)
                                {
                                    prevJumpImageSaveCount = 0;
                                    if(!rDataPreviewCacheImages[prevJumpImageSaveIndex])
                                    {
                                        const repBmpd:BitmapData = rcanvas1BitmapData;
                                        rDataPreviewCacheImages[prevJumpImageSaveIndex] = [repBmpd.clone(),repBmpd.width,repBmpd.height,RCANVAS_BG_COLOR,rFileCutBytes,rFrameSum];
                                    }
                                    prevJumpImageSaveIndex++;
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

                            if(jumpFlag === 0)
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

                            if(jumpFlag === 0 || doDrawSlowEventON === true)//1프레임 이상일때만 재시작 타이머 가동
                            {
                                //reset replay time해주지 말고 그냥 end플래그만 올려줌
                                //왜냐하면 리플레이 자연적으로 끝나고도 스킵프레임이나 oneframe jump을 해줄수가 있기 때문
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
        
                doTickDraw(cd2,(jumpFlag >= 2) ? true : (i === drawLimit));
                
                rFrameSum++; //resultFrameSum 으로 대체함
            }
            const nt:int = getTimer();
            var totalF:Number;

            if(jumpFlag === 0)
            {
                if(nt-rFrameCursorDelayTime >= 70)
                {
                    tcursor.x = rTinyCursorPos[0];
                    tcursor.y = rTinyCursorPos[1];
                    rFrameCursorDelayTime = nt;
                    
                    if(!mouseClickON)
                    {
                        checkAutoScroll.check(rTinyCursorPos[0],rTinyCursorPos[1]);
                    }
                }

                if(nt-rFrameTextDelayTime >= 1000) //갱신 느리게 해줌
                {
                    totalF = TOTAL_FRAME;
                    const getTimeStr:String = getReplayTime(jumpCount,totalF-rFrameSum);
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
            if(!rJumpMouseON)
            {
                totalF = TOTAL_FRAME;
                replayTimeBox["replayNowBar"].width = replayTimeBox["replayTotalBar"].width*rFrameSum/totalF;
            }
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

                    if(d[10] === true)
                    {
                        setBlurCanvasBySize(size,true);
                    }
                    else if(rcanvas2Draw.filters.length > 0)
                    {
                        rcanvas2Draw.filters = [];
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
                    blendMode = d[3] as String;

                    rcanvas2Draw.filters = [];

                    rLineStyleSave = [alpha,blendMode];
                    rcanvas2.alpha = alpha;
                    cd2.clear();
                    cd2.lineStyle(1,color);
                    cd2.beginFill(color);
                    cd2.drawPath(d[4] as Vector.<int>,d[5] as Vector.<Number>);

                    if(lastFlag) rTinyCursorPos = [d[5][0] as Number,d[5][1] as Number];
                }
               break;

                case "fill2":
                {
                    color = d[1] as uint;
                    alpha = d[2] as Number;
                    blendMode = d[3] as String;

                    rcanvas2Draw.filters = [];

                    rLineStyleSave = [alpha,blendMode];
                    rcanvas2.alpha = alpha;
                    cd2.clear();
                    cd2.lineStyle(1,color);
                    cd2.beginFill(color);

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

                    if(d[9] === true)
                    {
                        setBlurCanvasBySize(size,true);
                    }
                    else if(rcanvas2Draw.filters.length > 0)
                    {
                        rcanvas2Draw.filters = [];
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

                    if(d[11] === true)
                    {
                        setBlurCanvasBySize(size,true);
                    }
                    else if(rcanvas2Draw.filters.length > 0)
                    {
                        rcanvas2Draw.filters = [];
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



        // private function setDefaultTinyCursor():void
        // {
        //     var bitmapDatas:Vector.<BitmapData> = new Vector.<BitmapData>(1, true);
        //     var bitmapData:BitmapData = new BitmapData(7,10,true,0);

        //     // ■■-----
        //     // ■-■----
        //     // ■--■---
        //     // ■---■--
        //     // ■----■-
        //     // ■-----■
        //     // ■---■■-
        //     // ■■■--■-
        //     // ---■-■-
        //     // ----■■-
            
        //     bitmapData.setPixel32(0,0,0xFF000000);
        //     bitmapData.setPixel32(0,1,0xFF000000);
        //     bitmapData.setPixel32(0,2,0xFF000000);
        //     bitmapData.setPixel32(0,3,0xFF000000);
        //     bitmapData.setPixel32(0,4,0xFF000000);
        //     bitmapData.setPixel32(0,5,0xFF000000);
        //     bitmapData.setPixel32(0,6,0xFF000000);
        //     bitmapData.setPixel32(0,7,0xFF000000);
        //     bitmapData.setPixel32(0,8,0xFF000000);
        //     bitmapData.setPixel32(1,0,0xFF000000);
        //     bitmapData.setPixel32(1,8,0xFF000000);
        //     bitmapData.setPixel32(2,1,0xFF000000);
        //     bitmapData.setPixel32(2,7,0xFF000000);
        //     bitmapData.setPixel32(3,2,0xFF000000);
        //     bitmapData.setPixel32(3,8,0xFF000000);
        //     bitmapData.setPixel32(4,3,0xFF000000);
        //     bitmapData.setPixel32(4,6,0xFF000000);
        //     bitmapData.setPixel32(4,9,0xFF000000);
        //     bitmapData.setPixel32(5,4,0xFF000000);
        //     bitmapData.setPixel32(5,6,0xFF000000);
        //     bitmapData.setPixel32(5,7,0xFF000000);
        //     bitmapData.setPixel32(5,8,0xFF000000);
        //     bitmapData.setPixel32(6,5,0xFF000000);
        //     bitmapData.floodFill(1,1,0xFFFFFFFF);

        //     bitmapDatas[0] = bitmapData;

        //     var cursorData:MouseCursorData = new MouseCursorData();
        //     cursorData.hotSpot = new Point(0,0);
        //     cursorData.data = bitmapDatas;

        //     Mouse.registerCursor("MyCursor", cursorData);
        //     Mouse.cursor = "MyCursor";
        // }

        //13.26버전 필펜 따로 추가 되기전에 펜툴 함수
        private function closurePenTool():Function
        {
            const cd:Shape = canvas2Draw;
            const floor:Function = Math.floor; 
            const cdg:Graphics = cd.graphics;
            const circleGraphic:Graphics = capturePreviewCursor.graphics;

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
            var distLimit:Number;//penmove에서 distlimit이하이면 jump해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌
            var shortDistFlag:Boolean; //확대 많이 하고 살짝 움직였을때 penmove에서 아예 처리를 안하는데 이걸 dot으로 처리하게 해줌
            var subLayerFlag:Boolean;
            var sqPenCursorLastX:Number;
            var sqPenCursorLastY:Number;

            var _fillPenON:Boolean;
            const fillPenCommand:Vector.<int> = new Vector.<int>(); //필펜 커맨드
            const fillPenPoints:Vector.<Number> = new Vector.<Number>(); //필펜 좌표
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

                        if(_fillPenON == false)
                        {
                            //이게 정확할런지 모르겠다
                            rDataBuffer.splice(rDataBuffer.length-2,1);
                        }
                    
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

                    if(_fillPenON)
                    {
                        const bgContrast:Number = getColorBright(xColor,1.0);
                        const borderColor:uint = (bgContrast >= 137) ? 0 : 0xFFFFFF;
                        const _zoomed:Number = zoomed;

                        
                        canvas2.alpha = 1.0;
                        capturePreviewCursor.x = 0;
                        capturePreviewCursor.y = 0;
                        capturePreviewCursor.visible = true;
                        circleGraphic.clear();
                        circleGraphic.lineStyle(1/_zoomed,0,1.0);
                        circleGraphic.drawCircle(cx,cy,10/_zoomed);
                        circleGraphic.lineStyle(1/_zoomed,0xFFFFFF,1.0);
                        circleGraphic.drawCircle(cx,cy,9/_zoomed);

                        cdg.lineStyle(1,xColor);
                        fillPenCommand.push(1);
                        fillPenPoints.push(cx);
                        fillPenPoints.push(cy);
                    }
                    else
                    {
                        lineStyleReady(xShape,xSize,xColor,xAlpha);
                        rDataBuffer.push(["lineStyle",xShape,xSize,xColor,xAlpha,cx,cy,xBlendMode,false,subLayerFlag,_airBrushON]); //cx cy 처음 클릭한 지점으로 지정해줘야함
                        penCommand.push(1);
                        penPoints.push(cx);
                        penPoints.push(cy);
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

                if(!_fillPenON)
                {
                    rDataBuffer.push(["lineTo",x,y]);
                    penCommand.push(2);
                    penPoints.push(x);
                    penPoints.push(y);
                }
                else
                {
                    fillPenCommand.push(2);
                    fillPenPoints.push(x);
                    fillPenPoints.push(y);
                }
                
                if(pixelSnapON === true && _fillPenON === false
                && _penSmoothSlideValue === 0 && rotateFlag == false)
                {
                    checkPixelPerfect();
                }

                 //이 카운터 마다 다시 캔버스 2에 그려줌 길게 그을수록 cpu처리가 많아짐
                if(++mouseMoveCount >= 100)
                {
                    canvas2BitmapData.draw(cd,null,null,"layer");
                    canvas2Bitmap.bitmapData = canvas2BitmapData;
                    cdg.clear();

                    if(_fillPenON)
                    {
                        cdg.lineStyle(1,xColor);
                    }
                    else
                    {
                        penCommand.length = 0;
                        penPoints.length = 0;
                        lineStyleReady(xShape,xSize,xColor,xAlpha);
                        rDataBuffer.push(["tempDone"]);
                        rDataBuffer.push(["lineStyle",xShape,xSize,xColor,xAlpha,x,y,xBlendMode,false,subLayerFlag,_airBrushON]);

                        penCommand.push(1);
                        penPoints.push(x);
                        penPoints.push(y);
                    }

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
                else
                {
                    penMove2(mx,my);
                }

                e.updateAfterEvent();
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

                if(_fillPenON)
                {
                    circleGraphic.clear();
                    capturePreviewCursor.visible = false;

                    if(mouseMovedFlag)
                    {
                        //마지막 원점 이어줌
                        fillPenCommand.push(2);
                        fillPenPoints.push(cx);
                        fillPenPoints.push(cy);

                        //캔버스 2 초기화 하고
                        canvas2Bitmap.bitmapData = null;
                        canvas2BitmapData.dispose();
                        canvas2BitmapData = new BitmapData(CANVAS_WIDTH,CANVAS_HEIGHT,true,0);
                        cdg.clear();
                        canvas2.alpha = xAlpha; //다시 그려줌
                        cdg.lineStyle(1,xColor);
                        cdg.beginFill(xColor);
                        cdg.drawPath(fillPenCommand,fillPenPoints);
                        cdg.endFill();
                        rDataBuffer.push(["fill",xColor,xAlpha,xBlendMode,fillPenCommand.concat(),fillPenPoints.concat()]);
                    }

                    fillPenCommand.length = 0;
                    fillPenPoints.length = 0;
                }
                else if(_penSmoothSlideValue > 1 && penToolFlag)
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

                e.updateAfterEvent();
            }

            return function (penFlag:Boolean):void
            {
                penToolFlag = penFlag;
                
                if(penFlag)
                {
                    _fillPenON = (nowTool === TOOL_FILL_PEN);
                    xSize = penSize;
                    xColor = penColor;
                    xAlpha = penAlpha;
                    xShape = penShape;
                    xBlendMode = (xColor === CANVAS_BG_COLOR) ? "erase" : null;
                    _airBrushON = airBrushON;
                }
                else
                {
                    _fillPenON = false;
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

                if(_fillPenON)
                {
                    _airBrushON = false;
                    xOffset = (_pixelSnap) ? 0.5 : 0;
                    xSize = 1;
                    fillPenCommand.length = 0; //필펜 커맨드
                    fillPenPoints.length = 0; //필펜 좌표
                }

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
                distLimit = xSize/10;//penmove에서 distlimit이하이면 jump해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌
                shortDistFlag = false; //확대 많이 하고 살짝 움직였을때 penmove에서 아예 처리를 안하는데 이걸 dot으로 처리하게 해줌

                checkUndoReady();

                stage.addEventListener(MouseEvent.MOUSE_MOVE,penToolMoveEvent);
                stage.addEventListener(MouseEvent.MOUSE_UP,penToolUpEvent);
            };
        }
        
        private var printdeepLevel:int = 0;
        private function printArray(obj:Object,deepKey:String=""):void
        {
            var blank:String="";
            if(printdeepLevel === 0) trace('--- PRINT START --- ');
            else
            {
                const count:int = printdeepLevel;
                for(var b:int = 0; b < count;b++)
                {
                    blank += "   ";
                }
                trace(blank+'--> ['+deepKey+']');
            }

            for(var i:String in obj)
            {
                if(obj[i] !== null && typeof obj[i] === "object" && obj[i].length > 0)
                {
                    ++printdeepLevel;
                    printArray(obj[i],i);
                }
                else
                {
                    trace(blank+'|'+i + ' : ' + obj[i]);
                }
            }
            --printdeepLevel;
        }
    }

          private var gcCount:int;
        private function startGCCycle():void{
            gcCount = 0;
            trace('gc 시작');
            addEventListener(Event.ENTER_FRAME, doGC);
        }
        private function doGC(evt:Event):void{
            System.gc();
            trace('한번하고');
            if(++gcCount > 1){
                trace('두번하고');
                removeEventListener(Event.ENTER_FRAME, doGC);
                setTimeout(lastGC, 40);
            }
        }
        private function lastGC():void{
            trace('세번하고')
            System.gc();
        }

        private function printMemory(str:String):void
        {
            const a:Number = (System.privateMemory/1048576);
            const b:Number = (System.totalMemory/1048576);
            trace(str,' : memory = ',a,"/",b);
        }
        private function testSend():void
        {
            printMemory('보내기전 메모리')
            var ba:ByteArray = new ByteArray();
            canvas1BitmapData.copyPixelsToByteArray(
                new Rectangle(0,0,canvas1BitmapData.width,canvas1BitmapData.height),ba);
            trace('바이트 사이즈',ba.length/1048576);
            mainToBack.send(ba);
            // ba.clear();
            ba = null;
            printMemory('보낸 후 메모리')
            printMemory('gc한 메모리')

            startGCCycle();
        }

             // private function drawArcDashedLine(g:Graphics,radius:Number):void
        // {
        //     const div:Number = radius*2;
        //     const divAngle:Number = 360/div;
        //     const len:Number = div;

        //     for(var i:Number=0; i<len; i+=2)
        //         drawArc(g,0,0,0,radius,divAngle*i,divAngle*(i+1),1);

        //     for(i=1; i<=len; i+=2)
        //         drawArc(g,0xFFFFFF,0,0,radius,divAngle*i,divAngle*(i+1),1);
        // }

        // private function drawArc(g:Graphics,color:uint,
        // cx:Number,cy:Number,radius:Number
        // ,angleFrom:Number,angleTo:Number,precision:Number):void
        // {
		// 	var angle_diff:Number = angleTo-angleFrom;
		// 	var steps:Number = Math.round(angle_diff*precision);
		// 	var angle:Number = angleFrom;
		// 	var px:Number = cx+radius*Math.cos(angle*0.0174532925);
		// 	var py:Number = cy+radius*Math.sin(angle*0.0174532925);
            
        //     g.lineStyle(1,color);
		// 	g.moveTo(px,py);

		// 	for (var i:int=1; i<=steps; i++)
        //     {
		// 		angle=angleFrom+angle_diff/steps*i;
		// 		g.lineTo(cx+radius*Math.cos(angle*0.0174532925),cy+radius*Math.sin(angle*0.0174532925));
		// 	}
		// }

} */
