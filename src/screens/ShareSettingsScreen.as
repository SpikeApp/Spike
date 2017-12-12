package screens
{
	import display.LayoutFactory;
	import display.settings.share.DexcomSettingsList;
	import display.settings.share.HealthkitSettingsList;
	import display.settings.share.NightscoutSettingsList;
	
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;

	public class ShareSettingsScreen extends BaseSubScreen
	{
		public function ShareSettingsScreen() 
		{
			super();
			
			/* Set Header Title */
			title = "Share";
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.shareTexture);
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
			//Healthkit Section Label
			var healthkitLabel:Label = LayoutFactory.createSectionLabel("Healthkit");
			screenRenderer.addChild(healthkitLabel);
			
			//Healthkit Settings
			var healthkitSettings:List = new HealthkitSettingsList();
			screenRenderer.addChild(healthkitSettings);
			
			//Dexcom Section Label
			var dexcomLabel:Label = LayoutFactory.createSectionLabel("Dexcom Share", true);
			screenRenderer.addChild(dexcomLabel);
			
			//Dexcom Settings
			var dexcomSettings:List = new DexcomSettingsList();
			screenRenderer.addChild(dexcomSettings);
			
			//Nightscout Section Label
			var nightscoutLabel:Label = LayoutFactory.createSectionLabel("Nightscout", true);
			screenRenderer.addChild(nightscoutLabel);
			
			//Nightscout Settings
			var nightscoutSettings:List = new NightscoutSettingsList();
			screenRenderer.addChild(nightscoutSettings);
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