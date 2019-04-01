package utils
{
	import database.BgReading;
	import database.CommonSettings;
	
	import model.ModelLocator;
	
	import ui.chart.helpers.GlucoseFactory;

	[ResourceBundle("generalsettingsscreen")]
	
	public class GlucoseHelper
	{
		public static function getGlucoseUnit():String
		{
			var glucoseUnit:String = "";
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
				glucoseUnit = ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','mgdl');
			else
				glucoseUnit = ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','mmol');
			
			return glucoseUnit;
		}
		
		public static function isOptimalConditionToCalibrate():Boolean
		{
			var optimalCalibrationCondition:Boolean = false;
			
			if (ModelLocator.bgReadings != null && ModelLocator.bgReadings.length >= 3)
			{
				//We have at least 3 readings
				var lastReading:BgReading = ModelLocator.bgReadings[ModelLocator.bgReadings.length - 1] as BgReading;
				var middleReading:BgReading = ModelLocator.bgReadings[ModelLocator.bgReadings.length - 2] as BgReading;
				var firstReading:BgReading = ModelLocator.bgReadings[ModelLocator.bgReadings.length - 3] as BgReading;
				
				if (lastReading != null && lastReading.calculatedValue != 0 && middleReading != null && middleReading.calculatedValue != 0 && firstReading != null && firstReading.calculatedValue != 0)
				{
					//Last 3 readings are valid
					if (new Date().valueOf() - lastReading.timestamp < TimeSpan.TIME_6_MINUTES && lastReading.timestamp - middleReading.timestamp < TimeSpan.TIME_6_MINUTES && middleReading.timestamp - firstReading.timestamp < TimeSpan.TIME_6_MINUTES)
					{
						//All readings are not more than 6 minutes apart
						var lastReadingSlope:Number = Math.abs(lastReading.calculatedValue - middleReading.calculatedValue);
						var middleReadingSlope:Number = Math.abs(middleReading.calculatedValue - firstReading.calculatedValue);
						
						if (lastReadingSlope <= 3 && middleReadingSlope <= 3)
						{
							//Not going up or down by more than 3mg/dL
							var highThreshold:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK)) * 1.25;
							var lowThreshold:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
							
							if ((lastReading.calculatedValue < highThreshold && lastReading.calculatedValue > lowThreshold) && (middleReading.calculatedValue < highThreshold && middleReading.calculatedValue > lowThreshold) && (firstReading.calculatedValue < highThreshold && firstReading.calculatedValue > lowThreshold))
							{
								//All readings are within "in-range" threshold. Optimal calibration condition has been reached!
								optimalCalibrationCondition = true;
							}
						}
					}
				}
			}
			
			return optimalCalibrationCondition;
		}
		
		public static function calculateLatestDelta(trimWhiteSpace:Boolean = false, textToSpeechEnabled:Boolean = false):String
		{
			var delta:String = "unknown";	
			if (ModelLocator.bgReadings != null && ModelLocator.bgReadings.length >= 2)
			{
				var lastBgReading:BgReading = ModelLocator.bgReadings[ModelLocator.bgReadings.length - 1] as BgReading;
				var previousBgReading:BgReading = ModelLocator.bgReadings[ModelLocator.bgReadings.length - 2] as BgReading;
				
				if (lastBgReading != null && lastBgReading.calculatedValue != 0 && previousBgReading != null && previousBgReading.calculatedValue != 0)
				{
					var lastBgReadingProperties:Object = GlucoseFactory.getGlucoseOutput(lastBgReading.calculatedValue);
					var lastBgReadingGlucoseValueFormatted:Number = lastBgReadingProperties.glucoseValueFormatted;
					
					var previousBgReadingProperties:Object = GlucoseFactory.getGlucoseOutput(previousBgReading.calculatedValue);
					var previousBgReadingGlucoseValueFormatted:Number = previousBgReadingProperties.glucoseValueFormatted;
					
					delta = GlucoseFactory.getGlucoseSlope
					(
						previousBgReading.calculatedValue,
						previousBgReadingGlucoseValueFormatted,
						lastBgReading.calculatedValue,
						lastBgReadingGlucoseValueFormatted,
						textToSpeechEnabled
					);
				}
			}
			
			if (trimWhiteSpace) 
				delta.replace(/[\s\r\n]+/gim, '');
			
			return delta;
		}
		
		public static function isGlucoseChangingFast(value:Number, direction:String = "down"):Boolean
		{
			var isFastChanging:Boolean = false;
			
			if (ModelLocator.bgReadings != null && ModelLocator.bgReadings.length >= 3)
			{
				//We have at least 3 readings
				var lastReading:BgReading = ModelLocator.bgReadings[ModelLocator.bgReadings.length - 1] as BgReading;
				var middleReading:BgReading = ModelLocator.bgReadings[ModelLocator.bgReadings.length - 2] as BgReading;
				var firstReading:BgReading = ModelLocator.bgReadings[ModelLocator.bgReadings.length - 3] as BgReading;
				
				//Check Thresholds
				var isThresholdsEnabled:Boolean;
				var highThreshold:Number;
				var lowThreshold:Number;
				if (direction == "up")
				{
					isThresholdsEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_RISE_ALERT_GLUCOSE_THRESHOLDS_ON) == "true";
					highThreshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_RISE_ALERT_HIGH_GLUCOSE_THRESHOLD));
					lowThreshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_RISE_ALERT_LOW_GLUCOSE_THRESHOLD));
				}
				else if (direction == "down")
				{
					isThresholdsEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_DROP_ALERT_GLUCOSE_THRESHOLDS_ON) == "true";
					highThreshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_DROP_ALERT_HIGH_GLUCOSE_THRESHOLD));
					lowThreshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_DROP_ALERT_LOW_GLUCOSE_THRESHOLD));
				}
				
				if (lastReading != null && lastReading.calculatedValue != 0 && middleReading != null && middleReading.calculatedValue != 0 && firstReading != null && firstReading.calculatedValue != 0)
				{
					//Last 3 readings are valid
					if (isThresholdsEnabled && !isNaN(highThreshold) && !isNaN(lowThreshold) && (lastReading.calculatedValue < lowThreshold || lastReading.calculatedValue > highThreshold))
					{
						//Reading is outside user defined thresholds
						isFastChanging = false;
					}	
					else if (new Date().valueOf() - lastReading.timestamp < TimeSpan.TIME_9_MINUTES && lastReading.timestamp - middleReading.timestamp < TimeSpan.TIME_9_MINUTES && middleReading.timestamp - firstReading.timestamp < TimeSpan.TIME_9_MINUTES)
					{
						//All readings are not more than 6 minutes apart
						var lastReadingSlope:Number = lastReading.calculatedValue - middleReading.calculatedValue;
						var middleReadingSlope:Number = middleReading.calculatedValue - firstReading.calculatedValue;
						
						if (direction == "down")
						{
							if (middleReadingSlope <= -1 * Math.abs(value) && lastReadingSlope <= -1 * Math.abs(value))
							{
								//It's dropping fast
								isFastChanging = true;
							}
						}
						else if (direction == "up")
						{
							if (middleReadingSlope >= Math.abs(value) && lastReadingSlope >= Math.abs(value))
							{
								//It's rising fast
								isFastChanging = true;
							}
						}
					}
				}
			}
			
			return isFastChanging;
		}
	}
}