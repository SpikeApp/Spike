package ui.screens.display.settings.share
{
	import database.LocalSettings;
	
	import feathers.controls.Check;
	import feathers.controls.List;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	
	[ResourceBundle("globaltranslations")]

	public class AppBadgeSettingsList extends List 
	{
		/* Display Objects */
		private var appBadgeToggle:ToggleSwitch;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var appBadgeEnabled:Boolean;
		
		public function AppBadgeSettingsList()
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
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_APP_BADGE) == "true") appBadgeEnabled = true;
			else appBadgeEnabled = false;
		}
		
		private function setupContent():void
		{
			//Notifications On/Off Toggle
			appBadgeToggle = LayoutFactory.createToggleSwitch(appBadgeEnabled);
			appBadgeToggle.addEventListener(Event.CHANGE, onAppBadgeChanged);
			
			//Mmmol multiplier
			var mmolMultiplierCheck:Check = LayoutFactory.createCheckMark(true);
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var content:Array = [];
			content.push( { text: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled'), accessory: appBadgeToggle } );
			
			dataProvider = new ArrayCollection(content);
		}
		
		public function save():void
		{
			var appBadgeValueToSave:String;
			if(appBadgeEnabled) appBadgeValueToSave = "true";
			else appBadgeValueToSave = "false";
			
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_APP_BADGE) != appBadgeValueToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_APP_BADGE, appBadgeValueToSave);
			
			needsSave = false;
		}
		
		/**
		 * Event Handlers
		 */
		private function onAppBadgeChanged(e:Event):void
		{
			appBadgeEnabled = appBadgeToggle.isSelected;
			needsSave = true;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if(appBadgeToggle != null)
			{
				appBadgeToggle.removeEventListener(Event.CHANGE, onAppBadgeChanged);
				appBadgeToggle.dispose();
				appBadgeToggle = null;
			}
			
			super.dispose();
		}
	}
}