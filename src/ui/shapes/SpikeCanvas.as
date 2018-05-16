package ui.shapes
{
	import flash.geom.Point;
	
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Mesh;
	import starling.geom.Polygon;
	import starling.rendering.IndexData;
	import starling.rendering.VertexData;
	
	/** A display object supporting basic vector drawing functionality. In its current state,
	 *  the main use of this class is to provide a range of forms that can be used as masks.
	 */
	public class SpikeCanvas extends DisplayObjectContainer
	{
		private var _polygons:Vector.<Polygon>;
		private var _fillColor:uint;
		private var _fillAlpha:Number;
		
		/** Creates a new (empty) Canvas. Call one or more of the 'draw' methods to add content. */
		public function SpikeCanvas()
		{
			_polygons  = new <Polygon>[];
			_fillColor = 0xffffff;
			_fillAlpha = 1.0;
			touchGroup = true;
		}
		
		public override function dispose():void
		{
			_polygons.length = 0;
			super.dispose();
		}
		
		/** @inheritDoc */
		public override function hitTest(localPoint:Point):DisplayObject
		{
			if (!visible || !touchable || !hitTestMask(localPoint)) return null;
			
			// we could also use the standard hit test implementation, but the polygon class can
			// do that much more efficiently (it contains custom implementations for circles, etc).
			
			for (var i:int = 0, len:int = _polygons.length; i < len; ++i)
				if (_polygons[i].containsPoint(localPoint)) return this;
			
			return null;
		}
		
		/** Draws a circle. */
		public function drawCircle(x:Number, y:Number, radius:Number):void
		{
			appendPolygon(Polygon.createCircle(x, y, radius));
		}
		
		/** Draws an ellipse. */
		public function drawEllipse(x:Number, y:Number, width:Number, height:Number):void
		{
			var radiusX:Number = width  / 2.0;
			var radiusY:Number = height / 2.0;
			
			appendPolygon(Polygon.createEllipse(x + radiusX, y + radiusY, radiusX, radiusY));
		}
		
		/** Draws a rectangle. */
		public function drawRectangle(x:Number, y:Number, width:Number, height:Number):void
		{
			appendPolygon(Polygon.createRectangle(x, y, width, height));
		}
		
		/** Draws an arbitrary polygon. */
		public function drawPolygon(polygon:Polygon):void
		{
			appendPolygon(polygon);
		}
		
		/** Specifies a simple one-color fill that subsequent calls to drawing methods
		 *  (such as <code>drawCircle()</code>) will use. */
		public function beginFill(color:uint=0xffffff, alpha:Number=1.0):void
		{
			_fillColor = color;
			_fillAlpha = alpha;
		}
		
		/** Resets the color to 'white' and alpha to '1'. */
		public function endFill():void
		{
			_fillColor = 0xffffff;
			_fillAlpha = 1.0;
		}
		
		public function clear():void
		{
			removeChildren(0, -1, true);
			_polygons.length = 0;
		}
		
		private function appendPolygon(polygon:Polygon):void
		{
			var vertexData:VertexData = new VertexData();
			var indexData:IndexData = new IndexData(polygon.numTriangles * 3);
			
			polygon.triangulate(indexData);
			polygon.copyToVertexData(vertexData);
			
			vertexData.colorize("color", _fillColor, _fillAlpha);
			
			addChild(new Mesh(vertexData, indexData));
			_polygons[_polygons.length] = polygon;
		}
		
		public function drawRoundRectangle(x:Number, y:Number, width:Number, height:Number, radius:Number, numSides:int = 1):void
		{
			appendPolygon(Polygon.createCircle(x + radius, y + radius, radius, numSides));
			appendPolygon(Polygon.createCircle(x + width - radius, y + radius, radius, numSides));
			appendPolygon(Polygon.createCircle(x + radius, y + height - radius, radius, numSides));
			appendPolygon(Polygon.createCircle(x + + width - radius, y + height - radius, radius, numSides));
			appendPolygon(Polygon.createRectangle(x + radius, y, width - radius*2, height));
			appendPolygon(Polygon.createRectangle(x, y + radius, width, height - radius*2));
		}
	}
}