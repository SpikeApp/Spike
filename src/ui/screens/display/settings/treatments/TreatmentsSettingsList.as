package ui.screens.display.settings.treatments
{
	import feathers.controls.Check;
	import feathers.controls.List;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.layout.AnchorLayoutData;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	import ui.screens.Screens;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	
	public class TreatmentsSettingsList extends List 
	{
		/* Display Objects */
		private var chevronIconTexture:Texture;
		private var profileIconImage:Image;
		private var treatmentsEnabled:ToggleSwitch;
		private var nightscoutSyncEnabled:Check;
		private var chartDisplayEnabled:Check;
		
		/* Internal Variables */
		public var needsSave:Boolean = false;
		private var treatmentsEnabledValue:Boolean;
		private var nightscoutSyncEnabledValue:Boolean;
		private var chartDisplayEnabledValue:Boolean;
		
		public function TreatmentsSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupInitialContent();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			/* Properties */
			clipContent = false;
			isSelectable = true;
			autoHideBackground = true;
			hasElasticEdges = false;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialContent():void
		{
			treatmentsEnabledValue = true;
			chartDisplayEnabledValue = true;
			nightscoutSyncEnabledValue = true;
		}
		
		private function setupContent():void
		{
			/* Icons */
			chevronIconTexture = MaterialDeepGreyAmberMobileThemeIcons.chevronRightTexture;
			profileIconImage = new Image(chevronIconTexture);
			
			/* Enable/Disable Switch */
			treatmentsEnabled = LayoutFactory.createToggleSwitch(treatmentsEnabledValue);
			treatmentsEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Display on Chart */
			chartDisplayEnabled = LayoutFactory.createCheckMark(chartDisplayEnabledValue);
			chartDisplayEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Enable/Disable Nightscout Sync */
			nightscoutSyncEnabled = LayoutFactory.createCheckMark(nightscoutSyncEnabledValue);
			nightscoutSyncEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Renderer */
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				item.itemHasSelectable = true;
				item.selectableField = "selectable";
				return item;
			};
			
			layoutData = new AnchorLayoutData( 0, 0, 0, 0 );
			addEventListener( Event.CHANGE, onMenuChanged );
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			/* Data */
			var data:Array = [];
			
			data.push({ screen: Screens.SETTINGS_PROFILE, label: "Profile", accessory: profileIconImage, selectable: true });
			data.push({ screen: Screens.SETTINGS_PROFILE, label: "Enabled", accessory: treatmentsEnabled, selectable: false });
			if (treatmentsEnabledValue)
			{
				data.push({ screen: Screens.SETTINGS_PROFILE, label: "Display on Chart", accessory: chartDisplayEnabled, selectable: false });
				data.push({ screen: Screens.SETTINGS_PROFILE, label: "Nightscout Download Sync", accessory: nightscoutSyncEnabled, selectable: false });
			}
			
			dataProvider = new ListCollection(data);
		}
		
		public function save():void
		{
			
		}
		
		/**
		 * Event Handlers
		 */
		private function onSettingsChanged(e:Event):void
		{
			treatmentsEnabledValue = treatmentsEnabled.isSelected;
			chartDisplayEnabledValue = chartDisplayEnabled.isSelected;
			nightscoutSyncEnabledValue = nightscoutSyncEnabled.isSelected;
			
			refreshContent();
			
			needsSave = true;
		}
		
		private function onMenuChanged(e:Event):void 
		{
			const screenName:String = selectedItem.screen as String;
			AppInterface.instance.navigator.pushScreen( screenName );
		}
		
		/**
		 * Utility 
		 */
		override public function dispose():void
		{
			removeEventListener( Event.CHANGE, onMenuChanged );
			
			if (chevronIconTexture != null)
			{
				chevronIconTexture.dispose();
				chevronIconTexture = null;
			}
			
			if (profileIconImage != null)
			{
				profileIconImage.dispose();
				profileIconImage = null;
			}
			
			if (treatmentsEnabled != null)
			{
				treatmentsEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				treatmentsEnabled.dispose();
				treatmentsEnabled = null;
			}
			
			if (chartDisplayEnabled != null)
			{
				chartDisplayEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				chartDisplayEnabled.dispose();
				chartDisplayEnabled = null;
			}
			
			if (nightscoutSyncEnabled != null)
			{
				nightscoutSyncEnabled.removeEventListener(Event.CHANGE, onSettingsChanged);
				nightscoutSyncEnabled.dispose();
				nightscoutSyncEnabled = null;
			}
			
			super.dispose();
		}
	}
}