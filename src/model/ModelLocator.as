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
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	import spark.components.ViewNavigator;
	
	import database.BgReading;
	import database.Database;
	import database.LocalSettings;
	import database.Sensor;
	
	import distriqtkey.DistriqtKey;
	
	import events.DatabaseEvent;
	import events.NotificationServiceEvent;
	
	import services.AlarmService;
	import services.BackGroundFetchService;
	import services.BluetoothService;
	import services.CalibrationService;
	import services.DeepSleepService;
	import services.DexcomShareServiceEnhanced;
	import services.HealthKitService;
	import services.NightscoutServiceEnhanced;
	import services.NotificationService;
	import services.TextToSpeech;
	import services.TransmitterService;
	import services.UpdateService;
	
	import ui.AppInterface;
	import ui.InterfaceController;

	/**
	 * holds arraylist needed for displaying etc, like bgreadings of last 24 hours, loggings, .. 
	 */
	public class ModelLocator extends EventDispatcher
	{
		private static var _instance:ModelLocator = new ModelLocator();
		private static var dataSortFieldForBGReadings:SortField;
		private static var dataSortForBGReadings:Sort;

		public static const MAX_DAYS_TO_STORE_BGREADINGS_IN_MODELLOCATOR:int = 1;
		public static const DEBUG_MODE:Boolean = true;

		public static const TEST_FLIGHT_MODE:Boolean = false;
		
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
		
		private static var _bgReadings:ArrayCollection;

		/**
		 * Sorted ascending, from small to large, ie latest element is also the last element
		 */
		public static function get bgReadings():ArrayCollection
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
		
		public static var navigator:ViewNavigator;

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
			if (_instance != null) {
				throw new Error("ModelLocator class can only be instantiated through ModelLocator.getInstance()");	
			}
			
			_appStartTimestamp = (new Date()).valueOf();
			
			_resourceManagerInstance = ResourceManager.getInstance();
			
			//bgreadings arraycollection
			_bgReadings = new ArrayCollection();
			dataSortFieldForBGReadings = new SortField();
			dataSortFieldForBGReadings.name = "timestamp";
			dataSortFieldForBGReadings.numeric = true;
			dataSortFieldForBGReadings.descending = false;//ie ascending = from small to large
			dataSortForBGReadings = new Sort();
			dataSortForBGReadings.fields=[dataSortFieldForBGReadings];
			_bgReadings.sort = dataSortForBGReadings;
			Database.instance.addEventListener(DatabaseEvent.DATABASE_INIT_FINISHED_EVENT,getBgReadingsAndLogsFromDatabase);
						
			function getBgReadingsAndLogsFromDatabase():void {
				Database.instance.addEventListener(DatabaseEvent.BGREADING_RETRIEVAL_EVENT, bgReadingReceivedFromDatabase);
				//bgreadings created after app start time are not needed because they are already stored in the _bgReadings by the transmitter service
				Database.getBgReadings(_appStartTimestamp - (24 * 60 * 60 * 1000), _appStartTimestamp); //24H
			}

			function bgReadingReceivedFromDatabase(de:DatabaseEvent):void {
				if (de.data != null)
					if (de.data is BgReading) {
						if ((de.data as BgReading).timestamp > ((new Date()).valueOf() - MAX_DAYS_TO_STORE_BGREADINGS_IN_MODELLOCATOR * 24 * 60 * 60 * 1000)) {
							_bgReadings.addItem(de.data);
						}
					} else if (de.data is String) {
						if (de.data as String == Database.END_OF_RESULT) {
							_bgReadings.refresh();
							getLogsFromDatabase();
							if (_bgReadings.length < 2) {
								if (Sensor.getActiveSensor() != null) {
									//sensor is active but there's less than two bgreadings, this may happen exceptionally if was started previously but not used for exactly or more than  MAX_DAYS_TO_STORE_BGREADINGS_IN_MODELLOCATOR days
									Sensor.stopSensor();
								}
							}
						}
					}
			}

			//get stored logs from the database
			function getLogsFromDatabase():void {
				Database.instance.addEventListener(DatabaseEvent.LOGRETRIEVED_EVENT, logReceivedFromDatabase);
				//logs created after app start time are not needed because they are already added in the logginglist
				Database.getLoggings(_appStartTimestamp);
			}
			
			function logReceivedFromDatabase(de:DatabaseEvent):void {
				if (de.data != null)
					if (de.data is String) {
						if (de.data as String == Database.END_OF_RESULT) {
							//Start rendering interface now that all data is available
							
							//trace("Check BG Readings...");
							//trace("NOW:", ObjectUtil.toString(bgReadings));
							
							
							AppInterface.instance.init();
							
							Database.getBlueToothDevice();
							TransmitterService.init();
							BluetoothService.init();

							NotificationService.instance.addEventListener(NotificationServiceEvent.NOTIFICATION_SERVICE_INITIATED_EVENT, InterfaceController.notificationServiceInitiated);
							NotificationService.init();
							
							CalibrationService.init();
							NetworkInfo.init(DistriqtKey.distriqtKey);
							
							BackGroundFetchService.init();
							//set AVAudioSession to AVAudioSessionCategoryPlayback with optoin AVAudioSessionCategoryOptionMixWithOthers
							//this ensures that texttospeech and playsound work also in background
							BackgroundFetch.setAvAudioSessionCategory(true);
							
							AlarmService.init();
							HealthKitService.init();
							
							//DexcomShareService.init();
							//NightScoutService.init();
							TextToSpeech.init();
							DeepSleepService.init();
							
							if (!TEST_FLIGHT_MODE) {
								UpdateService.init();
							}
							
							updateApplicationVersion();
							
							NightscoutServiceEnhanced.init();
							DexcomShareServiceEnhanced.init();
							
							//test blockNumberForNowGlucoseData
							/*var bufferasstring:String = "8BDE03423F07115203C8A0";
							var bufferasbytearray:ByteArray = Utilities.UniqueId.hexStringToByteArray(bufferasstring);
							trace("test blockNumberForNowGlucoseData, result  " + BluetoothService.blockNumberForNowGlucoseData(bufferasbytearray) + ", expected = 08");
							
							bufferasstring = "8bde031ffd081d8804c834";
							bufferasbytearray = Utilities.UniqueId.hexStringToByteArray(bufferasstring);
							trace("test 2 for blockNumberForNowGlucoseData, result  " + BluetoothService.blockNumberForNowGlucoseData(bufferasbytearray) + ", expected = 08");
							
							//test nowGetGlucoseValue
							var nowGlucoseValueasString = "8bde08c204c8a45f00b804";
							bufferasbytearray = Utilities.UniqueId.hexStringToByteArray(nowGlucoseValueasString);
							trace("test nowGetGlucoseValue =   " + BluetoothService.nowGetGlucoseValue(bufferasbytearray) + ", expected = 142");*/
						} else {
						}
					}
			}
		}
		
		private static function updateApplicationVersion():void 
		{
			var currentAppVersion:String = BackgroundFetch.getAppVersion();
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APPLICATION_VERSION) != currentAppVersion)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_APPLICATION_VERSION, currentAppVersion); 
		}
		
		private static function coreEvent(event:Event):void {
			var test:int = 0;
			test++;
		}
		
		/**
		 * add bgreading also removes bgreadings older than MAX_DAYS_TO_STORE_BGREADINGS_IN_MODELLOCATOR days but keep at least 5<br>
		 */
		public static function addBGReading(bgReading:BgReading):void {
			_bgReadings.addItem(bgReading);
			_bgReadings.refresh();
			
			if (_bgReadings.length <= 5)
				return;
			
			var firstBGReading:BgReading = _bgReadings.getItemAt(0) as BgReading;
			var now:Number = (new Date()).valueOf();
			while (now - firstBGReading.timestamp > MAX_DAYS_TO_STORE_BGREADINGS_IN_MODELLOCATOR * 24 * 3600 * 1000) {
				_bgReadings.removeItemAt(0);
				if (_bgReadings.length <= 5)
					break;
				firstBGReading = _bgReadings.getItemAt(0) as BgReading;
			}
		}
	}
}
