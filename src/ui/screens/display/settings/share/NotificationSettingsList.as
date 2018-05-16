package ui.screens.display.settings.share
{
	import database.LocalSettings;
	
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
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
	
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("sharesettingsscreen")]

	public class NotificationSettingsList extends List 
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
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
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