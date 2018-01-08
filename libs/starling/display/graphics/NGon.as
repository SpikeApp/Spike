/*

	A fairly versatile primitive capable of representing circles, fans, hoops, and arcs.

	Contains a great sin/cos trick learned from Iñigo Quílez's site
	http://www.iquilezles.org/www/articles/sincos/sincos.htm

*/

package starling.display.graphics
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import starling.core.Starling;
	import starling.display.graphics.util.TriangleUtil;

	public class NGon extends Graphic
	{
		private const DEGREES_TO_RADIANS	:Number = Math.PI / 180;
		
		private var _radius			:Number;
		private var _innerRadius	:Number;
		private var _startAngle		:Number;
		private var _endAngle		:Number;
		private var _numSides		:int;
		private var _color			:uint = 0xFFFFFF;
		
		private static var _uv		:Point;
		
		public function NGon( radius:Number = 100, numSides:int = 10, innerRadius:Number = 0, startAngle:Number = 0, endAngle:Number = 360 )
		{
			this.radius = radius;
			this.numSides = numSides;
			this.innerRadius = innerRadius;
			this.startAngle = startAngle;
			this.endAngle = endAngle;
			
			minBounds.x = minBounds.y = -radius;
			maxBounds.x = maxBounds.y = radius;
			
			if ( !_uv )
			{
				_uv = new Point();
			}
		}
		
		public function get endAngle():Number
		{
			return _endAngle;
		}

		public function set endAngle(value:Number):void
		{
			_endAngle = value;
			setGeometryInvalid();
		}

		public function get startAngle():Number
		{
			return _startAngle;
		}

		public function set startAngle(value:Number):void
		{
			_startAngle = value;
			setGeometryInvalid();
		}

		public function get radius():Number
		{
			return _radius;
		}
		
		public function set color(value:uint) : void
		{
			_color = value;
			setGeometryInvalid();
		}
		
		public function set radius(value:Number):void
		{
			value = value < 0 ? 0 : value;
			_radius = value;
			var maxRadius:Number = Math.max(_radius, _innerRadius);
			minBounds.x = minBounds.y = -maxRadius;
			maxBounds.x = maxBounds.y = maxRadius;
			setGeometryInvalid();
		}
		
		public function get innerRadius():Number
		{
			return _innerRadius;
		}

		public function set innerRadius(value:Number):void
		{
			value = value < 0 ? 0 : value;
			_innerRadius = value;
			var maxRadius:Number = Math.max(_radius, _innerRadius);
			minBounds.x = minBounds.y = -maxRadius;
			maxBounds.x = maxBounds.y = maxRadius;
			setGeometryInvalid();
		}

		public function get numSides():int
		{
			return _numSides;
		}

		public function set numSides(value:int):void
		{
			value = value < 3 ? 3 : value;
			_numSides = value;
			setGeometryInvalid();
		}
		
		override protected function buildGeometry():void
		{
			vertices = new Vector.<Number>();
			indices = new Vector.<uint>();
			
			// Manipulate the input startAngle and endAngle values
			// into sa and ea. sa will always end up less than
			// ea, and ea-sa is the shortest clockwise distance
			// between them.
			var sa:Number = _startAngle;
			var ea:Number = _endAngle;
			var isEqual:Boolean = sa == ea;
			var sSign:int = sa < 0 ? -1 : 1;
			var eSign:int = ea < 0 ? -1 : 1;
			sa *= sSign;
			ea *= eSign;
			ea = ea % 360;
			ea *= eSign;
			sa = sa % 360;
			if ( ea < sa )
			{
				ea += 360;
			}
			sa *= sSign * DEGREES_TO_RADIANS;
			ea *= DEGREES_TO_RADIANS;
			if ( ea - sa > Math.PI*2 )
			{
				ea -= Math.PI*2;
			}
			
			// Manipulate innerRadius and outRadius in r and ir.
			// ir will always be less than r.
			var innerRadius:Number = _innerRadius < _radius ? _innerRadius : _radius;
			var radius:Number = _radius > _innerRadius ? _radius : _innerRadius;
			
			// Based upon the input values, choose from
			// 4 primitive types. Each more complex than the next.
			var isSegment:Boolean = (sa != 0 || ea != 0);
			if ( isSegment == false )
				isSegment = isEqual; // if sa and ea are equal, treat that as a segment, not a full lap around a circle.
				
			if ( innerRadius == 0 && !isSegment )
			{
				buildSimpleNGon(radius, _numSides, vertices, indices, _uvMatrix , _color);
			}
			else if ( innerRadius != 0 && !isSegment )
			{
				buildHoop(innerRadius, radius, _numSides, vertices, indices, _uvMatrix , _color);
			}
			else if ( innerRadius == 0 )
			{
				buildFan(radius, sa, ea, _numSides, vertices, indices, _uvMatrix , _color);
			}
			else
			{
				buildArc( innerRadius, radius, sa, ea, _numSides, vertices, indices, _uvMatrix , _color);
			}
		}
		
		override protected function shapeHitTestLocalInternal( localX:Number, localY:Number ):Boolean
		{
			var numIndices:int = indices.length;
			if ( numIndices < 2 )
			{
				validateNow();
				numIndices = indices.length;
				if ( numIndices < 2 )
					return false;
			}
			
			if ( _innerRadius == 0 && _radius > 0 && _startAngle == 0 && _endAngle == 360 && _numSides > 20 )  
			{  // simple - faster - if ngon is circle shape and numsides more than 20, assume circle is desired.
				if ( Math.sqrt( localX * localX + localY * localY ) < _radius )
					return true;
				return false;	
			}
				
			for ( var i:int = 2; i < numIndices; i+=3 )
			{ // slower version - should be complete though. For all triangles, check if point is in triangle
				var i0:int = indices[(i - 2)];
				var i1:int = indices[(i - 1)];
				var i2:int = indices[(i - 0)];
				
				var v0x:Number = vertices[VERTEX_STRIDE * i0 + 0];
				var v0y:Number = vertices[VERTEX_STRIDE * i0 + 1];
				var v1x:Number = vertices[VERTEX_STRIDE * i1 + 0];
				var v1y:Number = vertices[VERTEX_STRIDE * i1 + 1];
				var v2x:Number = vertices[VERTEX_STRIDE * i2 + 0];
				var v2y:Number = vertices[VERTEX_STRIDE * i2 + 1];
				if ( TriangleUtil.isPointInTriangle(v0x, v0y, v1x, v1y, v2x, v2y, localX, localY) )
					return true;
			}
			return false;
		}
		
		private static function buildSimpleNGon( radius:Number, numSides:int, vertices:Vector.<Number>, indices:Vector.<uint>, uvMatrix:Matrix, color:uint ):void
		{
			var numVertices:int = 0;
			
			_uv.x = 0;
			_uv.y = 0;
			if ( uvMatrix ) 
				_uv = uvMatrix.transformPoint(_uv);
			
			var r:Number = (color >> 16) / 255;
			var g:Number = ((color & 0x00FF00) >> 8) / 255;
			var b:Number = (color & 0x0000FF) / 255;
				
			vertices.push( 0, 0, 0, r, g, b, 1, _uv.x, _uv.y );
			numVertices++;
			
			var anglePerSide:Number = (Math.PI * 2) / numSides;
			var cosA:Number = Math.cos(anglePerSide);
			var sinB:Number = Math.sin(anglePerSide);
			var s:Number = 0.0;
			var c:Number = 1.0;
			
			for ( var i:int = 0; i < numSides; i++ )
			{
				var x:Number = s * radius;
				var y:Number = -c * radius;
				_uv.x = x;
				_uv.y = y;
				if ( uvMatrix ) 
					_uv = uvMatrix.transformPoint(_uv);
				
				vertices.push( x, y, 0, r, g, b, 1, _uv.x, _uv.y );
				numVertices++;
				indices.push( 0, numVertices-1, i == numSides-1 ? 1 : numVertices );
				
				const ns:Number = sinB*c + cosA*s;
				const nc:Number = cosA*c - sinB*s;
				c = nc;
				s = ns;
			}
		}
		
		private static function buildHoop( innerRadius:Number, radius:Number, numSides:int, vertices:Vector.<Number>, indices:Vector.<uint>, uvMatrix:Matrix , color:uint):void
		{
			var numVertices:int = 0;
			
			var anglePerSide:Number = (Math.PI * 2) / numSides;
			var cosA:Number = Math.cos(anglePerSide);
			var sinB:Number = Math.sin(anglePerSide);
			var s:Number = 0.0;
			var c:Number = 1.0;
			
			var r:Number = (color >> 16) / 255;
			var g:Number = ((color & 0x00FF00) >> 8) / 255;
			var b:Number = (color & 0x0000FF) / 255;
			
			for ( var i:int = 0; i < numSides; i++ )
			{
				var x:Number = s * radius;
				var y:Number = -c * radius;
				_uv.x = x;
				_uv.y = y;
				if ( uvMatrix ) 
					_uv = uvMatrix.transformPoint(_uv);
				
				vertices.push( x, y, 0, r, g, b, 1, _uv.x, _uv.y );
				numVertices++;
				
				x = s * innerRadius;
				y = -c * innerRadius;
				_uv.x = x;
				_uv.y = y;
				if ( uvMatrix ) 
					_uv = uvMatrix.transformPoint(_uv);
				
				vertices.push( x, y, 0, r, g, b, 1, _uv.x, _uv.y );
				numVertices++;
			
				if ( i == numSides-1 )
				{
					indices.push( numVertices-2, numVertices-1, 0, 0, numVertices-1, 1 );
				}
				else
				{
					indices.push( numVertices - 2, numVertices , numVertices-1, numVertices, numVertices + 1, numVertices - 1 );
				}
				
				const ns:Number = sinB*c + cosA*s;
				const nc:Number = cosA*c - sinB*s;
				c = nc;
				s = ns;
			}
		}
		
		private static function buildFan( radius:Number, startAngle:Number, endAngle:Number, numSides:int, vertices:Vector.<Number>, indices:Vector.<uint>, uvMatrix:Matrix , color:uint):void
		{
			var numVertices:int = 0;
			
			var r:Number = (color >> 16) / 255;
			var g:Number = ((color & 0x00FF00) >> 8) / 255;
			var b:Number = (color & 0x0000FF) / 255;
			
			vertices.push( 0, 0, 0, r, g, b, 1, 0.5, 0.5 );
			numVertices++;
			
			var radiansPerDivision:Number = (Math.PI * 2) / numSides;
			var startRadians:Number = (startAngle / radiansPerDivision);
			startRadians = startRadians < 0 ? -Math.ceil(-startRadians) : int(startRadians);
			startRadians *= radiansPerDivision;
			
			
			
			for ( var i:int = 0; i <= numSides+1; i++ )
			{
				var radians:Number = startRadians + i*radiansPerDivision;
				var nextRadians:Number = radians + radiansPerDivision;
				if ( nextRadians < startAngle ) continue;
				
				var x:Number = Math.sin( radians ) * radius;
				var y:Number = -Math.cos( radians ) * radius;
				var prevRadians:Number = radians-radiansPerDivision;
				
				var t:Number
				if ( radians < startAngle && nextRadians > startAngle )
				{
					var nextX:Number = Math.sin(nextRadians) * radius;
					var nextY:Number = -Math.cos(nextRadians) * radius;
					t = (startAngle-radians) / radiansPerDivision;
					x += t * (nextX-x);
					y += t * (nextY-y);
				}
				else if ( radians > endAngle && prevRadians < endAngle )
				{
					var prevX:Number = Math.sin(prevRadians) * radius;
					var prevY:Number = -Math.cos(prevRadians) * radius;
					
					t = (endAngle-prevRadians) / radiansPerDivision;
					x = prevX + t * (x-prevX);
					y = prevY + t * (y-prevY);
				}
				
				_uv.x = x;
				_uv.y = y;
				if ( uvMatrix ) 
					_uv = uvMatrix.transformPoint(_uv);
				
				vertices.push( x, y, 0, r, g, b, 1, _uv.x, _uv.y );
				numVertices++;
				
				if ( vertices.length > 2*9 )
				{
					indices.push( 0, numVertices-2, numVertices-1 );
				}
				
				if ( radians >= endAngle )
				{
					break;
				}
			}
		}
		
		private static function buildArc( innerRadius:Number, radius:Number, startAngle:Number, endAngle:Number, numSides:int, vertices:Vector.<Number>, indices:Vector.<uint>, uvMatrix:Matrix , color:uint):void
		{
			var nv:int = 0;
			var radiansPerDivision:Number = (Math.PI * 2) / numSides;
			var startRadians:Number = (startAngle / radiansPerDivision);
			startRadians = startRadians < 0 ? -Math.ceil(-startRadians) : int(startRadians);
			startRadians *= radiansPerDivision;
			var r:Number = (color >> 16) / 255;
			var g:Number = ((color & 0x00FF00) >> 8) / 255;
			var b:Number = (color & 0x0000FF) / 255;
			
			for ( var i:int = 0; i <= numSides+1; i++ )
			{
				var angle:Number = startRadians + i*radiansPerDivision;
				var nextAngle:Number = angle + radiansPerDivision;
				if ( nextAngle < startAngle ) continue;
				
				var sin:Number = Math.sin(angle);
				var cos:Number = Math.cos(angle);
				
				var x:Number = sin * radius;
				var y:Number = -cos * radius;
				var x2:Number = sin * innerRadius;
				var y2:Number = -cos * innerRadius;
				
				var prevAngle:Number = angle-radiansPerDivision;
				
				var t:Number
				if ( angle < startAngle && nextAngle > startAngle )
				{
					sin = Math.sin(nextAngle);
					cos = Math.cos(nextAngle);
					var nextX:Number = sin * radius;
					var nextY:Number = -cos * radius;
					var nextX2:Number = sin * innerRadius;
					var nextY2:Number = -cos * innerRadius;
					t = (startAngle-angle) / radiansPerDivision;
					x += t * (nextX-x);
					y += t * (nextY-y);
					x2 += t * (nextX2-x2);
					y2 += t * (nextY2-y2);
				}
				else if ( angle > endAngle && prevAngle < endAngle )
				{
					sin = Math.sin(prevAngle);
					cos = Math.cos(prevAngle);
					var prevX:Number = sin * radius;
					var prevY:Number = -cos * radius;
					var prevX2:Number = sin * innerRadius;
					var prevY2:Number = -cos * innerRadius;
					
					t = (endAngle-prevAngle) / radiansPerDivision;
					x = prevX + t * (x-prevX);
					y = prevY + t * (y-prevY);
					x2 = prevX2 + t * (x2-prevX2);
					y2 = prevY2 + t * (y2-prevY2);
				}
				
				_uv.x = x;
				_uv.y = y;
				if ( uvMatrix ) 
					_uv = uvMatrix.transformPoint(_uv);
				
				vertices.push( x, y, 0, r, g, b, 1, _uv.x, _uv.y );
				nv++;
				
				_uv.x = x2;
				_uv.y = y2;
				if ( uvMatrix ) 
					_uv = uvMatrix.transformPoint(_uv);
				
				vertices.push( x2, y2, 0, r, g, b, 1, _uv.x, _uv.y );
				nv++;
				
				if ( vertices.length > 3*9 )
				{
					//indices.push( nv-1, nv-2, nv-3, nv-3, nv-2, nv-4 );
					indices.push( nv-3, nv-2, nv-1, nv-3, nv-4, nv-2 );
				}
				
				if ( angle >= endAngle )
				{
					break;
				}
			}
		}
	}
}