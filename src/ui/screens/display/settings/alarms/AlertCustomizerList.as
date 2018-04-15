package ui.screens.display.settings.alarms
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import database.AlertType;
	import database.Database;
	
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
	
	[ResourceBundle("alertsettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class AlertCustomizerList extends List 
	{
		/**
		 * this is the default value for 5 minutes, to be used as repeat interval<br>
		 * the real value is a bit less than 5 minutes because if we would take 5 minutes then there's a risk that the check is done just a bit too soon 
		 */
		private const TIME_5_MINUTES:int = 5 * 60 * 1000 - 10000;

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
				enableRepeatValue = selectedAlertType.repeatInMinutes == TIME_5_MINUTES;
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
			soundListPopUp.margin = 10;
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
			var soundLabelsList:Array = ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"alert_sounds_names").split(",");
			var soundFilesList:Array = ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"alert_sounds_files").split(",");
			var soundListProvider:ArrayCollection = new ArrayCollection();
			soundAccessoriesList = [];
			var previousSoundFileIndex:int = 0;
			
			var soundListLength:uint = soundLabelsList.length;
			for (var i:int = 0; i < soundListLength; i++) 
			{
				/* Set Label */
				var labelValue:String = soundLabelsList[i];
				
				/* Set Accessory */
				var accessoryValue:DisplayObject;
				if (soundFilesList[i] == "no_sound" || soundFilesList[i] == "default")
					accessoryValue = new Sprite();
				else
				{
					accessoryValue = LayoutFactory.createPlayButton(onPlaySound);
					accessoryValue.pivotX = -15;
				}
				
				soundAccessoriesList.push(accessoryValue);
				
				/* Set Sound File */
				var soundFileValue:String;
				if (soundFilesList[i] != "no_sound" && soundFilesList[i] != "default")
					soundFileValue = "../assets/sounds/" + soundFilesList[i];
				else
					soundFileValue = soundFilesList[i];
				
				soundListProvider.push( { label: labelValue, accessory: accessoryValue, soundFile: soundFileValue } );
				
				if (mode == "edit" && (labelValue == selectedSoundNameValue || (labelValue == ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"no_sound_name") && selectedSoundNameValue == "no_sound") || (labelValue == ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"default_sound_name") && selectedSoundNameValue == "default")))
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
					{ label: Constants.deviceModel != DeviceInfo.IPHONE_X ? ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"default_snooze_time_label") : ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"default_snooze_time_iphone_x_label"), accessory: snoozeMinutes },
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
				if (Constants.deviceModel == DeviceInfo.IPHONE_X)
					item.paddingRight = -2;
				item.accessoryOffsetX = -10;
					
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
						var sound:String;
						if (soundList.selectedItem.soundFile == "no_sound" || soundList.selectedItem.soundFile == "default")
							sound = soundList.selectedItem.soundFile;
						else
							sound = soundList.selectedItem.label;
						
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
			enableRepeatValue == true ? repeatInMinutes = TIME_5_MINUTES : repeatInMinutes = 0;
			enableVibrationValue = enableVibration.isSelected;
			
			saveAlert.isEnabled = true;
			needsSave = true;
		}
		
		private function onPlaySound(e:Event):void
		{
			var selectedItemData:Object = DefaultListItemRenderer(Button(e.currentTarget).parent).data;
			var soundFile:String = selectedItemData.soundFile;
			if(soundFile != "" && soundFile != "default" && soundFile != "no_sound")
				BackgroundFetch.playSound(soundFile);
		}
		
		private function onSoundListClose():void
		{
			BackgroundFetch.stopPlayingSound();
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