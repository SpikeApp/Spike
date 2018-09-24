package ui.screens.display.settings.treatments
{
	import database.CommonSettings;
	
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
		
		/* Properties */
		public var needsSave:Boolean;
		private var insulinPrecisionValue:Number;
		private var carbsPrecisionValue:Number;
		
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
		}
		
		private function setupContent():void
		{	
			//Insulin Precision
			insulinPrecisionPicker = LayoutFactory.createPickerList();
			
			var insulinPrecisionValuesList:ArrayCollection = new ArrayCollection();
			insulinPrecisionValuesList.push( { label: "0.1" } );
			insulinPrecisionValuesList.push( { label: "0.5" } );
			insulinPrecisionValuesList.push( { label: "1.0" } );
			
			insulinPrecisionPicker.popUpContentManager = new DropDownPopUpContentManager();
			insulinPrecisionPicker.dataProvider = insulinPrecisionValuesList;
			
			if (insulinPrecisionValue == 0.1)
				insulinPrecisionPicker.selectedIndex = 0;
			else if (insulinPrecisionValue == 0.5)
				insulinPrecisionPicker.selectedIndex = 1;
			else if (insulinPrecisionValue == 1)
				insulinPrecisionPicker.selectedIndex = 2;
				
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

			//Set screen content
			var data:Array = [];
			
			data.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','insulin_precision_label'), accessory: insulinPrecisionPicker } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','carbs_precision_label'), accessory: carbsPrecisionPicker } );
			
			dataProvider = new ArrayCollection(data);
		}
		
		public function save():void
		{
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_INSULIN_PRECISION) != String(insulinPrecisionValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_INSULIN_PRECISION, String(insulinPrecisionValue), true, false);
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_CARBS_PRECISION) != String(carbsPrecisionValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_BOLUS_WIZARD_CARBS_PRECISION, String(carbsPrecisionValue), true, false);
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onSettingsChanged(e:Event):void
		{
			insulinPrecisionValue = Number(insulinPrecisionPicker.selectedItem.label);
			carbsPrecisionValue = Number(carbsPrecisionPicker.selectedItem.label);
			
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
				insulinPrecisionPicker.dispose();
				insulinPrecisionPicker = null;
			}
			
			if (carbsPrecisionPicker != null)
			{
				carbsPrecisionPicker.removeEventListener(Event.CHANGE, onSettingsChanged);
				carbsPrecisionPicker.dispose();
				carbsPrecisionPicker = null;
			}
			
			super.dispose();
		}
	}
}