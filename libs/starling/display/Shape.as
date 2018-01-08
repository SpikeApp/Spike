package starling.display
{
	import starling.display.Graphics;
	import starling.events.EnterFrameEvent;
	
	public class Shape extends DisplayObjectContainer
	{
		private var _graphics :Graphics;
		private var gap : Number = 0.00000001;
		
		public function Shape()
		{
			_graphics = new Graphics(this);
			//addEventListener(EnterFrameEvent.ENTER_FRAME, _step);
		}
		
//		private function _step(e:EnterFrameEvent):void 
//		{
//			var lastX = this.x;
//			this.x = lastX + gap;
//			gap = -gap;
//		}
		
		public function get graphics():Graphics
		{
			return _graphics;
		}
		
		override public function dispose():void 
		{
			//removeEventListener(EnterFrameEvent.ENTER_FRAME, _step);
			super.dispose();
		}
		
	/*	override public function dispose() : void
		{
			if ( _graphics != null )
			{
				_graphics.dispose();
				_graphics = null;
			}
			super.dispose();
		} */
	}
}