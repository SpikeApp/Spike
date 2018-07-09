package ui.screens.display.settings.general
{
	import database.CommonSettings;
	
	import feathers.controls.PickerList;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	
	[ResourceBundle("generalsettingsscreen")]

	public class LanguageSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var appLanguagePicker:PickerList;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var appLanguageValue:String;		
		
		public function LanguageSettingsList()
		{
			super(true);
			
			setupProperties();
			setupInitialContent();	
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			/* Set Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialContent():void
		{
			/* Get Values From Database */
			appLanguageValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_LANGUAGE);
		}
		
		private function setupContent():void
		{
			//Collection Picker List
			appLanguagePicker = LayoutFactory.createPickerList();
			
			/* Set DateFormatPicker Data */
			var appLanguageLabelsList:Array = ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','app_language_labels_list').split(",");
			var appLanguageCodesList:Array = ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','app_language_codes_list').split(",");
			var appLanguageList:ArrayCollection = new ArrayCollection();
			var selectedIndex:int = 0;
			for (var i:int = 0; i < appLanguageLabelsList.length; i++) 
			{
				appLanguageList.push( { label: appLanguageLabelsList[i], code: appLanguageCodesList[i] } );
				if (appLanguageCodesList[i] == appLanguageValue)
					selectedIndex = i;
			}
			appLanguageLabelsList.length = 0;
			appLanguageLabelsList = null;
			appLanguageCodesList.length = 0;
			appLanguageCodesList = null;
			appLanguagePicker.labelField = "label";
			appLanguagePicker.popUpContentManager = new DropDownPopUpContentManager();
			appLanguagePicker.dataProvider = appLanguageList;
			appLanguagePicker.selectedIndex = selectedIndex;
			appLanguagePicker.addEventListener(Event.CHANGE, onLanguageChanged);
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var data:Array = [];
			data.push( { label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','language_title'), accessory: appLanguagePicker } );
			dataProvider = new ArrayCollection(data);
		}
		
		public function save():void
		{
			//Update Database
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_LANGUAGE) != appLanguageValue)
			{
				ModelLocator.resourceManagerInstance.localeChain = [appLanguageValue,"en_US"];
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_APP_LANGUAGE, appLanguageValue);
			}
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onLanguageChanged(e:Event):void
		{
			//Update internal variables
			appLanguageValue = appLanguagePicker.selectedItem.code;
			needsSave = true;
		}
		
		/**
		 * Event Listeners
		 */
		override public function dispose():void
		{
			if (appLanguagePicker != null)
			{
				appLanguagePicker.removeEventListener(Event.CHANGE, onLanguageChanged);
				appLanguagePicker.dispose();
				appLanguagePicker = null;
			}
			
			super.dispose();
		}
	}
}