package Modules.L4UI.UIEngine
{
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.SimpleButton;
    import flash.display.Sprite;
    import flash.geom.Rectangle;

    // 층: L4 UI - 우클릭 툴 메뉴(toolBox2), 올가미 메뉴, 참조 레이어 메뉴처럼 배경 사각형 조각 여러 개가 맞붙어 한 상자를 이루는 메뉴의
    // 겉 테두리를 손으로 그린 듯 해진 모양으로 자르는 마스크(WornBorderMask)를 소유함.
    // 마스크는 깎기만 하므로 배경 조각의 바깥쪽 변을 EXTEND_PX만큼 먼저 늘려서, 깎인 뒤에도 원래 상자 크기에 가깝게 보이게 함.
    // 조각마다 같은 크기의 마스크를 하나씩 걸어서(마스크 하나는 객체 하나만 가릴 수 있음) 조각이 맞닿은 안쪽 이음매는 깎이지 않음
    public class MenuBoxBorderUI
    {
        // 배경 조각의 바깥쪽 변을 늘리는 길이(px). 메뉴 안 좌표 기준이라 메뉴 배율만큼 같이 커짐
        public static const EXTEND_PX:Number = 2.0;

        // 조각의 변이 상자 바깥 변과 같은 위치로 보는 오차(px). 올가미 메뉴의 BG2와 이동 버튼 오른쪽 끝이 0.1px 어긋나 있어서 둠
        private static const SAME_EDGE_TOLERANCE:Number = 0.5;

        private var backgroundPieceList:Array;
        private var borderMaskList:Array = [];

        // backgroundPieceList의 조각들은 바깥쪽 변을 EXTEND_PX 늘리고 마스크를 걸며, maskOnlyObjectList의 객체(진행 막대 등)는 크기는 그대로 두고 마스크만 걸어서
        // 같은 상자 테두리로 잘라냄. erosionScale은 상자별 깎임 강도 배율(1.0이 기본). 두 목록 모두 menuBox의 직계 자식이어야 하고, menuBox 생성자 맨 끝(조각들이 자리를 잡은 뒤)에서 불러야 함
        public function MenuBoxBorderUI(menuBox:Sprite, backgroundPieceList:Array, maskOnlyObjectList:Array, wornSeed:uint, erosionScale:Number = 1.0)
        {
            this.backgroundPieceList = backgroundPieceList;

            extendOuterEdgesOfBackgroundPieces();

            const maskTargetList:Array = backgroundPieceList.concat(maskOnlyObjectList);

            for each (var maskTarget:DisplayObject in maskTargetList)
            {
                const borderMask:WornBorderMask = new WornBorderMask(wornSeed, erosionScale);
                menuBox.addChild(borderMask);
                maskTarget.mask = borderMask;
                borderMaskList.push(borderMask);
            }

            updateMenuBoxBorderRect();
        }

        // 조각들이 이룬 상자 바깥 사각형을 구해서, 그 바깥 변과 같은 위치의 조각 변을 EXTEND_PX씩 바깥으로 늘림
        private function extendOuterEdgesOfBackgroundPieces():void
        {
            const boxLeft:Number = getBackgroundPiecesLeft();
            const boxTop:Number = getBackgroundPiecesTop();
            const boxRight:Number = getBackgroundPiecesRight();
            const boxBottom:Number = getBackgroundPiecesBottom();

            for each (var piece:DisplayObject in backgroundPieceList)
            {
                const pieceLeft:Number = piece.x;
                const pieceTop:Number = piece.y;
                const pieceRight:Number = piece.x + piece.width;
                const pieceBottom:Number = piece.y + piece.height;

                const isLeftOuter:Boolean = Math.abs(pieceLeft - boxLeft) <= SAME_EDGE_TOLERANCE;
                const isTopOuter:Boolean = Math.abs(pieceTop - boxTop) <= SAME_EDGE_TOLERANCE;
                const isRightOuter:Boolean = Math.abs(pieceRight - boxRight) <= SAME_EDGE_TOLERANCE;
                const isBottomOuter:Boolean = Math.abs(pieceBottom - boxBottom) <= SAME_EDGE_TOLERANCE;

                piece.x = isLeftOuter ? pieceLeft - EXTEND_PX : pieceLeft;
                piece.y = isTopOuter ? pieceTop - EXTEND_PX : pieceTop;
                piece.width = (pieceRight + (isRightOuter ? EXTEND_PX : 0)) - piece.x;
                piece.height = (pieceBottom + (isBottomOuter ? EXTEND_PX : 0)) - piece.y;
            }
        }

        // 배경 조각들이 지금 차지하는 상자 사각형에 마스크 위치와 크기를 맞춤. 힌트 때문에 조각이 움직이거나 높이가 바뀌면 불러야 함
        public function updateMenuBoxBorderRect():void
        {
            const boxLeft:Number = getBackgroundPiecesLeft();
            const boxTop:Number = getBackgroundPiecesTop();
            const boxWidth:Number = getBackgroundPiecesRight() - boxLeft;
            const boxHeight:Number = getBackgroundPiecesBottom() - boxTop;

            for each (var borderMask:WornBorderMask in borderMaskList)
            {
                borderMask.x = boxLeft;
                borderMask.y = boxTop;
                borderMask.updateMaskSize(boxWidth, boxHeight);
            }
        }

        // 버튼들의 마우스 올림 상태(overState) 배경에 해진 가장자리 마스크를 검. 마우스를 올렸을 때(누를 때도 downState가 overState와 같은 객체) 배경 사각형만 깎이고 클릭 영역(hitTestState)은 그대로임.
        // overState가 [0: 배경, 1: 아이콘] 구조인 버튼만 처리하고 다른 구조는 건너뜀. 색 지정 코드가 getChildAt(0/1)을 쓰므로 마스크는 맨 끝 자식으로 넣음.
        // 버튼마다 baseSeed + 목록 번호를 seed로 써서 타일마다 모양이 다름. 마스크는 배경 크기로 한 번만 그리며 상태 안 좌표라 버튼과 상자 배율을 그대로 받음
        public static function applyBorderMaskToButtonOverStates(buttonList:Array, baseSeed:uint, erosionScale:Number):void
        {
            for (var buttonIndex:int = 0; buttonIndex < buttonList.length; buttonIndex++)
            {
                const targetButton:SimpleButton = buttonList[buttonIndex] as SimpleButton;
                const overStateContainer:DisplayObjectContainer = targetButton.overState as DisplayObjectContainer;

                if (overStateContainer === null || overStateContainer.numChildren !== 2)
                {
                    continue;
                }

                const overBackground:DisplayObject = overStateContainer.getChildAt(0);
                const overBackgroundBounds:Rectangle = overBackground.getBounds(overStateContainer);
                const overBackgroundMask:WornBorderMask = new WornBorderMask(baseSeed + buttonIndex, erosionScale);

                overBackgroundMask.x = overBackgroundBounds.x;
                overBackgroundMask.y = overBackgroundBounds.y;
                overBackgroundMask.updateMaskSize(overBackgroundBounds.width, overBackgroundBounds.height);
                overStateContainer.addChild(overBackgroundMask);
                overBackground.mask = overBackgroundMask;
            }
        }

        // 배경 조각 중 가장 왼쪽 x
        private function getBackgroundPiecesLeft():Number
        {
            var left:Number = Number.MAX_VALUE;

            for each (var piece:DisplayObject in backgroundPieceList)
            {
                left = Math.min(left, piece.x);
            }

            return left;
        }

        // 배경 조각 중 가장 위쪽 y
        private function getBackgroundPiecesTop():Number
        {
            var top:Number = Number.MAX_VALUE;

            for each (var piece:DisplayObject in backgroundPieceList)
            {
                top = Math.min(top, piece.y);
            }

            return top;
        }

        // 배경 조각 중 가장 오른쪽 끝 x
        private function getBackgroundPiecesRight():Number
        {
            var right:Number = -Number.MAX_VALUE;

            for each (var piece:DisplayObject in backgroundPieceList)
            {
                right = Math.max(right, piece.x + piece.width);
            }

            return right;
        }

        // 배경 조각 중 가장 아래쪽 끝 y
        private function getBackgroundPiecesBottom():Number
        {
            var bottom:Number = -Number.MAX_VALUE;

            for each (var piece:DisplayObject in backgroundPieceList)
            {
                bottom = Math.max(bottom, piece.y + piece.height);
            }

            return bottom;
        }
    }
}
