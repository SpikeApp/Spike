package services
{
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	import database.Database;
	import database.LocalSettings;
	
	import events.CalibrationServiceEvent;
	import events.FollowerEvent;
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	import events.TreatmentsEvent;
	
	import model.ModelLocator;
	
	import treatments.ProfileManager;
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import utils.TimeSpan;
	import utils.Trace;
	
	public class HealthKitService
	{
		//Properties
		private static var _instance:HealthKitService = new HealthKitService();
		private static var hkTreatmentsList:Dictionary = new Dictionary();
		
		//Variables
		private static var initialStart:Boolean = true;
		
		public function HealthKitService()
		{
			if (_instance != null) {
				throw new Error("HealthKitService class constructor can not be used");	
			}
		}
		
		public static function init():void 
		{
			if (!initialStart)
				return;
			else
				initialStart = false;
			
			//Get existing HK treatments from DB
			var now:Number = new Date().valueOf();
			var hkTreatments:Array = Database.getHealthkitTreatmentsSynchronous(now - TimeSpan.TIME_24_HOURS, now);
			var numTreatments:uint = hkTreatments.length;
			for (var i:int = 0; i < numTreatments; i++) 
			{
				var hkTreatment:Object = hkTreatments[i] as Object;
				hkTreatmentsList[hkTreatment.id] = hkTreatment.timestamp;
			}
			
			//Delete old HK treatments from DB (older than 24H)
			Database.deleteOldHealthkitTreatments();
			
			//Set event listeners
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			LocalSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, localSettingChanged);
			TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_RECEIVED, bgReadingReceived);
			NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, bgReadingReceived);
			DexcomShareService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, bgReadingReceived);
			CalibrationService.instance.addEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, processInitialBackfillData);
			TreatmentsManager.instance.addEventListener(TreatmentsEvent.TREATMENT_ADDED, onTreatmentAdded);
			TreatmentsManager.instance.addEventListener(TreatmentsEvent.BASAL_TREATMENT_ADDED, onTreatmentAdded);
			
			//Init ANE
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) == "true") {
				SpikeANE.initHealthKit();
			}
		}
		
		private static function onTreatmentAdded(e:TreatmentsEvent):void
		{
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) == "false")
				return;
			
			var treatment:Treatment = e.treatment;
			if (treatment != null && hkTreatmentsList[treatment.ID] == null)
			{
				//Store in HealthKit
				var treatmentAdded:Boolean = false;
				var bolusInsulinToStore:Number = Math.round((treatment.type != Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT ? treatment.insulinAmount : treatment.getTotalInsulin()) * 100) / 100;
				var carbsToStore:Number = treatment.carbs;
				var basalInsulinToStore:Number = 0;
				
				if ((treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS || treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT) && treatment.insulinAmount > 0)
				{
					Trace.myTrace("HealthKitService.as", "Treatment Type: Bolus, Quantity: " + bolusInsulinToStore + "U, Time: " + new Date(treatment.timestamp).toString());
					SpikeANE.storeInsulin(bolusInsulinToStore, true, treatment.timestamp);
					treatmentAdded = true;
				}
				else if (treatment.type == Treatment.TYPE_CARBS_CORRECTION && treatment.carbs > 0)
				{
					Trace.myTrace("HealthKitService.as", "Treatment Type: Carbs, Quantity: " + carbsToStore + "g, Time: " + new Date(treatment.timestamp).toString());
					SpikeANE.storeCarbInHealthKitGram(carbsToStore, treatment.timestamp);
					treatmentAdded = true;
				}
				else if (treatment.type == Treatment.TYPE_MEAL_BOLUS || treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
				{
					Trace.myTrace("HealthKitService.as", "Treatment Type: Meal, Insulin Quantity: " + bolusInsulinToStore+ "U, Carbs Quantity: " + carbsToStore + "g, Time: " + new Date(treatment.timestamp).toString());
					if (bolusInsulinToStore > 0)
					{
						SpikeANE.storeInsulin(bolusInsulinToStore, true, treatment.timestamp);
						treatmentAdded = true;
					}
					if (carbsToStore > 0)
					{
						SpikeANE.storeCarbInHealthKitGram(carbsToStore, treatment.timestamp);
						treatmentAdded = true;
					}
				}
				else if (treatment.type == Treatment.TYPE_TEMP_BASAL)
				{
					if (treatment.isBasalAbsolute)
					{
						basalInsulinToStore = Math.round(treatment.basalAbsoluteAmount * 1000) / 1000;
					}
					else if (treatment.isBasalRelative)
					{
						var basalRate:Number = ProfileManager.getBasalRateByTime(treatment.timestamp);
						basalInsulinToStore = basalRate * (100 + treatment.basalPercentAmount) / 100;
					}
					
					if (isNaN(basalInsulinToStore) || treatment.isTempBasalEnd)
					{
						basalInsulinToStore = 0;
					}
					
					SpikeANE.storeInsulin(basalInsulinToStore, false, treatment.timestamp);
				}
				else if (treatment.type == Treatment.TYPE_MDI_BASAL)
				{
					basalInsulinToStore = Math.round(treatment.basalAbsoluteAmount * 1000) / 1000;
					
					if (isNaN(basalInsulinToStore))
					{
						basalInsulinToStore = 0;
					}
					
					SpikeANE.storeInsulin(basalInsulinToStore, false, treatment.timestamp);
				}
				
				//Add treatment to memory and database to avoid duplicates on the next run
				if (treatmentAdded)
				{
					hkTreatmentsList[treatment.ID] = treatment.timestamp;
					Database.insertHealthkitTreatmentSynchronous(treatment.ID, treatment.timestamp);
				}
			}
		}
		
		private static function localSettingChanged(event:SettingsServiceEvent):void {
			if (event.data == LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) {
				if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) == "true") {
					//doesn't matter if it's already initiated
					SpikeANE.initHealthKit();
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
			
			SpikeANE.storeBGInHealthKitMgDl(bgReading.calculatedValue, bgReading.timestamp);
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_HEALTHKIT_SYNC_TIMESTAMP, String(bgReading.timestamp));
		}
		
		private static function processInitialBackfillData(e:Event):void
		{
			if (!CGMBlueToothDevice.isMiaoMiao() || LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) == "false") //Only for backfil
				return
			
			var loopLength:int = ModelLocator.bgReadings.length
			for (var i:int = 0; i < loopLength; i++) 
			{
				var bgReading:BgReading = ModelLocator.bgReadings[i];
				if (bgReading != null && bgReading.calculatedValue != 0 && bgReading.calibration == null && bgReading.timestamp > Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HEALTHKIT_SYNC_TIMESTAMP)))
				{
					SpikeANE.storeBGInHealthKitMgDl(bgReading.calculatedValue, bgReading.timestamp);
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_HEALTHKIT_SYNC_TIMESTAMP, String(bgReading.timestamp));
				}
			}
		}
		
		/**
		 * Stops the service entirely. Useful for database restores
		 */
		private static function onHaltExecution(e:SpikeEvent):void
		{
			Trace.myTrace("HealthKitService.as", "Stopping service...");
			
			stopService();
		}
		
		private static function stopService():void
		{
			LocalSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, localSettingChanged);
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.BGREADING_RECEIVED, bgReadingReceived);
			NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, bgReadingReceived);
			DexcomShareService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, bgReadingReceived);
			CalibrationService.instance.removeEventListener(CalibrationServiceEvent.INITIAL_CALIBRATION_EVENT, processInitialBackfillData);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.TREATMENT_ADDED, onTreatmentAdded);
			
			Trace.myTrace("HealthKitService.as", "Service stopped!");
		}
	}
}