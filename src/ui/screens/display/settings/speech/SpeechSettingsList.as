package ui.screens.display.settings.speech
{
	import com.adobe.utils.StringUtil;
	
	import database.BgReading;
	import database.CommonSettings;
	import database.LocalSettings;
	
	import feathers.controls.Alert;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.Slider;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.popups.VerticalCenteredPopUpContentManager;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("speechsettingsscreen")]
	[ResourceBundle("alarmsettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class SpeechSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var speechToggle:ToggleSwitch;
		private var trendToggle:ToggleSwitch;
		private var deltaToggle:ToggleSwitch;
		private var speechInterval:NumericStepper;
		private var languagePicker:PickerList;
		private var glucoseThresholdsToggle:ToggleSwitch;
		private var highGlucoseStepper:NumericStepper;
		private var lowGlucoseStepper:NumericStepper;
		private var controlSystemVolumeToggle:ToggleSwitch;
		private var volumeSliderContainer:LayoutGroup;
		private var customSystemValueLabel:Label;
		private var systemVolumeSlider:Slider;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var selectedLanguageCode:String;
		private var selectedLanguageIndex:int;
		private var isSpeechEnabled:Boolean;
		private var isTrendEnabled:Boolean;
		private var isDeltaEnabled:Boolean;
		private var selectedInterval:int;
		private var initialInstructionsDisplayed:Boolean;
		private var useGlucoseThresholds:Boolean;
		private var glucoseThresholdHigh:Number;
		private var glucoseThresholdLow:Number;
		private var glucoseUnit:String;
		private var isSystemVolumeUserDefined:Boolean;
		private var userDefinedSystemVolume:Number;
		
		public function SpeechSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupInitialState();
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
		
		private function setupInitialState():void
		{
			/* Get data from database */
			selectedLanguageCode = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_LANGUAGE);
			isSpeechEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_ON) == "true";
			isTrendEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_TREND_ON) == "true";
			isDeltaEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_DELTA_ON) == "true";
			selectedInterval = int(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_INTERVAL));
			initialInstructionsDisplayed = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_SPEECH_INSTRUCTIONS_ACCEPTED) == "true";
			glucoseUnit = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? "mgdl" : "mmol";
			useGlucoseThresholds = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_ON) == "true";
			glucoseThresholdHigh = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_HIGH) == "0" ? Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK)) : Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_HIGH));
			if (glucoseUnit != "mgdl") glucoseThresholdHigh = Math.round(BgReading.mgdlToMmol(glucoseThresholdHigh) * 10) / 10;
			glucoseThresholdLow = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_LOW) == "0" ? Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK)) : Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_LOW));
			if (glucoseUnit != "mgdl") glucoseThresholdLow = Math.round(BgReading.mgdlToMmol(glucoseThresholdLow) * 10) / 10;
			isSystemVolumeUserDefined = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_USER_DEFINED_SYSTEM_VOLUME_ON) == "true";
			userDefinedSystemVolume = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_USER_DEFINED_SYSTEM_VOLUME_VALUE));
		}
		
		private function setupContent():void
		{
			//On/Off Toggle
			speechToggle = LayoutFactory.createToggleSwitch(isSpeechEnabled);
			speechToggle.addEventListener( Event.CHANGE, onSpeechOnOff );
			
			//Trend Toggle
			trendToggle = LayoutFactory.createToggleSwitch(isTrendEnabled);
			trendToggle.addEventListener( Event.CHANGE, onSettingsChanged);
			
			//Delta Toggle
			deltaToggle = LayoutFactory.createToggleSwitch(isDeltaEnabled);
			deltaToggle.addEventListener( Event.CHANGE, onSettingsChanged);
			
			//Thresholds On/Off Toggle
			glucoseThresholdsToggle = LayoutFactory.createToggleSwitch(useGlucoseThresholds);
			glucoseThresholdsToggle.addEventListener( Event.CHANGE, onGlucoseThresholdToggleChanged);
			
			//High/Low Thresholds
			highGlucoseStepper = LayoutFactory.createNumericStepper(glucoseUnit == "mgdl" ? 50 : Math.round(BgReading.mgdlToMmol(50) * 10) / 10, glucoseUnit == "mgdl" ? 400 : Math.round(BgReading.mgdlToMmol(400) * 10) / 10, glucoseThresholdHigh, glucoseUnit == "mgdl" ? 1 : 0.1);
			highGlucoseStepper.addEventListener( Event.CHANGE, onGlucoseThresholdHighChanged);
			
			lowGlucoseStepper = LayoutFactory.createNumericStepper(glucoseUnit == "mgdl" ? 40 : Math.round(BgReading.mgdlToMmol(40) * 10) / 10, glucoseUnit == "mgdl" ? 390 : Math.round(BgReading.mgdlToMmol(390) * 10) / 10, glucoseThresholdLow, glucoseUnit == "mgdl" ? 1 : 0.1);
			lowGlucoseStepper.addEventListener( Event.CHANGE, onGlucoseThresholdLowChanged);
			
			//Interval
			speechInterval = LayoutFactory.createNumericStepper(1, 1000, 1);
			speechInterval.value = selectedInterval;
			speechInterval.addEventListener( Event.CHANGE, onSettingsChanged);
			
			//System Volume
			controlSystemVolumeToggle = LayoutFactory.createToggleSwitch(isSystemVolumeUserDefined);
			controlSystemVolumeToggle.addEventListener(Event.CHANGE, onSystemVolumeToggleChanged);
			var volumeSliderLayout:VerticalLayout = new VerticalLayout();
			volumeSliderLayout.horizontalAlign = HorizontalAlign.RIGHT;
			volumeSliderLayout.gap = 0;
			volumeSliderContainer = new LayoutGroup();
			volumeSliderContainer.layout = volumeSliderLayout;
			customSystemValueLabel = LayoutFactory.createLabel(userDefinedSystemVolume + "%", HorizontalAlign.CENTER, VerticalAlign.TOP, 12);
			volumeSliderContainer.addChild(customSystemValueLabel);
			systemVolumeSlider = new Slider();
			systemVolumeSlider.minimum = 0;
			systemVolumeSlider.maximum = 100;
			systemVolumeSlider.step = 1;
			systemVolumeSlider.value = userDefinedSystemVolume;
			volumeSliderContainer.addChild(systemVolumeSlider);
			systemVolumeSlider.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Language Picker */
			languagePicker = LayoutFactory.createPickerList();
			languagePicker.pivotX = -3;
			
			//Temp Data Objects
			var languagesLabelsList:Array = ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','ttslanguagelistdescription').split(",");
			var languagesCodesList:Array = "zh-CN,zh-HK,zh-TW,da-DK,nl-BE,nl-NL,en-AU,en-IE,en-ZA,en-GB,en-US,fi-FI,fr-CA,fr-FR,de-DE,it-IT,no-NO,pl-PL,pt-BR,pt-PT,ru-RU,sl-SL,es-MX,es-ES,sv-SE".split(",");
			var languagePickerList:Array = new Array();
			var dataLength:int = languagesLabelsList.length;
			for (var i:int = 0; i < dataLength; i++) 
			{
				languagePickerList.push({ label: StringUtil.trim(languagesLabelsList[i]), code: StringUtil.trim(languagesCodesList[i]) });
			}
			languagePickerList.sortOn(["label"], Array.CASEINSENSITIVE);
			for (i = 0; i < languagePickerList.length; i++) 
			{
				var object:Object = languagePickerList[i];
				if (StringUtil.trim(selectedLanguageCode) == object.code)
					selectedLanguageIndex = i;
			}
			languagesLabelsList.length = 0;
			languagesLabelsList = null
			languagesCodesList.length = 0;
			languagesCodesList = null;
			
			// Populate data and define renderers
			languagePicker.labelField = "label";
			languagePicker.dataProvider = new ArrayCollection(languagePickerList);
			languagePicker.selectedIndex = selectedLanguageIndex;
			var languagePopUp:VerticalCenteredPopUpContentManager = new VerticalCenteredPopUpContentManager();
			languagePopUp.margin = 10;
			languagePicker.popUpContentManager = languagePopUp;
			languagePicker.addEventListener( Event.CHANGE, onSettingsChanged);
			
			reloadSpeechSettings(isSpeechEnabled);
		}
		
		public function save():void
		{
			/* Save data to database */
			//Language Code
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_LANGUAGE) != StringUtil.trim(selectedLanguageCode))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_LANGUAGE, StringUtil.trim(selectedLanguageCode));
			
			//Speak Interval
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_INTERVAL) != String(selectedInterval))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_INTERVAL, String(selectedInterval));
			
			//Speech Enabled
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_ON) != String(isSpeechEnabled))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_ON, String(isSpeechEnabled));
			
			//Trend Enabled
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_TREND_ON) != String(isTrendEnabled))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_TREND_ON, String(isTrendEnabled));
			
			//Delta Enabled
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_DELTA_ON) != String(isDeltaEnabled))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_DELTA_ON, String(isDeltaEnabled));
			
			//Thresholds
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_ON) != String(useGlucoseThresholds))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_ON, String(useGlucoseThresholds));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_HIGH) != String(glucoseUnit == "mgdl" ? glucoseThresholdHigh : Math.round(BgReading.mmolToMgdl(glucoseThresholdHigh))))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_HIGH, String(glucoseUnit == "mgdl" ? glucoseThresholdHigh : Math.round(BgReading.mmolToMgdl(glucoseThresholdHigh))));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_LOW) != String(glucoseUnit == "mgdl" ? glucoseThresholdLow : Math.round(BgReading.mmolToMgdl(glucoseThresholdLow))))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_LOW, String(glucoseUnit == "mgdl" ? glucoseThresholdLow : Math.round(BgReading.mmolToMgdl(glucoseThresholdLow))));
			
			//System Volume
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_USER_DEFINED_SYSTEM_VOLUME_ON) != String(isSystemVolumeUserDefined))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_USER_DEFINED_SYSTEM_VOLUME_ON, String(isSystemVolumeUserDefined));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_USER_DEFINED_SYSTEM_VOLUME_VALUE) != String(userDefinedSystemVolume))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_USER_DEFINED_SYSTEM_VOLUME_VALUE, String(userDefinedSystemVolume));
			
			needsSave = false;
		}
		
		private function reloadSpeechSettings(fullDisplay:Boolean):void
		{
			if(fullDisplay)
			{
				var data:Array = [];
				data.push( { label: ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','speak_bg_readings_title'), accessory: speechToggle } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','speak_bg_trend_title'), accessory: trendToggle } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','speak_bg_delta_title'), accessory: deltaToggle } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','speak_bg_readings_interval_title'), accessory: speechInterval } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','use_glucose_thresholds_label'), accessory: glucoseThresholdsToggle } );
				if (useGlucoseThresholds)
				{
					data.push( { label: ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','high_threshold_label'), accessory: highGlucoseStepper } );
					data.push( { label: ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','low_threshold_label'), accessory: lowGlucoseStepper } );
				}
				data.push( { label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"override_system_volume_label"), accessory: controlSystemVolumeToggle } );
				if(isSystemVolumeUserDefined)
				{
					data.push( { label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"custom_system_volume_label"), accessory: volumeSliderContainer } );
				}
				data.push( { label: ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','speak_bg_readings_language_title'), accessory: languagePicker } );
				
				dataProvider = new ArrayCollection(data);
			}
			else
			{
				dataProvider = new ArrayCollection(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled_label'), accessory: speechToggle },
				]);
			}
		}
		
		/**
		 * Event Handlers
		 */
		private function onSettingsChanged(E:Event):void
		{
			/* Update Internal Variables */
			isTrendEnabled = trendToggle.isSelected;
			isDeltaEnabled = deltaToggle.isSelected;
			selectedInterval = speechInterval.value;
			selectedLanguageCode = languagePicker.selectedItem.code;
			userDefinedSystemVolume = systemVolumeSlider.value;
			customSystemValueLabel.text = userDefinedSystemVolume + "%";
			
			needsSave = true;
		}
		
		private function onSystemVolumeToggleChanged(E:Event):void
		{
			isSystemVolumeUserDefined = controlSystemVolumeToggle.isSelected;
			
			if(speechToggle.isSelected) reloadSpeechSettings(true);
		}
		
		private function onGlucoseThresholdToggleChanged(E:Event):void
		{
			/* Update Internal Variables */
			useGlucoseThresholds = glucoseThresholdsToggle.isSelected;
			
			needsSave = true;
			
			if(speechToggle.isSelected) reloadSpeechSettings(true);
		}
		
		private function onGlucoseThresholdHighChanged(E:Event):void
		{
			glucoseThresholdHigh = highGlucoseStepper.value;
			
			if (glucoseThresholdHigh <= glucoseThresholdLow)
			{
				glucoseThresholdLow = glucoseThresholdHigh - (glucoseUnit == "mgdl" ? 1 : 0.1);
				lowGlucoseStepper.value = glucoseThresholdLow;
			}
			
			needsSave = true;
		}
		
		private function onGlucoseThresholdLowChanged(E:Event):void
		{
			glucoseThresholdLow = lowGlucoseStepper.value;
			
			if (glucoseThresholdLow >= glucoseThresholdHigh)
			{
				glucoseThresholdHigh = glucoseThresholdLow + (glucoseUnit == "mgdl" ? 1 : 0.1);
				highGlucoseStepper.value = glucoseThresholdHigh;
			}
				
			needsSave = true;
		}
		
		private function onSpeechOnOff(event:Event):void
		{
			isSpeechEnabled = speechToggle.isSelected;
			needsSave = true;
			
			if(speechToggle.isSelected)
			{
				reloadSpeechSettings(true);
				
				if (!initialInstructionsDisplayed)
				{
					//Display Initial Instructions
					var alert:Alert = AlertManager.showActionAlert
					(
						ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','speech_settings_title'),
						ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','initial_instructions'),
						Number.NaN,
						[
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','dont_show_again_alert_button_label'), triggered: onDisableSpeechInstructions },
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','ok_alert_button_label') }
						]
					);
					if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
						alert.height = 320;
					
					initialInstructionsDisplayed = true;
				}
			}
			else
				reloadSpeechSettings(false);
		}	
		
		private function onDisableSpeechInstructions(e:Event):void
		{
			//Don't warn the user again
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_SPEECH_INSTRUCTIONS_ACCEPTED, "true");
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if(speechToggle != null)
			{
				speechToggle.removeEventListener( Event.CHANGE, onSpeechOnOff );
				speechToggle.dispose();
				speechToggle = null;
			}
			if(trendToggle != null)
			{
				trendToggle.removeEventListener( Event.CHANGE, onSettingsChanged);
				trendToggle.dispose();
				trendToggle = null;
			}
			if(deltaToggle != null)
			{
				deltaToggle.removeEventListener( Event.CHANGE, onSettingsChanged);
				deltaToggle.dispose();
				deltaToggle = null;
			}
			if(speechInterval != null)
			{
				speechInterval.removeEventListener( Event.CHANGE, onSettingsChanged);
				speechInterval.dispose();
				speechInterval = null;
			}
			if(languagePicker != null)
			{
				languagePicker.removeEventListener( Event.CHANGE, onSettingsChanged);	
				languagePicker.dispose();
				languagePicker = null;
			}
			if(glucoseThresholdsToggle != null)
			{
				glucoseThresholdsToggle.removeEventListener( Event.CHANGE, onGlucoseThresholdToggleChanged);	
				glucoseThresholdsToggle.dispose();
				glucoseThresholdsToggle = null;
			}
			if(highGlucoseStepper != null)
			{
				highGlucoseStepper.removeEventListener( Event.CHANGE, onGlucoseThresholdHighChanged);	
				highGlucoseStepper.dispose();
				highGlucoseStepper = null;
			}
			if(lowGlucoseStepper != null)
			{
				lowGlucoseStepper.removeEventListener( Event.CHANGE, onGlucoseThresholdLowChanged);	
				lowGlucoseStepper.dispose();
				lowGlucoseStepper = null;
			}
			
			if (controlSystemVolumeToggle != null)
			{
				controlSystemVolumeToggle.removeEventListener(Event.CHANGE, onSystemVolumeToggleChanged);
				controlSystemVolumeToggle.removeFromParent();
				controlSystemVolumeToggle.dispose();
				controlSystemVolumeToggle = null;
			}
			
			if (systemVolumeSlider != null)
			{
				systemVolumeSlider.removeEventListener(Event.CHANGE, onSettingsChanged);
				systemVolumeSlider.removeFromParent();
				systemVolumeSlider.dispose();
				systemVolumeSlider = null;
			}
			
			if (customSystemValueLabel != null)
			{
				customSystemValueLabel.removeFromParent();
				customSystemValueLabel.dispose();
				customSystemValueLabel = null;
			}
			
			if (volumeSliderContainer != null)
			{
				volumeSliderContainer.removeFromParent();
				volumeSliderContainer.dispose();
				volumeSliderContainer = null;
			}
			
			super.dispose();
		}
	}
}