package display.settings.general
{
	import flash.system.System;
	
	import databaseclasses.BgReading;
	import databaseclasses.CommonSettings;
	
	import display.LayoutFactory;
	
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import utils.Constants;
	
	[ResourceBundle("generalsettingsscreen")]

	public class GlucoseSettingsList extends List 
	{
		/* Display Objects */
		private var glucoseUnitsPicker:PickerList;
		private var glucoseUrgentHighStepper:NumericStepper;
		private var glucoseHighStepper:NumericStepper;
		private var glucoseLowStepper:NumericStepper;
		private var glucoseUrgentLowStepper:NumericStepper;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var glucoseUrgentLowValue:Number;
		private var glucoseLowValue:Number;
		private var glucoseUrgentHighValue:Number;
		private var glucoseHighValue:Number;
		private var initiated:Boolean = false;
		private var selectedUnit:String = "";
		
		public function GlucoseSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupContent();
			setupInitialState();
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
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupContent():void
		{
			//Glucose Units Picker
			glucoseUnitsPicker = LayoutFactory.createPickerList();
			var glucoseUnits:ArrayCollection = new ArrayCollection(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','mgdl') },
					{ label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','mmol') },
				]);
			glucoseUnitsPicker.labelField = "label";
			glucoseUnitsPicker.popUpContentManager = new DropDownPopUpContentManager();
			glucoseUnitsPicker.dataProvider = glucoseUnits;
			
			//Glucose Urgent High Value
			glucoseUrgentHighStepper = new NumericStepper();
			
			//Glucose High Value
			glucoseHighStepper = new NumericStepper();
			
			//Glucose Low Value
			glucoseLowStepper = new NumericStepper();
			
			//Glucose Urgent Low Value
			glucoseUrgentLowStepper = new NumericStepper();
			
			//Define Glucose Settings Data
			var settingsData:ArrayCollection = new ArrayCollection(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','unit'), accessory: glucoseUnitsPicker },
					{ label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','urgent_high_threshold'), accessory: glucoseUrgentHighStepper },
					{ label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','high_threshold'), accessory: glucoseHighStepper },
					{ label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','low_threshold'), accessory: glucoseLowStepper },
					{ label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','urgent_low_threshold'), accessory: glucoseUrgentLowStepper }
				]);
			dataProvider = settingsData;
			
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				return itemRenderer;
			};
		}
		
		private function setupInitialState(glucoseUnit:String = null):void
		{
			/* Glucose Unit */
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") 
			{
				glucoseUnitsPicker.selectedIndex = 0;
				selectedUnit = "mg/dl";
			}
			else 
			{
				glucoseUnitsPicker.selectedIndex = 1;
				selectedUnit = "mmol/L";
			}
			
			/* Convert Steppers For Selected Glucose Unit */
			convertSettpers();
				
			/* Set Glucose Tresholds */
			glucoseHighValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
			glucoseLowValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
			glucoseUrgentHighValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK));
			glucoseUrgentLowValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK));
			
			/* Populate Steppers */
			populateSteppers();
			
			/* Set Change Event Handlers */
			if(!initiated)
			{
				glucoseUnitsPicker.addEventListener(Event.CHANGE, onUnitsChanged);
				glucoseUrgentHighStepper.addEventListener(Event.CHANGE, onUrgentHighChanged);
				glucoseHighStepper.addEventListener(Event.CHANGE, onHighChanged);
				glucoseLowStepper.addEventListener(Event.CHANGE, onLowChanged);
				glucoseUrgentLowStepper.addEventListener(Event.CHANGE, onUrgentLowChanged);
				
				initiated = true;
			}
		}
		
		private function convertSettpers():void
		{
			if (selectedUnit == "mg/dl")
			{
				//Glucose Urgent High Value
				glucoseUrgentHighStepper.minimum = 100;
				glucoseUrgentHighStepper.maximum = 600;
				glucoseUrgentHighStepper.step = 1;
				
				//Glucose High Value
				glucoseHighStepper.minimum = 80;
				glucoseHighStepper.maximum = 400;
				glucoseHighStepper.step = 1;
				
				//Glucose Low Value
				glucoseLowStepper.minimum = 55;
				glucoseLowStepper.maximum = 200;
				glucoseLowStepper.step = 1;
				
				//Glucose Urgent Low Value
				glucoseUrgentLowStepper.minimum = 50;
				glucoseUrgentLowStepper.maximum = 120;
				glucoseUrgentLowStepper.step = 1;
			}
			else if (selectedUnit == "mmol/L")
			{
				//Glucose Urgent High Value
				glucoseUrgentHighStepper.minimum = 5.5;
				glucoseUrgentHighStepper.maximum = 33.5;
				glucoseUrgentHighStepper.step = 0.1;
				
				//Glucose High Value
				glucoseHighStepper.minimum = 4.4;
				glucoseHighStepper.maximum = 22.3;
				glucoseHighStepper.step = 0.1;
				
				//Glucose Low Value
				glucoseLowStepper.minimum = 3;
				glucoseLowStepper.maximum = 11.1;
				glucoseLowStepper.step = 0.1;
				
				//Glucose Urgent Low Value
				glucoseUrgentLowStepper.minimum = 2.7;
				glucoseUrgentLowStepper.maximum = 6.7;
				glucoseUrgentLowStepper.step = 0.1;
			}
		}
		
		private function populateSteppers():void
		{
			if (selectedUnit == "mmol/L")
			{
				glucoseHighStepper.value = Math.round(((BgReading.mgdlToMmol((glucoseHighValue))) * 10)) / 10;
				glucoseLowStepper.value = Math.round(((BgReading.mgdlToMmol((glucoseLowValue))) * 10)) / 10;
				glucoseUrgentHighStepper.value = Math.round(((BgReading.mgdlToMmol((glucoseUrgentHighValue))) * 10)) / 10;
				glucoseUrgentLowStepper.value = Math.round(((BgReading.mgdlToMmol((glucoseUrgentLowValue))) * 10)) / 10;
			}
			else if (selectedUnit == "mg/dl")
			{
				glucoseHighStepper.value = glucoseHighValue;
				glucoseLowStepper.value = glucoseLowValue;
				glucoseUrgentHighStepper.value = glucoseUrgentHighValue;
				glucoseUrgentLowStepper.value = glucoseUrgentLowValue;
			}
		}
		
		public function save():void
		{
			/* Save Glucose Units */
			if (glucoseUnitsPicker.selectedIndex == 0) //mg/dl
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL, "true");
			}
			else if(glucoseUnitsPicker.selectedIndex == 1) //mmol/L
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL, "false");
			}
			
			/* Save Glucose Tresholds */
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK) != glucoseHighValue.toString())
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK, glucoseHighValue.toString());
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK) != glucoseLowValue.toString())
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK, glucoseLowValue.toString());
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK) != glucoseUrgentHighValue.toString())
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK, glucoseUrgentHighValue.toString());
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK) != glucoseUrgentLowValue.toString())
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK, glucoseUrgentLowValue.toString());		
			
			needsSave = false;
		}
		
		/**
		 * Event Handlers
		 */
		private function onUnitsChanged(e:Event = null):void
		{
			if (selectedUnit == "mg/dl" && glucoseUnitsPicker.selectedIndex == 1)
			{
				trace("MMOL");
				needsSave = true;
				selectedUnit = "mmol/L";
				convertSettpers();
				
				glucoseUrgentHighStepper.value = (BgReading.mgdlToMmol(glucoseUrgentHighValue) * 10) / 10;
				glucoseHighStepper.value = (BgReading.mgdlToMmol(glucoseHighValue)  * 10) / 10;
				glucoseLowStepper.value = (BgReading.mgdlToMmol(glucoseLowValue)  * 10) / 10;
				glucoseUrgentLowStepper.value = (BgReading.mgdlToMmol(glucoseUrgentLowValue) * 10) / 10;
			}
			else if (selectedUnit == "mmol/L" && glucoseUnitsPicker.selectedIndex == 0)
			{
				needsSave = true;
				selectedUnit = "mg/dl";
				convertSettpers();
				
				glucoseUrgentHighStepper.value = glucoseUrgentHighValue;
				glucoseHighStepper.value = glucoseHighValue;
				glucoseLowStepper.value = glucoseLowValue;
				glucoseUrgentLowStepper.value = glucoseUrgentLowValue;
			}
		}
		
		private function onSettingsChanged(e:Event):void
		{
			if (selectedUnit == "mg/dl")
			{
				//Update internal variables
				glucoseUrgentHighValue = glucoseUrgentHighStepper.value;
				glucoseHighValue = glucoseHighStepper.value;
				glucoseLowValue = glucoseLowStepper.value;
				glucoseUrgentLowValue = glucoseUrgentLowStepper.value;
			}
			else if (selectedUnit == "mmol/L")
			{
				glucoseUrgentHighValue = Math.round(BgReading.mmolToMgdl(glucoseUrgentHighStepper.value));
				glucoseHighValue = Math.round(BgReading.mmolToMgdl(glucoseHighStepper.value));
				glucoseLowValue = Math.round(BgReading.mmolToMgdl(glucoseLowStepper.value));
				glucoseUrgentLowValue = Math.round(BgReading.mmolToMgdl(glucoseUrgentLowStepper.value));
			}
			
			needsSave = true;
		}
		
		private function onUrgentHighChanged(e:Event):void
		{
			if (selectedUnit == "mg/dl")
			{
				//Avoid overlap
				if (glucoseUrgentHighStepper.value <= glucoseHighStepper.value)
					glucoseHighStepper.value = glucoseUrgentHighStepper.value - 1;
				
				//Update internal variables
				glucoseUrgentHighValue = glucoseUrgentHighStepper.value;
			}
			else if (selectedUnit == "mmol/L")
			{
				//Avoid overlap
				if (glucoseUrgentHighStepper.value <= glucoseHighStepper.value)
					glucoseHighStepper.value = glucoseUrgentHighStepper.value - 0.1;
				
				glucoseUrgentHighValue = Math.round(BgReading.mmolToMgdl(glucoseUrgentHighStepper.value));
			}
			
			needsSave = true;
		}
		
		private function onHighChanged(e:Event):void
		{
			if (selectedUnit == "mg/dl")
			{
				//Avoid overlap
				if (glucoseHighStepper.value <= glucoseLowStepper.value)
					glucoseLowStepper.value = glucoseHighStepper.value - 1;
				
				if (glucoseHighStepper.value >= glucoseUrgentHighStepper.value)
					glucoseUrgentHighStepper.value = glucoseHighStepper.value + 1;
				
				//Update internal variables
				glucoseHighValue = glucoseHighStepper.value;
			}
			else if (selectedUnit == "mmol/L")
			{
				//Avoid overlap
				if (glucoseHighStepper.value <= glucoseLowStepper.value)
					glucoseLowStepper.value = glucoseHighStepper.value - 0.1;
				
				if (glucoseHighStepper.value >= glucoseUrgentHighStepper.value)
					glucoseUrgentHighStepper.value = glucoseHighStepper.value + 0.1;
				
				glucoseHighValue = Math.round(BgReading.mmolToMgdl(glucoseHighStepper.value));
			}
			
			needsSave = true;
		}
		
		private function onLowChanged(e:Event):void
		{
			if (selectedUnit == "mg/dl")
			{
				//Avoid overlap
				if (glucoseLowStepper.value <= glucoseUrgentLowStepper.value)
					glucoseUrgentLowStepper.value = glucoseLowStepper.value - 1;
				
				if (glucoseLowStepper.value >= glucoseHighStepper.value)
					glucoseHighStepper.value = glucoseLowStepper.value + 1;
				
				//Update internal variables
				glucoseLowValue = glucoseLowStepper.value;
			}
			else if (selectedUnit == "mmol/L")
			{
				//Avoid overlap
				if (glucoseLowStepper.value <= glucoseUrgentLowStepper.value)
					glucoseUrgentLowStepper.value = glucoseLowStepper.value - 0.1;
				
				if (glucoseLowStepper.value >= glucoseHighStepper.value)
					glucoseHighStepper.value = glucoseLowStepper.value + 0.1;
				
				glucoseLowValue = Math.round(BgReading.mmolToMgdl(glucoseLowStepper.value));
			}
			
			needsSave = true;
		}
		
		private function onUrgentLowChanged(e:Event):void
		{
			if (selectedUnit == "mg/dl")
			{
				//Avoid overlap
				if (glucoseUrgentLowStepper.value >= glucoseLowStepper.value)
					glucoseLowStepper.value = glucoseUrgentLowStepper.value + 1;
				
				//Update internal variables
				glucoseUrgentLowValue = glucoseUrgentLowStepper.value;
			}
			else if (selectedUnit == "mmol/L")
			{
				//Avoid overlap
				if (glucoseUrgentLowStepper.value >= glucoseLowStepper.value)
					glucoseLowStepper.value = glucoseUrgentLowStepper.value + 0.1;
				
				glucoseUrgentLowValue = Math.round(BgReading.mmolToMgdl(glucoseUrgentLowStepper.value));
			}
			
			needsSave = true;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{	
			if(glucoseUnitsPicker != null)
			{
				glucoseUnitsPicker.removeEventListener(Event.CHANGE, onUnitsChanged);
				glucoseUnitsPicker.dispose();
				glucoseUnitsPicker = null;
			}
			if(glucoseUrgentHighStepper != null)
			{
				glucoseUrgentHighStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				glucoseUrgentHighStepper.dispose();
				glucoseUrgentHighStepper = null;
			}
			if(glucoseHighStepper != null)
			{
				glucoseHighStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				glucoseHighStepper.dispose();
				glucoseHighStepper = null;
			}
			if(glucoseLowStepper != null)
			{
				glucoseLowStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				glucoseLowStepper.dispose();
				glucoseLowStepper = null;
			}
			if(glucoseUrgentLowStepper != null)
			{
				glucoseUrgentLowStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				glucoseUrgentLowStepper.dispose();
				glucoseUrgentLowStepper = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}