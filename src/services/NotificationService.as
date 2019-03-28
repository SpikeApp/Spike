package services
{
	import com.distriqt.extension.core.Core;
	import com.distriqt.extension.notifications.AuthorisationStatus;
	import com.distriqt.extension.notifications.Notifications;
	import com.distriqt.extension.notifications.Service;
	import com.distriqt.extension.notifications.builders.ActionBuilder;
	import com.distriqt.extension.notifications.builders.CategoryBuilder;
	import com.distriqt.extension.notifications.builders.NotificationBuilder;
	import com.distriqt.extension.notifications.events.AuthorisationEvent;
	import com.distriqt.extension.notifications.events.NotificationEvent;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Timer;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.LocalSettings;
	
	import distriqtkey.DistriqtKey;
	
	import events.BlueToothServiceEvent;
	import events.CalibrationServiceEvent;
	import events.FollowerEvent;
	import events.NotificationServiceEvent;
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	
	import model.ModelLocator;
	
	import utils.BadgeBuilder;
	import utils.BgGraphBuilder;
	import utils.Trace;
	import services.bluetooth.CGMBluetoothService;
	
	/**
	 * This service<br>
	 * - registers for notifications<br>
	 * - defines id's<br>
	 * At the same time this service will at regular intervals set a notification for the end-user<br>
	 * each time again (period to be defined - probably in the settings) the notification will be reset later<br>
	 * Goal is that whenevever the application stops, also this service will not run anymore, hence the notification will expire, the user
	 * will know the application stopped and by just clicking it it will re-open and restart.
	 * 
	 * It also dispatches the notifications as NotificationServiceEvent 
	 */
	public class NotificationService extends EventDispatcher
	{
		
		[ResourceBundle("notificationservice")]
		[ResourceBundle("calibrationservice")]
		
		private static var _instance:NotificationService = new NotificationService();
		
		public static function get instance():NotificationService
		{
			return _instance;
		}
		
		
		private static var initialStart:Boolean = true;
		
		//Notification ID's
		/**
		 * for the notification with currently measured bg value<br>
		 * this is the always on notification
		 */
		public static const ID_FOR_BG_VALUE:int = 2;
		/**
		 * to request initial calibration
		 */
		public static const ID_FOR_REQUEST_CALIBRATION:int = 3;
		/**
		 * to request transmitter id 
		 */
		public static const ID_FOR_ENTER_TRANSMITTER_ID:int = 4;
		
		public static const ID_FOR_DEVICE_NOT_PAIRED:int = 5;
		
		public static const ID_FOR_LOW_ALERT:int = 6;
		public static const ID_FOR_HIGH_ALERT:int = 7;
		public static const ID_FOR_MISSED_READING_ALERT:int = 8;
		public static const ID_FOR_PHONEMUTED_ALERT:int = 9;
		public static const ID_FOR_BATTERY_ALERT:int = 10;
		public static const ID_FOR_CALIBRATION_REQUEST_ALERT:int = 11;
		public static const ID_FOR_VERY_LOW_ALERT:int = 12;
		public static const ID_FOR_VERY_HIGH_ALERT:int = 13;
		public static const ID_FOR_PATCH_READ_ERROR_BLUKON:int = 14;
		public static const ID_FOR_APP_UPDATE:int = 15; //used ?
		public static const ID_FOR_DEAD_G5_BATTERY_INFO:int = 16;
		public static const ID_FOR_BAD_PLACED_G5_G6_INFO:int = 17;
		public static const ID_FOR_OTHER_G5_APP:int = 18;
		public static const ID_FOR_APPLICATION_INACTIVE_ALERT:int = 19;
		public static const ID_FOR_DEAD_OR_EXPIRED_SENSOR_TRANSMITTER_PL:int = 20;
		public static const ID_FOR_HTTP_SERVER_DOWN:int = 21;
		public static const ID_FOR_SENSOR_NOT_DETECTED_MIAOMIAO:int = 22;
		public static const ID_FOR_LIBRE_SENSOR_14DAYS:int = 23;
		public static const ID_FOR_G5_RESET_DONE:int = 24;
		public static const ID_FOR_FAST_RISE_ALERT:int = 25;
		public static const ID_FOR_FAST_DROP_ALERT:int = 26;
		public static const ID_FOR_EXTENDED_BOLUS_ALERT:int = 27;
		public static const ID_FOR_NEW_APP_UPDATE_ALERT:int = 28;
		
		public static const ID_FOR_ALERT_LOW_CATEGORY:String = "LOW_ALERT_CATEGORY";
		public static const ID_FOR_ALERT_HIGH_CATEGORY:String = "HIGH_ALERT_CATEGORY";
		public static const ID_FOR_PHONE_MUTED_CATEGORY:String = "PHONE_MUTED_CATEGORY";
		public static const ID_FOR_ALERT_BATTERY_CATEGORY:String = "BATTERY_LEVEL_CATEGORY";
		public static const ID_FOR_ALERT_CALIBRATION_REQUEST_CATEGORY:String = "CALIBRATION_REQUEST_CATEGORY";
		public static const ID_FOR_ALERT_VERY_LOW_CATEGORY:String = "VERY_LOW_ALERT_CATEGORY";
		public static const ID_FOR_ALERT_VERY_HIGH_CATEGORY:String = "VERY_HIGH_ALERT_CATEGORY";
		public static const ID_FOR_ALERT_MISSED_READING_CATEGORY:String = "MISSED_READING_ALERT_CATEGORY";
		public static const ID_FOR_ALERT_FAST_RISE_CATEGORY:String = "FAST_RISE_ALERT_CATEGORY";
		public static const ID_FOR_ALERT_FAST_DROP_CATEGORY:String = "FAST_DROP_ALERT_CATEGORY";

		public static const ID_FOR_LOW_ALERT_SNOOZE_IDENTIFIER:String = "LOW_ALERT_SNOOZE_IDENTIFIER";
		public static const ID_FOR_HIGH_ALERT_SNOOZE_IDENTIFIER:String = "HIGH_ALERT_SNOOZE_IDENTIFIER";
		public static const ID_FOR_PHONE_MUTED_SNOOZE_IDENTIFIER:String = "PHONE_MUTED_SNOOZE_IDENTIFIER";
		public static const ID_FOR_BATTERY_LEVEL_ALERT_SNOOZE_IDENTIFIER:String = "BATTERY_LEVEL_SNOOZE_IDENTIFIER";
		public static const ID_FOR_CALIBRATION_REQUEST_ALERT_SNOOZE_IDENTIFIER:String = "CALIBRATION_REQUEST_SNOOZE_IDENTIFIER";
		public static const ID_FOR_VERY_LOW_ALERT_SNOOZE_IDENTIFIER:String = "VERY_LOW_ALERT_SNOOZE_IDENTIFIER";
		public static const ID_FOR_VERY_HIGH_ALERT_SNOOZE_IDENTIFIER:String = "VERY_HIGH_ALERT_SNOOZE_IDENTIFIER";
		public static const ID_FOR_MISSED_READING_ALERT_SNOOZE_IDENTIFIER:String = "MISSED_READING_ALERT_SNOOZE_IDENTIFIER";
		public static const ID_FOR_FAST_RISE_ALERT_SNOOZE_IDENTIFIER:String = "FAST_RISE_ALERT_SNOOZE_IDENTIFIER";
		public static const ID_FOR_FAST_DROP_ALERT_SNOOZE_IDENTIFIER:String = "FAST_DROP_ALERT_SNOOZE_IDENTIFIER";
		
		private static var timeStampSinceLastNotifForPatchReadError:Number = 0;
		public static var testTextToSpeechTimer:Timer;

		/**
		 * Always on notifications interval
		 */
		private static var alwaysOnNotificationsInterval:int = 3;
		private static var receivedReadings:int = 0;
		
		public function NotificationService()
		{
			if (_instance != null) {
				throw new Error("NotificationService class constructor can not be used");	
			}
		}
		
		private static function deviceNotPaired(event:Event):void {
			var titleText:String = ModelLocator.resourceManagerInstance.getString("notificationservice","device_not_paired_notification_title");
			var bodyText:String = ModelLocator.resourceManagerInstance.getString("notificationservice","device_not_paired_body_text_background");
			if (SpikeANE.appIsInForeground())
				bodyText = ModelLocator.resourceManagerInstance.getString("notificationservice","device_not_paired_body_text_foreground");
			Notifications.service.cancel(ID_FOR_DEVICE_NOT_PAIRED);
			Notifications.service.notify(
				new NotificationBuilder()
				.setCount(BadgeBuilder.getAppBadge())
				.setId(ID_FOR_DEVICE_NOT_PAIRED)
				.setAlert(titleText)
				.setTitle(titleText)
				.setBody(bodyText)
				.enableLights(true)
				.enableVibration(true)
				.build());
		}
		
		private static function glucosePatchReadError(event:Event):void {
			var titleText:String = ModelLocator.resourceManagerInstance.getString("notificationservice","glucose_patch_read_error_notification_title");
			var bodyText:String = ModelLocator.resourceManagerInstance.getString("notificationservice","glucose_patch_read_error_body_text");
			if ((new Date()).valueOf() - timeStampSinceLastNotifForPatchReadError > 5 * 60 * 1000) {
				
			} else {
				timeStampSinceLastNotifForPatchReadError = (new Date()).valueOf();
				Notifications.service.notify(
					new NotificationBuilder()
					.setCount(BadgeBuilder.getAppBadge())
					.setId(ID_FOR_PATCH_READ_ERROR_BLUKON)
					.setAlert(titleText)
					.setTitle(titleText)
					.setBody(bodyText)
					.enableLights(true)
					.enableVibration(true)
					.build());
			}
		}
		
		public static function init():void {
			if (!initialStart)
				return;
			else
				initialStart = false;
			
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			
			Core.init();
			Notifications.init(!ModelLocator.IS_IPAD ? DistriqtKey.distriqtKey : DistriqtKey.distriqtKeyIpad);
			if (!Notifications.isSupported) {
				return;
			}
			
			var service:Service = new Service();
			service.enableNotificationsWhenActive = true;
			
			service.categories.push( 
				new CategoryBuilder()
				.setIdentifier(ID_FOR_ALERT_LOW_CATEGORY)
				.addAction( 
					new ActionBuilder()
					.setTitle("Snooze")
					.setIdentifier(ID_FOR_LOW_ALERT_SNOOZE_IDENTIFIER)
					.build()
				)
				.build()
			);
			service.categories.push( 
				new CategoryBuilder()
				.setIdentifier(ID_FOR_ALERT_HIGH_CATEGORY)
				.addAction( 
					new ActionBuilder()
					.setTitle("Snooze")
					.setIdentifier(ID_FOR_HIGH_ALERT_SNOOZE_IDENTIFIER)
					.build()
				)
				.build()
			);
			service.categories.push( 
				new CategoryBuilder()
				.setIdentifier(ID_FOR_PHONE_MUTED_CATEGORY)
				.addAction( 
					new ActionBuilder()
					.setTitle("Snooze")
					.setIdentifier(ID_FOR_PHONE_MUTED_SNOOZE_IDENTIFIER)
					.build()
				)
				.build()
			);
			service.categories.push( 
				new CategoryBuilder()
				.setIdentifier(ID_FOR_ALERT_BATTERY_CATEGORY)
				.addAction( 
					new ActionBuilder()
					.setTitle("Snooze")
					.setIdentifier(ID_FOR_BATTERY_LEVEL_ALERT_SNOOZE_IDENTIFIER)
					.build()
				)
				.build()
			);
			service.categories.push( 
				new CategoryBuilder()
				.setIdentifier(ID_FOR_ALERT_CALIBRATION_REQUEST_CATEGORY)
				.addAction( 
					new ActionBuilder()
					.setTitle("Snooze")
					.setIdentifier(ID_FOR_CALIBRATION_REQUEST_ALERT_SNOOZE_IDENTIFIER)
					.build()
				)
				.build()
			);
			service.categories.push( 
				new CategoryBuilder()
				.setIdentifier(ID_FOR_ALERT_VERY_LOW_CATEGORY)
				.addAction( 
					new ActionBuilder()
					.setTitle("Snooze")
					.setIdentifier(ID_FOR_VERY_LOW_ALERT_SNOOZE_IDENTIFIER)
					.build()
				)
				.build()
			);
			service.categories.push( 
				new CategoryBuilder()
				.setIdentifier(ID_FOR_ALERT_VERY_HIGH_CATEGORY)
				.addAction( 
					new ActionBuilder()
					.setTitle("Snooze")
					.setIdentifier(ID_FOR_VERY_HIGH_ALERT_SNOOZE_IDENTIFIER)
					.build()
				)
				.build()
			);
			service.categories.push(
				new CategoryBuilder()
				.setIdentifier(ID_FOR_ALERT_MISSED_READING_CATEGORY)
				.addAction( 
					new ActionBuilder()
					.setTitle("Snooze")
					.setIdentifier(ID_FOR_MISSED_READING_ALERT_SNOOZE_IDENTIFIER)
					.build()
				)
				.build()
			);
			service.categories.push( 
				new CategoryBuilder()
				.setIdentifier(ID_FOR_ALERT_FAST_RISE_CATEGORY)
				.addAction( 
					new ActionBuilder()
					.setTitle("Snooze")
					.setIdentifier(ID_FOR_FAST_RISE_ALERT_SNOOZE_IDENTIFIER)
					.build()
				)
				.build()
			);
			service.categories.push( 
				new CategoryBuilder()
				.setIdentifier(ID_FOR_ALERT_FAST_DROP_CATEGORY)
				.addAction( 
					new ActionBuilder()
					.setTitle("Snooze")
					.setIdentifier(ID_FOR_FAST_DROP_ALERT_SNOOZE_IDENTIFIER)
					.build()
				)
				.build()
			);
			
			Notifications.service.setup(service);
			
			alwaysOnNotificationsInterval = int(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_NOTIFICATION_INTERVAL));
			
			CGMBluetoothService.instance.addEventListener(BlueToothServiceEvent.DEVICE_NOT_PAIRED, deviceNotPaired);
			CGMBluetoothService.instance.addEventListener(BlueToothServiceEvent.GLUCOSE_PATCH_READ_ERROR, glucosePatchReadError);
			
			//var object:Object = Notifications.service.authorisationStatus();
			switch (Notifications.service.authorisationStatus())
			{
				case AuthorisationStatus.AUTHORISED:
					// This device has been authorised.
					// You can register this device and expect to display notifications
					register();
					break;
				
				case AuthorisationStatus.DENIED:
				case AuthorisationStatus.NOT_DETERMINED:
					// You are yet to ask for authorisation to display notifications
					// At this point you should consider your strategy to get your user to authorise
					// notifications by explaining what the application will provide
					Notifications.service.addEventListener(AuthorisationEvent.CHANGED, authorisationChangedHandler);
					Notifications.service.requestAuthorisation();
					break;
				
			}
			
			function authorisationChangedHandler(event:AuthorisationEvent):void
			{
				switch (event.status) {
					case AuthorisationStatus.AUTHORISED:
						// This device has been authorised.
						// You can register this device and expect to display notifications
						register();
						break;
				}
				
				_instance.dispatchEvent(new NotificationServiceEvent(NotificationServiceEvent.NOTIFICATION_SERVICE_INITIATED_EVENT));
			}
			
			/**
			 * will obviously register and also add eventlisteners
			 */
			function register():void {
				Notifications.service.addEventListener(NotificationEvent.NOTIFICATION_SELECTED, notificationSelectedHandler);
				Notifications.service.addEventListener(NotificationEvent.NOTIFICATION, notificationHandler);
				Notifications.service.addEventListener(NotificationEvent.ACTION, notificationActionHandler);
				CalibrationService.instance.addEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, updateBgNotification);
				TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, updateBgNotification);
				NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, updateBgNotification);
				DexcomShareService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, updateBgNotification);
				Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, appInForeGround);
				Notifications.service.register();
				LocalSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onLocalSettingsChanged);
				CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onCommonSettingsChanged);
			}
		}
		
		private static function onLocalSettingsChanged(event:SettingsServiceEvent):void
		{
			if (event.data == LocalSettings.LOCAL_SETTING_ALWAYS_ON_APP_BADGE || (event.data == LocalSettings.LOCAL_SETTING_APP_BADGE_MMOL_MULTIPLIER_ON && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true"))
			{
				Notifications.service.setBadgeNumber( BadgeBuilder.getAppBadge() );
			}
			else if (event.data == LocalSettings.LOCAL_SETTING_ALWAYS_ON_NOTIFICATION_INTERVAL)
			{
				alwaysOnNotificationsInterval = int(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_NOTIFICATION_INTERVAL));
			}
		}
		
		private static function onCommonSettingsChanged(event:SettingsServiceEvent):void
		{
			if (event.data == CommonSettings.COMMON_SETTING_DO_MGDL)
			{
				Notifications.service.setBadgeNumber( BadgeBuilder.getAppBadge() );
			}
		}
		
		private static function appInForeGround(event:Event):void {
			myTrace("in appInForeGround, setting systemIdleMode = SystemIdleMode.NORMAL");
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
		}
		
		private static function notificationSelectedHandler(event:NotificationEvent):void {
			myTrace("in notificationSelectedHandler at " + (new Date()).toLocaleTimeString());
			var notificationServiceEvent:NotificationServiceEvent = new NotificationServiceEvent(NotificationServiceEvent.NOTIFICATION_SELECTED_EVENT);
			notificationServiceEvent.data = event;
			_instance.dispatchEvent(notificationServiceEvent);
		}
		
		private static function notificationHandler(event:NotificationEvent):void {
			myTrace("in notificationHandler at " + (new Date()).toLocaleTimeString());
			var notificationServiceEvent:NotificationServiceEvent = new NotificationServiceEvent(NotificationServiceEvent.NOTIFICATION_EVENT);
			notificationServiceEvent.data = event;
			_instance.dispatchEvent(notificationServiceEvent);
		}
		
		private static function notificationActionHandler(event:NotificationEvent):void {
			myTrace("in notificationActionHandler at " + (new Date()).toLocaleTimeString());
			var notificationServiceEvent:NotificationServiceEvent = new NotificationServiceEvent(NotificationServiceEvent.NOTIFICATION_ACTION_EVENT);
			notificationServiceEvent.data = event;
			_instance.dispatchEvent(notificationServiceEvent);
		}
		
		public static function updateBgNotification(be:Event = null):void {
			myTrace("in updateBgNotification");
			Notifications.service.cancel(ID_FOR_BG_VALUE);
			
			receivedReadings++;
			var lastBgReading:BgReading;
			
			//start with bgreading notification
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_NOTIFICATION) == "true" && SpikeANE.appIsInBackground() && ((receivedReadings - 2) % alwaysOnNotificationsInterval == 0)) {
				myTrace("in updateBgNotification notificatoin always on and not in foreground");
				if (Calibration.allForSensor().length >= 2 || CGMBlueToothDevice.isFollower()) {
					lastBgReading = BgReading.lastNoSensor(); 
					var valueToShow:String = "";
					myTrace("in updateBgNotification Calibration.allForSensor().length >= 2");
					if (lastBgReading != null) {
						myTrace("in updateBgNotification lastbgreading != null");
						if ((new Date()).valueOf() - lastBgReading.timestamp < 4.5 * 60 * 1000) {
							if (lastBgReading.calculatedValue != 0) {
								if ((new Date().getTime()) - (60000 * 11) - lastBgReading.timestamp > 0) {
									valueToShow = "---"
								} else {
									valueToShow = BgGraphBuilder.unitizedString(lastBgReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
									myTrace("in updateBgNotification value to show calculated");
									if (!lastBgReading.hideSlope) {
										valueToShow += " " + lastBgReading.slopeArrow();
									}
									
									valueToShow += " " + BgGraphBuilder.unitizedDeltaString(true, true);
								}
							} else {
								//not giving notification if it's older than 4,5 minutes
								//this can be the case for follower mode
								myTrace("in updateBgNotification, timestamp of lastbgreading is older than 4.5 minutes");
								return;
							}
						}
					} else {
						valueToShow = "---"
					}
					
					if (valueToShow != "" && valueToShow != " ")
					{
						Notifications.service.notify(
							new NotificationBuilder()
							.setCount(BadgeBuilder.getAppBadge())
							.setId(NotificationService.ID_FOR_BG_VALUE)
							.setAlert(valueToShow)
							.setTitle(valueToShow)
							.setBody(" ")
							.setSound("")
							.enableVibration(false)
							.enableLights(false)
							.build());
					}
				}
			}
			else if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_APP_BADGE) == "true") 
			{	
				//App badge
				myTrace("in updateBgNotification app badge on, local notifications off and not in foreground");
				if (Calibration.allForSensor().length >= 2 || CGMBlueToothDevice.isFollower()) {
					lastBgReading = BgReading.lastNoSensor(); 
					myTrace("in updateBgNotification Calibration.allForSensor().length >= 2, setting app badge");
					
					Notifications.service.setBadgeNumber( BadgeBuilder.getAppBadge() );
				}
			}
		}
		
		public static function notificationIdToText(id:int):String 
		{
			var returnValue:String = "notification id unknown";
			
			if (id == ID_FOR_BG_VALUE)
				returnValue = "ID_FOR_BG_VALUE";
			else if (id == ID_FOR_REQUEST_CALIBRATION)
				returnValue = "ID_FOR_REQUEST_CALIBRATION";
			else if (id == ID_FOR_ENTER_TRANSMITTER_ID)
				returnValue = "ID_FOR_ENTER_TRANSMITTER_ID";
			else if (id == ID_FOR_DEVICE_NOT_PAIRED)
				returnValue = "ID_FOR_DEVICE_NOT_PAIRED";
			else if (id == ID_FOR_LOW_ALERT)
				returnValue = "ID_FOR_LOW_ALERT";
			else if (id == ID_FOR_HIGH_ALERT)
				returnValue = "ID_FOR_HIGH_ALERT";
			else if (id == ID_FOR_MISSED_READING_ALERT)
				returnValue = "ID_FOR_MISSED_READING_ALERT";
			else if (id == ID_FOR_PHONEMUTED_ALERT)
				returnValue = "ID_FOR_PHONEMUTED_ALERT";
			else if (id == ID_FOR_BATTERY_ALERT)
				returnValue = "ID_FOR_BATTERY_ALERT";
			else if (id == ID_FOR_CALIBRATION_REQUEST_ALERT)
				returnValue = "ID_FOR_CALIBRATION_REQUEST_ALERT";
			else if (id == ID_FOR_VERY_LOW_ALERT)
				returnValue = "ID_FOR_VERY_LOW_ALERT";
			else if (id == ID_FOR_VERY_HIGH_ALERT)
				returnValue = "ID_FOR_VERY_HIGH_ALERT";
			else if (id == ID_FOR_PATCH_READ_ERROR_BLUKON)
				returnValue = "ID_FOR_PATCH_READ_ERROR_BLUKON";
			else if (id == ID_FOR_APP_UPDATE)
				returnValue = "ID_FOR_APP_UPDATE";
			else if (id == ID_FOR_DEAD_G5_BATTERY_INFO)
				returnValue = "ID_FOR_DEAD_G5_BATTERY_INFO";
			else if (id == ID_FOR_BAD_PLACED_G5_G6_INFO)
				returnValue = "ID_FOR_BAD_PLACED_G5_INFO";
			else if (id == ID_FOR_OTHER_G5_APP)
				returnValue = "ID_FOR_OTHER_G5_APP";
			else if (id == ID_FOR_APPLICATION_INACTIVE_ALERT)
				returnValue = "ID_FOR_APPLICATION_INACTIVE_ALERT";
			else if (id == ID_FOR_DEAD_OR_EXPIRED_SENSOR_TRANSMITTER_PL)
				returnValue = "ID_FOR_DEAD_OR_EXPIRED_SENSOR_TRANSMITTER_PL";
			else if (id == ID_FOR_HTTP_SERVER_DOWN)
				returnValue = "ID_FOR_HTTP_SERVER_DOWN";
			else if (id == ID_FOR_SENSOR_NOT_DETECTED_MIAOMIAO)
				returnValue = "ID_FOR_SENSOR_NOT_DETECTED_MIAOMIAO";
			else if (id == ID_FOR_LIBRE_SENSOR_14DAYS)
				returnValue = "ID_FOR_LIBRE_SENSOR_14DAYS";
			else if (id == ID_FOR_FAST_RISE_ALERT)
				returnValue = "ID_FOR_FAST_RISE_ALERT";
			else if (id == ID_FOR_FAST_DROP_ALERT)
				returnValue = "ID_FOR_FAST_DROP_ALERT";
			return returnValue;
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
			CGMBluetoothService.instance.removeEventListener(BlueToothServiceEvent.DEVICE_NOT_PAIRED, deviceNotPaired);
			CGMBluetoothService.instance.removeEventListener(BlueToothServiceEvent.GLUCOSE_PATCH_READ_ERROR, glucosePatchReadError);
			Notifications.service.removeEventListener(NotificationEvent.NOTIFICATION_SELECTED, notificationSelectedHandler);
			Notifications.service.removeEventListener(NotificationEvent.NOTIFICATION, notificationHandler);
			Notifications.service.removeEventListener(NotificationEvent.ACTION, notificationActionHandler);
			CalibrationService.instance.removeEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, updateBgNotification);
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, updateBgNotification);
			NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, updateBgNotification);
			DexcomShareService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, updateBgNotification);
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_FOREGROUND, appInForeGround);
			LocalSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, onLocalSettingsChanged);
			CommonSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, onCommonSettingsChanged);
			
			myTrace("Service stopped!");
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("NotificationService.as", log);
		}
	}
}