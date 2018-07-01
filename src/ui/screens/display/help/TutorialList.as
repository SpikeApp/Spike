package ui.screens.display.help
{
	import feathers.controls.Button;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("helpscreen")]

	public class TutorialList extends SpikeList 
	{
		/* Display Objects */
		private var tutorialButton:Button;
		
		public function TutorialList()
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
			///Notifications On/Off Toggle
			tutorialButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','start_button_label'));
			tutorialButton.addEventListener(Event.TRIGGERED, onShowTutorial);
			
			//Define Notifications Settings Data
			dataProvider = new ArrayCollection(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('helpscreen','tutorial_label'), accessory: tutorialButton }
				]);
		}
		
		/**
		 * Event Handlers
		 */
		private function onShowTutorial(event:Event):void
		{
			dispatchEventWith(Event.COMPLETE);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if(tutorialButton != null)
			{
				tutorialButton.removeEventListener(Event.TRIGGERED, onShowTutorial);
				tutorialButton.dispose();
				tutorialButton = null;
			}
			
			super.dispose();
		}
	}
}