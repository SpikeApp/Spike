package G5G6Model
{
	import database.CommonSettings;
	
	import utils.UniqueId;

	public class G5G6VersionInfo
	{
		public function G5G6VersionInfo()
		{
		}
		
		public static function getG5G6VersionInfo():VersionRequestRxMessage {
			return new VersionRequestRxMessage(utils.UniqueId.hexStringToByteArray(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_G6_VERSION_INFO)));
		}
	}
}