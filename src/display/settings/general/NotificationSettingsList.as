package display.settings.general
{
	import flash.system.System;
	
	import databaseclasses.LocalSettings;
	
	import display.LayoutFactory;
	
	import feathers.controls.List;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import utils.Constants;
	
	[ResourceBundle("globalsettings")]

	public class NotificationSettingsList extends List 
	{
		/* Display Objects */
		private var notificationsToggle:ToggleSwitch;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var notificationsEnabled:Boolean;
		
		public function NotificationSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
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
			//Notifications On/Off Toggle
			notificationsToggle = LayoutFactory.createToggleSwitch(false);
			
			//Define Notifications Settings Data
			var settingsData:ArrayCollection = new ArrayCollection(
				[
					{ text: ModelLocator.resourceManagerInstance.getString('globalsettings','enabled'), accessory: notificationsToggle },
				]);
			dataProvider = settingsData;
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
		}
		
		private function setupInitialState():void
		{
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_NOTIFICATION) == "true") notificationsEnabled = true;
			else notificationsEnabled = false;
			
			notificationsToggle.isSelected = notificationsEnabled;
			notificationsToggle.addEventListener(Event.CHANGE, onLocalNotificationsChanged);
		}
		
		public function save():void
		{
			var notificationValueToSave:String;
			if(notificationsEnabled) notificationValueToSave = "true";
			else notificationValueToSave = "false";
			
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_NOTIFICATION) != notificationValueToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_NOTIFICATION, notificationValueToSave);
			
			needsSave = false;
		}
		
		/**
		 * Event Handlers
		 */
		private function onLocalNotificationsChanged(e:Event):void
		{
			notificationsEnabled = notificationsToggle.isSelected;
			needsSave = true;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if(notificationsToggle != null)
			{
				notificationsToggle.dispose();
				notificationsToggle = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}