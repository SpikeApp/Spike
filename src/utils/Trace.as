package utils
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.filesystem.File;
	import flash.system.Capabilities;
	
	import spark.formatters.DateTimeFormatter;
	
	import databaseclasses.BlueToothDevice;
	import databaseclasses.Calibration;
	import databaseclasses.CommonSettings;
	import databaseclasses.LocalSettings;
	import databaseclasses.Sensor;
	
	import events.SettingsServiceEvent;
	
	
	public class Trace
	{
		private static var dateFormatter:DateTimeFormatter;
		//private static var writeFileStream:FileStream;
		private static const debugMode:Boolean = true;
		private static var initialStart:Boolean = true;
		private static var filePath:String = "";
		
		public function Trace()
		{
		}
		
		public static function init():void {
			if (initialStart) {
				initialStart = false;
				LocalSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, localSettingChanged);
				filePath = "";
			}
		}
		
		private static function localSettingChanged(event:SettingsServiceEvent):void {
			if (event.data == LocalSettings.LOCAL_SETTING_DETAILED_TRACING_ENABLED) {
				if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_DETAILED_TRACING_ENABLED) == "true") {
					getSaveStream(); 
				}
			}
		}
		
		/**
		 * tag usually the name of the class that generates the log<br>
		 * log is the actually log<br>
		 * <br>
		 * dontWriteToFile : if true, then even if  LOCAL_SETTING_DETAILED_TRACING_ENABLED = true, the log will not be written to file<br>
		 * Useful for instance to avoid that personal data is written to the file (and afterwards send via e-mail).
		 * It will however still be logged with NSLog, which means to view such logs, the only way is with phone connected to Mac and cfgutil
		 */
		public static function myTrace(tag:String, log:String, dontWriteToFile:Boolean = false):void {
			if (dateFormatter == null) {
				dateFormatter = new DateTimeFormatter();
				dateFormatter.dateTimePattern = "dd-MM-yyyy HH:mm:ss";
				dateFormatter.useUTC = false;
				dateFormatter.setStyle("locale",Capabilities.language.substr(0,2));
			}
			var nowMilliSecondsAsString:String = (new Date()).milliseconds.toString();
			while (nowMilliSecondsAsString.length < 3)
				nowMilliSecondsAsString = "0" + nowMilliSecondsAsString
			var traceText:String = dateFormatter.format(new Date()) + "." + nowMilliSecondsAsString + " spikereadertrace " + tag + " : " + log;
			if (debugMode)
				trace(traceText);
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_NSLOG) == "true") {
				BackgroundFetch.traceNSLog(traceText);
			}
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_DETAILED_TRACING_ENABLED) == "false" || dontWriteToFile) {
				
			} else {
				if (filePath == "")
					getSaveStream();
				BackgroundFetch.writeStringToFile(filePath, traceText.replace(" spikereadertrace ", " "));			
			}
		}
		
		/**
		 * Get a FileStream for writing the the log. 
		 * @return A FileStream instance we can read or write with. Don't forget to close it!
		 * also stores the new filename in the settings
		 */
		private static function getSaveStream():void 
		{
			var fileName:String = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_TRACE_FILE_NAME);
			if (fileName == "") {
				var dateFormatter:DateTimeFormatter = new DateTimeFormatter();
				dateFormatter.dateTimePattern = "yyyy-MM-dd-HH-mm-ss";
				dateFormatter.useUTC = false;
				dateFormatter.setStyle("locale",Capabilities.language.substr(0,2));
				fileName = "spike-" + dateFormatter.format(new Date()) + ".log";
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_TRACE_FILE_NAME, fileName);
				filePath = File.applicationStorageDirectory.resolvePath(fileName).nativePath;
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_TRACE_FILE_PATH_NAME, filePath);
				BackgroundFetch.writeStringToFile(filePath, "New file created with name " + fileName);
				BackgroundFetch.writeStringToFile(filePath, "Application version = " + LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APPLICATION_VERSION));
				BackgroundFetch.writeStringToFile(filePath, "Device Info = " + Capabilities.os);
				BackgroundFetch.writeStringToFile(filePath, "BackgroundFetch ANE version = " + BackgroundFetch.getANEVersion());
				var additionalInfoToWrite:String = "";
				additionalInfoToWrite += "Device type = " + BlueToothDevice.deviceType() + ".\n";
				additionalInfoToWrite += "Sensor " + (Sensor.getActiveSensor() == null ? "not":"") + " started ";
				additionalInfoToWrite += (Sensor.getActiveSensor() == null ? ".\n": dateFormatter.format(new Date(Sensor.getActiveSensor().startedAt)) + ".\n" + "\n");
				if (Sensor.getActiveSensor() != null) {
					additionalInfoToWrite += "Numer of calibrations for this sensor = " + Calibration.allForSensor().length + ".\n";
					if (Calibration.allForSensor().length > 0) {
						additionalInfoToWrite += "Last calibration = " + dateFormatter.format(new Date(Calibration.last().timestamp))  + ".\n";
					}
				}
				additionalInfoToWrite += "Battery alert = " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BATTERY_ALERT) + "\n";
				additionalInfoToWrite += "Low alert = " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_ALERT) + "\n";
				additionalInfoToWrite += "Very Low alert = " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_VERY_LOW_ALERT) + "\n";
				additionalInfoToWrite += "High alert = " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_ALERT) + "\n";
				additionalInfoToWrite += "Very High alert = " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_VERY_HIGH_ALERT) + "\n";
				additionalInfoToWrite += "Phone Muted alert = " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT) + "\n";
				additionalInfoToWrite += "Missed Reading alert = " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_MISSED_READING_ALERT) + "\n";
				additionalInfoToWrite += "Calibration Request alert = " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CALIBRATION_REQUEST_ALERT) + "\n";
				
				BackgroundFetch.writeStringToFile(filePath, additionalInfoToWrite);
			} else {
				filePath = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_TRACE_FILE_PATH_NAME);
			}
		}
	}
}