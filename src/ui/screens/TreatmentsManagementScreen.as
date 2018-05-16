package ui.screens
{
	import flash.system.System;
	
	import feathers.controls.DragGesture;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	import ui.screens.display.treatments.TreatmentsManagementList;
	
	import utils.Constants;
	
	[ResourceBundle("treatments")]

	public class TreatmentsManagementScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var treatmentsSection:TreatmentsManagementList;
		
		public function TreatmentsManagementScreen() 
		{
			super();
			
			setupHeader();	
			setupContent();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('treatments',"treatments_screen_title");
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.treatmentsTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Treatments Section
			treatmentsSection = new TreatmentsManagementList();
			screenRenderer.addChild(treatmentsSection);
		}
		
		/**
		 * Event Handlers
		 */
		override protected function onBackButtonTriggered(event:Event):void
		{
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
			//Pop Screen
			dispatchEventWith(Event.COMPLETE);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (treatmentsSection != null)
			{
				treatmentsSection.removeFromParent();
				treatmentsSection.dispose();
				treatmentsSection = null;
			}
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);
		}
		
		override protected function draw():void 
		{
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}