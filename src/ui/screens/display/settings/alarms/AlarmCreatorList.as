package ui.screens.display.settings.alarms
{
	import G5G6Model.TransmitterStatus;
	
	import database.AlertType;
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	import database.Database;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Check;
	import feathers.controls.DateTimeMode;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.GroupedList;
	import feathers.controls.LayoutGroup;
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultGroupedListItemRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.core.PopUpManager;
	import feathers.data.ArrayCollection;
	import feathers.data.HierarchicalCollection;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.RelativePosition;
	import feathers.layout.VerticalLayout;
	import feathers.layout.VerticalLayoutData;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.text.TextFormat;
	
	import ui.screens.data.AlarmNavigatorData;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.MathHelper;
	import utils.TimeSpan;
	
	[ResourceBundle("alarmsettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class AlarmCreatorList extends GroupedList 
	{
		/* Constants */
		public static const CANCEL:String = "cancel";
		public static const MODE_ADD:String = "add";
		public static const MODE_EDIT:String = "edit";
		public static const SAVE_EDIT:String = "saveEdit";
		public static const SAVE_ADD:String = "saveAdd";
		
		/* Display Objects */
		private var allDayAlarmCheck:Check;
		private var startTime:DateTimeSpinner;
		private var endTime:DateTimeSpinner;
		private var valueStepper:NumericStepper;
		private var saveAlarm:Button;
		private var cancelAlarm:Button;
		private var alertTypeList:PickerList;
		private var alertCreator:AlertCustomizerList;
		private var alertCreatorCallout:Callout;
		private var positionHelper:Sprite;
		private var actionButtonsContainer:LayoutGroup;
		
		/* Properties */
		private var mode:String;
		private var alarmData:Object;
		private var headerLabelValue:String;
		private var nowDate:Date;
		private var startDate:Date;
		private var endDate:Date;
		private var alarmValue:Number;
		private var alertTypeValue:String;
		private var selectedAlertTypeIndex:int;
		private var hideValue:Boolean = false;
		private var valueLabelValue:String;
		private var minimumStepperValue:Number;
		private var maximumStepperValue:Number;
		private var valueStepperStep:Number;
		private var isAllDay:Boolean;
		
		public function AlarmCreatorList(alarmData:Object, mode:String)
		{
			super();
			
			this.alarmData = alarmData;
			this.mode = mode;
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
			layoutData = new VerticalLayoutData( 100 );
			width = 300;
			(layout as VerticalLayout).hasVariableItemDimensions = true;
			(layout as VerticalLayout).useVirtualLayout = false;
		}
		
		private function setupInitialState(glucoseUnit:String = null):void
		{
			if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_PHONE_MUTED || alarmData.alarmID == CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT || ((alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_TRANSMITTER_LOW_BATTERY || alarmData.alarmID == CommonSettings.COMMON_SETTING_BATTERY_ALERT) && CGMBlueToothDevice.isBluKon()))
				hideValue = true;
			
			if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE)
			{
				valueLabelValue = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"bg_value_label");
				valueStepperStep = 1;
				minimumStepperValue = 40;
				maximumStepperValue = 400;
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
				{
					valueStepperStep = 0.1;
					minimumStepperValue = Math.round(((BgReading.mgdlToMmol((minimumStepperValue))) * 10)) / 10;
					maximumStepperValue = Math.round(((BgReading.mgdlToMmol((maximumStepperValue))) * 10)) / 10;
				}
			}
			else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE_CHANGE)
			{
				valueLabelValue = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"bg_change_label");
				valueStepperStep = 1;
				minimumStepperValue = 1;
				maximumStepperValue = 200;
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
				{
					valueStepperStep = 0.1;
					minimumStepperValue = Math.round(((BgReading.mgdlToMmol((minimumStepperValue))) * 10)) / 10;
					maximumStepperValue = Math.round(((BgReading.mgdlToMmol((maximumStepperValue))) * 10)) / 10;
				}
			}
			else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_CALIBRATION)
			{
				valueLabelValue = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"calibration_value_label");
				valueStepperStep = 1;
				minimumStepperValue = 1;
				maximumStepperValue = 168;
			}
			else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_MISSED_READING)
			{
				valueLabelValue = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"missed_readings_value_label");
				valueStepperStep = 5;
				minimumStepperValue = 10;
				maximumStepperValue = 999;
			}
			else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_TRANSMITTER_LOW_BATTERY && !CGMBlueToothDevice.isBluKon())
			{
				valueLabelValue = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"battery_value_label");
				valueStepperStep = 1;
				
				if (CGMBlueToothDevice.isDexcomG5() || CGMBlueToothDevice.isDexcomG6())
				{
					minimumStepperValue = 260;
					maximumStepperValue = 380;
				}
				else if (CGMBlueToothDevice.isDexcomG4())
				{
					minimumStepperValue = 170;
					maximumStepperValue = 240;
				}
				else if (CGMBlueToothDevice.isBlueReader() || CGMBlueToothDevice.isTransmiter_PL())
				{
					minimumStepperValue = 5;
					maximumStepperValue = 90;
				}
				else if (CGMBlueToothDevice.isMiaoMiao())
				{
					minimumStepperValue = 10;
					maximumStepperValue = 90;
				}
			}
			
			nowDate = new Date();
			if (mode == MODE_ADD)
			{
				headerLabelValue = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"add_alarm_title");
				isAllDay = false;
				startDate = new Date (nowDate.fullYear, nowDate.month, nowDate.date, 10, 0, 0, 0);
				endDate = new Date (nowDate.fullYear, nowDate.month, nowDate.date, 21, 00, 0, 0);
				alertTypeValue = "";
				if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE && alarmData.alarmID == CommonSettings.COMMON_SETTING_VERY_HIGH_ALERT)
				{
					alarmValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK));
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
						alarmValue = Math.round(((BgReading.mgdlToMmol((alarmValue))) * 10)) / 10;
				}
				else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE && alarmData.alarmID == CommonSettings.COMMON_SETTING_HIGH_ALERT)
				{
					alarmValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
						alarmValue = Math.round(((BgReading.mgdlToMmol((alarmValue))) * 10)) / 10;
				}
				else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE && alarmData.alarmID == CommonSettings.COMMON_SETTING_LOW_ALERT)
				{
					alarmValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
						alarmValue = Math.round(((BgReading.mgdlToMmol((alarmValue))) * 10)) / 10;
				}
				else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE && alarmData.alarmID == CommonSettings.COMMON_SETTING_VERY_LOW_ALERT)
				{
					alarmValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK));
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
						alarmValue = Math.round(((BgReading.mgdlToMmol((alarmValue))) * 10)) / 10;
				}
				else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE_CHANGE && (alarmData.alarmID == CommonSettings.COMMON_SETTING_FAST_RISE_ALERT || alarmData.alarmID == CommonSettings.COMMON_SETTING_FAST_DROP_ALERT))
				{
					alarmValue = 10;
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
						alarmValue = Math.round(((BgReading.mgdlToMmol((alarmValue))) * 10)) / 10;
				}
				else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_TRANSMITTER_LOW_BATTERY && alarmData.alarmID == CommonSettings.COMMON_SETTING_BATTERY_ALERT && !CGMBlueToothDevice.isBluKon())
				{
					if (CGMBlueToothDevice.isDexcomG5())
						alarmValue = G5G6Model.TransmitterStatus.LOW_BATTERY_WARNING_LEVEL_VOLTAGEA_G5;
					else if (CGMBlueToothDevice.isDexcomG6())
						alarmValue = G5G6Model.TransmitterStatus.LOW_BATTERY_WARNING_LEVEL_VOLTAGEA_G6;
					else if (CGMBlueToothDevice.isDexcomG4())
						alarmValue = 210;
					else if (CGMBlueToothDevice.isMiaoMiao())
						alarmValue = 30;
					else if (CGMBlueToothDevice.isBlueReader() || CGMBlueToothDevice.isTransmiter_PL())
						alarmValue = 20;
				}
				else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_CALIBRATION && alarmData.alarmID == CommonSettings.COMMON_SETTING_CALIBRATION_REQUEST_ALERT)
					alarmValue = 12;
				else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_MISSED_READING && alarmData.alarmID == CommonSettings.COMMON_SETTING_MISSED_READING_ALERT)
					alarmValue = 15;
			}
			else
			{
				headerLabelValue = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"edit_alarm_title");
				if (Number(alarmData.startHour) == 0 && Number(alarmData.startMinutes) == 0 && Number(alarmData.endHour) == 23 && Number(alarmData.endMinutes) == 59)
					isAllDay = true;
				startDate = new Date (nowDate.fullYear, nowDate.month, nowDate.date, Number(alarmData.startHour), Number(alarmData.startMinutes), 0, 0);
				endDate = new Date (nowDate.fullYear, nowDate.month, nowDate.date, Number(alarmData.endHour), Number(alarmData.endMinutes), 0, 0);
				alarmValue = Number(alarmData.value);
				if ((alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE || alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE_CHANGE) && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
					alarmValue = Math.round(((BgReading.mgdlToMmol((alarmValue))) * 10)) / 10;
				alertTypeValue = alarmData.alertType;
			}
		}
		
		private function setupContent():void
		{
			/* All Day Alarm */
			allDayAlarmCheck = LayoutFactory.createCheckMark(isAllDay);
			allDayAlarmCheck.addEventListener(Event.TRIGGERED, onAllDay);
			allDayAlarmCheck.pivotX = 1;
			
			/* Time Selectors */
			nowDate = new Date();
			
			startTime = new DateTimeSpinner();
			startTime.editingMode = DateTimeMode.TIME;
			startTime.locale = Constants.getUserLocale(true);
			startTime.minimum = new Date(nowDate.fullYear, nowDate.month, nowDate.date, 0, 0);
			startTime.maximum = new Date(nowDate.fullYear, nowDate.month, nowDate.date, 23, 58);
			startTime.value = startDate;
			if(Constants.deviceModel != DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 && Constants.deviceModel != DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6 && Constants.deviceModel != DeviceInfo.IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS && Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr && Constants.deviceModel != DeviceInfo.IPHONE_6_6S_7_8 && Constants.deviceModel != DeviceInfo.IPAD_MINI_1_2_3_4)
				startTime.height = 160;
			else if(Constants.deviceModel == DeviceInfo.IPAD_MINI_1_2_3_4)
				startTime.height = 150;
			else if(Constants.deviceModel == DeviceInfo.IPHONE_6_6S_7_8)
				startTime.height = 140;
			else if(Constants.deviceModel == DeviceInfo.IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
				startTime.height = 130;
			else if(Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
				startTime.height = 100;
			else if(Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				startTime.height = 60;
			else if(Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				startTime.height = 60;
			startTime.paddingTop = 5;
			startTime.paddingBottom = 5;
			startTime.pivotX = -1;
			if (isAllDay)
			{
				startTime.touchable = false;
				startTime.alpha = 0.6;
			}
			startTime.addEventListener(Event.CHANGE, onStartTimeChange);
			
			endTime = new DateTimeSpinner();
			endTime.editingMode = DateTimeMode.TIME;
			endTime.locale = Constants.getUserLocale(true);
			endTime.minimum = new Date(nowDate.fullYear, nowDate.month, nowDate.date, 0, 1);
			endTime.maximum = new Date(nowDate.fullYear, nowDate.month, nowDate.date, 23, 59);
			endTime.value = endDate;
			if(Constants.deviceModel != DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 && Constants.deviceModel != DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6 && Constants.deviceModel != DeviceInfo.IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS && Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr && Constants.deviceModel != DeviceInfo.IPHONE_6_6S_7_8 && Constants.deviceModel != DeviceInfo.IPAD_MINI_1_2_3_4)
				endTime.height = 160;
			else if(Constants.deviceModel == DeviceInfo.IPAD_MINI_1_2_3_4)
				endTime.height = 150;
			else if(Constants.deviceModel == DeviceInfo.IPHONE_6_6S_7_8)
				endTime.height = 140;
			else if(Constants.deviceModel == DeviceInfo.IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
				endTime.height = 130;
			else if(Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
				endTime.height = 100;
			else if(Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				endTime.height = 60;
			else if(Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				endTime.height = 60;
			endTime.paddingTop = 5;
			endTime.paddingBottom = 5;
			endTime.pivotX = -1;
			if (isAllDay)
			{
				endTime.touchable = false;
				endTime.alpha = 0.6;
			}
			endTime.addEventListener(Event.CHANGE, onEndTimeChange);
			
			/* Value Control */
			valueStepper = LayoutFactory.createNumericStepper(minimumStepperValue, maximumStepperValue, alarmValue);
			valueStepper.step = valueStepperStep;
			valueStepper.pivotX = -10;
			
			/* Alert Types List */
			alertTypeList = LayoutFactory.createPickerList();
			alertTypeList.pivotX = -3;
			
			var alertTypeDataProvider:ArrayCollection = new ArrayCollection();
			alertTypeDataProvider.push( { label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"new_alert_label") } );
			
			var alertTypesData:Array = Database.getAlertTypesList();
			var numAlertTypes:uint = alertTypesData.length;
			selectedAlertTypeIndex = -1;
			for (var i:int = 0; i < numAlertTypes; i++) 
			{
				var alertName:String = (alertTypesData[i] as AlertType).alarmName;
				
				if (alertName != "null" && alertName != "No Alert")
				{
					alertTypeDataProvider.push( { label: alertName } );
					
					if (alertName == alertTypeValue)
						selectedAlertTypeIndex = alertTypeDataProvider.length - 1;
				}
			}
			
			var alertTypeListPopup:DropDownPopUpContentManager = new DropDownPopUpContentManager();
			alertTypeListPopup.primaryDirection = RelativePosition.TOP;
			alertTypeList.popUpContentManager = alertTypeListPopup;
			alertTypeList.dataProvider = alertTypeDataProvider;
			alertTypeList.prompt = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"select_alert_prompt");
			alertTypeList.selectedIndex = selectedAlertTypeIndex;
			alertTypeList.listFactory = function():List
			{
				var list:List = new List();
				list.minWidth = 120;
				
				return list;
			};
			if(Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
			{
				alertTypeList.buttonFactory = function():Button
				{
					var button:Button = new Button();
					button.fontStyles = new TextFormat("Roboto", 10, 0xEEEEEE);
					return button;
				};
			}
			alertTypeList.addEventListener(Event.CHANGE, onAlertListChange);
			
			/* Action Buttons */
			var actionButtonsLayout:HorizontalLayout = new HorizontalLayout();
			actionButtonsLayout.gap = 5;
			
			actionButtonsContainer = new LayoutGroup();
			actionButtonsContainer.layout = actionButtonsLayout;
			actionButtonsContainer.pivotX = -3;
			
			cancelAlarm = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"cancel_button_label"), false, MaterialDeepGreyAmberMobileThemeIcons.cancelTexture);
			cancelAlarm.addEventListener(Event.TRIGGERED, onCancelAlarm);
			actionButtonsContainer.addChild(cancelAlarm);
			
			saveAlarm = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"save_button_label"), false, MaterialDeepGreyAmberMobileThemeIcons.saveTexture);
			saveAlarm.addEventListener(Event.TRIGGERED, onSave);
			actionButtonsContainer.addChild(saveAlarm);
			
			/* Data */
			var screenDataContent:Array = [];
			
			var infoSection:Object = {};
			if (Constants.deviceModel != DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6 && Constants.deviceModel != DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				infoSection.header = { label: headerLabelValue };
			
			var infoSectionChildren:Array = [];
			
			infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"all_day_label"), accessory: allDayAlarmCheck });
			infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"start_time_label"), accessory: startTime });
			infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"end_time_label"), accessory: endTime });
			if (!hideValue)
				infoSectionChildren.push({ label: valueLabelValue, accessory: valueStepper });
			infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"alert_type_label"), accessory: alertTypeList });
			infoSectionChildren.push({ label: "", accessory: actionButtonsContainer });
			
			infoSection.children = infoSectionChildren;
			screenDataContent.push(infoSection);
			
			dataProvider = new HierarchicalCollection(screenDataContent);
			
			itemRendererFactory = function():IGroupedListItemRenderer
			{
				var itemRenderer:DefaultGroupedListItemRenderer = new DefaultGroupedListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.iconSourceField = "accessory";
				itemRenderer.accessoryLabelProperties.wordWrap = true;
				itemRenderer.defaultLabelProperties.wordWrap = true;
				itemRenderer.paddingLeft = -5;
				if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE_CHANGE)
					itemRenderer.paddingTop = itemRenderer.paddingBottom = 5;
				
				return itemRenderer;
			};
			
			(layout as VerticalLayout).hasVariableItemDimensions = true;
			(layout as VerticalLayout).useVirtualLayout = false;
		}
		
		private function onAllDay(e:Event):void
		{
			//Define dates
			var now:Date = new Date();
			var startDate:Date;
			var endDate:Date;
			
			//Remove event listeners
			startTime.removeEventListener(Event.CHANGE, onStartTimeChange);
			endTime.removeEventListener(Event.CHANGE, onEndTimeChange);
			
			if (!allDayAlarmCheck.isSelected)
			{
				//Define value
				startDate = new Date (nowDate.fullYear, nowDate.month, nowDate.date, 0, 0, 0, 0);
				endDate = new Date (nowDate.fullYear, nowDate.month, nowDate.date, 23, 59, 0, 0);
				
				//Disable time controls
				startTime.touchable = false;
				startTime.alpha = 0.6;
				endTime.touchable = false;
				endTime.alpha = 0.6;
			}
			else
			{
				//Define value
				startDate = new Date (nowDate.fullYear, nowDate.month, nowDate.date, 10, 0, 0, 0);
				endDate = new Date (nowDate.fullYear, nowDate.month, nowDate.date, 21, 00, 0, 0);
				
				//Enable time controls
				startTime.touchable = true;
				startTime.alpha = 1;
				endTime.touchable = true;
				endTime.alpha = 1;
			}
			
			//Set Value
			startTime.value = startDate;
			endTime.value = endDate;
			
			//Enable event listeners
			startTime.addEventListener(Event.CHANGE, onStartTimeChange);
			endTime.addEventListener(Event.CHANGE, onEndTimeChange);
		}
		
		private function refreshAlertTypeList(newAlertName:String):void
		{
			alertTypeList.removeEventListener(Event.CHANGE, onAlertListChange);
			
			var alertTypeDataProvider:ArrayCollection = new ArrayCollection();
			alertTypeDataProvider.push( { label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"new_alert_label") } );
			
			var alertTypesData:Array = Database.getAlertTypesList();
			var numAlertTypes:uint = alertTypesData.length;
			for (var i:int = 0; i < numAlertTypes; i++) 
			{
				var alertName:String = (alertTypesData[i] as AlertType).alarmName;
				
				if (alertName != "null" && alertName != "No Alert")
				{
					alertTypeDataProvider.push( { label: alertName } );
					
					if (alertName == newAlertName)
						selectedAlertTypeIndex = alertTypeDataProvider.length - 1;
				}
			}
			
			alertTypeList.dataProvider = null;
			alertTypeList.dataProvider = alertTypeDataProvider;
			alertTypeList.selectedIndex = selectedAlertTypeIndex;
			alertTypeList.addEventListener(Event.CHANGE, onAlertListChange);
		}
		
		private function setupCalloutPosition():void
		{
			positionHelper = new Sprite();
			positionHelper.x = this.width / 2;
			positionHelper.y = -35;
			addChild(positionHelper);
		}
		
		private function onAlertListChange(e:Event):void
		{
			if (alertTypeList.selectedIndex == -1)
				return;
			
			saveAlarm.isEnabled = true;
			
			var selectedItemLabel:String = alertTypeList.selectedItem.label;
			if (selectedItemLabel == ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"new_alert_label"))
			{
				alertTypeList.selectedIndex = selectedAlertTypeIndex;
				
				alertCreator = new AlertCustomizerList(null);
				alertCreator.addEventListener(Event.COMPLETE, onAlertCreatorClose);
				alertCreatorCallout = new Callout();
				alertCreatorCallout.content = alertCreator;
				if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
					alertCreatorCallout.padding = 18;
				else
				{
					if (Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
						alertCreatorCallout.padding = 18;
					
					setupCalloutPosition();
					alertCreatorCallout.origin = positionHelper;
				}
				PopUpManager.addPopUp(alertCreatorCallout, true, false);
			}
			else
				selectedAlertTypeIndex = alertTypeList.selectedIndex;
		}
		
		private function onAlertCreatorClose(e:Event):void
		{
			if (e.data != null)
				refreshAlertTypeList(e.data.newAlertName);
			else
			{
				if (selectedAlertTypeIndex == -1)
					saveAlarm.isEnabled = false;
			}
			
			alertCreatorCallout.close(true);
		}
		
		/**
		 * Event Handlers
		 */
		private function onSave(e:Event):void
		{
			/* End Time */
			alarmData.endHour = endTime.value.hours;
			alarmData.endMinutes = endTime.value.minutes;
				
			alarmData.endTimeOutput = MathHelper.formatNumberToString(alarmData.endHour) + ":" + MathHelper.formatNumberToString(alarmData.endMinutes);
			alarmData.endTimeStamp = (Number(alarmData.endHour) * 60 * 60 * 1000) + (Number(alarmData.endMinutes) * 60 * 1000);
				
			/* Start Time */
			alarmData.startHour = startTime.value.hours;
			alarmData.startMinutes = startTime.value.minutes;
			
			alarmData.startTimeOutput = MathHelper.formatNumberToString(alarmData.startHour) + ":" + MathHelper.formatNumberToString(alarmData.startMinutes);
			alarmData.startTimeStamp = (Number(alarmData.startHour) * 60 * 60 * 1000) + (Number(alarmData.startMinutes) * 60 * 1000);
				
			/* Value */
			if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_PHONE_MUTED || alarmData.alarmID == CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT)
				alarmData.value = 0;
			else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_TRANSMITTER_LOW_BATTERY || alarmData.alarmID == CommonSettings.COMMON_SETTING_BATTERY_ALERT)
			{
				if (!CGMBlueToothDevice.isBluKon())
					alarmData.value = valueStepper.value;
				else
					alarmData.value = 5;
			}
			else if ((alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_MISSED_READING || alarmData.alarmID == CommonSettings.COMMON_SETTING_MISSED_READING_ALERT) || (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_CALIBRATION || alarmData.alarmID == CommonSettings.COMMON_SETTING_CALIBRATION_REQUEST_ALERT))
				alarmData.value = valueStepper.value;
			else
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
					alarmData.value = Math.round(BgReading.mmolToMgdl(valueStepper.value));
				else
					alarmData.value = valueStepper.value;
			}
				
			/* Alert Type */
			alarmData.alertType = alertTypeList.selectedItem.label;
			
			if (mode == MODE_EDIT) dispatchEventWith(SAVE_EDIT, false, alarmData);
			else dispatchEventWith(SAVE_ADD, false, alarmData);
		}
		
		private function onCancelAlarm(e:Event):void
		{
			dispatchEventWith(CANCEL);
		}
		
		private function onStartTimeChange(e:Event):void
		{
			var startTimestamp:Number = startTime.value.valueOf();
			var endDateTimestamp:Number = endTime.value.valueOf();
			
			if (startTimestamp + TimeSpan.TIME_1_MINUTE > endDateTimestamp)
				endTime.value = new Date(startTimestamp + TimeSpan.TIME_1_MINUTE);
		}
		
		private function onEndTimeChange(e:Event):void
		{
			var endDateTimestamp:Number = endTime.value.valueOf();
			var startTimestamp:Number = startTime.value.valueOf();
			
			if (endDateTimestamp <= startTimestamp)
				startTime.value = new Date(endDateTimestamp - TimeSpan.TIME_1_MINUTE);
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			if (selectedAlertTypeIndex == -1)
				saveAlarm.isEnabled = false;
			
			super.draw();
		}
		
		override public function dispose():void
		{	
			if (startTime != null)
			{
				startTime.dispose();
				startTime = null;
			}
			
			if (endTime != null)
			{
				endTime.dispose();
				endTime = null;
			}
			
			if (valueStepper != null)
			{
				valueStepper.dispose();
				valueStepper = null;
			}
			
			if (saveAlarm != null)
			{
				actionButtonsContainer.removeChild(saveAlarm);
				saveAlarm.dispose();
				saveAlarm = null;
			}
			
			if (cancelAlarm != null)
			{
				actionButtonsContainer.removeChild(cancelAlarm);
				cancelAlarm.dispose();
				cancelAlarm = null;
			}
			
			if (alertTypeList != null)
			{
				alertTypeList.dispose();
				alertTypeList = null;
			}
			
			if (actionButtonsContainer != null)
			{
				actionButtonsContainer.dispose();
				actionButtonsContainer = null;
			}
			
			if (alertCreator != null)
			{
				alertCreator.dispose();
				alertCreator = null;
			}
			
			if (alertCreatorCallout != null)
			{
				alertCreatorCallout.dispose();
				alertCreatorCallout = null;
			}
			
			if (positionHelper != null)
			{
				removeChild(positionHelper);
				positionHelper.dispose();
				positionHelper = null;
			}
			
			if (allDayAlarmCheck != null)
			{
				allDayAlarmCheck.removeEventListener(Event.TRIGGERED, onAllDay);
				allDayAlarmCheck.dispose();
				allDayAlarmCheck = null;
			}
			
			super.dispose();
		}
	}
}