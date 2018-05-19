package ui.shapes
{
	import starling.display.Mesh;
	import starling.rendering.IndexData;
	import starling.rendering.VertexData;
	import starling.styles.MeshStyle;
	
	public class SpikeNGon extends Mesh
	{
		// properties
		private var _sides		:int;
		private var _tint		:uint;
		private var _radius		:Number;
		private var _alpha		:Number;
		private var _startAngle	:Number;
		private var _endAngle	:Number;
		
		public function SpikeNGon(radius:Number = 100, sides:int = 10, startAngle:Number = 0, endAngle:Number = 360, colour:uint = 0, alpha:Number = 1.0) 
		{
			_sides = sides;
			_radius = radius;
			_tint = colour;
			_alpha = alpha;
			_startAngle = startAngle - 90;
			_endAngle = endAngle - 90;
			
			pixelSnapping = false;
			
			var vertexData:VertexData = new VertexData(
				MeshStyle.VERTEX_FORMAT, 1 + _sides);
			var indexData:IndexData = new IndexData(3 * _sides);
			
			super(vertexData, indexData);
			
			setupVertices();
			updateVertices();
			updateColours();
			setRequiresRedraw();
		}
		
		public function set radius(val:Number):void 
		{
			if (_radius != val) 
			{
				_radius = val;
				updateVertices();
				setRequiresRedraw();
			}
		}
		
		public function set colour(val:uint):void 
		{
			if (_tint != val) 
			{
				_tint = val;
				updateColours();
				setRequiresRedraw();
			}
		}
		
		public function set pieAlpha(val:Number):void 
		{
			if (_alpha != val) 
			{
				_alpha = val;
				updateColours();
				setRequiresRedraw();
			}
		}
		
		public function colourise(fAlpha:Number, iTint:uint):void 
		{
			_alpha = fAlpha;
			_tint = iTint;
			updateColours();
			setRequiresRedraw();
		}
		
		private function updateColours():void 
		{
			var colAttr:String = "color";
			var vData:VertexData = vertexData;
			vData.colorize(colAttr, _tint, _alpha, 0, _sides + 1);
		}
		
		private function updateVertices():void 
		{
			var iRay:int, fX:Number, fY:Number, fA:Number;
			var fStart:Number = _startAngle * Math.PI / 180;
			var fEnd:Number = _endAngle * Math.PI / 180;
			var iNumVert:int = 0;
			var posAttr:String = "position";
			var vData:VertexData = vertexData;
			
			// centre
			vData.setPoint(0, posAttr, 0, 0);
			iNumVert++;
			
			for (iRay = 0; iRay < _sides + 1; iRay++) 
			{
				fA = fStart + (iRay / _sides) * (fEnd - fStart);
				fX =  Math.cos(fA) * _radius;
				fY =  Math.sin(fA) * _radius;
				vData.setPoint(iNumVert, posAttr, fX, fY);
				iNumVert++;
			}
		}
		
		private function setupVertices():void
		{
			var iRay:int;
			var iNumVert:int = 1;
			var vData:VertexData = vertexData;
			var iData:IndexData = indexData;
			
			if (_endAngle - _startAngle >= 360)
			{
				for (iRay = 0; iRay < _sides; iRay++) 
				{
					iNumVert++;
					if (iRay == _sides - 1) 
						iData.addTriangle(0, 1, iNumVert - 1);
					else
						iData.addTriangle(0, iNumVert, iNumVert - 1);
				}
			}
			else
			{
				iData.numIndices = 0;
				vData.numVertices = 1 + _sides;
				
				for (iRay = 0; iRay < _sides; iRay++) 
				{
					iNumVert++;
					iData.addTriangle(0, iNumVert, iNumVert - 1);
				}
			}
		}
	}
}