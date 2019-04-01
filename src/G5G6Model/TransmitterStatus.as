package G5G6Model
{
	public class TransmitterStatus
	{
		public static const BRICKED:String = "BRICKED";
		public static const LOW:String = "LOW";
		public static const OK:String = "OK";
		public static const UNKNOWN:String = "UNKNOWN";
		public static const LOW_BATTERY_WARNING_LEVEL_VOLTAGEA_G5:int = 300;
		public static const LOW_BATTERY_WARNING_LEVEL_VOLTAGEB_G5:int = 290;
		public static const LOW_BATTERY_WARNING_LEVEL_VOLTAGEA_G6:int = 290;
		public static const LOW_BATTERY_WARNING_LEVEL_VOLTAGEB_G6:int = 270;
		public static const RESIST_BAD_G5:int = 1400;
		public static const RESIST_NOTICE_G5:int = 1000;
		public static const RESIST_NORMAL_G5:int = 750
		public static const RESIST_BAD_G6:int = 1450;
		public static const RESIST_NOTICE_G6:int = 1300;
		public static const RESIST_NORMAL_G6:int = 1200
		
		private var _batteryLevel:String;

		public function get batteryLevel():String
		{
			return _batteryLevel;
		}
		
		public function toString() : String 
		{
			return _batteryLevel;
		}
		
		public function TransmitterStatus():void {
			_batteryLevel = UNKNOWN;
		}
		
		public static function getBatteryLevel(b:int):TransmitterStatus {
			var returnValue:TransmitterStatus = new TransmitterStatus();
			if (b > 0x81) {
				returnValue._batteryLevel = BRICKED;
			}
			else {
				if (b == 0x81) {
					returnValue._batteryLevel = LOW;
				}
				else if (b == 0x00) {
					returnValue._batteryLevel = OK;
				}
				else {
					returnValue._batteryLevel = UNKNOWN;
				}
			}
			return returnValue;
		}
	}
}