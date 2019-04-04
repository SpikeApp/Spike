package services
{
	import com.distriqt.extension.networkinfo.NetworkInfo;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.navigateToURL;
	
	import database.LocalSettings;
	
	import events.SpikeEvent;
	
	import feathers.controls.Alert;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.popups.AlertManager;
	
	import utils.SpikeJSON;
	import utils.TimeSpan;
	import utils.Trace;
	
	[ResourceBundle('globaltranslations')]
	
	public class RemoteAlertService
	{
		// Constants
		private static var remoteAlertURL:String;
		
		//Variables 
		private static var initialStart:Boolean = true;
		private static var awaitingLoadResponse:Boolean = false;
		private static var serviceHalted:Boolean = false;
		
		public function RemoteAlertService()
		{
			throw new Error("RemoteAlertService class constructor can not be used");	
		}
		
		//Start Engine
		public static function init():void
		{
			myTrace("RemoteAlertService initiated!");
			
			remoteAlertURL = !ModelLocator.IS_IPAD ? "https://spike-app.com/app/global_alert.json" : "https://spike-app.com/app/global_alert_ipad.json"
			
			//Setup Event Listeners
			createEventListeners();
		}
		
		/**
		 * Functionality
		 */
		private static function createEventListeners():void
		{
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			
			//Register event listener for app in foreground
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, onApplicationActivated);
		}
		
		private static function getRemoteAlert():void
		{
			//Validation
			if (serviceHalted)
				return;
			
			myTrace("in getRemoteAlert");
			
			if (!NetworkInfo.networkInfo.isReachable())
			{
				myTrace("No internet connection. Aborting");
				return;
			}
			
			//Create and configure loader and url request
			var request:URLRequest = new URLRequest(remoteAlertURL);
			request.method = URLRequestMethod.GET;
			var loader:URLLoader = new URLLoader(); 
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			
			//Make connection and define listener
			loader.addEventListener(flash.events.Event.COMPLETE, onResponseReceived);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onResponseReceived);
			awaitingLoadResponse = true;
			
			try 
			{
				loader.load(request);
			}
			catch (error:Error) 
			{
				myTrace("Unable to load Spike Remote Alert API: " + error.getStackTrace().toString());
			}
		}
		
		private static function canDoCheck():Boolean
		{
			//Validation
			if (serviceHalted)
				return false;
			
			/**
			 * Uncomment next line and comment the other one for testing
			 * We are hardcoding a timestamp of more than 1 day ago for testing purposes otherwise the update popup wont fire 
			 */
			//var lastUpdateCheckStamp:Number = 1511014007853;
			var lastRemoteAlertCheckStamp:Number = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_REMOTE_ALERT_LAST_CHECK_TIMESTAMP));
			var currentTimeStamp:Number = (new Date()).valueOf();
			
			//If it has been more than 1 day since the last check for emote alerts or it's the first time the app checks for remote alerts
			if(currentTimeStamp - lastRemoteAlertCheckStamp > TimeSpan.TIME_24_HOURS)
			{
				myTrace("App can check for remote alerts");
				return true;
			}
			
			myTrace("App can not check for new remote alerts");
			return false;
		}
		
		/**
		 * Event Listeners
		 */
		protected static function onResponseReceived(event:flash.events.Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			if (awaitingLoadResponse) 
			{
				myTrace("in onResponseReceived");
				awaitingLoadResponse = false;
			} 
			else
				return;
			
			if (!event.target) 
			{
				myTrace("no event.target");
				return;
			}
			
			//Parse response and validate presence of mandatory objects 
			var loader:URLLoader = URLLoader(event.target);
			if (!loader.data) 
			{
				myTrace("no loader.data");
				return;
			}
			
			if (String(loader.data).indexOf ("id") == -1)
			{
				myTrace("server response empty");
				return;
			}
			
			//var data:Object = JSON.parse(loader.data as String);
			var data:Object = SpikeJSON.parse(loader.data as String);
			if (data.id == null) 
			{
				myTrace("no data.id");
				return;
			} 
			else if (data.message == null) 
			{
				myTrace("no data.message");
				return;
			}
			
			//Update database
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_REMOTE_ALERT_LAST_CHECK_TIMESTAMP, String((new Date()).valueOf()));
			
			var lastIDCheck:Number = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_REMOTE_ALERT_LAST_ID));
			var currentIDCheck:Number = Number(data.id);
			
			if (lastIDCheck == 0)
			{
				myTrace("Spike has just been installed. Ignoring all previous remote alerts.");
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_REMOTE_ALERT_LAST_ID, String(currentIDCheck));
				return;
			}
			else if (lastIDCheck >= currentIDCheck)
			{
				myTrace("This alert has already been shown to the user. Abort!");
				return;
			}
			else
			{
				//Backup iCloud database if certificate has been revoked
				if (String(data.message).indexOf("revoked") != -1)
				{
					//Backup to iCloud
					if (ICloudService.serviceStartedAt != 0)
					{
						ICloudService.backupDatabase();
					}
					
					//Show action alert to the user with a link to the revoke guide
					var alert:Alert = AlertManager.showActionAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations', "warning_alert_title"),
						String(data.message),
						Number.NaN,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations', "revoke_guide_button_label"), triggered: onShowRevokeGuide },
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations', "ok_alert_button_label") }	
						]
					);
					alert.buttonGroupProperties.gap = 3;
					
					function onShowRevokeGuide(e:starling.events.Event):void
					{
						//Navigate to guide
						navigateToURL(new URLRequest("https://github.com/SpikeApp/Spike/wiki/Fix-For-Revoked-Certificates"));
					}
				}
				else
				{
					//Show a simple alert to the user
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations', "info_alert_title"),
						String(data.message)
					);
				}
				
				//Update Database
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_REMOTE_ALERT_LAST_ID, String(currentIDCheck));
			}
		}
		
		protected static function onApplicationActivated(event:flash.events.Event = null):void
		{
			//App is in foreground. Let's see if we can make a remote alert check
			//but not the very first start of the app, otherwise there's too many pop ups
			if (initialStart) 
			{
				initialStart = false;
				myTrace("in onApplicationActivated, initialStart = true, not doing remote alert check at app startup");
				return;
			}
			
			if(canDoCheck())
				getRemoteAlert();
		}
		
		/**
		 * Stops the service entirely. Useful for database restores
		 */
		private static function onHaltExecution(e:SpikeEvent):void
		{
			myTrace("Stopping service...");
			
			serviceHalted = true;
			
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_FOREGROUND, onApplicationActivated);
			
			myTrace("Service stopped!");
		}
		
		/**
		 * Utility
		 */
		private static function myTrace(log:String):void 
		{
			Trace.myTrace("RemoteAlertService.as", log);
		}
	}
}