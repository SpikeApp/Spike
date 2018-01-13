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
	import ui.screens.display.settings.bugreport.BugReportSettingsList;
	
	import utilities.Constants;
	
	[ResourceBundle("bugreportsettingsscreen")]

	public class BugReportSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var bugReportSettings:BugReportSettingsList;
		private var bugReportLabel:Label;
		
		public function BugReportSettingsScreen() 
		{
			super();
			
			setupHeader();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupContent();
			adjustMainMenu();
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','screen_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.bugReportTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Tracing Section Label
			bugReportLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','trace_section_title'));
			screenRenderer.addChild(bugReportLabel);
			
			//Tracing Settings
			bugReportSettings = new BugReportSettingsList();
			screenRenderer.addChild(bugReportSettings);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 3;
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
			if (bugReportSettings != null)
			{
				bugReportSettings.dispose();
				bugReportSettings = null;
			}
			
			if (bugReportLabel != null)
			{
				bugReportLabel.dispose();
				bugReportLabel = null;
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