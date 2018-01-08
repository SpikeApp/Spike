package starling.display.graphics.util 
{
	import flash.geom.Point;
	
	public class TriangleUtil 
	{
		
		public function TriangleUtil() 
		{
			
		}
		
		public static function isLeft(v0x:Number, v0y:Number, v1x:Number, v1y:Number, px:Number, py:Number):Boolean
		{
			return ((v1x - v0x) * (py - v0y) - (v1y - v0y) * (px - v0x)) < 0;
		}
		
		public static function isPointInTriangle(v0x:Number, v0y:Number, v1x:Number, v1y:Number, v2x:Number, v2y:Number, px:Number, py:Number ):Boolean
		{
			if ( isLeft( v2x, v2y, v0x, v0y, px, py ) ) return false;  // In practical tests, this seems to be the one returning false the most. Put it on top as faster early out.
			if ( isLeft( v0x, v0y, v1x, v1y, px, py ) ) return false;
			if ( isLeft( v1x, v1y, v2x, v2y, px, py ) ) return false;
			return true;
		}
		
		public static function isPointInTriangleBarycentric(v0x:Number, v0y:Number, v1x:Number, v1y:Number, v2x:Number, v2y:Number, px:Number, py:Number ):Boolean
		{
			var alpha:Number = ((v1y - v2y)*(px - v2x) + (v2x - v1x)*(py - v2y)) / ((v1y - v2y)*(v0x - v2x) + (v2x - v1x)*(v0y - v2y));
			var beta:Number = ((v2y - v0y)*(px - v2x) + (v0x - v2x)*(py - v2y)) / ((v1y - v2y)*(v0x - v2x) + (v2x - v1x)*(v0y - v2y));
			var gamma:Number = 1.0 - alpha - beta;
			if ( alpha > 0 && beta > 0 && gamma > 0 )
				return true;
			return false;	
		}
		
		public static function isPointOnLine(v0x:Number, v0y:Number, v1x:Number, v1y:Number, px:Number, py:Number, distance:Number ):Boolean
		{
			var lineLengthSquared:Number = (v1x - v0x) * (v1x - v0x) + (v1y - v0y) * (v1y - v0y);
				
			var interpolation:Number = ( ( ( px - v0x ) * ( v1x - v0x ) ) + ( ( py - v0y ) * ( v1y - v0y ) ) )  /	( lineLengthSquared );
			if( interpolation < 0.0 || interpolation > 1.0 )
				return false;   // closest point does not fall within the line segment
					
			var intersectionX:Number = v0x + interpolation * ( v1x - v0x );
			var intersectionY:Number = v0y + interpolation * ( v1y - v0y );
				
			var distanceSquared:Number = (px - intersectionX) * (px - intersectionX) + (py - intersectionY) * (py - intersectionY);
				
			var intersectThickness:Number = 1 + distance;
				
			if ( distanceSquared <= intersectThickness * intersectThickness)
				return true;
				
			return false;	
		}
		
		public static function lineIntersectLine(line1V0x:Number, line1V0y:Number, line1V1x:Number, line1V1y:Number, line2V0x:Number, line2V0y:Number, line2V1x:Number, line2V1y:Number, intersectPoint:Point ) : Boolean
		{
 
			var a1:Number = line1V1y-line1V0y;
			var b1:Number = line1V0x-line1V1x;
			var c1:Number = line1V1x * line1V0y - line1V0x * line1V1y;
			
			var a2:Number = line2V1y-line2V0y;
			var b2:Number = line2V0x-line2V1x;
			var c2:Number = line2V1x * line2V0y - line2V0x * line2V1y;
			
			var d:Number=a1*b2 - a2*b1;
			if (d == 0) 
				return false;
			var invD:Number = 1.0 / d;
			var ptx:Number = (b1*c2 - b2*c1) * invD;
			var pty:Number = (a2*c1 - a1*c2) * invD;
 	
			if ( isPointOnLine(line1V0x, line1V0y, line1V1x, line1V1y, ptx, pty, 0) && isPointOnLine(line2V0x, line2V0y, line2V1x, line2V1y, ptx, pty, 0) )
			{
				intersectPoint.x = ptx;
				intersectPoint.y = pty;
				return true;
			}
			return false;
		}
	}

}