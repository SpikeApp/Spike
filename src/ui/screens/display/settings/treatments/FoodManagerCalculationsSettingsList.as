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
	
	[ResourceBundle("foodmanager")]
	
	public class FoodManagerCalculationsSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var fiberPrecisionPicker:PickerList;
		
		/* Properties */
		public var needsSave:Boolean;
		private var fiberPrecisionValue:Number;
		
		public function FoodManagerCalculationsSettingsList()
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
			fiberPrecisionValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_FIBER_PRECISION));
		}
		
		private function setupContent():void
		{	
			//Insulin Precision
			fiberPrecisionPicker = LayoutFactory.createPickerList();
			
			var fiberPrecisionValuesList:ArrayCollection = new ArrayCollection();
			fiberPrecisionValuesList.push( { label: ModelLocator.resourceManagerInstance.getString('foodmanager','half_fiber_label'), amount: 0.5 } );
			fiberPrecisionValuesList.push( { label: ModelLocator.resourceManagerInstance.getString('foodmanager','whole_fiber_label'), amount: 1 } );
			
			fiberPrecisionPicker.popUpContentManager = new DropDownPopUpContentManager();
			fiberPrecisionPicker.dataProvider = fiberPrecisionValuesList;
			
			if (fiberPrecisionValue == 0.5)
				fiberPrecisionPicker.selectedIndex = 0;
			else if (fiberPrecisionValue == 1)
				fiberPrecisionPicker.selectedIndex = 1;
				
			fiberPrecisionPicker.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				return itemRenderer;
			}
			fiberPrecisionPicker.addEventListener(Event.CHANGE, onSettingsChanged);

			//Set screen content
			var data:Array = [];
			
			data.push( { label: ModelLocator.resourceManagerInstance.getString('foodmanager','subtract_fiber_amount_label'), accessory: fiberPrecisionPicker } );
			
			dataProvider = new ArrayCollection(data);
		}
		
		public function save():void
		{
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_FIBER_PRECISION) != String(fiberPrecisionValue))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FOOD_MANAGER_FIBER_PRECISION, String(fiberPrecisionValue), true, false);
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onSettingsChanged(e:Event):void
		{
			fiberPrecisionValue = fiberPrecisionPicker.selectedItem.amount;
			
			needsSave = true;
		}
		
		/**
		 * Utility
		 */	
		override public function dispose():void
		{
			if (fiberPrecisionPicker != null)
			{
				fiberPrecisionPicker.removeEventListener(Event.CHANGE, onSettingsChanged);
				fiberPrecisionPicker.dispose();
				fiberPrecisionPicker = null;
			}
			
			super.dispose();
		}
	}
}