package display.settings.alarms
{
	import flash.system.System;
	
	import data.AlarmNavigatorData;
	
	import display.LayoutFactory;
	
	import feathers.controls.List;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.layout.AnchorLayoutData;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import screens.Screens;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import ui.AppInterface;
	
	import utils.Constants;

	public class AlarmsList extends List 
	{
		/* Display Objects */
		private var muteOverride:ToggleSwitch;
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
		
		public function AlarmsList()
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			/* List Properties */
			clipContent = false;
			isSelectable = true;
			autoHideBackground = true;
			hasElasticEdges = false;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			/* Controls & Icons */
			muteOverride = LayoutFactory.createToggleSwitch(false);
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
			
			dataProvider = new ListCollection(
				[
					{ screen: null, label: "Override Mute", accessory: muteOverride, selectable:false },
					{ screen: Screens.SETTINGS_ALERT_TYPE_CUSTOMIZER, label: "Alert Types", accessory: alertTypesIconImage },
					{ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: "Battery Low", accessory: batteryLowIconImage, alarmType: AlarmNavigatorData.BATTERY_LOW },
					{ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: "Calibration", accessory: calibrationIconImage, alarmType: AlarmNavigatorData.CALIBRATION },
					{ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: "Missed Reading", accessory: missedReadingIconImage, alarmType: AlarmNavigatorData.MISSED_READING },
					{ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: "Phone Muted", accessory: phoneMutedIconImage, alarmType: AlarmNavigatorData.PHONE_MUTED },
					{ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: "Urgent Low", accessory: urgentLowIconImage, alarmType: AlarmNavigatorData.URGENT_LOW },
					{ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: "Low", accessory: lowIconImage, alarmType: AlarmNavigatorData.LOW },
					{ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: "High", accessory: highIconImage, alarmType: AlarmNavigatorData.HIGH },
					{ screen: Screens.SETTINGS_ALARMS_CUSTOMIZER, label: "Urgent High", accessory: urgentHighIconImage, alarmType: AlarmNavigatorData.URGENT_HIGH },
				]);
			
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
			addEventListener( Event.CHANGE, onMenuChanged );
		}
		
		private function onMenuChanged(e:Event):void 
		{
			if(selectedItem.screen != null)
			{
				const screenName:String = selectedItem.screen as String;
				const alarmType:String = selectedItem.alarmType as String;
				const alarmLabel:String = selectedItem.label as String;
				
				if(alarmType != null)
				{
					AlarmNavigatorData.getInstance().selectedAlarm = alarmType;
					AlarmNavigatorData.getInstance().selectedAlarmTitle = alarmLabel;
				}
				
				AppInterface.instance.navigator.pushScreen( screenName );
			}
		}
		
		override public function dispose():void
		{
			if(muteOverride != null)
			{
				muteOverride.dispose();
				muteOverride = null;
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
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}