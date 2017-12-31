package display.settings.loggingtracing
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
	
	import starling.events.Event;
	
	import utils.Constants;

	public class LoggingSettingsList extends List 
	{
		/* Display Objects */
		private var nsLogToggle:ToggleSwitch;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var isNSLogEnabled:Boolean;
		
		public function LoggingSettingsList()
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
			isNSLogEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_NSLOG) == "true";
		}
		
		private function setupContent():void
		{
			//On/Off Toggle
			nsLogToggle = LayoutFactory.createToggleSwitch(isNSLogEnabled);
			nsLogToggle.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Define NSLog Settings Data
			dataProvider = new ArrayCollection(
				[
					{ label: "Enabled", accessory: nsLogToggle },
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
		
		public function save():void
		{
			var valueToSave:String
			if(isNSLogEnabled) valueToSave = "true";
			else valueToSave = "false";
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_NSLOG) != valueToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_NSLOG, valueToSave);
			
			needsSave = false;
		}
		
		/**
		 * Event Handlers
		 */
		private function onSettingsChanged(e:Event):void
		{
			isNSLogEnabled = nsLogToggle.isSelected;
			
			needsSave = true;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if(nsLogToggle != null)
			{
				nsLogToggle.removeEventListener(Event.CHANGE, onSettingsChanged);
				nsLogToggle.dispose();
				nsLogToggle = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}