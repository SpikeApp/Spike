package services
{
	import com.adobe.utils.DateUtil;
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.distriqt.extension.networkinfo.events.NetworkInfoEvent;
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.util.Hex;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import mx.utils.ObjectUtil;
	import mx.utils.StringUtil;
	
	import spark.formatters.DateTimeFormatter;
	
	import cryptography.Keys;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.FollowerBgReading;
	import database.Sensor;
	
	import events.CalibrationServiceEvent;
	import events.FollowerEvent;
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	import events.UserInfoEvent;
	
	import feathers.layout.HorizontalAlign;
	
	import model.Forecast;
	import model.ModelLocator;
	
	import network.NetworkConnector;
	
	import treatments.Insulin;
	import treatments.ProfileManager;
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import ui.chart.helpers.GlucoseFactory;
	import ui.popups.AlertManager;
	
	import utils.BatteryInfo;
	import utils.Constants;
	import utils.Cryptography;
	import utils.SpikeJSON;
	import utils.TimeSpan;
	import utils.Trace;
	import utils.UniqueId;
	
	[ResourceBundle("nightscoutservice")]
	[ResourceBundle("treatments")]
	[ResourceBundle("globaltranslations")]
	
	public class NightscoutService extends EventDispatcher
	{
		/* Constants */
		private static const MODE_GLUCOSE_READING:String = "glucoseReading";
		private static const MODE_GLUCOSE_READING_GET:String = "glucoseReadingGet";
		private static const MODE_CALIBRATION:String = "calibration";
		private static const MODE_VISUAL_CALIBRATION:String = "visualCalibration";
		private static const MODE_SENSOR_START:String = "sensorStart";
		private static const MODE_TEST_CREDENTIALS:String = "testCredentials";
		private static const MODE_TREATMENT_UPLOAD:String = "treatmentUpload";
		private static const MODE_TREATMENT_DELETE:String = "treatmentDelete";
		private static const MODE_PROFILE_GET:String = "profileGet";
		private static const MODE_TREATMENTS_GET:String = "treatmentsGet";
		private static const MODE_PROPERTIES_V2_GET:String = "propertiesV2Get";
		private static const MODE_USER_INFO_GET:String = "userInfoGet";
		private static const MODE_BATTERY_UPLOAD:String = "batteryUpload";
		private static const MODE_PREDICTIONS_UPLOAD:String = "predictionsUpload";
		private static const MAX_SYNC_TIME:Number = TimeSpan.TIME_45_SECONDS; //45 seconds
		private static const MAX_RETRIES_FOR_TREATMENTS:int = 1;
		
		/* Logical Variables */
		private static var nowTimestamp:Number = (new Date()).valueOf();
		private static var serviceStarted:Boolean = false;
		public static var serviceActive:Boolean = false;
		private static var _syncGlucoseReadingsActive:Boolean = false;
		private static var syncGlucoseReadingsActiveLastChange:Number = nowTimestamp;
		private static var _syncCalibrationsActive:Boolean = false;
		private static var syncCalibrationsActiveLastChange:Number = nowTimestamp;
		private static var _syncVisualCalibrationsActive:Boolean = false;
		private static var syncVisualCalibrationsActiveLastChange:Number = nowTimestamp;
		private static var _syncSensorStartActive:Boolean = false;
		private static var syncSensorStartActiveLastChange:Number = nowTimestamp;
		private static var externalAuthenticationCall:Boolean = false;
		public static var ignoreSettingsChanged:Boolean = false;
		public static var uploadSensorStart:Boolean = true;
		private static var serviceHalted:Boolean = false;
		private static var isNightscoutMgDl:Boolean = true;
		
		/* Data Variables */
		private static var apiSecret:String;
		private static var nightscoutEventsURL:String;
		private static var nightscoutTreatmentsURL:String;
		private static var nightscoutPebbleURL:String;
		private static var nightscoutPropertiesV2URL:String;
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
		
		/* Follower */
		private static var nextFollowDownloadTime:Number = 0;
		private static var timeOfFirstBgReadingToDowload:Number;
		private static var lastFollowDownloadAttempt:Number;
		private static var waitingForNSData:Boolean = false;
		private static var nightscoutFollowURL:String = "";
		private static var nightscoutFollowOffset:Number = 0;
		public static var followerModeEnabled:Boolean = false;
		private static var followerTimer:int = -1;
		private static var nightscoutFollowAPISecret:String = "";
		private static var nightscoutProfileURL:String = "";
		private static var isNSProfileSet:Boolean = false;
		private static var nightscoutDeviceStatusURL:String = "";
		
		private static var _instance:NightscoutService = new NightscoutService();

		/* Treatments */
		private static var nightscoutTreatmentsSyncEnabled:Boolean = true;
		private static var treatmentsEnabled:Boolean = true;
		private static var profileAlertShown:Boolean = false;
		private static var activeTreatmentsUpload:Array = [];
		private static var activeTreatmentsDelete:Array = [];
		private static var retriesForTreatmentsDownload:int = 0;
		private static var retriesForPropertiesV2Download:int = 0;
		private static var _syncTreatmentsUploadActive:Boolean = false;
		private static var _syncTreatmentsDeleteActive:Boolean = false;
		private static var _syncTreatmentsDownloadActive:Boolean = false;
		private static var _syncPebbleActive:Boolean = false;
		private static var syncTreatmentsUploadActiveLastChange:Number = (new Date()).valueOf();
		private static var syncTreatmentsDeleteActiveLastChange:Number = (new Date()).valueOf();
		private static var syncTreatmentsDownloadActiveLastChange:Number = (new Date()).valueOf();
		private static var syncPebbleActiveLastChange:Number = (new Date()).valueOf();
		private static var lastRemoteTreatmentsSync:Number = 0;
		private static var lastRemoteProfileSync:Number = 0;
		private static var lastRemotePropertiesV2Sync:Number = 0;
		private static var pumpUserEnabled:Boolean;
		private static var phoneBatteryLevel:Number = 0;
		private static var lastPredictionsUploadTimestamp:Number = 0;
		private static var propertiesV2Timeout:uint = 0;

		public function NightscoutService()
		{
			if (_instance != null)
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
			formatter.useUTC = true;
			
			//Event listener for settings changes
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingChanged);
			
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			
			setupNightscoutProperties();
			
			if (CGMBlueToothDevice.isFollower() && 
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE).toUpperCase() == "FOLLOWER" &&
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE).toUpperCase() == "NIGHTSCOUT" &&
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != ""
			)
			{
				setupFollowerProperties();
				activateFollower();
			}
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_ON) == "true" &&
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) != "" &&
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET) != "" &&
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URL_AND_API_SECRET_TESTED) == "false")
			{
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
			newReading["device"] = CGMBlueToothDevice.name;
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
		
		private static function getInitialGlucoseReadings(e:Event = null):void
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
			
			if (Calibration.allForSensor().length < 2 && !CGMBlueToothDevice.isFollower()) 
				return;
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON) == "true" && NetworkInfo.networkInfo.isWWAN() && !CGMBlueToothDevice.isFollower())
				return;
			
			syncGlucoseReadingsActive = true;
			
			//Upload Glucose Readings
			//NetworkConnector.createNSConnector(nightscoutEventsURL, apiSecret, URLRequestMethod.POST, JSON.stringify(activeGlucoseReadings), MODE_GLUCOSE_READING, onUploadGlucoseReadingsComplete, onConnectionFailed);
			NetworkConnector.createNSConnector(nightscoutEventsURL, apiSecret, URLRequestMethod.POST, SpikeJSON.stringify(activeGlucoseReadings), MODE_GLUCOSE_READING, onUploadGlucoseReadingsComplete, onConnectionFailed);
		}
		
		private static function onBgreadingReceived(e:Event):void 
		{
			//Validation
			if (serviceHalted)
				return;
			
			var latestGlucoseReading:BgReading;
			if(!CGMBlueToothDevice.isFollower())
				latestGlucoseReading= BgReading.lastNoSensor();
			else
				latestGlucoseReading= BgReading.lastWithCalculatedValue();
			
			if(latestGlucoseReading == null || (latestGlucoseReading.calculatedValue == 0 && latestGlucoseReading.calibration == null))
				return;
			
			//Trace.myTrace("NightscoutService.as", "in onBgreadingReceived, COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP = " + (new Date(new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP)))).toLocaleString());
			//Trace.myTrace("NightscoutService.as", "in onBgreadingReceived, latestGlucoseReading.timestamp = " + (new Date(latestGlucoseReading.timestamp)).toLocaleString());
			if (!(latestGlucoseReading.timestamp > new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP)))) {
				//Trace.myTrace("NightscoutService.as", "in onBgreadingReceived, ignoring the reading");
				return;
			}
			
			activeGlucoseReadings.push(createGlucoseReading(latestGlucoseReading));
			
		}
		
		private static function onLastBgreadingReceived(e:Event):void 
		{
			//Validation
			if (serviceHalted)
				return;
			
			syncGlucoseReadings();
		}
		
		private static function onUploadGlucoseReadingsComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "in onUploadGlucoseReadingsComplete.");
			
			//Validation
			if (serviceHalted)
				return;
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			if (loader == null || loader.data == null)
				return;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onUploadGlucoseReadingsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onConnectionFailed);
			loader = null;
			
			//Check response
			if (response.indexOf(CGMBlueToothDevice.name) != -1)
			{
				Trace.myTrace("NightscoutService.as", "Glucose reading upload was successful.");
				if (initialGlucoseReadingsIndex == 0)
				{
					//It's a new reading and there's no previous initial readings in queue
					if (activeGlucoseReadings != null && activeGlucoseReadings.length > 0 && activeGlucoseReadings[initialGlucoseReadingsIndex -1] != null && activeGlucoseReadings[initialGlucoseReadingsIndex -1].date != null) 
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP, String(activeGlucoseReadings[activeGlucoseReadings.length -1].date));
					else
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP, String(new Date().valueOf()));
							
					activeGlucoseReadings.length = 0; 
				}
				else
				{
					//It's an initial readings call
					if (activeGlucoseReadings != null && activeGlucoseReadings[initialGlucoseReadingsIndex -1] != null && activeGlucoseReadings[initialGlucoseReadingsIndex -1].date != null)
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP, String(activeGlucoseReadings[initialGlucoseReadingsIndex -1].date));
					else
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP, String(new Date().valueOf()));
					
					if (activeGlucoseReadings != null)
						activeGlucoseReadings = activeGlucoseReadings.slice(0, initialGlucoseReadingsIndex);
					
					initialGlucoseReadingsIndex = 0;
				}
				
				//Get remote treatments/IOB-COB
				if (ModelLocator.bgReadings != null && ModelLocator.bgReadings.length > 0 && treatmentsEnabled && nightscoutTreatmentsSyncEnabled)
				{
					getRemoteTreatments();
					
					if (pumpUserEnabled)
						propertiesV2Timeout = setTimeout(getPropertiesV2Endpoint, TimeSpan.TIME_1_MINUTE);
				}
				
				//Upload predictions
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_PREDICTIONS_UPLOADER_ON) == "true")
					uploadPredictions();
				
				//Upload battery status
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_BATTERY_UPLOADER_ON) == "true")
					uploadBatteryStatus();
			}
			else
			{
				Trace.myTrace("NightscoutService.as", "Error uploading glucose reading. Maybe server is down or no Internet connection? Server response: " + response);
			}
			
			syncGlucoseReadingsActive = false;
		}
		
		/**
		 * PREDICTIONS
		 */
		public static function uploadPredictions(forceIOBCOBRefresh:Boolean = false):void
		{
			Trace.myTrace("NightscoutService.as", "uploadPredictions called");
			
			//Validation #1
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_ENABLED) != "true" || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_PREDICTIONS_UPLOADER_ON) != "true" || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true" || CGMBlueToothDevice.isFollower() || !serviceActive || serviceHalted)
				return;
			
			//Validation #2
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON) == "true" && NetworkInfo.networkInfo.isWWAN() && !CGMBlueToothDevice.isFollower())
				return;
			
			//Get Predictions
			var predictionsData:Object = Forecast.predictBGs(Forecast.getCurrentPredictionsDuration(), forceIOBCOBRefresh);
			
			//Validation #3
			if (predictionsData == null)
				return;
			
			//Format NS predictions JSON
			var now:Number = new Date().valueOf();
			
			if (!forceIOBCOBRefresh)
			{
				var lastBgReading:BgReading = BgReading.lastWithCalculatedValue();
				if (lastBgReading != null && now - lastBgReading._timestamp < TimeSpan.TIME_6_MINUTES && lastPredictionsUploadTimestamp != lastBgReading._timestamp)
				{
					now = lastBgReading._timestamp;
				}
			}
			
			lastPredictionsUploadTimestamp = now;
			
			var formattedNow:String = formatter.format(now).replace("000+0000", "000Z");
			var currentIOB:Object = TreatmentsManager.getTotalIOB(now);
			var currentCOB:Object = TreatmentsManager.getTotalCOB(now, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps");
			var i:int;
			
			var predictBGsObject:Object = {};
			var iobPredictions:Array;
			var cobPredictions:Array;
			var uamPredictions:Array;
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_SINGLE_LINE_ENABLED) != "true")
			{
				if (predictionsData.IOB != null)
				{
					iobPredictions = predictionsData.IOB.concat();
					
					for(i = iobPredictions.length - 1 ; i >= 0; i--)
					{
						iobPredictions[i] = Math.round(iobPredictions[i]);
					}
					
					iobPredictions[0] = Number.NaN;
					
					predictBGsObject["IOB"] = iobPredictions;
				}
				if (predictionsData.COB != null)
				{
					cobPredictions = predictionsData.COB.concat();
					
					for(i = cobPredictions.length - 1 ; i >= 0; i--)
					{
						cobPredictions[i] = Math.round(cobPredictions[i]);
					}
					
					cobPredictions[0] = Number.NaN;
					
					predictBGsObject["COB"] = cobPredictions;
				}
				if (predictionsData.UAM != null)
				{
					uamPredictions = predictionsData.UAM.concat();
					
					for(i = uamPredictions.length - 1 ; i >= 0; i--)
					{
						uamPredictions[i] = Math.round(uamPredictions[i]);
					}
					
					uamPredictions[0] = Number.NaN;
					
					predictBGsObject["UAM"] = uamPredictions;
				}
			}
			else
			{
				var defaultPrediction:String = Forecast.determineDefaultPredictionCurve(predictionsData);
				
				if (defaultPrediction == "UAM")
				{
					uamPredictions = predictionsData.UAM.concat();
					
					for(i = uamPredictions.length - 1 ; i >= 0; i--)
					{
						uamPredictions[i] = Math.round(uamPredictions[i]);
					}
					
					uamPredictions[0] = Number.NaN;
					
					predictBGsObject["UAM"] = uamPredictions;
				}
				else if (defaultPrediction == "COB")
				{
					cobPredictions = predictionsData.COB.concat();
					
					for(i = cobPredictions.length - 1 ; i >= 0; i--)
					{
						cobPredictions[i] = Math.round(cobPredictions[i]);
					}
					
					cobPredictions[0] = Number.NaN;
					
					predictBGsObject["COB"] = cobPredictions;
				}
				else if (defaultPrediction == "IOB")
				{
					iobPredictions = predictionsData.IOB.concat();
					
					for(i = iobPredictions.length - 1 ; i >= 0; i--)
					{
						iobPredictions[i] = Math.round(iobPredictions[i]);
					}
					
					iobPredictions[0] = Number.NaN;
					
					predictBGsObject["IOB"] = iobPredictions;
				}
			}
			
			var suggestedObject:Object = {};
			suggestedObject["bg"] = predictionsData.bg != null ? Math.round(predictionsData.bg) : Number.NaN;
			suggestedObject["eventualBG"] = predictionsData.eventualBG != null ? predictionsData.eventualBG : Number.NaN;
			suggestedObject["deliverAt"] = formattedNow;
			suggestedObject["predBGs"] = predictBGsObject;
			suggestedObject["COB"] = currentCOB.cob;
			suggestedObject["IOB"] = currentIOB.iob;
			suggestedObject["timestamp"] = formattedNow;
			suggestedObject["reason"] = "COB: " + currentCOB.cob + 
										(predictionsData.isf != null ? ", ISF: " + (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? Math.round(predictionsData.isf) : Math.round(BgReading.mgdlToMmol(predictionsData.isf * 10)) / 10) : "") + 	
										(predictionsData.cr != null ? ", CR: " + predictionsData.cr : "") + 	
										(predictionsData.bgImpact != null ? ", BGI: " + (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? Math.round(predictionsData.bgImpact) : Math.round(BgReading.mgdlToMmol(predictionsData.bgImpact * 10)) / 10) : "") + 	
										(predictionsData.deviation != null ? ", Dev: " + (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? Math.round(predictionsData.deviation) : Math.round(BgReading.mgdlToMmol(predictionsData.deviation * 10)) / 10) : "") + 
										(predictionsData.minPredBG != null ? ", minPredBG: " + (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? Math.round(predictionsData.minPredBG) : Math.round(BgReading.mgdlToMmol(predictionsData.minPredBG * 10)) / 10) : "") + 
										(predictionsData.eventualBG != null ? ", eventualBG: " + (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? Math.round(predictionsData.eventualBG) : Math.round(BgReading.mgdlToMmol(predictionsData.eventualBG * 10)) / 10) : "") +
										(predictionsData.IOBpredBG != null ? ", IOBpredBG: " + (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? Math.round(predictionsData.IOBpredBG) : Math.round(BgReading.mgdlToMmol(predictionsData.IOBpredBG * 10)) / 10) : "") +
										(predictionsData.COBpredBG != null ? ", COBpredBG: " + (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? Math.round(predictionsData.COBpredBG) : Math.round(BgReading.mgdlToMmol(predictionsData.COBpredBG * 10)) / 10) : "") +
										(predictionsData.UAMpredBG != null ? ", UAMpredBG: " + (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? Math.round(predictionsData.UAMpredBG) : Math.round(BgReading.mgdlToMmol(predictionsData.UAMpredBG * 10)) / 10) : "");
			
			var openAPSObject:Object = {};
			openAPSObject["iob"] = {
				iob: currentIOB.iob,
					activity: currentIOB.activityForecast,
					time: formattedNow
			};
			openAPSObject["suggested"] = suggestedObject;
			
			var predictionsNSObject:Object = {};
			predictionsNSObject["_id"] = UniqueId.createEventId();
			predictionsNSObject["device"] = "openaps://" + "Spike " + Constants.deviceModelName;
			predictionsNSObject["created_at"] = formattedNow;
			predictionsNSObject["openaps"] = openAPSObject;
			
			NetworkConnector.createNSConnector(nightscoutDeviceStatusURL, apiSecret, URLRequestMethod.POST, SpikeJSON.stringify(predictionsNSObject), MODE_PREDICTIONS_UPLOAD, onUploadPredictionsComplete, onConnectionFailed);
		}
		
		private static function onUploadPredictionsComplete(e:Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			Trace.myTrace("NightscoutService.as", "onUploadPredictionsComplete called!");
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onUploadBatteryStatusComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onConnectionFailed);
			loader = null;
			
			if (response.indexOf("openaps") != -1)
			{
				Trace.myTrace("NightscoutService.as", "Predictions uploaded successfully!");
			}
			else
			{
				Trace.myTrace("NightscoutService.as", "Error uploading predictions! Response: " + response);
			}
		}
		
		/**
		 * BATTERY STATUS
		 */
		private static function uploadBatteryStatus():void
		{
			Trace.myTrace("NightscoutService.as", "uploadBatteryStatus called");
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON) == "true" && NetworkInfo.networkInfo.isWWAN() && !CGMBlueToothDevice.isFollower())
				return;
			
			phoneBatteryLevel = BatteryInfo.getBatteryLevel();
			if ((String(phoneBatteryLevel) == CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_LAST_BATTERY_UPLOADED) || Math.abs(phoneBatteryLevel - Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_LAST_BATTERY_UPLOADED))) < 3) && new Date().valueOf() - Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_LAST_BATTERY_UPLOADED_TIMESTAMP)) < TimeSpan.TIME_24_MINUTES)
			{
				Trace.myTrace("NightscoutService.as", "Battery level has not changed and is current. Skipping...");
				return;
			}
			
			var batteryStatus:Object = GlucoseFactory.getTransmitterBattery();
			var deviceModel:String = "Spike " + Constants.deviceModelName;
			
			var uploaderBatteryStatus:Object = {};
			uploaderBatteryStatus["device"] = deviceModel;
			uploaderBatteryStatus["uploader"] = { name: deviceModel, battery: phoneBatteryLevel, tName: CGMBlueToothDevice.getTransmitterName(), tBatteryValue: batteryStatus.level, tBatteryColor: batteryStatus.color };
			
			NetworkConnector.createNSConnector(nightscoutDeviceStatusURL, apiSecret, URLRequestMethod.POST, SpikeJSON.stringify(uploaderBatteryStatus), MODE_BATTERY_UPLOAD, onUploadBatteryStatusComplete, onConnectionFailed);
		}
		
		private static function onUploadBatteryStatusComplete(e:Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			Trace.myTrace("NightscoutService.as", "onUploadBatteryStatusComplete called!");
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onUploadBatteryStatusComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onConnectionFailed);
			loader = null;
			
			if (response.indexOf("uploader") != -1)
			{
				Trace.myTrace("NightscoutService.as", "Battery status uploaded successfully!");
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_LAST_BATTERY_UPLOADED, String(phoneBatteryLevel));
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_LAST_BATTERY_UPLOADED_TIMESTAMP, String(new Date().valueOf()));
			}
			else
				Trace.myTrace("NightscoutService.as", "Error uploading battery status! Response: " + response);
		}
		
		/**
		 * PROFILE
		 */
		private static function getNightscoutProfile():void
		{
			Trace.myTrace("NightscoutService.as", "getNightscoutProfile called!");
			
			if (!CGMBlueToothDevice.isFollower() && !serviceActive)
				return;
			
			if (CGMBlueToothDevice.isFollower() && !followerModeEnabled)
				return;
			
			var now:Number = new Date().valueOf();
			
			if (now - lastRemoteProfileSync < TimeSpan.TIME_30_SECONDS)
			{
				Trace.myTrace("NightscoutService.as", "Fetched profile less than 30 seconds ago. Ignoring!");
				return;
			}
			
			lastRemoteProfileSync = now;
			
			if (!isNSProfileSet)
			{
				if (!NetworkInfo.networkInfo.isReachable())
				{
					if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled)
					{
						Trace.myTrace("NightscoutService.as", "There's no Internet connection. Will retry in 30 seconds!");
						setTimeout(getNightscoutProfile, TimeSpan.TIME_30_SECONDS);
					}
					
					return;
				}
				
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON) == "true" && NetworkInfo.networkInfo.isWWAN() && !CGMBlueToothDevice.isFollower())
					return;
				
				//Define API secret
				var profileAPISecret:String = "";
				if (CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "")
					profileAPISecret = nightscoutFollowAPISecret;
				else if (!CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET) != "")
					profileAPISecret = apiSecret;
				
				//Fetch profile
				NetworkConnector.createNSConnector(nightscoutProfileURL, profileAPISecret != "" ? profileAPISecret : null, URLRequestMethod.GET, null, MODE_PROFILE_GET, onGetProfileComplete, onConnectionFailed);
			}
		}
		
		private static function onGetProfileComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "onGetProfileComplete called!");
			
			//Validation
			if (serviceHalted)
				return;
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onDownloadGlucoseReadingsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onConnectionFailed);
			loader = null;
			
			//Validate response
			if (response.indexOf("defaultProfile") != -1 || response.indexOf("created_at") != -1)
			{
				try
				{
					var profileProperties:Object = SpikeJSON.parse(response);
					if (profileProperties != null)
					{
						//Get Nightscout default unit
						if (profileProperties[0].units != null && (profileProperties[0].units as String).indexOf("mg") == -1)
							isNightscoutMgDl = false;
						
						var dia:Number = Number.NaN;
						var carbAbsorptionRate:Number = Number.NaN;
						
						if (profileProperties[0].dia)
							dia = Number(profileProperties[0].dia);
						else if (profileProperties[0].store && profileProperties[0].defaultProfile && profileProperties[0].store[profileProperties[0].defaultProfile].dia)
							dia = Number(profileProperties[0].store[profileProperties[0].defaultProfile].dia);
						
						if (profileProperties[0].carbs_hr)
							carbAbsorptionRate = Number(profileProperties[0].carbs_hr);
						else if (profileProperties[0].store && profileProperties[0].defaultProfile && profileProperties[0].store[profileProperties[0].defaultProfile].carbs_hr)
							carbAbsorptionRate = Number(profileProperties[0].store[profileProperties[0].defaultProfile].carbs_hr);
						
						
						if (isNaN(dia) || isNaN(carbAbsorptionRate))
						{
							Trace.myTrace("NightscoutService.as", "User has not yet set a profile in Nightscout!");
							
							if (!profileAlertShown)
							{
								AlertManager.showSimpleAlert
								(
									ModelLocator.resourceManagerInstance.getString("globaltranslations","warning_alert_title"),
									ModelLocator.resourceManagerInstance.getString("treatments","nightscout_profile_not_set")
								);
									
								profileAlertShown = true;
							}
							
							return;
						}
						
						Trace.myTrace("NightscoutService.as", "Profile retrieved and parsed successfully!" + " Unit: " + (isNightscoutMgDl ? "mg/dL" : "mmol/L")  + " DIA: " + dia + " CAR: " + carbAbsorptionRate);
						
						isNSProfileSet = true; //Mark profile as downloaded
							
						//Add nightscout insulin to Spike and don't save it to DB
						ProfileManager.addInsulin(ModelLocator.resourceManagerInstance.getString("treatments","nightscout_insulin"), dia, "", CGMBlueToothDevice.isFollower() ? true : false, "000000", !CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING ? true : false, true);
							
						//Add nightscout carbs absorption rate and don't save it to DB
						ProfileManager.addNightscoutCarbAbsorptionRate(carbAbsorptionRate);
							
						//Get treatmenents
						getRemoteTreatments();
						
						if (pumpUserEnabled)
							getPropertiesV2Endpoint();
					}
				} 
				catch(error:Error) 
				{
					Trace.myTrace("NightscoutService.as", "Error parsing profile properties. Will try on next transmitter reading! Response: " + response);
				}
			}
			else
				Trace.myTrace("NightscoutService.as", "Unexpected Nightscout response. Will try on next transmitter reading! Response: " + response);
		}
		
		/**
		 * FOLLOWER MODE
		 */
		private static function setupFollowerProperties():void
		{
			nightscoutFollowURL = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) + "/api/v1/entries/sgv.json?";
			if (nightscoutFollowURL.indexOf('http') == -1) nightscoutFollowURL = "https://" + nightscoutFollowURL;
			
			nightscoutFollowOffset = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_OFFSET));
			
			nightscoutFollowAPISecret = Hex.fromArray(hash.hash(Hex.toArray(Hex.fromString(Cryptography.decryptStringLight(Keys.STRENGTH_256_BIT, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET))))));
		}
		
		private static function activateFollower():void
		{
			Trace.myTrace("NightscoutService.as", "Follower mode activated!");
			
			followerModeEnabled = true;
			
			clearTimeout(followerTimer);
			
			clearTreatments();
			
			setupNightscoutProperties();
			getRemoteReadings();
			if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled)
				setTimeout(getNightscoutProfile, 1000);
			
			activateTimer();
		}
		
		private static function deactivateFollower():void
		{
			Trace.myTrace("NightscoutService.as", "Follower mode deactivated!");
			
			clearTimeout(followerTimer);
			
			followerModeEnabled = false;
			
			deactivateTimer();
			
			nextFollowDownloadTime = 0;
			
			ModelLocator.bgReadings.length = 0;
			
			clearTreatments();
		}
		
		private static function clearTreatments():void
		{
			TreatmentsManager.removeAllTreatmentsFromMemory();
			activeCalibrations.length = 0;
			activeSensorStarts.length = 0;
			activeGlucoseReadings.length = 0;
			activeTreatmentsDelete.length = 0;
			activeTreatmentsUpload.length = 0;
			activeVisualCalibrations.length = 0;
			lastRemoteProfileSync = 0;
			lastRemoteTreatmentsSync = 0;
			isNSProfileSet = false;
		}
		
		private static function calculateNextFollowDownloadTime():void 
		{
			var now:Number = (new Date()).valueOf();
			var latestBGReading:BgReading = BgReading.lastNoSensor();
			if (latestBGReading != null) 
			{
				if (now - latestBGReading.timestamp >= TimeSpan.TIME_5_MINUTES_30_SECONDS)
				{
					//Some users are uploading values to nightscout with a bigger delay than it was supposed (>10 seconds)... 
					//This will make Spike retry in 10sec so they don't see outdated values in the chart.
					nextFollowDownloadTime = now + TimeSpan.TIME_10_SECONDS; 
				}
				else
				{
					nextFollowDownloadTime = latestBGReading.timestamp + TimeSpan.TIME_5_MINUTES_10_SECONDS;
					while (nextFollowDownloadTime < now) 
					{
						nextFollowDownloadTime += TimeSpan.TIME_5_MINUTES;
					}
				}
			}
			else
				nextFollowDownloadTime = now + TimeSpan.TIME_5_MINUTES;		
		}
		
		private static function setNextFollowerFetch(delay:int = 0):void
		{
			var now:Number = new Date().valueOf();
			
			calculateNextFollowDownloadTime();
			var interval:Number = nextFollowDownloadTime + delay - now;
			clearTimeout(followerTimer);
			followerTimer = setTimeout(getRemoteReadings, interval);
			
			var timeSpan:TimeSpan = TimeSpan.fromMilliseconds(interval);
			Trace.myTrace("NightscoutService.as", "Fetching new follower data in: " + timeSpan.minutes + "m " + timeSpan.seconds + "s");
		}
		
		private static function getRemoteReadings():void
		{
			Trace.myTrace("NightscoutService.as", "getRemoteReadings called!");
			
			var now:Number = (new Date()).valueOf();
			
			if (!CGMBlueToothDevice.isFollower())
			{
				Trace.myTrace("NightscoutService.as", "Spike is not in follower mode. Aborting!");
				
				deactivateFollower();
				
				return
			}
			
			if (nightscoutFollowURL == "")
			{
				Trace.myTrace("NightscoutService.as", "Follower URL is not set. Aborting!");
				
				deactivateFollower();
				
				return;
			}
				
			if (!NetworkInfo.networkInfo.isReachable())
			{
				Trace.myTrace("NightscoutService.as", "There's no Internet connection. Will try again later!");
				
				setNextFollowerFetch(TimeSpan.TIME_10_SECONDS); //Plus 10 seconds to ensure it passes the getRemoteReadings validation
				
				return;
			}
			
			var latestBGReading:BgReading = BgReading.lastWithCalculatedValue();
			
			if (latestBGReading != null && !isNaN(latestBGReading.timestamp) && now - latestBGReading.timestamp < TimeSpan.TIME_5_MINUTES)
				return;
			
			if (nextFollowDownloadTime < now) 
			{
				if (latestBGReading == null) 
					timeOfFirstBgReadingToDowload = now - TimeSpan.TIME_24_HOURS;
				else
					timeOfFirstBgReadingToDowload = latestBGReading.timestamp + 1; //We add 1ms to avoid overlaps
				
				var numberOfReadings:Number = ((now - timeOfFirstBgReadingToDowload) / TimeSpan.TIME_1_HOUR * 12) + 1; //Add one more just to make sure we get all readings
				if (latestBGReading == null) numberOfReadings *= 2;
				
				var parameters:URLVariables = new URLVariables();
				parameters["find[dateString][$gte]"] = timeOfFirstBgReadingToDowload;
				parameters["count"] = Math.round(numberOfReadings);
				
				waitingForNSData = true;
				lastFollowDownloadAttempt = (new Date()).valueOf();
				
				NetworkConnector.createNSConnector(nightscoutFollowURL + parameters.toString(), CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "" ? nightscoutFollowAPISecret : null, URLRequestMethod.GET, null, MODE_GLUCOSE_READING_GET, onDownloadGlucoseReadingsComplete, onConnectionFailed);
			}
			else
			{
				Trace.myTrace("NightscoutService.as", "Tried to make a fetch while in the past. Setting new fetch again.");
				setNextFollowerFetch(TimeSpan.TIME_10_SECONDS); 
			}
		}
		
		private static function onDownloadGlucoseReadingsComplete(e:Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			Trace.myTrace("NightscoutService.as", "onDownloadGlucoseReadingsComplete called!");
			
			var now:Number = (new Date()).valueOf();
			
			//Validate call
			if (!waitingForNSData || (now - lastFollowDownloadAttempt > TimeSpan.TIME_4_MINUTES_30_SECONDS)) 
			{
				Trace.myTrace("NightscoutService.as", "Not waiting for data or last download attempt was more than 4 minutes, 30 seconds ago. Ignoring!");
				waitingForNSData = false;
				return;
			}
			
			waitingForNSData = false;
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onDownloadGlucoseReadingsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onConnectionFailed);
			loader = null;
			
			//Validate response
			if (response.length == 0)
			{
				Trace.myTrace("NightscoutService.as", "Server's gave an empty response. Retrying in a few minutes.");
				
				setNextFollowerFetch();
				
				return;
			}
			
			try 
			{
				var BgReadingsToSend:Array = [];
				//var NSResponseJSON:Object = JSON.parse(response);
				var NSResponseJSON:Object = SpikeJSON.parse(response);
				if (NSResponseJSON is Array) 
				{
					var NSBgReadings:Array = NSResponseJSON as Array;
					try
					{
						//Sort readings by timestamp. Some windows servers return values in reverse
						if (NSBgReadings != null && NSBgReadings is Array && NSBgReadings.length > 1 && NSBgReadings[0].date != null)
							NSBgReadings.sortOn(["date"], Array.NUMERIC | Array.DESCENDING); 
					} 
					catch(error:Error) {}
					
					var newData:Boolean = false;
					
					for(var arrayCounter:int = NSBgReadings.length - 1 ; arrayCounter >= 0; arrayCounter--)
					{
						var NSFollowReading:Object = NSBgReadings[arrayCounter];
						if (NSFollowReading.date) 
						{
							var NSFollowReadingDate:Date = new Date(NSFollowReading.date);
							NSFollowReadingDate.setMinutes(NSFollowReadingDate.minutes + nightscoutFollowOffset);
							
							var NSFollowReadingTime:Number = NSFollowReadingDate.valueOf();
							if (now - NSFollowReadingTime > TimeSpan.TIME_24_HOURS_6_MINUTES)
							{
								continue;
							}
							
							if (isNaN(NSFollowReading.sgv) || NSFollowReading.sgv < 38)
							{
								continue;
							}
							
							if (NSFollowReadingTime >= timeOfFirstBgReadingToDowload) 
							{
								var bgReading:FollowerBgReading = new FollowerBgReading
								(
									NSFollowReadingTime, //timestamp
									null, //sensor id, not known here as the reading comes from NS
									null, //calibration object
									NSFollowReading.unfiltered,  
									NSFollowReading.filtered, 
									Number.NaN, //ageAdjustedRawValue
									false, //calibrationFlag
									NSFollowReading.sgv >= 40 ? NSFollowReading.sgv : 40, //calculatedValue
									Number.NaN, //filteredCalculatedValue
									Number.NaN, //CalculatedValueSlope
									Number.NaN, //a
									Number.NaN, //b
									Number.NaN, //c
									Number.NaN, //ra
									Number.NaN, //cb
									Number.NaN, //rc
									Number.NaN, //rawCalculated
									false, //hideSlope
									NSFollowReading.noise != null ? NSFollowReading.noise : "", //noise
									NSFollowReadingTime, //lastmodifiedtimestamp
									NSFollowReading._id //unique id
								);  
								
								ModelLocator.addBGReading(bgReading);
								bgReading.findSlope(true);
								bgReading.calculateNoise();
								BgReadingsToSend.push(bgReading);
								newData = true;
							} 
							else
								continue;
						} 
						else 
						{
							Trace.myTrace("NightscoutService.as", "Nightscout has returned a reading without date. Ignoring!");
							
							if (NSFollowReading._id)
								Trace.myTrace("NightscoutService.as", "Reading ID: " + NSFollowReading._id);
						}
					}
					
					if (newData) 
					{
						//Notify Listeners
						_instance.dispatchEvent(new FollowerEvent(FollowerEvent.BG_READING_RECEIVED, false, false, BgReadingsToSend));
						
						//Get remote treatments/pebble
						if (ModelLocator.bgReadings != null && ModelLocator.bgReadings.length > 0 && treatmentsEnabled && nightscoutTreatmentsSyncEnabled)
						{
							getRemoteTreatments();
							
							if (pumpUserEnabled)
								getPropertiesV2Endpoint();
						}
					}
				} 
				else 
					Trace.myTrace("NightscoutService.as", "Nightscout response was not a JSON array. Ignoring! Response: " + response);
			} 
			catch (error:Error) 
			{
				Trace.myTrace("NightscoutService.as", "Error parsing Nightscout responde! Error: " + error.message + " Response: " + response);
			}
			
			setNextFollowerFetch();
		}
		
		/**
		 * TREATMENTS
		 */
		private static function createTreatmentObject(treatment:Treatment):Object
		{
			var newTreatment:Object = new Object();
			if (treatment == null)
			{
				return newTreatment;
			}
			
			var usedInsulin:Insulin;
			if (treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS)
			{
				usedInsulin = ProfileManager.getInsulin(treatment.insulinID);
				newTreatment["eventType"] = "Correction Bolus";	
				newTreatment["insulin"] = treatment.insulinAmount;	
				newTreatment["dia"] = treatment.dia;	
				newTreatment["insulinName"] = usedInsulin != null ? usedInsulin.name : ModelLocator.resourceManagerInstance.getString("treatments","nightscout_insulin");	
				newTreatment["insulinType"] = usedInsulin != null ? usedInsulin.type : "Unknown";	
				newTreatment["insulinID"] = treatment.insulinID;	
				newTreatment["insulinPeak"] = usedInsulin != null ? usedInsulin.peak : 75;	
				newTreatment["insulinCurve"] = usedInsulin != null ? usedInsulin.curve : "bilinear";	
			}
			else if (treatment.type == Treatment.TYPE_CARBS_CORRECTION)
			{
				newTreatment["eventType"] = "Carb Correction";	
				newTreatment["carbs"] = treatment.carbs;	
				newTreatment["carbDelayTime"] = treatment.carbDelayTime;	
			}
			else if (treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
			{
				newTreatment["eventType"] = "BG Check";	
				newTreatment["glucose"] = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? treatment.glucose : Math.round(BgReading.mgdlToMmol(treatment.glucose) * 10) / 10;
				newTreatment["glucoseType"] = "Finger";	
			}
			else if (treatment.type == Treatment.TYPE_MEAL_BOLUS)
			{
				usedInsulin = ProfileManager.getInsulin(treatment.insulinID);
				newTreatment["eventType"] = "Meal Bolus";
				newTreatment["insulin"] = treatment.insulinAmount;
				newTreatment["dia"] = treatment.dia;	
				newTreatment["insulinName"] = usedInsulin != null ? usedInsulin.name : ModelLocator.resourceManagerInstance.getString("treatments","nightscout_insulin");
				newTreatment["insulinType"] = usedInsulin != null ? usedInsulin.type : "Unknown";
				newTreatment["carbs"] = treatment.carbs;
				newTreatment["carbDelayTime"] = treatment.carbDelayTime;
				newTreatment["insulinID"] = treatment.insulinID;
				newTreatment["insulinPeak"] = usedInsulin != null ? usedInsulin.peak : 75;	
				newTreatment["insulinCurve"] = usedInsulin != null ? usedInsulin.curve : "bilinear";	
			}
			else if (treatment.type == Treatment.TYPE_NOTE)
			{
				newTreatment["eventType"] = "Note";
				newTreatment["duration"] = 45;
			}
			newTreatment["_id"] = treatment.ID;
			newTreatment["created_at"] = formatter.format(treatment.timestamp).replace("000+0000", "000Z");
			newTreatment["enteredBy"] = "Spike";
			newTreatment["notes"] = treatment.note;
			
			return newTreatment;
		}
		
		private static function deleteInternalTreatment(arrayToDelete:Array, treatment:Treatment):Boolean
		{
			var treatmentDeleted:Boolean = false;
			
			if (arrayToDelete == null || treatment == null)
				return treatmentDeleted;
			
			for (var i:int = 0; i < arrayToDelete.length; i++) 
			{
				var nsTreatment:Object = arrayToDelete[i];
				if (nsTreatment == null || !nsTreatment.hasOwnProperty("_id") || nsTreatment is Treatment)
					continue;
				
				if (nsTreatment["_id"] == treatment.ID)
				{
					arrayToDelete.removeAt(i);
					nsTreatment = null;
					treatmentDeleted = true;
					break;
				}
			}
			
			return treatmentDeleted;
		}
		
		public static function uploadTreatment(treatment:Treatment):void
		{
			if (!CGMBlueToothDevice.isFollower() && !serviceActive)
				return;
			
			if (CGMBlueToothDevice.isFollower() && !followerModeEnabled)
				return;
			
			if (CGMBlueToothDevice.isFollower() && (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) == "" || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) == "" || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) != "Nightscout"))
				return
			
			Trace.myTrace("NightscoutService.as", "in uploadTreatment.");
			
			//Check if the treatment is already present in another queue and delete it.
			if (!deleteInternalTreatment(activeTreatmentsDelete, treatment))
			{
				//Treatments that should not be reuploaded to Nightscout
				if 
				(
					treatment.note.indexOf("Exercise (NS)") != -1 ||
					treatment.note.indexOf("OpenAPS Offline") != -1 ||
					treatment.note.indexOf("Pump Site Change") != -1 ||
					treatment.note.indexOf("Pump Battery Change") != -1 ||
					treatment.note.indexOf("Resume Pump") != -1 ||
					treatment.note.indexOf("Suspend Pump") != -1 ||
					treatment.note.indexOf("Profile Switch") != -1 ||
					treatment.note.indexOf("Combo Bolus") != -1 ||
					treatment.note.indexOf("Announcement") != -1
				)
					return;
				
				//Add treatment to queue
				activeTreatmentsUpload.push(createTreatmentObject(treatment));
				
				//Sync uploads
				syncTreatmentsUpload();
			}
		}
		
		public static function uploadOptimalCalibrationNotification():void
		{
			//Validation
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_UPLOAD_OPTIMAL_CALIBRATION_TO_NS_ON) != "true" || (!CGMBlueToothDevice.isFollower() && !serviceActive) || (CGMBlueToothDevice.isFollower() && !followerModeEnabled))
			{
				return;
			}
			
			//Create Note Treatment
			var opTreatment:Object = new Object();
			opTreatment["_id"] = UniqueId.createEventId();
			opTreatment["created_at"] = formatter.format(new Date().valueOf()).replace("000+0000", "000Z");
			opTreatment["enteredBy"] = "Spike";
			opTreatment["eventType"] = "Note";
			opTreatment["duration"] = 60;
			opTreatment["notes"] = ModelLocator.resourceManagerInstance.getString("nightscoutservice","optimal_conditions_met");
			
			//Add treatment to queue
			activeTreatmentsUpload.push(opTreatment);
			
			//Sync uploads
			syncTreatmentsUpload();
		}
		
		private static function getInitialTreatments():void
		{
			Trace.myTrace("NightscoutService.as", "in getInitialTreatments");
			
			for (var i:int = 0; i < TreatmentsManager.treatmentsList.length; i++) 
			{
				//Add treatment to queue
				var treatment:Treatment = TreatmentsManager.treatmentsList[i] as Treatment;
				if 
				(
					treatment.note.indexOf("Exercise (NS)") != -1 ||
					treatment.note.indexOf("OpenAPS Offline") != -1 ||
					treatment.note.indexOf("Pump Site Change") != -1 ||
					treatment.note.indexOf("Pump Battery Change") != -1 ||
					treatment.note.indexOf("Resume Pump") != -1 ||
					treatment.note.indexOf("Suspend Pump") != -1 ||
					treatment.note.indexOf("Profile Switch") != -1 ||
					treatment.note.indexOf("Combo Bolus") != -1 ||
					treatment.note.indexOf("Announcement") != -1
				)
				{
					continue;
				}
				
				activeTreatmentsUpload.push(createTreatmentObject(treatment));
			}
			
			//Sync uploads
			syncTreatmentsUpload();
		}
		
		private static function syncTreatmentsUpload():void
		{
			if (activeTreatmentsUpload.length == 0 || syncTreatmentsUploadActive || !NetworkInfo.networkInfo.isReachable())
				return;
			
			if (!CGMBlueToothDevice.isFollower() && !serviceActive)
				return;
			
			if (CGMBlueToothDevice.isFollower() && !followerModeEnabled)
				return;
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON) == "true" && NetworkInfo.networkInfo.isWWAN() && !CGMBlueToothDevice.isFollower())
				return;
			
			Trace.myTrace("NightscoutService.as", "in syncTreatmentsUpload. Number of treatments to upload/update: " + activeTreatmentsUpload.length);
			
			syncTreatmentsUploadActive = true;
			
			//Upload Treatment
			NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.PUT, SpikeJSON.stringify(activeTreatmentsUpload[0]), MODE_TREATMENT_UPLOAD, onUploadTreatmentComplete, onConnectionFailed);
		}
		
		private static function onUploadTreatmentComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "in onUploadTreatmentComplete.");
			
			//Validation
			if (serviceHalted)
				return;
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onUploadTreatmentComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onConnectionFailed);
			loader = null;
			
			syncTreatmentsUploadActive = false;
			
			if (response.indexOf("Error") == -1 && response.indexOf("DOCTYPE") == -1 && response.indexOf("ok") != -1)
			{
				Trace.myTrace("NightscoutService.as", "Treatment uploaded/updated successfully!");
				
				//Remove treatment from queue
				activeTreatmentsUpload.shift() 
				
				if (activeTreatmentsUpload.length > 0)
				{
					Trace.myTrace("NightscoutService.as", "Uploading/updating next treatment in queue.");
					syncTreatmentsUpload();
				}
				else
				{
					getRemoteTreatments();
					
					if (pumpUserEnabled)
						getPropertiesV2Endpoint();
				}
			}
			else
				Trace.myTrace("NightscoutService.as", "Error uploading/updating treatment. Server response: " + response);
		}
		
		public static function deleteTreatment(treatment:Treatment):void
		{
			if (treatment.type == Treatment.TYPE_SENSOR_START)
				return;
			
			Trace.myTrace("NightscoutService.as", "in deleteTreatment.");
			
			//Check if the treatment is already present in another queue and delete it.
			if (!deleteInternalTreatment(activeTreatmentsUpload, treatment))
			{
				//Add treatment to queue
				activeTreatmentsDelete.push(treatment);
				
				//Delete treatment
				syncTreatmentsDelete();
			}
		}
		
		private static function syncTreatmentsDelete():void
		{
			if (activeTreatmentsDelete.length == 0 || syncTreatmentsDeleteActive || !NetworkInfo.networkInfo.isReachable())
				return;
			
			if (!CGMBlueToothDevice.isFollower() && !serviceActive)
				return;
			
			if (CGMBlueToothDevice.isFollower() && !followerModeEnabled)
				return;
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON) == "true" && NetworkInfo.networkInfo.isWWAN() && !CGMBlueToothDevice.isFollower())
				return;
			
			Trace.myTrace("NightscoutService.as", "in syncTreatmentsUpload. Number of treatments to delete: " + activeTreatmentsDelete.length);
			
			syncTreatmentsDeleteActive = true;
			
			//Delete Treatment
			NetworkConnector.createNSConnector(nightscoutTreatmentsURL + "/" + (activeTreatmentsDelete[0] as Treatment).ID, apiSecret, URLRequestMethod.DELETE, null, MODE_TREATMENT_DELETE, onDeleteTreatmentComplete, onConnectionFailed);
		}
		
		public static function deleteTreatmentByID(id:String):void
		{
			if (syncTreatmentsDeleteActive || !NetworkInfo.networkInfo.isReachable())
			{
				setTimeout(deleteTreatmentByID, TimeSpan.TIME_15_MINUTES, id);
				return;
			}
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON) == "true" && NetworkInfo.networkInfo.isWWAN() && !CGMBlueToothDevice.isFollower())
			{
				setTimeout(deleteTreatmentByID, TimeSpan.TIME_15_MINUTES, id);
				return;
			}
			
			if (!CGMBlueToothDevice.isFollower() && !serviceActive)
				return;
			
			if (CGMBlueToothDevice.isFollower() && !followerModeEnabled)
				return;
			
			//Delete Treatment
			NetworkConnector.createNSConnector(nightscoutTreatmentsURL + "/" + id, apiSecret, URLRequestMethod.DELETE, null, MODE_TREATMENT_DELETE, onDeleteTreatmentComplete, onConnectionFailed);
		}
		
		private static function onDeleteTreatmentComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "in onTreatmentDelete.");
			
			//Validation
			if (serviceHalted)
				return;
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onDeleteTreatmentComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onConnectionFailed);
			loader = null;
			
			//Update Internal Variables
			syncTreatmentsDeleteActive = false;
			
			if (response.indexOf("{}") != -1 && response.indexOf("Error") == -1 && response.indexOf("DOCTYPE") == -1)
			{
				Trace.myTrace("NightscoutService.as", "Treatment deleted successfully!");
				
				//Remove treatment from queue
				if (activeTreatmentsDelete.length > 0)
					activeTreatmentsDelete.shift() 
				
				if (activeTreatmentsDelete.length > 0)
				{
					Trace.myTrace("NightscoutService.as", "Deleting next treatment in queue.");
					syncTreatmentsDelete();
				}
			}
			else
				Trace.myTrace("NightscoutService.as", "Error deleting treatment. Server response: " + response);
		}
		
		public static function getUserInfo():void
		{
			Trace.myTrace("NightscoutService.as", "getUserInfo called!");
			
			if (!NetworkInfo.networkInfo.isReachable())
			{
				Trace.myTrace("NightscoutService.as", "There's no Internet connection.");
				
				return;
			}
			
			if (!serviceActive && !followerModeEnabled)
			{
				Trace.myTrace("NightscoutService.as", "Service not enabled.");
				
				return;
			}
			
			NetworkConnector.createNSConnector(nightscoutPropertiesV2URL, null, URLRequestMethod.GET, null, MODE_USER_INFO_GET, onGetUserInfoComplete, onConnectionFailed);
		}
		
		private static function onGetUserInfoComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "onGetUserInfoComplete called!");
			
			//Validation
			if (serviceHalted)
				return;
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			if (loader == null || loader.data == null)
				return;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onDownloadGlucoseReadingsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onConnectionFailed);
			loader = null;
			
			//Validate response
			if (response.indexOf("bgnow") != -1 && response.indexOf("DOCTYPE") == -1)
			{
				try
				{
					var userInfoProperties:Object = SpikeJSON.parse(response) as Object;
					
					if (userInfoProperties != null)
					{
						var currentBG:Number = userInfoProperties.bgnow != null && userInfoProperties.bgnow.mean != null ? Number(userInfoProperties.bgnow.mean) : Number.NaN;
						var basal:String = userInfoProperties.basal != null && userInfoProperties.basal.display != null && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BASAL_ON) == "true" ? String(userInfoProperties.basal.display) : "";
						var raw:Number = userInfoProperties.rawbg != null && userInfoProperties.rawbg.mgdl != null && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_RAW_GLUCOSE_ON) == "true" && !CGMBlueToothDevice.isBlueReader() && !CGMBlueToothDevice.isBluKon() && !CGMBlueToothDevice.isLimitter() && !CGMBlueToothDevice.isMiaoMiao() && !CGMBlueToothDevice.isTransmiter_PL() ? Number(userInfoProperties.rawbg.mgdl) : Number.NaN;
						!isNaN(raw) && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true" ? raw = Math.round((BgReading.mgdlToMmol(raw)) * 10) / 10 : raw = raw;
						var openAPSLastMoment:Number = userInfoProperties.openaps != null && userInfoProperties.openaps.lastLoopMoment != null && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_OPENAPS_MOMENT_ON) == "true" ? TimeSpan.fromDates(DateUtil.parseW3CDTF(userInfoProperties.openaps.lastLoopMoment), new Date()).minutes : Number.NaN;
						var pumpBattery:String =  userInfoProperties.pump != null && userInfoProperties.pump.data != null && userInfoProperties.pump.data.battery != null && userInfoProperties.pump.data.battery.display != null && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PUMP_BATTERY_ON) == "true" ? userInfoProperties.pump.data.battery.display : "";
						var pumpReservoir:Number =  userInfoProperties.pump != null && userInfoProperties.pump.data != null && userInfoProperties.pump.data.reservoir != null && userInfoProperties.pump.data.reservoir.value != null && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PUMP_RESERVOIR_ON) == "true" ? Number(userInfoProperties.pump.data.reservoir.value) : Number.NaN;
						var pumpStatus:String =  userInfoProperties.pump != null && userInfoProperties.pump.data != null && userInfoProperties.pump.data.status != null && userInfoProperties.pump.data.status.display != null && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PUMP_STATUS_ON) == "true" ? userInfoProperties.pump.data.status.display : "";
						var pumpTime:Number =  userInfoProperties.pump != null && userInfoProperties.pump.data != null && userInfoProperties.pump.data.clock != null && userInfoProperties.pump.data.clock.value != null && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PUMP_TIME_ON) == "true" ? TimeSpan.fromDates(DateUtil.parseW3CDTF(userInfoProperties.pump.data.clock.value), new Date()).minutes : Number.NaN;
						var cage:String =  userInfoProperties.cage != null && userInfoProperties.cage.display != null && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CAGE_ON) == "true" ? userInfoProperties.cage.display : "";
						var bage:String =  userInfoProperties.bage != null && userInfoProperties.bage.display != null && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BAGE_ON) == "true" ? userInfoProperties.bage.display : "";
						var sage:String =  userInfoProperties.sage != null && userInfoProperties.sage["Sensor Start"] != null && userInfoProperties.sage["Sensor Start"].display != null && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SAGE_ON) == "true" ? String(userInfoProperties.sage["Sensor Start"].display) : "";
						var iage:String =  userInfoProperties.iage != null && userInfoProperties.iage.display != null && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_IAGE_ON) == "true" ? String(userInfoProperties.iage.display) : "";
						var loopLastMoment:Number =  userInfoProperties.loop != null && userInfoProperties.loop.lastOkMoment != null && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOOP_MOMENT_ON) == "true" ? TimeSpan.fromDates(DateUtil.parseW3CDTF(userInfoProperties.loop.lastOkMoment), new Date()).minutes : Number.NaN;
						var isSpikeMaster:Boolean = false;
						var spikeMasterPhoneBattery:String = "";
						var spikeMasterTransmitterName:String = "";
						var spikeMasterTransmitterBattery:String = "";
						var spikeMasterTransmitterBatteryColor:uint = 0;
						
						if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_UPLOADER_BATTERY_ON) == "true" && userInfoProperties.upbat != null && userInfoProperties.upbat.devices != null)
						{
							for(var key:String in userInfoProperties.upbat.devices)
							{
								if (key.indexOf("Spike") != -1)
								{
									//It's a Spike master
									isSpikeMaster = true;
									
									if (userInfoProperties.upbat.devices[key].min != null)
									{
										if (userInfoProperties.upbat.devices[key].min.display != null)
											spikeMasterPhoneBattery = String(userInfoProperties.upbat.devices[key].min.display);
										
										if (userInfoProperties.upbat.devices[key].min.tBatteryValue != null)
											spikeMasterTransmitterName = String(userInfoProperties.upbat.devices[key].min.tName);
										
										if (userInfoProperties.upbat.devices[key].min.tBatteryValue != null)
											spikeMasterTransmitterBattery = String(userInfoProperties.upbat.devices[key].min.tBatteryValue);
										
										if (userInfoProperties.upbat.devices[key].min.tBatteryColor != null)
											spikeMasterTransmitterBatteryColor = uint(userInfoProperties.upbat.devices[key].min.tBatteryColor);
										
									}
									
									break;
								}
							}
						}
						
						var uploaderBattery:String = !isSpikeMaster && userInfoProperties.upbat != null && userInfoProperties.upbat.display != null && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_UPLOADER_BATTERY_ON) == "true" ? userInfoProperties.upbat.display : "";
						
						_instance.dispatchEvent
						(
							new UserInfoEvent
							(
								UserInfoEvent.USER_INFO_RETRIEVED,
								false,
								false,
								{
									basal: basal,
									raw: raw,
									uploaderBattery: uploaderBattery,
									openAPSLastMoment: openAPSLastMoment,
									loopLastMoment: loopLastMoment,
									pumpBattery: pumpBattery,
									pumpReservoir: pumpReservoir,
									pumpStatus: pumpStatus,
									pumpTime: pumpTime,
									cage: cage,
									bage: bage,
									sage: sage,
									iage: iage,
									spikeMasterPhoneBattery: spikeMasterPhoneBattery,
									spikeMasterTransmitterName: spikeMasterTransmitterName,
									spikeMasterTransmitterBattery: spikeMasterTransmitterBattery,
									spikeMasterTransmitterBatteryColor: spikeMasterTransmitterBatteryColor
								}
							)
						);
					} 
					else
					{
						Trace.myTrace("NightscoutService.as", "Could not parse User Info Nightscout response. Response: " + response);
						_instance.dispatchEvent(new UserInfoEvent(UserInfoEvent.USER_INFO_ERROR));
					}
				} 
				catch(error:Error) 
				{
					Trace.myTrace("NightscoutService.as", "Could not parse User Info Nightscout response. Error: " + error.message + " | Response: " + response);
					_instance.dispatchEvent(new UserInfoEvent(UserInfoEvent.USER_INFO_ERROR));
				}
			}
			else if (response.indexOf("Cannot GET /api/v2/properties") != -1 )
			{
				Trace.myTrace("NightscoutService.as", "Server doesn't have /api/v2/properties enabled. Notifying user!");
				_instance.dispatchEvent(new UserInfoEvent(UserInfoEvent.USER_INFO_API_NOT_FOUND));
			}
			else
			{
				Trace.myTrace("NightscoutService.as", "Server returned an unexpected response while retreiving user info. Response: " + response);
				_instance.dispatchEvent(new UserInfoEvent(UserInfoEvent.USER_INFO_ERROR));
			}
		}
		
		public static function getPropertiesV2Endpoint(forceRefresh:Boolean = false):void
		{
			if (!treatmentsEnabled || !nightscoutTreatmentsSyncEnabled)
				return;
			
			if (!pumpUserEnabled)
			{
				getRemoteTreatments();
				return;
			}
			
			Trace.myTrace("NightscoutService.as", "getPropertiesV2Endpoint called!");
			
			//Validation
			if (!isNSProfileSet)
			{
				if (nightscoutTreatmentsSyncEnabled && treatmentsEnabled)
				{
					Trace.myTrace("NightscoutService.as", "Profile has not yet been downloaded. Will try to download now!");
					getNightscoutProfile();
				}
				
				return;
			}
			
			if (!NetworkInfo.networkInfo.isReachable())
			{
				Trace.myTrace("NightscoutService.as", "There's no Internet connection.");
				
				return;
			}
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON) == "true" && NetworkInfo.networkInfo.isWWAN() && !CGMBlueToothDevice.isFollower())
				return;
			
			var now:Number = new Date().valueOf();
			
			if (now - lastRemotePropertiesV2Sync < TimeSpan.TIME_2_MINUTES_30_SECONDS && !forceRefresh)
				return;
			
			clearTimeout(propertiesV2Timeout);
			
			lastRemotePropertiesV2Sync = now;
			
			syncPropertiesV2Active = true;
			
			//API Secret
			var treatmentAPISecret:String = "";
			if (CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "")
				treatmentAPISecret = nightscoutFollowAPISecret;
			else if (!CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET) != "")
				treatmentAPISecret = apiSecret;
			
			NetworkConnector.createNSConnector(nightscoutPropertiesV2URL, treatmentAPISecret != "" ? treatmentAPISecret : null, URLRequestMethod.GET, null, MODE_PROPERTIES_V2_GET, onGetPropertiesV2Complete, onConnectionFailed);
		}
		
		private static function onGetPropertiesV2Complete(e:Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			if (!treatmentsEnabled || !nightscoutTreatmentsSyncEnabled)
				return;
			
			if (!pumpUserEnabled)
			{
				getRemoteTreatments();
				return;
			}
			
			Trace.myTrace("NightscoutService.as", "onGetPropertiesV2Complete called!");
			
			syncPropertiesV2Active = false;
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onDownloadGlucoseReadingsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onDownloadGlucoseReadingsComplete);
			loader = null;
			
			//Validate response
			if (response.indexOf("bgnow") != -1 && response.indexOf("DOCTYPE") == -1)
			{
				try
				{
					var propertiesV2Data:Object = SpikeJSON.parse(response) as Object;
					if (propertiesV2Data != null && (propertiesV2Data.iob != null || propertiesV2Data.cob != null || propertiesV2Data.openaps != null || propertiesV2Data.loop != null))
					{
						//IOB
						var previousPumpIOB:Number = TreatmentsManager.pumpIOB;
						if (propertiesV2Data.iob != null && propertiesV2Data.iob.iob != null)
						{
							//IOB found!
							var pumpIOB:Number = Number(propertiesV2Data.iob.iob);
							TreatmentsManager.setPumpIOB(pumpIOB);
						}
						
						//COB
						var previousPumpCOB:Number = TreatmentsManager.pumpCOB;
						if (propertiesV2Data.cob != null && propertiesV2Data.cob.cob != null)
						{
							//COB found
							var pumpCOB:Number = Number(propertiesV2Data.cob.cob);
							TreatmentsManager.setPumpCOB(pumpCOB);
						}
						
						//Notify listeners of updated IOB/COB
						if (previousPumpIOB != pumpIOB || previousPumpCOB != pumpCOB)
							TreatmentsManager.notifyIOBCOB();
						
						//Predictions
						if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_GLUCOSE_PREDICTIONS_ENABLED) == "true")
						{
							//OpenAPS
							var openAPSPredictions:Object;
							if (propertiesV2Data.openaps != null && propertiesV2Data.openaps.lastSuggested != null && propertiesV2Data.openaps.lastSuggested.predBGs != null)
							{
								openAPSPredictions = {};
								
								//Curves
								if (propertiesV2Data.openaps.lastSuggested.predBGs.IOB != null && propertiesV2Data.openaps.lastSuggested.predBGs.IOB is Array)
								{
									openAPSPredictions.IOB = propertiesV2Data.openaps.lastSuggested.predBGs.IOB;
									//(openAPSPredictions.IOB as Array).shift();
								}
								if (propertiesV2Data.openaps.lastSuggested.predBGs.COB != null && propertiesV2Data.openaps.lastSuggested.predBGs.COB is Array)
								{
									openAPSPredictions.COB = propertiesV2Data.openaps.lastSuggested.predBGs.COB;
									//(openAPSPredictions.COB as Array).shift();
								}
								if (propertiesV2Data.openaps.lastSuggested.predBGs.UAM != null && propertiesV2Data.openaps.lastSuggested.predBGs.UAM is Array)
								{
									openAPSPredictions.UAM = propertiesV2Data.openaps.lastSuggested.predBGs.UAM;
									//(openAPSPredictions.UAM as Array).shift();
								}
								if (propertiesV2Data.openaps.lastSuggested.predBGs.ZT != null && propertiesV2Data.openaps.lastSuggested.predBGs.ZT is Array)
								{
									openAPSPredictions.ZT = propertiesV2Data.openaps.lastSuggested.predBGs.ZT;
									//(openAPSPredictions.ZT as Array).shift();
								}
								
								//Properties
								if (propertiesV2Data.openaps.lastSuggested.reason != null && propertiesV2Data.openaps.lastSuggested.reason is String)
								{
									var openAPSReasonUnformatted:String = propertiesV2Data.openaps.lastSuggested.reason;
									openAPSReasonUnformatted = openAPSReasonUnformatted.replace(/;/g, ",").replace(/:/g, "");
									
									var openAPSReasonExploded:Array = openAPSReasonUnformatted.split(",");
									if (openAPSReasonExploded != null)
									{
										var numberOfReasons:uint = openAPSReasonExploded.length;
										if (numberOfReasons > 0)
										{
											var reasonProperties:Object = {};
											
											for (var i:int = 0; i < numberOfReasons; i++) 
											{
												var tempKeyString:String = StringUtil.trim(openAPSReasonExploded[i] as String);
												
												if (tempKeyString != null && tempKeyString != "" && tempKeyString.indexOf("Eventual") == -1)
												{
													var tempHolder:Array = tempKeyString.split(" ");
													if (tempHolder != null && tempHolder is Array && tempHolder.length == 2)
													{
														reasonProperties[tempHolder[0]] = Number(tempHolder[1]);
													}
												}
											}
											
											if (reasonProperties.ISF != null)
											{
												openAPSPredictions.isf = reasonProperties.ISF;
											}
											
											if (reasonProperties.CR != null)
											{
												openAPSPredictions.cr = reasonProperties.CR;
											}
											
											if (reasonProperties.BGI != null)
											{
												openAPSPredictions.bgImpact = reasonProperties.BGI;
											}
											
											if (reasonProperties.Dev != null)
											{
												openAPSPredictions.deviation = reasonProperties.Dev;
											}
											
											if (reasonProperties.minPredBG != null)
											{
												openAPSPredictions.minPredBG = reasonProperties.minPredBG;
												
												if (openAPSPredictions.minPredBG < 20 && !isNightscoutMgDl)
												{
													openAPSPredictions.minPredBG = Math.round(BgReading.mmolToMgdl(openAPSPredictions.minPredBG));
												}
											}
											
											if (reasonProperties.minGuardBG != null)
											{
												openAPSPredictions.minGuardBG = reasonProperties.minGuardBG;
												
												if (openAPSPredictions.minGuardBG < 20 && !isNightscoutMgDl)
												{
													openAPSPredictions.minGuardBG = Math.round(BgReading.mmolToMgdl(openAPSPredictions.minGuardBG));
												}
											}
											
											if (reasonProperties.COBpredBG != null)
											{
												openAPSPredictions.COBpredBG = reasonProperties.COBpredBG;
												
												if (openAPSPredictions.COBpredBG < 20 && !isNightscoutMgDl)
												{
													openAPSPredictions.COBpredBG = Math.round(BgReading.mmolToMgdl(openAPSPredictions.COBpredBG));
												}
											}
											
											if (reasonProperties.IOBpredBG != null)
											{
												openAPSPredictions.IOBpredBG = reasonProperties.IOBpredBG;
												
												if (openAPSPredictions.IOBpredBG < 20 && !isNightscoutMgDl)
												{
													openAPSPredictions.IOBpredBG = Math.round(BgReading.mmolToMgdl(openAPSPredictions.IOBpredBG));
												}
											}
											
											if (reasonProperties.UAMpredBG != null)
											{
												openAPSPredictions.UAMpredBG = reasonProperties.UAMpredBG;
												
												if (openAPSPredictions.UAMpredBG < 20 && !isNightscoutMgDl)
												{
													openAPSPredictions.UAMpredBG = Math.round(BgReading.mmolToMgdl(openAPSPredictions.UAMpredBG));
												}
											}
										}
									}
								}
								
								if (propertiesV2Data.openaps.lastSuggested.eventualBG != null)
								{
									openAPSPredictions.eventualBG = Number(propertiesV2Data.openaps.lastSuggested.eventualBG);
									
									if (openAPSPredictions.eventualBG < 20 && !isNightscoutMgDl)
									{
										openAPSPredictions.eventualBG = Math.round(BgReading.mmolToMgdl(openAPSPredictions.eventualBG));
									}
								}
								
								if (propertiesV2Data.openaps.lastSuggested.bg != null)
								{
									openAPSPredictions.bg = Number(propertiesV2Data.openaps.lastSuggested.bg);
									
									if (openAPSPredictions.bg < 20 && !isNightscoutMgDl)
									{
										openAPSPredictions.bg = Math.round(BgReading.mmolToMgdl(openAPSPredictions.bg));
									}
								}
								
								openAPSPredictions.lastUpdate = new Date().valueOf();
								
								Forecast.externalLoopAPS = false;
								Forecast.setAPSPredictions(openAPSPredictions);
							}
							
							//Loop
							if (openAPSPredictions == null && propertiesV2Data.loop != null && propertiesV2Data.loop.lastPredicted != null && propertiesV2Data.loop.lastPredicted.values != null && propertiesV2Data.loop.lastPredicted.values is Array)
							{
								var loopPredictions:Object = {};
								
								//Curve
								loopPredictions.IOB = propertiesV2Data.loop.lastPredicted.values;
								(loopPredictions.IOB as Array).shift();
								//(loopPredictions.IOB as Array).shift();
								
								loopPredictions.lastUpdate = new Date().valueOf();
								
								Forecast.externalLoopAPS = true;
								Forecast.setAPSPredictions(loopPredictions);
							}
						}
						
						retriesForPropertiesV2Download = 0;
					}
					else
					{
						if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && pumpUserEnabled && retriesForPropertiesV2Download < MAX_RETRIES_FOR_TREATMENTS)
						{
							Trace.myTrace("NightscoutService.as", "Server returned an unexpected response. Retrying new properties v2 fetch in 30 seconds. Responder: " + response);
							setTimeout(getPropertiesV2Endpoint, TimeSpan.TIME_30_SECONDS);
							retriesForPropertiesV2Download++;
						}
					}
				} 
				catch(error:Error) 
				{
					if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && pumpUserEnabled && retriesForPropertiesV2Download < MAX_RETRIES_FOR_TREATMENTS)
					{
						Trace.myTrace("NightscoutService.as", "SError parsing Nightscout response. Retrying new properties v2 fetch in 30 seconds. Responder: " + response);
						setTimeout(getPropertiesV2Endpoint, TimeSpan.TIME_30_SECONDS);
						retriesForPropertiesV2Download++;
					}
				}
			}
			else
			{
				if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && pumpUserEnabled && retriesForPropertiesV2Download < MAX_RETRIES_FOR_TREATMENTS)
				{
					Trace.myTrace("NightscoutService.as", "Server returned an unexpected response. Retrying new properties v2 fetch in 30 seconds. Responder: " + response);
					setTimeout(getPropertiesV2Endpoint, TimeSpan.TIME_30_SECONDS);
					retriesForPropertiesV2Download++;
				}
			}
		}
		
		private static function onGetPebbleComplete(e:Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			if (!treatmentsEnabled || !nightscoutTreatmentsSyncEnabled)
				return;
			
			if (!pumpUserEnabled)
			{
				getRemoteTreatments();
				return;
			}
			
			Trace.myTrace("NightscoutService.as", "onGetPebbleComplete called!");
			
			syncPropertiesV2Active = false;
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onDownloadGlucoseReadingsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onDownloadGlucoseReadingsComplete);
			loader = null;
			
			//Validate response
			if (response.indexOf("bgs") != -1 && response.indexOf("DOCTYPE") == -1)
			{
				try
				{
					var pebbleProperties:Object = SpikeJSON.parse(response) as Object;
					if (pebbleProperties != null && pebbleProperties.bgs != null)
					{
						var previousPumpIOB:Number = TreatmentsManager.pumpIOB;
						var pumpIOB:Number = Number(pebbleProperties.bgs[0].iob);
						TreatmentsManager.setPumpIOB(pumpIOB);
						
						var previousPumpCOB:Number = TreatmentsManager.pumpCOB;
						var pumpCOB:Number = Number(pebbleProperties.bgs[0].cob);
						TreatmentsManager.setPumpCOB(pumpCOB);
						
						if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled)
							getRemoteTreatments();
						
						//Notify listeners of updated IOB/COB
						if (previousPumpIOB != pumpIOB || previousPumpCOB != pumpCOB)
							TreatmentsManager.notifyIOBCOB();
						
						retriesForPropertiesV2Download = 0;
					}
					else
					{
						if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && pumpUserEnabled && retriesForPropertiesV2Download < MAX_RETRIES_FOR_TREATMENTS)
						{
							Trace.myTrace("NightscoutService.as", "Server returned an unexpected response. Retrying new pebble fetch in 30 seconds. Responder: " + response);
							setTimeout(getPropertiesV2Endpoint, TimeSpan.TIME_30_SECONDS);
							retriesForPropertiesV2Download++;
						}
					}
				} 
				catch(error:Error) 
				{
					if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && pumpUserEnabled && retriesForPropertiesV2Download < MAX_RETRIES_FOR_TREATMENTS)
					{
						Trace.myTrace("NightscoutService.as", "Error parsing Nightscout response. Retrying new pebble fetch in 30 seconds. Error: " + error.message + " | Response: " + response);
						setTimeout(getPropertiesV2Endpoint, TimeSpan.TIME_30_SECONDS);
						retriesForPropertiesV2Download++;
					}
				}
			}
			else
			{
				if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && pumpUserEnabled && retriesForPropertiesV2Download < MAX_RETRIES_FOR_TREATMENTS)
				{
					Trace.myTrace("NightscoutService.as", "Server returned an unexpected response. Retrying new pebble's fetch in 30 seconds. Responder: " + response);
					setTimeout(getPropertiesV2Endpoint, TimeSpan.TIME_30_SECONDS);
					retriesForPropertiesV2Download++;
				}
			}
		}
		
		private static function getRemoteTreatments():void
		{
			if (!treatmentsEnabled || !nightscoutTreatmentsSyncEnabled || activeTreatmentsDelete == null || activeTreatmentsUpload == null || activeSensorStarts == null || activeVisualCalibrations == null || serviceHalted)
				return;
			
			Trace.myTrace("NightscoutService.as", "getRemoteTreatments called!");
			
			//Validation
			if (!isNSProfileSet)
			{
				if (nightscoutTreatmentsSyncEnabled && treatmentsEnabled)
				{
					Trace.myTrace("NightscoutService.as", "Profile has not yet been downloaded. Will try to download now!");
					getNightscoutProfile();
				}
				
				return;
			}
			
			if (!NetworkInfo.networkInfo.isReachable())
			{
				Trace.myTrace("NightscoutService.as", "There's no Internet connection.");
				
				return;
			}
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON) == "true" && NetworkInfo.networkInfo.isWWAN() && !CGMBlueToothDevice.isFollower())
				return;
			
			if ((activeTreatmentsDelete.length > 0 || activeTreatmentsUpload.length > 0 || activeSensorStarts.length > 0 || activeVisualCalibrations.length > 0) && retriesForTreatmentsDownload < MAX_RETRIES_FOR_TREATMENTS)
			{	
				Trace.myTrace("NightscoutService.as", "Spike is still syncing treatments added by user. Will retry in 30 seconds");
					
				if (activeTreatmentsDelete.length > 0 && !syncTreatmentsDeleteActive)
					syncTreatmentsDelete();
				else if (activeTreatmentsUpload.length > 0 && !syncTreatmentsUploadActive)
					syncTreatmentsUpload();
				else if (activeSensorStarts.length > 0 && !syncSensorStartActive)
					syncSensorStart();
				else if (activeVisualCalibrations.length > 0 && !syncVisualCalibrationsActive)
					syncVisualCalibrations();
				
				setTimeout(getRemoteTreatments, TimeSpan.TIME_30_SECONDS);
				
				retriesForTreatmentsDownload++;
				
				return;
			}
			
			var now:Number = new Date().valueOf();
			
			if (now - lastRemoteTreatmentsSync < TimeSpan.TIME_30_SECONDS)
				return;
			
			lastRemoteTreatmentsSync = now;
			
			syncTreatmentsDownloadActive = true;
			
			//Define request parameters
			var parameters:URLVariables = new URLVariables();
			parameters["find[created_at][$gte]"] = formatter.format(new Date().valueOf() - TimeSpan.TIME_24_HOURS);
			parameters["find[eventType][$nin][0]"] = "Temp Basal";
			//parameters["find[eventType][$nin][1]"] = "Combo Bolus";
			
			/*parameters["find[eventType][$in][0]"] = "Correction Bolus";
			parameters["find[eventType][$in][1]"] = "Bolus";
			parameters["find[eventType][$in][2]"] = "Correction";
			parameters["find[eventType][$in][3]"] = "Meal Bolus";
			parameters["find[eventType][$in][4]"] = "Snack Bolus";
			parameters["find[eventType][$in][5]"] = "Carb Correction";
			parameters["find[eventType][$in][6]"] = "Carbs";
			parameters["find[eventType][$in][7]"] = "Note";
			parameters["find[eventType][$in][8]"] = "OpenAPS Offline";
			parameters["find[eventType][$in][9]"] = "Site Change";
			parameters["find[eventType][$in][10]"] = "Pump Battery Change";
			parameters["find[eventType][$in][11]"] = "Announcement";
			parameters["find[eventType][$in][12]"] = "Profile Switch";
			parameters["find[eventType][$in][13]"] = "Sensor Start";
			parameters["find[eventType][$in][14]"] = "BG Check";
			parameters["find[eventType][$in][15]"] = "Bolus Wizard";
			parameters["find[eventType][$in][16]"] = "<none>";
			parameters["find[eventType][$in][17]"] = "Suspend Pump";
			parameters["find[eventType][$in][18]"] = "Resume Pump";*/
			
			//API Secret
			var treatmentAPISecret:String = "";
			if (CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "")
			{
				if (nightscoutFollowAPISecret == null) return;
				treatmentAPISecret = nightscoutFollowAPISecret;
			}
			else if (!CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET) != "")
			{
				if (apiSecret == null) return;
				treatmentAPISecret = apiSecret;
			}
			
			NetworkConnector.createNSConnector(nightscoutTreatmentsURL + ".json?" + parameters, treatmentAPISecret != "" ? treatmentAPISecret : null, URLRequestMethod.GET, null, MODE_TREATMENTS_GET, onGetTreatmentsComplete, onConnectionFailed);
		}
		
		private static function onGetTreatmentsComplete(e:Event):void
		{
			//Validation
			if (serviceHalted)
				return;
			
			if (!treatmentsEnabled || !nightscoutTreatmentsSyncEnabled)
				return;
			
			Trace.myTrace("NightscoutService.as", "onGetTreatmentsComplete called!");
			
			syncTreatmentsDownloadActive = false;
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onDownloadGlucoseReadingsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onConnectionFailed);
			loader = null;
			
			//Validate if we can process treatments
			if ((activeTreatmentsDelete.length > 0 || activeTreatmentsUpload.length > 0 || activeSensorStarts.length > 0 || activeVisualCalibrations.length > 0) && retriesForTreatmentsDownload < MAX_RETRIES_FOR_TREATMENTS)
			{
				Trace.myTrace("NightscoutService.as", "Spike is still syncing treatments added by user. Will retry in 30 seconds to avoid overlaps!");
				
				if (activeTreatmentsDelete.length > 0 && !syncTreatmentsDeleteActive)
					syncTreatmentsDelete();
				else if (activeTreatmentsUpload.length > 0 && !syncTreatmentsUploadActive)
					syncTreatmentsUpload();
				else if (activeSensorStarts.length > 0 && !syncSensorStartActive)
					syncSensorStart();
				else if (activeVisualCalibrations.length > 0 && !syncVisualCalibrationsActive)
					syncVisualCalibrations();
				
				setTimeout(getRemoteTreatments, TimeSpan.TIME_30_SECONDS);
				
				retriesForTreatmentsDownload++;
				
				return;
			}
			
			//Validate response
			if (response.indexOf("created_at") != -1 && response.indexOf("Error") == -1 && response.indexOf("DOCTYPE") == -1)
			{
				if (NetworkConnector.nightscoutTreatmentsLastModifiedHeader != "" && TreatmentsManager.nightscoutTreatmentsLastModifiedHeader != "" && NetworkConnector.nightscoutTreatmentsLastModifiedHeader == TreatmentsManager.nightscoutTreatmentsLastModifiedHeader)
				{
					Trace.myTrace("NightscoutService.as", "No treatments where modified in Nightscout. No further processing.");
				}
				else
				{
					try
					{
						var nightscoutTreatments:Array = SpikeJSON.parse(response) as Array;
						if (nightscoutTreatments!= null && nightscoutTreatments is Array)
						{
							//Send nightscout treatments to TreatmentsManager for further processing
							TreatmentsManager.processNightscoutTreatments(nightscoutTreatments);
							TreatmentsManager.nightscoutTreatmentsLastModifiedHeader = NetworkConnector.nightscoutTreatmentsLastModifiedHeader;
							retriesForTreatmentsDownload = 0;
						}
						else
						{
							if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && retriesForTreatmentsDownload < MAX_RETRIES_FOR_TREATMENTS)
							{
								Trace.myTrace("NightscoutService.as", "Server returned an unexpected response. Retrying new treatment's fetch in 30 seconds. Responder: " + response);
								setTimeout(getRemoteTreatments, TimeSpan.TIME_30_SECONDS);
								retriesForTreatmentsDownload++;
							}
						}
					} 
					catch(error:Error) 
					{
						if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && retriesForTreatmentsDownload < MAX_RETRIES_FOR_TREATMENTS)
						{
							Trace.myTrace("NightscoutService.as", "Error parsing Nightscout response. Retrying new treatment's fetch in 30 seconds. Error: " + error.message + " | Response: " + response);
							setTimeout(getRemoteTreatments, TimeSpan.TIME_30_SECONDS);
							retriesForTreatmentsDownload++;
						}
					}
				}
			}
			else
			{
				if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && retriesForTreatmentsDownload < MAX_RETRIES_FOR_TREATMENTS)
				{
					Trace.myTrace("NightscoutService.as", "Server returned an unexpected response. Retrying new treatment's fetch in 30 seconds. Responder: " + response);
					setTimeout(getRemoteTreatments, TimeSpan.TIME_30_SECONDS);
					retriesForTreatmentsDownload++;
				}
			}
		}
		
		/**
		 * CALIBRATIONS
		 */
		private static function createCalibrationObject(calibration:Calibration):Object
		{	
			var newCalibration:Object = new Object();
			newCalibration["device"] = CGMBlueToothDevice.name;
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
			newVisualCalibration["_id"] = calibration.uniqueId;	
			newVisualCalibration["eventType"] = "BG Check";	
			newVisualCalibration["created_at"] = formatter.format(calibration.timestamp).replace("000+0000", "000Z");
			newVisualCalibration["enteredBy"] = "Spike";	
			newVisualCalibration["glucose"] = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? calibration.bg : Math.round(BgReading.mgdlToMmol(calibration.bg) * 10) / 10;
			newVisualCalibration["glucoseType"] = "Finger";
			newVisualCalibration["notes"] = ModelLocator.resourceManagerInstance.getString("treatments","sensor_calibration_note");
			
			return newVisualCalibration;
		}
		
		private static function syncCalibrations():void
		{
			if (activeCalibrations.length == 0 || syncGlucoseReadingsActive || !NetworkInfo.networkInfo.isReachable())
				return;
			
			if (!CGMBlueToothDevice.isFollower() && !serviceActive)
				return;
			
			if (CGMBlueToothDevice.isFollower() && !followerModeEnabled)
				return;
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON) == "true" && NetworkInfo.networkInfo.isWWAN() && !CGMBlueToothDevice.isFollower())
				return;
			
			syncCalibrationsActive = true;
			
			//Upload Glucose Readings
			//NetworkConnector.createNSConnector(nightscoutEventsURL, apiSecret, URLRequestMethod.POST, JSON.stringify(activeCalibrations), MODE_CALIBRATION, onUploadCalibrationsComplete, onConnectionFailed);
			NetworkConnector.createNSConnector(nightscoutEventsURL, apiSecret, URLRequestMethod.POST, SpikeJSON.stringify(activeCalibrations), MODE_CALIBRATION, onUploadCalibrationsComplete, onConnectionFailed);
		}
		
		private static function getInitialCalibrations():void
		{
			Trace.myTrace("NightscoutService.as", "in getInitialCalibrations.");
			
			var calibrationList:Array = Calibration.allForSensor();
			var lastCalibrationSyncTimeStamp:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_CALIBRATION_TIMESTAMP));
			
			for(var i:int = calibrationList.length - 1 ; i >= 0; i--)
			{
				var calibration:Calibration = calibrationList[i] as Calibration;
				if (calibration.timestamp > lastCalibrationSyncTimeStamp && calibration.slope != 0 && i > 0) 
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
			//Validation
			if (serviceHalted)
				return;
			
			if (Calibration.allForSensor().length == 1) //Ensures compatibility with the new method of only one initial calibration (ignores the first one)
				return;
			
			var lastCalibration:Calibration = Calibration.last();
			
			if (!(lastCalibration.timestamp > new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_CALIBRATION_TIMESTAMP)))) {
				return;
			}
			
			activeCalibrations.push(createCalibrationObject(lastCalibration));
			var visualCalibration:Object = createVisualCalibrationObject(lastCalibration);
			activeVisualCalibrations.push(visualCalibration);
			
			//Add calibration treatment to Spike
			TreatmentsManager.addInternalCalibrationTreatment(lastCalibration.bg, lastCalibration.timestamp, lastCalibration.uniqueId);
			
			syncCalibrations();
			syncVisualCalibrations();
		}

		private static function onUploadCalibrationsComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "in onUploadCalibrationsComplete.");
			
			//Validation
			if (serviceHalted)
				return;
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			if (loader == null || loader.data == null)
				return;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onUploadCalibrationsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onConnectionFailed);
			loader = null;
			
			//Update Internal Variables
			syncCalibrationsActive = false;
			
			if (response.indexOf(CGMBlueToothDevice.name) != -1)
			{
				Trace.myTrace("NightscoutService.as", "Calibration upload was successful.");
				
				var calibrationUploadTimestamp:Number;
				if (Calibration.last() != null && !isNaN(Calibration.last().timestamp))
					calibrationUploadTimestamp = Calibration.last().timestamp;
				else
					calibrationUploadTimestamp = new Date().valueOf();
				
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_CALIBRATION_TIMESTAMP, String(calibrationUploadTimestamp));
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
			
			if (!CGMBlueToothDevice.isFollower() && !serviceActive)
				return;
			
			if (CGMBlueToothDevice.isFollower() && !followerModeEnabled)
				return;
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON) == "true" && NetworkInfo.networkInfo.isWWAN() && !CGMBlueToothDevice.isFollower())
				return;
			
			syncVisualCalibrationsActive = true;
			
			//Upload Glucose Readings
			//NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.POST, JSON.stringify(activeVisualCalibrations), MODE_VISUAL_CALIBRATION, onUploadVisualCalibrationsComplete, onConnectionFailed);
			NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.PUT, SpikeJSON.stringify(activeVisualCalibrations[0]), MODE_VISUAL_CALIBRATION, onUploadVisualCalibrationsComplete, onConnectionFailed);
		}
		
		private static function onUploadVisualCalibrationsComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "onUploadVisualCalibrationsComplete");
			
			//Validation
			if (serviceHalted)
				return;
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onUploadVisualCalibrationsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onConnectionFailed);
			loader = null;
			
			syncVisualCalibrationsActive = false;
			
			if (response.indexOf("ok") != -1 && response.indexOf("Error") == -1)
			{
				Trace.myTrace("NightscoutService.as", "Visual calibration upload was successful!");
				
				if (activeVisualCalibrations.length > 0)
				{
					activeVisualCalibrations.shift();
					if (activeVisualCalibrations.length > 0)
						syncVisualCalibrations();
				}
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
			if (activeSensorStarts.length == 0 || syncSensorStartActive || !NetworkInfo.networkInfo.isReachable() || !serviceActive)
				return;
			
			if (!CGMBlueToothDevice.isFollower() && !serviceActive)
				return;
			
			if (CGMBlueToothDevice.isFollower() && !followerModeEnabled)
				return;
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_WIFI_ONLY_UPLOADER_ON) == "true" && NetworkInfo.networkInfo.isWWAN() && !CGMBlueToothDevice.isFollower())
				return;
			
			syncSensorStartActive = true;
			
			//Upload Sensor Start treatment
			//NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.POST, JSON.stringify(activeSensorStarts), MODE_SENSOR_START, onUploadSensorStartComplete, onConnectionFailed);
			NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.POST, SpikeJSON.stringify(activeSensorStarts), MODE_SENSOR_START, onUploadSensorStartComplete, onConnectionFailed);
		}
		
		private static function getSensorStart():void
		{
			Trace.myTrace("NightscoutService.as", "in getSensorStart.");
			
			var currentSensor:Sensor = Sensor.getActiveSensor();
			
			if (currentSensor == null || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR) == "0")
				return;
			
			var newSensor:Object = new Object();
			var eventID:String = UniqueId.createEventId();
			newSensor["_id"] = eventID;	
			newSensor["eventType"] = "Sensor Start";	
			newSensor["created_at"] = formatter.format(currentSensor.startedAt).replace("000+0000", "000Z");
			newSensor["enteredBy"] = "Spike";
			
			//Add sensor start to Chart
			TreatmentsManager.addInternalSensorStartTreatment(currentSensor.startedAt, eventID);
			
			activeSensorStarts.push(newSensor);
			
			syncSensorStart();
		}
		
		private static function onUploadSensorStartComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "onUploadSensorStartComplete");
			
			//Validation
			if (serviceHalted)
				return;
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onUploadVisualCalibrationsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onConnectionFailed);
			loader = null;
			
			syncSensorStartActive = false;
			
			if (response.indexOf("Sensor Start") != -1 && response.indexOf("Error") == -1)
			{
				Trace.myTrace("NightscoutService.as", "Sensor start uploaded successfuly");
				activeSensorStarts.length = 0;
			}
			else
			{
				Trace.myTrace("NightscoutService.as", "Error uploading sensor start! Response: " + response);
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
				credentialsTester["notes"] = "Spike Authentication Test";
				
				//NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.PUT, JSON.stringify(credentialsTester), MODE_TEST_CREDENTIALS, onTestCredentialsComplete, onConnectionFailed);
				NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.PUT, SpikeJSON.stringify(credentialsTester), MODE_TEST_CREDENTIALS, onTestCredentialsComplete, onConnectionFailed);
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
			
			//Validation
			if (serviceHalted)
				return;
			
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
					//var responseInfo:Object = JSON.parse(response);
					var responseInfo:Object = SpikeJSON.parse(response);
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
		
		public static function testNightscoutCredentialsFollower():void
		{
			Trace.myTrace("NightscoutService.as", "testNightscoutCredentialsFollower called.");
			
			setupNightscoutProperties();
			setupFollowerProperties();
			
			if (nightscoutTreatmentsURL == "" || apiSecret == "")
				return;
			
			if (NetworkInfo.networkInfo.isReachable()) 
			{
				credentialsTesterID = UniqueId.createEventId();
				var credentialsTester:Object = new Object();
				credentialsTester["_id"] = credentialsTesterID;
				credentialsTester["eventType"] = "Note";
				credentialsTester["duration"] = 30;
				credentialsTester["notes"] = "Spike Authentication Test";
				
				//NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.PUT, JSON.stringify(credentialsTester), MODE_TEST_CREDENTIALS, onTestCredentialsComplete, onConnectionFailed);
				NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.PUT, SpikeJSON.stringify(credentialsTester), MODE_TEST_CREDENTIALS, onTestCredentialsFollowerComplete, onConnectionFailed);
			}
			else
			{
				Trace.myTrace("NightscoutService.as", "Can't check NS credentials. No Internet connection!");
				
				AlertManager.showSimpleAlert(
					ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_title"),
					ModelLocator.resourceManagerInstance.getString("nightscoutservice","call_to_nightscout_to_verify_url_and_secret_can_not_be_made"),
					60
				);
			}
		}
		
		private static function onTestCredentialsFollowerComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "onTestCredentialsFollowerComplete called");
			
			//Validation
			if (serviceHalted)
				return;
			
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
				}
				else
				{
					var responseInfo:Object = SpikeJSON.parse(response);
					if (responseInfo.ok != null && responseInfo.ok == 1)
					{
						Trace.myTrace("NightscoutService.as", "NS Authentication follower successful!");
						
						//Alert user
						AlertManager.showSimpleAlert(
							ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_title"),
							ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_test_result_ok"),
							Number.NaN,
							null,
							HorizontalAlign.CENTER
						);
						
						//Delete credential test treatment
						NetworkConnector.createNSConnector(nightscoutTreatmentsURL + "/" + credentialsTesterID, apiSecret, URLRequestMethod.DELETE);
					}
					else if (responseInfo.status != null)
					{
						Trace.myTrace("NightscoutService.as", "Authentication failed! Wrong api secret?");
						Trace.myTrace("NightscoutService.as", "Error:", responseInfo.status + " " + responseInfo.message);
						
						//Alert User
						var errorMessage:String = ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_test_authentication_failed");
						errorMessage += " " + responseInfo.status + " " + responseInfo.message;
							
						AlertManager.showSimpleAlert(
							ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_title"),
							errorMessage,
							Number.NaN
						);
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
				AlertManager.showSimpleAlert(
					ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_title"),
					ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_test_url_not_found"),
					Number.NaN,
					null,
					HorizontalAlign.CENTER
				);
			}
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
			if (!CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) != "true" && treatmentsEnabled)
				getInitialTreatments();
			getInitialCalibrations();
			if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled)
				getNightscoutProfile();
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
			activeTreatmentsUpload.length = 0;
			activeTreatmentsDelete.length = 0;
		}
		
		private static function activateTimer():void
		{
			if (serviceTimer == null || !serviceTimer.running)
			{
				serviceTimer = new Timer(2.5 * 60 * 1000);
				serviceTimer.addEventListener(TimerEvent.TIMER, onServiceTimer, false, 0, true);
				serviceTimer.start();
			}
		}
		
		private static function deactivateTimer():void
		{
			if (serviceTimer != null && !serviceActive && !followerModeEnabled)
			{
				serviceTimer.stop();;
				serviceTimer.removeEventListener(TimerEvent.TIMER, onServiceTimer);
				serviceTimer = null;
			}
		}
		
		private static function setupNightscoutProperties():void
		{
			apiSecret = !CGMBlueToothDevice.isFollower() ? Hex.fromArray(hash.hash(Hex.toArray(Hex.fromString(Cryptography.decryptStringLight(Keys.STRENGTH_256_BIT, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET)))))) : Hex.fromArray(hash.hash(Hex.toArray(Hex.fromString(Cryptography.decryptStringLight(Keys.STRENGTH_256_BIT, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET))))));
			
			nightscoutEventsURL = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/api/v1/entries";
			if (nightscoutEventsURL.indexOf('http') == -1) nightscoutEventsURL = "https://" + nightscoutEventsURL;
			
			nightscoutTreatmentsURL = !CGMBlueToothDevice.isFollower() ? CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/api/v1/treatments" : CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) + "/api/v1/treatments";
			if (nightscoutTreatmentsURL.indexOf('http') == -1) nightscoutTreatmentsURL = "https://" + nightscoutTreatmentsURL;
			
			nightscoutProfileURL = !CGMBlueToothDevice.isFollower() ? CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/api/v1/profile.json" : CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) + "/api/v1/profile.json";
			if (nightscoutProfileURL.indexOf('http') == -1) nightscoutProfileURL = "https://" + nightscoutProfileURL;
			
			nightscoutPebbleURL = !CGMBlueToothDevice.isFollower() ? CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/pebble" : CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) + "/pebble";
			if (nightscoutPebbleURL.indexOf('http') == -1) nightscoutPebbleURL = "https://" + nightscoutPebbleURL;
			
			nightscoutPropertiesV2URL = !CGMBlueToothDevice.isFollower() ? CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/api/v2/properties" : CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) + "/api/v2/properties";
			if (nightscoutPropertiesV2URL.indexOf('http') == -1) nightscoutPropertiesV2URL = "https://" + nightscoutPropertiesV2URL;
			
			nightscoutDeviceStatusURL = !CGMBlueToothDevice.isFollower() ? CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/api/v1/devicestatus.json" : CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) + "/api/v1/devicestatus.json";
			if (nightscoutDeviceStatusURL.indexOf('http') == -1) nightscoutDeviceStatusURL = "https://" + nightscoutDeviceStatusURL;
			
			treatmentsEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED) == "true";
			nightscoutTreatmentsSyncEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_NIGHTSCOUT_DOWNLOAD_ENABLED) == "true";
			pumpUserEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true";
		}
		
		private static function activateEventListeners():void
		{
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_RECEIVED, onBgreadingReceived);
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onLastBgreadingReceived);
			//NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgreadingReceived);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, onCalibrationReceived);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, getInitialGlucoseReadings);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.NEW_CALIBRATION_EVENT, onCalibrationReceived);
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppActivated);
			NetworkInfo.networkInfo.addEventListener(NetworkInfoEvent.CHANGE, onNetworkChange);
		}
		private static function deactivateEventListeners():void
		{
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.BGREADING_RECEIVED, onBgreadingReceived);
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onLastBgreadingReceived);
			//NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgreadingReceived);
			CalibrationService.instance.removeEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, onCalibrationReceived);
			CalibrationService.instance.removeEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, getInitialGlucoseReadings);
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
			
			if (CGMBlueToothDevice.isFollower()) getRemoteReadings();
			
			if (activeTreatmentsUpload.length > 0) syncTreatmentsUpload();
			
			if (activeTreatmentsDelete.length > 0) syncTreatmentsDelete();
		}
		
		/**
		 * General Event Listeners
		 */
		private static function onConnectionFailed(error:Error, mode:String):void
		{
			//Validation
			if (serviceHalted)
				return;
			
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
				Trace.myTrace("NightscoutService.as", "in onConnectionFailed. Can't make connection to the server to test credentials. Error: " +  error.message);
				externalAuthenticationCall = false;
			}
			else if (mode == MODE_GLUCOSE_READING_GET)
			{
				Trace.myTrace("NightscoutService.as", "in onConnectionFailed. Can't make connection to the server while trying to download glucose readings. Error: " +  error.message);
				
				setNextFollowerFetch(TimeSpan.TIME_10_SECONDS); //Plus 10 seconds to ensure it passes the getRemoteReadings validation
			}
			else if (mode == MODE_TREATMENT_UPLOAD)
			{
				Trace.myTrace("NightscoutService.as", "in onConnectionFailed. Error uploading/updating treatment. Error: " + error.message);
				syncTreatmentsUploadActive = false;
			}
			else if (mode == MODE_TREATMENT_DELETE)
			{
				Trace.myTrace("NightscoutService.as", "in onConnectionFailed. Error deleting treatment. Error: " + error.message);
				syncTreatmentsDeleteActive = false;
			}
			else if (mode == MODE_TREATMENTS_GET)
			{
				if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && retriesForTreatmentsDownload < MAX_RETRIES_FOR_TREATMENTS)
				{
					Trace.myTrace("NightscoutService.as", "in onConnectionFailed. Error getting treatments. Retrying in 30 seconds. Error: " + error.message);
					setTimeout(getRemoteTreatments, TimeSpan.TIME_30_SECONDS);
					retriesForTreatmentsDownload++;
				}
			}
			else if (mode == MODE_PROFILE_GET)
			{
				if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled)
				{
					Trace.myTrace("NightscoutService.as", "in onConnectionFailed. Error getting profile. Retrying in 30 seconds. Error: " + error.message);
					setTimeout(getNightscoutProfile, TimeSpan.TIME_30_SECONDS);
				}
			}
			else if (mode == MODE_PROPERTIES_V2_GET)
			{
				if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && pumpUserEnabled && retriesForPropertiesV2Download < MAX_RETRIES_FOR_TREATMENTS)
				{
					Trace.myTrace("NightscoutService.as", "in onConnectionFailed. Error getting properties v2 endpoint. Retrying in 30 seconds. Error: " + error.message);
					setTimeout(getPropertiesV2Endpoint, TimeSpan.TIME_30_SECONDS);
					retriesForPropertiesV2Download++;
				}
			}
			else if (mode == MODE_USER_INFO_GET)
			{
				Trace.myTrace("NightscoutService.as", "in onConnectionFailed. Error getting user info. Error: " + error.message);
			}
			else if (mode == MODE_BATTERY_UPLOAD)
			{
				Trace.myTrace("NightscoutService.as", "in onConnectionFailed. Error uploading battery levels. Error: " + error.message);
			}
			else if (mode == MODE_PREDICTIONS_UPLOAD)
			{
				Trace.myTrace("NightscoutService.as", "in onConnectionFailed. Error uploading predictions. Error: " + error.message);
			}
		}
		
		private static function onSettingChanged(e:SettingsServiceEvent):void
		{
			//Validation
			if (serviceHalted)
				return;
			
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
			else if (e.data == CommonSettings.COMMON_SETTING_CURRENT_SENSOR && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_ON) == "true" && Sensor.getActiveSensor() != null && uploadSensorStart)
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR) != "0")
				{
					Trace.myTrace("NightscoutService.as", "in onSettingChanged, uploading new sensor.");
					getSensorStart();
				}
			}
			else if 
				(e.data == CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE ||
				 e.data == CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE ||
				 e.data == CommonSettings.COMMON_SETTING_FOLLOWER_MODE ||
				 e.data == CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL
				)
			{
				if (CGMBlueToothDevice.isFollower() && 
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE).toUpperCase() == "FOLLOWER" &&
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE).toUpperCase() == "NIGHTSCOUT" &&
					CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != ""
				)
				{
					deactivateFollower();
					setupNightscoutProperties();
					setupFollowerProperties();
					activateFollower();
				}
				else
					if(followerModeEnabled)
						deactivateFollower();
			}
			else if (e.data == CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_OFFSET || e.data == CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET)
			{
				if (followerModeEnabled)
				{
					deactivateFollower();
					setupNightscoutProperties();
					setupFollowerProperties();
					activateFollower();
				}
			}
			else if (e.data == CommonSettings.COMMON_SETTING_TREATMENTS_NIGHTSCOUT_DOWNLOAD_ENABLED || e.data == CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED || e.data == CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED)
			{
				setupNightscoutProperties();
			}
			else if (e.data == CommonSettings.COMMON_SETTING_NIGHTSCOUT_PREDICTIONS_UPLOADER_ON)
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_PREDICTIONS_UPLOADER_ON) == "True")
				{
					uploadPredictions();
				}
			}
		}
		
		private static function onServiceTimer(e:TimerEvent):void
		{
			resync();
		}
		
		private static function onNetworkChange( event:NetworkInfoEvent ):void
		{
			if(NetworkInfo.networkInfo.isReachable() && networkChangeOcurrances > 0 && !MultipleMiaoMiaoService.isMiaoMiaoMultiple())
				//if multiple miaomiao enalbed, then let multiplemiaomiaoservice check first if there's been a NS update by another device
				//if yes multiplemiaomiaoservice will change the value of COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP to a value corresponding to the latest reading at NS
				//this will avoid uploading duplicate readings
			{
				Trace.myTrace("NightscoutService.as", "Network is reachable again. Calling resync.");
				
				resync();
				
				//Update remote treatments so the user has updated data when returning to Spike
				if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled)
				{
					getRemoteTreatments();
					
					if (pumpUserEnabled)
						getPropertiesV2Endpoint();
				}
			}
			else
				networkChangeOcurrances++;
		}
		
		private static function onAppActivated(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "App in foreground. Calling resync.");
			
			resync();
			
			//Update remote treatments so the user has updated data when returning to Spike
			if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled)
			{
				getRemoteTreatments();
				
				if (pumpUserEnabled)
					getPropertiesV2Endpoint();
			}
		}
		
		/**
		 * Stops the service entirely. Useful for database restores
		 */
		private static function onHaltExecution(e:SpikeEvent):void
		{
			Trace.myTrace("NightscoutService.as", "Stopping service...");
			
			serviceHalted = true;
			
			CommonSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingChanged);
			
			deactivateService();
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

		public static function get syncTreatmentsUploadActive():Boolean
		{
			if (!_syncTreatmentsUploadActive)
				return false;
			
			var now:Number = (new Date()).valueOf();
			
			if (now - syncTreatmentsUploadActiveLastChange > MAX_SYNC_TIME)
			{
				syncTreatmentsUploadActiveLastChange = now;
				_syncTreatmentsUploadActive = false;
				return false;
			}
			
			return true;
		}

		public static function set syncTreatmentsUploadActive(value:Boolean):void
		{
			syncTreatmentsUploadActiveLastChange = new Date().valueOf();
			_syncTreatmentsUploadActive = value;
		}

		public static function get syncTreatmentsDeleteActive():Boolean
		{
			if (!_syncTreatmentsDeleteActive)
				return false;
			
			var now:Number = (new Date()).valueOf();
			
			if (now - syncTreatmentsDeleteActiveLastChange > MAX_SYNC_TIME)
			{
				syncTreatmentsDeleteActiveLastChange = now;
				_syncTreatmentsDeleteActive = false;
				return false;
			}
			
			return true;
		}

		public static function set syncTreatmentsDeleteActive(value:Boolean):void
		{
			syncTreatmentsDeleteActiveLastChange = new Date().valueOf();
			_syncTreatmentsDeleteActive = value;
		}

		public static function get syncTreatmentsDownloadActive():Boolean
		{
			if (!_syncTreatmentsDownloadActive)
				return false;
			
			var now:Number = (new Date()).valueOf();
			
			if (now - syncTreatmentsDownloadActiveLastChange > MAX_SYNC_TIME)
			{
				syncTreatmentsDownloadActiveLastChange = now;
				_syncTreatmentsDownloadActive = false;
				return false;
			}
			
			return true;
		}

		public static function set syncTreatmentsDownloadActive(value:Boolean):void
		{
			syncTreatmentsDownloadActiveLastChange = new Date().valueOf();
			_syncTreatmentsDownloadActive = value;
		}
		
		public static function get syncPropertiesV2Active():Boolean
		{
			if (!_syncPebbleActive)
				return false;
			
			var now:Number = (new Date()).valueOf();
			
			if (now - syncPebbleActiveLastChange > MAX_SYNC_TIME)
			{
				syncPebbleActiveLastChange = now;
				_syncPebbleActive = false;
				return false;
			}
			
			return true;
		}
		
		public static function set syncPropertiesV2Active(value:Boolean):void
		{
			syncPebbleActiveLastChange = new Date().valueOf();
			_syncPebbleActive = value;
		}
		
		public static function get instance():NightscoutService
		{
			return _instance;
		}
	}
}