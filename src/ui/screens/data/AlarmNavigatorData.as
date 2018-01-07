package ui.screens.data
{
	public class AlarmNavigatorData 
	{
		/* Constants */
		public static const ALARM_TYPE_CALIBRATION:String = "calibration";
		public static const ALARM_TYPE_GLUCOSE:String = "glucose";
		public static const ALARM_TYPE_MISSED_READING:String = "missedReading";
		public static const ALARM_TYPE_PHONE_MUTED:String = "phoneMuted";
		public static const ALARM_TYPE_TRANSMITTER_LOW_BATTERY:String = "transmitterLowBattery";
		
		/* Properties */
		private static var instance:AlarmNavigatorData;
		private var _alarmID:Number;
		private var _alarmTitle:String;
		private var _alarmType:String;
		
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
		public function get alarmID():Number
		{
			return _alarmID;
		}
		
		public function set alarmID(value:Number):void
		{
			_alarmID = value;
		}

		public function get alarmTitle():String
		{
			return _alarmTitle;
		}

		public function set alarmTitle(value:String):void
		{
			_alarmTitle = value;
		}

		public function get alarmType():String
		{
			return _alarmType;
		}

		public function set alarmType(value:String):void
		{
			_alarmType = value;
		}
	}
}

// Helpers
internal class SingletonBlocker {}