package database
{
	import model.ModelLocator;
	
	import utils.BgGraphBuilder;
	import utils.DateTimeUtilities;
	import utils.Trace;
	
	public class BgReading extends SuperDatabaseClass
	{
		public static const AGE_ADJUSTMENT_TIME:Number = 86400000 * 1.9;
		public static const  AGE_ADJUSTMENT_FACTOR:Number = .45;
		private static var predictBG:Boolean;
		public static const BESTOFFSET:Number = (60000 * 0); // Assume readings are about x minutes off from actual!
		public static const MMOLL_TO_MGDL:Number = 18.0182;
		public static const MGDL_TO_MMOLL:Number = 1 / MMOLL_TO_MGDL;
		
		
		private var _sensor:Sensor;
		public function get sensor():Sensor
		{
			return _sensor;
		}
		
		private var _calibration:Calibration;

		public function set calibration(value:Calibration):void
		{
			_calibration = value;
			resetLastModifiedTimeStamp();
		}

		public function get calibration():Calibration
		{
			return _calibration;
		}
		
		public var _timestamp:Number;//db
		
		/**
		 * ms sinds 1 jan 1970 
		 */
		public function get timestamp():Number
		{
			return _timestamp;
		}
		
		public var _rawData:Number;

		public function set rawData(value:Number):void
		{
			_rawData = value;
			resetLastModifiedTimeStamp();
		}
		
		public function get rawData():Number
		{
			return _rawData;
		}
		
		private var _filteredData:Number;

		public function set filteredData(value:Number):void
		{
			_filteredData = value;
			resetLastModifiedTimeStamp();
		}

		
		public function get filteredData():Number
		{
			return _filteredData;
		}
		
		private var _ageAdjustedRawValue:Number;

		public function set ageAdjustedRawValue(value:Number):void
		{
			_ageAdjustedRawValue = value;
			resetLastModifiedTimeStamp();
		}

		
		public function get ageAdjustedRawValue():Number
		{
			return _ageAdjustedRawValue;
		}
		
		private var _calibrationFlag:Boolean;

		public function set calibrationFlag(value:Boolean):void
		{
			_calibrationFlag = value;
			resetLastModifiedTimeStamp();
		}

		
		public function get calibrationFlag():Boolean
		{
			return _calibrationFlag;
		}
		
		public var _calculatedValue:Number;

		public function set calculatedValue(value:Number):void
		{
			_calculatedValue = value;
			resetLastModifiedTimeStamp();
		}

		
		public function get calculatedValue():Number
		{
			return _calculatedValue;
		}
		
		private var _filteredCalculatedValue:Number;

		public function set filteredCalculatedValue(value:Number):void
		{
			_filteredCalculatedValue = value;
			resetLastModifiedTimeStamp();
		}

		
		public function get filteredCalculatedValue():Number
		{
			return _filteredCalculatedValue;
		}
		
		private var _calculatedValueSlope:Number;

		public function set calculatedValueSlope(value:Number):void
		{
			_calculatedValueSlope = value;
			resetLastModifiedTimeStamp();
		}

		
		public function get calculatedValueSlope():Number
		{
			return _calculatedValueSlope;
		}
		
		private var _a:Number;
		
		public function get a():Number
		{
			return _a;
		}
		
		private var _b:Number;
		
		public function get b():Number
		{
			return _b;
		}
		
		private var _c:Number;
		
		public function get c():Number
		{
			return _c;
		}
		
		private var _ra:Number;
		
		public function get ra():Number
		{
			return _ra;
		}
		
		private var _rb:Number;
		
		public function get rb():Number
		{
			return _rb;
		}
		
		private var _rc:Number;
		
		public function get rc():Number
		{
			return _rc;
		}
		
		private var _rawCalculated:Number;

		public function set rawCalculated(value:Number):void
		{
			_rawCalculated = value;
			resetLastModifiedTimeStamp();
		}

		
		public function get rawCalculated():Number
		{
			return _rawCalculated;
		}
		
		private var _hideSlope:Boolean;

		public function set hideSlope(value:Boolean):void
		{
			_hideSlope = value;
			resetLastModifiedTimeStamp();
		}

		
		public function get hideSlope():Boolean
		{
			return _hideSlope;
		}
		
		private var _noise:String;
		
		public function get noise():String
		{
			return _noise;
		}
		
		
		/**
		 * if bgreadingid = null, then a new value will be assigned by the constructor<br>
		 * if lastmodifiedtimestamp = Number.NaN, then current time will be assigned by the constructor 
		 */
		public function BgReading(
			timestamp:Number,
			sensor:Sensor,
			calibration:Calibration,
			rawData:Number,
			filteredData:Number,
			ageAdjustedRawValue:Number,
			calibrationFlag:Boolean,
			calculatedValue:Number,
			filteredCalculatedValue:Number,
			calculatedValueSlope:Number,
			a:Number,
			b:Number,
			c:Number,
			ra:Number,
			rb:Number,
			rc:Number,
			rawCalculated:Number,
			hideSlope:Boolean,
			noise:String,
			lastmodifiedtimestamp:Number,
			bgreadingid:String
		)
		{
			super(bgreadingid, lastmodifiedtimestamp);
			_timestamp = timestamp;
			_sensor = sensor;
			_calibration = calibration;
			_rawData = rawData;
			_filteredData = filteredData;
			_ageAdjustedRawValue = ageAdjustedRawValue;
			_calibrationFlag = calibrationFlag;
			_calculatedValue = calculatedValue;
			_filteredCalculatedValue = filteredCalculatedValue;
			_calculatedValueSlope = calculatedValueSlope;
			_a = a;
			_b = b;
			_c = c;
			_ra = ra;
			_rb = rb;
			_rc = rc;
			_rawCalculated = rawCalculated;
			_hideSlope = hideSlope;
			_noise = noise;
		}
		
		public static function mgdlToMmol(mgdl:Number):Number {
			return mgdl * MGDL_TO_MMOLL;
		}
		
		public static function mmolToMgdl(mmoll:Number):Number {
			return mmoll * MMOLL_TO_MGDL;
		}
		
		public static function activeSlope():Number {
			var bgReading:BgReading = lastNoSensor();
			if (bgReading != null) {
				var slope:Number = (2 * bgReading.a * ((new Date()).valueOf() + BESTOFFSET)) + bgReading.b;
				return slope;
			}
			return 0;
		}
		
		/**
		 * returnvalue is an array of two objects, the first beging a Number, the second a Boolean 
		 */
		public static function calculateSlope(current:BgReading, last:BgReading):Array {
			if (current.timestamp == last.timestamp || 
				current.timestamp - last.timestamp > BgGraphBuilder.MAX_SLOPE_MINUTES * 60 * 1000) {
				return new Array(new Number(0), new Boolean(true));
			}
			var slope:Number =  (last.calculatedValue - current.calculatedValue) / (last.timestamp - current.timestamp);
			return new Array(slope,new Boolean(false));
		}
		
		/**
		 * array will contain number of bgreadings with<br>
		 * - if ignoreSensorId = false, then return only readings for which sensor = current sensor<br>
		 * - calculatedValule != 0<br>
		 * - rawData != 0<br>
		 * - latest 'number' that match these requirements<br>
		 * - descending timestamp, order
		 * <br>
		 * could also be less than number, ie returnvalue could be array of size 0 
		 */
		public static function latest(number:int, ignoreSensorId:Boolean = false):Array {
			var returnValue:Array = [];
			var currentSensorId:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR);
			if (currentSensorId != "0" || ignoreSensorId) {
				var cntr:int = ModelLocator.bgReadings.length - 1;
				var itemsAdded:int = 0;
				while (cntr > -1 && itemsAdded < number) {
					var bgReading:BgReading = ModelLocator.bgReadings[cntr];
					if (bgReading.sensor != null || ignoreSensorId) {
						if ((ignoreSensorId || bgReading.sensor.uniqueId == currentSensorId) && bgReading._calculatedValue != 0 && bgReading._rawData != 0) {
							returnValue.push(bgReading);
							itemsAdded++;
						}
					}
					cntr--;
				}
			}
			
			return returnValue;
		}
		
		/**
		 * array will contain number of bgreadings with<br>
		 * - sensor = current sensor<br>
		 * - rawData != 0<br>
		 * - latest 'number' that match these requirements<br>
		 * - descending timestamp, order
		 * <br>
		 * could also be less than number, ie returnvalue could be array of size 0 
		 */
		public static function latestBySize(number:int):Array {
			
			var returnValue:Array = [];
			var currentSensorId:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR);
			if (currentSensorId != "0") {
				var cntr:int = ModelLocator.bgReadings.length - 1;
				var itemsAdded:int = 0;
				while (cntr > -1 && itemsAdded < number) {
					var bgReading:BgReading = ModelLocator.bgReadings[cntr] as BgReading;
					if (bgReading.sensor != null) {
						if (bgReading.sensor.uniqueId == currentSensorId && bgReading.rawData != 0) {
							returnValue.push(bgReading);
							itemsAdded++;
						}
					}
					cntr--;
				}
			}
			
			return returnValue;
		}
		
		/**
		 * array will contain bgreadings with<br>
		 * - rawData != 0<br>
		 * - calculatedValue != 0<br>
		 * - descending timestamp, order
		 * <br>
		 * returnvalue could be array of size 0 
		 */
		public static function last30Minutes():Array {
			var returnValue:Array = [];
			if (ModelLocator.bgReadings.length == 0)
				return returnValue;
			
			var timestamp:Number = (new Date()).valueOf() - (60000 * 30);
			var cntr:int = ModelLocator.bgReadings.length - 1;
			var itemsAdded:int = 0;
			var bgReading:BgReading = ModelLocator.bgReadings[cntr] as BgReading;
			while (cntr > -1 && bgReading.timestamp > timestamp) {
				if (bgReading.calculatedValue != 0 && bgReading.rawData != 0) {
					returnValue.push(bgReading);
					itemsAdded++;
				}
				cntr--;
				if (cntr > -1)
					bgReading = ModelLocator.bgReadings[cntr] as BgReading;
			}
			
			return returnValue;
		}
		
		/**
		 * - rawData != 0<br>
		 * - calculatedValule != 0<br>
		 * - latest<br>
		 * - null if there's none i guess
		 */
		public static function lastNoSensor():BgReading {
			var returnValue:BgReading;
			var cntr:int = ModelLocator.bgReadings.length - 1;
			while (cntr > -1) {
				var bgReading:BgReading = ModelLocator.bgReadings[cntr] as BgReading;
				if (bgReading.rawData != 0 && bgReading.calculatedValue != 0) {
					returnValue = bgReading;
					break;
				}
				cntr--;
			}
			return returnValue;
		}
		
		/**
		 * - calculatedValule != 0<br>
		 * - latest<br>
		 * - null if there's none
		 */
		public static function lastWithCalculatedValue():BgReading {
			var returnValue:BgReading;
			var cntr:int = ModelLocator.bgReadings.length - 1;
			while (cntr > -1) {
				var bgReading:BgReading = ModelLocator.bgReadings[cntr] as BgReading;
				if (bgReading.calculatedValue != 0) {
					returnValue = bgReading;
					break;
				}
				cntr--;
			}
			return returnValue;
		}
		
		/**
		 * no database update ! 
		 */
		public function findNewCurve():void {
			var last3:Array = latest(3);
			var log:String = "";
			var y3:Number;
			var x3:Number;
			var y2:Number;
			var x2:Number;
			var y1:Number;
			var x1:Number;
			var latest:BgReading;
			var second_latest:BgReading;
			var third_latest:BgReading;
			if (last3.length == 3) {
				latest = last3[0] as BgReading;
				second_latest = last3[1] as BgReading;
				third_latest = last3[2] as BgReading;
				y3 = latest.calculatedValue;
				x3 = latest.timestamp;
				y2 = second_latest.calculatedValue;
				x2 = second_latest.timestamp;
				y1 = third_latest.calculatedValue;
				x1 = third_latest.timestamp;
				
				_a = y1/((x1-x2)*(x1-x3))+y2/((x2-x1)*(x2-x3))+y3/((x3-x1)*(x3-x2));
				_b = (-y1*(x2+x3)/((x1-x2)*(x1-x3))-y2*(x1+x3)/((x2-x1)*(x2-x3))-y3*(x1+x2)/((x3-x1)*(x3-x2)));
				_c = (y1*x2*x3/((x1-x2)*(x1-x3))+y2*x1*x3/((x2-x1)*(x2-x3))+y3*x1*x2/((x3-x1)*(x3-x2)));
				
				resetLastModifiedTimeStamp();
			} else if (last3.length == 2) {
				latest = last3[0] as BgReading;
				second_latest = last3[1] as BgReading;
				
				y2 = latest.calculatedValue;
				x2 = latest.timestamp;
				y1 = second_latest.calculatedValue;
				x1 = second_latest.timestamp;
				
				if (y1 == y2) {
					_b = 0;
				} else {
					_b = (y2 - y1)/(x2 - x1);
				}
				_a = 0;
				_c = -1 * ((latest.b * x1) - y1);
				
				resetLastModifiedTimeStamp();
			} else {
				_a = 0;
				_b = 0;
				_c = calculatedValue;
				
				resetLastModifiedTimeStamp();
			}
		}
		
		/**
		 * no database update ! 
		 */
		public function findNewRawCurve():void {
			var last3:Array = BgReading.latest(3);
			var y3:Number;
			var x3:Number;
			var y2:Number;
			var x2:Number;
			var y1:Number;
			var x1:Number;
			var latest:BgReading 
			var second_latest:BgReading; 
			var third_latest:BgReading;
			if (last3.length == 3) {
				latest = last3[0] as BgReading;
				second_latest = last3[1] as BgReading;
				third_latest = last3[2] as BgReading;
				
				y3 = latest.ageAdjustedRawValue;
				x3 = latest.timestamp;
				y2 = second_latest.ageAdjustedRawValue;
				x2 = second_latest.timestamp;
				y1 = third_latest.ageAdjustedRawValue;
				x1 = third_latest.timestamp;
				
				_ra = y1/((x1-x2)*(x1-x3))+y2/((x2-x1)*(x2-x3))+y3/((x3-x1)*(x3-x2));
				_rb = (-y1*(x2+x3)/((x1-x2)*(x1-x3))-y2*(x1+x3)/((x2-x1)*(x2-x3))-y3*(x1+x2)/((x3-x1)*(x3-x2)));
				_rc = (y1*x2*x3/((x1-x2)*(x1-x3))+y2*x1*x3/((x2-x1)*(x2-x3))+y3*x1*x2/((x3-x1)*(x3-x2)));
				
				resetLastModifiedTimeStamp();
				
			} else if (last3.length == 2) {
				latest = last3[0] as BgReading;
				second_latest = last3[1] as BgReading;
				
				y2 = latest.ageAdjustedRawValue;
				x2 = latest.timestamp;
				y1 = second_latest.ageAdjustedRawValue;
				x1 = second_latest.timestamp;
				
				if(y1 == y2) {
					_rb = 0;
				} else {
					_rb = (y2 - y1)/(x2 - x1);
				}
				_ra = 0;
				_rc = -1 * ((latest.rb * x1) - y1);
				
				resetLastModifiedTimeStamp();
			} else {
				latest = BgReading.lastNoSensor();
				_ra = 0;
				_rb = 0;
				if (latest != null) {
					_rc = latest.ageAdjustedRawValue;
				} else {
					_rc = 105;
				}
				
				resetLastModifiedTimeStamp();
			}
		}
		
		/**
		 * no database update ! 
		 */
		public static function updateCalculatedValue(bgReading:BgReading):void {
			if (bgReading.calculatedValue < 10) {
				bgReading.calculatedValue = 38;
				bgReading.hideSlope = true;
			} else {
				bgReading.calculatedValue = Math.min(400, Math.max(39, bgReading.calculatedValue));
			}
		}
		
		public static function estimatedRawBg(timestamp:Number):Number {
			timestamp = timestamp + BESTOFFSET;
			var estimate:Number;
			var latestReadings:Array = BgReading.latest(1);
			if (latestReadings.length == 0) {
				estimate = 160;
			} else {
				var latest:BgReading = latestReadings[0] as BgReading;
				estimate = (latest.ra * timestamp * timestamp) + (latest.rb * timestamp) + latest.rc;
			}
			return estimate;
		}
		
		public function timeSinceSensorStarted():Number {
			return timestamp - sensor.startedAt; 
		}
		
		/**
		 * stores in ModelLocator but not in database ! 
		 */
		public static function create(rawData:Number, filteredData:Number, timeStamp:Number = Number.NaN):BgReading {
			var timestamp:Number = timeStamp;
			if (isNaN(timeStamp)) {
				timestamp = (new Date()).valueOf();
			}
			
			myTrace("start of create bgreading with rawdata = " + rawData + ", and filtereddata = " + filteredData + ", timestamp = " + (new Date(timestamp)).toString());
			var sensor:Sensor = Sensor.getActiveSensor();
			var calibration:Calibration = Calibration.last();

			var bgReading:BgReading = (new BgReading(
				timestamp,
				sensor,//sensor
				calibration,//calibration
				rawData / 1000,//rawdata
				filteredData / 1000,//filtereddata
				new Number(0),//ageAdjustedRawValue
				false,//calibration flag
				new Number(0),//calculatedvalue
				new Number(0),//filteredCalculatedValue
				new Number(0),//calculatedValeSlopoe
				new Number(0),//a
				new Number(0),//b
				new Number(0),//c
				new Number(0),//ra
				new Number(0),//rb
				new Number(0),//Rc
				new Number(0),//rawcalculated
				false,//hideslope
				null,//noise
				Number.NaN,//lastmodifiedtimestamp wil be assigned by constructor
				null//bgreading id will be assigned by constructor
			)).calculateAgeAdjustedRawValue();
			
			ModelLocator.addBGReading(bgReading);

			if (calibration == null) {
				//No calibration yet
				
			} else {
				if(calibration.checkIn) {
					var firstAdjSlope:Number = calibration.firstSlope + (calibration.firstDecay * (Math.ceil((new Date()).valueOf() - calibration.timestamp)/(1000 * 60 * 10)));
					var calSlope:Number = (calibration.firstScale / firstAdjSlope)*1000;
					var calIntercept:Number = ((calibration.firstScale * calibration.firstIntercept) / firstAdjSlope)*-1;
					bgReading.calculatedValue = (((calSlope * rawData) + calIntercept) - 5);
					bgReading.filteredCalculatedValue = (((calSlope * bgReading.ageAdjustedRawValue) + calIntercept) -5);
					
				} else {
					var lastBgReading:BgReading = null;
					var lastBgReadings:Array = BgReading.latest(1);
					if (lastBgReadings.length > 0) {
						lastBgReading = (BgReading.latest(1))[0] as BgReading;
						if (lastBgReading != null && lastBgReading.calibration != null) {
							if (lastBgReading.calibrationFlag == true && ((lastBgReading.timestamp + (60000 * 20)) > timestamp) && ((lastBgReading.calibration.timestamp + (60000 * 20)) > timestamp)) {
								lastBgReading.calibration
									.rawValueOverride(BgReading.weightedAverageRaw(lastBgReading.timestamp, timestamp, lastBgReading.calibration.timestamp, lastBgReading.ageAdjustedRawValue, bgReading.ageAdjustedRawValue))
									.updateInDatabaseSynchronous();
							}
						}
					}
					
					bgReading.calculatedValue = ((calibration.slope * bgReading.ageAdjustedRawValue) + calibration.intercept);
					bgReading.filteredCalculatedValue = ((calibration.slope * bgReading.ageAdjustedFiltered()) + calibration.intercept);
				}
				updateCalculatedValue(bgReading);
			}
			bgReading.performCalculations();
			return bgReading;
		}
		
		public function ageAdjustedFiltered():Number {
			var usedRaw:Number = usedRaw();
			if(usedRaw == rawData || rawData == 0){
				return filteredData;
			} else {
				// adjust the filtered_data with the same factor as the age adjusted raw value
				return filteredData * (usedRaw/rawData);
			}
		}
		
		public function usedRaw():Number {
			var calibration:Calibration = Calibration.last();
			if (calibration != null && calibration.checkIn) {
				return rawData;
			}
			return ageAdjustedRawValue;
		}
		
		public static function weightedAverageRaw(timeA:Number, timeB:Number, calibrationTime:Number, rawA:Number, rawB:Number):Number {
			var relativeSlope:Number = (rawB -  rawA)/(timeB - timeA);
			var relativeIntercept:Number = rawA - (relativeSlope * timeA);
			return ((relativeSlope * calibrationTime) + relativeIntercept);
		}

		
		/**
		 * no database udpate ! 
		 */
		private function performCalculations():BgReading {
			findNewCurve();
			findNewRawCurve();
			findSlope();
			calculateNoise();
			return this;
		}
		
		/**
		 * no database update ! 
		 */
		public function findSlope(ignoreSensorId:Boolean = false):void {
			var last2:Array = BgReading.latest(2, ignoreSensorId);
			
			_hideSlope = true;
			if (last2.length == 2) {
				var slopePair:Array = calculateSlope(this, last2[1] as BgReading);
				_calculatedValueSlope = slopePair[0] as Number;
				_hideSlope = slopePair[1] as Boolean;
			} else if (last2.length == 1) {
				_calculatedValueSlope = 0;
			} else {
				_calculatedValueSlope = 0;
			}
			
			resetLastModifiedTimeStamp();
		}
		
		/**
		 * no database update ! <br>
		 * returns this
		 */
		private function calculateAgeAdjustedRawValue():BgReading {
			if (sensor == null) {
				_ageAdjustedRawValue = rawData;
				return this;
			}
			var adjust_for:Number = AGE_ADJUSTMENT_TIME - (timestamp - sensor.startedAt);
			if (adjust_for <= 0 || CGMBlueToothDevice.isTypeLimitter()) {
				_ageAdjustedRawValue = rawData;
			} else {
				_ageAdjustedRawValue = ((AGE_ADJUSTMENT_FACTOR * (adjust_for / AGE_ADJUSTMENT_TIME)) * rawData) + rawData;
			}
			resetLastModifiedTimeStamp();
			return this;
		}
		
		/**
		 * for new bgreadings only<br>
		 * synchronous meaning return means update in database is finished<br>
		 * returns this 
		 */
		public function saveToDatabaseSynchronous():BgReading {
			Database.insertBgReadingSynchronous(this);
			return this;
		}
		
		/**
		 * for existing bgreadings only<br>
		 * synchronous meaning return means update in database is finished<br>
		 * no feedback on result of database update<br>
		 * returns this 
		 */
		public function updateInDatabaseSynchronous():BgReading {
			Database.updateBgReadingSynchronous(this);
			return this;
		}
		
		/**
		 * for existing bgreadings only<br>
		 * asynchronous meaning return means update in database not guaranteed finished<br>
		 * returns this 
		 */
		public function deleteInDatabase():void {
			Database.deleteBgReadingSynchronous(this);
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("BgReading.as", log);
		}
		
		public function print(indentation:String):String {
			var r:String = "bgreading = ";
			r += "\n" + indentation + "uniqueid = " + uniqueId;
			r += "\n" + indentation + "a = " + a;
			r += "\n" + indentation + "ageAdjustedRawValue = " + ageAdjustedRawValue;
			r += "\n" + indentation + "b = " + b;
			r += "\n" + indentation + "c = " + c;
			r += "\n" + indentation + "calculatedValue = " + calculatedValue;
			r += "\n" + indentation + "calculatedValueSlope = " + calculatedValueSlope;
			r += "\n" + indentation + "calibration = " + (calibration == null ? "null":calibration.print("      "));
			r += "\n" + indentation + "calibrationFlag = " + calibrationFlag.toString();
			r += "\n" + indentation + "filteredCalculatedValue = " + filteredCalculatedValue;
			r += "\n" + indentation + "filteredData = " + filteredData;
			r += "\n" + indentation + "hideSlope = " + hideSlope;
			r += "\n" + indentation + "noise = " + noise;
			r += "\n" + indentation + "ra = " + ra;
			r += "\n" + indentation + "rawCalculated = " + rawCalculated;
			r += "\n" + indentation + "rawData = " + rawData;
			r += "\n" + indentation + "rb = " + rb;
			r += "\n" + indentation + "rc = " + rc;
			r += "\n" + indentation + "sensor = " + (sensor == null ? "null":sensor.print("      "));
			r += "\n" + indentation + "timestamp = " + timestamp;
			return r;
		}
		
		public function slopeArrow():String{
			return slopeToArrowSymbol(calculatedValueSlope * 60000);
		}

		public static function slopeToArrowSymbol(slope:Number):String {
			if (slope <= (-3.5)) {
				return "\u2193\u2193";
			} else if (slope <= (-2)) {
				return "\u2193";
			} else if (slope <= (-1)) {
				return "\u2198";
			} else if (slope <= (1)) {
				return "\u2192";
			} else if (slope <= (2)) {
				return "\u2197";
			} else if (slope <= (3.5)) {
				return "\u2191";
			} else {
				return "\u2191\u2191";
			}
		}
		
		public function getSlopeOrdinal():int {
			var slope_by_minute:Number = calculatedValueSlope * 60000;
			var ordinal:int = 0;
			if(!hideSlope) 
			{
				if (slope_by_minute <= (-3.5))
					ordinal = 7;
				else if (slope_by_minute <= (-2))
					ordinal = 6;
				else if (slope_by_minute <= (-1))
					ordinal = 5;
				else if (slope_by_minute <= (1))
					ordinal = 4;
				else if (slope_by_minute <= (2))
					ordinal = 3;
				else if (slope_by_minute <= (3.5))
					ordinal = 2;
				else
					ordinal = 1;
			}
			return ordinal;
		}
		
		public function slopeName():String {
			var slope_by_minute:Number = calculatedValueSlope * 60000;
			var arrow:String = "NONE";
			if (slope_by_minute <= (-3.5)) {
				arrow = "DoubleDown";
			} else if (slope_by_minute <= (-2)) {
				arrow = "SingleDown";
			} else if (slope_by_minute <= (-1)) {
				arrow = "FortyFiveDown";
			} else if (slope_by_minute <= (1)) {
				arrow = "Flat";
			} else if (slope_by_minute <= (2)) {
				arrow = "FortyFiveUp";
			} else if (slope_by_minute <= (3.5)) {
				arrow = "SingleUp";
			} else if (slope_by_minute <= (40)) {
				arrow = "DoubleUp";
			}

			if(hideSlope) {
				arrow = "NOT COMPUTABLE";
			}
			return arrow;
		}
		
		// Calculate the sum of the distance of all points (overallDistance)
		// Calculate the overall distance between the first and the last point (overallDistance)
		// Calculate the noise as the following formula: 1 - sod / overallDistance
		// Noise will get closer to zero as the sum of the individual lines are mostly in a straight or straight moving curve
		// Noise will get closer to one as the sum of the distance of the individual lines get large
		// Also add multiplier to get more weight to the latest BG values
		// Also added weight for points where the delta shifts from pos to neg or neg to pos (peaks/valleys)
		// the more peaks and valleys, the more noise is amplified
		public function calculateNoise():void 
		{
			//Common variables and constants
			const MAXRECORDS:int=8;
			const MINRECORDS:int=4;
			var internalNoise:Number = 0;
			
			//Last 8 readings (if possible)
			var sgvArr:Array = BgReading.latest(MAXRECORDS, CGMBlueToothDevice.isFollower());
			
			//Reverse records (oldest comes first)
			sgvArr.reverse();
			
			//Number of available readings for calculations
			var n:int = sgvArr.length;
			
			//Validation
			if (n < MINRECORDS)
			{
				//Not enough records. Assume no noise
				_noise = "1"; //Clean
				return; 
			}
			
			//Get oldest and newest readings as well as bg values
			var firstBGReading:BgReading = sgvArr[0];
			var lastBGReading:BgReading = sgvArr[n-1];
			
			var firstBgReadingCalculatedValue:Number = firstBGReading._calculatedValue;
			var lastBgReadingCalculatedValue:Number = lastBGReading._calculatedValue;
			
			if (lastBgReadingCalculatedValue > 400) 
			{
				_noise = "3";//Medium
				return; 
			} 
			else if (lastBgReadingCalculatedValue  < 40) 
			{
				_noise = "2";//Light
				return;
			}
			else if (Math.abs(lastBgReadingCalculatedValue - sgvArr[n-2]._calculatedValue) > 30) 
			{
				_noise = "4"; //Glucose change out of range [-30, 30] - setting noise level Heavy
				return;
			} 
			
			var firstSGV:Number = firstBgReadingCalculatedValue * 1000;
			var firstTime:Number = firstBGReading._timestamp / 1000 * 30;
			
			var lastSGV:Number = lastBgReadingCalculatedValue * 1000;
			var lastTime:Number = lastBGReading._timestamp / 1000 * 30;
			
			//Array that will hold time differences between bg readings
			var xarr:Array = [];
			
			//Common index for iterations
			var i:int;
			
			//Calculate and store time differences
			for (i = 0; i < n; i++) 
			{
				xarr.push(sgvArr[i]._timestamp / 1000 * 30 - firstTime);
			}
			
			//sod = sum of distances
			var sod:Number = 0;
			var lastDelta:Number = 0;
			
			//Calculate sod
			for (i = 1; i < n; i++) 
			{
				// y2y1Delta adds a multiplier that gives higher priority to the latest BG's
				var y2y1Delta:Number = (sgvArr[i]._calculatedValue - sgvArr[i-1]._calculatedValue) * 1000 * (1 + i / (n*3));
				var x2x1Delta:Number = xarr[i] - xarr[i-1];
				
				if ((lastDelta > 0) && (y2y1Delta < 0)) 
				{
					// switched from positive delta to negative, increase noise impact  
					//y2y1Delta = y2y1Delta * 1.1;
					y2y1Delta = y2y1Delta * 1.4;
				}
				else if ((lastDelta < 0) && (y2y1Delta > 0)) 
				{
					// switched from negative delta to positive, increase noise impact 
					//y2y1Delta = y2y1Delta * 1.2; ORIGINAL
					y2y1Delta = y2y1Delta * 1.4; 
				}
				
				sod += Math.sqrt(Math.pow(x2x1Delta, 2) + Math.pow(y2y1Delta, 2));
			}
			
			var overallsod:Number = Math.sqrt(Math.pow(lastSGV - firstSGV, 2) + Math.pow(lastTime - firstTime, 2));
			
			//Calculate final noise
			if (sod == 0) 
			{
				_noise = "1" //Assume no noise
				return;
			} 
			else 
			{
				internalNoise = 1 - (overallsod/sod);
			}
			
			//Convert to Nightscout/xDrip format
			//if (internalNoise < 0.35)  ORIGINAL
			if (internalNoise < 0.15) 
			{
				_noise = "1"; //Clean
				return;
			} 
			//else if (internalNoise < 0.5) 
			else if (internalNoise < 0.3) 
			{
				_noise = "2"; //Light
				return;
			} 
			//else if (internalNoise < 0.7) 
			else if (internalNoise < 0.5) 
			{
				_noise = "3"; //Medium
				return;
			} 
			else if (internalNoise >= 0.5) 
			{
				_noise = "4"; //Heavy
				return;
			}
			
			//If everything else fails, assume no noise
			_noise = "1"; //Clean
		}
		
		public function noiseValue():int {
			if(_noise == null || _noise == "") {
				return 1;
			} else {
				return int(_noise);
			}
		}
	
		/**
		 * if  ignoreSensorId = true, then calculations takes into account only readings that have sensor id = current sensor id
		 */
		public static function currentSlope(ignoreSensorId:Boolean = false):Number {
			var last_2:Array = BgReading.latest(2, ignoreSensorId);
			if (last_2.length == 2) {
				var slopePair:Array = calculateSlope(last_2[0] as BgReading, last_2[1] as BgReading);
				return slopePair[0] as Number;
			} else{
				return new Number(0);
			}
		}
		
		public static function getForPreciseTimestamp(timestamp:Number, precision:Number, lock_to_sensor:Boolean = true):BgReading {
			var activeSensor:Sensor = Sensor.getActiveSensor();
			var returnValue:BgReading = null;
			var cntr:int = ModelLocator.bgReadings.length - 1;
			if ((activeSensor != null) || (!lock_to_sensor)) {
				while (cntr > -1 && returnValue == null) {
					var bgReading:BgReading = ModelLocator.bgReadings[cntr] as BgReading;
					if ( (timestamp - precision <= bgReading.timestamp) 
						&& 
						(bgReading.timestamp >= timestamp + precision)
						&&
						(lock_to_sensor ? bgReading.sensor.uniqueId == activeSensor.uniqueId : bgReading.timestamp > 0) ) {
						returnValue = bgReading;
					}
					cntr--;
				}
			}
			if (returnValue == null)
				myTrace("getForPreciseTimestamp: No luck finding a BG timestamp match: " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(timestamp)) + ", precision:" + precision + ", Sensor: " + ((activeSensor == null) ? "null" : activeSensor.uniqueId));
			return returnValue;
		}
	}
}