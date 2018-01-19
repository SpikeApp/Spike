package ui.screens.display.settings.chart
{
	import databaseclasses.CommonSettings;
	
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

	public class GlucoseDistributionSettingsList extends List 
	{
		/* Display Objects */
		private var enableGlucoseDistribution:ToggleSwitch;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var pieChartEnabledValue:Boolean;
		
		public function GlucoseDistributionSettingsList()
		{
			super();
			
			setupProperties();
			setupContent();
			setupInitialState();	
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			/* Set Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupContent():void
		{
			/* Controls */
			enableGlucoseDistribution = LayoutFactory.createToggleSwitch();
			enableGlucoseDistribution.pivotX = 5;
			
			/* Set Size Settings Item Renderer */
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.paddingRight = 0;
				return itemRenderer;
			};
			
			/* Set  Data */
			dataProvider = new ArrayCollection(
				[
					{ text: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled_label'), accessory: enableGlucoseDistribution }
				]);
		}
		
		private function setupInitialState():void
		{
			//Retrieve data from database
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_GLUCOSE_DISTRIBUTION) == "true")
				pieChartEnabledValue = true;
			else
				pieChartEnabledValue = false;
			
			//Set control state
			enableGlucoseDistribution.isSelected = pieChartEnabledValue;
				
			//Add event listeners
			enableGlucoseDistribution.addEventListener(Event.CHANGE, onEnableGlucoseDistributionChanged);
		}
		
		public function save():void
		{
			//Convert Boolean to string
			var valueToSave:String;
			if (pieChartEnabledValue)
				valueToSave = "true";
			else
				valueToSave = "false";
			
			//Update Database
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_GLUCOSE_DISTRIBUTION) != valueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_GLUCOSE_DISTRIBUTION, valueToSave);
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onEnableGlucoseDistributionChanged(e:Event):void
		{
			//Update internal variables
			pieChartEnabledValue = enableGlucoseDistribution.isSelected
			needsSave = true;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (enableGlucoseDistribution != null)
			{
				enableGlucoseDistribution.removeEventListener(Event.CHANGE, onEnableGlucoseDistributionChanged);
				enableGlucoseDistribution.dispose();
				enableGlucoseDistribution = null;
			}
			
			super.dispose();
		}
	}
}