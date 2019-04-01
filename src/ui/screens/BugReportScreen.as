package ui.screens
{
	import flash.display.StageOrientation;
	import flash.system.System;
	
	import database.CGMBlueToothDevice;
	
	import feathers.controls.Label;
	import feathers.controls.ScrollPolicy;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.bugreport.BugReportSettingsList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
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
			onStarlingResize(null);
			
			this.horizontalScrollPolicy = ScrollPolicy.OFF;
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
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
			if (!CGMBlueToothDevice.isFollower())
				AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 7 : 6;
			else
				AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 4 : 3;
		}
		
		/**
		 * Event Handlers
		 */
		override protected function onTransitionInComplete(e:Event):void
		{
			//Swipe to pop functionality
			AppInterface.instance.navigator.isSwipeToPopEnabled = false;
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait && Constants.currentOrientation == StageOrientation.ROTATED_RIGHT && bugReportLabel != null)
			{
				bugReportLabel.paddingLeft = 30;
			}
			else
				bugReportLabel.paddingLeft = 0;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
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