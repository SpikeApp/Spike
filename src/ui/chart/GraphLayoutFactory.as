package ui.chart
{
    import flash.display.BitmapData;
    
    import feathers.controls.Label;
    
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Shape;
    import starling.display.Sprite;
    import starling.text.TextFormat;
    import starling.textures.Texture;
    
    import ui.shapes.SpikeDisplayObject;
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
		
		public static function createImageFromShape(shape:DisplayObject):SpikeDisplayObject
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
		}
    }
}
