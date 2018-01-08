package starling.display.graphics
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import starling.rendering.Painter;
	import starling.core.Starling;
	import starling.display.DisplayObject;

	public class Plane extends Graphic
	{
		private var _width			:Number;
		private var _height			:Number;
		private var _numVerticesX	:uint;
		private var _numVerticesY	:uint;
		private var _vertexFunction	:Function;
		
		public function Plane( width:Number = 100, height:Number = 100, numVerticesX:uint = 2, numVerticesY:uint = 2 )
		{
			_width = width;
			_height = height;
			_numVerticesX = numVerticesX;
			_numVerticesY = numVerticesY;
			_vertexFunction = defaultVertexFunction;
			setGeometryInvalid();
		}
		
		public static function defaultVertexFunction( column:int, row:int, width:Number, height:Number, numVerticesX:int, numVerticesY:int, output:Vector.<Number>, uvMatrix:Matrix = null ):void
		{
			var segmentWidth:Number = width / (numVerticesX-1);
			var segmentHeight:Number = height / (numVerticesY-1);
			
			output.push( 	segmentWidth * column, 		// x
							segmentHeight * row,		// y
							0,							// z
							1,1,1,1,					// rgba
							column / (numVerticesX-1), 	// u
							row / (numVerticesY-1) );	// v
		}
		
		public function set vertexFunction( value:Function ):void
		{
			if ( value == null )
			{
				throw( new Error( "Value must not be null" ) );
				return;
			}
			_vertexFunction = value;
			setGeometryInvalid();
		}
		
		public function get vertexFunction():Function
		{
			return _vertexFunction
		}
		
		override protected function buildGeometry():void
		{
			vertices = new Vector.<Number>();
			indices = new Vector.<uint>();
			
			// Generate vertices
			var numVertices:int = _numVerticesX * _numVerticesY;
			for ( var i:int = 0; i < numVertices; i++ )
			{
				var column:int = i % _numVerticesX;
				var row:int = i / _numVerticesX;
				_vertexFunction( column, row, _width, _height, _numVerticesX, _numVerticesY, vertices, _uvMatrix );
			}
			
			// Generate indices
			var qn:int = 0; //quad number
			for (var n:int = 0; n <_numVerticesX-1; n++) //create quads out of the vertices
			{               
				for (var m:int = 0; m <_numVerticesY - 1; m++)
				{
					
					indices.push(qn, qn + 1, qn + _numVerticesX ); //upper face
					indices.push(qn + _numVerticesX, qn + _numVerticesX  + 1, qn+1); //lower face
					
					qn++; //jumps to next quad
				}
				qn++; // jumps to next row
			}
		}
		
		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
		{
			minBounds.x = 0;
			minBounds.y = 0;
			maxBounds.x = _width;
			maxBounds.y = _height;
			return super.getBounds(targetSpace, resultRect);
		}
	}
}