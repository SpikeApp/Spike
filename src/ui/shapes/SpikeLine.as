package ui.shapes
{
	import starling.display.Quad;
	import starling.display.Sprite;
	
	public class SpikeLine extends Sprite
	{
		private var baseQuad:Quad;
		private var _thickness:Number = 1;
		private var _color:uint = 0x000000;
		
		public function SpikeLine()
		{
			baseQuad = new Quad(1, _thickness, _color);
			addChild(baseQuad);
		}
		
		public function lineTo(toX:int, toY:int):void
		{
			var toX2:int = toX-this.x;
			var toY2:int = toY-this.y;
			baseQuad.rotation = 0;
			baseQuad.width = Math.round(Math.sqrt((toX2*toX2)+(toY2*toY2)));
			baseQuad.rotation = Math.atan2(toY2, toX2);
		}
		
		public function set thickness(t:Number):void
		{
			var currentRotation:Number = baseQuad.rotation;
			baseQuad.rotation = 0;
			baseQuad.height = _thickness = t;
			baseQuad.rotation = currentRotation;
		}
		
		public function get thickness():Number
		{
			return _thickness;
		}
		
		public function set color(c:uint):void
		{
			baseQuad.color = _color = c;
		}
		
		public function get color():uint
		{
			return _color;
		}
		
		override public function dispose():void
		{
			baseQuad.dispose();
			
			super.dispose();
		}
	}
}