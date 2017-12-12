package services
{
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.distriqt.extension.networkinfo.events.NetworkInfoEvent;
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.util.Hex;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import mx.collections.ArrayCollection;
	
	import spark.formatters.DateTimeFormatter;
	
	import Utilities.Trace;
	import Utilities.UniqueId;
	
	import databaseclasses.BgReading;
	import databaseclasses.BlueToothDevice;
	import databaseclasses.Calibration;
	import databaseclasses.CommonSettings;
	import databaseclasses.LocalSettings;
	
	import events.BackGroundFetchServiceEvent;
	import events.CalibrationServiceEvent;
	import events.IosXdripReaderEvent;
	import events.SettingsServiceEvent;
	import events.TransmitterServiceEvent;
	
	import model.ModelLocator;
	
	public class NightScoutService extends EventDispatcher
	{
		[ResourceBundle("nightscoutservice")]
		
		private static var _instance:NightScoutService = new NightScoutService();
		
		public static function get instance():NightScoutService
		{
			return _instance;
		}
		
		
		private static var initialStart:Boolean = true;
		private static var loader:URLLoader;
		private static var _nightScoutEventsUrl:String = "";
		private static var _nightScoutTreatmentsUrl:String = "";
		private static var testUniqueId:String;
		private static var hash:SHA1 = new SHA1();
		
		private static var _syncRunning:Boolean = false;
		private static var lastSyncrunningChangeDate:Number = (new Date()).valueOf();
		private static const maxMinutesToKeepSyncRunningTrue:int = 1;
		private static var lastCalibrationSyncTimeStamp:Number = 0;
		
		//Holder for visual calibrations data
		private static var listOfVisualCalibrationsToUploadAsArray:Array = [];
		
		public static function NightScoutSyncRunning():Boolean {
			return syncRunning;
		}
		
		private static function get syncRunning():Boolean
		{
			if (!_syncRunning)
				return false;
			
			if ((new Date()).valueOf() - lastSyncrunningChangeDate > maxMinutesToKeepSyncRunningTrue * 60 * 1000) {
				lastSyncrunningChangeDate = (new Date()).valueOf();
				_syncRunning = false;
				return false;
			}
			return true;
		}
		
		private static function set syncRunning(value:Boolean):void
		{
			_syncRunning = value;
			myTrace("setting syncRunning = " + value);
			lastSyncrunningChangeDate = (new Date()).valueOf();
		}
		
		
		private static var _hashedAPISecret:String = "";
		
		/**
		 * should be a function that takes a BackGroundFetchServiceEvent as parameter and no return value 
		 */
		private static var functionToCallAtUpOrDownloadSuccess:Function = null;
		/**
		 * should be a function that takes a BackGroundFetchServiceEvent as parameter and no return value 
		 */
		private static var functionToCallAtUpOrDownloadFailure:Function = null;
		
		public function NightScoutService()
		{
			if (_instance != null) {
				throw new Error("NightScoutService class constructor can not be used");	
			}
		}
		
		public static function init():void {
			if (!initialStart)
				return;
			else
				initialStart = false;
			
			//Get Hashed API secret from user
			_hashedAPISecret = Hex.fromArray(hash.hash(Hex.toArray(Hex.fromString(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET)))));
			
			//Define URL for uploading calibrations
			_nightScoutEventsUrl = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/api/v1/entries";
			if (_nightScoutEventsUrl.indexOf('http') == -1) {
				_nightScoutEventsUrl = "https://" + _nightScoutEventsUrl;
			}
			
			//Define URL for uploading treatment (visual representation of the calibration)
			_nightScoutTreatmentsUrl = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/api/v1/treatments";
			if (_nightScoutTreatmentsUrl.indexOf('http') == -1) {
				_nightScoutTreatmentsUrl = "https://" + _nightScoutTreatmentsUrl;
			}
			
			//Define event listeners
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, settingChanged);
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, bgreadingEventReceived);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, calibrationReceived);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.NEW_CALIBRATION_EVENT, calibrationReceived);
			BackGroundFetchService.instance.addEventListener(BackGroundFetchServiceEvent.LOAD_REQUEST_ERROR, defaultErrorFunction);
			BackGroundFetchService.instance.addEventListener(BackGroundFetchServiceEvent.LOAD_REQUEST_RESULT, defaultSuccessFunction);
			BackGroundFetchService.instance.addEventListener(BackGroundFetchServiceEvent.PERFORM_FETCH, performFetch);
			iosxdripreader.instance.addEventListener(IosXdripReaderEvent.APP_IN_FOREGROUND, appInForeGround);
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) != CommonSettings.DEFAULT_SITE_NAME
				&&
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET) != CommonSettings.DEFAULT_API_SECRET
				&&
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URL_AND_API_SECRET_TESTED) == "false"
			) {
				testNightScoutUrlAndSecret();
			} 
			
			function appInForeGround(event:Event = null):void {
				myTrace("in appInForeGround");
				sync();
			}
			
			function calibrationReceived(event:CalibrationServiceEvent):void {
				myTrace("in initialCalibrationReceived");
				sync();
			}
			
			function performFetch(event:BackGroundFetchServiceEvent):void {
				myTrace("in performfetch");
				sync();
			}
			
			function bgreadingEventReceived(event:TransmitterServiceEvent):void {
				myTrace("in bgreadingEventReceived");
				sync();
			}
			
			function settingChanged(event:SettingsServiceEvent):void {
				if (event.data == CommonSettings.COMMON_SETTING_API_SECRET) {
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_WARNING_THAT_NIGHTSCOUT_URL_AND_SECRET_IS_NOT_OK_ALREADY_GIVEN, "false");
					_hashedAPISecret = Hex.fromArray(hash.hash(Hex.toArray(Hex.fromString(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET)))));
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_URL_AND_API_SECRET_TESTED,"false");
				} else if (event.data == CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) {
					LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_WARNING_THAT_NIGHTSCOUT_URL_AND_SECRET_IS_NOT_OK_ALREADY_GIVEN, "false");
					_nightScoutEventsUrl = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/api/v1/entries";			
					if (_nightScoutEventsUrl.indexOf('http') == -1) {
						_nightScoutEventsUrl = "https://" + _nightScoutEventsUrl;
					}
					
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_URL_AND_API_SECRET_TESTED,"false");
				}
				
				if (event.data == CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME || event.data == CommonSettings.COMMON_SETTING_API_SECRET) {
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) != CommonSettings.DEFAULT_SITE_NAME
						&&
						CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET) != CommonSettings.DEFAULT_API_SECRET
						&& 
						!syncRunning
						&& 
						!DexcomShareService.DexcomShareSyncRunning()) {
						testNightScoutUrlAndSecret();
					}
				}
			}
		}
		
		private static function testNightScoutUrlAndSecret():void {
			//test if network is available
			if (NetworkInfo.networkInfo.isReachable()) {
				var testEvent:Object = new Object();
				testUniqueId = UniqueId.createEventId();
				testEvent["_id"] = testUniqueId;
				testEvent["eventType"] = "Exercise";
				testEvent["duration"] = 20;
				testEvent["notes"] = "to test nightscout url";
				var nightScoutTreatmentsUrl:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/api/v1/treatments";
				if (nightScoutTreatmentsUrl.indexOf('http') == -1) {
					nightScoutTreatmentsUrl = "https://" + nightScoutTreatmentsUrl;
				}
				
				myTrace("call_to_nightscout_to_verify_url_and_secret");
				createAndLoadURLRequest(nightScoutTreatmentsUrl, URLRequestMethod.PUT,null,JSON.stringify(testEvent), nightScoutUrlTestSuccess, nightScoutUrlTestError);
			} else {
				myTrace("call_to_nightscout_to_verify_url_and_secret_can_not_be_made");
			}
		}
		
		private static function nightScoutUrlTestSuccess(event:BackGroundFetchServiceEvent):void {
			myTrace("nightScoutUrlTestSuccess with information =  " + event.data.information as String);
			functionToCallAtUpOrDownloadSuccess = null;
			functionToCallAtUpOrDownloadFailure = null;
			
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_URL_AND_API_SECRET_TESTED,"true");
			myTrace("nightscout_test_result_ok");
			var nightScoutTreatmentsUrl:String = "https://" + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) + "/api/v1/treatments";
			createAndLoadURLRequest(nightScoutTreatmentsUrl + "/" + testUniqueId, URLRequestMethod.DELETE, null, null,sync, null);
			
			myTrace(ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_test_result_ok"));
			
			if (BackgroundFetch.appIsInForeground()) {
				DialogService.openSimpleDialog(ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_title"),
					ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_test_result_ok"),
					60);
			}
		}
		
		private static function nightScoutUrlTestError(event:BackGroundFetchServiceEvent):void {
			myTrace("nightScoutUrlTestError with information =  " + event.data.information as String);
			functionToCallAtUpOrDownloadSuccess = null;
			functionToCallAtUpOrDownloadFailure = null;
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_WARNING_THAT_NIGHTSCOUT_URL_AND_SECRET_IS_NOT_OK_ALREADY_GIVEN) == "false" && BackgroundFetch.appIsInForeground()) {
				var errorMessage:String = ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_test_result_nok");
				errorMessage += "\n" + event.data.information;
				
				if ((event.data.information as String).indexOf("Cannot PUT /api/v1/treatments") > -1) {
					errorMessage += "\n" + ModelLocator.resourceManagerInstance.getString("nightscoutservice","care_portal_should_be_enabled");
				}
				
				myTrace(errorMessage);
				
				DialogService.openSimpleDialog(ModelLocator.resourceManagerInstance.getString("nightscoutservice","nightscout_title"),
					errorMessage,
					60);
				myTrace("nightscout_test_result_nok");
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_WARNING_THAT_NIGHTSCOUT_URL_AND_SECRET_IS_NOT_OK_ALREADY_GIVEN, "true");
			}
		}
		
		public static function sync(event:Event = null):void {
			myTrace("in sync");
			
			if (!NetworkInfo.networkInfo.isReachable()) {
				myTrace("network not reachable, calling BackGroundFetchService.callCompletionHandler although this wouldn't make any sense, no network, probably backgroundfetch is not waiting");
				syncFinished();
				return;
			}
			
			if (syncRunning) {
				myTrace("NightScoutService.as sync : sync running already, return");
				return;
			} else {
				if (DexcomShareService.DexcomShareSyncRunning()) {
					myTrace("NightScoutService.as sync : dexcom sync running already, return");
					return;
				}
			}
			
			functionToCallAtUpOrDownloadSuccess = null;
			functionToCallAtUpOrDownloadFailure = null;
			
			var starttime:Number  = (new Date()).valueOf();
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_AZURE_WEBSITE_NAME) == CommonSettings.DEFAULT_SITE_NAME
				||
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_API_SECRET) == CommonSettings.DEFAULT_API_SECRET
				||
				CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URL_AND_API_SECRET_TESTED) ==  "false") {
				syncFinished();
				return;
			}
			
			if (Calibration.allForSensor().length < 2) {
				syncFinished();
				return;
			}
			
			syncRunning = true;
			
			var listOfReadingsAsArray:Array = [];
			var lastSyncTimeStamp:Number = new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP));
			var formatter:DateTimeFormatter = new DateTimeFormatter();
			formatter.dateTimePattern = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
			formatter.setStyle("locale", "en_US");
			formatter.useUTC = false;
			
			var cntr:int = ModelLocator.bgReadings.length - 1;
			var arrayCntr:int = 0;
			
			while (cntr > -1) {
				var bgReading:BgReading = ModelLocator.bgReadings.getItemAt(cntr) as BgReading;
				if (bgReading.timestamp > lastSyncTimeStamp) {
					if (bgReading.calculatedValue != 0) {
						var newReading:Object = new Object();
						newReading["device"] = BlueToothDevice.name;
						newReading["date"] = bgReading.timestamp;
						newReading["dateString"] = formatter.format(bgReading.timestamp);
						newReading["sgv"] = Math.round(bgReading.calculatedValue);
						newReading["direction"] = bgReading.slopeName();
						newReading["type"] = "sgv";
						newReading["filtered"] = Math.round(bgReading.ageAdjustedFiltered() * 1000);
						newReading["unfiltered"] = Math.round(bgReading.usedRaw() * 1000);
						newReading["rssi"] = 100;
						newReading["noise"] = bgReading.noiseValue();
						newReading["xDrip_filtered_calculated_value"] = bgReading.filteredCalculatedValue;
						newReading["xDrip_raw"] = bgReading.rawData;
						newReading["xDrip_filtered"] = bgReading.filteredData;
						newReading["xDrip_calculated_value"] = bgReading.calculatedValue;
						newReading["xDrip_age_adjusted_raw_value"] = bgReading.ageAdjustedRawValue;
						newReading["xDrip_calculated_current_slope"] = BgReading.currentSlope();
						newReading["xDrip_hide_slope"] = bgReading.hideSlope;
						newReading["sysTime"] = formatter.format(bgReading.timestamp);
						newReading["_id"] = bgReading.uniqueId;
						listOfReadingsAsArray[arrayCntr] = newReading;
					}
				} else {
					break;
				}
				cntr--;
				arrayCntr++;
			}			
			
			var endtime:Number  = (new Date()).valueOf();
			
			myTrace("sync , time taken to go through bgreadings = " + ((endtime - starttime)/1000) + " seconds");
			if (listOfReadingsAsArray.length > 0) {
				myTrace("listOfReadingsAsArray.length > 0");
				var logString:String = ".. not filled in ..";
				/*for (var cntr2:int = 0; cntr2 < listOfReadingsAsArray.length; cntr2++) {
				logString += " " + listOfReadingsAsArray[cntr2]["_id"] + ",";
				}*/
				myTrace("uploading_events_with_id" + logString);
				createAndLoadURLRequest(_nightScoutEventsUrl, URLRequestMethod.POST, null, JSON.stringify(listOfReadingsAsArray), bgReadingToNSUploadSuccess, bgReadingToNSUploadFailed);
			} else {
				uploadCalibrations();
				return;
			}
		}
		
		private static function bgReadingToNSUploadSuccess(event:Event):void {
			myTrace("in bgReadingToNSUploadSuccess");
			myTrace("upload_to_nightscout_successfull");
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_BGREADING_TIMESTAMP, (new Date()).valueOf().toString());
			uploadCalibrations();
		}
		
		private static function bgReadingToNSUploadFailed(event:BackGroundFetchServiceEvent):void {
			myTrace("in nightScoutUploadFailed");
			
			var errorMessage:String;
			if (event.data) {
				if (event.data.information)
					errorMessage = event.data.information;
			} else {
				errorMessage = "";
			}
			
			myTrace("upload_to_nightscout_unsuccessfull" + errorMessage);
			syncFinished();
		}
		
		private static function defaultErrorFunction(event:BackGroundFetchServiceEvent):void {
			if(functionToCallAtUpOrDownloadFailure != null) {
				functionToCallAtUpOrDownloadFailure(event);
			}
			
			functionToCallAtUpOrDownloadSuccess = null;
			functionToCallAtUpOrDownloadFailure = null;
		}
		private static function defaultSuccessFunction(event:BackGroundFetchServiceEvent):void {
			if(functionToCallAtUpOrDownloadSuccess != null) {
				functionToCallAtUpOrDownloadSuccess(event);
			}
			
			functionToCallAtUpOrDownloadSuccess = null;
			functionToCallAtUpOrDownloadFailure = null;
		}
		
		/**
		 * creates URL request and loads it<br>
		 */
		private static function createAndLoadURLRequest(url:String, requestMethod:String, urlVariables:URLVariables, data:String, successFunction:Function, errorFunction:Function):void {
			if (errorFunction != null) {
				functionToCallAtUpOrDownloadFailure = errorFunction;
			} else
				functionToCallAtUpOrDownloadFailure = null;
			if (successFunction != null) {
				functionToCallAtUpOrDownloadSuccess = successFunction;
			} else {
				functionToCallAtUpOrDownloadSuccess = null;
			}
			BackGroundFetchService.createAndLoadUrlRequest(url, requestMethod ? requestMethod:URLRequestMethod.GET, urlVariables, data, "application/json", "api-secret", _hashedAPISecret);
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("NightScoutService.as", log);
		}
		
		private static function syncFinished():void {
			myTrace("syncfinished");
			syncRunning = false;
			DexcomShareService.sync();
		}
		
		private static function uploadCalibrations():void {
			var listOfCalibrationsToUploadAsArray:Array = [];
			var lastSyncTimeStamp:Number = new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_CALIBRATION_TIMESTAMP));
			var formatter:DateTimeFormatter = new DateTimeFormatter();
			formatter.dateTimePattern = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
			formatter.setStyle("locale", "en_US");
			formatter.useUTC = false;
			
			myTrace("in uploadcalibrations");
			var calibrations:ArrayCollection = Calibration.allForSensor();
			var cntr:int = calibrations.length - 1;
			var arrayCntr:int = 0;
			lastCalibrationSyncTimeStamp = 0;
			
			while (cntr > -1) {
				var calibration:Calibration = calibrations.getItemAt(cntr) as Calibration;
				if (calibration.timestamp > lastSyncTimeStamp && calibration.slope != 0) {
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
					//newCalibration["sysTime"] = formatter.format(calibration.timestamp);
					
					listOfCalibrationsToUploadAsArray[arrayCntr] = newCalibration;
					
					//Create holder for visual calibration
					var newVisualCalibration:Object = new Object();
					newVisualCalibration["eventType"] = "BG Check";	
					newVisualCalibration["created_at"] = formatter.format(calibration.timestamp);
					newVisualCalibration["enteredBy"] = "xDrip iOS";	
					newVisualCalibration["glucose"] = calibration.bg;
					newVisualCalibration["glucoseType"] = "Finger";
					newVisualCalibration["notes"] = "Sensor Calibration";
					newVisualCalibration["created_at"] = formatter.format(calibration.timestamp);
					
					//Push visual calibration to list for further processing
					listOfVisualCalibrationsToUploadAsArray[arrayCntr] = newVisualCalibration;
					
					arrayCntr++;
					if (calibration.timestamp > lastCalibrationSyncTimeStamp) {
						lastCalibrationSyncTimeStamp = calibration.timestamp;
					}
				}
				cntr--;
			}			
			if (listOfCalibrationsToUploadAsArray.length > 0) {
				myTrace("listOfCalibrationsToUploadAsArray.length > 0");
				createAndLoadURLRequest(_nightScoutEventsUrl, URLRequestMethod.POST, null, JSON.stringify(listOfCalibrationsToUploadAsArray), calibrationToNSUploadSuccess, calibrationToNSUploadFailed);
			} else {
				syncFinished();
				return;
			}
		}
		
		private static function calibrationToNSUploadSuccess(event:Event):void {
			myTrace("in calibrationToNSUploadSuccess");
			myTrace("upload to ns successfull");
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NIGHTSCOUT_UPLOAD_CALIBRATION_TIMESTAMP, lastCalibrationSyncTimeStamp.toString());
			
			if(listOfVisualCalibrationsToUploadAsArray.length > 0) {
				//Upload visual calibrations
				myTrace("listOfVisualCalibrationsToUploadAsArray.length > 0");
				myTrace("Uploading visual calibrations");
				createAndLoadURLRequest(_nightScoutTreatmentsUrl, URLRequestMethod.POST, null, JSON.stringify(listOfVisualCalibrationsToUploadAsArray), visualCalibrationToNSUploadSuccess, visualCalibrationToNSUploadFailed);
			} else {
				//Finish Sync
				syncFinished();
			}
		}
		
		private static function calibrationToNSUploadFailed(event:BackGroundFetchServiceEvent):void {
			myTrace("in calibrationToNSUploadFailed");
			myTrace("upload to ns failed, visual calibrations will not be uploaded as well");
			
			var errorMessage:String;
			if (event.data) {
				if (event.data.information)
					errorMessage = event.data.information;
			} else {
				errorMessage = "";
			}
			
			myTrace("upload_to_nightscout_unsuccessfull" + errorMessage);
			syncFinished();
		}
		
		private static function visualCalibrationToNSUploadSuccess(event:Event):void {
			myTrace("in visualCalibrationToNSUploadSuccess");
			myTrace("visual calibration upload to ns successfull");
			
			//Destroy list of visual calibrations to free up memory
			listOfVisualCalibrationsToUploadAsArray.length = 0;
			
			//Finish Sync
			syncFinished();
		}
		
		private static function visualCalibrationToNSUploadFailed(event:BackGroundFetchServiceEvent):void {
			myTrace("in visualCalibrationToNSUploadFailed");
			myTrace("visual calibration upload to ns failed");
			
			var errorMessage:String;
			if (event.data) {
				if (event.data.information)
					errorMessage = event.data.information;
			} else {
				errorMessage = "";
			}
			
			myTrace("visual_calibration_upload_to_nightscout_unsuccessfull" + errorMessage);
			
			//Destroy list of visual calibrations to free up memory
			listOfVisualCalibrationsToUploadAsArray.length = 0;
			
			//Finish Sync
			syncFinished();
		}
	}
}