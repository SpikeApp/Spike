package ui.chart.pills
{
	import database.CommonSettings;
	
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.display.Sprite;
	import starling.utils.SystemUtil;
	
	import ui.screens.display.LayoutFactory;
	import ui.shapes.SpikeCanvas;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	public class ChartTreatmentPill extends Sprite
	{
		/* Constants */
		public static const TYPE_IOB:String = "IOB";
		public static const TYPE_COB:String = "COB";
		private static const PADDING:int = 5;
		private static const CORNER_RADIUS:int = 4;
		private static const STROKE_THICKNESS:int = 1;
		
		/* Properties */
		private var type:String;
		private var value:String = "";
		private var treatmentPillColor:uint;
		private static var fontSize:int = 16;
		private static var pillHeight:int = 25;
		public var isPredictive:Boolean;
		
		/* Display Objects */
		private var pillBackground:SpikeCanvas;
		private var valueBackground:SpikeCanvas;
		private var titleLabel:Label;
		private var valueLabel:Label;
		
		public function ChartTreatmentPill(type:String, isPredictive:Boolean = false)
		{
			this.type = type;
			this.isPredictive = isPredictive;
			
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
		}
		
		public function setValue(value:String, title:String = null):void
		{
			this.value = value;
			if (title != null)
				type = title;
			
			treatmentPillColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_PILL_COLOR));
			
			drawPill();
		}
		
		private function drawPill():void
		{
			if (!SystemUtil.isApplicationActive)
			{
				return;
			}
			
			//Discart previous display objects
			discard();
			
			//Create Title Label
			titleLabel = LayoutFactory.createLabel(type, HorizontalAlign.CENTER, VerticalAlign.TOP, fontSize, false,  0x20222a);
			titleLabel.validate();
			
			//Create Value Label
			valueLabel = LayoutFactory.createLabel(value, HorizontalAlign.CENTER, VerticalAlign.TOP, fontSize, isPredictive,  !isPredictive ? treatmentPillColor : uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_DEFAULT_COLOR)));	
			valueLabel.validate();
			
			//Calculate Dimensions
			var pillWidth:Number = titleLabel.width + (2 * PADDING) + valueLabel.width + (2 * PADDING);
			var valueBackgroundWidth:Number = valueLabel.width + (2 * PADDING);
			
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
			
			valueLabel.x = pillWidth - valueBackgroundWidth - STROKE_THICKNESS;
			valueLabel.y = (pillHeight / 2) - (titleLabel.height / 2);
			valueLabel.width = valueBackgroundWidth;
			
			//Add Objects to Display List
			addChild(pillBackground);
			addChild(valueBackground);
			addChild(titleLabel);
			addChild(valueLabel);
		}
		
		public function colorizeLabel(labelColor:uint):void
		{
			if (valueLabel != null && valueLabel.fontStyles != null)
				valueLabel.fontStyles.color = labelColor;
		}
		
		private function discard():void
		{
			if (!SystemUtil.isApplicationActive)
			{
				return;
			}
			
			if (titleLabel != null)
			{
				removeChild(titleLabel);
				titleLabel.dispose();
				titleLabel = null;
			}
			
			if (valueLabel != null)
			{
				removeChild(valueLabel);
				valueLabel.dispose();
				valueLabel = null;
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
			if (!SystemUtil.isApplicationActive)
			{
				return;
			}
			
			if (pillBackground != null)
			{
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
				titleLabel.removeFromParent();
				titleLabel.dispose();
				titleLabel = null;
			}
			
			if (valueLabel != null)
			{
				valueLabel.removeFromParent();
				valueLabel.dispose();
				valueLabel = null;
			}
			
			super.dispose();
		}
	}
}