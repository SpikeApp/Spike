/**
 Copyright (C) 2017  Johan Degraeve
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
 
 * MOST OF THIS CODE HERE IS COPIED FROM THE xDRIP-EXPERIMENTAL PROJECT AND PORTED
 * see https://github.com/StephenBlackWasAlreadyTaken/xDrip-Experimental
 * 
 */
package databaseclasses
{
	import mx.collections.ArrayCollection;
	
	import Utilities.BgGraphBuilder;
	import Utilities.Trace;
	
	import model.ModelLocator;
	
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
		
		private var _timestamp:Number;//db
		
		/**
		 * ms sinds 1 jan 1970 
		 */
		public function get timestamp():Number
		{
			return _timestamp;
		}
		
		private var _rawData:Number;

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
		
		private var _calculatedValue:Number;

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
		 * arraycollection will contain number of bgreadings with<br>
		 * - sensor = current sensor<br>
		 * - calculatedValule != 0<br>
		 * - rawData != 0<br>
		 * - latest 'number' that match these requirements<br>
		 * - descending timestamp, order
		 * <br>
		 * could also be less than number, ie returnvalue could be arraycollection of size 0 
		 */
		public static function latest(number:int):ArrayCollection {
			var returnValue:ArrayCollection = new ArrayCollection();
			var currentSensorId:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR);
			if (currentSensorId != "0") {
				var cntr:int = ModelLocator.bgReadings.length - 1;
				var itemsAdded:int = 0;
				while (cntr > -1 && itemsAdded < number) {
					var bgReading:BgReading = ModelLocator.bgReadings.getItemAt(cntr) as BgReading;
					if (bgReading.sensor != null) {
						if (bgReading.sensor.uniqueId == currentSensorId && bgReading.calculatedValue != 0 && bgReading.rawData != 0) {
							returnValue.addItem(bgReading);
							itemsAdded++;
						}
					}
					cntr--;
				}
			}
			return returnValue;
		}
		
		/**
		 * arraycollection will contain number of bgreadings with<br>
		 * - sensor = current sensor<br>
		 * - rawData != 0<br>
		 * - latest 'number' that match these requirements<br>
		 * - descending timestamp, order
		 * <br>
		 * could also be less than number, ie returnvalue could be arraycollection of size 0 
		 */
		public static function latestBySize(number:int):ArrayCollection {
			var returnValue:ArrayCollection = new ArrayCollection();
			var currentSensorId:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CURRENT_SENSOR);
			if (currentSensorId != "0") {
				var cntr:int = ModelLocator.bgReadings.length - 1;
				var itemsAdded:int = 0;
				while (cntr > -1 && itemsAdded < number) {
					var bgReading:BgReading = ModelLocator.bgReadings.getItemAt(cntr) as BgReading;
					if (bgReading.sensor != null) {
						if (bgReading.sensor.uniqueId == currentSensorId && bgReading.rawData != 0) {
							returnValue.addItem(bgReading);
							itemsAdded++;
						}
					}
					cntr--;
				}
			}
			return returnValue;
		}
		
		/**
		 * arraycollection will contain bgreadings with<br>
		 * - rawData != 0<br>
		 * - calculatedValue != 0<br>
		 * - descending timestamp, order
		 * <br>
		 * returnvalue could be arraycollection of size 0 
		 */
		public static function last30Minutes():ArrayCollection {
			var returnValue:ArrayCollection = new ArrayCollection();
			if (ModelLocator.bgReadings.length == 0)
				return returnValue;
			
			var timestamp:Number = (new Date()).valueOf() - (60000 * 30);
			var cntr:int = ModelLocator.bgReadings.length - 1;
			var itemsAdded:int = 0;
			var bgReading:BgReading = ModelLocator.bgReadings.getItemAt(cntr) as BgReading;
			while (cntr > -1 && bgReading.timestamp > timestamp) {
				if (bgReading.calculatedValue != 0 && bgReading.rawData != 0) {
					returnValue.addItem(bgReading);
					itemsAdded++;
				}
				cntr--;
				if (cntr > -1)
					bgReading = ModelLocator.bgReadings.getItemAt(cntr) as BgReading;
			}
			return returnValue;
		}

		
		
		
		/**
		 * - rawData != 0<br>
		 * - calculatedValule != 0<br>
		 * - latest
		 * - null if there's none i guess
		 */
		public static function lastNoSensor():BgReading {
			var returnValue:BgReading;
			var cntr:int = ModelLocator.bgReadings.length - 1;
			while (cntr > -1) {
				var bgReading:BgReading = ModelLocator.bgReadings.getItemAt(cntr) as BgReading;
				if (bgReading.rawData != 0 && bgReading.calculatedValue != 0) {
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
			var last3:ArrayCollection = latest(3);
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
				latest = last3.getItemAt(0) as BgReading;
				second_latest = last3.getItemAt(1) as BgReading;
				third_latest = last3.getItemAt(2) as BgReading;
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
				latest = last3.getItemAt(0) as BgReading;
				second_latest = last3.getItemAt(1) as BgReading;
				
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
			var last3:ArrayCollection = BgReading.latest(3);
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
				latest = last3.getItemAt(0) as BgReading;
				second_latest = last3.getItemAt(1) as BgReading;
				third_latest = last3.getItemAt(2) as BgReading;
				
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
				latest = last3.getItemAt(0) as BgReading;
				second_latest = last3.getItemAt(1) as BgReading;
				
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
			var latestReadings:ArrayCollection = BgReading.latest(1);
			if (latestReadings.length == 0) {
				estimate = 160;
			} else {
				var latest:BgReading = latestReadings.getItemAt(0) as BgReading;
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
					var lastBgReading:BgReading = (BgReading.latest(1))[0] as BgReading;
					if (lastBgReading != null && lastBgReading.calibration != null) {
						if (lastBgReading.calibrationFlag == true && ((lastBgReading.timestamp + (60000 * 20)) > timestamp) && ((lastBgReading.calibration.timestamp + (60000 * 20)) > timestamp)) {
							lastBgReading.calibration
								.rawValueOverride(BgReading.weightedAverageRaw(lastBgReading.timestamp, timestamp, lastBgReading.calibration.timestamp, lastBgReading.ageAdjustedRawValue, bgReading.ageAdjustedRawValue))
								.updateInDatabaseSynchronous();
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
			return this;
		}
		
		/**
		 * no database update ! 
		 */
		public function findSlope():void {
			var last2:ArrayCollection = BgReading.latest(2);
			
			_hideSlope = true;
			if (last2.length == 2) {
				var slopePair:Array = calculateSlope(this, last2.getItemAt(1) as BgReading);
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
			if (adjust_for <= 0 || BlueToothDevice.isTypeLimitter()) {
				myTrace("in calculateAgeAdjustedRawValue, istypelimitter, not applying age adjustment");
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
			if(!hideSlope) {
				if (slope_by_minute <= (-3.5)) {
					ordinal = 7;
				} else if (slope_by_minute <= (-2)) {
					ordinal = 6;
				} else if (slope_by_minute <= (-1)) {
					ordinal = 5;
				} else if (slope_by_minute <= (1)) {
					ordinal = 4;
				} else if (slope_by_minute <= (2)) {
					ordinal = 3;
				} else if (slope_by_minute <= (3.5)) {
					ordinal = 2;
				} else {
					ordinal = 1;
				}
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
		
		public function noiseValue():int {
			if(noise == null || noise == "") {
				return 1;
			} else {
				return new Number(noise);
			}
		}
	
		public static function currentSlope():Number {
			var last_2:ArrayCollection = BgReading.latest(2);
			if (last_2.length == 2) {
				var slopePair:Array = calculateSlope(last_2.getItemAt(0) as BgReading, last_2.getItemAt(1) as BgReading);
				return slopePair[0] as Number;
			} else{
				return new Number(0);
			}
		}
		
	}
}