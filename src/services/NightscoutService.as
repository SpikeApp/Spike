package services
{
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.distriqt.extension.networkinfo.events.NetworkInfoEvent;
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.util.Hex;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.utils.Timer;
	
	import mx.utils.ObjectUtil;
	
	import spark.formatters.DateTimeFormatter;
	
	import database.BgReading;
	import database.BlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.Sensor;
	
	import events.CalibrationServiceEvent;
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	
	import feathers.layout.HorizontalAlign;
	
	import model.ModelLocator;
	
	import network.NetworkConnector;
	
	import ui.popups.AlertManager;
	
	import utils.Trace;
	import utils.UniqueId;
	
	[ResourceBundle("nightscoutservice")]
	
	public class NightscoutService
	{
		/* Constants */
		private static const MODE_GLUCOSE_READING:String = "glucoseReading";
		private static const MODE_CALIBRATION:String = "calibration";
		private static const MODE_VISUAL_CALIBRATION:String = "visualCalibration";
		private static const MODE_SENSOR_START:String = "sensorStart";
		private static const MODE_TEST_CREDENTIALS:String = "testCredentials";
		private static const MAX_SYNC_TIME:Number = 45 * 1000; //45 seconds
		private static const TIME_6_MINUTES:int = 6 * 60 * 1000;
		
		/* Logical Variables */
		private static var serviceStarted:Boolean = false;
		private static var serviceActive:Boolean = false;
		private static var _syncGlucoseReadingsActive:Boolean = false;
		private static var syncGlucoseReadingsActiveLastChange:Number = (new Date()).valueOf();
		private static var _syncCalibrationsActive:Boolean = false;
		private static var syncCalibrationsActiveLastChange:Number = (new Date()).valueOf();
		private static var _syncVisualCalibrationsActive:Boolean = false;
		private static var syncVisualCalibrationsActiveLastChange:Number = (new Date()).valueOf();
		private static var _syncSensorStartActive:Boolean = false;
		private static var syncSensorStartActiveLastChange:Number = (new Date()).valueOf();
		private static var externalAuthenticationCall:Boolean = false;
		public static var ignoreSettingsChanged:Boolean = false;
		
		/* Data Variables */
		private static var apiSecret:String;
		private static var nightscoutEventsURL:String;
		private static var nightscoutTreatmentsURL:String;
		private static var credentialsTesterID:String;
		private static var lastGlucoseReadingsSyncTimeStamp:Number;
		private static var initialGlucoseReadingsIndex:int = 0;
		private static var networkChangeOcurrances:int = 0;
		
		/* Objects */
		private static var hash:SHA1 = new SHA1();
		private static var formatter:DateTimeFormatter;
		private static var serviceTimer:Timer;
		
		/* Data Objects */
		private static var activeGlucoseReadings:Array = [];
		private static var activeCalibrations:Array = [];
		private static var activeVisualCalibrations:Array = [];
		private static var activeSensorStarts:Array = [];
		
		public function NightscoutService()
		{
			throw new Error("NightscoutService is not meant to be instantiated");
		}
		
		public static function init():void
		{
			if (serviceStarted)
				return;
			
			Trace.myTrace("NightscoutService.as", "Service started!");
			
			serviceStarted = true;
			
			formatter = new DateTimeFormatter();
			formatter.dateTimePattern = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
			formatter.setStyle("locale", "en_US");
			formatter.useUTC = false;
			
			//Event listener for settings changes
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingChanged);
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_ON) == "true" &&
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) != "" &&
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET) != "" &&
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URL_AND_API_SECRET_TESTED) == "false")
			{
				setupNightscoutProperties();
				testNightscoutCredentials();
			}
			else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_ON) == "true" &&
					 CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) != "" &&
					 CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET) != "" &&
					 CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URL_AND_API_SECRET_TESTED) == "true")
			{
				activateService();
			}
		}
		
		/**
		 * GLUCOSE READINGS
		 */
		private static function createGlucoseReading(glucoseReading:BgReading):Object
		{
			var newReading:Object = new Object();
			newReading["device"] = BlueToothDevice.name;
			newReading["date"] = glucoseReading.timestamp;
			newReading["dateString"] = formatter.format(glucoseReading.timestamp);
			newReading["sgv"] = Math.round(glucoseReading.calculatedValue);
			newReading["direction"] = glucoseReading.slopeName();
			newReading["type"] = "sgv";
			newReading["filtered"] = Math.round(glucoseReading.ageAdjustedFiltered() * 1000);
			newReading["unfiltered"] = Math.round(glucoseReading.usedRaw() * 1000);
			newReading["rssi"] = 100;
			newReading["noise"] = glucoseReading.noiseValue();
			newReading["sysTime"] = formatter.format(glucoseReading.timestamp);
			
			return newReading;
		}
		
		private static function getInitialGlucoseReadings():void
		{
			Trace.myTrace("NightscoutService.as", "in getInitialGlucoseReadings.");
			
			lastGlucoseReadingsSyncTimeStamp = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP));
			
			for(var i:int = ModelLocator.bgReadings.length - 1 ; i >= 0; i--)
			{
				var glucoseReading:BgReading = ModelLocator.bgReadings[i] as BgReading;
				
				if (glucoseReading.timestamp > lastGlucoseReadingsSyncTimeStamp) 
				{
					if (glucoseReading.calculatedValue != 0) 
						activeGlucoseReadings.push(createGlucoseReading(glucoseReading));
				}
				else 
					break;
			}
			
			Trace.myTrace("NightscoutService.as", "Number of initial readings to upload: " + activeGlucoseReadings.length);
			
			initialGlucoseReadingsIndex = activeGlucoseReadings.length;
			
			if (activeGlucoseReadings.length > 0)
				syncGlucoseReadings();
		}
		
		private static function syncGlucoseReadings():void
		{
			if (activeGlucoseReadings.length == 0 || syncGlucoseReadingsActive || !NetworkInfo.networkInfo.isReachable())
				return;
			
			if (Calibration.allForSensor().length < 2) 
				return;
			
			syncGlucoseReadingsActive = true;
			
			//Upload Glucose Readings
			NetworkConnector.createNSConnector(nightscoutEventsURL, apiSecret, URLRequestMethod.POST, JSON.stringify(activeGlucoseReadings), MODE_GLUCOSE_READING, onUploadGlucoseReadingsComplete, onConnectionFailed);
		}
		
		private static function onBgreadingReceived(e:TransmitterServiceEvent):void 
		{
			var latestGlucoseReading:BgReading = BgReading.lastNoSensor();
			
			if(latestGlucoseReading == null)
				return;
			
			activeGlucoseReadings.push(createGlucoseReading(latestGlucoseReading));
			
			//Only start uploading bg reading if it's newer than 6 minutes. Blucon sends historical data so we don't want to start upload for every reading. Just start upload on the last readings. The previous readings will still be uploaded because the reside in the queue array.
			if (new Date().valueOf() - latestGlucoseReading.timestamp < TIME_6_MINUTES)
				syncGlucoseReadings();
		}
		
		private static function onUploadGlucoseReadingsComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "in onUploadGlucoseReadingsComplete.");
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onUploadGlucoseReadingsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onUploadGlucoseReadingsComplete);
			loader = null;
			
			//Check response
			if (response.indexOf(BlueToothDevice.name) != -1)
			{
				Trace.myTrace("NightscoutService.as", "Glucose reading upload was successful.");
				if (initialGlucoseReadingsIndex == 0)
				{
					//It's a new reading and there's no previous initial readings in queue
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP, String(activeGlucoseReadings[activeGlucoseReadings.length -1].date));
					activeGlucoseReadings.length = 0; 
				}
				else
				{
					//It's an initial readings call
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP, String(activeGlucoseReadings[initialGlucoseReadingsIndex -1].date));
					activeGlucoseReadings = activeGlucoseReadings.slice(0, initialGlucoseReadingsIndex);
					initialGlucoseReadingsIndex = 0;
				}
			}
			else
			{
				Trace.myTrace("NightscoutService.as", "Error uploading glucose reading. Maybe server is down or no Internet connection? Server response: " + response);
			}
			
			syncGlucoseReadingsActive = false;
		}
		
		/**
		 * CALIBRATIONS
		 */
		private static function createCalibrationObject(calibration:Calibration):Object
		{
			var newCalibration:Object = new Object();
			newCalibration["device"] = BlueToothDevice.name;
			newCalibration["type"] = "cal";
			newCalibration["date"] = calibration.timestamp;
			newCalibration["dateString"] = formatter.format(calibration.timestamp);
			if (calibration.checkIn) {
				newCalibration["slope"] = calibration.slope;
				newCalibration["intercept"] = calibration.firstIntercept;
				newCalibration["scale"] = calibration.firstScale;
			} else {
				newCalibration["slope"] = 1000/calibration.slope;
				newCalibration["intercept"] = calibration.intercept * -1000 / calibration.slope;
				newCalibration["scale"] = 1;
			}
			
			return newCalibration;
		}
		
		private static function createVisualCalibrationObject(calibration:Calibration):Object
		{
			var newVisualCalibration:Object = new Object();
			newVisualCalibration["eventType"] = "BG Check";	
			newVisualCalibration["created_at"] = formatter.format(calibration.timestamp);
			newVisualCalibration["enteredBy"] = "Spike App";	
			newVisualCalibration["glucose"] = calibration.bg;
			newVisualCalibration["glucoseType"] = "Finger";
			newVisualCalibration["notes"] = ModelLocator.resourceManagerInstance.getString("nightscoutservice","sensor_calibration");
			
			return newVisualCalibration;
		}
		
		private static function syncCalibrations():void
		{
			if (activeCalibrations.length == 0 || syncGlucoseReadingsActive || !NetworkInfo.networkInfo.isReachable())
				return;
			
			syncCalibrationsActive = true;
			
			//Upload Glucose Readings
			NetworkConnector.createNSConnector(nightscoutEventsURL, apiSecret, URLRequestMethod.POST, JSON.stringify(activeCalibrations), MODE_CALIBRATION, onUploadCalibrationsComplete, onConnectionFailed);
		}
		
		private static function getInitialCalibrations():void
		{
			Trace.myTrace("NightscoutService.as", "in getInitialCalibrations.");
			
			var calibrationList:Array = Calibration.allForSensor().toArray();
			var lastCalibrationSyncTimeStamp:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_CALIBRATION_TIMESTAMP));
			
			for(var i:int = calibrationList.length - 1 ; i >= 0; i--)
			{
				var calibration:Calibration = calibrationList[i] as Calibration;
				if (calibration.timestamp > lastCalibrationSyncTimeStamp && calibration.slope != 0) 
				{
					activeCalibrations.push(createCalibrationObject(calibration));					
					activeVisualCalibrations.push(createVisualCalibrationObject(calibration));
				}
				else
					break;
			}
			
			Trace.myTrace("NightscoutService.as", "Initial calibrations to upload: " + activeCalibrations.length);
			
			if (activeCalibrations.length > 0)
				syncCalibrations();
			
			if (activeVisualCalibrations.length > 0)
				syncVisualCalibrations();
		}
		
		private static function onCalibrationReceived(e:CalibrationServiceEvent):void 
		{
			var lastCalibration:Calibration = Calibration.last();
			
			activeCalibrations.push(createCalibrationObject(lastCalibration));
			activeVisualCalibrations.push(createVisualCalibrationObject(lastCalibration));
			
			syncCalibrations();
			syncVisualCalibrations();
		}

		private static function onUploadCalibrationsComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "in onUploadCalibrationsComplete.");
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onUploadCalibrationsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onUploadCalibrationsComplete);
			loader = null;
			
			//Update Internal Variables
			syncCalibrationsActive = false;
			
			if (response.indexOf(BlueToothDevice.name) != -1)
			{
				Trace.myTrace("NightscoutService.as", "Calibration upload was successful.");
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_CALIBRATION_TIMESTAMP, String(activeCalibrations[activeCalibrations.length - 1].date));
				activeCalibrations.length = 0;
			}
			else
			{
				Trace.myTrace("NightscoutService.as", "Error uploading calibration.");
			}
		}
		
		private static function syncVisualCalibrations():void
		{
			if (activeVisualCalibrations.length == 0 || syncVisualCalibrationsActive || !NetworkInfo.networkInfo.isReachable())
				return;
			
			syncVisualCalibrationsActive = true;
			
			//Upload Glucose Readings
			NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.POST, JSON.stringify(activeVisualCalibrations), MODE_VISUAL_CALIBRATION, onUploadVisualCalibrationsComplete, onConnectionFailed);
		}
		
		private static function onUploadVisualCalibrationsComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "onUploadVisualCalibrationsComplete");
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onUploadVisualCalibrationsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onUploadVisualCalibrationsComplete);
			loader = null;
			
			syncVisualCalibrationsActive = false;
			
			if (response.indexOf("BG Check") != -1 && response.indexOf("Error") == -1)
			{
				Trace.myTrace("NightscoutService.as", "Visual calibration upload was successful!");
				activeVisualCalibrations.length = 0;
			}
			else
			{
				Trace.myTrace("NightscoutService.as", "Error uploading visual calibration!");
			}
		}
		
		/**
		 * SENSOR STARTS
		 */
		private static function syncSensorStart():void
		{
			if (activeSensorStarts.length == 0 || syncSensorStartActive || !NetworkInfo.networkInfo.isReachable())
				return;
			
			syncSensorStartActive = true;
			
			//Upload Glucose Readings
			NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.POST, JSON.stringify(activeSensorStarts), MODE_SENSOR_START, onUploadSensorStartComplete, onConnectionFailed);
		}
		
		private static function getSensorStart():void
		{
			Trace.myTrace("NightscoutService.as", "in getSensorStart.");
			
			var newSensor:Object = new Object();
			newSensor["eventType"] = "Sensor Start";	
			newSensor["created_at"] = formatter.format(Sensor.getActiveSensor().startedAt);
			newSensor["enteredBy"] = "Spike App";
			
			activeSensorStarts.push(newSensor);
			
			syncSensorStart();
		}
		
		private static function onUploadSensorStartComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "onUploadSensorStartComplete");
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onUploadVisualCalibrationsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onUploadVisualCalibrationsComplete);
			loader = null;
			
			syncSensorStartActive = false;
			
			if (response.indexOf("Sensor Start") != -1 && response.indexOf("Error") == -1)
			{
				Trace.myTrace("NightscoutService.as", "Sensor start uploaded successfuly");
				activeSensorStarts.length = 0;
			}
			else
			{
				Trace.myTrace("NightscoutService.as", "Error uploading sensor start!");
			}
		}
		
		/**
		 * CREDENTIALS TEST
		 */
		public static function testNightscoutCredentials(externalCall:Boolean = false):void
		{
			Trace.myTrace("NightscoutService.as", "testNightscoutCredentials called. External call = " + externalCall);
			
			if (nightscoutTreatmentsURL == "" || apiSecret == "")
				return;
			
			externalAuthenticationCall = externalCall;
			
			if (NetworkInfo.networkInfo.isReachable()) 
			{
				credentialsTesterID = UniqueId.createEventId();
				var credentialsTester:Object = new Object();
				credentialsTester["_id"] = credentialsTesterID;
				credentialsTester["eventType"] = "Note";
				credentialsTester["duration"] = 30;
				credentialsTester["notes"] = "Spike App Authentication Test";
				
				NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.PUT, JSON.stringify(credentialsTester), MODE_TEST_CREDENTIALS, onTestCredentialsComplete, onConnectionFailed);
			}
			else
			{
				Trace.myTrace("NightscoutService.as", "Can't check NS credentials. No Internet connection!");
				
				if (externalCall)
				{
					AlertManager.showSimpleAlert(
						ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_title"),
						ModelLocator.resourceManagerInstance.getString("nightscoutservice","call_to_nightscout_to_verify_url_and_secret_can_not_be_made"),
						60
					);
				}
			}
		}
		
		private static function onTestCredentialsComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "onTestCredentialsComplete called");
			
			var loader:URLLoader = e.currentTarget as URLLoader;
			var response:String = loader.data;
			loader = null;
			
			if (response != "")
			{
				if (response.indexOf("Cannot PUT /api/v1/treatments") != -1)
				{
					Trace.myTrace("NightscoutService.as", "NS Authentication failed! Careportal not enabled.");
					
					if (externalAuthenticationCall)
					{
						AlertManager.showSimpleAlert(
							ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_title"),
							ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_test_result_nok") + " " + ModelLocator.resourceManagerInstance.getString("nightscoutservice","care_portal_should_be_enabled"),
							Number.NaN
						);
					}
					
					//Update database
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_URL_AND_API_SECRET_TESTED, "false");
					
					//Deactivate service
					if (serviceActive)
						deactivateService();
				}
				else
				{
					var responseInfo:Object = JSON.parse(response);
					if (responseInfo.ok != null && responseInfo.ok == 1)
					{
						Trace.myTrace("NightscoutService.as", "NS Authentication successful! Activating service");
						
						//Alert user
						if (externalAuthenticationCall)
						{
							AlertManager.showSimpleAlert(
								ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_title"),
								ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_test_result_ok"),
								Number.NaN,
								null,
								HorizontalAlign.CENTER
							);
						}
						
						//Delete credential test treatment
						NetworkConnector.createNSConnector(nightscoutTreatmentsURL + "/" + credentialsTesterID, apiSecret, URLRequestMethod.DELETE);
						
						//Update database
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_URL_AND_API_SECRET_TESTED, "true");
						
						//Activate service
						if (!serviceActive)
							activateService();
					}
					else if (responseInfo.status != null)
					{
						Trace.myTrace("NightscoutService.as", "Authentication failed! Wrong api secret?");
						Trace.myTrace("NightscoutService.as", "Error:", responseInfo.status + " " + responseInfo.message);
						
						//Alert User
						if (externalAuthenticationCall)
						{
							var errorMessage:String = ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_test_authentication_failed");
							errorMessage += " " + responseInfo.status + " " + responseInfo.message;
							
							AlertManager.showSimpleAlert(
								ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_title"),
								errorMessage,
								Number.NaN
							);
						}
						
						//Update database
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_URL_AND_API_SECRET_TESTED, "false");
						
						//Deactivate service
						if (serviceActive)
							deactivateService();
					}
					else
					{
						Trace.myTrace("NightscoutService.as", "Something when wrong! ResponseInfo: " + ObjectUtil.toString(responseInfo));
					}
				}
			}
			else
			{
				Trace.myTrace("NightscoutService.as", "Authentication failed! URL not found. Response: " + response);
				
				//Alert user
				if (externalAuthenticationCall)
				{
					AlertManager.showSimpleAlert(
						ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_title"),
						ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_test_url_not_found"),
						Number.NaN,
						null,
						HorizontalAlign.CENTER
					);
				}
				
				//Update database
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_URL_AND_API_SECRET_TESTED, "false");
				
				//Deactivate service
				if (serviceActive)
					deactivateService();
			}
			
			externalAuthenticationCall = false;
		}
		
		/**
		 * Functionality
		 */
		private static function activateService():void
		{
			Trace.myTrace("NightscoutService.as", "Service activated!");
			serviceActive = true;
			setupNightscoutProperties();
			getInitialGlucoseReadings();
			getInitialCalibrations();
			activateEventListeners();
			activateTimer();
		}
		
		private static function deactivateService():void
		{
			Trace.myTrace("NightscoutService.as", "Service deactivated!");
			serviceActive = false;
			deactivateEventListeners();
			deactivateTimer();
			activeGlucoseReadings.length = 0;
			activeCalibrations.length = 0;
			activeVisualCalibrations.length = 0;
			activeSensorStarts.length = 0;
		}
		
		private static function activateTimer():void
		{
			serviceTimer = new Timer(60 * 1000);
			serviceTimer.addEventListener(TimerEvent.TIMER, onServiceTimer, false, 0, true);
			serviceTimer.start();
		}
		
		private static function deactivateTimer():void
		{
			if (serviceTimer != null)
			{
				serviceTimer.stop();;
				serviceTimer.removeEventListener(TimerEvent.TIMER, onServiceTimer);
				serviceTimer = null;
			}
		}
		
		private static function setupNightscoutProperties():void
		{
			apiSecret = Hex.fromArray(hash.hash(Hex.toArray(Hex.fromString(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET)))));
			
			nightscoutEventsURL = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/api/v1/entries";
			if (nightscoutEventsURL.indexOf('http') == -1) nightscoutEventsURL = "https://" + nightscoutEventsURL;
			
			nightscoutTreatmentsURL = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/api/v1/treatments";
			if (nightscoutTreatmentsURL.indexOf('http') == -1) nightscoutTreatmentsURL = "https://" + nightscoutTreatmentsURL;
		}
		
		private static function activateEventListeners():void
		{
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBgreadingReceived);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, onCalibrationReceived);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.NEW_CALIBRATION_EVENT, onCalibrationReceived);
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppActivated);
			NetworkInfo.networkInfo.addEventListener(NetworkInfoEvent.CHANGE, onNetworkChange);
		}
		private static function deactivateEventListeners():void
		{
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBgreadingReceived);
			CalibrationService.instance.removeEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, onCalibrationReceived);
			CalibrationService.instance.removeEventListener(CalibrationServiceEvent.NEW_CALIBRATION_EVENT, onCalibrationReceived);
			Spike.instance.removeEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppActivated);
			NetworkInfo.networkInfo.removeEventListener(NetworkInfoEvent.CHANGE, onNetworkChange);
		}
		
		private static function resync():void
		{
			if (activeGlucoseReadings.length > 0) syncGlucoseReadings();
			
			if (activeCalibrations.length > 0) syncCalibrations();
			
			if (activeVisualCalibrations.length > 0) syncVisualCalibrations();
			
			if (activeSensorStarts.length > 0) syncSensorStart();
		}
		
		/**
		 * General Event Listeners
		 */
		private static function onConnectionFailed(error:Error, mode:String):void
		{
			if (mode == MODE_GLUCOSE_READING)
			{
				Trace.myTrace("NightscoutService.as", "In onConnectionFailed. Error uploading glucose readings. Error: " + error.message);
				syncGlucoseReadingsActive = false;
			}
			else if (mode == MODE_CALIBRATION)
			{
				Trace.myTrace("NightscoutService.as", "In onConnectionFailed. Error uploading calibrations. Error: " + error.message);
				syncCalibrationsActive = false;
			}
			else if (mode == MODE_VISUAL_CALIBRATION)
			{
				Trace.myTrace("NightscoutService.as", "In onConnectionFailed. Error uploading visual calibrations. Error: " + error.message);
				syncVisualCalibrationsActive = false;
			}
			else if (mode == MODE_SENSOR_START)
			{
				Trace.myTrace("NightscoutService.as", "in onConnectionFailed. Error uploading sensor start event. Error: " + error.message);
				syncSensorStartActive = false;
			}
			else if (mode == MODE_TEST_CREDENTIALS)
			{
				Trace.myTrace("NightscoutService.as", "in onConnectionFailed. Can't make connection to the server. Error: " +  error.message);
				externalAuthenticationCall = false;
			}
		}
		
		private static function onSettingChanged(e:SettingsServiceEvent):void
		{
			if (ignoreSettingsChanged)
			{
				setupNightscoutProperties();
				return;
			}
			
			if (e.data == CommonSettings.COMMON_SETTING_NIGHTSCOUT_ON) 
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_ON) == "true")
				{
					setupNightscoutProperties();
					if (CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_URL_AND_API_SECRET_TESTED, "false"))
						testNightscoutCredentials();
					else
					{
						Trace.myTrace("NightscoutService.as", "in onSettingChanged, activating service");
						activateService();
					}
				}
				else
				{
					Trace.myTrace("NightscoutService.as", "in onSettingChanged, deactivating service.");
					deactivateService();
				}
			}
			else if (e.data == CommonSettings.COMMON_SETTING_API_SECRET || e.data == CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) 
			{
				Trace.myTrace("NightscoutService.as", "in onSettingChanged, restesting credentials");
				deactivateService();
				setupNightscoutProperties();
				testNightscoutCredentials();
			}
			else if (e.data == CommonSettings.COMMON_SETTING_CURRENT_SENSOR && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_ON) == "true" && Sensor.getActiveSensor() != null)
			{
				Trace.myTrace("NightscoutService.as", "in onSettingChanged, uploading new sensor.");
				getSensorStart();
			}
		}
		
		private static function onServiceTimer(e:TimerEvent):void
		{
			resync();
		}
		
		private static function onNetworkChange( event:NetworkInfoEvent ):void
		{
			if(NetworkInfo.networkInfo.isReachable() && networkChangeOcurrances > 0)
			{
				Trace.myTrace("NightscoutService.as", "Network is reachable again. Calling resync.");
				resync();
			}
			else
				networkChangeOcurrances++;
		}
		
		private static function onAppActivated(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "App in foreground. Calling resync.");
			resync();
		}

		/**
		 * Getters & Setters (With Timeout Management)
		 */
		private static function get syncGlucoseReadingsActive():Boolean
		{
			if (!_syncGlucoseReadingsActive)
				return false;
			
			var now:Number = (new Date()).valueOf();
			
			if (now - syncGlucoseReadingsActiveLastChange > MAX_SYNC_TIME)
			{
				syncGlucoseReadingsActiveLastChange = now;
				_syncGlucoseReadingsActive = false;
				return false;
			}
			
			return true;
		}

		private static function set syncGlucoseReadingsActive(value:Boolean):void
		{
			syncGlucoseReadingsActiveLastChange = (new Date()).valueOf();
			_syncGlucoseReadingsActive = value;
		}

		private static function get syncCalibrationsActive():Boolean
		{
			if (!_syncCalibrationsActive)
				return false;
			
			var now:Number = (new Date()).valueOf();
			
			if (now - syncCalibrationsActiveLastChange > MAX_SYNC_TIME)
			{
				syncCalibrationsActiveLastChange = now;
				_syncCalibrationsActive = false;
				return false;
			}
			
			return true;
		}

		private static function set syncCalibrationsActive(value:Boolean):void
		{
			syncCalibrationsActiveLastChange = (new Date()).valueOf();
			_syncCalibrationsActive = value;
		}

		private static function get syncVisualCalibrationsActive():Boolean
		{
			if (!_syncVisualCalibrationsActive)
				return false;
			
			var now:Number = (new Date()).valueOf();
			
			if (now - syncVisualCalibrationsActiveLastChange > MAX_SYNC_TIME)
			{
				syncVisualCalibrationsActiveLastChange = now;
				_syncVisualCalibrationsActive = false;
				return false;
			}
			
			return true;
		}

		private static function set syncVisualCalibrationsActive(value:Boolean):void
		{
			syncVisualCalibrationsActiveLastChange = (new Date()).valueOf();
			_syncVisualCalibrationsActive = value;
		}

		private static function get syncSensorStartActive():Boolean
		{
			if (!_syncSensorStartActive)
				return false;
			
			var now:Number = (new Date()).valueOf();
			
			if (now - syncSensorStartActiveLastChange > MAX_SYNC_TIME)
			{
				syncSensorStartActiveLastChange = now;
				_syncSensorStartActive = false;
				return false;
			}
				
			return true;
		}

		private static function set syncSensorStartActive(value:Boolean):void
		{
			syncSensorStartActiveLastChange = (new Date()).valueOf();
			_syncSensorStartActive = value;
		}
	}
}