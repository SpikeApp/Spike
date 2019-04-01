package services
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.navigateToURL;
	
	import cryptography.Keys;
	
	import database.CommonSettings;
	import database.LocalSettings;
	
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	
	import feathers.controls.Alert;
	import feathers.layout.HorizontalAlign;
	
	import model.ModelLocator;
	
	import network.NetworkConnector;
	
	import starling.events.Event;
	
	import ui.popups.AlertManager;
	
	import utils.TimeSpan;
	import utils.Trace;
	
	[ResourceBundle('updateservice')]
	[ResourceBundle('globaltranslations')]

	public class AppCenterService
	{
		//Properties
		private static var latestVersion:String = "";
		private static var lastReminded:Number = 0;
		private static var lastChecked:Number = 0;
		private static var serviceHalted:Boolean = false;
		private static var serviceActive:Boolean = false;
		
		public function AppCenterService()
		{
			throw new Error("AppCenterService class is not meant to be instantiated!");	
		}
		
		public static function init():void
		{
			//Listen for settings changed
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
			
			//Activate Service
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_CENTER_UPDATE_NOTIFICATIONS_ON) == "true")
				activateService();
		}
		
		private static function activateService():void
		{	
			myTrace("Activating service...");
			
			serviceActive = true;
			
			//Register event listener for app halted
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			
			//Register event listener for app in foreground
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, onApplicationActivated);
		}
		
		private static function deactivateService():void
		{
			myTrace("Deactivating service...");
			
			serviceActive = false;
			
			//Unregister event listener for app halted
			Spike.instance.removeEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			
			//Unregister event listener for app in foreground
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_FOREGROUND, onApplicationActivated);
		}
		
		private static function checkUpdate():void
		{
			//Validation
			if (serviceHalted)
				return;
			
			myTrace("Checking App Center Updates...");
			
			const API_URL:String = !ModelLocator.IS_IPAD ? "https://api.appcenter.ms/v0.1/apps/Nightscout-Foundation/Spike/distribution_groups/Spike%20Users/releases" : "https://api.appcenter.ms/v0.1/apps/Nightscout-Foundation/Spike-for-iPad/distribution_groups/Spike%20Users/releases";
			
			NetworkConnector.createAppCenterConnector(
				API_URL, 
				Keys.APP_CENTER_API_SECRET, 
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
		private static function onApplicationActivated(event:flash.events.Event = null):void
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
				var releasesList:Array = JSON.parse(response) as Array;
				if (releasesList != null && releasesList.length > 0 && releasesList[0] != null && releasesList[0].version != null)
				{
					latestVersion = releasesList[0].version as String;
					if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APPLICATION_VERSION) != "x.x.x" && latestVersion != CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_UPDATE_IGNORE_UPDATE) && versionAIsSmallerThanB(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APPLICATION_VERSION), latestVersion))
					{
						//There's an update in App Center
						myTrace("Notifying user of new App Center update! New version: " + latestVersion);
						
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
					}
					else
						myTrace("Not updating. User already has the latest version!");
				}
				
				lastChecked = new Date().valueOf();
			} 
			catch(error:Error) 
			{
				myTrace("Error parsing App Center API response! Error: " + error.message);
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
			navigateToURL(new URLRequest(!ModelLocator.IS_IPAD ? "https://install.appcenter.ms/orgs/Nightscout-Foundation/apps/Spike" : "https://install.appcenter.ms/orgs/Nightscout-Foundation/apps/Spike-for-iPad"));
		}
		
		private static function onConnectionFailed(error:Error, mode:String):void
		{
			myTrace("Failed to connect to App Center API! Error: " + error.message);
		}
		
		private static function onSettingsChanged(event:SettingsServiceEvent):void 
		{
			//Check if an update check can be made
			if (event.data == CommonSettings.COMMON_SETTING_APP_CENTER_UPDATE_NOTIFICATIONS_ON) 
			{
				myTrace("Settings changed! App Center update checker is now " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_CENTER_UPDATE_NOTIFICATIONS_ON));
				
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
			Trace.myTrace("AppCenterService.as", log);
		}
	}
}