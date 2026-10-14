package Symbols
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
	import assets.VisualBuilder;
	import assets.VisualFieldCollector;
	import Modules.L1Data.InputPriority;
	import Modules.L1Data.UIEngine.UITheme;

	// 층: L4 UI - 숫자패드와 LCH 조절 화면 묶음
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
		public var numClip:SimpleButton;
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
		public var numClipText:TextField = numClipText;

		private var numHexCopyTextBGDefaultColor:Array = [0, 0xFFFFFF];
		private var numHexCopyColor:* = null;

		private const okLWrapper:Sprite = new Sprite();
		private var okLBitmap:Bitmap;
		private const okLSliderCursor:Shape = new Shape();
		private const okCWrapper:Sprite = new Sprite();
		private var okCBitmap:Bitmap;
		private const okCSliderCursor:Shape = new Shape();
		private const okHWrapper:Sprite = new Sprite();
		private var okHBitmap:Bitmap;
		private const okHSliderCusor:Shape = new Shape();

		private const sliderOffset:Number = 5.0;
		// 최대 C를 찾을 때 탐색을 시작하는 C. sRGB에서 가장 진한 색(마젠타)의 C가 약 0.3225라 조금 여유를 둠
		private const okMaxChromaSearchUpperBound:Number = 0.33;
		// L이 0이나 1에 가까워 최대 C가 이보다 작으면 S(최대 C 대비 비율)가 의미 없으므로 0으로 봄
		private const okMinimumMaxChromaForSaturation:Number = 0.001;
		// 범위 안 판정에서 선형 RGB 계산 오차를 허용하는 폭
		private const okGamutCheckTolerance:Number = 1e-7;
		// 범위 밖 색을 채널별로 잘라도 되는 OKLab 거리 한계 (CSS Color 4의 JND 값)
		private const okGamutMappingJND:Number = 0.02;
		// C 이분 탐색을 멈추는 폭 (CSS Color 4 값)
		private const okGamutMappingChromaEpsilon:Number = 0.0001;
		// 계산 중 선형 RGB 결과를 담아 두는 재사용 객체 (픽셀마다 객체를 만들지 않으려고)
		private const okLinearRGBBuffer:Object = {r: 0, g: 0, b: 0};
		private var okBaseHue:Number = 0;
		private var okBaseColor:uint = 0;
		// 조절 중인 색 {L, S, H}. S는 그 L과 H에서 표시 가능한 최대 C 대비 비율(0~1)이라 L, H를 바꿔도 범위를 벗어나지 않음
		private var okBaseColorLsh:Object;
		private var okPickedColor:uint = 0;

		private const previewBox:Sprite = new Sprite();
		private var onMouseMoveUpdateLCH:Function;
		private var onMouseUpFuncMain:Function;
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
			okLSliderCursor.graphics.clear();
			okLSliderCursor.graphics.lineStyle(1, 0xFFFFFF, 1.0, false, "normal", "none");
			okLSliderCursor.graphics.moveTo(0, 0);
			okLSliderCursor.graphics.lineTo(width, 0);
			okLWrapper.addChild(okLBitmap);
			okLWrapper.addChild(okLSliderCursor);
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
			okCSliderCursor.graphics.clear();
			okCSliderCursor.graphics.lineStyle(1, 0xFFFFFF, 1.0, false, "normal", "none");
			okCSliderCursor.graphics.moveTo(0, 0);
			okCSliderCursor.graphics.lineTo(width, 0);
			okCWrapper.addChild(okCBitmap);
			okCWrapper.addChild(okCSliderCursor);
			// 가운데 슬라이더는 C 값이 아니라 최대 C 대비 비율(S)을 조절함
			oklabCText.text = "S";
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
			okHSliderCusor.graphics.clear();
			okHSliderCusor.graphics.lineStyle(1, 0xFFFFFF, 1.0, false, "normal", "none");
			okHSliderCusor.graphics.moveTo(0, 0);
			okHSliderCusor.graphics.lineTo(width, 0);
			okHWrapper.addChild(okHBitmap);
			okHWrapper.addChild(okHSliderCusor);
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

		public function updateUIColor():void
		{
			numHexCopyTextBGDefaultColor[0] = UITheme.getToolBoxBGColor();
			numHexCopyTextBGDefaultColor[1] = UITheme.getToolBoxButtonUpBGColor();

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
					numClipText,
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
					numClip,
					oklchBG,
				];

			var i:uint;
			var len:uint = buttons.length;
			var btn:SimpleButton;
			var btnUp:DisplayObject;
			var btnOver:DisplayObject;

			for (i = 0;i < len;i++)
			{
				btn = buttons[i];
				btnUp = btn.upState as DisplayObject;
				btnOver = btn.overState as DisplayObject;

				UITheme.applyToolBoxBGColor(btnUp);
				UITheme.applyToolBoxButtonOverBGColor(btnOver);
				btn.downState = btnOver;
			}

			len = texts.length;

			for (i = 0;i < len;i++)
			{
				texts[i].textColor = UITheme.getToolBoxButtonUpBGColor();
			}
		}

		private function initOkLchSliderPos(lsh:Object):void
		{
			const height:Number = okLBitmap.bitmapData.height;
			const lpos:Number = height - lsh.L * height;
			const cpos:Number = height - lsh.S * height;
			const hpos:Number = height - (lsh.H / 360.0) * height;

			okLSliderCursor.y = lpos + sliderOffset;
			okCSliderCursor.y = cpos + sliderOffset;
			okHSliderCusor.y = hpos + sliderOffset;
		}

		public function updateOkBaseColor(color:uint):void
		{
			okBaseColor = color;
			okBaseColorLsh = hexToOklsh(color);
			if (isBaseColorNearGray())
			{
				okBaseColorLsh.H = okBaseHue;
			}

			initOkLchSliderPos(okBaseColorLsh);

			updateOKGradient(true, true, true);
		}

		public function readyLCHAdjustment(purehue:uint, color:uint):void
		{
			visible = true;
			okBaseHue = hexToOklch(purehue).H;
			updateOkBaseColor(color);
			checkClipBoardHexColor();
		}

		public function off():void
		{
			visible = false;
		}

		private function updateHexCopyBGColor(color:uint):void
		{
			const c:ColorTransform = numClip.transform.colorTransform;
			c.color = color;
			const btnUp:DisplayObject = numClip.upState as DisplayObject;
			const btnOver:DisplayObject = numClip.overState as DisplayObject;
			const btnDown:DisplayObject = numClip.downState as DisplayObject;
			numClip.downState = btnOver;
			btnUp.transform.colorTransform = c;
			btnOver.transform.colorTransform = c;
			btnDown.transform.colorTransform = c;
		}

		private function isHexFormatColor(str:String):Boolean
		{
			const pattern:RegExp = /^#?[0-9a-fA-F]{6}$/;
			return pattern.test(str);
		}

		private function checkClipBoardHexColor():void
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
				const textcolor:uint = UITheme.getInvertedColor(hexcolor);
				numHexCopyColor = hexcolor;
				updateHexCopyBGColor(hexcolor);
				numClipText.text = "#" + colorstr;
				numClipText.textColor = textcolor;
			}
			else
			{
				numHexCopyColor = null;
				updateHexCopyBGColor(numHexCopyTextBGDefaultColor[0]);
				numClipText.text = "No value copied";
				numClipText.textColor = numHexCopyTextBGDefaultColor[1];
			}
		}

		public function getClipboardColor():*
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

		// 세제곱근. Math.pow는 음수에 NaN을 주므로 부호를 따로 처리함
		private function cubeRoot(x:Number):Number
		{
			return (x < 0) ? -Math.pow(-x, 1 / 3) : Math.pow(x, 1 / 3);
		}

		private function rgbToOklab(r:Number, g:Number, b:Number):Object
		{
			return linearSRGBToOklab(gammaToLinear(r / 255), gammaToLinear(g / 255), gammaToLinear(b / 255));
		}

		// 선형 sRGB(0~1)를 OKLab으로 바꿈
		private function linearSRGBToOklab(r:Number, g:Number, b:Number):Object
		{
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

		// OKLab 값을 자르지 않은 선형 sRGB(0~1 밖일 수 있음)로 바꿔 outLinearRGB에 채움
		private function oklabToLinearSRGB(L:Number, a:Number, b:Number, outLinearRGB:Object):void
		{
			var l:Number = L + a * 0.3963377774 + b * 0.2158037573;
			var m:Number = L - a * 0.1055613458 - b * 0.0638541728;
			var s:Number = L - a * 0.0894841775 - b * 1.2914855480;

			l = l * l * l;
			m = m * m * m;
			s = s * s * s;

			outLinearRGB.r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
			outLinearRGB.g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s;
			outLinearRGB.b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s;
		}

		// OKLab 값을 0~255 sRGB로 바꿈. 범위 밖 값은 채널별로 잘리므로 크게 벗어난 값은 먼저 C를 줄여서 넘겨야 색이 틀어지지 않음
		private function oklabToSRGB(L:Number, a:Number, b:Number):Object
		{
			oklabToLinearSRGB(L, a, b, okLinearRGBBuffer);

			const r:Number = Math.round(clamp(255 * linearToGamma(okLinearRGBBuffer.r), 0, 255));
			const g:Number = Math.round(clamp(255 * linearToGamma(okLinearRGBBuffer.g), 0, 255));
			const bb:Number = Math.round(clamp(255 * linearToGamma(okLinearRGBBuffer.b), 0, 255));

			return {r: r, g: g, b: bb};
		}

		// 주어진 L, C, H가 sRGB로 표시 가능한 범위 안인지 확인 (hueCos, hueSin은 H의 cos/sin)
		private function isOklchInsideSRGBGamut(L:Number, C:Number, hueCos:Number, hueSin:Number):Boolean
		{
			oklabToLinearSRGB(L, C * hueCos, C * hueSin, okLinearRGBBuffer);
			const minValue:Number = -okGamutCheckTolerance;
			const maxValue:Number = 1.0 + okGamutCheckTolerance;

			return okLinearRGBBuffer.r >= minValue && okLinearRGBBuffer.r <= maxValue
				&& okLinearRGBBuffer.g >= minValue && okLinearRGBBuffer.g <= maxValue
				&& okLinearRGBBuffer.b >= minValue && okLinearRGBBuffer.b <= maxValue;
		}

		// 주어진 L, C, H를 채널별로 잘랐을 때 원래 값과 OKLab에서 얼마나 떨어지는지(deltaEOK) 계산
		private function measureOklchClippingDistance(L:Number, C:Number, hueCos:Number, hueSin:Number):Number
		{
			const a:Number = C * hueCos;
			const b:Number = C * hueSin;
			oklabToLinearSRGB(L, a, b, okLinearRGBBuffer);
			const clipped:Object = linearSRGBToOklab(
					clamp(okLinearRGBBuffer.r, 0, 1),
					clamp(okLinearRGBBuffer.g, 0, 1),
					clamp(okLinearRGBBuffer.b, 0, 1));
			const dL:Number = clipped.L - L;
			const da:Number = clipped.a - a;
			const db:Number = clipped.b - b;
			return Math.sqrt(dL * dL + da * da + db * db);
		}

		// L과 H는 그대로 두고 C를 줄여 sRGB로 표시할 C를 찾음 (CSS Color 4 gamut mapping 방식)
		// 잘라도 눈에 띄지 않는 차이(JND 미만)면 그 C를 그대로 돌려주고, 이후 oklabToSRGB의 채널별 자르기가 마무리함
		// 파랑처럼 C를 줄이는 선이 범위 밖으로 잠깐 나갔다 꼭짓점에서 다시 들어오는 경우도 이 허용 덕분에 C가 크게 깎이지 않음
		private function findInGamutChromaKeepingLightnessAndHue(L:Number, C:Number, H:Number):Number
		{
			if (L <= 0.0 || L >= 1.0)
			{
				return 0.0;
			}

			const hueRadian:Number = H * Math.PI / 180;
			const hueCos:Number = Math.cos(hueRadian);
			const hueSin:Number = Math.sin(hueRadian);

			if (isOklchInsideSRGBGamut(L, C, hueCos, hueSin))
			{
				return C;
			}
			if (measureOklchClippingDistance(L, C, hueCos, hueSin) < okGamutMappingJND)
			{
				return C;
			}

			var minChroma:Number = 0.0;
			var maxChroma:Number = C;
			var isMinChromaInsideGamut:Boolean = true;

			while (maxChroma - minChroma > okGamutMappingChromaEpsilon)
			{
				var chroma:Number = (minChroma + maxChroma) / 2;
				if (isMinChromaInsideGamut && isOklchInsideSRGBGamut(L, chroma, hueCos, hueSin))
				{
					minChroma = chroma;
					continue;
				}

				var clippingDistance:Number = measureOklchClippingDistance(L, chroma, hueCos, hueSin);
				if (clippingDistance < okGamutMappingJND)
				{
					if (okGamutMappingJND - clippingDistance < okGamutMappingChromaEpsilon)
					{
						return chroma;
					}
					isMinChromaInsideGamut = false;
					minChroma = chroma;
				}
				else
				{
					maxChroma = chroma;
				}
			}
			return minChroma;
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

		// OKLCH 값을 hex 색으로 바꿈. 범위 밖이면 L과 H를 지키고 C를 줄여서 표시 가능한 색으로 만듦
		private function OklchToHex(oklch:Object):uint
		{
			const inGamutChroma:Number = findInGamutChromaKeepingLightnessAndHue(oklch.L, oklch.C, oklch.H);
			const ok:Object = oklchToOklab(oklch.L, inGamutChroma, oklch.H);
			const c:Object = oklabToSRGB(ok.L, ok.a, ok.b);
			return rgbToHex(c);
		}

		private function hexToOklch(color:uint):Object
		{
			const c:Object = hexToRGB(color);
			const ok:Object = rgbToOklab(c.r, c.g, c.b);

			return oklabToOklch(ok.L, ok.a, ok.b);
		}

		// 주어진 L과 H에서 sRGB로 표시할 수 있는 가장 큰 C (잘라도 눈에 띄지 않는 JND 허용 포함)
		private function findMaxChromaAtLightnessAndHue(L:Number, H:Number):Number
		{
			return findInGamutChromaKeepingLightnessAndHue(L, okMaxChromaSearchUpperBound, H);
		}

		// hex 색을 {L, S, H}로 바꿈. S는 그 L과 H에서의 최대 C 대비 비율(0~1)
		private function hexToOklsh(color:uint):Object
		{
			const lch:Object = hexToOklch(color);
			const maxChroma:Number = findMaxChromaAtLightnessAndHue(lch.L, lch.H);
			const S:Number = (maxChroma < okMinimumMaxChromaForSaturation) ? 0.0 : Math.min(lch.C / maxChroma, 1.0);
			return {L: lch.L, S: S, H: lch.H};
		}

		// {L, S, H}를 hex 색으로 바꿈. C = S × 최대 C라 항상 표시 가능한 범위 안에 있음
		private function OklshToHex(lsh:Object):uint
		{
			const C:Number = lsh.S * findMaxChromaAtLightnessAndHue(lsh.L, lsh.H);
			return OklchToHex({L: lsh.L, C: C, H: lsh.H});
		}

		private function onMouseUpOKLCH(e:MouseEvent):void
		{
			removeOKLCHMouseEvent();
		}

		private function onMouseMoveOKLCH(e:MouseEvent):void
		{
			onMouseMoveUpdateLCH();
			const hexColor:uint = OklshToHex(okBaseColorLsh);
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

			// onMouseUpFuncMain(okPickedColor);
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
			onMouseUpFuncMain(okPickedColor);
			onMouseMoveUpdateLCH = null;
			onMouseUpFuncMain = null;
			hideClorPreviewBox();
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveOKLCH);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpOKLCH);
		}

		private function addOKLCHMouseEvent():void
		{
			showColorPreviewBox();
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveOKLCH);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpOKLCH, false, InputPriority.DEFAULT);
		}

		public function startAdjustLCH(index:int, onMouseUpFunc:Function):void
		{
			if (index < 0 || index > 2)
			{
				return;
			}

			const onMouseMoveFuncs:Array = [updateL, updateS, updateH];
			clickedWrapperFlag = index;
			onMouseMoveUpdateLCH = onMouseMoveFuncs[index];
			onMouseUpFuncMain = onMouseUpFunc;
			showColorPreviewBox();

			onMouseMoveUpdateLCH();
			const hexColor:uint = OklshToHex(okBaseColorLsh);
			okPickedColor = hexColor;
			updateColorPreviewBox(hexColor);
			addOKLCHMouseEvent();
		}

		private function updateL():void
		{
			const ypos:Number = clamp(okLBitmap.mouseY, 0.0, okLBitmap.bitmapData.height - 1.0);
			const value:Number = 1.0 - ypos / okLBitmap.bitmapData.height;
			okBaseColorLsh.L = value;
			okLSliderCursor.y = ypos + sliderOffset;
		}

		// 가운데 슬라이더 위치로 S(최대 C 대비 비율, 0~1)를 정함
		private function updateS():void
		{
			const ypos:Number = clamp(okCBitmap.mouseY, 0.0, okCBitmap.bitmapData.height - 1.0);
			const value:Number = 1.0 - ypos / okCBitmap.bitmapData.height;
			okBaseColorLsh.S = value;
			okCSliderCursor.y = ypos + sliderOffset;
		}

		private function updateH():void
		{
			const ypos:Number = clamp(okHBitmap.mouseY, 0.0, okHBitmap.bitmapData.height - 1.0);
			const value:Number = 360.0 - 360.0 * (ypos / okHBitmap.bitmapData.height);
			okBaseColorLsh.H = value;
			okHSliderCusor.y = ypos + sliderOffset;
		}

		// 기준 색이 회색이거나, 채널 차이가 1 이하라 hex 반올림 때문에 H가 의미 없는 회색에 가까운 색인지 확인
		private function isBaseColorNearGray():Boolean
		{
			const rgb:Object = hexToRGB(okBaseColor);
			const maxChannel:int = Math.max(rgb.r, rgb.g, rgb.b);
			const minChannel:int = Math.min(rgb.r, rgb.g, rgb.b);
			return maxChannel - minChannel <= 1;
		}

		// 조절 중인 색에서 L, S, H 중 하나(flag 0/1/2)만 value로 바꾼 hex 색
		private function getAdjustedBaseColor(flag:int, value:Number):uint
		{
			const lsh:Object = {L: okBaseColorLsh.L, S: okBaseColorLsh.S, H: okBaseColorLsh.H};
			const props:Array = ["L", "S", "H"];
			lsh[props[flag]] = value;
			return OklshToHex(lsh);
		}

		// 조절 중인 색에서 S만 바꾼 hex 색. L, H가 같으면 최대 C도 같으므로 미리 구한 maxChroma를 받음
		private function getSaturationAdjustedBaseColor(saturation:Number, maxChroma:Number):uint
		{
			return OklchToHex({L: okBaseColorLsh.L, C: saturation * maxChroma, H: okBaseColorLsh.H});
		}

		private function updateOKGradient(lflag:Boolean, cflag:Boolean, hflag:Boolean):void
		{
			const height:int = okLBitmap.bitmapData.height;
			const configs:Array =
				[
					{flag: lflag, bmpd: okLBitmap.bitmapData, max: 1.0, step: 1.0 / height, idx: 0},
					{flag: cflag, bmpd: okCBitmap.bitmapData, max: 1.0, step: 1.0 / height, idx: 1},
					{flag: hflag, bmpd: okHBitmap.bitmapData, max: 360.0, step: 360.0 / height, idx: 2}
				];

			// S 그라데이션은 L, H가 고정이라 최대 C를 한 번만 구함
			const saturationGradientMaxChroma:Number = cflag ? findMaxChromaAtLightnessAndHue(okBaseColorLsh.L, okBaseColorLsh.H) : 0.0;

			for each (var cfg:Object in configs)
			{
				if (cfg.flag)
				{
					cfg.bmpd.lock();
					for (var i:int = height;i >= 0;i--)
					{
						var value:Number = cfg.max - cfg.step * i;
						var color:uint = (cfg.idx == 1)
							? getSaturationAdjustedBaseColor(value, saturationGradientMaxChroma)
							: getAdjustedBaseColor(cfg.idx, value);
						cfg.bmpd.setPixel(0, i, color);
					}
					cfg.bmpd.unlock();
				}
			}
		}

		private function hideClorPreviewBox():void
		{
			previewBox.visible = false;
			previewBox.graphics.clear();
		}

		private function updateColorPreviewBox(color:uint):void
		{
			previewBox.graphics.clear();
			previewBox.graphics.beginFill(color);
			previewBox.graphics.drawRect(0, 0, 27, 17);
			previewBox.graphics.beginFill(okBaseColor);
			previewBox.graphics.drawRect(27, 0, 27, 17);
			previewBox.graphics.endFill();
		}

		private function showColorPreviewBox():void
		{
			previewBox.visible = true;
		}

		[Embed(source="legacyUISet.swf",symbol="NumPadSet")]
		private static const EmbeddedClass:Class;

		public function NumPadSet()
		{
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this, EmbeddedClass, fields);

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
			numClipText.mouseEnabled = false;
			initOkLCHSlider();
		}
	}
}
