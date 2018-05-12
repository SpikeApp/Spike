package G5Model
{
	import database.CommonSettings;
	
	import utils.UniqueId;

	public class G5VersionInfo
	{
		public function G5VersionInfo()
		{
		}
		
		public static function getG5VersionInfo():VersionRequestRxMessage {
			return new VersionRequestRxMessage(utils.UniqueId.hexStringToByteArray(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_G5_VERSION_INFO)));
		}
	}
}