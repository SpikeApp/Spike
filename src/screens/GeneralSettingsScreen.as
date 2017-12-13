package screens
{
	import display.LayoutFactory;
	import display.settings.general.GlucoseSettingsList;
	import display.settings.general.NotificationSettingsList;
	import display.settings.general.UpdateSettingsList;
	
	import feathers.controls.Alert;
	import feathers.controls.Label;
	import feathers.data.ListCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;

	[ResourceBundle("generalsettingsscreen")]
	[ResourceBundle("globalsettings")]
	
	public class GeneralSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var glucoseSettings:GlucoseSettingsList;
		private var notificationSettings:NotificationSettingsList;
		private var updatesSettingsList:UpdateSettingsList;
		
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
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','general_settings_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.settingsApplicationsTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Glucose Section Label
			var glucoseLabel:Label = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','glucose_settings_title'));
			screenRenderer.addChild(glucoseLabel);
			
			//Glucose Settings
			glucoseSettings = new GlucoseSettingsList();
			screenRenderer.addChild(glucoseSettings);
			
			//Notifications Section Label
			var notificationsLabel:Label = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','bg_notifications'), true);
			screenRenderer.addChild(notificationsLabel);
			
			//Notification Settings
			notificationSettings = new NotificationSettingsList();
			screenRenderer.addChild(notificationSettings);
			
			//Update Section Label
			var updateLabel:Label = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('generalsettingsscreen','check_for_updates'), true);
			screenRenderer.addChild(updateLabel);
			
			//Update Settings
			updatesSettingsList = new UpdateSettingsList();
			screenRenderer.addChild(updatesSettingsList);
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
			if(glucoseSettings.needsSave || notificationSettings.needsSave || updatesSettingsList.needsSave)
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
			if (glucoseSettings.needsSave)
				glucoseSettings.save();
			if (notificationSettings.needsSave)
				notificationSettings.save();
			if (updatesSettingsList.needsSave)
				updatesSettingsList.save();
			
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
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}