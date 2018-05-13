package ui.chart
{
    import feathers.controls.Label;
    
    import starling.display.Shape;
    import starling.display.Sprite;
    import starling.text.TextFormat;
    
    import ui.shapes.SpikeLine;
    
    import utils.Constants;
    import utils.DeviceInfo;


	public class GraphLayoutFactory
    {
	
		public function GraphLayoutFactory():void{}

        public static function createVerticalLine(height:Number, thickness:int, color:uint):SpikeLine
        {
			var line:SpikeLine = new SpikeLine();
			line.thickness = thickness;
			line.color = color;
			line.lineTo(0, height);
			
			return line;
        }
		
		public static function createHorizontalLine(width:Number, thickness:int, color:uint):SpikeLine
		{
			var line:SpikeLine = new SpikeLine();
			line.thickness = thickness;
			line.color = color;
			line.lineTo(width, 0);
			
			return line;
		}

        public static function createHorizontalDashedLine(graphWidth:Number, lineWidth:int, lineGap:int, lineThickness:int, lineColor:uint, rightMargin:Number):Sprite
        {
            var line:Sprite = new Sprite();
			
			var dashedLineTotalWidth:Number = graphWidth - lineThickness - rightMargin - 30;
			var numDashedLines:Number = Math.round(dashedLineTotalWidth/(lineWidth+lineGap));
			var currentLineX:Number = 0;
			
			for(var i:int=0; i <numDashedLines; i++)
			{
				var smallLine:SpikeLine = new SpikeLine();
				smallLine.thickness = lineThickness;
				smallLine.color = lineColor;
				smallLine.x = currentLineX;
				smallLine.y = 0;
				smallLine.lineTo(currentLineX + lineWidth, 0);
				line.addChild(smallLine);
				
				currentLineX += lineWidth + lineGap;
			}
			
			return line;
        }
    
        public static function createVerticalDashedLine(grapHeight:Number, lineHeight:int, lineGap:int, lineThickness:int, lineColor:uint):Sprite
        {
			var line:Sprite = new Sprite();
			var dashedLineTotalHeight:Number = grapHeight;
			var numDashedLines:Number = Math.round(dashedLineTotalHeight/(lineHeight+lineGap));
			var currentLineY:Number = 0;
			
			for(var i:int=0; i <numDashedLines; i++)
			{
				var smallLine:SpikeLine = new SpikeLine();
				smallLine.thickness = lineThickness;
				smallLine.color = lineColor;
				smallLine.x = 0;
				smallLine.y = currentLineY;
				smallLine.lineTo(0, currentLineY + lineHeight);
				line.addChild(smallLine);
				
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
			var textFormat:TextFormat = new TextFormat("Roboto", textSize, color, direction, "top");
			textFormat.bold = bold;
			
            var legend:Label = new Label();
			if(!isNaN(width)) legend.width = width;
			if(!isNaN(height)) legend.height = height;
			legend.fontStyles = textFormat;
			legend.text = label;
			legend.invalidate();
			legend.validate();
			
			return legend;
        }
		
		public static function createPieLegend(fontColor:uint = 0xEEEEEE):Label
		{
			/* Calculate Font Size */
			var fontSize:Number;
			if (Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
				fontSize = 9.5;
			else 
				fontSize = 11;
			
			/* Create Legend */
			var legend:Label = new Label();
			legend.fontStyles = new TextFormat("Roboto", fontSize, fontColor, "left", "top");
			
			return legend;
		}
		
		public static function createOutline(width:Number, height:Number, lineThickness:int):Sprite
		{
			var outline:Sprite = new Sprite();
			
			var line1:SpikeLine = new SpikeLine();
			line1.thickness = lineThickness;
			line1.color = 0xFFFFFF;
			line1.x = 0;
			line1.y = 0;
			line1.lineTo(width, 0);
			outline.addChild(line1);
			
			var line2:SpikeLine = new SpikeLine();
			line2.thickness = lineThickness;
			line2.color = 0xFFFFFF;
			line2.x = width;
			line2.y = 0;
			line2.lineTo(width, height);
			outline.addChild(line2);
			
			var line3:SpikeLine = new SpikeLine();
			line3.thickness = lineThickness;
			line3.color = 0xFFFFFF;
			line3.x = width;
			line3.y = height;
			line3.lineTo(0, height);
			outline.addChild(line3);
			
			var line4:SpikeLine = new SpikeLine();
			line4.thickness = lineThickness;
			line4.color = 0xFFFFFF;
			line4.x = 0;
			line4.y = height;
			line4.lineTo(0, 0);
			outline.addChild(line4);
			
			return outline;
		}
    }
}
