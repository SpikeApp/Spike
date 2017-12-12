package screens
{
	import display.LayoutFactory;
	import display.settings.general.GlucoseSettingsList;
	import display.settings.general.NotificationSettingsList;
	import display.settings.general.UpdateSettingsList;
	
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;

	public class GeneralSettingsScreen extends BaseSubScreen
	{
		public function GeneralSettingsScreen() 
		{
			super();
			
			/* Set Header Title */
			title = "General";
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.settingsApplicationsTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupContent();
			adjustMainMenu();
		}
		
		private function setupContent():void
		{
			//Glucose Section Label
			var glucoseLabel:Label = LayoutFactory.createSectionLabel("Glucose");
			screenRenderer.addChild(glucoseLabel);
			
			//Glucose Settings
			var glucoseSettings:List = new GlucoseSettingsList();
			screenRenderer.addChild(glucoseSettings);
			
			//Notifications Section Label
			var notificationsLabel:Label = LayoutFactory.createSectionLabel("Notifications", true);
			screenRenderer.addChild(notificationsLabel);
			
			//Notification Settings
			var notificationSettings:List = new NotificationSettingsList();
			screenRenderer.addChild(notificationSettings);
			
			//Update Section Label
			var updateLabel:Label = LayoutFactory.createSectionLabel("Application Updates", true);
			screenRenderer.addChild(updateLabel);
			
			//Update Settings
			var updatesSettingsList:List = new UpdateSettingsList();
			screenRenderer.addChild(updatesSettingsList);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 3;
		}
		
		override protected function onBackButtonTriggered(event:Event):void
		{
			dispatchEventWith(Event.COMPLETE);
		}
		
		override protected function draw():void 
		{
			var layoutInvalid:Boolean = isInvalid( INVALIDATION_FLAG_LAYOUT );
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}