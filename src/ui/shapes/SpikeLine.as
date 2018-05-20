package ui.shapes
{
	import starling.display.Canvas;
	import starling.display.MeshBatch;
	import starling.display.Quad;
	
	public class SpikeLine extends Canvas
	{
		private var _thickness:Number = 1;
		private var _color:uint = 0;
		private var _alpha:Number = 1;
		private var _fromX:Number;
		private var _fromY:Number;
		private var _toX:Number;
		private var _toY:Number;
		private var line :Quad;
		private var batch :MeshBatch;
		
		public function SpikeLine()
		{
			super();
			addChild (batch = new MeshBatch ());
		}
		
		public function lineStyle(thickness:Number = 1, color:uint = 0, alpha:Number = 1):void
		{
			_thickness = thickness;
			_color = color;
			_alpha = alpha;
		}
		
		public function moveTo(x:Number, y:Number):void
		{
			_fromX = x;
			_fromY = y;
		}
		
		public function lineTo(x:Number, y:Number, startColor:Number = Number.NaN, endColor:Number = Number.NaN):void
		{
			_toX = x;
			_toY = y;
			
			line = new Quad (_thickness, _thickness, _color);
			
			var fXOffset:Number = _toX - _fromX;
			var fYOffset:Number = _toY - _fromY;
			var len:Number = Math.sqrt(fXOffset * fXOffset + fYOffset * fYOffset);
			fXOffset = fXOffset * _thickness / (len * 2);
			fYOffset = fYOffset * _thickness / (len * 2);
			
			line. setVertexPosition(2, _fromX + fYOffset, _fromY - fXOffset);
			line. setVertexPosition(1, _toX  - fYOffset, _toY + fXOffset);
			line. setVertexPosition(0, _toX  + fYOffset, _toY - fXOffset);
			line. setVertexPosition(3, _fromX - fYOffset, _fromY + fXOffset);
			
			if (!isNaN(startColor) && !isNaN(endColor))
			{
				line.setVertexColor(2, startColor);
				line.setVertexColor(3, startColor);
				line.setVertexColor(0, endColor);
				line.setVertexColor(1, endColor);
			}
			
			line.alpha = _alpha;
			
			batch.addMesh (line);
			
			_fromX = x;
			_fromY = y;
		}
		
		override public function clear():void
		{
			batch.clear();
		}
		
		override public function dispose():void
		{
			if (batch != null)
			{
				batch.clear();
				batch.dispose();
				batch = null;
			}
			
			if (line != null)
			{
				line.dispose();
				line = null;
			}
			
			super.dispose();
		}
	}
}