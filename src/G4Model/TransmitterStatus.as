package G4Model
{
	public class TransmitterStatus
	{
		public static const LOW:String = "LOW";
		public static const OK:String = "OK";
		public static const UNKNOWN:String = "UNKNOWN";
		public static const EMPTY:String = "EMPTY";
		public static const TRANSMITTER_BATTERY_LOW:int = 210;
		public static const TRANSMITTER_BATTERY_EMPTY:int = 207;

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
			if (b <= TRANSMITTER_BATTERY_EMPTY) {
				returnValue._batteryLevel = EMPTY;
			}
			else {
				if (b < TRANSMITTER_BATTERY_LOW) {
					returnValue._batteryLevel = LOW;
				}
				else {
					returnValue._batteryLevel = OK;
				}
			}
			return returnValue;
		}
	}
}