package ui.screens.display.settings.treatments
{
	import database.BgReading;
	import database.CommonSettings;
	
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
	
	[ResourceBundle("treatments")]
	
	public class BolusWizardCalculationsSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var insulinPrecisionPicker:PickerList;
		private var carbsPrecisionPicker:PickerList;
		private var errorMarginStepper:NumericStepper;
		private var autoIOBCheck:Check;
		private var autoCOBCheck:Check;
		private var autoTrendCheck:Check;
		
		/* Properties */
		public var needsSave:Boolean;
		private var insulinPrecisionValue:Number;
		private var carbsPrecisionValue:Number;
		private var errorMarginValue:Number;
		private var autoIOBValue:Boolean;
		private var autoCOBValue:Boolean;
		private var autoTrendValue:Boolean;
		private var isMgDl:Boolean;
		
		public function BolusWizardCalculationsSettingsList()
		{
			super(true);
			
			setupProperties();
			setupInitialContent();	
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
		
		private function setupInitialContent():void
		{
			/* Get Values From Database */
			insulinPrecisionValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_INSULIN_PRECISION));
			carbsPrecisionValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_CARBS_PRECISION));
			errorMarginValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_ACCEPTABLE_MARGIN));
			autoIOBValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_AUTO_IOB_ENABLED) == "true";
			autoCOBValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_AUTO_COB_ENABLED) == "true";
			autoTrendValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_AUTO_TREND_ENABLED) == "true";
			isMgDl = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true";
		}
		
		private function setupContent():void
		{	
			//Insulin Precision
			insulinPrecisionPicker = LayoutFactory.createPickerList();
			
			var insulinPrecisionValuesList:ArrayCollection = new ArrayCollection();
			insulinPrecisionValuesList.push( { label: "0.05" } );
			insulinPrecisionValuesList.push( { label: "0.1" } );
			insulinPrecisionValuesList.push( { label: "0.5" } );
			insulinPrecisionValuesList.push( { label: "1.0" } );
			
			insulinPrecisionPicker.popUpContentManager = new DropDownPopUpContentManager();
			insulinPrecisionPicker.dataProvider = insulinPrecisionValuesList;
			
			if (insulinPrecisionValue == 0.05)
				insulinPrecisionPicker.selectedIndex = 0;
			else if (insulinPrecisionValue == 0.1)
				insulinPrecisionPicker.selectedIndex = 1;
			else if (insulinPrecisionValue == 0.5)
				insulinPrecisionPicker.selectedIndex = 2;
			else if (insulinPrecisionValue == 1)
				insulinPrecisionPicker.selectedIndex = 3;
				
			insulinPrecisionPicker.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				return itemRenderer;
			}
			insulinPrecisionPicker.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Carbs Precision
			carbsPrecisionPicker = LayoutFactory.createPickerList();
			
			var carbsPrecisionValuesList:ArrayCollection = new ArrayCollection();
			carbsPrecisionValuesList.push( { label: "0.5" } );
			carbsPrecisionValuesList.push( { label: "1.0" } );
			
			carbsPrecisionPicker.popUpContentManager = new DropDownPopUpContentManager();
			carbsPrecisionPicker.dataProvider = carbsPrecisionValuesList;
			
			if (carbsPrecisionValue == 0.5)
				carbsPrecisionPicker.selectedIndex = 0;
			else if (carbsPrecisionValue ==1)
				carbsPrecisionPicker.selectedIndex = 1;
			
			carbsPrecisionPicker.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				return itemRenderer;
			}
			carbsPrecisionPicker.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Error Margin
			errorMarginStepper = LayoutFactory.createNumericStepper(0, isMgDl ? 50 : Math.round(BgReading.mgdlToMmol(50) * 10) / 10, isMgDl ? errorMarginValue : Math.round(BgReading.mgdlToMmol(errorMarginValue) * 10) / 10, isMgDl ? 1 : 0.1); 
			errorMarginStepper.pivotX = -8;
			errorMarginStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Auto IOB
			autoIOBCheck = LayoutFactory.createCheckMark(autoIOBValue);
			autoIOBCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Auto COB
			autoCOBCheck = LayoutFactory.createCheckMark(autoCOBValue);
			autoCOBCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Auto Trend
			autoTrendCheck = LayoutFactory.createCheckMark(autoTrendValue);
			autoTrendCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Set screen content
			var data:Array = [];
			data.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','insulin_precision_label'), accessory: insulinPrecisionPicker } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','carbs_precision_label'), accessory: carbsPrecisionPicker } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','bolus_wizard_allowed_margin'), accessory: errorMarginStepper } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','bolus_wizard_auto_account_for_iob'), accessory: autoIOBCheck } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','bolus_wizard_auto_account_for_cob'), accessory: autoCOBCheck } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','bolus_wizard_auto_account_for_trend'), accessory: autoTrendCheck } );
			dataProvider = new ArrayCollection(data);
		}
		
		public function save():void
		{
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_INSULIN_PRECISION) != String(insulinPrecisionValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_INSULIN_PRECISION, String(insulinPrecisionValue), true, false);
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_CARBS_PRECISION) != String(carbsPrecisionValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_CARBS_PRECISION, String(carbsPrecisionValue), true, false);
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_ACCEPTABLE_MARGIN) != String(errorMarginValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_ACCEPTABLE_MARGIN, String(errorMarginValue), true, false);
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_AUTO_IOB_ENABLED) != String(autoIOBValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_AUTO_IOB_ENABLED, String(autoIOBValue), true, false);
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_AUTO_COB_ENABLED) != String(autoCOBValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_AUTO_COB_ENABLED, String(autoCOBValue), true, false);
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_AUTO_TREND_ENABLED) != String(autoTrendValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_AUTO_TREND_ENABLED, String(autoTrendValue), true, false);
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onSettingsChanged(e:Event):void
		{
			insulinPrecisionValue = Number(insulinPrecisionPicker.selectedItem.label);
			carbsPrecisionValue = Number(carbsPrecisionPicker.selectedItem.label);
			errorMarginValue = isMgDl ? errorMarginStepper.value : Math.round(BgReading.mmolToMgdl(errorMarginStepper.value));
			autoIOBValue = autoIOBCheck.isSelected;
			autoCOBValue = autoCOBCheck.isSelected;
			autoTrendValue = autoTrendCheck.isSelected;
			
			needsSave = true;
		}
		
		/**
		 * Utility
		 */	
		override public function dispose():void
		{
			if (insulinPrecisionPicker != null)
			{
				insulinPrecisionPicker.removeEventListener(Event.CHANGE, onSettingsChanged);
				insulinPrecisionPicker.removeFromParent();
				insulinPrecisionPicker.dispose();
				insulinPrecisionPicker = null;
			}
			
			if (carbsPrecisionPicker != null)
			{
				carbsPrecisionPicker.removeEventListener(Event.CHANGE, onSettingsChanged);
				carbsPrecisionPicker.removeFromParent();
				carbsPrecisionPicker.dispose();
				carbsPrecisionPicker = null;
			}
			
			if (errorMarginStepper != null)
			{
				errorMarginStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				errorMarginStepper.removeFromParent();
				errorMarginStepper.dispose();
				errorMarginStepper = null;
			}
			
			if (autoIOBCheck != null)
			{
				autoIOBCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				autoIOBCheck.removeFromParent();
				autoIOBCheck.dispose();
				autoIOBCheck = null;
			}
			
			if (autoCOBCheck != null)
			{
				autoCOBCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				autoCOBCheck.removeFromParent();
				autoCOBCheck.dispose();
				autoCOBCheck = null;
			}
			
			if (autoTrendCheck != null)
			{
				autoTrendCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				autoTrendCheck.removeFromParent();
				autoTrendCheck.dispose();
				autoTrendCheck = null;
			}
			
			super.dispose();
		}
	}
}