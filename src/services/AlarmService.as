package services
{
	import com.distriqt.extension.notifications.Notifications;
	import com.distriqt.extension.notifications.builders.NotificationBuilder;
	import com.distriqt.extension.notifications.events.NotificationEvent;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	import com.spikeapp.spike.airlibrary.SpikeANEEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.utils.StringUtil;
	
	import database.AlertType;
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.Database;
	import database.LocalSettings;
	import database.Sensor;
	
	import events.AlarmServiceEvent;
	import events.FollowerEvent;
	import events.NotificationServiceEvent;
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	
	import model.ModelLocator;
	
	import services.bluetooth.CGMBluetoothService;
	
	import starling.events.Event;
	import starling.utils.SystemUtil;
	
	import ui.popups.AlarmSnoozer;
	import ui.screens.display.settings.alarms.AlertCustomizerList;
	
	import utils.BadgeBuilder;
	import utils.BgGraphBuilder;
	import utils.DateTimeUtilities;
	import utils.FromtimeAndValueArrayCollection;
	import utils.GlucoseHelper;
	import utils.TimeSpan;
	import utils.Trace;
	
	public class AlarmService extends EventDispatcher
	{
		[ResourceBundle("alarmservice")]
		
		private static var initialStart:Boolean = true;
		private static var _instance:AlarmService = new AlarmService(); 
		
		//low alert
		/**
		 * 0 is not snoozed, if > 0 this is snooze value chosen by user
		 */
		private static var _lowAlertSnoozePeriodInMinutes:int = 0;
		/**
		 * timestamp when alert was snoozed, ms 
		 */
		private static var _lowAlertLatestSnoozeTimeInMs:Number = Number.NaN;
		/**
		 * true means snooze is set by user
		 */
		private static var _lowAlertPreSnoozed:Boolean = false;
		
		//verylow alert
		/**
		 * 0 is not snoozed, if > 0 this is snooze value chosen by user
		 */
		private static var _veryLowAlertSnoozePeriodInMinutes:int = 0;
		/**
		 * timestamp when alert was snoozed, ms 
		 */
		private static var _veryLowAlertLatestSnoozeTimeInMs:Number = Number.NaN;
		/**
		 * true means snooze is set by user
		 */
		private static var _veryLowAlertPreSnoozed:Boolean = false;
		
		//high alert
		/**
		 * 0 is not snoozed, if > 0 this is snooze value chosen by user
		 */
		private static var _highAlertSnoozePeriodInMinutes:int = 0;
		/**
		 * timestamp when alert was snoozed, ms 
		 */
		private static var _highAlertLatestSnoozeTimeInMs:Number = Number.NaN;
		/**
		 * true means snooze is set by user
		 */
		private static var _highAlertPreSnoozed:Boolean = false;
		
		//very high alert
		/**
		 * 0 is not snoozed, if > 0 this is snooze value chosen by user
		 */
		private static var _veryHighAlertSnoozePeriodInMinutes:int = 0;
		/**
		 * timestamp when alert was snoozed, ms 
		 */
		private static var _veryHighAlertLatestSnoozeTimeInMs:Number = Number.NaN;
		/**
		 * true means snooze is set by user
		 */
		private static var _veryHighAlertPreSnoozed:Boolean = false;
		
		//fast rise alert
		/**
		 * 0 is not snoozed, if > 0 this is snooze value chosen by user
		 */
		private static var _fastRiseAlertSnoozePeriodInMinutes:int = 0;
		/**
		 * timestamp when alert was snoozed, ms 
		 */
		private static var _fastRiseAlertLatestSnoozeTimeInMs:Number = Number.NaN;
		/**
		 * true means snooze is set by user
		 */
		private static var _fastRiseAlertPreSnoozed:Boolean = false;
		
		//fast drop alert
		/**
		 * 0 is not snoozed, if > 0 this is snooze value chosen by user
		 */
		private static var _fastDropAlertSnoozePeriodInMinutes:int = 0;
		/**
		 * timestamp when alert was snoozed, ms 
		 */
		private static var _fastDropAlertLatestSnoozeTimeInMs:Number = Number.NaN;
		/**
		 * true means snooze is set by user
		 */
		private static var _fastDropAlertPreSnoozed:Boolean = false;
		
		/**
		 * if lastbgreading is older than MAX_AGE_OF_READING_IN_MINUTES minutes, then no low or high alert will be generated  
		 */
		public static const MAX_AGE_OF_READING_IN_MINUTES:int = 4;
		
		private static const MAX_REPEATS_FOR_ALERTS:int = 9;//repeating alerts are repeated every minute, means maximum 10 minutes of repeat
		
		//batteryLevel alert
		/**
		 * 0 is not snoozed, if > 0 this is snooze value chosen by user
		 */
		private static var _batteryLevelAlertSnoozePeriodInMinutes:int = 0;
		/**
		 * timestamp when alert was snoozed, ms 
		 */
		private static var _batteryLevelAlertLatestSnoozeTimeInMs:Number = Number.NaN;
		
		//missed reading
		/**
		 * 0 is not snoozed, if > 0 this is snooze value chosen by user
		 */
		private static var _missedReadingAlertSnoozePeriodInMinutes:int = 0;
		/**
		 * timestamp when alert was snoozed, ms 
		 */
		private static var _missedReadingAlertLatestSnoozeTimeInMs:Number = Number.NaN;
		/**
		 * true means snooze is set by user
		 */
		private static var _missedReadingAlertPreSnoozed:Boolean = false;
		
		//phone muted
		/**
		 * 0 is not snoozed, if > 0 this is snooze value chosen by user
		 */
		private static var _phoneMutedAlertSnoozePeriodInMinutes:int = 0;
		/**
		 * timestamp when alert was snoozed, ms 
		 */
		private static var _phoneMutedAlertLatestSnoozeTimeInMs:Number = Number.NaN;
		/**
		 * true means snooze is set by user
		 */
		private static var _phoneMutedAlertPreSnoozed:Boolean = false;
		
		//calibration request
		/**
		 * 0 is not snoozed, if > 0 this is snooze value chosen by user
		 */
		private static var _calibrationRequestSnoozePeriodInMinutes:int = 0;
		/**
		 * timestamp when alert was snoozed, ms 
		 */
		private static var _calibrationRequestLatestSnoozeTimeInMs:Number = Number.NaN;
		
		public static var snoozeValueMinutes:Array = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 75, 90, 105, 120, 150, 180, 240, 300, 360, 420, 480, 540, 600, 660, 720, 1440, 10080];
		public static var snoozeValueStrings:Array = ["5 minutes", "10 minutes", "15 minutes", "20 minutes", "25 minutes", "30 minutes", "35 minutes",
			"40 minutes", "45 minutes", "50 minutes", "55 minutes", "1 hour", "1 hour, 15 minutes", "1 hour, 30 minutes", "1 hour, 45 minutes", "2 hours", "2 hours, 30 minutes", "3 hours", "4 hours",
			"5 hours", "6 hours", "7 hours", "8 hours", "9 hours", "10 hours", "11 hours", "12 hours", "1 day", "1 week"];
		
		private static var lastAlarmCheckTimeStamp:Number;
		private static var lastCheckMuteTimeStamp:Number;
		private static var lastPhoneMutedAlertCheckTimeStamp:Number;
		private static var latestAlertTypeUsedInMissedReadingNotification:AlertType;
		private static var lastMissedReadingAlertCheckTimeStamp:Number;
		private static var lastApplicationStoppedAlertCheckTimeStamp:Number;
		
		//for repeat of alarms every minute, this is only for non-snoozed alerts
		//each element in an array represents certain alarm 
		/**
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted, 8:Fast Rise, 9:Fast Drop<br>
		 * true means alert is active, repeat check is necessary (not necessarily repeat, that depends on the setting in the alert type)<br>
		 * also used to check if an alert is active when the notification is coming from back to foreground<br>
		 */
		private static var activeAlertsArray:Array = [false,false,false,false,false,false,false,false,false,false,false];
		/**
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted, 8:Fast Rise, 9:Fast Drop<br>
		 * last timestamp the alert was fired
		 */
		private static var repeatAlertsLastFireTimeStampArray:Array = [0,0,0,0,0,0,0,0,0,0,0];
		/**
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted, 8:Fast Rise, 9:Fast Drop<br>
		 * the name of the alert type to be used when repeating the alert, and also to check if it needs to be repeated
		 */
		private static var repeatAlertsAlertTypeNameArray:Array = ["","","","","","","","","","",""];
		/**
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted, 8:Fast Rise, 9:Fast Drop<br>
		 * alert texts for the alert
		 */
		private static var repeatAlertsTexts:Array = ["","","","","","","","","","",""];
		/**
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted, 8:Fast Rise, 9:Fast Drop<br>
		 * body texts for the alert
		 */
		private static var repeatAlertsBodies:Array = ["","","","","","","","","","",""];
		/**
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted, 8:Fast Rise, 9:Fast Drop<br>
		 * how many times repeated
		 */
		private static var repeatAlertsRepeatCount:Array = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
		/**
		 * list of notification ids<br>
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted, 8:Fast Rise, 9:Fast Drop<br>
		 */
		private static const repeatAlertsNotificationIds:Array = [
			NotificationService.ID_FOR_CALIBRATION_REQUEST_ALERT,
			NotificationService.ID_FOR_LOW_ALERT,
			NotificationService.ID_FOR_VERY_LOW_ALERT,
			NotificationService.ID_FOR_HIGH_ALERT,
			NotificationService.ID_FOR_VERY_HIGH_ALERT,
			NotificationService.ID_FOR_MISSED_READING_ALERT,
			NotificationService.ID_FOR_BATTERY_ALERT,
			NotificationService.ID_FOR_PHONEMUTED_ALERT,
			NotificationService.ID_FOR_FAST_RISE_ALERT,
			NotificationService.ID_FOR_FAST_DROP_ALERT];
		/**
		 * list of category ids<br>
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted, 8:Fast Rise, 9:Fast Drop<br>
		 */
		private static const repeatAlertsCategoryIds:Array = [
			NotificationService.ID_FOR_ALERT_CALIBRATION_REQUEST_CATEGORY,
			NotificationService.ID_FOR_ALERT_LOW_CATEGORY,
			NotificationService.ID_FOR_ALERT_VERY_LOW_CATEGORY,
			NotificationService.ID_FOR_ALERT_HIGH_CATEGORY,
			NotificationService.ID_FOR_ALERT_VERY_HIGH_CATEGORY,
			NotificationService.ID_FOR_ALERT_MISSED_READING_CATEGORY,
			NotificationService.ID_FOR_ALERT_BATTERY_CATEGORY,
			NotificationService.ID_FOR_PHONE_MUTED_CATEGORY,
			NotificationService.ID_FOR_ALERT_FAST_RISE_CATEGORY,
			NotificationService.ID_FOR_ALERT_FAST_DROP_CATEGORY];
		
		private static var alarmTimer:Timer;
		
		private static var queuedAlertSound:String = "";
		private static var lastQueuedAlertSoundTimeStamp:Number = 0;
		
		/**
		 * Optimal Calibrations
		 */
		public static var userWarnedOfSuboptimalCalibration:Boolean = false;
		public static var userRequestedSuboptimalCalibrationNotification:Boolean = false;
		public static var canUploadCalibrationToNightscout:Boolean = true;
		
		public static function get instance():AlarmService {
			return _instance;
		}
		
		public function AlarmService() {
			if (_instance != null) {
				throw new Error("AlarmService class constructor can not be used");	
			}
		}
		
		public static function init():void {
			if (!initialStart)
				return;
			else
				initialStart = false;
			
			lastCheckMuteTimeStamp = new Number(0);
			lastPhoneMutedAlertCheckTimeStamp = new Number(0);
			
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, checkAlarms);
			NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, checkAlarms);
			DexcomShareService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, checkAlarms);
			
			//Get snooze times from database
			_veryHighAlertSnoozePeriodInMinutes = int(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES));
			_veryHighAlertLatestSnoozeTimeInMs = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS));
			_veryHighAlertPreSnoozed = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_PRESNOOZED) == "true";
			_highAlertSnoozePeriodInMinutes = int(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES));
			_highAlertLatestSnoozeTimeInMs = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS));
			_highAlertPreSnoozed = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_PRESNOOZED) == "true";
			_lowAlertSnoozePeriodInMinutes = int(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES));
			_lowAlertLatestSnoozeTimeInMs = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS));
			_lowAlertPreSnoozed = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_PRESNOOZED) == "true";
			_veryLowAlertSnoozePeriodInMinutes = int(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_VERY_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES));
			_veryLowAlertLatestSnoozeTimeInMs = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_VERY_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS));
			_veryLowAlertPreSnoozed = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_VERY_LOW_ALERT_PRESNOOZED) == "true";
			_missedReadingAlertSnoozePeriodInMinutes = int(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_SNOOZE_PERIOD_IN_MINUTES));
			_missedReadingAlertLatestSnoozeTimeInMs = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_LATEST_SNOOZE_TIME_IN_MS));
			_missedReadingAlertPreSnoozed = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_PRESNOOZED) == "true";
			_phoneMutedAlertSnoozePeriodInMinutes = int(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_SNOOZE_PERIOD_IN_MINUTES));
			_phoneMutedAlertLatestSnoozeTimeInMs = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_LATEST_SNOOZE_TIME_IN_MS));
			_phoneMutedAlertPreSnoozed = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_PRESNOOZED) == "true";
			_fastRiseAlertSnoozePeriodInMinutes = int(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_SNOOZE_PERIOD_IN_MINUTES));
			_fastRiseAlertLatestSnoozeTimeInMs = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_LATEST_SNOOZE_TIME_IN_MS));
			_fastRiseAlertPreSnoozed = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_PRESNOOZED) == "true";
			_fastDropAlertSnoozePeriodInMinutes = int(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_SNOOZE_PERIOD_IN_MINUTES));
			_fastDropAlertLatestSnoozeTimeInMs = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_LATEST_SNOOZE_TIME_IN_MS));
			_fastDropAlertPreSnoozed = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_PRESNOOZED) == "true";
			
			//listen to NOTIFICATION_EVENT. This even is received only if the app is in the foreground. The function notificationReceived will shows the snooze dialog
			NotificationService.instance.addEventListener(NotificationServiceEvent.NOTIFICATION_EVENT, notificationReceived);
			//listen to NOTIFICATION_ACTION_EVENT. This even is received if the user selected an action, ie if an alert was snoozed
			NotificationService.instance.addEventListener(NotificationServiceEvent.NOTIFICATION_ACTION_EVENT, notificationReceived);
			//not interested in NOTIFICATION_SELECTED_EVENT, because NOTIFICATION_SELECTED_EVENT is only received while the app is in the background and being braught to the
			//foreground because the user selects a notification. But in that case, in function appInForeGround, the notificationReceived function will also be called.
			
			SpikeANE.instance.addEventListener(SpikeANEEvent.PHONE_MUTED, phoneMuted);
			SpikeANE.instance.addEventListener(SpikeANEEvent.PHONE_NOT_MUTED, phoneNotMuted);
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, commonSettingChanged);
			LocalSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, localSettingChanged);
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, appInForeGround);
			lastAlarmCheckTimeStamp = 0;
			lastMissedReadingAlertCheckTimeStamp = 0;
			lastApplicationStoppedAlertCheckTimeStamp = 0;
			
			for (var cntr:int = 0;cntr < snoozeValueMinutes.length;cntr++) {
				snoozeValueStrings[cntr] = (snoozeValueStrings[cntr] as String).replace("minutes", ModelLocator.resourceManagerInstance.getString("alarmservice","minutes"));
				snoozeValueStrings[cntr] = (snoozeValueStrings[cntr] as String).replace("hours", ModelLocator.resourceManagerInstance.getString("alarmservice","hours"));
				snoozeValueStrings[cntr] = (snoozeValueStrings[cntr] as String).replace("hour", ModelLocator.resourceManagerInstance.getString("alarmservice","hour"));
				snoozeValueStrings[cntr] = (snoozeValueStrings[cntr] as String).replace("day", ModelLocator.resourceManagerInstance.getString("alarmservice","day"));
				snoozeValueStrings[cntr] = (snoozeValueStrings[cntr] as String).replace("week", ModelLocator.resourceManagerInstance.getString("alarmservice","week"));
			}
			
			//Optimal Calibrations
			userWarnedOfSuboptimalCalibration = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_OPTIMAL_CALIBRATION_BY_ALARM_NOTIFIED_ON) == "true";
			
			setTimer();
			
			checkMuted(null);
			Notifications.service.cancel(NotificationService.ID_FOR_APPLICATION_INACTIVE_ALERT);
		}
		
		private static function setTimer():void
		{
			alarmTimer = new Timer(60000)
			alarmTimer.addEventListener(TimerEvent.TIMER, onAlarmTimer);
			alarmTimer.start();
		}
		
		protected static function onAlarmTimer(event:TimerEvent):void
		{
			myTrace("in onAlarmTimer");
			if ((new Date()).valueOf() - lastMissedReadingAlertCheckTimeStamp > TimeSpan.TIME_5_MINUTES_30_SECONDS) {
				myTrace("in onAlarmTimer, calling checkMissedReadingAlert");
				checkMissedReadingAlert();
			}
			checkMuted(null);
			repeatAlerts();
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_INACTIVE_ALERT) == "true") 
			{
				myTrace("in onAlarmTimer, calling planApplicationStoppedAlert");
				planApplicationStoppedAlert();
				lastApplicationStoppedAlertCheckTimeStamp = (new Date()).valueOf();
			}
		}
		
		private static function checkMuted(event:flash.events.Event):void {
			var nowDate:Date = new Date();
			var nowNumber:Number = nowDate.valueOf();
			if ((nowNumber - _phoneMutedAlertLatestSnoozeTimeInMs) > _phoneMutedAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
				||
				isNaN(_phoneMutedAlertLatestSnoozeTimeInMs)) {
				//alert not snoozed
				if (nowNumber - lastCheckMuteTimeStamp > TimeSpan.TIME_4_MINUTES_45_SECONDS) {
					//more than 4 min 45 seconds ago since last check
					var listOfAlerts:FromtimeAndValueArrayCollection = FromtimeAndValueArrayCollection.createList(
						CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT), false);
					var alertName:String = listOfAlerts.getAlarmName(Number.NaN, "", nowDate);
					var alertType:AlertType = Database.getAlertType(alertName);
					if (alertType != null && (alertType.enabled || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_ON) == "true")) {
						//alert enabled or speak readings is on 
						myTrace("in checkMuted, calling SpikeANE.checkMuted");
						SpikeANE.checkMuted();
					}
					lastCheckMuteTimeStamp = nowNumber;
				}
			}
		}
		
		private static function notificationReceived(event:NotificationServiceEvent):void {
			myTrace("in notificationReceived");
			if (SpikeANE.appIsInBackground()) {
				//app is in background, which means the notification was received because the user clicked the notification action, typically "snooze"
				//  so stop the playing
				SpikeANE.stopPlayingSound();
			} else {
				//notificationReceived was called by appInForeGround(), ie the user brings the app in the foreground and an alert is active
				//or the app was already in the foreground and an notification was fired (ie firealert was called)
			}
			if (event != null) {
				var listOfAlerts:FromtimeAndValueArrayCollection;
				var alertName:String ;
				var alertType:AlertType;
				var index:int;
				var now:Date = new Date();
				var cntr:int;
				
				var notificationEvent:NotificationEvent = event.data as NotificationEvent;
				myTrace("in notificationReceived, event != null, id = " + NotificationService.notificationIdToText(notificationEvent.id));
				if (notificationEvent.id == NotificationService.ID_FOR_FAST_DROP_ALERT) {
					if (SpikeANE.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(9);
					}
					
					if ((now.valueOf() - _fastDropAlertLatestSnoozeTimeInMs) > _fastDropAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
						||
						isNaN(_fastDropAlertLatestSnoozeTimeInMs)) {
						openSnoozePickerDialog(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_DROP_ALERT),
							NotificationService.ID_FOR_FAST_DROP_ALERT,
							notificationEvent,
							fastDropSnoozePicker_closedHandler,
							"snooze_text_fast_drop_alert",
							NotificationService.ID_FOR_FAST_DROP_ALERT_SNOOZE_IDENTIFIER,
							setFastDropAlertSnooze);
					} else {
						myTrace("in checkAlarms, alarm snoozed, _fastDropAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_fastDropAlertLatestSnoozeTimeInMs)) + ", _fastDropAlertSnoozePeriodInMinutes = " + _fastDropAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				}
				else if (notificationEvent.id == NotificationService.ID_FOR_FAST_RISE_ALERT) {
					if (SpikeANE.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(8);
					}
					
					if ((now.valueOf() - _fastRiseAlertLatestSnoozeTimeInMs) > _fastRiseAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
						||
						isNaN(_fastRiseAlertLatestSnoozeTimeInMs)) {
						openSnoozePickerDialog(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_RISE_ALERT),
							NotificationService.ID_FOR_FAST_RISE_ALERT,
							notificationEvent,
							fastRiseSnoozePicker_closedHandler,
							"snooze_text_fast_rise_alert",
							NotificationService.ID_FOR_FAST_RISE_ALERT_SNOOZE_IDENTIFIER,
							setFastRiseAlertSnooze);
					} else {
						myTrace("in checkAlarms, alarm snoozed, _fastRiseAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_fastRiseAlertLatestSnoozeTimeInMs)) + ", _fastRiseAlertSnoozePeriodInMinutes = " + _fastRiseAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				}
				else if (notificationEvent.id == NotificationService.ID_FOR_LOW_ALERT) {
					if (SpikeANE.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(1);
					}
					
					if ((now.valueOf() - _lowAlertLatestSnoozeTimeInMs) > _lowAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
						||
						isNaN(_lowAlertLatestSnoozeTimeInMs)) {
						openSnoozePickerDialog(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_ALERT),
							NotificationService.ID_FOR_LOW_ALERT,
							notificationEvent,
							lowSnoozePicker_closedHandler,
							"snooze_text_low_alert",
							NotificationService.ID_FOR_LOW_ALERT_SNOOZE_IDENTIFIER,
							setLowAlertSnooze);
					} else {
						myTrace("in checkAlarms, alarm snoozed, _lowAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_lowAlertLatestSnoozeTimeInMs)) + ", _lowAlertSnoozePeriodInMinutes = " + _lowAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				} else if (notificationEvent.id == NotificationService.ID_FOR_HIGH_ALERT) {
					if (SpikeANE.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(3);
					}
					
					if ((now.valueOf() - _highAlertLatestSnoozeTimeInMs) > _highAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
						||
						isNaN(_highAlertLatestSnoozeTimeInMs)) {
						openSnoozePickerDialog(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_ALERT),
							NotificationService.ID_FOR_HIGH_ALERT,
							notificationEvent,
							highSnoozePicker_closedHandler,
							"snooze_text_high_alert",
							NotificationService.ID_FOR_HIGH_ALERT_SNOOZE_IDENTIFIER,
							setHighAlertSnooze);
					} else {
						myTrace("in checkAlarms, alarm snoozed, _highAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_highAlertLatestSnoozeTimeInMs)) + ", _highAlertSnoozePeriodInMinutes = " + _highAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				} else if (notificationEvent.id == NotificationService.ID_FOR_VERY_LOW_ALERT) {
					if (SpikeANE.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(2);
					}
					
					if ((now.valueOf() - _veryLowAlertLatestSnoozeTimeInMs) > _veryLowAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
						||
						isNaN(_veryLowAlertLatestSnoozeTimeInMs)) {
						openSnoozePickerDialog(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_VERY_LOW_ALERT),
							NotificationService.ID_FOR_VERY_LOW_ALERT,
							notificationEvent,
							veryLowSnoozePicker_closedHandler,
							"snooze_text_very_low_alert",
							NotificationService.ID_FOR_VERY_LOW_ALERT_SNOOZE_IDENTIFIER,
							setVeryLowAlertSnooze);
					} else {
						myTrace("in checkAlarms, alarm snoozed, _veryLowAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_veryLowAlertLatestSnoozeTimeInMs)) + ", _veryLowAlertSnoozePeriodInMinutes = " + _veryLowAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				} else if (notificationEvent.id == NotificationService.ID_FOR_VERY_HIGH_ALERT) {
					if (SpikeANE.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(4);
					}
					
					if ((now.valueOf() - _veryHighAlertLatestSnoozeTimeInMs) > _veryHighAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
						||
						isNaN(_veryHighAlertLatestSnoozeTimeInMs)) {
						openSnoozePickerDialog(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_VERY_HIGH_ALERT),
							NotificationService.ID_FOR_VERY_HIGH_ALERT,
							notificationEvent,
							veryHighSnoozePicker_closedHandler,
							"snooze_text_very_high_alert",
							NotificationService.ID_FOR_VERY_HIGH_ALERT_SNOOZE_IDENTIFIER,
							setVeryHighAlertSnooze);
					} else {
						myTrace("in checkAlarms, alarm snoozed, _veryHighAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_veryHighAlertLatestSnoozeTimeInMs)) + ", _veryHighAlertSnoozePeriodInMinutes = " + _veryHighAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				} else if (notificationEvent.id == NotificationService.ID_FOR_MISSED_READING_ALERT) {
					if (SpikeANE.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(5);
					}
					openSnoozePickerDialog(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_MISSED_READING_ALERT),
						NotificationService.ID_FOR_MISSED_READING_ALERT,
						notificationEvent,
						missedReadingSnoozePicker_closedHandler,
						"snooze_text_missed_reading_alert",
						NotificationService.ID_FOR_MISSED_READING_ALERT_SNOOZE_IDENTIFIER,
						setMissedReadingAlertSnooze);
				} else if (notificationEvent.id == NotificationService.ID_FOR_PHONEMUTED_ALERT) {
					if (SpikeANE.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(7);
					}
					
					if ((now.valueOf() - _phoneMutedAlertLatestSnoozeTimeInMs) > _phoneMutedAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
						||
						isNaN(_phoneMutedAlertLatestSnoozeTimeInMs)) {
						openSnoozePickerDialog(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT),
							NotificationService.ID_FOR_PHONEMUTED_ALERT,
							notificationEvent,
							phoneMutedSnoozePicker_closedHandler,
							"snooze_text_phone_muted_alert",
							NotificationService.ID_FOR_PHONE_MUTED_SNOOZE_IDENTIFIER,
							setPhoneMutedAlertSnooze);
					} else {
						myTrace("in checkAlarms, alarm snoozed, _phoneMutedAlertLatestSnoozeTimeInMs = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_phoneMutedAlertLatestSnoozeTimeInMs)) + ", _phoneMutedAlertSnoozePeriodInMinutes = " + _phoneMutedAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				} else if (notificationEvent.id == NotificationService.ID_FOR_BATTERY_ALERT) {
					if (SpikeANE.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(6);
					}
					
					if ((now.valueOf() - _batteryLevelAlertLatestSnoozeTimeInMs) > _batteryLevelAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
						||
						isNaN(_batteryLevelAlertLatestSnoozeTimeInMs)) {
						listOfAlerts = FromtimeAndValueArrayCollection.createList(
							CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BATTERY_ALERT), false);
						alertName = listOfAlerts.getAlarmName(Number.NaN, "", new Date());
						alertType = Database.getAlertType(alertName);
						myTrace("in notificationReceived with id = ID_FOR_BATTERY_ALERT, cancelling notification");
						myTrace("cancel any existing alert for ID_FOR_BATTERY_ALERT");
						Notifications.service.cancel(NotificationService.ID_FOR_BATTERY_ALERT);
						index = 0;
						for (cntr = 0;cntr < snoozeValueMinutes.length;cntr++) {
							if ((snoozeValueMinutes[cntr]) >= alertType.defaultSnoozePeriodInMinutes) {
								index = cntr;
								break;
							}
						}
						if (notificationEvent.identifier == null) 
						{
							AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CLOSED, batteryLevelSnoozePicker_closedHandler);
							AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CANCELLED, snoozePickerChangedOrCanceledHandler);
							SystemUtil.executeWhenApplicationIsActive
							(
								AlarmSnoozer.displaySnoozer,
								ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_battery_alert"),
								snoozeValueStrings,
								index
							);
						} else if (notificationEvent.identifier == NotificationService.ID_FOR_BATTERY_LEVEL_ALERT_SNOOZE_IDENTIFIER) {
							_batteryLevelAlertSnoozePeriodInMinutes = alertType.defaultSnoozePeriodInMinutes;
							myTrace("in notificationReceived with id = ID_FOR_BATTERY_ALERT, snoozing the notification for " + _batteryLevelAlertSnoozePeriodInMinutes + " minutes");
							_batteryLevelAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
							
							//Notify Services (ex: IFTTT)
							_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.TRANSMITTER_LOW_BATTERY_SNOOZED,false,false,{type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_battery_alert"),time: _batteryLevelAlertSnoozePeriodInMinutes}));
						}
					} else {
						myTrace("in checkAlarms, alarm snoozed, _batteryLevelAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_batteryLevelAlertLatestSnoozeTimeInMs)) + ", _batteryLevelAlertSnoozePeriodInMinutes = " + _batteryLevelAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				} else if (notificationEvent.id == NotificationService.ID_FOR_CALIBRATION_REQUEST_ALERT) {
					if (SpikeANE.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(0);
					}
					
					if ((now.valueOf() - _calibrationRequestLatestSnoozeTimeInMs) > _calibrationRequestSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
						||
						isNaN(_calibrationRequestLatestSnoozeTimeInMs)) {
						listOfAlerts = FromtimeAndValueArrayCollection.createList(
							CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CALIBRATION_REQUEST_ALERT), false);
						alertName = listOfAlerts.getAlarmName(Number.NaN, "", new Date());
						alertType = Database.getAlertType(alertName);
						myTrace("in notificationReceived with id = ID_FOR_CALIBRATION_REQUEST_ALERT, cancelling notification");
						myTrace("cancel any existing alert for ID_FOR_CALIBRATION_REQUEST_ALERT");
						Notifications.service.cancel(NotificationService.ID_FOR_CALIBRATION_REQUEST_ALERT);
						index = 0;
						for (cntr = 0;cntr < snoozeValueMinutes.length;cntr++) {
							if ((snoozeValueMinutes[cntr]) >= alertType.defaultSnoozePeriodInMinutes) {
								index = cntr;
								break;
							}
						}
						if (notificationEvent.identifier == null) {
							CalibrationService.calibrationOnRequest(false, true, snoozeCalibrationRequest);
						} else if (notificationEvent.identifier == NotificationService.ID_FOR_CALIBRATION_REQUEST_ALERT_SNOOZE_IDENTIFIER) {
							_calibrationRequestSnoozePeriodInMinutes = alertType.defaultSnoozePeriodInMinutes;
							myTrace("in notificationReceived with id = ID_FOR_CALIBRATION_REQUEST_ALERT, snoozing the notification for " + _calibrationRequestSnoozePeriodInMinutes + " minutes");
							_calibrationRequestLatestSnoozeTimeInMs = (new Date()).valueOf();
							
							//Notify Services (ex: IFTTT)
							_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.CALIBRATION_SNOOZED,false,false,{type: ModelLocator.resourceManagerInstance.getString("alarmservice","calibration_request_alert_notification_alert_title"),time: _calibrationRequestSnoozePeriodInMinutes}));
						}
					} else {
						myTrace("in checkAlarms, alarm snoozed, _calibrationRequestLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_calibrationRequestLatestSnoozeTimeInMs)) + ", _calibrationRequestSnoozePeriodInMinutes = " + _calibrationRequestSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				}
			}
			
			function snoozeCalibrationRequest():void {
				myTrace("in snoozeCalibrationRequest");
				AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CLOSED, calibrationRequestSnoozePicker_closedHandler);
				AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CANCELLED, snoozePickerChangedOrCanceledHandler);
				SystemUtil.executeWhenApplicationIsActive
				(
					AlarmSnoozer.displaySnoozer,
					ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_calibration_alert"),
					snoozeValueStrings,
					index
				);
			}
			
			function calibrationRequestSnoozePicker_closedHandler(event:starling.events.Event): void {
				myTrace("in calibrationRequestSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, calibrationRequestSnoozePicker_closedHandler);
				disableRepeatAlert(0);
				SpikeANE.stopPlayingSound();
				_calibrationRequestSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_calibrationRequestLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
			
			function batteryLevelSnoozePicker_closedHandler(event:starling.events.Event): void {
				myTrace("in batteryLevelSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, batteryLevelSnoozePicker_closedHandler);
				disableRepeatAlert(6);
				SpikeANE.stopPlayingSound();
				_batteryLevelAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_batteryLevelAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
			
			function phoneMutedSnoozePicker_closedHandler(event:starling.events.Event): void {
				myTrace("in phoneMutedSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, phoneMutedSnoozePicker_closedHandler);
				disableRepeatAlert(7);
				SpikeANE.stopPlayingSound();
				_phoneMutedAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_phoneMutedAlertSnoozePeriodInMinutes));
				_phoneMutedAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_phoneMutedAlertLatestSnoozeTimeInMs));
			}
			
			function missedReadingSnoozePicker_closedHandler(event:starling.events.Event): void {
				myTrace("in phoneMutedSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, missedReadingSnoozePicker_closedHandler);
				disableRepeatAlert(5);
				SpikeANE.stopPlayingSound();
				_missedReadingAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_missedReadingAlertSnoozePeriodInMinutes));
				_missedReadingAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_missedReadingAlertLatestSnoozeTimeInMs));
			}
			
			function lowSnoozePicker_closedHandler(event:starling.events.Event): void {
				myTrace("in lowSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, lowSnoozePicker_closedHandler);
				disableRepeatAlert(1);
				SpikeANE.stopPlayingSound();
				_lowAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_lowAlertSnoozePeriodInMinutes));
				_lowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_lowAlertLatestSnoozeTimeInMs));
			}
			
			function highSnoozePicker_closedHandler(event:starling.events.Event): void {
				myTrace("in highSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, highSnoozePicker_closedHandler);
				disableRepeatAlert(3);
				SpikeANE.stopPlayingSound();
				_highAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_highAlertSnoozePeriodInMinutes));
				_highAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_highAlertLatestSnoozeTimeInMs));
			}
			
			function veryHighSnoozePicker_closedHandler(event:starling.events.Event): void {
				myTrace("in veryHighSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, veryHighSnoozePicker_closedHandler);
				disableRepeatAlert(4);
				SpikeANE.stopPlayingSound();
				_veryHighAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_veryHighAlertSnoozePeriodInMinutes));
				_veryHighAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_veryHighAlertLatestSnoozeTimeInMs));
			}
			
			function fastDropSnoozePicker_closedHandler(event:starling.events.Event): void {
				myTrace("in fastDropSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, fastDropSnoozePicker_closedHandler);
				disableRepeatAlert(9);
				SpikeANE.stopPlayingSound();
				_fastDropAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_fastDropAlertSnoozePeriodInMinutes));
				_fastDropAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_fastDropAlertLatestSnoozeTimeInMs));
			}
			
			function fastRiseSnoozePicker_closedHandler(event:starling.events.Event): void {
				myTrace("in fastRiseSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, fastRiseSnoozePicker_closedHandler);
				disableRepeatAlert(8);
				SpikeANE.stopPlayingSound();
				_fastRiseAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_fastRiseAlertSnoozePeriodInMinutes));
				_fastRiseAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_fastRiseAlertLatestSnoozeTimeInMs));
			}
		}
		
		private static function snoozePickerChangedOrCanceledHandler(event:starling.events.Event): void {
			SpikeANE.stopPlayingSound();
		}
		
		public static function snoozeLowAlert(index:int, explicitMinutes:Number = Number.NaN):void {
			if (isNaN(explicitMinutes))
				myTrace("in snoozeLowAlert. Snoozing for " + snoozeValueMinutes[index] + " minutes");
			else
				myTrace("in snoozeLowAlert. Snoozing for " + explicitMinutes + " minutes");
			_lowAlertPreSnoozed = true;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_PRESNOOZED, String(_lowAlertPreSnoozed));
			Notifications.service.cancel(NotificationService.ID_FOR_LOW_ALERT);
			resetLowAlertPreSnooze();
			disableRepeatAlert(1);
			SpikeANE.stopPlayingSound();
			_lowAlertSnoozePeriodInMinutes = isNaN(explicitMinutes) ? snoozeValueMinutes[index] : explicitMinutes;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_lowAlertSnoozePeriodInMinutes));
			_lowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_lowAlertLatestSnoozeTimeInMs));
		}
		
		public static function snoozeVeyLowAlert(index:int, explicitMinutes:Number = Number.NaN):void {
			if (isNaN(explicitMinutes))
				myTrace("in snoozeVeyLowAlert. Snoozing for " + snoozeValueMinutes[index] + " minutes");
			else
				myTrace("in snoozeVeyLowAlert. Snoozing for " + explicitMinutes + " minutes");
			_veryLowAlertPreSnoozed = true;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_LOW_ALERT_PRESNOOZED, String(_veryLowAlertPreSnoozed));
			Notifications.service.cancel(NotificationService.ID_FOR_VERY_LOW_ALERT);
			resetVeryLowAlertPreSnooze();
			disableRepeatAlert(2);
			SpikeANE.stopPlayingSound();
			_veryLowAlertSnoozePeriodInMinutes = isNaN(explicitMinutes) ? snoozeValueMinutes[index] : explicitMinutes;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_veryLowAlertSnoozePeriodInMinutes));
			_veryLowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_veryLowAlertLatestSnoozeTimeInMs));
		}
		
		public static function snoozeHighAlert(index:int, explicitMinutes:Number = Number.NaN):void {
			if (isNaN(explicitMinutes))
				myTrace("in snoozeHighAlert. Snoozing for " + snoozeValueMinutes[index] + " minutes");
			else
				myTrace("in snoozeHighAlert. Snoozing for " + explicitMinutes + " minutes");
			_highAlertPreSnoozed = true;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_PRESNOOZED, String(_highAlertPreSnoozed));
			Notifications.service.cancel(NotificationService.ID_FOR_HIGH_ALERT);
			resetHighAlertPreSnooze();
			disableRepeatAlert(3);
			SpikeANE.stopPlayingSound();
			_highAlertSnoozePeriodInMinutes = isNaN(explicitMinutes) ? snoozeValueMinutes[index] : explicitMinutes;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_highAlertSnoozePeriodInMinutes));
			_highAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_highAlertLatestSnoozeTimeInMs));
		}
		
		public static function snoozeVeryHighAlert(index:int, explicitMinutes:Number = Number.NaN):void {
			if (isNaN(explicitMinutes))
				myTrace("in snoozeVeryHighAlert. Snoozing for " + snoozeValueMinutes[index] + " minutes");
			else
				myTrace("in snoozeVeryHighAlert. Snoozing for " + explicitMinutes + " minutes");
			_veryHighAlertPreSnoozed = true;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_PRESNOOZED, String(_veryHighAlertPreSnoozed));
			Notifications.service.cancel(NotificationService.ID_FOR_VERY_HIGH_ALERT);
			resetVeryHighAlertPreSnooze();
			disableRepeatAlert(4);
			SpikeANE.stopPlayingSound();
			_veryHighAlertSnoozePeriodInMinutes = isNaN(explicitMinutes) ? snoozeValueMinutes[index] : explicitMinutes;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_veryHighAlertSnoozePeriodInMinutes));
			_veryHighAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_veryHighAlertLatestSnoozeTimeInMs));
		}
		
		public static function snoozeMissedReadingAlert(index:int, explicitMinutes:Number = Number.NaN):void {
			if (isNaN(explicitMinutes))
				myTrace("in snoozeMissedReadingAlert. Snoozing for " + snoozeValueMinutes[index] + " minutes");
			else
				myTrace("in snoozeMissedReadingAlert. Snoozing for " + explicitMinutes + " minutes");
			_missedReadingAlertPreSnoozed = true;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_PRESNOOZED, String(_missedReadingAlertPreSnoozed));
			Notifications.service.cancel(NotificationService.ID_FOR_MISSED_READING_ALERT);
			resetMissedreadingAlertPreSnooze();
			disableRepeatAlert(5);
			SpikeANE.stopPlayingSound();
			_missedReadingAlertSnoozePeriodInMinutes = isNaN(explicitMinutes) ? snoozeValueMinutes[index] : explicitMinutes;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_missedReadingAlertSnoozePeriodInMinutes));
			_missedReadingAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_missedReadingAlertLatestSnoozeTimeInMs));
		}
		
		public static function snoozePhoneMutedAlert(index:int, explicitMinutes:Number = Number.NaN):void {
			if (isNaN(explicitMinutes))
				myTrace("in snoozePhoneMutedAlert. Snoozing for " + snoozeValueMinutes[index] + " minutes");
			else
				myTrace("in snoozePhoneMutedAlert. Snoozing for " + explicitMinutes + " minutes");
			_phoneMutedAlertPreSnoozed = true;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_PRESNOOZED, String(_phoneMutedAlertPreSnoozed));
			Notifications.service.cancel(NotificationService.ID_FOR_PHONEMUTED_ALERT);
			resetPhoneMutedAlertPreSnooze();
			disableRepeatAlert(7);
			SpikeANE.stopPlayingSound();
			_phoneMutedAlertSnoozePeriodInMinutes = isNaN(explicitMinutes) ? snoozeValueMinutes[index] : explicitMinutes;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_phoneMutedAlertSnoozePeriodInMinutes));
			_phoneMutedAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_phoneMutedAlertLatestSnoozeTimeInMs));
		}
		
		public static function snoozeFastDropAlert(index:int, explicitMinutes:Number = Number.NaN):void {
			if (isNaN(explicitMinutes))
				myTrace("in snoozeFastDropAlert. Snoozing for " + snoozeValueMinutes[index] + " minutes");
			else
				myTrace("in snoozeFastDropAlert. Snoozing for " + explicitMinutes + " minutes");
			_fastDropAlertPreSnoozed = true;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_PRESNOOZED, String(_fastDropAlertPreSnoozed));
			Notifications.service.cancel(NotificationService.ID_FOR_FAST_DROP_ALERT);
			resetFastDropAlertPreSnooze();
			disableRepeatAlert(9);
			SpikeANE.stopPlayingSound();
			_fastDropAlertSnoozePeriodInMinutes = isNaN(explicitMinutes) ? snoozeValueMinutes[index] : explicitMinutes;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_fastDropAlertSnoozePeriodInMinutes));
			_fastDropAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_fastDropAlertLatestSnoozeTimeInMs));
		}
		
		public static function snoozeFastRiseAlert(index:int, explicitMinutes:Number = Number.NaN):void {
			if (isNaN(explicitMinutes))
				myTrace("in snoozeFastRiseAlert. Snoozing for " + snoozeValueMinutes[index] + " minutes");
			else
				myTrace("in snoozeFastRiseAlert. Snoozing for " + explicitMinutes + " minutes");
			_fastRiseAlertPreSnoozed = true;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_PRESNOOZED, String(_fastRiseAlertPreSnoozed));
			Notifications.service.cancel(NotificationService.ID_FOR_FAST_RISE_ALERT);
			resetFastRiseAlertPreSnooze();
			disableRepeatAlert(8);
			SpikeANE.stopPlayingSound();
			_fastRiseAlertSnoozePeriodInMinutes = isNaN(explicitMinutes) ? snoozeValueMinutes[index] : explicitMinutes;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_fastRiseAlertSnoozePeriodInMinutes));
			_fastRiseAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_fastRiseAlertLatestSnoozeTimeInMs));
		}
		
		private static function openSnoozePickerDialog(alertSetting:String, notificationId:int, notificationEvent:NotificationEvent, 
													   snoozePickerClosedHandler:Function, 
													   snoozeText:String, alertSnoozeIdentifier:String, snoozeValueSetter:Function, presnoozeResetFunction:Function = null):void {
			
			if (alertSetting == null) return;
			
			var listOfAlerts:FromtimeAndValueArrayCollection = FromtimeAndValueArrayCollection.createList(
				alertSetting, true);
			if (listOfAlerts == null) return;
			
			var alertName:String = listOfAlerts != null ? listOfAlerts.getAlarmName(Number.NaN, "", new Date()) : "";
			if (alertName == null) return;
			
			var alertType:AlertType = Database.getAlertType(alertName);
			if (alertType == null) return;
			
			myTrace("in openSnoozePickerDialog with id = " + NotificationService.notificationIdToText(notificationId) + ", cancelling notification");
			Notifications.service.cancel(notificationId);
			
			if (snoozeValueMinutes == null || snoozeValueStrings == null)
				return;
			
			var index:int = 0;
			for (var cntr:int = 0;cntr < snoozeValueMinutes.length;cntr++) {
				if ((snoozeValueMinutes[cntr]) >= alertType.defaultSnoozePeriodInMinutes) {
					index = cntr;
					break;
				}
			}
			if (notificationEvent == null || notificationEvent.identifier == null) 
			{
				AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CLOSED, snoozePickerClosedHandler);
				AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CANCELLED, canceledHandler);
				if 
				(
					(snoozeText != null && snoozeText == "low_alert_notification_alert_text") ||
					(snoozeText != null && snoozeText == "verylow_alert_notification_alert_text") ||
					(snoozeText != null && snoozeText == "high_alert_notification_alert_text") ||
					(snoozeText != null && snoozeText == "veryhigh_alert_notification_alert_text") ||
					(snoozeText != null && snoozeText == "fast_drop_alert_notification_alert_text") ||
					(snoozeText != null && snoozeText == "fast_rise_alert_notification_alert_text") ||
					(snoozeText != null && snoozeText == "snooze_text_low_alert") ||
					(snoozeText != null && snoozeText == "snooze_text_very_low_alert") ||
					(snoozeText != null && snoozeText == "snooze_text_high_alert") ||
					(snoozeText != null && snoozeText == "snooze_text_very_high_alert") ||
					(snoozeText != null && snoozeText == "snooze_text_fast_drop_alert") ||
					(snoozeText != null && snoozeText == "snooze_text_fast_rise_alert")
				)
				{
					var snoozerReading:BgReading = BgReading.lastNoSensor();
					if (snoozerReading != null)
					{
						SystemUtil.executeWhenApplicationIsActive
						(
							AlarmSnoozer.displaySnoozer,
							ModelLocator.resourceManagerInstance.getString("alarmservice",snoozeText) + "\n" + BgGraphBuilder.unitizedString(snoozerReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") + " " + GlucoseHelper.getGlucoseUnit(),
							snoozeValueStrings,
							index
						);
					}
				}
				else
				{
					SystemUtil.executeWhenApplicationIsActive
					(
						AlarmSnoozer.displaySnoozer,
						ModelLocator.resourceManagerInstance.getString("alarmservice",snoozeText),
						snoozeValueStrings,
						index
					);
				}
			} 
			else if (notificationEvent != null && notificationEvent.identifier == alertSnoozeIdentifier) {
				snoozeValueSetter(alertType.defaultSnoozePeriodInMinutes);
			}
			
			function canceledHandler(event:starling.events.Event):void {
				SpikeANE.stopPlayingSound();
				if (presnoozeResetFunction != null) {
					presnoozeResetFunction();
				}
			}
		}
		
		private static function setLowAlertSnooze(periodInMinutes:int):void {
			_lowAlertSnoozePeriodInMinutes = periodInMinutes;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_lowAlertSnoozePeriodInMinutes));
			myTrace("in notificationReceived with id = ID_FOR_LOW_ALERT, snoozing the notification for " + _lowAlertSnoozePeriodInMinutes + " minutes");
			_lowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_lowAlertLatestSnoozeTimeInMs));
			
			//Notify Services (ex: IFTTT)
			_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.LOW_GLUCOSE_SNOOZED,false,false,{type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_low_alert"),time: _lowAlertSnoozePeriodInMinutes}));
		}
		
		private static function setVeryLowAlertSnooze(periodInMinutes:int):void {
			_veryLowAlertSnoozePeriodInMinutes = periodInMinutes;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_veryLowAlertSnoozePeriodInMinutes));
			myTrace("in notificationReceived with id = ID_FOR_VERY_LOW_ALERT, snoozing the notification for " + _veryLowAlertSnoozePeriodInMinutes + " minutes");
			_veryLowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_veryLowAlertLatestSnoozeTimeInMs));
			
			//Notify Services (ex: IFTTT)
			_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.URGENT_LOW_GLUCOSE_SNOOZED,false,false,{type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_very_low_alert"), time: _veryLowAlertSnoozePeriodInMinutes}));
		}
		
		private static function setHighAlertSnooze(periodInMinutes:int):void {
			_highAlertSnoozePeriodInMinutes = periodInMinutes;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_highAlertSnoozePeriodInMinutes));
			myTrace("in notificationReceived with id = ID_FOR_HIGH_ALERT, snoozing the notification for " + _highAlertSnoozePeriodInMinutes + " minutes");
			_highAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_highAlertLatestSnoozeTimeInMs));
			
			//Notify Services (ex: IFTTT)
			_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.HIGH_GLUCOSE_SNOOZED,false,false,{type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_high_alert"),time: _highAlertSnoozePeriodInMinutes}));
		}
		
		private static function setVeryHighAlertSnooze(periodInMinutes:int):void {
			_veryHighAlertSnoozePeriodInMinutes = periodInMinutes;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_veryHighAlertSnoozePeriodInMinutes));
			myTrace("in notificationReceived with id = ID_FOR_VERY_HIGH_ALERT, snoozing the notification for " + _veryHighAlertSnoozePeriodInMinutes + " minutes");
			_veryHighAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_veryHighAlertLatestSnoozeTimeInMs));
			
			//Notify Services (ex: IFTTT)
			_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.URGENT_HIGH_GLUCOSE_SNOOZED,false,false,{type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_very_high_alert"),time: _veryHighAlertSnoozePeriodInMinutes}));
		}
		
		private static function setMissedReadingAlertSnooze(periodInMinutes:int):void {
			_missedReadingAlertSnoozePeriodInMinutes = periodInMinutes;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_missedReadingAlertSnoozePeriodInMinutes));
			myTrace("in notificationReceived with id = ID_FOR_MISSED_READING_ALERT, snoozing the notification for " + _missedReadingAlertSnoozePeriodInMinutes + " minutes");
			_missedReadingAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_missedReadingAlertLatestSnoozeTimeInMs));
			
			//Notify Services (ex: IFTTT)
			_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.MISSED_READINGS_SNOOZED,false,false,{type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_missed_reading_alert"),time: _missedReadingAlertSnoozePeriodInMinutes}));
		}
		
		private static function setPhoneMutedAlertSnooze(periodInMinutes:int):void {
			_phoneMutedAlertSnoozePeriodInMinutes = periodInMinutes;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_phoneMutedAlertSnoozePeriodInMinutes));
			myTrace("in notificationReceived with id = ID_FOR_PHONE_MUTED_ALERT, snoozing the notification for " + _phoneMutedAlertSnoozePeriodInMinutes + " minutes");
			_phoneMutedAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_phoneMutedAlertLatestSnoozeTimeInMs));
			
			//Notify Services (ex: IFTTT)
			_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.PHONE_MUTED_SNOOZED,false,false,{type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_phone_muted_alert"),time: _phoneMutedAlertSnoozePeriodInMinutes}));
		}
		
		private static function setFastDropAlertSnooze(periodInMinutes:int):void {
			_fastDropAlertSnoozePeriodInMinutes = periodInMinutes;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_fastDropAlertSnoozePeriodInMinutes));
			myTrace("in notificationReceived with id = ID_FOR_FAST_DROP_ALERT, snoozing the notification for " + _fastDropAlertSnoozePeriodInMinutes + " minutes");
			_fastDropAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_fastDropAlertLatestSnoozeTimeInMs));
			
			//Notify Services (ex: IFTTT)
			_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.FAST_DROP_SNOOZED,false,false,{type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_fast_drop_alert"),time: _fastDropAlertSnoozePeriodInMinutes}));
		}
		
		private static function setFastRiseAlertSnooze(periodInMinutes:int):void {
			_fastRiseAlertSnoozePeriodInMinutes = periodInMinutes;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_fastRiseAlertSnoozePeriodInMinutes));
			myTrace("in notificationReceived with id = ID_FOR_FAST_RISE_ALERT, snoozing the notification for " + _fastRiseAlertSnoozePeriodInMinutes + " minutes");
			_fastRiseAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_fastRiseAlertLatestSnoozeTimeInMs));
			
			//Notify Services (ex: IFTTT)
			_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.FAST_RISE_SNOOZED,false,false,{type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_fast_rise_alert"),time: _fastRiseAlertSnoozePeriodInMinutes}));
		}
		
		private static function lowSnoozePicker_closedHandler(event:starling.events.Event): void {
			myTrace("in lowSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
			disableRepeatAlert(1);
			SpikeANE.stopPlayingSound();
			_lowAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_lowAlertSnoozePeriodInMinutes));
			_lowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_lowAlertLatestSnoozeTimeInMs));
		}
		
		private static function veryLowSnoozePicker_closedHandler(event:starling.events.Event): void {
			myTrace("in veryLowSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
			disableRepeatAlert(2);
			SpikeANE.stopPlayingSound();
			_veryLowAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_veryLowAlertSnoozePeriodInMinutes));
			_veryLowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_veryLowAlertLatestSnoozeTimeInMs));
		}
		
		private static function highSnoozePicker_closedHandler(event:starling.events.Event): void {
			myTrace("in highSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
			disableRepeatAlert(3);
			SpikeANE.stopPlayingSound();
			_highAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_highAlertSnoozePeriodInMinutes));
			_highAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_highAlertLatestSnoozeTimeInMs));
		}
		
		private static function veryHighSnoozePicker_closedHandler(event:starling.events.Event): void {
			myTrace("in veryHighSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
			disableRepeatAlert(4);
			SpikeANE.stopPlayingSound();
			_veryHighAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_veryHighAlertSnoozePeriodInMinutes));
			_veryHighAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_veryHighAlertLatestSnoozeTimeInMs));
		}
		
		private static function missedReadingSnoozePicker_closedHandler(event:starling.events.Event): void {
			myTrace("in missedReadingSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
			disableRepeatAlert(5);
			SpikeANE.stopPlayingSound();
			_missedReadingAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_missedReadingAlertSnoozePeriodInMinutes));
			_missedReadingAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_missedReadingAlertLatestSnoozeTimeInMs));
		}
		
		private static function phoneMutedSnoozePicker_closedHandler(event:starling.events.Event): void {
			myTrace("in phoneMutedSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
			AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, phoneMutedSnoozePicker_closedHandler);
			disableRepeatAlert(7);
			SpikeANE.stopPlayingSound();
			_phoneMutedAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_phoneMutedAlertSnoozePeriodInMinutes));
			_phoneMutedAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_phoneMutedAlertLatestSnoozeTimeInMs));
		}
		
		private static function fastDropSnoozePicker_closedHandler(event:starling.events.Event): void {
			myTrace("in fastDropSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
			disableRepeatAlert(9);
			SpikeANE.stopPlayingSound();
			_fastDropAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_fastDropAlertSnoozePeriodInMinutes));
			_fastDropAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_fastDropAlertLatestSnoozeTimeInMs));
		}
		
		private static function fastRiseSnoozePicker_closedHandler(event:starling.events.Event): void {
			myTrace("in fastRiseSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
			disableRepeatAlert(8);
			SpikeANE.stopPlayingSound();
			_fastRiseAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_fastRiseAlertSnoozePeriodInMinutes));
			_fastRiseAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_fastRiseAlertLatestSnoozeTimeInMs));
		}
		
		private static function checkAlarms(be:flash.events.Event):void {
			myTrace("in checkAlarms");
			var now:Date = new Date();
			lastAlarmCheckTimeStamp = now.valueOf();
			var alertActive:Boolean = false;
			
			var lastbgreading:BgReading = BgReading.lastNoSensor();
			if (lastbgreading != null) 
			{
				if (now.valueOf() - lastbgreading.timestamp < MAX_AGE_OF_READING_IN_MINUTES * TimeSpan.TIME_1_MINUTE) 
				{
					alertActive = checkFastDropAlert(now);
					if (!alertActive)
					{
						alertActive = checkFastRiseAlert(now);
						if (!alertActive)
						{
							alertActive = checkVeryLowAlert(now);
							if(!alertActive) 
							{
								alertActive = checkLowAlert(now);
								if (!alertActive) 
								{
									alertActive = checkVeryHighAlert(now);
									if (!alertActive) 
									{
										alertActive = checkHighAlert(now);
									} else 
									{
										if (!_highAlertPreSnoozed)
											resetHighAlert();
									}
								} 
								else 
								{
									if (!_highAlertPreSnoozed)
										resetHighAlert();
									if (!_veryHighAlertPreSnoozed)
										resetVeryHighAlert();
								}
							} 
							else 
							{
								if (!_highAlertPreSnoozed)
									resetHighAlert();
								if (!_veryHighAlertPreSnoozed)
									resetVeryHighAlert();
								if (!_lowAlertPreSnoozed)
									resetLowAlert();
							}
						}
						else
						{
							if (!_veryLowAlertPreSnoozed)
								resetVeryLowAlert();
							if (!_highAlertPreSnoozed)
								resetHighAlert();
							if (!_veryHighAlertPreSnoozed)
								resetVeryHighAlert();
							if (!_lowAlertPreSnoozed)
								resetLowAlert();
						}
					}
					else
					{
						if (!_fastRiseAlertPreSnoozed)
							resetFastRiseAlert();
						if (!_veryLowAlertPreSnoozed)
							resetVeryLowAlert();
						if (!_highAlertPreSnoozed)
							resetHighAlert();
						if (!_veryHighAlertPreSnoozed)
							resetVeryHighAlert();
						if (!_lowAlertPreSnoozed)
							resetLowAlert();
					}
				}
				checkMissedReadingAlert();

				if (!alertActive && !CGMBlueToothDevice.isFollower()) {
					//to avoid that the arrival of a notification of a checkCalibrationRequestAlert stops the sounds of a previous low or high alert
					checkCalibrationRequestAlert(now);
				}
			}

			if (!alertActive && !CGMBlueToothDevice.isFollower()) {
				//to avoid that the arrival of a notification of a checkBatteryLowAlert stops the sounds of a previous low or high alert
				checkBatteryLowAlert(now);
			}
		}
		
		private static function phoneMuted(event:SpikeANEEvent):void {
			myTrace("in phoneMuted");
			ModelLocator.phoneMuted = true;
			var now:Date = new Date(); 
			if (now.valueOf() - lastPhoneMutedAlertCheckTimeStamp > TimeSpan.TIME_4_MINUTES_45_SECONDS) {
				myTrace("in phoneMuted, checking phoneMute Alarm because it's been more than 4 minutes 45 seconds");
				lastPhoneMutedAlertCheckTimeStamp = (new Date()).valueOf();
				var listOfAlerts:FromtimeAndValueArrayCollection = FromtimeAndValueArrayCollection.createList(
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT), false);
				//var alertValue:Number = listOfAlerts.getValue(Number.NaN, "", now);
				var alertName:String = listOfAlerts.getAlarmName(Number.NaN, "", now);
				var alertType:AlertType = Database.getAlertType(alertName);
				if (alertType != null && alertType.enabled) {
					//first check if snoozeperiod is passed, checking first for value would generate multiple alarms in case the sensor is unstable
					if (((now).valueOf() - _phoneMutedAlertLatestSnoozeTimeInMs) > _phoneMutedAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
						||
						isNaN(_phoneMutedAlertLatestSnoozeTimeInMs)) {
						myTrace("in phoneMuted, phoneMuted alert not snoozed ");
						fireAlert(
							7,
							alertType, 
							NotificationService.ID_FOR_PHONEMUTED_ALERT, 
							ModelLocator.resourceManagerInstance.getString("alarmservice","phonemuted_alert_notification_alert_text"), 
							alertType.enableVibration,
							alertType.enableLights,
							NotificationService.ID_FOR_PHONE_MUTED_CATEGORY
						); 
						_phoneMutedAlertLatestSnoozeTimeInMs = Number.NaN;
						LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_phoneMutedAlertLatestSnoozeTimeInMs));
						_phoneMutedAlertSnoozePeriodInMinutes = 0;
						LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_phoneMutedAlertSnoozePeriodInMinutes));
					} else {
						//snoozed no need to do anything
						myTrace("in phoneMuted, alarm snoozed, _phoneMutedAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_phoneMutedAlertLatestSnoozeTimeInMs)) + ", _phoneMutedAlertSnoozePeriodInMinutes = " + _phoneMutedAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				} else {
					//if not presnoozed then remove notification, even if there isn't any
					myTrace("in phoneMuted, alerttype not enabled");
					if (!_phoneMutedAlertPreSnoozed) {
						myTrace("cancel any existing alert for ID_FOR_PHONEMUTED_ALERT");
						Notifications.service.cancel(NotificationService.ID_FOR_PHONEMUTED_ALERT);
						_phoneMutedAlertLatestSnoozeTimeInMs = Number.NaN;
						LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_phoneMutedAlertLatestSnoozeTimeInMs));
						_phoneMutedAlertSnoozePeriodInMinutes = 0;
						LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_phoneMutedAlertSnoozePeriodInMinutes));
					}
				}
				
			} else {
				myTrace("less than 4 minutes 45 seconds since last check, not checking phoneMuted alert now");
			}
		}
		
		private static function phoneNotMuted(event:SpikeANEEvent):void {
			myTrace("in phoneNotMuted");
			ModelLocator.phoneMuted = false;
			
			if ((new Date()).valueOf() - lastQueuedAlertSoundTimeStamp < TimeSpan.TIME_2_SECONDS) {//it should normally be max 1 second
				if (queuedAlertSound != "") {
					myTrace("in phoneNotMuted, sound queued and fired alert time < 2 seconds ago");
					SpikeANE.playSound(queuedAlertSound, Number.NaN, LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALARMS_USER_DEFINED_SYSTEM_VOLUME_ON) == "true" ? Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALARMS_USER_DEFINED_SYSTEM_VOLUME_VALUE)) : Number.NaN);
				}
			}
			queuedAlertSound = "";
			
			//if not presnoozed then remove notification, even if there isn't any
			if (!_phoneMutedAlertPreSnoozed) {
				myTrace("cancel any existing alert for ID_FOR_PHONEMUTED_ALERT");
				Notifications.service.cancel(NotificationService.ID_FOR_PHONEMUTED_ALERT);
				_phoneMutedAlertLatestSnoozeTimeInMs = Number.NaN;
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_phoneMutedAlertLatestSnoozeTimeInMs));
				_phoneMutedAlertSnoozePeriodInMinutes = 0;
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_phoneMutedAlertSnoozePeriodInMinutes));
				disableRepeatAlert(7);
			}
		}
		
		/**
		 * repeatId ==> 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted, 8:Fast Rise, 9:Fast Drop<br>
		 */
		private static function fireAlert(repeatId:int, alertType:AlertType, notificationId:int, alertText:String, enableVibration:Boolean, enableLights:Boolean, categoryId:String, alertBody:String = " "):void {	
			cancelInactiveAlert(); //so it doesn't overlap with the alarm sound
			
			var notificationBuilder:NotificationBuilder;
			var newSound:String;
			var soundToSet:String = "";
			if (alertBody.length == 0)
				alertBody = " ";
			
			notificationBuilder = new NotificationBuilder()
				.setCount(BadgeBuilder.getAppBadge())
				.setId(notificationId)
				.setAlert(alertText)
				.setTitle(alertText)
				.setBody(alertBody)
				.enableVibration(false)//vibration will be done through BackgroundFetch ANE
				.enableLights(enableLights);
			if (categoryId != null)
				notificationBuilder.setCategory(categoryId);
			
			if (StringUtil.trim(alertType.sound) == "default") {//using trim because during tests sometimes the soundname had a preceding white space
				soundToSet = "default";//only here for backward compatibility. default sound has been removed release 2.2.5
			} else if (StringUtil.trim(alertType.sound) == "no_sound") {
				//keep soundToSet = "";
			} else {	
				soundToSet = StringUtil.trim(alertType.sound);
				
				if (soundToSet.indexOf(".caf") == -1)
				{
					//Old version of Spike
					var soundNames:Array = AlertCustomizerList.ALERT_NAMES_LIST.split(",");
					var soundFiles:Array = AlertCustomizerList.ALERT_SOUNDS_LIST.split(",");
					
					for (var i:int = 0; i < soundNames.length; i++) 
					{
						var soundName:String = StringUtil.trim(soundNames[i] as String);
						if (soundName == soundToSet)
						{
							soundToSet = StringUtil.trim(soundFiles[i] as String);
							
							//Update to the new format because it's more efficient
							alertType.sound = soundToSet;
							Database.updateAlertTypeSynchronous(alertType);
							
							break;
						}
					}
				}
			}
			
			if (ModelLocator.phoneMuted && !(StringUtil.trim(alertType.sound) == "default") && !(StringUtil.trim(alertType.sound) == "")) {//check against default for backward compability. Default sound can't be played with playSound
				if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_OVERRIDE_MUTE) == "true") 
				{
					SpikeANE.playSound("../assets/sounds/" + soundToSet, Number.NaN, LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALARMS_USER_DEFINED_SYSTEM_VOLUME_ON) == "true" ? Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALARMS_USER_DEFINED_SYSTEM_VOLUME_VALUE)) : Number.NaN);
				}
				else 
				{
					if (ModelLocator.phoneMuted) {
						//Phone muted but user may have unmuted, so let's queue the sound and check muted
						queueAlertSound("../assets/sounds/" + soundToSet);
					}
				}
			} 
			else 
			{
				queueAlertSound("../assets/sounds/" + soundToSet);
			}
			
			if (soundToSet == "default")
				notificationBuilder.setSound("default");//just in case  soundToSet = default
			else 
				notificationBuilder.setSound("");
			
			Notifications.service.notify(notificationBuilder.build());
			
			if (enableVibration) {
				SpikeANE.vibrate();
			}
			
			//set repeat arrays
			enableRepeatAlert(repeatId, alertType.alarmName, alertText, alertBody);
			
			//Reset Timer
			if (alarmTimer.running)
			{
				alarmTimer.stop();
				alarmTimer.delay = 60000;
				alarmTimer.start();
			}
			
			//Notify services (ex: IFTTT)
			if (notificationId == NotificationService.ID_FOR_CALIBRATION_REQUEST_ALERT)
				_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.CALIBRATION_TRIGGERED));
			else if (notificationId == NotificationService.ID_FOR_LOW_ALERT)
				_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.LOW_GLUCOSE_TRIGGERED));
			else if (notificationId == NotificationService.ID_FOR_VERY_LOW_ALERT)
				_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.URGENT_LOW_GLUCOSE_TRIGGERED));
			else if (notificationId == NotificationService.ID_FOR_HIGH_ALERT)
				_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.HIGH_GLUCOSE_TRIGGERED));
			else if (notificationId == NotificationService.ID_FOR_VERY_HIGH_ALERT)
				_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.URGENT_HIGH_GLUCOSE_TRIGGERED));
			else if (notificationId == NotificationService.ID_FOR_MISSED_READING_ALERT)
				_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.MISSED_READINGS_TRIGGERED));
			else if (notificationId == NotificationService.ID_FOR_BATTERY_ALERT)
				_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.TRANSMITTER_LOW_BATTERY_TRIGGERED));
			else if (notificationId == NotificationService.ID_FOR_PHONEMUTED_ALERT)
				_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.PHONE_MUTED_TRIGGERED));
			else if (notificationId == NotificationService.ID_FOR_FAST_RISE_ALERT)
				_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.FAST_RISE_TRIGGERED));
			else if (notificationId == NotificationService.ID_FOR_FAST_DROP_ALERT)
				_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.FAST_DROP_TRIGGERED));
		}
		
		private static function queueAlertSound(sound:String):void {
			queuedAlertSound = sound;
			lastQueuedAlertSoundTimeStamp = (new Date()).valueOf();
			
			//phone might be muted, but Modellocator.phonemuted may be false
			//launch check now
			//use SpikeANE.checkmuted, bypasses all phone muted settings, user might have switched from non muted to muted just very recently
			SpikeANE.checkMuted();
		}
		
		public static function cancelInactiveAlert():void
		{
			myTrace("in cancelInactiveAlert, canceling app inactive alert");
			Notifications.service.cancel(NotificationService.ID_FOR_APPLICATION_INACTIVE_ALERT);
			lastApplicationStoppedAlertCheckTimeStamp = (new Date()).valueOf();
		}
		
		private static function planApplicationStoppedAlert():void {
			myTrace("in planApplicationStoppedAlert, planning alert for the future");
			cancelInactiveAlert();
			
			if ((CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) != "" && Calibration.allForSensor().length >= 2) || CGMBlueToothDevice.isFollower())
			{
				Notifications.service.cancel(NotificationService.ID_FOR_APPLICATION_INACTIVE_ALERT);
				
				var notificationBuilder:NotificationBuilder = new NotificationBuilder()
					.setId(NotificationService.ID_FOR_APPLICATION_INACTIVE_ALERT)
					.setAlert(ModelLocator.resourceManagerInstance.getString("globaltranslations","warning_alert_title"))
					.setTitle(ModelLocator.resourceManagerInstance.getString("globaltranslations","warning_alert_title"))
					.setBody(ModelLocator.resourceManagerInstance.getString("alarmservice","application_stopped_alert_body"))
					.enableVibration(true)
					.enableLights(true)
					.setSound("../assets/sounds/Sci-Fi_Alarm_Loop_4.caf")
					.setDelay(680);
				
				Notifications.service.notify(notificationBuilder.build());
			}
			else
				myTrace("in planApplicationStoppedAlert, not planning an inactive alert... user has not set a transmitter yet or doesn't have enough calibrtions.");
		}
		
		private static function checkMissedReadingAlert():void {
			var listOfAlerts:FromtimeAndValueArrayCollection;
			var alertValue:Number;
			var alertName:String;
			var alertType:AlertType;
			var now:Date = new Date();
			
			lastMissedReadingAlertCheckTimeStamp = (new Date()).valueOf(); 	
			
			if (Sensor.getActiveSensor() == null && !CGMBlueToothDevice.isFollower()) {
				myTrace("in checkMissedReadingAlert, but sensor is not active and not follower, not planning a missed reading alert now, and cancelling any missed reading alert that maybe still exists");
				myTrace("cancel any existing alert for ID_FOR_MISSED_READING_ALERT");
				Notifications.service.cancel(NotificationService.ID_FOR_MISSED_READING_ALERT);
				return;
			}
			var lastBgReading:BgReading 
			if (!CGMBlueToothDevice.isFollower()) {
				var lastBgReadings:Array = BgReading.latest(1);
				if (lastBgReadings.length == 0) {
					myTrace("in checkMissedReadingAlert, but no readings exist yet, not planning a missed reading alert now, and cancelling any missed reading alert that maybe still exists");
					myTrace("cancel any existing alert for ID_FOR_MISSED_READING_ALERT");
					Notifications.service.cancel(NotificationService.ID_FOR_MISSED_READING_ALERT);
					return;
				} 
				lastBgReading = lastBgReadings[0] as BgReading;
			} else {
				lastBgReading = BgReading.lastWithCalculatedValue();
				if (lastBgReading == null) {
					myTrace("in checkMissedReadingAlert, but no readings exist yet, not planning a missed reading alert now, and cancelling any missed reading alert that maybe still exists");
					myTrace("cancel any existing alert for ID_FOR_MISSED_READING_ALERT");
					Notifications.service.cancel(NotificationService.ID_FOR_MISSED_READING_ALERT);
					return;
				}
			}
			
			listOfAlerts = FromtimeAndValueArrayCollection.createList(
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_MISSED_READING_ALERT), false);
			alertValue = listOfAlerts.getValue(Number.NaN, "", now);
			alertName = listOfAlerts.getAlarmName(Number.NaN, "", now);
			alertType = Database.getAlertType(alertName);
			if (alertType != null && alertType.enabled) {
				myTrace("in checkMissedReadingAlert, alertType enabled");
				if (((now).valueOf() - _missedReadingAlertLatestSnoozeTimeInMs) > _missedReadingAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
					||
					isNaN(_missedReadingAlertLatestSnoozeTimeInMs)) {
					myTrace("in checkMissedReadingAlert, missed reading alert not snoozed");
					//not snoozed
					if (((now.valueOf() - lastBgReading.timestamp) > alertValue * TimeSpan.TIME_1_MINUTE) && ((now.valueOf() - ModelLocator.appStartTimestamp) > TimeSpan.TIME_5_MINUTES)) {
						myTrace("in checkAlarms, missed reading");
						
						var alertBody:String = " ";
						if (CGMBlueToothDevice.isMiaoMiao()) 
						{
							if (CGMBluetoothService.amountOfConsecutiveSensorNotDetectedForMiaoMiao > 0) 
							{
								alertBody = ModelLocator.resourceManagerInstance.getString("alarmservice","received");
								alertBody += " " + CGMBluetoothService.amountOfConsecutiveSensorNotDetectedForMiaoMiao + " ";
								alertBody += ModelLocator.resourceManagerInstance.getString("alarmservice","consecutive_sensor_not_detected");
							}
							myTrace("in checkMissedReadingAlert, fire alert with body = " + alertBody);
						}
						
						fireAlert(
							5,
							alertType, 
							NotificationService.ID_FOR_MISSED_READING_ALERT, 
							ModelLocator.resourceManagerInstance.getString("alarmservice","missed_reading_alert_notification_alert"), 
							alertType.enableVibration,
							alertType.enableLights,
							NotificationService.ID_FOR_ALERT_MISSED_READING_CATEGORY,
							alertBody
						); 
						_missedReadingAlertLatestSnoozeTimeInMs = Number.NaN;
						LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_missedReadingAlertLatestSnoozeTimeInMs));
						_missedReadingAlertSnoozePeriodInMinutes = 0;
						LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_missedReadingAlertSnoozePeriodInMinutes));
					} else {
						myTrace("cancel any existing alert for ID_FOR_MISSED_READING_ALERT");
						Notifications.service.cancel(NotificationService.ID_FOR_MISSED_READING_ALERT);
						disableRepeatAlert(5);
					}
				} else {
					//snoozed no need to do anything
					myTrace("in checkMissedReadingAlert, missed reading snoozed, _missedReadingAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_missedReadingAlertLatestSnoozeTimeInMs)) + ", _missedReadingAlertSnoozePeriodInMinutes = " + _missedReadingAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
				}
			} else {
				//if not presnoozed, remove missed reading notification, even if there isn't any
				if (!_missedReadingAlertPreSnoozed) {
					resetMissedReadingAlert();
				}
			}
		}
		
		private static function checkCalibrationRequestAlert(now:Date):void 
		{
			if (CalibrationService.optimalCalibrationScheduled)
				return;
			
			var listOfAlerts:FromtimeAndValueArrayCollection;
			var alertValue:Number;
			var alertName:String;
			var alertType:AlertType;
			
			listOfAlerts = FromtimeAndValueArrayCollection.createList(
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CALIBRATION_REQUEST_ALERT), false);
			if (listOfAlerts == null) return;
			
			alertValue = listOfAlerts.getValue(Number.NaN, "", now);
			if (isNaN(alertValue)) return;
			
			alertName = listOfAlerts.getAlarmName(Number.NaN, "", now);
			if (alertName == null) return;
			
			alertType = Database.getAlertType(alertName);
			if (alertType == null) return;
			
			if (alertType.enabled && !isNaN(alertValue) && alertName != "") {
				if ((now.valueOf() - _calibrationRequestLatestSnoozeTimeInMs) > _calibrationRequestSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
					||
					isNaN(_calibrationRequestLatestSnoozeTimeInMs)) {
					myTrace("in checkAlarms, calibration request alert not snoozed ");
					if (Calibration.last() != null && BgReading.last30Minutes() != null && BgReading.last30Minutes().length >= 2) 
					{
						var isOptimaCalibration:Boolean = GlucoseHelper.isOptimalConditionToCalibrate();
						var lastCalibrationTimestamp:Number = Calibration.last().timestamp;
						
						if (alertValue < ((now.valueOf() - lastCalibrationTimestamp) / 1000 / 60 / 60) && !isOptimaCalibration && !userWarnedOfSuboptimalCalibration) 
						{
							//Warn the user (only once) of suboptimal conditions to calibrate
							var notificationBuilder:NotificationBuilder = new NotificationBuilder()
								.setCount(BadgeBuilder.getAppBadge())
								.setId(NotificationService.ID_FOR_CALIBRATION_REQUEST_ALERT)
								.setAlert(ModelLocator.resourceManagerInstance.getString('alarmservice','suboptimal_calibration_request_alert_notification_alert_title'))
								.setTitle(ModelLocator.resourceManagerInstance.getString('alarmservice','suboptimal_calibration_request_alert_notification_alert_title'))
								.setBody(ModelLocator.resourceManagerInstance.getString('alarmservice','suboptimal_calibration_request_notification_body'))
								.enableLights(true)
								.setSound("default")
								.setCategory(NotificationService.ID_FOR_ALERT_CALIBRATION_REQUEST_CATEGORY);
							Notifications.service.notify(notificationBuilder.build());
							
							SpikeANE.vibrate();
							userWarnedOfSuboptimalCalibration = true;
							userRequestedSuboptimalCalibrationNotification = false;
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_OPTIMAL_CALIBRATION_BY_ALARM_NOTIFIED_ON, String(userWarnedOfSuboptimalCalibration), true, false);
						} 
						else if (alertValue < ((now.valueOf() - lastCalibrationTimestamp) / 1000 / 60 / 60) && isOptimaCalibration && !userRequestedSuboptimalCalibrationNotification) 
						{
							myTrace("in checkAlarms, calibration is necessary");
							fireAlert(
								0,
								alertType, 
								NotificationService.ID_FOR_CALIBRATION_REQUEST_ALERT, 
								ModelLocator.resourceManagerInstance.getString("alarmservice","calibration_request_alert_notification_alert_title"), 
								alertType.enableVibration,
								alertType.enableLights,
								NotificationService.ID_FOR_ALERT_CALIBRATION_REQUEST_CATEGORY
							); 
							_calibrationRequestLatestSnoozeTimeInMs = Number.NaN;
							_calibrationRequestSnoozePeriodInMinutes = 0;
							userWarnedOfSuboptimalCalibration = false;
							CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_OPTIMAL_CALIBRATION_BY_ALARM_NOTIFIED_ON, String(userWarnedOfSuboptimalCalibration), true, false);
							
							if (canUploadCalibrationToNightscout)
							{
								NightscoutService.uploadOptimalCalibrationNotification();
								canUploadCalibrationToNightscout = false;
							}
						} 
						else 
						{
							myTrace("cancel any existing alert for ID_FOR_CALIBRATION_REQUEST_ALERT");
							Notifications.service.cancel(NotificationService.ID_FOR_CALIBRATION_REQUEST_ALERT);
							disableRepeatAlert(0);
						}
					} else {
						myTrace("cancel any existing alert for ID_FOR_CALIBRATION_REQUEST_ALERT");
						Notifications.service.cancel(NotificationService.ID_FOR_CALIBRATION_REQUEST_ALERT);
						disableRepeatAlert(0);
					}
				} else {
					//snoozed no need to do anything
					myTrace("in checkAlarms, alarm snoozed, _calibrationRequestLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_calibrationRequestLatestSnoozeTimeInMs)) + ", _calibrationRequestSnoozePeriodInMinutes = " + _calibrationRequestSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
				}
			} else {
				//remove calibration request notification, even if there isn't any	
				myTrace("cancel any existing alert for ID_FOR_CALIBRATION_REQUEST_ALERT");
				Notifications.service.cancel(NotificationService.ID_FOR_CALIBRATION_REQUEST_ALERT);
				disableRepeatAlert(0);
				_calibrationRequestLatestSnoozeTimeInMs = Number.NaN;
				_calibrationRequestSnoozePeriodInMinutes = 0;
			}
		}
		
		/**
		 * returns true of alarm fired
		 */private static function checkBatteryLowAlert(now:Date):Boolean {
			 if (CGMBlueToothDevice.isBlueReader() || CGMBlueToothDevice.isLimitter()) {
				 myTrace("in checkAlarms, checkBatteryLowAlert, device is bluereader or limitter, battery value not yet supported/tested.");
				 return false;
			 }
			 
			 var listOfAlerts:FromtimeAndValueArrayCollection;
			 var alertValue:Number;
			 var alertName:String;
			 var alertType:AlertType;
			 var returnValue:Boolean = false;
			 
			 listOfAlerts = FromtimeAndValueArrayCollection.createList(
				 CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BATTERY_ALERT), false);
			 alertValue = listOfAlerts.getValue(Number.NaN, "", now);
			 alertName = listOfAlerts.getAlarmName(Number.NaN, "", now);
			 alertType = Database.getAlertType(alertName);
			 if (alertType != null && alertType.enabled) {
				 //first check if snoozeperiod is passed, checking first for value would generate multiple alarms in case the sensor is unstable
				 if (((now).valueOf() - _batteryLevelAlertLatestSnoozeTimeInMs) > _batteryLevelAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
					 ||
					 isNaN(_batteryLevelAlertLatestSnoozeTimeInMs)) {
					 myTrace("in checkAlarms, batteryLevel alert not snoozed ");
					 //not snoozed
					 
					 if ((CGMBlueToothDevice.isDexcomG4() && (new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G4_TRANSMITTER_BATTERY_VOLTAGE)) < alertValue) && (new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G4_TRANSMITTER_BATTERY_VOLTAGE)) > 0))
						 ||
						 (CGMBlueToothDevice.isBluKon() && (new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL)) < alertValue) && (new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL)) > 0))
						 ||
						 (CGMBlueToothDevice.isMiaoMiao() && (new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_MIAOMIAO_BATTERY_LEVEL)) < alertValue) && (new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_MIAOMIAO_BATTERY_LEVEL)) > 0))
						 ||
						 (CGMBlueToothDevice.isxBridgeR() && (new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_XBRIDGER_BATTERY_LEVEL)) < alertValue) && (new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_XBRIDGER_BATTERY_LEVEL)) > 0))
						 ||
						 (CGMBlueToothDevice.isBlueReader() && (new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL)) < alertValue) && (new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL)) > 0))
						 ||
						 ((CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6()) && (new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VOLTAGEA)) < alertValue) && (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VOLTAGEA) != "unknown"))) {
						 myTrace("in checkAlarms, battery level is too low");
						 fireAlert(
							 6,
							 alertType, 
							 NotificationService.ID_FOR_BATTERY_ALERT, 
							 ModelLocator.resourceManagerInstance.getString("alarmservice","batteryLevel_alert_notification_alert_text"), 
							 alertType.enableVibration,
							 alertType.enableLights,
							 NotificationService.ID_FOR_ALERT_BATTERY_CATEGORY
						 ); 
						 _batteryLevelAlertLatestSnoozeTimeInMs = Number.NaN;
						 _batteryLevelAlertSnoozePeriodInMinutes = 0;
						 returnValue = true;
					 } else {
						 myTrace("cancel any existing alert for ID_FOR_BATTERY_ALERT");
						 Notifications.service.cancel(NotificationService.ID_FOR_BATTERY_ALERT);
						 disableRepeatAlert(6);
					 }
				 } else {
					 //snoozed no need to do anything
					 myTrace("in checkAlarms, alarm snoozed, _batteryLevelAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_batteryLevelAlertLatestSnoozeTimeInMs)) + ", _batteryLevelAlertSnoozePeriodInMinutes = " + _batteryLevelAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
				 }
			 } else {
				 //remove notification, even if there isn't any
				 myTrace("cancel any existing alert for ID_FOR_BATTERY_ALERT");
				 Notifications.service.cancel(NotificationService.ID_FOR_BATTERY_ALERT);
				 disableRepeatAlert(6);
				 _batteryLevelAlertLatestSnoozeTimeInMs = Number.NaN;
				 _batteryLevelAlertSnoozePeriodInMinutes = 0;
			 }
			 return returnValue;
		 }
		
		/**
		 * returns true of alarm fired
		 */private static function checkHighAlert(now:Date):Boolean {
			 var listOfAlerts:FromtimeAndValueArrayCollection;
			 var alertValue:Number;
			 var alertName:String;
			 var alertType:AlertType;
			 var returnValue:Boolean = false;
			 
			 listOfAlerts = FromtimeAndValueArrayCollection.createList(
				 CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_ALERT), true);
			 alertValue = listOfAlerts.getValue(Number.NaN, "", now);
			 alertName = listOfAlerts.getAlarmName(Number.NaN, "", now);
			 alertType = Database.getAlertType(alertName);
			 if (alertType != null && alertType.enabled) {
				 //first check if snoozeperiod is passed, checking first for value would generate multiple alarms in case the sensor is unstable
				 if (((now).valueOf() - _highAlertLatestSnoozeTimeInMs) > _highAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
					 ||
					 isNaN(_highAlertLatestSnoozeTimeInMs)) {
					 myTrace("in checkAlarms, high alert not snoozed ");
					 //not snoozed
					 
					 var lastBgReading:BgReading = BgReading.lastNoSensor(); 
					 if (alertValue < lastBgReading.calculatedValue) {
						 myTrace("in checkAlarms, reading is too high");
						 fireAlert(
							 3,
							 alertType, 
							 NotificationService.ID_FOR_HIGH_ALERT, 
							 ModelLocator.resourceManagerInstance.getString("alarmservice","high_alert_notification_alert_text"),
							 alertType.enableVibration,
							 alertType.enableLights,
							 NotificationService.ID_FOR_ALERT_HIGH_CATEGORY,
							 BgGraphBuilder.unitizedString(BgReading.lastNoSensor().calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") + " " + (lastBgReading.hideSlope ? "":(lastBgReading.slopeArrow())) + " " + BgGraphBuilder.unitizedDeltaString(true, true)
						 ); 
						 _highAlertLatestSnoozeTimeInMs = Number.NaN;
						 LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_highAlertLatestSnoozeTimeInMs));
						 _highAlertSnoozePeriodInMinutes = 0;
						 LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_highAlertSnoozePeriodInMinutes));
						 returnValue = true;
					 } else {
						 myTrace("cancel any existing alert for ID_FOR_HIGH_ALERT");
						 Notifications.service.cancel(NotificationService.ID_FOR_HIGH_ALERT);
						 disableRepeatAlert(3);
					 }
				 } else {
					 //snoozed no need to do anything
					 myTrace("in checkAlarms, alarm snoozed, _highAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_highAlertLatestSnoozeTimeInMs)) + ", _highAlertSnoozePeriodInMinutes = " + _highAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
				 }
			 } else {
				 //if not presnoozed remove notification, even if there isn't any
				 if (!_highAlertPreSnoozed) {
					 resetHighAlert();
				 }
			 }
			 return returnValue;
		 }
		
		/**
		 * returns true of alarm fired or if alert is snoozed
		 */private static function checkVeryHighAlert(now:Date):Boolean {
			 var listOfAlerts:FromtimeAndValueArrayCollection;
			 var alertValue:Number;
			 var alertName:String;
			 var alertType:AlertType;
			 var returnValue:Boolean = false;
			 
			 listOfAlerts = FromtimeAndValueArrayCollection.createList(
				 CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_VERY_HIGH_ALERT), true);
			 alertValue = listOfAlerts.getValue(Number.NaN, "", now);
			 alertName = listOfAlerts.getAlarmName(Number.NaN, "", now);
			 alertType = Database.getAlertType(alertName);
			 if (alertType != null && alertType.enabled) {
				 //first check if snoozeperiod is passed, checking first for value would generate multiple alarms in case the sensor is unstable
				 if (((now).valueOf() - _veryHighAlertLatestSnoozeTimeInMs) > _veryHighAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
					 ||
					 isNaN(_veryHighAlertLatestSnoozeTimeInMs)) {
					 myTrace("in checkAlarms, veryHigh alert not snoozed ");
					 //not snoozed
					 
					 var lastBgReading:BgReading = BgReading.lastNoSensor(); 
					 if (alertValue < lastBgReading.calculatedValue) {
						 myTrace("in checkAlarms, reading is too veryHigh");
						 fireAlert(
							 4,
							 alertType, 
							 NotificationService.ID_FOR_VERY_HIGH_ALERT, 
							 ModelLocator.resourceManagerInstance.getString("alarmservice","veryhigh_alert_notification_alert_text"),
							 alertType.enableVibration,
							 alertType.enableLights,
							 NotificationService.ID_FOR_ALERT_VERY_HIGH_CATEGORY,
							 BgGraphBuilder.unitizedString(BgReading.lastNoSensor().calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") + " " + (lastBgReading.hideSlope ? "":(lastBgReading.slopeArrow())) + " " + BgGraphBuilder.unitizedDeltaString(true, true)
						 ); 
						 _veryHighAlertLatestSnoozeTimeInMs = Number.NaN;
						 LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_veryHighAlertLatestSnoozeTimeInMs));
						 _veryHighAlertSnoozePeriodInMinutes = 0;
						 LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_veryHighAlertSnoozePeriodInMinutes));
						 returnValue = true;
					 } else {
						 myTrace("cancel any existing alert for ID_FOR_VERY_HIGH_ALERT");
						 Notifications.service.cancel(NotificationService.ID_FOR_VERY_HIGH_ALERT);
						 disableRepeatAlert(4);
					 }
				 } else {
					 //snoozed no need to do anything,returnvalue = true because there's no need to check for high alert
					 returnValue = true;
					 myTrace("in checkAlarms, alarm snoozed, _veryHighAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_veryHighAlertLatestSnoozeTimeInMs)) + ", _veryHighAlertSnoozePeriodInMinutes = " + _veryHighAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
				 }
			 } else {
				 //if not presnoozed remove notification, even if there isn't any
				 if (!_veryHighAlertPreSnoozed) {
					 resetVeryHighAlert();
				 }
			 }
			 return returnValue;
		 }
		
		/**
		 * returns true of alarm fired
		 */private static function checkLowAlert(now:Date):Boolean {
			 var listOfAlerts:FromtimeAndValueArrayCollection;
			 var alertValue:Number;
			 var alertName:String;
			 var alertType:AlertType;
			 var returnValue:Boolean = false;
			 
			 listOfAlerts = FromtimeAndValueArrayCollection.createList(
				 CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_ALERT), true);
			 alertValue = listOfAlerts.getValue(Number.NaN, "", now);
			 alertName = listOfAlerts.getAlarmName(Number.NaN, "", now);
			 alertType = Database.getAlertType(alertName);
			 if (alertType != null && alertType.enabled) {
				 //first check if snoozeperiod is passed, checking first for value would generate multiple alarms in case the sensor is unstable
				 if ((now.valueOf() - _lowAlertLatestSnoozeTimeInMs) > _lowAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
					 ||
					 isNaN(_lowAlertLatestSnoozeTimeInMs)) {
					 myTrace("in checkAlarms, low alert not snoozed ");
					 //not snoozed
					 
					 var lastBgReading:BgReading = BgReading.lastNoSensor(); 
					 if (alertValue > lastBgReading.calculatedValue) {
						 myTrace("in checkAlarms, reading is too low");
						 fireAlert(
							 1,
							 alertType, 
							 NotificationService.ID_FOR_LOW_ALERT, 
							 ModelLocator.resourceManagerInstance.getString("alarmservice","low_alert_notification_alert_text"), 
							 alertType.enableVibration,
							 alertType.enableLights,
							 NotificationService.ID_FOR_ALERT_LOW_CATEGORY,
							 BgGraphBuilder.unitizedString(BgReading.lastNoSensor().calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") + " " + (lastBgReading.hideSlope ? "":(lastBgReading.slopeArrow())) + " " + BgGraphBuilder.unitizedDeltaString(true, true)
						 ); 
						 _lowAlertLatestSnoozeTimeInMs = Number.NaN;
						 LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_lowAlertLatestSnoozeTimeInMs));
						 _lowAlertSnoozePeriodInMinutes = 0;
						 LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_lowAlertSnoozePeriodInMinutes));
						 returnValue = true;
					 } else {
						 myTrace("cancel any existing alert for ID_FOR_LOW_ALERT");
						 Notifications.service.cancel(NotificationService.ID_FOR_LOW_ALERT);
						 disableRepeatAlert(1);
					 }
				 } else {
					 //snoozed no need to do anything
					 myTrace("in checkAlarms, alarm snoozed, _lowAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_lowAlertLatestSnoozeTimeInMs)) + ", _lowAlertSnoozePeriodInMinutes = " + _lowAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
				 }
			 } else {
				 //if not presnoozed, remove low notification, even if there isn't any
				 if (!_lowAlertPreSnoozed) {
					 resetLowAlert();
				 }
			 }
			 return returnValue;
		 }
		
		/**
		 * returns true of alarm fired or if snoozed
		 */private static function checkVeryLowAlert(now:Date):Boolean {
			 var listOfAlerts:FromtimeAndValueArrayCollection;
			 var alertValue:Number;
			 var alertName:String;
			 var alertType:AlertType;
			 var returnValue:Boolean = false;
			 
			 listOfAlerts = FromtimeAndValueArrayCollection.createList(
				 CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_VERY_LOW_ALERT), true);
			 alertValue = listOfAlerts.getValue(Number.NaN, "", now);
			 alertName = listOfAlerts.getAlarmName(Number.NaN, "", now);
			 alertType = Database.getAlertType(alertName);
			 if (alertType != null && alertType.enabled) {
				 //first check if snoozeperiod is passed, checking first for value would generate multiple alarms in case the sensor is unstable
				 if ((now.valueOf() - _veryLowAlertLatestSnoozeTimeInMs) > _veryLowAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
					 ||
					 isNaN(_veryLowAlertLatestSnoozeTimeInMs)) {
					 myTrace("in checkAlarms, veryLow alert not snoozed ");
					 //not snoozed
					 
					 var lastBgReading:BgReading = BgReading.lastNoSensor(); 
					 if (alertValue > lastBgReading.calculatedValue) {
						 myTrace("in checkAlarms, reading is too veryLow");
						 fireAlert(
							 2,
							 alertType, 
							 NotificationService.ID_FOR_VERY_LOW_ALERT, 
							 ModelLocator.resourceManagerInstance.getString("alarmservice","verylow_alert_notification_alert_text"), 
							 alertType.enableVibration,
							 alertType.enableLights,
							 NotificationService.ID_FOR_ALERT_VERY_LOW_CATEGORY,
							 BgGraphBuilder.unitizedString(BgReading.lastNoSensor().calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") + " " + (lastBgReading.hideSlope ? "":(lastBgReading.slopeArrow())) + " " + BgGraphBuilder.unitizedDeltaString(true, true)
						 ); 
						 _veryLowAlertLatestSnoozeTimeInMs = Number.NaN;
						 LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_veryLowAlertLatestSnoozeTimeInMs));
						 _veryLowAlertSnoozePeriodInMinutes = 0;
						 LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_veryLowAlertSnoozePeriodInMinutes));
						 returnValue = true;
					 } else {
						 myTrace("cancel any existing alert for ID_FOR_VERY_LOW_ALERT");
						 Notifications.service.cancel(NotificationService.ID_FOR_VERY_LOW_ALERT);
						 disableRepeatAlert(2);
					 }
				 } else {
					 //snoozed no need to do anything, set returnvalue to true because there's no need to further check
					 returnValue = true;
					 myTrace("in checkAlarms, alarm snoozed, _veryLowAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_veryLowAlertLatestSnoozeTimeInMs)) + ", _veryLowAlertSnoozePeriodInMinutes = " + _veryLowAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
				 }
			 } else {
				 //if not presnoozed then remove veryLow notification, even if there isn't any
				 if (!_veryLowAlertPreSnoozed) {
					 resetVeryLowAlert();
				 }
			 }
			 return returnValue;
		 }
		
		/**
		 * returns true of alarm fired or if snoozed
		 */
		private static function checkFastDropAlert(now:Date):Boolean {
			 var listOfAlerts:FromtimeAndValueArrayCollection;
			 var alertValue:Number;
			 var alertName:String;
			 var alertType:AlertType;
			 var returnValue:Boolean = false;
			 
			 listOfAlerts = FromtimeAndValueArrayCollection.createList(
				 CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_DROP_ALERT), true);
			 alertValue = listOfAlerts.getValue(Number.NaN, "", now);
			 alertName = listOfAlerts.getAlarmName(Number.NaN, "", now);
			 alertType = Database.getAlertType(alertName);
			 if (alertType != null && alertType.enabled) {
				 //first check if snoozeperiod is passed, checking first for value would generate multiple alarms in case the sensor is unstable
				 if ((now.valueOf() - _fastDropAlertLatestSnoozeTimeInMs) > _fastDropAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
					 ||
					 isNaN(_fastDropAlertLatestSnoozeTimeInMs)) {
					 myTrace("in checkAlarms, fastDrop alert not snoozed ");
					 //not snoozed
					 
					 var lastBgReading:BgReading = BgReading.lastNoSensor(); 
					 if (GlucoseHelper.isGlucoseChangingFast(alertValue, "down")) {
						 myTrace("in checkAlarms, glucose is dropping fast");
						 fireAlert(
							 9,
							 alertType, 
							 NotificationService.ID_FOR_FAST_DROP_ALERT, 
							 ModelLocator.resourceManagerInstance.getString("alarmservice","fast_drop_alert_notification_alert_text"), 
							 alertType.enableVibration,
							 alertType.enableLights,
							 NotificationService.ID_FOR_ALERT_FAST_DROP_CATEGORY,
							 BgGraphBuilder.unitizedString(BgReading.lastNoSensor().calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") + " " + (lastBgReading.hideSlope ? "":(lastBgReading.slopeArrow())) + " " + BgGraphBuilder.unitizedDeltaString(true, true)
						 ); 
						 _fastDropAlertLatestSnoozeTimeInMs = Number.NaN;
						 LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_fastDropAlertLatestSnoozeTimeInMs));
						 _fastDropAlertSnoozePeriodInMinutes = 0;
						 LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_fastDropAlertSnoozePeriodInMinutes));
						 returnValue = true;
					 } else {
						 myTrace("cancel any existing alert for ID_FOR_FAST_DROP_ALERT");
						 Notifications.service.cancel(NotificationService.ID_FOR_FAST_DROP_ALERT);
						 disableRepeatAlert(9);
					 }
				 } else {
					 //snoozed no need to do anything, set returnvalue to true because there's no need to further check
					 returnValue = true;
					 myTrace("in checkAlarms, alarm snoozed, _fastDropAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_fastDropAlertLatestSnoozeTimeInMs)) + ", _fastDropAlertSnoozePeriodInMinutes = " + _fastDropAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
				 }
			 } else {
				 //if not presnoozed then remove fastDrop notification, even if there isn't any
				 if (!_fastDropAlertPreSnoozed) {
					 resetFastDropAlert();
				 }
			 }
			 return returnValue;
		 }
		
		/**
		 * returns true of alarm fired or if snoozed
		 */private static function checkFastRiseAlert(now:Date):Boolean {
			 var listOfAlerts:FromtimeAndValueArrayCollection;
			 var alertValue:Number;
			 var alertName:String;
			 var alertType:AlertType;
			 var returnValue:Boolean = false;
			 
			 listOfAlerts = FromtimeAndValueArrayCollection.createList(
				 CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_RISE_ALERT), true);
			 alertValue = listOfAlerts.getValue(Number.NaN, "", now);
			 alertName = listOfAlerts.getAlarmName(Number.NaN, "", now);
			 alertType = Database.getAlertType(alertName);
			 if (alertType != null && alertType.enabled) {
				 //first check if snoozeperiod is passed, checking first for value would generate multiple alarms in case the sensor is unstable
				 if ((now.valueOf() - _fastRiseAlertLatestSnoozeTimeInMs) > _fastRiseAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE
					 ||
					 isNaN(_fastRiseAlertLatestSnoozeTimeInMs)) {
					 myTrace("in checkAlarms, fastRise alert not snoozed ");
					 //not snoozed
					 
					 var lastBgReading:BgReading = BgReading.lastNoSensor(); 
					 if (GlucoseHelper.isGlucoseChangingFast(alertValue, "up")) {
						 myTrace("in checkAlarms, glucose is rising fast");
						 fireAlert(
							 8,
							 alertType, 
							 NotificationService.ID_FOR_FAST_RISE_ALERT, 
							 ModelLocator.resourceManagerInstance.getString("alarmservice","fast_rise_alert_notification_alert_text"), 
							 alertType.enableVibration,
							 alertType.enableLights,
							 NotificationService.ID_FOR_ALERT_FAST_RISE_CATEGORY,
							 BgGraphBuilder.unitizedString(BgReading.lastNoSensor().calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") + " " + (lastBgReading.hideSlope ? "":(lastBgReading.slopeArrow())) + " " + BgGraphBuilder.unitizedDeltaString(true, true)
						 ); 
						 _fastRiseAlertLatestSnoozeTimeInMs = Number.NaN;
						 LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_fastRiseAlertLatestSnoozeTimeInMs));
						 _fastRiseAlertSnoozePeriodInMinutes = 0;
						 LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_fastRiseAlertSnoozePeriodInMinutes));
						 returnValue = true;
					 } else {
						 myTrace("cancel any existing alert for ID_FOR_FAST_RISE_ALERT");
						 Notifications.service.cancel(NotificationService.ID_FOR_FAST_RISE_ALERT);
						 disableRepeatAlert(8);
					 }
				 } else {
					 //snoozed no need to do anything, set returnvalue to true because there's no need to further check
					 returnValue = true;
					 myTrace("in checkAlarms, alarm snoozed, _fastRiseAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_fastRiseAlertLatestSnoozeTimeInMs)) + ", _fastRiseAlertSnoozePeriodInMinutes = " + _fastRiseAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
				 }
			 } else {
				 //if not presnoozed then remove fastDrop notification, even if there isn't any
				 if (!_fastRiseAlertPreSnoozed) {
					 resetFastRiseAlert();
				 }
			 }
			 return returnValue;
		 }
		
		public static function resetVeryHighAlert():void {
			myTrace("in resetVeryHighAlert");
			Notifications.service.cancel(NotificationService.ID_FOR_VERY_HIGH_ALERT);
			disableRepeatAlert(4);
			_veryHighAlertLatestSnoozeTimeInMs = Number.NaN;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_veryHighAlertLatestSnoozeTimeInMs));
			_veryHighAlertSnoozePeriodInMinutes = 0;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_veryHighAlertSnoozePeriodInMinutes));
			_veryHighAlertPreSnoozed = false;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_PRESNOOZED, String(_veryHighAlertPreSnoozed));
		}
		
		public static function resetVeryLowAlert():void {
			myTrace("in resetVeryLowAlert");
			Notifications.service.cancel(NotificationService.ID_FOR_VERY_LOW_ALERT);
			disableRepeatAlert(2);
			_veryLowAlertLatestSnoozeTimeInMs = Number.NaN;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_veryLowAlertLatestSnoozeTimeInMs));
			_veryLowAlertSnoozePeriodInMinutes = 0;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_veryLowAlertSnoozePeriodInMinutes));
			_veryLowAlertPreSnoozed = false;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_LOW_ALERT_PRESNOOZED, String(_veryLowAlertPreSnoozed));
		}
		
		public static function resetHighAlert():void {
			myTrace("in resetHighAlert");
			Notifications.service.cancel(NotificationService.ID_FOR_HIGH_ALERT);
			disableRepeatAlert(3);
			_highAlertLatestSnoozeTimeInMs = Number.NaN;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_highAlertLatestSnoozeTimeInMs));
			_highAlertSnoozePeriodInMinutes = 0;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_highAlertSnoozePeriodInMinutes));
			_highAlertPreSnoozed = false;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_PRESNOOZED, String(_highAlertPreSnoozed));
		}
		
		public static function resetLowAlert():void {
			myTrace("in resetLowAlert");
			Notifications.service.cancel(NotificationService.ID_FOR_LOW_ALERT);
			disableRepeatAlert(1);
			_lowAlertLatestSnoozeTimeInMs = Number.NaN;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_lowAlertLatestSnoozeTimeInMs));
			_lowAlertSnoozePeriodInMinutes = 0;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_lowAlertSnoozePeriodInMinutes));
			_lowAlertPreSnoozed = false;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_PRESNOOZED, String(_lowAlertPreSnoozed));
		}
		
		public static function resetMissedReadingAlert():void {
			myTrace("in resetMissedReadingAlert");
			Notifications.service.cancel(NotificationService.ID_FOR_MISSED_READING_ALERT);
			disableRepeatAlert(5);
			_missedReadingAlertLatestSnoozeTimeInMs = Number.NaN;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_missedReadingAlertLatestSnoozeTimeInMs));
			_missedReadingAlertSnoozePeriodInMinutes = 0;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_missedReadingAlertSnoozePeriodInMinutes));
			_missedReadingAlertPreSnoozed = false;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_PRESNOOZED, String(_missedReadingAlertPreSnoozed));
		}
		
		public static function resetPhoneMutedAlert():void {
			myTrace("in resetPhoneMutedAlert");
			Notifications.service.cancel(NotificationService.ID_FOR_PHONEMUTED_ALERT);
			disableRepeatAlert(7);
			_phoneMutedAlertLatestSnoozeTimeInMs = Number.NaN;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_phoneMutedAlertLatestSnoozeTimeInMs));
			_phoneMutedAlertSnoozePeriodInMinutes = 0;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_phoneMutedAlertSnoozePeriodInMinutes));
			_phoneMutedAlertPreSnoozed = false;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_PRESNOOZED, String(_phoneMutedAlertPreSnoozed));
		}
		
		public static function resetFastDropAlert():void {
			myTrace("in resetFastDropAlert");
			Notifications.service.cancel(NotificationService.ID_FOR_FAST_DROP_ALERT);
			disableRepeatAlert(9);
			_fastDropAlertLatestSnoozeTimeInMs = Number.NaN;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_fastDropAlertLatestSnoozeTimeInMs));
			_fastDropAlertSnoozePeriodInMinutes = 0;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_fastDropAlertSnoozePeriodInMinutes));
			_fastDropAlertPreSnoozed = false;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_PRESNOOZED, String(_fastDropAlertPreSnoozed));
		}
		
		public static function resetFastRiseAlert():void {
			myTrace("in resetFastRiseAlert");
			Notifications.service.cancel(NotificationService.ID_FOR_FAST_RISE_ALERT);
			disableRepeatAlert(8);
			_fastRiseAlertLatestSnoozeTimeInMs = Number.NaN;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_LATEST_SNOOZE_TIME_IN_MS, String(_fastRiseAlertLatestSnoozeTimeInMs));
			_fastRiseAlertSnoozePeriodInMinutes = 0;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_SNOOZE_PERIOD_IN_MINUTES, String(_fastRiseAlertSnoozePeriodInMinutes));
			_fastRiseAlertPreSnoozed = false;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_PRESNOOZED, String(_fastRiseAlertPreSnoozed));
		}
		
		private static function localSettingChanged(event:SettingsServiceEvent):void {
			/*if (event.data == LocalSettings.LOCAL_SETTING_APP_INACTIVE_ALERT || event.data == CommonSettings.COMMON_SETTING_LANGUAGE) {
			//if user changes language, alert needs to be replanned because notification text may have changed
			Notifications.service.cancel(NotificationService.ID_FOR_APPLICATION_INACTIVE_ALERT);
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_INACTIVE_ALERT) == "true") {
			planApplicationStoppedAlert();
			lastApplicationStoppedAlertCheckTimeStamp = (new Date()).valueOf();
			} else {
			lastApplicationStoppedAlertCheckTimeStamp = 0;
			}
			}*/
			
			if (event.data == LocalSettings.LOCAL_SETTING_APP_INACTIVE_ALERT) 
			{
				if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_INACTIVE_ALERT) == "true" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) != "") 
					planApplicationStoppedAlert();
				else 
					cancelInactiveAlert();
			}
		}
		
		private static function commonSettingChanged(event:SettingsServiceEvent):void {
			if (event.data == CommonSettings.COMMON_SETTING_CURRENT_SENSOR) {
				checkMissedReadingAlert();
				//need to plan missed reading alert
				//in case user has started, stopped a sensor
				//    if It was a sensor stop, then the setting COMMON_SETTING_CURRENT_SENSOR has value "0", and in checkMissedReadingAlert, the alert will be canceled and not replanned
			} else if (event.data == CommonSettings.COMMON_SETTING_CALIBRATION_REQUEST_ALERT) {
				checkCalibrationRequestAlert(new Date());
			} 
			else if (event.data == CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) 
			{
				if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_INACTIVE_ALERT) == "true" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) != "") 
					planApplicationStoppedAlert();
				else 
					cancelInactiveAlert();
			} 
			
			if ((event.data >= CommonSettings.COMMON_SETTING_LOW_ALERT && event.data <= CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT) 
				||
				(event.data >= CommonSettings.COMMON_SETTING_BATTERY_ALERT && event.data <= CommonSettings.COMMON_SETTING_VERY_HIGH_ALERT)
				||
				event.data == CommonSettings.COMMON_SETTING_FAST_DROP_ALERT
				||
				event.data == CommonSettings.COMMON_SETTING_FAST_RISE_ALERT
			) {
				var listOfAlerts:FromtimeAndValueArrayCollection = FromtimeAndValueArrayCollection.createList(
					CommonSettings.getCommonSetting(event.data), false);
				var alertName:String = listOfAlerts.getAlarmName(Number.NaN, "", new Date());
				var alertType:AlertType = Database.getAlertType(alertName);
				if (alertType != null && !alertType.enabled) {
					switch (event.data as int) {
						case CommonSettings.COMMON_SETTING_CALIBRATION_REQUEST_ALERT:
							disableRepeatAlert(0);
							break;
						case CommonSettings.COMMON_SETTING_LOW_ALERT:
							disableRepeatAlert(1);
							break;
						case CommonSettings.COMMON_SETTING_VERY_LOW_ALERT:
							disableRepeatAlert(2);
							break;
						case CommonSettings.COMMON_SETTING_HIGH_ALERT:
							disableRepeatAlert(3);
							break;
						case CommonSettings.COMMON_SETTING_VERY_HIGH_ALERT:
							disableRepeatAlert(4);
							break;
						case CommonSettings.COMMON_SETTING_MISSED_READING_ALERT:
							disableRepeatAlert(5);
							break;
						case CommonSettings.COMMON_SETTING_BATTERY_ALERT:
							disableRepeatAlert(6);
							break;
						case CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT:
							disableRepeatAlert(7);
							break;
						case CommonSettings.COMMON_SETTING_FAST_RISE_ALERT:
							disableRepeatAlert(8);
							break;
						case CommonSettings.COMMON_SETTING_FAST_DROP_ALERT:
							disableRepeatAlert(9);
							break;
					}
				}
			}
		}
		
		/**
		 * repeatAlert variables are used for repeating alerts<br><br>
		 * sets variables repeatAlertsArray, repeatAlertsLastFireTimeStampArray, repeatAlertsAlertTypeNameArray ...<br>
		 * <br>
		 * the function setrepeatAlert will set a specific alert (repeatAlertsArray), with alerttypename (repeatAlertsAlertTypeNameArray) and firedate (repeatAlertsLastFireTimeStampArray) which will be 
		 * the curren date and time<br><br>
		 * Every minute a check will be done to see if the alert needs to be repeated, based on lastfiredate and repeat setting for the alerttype<br>
		 * <br>
		 * id ==> 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted<br>
		 * <br>
		 * repeatCntr > 0 if this is a repeat
		 */
		private static function enableRepeatAlert(id:int, alertTypeName:String, alertText:String, bodyText:String, repeatCntr:int = 0):void {
			activeAlertsArray[id] = true;
			repeatAlertsAlertTypeNameArray[id] = alertTypeName;
			repeatAlertsLastFireTimeStampArray[id] = (new Date()).valueOf();
			repeatAlertsTexts[id] = alertText;
			repeatAlertsRepeatCount[id] = repeatCntr;
			repeatAlertsBodies[id] = bodyText;
		}
		
		/**
		 * disables an active alert. More explanation see enablerepeatAlert<br>
		 * id ==> 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted<br
		 */
		private static function disableRepeatAlert(id:int):void {
			activeAlertsArray[id] = false;
			repeatAlertsAlertTypeNameArray[id] = "";
			repeatAlertsLastFireTimeStampArray[id] = 0;
			repeatAlertsTexts[id] = "";
			repeatAlertsRepeatCount[id] = 0;
			repeatAlertsBodies[id] = "";
		}
		
		/**
		 * check if alerts need to be repeated<br>
		 * low/very low , high/very high : check will be done a number of repeats, if max reached then reset to false
		 */
		private static function repeatAlerts():void {
			//id ==> 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted, 8:Fast Rise, 9:Fast Drop<br
			if (activeAlertsArray == null || repeatAlertsLastFireTimeStampArray == null) return;
			for (var cntr:int = 0;cntr < activeAlertsArray.length;cntr++) {
				if (activeAlertsArray[cntr] == true) {
					if ((new Date()).valueOf() - repeatAlertsLastFireTimeStampArray[cntr] > TimeSpan.TIME_1_MINUTE) {
						var alertType:AlertType = Database.getAlertType(repeatAlertsAlertTypeNameArray[cntr]);
						if (alertType == null) continue;
						if (alertType.repeatInMinutes > 0) {
							Notifications.service.cancel(repeatAlertsNotificationIds[cntr]);//remove any notification that may already exist
							
							//remove also any open pickerdialog
							SystemUtil.executeWhenApplicationIsActive( AlarmSnoozer.closeCallout );
							
							//fire the alert again
							fireAlert(
								cntr,
								alertType, 
								repeatAlertsNotificationIds[cntr], 
								repeatAlertsTexts[cntr], 
								alertType.enableVibration, 
								alertType.enableLights, 
								repeatAlertsCategoryIds[cntr],
								repeatAlertsBodies[cntr]);
							enableRepeatAlert(cntr, repeatAlertsAlertTypeNameArray[cntr], repeatAlertsTexts[cntr], repeatAlertsBodies[cntr], repeatAlertsRepeatCount[cntr] + 1);
							
							//if it's a low, very low, high, very high alert, fast rise or fast drop, 
							if (cntr == 1 || cntr == 2 || cntr == 3 || cntr == 4 || cntr == 8 || cntr == 9) {
								if (repeatAlertsRepeatCount[cntr] > MAX_REPEATS_FOR_ALERTS) {
									disableRepeatAlert(cntr);
								}
							}
						}
						
					}
				}
			}
		}
		
		private static function appInForeGround(event:flash.events.Event):void {
			//check if there's active notification alert, 
			for (var cntr:int = 0;cntr < activeAlertsArray.length;cntr++) {
				if (activeAlertsArray[cntr] == true) {
					if ((new Date()).valueOf() - repeatAlertsLastFireTimeStampArray[cntr] < TimeSpan.TIME_31_SECONDS) {
						myTrace("in appInForeGround, found active alert with id " + repeatAlertsNotificationIds[cntr]);
						//user brings the app from back to foreground within 30 seconds after firing the alert
						//Stop playing sound, this will not be done by calling notificationReceived
						SpikeANE.stopPlayingSound();
						
						//simulating as if the app was opened by clicking a notification
						var notificationServiceEvent:NotificationServiceEvent = new NotificationServiceEvent(NotificationServiceEvent.NOTIFICATION_EVENT);
						notificationServiceEvent.data = new NotificationEvent("notification:notification:selected", repeatAlertsNotificationIds[cntr], "", "inactive", false, null, (new Date()).valueOf(), false, false);
						notificationReceived(notificationServiceEvent);
						
						//user opened the app within 30 seconds after the alarm was raised, most likely the user opened the app with the aim to snooze the alert
						//and the user will get the snooze popup, so there's no need to repeat the alert
						disableRepeatAlert(cntr);
					}
					
				}
			}
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("AlarmService.as", log);
		}
		
		/**
		 * snoozeTimeInMs = timestamp alert was snoozed, snoozePeriodInMinutes = snoozeperiod in minutes<br>
		 * returns time alert is still snoozed in format like "1 hours 3 minutes"<br
		 * <br>
		 * If alarm not snoozed anymore, returnvalue = "not snoozed"<br>
		 * If snoozePeriodInMinutes or snoozeTimeInMs isNaN, returnvalue = "not snoozed"
		 */
		private static function snoozeUntilAsString(snoozePeriodInMinutes:int, snoozeTimeInMs:Number):String {
			if (isNaN(snoozePeriodInMinutes) || isNaN(snoozeTimeInMs)) 
				return "not snoozed";
			var remainingSnoozeMinutes:int;
			var remainingSnoozeHours:int;
			var remainingSnoozeDays:int;
			var now:Number = (new Date()).valueOf();
			var snoozedUntil:Number = snoozeTimeInMs + snoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			if (now >= snoozedUntil) {
				return "not snoozed";
			}
			if (snoozedUntil - now < TimeSpan.TIME_1_HOUR) {//less than 1 hour
				remainingSnoozeMinutes = (snoozedUntil - now)/1000/60;
				return remainingSnoozeMinutes + " " + ModelLocator.resourceManagerInstance.getString("alarmservice","minutes");
			}
			if (snoozedUntil - now < TimeSpan.TIME_24_HOURS) {//less than 1 day
				remainingSnoozeHours =  (snoozedUntil - now)/1000/60/60;
				remainingSnoozeMinutes =  (snoozedUntil - now - remainingSnoozeHours * TimeSpan.TIME_1_HOUR)/1000/60;
				return remainingSnoozeHours + " " + ModelLocator.resourceManagerInstance.getString("alarmservice","hours")
					+ ", " + remainingSnoozeMinutes  + " " + ModelLocator.resourceManagerInstance.getString("alarmservice","minutes");
			}
			remainingSnoozeDays =  (snoozedUntil - now)/1000/60/60/24;
			remainingSnoozeHours =  (snoozedUntil - remainingSnoozeDays * TimeSpan.TIME_24_HOURS - now)/1000/60/60;
			remainingSnoozeMinutes = (snoozedUntil - remainingSnoozeDays * TimeSpan.TIME_24_HOURS - remainingSnoozeHours * TimeSpan.TIME_1_HOUR - now)/1000/60;
			return remainingSnoozeDays + " " + ModelLocator.resourceManagerInstance.getString("alarmservice","days") + ", " +
				+ remainingSnoozeHours + " " + ModelLocator.resourceManagerInstance.getString("alarmservice","hours")
				+ ", " + remainingSnoozeMinutes  + " " + ModelLocator.resourceManagerInstance.getString("alarmservice","minutes");
		}
		
		public static function veryLowAlertSnoozeAsString():String {
			return snoozeUntilAsString(_veryLowAlertSnoozePeriodInMinutes, _veryLowAlertLatestSnoozeTimeInMs);
		}
		
		public static function lowAlertSnoozeAsString():String {
			return snoozeUntilAsString(_lowAlertSnoozePeriodInMinutes, _lowAlertLatestSnoozeTimeInMs);
		}
		
		public static function highAlertSnoozeAsString():String {
			return snoozeUntilAsString(_highAlertSnoozePeriodInMinutes, _highAlertLatestSnoozeTimeInMs);
		}
		
		public static function veryHighAlertSnoozeAsString():String {
			return snoozeUntilAsString(_veryHighAlertSnoozePeriodInMinutes, _veryHighAlertLatestSnoozeTimeInMs);
		}
		
		public static function phoneMutedAlertSnoozeAsString():String {
			return snoozeUntilAsString(_phoneMutedAlertSnoozePeriodInMinutes, _phoneMutedAlertLatestSnoozeTimeInMs);
		}
		
		public static function missedReadingAlertSnoozeAsString():String {
			return snoozeUntilAsString(_missedReadingAlertSnoozePeriodInMinutes, _missedReadingAlertLatestSnoozeTimeInMs);
		}
		
		public static function fastRiseAlertSnoozeAsString():String {
			return snoozeUntilAsString(_fastRiseAlertSnoozePeriodInMinutes, _fastRiseAlertLatestSnoozeTimeInMs);
		}
		
		public static function fastDropAlertSnoozeAsString():String {
			return snoozeUntilAsString(_fastDropAlertSnoozePeriodInMinutes, _fastDropAlertLatestSnoozeTimeInMs);
		}
		
		public static function veryLowAlertSnoozed():Boolean 
		{
			var returnValue:Boolean = true;
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _veryLowAlertLatestSnoozeTimeInMs + _veryLowAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_veryLowAlertLatestSnoozeTimeInMs))
				returnValue = false;
			
			return returnValue;
		}
		public static function lowAlertSnoozed():Boolean 
		{
			var returnValue:Boolean = true;
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _lowAlertLatestSnoozeTimeInMs + _lowAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_lowAlertLatestSnoozeTimeInMs))
				returnValue = false;
			
			return returnValue;
		}
		public static function highAlertSnoozed():Boolean 
		{
			var returnValue:Boolean = true;
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _highAlertLatestSnoozeTimeInMs + _highAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_highAlertLatestSnoozeTimeInMs))
				returnValue = false;
			
			return returnValue;
		}
		public static function veryHighAlertSnoozed():Boolean 
		{
			var returnValue:Boolean = true;
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _veryHighAlertLatestSnoozeTimeInMs + _veryHighAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_veryHighAlertLatestSnoozeTimeInMs))
				returnValue = false;
			
			return returnValue;
		}
		public static function missedReadingAlertSnoozed():Boolean 
		{
			var returnValue:Boolean = true;
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _missedReadingAlertLatestSnoozeTimeInMs + _missedReadingAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_missedReadingAlertLatestSnoozeTimeInMs))
				returnValue = false;
			
			return returnValue;
		}
		public static function phoneMutedAlertSnoozed():Boolean 
		{
			var returnValue:Boolean = true;
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _phoneMutedAlertLatestSnoozeTimeInMs + _phoneMutedAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_phoneMutedAlertLatestSnoozeTimeInMs))
				returnValue = false;
			
			return returnValue;
		}
		public static function fastRiseAlertSnoozed():Boolean 
		{
			var returnValue:Boolean = true;
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _fastRiseAlertLatestSnoozeTimeInMs + _fastRiseAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_fastRiseAlertLatestSnoozeTimeInMs))
				returnValue = false;
			
			return returnValue;
		}
		public static function fastDropAlertSnoozed():Boolean 
		{
			var returnValue:Boolean = true;
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _fastDropAlertLatestSnoozeTimeInMs + _fastDropAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_fastDropAlertLatestSnoozeTimeInMs))
				returnValue = false;
			
			return returnValue;
		}
		
		private static function resetVeryLowAlertPreSnooze():void {
			_veryLowAlertPreSnoozed = false;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_LOW_ALERT_PRESNOOZED, String(_veryLowAlertPreSnoozed), true, false);
		}
		private static function resetLowAlertPreSnooze():void {
			_lowAlertPreSnoozed = false;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LOW_ALERT_PRESNOOZED, String(_lowAlertPreSnoozed), true, false);
		}
		private static function resetVeryHighAlertPreSnooze():void {
			_veryHighAlertPreSnoozed = false;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_VERY_HIGH_ALERT_PRESNOOZED, String(_veryHighAlertPreSnoozed), true, false);
		}
		private static function resetHighAlertPreSnooze():void {
			_highAlertPreSnoozed = false;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_HIGH_ALERT_PRESNOOZED, String(_highAlertPreSnoozed), true, false);
		}
		private static function resetMissedreadingAlertPreSnooze():void {
			_missedReadingAlertPreSnoozed = false;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_MISSED_READINGS_ALERT_PRESNOOZED, String(_missedReadingAlertPreSnoozed), true, false);
		}
		private static function resetPhoneMutedAlertPreSnooze():void {
			_phoneMutedAlertPreSnoozed = false;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_PHONE_MUTED_ALERT_PRESNOOZED, String(_phoneMutedAlertPreSnoozed), true, false);
		}
		private static function resetFastDropAlertPreSnooze():void {
			_fastDropAlertPreSnoozed = false;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_DROP_ALERT_PRESNOOZED, String(_fastDropAlertPreSnoozed), true, false);
		}
		private static function resetFastRiseAlertPreSnooze():void {
			_fastRiseAlertPreSnoozed = false;
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_FAST_RISE_ALERT_PRESNOOZED, String(_fastRiseAlertPreSnoozed), true, false);
		}
		
		public static function veryLowAlertSnoozedUntilTimestamp():Number 
		{
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _veryLowAlertLatestSnoozeTimeInMs + _veryLowAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_veryLowAlertLatestSnoozeTimeInMs))
				snoozedUntil = 0;
			
			return snoozedUntil;
		}
		
		public static function lowAlertSnoozedUntilTimestamp():Number 
		{
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _lowAlertLatestSnoozeTimeInMs + _lowAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_lowAlertLatestSnoozeTimeInMs))
				snoozedUntil = 0;
			
			return snoozedUntil;
		}
		
		public static function highAlertSnoozedUntilTimestamp():Number 
		{
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _highAlertLatestSnoozeTimeInMs + _highAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_highAlertLatestSnoozeTimeInMs))
				snoozedUntil = 0;
			
			return snoozedUntil;
		}
		
		public static function veryHighAlertSnoozedUntilTimestamp():Number 
		{
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _veryHighAlertLatestSnoozeTimeInMs + _veryHighAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_veryHighAlertLatestSnoozeTimeInMs))
				snoozedUntil = 0;
			
			return snoozedUntil;
		}
		
		public static function missedReadingAlertSnoozedUntilTimestamp():Number 
		{
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _missedReadingAlertLatestSnoozeTimeInMs + _missedReadingAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_missedReadingAlertLatestSnoozeTimeInMs))
				snoozedUntil = 0;
			
			return snoozedUntil;
		}
		
		public static function phoneMutedAlertSnoozedUntilTimestamp():Number 
		{
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _phoneMutedAlertLatestSnoozeTimeInMs + _phoneMutedAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_phoneMutedAlertLatestSnoozeTimeInMs))
				snoozedUntil = 0;
			
			return snoozedUntil;
		}
		
		public static function fastRiseAlertSnoozedUntilTimestamp():Number 
		{
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _fastRiseAlertLatestSnoozeTimeInMs + _fastRiseAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_fastRiseAlertLatestSnoozeTimeInMs))
				snoozedUntil = 0;
			
			return snoozedUntil;
		}
		
		public static function fastDropAlertSnoozedUntilTimestamp():Number 
		{
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _fastDropAlertLatestSnoozeTimeInMs + _fastDropAlertSnoozePeriodInMinutes * TimeSpan.TIME_1_MINUTE;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_fastDropAlertLatestSnoozeTimeInMs))
				snoozedUntil = 0;
			
			return snoozedUntil;
		}
		
		/**
		 * Stops the service entirely. Useful for database restores
		 */
		private static function onHaltExecution(e:SpikeEvent):void
		{
			myTrace("Stopping service...");
			
			stopService();
		}
		
		private static function stopService():void
		{
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, checkAlarms);
			NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, checkAlarms);
			DexcomShareService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, checkAlarms);
			NotificationService.instance.removeEventListener(NotificationServiceEvent.NOTIFICATION_EVENT, notificationReceived);
			NotificationService.instance.removeEventListener(NotificationServiceEvent.NOTIFICATION_ACTION_EVENT, notificationReceived);
			SpikeANE.instance.removeEventListener(SpikeANEEvent.PHONE_MUTED, phoneMuted);
			SpikeANE.instance.removeEventListener(SpikeANEEvent.PHONE_NOT_MUTED, phoneNotMuted);
			CommonSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, commonSettingChanged);
			LocalSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, localSettingChanged);
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_FOREGROUND, appInForeGround);
			
			if (alarmTimer != null && alarmTimer.running)
			{
				alarmTimer.removeEventListener(TimerEvent.TIMER, onAlarmTimer);
				alarmTimer.stop();
			}
			
			myTrace("Service stopped!");
		}
	}
}
