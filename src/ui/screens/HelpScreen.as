package ui.screens
{
	import flash.system.System;
	
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import services.TutorialService;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	import ui.screens.display.help.GeneralHelpList;
	import ui.screens.display.help.TutorialList;
	
	import utils.Constants;
	
	[ResourceBundle("helpscreen")]

	public class HelpScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var tutorialSection:TutorialList;
		private var generalHelpSection:GeneralHelpList;
		
		public function HelpScreen() 
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
			title = ModelLocator.resourceManagerInstance.getString('helpscreen','screen_title');
			//title = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','share_settings_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.settingsCellTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Tutorial Section
			tutorialSection = new TutorialList();
			tutorialSection.addEventListener(Event.COMPLETE, onShowTutorial);
			screenRenderer.addChild(tutorialSection);
			
			//General Help Section
			generalHelpSection = new GeneralHelpList();
			screenRenderer.addChild(generalHelpSection);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 4;
		}
		
		/**
		 * Event Handlers
		 */
		private function onShowTutorial(e:Event):void
		{
			Starling.juggler.delayCall(TutorialService.init, 1);
			onBackButtonTriggered(null);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (tutorialSection != null)
			{
				tutorialSection.removeFromParent();
				tutorialSection.dispose();
				tutorialSection = null;
			}
			
			if (generalHelpSection != null)
			{
				generalHelpSection.removeFromParent();
				generalHelpSection.dispose();
				generalHelpSection = null;
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