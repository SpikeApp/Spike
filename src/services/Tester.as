package services
{
	import mx.utils.ObjectUtil;
	
	import database.BgReading;
	import database.Calibration;
	import database.Database;
	import database.Sensor;

	public class Tester
	{
		public function Tester()
		{
		}
		
		public static function init():void
		{
			trace("TESTER INIT");
			
			//BgReading.last30Minutes();
		}
	}
}