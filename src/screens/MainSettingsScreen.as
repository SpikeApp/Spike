package screens
{
	
	import display.settings.main.SettingsList;
	
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.DisplayObject;
	
	import ui.AppInterface;
	
	import utils.Constants;

	public class MainSettingsScreen extends BaseSubScreen
	{	
		public function MainSettingsScreen() 
		{
			super();
			
			/* Set Header Title */
			title = "Settings";
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.settingsTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupScreen();
			adjustMainMenu();
		}
		
		private function setupScreen():void
		{
			var settingsMenu:SettingsList = new SettingsList();
			addChild(settingsMenu);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 3;
		}
		
		override protected function draw():void 
		{
			var layoutInvalid:Boolean = isInvalid( INVALIDATION_FLAG_LAYOUT );
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}