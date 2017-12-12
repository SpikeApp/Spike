package screens
{
	import display.transmitter.TransmitterStatusList;
	
	import feathers.controls.GroupedList;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.DisplayObject;
	
	import ui.AppInterface;
	
	import utils.Constants;

	public class TransmitterScreen extends BaseSubScreen
	{
		public function TransmitterScreen() 
		{
			super();
			
			/* Set Header Title */
			title = "Transmitter";
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.bluetoothTexture);
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
			var statusList:GroupedList = new TransmitterStatusList();
			screenRenderer.addChild(statusList);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 2;
		}
		
		override protected function draw():void 
		{
			var layoutInvalid:Boolean = isInvalid( INVALIDATION_FLAG_LAYOUT );
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}