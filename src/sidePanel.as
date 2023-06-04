package
{
	import flash.display.Sprite;
	import flash.display.Graphics;
	import flash.geom.ColorTransform;
	import flash.display.Shape;
	import flash.events.MouseEvent;

	public class sidePanel extends Sprite {
		private const sideBG:Shape = new Shape();
		public const w:Number = 220;
		public var h:Number = 220;
		private const sepLine:Shape = new Shape();
		public var tempVisibleON:Boolean = false;

		public function getWidth():Number
		{
			return Math.round(w*scaleX);
		}

		public function setTempVisibleOFF(rightSide:Boolean):void
		{
			tempVisibleON = false;
			visible = false;

			if(rightSide) x = stage.stageWidth-w*scaleX;
			else x = 0;
		}

		public function setTempVisibleON(toolBarWidth:Number,rightSide:Boolean):void
		{
			if(rightSide) x = stage.stageWidth-(toolBarWidth-1)*scaleX;
			else x = (-w+toolBarWidth)*scaleX;

			tempVisibleON = true;
			visible = true;
		}

		public function updateSideBGSize(sth:Number):void
		{
			sideBG.width = w;
			sideBG.height = sth+2; //공백 보정으로 길이를 약간 늘려줌
			h = sth;
		}

		public function changeUIColor(color:uint,op:uint):void
		{
			const b:ColorTransform = new ColorTransform();
			const o:ColorTransform = new ColorTransform();
			b.color = color;
			o.color = op;
			o.alphaMultiplier = 0.25;
			sideBG.transform.colorTransform = b;
		}

		public function sidePanel()
		{
			name = "sideBar";

			const g:Graphics = sideBG.graphics;
            g.clear();
            g.lineStyle(0,0,0);
            g.beginFill(0xCCCCCC);
            g.drawRect(0,0,10,10);
            g.endFill();
			sideBG.y = -1; //스케일 조절하면 윗 메뉴 사이에 흰 공백이 보여서 약간 위로 올려줌
			addChild(sideBG);
            cacheAsBitmap = false;
		}
	}
}
