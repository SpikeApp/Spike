package network.httpserver.API
{
	import flash.net.URLVariables;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectUtil;
	
	import spark.formatters.DateTimeFormatter;
	
	import database.BgReading;
	import database.BlueToothDevice;
	import database.Calibration;
	import database.Database;
	
	import network.httpserver.ActionController;
	
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
			nsFormatter.useUTC = false;
		}
		
		/**
		 * Functionality
		 */
		public function sgv(params:URLVariables):String
		{
			var response:String = "[]";
			
			try
			{
				var numReadings:int = 1;
				if (params.count != null)	
					numReadings = int(params.count);
				
				/*
				NOT IMPLEMENTED YET!!!
				var startTime:Number = 0;
				if (params["find[date][$gte]"] != null)
				{
					var startDate:String = params["find[date][$gte]"];
					if (startDate.indexOf("-") != -1)
						startTime = new Date(startDate).valueOf();
					else 
						startTime = new Date(Number(startDate)).valueOf();
				}
				var endTime:Number = new Date().valueOf();
				if (params["find[date][$lte]"] != null)
				{
					var endDate:String = params["find[date][$lte]"];
					if (endDate.indexOf("-") != -1)
						endTime = new Date(endDate).valueOf();
					else
						endTime = new Date(Number(endDate)).valueOf();
				}*/
				
				var readingsList:ArrayCollection = BgReading.latest(numReadings, BlueToothDevice.isFollower());
				var readingsCollection:Array = [];
				
				for (var i:int = 0; i < readingsList.length; i++) 
				{
					var bgReading:BgReading = readingsList.getItemAt(i) as BgReading;
					if (bgReading == null || bgReading.calculatedValue == 0)
						continue;
					
					var bgObject:Object = {};
					bgObject._id = bgReading.uniqueId;
					bgObject.unfiltered = !BlueToothDevice.isFollower() ? Math.round(bgReading.usedRaw() * 1000) : Math.round(bgReading.calculatedValue) * 1000;
					bgObject.device = !BlueToothDevice.isFollower() ? BlueToothDevice.name : "SpikeFollower";
					bgObject.sysTime = nsFormatter.format(bgReading.timestamp);
					bgObject.filtered = !BlueToothDevice.isFollower() ? Math.round(bgReading.ageAdjustedFiltered() * 1000) : Math.round(bgReading.calculatedValue) * 1000;
					bgObject.type = "sgv";
					bgObject.date = bgReading.timestamp;
					bgObject.sgv = Math.round(bgReading.calculatedValue);
					bgObject.rssi = 100;
					bgObject.noise = 1;
					bgObject.direction = bgReading.slopeName();
					bgObject.dateString = nsFormatter.format(bgReading.timestamp);
					
					readingsCollection.push(bgObject);
				}
				
				response = JSON.stringify(readingsCollection);
				
				readingsList = null;
				readingsCollection = null;
				params = null;
			} 
			catch(error:Error) {}
			
			return responseSuccess(response);
		}
		
		public function cal(params:URLVariables):String
		{
			var response:String = "[]";
			
			try
			{
				var numCalibrations:int = 1;
				if (params.count != null)	
					numCalibrations = int(params.count);
				var calibrationsCollection:Array = [];
				var calibrationsList:ArrayCollection;
				var i:int;
				
				if (!BlueToothDevice.isFollower())
				{
					calibrationsList = Calibration.latest(numCalibrations);
					
					for (i = 0; i < calibrationsList.length; i++) 
					{
						var calibration:Calibration = calibrationsList.getItemAt(i) as Calibration;
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
			catch(error:Error) {}
			
			return responseSuccess(response);
		}
		
		public function entries(params:URLVariables):String
		{
			var response:String = "";
			
			try
			{
				var numReadings:int = 1;
				if (params.count != null)	
					numReadings = int(params.count);
				
				var startTime:Number = 0;
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
				var endTime:Number = new Date().valueOf();
				if (params["find[date][$lte]"] != null)
				{
					var endDate:String = params["find[date][$lte]"];
					if (endDate.indexOf("-") != -1)
						endTime = new Date(endDate).valueOf();
					else
						endTime = new Date(Number(endDate)).valueOf();
				}
				
				var readingsList:Array = Database.getBgReadingsDataSynchronous(startTime, endTime, "timestamp, calculatedValue, calculatedValueSlope");
				
				/*
				var readingsList:ArrayCollection = BgReading.latest(numReadings, BlueToothDevice.isFollower());
				var loopLength:int = readingsList.length;
				
				for (var i:int = 0; i < loopLength; i++) 
				{
					var bgReading:BgReading = readingsList.getItemAt(i) as BgReading;
					if (bgReading == null || bgReading.calculatedValue == 0 || bgReading.timestamp < startTime || bgReading.timestamp > endTime )
						continue;
					
					response += nsFormatter.format(bgReading.timestamp) + "\t" + bgReading.timestamp + "\t" + Math.round(bgReading.calculatedValue) + "\t" + bgReading.slopeName() + "\t" + (!BlueToothDevice.isFollower() ? BlueToothDevice.name : "SpikeFollower");
					if (i < loopLength - 1)
						response += "\n";
				}
				
				readingsList = null;
				params = null;*/
			} 
			catch(error:Error) {}
			
			return responseSuccess(response);
		}
		
		public function status(params:URLVariables):String
		{
			var response:String = "<h1>STATUS OK</h1>";
			
			return responseSuccess(response);
		}
	}
}