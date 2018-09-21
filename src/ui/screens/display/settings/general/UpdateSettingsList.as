package ui.screens.display.settings.general
{
	import database.CommonSettings;
	
	import feathers.controls.ToggleSwitch;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("globaltranslations")]

	public class UpdateSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var updatesToggle:ToggleSwitch;
		
		/* Properties */
		private var updatesEnabled:Boolean;
		
		public function UpdateSettingsList()
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
		
		private function setupContent():void
		{
			///Notifications On/Off Toggle
			updatesToggle = LayoutFactory.createToggleSwitch(false);
			if(Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				updatesToggle.pivotX = -8;
			updatesToggle.isSelected = updatesEnabled;
			updatesToggle.addEventListener( Event.CHANGE, onUpdatesOnOff );
			
			//Define Notifications Settings Data
			dataProvider = new ArrayCollection(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled'), accessory: updatesToggle }
				]);
		}
		
		private function setupInitialState():void
		{
			updatesEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_CENTER_UPDATE_NOTIFICATIONS_ON) == "true";
		}
		
		public function save():void
		{
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_CENTER_UPDATE_NOTIFICATIONS_ON) != String(updatesEnabled))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_APP_CENTER_UPDATE_NOTIFICATIONS_ON, String(updatesEnabled));
		}
		
		/**
		 * Event Handlers
		 */
		private function onUpdatesOnOff(event:Event):void
		{
			updatesEnabled = updatesToggle.isSelected;
			save();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if(updatesToggle != null)
			{
				updatesToggle.removeEventListener( Event.CHANGE, onUpdatesOnOff );
				updatesToggle.dispose();
				updatesToggle = null;
			}
			
			super.dispose();
		}
	}
}