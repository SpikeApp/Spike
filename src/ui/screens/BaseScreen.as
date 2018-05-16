package ui.screens
{	
	import flash.geom.Point;
	import flash.system.System;
	
	import database.CommonSettings;
	
	import events.ScreenEvent;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.List;
	import feathers.controls.PanelScreen;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	import ui.screens.display.extraoptions.ExtraOptionsList;
	import ui.screens.display.treatments.TreatmentsList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	public class BaseScreen extends PanelScreen
	{
		/* Display Objects */
		protected var menuButton:Button;
		protected var treatmentsButton:Button;
		protected var moreButton:Button;
		protected var callout:Callout;
		private var treatmentsList:List;
		private var extraOptionsList:List;
		private var iphone4DummyMarker:Sprite;
		private var treatmentsEnabled:Boolean;
		private var menuButtonTexture:Texture;
		private var menuButtonImage:Image;
		private var moreButtonImage:Image;
		private var moreButtonTexture:Texture;
		private var treatmentsTexture:Texture;
		private var treatmentsImage:Image;
		
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
			
			treatmentsEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED) == "true";
		}
		
		private function setupContent():void
		{
			/* Add default menu button to the header */
			menuButtonTexture = MaterialDeepGreyAmberMobileThemeIcons.menuTexture;
			menuButtonImage = new Image(menuButtonTexture);
			menuButton = new Button();
			menuButton.defaultIcon = menuButtonImage;
			menuButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
			menuButton.addEventListener( Event.TRIGGERED, onMenuButtonTriggered );
			headerProperties.leftItems = new <DisplayObject>[
				menuButton
			];
			backButtonHandler = onBackButton;
			Constants.mainMenuButton = menuButton;
			
			
			/* Add more options to the header */
			moreButtonTexture = MaterialDeepGreyAmberMobileThemeIcons.moreVerticalTexture;
			moreButtonImage = new Image(moreButtonTexture);
			moreButton = new Button();
			moreButton.defaultIcon = moreButtonImage;
			moreButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
			moreButton.addEventListener( Event.TRIGGERED, onMoreButtonTriggered );
			moreButton.validate();
			
			/* Add treatments to the header */
			treatmentsTexture = MaterialDeepGreyAmberMobileThemeIcons.addTexture;
			treatmentsImage = new Image(treatmentsTexture);
			treatmentsButton = new Button();
			treatmentsButton.defaultIcon = treatmentsImage;
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
			treatmentsList.addEventListener(TreatmentsList.CLOSE, onCloseCallOut);
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 && treatmentsEnabled)
			{
				iphone4DummyMarker = new Sprite();
				var globalpoint:Point = treatmentsButton.localToGlobal(new Point(treatmentsButton.width / 2, treatmentsButton.height / 2));
				iphone4DummyMarker.x = globalpoint.x;
				iphone4DummyMarker.y = globalpoint.y + 15;
				Starling.current.stage.addChild(iphone4DummyMarker);
				callout = Callout.show( treatmentsList, iphone4DummyMarker );
			}
			else
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
			if (callout != null)
			{
				callout.close();
				callout.dispose();
				callout = null;
			}
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
			if (callout != null)
			{
				callout.removeFromParent();
				callout.dispose();
				callout = null;
			}
			
			if (menuButtonTexture != null)
			{
				menuButtonTexture.dispose();
				menuButtonTexture = null;
			}
			
			if (menuButtonImage != null)
			{
				menuButtonImage.removeFromParent();
				menuButtonImage.dispose();
				menuButtonImage = null;
			}
			
			if (moreButtonTexture != null)
			{
				moreButtonTexture.dispose();
				moreButtonTexture = null;
			}
			
			if (moreButtonImage != null)
			{
				moreButtonImage.removeFromParent();
				moreButtonImage.dispose();
				moreButtonImage = null;
			}
			
			if (treatmentsTexture != null)
			{
				treatmentsTexture.dispose();
				treatmentsTexture = null;
			}
			
			if (treatmentsImage != null)
			{
				treatmentsImage.removeFromParent();
				treatmentsImage.dispose();
				treatmentsImage = null;
			}
			
			if (menuButton != null)
			{
				menuButton.removeEventListener( Event.TRIGGERED, onMenuButtonTriggered );
				menuButton.removeFromParent();
				menuButton.dispose();
				menuButton = null;
			}
			
			if (treatmentsButton != null)
			{
				treatmentsButton.removeEventListener( Event.TRIGGERED, onTreatmentButtonTriggered );
				treatmentsButton.removeFromParent();
				treatmentsButton.dispose();
				treatmentsButton = null;
			}
			
			if (moreButton != null)
			{
				moreButton.removeEventListener( Event.TRIGGERED, onMoreButtonTriggered );
				moreButton.removeFromParent();
				moreButton.dispose();
				moreButton = null;
			}
			
			if (treatmentsList != null)
			{
				treatmentsList.removeEventListener(ExtraOptionsList.CLOSE, onCloseCallOut);
				treatmentsList.removeFromParent();
				treatmentsList.dispose();
				treatmentsList = null;
			}
			
			if (extraOptionsList != null)
			{
				extraOptionsList.removeEventListener(ExtraOptionsList.CLOSE, onCloseCallOut);
				extraOptionsList.removeFromParent();
				extraOptionsList.dispose();
				extraOptionsList = null;
			}
			
			if (iphone4DummyMarker != null)
			{
				Starling.current.stage.removeChild(iphone4DummyMarker);
				iphone4DummyMarker.removeFromParent();
				iphone4DummyMarker.dispose();
				iphone4DummyMarker = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}