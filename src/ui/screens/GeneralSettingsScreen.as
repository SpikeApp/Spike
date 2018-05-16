package ui.screens
{
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
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.settings.general.DataCollectionSettingsList;
	import ui.screens.display.settings.general.DateSettingsList;
	import ui.screens.display.settings.general.GlucoseSettingsList;
	import ui.screens.display.settings.general.UpdateSettingsList;
	
	import utils.Constants;

	[ResourceBundle("generalsettingsscreen")]
	
	public class GeneralSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var chartDateSettings:DateSettingsList;
		private var chartDateFormatLabel:Label;
		private var glucoseSettings:GlucoseSettingsList;
		private var updatesSettingsList:UpdateSettingsList;
		private var glucoseLabel:Label;
		private var updateLabel:Label;
		private var dataCollectionLabel:Label;
		private var dataCollectionSettings:DataCollectionSettingsList;
		
		
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
			
			//Data Collection Section Label
			dataCollectionLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','data_collection_title'), true);
			screenRenderer.addChild(dataCollectionLabel);
			
			//Time Format Settings
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
			
			if (!ModelLocator.TEST_FLIGHT_MODE)
			{
				//Update Section Label
				updateLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','check_for_updates'), true);
				screenRenderer.addChild(updateLabel);
				
				//Update Settings
				updatesSettingsList = new UpdateSettingsList();
				screenRenderer.addChild(updatesSettingsList);
			}
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 3;
		}
		
		private function setupEventHandlers():void
		{
			if( TutorialService.isActive && TutorialService.thirdStepActive)
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
			if (glucoseSettings.needsSave)
				glucoseSettings.save();
			if (updatesSettingsList != null && updatesSettingsList.needsSave)
				updatesSettingsList.save();
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
			
			if (updatesSettingsList != null)
			{
				updatesSettingsList.removeFromParent();
				updatesSettingsList.dispose();
				updatesSettingsList = null;
			}
			
			if (glucoseLabel != null)
			{
				glucoseLabel.removeFromParent();
				glucoseLabel.dispose();
				glucoseLabel = null;
			}
			
			if (updateLabel != null)
			{
				updateLabel.removeFromParent();
				updateLabel.dispose();
				updateLabel = null;
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