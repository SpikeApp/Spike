package screens
{
	import display.LayoutFactory;
	import display.settings.transmitter.TransmitterSettingsList;
	
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;

	public class TransmitterSettingsScreen extends BaseSubScreen
	{		
		public function TransmitterSettingsScreen() 
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
			
			setupContent();
			adjustMainMenu();
		}
		
		private function setupContent():void
		{
			//Transmitter Section Label
			var transmitterLabel:Label = LayoutFactory.createSectionLabel("Transmitter");
			screenRenderer.addChild(transmitterLabel);
			
			//Transmitter Settings
			var transmitterSettings:List = new TransmitterSettingsList();
			screenRenderer.addChild(transmitterSettings);
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