package services
{
	import com.distriqt.extension.notifications.Notifications;
	import com.distriqt.extension.notifications.builders.NotificationBuilder;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.navigateToURL;
	import flash.utils.setTimeout;
	
	import database.CommonSettings;
	import database.LocalSettings;
	
	import events.FollowerEvent;
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	
	import feathers.controls.Alert;
	import feathers.layout.HorizontalAlign;
	
	import model.ModelLocator;
	
	import network.NetworkConnector;
	
	import starling.events.Event;
	import starling.utils.SystemUtil;
	
	import ui.popups.AlertManager;
	
	import utils.BadgeBuilder;
	import utils.TimeSpan;
	import utils.Trace;
	
	[ResourceBundle('updateservice')]
	[ResourceBundle('globaltranslations')]

	public class IgnitionUpdateService
	{
		//Properties
		private static var latestVersion:String = "";
		private static var updateURL:String = "";
		private static var lastReminded:Number = 0;
		private static var lastChecked:Number = 0;
		private static var serviceHalted:Boolean = false;
		private static var serviceActive:Boolean = false;
		
		public function IgnitionUpdateService()
		{
			throw new Error("IgnitionUpdateService class is not meant to be instantiated!");	
		}
		
		public static function init():void
		{
			//Listen for settings changed
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
			
			//Activate Service
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_CENTER_UPDATE_NOTIFICATIONS_ON) == "true")
				activateService();
			
			setTimeout(displayChangeLog, TimeSpan.TIME_5_SECONDS);
		}
		
		private static function displayChangeLog():void
		{
			var currentAppVersion:String = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APPLICATION_VERSION);
			var lastChangelogVersion:String = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_LAST_SHOWN_CHANGELOG);
			
			if (lastChangelogVersion != "" && lastChangelogVersion != "x.x.x" && currentAppVersion != "x.x.x" && versionAIsSmallerThanB(lastChangelogVersion, currentAppVersion))
			{
				var alert:Alert = AlertManager.showActionAlert
				(
					ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_changelog"),
					ModelLocator.resourceManagerInstance.getString('updateservice', "changelog_request_message").replace("{app_version_do_not_translate_this_word}", currentAppVersion),
					Number.NaN,
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations', "no_uppercase") },
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations', "yes_uppercase"), triggered: onDisplayChangelog }	
					]
				);
				alert.buttonGroupProperties.gap = 0;
				alert.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
			}
			
			if (currentAppVersion != lastChangelogVersion)
			{
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_LAST_SHOWN_CHANGELOG, currentAppVersion, true, false);
			}
		}
		
		private static function onDisplayChangelog(e:starling.events.Event):void
		{
			//Display changelog
			navigateToURL(new URLRequest("https://github.com/SpikeApp/Spike/wiki/Changelog"));
		}
		
		private static function activateService():void
		{	
			myTrace("Activating service...");
			
			serviceActive = true;
			
			//Register event listener for app halted
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			
			//Register event listener for new reading
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBGReadingReceived, false, -900, true);
			NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBGReadingReceived, false, -900, true);
			DexcomShareService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBGReadingReceived, false, -900, true);
		}
		
		private static function deactivateService():void
		{
			myTrace("Deactivating service...");
			
			serviceActive = false;
			
			//Unregister event listener for app halted
			Spike.instance.removeEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			
			//Unregister event listener for app in foreground
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_FOREGROUND, onBGReadingReceived);
		}
		
		private static function checkUpdate():void
		{
			//Validation
			if (serviceHalted)
				return;
			
			myTrace("Checking App Updates...");
			
			const API_URL:String = "https://spike-app.com/app/latest_ignition_update.json";
			
			NetworkConnector.createSpikeUpdateConnector(
				API_URL, 
				URLRequestMethod.GET, 
				null, 
				null, 
				onUpdateResponse, 
				onConnectionFailed
			);
		}
		
		/**
		 * Event Listeners
		 */
		private static function onBGReadingReceived(event:flash.events.Event = null):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			//App is in foreground. Let's see if we can make an update
			//but not the very first start of the app, otherwise there's too many pop ups
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_UPDATE_SERVICE_INITIALCHECK) == "true") {
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_UPDATE_SERVICE_INITIALCHECK, "false");
				myTrace("in onApplicationActivated, not doing update check at app startup");
				return;
			}
			
			//Check updates (if possible)
			var nowDate:Date = new Date();
			var now:Number = nowDate.valueOf();
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_ENABLED) == "true")
			{
				var currentHour:Number = nowDate.hours;
				var currentMinutes:Number = nowDate.minutes;
				var quiteStartHour:Number = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_START_HOUR));
				var quietStartMinutes:Number = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_START_MINUTES));
				var quietEndHour:Number = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_END_HOUR));
				var quietEndMinutes:Number = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_END_MINUTES));
				
				if ((currentHour >= quiteStartHour && currentMinutes >= quietStartMinutes) || (currentHour <= quietEndHour && currentMinutes <= quietEndMinutes))
				{
					myTrace("in onApplicationActivated, device in quiet time, aborting!");
					return;
				}
			}
			
			if (now - lastReminded >= TimeSpan.TIME_24_HOURS && now - lastChecked >= TimeSpan.TIME_1_HOUR)
				checkUpdate();
		}
		
		private static function onUpdateResponse(e:flash.events.Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			myTrace("In onUpdateResponse!");
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(flash.events.Event.COMPLETE, onUpdateResponse);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onConnectionFailed);
			loader = null;
			
			try
			{
				var updateProperties:Object = JSON.parse(response) as Object;
				if (updateProperties != null && updateProperties.version != null && updateProperties.url != null)
				{
					updateURL = updateProperties.url as String;
					latestVersion = updateProperties.version as String;
					if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APPLICATION_VERSION) != "x.x.x" && latestVersion != CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_UPDATE_IGNORE_UPDATE) && versionAIsSmallerThanB(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APPLICATION_VERSION), latestVersion))
					{
						//There's an update in App Center
						myTrace("Notifying user of new Ignition update! New version: " + latestVersion);
						
						var alert:Alert = AlertManager.showActionAlert
						(
							ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_title"),
							ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_preversion_message") + " " + latestVersion + " " + ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_postversion_message") + ".",
							Number.NaN,
							[
								{ label: ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_remind_later"), triggered: onRemindLater },
								{ label: ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_ignore_update"), triggered: onIgnoreUpdate },
								{ label: ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_update_button_label"), triggered: onUpdate }	
							]
						);
						alert.buttonGroupProperties.gap = 0;
						alert.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
						
						if (!SystemUtil.isApplicationActive)
						{
							//Notification
							var notificationBuilder:NotificationBuilder = new NotificationBuilder()
								.setCount(BadgeBuilder.getAppBadge())
								.setId(NotificationService.ID_FOR_NEW_APP_UPDATE_ALERT)
								.setAlert(ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_title"))
								.setTitle(ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_title"))
								.setBody(ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_preversion_message") + " " + latestVersion + " " + ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_postversion_message") + ".")
								.enableVibration(true)
								.enableLights(true)
								.setSound("default");
							
							Notifications.service.notify(notificationBuilder.build());
						}
					}
					else
					{
						myTrace("Not updating. User already has the latest version!");
					}
				}
				
				lastChecked = new Date().valueOf();
			} 
			catch(error:Error) 
			{
				myTrace("Error parsing Update API response! Error: " + error.message);
			}
		}
		
		private static function onRemindLater(e:starling.events.Event):void
		{
			//Update properties
			lastReminded = new Date().valueOf();
		}
		
		private static function onIgnoreUpdate(e:starling.events.Event):void
		{
			//Add ignored version to database settings
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_APP_UPDATE_IGNORE_UPDATE, latestVersion as String);
		}
		
		private static function onUpdate(e:starling.events.Event):void
		{
			//Go to App Center control panel 
			navigateToURL(new URLRequest(updateURL));
		}
		
		private static function onConnectionFailed(error:Error, mode:String):void
		{
			myTrace("Failed to connect to Update API! Error: " + error.message);
		}
		
		private static function onSettingsChanged(event:SettingsServiceEvent):void 
		{
			//Check if an update check can be made
			if (event.data == CommonSettings.COMMON_SETTING_APP_CENTER_UPDATE_NOTIFICATIONS_ON) 
			{
				myTrace("Settings changed! Ignition update checker is now " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_CENTER_UPDATE_NOTIFICATIONS_ON));
				
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_CENTER_UPDATE_NOTIFICATIONS_ON) == "true")
				{
					if (!serviceActive)
						activateService();
				}
				else
				{
					if (serviceActive)
						deactivateService();
				}
			}
		}
		
		private static function onHaltExecution(e:SpikeEvent):void
		{
			myTrace("Stopping service...");
			
			CommonSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
			
			serviceHalted = true;
			deactivateService();
		}
		
		/**
		 * Utility
		 */
		private static function versionAIsSmallerThanB(versionA:String, versionB:String):Boolean 
		{
			var versionaSplitted:Array = versionA.split(".");
			var versionbSplitted:Array = versionB.split(".");
			if (new Number(versionaSplitted[0]) < new Number(versionbSplitted[0]))
				return true;
			if (new Number(versionaSplitted[0]) > new Number(versionbSplitted[0]))
				return false;
			if (new Number(versionaSplitted[1]) < new Number(versionbSplitted[1]))
				return true;
			if (new Number(versionaSplitted[1]) > new Number(versionbSplitted[1]))
				return false;
			if (new Number(versionaSplitted[2]) < new Number(versionbSplitted[2]))
				return true;
			if (new Number(versionaSplitted[2]) > new Number(versionbSplitted[2]))
				return false;
			return false;
		}
		
		private static function myTrace(log:String):void 
		{
			Trace.myTrace("IgnitionUpdateService.as", log);
		}
	}
}