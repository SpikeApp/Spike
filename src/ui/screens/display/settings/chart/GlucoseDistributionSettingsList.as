package ui.screens.display.settings.chart
{
	import database.BlueToothDevice;
	import database.CommonSettings;
	
	import feathers.controls.Check;
	import feathers.controls.List;
	import feathers.controls.PickerList;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.popups.DropDownPopUpContentManager;
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
	[ResourceBundle("chartsettingsscreen")]

	public class GlucoseDistributionSettingsList extends List 
	{
		/* Display Objects */
		private var enableGlucoseDistribution:ToggleSwitch;
		private var percentageRangePicker:PickerList;
		private var avgRangePicker:PickerList;
		private var a1cRangePicker:PickerList;
		private var a1cIFCCCheck:Check;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var pieChartEnabledValue:Boolean;
		private var percentageRangeValue:Number;
		private var a1cRangeValue:Number;
		private var avgRangeValue:Number;
		private var isA1CIFCC:Boolean;
		
		public function GlucoseDistributionSettingsList()
		{
			super();
			
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
			/* Set Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialState():void
		{
			//Retrieve data from database
			pieChartEnabledValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_GLUCOSE_DISTRIBUTION) == "true";
			percentageRangeValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_RANGES_OFFSET));
			a1cRangeValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_A1C_OFFSET));
			avgRangeValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_AVG_OFFSET));
			isA1CIFCC = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_A1C_IFCC_ON) == "true";
		}
		
		private function setupContent():void
		{
			/* Controls */
			enableGlucoseDistribution = LayoutFactory.createToggleSwitch(pieChartEnabledValue);
			enableGlucoseDistribution.pivotX = 5;
			enableGlucoseDistribution.addEventListener(Event.CHANGE, onEnableGlucoseDistributionChanged);
			
			var rangesLabels:Array = ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','glucose_distribution_range_labels').split(",");
			var rangesValues:Array = ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','glucose_distribution_range_values').split(",");
			var i:int;
			var value:Number;
			
			percentageRangePicker = LayoutFactory.createPickerList();
			percentageRangePicker.dataProvider = new ArrayCollection();
			for (i = 0; i < rangesLabels.length; i++) 
			{
				value = Number(rangesValues[i]);
				percentageRangePicker.dataProvider.push( { label: rangesLabels[i], value: value } );
				if (value == percentageRangeValue)
					percentageRangePicker.selectedIndex = i;
			}
			percentageRangePicker.labelField = "label";
			percentageRangePicker.popUpContentManager = new DropDownPopUpContentManager();
			percentageRangePicker.addEventListener(Event.CHANGE, onSettingsChanged);
			
			avgRangePicker = LayoutFactory.createPickerList();
			avgRangePicker.dataProvider = new ArrayCollection();
			for (i = 0; i < rangesLabels.length; i++) 
			{
				value = Number(rangesValues[i]);
				avgRangePicker.dataProvider.push( { label: rangesLabels[i], value: value } );
				if (value == avgRangeValue)
					avgRangePicker.selectedIndex = i;
			}
			avgRangePicker.labelField = "label";
			avgRangePicker.popUpContentManager = new DropDownPopUpContentManager();
			avgRangePicker.addEventListener(Event.CHANGE, onSettingsChanged);
			
			a1cRangePicker = LayoutFactory.createPickerList();
			a1cRangePicker.dataProvider = new ArrayCollection();
			for (i = 0; i < rangesLabels.length; i++) 
			{
				value = Number(rangesValues[i]);
				a1cRangePicker.dataProvider.push( { label: rangesLabels[i], value: value } );
				if (value == a1cRangeValue)
					a1cRangePicker.selectedIndex = i;
			}
			a1cRangePicker.labelField = "label";
			a1cRangePicker.popUpContentManager = new DropDownPopUpContentManager();
			a1cRangePicker.addEventListener(Event.CHANGE, onSettingsChanged);
			
			a1cIFCCCheck = LayoutFactory.createCheckMark(isA1CIFCC);
			a1cIFCCCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Set List Item Renderer */
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.paddingRight = 0;
				return itemRenderer;
			};
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var data:Array = [];
			data.push( { text: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled_label'), accessory: enableGlucoseDistribution } );
			if (pieChartEnabledValue)
			{
				if (!BlueToothDevice.isFollower())
				{
					data.push( { text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','thresholds_range_label'), accessory: percentageRangePicker } );
					data.push( { text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','average_glucose_range_label'), accessory: avgRangePicker } );
					data.push( { text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','a1c_range_label'), accessory: a1cRangePicker } );
				}
				data.push( { text: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','a1c_ifcc_label'), accessory: a1cIFCCCheck } );
			}
			
			dataProvider = new ArrayCollection( data );
		}
		
		public function save():void
		{
			//Update Database
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_GLUCOSE_DISTRIBUTION) != String(pieChartEnabledValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_GLUCOSE_DISTRIBUTION, String(pieChartEnabledValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_A1C_OFFSET) != String(a1cRangeValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_A1C_OFFSET, String(a1cRangeValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_AVG_OFFSET) != String(avgRangeValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_AVG_OFFSET, String(avgRangeValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_RANGES_OFFSET) != String(percentageRangeValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_RANGES_OFFSET, String(percentageRangeValue));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_A1C_IFCC_ON) != String(isA1CIFCC))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_PIE_CHART_A1C_IFCC_ON, String(isA1CIFCC));
			
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
			refreshContent();
		}
		
		private function onSettingsChanged(e:Event):void
		{
			percentageRangeValue = Number(percentageRangePicker.selectedItem.value);
			a1cRangeValue = Number(a1cRangePicker.selectedItem.value);
			avgRangeValue = Number(avgRangePicker.selectedItem.value);
			isA1CIFCC = a1cIFCCCheck.isSelected;
			
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
			
			if (enableGlucoseDistribution != null)
			{
				enableGlucoseDistribution.removeEventListener(Event.CHANGE, onEnableGlucoseDistributionChanged);
				enableGlucoseDistribution.dispose();
				enableGlucoseDistribution = null;
			}
			
			if (a1cRangePicker != null)
			{
				a1cRangePicker.removeEventListener(Event.CHANGE, onSettingsChanged);
				a1cRangePicker.dispose();
				a1cRangePicker = null;
			}
			
			if (avgRangePicker != null)
			{
				avgRangePicker.removeEventListener(Event.CHANGE, onSettingsChanged);
				avgRangePicker.dispose();
				avgRangePicker = null;
			}
			
			if (percentageRangePicker != null)
			{
				percentageRangePicker.removeEventListener(Event.CHANGE, onSettingsChanged);
				percentageRangePicker.dispose();
				percentageRangePicker = null;
			}
			
			if (a1cIFCCCheck != null)
			{
				a1cIFCCCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				a1cIFCCCheck.dispose();
				a1cIFCCCheck = null;
			}
			
			super.dispose();
		}
	}
}