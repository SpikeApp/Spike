package network.httpserver.API
{
	import flash.net.URLVariables;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectUtil;
	
	import spark.formatters.DateTimeFormatter;
	
	import database.BgReading;
	import database.BlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.Database;
	
	import model.ModelLocator;
	
	import network.httpserver.ActionController;
	
	import utils.Trace;
	import utils.UniqueId;
	
	public class NightscoutAPI1Controller extends ActionController
	{
		/* Constants */
		private static const TIME_24_HOURS_6_MINUTES:int = (24 * 60 * 60 * 1000) + 6000;
		
		/* Objects */
		private var nsFormatter:DateTimeFormatter;
		
		public function NightscoutAPI1Controller(path:String)
		{
			super(path);
			
			nsFormatter = new DateTimeFormatter();
			nsFormatter.dateTimePattern = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
			nsFormatter.setStyle("locale", "en_US");
			nsFormatter.useUTC = false;
		}
		
		/**
		 * End Points
		 */
		public function sgv(params:URLVariables):String
		{
			Trace.myTrace("NightscoutAPI1Controller.as", "sgv endpoint called!");
			
			return responseSuccess(getSGV(params));
		}
		
		private function getSGV(params:URLVariables):String
		{
			var response:String = "[]";
			
			try
			{
				var numReadings:int = 1;
				if (params.count != null)	
					numReadings = int(params.count);
				
				var now:Number = new Date().valueOf();
				
				var startTime:Number = now - TIME_24_HOURS_6_MINUTES;
				var startDate:String;
				if (params["find[date][$gte]"] != null)
				{
					startDate = params["find[date][$gte]"];
					if (startDate.indexOf("-") != -1)
						startTime = new Date(startDate).valueOf();
					else 
						startTime = new Date(Number(startDate)).valueOf();
				}
				if (params["find[date][$gt]"] != null)
				{
					startDate = params["find[date][$gt]"];
					if (startDate.indexOf("-") != -1)
						startTime = new Date(startDate).valueOf();
					else 
						startTime = new Date(Number(startDate)).valueOf();
				}
				
				var readingsCollection:Array = [];
				var currentSensorId:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR);
				
				if (currentSensorId != "0" || BlueToothDevice.isFollower()) 
				{
					var cntr:int = ModelLocator.bgReadings.length - 1;
					var itemParsed:int = 0;
					while (cntr > -1 && itemParsed < numReadings) 
					{
						var bgReading:BgReading = ModelLocator.bgReadings[cntr];
						
						if (bgReading.timestamp < startTime)
							break;
						
						if (bgReading.sensor != null || BlueToothDevice.isFollower()) 
						{
							if ((BlueToothDevice.isFollower() || bgReading.sensor.uniqueId == currentSensorId) && bgReading.calculatedValue != 0 && bgReading.rawData != 0) 
							{
								var glucoseValue:Number = Math.round(bgReading.calculatedValue);
								var date:String = nsFormatter.format(bgReading.timestamp);
								readingsCollection.push(
									{
										_id: bgReading.uniqueId,
										unfiltered: !BlueToothDevice.isFollower() ? Math.round(bgReading.usedRaw() * 1000) : glucoseValue * 1000,
										device: !BlueToothDevice.isFollower() ? BlueToothDevice.name : "SpikeFollower",
										sysTime: date,
										filtered: !BlueToothDevice.isFollower() ? Math.round(bgReading.ageAdjustedFiltered() * 1000) : glucoseValue * 1000,
										type: "sgv",
										date: bgReading.timestamp,
										sgv: glucoseValue,
										rssi: 100,
										noise: 1,
										direction: bgReading.slopeName(),
										dateString: date
									}
								);
								itemParsed++;
							}
						}
						cntr--;
					}
				}
				
				response = JSON.stringify(readingsCollection);
				
				readingsCollection = null;
				params = null;
			} 
			catch(error:Error) 
			{
				Trace.myTrace("NightscoutAPI1Controller.as", "Error performing sgv endpoint call. Error: " + error.message);
			}
			
			return response;
		}
		
		public function cal(params:URLVariables):String
		{
			Trace.myTrace("NightscoutAPI1Controller.as", "cal endpoint called.");
			
			var response:String = "[]";
			
			try
			{
				var numCalibrations:int = 1;
				if (params.count != null)	
					numCalibrations = int(params.count);
				var calibrationsCollection:Array = [];
				var calibrationsList:Array;
				var i:int;
				
				if (!BlueToothDevice.isFollower())
				{
					calibrationsList = Calibration.latest(numCalibrations);
					
					for (i = 0; i < calibrationsList.length; i++) 
					{
						var calibration:Calibration = calibrationsList[i] as Calibration;
						if (calibration == null)
							continue;
						
						var calibrationObject:Object = {};
						calibrationObject._id = calibration.uniqueId;
						calibrationObject.device = BlueToothDevice.name;
						calibrationObject.type = "cal";
						calibrationObject.scale = calibration.checkIn ? calibration.firstScale : 1;
						calibrationObject.intercept = calibration.checkIn ? calibration.firstIntercept : calibration.intercept * -1000 / calibration.slope;
						calibrationObject.slope = calibration.checkIn ? calibration.slope : 1000/calibration.slope;
						calibrationObject.date = calibration.timestamp;
						calibrationObject.dateString = nsFormatter.format(calibration.timestamp);
						
						calibrationsCollection.push(calibrationObject);
					}
				}
				else
				{
					var now:Number = new Date().valueOf();
					
					for (i = 0; i < numCalibrations; i++) 
					{
						var dummyCalibrationObject:Object = {};
						dummyCalibrationObject._id = UniqueId.createEventId();
						dummyCalibrationObject.device = "SpikeFollower";
						dummyCalibrationObject.type = "cal";
						dummyCalibrationObject.scale = 1;
						dummyCalibrationObject.intercept = 0;
						dummyCalibrationObject.slope = 0;
						dummyCalibrationObject.date = now;
						dummyCalibrationObject.dateString = nsFormatter.format(now);
						
						calibrationsCollection.push(dummyCalibrationObject);
					}
				}
				
				response = JSON.stringify(calibrationsCollection);
				
				calibrationsList = null;
				calibrationsCollection = null;
				params = null;
			} 
			catch(error:Error) 
			{
				Trace.myTrace("NightscoutAPI1Controller.as", "Error performing cal endpoint call. Error: " + error.message);
			}
			
			return responseSuccess(response);
		}
		
		public function entries(params:URLVariables):String
		{	
			Trace.myTrace("NightscoutAPI1Controller.as", "entries endpoint called!");
			
			var response:String = "";
			
			if (params.extension != null && params.extension != undefined && params.extension.indexOf("json") != -1)
			{
				try
				{
					response = getSGV(params)
				} 
				catch(error:Error) 
				{
					Trace.myTrace("NightscoutAPI1Controller.as", "getSGV returned error: " + error.message + ". Parameters: " + ObjectUtil.toString(params));
				}
				
				return response;
			}
			
			try
			{
				var numReadings:int = 1;
				if (params.count != null)	
					numReadings = int(params.count);
				
				var now:Number = new Date().valueOf();
				
				var startTime:Number = now - TIME_24_HOURS_6_MINUTES;
				var startDate:String;
				if (params["find[date][$gte]"] != null)
				{
					startDate = params["find[date][$gte]"];
					if (startDate.indexOf("-") != -1)
						startTime = new Date(startDate).valueOf();
					else 
						startTime = new Date(Number(startDate)).valueOf();
				}
				if (params["find[date][$gt]"] != null)
				{
					startDate = params["find[date][$gt]"];
					if (startDate.indexOf("-") != -1)
						startTime = new Date(startDate).valueOf();
					else 
						startTime = new Date(Number(startDate)).valueOf();
				}
				var endTime:Number = now;
				if (params["find[date][$lte]"] != null)
				{
					var endDate:String = params["find[date][$lte]"];
					if (endDate.indexOf("-") != -1)
						endTime = new Date(endDate).valueOf();
					else
						endTime = new Date(Number(endDate)).valueOf();
				}
				
				var outputArray:Array = [];
				var outputIndex:int = 0;
				
				if (!BlueToothDevice.isFollower() && (numReadings > 289 && startTime < now - TIME_24_HOURS_6_MINUTES))
				{
					//Get from database
					var readingsList:Array = Database.getBgReadingsDataSynchronous(startTime, endTime, "timestamp, calculatedValue, calculatedValueSlope, hideSlope", numReadings);
					readingsList.reverse();
					var loopLength:int = readingsList.length;
					
					for (var i:int = 0; i < loopLength; i++) 
					{
						var bgReading:Object = readingsList[i] as Object;
						if (bgReading == null || bgReading.calculatedValue == 0 || bgReading.timestamp < startTime || bgReading.timestamp > endTime )
							continue;
						
						outputArray[outputIndex] = nsFormatter.format(bgReading.timestamp) + "\t" + bgReading.timestamp + "\t" + Math.round(bgReading.calculatedValue) + "\t" + calculateSlopeName(Number(bgReading.calculatedValueSlope), bgReading.hideSlope == 1 ? true : false) + "\t" + BlueToothDevice.name + (i < loopLength - 1 ? "\n" : "");
						outputIndex++;
					}
					
					response = outputArray.join("");
					
					readingsList.length = 0;
					readingsList = null;
				}
				else
				{
					//Get from model locator
					var currentSensorId:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR);
					if (currentSensorId != "0" || BlueToothDevice.isFollower()) 
					{
						var cntr:int = ModelLocator.bgReadings.length - 1;
						var itemParsed:int = 0;
						while (cntr > -1 && itemParsed < numReadings) 
						{
							var followerOrInternalReading:BgReading = ModelLocator.bgReadings[cntr];
							
							if (followerOrInternalReading.timestamp < startTime)
								break;
							
							if ((followerOrInternalReading.sensor != null || BlueToothDevice.isFollower()) && ((BlueToothDevice.isFollower() || followerOrInternalReading.sensor.uniqueId == currentSensorId) && followerOrInternalReading.calculatedValue != 0 && followerOrInternalReading.rawData != 0)) 
							{
								outputArray[outputIndex] = (outputIndex > 0 ? "\n" : "") + nsFormatter.format(followerOrInternalReading.timestamp) + "\t" + followerOrInternalReading.timestamp + "\t" + Math.round(followerOrInternalReading.calculatedValue) + "\t" + followerOrInternalReading.slopeName() + "\t" + (!BlueToothDevice.isFollower() ? BlueToothDevice.name : "SpikeFollower");
								outputIndex++;
							}
							cntr--;
						}
					}
					
					response = outputArray.join("");
				}
				
				outputArray.length = 0;
				outputArray = null;
				params = null;
			} 
			catch(error:Error) 
			{
				Trace.myTrace("NightscoutAPI1Controller.as", "Error performing entries endpoint call. Error: " + error.message);
			}
			
			return responseSuccess(response);
		}
		
		public function status(params:URLVariables):String
		{
			Trace.myTrace("NightscoutAPI1Controller.as", "status endpoint called!");
			
			var response:String = "{}";
			
			try
			{
				var now:Number = new Date().valueOf();
				
				var statusObject:Object = {};
				statusObject.status = "ok";
				statusObject.name = "Nightscout";
				statusObject.version = "0.10.3-dev-20171205";
				statusObject.serverTime = nsFormatter.format(now);
				statusObject.serverTimeEpoch = now;
				statusObject.apiEnabled = true;
				statusObject.careportalEnabled = false;
				statusObject.boluscalcEnabled = false;
				statusObject.head = "";
				statusObject.settings = 
					{
						units: CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? "mg/dl" : "mmol",
							timeFormat: CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT).slice(0,2) == "24" ? 24 : 12,
							nightMode: false,
							nightMode: false,
							editMode: "on",
							showRawbg: "always",
							customTitle: "Spike",
							theme: "colors",
							alarmUrgentHigh: true,
							alarmUrgentHighMins: [30, 45, 60, 90, 120],
							alarmHigh: true,
							alarmHighMins: [30, 45, 60, 90, 120],
							alarmLow: true,
							alarmLowMins: [15, 30, 45, 60, 90, 120],
							alarmUrgentLow: true,
							alarmUrgentLowMins: [5, 15, 30, 45, 60, 90, 120],
							alarmUrgentMins: [30, 60, 90, 120],
							alarmWarnMins: [30, 60, 90, 120],
							alarmTimeagoWarn: true,
							alarmTimeagoWarnMins: 15,
							alarmTimeagoUrgent: true,
							alarmTimeagoUrgentMins: "30",
							language: "en",
							scaleY: "log-dynamic",
							showPlugins: "careportal iob cob bwp treatmentnotify basal pushover maker sage boluscalc rawbg upbat delta direction upbat rawbg",
							showForecast: "ar2",
							focusHours: 3,
							heartbeat: "10",
							baseURL: "http://127.0.0.1:1979",
							authDefaultRoles: "readable",
							thresholds: 
							{
								bgHigh: Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK)), 
								bgTargetTop: Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK)), 
								bgTargetBottom: Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK)), 
								bgLow: Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK)) 
							},
							DEFAULT_FEATURES: 
							[
								"bgnow",
								"delta",
								"direction",
								"timeago",
								"devicestatus",
								"upbat",
								"errorcodes",
								"profile"
							],
							alarmTypes: 
							[
								"simple"
							],
							enable:
							[
								"careportal",
								"iob",
								"cob",
								"bwp",
								"treatmentnotify",
								"basal",
								"pushover",
								"maker",
								"sage",
								"boluscalc",
								"rawbg",
								"upbat",
								"pushover",
								"treatmentnotify",
								"bgnow",
								"delta",
								"direction",
								"timeago",
								"devicestatus",
								"errorcodes",
								"profile",
								"simplealarms"
							]
					};
				statusObject.extendedSettings =
					{
						timeago: { enableAlerts: true },
						errorcodes: { urgent: "9 10", info: "1 2 3 4 5 6 7 8", warn: "1 2 3 4 5 6 7 8" },
						sage: { enableAlerts: true, info: 336, warn: 504 },
						basal: { render: "default" }
					};
				statusObject.authorized = null;
				
				response = JSON.stringify(statusObject);
			} 
			catch(error:Error) 
			{
				Trace.myTrace("NightscoutAPI1Controller.as", "error parsing status endpoint response. Error: " + error.message);
			}
			
			return responseSuccess(response);
		}
		
		public function devicestatus(params:URLVariables):String
		{
			Trace.myTrace("NightscoutAPI1Controller.as", "devicestatus endpoint called!");
			
			return responseSuccess("[]");
		}
		
		/**
		 * Utility
		 */
		private function calculateSlopeName(calculatedValueSlope:Number, hideSlope:Boolean):String 
		{
			var slope_by_minute:Number = calculatedValueSlope * 60000;
			var arrow:String = "NONE";
			
			if (slope_by_minute <= (-3.5))
				arrow = "DoubleDown";
			else if (slope_by_minute <= (-2))
				arrow = "SingleDown";
			else if (slope_by_minute <= (-1))
				arrow = "FortyFiveDown";
			else if (slope_by_minute <= (1))
				arrow = "Flat";
			else if (slope_by_minute <= (2))
				arrow = "FortyFiveUp";
			else if (slope_by_minute <= (3.5))
				arrow = "SingleUp";
			else if (slope_by_minute <= (40))
				arrow = "DoubleUp";
			
			if(hideSlope)
				arrow = "NOT COMPUTABLE";
			
			return arrow;
		}
	}
}