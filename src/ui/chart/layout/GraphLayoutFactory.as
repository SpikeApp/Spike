package ui.chart.layout
{
    import feathers.controls.Label;
    
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
			line.lineStyle(thickness, color);
			line.moveTo(0, 0);
			line.lineTo(0, height);
			
			return line;
        }
		
		public static function createHorizontalLine(width:Number, thickness:int, color:uint):SpikeLine
		{
			var line:SpikeLine = new SpikeLine();
			line.lineStyle(thickness, color);
			line.moveTo(0, 0);
			line.lineTo(width, 0);
			
			return line;
		}

        public static function createHorizontalDashedLine(graphWidth:Number, lineWidth:int, lineGap:int, lineThickness:int, lineColor:uint, rightMargin:Number):SpikeLine
        {
            
			var line:SpikeLine = new SpikeLine();
			line.lineStyle(lineThickness, lineColor);
			
			var dashedLineTotalWidth:Number = graphWidth - lineThickness - rightMargin - 30;
			var numDashedLines:Number = Math.round(dashedLineTotalWidth/(lineWidth+lineGap));
			var currentLineX:Number = 0;
			
			for(var i:int=0; i <numDashedLines; i++)
			{
				line.moveTo(currentLineX, 0);
				line.lineTo(currentLineX + lineWidth, 0);
				
				currentLineX += lineWidth + lineGap;
			}
			
			return line;
        }
    
        public static function createVerticalDashedLine(grapHeight:Number, lineHeight:int, lineGap:int, lineThickness:int, lineColor:uint):SpikeLine
        {
			var line:SpikeLine = new SpikeLine();
			line.lineStyle(lineThickness, lineColor);
			
			var dashedLineTotalHeight:Number = grapHeight;
			var numDashedLines:Number = Math.round(dashedLineTotalHeight/(lineHeight+lineGap));
			var currentLineY:Number = 0;
			
			for(var i:int=0; i <numDashedLines; i++)
			{
				line.moveTo(0, currentLineY);
				line.lineTo(0, currentLineY + lineHeight);
				
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
		
		public static function createOutline(width:Number, height:Number, lineThickness:int):SpikeLine
		{
			var outline:SpikeLine = new SpikeLine();
			outline.lineStyle(lineThickness, 0xFFFFFF);
			outline.moveTo(0 + (lineThickness/2), 0 + (lineThickness/2));
			outline.lineTo(width - (lineThickness/2), 0 + (lineThickness/2));
			outline.moveTo(width - (lineThickness/2), 0 + (lineThickness/2));
			outline.lineTo(width - (lineThickness/2), height - (lineThickness/2));
			outline.moveTo(width - (lineThickness/2), height - (lineThickness/2));
			outline.lineTo(0 + (lineThickness/2), height - (lineThickness/2));
			outline.moveTo(0 + (lineThickness/2), height - (lineThickness/2));
			outline.lineTo(0 + (lineThickness/2), 0 + (lineThickness/2));
			
			return outline;
		}
		
		/*public static function createImageFromShape(shape:DisplayObject):SpikeDisplayObject
		{			
			//Dummy transparent background to circumvent Starling bug that cuts 1 pixel in width and heigh when converting to bitmap data
			var dummyBackground:Quad = new Quad(shape.width + 2, shape.height + 2);
			dummyBackground.alpha = 0;
			
			//Adjust shape position to be out of the trimmed area
			shape.x += 1;
			shape.y += 1;
			
			//Create a container with the dummy background and the shape on top
			var container:Sprite = new Sprite();
			container.addChild(dummyBackground);
			container.addChild(shape);
			
			//Create bitmap data of the shape's visual representation
			var bitmapData:BitmapData = new BitmapData(container.width * Starling.contentScaleFactor, container.height * Starling.contentScaleFactor);
			container.drawToBitmapData(bitmapData)
			
			//Create and draw a texture onto the GPU. This texture can't be disposed unless we really want the object to not be drawn anymore on the Display List
			var texture:Texture = Texture.fromBitmapData(bitmapData);
			
			//Create an image of the texture. This image can be added to the display list
			var image:Image = new Image(texture);
			image.scale = 1 / Starling.contentScaleFactor;
			image.x = image.y = -1;
			
			//Create Spike Display Object
			var spikeDisplayObject:SpikeDisplayObject = new SpikeDisplayObject(container, dummyBackground, shape, bitmapData, texture, image);
			
			return spikeDisplayObject;
		}*/
    }
}
