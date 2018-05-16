package ui.screens.display.settings.speech
{
	import database.CommonSettings;
	import database.LocalSettings;
	
	import feathers.controls.Alert;
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.popups.VerticalCenteredPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("speechsettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class SpeechSettingsList extends List 
	{
		/* Display Objects */
		private var speechToggle:ToggleSwitch;
		private var trendToggle:ToggleSwitch;
		private var deltaToggle:ToggleSwitch;
		private var speechInterval:NumericStepper;
		private var languagePicker:PickerList;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var selectedLanguageCode:String;
		private var selectedLanguageIndex:int;
		private var isSpeechEnabled:Boolean;
		private var isTrendEnabled:Boolean;
		private var isDeltaEnabled:Boolean;
		private var selectedInterval:int;
		private var initialInstructionsDisplayed:Boolean;
		
		public function SpeechSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
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
			
			//Interval
			speechInterval = LayoutFactory.createNumericStepper(1, 1000, 1);
			speechInterval.value = selectedInterval;
			speechInterval.addEventListener( Event.CHANGE, onSettingsChanged);
			
			/* Language Picker */
			languagePicker = LayoutFactory.createPickerList();
			languagePicker.pivotX = -3;
			
			//Temp Data Objects
			var languagesLabelsList:Array = ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','ttslanguagelistdescription').split(",");
			var languagesCodesList:Array = ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','ttslanguagelistcodes').split(",");
			var languagePickerList:ArrayCollection = new ArrayCollection();
			var dataLength:int = languagesLabelsList.length;
			for (var i:int = 0; i < dataLength; i++) 
			{
				languagePickerList.push({ label: languagesLabelsList[i], code: languagesCodesList[i] });
				if (selectedLanguageCode == languagesCodesList[i])
					selectedLanguageIndex = i;
			}
			
			languagesLabelsList.length = 0;
			languagesLabelsList = null
			languagesCodesList.length = 0;
			languagesCodesList = null;
			
			// Populate data and define renderers
			languagePicker.labelField = "label";
			languagePicker.dataProvider = languagePickerList;
			languagePicker.selectedIndex = selectedLanguageIndex;
			var languagePopUp:VerticalCenteredPopUpContentManager = new VerticalCenteredPopUpContentManager();
			languagePopUp.margin = 10;
			languagePicker.popUpContentManager = languagePopUp;
			languagePicker.addEventListener( Event.CHANGE, onSettingsChanged);
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			reloadSpeechSettings(isSpeechEnabled);
		}
		
		public function save():void
		{
			/* Save data to database */
			//Language Code
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_LANGUAGE) != selectedLanguageCode)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_LANGUAGE, selectedLanguageCode);
			
			//Speak Interval
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_INTERVAL) != String(selectedInterval))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_INTERVAL, String(selectedInterval));
			
			//Speech Enabled
			var speechValueToSave:String
			if (isSpeechEnabled)
				speechValueToSave = "true";
			else
				speechValueToSave = "false";
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_ON) != speechValueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_ON, speechValueToSave);
			
			//Trend Enabled
			var trendValueToSave:String
			if (isTrendEnabled)
				trendValueToSave = "true";
			else
				trendValueToSave = "false";
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_TREND_ON) != trendValueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_TREND_ON, trendValueToSave);
			
			//Delta Enabled
			var deltaValueToSave:String
			if (isDeltaEnabled)
				deltaValueToSave = "true";
			else
				deltaValueToSave = "false";
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_DELTA_ON) != deltaValueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_DELTA_ON, deltaValueToSave);
			
			
			needsSave = false;
		}
		
		private function reloadSpeechSettings(fullDisplay:Boolean):void
		{
			if(fullDisplay)
			{
				dataProvider = new ArrayCollection(
					[
						{ label: ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','speak_bg_readings_title'), accessory: speechToggle },
						{ label: ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','speak_bg_trend_title'), accessory: trendToggle },
						{ label: ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','speak_bg_delta_title'), accessory: deltaToggle },
						{ label: ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','speak_bg_readings_interval_title'), accessory: speechInterval },
						{ label: ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','speak_bg_readings_language_title'), accessory: languagePicker },
					]);
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
					if (Constants.deviceModel == DeviceInfo.IPHONE_X)
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
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
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
			
			super.dispose();
		}
	}
}