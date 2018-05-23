package ui.shapes
{
    import flash.geom.Point;
    
    import starling.display.DisplayObject;
    import starling.display.Sprite;

    public class SpikeRing extends Sprite
    {
        private var _innerRadius:Number;
        private var _outerRadius:Number;
        private var _outerRadius2:Number;
        private var _polygons:Vector.<SpikePoly4>;

        public function get innerRadius():Number { return _innerRadius; }
        public function get outerRadius():Number { return _outerRadius; }

        public function SpikeRing(innerRadius:Number, outerRadius:Number, color:uint=0xffffff)
        {
            _polygons = new Vector.<SpikePoly4>;
            _innerRadius = innerRadius;
            _outerRadius = outerRadius;
            _outerRadius2 = outerRadius * outerRadius;
            var c0:Point = new Point();
            var c1:Point = new Point();
            var p0:Point = new Point();
            var p1:Point = new Point();
            var nParts:int = Math.max(Math.round(outerRadius * 1.0), 8);
            var angle:Number = 0;
            for (var i:int = 0; i < nParts; ++i) {
                var a0:Number = (i + 0.0) * 2.0 * Math.PI / nParts;
                var a1:Number = (i + 1.0) * 2.0 * Math.PI / nParts;
                var ca0:Number = Math.cos(a0);
                var sa0:Number = Math.sin(a0);
                var ca1:Number = Math.cos(a1);
                var sa1:Number = Math.sin(a1);
                c0.x = outerRadius + ca0 * innerRadius;
                c0.y = outerRadius + sa0 * innerRadius;
                c1.x = outerRadius + ca1 * innerRadius;
                c1.y = outerRadius + sa1 * innerRadius;
                p0.x = outerRadius + ca0 * outerRadius;
                p0.y = outerRadius + sa0 * outerRadius;
                p1.x = outerRadius + ca1 * outerRadius;
                p1.y = outerRadius + sa1 * outerRadius;
                var q:SpikePoly4 = new SpikePoly4(c0, p0, c1, p1, color);
                    q.pixelSnapping = false;
                _polygons.push(q);
                addChild(q);
            }
        }

        public function set color(value:uint):void {
            for (var i:int = 0; i < _polygons.length; ++i) {
                _polygons[i].color = value;
            }
        }

		override public function hitTest(localPoint:Point):DisplayObject {
            // on a touch test, invisible or untouchable objects cause the test to fail
            if (!visible || !touchable) return null;
            var vx:Number = localPoint.x - _outerRadius;
            var vy:Number = localPoint.y - _outerRadius;
            var l2:Number = vx*vx + vy*vy;
            return (l2 < _outerRadius2) ? this : null;
        }
    }
}


