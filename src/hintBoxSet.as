package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.display.Sprite;
	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;

	public class HintBoxSet extends Sprite
	{
		static private var _instantCount:int = 0;
		public var hintText:TextField;
		private var _hintBG:Sprite;
		private var _bgColor:uint = 0xFFA700;
		private var _hintHeight:Number = 0;
		private var _stage:DisplayObjectContainer;
		private var _hintTimerName:String;
		private var _isHintHideEventsAdded:Boolean = false;

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

		public function updateBGColor():void
		{
			_bgColor = Global.getHintBGColor();
		}

		public function getDefaultHeight():Number
		{
			return _hintHeight;
		}

		public function getScaledTextHeight():Number
		{
			return hintText.height * scaleX;
		}

		public function getScaledTextWidth():Number
		{
			return hintText.width * scaleX;
		}
		public function getScaledHeight():Number
		{
			return (_hintBG.height - 1) * scaleX;
		}

		public function setHintTextColor(color:uint):void
		{
			hintText.textColor = color;
		}

		public function setHintText(str:String):void
		{
			hintText.text = str;
			if (_hintBG != null)
			{
				_hintBG.graphics.clear();
				// _hintBG.graphics.lineStyle(0, 0, 0.0);
				_hintBG.graphics.beginFill(_bgColor, 0.75);
				_hintBG.graphics.drawRect(-2, -2, hintText.width + 6, hintText.height + 3);
				_hintBG.graphics.endFill();
			}
		}

		public function onMouseEventHideHint(e:MouseEvent):void
		{
			hide();
		}

		public function show(duration:Number = 0.0):void
		{
			this.visible = true;

			if (duration > 0.0)
			{
				FOFOTimer.addByName(_hintTimerName, duration, false, function():void
				{
					hide();
				});

				if (!_isHintHideEventsAdded)
				{
					_isHintHideEventsAdded = true;
					_stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseEventHideHint);
					_stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onMouseEventHideHint);
				}
			}
		}

		public function hide():void
		{
			this.visible = false;
			setHintText("");
			FOFOTimer.remove(_hintTimerName);
			_isHintHideEventsAdded = false;
			_stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseEventHideHint);
			_stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onMouseEventHideHint);
		}

		public function isShowing():Boolean
		{
			return this.visible;
		}

		public function HintBoxSet(stage:DisplayObjectContainer, initBG:Boolean)
		{
			_instantCount++;
			_hintTimerName = "hintShowTimer" + _instantCount;
			_stage = stage;
			visible = false;
			hintText.mouseEnabled = false;
			hintText.autoSize = TextFieldAutoSize.LEFT;
			this.mouseEnabled = false;

			setHintText("FOFO PAINT HINT");
			_hintHeight = this.height;
			setHintText("");

			if (initBG)
			{
				_hintBG = new Sprite();
				_hintBG.y = -1;
				addChild(_hintBG);
				setChildIndex(_hintBG, 0);
				_hintBG.mouseEnabled = false;
			}
			hintText.mouseEnabled = false;
			mouseEnabled = false;
			_stage.addChild(this);
		}
	}
}
