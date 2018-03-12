package ui.screens.display.settings.integration
{
	import database.BgReading;
	import database.CommonSettings;
	import database.LocalSettings;
	
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	
	[ResourceBundle("iftttsettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class IFTTTSettingsList extends List 
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
			isIFTTTUrgentHighTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_TRIGGERED_ON) == "true";
			isIFTTTUrgentHighSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_SNOOZED_ON) == "true";
			isIFTTTHighTriggeredEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HIGH_TRIGGERED_ON) == "true";
			isIFTTTHighSnoozedEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HIGH_SNOOZED_ON) == "true";
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
			makerKeyValue = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MAKER_KEY);
			isIFTTTGlucoseThresholdsEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_THRESHOLDS_ON) == "true";
			highGlucoseThresholdValue = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_HIGH_THRESHOLD));
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
				highGlucoseThresholdValue = (Math.round(highGlucoseThresholdValue * BgReading.MGDL_TO_MMOLL * 10))/10;
			lowGlucoseThresholdValue = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_GLUCOSE_LOW_THRESHOLD));
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
				lowGlucoseThresholdValue = (Math.round(lowGlucoseThresholdValue * BgReading.MGDL_TO_MMOLL * 10))/10;
		}
		
		private function setupContent():void
		{
			//On/Off Toggle
			IFTTTToggle = LayoutFactory.createToggleSwitch(isIFTTTEnabled);
			IFTTTToggle.addEventListener( Event.CHANGE, onSettingsReload );
			
			//Maker Key Input Field
			makerKeyTextInput = LayoutFactory.createTextInput(false, false, 160, HorizontalAlign.RIGHT);
			makerKeyTextInput.fontStyles.size = 11;
			makerKeyTextInput.text = makerKeyValue;
			makerKeyTextInput.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Maker Key Description
			makerKeyDescriptionLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","maker_key_description_label"), HorizontalAlign.CENTER, VerticalAlign.TOP, 10);
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
				upperLimit = 600;
				lowerLimit = 40;
				step = 1;
			}
			else
			{
				upperLimit = (Math.round(600 * BgReading.MGDL_TO_MMOLL * 10))/10;
				lowerLimit = (Math.round(40 * BgReading.MGDL_TO_MMOLL * 10))/10;
				step = 0.1;
			}
			
			//High Glucose Threshold Stepper
			highGlucoseThresholdStepper = LayoutFactory.createNumericStepper(lowerLimit, upperLimit, highGlucoseThresholdValue, step);
			highGlucoseThresholdStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Low Glucose Threshold Stepper
			lowGlucoseThresholdStepper = LayoutFactory.createNumericStepper(lowerLimit, upperLimit, lowGlucoseThresholdValue, step);
			lowGlucoseThresholdStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			
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
			
			//Glucose Readings
			glucoseReadingCheck = LayoutFactory.createCheckMark(isIFTTTGlucoseReadingsEnabled);
			glucoseReadingCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			reloadContent();
		}
		
		private function reloadContent():void
		{
			var screenContent:ArrayCollection = new ArrayCollection();
			screenContent.push({ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","enabled"), accessory: IFTTTToggle });
			
			if (isIFTTTEnabled)
			{
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","maker_key_label"), accessory: makerKeyTextInput } );
				screenContent.push( { label: "", accessory: makerKeyDescriptionLabel } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","glucose_thresholds_label"), accessory: glucoseThresholdsSwitch } );
				if (isIFTTTGlucoseThresholdsEnabled)
				{
					screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","high_threshold_label"), accessory: highGlucoseThresholdStepper } );
					screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","low_threshold_label"), accessory: lowGlucoseThresholdStepper } );
				}
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","glucose_readings_label"), accessory: glucoseReadingCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","urgent_high_glucose_triggered_label"), accessory: urgentHighGlucoseTriggeredCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","urgent_high_glucose_snoozed_label"), accessory: urgentHighGlucoseSnoozedCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","high_glucose_triggered_label"), accessory: highGlucoseTriggeredCheck } );
				screenContent.push( { label: ModelLocator.resourceManagerInstance.getString("iftttsettingsscreen","high_glucose_snoozed_label"), accessory: highGlucoseSnoozedCheck } );
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
			}
			
			dataProvider = screenContent;
		}
		
		public function save():void
		{
			/* Save data to database */
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_ON) != String(isIFTTTEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_ON, String(isIFTTTEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_TRIGGERED_ON) != String(isIFTTTUrgentHighTriggeredEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_TRIGGERED_ON, String(isIFTTTUrgentHighTriggeredEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_SNOOZED_ON) != String(isIFTTTUrgentHighSnoozedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_URGENT_HIGH_SNOOZED_ON, String(isIFTTTUrgentHighSnoozedEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HIGH_TRIGGERED_ON) != String(isIFTTTHighTriggeredEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HIGH_TRIGGERED_ON, String(isIFTTTHighTriggeredEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HIGH_SNOOZED_ON) != String(isIFTTTHighSnoozedEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_HIGH_SNOOZED_ON, String(isIFTTTHighSnoozedEnabled));
			
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
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MAKER_KEY) != makerKeyValue.replace(" ", ""))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_IFTTT_MAKER_KEY, makerKeyValue.replace(" ", ""));
			
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
			
			needsSave = false;
		}
		
		/**
		 * Event Handlers
		 */
		private function onSettingsChanged(E:Event):void
		{
			/* Update Internal Variables */
			isIFTTTUrgentHighTriggeredEnabled = urgentHighGlucoseTriggeredCheck.isSelected;
			isIFTTTUrgentHighSnoozedEnabled = urgentHighGlucoseSnoozedCheck.isSelected;
			isIFTTTHighTriggeredEnabled = highGlucoseTriggeredCheck.isSelected;
			isIFTTTHighSnoozedEnabled = highGlucoseSnoozedCheck.isSelected;
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
			
			needsSave = true;
		}
		
		private function onSettingsReload(event:Event):void
		{
			isIFTTTEnabled = IFTTTToggle.isSelected;
			isIFTTTGlucoseThresholdsEnabled = glucoseThresholdsSwitch.isSelected;
			reloadContent();
			needsSave = true;
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
			
			super.dispose();
		}
	}
}