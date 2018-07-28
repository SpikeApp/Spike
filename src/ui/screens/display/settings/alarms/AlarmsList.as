package ui.screens.display.settings.alarms
{
	import flash.display.StageOrientation;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	import database.LocalSettings;
	
	import feathers.controls.Button;
	import feathers.controls.LayoutGroup;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.layout.AnchorLayoutData;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	import ui.popups.WorkflowConfigSender;
	import ui.screens.Screens;
	import ui.screens.data.AlarmNavigatorData;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("alarmsettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class AlarmsList extends SpikeList 
	{
		/* Display Objects */
		private var muteOverride:ToggleSwitch;
		private var appInactive:ToggleSwitch;
		private var chevronTexture:Texture;
		private var alertTypesIconImage:Image;
		private var batteryLowIconImage:Image;
		private var calibrationIconImage:Image;
		private var missedReadingIconImage:Image;
		private var phoneMutedIconImage:Image;
		private var urgentLowIconImage:Image;
		private var lowIconImage:Image;
		private var highIconImage:Image;
		private var urgentHighIconImage:Image;
		private var fastRiseIconImage:Image;
		private var fastDropIconImage:Image;
		private var widgetWatchConfigSender:Button;
		private var actionsContainer:LayoutGroup;
		
		/* Properties */
		private var muteOverrideValue:Boolean;
		private var appInactiveValue:Boolean;

		public function AlarmsList()
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupInitialContent();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			/* List Properties */
			clipContent = false;
			isSelectable = true;
			autoHideBackground = true;
			hasElasticEdges = false;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialContent():void
		{
			muteOverrideValue = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_OVERRIDE_MUTE) == "true";
			appInactiveValue = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APP_INACTIVE_ALERT) == "true";
		}
		
		private function setupContent():void
		{
			/* Controls & Icons */
			muteOverride = LayoutFactory.createToggleSwitch(muteOverrideValue);
			muteOverride.addEventListener(Event.CHANGE, onOverrideMute);
			appInactive = LayoutFactory.createToggleSwitch(appInactiveValue);
			appInactive.addEventListener(Event.CHANGE, onAppInactive);
			chevronTexture = MaterialDeepGreyAmberMobileThemeIcons.chevronRightTexture;
			alertTypesIconImage = new Image(chevronTexture);
			batteryLowIconImage = new Image(chevronTexture);
			calibrationIconImage = new Image(chevronTexture);
			missedReadingIconImage = new Image(chevronTexture);
			phoneMutedIconImage = new Image(chevronTexture);
			urgentLowIconImage = new Image(chevronTexture);
			lowIconImage = new Image(chevronTexture);
			highIconImage = new Image(chevronTexture);
			urgentHighIconImage = new Image(chevronTexture);
			fastRiseIconImage = new Image(chevronTexture);
			fastDropIconImage = new Image(chevronTexture);
			var actionsLayout:HorizontalLayout = new HorizontalLayout();
			actionsLayout.horizontalAlign = HorizontalAlign.CENTER;
			actionsContainer = new LayoutGroup();
			actionsContainer.layout = actionsLayout;
			actionsContainer.width = width - 20;
			widgetWatchConfigSender = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"email_configurations_label"));
			widgetWatchConfigSender.addEventListener(Event.TRIGGERED, onSendConfigurationFiles);
			actionsContainer.addChild(widgetWatchConfigSender);
			
			/* Data */
			var dataSectionsContainer:Array = [];
			dataSectionsContainer.push({ screen: null, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"override_mute_label"), accessory: muteOverride, selectable:false });
			dataSectionsContainer.push({ screen: null, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"app_inactive_label"), accessory: appInactive, selectable:false });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALERT_TYPES_LIST, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"alert_types_label"), accessory: alertTypesIconImage });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"fast_rise_label"), accessory: fastRiseIconImage, alarmID: CommonSettings.COMMON_SETTING_FAST_RISE_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_GLUCOSE_CHANGE });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"urgent_high_label"), accessory: urgentHighIconImage, alarmID: CommonSettings.COMMON_SETTING_VERY_HIGH_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_GLUCOSE });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"high_label"), accessory: highIconImage, alarmID: CommonSettings.COMMON_SETTING_HIGH_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_GLUCOSE });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"fast_drop_label"), accessory: fastDropIconImage, alarmID: CommonSettings.COMMON_SETTING_FAST_DROP_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_GLUCOSE_CHANGE });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"low_label"), accessory: lowIconImage, alarmID: CommonSettings.COMMON_SETTING_LOW_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_GLUCOSE });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"urgent_low_label"), accessory: urgentLowIconImage, alarmID: CommonSettings.COMMON_SETTING_VERY_LOW_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_GLUCOSE });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"calibration_label"), accessory: calibrationIconImage, alarmID: CommonSettings.COMMON_SETTING_CALIBRATION_REQUEST_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_CALIBRATION });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"missed_reading_label"), accessory: missedReadingIconImage, alarmID: CommonSettings.COMMON_SETTING_MISSED_READING_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_MISSED_READING });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"phone_muted_label"), accessory: phoneMutedIconImage, alarmID: CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_PHONE_MUTED });
			if (!CGMBlueToothDevice.isLimitter() && !CGMBlueToothDevice.isFollower())
				dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"transmitter_low_battery_label"), accessory: batteryLowIconImage, alarmID: CommonSettings.COMMON_SETTING_BATTERY_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_TRANSMITTER_LOW_BATTERY });
			dataSectionsContainer.push({ screen: null, label: "", accessory: actionsContainer, selectable:false });
			
			var dataContainer:ListCollection = new ListCollection(dataSectionsContainer);
			dataProvider = dataContainer;
			
			/* Renderer */
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				item.itemHasSelectable = true;
				item.selectableField = "selectable";	
				return item;
			};
			
			layoutData = new AnchorLayoutData( 0, 0, 0, 0 );
			
			/* Event Listeners */
			addEventListener( Event.CHANGE, onMenuChanged );
		}
		
		override protected function setupRenderFactory():void
		{
			/* List Item Renderer */
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				item.itemHasSelectable = true;
				item.selectableField = "selectable";
				item.accessoryLabelProperties.wordWrap = true;
				item.defaultLabelProperties.wordWrap = true;
				if (Constants.deviceModel == DeviceInfo.IPHONE_X && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
						item.paddingLeft = 30;
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
						item.paddingRight = 30;
				}
				return item;
			};
		}
		
		/**
		 * Event Listeners
		 */
		private function onOverrideMute(e:Event):void
		{
			if (muteOverride.isSelected)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_OVERRIDE_MUTE, "true");
			else
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_OVERRIDE_MUTE, "false");
		}
		
		private function onAppInactive(e:Event):void
		{
			if (appInactive.isSelected)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_APP_INACTIVE_ALERT, "true");
			else
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_APP_INACTIVE_ALERT, "false");
		}
		
		private function onMenuChanged(e:Event):void 
		{
			if(selectedItem.screen != null)
			{
				const screenName:String = selectedItem.screen as String;
				const alarmID:Number = selectedItem.alarmID as Number;
				const alarmLabel:String = selectedItem.label as String;
				const alarmType:String = selectedItem.alarmType as String;
				
				if(!isNaN(alarmID) && alarmLabel != "" && alarmLabel != null && alarmType != null)
				{
					AlarmNavigatorData.getInstance().alarmID = alarmID;
					AlarmNavigatorData.getInstance().alarmTitle = alarmLabel;
					AlarmNavigatorData.getInstance().alarmType = alarmType;
				}
				
				AppInterface.instance.navigator.pushScreen( screenName );
			}
		}
		
		private function onSendConfigurationFiles(e:Event):void
		{
			WorkflowConfigSender.displayWorkflowConfigSender(WorkflowConfigSender.WORKFLOW_ALARMS);
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (actionsContainer != null) actionsContainer.width = width - 20;
			
			setupRenderFactory();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if(muteOverride != null)
			{
				muteOverride.removeEventListener(Event.CHANGE, onOverrideMute);
				muteOverride.dispose();
				muteOverride = null;
			}
			if(appInactive != null)
			{
				appInactive.removeEventListener(Event.CHANGE, onAppInactive);
				appInactive.dispose();
				appInactive = null;
			}
			if (chevronTexture != null)
			{
				chevronTexture.dispose();
				chevronTexture = null;
			}
			if (alertTypesIconImage != null)
			{
				alertTypesIconImage.dispose();
				alertTypesIconImage = null;
			}
			if(batteryLowIconImage != null)
			{
				batteryLowIconImage.dispose();
				batteryLowIconImage = null;
			}
			if(calibrationIconImage != null)
			{
				calibrationIconImage.dispose();
				calibrationIconImage = null;
			}
			if(missedReadingIconImage != null)
			{
				missedReadingIconImage.dispose();
				missedReadingIconImage = null;
			}
			if(phoneMutedIconImage != null)
			{
				phoneMutedIconImage.dispose();
				phoneMutedIconImage = null;
			}
			if(urgentLowIconImage != null)
			{
				urgentLowIconImage.dispose();
				urgentLowIconImage = null;
			}
			if(lowIconImage != null)
			{
				lowIconImage.dispose();
				lowIconImage = null;
			}
			if(highIconImage != null)
			{
				highIconImage.dispose();
				highIconImage = null;
			}
			if(urgentHighIconImage != null)
			{
				urgentHighIconImage.dispose();
				urgentHighIconImage = null;
			}
			if(fastRiseIconImage != null)
			{
				fastRiseIconImage.dispose();
				fastRiseIconImage = null;
			}
			if(fastDropIconImage != null)
			{
				fastDropIconImage.dispose();
				fastDropIconImage = null;
			}
			if(widgetWatchConfigSender != null)
			{
				widgetWatchConfigSender.removeEventListener(Event.TRIGGERED, onSendConfigurationFiles);
				widgetWatchConfigSender.removeFromParent();
				widgetWatchConfigSender.dispose();
				widgetWatchConfigSender = null;
			}
			if(actionsContainer != null)
			{
				actionsContainer.dispose();
				actionsContainer = null;
			}
			
			super.dispose();
		}
	}
}