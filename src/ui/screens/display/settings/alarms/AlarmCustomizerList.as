package ui.screens.display.settings.alarms
{
	import flash.display.StageOrientation;
	import flash.utils.ByteArray;
	
	import database.BgReading;
	import database.CommonSettings;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.NumericStepper;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.core.PopUpManager;
	import feathers.data.ListCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.text.TextFormat;
	
	import ui.popups.AlertManager;
	import ui.screens.data.AlarmNavigatorData;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.TimeSpan;
	
	[ResourceBundle("alarmsettingsscreen")]
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("speechsettingsscreen")]

	public class AlarmCustomizerList extends SpikeList 
	{
		/* Constants */
		private const UNIT_MGDL:String = "mg/dL";
		private const UNIT_MMOL:String = "mmol/L";
		
		/* Display Objects */
		private var alarmCustomizerCallout:Callout;
		private var alarmCreatorList:AlarmCreatorList;
		private var addAlarmtButton:Button;
		private var positionHelper:Sprite;
		private var useGlucoseThresholdsSwitch:ToggleSwitch;
		private var lowGlucoseThresholdStepper:NumericStepper;
		private var highGlucoseThresholdStepper:NumericStepper;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var glucoseUnit:String;
		private var alarmID:Number;
		private var alarmType:String;
		private var alarmData:Array = [];
		private var finalAlarmData:Array;
		private var alarmControlsList:Array = [];
		private var isThresholdsEnabled:Boolean;
		private var lowThresholdValue:Number;
		private var highThresholdValue:Number;
		
		public function AlarmCustomizerList(alarmID:Number, alarmType:String)
		{
			super();
			
			//Set initial internal variables
			this.alarmID = alarmID;
			this.alarmType = alarmType;
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupInitialContent();
			setupContent();
		}
		
		private function setupProperties():void
		{
			/* Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialContent():void
		{
			/* Set Internal Variables */
			if (alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE || alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE_CHANGE)
				glucoseUnit = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? UNIT_MGDL : UNIT_MMOL;
			
			if (alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE_CHANGE)
			{
				if (alarmID == CommonSettings.COMMON_SETTING_FAST_RISE_ALERT)
					isThresholdsEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_RISE_ALERT_GLUCOSE_THRESHOLDS_ON) == "true";
				else if (alarmID == CommonSettings.COMMON_SETTING_FAST_DROP_ALERT)
					isThresholdsEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_DROP_ALERT_GLUCOSE_THRESHOLDS_ON) == "true";
				
				if (alarmID == CommonSettings.COMMON_SETTING_FAST_RISE_ALERT)
					lowThresholdValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_RISE_ALERT_LOW_GLUCOSE_THRESHOLD) != "" ? Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_RISE_ALERT_LOW_GLUCOSE_THRESHOLD)) : Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
				else if (alarmID == CommonSettings.COMMON_SETTING_FAST_DROP_ALERT)
					lowThresholdValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_DROP_ALERT_LOW_GLUCOSE_THRESHOLD) != "" ? Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_DROP_ALERT_LOW_GLUCOSE_THRESHOLD)) : Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
				
				if (glucoseUnit != "mg/dL") lowThresholdValue = Math.round(BgReading.mgdlToMmol(lowThresholdValue) * 10) / 10;
				
				if (alarmID == CommonSettings.COMMON_SETTING_FAST_RISE_ALERT)
					highThresholdValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_RISE_ALERT_HIGH_GLUCOSE_THRESHOLD) != "" ? Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_RISE_ALERT_HIGH_GLUCOSE_THRESHOLD)) : Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
				else if (alarmID == CommonSettings.COMMON_SETTING_FAST_DROP_ALERT)
					highThresholdValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_DROP_ALERT_HIGH_GLUCOSE_THRESHOLD) != "" ? Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_DROP_ALERT_HIGH_GLUCOSE_THRESHOLD)) : Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
				
				if (glucoseUnit != "mg/dL") highThresholdValue = Math.round(BgReading.mgdlToMmol(highThresholdValue) * 10) / 10;
			}
				
			/* Parse Alarm Settings */
			var completeAlarmSettings:String = CommonSettings.getCommonSetting(alarmID);
			var alarmsSettingsDivided:Array = completeAlarmSettings.split("-");
			var alarmsSettingsLength:uint = alarmsSettingsDivided.length;
			
			var validIndex:uint = 0;
			for (var i:int = 0; i < alarmsSettingsLength; i++) 
			{
				//Get alarm settings
				var tempAlarmSettings:Array = (alarmsSettingsDivided[i] as String).split(">");
				
				//Get alarm time data
				var alarmTimeData:Array = (tempAlarmSettings[0] as String).split(":");
				
				//Create alarm settings object
				//Process Start Time
				var alarmSettings:Object = {};
				alarmSettings.startTimeStamp = (Number(alarmTimeData[0]) * 60 * 60 * 1000) + (Number(alarmTimeData[1]) * 60 * 1000);
				alarmSettings.startTimeOutput = tempAlarmSettings[0];
				alarmSettings.startHour = Number(alarmTimeData[0]);
				alarmSettings.startMinutes = Number(alarmTimeData[1]);
				if (i < alarmsSettingsLength - 1)
				{
					//Process End Time
					var tempNextAlarmSettings:Array = (alarmsSettingsDivided[i+1] as String).split(">");
					var nextAlarmTimeData:Array = (tempNextAlarmSettings[0] as String).split(":");
					
					var endHours:Number = Number(nextAlarmTimeData[0]);
					var endMinutes:Number = Number(nextAlarmTimeData[1]);
					if (endMinutes == 0)
					{
						endHours -= 1;
						if (endHours == -1)
							endHours = 23;
						
						endMinutes = 59;
					}
					else
						endMinutes -= 1;
					
					alarmSettings.endTimeStamp = (endHours * 60 * 60 * 1000) + (endMinutes * 60 * 1000);
					var timeSpan:TimeSpan = TimeSpan.fromMilliseconds(Number(alarmSettings.endTimeStamp));
					alarmSettings.endTimeOutput = timeSpan.hoursFormatted + ":" + timeSpan.minutesFormatted;
					alarmSettings.endHour = endHours;
					alarmSettings.endMinutes = endMinutes;
				}
				else
				{
					//We are at the end. Ensure the settings fill the entire 24h timespan
					alarmSettings.endTimeStamp = (23 * 60 * 60 * 1000) + (59 * 60 * 1000);
					alarmSettings.endTimeOutput = "23:59";
					alarmSettings.endHour = 23;
					alarmSettings.endMinutes = 59;
				}
				alarmSettings.value = tempAlarmSettings[1];
				alarmSettings.alertType = tempAlarmSettings[2];
				alarmSettings.alarmType = alarmType;
				alarmSettings.alarmID = alarmID;
				
				
				if (alarmSettings.alertType != "No Alert")
				{
					alarmSettings.index = validIndex;
					validIndex += 1;
					alarmData.push(alarmSettings);
				}
			}
		}
		
		private function setupContent():void
		{
			//Glucose thresholds
			if (alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE_CHANGE)
			{
				//On/Off Switch
				useGlucoseThresholdsSwitch = LayoutFactory.createToggleSwitch(isThresholdsEnabled);
				useGlucoseThresholdsSwitch.pivotX = 5;
				useGlucoseThresholdsSwitch.addEventListener(Event.CHANGE, onGlucoseThresholdsChange);
				
				lowGlucoseThresholdStepper = LayoutFactory.createNumericStepper(glucoseUnit == "mg/dL" ? 40 : Math.round(BgReading.mgdlToMmol(40) * 10) / 10, glucoseUnit == "mg/dL" ? 390 : Math.round(BgReading.mgdlToMmol(390) * 10) / 10, lowThresholdValue, glucoseUnit == "mg/dL" ? 1 : 0.1);
				lowGlucoseThresholdStepper.addEventListener( Event.CHANGE, onGlucoseThresholdLowChanged);
				highGlucoseThresholdStepper = LayoutFactory.createNumericStepper(glucoseUnit == "mg/dL" ? 50 : Math.round(BgReading.mgdlToMmol(50) * 10) / 10, glucoseUnit == "mg/dL" ? 400 : Math.round(BgReading.mgdlToMmol(400) * 10) / 10, highThresholdValue, glucoseUnit == "mg/dL" ? 1 : 0.1);
				highGlucoseThresholdStepper.addEventListener( Event.CHANGE, onGlucoseThresholdHighChanged);
			}
			
			//Add alarm button
			addAlarmtButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"add_button_label"), false, MaterialDeepGreyAmberMobileThemeIcons.alarmAddTexture);
			addAlarmtButton.gap = 5;
			addAlarmtButton.addEventListener(Event.TRIGGERED, onAddAlarm);
			
			/* List Content */
			var listData:ListCollection = new ListCollection();
			for (var i:int = 0; i < alarmData.length; i++) 
			{
				//Define alarm time range
				var startTime:String = alarmData[i].startTimeOutput;
				var endTime:String = alarmData[i].endTimeOutput
				var timeRangeOutput:String = startTime + " - " + endTime;
				
				//Define alarm value
				var valueOutput:String = String(alarmData[i].value);
				if (alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE || alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE_CHANGE)
				{
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
						valueOutput = String(Math.round(((BgReading.mgdlToMmol((Number(alarmData[i].value)))) * 10)) / 10);
						
					valueOutput += glucoseUnit;
				}
				else if (alarmType == AlarmNavigatorData.ALARM_TYPE_CALIBRATION)
					valueOutput += "h";
				else if (alarmType == AlarmNavigatorData.ALARM_TYPE_MISSED_READING)
					valueOutput += "m";
				
				//Define alarm alert type
				var alertTypeOutput:String = String(alarmData[i].alertType);
				
				//Create alarm controls, define event listeners and save them for disposal
				var alarmControls:AlarmManagerAccessory = new AlarmManagerAccessory();
				if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6 || Constants.deviceModel == DeviceInfo.IPHONE_6_6S_7_8)
					alarmControls.scale = 0.8;
				else if (Constants.deviceModel == DeviceInfo.IPHONE_6_6S_7_8 || Constants.deviceModel == DeviceInfo.IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
					alarmControls.scale = 0.9;
				else if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
					alarmControls.scale = 0.7;
				alarmControls.pivotX = -8;
				alarmControls.addEventListener(AlarmManagerAccessory.EDIT, onEditAlarm);
				alarmControls.addEventListener(AlarmManagerAccessory.DELETE, onDeleteAlarm);
				alarmControlsList.push(alarmControls);
				
				//Create alarm list item
				var itemLabel:String = timeRangeOutput;
				if (alarmType != AlarmNavigatorData.ALARM_TYPE_PHONE_MUTED && alarmType != AlarmNavigatorData.ALARM_TYPE_TRANSMITTER_LOW_BATTERY)
					itemLabel += " | " + valueOutput;
				itemLabel += " | " + alertTypeOutput;
				
				listData.push( { label: itemLabel, accessory: alarmControls, data: alarmData[i], index: i } );
			}
			//Add action buttons to the list
			listData.push( { label:"", accessory:addAlarmtButton } );
			
			if (alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE_CHANGE)
			{
				listData.push( { label:ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','use_glucose_thresholds_label'), accessory:useGlucoseThresholdsSwitch } );
				if (isThresholdsEnabled)
				{
					listData.push( { label:ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','high_threshold_label'), accessory:highGlucoseThresholdStepper } );
					listData.push( { label:ModelLocator.resourceManagerInstance.getString('speechsettingsscreen','low_threshold_label'), accessory:lowGlucoseThresholdStepper } );
				}
			}
			
			//Set list content
			dataProvider = listData;
		}
		
		override protected function setupRenderFactory():void
		{
			/* List Item Renderer */
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6 || Constants.deviceModel == DeviceInfo.IPHONE_6_6S_7_8)
					item.fontStyles = new TextFormat("Roboto", 11, 0xEEEEEE, "left", "top");
				else if (Constants.deviceModel == DeviceInfo.IPHONE_6_6S_7_8 || Constants.deviceModel == DeviceInfo.IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
					item.fontStyles = new TextFormat("Roboto", 12, 0xEEEEEE, "left", "top");
				item.accessoryField = "accessory";
				item.accessoryOffsetX = -8;
				item.accessoryLabelProperties.wordWrap = true;
				item.defaultLabelProperties.wordWrap = true;
				
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						item.paddingRight = -10;
						item.paddingLeft = 30;
					}
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
						item.paddingRight = 30;
				}
				else
					item.paddingRight = -10;
				
				return item;
			};
		}
		
		private function processAlarmData():void
		{
			//Holder for the parsed alarms, ready to be processed into a final setting's string
			finalAlarmData = [];
			
			//Common index for loop iterations
			var i:int;
			
			if (alarmData == null || alarmData.length == 0)
			{
				//There are no alarms. Create a 24h time span NO ALERT filler
				finalAlarmData.push
				(
					{ startTime: "00:00", value: 0, alertType: "No Alert" }
				)
			}
			else
			{
				//Sort all alarms by time (ascennding)
				sortAlarms();
				
				//Loop through all alarms to process them
				var dataLength:uint = alarmData.length;
				for (i = 0; i < dataLength; i++) 
				{
					//Define current alarm relevant settings
					var currentAlarmSettings:Object = alarmData[i] as Object;
					var currentAlarmStartTimeStamp:Number = Number(currentAlarmSettings.startTimeStamp);
					var currentAlarmEndTimeStamp:Number = Number(currentAlarmSettings.endTimeStamp);
					
					if (i == 0)
					{
						//We are in the first alarm. Does the alarm start at 00:00
						if (currentAlarmStartTimeStamp > 0)
						{
							//We need to insert a NO ALERT first
							finalAlarmData.push
							(
								{ startTime: "00:00", value: 0, alertType: "No Alert" }
							)
						}
						
						//Push the first alarm into the array
						finalAlarmData.push
						(
							{ startTime: currentAlarmSettings.startTimeOutput, value: currentAlarmSettings.value, alertType: currentAlarmSettings.alertType }
						)
						
						//Check if there's only one alarm. If so, we might need to push a NO ALERT filler at the end.
						if (alarmData.length == 1)
						{
							if (currentAlarmEndTimeStamp < TimeSpan.TIME_23_HOURS_59_MINUTES)
							{
								//We need to add a NO ALERT filler at the end
								timeSpan = TimeSpan.fromMilliseconds(currentAlarmEndTimeStamp + TimeSpan.TIME_1_MINUTE);
								finalAlarmData.push
								(
									{ startTime: timeSpan.hoursFormatted + ":" + timeSpan.minutesFormatted, value: 0, alertType: "No Alert" }
								)
							}
						}
					}
					else
					{
						//We are in the following alarms. Define main settings of the previous alarm so we can compare start/end times and add NO ALERT fillers when/if needed
						var previousAlarmSettings:Object = alarmData[i-1] as Object;
						var previousAlarmEndTimeStamp:Number = Number(previousAlarmSettings.endTimeStamp);
						var timeSpan:TimeSpan;
						
						if (previousAlarmEndTimeStamp + TimeSpan.TIME_1_MINUTE < currentAlarmStartTimeStamp)
						{
							//There's a gap between the previous alarm and this one. Let's add a filler NO ALERT alarm that starts 1 minute later
							timeSpan = TimeSpan.fromMilliseconds(previousAlarmEndTimeStamp + TimeSpan.TIME_1_MINUTE);
							finalAlarmData.push
							(
								{ startTime: timeSpan.hoursFormatted + ":" + timeSpan.minutesFormatted, value: 0, alertType: "No Alert" }
							)
						}
						
						//Add the current alarm to the array
						finalAlarmData.push
						(
							{ startTime: currentAlarmSettings.startTimeOutput, value: currentAlarmSettings.value, alertType: currentAlarmSettings.alertType }
						)
						
						if (i == dataLength - 1)
						{
							//We're in the final alarm. Check if we need to add a NO ALERT filler to the end to complete the entire 24h span
							if (currentAlarmEndTimeStamp < TimeSpan.TIME_23_HOURS_59_MINUTES)
							{
								//Complete the 24h timespan with a NO ALERT filler that starts 1 minute later
								timeSpan = TimeSpan.fromMilliseconds(currentAlarmEndTimeStamp + TimeSpan.TIME_1_MINUTE);
								finalAlarmData.push
								(
									{ startTime: timeSpan.hoursFormatted + ":" + timeSpan.minutesFormatted, value: 0, alertType: "No Alert" }
								)
							}
						}
					}
				}
			}
			
			//All alarms are processed. Let's create the final settings string
			var finalAlarmSettings:String = "";
			
			//Loop through all the alarms and create the settings string
			var loopLength:uint = finalAlarmData.length;
			for (i = 0; i < loopLength; i++) 
			{
				var alarmObject:Object = finalAlarmData[i];
				finalAlarmSettings += alarmObject.startTime;
				finalAlarmSettings += ">";
				finalAlarmSettings += alarmObject.value;
				finalAlarmSettings += ">";
				finalAlarmSettings += alarmObject.alertType;
				if (i < loopLength - 1)
					finalAlarmSettings += "-";
			}
			
			//Save settings to database
			CommonSettings.setCommonSetting(alarmID, finalAlarmSettings);
			
			//Pop screen
			//dispatchEventWith(Event.COMPLETE);
		}
		
		private function setupCalloutPosition():void
		{
			//Position helper for the callout
			positionHelper = new Sprite();
			positionHelper.x = (Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2)) / 2;
			positionHelper.y = 0;
			addChild(positionHelper);
		}
		
		private function cloneObject( source:Object ):Object 
		{ 
			//ByteArray capable of cloning objects
			var cloner:ByteArray = new ByteArray(); 
			cloner.writeObject( source ); 
			cloner.position = 0; 
			
			return( cloner.readObject() ); 
		}
		
		private function displayInvalidAlarmAlert(conflictingTimerange:String):void
		{
			//Displays and alert when the user tries to add an alarm with a timerange that conflicts with an existing alarm
			var alert:Alert = AlertManager.showSimpleAlert
			(
				ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"invalid_alarm_alert_title"),
				ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"invalid_alarm_alert_message") + " " + conflictingTimerange + ".",
				Number.NaN,
				onCloseAlert
			);
			
			function onCloseAlert(e:Event):void
			{
				Starling.current.juggler.delayCall(showAlarmCustomizerCallout, 0.001);
			}
		}
		
		private function showAlarmCustomizerCallout(forceCreation:Boolean = false):void
		{
			if (forceCreation || alarmCustomizerCallout == null)
			{
				setupCalloutPosition();
				
				if (positionHelper == null || positionHelper.parent == null)
					return;
				
				alarmCustomizerCallout = new Callout();
				alarmCustomizerCallout.content = alarmCreatorList;
				alarmCustomizerCallout.origin = positionHelper;
			}
			
			if (positionHelper == null || positionHelper.parent == null)
			{
				setupCalloutPosition();
				
				if (positionHelper == null || positionHelper.parent == null)
					return;
				
				alarmCustomizerCallout.origin = positionHelper;
			}
			
			PopUpManager.addPopUp(alarmCustomizerCallout, false, false);
		}
		
		private function validateAlarm(alarm:Object, editMode:Boolean = false):Boolean
		{
			//Set initial variables
			var isValid:Boolean = true;
			var alarmStartTimeStamp:Number = Number(alarm.startTimeStamp);
			var alarmEndTimeStamp:Number = Number(alarm.endTimeStamp);
			var conflictingTimerange:String = "";
			
			//Loop through all the alarms
			var alarmsNumber:uint = alarmData.length;
			for (var i:int = 0; i < alarmsNumber; i++) 
			{
				//If we are in edit mode, skip the alarm we are editing
				if (editMode && i == alarm.index)
					continue;
				
				var existingAlarm:Object = alarmData[i];
				var existingStartTimeStamp:Number = Number(existingAlarm.startTimeStamp);
				var existingEndTimeStamp:Number = Number(existingAlarm.endTimeStamp);
				
				//Conditions that make timeranges conflict with each other
				if ((alarmStartTimeStamp >= existingStartTimeStamp && alarmStartTimeStamp <= existingEndTimeStamp) ||
					(alarmStartTimeStamp < existingStartTimeStamp && alarmEndTimeStamp >= existingEndTimeStamp) ||
					(alarmStartTimeStamp == existingStartTimeStamp - TimeSpan.TIME_1_MINUTE) ||
					(alarmStartTimeStamp == existingStartTimeStamp) ||
					(alarmEndTimeStamp == existingEndTimeStamp) ||
					(alarmEndTimeStamp >= existingStartTimeStamp && alarmEndTimeStamp <= existingEndTimeStamp))
				{
					conflictingTimerange = existingAlarm.startTimeOutput + " - " + existingAlarm.endTimeOutput;
					isValid = false;
				}
			}
			
			if (!isValid)
				displayInvalidAlarmAlert(conflictingTimerange);
			
			return isValid;
		}
		
		private function sortAlarms():void
		{
			//Basic function that sorts the alarms by start time
			alarmData.sortOn(["startTimeStamp"], Array.NUMERIC);
			for (var i:int = 0; i < alarmData.length; i++) 
			{
				var alarm:Object = alarmData[i];
				alarm.index = i;
			}
		}
		
		public function save():void
		{
			processAlarmData();
			
			if (alarmID == CommonSettings.COMMON_SETTING_FAST_RISE_ALERT)
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_RISE_ALERT_GLUCOSE_THRESHOLDS_ON) != String(isThresholdsEnabled))
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FAST_RISE_ALERT_GLUCOSE_THRESHOLDS_ON, String(isThresholdsEnabled));
				
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_RISE_ALERT_HIGH_GLUCOSE_THRESHOLD) != String(glucoseUnit == "mg/dL" ? highThresholdValue : Math.round(BgReading.mmolToMgdl(highThresholdValue))))
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FAST_RISE_ALERT_HIGH_GLUCOSE_THRESHOLD, String(glucoseUnit == "mg/dL" ? highThresholdValue : Math.round(BgReading.mmolToMgdl(highThresholdValue))));
				
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_RISE_ALERT_LOW_GLUCOSE_THRESHOLD) != String(glucoseUnit == "mg/dL" ? lowThresholdValue : Math.round(BgReading.mmolToMgdl(lowThresholdValue))))
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FAST_RISE_ALERT_LOW_GLUCOSE_THRESHOLD, String(glucoseUnit == "mg/dL" ? lowThresholdValue : Math.round(BgReading.mmolToMgdl(lowThresholdValue))));
			}
			else if (alarmID == CommonSettings.COMMON_SETTING_FAST_DROP_ALERT)
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_DROP_ALERT_GLUCOSE_THRESHOLDS_ON) != String(isThresholdsEnabled))
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FAST_DROP_ALERT_GLUCOSE_THRESHOLDS_ON, String(isThresholdsEnabled));
				
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_DROP_ALERT_HIGH_GLUCOSE_THRESHOLD) != String(glucoseUnit == "mg/dL" ? highThresholdValue : Math.round(BgReading.mmolToMgdl(highThresholdValue))))
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FAST_DROP_ALERT_HIGH_GLUCOSE_THRESHOLD, String(glucoseUnit == "mg/dL" ? highThresholdValue : Math.round(BgReading.mmolToMgdl(highThresholdValue))));
				
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FAST_DROP_ALERT_LOW_GLUCOSE_THRESHOLD) != String(glucoseUnit == "mg/dL" ? lowThresholdValue : Math.round(BgReading.mmolToMgdl(lowThresholdValue))))
					CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FAST_DROP_ALERT_LOW_GLUCOSE_THRESHOLD, String(glucoseUnit == "mg/dL" ? lowThresholdValue : Math.round(BgReading.mmolToMgdl(lowThresholdValue))));
			}
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onSaveAllAlarms(e:Event):void
		{
			save();
		}
		
		private function onAddAlarm(e:Event):void
		{
			alarmCreatorList = new AlarmCreatorList({alarmType:alarmType, alarmID:alarmID}, AlarmCreatorList.MODE_ADD);
			alarmCreatorList.addEventListener(AlarmCreatorList.CANCEL, onCancelCallout);
			alarmCreatorList.addEventListener(AlarmCreatorList.SAVE_ADD, onSaveNewAlarm);
			
			showAlarmCustomizerCallout(true);
		}
		
		private function onEditAlarm(e:Event):void
		{	
			var alarmData:Object = (((e.currentTarget as AlarmManagerAccessory).parent as DefaultListItemRenderer).data as Object).data as Object;
			
			alarmCreatorList = new AlarmCreatorList(cloneObject(alarmData), AlarmCreatorList.MODE_EDIT);
			alarmCreatorList.addEventListener(AlarmCreatorList.CANCEL, onCancelCallout);
			alarmCreatorList.addEventListener(AlarmCreatorList.SAVE_EDIT, onSaveEditAlarm);
			
			showAlarmCustomizerCallout(true);
		}
		
		private function onSaveNewAlarm(e:Event):void
		{
			if (validateAlarm(e.data))
			{
				alarmData.push(e.data);
				sortAlarms()
				setupContent();
				
				if (PopUpManager.isPopUp(alarmCustomizerCallout))
					PopUpManager.removePopUp(alarmCustomizerCallout, true);
				else if (alarmCustomizerCallout != null)
					alarmCustomizerCallout.removeFromParent(true);
				
				needsSave = true;
			}
		}
		
		private function onSaveEditAlarm(e:Event):void
		{
			if (validateAlarm(e.data, true))
			{
				alarmData[Number(e.data.index)] = e.data;
				sortAlarms()
				setupContent();
				
				if (PopUpManager.isPopUp(alarmCustomizerCallout))
					PopUpManager.removePopUp(alarmCustomizerCallout, true);
				else if (alarmCustomizerCallout != null)
					alarmCustomizerCallout.removeFromParent(true);
				
				needsSave = true;
			}	
		}
		
		public function closeCallout():void
		{
			if (alarmCustomizerCallout != null)
			{
				alarmCustomizerCallout.close(true);
			}
		}
		
		private function onCancelCallout(e:Event):void
		{
			alarmCustomizerCallout.close(true);
		}
		
		private function onDeleteAlarm(e:Event):void
		{
			//Get current alarm index
			var alarmIndex:int = (((e.currentTarget as AlarmManagerAccessory).parent as DefaultListItemRenderer).data as Object).index as int;
			
			//Show delete confirmation alert
			AlertManager.showActionAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations',"warning_alert_title"),
				ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"delete_alarm_type_confirmation_message"),
				Number.NaN,
				[
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations',"no_uppercase") },	
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations',"yes_uppercase"), triggered: onDeleteAlarm }	
				]
			);
			
			//Delete alarm
			function onDeleteAlarm(e:Event):void
			{
				alarmData.removeAt(alarmIndex);
				
				setupContent();
				
				needsSave = true;
			}
		}
		
		private function onGlucoseThresholdsChange(e:Event):void
		{
			isThresholdsEnabled = useGlucoseThresholdsSwitch.isSelected;
			
			needsSave = true;
			
			setupContent();
		}
		
		private function onGlucoseThresholdHighChanged(E:Event):void
		{
			highThresholdValue = highGlucoseThresholdStepper.value;
			
			if (highThresholdValue <= lowThresholdValue)
			{
				lowThresholdValue = highThresholdValue - (glucoseUnit == "mg/dL" ? 1 : 0.1);
				lowGlucoseThresholdStepper.value = lowThresholdValue;
			}
			
			needsSave = true;
		}
		
		private function onGlucoseThresholdLowChanged(E:Event):void
		{
			lowThresholdValue = lowGlucoseThresholdStepper.value;
			
			if (lowThresholdValue >= highThresholdValue)
			{
				highThresholdValue = lowThresholdValue + (glucoseUnit == "mg/dL" ? 1 : 0.1);
				highGlucoseThresholdStepper.value = highThresholdValue;
			}
			
			needsSave = true;
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (positionHelper != null)
				positionHelper.x = (Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2)) / 2;
			
			setupRenderFactory();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (alarmCustomizerCallout != null)
			{
				alarmCustomizerCallout.dispose();
				alarmCustomizerCallout = null;
			}
			
			if (alarmCreatorList != null)
			{
				alarmCreatorList.dispose();
				alarmCreatorList = null;
			}
			
			if (addAlarmtButton != null)
			{
				addAlarmtButton.removeEventListener(Event.TRIGGERED, onAddAlarm);
				addAlarmtButton.dispose();
				addAlarmtButton = null;
			}
			
			if (positionHelper != null)
			{
				positionHelper.dispose();
				positionHelper = null;
			}
			
			if (alarmControlsList != null && alarmControlsList.length > 0)
			{
				for (var i:int = 0; i < alarmControlsList.length; i++) 
				{
					var control:AlarmManagerAccessory = alarmControlsList[i];
					if (control != null)
					{
						control.dispose();
						control = null;
					}
				}
			}
			
			if (useGlucoseThresholdsSwitch != null)
			{
				useGlucoseThresholdsSwitch.removeEventListener(Event.CHANGE, onGlucoseThresholdsChange);
				useGlucoseThresholdsSwitch.dispose();
				useGlucoseThresholdsSwitch = null;
			}
			
			if (lowGlucoseThresholdStepper != null)
			{
				lowGlucoseThresholdStepper.removeEventListener(Event.CHANGE, onGlucoseThresholdLowChanged);
				lowGlucoseThresholdStepper.dispose();
				lowGlucoseThresholdStepper = null;
			}
			
			if (highGlucoseThresholdStepper != null)
			{
				highGlucoseThresholdStepper.removeEventListener(Event.CHANGE, onGlucoseThresholdHighChanged);
				highGlucoseThresholdStepper.dispose();
				highGlucoseThresholdStepper = null;
			}
			
			super.dispose();
		}
	}
}