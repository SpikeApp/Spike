package ui.chart
{
	
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.display.Shape;
	import starling.display.Sprite;
	
	import ui.screens.display.LayoutFactory;
	
	public class ChartTreatmentPill extends Sprite
	{
		/* Constants */
		public static const TYPE_IOB:String = "IOB";
		public static const TYPE_COB:String = "COB";
		private static const PADDING:int = 3;
		private static const FONT_SIZE:int = 16;
		private static const PILL_HEIGHT:int = 25;
		private static const CORNER_RADIUS:int = 4;
		private static const STROKE_THICKNESS:int = 1;
		
		/* Properties */
		private var type:String;
		private var value:String = "";

		/* Display Objects */
		private var pillBackground:Shape;
		private var valueBackground:Shape;
		private var titleLabel:Label;
		private var valueLabel:Label;
		
		public function ChartTreatmentPill(type:String)
		{
			this.type = type;
		}
		
		public function setValue(value:String):void
		{
			this.value = value;
			
			drawPill();
		}
		
		private function drawPill():void
		{
			//Discart previous display objects
			discard();
			
			//Create Title Label
			titleLabel = LayoutFactory.createLabel(type, HorizontalAlign.CENTER, VerticalAlign.TOP, FONT_SIZE, false,  0x20222a);
			titleLabel.validate();
			
			//Create Value Label
			valueLabel = LayoutFactory.createLabel(value, HorizontalAlign.CENTER, VerticalAlign.TOP, FONT_SIZE, false,  0xEEEEEE);
			valueLabel.validate();
			
			//Calculate Dimensions
			var pillWidth:Number = titleLabel.width + (2 * PADDING) + valueLabel.width + (2 * PADDING);
			var valueBackgroundWidth:Number = valueLabel.width + (2 * PADDING);
			
			//Pill Background
			pillBackground = new Shape();
			pillBackground.graphics.beginFill(0xEEEEEE, 1);
			pillBackground.graphics.drawRoundRect(0, 0, pillWidth, PILL_HEIGHT, CORNER_RADIUS);
			
			//Value Background
			valueBackground = new Shape();
			valueBackground.graphics.beginFill(0x20222a, 1);
			valueBackground.graphics.drawRoundRect(pillWidth - valueBackgroundWidth - STROKE_THICKNESS, STROKE_THICKNESS, valueBackgroundWidth, PILL_HEIGHT - (2 * STROKE_THICKNESS), CORNER_RADIUS);
			
			//Position and Scale Objects
			titleLabel.x = 0;
			titleLabel.y = (PILL_HEIGHT / 2) - (titleLabel.height / 2);
			titleLabel.width = pillWidth - valueBackgroundWidth;
			
			valueLabel.x = pillWidth - valueBackgroundWidth - STROKE_THICKNESS;
			valueLabel.y = (PILL_HEIGHT / 2) - (titleLabel.height / 2);
			valueLabel.width = valueBackgroundWidth;
			
			//Add Objects to Display List
			addChild(pillBackground);
			addChild(valueBackground);
			addChild(titleLabel);
			addChild(valueLabel);
		}
		
		private function discard():void
		{
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
	}
}