package starling.display.graphics
{
	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.textures.Texture;
	
	public class TriangleFan extends Graphic
	{
		private var numVertices		:int;
		
		public function TriangleFan()
		{
			vertices.push(0,0,0,1,1,1,1,0,0);
			numVertices++;
		}
		
		public function addVertex( 	x:Number, y:Number, u:Number = 0, v:Number = 0, r:Number = 1, g:Number = 1, b:Number = 1, a:Number = 1 ):void
		{
			vertices.push( x, y, 0, r, g, b, a, u, v );
			numVertices++;
			
			minBounds.x = x < minBounds.x ? x : minBounds.x;
			minBounds.y = y < minBounds.y ? y : minBounds.y;
			maxBounds.x = x > maxBounds.x ? x : maxBounds.x;
			maxBounds.y = y > maxBounds.y ? y : maxBounds.y;
			
			if ( numVertices > 2 )
			{
				indices.push( 0, numVertices-2, numVertices-1 );
			}
			
			setGeometryInvalid();
		}
		
		public function modifyVertexPosition(index:int, x:Number, y:Number) : void
		{
			vertices[index * 9] = x;
			vertices[index * 9 + 1] = y;
			
			if ( isInvalid == false )
				setGeometryInvalid();
		}
		
		public function clear():void
		{
			vertices.length = 0;
			indices.length = 0;
			numVertices =  0;
			setGeometryInvalid();
		}
		
		override protected function buildGeometry():void
		{
			
		}
	}
}