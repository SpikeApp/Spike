package ui.screens
{
	import flash.display.StageOrientation;
	import flash.system.System;
	
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.controls.ScrollPolicy;
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
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.settings.transmitter.TransmitterSettingsList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("transmittersettingsscreen")]

	public class TransmitterSettingsScreen extends BaseSubScreen
	{		
		/* Display Objects */
		private var transmitterSettings:TransmitterSettingsList;
		private var transmitterLabel:Label;
		
		public function TransmitterSettingsScreen() 
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
			title = ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','transmitter_settings_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.bluetoothTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Transmitter Section Label
			transmitterLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','transmitter_settings_title'));
			screenRenderer.addChild(transmitterLabel);
			
			//Transmitter Settings
			transmitterSettings = new TransmitterSettingsList();
			screenRenderer.addChild(transmitterSettings);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 4 : 3;
		}
		
		private function setupEventHandlers():void
		{
			if( TutorialService.isActive && TutorialService.fifthStepActive)
				addEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onScreenIn);
		}
		
		/**
		 * Event Handlers
		 */
		private function onScreenIn(e:Event):void
		{
			removeEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onScreenIn);
			
			if( TutorialService.isActive && TutorialService.fifthStepActive)
				Starling.juggler.delayCall(TutorialService.sixthStep, .2);
		}
		
		override protected function onBackButtonTriggered(event:Event):void
		{
			//Save Settings
			if (transmitterSettings.needsSave)
				transmitterSettings.save();
			
			if (TutorialService.isActive && TutorialService.sixthStepActive)
				Starling.juggler.delayCall(TutorialService.seventhStep, .2);
			else if (transmitterSettings.warnUser) //Warn User if Transmitter ID is Empty
			{
				transmitterSettings.warnUser = false;
				AlertManager.showSimpleAlert(
					ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','warning_alert_message'),
					30
				);
			}
			
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
				if (transmitterLabel != null) transmitterLabel.paddingLeft = 30;
			}
			else
			{
				if (transmitterLabel != null) transmitterLabel.paddingLeft = 0;
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
			
			if (transmitterSettings != null)
			{
				transmitterSettings.removeFromParent();
				transmitterSettings.dispose();
				transmitterSettings = null;
			}
			
			if (transmitterLabel != null)
			{
				transmitterLabel.removeFromParent();
				transmitterLabel.dispose();
				transmitterLabel = null;
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