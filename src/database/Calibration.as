package database
{
	import mx.collections.ArrayCollection;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	
	import utils.Trace;
	import utils.UniqueId;
	
	public class Calibration extends SuperDatabaseClass
	{
		private var _timestamp:Number;
		
		/**
		 * ms sinds 1 jan 1970 
		 */
		public function get timestamp():Number
		{
			return _timestamp;
		}
		
		private var _sensorAgeAtTimeOfEstimation:Number;
		
		/**
		 * in ms 
		 */
		public function get sensorAgeAtTimeOfEstimation():Number
		{
			return _sensorAgeAtTimeOfEstimation;
		}
		
		private var _sensor:Sensor;
		
		public function get sensor():Sensor
		{
			return _sensor;
		}
		
		private var _bg:Number;
		
		public function get bg():Number
		{
			return _bg;
		}
		
		private var _rawValue:Number;
		
		public function get rawValue():Number
		{
			return _rawValue;
		}
		
		private var _adjustedRawValue:Number;
		
		public function get adjustedRawValue():Number
		{
			return _adjustedRawValue;
		}
		
		private var _sensorConfidence:Number;
		
		public function set sensorConfidence(value:Number):void
		{
			_sensorConfidence = value;
			resetLastModifiedTimeStamp();
		}
		
		
		public function get sensorConfidence():Number
		{
			return _sensorConfidence;
		}
		
		private var _slopeConfidence:Number;
		
		public function set slopeConfidence(value:Number):void
		{
			_slopeConfidence = value;
			resetLastModifiedTimeStamp();
		}
		
		
		public function get slopeConfidence():Number
		{
			return _slopeConfidence;
		}
		
		private var _rawTimestamp:Number;
		
		public function get rawTimestamp():Number
		{
			return _rawTimestamp;
		}
		
		private var _slope:Number;
		
		public function set slope(value:Number):void
		{
			_slope = value;
			resetLastModifiedTimeStamp();
		}
		
		
		public function get slope():Number
		{
			return _slope;
		}
		
		private var _intercept:Number;
		
		public function set intercept(value:Number):void
		{
			_intercept = value;
			resetLastModifiedTimeStamp();
		}
		
		
		public function get intercept():Number
		{
			return _intercept;
		}
		
		private var _distanceFromEstimate:Number;
		
		public function get distanceFromEstimate():Number
		{
			return _distanceFromEstimate;
		}
		
		private var _estimateRawAtTimeOfCalibration:Number;
		
		public function get estimateRawAtTimeOfCalibration():Number
		{
			return _estimateRawAtTimeOfCalibration;
		}
		
		private var _estimateBgAtTimeOfCalibration:Number;
		
		public function get estimateBgAtTimeOfCalibration():Number
		{
			return _estimateBgAtTimeOfCalibration;
		}
		
		private var _possibleBad:Boolean;
		
		public function set possibleBad(value:Boolean):void
		{
			_possibleBad = value;
			resetLastModifiedTimeStamp();
		}
		
		
		public function get possibleBad():Boolean
		{
			return _possibleBad;
		}
		
		private var _checkIn:Boolean;
		
		public function get checkIn():Boolean
		{
			return _checkIn;
		}
		
		private var _firstDecay:Number;
		
		public function get firstDecay():Number
		{
			return _firstDecay;
		}
		
		private var _secondDecay:Number;
		
		public function get secondDecay():Number
		{
			return _secondDecay;
		}
		
		private var _firstSlope:Number;
		
		public function get firstSlope():Number
		{
			return _firstSlope;
		}
		
		private var _secondSlope:Number;
		
		public function get secondSlope():Number
		{
			return _secondSlope;
		}
		
		private var _firstIntercept:Number;
		
		public function get firstIntercept():Number
		{
			return _firstIntercept;
		}
		
		private var _secondIntercept:Number;
		
		public function get secondIntercept():Number
		{
			return _secondIntercept;
		}
		
		private var _firstScale:Number;
		
		public function get firstScale():Number
		{
			return _firstScale;
		}
		
		private var _secondScale:Number;
		
		public function get secondScale():Number
		{
			return _secondScale;
		}
		
		
		
		/**
		 * if calibrationid = null, then a new value will be assigned by the constructor<br>
		 * if lastmodifiedtimestamp = Number.NaN, then current time will be assigned by the constructor 
		 */
		public function Calibration(
			timestamp:Number,
			sensorAgeAtTimeOfEstimation:Number,
			sensor:Sensor,
			bg:Number,
			rawValue:Number,
			adjustedRawValue:Number,
			sensorConfidence:Number,
			slopeConfidence:Number,
			rawTimestamp:Number,
			slope:Number,
			intercept:Number,
			distanceFromEstimate:Number,
			estimateRawAtTimeOfCalibration:Number,
			estimateBgAtTimeOfCalibration:Number,
			possibleBad:Boolean,
			checkIn:Boolean,
			firstDecay:Number,
			secondDecay:Number,
			firstSlope:Number,
			secondSlope:Number,
			firstIntercept:Number,
			secondIntercept:Number,
			firstScale:Number,
			secondScale:Number,
			lastmodifiedtimestamp:Number,
			calibrationid:String
		)
		{
			super(calibrationid, lastmodifiedtimestamp);
			_timestamp = timestamp;
			_sensorAgeAtTimeOfEstimation = sensorAgeAtTimeOfEstimation;
			_sensor = sensor;
			_bg = bg;
			_rawValue = rawValue;
			_adjustedRawValue = adjustedRawValue;
			_sensorConfidence = sensorConfidence;
			_slopeConfidence = slopeConfidence;
			_rawTimestamp = rawTimestamp;
			_slope = slope,
				_intercept = intercept;
			_distanceFromEstimate = distanceFromEstimate;
			_estimateRawAtTimeOfCalibration = estimateRawAtTimeOfCalibration;
			_estimateBgAtTimeOfCalibration = estimateBgAtTimeOfCalibration;
			_possibleBad = possibleBad;
			_checkIn = checkIn;
			_firstDecay = firstDecay;
			_secondDecay = secondDecay;
			_firstSlope = firstSlope;
			_secondSlope = secondSlope;
			_firstIntercept = firstIntercept;
			_secondIntercept = secondIntercept;
			_firstScale = firstScale;
			_secondScale = secondScale;
		}
		
		/**
		 * returns all calibrations for the ative sensor<br>
		 * if no sensor active then the return value is an empty array (size = 0)<br> 
		 * the calibrations will be order in descending order by timestamp
		 */
		public static function allForSensor():Array { //SPIKE
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR) == "0")
				return new Array();//an empty arraycollection
			
			var returnValue:Array = Database.getCalibrationForSensorId(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR));
			for (var i:int = 0; i < returnValue.length; i++) {
				var calibration:Calibration = returnValue[i] as Calibration;
				if (calibration.slopeConfidence == 0 || calibration.sensorConfidence == 0) {
					returnValue.removeAt(i);
					i--;
				}
				i++;
				if (i == returnValue.length)
					break;
			}
			
			returnValue.sortOn(["timestamp"], Array.NUMERIC | Array.DESCENDING);
			
			return returnValue;
		}
		
		public static function initialCalibration(bg1:Number, timestampCalibration1:Number, timestampCalibration2:Number, numAdjustedReadings:int = 5):void {
			myTrace("start initialCalibration");
			var bg2:Number = bg1;
			//TODO take unit from settings
			var unit:String = "mgdl";
			if (unit != "mgdl") {
				bg1 = bg1 * BgReading.MMOLL_TO_MGDL;
				bg2 = bg2 * BgReading.MMOLL_TO_MGDL;
			}

			var sensorId:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR);
			var sensor:Sensor = Database.getSensor(sensorId);
			var bgReadings:Array = BgReading.latestBySize(2);
			var bgReading1:BgReading = bgReadings[0] as BgReading;
			var bgReading2:BgReading = bgReadings[1] as BgReading;
			
			bgReading1.calculatedValue = bg1;
			bgReading1.calibrationFlag = true;
			
			bgReading2.calculatedValue = bg2;
			bgReading2.calibrationFlag = true;
			
			bgReading1.findNewCurve();
			bgReading1.findNewRawCurve();
			bgReading2.findNewCurve();
			bgReading2.findNewRawCurve();
			
			//create and save low calibration
			var calibration1:Calibration = new Calibration(
				timestampCalibration1,//timestamp
				(new Date()).valueOf() - sensor.startedAt,//sensor age at time of estimation
				sensor,
				bg1,//bg
				bgReading1.rawData,//rawvalue
				bgReading1.ageAdjustedRawValue,//adjustedrawvalue
				((-0.0018 * bg1 * bg1) + (0.6657 * bg1) + 36.7505) / 100,//sensorconfidence,
				0.5,//slopeconfidence,
				bgReading1.timestamp,//rawtimestamp
				1,//slope
				bg1,//intercept
				0,//distancefromestimate,
				bgReading1.ageAdjustedRawValue,//estimaterawattimeofcalibration
				0,//estimatebgattimeofcalibration - default value, it seems never assigned a value in the android project
				false,//possible bad defualt value
				false,//checkin
				new Number(0),//firstdecay
				new Number(0),//seconddecay
				new Number(0),//firstslope
				new Number(0),//secondslope
				new Number(0),//firstintercept
				new Number(0),//secondintercept
				new Number(0),//firstscale
				new Number(0),//secondscale
				(new Date()).valueOf(),
				utils.UniqueId.createEventId()
			);
			calculateWLS(calibration1).saveToDatabaseSynchronous();
			
			//create and save high calibration
			var calibration2:Calibration = new Calibration(
				timestampCalibration2,//timestamp
				(new Date()).valueOf() - sensor.startedAt,//sensor age at time of estimation
				sensor,
				bg2,//bg
				bgReading2.rawData,//rawvalue
				bgReading2.ageAdjustedRawValue,//adjustedrawvalue
				((-0.0018 * bg2 * bg2) + (0.6657 * bg2) + 36.7505) / 100,//sensorconfidence,
				0.5,//slopeconfidence
				bgReading2.timestamp,//rawtimestamp
				1,//slope
				bg2,//intercept
				0,//distancefromestimate,
				bgReading2.ageAdjustedRawValue,//estimaterawattimeofcalibration
				0,//estimatebgattimeofcalibration - default value, it seems never assigned a value in the android project
				false,//possible bad defualt value
				false,//checkin
				new Number(0),//firstdecay
				new Number(0),//seconddecay
				new Number(0),//firstslope
				new Number(0),//secondslope
				new Number(0),//firstintercept
				new Number(0),//secondintercept
				new Number(0),//firstscale
				new Number(0),//secondscale
				(new Date()).valueOf(),
				utils.UniqueId.createEventId()
			);
			calculateWLS(calibration2).saveToDatabaseSynchronous();
			
			bgReading1.calibration = calibration1;
			bgReading2.calibration = calibration2;
			
			bgReading1.updateInDatabaseSynchronous();
			bgReading2.updateInDatabaseSynchronous();
			
			//myTrace("Calibration.intialCalibration before calculate_w_l_s");
			//myTrace("Calibration.intialCalibration after calculate_w_l_s");
			//myTrace("before adjustbgreadings bgReading1 = " + bgReading1.print("   "));
			//myTrace("before adjustbgreadings bgReading2 = " + bgReading2.print("   "));
			var latest3Calibrations:Array = [];
			latest3Calibrations.push(calibration1);//the first is the latest, this one comes first, so it will be sorted from large to small
			latest3Calibrations.push(calibration2);
			
			adjustRecentBgReadings(numAdjustedReadings, latest3Calibrations);
			//myTrace("after adjustbgreadings");
			//myTrace("End of initialCalibration bgReading1 = " + bgReading1.print("   "));
			//myTrace("End of initialCalibration bgReading2 = " + bgReading2.print("   "));
			//myTrace("End of initialCalibration calibration1 = " + calibration1.print("   "));
			//myTrace("End of initialCalibration calibration2 = " + calibration2.print("   "));
		}
		
		/**
		 * no database insert of the new calibration !
		 */
		public static function create(bg:Number, timeStamp:Number = Number.NaN):Calibration {
			var calibrationTimeStamp:Number = isNaN(timeStamp) ? (new Date()).valueOf() : timeStamp;

			myTrace("in create, with timestamp  = " + timeStamp);
			myTrace("in create, with timestamp  = " + (new Date(calibrationTimeStamp)).toString());
			
			var calibration:Calibration;
			var unit:String = "mgdl";
			if (unit != "mgdl") {
				bg = bg * BgReading.MMOLL_TO_MGDL;
			}
			
			var sensor:Sensor = Sensor.getActiveSensor();
			if (sensor != null) {
				var bgReading:BgReading = (BgReading.latest(1))[0]  as BgReading;
				if (bgReading != null) {
					var estimatedRawBg:Number = BgReading.estimatedRawBg((new Date()).valueOf());
					calibration = (new Calibration(
						calibrationTimeStamp,//timestamp
						calibrationTimeStamp - sensor.startedAt,//sensorageattimeofestimation
						sensor,//sensor
						bg,//bg
						bgReading.rawData,//rawvalue
						bgReading.ageAdjustedRawValue,//ajustedrawvalue
						Math.max(((-0.0018 * bg * bg) + (0.6657 * bg) + 36.7505) / 100, 0),//sensorconfidence
						Math.min(Math.max(((4 - Math.abs((bgReading.calculatedValueSlope) * 60000))/4), 0), 1),//slopeconfidence,
						bgReading.timestamp,//rawtimestamp
						new Number(0),//slope
						new Number(0),//intercept
						Math.abs(bg - bgReading.calculatedValue),//distance from estimate
						Math.abs(estimatedRawBg - bgReading.ageAdjustedRawValue) > 20 ? bgReading.ageAdjustedRawValue : estimatedRawBg,//estimaterawattimeofcalibration
						new Number(0),//estimatebgattimeofcalibration
						false,//possiblebad
						false,//checkin
						new Number(0),//firstdecay
						new Number(0),//seconddecay
						new Number(0),//firstslope
						new Number(0),//secondslope
						new Number(0),//firstintercept
						new Number(0),//secondintercept
						new Number(0),//firstscale
						new Number(0),//second scale
						(new Date()).valueOf(),//lastmodifiedtimestamp
						utils.UniqueId.createEventId()//eventid
					));
					calculateWLS(calibration);
					bgReading.calibration = calibration;
					bgReading.calibrationFlag = true;
					
					//just doing an update of the latest bgreading, which may not be aligned with the Android version
					//not doing a database update of the bgreading, because adjustRecentBgReadings is already doing that update
					var latest3Calibrations:Array = latest(2);
					latest3Calibrations.unshift(calibration)
					adjustRecentBgReadings(1, latest3Calibrations);
					
					//calling requestCalibrationIfRangeTooNarrow in the CalibrationService which handles also the save to database
				}
			}
			return calibration;
		}
		
		/**
		 * Same as in Android version<br>
		 * If calibration input parameter == null, then method will get the last calibration from the database<br>
		 * returns the calibration to allow chaining which is either the original calibration in the parameter or the one from the database<br>
		 * without database update<br> 
		 */
		private static function calculateWLS(calibration:Calibration):Calibration {
			var sParams:SlopeParameters = CGMBlueToothDevice.isTypeLimitter() ? new LiParameters(): new DexParameters();
			if (Sensor.getActiveSensor()) {
				myTrace("calculatewls : sensor is active");
				var l:Number = 0;
				var m:Number = 0;
				var n:Number = 0;
				var p:Number = 0;
				var q:Number = 0;
				var w:Number;
				var calibrations:ArrayCollection = allForSensorInLastXDays(4);
				
				//check if this item is already in that list, if not add it
				var calibrationItem:Calibration;
				var itemfound:Boolean = false;
				var dataSortFieldForReturnValue:SortField;
				var dataSortForBGReadings:Sort;
				var calibcntr:int;
				if (calibration != null) {
					for (calibcntr = 0; calibcntr< calibrations.length; calibcntr++) {
						if ((calibrations.getItemAt(calibcntr) as Calibration).uniqueId == calibration.uniqueId) {
							itemfound = true;
							break;
						}
					}
				}
				
				if (!itemfound && calibration != null) {
					calibrations.addItemAt(calibration, 0);
					dataSortFieldForReturnValue = new SortField();
					dataSortFieldForReturnValue.name = "timestamp";
					dataSortFieldForReturnValue.numeric = true;
					dataSortFieldForReturnValue.descending = true;//ie from large to small
					dataSortForBGReadings = new Sort();
					dataSortForBGReadings.fields=[dataSortFieldForReturnValue];
					calibrations.sort = dataSortForBGReadings;
					calibrations.refresh();
				}
				
				if (calibration == null) {
					calibration = Calibration.last();
				}
				
				//myTrace("calibrations length = " + calibrations.length);
				if (calibrations.length <= 1) {
					//myTrace("calculatewls : length <= 1");
					calibration.slope = 1;
					//myTrace("intercept checkpoint 1 = " + calibration.intercept);
					calibration.intercept = calibration.bg - (calibration.rawValue * calibration.slope);
					//myTrace("intercept checkpoint 2 = " + calibration.intercept);
				} else {
					//myTrace("calculatewls : length > 1");
					for (calibcntr = 0; calibcntr< calibrations.length; calibcntr++) {
						calibrationItem = calibrations.getItemAt(calibcntr) as Calibration;
						w = calibrationItem.calculateWeight(calibrations);
						l += (w);
						m += (w * calibrationItem.estimateRawAtTimeOfCalibration);
						n += (w * calibrationItem.estimateRawAtTimeOfCalibration * calibrationItem.estimateRawAtTimeOfCalibration);
						p += (w * calibrationItem.bg);
						q += (w * calibrationItem.estimateRawAtTimeOfCalibration * calibrationItem.bg);
					}
					//myTrace("calculatewls 1 : w = " + w + ", l = " + l + ", m = " + m + ", n = " + n + ", p = " + p + ", q = " + q);
					//myTrace("calculatewls : lastcalibration has id = " + calibration.uniqueId);
					w = (calibration.calculateWeight(calibrations) * (calibrations.length * 0.14));
					l += (w);
					m += (w * calibration.estimateRawAtTimeOfCalibration);
					n += (w * calibration.estimateRawAtTimeOfCalibration * calibration.estimateRawAtTimeOfCalibration);
					p += (w * calibration.bg);
					q += (w * calibration.estimateRawAtTimeOfCalibration * calibration.bg);
					//myTrace("calculatewls 2 : w = " + w + ", l = " + l + ", m = " + m + ", n = " + n + ", p = " + p + ", q = " + q);
					var d:Number = (l * n) - (m * m);
					//myTrace("d = " + d);
					//myTrace("intercept checkpoint 3 = " + calibration.intercept);
					calibration.intercept = ((n * p) - (m * q)) / d;
					//myTrace("intercept checkpoint 4 = " + calibration.intercept);
					calibration.slope = ((l * q) - (m * p)) / d;
					//myTrace("1 intercept = "+  calibration.intercept + ", slope = " + calibration.slope);
					
					//getting the latest 3 calibrations from database
					//then check if calibration is not null and of not if it's already in that list, if not add it, resort and get the latest 3
					var latest3Calibrations:Array = Calibration.latest(3);
					if (calibration != null) {
						for (calibcntr = 0; calibcntr < latest3Calibrations.length; calibcntr++) {
							if ((latest3Calibrations[calibcntr] as Calibration).uniqueId == calibration.uniqueId) {
								itemfound = true;
								break;
							}
						}
						if (!itemfound) {
							latest3Calibrations.unshift(calibration);
							latest3Calibrations.sortOn(["timestamp"], Array.NUMERIC | Array.DESCENDING);
							
							while (latest3Calibrations.length > 3)
								latest3Calibrations.removeAt(latest3Calibrations.length - 1);
						}
					}
					
					if ((calibrations.length == 2 && calibration.slope < sParams.LOW_SLOPE_1) || (calibration.slope < sParams.LOW_SLOPE_2)) { 
						calibration.slope = calibration.slopeOOBHandler(0, latest3Calibrations);
						if(calibrations.length > 2) { calibration.possibleBad = true; }
						//myTrace("intercept checkpoint 5 = " + calibration.intercept);
						calibration.intercept = calibration.bg - (calibration.estimateRawAtTimeOfCalibration * calibration.slope);
						//myTrace("intercept checkpoint 6 = " + calibration.intercept);
						//myTrace("2 intercept = "+  calibration.intercept + ", slope = " + calibration.slope);
					}
					if ((calibrations.length == 2 && calibration.slope > sParams.HIGH_SLOPE_1) || (calibration.slope > sParams.HIGH_SLOPE_2)) {
						calibration.slope = calibration.slopeOOBHandler(1, latest3Calibrations);
						if(calibrations.length > 2) { calibration.possibleBad = true; }
						//myTrace("intercept checkpoint 7 = " + calibration.intercept);
						calibration.intercept = calibration.bg - (calibration.estimateRawAtTimeOfCalibration * calibration.slope);
						//myTrace("intercept checkpoint 8 = " + calibration.intercept);
						//myTrace("3 intercept = "+  calibration.intercept + ", slope = " + calibration.slope);
					}
				}
			}
			return calibration;
		}
		
		/**
		 * array with latest number of calibrations that match the active sensorid<br>
		 * descending timestamp, large to small<br>
		 * if there's none then empty array is returned 
		 */
		public static function latest(number:int):Array {
			var sensorId:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR);
			if (sensorId == "0")
				return new Array();
			return Database.getLatestCalibrations(number,sensorId);
		}
		
		/**
		 * calibrations should have maximum 3 calibrations, the latest,  from large to small ie descending
		 */
		private function slopeOOBHandler(status:int, calibrations:Array):Number {
			var sParams:SlopeParameters = CGMBlueToothDevice.isTypeLimitter() ? new LiParameters(): new DexParameters();
			
			var thisCalibration:Calibration = calibrations[0] as Calibration;
			if(status == 0) {
				//myTrace("in slopeOOBHandler, with status = 0");
				//myTrace("calibrations.size = " + calibrations.length);
				if (calibrations.length == 3) {
					if ((Math.abs(thisCalibration.bg - thisCalibration.estimateBgAtTimeOfCalibration) < 30) && ((calibrations[1] as Calibration).possibleBad == true)) {
						//myTrace("returnvalue for size 3, first branch = " + (calibrations.getItemAt(1) as Calibration).slope);
						return (calibrations[1] as Calibration).slope;
					} else {
						//myTrace("returnvalue for size 3, second branch = " + Math.max(((-0.048) * (thisCalibration.sensorAgeAtTimeOfEstimation / (60000 * 60 * 24))) + 1.1, sParams.DEFAULT_LOW_SLOPE_LOW));
						return Math.max(((-0.048) * (thisCalibration.sensorAgeAtTimeOfEstimation / (60000 * 60 * 24))) + 1.1, sParams.DEFAULT_LOW_SLOPE_LOW);
					}
				} else if (calibrations.length == 2) {
					//myTrace("thisCalibration.sensor_age_at_time_of_estimation = " + thisCalibration.sensorAgeAtTimeOfEstimation);
					//myTrace("(thisCalibration.sensor_age_at_time_of_estimation / (60000 * 60 * 24) = " + (thisCalibration.sensorAgeAtTimeOfEstimation / (60000 * 60 * 24)));
					//myTrace("sParams.getDefaultLowSlopeHigh() = " + sParams.DEFAULT_LOW_SLOPE_HIGH);
					//myTrace("return value for size 2 = " + Math.max(((-0.048) * (thisCalibration.sensorAgeAtTimeOfEstimation / (60000 * 60 * 24))) + 1.1, sParams.DEFAULT_LOW_SLOPE_HIGH));
					return Math.max(((-0.048) * (thisCalibration.sensorAgeAtTimeOfEstimation / (60000 * 60 * 24))) + 1.1, sParams.DEFAULT_LOW_SLOPE_HIGH);
				}
				return sParams.DEFAULT_SLOPE;
			} else {
				if (calibrations.length == 3) {
					if ((Math.abs(thisCalibration.bg - thisCalibration.estimateBgAtTimeOfCalibration) < 30) && ((calibrations[1] as Calibration).possibleBad)) {
						return (calibrations[1] as Calibration).slope;
					} else {
						return sParams.DEFAULT_HIGH_SLOPE_HIGH;
					}
				} else if (calibrations.length == 2) {
					return sParams.DEFAUL_HIGH_SLOPE_LOW;
				}
			}
			return sParams.DEFAULT_SLOPE;
		}
		
		/**
		 * gets the last calibration for the current active sensor<br>
		 * returns null if there's none
		 */
		public static function last():Calibration {
			var sensorId:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR);
			return Database.getLastOrFirstCalibration(sensorId, false);
		}
		
		/**
		 * gets the first calibration for the current active sensor<br>
		 * returns null if there's none
		 */
		public static function first():Calibration {
			var sensorId:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR);
			return Database.getLastOrFirstCalibration(sensorId, true);
		}
		
		/**
		 * Returns calibrations in database for which <br>
		 * - sensorConfidence != 0<br>
		 * - slopeConfidence != 0 <br>
		 * - sensorId == active sensor<br>
		 * - timestamp within last days days<br>
		 * same as  allForSensorInLastFiveDays in android version, but taking days as a parameter<br>
		 * returnvalue will never be null but can have size 0 if there's no calibration matching<br>
		 * order by timestamp, large to small (descending)
		 */
		public static function allForSensorInLastXDays(days:int):ArrayCollection {
			var sensorId:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR);
			if (sensorId == "0")
				return new ArrayCollection();
			return Database.getCalibrationForSensorInLastXDays(days, sensorId);
		}
		
		/**
		 * for calculation of first and last :<br>
		 * - the method will combine all calibrations found in the database matching the sensor id and add the calibratoins in the supplied arraycollection calibrations<br>
		 * From this list, the first and the last will be used.<br>
		 * <br>
		 * In this list, all calibrations are checked, ie the ones already stored in the database, and those that are not yet stored also.<br>
		 * Prerequisites<br>
		 * - calibrations in the supplied parameter do have a timestamp != 0<br>
		 * - calibrations in the supplied timestamp must have the active sensorid<br>
		 * - there's at least two calibrations when combining the ones in the database and the ones in the supplied parameter<br>
		 * - calibrations need to be sorted from large to small (descending)<br>
		 * - calibrations will not be modified
		 */
		private function calculateWeight(calibrations:ArrayCollection):Number {
			//get the first calibration
			var firstCalibration:Calibration = Calibration.first();
			if (firstCalibration == null) {
				firstCalibration = calibrations.getItemAt(calibrations.length - 1) as Calibration;
			} else {
				if (calibrations != null) {
					if (calibrations.length > 0) {
						if (firstCalibration.timestamp > (calibrations.getItemAt(calibrations.length - 1) as Calibration).timestamp) {
							firstCalibration = calibrations.getItemAt(calibrations.length - 1) as Calibration;
						}
					}
				}
			}
			
			//get the last calibration
			var lastCalibration:Calibration = Calibration.last();
			if (lastCalibration == null) {
				lastCalibration = calibrations.getItemAt(0) as Calibration;
			} else {
				if (calibrations != null) {
					if (calibrations.length > 0) {
						if (lastCalibration.timestamp < (calibrations.getItemAt(0) as Calibration).timestamp) {
							lastCalibration = calibrations.getItemAt(0) as Calibration;
						}
					}
				}
			}
			
			//myTrace("id of firstcalibration = " + firstCalibration.uniqueId);
			//myTrace("id of last calibration = " + lastCalibration.uniqueId);
			var firstTimeStarted:Number = firstCalibration.sensorAgeAtTimeOfEstimation;
			var lastTimeStarted:Number = lastCalibration.sensorAgeAtTimeOfEstimation;
			//myTrace("calculateWeight: firstTimeStarted = " + firstTimeStarted);
			//myTrace("calculateWeight: lastTimeStarted = " + lastTimeStarted);
			//myTrace("sensor_age_at_time_of_estimation = " + sensorAgeAtTimeOfEstimation);//calibration creation date - sensor started at, gewoonlijk 2 uur + 10 minuten = 7800000
			//myTrace("sensor_age_at_time_of_estimation - firstTimeStarted = " + (sensorAgeAtTimeOfEstimation - firstTimeStarted));//
			//myTrace("lastTimeStarted - firstTimeStarted" + (lastTimeStarted - firstTimeStarted));
			//myTrace("division = " + ((sensorAgeAtTimeOfEstimation - firstTimeStarted) / (lastTimeStarted - firstTimeStarted)));
			var timePercentage:Number = Math.min(((sensorAgeAtTimeOfEstimation - firstTimeStarted) / (lastTimeStarted - firstTimeStarted)) / (0.85), 1);
			timePercentage = (timePercentage + 0.01);
			//myTrace("calculateWeight: timePercentage = " + timePercentage);
			//myTrace("returnvalue = " + Math.max((((((slopeConfidence + sensorConfidence) * (timePercentage))) / 2) * 100), 1));
			return Math.max((((((slopeConfidence + sensorConfidence) * (timePercentage))) / 2) * 100), 1);
		}
		
		/**
		 * with database update of the adjusted bgreadings<br>
		 * calibrations should be the latest, maximum 3, descending by timestamp, ie large to small
		 */
		public static function adjustRecentBgReadings(adjustCount:int, calibrations:Array):void {
			var bgReadings:Array= BgReading.latestBySize(adjustCount);
			var latestCalibration:Calibration;
			var bgcntr:int;
			var bgReading:BgReading;
			var newYvalue:Number;
			var oldYValue:Number;
			if (calibrations.length == 3) {
				var denom:int = bgReadings.length;
				latestCalibration = calibrations[0] as Calibration;
				var i:int = 0;
				for each (bgReading in bgReadings) {
					oldYValue = bgReading.calculatedValue;
					newYvalue = (bgReading.ageAdjustedRawValue * latestCalibration.slope) + latestCalibration.intercept;
					bgReading.calculatedValue = ((newYvalue * (denom - i)) + (oldYValue * ( i ))) / denom;
					bgReading.updateInDatabaseSynchronous();
					i += 1;
				}
			} else if (calibrations.length == 2) {
				latestCalibration = calibrations[0] as Calibration;
				for each (bgReading in bgReadings) {
					newYvalue = (bgReading.ageAdjustedRawValue * latestCalibration.slope) + latestCalibration.intercept;
					bgReading.calculatedValue = newYvalue;
					BgReading.updateCalculatedValue(bgReading);
					bgReading.updateInDatabaseSynchronous();
				}
			}
			(bgReadings[0] as BgReading).findNewRawCurve();
			(bgReadings[0] as BgReading).findNewCurve();
			(bgReadings[0] as BgReading).updateInDatabaseSynchronous();		
		}
		
		/**
		 * same as minRecent and maxRecent in the android project but combined in one single method
		 */
		public static function recent(max:Boolean):Number {
			var sensor:Sensor = Sensor.getActiveSensor();
			var calibrations:ArrayCollection = Database.getCalibrationForSensorInLastXDays(4, sensor.uniqueId);
			if (calibrations.length == 0) {
				if (max)
					return 120;
				else
					return 100;
			}
			var dataSortField:SortField = new SortField();
			dataSortField.name = "bg";
			dataSortField.numeric = true;
			if (max)
				dataSortField.descending = true;//ie from large to small
			else
				dataSortField.descending = false;
			var dataSort:Sort = new Sort();
			dataSort.fields=[dataSortField];
			calibrations.sort = dataSort;
			calibrations.refresh();
			
			return (calibrations.getItemAt(0) as Calibration).bg;
		}
		
		/**
		 * no database update of the calibration ! 
		 */
		public function rawValueOverride(rawValue:Number):Calibration {
			_estimateRawAtTimeOfCalibration = rawValue;
			resetLastModifiedTimeStamp();
			calculateWLS(null).updateInDatabaseSynchronous();
			return this;
		}
		
		public function saveToDatabaseSynchronous():Calibration {
			Database.insertCalibrationSynchronous(this);
			return this;
		}
		
		public function updateInDatabaseSynchronous():Calibration {
			Database.updateCalibrationSynchronous(this);
			return this;
		}
		
		public function deleteInDatabaseSynchronous():Calibration {
			Database.deleteCalibrationSynchronous(this);
			return this;
		}
		
		public static function clearLastCalibration():void {
			var lastCalibration:Calibration = Calibration.last();
			if (lastCalibration == null)
				return;
			lastCalibration.sensorConfidence = 0;
			lastCalibration.slopeConfidence = 0;
			lastCalibration.updateInDatabaseSynchronous();
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("Calibration.as", log);
		}
		
		public function print(indentation:String):String {
			var r:String = "calibration = ";
			r += "\n" + indentation + "uniqueid = " + uniqueId;
			r += "\n" + indentation + "adjustedRawValue = " + adjustedRawValue;
			r += "\n" + indentation + "bg = " + bg;
			r += "\n" + indentation + "checkIn = " + checkIn;
			r += "\n" + indentation + "distanceFromEstimate = " + distanceFromEstimate;
			r += "\n" + indentation + "estimateBgAtTimeOfCalibration = " + estimateBgAtTimeOfCalibration;
			r += "\n" + indentation + "estimateRawAtTimeOfCalibration = " + estimateRawAtTimeOfCalibration;
			r += "\n" + indentation + "firstDecay = " + firstDecay;
			r += "\n" + indentation + "firstIntercept = " + firstIntercept;
			r += "\n" + indentation + "firstScale = " + firstScale;
			r += "\n" + indentation + "firstSlope = " + firstSlope;
			r += "\n" + indentation + "intercept = " + intercept;
			r += "\n" + indentation + "possibleBad = " + possibleBad;
			r += "\n" + indentation + "rawTimestamp = " + rawTimestamp;
			r += "\n" + indentation + "rawValue = " + rawValue;
			r += "\n" + indentation + "secondDecay = " + secondDecay;
			r += "\n" + indentation + "secondIntercept = " + secondIntercept;
			r += "\n" + indentation + "secondScale = " + secondScale;
			r += "\n" + indentation + "secondSlope = " + secondSlope;
			r += "\n" + indentation + "sensor = " + (sensor == null ? "null":sensor.print("         "));
			r += "\n" + indentation + "sensorAgeAtTimeOfEstimation = " + sensorAgeAtTimeOfEstimation;
			r += "\n" + indentation + "sensorConfidence = " + sensorConfidence;
			r += "\n" + indentation + "slope = " + slope;
			r += "\n" + indentation + "slopeConfidence = " + slopeConfidence;
			r += "\n" + indentation + "timestamp = " + timestamp;
			return r;
		}
		
	}
}

internal class SlopeParameters {
	protected var _LOW_SLOPE_1:Number;
	
	public function set LOW_SLOPE_1(value:Number):void
	{
		_LOW_SLOPE_1 = value;
	}
	
	
	public function get LOW_SLOPE_1():Number
	{
		return _LOW_SLOPE_1;
	}
	
	protected var _LOW_SLOPE_2:Number;
	
	public function set LOW_SLOPE_2(value:Number):void
	{
		_LOW_SLOPE_2 = value;
	}
	
	
	public function get LOW_SLOPE_2():Number
	{
		return _LOW_SLOPE_2;
	}
	
	protected var _HIGH_SLOPE_1:Number;
	
	public function set HIGH_SLOPE_1(value:Number):void
	{
		_HIGH_SLOPE_1 = value;
	}
	
	
	public function get HIGH_SLOPE_1():Number
	{
		return _HIGH_SLOPE_1;
	}
	
	protected var _HIGH_SLOPE_2:Number;
	
	public function set HIGH_SLOPE_2(value:Number):void
	{
		_HIGH_SLOPE_2 = value;
	}
	
	
	public function get HIGH_SLOPE_2():Number
	{
		return _HIGH_SLOPE_2;
	}
	
	protected var _DEFAULT_LOW_SLOPE_LOW:Number;
	
	public function set DEFAULT_LOW_SLOPE_LOW(value:Number):void
	{
		_DEFAULT_LOW_SLOPE_LOW = value;
	}
	
	
	public function get DEFAULT_LOW_SLOPE_LOW():Number
	{
		return _DEFAULT_LOW_SLOPE_LOW;
	}
	
	protected var _DEFAULT_LOW_SLOPE_HIGH:Number;
	
	public function set DEFAULT_LOW_SLOPE_HIGH(value:Number):void
	{
		_DEFAULT_LOW_SLOPE_HIGH = value;
	}
	
	
	public function get DEFAULT_LOW_SLOPE_HIGH():Number
	{
		return _DEFAULT_LOW_SLOPE_HIGH;
	}
	
	protected var _DEFAULT_SLOPE:int;
	
	public function set DEFAULT_SLOPE(value:int):void
	{
		_DEFAULT_SLOPE = value;
	}
	
	
	public function get DEFAULT_SLOPE():int
	{
		return _DEFAULT_SLOPE;
	}
	
	protected var _DEFAULT_HIGH_SLOPE_HIGH:Number;
	
	public function set DEFAULT_HIGH_SLOPE_HIGH(value:Number):void
	{
		_DEFAULT_HIGH_SLOPE_HIGH = value;
	}
	
	
	public function get DEFAULT_HIGH_SLOPE_HIGH():Number
	{
		return _DEFAULT_HIGH_SLOPE_HIGH;
	}
	
	protected var _DEFAUL_HIGH_SLOPE_LOW:Number;
	
	public function set DEFAUL_HIGH_SLOPE_LOW(value:Number):void
	{
		_DEFAUL_HIGH_SLOPE_LOW = value;
	}
	
	
	public function get DEFAUL_HIGH_SLOPE_LOW():Number
	{
		return _DEFAUL_HIGH_SLOPE_LOW;
	}
	
}

internal class DexParameters extends SlopeParameters {
	function DexParameters() {
		LOW_SLOPE_1 = 0.95;
		LOW_SLOPE_2 = 0.85;
		HIGH_SLOPE_1 = 1.3;
		HIGH_SLOPE_2 = 1.4;
		DEFAULT_LOW_SLOPE_LOW = 1.08;
		DEFAULT_LOW_SLOPE_HIGH = 1.15;
		DEFAULT_SLOPE = 1;
		DEFAULT_HIGH_SLOPE_HIGH = 1.3;
		DEFAUL_HIGH_SLOPE_LOW = 1.2;
	}
}

/* THIS IS FOR LIMITTER */
internal class LiParameters extends SlopeParameters {
	function LiParameters(){
		LOW_SLOPE_1 = 1;
		LOW_SLOPE_2 = 1;
		HIGH_SLOPE_1 = 1;
		HIGH_SLOPE_2 = 1;
		DEFAULT_LOW_SLOPE_LOW = 1;
		DEFAULT_LOW_SLOPE_HIGH = 1;
		DEFAULT_SLOPE = 1;
		DEFAULT_HIGH_SLOPE_HIGH = 1;
		DEFAUL_HIGH_SLOPE_LOW = 1;
		
		/*
		LOW_SLOPE_1 = 0.55;
		LOW_SLOPE_2 = 0.50;
		HIGH_SLOPE_1 = 1.5;
		HIGH_SLOPE_2 = 1.6;
		DEFAULT_LOW_SLOPE_LOW = 0.55;
		DEFAULT_LOW_SLOPE_HIGH = 0.50;
		DEFAULT_SLOPE = 1;
		DEFAULT_HIGH_SLOPE_HIGH = 1.5;
		DEFAUL_HIGH_SLOPE_LOW = 1.4;	
*/
	}
}

