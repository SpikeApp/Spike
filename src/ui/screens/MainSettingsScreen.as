package ui.screens
{
	
	import flash.system.System;
	
	import database.BlueToothDevice;
	
	import feathers.events.FeathersEventType;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import services.TutorialService;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	import ui.screens.display.settings.main.SettingsList;
	
	import utils.Constants;

	[ResourceBundle("mainsettingsscreen")]
	
	public class MainSettingsScreen extends BaseSubScreen
	{	
		/* Display Objects */
		private var settingsMenu:SettingsList;
		
		public function MainSettingsScreen() 
		{
			super();
			
			setupHeader();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupScreen();
			adjustMainMenu();
			setupEventListeners();
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('mainsettingsscreen','screen_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.settingsTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupScreen():void
		{
			settingsMenu = new SettingsList();
			addChild(settingsMenu);
		}
		
		private function adjustMainMenu():void
		{
			if (!BlueToothDevice.isFollower())
				AppInterface.instance.menu.selectedIndex = 3;
			else
				AppInterface.instance.menu.selectedIndex = 1;
		}
		
		private function setupEventListeners():void
		{
			if( TutorialService.isActive && TutorialService.secondStepActive)
				addEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onTransitionInComplete);
		}
		
		/**
		 * Event Handlers
		 */
		private function onTransitionInComplete(e:Event):void
		{
			if( TutorialService.isActive)
				removeEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onTransitionInComplete);
			
			if( TutorialService.isActive && TutorialService.secondStepActive)
				Starling.juggler.delayCall(TutorialService.thirdStep, .2);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (settingsMenu != null)
			{
				settingsMenu.removeFromParent();
				settingsMenu.dispose();
				settingsMenu = null;
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