package ui.chart
{
	
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.display.Shape;
	import starling.display.Sprite;
	
	import ui.screens.display.LayoutFactory;
	
	public class ChartPill extends Sprite
	{
		/* Constants */
		public static const TYPE_IOB:String = "IOB";
		public static const TYPE_COB:String = "COB";
		private static const PADDING:int = 3;
		private static const PILL_HEIGHT:int = 20;
		private static const CORNER_RADIUS:int = 3;
		private static const STROKE_THICKNESS:int = 1;
		
		/* Properties */
		private var type:String;
		private var value:String = "";

		/* Display Objects */
		private var pillBackground:Shape;
		private var valueBackground:Shape;
		private var titleLabel:Label;
		private var valueLabel:Label;
		
		public function ChartPill(type:String)
		{
			this.type = type;
		}
		
		/*public function ChartPill(type:String, pillWidth:Number, pillHeight:Number)
		{
			this.type = type;
			
			drawPill();
			
			var valueBackgroundWidth:Number = 33;
			var strokeThickness:Number = 1;
				
			if (type == TYPE_IOB)
			{
				var pillBackground:Shape = new Shape();
				pillBackground.graphics.beginFill(0xEEEEEE, 1);
				pillBackground.graphics.drawRoundRect(0, 0, pillWidth, pillHeight, 3);
				addChild(pillBackground);
				
				var valueBackground:Shape = new Shape();
				valueBackground.graphics.beginFill(0x20222a, 1);
				valueBackground.graphics.drawRoundRect(pillWidth - valueBackgroundWidth - strokeThickness, strokeThickness, valueBackgroundWidth, pillHeight - (2 * strokeThickness), 3);
				addChild(valueBackground);
				
				var title:Label = LayoutFactory.createLabel("IOB", HorizontalAlign.CENTER, VerticalAlign.TOP, 11, true,  0x20222a);
				title.validate();
				title.x = 0;
				title.y = (pillHeight / 2) - (title.height / 2);
				title.width = pillWidth - valueBackgroundWidth;
				addChild(title);
				
				valueLabel = LayoutFactory.createLabel("60.34U", HorizontalAlign.CENTER, VerticalAlign.TOP, 11, false, 0xEEEEEE);
				valueLabel.validate();
				valueLabel.x = pillWidth - valueBackgroundWidth - strokeThickness;
				valueLabel.y = (pillHeight / 2) - (title.height / 2);
				valueLabel.width = valueBackgroundWidth;
				addChild(valueLabel);
			}
		}*/
		
		public function setValue(value:String):void
		{
			this.value = value;
			drawPill();
		}
		
		private function drawPill():void
		{
			//Discart previous display objects
			discart();
			
			//Create Title Label
			titleLabel = LayoutFactory.createLabel(type, HorizontalAlign.CENTER, VerticalAlign.TOP, 11, true,  0x20222a);
			titleLabel.validate();
			
			//Create Value Label
			valueLabel = LayoutFactory.createLabel(value, HorizontalAlign.CENTER, VerticalAlign.TOP, 11, true,  0xEEEEEE);
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
		
		private function discart():void
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