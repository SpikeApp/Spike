package utils
{
	import database.BgReading;
	import database.BlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.LocalSettings;

	public class BadgeBuilder
	{
		private static const TIME_4_MINUTES_30_SECONDS:int = 4.5 * 60 * 1000;
		
		public function BadgeBuilder()
		{
			throw new Error("BadgeBuilder class is not meant to be instantiated!");
		}
		
		public static function getAppBadge():int
		{
			var badgeNumber:int = 0;
			
			if ((Calibration.allForSensor().length >= 2 || BlueToothDevice.isFollower()) && LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_APP_BADGE) == "true") 
			{
				var latestReading:BgReading;
				if (!BlueToothDevice.isFollower())
					latestReading = BgReading.lastNoSensor();
				else
					latestReading = BgReading.lastWithCalculatedValue();
				
				var now:Number = new Date().valueOf();
				
				if (latestReading != null && latestReading.calculatedValue != 0 && now - latestReading.timestamp < TIME_4_MINUTES_30_SECONDS)
				{
					var isMgDl:Boolean = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true";
					var preBadgeNumber:String = BgGraphBuilder.unitizedString(latestReading.calculatedValue, isMgDl);
					
					if (preBadgeNumber == "HIGH")
					{
						if (isMgDl)
							badgeNumber = 400;
						else
							badgeNumber = int(Math.round(BgReading.mgdlToMmol(400)));
					}
					else if (preBadgeNumber == "LOW" || preBadgeNumber == "??0" || preBadgeNumber == "?SN" || preBadgeNumber == "??2" || preBadgeNumber == "?NA" || preBadgeNumber == "?NC" || preBadgeNumber == "?CD" || preBadgeNumber == "?AD" || preBadgeNumber == "?RF" || preBadgeNumber == "???")
					{
						if (isMgDl)
							badgeNumber = 38;
						else
							badgeNumber = int(Math.round(BgReading.mgdlToMmol(38)));
					}
					else
					{
						if (isMgDl)
							badgeNumber = int(preBadgeNumber);
						else
						{
							if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_BADGE_MMOL_MULTIPLIER_ON) == "true")
								badgeNumber = int(Number(preBadgeNumber) * 10);
							else
								badgeNumber = int(Math.round(Number(preBadgeNumber)));
						}
					}
				}
			}
			
			return badgeNumber;
		}
	}
}