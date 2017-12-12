package display.settings.chart
{
	import flash.system.System;
	
	import display.LayoutFactory;
	
	import feathers.controls.List;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import utils.Constants;

	public class DisplaySettingsList extends List 
	{
		/* Display Objects */
		private var enablePieChart:ToggleSwitch;
		
		public function DisplaySettingsList()
		{
			super();
			
			/* Set Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			/* Controls */
			enablePieChart = LayoutFactory.createToggleSwitch(true);
			
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
					{ text: "Pie Chart Enabled", accessory: enablePieChart }
				]);
		}
		
		override public function dispose():void
		{
			if (enablePieChart != null)
			{
				enablePieChart.dispose();
				enablePieChart = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}