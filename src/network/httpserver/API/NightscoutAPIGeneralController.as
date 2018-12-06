package network.httpserver.API
{
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.net.URLVariables;
	
	import spark.formatters.DateTimeFormatter;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	
	import model.Forecast;
	import model.ModelLocator;
	
	import network.httpserver.ActionController;
	
	import services.AlarmService;
	
	import stats.BasicUserStats;
	import stats.StatsManager;
	
	import treatments.TreatmentsManager;
	
	import ui.InterfaceController;
	import ui.chart.helpers.GlucoseFactory;
	
	import utils.BatteryInfo;
	import utils.BgGraphBuilder;
	import utils.GlucoseHelper;
	import utils.SpikeJSON;
	import utils.TimeSpan;
	import utils.Trace;
	
	public class NightscoutAPIGeneralController extends ActionController
	{
		/* Objects */
		private var nsFormatter:DateTimeFormatter;
		
		public function NightscoutAPIGeneralController(path:String)
		{
			super(path);
			
			nsFormatter = new DateTimeFormatter();
			nsFormatter.dateTimePattern = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
			nsFormatter.setStyle("locale", "en_US");
			nsFormatter.useUTC = true;
		}
		
		/**
		 * Functionality
		 */
		public function pebble(params:URLVariables):String
		{
			Trace.myTrace("NightscoutAPIGeneralController.as", "pebble endpoint called!");
			
			var response:String = "{}";
			
			try
			{
				//Parameters
				var numReadings:int = 1;
				if (params.count != null)	
					numReadings = int(params.count);
				
				var now:Number = new Date().valueOf();
				
				//Main response object
				var responseObject:Object = {};
				
				//Status property
				responseObject.status = [ {now: new Date().valueOf()} ];
				
				//Bgs Property
				var readingsList:Array = BgReading.latest(numReadings + 1, CGMBlueToothDevice.isFollower());
				var readingsCollection:Array = [];
				var loopLength: int;
				if (readingsList.length > numReadings)
					loopLength = readingsList.length - 1;
				else
					loopLength = readingsList.length;
				
				for (var i:int = 0; i < loopLength; i++) 
				{
					var bgReading:BgReading = readingsList[i] as BgReading;
					if (bgReading == null || bgReading.calculatedValue == 0)
						continue;
					
					var bgsObject:Object = {};
					bgsObject.sgv = BgGraphBuilder.unitizedString(bgReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
					bgsObject.trend = bgReading.getSlopeOrdinal()
					bgsObject.direction = bgReading.slopeName();
					bgsObject.datetime = bgReading.timestamp;
					bgsObject.filtered = !CGMBlueToothDevice.isFollower() ? Math.round(bgReading.ageAdjustedFiltered() * 1000) : Math.round(bgReading.calculatedValue) * 1000;
					bgsObject.unfiltered = !CGMBlueToothDevice.isFollower() ? Math.round(bgReading.usedRaw() * 1000) : Math.round(bgReading.calculatedValue) * 1000;
					bgsObject.noise = bgReading.noiseValue();
					if (i == 0)
					{
						bgsObject.bgdelta = Number(BgGraphBuilder.unitizedDeltaString(false, false));
						bgsObject.battery = String(BatteryInfo.getBatteryLevel());
						bgsObject.iob = String(TreatmentsManager.getTotalIOB(now).iob);
						bgsObject.cob = TreatmentsManager.getTotalCOB(now, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps").cob;
						bgsObject.bwp = "0";
						bgsObject.bwpo = 0;
					}
					
					readingsCollection.push(bgsObject);
				}
				
				responseObject.bgs = readingsCollection;
				
				//Cals Property
				var latestCalibration:Calibration = Calibration.last();
				var calsArray:Array
				
				if (latestCalibration != null)
				{
					responseObject.cals = 
						[
							{
								slope: latestCalibration.checkIn ? latestCalibration.slope : 1000/latestCalibration.slope,
								intercept: latestCalibration.checkIn ? latestCalibration.firstIntercept : latestCalibration.intercept * -1000 / latestCalibration.slope,
								scale: latestCalibration.checkIn ? latestCalibration.firstScale : 1
							}	
						];
				}
				else
				{
					responseObject.cals = 
						[
							{
								slope: 0,
								intercept: 0,
								scale: 1
							}	
						];
				}
				
				//Final Response
				response = SpikeJSON.stringify(responseObject);
			} 
			catch(error:Error) 
			{
				Trace.myTrace("NightscoutAPIGeneralController.as", "Error performing pebble endpoint call. Error: " + error.message);
			}
			
			return responseSuccess(response);
		}
		
		public function sgv(params:URLVariables):String
		{
			Trace.myTrace("NightscoutAPIGeneralController.as", "sgv endpoint called!");
			
			var response:String = "{}";
			
			try
			{
				var numReadings:int = 1;
				if (params.count != null)	
					numReadings = int(params.count);
				
				var readingsList:Array = BgReading.latest(numReadings + 1, CGMBlueToothDevice.isFollower());
				var readingsCollection:Array = [];
				var loopLength: int;
				if (readingsList.length > numReadings)
					loopLength = readingsList.length - 1;
				else
					loopLength = readingsList.length;
				
				for (var i:int = 0; i < loopLength; i++) 
				{
					var bgReading:BgReading = readingsList[i] as BgReading;
					if (bgReading == null || bgReading.calculatedValue == 0)
						continue;
					
					var delta:Number;
					try
					{
						var previousReading:BgReading = readingsList[i + 1]; 
						delta = Math.round(bgReading.calculatedValue - previousReading.calculatedValue);
					} 
					catch(error:Error) 
					{
						delta = 0;
					}
					
					var bgObject:Object = {};
					if (i == 0)
					{
						bgObject.units_hint = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? "mgdl" : "mmol";
						var now:Number = new Date().valueOf();
						var currentIOB:Number = TreatmentsManager.getTotalIOB(now).iob;
						var currentCOB:Number = TreatmentsManager.getTotalCOB(now, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps").cob;
						if (currentIOB > 0)
							bgObject.IOB = currentIOB;
						if (currentCOB > 0)
							bgObject.COB = currentCOB;
					}
					bgObject.date = bgReading.timestamp;
					bgObject.dateString = nsFormatter.format(bgReading.timestamp);
					bgObject.sysTime = nsFormatter.format(bgReading.timestamp);
					bgObject.sgv = Math.round(bgReading.calculatedValue);
					bgObject.delta = delta;
					bgObject.direction = bgReading.slopeName();
					bgObject.noise = 1;
					
					readingsCollection.push(bgObject);
				}
				
				response = SpikeJSON.stringify(readingsCollection);
				
				readingsList = null;
				readingsCollection = null;
				params = null;
			} 
			catch(error:Error) 
			{
				Trace.myTrace("NightscoutAPIGeneralController.as", "Error performing sgv endpoint call. Error: " + error.message);
			}
			
			return responseSuccess(response);
		}
		
		public function spikewatch(params:URLVariables):String
		{
			Trace.myTrace("NightscoutAPIGeneralController.as", "spikewatch endpoint called!");
			
			var response:String = "[]";
			
			try
			{
				var now:Number = new Date().valueOf();
				
				var numReadings:int = 1;
				if (params.count != null)	
					numReadings = int(params.count);
				
				var startTime:Number;
				if (params["startoffset"] != null)
					startTime = now - Number(params["startoffset"]);
				else
					startTime = now - TimeSpan.TIME_24_HOURS_6_MINUTES;
				
				var lightMode:Boolean = false;
				if (params["lightMode"] != null && params["lightMode"] == "true")
					lightMode = true;
				
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
								var readingObject:Object = {}
								readingObject.date = bgReading.timestamp;
								readingObject.sgv = Math.round(bgReading.calculatedValue);
								readingObject.direction = bgReading.slopeName();
								if (itemParsed == 0)
								{
									//Watch settings
									readingObject.unit = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? "mgdl" : "mmol";
									readingObject.urgent_high_threshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK));
									readingObject.high_threshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
									readingObject.low_threshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
									readingObject.urgent_low_threshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK));
									readingObject.urgent_high_color = "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_HIGH_COLOR)).toString(16).toUpperCase();
									readingObject.high_color = "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_HIGH_COLOR)).toString(16).toUpperCase();
									readingObject.in_range_color = "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_IN_RANGE_COLOR)).toString(16).toUpperCase();
									readingObject.low_color = "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_LOW_COLOR)).toString(16).toUpperCase();
									readingObject.urgent_low_color = "#" + uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_LOW_COLOR)).toString(16).toUpperCase();
									
									//Stats / Predictions / Velocity
									readingObject.status_one = "COB: " + GlucoseFactory.formatCOB(TreatmentsManager.getTotalCOB(now, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps").cob) + " | IOB: " + GlucoseFactory.formatIOB(TreatmentsManager.getTotalIOB(now).iob);
									if (!lightMode)
									{
										//Stats
										var userStats:BasicUserStats = StatsManager.getBasicUserStats();
										readingObject.status_two = "L: " + userStats.percentageLowRounded + "% | " + "R: " + userStats.percentageInRangeRounded + "% | " + "H: " + userStats.percentageHighRounded + "%";
										readingObject.status_three = "AVG: " + userStats.averageGlucose + GlucoseHelper.getGlucoseUnit() + " | " + "A1C: " + userStats.a1c + (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_A1C_IFCC_ON) != "true" ? "%" : "m");
										
										//Predictions
										var predictionsLengthInMinutes:Number = Forecast.getCurrentPredictionsDuration();
										if (!isNaN(predictionsLengthInMinutes))
										{
											var currentPrediction:Number = Forecast.getLastPredictiveBG(predictionsLengthInMinutes);
											if (!isNaN(currentPrediction))
											{
												readingObject.predictions_duration = String(predictionsLengthInMinutes);
												readingObject.predictions_outcome = readingObject.unit == "mgdl" ? String(Math.round(currentPrediction)) : String(Math.round(BgReading.mgdlToMmol(currentPrediction * 10)) / 10);
											}
											else
											{
												readingObject.predictions_duration = String(predictionsLengthInMinutes);
												readingObject.predictions_outcome = "N/A";
											}
										}
										else
										{
											readingObject.predictions_duration = "";
											readingObject.predictions_outcome = "N/A";
										}
										
										//Velocity
										var glucoseVelocity:Number = GlucoseFactory.getGlucoseVelocity();
										if (!isNaN(glucoseVelocity))
										{
											readingObject.glucose_velocity = String(glucoseVelocity);
										}
									}
								}
								readingsCollection.push(readingObject);
								itemParsed++;
							}
						}
						cntr--;
					}
				}
				
				response = SpikeJSON.stringify(readingsCollection);
				
				readingsCollection = null;
				params = null;
			} 
			catch(error:Error) 
			{
				Trace.myTrace("NightscoutAPI1Controller.as", "Error performing spikewatch endpoint call. Error: " + error.message);
			}
			
			return responseSuccess(response);
		}
		
		public function spikeondemand(params:URLVariables):String
		{
			if (CGMBlueToothDevice.isMiaoMiao() && CGMBlueToothDevice.known() && InterfaceController.peripheralConnected)
				SpikeANE.sendStartReadingCommmandToMiaoMia();
			
			return responseSuccess("OK");
		}
		
		public function spikesnooze(params:URLVariables):String
		{
			var snoozeTime:Number = 60;
			if (params.snoozeTime != null)
				snoozeTime = Number(params.snoozeTime);
			
			AlarmService.snoozeVeryHighAlert(0, snoozeTime);
			AlarmService.snoozeHighAlert(0, snoozeTime);
			AlarmService.snoozeLowAlert(0, snoozeTime);
			AlarmService.snoozeVeyLowAlert(0, snoozeTime);
			AlarmService.snoozeMissedReadingAlert(0, snoozeTime);
			AlarmService.snoozePhoneMutedAlert(0, snoozeTime);
			AlarmService.snoozeFastRiseAlert(0, snoozeTime);
			AlarmService.snoozeFastDropAlert(0, snoozeTime);
			
			return responseSuccess("Snoozed for " + snoozeTime + " minutes");
		}
		
		public function spikeunsnooze(params:URLVariables):String
		{
			if (AlarmService.veryHighAlertSnoozed())
				AlarmService.resetVeryHighAlert();
			
			if (AlarmService.highAlertSnoozed())
				AlarmService.resetHighAlert();
			
			if (AlarmService.lowAlertSnoozed())
				AlarmService.resetLowAlert();
			
			if (AlarmService.veryLowAlertSnoozed())
				AlarmService.resetVeryLowAlert();
			
			if (AlarmService.missedReadingAlertSnoozed())
				AlarmService.resetMissedReadingAlert();
			
			if (AlarmService.phoneMutedAlertSnoozed())
				AlarmService.resetPhoneMutedAlert();
			
			if (AlarmService.fastRiseAlertSnoozed())
				AlarmService.resetFastRiseAlert();
			
			if (AlarmService.fastDropAlertSnoozed())
				AlarmService.resetFastDropAlert();
			
			return responseSuccess("OK");
		}
	}
}