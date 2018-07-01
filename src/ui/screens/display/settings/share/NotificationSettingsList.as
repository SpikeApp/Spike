package ui.screens.display.settings.share
{
	import database.LocalSettings;
	
	import feathers.controls.NumericStepper;
	import feathers.controls.ToggleSwitch;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("sharesettingsscreen")]

	public class NotificationSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var notificationsToggle:ToggleSwitch;
		private var notificationsIntervalStepper:NumericStepper;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var notificationsEnabled:Boolean;
		private var notificationsIntervalValue:Number;
		
		public function NotificationSettingsList()
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
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_NOTIFICATION) == "true") notificationsEnabled = true;
			else notificationsEnabled = false;
			
			notificationsIntervalValue = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_NOTIFICATION_INTERVAL));
		}
		
		private function setupContent():void
		{
			//Notifications On/Off Toggle
			notificationsToggle = LayoutFactory.createToggleSwitch(notificationsEnabled);
			notificationsToggle.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Interval
			notificationsIntervalStepper = LayoutFactory.createNumericStepper(1, 1000, notificationsIntervalValue, 1);
			notificationsIntervalStepper.pivotX = -10;
			notificationsIntervalStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			//Define Notifications Settings Data
			var displayContent:Array = [];
			displayContent.push( { label: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled'), accessory: notificationsToggle } );
			if (notificationsEnabled)
				displayContent.push( { label: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','interval_label') , accessory: notificationsIntervalStepper } );
			
			dataProvider = new ArrayCollection(displayContent);
		}
		
		public function save():void
		{
			var notificationValueToSave:String;
			if(notificationsEnabled) notificationValueToSave = "true";
			else notificationValueToSave = "false";
			
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_NOTIFICATION) != notificationValueToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_NOTIFICATION, notificationValueToSave);
			
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_NOTIFICATION_INTERVAL) != String(notificationsIntervalValue))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_NOTIFICATION_INTERVAL, String(notificationsIntervalValue));
			
			needsSave = false;
		}
		
		/**
		 * Event Handlers
		 */
		private function onSettingsChanged(e:Event):void
		{
			var previousNotificationSetting:Boolean = notificationsEnabled;
			notificationsEnabled = notificationsToggle.isSelected;
			notificationsIntervalValue = notificationsIntervalStepper.value;
			
			if (previousNotificationSetting != notificationsEnabled)
				refreshContent();
			needsSave = true;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if(notificationsToggle != null)
			{
				notificationsToggle.removeEventListener(Event.CHANGE, onSettingsChanged);
				notificationsToggle.dispose();
				notificationsToggle = null;
			}
			
			if(notificationsIntervalStepper != null)
			{
				notificationsIntervalStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				notificationsIntervalStepper.dispose();
				notificationsIntervalStepper = null;
			}
			
			super.dispose();
		}
	}
}