package ui.screens
{
	import flash.system.System;
	
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.settings.treatments.TreatmentsSettingsList;
	
	import utils.Constants;
	
	public class TreatmentsSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var treatmentsSettings:TreatmentsSettingsList;
		private var treatmentsLabel:Label;
		
		public function TreatmentsSettingsScreen() 
		{
			super();
			
			setupHeader();	
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			title = "Treatments";
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.treatmentsTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Treatments Section Label
			treatmentsLabel = LayoutFactory.createSectionLabel("Treatments", true);
			//screenRenderer.addChild(treatmentsLabel);
			
			//Treatments Settings
			treatmentsSettings = new TreatmentsSettingsList();
			screenRenderer.addChild(treatmentsSettings);
		}
		
		/**
		 * Event Handlers
		 */
		override protected function onBackButtonTriggered(event:Event):void
		{
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
			//Save settings
			if (treatmentsSettings.needsSave)
				treatmentsSettings.save();
			
			//Pop Screen
			dispatchEventWith(Event.COMPLETE);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (treatmentsLabel != null)
			{
				treatmentsLabel.dispose();
				treatmentsLabel = null;
			}
			
			if (treatmentsSettings != null)
			{
				treatmentsSettings.dispose();
				treatmentsSettings = null;
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