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
	import ui.screens.display.settings.treatments.BolusWizardSettingsList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("treatments")]

	public class BolusWizardSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var bolusWizardSettings:BolusWizardSettingsList;
		private var bolusWizardLabel:Label;
		
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
			
			//Insulins Section Label
			bolusWizardLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('treatments','calculations_label'), true);
			screenRenderer.addChild(bolusWizardLabel);
			
			//Insulins Settings
			bolusWizardSettings = new BolusWizardSettingsList();
			screenRenderer.addChild(bolusWizardSettings);
		}
		
		/**
		 * Event Handlers
		 */
		override protected function onBackButtonTriggered(event:Event):void
		{
			if (bolusWizardSettings.needsSave)
				bolusWizardSettings.save();
			
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
				if (bolusWizardLabel != null) bolusWizardLabel.paddingLeft = 30;
			}
			else
			{
				if (bolusWizardLabel != null) bolusWizardLabel.paddingLeft = 0;
			}
			
			setupHeaderSize();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (bolusWizardLabel != null)
			{
				bolusWizardLabel.removeFromParent();
				bolusWizardLabel.dispose();
				bolusWizardLabel = null;
			}
			
			if (bolusWizardSettings != null)
			{
				bolusWizardSettings.removeFromParent();
				bolusWizardSettings.dispose();
				bolusWizardSettings = null;
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