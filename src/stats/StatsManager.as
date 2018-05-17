package stats
{
	import database.BgReading;
	import database.BlueToothDevice;
	import database.CommonSettings;
	import database.Database;
	
	import model.ModelLocator;

	public class StatsManager
	{
		/* Constants */
		private static const TIME_24_HOURS:int = 24 * 60 * 60 * 1000;
		private static const TIME_30_SECONDS:int = 30 * 1000;
		
		public function StatsManager()
		{
			throw new Error("StatsManager is not meant to be instantiated!");
		}
		
		public static function getBasicUserStats():BasicUserStats
		{
			var now:Number = new Date().valueOf();
			var lowTreshold:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));;
			var highTreshold:Number = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
			
			if (!BlueToothDevice.isFollower())
			{
				var masterUserStats:BasicUserStats = Database.getBasicUserStats();
				if (masterUserStats == null)
					masterUserStats = new BasicUserStats();
				
				return masterUserStats;
			}
			else
			{
				var followerUserStats:BasicUserStats = new BasicUserStats();
				var high:int = 0;
				var inRange:int = 0;
				var low:int = 0;
				var dataLength:int = ModelLocator.bgReadings.length;
				var realReadingsNumber:int = 0;
				var totalGlucose:Number = 0;
				
				//Calculations
				for (var i:int = 0; i < dataLength; i++) 
				{
					var bgReading:BgReading = ModelLocator.bgReadings[i];
					
					if (now - bgReading.timestamp > TIME_24_HOURS - TIME_30_SECONDS || bgReading.calculatedValue == 0)
						continue;
					
					var glucoseValue:Number = Number(bgReading.calculatedValue);
					if(glucoseValue >= highTreshold)
						high += 1;
					else if (glucoseValue > lowTreshold && glucoseValue < highTreshold)
						inRange += 1;
					else if (glucoseValue <= lowTreshold)
						low += 1;
					
					totalGlucose += glucoseValue;
					realReadingsNumber++;
				}
				
				followerUserStats.numReadingsHigh = high;
				followerUserStats.numReadingsLow = low;
				followerUserStats.numReadingsInRange = inRange;
				followerUserStats.percentageHigh = (high * 100) / realReadingsNumber;
				followerUserStats.percentageHighRounded = (( followerUserStats.percentageHigh * 10 + 0.5)  >> 0) / 10;
				followerUserStats.percentageInRange = (inRange * 100) / realReadingsNumber;
				followerUserStats.percentageInRangeRounded = (( followerUserStats.percentageInRange * 10 + 0.5)  >> 0) / 10;
				var preLow:Number = Math.round((low * 100) / realReadingsNumber) * 10 / 10;
				if ( preLow != 0 && !isNaN(preLow))
				{
					followerUserStats.percentageLow = 100 - followerUserStats.percentageInRange - followerUserStats.percentageHigh;
					followerUserStats.percentageLowRounded = Math.round ((100 - followerUserStats.percentageInRangeRounded - followerUserStats.percentageHighRounded) * 10) / 10;
				}
				
				//Overcome AS3 number precision limitation
				if (followerUserStats.percentageHighRounded == 0 && followerUserStats.percentageLowRounded == 0)
				{
					followerUserStats.percentageHigh = 0;
					followerUserStats.percentageLow = 0;
					followerUserStats.percentageInRange = 100;
					followerUserStats.percentageInRangeRounded = 100;
				}
				else if (followerUserStats.percentageHighRounded == 0 && followerUserStats.percentageInRangeRounded == 0)
				{
					followerUserStats.percentageHigh = 0;
					followerUserStats.percentageInRange = 0;
					followerUserStats.percentageLow = 100;
					followerUserStats.percentageLowRounded = 100;
				}
				else if (followerUserStats.percentageLowRounded == 0 && followerUserStats.percentageInRangeRounded == 0)
				{
					followerUserStats.percentageLow = 0;
					followerUserStats.percentageInRange = 0;
					followerUserStats.percentageHigh = 100;
					followerUserStats.percentageHighRounded = 100;
				}
				
				followerUserStats.averageGlucose = (( (totalGlucose / realReadingsNumber) * 10 + 0.5)  >> 0) / 10;
				if (realReadingsNumber != 0)
				{
					followerUserStats.a1c = (( ((46.7 + followerUserStats.averageGlucose) / 28.7) * 10 + 0.5)  >> 0) / 10;
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_A1C_IFCC_ON) == "true")
						followerUserStats.a1c = ((((followerUserStats.a1c - 2.15) * 10.929) * 10 + 0.5)  >> 0) / 10; //IFCC support
				}
				followerUserStats.captureRate = ((((realReadingsNumber * 100) / 288) * 10 + 0.5)  >> 0) / 10;
				followerUserStats.numReadingsTotal = realReadingsNumber;
				followerUserStats.numReadingsDay = realReadingsNumber;
				
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true") followerUserStats.averageGlucose = Math.round(((BgReading.mgdlToMmol((followerUserStats.averageGlucose))) * 10)) / 10;

				return followerUserStats;
			}
		}
	}
}