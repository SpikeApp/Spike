package screens
{
	import display.settings.alarms.AlertCustomizerList;
	
	import feathers.controls.Alert;
	import feathers.data.ListCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;

	public class AlertTypeCustomizerScreen extends BaseSubScreen
	{
		private var settingsSaved:Boolean = true;

		private var alertSettings:AlertCustomizerList;
		
		public function AlertTypeCustomizerScreen() 
		{
			super();
			
			/* Set Header Title */
			title = "Add Alert";
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.alarmTexture);
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
			alertSettings = new AlertCustomizerList();
			alertSettings.addEventListener(AlertCustomizerList.SAVED, onSettingsSaved);
			alertSettings.addEventListener(AlertCustomizerList.CHANGED, onSettingsChanged);
			screenRenderer.addChild(alertSettings);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 3;
		}
		
		private function onSettingsChanged():void
		{
			settingsSaved = false;
		}
		
		private function onSettingsSaved(e:Event):void
		{
			settingsSaved = true;
		}
		
		override protected function onBackButtonTriggered(event:Event):void
		{
			if(settingsSaved)
				dispatchEventWith(Event.COMPLETE);
			else
			{
				var alert:Alert = Alert.show(
					"Do you want to save your changes?",
					"Save Changes",
					new ListCollection(
						[
							{ label: "No", triggered: onSkipSaveSettings },
							{ label: "Yes", triggered: onSaveSettings }
						]
					)
				);
			}
		}
		
		private function onSaveSettings(e:Event):void
		{
			if(alertSettings.save())
				dispatchEventWith(Event.COMPLETE);
		}
		
		private function onSkipSaveSettings(e:Event):void
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