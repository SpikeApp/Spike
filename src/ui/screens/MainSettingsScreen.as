package ui.screens
{
	import flash.system.System;
	
	import database.CGMBlueToothDevice;
	
	import feathers.controls.ScrollPolicy;
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
			
			this.horizontalScrollPolicy = ScrollPolicy.OFF;
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
			if (!CGMBlueToothDevice.isFollower())
				AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 4 : 3;
			else
				AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 2 : 1;
		}
		
		/**
		 * Event Handlers
		 */
		override protected function onTransitionInComplete(e:Event):void
		{
			/*if( TutorialService.isActive)
				removeEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onTransitionInComplete);*/
			
			if( TutorialService.isActive && TutorialService.secondStepActive)
				Starling.juggler.delayCall(TutorialService.thirdStep, .2);
			
			//Swipe to pop functionality
			AppInterface.instance.navigator.isSwipeToPopEnabled = false;
			
			//Re-adjust menu
			adjustMainMenu();
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