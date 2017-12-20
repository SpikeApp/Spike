package screens
{
	import display.LayoutFactory;
	import display.settings.speech.SpeechSettingsList;
	
	import feathers.controls.Alert;
	import feathers.controls.Label;
	import feathers.data.ListCollection;
	import feathers.events.FeathersEventType;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;
	
	[ResourceBundle("speechsettingsscreen")]

	public class SpeechSettingsScreen extends BaseSubScreen
	{	

		private var speechSettings:SpeechSettingsList;
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
			setupEventHandlers();
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
			//Speech Section Label
			var speechLabel:Label = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','speech_settings_title'));
			screenRenderer.addChild(speechLabel);
			
			//Glucose Settings
			speechSettings = new SpeechSettingsList();
			screenRenderer.addChild(speechSettings);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 3;
		}
		
		private function setupEventHandlers():void
		{
			addEventListener(FeathersEventType.TRANSITION_OUT_COMPLETE, onScreenOut);
		}
		
		/**
		 * Event Handlers
		 */
		private function onScreenOut(e:Event):void
		{
			//Save Settings
			if (speechSettings.needsSave)
				speechSettings.save();
		}
		
		override protected function onBackButtonTriggered(event:Event):void
		{
			//Pop Screen
			dispatchEventWith(Event.COMPLETE);
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void 
		{
			var layoutInvalid:Boolean = isInvalid( INVALIDATION_FLAG_LAYOUT );
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}