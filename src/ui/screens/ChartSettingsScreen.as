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
	import ui.screens.display.settings.chart.ColorSettingsList;
	import ui.screens.display.settings.chart.DateSettingsList;
	import ui.screens.display.settings.chart.GlucoseDistributionSettingsList;
	import ui.screens.display.settings.chart.SizeSettingsList;
	
	import utils.Constants;
	
	[ResourceBundle("chartsettingsscreen")]

	public class ChartSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var chartDateSettings:DateSettingsList;
		private var chartColorSettings:ColorSettingsList;
		private var chartSizeSettings:SizeSettingsList;
		private var chartGlucoseDistributionSettings:GlucoseDistributionSettingsList;
		private var chartDateFormatLabel:Label;
		private var chartColorLabel:Label;
		private var chartSizeLabel:Label;
		private var chartGlucoseDistributionLabel:Label;
		
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
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//Time Format Section Label
			chartDateFormatLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','chart_date_settings_title'), true);
			screenRenderer.addChild(chartDateFormatLabel);
			
			//Display Settings
			chartDateSettings = new DateSettingsList();
			screenRenderer.addChild(chartDateSettings);
			
			//Colors Section Label
			chartColorLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','chart_colors_settings_title'));
			screenRenderer.addChild(chartColorLabel);
			
			//Colors Settings
			chartColorSettings = new ColorSettingsList(this);
			screenRenderer.addChild(chartColorSettings);
			
			//Size Section Label
			chartSizeLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','size_settings_title'), true);
			screenRenderer.addChild(chartSizeLabel);
			
			//Size Settings
			chartSizeSettings = new SizeSettingsList();
			screenRenderer.addChild(chartSizeSettings);
			
			//Display Section Label
			chartGlucoseDistributionLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','glucose_distribution_settings_title'), true);
			screenRenderer.addChild(chartGlucoseDistributionLabel);
			
			//Display Settings
			chartGlucoseDistributionSettings = new GlucoseDistributionSettingsList();
			screenRenderer.addChild(chartGlucoseDistributionSettings);
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
			if (chartColorSettings.needsSave)
				chartColorSettings.save();
			if (chartSizeSettings.needsSave)
				chartSizeSettings.save();
			if (chartGlucoseDistributionSettings.needsSave)
				chartGlucoseDistributionSettings.save();
			if (chartDateSettings.needsSave)
				chartDateSettings.save();
			
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
			dispatchEventWith(Event.COMPLETE);
		}

		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
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
			
			if (chartGlucoseDistributionSettings != null)
			{
				chartGlucoseDistributionSettings.dispose();
				chartGlucoseDistributionSettings = null;
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
			
			if (chartGlucoseDistributionLabel != null)
			{
				chartGlucoseDistributionLabel.dispose();
				chartGlucoseDistributionLabel = null;
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