package ui.screens.display.settings.integration
{
	import feathers.controls.Button;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.events.Event;
	
	import ui.popups.EmailFileSender;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.SiDiary;
	
	[ResourceBundle("sidiarysettingsscreen")]

	public class SiDiarySettingsList extends SpikeList 
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
			exportBtn.validate();
			exportBtn.isEnabled = false;
			
			SiDiary.instance.addEventListener(Event.COMPLETE, onExportComplete);
			Starling.juggler.delayCall(SiDiary.exportSiDiary, 0.5);
		}
		
		private function onExportComplete(e:Event):void
		{
			SiDiary.instance.removeEventListener(Event.COMPLETE, onExportComplete);
			
			if (exportBtn != null && exportBtn.label != null)
			{
				exportBtn.label = ModelLocator.resourceManagerInstance.getString('sidiarysettingsscreen','export_button_label');
				exportBtn.validate();
				exportBtn.isEnabled = true;
			}
		}
		
		/**
		 * Utility
		 */		
		override public function dispose():void
		{
			EmailFileSender.dispose();
			SiDiary.instance.removeEventListener(Event.COMPLETE, onExportComplete);
			
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