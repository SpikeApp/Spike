package  ui.chart.visualcomponents 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	
	import feathers.controls.PanelScreen;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.Button;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	
	import utils.Constants;
	import utils.DeviceInfo;

	public class ColorPicker extends Sprite
	{
		//Assets
		[Embed(source = "../../../assets/images/paletteiOS.png")]
		private static const Palette:Class;
		
		//Events
		public static const CHANGED:String = "changed";
		public static const PALETTE_OPEN:String = "paletteOpened";
		public static const PALETTE_CLOSE:String = "paletteClose";
		//public static const CHANGING:String = "changing";
		
		//Animation
		private var tween:Tween;
		
		//Color
		private var _value:uint;
		public var currentValue:uint;
		
		//Display Objects
		private var baseButton:Button;
		private var baseButtonTexture:Texture;
		private var _parent:PanelScreen;
		
		//GFX Manipulation
		private var paletteBMD:BitmapData;
		private var bitmap:Bitmap;
		public var palette:Image;
		
		//Visual Variables
		private var displaySize:int;
		private var initialColor:uint;
		private var hAlign:String;
		private var vAlign:String;
		
		//Touch
		private var touches:Vector.<Touch>;
		private var m_TouchEndedPoint:Point;
		private var m_TouchTarget:DisplayObject;
		private var touch:Touch;
		
		public function ColorPicker(displaySize:int, initialColor:uint, parentContainer:PanelScreen = null, hAlign:String = HorizontalAlign.LEFT, vAlign:String = VerticalAlign.BOTTOM)
		{
			this.displaySize = displaySize;
			this.initialColor = initialColor;
			this._parent = parentContainer;
			this.hAlign = hAlign;
			this.vAlign = vAlign;
			
			bitmap = new Palette();
			paletteBMD = bitmap.bitmapData;
			
			init();
		}
		
		private function init():void 
		{
			//Initialize Palette
			palette = new Image(Texture.fromBitmapData(paletteBMD));
			palette.scaleX = palette.scaleY = DeviceInfo.getSizeMultipier();
			palette.visible = false;
			
			//Initialize Button
			baseButtonTexture = Texture.fromColor(displaySize, displaySize, initialColor);
			baseButton = new Button(baseButtonTexture);
			baseButton.addEventListener(Event.TRIGGERED, showHidePalette);
			addChild(baseButton);
			
			//Position Palette
			if(_parent != null)
				_parent.addChild(palette);
			else
				addChild(palette);
		}
		
		private function onStageTouch (e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			
			if(touch != null && touch.phase == TouchPhase.BEGAN)
			{
				if(palette.visible)
				{
					var paletteGlobalPosition:Point = palette.localToGlobal(new Point(0, 0));
					var paletteGlobalRectangle:Rectangle = new Rectangle(paletteGlobalPosition.x, paletteGlobalPosition.y, palette.width, palette.height);
					if (!paletteGlobalRectangle.containsPoint(new Point(touch.globalX, touch.globalY)))
						hidePalette();//palette.visible = false;
				}
				
			}
		}
		
		private function setPositionPallete():void 
		{
			//Calculate Local To Global Coordinates
			var globalPoint:Point; 
			if(hAlign == HorizontalAlign.LEFT && vAlign == VerticalAlign.BOTTOM)
				globalPoint = baseButton.localToGlobal(new Point(baseButton.width*2, -baseButton.height*2));
			else if (hAlign == HorizontalAlign.RIGHT && vAlign == VerticalAlign.BOTTOM)
				globalPoint = baseButton.localToGlobal(new Point(-baseButton.width, -baseButton.height*2));
			else if (hAlign == HorizontalAlign.RIGHT && vAlign == VerticalAlign.TOP)
				globalPoint = baseButton.localToGlobal(new Point(-baseButton.width, -baseButton.height*2.5));
			else if (hAlign == HorizontalAlign.LEFT && vAlign == VerticalAlign.TOP)
				globalPoint = baseButton.localToGlobal(new Point(baseButton.width*2, -baseButton.height*2.5));
			
			//Palette horizontal align
			if (hAlign == HorizontalAlign.RIGHT)
				palette.x = globalPoint.x + baseButton.width;
			else if (hAlign == HorizontalAlign.LEFT)
				palette.x = globalPoint.x - baseButton.width - palette.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
			
			//Palette vertical align
			if (vAlign == VerticalAlign.TOP) 
			{
				palette.y = globalPoint.y - palette.height - baseButton.height + _parent.verticalScrollPosition - 8;
			}
			else if (vAlign == VerticalAlign.BOTTOM) 
			{
				palette.y = globalPoint.y + _parent.verticalScrollPosition;
			}
			
			if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
			{
				palette.y -= 30;
			}
		}
		
		private function getColor(_x:int,_y:int):void 
		{
			//Get current color value
			currentValue = paletteBMD.getPixel(_x, _y);
			
			//Set button color to current color
			baseButtonTexture.dispose();
			baseButtonTexture = null;
			baseButtonTexture = Texture.fromColor(displaySize, displaySize, currentValue);
			baseButton.upState = baseButtonTexture;
		}
		
		public function set value(c:uint):void 
		{
			_value = c;
		}
		
		public function get value():uint 
		{
			return _value;
		}
		
		public function setColor(color:uint):void
		{
			baseButtonTexture.dispose();
			baseButtonTexture = null;
			baseButtonTexture = Texture.fromColor(displaySize, displaySize, color);
			baseButton.upState = baseButtonTexture;
		}
		
		public function showPalette():void 
		{			
			//Event Listener
			Starling.current.stage.addEventListener(TouchEvent.TOUCH, onStageTouch);
			
			//Determine location of palette
			var buttonGlobalPosition:Point = this.localToGlobal(new Point(0, 0));
			if (buttonGlobalPosition.y + palette.height < Constants.stageHeight - 35)
				this.vAlign = VerticalAlign.BOTTOM;
			else
				this.vAlign = VerticalAlign.TOP;
			
			setPositionPallete();
			tween = new Tween(palette, 0.2);
			palette.alpha = 0;
			palette.visible=true;
			tween.fadeTo(1);
			Starling.juggler.add(tween);
			tween.onComplete = function():void
			{
				Starling.juggler.remove(tween);
				palette.addEventListener(TouchEvent.TOUCH, onTouchPalette);
			};
			
			dispatchEvent(new Event(PALETTE_OPEN, false, {name: this.name}));
		}
		
		public function hidePalette():void 
		{
			//Event Listener
			Starling.current.stage.removeEventListener(TouchEvent.TOUCH, onStageTouch);
			
			tween = new Tween(palette, 0.2);
			palette.alpha = 1;
			palette.visible=true;
			tween.fadeTo(0);
			Starling.juggler.add(tween);
			tween.onComplete = function():void
			{
				Starling.juggler.remove(tween);
				palette.removeEventListener(TouchEvent.TOUCH, onTouchPalette);
				palette.visible=false;
			};
			
			dispatchEvent(new Event(PALETTE_CLOSE, false, {name: this.name}));
		}
		
		private function showHidePalette(e:Event):void 
		{
			palette.visible?hidePalette():showPalette();
		}
		
		private function onTouchPalette(e:TouchEvent):void 
		{
			touches = e.getTouches(stage);
			if (touches.length == 1)
			{
				touch = touches[0];
				m_TouchEndedPoint = new Point(touch.globalX, touch.globalY);
				if (touch.phase == TouchPhase.BEGAN)
				{
					m_TouchTarget = touch.target;
					touch.getLocation(palette, m_TouchEndedPoint);
					getColor(int(m_TouchEndedPoint.x), int(m_TouchEndedPoint.y));
				}
				if (touch.phase == TouchPhase.ENDED)
				{
					if (stage.hitTest(m_TouchEndedPoint) == m_TouchTarget)
					{
						value = currentValue;
						baseButton.upState = Texture.fromColor(displaySize, displaySize, currentValue);
						dispatchEvent(new Event(CHANGED, false, {name:this.name, color:currentValue}));
						hidePalette();
					}
				}
				if (touch.phase == TouchPhase.MOVED)
				{
					if (stage.hitTest(m_TouchEndedPoint) == m_TouchTarget)
					{
						touch.getLocation(palette, m_TouchEndedPoint);
						getColor(int(m_TouchEndedPoint.x), int(m_TouchEndedPoint.y));
					}
				}
			}
		}
		
		override public function dispose():void
		{
			Starling.current.stage.addEventListener(TouchEvent.TOUCH, onStageTouch);
			
			if (palette != null)
			{
				palette.removeEventListener(TouchEvent.TOUCH, onTouchPalette);
				if (palette.texture != null)
				{
					palette.texture.dispose();
					palette.texture = null;
				}
				palette.dispose();
				palette = null;
			}
			
			if (baseButtonTexture != null)
			{
				baseButtonTexture.dispose();
				baseButtonTexture = null;
			}
			
			if (baseButton != null)
			{
				baseButton.removeEventListener(Event.TRIGGERED, showHidePalette);
				baseButton.dispose();
				baseButton = null;
			}
			
			if (bitmap != null)
				bitmap = null;
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}