package G5Model
{
	public class TransmitterStatus
	{
		public static const BRICKED:String = "BRICKED";
		public static const LOW:String = "LOW";
		public static const OK:String = "OK";
		public static const UNKNOWN:String = "UNKNOWN";
		public static const LOW_BATTERY_WARNING_LEVEL_VOLTAGEA:int = 300;
		public static const LOW_BATTERY_WARNING_LEVEL_VOLTAGEB:int = 290;
		public static const RESIST_BAD:int = 1400;
		public static const RESIST_NOTICE:int = 1000;
		public static const RESIST_NORMAL:int = 750
		
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