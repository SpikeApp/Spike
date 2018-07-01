package ui.screens.display.settings.widget
{
	import database.CommonSettings;
	
	import feathers.controls.NumericStepper;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	
	[ResourceBundle("widgetsettingsscreen")]
	
	public class HistorySettingsList extends SpikeList
	{
		/* Display Objects */
		private var historyStepper:NumericStepper;
		
		/* Variables */
		public var needsSave:Boolean = false;
		private var historyValue:int;
		
		public function HistorySettingsList()
		{
			super(true);
			
			setupProperties();
			stupInitialContent();
			setupContent();
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
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function stupInitialContent():void
		{
			historyValue = int(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_HISTORY_TIMESPAN));
		}
		
		private function setupContent():void
		{
			//History Numeric Stepper
			historyStepper = LayoutFactory.createNumericStepper(1, 2, historyValue);
			historyStepper.pivotX = -8;
			historyStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Set Data
			dataProvider = new ArrayCollection
			(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','history_label'), accessory: historyStepper }
				]
			);
		}
		
		public function save():void
		{
			if (!needsSave)
				return;
			
			var valueToSave:String = String(historyValue);
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_HISTORY_TIMESPAN) != valueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_HISTORY_TIMESPAN, valueToSave);
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onSettingsChanged(e:Event):void
		{
			historyValue = historyStepper.value;
			needsSave = true;
			save();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (historyStepper != null)
			{
				historyStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				historyStepper.dispose();
				historyStepper = null;
			}
			
			super.dispose();
		}
	}
}