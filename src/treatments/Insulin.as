package treatments
{
	import flash.utils.setInterval;
	import flash.utils.setTimeout;

	public class Insulin
	{
		private static var dia:Number = 2;
		private static var scaleFactor:Number = 3 / dia;
		private static var peak:uint = 75;
		private static var bolusTime:Number = new Date(2018, 1, 14, 3, 30).valueOf();
		private static var bolusAmount:Number = 4.5;
		
		public function Insulin()
		{
			
		}
		
		public static function init():void
		{
			setInterval(getCOB, 1000);
		}
		
		public static function getIOB():void
		{
			var time:Number = new Date().valueOf();
			var minAgo:Number = scaleFactor * (time - bolusTime) / 1000 / 60;
			var iob:Number;
			
			if (minAgo < peak) 
			{
				var x1:Number = minAgo / 5 + 1;
				iob = bolusAmount * (1 - 0.001852 * x1 * x1 + 0.001852 * x1);
			} else if (minAgo < 180) 
			{
				var x2:Number = (minAgo - 75) / 5;
				iob = bolusAmount * (0.001323 * x2 * x2 - 0.054233 * x2 + 0.55556);
			}
			
			if (iob < 0.001)
				iob = 0;
			
			trace("IOB:", iob);
		}
		
		public static function getCOB():void
		{	
			var carbs:Number = 45;
			var timestamp:Number = new Date(2018, 1, 14, 4, 49).valueOf();
			
			var carbsPerHour:Number = 20;
			var carbsPerMinute:Number = carbsPerHour / 60;
			var elapsedMinutes:Number = ((new Date().valueOf() - timestamp) / 1000) / 60 ;
			
			
			
			
			var cob:Number = carbs - (carbsPerMinute * elapsedMinutes);
		}
	}
}