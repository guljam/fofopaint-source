package
{
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.display.Shape;

	public class SidePanelSet extends Sprite
	{
		private const sideBarBG:Shape = new Shape();
		public const WIDTH:Number = 223;
		public var HEIGHT:Number = 220;
		public var tempVisibleON:Boolean = false;

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		public function getWidth():Number
		{
			return Math.round(WIDTH * scaleX);
		}

		public function resetBG():void
		{
			sideBarBG.alpha = 1.0
		}
		public function setTransparentBG():void
		{
			sideBarBG.alpha = 0.8;
		}

		public function updateSideBGSize(sth:Number):void
		{
			sideBarBG.width = WIDTH;
			sideBarBG.height = sth + 1; // 공백 보정으로 길이를 약간 늘려줌
			HEIGHT = sth;
		}

		public function setTempVisibleOFF(rightSide:Boolean):void
		{
			tempVisibleON = false;
			visible = false;

			if (rightSide)
			{
				x = stage.stageWidth - WIDTH * scaleX;
			}
			else
			{
				x = 0;
			}
		}

		public function setTempVisibleON(toolBarWidth:Number, rightSide:Boolean):void
		{
			if (rightSide)
			{
				x = stage.stageWidth - (toolBarWidth - 1) * scaleX;
			}
			else
			{
				x = (-WIDTH + toolBarWidth) * scaleX;
			}

			tempVisibleON = true;
			visible = true;
		}

		public function updateUIColor():void
		{
			Global.applyUIBGColor(sideBarBG);
		}

		public function SidePanelSet()
		{
			name = "sideBar";

			sideBarBG.graphics.clear();
			sideBarBG.graphics.lineStyle(0, 0, 0);
			sideBarBG.graphics.beginFill(0xCCCCCC);
			sideBarBG.graphics.drawRect(0, 0, 10, 10);
			sideBarBG.graphics.endFill();

			sideBarBG.y = -1; // 스케일 조절하면 윗 메뉴 사이에 흰 공백이 보여서 약간 위로 올려줌
			addChild(sideBarBG);
		}
	}
}
