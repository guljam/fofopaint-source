package
{

	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.text.TextField;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.Clipboard;
	import flash.events.MouseEvent;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.display.Shape;

	public class NumPadSet extends Sprite
	{
		public var numInc:SimpleButton;
		public var numDec:SimpleButton;
		public var num0:SimpleButton;
		public var num1:SimpleButton;
		public var num2:SimpleButton;
		public var num3:SimpleButton;
		public var num4:SimpleButton;
		public var num5:SimpleButton;
		public var num6:SimpleButton;
		public var num7:SimpleButton;
		public var num8:SimpleButton;
		public var num9:SimpleButton;
		public var numHexCopyBG:SimpleButton;
		public var oklchBG:SimpleButton;
		public var numIncText:TextField;
		public var numDecText:TextField;
		public var num0Text:TextField;
		public var num1Text:TextField;
		public var num2Text:TextField;
		public var num3Text:TextField;
		public var num4Text:TextField;
		public var num5Text:TextField;
		public var num6Text:TextField;
		public var num7Text:TextField;
		public var num8Text:TextField;
		public var num9Text:TextField;
		public var oklabLText:TextField;
		public var oklabCText:TextField;
		public var oklabHText:TextField;
		public var numHexCopyText:TextField = numHexCopyText;

		private var numHexCopyTextBGDefaultColor:Array = [0, 0xFFFFFF];
		private var numHexCopyColor:* = null;

		private const okLWrapper:Sprite = new Sprite();
		private var okLBitmap:Bitmap;
		private const okLSlider:Shape = new Shape();
		private const okCWrapper:Sprite = new Sprite();
		private var okCBitmap:Bitmap;
		private const okCSlider:Shape = new Shape();
		private const okHWrapper:Sprite = new Sprite();
		private var okHBitmap:Bitmap;
		private const okHSlider:Shape = new Shape();

		private const sliderOffset:Number = 5.0;
		private var okBaseHue:Number = 0;
		private var okBaseColor:uint = 0;
		private var okBaseColorLch:Object;
		private var okPickedColor:uint = 0;

		private const previewBox:Sprite = new Sprite();
		private var onMouseMoveUpdateLCH:Function;
		private var pickColorFunc:Function;
		private var clickedWrapperFlag:int;

		private function initOkLCHSlider():void
		{
			const width:Number = 16;
			const height:Number = 150;

			okLWrapper.name = "okLWrapper";
			okLWrapper.graphics.clear();
			okLWrapper.graphics.beginFill(0, 0);
			okLWrapper.graphics.drawRect(0, 0, width, height);
			okLWrapper.graphics.endFill();
			okLWrapper.x = 112;
			okLWrapper.y = 21;
			okLBitmap = new Bitmap(new BitmapData(1, height - 10, false, 0));
			okLBitmap.y = sliderOffset;
			okLBitmap.width = width;
			okLSlider.graphics.clear();
			okLSlider.graphics.lineStyle(1, 0xFFFFFF);
			okLSlider.graphics.moveTo(0, 0);
			okLSlider.graphics.lineTo(width, 0);
			okLWrapper.addChild(okLBitmap);
			okLWrapper.addChild(okLSlider);
			oklabLText.x = okLWrapper.x + (width - oklabLText.width) / 2 - 1;
			oklabLText.y = okLWrapper.y - 14;

			okCWrapper.name = "okCWrapper";
			okCWrapper.graphics.clear();
			okCWrapper.graphics.beginFill(0, 0.0);
			okCWrapper.graphics.drawRect(0, 0, width, height);
			okCWrapper.graphics.endFill();
			okCWrapper.x = okLWrapper.x + okLWrapper.width + 3;
			okCWrapper.y = okLWrapper.y;
			okCBitmap = new Bitmap(new BitmapData(1, height - 10, false, 0));
			okCBitmap.y = sliderOffset;
			okCBitmap.width = width;
			okCSlider.graphics.clear();
			okCSlider.graphics.lineStyle(1, 0xFFFFFF);
			okCSlider.graphics.moveTo(0, 0);
			okCSlider.graphics.lineTo(width, 0);
			okCWrapper.addChild(okCBitmap);
			okCWrapper.addChild(okCSlider);
			oklabCText.x = okCWrapper.x + (width - oklabCText.width) / 2 - 1;
			oklabCText.y = okCWrapper.y - 14;

			okHWrapper.name = "okHWrapper";
			okHWrapper.graphics.clear();
			okHWrapper.graphics.beginFill(0, 0.0);
			okHWrapper.graphics.drawRect(0, 0, width, height);
			okHWrapper.graphics.endFill();
			okHWrapper.x = okCWrapper.x + okCWrapper.width + 3;
			okHWrapper.y = okLWrapper.y;
			okHBitmap = new Bitmap(new BitmapData(1, height - 10, false, 0));
			okHBitmap.y = sliderOffset;
			okHBitmap.width = width;
			okHSlider.graphics.clear();
			okHSlider.graphics.lineStyle(1, 0xFFFFFF);
			okHSlider.graphics.moveTo(0, 0);
			okHSlider.graphics.lineTo(width, 0);
			okHWrapper.addChild(okHBitmap);
			okHWrapper.addChild(okHSlider);
			oklabHText.x = okHWrapper.x + (width - oklabHText.width) / 2;
			oklabHText.y = okHWrapper.y - 14;

			previewBox.visible = false;
			previewBox.x = oklabLText.x - 2;
			previewBox.y = oklabLText.y - 2;

			addChild(okHWrapper);
			addChild(okLWrapper);
			addChild(okCWrapper);
			addChild(previewBox);
		}

		public function setScale(newScale:Number):void
		{
			scaleX = newScale;
			scaleY = newScale;
		}

		public function changeUIColor(arr:Array):void
		{
			const base:ColorTransform = new ColorTransform();
			const over:ColorTransform = new ColorTransform();

			numHexCopyTextBGDefaultColor[0] = arr[0];
			numHexCopyTextBGDefaultColor[1] = arr[2];
			base.color = arr[0];
			over.color = arr[4];

			const texts:Array = [
					numIncText,
					numDecText,
					num0Text,
					num1Text,
					num2Text,
					num3Text,
					num4Text,
					num5Text,
					num6Text,
					num7Text,
					num8Text,
					num9Text,
					numHexCopyText,
					oklabLText,
					oklabCText,
					oklabHText
				];

			const buttons:Array = [
					numInc,
					numDec,
					num0,
					num1,
					num2,
					num3,
					num4,
					num5,
					num6,
					num7,
					num8,
					num9,
					numHexCopyBG,
					oklchBG,
				];

			var i:uint;
			var len:uint = buttons.length;
			var btn:SimpleButton;
			var btnUp:DisplayObject;
			var btnOver:DisplayObject;

			for (i = 0; i < len; i++)
			{
				btn = buttons[i];
				btnUp = btn.upState as DisplayObject;
				btnOver = btn.overState as DisplayObject;
				btnUp.transform.colorTransform = base;
				btnOver.transform.colorTransform = over;
				btn.downState = btnOver;
			}

			len = texts.length;

			for (i = 0; i < len; i++)
			{
				texts[i].textColor = arr[2];
			}
		}

		public function initOkLchSliderPos(lch:Object):void
		{
			const height:Number = okLBitmap.bitmapData.height;
			const lpos:Number = height-lch.L*height;
			const cpos:Number = height-lch.C*height;
			const hpos:Number = height-(lch.H/360.0)*height;

			okLSlider.y = lpos+sliderOffset;
			okCSlider.y = cpos+sliderOffset;
			okHSlider.y = hpos+sliderOffset;
		}

		public function updateOkBaseColor(color:uint):void
		{
			okBaseColor = color;
			okBaseColorLch = hexToOklch(color);
			if (isBaseColorGray())
			{
				okBaseColorLch.H = okBaseHue;
			}
			
			initOkLchSliderPos(okBaseColorLch);

			updateOKGradient(true, true, true);
		}

		public function readyLCHAdjustment(purehue:uint, color:uint, invertcolorfunc:Function):void
		{
			visible = true;
			okBaseHue = hexToOklch(purehue).H;
			updateOkBaseColor(color);
			checkClipBoardHexColor(invertcolorfunc);
		}

		public function off():void
		{
			visible = false;
		}

		private function updateHexCopyBGColor(color:uint):void
		{
			const c:ColorTransform = numHexCopyBG.transform.colorTransform;
			c.color = color;
			const btnUp:DisplayObject = numHexCopyBG.upState as DisplayObject;
			const btnOver:DisplayObject = numHexCopyBG.overState as DisplayObject;
			const btnDown:DisplayObject = numHexCopyBG.downState as DisplayObject;
			numHexCopyBG.downState = btnOver;
			btnUp.transform.colorTransform = c;
			btnOver.transform.colorTransform = c;
			btnDown.transform.colorTransform = c;
		}

		private function isHexFormatColor(str:String):Boolean
		{
			const pattern:RegExp = /^#?[0-9a-fA-F]{6}$/g;
			return pattern.test(str);
		}

		public function checkClipBoardHexColor(invertcolorfunc:Function):void
		{
			var str:* = Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT) as String;
			if (str && isHexFormatColor(str))
			{
				var colorstr:String = str;
				if (colorstr.charAt(0) === '#')
				{
					colorstr = colorstr.substr(1);
				}

				const hexcolor:uint = uint("0x" + colorstr);
				const textcolor:uint = invertcolorfunc(hexcolor);
				numHexCopyColor = hexcolor;
				updateHexCopyBGColor(hexcolor);
				numHexCopyText.text = "#" + colorstr;
				numHexCopyText.textColor = textcolor;
			}
			else
			{
				numHexCopyColor = null;
				updateHexCopyBGColor(numHexCopyTextBGDefaultColor[0]);
				numHexCopyText.text = "No copied value";
				numHexCopyText.textColor = numHexCopyTextBGDefaultColor[1];
			}
		}

		public function getCopyiedHexColor():*
		{
			return numHexCopyColor;
		}

		private function gammaToLinear(c:Number):Number
		{
			return (c >= 0.04045) ? Math.pow((c + 0.055) / 1.055, 2.4) : c / 12.92;
		}

		private function linearToGamma(c:Number):Number
		{
			return (c >= 0.0031308) ? 1.055 * Math.pow(c, 1 / 2.4) - 0.055 : 12.92 * c;
		}

		private function hexToRGB(num:uint):Object
		{
			return {r: num >> 16, g: (num >> 8) & 0xFF, b: num & 0xFF};
		}

		private function rgbToHex(rgb:Object):uint
		{
			var r:uint = rgb.r;
			var g:uint = rgb.g;
			var b:uint = rgb.b;
			return (r << 16) | (g << 8) | b;
		}

		private function clamp(v:Number, min:Number, max:Number):Number
		{
			return (v < min) ? min : (v > max) ? max : v;
		}

		private function cubeRoot(x:Number, tol:Number = 1e-12, maxIter:int = 20):Number
		{
			if (x == 0)
				return 0;
			var sign:int = (x < 0) ? -1 : 1;
			if (x < 0)
				x = -x;

			var y:Number = Math.exp(Math.log(x) / 3); // 초기 추정값

			for (var i:int = 0; i < maxIter; i++)
			{
				var next:Number = (2 * y + x / (y * y)) / 3;
				if (Math.abs(next - y) < tol)
				{
					return sign * next;
				}
				y = next;
			}
			return sign * y;
		}

		private function rgbToOklab(r:Number, g:Number, b:Number):Object
		{
			r = gammaToLinear(r / 255);
			g = gammaToLinear(g / 255);
			b = gammaToLinear(b / 255);

			var l:Number = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b;
			var m:Number = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b;
			var s:Number = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b;

			l = cubeRoot(l);
			m = cubeRoot(m);
			s = cubeRoot(s);

			return {
					L: 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
					a: 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
					b: 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
				};
		}

		private function oklabToSRGB(L:Number, a:Number, b:Number):Object
		{
			var l:Number = L + a * 0.3963377774 + b * 0.2158037573;
			var m:Number = L - a * 0.1055613458 - b * 0.0638541728;
			var s:Number = L - a * 0.0894841775 - b * 1.2914855480;

			l = l * l * l;
			m = m * m * m;
			s = s * s * s;

			var r:Number = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
			var g:Number = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s;
			var bb:Number = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s;

			r = Math.round(clamp(255 * linearToGamma(r), 0, 255));
			g = Math.round(clamp(255 * linearToGamma(g), 0, 255));
			bb = Math.round(clamp(255 * linearToGamma(bb), 0, 255));

			return {r: r, g: g, b: bb};
		}

		private function oklchToOklab(L:Number, C:Number, H:Number):Object
		{
			var Hr:Number = H * Math.PI / 180;
			return {L: L, a: C * Math.cos(Hr), b: C * Math.sin(Hr)};
		}

		private function oklabToOklch(L:Number, a:Number, b:Number):Object
		{
			var C:Number = Math.sqrt(a * a + b * b);
			var H:Number = Math.atan2(b, a) * 180 / Math.PI;
			if (H < 0)
				H += 360;
			return {L: L, C: C, H: H};
		}

		private function OklchToHex(oklch:Object):uint
		{
			const ok:Object = oklchToOklab(oklch.L, oklch.C, oklch.H);
			const c:Object = oklabToSRGB(ok.L, ok.a, ok.b);
			return rgbToHex(c);
		}

		private function hexToOklch(color:uint):Object
		{
			const c:Object = hexToRGB(color);
			const ok:Object = rgbToOklab(c.r, c.g, c.b);

			return oklabToOklch(ok.L, ok.a, ok.b);
		}

		public function onOKLCHMouseUp(e:MouseEvent):void
		{
			removeOKLCHMouseEvent();
		}

		public function onOKLCHMouseMove(e:MouseEvent):void
		{
			onMouseMoveUpdateLCH();
			const hexColor:uint = OklchToHex(okBaseColorLch);
			okPickedColor = hexColor;
			updateColorPreviewBox(hexColor);

			if (clickedWrapperFlag == 0)
			{
				updateOKGradient(false, true, true);
			}
			else if (clickedWrapperFlag == 1)
			{
				updateOKGradient(true, false, true);
			}
			else if (clickedWrapperFlag == 2)
			{
				updateOKGradient(true, true, false);
			}

			pickColorFunc(okPickedColor);
		}

		public function isLCHSliderActive():Boolean
		{
			if (onMouseMoveUpdateLCH !== null)
			{
				return true;
			}
			return false;
		}

		public function removeOKLCHMouseEvent():void
		{
			onMouseMoveUpdateLCH = null;
			pickColorFunc = null;
			hideClorPreviewBox();
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onOKLCHMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onOKLCHMouseUp);
		}

		private function addOKLCHMouseEvent():void
		{
			showColorPreviewBox();
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onOKLCHMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onOKLCHMouseUp);
		}

		public function startAdjustLCH(flag:int, pickerBoxFunc:Function):void
		{
			if (flag < 0 || flag > 2)
			{
				return;
			}

			const elements:Array = [okLWrapper, okCWrapper, okHWrapper];
			const moveFuncs:Array = [updateL, updateC, updateH];
			clickedWrapperFlag = flag;
			onMouseMoveUpdateLCH = moveFuncs[flag];
			pickColorFunc = pickerBoxFunc;
			showColorPreviewBox();

			onMouseMoveUpdateLCH();
			const hexColor:uint = OklchToHex(okBaseColorLch);
			okPickedColor = hexColor;
			updateColorPreviewBox(hexColor);

			addOKLCHMouseEvent();
		}

		public function updateL():void
		{
			const ypos:Number = clamp(okLBitmap.mouseY, 0.0, okLBitmap.bitmapData.height - 1.0);
			const value:Number = 1.0 - ypos / okLBitmap.bitmapData.height;
			okBaseColorLch.L = value;
			okLSlider.y = ypos + sliderOffset;
		}

		public function updateC():void
		{
			const ypos:Number = clamp(okCBitmap.mouseY, 0.0, okCBitmap.bitmapData.height - 1.0);
			var value:Number = (1.0 - ypos / okCBitmap.bitmapData.height);
			okBaseColorLch.C = value;
			okCSlider.y = ypos + sliderOffset;
		}

		public function updateH():void
		{
			const ypos:Number = clamp(okHBitmap.mouseY, 0.0, okHBitmap.bitmapData.height - 1.0);
			const value:Number = 360.0 - 360.0 * (ypos / okHBitmap.bitmapData.height);
			okBaseColorLch.H = value;
			okHSlider.y = ypos + sliderOffset;
		}

		public function isBaseColorGray():Boolean
		{
			return okBaseColor % 0x010101 == 0;
		}

		public function getAdjustedBaseColor(flag:int, value:Number):uint
		{
			const l:Object = {L: okBaseColorLch.L, C: okBaseColorLch.C, H: okBaseColorLch.H};
			const props:Array = ["L", "C", "H"];
			l[props[flag]] = value;
			return OklchToHex(l);
		}

		public function updateOKGradient(lflag:Boolean, cflag:Boolean, hflag:Boolean):void
		{
			const height:int = okLBitmap.bitmapData.height;
			const configs:Array =
				[
					{flag: lflag, bmpd: okLBitmap.bitmapData, max: 1.0, step: 1.0 / height, idx: 0},
					{flag: cflag, bmpd: okCBitmap.bitmapData, max: 1.0, step: 1.0 / height, idx: 1},
					{flag: hflag, bmpd: okHBitmap.bitmapData, max: 360.0, step: 360.0 / height, idx: 2}
				];

			for each (var cfg:Object in configs)
			{
				if (cfg.flag)
				{
					cfg.bmpd.lock();
					for (var i:int = height; i >= 0; i--)
					{
						cfg.bmpd.setPixel(0, i, getAdjustedBaseColor(cfg.idx, cfg.max - cfg.step * i));
					}
					cfg.bmpd.unlock();
				}
			}
		}

		public function hideClorPreviewBox():void
		{
			previewBox.visible = false;
			previewBox.graphics.clear();
		}

		public function updateColorPreviewBox(color:uint):void
		{
			previewBox.graphics.clear();
			previewBox.graphics.beginFill(color);
			previewBox.graphics.drawRect(0, 0, 27, 17);
			previewBox.graphics.beginFill(okBaseColor);
			previewBox.graphics.drawRect(27, 0, 27, 17);
			previewBox.graphics.endFill();
		}

		public function showColorPreviewBox():void
		{
			previewBox.visible = true;
		}

		public function NumPadSet()
		{
			visible = false;
			name = "numPadBox";
			numIncText.mouseEnabled = false;
			numDecText.mouseEnabled = false;
			num0Text.mouseEnabled = false;
			num1Text.mouseEnabled = false;
			num2Text.mouseEnabled = false;
			num3Text.mouseEnabled = false;
			num4Text.mouseEnabled = false;
			num5Text.mouseEnabled = false;
			num6Text.mouseEnabled = false;
			num7Text.mouseEnabled = false;
			num8Text.mouseEnabled = false;
			num9Text.mouseEnabled = false;
			oklchBG.mouseEnabled = false;
			numHexCopyText.mouseEnabled = false;
			initOkLCHSlider();
		}
	}
}
