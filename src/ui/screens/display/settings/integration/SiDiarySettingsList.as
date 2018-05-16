package ui.screens.display.settings.integration
{
	import feathers.controls.Button;
	import feathers.controls.List;
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
	import utils.SiDiary;
	
	[ResourceBundle("sidiarysettingsscreen")]

	public class SiDiarySettingsList extends List 
	{
		/* Display Objects */
		private var exportBtn:Button;
		

		public function SiDiarySettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			setupProperties();
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
		
		private function setupContent():void
		{
			//Export Button
			exportBtn = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('sidiarysettingsscreen','export_button_label'));
			exportBtn.addEventListener(Event.TRIGGERED, onGenerateCSV);
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				
				return itemRenderer;
			};
			
			dataProvider = new ArrayCollection
			(
				[ { label: ModelLocator.resourceManagerInstance.getString('sidiarysettingsscreen','export_section_label'), accessory: exportBtn } ]
			);
		}
		
		/**
		 * Event Handlers
		 */
		private function onGenerateCSV(e:Event):void
		{
			exportBtn.label = ModelLocator.resourceManagerInstance.getString('sidiarysettingsscreen','export_button__standby_label');
			
			SiDiary.instance.addEventListener(Event.COMPLETE, onExportComplete);
			Starling.juggler.delayCall(SiDiary.exportSiDiary, 0.5);
		}
		
		private function onExportComplete(e:Event):void
		{
			if (exportBtn != null && exportBtn.label != null)
				exportBtn.label = ModelLocator.resourceManagerInstance.getString('sidiarysettingsscreen','export_button_label');
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
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if (exportBtn != null)
			{
				exportBtn.removeEventListener(Event.TRIGGERED, onGenerateCSV);
				exportBtn.dispose();
				exportBtn = null;
			}
			
			super.dispose();
		}
	}
}