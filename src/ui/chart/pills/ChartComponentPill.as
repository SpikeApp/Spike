package ui.chart.pills
{
	import database.CommonSettings;
	
	import feathers.controls.Label;
	import feathers.core.FeathersControl;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.display.Sprite;
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	import ui.shapes.SpikeCanvas;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	public class ChartComponentPill extends Sprite
	{
		/* Constants */
		private static const PADDING:int = 5;
		private static const CORNER_RADIUS:int = 4;
		private static const STROKE_THICKNESS:int = 1;
		
		/* Properties */
		private var title:String;
		private var component:FeathersControl;
		private var treatmentPillColor:uint;
		private var extraPadding:int = 0;
		private static var fontSize:int = 16;
		private static var pillHeight:int = 25;
		
		/* Display Objects */
		public var pillBackground:SpikeCanvas;
		private var valueBackground:SpikeCanvas;
		public var titleLabel:Label;
		
		public function ChartComponentPill(title:String, component:FeathersControl, extraPadding:int = 0, listenForChangeEvents:Boolean = false)
		{
			this.title = title;
			this.component = component;
			if (listenForChangeEvents)
				this.component.addEventListener(Event.CHANGE, onComponentChanged);
			this.component.validate();
			this.extraPadding = extraPadding;
			this.treatmentPillColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_PILL_COLOR));
			
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
			{
				fontSize = 10;
				pillHeight = 18;
			}
			else if (Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
			{
				fontSize = 10.5;
				pillHeight = 19.5;
			}
			else if (Constants.deviceModel == DeviceInfo.IPHONE_6_6S_7_8)
			{
				fontSize = 12.5;
				pillHeight = 22;
			}
			else if (Constants.deviceModel == DeviceInfo.IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
			{
				fontSize = 12;
				pillHeight = 21;
			}
			else if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
			{
				fontSize = 10;
				pillHeight = 19;
			}
			else if (Constants.deviceModel == DeviceInfo.IPAD_MINI_1_2_3_4)
			{
				fontSize = 15;
				pillHeight = 24;
			}
			else if (Constants.deviceModel == DeviceInfo.IPAD_PRO_105)
			{
				fontSize = 24;
				pillHeight = 36;
			}
			else if (Constants.deviceModel == DeviceInfo.IPAD_PRO_129)
			{
				fontSize = 28;
				pillHeight = 40;
			}
			else if (Constants.deviceModel == DeviceInfo.IPAD_1_2_3_4_5_AIR1_2_PRO_97)
			{
				fontSize = 18;
				pillHeight = 30;
			}
			
			var userFontMultiplier:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_TIMEAGO_FONT_SIZE));
			if (!Constants.isPortrait && userFontMultiplier > 1)
				userFontMultiplier = 1;
			
			fontSize *= userFontMultiplier;
			pillHeight *= userFontMultiplier;
			
			drawPill();
		}
		
		private function drawPill():void
		{
			//Size Adjustments
			if (pillHeight < component.height + PADDING)
				pillHeight = component.height + PADDING;
			
			pillHeight += extraPadding;
			
			//Create Title Label
			titleLabel = LayoutFactory.createLabel(title, HorizontalAlign.CENTER, VerticalAlign.TOP, fontSize, false,  0x20222a);
			titleLabel.validate();
			
			//Calculate Dimensions
			var pillWidth:Number = titleLabel.width + (2 * PADDING) + component.width + (2 * PADDING);
			var valueBackgroundWidth:Number = component.width + (2 * PADDING);
			
			//Pill Background
			pillBackground = new SpikeCanvas();
			pillBackground.beginFill(treatmentPillColor, 1);
			pillBackground.drawRoundRectangle(0, 0, pillWidth, pillHeight, CORNER_RADIUS, 10);
			
			//Value Background
			valueBackground = new SpikeCanvas();
			valueBackground.beginFill(0x20222a, 1);
			valueBackground.drawRoundRectangle(pillWidth - valueBackgroundWidth - STROKE_THICKNESS, STROKE_THICKNESS, valueBackgroundWidth, pillHeight - (2 * STROKE_THICKNESS), CORNER_RADIUS, 10);
			
			//Position and Scale Objects
			titleLabel.x = 0;
			titleLabel.y = (pillHeight / 2) - (titleLabel.height / 2);
			titleLabel.width = pillWidth - valueBackgroundWidth;
			
			component.x = pillWidth - STROKE_THICKNESS - valueBackgroundWidth + ((valueBackgroundWidth - component.width) / 2);
			component.y = (pillHeight / 2) - (component.height / 2);
			
			//Add Objects to Display List
			addChild(pillBackground);
			addChild(valueBackground);
			addChild(titleLabel);
			addChild(component);
		}
		
		private function onComponentChanged(e:Event):void
		{
			this.component.validate();
			
			discard();
			
			extraPadding = 0;
			
			drawPill();
			
			dispatchEventWith(Event.UPDATE);
		}
		
		private function discard():void
		{
			if (titleLabel != null)
			{
				removeChild(titleLabel);
				titleLabel.dispose();
				titleLabel = null;
			}
			
			if (pillBackground != null)
			{
				removeChild(pillBackground);
				pillBackground.dispose();
				pillBackground = null;
			}
			
			if (valueBackground != null)
			{
				removeChild(valueBackground);
				valueBackground.dispose();
				valueBackground = null;
			}
		}
		
		override public function dispose():void
		{
			if (pillBackground != null)
			{
				pillBackground.removeEventListeners();
				pillBackground.removeFromParent();
				pillBackground.dispose();
				pillBackground = null;
			}
			
			if (valueBackground != null)
			{
				valueBackground.removeFromParent();
				valueBackground.dispose();
				valueBackground = null;
			}
			
			if (titleLabel != null)
			{
				titleLabel.removeEventListeners();
				titleLabel.removeFromParent();
				titleLabel.dispose();
				titleLabel = null;
			}
			
			if (component != null)
			{
				component.removeEventListener(Event.CHANGE, onComponentChanged);
				component.removeFromParent();
				component.dispose();
				component = null;
			}
			
			super.dispose();
		}
	}
}