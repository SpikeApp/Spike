package utils
{
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.LocalSettings;

	public class BadgeBuilder
	{
		private static const MMOL_MULTIPLIER:int = 10;
		private static const HIGH_VALUE:int = 400;
		private static const LOW_VALUE:int = 38;		
		
		public function BadgeBuilder()
		{
			throw new Error("BadgeBuilder class is not meant to be instantiated!");
		}
		
		public static function formatBadgeNumber(preBadgeNumber:Number, isMgDl:Boolean):int
		{			
			if (isMgDl)
				return preBadgeNumber;
			else
			{
				if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_BADGE_MMOL_MULTIPLIER_ON) == "true")
					return Math.round(preBadgeNumber * MMOL_MULTIPLIER);
				else
					return Math.round(preBadgeNumber);
			}			
		}
		
		public static function getAppBadge():int
		{
			var badgeNumber:int = 0;
			
			if ((Calibration.allForSensor().length >= 2 || CGMBlueToothDevice.isFollower()) && LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_APP_BADGE) == "true") 
			{
				var latestReading:BgReading;
				if (!CGMBlueToothDevice.isFollower())
					latestReading = BgReading.lastNoSensor();
				else
					latestReading = BgReading.lastWithCalculatedValue();
				
				var now:Number = new Date().valueOf();
				
				if (latestReading != null && latestReading.calculatedValue != 0 && now - latestReading.timestamp < TimeSpan.TIME_4_MINUTES_30_SECONDS)
				{
					var isMgDl:Boolean = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true";					
					var preBadgeNumber:String = BgGraphBuilder.unitizedString(latestReading.calculatedValue, isMgDl);
					
					if (preBadgeNumber == "HIGH")
					{
						badgeNumber = formatBadgeNumber(isMgDl ? HIGH_VALUE : BgReading.mgdlToMmol(HIGH_VALUE), isMgDl);
					}
					else if (preBadgeNumber == "LOW" || preBadgeNumber == "??0" || preBadgeNumber == "?SN" || preBadgeNumber == "??2" || preBadgeNumber == "?NA" || preBadgeNumber == "?NC" || preBadgeNumber == "?CD" || preBadgeNumber == "?AD" || preBadgeNumber == "?RF" || preBadgeNumber == "???")
					{
						badgeNumber = formatBadgeNumber(isMgDl ? LOW_VALUE : BgReading.mgdlToMmol(LOW_VALUE), isMgDl);
					}
					else
					{
						badgeNumber = formatBadgeNumber(Number(preBadgeNumber), isMgDl);
					}
				}
			}
			return badgeNumber;
		}
	}
}