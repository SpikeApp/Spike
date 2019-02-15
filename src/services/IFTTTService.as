package services
{
	import flash.events.Event;
	import flash.net.URLRequestMethod;
	
	import cryptography.Keys;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.LocalSettings;
	
	import events.AlarmServiceEvent;
	import events.FollowerEvent;
	import events.HTTPServerEvent;
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	import events.TreatmentsEvent;
	
	import model.ModelLocator;
	
	import network.NetworkConnector;
	import network.httpserver.HttpServer;
	
	import treatments.ProfileManager;
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import ui.chart.helpers.GlucoseFactory;
	
	import utils.BgGraphBuilder;
	import utils.Cryptography;
	import utils.GlucoseHelper;
	import utils.MathHelper;
	import utils.SpikeJSON;
	import utils.TimeSpan;
	import utils.Trace;
	
	[ResourceBundle("alarmservice")]
	[ResourceBundle("treatments")]

	public class IFTTTService
	{
		/* Constants */
		private static const IFTTT_URL:String = "https://maker.ifttt.com/trigger/{trigger}/with/key/{key}";
		
		/* Internal Variables */
		private static var isIFTTTEnabled:Boolean;
		private static var isIFTTTUrgentHighTriggeredEnabled:Boolean;
		private static var isIFTTTHighTriggeredEnabled:Boolean;
		private static var isIFTTTLowTriggeredEnabled:Boolean;
		private static var isIFTTTUrgentLowTriggeredEnabled:Boolean;
		private static var isIFTTTCalibrationTriggeredEnabled:Boolean;
		private static var isIFTTTMissedReadingsTriggeredEnabled:Boolean;
		private static var isIFTTTPhoneMutedTriggeredEnabled:Boolean;
		private static var isIFTTTTransmitterLowBatteryTriggeredEnabled:Boolean;
		private static var isIFTTTGlucoseReadingsEnabled:Boolean;
		private static var isIFTTTUrgentHighSnoozedEnabled:Boolean;
		private static var isIFTTTHighSnoozedEnabled:Boolean;
		private static var isIFTTTLowSnoozedEnabled:Boolean;
		private static var isIFTTTUrgentLowSnoozedEnabled:Boolean;
		private static var isIFTTTCalibrationSnoozedEnabled:Boolean;
		private static var isIFTTTMissedReadingsSnoozedEnabled:Boolean;
		private static var isIFTTTPhoneMutedSnoozedEnabled:Boolean;
		private static var isIFTTTTransmitterLowBatterySnoozedEnabled:Boolean;
		private static var isIFTTTGlucoseThresholdsEnabled:Boolean;
		private static var isIFTTTinteralServerErrorsEnabled:Boolean;
		private static var highGlucoseThresholdValue:Number;
		private static var lowGlucoseThresholdValue:Number;
		private static var makerKeyList:Array;
		private static var makerKeyValue:String;
		private static var isIFTTTbolusTreatmentAddedEnabled:Boolean;
		private static var isIFTTTbolusTreatmentUpdatedEnabled:Boolean;
		private static var isIFTTTbolusTreatmentDeletedEnabled:Boolean;
		private static var isIFTTTcarbsTreatmentAddedEnabled:Boolean;
		private static var isIFTTTcarbsTreatmentUpdatedEnabled:Boolean;
		private static var isIFTTTcarbsTreatmentDeletedEnabled:Boolean;
		private static var isIFTTTmealTreatmentAddedEnabled:Boolean;
		private static var isIFTTTmealTreatmentUpdatedEnabled:Boolean;
		private static var isIFTTTmealTreatmentDeletedEnabled:Boolean;
		private static var isIFTTTbgCheckTreatmentAddedEnabled:Boolean;
		private static var isIFTTTbgCheckTreatmentUpdatedEnabled:Boolean;
		private static var isIFTTTbgCheckTreatmentDeletedEnabled:Boolean;
		private static var isIFTTTnoteTreatmentAddedEnabled:Boolean;
		private static var isIFTTTnoteTreatmentUpdatedEnabled:Boolean;
		private static var isIFTTTnoteTreatmentDeletedEnabled:Boolean;
		private static var isIFTTTiobUpdatedEnabled:Boolean;
		private static var isIFTTTcobUpdatedEnabled:Boolean;
		private static var isIFTTTFastRiseTriggeredEnabled:Boolean;
		private static var isIFTTTFastRiseSnoozedEnabled:Boolean;
		private static var isIFTTTFastDropTriggeredEnabled:Boolean;
		private static var isIFTTTFastDropSnoozedEnabled:Boolean;
		private static var isIFTTTexerciseTreatmentAddedEnabled:Boolean;
		private static var isIFTTTexerciseTreatmentUpdatedEnabled:Boolean;
		private static var isIFTTTexerciseTreatmentDeletedEnabled:Boolean;
		private static var isIFTTTinsulinCartridgeTreatmentAddedEnabled:Boolean;
		private static var isIFTTTinsulinCartridgeTreatmentUpdatedEnabled:Boolean;
		private static var isIFTTTinsulinCartridgeTreatmentDeletedEnabled:Boolean;
		private static var isIFTTTpumpSiteTreatmentAddedEnabled:Boolean;
		private static var isIFTTTpumpSiteTreatmentUpdatedEnabled:Boolean;
		private static var isIFTTTpumpSiteTreatmentDeletedEnabled:Boolean;
		private static var isIFTTTpumpBatteryTreatmentAddedEnabled:Boolean;
		private static var isIFTTTpumpBatteryTreatmentUpdatedEnabled:Boolean;
		private static var isIFTTTpumpBatteryTreatmentDeletedEnabled:Boolean;
		private static var isIFTTTtempBasalStartAddedEnabled:Boolean;
		private static var isIFTTTtempBasalStartUpdatedEnabled:Boolean;
		private static var isIFTTTtempBasalStartDeletedEnabled:Boolean;
		private static var isIFTTTtempBasalEndAddedEnabled:Boolean;
		private static var isIFTTTtempBasalEndUpdatedEnabled:Boolean;
		private static var isIFTTTtempBasalEndDeletedEnabled:Boolean;
		private static var isIFTTTmdiBasalAddedEnabled:Boolean;
		private static var isIFTTTmdiBasalUpdatedEnabled:Boolean;
		private static var isIFTTTmdiBasalDeletedEnabled:Boolean;
		
		public function IFTTTService()
		{
			throw new Error("IFTTTService is not meant to be instantiated!");
		}
		
		public static function init():void
		{
			Trace.myTrace("IFTTTService.as", "Service started!");
			
			getInitialProperties();
			
			if (isIFTTTEnabled)
				configureService();
			
			Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
			LocalSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
		}
		
		private static function onSettingsChanged(e:SettingsServiceEvent):void
		{
			if (e.data == LocalSettings.LOCAL_SETTING_IFTTT_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_CALIBRATION_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_CALIBRATION_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_HIGH_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_HIGH_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_FAST_DROP_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_FAST_DROP_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_LOW_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_LOW_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_MISSED_READINGS_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_MISSED_READINGS_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_PHONE_MUTED_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_PHONE_MUTED_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_FAST_RISE_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_FAST_RISE_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_URGENT_LOW_TRIGGERED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_URGENT_LOW_SNOOZED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_MAKER_KEY ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_THRESHOLDS_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_HIGH_THRESHOLD ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_LOW_THRESHOLD ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_HTTP_SERVER_ERRORS_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_BOLUS_ADDED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_BOLUS_UPDATED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_BOLUS_DELETED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_CARBS_ADDED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_CARBS_UPDATED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_CARBS_DELETED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_MEAL_ADDED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_MEAL_UPDATED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_MEAL_DELETED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_BGCHECK_ADDED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_BGCHECK_UPDATED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_BGCHECK_DELETED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_NOTE_ADDED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_NOTE_ADDED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_NOTE_UPDATED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_NOTE_DELETED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_IOB_UPDATED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_COB_UPDATED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_EXERCISE_ADDED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_EXERCISE_UPDATED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_EXERCISE_DELETED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_INSULIN_CARTRIDGE_ADDED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_INSULIN_CARTRIDGE_UPDATED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_INSULIN_CARTRIDGE_DELETED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_PUMP_SITE_ADDED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_PUMP_SITE_UPDATED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_PUMP_SITE_DELETED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_PUMP_BATTERY_ADDED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_PUMP_BATTERY_UPDATED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_PUMP_BATTERY_DELETED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_TEMP_BASAL_START_ADDED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_TEMP_BASAL_START_UPDATED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_TEMP_BASAL_START_DELETED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_TEMP_BASAL_END_ADDED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_TEMP_BASAL_END_UPDATED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_TEMP_BASAL_END_DELETED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_MDI_BASAL_ADDED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_MDI_BASAL_UPDATED_ON ||
				e.data == LocalSettings.LOCAL_SETTING_IFTTT_MDI_BASAL_DELETED_ON
			)
			{
				getInitialProperties();
				configureService();
			}
		}
		
		private static function getInitialProperties():void
		{
			isIFTTTEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_ON) == "true";
			isIFTTTFastRiseTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_FAST_RISE_TRIGGERED_ON) == "true";
			isIFTTTFastRiseSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_FAST_RISE_SNOOZED_ON) == "true";
			isIFTTTUrgentHighTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_TRIGGERED_ON) == "true";
			isIFTTTHighTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HIGH_TRIGGERED_ON) == "true";
			isIFTTTFastDropTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_FAST_DROP_TRIGGERED_ON) == "true";
			isIFTTTFastDropSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_FAST_DROP_SNOOZED_ON) == "true";
			isIFTTTLowTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_LOW_TRIGGERED_ON) == "true";
			isIFTTTUrgentLowTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_LOW_TRIGGERED_ON) == "true";
			isIFTTTCalibrationTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CALIBRATION_TRIGGERED_ON) == "true";
			isIFTTTMissedReadingsTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MISSED_READINGS_TRIGGERED_ON) == "true";
			isIFTTTPhoneMutedTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_PHONE_MUTED_TRIGGERED_ON) == "true";
			isIFTTTTransmitterLowBatteryTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_TRIGGERED_ON) == "true";
			isIFTTTUrgentHighSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_SNOOZED_ON) == "true";
			isIFTTTHighSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HIGH_SNOOZED_ON) == "true";
			isIFTTTLowSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_LOW_SNOOZED_ON) == "true";
			isIFTTTUrgentLowSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_LOW_SNOOZED_ON) == "true";
			isIFTTTCalibrationSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CALIBRATION_SNOOZED_ON) == "true";
			isIFTTTMissedReadingsSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MISSED_READINGS_SNOOZED_ON) == "true";
			isIFTTTPhoneMutedSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_PHONE_MUTED_SNOOZED_ON) == "true";
			isIFTTTTransmitterLowBatterySnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_SNOOZED_ON) == "true";
			isIFTTTGlucoseReadingsEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_READING_ON) == "true";
			makerKeyList = Cryptography.decryptStringLight(Keys.STRENGTH_256_BIT, LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MAKER_KEY)).split(",");
			makerKeyValue = Cryptography.decryptStringLight(Keys.STRENGTH_256_BIT, LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MAKER_KEY));
			isIFTTTGlucoseThresholdsEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_THRESHOLDS_ON) == "true";
			highGlucoseThresholdValue = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_HIGH_THRESHOLD));
			lowGlucoseThresholdValue = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_LOW_THRESHOLD));
			isIFTTTinteralServerErrorsEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HTTP_SERVER_ERRORS_ON) == "true";
			isIFTTTbolusTreatmentAddedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BOLUS_ADDED_ON) == "true";
			isIFTTTbolusTreatmentUpdatedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BOLUS_UPDATED_ON) == "true";
			isIFTTTbolusTreatmentDeletedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BOLUS_DELETED_ON) == "true";
			isIFTTTcarbsTreatmentAddedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CARBS_ADDED_ON) == "true";
			isIFTTTcarbsTreatmentUpdatedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CARBS_UPDATED_ON) == "true";
			isIFTTTcarbsTreatmentDeletedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CARBS_DELETED_ON) == "true";
			isIFTTTmealTreatmentAddedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MEAL_ADDED_ON) == "true";
			isIFTTTmealTreatmentUpdatedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MEAL_UPDATED_ON) == "true";
			isIFTTTmealTreatmentDeletedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MEAL_DELETED_ON) == "true";
			isIFTTTbgCheckTreatmentAddedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BGCHECK_ADDED_ON) == "true";
			isIFTTTbgCheckTreatmentUpdatedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BGCHECK_UPDATED_ON) == "true";
			isIFTTTbgCheckTreatmentDeletedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BGCHECK_DELETED_ON) == "true";
			isIFTTTnoteTreatmentAddedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_NOTE_ADDED_ON) == "true";
			isIFTTTnoteTreatmentUpdatedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_NOTE_UPDATED_ON) == "true";
			isIFTTTnoteTreatmentDeletedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_NOTE_DELETED_ON) == "true";
			isIFTTTiobUpdatedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_IOB_UPDATED_ON) == "true";
			isIFTTTcobUpdatedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_COB_UPDATED_ON) == "true";
			isIFTTTexerciseTreatmentAddedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_EXERCISE_ADDED_ON) == "true";
			isIFTTTexerciseTreatmentUpdatedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_EXERCISE_UPDATED_ON) == "true";
			isIFTTTexerciseTreatmentDeletedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_EXERCISE_DELETED_ON) == "true";
			isIFTTTinsulinCartridgeTreatmentAddedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_INSULIN_CARTRIDGE_ADDED_ON) == "true";
			isIFTTTinsulinCartridgeTreatmentUpdatedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_INSULIN_CARTRIDGE_UPDATED_ON) == "true";
			isIFTTTinsulinCartridgeTreatmentDeletedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_INSULIN_CARTRIDGE_DELETED_ON) == "true";
			isIFTTTpumpSiteTreatmentAddedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_PUMP_SITE_ADDED_ON) == "true";
			isIFTTTpumpSiteTreatmentUpdatedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_PUMP_SITE_UPDATED_ON) == "true";
			isIFTTTpumpSiteTreatmentDeletedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_PUMP_SITE_DELETED_ON) == "true";
			isIFTTTpumpBatteryTreatmentAddedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_PUMP_BATTERY_ADDED_ON) == "true";
			isIFTTTpumpBatteryTreatmentUpdatedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_PUMP_BATTERY_UPDATED_ON) == "true";
			isIFTTTpumpBatteryTreatmentDeletedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_PUMP_BATTERY_DELETED_ON) == "true";
			isIFTTTtempBasalStartAddedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_TEMP_BASAL_START_ADDED_ON) == "true";
			isIFTTTtempBasalStartUpdatedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_TEMP_BASAL_START_UPDATED_ON) == "true";
			isIFTTTtempBasalStartDeletedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_TEMP_BASAL_START_DELETED_ON) == "true";
			isIFTTTtempBasalEndAddedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_TEMP_BASAL_END_ADDED_ON) == "true";
			isIFTTTtempBasalEndUpdatedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_TEMP_BASAL_END_UPDATED_ON) == "true";
			isIFTTTtempBasalEndDeletedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_TEMP_BASAL_END_DELETED_ON) == "true";
			isIFTTTmdiBasalAddedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MDI_BASAL_ADDED_ON) == "true";
			isIFTTTmdiBasalUpdatedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MDI_BASAL_UPDATED_ON) == "true";
			isIFTTTmdiBasalDeletedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MDI_BASAL_DELETED_ON) == "true";
		}
		
		private static function configureService():void
		{
			if (isIFTTTFastRiseTriggeredEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.FAST_RISE_TRIGGERED, onFastRiseGlucoseTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.FAST_RISE_TRIGGERED, onFastRiseGlucoseTriggered);
			
			if (isIFTTTFastRiseSnoozedEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.FAST_RISE_SNOOZED, onFastRiseGlucoseSnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.FAST_RISE_SNOOZED, onFastRiseGlucoseSnoozed);
			
			if (isIFTTTUrgentHighTriggeredEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.URGENT_HIGH_GLUCOSE_TRIGGERED, onUrgentHighGlucoseTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.URGENT_HIGH_GLUCOSE_TRIGGERED, onUrgentHighGlucoseTriggered);
			
			if (isIFTTTUrgentHighSnoozedEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.URGENT_HIGH_GLUCOSE_SNOOZED, onUrgentHighGlucoseSnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.URGENT_HIGH_GLUCOSE_SNOOZED, onUrgentHighGlucoseSnoozed);
				
			if (isIFTTTHighTriggeredEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.HIGH_GLUCOSE_TRIGGERED, onHighGlucoseTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.HIGH_GLUCOSE_TRIGGERED, onHighGlucoseTriggered);
			
			if (isIFTTTHighSnoozedEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.HIGH_GLUCOSE_SNOOZED, onHighGlucoseSnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.HIGH_GLUCOSE_SNOOZED, onHighGlucoseSnoozed);
			
			if (isIFTTTFastDropTriggeredEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.FAST_DROP_TRIGGERED, onFastDropGlucoseTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.FAST_DROP_TRIGGERED, onFastDropGlucoseTriggered);
			
			if (isIFTTTFastDropSnoozedEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.FAST_DROP_SNOOZED, onFastDropGlucoseSnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.FAST_DROP_SNOOZED, onFastDropGlucoseSnoozed);
				
			if (isIFTTTLowTriggeredEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.LOW_GLUCOSE_TRIGGERED, onLowGlucoseTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.HIGH_GLUCOSE_TRIGGERED, onLowGlucoseTriggered);
			
			if (isIFTTTLowSnoozedEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.LOW_GLUCOSE_SNOOZED, onLowGlucoseSnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.LOW_GLUCOSE_SNOOZED, onLowGlucoseSnoozed);
				
			if (isIFTTTUrgentLowTriggeredEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.URGENT_LOW_GLUCOSE_TRIGGERED, onUrgentLowGlucoseTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.HIGH_GLUCOSE_TRIGGERED, onUrgentLowGlucoseTriggered);
			
			if (isIFTTTUrgentLowSnoozedEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.URGENT_LOW_GLUCOSE_SNOOZED, onUrgentLowGlucoseSnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.URGENT_LOW_GLUCOSE_SNOOZED, onUrgentLowGlucoseSnoozed);
				
			if (isIFTTTCalibrationTriggeredEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.CALIBRATION_TRIGGERED, onCalibrationTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.CALIBRATION_TRIGGERED, onCalibrationTriggered);
			
			if (isIFTTTCalibrationSnoozedEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.CALIBRATION_SNOOZED, onCalibrationSnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.CALIBRATION_SNOOZED, onCalibrationSnoozed);
				
			if (isIFTTTMissedReadingsTriggeredEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.MISSED_READINGS_TRIGGERED, onMissedReadingsTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.MISSED_READINGS_TRIGGERED, onMissedReadingsTriggered);
			
			if (isIFTTTMissedReadingsSnoozedEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.MISSED_READINGS_SNOOZED, onMissedReadingsSnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.MISSED_READINGS_SNOOZED, onMissedReadingsSnoozed);
				
			if (isIFTTTPhoneMutedTriggeredEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.PHONE_MUTED_TRIGGERED, onPhoneMutedTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.PHONE_MUTED_TRIGGERED, onPhoneMutedTriggered);
			
			if (isIFTTTPhoneMutedSnoozedEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.PHONE_MUTED_SNOOZED, onPhoneMutedSnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.PHONE_MUTED_SNOOZED, onPhoneMutedSnoozed);
				
			if (isIFTTTTransmitterLowBatteryTriggeredEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.TRANSMITTER_LOW_BATTERY_TRIGGERED, onTransmitterLowBatteryTriggered);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.TRANSMITTER_LOW_BATTERY_TRIGGERED, onTransmitterLowBatteryTriggered);
			
			if (isIFTTTTransmitterLowBatterySnoozedEnabled && isIFTTTEnabled && makerKeyValue != "")
				AlarmService.instance.addEventListener(AlarmServiceEvent.TRANSMITTER_LOW_BATTERY_SNOOZED, onTransmitterLowBatterySnoozed);
			else
				AlarmService.instance.removeEventListener(AlarmServiceEvent.TRANSMITTER_LOW_BATTERY_SNOOZED, onTransmitterLowBatterySnoozed);
			
			if ((isIFTTTGlucoseReadingsEnabled || isIFTTTGlucoseThresholdsEnabled || isIFTTTiobUpdatedEnabled || isIFTTTcobUpdatedEnabled) && isIFTTTEnabled && makerKeyValue != "")
			{
				TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReading);
				NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReading);
				DexcomShareService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReading);
			}
			else
			{
				TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReading);
				NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReading);
				DexcomShareService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReading);
			}
			
			if (isIFTTTinteralServerErrorsEnabled && isIFTTTEnabled && makerKeyValue != "")
				HttpServer.instance.addEventListener(HTTPServerEvent.SERVER_OFFLINE, onServerOffline, false, 0, true);
			else
				HttpServer.instance.removeEventListener(HTTPServerEvent.SERVER_OFFLINE, onServerOffline);
			
			if ((isIFTTTbolusTreatmentAddedEnabled || isIFTTTcarbsTreatmentAddedEnabled || isIFTTTmealTreatmentAddedEnabled || isIFTTTbgCheckTreatmentAddedEnabled || isIFTTTnoteTreatmentAddedEnabled || isIFTTTexerciseTreatmentAddedEnabled || isIFTTTinsulinCartridgeTreatmentAddedEnabled || isIFTTTpumpSiteTreatmentAddedEnabled || isIFTTTpumpBatteryTreatmentAddedEnabled || isIFTTTiobUpdatedEnabled || isIFTTTcobUpdatedEnabled) && isIFTTTEnabled && makerKeyValue != "")
				TreatmentsManager.instance.addEventListener(TreatmentsEvent.TREATMENT_ADDED, onTreatmentAdded);
			else
				TreatmentsManager.instance.removeEventListener(TreatmentsEvent.TREATMENT_ADDED, onTreatmentAdded);
			
			if ((isIFTTTbolusTreatmentDeletedEnabled || isIFTTTcarbsTreatmentDeletedEnabled || isIFTTTmealTreatmentDeletedEnabled || isIFTTTbgCheckTreatmentDeletedEnabled || isIFTTTnoteTreatmentDeletedEnabled || isIFTTTexerciseTreatmentDeletedEnabled || isIFTTTinsulinCartridgeTreatmentDeletedEnabled || isIFTTTpumpSiteTreatmentDeletedEnabled || isIFTTTpumpBatteryTreatmentDeletedEnabled || isIFTTTiobUpdatedEnabled || isIFTTTcobUpdatedEnabled) && isIFTTTEnabled && makerKeyValue != "")
				TreatmentsManager.instance.addEventListener(TreatmentsEvent.TREATMENT_DELETED, onTreatmentDeleted);
			else
				TreatmentsManager.instance.removeEventListener(TreatmentsEvent.TREATMENT_DELETED, onTreatmentDeleted);
			
			if ((isIFTTTbolusTreatmentUpdatedEnabled || isIFTTTcarbsTreatmentUpdatedEnabled || isIFTTTmealTreatmentUpdatedEnabled || isIFTTTbgCheckTreatmentUpdatedEnabled || isIFTTTnoteTreatmentUpdatedEnabled || isIFTTTexerciseTreatmentUpdatedEnabled || isIFTTTinsulinCartridgeTreatmentUpdatedEnabled || isIFTTTpumpSiteTreatmentUpdatedEnabled || isIFTTTpumpBatteryTreatmentUpdatedEnabled || isIFTTTiobUpdatedEnabled || isIFTTTcobUpdatedEnabled) && isIFTTTEnabled && makerKeyValue != "")
				TreatmentsManager.instance.addEventListener(TreatmentsEvent.TREATMENT_UPDATED, onTreatmentUpdated);
			else
				TreatmentsManager.instance.removeEventListener(TreatmentsEvent.TREATMENT_UPDATED, onTreatmentUpdated);
			
			if ((isIFTTTiobUpdatedEnabled || isIFTTTcobUpdatedEnabled) && isIFTTTEnabled && makerKeyValue != "")
				TreatmentsManager.instance.addEventListener(TreatmentsEvent.IOB_COB_UPDATED, onIOBCOBUpdated);
			else
				TreatmentsManager.instance.removeEventListener(TreatmentsEvent.IOB_COB_UPDATED, onIOBCOBUpdated);
			
			if ((isIFTTTtempBasalStartAddedEnabled || isIFTTTtempBasalEndAddedEnabled || isIFTTTmdiBasalAddedEnabled) && isIFTTTEnabled && makerKeyValue != "")
				TreatmentsManager.instance.addEventListener(TreatmentsEvent.BASAL_TREATMENT_ADDED, onTreatmentAdded);
			else
				TreatmentsManager.instance.removeEventListener(TreatmentsEvent.BASAL_TREATMENT_ADDED, onTreatmentAdded);
			
			if ((isIFTTTtempBasalStartUpdatedEnabled || isIFTTTtempBasalEndUpdatedEnabled || isIFTTTmdiBasalUpdatedEnabled) && isIFTTTEnabled && makerKeyValue != "")
				TreatmentsManager.instance.addEventListener(TreatmentsEvent.BASAL_TREATMENT_UPDATED, onTreatmentUpdated);
			else
				TreatmentsManager.instance.removeEventListener(TreatmentsEvent.BASAL_TREATMENT_UPDATED, onTreatmentUpdated);
			
			if ((isIFTTTtempBasalStartDeletedEnabled || isIFTTTtempBasalEndDeletedEnabled || isIFTTTmdiBasalDeletedEnabled) && isIFTTTEnabled && makerKeyValue != "")
				TreatmentsManager.instance.addEventListener(TreatmentsEvent.BASAL_TREATMENT_DELETED, onTreatmentDeleted);
			else
				TreatmentsManager.instance.removeEventListener(TreatmentsEvent.BASAL_TREATMENT_DELETED, onTreatmentDeleted);
		}
		
		private static function onTreatmentAdded(e:TreatmentsEvent):void
		{
			var treatment:Treatment = e.treatment;
			if 
			(
				(treatment.type == Treatment.TYPE_BOLUS && isIFTTTbolusTreatmentAddedEnabled) || 
				(treatment.type == Treatment.TYPE_CORRECTION_BOLUS && isIFTTTbolusTreatmentAddedEnabled) || 
				(treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT && isIFTTTbolusTreatmentAddedEnabled) || 
				(treatment.type == Treatment.TYPE_CARBS_CORRECTION && isIFTTTcarbsTreatmentAddedEnabled) ||
				(treatment.type == Treatment.TYPE_GLUCOSE_CHECK && isIFTTTbgCheckTreatmentAddedEnabled) ||
				(treatment.type == Treatment.TYPE_MEAL_BOLUS && isIFTTTmealTreatmentAddedEnabled) ||
				(treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT && isIFTTTmealTreatmentAddedEnabled) ||
				(treatment.type == Treatment.TYPE_NOTE && isIFTTTnoteTreatmentAddedEnabled) ||
				(treatment.type == Treatment.TYPE_EXERCISE && isIFTTTexerciseTreatmentAddedEnabled) ||
				(treatment.type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE && isIFTTTinsulinCartridgeTreatmentAddedEnabled) ||
				(treatment.type == Treatment.TYPE_PUMP_SITE_CHANGE && isIFTTTpumpSiteTreatmentAddedEnabled) ||
				(treatment.type == Treatment.TYPE_PUMP_BATTERY_CHANGE && isIFTTTpumpBatteryTreatmentAddedEnabled) ||
				(treatment.type == Treatment.TYPE_TEMP_BASAL && isIFTTTtempBasalStartAddedEnabled) ||
				(treatment.type == Treatment.TYPE_TEMP_BASAL_END && isIFTTTtempBasalEndAddedEnabled) ||
				(treatment.type == Treatment.TYPE_MDI_BASAL && isIFTTTmdiBasalAddedEnabled)
			)
				triggerTreatment(treatment, "added");
			
			if (isIFTTTiobUpdatedEnabled && isIFTTTcobUpdatedEnabled)
				triggerIOBCOB();
			else if (isIFTTTiobUpdatedEnabled)
				triggerIOB();
			else if (isIFTTTcobUpdatedEnabled)
				triggerCOB();
		}
		
		private static function onTreatmentDeleted(e:TreatmentsEvent):void
		{
			var treatment:Treatment = e.treatment;
			if 
			(
				(treatment.type == Treatment.TYPE_BOLUS && isIFTTTbolusTreatmentDeletedEnabled) || 
				(treatment.type == Treatment.TYPE_CORRECTION_BOLUS && isIFTTTbolusTreatmentDeletedEnabled) || 
				(treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT && isIFTTTbolusTreatmentDeletedEnabled) || 
				(treatment.type == Treatment.TYPE_CARBS_CORRECTION && isIFTTTcarbsTreatmentDeletedEnabled) ||
				(treatment.type == Treatment.TYPE_GLUCOSE_CHECK && isIFTTTbgCheckTreatmentDeletedEnabled) ||
				(treatment.type == Treatment.TYPE_MEAL_BOLUS && isIFTTTmealTreatmentDeletedEnabled) ||
				(treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT && isIFTTTmealTreatmentDeletedEnabled) ||
				(treatment.type == Treatment.TYPE_NOTE && isIFTTTnoteTreatmentDeletedEnabled) ||
				(treatment.type == Treatment.TYPE_EXERCISE && isIFTTTexerciseTreatmentDeletedEnabled) ||
				(treatment.type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE && isIFTTTinsulinCartridgeTreatmentDeletedEnabled) ||
				(treatment.type == Treatment.TYPE_PUMP_SITE_CHANGE && isIFTTTpumpSiteTreatmentDeletedEnabled) ||
				(treatment.type == Treatment.TYPE_PUMP_BATTERY_CHANGE && isIFTTTpumpBatteryTreatmentDeletedEnabled) ||
				(treatment.type == Treatment.TYPE_TEMP_BASAL && isIFTTTtempBasalStartDeletedEnabled) ||
				(treatment.type == Treatment.TYPE_TEMP_BASAL_END && isIFTTTtempBasalEndDeletedEnabled) ||
				(treatment.type == Treatment.TYPE_MDI_BASAL && isIFTTTmdiBasalDeletedEnabled)
			)
				triggerTreatment(treatment, "deleted");
			
			if (isIFTTTiobUpdatedEnabled && isIFTTTcobUpdatedEnabled)
				triggerIOBCOB();
			else if (isIFTTTiobUpdatedEnabled)
				triggerIOB();
			else if (isIFTTTcobUpdatedEnabled)
				triggerCOB();
		}
		
		private static function onTreatmentUpdated(e:TreatmentsEvent):void
		{
			var treatment:Treatment = e.treatment;
			if 
			(
				(treatment.type == Treatment.TYPE_BOLUS && isIFTTTbolusTreatmentUpdatedEnabled) || 
				(treatment.type == Treatment.TYPE_CORRECTION_BOLUS && isIFTTTbolusTreatmentUpdatedEnabled) || 
				(treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT && isIFTTTbolusTreatmentUpdatedEnabled) || 
				(treatment.type == Treatment.TYPE_CARBS_CORRECTION && isIFTTTcarbsTreatmentUpdatedEnabled) ||
				(treatment.type == Treatment.TYPE_GLUCOSE_CHECK && isIFTTTbgCheckTreatmentUpdatedEnabled) ||
				(treatment.type == Treatment.TYPE_MEAL_BOLUS && isIFTTTmealTreatmentUpdatedEnabled) ||
				(treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT && isIFTTTmealTreatmentUpdatedEnabled) ||
				(treatment.type == Treatment.TYPE_NOTE && isIFTTTnoteTreatmentUpdatedEnabled) ||
				(treatment.type == Treatment.TYPE_EXERCISE && isIFTTTexerciseTreatmentUpdatedEnabled) ||
				(treatment.type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE && isIFTTTinsulinCartridgeTreatmentUpdatedEnabled) ||
				(treatment.type == Treatment.TYPE_PUMP_SITE_CHANGE && isIFTTTpumpSiteTreatmentUpdatedEnabled) ||
				(treatment.type == Treatment.TYPE_PUMP_BATTERY_CHANGE && isIFTTTpumpBatteryTreatmentUpdatedEnabled) ||
				(treatment.type == Treatment.TYPE_TEMP_BASAL && isIFTTTtempBasalStartUpdatedEnabled) ||
				(treatment.type == Treatment.TYPE_TEMP_BASAL_END && isIFTTTtempBasalEndUpdatedEnabled) ||
				(treatment.type == Treatment.TYPE_MDI_BASAL && isIFTTTmdiBasalUpdatedEnabled)
			)
				triggerTreatment(treatment, "updated");
			
			if (isIFTTTiobUpdatedEnabled && isIFTTTcobUpdatedEnabled)
				triggerIOBCOB();
			else if (isIFTTTiobUpdatedEnabled)
				triggerIOB();
			else if (isIFTTTcobUpdatedEnabled)
				triggerCOB();
		}
		
		private static function triggerTreatment(treatment:Treatment, mode:String):void
		{
			var treatmentDate:Date = new Date(treatment.timestamp);
			var dateFormat:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
			var treatmentTime:String;
			if (dateFormat.slice(0,2) == "24")
				treatmentTime = TimeSpan.formatHoursMinutes(treatmentDate.getHours(), treatmentDate.getMinutes(), TimeSpan.TIME_FORMAT_24H);
			else
				treatmentTime = TimeSpan.formatHoursMinutes(treatmentDate.getHours(), treatmentDate.getMinutes(), TimeSpan.TIME_FORMAT_12H);
			
			var treatmentType:String;
			var treatmentValue:String;
			
			if (treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS)
			{
				treatmentType = ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_bolus");
				treatmentValue = GlucoseFactory.formatIOB(treatment.insulinAmount);
			}
			else if (treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT)
			{
				treatmentType = ModelLocator.resourceManagerInstance.getString("treatments","extended_bolus_treatment");
				treatmentValue = GlucoseFactory.formatIOB(treatment.getTotalInsulin());
			} 
			else if (treatment.type == Treatment.TYPE_CARBS_CORRECTION)
			{
				treatmentType = ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_carbs");
				treatmentValue = GlucoseFactory.formatCOB(treatment.carbs);
			}
			else if (treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
			{
				treatmentType = ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_bg_check");
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
					treatmentValue = treatment.glucose + " " + GlucoseHelper.getGlucoseUnit();
				else
					treatmentValue = (Math.round(((BgReading.mgdlToMmol((treatment.glucose))) * 10)) / 10) + " " + GlucoseHelper.getGlucoseUnit();
			}
			else if (treatment.type == Treatment.TYPE_MEAL_BOLUS)
			{
				treatmentType = ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_meal");
				treatmentValue = ModelLocator.resourceManagerInstance.getString("treatments","treatment_insulin_label") + ": " + GlucoseFactory.formatIOB(treatment.insulinAmount) + ", " + ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_carbs") + ": " + GlucoseFactory.formatCOB(treatment.carbs);
			}
			else if (treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
			{
				treatmentType = ModelLocator.resourceManagerInstance.getString("treatments","meal_with_extended_bolus");
				treatmentValue = ModelLocator.resourceManagerInstance.getString("treatments","treatment_insulin_label") + ": " + GlucoseFactory.formatIOB(treatment.getTotalInsulin()) + ", " + ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_carbs") + ": " + GlucoseFactory.formatCOB(treatment.carbs);
			}
			else if (treatment.type == Treatment.TYPE_NOTE)
			{
				treatmentType = ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_note");
				treatmentValue = treatment.note;
			}
			else if (treatment.type == Treatment.TYPE_EXERCISE)
			{
				treatmentType = ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_exercise");
				treatmentValue = ModelLocator.resourceManagerInstance.getString("treatments","exercise_duration_label") + ": " + treatment.duration + ModelLocator.resourceManagerInstance.getString("treatments","minutes_small_label") + ", " + ModelLocator.resourceManagerInstance.getString("treatments","exercise_intensity_label") + ": " + TreatmentsManager.getExerciseTreatmentIntensity(treatment);
			}
			else if (treatment.type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE)
			{
				treatmentType = ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_insulin_cartridge_change");
				treatmentValue = treatment.note;
			}
			else if (treatment.type == Treatment.TYPE_PUMP_SITE_CHANGE)
			{
				treatmentType = ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_pump_site_change");
				treatmentValue = treatment.note;
			}
			else if (treatment.type == Treatment.TYPE_PUMP_BATTERY_CHANGE)
			{
				treatmentType = ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_pump_battery_change");
				treatmentValue = treatment.note;
			}
			else if (treatment.type == Treatment.TYPE_MDI_BASAL)
			{
				treatmentType = ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_basal");
				treatmentValue = GlucoseFactory.formatIOB(treatment.basalAbsoluteAmount);
			}
			else if (treatment.type == Treatment.TYPE_TEMP_BASAL_END)
			{
				treatmentType = ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_temp_basal_end");
				treatmentValue = GlucoseFactory.formatIOB(0);
			}
			else if (treatment.type == Treatment.TYPE_TEMP_BASAL)
			{
				treatmentType = treatment.isTempBasalEnd ? ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_temp_basal_end") : ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_temp_basal_start");
				
				if (treatment.isTempBasalEnd)
				{
					treatmentValue = GlucoseFactory.formatIOB(0);
				}
				else if (treatment.isBasalAbsolute)
				{
					treatmentValue = GlucoseFactory.formatIOB(treatment.basalAbsoluteAmount);
				}
				else if (treatment.isBasalRelative)
				{
					var currentBasalRate:Number = ProfileManager.getBasalRateByTime(treatment.timestamp);
					treatmentValue = GlucoseFactory.formatIOB(currentBasalRate * (100 + treatment.basalPercentAmount) / 100);
				}
			}
			
			//JSON Object
			var info:Object = {};
			info.value1 = treatmentType;
			info.value2 = treatmentValue;
			info.value3 = treatmentTime;
			
			var triggerName:String;
			if (treatment.type == Treatment.TYPE_TEMP_BASAL || treatment.type == Treatment.TYPE_TEMP_BASAL_END || treatment.type == Treatment.TYPE_MDI_BASAL)
			{
				if (mode == "added")
					triggerName = "spike-basal-added";
				else if (mode == "deleted")
					triggerName = "spike-basal-deleted";
				else if (mode == "updated")
					triggerName = "spike-basal-updated";
			}
			else
			{
				if (mode == "added")
					triggerName = "spike-treatment-added";
				else if (mode == "deleted")
					triggerName = "spike-treatment-deleted";
				else if (mode == "updated")
					triggerName = "spike-treatment-updated";
			}
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", triggerName).replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onIOBCOBUpdated(e:TreatmentsEvent):void
		{
			if (isIFTTTiobUpdatedEnabled && isIFTTTcobUpdatedEnabled)
				triggerIOBCOB();
			else if (isIFTTTiobUpdatedEnabled)
				triggerIOB();
			else if (isIFTTTcobUpdatedEnabled)
				triggerCOB();
		}
		
		private static function triggerIOB():void
		{
			var info:Object = {};
			info.value1 = GlucoseFactory.formatIOB(TreatmentsManager.getTotalIOB(new Date().valueOf()).iob);
			info.value2 = "";
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-iob").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function triggerCOB():void
		{
			var info:Object = {};
			info.value1 = GlucoseFactory.formatCOB(TreatmentsManager.getTotalCOB(new Date().valueOf(), CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps").cob);
			info.value2 = "";
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-cob").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function triggerIOBCOB():void
		{
			var now:Number = new Date().valueOf();
			
			var info:Object = {};
			info.value1 = "IOB: " + GlucoseFactory.formatIOB(TreatmentsManager.getTotalIOB(now).iob);
			info.value2 = "COB: " + GlucoseFactory.formatCOB(TreatmentsManager.getTotalCOB(now, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps").cob);
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-iobcob").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
			}
		}
		
		private static function onBgReading(e:Event):void
		{
			if (Calibration.allForSensor().length >= 2 || CGMBlueToothDevice.isFollower()) 
			{
				var lastReading:BgReading;
				if (!CGMBlueToothDevice.isFollower()) lastReading = BgReading.lastNoSensor();
				else lastReading = BgReading.lastWithCalculatedValue();
				
				if (lastReading != null && lastReading.calculatedValue != 0 && (new Date()).valueOf() - lastReading.timestamp < 4.5 * 60 * 1000 && lastReading.calculatedValue != 0 && (new Date().getTime()) - (60000 * 11) - lastReading.timestamp <= 0) 
				{
					var info:Object = {};
					info.value1 = BgGraphBuilder.unitizedString(lastReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
					info.value2 = !lastReading.hideSlope ? lastReading.slopeArrow() : "";
					info.value3 = BgGraphBuilder.unitizedDeltaString(true, true);
					
					var key:String;
					var i:int;
					
					if (isIFTTTGlucoseThresholdsEnabled && !isNaN(lastReading.calculatedValue) && Math.round(lastReading.calculatedValue) <= lowGlucoseThresholdValue)
					{
						for (i = 0; i < makerKeyList.length; i++) 
						{
							key = makerKeyList[i] as String;
							//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-lowbgreading").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
							NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-lowbgreading").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
						}
					}
					else if (isIFTTTGlucoseThresholdsEnabled && !isNaN(lastReading.calculatedValue) && Math.round(lastReading.calculatedValue) >= highGlucoseThresholdValue)
					{
						for (i = 0; i < makerKeyList.length; i++) 
						{
							key = makerKeyList[i] as String;
							//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-highbgreading").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
							NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-highbgreading").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
						}
					}
					else if (isIFTTTGlucoseReadingsEnabled) //Trigger glucose reading... this is when the user selected to trigger all glucose readings
					{
						for (i = 0; i < makerKeyList.length; i++) 
						{
							key = makerKeyList[i] as String;
							NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-bgreading").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
						}
						
						if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_DIVIDE_BG_EVENTS_BY_THRESHOLD_ON) == "true" && !isNaN(lastReading.calculatedValue))
						{
							var trigger:String = "";
							
							if (lastReading.calculatedValue >= Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK)))
							{
								trigger = "spike-bgreading-urgent-high";
							}
							else if (lastReading.calculatedValue >= Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK)))
							{
								trigger = "spike-bgreading-high";
							}
							else if (lastReading.calculatedValue > Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK)) && lastReading.calculatedValue < Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK)))
							{
								trigger = "spike-bgreading-in-range";
							}
							else if (lastReading.calculatedValue <= Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK)) && lastReading.calculatedValue > Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK)))
							{
								trigger = "spike-bgreading-low";
							}
							else if (lastReading.calculatedValue <= Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK)))
							{
								trigger = "spike-bgreading-urgent-low";
							}
							
							if (trigger != "")
							{
								for (i = 0; i < makerKeyList.length; i++) 
								{
									key = makerKeyList[i] as String;
									NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", trigger).replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
								}
							}
						}
					}
					
					if (isIFTTTiobUpdatedEnabled && isIFTTTcobUpdatedEnabled)
						triggerIOBCOB();
					else if (isIFTTTiobUpdatedEnabled)
						triggerIOB();
					else if (isIFTTTcobUpdatedEnabled)
						triggerCOB();
				}
			}
		}
		
		private static function onFastRiseGlucoseTriggered(e:AlarmServiceEvent):void
		{
			var lastReading:BgReading;
			if (!CGMBlueToothDevice.isFollower()) lastReading = BgReading.lastNoSensor();
			else lastReading = BgReading.lastWithCalculatedValue();
			
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","fast_rise_alert_notification_alert_text");
			info.value2 = BgGraphBuilder.unitizedString(lastReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
			info.value3 = (!lastReading.hideSlope ? lastReading.slopeArrow() + " " : "\u21C4 ") + BgGraphBuilder.unitizedDeltaString(true, true);
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-urgent-high-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-fast-rising-triggered").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onFastRiseGlucoseSnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-urgent-high-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-fast-rising-snoozed").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onUrgentHighGlucoseTriggered(e:AlarmServiceEvent):void
		{
			var lastReading:BgReading;
			if (!CGMBlueToothDevice.isFollower()) lastReading = BgReading.lastNoSensor();
			else lastReading = BgReading.lastWithCalculatedValue();
			
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","veryhigh_alert_notification_alert_text");
			info.value2 = BgGraphBuilder.unitizedString(lastReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
			info.value3 = (!lastReading.hideSlope ? lastReading.slopeArrow() + " " : "\u21C4 ") + BgGraphBuilder.unitizedDeltaString(true, true);
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-urgent-high-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-urgent-high-triggered").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onUrgentHighGlucoseSnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-urgent-high-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-urgent-high-snoozed").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onHighGlucoseTriggered(e:AlarmServiceEvent):void
		{
			var lastReading:BgReading;
			if (!CGMBlueToothDevice.isFollower()) lastReading = BgReading.lastNoSensor();
			else lastReading = BgReading.lastWithCalculatedValue();
			
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","high_alert_notification_alert_text");
			info.value2 = BgGraphBuilder.unitizedString(lastReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
			info.value3 = (!lastReading.hideSlope ? lastReading.slopeArrow() + " " : "\u21C4 ") + BgGraphBuilder.unitizedDeltaString(true, true);
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-high-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-high-triggered").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onHighGlucoseSnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-high-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-high-snoozed").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onFastDropGlucoseTriggered(e:AlarmServiceEvent):void
		{
			var lastReading:BgReading;
			if (!CGMBlueToothDevice.isFollower()) lastReading = BgReading.lastNoSensor();
			else lastReading = BgReading.lastWithCalculatedValue();
			
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","fast_drop_alert_notification_alert_text");
			info.value2 = BgGraphBuilder.unitizedString(lastReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
			info.value3 = (!lastReading.hideSlope ? lastReading.slopeArrow() + " " : "\u21C4 ") + BgGraphBuilder.unitizedDeltaString(true, true);
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-low-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-fast-drop-triggered").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onFastDropGlucoseSnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-low-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-fast-drop-snoozed").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onLowGlucoseTriggered(e:AlarmServiceEvent):void
		{
			var lastReading:BgReading;
			if (!CGMBlueToothDevice.isFollower()) lastReading = BgReading.lastNoSensor();
			else lastReading = BgReading.lastWithCalculatedValue();
			
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","low_alert_notification_alert_text");
			info.value2 = BgGraphBuilder.unitizedString(lastReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
			info.value3 = (!lastReading.hideSlope ? lastReading.slopeArrow() + " " : "\u21C4 ") + BgGraphBuilder.unitizedDeltaString(true, true);
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-low-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-low-triggered").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onLowGlucoseSnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-low-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-low-snoozed").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onUrgentLowGlucoseTriggered(e:AlarmServiceEvent):void
		{
			var lastReading:BgReading;
			if (!CGMBlueToothDevice.isFollower()) lastReading = BgReading.lastNoSensor();
			else lastReading = BgReading.lastWithCalculatedValue();
			
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","verylow_alert_notification_alert_text");
			info.value2 = BgGraphBuilder.unitizedString(lastReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
			info.value3 = (!lastReading.hideSlope ? lastReading.slopeArrow() + " " : "\u21C4 ") + BgGraphBuilder.unitizedDeltaString(true, true);
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-urgent-low-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-urgent-low-triggered").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onUrgentLowGlucoseSnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-urgent-low-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-urgent-low-snoozed").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onCalibrationTriggered(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","calibration_request_alert_notification_alert_title");
			info.value2 = "";
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-calibration-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-calibration-triggered").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onCalibrationSnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-calibration-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-calibration-snoozed").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onMissedReadingsTriggered(e:AlarmServiceEvent):void
		{
			var lastReading:BgReading;
			if (!CGMBlueToothDevice.isFollower()) lastReading = BgReading.lastNoSensor();
			else lastReading = BgReading.lastWithCalculatedValue();
			
			var timeSpan:TimeSpan;
			if (lastReading != null)
				timeSpan = TimeSpan.fromMilliseconds(new Date().valueOf() - lastReading.timestamp);
			
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","missed_reading_alert_notification_alert");
			info.value2 = lastReading != null ? String(Math.round(timeSpan.minutes / TimeSpan.TIME_5_MINUTES)) : ""; //Number of missed readings
			info.value3 = lastReading != null ? String((timeSpan.hours > 0 ? MathHelper.formatNumberToString(timeSpan.hours) + "h" : "") + (timeSpan.hours > 0  ? MathHelper.formatNumberToString(timeSpan.minutes) + "m" : timeSpan.minutes + "m")) : ""; //Time since last reading
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-missed-readings-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-missed-readings-triggered").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onMissedReadingsSnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-missed-readings-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-missed-readings-snoozed").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onPhoneMutedTriggered(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","phonemuted_alert_notification_alert_text");
			info.value2 = "";
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-phone-muted-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-phone-muted-triggered").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onPhoneMutedSnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-phone-muted-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-phone-muted-snoozed").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onTransmitterLowBatteryTriggered(e:Event):void
		{
			var info:Object = {};
			info.value1 = ModelLocator.resourceManagerInstance.getString("alarmservice","batteryLevel_alert_notification_alert_text");
			info.value2 = "";
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-transmitter-low-battery-triggered").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-transmitter-low-battery-triggered").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onTransmitterLowBatterySnoozed(e:AlarmServiceEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.type;
			info.value2 = e.data.time;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-transmitter-low-battery-snoozed").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-transmitter-low-battery-snoozed").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		private static function onServerOffline(e:HTTPServerEvent):void
		{
			var info:Object = {};
			info.value1 = e.data.title;
			info.value2 = e.data.message;
			info.value3 = "";
			
			for (var i:int = 0; i < makerKeyList.length; i++) 
			{
				var key:String = makerKeyList[i] as String;
				//NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-server-error").replace("{key}", key), URLRequestMethod.POST, JSON.stringify(info));
				NetworkConnector.createIFTTTConnector(IFTTT_URL.replace("{trigger}", "spike-server-error").replace("{key}", key), URLRequestMethod.POST, SpikeJSON.stringify(info));
			}
		}
		
		/**
		 * Stops the service entirely. Useful for database restores
		 */
		private static function onHaltExecution(e:SpikeEvent):void
		{
			Trace.myTrace("IFTTTService.as", "Stopping service...");
			
			stopService();
		}
		
		private static function stopService():void
		{
			LocalSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.FAST_RISE_TRIGGERED, onFastRiseGlucoseTriggered);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.FAST_RISE_SNOOZED, onFastRiseGlucoseSnoozed);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.URGENT_HIGH_GLUCOSE_TRIGGERED, onUrgentHighGlucoseTriggered);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.URGENT_HIGH_GLUCOSE_SNOOZED, onUrgentHighGlucoseSnoozed);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.HIGH_GLUCOSE_TRIGGERED, onHighGlucoseTriggered);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.HIGH_GLUCOSE_SNOOZED, onHighGlucoseSnoozed);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.FAST_DROP_TRIGGERED, onFastDropGlucoseTriggered);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.FAST_DROP_SNOOZED, onFastDropGlucoseSnoozed);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.HIGH_GLUCOSE_TRIGGERED, onLowGlucoseTriggered);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.LOW_GLUCOSE_SNOOZED, onLowGlucoseSnoozed);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.HIGH_GLUCOSE_TRIGGERED, onUrgentLowGlucoseTriggered);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.URGENT_LOW_GLUCOSE_SNOOZED, onUrgentLowGlucoseSnoozed);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.CALIBRATION_TRIGGERED, onCalibrationTriggered);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.CALIBRATION_SNOOZED, onCalibrationSnoozed);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.MISSED_READINGS_TRIGGERED, onMissedReadingsTriggered);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.MISSED_READINGS_SNOOZED, onMissedReadingsSnoozed);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.PHONE_MUTED_TRIGGERED, onPhoneMutedTriggered);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.PHONE_MUTED_SNOOZED, onPhoneMutedSnoozed);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.TRANSMITTER_LOW_BATTERY_TRIGGERED, onTransmitterLowBatteryTriggered);
			AlarmService.instance.removeEventListener(AlarmServiceEvent.TRANSMITTER_LOW_BATTERY_SNOOZED, onTransmitterLowBatterySnoozed);
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReading);
			NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReading);
			DexcomShareService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReading);
			HttpServer.instance.removeEventListener(HTTPServerEvent.SERVER_OFFLINE, onServerOffline);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.TREATMENT_ADDED, onTreatmentAdded);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.TREATMENT_DELETED, onTreatmentDeleted);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.TREATMENT_UPDATED, onTreatmentUpdated);
			TreatmentsManager.instance.removeEventListener(TreatmentsEvent.IOB_COB_UPDATED, onIOBCOBUpdated);
			
			Trace.myTrace("IFTTTService.as", "Service stopped!");
		}
	}
}