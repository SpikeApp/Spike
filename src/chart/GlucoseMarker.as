package chart
{
import starling.display.Canvas;
import starling.display.Sprite;

public class GlucoseMarker extends Sprite
    {
		public var index:int;
        public var glucoseValue:Number;
		public var glucoseValueFormatted:Number;
		public var glucoseOutput:String;
		public var slopeOutput:String;
		public var slopeArrow:String;
        public var timestamp:Number;
		public var radius:Number;
		public var color:uint;

        public function GlucoseMarker(radius:Number, color:uint)
        {
            //Set properties
            this.radius = radius;
            this.color = color;

            //Create graphics
            draw();
        }

        //Function to draw the shape
        public function draw():void
        {
            var glucoseMarker:Canvas = new Canvas();
            glucoseMarker.beginFill(color);
            glucoseMarker.drawCircle(radius,radius,radius);
            glucoseMarker.endFill();
            
            addChild(glucoseMarker);
        }
    }
}
