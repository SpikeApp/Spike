package screens
{
	import display.LayoutFactory;
	import display.settings.loggingtracing.LoggingSettingsList;
	import display.settings.loggingtracing.TracingSettingsList;
	
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;

	public class LoggingTracingSettingsScreen extends BaseSubScreen
	{
		public function LoggingTracingSettingsScreen() 
		{
			super();
			
			/* Set Header Title */
			title = "Log & Trace";
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.bugReportTexture);
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
			//Tracing Section Label
			var tracingLabel:Label = LayoutFactory.createSectionLabel("Trace");
			screenRenderer.addChild(tracingLabel);
			
			//Tracing Settings
			var tracingSettings:List = new TracingSettingsList();
			screenRenderer.addChild(tracingSettings);
			
			//Logging Section Label
			var loggingLabel:Label = LayoutFactory.createSectionLabel("NSLog", true);
			screenRenderer.addChild(loggingLabel);
			
			//Loging Settings
			var loggingSettings:List = new LoggingSettingsList();
			screenRenderer.addChild(loggingSettings);
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