package ui.screens
{
	import flash.display.StageOrientation;
	import flash.system.System;
	
	import database.CGMBlueToothDevice;
	
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.settings.chart.ColorSettingsList;
	import ui.screens.display.settings.chart.GlucoseDistributionSettingsList;
	import ui.screens.display.settings.chart.ModeSettingsList;
	import ui.screens.display.settings.chart.SizeSettingsList;
	import ui.screens.display.settings.chart.VisualizationSettingsList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("chartsettingsscreen")]

	public class ChartSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var chartColorSettings:ColorSettingsList;
		private var chartSizeSettings:SizeSettingsList;
		private var chartGlucoseDistributionSettings:GlucoseDistributionSettingsList;
		private var chartColorLabel:Label;
		private var chartSizeLabel:Label;
		private var chartGlucoseDistributionLabel:Label;
		private var chartModeLabel:Label;
		private var chartModeSettings:ModeSettingsList;
		private var chartVisualizationLabel:Label;
		private var chartVisualizationSettings:VisualizationSettingsList;
		
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
			
			//24H Distribution Section Label
			if (!CGMBlueToothDevice.isFollower())
				chartGlucoseDistributionLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','statistics_settings_title_master'), true);
			else
				chartGlucoseDistributionLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','statistics_settings_title_follower'), true);
			screenRenderer.addChild(chartGlucoseDistributionLabel);
			
			//24H Distribution Settings
			chartGlucoseDistributionSettings = new GlucoseDistributionSettingsList();
			screenRenderer.addChild(chartGlucoseDistributionSettings);
			
			//Mode Section Label
			chartModeLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','resize_mode_settings_title'), true);
			screenRenderer.addChild(chartModeLabel);
			
			//Mode Settings
			chartModeSettings = new ModeSettingsList();
			screenRenderer.addChild(chartModeSettings);
			
			//Visualization Section Label
			chartVisualizationLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','visualization_section_label'), true);
			screenRenderer.addChild(chartVisualizationLabel);
			
			//Visualization Settings
			chartVisualizationSettings = new VisualizationSettingsList();
			screenRenderer.addChild(chartVisualizationSettings);
			
			//Size Section Label
			chartSizeLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','size_settings_title'), true);
			screenRenderer.addChild(chartSizeLabel);
			
			//Size Settings
			chartSizeSettings = new SizeSettingsList();
			screenRenderer.addChild(chartSizeSettings);
			
			//Colors Section Label
			chartColorLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','chart_colors_settings_title'));
			screenRenderer.addChild(chartColorLabel);
			
			//Colors Settings
			chartColorSettings = new ColorSettingsList(this);
			screenRenderer.addChild(chartColorSettings);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 4 : 3;
		}
		
		/**
		 * Event Handlers
		 */
		override protected function onBackButtonTriggered(event:Event):void
		{
			//Save Settings
			if (chartModeSettings.needsSave)
				chartModeSettings.save();
			if (chartVisualizationSettings.needsSave)
				chartVisualizationSettings.save();
			if (chartColorSettings.needsSave)
				chartColorSettings.save();
			if (chartSizeSettings.needsSave)
				chartSizeSettings.save();
			if (chartGlucoseDistributionSettings.needsSave)
				chartGlucoseDistributionSettings.save();
			
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
			dispatchEventWith(Event.COMPLETE);
		}

		override protected function onTransitionInComplete(e:Event):void
		{
			//Swipe to pop functionality
			AppInterface.instance.navigator.isSwipeToPopEnabled = true;
		}
		
		override protected function onStarlingBaseResize(e:ResizeEvent):void 
		{
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait && Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
			{
				if (chartGlucoseDistributionLabel != null) chartGlucoseDistributionLabel.paddingLeft = 30;
				if (chartModeLabel != null) chartModeLabel.paddingLeft = 30;
				if (chartVisualizationLabel != null) chartVisualizationLabel.paddingLeft = 30;
				if (chartSizeLabel != null) chartSizeLabel.paddingLeft = 30;
				if (chartColorLabel != null) chartColorLabel.paddingLeft = 30;
			}
			else
			{
				if (chartGlucoseDistributionLabel != null) chartGlucoseDistributionLabel.paddingLeft = 0;
				if (chartModeLabel != null) chartModeLabel.paddingLeft = 0;
				if (chartVisualizationLabel != null) chartVisualizationLabel.paddingLeft = 0;
				if (chartSizeLabel != null) chartSizeLabel.paddingLeft = 0;
				if (chartColorLabel != null) chartColorLabel.paddingLeft = 0;
			}
			
			setupHeaderSize();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (chartColorSettings != null)
			{
				chartColorSettings.removeFromParent();
				chartColorSettings.dispose();
				chartColorSettings = null;
			}
			
			if (chartSizeSettings != null)
			{
				chartSizeSettings.removeFromParent();
				chartSizeSettings.dispose();
				chartSizeSettings = null;
			}
			
			if (chartGlucoseDistributionSettings != null)
			{
				chartGlucoseDistributionSettings.removeFromParent();
				chartGlucoseDistributionSettings.dispose();
				chartGlucoseDistributionSettings = null;
			}
			
			if (chartColorLabel != null)
			{
				chartColorLabel.removeFromParent();
				chartColorLabel.dispose();
				chartColorLabel = null;
			}
			
			if (chartSizeLabel != null)
			{
				chartSizeLabel.removeFromParent();
				chartSizeLabel.dispose();
				chartSizeLabel = null;
			}
			
			if (chartGlucoseDistributionLabel != null)
			{
				chartGlucoseDistributionLabel.removeFromParent();
				chartGlucoseDistributionLabel.dispose();
				chartGlucoseDistributionLabel = null;
			}
			
			if (chartModeLabel != null)
			{
				chartModeLabel.removeFromParent();
				chartModeLabel.dispose();
				chartModeLabel = null;
			}
			
			if (chartModeSettings != null)
			{
				chartModeSettings.removeFromParent();
				chartModeSettings.dispose();
				chartModeSettings = null;
			}
			
			if (chartVisualizationLabel != null)
			{
				chartVisualizationLabel.removeFromParent();
				chartVisualizationLabel.dispose();
				chartVisualizationLabel = null;
			}
			
			if (chartVisualizationSettings != null)
			{
				chartVisualizationSettings.removeFromParent();
				chartVisualizationSettings.dispose();
				chartVisualizationSettings = null;
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