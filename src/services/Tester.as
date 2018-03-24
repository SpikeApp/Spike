package services
{
	import mx.utils.ObjectUtil;
	
	import database.Calibration;

	public class Tester
	{
		public function Tester()
		{
		}
		
		public static function init():void
		{
			trace("TESTER INIT");
			
			trace(ObjectUtil.toString(Calibration.allForSensor()));
		}
	}
}