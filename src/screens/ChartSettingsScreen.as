package screens
{
	import display.LayoutFactory;
	import display.settings.chart.ColorSettingsList;
	import display.settings.chart.DisplaySettingsList;
	import display.settings.chart.SizeSettingsList;
	
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;

	public class ChartSettingsScreen extends BaseSubScreen
	{
		public function ChartSettingsScreen() 
		{
			super();
			
			/* Set Header Title */
			title = "Chart";
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.timelineTexture);
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
			//Colors Section Label
			var colorsLabel:Label = LayoutFactory.createSectionLabel("Colors");
			screenRenderer.addChild(colorsLabel);
			
			//Colors Settings
			var colorsSettings:List = new ColorSettingsList(this);
			screenRenderer.addChild(colorsSettings);
			
			//Size Section Label
			var sizeLabel:Label = LayoutFactory.createSectionLabel("Size", true);
			screenRenderer.addChild(sizeLabel);
			
			//Size Settings
			var sizeSettings:List = new SizeSettingsList();
			screenRenderer.addChild(sizeSettings);
			
			//Display Section Label
			var displayLabel:Label = LayoutFactory.createSectionLabel("Display", true);
			screenRenderer.addChild(displayLabel);
			
			//Display Settings
			var displaySettings:List = new DisplaySettingsList();
			screenRenderer.addChild(displaySettings);
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