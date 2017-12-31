package screens
{	
	import flash.system.System;
	
	import display.extraoptions.ExtraOptionsList;
	import display.treatments.TreatmentsList;
	
	import events.ScreenEvent;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.List;
	import feathers.controls.PanelScreen;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;
	
	public class BaseScreen extends PanelScreen
	{
		/* Display Objects */
		protected var menuButton:Button;
		protected var treatmentsButton:Button;
		protected var moreButton:Button;
		protected var callout:Callout;
		private var treatmentsList:List;
		private var extraOptionsList:List;
		
		public function BaseScreen()
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			headerProperties.gap = -10;
			headerProperties.disposeItems = true;
		}
		
		private function setupContent():void
		{
			/* Add default menu button to the header */
			menuButton = new Button();
			menuButton.defaultIcon = new Image( MaterialDeepGreyAmberMobileThemeIcons.menuTexture );
			menuButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
			menuButton.addEventListener( Event.TRIGGERED, onMenuButtonTriggered );
			headerProperties.leftItems = new <DisplayObject>[
				menuButton
			];
			backButtonHandler = onBackButton;
			Constants.mainMenuButton = menuButton;
			
			
			/* Add more options to the header */
			moreButton = new Button();
			moreButton.defaultIcon = new Image( MaterialDeepGreyAmberMobileThemeIcons.moreVerticalTexture );
			moreButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
			moreButton.addEventListener( Event.TRIGGERED, onMoreButtonTriggered );
			moreButton.validate();
			
			/* Add treatments to the header */
			treatmentsButton = new Button();
			treatmentsButton.defaultIcon = new Image( MaterialDeepGreyAmberMobileThemeIcons.addTexture );
			treatmentsButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
			treatmentsButton.addEventListener( Event.TRIGGERED, onTreatmentButtonTriggered );
			treatmentsButton.validate();
			
			/* Populate Header */
			headerProperties.rightItems = new <DisplayObject>[
				treatmentsButton,
				moreButton
			];
		}
		
		/**
		 * Event Handlers
		 */
		private function onMenuButtonTriggered():void 
		{
			toggleMenu();
		}
		
		private function onBackButton():void 
		{
			toggleMenu();
		}
		
		protected function onTreatmentButtonTriggered():void 
		{
			treatmentsList = new TreatmentsList();
			treatmentsList.addEventListener(ExtraOptionsList.CLOSE, onCloseCallOut);
			callout = Callout.show( treatmentsList, treatmentsButton );
		}
		
		protected function onMoreButtonTriggered():void 
		{
			extraOptionsList = new ExtraOptionsList();
			extraOptionsList.addEventListener(ExtraOptionsList.CLOSE, onCloseCallOut);
			callout = Callout.show( extraOptionsList, moreButton );
			
			Callout.stagePaddingRight = -5
		}
		
		private function onCloseCallOut(e:Event):void
		{
			callout.close(true);
		}
		
		private function toggleMenu():void 
		{
			if(!AppInterface.instance.drawers.isLeftDrawerOpen)
				dispatchEventWith( ScreenEvent.TOGGLE_MENU );
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (menuButton != null)
			{
				menuButton.removeEventListener( Event.TRIGGERED, onMenuButtonTriggered );
				menuButton.dispose();
				menuButton = null;
			}
			
			if (treatmentsButton != null)
			{
				treatmentsButton.removeEventListener( Event.TRIGGERED, onTreatmentButtonTriggered );
				treatmentsButton.dispose();
				treatmentsButton = null;
			}
			
			if (moreButton != null)
			{
				moreButton.removeEventListener( Event.TRIGGERED, onMoreButtonTriggered );
				moreButton.dispose();
				moreButton = null;
			}
			
			if (treatmentsList != null)
			{
				treatmentsList.removeEventListener(ExtraOptionsList.CLOSE, onCloseCallOut);
				treatmentsList.dispose();
				treatmentsList = null;
			}
			
			if (extraOptionsList != null)
			{
				extraOptionsList.removeEventListener(ExtraOptionsList.CLOSE, onCloseCallOut);
				extraOptionsList.dispose();
				extraOptionsList = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}