package display.settings.chart
{
	import flash.system.System;
	
	import display.LayoutFactory;
	
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
	import feathers.controls.Slider;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import utils.Constants;

	public class SizeSettingsList extends List 
	{
		/* Display Objects */
		private var glucoseMarkerRadius:NumericStepper;

		private var glucoseDisplayFontSize:Slider;

		private var timeAgoDisplayFontSize:Slider;

		private var axisFontSize:Slider;

		private var pieChartFontSize:Slider;
		
		public function SizeSettingsList()
		{
			super();
			
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			/* Controls */
			glucoseMarkerRadius = LayoutFactory.createNumericStepper(1, 5, 3);
			glucoseMarkerRadius.validate();
			
			glucoseDisplayFontSize = new Slider();
			glucoseDisplayFontSize.minimum = 0;
			glucoseDisplayFontSize.maximum = 100;
			glucoseDisplayFontSize.value = 50;
			glucoseDisplayFontSize.step = 50;
			glucoseDisplayFontSize.width = glucoseMarkerRadius.width;
			
			timeAgoDisplayFontSize = new Slider();
			timeAgoDisplayFontSize.minimum = 0;
			timeAgoDisplayFontSize.maximum = 100;
			timeAgoDisplayFontSize.value = 50;
			timeAgoDisplayFontSize.step = 50;
			timeAgoDisplayFontSize.width = glucoseMarkerRadius.width;
			
			axisFontSize = new Slider();
			axisFontSize.minimum = 0;
			axisFontSize.maximum = 100;
			axisFontSize.value = 50;
			axisFontSize.step = 50;
			axisFontSize.width = glucoseMarkerRadius.width;
			
			pieChartFontSize = new Slider();
			pieChartFontSize.minimum = 0;
			pieChartFontSize.maximum = 100;
			pieChartFontSize.value = 50;
			pieChartFontSize.step = 50;
			pieChartFontSize.width = glucoseMarkerRadius.width;
			
			//Set Size Settings Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			//Set Colors Data
			dataProvider = new ArrayCollection(
				[
					{ text: "BG Marker Radius", accessory: glucoseMarkerRadius },
					{ text: "Glucose Font Size", accessory: glucoseDisplayFontSize },
					{ text: "Time Ago Font Size", accessory: timeAgoDisplayFontSize },
					{ text: "Axis Font Size", accessory: axisFontSize },
					{ text: "Pie Chart Font Size", accessory: pieChartFontSize },
				]);
		}
		
		override public function dispose():void
		{
			if (glucoseMarkerRadius != null)
			{
				glucoseMarkerRadius.dispose();
				glucoseMarkerRadius = null;
			}
			
			if(glucoseDisplayFontSize != null)
			{
				glucoseDisplayFontSize.dispose();
				glucoseDisplayFontSize = null;
			}
			
			if(timeAgoDisplayFontSize != null)
			{
				timeAgoDisplayFontSize.dispose();
				timeAgoDisplayFontSize = null;
			}
			
			if(axisFontSize != null)
			{
				axisFontSize.dispose();
				axisFontSize = null;
			}
			
			if(pieChartFontSize != null)
			{
				pieChartFontSize.dispose();
				pieChartFontSize = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}