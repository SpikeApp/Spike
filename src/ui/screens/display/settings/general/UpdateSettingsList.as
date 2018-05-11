package ui.screens.display.settings.general
{
	import database.CommonSettings;
	
	import feathers.controls.List;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("globaltranslations")]

	public class UpdateSettingsList extends List 
	{
		/* Display Objects */
		private var updatesToggle:ToggleSwitch;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var updatesEnabled:Boolean;
		
		public function UpdateSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			setupProperties();
			setupContent();
			setupInitialState();
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
			if(Constants.deviceModel == DeviceInfo.IPHONE_X)
				updatesToggle.pivotX = -8;
			
			//Define Notifications Settings Data
			dataProvider = new ArrayCollection(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled'), accessory: updatesToggle }
				]);
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
		}
		
		private function setupInitialState():void
		{
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_UPDATE_NOTIFICATIONS_ON) == "true") updatesEnabled = true;
			else updatesEnabled = false;
			
			updatesToggle.isSelected = updatesEnabled;
			updatesToggle.addEventListener( Event.CHANGE, onUpdatesOnOff );
		}
		
		public function save():void
		{
			var updateValueToSave:String;
			if(updatesEnabled) updateValueToSave = "true";
			else updateValueToSave = "false";
			
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_UPDATE_NOTIFICATIONS_ON) != updateValueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_APP_UPDATE_NOTIFICATIONS_ON, updateValueToSave);
			
			needsSave = false;
		}
		
		/**
		 * Event Handlers
		 */
		private function onUpdatesOnOff(event:Event):void
		{
			updatesEnabled = updatesToggle.isSelected;
			needsSave = true;
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