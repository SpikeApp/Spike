package services
{
	import com.distriqt.extension.notifications.Notifications;
	import com.distriqt.extension.notifications.builders.NotificationBuilder;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import database.LocalSettings;
	
	import events.SpikeEvent;
	
	import feathers.controls.Alert;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	import starling.utils.SystemUtil;
	
	import ui.popups.AlertManager;
	
	import utils.BadgeBuilder;
	import utils.TimeSpan;
	import utils.Trace;
	
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("chartscreen")]
	[ResourceBundle("certificateservice")]
	
	public class CertificateService extends EventDispatcher
	{
		//Objects & Properties
		private static var _instance:CertificateService = new CertificateService();
		private static var serviceHalted:Boolean = false;
		private static var checkExpirationTimeout:uint;
		private static var checkExpirationInterval:uint;
		public static var certificateCreationDate:Date;
		public static var certificateExpirationDate:Date;
		public static var hasHealthKitCapabilities:Boolean = false;
		public static var hasiCloudCapabilities:Boolean = false;
		public static var fullEntitlements:String = "";
		public static var isFreeCertificate:Boolean = true;

		public function CertificateService()
		{
			if (_instance != null)
				throw new Error("Certificate is not meant to be instantiated");
		}
		
		public static function init():void
		{
			certificateCreationDate = SpikeANE.getCertificateCreationDate();
			certificateExpirationDate = SpikeANE.getCertificateExpirationDate();
			hasHealthKitCapabilities = SpikeANE.hasHealthKitEntitlements();
			hasiCloudCapabilities = SpikeANE.hasiCloudEntitlements();
			fullEntitlements = SpikeANE.getFullEntitlements();
			
			if (certificateCreationDate != null && certificateExpirationDate != null)
			{
				if (TimeSpan.fromDates(certificateCreationDate, certificateExpirationDate).days > 7)
				{
					isFreeCertificate = false;
				}
			}
			
			if (certificateExpirationDate != null)
			{
				checkExpirationTimeout = setTimeout(checkCertificateExpiration, TimeSpan.TIME_1_MINUTE);
				checkExpirationInterval = setInterval(checkCertificateExpiration, TimeSpan.TIME_1_HOUR);
			}
			
			//Register event listener for app halted
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
		}
		
		/**
		 * Public Methods
		 */
		public static function getFormattedTimeUntilExpiration():Object
		{
			var green:uint = 0x4bef0a;
			var orange:uint = 0xff671c;
			var red:uint = 0xff1c1c;
			
			if (certificateExpirationDate == null)
			{
				return { label: ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available'), color: red };
			}
			
			var now:Date = new Date();
			var timeSpan:TimeSpan = TimeSpan.fromDates(now, certificateExpirationDate);
			var totalDays:Number = timeSpan.days;
			var totalHours:Number = timeSpan.hours;
			var totalMinutes:Number = timeSpan.minutes;
			var totalSeconds:Number = timeSpan.totalSeconds;
			
			var expiredAbb:String = ModelLocator.resourceManagerInstance.getString('chartscreen','expired_certificate');
			var daysAbb:String = ModelLocator.resourceManagerInstance.getString('chartscreen','days_small_abbreviation_label');
			var hoursAbb:String = ModelLocator.resourceManagerInstance.getString('chartscreen','hours_small_abbreviation_label');
			var minutesAbb:String = ModelLocator.resourceManagerInstance.getString('chartscreen','minutes_small_abbreviation_label');
			
			if (timeSpan.totalSeconds < 0)
			{
				return { label: expiredAbb, color: red };
			}
			
			var time:String = "";
			
			if (totalDays > 0)
			{
				totalDays < 10 ? time += "0" + totalDays + daysAbb + " " : time += totalDays + daysAbb + " ";
			}
			
			if (totalHours > 0)
			{
				totalHours < 10 ? time += "0" + totalHours + hoursAbb + " " : time += totalHours + hoursAbb + " ";
			}
			
			totalMinutes < 10 ? time += "0" + totalMinutes + minutesAbb: time += totalMinutes + minutesAbb;
			
			var selectedColor:uint = red;
			if (isFreeCertificate)
			{
				if (totalDays < 1)
				{
					selectedColor = red;
				}
				else if (totalDays < 2)
				{
					selectedColor = orange;
				}
				else
				{
					selectedColor = green;
				}
			}
			else
			{
				if (totalDays < 3)
				{
					selectedColor = red;
				}
				else if (totalDays < 7)
				{
					selectedColor = orange;
				}
				else
				{
					selectedColor = green;
				}
			}
			
			return { label: time, color: selectedColor };
		}
		
		/**
		 * Private Methods
		 */
		private static function checkCertificateExpiration():void
		{
			if (certificateExpirationDate == null || certificateCreationDate == null || serviceHalted)
			{
				return;
			}
			
			var hoursTillExpiration:Number = TimeSpan.fromDates(new Date(), certificateExpirationDate).totalHours;
			var certificateHash:String = String(certificateCreationDate.valueOf());
			
			if (hoursTillExpiration <= 0 && LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_CERTIFICATE_NOTIFICATION_EXPIRED) != certificateHash)
			{
				//Expired
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_CERTIFICATE_NOTIFICATION_EXPIRED, certificateHash, true, false);
				
				var expiredAlert:Alert = AlertManager.showActionAlert
					(
						ModelLocator.resourceManagerInstance.getString('certificateservice', "expired_title"),
						ModelLocator.resourceManagerInstance.getString('certificateservice', "expired_message"),
						Number.NaN,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('certificateservice', "help_button"), triggered: onResignHelp },
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations', "ok_alert_button_label") }	
						]
					);
				expiredAlert.buttonGroupProperties.gap = 5;
				
				if (!SystemUtil.isApplicationActive)
				{
					//Notification
					var expiredNotificationBuilder:NotificationBuilder = new NotificationBuilder()
						.setCount(BadgeBuilder.getAppBadge())
						.setId(NotificationService.ID_FOR_CERTIFICATE_EXPIRATION_ALERT)
						.setAlert(ModelLocator.resourceManagerInstance.getString('certificateservice', "expired_title"))
						.setTitle(ModelLocator.resourceManagerInstance.getString('certificateservice', "expired_title"))
						.setBody(ModelLocator.resourceManagerInstance.getString('certificateservice', "expired_message"))
						.enableVibration(true)
						.enableLights(true)
						.setSound("default");
					
					Notifications.service.notify(expiredNotificationBuilder.build());
				}
			}
			else if (hoursTillExpiration <= 1 && LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_CERTIFICATE_NOTIFICATION_CRITICAL) != certificateHash)
			{
				//Critical
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_CERTIFICATE_NOTIFICATION_CRITICAL, certificateHash, true, false);
				
				var criticalAlert:Alert = AlertManager.showActionAlert
					(
						ModelLocator.resourceManagerInstance.getString('certificateservice', "critical_title"),
						ModelLocator.resourceManagerInstance.getString('certificateservice', "critical_message").replace("{expiration_time_do_not_transalte}", getFormattedTimeUntilExpiration().label),
						Number.NaN,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('certificateservice', "help_button"), triggered: onResignHelp },
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations', "ok_alert_button_label") }	
						]
					);
				criticalAlert.buttonGroupProperties.gap = 5;
				
				if (!SystemUtil.isApplicationActive)
				{
					//Notification
					var criticalNotificationBuilder:NotificationBuilder = new NotificationBuilder()
						.setCount(BadgeBuilder.getAppBadge())
						.setId(NotificationService.ID_FOR_CERTIFICATE_EXPIRATION_ALERT)
						.setAlert(ModelLocator.resourceManagerInstance.getString('certificateservice', "critical_title"))
						.setTitle(ModelLocator.resourceManagerInstance.getString('certificateservice', "critical_title"))
						.setBody(ModelLocator.resourceManagerInstance.getString('certificateservice', "critical_message").replace("{expiration_time_do_not_transalte}", getFormattedTimeUntilExpiration().label))
						.enableVibration(true)
						.enableLights(true)
						.setSound("default");
					
					Notifications.service.notify(criticalNotificationBuilder.build());
				}
			}
			else if (hoursTillExpiration <= 12 && LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_CERTIFICATE_NOTIFICATION_WARNING) != certificateHash)
			{
				//Warning
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_CERTIFICATE_NOTIFICATION_WARNING, certificateHash, true, false);
				
				var warningAlert:Alert = AlertManager.showActionAlert
					(
						ModelLocator.resourceManagerInstance.getString('certificateservice', "warning_title"),
						ModelLocator.resourceManagerInstance.getString('certificateservice', "warning_message").replace("{expiration_time_do_not_transalte}", getFormattedTimeUntilExpiration().label),
						Number.NaN,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('certificateservice', "help_button"), triggered: onResignHelp },
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations', "ok_alert_button_label") }	
						]
					);
				warningAlert.buttonGroupProperties.gap = 5;
				
				if (!SystemUtil.isApplicationActive)
				{
					//Notification
					var warningNotificationBuilder:NotificationBuilder = new NotificationBuilder()
						.setCount(BadgeBuilder.getAppBadge())
						.setId(NotificationService.ID_FOR_CERTIFICATE_EXPIRATION_ALERT)
						.setAlert(ModelLocator.resourceManagerInstance.getString('certificateservice', "warning_title"))
						.setTitle(ModelLocator.resourceManagerInstance.getString('certificateservice', "warning_title"))
						.setBody(ModelLocator.resourceManagerInstance.getString('certificateservice', "warning_message").replace("{expiration_time_do_not_transalte}", getFormattedTimeUntilExpiration().label))
						.enableVibration(true)
						.enableLights(true)
						.setSound("default");
					
					Notifications.service.notify(warningNotificationBuilder.build());
				}
			}
			else if (hoursTillExpiration <= 24 && LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_CERTIFICATE_NOTIFICATION_ALERT) != certificateHash)
			{
				//Alert
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_CERTIFICATE_NOTIFICATION_ALERT, certificateHash, true, false);
				
				var alertAlert:Alert = AlertManager.showActionAlert
					(
						ModelLocator.resourceManagerInstance.getString('certificateservice', "alert_title"),
						ModelLocator.resourceManagerInstance.getString('certificateservice', "alert_message").replace("{expiration_time_do_not_transalte}", getFormattedTimeUntilExpiration().label),
						Number.NaN,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('certificateservice', "help_button"), triggered: onResignHelp },
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations', "ok_alert_button_label") }	
						]
					);
				alertAlert.buttonGroupProperties.gap = 5;
				
				if (!SystemUtil.isApplicationActive)
				{
					//Notification
					var alertNotificationBuilder:NotificationBuilder = new NotificationBuilder()
						.setCount(BadgeBuilder.getAppBadge())
						.setId(NotificationService.ID_FOR_CERTIFICATE_EXPIRATION_ALERT)
						.setAlert(ModelLocator.resourceManagerInstance.getString('certificateservice', "alert_title"))
						.setTitle(ModelLocator.resourceManagerInstance.getString('certificateservice', "alert_title"))
						.setBody(ModelLocator.resourceManagerInstance.getString('certificateservice', "alert_message").replace("{expiration_time_do_not_transalte}", getFormattedTimeUntilExpiration().label))
						.enableVibration(true)
						.enableLights(true)
						.setSound("default");
					
					Notifications.service.notify(alertNotificationBuilder.build());
				}
			}
			else if (hoursTillExpiration <= 72 && !isFreeCertificate && LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_CERTIFICATE_NOTIFICATION_REMINDER_2) != certificateHash)
			{
				//Reminder 2
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_CERTIFICATE_NOTIFICATION_REMINDER_2, certificateHash, true, false);
				
				var reminder2Alert:Alert = AlertManager.showActionAlert
					(
						ModelLocator.resourceManagerInstance.getString('certificateservice', "reminder_title"),
						ModelLocator.resourceManagerInstance.getString('certificateservice', "reminder_message").replace("{expiration_time_do_not_transalte}", getFormattedTimeUntilExpiration().label),
						Number.NaN,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('certificateservice', "help_button"), triggered: onResignHelp },
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations', "ok_alert_button_label") }	
						]
					);
				reminder2Alert.buttonGroupProperties.gap = 5;
				
				if (!SystemUtil.isApplicationActive)
				{
					//Notification
					var reminder2NotificationBuilder:NotificationBuilder = new NotificationBuilder()
						.setCount(BadgeBuilder.getAppBadge())
						.setId(NotificationService.ID_FOR_CERTIFICATE_EXPIRATION_ALERT)
						.setAlert(ModelLocator.resourceManagerInstance.getString('certificateservice', "reminder_title"))
						.setTitle(ModelLocator.resourceManagerInstance.getString('certificateservice', "reminder_title"))
						.setBody(ModelLocator.resourceManagerInstance.getString('certificateservice', "reminder_message").replace("{expiration_time_do_not_transalte}", getFormattedTimeUntilExpiration().label))
						.enableVibration(true)
						.enableLights(true)
						.setSound("default");
					
					Notifications.service.notify(reminder2NotificationBuilder.build());
				}
			}
			else if (hoursTillExpiration <= 168 && !isFreeCertificate && LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_CERTIFICATE_NOTIFICATION_REMINDER_1) != certificateHash)
			{
				//Reminder 1
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_CERTIFICATE_NOTIFICATION_REMINDER_1, certificateHash, true, false);
				
				var reminder1Alert:Alert = AlertManager.showActionAlert
					(
						ModelLocator.resourceManagerInstance.getString('certificateservice', "reminder_title"),
						ModelLocator.resourceManagerInstance.getString('certificateservice', "reminder_message").replace("{expiration_time_do_not_transalte}", getFormattedTimeUntilExpiration().label),
						Number.NaN,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('certificateservice', "help_button"), triggered: onResignHelp },
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations', "ok_alert_button_label") }	
						]
					);
				reminder1Alert.buttonGroupProperties.gap = 5;
				
				if (!SystemUtil.isApplicationActive)
				{
					//Notification
					var reminder1NotificationBuilder:NotificationBuilder = new NotificationBuilder()
						.setCount(BadgeBuilder.getAppBadge())
						.setId(NotificationService.ID_FOR_CERTIFICATE_EXPIRATION_ALERT)
						.setAlert(ModelLocator.resourceManagerInstance.getString('certificateservice', "reminder_title"))
						.setTitle(ModelLocator.resourceManagerInstance.getString('certificateservice', "reminder_title"))
						.setBody(ModelLocator.resourceManagerInstance.getString('certificateservice', "reminder_message").replace("{expiration_time_do_not_transalte}", getFormattedTimeUntilExpiration().label))
						.enableVibration(true)
						.enableLights(true)
						.setSound("default");
					
					Notifications.service.notify(reminder1NotificationBuilder.build());
				}
			}
		}
		
		/**
		 * Event Listeners
		 */
		private static function onResignHelp(e:Event):void
		{
			navigateToURL(new URLRequest(""));
		}
		
		private static function onHaltExecution(e:SpikeEvent):void
		{
			myTrace("Stopping service...");
			
			clearTimeout(checkExpirationTimeout);
			clearInterval(checkExpirationInterval);
			serviceHalted = true;
		}
		
		/**
		 * Utility
		 */
		private static function myTrace(log:String):void 
		{
			Trace.myTrace("CertificateService.as", log);
		}
			
		/**
		 * Getters & Setters
		 */
		public static function get instance():CertificateService
		{
			return _instance;
		}
	}
}