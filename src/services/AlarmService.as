package services
{
	import com.distriqt.extension.notifications.Notifications;
	import com.distriqt.extension.notifications.builders.NotificationBuilder;
	import com.distriqt.extension.notifications.events.NotificationEvent;
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetchEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.utils.StringUtil;
	
	import database.AlertType;
	import database.BgReading;
	import database.BlueToothDevice;
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
	
	import starling.events.Event;
	
	import ui.popups.AlarmSnoozer;
	
	import utils.BadgeBuilder;
	import utils.BgGraphBuilder;
	import utils.DateTimeUtilities;
	import utils.FromtimeAndValueArrayCollection;
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
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted<br>
		 * true means alert is active, repeat check is necessary (not necessarily repeat, that depends on the setting in the alert type)<br>
		 * also used to check if an alert is active when the notification is coming from back to foreground<br>
		 */
		private static var activeAlertsArray:Array = [false,false,false,false,false,false,false,false,false];
		/**
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted<br>
		 * last timestamp the alert was fired
		 */
		private static var repeatAlertsLastFireTimeStampArray:Array = [0,0,0,0,0,0,0,0,0];
		/**
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted<br>
		 * the name of the alert type to be used when repeating the alert, and also to check if it needs to be repeated
		 */
		private static var repeatAlertsAlertTypeNameArray:Array = ["","","","","","","","",""];
		/**
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted<br>
		 * alert texts for the alert
		 */
		private static var repeatAlertsTexts:Array = ["","","","","","","","",""];
		/**
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted<br>
		 * body texts for the alert
		 */
		private static var repeatAlertsBodies:Array = ["","","","","","","","",""];
		/**
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted<br>
		 * how many times repeated
		 */
		private static var repeatAlertsRepeatCount:Array = [1, 1, 1, 1, 1, 1, 1, 1, 1];
		/**
		 * list of notification ids<br>
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted<br>
		 */
		private static const repeatAlertsNotificationIds:Array = [
			NotificationService.ID_FOR_CALIBRATION_REQUEST_ALERT,
			NotificationService.ID_FOR_LOW_ALERT,
			NotificationService.ID_FOR_VERY_LOW_ALERT,
			NotificationService.ID_FOR_HIGH_ALERT,
			NotificationService.ID_FOR_VERY_HIGH_ALERT,
			NotificationService.ID_FOR_MISSED_READING_ALERT,
			NotificationService.ID_FOR_BATTERY_ALERT,
			NotificationService.ID_FOR_PHONEMUTED_ALERT];
		/**
		 * list of category ids<br>
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted<br>
		 */
		private static const repeatAlertsCategoryIds:Array = [
			NotificationService.ID_FOR_ALERT_CALIBRATION_REQUEST_CATEGORY,
			NotificationService.ID_FOR_ALERT_LOW_CATEGORY,
			NotificationService.ID_FOR_ALERT_VERY_LOW_CATEGORY,
			NotificationService.ID_FOR_ALERT_HIGH_CATEGORY,
			NotificationService.ID_FOR_ALERT_VERY_HIGH_CATEGORY,
			NotificationService.ID_FOR_ALERT_MISSED_READING_CATEGORY,
			NotificationService.ID_FOR_ALERT_BATTERY_CATEGORY,
			NotificationService.ID_FOR_PHONE_MUTED_CATEGORY];
		
		private static var alarmTimer:Timer;
		
		private static var soundsAsDisplayed:String;
		private static var soundsAsStoredInAssets:String;
		private static var soundsAsDisplayedSplitted:Array;
		private static var soundsAsStoredInAssetsSplitted:Array;
		
		private static var queuedAlertSound:String = "";
		private static var lastQueuedAlertSoundTimeStamp:Number = 0;
		
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
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, checkAlarms);
			NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, checkAlarms);
			
			//listen to NOTIFICATION_EVENT. This even is received only if the app is in the foreground. The function notificationReceived will shows the snooze dialog
			NotificationService.instance.addEventListener(NotificationServiceEvent.NOTIFICATION_EVENT, notificationReceived);
			//listen to NOTIFICATION_ACTION_EVENT. This even is received if the user selected an action, ie if an alert was snoozed
			NotificationService.instance.addEventListener(NotificationServiceEvent.NOTIFICATION_ACTION_EVENT, notificationReceived);
			//not interested in NOTIFICATION_SELECTED_EVENT, because NOTIFICATION_SELECTED_EVENT is only received while the app is in the background and being braught to the
			//foreground because the user selects a notification. But in that case, in function appInForeGround, the notificationReceived function will also be called.
			
			BackgroundFetch.instance.addEventListener(BackgroundFetchEvent.PHONE_MUTED, phoneMuted);
			BackgroundFetch.instance.addEventListener(BackgroundFetchEvent.PHONE_NOT_MUTED, phoneNotMuted);
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, commonSettingChanged);
			LocalSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, localSettingChanged);
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, appInForeGround);
			lastAlarmCheckTimeStamp = 0;
			lastMissedReadingAlertCheckTimeStamp = 0;
			lastApplicationStoppedAlertCheckTimeStamp = 0;
			
			for (var cntr:int = 0;cntr < snoozeValueMinutes.length;cntr++) {
				snoozeValueStrings[cntr] = (snoozeValueStrings[cntr] as String).replace("minutes", ModelLocator.resourceManagerInstance.getString("alarmservice","minutes"));
				snoozeValueStrings[cntr] = (snoozeValueStrings[cntr] as String).replace("hour", ModelLocator.resourceManagerInstance.getString("alarmservice","hour"));
				snoozeValueStrings[cntr] = (snoozeValueStrings[cntr] as String).replace("hours", ModelLocator.resourceManagerInstance.getString("alarmservice","hours"));
				snoozeValueStrings[cntr] = (snoozeValueStrings[cntr] as String).replace("day", ModelLocator.resourceManagerInstance.getString("alarmservice","day"));
				snoozeValueStrings[cntr] = (snoozeValueStrings[cntr] as String).replace("week", ModelLocator.resourceManagerInstance.getString("alarmservice","week"));
			}
			
			setTimer();
			
			checkMuted(null);
			Notifications.service.cancel(NotificationService.ID_FOR_APPLICATION_INACTIVE_ALERT);
			
			soundsAsDisplayed = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","alert_sounds_names");
			soundsAsStoredInAssets = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","alert_sounds_files");
			soundsAsDisplayedSplitted = soundsAsDisplayed.split(',');
			soundsAsStoredInAssetsSplitted = soundsAsStoredInAssets.split(',');
			
			/*soundsAsDisplayed = ModelLocator.resourceManagerInstance.getString("alerttypeview","sound_names_as_displayed_can_be_translated_must_match_above_list");
			soundsAsStoredInAssets = ModelLocator.resourceManagerInstance.getString("alerttypeview","sound_names_as_in_assets_no_translation_needed_comma_seperated");
			soundsAsDisplayedSplitted = soundsAsDisplayed.split(',');
			soundsAsStoredInAssetsSplitted = soundsAsStoredInAssets.split(',');*/
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
			if (((new Date()).valueOf() - lastMissedReadingAlertCheckTimeStamp)/1000 > 5 * 60 + 30) {
				myTrace("in onAlarmTimer, calling checkMissedReadingAlert");
				checkMissedReadingAlert();
			}
			checkMuted(null);
			repeatAlerts();
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_INACTIVE_ALERT) == "true") 
			{
				//if (((new Date()).valueOf() - lastApplicationStoppedAlertCheckTimeStamp) > 10 * 60 * 1000) 
				//{
					myTrace("in onAlarmTimer, calling planApplicationStoppedAlert");
					planApplicationStoppedAlert();
					lastApplicationStoppedAlertCheckTimeStamp = (new Date()).valueOf();
				//}
			}
		}
		
		private static function checkMuted(event:flash.events.Event):void {
			var nowDate:Date = new Date();
			var nowNumber:Number = nowDate.valueOf();
			if ((nowNumber - _phoneMutedAlertLatestSnoozeTimeInMs) > _phoneMutedAlertSnoozePeriodInMinutes * 60 * 1000
				||
				isNaN(_phoneMutedAlertLatestSnoozeTimeInMs)) {
				//alert not snoozed
				if (nowNumber - lastCheckMuteTimeStamp > (4 * 60 + 45) * 1000) {
					//more than 4 min 45 seconds ago since last check
					var listOfAlerts:FromtimeAndValueArrayCollection = FromtimeAndValueArrayCollection.createList(
						CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT), false);
					var alertName:String = listOfAlerts.getAlarmName(Number.NaN, "", nowDate);
					var alertType:AlertType = Database.getAlertType(alertName);
					if (alertType.enabled || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_ON) == "true") {
						//alert enabled or speak readings is on 
						myTrace("in checkMuted, calling BackgroundFetch.checkMuted");
						BackgroundFetch.checkMuted();
					}
					lastCheckMuteTimeStamp = nowNumber;
				}
			}
		}
		
		private static function notificationReceived(event:NotificationServiceEvent):void {
			myTrace("in notificationReceived");
			if (BackgroundFetch.appIsInBackground()) {
				//app is in background, which means the notification was received because the user clicked the notification action, typically "snooze"
				//  so stop the playing
				BackgroundFetch.stopPlayingSound();
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
				if (notificationEvent.id == NotificationService.ID_FOR_LOW_ALERT) {
					if (BackgroundFetch.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(1);
					}
					
					if ((now.valueOf() - _lowAlertLatestSnoozeTimeInMs) > _lowAlertSnoozePeriodInMinutes * 60 * 1000
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
					if (BackgroundFetch.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(3);
					}
					
					if ((now.valueOf() - _highAlertLatestSnoozeTimeInMs) > _highAlertSnoozePeriodInMinutes * 60 * 1000
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
					if (BackgroundFetch.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(2);
					}
					
					if ((now.valueOf() - _veryLowAlertLatestSnoozeTimeInMs) > _veryLowAlertSnoozePeriodInMinutes * 60 * 1000
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
					if (BackgroundFetch.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(4);
					}
					
					if ((now.valueOf() - _veryHighAlertLatestSnoozeTimeInMs) > _veryHighAlertSnoozePeriodInMinutes * 60 * 1000
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
					if (BackgroundFetch.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
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
					if (BackgroundFetch.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(7);
					}
					
					if ((now.valueOf() - _phoneMutedAlertLatestSnoozeTimeInMs) > _phoneMutedAlertSnoozePeriodInMinutes * 60 * 1000
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
					if (BackgroundFetch.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(6);
					}
					
					if ((now.valueOf() - _batteryLevelAlertLatestSnoozeTimeInMs) > _batteryLevelAlertSnoozePeriodInMinutes * 60 * 1000
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
							AlarmSnoozer.displaySnoozer(ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_battery_alert"), snoozeValueStrings, index);
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
					if (BackgroundFetch.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(0);
					}
					
					if ((now.valueOf() - _calibrationRequestLatestSnoozeTimeInMs) > _calibrationRequestSnoozePeriodInMinutes * 60 * 1000
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
							CalibrationService.calibrationOnRequest(false, false, true, snoozeCalibrationRequest);
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
				AlarmSnoozer.displaySnoozer(ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_calibration_alert"), snoozeValueStrings, index);
			}
			
			function calibrationRequestSnoozePicker_closedHandler(event:starling.events.Event): void {
				BackgroundFetch.stopPlayingSound();
				myTrace("in calibrationRequestSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				disableRepeatAlert(0);
				_calibrationRequestSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_calibrationRequestLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
			
			function batteryLevelSnoozePicker_closedHandler(event:starling.events.Event): void {
				BackgroundFetch.stopPlayingSound();
				myTrace("in batteryLevelSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				disableRepeatAlert(6);
				_batteryLevelAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_batteryLevelAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
			
			function phoneMutedSnoozePicker_closedHandler(event:starling.events.Event): void {
				BackgroundFetch.stopPlayingSound();
				myTrace("in phoneMutedSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				disableRepeatAlert(7);
				_phoneMutedAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_phoneMutedAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
			
			function missedReadingSnoozePicker_closedHandler(event:starling.events.Event): void {
				BackgroundFetch.stopPlayingSound();
				myTrace("in phoneMutedSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				disableRepeatAlert(5);
				_missedReadingAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_missedReadingAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
			
			function lowSnoozePicker_closedHandler(event:starling.events.Event): void {
				myTrace("in lowSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				disableRepeatAlert(1);
				BackgroundFetch.stopPlayingSound();
				_lowAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_lowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
			
			function highSnoozePicker_closedHandler(event:starling.events.Event): void {
				myTrace("in highSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				disableRepeatAlert(3);
				BackgroundFetch.stopPlayingSound();
				_highAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_highAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
			
			function veryHighSnoozePicker_closedHandler(event:starling.events.Event): void {
				myTrace("in veryHighSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				disableRepeatAlert(4);
				BackgroundFetch.stopPlayingSound();
				_veryHighAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_veryHighAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
		}
		
		private static function snoozePickerChangedOrCanceledHandler(event:starling.events.Event): void {
			BackgroundFetch.stopPlayingSound();
		}
		
		public static function snoozeLowAlert(index:int):void {
			myTrace("in snoozeLowAlert. Snoozing for " + snoozeValueMinutes[index] + " minutes");
			_lowAlertPreSnoozed = true;
			Notifications.service.cancel(NotificationService.ID_FOR_LOW_ALERT);
			resetLowAlertPreSnooze();
			disableRepeatAlert(1);
			BackgroundFetch.stopPlayingSound();
			_lowAlertSnoozePeriodInMinutes = snoozeValueMinutes[index];
			_lowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
		}
		
		public static function snoozeVeyLowAlert(index:int):void {
			myTrace("in snoozeVeyLowAlert. Snoozing for " + snoozeValueMinutes[index] + " minutes");
			_veryLowAlertPreSnoozed = true;
			Notifications.service.cancel(NotificationService.ID_FOR_VERY_LOW_ALERT);
			resetVeryLowAlertPreSnooze();
			disableRepeatAlert(2);
			BackgroundFetch.stopPlayingSound();
			_veryLowAlertSnoozePeriodInMinutes = snoozeValueMinutes[index];
			_veryLowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
		}
		
		public static function snoozeHighAlert(index:int):void {
			myTrace("in snoozeHighAlert. Snoozing for " + snoozeValueMinutes[index] + " minutes");
			_highAlertPreSnoozed = true;
			Notifications.service.cancel(NotificationService.ID_FOR_HIGH_ALERT);
			resetHighAlertPreSnooze();
			disableRepeatAlert(3);
			BackgroundFetch.stopPlayingSound();
			_highAlertSnoozePeriodInMinutes = snoozeValueMinutes[index];
			_highAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
		}
		
		public static function snoozeVeryHighAlert(index:int):void {
			myTrace("in snoozeVeryHighAlert. Snoozing for " + snoozeValueMinutes[index] + " minutes");
			_veryHighAlertPreSnoozed = true;
			Notifications.service.cancel(NotificationService.ID_FOR_VERY_HIGH_ALERT);
			resetVeryHighAlertPreSnooze();
			disableRepeatAlert(4);
			BackgroundFetch.stopPlayingSound();
			_veryHighAlertSnoozePeriodInMinutes = snoozeValueMinutes[index];
			_veryHighAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
		}
		
		public static function snoozeMissedReadingAlert(index:int):void {
			myTrace("in snoozeMissedReadingAlert. Snoozing for " + snoozeValueMinutes[index] + " minutes");
			_missedReadingAlertPreSnoozed = true;
			Notifications.service.cancel(NotificationService.ID_FOR_MISSED_READING_ALERT);
			resetMissedreadingAlertPreSnooze();
			disableRepeatAlert(5);
			BackgroundFetch.stopPlayingSound();
			_missedReadingAlertSnoozePeriodInMinutes = snoozeValueMinutes[index];
			_missedReadingAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
		}
		
		public static function snoozePhoneMutedAlert(index:int):void {
			myTrace("in snoozePhoneMutedAlert. Snoozing for " + snoozeValueMinutes[index] + " minutes");
			_phoneMutedAlertPreSnoozed = true;
			Notifications.service.cancel(NotificationService.ID_FOR_PHONEMUTED_ALERT);
			resetPhoneMutedAlertPreSnooze();
			disableRepeatAlert(7);
			BackgroundFetch.stopPlayingSound();
			_phoneMutedAlertSnoozePeriodInMinutes = snoozeValueMinutes[index];
			_phoneMutedAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
		}
		
		private static function openSnoozePickerDialog(alertSetting:String, notificationId:int, notificationEvent:NotificationEvent, 
													   snoozePickerClosedHandler:Function, 
													   snoozeText:String, alertSnoozeIdentifier:String, snoozeValueSetter:Function, presnoozeResetFunction:Function = null):void {
			var listOfAlerts:FromtimeAndValueArrayCollection = FromtimeAndValueArrayCollection.createList(
				alertSetting, true);
			var alertName:String = listOfAlerts.getAlarmName(Number.NaN, "", new Date());
			var alertType:AlertType = Database.getAlertType(alertName);
			myTrace("in openSnoozePickerDialog with id = " + NotificationService.notificationIdToText(notificationId) + ", cancelling notification");
			Notifications.service.cancel(notificationId);
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
				if (snoozeText == "low_alert_notification_alert_text" ||
					snoozeText == "verylow_alert_notification_alert_text" ||
					snoozeText == "high_alert_notification_alert_text" ||
					snoozeText == "veryhigh_alert_notification_alert_text")
				{
					AlarmSnoozer.displaySnoozer(ModelLocator.resourceManagerInstance.getString("alarmservice",snoozeText) + " (" + BgGraphBuilder.unitizedString(BgReading.lastNoSensor().calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") + ")", snoozeValueStrings, index);
				}
				else
					AlarmSnoozer.displaySnoozer(ModelLocator.resourceManagerInstance.getString("alarmservice",snoozeText), snoozeValueStrings, index);
			} 
			else if (notificationEvent.identifier == alertSnoozeIdentifier) {
				snoozeValueSetter(alertType.defaultSnoozePeriodInMinutes);
			}
			
			function canceledHandler(event:starling.events.Event):void {
				BackgroundFetch.stopPlayingSound();
				if (presnoozeResetFunction != null) {
					presnoozeResetFunction();
				}
			}
		}
		
		private static function setLowAlertSnooze(periodInMinutes:int):void {
			_lowAlertSnoozePeriodInMinutes = periodInMinutes;
			myTrace("in notificationReceived with id = ID_FOR_LOW_ALERT, snoozing the notification for " + _lowAlertSnoozePeriodInMinutes + " minutes");
			_lowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			
			//Notify Services (ex: IFTTT)
			_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.LOW_GLUCOSE_SNOOZED,false,false,{type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_low_alert"),time: _lowAlertSnoozePeriodInMinutes}));
		}
		
		private static function setVeryLowAlertSnooze(periodInMinutes:int):void {
			_veryLowAlertSnoozePeriodInMinutes = periodInMinutes;
			myTrace("in notificationReceived with id = ID_FOR_VERY_LOW_ALERT, snoozing the notification for " + _veryLowAlertSnoozePeriodInMinutes + " minutes");
			_veryLowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			
			//Notify Services (ex: IFTTT)
			_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.URGENT_LOW_GLUCOSE_SNOOZED,false,false,{type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_very_low_alert"), time: _veryLowAlertSnoozePeriodInMinutes}));
		}
		
		private static function setHighAlertSnooze(periodInMinutes:int):void {
			_highAlertSnoozePeriodInMinutes = periodInMinutes;
			myTrace("in notificationReceived with id = ID_FOR_HIGH_ALERT, snoozing the notification for " + _highAlertSnoozePeriodInMinutes + " minutes");
			_highAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			
			//Notify Services (ex: IFTTT)
			_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.HIGH_GLUCOSE_SNOOZED,false,false,{type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_high_alert"),time: _highAlertSnoozePeriodInMinutes}));
		}
		
		private static function setVeryHighAlertSnooze(periodInMinutes:int):void {
			_veryHighAlertSnoozePeriodInMinutes = periodInMinutes;
			myTrace("in notificationReceived with id = ID_FOR_VERY_HIGH_ALERT, snoozing the notification for " + _veryHighAlertSnoozePeriodInMinutes + " minutes");
			_veryHighAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			
			//Notify Services (ex: IFTTT)
			_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.URGENT_HIGH_GLUCOSE_SNOOZED,false,false,{type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_very_high_alert"),time: _veryHighAlertSnoozePeriodInMinutes}));
		}
		
		private static function setMissedReadingAlertSnooze(periodInMinutes:int):void {
			_missedReadingAlertSnoozePeriodInMinutes = periodInMinutes;
			myTrace("in notificationReceived with id = ID_FOR_MISSED_READING_ALERT, snoozing the notification for " + _missedReadingAlertSnoozePeriodInMinutes + " minutes");
			_missedReadingAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			
			//Notify Services (ex: IFTTT)
			_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.MISSED_READINGS_SNOOZED,false,false,{type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_missed_reading_alert"),time: _missedReadingAlertSnoozePeriodInMinutes}));
		}
		
		private static function setPhoneMutedAlertSnooze(periodInMinutes:int):void {
			_phoneMutedAlertSnoozePeriodInMinutes = periodInMinutes;
			myTrace("in notificationReceived with id = ID_FOR_PHONE_MUTED_ALERT, snoozing the notification for " + _phoneMutedAlertSnoozePeriodInMinutes + " minutes");
			_phoneMutedAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			
			//Notify Services (ex: IFTTT)
			_instance.dispatchEvent(new AlarmServiceEvent(AlarmServiceEvent.PHONE_MUTED_SNOOZED,false,false,{type: ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_phone_muted_alert"),time: _phoneMutedAlertSnoozePeriodInMinutes}));
		}
		
		private static function lowSnoozePicker_closedHandler(event:starling.events.Event): void {
			myTrace("in lowSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
			disableRepeatAlert(1);
			BackgroundFetch.stopPlayingSound();
			_lowAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
			_lowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
		}
		
		private static function veryLowSnoozePicker_closedHandler(event:starling.events.Event): void {
			myTrace("in veryLowSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
			disableRepeatAlert(2);
			BackgroundFetch.stopPlayingSound();
			_veryLowAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
			_veryLowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
		}
		
		private static function highSnoozePicker_closedHandler(event:starling.events.Event): void {
			myTrace("in highSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
			disableRepeatAlert(3);
			BackgroundFetch.stopPlayingSound();
			_highAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
			_highAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
		}
		
		private static function veryHighSnoozePicker_closedHandler(event:starling.events.Event): void {
			myTrace("in veryHighSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
			disableRepeatAlert(4);
			BackgroundFetch.stopPlayingSound();
			_veryHighAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
			_veryHighAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
		}
		
		private static function missedReadingSnoozePicker_closedHandler(event:starling.events.Event): void {
			myTrace("in missedReadingSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
			disableRepeatAlert(5);
			BackgroundFetch.stopPlayingSound();
			_missedReadingAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
			_missedReadingAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
		}
		
		private static function phoneMutedSnoozePicker_closedHandler(event:starling.events.Event): void {
			myTrace("in phoneMutedSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
			AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, phoneMutedSnoozePicker_closedHandler);
			disableRepeatAlert(7);
			BackgroundFetch.stopPlayingSound();
			_phoneMutedAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
			_phoneMutedAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
		}
		
		private static function checkAlarms(be:flash.events.Event):void {
			myTrace("in checkAlarms");
			var now:Date = new Date();
			lastAlarmCheckTimeStamp = now.valueOf();
			var alertActive:Boolean = false;
			
			var lastbgreading:BgReading = BgReading.lastNoSensor();
			if (lastbgreading != null) {
				if (now.valueOf() - lastbgreading.timestamp < MAX_AGE_OF_READING_IN_MINUTES * 60 * 1000) {
					alertActive = checkVeryLowAlert(now);
					if(!alertActive) {
						alertActive = checkLowAlert(now);
						if (!alertActive) {
							alertActive = checkVeryHighAlert(now);
							if (!alertActive) {
								alertActive = checkHighAlert(now);
							} else {
								if (!_highAlertPreSnoozed)
									resetHighAlert();
							}
						} else {
							if (!_highAlertPreSnoozed)
								resetHighAlert();
							if (!_veryHighAlertPreSnoozed)
								resetVeryHighAlert();
						}
					} else {
						if (!_highAlertPreSnoozed)
							resetHighAlert();
						if (!_veryHighAlertPreSnoozed)
							resetVeryHighAlert();
						if (!_lowAlertPreSnoozed)
							resetLowAlert();
					}
				}
				checkMissedReadingAlert();
				if (!alertActive && !BlueToothDevice.isFollower()) {
					//to avoid that the arrival of a notification of a checkCalibrationRequestAlert stops the sounds of a previous low or high alert
					checkCalibrationRequestAlert(now);
				}
			}
			if (!alertActive && !BlueToothDevice.isFollower()) {
				//to avoid that the arrival of a notification of a checkBatteryLowAlert stops the sounds of a previous low or high alert
				checkBatteryLowAlert(now);
			}
		}
		
		private static function phoneMuted(event:BackgroundFetchEvent):void {
			myTrace("in phoneMuted");
			ModelLocator.phoneMuted = true;
			var now:Date = new Date(); 
			if (now.valueOf() - lastPhoneMutedAlertCheckTimeStamp > (4 * 60 + 45) * 1000) {
				myTrace("in phoneMuted, checking phoneMute Alarm because it's been more than 4 minutes 45 seconds");
				lastPhoneMutedAlertCheckTimeStamp = (new Date()).valueOf();
				var listOfAlerts:FromtimeAndValueArrayCollection = FromtimeAndValueArrayCollection.createList(
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT), false);
				//var alertValue:Number = listOfAlerts.getValue(Number.NaN, "", now);
				var alertName:String = listOfAlerts.getAlarmName(Number.NaN, "", now);
				var alertType:AlertType = Database.getAlertType(alertName);
				if (alertType.enabled) {
					//first check if snoozeperiod is passed, checking first for value would generate multiple alarms in case the sensor is unstable
					if (((now).valueOf() - _phoneMutedAlertLatestSnoozeTimeInMs) > _phoneMutedAlertSnoozePeriodInMinutes * 60 * 1000
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
						_phoneMutedAlertSnoozePeriodInMinutes = 0;
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
						_phoneMutedAlertSnoozePeriodInMinutes = 0;
					}
				}
				
			} else {
				myTrace("less than 4 minutes 45 seconds since last check, not checking phoneMuted alert now");
			}
		}
		
		private static function phoneNotMuted(event:BackgroundFetchEvent):void {
			myTrace("in phoneNotMuted");
			ModelLocator.phoneMuted = false;
			
			if ((new Date()).valueOf() - lastQueuedAlertSoundTimeStamp < 2 * 1000) {//it should normally be max 1 second
				if (queuedAlertSound != "") {
					myTrace("in phoneNotMuted, sound queued and fired alert time < 2 seconds ago");
					BackgroundFetch.playSound(queuedAlertSound);
				}
			}
			queuedAlertSound = "";
			
			//if not presnoozed then remove notification, even if there isn't any
			if (!_phoneMutedAlertPreSnoozed) {
				myTrace("cancel any existing alert for ID_FOR_PHONEMUTED_ALERT");
				Notifications.service.cancel(NotificationService.ID_FOR_PHONEMUTED_ALERT);
				_phoneMutedAlertLatestSnoozeTimeInMs = Number.NaN;
				_phoneMutedAlertSnoozePeriodInMinutes = 0;
				disableRepeatAlert(7);
			}
		}
		
		/**
		 * repeatId ==> 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted<br>
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
				//if sound not found in assets, take xdrip sound - this could happen if different languages have different sets of sounds and user switches language
				soundToSet = "";
				for (var cntr:int = 0;cntr < soundsAsDisplayedSplitted.length;cntr++) {
					newSound = StringUtil.trim(soundsAsDisplayedSplitted[cntr]);//using trim because during tests sometimes the soundname had a preceding white space
					if (newSound == StringUtil.trim(alertType.sound)) {//using trim because during tests sometimes the soundname had a preceding white space
						soundToSet = soundsAsStoredInAssetsSplitted[cntr];
						break;
					}
				}
			}
			
			if (ModelLocator.phoneMuted && !(StringUtil.trim(alertType.sound) == "default") && !(StringUtil.trim(alertType.sound) == "")) {//check against default for backward compability. Default sound can't be played with playSound
				if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_OVERRIDE_MUTE) == "true") 
				{
					BackgroundFetch.playSound("../assets/sounds/" + soundToSet);
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
				BackgroundFetch.vibrate();
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
		}
		
		private static function queueAlertSound(sound:String):void {
			queuedAlertSound = sound;
			lastQueuedAlertSoundTimeStamp = (new Date()).valueOf();
			
			//phone might be muted, but Modellocator.phonemuted may be false
			//launch check now
			//use backgroundfetch.checkmuted, bypasses all phone muted settings, user might have switched from non muted to muted just very recently
			BackgroundFetch.checkMuted();
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
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE) != "" && (Calibration.allForSensor().length >= 2 || BlueToothDevice.isFollower()))
			{
				Notifications.service.cancel(NotificationService.ID_FOR_APPLICATION_INACTIVE_ALERT);
				
				var notificationBuilder:NotificationBuilder = new NotificationBuilder()
					.setCount(BadgeBuilder.getAppBadge())
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
				myTrace("in planApplicationStoppedAlert, not planning an inactive alert... user has not set a transmitter yet.");
		}
		
		private static function checkMissedReadingAlert():void {
			var listOfAlerts:FromtimeAndValueArrayCollection;
			var alertValue:Number;
			var alertName:String;
			var alertType:AlertType;
			var now:Date = new Date();
			
			lastMissedReadingAlertCheckTimeStamp = (new Date()).valueOf(); 	
			
			if (Sensor.getActiveSensor() == null && !BlueToothDevice.isFollower()) {
				myTrace("in checkMissedReadingAlert, but sensor is not active and not follower, not planning a missed reading alert now, and cancelling any missed reading alert that maybe still exists");
				myTrace("cancel any existing alert for ID_FOR_MISSED_READING_ALERT");
				Notifications.service.cancel(NotificationService.ID_FOR_MISSED_READING_ALERT);
				return;
			}
			var lastBgReading:BgReading 
			if (!BlueToothDevice.isFollower()) {
				var lastBgReadings:ArrayCollection = BgReading.latest(1);
				if (lastBgReadings.length == 0) {
					myTrace("in checkMissedReadingAlert, but no readings exist yet, not planning a missed reading alert now, and cancelling any missed reading alert that maybe still exists");
					myTrace("cancel any existing alert for ID_FOR_MISSED_READING_ALERT");
					Notifications.service.cancel(NotificationService.ID_FOR_MISSED_READING_ALERT);
					return;
				} 
				lastBgReading = lastBgReadings.getItemAt(0) as BgReading;
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
			if (alertType.enabled) {
				myTrace("in checkMissedReadingAlert, alertType enabled");
				if (((now).valueOf() - _missedReadingAlertLatestSnoozeTimeInMs) > _missedReadingAlertSnoozePeriodInMinutes * 60 * 1000
					||
					isNaN(_missedReadingAlertLatestSnoozeTimeInMs)) {
					myTrace("in checkMissedReadingAlert, missed reading alert not snoozed");
					//not snoozed
					if (((now.valueOf() - lastBgReading.timestamp) > alertValue * 60 * 1000) && ((now.valueOf() - ModelLocator.appStartTimestamp) > 5 * 60 * 1000)) {
						myTrace("in checkAlarms, missed reading");
						fireAlert(
							5,
							alertType, 
							NotificationService.ID_FOR_MISSED_READING_ALERT, 
							ModelLocator.resourceManagerInstance.getString("alarmservice","missed_reading_alert_notification_alert"), 
							alertType.enableVibration,
							alertType.enableLights,
							NotificationService.ID_FOR_ALERT_MISSED_READING_CATEGORY
						); 
						_missedReadingAlertLatestSnoozeTimeInMs = Number.NaN;
						_missedReadingAlertSnoozePeriodInMinutes = 0;
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
		
		private static function checkCalibrationRequestAlert(now:Date):void {
			var listOfAlerts:FromtimeAndValueArrayCollection;
			var alertValue:Number;
			var alertName:String;
			var alertType:AlertType;
			
			listOfAlerts = FromtimeAndValueArrayCollection.createList(
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CALIBRATION_REQUEST_ALERT), false);
			alertValue = listOfAlerts.getValue(Number.NaN, "", now);
			alertName = listOfAlerts.getAlarmName(Number.NaN, "", now);
			alertType = Database.getAlertType(alertName);
			if (alertType.enabled) {
				if ((now.valueOf() - _calibrationRequestLatestSnoozeTimeInMs) > _calibrationRequestSnoozePeriodInMinutes * 60 * 1000
					||
					isNaN(_calibrationRequestLatestSnoozeTimeInMs)) {
					myTrace("in checkAlarms, calibration request alert not snoozed ");
					if (Calibration.last() != null && BgReading.last30Minutes().length >= 2) {
						if (alertValue < ((now.valueOf() - Calibration.last().timestamp) / 1000 / 60 / 60)) {
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
						} else {
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
			 if (BlueToothDevice.isBlueReader() || BlueToothDevice.isLimitter()) {
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
			 if (alertType.enabled) {
				 //first check if snoozeperiod is passed, checking first for value would generate multiple alarms in case the sensor is unstable
				 if (((now).valueOf() - _batteryLevelAlertLatestSnoozeTimeInMs) > _batteryLevelAlertSnoozePeriodInMinutes * 60 * 1000
					 ||
					 isNaN(_batteryLevelAlertLatestSnoozeTimeInMs)) {
					 myTrace("in checkAlarms, batteryLevel alert not snoozed ");
					 //not snoozed
					 
					 if ((BlueToothDevice.isDexcomG4() && (new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G4_TRANSMITTER_BATTERY_VOLTAGE)) < alertValue) && (new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G4_TRANSMITTER_BATTERY_VOLTAGE)) > 0))
						 ||
						 (BlueToothDevice.isBluKon() && (new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL)) < alertValue) && (new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL)) > 0))
						 ||
						 (BlueToothDevice.isDexcomG5() && (new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_VOLTAGEA)) < alertValue) && (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_VOLTAGEA) != "unknown"))) {
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
			 if (alertType.enabled) {
				 //first check if snoozeperiod is passed, checking first for value would generate multiple alarms in case the sensor is unstable
				 if (((now).valueOf() - _highAlertLatestSnoozeTimeInMs) > _highAlertSnoozePeriodInMinutes * 60 * 1000
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
						 _highAlertSnoozePeriodInMinutes = 0;
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
			 if (alertType.enabled) {
				 //first check if snoozeperiod is passed, checking first for value would generate multiple alarms in case the sensor is unstable
				 if (((now).valueOf() - _veryHighAlertLatestSnoozeTimeInMs) > _veryHighAlertSnoozePeriodInMinutes * 60 * 1000
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
						 _veryHighAlertSnoozePeriodInMinutes = 0;
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
			 if (alertType.enabled) {
				 //first check if snoozeperiod is passed, checking first for value would generate multiple alarms in case the sensor is unstable
				 if ((now.valueOf() - _lowAlertLatestSnoozeTimeInMs) > _lowAlertSnoozePeriodInMinutes * 60 * 1000
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
						 _lowAlertSnoozePeriodInMinutes = 0;
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
			 if (alertType.enabled) {
				 //first check if snoozeperiod is passed, checking first for value would generate multiple alarms in case the sensor is unstable
				 if ((now.valueOf() - _veryLowAlertLatestSnoozeTimeInMs) > _veryLowAlertSnoozePeriodInMinutes * 60 * 1000
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
						 _veryLowAlertSnoozePeriodInMinutes = 0;
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
		
		public static function resetVeryHighAlert():void {
			myTrace("in resetVeryHighAlert");
			Notifications.service.cancel(NotificationService.ID_FOR_VERY_HIGH_ALERT);
			disableRepeatAlert(4);
			_veryHighAlertLatestSnoozeTimeInMs = Number.NaN;
			_veryHighAlertSnoozePeriodInMinutes = 0;
			_veryHighAlertPreSnoozed = false;
		}
		
		public static function resetVeryLowAlert():void {
			myTrace("in resetVeryLowAlert");
			Notifications.service.cancel(NotificationService.ID_FOR_VERY_LOW_ALERT);
			disableRepeatAlert(2);
			_veryLowAlertLatestSnoozeTimeInMs = Number.NaN;
			_veryLowAlertSnoozePeriodInMinutes = 0;
			_veryLowAlertPreSnoozed = false;
		}
		
		public static function resetHighAlert():void {
			myTrace("in resetHighAlert");
			Notifications.service.cancel(NotificationService.ID_FOR_HIGH_ALERT);
			disableRepeatAlert(3);
			_highAlertLatestSnoozeTimeInMs = Number.NaN;
			_highAlertSnoozePeriodInMinutes = 0;
			_highAlertPreSnoozed = false;
		}
		
		public static function resetLowAlert():void {
			myTrace("in resetLowAlert");
			Notifications.service.cancel(NotificationService.ID_FOR_LOW_ALERT);
			disableRepeatAlert(1);
			_lowAlertLatestSnoozeTimeInMs = Number.NaN;
			_lowAlertSnoozePeriodInMinutes = 0;
			_lowAlertPreSnoozed = false;
		}
		
		public static function resetMissedReadingAlert():void {
			myTrace("in resetMissedReadingAlert");
			Notifications.service.cancel(NotificationService.ID_FOR_MISSED_READING_ALERT);
			disableRepeatAlert(5);
			_missedReadingAlertLatestSnoozeTimeInMs = Number.NaN;
			_missedReadingAlertSnoozePeriodInMinutes = 0;
			_missedReadingAlertPreSnoozed = false;
		}
		
		public static function resetPhoneMutedAlert():void {
			myTrace("in resetPhoneMutedAlert");
			Notifications.service.cancel(NotificationService.ID_FOR_PHONEMUTED_ALERT);
			disableRepeatAlert(7);
			_phoneMutedAlertLatestSnoozeTimeInMs = Number.NaN;
			_phoneMutedAlertSnoozePeriodInMinutes = 0;
			_phoneMutedAlertPreSnoozed = false;
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
			/*else if (event.data == CommonSettings.COMMON_SETTING_LANGUAGE) {
			var newSoundsAsDisplayed:String = ModelLocator.resourceManagerInstance.getString("alerttypeview","sound_names_as_displayed_can_be_translated_must_match_above_list");
			var newSoundsAsDisplayedSplitted:Array = newSoundsAsDisplayed.split(',');
			var existingAlertTypes:ArrayCollection = Database.getAllAlertTypes();
			for (var alertTypeCntr:int = 0; alertTypeCntr < existingAlertTypes.length; alertTypeCntr++) {
			for(var soundCntr:int = 0; soundCntr < soundsAsDisplayedSplitted.length; soundCntr++) {
			if ((StringUtil.trim(soundsAsDisplayedSplitted[soundCntr] as String)).toUpperCase() == StringUtil.trim((existingAlertTypes.getItemAt(alertTypeCntr) as AlertType).sound).toUpperCase()) {
			(existingAlertTypes.getItemAt(alertTypeCntr) as AlertType).sound = newSoundsAsDisplayedSplitted[soundCntr] as String;
			(existingAlertTypes.getItemAt(alertTypeCntr) as AlertType).updateInDatabase();
			break;
			}
			}
			}
			soundsAsDisplayed = newSoundsAsDisplayed;
			soundsAsDisplayedSplitted = newSoundsAsDisplayedSplitted;
			}*/
			if ((event.data >= CommonSettings.COMMON_SETTING_LOW_ALERT && event.data <= CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT) 
				||
				(event.data >= CommonSettings.COMMON_SETTING_BATTERY_ALERT && event.data <= CommonSettings.COMMON_SETTING_VERY_HIGH_ALERT)
			) {
				var listOfAlerts:FromtimeAndValueArrayCollection = FromtimeAndValueArrayCollection.createList(
					CommonSettings.getCommonSetting(event.data), false);
				var alertName:String = listOfAlerts.getAlarmName(Number.NaN, "", new Date());
				var alertType:AlertType = Database.getAlertType(alertName);
				if (!alertType.enabled) {
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
			//id ==> 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted<br
			for (var cntr:int = 0;cntr < activeAlertsArray.length;cntr++) {
				if (activeAlertsArray[cntr] == true) {
					if ((new Date()).valueOf() - repeatAlertsLastFireTimeStampArray[cntr] > 60 * 1000) {
						var alertType:AlertType = Database.getAlertType(repeatAlertsAlertTypeNameArray[cntr]);
						if (alertType.repeatInMinutes > 0) {
							Notifications.service.cancel(repeatAlertsNotificationIds[cntr]);//remove any notification that may already exist
							
							//remove also any open pickerdialog
							AlarmSnoozer.closeCallout();
							
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
							
							//if it's a low, very low, high or very high alert, 
							if (cntr == 1 || cntr == 2 || cntr == 3 || cntr == 4) {
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
					if ((new Date()).valueOf() - repeatAlertsLastFireTimeStampArray[cntr] < 31 * 1000) {
						myTrace("in appInForeGround, found active alert with id " + repeatAlertsNotificationIds[cntr]);
						//user brings the app from back to foreground within 30 seconds after firing the alert
						//Stop playing sound, this will not be done by calling notificationReceived
						BackgroundFetch.stopPlayingSound();
						
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
			var snoozedUntil:Number = snoozeTimeInMs + snoozePeriodInMinutes * 60 * 1000;
			if (now >= snoozedUntil) {
				return "not snoozed";
			}
			if (snoozedUntil - now < 1 * 60 * 60 * 1000) {//less than 1 hour
				remainingSnoozeMinutes = (snoozedUntil - now)/1000/60;
				return remainingSnoozeMinutes + " " + ModelLocator.resourceManagerInstance.getString("alarmservice","minutes");
			}
			if (snoozedUntil - now < 24 * 60 * 60 * 1000) {//less than 1 day
				remainingSnoozeHours =  (snoozedUntil - now)/1000/60/60;
				remainingSnoozeMinutes =  (snoozedUntil - now - remainingSnoozeHours * 60 * 60 * 1000)/1000/60;
				return remainingSnoozeHours + " " + ModelLocator.resourceManagerInstance.getString("alarmservice","hours")
					+ ", " + remainingSnoozeMinutes  + " " + ModelLocator.resourceManagerInstance.getString("alarmservice","minutes");
			}
			remainingSnoozeDays =  (snoozedUntil - now)/1000/60/60/24;
			remainingSnoozeHours =  (snoozedUntil - remainingSnoozeDays * 24 * 60 * 60 * 1000 - now)/1000/60/60;
			remainingSnoozeMinutes = (snoozedUntil - remainingSnoozeDays * 24 * 60 * 60 * 1000 - remainingSnoozeHours * 60 * 60 * 1000 - now)/1000/60;
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
		
		public static function veryLowAlertSnoozed():Boolean 
		{
			var returnValue:Boolean = true;
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _veryLowAlertLatestSnoozeTimeInMs + _veryLowAlertSnoozePeriodInMinutes * 60 * 1000;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_veryLowAlertLatestSnoozeTimeInMs))
				returnValue = false;
			
			return returnValue;
		}
		public static function lowAlertSnoozed():Boolean 
		{
			var returnValue:Boolean = true;
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _lowAlertLatestSnoozeTimeInMs + _lowAlertSnoozePeriodInMinutes * 60 * 1000;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_lowAlertLatestSnoozeTimeInMs))
				returnValue = false;
			
			return returnValue;
		}
		public static function highAlertSnoozed():Boolean 
		{
			var returnValue:Boolean = true;
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _highAlertLatestSnoozeTimeInMs + _highAlertSnoozePeriodInMinutes * 60 * 1000;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_highAlertLatestSnoozeTimeInMs))
				returnValue = false;
			
			return returnValue;
		}
		public static function veryHighAlertSnoozed():Boolean 
		{
			var returnValue:Boolean = true;
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _veryHighAlertLatestSnoozeTimeInMs + _veryHighAlertSnoozePeriodInMinutes * 60 * 1000;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_veryHighAlertLatestSnoozeTimeInMs))
				returnValue = false;
			
			return returnValue;
		}
		public static function missedReadingAlertSnoozed():Boolean 
		{
			var returnValue:Boolean = true;
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _missedReadingAlertLatestSnoozeTimeInMs + _missedReadingAlertSnoozePeriodInMinutes * 60 * 1000;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_missedReadingAlertLatestSnoozeTimeInMs))
				returnValue = false;
			
			return returnValue;
		}
		public static function phoneMutedAlertSnoozed():Boolean 
		{
			var returnValue:Boolean = true;
			var now:Number = new Date().valueOf();
			var snoozedUntil:Number = _phoneMutedAlertLatestSnoozeTimeInMs + _phoneMutedAlertSnoozePeriodInMinutes * 60 * 1000;
			
			if (isNaN(snoozedUntil) || now >= snoozedUntil || isNaN(_phoneMutedAlertLatestSnoozeTimeInMs))
				returnValue = false;
			
			return returnValue;
		}
		
		private static function resetVeryLowAlertPreSnooze():void {
			_veryLowAlertPreSnoozed = false;
		}
		private static function resetLowAlertPreSnooze():void {
			_lowAlertPreSnoozed = false;
		}
		private static function resetVeryHighAlertPreSnooze():void {
			_veryHighAlertPreSnoozed = false;
		}
		private static function resetHighAlertPreSnooze():void {
			_highAlertPreSnoozed = false;
		}
		private static function resetMissedreadingAlertPreSnooze():void {
			_missedReadingAlertPreSnoozed = false;
		}
		private static function resetPhoneMutedAlertPreSnooze():void {
			_phoneMutedAlertPreSnoozed = false;
		}
	}
}