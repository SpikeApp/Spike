package data
{
	public class AlarmNavigatorData 
	{
		public static const BATTERY_LOW:String = "batteryLow";
		public static const CALIBRATION:String = "calibration";
		public static const MISSED_READING:String = "missedReading";
		public static const PHONE_MUTED:String = "phoneMuted";
		public static const URGENT_LOW:String = "urgentLow";
		public static const LOW:String = "low";
		public static const HIGH:String = "high";
		public static const URGENT_HIGH:String = "urgentHigh";
		
		private static var instance:AlarmNavigatorData;
		
		private var _selectedAlarm:String;
		private var _selectedAlarmTitle:String;
		
		public static function getInstance():AlarmNavigatorData 
		{
			if (instance == null) 
			{
				instance = new AlarmNavigatorData(new SingletonBlocker());
			}
			
			return instance;
		}

		public function AlarmNavigatorData(key:SingletonBlocker):void 
		{
			if (key == null) 
			{
				throw new Error("Error: Instantiation failed: Use AlarmNavigatorData.getInstance() instead of new.");
			}
		}
		
		/**
		 * Getters & Setters
		 */
		public function get selectedAlarm():String
		{
			return _selectedAlarm;
		}
		
		public function set selectedAlarm(value:String):void
		{
			_selectedAlarm = value;
		}

		public function get selectedAlarmTitle():String
		{
			return _selectedAlarmTitle;
		}

		public function set selectedAlarmTitle(value:String):void
		{
			_selectedAlarmTitle = value;
		}

	}
}

// Helpers
internal class SingletonBlocker {}