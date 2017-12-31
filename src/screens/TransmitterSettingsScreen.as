package screens
{
	import flash.system.System;
	
	import display.LayoutFactory;
	import display.settings.transmitter.TransmitterSettingsList;
	
	import events.ScreenEvent;
	
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
	
	import utils.AlertManager;
	import utils.Constants;
	
	[ResourceBundle("transmittersettingsscreen")]
	[ResourceBundle("globalsettings")]

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
			//Transmitter Section Label
			transmitterLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','transmitter_settings_title'));
			screenRenderer.addChild(transmitterLabel);
			
			//Transmitter Settings
			transmitterSettings = new TransmitterSettingsList();
			screenRenderer.addChild(transmitterSettings);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 3;
		}
		
		private function setupEventHandlers():void
		{
			addEventListener(FeathersEventType.TRANSITION_OUT_COMPLETE, onScreenOut);
			AppInterface.instance.menu.addEventListener(ScreenEvent.BEGIN_SWITCH, onScreenOut);
			if( TutorialService.isActive && TutorialService.fifthStepActive)
				addEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onScreenIn);
		}
		
		/**
		 * Event Handlers
		 */
		private function onScreenOut(e:Event):void
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
		}
		
		private function onScreenIn(e:Event):void
		{
			removeEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onScreenIn);
			
			if( TutorialService.isActive && TutorialService.fifthStepActive)
				Starling.juggler.delayCall(TutorialService.sixthStep, .2);
		}
		
		override protected function onBackButtonTriggered(event:Event):void
		{
			//Pop Screen
			dispatchEventWith(Event.COMPLETE);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			removeEventListener(FeathersEventType.TRANSITION_OUT_COMPLETE, onScreenOut);
			AppInterface.instance.menu.removeEventListener(ScreenEvent.BEGIN_SWITCH, onScreenOut);
			if( TutorialService.isActive)
				removeEventListener(FeathersEventType.TRANSITION_IN_COMPLETE, onScreenIn);
			
			if (transmitterSettings != null)
			{
				transmitterSettings.dispose();
				transmitterSettings = null;
			}
			
			if (transmitterLabel != null)
			{
				transmitterLabel.dispose();
				transmitterLabel = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
		
		override protected function draw():void 
		{
			var layoutInvalid:Boolean = isInvalid( INVALIDATION_FLAG_LAYOUT );
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}