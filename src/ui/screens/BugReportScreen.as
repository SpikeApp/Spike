package ui.screens
{
	import flash.system.System;
	
	import database.BlueToothDevice;
	
	import feathers.controls.Label;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.bugreport.BugReportSettingsList;
	
	import utils.Constants;
	
	[ResourceBundle("bugreportsettingsscreen")]

	public class BugReportScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var bugReportSettings:BugReportSettingsList;
		private var bugReportLabel:Label;
		
		public function BugReportScreen() 
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
			//Section Label
			bugReportLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','trace_section_title'));
			screenRenderer.addChild(bugReportLabel);
			
			//Settings
			bugReportSettings = new BugReportSettingsList();
			screenRenderer.addChild(bugReportSettings);
		}
		
		private function adjustMainMenu():void
		{
			if (!BlueToothDevice.isFollower())
				AppInterface.instance.menu.selectedIndex = 5;
			else
				AppInterface.instance.menu.selectedIndex = 2;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (bugReportSettings != null)
			{
				bugReportSettings.removeFromParent();
				bugReportSettings.dispose();
				bugReportSettings = null;
			}
			
			if (bugReportLabel != null)
			{
				bugReportLabel.removeFromParent();
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