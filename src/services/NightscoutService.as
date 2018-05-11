package services
{
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
	
	import spark.formatters.DateTimeFormatter;
	
	import database.BgReading;
	import database.BlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.FollowerBgReading;
	import database.Sensor;
	
	import events.CalibrationServiceEvent;
	import events.FollowerEvent;
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	
	import feathers.layout.HorizontalAlign;
	
	import model.ModelLocator;
	
	import network.NetworkConnector;
	
	import treatments.ProfileManager;
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import ui.popups.AlertManager;
	
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
		private static const MODE_PEBBLE_GET:String = "pebbleGet";
		private static const MAX_SYNC_TIME:Number = 45 * 1000; //45 seconds
		private static const MAX_RETRIES_FOR_TREATMENTS:int = 1;
		private static const TIME_1_DAY:int = 24 * 60 * 60 * 1000;
		private static const TIME_1_HOUR:int = 60 * 60 * 1000;
		private static const TIME_6_MINUTES:int = 6 * 60 * 1000;
		private static const TIME_5_MINUTES_30_SECONDS:int = (5 * 60 * 1000) + 30000;
		private static const TIME_5_MINUTES_10_SECONDS:int = (5 * 60 * 1000) + 10000;
		private static const TIME_5_MINUTES:int = 5 * 60 * 1000;
		private static const TIME_4_MINUTES_30_SECONDS:int = (4 * 60 * 1000) + 30000;
		private static const TIME_1_MINUTE:int = 60 * 1000;
		private static const TIME_30_SECONDS:int = 30000;
		private static const TIME_10_SECONDS:int = 10000;
		private static const TIME_5_SECONDS:int = 6000;
		
		/* Logical Variables */
		private static var serviceStarted:Boolean = false;
		public static var serviceActive:Boolean = false;
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
		public static var uploadSensorStart:Boolean = true;
		
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
		
		/* Follower */
		private static var nextFollowDownloadTime:Number = 0;
		private static var timeOfFirstBgReadingToDowload:Number;
		private static var lastFollowDownloadAttempt:Number;
		private static var waitingForNSData:Boolean = false;
		private static var nightscoutFollowURL:String = "";
		private static var nightscoutFollowOffset:Number = 0;
		private static var followerModeEnabled:Boolean = false;
		private static var followerTimer:int = -1;
		private static var nightscoutFollowAPISecret:String = "";
		private static var nightscoutProfileURL:String = "";
		private static var isNSProfileSet:Boolean = false;
		
		private static var _instance:NightscoutService = new NightscoutService();

		/* Treatments */
		private static var nightscoutTreatmentsSyncEnabled:Boolean = true;
		private static var treatmentsEnabled:Boolean = true;
		private static var profileAlertShown:Boolean = false;
		private static var activeTreatmentsUpload:Array = [];
		private static var activeTreatmentsDelete:Array = [];
		private static var retriesForTreatmentsDownload:int = 0;
		private static var retriesForPebbleDownload:int = 0;
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
		private static var lastRemotePebbleSync:Number = 0;

		private static var pumpUserEnabled:Boolean;

		private static var nightscoutPebbleURL:String;

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
			
			setupNightscoutProperties();
			
			if (BlueToothDevice.isFollower() && 
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
			
			if (Calibration.allForSensor().length < 2 && !BlueToothDevice.isFollower()) 
				return;
			
			syncGlucoseReadingsActive = true;
			
			//Upload Glucose Readings
			//NetworkConnector.createNSConnector(nightscoutEventsURL, apiSecret, URLRequestMethod.POST, JSON.stringify(activeGlucoseReadings), MODE_GLUCOSE_READING, onUploadGlucoseReadingsComplete, onConnectionFailed);
			NetworkConnector.createNSConnector(nightscoutEventsURL, apiSecret, URLRequestMethod.POST, SpikeJSON.stringify(activeGlucoseReadings), MODE_GLUCOSE_READING, onUploadGlucoseReadingsComplete, onConnectionFailed);
		}
		
		private static function onBgreadingReceived(e:Event):void 
		{
			var latestGlucoseReading:BgReading;
			if(!BlueToothDevice.isFollower())
				latestGlucoseReading= BgReading.lastNoSensor();
			else
				latestGlucoseReading= BgReading.lastWithCalculatedValue();
			
			if(latestGlucoseReading == null || (latestGlucoseReading.calculatedValue == 0 && latestGlucoseReading.calibration == null))
				return;
			
			
			activeGlucoseReadings.push(createGlucoseReading(latestGlucoseReading));
			
			//Only start uploading bg reading if it's newer than 1 minute. Blucon sends historical data so we don't want to start upload for every reading. Just start upload on the last reading. The previous readings will still be uploaded because they reside in the queue array.
			if (new Date().valueOf() - latestGlucoseReading.timestamp < TIME_1_MINUTE)
			{
				if (!BlueToothDevice.canDoBackfill()) //No backfill transmitter, sync immediately
					syncGlucoseReadings();
				else //Backfill transmitter. Wait 5 seconds to process all data
					setTimeout(syncGlucoseReadings, TIME_5_SECONDS);
			}
		}
		
		private static function onUploadGlucoseReadingsComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "in onUploadGlucoseReadingsComplete.");
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			if (loader == null || loader.data == null)
				return;
			
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
					if (activeGlucoseReadings != null && activeGlucoseReadings.length > 0 && activeGlucoseReadings[initialGlucoseReadingsIndex -1] != null && activeGlucoseReadings[initialGlucoseReadingsIndex -1].date != null) 
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP, String(activeGlucoseReadings[activeGlucoseReadings.length -1].date));
					else
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP, String(new Date().valueOf()));
							
					activeGlucoseReadings.length = 0; 
				}
				else
				{
					//It's an initial readings call
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP, String(activeGlucoseReadings[initialGlucoseReadingsIndex -1].date));
					activeGlucoseReadings = activeGlucoseReadings.slice(0, initialGlucoseReadingsIndex);
					initialGlucoseReadingsIndex = 0;
				}
				
				//Get remote treatments/IOB-COB
				if (ModelLocator.bgReadings != null && ModelLocator.bgReadings.length > 0 && treatmentsEnabled && nightscoutTreatmentsSyncEnabled)
				{
					if (!pumpUserEnabled)
						getRemoteTreatments();
					else
						getPebbleEndpoint();
				}
			}
			else
			{
				Trace.myTrace("NightscoutService.as", "Error uploading glucose reading. Maybe server is down or no Internet connection? Server response: " + response);
			}
			
			syncGlucoseReadingsActive = false;
		}
		
		/**
		 * PROFILE
		 */
		private static function getNightscoutProfile():void
		{
			Trace.myTrace("NightscoutService.as", "getNightscoutProfile called!");
			
			if (!BlueToothDevice.isFollower() && !serviceActive)
				return;
			
			if (BlueToothDevice.isFollower() && !followerModeEnabled)
				return;
			
			var now:Number = new Date().valueOf();
			
			if (now - lastRemoteProfileSync < TIME_30_SECONDS)
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
						setTimeout(getNightscoutProfile, TIME_30_SECONDS);
					}
					
					return;
				}
				
				//Define API secret
				var profileAPISecret:String = "";
				if (BlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "")
					profileAPISecret = nightscoutFollowAPISecret;
				else if (!BlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET) != "")
					profileAPISecret = apiSecret;
				
				//Fetch profile
				NetworkConnector.createNSConnector(nightscoutProfileURL, profileAPISecret != "" ? profileAPISecret : null, URLRequestMethod.GET, null, MODE_PROFILE_GET, onGetProfileComplete, onConnectionFailed);
			}
		}
		
		private static function onGetProfileComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "onGetProfileComplete called!");
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onDownloadGlucoseReadingsComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onDownloadGlucoseReadingsComplete);
			loader = null;
			
			//Validate response
			if (response.indexOf("defaultProfile") != -1 || response.indexOf("created_at") != -1)
			{
				try
				{
					var profileProperties:Object = SpikeJSON.parse(response);
					if (profileProperties != null)
					{
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
						
						Trace.myTrace("NightscoutService.as", "Profile retrieved and parsed successfully! DIA: " + dia + " CAR: " + carbAbsorptionRate);
						
						isNSProfileSet = true; //Mark profile as downloaded
							
						//Add nightscout insulin to Spike and don't save it to DB
						ProfileManager.addInsulin(ModelLocator.resourceManagerInstance.getString("treatments","nightscout_insulin"), dia, "", BlueToothDevice.isFollower() ? true : false, "000000", !BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING ? true : false);
							
						//Add nightscout carbs absorption rate and don't save it to DB
						ProfileManager.addNightscoutCarbAbsorptionRate(carbAbsorptionRate);
							
						//Get treatmenents
						if (!pumpUserEnabled)
							getRemoteTreatments();
						else
							getPebbleEndpoint();
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
			
			nightscoutFollowAPISecret = Hex.fromArray(hash.hash(Hex.toArray(Hex.fromString(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET)))));
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
				if (now - latestBGReading.timestamp >= TIME_5_MINUTES_30_SECONDS)
				{
					//Some users are uploading values to nightscout with a bigger delay than it was supposed (>10 seconds)... 
					//This will make Spike retry in 30sec so they don't see outdated values in the chart.
					nextFollowDownloadTime = now + TIME_30_SECONDS; 
				}
				else
				{
					nextFollowDownloadTime = latestBGReading.timestamp + TIME_5_MINUTES_10_SECONDS;
					while (nextFollowDownloadTime < now) 
					{
						nextFollowDownloadTime += TIME_5_MINUTES;
					}
				}
			}
			else
				nextFollowDownloadTime = now + TIME_5_MINUTES;		
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
			
			if (!BlueToothDevice.isFollower())
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
				
				setNextFollowerFetch(TIME_10_SECONDS); //Plus 10 seconds to ensure it passes the getRemoteReadings validation
				
				return;
			}
			
			var latestBGReading:BgReading = BgReading.lastWithCalculatedValue();
			
			if (latestBGReading != null && !isNaN(latestBGReading.timestamp) && now - latestBGReading.timestamp < TIME_5_MINUTES)
				return;
			
			if (nextFollowDownloadTime < now) 
			{
				if (latestBGReading == null) 
					timeOfFirstBgReadingToDowload = now - TIME_1_DAY;
				else
					timeOfFirstBgReadingToDowload = latestBGReading.timestamp + 1; //We add 1ms to avoid overlaps
				
				var numberOfReadings:Number = ((now - timeOfFirstBgReadingToDowload) / TIME_1_HOUR * 12) + 1; //Add one more just to make sure we get all readings
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
				setNextFollowerFetch(TIME_10_SECONDS); 
			}
		}
		
		private static function onDownloadGlucoseReadingsComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "onDownloadGlucoseReadingsComplete called!");
			
			var now:Number = (new Date()).valueOf();
			
			//Validate call
			if (!waitingForNSData || (now - lastFollowDownloadAttempt > TIME_4_MINUTES_30_SECONDS)) 
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
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onDownloadGlucoseReadingsComplete);
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
					var newData:Boolean = false;
					for(var arrayCounter:int = NSBgReadings.length - 1 ; arrayCounter >= 0; arrayCounter--)
					{
						var NSFollowReading:Object = NSBgReadings[arrayCounter];
						if (NSFollowReading.date) 
						{
							var NSFollowReadingDate:Date = new Date(NSFollowReading.date);
							NSFollowReadingDate.setMinutes(NSFollowReadingDate.minutes + nightscoutFollowOffset);
							var NSFollowReadingTime:Number = NSFollowReadingDate.valueOf();
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
									"", //noise
									NSFollowReadingTime, //lastmodifiedtimestamp
									NSFollowReading._id //unique id
								);  
								
								ModelLocator.addBGReading(bgReading);
								bgReading.findSlope(true);
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
							if (!pumpUserEnabled)
								getRemoteTreatments();
							else
								getPebbleEndpoint();
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
			if (treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS)
			{
				newTreatment["eventType"] = "Correction Bolus";	
				newTreatment["insulin"] = treatment.insulinAmount;	
			}
			else if (treatment.type == Treatment.TYPE_CARBS_CORRECTION)
			{
				newTreatment["eventType"] = "Carb Correction";	
				newTreatment["carbs"] = treatment.carbs;	
			}
			else if (treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
			{
				newTreatment["eventType"] = "BG Check";	
				newTreatment["glucose"] = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? treatment.glucose : Math.round(BgReading.mgdlToMmol(treatment.glucose) * 10) / 10;
				newTreatment["glucoseType"] = "Finger";	
			}
			else if (treatment.type == Treatment.TYPE_MEAL_BOLUS)
			{
				newTreatment["eventType"] = "Meal Bolus";
				newTreatment["insulin"] = treatment.insulinAmount;
				newTreatment["carbs"] = treatment.carbs;
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
				var nsTreatment:Object = arrayToDelete[i] as Object;
				if (nsTreatment != null && nsTreatment["_id"] != null && nsTreatment["_id"] == treatment.ID)
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
			if (!serviceActive)
				return;
			
			Trace.myTrace("NightscoutService.as", "in uploadTreatment.");
			
			//Check if the treatment is already present in another queue and delete it.
			if (!deleteInternalTreatment(activeTreatmentsDelete, treatment))
			{
				//Add treatment to queue
				activeTreatmentsUpload.push(createTreatmentObject(treatment));
				
				//Sync uploads
				syncTreatmentsUpload();
			}
		}
		
		private static function getInitialTreatments():void
		{
			Trace.myTrace("NightscoutService.as", "in getInitialTreatments");
			
			for (var i:int = 0; i < TreatmentsManager.treatmentsList.length; i++) 
			{
				//Add treatment to queue
				var treatment:Treatment = TreatmentsManager.treatmentsList[i] as Treatment;
				activeTreatmentsUpload.push(createTreatmentObject(treatment));
			}
			
			//Sync uploads
			syncTreatmentsUpload();
		}
		
		private static function syncTreatmentsUpload():void
		{
			if (activeTreatmentsUpload.length == 0 || syncTreatmentsUploadActive || !NetworkInfo.networkInfo.isReachable())
				return;
			
			if (!BlueToothDevice.isFollower() && !serviceActive)
				return;
			
			if (BlueToothDevice.isFollower() && !followerModeEnabled)
				return;
			
			Trace.myTrace("NightscoutService.as", "in syncTreatmentsUpload. Number of treatments to upload/update: " + activeTreatmentsUpload.length);
			
			syncTreatmentsUploadActive = true;
			
			//Upload Treatment
			NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.PUT, SpikeJSON.stringify(activeTreatmentsUpload[0]), MODE_TREATMENT_UPLOAD, onUploadTreatmentComplete, onConnectionFailed);
		}
		
		private static function onUploadTreatmentComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "in onUploadTreatmentComplete.");
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onUploadTreatmentComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onUploadTreatmentComplete);
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
					if (!pumpUserEnabled)
						getRemoteTreatments();
					else
						getPebbleEndpoint();
				}
			}
			else
				Trace.myTrace("NightscoutService.as", "Error uploading/updating treatment. Server response: " + response);
		}
		
		public static function deleteTreatment(treatment:Treatment):void
		{
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
			
			if (!BlueToothDevice.isFollower() && !serviceActive)
				return;
			
			if (BlueToothDevice.isFollower() && !followerModeEnabled)
				return;
			
			Trace.myTrace("NightscoutService.as", "in syncTreatmentsUpload. Number of treatments to delete: " + activeTreatmentsDelete.length);
			
			syncTreatmentsDeleteActive = true;
			
			//Delete Treatment
			NetworkConnector.createNSConnector(nightscoutTreatmentsURL + "/" + (activeTreatmentsDelete[0] as Treatment).ID, apiSecret, URLRequestMethod.DELETE, null, MODE_TREATMENT_DELETE, onDeleteTreatmentComplete, onConnectionFailed);
		}
		
		private static function onDeleteTreatmentComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "in onTreatmentDelete.");
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			//Get response
			var response:String = loader.data;
			
			//Dispose loader
			loader.removeEventListener(Event.COMPLETE, onDeleteTreatmentComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onDeleteTreatmentComplete);
			loader = null;
			
			//Update Internal Variables
			syncTreatmentsDeleteActive = false;
			
			if (response.indexOf("{}") != -1 && response.indexOf("Error") == -1 && response.indexOf("DOCTYPE") == -1)
			{
				Trace.myTrace("NightscoutService.as", "Treatment deleted successfully!");
				
				//Remove treatment from queue
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
		
		private static function getPebbleEndpoint():void
		{
			if (!treatmentsEnabled || !nightscoutTreatmentsSyncEnabled)
				return;
			
			if (!pumpUserEnabled)
			{
				getRemoteTreatments();
				return;
			}
			
			Trace.myTrace("NightscoutService.as", "getPebbleEndpoint called!");
			
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
			
			var now:Number = new Date().valueOf();
			
			if (now - lastRemotePebbleSync < TIME_30_SECONDS)
				return;
			
			lastRemotePebbleSync = now;
			
			syncPebbleActive = true;
			
			//API Secret
			var treatmentAPISecret:String = "";
			if (BlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "")
				treatmentAPISecret = nightscoutFollowAPISecret;
			else if (!BlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET) != "")
				treatmentAPISecret = apiSecret;
			
			NetworkConnector.createNSConnector(nightscoutPebbleURL, treatmentAPISecret != "" ? treatmentAPISecret : null, URLRequestMethod.GET, null, MODE_PEBBLE_GET, onGetPebbleComplete, onConnectionFailed);
		}
		
		private static function onGetPebbleComplete(e:Event):void
		{
			if (!treatmentsEnabled || !nightscoutTreatmentsSyncEnabled)
				return;
			
			if (!pumpUserEnabled)
			{
				getRemoteTreatments();
				return;
			}
			
			Trace.myTrace("NightscoutService.as", "onGetPebbleComplete called!");
			
			syncPebbleActive = false;
			
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
						
						retriesForPebbleDownload = 0;
					}
					else
					{
						if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && pumpUserEnabled && retriesForPebbleDownload < MAX_RETRIES_FOR_TREATMENTS)
						{
							Trace.myTrace("NightscoutService.as", "Server returned an unexpected response. Retrying new pebble fetch in 30 seconds. Responder: " + response);
							setTimeout(getPebbleEndpoint, TIME_30_SECONDS);
							retriesForPebbleDownload++;
						}
					}
				} 
				catch(error:Error) 
				{
					if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && pumpUserEnabled && retriesForPebbleDownload < MAX_RETRIES_FOR_TREATMENTS)
					{
						Trace.myTrace("NightscoutService.as", "Error parsing Nightscout response. Retrying new pebble fetch in 30 seconds. Error: " + error.message + " | Response: " + response);
						setTimeout(getPebbleEndpoint, TIME_30_SECONDS);
						retriesForPebbleDownload++;
					}
				}
			}
			else
			{
				if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && pumpUserEnabled && retriesForPebbleDownload < MAX_RETRIES_FOR_TREATMENTS)
				{
					Trace.myTrace("NightscoutService.as", "Server returned an unexpected response. Retrying new pebble's fetch in 30 seconds. Responder: " + response);
					setTimeout(getPebbleEndpoint, TIME_30_SECONDS);
					retriesForPebbleDownload++;
				}
			}
		}
		
		private static function getRemoteTreatments():void
		{
			if (!treatmentsEnabled || !nightscoutTreatmentsSyncEnabled)
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
				
				setTimeout(getRemoteTreatments, TIME_30_SECONDS);
				
				retriesForTreatmentsDownload++;
				
				return;
			}
			
			var now:Number = new Date().valueOf();
			
			if (now - lastRemoteTreatmentsSync < TIME_30_SECONDS)
				return;
			
			lastRemoteTreatmentsSync = now;
			
			syncTreatmentsDownloadActive = true;
			
			//Define request parameters
			var parameters:URLVariables = new URLVariables();
			parameters["find[created_at][$gte]"] = formatter.format(new Date().valueOf() - TIME_1_DAY);
			
			//API Secret
			var treatmentAPISecret:String = "";
			if (BlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "")
				treatmentAPISecret = nightscoutFollowAPISecret;
			else if (!BlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET) != "")
				treatmentAPISecret = apiSecret;
			
			NetworkConnector.createNSConnector(nightscoutTreatmentsURL + ".json?" + parameters, treatmentAPISecret != "" ? treatmentAPISecret : null, URLRequestMethod.GET, null, MODE_TREATMENTS_GET, onGetTreatmentsComplete, onConnectionFailed);
		}
		
		private static function onGetTreatmentsComplete(e:Event):void
		{
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
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onDownloadGlucoseReadingsComplete);
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
				
				setTimeout(getRemoteTreatments, TIME_30_SECONDS);
				
				retriesForTreatmentsDownload++;
				
				return;
			}
			
			//Validate response
			if (response.indexOf("created_at") != -1 && response.indexOf("Error") == -1 && response.indexOf("DOCTYPE") == -1)
			{
				try
				{
					var nightscoutTreatments:Array = SpikeJSON.parse(response) as Array;
					if (nightscoutTreatments!= null && nightscoutTreatments is Array)
					{
						//Send nightscout treatments to TreatmentsManager for further processing
						TreatmentsManager.processNightscoutTreatments(nightscoutTreatments);
						
						retriesForTreatmentsDownload = 0;
					}
					else
					{
						if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && retriesForTreatmentsDownload < MAX_RETRIES_FOR_TREATMENTS)
						{
							Trace.myTrace("NightscoutService.as", "Server returned an unexpected response. Retrying new treatment's fetch in 30 seconds. Responder: " + response);
							setTimeout(getRemoteTreatments, TIME_30_SECONDS);
							retriesForTreatmentsDownload++;
						}
					}
				} 
				catch(error:Error) 
				{
					if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && retriesForTreatmentsDownload < MAX_RETRIES_FOR_TREATMENTS)
					{
						Trace.myTrace("NightscoutService.as", "Error parsing Nightscout response. Retrying new treatment's fetch in 30 seconds. Error: " + error.message + " | Response: " + response);
						setTimeout(getRemoteTreatments, TIME_30_SECONDS);
						retriesForTreatmentsDownload++;
					}
				}
			}
			else
			{
				if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && retriesForTreatmentsDownload < MAX_RETRIES_FOR_TREATMENTS)
				{
					Trace.myTrace("NightscoutService.as", "Server returned an unexpected response. Retrying new treatment's fetch in 30 seconds. Responder: " + response);
					setTimeout(getRemoteTreatments, TIME_30_SECONDS);
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
			newVisualCalibration["_id"] = UniqueId.createEventId();	
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
			
			if (!BlueToothDevice.isFollower() && !serviceActive)
				return;
			
			if (BlueToothDevice.isFollower() && !followerModeEnabled)
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
			if (Calibration.allForSensor().length == 1) //Ensures compatibility with the new method of only one initial calibration (ignores the first one)
				return;
			
			var lastCalibration:Calibration = Calibration.last();
			
			activeCalibrations.push(createCalibrationObject(lastCalibration));
			var visualCalibration:Object = createVisualCalibrationObject(lastCalibration);
			activeVisualCalibrations.push(visualCalibration);
			
			//Add calibration treatment to Spike
			TreatmentsManager.addInternalCalibrationTreatment(lastCalibration.bg, lastCalibration.timestamp, visualCalibration._id);
			
			syncCalibrations();
			syncVisualCalibrations();
		}

		private static function onUploadCalibrationsComplete(e:Event):void
		{
			Trace.myTrace("NightscoutService.as", "in onUploadCalibrationsComplete.");
			
			//Get loader
			var loader:URLLoader = e.currentTarget as URLLoader;
			
			if (loader == null || loader.data == null)
				return;
			
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
			
			if (!BlueToothDevice.isFollower() && !serviceActive)
				return;
			
			if (BlueToothDevice.isFollower() && !followerModeEnabled)
				return;
			
			syncVisualCalibrationsActive = true;
			
			//Upload Glucose Readings
			//NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.POST, JSON.stringify(activeVisualCalibrations), MODE_VISUAL_CALIBRATION, onUploadVisualCalibrationsComplete, onConnectionFailed);
			NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.POST, SpikeJSON.stringify(activeVisualCalibrations), MODE_VISUAL_CALIBRATION, onUploadVisualCalibrationsComplete, onConnectionFailed);
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
			if (activeSensorStarts.length == 0 || syncSensorStartActive || !NetworkInfo.networkInfo.isReachable() || !serviceActive)
				return;
			
			if (!BlueToothDevice.isFollower() && !serviceActive)
				return;
			
			if (BlueToothDevice.isFollower() && !followerModeEnabled)
				return;
			
			syncSensorStartActive = true;
			
			//Upload Sensor Start treatment
			//NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.POST, JSON.stringify(activeSensorStarts), MODE_SENSOR_START, onUploadSensorStartComplete, onConnectionFailed);
			NetworkConnector.createNSConnector(nightscoutTreatmentsURL, apiSecret, URLRequestMethod.POST, SpikeJSON.stringify(activeSensorStarts), MODE_SENSOR_START, onUploadSensorStartComplete, onConnectionFailed);
		}
		
		private static function getSensorStart():void
		{
			Trace.myTrace("NightscoutService.as", "in getSensorStart.");
			
			var newSensor:Object = new Object();
			var eventID:String = UniqueId.createEventId();
			newSensor["_id"] = eventID;	
			newSensor["eventType"] = "Sensor Start";	
			newSensor["created_at"] = formatter.format(Sensor.getActiveSensor().startedAt).replace("000+0000", "000Z");
			newSensor["enteredBy"] = "Spike";
			
			//Add sensor start to Chart
			TreatmentsManager.addInternalSensorStartTreatment(Sensor.getActiveSensor().startedAt, eventID);
			
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
		
		/**
		 * Functionality
		 */
		private static function activateService():void
		{
			Trace.myTrace("NightscoutService.as", "Service activated!");
			serviceActive = true;
			setupNightscoutProperties();
			getInitialGlucoseReadings();
			if (!BlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) != "true" && treatmentsEnabled)
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
				serviceTimer = new Timer(60 * 1000);
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
			apiSecret = Hex.fromArray(hash.hash(Hex.toArray(Hex.fromString(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET)))));
			
			nightscoutEventsURL = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/api/v1/entries";
			if (nightscoutEventsURL.indexOf('http') == -1) nightscoutEventsURL = "https://" + nightscoutEventsURL;
			
			nightscoutTreatmentsURL = !BlueToothDevice.isFollower() ? CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/api/v1/treatments" : CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) + "/api/v1/treatments";
			if (nightscoutTreatmentsURL.indexOf('http') == -1) nightscoutTreatmentsURL = "https://" + nightscoutTreatmentsURL;
			
			nightscoutProfileURL = !BlueToothDevice.isFollower() ? CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/api/v1/profile.json" : CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) + "/api/v1/profile.json";
			if (nightscoutProfileURL.indexOf('http') == -1) nightscoutProfileURL = "https://" + nightscoutProfileURL;
			
			nightscoutPebbleURL = !BlueToothDevice.isFollower() ? CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/pebble" : CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) + "/pebble";
			if (nightscoutPebbleURL.indexOf('http') == -1) nightscoutPebbleURL = "https://" + nightscoutPebbleURL;
			
			treatmentsEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED) == "true";
			nightscoutTreatmentsSyncEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_NIGHTSCOUT_DOWNLOAD_ENABLED) == "true";
			pumpUserEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true";
		}
		
		private static function activateEventListeners():void
		{
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBgreadingReceived);
			NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgreadingReceived);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, onCalibrationReceived);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, getInitialGlucoseReadings);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.NEW_CALIBRATION_EVENT, onCalibrationReceived);
			Spike.instance.addEventListener(SpikeEvent.APP_IN_FOREGROUND, onAppActivated);
			NetworkInfo.networkInfo.addEventListener(NetworkInfoEvent.CHANGE, onNetworkChange);
		}
		private static function deactivateEventListeners():void
		{
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBgreadingReceived);
			NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgreadingReceived);
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
			
			if (BlueToothDevice.isFollower()) getRemoteReadings();
			
			if (activeTreatmentsUpload.length > 0) syncTreatmentsUpload();
			
			if (activeTreatmentsDelete.length > 0) syncTreatmentsDelete();
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
				Trace.myTrace("NightscoutService.as", "in onConnectionFailed. Can't make connection to the server to test credentials. Error: " +  error.message);
				externalAuthenticationCall = false;
			}
			else if (mode == MODE_GLUCOSE_READING_GET)
			{
				Trace.myTrace("NightscoutService.as", "in onConnectionFailed. Can't make connection to the server while trying to download glucose readings. Error: " +  error.message);
				
				setNextFollowerFetch(TIME_10_SECONDS); //Plus 10 seconds to ensure it passes the getRemoteReadings validation
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
					setTimeout(getRemoteTreatments, TIME_30_SECONDS);
					retriesForTreatmentsDownload++;
				}
			}
			else if (mode == MODE_PROFILE_GET)
			{
				if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled)
				{
					Trace.myTrace("NightscoutService.as", "in onConnectionFailed. Error getting profile. Retrying in 30 seconds. Error: " + error.message);
					setTimeout(getNightscoutProfile, TIME_30_SECONDS);
				}
			}
			else if (mode == MODE_PEBBLE_GET)
			{
				if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled && pumpUserEnabled && retriesForPebbleDownload < MAX_RETRIES_FOR_TREATMENTS)
				{
					Trace.myTrace("NightscoutService.as", "in onConnectionFailed. Error getting pebble endpoint. Retrying in 30 seconds. Error: " + error.message);
					setTimeout(getPebbleEndpoint, TIME_30_SECONDS);
					retriesForPebbleDownload++;
				}
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
				Trace.myTrace("NightscoutService.as", "in onSettingChanged, uploading new sensor.");
				getSensorStart();
			}
			else if 
				(e.data == CommonSettings.COMMON_SETTING_PERIPHERAL_TYPE ||
				 e.data == CommonSettings.COMMON_SETTING_DATA_COLLECTION_MODE ||
				 e.data == CommonSettings.COMMON_SETTING_FOLLOWER_MODE ||
				 e.data == CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL
				)
			{
				if (BlueToothDevice.isFollower() && 
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
					deactivateFollower()
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
				
				//Update remote treatments so the user has updated data when returning to Spike
				if (treatmentsEnabled && nightscoutTreatmentsSyncEnabled)
				{
					if (!pumpUserEnabled)
						getRemoteTreatments();
					else
						getPebbleEndpoint();
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
				if (!pumpUserEnabled)
					getRemoteTreatments();
				else
					getPebbleEndpoint();
			}
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
		
		public static function get syncPebbleActive():Boolean
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
		
		public static function set syncPebbleActive(value:Boolean):void
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