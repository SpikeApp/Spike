package chart
{
import starling.display.Canvas;
import starling.display.Sprite;

public class GlucoseMarker extends Sprite
    {
        private var _glucoseValue:Number = 0;
        private var _timestamp:Number = 0;
        private var _radius:Number = 0;
        private var _color:uint = 0;

        public function GlucoseMarker(radius:Number, color:uint)
        {
            //Set properties
            _radius = radius;
            _color = color;

            //Create graphics
            draw();
        }

        //Function to draw the shape
        public function draw():void
        {
            var glucoseMarker:Canvas = new Canvas();
            glucoseMarker.beginFill(color);
            glucoseMarker.drawCircle(_radius,_radius,_radius);
            glucoseMarker.endFill();
            
            addChild(glucoseMarker);
        }

        //Getters & Setters
        public function get glucoseValue():Number {
            return _glucoseValue;
        }

        public function set glucoseValue(value:Number):void {
            _glucoseValue = value;
        }

        public function get timestamp():Number {
            return _timestamp;
        }

        public function set timestamp(value:Number):void {
            _timestamp = value;
        }

        public function get radius():Number {
            return _radius;
        }

        public function get color():uint {
            return _color;
        }
    }
}
