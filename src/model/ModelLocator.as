package model
{
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.distriqt.extension.scanner.Scanner;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.events.EventDispatcher;
	
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	import database.Database;
	import database.LocalSettings;
	
	import distriqtkey.DistriqtKey;
	
	import events.DatabaseEvent;
	import events.NotificationServiceEvent;
	
	import services.AlarmService;
	import services.IgnitionUpdateService;
	import services.CalibrationService;
	import services.DeepSleepService;
	import services.DexcomShareService;
	import services.HTTPServerService;
	import services.HealthKitService;
	import services.ICloudService;
	import services.IFTTTService;
	import services.MultipleMiaoMiaoService;
	import services.NightscoutService;
	import services.NotificationService;
	import services.RemoteAlertService;
	import services.TextToSpeechService;
	import services.TransmitterService;
	import services.UpdateService;
	import services.WatchService;
	import services.WidgetService;
	import services.bluetooth.CGMBluetoothService;
	
	import starling.utils.SystemUtil;
	
	import treatments.ProfileManager;
	import treatments.TreatmentsManager;
	
	import ui.AppInterface;
	import ui.InterfaceController;
	import ui.popups.AlertManager;
	
	import utils.Constants;
	import utils.TimeSpan;

	/**
	 * holds arraylist needed for displaying etc, like bgreadings of last 24 hours, loggings, .. 
	 */
	public class ModelLocator extends EventDispatcher
	{
		private static var _instance:ModelLocator = new ModelLocator();

		public static const MAX_DAYS_TO_STORE_BGREADINGS_IN_MODELLOCATOR:int = 1;
		public static const MAX_TIME_FOR_BGREADINGS:int = MAX_DAYS_TO_STORE_BGREADINGS_IN_MODELLOCATOR * TimeSpan.TIME_24_HOURS + Constants.READING_OFFSET;

		public static const IS_IPAD:Boolean = false;
		public static const INTERNAL_TESTING:Boolean = false;
		
		public static function get instance():ModelLocator
		{
			return _instance;
		}

		private static var _resourceManagerInstance:IResourceManager;

		/**
		 * can be used anytime the resourcemanager is needed
		 */
		public static function get resourceManagerInstance():IResourceManager
		{
			return _resourceManagerInstance;
		}
		
		private static var _bgReadings:Array = [];

		/**
		 * Sorted ascending, from small to large, ie latest element is also the last element
		 */
		public static function get bgReadings():Array
		{
			return _bgReadings;
		}
		
		private static var _appStartTimestamp:Number;

		/**
		 * time that the application was started 
		 */
		public static function get appStartTimestamp():Number
		{
			return _appStartTimestamp;
		}
		
		private static var _phoneMuted:Boolean;

		public static function get phoneMuted():Boolean
		{
			return _phoneMuted;
		}

		public static function set phoneMuted(value:Boolean):void
		{
			_phoneMuted = value;
		}

		public function ModelLocator()
		{
			if (_instance != null)
				throw new Error("ModelLocator class can only be instantiated through ModelLocator.getInstance()");	
			
			_appStartTimestamp = (new Date()).valueOf();
			
			_resourceManagerInstance = ResourceManager.getInstance();
			
			Database.instance.addEventListener(DatabaseEvent.DATABASE_INIT_FINISHED_EVENT,getBgReadingsFromDatabase);
						
			function getBgReadingsFromDatabase():void 
			{
				if (!CGMBlueToothDevice.isFollower())
				{
					//Load readings from database
					Database.instance.addEventListener(DatabaseEvent.BGREADING_RETRIEVAL_EVENT, bgReadingsReceivedFromDatabase);
					
					//bgreadings created after app start time are not needed because they are already stored in the _bgReadings by the transmitter service
					Database.getBgReadings(_appStartTimestamp - MAX_TIME_FOR_BGREADINGS, _appStartTimestamp); //24H
				}
				else
				{
					//Init app
					bgReadingsReceivedFromDatabase(null);
				}
			}

			function bgReadingsReceivedFromDatabase(de:DatabaseEvent):void 
			{
				if (de != null) Database.instance.removeEventListener(DatabaseEvent.BGREADING_RETRIEVAL_EVENT, bgReadingsReceivedFromDatabase);
				
				//Set Language
				ModelLocator.resourceManagerInstance.localeChain = [CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_LANGUAGE),"en_US"];
				
				//Manage Rotation
				var preventRotation:Boolean = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PREVENT_SCREEN_ROTATION_ON) == "true";
				Constants.appStage.autoOrients = !preventRotation;
				
				if (de != null && de.data != null) _bgReadings = de.data as Array;
				
				//ANE Initialization
				SpikeANE.init();
				NetworkInfo.init(!IS_IPAD ? DistriqtKey.distriqtKey : DistriqtKey.distriqtKeyIpad);
				Scanner.init(!IS_IPAD ? DistriqtKey.distriqtKey : DistriqtKey.distriqtKeyIpad);
				
				//Audio Initialization
				SpikeANE.setAvAudioSessionCategory(true);
				
				//CGM Initialization
				Database.getBlueToothDevice();
				
				//App Version
				updateApplicationVersion();
				
				//Services Initialization
				ProfileManager.init();
				TreatmentsManager.init();
				SystemUtil.executeWhenApplicationIsActive( AppInterface.instance.init ); //Start rendering interface now that all data is available but only when app is active
				AlertManager.init();
				DeepSleepService.init();
				TransmitterService.init();
				CGMBluetoothService.init();
				NotificationService.instance.addEventListener(NotificationServiceEvent.NOTIFICATION_SERVICE_INITIATED_EVENT, InterfaceController.notificationServiceInitiated);
				NotificationService.init();
				CalibrationService.init();
				AlarmService.init();
				HTTPServerService.init();
				if (!IS_IPAD) HealthKitService.init();
				NightscoutService.init();
				DexcomShareService.init();
				IFTTTService.init();
				TextToSpeechService.init();
				WidgetService.init();
				WatchService.init();
				ICloudService.init();
				RemoteAlertService.init();
				IgnitionUpdateService.init();
				//MultipleMiaoMiaoService.init();
			}
		}
		
		public static function getMasterReadings():void
		{
			//Clear previous readings
			_bgReadings.length = 0;
			
			//Load readings from database
			var now:Number = new Date().valueOf();
			Database.instance.addEventListener(DatabaseEvent.BGREADING_RETRIEVAL_EVENT, bgReadingsReceivedFromDatabase);
			Database.getBgReadings(now - MAX_TIME_FOR_BGREADINGS, now); //24H
			
			function bgReadingsReceivedFromDatabase(de:DatabaseEvent):void 
			{
				Database.instance.removeEventListener(DatabaseEvent.BGREADING_RETRIEVAL_EVENT, bgReadingsReceivedFromDatabase);
				
				if (de != null && de.data != null) _bgReadings = de.data as Array;
			}
		}
		
		private static function updateApplicationVersion():void 
		{
			var currentAppVersion:String = SpikeANE.getAppVersion();
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APPLICATION_VERSION) != currentAppVersion)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_APPLICATION_VERSION, currentAppVersion); 
		}
		
		/**
		 * add bgreading also removes bgreadings older than MAX_DAYS_TO_STORE_BGREADINGS_IN_MODELLOCATOR days but keep at least 5<br>
		 */
		public static function addBGReading(bgReading:BgReading):void 
		{
			_bgReadings.push(bgReading);
			
			if (_bgReadings.length <= 5)
					return;
				
			var firstBGReading:BgReading = _bgReadings[0] as BgReading;
			var now:Number = (new Date()).valueOf();
			while (now - firstBGReading.timestamp > MAX_TIME_FOR_BGREADINGS) 
			{
				_bgReadings.removeAt(0);
						
				if (_bgReadings.length <= 5)
					break;
					
				firstBGReading = _bgReadings[0] as BgReading;
			}
		}
		
		/**
		 * returns true if last reading was successfully removed 
		 */
		public static function removeLastBgReading():Boolean 
		{
			if (_bgReadings.length > 0) 
			{
				var removedReading:BgReading = _bgReadings.pop() as BgReading;
				Database.deleteBgReadingSynchronous(removedReading);
				return true;
			}
			
			return false;
		}
		
		public static function getLastBgReading():BgReading 
		{
			if (_bgReadings.length > 0) 
			{
				return _bgReadings[_bgReadings.length - 1] as BgReading;
			}
			
			return null;
		}
	}
}
