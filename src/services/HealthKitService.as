package services
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import databaseclasses.BgReading;
	import databaseclasses.LocalSettings;
	
	import events.SettingsServiceEvent;
	import events.TransmitterServiceEvent;
	
	public class HealthKitService
	{
		private static var _instance:HealthKitService = new HealthKitService(); 
		private static var initialStart:Boolean = true;
		
		public function HealthKitService()
		{
			if (_instance != null) {
				throw new Error("HealthKitService class constructor can not be used");	
			}
		}
		
		public static function init():void {
			if (!initialStart)
				return;
			else
				initialStart = false;
			
			trace("INICIEI HEALTHKIT");
			
			LocalSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, localSettingChanged);
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, bgReadingReceived);
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) == "true") {
				trace("VOU INICIAR HEALTHKIT 1");
				BackgroundFetch.initHealthKit();
			}
		}
		
		private static function localSettingChanged(event:SettingsServiceEvent):void {
			if (event.data == LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) {
				if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) == "true") {
					//doesn't matterif it's already initiated
					trace("VOU INICIAR HEALTHKIT 2");
					BackgroundFetch.initHealthKit();
				}
			}
		}
		
		private static function bgReadingReceived(be:TransmitterServiceEvent):void {
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) == "false") {
				return;
			}
			
			var bgReading:BgReading = BgReading.lastNoSensor();
			
			if (bgReading == null)
				return;
			if (bgReading.calculatedValue == 0) {
				return;
			}
			if ((new Date()).valueOf() - bgReading.timestamp > 4 * 60 * 1000) {
				return;
			}
			
			trace("VOU METER BG READING NO HEALTHKIT");
			BackgroundFetch.storeBGInHealthKitMgDl(bgReading.calculatedValue);
		}
	}
}