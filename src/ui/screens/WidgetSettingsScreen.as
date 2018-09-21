package ui.screens
{
	import flash.display.StageOrientation;
	import flash.system.System;
	
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
	import ui.screens.display.settings.widget.ChartSettingsList;
	import ui.screens.display.settings.widget.ColorSettingsList;
	import ui.screens.display.settings.widget.HistorySettingsList;
	import ui.screens.display.settings.widget.SizeSettingsList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("widgetsettingsscreen")]

	public class WidgetSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var chartColorSettings:ColorSettingsList;
		private var chartColorLabel:Label;
		private var historySettings:HistorySettingsList;
		private var historyLabel:Label;
		private var chartSettingsLabel:Label;
		private var chartSettings:ChartSettingsList;
		private var sizeSettingsLabel:Label;
		private var sizeSettings:SizeSettingsList;
		
		public function WidgetSettingsScreen() 
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
			title = ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','screen_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.widgetTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//History Label
			historyLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','chart_history_settings_title'));
			screenRenderer.addChild(historyLabel);
			
			//History Settings
			historySettings = new HistorySettingsList();
			screenRenderer.addChild(historySettings);
			
			//Chart Settings Label
			chartSettingsLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','chart_settings_title'));
			screenRenderer.addChild(chartSettingsLabel);
			
			//Chart Settings
			chartSettings = new ChartSettingsList();
			screenRenderer.addChild(chartSettings);
			
			//Size Settings Label
			sizeSettingsLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','chart_size_settings_title'));
			screenRenderer.addChild(sizeSettingsLabel);
			
			//Size Settings
			sizeSettings = new SizeSettingsList();
			screenRenderer.addChild(sizeSettings);
			
			//Colors Section Label
			chartColorLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','chart_colors_settings_title'));
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
			if (historySettings.needsSave)
				historySettings.save();
			if (chartSettings.needsSave)
				chartSettings.save();
			if (sizeSettings.needsSave)
				sizeSettings.save();
			if (chartColorSettings.needsSave)
				chartColorSettings.save();
			
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
				if (historyLabel != null) historyLabel.paddingLeft = 30;
				if (chartSettingsLabel != null) chartSettingsLabel.paddingLeft = 30;
				if (sizeSettingsLabel != null) sizeSettingsLabel.paddingLeft = 30;
				if (chartColorLabel != null) chartColorLabel.paddingLeft = 30;
			}
			else
			{
				if (historyLabel != null) historyLabel.paddingLeft = 0;
				if (chartSettingsLabel != null) chartSettingsLabel.paddingLeft = 0;
				if (sizeSettingsLabel != null) sizeSettingsLabel.paddingLeft = 0;
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
			
			if (chartColorLabel != null)
			{
				chartColorLabel.removeFromParent();
				chartColorLabel.dispose();
				chartColorLabel = null;
			}
			
			if (historySettings != null)
			{
				historySettings.removeFromParent();
				historySettings.dispose();
				historySettings = null;
			}
			
			if (historyLabel != null)
			{
				historyLabel.removeFromParent();
				historyLabel.dispose();
				historyLabel = null;
			}
			
			if (chartSettingsLabel != null)
			{
				chartSettingsLabel.removeFromParent();
				chartSettingsLabel.dispose();
				chartSettingsLabel = null;
			}
			
			if (chartSettings != null)
			{
				chartSettings.removeFromParent();
				chartSettings.dispose();
				chartSettings = null;
			}
			
			if (sizeSettingsLabel != null)
			{
				sizeSettingsLabel.removeFromParent();
				sizeSettingsLabel.dispose();
				sizeSettingsLabel = null;
			}
			
			if (sizeSettings != null)
			{
				sizeSettings.removeFromParent();
				sizeSettings.dispose();
				sizeSettings = null;
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