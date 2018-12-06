package ui.chart.pills
{
	import database.CommonSettings;
	
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.display.Sprite;
	
	import ui.screens.display.LayoutFactory;
	import ui.shapes.SpikeCanvas;
	
	public class ChartInfoPill extends Sprite
	{
		/* Constants */
		private static const PADDING:int = 5;
		private static const CORNER_RADIUS:int = 4;
		private static const STROKE_THICKNESS:int = 1;
		
		/* Properties */
		public var value:String = "";
		public var unit:String = "";
		private var fontSize:Number;
		private var selectedColor:uint;
		private var fontColor:uint;
		private var oldColor:uint;
		
		/* Display Objects */
		private var pillBackground:SpikeCanvas;
		private var valueBackground:SpikeCanvas;
		private var unitLabel:Label;
		private var valueLabel:Label;
		
		public function ChartInfoPill(fontSize:Number)
		{
			this.fontSize = fontSize;
			fontColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_FONT_COLOR));
			oldColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_OLD_DATA_COLOR));
		}
		
		public function setValue(value:String, unit:String, color:uint):void
		{
			this.value = value;
			this.unit = unit;
			this.selectedColor = color;
			
			drawPill();
		}
		
		private function drawPill():void
		{
			//Discart previous display objects
			discard();
			
			if (this.value == "" && this.unit == "")
				return;
			
			//Create Title Label
			var unitWidth:Number = 0;
			if (unit != "")
			{
				unitLabel = LayoutFactory.createLabel(unit, HorizontalAlign.CENTER, VerticalAlign.TOP, fontSize, false,  0x20222a);
				unitLabel.validate();
				unitWidth = unitLabel.width;
			}
			
			//Create Value Label
			valueLabel = LayoutFactory.createLabel(value, HorizontalAlign.CENTER, VerticalAlign.TOP, fontSize, false,  selectedColor);
			valueLabel.validate();
			
			//Calculate Dimensions
			var pillWidth:Number
			if (unit != "")
				pillWidth = unitWidth + (2 * PADDING) + valueLabel.width + (2 * PADDING);
			else
				pillWidth = valueLabel.width + (2 * PADDING) + (2 * STROKE_THICKNESS);
			
			var valueBackgroundWidth:Number = valueLabel.width + (2 * PADDING);
			var valueBackgroundHeight:Number = valueLabel.height + (1 * PADDING);
			
			//Pill Background
			pillBackground = new SpikeCanvas();
			pillBackground.beginFill(selectedColor, 1);
			pillBackground.drawRoundRectangle(0, 0, pillWidth, valueBackgroundHeight, CORNER_RADIUS, 10);
			
			//Value Background
			valueBackground = new SpikeCanvas();
			valueBackground.beginFill(0x20222a, 1);
			valueBackground.drawRoundRectangle(STROKE_THICKNESS, STROKE_THICKNESS, valueBackgroundWidth, valueBackgroundHeight - (2 * STROKE_THICKNESS), CORNER_RADIUS, 10);
			
			//Position and Scale Objects
			if (unit != "")
			{
				unitLabel.x = valueBackgroundWidth;
				unitLabel.y = (valueBackgroundHeight / 2) - (unitLabel.height / 2) - (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? 0.5 : 0);
				unitLabel.width = pillWidth - valueBackgroundWidth;
			}
			
			valueLabel.x = 0;
			valueLabel.y = (valueBackgroundHeight / 2) - (valueLabel.height / 2);
			valueLabel.width = valueBackgroundWidth;
			
			//Add Objects to Display List
			addChild(pillBackground);
			addChild(valueBackground);
			if (unit != "")
				addChild(unitLabel);
			addChild(valueLabel);
		}
		
		private function discard():void
		{
			if (unitLabel != null)
			{
				removeChild(unitLabel);
				unitLabel.dispose();
				unitLabel = null;
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
			
			if (unitLabel != null)
			{
				unitLabel.removeFromParent();
				unitLabel.dispose();
				unitLabel = null;
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