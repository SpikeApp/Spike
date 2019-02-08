package ui.chart.helpers
{
	import flash.errors.IllegalOperationError;
	
	import spark.formatters.DateTimeFormatter;
	
	import G5G6Model.TransmitterStatus;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.Sensor;
	
	import model.ModelLocator;
	
	import treatments.BasalRate;
	import treatments.ProfileManager;
	
	import ui.InterfaceController;
	
	import utils.Constants;
	import utils.TimeSpan;
	
	[ResourceBundle("chartscreen")]
	[ResourceBundle("transmitterscreen")]
	[ResourceBundle("treatments")]

	public class GlucoseFactory
	{
		public function GlucoseFactory()
		{
			throw new IllegalOperationError("GlucoseFactory class is not meant to be instantiated!");
		}
		
		public static function getGlucoseOutput(glucoseValue:Number):Object
		{
			var glucoseUnit:String;
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") 
				glucoseUnit = "mg/dL";
			else
				glucoseUnit = "mmol/L";
			
			var glucoseOutput:String;
			var glucoseValueFormatted:Number;
			if (glucoseValue > 40 && glucoseValue < 400)
			{
				if (glucoseUnit == "mg/dL")
				{
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_ROUND_MGDL_ON) != "true")
						glucoseValueFormatted = Math.round(glucoseValue * 10) / 10;
					else
						glucoseValueFormatted = Math.round(glucoseValue);
					glucoseOutput = String( glucoseValueFormatted );
				}
				else
				{
					glucoseValueFormatted = Math.round(BgReading.mgdlToMmol(glucoseValue) * 10) / 10;
					
					if ( glucoseValueFormatted % 1 == 0)
						glucoseOutput = String(glucoseValueFormatted) + ".0";
					else
						glucoseOutput = String(glucoseValueFormatted);
				}
			}
			else
			{
				if (glucoseUnit == "mg/dL")
				{
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_ROUND_MGDL_ON) != "true")
						glucoseValueFormatted = Math.round(glucoseValue * 10) / 10;
					else
						glucoseValueFormatted = Math.round(glucoseValue);
				}
				else
					glucoseValueFormatted = Math.round(BgReading.mgdlToMmol(glucoseValue) * 10) / 10;
				
				if (glucoseValue >= 400)
					glucoseOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','glucose_high');
				else if (glucoseValue <= 40 && glucoseValue > 12)
					glucoseOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','glucose_low');
				else
				{
					switch(glucoseValue) {
						case 0:
							glucoseOutput = "??0";
							break;
						case 1:
							glucoseOutput = "?SN";
							break;
						case 2:
							glucoseOutput = "??2";
							break;
						case 3:
							glucoseOutput = "?NA";
							break;
						case 5:
							glucoseOutput = "?NC";
							break;
						case 6:
							glucoseOutput = "?CD";
							break;
						case 9:
							glucoseOutput = "?AD";
							break;
						case 12:
							glucoseOutput = "?RF";
							break;
						default:
							glucoseOutput = "???";
							break;
					}
				}
			}
			
			return {glucoseOutput: glucoseOutput, glucoseValueFormatted: glucoseValueFormatted};
		}
		
		public static function getGlucoseSlope(previousGlucoseValue:Number, previousGlucoseValueFormatted:Number, glucoseValue:Number, glucoseValueFormatted:Number, textToSpeechEnabled:Boolean = false):String
		{
			var glucoseUnit:String;
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") 
				glucoseUnit = "mg/dL";
			else
				glucoseUnit = "mmol/L";
			
			var slopeOutput:String;
			var glucoseDifference:Number;
			
			if (glucoseUnit == "mg/dL")
				glucoseDifference = Math.round((glucoseValueFormatted - previousGlucoseValueFormatted) * 10) / 10;
			else
			{
				glucoseDifference = Math.round(((Math.round(BgReading.mgdlToMmol(glucoseValue) * 100) / 100) - (Math.round(BgReading.mgdlToMmol(previousGlucoseValue) * 100) / 100)) * 100) / 100;
				
			}
				
			if((glucoseUnit == "mg/dL" && Math.abs(glucoseDifference) > 100) || (glucoseUnit == "mmol/L" && Math.abs(glucoseDifference) > 5.5))
				slopeOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','slope_error');
			else
			{
				var glucoseDifferenceOutput:String;
				
				if (glucoseDifference >= 0)
				{
					glucoseDifferenceOutput = String(glucoseDifference);
						
					if ( glucoseDifference % 1 == 0 && (!CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) != "Nightscout"))
						glucoseDifferenceOutput += ".0";
					
					if (!textToSpeechEnabled)
						slopeOutput = "+ " + glucoseDifferenceOutput;
					else
						slopeOutput = "+" + glucoseDifferenceOutput;
				}
				else
				{
					glucoseDifferenceOutput = String(Math.abs(glucoseDifference));
						
					if ( glucoseDifference % 1 == 0 && (!CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) != "Nightscout"))
						glucoseDifferenceOutput += ".0";
						
					if (!textToSpeechEnabled)
						slopeOutput = "- " + glucoseDifferenceOutput;
					else
						slopeOutput = "-" + glucoseDifferenceOutput;
				}
			}
			
			return slopeOutput;
		}
		
		public static function getGlucoseColor(glucoseValue:Number):uint
		{
			//Colors
			var highUrgentGlucoseMarkerColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_HIGH_COLOR));
			var highGlucoseMarkerColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_HIGH_COLOR));
			var inrangeGlucoseMarkerColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_IN_RANGE_COLOR));
			var lowGlucoseMarkerColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_LOW_COLOR));
			var lowUrgentGlucoseMarkerColor:uint = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_LOW_COLOR));
			
			//Threshold
			var glucoseUrgentLow:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK));
			var glucoseLow:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
			var glucoseHigh:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
			var glucoseUrgentHigh:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK));
			
			var color:uint;
			if(glucoseValue >= glucoseUrgentHigh)
				color = highUrgentGlucoseMarkerColor;
			else if(glucoseValue >= glucoseHigh)
				color = highGlucoseMarkerColor;
			else if(glucoseValue > glucoseLow && glucoseValue < glucoseHigh)
				color = inrangeGlucoseMarkerColor;
			else if(glucoseValue <= glucoseLow && glucoseValue > glucoseUrgentLow)
				color = lowGlucoseMarkerColor;
			else if(glucoseValue <= glucoseUrgentLow)
				color = lowUrgentGlucoseMarkerColor;
			
			return color;
		}
		
		public static function formatIOB(IOBValue:Number):String
		{
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_LOOP_OPENAPS_USER_ENABLED) == "true")
			{
				return IOBValue.toFixed(2) + "U";
			}
			else
			{
				return Math.abs(IOBValue).toFixed(2) + "U";
			}
		}
		public static function formatCOB(COBValue:Number):String
		{
			return Math.abs(COBValue).toFixed(1) + "g";
		}
		
		public static function getRawGlucose(targetBGReading:BgReading = null, lastestCalibration:Calibration = null):Number 
		{
			var raw:Number = Number.NaN;
			var lastBgReading:BgReading = targetBGReading != null ? targetBGReading : BgReading.lastNoSensor();
			var lastCalibration:Calibration = lastestCalibration != null ? lastestCalibration : Calibration.last();
			if (lastBgReading != null && lastCalibration != null)
			{
				var slope:Number = lastCalibration.checkIn ? lastCalibration.slope : 1000 / lastCalibration.slope;
				var scale:Number = lastCalibration.checkIn ? lastCalibration.firstScale : 1;
				var intercept:Number = lastCalibration.checkIn ? lastCalibration.firstIntercept : lastCalibration.intercept * -1000 / lastCalibration.slope;
				var unfiltered:Number = lastCalibration.checkIn ? lastBgReading.rawData * 1000 : lastBgReading.ageAdjustedRawValue * 1000;
				var filtered:Number = lastCalibration.checkIn || lastBgReading.rawData == 0 ? lastBgReading.filteredData * 1000 : (lastBgReading.filteredData * (lastBgReading.ageAdjustedRawValue / lastBgReading.rawData)) * 1000;
				
				if (slope === 0 || unfiltered === 0 || scale === 0) 
					raw = 0;
				else if (filtered === 0 || lastBgReading.calculatedValue < 40) 
					raw = scale * (unfiltered - intercept) / slope;
				else 
				{
					var ratio:Number = scale * (filtered - intercept) / slope / lastBgReading.calculatedValue;
					raw = scale * (unfiltered - intercept) / slope / ratio;
				}
				
				if (!isNaN(raw) && raw != 0 && targetBGReading == null)
				{
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
					{
						if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_ROUND_MGDL_ON) != "true")
							raw = Math.round(raw * 10) / 10;
						else
							raw = Math.round(raw);
					}
					else
						raw = Math.round(BgReading.mgdlToMmol(raw) * 10) / 10;
				}
			}
			
			return raw;
		}
		
		/**
		 * Velocity
		 */
		public static function getGlucoseVelocity():Number
		{
			var isMgDl:Boolean = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true";
			var v:Number = 0;
			var n:int = 0;
			var i:int = 0;
			
			var last4Readings:Array = BgReading.latest(4, CGMBlueToothDevice.isFollower());
			var numberOfAvailableReadings:int = last4Readings.length;
			
			if (numberOfAvailableReadings == 4 && (last4Readings[0].timestamp - last4Readings[3].timestamp) / TimeSpan.TIME_1_MINUTE < 15.1) 
			{
				n = 4;
			}
			else
			{
				if (numberOfAvailableReadings == 3 && (last4Readings[0].timestamp - last4Readings[2].timestamp) / TimeSpan.TIME_1_MINUTE < 10.1) 
				{
					n = 3;
				}
				else
				{
					if (numberOfAvailableReadings == 2 && (last4Readings[0].timestamp - last4Readings[1].timestamp) / TimeSpan.TIME_1_MINUTE < 10.1) 
					{
						n = 2;
					}
					else
					{
						n = 0;
					}
				}
			}
			
			var xm:Number = 0;
			var ym:Number = 0;
			
			if (n > 0)
			{
				for (i = 0; i < n; i++) 
				{
					xm = xm + last4Readings[i].timestamp / TimeSpan.TIME_1_MINUTE;
					ym = ym + last4Readings[i].calculatedValue;
				}
				
				xm = xm / n;
				ym = ym / n;
				
				var c1:Number = 0;
				var c2:Number = 0;
				var t:Number = 0;
				
				for (i = 0; i < n; i++) 
				{
					t = last4Readings[i].timestamp / TimeSpan.TIME_1_MINUTE;
					c1 = c1 + ((t - xm) * (last4Readings[i].calculatedValue - ym));
					c2 = c2 + ((t - xm) * (t - xm));
				}
				
				v = c1 / c2;
			}
			else
			{
				//Not enough data
				v = Number.NaN;
			}
			
			if (!isNaN(v))
			{
				if (isMgDl)
				{
					v = Math.round(v * 100) / 100;
				}
				else
				{
					v = Math.round(BgReading.mgdlToMmol(v) * 1000) / 1000;
				}
			}
			
			return v;
		}
		
		public static function getSensorAge():String
		{
			var sage:String = "N/A";
			
			if (Sensor.getActiveSensor() != null)
			{
				var dateFormatter:DateTimeFormatter = new DateTimeFormatter();
				dateFormatter.dateTimePattern = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT).slice(0,2) == "24" ? "dd MMM HH:mm" : "dd MMM h:mm a";
				dateFormatter.useUTC = false;
				dateFormatter.setStyle("locale", Constants.getUserLocale());
				
				//Set sensor start time
				var sensorStartDate:Date = new Date(Sensor.getActiveSensor().startedAt)
				var sensorStartDateValue:String =  dateFormatter.format(sensorStartDate);
				
				//Calculate Sensor Age
				var sensorDays:String;
				var sensorHours:String;
				
				if (CGMBlueToothDevice.knowsFSLAge()) 
				{
					var sensorAgeInMinutes:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE);
					
					if (sensorAgeInMinutes == "0") 
						sage = ModelLocator.resourceManagerInstance.getString('sensorscreen', "sensor_age_not_applicable");
					else if ((new Number(sensorAgeInMinutes)) > 14.5 * 24 * 60) 
					{
						sage = ModelLocator.resourceManagerInstance.getString('sensorscreen','sensor_expired');
					}
					else 
					{
						sensorDays = TimeSpan.fromMinutes(Number(sensorAgeInMinutes)).days.toString();
						sensorHours = TimeSpan.fromMinutes(Number(sensorAgeInMinutes)).hours.toString();
						
						sage = sensorDays + "d " + sensorHours + "h";
					}
				}
				else
				{
					var nowDate:Date = new Date();
					sensorDays = TimeSpan.fromDates(sensorStartDate, nowDate).days.toString();
					sensorHours = TimeSpan.fromDates(sensorStartDate, nowDate).hours.toString();
					
					sage = sensorDays + "d " + sensorHours + "h";
				}
			}
			
			return sage;
		}
		
		public static function getTransmitterBattery():Object
		{
			var transmitterBatteryColor:uint = 0xEEEEEE;
			var transmitterBattery:String;
			var transmitterValue:Number = Number.NaN;
			var transmitterNameValue:String = CGMBlueToothDevice.known() ? CGMBlueToothDevice.name : ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown');
			
			if (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6())
			{
				var voltageAValue:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VOLTAGEA);
				if (voltageAValue == "unknown" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) voltageAValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				
				var voltageBValue:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VOLTAGEB);
				if (voltageBValue == "unknown" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) voltageBValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				
				var resistanceValue:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_RESIST);
				if (resistanceValue == "unknown" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) resistanceValue = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				
				transmitterBattery = "A: " + voltageAValue + ", B: " + voltageBValue + ", R: " + resistanceValue;
				
				if (!isNaN(Number(voltageAValue)))
				{
					if (CGMBlueToothDevice.isDexcomG5())
					{
						if (Number(voltageAValue) < G5G6Model.TransmitterStatus.LOW_BATTERY_WARNING_LEVEL_VOLTAGEA_G5)
							transmitterBatteryColor = 0xff1c1c;
						else
							transmitterBatteryColor = 0x4bef0a;
					}
					else if (CGMBlueToothDevice.isDexcomG6())
					{
						if (Number(voltageAValue) < G5G6Model.TransmitterStatus.LOW_BATTERY_WARNING_LEVEL_VOLTAGEA_G6)
							transmitterBatteryColor = 0xff1c1c;
						else
							transmitterBatteryColor = 0x4bef0a;
					}
				}
			}
			else if (CGMBlueToothDevice.isDexcomG4()) 
			{
				transmitterBattery = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G4_TRANSMITTER_BATTERY_VOLTAGE);
				
				if (transmitterBattery.toUpperCase() == "0" || transmitterBattery.toUpperCase() == "UNKNOWN" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) 
					transmitterBattery = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				
				transmitterValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G4_TRANSMITTER_BATTERY_VOLTAGE))
				
				if (!isNaN(transmitterValue))
				{
					if (transmitterValue >= 213)
						transmitterBatteryColor = 0x4bef0a;
					else if (transmitterValue > 210)
						transmitterBatteryColor = 0xff671c;
					else
						transmitterBatteryColor = 0xff1c1c;
				}
					
			}
			else if (CGMBlueToothDevice.isBlueReader())
			{
				transmitterBattery = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL);
				
				if (transmitterBattery == "0" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) 
					transmitterBattery = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				else
					transmitterBattery = String(Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL)))  + "%";
				
				transmitterValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL))
				
				if (!isNaN(transmitterValue))
				{
					if (transmitterValue > 40)
						transmitterBatteryColor = 0x4bef0a;
					else if (transmitterValue > 20)
						transmitterBatteryColor = 0xff671c;
					else
						transmitterBatteryColor = 0xff1c1c;
				}
			}
			else if (CGMBlueToothDevice.isTransmiter_PL())
			{
				transmitterBattery = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL);
				
				if (transmitterBattery == "0" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) 
					transmitterBattery = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				else
					transmitterBattery = String(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL) + "%");
				
				transmitterValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL))
				
				if (!isNaN(transmitterValue))
				{
					if (transmitterValue > 40)
						transmitterBatteryColor = 0x4bef0a;
					else if (transmitterValue > 20)
						transmitterBatteryColor = 0xff671c;
					else
						transmitterBatteryColor = 0xff1c1c;
				}
			}
			else if (CGMBlueToothDevice.isMiaoMiao())
			{
				transmitterBattery = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_MIAOMIAO_BATTERY_LEVEL);
				
				if (transmitterBattery == "0" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) 
					transmitterBattery = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				else
					transmitterBattery = String(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_MIAOMIAO_BATTERY_LEVEL) + "%");
				
				transmitterValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_MIAOMIAO_BATTERY_LEVEL))
				
				if (!isNaN(transmitterValue))
				{
					if (transmitterValue > 40)
						transmitterBatteryColor = 0x4bef0a;
					else if (transmitterValue > 20)
						transmitterBatteryColor = 0xff671c;
					else
						transmitterBatteryColor = 0xff1c1c;
				}
			}
			else if (CGMBlueToothDevice.isBluKon())
			{
				transmitterBattery = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL) + "%";
				if (transmitterBattery == "0" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown') || !InterfaceController.peripheralConnected)
					transmitterBattery = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				
				transmitterValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUKON_BATTERY_LEVEL))
				
				if (!isNaN(transmitterValue))
				{
					if (transmitterValue > 40)
						transmitterBatteryColor = 0x4bef0a;
					else if (transmitterValue > 20)
						transmitterBatteryColor = 0xff671c;
					else
						transmitterBatteryColor = 0xff1c1c;
				}
			}
			else if (CGMBlueToothDevice.isLimitter())
			{
				transmitterBattery = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL);
				if (transmitterBattery == "0" || transmitterNameValue == ModelLocator.resourceManagerInstance.getString('transmitterscreen','device_unknown')) 
					transmitterBattery = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');
				else
					transmitterBattery = String((Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL)))/1000);
				
				transmitterValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BLUEREADER_BATTERY_LEVEL))
				
				if (!isNaN(transmitterValue))
				{
					if (transmitterValue > 40)
						transmitterBatteryColor = 0x4bef0a;
					else if (transmitterValue > 20)
						transmitterBatteryColor = 0xff671c;
					else
						transmitterBatteryColor = 0xff1c1c;
				}
			}
			
			if (transmitterBattery == null || transmitterBattery == "")
				transmitterBattery = ModelLocator.resourceManagerInstance.getString('transmitterscreen','battery_unknown');	
			
			return { level: transmitterBattery, color: transmitterBatteryColor };
		}
		
		public static function calculateAdvancedStats(readingsList:Array, timeInRangePercentage:Number):Object
		{
			var totalReadings:uint = readingsList.length;
			
			var GVI:Number = Number.NaN;
			var PGS:Number = Number.NaN;
			var TDC:Number = Number.NaN;
			var TDCHourly:Number = Number.NaN;
			var timeInT1:Number = Number.NaN;
			var timeInT2:Number = Number.NaN;
			
			if (totalReadings > 0)
			{
				var lowTreshold:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));;
				var highTreshold:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
				var t1:Number = 6;
				var t2:Number = 11;
				var t1count:Number = 0;
				var t2count:Number = 0;
				var total:Number = 0;
				var events:Number = 0;
				var GVITotal:Number = 0;
				var GVIIdeal:Number = 0;
				var usedRecords:Number = 0;
				var glucoseTotal:Number = 0;
				var deltaTotal:Number = 0;
				var daysTotal:Number = (readingsList[totalReadings - 1].timestamp - readingsList[0].timestamp) / TimeSpan.TIME_24_HOURS;
				
				for (var i:int = 0; i < totalReadings - 2; i++) 
				{
					var currentReading:Number = readingsList[i].calculatedValue;
					var nextReading:Number = readingsList[i + 1].calculatedValue;
					var delta:Number = Math.abs(nextReading - currentReading);
					
					events += 1;
					usedRecords += 1;
					deltaTotal += delta;
					total += delta;
					if (delta >= t1) t1count += 1;
					if (delta >= t2) t2count += 1;
					GVITotal += Math.sqrt(25 + Math.pow(delta, 2));  
					glucoseTotal += currentReading;
				}
				
				var GVIDelta:Number = Math.abs(readingsList[totalReadings-1].calculatedValue - readingsList[0].calculatedValue); //var GVIDelta:Number = Math.floor(readingsList[0], readingsList[totalReadings-1]);
				GVIIdeal = Math.sqrt(Math.pow(usedRecords*5,2) + Math.pow(GVIDelta,2));
				GVI = Math.round(GVITotal / GVIIdeal * 100) / 100;
				var glucoseMean:Number = Math.floor(glucoseTotal / usedRecords);
				var tirMultiplier:Number = timeInRangePercentage / 100.0;
				PGS = Math.round(GVI * glucoseMean * (1-tirMultiplier) * 100) / 100;
				TDC = deltaTotal / daysTotal;
				TDCHourly = TDC / 24;
				timeInT1 = Number(Math.round(100 * t1count / events).toFixed(1));
				timeInT2 = Number(Math.round(100 * t2count / events).toFixed(1));
				
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true") 
				{
					TDC = TDC / 18.0182;
					TDCHourly = TDCHourly / 18.0182;
				}
				
				TDC = Math.round(TDC * 100) / 100;
				TDCHourly = Math.round(TDCHourly * 100) / 100;
			}
			
			return {
				GVI: GVI,
				PGS: PGS,
				meanTotalDailyChange: TDC,
				meanHourlyChange: TDCHourly,
				timeInFluctuation: timeInT1,
				timeInRapidFluctuation: timeInT2,
				glucoseMean: glucoseMean
			}
		}
		
		public static function getCurrentBasalForPill():String
		{
			var userType:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI);
			var now:Number = new Date().valueOf();
			var basalResult:String = "0.000" + (userType == "pump" ? "U" : ModelLocator.resourceManagerInstance.getString('treatments','basal_units_per_hour'));
			
			if (userType == "pump")
			{
				var pumpBasalProperties:Object = ProfileManager.getPumpBasalData(now, CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Nightscout", Number.NaN);
				if (pumpBasalProperties != null)
				{
					var currentPumpBasal:Number = pumpBasalProperties.tempBasalAmount != null && !isNaN(pumpBasalProperties.tempBasalAmount) ? pumpBasalProperties.tempBasalAmount : 0;
					var isTempBasal:Boolean = pumpBasalProperties.tempBasalTreatment != null;
					
					if (isTempBasal)
					{
						basalResult = "T: " + (Math.round(currentPumpBasal * 1000) / 1000) + "U";
					}
					else
					{
						basalResult = (Math.round(currentPumpBasal * 1000) / 1000) + "U";
					}
				}
			}
			else if (userType == "mdi")
			{
				var mdiBasalProperties:Object = ProfileManager.getMDIBasalData(now);
				if (mdiBasalProperties != null)
				{
					var currentMDIBasal:Number = mdiBasalProperties.mdiBasalAmount != null && !isNaN(mdiBasalProperties.mdiBasalAmount) ? mdiBasalProperties.mdiBasalAmount : 0;
					var currentMDIDuration:Number = mdiBasalProperties.mdiBasalDuration != null && !isNaN(mdiBasalProperties.mdiBasalDuration) ? mdiBasalProperties.mdiBasalDuration : 1;
					basalResult = (Math.round((currentMDIBasal / (currentMDIDuration / 60)) * 1000) / 1000) + ModelLocator.resourceManagerInstance.getString('treatments','basal_units_per_hour');
				}
			}
			
			return basalResult;
		}
		
		public static function getTotalDailyBasalRate():Number
		{
			var userBasalRates:Array = ProfileManager.basalRatesList;
			var total:Number = 0;
			
			for (var i:Number = 0, len:uint = userBasalRates.length; i < len; i++) 
			{
				var basalRate1:BasalRate = userBasalRates[i];
				var basalRate2:BasalRate = userBasalRates[(i+1)%len];
				
				if (basalRate1 != null && basalRate2 != null)
				{
					var time1:Date = new Date();
					time1.hours = basalRate1.startHours;
					time1.minutes = basalRate1.startMinutes;
					time1.seconds = 0;
					time1.milliseconds = 0;
					
					var time2:Date = new Date();
					time2.hours = i < len - 1 ? basalRate2.startHours : 23;
					time2.minutes = i < len - 1 ? basalRate2.startMinutes : 59;
					time2.seconds = 0;
					time2.milliseconds = 0;
					
					var value:Number = basalRate1.basalRate;
					
					total += (TimeSpan.fromDates(time1, time2).totalMinutes + (i < len - 1 ? 0 : 1)) * value / 60;
				}
			}
			
			return total;
		}
	}
}