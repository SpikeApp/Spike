package ui.screens
{
	import flash.display.StageOrientation;
	import flash.system.System;
	
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.events.FeathersEventType;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import services.TutorialService;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.settings.general.DataCollectionSettingsList;
	import ui.screens.display.settings.general.DateSettingsList;
	import ui.screens.display.settings.general.GlucoseSettingsList;
	import ui.screens.display.settings.general.LanguageSettingsList;
	
	import utils.Constants;
	import utils.DeviceInfo;

	[ResourceBundle("generalsettingsscreen")]
	
	public class GeneralSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var chartDateSettings:DateSettingsList;
		private var chartDateFormatLabel:Label;
		private var glucoseSettings:GlucoseSettingsList;
		private var glucoseLabel:Label;
		private var dataCollectionLabel:Label;
		private var dataCollectionSettings:DataCollectionSettingsList;
		private var languageLabel:Label;
		private var languageSettings:LanguageSettingsList;
		
		public function GeneralSettingsScreen() 
		{
			super();
			
			setupHeader();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupContent();
			adjustMainMenu();
			setupEventHandlers();
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','general_settings_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.generalSettingsTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Language Section Label
			languageLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','language_title'), true);
			screenRenderer.addChild(languageLabel);
			
			//Language Settings
			languageSettings = new LanguageSettingsList();
			screenRenderer.addChild(languageSettings);
			
			//Data Collection Section Label
			dataCollectionLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','data_collection_title'), true);
			screenRenderer.addChild(dataCollectionLabel);
			
			//Data Collection Settings
			dataCollectionSettings = new DataCollectionSettingsList();
			screenRenderer.addChild(dataCollectionSettings);
			
			//Time Format Section Label
			chartDateFormatLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','chart_date_settings_title'), true);
			screenRenderer.addChild(chartDateFormatLabel);
			
			//Time Format Settings
			chartDateSettings = new DateSettingsList();
			screenRenderer.addChild(chartDateSettings);
			
			//Glucose Section Label
			glucoseLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','glucose_settings_title'));
			screenRenderer.addChild(glucoseLabel);
			
			//Glucose Settings
			glucoseSettings = new GlucoseSettingsList();
			screenRenderer.addChild(glucoseSettings);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 4 : 3;
		}
		
		private function setupEventHandlers():void
		{
			if (TutorialService.isActive && TutorialService.thirdStepActive)
				addEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onScreenIn);
		}
		
		/**
		 * Event Handlers
		 */
		private function onScreenIn(e:Event):void
		{
			removeEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onScreenIn);
			
			if( TutorialService.isActive && TutorialService.thirdStepActive)
				Starling.juggler.delayCall(TutorialService.fourthStep, .2);
		}
		
		override protected function onBackButtonTriggered(event:Event):void
		{
			//Save Settings
			if (languageSettings != null && languageSettings.needsSave)
				languageSettings.save();
			if (glucoseSettings.needsSave)
				glucoseSettings.save();
			if (chartDateSettings.needsSave)
				chartDateSettings.save();
			if (dataCollectionSettings.needsSave)
				dataCollectionSettings.save();
			
			//Advance tutorial
			if (TutorialService.isActive && TutorialService.fourthStepActive)
				Starling.juggler.delayCall(TutorialService.fifthStep, 1);
			
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
			dispatchEventWith(Event.COMPLETE);
		}
		
		override protected function onTransitionInComplete(e:Event):void
		{
			//Swipe to pop functionality
			AppInterface.instance.navigator.isSwipeToPopEnabled = true;
		}
		
		override protected function onStarlingBaseResize(e:ResizeEvent):void 
		{
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait && Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
			{
				if (languageLabel != null) languageLabel.paddingLeft = 30;
				if (dataCollectionLabel != null) dataCollectionLabel.paddingLeft = 30;
				if (chartDateFormatLabel != null) chartDateFormatLabel.paddingLeft = 30;
				if (glucoseLabel != null) glucoseLabel.paddingLeft = 30;
			}
			else
			{
				if (languageLabel != null) languageLabel.paddingLeft = 0;
				if (dataCollectionLabel != null) dataCollectionLabel.paddingLeft = 0;
				if (chartDateFormatLabel != null) chartDateFormatLabel.paddingLeft = 0;
				if (glucoseLabel != null) glucoseLabel.paddingLeft = 0;
			}
			
			setupHeaderSize();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if( TutorialService.isActive)
				removeEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onScreenIn);
			
			if (glucoseSettings != null)
			{
				glucoseSettings.removeFromParent();
				glucoseSettings.dispose();
				glucoseSettings = null;
			}
			
			if (glucoseLabel != null)
			{
				glucoseLabel.removeFromParent();
				glucoseLabel.dispose();
				glucoseLabel = null;
			}
			
			if (chartDateSettings != null)
			{
				chartDateSettings.removeFromParent();
				chartDateSettings.dispose();
				chartDateSettings = null;
			}
			
			if (chartDateFormatLabel != null)
			{
				chartDateFormatLabel.removeFromParent();
				chartDateFormatLabel.dispose();
				chartDateFormatLabel = null;
			}
			
			if (dataCollectionLabel != null)
			{
				dataCollectionLabel.removeFromParent();
				dataCollectionLabel.dispose();
				dataCollectionLabel = null;
			}
			
			if (dataCollectionSettings != null)
			{
				dataCollectionSettings.removeFromParent();
				dataCollectionSettings.dispose();
				dataCollectionSettings = null;
			}
			
			if (languageSettings != null)
			{
				languageSettings.removeFromParent();
				languageSettings.dispose();
				languageSettings = null;
			}
			
			if (languageLabel != null)
			{
				languageLabel.removeFromParent();
				languageLabel.dispose();
				languageLabel = null;
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