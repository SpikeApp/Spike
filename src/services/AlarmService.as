package services
{
	import com.distriqt.extension.bluetoothle.BluetoothLE;
	import com.distriqt.extension.bluetoothle.events.PeripheralEvent;
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
	
	import events.BlueToothServiceEvent;
	import events.NotificationServiceEvent;
	import events.SettingsServiceEvent;
	import events.TransmitterServiceEvent;
	
	import feathers.motion.Fade;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.AppInterface;
	import ui.popups.AlarmSnoozer;
	import ui.screens.Screens;
	
	import utils.BgGraphBuilder;
	import utils.DateTimeUtilities;
	import utils.FromtimeAndValueArrayCollection;
	import utils.Trace;
	
	public class AlarmService extends EventDispatcher
	{
		[ResourceBundle("alarmservice")]
		[ResourceBundle("alertsettingsscreen")]
		
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
		 * timestamp of latest notification 
		 */
		private static var _lowAlertLatestNotificationTime:Number = Number.NaN;
		
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
		 * timestamp of latest notification 
		 */
		private static var _veryLowAlertLatestNotificationTime:Number = Number.NaN;
		
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
		 * timestamp of latest notification 
		 */
		private static var _highAlertLatestNotificationTime:Number = Number.NaN;
		
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
		 * timestamp of latest notification 
		 */
		private static var _veryHighAlertLatestNotificationTime:Number = Number.NaN;
		
		/**
		 * if lastbgreading is older than MAX_AGE_OF_READING_IN_MINUTES minutes, then no low or high alert will be generated  
		 */
		public static const MAX_AGE_OF_READING_IN_MINUTES:int = 4
		private static const MAX_REPEATS_FOR_ALERTS:int = 9; //repeating alerts are repeated every minute, means maximum 10 minutes of repeat
		
		//batteryLevel alert
		/**
		 * 0 is not snoozed, if > 0 this is snooze value chosen by user
		 */
		private static var _batteryLevelAlertSnoozePeriodInMinutes:int = 0;
		/**
		 * timestamp when alert was snoozed, ms 
		 */
		private static var _batteryLevelAlertLatestSnoozeTimeInMs:Number = Number.NaN;
		/**
		 * timestamp of latest notification 
		 */
		private static var _batteryLevelAlertLatestNotificationTime:Number = Number.NaN;
		
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
		 * timestamp of latest notification 
		 */
		private static var _missedReadingAlertLatestNotificationTime:Number = Number.NaN;
		
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
		 * timestamp of latest notification 
		 */
		private static var _phoneMutedAlertLatestNotificationTime:Number = Number.NaN;
		
		//calibration request
		/**
		 * 0 is not snoozed, if > 0 this is snooze value chosen by user
		 */
		private static var _calibrationRequestSnoozePeriodInMinutes:int = 0;
		/**
		 * timestamp when alert was snoozed, ms 
		 */
		private static var _calibrationRequestLatestSnoozeTimeInMs:Number = Number.NaN;
		/**
		 * timestamp of latest notification 
		 */
		private static var _calibrationRequestLatestNotificationTime:Number = Number.NaN;
		
		private static var snoozeValueMinutes:Array = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 75, 90, 105, 120, 150, 180, 240, 300, 360, 420, 480, 540, 600, 660, 720, 1440, 10080];
		private static var snoozeValueStrings:Array = ["5 minutes", "10 minutes", "15 minutes", "20 minutes", "25 minutes", "30 minutes", "35 minutes",
			"40 minutes", "45 minutes", "50 minutes", "55 minutes", "1 hour", "1 hour, 15 minutes", "1 hour, 30 minutes", "1 hour, 45 minutes", "2 hours", "2 hours, 30 minutes", "3 hours", "4 hours",
			"5 hours", "6 hours", "7 hours", "8 hours", "9 hours", "10 hours", "11 hours", "12 hours", "1 day", "1 week"];
		
		private static var lastAlarmCheckTimeStamp:Number;
		private static var lastCheckMuteTimeStamp:Number;
		private static var latestAlertTypeUsedInMissedReadingNotification:AlertType;
		private static var lastMissedReadingAlertCheckTimeStamp:Number;
		
		//for repeat of alarms every minute, this is only for non-snoozed alerts
		//each element in an array represents certain alarm 
		/**
		 * 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted<br>
		 * true means alert is active, repeat check is necessary (not necessarily repeat, that depends on the setting in the alert type)
		 */
		private static var repeatAlertsArray:Array = [false,false,false,false,false,false,false,false,false];
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
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, checkAlarms);
			NotificationService.instance.addEventListener(NotificationServiceEvent.NOTIFICATION_EVENT, notificationReceived);
			BackgroundFetch.instance.addEventListener(BackgroundFetchEvent.PHONE_MUTED, phoneMuted);
			BackgroundFetch.instance.addEventListener(BackgroundFetchEvent.PHONE_NOT_MUTED, phoneNotMuted);
			BluetoothService.instance.addEventListener(BlueToothServiceEvent.CHARACTERISTIC_UPDATE, checkMuted);
			BluetoothLE.service.centralManager.addEventListener(PeripheralEvent.DISCOVERED, checkMuted);
			BluetoothLE.service.centralManager.addEventListener(PeripheralEvent.CONNECT, checkMuted );
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, settingChanged);
			lastAlarmCheckTimeStamp = 0;
			lastMissedReadingAlertCheckTimeStamp = 0;
			lastCheckMuteTimeStamp = 0;
			
			for (var cntr:int = 0;cntr < snoozeValueMinutes.length;cntr++) {
				snoozeValueStrings[cntr] = (snoozeValueStrings[cntr] as String).replace("minutes", ModelLocator.resourceManagerInstance.getString("alarmservice","minutes"));
				snoozeValueStrings[cntr] = (snoozeValueStrings[cntr] as String).replace("hour", ModelLocator.resourceManagerInstance.getString("alarmservice","hour"));
				snoozeValueStrings[cntr] = (snoozeValueStrings[cntr] as String).replace("hours", ModelLocator.resourceManagerInstance.getString("alarmservice","hours"));
				snoozeValueStrings[cntr] = (snoozeValueStrings[cntr] as String).replace("day", ModelLocator.resourceManagerInstance.getString("alarmservice","day"));
				snoozeValueStrings[cntr] = (snoozeValueStrings[cntr] as String).replace("week", ModelLocator.resourceManagerInstance.getString("alarmservice","week"));
			}
			
			setTimer();
			
			//immediately check missedreading alerts
			checkMuted(null);
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
			if (((new Date()).valueOf() - lastMissedReadingAlertCheckTimeStamp)/1000 > 5 * 60 + 30) 
			{
				myTrace("in onAlarmTimer, calling checkMissedReadingAlert");
				checkMissedReadingAlert();
			}
			checkMuted(null);
			repeatAlerts();
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
						if (alertType.enabled) {
							//alert enabled
							myTrace("in checkMuted, calling BackgroundFetch.checkMuted");
							BackgroundFetch.checkMuted();
						} else {
							lastCheckMuteTimeStamp = nowNumber;
						}
					}
				}
		}
		
		
		private static function notificationReceived(event:NotificationServiceEvent):void {
			myTrace("in notificationReceived");
			if (BackgroundFetch.appIsInBackground()) {
				//app is in background, which means the notification was received due to a specific app related user action, like clicking "snooze" or opening the notification
				//  so stop the playing
				BackgroundFetch.stopPlayingSound();
			} else {
				//alert was fired while the app was in the foreground, in this case the notificationReceived function is called by iOS itself, it's not due to a user action
				//user can now snooze or cancel the alert, which will cause a stopPlayingSound
			}
			if (event != null) {
				var listOfAlerts:FromtimeAndValueArrayCollection;
				var alertName:String ;
				var alertType:AlertType;
				var index:int;
				var now:Date;
				var cntr:int;
				
				//Display Home Screen
				if(AppInterface.instance.navigator.activeScreenID != Screens.GLUCOSE_CHART)
				{
					AppInterface.instance.menu.selectedIndex = 0;
					AppInterface.instance.navigator.replaceScreen(Screens.GLUCOSE_CHART, Fade.createCrossfadeTransition(1.5));
				}
				
				var notificationEvent:NotificationEvent = event.data as NotificationEvent;
				myTrace("in notificationReceived, event != null, id = " + NotificationService.notificationIdToText(notificationEvent.id));
				if (notificationEvent.id == NotificationService.ID_FOR_LOW_ALERT) 
				{
					if (BackgroundFetch.appIsInBackground()) 
					{
						//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(1);
					}
					
					now = new Date();
					if ((now.valueOf() - _lowAlertLatestSnoozeTimeInMs) > _lowAlertSnoozePeriodInMinutes * 60 * 1000
						||
						isNaN(_lowAlertLatestSnoozeTimeInMs)) {
						listOfAlerts = FromtimeAndValueArrayCollection.createList(
							CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_ALERT), true);
						alertName = listOfAlerts.getAlarmName(Number.NaN, "", new Date());
						alertType = Database.getAlertType(alertName);
						myTrace("in notificationReceived with id = ID_FOR_LOW_ALERT, cancelling notification");
						myTrace("cancel any existing alert for ID_FOR_LOW_ALERT");
						Notifications.service.cancel(NotificationService.ID_FOR_LOW_ALERT);
						index = 0;
						for (cntr = 0;cntr < snoozeValueMinutes.length;cntr++) {
							if ((snoozeValueMinutes[cntr]) >= alertType.defaultSnoozePeriodInMinutes) {
								index = cntr;
								break;
							}
						}
						if (notificationEvent.identifier == null) 
						{
							AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CLOSED, lowSnoozePicker_closedHandler);
							AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CANCELLED, snoozePickerChangedOrCanceledHandler);
							AlarmSnoozer.displaySnoozer(ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_low_alert"), snoozeValueStrings, index);
						} 
						else if (notificationEvent.identifier == NotificationService.ID_FOR_LOW_ALERT_SNOOZE_IDENTIFIER) 
						{
							_lowAlertSnoozePeriodInMinutes = alertType.defaultSnoozePeriodInMinutes;
							myTrace("in notificationReceived with id = ID_FOR_LOW_ALERT, snoozing the notification for " + _lowAlertSnoozePeriodInMinutes + " minutes");
							_lowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
						}
					} else {
						myTrace("in checkAlarms, alarm snoozed, _lowAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_lowAlertLatestSnoozeTimeInMs)) + ", _lowAlertSnoozePeriodInMinutes = " + _lowAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				} else if (notificationEvent.id == NotificationService.ID_FOR_HIGH_ALERT) {
					if (BackgroundFetch.appIsInBackground()) 
					{
						//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(3);
					}
					now = new Date();
					if ((now.valueOf() - _highAlertLatestSnoozeTimeInMs) > _highAlertSnoozePeriodInMinutes * 60 * 1000
						||
						isNaN(_highAlertLatestSnoozeTimeInMs)) {
						listOfAlerts = FromtimeAndValueArrayCollection.createList(
							CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_ALERT), true);
						alertName = listOfAlerts.getAlarmName(Number.NaN, "", new Date());
						alertType = Database.getAlertType(alertName);
						myTrace("in notificationReceived with id = ID_FOR_HIGH_ALERT, cancelling notification");
						myTrace("cancel any existing alert for ID_FOR_HIGH_ALERT");
						Notifications.service.cancel(NotificationService.ID_FOR_HIGH_ALERT);
						index = 0;
						for (cntr = 0;cntr < snoozeValueMinutes.length;cntr++) {
							if ((snoozeValueMinutes[cntr]) >= alertType.defaultSnoozePeriodInMinutes) {
								index = cntr;
								break;
							}
						}
						if (notificationEvent.identifier == null) 
						{
							AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CLOSED, highSnoozePicker_closedHandler);
							AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CANCELLED, snoozePickerChangedOrCanceledHandler);
							AlarmSnoozer.displaySnoozer(ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_high_alert"), snoozeValueStrings, index);
						} 
						else if (notificationEvent.identifier == NotificationService.ID_FOR_HIGH_ALERT_SNOOZE_IDENTIFIER) 
						{
							_highAlertSnoozePeriodInMinutes = alertType.defaultSnoozePeriodInMinutes;
							myTrace("in notificationReceived with id = ID_FOR_HIGH_ALERT, snoozing the notification for " + _highAlertSnoozePeriodInMinutes + " minutes");
							_highAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
						}
					} else {
						myTrace("in checkAlarms, alarm snoozed, _highAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_highAlertLatestSnoozeTimeInMs)) + ", _highAlertSnoozePeriodInMinutes = " + _highAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				} else if (notificationEvent.id == NotificationService.ID_FOR_VERY_LOW_ALERT) {
					if (BackgroundFetch.appIsInBackground()) 
					{
						//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(2);
					}
					now = new Date();
					if ((now.valueOf() - _veryLowAlertLatestSnoozeTimeInMs) > _veryLowAlertSnoozePeriodInMinutes * 60 * 1000
						||
						isNaN(_veryLowAlertLatestSnoozeTimeInMs)) {
						listOfAlerts = FromtimeAndValueArrayCollection.createList(
							CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_VERY_LOW_ALERT), true);
						alertName = listOfAlerts.getAlarmName(Number.NaN, "", new Date());
						alertType = Database.getAlertType(alertName);
						myTrace("in notificationReceived with id = ID_FOR_VERY_LOW_ALERT, cancelling notification");
						myTrace("cancel any existing alert for ID_FOR_VERY_LOW_ALERT");
						Notifications.service.cancel(NotificationService.ID_FOR_VERY_LOW_ALERT);
						index = 0;
						for (cntr = 0;cntr < snoozeValueMinutes.length;cntr++) {
							if ((snoozeValueMinutes[cntr]) >= alertType.defaultSnoozePeriodInMinutes) {
								index = cntr;
								break;
							}
						}
						if (notificationEvent.identifier == null) 
						{
							AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CLOSED, veryLowSnoozePicker_closedHandler);
							AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CANCELLED, snoozePickerChangedOrCanceledHandler);
							AlarmSnoozer.displaySnoozer(ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_very_low_alert"), snoozeValueStrings, index);
						} 
						else if (notificationEvent.identifier == NotificationService.ID_FOR_VERY_LOW_ALERT_SNOOZE_IDENTIFIER) 
						{
							_veryLowAlertSnoozePeriodInMinutes = alertType.defaultSnoozePeriodInMinutes;
							myTrace("in notificationReceived with id = ID_FOR_VERY_LOW_ALERT, snoozing the notification for " + _veryLowAlertSnoozePeriodInMinutes + " minutes");
							_veryLowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
						}
					} else {
						myTrace("in checkAlarms, alarm snoozed, _veryLowAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_veryLowAlertLatestSnoozeTimeInMs)) + ", _veryLowAlertSnoozePeriodInMinutes = " + _veryLowAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				} else if (notificationEvent.id == NotificationService.ID_FOR_VERY_HIGH_ALERT) {
					if (BackgroundFetch.appIsInBackground()) {//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(4);
					}
					now = new Date();
					if ((now.valueOf() - _veryHighAlertLatestSnoozeTimeInMs) > _veryHighAlertSnoozePeriodInMinutes * 60 * 1000
						||
						isNaN(_veryHighAlertLatestSnoozeTimeInMs)) {
						listOfAlerts = FromtimeAndValueArrayCollection.createList(
							CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_VERY_HIGH_ALERT), true);
						alertName = listOfAlerts.getAlarmName(Number.NaN, "", new Date());
						alertType = Database.getAlertType(alertName);
						myTrace("in notificationReceived with id = ID_FOR_VERY_HIGH_ALERT, cancelling notification");
						myTrace("cancel any existing alert for ID_FOR_VERY_HIGH_ALERT");
						Notifications.service.cancel(NotificationService.ID_FOR_VERY_HIGH_ALERT);
						index = 0;
						for (cntr = 0;cntr < snoozeValueMinutes.length;cntr++) {
							if ((snoozeValueMinutes[cntr]) >= alertType.defaultSnoozePeriodInMinutes) {
								index = cntr;
								break;
							}
						}
						if (notificationEvent.identifier == null) 
						{
							AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CLOSED, veryHighSnoozePicker_closedHandler);
							AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CANCELLED, snoozePickerChangedOrCanceledHandler);
							AlarmSnoozer.displaySnoozer(ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_very_high_alert"), snoozeValueStrings, index);
						} 
						else if (notificationEvent.identifier == NotificationService.ID_FOR_VERY_HIGH_ALERT_SNOOZE_IDENTIFIER) 
						{
							_veryHighAlertSnoozePeriodInMinutes = alertType.defaultSnoozePeriodInMinutes;
							myTrace("in notificationReceived with id = ID_FOR_VERY_HIGH_ALERT, snoozing the notification for " + _veryHighAlertSnoozePeriodInMinutes + " minutes");
							_veryHighAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
						}
					} else {
						myTrace("in checkAlarms, alarm snoozed, _veryHighAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_veryHighAlertLatestSnoozeTimeInMs)) + ", _veryHighAlertSnoozePeriodInMinutes = " + _veryHighAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				} else if (notificationEvent.id == NotificationService.ID_FOR_MISSED_READING_ALERT) {
					if (BackgroundFetch.appIsInBackground()) 
					{
						//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(5);
					}
					listOfAlerts = FromtimeAndValueArrayCollection.createList(
						CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_MISSED_READING_ALERT), false);
					alertName = listOfAlerts.getAlarmName(Number.NaN, "", new Date());
					alertType = Database.getAlertType(alertName);
					myTrace("in notificationReceived with id = ID_FOR_MISSED_READING_ALERT, cancelling notification");
					myTrace("cancel any existing alert for ID_FOR_MISSED_READING_ALERT");
					Notifications.service.cancel(NotificationService.ID_FOR_MISSED_READING_ALERT);
					index = 0;
					for (cntr = 0;cntr < snoozeValueMinutes.length;cntr++) {
						if ((snoozeValueMinutes[cntr]) >= alertType.defaultSnoozePeriodInMinutes) {
							index = cntr;
							break;
						}
					}
					if (notificationEvent.identifier == null) 
					{
						AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CLOSED, missedReadingSnoozePicker_closedHandler);
						AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CANCELLED, snoozePickerChangedOrCanceledHandler);
						AlarmSnoozer.displaySnoozer(ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_missed_reading_alert"), snoozeValueStrings, index);
					}
				} else if (notificationEvent.identifier == NotificationService.ID_FOR_MISSED_READING_ALERT_SNOOZE_IDENTIFIER) {
					_missedReadingAlertSnoozePeriodInMinutes = alertType.defaultSnoozePeriodInMinutes;
					myTrace("in notificationReceived with id = ID_FOR_MISSED_READING_ALERT, snoozing the notification for " + _missedReadingAlertSnoozePeriodInMinutes + " minutes");
					_missedReadingAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
				}
				else if (notificationEvent.id == NotificationService.ID_FOR_PHONEMUTED_ALERT) 
				{
					if (BackgroundFetch.appIsInBackground()) 
					{
						//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(7);
					}
					now = new Date();
					if ((now.valueOf() - _phoneMutedAlertLatestSnoozeTimeInMs) > _phoneMutedAlertSnoozePeriodInMinutes * 60 * 1000
						||
						isNaN(_phoneMutedAlertLatestSnoozeTimeInMs)) {
						listOfAlerts = FromtimeAndValueArrayCollection.createList(
							CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT), false);
						alertName = listOfAlerts.getAlarmName(Number.NaN, "", new Date());
						alertType = Database.getAlertType(alertName);
						myTrace("in notificationReceived with id = ID_FOR_PHONEMUTED_ALERT, cancelling notification");
						myTrace("cancel any existing alert for ID_FOR_PHONEMUTED_ALERT");
						Notifications.service.cancel(NotificationService.ID_FOR_PHONEMUTED_ALERT);
						index = 0;
						for (cntr = 0;cntr < snoozeValueMinutes.length;cntr++) {
							if ((snoozeValueMinutes[cntr]) >= alertType.defaultSnoozePeriodInMinutes) {
								index = cntr;
								break;
							}
						}
						if (notificationEvent.identifier == null) 
						{
							AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CLOSED, phoneMutedSnoozePicker_closedHandler);
							AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CANCELLED, snoozePickerChangedOrCanceledHandler);
							AlarmSnoozer.displaySnoozer(ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_phone_muted_alert"), snoozeValueStrings, index);
						} 
						else if (notificationEvent.identifier == NotificationService.ID_FOR_PHONE_MUTED_SNOOZE_IDENTIFIER) 
						{
							_phoneMutedAlertSnoozePeriodInMinutes = alertType.defaultSnoozePeriodInMinutes;
							myTrace("in notificationReceived with id = ID_FOR_PHONEMUTED_ALERT, snoozing the notification for " + _phoneMutedAlertSnoozePeriodInMinutes + " minutes");
							_phoneMutedAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
						}
					} else {
						myTrace("in checkAlarms, alarm snoozed, _phoneMutedAlertLatestSnoozeTimeInMs = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_phoneMutedAlertLatestSnoozeTimeInMs)) + ", _phoneMutedAlertSnoozePeriodInMinutes = " + _phoneMutedAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				} else if (notificationEvent.id == NotificationService.ID_FOR_BATTERY_ALERT) {
					if (BackgroundFetch.appIsInBackground()) 
					{
						//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(6);
					}
					now = new Date();
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
						} 
						else if (notificationEvent.identifier == NotificationService.ID_FOR_BATTERY_LEVEL_ALERT_SNOOZE_IDENTIFIER) 
						{
							_batteryLevelAlertSnoozePeriodInMinutes = alertType.defaultSnoozePeriodInMinutes;
							myTrace("in notificationReceived with id = ID_FOR_BATTERY_ALERT, snoozing the notification for " + _batteryLevelAlertSnoozePeriodInMinutes + " minutes");
							_batteryLevelAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
						}
					} else {
						myTrace("in checkAlarms, alarm snoozed, _batteryLevelAlertLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_batteryLevelAlertLatestSnoozeTimeInMs)) + ", _batteryLevelAlertSnoozePeriodInMinutes = " + _batteryLevelAlertSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				} else if (notificationEvent.id == NotificationService.ID_FOR_CALIBRATION_REQUEST_ALERT) {
					if (BackgroundFetch.appIsInBackground()) 
					{
						//if app would be in foreground, notificationReceived is called even withtout any user interaction, don't disable the repeat in that case
						disableRepeatAlert(0);
					}
					now = new Date();
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
						}
					} else {
						myTrace("in checkAlarms, alarm snoozed, _calibrationRequestLatestSnoozeTime = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(_calibrationRequestLatestSnoozeTimeInMs)) + ", _calibrationRequestSnoozePeriodInMinutes = " + _calibrationRequestSnoozePeriodInMinutes + ", actual time = " + DateTimeUtilities.createNSFormattedDateAndTime(new Date()));
					}
				}
			}
		
			function snoozeCalibrationRequest():void 
			{
				myTrace("in snoozeCalibrationRequest");
				AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CLOSED, calibrationRequestSnoozePicker_closedHandler);
				AlarmSnoozer.instance.addEventListener(AlarmSnoozer.CANCELLED, snoozePickerChangedOrCanceledHandler);
				AlarmSnoozer.displaySnoozer(ModelLocator.resourceManagerInstance.getString("alarmservice","snooze_text_calibration_alert"), snoozeValueStrings, index);
			}
			
			function calibrationRequestSnoozePicker_closedHandler(event:starling.events.Event): void {
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, calibrationRequestSnoozePicker_closedHandler);
				BackgroundFetch.stopPlayingSound();
				myTrace("in calibrationRequestSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index] + " minutes");
				disableRepeatAlert(0);
				_calibrationRequestSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_calibrationRequestLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
			
			function batteryLevelSnoozePicker_closedHandler(event:starling.events.Event): void {
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, batteryLevelSnoozePicker_closedHandler);
				BackgroundFetch.stopPlayingSound();
				myTrace("in batteryLevelSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index] + " minutes");
				disableRepeatAlert(6);
				_batteryLevelAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_batteryLevelAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
			
			function phoneMutedSnoozePicker_closedHandler(event:starling.events.Event): void 
			{
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, phoneMutedSnoozePicker_closedHandler);
				BackgroundFetch.stopPlayingSound();
				myTrace("in phoneMutedSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index] + " minutes");
				disableRepeatAlert(7);
				_phoneMutedAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_phoneMutedAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
			
			function missedReadingSnoozePicker_closedHandler(event:starling.events.Event): void {
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, missedReadingSnoozePicker_closedHandler);
				BackgroundFetch.stopPlayingSound();
				myTrace("in phoneMutedSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index] + " minutes");
				disableRepeatAlert(5);
				_missedReadingAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_missedReadingAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
			
			function lowSnoozePicker_closedHandler(event:starling.events.Event): void 
			{
				myTrace("in lowSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, lowSnoozePicker_closedHandler);
				disableRepeatAlert(1);
				BackgroundFetch.stopPlayingSound();
				_lowAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_lowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
			
			function highSnoozePicker_closedHandler(event:starling.events.Event): void {
				myTrace("in highSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, highSnoozePicker_closedHandler);
				disableRepeatAlert(3);
				BackgroundFetch.stopPlayingSound();
				_highAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_highAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
			
			function veryHighSnoozePicker_closedHandler(event:starling.events.Event): void {
				myTrace("in veryHighSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, veryHighSnoozePicker_closedHandler);
				disableRepeatAlert(4);
				BackgroundFetch.stopPlayingSound();
				_veryHighAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_veryHighAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
			
			function veryLowSnoozePicker_closedHandler(event:starling.events.Event): void {
				myTrace("in veryLowSnoozePicker_closedHandler snoozing the notification for " + snoozeValueStrings[event.data.index]);
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CLOSED, veryLowSnoozePicker_closedHandler);
				disableRepeatAlert(2);
				BackgroundFetch.stopPlayingSound();
				_veryLowAlertSnoozePeriodInMinutes = snoozeValueMinutes[event.data.index];
				_veryLowAlertLatestSnoozeTimeInMs = (new Date()).valueOf();
			}
			
			function snoozePickerChangedOrCanceledHandler(event:starling.events.Event): void 
			{
				AlarmSnoozer.instance.removeEventListener(AlarmSnoozer.CANCELLED, snoozePickerChangedOrCanceledHandler);
				BackgroundFetch.stopPlayingSound();
			}
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
								resetHighAlert();
							}
						} else {
							resetHighAlert();
							resetVeryHighAlert();
						}
					} else {
						resetHighAlert();
						resetVeryHighAlert();
						resetLowAlert();
					}
				}
				checkMissedReadingAlert();
				if (!alertActive) {
					//to avoid that the arrival of a notification of a checkCalibrationRequestAlert stops the sounds of a previous low or high alert
					checkCalibrationRequestAlert(now);
				}
			}
			if (!alertActive) {
				//to avoid that the arrival of a notification of a checkBatteryLowAlert stops the sounds of a previous low or high alert
				checkBatteryLowAlert(now);
			}
		}
		
		private static function phoneMuted(event:BackgroundFetchEvent):void {
			myTrace("in phoneMuted");
			ModelLocator.phoneMuted = true;
			var now:Date = new Date(); 
			if (now.valueOf() - lastCheckMuteTimeStamp > (4 * 60 + 45) * 1000) {
				myTrace("in phoneMuted, checking phoneMute Alarm because it's been more than 4 minutes 45 seconds");
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
					//remove notification, even if there isn't any
					myTrace("in phoneMuted, alerttype not enabled");
					myTrace("cancel any existing alert for ID_FOR_PHONEMUTED_ALERT");
					Notifications.service.cancel(NotificationService.ID_FOR_PHONEMUTED_ALERT);
					_phoneMutedAlertLatestSnoozeTimeInMs = Number.NaN;
					_phoneMutedAlertLatestNotificationTime = Number.NaN;
					_phoneMutedAlertSnoozePeriodInMinutes = 0;
				}
				
			} else {
				myTrace("less than 4 minutes 45 seconds since last check, not checking phoneMuted alert now");
			}
			lastCheckMuteTimeStamp = now.valueOf();
		}
		
		private static function phoneNotMuted(event:BackgroundFetchEvent):void {
			myTrace("in phoneNotMuted");
			ModelLocator.phoneMuted = false;
			//remove notification, even if there isn't any
			myTrace("cancel any existing alert for ID_FOR_PHONEMUTED_ALERT");
			Notifications.service.cancel(NotificationService.ID_FOR_PHONEMUTED_ALERT);
			_phoneMutedAlertLatestSnoozeTimeInMs = Number.NaN;
			_phoneMutedAlertLatestNotificationTime = Number.NaN;
			_phoneMutedAlertSnoozePeriodInMinutes = 0;
			lastCheckMuteTimeStamp = (new Date()).valueOf();
			disableRepeatAlert(7);
		}
		
		/**
		 * repeatId ==> 0:calibration, 1:Low, 2:Very Low, 3:High, 4:Very High, 5:Missed Reading, 6:Battery Low, 7:Phone Muted<br>
		 */
		private static function fireAlert(repeatId:int, alertType:AlertType, notificationId:int, alertText:String, enableVibration:Boolean, enableLights:Boolean, categoryId:String, alertBody:String = " "):void 
		{
			var soundsAsDisplayed:String = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","alert_sounds_names");
			var soundsAsStoredInAssets:String = ModelLocator.resourceManagerInstance.getString("alertsettingsscreen","alert_sounds_files");
			var soundsAsDisplayedSplitted:Array = soundsAsDisplayed.split(',');
			var soundsAsStoredInAssetsSplitted:Array = soundsAsStoredInAssets.split(',');
			var notificationBuilder:NotificationBuilder;
			var newSound:String;
			var soundToSet:String = "";
			if (alertBody.length == 0)
				alertBody = " ";
			
			notificationBuilder = new NotificationBuilder()
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
				for (var cntr:int = 0;cntr < soundsAsDisplayedSplitted.length;cntr++) {
					newSound = StringUtil.trim(soundsAsDisplayedSplitted[cntr]);//using trim because during tests sometimes the soundname had a preceding white space
					if (newSound == StringUtil.trim(alertType.sound)) {//using trim because during tests sometimes the soundname had a preceding white space
							soundToSet = soundsAsStoredInAssetsSplitted[cntr];
							break;
					}
				}
			}
			
			if (ModelLocator.phoneMuted && !(StringUtil.trim(alertType.sound) == "default") && !(StringUtil.trim(alertType.sound) == "")) //check against default for backward compability. Default sound can't be played with playSound 
			{
				if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_OVERRIDE_MUTE) == "true")
				{
					BackgroundFetch.playSound("../assets/sounds/" + soundToSet);	
				}
				else
				{
					//phone is muted
					//play sound through notification, as a result it will actually not be played because notification sounds are not played when phone is muted
					notificationBuilder.setSound(soundToSet);
				}
			} 
			else 
			{
				BackgroundFetch.playSound("../assets/sounds/" + soundToSet);		
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
		}
		
		private static function checkMissedReadingAlert():void {
			var listOfAlerts:FromtimeAndValueArrayCollection;
			var alertValue:Number;
			var alertName:String;
			var alertType:AlertType;
			var now:Date = new Date();

			lastMissedReadingAlertCheckTimeStamp = (new Date()).valueOf(); 	

			if (Sensor.getActiveSensor() == null) {
				myTrace("in checkMissedReadingAlert, but sensor is not active, not planning a missed reading alert now, and cancelling any missed reading alert that maybe still exists");
				myTrace("cancel any existing alert for ID_FOR_MISSED_READING_ALERT");
				Notifications.service.cancel(NotificationService.ID_FOR_MISSED_READING_ALERT);
				return;
			}
			var lastBgReadings:ArrayCollection = BgReading.latestBySize(1);
			if (lastBgReadings.length == 0) {
				myTrace("in checkMissedReadingAlert, but no readings exist yet, not planning a missed reading alert now, and cancelling any missed reading alert that maybe still exists");
				myTrace("cancel any existing alert for ID_FOR_MISSED_READING_ALERT");
				Notifications.service.cancel(NotificationService.ID_FOR_MISSED_READING_ALERT);
				return;
			} 
			var lastBgReading:BgReading = lastBgReadings.getItemAt(0) as BgReading;
			
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
				//remove missed reading notification, even if there isn't any
				resetMissedReadingAlert();
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
				_calibrationRequestLatestNotificationTime = Number.NaN;
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
				 _batteryLevelAlertLatestNotificationTime = Number.NaN;
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
							 BgGraphBuilder.unitizedString(BgReading.lastNoSensor().calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") +  (lastBgReading.hideSlope ? "":(" " + lastBgReading.slopeArrow())) + " " + BgGraphBuilder.unitizedDeltaString(true, true)
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
				 //remove notification, even if there isn't any
				 resetHighAlert();
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
							 BgGraphBuilder.unitizedString(BgReading.lastNoSensor().calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") +  (lastBgReading.hideSlope ? "":(" " + lastBgReading.slopeArrow())) + " " + BgGraphBuilder.unitizedDeltaString(true, true)
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
				 //remove notification, even if there isn't any
				 resetVeryHighAlert();
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
							 BgGraphBuilder.unitizedString(BgReading.lastNoSensor().calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") +  (lastBgReading.hideSlope ? "":(" " + lastBgReading.slopeArrow())) + " " + BgGraphBuilder.unitizedDeltaString(true, true)
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
				 //remove low notification, even if there isn't any
				 resetLowAlert();
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
							 BgGraphBuilder.unitizedString(BgReading.lastNoSensor().calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") +  (lastBgReading.hideSlope ? "":(" " + lastBgReading.slopeArrow())) + " " + BgGraphBuilder.unitizedDeltaString(true, true)
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
				 //remove veryLow notification, even if there isn't any
				 resetVeryLowAlert();
			 }
			 return returnValue;
		 }
		
		private static function resetVeryHighAlert():void {
			myTrace("cancel any existing alert for ID_FOR_VERY_HIGH_ALERT");
			Notifications.service.cancel(NotificationService.ID_FOR_VERY_HIGH_ALERT);
			disableRepeatAlert(4);
			_veryHighAlertLatestSnoozeTimeInMs = Number.NaN;
			_veryHighAlertLatestNotificationTime = Number.NaN;
			_veryHighAlertSnoozePeriodInMinutes = 0;
		}
		
		private static function resetVeryLowAlert():void {
			myTrace("cancel any existing alert for ID_FOR_VERY_LOW_ALERT");
			Notifications.service.cancel(NotificationService.ID_FOR_VERY_LOW_ALERT);
			disableRepeatAlert(2);
			_veryLowAlertLatestSnoozeTimeInMs = Number.NaN;
			_veryLowAlertLatestNotificationTime = Number.NaN;
			_veryLowAlertSnoozePeriodInMinutes = 0;
		}
		
		private static function resetHighAlert():void {
			myTrace("cancel any existing alert for ID_FOR_HIGH_ALERT");
			Notifications.service.cancel(NotificationService.ID_FOR_HIGH_ALERT);
			disableRepeatAlert(3);
			_highAlertLatestSnoozeTimeInMs = Number.NaN;
			_highAlertLatestNotificationTime = Number.NaN;
			_highAlertSnoozePeriodInMinutes = 0;
		}
		
		private static function resetLowAlert():void {
			myTrace("cancel any existing alert for ID_FOR_LOW_ALERT");
			Notifications.service.cancel(NotificationService.ID_FOR_LOW_ALERT);
			disableRepeatAlert(1);
			_lowAlertLatestSnoozeTimeInMs = Number.NaN;
			_lowAlertLatestNotificationTime = Number.NaN;
			_lowAlertSnoozePeriodInMinutes = 0;
		}
		
		private static function resetMissedReadingAlert():void {
			myTrace("cancel any existing alert for ID_FOR_MISSED_READING_ALERT");
			Notifications.service.cancel(NotificationService.ID_FOR_MISSED_READING_ALERT);
			disableRepeatAlert(5);
			_missedReadingAlertLatestSnoozeTimeInMs = Number.NaN;
			_missedReadingAlertLatestNotificationTime = Number.NaN;
			_missedReadingAlertSnoozePeriodInMinutes = 0;
		}

		
		private static function settingChanged(event:SettingsServiceEvent):void {
			if (event.data == CommonSettings.COMMON_SETTING_CURRENT_SENSOR) {
				checkMissedReadingAlert();
				//need to plan missed reading alert
				//in case user has started, stopped a sensor
				//    if It was a sensor stop, then the setting COMMON_SETTING_CURRENT_SENSOR has value "0", and in checkMissedReadingAlert, the alert will be canceled and not replanned
			} else if (event.data == CommonSettings.COMMON_SETTING_CALIBRATION_REQUEST_ALERT) {
				checkCalibrationRequestAlert(new Date());
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
			repeatAlertsArray[id] = true;
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
			repeatAlertsArray[id] = false;
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
			for (var cntr:int = 0;cntr < repeatAlertsArray.length;cntr++) {
				if (repeatAlertsArray[cntr] == true) {
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
		
		private static function myTrace(log:String):void {
			Trace.myTrace("AlarmService.as", log);
		}
	}
}