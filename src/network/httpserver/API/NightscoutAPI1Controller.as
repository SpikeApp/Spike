package network.httpserver.API
{
	import com.adobe.utils.DateUtil;
	
	import flash.net.URLVariables;
	
	import mx.utils.ObjectUtil;
	
	import spark.formatters.DateTimeFormatter;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.Database;
	
	import model.ModelLocator;
	
	import network.httpserver.ActionController;
	
	import services.AlarmService;
	
	import treatments.BasalRate;
	import treatments.Insulin;
	import treatments.Profile;
	import treatments.ProfileManager;
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import utils.SpikeJSON;
	import utils.TimeSpan;
	import utils.Trace;
	import utils.UniqueId;
	
	public class NightscoutAPI1Controller extends ActionController
	{	
		/* Objects */
		private var nsFormatter:DateTimeFormatter;
		
		public function NightscoutAPI1Controller(path:String)
		{
			super(path);
			
			nsFormatter = new DateTimeFormatter();
			nsFormatter.dateTimePattern = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
			nsFormatter.setStyle("locale", "en_US");
			nsFormatter.useUTC = true;
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
				
				var startTime:Number = now - TimeSpan.TIME_24_HOURS_6_MINUTES;
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
				
				if (currentSensorId != "0" || CGMBlueToothDevice.isFollower()) 
				{
					var cntr:int = ModelLocator.bgReadings.length - 1;
					var itemParsed:int = 0;
					while (cntr > -1 && itemParsed < numReadings) 
					{
						var bgReading:BgReading = ModelLocator.bgReadings[cntr];
						
						if (bgReading.timestamp < startTime)
							break;
						
						if (bgReading.sensor != null || CGMBlueToothDevice.isFollower()) 
						{
							if ((CGMBlueToothDevice.isFollower() || bgReading.sensor.uniqueId == currentSensorId) && bgReading.calculatedValue != 0 && bgReading.rawData != 0) 
							{
								var glucoseValue:Number = Math.round(bgReading.calculatedValue);
								var date:String = nsFormatter.format(bgReading.timestamp);
								var readingObject:Object = {};
								readingObject["_id"] = bgReading.uniqueId;
								readingObject.unfiltered = !CGMBlueToothDevice.isFollower() ? Math.round(bgReading.usedRaw() * 1000) : glucoseValue * 1000;
								readingObject.device = !CGMBlueToothDevice.isFollower() ? CGMBlueToothDevice.name : "SpikeFollower";
								readingObject.sysTime = date;
								readingObject.filtered = !CGMBlueToothDevice.isFollower() ? Math.round(bgReading.ageAdjustedFiltered() * 1000) : glucoseValue * 1000;
								readingObject.type = "sgv";
								readingObject.date = bgReading.timestamp;
								readingObject.sgv = glucoseValue;
								readingObject.rssi = 100;
								readingObject.noise = 1;
								readingObject.direction = bgReading.slopeName();
								readingObject.dateString = date;
								readingsCollection.push(readingObject);
								itemParsed++;
							}
						}
						cntr--;
					}
				}
				
				//response = JSON.stringify(readingsCollection);
				response = SpikeJSON.stringify(readingsCollection);
				
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
				
				if (!CGMBlueToothDevice.isFollower())
				{
					calibrationsList = Calibration.latest(numCalibrations);
					
					for (i = 0; i < calibrationsList.length; i++) 
					{
						var calibration:Calibration = calibrationsList[i] as Calibration;
						if (calibration == null)
							continue;
						
						var calibrationObject:Object = {};
						calibrationObject["_id"] = calibration.uniqueId;
						calibrationObject.device = CGMBlueToothDevice.name;
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
						dummyCalibrationObject["_id"] = UniqueId.createEventId();
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
				
				//response = JSON.stringify(calibrationsCollection);
				response = SpikeJSON.stringify(calibrationsCollection);
				
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
					response = getSGV(params);
				} 
				catch(error:Error) 
				{
					Trace.myTrace("NightscoutAPI1Controller.as", "getSGV returned error: " + error.message + ". Parameters: " + ObjectUtil.toString(params));
				}
				
				return responseSuccess(response);
			}
			
			try
			{
				var numReadings:int = 1;
				if (params.count != null)	
					numReadings = int(params.count);
				
				var now:Number = new Date().valueOf();
				
				var startTime:Number = now - TimeSpan.TIME_24_HOURS_6_MINUTES;
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
				
				if (!CGMBlueToothDevice.isFollower() && (numReadings > 289 && startTime < now - TimeSpan.TIME_24_HOURS_6_MINUTES))
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
						
						outputArray[outputIndex] = nsFormatter.format(bgReading.timestamp) + "\t" + bgReading.timestamp + "\t" + Math.round(bgReading.calculatedValue) + "\t" + calculateSlopeName(Number(bgReading.calculatedValueSlope), bgReading.hideSlope == 1 ? true : false) + "\t" + CGMBlueToothDevice.name + (i < loopLength - 1 ? "\n" : "");
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
					if (currentSensorId != "0" || CGMBlueToothDevice.isFollower()) 
					{
						var cntr:int = ModelLocator.bgReadings.length - 1;
						var itemParsed:int = 0;
						while (cntr > -1 && itemParsed < numReadings) 
						{
							var followerOrInternalReading:BgReading = ModelLocator.bgReadings[cntr];
							
							if (followerOrInternalReading.timestamp < startTime)
								break;
							
							if ((followerOrInternalReading.sensor != null || CGMBlueToothDevice.isFollower()) && ((CGMBlueToothDevice.isFollower() || followerOrInternalReading.sensor.uniqueId == currentSensorId) && followerOrInternalReading.calculatedValue != 0 && followerOrInternalReading.rawData != 0)) 
							{
								outputArray[outputIndex] = (outputIndex > 0 ? "\n" : "") + nsFormatter.format(followerOrInternalReading.timestamp) + "\t" + followerOrInternalReading.timestamp + "\t" + Math.round(followerOrInternalReading.calculatedValue) + "\t" + followerOrInternalReading.slopeName() + "\t" + (!CGMBlueToothDevice.isFollower() ? CGMBlueToothDevice.name : "SpikeFollower");
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
						alarmsSnoozedUntilTimestamps: 
						{
							bgHigh: AlarmService.highAlertSnoozedUntilTimestamp(), 
							bgTargetTop: AlarmService.veryHighAlertSnoozedUntilTimestamp(), 
							bgTargetBottom: AlarmService.lowAlertSnoozedUntilTimestamp(), 
							bgLow: AlarmService.veryLowAlertSnoozedUntilTimestamp(),
							missedReadings: AlarmService.missedReadingAlertSnoozedUntilTimestamp(),
							phoneMuted: AlarmService.phoneMutedAlertSnoozedUntilTimestamp(),
							bgFastRise: AlarmService.fastRiseAlertSnoozedUntilTimestamp(),
							bgFastDrop: AlarmService.fastDropAlertSnoozedUntilTimestamp()
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
				
				//response = JSON.stringify(statusObject);
				response = SpikeJSON.stringify(statusObject);
			} 
			catch(error:Error) 
			{
				Trace.myTrace("NightscoutAPI1Controller.as", "error parsing status endpoint response. Error: " + error.message);
			}
			
			return responseSuccess(response);
		}
		
		public function profile(params:URLVariables):String
		{
			var i:int;
			
			var upperProfileObject:Object = {};
			upperProfileObject["_id"] = UniqueId.createEventId();
			upperProfileObject.defaultProfile = "SpikeProfile";
			upperProfileObject.startDate = nsFormatter.format(0);
			upperProfileObject.mills = "0";
			upperProfileObject.units = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? "mg/dl" : "mmol";
			upperProfileObject.created_at = !CGMBlueToothDevice.isFollower() && ProfileManager.profilesList.length > 0 ? nsFormatter.format((ProfileManager.profilesList[0] as Profile).timestamp).replace("000+0000", "000Z") : nsFormatter.format(new Date().valueOf()).replace("000+0000", "000Z"); 
			
			var upperSpikeProfile:Object = {};
			var spikeProfile:Object = {};
			var defaultInsulinID:String = ProfileManager.getDefaultInsulinID();
			var defaultInsulin:Insulin;
			if (defaultInsulinID != "")
			{
				ProfileManager.getInsulin(defaultInsulinID)
			}
			spikeProfile.dia = defaultInsulin != null ? defaultInsulin.dia : 3;
			spikeProfile.carbratio = [];
			spikeProfile.sens = [];
			spikeProfile["target_low"] = [];
			spikeProfile["target_high"] = [];
			
			var userProfiles:Array = ProfileManager.profilesList;
			for (i = 0; i < userProfiles.length; i++) 
			{
				var profile:Profile = userProfiles[i];
				if (profile != null && profile.time != "" && profile.insulinSensitivityFactors != "" && profile.insulinToCarbRatios != "" && profile.targetGlucoseRates != "")
				{
					//Date
					var profileDate:Date = ProfileManager.getProfileDate(profile);
					
					//Data
					if (i == 0)
					{
						spikeProfile.carbratio.push( { time: TimeSpan.formatHoursMinutes(profileDate.hours, profileDate.minutes, TimeSpan.TIME_FORMAT_24H), value: String(profile.insulinToCarbRatios), timeAsSeconds: "0" } );
						spikeProfile.sens.push( { time: TimeSpan.formatHoursMinutes(profileDate.hours, profileDate.minutes, TimeSpan.TIME_FORMAT_24H), value: String(profile.insulinSensitivityFactors), timeAsSeconds: "0" } );
						spikeProfile["target_low"].push( { time: TimeSpan.formatHoursMinutes(profileDate.hours, profileDate.minutes, TimeSpan.TIME_FORMAT_24H), value: String(profile.targetGlucoseRates), timeAsSeconds: "0" } );
						spikeProfile["target_high"].push( { time: TimeSpan.formatHoursMinutes(profileDate.hours, profileDate.minutes, TimeSpan.TIME_FORMAT_24H), value: String(profile.targetGlucoseRates), timeAsSeconds: "0" } );
					}
					else
					{
						spikeProfile.carbratio.push( { time: TimeSpan.formatHoursMinutes(profileDate.hours, profileDate.minutes, TimeSpan.TIME_FORMAT_24H), value: String(profile.insulinToCarbRatios) } );
						spikeProfile.sens.push( { time: TimeSpan.formatHoursMinutes(profileDate.hours, profileDate.minutes, TimeSpan.TIME_FORMAT_24H), value: String(profile.insulinSensitivityFactors) } );
						spikeProfile["target_low"].push( { time: TimeSpan.formatHoursMinutes(profileDate.hours, profileDate.minutes, TimeSpan.TIME_FORMAT_24H), value: String(profile.targetGlucoseRates) } );
						spikeProfile["target_high"].push( { time: TimeSpan.formatHoursMinutes(profileDate.hours, profileDate.minutes, TimeSpan.TIME_FORMAT_24H), value: String(profile.targetGlucoseRates) } );
					}
				}
			}
			
			spikeProfile["carbs_hr"] = String(ProfileManager.getCarbAbsorptionRate());
			spikeProfile.delay = "20";
			spikeProfile.timezone = "Europe/Lisbon";
			
			var basalRates:Array = [];
			ProfileManager.basalRatesList.sortOn(["startTime"], Array.CASEINSENSITIVE);
			for (i = 0; i < ProfileManager.basalRatesList.length; i++) 
			{
				var basalRate:BasalRate = ProfileManager.basalRatesList[i];
				if (basalRate != null)
				{
					var br:Object = {};
					br.time = basalRate.startTime;
					br.value = String(basalRate.basalRate);
					br.timeAsSeconds = (basalRate.startHours * 60 * 60) + (basalRate.startMinutes * 60);
					
					basalRates.push(br);
				}
			}
			
			spikeProfile.basal = basalRates;
			spikeProfile.startDate = nsFormatter.format(0);
			spikeProfile.units = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? "mg/dl" : "mmol";
			
			upperSpikeProfile.SpikeProfile = spikeProfile;
			
			upperProfileObject.store = upperSpikeProfile
				
			return responseSuccess(SpikeJSON.stringify([upperProfileObject]));
		}
		
		public function devicestatus(params:URLVariables):String
		{
			Trace.myTrace("NightscoutAPI1Controller.as", "devicestatus endpoint called!");
			
			return responseSuccess("[]");
		}
		
		public function treatments(params:URLVariables):String
		{
			Trace.myTrace("NightscoutAPI1Controller.as", "treatments endpoint called!");
			
			var response:String = "";
			
			if (params.method == "POST") //Insert treatment in Spike
			{
				//Validation
				if (CGMBlueToothDevice.isFollower() && (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) == "" || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) == "" || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) != "Nightscout"))
					return responseSuccess("Follower doesn't have enough privileges to add treatments!");
				
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED) != "true")
					return responseSuccess("Treatments are not enabled in Spike!");
				
				//Define initial treatment properties
				var treatmentTimestamp:Number = new Date().valueOf();
				if (params.eventTime != null && !isNaN(Number(params.eventTime)))
					treatmentTimestamp = Number(params.eventTime);
				var treatmentEventType:String = "";
				if (params.eventType != null)
					treatmentEventType = String(params.eventType);
				var treatmentType:String = "";
				var treatmentInsulinAmount:Number = 0;
				var treatmentInsulinID:String = "";
				var treatmentCarbs:Number = 0;
				var treatmentGlucose:Number = 0;
				var treatmentNote:String = "";
				var treatmentDuration:Number = 0;
				var treatmentExerciseIntensity:String = Treatment.EXERCISE_INTENSITY_MODERATE;
				var basalAmount:Number = 0;
				var basalDuration:Number = 30;
				var isBasalAbsolute:Boolean = false;
				var isBasalRelative:Boolean = false;
				var isTempBasalEnd:Boolean = false;
				
				if (treatmentEventType == "Correction Bolus" || treatmentEventType == "Bolus" || treatmentEventType == "Correction")
				{
					treatmentType = Treatment.TYPE_BOLUS;
					if (params.insulin != null)
						treatmentInsulinAmount = Number(params.insulin);
					treatmentInsulinID = "000000";
				}
				else if (treatmentEventType == "Meal Bolus" || treatmentEventType == "Snack Bolus")
				{
					treatmentType = Treatment.TYPE_MEAL_BOLUS;
					if (params.insulin != null)
						treatmentInsulinAmount = Number(params.insulin);
					treatmentInsulinID = "000000";
					if (params.carbs != null)
						treatmentCarbs = Number(params.carbs);
				}
				else if (treatmentEventType == "Carb Correction" || treatmentEventType == "Carbs")
				{
					treatmentType = Treatment.TYPE_CARBS_CORRECTION;
					if (params.carbs != null)
						treatmentCarbs = Number(params.carbs);
				}
				else if (treatmentEventType == "Note")
				{
					treatmentType = Treatment.TYPE_NOTE;
					if (params.insulin != null && params.carbs != null)
					{
						//It's not actually a note, it's a meal
						treatmentType = Treatment.TYPE_MEAL_BOLUS;
						treatmentInsulinAmount = Number(params.insulin);
						treatmentInsulinID = ProfileManager.getDefaultInsulinID();
						treatmentCarbs = Number(params.carbs);
					}
					else if (params.insulin != null)
					{
						//It's not actually a note, it's a bolus
						treatmentType = Treatment.TYPE_BOLUS;
						treatmentInsulinAmount = Number(params.insulin);
						treatmentInsulinID = ProfileManager.getDefaultInsulinID();
					}
					else if (params.carbs != null)
					{
						//It's not actually a note, it's a carb
						treatmentType = Treatment.TYPE_CARBS_CORRECTION;
						treatmentCarbs = Number(params.carbs);
					}
				}
				else if (treatmentEventType == "BG Check")
				{
					treatmentType = Treatment.TYPE_GLUCOSE_CHECK;
					treatmentGlucose = Number(params.glucose);
				}
				else if (treatmentEventType == "Insulin Change")
				{
					treatmentType = Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE;
				}
				else if (treatmentEventType == "Pump Battery Change")
				{
					treatmentType = Treatment.TYPE_PUMP_BATTERY_CHANGE;
				}
				else if (treatmentEventType == "Site Change")
				{
					treatmentType = Treatment.TYPE_PUMP_SITE_CHANGE;
				}
				else if (treatmentEventType == "Exercise")
				{
					treatmentType = Treatment.TYPE_EXERCISE;
					
					if (params.duration != null)
						treatmentDuration = Number(params.duration);
					
					if (params.exerciseIntensity != null)
						treatmentExerciseIntensity= String(params.exerciseIntensity);
				}
				else if (treatmentEventType == "Temp Basal")
				{
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI) == "pump")
					{
						treatmentType = Treatment.TYPE_TEMP_BASAL;
					}
					else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI) == "mdi")
					{
						treatmentType = Treatment.TYPE_MDI_BASAL;
					}
					
					if (params.duration != null)
						basalDuration = Number(params.duration);
					
					if (params.absolute != null)
					{
						basalAmount = Number(params.absolute);
						isBasalAbsolute = true;
						isBasalRelative = false;
					}
					else if (params.percent != null)
					{
						basalAmount = Number(params.percent);
						isBasalRelative = true;
						isBasalAbsolute = false;
					}
					
					if (!isBasalAbsolute && !isBasalRelative)
					{
						isTempBasalEnd = true;
					}
				}
				
				
				if (params.notes != null)
					treatmentNote = params.notes;
				
				//Check if treatment is supported by Spike
				if (treatmentType != "")
				{
					//It's a new treatment. Let's create it
					var treatment:Treatment = new Treatment
					(
						treatmentType,
						treatmentTimestamp,
						treatmentInsulinAmount,
						treatmentInsulinID,
						treatmentCarbs,
						treatmentGlucose,
						treatmentEventType != "BG Check" ? TreatmentsManager.getEstimatedGlucose(treatmentTimestamp) : treatmentGlucose,
						treatmentNote
					);
					
					if (treatmentType == Treatment.TYPE_EXERCISE)
					{
						treatment.duration = treatmentDuration;
						treatment.exerciseIntensity = treatmentExerciseIntensity;
					}
					
					if (treatmentType == Treatment.TYPE_MDI_BASAL || treatmentType == Treatment.TYPE_TEMP_BASAL)
					{
						if (isBasalAbsolute)
						{
							treatment.basalAbsoluteAmount = basalAmount;
						}
						else if (isBasalRelative)
						{
							treatment.basalPercentAmount = basalAmount;
						}
						
						treatment.basalDuration = basalDuration;
						treatment.isBasalAbsolute = isBasalAbsolute;
						treatment.isBasalRelative = isBasalRelative;
						treatment.isTempBasalEnd = isTempBasalEnd;
					}
					
					if (treatmentType == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE)
					{
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_INSULIN_CARTRIDGE_CHANGE, String(treatmentTimestamp), true, false);
					}
					else if (treatmentType == Treatment.TYPE_PUMP_BATTERY_CHANGE)
					{
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_BATTERY_CHANGE, String(treatmentTimestamp), true, false);
					}
					else if (treatmentType == Treatment.TYPE_PUMP_SITE_CHANGE)
					{
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LAST_PUMP_SITE_CHANGE, String(treatmentTimestamp), true, false);
					}
					
					//Add treatment to Spike and Databse
					TreatmentsManager.addInternalTreatment(treatment, true);
					
					//Format response
					var responseArray:Array = [];
					var responseObject:Object = {};
					responseObject["_id"] = treatment.ID;
					responseObject["created_at"] = nsFormatter.format(treatmentTimestamp).replace("000+0000", "000Z");
					responseObject.eventType = treatmentEventType;
					responseObject.insulin = treatmentInsulinAmount;
					responseObject.carbs = treatmentCarbs;
					responseObject.glucose = treatmentGlucose;
					responseObject.notes = treatmentNote;
					if (treatmentType == Treatment.TYPE_EXERCISE)
					{
						responseObject.duration = treatmentDuration;
						responseObject.exerciseIntensity = treatmentExerciseIntensity;
					}
					if (treatmentType == Treatment.TYPE_MDI_BASAL || treatmentType == Treatment.TYPE_TEMP_BASAL)
					{
						if (isBasalAbsolute)
						{
							responseObject.absolute = basalAmount;
						}
						else if (isBasalRelative)
						{
							responseObject.percent = basalAmount;
						}
						responseObject.duration = basalDuration;
					}
					responseArray.push(responseObject);
					response = SpikeJSON.stringify(responseArray);
				}
			}
			else if (params.method == "GET") //Return treatments. Useful for Spike to Spike follower mode
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED) != "true")
					return responseSuccess("[]");
				
				var excludedTreatmentsList:Object = {};
				var excludedTreatmentsExist:Boolean = false;
				var includedTreatmentsList:Object = {};
				var includedTreatmentsExist:Boolean = false;
				
				for (var prop:String in params) 
				{ 
					if (prop.indexOf("[$nin]") != -1)
					{
						excludedTreatmentsList[params[prop]] = true;
						excludedTreatmentsExist = true;
					}
					
					if (prop.indexOf("[$in]") != -1)
					{
						includedTreatmentsList[params[prop]] = true;
						includedTreatmentsExist = true;
					}
				}
				
				var firstTreatmentTimestamp:Number = new Date().valueOf() - TimeSpan.TIME_24_HOURS;
				if (params["find[created_at][$gte]"] != null)
				{
					firstTreatmentTimestamp = DateUtil.parseW3CDTF(params["find[created_at][$gte]"]).valueOf();
				}
				
				//Common Variables
				var i:int;
				var treatmentsList:Array = [];
				
				//Treatments
				var spikeTreatmentsList:Array = TreatmentsManager.treatmentsList.concat();
				spikeTreatmentsList.sortOn(["timestamp"], Array.NUMERIC | Array.DESCENDING);
				
				for (i = 0; i < spikeTreatmentsList.length; i++) 
				{
					var spikeTreatment:Treatment = spikeTreatmentsList[i] as Treatment;
					if (spikeTreatment != null && spikeTreatment.timestamp >= firstTreatmentTimestamp)
					{
						var responseTreatmentType:String;
						if (spikeTreatment.type == Treatment.TYPE_BOLUS)
							responseTreatmentType = "Bolus";
						else if (spikeTreatment.type == Treatment.TYPE_CORRECTION_BOLUS)
							responseTreatmentType = "Correction Bolus";
						else if (spikeTreatment.type == Treatment.TYPE_CARBS_CORRECTION)
							responseTreatmentType = "Carb Correction";
						else if (spikeTreatment.type == Treatment.TYPE_GLUCOSE_CHECK)
							responseTreatmentType = "BG Check";
						else if (spikeTreatment.type == Treatment.TYPE_MEAL_BOLUS)
							responseTreatmentType = "Meal Bolus";
						else if (spikeTreatment.type == Treatment.TYPE_NOTE)
							responseTreatmentType = "Note";
						else if (spikeTreatment.type == Treatment.TYPE_SENSOR_START)
							responseTreatmentType = "Sensor Start";
						else if (spikeTreatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT || spikeTreatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
							responseTreatmentType = "Combo Bolus";
						else if (spikeTreatment.type == Treatment.TYPE_EXERCISE)
							responseTreatmentType = "Exercise";
						else if (spikeTreatment.type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE)
							responseTreatmentType = "Insulin Change";
						else if (spikeTreatment.type == Treatment.TYPE_PUMP_BATTERY_CHANGE)
							responseTreatmentType = "Pump Battery Change";
						else if (spikeTreatment.type == Treatment.TYPE_PUMP_SITE_CHANGE)
							responseTreatmentType = "Site Change";
						
						if (excludedTreatmentsExist && excludedTreatmentsList[responseTreatmentType] != null)
						{
							continue;
						}
						
						if (includedTreatmentsExist && includedTreatmentsList[responseTreatmentType] == null)
						{
							continue;
						}
						
						var responseTreatment:Object = {};
						responseTreatment["_id"] = spikeTreatment.ID;
						responseTreatment["created_at"] = nsFormatter.format(spikeTreatment.timestamp).replace("000+0000", "000Z");
						responseTreatment.eventType = responseTreatmentType;
						
						if (responseTreatmentType == "Bolus" || responseTreatmentType == "Correction Bolus" || responseTreatmentType == "Meal Bolus" || (responseTreatmentType == "Combo Bolus" && spikeTreatment.insulinAmount > 0))
						{
							responseTreatment.insulin = spikeTreatment.insulinAmount;
							responseTreatment.insulinID = spikeTreatment.insulinID;
							responseTreatment.dia = spikeTreatment.dia;
							
							var treatmentInsulin:Insulin = ProfileManager.getInsulin(spikeTreatment.insulinID);
							if (treatmentInsulin != null)
							{
								responseTreatment.insulinName = treatmentInsulin.name;
								responseTreatment.insulinType = treatmentInsulin.type;
								responseTreatment.insulinPeak = treatmentInsulin.peak;
								responseTreatment.insulinCurve = treatmentInsulin.curve;
							}
						}
						
						if (responseTreatmentType == "Meal Bolus" || responseTreatmentType == "Carb Correction" || (responseTreatmentType == "Combo Bolus" && spikeTreatment.carbs > 0))
						{
							responseTreatment.carbs = spikeTreatment.carbs;
							responseTreatment.carbDelayTime = spikeTreatment.carbDelayTime;
						}
						
						if (responseTreatmentType == "Combo Bolus")
						{
							var parentInsulin:Number = Math.round(spikeTreatment.insulinAmount * 100) / 100;
							var totalInsulin:Number = Math.round(spikeTreatment.getTotalInsulin() * 100) / 100;
							var childrenInsulin:Number = Math.round((totalInsulin - parentInsulin) * 100) / 100;
							var parentSplit:Number = Math.round((parentInsulin * 100) / totalInsulin);
							var childrenSplit:Number = 100 - parentSplit;
							
							responseTreatment.enteredinsulin = String(totalInsulin);
							responseTreatment.duration = spikeTreatment.childTreatments.length * 5;
							responseTreatment.splitNow = String(parentSplit);
							responseTreatment.splitExt = String(childrenSplit);
							responseTreatment.relative = totalInsulin - parentInsulin;
							
							if (!isNaN(treatment.preBolus))
							{
								responseTreatment.preBolus = spikeTreatment.preBolus;
							}
						}
						
						if (responseTreatmentType == "BG Check")
						{
							responseTreatment.glucoseType = "Finger";
						}
						
						if (responseTreatmentType == "Exercise")
						{
							responseTreatment.duration = spikeTreatment.duration;
							responseTreatment.exerciseIntensity = spikeTreatment.exerciseIntensity;
						}
						
						responseTreatment.date = spikeTreatment.timestamp;
						responseTreatment.glucose = spikeTreatment.glucose;
						responseTreatment.notes = spikeTreatment.note;
						
						treatmentsList.push(responseTreatment);
					}
				}
				
				//Basals
				if ((!excludedTreatmentsExist && !includedTreatmentsExist) || (excludedTreatmentsExist && excludedTreatmentsList["Temp Basal"] == null) || (includedTreatmentsExist && includedTreatmentsList["Temp Basal"] != null && includedTreatmentsList["Temp Basal"] == true))
				{
					var spikeBasalsList:Array = TreatmentsManager.basalsList.concat();
					spikeBasalsList.sortOn(["timestamp"], Array.NUMERIC | Array.DESCENDING);
					
					for (i = 0; i < spikeBasalsList.length; i++) 
					{
						var spikeBasal:Treatment = spikeBasalsList[i] as Treatment;
						if (spikeBasal != null && spikeBasal.timestamp >= firstTreatmentTimestamp)
						{
							var responseBasalTreatment:Object = {};
							responseBasalTreatment["_id"] = spikeBasal.ID;
							responseBasalTreatment["created_at"] = nsFormatter.format(spikeBasal.timestamp).replace("000+0000", "000Z");
							responseBasalTreatment.eventType = "Temp Basal";
							responseBasalTreatment.notes = spikeBasal.note;
							responseBasalTreatment.date = spikeBasal.timestamp;
							if (spikeBasal.isBasalAbsolute || spikeBasal.type == Treatment.TYPE_MDI_BASAL) responseBasalTreatment.absolute = spikeBasal.basalAbsoluteAmount;
							if (spikeBasal.isBasalRelative) responseBasalTreatment.percent = spikeBasal.basalPercentAmount;
							if (spikeBasal.isBasalAbsolute || spikeBasal.isBasalRelative) responseBasalTreatment.duration = spikeBasal.basalDuration;
							if (spikeBasal.type == Treatment.TYPE_MDI_BASAL || CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI) == "mdi")
							{
								var usedInsulin:Insulin = ProfileManager.getInsulin(spikeBasal.insulinID);
								if (usedInsulin != null)
								{
									responseBasalTreatment.insulinName = usedInsulin.name;	
									responseBasalTreatment.insulinType = usedInsulin.type;	
									responseBasalTreatment.insulinID = usedInsulin.ID;
									responseBasalTreatment.insulinDIA = usedInsulin.dia;
								}
							}
							
							treatmentsList.push(responseBasalTreatment);
						}
					}
				}
					
				treatmentsList.sortOn(["date"], Array.NUMERIC | Array.DESCENDING);
				response = SpikeJSON.stringify(treatmentsList);
			}
			
			return responseSuccess(response);
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