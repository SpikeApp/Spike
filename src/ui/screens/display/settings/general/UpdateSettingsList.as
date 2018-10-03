package ui.screens.display.settings.general
{
	import flash.display.StageOrientation;
	
	import mx.states.OverrideBase;
	
	import database.CommonSettings;
	import database.LocalSettings;
	
	import feathers.controls.DateTimeMode;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultGroupedListItemRenderer;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.data.AlarmNavigatorData;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.TimeSpan;
	
	[ResourceBundle("globaltranslations")]

	public class UpdateSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var updatesToggle:ToggleSwitch;
		private var quietTimeToggle:ToggleSwitch;
		private var quietTimeStartSelector:DateTimeSpinner;
		private var quietTimeEndSelector:DateTimeSpinner;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var updatesEnabled:Boolean;
		private var quietTimeEnabled:Boolean;
		private var quietTimeStartHour:Number;
		private var quietTimeStartMinutes:Number;
		private var quietTimeEndHour:Number;
		private var quietTimeEndMinutes:Number;
		
		public function UpdateSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupInitialState();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialState():void
		{
			updatesEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_CENTER_UPDATE_NOTIFICATIONS_ON) == "true";
			quietTimeEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_ENABLED) == "true";
			quietTimeStartHour = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_START_HOUR));
			quietTimeStartMinutes = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_START_MINUTES));
			quietTimeEndHour = Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_END_HOUR));
			quietTimeEndMinutes =  Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_END_MINUTES));
		}
		
		private function setupContent():void
		{
			///Notifications On/Off Toggle
			updatesToggle = LayoutFactory.createToggleSwitch(updatesEnabled);
			if(Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				updatesToggle.pivotX = -8;
			updatesToggle.addEventListener( Event.CHANGE, onUpdatesOnOff );
			
			//Quiet Time On/Off
			quietTimeToggle = LayoutFactory.createToggleSwitch(quietTimeEnabled);
			if(Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				quietTimeToggle.pivotX = -8;
			quietTimeToggle.addEventListener( Event.CHANGE, onQuietTimeOnOff );
			
			//Date Selectors
			
			var nowDate:Date = new Date();
			var startDate:Date = new Date (nowDate.fullYear, nowDate.month, nowDate.date, quietTimeStartHour, quietTimeStartMinutes, 0, 0);
			var endDate:Date = new Date (nowDate.fullYear, nowDate.month, nowDate.date, quietTimeEndHour, quietTimeEndMinutes, 0, 0);
			
			quietTimeStartSelector = new DateTimeSpinner();
			quietTimeStartSelector.editingMode = DateTimeMode.TIME;
			quietTimeStartSelector.locale = Constants.getUserLocale(true);
			quietTimeStartSelector.minimum = new Date(nowDate.fullYear, nowDate.month, nowDate.date, 0, 0);
			quietTimeStartSelector.maximum = new Date(nowDate.fullYear, nowDate.month, nowDate.date, 23, 58);
			quietTimeStartSelector.value = startDate;
			quietTimeStartSelector.height = 50;
			quietTimeStartSelector.addEventListener(Event.CHANGE, onStartTimeChanged);
			
			quietTimeEndSelector = new DateTimeSpinner();
			quietTimeEndSelector.editingMode = DateTimeMode.TIME;
			quietTimeEndSelector.locale = Constants.getUserLocale(true);
			quietTimeEndSelector.minimum = new Date(nowDate.fullYear, nowDate.month, nowDate.date, 0, 1);
			quietTimeEndSelector.maximum = new Date(nowDate.fullYear, nowDate.month, nowDate.date, 23, 59);
			quietTimeEndSelector.value = endDate;
			quietTimeEndSelector.height = 50;
			quietTimeEndSelector.addEventListener(Event.CHANGE, onEndTimeChanged);
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			//Define Notifications Settings Data
			var data:Array = [];
			
			data.push( { label: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled'), accessory: updatesToggle } );
			if (updatesEnabled)
			{
				data.push( { label: "Quiet Time Enabled", accessory: quietTimeToggle } );
			} 
			
			if (updatesEnabled && quietTimeEnabled)
			{
				data.push( { label: "Start", accessory: quietTimeStartSelector } );
				data.push( { label: "End", accessory: quietTimeEndSelector } );
			}
			
			dataProvider = new ArrayCollection(data);
		}
		
		public function save():void
		{
			if(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_CENTER_UPDATE_NOTIFICATIONS_ON) != String(updatesEnabled))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_APP_CENTER_UPDATE_NOTIFICATIONS_ON, String(updatesEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_ENABLED) != String(quietTimeEnabled))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_ENABLED, String(quietTimeEnabled));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_START_HOUR) != String(quietTimeStartHour))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_START_HOUR, String(quietTimeStartHour));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_START_MINUTES) != String(quietTimeStartMinutes))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_START_MINUTES, String(quietTimeStartMinutes));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_END_HOUR) != String(quietTimeEndHour))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_END_HOUR, String(quietTimeEndHour));
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_END_MINUTES) != String(quietTimeEndMinutes))
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_APP_CENTER_UPDATER_QUIET_TIME_END_MINUTES, String(quietTimeEndMinutes));
		}
		
		/**
		 * Event Handlers
		 */
		private function onUpdatesOnOff(event:Event):void
		{
			updatesEnabled = updatesToggle.isSelected;
			
			needsSave = true;
			
			refreshContent();
		}
		
		private function onQuietTimeOnOff(event:Event):void
		{
			quietTimeEnabled = quietTimeToggle.isSelected;
			
			needsSave = true;
			
			refreshContent();
		}
		
		private function onStartTimeChanged(e:Event):void
		{
			var startTimestamp:Number = quietTimeStartSelector.value.valueOf();
			var endDateTimestamp:Number = quietTimeEndSelector.value.valueOf();
			
			if (startTimestamp + TimeSpan.TIME_1_MINUTE > endDateTimestamp)
				quietTimeEndSelector.value = new Date(startTimestamp + TimeSpan.TIME_1_MINUTE);
			
			quietTimeStartHour = quietTimeStartSelector.value.hours;
			quietTimeStartMinutes = quietTimeStartSelector.value.minutes;
			
			needsSave = true
		}
		
		private function onEndTimeChanged(e:Event):void
		{
			var endDateTimestamp:Number = quietTimeEndSelector.value.valueOf();
			var startTimestamp:Number = quietTimeStartSelector.value.valueOf();
			
			if (endDateTimestamp <= startTimestamp)
				quietTimeStartSelector.value = new Date(endDateTimestamp - TimeSpan.TIME_1_MINUTE);
			
			quietTimeEndHour = quietTimeEndSelector.value.hours;
			quietTimeEndMinutes = quietTimeEndSelector.value.minutes;
			
			needsSave = true
		}
		
		/**
		 * Utility
		 */
		override protected function setupRenderFactory():void
		{
			/* List Item Renderer */
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				item.iconSourceField = "icon";
				item.accessoryLabelProperties.wordWrap = true;
				item.defaultLabelProperties.wordWrap = true;
				item.paddingTop = item.paddingBottom = 10;
				
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						item.paddingLeft = 30;
						if (noRightPadding) item.paddingRight = 0;
					}
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
						item.paddingRight = 30;
				}
				else
					if (noRightPadding) item.paddingRight = 0;
				
				return item;
			};
		}
		
		override protected function draw():void
		{
			if (layout != null)
			{
				(layout as VerticalLayout).hasVariableItemDimensions = true;
				(layout as VerticalLayout).useVirtualLayout = false;
			}
			
			super.draw();
		}
		
		override public function dispose():void
		{
			if(updatesToggle != null)
			{
				updatesToggle.removeFromParent();
				updatesToggle.removeEventListener( Event.CHANGE, onUpdatesOnOff );
				updatesToggle.dispose();
				updatesToggle = null;
			}
			
			if(quietTimeToggle != null)
			{
				quietTimeToggle.removeFromParent();
				quietTimeToggle.removeEventListener( Event.CHANGE, onQuietTimeOnOff );
				quietTimeToggle.dispose();
				quietTimeToggle = null;
			}
			
			if(quietTimeStartSelector != null)
			{
				quietTimeStartSelector.removeFromParent();
				quietTimeStartSelector.removeEventListener( Event.CHANGE, onStartTimeChanged );
				quietTimeStartSelector.dispose();
				quietTimeStartSelector = null;
			}
			
			if(quietTimeEndSelector != null)
			{
				quietTimeEndSelector.removeFromParent();
				quietTimeEndSelector.removeEventListener( Event.CHANGE, onEndTimeChanged );
				quietTimeEndSelector.dispose();
				quietTimeEndSelector = null;
			}
			
			super.dispose();
		}
	}
}