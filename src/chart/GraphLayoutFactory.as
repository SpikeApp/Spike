package chart
{
    import feathers.controls.Label;
    import feathers.controls.text.TextFieldTextRenderer;
    import feathers.core.ITextRenderer;
    
    import starling.core.Starling;
    import starling.display.Shape;
    import starling.text.TextFormat;
    
    import utils.DeviceInfo;


public class GraphLayoutFactory
    {
        public function Axis():void{}

        public static function createVerticalLine(height:Number, thickness:int, color:uint):Shape
        {
            var line:Shape = new Shape();
            line.graphics.lineStyle(thickness, color);
            line.graphics.lineTo(0, height);

            return line;
        }
		
		public static function createHorizontalLine(width:Number, thickness:int, color:uint):Shape
		{
			var line:Shape = new Shape();
			line.graphics.lineStyle(thickness, color);
			line.graphics.lineTo(width, 0);
			
			return line;
		}

        public static function createHorizontalDashedLine(graphWidth:Number, lineWidth:int, lineGap:int, lineThickness:int, lineColor:uint, rightMargin:Number):Shape
        {
            var line:Shape = new Shape();
            var dashedLineTotalWidth:Number = graphWidth - lineThickness - rightMargin - 30;
            var numDashedLines:Number = Math.round(dashedLineTotalWidth/(lineWidth+lineGap));
            var currentLineX:Number = 0;
            line.graphics.lineStyle(lineThickness, lineColor);
            for(var i:int=0; i <numDashedLines; i++)
            {
                line.graphics.moveTo(currentLineX, 0);
                line.graphics.lineTo(currentLineX + lineWidth, 0);
                currentLineX += lineWidth + lineGap;
            }

            return line;
        }
    
        public static function createVerticalDashedLine(grapHeight:Number, lineHeight:int, lineGap:int, lineThickness:int, lineColor:uint):Shape
        {
            var line:Shape = new Shape();
            var dashedLineTotalHeight:Number = grapHeight;
            var numDashedLines:Number = Math.round(dashedLineTotalHeight/(lineHeight+lineGap));
            var currentLineY:Number = 0;
            line.graphics.lineStyle(lineThickness, lineColor);
            for(var i:int=0; i <numDashedLines; i++)
            {
                line.graphics.moveTo(0, currentLineY);
                line.graphics.lineTo(0, currentLineY + lineHeight);
                currentLineY += lineHeight + lineGap;
            }
        
            return line;
        }
    
        public static function createGraphLegend(label:String, color:uint, textSize:int):Label
        {
           	var legend:Label = new Label();
			legend.fontStyles = new TextFormat("Roboto", textSize, color, "left", "top");
			legend.text = label;
			legend.invalidate();
			legend.validate();
			
			return legend;
        }
    
        public static function createChartStatusText(label:String, color:uint, textSize:int, direction:String, bold:Boolean = false, width:Number = NaN, height:Number = NaN):Label
        {
            var legend:Label = new Label();
			if(!isNaN(width))
				legend.width = width;
			if(!isNaN(height))
				legend.height = height;
			var textFormat:TextFormat = new TextFormat("Roboto", textSize, color, direction, "top");
			textFormat.bold = bold;
			legend.fontStyles = textFormat;
			legend.text = label;
			legend.invalidate();
			legend.validate();
			legend.textRendererFactory = function():ITextRenderer
			{
				var textFieldRenderer:TextFieldTextRenderer = new TextFieldTextRenderer();
				textFieldRenderer.pixelSnapping = true;
				return textFieldRenderer;
			};
			
			return legend;
        }
		
		public static function createPieLegend():Label
		{
			/* Calculate Font Size */
			var fontSize:Number;
			var deviceType:String = DeviceInfo.getDeviceType();
			if (deviceType == DeviceInfo.IPHONE_5_5S_5C_SE)
				fontSize = 9.5;
			else 
				fontSize = 11;
			
			/* Create Legend */
			var legend:Label = new Label();
			legend.fontStyles = new TextFormat("Roboto", fontSize, 0xFFFFFF, "left", "top");
			
			return legend;
		}
		
		public static function createOutline(width:Number, height:Number, lineThickness:int):Shape
		{
			var outline:Shape = new Shape();
			outline.graphics.lineStyle(lineThickness, 0xFFFFFF);
			outline.graphics.moveTo(lineThickness/2, lineThickness/2);
			outline.graphics.lineTo(width - (lineThickness/2), lineThickness/2);
			outline.graphics.moveTo(width - (lineThickness/2), lineThickness/2);
			outline.graphics.lineTo(width - (lineThickness/2), height - (lineThickness/2));
			outline.graphics.moveTo(width - (lineThickness/2), height - (lineThickness/2));
			outline.graphics.lineTo(lineThickness/2, height - (lineThickness/2));
			outline.graphics.moveTo(lineThickness/2, height - (lineThickness/2));
			outline.graphics.lineTo(lineThickness/2, lineThickness/2);
			
			return outline;
		}
    }
}
