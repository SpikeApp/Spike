package utils
{
	import com.spikeapp.spike.airlibrary.SpikeANE;

	public class BatteryInfo
	{
		/* Constants */
		public static const BATTERY_STATUS_UNKNOWN:int = 0;
		public static const BATTERY_STATUS_UNPLUGGED:int = 1;
		public static const BATTERY_STATUS_CHARGING:int = 2;
		public static const BATTERY_STATUS_FULL:int = 3;
		
		public function BatteryInfo()
		{
			throw new Error("BatteryInfo class is not meant to be instantiated!");
		}
		
		public static function getBatteryLevel():Number
		{
			return Math.round(SpikeANE.getBatteryLevel());
		}
		
		public static function getBatteryStatus():int
		{
			return SpikeANE.getBatteryStatus();
		}
	}
}