package utils
{
	import database.BgReading;
	import database.CommonSettings;
	
	import model.ModelLocator;

	[ResourceBundle("generalsettingsscreen")]
	
	public class GlucoseHelper
	{
		private static const TIME_6_MINUTES:int = 6 * 60 * 1000;
		
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
					if (new Date().valueOf() - lastReading.timestamp < TIME_6_MINUTES && lastReading.timestamp - middleReading.timestamp < TIME_6_MINUTES && middleReading.timestamp - firstReading.timestamp < TIME_6_MINUTES)
					{
						//All readings are not more than 6 minutes apart
						var lastReadingSlope:Number = Math.abs(lastReading.calculatedValue - middleReading.calculatedValue);
						var middleReadingSlope:Number = Math.abs(middleReading.calculatedValue - firstReading.calculatedValue);
						
						if (lastReadingSlope <= 3 && middleReadingSlope <= 3)
						{
							//Not going up or down by more than 3mg/dL
							var highThreshold:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
							var lowThreshold:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
							
							if ((lastReading.calculatedValue < highThreshold && lastReading.calculatedValue > lowThreshold) && (middleReading.calculatedValue < highThreshold && middleReading.calculatedValue > lowThreshold) && (firstReading.calculatedValue < highThreshold && firstReading.calculatedValue > lowThreshold))
							{
								//All readings are within "in-range" threshold. Optimal calibration condition has been found!
								optimalCalibrationCondition = true;
							}
						}
					}
				}
			}
			
			return optimalCalibrationCondition;
		}
	}
}