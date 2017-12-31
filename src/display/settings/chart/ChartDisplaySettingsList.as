package display.settings.chart
{
	import flash.system.System;
	
	import databaseclasses.CommonSettings;
	
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
	
	[ResourceBundle("chartsettingsscreen")]

	public class ChartDisplaySettingsList extends List 
	{
		/* Display Objects */
		private var enablePieChart:ToggleSwitch;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var pieChartEnabledValue:Boolean;
		
		public function ChartDisplaySettingsList()
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
			enablePieChart = LayoutFactory.createToggleSwitch();
			
			/* Set Size Settings Item Renderer */
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			/* Set  Data */
			dataProvider = new ArrayCollection(
				[
					{ text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','enable_pie_chart'), accessory: enablePieChart }
				]);
		}
		
		private function setupInitialState():void
		{
			//Retrieve data from database
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_PIE_CHART) == "true")
				pieChartEnabledValue = true;
			else
				pieChartEnabledValue = false;
			
			//Set control state
			enablePieChart.isSelected = pieChartEnabledValue;
				
			//Add event listeners
			enablePieChart.addEventListener(Event.CHANGE, onEnablePieChartChanged);
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
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_PIE_CHART) != valueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_PIE_CHART, valueToSave);
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onEnablePieChartChanged(e:Event):void
		{
			//Update internal variables
			pieChartEnabledValue = enablePieChart.isSelected
			needsSave = true;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (enablePieChart != null)
			{
				enablePieChart.removeEventListener(Event.CHANGE, onEnablePieChartChanged);
				enablePieChart.dispose();
				enablePieChart = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}