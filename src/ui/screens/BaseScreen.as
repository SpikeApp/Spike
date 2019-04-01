package ui.screens
{	
	import flash.geom.Point;
	import flash.system.System;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import events.ScreenEvent;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.List;
	import feathers.controls.PanelScreen;
	import feathers.controls.ScrollContainer;
	import feathers.controls.ScrollPolicy;
	import feathers.events.FeathersEventType;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	import ui.screens.display.extraoptions.ExtraOptionsList;
	import ui.screens.display.treatments.TreatmentsList;
	
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
		private var treatmentsEnabled:Boolean;
		private var menuButtonTexture:Texture;
		private var menuButtonImage:Image;
		private var moreButtonImage:Image;
		private var moreButtonTexture:Texture;
		private var treatmentsTexture:Texture;
		private var treatmentsImage:Image;
		private var treatmentsMenuContainer:ScrollContainer;
		private var extraOptionsMenuContainer:ScrollContainer;
		
		/* Logical Variables */
		private var isTreatmentsMenuOpened:Boolean = false;
		private var isExtraOptionsMenuOpened:Boolean = false;
		
		public function BaseScreen()
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupContent();
			setupEventListeners();
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
			
			if ((CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED) == "true" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ON_CHART_ENABLED) == "true" && !CGMBlueToothDevice.isDexcomFollower()) || !CGMBlueToothDevice.isFollower()) 
			{
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
			else
			{
				/* Populate Header */
				headerProperties.rightItems = new <DisplayObject>[
					moreButton
				];
			}
		}
		
		private function setupEventListeners():void
		{
			this.addEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onTransitionInComplete);
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
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
			if (treatmentsMenuContainer != null) treatmentsMenuContainer.removeFromParent(true);
			treatmentsMenuContainer = new ScrollContainer();
			treatmentsMenuContainer.layout = new VerticalLayout();
			treatmentsMenuContainer.horizontalScrollPolicy = ScrollPolicy.OFF;
			
			if (treatmentsList != null) treatmentsList.removeFromParent(true);
			treatmentsList = new TreatmentsList();
			treatmentsList.addEventListener(TreatmentsList.CLOSE, onCloseCallOut);
			treatmentsMenuContainer.addChild(treatmentsList);
			treatmentsMenuContainer.validate();
			
			var treatmentsCalloutPointOfOrigin:Number = treatmentsButton.localToGlobal(new Point(0, 0)).y + treatmentsButton.height;
			var treatmentsContentOriginalHeight:Number = treatmentsList.height + 60;
			var suggestedTreatmentsCalloutHeight:Number = Constants.stageHeight - treatmentsCalloutPointOfOrigin - 5;
			var finalCalloutHeight:Number = treatmentsContentOriginalHeight > suggestedTreatmentsCalloutHeight ?  suggestedTreatmentsCalloutHeight : treatmentsContentOriginalHeight;
			
			callout = Callout.show( treatmentsMenuContainer, treatmentsButton );
			callout.addEventListener(Event.CLOSE, onCloseCallOut);
			
			callout.height = finalCalloutHeight;
			treatmentsMenuContainer.height = finalCalloutHeight - 50;
			treatmentsMenuContainer.maxHeight = finalCalloutHeight - 50;
			
			isTreatmentsMenuOpened = true;
		}
		
		protected function onMoreButtonTriggered():void 
		{
			if (extraOptionsMenuContainer != null) extraOptionsMenuContainer.removeFromParent(true);
			extraOptionsMenuContainer = new ScrollContainer();
			extraOptionsMenuContainer.layout = new VerticalLayout();
			extraOptionsMenuContainer.horizontalScrollPolicy = ScrollPolicy.OFF;
			
			if (extraOptionsList != null) extraOptionsList.removeFromParent(true);
			extraOptionsList = new ExtraOptionsList();
			extraOptionsList.addEventListener(ExtraOptionsList.CLOSE, onCloseCallOut);
			extraOptionsMenuContainer.addChild(extraOptionsList);
			extraOptionsMenuContainer.validate();
			
			var extraOptionsCalloutPointOfOrigin:Number = moreButton.localToGlobal(new Point(0, 0)).y + moreButton.height;
			var extraOptionsContentOriginalHeight:Number = extraOptionsList.height + 60;
			var suggestedExtraOptionsCalloutHeight:Number = Constants.stageHeight - extraOptionsCalloutPointOfOrigin - 5;
			var finalCalloutHeight:Number = extraOptionsContentOriginalHeight > suggestedExtraOptionsCalloutHeight ?  suggestedExtraOptionsCalloutHeight : extraOptionsContentOriginalHeight;
			
			callout = Callout.show( extraOptionsMenuContainer, moreButton );
			callout.addEventListener(Event.CLOSE, onCloseCallOut);
			
			callout.height = finalCalloutHeight;
			Callout.stagePaddingRight = -5;
			extraOptionsMenuContainer.height = finalCalloutHeight - 50;
			extraOptionsMenuContainer.maxHeight = finalCalloutHeight - 50;
			
			isExtraOptionsMenuOpened = true;
		}
		
		private function onCloseCallOut(e:Event):void
		{
			isTreatmentsMenuOpened = false;
			isExtraOptionsMenuOpened = false;
			
			disposeOnScreenComponents();
			
			if (callout != null)
			{
				callout.removeFromParent();
				callout.removeEventListener(Event.CLOSE, onCloseCallOut);
				callout.disposeContent = true;
				callout.dispose();
				callout = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			System.gc();
		}
		
		private function toggleMenu():void 
		{
			if(!AppInterface.instance.drawers.isLeftDrawerOpen)
				dispatchEventWith( ScreenEvent.TOGGLE_MENU );
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			var pointOfOrigin:Number;
			var contentOriginalHeight:Number;
			var suggestedCalloutHeight:Number;
			var finalCalloutHeight:Number;
			
			if (isTreatmentsMenuOpened && callout != null && treatmentsMenuContainer != null)
			{
				pointOfOrigin = treatmentsButton.localToGlobal(new Point(0, 0)).y + treatmentsButton.height;
				contentOriginalHeight = treatmentsList.height + 60;
				suggestedCalloutHeight = Constants.stageHeight - pointOfOrigin - 5;
				finalCalloutHeight = contentOriginalHeight > suggestedCalloutHeight ?  suggestedCalloutHeight : contentOriginalHeight;
				
				callout.height = finalCalloutHeight;
				treatmentsMenuContainer.height = finalCalloutHeight - 50;
				treatmentsMenuContainer.maxHeight = finalCalloutHeight - 50;
			}
			else if (isExtraOptionsMenuOpened && callout != null && extraOptionsMenuContainer != null)
			{
				pointOfOrigin = moreButton.localToGlobal(new Point(0, 0)).y + moreButton.height;
				contentOriginalHeight = extraOptionsList.height + 60;
				suggestedCalloutHeight = Constants.stageHeight - pointOfOrigin - 5;
				finalCalloutHeight = contentOriginalHeight > suggestedCalloutHeight ?  suggestedCalloutHeight : contentOriginalHeight;
				
				callout.height = finalCalloutHeight;
				extraOptionsMenuContainer.height = finalCalloutHeight - 50;
				extraOptionsMenuContainer.maxHeight = finalCalloutHeight - 50;
			}
		}
		
		protected function onTransitionInComplete(e:Event):void
		{
			//Meant to be overriden
		}
		
		/**
		 * Utility
		 */
		private function disposeOnScreenComponents():void
		{
			if (treatmentsList != null)
			{
				treatmentsList.removeEventListener(TreatmentsList.CLOSE, onCloseCallOut);
				treatmentsList.removeFromParent();
				treatmentsList.dispose();
				treatmentsList = null;
			}
			
			if (treatmentsMenuContainer != null)
			{
				treatmentsMenuContainer.removeFromParent();
				treatmentsMenuContainer.dispose();
				treatmentsMenuContainer = null;
			}
			
			if (extraOptionsList != null)
			{
				extraOptionsList.removeEventListener(ExtraOptionsList.CLOSE, onCloseCallOut);
				extraOptionsList.removeFromParent();
				extraOptionsList.dispose();
				extraOptionsList = null;
			}
			
			if (extraOptionsMenuContainer != null)
			{
				extraOptionsMenuContainer.removeFromParent();
				extraOptionsMenuContainer.dispose();
				extraOptionsMenuContainer = null;
			}
		}
		
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if (menuButtonTexture != null)
			{
				menuButtonTexture.dispose();
				menuButtonTexture = null;
			}
			
			if (menuButtonImage != null)
			{
				menuButtonImage.removeFromParent();
				if (menuButtonImage.texture != null)
					menuButtonImage.texture.dispose();
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
				if (moreButtonImage.texture != null)
					moreButtonImage.texture.dispose();
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
				if (treatmentsImage.texture != null)
					treatmentsImage.texture.dispose();
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
			
			if (treatmentsMenuContainer != null)
			{
				treatmentsMenuContainer.removeFromParent();
				treatmentsMenuContainer.dispose();
				treatmentsMenuContainer = null;
			}
			
			if (extraOptionsList != null)
			{
				extraOptionsList.removeEventListener(ExtraOptionsList.CLOSE, onCloseCallOut);
				extraOptionsList.removeFromParent();
				extraOptionsList.dispose();
				extraOptionsList = null;
			}
			
			if (extraOptionsMenuContainer != null)
			{
				extraOptionsMenuContainer.removeFromParent();
				extraOptionsMenuContainer.dispose();
				extraOptionsMenuContainer = null;
			}
			
			if (callout != null)
			{
				callout.removeEventListener(Event.CLOSE, onCloseCallOut);
				callout.removeFromParent();
				callout.disposeContent = true;
				callout.dispose();
				callout = null;
			}
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);
			System.gc();
		}
	}
}