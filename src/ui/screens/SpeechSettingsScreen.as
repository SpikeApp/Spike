package ui.screens
{
	import flash.system.System;
	
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.settings.speech.SpeechSettingsList;
	
	import utils.Constants;
	
	[ResourceBundle("speechsettingsscreen")]

	public class SpeechSettingsScreen extends BaseSubScreen
	{	
		/* Display Objects */
		private var speechSettings:SpeechSettingsList;
		private var speechLabel:Label;
		
		public function SpeechSettingsScreen() 
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
			title = ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','speech_settings_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.phoneSpeakerTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Speech Section Label
			speechLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','speech_settings_title'));
			screenRenderer.addChild(speechLabel);
			
			//Glucose Settings
			speechSettings = new SpeechSettingsList();
			screenRenderer.addChild(speechSettings);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 3;
		}
		
		/**
		 * Event Handlers
		 */
		override protected function onBackButtonTriggered(event:Event):void
		{
			//Save Settings
			if (speechSettings.needsSave)
				speechSettings.save();
			
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
			//Pop Screen
			dispatchEventWith(Event.COMPLETE);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (speechSettings != null)
			{
				speechSettings.removeFromParent();
				speechSettings.dispose();
				speechSettings = null;
			}
			
			if (speechLabel != null)
			{
				speechLabel.removeFromParent();
				speechLabel.dispose();
				speechLabel = null;
			}
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);
		}
		
		override protected function draw():void 
		{
			var layoutInvalid:Boolean = isInvalid( INVALIDATION_FLAG_LAYOUT );
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}