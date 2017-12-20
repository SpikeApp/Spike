package screens
{
	import display.LayoutFactory;
	import display.settings.loggingtracing.LoggingSettingsList;
	import display.settings.loggingtracing.TracingSettingsList;
	
	import feathers.controls.Alert;
	import feathers.controls.Label;
	import feathers.data.ListCollection;
	import feathers.events.FeathersEventType;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;
	
	[ResourceBundle("logtracesettingsscreen")]

	public class LoggingTracingSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var loggingSettings:LoggingSettingsList;
		private var tracingSettings:TracingSettingsList;
		
		public function LoggingTracingSettingsScreen() 
		{
			super();
			
			setupHeader();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupContent();
			adjustMainMenu();
			setupEventHandlers();
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('logtracesettingsscreen','screen_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.bugReportTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Tracing Section Label
			var tracingLabel:Label = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('logtracesettingsscreen','trace_section_title'));
			screenRenderer.addChild(tracingLabel);
			
			//Tracing Settings
			tracingSettings = new TracingSettingsList();
			screenRenderer.addChild(tracingSettings);
			
			//Logging Section Label
			var loggingLabel:Label = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('logtracesettingsscreen','nslog_section_title'), true);
			screenRenderer.addChild(loggingLabel);
			
			//Loging Settings
			loggingSettings = new LoggingSettingsList();
			screenRenderer.addChild(loggingSettings);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 3;
		}
		
		private function setupEventHandlers():void
		{
			addEventListener(FeathersEventType.TRANSITION_OUT_COMPLETE, onScreenOut);
		}
		
		/**
		 * Event Handlers
		 */
		private function onScreenOut(e:Event):void
		{
			//Save Settings
			if (tracingSettings.needsSave)
				tracingSettings.save();
			if (loggingSettings.needsSave)
				loggingSettings.save();
		}
		
		override protected function onBackButtonTriggered(event:Event):void
		{
			//Pop Screen
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