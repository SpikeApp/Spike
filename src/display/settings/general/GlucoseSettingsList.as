package display.settings.general
{
	import flash.system.System;
	
	import display.LayoutFactory;
	
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import utils.Constants;

	public class GlucoseSettingsList extends List 
	{
		/* Display Objects */
		private var glucoseUnitsPicker:PickerList;
		private var glucoseUrgentHighValue:NumericStepper;
		private var glucoseHighValue:NumericStepper;
		private var glucoseLowValue:NumericStepper;
		private var glucoseUrgentLowValue:NumericStepper;
		
		public function GlucoseSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			//Glucose Units Picker
			glucoseUnitsPicker = LayoutFactory.createPickerList();
			var glucoseUnits:ArrayCollection = new ArrayCollection(
				[
					{ text: "mg/dl" },
					{ text: "mmol" },
				]);
			glucoseUnitsPicker.labelField = "text";
			glucoseUnitsPicker.dataProvider = glucoseUnits;
			glucoseUnitsPicker.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				return itemRenderer;
			}
			clipContent = false;
				
			//Glucose Urgen High Value
			glucoseUrgentHighValue = LayoutFactory.createNumericStepper(90, 600, 180);
			
			//Glucose High Value
			glucoseHighValue = LayoutFactory.createNumericStepper(90, 400, 140);
			
			//Glucose Low Value
			glucoseLowValue = LayoutFactory.createNumericStepper(50, 200, 80);
			
			//Glucose Urgent Low Value
			glucoseUrgentLowValue = LayoutFactory.createNumericStepper(40, 120, 55);
			
			//Define Glucose Settings Data
			var settingsData:ArrayCollection = new ArrayCollection(
				[
					{ label: "Unit", accessory: glucoseUnitsPicker },
					{ label: "High Treshold", accessory: glucoseHighValue },
					{ label: "Low Treshold", accessory: glucoseLowValue },
					{ label: "Urgent High Treshold", accessory: glucoseUrgentHighValue },
					{ label: "Urgent Low Treshold", accessory: glucoseUrgentLowValue }
				]);
			dataProvider = settingsData;
				
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				return itemRenderer;
			};
		}
		
		override public function dispose():void
		{
			if(glucoseUnitsPicker != null)
			{
				glucoseUnitsPicker.dispose();
				glucoseUnitsPicker = null;
			}
			if(glucoseUrgentHighValue != null)
			{
				glucoseUrgentHighValue.dispose();
				glucoseUrgentHighValue = null;
			}
			if(glucoseHighValue != null)
			{
				glucoseHighValue.dispose();
				glucoseHighValue = null;
			}
			if(glucoseLowValue != null)
			{
				glucoseLowValue.dispose();
				glucoseLowValue = null;
			}
			if(glucoseUrgentLowValue != null)
			{
				glucoseUrgentLowValue.dispose();
				glucoseUrgentLowValue = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}