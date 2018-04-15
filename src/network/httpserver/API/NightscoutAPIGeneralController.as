package network.httpserver.API
{
	import flash.net.URLVariables;
	
	import spark.formatters.DateTimeFormatter;
	
	import database.BgReading;
	import database.BlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	
	import network.httpserver.ActionController;
	
	import treatments.TreatmentsManager;
	
	import utils.BgGraphBuilder;
	import utils.SpikeJSON;
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
						bgObject.units_hint = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? "mgdl" : "mmol";
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
	}
}