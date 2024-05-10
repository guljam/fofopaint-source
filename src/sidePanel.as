package
{
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.display.Shape;

	public class sidePanel extends Sprite {
		private const sideBG:Shape = new Shape();
		public const WIDTH:Number = 223;
		public var HEIGHT:Number = 220;
		private const baseColor:ColorTransform = new ColorTransform();
		private const opColor:ColorTransform = new ColorTransform();
		public var tempVisibleON:Boolean = false;

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		public function getWidth():Number
		{
			return Math.round(WIDTH*scaleX);
		}

		public function updateSideBGSize(sth:Number):void
		{
			sideBG.width = WIDTH;
			sideBG.height = sth+1; //공백 보정으로 길이를 약간 늘려줌
			HEIGHT = sth;
		}

		public function setTempVisibleOFF(rightSide:Boolean):void
		{
			tempVisibleON = false;
			visible = false;

			if(rightSide) x = stage.stageWidth-WIDTH*scaleX;
			else x = 0;
		}

		public function setTempVisibleON(toolBarWidth:Number,rightSide:Boolean):void
		{
			if(rightSide) x = stage.stageWidth-(toolBarWidth-1)*scaleX;
			else x = (-WIDTH+toolBarWidth)*scaleX;

			tempVisibleON = true;
			visible = true;
		}

		public function changeUIColor(color:uint):void
		{
			baseColor.color = color;
			sideBG.transform.colorTransform = baseColor;
		}

		public function sidePanel()
		{
			name = "sideBar";

            sideBG.graphics.clear();
            sideBG.graphics.lineStyle(0,0,0);
            sideBG.graphics.beginFill(0xCCCCCC);
            sideBG.graphics.drawRect(0,0,10,10);
            sideBG.graphics.endFill();

			sideBG.y = -1; //스케일 조절하면 윗 메뉴 사이에 흰 공백이 보여서 약간 위로 올려줌
			addChild(sideBG);
		}
	}
}
