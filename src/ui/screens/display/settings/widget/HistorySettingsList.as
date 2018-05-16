package ui.screens.display.settings.widget
{
	import database.CommonSettings;
	
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
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
	
	[ResourceBundle("widgetsettingsscreen")]
	
	public class HistorySettingsList extends List
	{
		/* Display Objects */
		private var historyStepper:NumericStepper;
		
		/* Variables */
		public var needsSave:Boolean = false;
		private var historyValue:int;
		
		public function HistorySettingsList()
		{
			super();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
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
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.paddingRight = 0;
				return itemRenderer;
			};
			
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
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
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