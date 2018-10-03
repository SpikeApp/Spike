package ui.screens.display.settings.alarms
{
	import com.adobe.utils.StringUtil;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import database.AlertType;
	import database.Database;
	import database.LocalSettings;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.Check;
	import feathers.controls.LayoutGroup;
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.popups.VerticalCenteredPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.core.PopUpManager;
	import feathers.data.ArrayCollection;
	import feathers.data.ListCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.AnchorLayoutData;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.events.Event;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.TimeSpan;
	
	[ResourceBundle("alertsettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class AlertCustomizerList extends List 
	{
		/* Constants */
		public static const ALERT_NAMES_LIST:String = "No Sound,Alarm Buzzer,Alarm Clock,Alert Tone Busy,Alert Tone Ringtone 1,Alert Tone Ringtone 2,Alien Siren,Ambulance,Analog Watch Alarm,Big Clock Ticking,Burglar Alarm Siren 1,Burglar Alarm Siren 2,Cartoon Ascend Climb Sneaky,Cartoon Ascend Then Descend,Cartoon Bounce To Ceiling,Cartoon Dreamy Glissando Harp,Cartoon Fail Strings Trumpet,Cartoon Machine Clumsy Loop,Cartoon Siren,Cartoon Tip Toe Sneaky Walk,Cartoon Uh Oh,Cartoon Villain Horns,Cell Phone Ring Tone,Chimes Glassy,Computer Magic,CSFX-2 Alarm,Cuckoo Clock,Dhol Shuffleloop,Discreet,Early Sunrise,Emergency Alarm Carbon,Emergency Alarm Siren,Emergency Alarm,Ending Reached,Fly,Ghost Hover,Good Morning,Hell Yeah Somewhat Calmer,In A Hurry,Indeed,Insistently,Jingle All The Way,Laser Shoot,Machine Charge,Magical Twinkle,Marching Fat Elephants,Marimba Descend,Marimba Flutter or Shake,Martian Gun,Martian Scanner,Metallic,Nightguard,Not Kiddin,Open Your Eyes And See,Orchestral Horns,Oringz,Pager Beeps,Remembers Me Of Asia,Rise And Shine,Rush,Sci-Fi Air Raid Alarm,Sci-Fi Alarm Loop 1,Sci-Fi Alarm Loop 2,Sci-Fi Alarm Loop 3,Sci-Fi Alarm Loop 4,Sci-Fi Alarm,Sci-Fi Computer Console Alarm,Sci-Fi Console Alarm,Sci-Fi Eerie Alarm,Sci-Fi Engine Shut Down,Sci-Fi Incoming Message Alert,Sci-Fi Spaceship Message,Sci-Fi Spaceship Warm Up,Sci-Fi Warning,Signature Corporate,Siri Alert Calibration Needed,Siri Alert Device Muted,Siri Alert Glucose Dropping Fast,Siri Alert Glucose Rising Fast,Siri Alert High Glucose,Siri Alert Low Glucose,Siri Alert Missed Readings,Siri Alert Transmitter Battery Low,Siri Alert Urgent High Glucose,Siri Alert Urgent Low Glucose,Siri Calibration Needed,Siri Device Muted,Siri Glucose Dropping Fast,Siri Glucose Rising Fast,Siri High Glucose,Siri Low Glucose,Siri Missed Readings,Siri Transmitter Battery Low,Siri Urgent High Glucose,Siri Urgent Low Glucose,Soft Marimba Pad Positive,Soft Warm Airy Optimistic,Soft Warm Airy Reassuring,Store Door Chime,Sunny,Thunder Sound FX,Time Has Come,Tornado Siren,Two Turtle Doves,Unpaved,Wake Up Will You,Win Gain,Wrong Answer";
		public static const ALERT_SOUNDS_LIST:String = "no_sound,Alarm_Buzzer.caf,Alarm_Clock.caf,Alert_Tone_Busy.caf,Alert_Tone_Ringtone_1.caf,Alert_Tone_Ringtone_2.caf,Alien_Siren.caf,Ambulance.caf,Analog_Watch_Alarm.caf,Big_Clock_Ticking.caf,Burglar_Alarm_Siren_1.caf,Burglar_Alarm_Siren_2.caf,Cartoon_Ascend_Climb_Sneaky.caf,Cartoon_Ascend_Then_Descend.caf,Cartoon_Bounce_To_Ceiling.caf,Cartoon_Dreamy_Glissando_Harp.caf,Cartoon_Fail_Strings_Trumpet.caf,Cartoon_Machine_Clumsy_Loop.caf,Cartoon_Siren.caf,Cartoon_Tip_Toe_Sneaky_Walk.caf,Cartoon_Uh_Oh.caf,Cartoon_Villain_Horns.caf,Cell_Phone_Ring_Tone.caf,Chimes_Glassy.caf,Computer_Magic.caf,CSFX-2_Alarm.caf,Cuckoo_Clock.caf,Dhol_Shuffleloop.caf,Discreet.caf,Early_Sunrise.caf,Emergency_Alarm_Carbon_Monoxide.caf,Emergency_Alarm_Siren.caf,Emergency_Alarm.caf,Ending_Reached.caf,Fly.caf,Ghost_Hover.caf,Good_Morning.caf,Hell_Yeah_Somewhat_Calmer.caf,In_A_Hurry.caf,Indeed.caf,Insistently.caf,Jingle_All_The_Way.caf,Laser_Shoot.caf,Machine_Charge.caf,Magical_Twinkle.caf,Marching_Heavy_Footed_Fat_Elephants.caf,Marimba_Descend.caf,Marimba_Flutter_or_Shake.caf,Martian_Gun.caf,Martian_Scanner.caf,Metallic.caf,Nightguard.caf,Not_Kiddin.caf,Open_Your_Eyes_And_See.caf,Orchestral_Horns.caf,Oringz.caf,Pager_Beeps.caf,Remembers_Me_Of_Asia.caf,Rise_And_Shine.caf,Rush.caf,Sci-Fi_Air_Raid_Alarm.caf,Sci-Fi_Alarm_Loop_1.caf,Sci-Fi_Alarm_Loop_2.caf,Sci-Fi_Alarm_Loop_3.caf,Sci-Fi_Alarm_Loop_4.caf,Sci-Fi_Alarm.caf,Sci-Fi_Computer_Console_Alarm.caf,Sci-Fi_Console_Alarm.caf,Sci-Fi_Eerie_Alarm.caf,Sci-Fi_Engine_Shut_Down.caf,Sci-Fi_Incoming_Message_Alert.caf,Sci-Fi_Spaceship_Message.caf,Sci-Fi_Spaceship_Warm_Up.caf,Sci-Fi_Warning.caf,Signature_Corporate.caf,Siri_Alert_Calibration_Needed.caf,Siri_Alert_Device_Muted.caf,Siri_Alert_Glucose_Dropping_Fast.caf,Siri_Alert_Glucose_Rising_Fast.caf,Siri_Alert_High_Glucose.caf,Siri_Alert_Low_Glucose.caf,Siri_Alert_Missed_Readings.caf,Siri_Alert_Transmitter_Battery_Low.caf,Siri_Alert_Urgent_High_Glucose.caf,Siri_Alert_Urgent_Low_Glucose.caf,Siri_Calibration_Needed.caf,Siri_Device_Muted.caf,Siri_Glucose_Dropping_Fast.caf,Siri_Glucose_Rising_Fast.caf,Siri_High_Glucose.caf,Siri_Low_Glucose.caf,Siri_Missed_Readings.caf,Siri_Transmitter_Battery_Low.caf,Siri_Urgent_High_Glucose.caf,Siri_Urgent_Low_Glucose.caf,Soft_Marimba_Pad_Positive.caf,Soft_Warm_Airy_Optimistic.caf,Soft_Warm_Airy_Reassuring.caf,Store_Door_Chime.caf,Sunny.caf,Thunder_Sound_FX.caf,Time_Has_Come.caf,Tornado_Siren.caf,Two_Turtle_Doves.caf,Unpaved.caf,Wake_Up_Will_You.caf,Win_Gain.caf,Wrong_Answer.caf";
		
		/* Display Objects */
		private var alertName:TextInput;
		private var enableSnoozeInNotification:Check;
		private var snoozeMinutes:NumericStepper;
		private var enableRepeat:Check;
		private var enableVibration:Check;
		private var soundList:PickerList;
		private var saveAlert:Button;
		private var alertEnabled:ToggleSwitch;
		private var cancelAlert:Button;
		private var actionButtonsContainer:LayoutGroup;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var soundName:String;
		private var repeatInMinutes:int = 0;
		private var selectedAlertType:AlertType;
		private var mode:String;
		private var alertEnabledSwitchStateValue:Boolean;
		private var alertNameValue:String;
		private var enableSnoozeInNotificationValue:Boolean;
		private var snoozeMinutesValue:int;
		private var enableRepeatValue:Boolean;
		private var enableVibrationValue:Boolean;
		private var soundAccessoriesList:Array;
		private var alertTypesList:Array;
		private var previousAlertName:String;
		private var selectedSoundNameValue:String;
		private var alertTypeUniqueID:String;
		
		public function AlertCustomizerList(selectedAlertType:AlertType)
		{
			this.selectedAlertType = selectedAlertType;
			
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
			/* Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			width = 300;
		}
		
		private function setupInitialContent():void
		{
			/* Get All Current Alert Types */
			alertTypesList = Database.getAlertTypesList();
			
			/* Setup Initial Values */
			if (selectedAlertType == null)
			{
				mode = "add";
				alertEnabledSwitchStateValue = true;
				alertNameValue = "";
				enableSnoozeInNotificationValue = false;
				snoozeMinutesValue = 5;
				enableRepeatValue = false;
				enableVibrationValue = false;
				previousAlertName = "";
				selectedSoundNameValue = "";
				alertTypeUniqueID = null;
			}
			else
			{
				mode = "edit";
				alertEnabledSwitchStateValue = selectedAlertType.enabled;
				alertNameValue = selectedAlertType.alarmName;
				enableSnoozeInNotificationValue = selectedAlertType.snoozeFromNotification;
				snoozeMinutesValue = selectedAlertType.defaultSnoozePeriodInMinutes;
				enableRepeatValue = selectedAlertType.repeatInMinutes == TimeSpan.TIME_5_MINUTES;
				enableVibrationValue = selectedAlertType.enableVibration;
				previousAlertName = selectedAlertType.alarmName;
				selectedSoundNameValue = selectedAlertType.sound;
				alertTypeUniqueID = selectedAlertType.uniqueId;
			}
		}
		
		private function setupContent():void
		{
			/* Create Controls */
			alertEnabled = LayoutFactory.createToggleSwitch(alertEnabledSwitchStateValue);
			alertEnabled.addEventListener(Event.CHANGE, onSettingsChanged);
			
			alertName = LayoutFactory.createTextInput(false, false, 120, HorizontalAlign.RIGHT);
			alertName.text = alertNameValue;
			alertName.addEventListener(Event.CHANGE, onSettingsChanged);
			alertName.addEventListener( FeathersEventType.ENTER, onTextInputEnter );
			
			enableSnoozeInNotification = LayoutFactory.createCheckMark(enableSnoozeInNotificationValue);
			enableSnoozeInNotification.addEventListener(Event.CHANGE, onSettingsChanged);
			
			snoozeMinutes = LayoutFactory.createNumericStepper(0, 9999, snoozeMinutesValue);
			snoozeMinutes.pivotX = -12;
			snoozeMinutes.addEventListener(Event.CHANGE, onSettingsChanged);
			
			enableRepeat = LayoutFactory.createCheckMark(enableRepeatValue);
			enableRepeat.addEventListener(Event.CHANGE, onSettingsChanged);
			
			enableVibration = LayoutFactory.createCheckMark(enableVibrationValue);
			enableVibration.addEventListener(Event.CHANGE, onSettingsChanged);
			
			soundList = LayoutFactory.createPickerList();
			var soundListPopUp:VerticalCenteredPopUpContentManager = new VerticalCenteredPopUpContentManager();
			soundListPopUp.margin = 20;
			soundList.popUpContentManager = soundListPopUp;
			soundList.pivotX = -3;
			soundList.maxWidth = 200;
			soundList.addEventListener(Event.CLOSE, onSoundListClose);
			
			/* Action Buttons */
			//Action buttons container & layout
			var actionButtonsLayout:HorizontalLayout = new HorizontalLayout();
			actionButtonsLayout.gap = 5;
			
			actionButtonsContainer = new LayoutGroup();
			actionButtonsContainer.layout = actionButtonsLayout;
			actionButtonsContainer.pivotX = -3;
			
			//Buttons
			cancelAlert = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"cancel_button_label"), false, MaterialDeepGreyAmberMobileThemeIcons.cancelTexture);
			cancelAlert.addEventListener(Event.TRIGGERED, onCancel);
			actionButtonsContainer.addChild(cancelAlert);
			
			saveAlert = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"save_button_label"), false, MaterialDeepGreyAmberMobileThemeIcons.saveTexture);
			saveAlert.addEventListener(Event.TRIGGERED, onSave);
			actionButtonsContainer.addChild(saveAlert);
			
			/* Setup Content */
			var soundLabelsList:Array = ALERT_NAMES_LIST.split(",");
			var soundFilesList:Array = ALERT_SOUNDS_LIST.split(",");
			var soundListProvider:ArrayCollection = new ArrayCollection();
			soundAccessoriesList = [];
			var previousSoundFileIndex:int = 0;
			
			var soundListLength:uint = soundLabelsList.length;
			for (var i:int = 0; i < soundListLength; i++) 
			{
				/* Set Label */
				var labelValue:String = StringUtil.trim(soundLabelsList[i]);
				
				/* Set Accessory */
				var accessoryValue:DisplayObject;
				if (StringUtil.trim(soundFilesList[i]) == "no_sound" || StringUtil.trim(soundFilesList[i]) == "default")
					accessoryValue = new Sprite();
				else
				{
					accessoryValue = LayoutFactory.createPlayButton(onPlaySound);
					accessoryValue.pivotX = -15;
				}
				
				soundAccessoriesList.push(accessoryValue);
				
				/* Set Sound File */
				var soundFileValue:String;
				if (StringUtil.trim(soundFilesList[i]) != "no_sound" && StringUtil.trim(soundFilesList[i]) != "default")
					soundFileValue = "../assets/sounds/" + StringUtil.trim(soundFilesList[i]);
				else
					soundFileValue = StringUtil.trim(soundFilesList[i]);
				
				soundListProvider.push( { label: labelValue, accessory: accessoryValue, soundFile: soundFileValue } );
				
				if (mode == "edit" && ((soundFileValue == "../assets/sounds/" + selectedSoundNameValue || labelValue == selectedSoundNameValue) || (labelValue == "No Sound" && selectedSoundNameValue == "../assets/sounds/" + "no_sound") || (labelValue == "Default iOS" && selectedSoundNameValue == "../assets/sounds/" + "default")))
					previousSoundFileIndex = i;
			}
			
			soundList.dataProvider = soundListProvider;
			soundList.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.accessoryOffsetX = -20;
				itemRenderer.labelOffsetX = 20;
				
				return itemRenderer;
			};
			soundList.selectedIndex = previousSoundFileIndex;
			soundList.addEventListener(Event.CHANGE, onSettingsChanged);
			
			/* Data */
			dataProvider = new ListCollection(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations',"enabled"), accessory: alertEnabled },
					{ label: ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"name_label"), accessory: alertName },
					{ label: ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"snooze_notification_label"), accessory: enableSnoozeInNotification },
					{ label: Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr ? ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"default_snooze_time_label") : ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"default_snooze_time_iphone_x_label"), accessory: snoozeMinutes },
					{ label: ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"repeat_label"), accessory: enableRepeat },
					{ label: ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"sound_label"), accessory: soundList },
					{ label: ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"vibration_label"), accessory: enableVibration },
					{ label: "", accessory: actionButtonsContainer }
				]);
			
			/* Renderer */
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				item.paddingRight = 0;
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
					item.paddingRight = -2;
				item.accessoryOffsetX = -10;
				item.accessoryLabelProperties.wordWrap = true;
				item.defaultLabelProperties.wordWrap = true;
					
				return item;
			};
			
			/* Layout */
			layoutData = new AnchorLayoutData( 0, 0, 0, 0 );
		}
		
		public function save():Boolean
		{
			if (needsSave)
			{
				var alert:Alert;
				
				//If alert name is empty, warn the user
				if(alertName.text == "")
				{
					alert = new Alert();
					alert.title = ModelLocator.resourceManagerInstance.getString('globaltranslations',"warning_alert_title");
					alert.message = ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"alarm_name_empty_alert_message");
					alert.buttonsDataProvider = new ListCollection
					(
						[
							{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations',"ok_alert_button_label") }
						]
					)
					PopUpManager.addPopUp(alert, true, true);
					
					needsSave = true;
					return false;
				}
				else if (alertName.text != null && alertName.text != "null")
				{
					var duplicateName:Boolean = false;
					var alertTypeLength:uint = alertTypesList.length;
					for (var i:int = 0; i < alertTypeLength; i++) 
					{
						var alertType:AlertType = alertTypesList[i];
						if (alertNameValue.toUpperCase() == alertType.alarmName.toUpperCase())
						{
							duplicateName = true;
							break;
						}
					}
					
					//If alert name already exists and it's not an edit, warn the user
					if (duplicateName && mode == "add")
					{
						alert = AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('globaltranslations',"warning_alert_title"),
							ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"invalid_alert_name_alert_message"),
							Number.NaN,
							null,
							HorizontalAlign.CENTER
						);
						
						needsSave = true;
						return false;
					}
					else
					{
						//Create and save alert to the database
						var sound:String = soundList != null && soundList.selectedItem != null && soundList.selectedItem.soundFile != null ? (soundList.selectedItem.soundFile as String).replace("../assets/sounds/", "") : "";
						
						var newAlertType:AlertType = new AlertType
						(
							alertTypeUniqueID,
							Number.NaN,
							alertNameValue,
							false,
							enableVibrationValue,
							enableSnoozeInNotificationValue,
							alertEnabledSwitchStateValue,
							false,
							sound,
							snoozeMinutesValue,
							repeatInMinutes
						);
						
						if (mode == "edit")
							Database.updateAlertTypeSynchronous(newAlertType);
						else
							Database.insertAlertTypeSychronous(newAlertType);
						
						if (previousAlertName != "" && previousAlertName != alertNameValue) 
							AlertType.alertTypeUsed(previousAlertName, alertNameValue);
						
						needsSave = false;
						return true;
					}
				}
				else
				{
					//Something went wrong, warn the user
					alert = new Alert();
					alert.title = ModelLocator.resourceManagerInstance.getString('globaltranslations',"warning_alert_title");
					alert.message = ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"something_went_wrong_alert_message");
					alert.buttonsDataProvider = new ListCollection
						(
							[
								{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations',"ok_alert_button_label") }
							]
						)
					PopUpManager.addPopUp(alert, true, true);
					
					needsSave = true;
					return false;
				}
			}
			
			return false;
		}
		
		/**
		 * Event Handlers
		 */
		private function onSave(e:Event):void
		{	
			if(save())
				dispatchEventWith(Event.COMPLETE, false, { newAlertName: alertNameValue });
		}
		
		private function onCancel(e:Event):void
		{	
			dispatchEventWith(Event.COMPLETE);
		}
		
		private function onSettingsChanged(e:Event):void
		{
			//Restrict characters
			alertName.text = alertName.text.replace("-", "").replace(":","").replace(">","");
			
			//Update internal variables
			alertEnabledSwitchStateValue = alertEnabled.isSelected;
			alertNameValue = alertName.text;
			enableSnoozeInNotificationValue = enableSnoozeInNotification.isSelected;
			snoozeMinutesValue = snoozeMinutes.value;
			enableRepeatValue = enableRepeat.isSelected;
			enableRepeatValue == true ? repeatInMinutes = TimeSpan.TIME_5_MINUTES : repeatInMinutes = 0;
			enableVibrationValue = enableVibration.isSelected;
			
			saveAlert.isEnabled = true;
			needsSave = true;
		}
		
		private function onPlaySound(e:Event):void
		{
			var selectedItemData:Object = DefaultListItemRenderer(Button(e.currentTarget).parent).data;
			var soundFile:String = selectedItemData.soundFile;
			if(soundFile != "" && soundFile != "default" && soundFile != "no_sound")
				SpikeANE.playSound(soundFile, Number.NaN, LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALARMS_USER_DEFINED_SYSTEM_VOLUME_ON) == "true" ? Number(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_ALARMS_USER_DEFINED_SYSTEM_VOLUME_VALUE)) : Number.NaN);
		}
		
		private function onSoundListClose():void
		{
			SpikeANE.stopPlayingSound();
		}
		
		private function onTextInputEnter(event:Event):void
		{
			//Clear focus to dismiss the keyboard
			alertName.clearFocus();
		}
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			super.draw();
			
			saveAlert.isEnabled = false;
		}
		
		override public function dispose():void
		{
			if(soundAccessoriesList != null && soundAccessoriesList.length > 0)
			{
				var length:int = soundAccessoriesList.length;
				for (var i:int = 0; i < length; i++) 
				{
					var btn:Button = soundAccessoriesList[i] as Button;
					if (btn != null)
					{
						btn.dispose();
						btn = null;
					}
				}
				soundAccessoriesList.length = 0;
				soundAccessoriesList = null;
			}
			
			if(alertEnabled != null)
			{
				alertEnabled.dispose();
				alertEnabled = null;
			}
			if (alertName != null)
			{
				alertName.removeEventListener( FeathersEventType.ENTER, onTextInputEnter );
				alertName.removeEventListener(Event.CHANGE, onSettingsChanged);
				alertName.dispose();
				alertName = null;
			}
			if(enableSnoozeInNotification != null)
			{
				enableSnoozeInNotification.dispose();
				enableSnoozeInNotification = null;
			}
			if (snoozeMinutes != null)
			{
				snoozeMinutes.dispose();
				snoozeMinutes = null;
			}
			if(enableRepeat != null)
			{
				enableRepeat.dispose();
				enableRepeat = null;
			}
			if(enableVibration != null)
			{
				enableVibration.dispose();
				enableVibration = null;
			}
			if(soundList != null)
			{
				soundList.dispose();
				soundList = null;
			}
			if(saveAlert != null)
			{
				actionButtonsContainer.removeChild(saveAlert);
				saveAlert.dispose();
				saveAlert = null;
			}
			
			if(cancelAlert != null)
			{
				actionButtonsContainer.removeChild(cancelAlert);
				cancelAlert.dispose();
				cancelAlert = null;
			}
			
			if(actionButtonsContainer != null)
			{
				actionButtonsContainer.dispose();
				actionButtonsContainer = null;
			}
			
			super.dispose();
		}
	}
}