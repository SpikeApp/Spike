package starling.display.graphics
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import starling.display.DisplayObject;
	import starling.display.graphics.StrokeVertex;
	import starling.textures.Texture;
	import starling.display.graphics.util.TriangleUtil;
	import starling.utils.MatrixUtil;
		
	public class Stroke extends Graphic
	{
		protected var _line			:Vector.<StrokeVertex>;
		protected var _numVertices		:int;
		
		protected static const c_degenerateUseNext:uint = 1;
		protected static const c_degenerateUseLast:uint = 2;
		protected var _hasDegenerates:Boolean = false;
		
		protected static var sCollissionHelper:StrokeCollisionHelper = null;
		
		public function Stroke()
		{
			clear();
		}
		
		public function get numVertices():int
		{
			return _numVertices;
		}
		
		override public function dispose():void
		{
			clear();
			super.dispose();
		}

		public function clear():void
		{
			if(minBounds)
			{
				minBounds.x = minBounds.y = Number.POSITIVE_INFINITY; 
				maxBounds.x = maxBounds.y = Number.NEGATIVE_INFINITY;
			}
			
			if (_line)
			{
				StrokeVertex.returnInstances(_line);
				_line.length = 0;
			}
			else
				_line = new Vector.<StrokeVertex>;
				
			_numVertices = 0;
			setGeometryInvalid();
			_hasDegenerates = false;
		}
		
		public function addDegenerates(destX:Number, destY:Number):void
		{
			if (_numVertices < 1)
			{
				return;
			}
			var lastVertex:StrokeVertex = _line[_numVertices-1];
			addVertexInternal(lastVertex.x, lastVertex.y, 0.0);
			setLastVertexAsDegenerate(c_degenerateUseLast);
			addVertexInternal(destX, destY, 0.0);
			setLastVertexAsDegenerate(c_degenerateUseNext);
			_hasDegenerates = true;
		}
		
		protected function setLastVertexAsDegenerate(type:uint):void
		{
			_line[_numVertices-1].degenerate = type;
			_line[_numVertices-1].u = 0.0;
		}
		
		public function lineTo(	x:Number, y:Number, thickness:Number = 1, color:uint = 0xFFFFFF,  alpha:Number = 1) : void
		{
			addVertexInternal(x, y, thickness, color, alpha, color, alpha);
		}
		
		public function moveTo( x:Number, y:Number, thickness:Number = 1, color:uint = 0xFFFFFF, alpha:Number = 1.0 ) : void
		{
			addDegenerates(x, y);
		}
		
		public function modifyVertexPosition(index:int, x:Number, y:Number) : void
		{
			var v:StrokeVertex = _line[index];
			v.x = x;
			v.y = y;
			if ( isInvalid == false )
				setGeometryInvalid();
		}
		
		public function fromBounds(boundingBox:Rectangle, thickness:int = 1) : void
		{
			clear();
			addVertex(boundingBox.x, boundingBox.y, thickness); 
			addVertex(boundingBox.x+boundingBox.width, boundingBox.y, thickness);
			addVertex(boundingBox.x+boundingBox.width, boundingBox.y+boundingBox.height, thickness);
			addVertex(boundingBox.x, boundingBox.y+boundingBox.height, thickness);
			addVertex(boundingBox.x, boundingBox.y, thickness);
		}
		
		
	//	[Deprecated(replacement="starling.display.graphics.Stroke.lineTo()")]
		public function addVertex( 	x:Number, y:Number, thickness:Number = 1,
									color0:uint = 0xFFFFFF,  alpha0:Number = 1,
									color1:uint = 0xFFFFFF, alpha1:Number = 1 ):void
		{
			
			addVertexInternal(x, y, thickness, color0, alpha0, color1, alpha1);
		}
		
		protected function addVertexInternal(	x:Number, y:Number, thickness:Number = 1,
									color0:uint = 0xFFFFFF,  alpha0:Number = 1,
									color1:uint = 0xFFFFFF, alpha1:Number = 1 ):void
		{							
									
			var u:Number = 0;
			var textures:Vector.<Texture> = _material.textures;
			if ( textures.length > 0 && _line.length > 0 )
			{
			
				var prevVertex:StrokeVertex = _line[_line.length - 1];
				var dx:Number = x - prevVertex.x;
				var dy:Number = y - prevVertex.y;
				var d:Number = Math.sqrt(dx*dx+dy*dy);
				u = prevVertex.u + (d / textures[0].width);
			}
			
			var r0:Number = (color0 >> 16) / 255;
			var g0:Number = ((color0 & 0x00FF00) >> 8) / 255;
			var b0:Number = (color0 & 0x0000FF) / 255;
			var r1:Number = (color1 >> 16) / 255;
			var g1:Number = ((color1 & 0x00FF00) >> 8) / 255;
			var b1:Number = (color1 & 0x0000FF) / 255;
			
			var v:StrokeVertex = StrokeVertex.getInstance();
			_line[_numVertices] = v;
			v.x = x;
			v.y = y;
			v.r1 = r0;
			v.g1 = g0;
			v.b1 = b0;
			v.a1 = alpha0;
			v.r2 = r1;
			v.g2 = g1;
			v.b2 = b1;
			v.a2 = alpha1;
			v.u = u;
			v.v = 0;
			v.thickness = thickness;
			v.degenerate = 0;
			_numVertices++;
			
			if(x < minBounds.x) 
			{
				minBounds.x = x;
			}
			else if(x > maxBounds.x)
			{
				maxBounds.x = x;
			}
			
			if(y < minBounds.y)
			{
				minBounds.y = y;
			}
			else if(y > maxBounds.y)
			{
				maxBounds.y = y;
			}
			
			if ( maxBounds.x == Number.NEGATIVE_INFINITY )
				maxBounds.x = x;
			if ( maxBounds.y == Number.NEGATIVE_INFINITY )	
				maxBounds.y = y;
			if ( isInvalid == false )
				setGeometryInvalid();
		}
		
		
		public function getVertexPosition(index:int, prealloc:Point = null):Point
		{
			var point:Point = prealloc;
			if ( point == null ) 
				point = new Point();
				
			point.x = _line[index].x;
			point.y = _line[index].y;
			return point;
		}
		
		override protected function buildGeometry():void
		{
			//buildGeometryOriginal();
			buildGeometryPreAllocatedVectors();
		}
		
		protected function buildGeometryOriginal() : void
		{
			if ( _line == null || _line.length == 0 )
				return; // block against odd cases.
				
			// This is the original (slower) code that does not preallocate the vectors for vertices and indices.	
			vertices = new Vector.<Number>();
			indices = new Vector.<uint>();
				
			var indexOffset:int = 0;
					
			var oldVerticesLength:int = vertices.length;
			const oneOverVertexStride:Number = 1 / VERTEX_STRIDE;	
			_numVertices = fixUpPolyLine( _line );
			createPolyLine( _line, vertices, indices, indexOffset);
			indexOffset += (vertices.length - oldVerticesLength) * oneOverVertexStride;
		}
		
		protected function buildGeometryPreAllocatedVectors() : void
		{
			if ( _line == null || _line.length == 0 )
				return; // block against odd cases.
				
			// This is the code that uses the preAllocated code path for createPolyLinePreAlloc
			var indexOffset:int = 0;
			// First remove all deformed things in _line
			_numVertices = fixUpPolyLine( _line );
			
			// Then use the line lenght to pre allocate the vertex vectors
			var numVerts:int = _line.length * 18; // this looks odd, but for each StrokeVertex, we generate 18 verts in createPolyLine
			var numIndices:int = (_line.length - 1) * 6; // this looks odd, but for each StrokeVertex-1, we generate 6 indices in createPolyLine
			
			// In special cases, there is some time to save here. 
			// If the new number of vertices is the same as in the previous list of vertices, there's no need to recreate the buffer of vertices and indices
			if ( vertices == null || numVerts != vertices.length )
			{
				vertices = new Vector.<Number>(numVerts, true);
			}
			if ( indices == null || numIndices != indices.length )
			{
				indices = new Vector.<uint>(numIndices, true);
			}	
			
			createPolyLinePreAlloc( _line, vertices, indices, _hasDegenerates);
		
			var oldVerticesLength:int = 0; // this is always zero in the old code, even if we use vertices.length in the original code. Not sure why it is here.
			const oneOverVertexStride:Number = 1 / VERTEX_STRIDE;	
			indexOffset += (vertices.length - oldVerticesLength) * oneOverVertexStride;
			
		}
		
		///////////////////////////////////
		// Static helper methods
		///////////////////////////////////
		[inline]
		protected static function createPolyLinePreAlloc( _line:Vector.<StrokeVertex>, 
												vertices:Vector.<Number>, 
												indices:Vector.<uint>, 
												_hasDegenerates:Boolean):void 
		{
		
			const numVertices:int = _line.length;
			const PI:Number = Math.PI;
			var vertCounter:int = 0;
			var indiciesCounter:int = 0;
			var lastD0:Number = 0;
			var lastD1:Number = 0;
			var degenerate:uint = 0;
			var idx:uint = 0;
			var treatAsFirst:Boolean;
			var treatAsLast:Boolean;
			
			for ( var i:int = 0; i < numVertices; i++ )
			{
				idx = i;
				if ( _hasDegenerates )
				{
					degenerate = _line[i].degenerate;
					if ( degenerate != 0 ) {
						idx = ( degenerate == c_degenerateUseLast ) ? ( i - 1 ) : ( i + 1 );
					}
					treatAsFirst = ( idx == 0 ) || ( _line[ idx - 1 ].degenerate > 0 );
					treatAsLast = ( idx == numVertices - 1 ) || ( _line[ idx + 1 ].degenerate > 0 );
				}
				else
				{
					treatAsFirst = (idx == 0);
					treatAsLast = ( idx == numVertices - 1 )
				}
				
				var treatAsRegular:Boolean = treatAsFirst == false && treatAsLast == false;
				
				var idx0:uint = treatAsFirst ? idx : ( idx - 1 );
				var idx2:uint = treatAsLast ? idx : ( idx + 1 );
				
				var v0:StrokeVertex = _line[idx0];
				var v1:StrokeVertex = _line[idx];
				var v2:StrokeVertex = _line[idx2];
				
				var vThickness:Number = v1.thickness;
				
				var v0x:Number = v0.x;
				var v0y:Number = v0.y;
				var v1x:Number = v1.x;
				var v1y:Number = v1.y;
				var v2x:Number = v2.x;
				var v2y:Number = v2.y;
				
				var d0x:Number = v1x - v0x;
				var d0y:Number = v1y - v0y;
				var d1x:Number = v2x - v1x;
				var d1y:Number = v2y - v1y;
				
				if ( treatAsRegular == false )
				{
					if ( treatAsLast )
					{
						v2x += d0x;
						v2y += d0y;
						
						d1x = v2x - v1x;
						d1y = v2y - v1y;
					}
				
					if ( treatAsFirst )
					{
						v0x -= d1x;
						v0y -= d1y;
						
						d0x = v1x - v0x;
						d0y = v1y - v0y;
					}
				}
				
				var d0:Number = Math.sqrt( d0x*d0x + d0y*d0y );
				var d1:Number = Math.sqrt( d1x*d1x + d1y*d1y );
		
				var elbowThickness:Number = vThickness*0.5;
				if ( treatAsRegular )
				{
					if ( d0 == 0 )
						d0 = lastD0;
					else
						lastD0 = d0;
					
					if ( d1 == 0 )
						d1 = lastD1;
					else
						lastD1 = d1;
				
					// Thanks to Tom Clapham for spotting this relationship.
					var dot:Number = (d0x * d1x + d0y * d1y) / (d0 * d1);
					var arcCosDot:Number = Math.acos(dot);
					elbowThickness /= Math.sin( (PI-arcCosDot) * 0.5);
					
					if ( elbowThickness > vThickness * 4 )
					{
						elbowThickness = vThickness * 4;
					}
					
					if ( elbowThickness != elbowThickness ) // faster NaN comparison
					{
						elbowThickness = vThickness*0.5;
					}
				}
				
				var n0x:Number = -d0y / d0;
				var n0y:Number =  d0x / d0;
				var n1x:Number = -d1y / d1;
				var n1y:Number =  d1x / d1;
				
				var cnx:Number = n0x + n1x;
				var cny:Number = n0y + n1y;
				
				var c:Number = (1/Math.sqrt( cnx*cnx + cny*cny )) * elbowThickness;
				cnx *= c;
				cny *= c;
				
				var v1xPos:Number = v1x + cnx;
				var v1yPos:Number = v1y + cny;
				var v1xNeg:Number = ( degenerate ) ? v1xPos : ( v1x - cnx );
				var v1yNeg:Number = ( degenerate ) ? v1yPos : ( v1y - cny );
			
				vertices[vertCounter++] = v1xPos;
				vertices[vertCounter++] = v1yPos;
				vertices[vertCounter++] = 0;
				vertices[vertCounter++] = v1.r2;
				vertices[vertCounter++] = v1.g2;
				vertices[vertCounter++] = v1.b2;
				vertices[vertCounter++] = v1.a2;
				vertices[vertCounter++] = v1.u;
				vertices[vertCounter++] = 1;
				vertices[vertCounter++] = v1xNeg;
				vertices[vertCounter++] = v1yNeg;
				vertices[vertCounter++] = 0;
				vertices[vertCounter++] = v1.r1;
				vertices[vertCounter++] = v1.g1;
				vertices[vertCounter++] = v1.b1;
				vertices[vertCounter++] = v1.a1;
				vertices[vertCounter++] = v1.u;
				vertices[vertCounter++] = 0;
				
				if ( i < numVertices - 1 )
				{
					var i2:int = (i << 1);
					indices[indiciesCounter++] = i2;
					indices[indiciesCounter++] = i2+2;
					indices[indiciesCounter++] = i2+1;
					indices[indiciesCounter++] = i2+1;
					indices[indiciesCounter++] = i2+2;
					indices[indiciesCounter++] = i2+3;
				}
				
			}
		}
		
		///////////////////////////////////
		// Static helper methods - Old version of createPolyLine that does not use pre allocated vectors. Slower.
		///////////////////////////////////
		[inline]
		protected static function createPolyLine( vertices:Vector.<StrokeVertex>, 
												outputVertices:Vector.<Number>, 
												outputIndices:Vector.<uint>, 
												indexOffset:int ):void
		{
			
			var sqrt:Function = Math.sqrt;
			var sin:Function = Math.sin;
			const numVertices:int = vertices.length;
			const PI:Number = Math.PI;
			
			for ( var i:int = 0; i < numVertices; i++ )
			{
				var degenerate:uint = vertices[i].degenerate;
				var idx:uint = i;
				if ( degenerate != 0 ) {
					idx = ( degenerate == c_degenerateUseLast ) ? ( i - 1 ) : ( i + 1 );
				}
				var treatAsFirst:Boolean = ( idx == 0 ) || ( vertices[ idx - 1 ].degenerate > 0 );
				var treatAsLast:Boolean = ( idx == numVertices - 1 ) || ( vertices[ idx + 1 ].degenerate > 0 );
				var idx0:uint = treatAsFirst ? idx : ( idx - 1 );
				var idx2:uint = treatAsLast ? idx : ( idx + 1 );
				
				var v0:StrokeVertex = vertices[idx0];
				var v1:StrokeVertex = vertices[idx];
				var v2:StrokeVertex = vertices[idx2];
				
				var v0x:Number = v0.x;
				var v0y:Number = v0.y;
				var v1x:Number = v1.x;
				var v1y:Number = v1.y;
				var v2x:Number = v2.x;
				var v2y:Number = v2.y;
				
				var d0x:Number = v1x - v0x;
				var d0y:Number = v1y - v0y;
				var d1x:Number = v2x - v1x;
				var d1y:Number = v2y - v1y;
				
				if ( treatAsLast )
				{
					v2x += d0x;
					v2y += d0y;
					
					d1x = v2x - v1x;
					d1y = v2y - v1y;
				}
				
				if ( treatAsFirst )
				{
					v0x -= d1x;
					v0y -= d1y;
					
					d0x = v1x - v0x;
					d0y = v1y - v0y;
				}
				
				var d0:Number = sqrt( d0x*d0x + d0y*d0y );
				var d1:Number = sqrt( d1x*d1x + d1y*d1y );
				
				var elbowThickness:Number = v1.thickness*0.5;
				if ( !(treatAsFirst || treatAsLast) )
				{
					// Thanks to Tom Clapham for spotting this relationship.
					var dot:Number = (d0x*d1x+d0y*d1y) / (d0*d1);
					elbowThickness /= sin((PI-Math.acos(dot)) * 0.5);
					
					if ( elbowThickness > v1.thickness * 4 )
					{
						elbowThickness = v1.thickness * 4;
					}
					
					if ( isNaN( elbowThickness ) )
					{
						elbowThickness = v1.thickness*0.5;
					}
				}
				
				var n0x:Number = -d0y / d0;
				var n0y:Number =  d0x / d0;
				var n1x:Number = -d1y / d1;
				var n1y:Number =  d1x / d1;
				
				var cnx:Number = n0x + n1x;
				var cny:Number = n0y + n1y;
				var c:Number = (1/sqrt( cnx*cnx + cny*cny )) * elbowThickness;
				cnx *= c;
				cny *= c;
				
				var v1xPos:Number = v1x + cnx;
				var v1yPos:Number = v1y + cny;
				var v1xNeg:Number = ( degenerate ) ? v1xPos : ( v1x - cnx );
				var v1yNeg:Number = ( degenerate ) ? v1yPos : ( v1y - cny );
			
				
				outputVertices.push( v1xPos, v1yPos, 0, v1.r2, v1.g2, v1.b2, v1.a2, v1.u, 1,
								 v1xNeg, v1yNeg, 0, v1.r1, v1.g1, v1.b1, v1.a1, v1.u, 0 );
				
				
				if ( i < numVertices - 1 )
				{
					var i2:int = indexOffset + (i << 1);
					outputIndices.push(i2, i2 + 2, i2 + 1, i2 + 1, i2 + 2, i2 + 3);
				}
			}
		}
		
		protected static function fixUpPolyLine( vertices:Vector.<StrokeVertex> ): int
		{
			
			if ( vertices.length > 0 && vertices[0].degenerate > 0 ) { throw ( new Error("Degenerate on first line vertex") ); }
			var idx:int = vertices.length - 1;
			while ( idx > 0 && vertices[idx].degenerate > 0 )
			{
				vertices.pop();
				idx--;
			}
			return vertices.length;
		}
		
		override protected function shapeHitTestLocalInternal( localX:Number, localY:Number ):Boolean
		{
			if ( _line == null ) return false;
			if ( _line.length < 2 ) return false;
			
			var numLines:int = _line.length;
			
			for ( var i: int = 1; i < numLines; i++ )
			{
				var v0:StrokeVertex = _line[i - 1];
				var v1:StrokeVertex = _line[i];
				
				var lineLengthSquared:Number = (v1.x - v0.x) * (v1.x - v0.x) + (v1.y - v0.y) * (v1.y - v0.y);
				
				var interpolation:Number = ( ( ( localX - v0.x ) * ( v1.x - v0.x ) ) + ( ( localY - v0.y ) * ( v1.y - v0.y ) ) )  /	( lineLengthSquared );
				if( interpolation < 0.0 || interpolation > 1.0 )
					continue;   // closest point does not fall within the line segment
					
				var intersectionX:Number = v0.x + interpolation * ( v1.x - v0.x );
				var intersectionY:Number = v0.y + interpolation * ( v1.y - v0.y );
				
				var distanceSquared:Number = (localX - intersectionX) * (localX - intersectionX) + (localY - intersectionY) * (localY - intersectionY);
				
				var intersectThickness:Number = (v0.thickness * (1.0 - interpolation) + v1.thickness * interpolation); // Support for varying thicknesses
				
				intersectThickness += _precisionHitTestDistance;
				
				if ( distanceSquared <= intersectThickness * intersectThickness)
					return true;
			}
				
			return false;
		}
		
		/** Transforms a point from the local coordinate system to parent coordinates.
         *  If you pass a 'resultPoint', the result will be stored in this point instead of 
         *  creating a new object. */
        public function localToParent(localPoint:Point, resultPoint:Point=null):Point
        {
            return MatrixUtil.transformCoords(transformationMatrix, localPoint.x, localPoint.y, resultPoint);
        }
		
		
		public static function strokeCollideTest(s1:Stroke, s2:Stroke, intersectPoint:Point, staticLenIntersectPoints:Vector.<Point> = null ) : Boolean
		{
			if ( s1 == null || s2 == null ||  s1._line == null || s1._line == null )
				return false;
				
				
			if ( sCollissionHelper == null )
				sCollissionHelper  = new StrokeCollisionHelper();
			sCollissionHelper.testIntersectPoint.x = 0;
			sCollissionHelper.testIntersectPoint.y = 0;
			intersectPoint.x = 0;
			intersectPoint.y = 0;
			var hasSameParent:Boolean = false;
			if ( s1.parent == s2.parent )
				hasSameParent = true;

			s1.getBounds(hasSameParent ? s1.parent: s1.stage, sCollissionHelper.bounds1);
			s2.getBounds(hasSameParent ? s2.parent: s2.stage, sCollissionHelper.bounds2);
			if ( sCollissionHelper.bounds1.intersects(sCollissionHelper.bounds2) == false )
				return false;
			
		
			if ( intersectPoint == null )
				intersectPoint = new Point();
			var numLinesS1:int = s1._line.length;
			var numLinesS2:int = s2._line.length;
			var hasHit:Boolean = false;
			
			
			if ( sCollissionHelper.s2v0Vector == null || sCollissionHelper.s2v0Vector.length < numLinesS2 )
			{
				sCollissionHelper.s2v0Vector = new Vector.<Point>(numLinesS2, true);
				sCollissionHelper.s2v1Vector = new Vector.<Point>(numLinesS2, true);
			}
			
			var pointCounter:int = 0;
			var maxPointCounter:int = 0;
			if ( staticLenIntersectPoints != null )
				maxPointCounter = staticLenIntersectPoints.length;
			
			for ( var i: int = 1; i < numLinesS1; i++ )
			{
				var s1v0:StrokeVertex = s1._line[i - 1];
				var s1v1:StrokeVertex = s1._line[i];
				
				sCollissionHelper.localPT1.setTo(s1v0.x, s1v0.y);
				sCollissionHelper.localPT2.setTo(s1v1.x, s1v1.y);
				if ( hasSameParent )
				{
					s1.localToParent(sCollissionHelper.localPT1, sCollissionHelper.globalPT1);
					s1.localToParent(sCollissionHelper.localPT2, sCollissionHelper.globalPT2);
				}
				else
				{
					s1.localToGlobal(sCollissionHelper.localPT1, sCollissionHelper.globalPT1);
					s1.localToGlobal(sCollissionHelper.localPT2, sCollissionHelper.globalPT2);
				}
			
			
				for	( var j: int = 1; j < numLinesS2; j++ )
				{
					var s2v0:StrokeVertex = s2._line[j - 1];
					var s2v1:StrokeVertex = s2._line[j];
				
					if ( i == 1 )
					{ // when we do the first loop through this set, we can cache all global points in s2v0Vector and s2v1Vector, to avoid slow localToGlobals on next loop passes
						sCollissionHelper.localPT3.setTo(s2v0.x, s2v0.y);
						sCollissionHelper.localPT4.setTo(s2v1.x, s2v1.y);
						
						if ( hasSameParent )
						{
							s2.localToParent(sCollissionHelper.localPT3, sCollissionHelper.globalPT3);
							s2.localToParent(sCollissionHelper.localPT4, sCollissionHelper.globalPT4);
						}
						else	
						{
							s2.localToGlobal(sCollissionHelper.localPT3, sCollissionHelper.globalPT3);
							s2.localToGlobal(sCollissionHelper.localPT4, sCollissionHelper.globalPT4);
						}
							
						if ( sCollissionHelper.s2v0Vector[j] == null )
						{
							sCollissionHelper.s2v0Vector[j] = new Point(sCollissionHelper.globalPT3.x, sCollissionHelper.globalPT3.y);
							sCollissionHelper.s2v1Vector[j] = new Point(sCollissionHelper.globalPT4.x, sCollissionHelper.globalPT4.y);
						}
						else
						{
							sCollissionHelper.s2v0Vector[j].x = sCollissionHelper.globalPT3.x;
							sCollissionHelper.s2v0Vector[j].y = sCollissionHelper.globalPT3.y;
							sCollissionHelper.s2v1Vector[j].x = sCollissionHelper.globalPT4.x;
							sCollissionHelper.s2v1Vector[j].y = sCollissionHelper.globalPT4.y;
						}
					}
					else
					{
						sCollissionHelper.globalPT3.x = sCollissionHelper.s2v0Vector[j].x;
						sCollissionHelper.globalPT3.y = sCollissionHelper.s2v0Vector[j].y;
						
						sCollissionHelper.globalPT4.x = sCollissionHelper.s2v1Vector[j].x;
						sCollissionHelper.globalPT4.y = sCollissionHelper.s2v1Vector[j].y;
					}
						
					if ( TriangleUtil.lineIntersectLine(sCollissionHelper.globalPT1.x, sCollissionHelper.globalPT1.y, sCollissionHelper.globalPT2.x, sCollissionHelper.globalPT2.y, sCollissionHelper.globalPT3.x, sCollissionHelper.globalPT3.y, sCollissionHelper.globalPT4.x, sCollissionHelper.globalPT4.y, sCollissionHelper.testIntersectPoint) )
					{
						if ( staticLenIntersectPoints != null && pointCounter < (maxPointCounter-1) )
						{
							if ( hasSameParent )
								s1.parent.localToGlobal(sCollissionHelper.testIntersectPoint, staticLenIntersectPoints[pointCounter])
							else
							{
								staticLenIntersectPoints[pointCounter].x = sCollissionHelper.testIntersectPoint.x;
								staticLenIntersectPoints[pointCounter].y = sCollissionHelper.testIntersectPoint.y;
							}
							pointCounter++;
							staticLenIntersectPoints[pointCounter].x = NaN;
							staticLenIntersectPoints[pointCounter].y = NaN;
						}
						
						if ( sCollissionHelper.testIntersectPoint.length > intersectPoint.length )
						{
							if ( hasSameParent )
								s1.parent.localToGlobal(sCollissionHelper.testIntersectPoint, intersectPoint);
							else
							{
								intersectPoint.x = sCollissionHelper.testIntersectPoint.x;
								intersectPoint.y = sCollissionHelper.testIntersectPoint.y;
							}
							
						}
						hasHit = true;
					}
				}
			}
			
			return hasHit;
		}
	}
}

import flash.geom.Point;
import flash.geom.Rectangle;

class StrokeCollisionHelper
{
	public var localPT1:Point = new Point();	
	public var localPT2:Point = new Point();	
	public var localPT3:Point = new Point();	
	public var localPT4:Point = new Point();	
			
	public var globalPT1:Point = new Point();	
	public var globalPT2:Point = new Point();	
	public var globalPT3:Point = new Point();		
	public var globalPT4:Point = new Point();	
	
	public var bounds1:Rectangle = new Rectangle();
	public var bounds2:Rectangle = new Rectangle();
	
	public var testIntersectPoint:Point = new Point();
	public var s1v0Vector:Vector.<Point> = null;
	public var s1v1Vector:Vector.<Point>= null;
	public var s2v0Vector:Vector.<Point>= null;
	public var s2v1Vector:Vector.<Point>= null;
}