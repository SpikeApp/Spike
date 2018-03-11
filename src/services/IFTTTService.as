package services
{
	import flash.events.Event;
	import flash.net.URLRequestMethod;
	
	import database.BgReading;
	import database.BlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.LocalSettings;
	
	import events.AlarmServiceEvent;
	import events.SettingsServiceEvent;
	import events.TransmitterServiceEvent;
	
	import model.ModelLocator;
	
	import network.NetworkConnector;
	
	import utils.BgGraphBuilder;
	import utils.MathHelper;
	import utils.TimeSpan;
	
	[ResourceBundle("alarmservice")]

	public class IFTTTService
	{
		/* Constants */
		private static const IFTTT_URL:String = "https://maker.ifttt.com/trigger/{trigger}/with/key/{key}";
		private static const TIME_5_MINUTES:int = 5 * 60 * 1000;
		
		/* Internal Variables */
		private static var isIFTTTEnabled:Boolean;
		private static var isIFTTTUrgentHighTriggeredEnabled:Boolean;
		private static var isIFTTTHighTriggeredEnabled:Boolean;
		private static var isIFTTTLowTriggeredEnabled:Boolean;
		private static var isIFTTTUrgentLowTriggeredEnabled:Boolean;
		private static var isIFTTTCalibrationTriggeredEnabled:Boolean;
		private static var isIFTTTMissedReadingsTriggeredEnabled:Boolean;
		private static var isIFTTTPhoneMutedTriggeredEnabled:Boolean;
		private static var isIFTTTTransmitterLowBatteryTriggeredEnabled:Boolean;
		private static var isIFTTTGlucoseReadingsEnabled:Boolean;
		private static var isIFTTTUrgentHighSnoozedEnabled:Boolean;
		private static var isIFTTTHighSnoozedEnabled:Boolean;
		private static var isIFTTTLowSnoozedEnabled:Boolean;
		private static var isIFTTTUrgentLowSnoozedEnabled:Boolean;
		private static var isIFTTTCalibrationSnoozedEnabled:Boolean;
		private static var isIFTTTMissedReadingsSnoozedEnabled:Boolean;
		private static var isIFTTTPhoneMutedSnoozedEnabled:Boolean;
		private static var isIFTTTTransmitterLowBatterySnoozedEnabled:Boolean;
		private static var makerKeyList:Array;
		
		public function IFTTTService()
		{
			throw new Error("IFTTTService is not meant to be instantiated!");
		}
		
		public static function init():void
		{
			getInitialProperties();
			
			if (isIFTTTEnabled)
				configureService();
			
			LocalSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
		}
		
		private static function onSettingsChanged(e:SettingsServiceEvent):void
		{
			if (e.data == LocalSettings.LOCAL_SETTING_IFTTT_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_CALIBRATION_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_CALIBRATION_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_HIGH_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_HIGH_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_LOW_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_LOW_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_MISSED_READINGS_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_MISSED_READINGS_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_PHONE_MUTED_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_PHONE_MUTED_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_URGENT_LOW_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_URGENT_LOW_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_MAKER_KEY
			)
			{
				getInitialProperties();
				configureService();
			}
		}
		
		private static function getInitialProperties():void
		{
			isIFTTTEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_ON) == "true";
			isIFTTTUrgentHighTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_TRIGGERED_ON) == "true";
			isIFTTTHighTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HIGH_TRIGGERED_ON) == "true";
			isIFTTTLowTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_LOW_TRIGGERED_ON) == "true";
			isIFTTTUrgentLowTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_LOW_TRIGGERED_ON) == "true";
			isIFTTTCalibrationTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CALIBRATION_TRIGGERED_ON) == "true";
			isIFTTTMissedReadingsTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MISSED_READINGS_TRIGGERED_ON) == "true";
			isIFTTTPhoneMutedTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_PHONE_MUTED_TRIGGERED_ON) == "true";
			isIFTTTTransmitterLowBatteryTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_TRIGGERED_ON) == "true";
			isIFTTTUrgentHighSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_SNOOZED_ON) == "true";
			isIFTTTHighSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HIGH_SNOOZED_ON) == "true";
			isIFTTTLowSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_LOW_SNOOZED_ON) == "true";
			isIFTTTUrgentLowSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_LOW_SNOOZED_ON) == "true";
			isIFTTTCalibrationSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CALIBRATION_SNOOZED_ON) == "true";
			isIFTTTMissedReadingsSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MISSED_READINGS_SNOOZED_ON) == "true";
			isIFTTTPhoneMutedSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_PHONE_MUTED_SNOOZED_ON) == "true";
			isIFTTTTransmitterLowBatterySnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_SNOOZED_ON) == "true";
			isIFTTTGlucoseReadingsEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_READING_ON) == "true";
			makerKeyList = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MAKER_KEY).split(",");
		}
		
		private static function configureService():void
		{
			if (isIFTTTUrgentHighTriggeredEnabled && isIFTTTEnabled)
				AlarmService.instance.addEventListener(AlarmServiceEvent.URGENT_HIGH_GLUCOSE_TRIGGERED, onUrgentHighGlucoseTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.URGENT_HIGH_GLUCOSE_TRIGGERED, onUrgentHighGlucoseTriggered);
			
			if (isIFTTTUrgentHighSnoozedEnabled && isIFTTTEnabled)
				AlarmService.instance.addEventListener(AlarmServiceEvent.URGENT_HIGH_GLUCOSE_SNOOZED, onUrgentHighGlucoseSnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.URGENT_HIGH_GLUCOSE_SNOOZED, onUrgentHighGlucoseSnoozed);
				
			if (isIFTTTHighTriggeredEnabled && isIFTTTEnabled)
				AlarmService.instance.addEventListener(AlarmServiceEvent.HIGH_GLUCOSE_TRIGGERED, onHighGlucoseTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.HIGH_GLUCOSE_TRIGGERED, onHighGlucoseTriggered);
			
			if (isIFTTTHighSnoozedEnabled && isIFTTTEnabled)
				AlarmService.instance.addEventListener(AlarmServiceEvent.HIGH_GLUCOSE_SNOOZED, onHighGlucoseSnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.HIGH_GLUCOSE_SNOOZED, onHighGlucoseSnoozed);
				
			if (isIFTTTLowTriggeredEnabled && isIFTTTEnabled)
				AlarmService.instance.addEventListener(AlarmServiceEvent.LOW_GLUCOSE_TRIGGERED, onLowGlucoseTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.HIGH_GLUCOSE_TRIGGERED, onLowGlucoseTriggered);
			
			if (isIFTTTLowSnoozedEnabled && isIFTTTEnabled)
				AlarmService.instance.addEventListener(AlarmServiceEvent.LOW_GLUCOSE_SNOOZED, onLowGlucoseSnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.LOW_GLUCOSE_SNOOZED, onLowGlucoseSnoozed);
				
			if (isIFTTTUrgentLowTriggeredEnabled && isIFTTTEnabled)
				AlarmService.instance.addEventListener(AlarmServiceEvent.URGENT_LOW_GLUCOSE_TRIGGERED, onUrgentLowGlucoseTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.HIGH_GLUCOSE_TRIGGERED, onUrgentLowGlucoseTriggered);
			
			if (isIFTTTUrgentLowSnoozedEnabled && isIFTTTEnabled)
				AlarmService.instance.addEventListener(AlarmServiceEvent.URGENT_LOW_GLUCOSE_SNOOZED, onUrgentLowGlucoseSnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.URGENT_LOW_GLUCOSE_SNOOZED, onUrgentLowGlucoseSnoozed);
				
			if (isIFTTTCalibrationTriggeredEnabled && isIFTTTEnabled)
				AlarmService.instance.addEventListener(AlarmServiceEvent.CALIBRATION_TRIGGERED, onCalibrationTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.CALIBRATION_TRIGGERED, onCalibrationTriggered);
			
			if (isIFTTTCalibrationSnoozedEnabled && isIFTTTEnabled)
				AlarmService.instance.addEventListener(AlarmServiceEvent.CALIBRATION_SNOOZED, onCalibrationSnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.CALIBRATION_SNOOZED, onCalibrationSnoozed);
				
			if (isIFTTTMissedReadingsTriggeredEnabled && isIFTTTEnabled)
				AlarmService.instance.addEventListener(AlarmServiceEvent.MISSED_READINGS_TRIGGERED, onMissedReadingsTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.MISSED_READINGS_TRIGGERED, onMissedReadingsTriggered);
			
			if (isIFTTTMissedReadingsSnoozedEnabled && isIFTTTEnabled)
				AlarmService.instance.addEventListener(AlarmServiceEvent.MISSED_READINGS_SNOOZED, onMissedReadingsSnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.MISSED_READINGS_SNOOZED, onMissedReadingsSnoozed);
				
			if (isIFTTTPhoneMutedTriggeredEnabled && isIFTTTEnabled)
				AlarmService.instance.addEventListener(AlarmServiceEvent.PHONE_MUTED_TRIGGERED, onPhoneMutedTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.PHONE_MUTED_TRIGGERED, onPhoneMutedTriggered);
			
			if (isIFTTTPhoneMutedSnoozedEnabled && isIFTTTEnabled)
				AlarmService.instance.addEventListener(AlarmServiceEvent.PHONE_MUTED_SNOOZED, onPhoneMutedSnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.PHONE_MUTED_SNOOZED, onPhoneMutedSnoozed);
				
			if (isIFTTTTransmitterLowBatteryTriggeredEnabled && isIFTTTEnabled)
				AlarmService.instance.addEventListener(AlarmServiceEvent.TRANSMITTER_LOW_BATTERY_TRIGGERED, onTransmitterLowBatteryTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.TRANSMITTER_LOW_BATTERY_TRIGGERED, onTransmitterLowBatteryTriggered);
			
			if (isIFTTTTransmitterLowBatterySnoozedEnabled && isIFTTTEnabled)
				AlarmService.instance.addEventListener(AlarmServiceEvent.TRANSMITTER_LOW_BATTERY_SNOOZED, onTransmitterLowBatterySnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.TRANSMITTER_LOW_BATTERY_SNOOZED, onTransmitterLowBatterySnoozed);
			
			if (isIFTTTGlucoseReadingsEnabled && isIFTTTEnabled)
				TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBgReading);
			else
				TransmitterService.instance.removeEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBgReading);
		}
		
		private static function onBgReading(e:Event):void
		{
			if (Calibration.allForSensor().length >= 2 || BlueToothDevice.isFollower()) 
			{
				var lastReading:BgReading;
				if (!BlueToothDevice.isFollower()) lastReading = BgReading.lastNoSensor();
				else lastReading = BgReading.lastWithCalculatedValue();
				
				if (lastReading != null && lastReading.calculatedValue != 0 && (new Date()).valueOf() - lastReading.timestamp < 4.5 * 60 * 1000 && lastReading.calculatedValue != 0 && (new Date().getTime()) - (60000 * 11) - lastReading.timestamp <= 0) 
				{
					var info:Object = {};
					info.value1 = BgGraphBuilder.unitizedString(lastReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
					info.value2 = !lastReading.hideSlope ? lastReading.slopeArrow() : "";
					info.value3 = BgGraphBuilder.unitizedDeltaString(true, true);
						
					for (var i:int = 0; i < makerKeyList.length; i++) 
					{
						var key:String = makerKeyList[i] as String;
						NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-bgreading").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
					}	
				}
			}
		}
		
		private static function onUrgentHighGlucoseTriggered(e:AlarmServiceEvent):void
		{
			var lastReading:BgReading;
			if (!BlueToothDevice.isFollower()) lastReading = BgReading.lastNoSensor();
			else lastReading = BgReading.lastWithCalculatedValue();
			
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","veryhigh_alert_notification_alert_text");
			info.value2 = BgGraphBuilder.unitizedString(lastReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
			info.value3 = (!lastReading.hideSlope ? lastReading.slopeArrow() + " " : "\u21C4 ") + BgGraphBuilder.unitizedDeltaString(true, true);
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-urgent-high-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onUrgentHighGlucoseSnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-urgent-high-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onHighGlucoseTriggered(e:AlarmServiceEvent):void
		{
			var lastReading:BgReading;
			if (!BlueToothDevice.isFollower()) lastReading = BgReading.lastNoSensor();
			else lastReading = BgReading.lastWithCalculatedValue();
			
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","high_alert_notification_alert_text");
			info.value2 = BgGraphBuilder.unitizedString(lastReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
			info.value3 = (!lastReading.hideSlope ? lastReading.slopeArrow() + " " : "\u21C4 ") + BgGraphBuilder.unitizedDeltaString(true, true);
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-high-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onHighGlucoseSnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-high-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onLowGlucoseTriggered(e:AlarmServiceEvent):void
		{
			var lastReading:BgReading;
			if (!BlueToothDevice.isFollower()) lastReading = BgReading.lastNoSensor();
			else lastReading = BgReading.lastWithCalculatedValue();
			
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","low_alert_notification_alert_text");
			info.value2 = BgGraphBuilder.unitizedString(lastReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
			info.value3 = (!lastReading.hideSlope ? lastReading.slopeArrow() + " " : "\u21C4 ") + BgGraphBuilder.unitizedDeltaString(true, true);
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-low-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onLowGlucoseSnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-low-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onUrgentLowGlucoseTriggered(e:AlarmServiceEvent):void
		{
			var lastReading:BgReading;
			if (!BlueToothDevice.isFollower()) lastReading = BgReading.lastNoSensor();
			else lastReading = BgReading.lastWithCalculatedValue();
			
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","verylow_alert_notification_alert_text");
			info.value2 = BgGraphBuilder.unitizedString(lastReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
			info.value3 = (!lastReading.hideSlope ? lastReading.slopeArrow() + " " : "\u21C4 ") + BgGraphBuilder.unitizedDeltaString(true, true);
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-urgent-low-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onUrgentLowGlucoseSnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-urgent-low-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onCalibrationTriggered(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","calibration_request_alert_notification_alert_title");
			info.value2 = "";
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-calibration-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onCalibrationSnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-calibration-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onMissedReadingsTriggered(e:AlarmServiceEvent):void
		{
			var lastReading:BgReading;
			if (!BlueToothDevice.isFollower()) lastReading = BgReading.lastNoSensor();
			else lastReading = BgReading.lastWithCalculatedValue();
			
			var timeSpan:TimeSpan;
			if (lastReading != null)
				timeSpan = TimeSpan.fromMilliseconds(new Date().valueOf() - lastReading.timestamp);
			
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","missed_reading_alert_notification_alert");
			info.value2 = lastReading != null ? String(Math.round(timeSpan.minutes / TIME_5_MINUTES)) : ""; //Number of missed readings
			info.value3 = lastReading != null ? String((timeSpan.hours > 0 ? MathHelper.formatNumberToString(timeSpan.hours) + "h" : "") + (timeSpan.hours > 0  ? MathHelper.formatNumberToString(timeSpan.minutes) + "m" : timeSpan.minutes + "m")) : ""; //Time since last reading
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-missed-readings-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onMissedReadingsSnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-missed-readings-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onPhoneMutedTriggered(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","phonemuted_alert_notification_alert_text");
			info.value2 = "";
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-phone-muted-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onPhoneMutedSnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-phone-muted-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onTransmitterLowBatteryTriggered(e:Event):void
		{
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","batteryLevel_alert_notification_alert_text");
			info.value2 = "";
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-transmitter-low-battery-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onTransmitterLowBatterySnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-transmitter-low-battery-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
	}
}