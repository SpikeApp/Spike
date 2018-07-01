package ui.screens.display.settings.share
{
	import database.LocalSettings;
	
	import feathers.controls.ToggleSwitch;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	
	[ResourceBundle("sharesettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class HealthkitSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var hkToggle:ToggleSwitch;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var isHKEnabled:Boolean;
		
		public function HealthkitSettingsList()
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
			isHKEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) == "true";
		}
		
		private function setupContent():void
		{
			//Healthkit On/Off Toggle
			hkToggle = LayoutFactory.createToggleSwitch(isHKEnabled);
			hkToggle.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Define HealthKit Settings Data
			dataProvider = new ArrayCollection(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled_label'), accessory: hkToggle },
				]);
		}
		
		public function save():void
		{
			var valueToSave:String;
			if (isHKEnabled == true)
				valueToSave = "true";
			else
				valueToSave = "false";
			
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON) != valueToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_HEALTHKIT_STORE_ON, valueToSave);
			
			needsSave = false;
		}
		
		/**
		 * Event Handlers
		 */
		private function onSettingsChanged(e:Event):void
		{
			isHKEnabled = hkToggle.isSelected;

			save();
		}
		
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if(hkToggle != null)
			{
				hkToggle.removeEventListener(Event.CHANGE, onSettingsChanged);
				hkToggle.dispose();
				hkToggle = null;
			}
			
			super.dispose();
		}
	}
}