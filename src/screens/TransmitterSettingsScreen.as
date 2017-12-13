package screens
{
	import display.LayoutFactory;
	import display.settings.transmitter.TransmitterSettingsList;
	
	import feathers.controls.Alert;
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.data.ListCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;
	
	[ResourceBundle("transmittersettingsscreen")]
	[ResourceBundle("globalsettings")]

	public class TransmitterSettingsScreen extends BaseSubScreen
	{		

		private var transmitterSettings:TransmitterSettingsList;
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
			var transmitterLabel:Label = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('transmittersettingsscreen','transmitter_settings_title'));
			screenRenderer.addChild(transmitterLabel);
			
			//Transmitter Settings
			transmitterSettings = new TransmitterSettingsList();
			screenRenderer.addChild(transmitterSettings);
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
			//If settings have been modified, display Alert
			if(transmitterSettings.needsSave)
			{
				var alert:Alert = Alert.show(
					ModelLocator.resourceManagerInstance.getString('globalsettings','want_to_save_changes'),
					ModelLocator.resourceManagerInstance.getString('globalsettings','save_changes'),
					new ListCollection(
						[
							{ label: ModelLocator.resourceManagerInstance.getString('globalsettings','no_uppercase'), triggered: onSkipSaveSettings },
							{ label: ModelLocator.resourceManagerInstance.getString('globalsettings','yes_uppercase'), triggered: onSaveSettings }
						]
					)
				);
			}
			else
				dispatchEventWith(Event.COMPLETE);
		}
		
		private function onSaveSettings(e:Event):void
		{
			//Save Settings
			if (transmitterSettings.needsSave)
				transmitterSettings.save();
			
			//Pop Screen
			dispatchEventWith(Event.COMPLETE);
		}
		
		private function onSkipSaveSettings(e:Event):void
		{
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