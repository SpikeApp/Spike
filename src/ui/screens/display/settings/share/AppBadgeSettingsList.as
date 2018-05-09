package ui.screens.display.settings.share
{
	import database.CommonSettings;
	import database.LocalSettings;
	
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("sharesettingsscreen")]

	public class AppBadgeSettingsList extends List 
	{
		/* Display Objects */
		private var appBadgeToggle:ToggleSwitch;
		private var mmolMultiplierCheck:Check;
		private var mmolMultiplierLabel:Label;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var appBadgeEnabled:Boolean;
		private var mmolMultiplierEnabled:Boolean;
		
		public function AppBadgeSettingsList()
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
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_APP_BADGE) == "true") appBadgeEnabled = true;
			else appBadgeEnabled = false;
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_BADGE_MMOL_MULTIPLIER_ON) == "true") mmolMultiplierEnabled = true;
			else mmolMultiplierEnabled = false;
		}
		
		private function setupContent():void
		{
			//Notifications On/Off Toggle
			appBadgeToggle = LayoutFactory.createToggleSwitch(appBadgeEnabled);
			appBadgeToggle.addEventListener(Event.CHANGE, onAppBadgeChanged);
			
			//Mmmol multiplier
			mmolMultiplierCheck = LayoutFactory.createCheckMark(mmolMultiplierEnabled);
			mmolMultiplierCheck.addEventListener(Event.CHANGE, onMMOLMultiplierChanged);
			
			//Mmmol multiplier description
			mmolMultiplierLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','mmol_multiplier_description'), HorizontalAlign.JUSTIFY);
			mmolMultiplierLabel.wordWrap = true; 
			mmolMultiplierLabel.width = width - 20;
			mmolMultiplierLabel.paddingTop = mmolMultiplierLabel.paddingBottom = 10;
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			(layout as VerticalLayout).hasVariableItemDimensions = true;
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var content:Array = [];
			content.push( { text: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled'), accessory: appBadgeToggle } );
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true")
			{
				content.push( { text: ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','mmol_multiplier_label'), accessory: mmolMultiplierCheck } );
				content.push( { text: "", accessory: mmolMultiplierLabel } );
			}
				
			
			dataProvider = new ArrayCollection(content);
		}
		
		public function save():void
		{
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_APP_BADGE) != String(appBadgeEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_ALWAYS_ON_APP_BADGE, String(appBadgeEnabled));
			
			if(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_BADGE_MMOL_MULTIPLIER_ON) != String(mmolMultiplierEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_APP_BADGE_MMOL_MULTIPLIER_ON, String(mmolMultiplierEnabled));
			
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
		
		private function onMMOLMultiplierChanged(e:Event):void
		{
			mmolMultiplierEnabled = mmolMultiplierCheck.isSelected;
			needsSave = true;
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (mmolMultiplierLabel != null)
				mmolMultiplierLabel.width = width - 20;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if(appBadgeToggle != null)
			{
				appBadgeToggle.removeEventListener(Event.CHANGE, onAppBadgeChanged);
				appBadgeToggle.dispose();
				appBadgeToggle = null;
			}
			
			if(mmolMultiplierCheck != null)
			{
				mmolMultiplierCheck.removeEventListener(Event.CHANGE, onMMOLMultiplierChanged);
				mmolMultiplierCheck.dispose();
				mmolMultiplierCheck = null;
			}
			
			if(mmolMultiplierLabel != null)
			{
				mmolMultiplierLabel.dispose();
				mmolMultiplierLabel = null;
			}
			
			super.dispose();
		}
	}
}