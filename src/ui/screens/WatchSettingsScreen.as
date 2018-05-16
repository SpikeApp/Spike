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
	import ui.screens.display.settings.watch.WatchSettingsList;
	
	import utils.Constants;
	
	[ResourceBundle("watchsettingsscreen")]

	public class WatchSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var watchComplicationLabel:Label;
		private var watchComplicationSettings:WatchSettingsList;
		
		public function WatchSettingsScreen() 
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
			title = ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','screen_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.watchTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Notifications Section Label
			watchComplicationLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('watchsettingsscreen','watch_section_label'), false);
			screenRenderer.addChild(watchComplicationLabel);
			
			//Notification Settings
			watchComplicationSettings = new WatchSettingsList();
			screenRenderer.addChild(watchComplicationSettings);
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
			//Save Settings
			if (watchComplicationSettings.needsSave)
				watchComplicationSettings.save();
			
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
			if (watchComplicationSettings != null)
			{
				watchComplicationSettings.removeFromParent();
				watchComplicationSettings.dispose();
				watchComplicationSettings = null;
			}
			
			if (watchComplicationLabel != null)
			{
				watchComplicationLabel.removeFromParent();
				watchComplicationLabel.dispose();
				watchComplicationLabel = null;
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