package starling.display.util
{
	public class CurveUtil
	{
		// State variables for quadratic subdivision.
		private static const STEPS:int = 8;
		public static const BEZIER_ERROR:Number = 0.75;
		private static var _subSteps:int = 0;
		private static var _bezierError:Number = BEZIER_ERROR;
		
		// ax1, ay1, cx, cy, ax2, ay2 for quadratic, or
		// ax1, ay1, cx1, cy1, cx2, cy2, ax2, ay2 for cubic
		private static var _terms:Vector.<Number> = new Vector.<Number>( 8, true );
		
		public static function quadraticCurve( a1x:Number, a1y:Number, cx:Number, cy:Number, a2x:Number, a2y:Number, error:Number = BEZIER_ERROR ):Vector.<Number>
		{
			_subSteps = 0;
			_bezierError = error;
			
			_terms[0] = a1x;
			_terms[1] = a1y;
			_terms[2] = cx;
			_terms[3] = cy;
			_terms[4] = a2x;
			_terms[5] = a2y;
			
			var output:Vector.<Number> = new Vector.<Number>();
			
			subdivideQuadratic( 0.0, 0.5, 0, output );
			subdivideQuadratic( 0.5, 1.0, 0, output );
		
			return output;
		}
		
		public static function cubicCurve( a1x:Number, a1y:Number, c1x:Number, c1y:Number, c2x:Number, c2y:Number, a2x:Number, a2y:Number, error:Number = BEZIER_ERROR ):Vector.<Number>
		{
			_subSteps = 0;
			_bezierError = error;
			
			_terms[0] = a1x;
			_terms[1] = a1y;
			_terms[2] = c1x;
			_terms[3] = c1y;
			_terms[4] = c2x;
			_terms[5] = c2y;
			_terms[6] = a2x;
			_terms[7] = a2y;
			
			var output:Vector.<Number> = new Vector.<Number>();
			
			subdivideCubic( 0.0, 0.5, 0, output );
			subdivideCubic( 0.5, 1.0, 0, output );
			
			return output;
		}
		
		private static function quadratic( t:Number, axis:int ):Number 
		{
			var oneMinusT:Number = (1.0 - t);
			var a1:Number = _terms[0 + axis];
			var c:Number  = _terms[2 + axis];
			var a2:Number = _terms[4 + axis];
			return (oneMinusT*oneMinusT*a1) + (2.0*oneMinusT*t*c) + t*t*a2;
		}
		
		private static function cubic( t:Number, axis:int ):Number 
		{
			var oneMinusT:Number = (1.0 - t);
			
			var a1:Number = _terms[0 + axis];
			var c1:Number = _terms[2 + axis];
			var c2:Number = _terms[4 + axis];
			var a2:Number = _terms[6 + axis];
			return (oneMinusT*oneMinusT*oneMinusT*a1) + (3.0*oneMinusT*oneMinusT*t*c1) + (3.0*oneMinusT*t*t*c2) + t*t*t*a2;
		}
		
		/* Subdivide until an error metric is hit.
		* Uses depth first recursion, so that lineTo() can be called directory,
		* and the calls will be in the currect order.
		*/
		private static function subdivide( t0:Number, t1:Number, depth:int, equation:Function, output:Vector.<Number> ):void
		{
			var quadX:Number = equation( (t0 + t1) * 0.5, 0 );
			var quadY:Number = equation( (t0 + t1) * 0.5, 1 );
			
			var x0:Number = equation( t0, 0 );
			var y0:Number = equation( t0, 1 );
			var x1:Number = equation( t1, 0 );
			var y1:Number = equation( t1, 1 );
			
			var midX:Number = ( x0 + x1 ) * 0.5;
			var midY:Number = ( y0 + y1 ) * 0.5;
			
			var dx:Number = quadX - midX;
			var dy:Number = quadY - midY;
			
			var error2:Number = dx * dx + dy * dy;
			
			if ( error2 > (_bezierError*_bezierError) ) {
				subdivide( t0, (t0 + t1)*0.5, depth+1, equation, output );	
				subdivide( (t0 + t1)*0.5, t1, depth+1, equation, output );	
			}
			else {
				++_subSteps;
				output.push(x1,y1);
			}
		}
		
		private static function subdivideQuadratic( t0:Number, t1:Number, depth:int, output:Vector.<Number> ):void
		{
			var quadX:Number = quadratic( (t0 + t1) * 0.5, 0 );
			var quadY:Number = quadratic( (t0 + t1) * 0.5, 1 );
			
			var x0:Number = quadratic( t0, 0 );
			var y0:Number = quadratic( t0, 1 );
			var x1:Number = quadratic( t1, 0 );
			var y1:Number = quadratic( t1, 1 );
			
			var midX:Number = ( x0 + x1 ) * 0.5;
			var midY:Number = ( y0 + y1 ) * 0.5;
			
			var dx:Number = quadX - midX;
			var dy:Number = quadY - midY;
			
			var error2:Number = dx * dx + dy * dy;
			
			if ( error2 > (_bezierError*_bezierError) ) {
				subdivideQuadratic( t0, (t0 + t1)*0.5, depth+1, output );	
				subdivideQuadratic( (t0 + t1)*0.5, t1, depth+1, output );	
			}
			else {
				++_subSteps;
				output.push(x1,y1);
			}
		}
		
		private static function subdivideCubic( t0:Number, t1:Number, depth:int, output:Vector.<Number> ):void
		{
			var quadX:Number = cubic( (t0 + t1) * 0.5, 0 );
			var quadY:Number = cubic( (t0 + t1) * 0.5, 1 );
			
			var x0:Number = cubic( t0, 0 );
			var y0:Number = cubic( t0, 1 );
			var x1:Number = cubic( t1, 0 );
			var y1:Number = cubic( t1, 1 );
			
			var midX:Number = ( x0 + x1 ) * 0.5;
			var midY:Number = ( y0 + y1 ) * 0.5;
			
			var dx:Number = quadX - midX;
			var dy:Number = quadY - midY;
			
			var error2:Number = dx * dx + dy * dy;
			
			if ( error2 > (_bezierError*_bezierError) ) {
				subdivideCubic( t0, (t0 + t1)*0.5, depth+1, output );	
				subdivideCubic( (t0 + t1)*0.5, t1, depth+1, output );	
			}
			else {
				++_subSteps;
				output.push(x1,y1);
			}
		}
		
	}
}