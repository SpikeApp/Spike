package ui.screens.display.settings.alarms
{
	import database.BlueToothDevice;
	import database.CommonSettings;
	import database.LocalSettings;
	
	import feathers.controls.List;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.layout.AnchorLayoutData;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.display.Image;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	import ui.screens.Screens;
	import ui.screens.data.AlarmNavigatorData;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	
	[ResourceBundle("alarmsettingsscreen")]

	public class AlarmsList extends List 
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
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
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
			
			/* Data */
			var dataSectionsContainer:Array = [];
			dataSectionsContainer.push({ screen: null, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"override_mute_label"), accessory: muteOverride, selectable:false });
			dataSectionsContainer.push({ screen: null, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"app_inactive_label"), accessory: appInactive, selectable:false });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALERT_TYPES_LIST, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"alert_types_label"), accessory: alertTypesIconImage });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"urgent_high_label"), accessory: urgentHighIconImage, alarmID: CommonSettings.COMMON_SETTING_VERY_HIGH_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_GLUCOSE });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"high_label"), accessory: highIconImage, alarmID: CommonSettings.COMMON_SETTING_HIGH_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_GLUCOSE });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"low_label"), accessory: lowIconImage, alarmID: CommonSettings.COMMON_SETTING_LOW_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_GLUCOSE });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"urgent_low_label"), accessory: urgentLowIconImage, alarmID: CommonSettings.COMMON_SETTING_VERY_LOW_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_GLUCOSE });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"calibration_label"), accessory: calibrationIconImage, alarmID: CommonSettings.COMMON_SETTING_CALIBRATION_REQUEST_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_CALIBRATION });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"missed_reading_label"), accessory: missedReadingIconImage, alarmID: CommonSettings.COMMON_SETTING_MISSED_READING_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_MISSED_READING });
			dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"phone_muted_label"), accessory: phoneMutedIconImage, alarmID: CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_PHONE_MUTED });
			if (!BlueToothDevice.isLimitter() && !BlueToothDevice.isFollower())
				dataSectionsContainer.push({ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"transmitter_low_battery_label"), accessory: batteryLowIconImage, alarmID: CommonSettings.COMMON_SETTING_BATTERY_ALERT, alarmType: AlarmNavigatorData.ALARM_TYPE_TRANSMITTER_LOW_BATTERY });
			
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
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
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
			if(highIconImage)
			{
				highIconImage.dispose();
				highIconImage = null;
			}
			if(urgentHighIconImage)
			{
				urgentHighIconImage.dispose();
				urgentHighIconImage = null;
			}
			
			super.dispose();
		}
	}
}