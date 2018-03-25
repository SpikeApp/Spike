package services
{
	import mx.utils.ObjectUtil;
	
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
			
			//ObjectUtil.toString(Database.getLatestCalibrations(4, Sensor.getActiveSensor().uniqueId));
		}
	}
}