package ui.screens.display.settings.integration
{
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import cryptography.Keys;
	
	import database.BgReading;
	import database.CommonSettings;
	import database.LocalSettings;
	
	import feathers.controls.Button;
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.NumericStepper;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.Cryptography;
	import utils.DeviceInfo;
	
	[ResourceBundle("iftttsettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class IFTTTSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var IFTTTToggle:ToggleSwitch;
		private var urgentHighGlucoseTriggeredCheck:Check;
		private var highGlucoseTriggeredCheck:Check;
		private var lowGlucoseTriggeredCheck:Check;
		private var urgentLowGlucoseTriggeredCheck:Check;
		private var calibrationTriggeredCheck:Check;
		private var missedReadingsTriggeredCheck:Check;
		private var phoneMutedTriggeredCheck:Check;
		private var transmitterLowBatteryTriggeredCheck:Check;
		private var glucoseReadingCheck:Check;
		private var makerKeyTextInput:TextInput;
		private var makerKeyDescriptionLabel:Label;
		private var urgentHighGlucoseSnoozedCheck:Check;
		private var highGlucoseSnoozedCheck:Check;
		private var lowGlucoseSnoozedCheck:Check;
		private var urgentLowGlucoseSnoozedCheck:Check;
		private var calibrationSnoozedCheck:Check;
		private var missedReadingsSnoozedCheck:Check;
		private var phoneMutedSnoozedCheck:Check;
		private var transmitterLowBatterySnoozedCheck:Check;
		private var glucoseThresholdsSwitch:ToggleSwitch;
		private var lowGlucoseThresholdStepper:NumericStepper;
		private var highGlucoseThresholdStepper:NumericStepper;
		private var alarmsLabel:Label;
		private var httpServerErrorsCheck:Check;
		private var instructionsButton:Button;
		private var instructionsContainer:LayoutGroup;
		private var treatmentsLabel:Label;
		private var treatmentIOBUpdatedCheck:Check;
		private var treatmentCOBUpdatedCheck:Check;
		private var treatmentBolusAddedCheck:Check;
		private var treatmentBolusUpdatedCheck:Check;
		private var treatmentBolusDeletedCheck:Check;
		private var treatmentCarbsAddedCheck:Check;
		private var treatmentCarbsUpdatedCheck:Check;
		private var treatmentCarbsDeletedCheck:Check;
		private var treatmentMealAddedCheck:Check;
		private var treatmentMealUpdatedCheck:Check;
		private var treatmentMealDeletedCheck:Check;
		private var treatmentBGCheckAddedCheck:Check;
		private var treatmentBGCheckUpdatedCheck:Check;
		private var treatmentBGCheckDeletedCheck:Check;
		private var treatmentNoteAddedCheck:Check;
		private var treatmentNoteUpdatedCheck:Check;
		private var treatmentNoteDeletedCheck:Check;
		private var fastRiseGlucoseTriggeredCheck:Check;
		private var fastRiseGlucoseSnoozedCheck:Check;
		private var fastDropGlucoseTriggeredCheck:Check;
		private var fastDropGlucoseSnoozedCheck:Check;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var isIFTTTEnabled:Boolean;
		private var isIFTTTUrgentHighTriggeredEnabled:Boolean;
		private var isIFTTTHighTriggeredEnabled:Boolean;
		private var isIFTTTLowTriggeredEnabled:Boolean;
		private var isIFTTTUrgentLowTriggeredEnabled:Boolean;
		private var isIFTTTCalibrationTriggeredEnabled:Boolean;
		private var isIFTTTMissedReadingsTriggeredEnabled:Boolean;
		private var isIFTTTPhoneMutedTriggeredEnabled:Boolean;
		private var isIFTTTTransmitterLowBatteryTriggeredEnabled:Boolean;
		private var isIFTTTAlarmSnoozedTriggeredEnabled:Boolean;
		private var isIFTTTGlucoseReadingsEnabled:Boolean;
		private var isIFTTTUrgentHighSnoozedEnabled:Boolean;
		private var isIFTTTHighSnoozedEnabled:Boolean;
		private var isIFTTTLowSnoozedEnabled:Boolean;
		private var isIFTTTUrgentLowSnoozedEnabled:Boolean;
		private var isIFTTTCalibrationSnoozedEnabled:Boolean;
		private var isIFTTTMissedReadingsSnoozedEnabled:Boolean;
		private var isIFTTTPhoneMutedSnoozedEnabled:Boolean;
		private var isIFTTTTransmitterLowBatterySnoozedEnabled:Boolean;
		private var makerKeyValue:String;
		private var isIFTTTGlucoseThresholdsEnabled:Boolean;
		private var highGlucoseThresholdValue:Number;
		private var lowGlucoseThresholdValue:Number;
		private var isIFTTTinteralServerErrorsEnabled:Boolean;
		private var isIFTTTbolusTreatmentAddedEnabled:Boolean;
		private var isIFTTTbolusTreatmentUpdatedEnabled:Boolean;
		private var isIFTTTbolusTreatmentDeletedEnabled:Boolean;
		private var isIFTTTcarbsTreatmentAddedEnabled:Boolean;
		private var isIFTTTcarbsTreatmentUpdatedEnabled:Boolean;
		private var isIFTTTcarbsTreatmentDeletedEnabled:Boolean;
		private var isIFTTTmealTreatmentAddedEnabled:Boolean;
		private var isIFTTTmealTreatmentUpdatedEnabled:Boolean;
		private var isIFTTTmealTreatmentDeletedEnabled:Boolean;
		private var isIFTTTbgCheckTreatmentAddedEnabled:Boolean;
		private var isIFTTTbgCheckTreatmentUpdatedEnabled:Boolean;
		private var isIFTTTbgCheckTreatmentDeletedEnabled:Boolean;
		private var isIFTTTnoteTreatmentAddedEnabled:Boolean;
		private var isIFTTTnoteTreatmentUpdatedEnabled:Boolean;
		private var isIFTTTnoteTreatmentDeletedEnabled:Boolean;
		private var isIFTTTiobUpdatedEnabled:Boolean;
		private var isIFTTTcobUpdatedEnabled:Boolean;
		private var isIFTTTFastRiseTriggeredEnabled:Boolean;
		private var isIFTTTFastRiseSnoozedEnabled:Boolean;
		private var isIFTTTFastDropTriggeredEnabled:Boolean;
		private var isIFTTTFastDropSnoozedEnabled:Boolean;

		public function IFTTTSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupInitialContent();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialContent():void
		{
			/* Get data from database */
			isIFTTTEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_ON) == "true";
			isIFTTTFastRiseTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_FAST_RISE_TRIGGERED_ON) == "true";
			isIFTTTFastRiseSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_FAST_RISE_SNOOZED_ON) == "true";
			isIFTTTUrgentHighTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_TRIGGERED_ON) == "true";
			isIFTTTUrgentHighSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_SNOOZED_ON) == "true";
			isIFTTTHighTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HIGH_TRIGGERED_ON) == "true";
			isIFTTTHighSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HIGH_SNOOZED_ON) == "true";
			isIFTTTFastDropTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_FAST_DROP_TRIGGERED_ON) == "true";
			isIFTTTFastDropSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_FAST_DROP_SNOOZED_ON) == "true";
			isIFTTTLowTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_LOW_TRIGGERED_ON) == "true";
			isIFTTTLowSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_LOW_SNOOZED_ON) == "true";
			isIFTTTUrgentLowTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_LOW_TRIGGERED_ON) == "true";
			isIFTTTUrgentLowSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_LOW_SNOOZED_ON) == "true";
			isIFTTTCalibrationTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CALIBRATION_TRIGGERED_ON) == "true";
			isIFTTTCalibrationSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CALIBRATION_SNOOZED_ON) == "true";
			isIFTTTMissedReadingsTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MISSED_READINGS_TRIGGERED_ON) == "true";
			isIFTTTMissedReadingsSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MISSED_READINGS_SNOOZED_ON) == "true";
			isIFTTTPhoneMutedTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_PHONE_MUTED_TRIGGERED_ON) == "true";
			isIFTTTPhoneMutedSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_PHONE_MUTED_SNOOZED_ON) == "true";
			isIFTTTTransmitterLowBatteryTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_TRIGGERED_ON) == "true";
			isIFTTTTransmitterLowBatterySnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_SNOOZED_ON) == "true";
			isIFTTTGlucoseReadingsEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_READING_ON) == "true";
			makerKeyValue = Cryptography.decryptStringLight(Keys.STRENGTH_256_BIT, LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MAKER_KEY));
			isIFTTTGlucoseThresholdsEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_THRESHOLDS_ON) == "true";
			highGlucoseThresholdValue = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_HIGH_THRESHOLD));
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
				highGlucoseThresholdValue = (Math.round(highGlucoseThresholdValue * BgReading.MGDL_TO_MMOLL * 10))/10;
			lowGlucoseThresholdValue = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_LOW_THRESHOLD));
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
				lowGlucoseThresholdValue = (Math.round(lowGlucoseThresholdValue * BgReading.MGDL_TO_MMOLL * 10))/10;
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
		}
		
		private function setupContent():void
		{
			//On/Off Toggle
			IFTTTToggle = LayoutFactory.createToggleSwitch(isIFTTTEnabled);
			IFTTTToggle.addEventListener( Event.CHANGE, onSettingsReload );
			
			//Instructions
			var instructionsLayout:HorizontalLayout = new HorizontalLayout();
			instructionsLayout.horizontalAlign = HorizontalAlign.CENTER;
			
			instructionsContainer = new LayoutGroup();
			instructionsContainer.layout = instructionsLayout;
			instructionsContainer.width = width - 20;
			
			instructionsButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","instructions_Label"));
			instructionsContainer.addChild(instructionsButton);
			instructionsButton.addEventListener(Event.TRIGGERED, onShowInstructions);
			
			//Maker Key Input Field
			makerKeyTextInput = LayoutFactory.createTextInput(false, false, Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 160 : 130, HorizontalAlign.RIGHT);
			if (!Constants.isPortrait) makerKeyTextInput.width += 100;
			makerKeyTextInput.fontStyles.size = 11;
			makerKeyTextInput.text = makerKeyValue;
			makerKeyTextInput.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Maker Key Description
			makerKeyDescriptionLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","maker_key_description_label"), HorizontalAlign.CENTER, VerticalAlign.TOP, Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 10 : 9);
			makerKeyDescriptionLabel.wordWrap = true;
			makerKeyDescriptionLabel.width = width - 10;
			
			//Glucose tresholds on/off switch
			glucoseThresholdsSwitch = LayoutFactory.createToggleSwitch(isIFTTTGlucoseThresholdsEnabled);
			glucoseThresholdsSwitch.addEventListener(Event.CHANGE, onSettingsReload);
			
			//Thresholds
			var upperLimit:Number;
			var lowerLimit:Number;
			var step:Number;
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
			{
				upperLimit = 400;
				lowerLimit = 40;
				step = 1;
			}
			else
			{
				upperLimit = (Math.round(400 * BgReading.MGDL_TO_MMOLL * 10))/10;
				lowerLimit = (Math.round(40 * BgReading.MGDL_TO_MMOLL * 10))/10;
				step = 0.1;
			}
			
			//High Glucose Threshold Stepper
			highGlucoseThresholdStepper = LayoutFactory.createNumericStepper(lowerLimit, upperLimit, highGlucoseThresholdValue, step);
			highGlucoseThresholdStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Low Glucose Threshold Stepper
			lowGlucoseThresholdStepper = LayoutFactory.createNumericStepper(lowerLimit, upperLimit, lowGlucoseThresholdValue, step);
			lowGlucoseThresholdStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Glucose Readings
			glucoseReadingCheck = LayoutFactory.createCheckMark(isIFTTTGlucoseReadingsEnabled);
			glucoseReadingCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//HTTP Server
			httpServerErrorsCheck = LayoutFactory.createCheckMark(isIFTTTinteralServerErrorsEnabled);
			httpServerErrorsCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Alarms label
			alarmsLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","alarms_label"), HorizontalAlign.CENTER, VerticalAlign.TOP, 15, true);
			alarmsLabel.width = width - 20;
			
			//Fast Rise Glucose Triggered
			fastRiseGlucoseTriggeredCheck = LayoutFactory.createCheckMark(isIFTTTFastRiseTriggeredEnabled);
			fastRiseGlucoseTriggeredCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Fast Rise Glucose Snoozed
			fastRiseGlucoseSnoozedCheck = LayoutFactory.createCheckMark(isIFTTTFastRiseSnoozedEnabled);
			fastRiseGlucoseSnoozedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Urgent High Glucose Triggered
			urgentHighGlucoseTriggeredCheck = LayoutFactory.createCheckMark(isIFTTTUrgentHighTriggeredEnabled);
			urgentHighGlucoseTriggeredCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Urgent High Glucose Snoozed
			urgentHighGlucoseSnoozedCheck = LayoutFactory.createCheckMark(isIFTTTUrgentHighSnoozedEnabled);
			urgentHighGlucoseSnoozedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//High Glucose Triggered
			highGlucoseTriggeredCheck = LayoutFactory.createCheckMark(isIFTTTHighTriggeredEnabled);
			highGlucoseTriggeredCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//High Glucose Snoozed
			highGlucoseSnoozedCheck = LayoutFactory.createCheckMark(isIFTTTHighSnoozedEnabled);
			highGlucoseSnoozedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Fast Drop Glucose Triggered
			fastDropGlucoseTriggeredCheck = LayoutFactory.createCheckMark(isIFTTTFastDropTriggeredEnabled);
			fastDropGlucoseTriggeredCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Fast Drop Glucose Snoozed
			fastDropGlucoseSnoozedCheck = LayoutFactory.createCheckMark(isIFTTTFastDropSnoozedEnabled);
			fastDropGlucoseSnoozedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Low Glucose Triggered
			lowGlucoseTriggeredCheck = LayoutFactory.createCheckMark(isIFTTTLowTriggeredEnabled);
			lowGlucoseTriggeredCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Low Glucose Snoozed
			lowGlucoseSnoozedCheck = LayoutFactory.createCheckMark(isIFTTTLowSnoozedEnabled);
			lowGlucoseSnoozedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Urgent Low Glucose Triggered
			urgentLowGlucoseTriggeredCheck = LayoutFactory.createCheckMark(isIFTTTUrgentLowTriggeredEnabled);
			urgentLowGlucoseTriggeredCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Urgent Low Glucose Snoozed
			urgentLowGlucoseSnoozedCheck = LayoutFactory.createCheckMark(isIFTTTUrgentLowSnoozedEnabled);
			urgentLowGlucoseSnoozedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Calibration Triggered
			calibrationTriggeredCheck = LayoutFactory.createCheckMark(isIFTTTCalibrationTriggeredEnabled);
			calibrationTriggeredCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Calibration Snoozed
			calibrationSnoozedCheck = LayoutFactory.createCheckMark(isIFTTTCalibrationSnoozedEnabled);
			calibrationSnoozedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Missed Readings Triggered
			missedReadingsTriggeredCheck = LayoutFactory.createCheckMark(isIFTTTMissedReadingsTriggeredEnabled);
			missedReadingsTriggeredCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Missed Readings Snoozed
			missedReadingsSnoozedCheck = LayoutFactory.createCheckMark(isIFTTTMissedReadingsSnoozedEnabled);
			missedReadingsSnoozedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Phone Muted Triggered
			phoneMutedTriggeredCheck = LayoutFactory.createCheckMark(isIFTTTPhoneMutedTriggeredEnabled);
			phoneMutedTriggeredCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Phone Muted Snoozed
			phoneMutedSnoozedCheck = LayoutFactory.createCheckMark(isIFTTTPhoneMutedSnoozedEnabled);
			phoneMutedSnoozedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Transmitter Low Battery Triggered
			transmitterLowBatteryTriggeredCheck = LayoutFactory.createCheckMark(isIFTTTTransmitterLowBatteryTriggeredEnabled);
			transmitterLowBatteryTriggeredCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Transmitter Low Battery Snoozed
			transmitterLowBatterySnoozedCheck = LayoutFactory.createCheckMark(isIFTTTTransmitterLowBatterySnoozedEnabled);
			transmitterLowBatterySnoozedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Treatments label
			treatmentsLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","treatments_label"), HorizontalAlign.CENTER, VerticalAlign.TOP, 15, true);
			treatmentsLabel.width = width - 20;
			
			//IOB Updated
			treatmentIOBUpdatedCheck = LayoutFactory.createCheckMark(isIFTTTiobUpdatedEnabled);
			treatmentIOBUpdatedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//COB Updated
			treatmentCOBUpdatedCheck = LayoutFactory.createCheckMark(isIFTTTcobUpdatedEnabled);
			treatmentCOBUpdatedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Treatment Bolus Added
			treatmentBolusAddedCheck = LayoutFactory.createCheckMark(isIFTTTbolusTreatmentAddedEnabled);
			treatmentBolusAddedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Treatment Bolus Updated
			treatmentBolusUpdatedCheck = LayoutFactory.createCheckMark(isIFTTTbolusTreatmentUpdatedEnabled);
			treatmentBolusUpdatedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Treatment Bolus Deleted
			treatmentBolusDeletedCheck = LayoutFactory.createCheckMark(isIFTTTbolusTreatmentDeletedEnabled);
			treatmentBolusDeletedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Treatment Carbs Added
			treatmentCarbsAddedCheck = LayoutFactory.createCheckMark(isIFTTTcarbsTreatmentAddedEnabled);
			treatmentCarbsAddedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Treatment Carbs Updated
			treatmentCarbsUpdatedCheck = LayoutFactory.createCheckMark(isIFTTTcarbsTreatmentUpdatedEnabled);
			treatmentCarbsUpdatedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Treatment Carbs Deleted
			treatmentCarbsDeletedCheck = LayoutFactory.createCheckMark(isIFTTTcarbsTreatmentDeletedEnabled);
			treatmentCarbsDeletedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Treatment Meal Added
			treatmentMealAddedCheck = LayoutFactory.createCheckMark(isIFTTTmealTreatmentAddedEnabled);
			treatmentMealAddedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Treatment Meal Updated
			treatmentMealUpdatedCheck = LayoutFactory.createCheckMark(isIFTTTmealTreatmentUpdatedEnabled);
			treatmentMealUpdatedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Treatment Meal Deleted
			treatmentMealDeletedCheck = LayoutFactory.createCheckMark(isIFTTTmealTreatmentDeletedEnabled);
			treatmentMealDeletedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Treatment BGCheck Added
			treatmentBGCheckAddedCheck = LayoutFactory.createCheckMark(isIFTTTbgCheckTreatmentAddedEnabled);
			treatmentBGCheckAddedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Treatment BGCheck Updated
			treatmentBGCheckUpdatedCheck = LayoutFactory.createCheckMark(isIFTTTbgCheckTreatmentUpdatedEnabled);
			treatmentBGCheckUpdatedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Treatment BGCheck Deleted
			treatmentBGCheckDeletedCheck = LayoutFactory.createCheckMark(isIFTTTbgCheckTreatmentDeletedEnabled);
			treatmentBGCheckDeletedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Treatment Note Added
			treatmentNoteAddedCheck = LayoutFactory.createCheckMark(isIFTTTnoteTreatmentAddedEnabled);
			treatmentNoteAddedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Treatment Note Updated
			treatmentNoteUpdatedCheck = LayoutFactory.createCheckMark(isIFTTTnoteTreatmentUpdatedEnabled);
			treatmentNoteUpdatedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Treatment Note Deleted
			treatmentNoteDeletedCheck = LayoutFactory.createCheckMark(isIFTTTnoteTreatmentDeletedEnabled);
			treatmentNoteDeletedCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			reloadContent();
		}
		
		private function reloadContent():void
		{
			var screenContent:ArrayCollection = new ArrayCollection();
			screenContent.push({ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","enabled"), accessory: IFTTTToggle });
			
			if (isIFTTTEnabled)
			{
				screenContent.push( { label: "", accessory: instructionsContainer } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","maker_key_label"), accessory: makerKeyTextInput } );
				screenContent.push( { label: "", accessory: makerKeyDescriptionLabel } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","glucose_thresholds_label"), accessory: glucoseThresholdsSwitch } );
				if (isIFTTTGlucoseThresholdsEnabled)
				{
					screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","high_threshold_label"), accessory: highGlucoseThresholdStepper } );
					screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","low_threshold_label"), accessory: lowGlucoseThresholdStepper } );
				}
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","glucose_readings_label"), accessory: glucoseReadingCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","http_server_errors"), accessory: httpServerErrorsCheck } );
				screenContent.push( { label: "", accessory: alarmsLabel } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","fast_rise_glucose_triggered_label"), accessory: fastRiseGlucoseTriggeredCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","fast_rise_glucose_snoozed_label"), accessory: fastRiseGlucoseSnoozedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","urgent_high_glucose_triggered_label"), accessory: urgentHighGlucoseTriggeredCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","urgent_high_glucose_snoozed_label"), accessory: urgentHighGlucoseSnoozedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","high_glucose_triggered_label"), accessory: highGlucoseTriggeredCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","high_glucose_snoozed_label"), accessory: highGlucoseSnoozedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","fast_drop_glucose_triggered_label"), accessory: fastDropGlucoseTriggeredCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","fast_drop_glucose_snoozed_label"), accessory: fastDropGlucoseSnoozedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","low_glucose_triggered_label"), accessory: lowGlucoseTriggeredCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","low_glucose_snoozed_label"), accessory: lowGlucoseSnoozedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","urgent_low_glucose_triggered_label"), accessory: urgentLowGlucoseTriggeredCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","urgent_low_glucose_snoozed_label"), accessory: urgentLowGlucoseSnoozedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","calibration_request_triggered_label"), accessory: calibrationTriggeredCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","calibration_request_snoozed_label"), accessory: calibrationSnoozedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","missed_readings_triggered_label"), accessory: missedReadingsTriggeredCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","missed_readings_snoozed_label"), accessory: missedReadingsSnoozedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","phone_muted_triggered_label"), accessory: phoneMutedTriggeredCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","phone_muted_snoozed_label"), accessory: phoneMutedSnoozedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","transmitter_battery_triggered_label"), accessory: transmitterLowBatteryTriggeredCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","transmitter_battery_snoozed_label"), accessory: transmitterLowBatterySnoozedCheck } );
				screenContent.push( { label: "", accessory: treatmentsLabel } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","iob_updated_label"), accessory: treatmentIOBUpdatedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","cob_updated_label"), accessory: treatmentCOBUpdatedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","bolus_added_label"), accessory: treatmentBolusAddedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","bolus_updated_label"), accessory: treatmentBolusUpdatedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","bolus_deleted_label"), accessory: treatmentBolusDeletedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","carbs_added_label"), accessory: treatmentCarbsAddedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","carbs_updated_label"), accessory: treatmentCarbsUpdatedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","carbs_deleted_label"), accessory: treatmentCarbsDeletedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","meal_added_label"), accessory: treatmentMealAddedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","meal_updated_label"), accessory: treatmentMealUpdatedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","meal_deleted_label"), accessory: treatmentMealDeletedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","bgcheck_added_label"), accessory: treatmentBGCheckAddedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","bgcheck_updated_label"), accessory: treatmentBGCheckUpdatedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","bgcheck_deleted_label"), accessory: treatmentBGCheckDeletedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","note_added_label"), accessory: treatmentNoteAddedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","note_updated_label"), accessory: treatmentNoteUpdatedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","note_deleted_label"), accessory: treatmentNoteDeletedCheck } );
			}
			
			dataProvider = screenContent;
		}
		
		public function save():void
		{
			/* Save data to database */
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_ON) != String(isIFTTTEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_ON, String(isIFTTTEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_FAST_RISE_TRIGGERED_ON) != String(isIFTTTFastRiseTriggeredEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_FAST_RISE_TRIGGERED_ON, String(isIFTTTFastRiseTriggeredEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_FAST_RISE_SNOOZED_ON) != String(isIFTTTFastRiseSnoozedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_FAST_RISE_SNOOZED_ON, String(isIFTTTFastRiseSnoozedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_TRIGGERED_ON) != String(isIFTTTUrgentHighTriggeredEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_TRIGGERED_ON, String(isIFTTTUrgentHighTriggeredEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_SNOOZED_ON) != String(isIFTTTUrgentHighSnoozedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_SNOOZED_ON, String(isIFTTTUrgentHighSnoozedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HIGH_TRIGGERED_ON) != String(isIFTTTHighTriggeredEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HIGH_TRIGGERED_ON, String(isIFTTTHighTriggeredEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HIGH_SNOOZED_ON) != String(isIFTTTHighSnoozedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HIGH_SNOOZED_ON, String(isIFTTTHighSnoozedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_FAST_DROP_TRIGGERED_ON) != String(isIFTTTFastDropTriggeredEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_FAST_DROP_TRIGGERED_ON, String(isIFTTTFastDropTriggeredEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_FAST_DROP_SNOOZED_ON) != String(isIFTTTFastDropSnoozedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_FAST_DROP_SNOOZED_ON, String(isIFTTTFastDropSnoozedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_LOW_TRIGGERED_ON) != String(isIFTTTLowTriggeredEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_LOW_TRIGGERED_ON, String(isIFTTTLowTriggeredEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_LOW_SNOOZED_ON) != String(isIFTTTLowSnoozedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_LOW_SNOOZED_ON, String(isIFTTTLowSnoozedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_LOW_TRIGGERED_ON) != String(isIFTTTUrgentLowTriggeredEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_LOW_TRIGGERED_ON, String(isIFTTTUrgentLowTriggeredEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_LOW_SNOOZED_ON) != String(isIFTTTUrgentLowSnoozedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_LOW_SNOOZED_ON, String(isIFTTTUrgentLowSnoozedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CALIBRATION_TRIGGERED_ON) != String(isIFTTTCalibrationTriggeredEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CALIBRATION_TRIGGERED_ON, String(isIFTTTCalibrationTriggeredEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CALIBRATION_SNOOZED_ON) != String(isIFTTTCalibrationSnoozedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CALIBRATION_SNOOZED_ON, String(isIFTTTCalibrationSnoozedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MISSED_READINGS_TRIGGERED_ON) != String(isIFTTTMissedReadingsTriggeredEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MISSED_READINGS_TRIGGERED_ON, String(isIFTTTMissedReadingsTriggeredEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MISSED_READINGS_SNOOZED_ON) != String(isIFTTTMissedReadingsSnoozedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MISSED_READINGS_SNOOZED_ON, String(isIFTTTMissedReadingsSnoozedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_PHONE_MUTED_TRIGGERED_ON) != String(isIFTTTPhoneMutedTriggeredEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_PHONE_MUTED_TRIGGERED_ON, String(isIFTTTPhoneMutedTriggeredEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_PHONE_MUTED_SNOOZED_ON) != String(isIFTTTPhoneMutedSnoozedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_PHONE_MUTED_SNOOZED_ON, String(isIFTTTPhoneMutedSnoozedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_TRIGGERED_ON) != String(isIFTTTTransmitterLowBatteryTriggeredEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_TRIGGERED_ON, String(isIFTTTTransmitterLowBatteryTriggeredEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_SNOOZED_ON) != String(isIFTTTTransmitterLowBatterySnoozedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_TRANSMITTER_LOW_BATTERY_SNOOZED_ON, String(isIFTTTTransmitterLowBatterySnoozedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_READING_ON) != String(isIFTTTGlucoseReadingsEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_READING_ON, String(isIFTTTGlucoseReadingsEnabled));
			
			var masterKeyToSave:String = Cryptography.encryptStringLight(Keys.STRENGTH_256_BIT, makerKeyValue.replace(" ", ""));
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MAKER_KEY) != masterKeyToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MAKER_KEY, masterKeyToSave);
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_THRESHOLDS_ON) != String(isIFTTTGlucoseThresholdsEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_THRESHOLDS_ON, String(isIFTTTGlucoseThresholdsEnabled));
			
			var highValueToSave:Number;
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
				highValueToSave = highGlucoseThresholdValue;
			else
				highValueToSave = Math.round(BgReading.mmolToMgdl(highGlucoseThresholdValue));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_HIGH_THRESHOLD) != String(highValueToSave))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_HIGH_THRESHOLD, String(highValueToSave));
			
			var lowValueToSave:Number;
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
				lowValueToSave = lowGlucoseThresholdValue;
			else
				lowValueToSave = Math.round(BgReading.mmolToMgdl(lowGlucoseThresholdValue));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_LOW_THRESHOLD) != String(lowValueToSave))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_LOW_THRESHOLD, String(lowValueToSave));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HTTP_SERVER_ERRORS_ON) != String(isIFTTTinteralServerErrorsEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HTTP_SERVER_ERRORS_ON, String(isIFTTTinteralServerErrorsEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BOLUS_ADDED_ON) != String(isIFTTTbolusTreatmentAddedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BOLUS_ADDED_ON, String(isIFTTTbolusTreatmentAddedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BOLUS_UPDATED_ON) != String(isIFTTTbolusTreatmentUpdatedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BOLUS_UPDATED_ON, String(isIFTTTbolusTreatmentUpdatedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BOLUS_DELETED_ON) != String(isIFTTTbolusTreatmentDeletedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BOLUS_DELETED_ON, String(isIFTTTbolusTreatmentDeletedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CARBS_ADDED_ON) != String(isIFTTTcarbsTreatmentAddedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CARBS_ADDED_ON, String(isIFTTTcarbsTreatmentAddedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CARBS_UPDATED_ON) != String(isIFTTTcarbsTreatmentUpdatedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CARBS_UPDATED_ON, String(isIFTTTcarbsTreatmentUpdatedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CARBS_DELETED_ON) != String(isIFTTTcarbsTreatmentDeletedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_CARBS_DELETED_ON, String(isIFTTTcarbsTreatmentDeletedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MEAL_ADDED_ON) != String(isIFTTTmealTreatmentAddedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MEAL_ADDED_ON, String(isIFTTTmealTreatmentAddedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MEAL_UPDATED_ON) != String(isIFTTTmealTreatmentUpdatedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MEAL_UPDATED_ON, String(isIFTTTmealTreatmentUpdatedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MEAL_DELETED_ON) != String(isIFTTTmealTreatmentDeletedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MEAL_DELETED_ON, String(isIFTTTmealTreatmentDeletedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BGCHECK_ADDED_ON) != String(isIFTTTbgCheckTreatmentAddedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BGCHECK_ADDED_ON, String(isIFTTTbgCheckTreatmentAddedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BGCHECK_UPDATED_ON) != String(isIFTTTbgCheckTreatmentUpdatedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BGCHECK_UPDATED_ON, String(isIFTTTbgCheckTreatmentUpdatedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BGCHECK_DELETED_ON) != String(isIFTTTbgCheckTreatmentDeletedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_BGCHECK_DELETED_ON, String(isIFTTTbgCheckTreatmentDeletedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_NOTE_ADDED_ON) != String(isIFTTTnoteTreatmentAddedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_NOTE_ADDED_ON, String(isIFTTTnoteTreatmentAddedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_NOTE_UPDATED_ON) != String(isIFTTTnoteTreatmentUpdatedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_NOTE_UPDATED_ON, String(isIFTTTnoteTreatmentUpdatedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_NOTE_DELETED_ON) != String(isIFTTTnoteTreatmentDeletedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_NOTE_DELETED_ON, String(isIFTTTnoteTreatmentDeletedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_IOB_UPDATED_ON) != String(isIFTTTiobUpdatedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_IOB_UPDATED_ON, String(isIFTTTiobUpdatedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_COB_UPDATED_ON) != String(isIFTTTcobUpdatedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_COB_UPDATED_ON, String(isIFTTTcobUpdatedEnabled));
			
			needsSave = false;
		}
		
		/**
		 * Event Handlers
		 */
		private function onSettingsChanged(E:Event):void
		{
			/* Update Internal Variables */
			isIFTTTFastRiseTriggeredEnabled = fastRiseGlucoseTriggeredCheck.isSelected;
			isIFTTTFastRiseSnoozedEnabled = fastRiseGlucoseSnoozedCheck.isSelected;
			isIFTTTUrgentHighTriggeredEnabled = urgentHighGlucoseTriggeredCheck.isSelected;
			isIFTTTUrgentHighSnoozedEnabled = urgentHighGlucoseSnoozedCheck.isSelected;
			isIFTTTHighTriggeredEnabled = highGlucoseTriggeredCheck.isSelected;
			isIFTTTHighSnoozedEnabled = highGlucoseSnoozedCheck.isSelected;
			isIFTTTFastDropTriggeredEnabled = fastDropGlucoseTriggeredCheck.isSelected;
			isIFTTTFastDropSnoozedEnabled = fastDropGlucoseSnoozedCheck.isSelected;
			isIFTTTLowTriggeredEnabled = lowGlucoseTriggeredCheck.isSelected;
			isIFTTTLowSnoozedEnabled = lowGlucoseSnoozedCheck.isSelected;
			isIFTTTUrgentLowTriggeredEnabled = urgentLowGlucoseTriggeredCheck.isSelected;
			isIFTTTUrgentLowSnoozedEnabled = urgentLowGlucoseSnoozedCheck.isSelected;
			isIFTTTCalibrationTriggeredEnabled = calibrationTriggeredCheck.isSelected;
			isIFTTTCalibrationSnoozedEnabled = calibrationSnoozedCheck.isSelected;
			isIFTTTMissedReadingsTriggeredEnabled = missedReadingsTriggeredCheck.isSelected;
			isIFTTTMissedReadingsSnoozedEnabled = missedReadingsSnoozedCheck.isSelected;
			isIFTTTPhoneMutedTriggeredEnabled = phoneMutedTriggeredCheck.isSelected;
			isIFTTTPhoneMutedSnoozedEnabled = phoneMutedSnoozedCheck.isSelected;
			isIFTTTTransmitterLowBatteryTriggeredEnabled = transmitterLowBatteryTriggeredCheck.isSelected;
			isIFTTTTransmitterLowBatterySnoozedEnabled = transmitterLowBatterySnoozedCheck.isSelected;
			isIFTTTGlucoseReadingsEnabled = glucoseReadingCheck.isSelected;
			makerKeyValue = makerKeyTextInput.text.replace(" ", "");
			highGlucoseThresholdValue = highGlucoseThresholdStepper.value;
			lowGlucoseThresholdValue = lowGlucoseThresholdStepper.value;
			isIFTTTinteralServerErrorsEnabled = httpServerErrorsCheck.isSelected;
			isIFTTTbolusTreatmentAddedEnabled = treatmentBolusAddedCheck.isSelected;
			isIFTTTbolusTreatmentUpdatedEnabled = treatmentBolusUpdatedCheck.isSelected;
			isIFTTTbolusTreatmentDeletedEnabled = treatmentBolusDeletedCheck.isSelected;
			isIFTTTcarbsTreatmentAddedEnabled = treatmentCarbsAddedCheck.isSelected;
			isIFTTTcarbsTreatmentUpdatedEnabled = treatmentCarbsUpdatedCheck.isSelected;
			isIFTTTcarbsTreatmentDeletedEnabled = treatmentCarbsDeletedCheck.isSelected;
			isIFTTTmealTreatmentAddedEnabled = treatmentMealAddedCheck.isSelected;
			isIFTTTmealTreatmentUpdatedEnabled = treatmentMealUpdatedCheck.isSelected;
			isIFTTTmealTreatmentDeletedEnabled = treatmentMealDeletedCheck.isSelected;
			isIFTTTbgCheckTreatmentAddedEnabled = treatmentBGCheckAddedCheck.isSelected;
			isIFTTTbgCheckTreatmentUpdatedEnabled = treatmentBGCheckUpdatedCheck.isSelected;
			isIFTTTbgCheckTreatmentDeletedEnabled = treatmentBGCheckDeletedCheck.isSelected;
			isIFTTTnoteTreatmentAddedEnabled = treatmentNoteAddedCheck.isSelected;
			isIFTTTnoteTreatmentUpdatedEnabled = treatmentNoteUpdatedCheck.isSelected;
			isIFTTTnoteTreatmentDeletedEnabled = treatmentNoteDeletedCheck.isSelected;
			isIFTTTiobUpdatedEnabled = treatmentIOBUpdatedCheck.isSelected;
			isIFTTTcobUpdatedEnabled = treatmentCOBUpdatedCheck.isSelected;
			
			needsSave = true;
		}
		
		private function onSettingsReload(event:Event):void
		{
			isIFTTTEnabled = IFTTTToggle.isSelected;
			isIFTTTGlucoseThresholdsEnabled = glucoseThresholdsSwitch.isSelected;
			reloadContent();
			needsSave = true;
		}
		
		private function onShowInstructions(e:Event):void
		{
			navigateToURL(new URLRequest("https://github.com/SpikeApp/Spike/wiki/IFTTT"));
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (instructionsContainer != null)
				instructionsContainer.width = width - 20;
			
			if (makerKeyDescriptionLabel != null)
				makerKeyDescriptionLabel.width = width - 10;
			
			if (alarmsLabel != null)
				alarmsLabel.width = width - 20;
			
			if (treatmentsLabel != null)
				treatmentsLabel.width = width - 20;
			
			if (makerKeyTextInput != null)
			{
				makerKeyTextInput.width = Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? 160 : 130;
				if (!Constants.isPortrait)
					makerKeyTextInput.width += 100;
			}
			
			setupRenderFactory();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if(IFTTTToggle != null)
			{
				IFTTTToggle.removeEventListener( Event.CHANGE, onSettingsReload );
				IFTTTToggle.dispose();
				IFTTTToggle = null;
			}
			
			if(glucoseThresholdsSwitch != null)
			{
				glucoseThresholdsSwitch.removeEventListener( Event.CHANGE, onSettingsReload );
				glucoseThresholdsSwitch.dispose();
				glucoseThresholdsSwitch = null;
			}
			
			if(fastRiseGlucoseTriggeredCheck != null)
			{
				fastRiseGlucoseTriggeredCheck.removeEventListener( Event.CHANGE, onSettingsChanged);
				fastRiseGlucoseTriggeredCheck.dispose();
				fastRiseGlucoseTriggeredCheck = null;
			}
			
			if(fastRiseGlucoseSnoozedCheck != null)
			{
				fastRiseGlucoseSnoozedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);
				fastRiseGlucoseSnoozedCheck.dispose();
				fastRiseGlucoseSnoozedCheck = null;
			}
			
			if(urgentHighGlucoseTriggeredCheck != null)
			{
				urgentHighGlucoseTriggeredCheck.removeEventListener( Event.CHANGE, onSettingsChanged);
				urgentHighGlucoseTriggeredCheck.dispose();
				urgentHighGlucoseTriggeredCheck = null;
			}
			
			if(urgentHighGlucoseSnoozedCheck != null)
			{
				urgentHighGlucoseSnoozedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);
				urgentHighGlucoseSnoozedCheck.dispose();
				urgentHighGlucoseSnoozedCheck = null;
			}
			
			if(highGlucoseTriggeredCheck != null)
			{
				highGlucoseTriggeredCheck.removeEventListener( Event.CHANGE, onSettingsChanged);
				highGlucoseTriggeredCheck.dispose();
				highGlucoseTriggeredCheck = null;
			}
			
			if(highGlucoseSnoozedCheck != null)
			{
				highGlucoseSnoozedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);
				highGlucoseSnoozedCheck.dispose();
				highGlucoseSnoozedCheck = null;
			}
			
			if(fastDropGlucoseTriggeredCheck != null)
			{
				fastDropGlucoseTriggeredCheck.removeEventListener( Event.CHANGE, onSettingsChanged);
				fastDropGlucoseTriggeredCheck.dispose();
				fastDropGlucoseTriggeredCheck = null;
			}
			
			if(fastDropGlucoseSnoozedCheck != null)
			{
				fastDropGlucoseSnoozedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);
				fastDropGlucoseSnoozedCheck.dispose();
				fastDropGlucoseSnoozedCheck = null;
			}
			
			if(lowGlucoseTriggeredCheck != null)
			{
				lowGlucoseTriggeredCheck.removeEventListener( Event.CHANGE, onSettingsChanged);
				lowGlucoseTriggeredCheck.dispose();
				lowGlucoseTriggeredCheck = null;
			}
			
			if(lowGlucoseSnoozedCheck != null)
			{
				lowGlucoseSnoozedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);
				lowGlucoseSnoozedCheck.dispose();
				lowGlucoseSnoozedCheck = null;
			}
			
			if(urgentLowGlucoseTriggeredCheck != null)
			{
				urgentLowGlucoseTriggeredCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				urgentLowGlucoseTriggeredCheck.dispose();
				urgentLowGlucoseTriggeredCheck = null;
			}
			
			if(urgentLowGlucoseSnoozedCheck != null)
			{
				urgentLowGlucoseSnoozedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				urgentLowGlucoseSnoozedCheck.dispose();
				urgentLowGlucoseSnoozedCheck = null;
			}
			
			if(calibrationTriggeredCheck != null)
			{
				calibrationTriggeredCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				calibrationTriggeredCheck.dispose();
				calibrationTriggeredCheck = null;
			}
			
			if(calibrationSnoozedCheck != null)
			{
				calibrationSnoozedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				calibrationSnoozedCheck.dispose();
				calibrationSnoozedCheck = null;
			}
			
			if(missedReadingsTriggeredCheck != null)
			{
				missedReadingsTriggeredCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				missedReadingsTriggeredCheck.dispose();
				missedReadingsTriggeredCheck = null;
			}
			
			if(missedReadingsSnoozedCheck != null)
			{
				missedReadingsSnoozedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				missedReadingsSnoozedCheck.dispose();
				missedReadingsSnoozedCheck = null;
			}
			
			if(phoneMutedTriggeredCheck != null)
			{
				phoneMutedTriggeredCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				phoneMutedTriggeredCheck.dispose();
				phoneMutedTriggeredCheck = null;
			}
			
			if(phoneMutedSnoozedCheck != null)
			{
				phoneMutedSnoozedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				phoneMutedSnoozedCheck.dispose();
				phoneMutedSnoozedCheck = null;
			}
			
			if(transmitterLowBatteryTriggeredCheck != null)
			{
				transmitterLowBatteryTriggeredCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				transmitterLowBatteryTriggeredCheck.dispose();
				transmitterLowBatteryTriggeredCheck = null;
			}
			
			if(transmitterLowBatterySnoozedCheck != null)
			{
				transmitterLowBatterySnoozedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				transmitterLowBatterySnoozedCheck.dispose();
				transmitterLowBatterySnoozedCheck = null;
			}
			
			if(glucoseReadingCheck != null)
			{
				glucoseReadingCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				glucoseReadingCheck.dispose();
				glucoseReadingCheck = null;
			}
			
			if(makerKeyTextInput != null)
			{
				makerKeyTextInput.removeEventListener( Event.CHANGE, onSettingsChanged);	
				makerKeyTextInput.dispose();
				makerKeyTextInput = null;
			}
			
			if(makerKeyDescriptionLabel != null)
			{
				makerKeyDescriptionLabel.removeEventListener( Event.CHANGE, onSettingsChanged);	
				makerKeyDescriptionLabel.dispose();
				makerKeyDescriptionLabel = null;
			}
			
			if(highGlucoseThresholdStepper != null)
			{
				highGlucoseThresholdStepper.removeEventListener( Event.CHANGE, onSettingsChanged);	
				highGlucoseThresholdStepper.dispose();
				highGlucoseThresholdStepper = null;
			}
			
			if(lowGlucoseThresholdStepper != null)
			{
				lowGlucoseThresholdStepper.removeEventListener( Event.CHANGE, onSettingsChanged);	
				lowGlucoseThresholdStepper.dispose();
				lowGlucoseThresholdStepper = null;
			}
			
			if(httpServerErrorsCheck != null)
			{
				httpServerErrorsCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				httpServerErrorsCheck.dispose();
				httpServerErrorsCheck = null;
			}
			
			if(alarmsLabel != null)
			{
				alarmsLabel.dispose();
				alarmsLabel = null;
			}
			
			if(instructionsButton != null)
			{
				instructionsButton.removeEventListener( Event.CHANGE, onShowInstructions);
				instructionsContainer.removeChild(instructionsButton);
				instructionsButton.dispose();
				instructionsButton = null;
			}
			
			if(instructionsContainer != null)
			{
				instructionsContainer.dispose();
				instructionsContainer = null;
			}
			
			if(treatmentsLabel != null)
			{
				treatmentsLabel.dispose();
				treatmentsLabel = null;
			}
			
			if(treatmentIOBUpdatedCheck != null)
			{
				treatmentIOBUpdatedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentIOBUpdatedCheck.dispose();
				treatmentIOBUpdatedCheck = null;
			}
			
			if(treatmentCOBUpdatedCheck != null)
			{
				treatmentCOBUpdatedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentCOBUpdatedCheck.dispose();
				treatmentCOBUpdatedCheck = null;
			}
			
			if(treatmentBolusAddedCheck != null)
			{
				treatmentBolusAddedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentBolusAddedCheck.dispose();
				treatmentBolusAddedCheck = null;
			}
			
			if(treatmentBolusUpdatedCheck != null)
			{
				treatmentBolusUpdatedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentBolusUpdatedCheck.dispose();
				treatmentBolusUpdatedCheck = null;
			}
			
			if(treatmentBolusDeletedCheck != null)
			{
				treatmentBolusDeletedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentBolusDeletedCheck.dispose();
				treatmentBolusDeletedCheck = null;
			}
			
			if(treatmentCarbsAddedCheck != null)
			{
				treatmentCarbsAddedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentCarbsAddedCheck.dispose();
				treatmentCarbsAddedCheck = null;
			}
			
			if(treatmentCarbsUpdatedCheck != null)
			{
				treatmentCarbsUpdatedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentCarbsUpdatedCheck.dispose();
				treatmentCarbsUpdatedCheck = null;
			}
			
			if(treatmentCarbsDeletedCheck != null)
			{
				treatmentCarbsDeletedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentCarbsDeletedCheck.dispose();
				treatmentCarbsDeletedCheck = null;
			}
			
			if(treatmentMealAddedCheck != null)
			{
				treatmentMealAddedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentMealAddedCheck.dispose();
				treatmentMealAddedCheck = null;
			}
			
			if(treatmentMealUpdatedCheck != null)
			{
				treatmentMealUpdatedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentMealUpdatedCheck.dispose();
				treatmentMealUpdatedCheck = null;
			}
			
			if(treatmentMealDeletedCheck != null)
			{
				treatmentMealDeletedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentMealDeletedCheck.dispose();
				treatmentMealDeletedCheck = null;
			}
			
			if(treatmentBGCheckAddedCheck != null)
			{
				treatmentBGCheckAddedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentBGCheckAddedCheck.dispose();
				treatmentBGCheckAddedCheck = null;
			}
			
			if(treatmentBGCheckUpdatedCheck != null)
			{
				treatmentBGCheckUpdatedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentBGCheckUpdatedCheck.dispose();
				treatmentBGCheckUpdatedCheck = null;
			}
			
			if(treatmentBGCheckDeletedCheck != null)
			{
				treatmentBGCheckDeletedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentBGCheckDeletedCheck.dispose();
				treatmentBGCheckDeletedCheck = null;
			}
			
			if(treatmentNoteAddedCheck != null)
			{
				treatmentNoteAddedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentNoteAddedCheck.dispose();
				treatmentNoteAddedCheck = null;
			}
			
			if(treatmentNoteUpdatedCheck != null)
			{
				treatmentNoteUpdatedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentNoteUpdatedCheck.dispose();
				treatmentNoteUpdatedCheck = null;
			}
			
			if(treatmentNoteDeletedCheck != null)
			{
				treatmentNoteDeletedCheck.removeEventListener( Event.CHANGE, onSettingsChanged);	
				treatmentNoteDeletedCheck.dispose();
				treatmentNoteDeletedCheck = null;
			}
			
			super.dispose();
		}
	}
}