package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.display.Sprite;
	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;

	public class hintBoxSet extends Sprite {
		public var hintText:TextField;
		private var _hintBG:Sprite;
		private var _bgColor:uint = 0xFFA700;
		private var _hintHeight:Number = 0;
		private var _stage:DisplayObjectContainer;
		private var _hintTimer:int = 0;

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		public function getText():String
		{
			return hintText.text;
		}

		public function updateHintTextColor(color:uint):void
		{
			hintText.textColor = color;
		}

		public function updateBGColor(color:uint):void
		{
			_bgColor = color;
		}

		public function getDefaultHeight():Number
		{
			return _hintHeight;
		}

		public function getScaledTextHeight():Number
		{
			return hintText.height*scaleX;
		}

		public function getScaledTextWidth():Number
		{
			return hintText.width*scaleX;
		}
		public function getScaledHeight():Number
		{
			return (_hintBG.height-1)*scaleX;
		}

		public function setHintText(str:String):void
		{
			hintText.text = str;
			if(_hintBG != null)
			{
				_hintBG.graphics.clear();
				_hintBG.graphics.lineStyle(1,0,0.5);
				_hintBG.graphics.beginFill(_bgColor,0.75);
				_hintBG.graphics.drawRect(-1,-1,hintText.width+2,hintText.height+2);
				_hintBG.graphics.endFill();
			}
		}

		public function hideHintWithMouseEvents():void
		{
			if(_hintTimer !== 0)
			{
				clearTimeout(_hintTimer);
				_hintTimer = 0;
			}
			hide();
			_stage.removeEventListener(MouseEvent.MOUSE_DOWN,onMouseEventHideHint);
			_stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onMouseEventHideHint);
		}
		public function onMouseEventHideHint(e:MouseEvent):void
		{
			hideHintWithMouseEvents();
		}

		public function show(duration:Number=0.0):void
		{
			this.visible = true;

			if(duration > 0.0)
			{
				_hintTimer = setTimeout(function():void
				{
					hideHintWithMouseEvents();
				},duration*1000);
				_stage.addEventListener(MouseEvent.MOUSE_DOWN,onMouseEventHideHint);
				_stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,onMouseEventHideHint);
			}
		}

		public function hide():void
		{
			this.visible = false;
			setHintText("");
		}

		public function isShowing():Boolean
		{
			return this.visible;
		}

		public function hintBoxSet(stage:DisplayObjectContainer,initBG:Boolean)
		{
			_stage = stage;
			visible = false;
			hintText.mouseEnabled = false;
			hintText.autoSize = TextFieldAutoSize.LEFT;
			this.mouseEnabled = false;

			setHintText("FOFO PAINT HINT");
			_hintHeight = this.height;
			setHintText("");

			if(initBG)
			{
				_hintBG = new Sprite();
				_hintBG.y = -1;
				addChild(_hintBG);
				setChildIndex(_hintBG,0);
				_hintBG.mouseEnabled = false;
			}
			hintText.mouseEnabled = false;
			mouseEnabled = false;
			_stage.addChild(this);
		}
	}
}
