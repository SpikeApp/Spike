/**
 code ported from xdripplus 
 */
package utils.libre
{
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	
	import database.BgReading;
	import database.CommonSettings;
	import database.Sensor;
	
	import model.ModelLocator;
	
	import services.TransmitterService;
	
	import utils.Trace;
	
	public class LibreAlarmReceiver extends EventDispatcher
	{
		private static var sensorAge:Number = 0;
		private static var timeShiftNearest:Number = -1;
		
		public function LibreAlarmReceiver() {}
		
		private static function toDateString(timestamp:Number):String {
			var date:Date = new Date(timestamp);
			return date.toLocaleString();
		}
		
		/**
		 * returns true if a new reading is created
		 */
		public static function CalculateFromDataTransferObject(bgReadings:Array):Boolean {
			myTrace("in CalculateFromDataTransferObject");
			var timeStampLastBgReadingBeforeStart:Number = 0;
			
			if ( ModelLocator.getLastBgReading() != null) {
				timeStampLastBgReadingBeforeStart = (ModelLocator.getLastBgReading()).timestamp;
			}
			var timeStampLastAddedBgReading:Number = timeStampLastBgReadingBeforeStart;
			/**
			 * latest reading in bgReadings that was not added because time difference with previous added reading was too narrow.
			 */
			var lastReadingNotAdded:GlucoseData = null;
			if (bgReadings != null) {
				if (bgReadings.length > 0) {
					var thisSensorAge:Number = (bgReadings[bgReadings.length - 1] as GlucoseData).sensorTime;
					sensorAge = new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE));
					if (thisSensorAge > sensorAge) {
						sensorAge = thisSensorAge;
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE, thisSensorAge.toString());
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NFC_AGE_PROBEM, "false");
						myTrace("in CalculateFromDataTransferObject, Sensor age advanced to: " + thisSensorAge);
					} else if (thisSensorAge == sensorAge) {
						myTrace("in CalculateFromDataTransferObject, Sensor age has not advanced: " + sensorAge);
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NFC_AGE_PROBEM, "true");
					} else {
						myTrace("in CalculateFromDataTransferObject, Sensor age has gone backwards!!! " + sensorAge);
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE, thisSensorAge.toString());
						CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_NFC_AGE_PROBEM, "true");
					}
					
					if (Sensor.getActiveSensor() == null) {
						//start sensor without user intervention 
						Sensor.startSensor(((new Date()).valueOf() - sensorAge * 60 * 1000));
					}
					
					//got all readings and if there's new one add them, at least 4.5 minutes between two readings
					for (var cntr:int = 0; cntr < bgReadings.length ;cntr ++) {
						var gd:GlucoseData = bgReadings[cntr] as GlucoseData;
						if (gd.glucoseLevelRaw > 0) {
							if (gd.realDate > timeStampLastAddedBgReading + 4.5 * 60 * 1000) {//
								myTrace("in CalculateFromDataTransferObject createbgd : " + (new Date(gd.realDate)).toString() + " " + gd.glucose(0, false));
								createBGfromGD(gd);
								timeStampLastAddedBgReading = gd.realDate;
								lastReadingNotAdded = null;
							} else {
								//save the lastReading that was skipped, because the last reading is too interesting too drop
								lastReadingNotAdded = gd;
							}
						} else {
							myTrace("in CalculateFromDataTransferObject, received glucoseLevelRaw = 0");
						}
					}
					if (lastReadingNotAdded != null) {
						//lastreading was not added because it was too close to previous reading
						//adding it now will guarantee that the most recent reading is shown, next readings will follow 5 minutes later)

						//however if the last reading that was added, is less than 2 minutes close to this lastReadingNotAdded, then let's remove the lastreading that was added
						/*if (lastReadingNotAdded.realDate - timeStampLastAddedBgReading < 2 * 60 * 1000) {
							myTrace("in CalculateFromDataTransferObject, removing last reading from modellocator");
							ModelLocator.removeLastBgReading();
						}*/
						myTrace("in CalculateFromDataTransferObject createbgd : " + (new Date(gd.realDate)).toString() + " " + gd.glucose(0, false));
						createBGfromGD(lastReadingNotAdded);
						timeStampLastAddedBgReading = gd.realDate;
					}
				} else {
					myTrace("in CalculateFromDataTransferObject, Trend data has no elements")
				}
			} else {
				myTrace("in CalculateFromDataTransferObject, Trend data is null!");
			}
			
			return timeStampLastAddedBgReading > timeStampLastBgReadingBeforeStart;
		}
		
		private static function createBGfromGD(gd:GlucoseData):void {
			var bgReading:BgReading = null;
			bgReading = BgReading.create(getGlucose(gd.glucoseLevelRaw), getGlucose(gd.glucoseLevelRaw), gd.realDate);
			//myTrace("in createBGfromGD, created bgreading at: " + DateTimeUtilities.createNSFormattedDateAndTime(new Date(gd.realDate)) + ", with value " + bgReading.calculatedValue);
			myTrace("in createBGfromGD, created bgreading at: " + (new Date(gd.realDate)).toString() + ", with value " + bgReading.calculatedValue);
			bgReading.saveToDatabaseSynchronous();
			TransmitterService.dispatchBgReadingEvent();
		}
		
		public static function getGlucose(rawGlucose:Number):Number {
			//LIBRE_MULTIPLIER
			return (rawGlucose * 117.64705);
		}
		
		/**
		 * original comes from xdripplus NFCReaderX.java<br>
		 * returnvalue will have bgreading list chronologically sorted, ascending according to realdate<br> 
		 * <br>
		 * Any reading in data that is younger than the latest BGReading will be ignored<br>
		 */
		public static function parseData(tagId:String, data:ByteArray):Array {
			var index:int;
			var i:int;
			var glucoseData:GlucoseData;
			var byte:ByteArray;
			var time:Number;
			
			var ourTime:Number = (new Date()).valueOf();
			
			var indexTrend:int = getByteAt(data, 26) & 0xFF;
			
			var indexHistory:int = getByteAt(data, 27) & 0xFF; // double check this bitmask? should be lower?
			
			var sensorTime:int = 256 * (getByteAt(data, 317) & 0xFF) + (getByteAt(data, 316) & 0xFF);
			
			var sensorStartTime:Number = ourTime - sensorTime * 60 * 1000;
			
			var latestBgReading:BgReading = BgReading.lastNoSensor();
			var timeStampLastBgReading:Number = 0;
			if (latestBgReading != null) {
				timeStampLastBgReading = latestBgReading.timestamp;
			}
			
			// option to use 13 bit mask
			var thirteen_bit_mask:Boolean = true;//Pref.getBooleanDefaultFalse("testing_use_thirteen_bit_mask");
			
			var bgReadingList:Array = new Array();//arraylist of glucosedata
			
			// loads history values (ring buffer, starting at index_trent. byte 124-315)
			for (index = 0; index < 32; index++) {
				i = indexHistory - index - 1;
				if (i < 0) i += 32;
				time = Math.max(0,(int)(Math.abs(sensorTime - 3)/15)*15 - index*15);
				if (sensorStartTime + time * 60 * 1000 > timeStampLastBgReading) {
					byte = new ByteArray();
					byte.writeByte(getByteAt(data, (i * 6 + 125)));
					byte.writeByte(getByteAt(data, (i * 6 + 124)));
					glucoseData = new GlucoseData();
					glucoseData.glucoseLevelRaw = getGlucoseRaw(byte, thirteen_bit_mask);
					glucoseData.realDate = sensorStartTime + time * 60 * 1000;
					glucoseData.sensorId = tagId;
					glucoseData.sensorTime = time;
					myTrace("add history with realDate = " + glucoseData.realDate + ", sensorTime = " + glucoseData.sensorTime + ", glucoselevelRaw = " + glucoseData.glucoseLevelRaw);
					bgReadingList.push(glucoseData);
				}
			}
						
			// loads trend values (ring buffer, starting at index_trent. byte 28-123)
			for (index = 0; index < 16; index++) {
				i = indexTrend - index - 1;
				if (i < 0) i += 16;
				time = Math.max(0, sensorTime - index);
				if (sensorStartTime + time * 60 * 1000 > timeStampLastBgReading) {
					byte = new ByteArray();
					byte.writeByte(getByteAt(data, (i * 6 + 29)));
					byte.writeByte(getByteAt(data, (i * 6 + 28)));
					glucoseData = new GlucoseData();
					glucoseData.glucoseLevelRaw = getGlucoseRaw(byte, thirteen_bit_mask);
					glucoseData.realDate = sensorStartTime + time * 60 * 1000;
					glucoseData.sensorId = tagId;
					glucoseData.sensorTime = time;
					//myTrace("in parseData trendlist, glucoselevelraw = " + glucoseData.glucoseLevelRaw + ", realdata = " + glucoseData.realDate + ", glucoseData.sensorId = " + glucoseData.sensorId + ", sensorTime = " + glucoseData.sensorTime);
					myTrace("add trend with realDate = " + glucoseData.realDate + ", sensorTime = " + glucoseData.sensorTime + ", glucoselevelRaw = " + glucoseData.glucoseLevelRaw);
					bgReadingList.push(glucoseData);
				}
			}
			
			//Sort by realDate, ascending.
			bgReadingList.sortOn(["realDate"], Array.NUMERIC);
			
			return bgReadingList;
		}
		
		private static function getGlucoseRaw(bytes:ByteArray, thirteenBitMask:Boolean):int {
			if (thirteenBitMask) {
				return ((256 * (getByteAt(bytes, 0) & 0xFF) + (getByteAt(bytes, 1) & 0xFF)) & 0x1FFF);
			} else {
				return ((256 * (getByteAt(bytes, 0) & 0xFF) + (getByteAt(bytes, 1) & 0xFF)) & 0x0FFF);
			}
		}
		
		private static function getByteAt(buffer:ByteArray, position:int):int {
			buffer.position = position;
			return buffer.readByte();
		}
		
		/**
		 * gds : gluosedata
		 */
		private static function myTrace(log:String):void {
			Trace.myTrace("LibreAlarmReceiver.as", log);
		}
	}
}