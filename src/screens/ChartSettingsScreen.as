package screens
{
	import flash.system.System;
	
	import display.LayoutFactory;
	import display.settings.chart.ChartColorSettingsList;
	import display.settings.chart.ChartDateSettingsList;
	import display.settings.chart.ChartDisplaySettingsList;
	import display.settings.chart.ChartSizeSettingsList;
	
	import events.ScreenEvent;
	
	import feathers.controls.Label;
	import feathers.events.FeathersEventType;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;
	
	[ResourceBundle("chartsettingsscreen")]

	public class ChartSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var chartDateSettings:ChartDateSettingsList;
		private var chartColorSettings:ChartColorSettingsList;
		private var chartSizeSettings:ChartSizeSettingsList;
		private var chartDisplaySettings:ChartDisplaySettingsList;
		private var chartDateFormatLabel:Label;
		private var chartColorLabel:Label;
		private var chartSizeLabel:Label;
		private var chartDisplayLabel:Label;
		
		public function ChartSettingsScreen() 
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
			title = ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','chart_settings_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.timelineTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Time Format Section Label
			chartDateFormatLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','chart_date_settings_title'), true);
			screenRenderer.addChild(chartDateFormatLabel);
			
			//Display Settings
			chartDateSettings = new ChartDateSettingsList();
			screenRenderer.addChild(chartDateSettings);
			
			//Colors Section Label
			chartColorLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','chart_colors_settings_title'));
			screenRenderer.addChild(chartColorLabel);
			
			//Colors Settings
			chartColorSettings = new ChartColorSettingsList(this);
			screenRenderer.addChild(chartColorSettings);
			
			//Size Section Label
			chartSizeLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','size_settings_title'), true);
			screenRenderer.addChild(chartSizeLabel);
			
			//Size Settings
			chartSizeSettings = new ChartSizeSettingsList();
			screenRenderer.addChild(chartSizeSettings);
			
			//Display Section Label
			chartDisplayLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','display_settings_title'), true);
			screenRenderer.addChild(chartDisplayLabel);
			
			//Display Settings
			chartDisplaySettings = new ChartDisplaySettingsList();
			screenRenderer.addChild(chartDisplaySettings);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 3;
		}
		
		private function setupEventHandlers():void
		{
			addEventListener(FeathersEventType.TRANSITION_OUT_COMPLETE, onScreenOut);
			AppInterface.instance.menu.addEventListener(ScreenEvent.BEGIN_SWITCH, onScreenOut);
		}
		
		/**
		 * Event Handlers
		 */
		private function onScreenOut(e:Event):void
		{
			//Save Settings
			if (chartColorSettings.needsSave)
				chartColorSettings.save();
			if (chartSizeSettings.needsSave)
				chartSizeSettings.save();
			if (chartDisplaySettings.needsSave)
				chartDisplaySettings.save();
			if (chartDateSettings.needsSave)
				chartDateSettings.save();
		}
		
		override protected function onBackButtonTriggered(event:Event):void
		{
			dispatchEventWith(Event.COMPLETE);
		}

		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			removeEventListener(FeathersEventType.TRANSITION_OUT_COMPLETE, onScreenOut);
			AppInterface.instance.menu.removeEventListener(ScreenEvent.BEGIN_SWITCH, onScreenOut);
			
			if (chartDateSettings != null)
			{
				chartDateSettings.dispose();
				chartDateSettings = null;
			}
			
			if (chartColorSettings != null)
			{
				chartColorSettings.dispose();
				chartColorSettings = null;
			}
			
			if (chartSizeSettings != null)
			{
				chartSizeSettings.dispose();
				chartSizeSettings = null;
			}
			
			if (chartDisplaySettings != null)
			{
				chartDisplaySettings.dispose();
				chartDisplaySettings = null;
			}
			
			if (chartDateFormatLabel != null)
			{
				chartDateFormatLabel.dispose();
				chartDateFormatLabel = null;
			}
			
			if (chartColorLabel != null)
			{
				chartColorLabel.dispose();
				chartColorLabel = null;
			}
			
			if (chartSizeLabel != null)
			{
				chartSizeLabel.dispose();
				chartSizeLabel = null;
			}
			
			if (chartDisplayLabel != null)
			{
				chartDisplayLabel.dispose();
				chartDisplayLabel = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
		
		override protected function draw():void 
		{
			var layoutInvalid:Boolean = isInvalid( INVALIDATION_FLAG_LAYOUT );
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}