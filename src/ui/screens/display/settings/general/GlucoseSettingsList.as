package ui.screens.display.settings.general
{
	import flash.display.StageOrientation;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import events.SettingsServiceEvent;
	
	import feathers.controls.Check;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("generalsettingsscreen")]

	public class GlucoseSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var glucoseUnitsPicker:PickerList;
		private var glucoseUrgentHighStepper:NumericStepper;
		private var glucoseHighStepper:NumericStepper;
		private var glucoseLowStepper:NumericStepper;
		private var glucoseUrgentLowStepper:NumericStepper;
		private var roundMgDlCheck:Check;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var isSaving:Boolean = false;
		private var glucoseUrgentLowValue:Number;
		private var glucoseLowValue:Number;
		private var glucoseUrgentHighValue:Number;
		private var glucoseHighValue:Number;
		private var initiated:Boolean = false;
		private var selectedUnit:String = "";
		private var roundMfDlValue:Boolean;
		
		public function GlucoseSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			
			/* Glucose Unit */
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true") 
				selectedUnit = "mg/dL";
			else
				selectedUnit = "mmol/L";
			
			roundMfDlValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_ROUND_MGDL_ON) == "true";
			
			setupContent();
			setupInitialState();
			setupRenderFactory();
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
			
			//Event Listeners
			CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSpikeSettingChanged);
		}
		
		private function onSpikeSettingChanged(e:SettingsServiceEvent):void
		{
			if (isSaving)
			{
				return;
			}
			
			if (e.data == CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK
				||
				e.data == CommonSettings.COMMON_SETTING_HIGH_MARK
				||
				e.data == CommonSettings.COMMON_SETTING_LOW_MARK
				||
				e.data == CommonSettings.COMMON_SETTING_URGENT_LOW_MARK
			) 
			{
				setupInitialState();
			}
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
			if(Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				glucoseUnitsPicker.pivotX = 38;
			if (selectedUnit == "mmol/L") 
				glucoseUnitsPicker.selectedIndex = 1;
			
			//Round MGDL values
			roundMgDlCheck = LayoutFactory.createCheckMark(roundMfDlValue);
			roundMgDlCheck.pivotX = 3;
			if(Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				roundMgDlCheck.pivotX = 41;
			
			//Glucose Urgent High Value
			glucoseUrgentHighStepper = new NumericStepper();
			if(Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				glucoseUrgentHighStepper.pivotX = 28;
			
			//Glucose High Value
			glucoseHighStepper = new NumericStepper();
			if(Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				glucoseHighStepper.pivotX = 28;
			
			//Glucose Low Value
			glucoseLowStepper = new NumericStepper();
			if(Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				glucoseLowStepper.pivotX = 28;
			
			//Glucose Urgent Low Value
			glucoseUrgentLowStepper = new NumericStepper();
			if(Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				glucoseUrgentLowStepper.pivotX = 28;
			
			//Define Glucose Settings Data
			var data:Array = [];
			data.push( { label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','unit'), accessory: glucoseUnitsPicker } );
			if (selectedUnit == "mg/dL" && !CGMBlueToothDevice.isFollower())
				data.push( { label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','round_mgdl_chart_value'), accessory: roundMgDlCheck } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','urgent_high_threshold'), accessory: glucoseUrgentHighStepper } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','high_threshold'), accessory: glucoseHighStepper } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','low_threshold'), accessory: glucoseLowStepper } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','urgent_low_threshold'), accessory: glucoseUrgentLowStepper } );
			
			dataProvider = new ArrayCollection(data);
			
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.paddingRight = 0;
				if(Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
					itemRenderer.paddingRight = -40;
				return itemRenderer;
			};
		}
		
		override protected function setupRenderFactory():void
		{
			/* List Item Renderer */
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryLabelProperties.wordWrap = true;
				itemRenderer.defaultLabelProperties.wordWrap = true;
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						itemRenderer.paddingLeft = 30;
						itemRenderer.paddingRight = -40;
					}
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
					{
						itemRenderer.paddingRight = -10;
					}
				}
				else
				{
					if(Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
						itemRenderer.paddingRight = -40;
					else
						itemRenderer.paddingRight = 0;
				}
				return itemRenderer;
			};
		}
		
		private function setupInitialState(glucoseUnit:String = null):void
		{	
			if (selectedUnit == "mg/dL") 
				glucoseUnitsPicker.selectedIndex = 0;
			else 
				glucoseUnitsPicker.selectedIndex = 1;
			
			/* Convert Steppers For Selected Glucose Unit */
			convertSettpers();
			
			/* Set Up Round Values for MG/DL */
			roundMgDlCheck.isSelected = roundMfDlValue;
				
			/* Set Glucose Tresholds */
			glucoseHighValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
			glucoseLowValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
			glucoseUrgentHighValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK));
			glucoseUrgentLowValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK));
			
			/* Populate Steppers */
			populateSteppers();
			
			/* Set Change Event Handlers */
			enableEventListeners();
		}
		
		private function enableEventListeners():void
		{
			glucoseUnitsPicker.addEventListener(Event.CHANGE, onUnitsChanged);
			glucoseUrgentHighStepper.addEventListener(Event.CHANGE, onUrgentHighChanged);
			glucoseHighStepper.addEventListener(Event.CHANGE, onHighChanged);
			glucoseLowStepper.addEventListener(Event.CHANGE, onLowChanged);
			glucoseUrgentLowStepper.addEventListener(Event.CHANGE, onUrgentLowChanged);
			roundMgDlCheck.addEventListener(Event.CHANGE, onSettingsChanged);
		}
		
		private function disableEventListeners():void
		{
			glucoseUnitsPicker.removeEventListener(Event.CHANGE, onUnitsChanged);
			glucoseUrgentHighStepper.removeEventListener(Event.CHANGE, onUrgentHighChanged);
			glucoseHighStepper.removeEventListener(Event.CHANGE, onHighChanged);
			glucoseLowStepper.removeEventListener(Event.CHANGE, onLowChanged);
			glucoseUrgentLowStepper.removeEventListener(Event.CHANGE, onUrgentLowChanged);
			roundMgDlCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
		}
		
		private function convertSettpers():void
		{
			if (selectedUnit == "mg/dL")
			{
				//Glucose Urgent High Value
				glucoseUrgentHighStepper.minimum = 80;
				glucoseUrgentHighStepper.maximum = 400;
				glucoseUrgentHighStepper.step = 1;
				
				//Glucose High Value
				glucoseHighStepper.minimum = 60;
				glucoseHighStepper.maximum = 400;
				glucoseHighStepper.step = 1;
				
				//Glucose Low Value
				glucoseLowStepper.minimum = 45;
				glucoseLowStepper.maximum = 200;
				glucoseLowStepper.step = 1;
				
				//Glucose Urgent Low Value
				glucoseUrgentLowStepper.minimum = 40;
				glucoseUrgentLowStepper.maximum = 150;
				glucoseUrgentLowStepper.step = 1;
			}
			else if (selectedUnit == "mmol/L")
			{
				//Glucose Urgent High Value
				glucoseUrgentHighStepper.minimum = 4.4;
				glucoseUrgentHighStepper.maximum = 22.2;
				glucoseUrgentHighStepper.step = 0.1;
				
				//Glucose High Value
				glucoseHighStepper.minimum = 3.3;
				glucoseHighStepper.maximum = 22.3;
				glucoseHighStepper.step = 0.1;
				
				//Glucose Low Value
				glucoseLowStepper.minimum = 2.5;
				glucoseLowStepper.maximum = 11.1;
				glucoseLowStepper.step = 0.1;
				
				//Glucose Urgent Low Value
				glucoseUrgentLowStepper.minimum = 2.2;
				glucoseUrgentLowStepper.maximum = 8.3;
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
			else if (selectedUnit == "mg/dL")
			{
				glucoseHighStepper.value = glucoseHighValue;
				glucoseLowStepper.value = glucoseLowValue;
				glucoseUrgentHighStepper.value = glucoseUrgentHighValue;
				glucoseUrgentLowStepper.value = glucoseUrgentLowValue;
			}
		}
		
		public function save():void
		{
			isSaving = true;
			
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
			
			/* Round MGDL Values */
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_ROUND_MGDL_ON) != String(roundMfDlValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_ROUND_MGDL_ON, String(roundMfDlValue));
			
			isSaving = false;
			needsSave = false;
		}
		
		/**
		 * Event Handlers
		 */
		private function onUnitsChanged(e:Event = null):void
		{
			if (selectedUnit == "mg/dL" && glucoseUnitsPicker.selectedIndex == 1)
			{
				needsSave = true;
				selectedUnit = "mmol/L";
				
				disableEventListeners();
				
				convertSettpers();
				
				glucoseUrgentHighStepper.value = (BgReading.mgdlToMmol(glucoseUrgentHighValue) * 10) / 10;
				
				glucoseHighStepper.value = (BgReading.mgdlToMmol(glucoseHighValue)  * 10) / 10;
				if (glucoseHighStepper.value >= glucoseUrgentHighStepper.value)
				{
					glucoseHighStepper.value = glucoseUrgentHighStepper.value - 0.1;
					glucoseHighValue = Math.round(BgReading.mmolToMgdl(glucoseHighStepper.value));
				}
					
				glucoseLowStepper.value = (BgReading.mgdlToMmol(glucoseLowValue)  * 10) / 10;
				if (glucoseLowStepper.value >= glucoseHighStepper.value)
				{
					glucoseLowStepper.value = glucoseHighStepper.value - 0.1;
					glucoseLowValue = Math.round(BgReading.mmolToMgdl(glucoseLowStepper.value));
				}
				
				glucoseUrgentLowStepper.value = (BgReading.mgdlToMmol(glucoseUrgentLowValue) * 10) / 10;
				if (glucoseUrgentLowStepper.value >= glucoseLowStepper.value)
				{
					glucoseUrgentLowStepper.value = glucoseLowStepper.value - 0.1;
					glucoseUrgentLowValue = Math.round(BgReading.mmolToMgdl(glucoseUrgentLowStepper.value));
				}
				
				enableEventListeners();
			}
			else if (selectedUnit == "mmol/L" && glucoseUnitsPicker.selectedIndex == 0)
			{
				needsSave = true;
				selectedUnit = "mg/dL";
				
				disableEventListeners();
				
				convertSettpers();
				
				glucoseUrgentHighStepper.value = glucoseUrgentHighValue;
				
				glucoseHighStepper.value = glucoseHighValue;
				if (glucoseHighStepper.value >= glucoseUrgentHighStepper.value)
				{
					glucoseHighStepper.value = glucoseUrgentHighStepper.value - 1;
					glucoseHighValue = glucoseHighStepper.value;
				}
				
				glucoseLowStepper.value = glucoseLowValue;
				if (glucoseLowStepper.value >= glucoseHighStepper.value)
				{
					glucoseLowStepper.value = glucoseHighStepper.value - 1;
					glucoseLowValue = glucoseLowStepper.value;
				}
				
				glucoseUrgentLowStepper.value = glucoseUrgentLowValue;
				if (glucoseUrgentLowStepper.value >= glucoseLowStepper.value)
				{
					glucoseUrgentLowStepper.value = glucoseLowStepper.value - 1;
					glucoseUrgentLowValue = glucoseUrgentLowStepper.value;
				}
				
				enableEventListeners();
			}
			
			disableEventListeners();
			setupContent();
			if (selectedUnit == "mg/dL") 
				glucoseUnitsPicker.selectedIndex = 0;
			else 
				glucoseUnitsPicker.selectedIndex = 1;
			convertSettpers();
			populateSteppers();
			enableEventListeners();
		}
		
		private function onSettingsChanged(e:Event):void
		{
			if (selectedUnit == "mg/dL")
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
			
			roundMfDlValue = roundMgDlCheck.isSelected;
			
			needsSave = true;
		}
		
		private function onUrgentHighChanged(e:Event):void
		{
			if (selectedUnit == "mg/dL")
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
			if (selectedUnit == "mg/dL")
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
			if (selectedUnit == "mg/dL")
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
			if (selectedUnit == "mg/dL")
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
			CommonSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, onSpikeSettingChanged);
			
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
			if (roundMgDlCheck != null)
			{
				roundMgDlCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				roundMgDlCheck.dispose();
				roundMgDlCheck = null;
			}
			
			super.dispose();
		}
	}
}