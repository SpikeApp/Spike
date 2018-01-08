package starling.display.graphics
{
	
	public class StrokeVertex
	{
		public var x:Number;
		public var y:Number;
		public var u:Number;
		public var v:Number;
		public var r1:Number;
		public var g1:Number;
		public var b1:Number;
		public var a1:Number;
		public var r2:Number;
		public var g2:Number;
		public var b2:Number;
		public var a2:Number;
		public var thickness:Number;
		public var degenerate:uint;
		
		public function StrokeVertex()
		{
		
		}
		
		public function clone():StrokeVertex
		{
			var vertex:StrokeVertex = getInstance();
			vertex.x = x;
			vertex.y = y;
			vertex.r1 = r1;
			vertex.g1 = g1;
			vertex.b1 = b1;
			vertex.a1 = a1;
			vertex.u = u;
			vertex.v = v;
			vertex.degenerate = degenerate;
			return vertex;
		}
		
		private static var pool:Vector.<StrokeVertex> = new Vector.<StrokeVertex>();
		private static var poolLength:int = 0;
		
		public static function getInstance():StrokeVertex
		{
			if (poolLength == 0)
			{
				return new StrokeVertex();
			}
			poolLength--;
			return pool.pop();
		}
		
		public static function returnInstance(instance:StrokeVertex):void
		{
			pool[poolLength] = instance;
			poolLength++;
		}
		
		public static function returnInstances(instances:Vector.<StrokeVertex>):void
		{
			var L:int = instances.length;
			for (var i:int = 0; i < L; i++)
			{
				pool[poolLength] = instances[i];
				poolLength++;
			}
		}
	}

}