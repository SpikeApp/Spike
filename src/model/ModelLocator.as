/**
 Copyright (C) 2016  Johan Degraeve
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
 
 */
package model
{
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.events.EventDispatcher;
	
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	
	import database.BgReading;
	import database.Database;
	import database.LocalSettings;
	
	import distriqtkey.DistriqtKey;
	
	import events.DatabaseEvent;
	import events.NotificationServiceEvent;
	
	import services.AlarmService;
	import services.BackGroundFetchService;
	import services.BluetoothService;
	import services.CalibrationService;
	import services.DeepSleepService;
	import services.DexcomShareService;
	import services.HTTPServerService;
	import services.HealthKitService;
	import services.IFTTTService;
	import services.NightscoutService;
	import services.NotificationService;
	import services.RemoteAlertService;
	import services.TextToSpeechService;
	import services.TransmitterService;
	import services.UpdateService;
	import services.WatchService;
	import services.WidgetService;
	
	import treatments.ProfileManager;
	import treatments.TreatmentsManager;
	
	import ui.AppInterface;
	import ui.InterfaceController;
	import ui.popups.AlertManager;
	
	import utils.Constants;

	/**
	 * holds arraylist needed for displaying etc, like bgreadings of last 24 hours, loggings, .. 
	 */
	public class ModelLocator extends EventDispatcher
	{
		private static var _instance:ModelLocator = new ModelLocator();

		public static const MAX_DAYS_TO_STORE_BGREADINGS_IN_MODELLOCATOR:int = 1;
		public static const MAX_TIME_FOR_BGREADINGS:int = MAX_DAYS_TO_STORE_BGREADINGS_IN_MODELLOCATOR * 24 * 60 * 60 * 1000 + Constants.READING_OFFSET;

		public static const TEST_FLIGHT_MODE:Boolean = true;
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
		
		private static var _bgReadings:Array;

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
				Database.instance.addEventListener(DatabaseEvent.BGREADING_RETRIEVAL_EVENT, bgReadingsReceivedFromDatabase);
				
				//bgreadings created after app start time are not needed because they are already stored in the _bgReadings by the transmitter service
				Database.getBgReadings(_appStartTimestamp - MAX_TIME_FOR_BGREADINGS, _appStartTimestamp); //24H
			}

			function bgReadingsReceivedFromDatabase(de:DatabaseEvent):void 
			{
				Database.instance.removeEventListener(DatabaseEvent.BGREADING_RETRIEVAL_EVENT, bgReadingsReceivedFromDatabase);
				
				_bgReadings = de.data as Array;
				ProfileManager.init();
				TreatmentsManager.init();
				AppInterface.instance.init(); //Start rendering interface now that all data is available
				AlertManager.init();
				DeepSleepService.init();
				Database.getBlueToothDevice();
				TransmitterService.init();
				BackGroundFetchService.init();
				BluetoothService.init();
				NotificationService.instance.addEventListener(NotificationServiceEvent.NOTIFICATION_SERVICE_INITIATED_EVENT, InterfaceController.notificationServiceInitiated);
				NotificationService.init();
				CalibrationService.init();
				NetworkInfo.init(DistriqtKey.distriqtKey);
				BackgroundFetch.setAvAudioSessionCategory(true);
				BackgroundFetch.isVersion2_1_1()//to make sure the correct ANE is used
				WidgetService.init();
				WatchService.init();
				AlarmService.init();
				HTTPServerService.init();
				HealthKitService.init();
				NightscoutService.init();
				DexcomShareService.init();
				IFTTTService.init();
				TextToSpeechService.init();
				RemoteAlertService.init();
				if (!TEST_FLIGHT_MODE) UpdateService.init();
				updateApplicationVersion();
			}
		}
		
		private static function updateApplicationVersion():void 
		{
			var currentAppVersion:String = BackgroundFetch.getAppVersion();
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
