package services
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.events.Event;
	
	import database.BgReading;
	import database.BlueToothDevice;
	import database.CommonSettings;
	import database.LocalSettings;
	
	import events.CalibrationServiceEvent;
	import events.FollowerEvent;
	import events.SettingsServiceEvent;
	import events.TransmitterServiceEvent;
	import events.TreatmentsEvent;
	
	import model.ModelLocator;
	
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import utils.Trace;
	
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
			
			LocalSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, localSettingChanged);
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, bgReadingReceived);
			NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, bgReadingReceived);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, processInitialBackfillData);
			TreatmentsManager.instance.addEventListener(TreatmentsEvent.TREATMENT_ADDED, onTreatmentAdded);
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) == "true") {
				BackgroundFetch.initHealthKit();
			}
		}
		
		private static function onTreatmentAdded(e:TreatmentsEvent):void
		{
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) == "false")
				return;
			
			var treatment:Treatment = e.treatment;
			if (treatment != null)
			{
				//Store in HealthKit
				if (treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS)
				{
					Trace.myTrace("HealthKitService.as", "Treatment Type: Bolus, Quantity: " + treatment.insulinAmount + "U, Time: " + new Date(treatment.timestamp).toString());
					BackgroundFetch.storeInsulin(treatment.insulinAmount, true, treatment.timestamp);
				}
				else if (treatment.type == Treatment.TYPE_CARBS_CORRECTION)
				{
					Trace.myTrace("HealthKitService.as", "Treatment Type: Carbs, Quantity: " + treatment.carbs + "g, Time: " + new Date(treatment.timestamp).toString());
					BackgroundFetch.storeCarbInHealthKitGram(treatment.carbs, treatment.timestamp);
				}
				else if (treatment.type == Treatment.TYPE_MEAL_BOLUS)
				{
					Trace.myTrace("HealthKitService.as", "Treatment Type: Meal, Insulin Quantity: " + treatment.insulinAmount + "U, Carbs Quantity: " + treatment.carbs + "g, Time: " + new Date(treatment.timestamp).toString());
					BackgroundFetch.storeInsulin(treatment.insulinAmount, true, treatment.timestamp);
					BackgroundFetch.storeCarbInHealthKitGram(treatment.carbs, treatment.timestamp);
				}
			}
		}
		
		private static function localSettingChanged(event:SettingsServiceEvent):void {
			if (event.data == LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) {
				if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) == "true") {
					//doesn't matter if it's already initiated
					BackgroundFetch.initHealthKit();
				}
			}
		}
		
		private static function bgReadingReceived(be:Event):void {
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) == "false") {
				return;
			}
			
			var bgReading:BgReading = BgReading.lastNoSensor();
			
			if (bgReading == null || bgReading.calculatedValue == 0 || (bgReading.calculatedValue == 0 && bgReading.calibration == null) || bgReading.timestamp <= Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HEALTHKIT_SYNC_TIMESTAMP)))
				return;
			
			BackgroundFetch.storeBGInHealthKitMgDl(bgReading.calculatedValue, bgReading.timestamp);
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_HEALTHKIT_SYNC_TIMESTAMP, String(bgReading.timestamp));
		}
		
		private static function processInitialBackfillData(e:Event):void
		{
			if (!BlueToothDevice.isMiaoMiao() || LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) == "false") //Only for backfil
				return
			
			var loopLength:int = ModelLocator.bgReadings.length
			for (var i:int = 0; i < loopLength; i++) 
			{
				var bgReading:BgReading = ModelLocator.bgReadings[i];
				if (bgReading != null && bgReading.calculatedValue != 0 && bgReading.calibration == null && bgReading.timestamp > Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HEALTHKIT_SYNC_TIMESTAMP)))
				{
					BackgroundFetch.storeBGInHealthKitMgDl(bgReading.calculatedValue, bgReading.timestamp);
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_HEALTHKIT_SYNC_TIMESTAMP, String(bgReading.timestamp));
				}
			}
		}
	}
}