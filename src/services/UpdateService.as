package services
{
	import com.distriqt.extension.networkinfo.NetworkInfo;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.navigateToURL;
	
	import database.CommonSettings;
	import database.LocalSettings;
	
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	
	import feathers.controls.Alert;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.popups.AlertManager;
	
	import utils.SpikeJSON;
	import utils.Trace;
	
	[ResourceBundle('updateservice')]
	
	public class UpdateService extends EventDispatcher
	{
		//Instance
		private static var _instance:UpdateService = new UpdateService();
		
		//Variables 
		private static var updateURL:String = "";
		private static var latestAppVersion:String = "";
		private static var awaitingLoadResponse:Boolean = false;
		private static var serviceHalted:Boolean = false;
		
		public function UpdateService(target:IEventDispatcher=null)
		{
			if (_instance != null) {
				throw new Error("UpdateService class constructor can not be used");	
			}
		}
		
		//Start Engine
		public static function init():void
		{
			//Setup Event Listeners
			createEventListeners();
		}
		
		//Getters/Setters
		public static function get instance():UpdateService {
			return _instance;
		}
		
		/**
		 * Functionality
		 */
		private static function createEventListeners():void
		{
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			
			//Register event listener for app in foreground
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, onApplicationActivated);
			
			//Register event listener for changed settings
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
		}
		
		private static function getUpdate():void
		{
			myTrace("in getUpdate");
			
			//Validation
			if (serviceHalted)
				true;
			
			if (!NetworkInfo.networkInfo.isReachable())
			{
				myTrace("No internet connection. Aborting");
				return;
			}
			
			//Create and configure loader and url request
			var request:URLRequest = new URLRequest(CommonSettings.APP_UPDATE_API_URL);
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
				myTrace("in getUpdate, Unable to load Spike Update API: " + error.getStackTrace().toString());
			}
		}
		
		private static function checkDaysBetweenLastUpdateCheck(previousUpdateStamp:Number, currentStamp:Number):Number
		{
			var oneDay:Number = 1000 * 60 * 60 * 24;
			var differenceMilliseconds:Number = Math.abs(previousUpdateStamp - currentStamp);
			var daysAgo:Number =  differenceMilliseconds/oneDay;
			return daysAgo;
		}
		
		private static function canDoUpdate():Boolean
		{
			//Validation
			if (serviceHalted)
				true;
			
			/**
			 * Uncomment next line and comment the other one for testing
			 * We are hardcoding a timestamp of more than 1 day ago for testing purposes otherwise the update popup wont fire 
			 */
			//var lastUpdateCheckStamp:Number = 1511014007853;
			var lastUpdateCheckStamp:Number = new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_UPDATE_LAST_UPDATE_CHECK));
			var currentTimeStamp:Number = (new Date()).valueOf();
			var daysSinceLastUpdateCheck:Number = checkDaysBetweenLastUpdateCheck(lastUpdateCheckStamp, currentTimeStamp);
			
			myTrace("in canDoUpdate, currentTimeStamp: " + currentTimeStamp);
			myTrace("in canDoUpdate, time between last update in days " + daysSinceLastUpdateCheck);
			
			//If it has been more than 1 day since the last check for updates or it's the first time the app checks for updates and app updates are enebled in the settings
			if((daysSinceLastUpdateCheck > 1 || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_UPDATE_LAST_UPDATE_CHECK) == "") && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_UPDATE_NOTIFICATIONS_ON) == "true")
			{
				myTrace("App can check for new updates");
				return true;
			}
			
			myTrace("App can not check for new updates");
			return false;
		}
		
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
		
		/**
		 * Event Listeners
		 */
		protected static function onResponseReceived(event:flash.events.Event):void
		{
			//Validation
			if (serviceHalted)
				true;
			
			if (awaitingLoadResponse) {
				myTrace("in onLoadSuccess");
				awaitingLoadResponse = false;
			} else {
				return;
			}
			
			if (!event.target) {
				myTrace("in onLoadSuccess, no event.target");
				return;
			}
			//Parse response and validate presence if mandatory objects 
			var loader:URLLoader = URLLoader(event.target);
			if (loader.data == null) {
				myTrace("in onLoadSuccess, no loader.data");
				return;
			}
			
			if (String(loader.data).indexOf("version") == -1)
			{
				myTrace("in onLoadSuccess, wrong response from server");
				return;
			}
			
			try
			{
				//var data:Object = JSON.parse(loader.data as String);
				var data:Object = SpikeJSON.parse(loader.data as String);
			} 
			catch(error:Error) 
			{
				myTrace("in onLoadSuccess, error parsing json... returning!");
				return;
			}
			
			
			if (data.version == null) {
				myTrace("in onLoadSuccess, no data.version");
				return;
			}
			if (data.changelog == null) {
				myTrace("in onLoadSuccess, no data.changelog");
				return;
			}
			if (data.url == null) {
				myTrace("in onLoadSuccess, no data.url");
				return;
			}
			
			var currentAppVersion:String = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APPLICATION_VERSION);
			//var currentAppVersion:String = "0.5";
			latestAppVersion = data.version;
			var updateAvailable:Boolean = versionAIsSmallerThanB(currentAppVersion, latestAppVersion);
			
			//Here's the right time to set last update check
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_APP_UPDATE_LAST_UPDATE_CHECK, (new Date()).valueOf().toString());
			
			//Handle User Update
			if(updateAvailable && latestAppVersion != CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_UPDATE_IGNORE_UPDATE))
			{
				//We are here because the lastest Spike version is higher than the one installed and the user hasn't chosen to ignore this new version
				updateURL = data.url;
					
				//Warn User
				var message:String = ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_preversion_message") + " " + latestAppVersion + " " + ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_postversion_message") + ".\n\n"; 
				message += ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_changelog") + ":\n" + data.changelog;		
				
				var alert:Alert = AlertManager.showActionAlert
				(
					ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_title"),
					message,
					Number.NaN,
					[
						{ label: ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_ignore_update"), triggered: onIgnoreUpdate },
						{ label: ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_remind_later") },
						{ label: ModelLocator.resourceManagerInstance.getString('updateservice', "update_dialog_download"), triggered: onDownload }	
					]
				);
				alert.buttonGroupProperties.gap = 0;
				alert.buttonGroupProperties.paddingLeft = 14;
			}
		}
		
		private static function onIgnoreUpdate(e:starling.events.Event):void
		{
			//Add ignored version to database settings
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_APP_UPDATE_IGNORE_UPDATE, latestAppVersion as String);
		}
		
		private static function onDownload(e:starling.events.Event):void
		{
			//Go to github release page
			if (updateURL != "")
			{
				navigateToURL(new URLRequest(updateURL));
				updateURL = "";
			}
		}
		
		//Event fired when app settings are changed
		private static function onSettingsChanged(event:SettingsServiceEvent):void 
		{
			//Check if an update check can be made
			if (event.data == CommonSettings.COMMON_SETTING_APP_UPDATE_NOTIFICATIONS_ON) 
			{
				myTrace("Settings changed! App update checker is now " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_UPDATE_NOTIFICATIONS_ON));
				
				//Let's see if we can make an update
				if(canDoUpdate())
					getUpdate();
			}
		}
		
		protected static function onApplicationActivated(event:flash.events.Event = null):void
		{
			//App is in foreground. Let's see if we can make an update
			//but not the very first start of the app, otherwise there's too many pop ups
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_UPDATE_SERVICE_INITIALCHECK) == "true") {
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_UPDATE_SERVICE_INITIALCHECK, "false");
				myTrace("in onApplicationActivated, LOCAL_SETTING_UPDATE_SERVICE_INITIALCHECK = true, not doing update check at app startup");
				return;
			}
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_UPDATE_NOTIFICATIONS_ON) == "true")
				if(canDoUpdate())
					getUpdate();
		}
		
		/**
		 * Stops the service entirely. Useful for database restores
		 */
		private static function onHaltExecution(e:SpikeEvent):void
		{
			myTrace("Stopping service...");
			
			serviceHalted = true;
			
			stopService();
		}
		
		private static function stopService():void
		{
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_FOREGROUND, onApplicationActivated);
			CommonSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
			
			myTrace("Service stopped!");
		}
		
		/**
		 * Utility
		 */
		private static function myTrace(log:String):void 
		{
			Trace.myTrace("UpdateService.as", log);
		}
	}
}