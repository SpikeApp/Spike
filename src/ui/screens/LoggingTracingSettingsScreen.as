package ui.screens
{
	import flash.system.System;
	
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.settings.loggingtracing.LoggingSettingsList;
	import ui.screens.display.settings.loggingtracing.TracingSettingsList;
	
	import utilities.Constants;
	
	[ResourceBundle("logtracesettingsscreen")]

	public class LoggingTracingSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var loggingSettings:LoggingSettingsList;
		private var tracingSettings:TracingSettingsList;
		private var tracingLabel:Label;
		private var loggingLabel:Label;
		
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
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Tracing Section Label
			tracingLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('logtracesettingsscreen','trace_section_title'));
			screenRenderer.addChild(tracingLabel);
			
			//Tracing Settings
			tracingSettings = new TracingSettingsList();
			screenRenderer.addChild(tracingSettings);
			
			//Logging Section Label
			loggingLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('logtracesettingsscreen','nslog_section_title'), true);
			screenRenderer.addChild(loggingLabel);
			
			//Loging Settings
			loggingSettings = new LoggingSettingsList();
			screenRenderer.addChild(loggingSettings);
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
			//Save Settings
			if (tracingSettings.needsSave)
				tracingSettings.save();
			if (loggingSettings.needsSave)
				loggingSettings.save();
			
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
			//Pop Screen
			dispatchEventWith(Event.COMPLETE);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (loggingSettings != null)
			{
				loggingSettings.dispose();
				loggingSettings = null;
			}
			
			if (tracingSettings != null)
			{
				tracingSettings.dispose();
				tracingSettings = null;
			}
			
			if (tracingLabel != null)
			{
				tracingLabel.dispose();
				tracingLabel = null;
			}
			
			if (loggingLabel != null)
			{
				loggingLabel.dispose();
				loggingLabel = null;
			}
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);	
		}
		
		override protected function draw():void 
		{
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}