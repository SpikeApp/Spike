package utils
{
	import database.CommonSettings;
	
	import model.ModelLocator;

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
	}
}