package ui.screens
{
	import flash.display.StageOrientation;
	import flash.system.System;
	
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.settings.treatments.BolusWizardCalculationsSettingsList;
	import ui.screens.display.settings.treatments.BolusWizardUISettingsList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("treatments")]
	[ResourceBundle("foodmanager")]

	public class BolusWizardSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var bolusWizardCalculationsSettings:BolusWizardCalculationsSettingsList;
		private var bolusWizardCalculationsLabel:Label;
		private var bolusWizardUILabel:Label;
		private var bolusWizardUISettings:BolusWizardUISettingsList;
		
		public function BolusWizardSettingsScreen() 
		{
			super();
			
			setupHeader();	
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('treatments','bolus_wizard_settings_label');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.bolusWizardTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Calculations Section Label
			bolusWizardCalculationsLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('treatments','calculations_label'), true);
			screenRenderer.addChild(bolusWizardCalculationsLabel);
			
			//Calculations Settings
			bolusWizardCalculationsSettings = new BolusWizardCalculationsSettingsList();
			screenRenderer.addChild(bolusWizardCalculationsSettings);
			
			//UI Section Label
			bolusWizardUILabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('foodmanager','user_interface_lable'), true);
			screenRenderer.addChild(bolusWizardUILabel);
			
			//UI Settings
			bolusWizardUISettings = new BolusWizardUISettingsList(this);
			screenRenderer.addChild(bolusWizardUISettings);
		}
		
		/**
		 * Event Handlers
		 */
		override protected function onBackButtonTriggered(event:Event):void
		{
			if (bolusWizardCalculationsSettings.needsSave)
				bolusWizardCalculationsSettings.save();
			
			if (bolusWizardUISettings.needsSave)
				bolusWizardUISettings.save();
			
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
			//Pop Screen
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
				if (bolusWizardCalculationsLabel != null) bolusWizardCalculationsLabel.paddingLeft = 30;
				if (bolusWizardUILabel != null) bolusWizardUILabel.paddingLeft = 30;
			}
			else
			{
				if (bolusWizardCalculationsLabel != null) bolusWizardCalculationsLabel.paddingLeft = 0;
				if (bolusWizardUILabel != null) bolusWizardUILabel.paddingLeft = 0;
			}
			
			setupHeaderSize();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (bolusWizardCalculationsLabel != null)
			{
				bolusWizardCalculationsLabel.removeFromParent();
				bolusWizardCalculationsLabel.dispose();
				bolusWizardCalculationsLabel = null;
			}
			
			if (bolusWizardCalculationsSettings != null)
			{
				bolusWizardCalculationsSettings.removeFromParent();
				bolusWizardCalculationsSettings.dispose();
				bolusWizardCalculationsSettings = null;
			}
			
			if (bolusWizardUILabel != null)
			{
				bolusWizardUILabel.removeFromParent();
				bolusWizardUILabel.dispose();
				bolusWizardUILabel = null;
			}
			
			if (bolusWizardUISettings != null)
			{
				bolusWizardUISettings.removeFromParent();
				bolusWizardUISettings.dispose();
				bolusWizardUISettings = null;
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