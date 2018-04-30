package network.httpserver.API
{
	import flash.net.URLVariables;
	
	import spark.formatters.DateTimeFormatter;
	
	import database.BgReading;
	import database.BlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	
	import model.ModelLocator;
	
	import network.httpserver.ActionController;
	
	import treatments.TreatmentsManager;
	
	import ui.chart.GlucoseFactory;
	
	import utils.BgGraphBuilder;
	import utils.GlucoseHelper;
	import utils.SpikeJSON;
	import utils.Trace;
	
	public class NightscoutAPIGeneralController extends ActionController
	{
		/* Constants */
		private static const TIME_24_HOURS_6_MINUTES:int = (24 * 60 * 60 * 1000) + 6000;
		private static const TIME_24H:int = 24 * 60 * 60 * 1000;
		private static const TIME_30SEC:int = 30 * 1000;
		
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
				//Main response object
				var responseObject:Object = {};
				
				//Status property
				responseObject.status = [ {now: new Date().valueOf()} ];
				
				//Bgs Propery
				var latestReading:BgReading;
				if (!BlueToothDevice.isFollower())
					latestReading = BgReading.lastNoSensor();
				else
					latestReading = BgReading.lastWithCalculatedValue();
				
				var now:Number = new Date().valueOf();
				
				responseObject.bgs =
				[ 
					{
						sgv: BgGraphBuilder.unitizedString(latestReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true"), 
						trend: latestReading.getSlopeOrdinal(), 
						direction: latestReading.slopeName(), 
						datetime: latestReading.timestamp,
						filtered: !BlueToothDevice.isFollower() ? Math.round(latestReading.ageAdjustedFiltered() * 1000) : Math.round(latestReading.calculatedValue) * 1000,
						unfiltered: !BlueToothDevice.isFollower() ? Math.round(latestReading.usedRaw() * 1000) : Math.round(latestReading.calculatedValue) * 1000,
						noise: latestReading.noiseValue(),
						bgdelta: Number(BgGraphBuilder.unitizedDeltaString(false, false)),
						iob: String(TreatmentsManager.getTotalIOB(now)),
						cob: TreatmentsManager.getTotalCOB(now)
					} 
				];
				
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
				//response = JSON.stringify(responseObject);
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
				
				var readingsList:Array = BgReading.latest(numReadings + 1, BlueToothDevice.isFollower());
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
						var currentIOB:Number = TreatmentsManager.getTotalIOB(now);
						var currentCOB:Number = TreatmentsManager.getTotalCOB(now);
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
				
				//response = JSON.stringify(readingsCollection);
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
					startTime = now - TIME_24_HOURS_6_MINUTES;
				
				var lightMode:Boolean = false;
				if (params["lightMode"] != null && params["lightMode"] == "true")
					lightMode = true;
				
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
									
									//Stats
									readingObject.status_one = "IOB: " + GlucoseFactory.formatIOB(TreatmentsManager.getTotalIOB(now)) + " | COB: " + GlucoseFactory.formatCOB(TreatmentsManager.getTotalCOB(now));
									if (!lightMode)
									{
										var userStats:Object = getUserStats();
										readingObject.status_two = "L: " + userStats.lowPercentage + " | " + "R: " + userStats.inRangePercentage + " | " + "H: " + userStats.highPercentage;
										readingObject.status_three = "AVG: " + userStats.averageGlucose + " | " + "A1C: " + userStats.a1c;
									}
								}
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
				Trace.myTrace("NightscoutAPI1Controller.as", "Error performing spikewatch endpoint call. Error: " + error.message);
			}
			
			return responseSuccess(response);
		}
		
		private function getUserStats():Object
		{
			/**
			 * VARIABLES
			 */
			var high:int = 0;
			var percentageHigh:Number;
			var percentageHighRounded:Number;
			var inRange:int = 0;
			var percentageInRange:Number;
			var percentageInRangeRounded:Number
			var low:int = 0;
			var percentageLow:Number;
			var percentageLowRounded:Number;
			var dataLength:int = ModelLocator.bgReadings.length;
			var realReadingsNumber:int = 0;
			var totalGlucose:Number = 0;
			var dummyModeActive:Boolean = false;
			var lowTreshold:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));;
			var highTreshold:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
			
			/**
			 * GLUCOSE DISTRIBUTION CALCULATION
			 */
			var glucoseValue:Number;
			var i:int;
			var nowTimestamp:Number = (new Date()).valueOf();
			for (i = 0; i < dataLength; i++) 
			{
				var bgReading:BgReading = ModelLocator.bgReadings[i];
				
				if (nowTimestamp - bgReading.timestamp > TIME_24H - TIME_30SEC || (bgReading.calibration == null && bgReading.calculatedValue == 0))
					continue;
				
				glucoseValue = Number(bgReading.calculatedValue);
				if(glucoseValue >= highTreshold)
					high += 1;
				else if (glucoseValue > lowTreshold && glucoseValue < highTreshold)
					inRange += 1;
				else if (glucoseValue <= lowTreshold)
					low += 1;
				
				totalGlucose += glucoseValue;
				
				realReadingsNumber++;
			}
			
			//If there's no good readings then activate dummy mode.
			if (realReadingsNumber == 0)
				dummyModeActive = true;
			
			//Glucose Distribution Percentages
			percentageHigh = (high * 100) / realReadingsNumber;
			percentageHighRounded = (( percentageHigh * 10 + 0.5)  >> 0) / 10;
			
			percentageInRange = (inRange * 100) / realReadingsNumber;
			percentageInRangeRounded = (( percentageInRange * 10 + 0.5)  >> 0) / 10;
			
			var preLow:Number = Math.round((low * 100) / realReadingsNumber) * 10 / 10;
			if ( preLow != 0 && !isNaN(preLow))
			{
				percentageLow = 100 - percentageInRange - percentageHigh;
				percentageLowRounded = Math.round ((100 - percentageInRangeRounded - percentageHighRounded) * 10) / 10;
			}
			else
			{
				percentageLow = 0;
				percentageLowRounded = 0;
			}
			
			//Calculate Average Glucose & A1C
			var averageGlucose:Number = (( (totalGlucose / realReadingsNumber) * 10 + 0.5)  >> 0) / 10;
			var averageGlucoseValue:Number = averageGlucose;
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
				averageGlucoseValue = Math.round(((BgReading.mgdlToMmol((averageGlucoseValue))) * 10)) / 10;
			
			var averageGlucoseValueOutput:String
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
				averageGlucoseValueOutput = String(averageGlucoseValue);
			else
			{
				if ( averageGlucoseValue % 1 == 0)
					averageGlucoseValueOutput = String(averageGlucoseValue) + ".0";
				else
					averageGlucoseValueOutput = String(averageGlucoseValue);
			}
			
			var A1C:Number;
			if (!dummyModeActive)
				A1C = (( ((46.7 + averageGlucose) / 28.7) * 10 + 0.5)  >> 0) / 10;
			else
				A1C = 0;
			
			var status:Object = {};
			status.lowPercentage = percentageLowRounded + "%";
			status.inRangePercentage = percentageInRangeRounded + "%";
			status.highPercentage = percentageHighRounded + "%";
			status.averageGlucose = !dummyModeActive ? averageGlucoseValueOutput + GlucoseHelper.getGlucoseUnit() : "N/A";
			status.a1c = !dummyModeActive ? A1C + "%" : "N/A";
			
			return status;
		}
	}
}