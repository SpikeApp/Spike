package database
{
	

	public class Sensor extends SuperDatabaseClass
	{
		private var _startedAt:Number;
		public function get startedAt():Number
		{
			return _startedAt;
		}
		
		private var _stoppedAt:Number;
		public function get stoppedAt():Number
		{
			return _stoppedAt;
		}
		
		private var _latestBatteryLevel:int;

		public function set latestBatteryLevel(value:int):void
		{
			_latestBatteryLevel = value;
			Database.updateSensor(this);
		}

		public function get latestBatteryLevel():int
		{
			return _latestBatteryLevel;
		}
		
		public function Sensor(startedAt:Number, stoppedAt:Number, latestBatteryLevel:int, sensorId:String, lastmodifiedtimestamp:Number)
		{
			super(sensorId, lastmodifiedtimestamp);
			_startedAt = startedAt;
			_stoppedAt = stoppedAt;
			_latestBatteryLevel = latestBatteryLevel;
		}
		
		/**
		 * if sensor is active, then returns the active sensor<br>
		 * if sensor not active, then returns null<br>
		 */
		public static function getActiveSensor():Sensor {
			var sensorId:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR);
			if (sensorId == "0")
				return null;
			return Database.getSensor(sensorId);
		}
		
		/**
		 * starts a new sensor and inserts it in the database<br>
		 * if a sensor is currently active then it will be stopped<br>
		 * <br>
		 *  If timestamp isNaN then start time will be set to current time - 2 hours, otherwise it's assigned value of timestamp<br>
		 * Number.NaN is only to be used for testpurposes
		 */
		public static function startSensor(timestamp:Number = Number.NaN):void {
			if (isNaN(timestamp))
				timestamp = (new Date()).valueOf() - 2 * 60 * 60 * 1000;
			var currentSensor:Sensor = getActiveSensor();
			if (currentSensor != null) {
				currentSensor._stoppedAt = (new Date()).valueOf();
				currentSensor.resetLastModifiedTimeStamp();
				Database.updateSensor(currentSensor);
			}
			currentSensor = new Sensor(timestamp, 0, 0, null, Number.NaN);
			Database.insertSensor(currentSensor);
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR, currentSensor.uniqueId);
		}
		
		/**
		 * stops the sensor and updates the database<br>
		 */
		public static function stopSensor():void {
			var currentSensor:Sensor = getActiveSensor();
			if (currentSensor != null) {
				currentSensor._stoppedAt = (new Date()).valueOf();
				currentSensor.resetLastModifiedTimeStamp();
				Database.updateSensor(currentSensor);
			}
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR, "0");
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LIBRE_SENSOR_14DAYS_WARNING_GIVEN, "false");
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_TIME_STAMP_LAST_SENSOR_AGE_CHECK_IN_MS, "0");
		}
		
		public function print(indentation:String):String {
			var r:String = "sensor = ";
			r += "\n" + indentation + "uniqueid = " + uniqueId;
			r += "\n" + indentation + "startedAt = " + (new Date(startedAt)).toLocaleString();
			r += "\n" + indentation + "stoppedAt = " + (new Date(stoppedAt)).toLocaleString();
			r += "\n" + indentation + "latestBatteryLevel = " + latestBatteryLevel;
			return r;
		}
	}
}